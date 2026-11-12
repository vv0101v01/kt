///|
// K10 constructive federation bridges for the tenth federation `ualg`.
//
// Each edge below is a mathematical construction transporting an object or
// algorithm from `ualg` into another federation, then checking a derived
// theorem with an independent path and a negative control.  The report shape
// is the existing `FederationPairBridge`, but `holds` is computed from the
// construction itself, not from conjoining two unrelated health booleans.
//
// Edges:
//   K10-37 Ualg × Cubical   : face lattice ↔ dual-rail CCHM cofibration BDD
//   K10-38 Ualg × Symlib    : B₂ action on subcomplexes ↔ G-set marks/Burnside
//   K10-39 Ualg × Semiring  : congruence generation ↔ Boolean Kleene star
//   K10-40 Ualg × Topos     : cube opens ↔ Sieve64 Heyting/nucleus transport
//   K10-41 Ualg × Scheme    : cubical subcomplex ↔ Stanley–Reisner/Hilbert
//   K10-42 Ualg × Condensed : translation spectrum ↔ Roos–Milnor inverse limit
//   K10-43 Ualg × Discovery : cubical homology predicates ↔ SWAR implication lattice
//   K10-44 Ualg × Accel     : cubical boundary ↔ GF(2) SWAR RREF Betti
//   K10-45 Ualg × Meta      : congruence/Mal'cev ↔ meta/core relation algebra

///|
fn bit_at(x : Int32, i : Int32) -> Bool {
  ((x >> i) & 1) != 0
}

///|
fn ualg_face_formulas(n : Int32) -> Array[Array[Int32]] {
  let seen : Map[String, Bool] = Map([])
  let out : Array[Array[Int32]] = []
  for f in @udm.dm_elements(n) {
    let g = @udm.face_norm(f)
    let k = @udm.dnf_key(g)
    if !seen.contains(k) {
      seen[k] = true
      out.push(g)
    }
  }
  out
}

///|
fn dual_rail_valid_mask(m : @fb.BddManager, n : Int32) -> Int32 {
  let mut acc = @fb.bdd_dag_true(m)
  for i in 0..<n {
    let both = @fb.bdd_dag_and(
      m,
      @fb.bdd_dag_var(m, 2 * i),
      @fb.bdd_dag_var(m, 2 * i + 1),
    )
    acc = @fb.bdd_dag_and(m, acc, @fb.bdd_dag_not(m, both))
  }
  acc
}

///|
fn dnf_to_dual_rail(m : @fb.BddManager, f : Array[Int32], n : Int32) -> Int32 {
  let mut acc = @fb.bdd_dag_false(m)
  for c in f {
    if !@udm.clause_consistent(c) {
      continue
    }
    let mut term = @fb.bdd_dag_true(m)
    for i in 0..<n {
      if bit_at(c, 2 * i) {
        term = @fb.bdd_dag_and(m, term, @fb.bdd_dag_var(m, 2 * i))
      }
      if bit_at(c, 2 * i + 1) {
        term = @fb.bdd_dag_and(m, term, @fb.bdd_dag_var(m, 2 * i + 1))
      }
    }
    acc = @fb.bdd_dag_or(m, acc, term)
  }
  acc
}

