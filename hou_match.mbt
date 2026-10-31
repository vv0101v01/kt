///|
// Higher-order MATCHING: the decidable side of the HOU boundary.
//
// SPEC section 4 records that higher-order unification is undecidable
// (Goldfarb 1981: already at order 2), and `hou_elaborator.mbt`
// therefore implements the Miller pattern fragment plus a bounded Huet
// search.  That is the right response for *unification*.  But the
// boundary is not the whole story, and the story matters:
//
//   * unification  -- undecidable from order 2 (Goldfarb 1981)
//   * matching     -- DECIDABLE at every order
//                     (2nd: Huet & Lang 1978; 3rd: Dowek 1992;
//                      4th: Padovani 2000; all orders: Stirling 2009)
//
// Matching is the one-sided problem: `?F t1 .. tn  ==  u` with the
// right-hand side ground (no metavariables).  It is what rewriting,
// lemma application and proof search actually need.
//
// What this file provides, stated precisely:
//
//   SOUNDNESS (unconditional).  Every returned solution is verified:
//   the candidate is applied to the spine, normalized, and compared
//   with the right-hand side by beta/eta conversion.  Nothing is
//   returned on trust.
//
//   COMPLETENESS (pattern spine, unconditional).  When the spine
//   consists of distinct bound variables, the solution is unique and
//   is computed directly -- no bound is involved, and the answer is
//   definitive.
//
//   COMPLETENESS (general spine, within the enumerated space).  The
//   search enumerates candidate bodies of size <= `size_bound` built
//   from the spine variables and the constants occurring in the
//   problem.  If nothing verifies, the answer is reported as
//   `HouMatchNoneWithinBound(bound)`, NEVER as "no solution exists".
//   Stirling's theorem guarantees a finite bound suffices at every
//   order; this file does not compute that bound, so it exposes the
//   bound as part of the answer instead of asserting one.
//
//   SCOPE, stated honestly.  Bodies are enumerated without inner
//   lambdas, so the result type after the spine is assumed
//   first-order.  Function-typed results fall outside the enumerated
//   space and are reported as `HouMatchNoneWithinBound`, not as a
//   solved match.

///|
/// The outcome of a matching attempt.
pub enum HouMatchResult {
  /// A solution, verified by beta/eta conversion against the constraint.
  HouMatchSolved(UTerm)
  /// Every candidate of size `<= bound` was tried; none verified.  This
  /// is a statement about the bound, not about existence.
  HouMatchNoneWithinBound(Int32)
  /// The node budget ran out before the bound was exhausted.
  HouMatchBudgetExceeded(Int32)
} derive(Debug, Eq)

///|
pub extend HouMatchResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouMatchResult with Eq::{not_equal, equal}

// ---------------------------------------------------------------------------
// Normalization and conversion
// ---------------------------------------------------------------------------

///|
/// Deep beta / projection / Nat normalization.
fn hou_norm(t : UTerm, u : Unifier) -> UTerm {
  match uterm_whnf(t, u) {
    ULam(a, b) => ULam(hou_norm(a, u), hou_norm(b, u))
    UApp(f, x) => UApp(hou_norm(f, u), hou_norm(x, u))
    UPi(a, b) => UPi(hou_norm(a, u), hou_norm(b, u))
    UImplicitPi(a, b) => UImplicitPi(hou_norm(a, u), hou_norm(b, u))
    USigma(a, b) => USigma(hou_norm(a, u), hou_norm(b, u))
    UPair(a, b) => UPair(hou_norm(a, u), hou_norm(b, u))
    UFst(x) => UFst(hou_norm(x, u))
    USnd(x) => USnd(hou_norm(x, u))
    USucc(x) => USucc(hou_norm(x, u))
    UNatElim(a, b, c, d) =>
      UNatElim(hou_norm(a, u), hou_norm(b, u), hou_norm(c, u), hou_norm(d, u))
    other => other
  }
}

