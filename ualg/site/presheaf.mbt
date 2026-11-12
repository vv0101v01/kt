// ---------------------------------------------------------------------------
// ualg/site — 預層模板：預層、匹配族、j-層、層化（左伴隨）
// ---------------------------------------------------------------------------
//
// [D-Psh]   預層 F : P^op → FinSet：|F(x)| 與限制映射 res[y][x] : F(y) → F(x)（x ≤ y）。
// [D-Cov]   核子 j 誘導 Grothendieck 拓撲：篩 S ⊆ ↓x 覆蓋 x ⇔ x ∈ j(S)。
// [D-Shf]   F 是 j-層 ⇔ 對每個覆蓋篩 S，F(x) → Match(S,F) 是雙射。
// [A-Plus]  有限時覆蓋篩有最小者 S_x（j 保有限交），F⁺(x) = Match(S_x, F)；
//           層化 a(F) = F⁺⁺，單位 η : F → aF。
// [T-Adj]   a ⊣ i：對層 G，|Nat(aF, G)| = |Nat(F, G)|（以窮舉自然變換計數驗證）。
// [T-DN]    j = ¬¬：a(F)(x) = ∏_{極小 v ≤ x} F(v)；Sh_¬¬ ≃ Set^{極小元}（布林）。

///|
pub(all) struct Presheaf {
  size : Array[Int32]
  res : Array[Array[Array[Int32]]]
}

///|
pub fn psh_make(
  p : Poset,
  size : Array[Int32],
  gen : (Int32, Int32, Int32) -> Int32,
) -> Presheaf {
  {
    size,
    res: Array::makei(p.n, y => {
      Array::makei(p.n, x => {
        if leq(p, x, y) {
          Array::makei(size[y], s => gen(y, x, s))
        } else {
          []
        }
      })
    }),
  }
}

///|
/// 函子性：res[x][x] = id、res[y][x]∘res[z][y] = res[z][x]、值域合法。
pub fn psh_ok(p : Poset, f : Presheaf) -> Bool {
  for x in 0..<p.n {
    for y in 0..<p.n {
      if leq(p, x, y) {
        if f.res[y][x].length() != f.size[y] {
          return false
        }
        for s in 0..<f.size[y] {
          let v = f.res[y][x][s]
          if v < 0 || v >= f.size[x] || (x == y && v != s) {
            return false
          }
        }
        for z in 0..<p.n {
          if leq(p, y, z) {
            for s in 0..<f.size[z] {
              if f.res[y][x][f.res[z][y][s]] != f.res[z][x][s] {
                return false
              }
            }
          }
        }
      }
    }
  }
  true
}

///|
pub fn psh_const(p : Poset, k : Int32) -> Presheaf {
  psh_make(p, Array::make(p.n, k), (_, _, s) => s)
}

///|
/// 開集 u 當作子終對象（u = ↓x 時即可表預層 y(x)）。
pub fn psh_sub(p : Poset, u : Int32) -> Presheaf {
  psh_make(p, Array::makei(p.n, x => if bit(u, x) { 1 } else { 0 }), (_, _, _) => {
    0
  })
}

///|
/// Ω_j：x ↦ {↓x 上的 j-閉篩}，限制 = 與 ↓y 取交。j = id 時即子對象分類子 Ω。
pub fn psh_omega(
  p : Poset,
  opens : Array[Int32],
  j : (Int32) -> Int32,
) -> Presheaf {
  let sieves = Array::makei(p.n, x => {
    opens.filter(s => (s & p.down[x]) == s && (j(s) & p.down[x]) == s)
  })
  let find = (x : Int32, s : Int32) => {
    for i, t in sieves[x] {
      if t == s {
        return i
      }
    }
    -1
  }
  psh_make(p, Array::makei(p.n, x => sieves[x].length()), (y, x, s) => {
    find(x, sieves[y][s] & p.down[x])
  })
}