///|
/// K10-37: the 48-element face lattice 𝔽(2) is faithfully represented by
/// dual-rail BDDs over the 3-valued CCHM domain (p,q) ∈ {(0,0),(1,0),(0,1)}.
/// The coordinate (0,0) is the free/interior face, so `x ∨ ¬x` is the boundary,
/// not top.  Existential/universal face quantifiers are Boolean quantifiers
/// over the two rails restricted to this valid domain.
pub fn construct_k10_ualg_cubical_face_bdd() -> FederationPairBridge {
  let n = 2
  let forms = ualg_face_formulas(n)
  let m = @fb.bdd_manager_new(2 * n)
  let valid = dual_rail_valid_mask(m, n)
  let roots : Array[Int32] = []
  for f in forms {
    roots.push(@fb.bdd_dag_and(m, dnf_to_dual_rail(m, f, n), valid))
  }
  let mut faithful = forms.length() == 48
  let seen : Map[Int32, Bool] = Map([])
  for r in roots {
    if seen.contains(r) {
      faithful = false
    }
    seen[r] = true
  }
  let mut order_ok = true
  for i in 0..<forms.length() {
    for j in 0..<forms.length() {
      let le_bdd = @fb.bdd_dag_and(m, roots[i], @fb.bdd_dag_not(m, roots[j])) ==
        0
      if le_bdd != @udm.dnf_leq(forms[i], forms[j]) {
        order_ok = false
      }
    }
  }
  let mut quant_ok = true
  let mut adj_ok = true
  let p = @usite.poset_cube(n)
  let opens = @usite.opens_all(p)
  let open_forms = opens.map(u => @udm.open_face(p, u, n))
  for i in 0..<n {
    let pi = @fb.bdd_dag_var(m, 2 * i)
    let qi = @fb.bdd_dag_var(m, 2 * i + 1)
    let invalid_i = @fb.bdd_dag_and(m, pi, qi)
    for a, f in open_forms {
      let raw = dnf_to_dual_rail(m, f, n)
      let ex_inner = @fb.bdd_dag_and(m, raw, @fb.bdd_dag_not(m, invalid_i))
      let ex = @fb.bdd_dag_exists(
        m,
        @fb.bdd_dag_exists(m, ex_inner, 2 * i),
        2 * i + 1,
      )
      let ex_root = @fb.bdd_dag_and(m, ex, valid)
      let fa_inner = @fb.bdd_dag_or(m, invalid_i, raw)
      let fa = @fb.bdd_dag_forall(
        m,
        @fb.bdd_dag_forall(m, fa_inner, 2 * i),
        2 * i + 1,
      )
      let fa_root = @fb.bdd_dag_and(m, fa, valid)
      let ex_ualg = @fb.bdd_dag_and(
        m,
        dnf_to_dual_rail(m, @udm.face_exists(f, i), n),
        valid,
      )
      let fa_ualg = @fb.bdd_dag_and(
        m,
        dnf_to_dual_rail(m, @udm.face_forall(f, i), n),
        valid,
      )
      if ex_root != ex_ualg || fa_root != fa_ualg {
        quant_ok = false
      }
      let ex_u = @udm.face_open(p, @udm.face_exists(f, i), n)
      let fa_u = @udm.face_open(p, @udm.face_forall(f, i), n)
      let u = opens[a]
      for b, psi in open_forms {
        if !@udm.face_mentions(psi, i) {
          let v = opens[b]
          if ((ex_u & v) == ex_u) != ((u & v) == u) {
            adj_ok = false
          }
          if ((v & fa_u) == v) != ((v & u) == v) {
            adj_ok = false
          }
        }
      }
    }
  }
  let boundary = @udm.dnf_join(@udm.dnf_var(0), @udm.dnf_nvar(0))
  let boundary_not_top = !@udm.dnf_leq(@udm.dnf_one(), boundary)
  let boundary_root = @fb.bdd_dag_and(
    m,
    dnf_to_dual_rail(m, boundary, 1),
    dual_rail_valid_mask(m, 1),
  )
  let top_root = @fb.bdd_dag_and(
    m,
    dnf_to_dual_rail(m, @udm.dnf_one(), 1),
    dual_rail_valid_mask(m, 1),
  )
  let negative_control = boundary_not_top && boundary_root != top_root
  let holds = faithful && order_ok && quant_ok && adj_ok && negative_control
  FederationPairBridge::{
    id: "K10-37",
    lhs: Ualg,
    rhs: Cubical,
    bridge_theorem: "𝔽(2) face lattice ↔ dual-rail CCHM cofibration BDD; ∃/∀ face quantifiers = Boolean rail quantifiers on the 3-valued valid domain",
    holds,
    quantitative_witness: "faces=\{forms.length()}/48, faithful=\{faithful}, order=\{order_ok}, quantifiers=\{quant_ok}, adjunction=\{adj_ok}, boundary≠top=\{negative_control}",
  }
}

///|
fn partition_to_relation(p : Array[Int32], n : Int32) -> Array[Array[Bool]] {
  Array::makei(n, i => Array::makei(n, j => p[i] == p[j]))
}

///|
fn relation_to_partition(r : Array[Array[Bool]], n : Int32) -> Array[Int32] {
  let labels = Array::makei(n, i => {
    let mut rep = i
    for j in 0..<i {
      if r[i][j] {
        rep = j
        break
      }
    }
    rep
  })
  @ucommon.part_norm(labels)
}

///|
/// Mal'cev lemma as a semiring algorithm: Cg(R) is the least equivalence
/// relation closed under all basic translations.  The equivalence-closure
/// step is `semiring/matrix` Boolean SWAR Kleene star; iterating it with the
/// translation-image step reaches the same congruence as the independent
/// Freese union-find generator in `ualg/core`.
fn boolean_kleene_relation(rel : Array[Array[Bool]]) -> Array[Array[Bool]] {
  let n = rel.length()
  let mat : @smat.Mat[@semialg.BoolSr] = @smat.Mat::new(
    n,
    n,
    @semialg.BoolSr::of(false),
  )
  for i in 0..<n {
    for j in 0..<n {
      if rel[i][j] {
        mat.set(i, j, @semialg.BoolSr::of(true))
      }
    }
  }
  let (closed, _) = @smat.closure_bool_swar(mat)
  Array::makei(n, i => Array::makei(n, j => closed.get(i, j).b))
}

///|
/// Mal'cev congruence generation as a least fixpoint:
///   E ← reflexive-symmetric-transitive closure of E ∪ { (t(x),t(y)) | (x,y)∈E, t basic translation }.
/// The equivalence-closure step is the Boolean SWAR Kleene star from
/// `semiring/matrix`; the translation step is `ualg/core` basic translations.
fn congruence_via_boolean_kleene(
  a : @ucommon.Alg,
  pairs : Array[(Int32, Int32)],
) -> Array[Int32] {
  let n = a.n
  let translations = @ucommon.basic_translations(a)
  let rel = Array::makei(n, _ => Array::make(n, false))
  for i in 0..<n {
    rel[i][i] = true
  }
  for pair in pairs {
    let (x, y) = pair
    rel[x][y] = true
    rel[y][x] = true
  }
  let mut current = boolean_kleene_relation(rel)
  for _ in 0..<(n * n + 1) {
    let next = current.map(r => r.copy())
    for x in 0..<n {
      for y in 0..<n {
        if current[x][y] {
          for t in translations {
            let u = t[x]
            let v = t[y]
            next[u][v] = true
            next[v][u] = true
          }
        }
      }
    }
    let closed = boolean_kleene_relation(next)
    if closed == current {
      return relation_to_partition(closed, n)
    }
    current = closed
  }
  relation_to_partition(current, n)
}

