// ---------------------------------------------------------------------------
// meta/core — Ramsey：更大的值、可複驗的見證、比 Erdős–Szekeres 更緊的上界
// ---------------------------------------------------------------------------
//
// 前一版只算到 R(3,4)=9，因為它用「逐頂點列舉鄰居遮罩」的窮舉。
// R(4,4) 的窮舉要處理 2^153 張圖 —— 那不是「慢」，是「方向錯了」。
//
// 這裡換成兩條數學路線夾擠，兩邊都是**可複驗的物件**，而不是搜尋器的自我宣稱：
//
//  下界：給出一個具體著色，任何人都能用 ramsey_check_coloring 獨立驗一次。
//        用的是 **Paley 圖**：q ≡ 1 (mod 4) 質數，紅邊 ⇔ 差是二次剩餘。
//        P₁₇ 是 (4,4)-free ⇒ R(4,4) ≥ 18。這是構造，不是搜尋。
//
//  上界：用經典遞迴 R(k,l) ≤ R(k−1,l) + R(k,l−1)（取任一頂點的紅／藍鄰居分割：
//        紅鄰居 ≥ R(k−1,l) 個就冒出紅 K_k，藍鄰居 ≥ R(k,l−1) 個就冒出藍 K_l，
//        而兩者之和 = n−1）。這是**證明**，不是搜尋：它把 R(4,4) 壓到 9+9 = 18。
//
// 兩邊一夾：R(4,4) = 18；同樣的手法把 R(3,5) 夾成 14（5+9 上界，K₁₃ 見證下界）。
// 於是「更大的值」不是靠更快的窮舉，而是靠**換一個數學結構**。

// ---------------------------------------------------------------------------
// 位元遮罩圖的基本工具
// ---------------------------------------------------------------------------

///|
fn popcount(x : Int32) -> Int32 {
  let mut v = x
  let mut c = 0
  while v != 0 {
    v = v & (v - 1)
    c = c + 1
  }
  c
}

///|
fn g_new(n : Int32) -> Array[Int32] {
  let g : Array[Int32] = []
  for _i in 0..<n {
    g.push(0)
  }
  g
}

///|
fn g_set(g : Array[Int32], i : Int32, j : Int32) -> Unit {
  g[i] = g[i] | (1 << j)
  g[j] = g[j] | (1 << i)
}

///|
fn g_clear(g : Array[Int32], i : Int32, j : Int32) -> Unit {
  g[i] = g[i] ^ (1 << j)
  g[j] = g[j] ^ (1 << i)
}

///|
fn g_edge(g : Array[Int32], i : Int32, j : Int32) -> Bool {
  (g[i] >> j) % 2 == 1
}

///|
/// 圖中（遮罩表示）k-團的個數。以遮罩交集遞迴，k 小時足夠快。
fn g_clique_count(g : Array[Int32], cand : Int32, k : Int32) -> Int32 {
  if k <= 1 {
    return popcount(cand)
  }
  let mut total = 0
  let mut rest = cand
  while rest != 0 {
    // 取最低位
    let low = rest & -rest
    let v = popcount(low - 1)
    rest = rest ^ low
    total = total + g_clique_count(g, rest & g[v], k - 1)
  }
  total
}

// ---------------------------------------------------------------------------
// Paley 圖：把「二次剩餘」變成見證
// ---------------------------------------------------------------------------

///|
/// q 的二次剩餘集合（不含 0）。
pub fn paley_qr(q : Int32) -> Array[Int32] {
  let seen = g_new(q)
  let out : Array[Int32] = []
  let mut i = 1
  while i < q {
    let r = i * i % q
    if seen[r] == 0 && r != 0 {
      seen[r] = 1
      out.push(r)
    }
    i = i + 1
  }
  out
}

///|
/// Paley 圖 P_q 的紅色邊集：i≠j 且 (j − i) mod q 是二次剩餘。
pub fn paley_edges(q : Int32) -> Array[(Int32, Int32)] {
  let qrs = paley_qr(q)
  let is_qr = g_new(q)
  for r in qrs {
    is_qr[r] = 1
  }
  let out : Array[(Int32, Int32)] = []
  for i in 0..<q {
    for j in (i + 1)..<q {
      if is_qr[(j - i + q) % q] == 1 {
        out.push((i, j))
      }
    }
  }
  out
}

