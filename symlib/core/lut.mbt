///|
/// # KeyLut — 64 位元鍵 → 索引 之開放定址查找表（零配置熱路徑）
///
/// 本庫之群演算法（陪集 G-集、子群共軛類、標記矩陣、歸納/上歸納、Cayley 圖）
/// 都需要「群元素 → 元素索引」之反查。以 `Map[Int64,Int32]`（HAMT）實作時，
/// 每次查找需裝箱與指標追逐；在內層迴圈（|G|×|X| 量級）中成為瓶頸。
///
/// `KeyLut` 以**開放定址 + 線性探測**之兩個原始型別陣列實作同一介面：
/// - 建構 O(cap)（cap = ≥2n 之最小 2 的冪）
/// - 查找 O(1) 期望，且**零配置**
/// - 以 0L 為空槽哨兵（`perm_key64` 之鍵恆 ≥ 1，故安全）
///
/// 這是「規範形式/範疇化層」導出之**資料結構級**加速：演算法不變、複雜度不變，
/// 但常數因子大幅下降（實測：陪集 G-集 / 標記矩陣一類之內層反查約 3× 加速；
/// 絕對毫秒數見 `docs/bench_output.txt` D 節）。

///|
/// 開放定址鍵表。`keys[i] == 0L` 表示空槽。
pub(all) struct KeyLut {
  keys : Array[Int64]
  vals : Array[Int32]
  mask : Int64
}

///|
/// 混合函數（Fibonacci hashing）+ 遮罩 ⇒ 槽位。
fn key_slot(k : Int64, mask : Int64) -> Int32 {
  let mut h = k * 0x9E3779B97F4A7C15L
  h = h ^ (h >> 32)
  (h & mask).to_int()
}

///|
/// 開放定址表之通用建構：`val_of(i)` 決定第 i 個鍵對應之值。
/// `key_lut` 用 `val_of = i`（鍵 → 索引），`key_lut_pairs` 用 `val_of = vals[i]`。
fn key_lut_of(keys : Array[Int64], val_of : (Int32) -> Int32) -> KeyLut {
  let n = keys.length()
  let mut cap = 2
  while cap < 2 * n + 1 {
    cap = cap * 2
  }
  let mask = (cap - 1).to_int64()
  let ks = Array::make(cap, 0L)
  let vs = Array::make(cap, 0)
  for i, k in keys {
    guard k != 0L else { abort("key_lut: zero key") }
    let mut j = key_slot(k, mask)
    while ks[j] != 0L {
      j = (j + 1) & (cap - 1)
    }
    ks[j] = k
    vs[j] = val_of(i)
  }
  { keys: ks, vals: vs, mask, }
}

///|
/// 由鍵陣列建構（值 = 鍵在陣列中之索引）。
pub fn key_lut(keys : Array[Int64]) -> KeyLut {
  key_lut_of(keys, fn(i : Int32) -> Int32 { i })
}

///|
/// 查找；不存在時回傳 -1。
pub fn KeyLut::find(self : KeyLut, k : Int64) -> Int32 {
  let mut j = key_slot(k, self.mask)
  while self.keys[j] != 0L {
    if self.keys[j] == k {
      return self.vals[j]
    }
    j = (j + 1) & self.mask.to_int()
  }
  -1
}

///|
/// 查找；不存在時 abort（與 `Map.get(k).unwrap()` 同語意，但零配置）。
pub fn KeyLut::at(self : KeyLut, k : Int64) -> Int32 {
  let v = self.find(k)
  guard v >= 0 else { abort("KeyLut::at: key not found") }
  v
}

///|
/// 群元素列表 → 元素索引表（`perm_key64` 為鍵；要求 n ≤ 12）。
pub fn elem_lut_fast(elems : Array[Perm]) -> KeyLut {
  let keys : Array[Int64] = []
  for e in elems {
    keys.push(perm_key64(e))
  }
  key_lut(keys)
}

///|
/// 置換之單射整數鍵（n ≤ 12 時以 (n+1) 進位打包，保證單射）。
pub fn perm_key64(p : Perm) -> Int64 {
  guard p.n <= 12 else { abort("perm_key64: need n <= 12") }
  let base = (p.n + 1).to_int64()
  let mut k = 1L
  for v in p.img {
    k = k * base + v.to_int64()
  }
  k
}

///|
/// 免配置之合成鍵：`compose_key64(x, g) == perm_key64(x.compose(g))`。
/// 直接由像陣列算出 64 位元鍵，避開熱迴圈中之 Perm 配置（沙箱配置成本約 14µs）。
pub fn compose_key64(x : Array[Int32], g : Array[Int32]) -> Int64 {
  let n = x.length()
  guard n <= 12 else { abort("compose_key64: need n <= 12") }
  let base = (n + 1).to_int64()
  let mut k = 1L
  for i in 0..<n {
    k = k * base + x[g[i]].to_int64()
  }
  k
}

