// ---------------------------------------------------------------------------
// ualg/demorgan — De Morgan 立方體範疇 □_DM：代換、自同構群、仿射片段
// ---------------------------------------------------------------------------
//
// [D-Cube]  □_DM = De Morgan 代數的 Lawvere 理論：態射 [m] → [n] 是 n 個 m 元
//           DM 項（代換）；合成 = 代入。面、退化、對稱、連接 ∧/∨、反轉 ¬、
//           對角線都是它的態射。
// [T-Sub]   代換兩條路徑：正規形代入 = 真值表經字面賦值的拉回 Φ_σ。
// [T-Aut]   σ 可逆 ⇔ Φ_σ 是 {0,1}^{2n} 上的雙射；Aut([n]) = 超八面體群 B_n，
//           階 2ⁿ·n!（n=1,2 窮舉全部自同態；n=3 由生成元閉包）。
// [D-Aff]   仿射（read-once）元素：存在每個變數至多出現一次的項。
// [T-Gur]   Gurvich 判準：正函數 read-once ⇔ 每個質蘊涵與每個對偶質蘊涵
//           恰交於一個變數；再加「同一變數不同時以兩種極性出現」。
// [T-AffC]  仿射態射對合成封閉（BCH 仿射立方體是 □_DM 的子範疇）；
//           對角線與 x∧¬x 不在其中（收縮規則正是差別所在）。

///|
/// 代入：f(x_i := σ_i)。
pub fn dnf_subst(
  f : Array[Int32],
  sigma : Array[Array[Int32]],
) -> Array[Int32] {
  let negs = sigma.map(dnf_neg)
  let mut r = dnf_zero()
  for c in f {
    let mut t = dnf_one()
    for i in 0..<sigma.length() {
      if has(c, 2 * i) {
        t = dnf_meet(t, sigma[i])
      }
      if has(c, 2 * i + 1) {
        t = dnf_meet(t, negs[i])
      }
    }
    r = dnf_join(r, t)
  }
  r
}

///|
/// 合成 τ∘σ：σ : [m] → [n]、τ : [n] → [k]。
pub fn mor_compose(
  tau : Array[Array[Int32]],
  sigma : Array[Array[Int32]],
) -> Array[Array[Int32]] {
  tau.map(f => dnf_subst(f, sigma))
}

///|
pub fn mor_id(n : Int32) -> Array[Array[Int32]] {
  Array::makei(n, i => dnf_var(i))
}

///|
pub fn mor_key(sigma : Array[Array[Int32]]) -> String {
  let sb = StringBuilder()
  for f in sigma {
    sb.write_string(dnf_key(f))
  }
  sb.to_string()
}

///|
/// Φ_σ：m 個變數的字面賦值 L ↦ n 個變數的字面賦值（σ_i 與 ¬σ_i 在 L 的值）。
pub fn lit_pullback(sigma : Array[Array[Int32]], m : Int32) -> Array[Int32] {
  let pos = sigma.map(f => dnf_table(f, m))
  let neg = sigma.map(f => dnf_table(dnf_neg(f), m))
  Array::makei(1 << (2 * m), l => {
    let mut r = 0
    for i in 0..<sigma.length() {
      if table_bit(pos[i], l) {
        r = r | (1 << (2 * i))
      }
      if table_bit(neg[i], l) {
        r = r | (1 << (2 * i + 1))
      }
    }
    r
  })
}

///|
/// 真值表層的代入：tt(f∘σ) = tt(f)∘Φ_σ。
pub fn table_pull(t : UInt64, phi : Array[Int32]) -> UInt64 {
  let mut r = 0UL
  for l, image in phi {
    if table_bit(t, image) {
      r = r | (1UL << l)
    }
  }
  r
}

///|
/// [T-Aut] σ : [n] → [n] 可逆 ⇔ Φ_σ 是雙射。
pub fn mor_is_iso(sigma : Array[Array[Int32]], n : Int32) -> Bool {
  if sigma.length() != n {
    return false
  }
  let phi = lit_pullback(sigma, n)
  let hit = Array::make(phi.length(), false)
  for v in phi {
    if hit[v] {
      return false
    }
    hit[v] = true
  }
  true
}