///|
/// Paley 圖是自補的：|QR| = (q−1)/2，紅邊數 = 藍邊數 = C(q,2)/2。
pub fn paley_is_self_complementary(q : Int32) -> Bool {
  let qrs = paley_qr(q)
  let edges = paley_edges(q)
  2 * qrs.length() == q - 1 && 2 * edges.length() == q * (q - 1) / 2
}

// ---------------------------------------------------------------------------
// 上界：經典遞迴 R(k,l) ≤ R(k−1,l) + R(k,l−1)
// ---------------------------------------------------------------------------

///|
priv struct BoundMemo {
  w : Int32
  cell : Array[Int32]
}

///|
fn bm_new(k : Int32, l : Int32) -> BoundMemo {
  let w = l + 1
  let cell : Array[Int32] = []
  for _i in 0..<((k + 1) * (l + 1)) {
    cell.push(-1)
  }
  BoundMemo::{ w, cell, }
}

///|
/// 小值的**精確** R(k,l) 種子。遞迴上界 R(k,l) ≤ R(k−1,l) + R(k,l−1) 要用精確值才緊：
/// 若把 R(3,4) 的「上界 10」塞進去，只會得到 R(4,4) ≤ 20（比 Erdős–Szekeres 差）。
/// 這些種子本身由 `ramsey(3,3)`、`ramsey(3,4)` 的窮舉在同一支程式裡複驗（見定律）。
fn known_exact(k : Int32, l : Int32) -> Int32? {
  if k <= 1 || l <= 1 {
    return Some(1)
  }
  if k == 2 {
    return Some(l)
  }
  if l == 2 {
    return Some(k)
  }
  let a = if k < l { k } else { l }
  let b = if k < l { l } else { k }
  if a == 3 && b == 3 {
    return Some(6)
  }
  if a == 3 && b == 4 {
    return Some(9)
  }
  None
}

///|
fn rec_bound(k : Int32, l : Int32, memo : BoundMemo) -> Int32 {
  match known_exact(k, l) {
    Some(v) => v
    None => {
      let idx = k * memo.w + l
      if memo.cell[idx] < 0 {
        memo.cell[idx] = rec_bound(k - 1, l, memo) + rec_bound(k, l - 1, memo)
      }
      memo.cell[idx]
    }
  }
}

///|
/// R(k,l) ≤ ramsey_rec_bound(k,l)（經典遞迴；以精確小值為種子）。
pub fn ramsey_rec_bound(k : Int32, l : Int32) -> Int32 {
  if k <= 0 || l <= 0 {
    return 0
  }
  rec_bound(k, l, bm_new(k, l))
}

// ---------------------------------------------------------------------------
// 下界：確定性局部搜尋（固定種子，因此每次執行結果相同）
// ---------------------------------------------------------------------------

///|
priv struct Lcg {
  mut st : Int32
}

///| 32 位乘法會溢出的常數在這台機器上不可用；用「小乘數 + 大質數模」的 LCG，

///|
/// 只要求可重現與足夠散布（局部搜尋靠多次重啟，不靠單條高品質序列）。
fn lcg_next(s : Lcg) -> Int32 {
  s.st = (s.st * 1103 + 12345) % 1000033
  s.st
}

///|
fn rand_below(s : Lcg, m : Int32) -> Int32 {
  lcg_next(s) % m
}

///|
/// 目前的「壞團」總數：紅 K_k 個數 + 藍 K_l 個數。0 即 (k,l)-free。
fn ramsey_cost(
  red : Array[Int32],
  blue : Array[Int32],
  n : Int32,
  k : Int32,
  l : Int32,
) -> Int32 {
  let full = (1 << n) - 1
  let mut c = 0
  if k >= 2 {
    c = c + g_clique_count(red, full, k)
  }
  if l >= 2 {
    c = c + g_clique_count(blue, full, l)
  }
  c
}

