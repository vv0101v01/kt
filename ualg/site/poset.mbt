// ---------------------------------------------------------------------------
// ualg/site — 有限偏序、Alexandrov 拓撲、開集的 Heyting 代數
// ---------------------------------------------------------------------------
//
// [D-Alex]  偏序 P 的 Alexandrov 拓撲：開集 = 下閉集（位元遮罩，|P| ≤ 30）。
//           取「下閉」為開，是為了讓立方體面偏序的開集恰為子複形。
// [T-Alex]  有限 T0 空間 ⇔ 有限偏序：特化序還原 ≤、最小鄰域是 ↓x、
//           連續映射 = 單調映射。
// [D-Hey]   u → v = {x : ↓x ∩ u ⊆ v}，¬u = u → ∅：開集構成 Heyting 代數（框架）。
// [A-Enum]  `opens_all`：沿線性延拓深搜，每個葉都是下閉集（無死路，輸出線性）。
//           兩條獨立計數路徑：`opens_count`（極大元遞迴＋備忘）與 2ⁿ 窮舉。

///|
pub(all) struct Poset {
  n : Int32
  down : Array[Int32]
  up : Array[Int32]
}

///|
pub fn bit(mask : Int32, i : Int32) -> Bool {
  ((mask >> i) & 1) != 0
}

///|
pub fn poset_from_leq(leq : Array[Array[Bool]]) -> Poset {
  let n = leq.length()
  let down = Array::make(n, 0)
  let up = Array::make(n, 0)
  for x in 0..<n {
    for y in 0..<n {
      if leq[x][y] {
        down[y] = down[y] | (1 << x)
        up[x] = up[x] | (1 << y)
      }
    }
  }
  { n, down, up }
}

///|
pub fn leq(p : Poset, x : Int32, y : Int32) -> Bool {
  bit(p.down[y], x)
}

///|
pub fn poset_ok(p : Poset) -> Bool {
  for x in 0..<p.n {
    if !leq(p, x, x) {
      return false
    }
    for y in 0..<p.n {
      if x != y && leq(p, x, y) && leq(p, y, x) {
        return false
      }
      for z in 0..<p.n {
        if leq(p, x, y) && leq(p, y, z) && !leq(p, x, z) {
          return false
        }
      }
    }
  }
  true
}

///|
pub fn poset_chain(n : Int32) -> Poset {
  poset_from_leq(Array::makei(n, x => Array::makei(n, y => x <= y)))
}

///|
pub fn poset_antichain(n : Int32) -> Poset {
  poset_from_leq(Array::makei(n, x => Array::makei(n, y => x == y)))
}

///|
/// 區間的面偏序 V：頂點 0、1 在下，邊 2 在上。
pub fn poset_v() -> Poset {
  poset_from_leq([
    [true, false, true],
    [false, true, true],
    [false, false, true],
  ])
}

///|
/// 直積偏序；(x,y) ↦ x + |P|·y。
pub fn poset_product(p : Poset, q : Poset) -> Poset {
  let n = p.n * q.n
  poset_from_leq(
    Array::makei(n, a => Array::makei(n, b => leq(p, a % p.n, b % p.n) &&
      leq(q, a / p.n, b / p.n))),
  )
}

///|
/// Vⁿ = n 維立方體的面偏序（3ⁿ 個面）。
pub fn poset_cube(n : Int32) -> Poset {
  let mut p = poset_chain(1)
  for _ in 0..<n {
    p = poset_product(p, poset_v())
  }
  p
}

///|
pub fn full_mask(p : Poset) -> Int32 {
  (1 << p.n) - 1
}

///|
pub fn is_open(p : Poset, u : Int32) -> Bool {
  for x in 0..<p.n {
    if bit(u, x) && (p.down[x] & u) != p.down[x] {
      return false
    }
  }
  true
}

