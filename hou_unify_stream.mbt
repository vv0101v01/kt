// ---------------------------------------------------------------------------
// Bounded Huet search beyond the deterministic fragment
// ---------------------------------------------------------------------------

///|
/// Outcome of bounded higher-order search.  `HouResidual` is not a
/// claim of non-unifiability: it records that the deterministic
/// fragment and the guesses allowed by the supplied depth did not
/// solve the equation.  General HOU is undecidable, so this API is
/// deliberately transactional and budget-explicit.
pub enum HouSearchStatus {
  HouSolved
  HouNoUnifier
  HouResidual
  HouBudgetExceeded
} derive(Debug, Eq)

///|
pub extend HouSearchStatus with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouSearchStatus with Eq::{not_equal, equal}

///|
pub struct HouSearchReport {
  status : HouSearchStatus
  solved_metas : Int32
  nodes : Int32
  branches_tried : Int32
  max_depth_reached : Int32
} derive(Debug, Eq)

///|
pub extend HouSearchReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouSearchReport with Eq::{not_equal, equal}

///|
fn hou_clone_unifier(unifier : Unifier) -> Unifier {
  let metas : Array[UMetaInfo] = []
  for i in 0..<unifier.metas.length() {
    metas.push(UMetaInfo::{
      context_depth: unifier.metas[i].context_depth,
      solution: unifier.metas[i].solution,
    })
  }
  Unifier::{ metas, solved_count: unifier.solved_count, }
}

///|
fn hou_restore_unifier(unifier : Unifier, snapshot : Unifier) -> Unit {
  while unifier.metas.length() > 0 {
    ignore(unifier.metas.pop())
  }
  for i in 0..<snapshot.metas.length() {
    unifier.metas.push(UMetaInfo::{
      context_depth: snapshot.metas[i].context_depth,
      solution: snapshot.metas[i].solution,
    })
  }
  unifier.solved_count = snapshot.solved_count
}

///|
fn hou_fresh_meta_id(unifier : Unifier) -> Int32 {
  let id = unifier.metas.length()
  unifier.metas.push(UMetaInfo::{ context_depth: 0, solution: None, })
  id
}

///|
fn huet_formal_index(
  formals : Int32,
  binders : Int32,
  position : Int32,
) -> Int32 {
  formals - 1 - position + binders
}

///|
fn huet_fresh_over(
  unifier : Unifier,
  formals : Int32,
  binders : Int32,
) -> UTerm {
  let args : Array[UTerm] = []
  for position in 0..<formals {
    args.push(UVar(huet_formal_index(formals, binders, position)))
  }
  for binder in 0..<binders {
    args.push(UVar(binders - 1 - binder))
  }
  UMeta(hou_fresh_meta_id(unifier), args)
}

///|
fn huet_assign_solution(
  unifier : Unifier,
  id : Int32,
  body : UTerm,
  arity : Int32,
) -> Bool {
  if id < 0 || id >= unifier.metas.length() {
    return false
  }
  match unifier.metas[id].solution {
    Some(_) => return false
    None => ()
  }
  let solution = wrap_pattern_lambdas(body, arity)
  if uterm_occurs_meta(solution, id, unifier) {
    return false
  }
  assign_meta_solution(unifier, id, solution)
  true
}

///|
/// Build the rigid part of a Huet imitation template.  Only closed
/// rigid heads and term formers are copied; every genuinely unknown
/// subterm becomes a fresh metavariable over the formal spine (and
/// any template binders).  Bound-variable heads are handled by the
/// separate projection branches.
fn huet_imitation_template(
  unifier : Unifier,
  rhs : UTerm,
  formals : Int32,
  binders : Int32,
) -> UTerm? {
  match uterm_whnf(rhs, unifier) {
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => Some(rhs)
    UApp(f, _) =>
      match huet_imitation_template(unifier, f, formals, binders) {
        Some(head) =>
          Some(UApp(head, huet_fresh_over(unifier, formals, binders)))
        None => None
      }
    UPair(_, _) =>
      Some(
        UPair(
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders),
        ),
      )
    UFst(_) => Some(UFst(huet_fresh_over(unifier, formals, binders)))
    USnd(_) => Some(USnd(huet_fresh_over(unifier, formals, binders)))
    USucc(_) => Some(USucc(huet_fresh_over(unifier, formals, binders)))
    UNatElim(_, _, _, _) =>
      Some(
        UNatElim(
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders),
        ),
      )
    ULam(_, _) =>
      Some(
        ULam(
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders + 1),
        ),
      )
    UPi(_, _) =>
      Some(
        UPi(
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders + 1),
        ),
      )
    UImplicitPi(_, _) =>
      Some(
        UImplicitPi(
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders + 1),
        ),
      )
    USigma(_, _) =>
      Some(
        USigma(
          huet_fresh_over(unifier, formals, binders),
          huet_fresh_over(unifier, formals, binders + 1),
        ),
      )
    _ => None
  }
}

///|
/// Deep imitation: like `huet_imitation_template`, but rigid
/// structure is copied recursively -- into arguments and under
/// binders -- and variables bound by the copied binders are kept
/// (they have the same relative indices in the template).
/// Subterms that cannot be copied (flex heads, free variables of
/// the equation context) become fresh pattern metavariables.
/// This is still a Huet imitation guess, just a more specific
/// one: it solves in one branch some problems whose standard
/// imitation needs several further search rounds.
fn huet_imitation_template_deep(
  unifier : Unifier,
  rhs : UTerm,
  formals : Int32,
  binders : Int32,
) -> UTerm? {
  match uterm_whnf(rhs, unifier) {
    UConst(_) | UType(_) | UBoolLit(_) | UNatZero => Some(rhs)
    UVar(k) => if k < binders { Some(rhs) } else { None }
    UApp(f, x) =>
      match huet_imitation_template_deep(unifier, f, formals, binders) {
        Some(head) =>
          Some(UApp(head, huet_deep_or_fresh(unifier, x, formals, binders)))
        None => None
      }
    UPair(a, b) =>
      Some(
        UPair(
          huet_deep_or_fresh(unifier, a, formals, binders),
          huet_deep_or_fresh(unifier, b, formals, binders),
        ),
      )
    UFst(a) => Some(UFst(huet_deep_or_fresh(unifier, a, formals, binders)))
    USnd(a) => Some(USnd(huet_deep_or_fresh(unifier, a, formals, binders)))
    USucc(a) => Some(USucc(huet_deep_or_fresh(unifier, a, formals, binders)))
    UNatElim(a, b, c, d) =>
      Some(
        UNatElim(
          huet_deep_or_fresh(unifier, a, formals, binders),
          huet_deep_or_fresh(unifier, b, formals, binders),
          huet_deep_or_fresh(unifier, c, formals, binders),
          huet_deep_or_fresh(unifier, d, formals, binders),
        ),
      )
    ULam(dom, body) =>
      Some(
        ULam(
          huet_deep_or_fresh(unifier, dom, formals, binders),
          huet_deep_or_fresh(unifier, body, formals, binders + 1),
        ),
      )
    UPi(dom, body) =>
      Some(
        UPi(
          huet_deep_or_fresh(unifier, dom, formals, binders),
          huet_deep_or_fresh(unifier, body, formals, binders + 1),
        ),
      )
    UImplicitPi(dom, body) =>
      Some(
        UImplicitPi(
          huet_deep_or_fresh(unifier, dom, formals, binders),
          huet_deep_or_fresh(unifier, body, formals, binders + 1),
        ),
      )
    USigma(dom, body) =>
      Some(
        USigma(
          huet_deep_or_fresh(unifier, dom, formals, binders),
          huet_deep_or_fresh(unifier, body, formals, binders + 1),
        ),
      )
    _ => None
  }
}

///|
fn huet_deep_or_fresh(
  unifier : Unifier,
  rhs : UTerm,
  formals : Int32,
  binders : Int32,
) -> UTerm {
  match huet_imitation_template_deep(unifier, rhs, formals, binders) {
    Some(template) => template
    None => huet_fresh_over(unifier, formals, binders)
  }
}

///|
fn huet_projection_template(
  unifier : Unifier,
  formals : Int32,
  position : Int32,
  applied_args : Int32,
) -> UTerm {
  let mut out = UVar(huet_formal_index(formals, 0, position))
  for _i in 0..<applied_args {
    out = UApp(out, huet_fresh_over(unifier, formals, 0))
  }
  out
}

///|
fn hou_search_note_node(
  state : Array[Int32],
  max_nodes : Int32,
  depth : Int32,
) -> Bool {
  state[0] = state[0] + 1
  if depth > state[2] {
    state[2] = depth
  }
  max_nodes <= 0 || state[0] <= max_nodes
}

///|
fn hou_search_try_body(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
  meta_id : Int32,
  arity : Int32,
  body : UTerm,
) -> Int32 {
  state[1] = state[1] + 1
  if !huet_assign_solution(unifier, meta_id, body, arity) {
    return -2
  }
  hou_search_go(
    a,
    b,
    depth,
    unifier,
    state,
    max_nodes,
    search_depth + 1,
    max_depth,
  )
}

