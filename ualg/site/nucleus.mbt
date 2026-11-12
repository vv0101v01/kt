// ---------------------------------------------------------------------------
// ualg/site — 核子（Lawvere–Tierney 拓撲 j）、雙重否定、子場所普查
// ---------------------------------------------------------------------------
//
// [D-Nuc]   j : Ω → Ω 是核子：u ≤ j(u)、j(j(u)) = j(u)、j(u∧v) = j(u)∧j(v)。
// [T-DN]    j = ¬¬ 是核子；¬¬u = {x : ↓x 的極小元全在 u}（「頂點決定」）。
// [T-Gliv]  Glivenko：Fix(¬¬) 是布林代數，同構於極小元的冪集（2^{#min} 個）。
// [T-Refl]  a = j : Ω → Fix(j) 是包含 i 的左伴隨且保有限交（層化在 Ω 上的影子）。
// [T-Subl]  有限偏序 P 的框架 O(P) 恰有 2^{|P|} 個核子（子場所 ↔ 點的子集）。
// [T-Isb]   Isbell 稠密性：滿足 j(∅) = ∅ 的核子中 ¬¬ 最大（最小稠密子場所）。

///|
pub fn is_nucleus(opens : Array[Int32], j : (Int32) -> Int32) -> Bool {
  let set : Map[Int32, Bool] = Map([])
  for u in opens {
    set[u] = true
  }
  for u in opens {
    let ju = j(u)
    if !set.contains(ju) || (u & ju) != u || j(ju) != ju {
      return false
    }
    for v in opens {
      if j(u & v) != (ju & j(v)) {
        return false
      }
    }
  }
  true
}

///|
pub fn j_dneg(p : Poset) -> (Int32) -> Int32 {
  u => hneg(p, hneg(p, u))
}

///|
/// [T-DN] 第二條路徑：直接由極小元寫出 ¬¬u。
pub fn dneg_via_atoms(p : Poset, u : Int32) -> Int32 {
  let m = minimals(p)
  let mut r = 0
  for x in 0..<p.n {
    let atoms = p.down[x] & m
    if (atoms & u) == atoms {
      r = r | (1 << x)
    }
  }
  r
}

///|
/// 閉核子 u ↦ u ∪ c。
pub fn j_closed(c : Int32) -> (Int32) -> Int32 {
  u => u | c
}

///|
/// 開核子 u ↦ (c → u)。
pub fn j_open(p : Poset, c : Int32) -> (Int32) -> Int32 {
  u => imp(p, c, u)
}

///|
pub fn fixed_points(opens : Array[Int32], j : (Int32) -> Int32) -> Array[Int32] {
  opens.filter(u => j(u) == u)
}

///|
/// [T-Subl] 全部核子（以「在 opens 上的取值表」表示）。子場所 S ⊆ Ω：
/// 含 ⊤、對 ∧ 封閉、且 ∀u∈Ω, s∈S: (u→s) ∈ S；j_S(u) = ⋂{s∈S : u ≤ s}。
pub fn all_nuclei(p : Poset, opens : Array[Int32]) -> Array[Array[Int32]] {
  let m = opens.length()
  let index : Map[Int32, Int32] = Map([])
  for i, u in opens {
    index[u] = i
  }
  let top = full_mask(p)
  let impt = Array::makei(m, i => {
    Array::makei(m, k => {
      match index.get(imp(p, opens[i], opens[k])) {
        Some(v) => v
        None => -1
      }
    })
  })
  let meet = Array::makei(m, i => {
    Array::makei(m, k => {
      match index.get(opens[i] & opens[k]) {
        Some(v) => v
        None => -1
      }
    })
  })
  let out : Array[Array[Int32]] = []
  for code in 0..<(1 << m) {
    let mut ok = match index.get(top) {
      Some(t) => bit(code, t)
      None => false
    }
    for s in 0..<m {
      if ok && bit(code, s) {
        for t in 0..<m {
          if bit(code, t) && !bit(code, meet[s][t]) {
            ok = false
          }
          if !bit(code, impt[t][s]) {
            ok = false
          }
        }
      }
    }
    if ok {
      out.push(
        Array::makei(m, i => {
          let mut r = top
          for s in 0..<m {
            if bit(code, s) && (opens[i] & opens[s]) == opens[i] {
              r = r & opens[s]
            }
          }
          r
        }),
      )
    }
  }
  out
}

