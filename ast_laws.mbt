///|
// Behavioural laws for the cubical AST: Path types, data types, HITs,
// and the Kan term constructors.  Terms are written in DTerm syntax;
// dimension index 0 inside a line/tube/path body is its bound
// dimension (term indices and dimension indices are separate spaces).

///|
pub fn check_ast_paths() -> Bool {
  if dep_type_of_closed(DPath(DNatTy, DNatZero, DSucc(DNatZero))) !=
    Some(DUniv(0)) {
    return false
  }
  if !dep_check_closed(DLamDim(DNatZero), DPath(DNatTy, DNatZero, DNatZero)) {
    return false
  }
  // A varying PathP line: Bool presented through an identity Glue.
  let glue_line = DTerm::DHComp(
    DTerm::DUniv(0),
    [d_tube(FEq1(DVar(0)), DBoolTy)],
    DTerm::DBoolTy,
  )
  if dep_type_of_closed(DPathP(glue_line, DBoolLit(true), DBoolLit(true))) !=
    Some(DUniv(0)) {
    return false
  }
  let refl0 = DTerm::DAnn(
    DTerm::DLamDim(DTerm::DNatZero),
    DTerm::DPath(DTerm::DNatTy, DTerm::DNatZero, DTerm::DNatZero),
  )
  if dep_nf_closed(DAppDim(refl0, DOne), DNatTy) != Some(DNatZero) {
    return false
  }
  // HIT path constructors have base endpoints, including both
  // directions of the torus square.
  if dep_nf_closed(DAppDim(DCircleLoop, DOne), DCircleTy) != Some(DCircleBase) {
    return false
  }
  if dep_nf_closed(DAppDim(DAppDim(DTorusSquare, DOne), DOne), DTorusTy) !=
    Some(DTorusBase) {
    return false
  }
  let square_ty = DTerm::DPathP(
    DTerm::DPath(
      DTerm::DTorusTy,
      DTerm::DAppDim(DTerm::DTorusLoopA, Dim::DVar(0)),
      DTerm::DAppDim(DTerm::DTorusLoopA, Dim::DVar(0)),
    ),
    DTerm::DTorusLoopB,
    DTerm::DTorusLoopB,
  )
  dep_check_closed(DTorusSquare, square_ty)
}

///|
pub fn check_ast_nat_pred() -> Bool {
  let pred = DTerm::DLam(
    DTerm::DNatTy,
    DTerm::DNatElim(
      DTerm::DNatTy,
      DTerm::DNatZero,
      DTerm::DLam(DTerm::DNatTy, DTerm::DLam(DTerm::DNatTy, DTerm::DTVar(1))),
      DTerm::DTVar(0),
    ),
  )
  if dep_nf_closed(DApp(pred, d_nat_lit(2)), DNatTy) != Some(d_nat_lit(1)) {
    return false
  }
  dep_nf_closed(DApp(pred, d_nat_lit(0)), DNatTy) == Some(DNatZero)
}

///|
pub fn check_ast_nat_dep() -> Bool {
  // Dependent Nat elimination into refl paths.
  let refl_step = DTerm::DLam(
    DTerm::DNatTy,
    DTerm::DLam(
      DTerm::DPath(DTerm::DNatTy, DTerm::DTVar(0), DTerm::DTVar(0)),
      DTerm::DLamDim(
        DTerm::DSucc(DTerm::DAppDim(DTerm::DTVar(0), Dim::DVar(0))),
      ),
    ),
  )
  let dep_refl = DTerm::DNatElim(
    DTerm::DPath(DTerm::DNatTy, DTerm::DTVar(0), DTerm::DTVar(0)),
    DTerm::DLamDim(DTerm::DNatZero),
    refl_step,
    d_nat_lit(1),
  )
  dep_nf_closed(dep_refl, DPath(DNatTy, d_nat_lit(1), d_nat_lit(1))) ==
  Some(DLamDim(DSucc(DNatZero)))
}

