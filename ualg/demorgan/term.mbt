// ---------------------------------------------------------------------------
// ualg/demorgan — 自由 De Morgan 代數 DM(n)：正規形、Kalman 語義、Dedekind 數
// ---------------------------------------------------------------------------
//
// [D-DNF]   元素 = 字面 {x_i, ¬x_i} 上的反鏈 DNF：子句是位元遮罩（位 2i = x_i，
//           位 2i+1 = ¬x_i），取 ⊆-極小者並排序。0 = []，1 = [∅]。
//           De Morgan 代數裡 x∧¬x ≠ 0，所以子句可以同時含 x_i 與 ¬x_i。
// [D-Tab]   語義 = 2n 個字面當獨立布林變數的單調函數真值表（UInt64，n ≤ 3）。
// [T-Kal]   Kalman (1958)：𝟜 生成 De Morgan 簇 ⇒ DM(n) ≅ 自由有界分配格 FD(2n)，
//           |DM(n)| = M(2n)（Dedekind 數）：6、168、7 828 354。
//           驗證：正規形閉包 = 真值表 = ualg/core 的 F_{V(𝟜)}(n)（三條路徑）。
// [A-Ded]   M(k) 兩條路徑：逐變數配對 (f0 ≤ f1)；區間公式
//           M(k) = Σ_{f,g∈M(k−2)} |↓(f∧g)|·|↑(f∨g)|。

///|
fn chk(out : Array[(String, Bool)], label : String, cond : Bool) -> Unit {
  out.push((label, cond))
}

///|
fn has(mask : Int32, i : Int32) -> Bool {
  ((mask >> i) & 1) == 1
}

///|
/// 取 ⊆-極小子句、去重、排序。
pub fn dnf_norm(cs : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for c in cs {
    let mut keep = true
    for d in cs {
      if d != c && (d & c) == d {
        keep = false
      }
    }
    if keep && !out.contains(c) {
      out.push(c)
    }
  }
  out.sort()
  out
}

///|
pub fn dnf_zero() -> Array[Int32] {
  []
}

///|
pub fn dnf_one() -> Array[Int32] {
  [0]
}

///|
pub fn dnf_var(i : Int32) -> Array[Int32] {
  [1 << (2 * i)]
}

///|
pub fn dnf_nvar(i : Int32) -> Array[Int32] {
  [1 << (2 * i + 1)]
}

///|
pub fn dnf_join(f : Array[Int32], g : Array[Int32]) -> Array[Int32] {
  let cs = f.copy()
  for c in g {
    cs.push(c)
  }
  dnf_norm(cs)
}

///|
pub fn dnf_meet(f : Array[Int32], g : Array[Int32]) -> Array[Int32] {
  let cs : Array[Int32] = []
  for c in f {
    for d in g {
      cs.push(c | d)
    }
  }
  dnf_norm(cs)
}

///|
/// De Morgan：¬(⋁_c ⋀_{l∈c} l) = ⋀_c ⋁_{l∈c} ¬l。
pub fn dnf_neg(f : Array[Int32]) -> Array[Int32] {
  let mut r = dnf_one()
  for c in f {
    let lits : Array[Int32] = []
    for b in 0..<30 {
      if has(c, b) {
        lits.push(1 << (b ^ 1))
      }
    }
    r = dnf_meet(r, lits)
  }
  r
}

///|
/// f ≤ g ⇔ f 的每個子句都包含 g 的某個子句。
pub fn dnf_leq(f : Array[Int32], g : Array[Int32]) -> Bool {
  for c in f {
    let mut ok = false
    for d in g {
      if (d & c) == d {
        ok = true
      }
    }
    if !ok {
      return false
    }
  }
  true
}

///|
pub fn dnf_key(f : Array[Int32]) -> String {
  @core.show_ints(f)
}