///|
pub fn construct_k10_ualg_semiring_congruence_kleene() -> FederationPairBridge {
  let algebras : Array[@ucommon.Alg] = [
    @ucommon.alg_zn(6),
    @ucommon.alg_chain(3),
    @ucommon.alg_m3(),
    @ucommon.alg_n5(),
    @ucommon.alg_bool2(),
    @ucommon.alg_product(@ucommon.alg_zn(2), @ucommon.alg_zn(2)),
  ]
  let mut checked = 0
  let mut agree = true
  for a in algebras {
    for x in 0..<a.n {
      for y in (x + 1)..<a.n {
        let pairs = [(x, y)]
        let freese = @ucommon.part_norm(@ucommon.cg(a, pairs))
        let kleene = congruence_via_boolean_kleene(a, pairs)
        checked = checked + 1
        if freese != kleene || !@ucommon.is_congruence(a, kleene) {
          agree = false
        }
      }
    }
  }
  let chain = @ucommon.alg_chain(3)
  let raw = @ucommon.part_norm([0, 1, 0])
  let raw_not_congruence = !@ucommon.is_congruence(chain, raw)
  let closed = congruence_via_boolean_kleene(chain, [(0, 2)])
  let negative_control = raw_not_congruence &&
    closed == @ucommon.part_full(chain.n) &&
    @ucommon.is_congruence(chain, closed)
  let holds = agree && checked > 0 && negative_control
  FederationPairBridge::{
    id: "K10-39",
    lhs: Ualg,
    rhs: Semiring,
    bridge_theorem: "Mal'cev congruence generation Cg(R) = least fixpoint of Boolean Kleene star ∘ basic-translation images; Freese union-find == SWAR semiring closure",
    holds,
    quantitative_witness: "principal_pairs=\{checked}, algebras=\{algebras.length()}, Freese==Kleene=\{agree}, Chain3(0,2)_raw_not_congruence=\{raw_not_congruence}, closed_full=\{negative_control}",
  }
}

///|
fn open_to_sieve64(
  cat : @sym.FinCat,
  sp : @tsite.SitePrecomp64,
  top : Int32,
  u : Int32,
) -> @tsite.Sieve64 {
  let mut mask = 0UL
  for f in 0..<cat.nmor {
    if cat.cod[f] == top && bit_at(u, cat.dom[f]) {
      mask = mask | (1UL << f)
    }
  }
  @tsite.sieve64_generate(sp, top, mask)
}

///|
fn sieve64_to_open(cat : @sym.FinCat, top : Int32, s : @tsite.Sieve64) -> Int32 {
  let mut u = 0
  let mut rem = s.mask
  while rem != 0UL {
    let f = rem.ctz()
    if cat.cod[f] == top {
      u = u | (1 << cat.dom[f])
    }
    rem = rem & (rem - 1UL)
  }
  u
}

///|
pub fn construct_k10_ualg_topos_cube_sieve64() -> FederationPairBridge {
  let n = 2
  let p = @usite.poset_cube(n)
  let opens = @usite.opens_all(p)
  let top = p.n - 1
  let edges : Array[(Int32, Int32)] = []
  for x in 0..<p.n {
    for y in 0..<p.n {
      if x != y && @usite.leq(p, x, y) {
        edges.push((x, y))
      }
    }
  }
  let cat = @sym.cat_poset(p.n, edges)
  let sp = @tsite.site_precomp64_build(cat)
  let sieves = @tsite.enumerate_sieves64_on_obj(sp, top)
  let j = @usite.j_dneg(p)
  let mut bijective = opens.length() == 48 && sieves.length() == 48
  let mapped : Array[@tsite.Sieve64] = []
  let seen : Map[UInt64, Bool] = Map([])
  for u in opens {
    let s = open_to_sieve64(cat, sp, top, u)
    mapped.push(s)
    if seen.contains(s.mask) {
      bijective = false
    }
    seen[s.mask] = true
    if sieve64_to_open(cat, top, s) != u {
      bijective = false
    }
  }
  let mut ops_ok = true
  for a in 0..<opens.length() {
    let u = opens[a]
    let su = mapped[a]
    if @tsite.sieve64_heyting_neg(sp, su) !=
      open_to_sieve64(cat, sp, top, @usite.hneg(p, u)) {
      ops_ok = false
    }
    if @tsite.sieve64_double_negation(sp, su) !=
      open_to_sieve64(cat, sp, top, j(u)) {
      ops_ok = false
    }
    if @tsite.sieve64_double_negation(sp, su) !=
      open_to_sieve64(cat, sp, top, @ucube.dneg_vertex(n, u)) {
      ops_ok = false
    }
    for b in 0..<opens.length() {
      let v = opens[b]
      let sv = mapped[b]
      if @tsite.sieve64_heyting_implies(sp, su, sv) !=
        open_to_sieve64(cat, sp, top, @usite.imp(p, u, v)) {
        ops_ok = false
      }
      if @tsite.sieve64_inter(su, sv) != open_to_sieve64(cat, sp, top, u & v) {
        ops_ok = false
      }
      if @tsite.sieve64_union(su, sv) != open_to_sieve64(cat, sp, top, u | v) {
        ops_ok = false
      }
    }
  }
  let full = @usite.full_mask(p)
  let boundary = full ^ (1 << top)
  let s_full = open_to_sieve64(cat, sp, top, full)
  let s_boundary = open_to_sieve64(cat, sp, top, boundary)
  let same_dneg = @tsite.sieve64_double_negation(sp, s_boundary) == s_full &&
    j(boundary) == full
  let distinct = s_boundary != s_full
  let mut join_failures = 0
  for u in opens {
    for v in opens {
      if j(u | v) != (j(u) | j(v)) {
        join_failures = join_failures + 1
      }
    }
  }
  let mut sheaf_ok = true
  for u in opens {
    let (af, _, valid) = @usite.sheafify(p, opens, j, @usite.psh_sub(p, u))
    if !valid {
      sheaf_ok = false
    }
    let expected = @ucube.vertex_closure(n, @ucube.open_vertex_mask(n, u))
    let mut sizes_ok = true
    for x in 0..<p.n {
      let want = if bit_at(expected, x) { 1 } else { 0 }
      if af.size[x] != want {
        sizes_ok = false
      }
    }
    if !sizes_ok {
      sheaf_ok = false
    }
  }
  let negative_control = same_dneg && distinct && join_failures > 0
  let holds = bijective && ops_ok && sheaf_ok && negative_control
  FederationPairBridge::{
    id: "K10-40",
    lhs: Ualg,
    rhs: Topos,
    bridge_theorem: "□² subcomplex opens ↔ Sieve64 on the top cube object; Heyting implication, ¬¬ nucleus and subterminal sheafification transport isomorphically",
    holds,
    quantitative_witness: "opens=\{opens.length()}/48, sieves=\{sieves.length()}/48, bijective=\{bijective}, ops=\{ops_ok}, sheafify=vertex_closure=\{sheaf_ok}, ∂□²~□²_under_¬¬=\{same_dneg}, join_failures=\{join_failures}",
  }
}

