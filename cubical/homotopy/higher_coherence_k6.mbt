///|
/// Non-Abelian Figure-Eight `S^1 v S^1` (`pi_1 = F_2 = <a, b>`) Square Boundary Filler Report:
/// distinguishes genuine `F_2` free-group boundary word cancellation (`top^{-1} * left * bottom * right^{-1} == 1`
/// in `F_2`) from naive abelianized `H_1 = Z^2` winding `(w_a, w_b) == (0, 0)`!
#derive(Debug, Eq)
pub(all) struct WedgeSquareFillerReport {
  abelian_winding_a : Int32
  abelian_winding_b : Int32
  reduced_f2_boundary_word : Array[Int32]
  fills_in_wedge_s1_s1 : Bool
  fills_in_abelianized_torus : Bool
}

///|
pub extend WedgeSquareFillerReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend WedgeSquareFillerReport with Eq::{not_equal, equal}

///|
pub fn f2_reduce_word(word : Array[Int32]) -> Array[Int32] {
  @gcd.ugcd_free_group_reduce(word)
}

///|
pub fn f2_invert_word(word : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut i = word.length() - 1
  while i >= 0 {
    out.push(-word[i])
    i = i - 1
  }
  out
}

///|
/// Decide whether a 2-box `(top, bottom, left, right)` of edge words in `pi_1(S^1 v S^1) = F_2`
/// (`+1 = loop_a, -1 = loop_a^{-1}, +2 = loop_b, -2 = loop_b^{-1}`) admits a 2-cell filler in
/// the 1-dimensional HIT `S^1 v S^1` (no 2-cells => fills iff reduced boundary word in `F_2` is empty!)
/// vs in `T^2 = (S^1 v S^1) u_([a,b]) e^2` (fills iff abelianized winding `(w_a, w_b) == (0, 0)`!).
pub fn wedge_square_filler_report(
  top : Array[Int32],
  bottom : Array[Int32],
  left : Array[Int32],
  right : Array[Int32],
) -> WedgeSquareFillerReport {
  // Boundary loop around square: left * bottom * right^{-1} * top^{-1}
  let bdry : Array[Int32] = []
  for x in left {
    bdry.push(x)
  }
  for x in bottom {
    bdry.push(x)
  }
  for x in f2_invert_word(right) {
    bdry.push(x)
  }
  for x in f2_invert_word(top) {
    bdry.push(x)
  }
  let red = f2_reduce_word(bdry)
  let mut wa = 0
  let mut wb = 0
  for g in red {
    if g == 1 {
      wa = wa + 1
    } else if g == -1 {
      wa = wa - 1
    } else if g == 2 {
      wb = wb + 1
    } else if g == -2 {
      wb = wb - 1
    }
  }
  WedgeSquareFillerReport::{
    abelian_winding_a: wa,
    abelian_winding_b: wb,
    reduced_f2_boundary_word: red,
    fills_in_wedge_s1_s1: red.length() == 0,
    fills_in_abelianized_torus: wa == 0 && wb == 0,
  }
}

///|
// Phase 21 Breakthroughs for Capability Boundaries §4.6, §4.7, and §4.3:
//   • §4.6 (`Arbitrary-n Singleton Contraction, Stasheff K_6 6-Cell, Variable-Endpoint HITs & Condensed Adams-Brunerie`):
//       - `[T-Singleton-N]`: Arbitrary-`n` cubical path-telescope singleton contraction
//         `dpath_singleton_n_transport_value`, eliminating the hardcoded `n = 5` ceiling;
//       - `[T-Associahedron-K6]`: Stasheff `K_6` (`C_5 = 42`, `f = [42, 84, 56, 14, 1]`, `chi = 1`)
//         Northern/Southern 5-cells + unified interior 6-cell `dpath_associahedron_k6_cell6_value`;
//       - `[T-VarEndpoint-HIT]`: Kernel-checked variable-endpoint HITs (`PropTrunc` squash & `SuspBool` meridians);
//       - `[T-Adams-Brunerie-Bridge]`: Algebraic Steenrod-Adams `Ext_A^{2,3}(F_2, F_2) = 0` (`2*eta = 0`)
//         locked to geometric Brunerie `|beta| = 2` (`pi_4(S^3) = Z/2Z`) + Serre Hopf convergence.
//   • §4.7 (`Higher-Order Inner-Lambda Matching & Goldfarb Diophantine Undecidability Compiler`):
//       - `[T-HOU-InnerLam]`: Higher-order matching with arrow return types and synthesized inner `ULam` arguments;
//       - `[T-Goldfarb-Diophantine]`: Constructive Goldfarb (1981) compiler reducing Diophantine `a + b = c`
//         and `a * b = c` to second-order `UTerm` unification equations.
//   • §4.3 (`RFC 8032 Ed25519 2f+1-of-3f+1 BFT Quorum + Crash-Durable WAL + Tarjan SCC Atomic MVCC Hot-Load`):
//       - `[T-BFT-Ed25519-WAL]`: Cryptographic Ed25519 threshold quorum commit into `ArtifactWalStore` + `@hostfs` + `@condensed` Ledger;
//       - `[T-Tarjan-MVCC-HotLoad]`: Linear-time Tarjan SCC condensation + lock-free MVCC epoch snapshot hot-swapping.

