///|
using @kernel {type DTerm, d_nat_lit, dep_check_closed, dep_nf_closed}

///|
// Pattern higher-order unification and a bidirectional elaborator.
//
// Full higher-order unification is undecidable, so the unifier here
// implements the useful Miller pattern fragment: a flexible head
// `?F x1 ... xn`, where the xi are distinct bound variables, is
// solved by abstracting exactly those variables.  Rigid/rigid
// decomposition, beta/eta/projection reduction, occurs and scope
// checks, closed non-pattern assignment, and flex-headed applications
// are also handled.  Phase 9 adds three further sound fragments:
// repeated-variable spines, constructor-pattern spines whose leaves
// can be extracted with `pred`/`fst`/`snd`, and distinct flex-flex
// intersection through a fresh common metavariable.  This deterministic
// fragment is what the elaborator uses synchronously for implicit
// arguments and dependent motives.  Phase 10 adds a separate bounded,
// transactional Huet search (`hou_search_unify`) above it; its
// residual/budget outcomes are explicit and are not completeness
// claims for general HOU.  Phase 12 adds `hou_unify_mgu`, a
// worklist pattern unifier whose solved outcome is a certified
// most general unifier and whose residual outcome returns the
// remaining constraints under a principal partial substitution.
//
// The bidirectional elaborator consumes a named surface syntax,
// inserts implicit arguments as metavariables, infers/checks against
// UTerm types, solves the resulting HOU constraints, beta/eta
// optimizes the zonked core term, and finally translates it to the
// project's DTerm.  The laws validate those DTerms with the ordinary
// dependent checker.

///|
pub(all) enum UTerm {
  UVar(Int32)
  UMeta(Int32, Array[UTerm])
  UConst(String)
  UType(Int32)
  ULam(UTerm, UTerm)
  UApp(UTerm, UTerm)
  UPi(UTerm, UTerm)
  UImplicitPi(UTerm, UTerm)
  USigma(UTerm, UTerm)
  UPair(UTerm, UTerm)
  UFst(UTerm)
  USnd(UTerm)
  UBoolLit(Bool)
  UNatZero
  USucc(UTerm)
  UNatElim(UTerm, UTerm, UTerm, UTerm)
} derive(Debug, Eq)

///|
pub extend UTerm with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend UTerm with Eq::{not_equal, equal}

///|
pub fn uty_bool() -> UTerm {
  UConst("Bool")
}

///|
pub fn uty_nat() -> UTerm {
  UConst("Nat")
}

///|
pub fn uty_unit() -> UTerm {
  UConst("Unit")
}

///|
pub fn uty_arrow(a : UTerm, b : UTerm) -> UTerm {
  UPi(a, uterm_shift(b, 1, 0))
}

///|

///|
pub struct UMetaInfo {
  context_depth : Int32
  mut solution : UTerm?
} derive(Debug, Eq)

///|
pub extend UMetaInfo with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend UMetaInfo with Eq::{not_equal, equal}

///|
pub struct Unifier {
  metas : Array[UMetaInfo]
  mut solved_count : Int32
} derive(Debug, Eq)

///|
pub extend Unifier with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Unifier with Eq::{not_equal, equal}

///|
pub fn unifier_new() -> Unifier {
  Unifier::{ metas: [], solved_count: 0, }
}

///|
fn uterm_shift(t : UTerm, amount : Int32, cutoff : Int32) -> UTerm {
  match t {
    UVar(i) => if i >= cutoff { UVar(i + amount) } else { UVar(i) }
    UMeta(id, args) => {
      let out : Array[UTerm] = []
      for i in 0..<args.length() {
        out.push(uterm_shift(args[i], amount, cutoff))
      }
      UMeta(id, out)
    }
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => t
    ULam(dom, body) =>
      ULam(
        uterm_shift(dom, amount, cutoff),
        uterm_shift(body, amount, cutoff + 1),
      )
    UApp(f, x) =>
      UApp(uterm_shift(f, amount, cutoff), uterm_shift(x, amount, cutoff))
    UPi(a, b) =>
      UPi(uterm_shift(a, amount, cutoff), uterm_shift(b, amount, cutoff + 1))
    UImplicitPi(a, b) =>
      UImplicitPi(
        uterm_shift(a, amount, cutoff),
        uterm_shift(b, amount, cutoff + 1),
      )
    USigma(a, b) =>
      USigma(uterm_shift(a, amount, cutoff), uterm_shift(b, amount, cutoff + 1))
    UPair(a, b) =>
      UPair(uterm_shift(a, amount, cutoff), uterm_shift(b, amount, cutoff))
    UFst(x) => UFst(uterm_shift(x, amount, cutoff))
    USnd(x) => USnd(uterm_shift(x, amount, cutoff))
    USucc(x) => USucc(uterm_shift(x, amount, cutoff))
    UNatElim(m, z, s, scrut) =>
      UNatElim(
        uterm_shift(m, amount, cutoff),
        uterm_shift(z, amount, cutoff),
        uterm_shift(s, amount, cutoff),
        uterm_shift(scrut, amount, cutoff),
      )
  }
}

///|
/// Beta substitution: replace de Bruijn index `index + binder_depth`
/// by the (suitably shifted) replacement and lower higher indices.
fn uterm_subst(
  t : UTerm,
  replacement : UTerm,
  index : Int32,
  binder_depth : Int32,
) -> UTerm {
  match t {
    UVar(i) =>
      if i == index + binder_depth {
        uterm_shift(replacement, binder_depth, 0)
      } else if i > index + binder_depth {
        UVar(i - 1)
      } else {
        UVar(i)
      }
    UMeta(id, args) => {
      let out : Array[UTerm] = []
      for i in 0..<args.length() {
        out.push(uterm_subst(args[i], replacement, index, binder_depth))
      }
      UMeta(id, out)
    }
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => t
    ULam(dom, body) =>
      ULam(
        uterm_subst(dom, replacement, index, binder_depth),
        uterm_subst(body, replacement, index, binder_depth + 1),
      )
    UApp(f, x) =>
      UApp(
        uterm_subst(f, replacement, index, binder_depth),
        uterm_subst(x, replacement, index, binder_depth),
      )
    UPi(a, b) =>
      UPi(
        uterm_subst(a, replacement, index, binder_depth),
        uterm_subst(b, replacement, index, binder_depth + 1),
      )
    UImplicitPi(a, b) =>
      UImplicitPi(
        uterm_subst(a, replacement, index, binder_depth),
        uterm_subst(b, replacement, index, binder_depth + 1),
      )
    USigma(a, b) =>
      USigma(
        uterm_subst(a, replacement, index, binder_depth),
        uterm_subst(b, replacement, index, binder_depth + 1),
      )
    UPair(a, b) =>
      UPair(
        uterm_subst(a, replacement, index, binder_depth),
        uterm_subst(b, replacement, index, binder_depth),
      )
    UFst(x) => UFst(uterm_subst(x, replacement, index, binder_depth))
    USnd(x) => USnd(uterm_subst(x, replacement, index, binder_depth))
    USucc(x) => USucc(uterm_subst(x, replacement, index, binder_depth))
    UNatElim(m, z, s, scrut) =>
      UNatElim(
        uterm_subst(m, replacement, index, binder_depth),
        uterm_subst(z, replacement, index, binder_depth),
        uterm_subst(s, replacement, index, binder_depth),
        uterm_subst(scrut, replacement, index, binder_depth),
      )
  }
}

///|
fn uterm_instantiate(body : UTerm, arg : UTerm) -> UTerm {
  uterm_subst(body, arg, 0, 0)
}

///|
fn uterm_apply_many(f : UTerm, args : Array[UTerm]) -> UTerm {
  let mut out = f
  for i in 0..<args.length() {
    out = UApp(out, args[i])
  }
  out
}