///|
fn spanning_face_code(vertices : Int32, n : Int32) -> Int32 {
  let mut code = 0
  for i in 0..<n {
    let mut all0 = true
    let mut all1 = true
    for v in 0..<(1 << n) {
      if bit_at(vertices, v) {
        if bit_at(v, i) {
          all0 = false
        } else {
          all1 = false
        }
      }
    }
    let d = if all0 { 0 } else if all1 { 1 } else { 2 }
    code = code + d * @udm.pow3(i)
  }
  code
}

///|
fn stanley_reisner_ideal_of_cubical(
  k : Array[Bool],
  n : Int32,
) -> @scheme.Ideal {
  let nv = 1 << n
  let gens : Array[@scheme.MPoly] = []
  let nonfaces : Array[Int32] = []
  for mask in 1..<(1 << nv) {
    let code = spanning_face_code(mask, n)
    if !k[code] {
      let mut minimal = true
      for prev in nonfaces {
        if (prev & mask) == prev {
          minimal = false
          break
        }
      }
      if minimal {
        nonfaces.push(mask)
        let mut mono = @scheme.mpoly_int(nv, 1)
        for v in 0..<nv {
          if bit_at(mask, v) {
            mono = @scheme.mpoly_mul(mono, @scheme.mpoly_var(nv, v))
          }
        }
        gens.push(mono)
      }
    }
  }
  @scheme.ideal_new(nv, gens)
}

///|
pub fn construct_k10_ualg_scheme_stanley_reisner() -> FederationPairBridge {
  let n = 2
  let boundary = @udm.cx_boundary(n)
  let full = @udm.cx_full(n)
  let ib = stanley_reisner_ideal_of_cubical(boundary, n)
  let ifull = stanley_reisner_ideal_of_cubical(full, n)
  let rb = @scheme.projective_hilbert_report(ib)
  let rf = @scheme.projective_hilbert_report(ifull)
  let betti_b = @udm.cx_betti(boundary, n, 0L)
  let betti_f = @udm.cx_betti(full, n, 0L)
  let hb2 = @scheme.projective_hilbert_function(ib, 2)
  let hf2 = @scheme.projective_hilbert_function(ifull, 2)
  let pb2 = @exactalg.qpoly_eval(rb.hilbert_poly, @exactalg.rat_int(2))
  let pf2 = @exactalg.qpoly_eval(rf.hilbert_poly, @exactalg.rat_int(2))
  let boundary_ok = rb.matches_hilbert_function &&
    rb.projective_dim == 1 &&
    rb.degree == 4 &&
    rb.arithmetic_genus == 1 &&
    hb2 == 8 &&
    @exactalg.rat_eq(pb2, @exactalg.rat_int(8)) &&
    betti_b == [1, 1] &&
    @udm.cx_euler(boundary, n) == 0
  let full_ok = rf.matches_hilbert_function &&
    rf.projective_dim == 3 &&
    rf.degree == 1 &&
    rf.arithmetic_genus == 0 &&
    hf2 == 10 &&
    @exactalg.rat_eq(pf2, @exactalg.rat_int(10)) &&
    betti_f == [1] &&
    @udm.cx_euler(full, n) == 1
  let negative_control = !@scheme.ideal_eq(ib, ifull) && betti_b != betti_f
  let holds = boundary_ok && full_ok && negative_control
  FederationPairBridge::{
    id: "K10-41",
    lhs: Ualg,
    rhs: Scheme,
    bridge_theorem: "Cubical subcomplex → vertex Stanley–Reisner ideal; ∂□² gives C₄ with P(t)=4t, deg=4, p_a=1, β=[1,1] (β₁=1), while □² gives the full simplex with cubic Hilbert polynomial",
    holds,
    quantitative_witness: "boundary(dim=\{rb.projective_dim},deg=\{rb.degree},genus=\{rb.arithmetic_genus},H(2)=\{hb2},β=\{@ucommon.show_ints(betti_b)}) full(dim=\{rf.projective_dim},deg=\{rf.degree},genus=\{rf.arithmetic_genus},H(2)=\{hf2},β=\{@ucommon.show_ints(betti_f)}) distinct=\{negative_control}",
  }
}