///|
/// 定律：雙重否定核子、Glivenko、反射子格（預層模板在 Ω 上的部分）。
pub fn law_double_negation_nucleus() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let mut nuc = true
  let mut atoms = true
  let mut gliv = true
  let mut adj = true
  let mut lex = true
  let mut join_fail = 0
  let reg : Array[Int32] = []
  for p in [poset_v(), poset_cube(2), poset_product(poset_v(), poset_chain(3))] {
    let opens = opens_all(p)
    let j = j_dneg(p)
    if !is_nucleus(opens, j) {
      nuc = false
    }
    let fix = fixed_points(opens, j)
    reg.push(fix.length())
    if fix.length() != 1 << minimals(p).popcnt() {
      gliv = false
    }
    for u in opens {
      if j(u) != dneg_via_atoms(p, u) {
        atoms = false
      }
      for v in opens {
        if j(u | v) != (j(u) | j(v)) {
          join_fail = join_fail + 1
        }
        if j(u & v) != (j(u) & j(v)) {
          lex = false
        }
      }
      // a ⊣ i：j(u) ≤ v ⇔ u ≤ v（v 取遍正則開集）
      for v in fix {
        if ((j(u) & v) == j(u)) != ((u & v) == u) {
          adj = false
        }
      }
    }
    // 布林：補元在 Fix 內，u∧¬u = ∅，j(u∨¬u) = ⊤
    for u in fix {
      let c = hneg(p, u)
      if j(c) != c || (u & c) != 0 || j(u | c) != full_mask(p) {
        gliv = false
      }
    }
  }
  chk(
    out, "j = ¬¬ 是核子：u ≤ j(u)、j(j(u)) = j(u)、j(u∧v) = j(u)∧j(v)（V、V²、V×Chain3 的全部開集）",
    nuc,
  )
  chk(
    out, "¬¬u 的兩條路徑：Heyting 定義 = 「↓x 的極小元全在 u」",
    atoms,
  )
  chk(
    out,
    "Glivenko：正則開集數 \{show_ints(reg)} = 2^{#極小元}，且構成布林代數（補元、u∧¬u = ∅、j(u∨¬u) = ⊤）",
    gliv,
  )
  chk(
    out,
    "層化在 Ω 上：a = j 是包含 Fix(j) ↪ Ω 的左伴隨（j(u) ≤ v ⇔ u ≤ v），且保有限交",
    adj && lex,
  )
  chk(
    out,
    "反例對照：j 不保併——j(u∨v) ≠ j(u)∨j(v) 共 \{join_fail} 組（所以 Fix(j) 的併要再取一次 j）",
    join_fail > 0,
  )
  // 立方體：邊界 ∂□ⁿ 是 ¬¬-稠密的
  let mut dense = true
  for n in 1..<=3 {
    let p = poset_cube(n)
    let boundary = full_mask(p) ^ (1 << (p.n - 1))
    if !is_open(p, boundary) ||
      j_dneg(p)(boundary) != full_mask(p) ||
      p.down[p.n - 1] != full_mask(p) {
      dense = false
    }
  }
  chk(
    out, "立方體面偏序 Vⁿ（n = 1,2,3）：邊界 ∂□ⁿ 是開集且 ¬¬(∂□ⁿ) = ⊤（稠密）",
    dense,
  )
  out
}

///|
/// 定律：核子普查與 Isbell 稠密性定理。
pub fn law_nuclei_census_and_isbell() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let mut census = true
  let mut isbell = true
  let mut dense_count = true
  let counts : Array[Int32] = []
  for
    p in [
      poset_chain(3),
      poset_v(),
      poset_antichain(3),
      poset_product(poset_chain(2), poset_chain(2)),
      poset_chain(4),
    ] {
    let opens = opens_all(p)
    let nuclei = all_nuclei(p, opens)
    counts.push(nuclei.length())
    let index : Map[Int32, Int32] = Map([])
    for i, u in opens {
      index[u] = i
    }
    let lookup = (t : Array[Int32]) => {
      (u : Int32) => {
        match index.get(u) {
          Some(i) => t[i]
          None => -1
        }
      }
    }
    let dn = j_dneg(p)
    let mut dense = 0
    let mut has_dn = false
    for t in nuclei {
      if !is_nucleus(opens, lookup(t)) {
        census = false
      }
      if lookup(t)(0) == 0 {
        dense = dense + 1
        let mut same = true
        for i, u in opens {
          if (t[i] & dn(u)) != t[i] {
            isbell = false
          }
          if t[i] != dn(u) {
            same = false
          }
        }
        if same {
          has_dn = true
        }
      }
    }
    if nuclei.length() != 1 << p.n {
      census = false
    }
    if !has_dn || dense != 1 << (p.n - minimals(p).popcnt()) {
      dense_count = false
    }
  }
  chk(
    out,
    "核子普查：O(P) 的核子數 \{show_ints(counts)} = 2^{|P|}（Chain3、V、反鏈3、2×2、Chain4），每張表都通過核子公理",
    census,
  )
  chk(
    out,
    "Isbell：每個稠密核子（j(∅) = ∅）都逐點 ≤ ¬¬，且 ¬¬ 本身在其中；稠密核子數 = 2^{|P|−#極小元}",
    isbell && dense_count,
  )
  out
}