///|
fn hou_search_try_flex(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
  meta_id : Int32,
  args : Array[UTerm],
  rhs : UTerm,
) -> Int32 {
  let arity = args.length()
  // Imitation.
  {
    let snapshot = hou_clone_unifier(unifier)
    match huet_imitation_template(unifier, rhs, arity, 0) {
      Some(body) => {
        let result = hou_search_try_body(
          a, b, depth, unifier, state, max_nodes, search_depth, max_depth, meta_id,
          arity, body,
        )
        if result == 1 || result == -1 {
          return result
        }
      }
      None => ()
    }
    hou_restore_unifier(unifier, snapshot)
  }
  // Deep imitation (Phase 11): a more specific imitation guess
  // that copies rigid structure into arguments and under binders.
  {
    let snapshot = hou_clone_unifier(unifier)
    match huet_imitation_template_deep(unifier, rhs, arity, 0) {
      Some(body) => {
        let result = hou_search_try_body(
          a, b, depth, unifier, state, max_nodes, search_depth, max_depth, meta_id,
          arity, body,
        )
        if result == 1 || result == -1 {
          return result
        }
      }
      None => ()
    }
    hou_restore_unifier(unifier, snapshot)
  }
  // Projections, first exact projections and then projections
  // applied to fresh subgoals.  The number of applied fresh
  // subgoals is bounded by `state[3]` (`max_projection_args`),
  // threaded through the search state.
  let proj_limit = state[3] + 1
  for applied_args in 0..<proj_limit {
    for position in 0..<arity {
      let snapshot = hou_clone_unifier(unifier)
      let body = huet_projection_template(
        unifier, arity, position, applied_args,
      )
      let result = hou_search_try_body(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, meta_id,
        arity, body,
      )
      if result == 1 || result == -1 {
        return result
      }
      hou_restore_unifier(unifier, snapshot)
    }
  }
  // Eta generation: guess one more lambda and solve under it.
  {
    let snapshot = hou_clone_unifier(unifier)
    let body = ULam(UConst("PatternDomain"), huet_fresh_over(unifier, arity, 1))
    let result = hou_search_try_body(
      a, b, depth, unifier, state, max_nodes, search_depth, max_depth, meta_id, arity,
      body,
    )
    if result == 1 || result == -1 {
      return result
    }
    hou_restore_unifier(unifier, snapshot)
  }
  // A constant guess.  This is a sound specific unifier whenever
  // the recursive equation can solve the fresh constant.
  let snapshot = hou_clone_unifier(unifier)
  let body = UMeta(hou_fresh_meta_id(unifier), [])
  let result = hou_search_try_body(
    a, b, depth, unifier, state, max_nodes, search_depth, max_depth, meta_id, arity,
    body,
  )
  if result != 1 {
    hou_restore_unifier(unifier, snapshot)
  }
  result
}

///|
fn hou_search_same_head_prune(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
  meta_id : Int32,
  args_a : Array[UTerm],
  args_b : Array[UTerm],
) -> Int32 {
  if args_a.length() != args_b.length() {
    return -2
  }
  state[1] = state[1] + 1
  // Keep precisely the positions made equal by sound pairwise
  // unification.  For a permutation with no fixed position this
  // retains no argument; for a partially invariant spine it retains
  // every invariant coordinate.  The result is a specific unifier,
  // not a claimed most general one.
  let fixed : Array[Int32] = []
  for i in 0..<args_a.length() {
    let before_pair = hou_clone_unifier(unifier)
    if hou_unify(args_a[i], args_b[i], depth, unifier) {
      if hou_semantic_optimize(args_a[i], unifier) ==
        hou_semantic_optimize(args_b[i], unifier) {
        fixed.push(i)
      }
    } else {
      hou_restore_unifier(unifier, before_pair)
    }
  }
  // Pairwise assignments can make additional positions equal.
  for i in 0..<args_a.length() {
    if pattern_level_position(fixed, i) < 0 &&
      hou_semantic_optimize(args_a[i], unifier) ==
      hou_semantic_optimize(args_b[i], unifier) {
      fixed.push(i)
    }
  }
  let common_id = hou_fresh_meta_id(unifier)
  let common_args : Array[UTerm] = []
  for i in 0..<fixed.length() {
    common_args.push(UVar(huet_formal_index(args_a.length(), 0, fixed[i])))
  }
  if !huet_assign_solution(
      unifier,
      meta_id,
      UMeta(common_id, common_args),
      args_a.length(),
    ) {
    return -2
  }
  hou_search_go(
    a,
    b,
    depth,
    unifier,
    state,
    max_nodes,
    search_depth + 1,
    max_depth,
  )
}

///|
fn hou_search_common_constant(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
  id_a : Int32,
  args_a : Array[UTerm],
  id_b : Int32,
  args_b : Array[UTerm],
) -> Int32 {
  state[1] = state[1] + 1
  let common_id = hou_fresh_meta_id(unifier)
  if !huet_assign_solution(unifier, id_a, UMeta(common_id, []), args_a.length()) ||
    !huet_assign_solution(unifier, id_b, UMeta(common_id, []), args_b.length()) {
    return -2
  }
  hou_search_go(
    a,
    b,
    depth,
    unifier,
    state,
    max_nodes,
    search_depth + 1,
    max_depth,
  )
}

///|
/// Identification for distinct flex heads (Phase 11): guess a
/// common fresh head applied to the argument positions that can
/// be made equal on both sides (found greedily by transactional
/// pairwise unification).  This generalizes the common-constant
/// guess (the empty common spine), retaining exactly the shared
/// argument dependence.  Like the same-head prune, the result is
/// a sound specific unifier, not a most general one.
fn hou_search_identification(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
  id_a : Int32,
  args_a : Array[UTerm],
  id_b : Int32,
  args_b : Array[UTerm],
) -> Int32 {
  state[1] = state[1] + 1
  let used_b : Array[Bool] = []
  for _i in 0..<args_b.length() {
    used_b.push(false)
  }
  let positions_a : Array[Int32] = []
  let positions_b : Array[Int32] = []
  for i in 0..<args_a.length() {
    for j in 0..<args_b.length() {
      if used_b[j] {
        continue
      }
      let before_pair = hou_clone_unifier(unifier)
      if hou_unify(args_a[i], args_b[j], depth, unifier) &&
        hou_semantic_optimize(args_a[i], unifier) ==
        hou_semantic_optimize(args_b[j], unifier) {
        positions_a.push(i)
        positions_b.push(j)
        used_b[j] = true
        break
      }
      hou_restore_unifier(unifier, before_pair)
    }
  }
  if positions_a.length() == 0 {
    return -2
  }
  let common_id = hou_fresh_meta_id(unifier)
  let common_args_a : Array[UTerm] = []
  for i in 0..<positions_a.length() {
    common_args_a.push(
      UVar(huet_formal_index(args_a.length(), 0, positions_a[i])),
    )
  }
  let common_args_b : Array[UTerm] = []
  for i in 0..<positions_b.length() {
    common_args_b.push(
      UVar(huet_formal_index(args_b.length(), 0, positions_b[i])),
    )
  }
  if !huet_assign_solution(
      unifier,
      id_a,
      UMeta(common_id, common_args_a),
      args_a.length(),
    ) ||
    !huet_assign_solution(
      unifier,
      id_b,
      UMeta(common_id, common_args_b),
      args_b.length(),
    ) {
    return -2
  }
  hou_search_go(
    a,
    b,
    depth,
    unifier,
    state,
    max_nodes,
    search_depth + 1,
    max_depth,
  )
}

///|
fn hou_search_all(
  pairs : Array[(UTerm, UTerm)],
  depths : Array[Int32],
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
) -> Int32 {
  for i in 0..<pairs.length() {
    let result = hou_search_go(
      pairs[i].0,
      pairs[i].1,
      depths[i],
      unifier,
      state,
      max_nodes,
      search_depth,
      max_depth,
    )
    if result != 1 {
      return result
    }
  }
  1
}

///|
fn hou_search_decompose(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
) -> Int32 {
  match (uterm_whnf(a, unifier), uterm_whnf(b, unifier)) {
    (ULam(ad, ab), ULam(bd, bb)) =>
      hou_search_all(
        [(ad, bd), (ab, bb)],
        [depth, depth + 1],
        unifier,
        state,
        max_nodes,
        search_depth,
        max_depth,
      )
    (ULam(_, body), other) =>
      hou_search_go(
        body,
        UApp(uterm_shift(other, 1, 0), UVar(0)),
        depth + 1,
        unifier,
        state,
        max_nodes,
        search_depth + 1,
        max_depth,
      )
    (other, ULam(_, body)) =>
      hou_search_go(
        UApp(uterm_shift(other, 1, 0), UVar(0)),
        body,
        depth + 1,
        unifier,
        state,
        max_nodes,
        search_depth + 1,
        max_depth,
      )
    (UPi(x1, y1), UPi(x2, y2))
    | (UImplicitPi(x1, y1), UImplicitPi(x2, y2))
    | (USigma(x1, y1), USigma(x2, y2)) =>
      hou_search_all(
        [(x1, x2), (y1, y2)],
        [depth, depth + 1],
        unifier,
        state,
        max_nodes,
        search_depth,
        max_depth,
      )
    (UPair(x1, y1), UPair(x2, y2)) | (UApp(x1, y1), UApp(x2, y2)) =>
      hou_search_all(
        [(x1, x2), (y1, y2)],
        [depth, depth],
        unifier,
        state,
        max_nodes,
        search_depth,
        max_depth,
      )
    (UFst(x), UFst(y)) | (USnd(x), USnd(y)) | (USucc(x), USucc(y)) =>
      hou_search_go(
        x, y, depth, unifier, state, max_nodes, search_depth, max_depth,
      )
    (UNatElim(a1, b1, c1, d1), UNatElim(a2, b2, c2, d2)) =>
      hou_search_all(
        [(a1, a2), (b1, b2), (c1, c2), (d1, d2)],
        [depth, depth, depth, depth],
        unifier,
        state,
        max_nodes,
        search_depth,
        max_depth,
      )
    _ => -2
  }
}