///|
pub fn uterm_whnf(t : UTerm, unifier : Unifier) -> UTerm {
  match t {
    UMeta(id, args) =>
      if id >= 0 && id < unifier.metas.length() {
        match unifier.metas[id].solution {
          Some(solution) =>
            uterm_whnf(uterm_apply_many(solution, args), unifier)
          None => t
        }
      } else {
        t
      }
    UApp(f, x) =>
      match uterm_whnf(f, unifier) {
        ULam(_, body) => uterm_whnf(uterm_instantiate(body, x), unifier)
        f2 => UApp(f2, x)
      }
    UFst(x) =>
      match uterm_whnf(x, unifier) {
        UPair(a, _) => uterm_whnf(a, unifier)
        x2 => UFst(x2)
      }
    USnd(x) =>
      match uterm_whnf(x, unifier) {
        UPair(_, b) => uterm_whnf(b, unifier)
        x2 => USnd(x2)
      }
    UNatElim(m, z, s, scrut) =>
      match uterm_whnf(scrut, unifier) {
        UNatZero => uterm_whnf(z, unifier)
        USucc(pred) =>
          uterm_whnf(UApp(UApp(s, pred), UNatElim(m, z, s, pred)), unifier)
        scrut2 => UNatElim(m, z, s, scrut2)
      }
    _ => t
  }
}

///|
/// Substitute solved metavariables and beta/projection/Nat-reduce
/// recursively.  This is the semantic optimization pass run before
/// translation to DTerm.
pub fn hou_semantic_optimize(t : UTerm, unifier : Unifier) -> UTerm {
  match uterm_whnf(t, unifier) {
    ULam(dom, body) =>
      ULam(
        hou_semantic_optimize(dom, unifier),
        hou_semantic_optimize(body, unifier),
      )
    UApp(f, x) =>
      UApp(hou_semantic_optimize(f, unifier), hou_semantic_optimize(x, unifier))
    UPi(a, b) =>
      UPi(hou_semantic_optimize(a, unifier), hou_semantic_optimize(b, unifier))
    UImplicitPi(a, b) =>
      UImplicitPi(
        hou_semantic_optimize(a, unifier),
        hou_semantic_optimize(b, unifier),
      )
    USigma(a, b) =>
      USigma(
        hou_semantic_optimize(a, unifier),
        hou_semantic_optimize(b, unifier),
      )
    UPair(a, b) =>
      UPair(
        hou_semantic_optimize(a, unifier),
        hou_semantic_optimize(b, unifier),
      )
    UFst(x) => UFst(hou_semantic_optimize(x, unifier))
    USnd(x) => USnd(hou_semantic_optimize(x, unifier))
    USucc(x) => USucc(hou_semantic_optimize(x, unifier))
    UNatElim(m, z, s, scrut) =>
      UNatElim(
        hou_semantic_optimize(m, unifier),
        hou_semantic_optimize(z, unifier),
        hou_semantic_optimize(s, unifier),
        hou_semantic_optimize(scrut, unifier),
      )
    UVar(i) => UVar(i)
    UMeta(id, args) => {
      let out : Array[UTerm] = []
      for i in 0..<args.length() {
        out.push(hou_semantic_optimize(args[i], unifier))
      }
      UMeta(id, out)
    }
    UConst(name) => UConst(name)
    UType(level) => UType(level)
    UBoolLit(value) => UBoolLit(value)
    UNatZero => UNatZero
  }
}

///|
pub fn uterm_contains_unsolved_meta(t : UTerm, unifier : Unifier) -> Bool {
  match uterm_whnf(t, unifier) {
    UMeta(_, _) => true
    UVar(_) | UConst(_) | UType(_) | UBoolLit(_) | UNatZero => false
    ULam(a, b)
    | UApp(a, b)
    | UPi(a, b)
    | UImplicitPi(a, b)
    | USigma(a, b)
    | UPair(a, b) =>
      uterm_contains_unsolved_meta(a, unifier) ||
      uterm_contains_unsolved_meta(b, unifier)
    UFst(x) | USnd(x) | USucc(x) => uterm_contains_unsolved_meta(x, unifier)
    UNatElim(a, b, c, d) =>
      uterm_contains_unsolved_meta(a, unifier) ||
      uterm_contains_unsolved_meta(b, unifier) ||
      uterm_contains_unsolved_meta(c, unifier) ||
      uterm_contains_unsolved_meta(d, unifier)
  }
}

///|
fn uterm_occurs_meta(t : UTerm, id : Int32, unifier : Unifier) -> Bool {
  match t {
    UMeta(other, args) => {
      if other == id {
        return true
      }
      let other_solution = if other >= 0 && other < unifier.metas.length() {
        unifier.metas[other].solution
      } else {
        None
      }
      match other_solution {
        Some(solution) =>
          uterm_occurs_meta(uterm_apply_many(solution, args), id, unifier)
        None => {
          for i in 0..<args.length() {
            if uterm_occurs_meta(args[i], id, unifier) {
              return true
            }
          }
          false
        }
      }
    }
    UVar(_) | UConst(_) | UType(_) | UBoolLit(_) | UNatZero => false
    ULam(a, b)
    | UApp(a, b)
    | UPi(a, b)
    | UImplicitPi(a, b)
    | USigma(a, b)
    | UPair(a, b) =>
      uterm_occurs_meta(a, id, unifier) || uterm_occurs_meta(b, id, unifier)
    UFst(x) | USnd(x) | USucc(x) => uterm_occurs_meta(x, id, unifier)
    UNatElim(a, b, c, d) =>
      uterm_occurs_meta(a, id, unifier) ||
      uterm_occurs_meta(b, id, unifier) ||
      uterm_occurs_meta(c, id, unifier) ||
      uterm_occurs_meta(d, id, unifier)
  }
}

///|
fn pattern_level_position(levels : Array[Int32], level : Int32) -> Int32 {
  for i in 0..<levels.length() {
    if levels[i] == level {
      return i
    }
  }
  -1
}

///|
fn wrap_pattern_lambdas(body : UTerm, count : Int32) -> UTerm {
  let mut out = body
  for _i in 0..<count {
    out = ULam(UConst("PatternDomain"), out)
  }
  out
}

///|
/// Levels of a spine consisting solely of bound variables.  Repeated
/// variables are retained: during abstraction the first occurrence of
/// a level is the binder used for that variable.
fn variable_spine_levels(
  args : Array[UTerm],
  depth : Int32,
  unifier : Unifier,
) -> Array[Int32]? {
  let levels : Array[Int32] = []
  for i in 0..<args.length() {
    match uterm_whnf(args[i], unifier) {
      UVar(index) => {
        let level = depth - 1 - index
        if level < 0 || level >= depth {
          return None
        }
        levels.push(level)
      }
      _ => return None
    }
  }
  Some(levels)
}

///|
fn collect_constructor_pattern_levels(
  t : UTerm,
  depth : Int32,
  unifier : Unifier,
  levels : Array[Int32],
) -> Bool {
  match uterm_whnf(t, unifier) {
    UVar(index) => {
      let level = depth - 1 - index
      if level < 0 || level >= depth {
        return false
      }
      if pattern_level_position(levels, level) < 0 {
        levels.push(level)
      }
      true
    }
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => true
    USucc(x) => collect_constructor_pattern_levels(x, depth, unifier, levels)
    UPair(a, b) =>
      collect_constructor_pattern_levels(a, depth, unifier, levels) &&
      collect_constructor_pattern_levels(b, depth, unifier, levels)
    _ => false
  }
}

///|
fn nat_pred_term(node : UTerm) -> UTerm {
  UNatElim(
    ULam(uty_nat(), uty_nat()),
    UNatZero,
    ULam(uty_nat(), ULam(uty_nat(), UVar(1))),
    node,
  )
}

///|
fn constructor_pattern_extractor(
  t : UTerm,
  target_level : Int32,
  depth : Int32,
  node : UTerm,
  unifier : Unifier,
) -> UTerm? {
  match uterm_whnf(t, unifier) {
    UVar(index) =>
      if depth - 1 - index == target_level {
        Some(node)
      } else {
        None
      }
    USucc(x) =>
      constructor_pattern_extractor(
        x,
        target_level,
        depth,
        nat_pred_term(node),
        unifier,
      )
    UPair(a, b) =>
      match
        constructor_pattern_extractor(
          a,
          target_level,
          depth,
          UFst(node),
          unifier,
        ) {
        Some(v) => Some(v)
        None =>
          constructor_pattern_extractor(
            b,
            target_level,
            depth,
            USnd(node),
            unifier,
          )
      }
    _ => None
  }
}

///|
fn extractor_from_args(
  args : Array[UTerm],
  target_level : Int32,
  depth : Int32,
  unifier : Unifier,
) -> UTerm? {
  for i in 0..<args.length() {
    let root = UVar(args.length() - 1 - i)
    match
      constructor_pattern_extractor(args[i], target_level, depth, root, unifier) {
      Some(v) => return Some(v)
      None => ()
    }
  }
  None
}