///|
pub fn check_ast_list_len() -> Bool {
  // List length by dependent elimination.
  let step = DTerm::DLam(
    DTerm::DBoolTy,
    DTerm::DLam(
      DTerm::DListTy(DTerm::DBoolTy),
      DTerm::DLam(DTerm::DNatTy, DTerm::DSucc(DTerm::DTVar(0))),
    ),
  )
  let xs = DTerm::DAnn(
    DTerm::DCons(
      DTerm::DBoolLit(true),
      DTerm::DCons(DTerm::DBoolLit(false), DTerm::DNil),
    ),
    DTerm::DListTy(DTerm::DBoolTy),
  )
  let len = DTerm::DListElim(DTerm::DNatTy, DTerm::DNatZero, step, xs)
  dep_nf_closed(len, DNatTy) == Some(d_nat_lit(2))
}

///|
pub fn check_ast_bool_elim() -> Bool {
  let not_to_nat = DTerm::DLam(
    DTerm::DBoolTy,
    DTerm::DBoolElim(DTerm::DNatTy, d_nat_lit(0), d_nat_lit(1), DTerm::DTVar(0)),
  )
  dep_nf_closed(DApp(not_to_nat, DBoolLit(true)), DNatTy) == Some(DNatZero) &&
  dep_nf_closed(DApp(not_to_nat, DBoolLit(false)), DNatTy) == Some(d_nat_lit(1))
}

///|
pub fn check_ast_data() -> Bool {
  check_ast_nat_pred() &&
  check_ast_nat_dep() &&
  check_ast_list_len() &&
  check_ast_bool_elim()
}

///|
pub fn check_ast_hits() -> Bool {
  let circle_el = DTerm::DCircleElim(
    DTerm::DBoolTy,
    DTerm::DBoolLit(true),
    DTerm::DLamDim(DTerm::DBoolLit(true)),
    DTerm::DCircleBase,
  )
  if dep_nf_closed(circle_el, DBoolTy) != Some(DBoolLit(true)) {
    return false
  }
  // The eliminator computes along loop.
  let along_loop = DTerm::DLamDim(
    DTerm::DCircleElim(
      DTerm::DBoolTy,
      DTerm::DBoolLit(true),
      DTerm::DLamDim(DTerm::DBoolLit(true)),
      DTerm::DAppDim(DTerm::DCircleLoop, Dim::DVar(0)),
    ),
  )
  if !dep_def_eq_closed(
      along_loop,
      DLamDim(DBoolLit(true)),
      DPath(DBoolTy, DBoolLit(true), DBoolLit(true)),
    ) {
    return false
  }
  // Dependent circle motive: refl at every point, checked at base.
  let dep_circle = DTerm::DCircleElim(
    DTerm::DPath(DTerm::DCircleTy, DTerm::DTVar(0), DTerm::DTVar(0)),
    DTerm::DLamDim(DTerm::DCircleBase),
    DTerm::DLamDim(
      DTerm::DLamDim(DTerm::DAppDim(DTerm::DCircleLoop, Dim::DVar(1))),
    ),
    DTerm::DCircleBase,
  )
  if dep_nf_closed(dep_circle, DPath(DCircleTy, DCircleBase, DCircleBase)) !=
    Some(DLamDim(DCircleBase)) {
    return false
  }
  // Torus eliminator at base and along the whole square.
  let torus_el = DTerm::DTorusElim(
    DTerm::DBoolTy,
    DTerm::DBoolLit(true),
    DTerm::DTorusBase,
  )
  if dep_nf_closed(torus_el, DBoolTy) != Some(DBoolLit(true)) {
    return false
  }
  let along_square = DTerm::DLamDim(
    DTerm::DLamDim(
      DTerm::DTorusElim(
        DTerm::DBoolTy,
        DTerm::DBoolLit(true),
        DTerm::DAppDim(
          DTerm::DAppDim(DTerm::DTorusSquare, Dim::DVar(1)),
          Dim::DVar(0),
        ),
      ),
    ),
  )
  let square_bool_ty = DTerm::DPathP(
    DTerm::DPath(DTerm::DBoolTy, DTerm::DBoolLit(true), DTerm::DBoolLit(true)),
    DTerm::DLamDim(DTerm::DBoolLit(true)),
    DTerm::DLamDim(DTerm::DBoolLit(true)),
  )
  dep_def_eq_closed(
    along_square,
    DLamDim(DLamDim(DBoolLit(true))),
    square_bool_ty,
  )
}