///|
fn hou_search_go(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  state : Array[Int32],
  max_nodes : Int32,
  search_depth : Int32,
  max_depth : Int32,
) -> Int32 {
  if !hou_search_note_node(state, max_nodes, search_depth) {
    return -1
  }
  let snapshot = hou_clone_unifier(unifier)
  if hou_unify(a, b, depth, unifier) {
    return 1
  }
  hou_restore_unifier(unifier, snapshot)
  if !uterm_contains_unsolved_meta(a, unifier) &&
    !uterm_contains_unsolved_meta(b, unifier) {
    return 0
  }
  if search_depth >= max_depth {
    return -2
  }
  let a_head = meta_head_spine(a, unifier)
  let b_head = meta_head_spine(b, unifier)
  match (a_head, b_head) {
    (Some((id_a, args_a)), Some((id_b, args_b))) => {
      if id_a == id_b {
        let before = hou_clone_unifier(unifier)
        let pruned = hou_search_same_head_prune(
          a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id_a,
          args_a, args_b,
        )
        if pruned == 1 || pruned == -1 {
          return pruned
        }
        hou_restore_unifier(unifier, before)
        return hou_search_try_flex(
          a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id_a,
          args_a, b,
        )
      }
      let first = hou_search_try_flex(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id_a, args_a,
        b,
      )
      if first == 1 || first == -1 {
        return first
      }
      let second = hou_search_try_flex(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id_b, args_b,
        a,
      )
      if second == 1 || second == -1 {
        return second
      }
      let before_id = hou_clone_unifier(unifier)
      let identified = hou_search_identification(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id_a, args_a,
        id_b, args_b,
      )
      if identified == 1 || identified == -1 {
        return identified
      }
      hou_restore_unifier(unifier, before_id)
      let before = hou_clone_unifier(unifier)
      let common = hou_search_common_constant(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id_a, args_a,
        id_b, args_b,
      )
      if common != 1 {
        hou_restore_unifier(unifier, before)
      }
      common
    }
    (Some((id, args)), None) =>
      hou_search_try_flex(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id, args,
        b,
      )
    (None, Some((id, args))) =>
      hou_search_try_flex(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth, id, args,
        a,
      )
    (None, None) =>
      hou_search_decompose(
        a, b, depth, unifier, state, max_nodes, search_depth, max_depth,
      )
  }
}

///|
/// Bounded Huet search.  The deterministic Miller/constructor/
/// intersection fragment is tried first at every node; thereafter
/// the search branches over imitation, deep imitation,
/// projection (applied to at most `max_projection_args` fresh
/// subgoals), eta-generation, same-head invariant-coordinate
/// pruning, and (for distinct flex-flex pairs) identification
/// over a shared argument spine, falling back to a common
/// constant.  A failed or exhausted search restores the input
/// unifier exactly.
pub fn hou_search_unify(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  max_nodes~ : Int32 = 1000,
  max_depth~ : Int32 = 4,
  max_projection_args~ : Int32 = 2,
) -> HouSearchReport {
  let initial = hou_clone_unifier(unifier)
  // Search state: [nodes, branches, max depth reached,
  // projection applied-argument cap].
  let state : Array[Int32] = [
    0,
    0,
    0,
    if max_projection_args < 0 {
      0
    } else {
      max_projection_args
    },
  ]
  let code = if max_nodes <= 0 {
    -1
  } else {
    hou_search_go(a, b, depth, unifier, state, max_nodes, 0, max_depth)
  }
  let status = if code == 1 {
    HouSolved
  } else if code == 0 {
    HouNoUnifier
  } else if code == -1 {
    HouBudgetExceeded
  } else {
    HouResidual
  }
  if status != HouSolved {
    hou_restore_unifier(unifier, initial)
  }
  let mut solved = 0
  for i in 0..<unifier.metas.length() {
    match unifier.metas[i].solution {
      Some(_) => solved = solved + 1
      None => ()
    }
  }
  HouSearchReport::{
    status,
    solved_metas: solved,
    nodes: state[0],
    branches_tried: state[1],
    max_depth_reached: state[2],
  }
}

///|
/// Boolean wrapper for bounded Huet search.
pub fn hou_search_unify_bool(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  max_nodes~ : Int32 = 1000,
  max_depth~ : Int32 = 4,
) -> Bool {
  hou_search_unify(a, b, depth, unifier, max_nodes~, max_depth~).status ==
  HouSolved
}

///|
pub struct HouIterativeReport {
  report : HouSearchReport
  solved_at_depth : Int32
  rounds : Int32
} derive(Debug, Eq)

///|
pub extend HouIterativeReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouIterativeReport with Eq::{not_equal, equal}

///|
/// Iterative-deepening Huet search (Phase 11): run bounded search
/// at depths `0, 1, ..., depth_cap`, each with its own node
/// budget, stopping at the first success or at a definitive
/// no-unifier answer.  Because every round is transactional, a
/// failed round leaves the unifier untouched for the next.  The
/// report names the shallowest solving depth (`-1` if none), so
/// callers can see how much guessing a problem actually needed.
pub fn hou_search_unify_iterative(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  max_nodes_per_round~ : Int32 = 1000,
  depth_cap~ : Int32 = 6,
  max_projection_args~ : Int32 = 2,
) -> HouIterativeReport {
  let mut last : HouSearchReport? = None
  for d in 0..<(depth_cap + 1) {
    let report = hou_search_unify(
      a,
      b,
      depth,
      unifier,
      max_nodes=max_nodes_per_round,
      max_depth=d,
      max_projection_args~,
    )
    if report.status == HouSolved {
      return { report, solved_at_depth: d, rounds: d + 1, }
    }
    if report.status == HouNoUnifier {
      return { report, solved_at_depth: -1, rounds: d + 1, }
    }
    last = Some(report)
  }
  let fallback = HouSearchReport::{
    status: HouResidual,
    solved_metas: 0,
    nodes: 0,
    branches_tried: 0,
    max_depth_reached: 0,
  }
  {
    report: match last {
      Some(r) => r
      None => fallback
    },
    solved_at_depth: -1,
    rounds: depth_cap + 1,
  }
}

///|
/// Checks for the search branches that are deliberately absent
/// from deterministic `hou_unify`: an arbitrary rigid spine solved
/// by imitation plus projections, a same-head permutation solved
/// by invariant-coordinate pruning, transactional failure, and an
/// explicit budget outcome.
pub fn check_hou_bounded_search() -> Bool {
  // ?F (g x) (succ y) = ((g x), succ y), with x = UVar(1),
  // y = UVar(0).  Imitation guesses the pair and projection
  // solves both coordinates over the non-variable spine.
  let u1 = unifier_new()
  ignore(hou_fresh_meta(u1, 0))
  let gx = UApp(UConst("g"), UVar(1))
  let sy = USucc(UVar(0))
  let rigid_problem = UMeta(0, [gx, sy])
  let rigid_rhs = UPair(gx, sy)
  let rigid_report = hou_search_unify(rigid_problem, rigid_rhs, 2, u1)
  if rigid_report.status != HouSolved ||
    hou_semantic_optimize(rigid_problem, u1) != rigid_rhs {
    return false
  }
  // ?F x y = ?F y x: prune to the (empty) invariant coordinate
  // set.  The two sides become the same fresh constant; this is a
  // sound specific symmetric unifier.
  let u2 = unifier_new()
  ignore(hou_fresh_meta(u2, 0))
  let perm_left = UMeta(0, [UVar(1), UVar(0)])
  let perm_right = UMeta(0, [UVar(0), UVar(1)])
  let perm_report = hou_search_unify(perm_left, perm_right, 2, u2)
  if perm_report.status != HouSolved ||
    hou_semantic_optimize(perm_left, u2) !=
    hou_semantic_optimize(perm_right, u2) {
    return false
  }
  // A partially invariant permutation retains its fixed second
  // coordinate: ?F x y z = ?F y x z (indices 2,1,0).  Pruning to
  // z solves it, and the optimized sides agree.
  let u3 = unifier_new()
  ignore(hou_fresh_meta(u3, 0))
  let fixed_left = UMeta(0, [UVar(2), UVar(1), UVar(0)])
  let fixed_right = UMeta(0, [UVar(1), UVar(2), UVar(0)])
  if !hou_search_unify_bool(fixed_left, fixed_right, 3, u3) ||
    hou_semantic_optimize(fixed_left, u3) !=
    hou_semantic_optimize(fixed_right, u3) {
    return false
  }
  // Transactionality: an intentionally tiny budget leaves the
  // original unifier untouched.
  let u4 = unifier_new()
  ignore(hou_fresh_meta(u4, 0))
  let before_count = u4.metas.length()
  let budget_report = hou_search_unify(
    UMeta(0, [gx, sy]),
    rigid_rhs,
    2,
    u4,
    max_nodes=1,
  )
  if budget_report.status != HouBudgetExceeded ||
    u4.metas.length() != before_count {
    return false
  }
  match u4.metas[0].solution {
    Some(_) => return false
    None => ()
  }
  // A closed rigid clash is a genuine no-unifier result.
  let u5 = unifier_new()
  hou_search_unify(UBoolLit(true), UBoolLit(false), 0, u5).status ==
  HouNoUnifier
}