///|
fn hou_var_free(t : UTerm, level : Int32) -> Bool {
  match t {
    UVar(i) => i == level
    UMeta(_, args) => {
      for i in 0..<args.length() {
        if hou_var_free(args[i], level) {
          return true
        }
      }
      false
    }
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => false
    ULam(a, b)
    | UApp(a, b)
    | UPi(a, b)
    | UImplicitPi(a, b)
    | USigma(a, b)
    | UPair(a, b) => hou_var_free(a, level) || hou_var_free(b, level)
    UFst(x) | USnd(x) | USucc(x) => hou_var_free(x, level)
    UNatElim(a, b, c, d) =>
      hou_var_free(a, level) ||
      hou_var_free(b, level) ||
      hou_var_free(c, level) ||
      hou_var_free(d, level)
  }
}

///|
/// Eta-contract `ULam(_, UApp(f, UVar(0)))` to `f` whenever `UVar(0)`
/// does not occur in `f`.
fn hou_eta_short(t : UTerm) -> UTerm {
  match t {
    ULam(a, body) =>
      match hou_eta_short(body) {
        UApp(f, UVar(0)) =>
          if !hou_var_free(f, 0) {
            hou_eta_short(uterm_shift(f, -1, 0))
          } else {
            ULam(a, UApp(f, UVar(0)))
          }
        b2 => ULam(a, b2)
      }
    UApp(f, x) => UApp(hou_eta_short(f), hou_eta_short(x))
    UPi(a, b) => UPi(hou_eta_short(a), hou_eta_short(b))
    UImplicitPi(a, b) => UImplicitPi(hou_eta_short(a), hou_eta_short(b))
    USigma(a, b) => USigma(hou_eta_short(a), hou_eta_short(b))
    UPair(a, b) => UPair(hou_eta_short(a), hou_eta_short(b))
    UFst(x) => UFst(hou_eta_short(x))
    USnd(x) => USnd(hou_eta_short(x))
    USucc(x) => USucc(hou_eta_short(x))
    UNatElim(a, b, c, d) =>
      UNatElim(
        hou_eta_short(a),
        hou_eta_short(b),
        hou_eta_short(c),
        hou_eta_short(d),
      )
    other => other
  }
}

///|
/// Beta/eta conversion for ground terms under a unifier.
pub fn hou_conv(a : UTerm, b : UTerm, u : Unifier) -> Bool {
  let x = hou_eta_short(hou_norm(a, u))
  let y = hou_eta_short(hou_norm(b, u))
  x == y
}

// ---------------------------------------------------------------------------
// Building and checking candidate solutions
// ---------------------------------------------------------------------------

///|
/// Rename free variables: `UVar(from[i])` becomes `UVar(to[i])`.
fn hou_rename_vars(t : UTerm, from : Array[Int32], to : Array[Int32]) -> UTerm {
  match t {
    UVar(i) => {
      for k in 0..<from.length() {
        if from[k] == i {
          return UVar(to[k])
        }
      }
      UVar(i)
    }
    UMeta(id, args) => {
      let out : Array[UTerm] = []
      for i in 0..<args.length() {
        out.push(hou_rename_vars(args[i], from, to))
      }
      UMeta(id, out)
    }
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => t
    ULam(a, b) =>
      ULam(hou_rename_vars(a, from, to), hou_rename_vars(b, from, to))
    UApp(a, b) =>
      UApp(hou_rename_vars(a, from, to), hou_rename_vars(b, from, to))
    UPi(a, b) => UPi(hou_rename_vars(a, from, to), hou_rename_vars(b, from, to))
    UImplicitPi(a, b) =>
      UImplicitPi(hou_rename_vars(a, from, to), hou_rename_vars(b, from, to))
    USigma(a, b) =>
      USigma(hou_rename_vars(a, from, to), hou_rename_vars(b, from, to))
    UPair(a, b) =>
      UPair(hou_rename_vars(a, from, to), hou_rename_vars(b, from, to))
    UFst(x) => UFst(hou_rename_vars(x, from, to))
    USnd(x) => USnd(hou_rename_vars(x, from, to))
    USucc(x) => USucc(hou_rename_vars(x, from, to))
    UNatElim(a, b, c, d) =>
      UNatElim(
        hou_rename_vars(a, from, to),
        hou_rename_vars(b, from, to),
        hou_rename_vars(c, from, to),
        hou_rename_vars(d, from, to),
      )
  }
}

///|
/// Wrap `body` in `n` lambdas whose domains are `types`, shifted as the
/// telescope is entered.
fn hou_wrap_lams(types : Array[UTerm], body : UTerm) -> UTerm {
  let mut out = body
  let mut i = types.length() - 1
  while i >= 0 {
    out = ULam(uterm_shift(types[i], i, 0), out)
    i = i - 1
  }
  out
}

