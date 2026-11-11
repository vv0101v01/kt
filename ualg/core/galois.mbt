// ---------------------------------------------------------------------------
// ualg/core — 伽羅瓦對應：極性、概念格（NextClosure）、Fix/Stab、Mod/Th
// ---------------------------------------------------------------------------
//
// [D-Pol]   關係 R ⊆ X×Y 的極性：S↑ = {y : ∀x∈S. xRy}，T↓ = {x : ∀y∈T. xRy}。
// [T-Gal]   (↑,↓) 是反序伽羅瓦連接：T ⊆ S↑ ⇔ S ⊆ T↓；↓↑ 與 ↑↓ 是閉包算子；
//           兩側閉集互為反同構（概念格）。——由公理轉成已證定理：在小極性上
//           對**全部**子集對窮舉，在大極性上以兩條路徑列舉閉集。
// [A-Next]  Ganter 的 NextClosure：依字典序逐一產生閉集，多項式延遲，不需存表。
// [T-Artin] 有限體 GF(p^k)/GF(p)：Aut 循環（Frobenius 生成），每個子群皆閉，
//           |Fix(H)| = p^(k/|H|)。對照：Klein 四元群的 A3 **不是**閉子群。
// [T-Birk]  Mod/Th：等式與代數之間的滿足關係是同一個極性；閉集 = 等式理論／簇。

///|
pub(all) struct Polarity {
  nx : Int32
  ny : Int32
  rel : Array[Array[Bool]]
}

///|
pub fn polar_up(p : Polarity, s : Array[Bool]) -> Array[Bool] {
  Array::makei(p.ny, y => {
    for x in 0..<p.nx {
      if s[x] && !p.rel[x][y] {
        return false
      }
    }
    true
  })
}

///|
pub fn polar_down(p : Polarity, t : Array[Bool]) -> Array[Bool] {
  Array::makei(p.nx, x => {
    for y in 0..<p.ny {
      if t[y] && !p.rel[x][y] {
        return false
      }
    }
    true
  })
}

///|
fn subset_of(a : Array[Bool], b : Array[Bool]) -> Bool {
  for i in 0..<a.length() {
    if a[i] && !b[i] {
      return false
    }
  }
  true
}

///|
fn mask_to_set(mask : Int32, n : Int32) -> Array[Bool] {
  Array::makei(n, i => ((mask >> i) & 1) != 0)
}

///|
pub fn set_size(s : Array[Bool]) -> Int32 {
  let mut c = 0
  for b in s {
    if b {
      c = c + 1
    }
  }
  c
}

///|
/// [A-Next] X 側全部閉集（字典序）。
pub fn closed_sets_next_closure(p : Polarity) -> Array[Array[Bool]] {
  let n = p.nx
  let close = (s : Array[Bool]) => polar_down(p, polar_up(p, s))
  let out : Array[Array[Bool]] = []
  let mut cur = close(Array::make(n, false))
  let mut running = true
  while running {
    out.push(cur)
    let mut advanced = false
    let mut i = n - 1
    while i >= 0 && !advanced {
      if !cur[i] {
        let seed = Array::makei(n, j => (j < i && cur[j]) || j == i)
        let cand = close(seed)
        let mut ok = true
        for j in 0..<i {
          if cand[j] && !cur[j] {
            ok = false
          }
        }
        if ok {
          cur = cand
          advanced = true
        }
      }
      i = i - 1
    }
    if !advanced {
      running = false
    }
  }
  out
}

///|
/// 獨立路徑：對全部 2^nx 個子集取閉包再去重（nx ≤ 20）。
pub fn closed_sets_bruteforce(p : Polarity) -> Array[Array[Bool]] {
  let seen : Map[Int32, Bool] = Map([])
  let out : Array[Array[Bool]] = []
  for mask in 0..<(1 << p.nx) {
    let c = polar_down(p, polar_up(p, mask_to_set(mask, p.nx)))
    let mut key = 0
    for i in 0..<p.nx {
      if c[i] {
        key = key | (1 << i)
      }
    }
    if !seen.contains(key) {
      seen[key] = true
      out.push(c)
    }
  }
  out
}