// ---------------------------------------------------------------------------
// 無度數上限 `PermLut`（n <= 15 採 4-bit Nibble 無乘法 SWAR，n > 15 採 SplitMix64 + 原像核對）
// ---------------------------------------------------------------------------

///|
/// 任意度數 `n` 皆可用之零配置群元素開放定址查找表（解除 `n <= 12` 硬上限）。
pub(all) struct PermLut {
  n : Int32
  imgs : Array[Array[Int32]]
  hashes : Array[UInt64]
  slots : Array[Int32]
  mask : Int32
}

///|
fn perm_nibble_or_hash_img(img : Array[Int32]) -> UInt64 {
  let n = img.length()
  if n <= 15 {
    let mut w = 1UL << 60
    for i in 0..<n {
      w = (w << 4) | (img[i].to_uint64() & 0xFUL)
    }
    if w == 0UL {
      1UL
    } else {
      w
    }
  } else {
    let mut h = 0x9E3779B97F4A7C15UL ^ n.to_uint64()
    for i in 0..<n {
      h = (h ^ (img[i].to_uint64() + 1UL)) * 0xBF58476D1CE4E5B9UL
      h = h ^ (h >> 30)
    }
    if h == 0UL {
      1UL
    } else {
      h
    }
  }
}

///|
fn perm_nibble_or_hash_composed(x : Array[Int32], g : Array[Int32]) -> UInt64 {
  let n = x.length()
  if n <= 15 {
    let mut w = 1UL << 60
    for i in 0..<n {
      w = (w << 4) | (x[g[i]].to_uint64() & 0xFUL)
    }
    if w == 0UL {
      1UL
    } else {
      w
    }
  } else {
    let mut h = 0x9E3779B97F4A7C15UL ^ n.to_uint64()
    for i in 0..<n {
      h = (h ^ (x[g[i]].to_uint64() + 1UL)) * 0xBF58476D1CE4E5B9UL
      h = h ^ (h >> 30)
    }
    if h == 0UL {
      1UL
    } else {
      h
    }
  }
}

///|
fn perm_slot_u64(h : UInt64, mask : Int32) -> Int32 {
  let mixed = (h * 0x9E3779B97F4A7C15UL) ^ (h >> 32)
  (mixed.reinterpret_as_int64() & mask.to_int64()).to_int()
}

///|
/// 建立支援任意度數 `n` 之群元素反查表 `PermLut`。
pub fn PermLut::of_elems(elems : Array[Perm]) -> PermLut {
  let ng = elems.length()
  let n = if ng == 0 { 0 } else { elems[0].size() }
  let mut cap = 2
  while cap < 2 * ng + 1 {
    cap = cap * 2
  }
  let mask = cap - 1
  let imgs : Array[Array[Int32]] = []
  let hashes = Array::make(cap, 0UL)
  let slots = Array::make(cap, -1)
  for i in 0..<ng {
    let im = elems[i].img
    imgs.push(im)
    let h = perm_nibble_or_hash_img(im)
    let mut j = perm_slot_u64(h, mask)
    while slots[j] >= 0 {
      j = (j + 1) & mask
    }
    hashes[j] = h
    slots[j] = i
  }
  { n, imgs, hashes, slots, mask, }
}

///|
/// 查找像陣列 `img` 的元素索引；不存在時回傳 `-1`。
pub fn PermLut::find_img(self : PermLut, img : Array[Int32]) -> Int32 {
  let h = perm_nibble_or_hash_img(img)
  let mut j = perm_slot_u64(h, self.mask)
  while self.slots[j] >= 0 {
    if self.hashes[j] == h {
      let cand = self.slots[j]
      if self.n <= 15 {
        return cand
      }
      let cim = self.imgs[cand]
      let mut eq = true
      for k in 0..<self.n {
        if cim[k] != img[k] {
          eq = false
          break
        }
      }
      if eq {
        return cand
      }
    }
    j = (j + 1) & self.mask
  }
  -1
}

///|
/// 查找置換 `p` 的索引；不存在時 `abort`。
pub fn PermLut::at_perm(self : PermLut, p : Perm) -> Int32 {
  let idx = self.find_img(p.img)
  guard idx >= 0 else { abort("PermLut::at_perm: key not found") }
  idx
}

///|
/// 零配置合成查找 `x ∘ g`（即 `i ↦ x[g[i]]`）在群元素表中的索引；不存在時 `abort`。
pub fn PermLut::at_composed(
  self : PermLut,
  x : Array[Int32],
  g : Array[Int32],
) -> Int32 {
  let h = perm_nibble_or_hash_composed(x, g)
  let mut j = perm_slot_u64(h, self.mask)
  while self.slots[j] >= 0 {
    if self.hashes[j] == h {
      let cand = self.slots[j]
      if self.n <= 15 {
        return cand
      }
      let cim = self.imgs[cand]
      let mut eq = true
      for k in 0..<self.n {
        if cim[k] != x[g[k]] {
          eq = false
          break
        }
      }
      if eq {
        return cand
      }
    }
    j = (j + 1) & self.mask
  }
  abort("PermLut::at_composed: composed element not found")
}