///|
pub fn construct_k10_ualg_condensed_translation_spectrum() -> FederationPairBridge {
  let a = @ucommon.alg_product(@ucommon.alg_zn(2), @ucommon.alg_zn(2))
  let auts = @ucommon.automorphisms(a)
  let mut perm_checked = 0
  let mut perm_ok = true
  for f in auts {
    let mat = @ucommon.functional_matrix(f)
    let chi = @ucommon.functional_charpoly(f)
    let (cycles, transient) = @ucommon.cycle_type(f)
    let root_mult = @ucommon.root_multiplicity(chi, 1)
    let z = @gcd.zmat_from_rows(mat)
    let (rank, torsion) = @condensed.rlim_zmat_endomorphism(z)
    perm_checked = perm_checked + 1
    if transient != 0 ||
      rank != cycles.length() ||
      root_mult != cycles.length() ||
      torsion.length() != 0 ||
      !@ucommon.charpoly_cross_checked(mat) {
      perm_ok = false
    }
  }
  // Contrast: tripling on Z² is an integer endomorphism, not a finite
  // permutation.  Its characteristic polynomial has no root at 1, but the
  // SNF cokernel of I−2I carries 2-torsion invisible to χ(1).
  let mat : Array[Array[BigInt]] = [[3N, 0N], [0N, 3N]]
  let chi = @ucommon.mat_charpoly(mat)
  let root_mult = @ucommon.root_multiplicity(chi, 1)
  let z = @gcd.zmat_from_rows(mat)
  let (rank, torsion) = @condensed.rlim_zmat_endomorphism(z)
  let id_minus = @gcd.zmat_make(2, 2, 0N)
  for i in 0..<2 {
    for j in 0..<2 {
      let base = if i == j { 1N } else { 0N }
      @gcd.zmat_set(id_minus, i, j, base - @gcd.zmat_get(z, i, j))
    }
  }
  let snf = @gcd.zmat_snf(id_minus)
  let snf_ok = @gcd.zmat_snf_verify(id_minus, snf)
  let general_ok = rank <= root_mult &&
    snf_ok &&
    @ucommon.charpoly_cross_checked(mat)
  let negative_control = torsion.length() > 0
  let holds = perm_ok && perm_checked == 6 && general_ok && negative_control
  FederationPairBridge::{
    id: "K10-42",
    lhs: Ualg,
    rhs: Condensed,
    bridge_theorem: "Finite translation spectrum χ_f(1) ↔ Roos–Milnor inverse limit of Z^n under f: permutations have lim0 rank = cycle count and no torsion; the integer endomorphism 3·I₂ has χ(1)≠0 yet SNF cokernel (Z/2)², separating spectral and inverse-limit invariants",
    holds,
    quantitative_witness: "GL(2,2)_auts=\{perm_checked}/6, perm_rank=cycles=root_mult=\{perm_ok}, Z²_×3(rank=\{rank},root_mult=\{root_mult},torsion=\{torsion.length()},snf=\{snf_ok}), contrast=\{negative_control}",
  }
}

///|
fn complex_of_open(u : Int32, n : Int32) -> Array[Bool] {
  Array::makei(@udm.pow3(n), c => bit_at(u, c))
}

///|
pub fn construct_k10_ualg_discovery_cubical_implications() -> FederationPairBridge {
  let n = 2
  let p = @usite.poset_cube(n)
  let opens = @usite.opens_all(p)
  let full = @usite.full_mask(p)
  let num_samples = opens.length()
  let num_predicates = 4
  let eval_pred = fn(s : Int32, pred : Int32) -> Bool {
    let u = opens[s]
    let k = complex_of_open(u, n)
    match pred {
      0 => @udm.cx_betti(k, n, 0L) == [1]
      1 => @udm.cx_euler(k, n) == 1
      2 => @ucube.dneg_vertex(n, u) == u
      _ => u == full
    }
  }
  let lat = @dkernel.implication_lattice_build(
    num_samples, num_predicates, eval_pred,
  )
  let mut brute_ok = true
  let mut strict = 0
  let mut equiv = 0
  for i in 0..<num_predicates {
    for j in 0..<num_predicates {
      let mut imp = true
      let mut cex = -1
      for s in 0..<num_samples {
        if eval_pred(s, i) && !eval_pred(s, j) {
          imp = false
          if cex < 0 {
            cex = s
          }
        }
      }
      if lat.implies[i][j] != imp || lat.counterexamples[i][j] != cex {
        brute_ok = false
      }
      if i != j {
        if imp && lat.implies[j][i] {
          equiv = equiv + 1
        } else if imp || lat.implies[j][i] {
          strict = strict + 1
        }
      }
    }
  }
  let derived_ok = lat.implies[0][1] &&
    lat.implies[3][2] &&
    lat.implies[3][0] &&
    !lat.implies[2][0] &&
    !lat.implies[0][2]
  let cex_regular_not_acyclic = lat.counterexamples[2][0]
  let cex_acyclic_not_regular = lat.counterexamples[0][2]
  let negative_control = cex_regular_not_acyclic >= 0 &&
    cex_acyclic_not_regular >= 0 &&
    eval_pred(cex_regular_not_acyclic, 2) &&
    !eval_pred(cex_regular_not_acyclic, 0) &&
    eval_pred(cex_acyclic_not_regular, 0) &&
    !eval_pred(cex_acyclic_not_regular, 2)
  let holds = brute_ok &&
    derived_ok &&
    negative_control &&
    lat.strict_unidirectional_edges == strict / 2 &&
    lat.nontrivial_equiv_pairs == equiv / 2
  FederationPairBridge::{
    id: "K10-43",
    lhs: Ualg,
    rhs: Discovery,
    bridge_theorem: "SWAR bitplane implication discovery over all 48 □² subcomplexes: acyclic⇒χ=1 and full⇒regular/acyclic are derived; regular⇒acyclic and acyclic⇒regular are refuted by minimal counterexamples",
    holds,
    quantitative_witness: "samples=\{num_samples}, predicates=\{num_predicates}, brute==SWAR=\{brute_ok}, strict=\{lat.strict_unidirectional_edges}, equiv=\{lat.nontrivial_equiv_pairs}, cex(regular¬acyclic)=\{cex_regular_not_acyclic}, cex(acyclic¬regular)=\{cex_acyclic_not_regular}",
  }
}