///|
pub fn dnf_show(f : Array[Int32]) -> String {
  if f.length() == 0 {
    return "0"
  }
  let sb = StringBuilder()
  for k, c in f {
    if k > 0 {
      sb.write_string(" ∨ ")
    }
    if c == 0 {
      sb.write_string("1")
    }
    let mut first = true
    for b in 0..<30 {
      if has(c, b) {
        if !first {
          sb.write_string("∧")
        }
        first = false
        if b % 2 == 1 {
          sb.write_string("¬")
        }
        sb.write_string("x\{b / 2}")
      }
    }
  }
  sb.to_string()
}

///|
/// 把字面遮罩裡每個 x_i 與 ¬x_i 互換。
pub fn flip_mask(c : Int32) -> Int32 {
  ((c & 0x15555555) << 1) | ((c >> 1) & 0x15555555)
}

///|
/// [D-Tab] 真值表：位 L（L 是「哪些字面為真」的遮罩）為 1 ⇔ 某個子句 ⊆ L。
pub fn dnf_table(f : Array[Int32], n : Int32) -> UInt64 {
  let mut t = 0UL
  for l in 0..<(1 << (2 * n)) {
    for c in f {
      if (c & l) == c {
        t = t | (1UL << l)
        break
      }
    }
  }
  t
}

///|
pub fn table_bit(t : UInt64, l : Int32) -> Bool {
  ((t >> l) & 1UL) == 1UL
}

///|
/// 單調真值表 → 正規形（極小真點）。
pub fn table_dnf(t : UInt64, n : Int32) -> Array[Int32] {
  let cs : Array[Int32] = []
  for l in 0..<(1 << (2 * n)) {
    if table_bit(t, l) {
      cs.push(l)
    }
  }
  dnf_norm(cs)
}

///|
/// (¬f)(a,b) = ¬f(¬b,¬a)：對偶再交換兩類字面。
pub fn table_neg(t : UInt64, n : Int32) -> UInt64 {
  let full = (1 << (2 * n)) - 1
  let mut r = 0UL
  for l in 0..<(1 << (2 * n)) {
    if !table_bit(t, flip_mask(l) ^ full) {
      r = r | (1UL << l)
    }
  }
  r
}

///|
/// 𝟜-語義（與 ualg/core 的 `alg_dm4` 同一編碼 (p,q) ↦ p+2q）：
/// 賦值 v_i = p_i + 2q_i 下的值 = F(P,¬Q) + 2·F(Q,¬P)。
pub fn table_dm4_tuple(t : UInt64, n : Int32) -> Array[Int32] {
  Array::makei(1 << (2 * n), idx => {
    let mut l1 = 0
    let mut l2 = 0
    for i in 0..<n {
      let p = (idx >> (2 * i)) & 1
      let q = (idx >> (2 * i + 1)) & 1
      l1 = l1 | (p << (2 * i)) | ((1 - q) << (2 * i + 1))
      l2 = l2 | (q << (2 * i)) | ((1 - p) << (2 * i + 1))
    }
    (if table_bit(t, l1) { 1 } else { 0 }) +
    (if table_bit(t, l2) { 2 } else { 0 })
  })
}

///|
/// DM(n) 的全部元素：由 0、1、x_i、¬x_i 在 ∧、∨、¬ 下的閉包（n ≤ 2 可列舉）。
pub fn dm_elements(n : Int32) -> Array[Array[Int32]] {
  let elems : Array[Array[Int32]] = [dnf_zero(), dnf_one()]
  for i in 0..<n {
    elems.push(dnf_var(i))
    elems.push(dnf_nvar(i))
  }
  let index : Map[String, Int32] = Map([])
  for i, e in elems {
    index[dnf_key(e)] = i
  }
  let add = (e : Array[Int32]) => {
    let k = dnf_key(e)
    if !index.contains(k) {
      index[k] = elems.length()
      elems.push(e)
    }
  }
  let mut i = 0
  while i < elems.length() {
    add(dnf_neg(elems[i]))
    for j in 0..<=i {
      add(dnf_meet(elems[i], elems[j]))
      add(dnf_join(elems[i], elems[j]))
    }
    i = i + 1
  }
  elems
}