///|
/// 篩 s 上的全部匹配族（長度 |P|，篩外為 -1）。
pub fn matching_families(
  p : Poset,
  f : Presheaf,
  s : Int32,
) -> Array[Array[Int32]] {
  let ys : Array[Int32] = []
  for y in 0..<p.n {
    if bit(s, y) {
      ys.push(y)
    }
  }
  let out : Array[Array[Int32]] = []
  let cur = Array::make(p.n, -1)
  fn rec(k : Int32) -> Unit {
    if k == ys.length() {
      out.push(cur.copy())
      return
    }
    let y = ys[k]
    for v in 0..<f.size[y] {
      let mut ok = true
      for l in 0..<k {
        let z = ys[l]
        if leq(p, z, y) && f.res[y][z][v] != cur[z] {
          ok = false
        }
        if leq(p, y, z) && f.res[z][y][cur[z]] != v {
          ok = false
        }
      }
      if ok {
        cur[y] = v
        rec(k + 1)
        cur[y] = -1
      }
    }
  }

  rec(0)
  out
}

///|
/// x 的最小覆蓋篩 S_x = ⋂{S ⊆ ↓x 開 : x ∈ j(S)}。
pub fn least_cover(
  p : Poset,
  opens : Array[Int32],
  j : (Int32) -> Int32,
  x : Int32,
) -> Int32 {
  let mut s = p.down[x]
  for u in opens {
    let t = u & p.down[x]
    if bit(j(t), x) {
      s = s & t
    }
  }
  s
}

///|
fn fam_key(m : Array[Int32]) -> String {
  let sb = StringBuilder()
  for v in m {
    sb.write_string(v.to_string())
    sb.write_string(",")
  }
  sb.to_string()
}

///|
/// [D-Shf] 對**每個**覆蓋篩檢查雙射（定義本身，不取捷徑）。
pub fn is_sheaf(
  p : Poset,
  opens : Array[Int32],
  j : (Int32) -> Int32,
  f : Presheaf,
) -> Bool {
  for x in 0..<p.n {
    for u in opens {
      let s = u & p.down[x]
      if bit(j(s), x) {
        let fams = matching_families(p, f, s)
        if fams.length() != f.size[x] {
          return false
        }
        let seen : Map[String, Bool] = Map([])
        for t in 0..<f.size[x] {
          seen[fam_key(
            Array::makei(p.n, z => if bit(s, z) { f.res[x][z][t] } else { -1 }),
          )] = true
        }
        if seen.length() != f.size[x] {
          return false
        }
      }
    }
  }
  true
}

///|
/// [A-Plus] F⁺ 與單位 F → F⁺；第三個分量回報構造的前提（S_x ⊆ S_y）是否成立。
pub fn plus(
  p : Poset,
  opens : Array[Int32],
  j : (Int32) -> Int32,
  f : Presheaf,
) -> (Presheaf, Array[Array[Int32]], Bool) {
  let n = p.n
  let cover = Array::makei(n, x => least_cover(p, opens, j, x))
  let fams = Array::makei(n, x => matching_families(p, f, cover[x]))
  let index : Array[Map[String, Int32]] = Array::makei(n, _ => Map([]))
  for x in 0..<n {
    for i, m in fams[x] {
      index[x][fam_key(m)] = i
    }
  }
  let mut valid = true
  let lookup = (x : Int32, m : Array[Int32]) => {
    match index[x].get(fam_key(m)) {
      Some(i) => i
      None => {
        valid = false
        0
      }
    }
  }
  for x in 0..<n {
    for y in 0..<n {
      if leq(p, x, y) && (cover[x] & cover[y]) != cover[x] {
        valid = false
      }
    }
  }
  let g = psh_make(p, Array::makei(n, x => fams[x].length()), (y, x, s) => {
    lookup(
      x,
      Array::makei(n, z => if bit(cover[x], z) { fams[y][s][z] } else { -1 }),
    )
  })
  let unit = Array::makei(n, x => {
    Array::makei(f.size[x], t => {
      lookup(
        x,
        Array::makei(n, z => if bit(cover[x], z) { f.res[x][z][t] } else { -1 }),
      )
    })
  })
  (g, unit, valid)
}