///|
fn hou_collect_consts(t : UTerm, acc : Array[String]) -> Unit {
  match t {
    UConst(name) => {
      let mut seen = false
      for i in 0..<acc.length() {
        if acc[i] == name {
          seen = true
        }
      }
      if !seen {
        acc.push(name)
      }
    }
    UMeta(_, args) =>
      for i in 0..<args.length() {
        hou_collect_consts(args[i], acc)
      }
    UVar(_) | UType(_) | UBoolLit(_) | UNatZero => ()
    ULam(a, b)
    | UApp(a, b)
    | UPi(a, b)
    | UImplicitPi(a, b)
    | USigma(a, b)
    | UPair(a, b) => {
      hou_collect_consts(a, acc)
      hou_collect_consts(b, acc)
    }
    UFst(x) | USnd(x) | USucc(x) => hou_collect_consts(x, acc)
    UNatElim(a, b, c, d) => {
      hou_collect_consts(a, acc)
      hou_collect_consts(b, acc)
      hou_collect_consts(c, acc)
      hou_collect_consts(d, acc)
    }
  }
}

///|
/// Enumerate lambda-free terms of size `<= max_size` over `vars` bound
/// variables and the given constants.  `nodes` is a one-element mutable
/// counter used to enforce the budget.
fn hou_enum_bodies(
  vars : Int32,
  consts : Array[String],
  max_size : Int32,
  nodes : Array[Int32],
  node_budget : Int32,
) -> Array[UTerm] {
  let by_size : Array[Array[UTerm]] = []
  by_size.push([]) // index 0 unused
  let size1 : Array[UTerm] = []
  let mut i = 0
  while i < vars {
    size1.push(UVar(i))
    i = i + 1
  }
  for j in 0..<consts.length() {
    size1.push(UConst(consts[j]))
  }
  by_size.push(size1)
  nodes[0] = nodes[0] + size1.length()
  let mut s = 2
  while s <= max_size {
    if nodes[0] > node_budget {
      // Stop growing; report the budget outcome.
      s = max_size + 1
      continue
    }
    let cur : Array[UTerm] = []
    let mut a = 1
    while a < s {
      let b = s - a - 1
      if b >= 1 {
        let fs = by_size[a]
        let xs = by_size[b]
        for p in 0..<fs.length() {
          for q in 0..<xs.length() {
            if nodes[0] > node_budget {
              break
            }
            cur.push(UApp(fs[p], xs[q]))
            nodes[0] = nodes[0] + 1
          }
        }
      }
      a = a + 1
    }
    by_size.push(cur)
    s = s + 1
  }
  let out : Array[UTerm] = []
  for k in 1..<by_size.length() {
    for p in 0..<by_size[k].length() {
      out.push(by_size[k][p])
    }
  }
  out
}

///|
/// True when every entry of the spine is a bound variable and those
/// variables are pairwise distinct.
fn hou_spine_is_distinct_vars(spine : Array[UTerm]) -> Bool {
  let mut i = 0
  while i < spine.length() {
    match spine[i] {
      UVar(level) => {
        let mut j = 0
        while j < i {
          match spine[j] {
            UVar(other) => if other == level { return false }
            _ => return false
          }
          j = j + 1
        }
      }
      _ => return false
    }
    i = i + 1
  }
  true
}

// ---------------------------------------------------------------------------
// The matcher
// ---------------------------------------------------------------------------