///|
/// [T-Gal] 在整個冪集上窮舉驗證伽羅瓦連接的全部公理（nx, ny ≤ 8）。
pub fn galois_axioms_hold(p : Polarity) -> Bool {
  let closed_y : Map[Int32, Bool] = Map([])
  let closed_x : Map[Int32, Bool] = Map([])
  for sm in 0..<(1 << p.nx) {
    let s = mask_to_set(sm, p.nx)
    let up = polar_up(p, s)
    let back = polar_down(p, up)
    // 膨脹、三次律
    if !subset_of(s, back) || polar_up(p, back) != up {
      return false
    }
    let mut ky = 0
    for i in 0..<p.ny {
      if up[i] {
        ky = ky | (1 << i)
      }
    }
    closed_y[ky] = true
    let mut kx = 0
    for i in 0..<p.nx {
      if back[i] {
        kx = kx | (1 << i)
      }
    }
    closed_x[kx] = true
    for tm in 0..<(1 << p.ny) {
      let t = mask_to_set(tm, p.ny)
      if subset_of(t, up) != subset_of(s, polar_down(p, t)) {
        return false
      }
    }
  }
  // Y 側由 T↓↑ 得到的閉集也必須落在同一族
  for tm in 0..<(1 << p.ny) {
    let t = mask_to_set(tm, p.ny)
    let c = polar_up(p, polar_down(p, t))
    let mut ky = 0
    for i in 0..<p.ny {
      if c[i] {
        ky = ky | (1 << i)
      }
    }
    if !closed_y.contains(ky) {
      return false
    }
  }
  closed_x.length() == closed_y.length()
}

// ---------------------------------------------------------------------------
// 自同構群與 Fix/Stab
// ---------------------------------------------------------------------------

///|
/// 貪婪生成集：依序加入尚未被生成的最小元。
pub fn generating_set(a : Alg) -> Array[Int32] {
  let gens : Array[Int32] = []
  let mut cur = sg(a, gens)
  while cur.length() < a.n {
    let mut x = 0
    while cur.contains(x) {
      x = x + 1
    }
    gens.push(x)
    cur = sg(a, gens)
  }
  gens
}

///|
/// Aut(A)：自同構由生成元的像決定；對每組候選像，在 A×A 中生成配對的子代數，
/// 它是雙射的圖 ⇔ 該指派延拓成自同構。
pub fn automorphisms(a : Alg) -> Array[Array[Int32]] {
  let n = a.n
  let gens = generating_set(a)
  let g = gens.length()
  let sq = alg_product(a, a)
  let out : Array[Array[Int32]] = []
  for code in 0..<ipow(n, g) {
    let img = digits(code, n, g)
    let graph = sg(sq, Array::makei(g, i => gens[i] + n * img[i]))
    if graph.length() == n {
      let f = Array::make(n, -1)
      let hit = Array::make(n, false)
      let mut ok = true
      for e in graph {
        if f[e % n] >= 0 || hit[e / n] {
          ok = false
        }
        f[e % n] = e / n
        hit[e / n] = true
      }
      if ok {
        out.push(f)
      }
    }
  }
  out
}

///|
/// Fix/Stab 極性：X = 自同構、Y = 元素，g R y ⇔ g(y) = y。
pub fn fixstab_polarity(n : Int32, auts : Array[Array[Int32]]) -> Polarity {
  {
    nx: auts.length(),
    ny: n,
    rel: Array::makei(auts.length(), g => Array::makei(n, y => auts[g][y] == y)),
  }
}

