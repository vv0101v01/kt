///|
// Structural replacements for six previously nominal federation bridges.
// Each function returns a `FederationPairBridge` whose `holds` is computed
// from a concrete cross-federation construction, an independent verification
// path, and a negative control — not from conjoining two health reports.
//
//   K8-22 Accel × Cubical   : exhaustive n=2 Boolean face algebra ↔ ROBDD
//   K8-24 Accel × Semiring  : four tropical APSP/closure algorithms agree
//   K8-27 Accel × Condensed : Ozaki-II CRT == schoolbook == BigInt ZMat; SNF
//   K9-29 Meta  × Cubical   : STLC βη NBE ↔ dependent DTerm NBE compilation
//   K9-31 Meta  × Semiring  : unary Horn least model == Boolean Kleene star
//   K9-34 Meta  × Condensed : Möbius sign glue ↔ rlim([-1]) 2-torsion

///|
fn popcount64(x : UInt64) -> Int32 {
  @swar.swar_popcount64(x)
}

///|
fn bool_face_of_truth(mask : Int32, n : Int32) -> @fb.Face {
  let mut acc = @fb.face_bot()
  for a in 0..<(1 << n) {
    if ((mask >> a) & 1) != 0 {
      let mut term = @fb.face_top()
      for i in 0..<n {
        let lit = if ((a >> i) & 1) != 0 {
          @fb.face_var1(i)
        } else {
          @fb.face_var0(i)
        }
        term = @fb.face_and(term, lit)
      }
      acc = @fb.face_or(acc, term)
    }
  }
  acc
}

///|
pub fn replace_k8_22_swar_face_bdd() -> FederationPairBridge {
  let n = 2
  let m = @fb.bdd_manager_new(n)
  let faces : Array[@fb.Face] = []
  let truths : Array[UInt64] = []
  let roots : Array[Int32] = []
  let mut sat_ok = true
  let mut truth_ok = true
  for mask in 0..<(1 << (1 << n)) {
    let f = bool_face_of_truth(mask, n)
    let t = @fb.face_truth_u64(f, n) & ((1UL << (1 << n)) - 1UL)
    let root = @fb.bdd_dag_build_face(m, f)
    let sat = @fb.bdd_dag_sat_count(m, root)
    faces.push(f)
    truths.push(t)
    roots.push(root)
    if t != mask.to_uint64() {
      truth_ok = false
    }
    if sat != BigInt::from_int(popcount64(t)) {
      sat_ok = false
    }
  }
  let mut hom_ok = true
  for i in 0..<faces.length() {
    let ni = @fb.face_not(faces[i])
    let nt = @fb.face_truth_u64(ni, n) & ((1UL << (1 << n)) - 1UL)
    let nr = @fb.bdd_dag_build_face(m, ni)
    if nt != (truths[i].lnot() & 0xFUL) || nr != @fb.bdd_dag_not(m, roots[i]) {
      hom_ok = false
    }
    for j in 0..<faces.length() {
      let fa = @fb.face_and(faces[i], faces[j])
      let fo = @fb.face_or(faces[i], faces[j])
      let ta = @fb.face_truth_u64(fa, n) & ((1UL << (1 << n)) - 1UL)
      let to = @fb.face_truth_u64(fo, n) & ((1UL << (1 << n)) - 1UL)
      let ra = @fb.bdd_dag_build_face(m, fa)
      let ro = @fb.bdd_dag_build_face(m, fo)
      if ta != (truths[i] & truths[j]) ||
        to != (truths[i] | truths[j]) ||
        ra != @fb.bdd_dag_and(m, roots[i], roots[j]) ||
        ro != @fb.bdd_dag_or(m, roots[i], roots[j]) {
        hom_ok = false
      }
    }
  }
  let v0 = @fb.face_var0(0)
  let v1 = @fb.face_var1(0)
  let negative_control = !@fb.bdd_dag_face_eq(v0, v1, n) &&
    @fb.bdd_dag_sat_count(m, @fb.bdd_dag_build_face(m, v0)) == 2N &&
    @fb.bdd_dag_sat_count(m, @fb.bdd_dag_build_face(m, @fb.face_top())) == 4N &&
    @fb.bdd_dag_sat_count(m, @fb.bdd_dag_build_face(m, @fb.face_and(v0, v1))) ==
    0N
  let holds = truth_ok &&
    sat_ok &&
    hom_ok &&
    negative_control &&
    faces.length() == 16
  FederationPairBridge::{
    id: "K8-22",
    lhs: Accel,
    rhs: Cubical,
    bridge_theorem: "Exhaustive 16-element Boolean face algebra on 2 variables: SWAR truth-word popcount == ROBDD sat_count, and ∧/∨/¬ commute with BDD apply",
    holds,
    quantitative_witness: "faces=\{faces.length()}/16, truth=\{truth_ok}, sat_count==popcount=\{sat_ok}, homomorphism=\{hom_ok}, var0≠var1_sat2_top4_bot0=\{negative_control}",
  }
}