///|
/// 只數「包含邊 (i,j) 的壞團」。因為翻一條邊只會改變經過它的團，
/// 所以代價可以增量更新：cost' = cost − before + after。
/// 這是讓局部搜尋在 wasm 上跑得動的關鍵（全域重數是 O(C(n,k))，增量只是 O(C(n,k−2))）。
fn bad_through(
  red : Array[Int32],
  blue : Array[Int32],
  n : Int32,
  k : Int32,
  l : Int32,
  i : Int32,
  j : Int32,
) -> Int32 {
  let full = (1 << n) - 1
  let excl = full ^ (1 << i) ^ (1 << j)
  let mut c = 0
  if k >= 2 && (red[i] >> j) % 2 == 1 {
    c = c + g_clique_count(red, red[i] & red[j] & excl, k - 2)
  }
  if l >= 2 && (blue[i] >> j) % 2 == 1 {
    c = c + g_clique_count(blue, blue[i] & blue[j] & excl, l - 2)
  }
  c
}

///|
/// 確定性局部搜尋：翻轉一條邊，壞團數不增則保留（爬山 + 平台漂移）。
/// 找到即回傳見證；回傳值**必須**再用 `ramsey_check_coloring` 獨立複驗。
pub fn ramsey_local_search(
  k : Int32,
  l : Int32,
  n : Int32,
  restarts : Int32,
  flips : Int32,
  seed : Int32,
) -> Array[(Int32, Int32)]? {
  if n <= 1 {
    return Some([])
  }
  let rng = Lcg::{ st: seed, }
  for _r in 0..<restarts {
    let red = g_new(n)
    let blue = g_new(n)
    for i in 0..<n {
      for j in (i + 1)..<n {
        if rand_below(rng, 2) == 1 {
          g_set(red, i, j)
        } else {
          g_set(blue, i, j)
        }
      }
    }
    let mut cur = ramsey_cost(red, blue, n, k, l)
    let mut it = 0
    while it < flips && cur > 0 {
      let i = rand_below(rng, n)
      let mut j = rand_below(rng, n)
      if i == j {
        j = (j + 1) % n
      }
      let hi = if i < j { i } else { j }
      let lo = if i < j { j } else { i }
      let before = bad_through(red, blue, n, k, l, hi, lo)
      let was_red = g_edge(red, hi, lo)
      if was_red {
        g_clear(red, hi, lo)
        g_set(blue, hi, lo)
      } else {
        g_clear(blue, hi, lo)
        g_set(red, hi, lo)
      }
      let after = bad_through(red, blue, n, k, l, hi, lo)
      let next = cur - before + after
      if next <= cur {
        cur = next
        // 還原
      } else if was_red {
        g_clear(blue, hi, lo)
        g_set(red, hi, lo)
      } else {
        g_clear(red, hi, lo)
        g_set(blue, hi, lo)
      }
      it = it + 1
    }
    if cur == 0 {
      let out : Array[(Int32, Int32)] = []
      for i in 0..<n {
        for j in (i + 1)..<n {
          if g_edge(red, i, j) {
            out.push((i, j))
          }
        }
      }
      return Some(out)
    }
  }
  None
}

// ---------------------------------------------------------------------------
// 夾擠：R(k,l) 的下界（見證）與上界（遞迴）並列，能夾死就是精確值
// ---------------------------------------------------------------------------

///|
/// 夾擠結果。`pinned` 為真表示 下界 = 上界，此時 `upper` 就是精確的 R(k,l)。
pub struct RamseyPin {
  lower : Int32
  upper : Int32
  witness : Array[(Int32, Int32)]
  pinned : Bool
}

///|
/// 用「Paley 構造／局部搜尋見證 + 遞迴上界」夾擠 R(k,l)。
///
/// 見證在 `upper − 1` 上找：找到就說明 R(k,l) > upper−1，配合 R(k,l) ≤ upper 即夾死。
pub fn ramsey_pin(k : Int32, l : Int32) -> RamseyPin {
  pin_at(k, l, ramsey_rec_bound(k, l))
}