///|
fn betti_gf2_swar(k : Array[Bool], n : Int32) -> Array[Int32] {
  let cells = @udm.cx_cells(k, n)
  let ranks = Array::make(n + 2, 0)
  for d in 1..<=n {
    let rows = cells[d - 1].length()
    let cols = cells[d].length()
    if rows > 0 && cols > 0 {
      let m = @udm.cx_boundary_matrix(cells, n, d)
      let entries : Array[Int32] = []
      for r in 0..<rows {
        for c in 0..<cols {
          entries.push((m[r][c] & 1L).to_int())
        }
      }
      let gf2 = @swar.gf2_bit_matrix_from_ints(rows, cols, entries)
      ranks[d] = @swar.gf2_rref_rank_u64(gf2)
    }
  }
  let out = Array::makei(n + 1, d => cells[d].length() - ranks[d] - ranks[d + 1])
  while out.length() > 1 && out[out.length() - 1] == 0 {
    ignore(out.pop())
  }
  out
}

///|
pub fn construct_k10_ualg_accel_gf2_cubical_betti() -> FederationPairBridge {
  let cases : Array[(Array[Bool], Int32)] = [
    (@udm.cx_full(1), 1),
    (@udm.cx_boundary(1), 1),
    (@udm.cx_open_box(1, 0, 1), 1),
    (@udm.cx_full(2), 2),
    (@udm.cx_boundary(2), 2),
    (@udm.cx_open_box(2, 0, 1), 2),
    (@udm.cx_suspension(@udm.cx_boundary(1)), 2),
    (@udm.cx_product(@udm.cx_boundary(1), @udm.cx_boundary(1)), 2),
    (@udm.cx_full(3), 3),
    (@udm.cx_boundary(3), 3),
    (@udm.cx_open_box(3, 0, 1), 3),
  ]
  let mut checked = 0
  let mut agree = true
  for case in cases {
    let (k, n) = case
    let q = @udm.cx_betti(k, n, 0L)
    let f2 = @udm.cx_betti(k, n, 2L)
    let swar = betti_gf2_swar(k, n)
    checked = checked + 1
    if q != f2 || q != swar {
      agree = false
    }
  }
  let s1 = @udm.cx_suspension(@udm.cx_boundary(1))
  let torus = @udm.cx_product(s1, s1)
  let torus_ok = betti_gf2_swar(torus, 4) == [1, 2, 1]
  let sphere_ok = betti_gf2_swar(@udm.cx_boundary(3), 3) == [1, 0, 1]
  let holds = agree && checked == cases.length() && torus_ok && sphere_ok
  FederationPairBridge::{
    id: "K10-44",
    lhs: Ualg,
    rhs: Accel,
    bridge_theorem: "Cubical boundary matrices mod 2 → M4RI/SWAR GF(2) RREF rank → Betti numbers; on the torsion-free cube family this equals exact ℚ Bareiss and mod-p ranks",
    holds,
    quantitative_witness: "complexes=\{checked}/\{cases.length()}, Q==F2==SWAR=\{agree}, T²β=[1,2,1]=\{torus_ok}, S²β=[1,0,1]=\{sphere_ok}",
  }
}