///|
/// 由生成元在合成下的閉包（有限群）。
pub fn mor_group(
  gens : Array[Array[Array[Int32]]],
  n : Int32,
) -> Array[Array[Array[Int32]]] {
  let elems : Array[Array[Array[Int32]]] = [mor_id(n)]
  let seen : Map[String, Bool] = Map([])
  seen[mor_key(elems[0])] = true
  let mut i = 0
  while i < elems.length() {
    for g in gens {
      let h = mor_compose(elems[i], g)
      let k = mor_key(h)
      if !seen.contains(k) {
        seen[k] = true
        elems.push(h)
      }
    }
    i = i + 1
  }
  elems
}

///|
/// 變數支撐（位 i ⇔ x_i 或 ¬x_i 出現）。
pub fn dnf_vars(f : Array[Int32]) -> Int32 {
  let mut lits = 0
  for c in f {
    lits = lits | c
  }
  let mut v = 0
  for i in 0..<15 {
    if ((lits >> (2 * i)) & 3) != 0 {
      v = v | (1 << i)
    }
  }
  v
}

///|
/// 把字面當獨立正變數時的對偶函數（質蘊涵 = 極小橫截）。
pub fn dnf_dual(f : Array[Int32]) -> Array[Int32] {
  dnf_norm(dnf_neg(f).map(flip_mask))
}

///|
/// [T-Gur] 仿射判定。
pub fn is_affine(f : Array[Int32]) -> Bool {
  let mut lits = 0
  for c in f {
    lits = lits | c
  }
  if (lits & (lits >> 1) & 0x15555555) != 0 {
    return false
  }
  let d = dnf_dual(f)
  for c in f {
    for e in d {
      if (c & e).popcnt() != 1 {
        return false
      }
    }
  }
  true
}

///|
/// 生成路徑：依變數支撐 S 作動態規劃，A[S] = 恰用到 S 的 read-once 元素。
/// 回傳 (全部仿射元素, 各支撐大小 k 的 |A[S]|)。
pub fn affine_elements(n : Int32) -> (Array[Array[Int32]], Array[Int32]) {
  let by_support : Array[Array[Array[Int32]]] = Array::makei(1 << n, _ => [])
  let per_size = Array::make(n + 1, 0)
  let all : Array[Array[Int32]] = [dnf_zero(), dnf_one()]
  per_size[0] = 2
  for s in 1..<(1 << n) {
    let found : Array[Array[Int32]] = []
    let seen : Map[String, Bool] = Map([])
    if s.popcnt() == 1 {
      let i = s.ctz()
      found.push(dnf_var(i))
      found.push(dnf_nvar(i))
    } else {
      let low = s & -s
      // 列舉 s 的真子集 s1 ∋ 最低位，s2 = s ∖ s1 非空
      let mut s1 = s
      while s1 > 0 {
        s1 = (s1 - 1) & s
        if s1 != 0 && (s1 & low) != 0 {
          let s2 = s ^ s1
          for f in by_support[s1] {
            for g in by_support[s2] {
              for h in [dnf_meet(f, g), dnf_join(f, g)] {
                let k = dnf_key(h)
                if !seen.contains(k) {
                  seen[k] = true
                  found.push(h)
                }
              }
            }
          }
        }
      }
    }
    by_support[s] = found
    per_size[s.popcnt()] = found.length()
    for f in found {
      all.push(f)
    }
  }
  (all, per_size)
}

///|
/// 態射是否仿射：各分量仿射且變數支撐兩兩不交。
pub fn mor_is_affine(sigma : Array[Array[Int32]]) -> Bool {
  let mut used = 0
  for f in sigma {
    let v = dnf_vars(f)
    if !is_affine(f) || (used & v) != 0 {
      return false
    }
    used = used | v
  }
  true
}