///|
/// Phase 11 checks: deep imitation templates, the projection
/// applied-argument cap, identification retaining shared
/// argument dependence, and iterative deepening.
pub fn check_hou_search_extensions() -> Bool {
  // Deep imitation copies rigid structure under a binder,
  // keeping the bound variable; the standard template leaves
  // the body fresh.
  let u0 = unifier_new()
  let deep_rhs = ULam(
    UConst("Nat"),
    UPair(UApp(UConst("c"), UVar(0)), UApp(UConst("d"), UVar(0))),
  )
  match huet_imitation_template_deep(u0, deep_rhs, 0, 0) {
    Some(ULam(_, UPair(UApp(UConst("c"), UVar(0)), UApp(UConst("d"), UVar(0))))) =>
      ()
    _ => return false
  }
  match huet_imitation_template(u0, deep_rhs, 0, 0) {
    Some(ULam(_, UPair(_, _))) => return false
    _ => ()
  }
  // Projection cap: ?F (g x) (succ y) = ((g x) d1 d2 d3, succ y).
  // Imitation guesses the pair, but then the first coordinate's
  // fresh meta can only be solved by projecting its first formal
  // (the term `g x` itself) onto three fresh subgoals: plain
  // imitation there would need a subgoal equal to the bound
  // variable `x`, which no branch can produce.  So a projection
  // cap of 2 leaves the problem residual, while 3 solves it.
  let gx = UApp(UConst("g"), UVar(1))
  let sy = USucc(UVar(0))
  let proj_rhs = UPair(
    UApp(UApp(UApp(gx, UConst("d1")), UConst("d2")), UConst("d3")),
    sy,
  )
  let proj_problem = UMeta(0, [gx, sy])
  let u1 = unifier_new()
  ignore(hou_fresh_meta(u1, 0))
  let capped = hou_search_unify(
    proj_problem,
    proj_rhs,
    2,
    u1,
    max_projection_args=2,
  )
  if capped.status == HouSolved {
    return false
  }
  match u1.metas[0].solution {
    Some(_) => return false
    None => ()
  }
  let u2 = unifier_new()
  ignore(hou_fresh_meta(u2, 0))
  let uncapped = hou_search_unify(
    proj_problem,
    proj_rhs,
    2,
    u2,
    max_projection_args=3,
  )
  if uncapped.status != HouSolved ||
    hou_semantic_optimize(proj_problem, u2) != proj_rhs {
    return false
  }
  // Identification (white-box): it keeps the shared constant
  // argument, so the solution of ?F genuinely depends on its
  // second argument (a common-constant solution would not).
  // (Black-box search may find this equation through earlier
  // branches; here the identification branch itself is forced.)
  let u3 = unifier_new()
  ignore(hou_fresh_meta(u3, 0))
  ignore(hou_fresh_meta(u3, 0))
  let f_side = UMeta(0, [UVar(1), UConst("c")])
  let g_side = UMeta(1, [UConst("c"), UVar(0)])
  let id_state : Array[Int32] = [0, 0, 0, 2]
  let id_code = hou_search_identification(
    f_side,
    g_side,
    2,
    u3,
    id_state,
    1000,
    0,
    4,
    0,
    [UVar(1), UConst("c")],
    1,
    [UConst("c"), UVar(0)],
  )
  if id_code != 1 {
    return false
  }
  if hou_semantic_optimize(f_side, u3) != hou_semantic_optimize(g_side, u3) {
    return false
  }
  let f_at_c = hou_semantic_optimize(UMeta(0, [UVar(1), UConst("c")]), u3)
  let f_at_d = hou_semantic_optimize(UMeta(0, [UVar(1), UConst("d")]), u3)
  if f_at_c == f_at_d {
    return false
  }
  // And the equation is of course solvable by the full search.
  let u3b = unifier_new()
  ignore(hou_fresh_meta(u3b, 0))
  ignore(hou_fresh_meta(u3b, 0))
  if !hou_search_unify_bool(f_side, g_side, 2, u3b) {
    return false
  }
  // Iterative deepening finds the projection problem's shallow
  // solution and reports it; with the projection cap kept at 2
  // it exhausts the rounds transactionally.
  let u4 = unifier_new()
  ignore(hou_fresh_meta(u4, 0))
  let iterative = hou_search_unify_iterative(
    proj_problem,
    proj_rhs,
    2,
    u4,
    depth_cap=4,
    max_projection_args=3,
  )
  if iterative.solved_at_depth < 1 ||
    iterative.solved_at_depth > 3 ||
    iterative.rounds != iterative.solved_at_depth + 1 ||
    hou_semantic_optimize(proj_problem, u4) != proj_rhs {
    return false
  }
  let u5 = unifier_new()
  ignore(hou_fresh_meta(u5, 0))
  let exhausted = hou_search_unify_iterative(
    proj_problem,
    proj_rhs,
    2,
    u5,
    depth_cap=2,
    max_projection_args=2,
  )
  if exhausted.solved_at_depth != -1 || exhausted.rounds != 3 {
    return false
  }
  match u5.metas[0].solution {
    Some(_) => false
    None => u5.metas.length() == 1
  }
}

// ---------------------------------------------------------------------------
// Phase 13: a solver for MGU residual constraint sets.
//
// `hou_unify_mgu` deliberately stops at the boundary of the
// certified Miller-pattern fragment and returns the remaining
// equations.  The solver below treats such a residual set as a
// first-class problem: principal propagation is run to a fixed
// point; one residual equation at a time is handed to
// iterative-deepening Huet search; every successful specific
// assignment is followed by principal propagation over the
// whole original constraint set.  A search guess that makes a
// later principal constraint clash is therefore reported as
// residual, not as a false no-unifier verdict.  The solved
// outcome is always verified by comparing both sides of every
// original constraint under the final substitution.  General
// HOU remains undecidable: residual and budget outcomes retain
// the last sound partial substitution and say exactly what is
// left.
// ---------------------------------------------------------------------------

///|
pub struct HouResidualSolveReport {
  status : HouSearchStatus
  substitution : Array[(Int32, UTerm)]
  residual : Array[HouConstraint]
  initial_constraints : Int32
  solved_constraints : Int32
  search_rounds : Int32
  nodes : Int32
  branches_tried : Int32
  max_depth_reached : Int32
} derive(Debug, Eq)

///|
pub extend HouResidualSolveReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouResidualSolveReport with Eq::{not_equal, equal}

///|
fn hou_substitution_since(
  snapshot : Unifier,
  unifier : Unifier,
) -> Array[(Int32, UTerm)] {
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
  substitution
}

///|
fn hou_constraint_normalized(
  constraint : HouConstraint,
  unifier : Unifier,
) -> HouConstraint {
  HouConstraint::{
    lhs: hou_semantic_optimize(constraint.lhs, unifier),
    rhs: hou_semantic_optimize(constraint.rhs, unifier),
    depth: constraint.depth,
  }
}

///|
fn hou_constraints_normalized_unsolved(
  constraints : Array[HouConstraint],
  unifier : Unifier,
) -> Array[HouConstraint] {
  let out : Array[HouConstraint] = []
  for i in 0..<constraints.length() {
    let c = hou_constraint_normalized(constraints[i], unifier)
    if c.lhs != c.rhs {
      out.push(c)
    }
  }
  out
}

///|
/// Principal propagation to a fixed point.  Codes:
/// 1 = every constraint principal-solved, 0 = stable residual,
/// -1 = definitive clash, -2 = propagation round budget used.
fn hou_residual_propagate(
  constraints : Array[HouConstraint],
  unifier : Unifier,
  max_rounds : Int32,
) -> (Int32, Array[HouConstraint]) {
  let mut pending = hou_constraints_normalized_unsolved(constraints, unifier)
  let mut rounds = 0
  while pending.length() > 0 {
    if rounds >= max_rounds {
      return (-2, pending)
    }
    rounds = rounds + 1
    let progress_mark = unifier.solved_count + unifier.metas.length()
    let next : Array[HouConstraint] = []
    for i in 0..<pending.length() {
      let c = pending[i]
      let report = hou_unify_mgu(c.lhs, c.rhs, c.depth, unifier)
      match report.status {
        HouMguPrincipal => ()
        HouMguNoUnifier => return (-1, [])
        HouMguResidual =>
          for j in 0..<report.residual.length() {
            next.push(report.residual[j])
          }
      }
    }
    pending = hou_constraints_normalized_unsolved(next, unifier)
    if pending.length() == 0 {
      return (1, [])
    }
    let progress = unifier.solved_count + unifier.metas.length()
    if progress == progress_mark {
      return (0, pending)
    }
  }
  (1, [])
}

///|
fn hou_constraints_all_solved(
  constraints : Array[HouConstraint],
  unifier : Unifier,
) -> Bool {
  hou_constraints_normalized_unsolved(constraints, unifier).length() == 0
}