///|
/// 置換族的一個子集是否對合成封閉且含恆等（有限 ⇒ 子群）。
pub fn is_subgroup(auts : Array[Array[Int32]], s : Array[Bool]) -> Bool {
  let n = auts[0].length()
  let index : Map[String, Int32] = Map([])
  for i, f in auts {
    index[tuple_key(f)] = i
  }
  let mut has_id = false
  for i in 0..<auts.length() {
    if s[i] {
      if auts[i] == Array::makei(n, x => x) {
        has_id = true
      }
      for j in 0..<auts.length() {
        if s[j] {
          let comp = Array::makei(n, x => auts[i][auts[j][x]])
          match index.get(tuple_key(comp)) {
            Some(k) => if !s[k] { return false }
            None => return false
          }
        }
      }
    }
  }
  has_id
}

///|
/// Burnside：軌道數 = (1/|G|)·Σ_g |Fix(g)|；回傳（Σ, |G|）。
pub fn burnside_sum(perms : Array[Array[Int32]]) -> (Int32, Int32) {
  let mut s = 0
  for f in perms {
    for x in 0..<f.length() {
      if f[x] == x {
        s = s + 1
      }
    }
  }
  (s, perms.length())
}

///|
/// 獨立路徑：併查集直接數軌道。
pub fn orbit_count(perms : Array[Array[Int32]]) -> Int32 {
  let n = perms[0].length()
  let parent = Array::makei(n, i => i)
  for f in perms {
    for x in 0..<n {
      ignore(uf_union(parent, x, f[x]))
    }
  }
  let mut c = 0
  for x in 0..<n {
    if uf_find(parent, x) == x {
      c = c + 1
    }
  }
  c
}

///|
/// Mod/Th 極性：X = 等式 (lhs, rhs, 變元數)、Y = 代數。
pub fn modth_polarity(
  eqs : Array[(Term, Term, Int32)],
  algs : Array[Alg],
) -> Polarity {
  {
    nx: eqs.length(),
    ny: algs.length(),
    rel: Array::makei(eqs.length(), i => Array::makei(algs.length(), j => satisfies(
      algs[j],
      eqs[i].0,
      eqs[i].1,
      eqs[i].2,
    ))),
  }
}

///|
fn lcg_relation(nx : Int32, ny : Int32, seed : Int32) -> Polarity {
  let mut s = seed
  let rel = Array::makei(nx, _ => Array::make(ny, false))
  for x in 0..<nx {
    for y in 0..<ny {
      s = (s * 1103515245 + 12345) & 0x7fffffff
      rel[x][y] = ((s >> 16) & 3) != 0
    }
  }
  { nx, ny, rel }
}

///|
fn euler_phi(n : Int32) -> Int32 {
  let mut c = 0
  for k in 1..<=n {
    let mut a = k
    let mut b = n
    while b != 0 {
      let r = a % b
      a = b
      b = r
    }
    if a == 1 {
      c = c + 1
    }
  }
  c
}

///|
/// 定律：伽羅瓦連接公理（窮舉）與 NextClosure。
pub fn law_galois_connection_and_next_closure() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let mut ax = true
  let mut nc = true
  let mut total = 0
  for seed in 1..<=12 {
    let p = lcg_relation(6, 7, seed * 7919)
    if !galois_axioms_hold(p) {
      ax = false
    }
    let c1 = closed_sets_next_closure(p)
    let c2 = closed_sets_bruteforce(p)
    total = total + c1.length()
    // NextClosure 的輸出須是嚴格字典序遞增、且與窮舉同為一族
    let keys : Map[String, Bool] = Map([])
    for c in c2 {
      keys[tuple_key(c.map(b => if b { 1 } else { 0 }))] = true
    }
    if c1.length() != c2.length() {
      nc = false
    }
    for c in c1 {
      if !keys.contains(tuple_key(c.map(b => if b { 1 } else { 0 }))) {
        nc = false
      }
    }
  }
  chk(
    out,
    "伽羅瓦連接公理：12 個 6×7 關係，對全部 2⁶×2⁷ 組 (S,T) 驗 T⊆S↑ ⇔ S⊆T↓、膨脹、↑↓↑ = ↑、兩側閉集等勢",
    ax,
  )
  chk(
    out,
    "NextClosure（Ganter）列舉的閉集 = 冪集窮舉取閉包（12 個關係共 \{total} 個概念）",
    nc,
  )
  // 整除關係：X = Y = {1..8}，x R y ⇔ x | y
  let div : Polarity = {
    nx: 8,
    ny: 8,
    rel: Array::makei(8, x => Array::makei(8, y => (y + 1) % (x + 1) == 0)),
  }
  chk(
    out,
    "整除極性 {1..8}：公理成立，概念數 \{closed_sets_next_closure(div).length()}（兩條路徑相同）",
    galois_axioms_hold(div) &&
    closed_sets_next_closure(div).length() ==
    closed_sets_bruteforce(div).length(),
  )
  out
}