///|
/// 定律：代換的兩條路徑、範疇公理、立方恆等式。
pub fn law_cube_category_substitution() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let x = dnf_var(0)
  let y = dnf_var(1)
  let z = dnf_var(2)
  let nx = dnf_nvar(0)
  let ny = dnf_nvar(1)
  let zero = dnf_zero()
  let one = dnf_one()
  let elems = dm_elements(2)
  let tabs = elems.map(e => dnf_table(e, 2))
  let sample = [
    zero,
    one,
    x,
    nx,
    y,
    ny,
    dnf_meet(x, y),
    dnf_join(x, y),
    dnf_meet(x, nx),
    dnf_join(x, ny),
    dnf_join(dnf_meet(x, ny), dnf_meet(nx, y)),
    dnf_join(x, nx),
  ]
  let mut two_paths = true
  let mut count = 0
  for s0 in sample {
    for s1 in sample {
      let sigma = [s0, s1]
      let phi = lit_pullback(sigma, 2)
      for i, f in elems {
        count = count + 1
        if dnf_table(dnf_subst(f, sigma), 2) != table_pull(tabs[i], phi) {
          two_paths = false
        }
      }
    }
  }
  chk(
    out,
    "代換兩條路徑：正規形代入 = 真值表沿 Φ_σ 拉回（\{count} 組 (f,σ)，f 取遍 DM(2)）",
    two_paths,
  )
  let mut unit = true
  for f in elems {
    if dnf_subst(f, mor_id(2)) != f {
      unit = false
    }
  }
  let mut assoc = true
  let mut triples = 0
  for a in 0..<8 {
    for b in 0..<8 {
      let tau = [sample[a], sample[b]]
      for c in 0..<6 {
        for d in 0..<6 {
          let sigma = [sample[c + 4], sample[d + 6]]
          if mor_key(mor_compose(mor_id(2), sigma)) != mor_key(sigma) {
            unit = false
          }
          let ts = mor_compose(tau, sigma)
          for f in sample {
            triples = triples + 1
            if dnf_subst(dnf_subst(f, tau), sigma) != dnf_subst(f, ts) {
              assoc = false
            }
          }
        }
      }
    }
  }
  chk(
    out,
    "範疇公理：f∘id = f、id∘σ = σ；結合律 (f∘τ)∘σ = f∘(τ∘σ)（\{triples} 組）",
    unit && assoc,
  )
  let conn_and = dnf_meet(x, y)
  let conn_or = dnf_join(x, y)
  let ids = [
    dnf_subst(conn_and, [one, y]) == y, // 連接的面
    dnf_subst(conn_and, [zero, y]) == zero,
    dnf_subst(conn_or, [zero, y]) == y,
    dnf_subst(conn_or, [one, y]) == one,
    dnf_subst(nx, [zero]) == one, // 反轉交換兩個端點
    dnf_subst(nx, [one]) == zero,
    dnf_subst(y, [zero, y]) == y, // 退化後取面 = 恆等
    dnf_subst(conn_and, [x, x]) == x, // 對角線：冪等
    dnf_subst(conn_or, [x, x]) == x,
    dnf_subst(conn_and, [y, x]) == conn_and, // 對稱
    dnf_subst(nx, [nx]) == x, // 反轉是對合
    dnf_subst(conn_and, [nx, ny]) == dnf_neg(conn_or), // De Morgan
    dnf_subst(conn_and, [x, dnf_meet(y, z)]) ==
    dnf_subst(conn_and, [conn_and, z]), // 連接結合
    dnf_subst(conn_and, [x, conn_or]) == x, // 吸收
  ]
  let mut all_ids = true
  for b in ids {
    if !b {
      all_ids = false
    }
  }
  chk(
    out,
    "立方恆等式 \{ids.length()} 條：連接的面、反轉換端點、退化∘面 = id、對角冪等、對稱、反轉對合、De Morgan、結合、吸收",
    all_ids,
  )
  chk(
    out,
    "Hom 集大小：|Hom([0],[1])| = \{dm_elements(0).length()}（兩個端點）、|Hom([1],[1])| = \{dm_elements(1).length()}、|Hom([2],[2])| = \{elems.length() * elems.length()}",
    dm_elements(0).length() == 2 &&
    dm_elements(1).length() == 6 &&
    elems.length() * elems.length() == 28224,
  )
  out
}