///|
/// Solve the matching problem `?meta_id spine  ==  rhs`.
///
/// `param_types` gives the domains of the metavariable's arguments; it
/// is only used to type the lambdas of the returned solution, never to
/// decide the answer.
pub fn hou_match(
  unifier : Unifier,
  meta_id : Int32,
  spine : Array[UTerm],
  rhs : UTerm,
  param_types : Array[UTerm],
  size_bound~ : Int32 = 6,
  node_budget~ : Int32 = 50000,
) -> HouMatchResult {
  // Matching only makes sense for an existing, still-unsolved meta.
  if meta_id < 0 || meta_id >= unifier.metas.length() {
    return HouMatchNoneWithinBound(size_bound)
  }
  if unifier.metas[meta_id].solution is Some(_) {
    return HouMatchNoneWithinBound(size_bound)
  }
  let n = spine.length()
  if n != param_types.length() {
    return HouMatchNoneWithinBound(size_bound)
  }
  // Matching requires a ground right-hand side and a ground spine.
  if uterm_contains_unsolved_meta(rhs, unifier) {
    return HouMatchNoneWithinBound(size_bound)
  }
  for i in 0..<n {
    if uterm_contains_unsolved_meta(spine[i], unifier) {
      return HouMatchNoneWithinBound(size_bound)
    }
  }

  // ---- Fast path: distinct-variable spine. -----------------------------
  // Here the solution is unique and no bound is involved: substituting
  // ?F := \x1..xn. M into (?F x1 .. xn) yields M itself, so M must be
  // convertible to rhs.
  if hou_spine_is_distinct_vars(spine) {
    let from : Array[Int32] = []
    let to : Array[Int32] = []
    let mut i = 0
    while i < n {
      match spine[i] {
        UVar(level) => {
          from.push(level + n)
          to.push(n - 1 - i)
        }
        _ => ()
      }
      i = i + 1
    }
    let body = hou_rename_vars(uterm_shift(rhs, n, 0), from, to)
    let solution = hou_wrap_lams(param_types, body)
    if hou_conv(uterm_apply_many(solution, spine), rhs, unifier) {
      return HouMatchSolved(solution)
    }
    return HouMatchNoneWithinBound(size_bound)
  }

  // ---- General spine: bounded enumeration with verification. ----------
  let consts : Array[String] = []
  hou_collect_consts(rhs, consts)
  for i in 0..<n {
    hou_collect_consts(spine[i], consts)
  }
  let nodes : Array[Int32] = [0]
  let candidates = hou_enum_bodies(n, consts, size_bound, nodes, node_budget)
  for i in 0..<candidates.length() {
    let solution = hou_wrap_lams(param_types, candidates[i])
    if hou_conv(uterm_apply_many(solution, spine), rhs, unifier) {
      return HouMatchSolved(solution)
    }
  }
  if nodes[0] > node_budget {
    HouMatchBudgetExceeded(size_bound)
  } else {
    HouMatchNoneWithinBound(size_bound)
  }
}

///|
/// Convenience: does a matching problem have a verified solution within
/// the bound?
pub fn hou_match_solved_within(
  unifier : Unifier,
  meta_id : Int32,
  spine : Array[UTerm],
  rhs : UTerm,
  param_types : Array[UTerm],
  size_bound~ : Int32 = 6,
) -> Bool {
  match hou_match(unifier, meta_id, spine, rhs, param_types, size_bound~) {
    HouMatchSolved(_) => true
    _ => false
  }
}

// ---------------------------------------------------------------------------
// Law
// ---------------------------------------------------------------------------

///|
/// Mint a fresh metavariable and return its id.  The matcher refuses
/// unknown or already-solved metas, so tests must register real ones.
fn hou_mk_meta(u : Unifier) -> Int32 {
  match hou_fresh_meta(u, 0) {
    UMeta(id, _) => id
    _ => -1
  }
}

///|
fn hou_c(name : String) -> UTerm {
  UConst(name)
}

///|
fn hou_app2(f : UTerm, a : UTerm, b : UTerm) -> UTerm {
  UApp(UApp(f, a), b)
}

///|
fn hou_b_ty() -> UTerm {
  UType(0)
}

///|
/// True when the result is a verified solution of the original
/// constraint.  The solution is re-checked here rather than trusted.
fn hou_solves(
  r : HouMatchResult,
  u : Unifier,
  spine : Array[UTerm],
  rhs : UTerm,
) -> Bool {
  match r {
    HouMatchSolved(sol) => hou_conv(uterm_apply_many(sol, spine), rhs, u)
    _ => false
  }
}

///|
fn hou_is_none_within(r : HouMatchResult, bound : Int32) -> Bool {
  match r {
    HouMatchNoneWithinBound(b) => b == bound
    _ => false
  }
}

///|
fn hou_is_solved(r : HouMatchResult) -> Bool {
  match r {
    HouMatchSolved(_) => true
    _ => false
  }
}