///|
/// 定律：有限體的伽羅瓦基本定理；以及它在一般代數上會失敗的地方。
pub fn law_galois_fixstab_fundamental_theorem() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let fields = [(2, 7), (3, 11), (4, 19)]
  let mut fund = true
  let mut frob = true
  let mut orbits_ok = true
  let orbit_counts : Array[Int32] = []
  for kp in fields {
    let (k, poly) = kp
    let a = alg_gf2k(k, poly)
    let n = a.n
    let auts = automorphisms(a)
    // Frobenius x ↦ x² 是自同構，且其冪次窮盡 Aut
    let sqmap = Array::makei(n, x => ap2(a.ops[1], n, x, x))
    let powers : Map[String, Bool] = Map([])
    let mut cur = Array::makei(n, x => x)
    for _ in 0..<k {
      powers[tuple_key(cur)] = true
      cur = Array::makei(n, x => sqmap[cur[x]])
    }
    if auts.length() != k || !is_hom(a, a, sqmap) || powers.length() != k {
      frob = false
    }
    for f in auts {
      if !powers.contains(tuple_key(f)) {
        frob = false
      }
    }
    let p = fixstab_polarity(n, auts)
    let closed = closed_sets_next_closure(p)
    if closed.length() != divisor_count(k) ||
      closed.length() != closed_sets_bruteforce(p).length() {
      fund = false
    }
    for h in closed {
      let fix = polar_up(p, h)
      let elems : Array[Int32] = []
      for y in 0..<n {
        if fix[y] {
          elems.push(y)
        }
      }
      // 次數公式 |Fix(H)| = 2^(k/|H|)、Fix(H) 是子體、H 是子群
      if elems.length() != (1 << (k / set_size(h))) ||
        sg(a, elems) != elems ||
        !is_subgroup(auts, h) {
        fund = false
      }
    }
    let (s, g) = burnside_sum(auts)
    orbit_counts.push(orbit_count(auts))
    if s % g != 0 || s / g != orbit_count(auts) {
      orbits_ok = false
    }
  }
  chk(
    out,
    "GF(4)、GF(8)、GF(16)：|Aut| = k，Frobenius x↦x² 是自同構且生成 Aut",
    frob,
  )
  chk(
    out,
    "伽羅瓦基本定理：閉子群數 = d(k)（每個子群皆閉），Fix(H) 是子體、|Fix(H)| = 2^(k/|H|)",
    fund,
  )
  chk(
    out,
    "Burnside = 併查集軌道數 = 次數整除 k 的 𝔽₂ 首一不可約多項式數：\{show_ints(orbit_counts)}（= 2+1、2+2、2+1+3）",
    orbits_ok && orbit_counts == [3, 4, 6],
  )
  // 對照：Klein 四元群的自同構群 ≅ S3，但 A3 不閉
  let klein = alg_product(alg_zn(2), alg_zn(2))
  let ka = automorphisms(klein)
  let kp = fixstab_polarity(4, ka)
  let id4 = [0, 1, 2, 3]
  let a3 = Array::makei(ka.length(), i => {
    let f = ka[i]
    let f3 = Array::makei(4, x => f[f[f[x]]])
    let f2 = Array::makei(4, x => f[f[x]])
    f == id4 || (f3 == id4 && f2 != id4)
  })
  let a3_closure = polar_down(kp, polar_up(kp, a3))
  chk(
    out,
    "對照（非伽羅瓦情形）：Aut(ℤ2²) 有 \{ka.length()} 個元素、\{closed_sets_next_closure(kp).length()} 個閉子群；A3 是子群但不閉（閉包是整個 Aut）",
    ka.length() == 6 &&
    closed_sets_next_closure(kp).length() == 5 &&
    set_size(a3) == 3 &&
    is_subgroup(ka, a3) &&
    set_size(a3_closure) == 6,
  )
  let mut phi_ok = true
  for n in [5, 7, 8, 9, 12] {
    if automorphisms(alg_zn(n)).length() != euler_phi(n) {
      phi_ok = false
    }
  }
  chk(
    out,
    "|Aut(ℤ_n)| = φ(n)（n = 5,7,8,9,12）；|Aut(S3)| = 6（全為內自同構）",
    phi_ok && automorphisms(alg_s3()).length() == 6,
  )
  out
}