///|
/// 定律：Aut([n]) 是超八面體群 B_n。
pub fn law_cube_automorphisms_hyperoctahedral() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let x = dnf_var(0)
  let y = dnf_var(1)
  let z = dnf_var(2)
  // n = 1：6 個自同態
  let e1 = dm_elements(1)
  let mut iso1 = 0
  for f in e1 {
    if mor_is_iso([f], 1) {
      iso1 = iso1 + 1
    }
  }
  // n = 2：28 224 個自同態，兩條路徑
  let e2 = dm_elements(2)
  let tabs = e2.map(e => dnf_table(e, 2))
  let isos : Array[Array[Array[Int32]]] = []
  let mut agree = true
  let mut endo = 0
  for f in e2 {
    for g in e2 {
      endo = endo + 1
      let sigma = [f, g]
      let phi = lit_pullback(sigma, 2)
      let hit = Array::make(16, false)
      let mut bij = true
      for v in phi {
        if hit[v] {
          bij = false
        }
        hit[v] = true
      }
      // 獨立路徑：σ* 在 DM(2) 的 168 個元素上是否單射
      let imgs = tabs.map(t => table_pull(t, phi))
      imgs.sort()
      let mut inj = true
      for i in 1..<imgs.length() {
        if imgs[i] == imgs[i - 1] {
          inj = false
        }
      }
      if bij != inj {
        agree = false
      }
      if bij {
        isos.push(sigma)
      }
    }
  }
  chk(
    out,
    "可逆判準兩條路徑：Φ_σ 雙射 ⇔ σ* 在 DM(2) 上單射（窮舉全部 \{endo} 個自同態）",
    agree,
  )
  let g2 = mor_group([[y, x], [dnf_nvar(0), y]], 2)
  let keys : Map[String, Bool] = Map([])
  for s in isos {
    keys[mor_key(s)] = true
  }
  let mut same = g2.length() == isos.length()
  for s in g2 {
    if !keys.contains(mor_key(s)) {
      same = false
    }
  }
  // 元素的階
  let orders : Array[Int32] = []
  let mut inverses = true
  for s in g2 {
    let mut k = 1
    let mut pw = s
    while mor_key(pw) != mor_key(mor_id(2)) && k < 10 {
      pw = mor_compose(pw, s)
      k = k + 1
    }
    orders.push(k)
    let mut found = false
    for t in isos {
      if mor_key(mor_compose(t, s)) == mor_key(mor_id(2)) &&
        mor_key(mor_compose(s, t)) == mor_key(mor_id(2)) {
        found = true
      }
    }
    if !found {
      inverses = false
    }
  }
  orders.sort()
  chk(
    out,
    "|Aut([1])| = \{iso1}（6 個自同態中）；|Aut([2])| = \{isos.length()}（\{endo} 個中），恰為「交換、反轉」生成的群，且各有雙邊逆",
    iso1 == 2 && isos.length() == 8 && same && inverses,
  )
  chk(
    out,
    "Aut([2]) 的元素階 \{@core.show_ints(orders)}：1 個恆等、5 個對合、2 個四階 ⇒ ≅ D₄ = B₂",
    orders == [1, 2, 2, 2, 2, 2, 4, 4],
  )
  let g3 = mor_group([[y, x, z], [y, z, x], [dnf_nvar(0), y, z]], 3)
  let mut all_iso = true
  for s in g3 {
    if !mor_is_iso(s, 3) {
      all_iso = false
    }
  }
  let a = [y, x, z]
  let b = [dnf_nvar(0), y, z]
  chk(
    out,
    "n = 3：「對換、三循環、反轉」生成 \{g3.length()} = 2³·3! 個代換，全部通過 Φ_σ 雙射判準（64 點）；群非交換",
    g3.length() == 48 &&
    all_iso &&
    mor_key(mor_compose(a, b)) != mor_key(mor_compose(b, a)),
  )
  chk(
    out,
    "反例對照：連接 (x∧y, x∨y)、對角 (x, x)、常值 (0, y) 都不可逆",
    !mor_is_iso([dnf_meet(x, y), dnf_join(x, y)], 2) &&
    !mor_is_iso([x, x], 2) &&
    !mor_is_iso([dnf_zero(), y], 2),
  )
  out
}

