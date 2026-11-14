// Cross-Federation Hardware-Acceleration & Triad Bridge (`@accel`/`@swar` F8 <-> `@scheme` F5 <-> `@cub` F1):
// 1. Frontier CPU SWAR / RNS-CRT / HVM2 INet + 8/8 Browser Free WebGPU (`WGSL`) Suite;
// 2. Stone–Boolean Representation Isomorphism: M4RI `GF(2)` Faugère F4 Boolean Gröbner (`F8`+`F5`) <-> ROBDD (`F1`);
// 3. Free De Morgan & CCHM Cofibration Lattice (`F1`) <-> Affine Zariski Radical Ideals & Multi-Prime F4 (`F5`);
// 4. Higher-Order Closed Peano `λ`-Terms: Lafont `INetArena` Strong Confluence (`F8`) <-> Dependent NbE (`F1`).

///|
#derive(Debug, Eq)
pub(all) struct F8F5F1TriadBridgeReport {
  gf2_f4_robdd_isomorphism_ok : Bool
  cchm_zariski_cofibration_duality_ok : Bool
  modular_f4_matches_buchberger_ok : Bool
  inet_nbe_peano_confluence_ok : Bool
  ozaki2_qmat_crt_matches_exact_ok : Bool
  wgsl_all_8_registered_ok : Bool
  all_holds : Bool
}

///|
pub extend F8F5F1TriadBridgeReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend F8F5F1TriadBridgeReport with Eq::{not_equal, equal}

///|
fn anf_of_face_truth(nvars : Int32, f : @cub.Face) -> @scheme.BoolAnfPoly {
  // Exact Möbius transform over `{0, 1}^{nvars}` converting the Boolean truth table
  // of `1 + [face_holds(f)]` (so vanishing `g(pt) == 0` <=> `face_holds(f, pt) == true`!)
  // into a Boolean polynomial in `GF(2)[x_0..x_{nvars-1}] / <x_i^2 + x_i>`.
  let size = 1 << nvars
  let coeffs : Array[Int32] = Array::make(size, 0)
  for mask in 0..<size {
    let env : Array[Bool] = Array::makei(nvars, k => ((mask >> k) & 1) == 1)
    // Vanishing generator `1 ⊕ φ(x)`: equals `0` iff `φ(x)` holds!
    coeffs[mask] = if @cub.face_holds(f, env) { 0 } else { 1 }
  }
  // Fast binary Möbius transform (Zhegalkin / ANF transform in `O(n · 2^n)`)
  for bit in 0..<nvars {
    let step = 1 << bit
    for mask in 0..<size {
      if (mask & step) != 0 {
        coeffs[mask] = coeffs[mask] ^ coeffs[mask ^ step]
      }
    }
  }
  let monos : Array[UInt64] = []
  for mask in 0..<size {
    if coeffs[mask] == 1 {
      monos.push(mask.to_uint64())
    }
  }
  @scheme.bool_anf_from_masks(nvars, monos)
}

///|
fn compile_inet_lam_to_dterm(t : @swar.InetClosedLam) -> @cub.DTerm {
  match t {
    @swar.InetClosedLam::ILVar(idx) => @cub.DTerm::DTVar(idx)
    @swar.InetClosedLam::ILLam(body) =>
      @cub.DTerm::DLam(@cub.DTerm::DNatTy, compile_inet_lam_to_dterm(body))
    @swar.InetClosedLam::ILApp(fn_t, arg_t) =>
      @cub.DTerm::DApp(
        compile_inet_lam_to_dterm(fn_t),
        compile_inet_lam_to_dterm(arg_t),
      )
    @swar.InetClosedLam::ILZero => @cub.DTerm::DNatZero
    @swar.InetClosedLam::ILSucc(inner) =>
      @cub.DTerm::DSucc(compile_inet_lam_to_dterm(inner))
  }
}

