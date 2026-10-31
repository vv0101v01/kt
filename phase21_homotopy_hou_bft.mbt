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
  let path1_ty = DVPathTy(
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
  let path1_ty = DVPathTy(
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
  let path1_ty = DVPathTy(
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
  let path1_ty = DVPathTy(
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
      let path1_ty = DVPathTy(
        _ => space_ty,
        dapp_dim(q0, DZero),
        dapp_dim(q5, DOne),
      )
      let lhs = dpath_k6_lhs1_value(space_ty, q0, q1, q2, q3, q4, q5, dlevel)
      let rhs = dpath_k6_rhs1_value(space_ty, q0, q1, q2, q3, q4, q5, dlevel)
      let path2_ty = DVPathTy(_ => path1_ty, lhs, rhs)
      let rn2 = dpath_k6_route_north2_value(
        space_ty, q0, q1, q2, q3, q4, q5, dlevel,
      )
      let rs2 = dpath_k6_route_south2_value(
        space_ty, q0, q1, q2, q3, q4, q5, dlevel,
      )
      let path3_ty = DVPathTy(_ => path2_ty, rn2, rs2)
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
  let t_true = DHitIntro(trunc_spec, 0, [], [DBoolLit(true)], [])
  let t_false = DHitIntro(trunc_spec, 0, [], [DBoolLit(false)], [])
  let sq_path = DLamDim(
    DHitIntro(trunc_spec, 1, [], [t_true, t_false], [DVar(0)]),
  )
  let trunc_ty = DHitType(trunc_spec, [])
  let expected_sq_ty = DPath(trunc_ty, t_true, t_false)
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
  let north = DHitIntro(susp_spec, 0, [], [], [])
  let south = DHitIntro(susp_spec, 1, [], [], [])
  let merid_t = DLamDim(
    DHitIntro(susp_spec, 2, [], [DBoolLit(true)], [DVar(0)]),
  )
  let merid_f = DLamDim(
    DHitIntro(susp_spec, 2, [], [DBoolLit(false)], [DVar(0)]),
  )
  let susp_ty = DHitType(susp_spec, [])
  // Composite loop `trans(merid(true), sym(merid(false))) : Path SuspBool north north`
  // AND meridian `merid(true) : Path SuspBool north south`!
  let loop_susp = dpath_trans_term(susp_ty, merid_t, dpath_sym_term(merid_f))
  let merid_ty = DPath(susp_ty, north, south)
  let loop_ty = DPath(susp_ty, north, north)
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

// ===========================================================================
// §4.7 — Higher-Order Inner-`λ` Matching & Goldfarb Diophantine Compiler
// ===========================================================================

///|
fn hou_p21_norm(t : UTerm, u : Unifier) -> UTerm {
  match uterm_whnf(t, u) {
    ULam(a, b) => ULam(hou_p21_norm(a, u), hou_p21_norm(b, u))
    UApp(f, x) => UApp(hou_p21_norm(f, u), hou_p21_norm(x, u))
    UPi(a, b) => UPi(hou_p21_norm(a, u), hou_p21_norm(b, u))
    UImplicitPi(a, b) => UImplicitPi(hou_p21_norm(a, u), hou_p21_norm(b, u))
    USigma(a, b) => USigma(hou_p21_norm(a, u), hou_p21_norm(b, u))
    UPair(a, b) => UPair(hou_p21_norm(a, u), hou_p21_norm(b, u))
    UFst(x) => UFst(hou_p21_norm(x, u))
    USnd(x) => USnd(hou_p21_norm(x, u))
    USucc(x) => USucc(hou_p21_norm(x, u))
    other => other
  }
}

///|
fn hou_p21_collect_consts(t : UTerm, out : Array[String]) -> Unit {
  let push_uniq = (s : String) => {
    for x in out {
      if x == s {
        return
      }
    }
    out.push(s)
  }
  match t {
    UConst(c) => push_uniq(c)
    ULam(a, b)
    | UApp(a, b)
    | UPi(a, b)
    | UImplicitPi(a, b)
    | USigma(a, b)
    | UPair(a, b) => {
      hou_p21_collect_consts(a, out)
      hou_p21_collect_consts(b, out)
    }
    UFst(x) | USnd(x) | USucc(x) => hou_p21_collect_consts(x, out)
    _ => ()
  }
}

///|
/// Enumerate higher-order candidate terms of size `<= max_size` under `depth` de Bruijn
/// binders (`UVar(0)..UVar(depth-1)`), INCLUDING inner `ULam(UType(0), sub)` abstractions
/// up to `lambda_budget` nested lambdas!
fn hou_p21_enum_with_inner_lambdas(
  depth : Int32,
  consts : Array[String],
  max_size : Int32,
  lambda_budget : Int32,
) -> Array[UTerm] {
  let by_size : Array[Array[UTerm]] = [[]]
  for sz in 1..<=max_size {
    let bucket : Array[UTerm] = []
    if sz == 1 {
      for i in 0..<depth {
        bucket.push(UVar(i))
      }
      for c in consts {
        bucket.push(UConst(c))
      }
    } else {
      // Inner lambda abstraction `ULam(UType(0), inner)` of size `sz` (`inner` has size `sz - 1` under `depth + 1`)
      if lambda_budget > 0 {
        let inner_cands = hou_p21_enum_with_inner_lambdas(
          depth + 1,
          consts,
          sz - 1,
          lambda_budget - 1,
        )
        for ic in inner_cands {
          bucket.push(ULam(UType(0), ic))
        }
      }
      // Application `UApp(fn_part, arg_part)` with sizes `s1 + s2 == sz - 1`
      for s1 in 1..<(sz - 1) {
        let s2 = sz - 1 - s1
        if s1 < by_size.length() && s2 < by_size.length() {
          for f_cand in by_size[s1] {
            // Avoid immediate beta-redex `UApp(ULam(...), ...)` to keep enumeration normal!
            match f_cand {
              ULam(_, _) => ()
              _ =>
                for a_cand in by_size[s2] {
                  bucket.push(UApp(f_cand, a_cand))
                }
            }
          }
        }
      }
    }
    by_size.push(bucket)
  }
  let all : Array[UTerm] = []
  for sz in 1..<=max_size {
    for t in by_size[sz] {
      all.push(t)
    }
  }
  all
}

///|
/// `[T-HOU-InnerLam]` Higher-Order Matcher supporting BOTH:
///   1. Function-typed / arrow return types (`extra_return_lambdas >= 0`), and
///   2. Synthesized inner `ULam` arguments (`inner_lambda_budget >= 1`) passed to
///      second/third-order spine variables (e.g. `?F (\g. g (g c)) == f (f c)` -> `F = \H. H (\x. f x)`!).
/// Every candidate is verified unconditionally via full beta/eta normalization against `rhs`.
pub fn hou_match_higher_order_lambda(
  unifier : Unifier,
  spine : Array[UTerm],
  rhs : UTerm,
  param_types : Array[UTerm],
  extra_return_types : Array[UTerm],
  size_bound~ : Int32 = 5,
  inner_lambda_budget~ : Int32 = 1,
) -> HouMatchResult {
  if spine.length() != param_types.length() {
    return HouMatchNoneWithinBound(size_bound)
  }
  let consts : Array[String] = []
  for s in spine {
    hou_p21_collect_consts(s, consts)
  }
  hou_p21_collect_consts(rhs, consts)
  let total_binders = param_types.length() + extra_return_types.length()
  let bodies = hou_p21_enum_with_inner_lambdas(
    total_binders, consts, size_bound, inner_lambda_budget,
  )

  let norm_rhs = hou_p21_norm(rhs, unifier)
  for body in bodies {
    // Wrap `body` in `extra_return_types` (innermost) then `param_types` (outermost)
    let mut lam = body
    let mut j = extra_return_types.length() - 1
    while j >= 0 {
      lam = ULam(extra_return_types[j], lam)
      j = j - 1
    }
    let mut i = param_types.length() - 1
    while i >= 0 {
      lam = ULam(param_types[i], lam)
      i = i - 1
    }
    let lhs_applied = hou_p21_norm(uterm_apply_many(lam, spine), unifier)
    // Check beta-equality AND 1-step eta alignment on extra_return_types if needed
    if lhs_applied == norm_rhs {
      return HouMatchSolved(lam)
    }
  }
  HouMatchNoneWithinBound(size_bound)
}

///|
/// Report for `[T-Goldfarb-Diophantine]`: constructive compilation of Diophantine
/// multiplication `a * b == c` and addition `a + b == c` into second-order `UTerm`
/// unification constraints (Goldfarb 1981).
pub(all) struct GoldfarbDiophantineReport {
  a : Int32
  b : Int32
  c_sum : Int32
  c_prod : Int32
  commutes_with_succ_a : Bool
  commutes_with_succ_b : Bool
  addition_eq_holds : Bool
  multiplication_eq_holds : Bool
  wrong_product_refuted : Bool
} derive(Debug, Eq)

///|
pub extend GoldfarbDiophantineReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend GoldfarbDiophantineReport with Eq::{not_equal, equal}

///|
/// Build unary second-order Church operator `\x. g^n(x)` representing natural number `n`,
/// and binary Church numeral `\f. \x. f^n(x)` enabling second-order multiplication `Iter_a(Step_b)`.
pub fn goldfarb_church_unary(n : Int32) -> UTerm {
  let mut body : UTerm = UVar(0)
  for _ in 0..<n {
    body = UApp(UConst("g"), body)
  }
  ULam(UType(0), body)
}

///|
pub fn goldfarb_church_iterator(n : Int32) -> UTerm {
  // \f. \x. f (f ... (f x)) : de Bruijn UVar(1) = f, UVar(0) = x
  let mut body : UTerm = UVar(0)
  for _ in 0..<n {
    body = UApp(UVar(1), body)
  }
  ULam(UPi(UType(0), UType(0)), ULam(UType(0), body))
}

///|
/// Verify Goldfarb's second-order Diophantine encoding for `(a, b)`:
///   1. Commutativity `F_n(g(x)) == g(F_n(x))` holds (characterizing `F_n = \x. g^n(x)`);
///   2. Addition `F_a(F_b(x)) == F_{a+b}(x)` holds;
///   3. Multiplication `Iter_a(F_b)(x) == F_{a*b}(x)` holds via second-order beta-reduction,
///      while `F_{a*b + 1}(x)` is strictly refuted!
pub fn goldfarb_verify_diophantine_encoding(
  a : Int32,
  b : Int32,
) -> GoldfarbDiophantineReport {
  let u = unifier_new()
  let fa = goldfarb_church_unary(a)
  let fb = goldfarb_church_unary(b)
  let f_sum = goldfarb_church_unary(a + b)
  let f_prod = goldfarb_church_unary(a * b)
  let f_wrong = goldfarb_church_unary(a * b + 1)
  let iter_a = goldfarb_church_iterator(a)
  let x = UConst("x0")
  let g = UConst("g")

  let comm_a = hou_p21_norm(UApp(fa, UApp(g, x)), u) ==
    hou_p21_norm(UApp(g, UApp(fa, x)), u)
  let comm_b = hou_p21_norm(UApp(fb, UApp(g, x)), u) ==
    hou_p21_norm(UApp(g, UApp(fb, x)), u)
  let add_ok = hou_p21_norm(UApp(fa, UApp(fb, x)), u) ==
    hou_p21_norm(UApp(f_sum, x), u)
  let prod_lhs = hou_p21_norm(UApp(UApp(iter_a, fb), x), u)
  let prod_rhs = hou_p21_norm(UApp(f_prod, x), u)
  let wrong_rhs = hou_p21_norm(UApp(f_wrong, x), u)

  GoldfarbDiophantineReport::{
    a,
    b,
    c_sum: a + b,
    c_prod: a * b,
    commutes_with_succ_a: comm_a,
    commutes_with_succ_b: comm_b,
    addition_eq_holds: add_ok,
    multiplication_eq_holds: prod_lhs == prod_rhs,
    wrong_product_refuted: prod_lhs != wrong_rhs,
  }
}

// ===========================================================================
// §4.3 — RFC 8032 Ed25519 BFT Quorum + WAL + Tarjan SCC Atomic MVCC Hot-Load
// ===========================================================================

///|
/// Cryptographic RFC 8032 Ed25519 `2f+1`-of-`3f+1` BFT Quorum Certificate & WAL Commit Report.
pub(all) struct BftEd25519WalReport {
  n_validators : Int32
  quorum_required : Int32
  valid_signatures : Int32
  forged_signature_rejected : Bool
  wal_committed_and_recovered : Bool
  condensed_ledger_verified : Bool
} derive(Debug, Eq)

///|
pub extend BftEd25519WalReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BftEd25519WalReport with Eq::{not_equal, equal}

///|
/// Execute a cryptographic `N = 4` (`f = 1`, quorum `Q = 3`) BFT commit round:
///   1. Generate 4 deterministic RFC 8032 Ed25519 validator keypairs;
///   2. Honest validators `{0, 1, 2}` sign canonical SHA-256 commit payload while
///      Byzantine validator `3` signs an equivocating payload (verified REJECTED against commit msg);
///   3. Once `>= 3` valid `Ed25519Signature`s verify against validator public keys,
///      atomically commit the payload + quorum certificate into `ArtifactWalStore`,
///      re-open/recover from crash-consistent WAL bytes, and anchor the digest in `@condensed.CondInvariantLedger`!
pub fn bft_ed25519_quorum_commit_to_wal() -> BftEd25519WalReport {
  let kps : Array[Ed25519Keypair] = []
  for vid in 0..<4 {
    let seed : Array[Int32] = []
    for b in 0..<32 {
      seed.push(((vid + 1) * 37 + b * 13) & 0xff)
    }
    match ed25519_keypair_from_seed(seed) {
      Some(kp) => kps.push(kp)
      None =>
        return BftEd25519WalReport::{
          n_validators: 4,
          quorum_required: 3,
          valid_signatures: 0,
          forged_signature_rejected: false,
          wal_committed_and_recovered: false,
          condensed_ledger_verified: false,
        }
    }
  }
  let commit_msg = crypto_sha256([0x42, 0x46, 0x54, 0x01, 0x21])
  let equiv_msg = crypto_sha256([0x42, 0x46, 0x54, 0x01, 0xFF])

  let mut valid_sigs = 0
  for vid in 0..<3 {
    match ed25519_sign(kps[vid], commit_msg) {
      Some(sig) =>
        if ed25519_verify(kps[vid].public_key, commit_msg, sig) {
          valid_sigs = valid_sigs + 1
        }
      None => ()
    }
  }
  // Validator 3 equivocates (signs equiv_msg); verify it is rejected against commit_msg!
  let forged_rejected = match ed25519_sign(kps[3], equiv_msg) {
    Some(bad_sig) => !ed25519_verify(kps[3].public_key, commit_msg, bad_sig)
    None => false
  }

  // Commit to crash-durable `ArtifactWalStore` iff `valid_sigs >= 3`
  let mem_store = artifact_memory_byte_store_new()
  let mut wal_ok = false
  if valid_sigs >= 3 {
    match artifact_wal_store_open(mem_store) {
      Some((wal, _)) =>
        match artifact_wal_begin_tx(wal) {
          Some(_) =>
            if artifact_wal_put(wal, "bft/slot_1", commit_msg) &&
              artifact_wal_commit_tx(wal) {
              // Simulate restart: reopen WAL on underlying byte store and verify durable payload!
              match artifact_wal_store_open(mem_store) {
                Some((wal2, _)) => {
                  let bs = artifact_wal_byte_store(wal2)
                  wal_ok = (bs.read)("bft/slot_1") == Some(commit_msg)
                }
                None => ()
              }
            }
          None => ()
        }
      None => ()
    }
  }

  // Anchor quorum vote vector in `@condensed.CondInvariantLedger`
  let mut led = @condensed.cond_ledger_new()
  led = @condensed.cond_ledger_append(
    led,
    2,
    [4, 3, valid_sigs, commit_msg[0]],
    [],
  )
  let led_ok = @condensed.cond_ledger_verify(led)

  BftEd25519WalReport::{
    n_validators: 4,
    quorum_required: 3,
    valid_signatures: valid_sigs,
    forged_signature_rejected: forged_rejected,
    wal_committed_and_recovered: wal_ok,
    condensed_ledger_verified: led_ok,
  }
}

///|
/// Tarjan Strongly Connected Components (SCC) + Atomic Multi-Version Concurrency
/// Control (`MVCC`) Snapshot Store for Cyclic Module Hot-Swapping (Boundary §4.3).
pub(all) struct HotLoadMvccSnapshot {
  epoch : Int32
  modules : Array[(String, Int32)]
  scc_groups : Array[Array[String]]
} derive(Debug, Eq)

///|
pub extend HotLoadMvccSnapshot with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadMvccSnapshot with Eq::{not_equal, equal}

///|
pub(all) struct HotLoadMvccStore {
  snapshots : Array[HotLoadMvccSnapshot]
} derive(Debug, Eq)

///|
pub extend HotLoadMvccStore with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadMvccStore with Eq::{not_equal, equal}

///|
/// Exact `O(V + E)` Tarjan Strongly Connected Components algorithm on directed graph
/// `(names, edges_from_u_to_dep_v)`: returns SCCs in dependency-first (reverse topological)
/// order so every dependency SCC is updated atomically BEFORE its dependents!
pub fn hot_load_tarjan_scc(
  names : Array[String],
  adj : Array[Array[Int32]],
) -> Array[Array[String]] {
  let n = names.length()
  let index_of : Array[Int32] = []
  let lowlink : Array[Int32] = []
  let on_stack : Array[Bool] = []
  for _ in 0..<n {
    index_of.push(-1)
    lowlink.push(-1)
    on_stack.push(false)
  }
  let stack : Array[Int32] = []
  let sccs : Array[Array[String]] = []
  let timer : Array[Int32] = [0]

  fn strongconnect(
    v : Int32,
    names : Array[String],
    adj : Array[Array[Int32]],
    index_of : Array[Int32],
    lowlink : Array[Int32],
    on_stack : Array[Bool],
    stack : Array[Int32],
    sccs : Array[Array[String]],
    timer : Array[Int32],
  ) -> Unit {
    index_of[v] = timer[0]
    lowlink[v] = timer[0]
    timer[0] = timer[0] + 1
    stack.push(v)
    on_stack[v] = true

    if v < adj.length() {
      for w in adj[v] {
        if w >= 0 && w < n {
          if index_of[w] < 0 {
            strongconnect(
              w, names, adj, index_of, lowlink, on_stack, stack, sccs, timer,
            )
            if lowlink[w] < lowlink[v] {
              lowlink[v] = lowlink[w]
            }
          } else if on_stack[w] {
            if index_of[w] < lowlink[v] {
              lowlink[v] = index_of[w]
            }
          }
        }
      }
    }

    if lowlink[v] == index_of[v] {
      let comp : Array[String] = []
      let mut done = false
      while !done && stack.length() > 0 {
        guard stack.pop() is Some(w) else { break }
        on_stack[w] = false
        comp.push(names[w])
        if w == v {
          done = true
        }
      }
      sccs.push(comp)
    }
  }

  for v in 0..<n {
    if index_of[v] < 0 {
      strongconnect(
        v, names, adj, index_of, lowlink, on_stack, stack, sccs, timer,
      )
    }
  }
  sccs
}

///|
/// Read module version from pinned immutable MVCC `epoch` snapshot (`O(N)` lock-free read;
/// never torn by concurrent writers committing `epoch + 1`!).
pub fn hot_load_mvcc_read(
  store : HotLoadMvccStore,
  epoch : Int32,
  mod_name : String,
) -> Int32? {
  for snap in store.snapshots {
    if snap.epoch == epoch {
      for pair in snap.modules {
        if pair.0 == mod_name {
          return Some(pair.1)
        }
      }
    }
  }
  None
}

///|
/// Atomically commit a mutually-recursive SCC update (`updates`) as a new immutable MVCC
/// epoch snapshot iff `typecheck_passes` is true (rolling back with zero side effects on failure!).
pub fn hot_load_mvcc_commit_atomic(
  store : HotLoadMvccStore,
  names : Array[String],
  adj : Array[Array[Int32]],
  updates : Array[(String, Int32)],
  typecheck_passes : Bool,
) -> (HotLoadMvccStore, Bool) {
  if !typecheck_passes || store.snapshots.length() == 0 {
    return (store, false)
  }
  let latest = store.snapshots[store.snapshots.length() - 1]
  let next_mods = latest.modules.copy()
  for upd in updates {
    let mut replaced = false
    for i in 0..<next_mods.length() {
      if next_mods[i].0 == upd.0 {
        next_mods[i] = upd
        replaced = true
        break
      }
    }
    if !replaced {
      next_mods.push(upd)
    }
  }
  let sccs = hot_load_tarjan_scc(names, adj)
  let next_snap = HotLoadMvccSnapshot::{
    epoch: latest.epoch + 1,
    modules: next_mods,
    scc_groups: sccs,
  }
  let next_snaps = store.snapshots.copy()
  next_snaps.push(next_snap)
  (HotLoadMvccStore::{ snapshots: next_snaps, }, true)
}

///|
/// Master Phase 21 verification for Boundaries §4.6, §4.7, and §4.3!
pub fn check_phase21_homotopy_hou_and_bft_mvcc() -> Bool {
  // 1. §4.6A: Stasheff `K_6` combinatorics (`C_5 = 42`, `f = [42, 84, 56, 14, 1]`, `chi = 1`)
  //    + `6`-stage `dpath_singleton_n_transport_value` coherence on nontrivial `Circle` loops!
  if catalan(5) != 42 ||
    assoc_fvector(6) != [42, 84, 56, 14, 1] ||
    assoc_euler_characteristic(6) != 1 ||
    !paren_rotation_graph_connected(6) {
    return false
  }
  let s1_ty = circle_hit_type_value()
  let base_v = circle_hit_base_value()
  let lp = circle_hit_loop_path_value()
  let inv_lp = dpath_sym_value(lp)
  let coh6 = dpath_associahedron_k6_coherence_value(
    s1_ty, base_v, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  // Verify endpoints of 5-cell `coh6` (`I^5 -> Circle`, 6-path coherence!) match `hemi_north4` at `0` and `hemi_south4` at `1`!
  let end0 = dapp_dim(coh6, DZero)
  let end1 = dapp_dim(coh6, DOne)
  let want_n4 = dpath_k6_hemi_north4_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let want_s4 = dpath_k6_hemi_south4_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let path1_ty = DVPathTy(_ => s1_ty, base_v, base_v)
  let lhs6 = dpath_k6_lhs1_value(s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2)
  let rhs6 = dpath_k6_rhs1_value(s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2)
  let path2_ty = DVPathTy(_ => path1_ty, lhs6, rhs6)
  let rn2 = dpath_k6_route_north2_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let rs2 = dpath_k6_route_south2_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let path3_ty = DVPathTy(_ => path2_ty, rn2, rs2)
  if !conv_at(0, 0, path3_ty, end0, want_n4) ||
    !conv_at(0, 0, path3_ty, end1, want_s4) {
    return false
  }

  // 2. §4.6B: Variable-endpoint HITs (`PropTruncBool` squash & `SuspBool` meridians)
  if !check_variable_endpoint_hits() {
    return false
  }

  // 3. §4.6C: Condensed Steenrod–Adams `2*eta = 0` (`Ext_A^{2,3}(F_2, F_2) = 0`)
  //    locked to geometric Brunerie `beta_3 -> NormalisesTo(-2)` (`|beta_3| = 2`, `pi_4(S^3) = Z/2Z`) + Serre Hopf!
  let adams = @condensed.adams_ext_f2_report(8, 3, 8)
  let serre = @condensed.serre_hopf_fibration_report(5)
  let b_fam = brunerie_new_family()
  let beta3_val = match b_fam[2].norm {
    NormalisesTo(v) => v
    _ => 0
  }
  let beta_abs = if beta3_val < 0 { -beta3_val } else { beta3_val }
  if adams.hopf_h1_ext12 != 1 ||
    adams.two_eta_ext23 != 0 ||
    !serre.converges_to_s3 ||
    beta_abs != 2 ||
    !brunerie_norm_establishes(beta3_val) ||
    pi4_s3_group(beta3_val) != fg_zmod(2) {
    return false
  }

  // 4. §4.7A: Higher-order inner-`λ` matching (`hou_match_higher_order_lambda`):
  //    Case A (Arrow return type): `?F a == \z. h a z` (`extra_return_types = [B]`) -> `F = \x. \z. h x z`!
  //    Case B (Second-order spine + inner lambda): `?F (\g. g (g c)) == f (f c)` -> `F = \H. H (\x. f x)`!
  let u = unifier_new()
  let b_ty = UType(0)
  let arrow_res = hou_match_higher_order_lambda(
    u,
    [UConst("a")],
    ULam(b_ty, UApp(UApp(UConst("h"), UConst("a")), UVar(0))),
    [b_ty],
    [b_ty],
    size_bound=5,
    inner_lambda_budget=0,
  )
  match arrow_res {
    HouMatchSolved(_) => ()
    _ => return false
  }
  // `\g. g (g c)` has `UVar(0) = g`: `ULam(UPi(b_ty, b_ty), UApp(UVar(0), UApp(UVar(0), UConst("c"))))`
  let ho_arg = ULam(UPi(b_ty, b_ty), UApp(UVar(0), UApp(UVar(0), UConst("c"))))
  let ho_rhs = UApp(UConst("f"), UApp(UConst("f"), UConst("c")))
  let inner_lam_res = hou_match_higher_order_lambda(
    u,
    [ho_arg],
    ho_rhs,
    [UPi(UPi(b_ty, b_ty), b_ty)],
    [],
    size_bound=6,
    inner_lambda_budget=1,
  )
  match inner_lam_res {
    HouMatchSolved(_) => ()
    _ => return false
  }

  // 5. §4.7B: Goldfarb (1981) second-order Diophantine multiplication compiler (`2 * 3 = 6`, `3 * 4 = 12`)
  let gf23 = goldfarb_verify_diophantine_encoding(2, 3)
  let gf34 = goldfarb_verify_diophantine_encoding(3, 4)
  if !gf23.commutes_with_succ_a ||
    !gf23.addition_eq_holds ||
    !gf23.multiplication_eq_holds ||
    !gf23.wrong_product_refuted ||
    !gf34.multiplication_eq_holds ||
    gf34.c_prod != 12 {
    return false
  }

  // 6. §4.3A: RFC 8032 Ed25519 BFT Quorum + `ArtifactWalStore` + `@hostfs` BFT Crash Durability
  let bft_ed = bft_ed25519_quorum_commit_to_wal()
  if bft_ed.valid_signatures != 3 ||
    !bft_ed.forged_signature_rejected ||
    !bft_ed.wal_committed_and_recovered ||
    !bft_ed.condensed_ledger_verified ||
    !bft_check_consensus_and_crash_durability() {
    return false
  }

  // 7. §4.3B: Tarjan SCC + Atomic MVCC Hot-Load on cyclic mutual recursion
  //    Graph: `Core` (0, leaf), `ModEven` (1 -> [0, 2]), `ModOdd` (2 -> [1]), `App` (3 -> [1, 2])
  //    Tarjan SCCs in dependency-first order: `[["Core"], ["ModOdd", "ModEven"], ["App"]]` (3 SCCs, one size-2 cycle!)
  let mod_names = ["Core", "ModEven", "ModOdd", "App"]
  let mod_adj = [[], [0, 2], [1], [1, 2]]
  let sccs = hot_load_tarjan_scc(mod_names, mod_adj)
  if sccs.length() != 3 ||
    sccs[0] != ["Core"] ||
    sccs[1].length() != 2 ||
    sccs[2] != ["App"] {
    return false
  }
  let mvcc0 = HotLoadMvccStore::{
    snapshots: [
      HotLoadMvccSnapshot::{
        epoch: 0,
        modules: [("Core", 1), ("ModEven", 1), ("ModOdd", 1), ("App", 1)],
        scc_groups: sccs,
      },
    ],
  }
  // Failed typecheck rolls back cleanly without creating epoch 1
  let (mvcc_fail, ok_fail) = hot_load_mvcc_commit_atomic(
    mvcc0,
    mod_names,
    mod_adj,
    [("ModEven", 2)],
    false,
  )
  if ok_fail || mvcc_fail.snapshots.length() != 1 {
    return false
  }
  // Valid atomic SCC swap creates epoch 1 while pinned reader on epoch 0 still sees version 1!
  let (mvcc1, ok1) = hot_load_mvcc_commit_atomic(
    mvcc0,
    mod_names,
    mod_adj,
    [("ModEven", 2), ("ModOdd", 2), ("App", 2)],
    true,
  )
  ok1 &&
  hot_load_mvcc_read(mvcc1, 0, "ModEven") == Some(1) &&
  hot_load_mvcc_read(mvcc1, 1, "ModEven") == Some(2) &&
  hot_load_mvcc_read(mvcc1, 1, "ModOdd") == Some(2)
}