///|
/// 元素 → 序號。
pub fn dm_index(elems : Array[Array[Int32]]) -> Map[String, Int32] {
  let index : Map[String, Int32] = Map([])
  for i, e in elems {
    index[dnf_key(e)] = i
  }
  index
}

///|
/// k 個變數的全部單調布林函數（真值表 2^k 位；k ≤ 5）。
pub fn monotone_tables(k : Int32) -> Array[UInt64] {
  let mut cur : Array[UInt64] = [0UL, 1UL]
  for v in 0..<k {
    let half = 1 << v
    let next : Array[UInt64] = []
    for f1 in cur {
      for f0 in cur {
        if (f0 & f1) == f0 {
          next.push(f0 | (f1 << half))
        }
      }
    }
    cur = next
  }
  cur
}

///|
/// [A-Ded] 路徑一：M(k) = #{(f0,f1) ∈ M(k−1)² : f0 ≤ f1}。
pub fn dedekind_by_pairs(k : Int32) -> Int64 {
  if k == 0 {
    return 2L
  }
  let ms = monotone_tables(k - 1)
  let mut c = 0L
  for f1 in ms {
    for f0 in ms {
      if (f0 & f1) == f0 {
        c = c + 1L
      }
    }
  }
  c
}

///|
/// [A-Ded] 路徑二：M(k) = Σ_{f,g ∈ M(k−2)} |↓(f∧g)|·|↑(f∨g)|（k ≥ 2）。
pub fn dedekind_by_intervals(k : Int32) -> Int64 {
  let ms = monotone_tables(k - 2)
  let index : Map[UInt64, Int32] = Map([])
  for i, f in ms {
    index[f] = i
  }
  let down = Array::make(ms.length(), 0L)
  let up = Array::make(ms.length(), 0L)
  for i, f in ms {
    for g in ms {
      if (g & f) == g {
        down[i] = down[i] + 1L
      }
      if (g & f) == f {
        up[i] = up[i] + 1L
      }
    }
  }
  let mut total = 0L
  for f in ms {
    for g in ms {
      match (index.get(f & g), index.get(f | g)) {
        (Some(a), Some(b)) => total = total + down[a] * up[b]
        _ => return -1L
      }
    }
  }
  total
}

///|
/// 路徑三（k ≤ 4）：窮舉全部 2^(2^k) 張真值表，逐一檢查單調性。
pub fn monotone_count_bruteforce(k : Int32) -> Int32 {
  let points = 1 << k
  let mut c = 0
  for t in 0..<(1 << points) {
    let mut mono = true
    for l in 0..<points {
      if has(t, l) {
        for v in 0..<k {
          if !has(t, l | (1 << v)) {
            mono = false
          }
        }
      }
    }
    if mono {
      c = c + 1
    }
  }
  c
}

///|
/// 定律：Dedekind 數的三條路徑。
pub fn law_dedekind_numbers_three_paths() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let expect : Array[Int64] = [2L, 3L, 6L, 20L, 168L, 7581L, 7828354L]
  let mut pairs = true
  let mut lists = true
  for k in 0..<=6 {
    if dedekind_by_pairs(k) != expect[k] {
      pairs = false
    }
    if k <= 5 && monotone_tables(k).length().to_int64() != expect[k] {
      lists = false
    }
  }
  chk(
    out,
    "Dedekind 數（配對 f0 ≤ f1）：M(0..6) = 2, 3, 6, 20, 168, 7581, 7 828 354；k ≤ 5 的真值表清單長度一致",
    pairs && lists,
  )
  let mut intervals = true
  for k in 2..<=6 {
    if dedekind_by_intervals(k) != expect[k] {
      intervals = false
    }
  }
  chk(
    out,
    "區間公式 M(k) = Σ_{f,g∈M(k−2)} |↓(f∧g)|·|↑(f∨g)| 對 k = 2..6 給出相同的數（M(6) 只用 168² 項）",
    intervals,
  )
  let mut brute = true
  for k in 0..<=4 {
    if monotone_count_bruteforce(k).to_int64() != expect[k] {
      brute = false
    }
  }
  chk(out, "窮舉全部 2^(2^k) 張真值表逐一驗單調（k ≤ 4，65 536 張）：計數相同", brute)
  out
}