///|
/// Execute the complete **F8 (`@swar`/`@accel`) ↔ F5 (`@scheme`) ↔ F1 (`@cub`) Triad Equivalence Suite**.
pub fn verify_f8_f5_f1_triad_bridge() -> F8F5F1TriadBridgeReport {
  // 1. Stone–Boolean Isomorphism: M4RI `GF(2)` F4 Boolean Gröbner (`F8`+`F5`) <-> ROBDD (`F1`)
  let i0 = @cub.face_var0(0)
  let i1 = @cub.face_var1(0)
  let j0 = @cub.face_var0(1)
  let k1 = @cub.face_var1(2)
  let l0 = @cub.face_var0(3)
  // Two syntactically distinct faces `phi_a`, `phi_b` that are semantically equal by absorption/distributivity:
  // `phi_a = ((i=0) ∨ (j=0)) ∧ ((i=0) ∨ (k=1)) ∧ (l=0)`
  // `phi_b = ((i=0) ∨ ((j=0) ∧ (k=1))) ∧ (l=0)`
  let phi_a = @cub.face_and(
    @cub.face_and(@cub.face_or(i0, j0), @cub.face_or(i0, k1)),
    l0,
  )
  let phi_b = @cub.face_and(@cub.face_or(i0, @cub.face_and(j0, k1)), l0)
  let phi_c = @cub.face_and(@cub.face_or(i1, j0), l0)
  // Present `phi_a` as a 2-generator Boolean ideal `<1 + (i0 ∨ j0), 1 + (i0 ∨ k1), 1 + l0>`
  // and `phi_b` as `<1 + ((i0 ∨ (j0 ∧ k1)) ∧ l0)>` — M4RI `GF(2)` F4 reduces BOTH to the EXACT SAME RGB!
  let rgb_a = @scheme.f4_boolean_groebner_gf2(4, [
    anf_of_face_truth(4, @cub.face_or(i0, j0)),
    anf_of_face_truth(4, @cub.face_or(i0, k1)),
    anf_of_face_truth(4, l0),
  ])
  let rgb_b = @scheme.f4_boolean_groebner_gf2(4, [anf_of_face_truth(4, phi_b)])
  let rgb_c = @scheme.f4_boolean_groebner_gf2(4, [anf_of_face_truth(4, phi_c)])
  let mut locus_ok = true
  for mask in 0..<16 {
    let env : Array[Bool] = Array::makei(4, v => ((mask >> v) & 1) == 1)
    let mut all_vanish = true
    for g in rgb_a {
      if @scheme.bool_anf_eval(g, mask.to_uint64()) {
        all_vanish = false
      }
    }
    if all_vanish != @cub.face_holds(phi_a, env) {
      locus_ok = false
    }
  }
  let gf2_f4_ok = @cub.bdd_face_eq(phi_a, phi_b, 4) &&
    !@cub.bdd_face_eq(phi_a, phi_c, 4) &&
    rgb_a == rgb_b &&
    rgb_a != rgb_c &&
    locus_ok

  // 2. Free De Morgan & CCHM Cofibration (`F1`) <-> Affine Zariski Radical Ideals (`F5`)
  // Over `Q[x_0, x_1]`: `(x_0 = 0) ↦ <x_0>`, `(x_0 = 1) ↦ <x_0 - 1>`.
  let x0 = @scheme.mpoly_var(2, 0)
  let x1 = @scheme.mpoly_var(2, 1)
  let one2 = @scheme.mpoly_int(2, 1)
  let id_i0 = @scheme.ideal_new(2, [x0])
  let id_i1 = @scheme.ideal_new(2, [@scheme.mpoly_sub(x0, one2)])
  // Disjoint endpoints: `(i=0) ∧ (i=1) == ⊥_F` <-> `<x_0> + <x_0 - 1> == <1>` (empty scheme!)
  let id_meet = @scheme.ideal_add(id_i0, id_i1)
  // Boundary ∂I: `(i=0) ∨ (i=1) != ⊤_F` <-> `<x_0> ∩ <x_0 - 1> = <x_0^2 - x_0> != <0>`!
  let id_bdry = @scheme.ideal_intersect(id_i0, id_i1)
  let di = @cub.dim_var(0)
  let tent = @cub.Dim::DAnd(di, @cub.Dim::DNeg(di))
  let bdry_face = @cub.face_or(i0, i1)
  let cchm_zariski_ok = !@cub.dim_eq_demorgan(tent, @cub.Dim::DZero) &&
    !@cub.dim_is_zero_demorgan(tent) &&
    @cub.cchm_face_is_bot(@cub.face_and(i0, i1)) &&
    !@cub.cchm_face_is_top(bdry_face) &&
    @cub.cchm_face_eq(@cub.face_eq0(tent), bdry_face) &&
    @scheme.ideal_is_unit(id_meet) &&
    !@scheme.ideal_is_zero(id_bdry) &&
    @scheme.ideal_eq(
      id_bdry,
      @scheme.ideal_new(2, [@scheme.mpoly_sub(@scheme.mpoly_mul(x0, x0), x0)]),
    )

  // 3. Multi-Prime Modular Faugère F4 (`@gcd.FpMat` + CRT + Wang) == Buchberger RGB over `Q[x_0, x_1]`
  let f_circle = @scheme.mpoly_sub(
    @scheme.mpoly_add(@scheme.mpoly_mul(x0, x0), @scheme.mpoly_mul(x1, x1)),
    @scheme.mpoly_int(2, 5),
  )
  let f_hyper = @scheme.mpoly_sub(
    @scheme.mpoly_mul(x0, x1),
    @scheme.mpoly_int(2, 2),
  )
  let rgb_mod_f4 = @scheme.f4_groebner_rat_modular(
    2,
    [f_circle, f_hyper],
    @scheme.MonomialOrder::GRevLex,
  )
  let rgb_buch = @scheme.reduced_groebner_basis(
    2,
    [f_circle, f_hyper],
    @scheme.MonomialOrder::GRevLex,
  )
  let mw_a = @scheme.mono64_try_pack([2, 0, 3])
  let mw_b = @scheme.mono64_try_pack([0, 4, 0])
  let mw_ab = @scheme.mono64_try_pack([2, 4, 3])
  let mono64_ok = match (mw_a, mw_b, mw_ab) {
    (Some(wa), Some(wb), Some(wab)) =>
      @scheme.mono64_coprime(wa, wb) &&
      @scheme.mono64_divides(wa, wab) &&
      @scheme.mono64_quot(wab, wa) == wb
    _ => false
  }
  let mod_f4_ok = mono64_ok &&
    rgb_mod_f4 == rgb_buch &&
    rgb_mod_f4.gens.length() >= 2

  // 4. HVM2 Flat-Arena `InetClosedLam` (`F8`) <-> Dependent NbE `kernel_eval_closed_peano` (`F1`)
  // Term 1: `(λf. λx. f (f (f x))) (λn. S(S(S(n)))) (S Z)` == 10
  let church3 = @swar.InetClosedLam::ILLam(
    @swar.InetClosedLam::ILLam(
      @swar.InetClosedLam::ILApp(
        @swar.InetClosedLam::ILVar(1),
        @swar.InetClosedLam::ILApp(
          @swar.InetClosedLam::ILVar(1),
          @swar.InetClosedLam::ILApp(
            @swar.InetClosedLam::ILVar(1),
            @swar.InetClosedLam::ILVar(0),
          ),
        ),
      ),
    ),
  )
  let plus3 = @swar.InetClosedLam::ILLam(
    @swar.InetClosedLam::ILSucc(
      @swar.InetClosedLam::ILSucc(
        @swar.InetClosedLam::ILSucc(@swar.InetClosedLam::ILVar(0)),
      ),
    ),
  )
  let term10 = @swar.InetClosedLam::ILApp(
    @swar.InetClosedLam::ILApp(church3, plus3),
    @swar.InetClosedLam::ILSucc(@swar.InetClosedLam::ILZero),
  )
  // Term 2 (with Erasure!): `(λu. λy. S(S(y))) (church3 plus3 Z) (S(S(S Z)))` == 5
  let drop_first = @swar.InetClosedLam::ILLam(
    @swar.InetClosedLam::ILLam(
      @swar.InetClosedLam::ILSucc(
        @swar.InetClosedLam::ILSucc(@swar.InetClosedLam::ILVar(0)),
      ),
    ),
  )
  let dead_sub = @swar.InetClosedLam::ILApp(
    @swar.InetClosedLam::ILApp(church3, plus3),
    @swar.InetClosedLam::ILZero,
  )
  let three_lit = @swar.InetClosedLam::ILSucc(
    @swar.InetClosedLam::ILSucc(
      @swar.InetClosedLam::ILSucc(@swar.InetClosedLam::ILZero),
    ),
  )
  let term5 = @swar.InetClosedLam::ILApp(
    @swar.InetClosedLam::ILApp(drop_first, dead_sub),
    three_lit,
  )
  let (v10_fwd, _) = @swar.inet_eval_closed_peano_lam(
    term10,
    schedule=@swar.INetWaveSchedule::ScheduleForward,
  )
  let (v10_rev, _) = @swar.inet_eval_closed_peano_lam(
    term10,
    schedule=@swar.INetWaveSchedule::ScheduleReverse,
  )
  let (v5_fwd, st5) = @swar.inet_eval_closed_peano_lam(
    term5,
    schedule=@swar.INetWaveSchedule::ScheduleForward,
  )
  let (v5_rev, _) = @swar.inet_eval_closed_peano_lam(
    term5,
    schedule=@swar.INetWaveSchedule::ScheduleReverse,
  )
  let nbe10 = @cub.kernel_eval_closed_peano(compile_inet_lam_to_dterm(term10))
  let nbe5 = @cub.kernel_eval_closed_peano(compile_inet_lam_to_dterm(term5))
  let inet_nbe_ok = v10_fwd == 10 &&
    v10_rev == 10 &&
    nbe10 == Some(10) &&
    v5_fwd == 5 &&
    v5_rev == 5 &&
    st5 > 0 &&
    nbe5 == Some(5)

  // 5. `algebra/core` Ozaki-II DP4A CRT rational GEMM == exact `qmat_mul`
  let qa = @exactalg.QMat::{
    n: 2,
    rows: [
      [@exactalg.rat_make(3, 2), @exactalg.rat_make(-5, 3)],
      [@exactalg.rat_make(7, 4), @exactalg.rat_make(11, 5)],
    ],
  }
  let qb = @exactalg.QMat::{
    n: 2,
    rows: [
      [@exactalg.rat_make(2, 7), @exactalg.rat_make(-3, 5)],
      [@exactalg.rat_make(4, 3), @exactalg.rat_make(9, 2)],
    ],
  }
  let ozaki_qmat_ok = @exactalg.qmat_eq(
    @exactalg.qmat_mul_ozaki2_crt(qa, qb),
    @exactalg.qmat_mul(qa, qb),
  )

  // 6. All 8/8 registered WGSL shaders portable
  let all8 = @accel.webgpu_all_registered_kernels()
  let mut wgsl8_ok = all8.length() == 8
  for k in all8 {
    if !@accel.audit_wgsl_browser_portability(k).browser_portable {
      wgsl8_ok = false
    }
  }

  let all_holds = gf2_f4_ok &&
    cchm_zariski_ok &&
    mod_f4_ok &&
    inet_nbe_ok &&
    ozaki_qmat_ok &&
    wgsl8_ok
  F8F5F1TriadBridgeReport::{
    gf2_f4_robdd_isomorphism_ok: gf2_f4_ok,
    cchm_zariski_cofibration_duality_ok: cchm_zariski_ok,
    modular_f4_matches_buchberger_ok: mod_f4_ok,
    inet_nbe_peano_confluence_ok: inet_nbe_ok,
    ozaki2_qmat_crt_matches_exact_ok: ozaki_qmat_ok,
    wgsl_all_8_registered_ok: wgsl8_ok,
    all_holds,
  }
}