///|
pub fn construct_k10_ualg_meta_congruence_malcev() -> FederationPairBridge {
  let algebras : Array[@ucommon.Alg] = [
    @ucommon.alg_zn(6),
    @ucommon.alg_affine_zn(3),
    @ucommon.alg_product(@ucommon.alg_zn(2), @ucommon.alg_zn(2)),
    @ucommon.alg_chain(3),
    @ucommon.alg_m3(),
    @ucommon.alg_n5(),
  ]
  let mut congruences_checked = 0
  let mut relation_ok = true
  let mut quotient_ok = true
  let mut join_ok = true
  for a in algebras {
    let con = @ucommon.con_lattice(a)
    for theta in con {
      let r = partition_to_relation(theta, a.n)
      congruences_checked = congruences_checked + 1
      if !@mcore.ua_is_equiv(a.n, r) {
        relation_ok = false
      }
      let (_, proj) = @mcore.ua_quotient_classes(a.n, r)
      let (_, cls) = @ucommon.quotient(a, theta)
      if proj != cls {
        quotient_ok = false
      }
      let ker = @mcore.ua_kernel_congruence(a.n, x => proj[x])
      if ker != r {
        quotient_ok = false
      }
    }
    for i in 0..<con.length() {
      for j in 0..<con.length() {
        let ri = partition_to_relation(con[i], a.n)
        let rj = partition_to_relation(con[j], a.n)
        let join_rel = @mcore.ua_equiv_join_closure(a.n, ri, rj)
        let join_part = @ucommon.part_norm(@ucommon.part_join(con[i], con[j]))
        if relation_to_partition(join_rel, a.n) != join_part {
          join_ok = false
        }
      }
    }
  }
  let malcev_algebras : Array[@ucommon.Alg] = [
    @ucommon.alg_zn(6),
    @ucommon.alg_affine_zn(3),
    @ucommon.alg_product(@ucommon.alg_zn(2), @ucommon.alg_zn(2)),
  ]
  let mut malcev_checked = 0
  let mut malcev_ok = true
  for a in malcev_algebras {
    let verdict = @ucommon.malcev_global(a, 20000)
    match verdict.term {
      Some(t) => {
        malcev_checked = malcev_checked + 1
        let p = fn(x : Int32, y : Int32, z : Int32) -> Int32 {
          @ucommon.term_eval(a, t, [x, y, z])
        }
        if !@ucommon.malcev_term_ok(a, t) || !@mcore.ua_is_malcev_op(a.n, p) {
          malcev_ok = false
        }
        for theta in @ucommon.con_lattice(a) {
          let r = partition_to_relation(theta, a.n)
          if !@mcore.ua_is_ternary_congruence(a.n, r, p) {
            malcev_ok = false
          }
        }
      }
      None => malcev_ok = false
    }
  }
  let chain = @ucommon.alg_chain(3)
  let bad_rel = partition_to_relation(@ucommon.part_norm([0, 1, 0]), chain.n)
  let bad_p = fn(x : Int32, y : Int32, _z : Int32) -> Int32 { (x + y) % 3 }
  let negative_control = !@mcore.ua_is_malcev_op(chain.n, bad_p) &&
    !@mcore.ua_is_ternary_congruence(chain.n, bad_rel, bad_p) &&
    !@ucommon.is_congruence(chain, @ucommon.part_norm([0, 1, 0]))
  let holds = relation_ok &&
    quotient_ok &&
    join_ok &&
    malcev_ok &&
    malcev_checked == malcev_algebras.length() &&
    negative_control
  FederationPairBridge::{
    id: "K10-45",
    lhs: Ualg,
    rhs: Meta,
    bridge_theorem: "ualg partition congruences ↔ meta/core Boolean relation algebra: quotient kernel, join closure and Mal'cev term preservation agree; a non-Mal'cev operation and a non-congruence relation are rejected",
    holds,
    quantitative_witness: "congruences=\{congruences_checked}, relation=\{relation_ok}, quotient_kernel=\{quotient_ok}, join=\{join_ok}, Mal'cev_algebras=\{malcev_checked}/\{malcev_algebras.length()}, Mal'cev_preserves_all_congruences=\{malcev_ok}, negative=\{negative_control}",
  }
}

///|
pub fn construct_k10_ualg_symlib_burnside_marks() -> FederationPairBridge {
  let n = 2
  let forms = ualg_face_formulas(n)
  let group = @udm.mor_group(
    [[@udm.dnf_var(1), @udm.dnf_var(0)], [@udm.dnf_nvar(0), @udm.dnf_var(1)]],
    n,
  )
  let perms = group.map(s => @udm.subst_action(forms, s, @udm.face_norm))
  let mut well_defined = group.length() == 8 && forms.length() == 48
  for p in perms {
    let hit = Array::make(forms.length(), false)
    for v in p {
      if v < 0 || v >= forms.length() || hit[v] {
        well_defined = false
      } else {
        hit[v] = true
      }
    }
  }
  let sym_perms = perms.map(p => @sym.Perm::from_img(p))
  let g = @sym.PermGroup::new(forms.length(), sym_perms)
  let gs = @sym.gset_points(g, 64)
  let (orbits, burnside) = @sym.gset_burnside(gs)
  let (sum, order) = @ucommon.burnside_sum(perms)
  let direct = @ucommon.orbit_count(perms)
  let subs = @sym.subgroup_classes(g, 64)
  let marks = @sym.mark_vector(gs, subs)
  let table = @sym.table_of_marks(g, subs, 64)
  let table_formula = @sym.table_of_marks_formula(g, subs, 64)
  let marks_ok = table == table_formula && marks.length() == subs.length()
  let mut orbit_stabilizer = true
  for i in 0..<forms.length() {
    let orb = @sym.gset_orbits(gs)
    let mut orb_size = 0
    for o in orb {
      if o.contains(i) {
        orb_size = o.length()
      }
    }
    let stab = g.stabilizer(i).order()
    if orb_size.to_int64() * stab != 8L {
      orbit_stabilizer = false
    }
  }
  let trivial = @sym.PermGroup::trivial(forms.length())
  let gs_trivial = @sym.gset_points(trivial, 64)
  let (trivial_orbits, _) = @sym.gset_burnside(gs_trivial)
  let negative_control = trivial_orbits == 48 && orbits == 15
  let holds = well_defined &&
    orbits == direct &&
    burnside == direct &&
    sum % order == 0 &&
    sum / order == direct &&
    orbits == 15 &&
    marks_ok &&
    orbit_stabilizer &&
    negative_control
  FederationPairBridge::{
    id: "K10-38",
    lhs: Ualg,
    rhs: Symlib,
    bridge_theorem: "B₂ = Aut([2]) substitutions induce a 48-point G-set of □² subcomplexes; Burnside orbit count, table of marks and orbit–stabilizer agree with ualg's independent permutation action",
    holds,
    quantitative_witness: "|B₂|=\{group.length()}, points=\{forms.length()}, orbits=\{orbits}=Burnside=\{burnside}=ualg=\{direct}, subgroups=\{subs.length()}, marks==formula=\{marks_ok}, orbit_stabilizer=\{orbit_stabilizer}, trivial_orbits=\{trivial_orbits}",
  }
}