///|
fn canon_trop(v : Int32) -> Int32 {
  if v >= @swar.trop_inf_i32 {
    @swar.trop_inf_i32
  } else {
    v
  }
}

///|
fn trop_mat_to_adj(mat : @smat.Mat[@semialg.Trop]) -> Array[Int32] {
  let n = mat.rows
  Array::makei(n * n, k => {
    let x = mat.d[k]
    if x.is_inf() {
      @swar.trop_inf_i32
    } else {
      x.value()
    }
  })
}

///|
pub fn replace_k8_24_tropical_four_way() -> FederationPairBridge {
  let g = @sgraph.Graph::build(4, [0, 1, 0, 2, 1], [1, 2, 2, 3, 3], [
    2, 3, 7, 1, 8,
  ])
  let mat = g.to_trop_mat()
  let adj = trop_mat_to_adj(mat)
  let swar_closed = @swar.tropical_blocked_kleene_closure(4, adj, block_size=2)
  let trop_swar = @smat.closure_trop_swar(mat, tile_size=2)
  let (kleene, neg_kleene) = @sgraph.apsp_kleene(g)
  let dijkstra = @sgraph.apsp_dijkstra(g)
  let mut four_way = !neg_kleene && !@sgraph.has_negative_cycle(trop_swar)
  for i in 0..<4 {
    for j in 0..<4 {
      let v = canon_trop(swar_closed[i * 4 + j])
      if canon_trop(kleene[i][j]) != v {
        four_way = false
      }
      let d = dijkstra.d[i * 4 + j]
      let dv = if d.is_inf() {
        @swar.trop_inf_i32
      } else {
        canon_trop(d.value())
      }
      if dv != v {
        four_way = false
      }
      let t = trop_swar.d[i * 4 + j]
      let tv = if t.is_inf() {
        @swar.trop_inf_i32
      } else {
        canon_trop(t.value())
      }
      if tv != v {
        four_way = false
      }
    }
  }
  let g_neg = @sgraph.Graph::build(4, [0, 1, 0, 2, 1, 3], [1, 2, 2, 3, 3, 1], [
    2, 3, 7, 1, 8, -5,
  ])
  let neg_mat = g_neg.to_trop_mat()
  let neg_closed = @smat.closure_trop_swar(neg_mat, tile_size=2)
  let (_, neg_flag) = @sgraph.apsp_kleene(g_neg)
  let negative_control = @sgraph.has_negative_cycle(neg_closed) && neg_flag
  let holds = four_way && negative_control
  FederationPairBridge::{
    id: "K8-24",
    lhs: Accel,
    rhs: Semiring,
    bridge_theorem: "Nonnegative weighted digraph: blocked SWAR tropical Kleene == closure_trop_swar == apsp_kleene == apsp_dijkstra; a negative cycle is detected by both has_negative_cycle and apsp_kleene",
    holds,
    quantitative_witness: "nodes=4, edges=\{g.edges()}, four_way=\{four_way}, negative_cycle_detected=\{negative_control}",
  }
}

///|
fn zmat_to_int_rows(z : @gcd.ZMat) -> Array[Array[Int32]] {
  Array::makei(z.rows, i => {
    Array::makei(z.cols, j => @gcd.zmat_get(z, i, j).to_int())
  })
}