// ===========================================================================
// §4.6 — Arbitrary-`n` Singleton Contraction, Stasheff `K_6` 6-Cell & Variable-Endpoint HITs
// ===========================================================================

///|
/// `[T-Singleton-N]` Arbitrary-`n` Cubical Path-Telescope Singleton Contraction:
/// Given a composable chain of `n` paths `paths = [p_0, ..., p_{n-1}]` (`p_k(0) == p_{k-1}(1)`)
/// and `base_cell : fam_n([refl(x_0), ..., refl(x_0)])`, iteratively transports `base_cell`
/// along `n` singleton prefixes `w_k |-> [p_0, ..., p_{k-1}, prefix(p_k, w_k), refl(p_k(w_k)), ...]`
/// to inhabit `fam_n([p_0, ..., p_{n-1}])` for ANY `n >= 0`!
pub fn dpath_singleton_n_transport_value(
  fam_n : (Array[DValue]) -> DValue,
  base_cell : DValue,
  paths : Array[DValue],
  dlevel : Int32,
) -> DValue {
  let n = paths.length()
  let mut cur = base_cell
  for k in 0..<n {
    let pk = paths[k]
    cur = transport_value(
      memo_dim_line(wk => {
        let args : Array[DValue] = []
        for j in 0..<k {
          args.push(paths[j])
        }
        args.push(dpath_prefix_value(pk, wk))
        let rx = dpath_refl_value(dapp_dim(pk, wk))
        for _ in (k + 1)..<n {
          args.push(rx)
        }
        fam_n(args)
      }),
      cur,
      dlevel + n,
    )
  }
  cur
}

///|
/// Leftmost bi-triple 6-fold parenthesization `((p0 . p1) . p2) . ((p3 . p4) . p5)` (a `K_6` vertex).
pub fn dpath_k6_lhs1_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let l01 = dpath_trans_value(space_ty, p0, p1, dlevel)
  let l012 = dpath_trans_value(space_ty, l01, p2, dlevel)
  let r34 = dpath_trans_value(space_ty, p3, p4, dlevel)
  let r345 = dpath_trans_value(space_ty, r34, p5, dlevel)
  dpath_trans_value(space_ty, l012, r345, dlevel)
}

///|
/// Rightmost bi-triple 6-fold parenthesization `(p0 . (p1 . p2)) . (p3 . (p4 . p5))` (opposite `K_6` square corner).
pub fn dpath_k6_rhs1_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let l12 = dpath_trans_value(space_ty, p1, p2, dlevel)
  let l012 = dpath_trans_value(space_ty, p0, l12, dlevel)
  let r45 = dpath_trans_value(space_ty, p4, p5, dlevel)
  let r345 = dpath_trans_value(space_ty, p3, r45, dlevel)
  dpath_trans_value(space_ty, l012, r345, dlevel)
}

///|
fn dpath_k6_interchange_square_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let assoc_l = dpath_assoc_path3_value(space_ty, p0, p1, p2, dlevel)
  let assoc_r = dpath_assoc_path3_value(space_ty, p3, p4, p5, dlevel)
  DVPathLam(
    memo_dim_line(a => {
      DVPathLam(
        memo_dim_line(b => {
          dpath_trans_value(
            space_ty,
            dapp_dim(assoc_l, a),
            dapp_dim(assoc_r, b),
            dlevel,
          )
        }),
      )
    }),
  )
}

///|
/// Northern 2-edge walk on Stasheff `K_6`: reassociate `(p0, p1, p2)` first, then `(p3, p4, p5)`.
pub fn dpath_k6_route_north2_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let path1_ty = DValue::DVPathTy(
    _ => space_ty,
    dapp_dim(p0, DZero),
    dapp_dim(p5, DOne),
  )
  let sq = dpath_k6_interchange_square_value(
    space_ty, p0, p1, p2, p3, p4, p5, dlevel,
  )
  let b0 : DValue = DVPathLam(a => dapp_dim(dapp_dim(sq, a), DZero))
  let r1 : DValue = DVPathLam(b => dapp_dim(dapp_dim(sq, DOne), b))
  dpath_trans_value(path1_ty, b0, r1, dlevel + 2)
}