///|
/// Higher-order matching: the decidable side of the HOU boundary.
pub fn check_hou_matching() -> Bool {
  let u = unifier_new()
  let ty2 = [hou_b_ty(), hou_b_ty()]
  let m1 = hou_mk_meta(u)
  let m2 = hou_mk_meta(u)
  let m3 = hou_mk_meta(u)
  let m4 = hou_mk_meta(u)
  let m5 = hou_mk_meta(u)
  let m6 = hou_mk_meta(u)
  let m7 = hou_mk_meta(u)

  // (1) Distinct-variable spine: the solution is unique and no bound is
  //     involved.  ?F x y == and(x, y)
  let rhs1 = hou_app2(hou_c("and"), UVar(0), UVar(1))
  let spine1 = [UVar(0), UVar(1)]
  let solved1 = hou_solves(hou_match(u, m1, spine1, rhs1, ty2), u, spine1, rhs1)

  // (2) Repeated spine: ?F x x == g x.  Projection onto either argument
  //     works; whichever is found must verify.
  let rhs2 = UApp(hou_c("g"), UVar(0))
  let spine2 = [UVar(0), UVar(0)]
  let solved2 = hou_solves(hou_match(u, m2, spine2, rhs2, ty2), u, spine2, rhs2)

  // (3) Honest incompleteness -- and it must be a REAL bound, so the
  //     spine is repeated (a distinct-variable spine takes the unique
  //     fast path and needs no bound at all).  ?F x x == f(f(f x))
  //     needs a body of size 5.
  let rhs3 = UApp(hou_c("f"), UApp(hou_c("f"), UApp(hou_c("f"), UVar(0))))
  let spine3 = [UVar(0), UVar(0)]
  let too_small = hou_match(u, m3, spine3, rhs3, ty2, size_bound=3)
  let big_enough = hou_match(u, m3, spine3, rhs3, ty2, size_bound=7)
  let bound_ok = hou_is_none_within(too_small, 3) &&
    hou_solves(big_enough, u, spine3, rhs3) &&
    // The bound is reported, so a caller can always tell "not within 3"
    // apart from "does not exist".
    !hou_is_solved(too_small)

  // (4) Enumeration also solves the diagonal: ?F x x == x, whose two
  //     solutions are the two projections.
  let spine4 = [UVar(0), UVar(0)]
  let identity_ok = hou_solves(
    hou_match(u, m4, spine4, UVar(0), ty2, size_bound=3),
    u,
    spine4,
    UVar(0),
  )

  // (5) Soundness guard: a metavariable on the right-hand side is not a
  //     matching problem, so it is refused rather than guessed at.
  let meta_rhs = UApp(hou_c("g"), UMeta(9999, []))
  let guard_ok = hou_is_none_within(hou_match(u, m5, spine4, meta_rhs, ty2), 6)

  // (6) A repeated spine with a non-trivial right-hand side:
  //     ?F x x == g x, again solved within a small bound.
  let rhs6 = UApp(hou_c("g"), UVar(0))
  let rep_ok = hou_solves(
    hou_match(u, m6, spine4, rhs6, ty2, size_bound=3),
    u,
    spine4,
    rhs6,
  )

  // (7) The conversion checker: beta, eta, and a negative case.
  let idterm = ULam(hou_b_ty(), UVar(0))
  let conv_ok = hou_conv(UApp(idterm, hou_c("z")), hou_c("z"), u) &&
    hou_conv(ULam(hou_b_ty(), UApp(hou_c("g"), UVar(0))), hou_c("g"), u) &&
    hou_conv(
      UApp(ULam(hou_b_ty(), UApp(hou_c("g"), UVar(0))), hou_c("z")),
      UApp(hou_c("g"), hou_c("z")),
      u,
    ) &&
    !hou_conv(hou_c("a"), hou_c("b"), u)

  // (7) Matching is strictly stronger than unification on ground
  //     right-hand sides: the pattern unifier needs a variable spine,
  //     while the matcher also handles a non-variable one.  The repeated
  //     spine of case (2) is exactly the case `hou_unify_mgu` must
  //     leave as a residual.
  let nonvar_ok = hou_is_solved(hou_match(u, m7, spine2, rhs2, ty2)) &&
    hou_is_solved(hou_match(u, m1, spine1, rhs1, ty2))

  solved1 &&
  solved2 &&
  bound_ok &&
  identity_ok &&
  guard_ok &&
  rep_ok &&
  conv_ok &&
  nonvar_ok
}