///|
pub fn verify_k10_ualg_federation_bridges() -> Array[FederationPairBridge] {
  [
    construct_k10_ualg_cubical_face_bdd(),
    construct_k10_ualg_symlib_burnside_marks(),
    construct_k10_ualg_semiring_congruence_kleene(),
    construct_k10_ualg_topos_cube_sieve64(),
    construct_k10_ualg_scheme_stanley_reisner(),
    construct_k10_ualg_condensed_translation_spectrum(),
    construct_k10_ualg_discovery_cubical_implications(),
    construct_k10_ualg_accel_gf2_cubical_betti(),
    construct_k10_ualg_meta_congruence_malcev(),
  ]
}

///|
pub fn ten_federation_descriptors(
  accel_precomputed~ : @accel.AccelFederationReport? = None,
) -> Array[FederationDescriptor] {
  let out = nine_federation_descriptors(accel_precomputed~)
  let ualg_ok = @udm.face_count_recursive(2) == 48L &&
    @usite.opens_count(@usite.poset_cube(2)) == 48L &&
    @ucube.vertex_closure(2, 0) == 0 &&
    @ucommon.alg_ok(@ucommon.alg_zn(6))
  out.push(FederationDescriptor::{
    id: Ualg,
    slug: "ualg",
    packages: [
      "ualg-core", "ualg-site", "ualg-demorgan", "ualg-cube", "cmd-ualg",
    ],
    canonical_normal_form: "Freese congruence / Mal'cev term / Kalman DNF / Alexandrov ¬¬ sheafification / cubical Betti",
    categorification_role: "Constructive Universal Algebra, Finite Poset Toposes & De Morgan Cubical Complexes",
    live_health_ok: ualg_ok,
    summary: "K10 constructive federation: congruence lattices, B₂ marks, Stanley–Reisner, Sieve64 transport, GF2 Betti and Mal'cev reflection",
  })
  out
}

///|
#derive(Debug, Eq)
pub(all) struct TenFederationUnificationReport {
  ten_federations_verified : Int32
  k10_bridges_verified : Int32
  ualg_bridges_verified : Int32
  promotion_pipeline : FourFederationPromotionReport
  v5_ackermann_65536_sets_verified : Bool
  rotation_axis_cert_ok : Bool
  legacy_k5_dispatch_ok : Bool
  all_holds : Bool
}

///|
pub extend TenFederationUnificationReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend TenFederationUnificationReport with Eq::{not_equal, equal}

///|
pub fn verify_k10_ten_federation_bridges(
  k7_precomputed~ : Array[FederationPairBridge]? = None,
  accel_precomputed~ : @accel.AccelFederationReport? = None,
  atlas_precomputed~ : @tensor.F3Tensor222Atlas? = None,
) -> Array[FederationPairBridge] {
  let out = verify_k9_federation_bridges(
    k7_precomputed~,
    accel_precomputed~,
    atlas_precomputed~,
  )
  for e in verify_k10_ualg_federation_bridges() {
    out.push(e)
  }
  out
}

///|
pub fn verify_k10_ten_federation_unification(
  k7_precomputed~ : Array[FederationPairBridge]? = None,
  accel_precomputed~ : @accel.AccelFederationReport? = None,
  rotation_precomputed~ : RotationAxisBridgeReport? = None,
  k5_preverified_ok~ : Bool? = None,
) -> TenFederationUnificationReport {
  let atlas = @tensor.f3_tensor222_atlas_build()
  let feds = ten_federation_descriptors(accel_precomputed~)
  let mut feds_ok = 0
  for f in feds {
    if f.live_health_ok {
      feds_ok = feds_ok + 1
    }
  }
  let k10 = verify_k10_ten_federation_bridges(
    k7_precomputed~,
    accel_precomputed~,
    atlas_precomputed=Some(atlas),
  )
  let mut k10_ok = 0
  let mut ualg_ok = 0
  for e in k10 {
    if e.holds {
      k10_ok = k10_ok + 1
      if e.lhs == Ualg || e.rhs == Ualg {
        ualg_ok = ualg_ok + 1
      }
    }
  }
  let promo = promote_discovered_implication_to_focused_theorem(
    atlas_precomputed=Some(atlas),
  )
  let (v5_rk, v5_cnts) = @mreflect.v5_ackermann_rank_spectrum()
  let v5_ok = v5_rk == 4 &&
    v5_cnts[0] + v5_cnts[1] + v5_cnts[2] + v5_cnts[3] + v5_cnts[4] == 65536
  let rot_cert = rotation_axis_certificate(precomputed=rotation_precomputed)
  let k5_disp = verify_legacy_k5_system_dispatch(
    preverified_ok=k5_preverified_ok,
  )
  let holds = feds_ok == 10 &&
    k10.length() == 45 &&
    k10_ok == 45 &&
    ualg_ok == 9 &&
    promo.pipeline_holds &&
    v5_ok &&
    rot_cert.ok &&
    k5_disp
  TenFederationUnificationReport::{
    ten_federations_verified: feds_ok,
    k10_bridges_verified: k10_ok,
    ualg_bridges_verified: ualg_ok,
    promotion_pipeline: promo,
    v5_ackermann_65536_sets_verified: v5_ok,
    rotation_axis_cert_ok: rot_cert.ok,
    legacy_k5_dispatch_ok: k5_disp,
    all_holds: holds,
  }
}