///|
pub fn check_ast_coe_terms() -> Bool {
  // coe along a constant line, at Bool and at Pi.
  if dep_nf_closed(DCoe(DBoolTy, DZero, DOne, DBoolLit(true)), DBoolTy) !=
    Some(DBoolLit(true)) {
    return false
  }
  let coe_pi = DTerm::DApp(
    DTerm::DCoe(
      DTerm::DPi(DTerm::DBoolTy, DTerm::DBoolTy),
      Dim::DZero,
      Dim::DOne,
      DTerm::DLam(DTerm::DBoolTy, DTerm::DTVar(0)),
    ),
    DTerm::DBoolLit(true),
  )
  if dep_nf_closed(coe_pi, DBoolTy) != Some(DBoolLit(true)) {
    return false
  }
  // coe along the identity Glue line over Bool (packs, composes in
  // Glue, and unpacks at the decided face).
  let glue_line = DTerm::DHComp(
    DTerm::DUniv(0),
    [d_tube(FEq1(DVar(0)), DBoolTy)],
    DTerm::DBoolTy,
  )
  dep_nf_closed(DCoe(glue_line, DZero, DOne, DBoolLit(true)), DBoolTy) ==
  Some(DBoolLit(true))
}

///|
pub fn check_ast_hcomp_data_terms() -> Bool {
  // hcomp / hfill at data types.
  let hc_nat = DTerm::DHComp(
    DTerm::DNatTy,
    [d_tube(FEq0(DVar(0)), DNatZero)],
    DTerm::DNatZero,
  )
  if dep_nf_closed(hc_nat, DNatTy) != Some(DNatZero) {
    return false
  }
  let fill0 = DTerm::DHFill(
    DTerm::DNatTy,
    [d_tube(FBot, DNatZero)],
    DTerm::DNatZero,
    Dim::DZero,
  )
  let fill1 = DTerm::DHFill(
    DTerm::DNatTy,
    [d_tube(FBot, DNatZero)],
    DTerm::DNatZero,
    Dim::DOne,
  )
  if dep_nf_closed(fill0, DNatTy) != Some(DNatZero) ||
    dep_nf_closed(fill1, DNatTy) != Some(DNatZero) {
    return false
  }
  let two_branch = DTerm::DHComp(
    DTerm::DNatTy,
    [d_tube(FEq0(DVar(0)), DNatZero), d_tube(FEq1(DVar(0)), DNatZero)],
    DTerm::DNatZero,
  )
  if dep_nf_closed(two_branch, DNatTy) != Some(DNatZero) {
    return false
  }
  let list_ty = DTerm::DListTy(DTerm::DBoolTy)
  let one_xs = DTerm::DAnn(
    DTerm::DCons(DTerm::DBoolLit(true), DTerm::DNil),
    list_ty,
  )
  let hc_list = DTerm::DHComp(
    list_ty,
    [d_tube(FEq0(DVar(0)), DCons(DBoolLit(true), DNil))],
    one_xs,
  )
  dep_def_eq_closed(hc_list, one_xs, list_ty)
}

///|
pub fn check_ast_hcomp_sigma_path_terms() -> Bool {
  // hcomp at Sigma and at a Path type.
  let sig_ty = DTerm::DSigma(DTerm::DBoolTy, DTerm::DBoolTy)
  let pair = DTerm::DPair(DTerm::DBoolLit(true), DTerm::DBoolLit(false))
  if !dep_def_eq_closed(
      DHComp(sig_ty, [d_tube(FBot, pair)], pair),
      pair,
      sig_ty,
    ) {
    return false
  }
  let path_ty = DTerm::DPath(DTerm::DNatTy, DTerm::DNatZero, DTerm::DNatZero)
  let refl0 = DTerm::DLamDim(DTerm::DNatZero)
  dep_def_eq_closed(
    DHComp(path_ty, [d_tube(FBot, refl0)], refl0),
    refl0,
    path_ty,
  )
}