///|
/// 層化 a(F) = F⁺⁺ 與單位 η。
pub fn sheafify(
  p : Poset,
  opens : Array[Int32],
  j : (Int32) -> Int32,
  f : Presheaf,
) -> (Presheaf, Array[Array[Int32]], Bool) {
  let (f1, u1, v1) = plus(p, opens, j, f)
  let (f2, u2, v2) = plus(p, opens, j, f1)
  let unit = Array::makei(p.n, x => {
    Array::makei(f.size[x], t => u2[x][u1[x][t]])
  })
  (f2, unit, v1 && v2)
}

///|
/// η 是否自然：η_x ∘ res^F = res^G ∘ η_y。
pub fn is_natural(
  p : Poset,
  f : Presheaf,
  g : Presheaf,
  eta : Array[Array[Int32]],
) -> Bool {
  for x in 0..<p.n {
    for y in 0..<p.n {
      if leq(p, x, y) {
        for s in 0..<f.size[y] {
          if eta[x][f.res[y][x][s]] != g.res[y][x][eta[y][s]] {
            return false
          }
        }
      }
    }
  }
  true
}

///|
pub fn is_iso(f : Presheaf, g : Presheaf, eta : Array[Array[Int32]]) -> Bool {
  for x in 0..<f.size.length() {
    if f.size[x] != g.size[x] {
      return false
    }
    let hit = Array::make(g.size[x], false)
    for v in eta[x] {
      if hit[v] {
        return false
      }
      hit[v] = true
    }
  }
  true
}

///|
/// 窮舉自然變換 F ⇒ G 的個數（逐點指派函數，與已指派的可比點檢查交換）。
pub fn count_nat(p : Poset, f : Presheaf, g : Presheaf) -> Int32 {
  let n = p.n
  let phi : Array[Array[Int32]] = Array::makei(n, _ => [])
  let mut count = 0
  fn rec(x : Int32) -> Unit {
    if x == n {
      count = count + 1
      return
    }
    let dom = f.size[x]
    let cod = g.size[x]
    let mut total = 1
    for _ in 0..<dom {
      total = total * cod
    }
    for code in 0..<total {
      let h = Array::make(dom, 0)
      let mut rest = code
      for i in 0..<dom {
        h[i] = rest % cod
        rest = rest / cod
      }
      let mut ok = true
      for y in 0..<x {
        if leq(p, y, x) {
          for s in 0..<dom {
            if g.res[x][y][h[s]] != phi[y][f.res[x][y][s]] {
              ok = false
            }
          }
        }
        if leq(p, x, y) {
          for s in 0..<f.size[y] {
            if g.res[y][x][phi[y][s]] != h[f.res[y][x][s]] {
              ok = false
            }
          }
        }
      }
      if ok {
        phi[x] = h
        rec(x + 1)
      }
    }
  }

  rec(0)
  count
}

///|
/// V 上的測試預層：F(v0), F(v1), F(e) 的大小與兩個端點映射。
fn psh_on_v(
  size : Array[Int32],
  to0 : Array[Int32],
  to1 : Array[Int32],
) -> Presheaf {
  psh_make(poset_v(), size, (y, x, s) => {
    if y == x {
      s
    } else if x == 0 {
      to0[s]
    } else {
      to1[s]
    }
  })
}

