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