///|
pub fn check_ast_hcomp_hit_terms() -> Bool {
  // All-base hcomp at the HITs.
  if dep_nf_closed(
      DHComp(DCircleTy, [d_tube(FEq0(DVar(0)), DCircleBase)], DCircleBase),
      DCircleTy,
    ) !=
    Some(DCircleBase) {
    return false
  }
  if dep_nf_closed(
      DHComp(DTorusTy, [d_tube(FEq0(DVar(0)), DTorusBase)], DTorusBase),
      DTorusTy,
    ) !=
    Some(DTorusBase) {
    return false
  }
  true
}

///|
pub fn check_ast_hcomp_univ_term() -> Bool {
  // hcomp in the universe is a Glue type; its pairs must agree on the
  // face, and quoting reproduces the hcomp syntax.
  let glue_ty = DTerm::DHComp(
    DTerm::DUniv(0),
    [d_tube(FEq1(DVar(0)), DBoolTy)],
    DTerm::DBoolTy,
  )
  match as_glue(deval_dim(glue_ty, denv_empty(), ddim_empty())) {
    Some(_) => ()
    None => return false
  }
  if !dep_check_closed(DPair(DBoolLit(true), DBoolLit(true)), glue_ty) {
    return false
  }
  if dep_check_closed(DPair(DBoolLit(true), DBoolLit(false)), glue_ty) {
    return false
  }
  quote_ty(0, 0, deval_dim(glue_ty, denv_empty(), ddim_empty())) == glue_ty
}

///|
pub fn check_ast_kan_terms() -> Bool {
  check_ast_coe_terms() &&
  check_ast_hcomp_data_terms() &&
  check_ast_hcomp_sigma_path_terms() &&
  check_ast_hcomp_hit_terms() &&
  check_ast_hcomp_univ_term()
}