///|
fn constructor_spine_solution(
  rhs : UTerm,
  args : Array[UTerm],
  depth : Int32,
  meta_depth : Int32,
  unifier : Unifier,
) -> UTerm? {
  let levels : Array[Int32] = []
  for i in 0..<args.length() {
    if !collect_constructor_pattern_levels(args[i], depth, unifier, levels) {
      return None
    }
  }
  let body = match abstract_pattern_go(rhs, depth, 0, meta_depth, levels) {
    Some(v) => v
    None => return None
  }
  let inner = wrap_pattern_lambdas(body, levels.length())
  let extractors : Array[UTerm] = []
  for i in 0..<levels.length() {
    match extractor_from_args(args, levels[i], depth, unifier) {
      Some(v) => extractors.push(v)
      None => return None
    }
  }
  let applied = uterm_apply_many(
    uterm_shift(inner, args.length(), 0),
    extractors,
  )
  Some(wrap_pattern_lambdas(applied, args.length()))
}

///|
fn spine_support_levels(
  args : Array[UTerm],
  depth : Int32,
  unifier : Unifier,
) -> Array[Int32]? {
  let levels : Array[Int32] = []
  for i in 0..<args.length() {
    if !collect_constructor_pattern_levels(args[i], depth, unifier, levels) {
      return None
    }
  }
  Some(levels)
}

///|
fn levels_intersection(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<a.length() {
    if pattern_level_position(b, a[i]) >= 0 {
      out.push(a[i])
    }
  }
  out
}

///|
fn common_meta_solution(
  args : Array[UTerm],
  common_levels : Array[Int32],
  common_id : Int32,
  depth : Int32,
  unifier : Unifier,
) -> UTerm? {
  let common_args : Array[UTerm] = []
  for i in 0..<common_levels.length() {
    match extractor_from_args(args, common_levels[i], depth, unifier) {
      Some(v) => common_args.push(v)
      None => return None
    }
  }
  Some(wrap_pattern_lambdas(UMeta(common_id, common_args), args.length()))
}

///|
fn assign_meta_solution(
  unifier : Unifier,
  id : Int32,
  solution : UTerm,
) -> Unit {
  unifier.metas[id].solution = Some(solution)
  unifier.solved_count = unifier.solved_count + 1
}

///|
fn flex_flex_intersection(
  unifier : Unifier,
  id_a : Int32,
  args_a : Array[UTerm],
  id_b : Int32,
  args_b : Array[UTerm],
  depth : Int32,
) -> Bool {
  if id_a == id_b ||
    id_a < 0 ||
    id_b < 0 ||
    id_a >= unifier.metas.length() ||
    id_b >= unifier.metas.length() {
    return false
  }
  match (unifier.metas[id_a].solution, unifier.metas[id_b].solution) {
    (None, None) => ()
    _ => return false
  }
  let support_a = match spine_support_levels(args_a, depth, unifier) {
    Some(v) => v
    None => return false
  }
  let support_b = match spine_support_levels(args_b, depth, unifier) {
    Some(v) => v
    None => return false
  }
  let common = levels_intersection(support_a, support_b)
  let common_id = unifier.metas.length()
  let solution_a = match
    common_meta_solution(args_a, common, common_id, depth, unifier) {
    Some(v) => v
    None => return false
  }
  let solution_b = match
    common_meta_solution(args_b, common, common_id, depth, unifier) {
    Some(v) => v
    None => return false
  }
  unifier.metas.push(UMetaInfo::{ context_depth: 0, solution: None, })
  assign_meta_solution(unifier, id_a, solution_a)
  assign_meta_solution(unifier, id_b, solution_b)
  true
}