///|
/// [A-Enum] 全部開集。
pub fn opens_all(p : Poset) -> Array[Int32] {
  let n = p.n
  // 線性延拓：依 |↓x| 遞增
  let order = Array::makei(n, i => i)
  order.sort_by((a, b) => p.down[a].popcnt() - p.down[b].popcnt())
  let out : Array[Int32] = []
  fn rec(k : Int32, cur : Int32) -> Unit {
    if k == n {
      out.push(cur)
      return
    }
    let x = order[k]
    rec(k + 1, cur)
    let below = p.down[x] ^ (1 << x)
    if (below & cur) == below {
      rec(k + 1, cur | (1 << x))
    }
  }

  rec(0, 0)
  out.sort()
  out
}

///|
/// 獨立計數：取剩餘元素中的極大元 x，N(S) = N(S∖{x}) + N(S∖↓x)。
pub fn opens_count(p : Poset) -> Int64 {
  let memo : Map[Int32, Int64] = Map([])
  fn rec(s : Int32) -> Int64 {
    if s == 0 {
      return 1L
    }
    match memo.get(s) {
      Some(v) => return v
      None => ()
    }
    let mut x = -1
    for i in 0..<p.n {
      if bit(s, i) && (p.up[i] & s) == (1 << i) {
        x = i
      }
    }
    let v = rec(s ^ (1 << x)) + rec(s & (p.down[x] ^ full_mask(p)))
    memo[s] = v
    v
  }

  rec(full_mask(p))
}

///|
/// [D-Hey] Heyting 蘊涵。
pub fn imp(p : Poset, u : Int32, v : Int32) -> Int32 {
  let nv = v ^ full_mask(p)
  let mut r = 0
  for x in 0..<p.n {
    if (p.down[x] & u & nv) == 0 {
      r = r | (1 << x)
    }
  }
  r
}

///|
pub fn hneg(p : Poset, u : Int32) -> Int32 {
  imp(p, u, 0)
}

///|
/// 極小元（原子點）的遮罩。
pub fn minimals(p : Poset) -> Int32 {
  let mut m = 0
  for x in 0..<p.n {
    if p.down[x] == (1 << x) {
      m = m | (1 << x)
    }
  }
  m
}

///|
/// 由開集族還原特化序：x ≤ y ⇔ 含 y 的開集都含 x。
pub fn specialization(opens : Array[Int32], n : Int32) -> Array[Array[Bool]] {
  Array::makei(n, x => Array::makei(n, y => {
    for u in opens {
      if bit(u, y) && !bit(u, x) {
        return false
      }
    }
    true
  }))
}

///|
fn chk(out : Array[(String, Bool)], label : String, cond : Bool) -> Unit {
  out.push((label, cond))
}

///|
fn show_ints(xs : Array[Int32]) -> String {
  let sb = StringBuilder()
  sb.write_string("[")
  for i, x in xs {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string(x.to_string())
  }
  sb.write_string("]")
  sb.to_string()
}

///|
fn sample_posets() -> Array[Poset] {
  [
    poset_chain(4),
    poset_antichain(3),
    poset_v(),
    poset_product(poset_chain(2), poset_chain(2)),
    poset_cube(2),
    poset_product(poset_v(), poset_chain(3)),
  ]
}