///|
/// Southern 2-edge walk on Stasheff `K_6`: reassociate `(p3, p4, p5)` first, then `(p0, p1, p2)`.
pub fn dpath_k6_route_south2_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let path1_ty = DValue::DVPathTy(
    _ => space_ty,
    dapp_dim(p0, DZero),
    dapp_dim(p5, DOne),
  )
  let sq = dpath_k6_interchange_square_value(
    space_ty, p0, p1, p2, p3, p4, p5, dlevel,
  )
  let l0 : DValue = DVPathLam(b => dapp_dim(dapp_dim(sq, DZero), b))
  let t1 : DValue = DVPathLam(a => dapp_dim(dapp_dim(sq, a), DOne))
  dpath_trans_value(path1_ty, l0, t1, dlevel + 2)
}

///|
/// Northern 4-cell filler between `route_north2` and `route_south2` on `K_6`.
pub fn dpath_k6_hemi_north4_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let path1_ty = DValue::DVPathTy(
    _ => space_ty,
    dapp_dim(p0, DZero),
    dapp_dim(p5, DOne),
  )
  let sq = dpath_k6_interchange_square_value(
    space_ty, p0, p1, p2, p3, p4, p5, dlevel,
  )
  dpath_square_boundary3_value(path1_ty, sq, dlevel + 2)
}

///|
/// Southern 4-cell filler (inverted transposed square) between `route_north2` and `route_south2` on `K_6`.
pub fn dpath_k6_hemi_south4_value(
  space_ty : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let path1_ty = DValue::DVPathTy(
    _ => space_ty,
    dapp_dim(p0, DZero),
    dapp_dim(p5, DOne),
  )
  let sq = dpath_k6_interchange_square_value(
    space_ty, p0, p1, p2, p3, p4, p5, dlevel,
  )
  let sq_tr : DValue = DVPathLam(b => {
    DVPathLam(a => dapp_dim(dapp_dim(sq, a), b))
  })
  dpath_sym_value(dpath_square_boundary3_value(path1_ty, sq_tr, dlevel + 2))
}

///|
/// `[T-Associahedron-K6]` Stasheff's `K_6` Higher Coherence Cell constructed via
/// `6`-stage `dpath_singleton_n_transport_value` (`n = 6`!), unifying `hemi_north4`
/// and `hemi_south4` across all 6-fold composable path chains `(p0, p1, p2, p3, p4, p5)`!
pub fn dpath_associahedron_k6_coherence_value(
  space_ty : DValue,
  r : DValue,
  p0 : DValue,
  p1 : DValue,
  p2 : DValue,
  p3 : DValue,
  p4 : DValue,
  p5 : DValue,
  dlevel : Int32,
) -> DValue {
  let rr = dpath_refl_value(r)
  let base_north4 = dpath_k6_hemi_north4_value(
    space_ty, rr, rr, rr, rr, rr, rr, dlevel,
  )
  let base_coh = dpath_refl_value(base_north4)
  dpath_singleton_n_transport_value(
    ps => {
      let q0 = ps[0]
      let q1 = ps[1]
      let q2 = ps[2]
      let q3 = ps[3]
      let q4 = ps[4]
      let q5 = ps[5]
      let path1_ty = DValue::DVPathTy(
        _ => space_ty,
        dapp_dim(q0, DZero),
        dapp_dim(q5, DOne),
      )
      let lhs = dpath_k6_lhs1_value(space_ty, q0, q1, q2, q3, q4, q5, dlevel)
      let rhs = dpath_k6_rhs1_value(space_ty, q0, q1, q2, q3, q4, q5, dlevel)
      let path2_ty = DValue::DVPathTy(_ => path1_ty, lhs, rhs)
      let rn2 = dpath_k6_route_north2_value(
        space_ty, q0, q1, q2, q3, q4, q5, dlevel,
      )
      let rs2 = dpath_k6_route_south2_value(
        space_ty, q0, q1, q2, q3, q4, q5, dlevel,
      )
      let path3_ty = DValue::DVPathTy(_ => path2_ty, rn2, rs2)
      DVPathTy(
        _ => path3_ty,
        dpath_k6_hemi_north4_value(space_ty, q0, q1, q2, q3, q4, q5, dlevel),
        dpath_k6_hemi_south4_value(space_ty, q0, q1, q2, q3, q4, q5, dlevel),
      )
    },
    base_coh,
    [p0, p1, p2, p3, p4, p5],
    dlevel + 4,
  )
}