///|
fn abstract_pattern_go(
  t : UTerm,
  root_depth : Int32,
  binder_depth : Int32,
  meta_depth : Int32,
  levels : Array[Int32],
) -> UTerm? {
  match t {
    UVar(i) => {
      if i < binder_depth {
        return Some(t)
      }
      let level = root_depth + binder_depth - 1 - i
      if level < 0 {
        return None
      }
      let pos = pattern_level_position(levels, level)
      if pos >= 0 {
        Some(UVar(binder_depth + levels.length() - 1 - pos))
      } else if level < meta_depth {
        Some(UVar(meta_depth + levels.length() + binder_depth - 1 - level))
      } else {
        None
      }
    }
    UMeta(id, args) => {
      let out : Array[UTerm] = []
      for i in 0..<args.length() {
        match
          abstract_pattern_go(
            args[i],
            root_depth,
            binder_depth,
            meta_depth,
            levels,
          ) {
          Some(x) => out.push(x)
          None => return None
        }
      }
      Some(UMeta(id, out))
    }
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => Some(t)
    ULam(dom, body) => {
      let d = match
        abstract_pattern_go(dom, root_depth, binder_depth, meta_depth, levels) {
        Some(x) => x
        None => return None
      }
      let b = match
        abstract_pattern_go(
          body,
          root_depth,
          binder_depth + 1,
          meta_depth,
          levels,
        ) {
        Some(x) => x
        None => return None
      }
      Some(ULam(d, b))
    }
    UApp(f, x) => {
      let f2 = match
        abstract_pattern_go(f, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let x2 = match
        abstract_pattern_go(x, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      Some(UApp(f2, x2))
    }
    UPi(a, b) => {
      let a2 = match
        abstract_pattern_go(a, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let b2 = match
        abstract_pattern_go(b, root_depth, binder_depth + 1, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      Some(UPi(a2, b2))
    }
    UImplicitPi(a, b) => {
      let a2 = match
        abstract_pattern_go(a, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let b2 = match
        abstract_pattern_go(b, root_depth, binder_depth + 1, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      Some(UImplicitPi(a2, b2))
    }
    USigma(a, b) => {
      let a2 = match
        abstract_pattern_go(a, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let b2 = match
        abstract_pattern_go(b, root_depth, binder_depth + 1, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      Some(USigma(a2, b2))
    }
    UPair(a, b) => {
      let a2 = match
        abstract_pattern_go(a, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let b2 = match
        abstract_pattern_go(b, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      Some(UPair(a2, b2))
    }
    UFst(x) =>
      match
        abstract_pattern_go(x, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => Some(UFst(v))
        None => None
      }
    USnd(x) =>
      match
        abstract_pattern_go(x, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => Some(USnd(v))
        None => None
      }
    USucc(x) =>
      match
        abstract_pattern_go(x, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => Some(USucc(v))
        None => None
      }
    UNatElim(a, b, c, d) => {
      let a2 = match
        abstract_pattern_go(a, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let b2 = match
        abstract_pattern_go(b, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let c2 = match
        abstract_pattern_go(c, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      let d2 = match
        abstract_pattern_go(d, root_depth, binder_depth, meta_depth, levels) {
        Some(v) => v
        None => return None
      }
      Some(UNatElim(a2, b2, c2, d2))
    }
  }
}

///|
fn pattern_solution(
  rhs : UTerm,
  args : Array[UTerm],
  depth : Int32,
  meta_depth : Int32,
  unifier : Unifier,
) -> UTerm? {
  let levels : Array[Int32] = []
  let mut is_pattern = true
  for i in 0..<args.length() {
    match uterm_whnf(args[i], unifier) {
      UVar(index) => {
        let level = depth - 1 - index
        if level < meta_depth || pattern_level_position(levels, level) >= 0 {
          is_pattern = false
        } else {
          levels.push(level)
        }
      }
      _ => is_pattern = false
    }
  }
  if is_pattern {
    return match abstract_pattern_go(rhs, depth, 0, meta_depth, levels) {
      Some(body) => Some(wrap_pattern_lambdas(body, levels.length()))
      None => None
    }
  }

  // Repeated-variable spines are no longer rejected merely for not
  // being a Miller pattern.  `levels` retains every spine position;
  // abstraction maps a repeated variable to its first binder.
  match variable_spine_levels(args, depth, unifier) {
    Some(spine_levels) =>
      match abstract_pattern_go(rhs, depth, 0, meta_depth, spine_levels) {
        Some(body) => return Some(wrap_pattern_lambdas(body, args.length()))
        None => ()
      }
    None => ()
  }

  // Constructor-pattern spines: abstract over the distinct pattern
  // leaves, then extract those leaves from the formal spine arguments.
  match constructor_spine_solution(rhs, args, depth, meta_depth, unifier) {
    Some(solution) => return Some(solution)
    None => ()
  }

  // The pre-existing sound non-pattern fallback: a constant solution
  // is allowed when `rhs` only uses variables from the metavariable
  // context.
  match abstract_pattern_go(rhs, depth, 0, meta_depth, []) {
    Some(body) => Some(wrap_pattern_lambdas(body, args.length()))
    None => None
  }
}

///|
fn assign_meta(
  unifier : Unifier,
  id : Int32,
  args : Array[UTerm],
  rhs_in : UTerm,
  depth : Int32,
) -> Bool {
  if id < 0 || id >= unifier.metas.length() {
    return false
  }
  match unifier.metas[id].solution {
    Some(_) => hou_unify(UMeta(id, args), rhs_in, depth, unifier)
    None => {
      let rhs = uterm_whnf(rhs_in, unifier)
      if uterm_occurs_meta(rhs, id, unifier) {
        return false
      }
      match
        pattern_solution(
          rhs,
          args,
          depth,
          unifier.metas[id].context_depth,
          unifier,
        ) {
        Some(solution) => {
          assign_meta_solution(unifier, id, solution)
          true
        }
        None => false
      }
    }
  }
}

///|
fn meta_head_spine(t : UTerm, unifier : Unifier) -> (Int32, Array[UTerm])? {
  match uterm_whnf(t, unifier) {
    UMeta(id, args) => Some((id, args))
    UApp(f, x) =>
      match meta_head_spine(f, unifier) {
        Some((id, args)) => {
          let out : Array[UTerm] = []
          for i in 0..<args.length() {
            out.push(args[i])
          }
          out.push(x)
          Some((id, out))
        }
        None => None
      }
    _ => None
  }
}

///|
/// Higher-order unification in the Miller pattern fragment, extended
/// by the repeated-variable, constructor-pattern and flex-flex
/// intersection cases described at the top of this file.
/// `depth` is the number of variables in scope.  It beta/eta reduces,
/// decomposes rigid heads, and solves pattern-flexible heads.
pub fn hou_unify(
  a_in : UTerm,
  b_in : UTerm,
  depth : Int32,
  unifier : Unifier,
) -> Bool {
  let a = uterm_whnf(a_in, unifier)
  let b = uterm_whnf(b_in, unifier)
  if a == b {
    return true
  }
  let a_head = meta_head_spine(a, unifier)
  let b_head = meta_head_spine(b, unifier)
  match (a_head, b_head) {
    (Some((id_a, args_a)), Some((id_b, args_b))) => {
      if id_a == id_b {
        if args_a == args_b {
          return true
        }
        // The remaining sound same-head case handled here is that
        // the corresponding spine arguments can themselves be
        // unified, after which the two spines are identical.  Other
        // same-head equations are left unresolved rather than
        // pruned to an arbitrary symmetric/constant solution.
        if args_a.length() != args_b.length() {
          return false
        }
        for i in 0..<args_a.length() {
          if !hou_unify(args_a[i], args_b[i], depth, unifier) {
            return false
          }
        }
        return hou_semantic_optimize(UMeta(id_a, args_a), unifier) ==
          hou_semantic_optimize(UMeta(id_b, args_b), unifier)
      }
      if assign_meta(unifier, id_a, args_a, b, depth) {
        return true
      }
      return flex_flex_intersection(unifier, id_a, args_a, id_b, args_b, depth)
    }
    (Some((id, args)), None) => return assign_meta(unifier, id, args, b, depth)
    (None, Some((id, args))) => return assign_meta(unifier, id, args, a, depth)
    (None, None) => ()
  }
  match (a, b) {
    (ULam(ad, ab), ULam(bd, bb)) =>
      hou_unify(ad, bd, depth, unifier) && hou_unify(ab, bb, depth + 1, unifier)
    (ULam(_, body), other) =>
      hou_unify(
        body,
        UApp(uterm_shift(other, 1, 0), UVar(0)),
        depth + 1,
        unifier,
      )
    (other, ULam(_, body)) =>
      hou_unify(
        UApp(uterm_shift(other, 1, 0), UVar(0)),
        body,
        depth + 1,
        unifier,
      )
    (UPi(x1, y1), UPi(x2, y2))
    | (UImplicitPi(x1, y1), UImplicitPi(x2, y2))
    | (USigma(x1, y1), USigma(x2, y2))
    | (UPair(x1, y1), UPair(x2, y2))
    | (UApp(x1, y1), UApp(x2, y2)) =>
      hou_unify(x1, x2, depth, unifier) && hou_unify(y1, y2, depth, unifier)
    (UFst(x), UFst(y)) | (USnd(x), USnd(y)) | (USucc(x), USucc(y)) =>
      hou_unify(x, y, depth, unifier)
    (UNatElim(a1, b1, c1, d1), UNatElim(a2, b2, c2, d2)) =>
      hou_unify(a1, a2, depth, unifier) &&
      hou_unify(b1, b2, depth, unifier) &&
      hou_unify(c1, c2, depth, unifier) &&
      hou_unify(d1, d2, depth, unifier)
    _ => false
  }
}

///|
/// Status of the certified pattern-unification API below.
pub(all) enum HouMguStatus {
  /// Solved, and the returned substitution is a most general
  /// unifier for the Miller-pattern problem.
  HouMguPrincipal
  /// Definitively not unifiable (rigid clash, rigid occurs
  /// failure, or a pattern scope failure against a meta-free
  /// right-hand side).  The unifier is restored.
  HouMguNoUnifier
  /// The problem left the certified pattern fragment.  The
  /// unifier retains the (principal) partial substitution for
  /// the solved part, and `residual` holds the remaining
  /// normalized constraints; solving those under the partial
  /// substitution is equivalent to solving the original problem.
  HouMguResidual
} derive(Debug, Eq)

///|
pub extend HouMguStatus with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouMguStatus with Eq::{not_equal, equal}

///|
/// One residual higher-order equation, at the displayed context
/// depth, normalized under the current partial substitution.
pub(all) struct HouConstraint {
  lhs : UTerm
  rhs : UTerm
  depth : Int32
} derive(Debug, Eq)

///|
pub extend HouConstraint with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouConstraint with Eq::{not_equal, equal}

///|
pub struct HouMguReport {
  status : HouMguStatus
  /// Assignments made by this call, as `(meta id, solution)`
  /// pairs with solutions zonked under the final unifier.
  substitution : Array[(Int32, UTerm)]
  residual : Array[HouConstraint]
} derive(Debug, Eq)

///|
pub extend HouMguReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouMguReport with Eq::{not_equal, equal}

///|
fn hou_mgu_strict_levels(
  args : Array[UTerm],
  depth : Int32,
  meta_depth : Int32,
  unifier : Unifier,
) -> Array[Int32]? {
  let levels : Array[Int32] = []
  for i in 0..<args.length() {
    match uterm_whnf(args[i], unifier) {
      UVar(index) => {
        let level = depth - 1 - index
        if level < meta_depth ||
          level >= depth ||
          pattern_level_position(levels, level) >= 0 {
          return None
        }
        levels.push(level)
      }
      _ => return None
    }
  }
  Some(levels)
}

///|
/// Occurrence of `id` on a rigid path: occurrences inside the
/// arguments of a different unsolved metavariable do not count,
/// because that metavariable could still ignore them.
fn hou_mgu_occurs_rigid(t : UTerm, id : Int32, unifier : Unifier) -> Bool {
  match t {
    UMeta(other, args) => {
      if other == id {
        return true
      }
      let solved = if other >= 0 && other < unifier.metas.length() {
        unifier.metas[other].solution
      } else {
        None
      }
      match solved {
        Some(solution) =>
          hou_mgu_occurs_rigid(uterm_apply_many(solution, args), id, unifier)
        None => false
      }
    }
    UVar(_) | UConst(_) | UType(_) | UBoolLit(_) | UNatZero => false
    ULam(a, b)
    | UApp(a, b)
    | UPi(a, b)
    | UImplicitPi(a, b)
    | USigma(a, b)
    | UPair(a, b) =>
      hou_mgu_occurs_rigid(a, id, unifier) ||
      hou_mgu_occurs_rigid(b, id, unifier)
    UFst(x) | USnd(x) | USucc(x) => hou_mgu_occurs_rigid(x, id, unifier)
    UNatElim(a, b, c, d) =>
      hou_mgu_occurs_rigid(a, id, unifier) ||
      hou_mgu_occurs_rigid(b, id, unifier) ||
      hou_mgu_occurs_rigid(c, id, unifier) ||
      hou_mgu_occurs_rigid(d, id, unifier)
  }
}

///|
/// Strict pattern assignment: 1 = assigned, 0 = residual,
/// -1 = definitive failure.
fn hou_mgu_assign_pattern(
  unifier : Unifier,
  id : Int32,
  args : Array[UTerm],
  rhs_in : UTerm,
  depth : Int32,
) -> Int32 {
  if id < 0 || id >= unifier.metas.length() {
    return -1
  }
  let meta_depth = unifier.metas[id].context_depth
  let levels = match hou_mgu_strict_levels(args, depth, meta_depth, unifier) {
    Some(v) => v
    None => return 0
  }
  let rhs = hou_semantic_optimize(rhs_in, unifier)
  if hou_mgu_occurs_rigid(rhs, id, unifier) {
    return -1
  }
  if uterm_occurs_meta(rhs, id, unifier) {
    return 0
  }
  match abstract_pattern_go(rhs, depth, 0, meta_depth, levels) {
    Some(body) => {
      assign_meta_solution(
        unifier,
        id,
        wrap_pattern_lambdas(body, levels.length()),
      )
      1
    }
    None => if uterm_contains_unsolved_meta(rhs, unifier) { 0 } else { -1 }
  }
}

///|
/// Same-head pattern pruning: `?F s = ?F t` forces `?F` to
/// depend only on the spine variables occupying the same
/// position on both sides.
fn hou_mgu_same_head_prune(
  unifier : Unifier,
  id : Int32,
  args_a : Array[UTerm],
  args_b : Array[UTerm],
  depth : Int32,
) -> Bool {
  if args_a.length() != args_b.length() {
    return false
  }
  let meta_depth = unifier.metas[id].context_depth
  let levels_a = match
    hou_mgu_strict_levels(args_a, depth, meta_depth, unifier) {
    Some(v) => v
    None => return false
  }
  let levels_b = match
    hou_mgu_strict_levels(args_b, depth, meta_depth, unifier) {
    Some(v) => v
    None => return false
  }
  let common : Array[Int32] = []
  for i in 0..<levels_a.length() {
    if levels_a[i] == levels_b[i] {
      common.push(levels_a[i])
    }
  }
  let common_id = unifier.metas.length()
  let solution = match
    common_meta_solution(args_a, common, common_id, depth, unifier) {
    Some(v) => v
    None => return false
  }
  unifier.metas.push(UMetaInfo::{ context_depth: 0, solution: None, })
  assign_meta_solution(unifier, id, solution)
  true
}

///|
fn hou_mgu_push(
  queue : Array[HouConstraint],
  lhs : UTerm,
  rhs : UTerm,
  depth : Int32,
) -> Unit {
  queue.push(HouConstraint::{ lhs, rhs, depth, })
}

///|
/// Process one constraint: 1 = handled (possibly decomposed
/// into `queue`), 0 = residual, -1 = definitive clash.
fn hou_mgu_process(
  constraint : HouConstraint,
  unifier : Unifier,
  queue : Array[HouConstraint],
) -> Int32 {
  let depth = constraint.depth
  let a = uterm_whnf(constraint.lhs, unifier)
  let b = uterm_whnf(constraint.rhs, unifier)
  if a == b {
    return 1
  }
  let a_head = meta_head_spine(a, unifier)
  let b_head = meta_head_spine(b, unifier)
  match (a_head, b_head) {
    (Some((id_a, args_a)), Some((id_b, args_b))) => {
      if id_a == id_b {
        if args_a == args_b {
          return 1
        }
        return if hou_mgu_same_head_prune(unifier, id_a, args_a, args_b, depth) {
          1
        } else {
          0
        }
      }
      let a_strict = hou_mgu_strict_levels(
        args_a,
        depth,
        unifier.metas[id_a].context_depth,
        unifier,
      )
      let b_strict = hou_mgu_strict_levels(
        args_b,
        depth,
        unifier.metas[id_b].context_depth,
        unifier,
      )
      match (a_strict, b_strict) {
        (Some(_), Some(_)) =>
          return if flex_flex_intersection(
              unifier, id_a, args_a, id_b, args_b, depth,
            ) {
            1
          } else {
            0
          }
        _ => return 0
      }
    }
    (Some((id, args)), None) =>
      return hou_mgu_assign_pattern(unifier, id, args, b, depth)
    (None, Some((id, args))) =>
      return hou_mgu_assign_pattern(unifier, id, args, a, depth)
    (None, None) => ()
  }
  match (a, b) {
    (ULam(ad, ab), ULam(bd, bb)) => {
      hou_mgu_push(queue, ad, bd, depth)
      hou_mgu_push(queue, ab, bb, depth + 1)
      1
    }
    (ULam(_, body), other) => {
      hou_mgu_push(
        queue,
        body,
        UApp(uterm_shift(other, 1, 0), UVar(0)),
        depth + 1,
      )
      1
    }
    (other, ULam(_, body)) => {
      hou_mgu_push(
        queue,
        UApp(uterm_shift(other, 1, 0), UVar(0)),
        body,
        depth + 1,
      )
      1
    }
    (UPi(x1, y1), UPi(x2, y2))
    | (UImplicitPi(x1, y1), UImplicitPi(x2, y2))
    | (USigma(x1, y1), USigma(x2, y2)) => {
      hou_mgu_push(queue, x1, x2, depth)
      hou_mgu_push(queue, y1, y2, depth + 1)
      1
    }
    (UPair(x1, y1), UPair(x2, y2)) | (UApp(x1, y1), UApp(x2, y2)) => {
      hou_mgu_push(queue, x1, x2, depth)
      hou_mgu_push(queue, y1, y2, depth)
      1
    }
    (UFst(x), UFst(y)) | (USnd(x), USnd(y)) | (USucc(x), USucc(y)) => {
      hou_mgu_push(queue, x, y, depth)
      1
    }
    (UNatElim(a1, b1, c1, d1), UNatElim(a2, b2, c2, d2)) => {
      hou_mgu_push(queue, a1, a2, depth)
      hou_mgu_push(queue, b1, b2, depth)
      hou_mgu_push(queue, c1, c2, depth)
      hou_mgu_push(queue, d1, d2, depth)
      1
    }
    _ =>
      // A root mismatch is only certified as a clash when no
      // unsolved metavariable could still change either side's
      // head through further assignment and reduction.
      if uterm_contains_unsolved_meta(a, unifier) ||
        uterm_contains_unsolved_meta(b, unifier) {
        0
      } else {
        -1
      }
  }
}

///|
/// Pattern unification with a certified outcome.  Unlike
/// `hou_unify` (which additionally uses repeated-variable,
/// constructor-pattern and constant fallbacks that produce
/// *specific* unifiers) and `hou_search_unify` (bounded Huet
/// guesses), this entry point either returns a most general
/// unifier for the Miller-pattern fragment, a definitive
/// non-unifiability verdict, or an explicit residual constraint
/// set under a principal partial substitution.
pub fn hou_unify_mgu(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
) -> HouMguReport {
  let snapshot = hou_clone_unifier(unifier)
  let queue : Array[HouConstraint] = [HouConstraint::{ lhs: a, rhs: b, depth, }]
  let residual : Array[HouConstraint] = []
  let mut progress_mark = unifier.solved_count + unifier.metas.length()
  while true {
    match queue.pop() {
      Some(constraint) =>
        match hou_mgu_process(constraint, unifier, queue) {
          1 => ()
          0 =>
            residual.push(HouConstraint::{
              lhs: hou_semantic_optimize(constraint.lhs, unifier),
              rhs: hou_semantic_optimize(constraint.rhs, unifier),
              depth: constraint.depth,
            })
          _ => {
            hou_restore_unifier(unifier, snapshot)
            return HouMguReport::{
              status: HouMguNoUnifier,
              substitution: [],
              residual: [],
            }
          }
        }
      None => {
        let progress = unifier.solved_count + unifier.metas.length()
        if residual.length() > 0 && progress != progress_mark {
          progress_mark = progress
          while residual.length() > 0 {
            match residual.pop() {
              Some(c) => queue.push(c)
              None => ()
            }
          }
        } else {
          break
        }
      }
    }
  }
  let substitution : Array[(Int32, UTerm)] = []
  for id in 0..<unifier.metas.length() {
    let was_solved = id < snapshot.metas.length() &&
      snapshot.metas[id].solution != None
    match unifier.metas[id].solution {
      Some(solution) =>
        if !was_solved {
          substitution.push((id, hou_semantic_optimize(solution, unifier)))
        }
      None => ()
    }
  }
  if residual.length() == 0 {
    HouMguReport::{ status: HouMguPrincipal, substitution, residual: [], }
  } else {
    let normalized : Array[HouConstraint] = []
    for i in 0..<residual.length() {
      normalized.push(HouConstraint::{
        lhs: hou_semantic_optimize(residual[i].lhs, unifier),
        rhs: hou_semantic_optimize(residual[i].rhs, unifier),
        depth: residual[i].depth,
      })
    }
    HouMguReport::{
      status: HouMguResidual,
      substitution,
      residual: normalized,
    }
  }
}

///|
/// Create a fresh pattern metavariable over every variable in scope.
pub fn hou_fresh_meta(unifier : Unifier, depth : Int32) -> UTerm {
  let id = unifier.metas.length()
  unifier.metas.push(UMetaInfo::{ context_depth: 0, solution: None, })
  let args : Array[UTerm] = []
  for level in 0..<depth {
    args.push(UVar(depth - 1 - level))
  }
  UMeta(id, args)
}

///|
pub enum STerm {
  SVar(String)
  SLam(String, UTerm?, STerm)
  SApp(STerm, STerm)
  SPair(STerm, STerm)
  SFst(STerm)
  SSnd(STerm)
  SBoolLit(Bool)
  SUnitLit
  SNatZero
  SSucc(STerm)
  SNatElim(STerm, STerm, STerm, STerm)
  SAnn(STerm, UTerm)
  SHole
} derive(Debug, Eq)

///|
pub extend STerm with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend STerm with Eq::{not_equal, equal}

///|
pub struct ElabVar {
  name : String
  ty : UTerm
} derive(Debug, Eq)

///|
pub extend ElabVar with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ElabVar with Eq::{not_equal, equal}

///|
pub struct Elaborator {
  unifier : Unifier
  vars : Array[ElabVar]
} derive(Debug, Eq)

///|
pub extend Elaborator with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Elaborator with Eq::{not_equal, equal}

///|
pub struct ElabResult {
  term : UTerm
  ty : UTerm
} derive(Debug, Eq)

///|
pub extend ElabResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ElabResult with Eq::{not_equal, equal}

///|
pub fn elaborator_new() -> Elaborator {
  Elaborator::{ unifier: unifier_new(), vars: [], }
}

///|
fn elab_depth(e : Elaborator) -> Int32 {
  e.vars.length()
}

///|
fn elab_fresh(e : Elaborator) -> UTerm {
  hou_fresh_meta(e.unifier, elab_depth(e))
}

///|
fn elab_fresh_at(e : Elaborator, depth : Int32) -> UTerm {
  hou_fresh_meta(e.unifier, depth)
}

///|
fn elab_lookup(e : Elaborator, name : String) -> ElabResult? {
  let depth = elab_depth(e)
  for i in 0..<depth {
    let index = depth - 1 - i
    if e.vars[index].name == name {
      let ty = uterm_shift(e.vars[index].ty, depth - index - 1, 0)
      return Some(ElabResult::{ term: UVar(depth - 1 - index), ty, })
    }
  }
  None
}

///|
fn elab_push(e : Elaborator, name : String, ty : UTerm) -> Unit {
  e.vars.push(ElabVar::{ name, ty, })
}

///|
fn elab_truncate(e : Elaborator, depth : Int32) -> Unit {
  while e.vars.length() > depth {
    match e.vars.pop() {
      Some(_) => ()
      None => break
    }
  }
}

///|
pub fn elab_check(
  e : Elaborator,
  term : STerm,
  expected : UTerm,
) -> ElabResult? {
  let depth = elab_depth(e)
  match term {
    SHole => Some(ElabResult::{ term: elab_fresh(e), ty: expected, })
    SLam(name, annotation, body) => {
      let expected2 = uterm_whnf(expected, e.unifier)
      let (dom, cod) = match expected2 {
        UPi(a, b) | UImplicitPi(a, b) => (a, b)
        UMeta(_, _) => {
          let dom = elab_fresh(e)
          let cod = elab_fresh_at(e, depth + 1)
          if !hou_unify(expected2, UPi(dom, cod), depth, e.unifier) {
            return None
          }
          (dom, cod)
        }
        _ => return None
      }
      match annotation {
        Some(ann) => if !hou_unify(ann, dom, depth, e.unifier) { return None }
        None => ()
      }
      elab_push(e, name, dom)
      let body_result = elab_check(e, body, cod)
      elab_truncate(e, depth)
      match body_result {
        Some(r) =>
          Some(ElabResult::{ term: ULam(dom, r.term), ty: UPi(dom, cod), })
        None => None
      }
    }
    SPair(first, second) => {
      let expected2 = uterm_whnf(expected, e.unifier)
      let (dom, cod) = match expected2 {
        USigma(a, b) => (a, b)
        UMeta(_, _) => {
          let dom = elab_fresh(e)
          let cod = elab_fresh_at(e, depth + 1)
          if !hou_unify(expected2, USigma(dom, cod), depth, e.unifier) {
            return None
          }
          (dom, cod)
        }
        _ => return None
      }
      let first_r = match elab_check(e, first, dom) {
        Some(r) => r
        None => return None
      }
      let second_ty = uterm_instantiate(cod, first_r.term)
      let second_r = match elab_check(e, second, second_ty) {
        Some(r) => r
        None => return None
      }
      Some(ElabResult::{
        term: UPair(first_r.term, second_r.term),
        ty: USigma(dom, cod),
      })
    }
    _ => {
      let inferred = match elab_infer(e, term) {
        Some(r) => r
        None => return None
      }
      if hou_unify(inferred.ty, expected, depth, e.unifier) {
        Some(ElabResult::{ term: inferred.term, ty: expected, })
      } else {
        None
      }
    }
  }
}

///|
pub fn elab_infer(e : Elaborator, term : STerm) -> ElabResult? {
  let depth = elab_depth(e)
  match term {
    SVar(name) => elab_lookup(e, name)
    SHole => {
      let ty = elab_fresh(e)
      Some(ElabResult::{ term: elab_fresh(e), ty, })
    }
    SBoolLit(value) =>
      Some(ElabResult::{ term: UBoolLit(value), ty: uty_bool(), })
    SUnitLit => Some(ElabResult::{ term: UConst("UnitLit"), ty: uty_unit(), })
    SNatZero => Some(ElabResult::{ term: UNatZero, ty: uty_nat(), })
    SSucc(x) => {
      let r = match elab_check(e, x, uty_nat()) {
        Some(v) => v
        None => return None
      }
      Some(ElabResult::{ term: USucc(r.term), ty: uty_nat(), })
    }
    SAnn(inner, ty) => elab_check(e, inner, ty)
    SLam(name, annotation, body) => {
      let dom = match annotation {
        Some(ann) => ann
        None => elab_fresh(e)
      }
      elab_push(e, name, dom)
      let body_r = elab_infer(e, body)
      elab_truncate(e, depth)
      match body_r {
        Some(r) =>
          Some(ElabResult::{ term: ULam(dom, r.term), ty: UPi(dom, r.ty), })
        None => None
      }
    }
    SPair(first, second) => {
      let first_r = match elab_infer(e, first) {
        Some(r) => r
        None => return None
      }
      let second_r = match elab_infer(e, second) {
        Some(r) => r
        None => return None
      }
      Some(ElabResult::{
        term: UPair(first_r.term, second_r.term),
        ty: USigma(first_r.ty, uterm_shift(second_r.ty, 1, 0)),
      })
    }
    SFst(pair) => {
      let r = match elab_infer(e, pair) {
        Some(v) => v
        None => return None
      }
      let dom = elab_fresh(e)
      let cod = elab_fresh_at(e, depth + 1)
      if !hou_unify(r.ty, USigma(dom, cod), depth, e.unifier) {
        return None
      }
      Some(ElabResult::{ term: UFst(r.term), ty: dom, })
    }
    SSnd(pair) => {
      let r = match elab_infer(e, pair) {
        Some(v) => v
        None => return None
      }
      let dom = elab_fresh(e)
      let cod = elab_fresh_at(e, depth + 1)
      if !hou_unify(r.ty, USigma(dom, cod), depth, e.unifier) {
        return None
      }
      Some(ElabResult::{
        term: USnd(r.term),
        ty: uterm_instantiate(cod, UFst(r.term)),
      })
    }
    SApp(fn_term, arg_term) => {
      let fn_r0 = match elab_infer(e, fn_term) {
        Some(r) => r
        None => return None
      }
      let mut fn_r = fn_r0
      // Insert implicit arguments until an explicit Pi (or a
      // metavariable that can be forced to one) is exposed.
      for _i in 0..<16 {
        match uterm_whnf(fn_r.ty, e.unifier) {
          UImplicitPi(_dom, cod) => {
            let inserted = elab_fresh(e)
            // The inserted hole must itself inhabit dom; recording
            // that fact is the job of cross-checking the zonked
            // DTerm.  HOU normally solves it from the explicit
            // argument below (for example the A in id {A}).
            fn_r = ElabResult::{
              term: UApp(fn_r.term, inserted),
              ty: uterm_instantiate(cod, inserted),
            }
          }
          _ => break
        }
      }
      let (dom, cod) = match uterm_whnf(fn_r.ty, e.unifier) {
        UPi(a, b) => (a, b)
        UMeta(_, _) => {
          let dom = elab_fresh(e)
          let cod = elab_fresh_at(e, depth + 1)
          if !hou_unify(fn_r.ty, UPi(dom, cod), depth, e.unifier) {
            return None
          }
          (dom, cod)
        }
        _ => return None
      }
      let arg_r = match elab_check(e, arg_term, dom) {
        Some(r) => r
        None => return None
      }
      Some(ElabResult::{
        term: UApp(fn_r.term, arg_r.term),
        ty: uterm_instantiate(cod, arg_r.term),
      })
    }
    SNatElim(motive_s, zero_s, succ_s, scrut_s) => {
      let scrut = match elab_check(e, scrut_s, uty_nat()) {
        Some(r) => r
        None => return None
      }
      let motive_ty = UPi(uty_nat(), UType(0))
      let motive = match elab_check(e, motive_s, motive_ty) {
        Some(r) => r
        None => return None
      }
      let zero_ty = UApp(motive.term, UNatZero)
      let zero = match elab_check(e, zero_s, zero_ty) {
        Some(r) => r
        None => return None
      }
      let motive1 = uterm_shift(motive.term, 1, 0)
      let motive2 = uterm_shift(motive.term, 2, 0)
      let succ_ty = UPi(
        uty_nat(),
        UPi(UApp(motive1, UVar(0)), UApp(motive2, USucc(UVar(1)))),
      )
      let succ = match elab_check(e, succ_s, succ_ty) {
        Some(r) => r
        None => return None
      }
      Some(ElabResult::{
        term: UNatElim(motive.term, zero.term, succ.term, scrut.term),
        ty: UApp(motive.term, scrut.term),
      })
    }
  }
}

///|
fn uterm_to_dterm_depth(
  t_in : UTerm,
  depth : Int32,
  unifier : Unifier,
) -> DTerm? {
  let t = uterm_whnf(t_in, unifier)
  match t {
    UVar(i) => if i < depth { Some(DTVar(i)) } else { None }
    UMeta(_, _) => None
    UConst(name) =>
      if name == "Bool" {
        Some(DBoolTy)
      } else if name == "Nat" {
        Some(DNatTy)
      } else if name == "Unit" {
        Some(DUnitTy)
      } else if name == "UnitLit" {
        Some(DUnitLit)
      } else {
        None
      }
    UType(level) => Some(DUniv(level))
    ULam(dom, body) => {
      let d = match uterm_to_dterm_depth(dom, depth, unifier) {
        Some(x) => x
        None => return None
      }
      let b = match uterm_to_dterm_depth(body, depth + 1, unifier) {
        Some(x) => x
        None => return None
      }
      Some(DLam(d, b))
    }
    UApp(f, x) => {
      let f2 = match uterm_to_dterm_depth(f, depth, unifier) {
        Some(v) => v
        None => return None
      }
      let x2 = match uterm_to_dterm_depth(x, depth, unifier) {
        Some(v) => v
        None => return None
      }
      Some(DApp(f2, x2))
    }
    UPi(a, b) | UImplicitPi(a, b) => {
      let a2 = match uterm_to_dterm_depth(a, depth, unifier) {
        Some(v) => v
        None => return None
      }
      let b2 = match uterm_to_dterm_depth(b, depth + 1, unifier) {
        Some(v) => v
        None => return None
      }
      Some(DPi(a2, b2))
    }
    USigma(a, b) => {
      let a2 = match uterm_to_dterm_depth(a, depth, unifier) {
        Some(v) => v
        None => return None
      }
      let b2 = match uterm_to_dterm_depth(b, depth + 1, unifier) {
        Some(v) => v
        None => return None
      }
      Some(DSigma(a2, b2))
    }
    UPair(a, b) => {
      let a2 = match uterm_to_dterm_depth(a, depth, unifier) {
        Some(v) => v
        None => return None
      }
      let b2 = match uterm_to_dterm_depth(b, depth, unifier) {
        Some(v) => v
        None => return None
      }
      Some(DPair(a2, b2))
    }
    UFst(x) =>
      match uterm_to_dterm_depth(x, depth, unifier) {
        Some(v) => Some(DFst(v))
        None => None
      }
    USnd(x) =>
      match uterm_to_dterm_depth(x, depth, unifier) {
        Some(v) => Some(DSnd(v))
        None => None
      }
    UBoolLit(value) => Some(DBoolLit(value))
    UNatZero => Some(DNatZero)
    USucc(x) =>
      match uterm_to_dterm_depth(x, depth, unifier) {
        Some(v) => Some(DSucc(v))
        None => None
      }
    UNatElim(m, z, s, scrut) => {
      // DTerm's DNatElim stores the motive *body* under its Nat
      // binder, not a lambda.  A UTerm lambda therefore contributes
      // its body; any other motive is eta-expanded under the binder.
      let motive = match uterm_whnf(m, unifier) {
        ULam(_, body) =>
          match uterm_to_dterm_depth(body, depth + 1, unifier) {
            Some(body2) => body2
            None => return None
          }
        _ =>
          match uterm_to_dterm_depth(uterm_shift(m, 1, 0), depth + 1, unifier) {
            Some(v) => DApp(v, DTVar(0))
            None => return None
          }
      }
      let z2 = match uterm_to_dterm_depth(z, depth, unifier) {
        Some(v) => v
        None => return None
      }
      let s2 = match uterm_to_dterm_depth(s, depth, unifier) {
        Some(v) => v
        None => return None
      }
      let scrut2 = match uterm_to_dterm_depth(scrut, depth, unifier) {
        Some(v) => v
        None => return None
      }
      Some(DNatElim(motive, z2, s2, scrut2))
    }
  }
}

///|
/// Optimize and translate a closed elaborated term to DTerm.  Fails
/// if a metavariable remains unsolved.
pub fn elab_result_to_dterm(e : Elaborator, result : ElabResult) -> DTerm? {
  let term = hou_semantic_optimize(result.term, e.unifier)
  if uterm_contains_unsolved_meta(term, e.unifier) {
    None
  } else {
    uterm_to_dterm_depth(term, 0, e.unifier)
  }
}

///|
pub fn elab_type_to_dterm(e : Elaborator, result : ElabResult) -> DTerm? {
  let ty = hou_semantic_optimize(result.ty, e.unifier)
  if uterm_contains_unsolved_meta(ty, e.unifier) {
    None
  } else {
    uterm_to_dterm_depth(ty, 0, e.unifier)
  }
}

///|

///|
/// Checks for the Phase 9 HOU fragments beyond distinct-variable
/// Miller patterns: repeated-variable spines, constructor-pattern
/// extraction, distinct flex-flex intersection, and the delimited
/// same-head case.  In this deterministic layer, non-pattern
/// applications outside these fragments still fail instead of being
/// guessed; the separate bounded search below may then be called
/// explicitly.
pub fn check_hou_phase9_extensions() -> Bool {
  // Repeated variable: ?F x x = (succ x, x), at depth 2 with x
  // represented by de Bruijn index 1.
  let u1 = unifier_new()
  ignore(hou_fresh_meta(u1, 0))
  let repeated_problem = UMeta(0, [UVar(1), UVar(1)])
  let repeated_rhs = UPair(USucc(UVar(1)), UVar(1))
  if !hou_unify(repeated_problem, repeated_rhs, 2, u1) {
    return false
  }
  if hou_semantic_optimize(repeated_problem, u1) != repeated_rhs {
    return false
  }

  // Constructor-pattern spine:
  // ?F (succ x) (y, 0) = (succ y, x), where x=1 and y=0 in de
  // Bruijn indices at depth 2.  The solution extracts x by the
  // predecessor eliminator and y by first projection.
  let u2 = unifier_new()
  ignore(hou_fresh_meta(u2, 0))
  let constructor_problem = UMeta(0, [USucc(UVar(1)), UPair(UVar(0), UNatZero)])
  let constructor_rhs = UPair(USucc(UVar(0)), UVar(1))
  if !hou_unify(constructor_problem, constructor_rhs, 2, u2) {
    return false
  }
  if hou_semantic_optimize(constructor_problem, u2) != constructor_rhs {
    return false
  }

  // Distinct flex-flex with disjoint variable support:
  // ?F (succ x) = ?G y.  Both metas are assigned the same fresh
  // constant common metavariable.
  let u3 = unifier_new()
  ignore(hou_fresh_meta(u3, 0))
  ignore(hou_fresh_meta(u3, 0))
  let flex_left = UMeta(0, [USucc(UVar(1))])
  let flex_right = UMeta(1, [UVar(0)])
  if !hou_unify(flex_left, flex_right, 2, u3) {
    return false
  }
  if hou_semantic_optimize(flex_left, u3) !=
    hou_semantic_optimize(flex_right, u3) {
    return false
  }

  // Distinct flex-flex with a shared constructor-pattern variable:
  // ?F (succ x) y = ?G (y, 0).  This is solved soundly (by direct
  // constructor assignment, without needing the intersection path).
  let u4 = unifier_new()
  ignore(hou_fresh_meta(u4, 0))
  ignore(hou_fresh_meta(u4, 0))
  let shared_left = UMeta(0, [USucc(UVar(1)), UVar(0)])
  let shared_right = UMeta(1, [UPair(UVar(0), UNatZero)])
  if !hou_unify(shared_left, shared_right, 2, u4) {
    return false
  }
  if hou_semantic_optimize(shared_left, u4) !=
    hou_semantic_optimize(shared_right, u4) {
    return false
  }

  // Same-head flex-flex whose corresponding arguments unify:
  // ?F (?G x) = ?F x solves ?G as the identity pattern.
  let u5 = unifier_new()
  ignore(hou_fresh_meta(u5, 0))
  ignore(hou_fresh_meta(u5, 0))
  let same_left = UMeta(0, [UMeta(1, [UVar(0)])])
  let same_right = UMeta(0, [UVar(0)])
  if !hou_unify(same_left, same_right, 1, u5) {
    return false
  }

  // Same-head permutation remains a residual constraint for the
  // deterministic unifier, not an arbitrary pruning: ?F x y = ?F y
  // x is not assigned by `hou_unify` itself.
  let u6 = unifier_new()
  ignore(hou_fresh_meta(u6, 0))
  if hou_unify(
      UMeta(0, [UVar(1), UVar(0)]),
      UMeta(0, [UVar(0), UVar(1)]),
      2,
      u6,
    ) {
    return false
  }

  // An arbitrary rigid application in the spine is still outside
  // this deterministic fragment: ?F (g x) = succ x is not guessed
  // by `hou_unify` (the bounded search is a distinct entry point).
  let u7 = unifier_new()
  ignore(hou_fresh_meta(u7, 0))
  !hou_unify(UMeta(0, [UApp(UConst("g"), UVar(0))]), USucc(UVar(0)), 1, u7)
}

///|
pub fn check_hou_elaborator() -> Bool {
  // Direct Miller pattern problem at depth 2.  Levels are x=0, y=1,
  // hence de Bruijn indices are y=0 and x=1: solve ?F x y = (y, x).
  let u = unifier_new()
  let f = hou_fresh_meta(u, 2)
  if !hou_unify(f, UPair(UVar(0), UVar(1)), 2, u) {
    return false
  }
  let instantiated = hou_semantic_optimize(
    UApp(UApp(ULam(uty_nat(), ULam(uty_nat(), f)), UNatZero), USucc(UNatZero)),
    u,
  )
  if instantiated != UPair(USucc(UNatZero), UNatZero) {
    return false
  }
  // Scope failure: a pattern over the first variable alone cannot
  // be solved by a body mentioning the second variable.
  let u2 = unifier_new()
  let only_x = uterm_shift(hou_fresh_meta(u2, 1), 1, 0)
  if hou_unify(only_x, UVar(0), 2, u2) {
    return false
  }
  // Implicit identity in a one-variable context.  Elaborating
  // `id true` inserts a type metavariable and HOU solves it as Bool.
  let id_ty = UImplicitPi(UType(0), UPi(UVar(0), UVar(1)))
  let e2 = elaborator_new()
  elab_push(e2, "id", id_ty)
  let id_result = elab_infer(e2, SApp(SVar("id"), SBoolLit(true)))
  elab_truncate(e2, 0)
  let id_ok = match id_result {
    Some(result) => {
      let opt_ty = hou_semantic_optimize(result.ty, e2.unifier)
      let opt_term = hou_semantic_optimize(result.term, e2.unifier)
      let term_ok = match opt_term {
        UApp(UApp(UVar(0), UConst(name)), UBoolLit(true)) => name == "Bool"
        _ => false
      }
      opt_ty == uty_bool() && term_ok
    }
    None => false
  }
  if !id_ok {
    return false
  }
  // Dependent motive inference: checking a Nat eliminator against
  // Nat -> Nat solves its motive as a constant family.  The core is
  // translated to DTerm, accepted by the dependent checker, and
  // computes on a literal.
  let e3 = elaborator_new()
  let surface3 = SLam(
    "n",
    Some(uty_nat()),
    SNatElim(
      SHole,
      SNatZero,
      SLam("k", None, SLam("ih", None, SVar("ih"))),
      SVar("n"),
    ),
  )
  let result3 = match
    elab_check(e3, surface3, uty_arrow(uty_nat(), uty_nat())) {
    Some(r) => r
    None => return false
  }
  let core = match elab_result_to_dterm(e3, result3) {
    Some(t) => t
    None => return false
  }
  let core_ty = match elab_type_to_dterm(e3, result3) {
    Some(t) => t
    None => return false
  }
  if !dep_check_closed(core, core_ty) ||
    dep_nf_closed(DApp(core, d_nat_lit(3)), DNatTy) != Some(DNatZero) {
    return false
  }
  // The remaining surface forms elaborate through the same
  // bidirectional rules, with projections reduced by the semantic
  // optimizer.
  let e4 = elaborator_new()
  let pair_surface = SPair(SAnn(SBoolLit(true), uty_bool()), SSucc(SNatZero))
  let fst_ok = match elab_infer(e4, SFst(pair_surface)) {
    Some(r) =>
      hou_semantic_optimize(r.term, e4.unifier) == UBoolLit(true) &&
      hou_semantic_optimize(r.ty, e4.unifier) == uty_bool()
    None => false
  }
  let snd_ok = match elab_infer(e4, SSnd(pair_surface)) {
    Some(r) =>
      hou_semantic_optimize(r.term, e4.unifier) == USucc(UNatZero) &&
      hou_semantic_optimize(r.ty, e4.unifier) == uty_nat()
    None => false
  }
  let unit_ok = match elab_infer(e4, SUnitLit) {
    Some(r) => r.ty == uty_unit()
    None => false
  }
  fst_ok && snd_ok && unit_ok
}