///|
/// Solve a set of higher-order constraints, typically the
/// `residual` field of `hou_unify_mgu`, by alternating principal
/// propagation with transactional iterative-deepening search.
/// On `HouSolved`, `unifier` contains a verified unifier of all
/// constraints.  On `HouNoUnifier`, the input unifier is
/// restored.  On residual/budget outcomes, the unifier retains
/// the last sound partial substitution reached before the failed
/// search attempt, and `residual` is normalized under it.  The
/// node/branch counters aggregate the final iterative round of
/// each attempted residual equation.
pub fn hou_solve_constraints(
  constraints : Array[HouConstraint],
  unifier : Unifier,
  max_nodes_per_round~ : Int32 = 1000,
  depth_cap~ : Int32 = 6,
  max_projection_args~ : Int32 = 2,
  max_rounds~ : Int32 = 64,
) -> HouResidualSolveReport {
  let initial = hou_clone_unifier(unifier)
  let round_budget = if max_rounds <= 0 { 1 } else { max_rounds }
  let mut search_rounds = 0
  let mut nodes = 0
  let mut branches = 0
  let mut max_depth = 0
  let mut solved_by_search = 0
  let (first_code, first_residual) = hou_residual_propagate(
    constraints, unifier, round_budget,
  )
  if first_code == -1 {
    hou_restore_unifier(unifier, initial)
    return HouResidualSolveReport::{
      status: HouNoUnifier,
      substitution: [],
      residual: [],
      initial_constraints: constraints.length(),
      solved_constraints: 0,
      search_rounds: 0,
      nodes: 0,
      branches_tried: 0,
      max_depth_reached: 0,
    }
  }
  if first_code == -2 {
    return HouResidualSolveReport::{
      status: HouBudgetExceeded,
      substitution: hou_substitution_since(initial, unifier),
      residual: first_residual,
      initial_constraints: constraints.length(),
      solved_constraints: constraints.length() - first_residual.length(),
      search_rounds: 0,
      nodes: 0,
      branches_tried: 0,
      max_depth_reached: 0,
    }
  }
  let mut residual = first_residual
  let mut attempts = 0
  while residual.length() > 0 {
    if attempts >= round_budget {
      return HouResidualSolveReport::{
        status: HouBudgetExceeded,
        substitution: hou_substitution_since(initial, unifier),
        residual,
        initial_constraints: constraints.length(),
        solved_constraints: solved_by_search,
        search_rounds,
        nodes,
        branches_tried: branches,
        max_depth_reached: max_depth,
      }
    }
    attempts = attempts + 1
    let before_search = hou_clone_unifier(unifier)
    let target = residual[0]
    let search = hou_search_unify_iterative(
      target.lhs,
      target.rhs,
      target.depth,
      unifier,
      max_nodes_per_round~,
      depth_cap~,
      max_projection_args~,
    )
    search_rounds = search_rounds + search.rounds
    nodes = nodes + search.report.nodes
    branches = branches + search.report.branches_tried
    if search.report.max_depth_reached > max_depth {
      max_depth = search.report.max_depth_reached
    }
    match search.report.status {
      HouSolved => {
        solved_by_search = solved_by_search + 1
        let (code, next_residual) = hou_residual_propagate(
          constraints, unifier, round_budget,
        )
        if code == -1 {
          // The specific guess is incompatible with another
          // constraint; another unifier of `target` might work.
          hou_restore_unifier(unifier, before_search)
          return HouResidualSolveReport::{
            status: HouResidual,
            substitution: hou_substitution_since(initial, unifier),
            residual,
            initial_constraints: constraints.length(),
            solved_constraints: solved_by_search - 1,
            search_rounds,
            nodes,
            branches_tried: branches,
            max_depth_reached: max_depth,
          }
        }
        if code == -2 {
          return HouResidualSolveReport::{
            status: HouBudgetExceeded,
            substitution: hou_substitution_since(initial, unifier),
            residual: next_residual,
            initial_constraints: constraints.length(),
            solved_constraints: solved_by_search,
            search_rounds,
            nodes,
            branches_tried: branches,
            max_depth_reached: max_depth,
          }
        }
        residual = next_residual
      }
      HouNoUnifier => {
        hou_restore_unifier(unifier, initial)
        return HouResidualSolveReport::{
          status: HouNoUnifier,
          substitution: [],
          residual: [],
          initial_constraints: constraints.length(),
          solved_constraints: 0,
          search_rounds,
          nodes,
          branches_tried: branches,
          max_depth_reached: max_depth,
        }
      }
      HouBudgetExceeded => {
        hou_restore_unifier(unifier, before_search)
        return HouResidualSolveReport::{
          status: HouBudgetExceeded,
          substitution: hou_substitution_since(initial, unifier),
          residual,
          initial_constraints: constraints.length(),
          solved_constraints: solved_by_search,
          search_rounds,
          nodes,
          branches_tried: branches,
          max_depth_reached: max_depth,
        }
      }
      HouResidual => {
        hou_restore_unifier(unifier, before_search)
        return HouResidualSolveReport::{
          status: HouResidual,
          substitution: hou_substitution_since(initial, unifier),
          residual,
          initial_constraints: constraints.length(),
          solved_constraints: solved_by_search,
          search_rounds,
          nodes,
          branches_tried: branches,
          max_depth_reached: max_depth,
        }
      }
    }
  }
  if !hou_constraints_all_solved(constraints, unifier) {
    // Propagation reported no residual but direct verification
    // disagrees: expose the discrepancy as residual rather than
    // claiming a solution.
    return HouResidualSolveReport::{
      status: HouResidual,
      substitution: hou_substitution_since(initial, unifier),
      residual: hou_constraints_normalized_unsolved(constraints, unifier),
      initial_constraints: constraints.length(),
      solved_constraints: solved_by_search,
      search_rounds,
      nodes,
      branches_tried: branches,
      max_depth_reached: max_depth,
    }
  }
  HouResidualSolveReport::{
    status: HouSolved,
    substitution: hou_substitution_since(initial, unifier),
    residual: [],
    initial_constraints: constraints.length(),
    solved_constraints: constraints.length(),
    search_rounds,
    nodes,
    branches_tried: branches,
    max_depth_reached: max_depth,
  }
}

///|
/// Solve one equation through the MGU/residual pipeline.  This is
/// the one-equation counterpart of `hou_solve_constraints`.
pub fn hou_unify_residual(
  a : UTerm,
  b : UTerm,
  depth : Int32,
  unifier : Unifier,
  max_nodes_per_round~ : Int32 = 1000,
  depth_cap~ : Int32 = 6,
  max_projection_args~ : Int32 = 2,
  max_rounds~ : Int32 = 64,
) -> HouResidualSolveReport {
  hou_solve_constraints(
    [HouConstraint::{ lhs: a, rhs: b, depth, }],
    unifier,
    max_nodes_per_round~,
    depth_cap~,
    max_projection_args~,
    max_rounds~,
  )
}

// ---------------------------------------------------------------------------
// Phase 14: Multi-constraint Huet backtracking solver & bounded complete
// normal-form unifier enumeration
// ---------------------------------------------------------------------------

///|
/// Report returned by bounded complete unifier enumeration (`hou_enumerate_unifiers`).
/// `solutions` contains pairwise-distinct substitutions normalized over the
/// initial metavariables; `search_exhausted` is `true` iff no branch hit the
/// depth/node/solution cap, certifying completeness within the Huet search tree.
pub(all) struct HouEnumerationReport {
  solutions : Array[Array[(Int32, UTerm)]]
  search_exhausted : Bool
  capped : Bool
  nodes : Int32
  branches_tried : Int32
  max_depth_reached : Int32
} derive(Debug, Eq)

///|
pub extend HouEnumerationReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouEnumerationReport with Eq::{not_equal, equal}

///|
fn hou_pick_branch_constraint(
  residual : Array[HouConstraint],
  unifier : Unifier,
) -> Int32 {
  // Prefer flex-rigid over flex-flex because flex-rigid branching is finite
  // and Huet-complete at fixed projection arity.
  for i in 0..<residual.length() {
    let c = residual[i]
    let la = meta_head_spine(c.lhs, unifier) != None
    let rb = meta_head_spine(c.rhs, unifier) != None
    if la != rb {
      return i
    }
  }
  0
}

///|
fn hou_contains_solution(
  solutions : Array[Array[(Int32, UTerm)]],
  cand : Array[(Int32, UTerm)],
) -> Bool {
  for s in solutions {
    if s == cand {
      return true
    }
  }
  false
}