///|
/// 定律：Alexandrov 對應（有限 T0 空間 ⇔ 有限偏序）。
pub fn law_alexandrov_topology() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let mut topo = true
  let mut three = true
  let mut spec = true
  let mut nbhd = true
  let counts : Array[Int32] = []
  for p in sample_posets() {
    let opens = opens_all(p)
    counts.push(opens.length())
    let set : Map[Int32, Bool] = Map([])
    for u in opens {
      set[u] = true
    }
    // 拓撲公理：∅、P、有限交、有限併
    if !set.contains(0) || !set.contains(full_mask(p)) {
      topo = false
    }
    for u in opens {
      for v in opens {
        if !set.contains(u & v) || !set.contains(u | v) {
          topo = false
        }
      }
    }
    // 三條計數路徑
    let mut brute = 0
    for u in 0..<(1 << p.n) {
      if is_open(p, u) {
        brute = brute + 1
      }
    }
    if brute != opens.length() ||
      opens_count(p) != opens.length().to_int64() ||
      !poset_ok(p) {
      three = false
    }
    // 特化序還原 ≤（⇒ T0）
    let sp = specialization(opens, p.n)
    for x in 0..<p.n {
      for y in 0..<p.n {
        if sp[x][y] != leq(p, x, y) {
          spec = false
        }
      }
      // 最小鄰域 = ↓x
      let mut inter = full_mask(p)
      for u in opens {
        if bit(u, x) {
          inter = inter & u
        }
      }
      if inter != p.down[x] {
        nbhd = false
      }
    }
  }
  chk(
    out,
    "Alexandrov 拓撲公理：6 個偏序的下閉集族含 ∅、P，對 ∩、∪ 封閉；開集數 \{show_ints(counts)}",
    topo,
  )
  chk(
    out,
    "開集計數三條路徑相同：線性延拓深搜 = 極大元遞迴 N(S)=N(S∖x)+N(S∖↓x) = 2ⁿ 窮舉",
    three,
  )
  chk(out, "特化序還原偏序（故為 T0）；x 的最小開鄰域 = ↓x", spec && nbhd)
  // 連續 = 單調：V → Chain3、Chain3 → V、V → V 的全部函數
  let mut cm = true
  let mut mono_total = 0
  let pairs = [
    (poset_v(), poset_chain(3)),
    (poset_chain(3), poset_v()),
    (poset_v(), poset_v()),
    (poset_product(poset_chain(2), poset_chain(2)), poset_v()),
  ]
  for pq in pairs {
    let (p, q) = pq
    let qo = opens_all(q)
    let mut total = 1
    for _ in 0..<p.n {
      total = total * q.n
    }
    for code in 0..<total {
      let f = Array::make(p.n, 0)
      let mut rest = code
      for i in 0..<p.n {
        f[i] = rest % q.n
        rest = rest / q.n
      }
      let mut mono = true
      for x in 0..<p.n {
        for y in 0..<p.n {
          if leq(p, x, y) && !leq(q, f[x], f[y]) {
            mono = false
          }
        }
      }
      let mut cont = true
      for v in qo {
        let mut pre = 0
        for x in 0..<p.n {
          if bit(v, f[x]) {
            pre = pre | (1 << x)
          }
        }
        if !is_open(p, pre) {
          cont = false
        }
      }
      if mono {
        mono_total = mono_total + 1
      }
      if mono != cont {
        cm = false
      }
    }
  }
  chk(
    out,
    "連續 ⇔ 單調：四組偏序間的全部函數逐一比對（其中單調者共 \{mono_total} 個）",
    cm,
  )
  out
}

///|
/// 定律：開集是 Heyting 代數；蘊涵是交的右伴隨。
pub fn law_heyting_algebra_of_opens() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let mut adj = true
  let mut triples = 0
  let mut lem_fail = 0
  let mut dn_fail = 0
  for p in sample_posets() {
    let opens = opens_all(p)
    if opens.length() > 60 {
      continue
    }
    for u in opens {
      if (u | hneg(p, u)) != full_mask(p) {
        lem_fail = lem_fail + 1
      }
      if hneg(p, hneg(p, u)) != u {
        dn_fail = dn_fail + 1
      }
      for v in opens {
        let uv = imp(p, u, v)
        if !is_open(p, uv) {
          adj = false
        }
        for w in opens {
          triples = triples + 1
          // w ∧ u ≤ v ⇔ w ≤ u → v
          if ((w & u & (v ^ full_mask(p))) == 0) != ((w & uv) == w) {
            adj = false
          }
        }
      }
    }
  }
  chk(
    out,
    "Heyting 伴隨：w∧u ≤ v ⇔ w ≤ (u→v)，且 u→v 是開集（\{triples} 組 (u,v,w) 窮舉）",
    adj,
  )
  chk(
    out,
    "內在邏輯非布林：排中律 u∨¬u = ⊤ 失敗 \{lem_fail} 次、雙重否定律 ¬¬u = u 失敗 \{dn_fail} 次（反鏈上兩者皆成立）",
    lem_fail > 0 && dn_fail > 0,
  )
  let anti = poset_antichain(3)
  let mut bool_ok = true
  for u in opens_all(anti) {
    if (u | hneg(anti, u)) != full_mask(anti) {
      bool_ok = false
    }
  }
  chk(out, "對照：反鏈（離散空間）的開集代數是布林代數，排中律成立", bool_ok)
  out
}