///|
/// 定律：仿射片段（read-once）——生成路徑對 Gurvich 判準。
pub fn law_affine_fragment_read_once() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let totals : Array[Int32] = []
  let mut two_paths = true
  let mut gurvich = true
  let mut per = [0]
  for n in 1..<=4 {
    let (aff, per_size) = affine_elements(n)
    totals.push(aff.length())
    per = per_size
    let keys : Map[String, Bool] = Map([])
    for f in aff {
      keys[dnf_key(f)] = true
      if !is_affine(f) {
        gurvich = false
      }
    }
    if n <= 2 {
      let mut c = 0
      for f in dm_elements(n) {
        if is_affine(f) {
          c = c + 1
          if !keys.contains(dnf_key(f)) {
            two_paths = false
          }
        }
      }
      if c != aff.length() {
        two_paths = false
      }
    }
  }
  chk(
    out,
    "仿射元素個數（生成路徑，n = 1..4）：\{@core.show_ints(totals)} = Σ_k C(n,k)·2^k·a(k)",
    totals == [4, 14, 96, 1146],
  )
  let a = Array::makei(4, k => per[k + 1] >> (k + 1))
  chk(
    out,
    "恰用 k 個有標變數的 read-once 正函數個數 a(1..4) = \{@core.show_ints(a)}（有標串並聯網路數 A006351）",
    a == [1, 2, 8, 52],
  )
  chk(
    out,
    "兩條路徑：n ≤ 2 時 Gurvich 判準在整個 DM(n) 上篩出的集合 = 生成的集合（6 中 4、168 中 14）",
    two_paths,
  )
  chk(out, "n = 3, 4：生成的 96 與 1146 個元素全部通過 Gurvich 判準", gurvich)
  let x0 = dnf_var(0)
  let x1 = dnf_var(1)
  let x2 = dnf_var(2)
  let x3 = dnf_var(3)
  let maj = dnf_join(
    dnf_join(dnf_meet(x0, x1), dnf_meet(x1, x2)),
    dnf_meet(x0, x2),
  )
  let p4 = dnf_join(
    dnf_join(dnf_meet(x0, x1), dnf_meet(x1, x2)),
    dnf_meet(x2, x3),
  )
  chk(
    out,
    "反例對照：多數函數、P₄ 函數 x0x1∨x1x2∨x2x3、x∧¬x 都不是仿射的；x0∧(x1∨x2) 是",
    !is_affine(maj) &&
    !is_affine(p4) &&
    !is_affine(dnf_meet(x0, dnf_nvar(0))) &&
    is_affine(dnf_meet(x0, dnf_join(x1, x2))),
  )
  // 仿射態射對合成封閉
  let (aff2, _) = affine_elements(2)
  let mors : Array[Array[Array[Int32]]] = []
  for f in aff2 {
    for g in aff2 {
      if mor_is_affine([f, g]) {
        mors.push([f, g])
      }
    }
  }
  let mut closed = true
  for t in mors {
    for s in mors {
      if !mor_is_affine(mor_compose(t, s)) {
        closed = false
      }
    }
  }
  chk(
    out,
    "仿射態射 [2] → [2] 共 \{mors.length()} 個，對合成封閉（\{mors.length() * mors.length()} 組全驗）⇒ 仿射立方體是 □_DM 的子範疇",
    closed,
  )
  chk(
    out,
    "收縮正是差別：對角 (x, x) 非仿射；連接∘(id,¬)∘對角 = \{dnf_show(dnf_subst(dnf_meet(x0, x1), [x0, dnf_nvar(0)]))} 離開仿射片段",
    !mor_is_affine([x0, x0]) &&
    !is_affine(dnf_subst(dnf_meet(x0, x1), [x0, dnf_nvar(0)])),
  )
  out
}