///|
/// Candidate single-step metavariable assignments for a flexible equation
/// `(lhs, rhs)` at `depth` in `unifier`. Each thunk mutates `unifier` and
/// returns `true` when the assignment succeeded.
fn hou_flex_step_candidates(
  meta_id : Int32,
  args : Array[UTerm],
  other_side : UTerm,
  max_projection_args : Int32,
) -> Array[(Unifier) -> Bool] {
  let arity = args.length()
  let steps : Array[(Unifier) -> Bool] = []
  steps.push(u => {
    match huet_imitation_template(u, other_side, arity, 0) {
      Some(body) => huet_assign_solution(u, meta_id, body, arity)
      None => false
    }
  })
  steps.push(u => {
    let probe_u = hou_clone_unifier(u)
    let shallow = huet_imitation_template(probe_u, other_side, arity, 0)
    match huet_imitation_template_deep(u, other_side, arity, 0) {
      Some(body) =>
        if Some(body) != shallow {
          huet_assign_solution(u, meta_id, body, arity)
        } else {
          false
        }
      None => false
    }
  })
  let proj_limit = (if max_projection_args < 0 {
      0
    } else {
      max_projection_args
    }) +
    1
  for applied_args in 0..<proj_limit {
    for position in 0..<arity {
      let app_n = applied_args
      let pos_n = position
      steps.push(u => {
        let body = huet_projection_template(u, arity, pos_n, app_n)
        huet_assign_solution(u, meta_id, body, arity)
      })
    }
  }
  match other_side {
    ULam(_, _) =>
      steps.push(u => {
        let body = ULam(UConst("PatternDomain"), huet_fresh_over(u, arity, 1))
        huet_assign_solution(u, meta_id, body, arity)
      })
    _ => ()
  }
  if arity > 0 {
    steps.push(u => {
      let body = UMeta(hou_fresh_meta_id(u), [])
      huet_assign_solution(u, meta_id, body, arity)
    })
  }
  steps
}

///|
fn hou_multi_backtrack_dfs(
  all_constraints : Array[HouConstraint],
  initial : Unifier,
  unifier : Unifier,
  search_depth : Int32,
  max_depth : Int32,
  max_nodes : Int32,
  max_projection_args : Int32,
  round_budget : Int32,
  max_solutions : Int32,
  solutions : Array[Array[(Int32, UTerm)]],
  first_unifier_out : Array[Unifier],
  counters : Array[Int32], // [nodes, branches, max_depth_seen, incomplete_flag, capped_flag]
) -> Unit {
  if counters[4] != 0 {
    return
  }
  if counters[0] >= max_nodes {
    counters[3] = 1
    return
  }
  counters[0] = counters[0] + 1
  if search_depth > counters[2] {
    counters[2] = search_depth
  }
  let (code, residual) = hou_residual_propagate(
    all_constraints, unifier, round_budget,
  )
  if code == -1 {
    return
  }
  if code == -2 {
    counters[3] = 1
    return
  }
  if residual.length() == 0 {
    if hou_constraints_all_solved(all_constraints, unifier) {
      let sub = hou_substitution_since(initial, unifier)
      if !hou_contains_solution(solutions, sub) {
        if first_unifier_out.length() == 0 {
          first_unifier_out.push(hou_clone_unifier(unifier))
        }
        solutions.push(sub)
        if solutions.length() >= max_solutions {
          counters[4] = 1
        }
      }
    } else {
      counters[3] = 1
    }
    return
  }
  if search_depth >= max_depth {
    counters[3] = 1
    return
  }
  let idx = hou_pick_branch_constraint(residual, unifier)
  let eq = residual[idx]
  let lhs = uterm_whnf(eq.lhs, unifier)
  let rhs = uterm_whnf(eq.rhs, unifier)
  let a_head = meta_head_spine(lhs, unifier)
  let b_head = meta_head_spine(rhs, unifier)

  let run_step = (step : (Unifier) -> Bool) => {
    if counters[4] != 0 {
      return
    }
    let snap = hou_clone_unifier(unifier)
    counters[1] = counters[1] + 1
    if step(unifier) {
      hou_multi_backtrack_dfs(
        all_constraints,
        initial,
        unifier,
        search_depth + 1,
        max_depth,
        max_nodes,
        max_projection_args,
        round_budget,
        max_solutions,
        solutions,
        first_unifier_out,
        counters,
      )
    }
    hou_restore_unifier(unifier, snap)
  }

  match (a_head, b_head) {
    (Some((id_a, args_a)), None) =>
      for
        step in hou_flex_step_candidates(id_a, args_a, rhs, max_projection_args) {
        run_step(step)
      }
    (None, Some((id_b, args_b))) =>
      for
        step in hou_flex_step_candidates(id_b, args_b, lhs, max_projection_args) {
        run_step(step)
      }
    (Some((id_a, args_a)), Some((id_b, args_b))) => {
      if id_a == id_b && args_a.length() == args_b.length() {
        run_step(u => {
          let fixed : Array[Int32] = []
          for i in 0..<args_a.length() {
            let bp = hou_clone_unifier(u)
            if hou_unify(args_a[i], args_b[i], eq.depth, u) &&
              hou_semantic_optimize(args_a[i], u) ==
              hou_semantic_optimize(args_b[i], u) {
              fixed.push(i)
            } else {
              hou_restore_unifier(u, bp)
            }
          }
          let cid = hou_fresh_meta_id(u)
          let cargs : Array[UTerm] = []
          for pos in fixed {
            cargs.push(UVar(huet_formal_index(args_a.length(), 0, pos)))
          }
          huet_assign_solution(u, id_a, UMeta(cid, cargs), args_a.length())
        })
      }
      for
        step in hou_flex_step_candidates(id_a, args_a, rhs, max_projection_args) {
        run_step(step)
      }
      if id_a != id_b {
        for
          step in hou_flex_step_candidates(
            id_b, args_b, lhs, max_projection_args,
          ) {
          run_step(step)
        }
        run_step(u => {
          let cid = hou_fresh_meta_id(u)
          huet_assign_solution(u, id_a, UMeta(cid, []), args_a.length()) &&
          huet_assign_solution(u, id_b, UMeta(cid, []), args_b.length())
        })
      }
    }
    (None, None) =>
      // Rigid-rigid residual that failed `hou_unify` either needs eta/binder
      // decomposition or is a rigid clash; delegate one step to `hou_search_go`.
      run_step(u => {
        let st : Array[Int32] = [0, 0, 0, max_projection_args]
        hou_search_go(lhs, rhs, eq.depth, u, st, 64, 0, 2) == 1
      })
  }
}

///|
/// Bounded complete unifier enumeration modulo normal form over simultaneous
/// higher-order unification constraints. Leaves `unifier` unchanged.
pub fn hou_enumerate_unifiers(
  constraints : Array[HouConstraint],
  unifier : Unifier,
  max_solutions~ : Int32 = 16,
  max_nodes~ : Int32 = 2000,
  max_depth~ : Int32 = 4,
  max_projection_args~ : Int32 = 2,
  round_budget~ : Int32 = 64,
) -> HouEnumerationReport {
  let initial = hou_clone_unifier(unifier)
  let work = hou_clone_unifier(unifier)
  let solutions : Array[Array[(Int32, UTerm)]] = []
  let first_out : Array[Unifier] = []
  let counters : Array[Int32] = [0, 0, 0, 0, 0]
  if max_solutions > 0 && max_nodes > 0 {
    hou_multi_backtrack_dfs(
      constraints, initial, work, 0, max_depth, max_nodes, max_projection_args, round_budget,
      max_solutions, solutions, first_out, counters,
    )
  } else {
    counters[3] = 1
  }
  let capped = counters[4] != 0
  HouEnumerationReport::{
    solutions,
    search_exhausted: counters[3] == 0 && !capped,
    capped,
    nodes: counters[0],
    branches_tried: counters[1],
    max_depth_reached: counters[2],
  }
}

///|
/// Solve a system of higher-order unification constraints with full
/// cross-constraint backtracking: when one Huet unifier of an earlier residual
/// equation clashes with a later equation, search backtracks to alternative
/// imitation/projection unifiers until a joint solution is found.
pub fn hou_solve_constraints_backtracking(
  constraints : Array[HouConstraint],
  unifier : Unifier,
  max_nodes~ : Int32 = 2000,
  max_depth~ : Int32 = 5,
  max_projection_args~ : Int32 = 2,
  round_budget~ : Int32 = 64,
) -> HouResidualSolveReport {
  let initial = hou_clone_unifier(unifier)
  let work = hou_clone_unifier(unifier)
  let solutions : Array[Array[(Int32, UTerm)]] = []
  let first_out : Array[Unifier] = []
  let counters : Array[Int32] = [0, 0, 0, 0, 0]
  if max_nodes > 0 {
    hou_multi_backtrack_dfs(
      constraints, initial, work, 0, max_depth, max_nodes, max_projection_args, round_budget,
      1, solutions, first_out, counters,
    )
  } else {
    counters[3] = 1
  }
  if first_out.length() > 0 {
    hou_restore_unifier(unifier, first_out[0])
    return HouResidualSolveReport::{
      status: HouSolved,
      substitution: solutions[0],
      residual: [],
      initial_constraints: constraints.length(),
      solved_constraints: constraints.length(),
      search_rounds: 1,
      nodes: counters[0],
      branches_tried: counters[1],
      max_depth_reached: counters[2],
    }
  }
  hou_restore_unifier(unifier, initial)
  let (_, rem) = hou_residual_propagate(
    constraints,
    hou_clone_unifier(initial),
    round_budget,
  )
  let status = if counters[0] >= max_nodes {
    HouBudgetExceeded
  } else if counters[3] == 0 {
    HouNoUnifier
  } else {
    HouResidual
  }
  HouResidualSolveReport::{
    status,
    substitution: [],
    residual: rem,
    initial_constraints: constraints.length(),
    solved_constraints: 0,
    search_rounds: 1,
    nodes: counters[0],
    branches_tried: counters[1],
    max_depth_reached: counters[2],
  }
}