///|
/// 定律：預層模板——¬¬-層化是左伴隨、冪等，並給出明確公式。
pub fn law_presheaf_template_sheafification() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let p = poset_v()
  let opens = opens_all(p)
  let j = j_dneg(p)
  let id = (u : Int32) => u
  let fs = [
    psh_on_v([2, 3, 2], [0, 1], [0, 2]), // 一般
    psh_on_v([1, 1, 3], [0, 0, 0], [0, 0, 0]), // 非分離：三條邊同端點
    psh_on_v([2, 2, 0], [], []), // 邊上沒有截面
    psh_const(p, 2),
    psh_sub(p, 0b011), // 邊界（兩個端點）
    psh_omega(p, opens, id), // Ω 本身
    psh_const(p, 1), // 終對象（層）
    psh_sub(p, 0b001), // y(v0)（層）
    psh_omega(p, opens, j), // Ω_¬¬（層）
    psh_on_v([2, 3, 6], [0, 1, 0, 1, 0, 1], [0, 0, 1, 1, 2, 2]), // 積（層）
  ]
  let mut well = true
  let mut sheaf = true
  let mut formula = true
  let mut idem = true
  let mut iff = true
  let mut sheaf_count = 0
  for f in fs {
    let (af, eta, valid) = sheafify(p, opens, j, f)
    if !psh_ok(p, f) || !valid || !psh_ok(p, af) || !is_natural(p, f, af, eta) {
      well = false
    }
    if !is_sheaf(p, opens, j, af) {
      sheaf = false
    }
    if af.size != [f.size[0], f.size[1], f.size[0] * f.size[1]] {
      formula = false
    }
    let (aaf, eta2, _) = sheafify(p, opens, j, af)
    if !is_iso(af, aaf, eta2) {
      idem = false
    }
    let s = is_sheaf(p, opens, j, f)
    if s {
      sheaf_count = sheaf_count + 1
    }
    if s != is_iso(f, af, eta) {
      iff = false
    }
  }
  chk(
    out,
    "層化良構：\{fs.length()} 個預層的 F⁺⁺ 仍是預層、S_x ⊆ S_y 前提成立、單位 η : F → aF 自然",
    well,
  )
  chk(
    out, "aF 是 ¬¬-層（對每個覆蓋篩檢查匹配族雙射）", sheaf,
  )
  chk(
    out, "公式：V 上 a(F) 的大小 = [|F(v0)|, |F(v1)|, |F(v0)|·|F(v1)|]",
    formula,
  )
  chk(
    out, "冪等：a(aF) ≅ aF（aF 的單位逐點雙射）——即 j(j(p)) = j(p) 的預層版",
    idem,
  )
  chk(
    out,
    "F 是層 ⇔ η_F 是同構（\{fs.length()} 個中 \{sheaf_count} 個本來就是層）；Ω 本身不是 ¬¬-層",
    iff && sheaf_count == 4 && !is_sheaf(p, opens, j, fs[5]),
  )
  // 伴隨：|Nat(aF, G)| = |Nat(F, G)|，G 取遍層
  let omega_j = psh_omega(p, opens, j)
  let gs = [
    omega_j,
    sheafify(p, opens, j, fs[3]).0,
    sheafify(p, opens, j, psh_on_v([3, 1, 0], [], [])).0,
  ]
  let mut adj = true
  let nat : Array[Int32] = []
  for g in gs {
    if !is_sheaf(p, opens, j, g) {
      adj = false
    }
    for f in fs {
      let af = sheafify(p, opens, j, f).0
      if af.size[2] > 6 {
        continue
      }
      let a = count_nat(p, af, g)
      let b = count_nat(p, f, g)
      nat.push(b)
      if a != b {
        adj = false
      }
    }
  }
  chk(
    out,
    "a ⊣ i：對 3 個層 G（含 Ω_¬¬）與各預層 F，|Nat(aF,G)| = |Nat(F,G)|；計數 \{show_ints(nat)}",
    adj,
  )
  let f3 = fs[2]
  let af3 = sheafify(p, opens, j, f3).0
  let n_f = count_nat(p, f3, fs[5])
  let n_af = count_nat(p, af3, fs[5])
  chk(
    out,
    "反例對照：G = Ω 不是層時伴隨計數不等——|Nat(F,Ω)| = \{n_f} ≠ |Nat(aF,Ω)| = \{n_af}",
    n_f != n_af,
  )
  chk(
    out,
    "Ω_¬¬ 的大小 \{show_ints(omega_j.size)}：Ω_¬¬(e) = 4 = 2×2（布林），而 Ω(e) = \{fs[5].size[2]}",
    omega_j.size == [2, 2, 4] && fs[5].size == [2, 2, 5],
  )
  out
}