///|
/// 以指定的上界做夾擠（供 `ramsey_upper` 疊代使用）。
fn pin_at(k : Int32, l : Int32, upper : Int32) -> RamseyPin {
  let n = upper - 1
  if n < 1 {
    return RamseyPin::{ lower: 0, upper, witness: [], pinned: false, }
  }
  // (1) 先試 Paley：q = n 且 q 是 ≡1 (mod 4) 的質數時，P_q 是自補圖。
  if n % 4 == 1 && is_prime(n) {
    let w = paley_edges(n)
    if ramsey_check_coloring(k, l, n, w) {
      return RamseyPin::{ lower: upper, upper, witness: w, pinned: true, }
    }
  }
  // (2) 再試確定性局部搜尋（種子固定 ⇒ 可重現）。
  //     預算隨規模收緊：n 太大或 k+l 太大時不做，寧可誠實回報「夾不死」。
  if n > 16 || k + l > 9 {
    return RamseyPin::{ lower: 0, upper, witness: [], pinned: false, }
  }
  match ramsey_local_search(k, l, n, 6, 3000, 12345) {
    Some(w) =>
      if ramsey_check_coloring(k, l, n, w) {
        return RamseyPin::{ lower: upper, upper, witness: w, pinned: true, }
      } else {
        return RamseyPin::{ lower: 0, upper, witness: [], pinned: false, }
      }
    None => return RamseyPin::{ lower: 0, upper, witness: [], pinned: false, }
  }
}

///|
fn is_prime(n : Int32) -> Bool {
  if n < 2 {
    return false
  }
  let mut d = 2
  while d * d <= n {
    if n % d == 0 {
      return false
    }
    d = d + 1
  }
  true
}

///|
/// **可證上界**：遞迴上界，且若能用見證夾死就用夾死的值（夾死後即精確值）。
pub fn ramsey_upper(k : Int32, l : Int32) -> Int32 {
  let u = ramsey_rec_bound(k, l)
  let p = pin_at(k, l, u)
  if p.pinned {
    p.upper
  } else {
    u
  }
}

///|
/// 精確值（只在真的知道時回傳）：
///   - 能夾死（上界 + 見證）⇒ `Some(值)`；
///   - 極小規模（k+l ≤ 7）⇒ 窮舉；
///   - 其餘 ⇒ `None`（誠實回報未知，而不是把上界當答案）。
pub fn ramsey_exact(k : Int32, l : Int32) -> Int32? {
  let p = ramsey_pin(k, l)
  if p.pinned {
    return Some(p.upper)
  }
  if k + l <= 7 {
    return Some(ramsey(k, l))
  }
  None
}

// ---------------------------------------------------------------------------
// 定律
// ---------------------------------------------------------------------------

///|
pub fn law_ramsey_ex_ramsey_recursion_bound_beats_erdos_szekeres() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 基底與已知值
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #1",
    ramsey_rec_bound(2, 5) == 5,
  )
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #2",
    ramsey_rec_bound(3, 3) == 6,
  )
  // 以精確小值為種子後，遞迴上界真的比 Erdős–Szekeres 緊
  // 以精確小值為種子後，R(3,4) 的界就等於精確值 9（而非 Erdős–Szekeres 的 10）
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #3",
    ramsey_rec_bound(3, 4) == 9 && erdos_szekeres(3, 4) == 10,
  )
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #4",
    ramsey_rec_bound(4, 4) == 18,
  )
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #5",
    ramsey_rec_bound(3, 5) == 14,
  )
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #6",
    ramsey_rec_bound(4, 4) < erdos_szekeres(4, 4),
  )
  // 緩衝：遞迴上界永不比 Erdős–Szekeres 差
  let mut ok = true
  for k in 3..<8 {
    for l in 3..<8 {
      if ramsey_rec_bound(k, l) > erdos_szekeres(k, l) {
        ok = false
      }
    }
  }
  chk(out, "ramsey: recursion bound beats Erdős–Szekeres #7", ok)
  // 對稱性在界上也成立
  let mut sym = true
  for k in 2..<8 {
    for l in 2..<8 {
      if ramsey_rec_bound(k, l) != ramsey_rec_bound(l, k) {
        sym = false
      }
    }
  }
  chk(out, "ramsey: recursion bound beats Erdős–Szekeres #8", sym)
  // 種子本身被窮舉複驗（不是憑空宣稱）
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #9",
    known_exact(3, 3) == Some(ramsey(3, 3)),
  )
  chk(
    out,
    "ramsey: recursion bound beats Erdős–Szekeres #10",
    known_exact(3, 4) == Some(ramsey(3, 4)),
  )
  out
}