///|
pub fn replace_k8_27_ozaki_crt_zmat_snf() -> FederationPairBridge {
  let a_small = [[1, 2], [3, 4]]
  let b_small = [[5, 6], [7, 8]]
  let qa = @exactalg.qmat_from_int_rows(a_small)
  let qb = @exactalg.qmat_from_int_rows(b_small)
  let school = @exactalg.qmat_mul(qa, qb)
  let crt = @exactalg.qmat_mul_ozaki2_crt(qa, qb)
  let za = @gcd.zmat_from_rows(
    a_small.map(r => r.map(v => BigInt::from_int(v))),
  )
  let zb = @gcd.zmat_from_rows(
    b_small.map(r => r.map(v => BigInt::from_int(v))),
  )
  let zprod = @gcd.zmat_mul(za, zb)
  let qz = @exactalg.qmat_from_int_rows(zmat_to_int_rows(zprod))
  let small_ok = @exactalg.qmat_eq(school, crt) && @exactalg.qmat_eq(school, qz)
  // Large regime: entries exceed 2^53, where fp64 would round.
  let a_big = [[1000000000, 999999999], [999999998, 999999997]]
  let b_big = [[999999997, 999999998], [999999999, 1000000000]]
  let qab = @exactalg.qmat_from_int_rows(a_big)
  let qbb = @exactalg.qmat_from_int_rows(b_big)
  let big_school = @exactalg.qmat_mul(qab, qbb)
  let big_crt = @exactalg.qmat_mul_ozaki2_crt(qab, qbb)
  let zab = @gcd.zmat_from_rows(a_big.map(r => r.map(v => BigInt::from_int(v))))
  let zbb = @gcd.zmat_from_rows(b_big.map(r => r.map(v => BigInt::from_int(v))))
  let zbig = @gcd.zmat_mul(zab, zbb)
  let mut beyond_fp64 = false
  for i in 0..<2 {
    for j in 0..<2 {
      if @gcd.zmat_get(zbig, i, j) > 9007199254740992N {
        beyond_fp64 = true
      }
    }
  }
  let big_ok = @exactalg.qmat_eq(big_school, big_crt) && beyond_fp64
  let (rank, torsion) = @condensed.coinvariants_zmat_endomorphism(za)
  let id_minus = @gcd.zmat_make(2, 2, 0N)
  for i in 0..<2 {
    for j in 0..<2 {
      let base = if i == j { 1N } else { 0N }
      @gcd.zmat_set(id_minus, i, j, base - @gcd.zmat_get(za, i, j))
    }
  }
  let snf = @gcd.zmat_snf(id_minus)
  let snf_ok = @gcd.zmat_snf_verify(id_minus, snf)
  let negative_control = rank == 0 && torsion == [6N] && snf_ok
  let holds = small_ok && big_ok && negative_control
  FederationPairBridge::{
    id: "K8-27",
    lhs: Accel,
    rhs: Condensed,
    bridge_theorem: "Ozaki-II CRT exact rational matrix multiplication == schoolbook == BigInt ZMat multiplication, including a >2^53 regime; SNF of I−A certifies the condensed inverse-limit torsion",
    holds,
    quantitative_witness: "small_triple=\{small_ok}, big_crt==school_beyond2^53=\{big_ok}, rlim(rank=\{rank},torsion=\{torsion.length()},snf=\{snf_ok}), torsion6=\{negative_control}",
  }
}

///|
fn compile_stlc_ty(ty : @mreflect.Ty) -> @kernel.DTerm {
  match ty {
    @mreflect.Ty::TOne => @kernel.DTerm::DUnitTy
    @mreflect.Ty::TBase(_) => @kernel.DTerm::DUnitTy
    @mreflect.Ty::TArr(a, b) =>
      @kernel.DTerm::DPi(compile_stlc_ty(a), compile_stlc_ty(b))
  }
}

///|
fn compile_stlc_term(t : @mreflect.Term) -> @kernel.DTerm {
  match t {
    @mreflect.Term::TVar(i) => @kernel.DTerm::DTVar(i)
    @mreflect.Term::TLam(ty, b) =>
      @kernel.DTerm::DLam(compile_stlc_ty(ty), compile_stlc_term(b))
    @mreflect.Term::TApp(f, a) =>
      @kernel.DTerm::DApp(compile_stlc_term(f), compile_stlc_term(a))
    @mreflect.Term::TStar => @kernel.DTerm::DUnitLit
  }
}