///|
pub fn check_ast_kan_types() -> Bool {
  // Pi: comp with a top tube returns the tube cap function.
  let pi_ty = DValue::DVPi(DValue::DVBoolTy, _ => DValue::DVBoolTy)
  let idv : DValue = DVLam(x => x)
  let notv : DValue = DVLam(x => dbool_not(x))
  let capped = hcomp_value(
    pi_ty,
    dsystem_of([tube_branch(FTop, _ => notv)]),
    idv,
    0,
  )
  if !dv_is_bool_dep(dapp_typed(capped, DVBool(true), DVBoolTy), false) {
    return false
  }
  // Pi filler: 0 is the base, 1 is the comp cap.
  let pi_fill = hfill_value(
    pi_ty,
    dsystem_of([tube_branch(FTop, _ => notv)]),
    idv,
    0,
  )
  if !dv_is_bool_dep(dapp_typed(pi_fill(DZero), DVBool(true), DVBoolTy), true) {
    return false
  }
  if !dv_is_bool_dep(dapp_typed(pi_fill(DOne), DVBool(true), DVBoolTy), false) {
    return false
  }
  // Path types: composition adds the endpoint branches, so the
  // composed path starts at the *target* left endpoint.
  let path_line = (j : Dim) => {
    match dim_simplify(j) {
      DOne =>
        DValue::DVPathTy(_ => DValue::DVNatTy, dv_nat_lit(1), DValue::DVZeroNat)
      _ =>
        DValue::DVPathTy(
          _ => DValue::DVNatTy,
          DValue::DVZeroNat,
          DValue::DVZeroNat,
        )
    }
  }
  let moved = comp_value(
    path_line,
    dsystem_empty(),
    DVPathLam(_ => DVZeroNat),
    0,
  )
  if !dv_is_nat(dapp_dim(moved, DZero), 1) ||
    !dv_is_nat(dapp_dim(moved, DOne), 0) {
    return false
  }
  // Data: constructor recursion for succ and cons.
  let nat_out = hcomp_value(
    DVNatTy,
    dsystem_of([tube_branch(FEq0(DVar(0)), _ => dv_nat_lit(1))]),
    dv_nat_lit(1),
    1,
  )
  if !dv_is_nat(nat_out, 1) {
    return false
  }
  let xs1 : DValue = DVCons(DVBool(true), DVNil)
  let list_out = hcomp_value(
    DVListTy(DVBoolTy),
    dsystem_of([tube_branch(FEq0(DVar(0)), _ => xs1)]),
    xs1,
    1,
  )
  if !conv_at(0, 1, DVListTy(DVBoolTy), list_out, xs1) {
    return false
  }
  // Universe: a top tube composes to its type; a proper tube to Glue.
  let u_top = hcomp_univ_value(
    0,
    dsystem_of([tube_branch(FTop, _ => DVNatTy)]),
    DVBoolTy,
    0,
  )
  if !conv_ty(0, 0, u_top, DVNatTy) {
    return false
  }
  let u_glue = hcomp_univ_value(
    0,
    dsystem_of([tube_branch(FEq1(DVar(0)), _ => DVBoolTy)]),
    DVBoolTy,
    1,
  )
  match as_glue(u_glue) {
    Some(_) => ()
    None => return false
  }
  // HITs: a point-valued circle system composes to a point by
  // De Morgan selection (Phase 11), and eliminators compute over
  // it.  A tube through a neutral (non-point-valued) path remains
  // a formal hcomp.
  let circle_cap = hcomp_value(
    DVCircleTy,
    dsystem_of([tube_branch(FEq1(DVar(0)), _ => circle_point(DVar(0)))]),
    DVCirclePoint(DZero),
    1,
  )
  match force_value(circle_cap) {
    DVCirclePoint(_) => ()
    _ => return false
  }
  if !conv_at(0, 1, DVCircleTy, circle_cap, circle_point(DVar(0))) {
    return false
  }
  match
    hcomp_value(
      DVCircleTy,
      dsystem_of([tube_branch(FEq1(DVar(0)), _ => DVNeutral(DNVar(0)))]),
      DVCirclePoint(DZero),
      1,
    ) {
    DVNeutral(DNHComp(_, _, _)) => ()
    _ => return false
  }
  let elim_formal = eval_circle_elim(
    _ => DVBoolTy,
    DVBool(true),
    DVPathLam(_ => DVBool(true)),
    circle_cap,
    1,
  )
  if !dv_is_bool_dep(elim_formal, true) {
    return false
  }
  // Bool is discrete: matching systems compose to the constructor;
  // a mismatched host-level system stays formal.  Unit always fills.
  let bool_out = hcomp_value(
    DVBoolTy,
    dsystem_of([tube_branch(FEq0(DVar(0)), _ => DVBool(true))]),
    DVBool(true),
    1,
  )
  if !dv_is_bool_dep(bool_out, true) {
    return false
  }
  match
    hcomp_value(
      DVBoolTy,
      dsystem_of([tube_branch(FEq0(DVar(0)), _ => DVBool(false))]),
      DVBool(true),
      1,
    ) {
    DVNeutral(DNHComp(_, _, _)) => ()
    _ => return false
  }
  match
    hcomp_value(
      DVUnitTy,
      dsystem_of([tube_branch(FEq0(DVar(0)), _ => DVUnit)]),
      DVUnit,
      1,
    ) {
    DVUnit => ()
    _ => return false
  }
  let formal_two = hcomp_value(
    DVBoolTy,
    dsystem_of([
      tube_branch(FEq0(DVar(0)), _ => DVBool(false)),
      tube_branch(FEq1(DVar(0)), _ => DVBool(false)),
    ]),
    DVBool(true),
    1,
  )
  match quote_at(0, 1, DVBoolTy, formal_two) {
    DHComp(_, tubes, _) => if tubes.length() != 1 { return false } // equal bodies merge in the DSystem normal form
    _ => return false
  }
  // Torus: a point-valued loop system composes to a point by
  // coordinatewise De Morgan selection (Phase 11); a neutral tube
  // remains formal.
  let torus_cap = hcomp_value(
    DVTorusTy,
    dsystem_of([tube_branch(FEq1(DVar(0)), _ => torus_point(DVar(0), DZero))]),
    DVTorusPoint(DZero, DZero),
    1,
  )
  match force_value(torus_cap) {
    DVTorusPoint(_, _) => ()
    _ => return false
  }
  if !conv_at(0, 1, DVTorusTy, torus_cap, torus_point(DVar(0), DZero)) {
    return false
  }
  match
    hcomp_value(
      DVTorusTy,
      dsystem_of([tube_branch(FEq1(DVar(0)), _ => DVNeutral(DNVar(0)))]),
      DVTorusPoint(DZero, DZero),
      1,
    ) {
    DVNeutral(DNHComp(_, _, _)) => ()
    _ => return false
  }
  // Pi contravariance over the moving Path domain above: the target
  // argument (a path starting at 1) is filled *backwards* to a path
  // starting at 0 before the source function reads its start point.
  let pi_line = (j : Dim) => DValue::DVPi(path_line(j), _ => DValue::DVNatTy)
  let reader : DValue = DVLam(p => dapp_dim(p, DZero))
  let moved_reader = comp_value(pi_line, dsystem_empty(), reader, 0)
  let target_arg : DValue = DVPathLam(k => {
    match dim_simplify(k) {
      DZero => dv_nat_lit(1)
      _ => DVZeroNat
    }
  })
  if !dv_is_nat(dapp_typed(moved_reader, target_arg, path_line(DOne)), 0) {
    return false
  }
  // Sigma: the second component is composed over the fill of the
  // first.  Here B(p) = Path Nat (p @ 0) 0, so after the first
  // component moves to a path starting at 1, the second component
  // must start at 1 as well.
  let sigma_line = (j : Dim) => {
    DValue::DVSigma(path_line(j), p => {
      DValue::DVPathTy(
        _ => DValue::DVNatTy,
        dapp_dim(p, DZero),
        DValue::DVZeroNat,
      )
    })
  }
  let sigma_base : DValue = DVPair(
    DVPathLam(_ => DVZeroNat),
    DVPathLam(_ => DVZeroNat),
  )
  let sigma_out = comp_value(sigma_line, dsystem_empty(), sigma_base, 0)
  let fam0 = (x : DValue) => {
    DValue::DVPathTy(
      _ => DValue::DVNatTy,
      dapp_dim(x, DZero),
      DValue::DVZeroNat,
    )
  }
  let first_out = dfst_typed(sigma_out, fam0)
  let second_out = dsnd_typed(sigma_out, path_line(DOne), fam0)
  if !dv_is_nat(dapp_dim(first_out, DZero), 1) ||
    !dv_is_nat(dapp_dim(second_out, DZero), 1) ||
    !dv_is_nat(dapp_dim(second_out, DOne), 0) {
    return false
  }
  // Data eliminators likewise commute with formal compositions.
  let formal_nat = hcomp_value(
    DVNatTy,
    dsystem_of([tube_branch(FEq1(DVar(0)), _ => dv_nat_lit(1))]),
    DVZeroNat,
    1,
  )
  let pred_step : DValue = DVLam(n => DVLam(_ => n))
  let pred_formal = eval_nat_elim(
    _ => DVNatTy,
    DVZeroNat,
    pred_step,
    formal_nat,
    1,
  )
  if !dv_is_nat(pred_formal, 0) {
    return false
  }
  let formal_bool = hcomp_value(
    DVBoolTy,
    dsystem_of([tube_branch(FEq1(DVar(0)), _ => DVBool(false))]),
    DVBool(true),
    1,
  )
  let bool_elim_formal = eval_bool_elim(
    _ => DVNatTy,
    DVZeroNat,
    DVZeroNat,
    formal_bool,
    1,
  )
  dv_is_nat(bool_elim_formal, 0)
}