// ===========================================================================
// Phase 16 (Track 6A): Huet Delayed Flex-Flex Constraint Graph &
// Pull-Based Lazy Stream Unifier Iterator
// ===========================================================================

///|
/// Suspended flex-flex constraint `?F a_1 ... a_m = ?G b_1 ... b_n` held in the
/// metavariable-indexed delayed constraint graph until either `?F` or `?G`
/// becomes instantiated to a rigid head.
pub struct HouFlexFlexEdge {
  lhs_meta : Int32
  lhs_arity : Int32
  lhs : UTerm
  rhs_meta : Int32
  rhs_arity : Int32
  rhs : UTerm
  depth : Int32
} derive(Debug, Eq)

///|
pub extend HouFlexFlexEdge with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouFlexFlexEdge with Eq::{not_equal, equal}

///|
pub enum HouDelayedSolveStatus {
  HouDelayedSolved
  HouDelayedPreUnifier
  HouDelayedNoUnifier
  HouDelayedBudgetExceeded
} derive(Debug, Eq)

///|
pub extend HouDelayedSolveStatus with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouDelayedSolveStatus with Eq::{not_equal, equal}

///|
pub struct HouDelayedGraphReport {
  status : HouDelayedSolveStatus
  substitution : Array[(Int32, UTerm)]
  delayed_edges : Array[HouFlexFlexEdge]
  woke_edges : Int32
  nodes : Int32
  branches_tried : Int32
} derive(Debug, Eq)

///|
pub extend HouDelayedGraphReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HouDelayedGraphReport with Eq::{not_equal, equal}

///|
fn hou_partition_flex_flex_graph(
  residual : Array[HouConstraint],
  unifier : Unifier,
) -> (Array[HouConstraint], Array[HouFlexFlexEdge]) {
  let active_rigid : Array[HouConstraint] = []
  let flex_edges : Array[HouFlexFlexEdge] = []
  for eq in residual {
    let lhs = uterm_whnf(eq.lhs, unifier)
    let rhs = uterm_whnf(eq.rhs, unifier)
    if hou_semantic_optimize(lhs, unifier) ==
      hou_semantic_optimize(rhs, unifier) {
      continue
    }
    match (meta_head_spine(lhs, unifier), meta_head_spine(rhs, unifier)) {
      (Some((id_a, args_a)), Some((id_b, args_b))) =>
        flex_edges.push(HouFlexFlexEdge::{
          lhs_meta: id_a,
          lhs_arity: args_a.length(),
          lhs,
          rhs_meta: id_b,
          rhs_arity: args_b.length(),
          rhs,
          depth: eq.depth,
        })
      _ => active_rigid.push(eq)
    }
  }
  (active_rigid, flex_edges)
}

///|
/// Constructively materialize Huet's canonical constant-projection unifier for
/// a delayed flex-flex graph: connected components of unsolved head metas
/// `?F ~ ?G` are unified via union-find and mapped to `\x_1 ... x_k => ?Z_c`
/// so every suspended flex-flex equation becomes judgementally identical.
pub fn hou_reify_delayed_flex_flex(
  unifier : Unifier,
  edges : Array[HouFlexFlexEdge],
) -> Bool {
  if edges.length() == 0 {
    return true
  }
  let metas : Array[Int32] = []
  let arities : Array[Int32] = []
  let find_or_add = (m : Int32, ar : Int32) => {
    for i in 0..<metas.length() {
      if metas[i] == m {
        if ar > arities[i] {
          arities[i] = ar
        }
        return i
      }
    }
    let idx = metas.length()
    metas.push(m)
    arities.push(ar)
    idx
  }
  for e in edges {
    ignore(find_or_add(e.lhs_meta, e.lhs_arity))
    ignore(find_or_add(e.rhs_meta, e.rhs_arity))
  }
  let n = metas.length()
  let parent : Array[Int32] = Array::makei(n, i => i)
  let uf_find = (x0 : Int32) => {
    let mut x = x0
    while parent[x] != x {
      parent[x] = parent[parent[x]]
      x = parent[x]
    }
    x
  }
  for e in edges {
    let ia = find_or_add(e.lhs_meta, e.lhs_arity)
    let ib = find_or_add(e.rhs_meta, e.rhs_arity)
    let ra = uf_find(ia)
    let rb = uf_find(ib)
    if ra != rb {
      parent[rb] = ra
    }
  }
  let comp_fresh : Array[Int32] = Array::make(n, -1)
  for i in 0..<n {
    let root = uf_find(i)
    if comp_fresh[root] < 0 {
      comp_fresh[root] = hou_fresh_meta_id(unifier)
    }
  }
  for i in 0..<n {
    let m = metas[i]
    let cur = uterm_whnf(UMeta(m, []), unifier)
    match meta_head_spine(cur, unifier) {
      Some((hm, _)) if hm == m => {
        let root = uf_find(i)
        let zid = comp_fresh[root]
        if !huet_assign_solution(unifier, m, UMeta(zid, []), arities[i]) {
          return false
        }
      }
      _ => ()
    }
  }
  true
}

///|
fn hou_delayed_dfs(
  all_constraints : Array[HouConstraint],
  unifier : Unifier,
  prev_delayed : Array[HouFlexFlexEdge],
  depth : Int32,
  max_depth : Int32,
  max_nodes : Int32,
  max_projection_args : Int32,
  round_budget : Int32,
  out_unifier : Array[Unifier],
  out_edges : Array[Array[HouFlexFlexEdge]],
  stats : Array[Int32], // [nodes, branches, woke_edges, incomplete_flag]
) -> Bool {
  if stats[0] >= max_nodes {
    stats[3] = 1
    return false
  }
  stats[0] = stats[0] + 1
  let (code, residual) = hou_residual_propagate(
    all_constraints, unifier, round_budget,
  )
  if code == -1 {
    return false
  }
  if code == -2 {
    stats[3] = 1
    return false
  }
  let (active_rigid, flex_edges) = hou_partition_flex_flex_graph(
    residual, unifier,
  )
  // Count previously delayed flex-flex edges whose head(s) woke up into rigid
  // or solved equations after the latest metavariable assignment.
  for pe in prev_delayed {
    let mut still_flex = false
    for fe in flex_edges {
      if fe.lhs_meta == pe.lhs_meta && fe.rhs_meta == pe.rhs_meta {
        still_flex = true
        break
      }
    }
    if !still_flex {
      stats[2] = stats[2] + 1
    }
  }
  if active_rigid.length() == 0 {
    out_unifier.push(hou_clone_unifier(unifier))
    out_edges.push(flex_edges)
    return true
  }
  if depth >= max_depth {
    stats[3] = 1
    return false
  }
  let eq = active_rigid[0]
  let lhs = uterm_whnf(eq.lhs, unifier)
  let rhs = uterm_whnf(eq.rhs, unifier)
  let steps : Array[(Unifier) -> Bool] = match
    (meta_head_spine(lhs, unifier), meta_head_spine(rhs, unifier)) {
    (Some((id_a, args_a)), None) =>
      hou_flex_step_candidates(id_a, args_a, rhs, max_projection_args)
    (None, Some((id_b, args_b))) =>
      hou_flex_step_candidates(id_b, args_b, lhs, max_projection_args)
    _ =>
      [
        u => {
          let st : Array[Int32] = [0, 0, 0, max_projection_args]
          hou_search_go(lhs, rhs, eq.depth, u, st, 64, 0, 2) == 1
        },
      ]
  }
  for step in steps {
    let snap = hou_clone_unifier(unifier)
    stats[1] = stats[1] + 1
    if step(unifier) {
      if hou_delayed_dfs(
          all_constraints,
          unifier,
          flex_edges,
          depth + 1,
          max_depth,
          max_nodes,
          max_projection_args,
          round_budget,
          out_unifier,
          out_edges,
          stats,
        ) {
        return true
      }
    }
    hou_restore_unifier(unifier, snap)
  }
  false
}