///|
/// 定律：其他拓撲的邊界情形，以及立方體上「層化把邊界填滿」。
pub fn law_sheaves_for_other_topologies() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let p = poset_v()
  let opens = opens_all(p)
  let fs = [
    psh_on_v([2, 3, 2], [0, 1], [0, 2]),
    psh_on_v([1, 1, 3], [0, 0, 0], [0, 0, 0]),
    psh_on_v([2, 2, 0], [], []),
    psh_const(p, 2),
  ]
  // j = id：平凡拓撲，每個預層都是層
  let id = (u : Int32) => u
  let mut triv = true
  // j = ⊤：只有終對象是層
  let top = (_ : Int32) => full_mask(p)
  let mut degenerate = true
  // 閉核子 c = {v0}：層 ⇔ F(v0) = 1（Sh_j ≃ PSh(P∖c)）
  let jc = j_closed(0b001)
  let mut closed = true
  for f in fs {
    let (a1, e1, v1) = sheafify(p, opens, id, f)
    if !v1 || !is_sheaf(p, opens, id, f) || !is_iso(f, a1, e1) {
      triv = false
    }
    let (a2, _, v2) = sheafify(p, opens, top, f)
    if !v2 || a2.size != [1, 1, 1] || !is_sheaf(p, opens, top, a2) {
      degenerate = false
    }
    let (a3, _, v3) = sheafify(p, opens, jc, f)
    if !v3 ||
      a3.size != [1, f.size[1], f.size[2]] ||
      !is_sheaf(p, opens, jc, a3) {
      closed = false
    }
  }
  chk(
    out,
    "三種核子都是核子：id、⊤、閉核子 u ↦ u∪{v0}",
    is_nucleus(opens, id) && is_nucleus(opens, top) && is_nucleus(opens, jc),
  )
  chk(
    out, "j = id（平凡拓撲）：每個預層都是層，η 是同構 ⇒ Sh_id = PSh",
    triv,
  )
  chk(
    out, "j = ⊤（退化拓撲）：a(F) 恆為終對象 [1,1,1] ⇒ Sh_⊤ = {1}",
    degenerate,
  )
  chk(
    out, "閉核子 c = {v0}：a(F) 的大小 = [1, |F(v1)|, |F(e)|] ⇒ Sh_j ≃ PSh(P∖c)",
    closed,
  )
  // 立方體 V²：¬¬-層化
  let q = poset_cube(2)
  let qo = opens_all(q)
  let jq = j_dneg(q)
  let boundary = full_mask(q) ^ (1 << 8)
  let (ab, _, vb) = sheafify(q, qo, jq, psh_sub(q, boundary))
  let (ac, _, vc) = sheafify(q, qo, jq, psh_const(q, 2))
  let mut prod = true
  for x in 0..<q.n {
    if ac.size[x] != 1 << (q.down[x] & minimals(q)).popcnt() {
      prod = false
    }
  }
  chk(
    out,
    "正方形 V²：a(∂□²) = □²（層化把邊界填滿，9 個面的截面數全為 1）；∂□² 本身不是層",
    vb &&
    ab.size == Array::make(9, 1) &&
    !is_sheaf(q, qo, jq, psh_sub(q, boundary)),
  )
  chk(
    out,
    "正方形 V²：a(Δ2)(x) = 2^{x 的頂點數}（頂點 2、邊 4、面 16）——a(F)(x) = ∏_{v ≤ x} F(v)",
    vc && prod && is_sheaf(q, qo, jq, ac),
  )
  // 可表預層 y(邊) 已是層
  let mut repr = true
  for x in 0..<q.n {
    if !is_sheaf(q, qo, jq, psh_sub(q, q.down[x])) {
      repr = false
    }
  }
  chk(
    out, "正方形 V²：9 個可表預層 y(x) 全是 ¬¬-層（拓撲是次典範的）",
    repr,
  )
  out
}