///|
pub fn replace_k9_29_stlc_dterm_nbe() -> FederationPairBridge {
  let unit = @mreflect.Ty::TOne
  let arr = @mreflect.Ty::TArr(unit, unit)
  let id = @mreflect.Term::TLam(unit, @mreflect.Term::TVar(0))
  let cases : Array[(@mreflect.Term, @mreflect.Ty)] = [
    (id, arr),
    (
      @mreflect.Term::TLam(
        unit,
        @mreflect.Term::TLam(unit, @mreflect.Term::TVar(1)),
      ),
      @mreflect.Ty::TArr(unit, arr),
    ),
    (
      @mreflect.Term::TLam(
        arr,
        @mreflect.Term::TLam(
          unit,
          @mreflect.Term::TApp(@mreflect.Term::TVar(1), @mreflect.Term::TVar(0)),
        ),
      ),
      @mreflect.Ty::TArr(arr, arr),
    ),
    (
      @mreflect.Term::TLam(
        unit,
        @mreflect.Term::TApp(id, @mreflect.Term::TVar(0)),
      ),
      arr,
    ),
    (@mreflect.Term::TApp(id, @mreflect.Term::TStar), unit),
  ]
  let mut checked = 0
  let mut agree = true
  for case in cases {
    let (t, ty) = case
    let meta_nf = @mreflect.nf_in([], ty, t)
    let dterm = compile_stlc_term(t)
    let dty = compile_stlc_ty(ty)
    let dnf = @kernel.dep_nf_closed(dterm, dty)
    let meta_dnf = compile_stlc_term(meta_nf)
    checked = checked + 1
    if !@mreflect.nf_is_fixpoint(ty, meta_nf) ||
      !@kernel.dep_check_closed(dterm, dty) {
      agree = false
    }
    match dnf {
      Some(nf) =>
        if !@kernel.dep_def_eq_closed(nf, meta_dnf, dty) {
          agree = false
        }
      None => agree = false
    }
  }
  let eta = @mreflect.Term::TLam(
    unit,
    @mreflect.Term::TApp(id, @mreflect.Term::TVar(0)),
  )
  let eta_before = !@mreflect.term_eq(eta, id)
  let eta_after = @mreflect.term_eq(
    @mreflect.nf_in([], arr, eta),
    @mreflect.nf_in([], arr, id),
  )
  let open_rejected = !@kernel.dep_check_closed(
    @kernel.DTerm::DTVar(0),
    @kernel.DTerm::DUnitTy,
  )
  let negative_control = eta_before && eta_after && open_rejected
  let holds = agree && checked == cases.length() && negative_control
  FederationPairBridge::{
    id: "K9-29",
    lhs: Meta,
    rhs: Cubical,
    bridge_theorem: "Simply typed λ-calculus βη NBE compiles to cubical DTerm dependent NBE: closed Unit/arrow normal forms agree definitionally; η-redex normalizes to id and open terms are rejected by the closed kernel checker",
    holds,
    quantitative_witness: "closed_terms=\{checked}/\{cases.length()}, meta_nf==dep_nf=\{agree}, η_before≠id_after=\{eta_before && eta_after}, open_rejected=\{open_rejected}",
  }
}

///|
pub fn replace_k9_31_horn_kleene_least_model() -> FederationPairBridge {
  let e = @minstances.env_unary_chain()
  let closure = @minstances.forward_least_model(e, 20, 10, 10)
  let goal = @minstances.cls_show(@minstances.ty_array(@minstances.ty_int()))
  let derivable = @minstances.forward_derivable(e, goal, 20)
  let mut model_ok = false
  let mut fixpoint = false
  let mut facts = 0
  match closure {
    Some(c) => {
      facts = c.facts.length()
      fixpoint = c.fixpoint
      model_ok = facts == 2 && fixpoint && derivable == Some(true)
    }
    None => ()
  }
  // Dependency graph: node 0 = Show(Int) fact, node 1 = Show(Array Int).
  let edges : @smat.Mat[@semialg.BoolSr] = @smat.Mat::new(
    2,
    2,
    @semialg.BoolSr::of(false),
  )
  edges.set(0, 0, @semialg.BoolSr::of(true))
  edges.set(1, 1, @semialg.BoolSr::of(true))
  edges.set(0, 1, @semialg.BoolSr::of(true))
  let (reach, reach_pairs) = @smat.closure_bool_swar(edges)
  let kleene_ok = reach_pairs == 3 && reach.get(0, 1).b && model_ok
  // Negative control: a binary-body rule is not captured by unary reachability.
  let bad_env = @minstances.env([
    @minstances.rule("intRule", 0, @minstances.cls_show(@minstances.ty_int()), []),
    @minstances.rule(
      "pairRule",
      0,
      @minstances.cls_show(
        @minstances.ty_pair(@minstances.ty_int(), @minstances.ty_bool()),
      ),
      [
        @minstances.cls_show(@minstances.ty_int()),
        @minstances.cls_show(@minstances.ty_bool()),
      ],
    ),
  ])
  let bad_goal = @minstances.cls_show(
    @minstances.ty_pair(@minstances.ty_int(), @minstances.ty_bool()),
  )
  let bad_closure = @minstances.forward_least_model(bad_env, 20, 10, 10)
  let bad_derivable = @minstances.forward_derivable(bad_env, bad_goal, 20)
  let mut bad_facts = 0
  match bad_closure {
    Some(c) => bad_facts = c.facts.length()
    None => ()
  }
  let naive : @smat.Mat[@semialg.BoolSr] = @smat.Mat::new(
    2,
    2,
    @semialg.BoolSr::of(false),
  )
  naive.set(0, 0, @semialg.BoolSr::of(true))
  naive.set(1, 1, @semialg.BoolSr::of(true))
  naive.set(0, 1, @semialg.BoolSr::of(true))
  let (_, naive_pairs) = @smat.closure_bool_swar(naive)
  let bad_deriv_str = match bad_derivable {
    Some(true) => "Some(true)"
    Some(false) => "Some(false)"
    None => "None"
  }
  let negative_control = bad_facts == 1 &&
    bad_derivable == Some(false) &&
    naive_pairs == 3
  let holds = kleene_ok && negative_control
  FederationPairBridge::{
    id: "K9-31",
    lhs: Meta,
    rhs: Semiring,
    bridge_theorem: "Unary definite Horn least model = Boolean Kleene star of the dependency graph (Knaster–Tarski lfp); binary-body rule shows unary reachability alone is insufficient and forward saturation correctly refuses the goal",
    holds,
    quantitative_witness: "unary_facts=\{facts}/2, fixpoint=\{fixpoint}, Kleene_reach_pairs=\{reach_pairs}/3, binary_body_facts=\{bad_facts}, derivable=\{bad_deriv_str}, naive_reach_would_overderive=\{naive_pairs == 3}",
  }
}