///|
/// Huet pre-unification solver with metavariable-indexed delayed flex-flex
/// constraint suspension:
/// - Suspends all flex-flex equations without branching on them;
/// - Automatically wakes delayed edges whenever a flex-rigid assignment
///   instantiates either endpoint;
/// - Returns `HouDelayedPreUnifier` with the suspended `HouFlexFlexEdge` graph
///   when `reify_flex_flex == false` (and `delayed_edges` is non-empty), or
///   reifies a concrete closed unifier (`HouDelayedSolved`) when
///   `reify_flex_flex == true`.
pub fn hou_solve_with_delayed_flex_flex(
  constraints : Array[HouConstraint],
  unifier : Unifier,
  reify_flex_flex~ : Bool = false,
  max_nodes~ : Int32 = 2000,
  max_depth~ : Int32 = 5,
  max_projection_args~ : Int32 = 2,
  round_budget~ : Int32 = 64,
) -> HouDelayedGraphReport {
  let initial = hou_clone_unifier(unifier)
  let work = hou_clone_unifier(unifier)
  let out_u : Array[Unifier] = []
  let out_edges : Array[Array[HouFlexFlexEdge]] = []
  let stats : Array[Int32] = [0, 0, 0, 0]
  let found = if max_nodes > 0 {
    hou_delayed_dfs(
      constraints,
      work,
      [],
      0,
      max_depth,
      max_nodes,
      max_projection_args,
      round_budget,
      out_u,
      out_edges,
      stats,
    )
  } else {
    stats[3] = 1
    false
  }
  if found && out_u.length() > 0 {
    let solved_u = out_u[0]
    let edges = out_edges[0]
    if edges.length() == 0 {
      hou_restore_unifier(unifier, solved_u)
      return HouDelayedGraphReport::{
        status: HouDelayedSolved,
        substitution: hou_substitution_since(initial, solved_u),
        delayed_edges: [],
        woke_edges: stats[2],
        nodes: stats[0],
        branches_tried: stats[1],
      }
    }
    if reify_flex_flex {
      let reified_u = hou_clone_unifier(solved_u)
      if hou_reify_delayed_flex_flex(reified_u, edges) &&
        hou_constraints_all_solved(constraints, reified_u) {
        hou_restore_unifier(unifier, reified_u)
        return HouDelayedGraphReport::{
          status: HouDelayedSolved,
          substitution: hou_substitution_since(initial, reified_u),
          delayed_edges: [],
          woke_edges: stats[2],
          nodes: stats[0],
          branches_tried: stats[1],
        }
      }
    }
    hou_restore_unifier(unifier, solved_u)
    return HouDelayedGraphReport::{
      status: HouDelayedPreUnifier,
      substitution: hou_substitution_since(initial, solved_u),
      delayed_edges: edges,
      woke_edges: stats[2],
      nodes: stats[0],
      branches_tried: stats[1],
    }
  }
  hou_restore_unifier(unifier, initial)
  let status = if stats[0] >= max_nodes || stats[3] != 0 {
    HouDelayedBudgetExceeded
  } else {
    HouDelayedNoUnifier
  }
  HouDelayedGraphReport::{
    status,
    substitution: [],
    delayed_edges: [],
    woke_edges: stats[2],
    nodes: stats[0],
    branches_tried: stats[1],
  }
}

///|
struct HouStreamFrame {
  snapshot : Unifier
  depth : Int32
  steps : Array[(Unifier) -> Bool]
  mut step_idx : Int32
}

///|
/// Pull-based lazy stream iterator over normal-form higher-order unifiers:
/// maintains an explicit resumable DFS stack so each `hou_unifier_stream_next`
/// expands only the search prefix needed to yield the next solution.
pub struct HouLazyUnifierStream {
  constraints : Array[HouConstraint]
  initial : Unifier
  stack : Array[HouStreamFrame]
  emitted : Array[Array[(Int32, UTerm)]]
  max_nodes : Int32
  max_depth : Int32
  max_projection_args : Int32
  round_budget : Int32
  reify_flex_flex : Bool
  mut root_started : Bool
  mut exhausted : Bool
  mut nodes_expanded : Int32
}

///|
pub fn hou_unifier_stream_new(
  constraints : Array[HouConstraint],
  unifier : Unifier,
  max_nodes~ : Int32 = 2000,
  max_depth~ : Int32 = 4,
  max_projection_args~ : Int32 = 2,
  round_budget~ : Int32 = 64,
  reify_flex_flex~ : Bool = true,
) -> HouLazyUnifierStream {
  HouLazyUnifierStream::{
    constraints,
    initial: hou_clone_unifier(unifier),
    stack: [],
    emitted: [],
    max_nodes,
    max_depth,
    max_projection_args,
    round_budget,
    reify_flex_flex,
    root_started: false,
    exhausted: max_nodes <= 0,
    nodes_expanded: 0,
  }
}

///|
pub fn hou_unifier_stream_is_exhausted(stream : HouLazyUnifierStream) -> Bool {
  stream.exhausted
}

///|
pub fn hou_unifier_stream_nodes(stream : HouLazyUnifierStream) -> Int32 {
  stream.nodes_expanded
}

///|
fn hou_stream_candidate_steps(
  eq : HouConstraint,
  unifier : Unifier,
  max_projection_args : Int32,
) -> Array[(Unifier) -> Bool] {
  let lhs = uterm_whnf(eq.lhs, unifier)
  let rhs = uterm_whnf(eq.rhs, unifier)
  match (meta_head_spine(lhs, unifier), meta_head_spine(rhs, unifier)) {
    (Some((id_a, args_a)), None) =>
      hou_flex_step_candidates(id_a, args_a, rhs, max_projection_args)
    (None, Some((id_b, args_b))) =>
      hou_flex_step_candidates(id_b, args_b, lhs, max_projection_args)
    (Some((id_a, args_a)), Some((id_b, args_b))) => {
      let out : Array[(Unifier) -> Bool] = []
      if id_a == id_b && args_a.length() == args_b.length() {
        out.push(u => {
          let fixed : Array[Int32] = []
          for i in 0..<args_a.length() {
            let bp = hou_clone_unifier(u)
            if hou_unify(args_a[i], args_b[i], eq.depth, u) &&
              hou_semantic_optimize(args_a[i], u) ==
              hou_semantic_optimize(args_b[i], u) {
              fixed.push(i)
            } else {
              hou_restore_unifier(u, bp)
            }
          }
          let cid = hou_fresh_meta_id(u)
          let cargs : Array[UTerm] = []
          for pos in fixed {
            cargs.push(UVar(huet_formal_index(args_a.length(), 0, pos)))
          }
          huet_assign_solution(u, id_a, UMeta(cid, cargs), args_a.length())
        })
      }
      for s in hou_flex_step_candidates(id_a, args_a, rhs, max_projection_args) {
        out.push(s)
      }
      if id_a != id_b {
        for
          s in hou_flex_step_candidates(id_b, args_b, lhs, max_projection_args) {
          out.push(s)
        }
        out.push(u => {
          let cid = hou_fresh_meta_id(u)
          huet_assign_solution(u, id_a, UMeta(cid, []), args_a.length()) &&
          huet_assign_solution(u, id_b, UMeta(cid, []), args_b.length())
        })
      }
      out
    }
    (None, None) =>
      [
        u => {
          let st : Array[Int32] = [0, 0, 0, max_projection_args]
          hou_search_go(lhs, rhs, eq.depth, u, st, 64, 0, 2) == 1
        },
      ]
  }
}

///|
fn hou_stream_visit_node(
  stream : HouLazyUnifierStream,
  u : Unifier,
  depth : Int32,
) -> Array[(Int32, UTerm)]? {
  if stream.nodes_expanded >= stream.max_nodes {
    stream.stack.clear()
    stream.exhausted = true
    return None
  }
  stream.nodes_expanded = stream.nodes_expanded + 1
  let (code, residual) = hou_residual_propagate(
    stream.constraints,
    u,
    stream.round_budget,
  )
  if code < 0 {
    return None
  }
  if residual.length() == 0 {
    if hou_constraints_all_solved(stream.constraints, u) {
      let sub = hou_substitution_since(stream.initial, u)
      if !hou_contains_solution(stream.emitted, sub) {
        stream.emitted.push(sub)
        return Some(sub)
      }
    }
    return None
  }
  let (active_rigid, flex_edges) = hou_partition_flex_flex_graph(residual, u)
  if active_rigid.length() == 0 && stream.reify_flex_flex {
    let reified = hou_clone_unifier(u)
    if hou_reify_delayed_flex_flex(reified, flex_edges) &&
      hou_constraints_all_solved(stream.constraints, reified) {
      let sub = hou_substitution_since(stream.initial, reified)
      if !hou_contains_solution(stream.emitted, sub) {
        stream.emitted.push(sub)
        return Some(sub)
      }
    }
    return None
  }
  if depth < stream.max_depth {
    let idx = hou_pick_branch_constraint(residual, u)
    let steps = hou_stream_candidate_steps(
      residual[idx],
      u,
      stream.max_projection_args,
    )
    if steps.length() > 0 {
      stream.stack.push(HouStreamFrame::{
        snapshot: hou_clone_unifier(u),
        depth,
        steps,
        step_idx: 0,
      })
    }
  }
  None
}

///|
/// Pull the next distinct normal-form higher-order unifier from `stream`,
/// returning `None` once the search tree (or `max_nodes` budget) is exhausted.
pub fn hou_unifier_stream_next(
  stream : HouLazyUnifierStream,
) -> Array[(Int32, UTerm)]? {
  if stream.exhausted {
    return None
  }
  if !stream.root_started {
    stream.root_started = true
    let root_u = hou_clone_unifier(stream.initial)
    match hou_stream_visit_node(stream, root_u, 0) {
      Some(sol) => {
        if stream.stack.length() == 0 {
          stream.exhausted = true
        }
        return Some(sol)
      }
      None => ()
    }
  }
  while stream.stack.length() > 0 {
    let top_idx = stream.stack.length() - 1
    let frame = stream.stack[top_idx]
    if frame.step_idx >= frame.steps.length() {
      ignore(stream.stack.pop())
      continue
    }
    let s_idx = frame.step_idx
    frame.step_idx = s_idx + 1
    let step = frame.steps[s_idx]
    let child_u = hou_clone_unifier(frame.snapshot)
    let next_depth = frame.depth + 1
    if step(child_u) {
      match hou_stream_visit_node(stream, child_u, next_depth) {
        Some(sol) => {
          if stream.stack.length() == 0 {
            stream.exhausted = true
          }
          return Some(sol)
        }
        None => ()
      }
    }
  }
  stream.exhausted = true
  None
}