///|
/// 定律：DM(n) 的正規形是典範的（Kalman 定理的三條路徑）。
pub fn law_demorgan_normal_form_kalman() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let sizes : Array[Int32] = []
  let free_sizes : Array[Int32] = []
  let mut iso = true
  let mut round = true
  let mut kalman = true
  let mut axioms = true
  for n in 1..<=2 {
    let elems = dm_elements(n)
    sizes.push(elems.length())
    let tabs = elems.map(e => dnf_table(e, n))
    let seen : Map[UInt64, Bool] = Map([])
    for t in tabs {
      seen[t] = true
    }
    if seen.length() != elems.length() {
      iso = false
    }
    // 正規形運算 = 真值表運算
    for i, f in elems {
      if table_dnf(tabs[i], n) != f {
        round = false
      }
      if dnf_table(dnf_neg(f), n) != table_neg(tabs[i], n) {
        iso = false
      }
      if dnf_neg(dnf_neg(f)) != f {
        axioms = false
      }
      for j, g in elems {
        if dnf_table(dnf_meet(f, g), n) != (tabs[i] & tabs[j]) ||
          dnf_table(dnf_join(f, g), n) != (tabs[i] | tabs[j]) {
          iso = false
        }
        if dnf_neg(dnf_meet(f, g)) != dnf_join(dnf_neg(f), dnf_neg(g)) ||
          dnf_leq(f, g) != ((tabs[i] & tabs[j]) == tabs[i]) {
          axioms = false
        }
      }
    }
    // Kalman：與 ualg/core 的 F_{V(𝟜)}(n) 逐元素對上
    let cl = @core.free_algebra(@core.alg_dm4(), n, 1000)
    free_sizes.push(cl.elems.length())
    let keys : Map[String, Bool] = Map([])
    for t in cl.elems {
      keys[@core.tuple_key(t)] = true
    }
    let hit : Map[String, Bool] = Map([])
    for t in tabs {
      let k = @core.tuple_key(table_dm4_tuple(t, n))
      if !keys.contains(k) {
        kalman = false
      }
      hit[k] = true
    }
    if !cl.complete || hit.length() != cl.elems.length() {
      kalman = false
    }
  }
  chk(
    out,
    "|DM(1)|, |DM(2)| = \{@core.show_ints(sizes)} = M(2), M(4)（正規形在 ∧、∨、¬ 下的閉包）",
    sizes == [6, 168],
  )
  chk(
    out,
    "正規形 ↔ 單調真值表是代數同構：∧ ↦ &、∨ ↦ |、¬ ↦ 對偶換位，且真值表兩兩相異、可逆",
    iso && round,
  )
  chk(
    out,
    "Kalman：ualg/core 以泛代數閉包算出的 F_{V(𝟜)}(n) 大小 \{@core.show_ints(free_sizes)}，與正規形經 𝟜-語義逐元素一一對應",
    kalman && free_sizes == sizes,
  )
  chk(out, "De Morgan 公理：¬¬f = f、¬(f∧g) = ¬f∨¬g、序 ≤ 與真值表蘊涵一致（全部元素對）", axioms)
  let x = dnf_var(0)
  let nx = dnf_nvar(0)
  let y = dnf_var(1)
  let ny = dnf_nvar(1)
  chk(
    out,
    "反例對照：x∧¬x ≠ 0、x∨¬x ≠ 1（非布林）；x∧¬x ≰ y∨¬y（非 Kleene）——DM(n) 嚴格大於自由布林／Kleene 代數",
    dnf_meet(x, nx) != dnf_zero() &&
    dnf_join(x, nx) != dnf_one() &&
    !dnf_leq(dnf_meet(x, nx), dnf_join(y, ny)),
  )
  chk(
    out,
    "|DM(3)| = M(6) = \{dedekind_by_intervals(6)}（De Morgan 立方體範疇 Hom([3],[1]) 的大小）",
    dedekind_by_intervals(6) == 7828354L,
  )
  out
}