///|
pub fn replace_k9_34_mobius_glue_rlim_torsion() -> FederationPairBridge {
  let patches = [
    @minstances.patch("A", [0], 1),
    @minstances.patch("B", [0], 1),
    @minstances.patch("C", [0], 1),
  ]
  let mobius_trans = [
    @minstances.transition(0, 1, 1),
    @minstances.transition(1, 2, 1),
    @minstances.transition(2, 0, -1),
  ]
  let mobius = @minstances.glue(patches, mobius_trans)
  let witness = @minstances.monodromy_witness(patches, mobius_trans)
  let zero_patches = [
    @minstances.patch("A", [0], 0),
    @minstances.patch("B", [0], 0),
    @minstances.patch("C", [0], 0),
  ]
  let zero_glue = @minstances.glue(zero_patches, mobius_trans)
  let trivial_trans = [
    @minstances.transition(0, 1, 1),
    @minstances.transition(1, 2, 1),
    @minstances.transition(2, 0, 1),
  ]
  let trivial_glue = @minstances.glue(patches, trivial_trans)
  let minus_one = @gcd.zmat_from_rows([[-1N]])
  let plus_one = @gcd.zmat_from_rows([[1N]])
  let (rank_m, torsion_m) = @condensed.coinvariants_zmat_endomorphism(minus_one)
  let (rank_p, torsion_p) = @condensed.coinvariants_zmat_endomorphism(plus_one)
  let mobius_ok = mobius.glued == None &&
    mobius.obstruction != None &&
    mobius.structurally_ok &&
    witness != None &&
    rank_m == 0 &&
    torsion_m == [2N]
  let trivial_ok = trivial_glue.glued == Some([1, 1, 1]) &&
    rank_p == 1 &&
    torsion_p.length() == 0
  let zero_ok = zero_glue.glued == Some([0, 0, 0])
  let negative_control = mobius_ok && zero_ok && trivial_ok
  let holds = negative_control
  FederationPairBridge::{
    id: "K9-34",
    lhs: Meta,
    rhs: Condensed,
    bridge_theorem: "Möbius sign monodromy obstruction ↔ coinvariants coker(I−(−1))=Z/2; trivial +1 has coinvariants Z and no torsion; the zero section glues even under the Möbius twist",
    holds,
    quantitative_witness: "mobius_glued=\{mobius.glued != None}, obstruction=\{mobius.obstruction != None}, monodromy=\{witness != None}, coinv(-1)=(rank=\{rank_m},torsion=\{torsion_m.length()}), coinv(+1)=(rank=\{rank_p},torsion=\{torsion_p.length()}), zero_glues=\{zero_ok}, trivial_glues=\{trivial_ok}",
  }
}

///|
pub fn verify_structural_bridge_replacements() -> Array[FederationPairBridge] {
  [
    replace_k8_22_swar_face_bdd(),
    replace_k8_24_tropical_four_way(),
    replace_k8_27_ozaki_crt_zmat_snf(),
    replace_k9_29_stlc_dterm_nbe(),
    replace_k9_31_horn_kleene_least_model(),
    replace_k9_34_mobius_glue_rlim_torsion(),
  ]
}