///|
pub fn verify_accel_hardware_bridge() -> @accel.AccelFederationReport {
  @accel.verify_accel_federation()
}

///|
pub fn accel_hardware_certificate(
  precomputed~ : @accel.AccelFederationReport? = None,
  triad_precomputed~ : F8F5F1TriadBridgeReport? = None,
) -> BridgeCertificate {
  let rep = match precomputed {
    Some(r) => r
    None => @accel.verify_accel_federation()
  }
  let triad = match triad_precomputed {
    Some(r) => r
    None => verify_f8_f5_f1_triad_bridge()
  }
  let f3 = @accel.gf3_bitsliced_all_6561_hyperdeterminants()
  let detail = "M4RI_GF2=\{rep.m4ri_gf2_and_rank_ok}, GF3_bitslice_6561=\{f3.singular_det_zero}+\{f3.det_eq_one}+\{f3.det_eq_two}, Face_SWAR=\{rep.face_swar_bdd_sat_ok}, Ozaki2_DP4A_CRT=\{rep.ozaki2_crt_exact_and_fp64_ok}, Stockham_RNS_NTT=\{rep.stockham_rns_ntt_and_mont30_ok}, Scanbox_Tropical=\{rep.scanbox_morton_tropical_ok}, HVM2_INet=\{rep.hvm2_inet_strong_confluence_ok}, F8_F5_F1_Triad=\{triad.all_holds}, WGSL_static_legacy=\{rep.wgsl_browser_kernels_audited}/7, all_8_registered=\{triad.wgsl_all_8_registered_ok}; no GPU execution"
  bridge_certificate(
    "accel/webgpu+cpu",
    "CPU reference comparisons and WGSL static portability (no GPU execution)",
    rep.all_ok && triad.all_holds,
    detail~,
  )
}