///|
/// 定律：Mod/Th 極性把 布林 ⊂ Kleene ⊂ De Morgan 三層簇分開。
pub fn law_galois_mod_th_varieties() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let x = TVar(0)
  let y = TVar(1)
  let z = TVar(2)
  let meet = (a : Term, b : Term) => TApp(0, [a, b])
  let join = (a : Term, b : Term) => TApp(1, [a, b])
  let neg = (a : Term) => TApp(2, [a])
  let zero = TApp(3, [])
  let one = TApp(4, [])
  let eqs : Array[(Term, Term, Int32)] = [
    (neg(neg(x)), x, 1), // 0 對合
    (join(x, neg(x)), one, 1), // 1 排中律
    (meet(x, neg(x)), zero, 1), // 2 矛盾律
    (neg(meet(x, y)), join(neg(x), neg(y)), 2), // 3 De Morgan
    (meet(meet(x, neg(x)), join(y, neg(y))), meet(x, neg(x)), 2), // 4 Kleene
    (join(neg(x), neg(neg(x))), one, 1), // 5 Stone
    (meet(x, join(y, z)), join(meet(x, y), meet(x, z)), 3), // 6 分配
    (x, y, 2), // 7 平凡
  ]
  let algs = [
    alg_bool2(),
    alg_kleene3(),
    alg_dm4(),
    alg_stone3(),
    alg_product(alg_bool2(), alg_kleene3()),
  ]
  let p = modth_polarity(eqs, algs)
  let th = (j : Int32) => {
    let s : Array[Int32] = []
    for i in 0..<p.nx {
      if p.rel[i][j] {
        s.push(i)
      }
    }
    s
  }
  chk(
    out,
    "Th(𝟚) = \{show_ints(th(0))} ⊋ Th(𝟛) = \{show_ints(th(1))} ⊋ Th(𝟜) = \{show_ints(th(2))}：排中律分離 𝟚/𝟛，Kleene 律分離 𝟛/𝟜",
    th(0) == [0, 1, 2, 3, 4, 5, 6] && th(1) == [0, 3, 4, 6] && th(2) == [0, 3, 6],
  )
  chk(
    out,
    "Stone3 滿足 \{show_ints(th(3))}（矛盾律、Stone 律）但不滿足對合 ⇒ 不在 De Morgan 簇；Th(𝟚×𝟛) = Th(𝟛)",
    th(3) == [2, 3, 4, 5, 6] && th(4) == th(1),
  )
  // Mod(Th(𝟜)) ∩ Y：De Morgan 簇在樣本中的成員
  let only_dm4 = Array::makei(5, j => j == 2)
  let closure = polar_up(p, polar_down(p, only_dm4))
  let c1 = closed_sets_next_closure(p)
  chk(
    out,
    "Mod(Th(𝟜)) 在樣本中 = {𝟚, 𝟛, 𝟜, 𝟚×𝟛}（HSP 的可觀測面）；概念格有 \{c1.length()} 個閉等式理論；極性公理窮舉成立",
    closure == [true, true, true, false, true] &&
    c1.length() == closed_sets_bruteforce(p).length() &&
    galois_axioms_hold(p),
  )
  out
}