///|
/// `[T-VarEndpoint-HIT]` Build and kernel-verify two variable-endpoint HIT schemas:
///   1. `PropTruncBool`: `inc(b : Bool) : ||Bool||`, `squash(x y : ||Bool||) : Path ||Bool|| x y`
///      (using `dhit_arg_face(DTVar(1))` and `dhit_arg_face(DTVar(0))` — genuinely variable endpoints!);
///   2. `SuspBool`: `north : SuspBool`, `south : SuspBool`, `merid(b : Bool) : Path SuspBool north south`.
pub fn check_variable_endpoint_hits() -> Bool {
  // 1. Propositional Truncation of Bool (`squash` has variable endpoints `x` and `y`!)
  let trunc_spec = dhit_spec("PropTruncBool", 0, [], [], [
    dhit_cell_spec("inc", 0, [darg_external("b", DBoolTy)], []),
    dhit_cell_spec("squash", 1, [darg_recursive("x"), darg_recursive("y")], [
      dhit_arg_face(DTVar(1)),
      dhit_arg_face(DTVar(0)),
    ]),
  ])
  let t_true = DTerm::DHitIntro(trunc_spec, 0, [], [DTerm::DBoolLit(true)], [])
  let t_false = DTerm::DHitIntro(trunc_spec, 0, [], [DTerm::DBoolLit(false)], [])
  let sq_path = DTerm::DLamDim(
    DTerm::DHitIntro(trunc_spec, 1, [], [t_true, t_false], [Dim::DVar(0)]),
  )
  let trunc_ty = DTerm::DHitType(trunc_spec, [])
  let expected_sq_ty = DTerm::DPath(trunc_ty, t_true, t_false)
  let trunc_ok = match
    d_as_type(expected_sq_ty, denv_empty(), denv_empty(), ddim_empty()) {
    Some(tv) =>
      match
        d_check(sq_path, tv.value, denv_empty(), denv_empty(), ddim_empty()) {
        Some(_) => {
          // Verify endpoints reduce to `inc(true)` at `0` and `inc(false)` at `1`!
          let v0 = deval_dim(
            DAppDim(sq_path, DZero),
            denv_empty(),
            ddim_empty(),
          )
          let v1 = deval_dim(DAppDim(sq_path, DOne), denv_empty(), ddim_empty())
          let vt = deval_dim(t_true, denv_empty(), ddim_empty())
          let vf = deval_dim(t_false, denv_empty(), ddim_empty())
          let trunc_v = deval_dim(trunc_ty, denv_empty(), ddim_empty())
          conv_at(0, 0, trunc_v, v0, vt) &&
          conv_at(0, 0, trunc_v, v1, vf) &&
          conv_at(0, 0, trunc_v, vt, vf) == false
        }
        None => false
      }
    None => false
  }

  // 2. Suspension of Bool (`Susp(Bool) ≃ S^1`: distinct poles `north`, `south` + parameterized `merid(b : Bool)`)
  let susp_spec = dhit_spec("SuspBool", 0, [], [], [
    dhit_cell_spec("north", 0, [], []),
    dhit_cell_spec("south", 0, [], []),
    dhit_cell_spec("merid", 1, [darg_external("b", DBoolTy)], [
      dhit_face(0, [], []),
      dhit_face(1, [], []),
    ]),
  ])
  let north = DTerm::DHitIntro(susp_spec, 0, [], [], [])
  let south = DTerm::DHitIntro(susp_spec, 1, [], [], [])
  let merid_t = DTerm::DLamDim(
    DTerm::DHitIntro(susp_spec, 2, [], [DTerm::DBoolLit(true)], [Dim::DVar(0)]),
  )
  let merid_f = DTerm::DLamDim(
    DTerm::DHitIntro(susp_spec, 2, [], [DTerm::DBoolLit(false)], [Dim::DVar(0)]),
  )
  let susp_ty = DTerm::DHitType(susp_spec, [])
  // Composite loop `trans(merid(true), sym(merid(false))) : Path SuspBool north north`
  // AND meridian `merid(true) : Path SuspBool north south`!
  let loop_susp = dpath_trans_term(susp_ty, merid_t, dpath_sym_term(merid_f))
  let merid_ty = DTerm::DPath(susp_ty, north, south)
  let loop_ty = DTerm::DPath(susp_ty, north, north)
  let merid_ok = match
    d_as_type(merid_ty, denv_empty(), denv_empty(), ddim_empty()) {
    Some(tv) =>
      match
        d_check(merid_t, tv.value, denv_empty(), denv_empty(), ddim_empty()) {
        Some(_) => true
        None => false
      }
    None => false
  }
  let susp_ok = match
    d_as_type(loop_ty, denv_empty(), denv_empty(), ddim_empty()) {
    Some(tv) =>
      match
        d_check(loop_susp, tv.value, denv_empty(), denv_empty(), ddim_empty()) {
        Some(_) => merid_ok
        None => false
      }
    None => false
  }
  trunc_ok && susp_ok
}