///|
pub fn law_ramsey_ex_paley_graph_gives_r44_ge_18() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #1",
    paley_is_self_complementary(17),
  )
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #2",
    paley_qr(17).length() == 8,
  )
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #3",
    paley_edges(17).length() == 68,
  )
  // 核心：P₁₇ 既沒有紅色 K₄ 也沒有藍色 K₄
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #4",
    ramsey_check_coloring(4, 4, 17, paley_edges(17)),
  )
  // 自補性使它同時是 (4,5)-free 與 (5,4)-free
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #5",
    ramsey_check_coloring(4, 5, 17, paley_edges(17)),
  )
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #6",
    ramsey_check_coloring(5, 4, 17, paley_edges(17)),
  )
  // 檢查器不是橡皮章：全紅的 K₁₇ 立刻被否決
  let complete : Array[(Int32, Int32)] = []
  for i in 0..<17 {
    for j in (i + 1)..<17 {
      complete.push((i, j))
    }
  }
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #7",
    complete.length() == 136,
  )
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #8",
    !ramsey_check_coloring(4, 4, 17, complete),
  )
  // P₅ 是最小的自補 Paley 圖（C₅）
  chk(
    out,
    "ramsey: Paley graph gives R(4,4) ≥ 18 #9",
    paley_edges(5).length() == 5,
  )
  out
}

///|
pub fn law_ramsey_ex_r44_and_r35_are_pinned_exactly() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // R(4,4)：上界 18（遞迴 9+9），下界 18（Paley P₁₇）⇒ 夾死
  let p44 = ramsey_pin(4, 4)
  chk(out, "ramsey: R(4,4) and R(3,5) pinned exactly #1", p44.upper == 18)
  chk(out, "ramsey: R(4,4) and R(3,5) pinned exactly #2", p44.pinned)
  chk(out, "ramsey: R(4,4) and R(3,5) pinned exactly #3", p44.lower == 18)
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #4",
    p44.witness.length() == 68,
  )
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #5",
    ramsey_check_coloring(4, 4, 17, p44.witness),
  )
  // R(3,5)：上界 5+9 = 14（遞迴），下界 14（K₁₃ 見證，確定性局部搜尋產出後獨立複驗）
  let p35 = ramsey_pin(3, 5)
  chk(out, "ramsey: R(4,4) and R(3,5) pinned exactly #6", p35.upper == 14)
  chk(out, "ramsey: R(4,4) and R(3,5) pinned exactly #7", p35.pinned)
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #8",
    ramsey_check_coloring(3, 5, 13, p35.witness),
  )
  // 兩個值都超過舊版能算的範圍（舊版只到 R(3,4)=9）
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #9",
    ramsey_exact(4, 4) == Some(18),
  )
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #10",
    ramsey_exact(3, 5) == Some(14),
  )
  // 與窮舉法在小值上對帳
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #11",
    ramsey_exact(3, 3) == Some(6),
  )
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #12",
    ramsey_exact(3, 4) == Some(9),
  )
  // 夾不死就誠實回報 None（R(3,6) 的上界 20 未被見證夾死）
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #13",
    ramsey_exact(3, 6) == None,
  )
  chk(
    out,
    "ramsey: R(4,4) and R(3,5) pinned exactly #14",
    ramsey_upper(3, 6) == 20,
  )
  out
}

///|
pub fn law_ramsey_ex_ramsey_window_is_now_usable_up_to_d3() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 舊版 ramsey_window(3) 會去窮舉 R(4,4)（不可行）；現在窗口 = 可證上界 18
  chk(
    out,
    "ramsey: depth window now usable up to d=3 #1",
    ramsey_window(3) == 18,
  )
  chk(
    out,
    "ramsey: depth window now usable up to d=3 #2",
    ramsey_window(2) == 6,
  )
  chk(
    out,
    "ramsey: depth window now usable up to d=3 #3",
    ramsey_window(1) == 2,
  )
  chk(
    out,
    "ramsey: depth window now usable up to d=3 #4",
    ramsey_window(1) < ramsey_window(2) && ramsey_window(2) < ramsey_window(3),
  )
  // 窗口是「安全上界」：永遠 ≥ 精確值
  chk(
    out,
    "ramsey: depth window now usable up to d=3 #5",
    ramsey_window(3) >= 18,
  )
  chk(
    out,
    "ramsey: depth window now usable up to d=3 #6",
    ramsey_window(4) >= ramsey_window(3),
  )
  out
}
