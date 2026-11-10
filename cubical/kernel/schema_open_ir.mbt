///|
fn sim_joint_tuple_type(cods : Array[DTerm]) -> DTerm {
  if cods.length() == 0 {
    return DUnitTy
  }
  let mut acc = cods[cods.length() - 1]
  let mut i = cods.length() - 2
  while i >= 0 {
    acc = DSigma(cods[i], dterm_shift(acc, 0, 1))
    i = i - 1
  }
  acc
}

///|
fn sim_joint_tuple_intro(vals : Array[DTerm]) -> DTerm {
  if vals.length() == 0 {
    return DUnitLit
  }
  let mut acc = vals[vals.length() - 1]
  let mut i = vals.length() - 2
  while i >= 0 {
    acc = DPair(vals[i], acc)
    i = i - 1
  }
  acc
}

///|
fn sim_joint_tuple_proj(tup : DTerm, idx : Int32, count : Int32) -> DTerm {
  if count <= 1 {
    return tup
  }
  let mut cur = tup
  for _s in 0..<idx {
    cur = DSnd(cur)
  }
  if idx < count - 1 {
    DFst(cur)
  } else {
    cur
  }
}

///|
/// Rewrite a function's `result_type` (in scope `params, indices, code`)
/// at arbitrary index terms and scrutinee `code_term` in context `total`
/// whose leading positions `0..<param_count` are the base parameters.
fn sim_general_result_type_at(
  spec : DSimultaneousIRSpec,
  g : Int32,
  indices : Array[DTerm],
  code_term : DTerm,
  total : Int32,
) -> DTerm {
  let pc = spec.base.params.length()
  let ic = spec.base.indices.length()
  let src_len = pc + ic + 1
  dterm_map_vars_at(spec.functions[g].result_type, 0, (v, depth) => {
    if v < depth {
      DTVar(v)
    } else {
      let pos = src_len - 1 - (v - depth)
      if pos < 0 || pos >= src_len {
        DTVar(v)
      } else if pos < pc {
        DTVar(total - 1 - pos + depth)
      } else if pos < pc + ic {
        let j = pos - pc
        if j < indices.length() {
          dterm_shift(indices[j], 0, depth)
        } else {
          DTVar(v)
        }
      } else {
        dterm_shift(code_term, 0, depth)
      }
    }
  })
}

///|
fn sim_joint_result_type_at(
  spec : DSimultaneousIRSpec,
  indices : Array[DTerm],
  code_term : DTerm,
  total : Int32,
) -> DTerm {
  let cods : Array[DTerm] = []
  for g in 0..<spec.functions.length() {
    cods.push(sim_general_result_type_at(spec, g, indices, code_term, total))
  }
  sim_joint_tuple_type(cods)
}

///|
/// General dependent Pi type of compiled function `function_index` in a
/// simultaneous block (supporting both universe-valued and arbitrary
/// small/dependent codomains `result_type` at level `<= base.level`).
pub fn simultaneous_ir_general_eliminator_type(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
) -> DTerm? {
  if function_index < 0 || function_index >= spec.functions.length() {
    return None
  }
  let base = spec.base
  let pc = base.params.length()
  let ic = base.indices.length()
  let outer = pc + ic
  let code_ty = DInductive(
    base,
    sim_elim_vars_at(outer, sim_elim_positions(pc + ic, 0)),
  )
  let mut ty = DPi(code_ty, spec.functions[function_index].result_type)
  let mut j = ic - 1
  while j >= 0 {
    ty = DPi(base.indices[j].ty, ty)
    j = j - 1
  }
  let mut p = pc - 1
  while p >= 0 {
    ty = DPi(base.params[p].ty, ty)
    p = p - 1
  }
  Some(ty)
}

///|
fn sim_joint_motive(spec : DSimultaneousIRSpec) -> DTerm {
  let base = spec.base
  let pc = base.params.length()
  let ic = base.indices.length()
  let outer = pc + ic + 1
  let scrut_total = outer + ic
  let scrut_args : Array[DTerm] = []
  for p in 0..<pc {
    scrut_args.push(DTVar(scrut_total - 1 - p))
  }
  for t in 0..<ic {
    scrut_args.push(DTVar(ic - 1 - t))
  }
  let motive_total = scrut_total + 1
  let idx_terms : Array[DTerm] = []
  for t in 0..<ic {
    idx_terms.push(DTVar(ic - t))
  }
  let body = sim_joint_result_type_at(spec, idx_terms, DTVar(0), motive_total)
  let mut motive = DLam(DInductive(base, scrut_args), body)
  let mut j = ic - 1
  while j >= 0 {
    let target_pos : Array[Int32] = []
    for p in 0..<pc {
      target_pos.push(p)
    }
    for t in 0..<j {
      target_pos.push(outer + t)
    }
    let dom = sim_elim_rewrite(
      base.indices[j].ty,
      pc + j,
      target_pos,
      outer + j,
    )
    motive = DLam(dom, motive)
    j = j - 1
  }
  motive
}

///|
/// Compute the minimum cumulative universe level `>= spec.base.level`
/// inhabited by every function's `result_type` in `spec` (supporting
/// arbitrarily large universe codomains `codomain_level > base.level`).
pub fn simultaneous_ir_joint_motive_level(spec : DSimultaneousIRSpec) -> Int32 {
  let base = spec.base
  let param_values = schema_fresh_values(base.params.length(), 13000)
  let param_types = inductive_param_types(base, param_values)
  let index_values = schema_fresh_values(base.indices.length(), 13040)
  let index_types : Array[DValue] = []
  let prior_values : Array[DValue] = []
  for j in 0..<base.indices.length() {
    index_types.push(
      telescope_next_type(
        base.indices,
        param_types,
        param_values,
        index_types,
        prior_values,
      ),
    )
    prior_values.push(index_values[j])
  }
  let code_value : DValue = DVNeutral(DNVar(13080))
  let mut ctx = denv_empty()
  let mut env = denv_empty()
  for i in 0..<param_types.length() {
    ctx = denv_cons(param_types[i], ctx)
    env = denv_cons(param_values[i], env)
  }
  for i in 0..<index_types.length() {
    ctx = denv_cons(index_types[i], ctx)
    env = denv_cons(index_values[i], env)
  }
  ctx = denv_cons(DVInductive(base, param_values, index_values), ctx)
  env = denv_cons(code_value, env)
  let mut max_lvl = base.level
  for fi in 0..<spec.functions.length() {
    match d_as_type(spec.functions[fi].result_type, ctx, env, ddim_empty()) {
      Some(tv) => if tv.level > max_lvl { max_lvl = tv.level }
      None => return -1
    }
  }
  max_lvl
}

///|
/// General bundle type `All_F(M)` for either a single function `g >= 0`
/// or the joint `Σ`-tuple motive (`g == -1`).
fn sim_general_bundle_type_term(
  spec : DSimultaneousIRSpec,
  joint_level : Int32,
  g : Int32,
  functor : DPositiveFunctor,
  value : DTerm,
  target_pos : Array[Int32],
  total : Int32,
) -> DTerm? {
  let base = spec.base
  match functor {
    DFunctorIdentity(index) => {
      let idx = sim_elim_rewrite_all(index, target_pos, total)
      if g < 0 {
        Some(sim_joint_result_type_at(spec, idx, value, total))
      } else {
        Some(sim_general_result_type_at(spec, g, idx, value, total))
      }
    }
    DFunctorConst(_) => Some(DUnitTy)
    DFunctorProduct(a, b) =>
      match
        (
          sim_general_bundle_type_term(
            spec,
            joint_level,
            g,
            a,
            DFst(value),
            target_pos,
            total,
          ),
          sim_general_bundle_type_term(
            spec,
            joint_level,
            g,
            b,
            DSnd(value),
            target_pos,
            total,
          ),
        ) {
        (Some(ta), Some(tb)) => Some(DSigma(ta, dterm_shift(tb, 0, 1)))
        _ => None
      }
    DFunctorSigma(a, b) => {
      let ta = match sim_elim_functor_type_term(base, a, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let tp2 = sim_elim_extend_pos(target_pos, total)
      let shifted = dterm_shift(value, 0, 1)
      let first = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          a,
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let second = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          b,
          DSnd(shifted),
          tp2,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      Some(
        DApp(DLam(ta, DSigma(first, dterm_shift(second, 0, 1))), DFst(value)),
      )
    }
    DFunctorPi(dom, inner) => {
      let tb = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          inner,
          DApp(dterm_shift(value, 0, 1), DTVar(0)),
          sim_elim_extend_pos(target_pos, total),
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      Some(
        DPi(sim_elim_rewrite(dom, target_pos.length(), target_pos, total), tb),
      )
    }
    DFunctorContainer(shape, positions, index) => {
      let shape_t = sim_elim_rewrite(
        shape,
        target_pos.length(),
        target_pos,
        total,
      )
      let tp2 = sim_elim_extend_pos(target_pos, total)
      let pos_t = sim_elim_rewrite(positions, tp2.length(), tp2, total + 1)
      let tp3 = sim_elim_extend_pos(tp2, total + 1)
      let idx = sim_elim_rewrite_all(index, tp3, total + 2)
      let leaf_val = DApp(DSnd(dterm_shift(value, 0, 2)), DTVar(0))
      let leaf_ty = if g < 0 {
        sim_joint_result_type_at(spec, idx, leaf_val, total + 2)
      } else {
        sim_general_result_type_at(spec, g, idx, leaf_val, total + 2)
      }
      Some(DApp(DLam(shape_t, DPi(pos_t, leaf_ty)), DFst(value)))
    }
    DFunctorSum(a, b) =>
      match
        (
          sim_general_bundle_type_term(
            spec,
            joint_level,
            g,
            a,
            DSnd(value),
            target_pos,
            total,
          ),
          sim_general_bundle_type_term(
            spec,
            joint_level,
            g,
            b,
            DSnd(value),
            target_pos,
            total,
          ),
        ) {
        (Some(ta), Some(tb)) =>
          Some(DBoolElim(DUniv(joint_level), ta, tb, DFst(value)))
        _ => None
      }
    DFunctorList(inner) => {
      let elem = match
        sim_elim_functor_type_term(base, inner, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let head_ty = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          inner,
          DTVar(2),
          target_pos,
          total + 3,
        ) {
        Some(v) => v
        None => return None
      }
      let step = DLam(
        elem,
        DLam(
          DListTy(dterm_shift(elem, 0, 1)),
          DLam(DUniv(joint_level), DSigma(head_ty, DTVar(1))),
        ),
      )
      Some(DListElim(DUniv(joint_level), DUnitTy, step, value))
    }
    DFunctorFamily(_) | DFunctorSelfFamily(_) => None
  }
}

///|
/// Project the `g`-th induction hypothesis bundle `All_F(M_g)(arg_val)`
/// out of the single joint bundle `joint_ih : All_F(M_joint)(arg_val)`.
fn sim_joint_project_bundle(
  spec : DSimultaneousIRSpec,
  joint_level : Int32,
  g : Int32,
  functor : DPositiveFunctor,
  arg_val : DTerm,
  joint_ih : DTerm,
  target_pos : Array[Int32],
  total : Int32,
) -> DTerm? {
  let base = spec.base
  let k = spec.functions.length()
  match functor {
    DFunctorIdentity(_) => Some(sim_joint_tuple_proj(joint_ih, g, k))
    DFunctorConst(_) => Some(DUnitLit)
    DFunctorProduct(a, b) =>
      match
        (
          sim_joint_project_bundle(
            spec,
            joint_level,
            g,
            a,
            DFst(arg_val),
            DFst(joint_ih),
            target_pos,
            total,
          ),
          sim_joint_project_bundle(
            spec,
            joint_level,
            g,
            b,
            DSnd(arg_val),
            DSnd(joint_ih),
            target_pos,
            total,
          ),
        ) {
        (Some(pa), Some(pb)) => Some(DPair(pa, pb))
        _ => None
      }
    DFunctorSigma(a, b) => {
      let ta = match sim_elim_functor_type_term(base, a, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let tp2 = sim_elim_extend_pos(target_pos, total)
      let s_arg = dterm_shift(arg_val, 0, 1)
      let s_ih = dterm_shift(joint_ih, 0, 1)
      let p1 = match
        sim_joint_project_bundle(
          spec,
          joint_level,
          g,
          a,
          DTVar(0),
          DFst(s_ih),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let p2 = match
        sim_joint_project_bundle(
          spec,
          joint_level,
          g,
          b,
          DSnd(s_arg),
          DSnd(s_ih),
          tp2,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      Some(DApp(DLam(ta, DPair(p1, p2)), DFst(arg_val)))
    }
    DFunctorPi(dom, inner) => {
      let body = match
        sim_joint_project_bundle(
          spec,
          joint_level,
          g,
          inner,
          DApp(dterm_shift(arg_val, 0, 1), DTVar(0)),
          DApp(dterm_shift(joint_ih, 0, 1), DTVar(0)),
          sim_elim_extend_pos(target_pos, total),
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      Some(
        DLam(
          sim_elim_rewrite(dom, target_pos.length(), target_pos, total),
          body,
        ),
      )
    }
    DFunctorContainer(shape, positions, _) => {
      let shape_t = sim_elim_rewrite(
        shape,
        target_pos.length(),
        target_pos,
        total,
      )
      let tp2 = sim_elim_extend_pos(target_pos, total)
      let pos_t = sim_elim_rewrite(positions, tp2.length(), tp2, total + 1)
      let leaf_proj = sim_joint_tuple_proj(
        DApp(dterm_shift(joint_ih, 0, 2), DTVar(0)),
        g,
        k,
      )
      Some(DApp(DLam(shape_t, DLam(pos_t, leaf_proj)), DFst(arg_val)))
    }
    DFunctorSum(a, b) => {
      let ta = match sim_elim_functor_type_term(base, a, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let tb = match sim_elim_functor_type_term(base, b, target_pos, total) {
        Some(v) => v
        None => return None
      }
      // Motive over `tag : Bool`:
      // `Π (payload : if tag then ta else tb), Π (ih : All_(if tag then a else b)(M_joint)(tag, payload)), All_(if tag then a else b)(M_g)(tag, payload)`
      let j_a = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          -1,
          a,
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let j_b = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          -1,
          b,
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let g_a = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          a,
          DTVar(1),
          target_pos,
          total + 3,
        ) {
        Some(v) => v
        None => return None
      }
      let g_b = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          b,
          DTVar(1),
          target_pos,
          total + 3,
        ) {
        Some(v) => v
        None => return None
      }
      let j_a_1 = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          -1,
          a,
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let j_b_1 = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          -1,
          b,
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let pa = match
        sim_joint_project_bundle(
          spec,
          joint_level,
          g,
          a,
          DTVar(1),
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let pb = match
        sim_joint_project_bundle(
          spec,
          joint_level,
          g,
          b,
          DTVar(1),
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let motive_sum = DPi(
        DBoolElim(
          DUniv(base.level),
          dterm_shift(ta, 0, 1),
          dterm_shift(tb, 0, 1),
          DTVar(0),
        ),
        DPi(
          DBoolElim(DUniv(joint_level), j_a, j_b, DTVar(1)),
          DBoolElim(DUniv(joint_level), g_a, g_b, DTVar(2)),
        ),
      )
      Some(
        DApp(
          DApp(
            DBoolElim(
              motive_sum,
              DLam(ta, DLam(j_a_1, pa)),
              DLam(tb, DLam(j_b_1, pb)),
              DFst(arg_val),
            ),
            DSnd(arg_val),
          ),
          joint_ih,
        ),
      )
    }
    DFunctorList(inner) => {
      let elem = match
        sim_elim_functor_type_term(base, inner, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let list_j_motive = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          -1,
          DFunctorList(inner),
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let list_g_motive = match
        sim_general_bundle_type_term(
          spec,
          joint_level,
          g,
          DFunctorList(inner),
          DTVar(1),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let step_dom_fn = DPi(
        match
          sim_general_bundle_type_term(
            spec,
            joint_level,
            -1,
            DFunctorList(inner),
            DTVar(0),
            target_pos,
            total + 2,
          ) {
          Some(v) => v
          None => return None
        },
        match
          sim_general_bundle_type_term(
            spec,
            joint_level,
            g,
            DFunctorList(inner),
            DTVar(1),
            target_pos,
            total + 3,
          ) {
          Some(v) => v
          None => return None
        },
      )
      let cons_ih_dom = DSigma(
        match
          sim_general_bundle_type_term(
            spec,
            joint_level,
            -1,
            inner,
            DTVar(2),
            target_pos,
            total + 3,
          ) {
          Some(v) => v
          None => return None
        },
        match
          sim_general_bundle_type_term(
            spec,
            joint_level,
            -1,
            DFunctorList(inner),
            DTVar(2),
            target_pos,
            total + 4,
          ) {
          Some(v) => v
          None => return None
        },
      )
      let head_proj = match
        sim_joint_project_bundle(
          spec,
          joint_level,
          g,
          inner,
          DTVar(3),
          DFst(DTVar(0)),
          target_pos,
          total + 4,
        ) {
        Some(v) => v
        None => return None
      }
      let step = DLam(
        elem,
        DLam(
          DListTy(dterm_shift(elem, 0, 1)),
          DLam(
            step_dom_fn,
            DLam(cons_ih_dom, DPair(head_proj, DApp(DTVar(1), DSnd(DTVar(0))))),
          ),
        ),
      )
      Some(
        DApp(
          DListElim(
            DPi(list_j_motive, list_g_motive),
            DLam(DUnitTy, DUnitLit),
            step,
            arg_val,
          ),
          joint_ih,
        ),
      )
    }
    DFunctorFamily(_) | DFunctorSelfFamily(_) => None
  }
}

///|
fn sim_joint_verify_cases(
  spec : DSimultaneousIRSpec,
  joint_level : Int32,
  motive_term : DTerm,
  cases : Array[DTerm],
) -> Bool {
  let base = spec.base
  let param_values = schema_fresh_values(base.params.length(), 13100)
  let param_types = inductive_param_types(base, param_values)
  let index_values = schema_fresh_values(base.indices.length(), 13200)
  let index_types : Array[DValue] = []
  let prior_values : Array[DValue] = []
  for j in 0..<base.indices.length() {
    index_types.push(
      telescope_next_type(
        base.indices,
        param_types,
        param_values,
        index_types,
        prior_values,
      ),
    )
    prior_values.push(index_values[j])
  }
  let code_value : DValue = DVNeutral(DNVar(13300))
  let mut ctx = denv_empty()
  let mut env = denv_empty()
  for i in 0..<param_types.length() {
    ctx = denv_cons(param_types[i], ctx)
    env = denv_cons(param_values[i], env)
  }
  for i in 0..<index_types.length() {
    ctx = denv_cons(index_types[i], ctx)
    env = denv_cons(index_values[i], env)
  }
  ctx = denv_cons(DVInductive(base, param_values, index_values), ctx)
  env = denv_cons(code_value, env)
  let motive_value = match
    check_schema_motive(
      motive_term,
      base.indices,
      param_types,
      param_values,
      idx => DVInductive(base, param_values, idx),
      joint_level,
      ctx,
      env,
      ddim_empty(),
    ) {
    Some(v) => v
    None => return false
  }
  let motive_fn = inductive_motive_from_value(base, param_values, motive_value)
  for c in 0..<cases.length() {
    let case_type = inductive_case_type(base, motive_fn, param_values, c)
    let case_value = match
      d_check(cases[c], case_type, ctx, env, ddim_empty()) {
      Some(v) => v
      None => return false
    }
    let mut cur = case_value
    let mut ty = case_type
    let mut step = 0
    while true {
      match as_pi(ty) {
        Some(parts) => {
          let fresh : DValue = DVNeutral(DNVar(13400 + c * 40 + step))
          cur = dapp_typed(cur, fresh, parts.dom)
          ty = (parts.fam)(fresh)
          step = step + 1
        }
        None => break
      }
    }
    match force_value(cur) {
      DVUnit => if spec.functions.length() > 0 { return false }
      _ => ()
    }
  }
  true
}

///|
/// Compile an arbitrary simultaneous IR / mutual-recursion block (including
/// forward references, cyclic mutual recursion, `DFunctorSum` / `Sigma` /
/// `Container` / `List` nested arguments, and non-universe small/dependent
/// codomains at level `<= base.level`) via a single joint `Σ`-tuple motive
/// `DInductiveElim`, projecting each function's closed eliminator term and
/// auditing every function with `dep_check_closed`.
pub fn simultaneous_ir_compile_joint_block(
  spec : DSimultaneousIRSpec,
) -> Array[DTerm?] {
  let fn_count = spec.functions.length()
  let empty_out : Array[DTerm?] = []
  for _i in 0..<fn_count {
    empty_out.push(None)
  }
  if fn_count == 0 || !simultaneous_ir_validate(spec) {
    return empty_out
  }
  let joint_level = simultaneous_ir_joint_motive_level(spec)
  if joint_level < 0 {
    return empty_out
  }
  let base = spec.base
  let pc = base.params.length()
  let ic = base.indices.length()
  let outer = pc + ic + 1
  let motive_term = sim_joint_motive(spec)
  // Evaluate the joint motive in a neutral parameter context so we can
  // quote exact case binder domains generically.
  let param_neutrals : Array[DValue] = []
  for p in 0..<pc {
    param_neutrals.push(DVNeutral(DNVar(p)))
  }
  let outer_env_vals : Array[DValue] = []
  for pos in 0..<outer {
    outer_env_vals.push(DVNeutral(DNVar(pos)))
  }
  let motive_val = deval_dim(
    motive_term,
    schema_env(outer_env_vals),
    ddim_empty(),
  )
  let motive_fn = inductive_motive_from_value(base, param_neutrals, motive_val)

  let joint_cases : Array[DTerm] = []
  for c in 0..<base.constructors.length() {
    let ctor = base.constructors[c]
    let bind_kinds : Array[Int32] = []
    let arg_bind_pos : Array[Int32] = []
    let ih_bind_pos : Array[Int32] = []
    for i in 0..<ctor.args.length() {
      let kind = ctor.args[i].kind
      match kind {
        DArgExternal | DArgRecursive | DArgFunction | DArgNested => ()
        _ => return empty_out
      }
      arg_bind_pos.push(bind_kinds.length())
      bind_kinds.push(0)
      if simultaneous_arg_has_hypothesis(kind) {
        ih_bind_pos.push(bind_kinds.length())
        bind_kinds.push(1)
      } else {
        ih_bind_pos.push(-1)
      }
    }
    let constraint_bind_start = bind_kinds.length()
    for _k in 0..<ctor.constraints.length() {
      bind_kinds.push(2)
    }
    let binder_count = bind_kinds.length()
    let body_total = outer + binder_count
    let domains : Array[DTerm] = []
    {
      let mut case_ty = inductive_case_type(base, motive_fn, param_neutrals, c)
      for r in 0..<binder_count {
        match as_pi(case_ty) {
          Some(parts) => {
            domains.push(quote_at(outer + r, 0, DVUniv(joint_level), parts.dom))
            case_ty = (parts.fam)(DVNeutral(DNVar(outer + r)))
          }
          None => return empty_out
        }
      }
    }
    let sim_pos_of_arg : Array[Int32] = []
    let sim_pos_of_ih : Array[Array[Int32]] = []
    let mut sim_len = pc
    for i in 0..<ctor.args.length() {
      sim_pos_of_arg.push(sim_len)
      sim_len = sim_len + 1
      let slots : Array[Int32] = []
      if simultaneous_arg_has_hypothesis(ctor.args[i].kind) {
        for _g in 0..<fn_count {
          slots.push(sim_len)
          sim_len = sim_len + 1
        }
      }
      sim_pos_of_ih.push(slots)
    }
    let sim_constraint_start = sim_len
    sim_len = sim_len + ctor.constraints.length()

    let fn_bodies : Array[DTerm] = []
    for fi in 0..<fn_count {
      let mut failed = false
      let rewritten = dterm_map_vars_at(spec.functions[fi].cases[c], 0, (
        v,
        depth,
      ) => {
        if v < depth {
          DTVar(v)
        } else {
          let pos = sim_len - 1 - (v - depth)
          if pos < 0 || pos >= sim_len {
            DTVar(v)
          } else if pos < pc {
            DTVar(body_total - 1 - pos + depth)
          } else if pos >= sim_constraint_start {
            DTVar(
              body_total -
              1 -
              (outer + constraint_bind_start + (pos - sim_constraint_start)) +
              depth,
            )
          } else {
            let mut out = DTVar(v)
            let mut placed = false
            for i in 0..<ctor.args.length() {
              if pos == sim_pos_of_arg[i] {
                out = DTVar(body_total - 1 - (outer + arg_bind_pos[i]) + depth)
                placed = true
                break
              }
              for g in 0..<sim_pos_of_ih[i].length() {
                if pos == sim_pos_of_ih[i][g] {
                  let total = body_total + depth
                  let arg = ctor.args[i]
                  let ih_var = DTVar(total - 1 - (outer + ih_bind_pos[i]))
                  let arg_var = DTVar(total - 1 - (outer + arg_bind_pos[i]))
                  let target_pos : Array[Int32] = []
                  for p in 0..<pc {
                    target_pos.push(p)
                  }
                  for j in 0..<i {
                    target_pos.push(outer + arg_bind_pos[j])
                  }
                  match arg.kind {
                    DArgRecursive =>
                      out = sim_joint_tuple_proj(ih_var, g, fn_count)
                    DArgFunction => {
                      let dom = sim_elim_rewrite(
                        arg.ty,
                        pc + i,
                        target_pos,
                        total,
                      )
                      let shifted_ih = dterm_shift(ih_var, 0, 1)
                      out = DLam(
                        dom,
                        sim_joint_tuple_proj(
                          DApp(shifted_ih, DTVar(0)),
                          g,
                          fn_count,
                        ),
                      )
                    }
                    DArgNested =>
                      match
                        (
                          sim_joint_project_bundle(
                            spec,
                            joint_level,
                            g,
                            arg.nested,
                            arg_var,
                            ih_var,
                            target_pos,
                            total,
                          ),
                          sim_general_bundle_type_term(
                            spec,
                            joint_level,
                            g,
                            arg.nested,
                            arg_var,
                            target_pos,
                            total,
                          ),
                        ) {
                        (Some(proj_b), Some(ty_b)) => out = DAnn(proj_b, ty_b)
                        _ => failed = true
                      }
                    _ => failed = true
                  }
                  placed = true
                  break
                }
              }
              if placed {
                break
              }
            }
            out
          }
        }
      })
      if failed {
        return empty_out
      }
      fn_bodies.push(rewritten)
    }
    let mut case_term = sim_joint_tuple_intro(fn_bodies)
    let mut r = binder_count - 1
    while r >= 0 {
      case_term = DLam(domains[r], case_term)
      r = r - 1
    }
    joint_cases.push(case_term)
  }
  if !sim_joint_verify_cases(spec, joint_level, motive_term, joint_cases) {
    return empty_out
  }
  let joint_elim = DInductiveElim(
    base,
    motive_term,
    joint_cases,
    sim_elim_vars_at(outer, sim_elim_positions(pc, 0)),
    sim_elim_vars_at(outer, sim_elim_positions(ic, pc)),
    DTVar(0),
  )
  let code_ty = DInductive(
    base,
    sim_elim_vars_at(pc + ic, sim_elim_positions(pc + ic, 0)),
  )
  let result : Array[DTerm?] = []
  for fi in 0..<fn_count {
    let projected = sim_joint_tuple_proj(joint_elim, fi, fn_count)
    let mut term = DLam(code_ty, projected)
    let mut j = ic - 1
    while j >= 0 {
      term = DLam(base.indices[j].ty, term)
      j = j - 1
    }
    let mut p = pc - 1
    while p >= 0 {
      term = DLam(base.params[p].ty, term)
      p = p - 1
    }
    match simultaneous_ir_general_eliminator_type(spec, fi) {
      Some(ty) =>
        if dep_check_closed(term, ty) {
          result.push(Some(term))
        } else {
          return empty_out
        }
      None => return empty_out
    }
  }
  result
}

// ---------------------------------------------------------------------------
// Phase 16: Dybjer–Setzer Open Simultaneous Induction-Recursion
// ---------------------------------------------------------------------------

///|
/// Constructor-argument forms for open Dybjer–Setzer simultaneous
/// induction-recursion over a code universe `U : Type[level]` equipped with
/// `m >= 1` simultaneous decoding functions `T_0, ..., T_{m-1}`:
/// - `DOpenArgExternal(ty)` : non-recursive external parameter `x : ty`
///   (evaluated in the telescope of preceding constructor arguments).
/// - `DOpenArgCode` : recursive code argument `a : U`, binding `m`
///   simultaneous decoded-type hypotheses `T_0(a), ..., T_{m-1}(a)`.
/// - `DOpenArgDecodedVal(source_arg, decoder_idx)` : an element
///   `v : T_{decoder_idx}(a_{source_arg})` of a simultaneous decoder applied
///   to an earlier `DOpenArgCode` argument `source_arg`.
/// - `DOpenArgDecodedCodeFn(source_arg, decoder_idx)` : a family of recursive
///   codes `f : T_{decoder_idx}(a_{source_arg}) -> U`, binding `m`
///   simultaneous functional hypotheses
///   `λx. T_0(f(x)), ..., λx. T_{m-1}(f(x))`.
#derive(Debug, Eq)
pub(all) enum DOpenIRArgKind {
  DOpenArgExternal(DTerm)
  DOpenArgCode
  DOpenArgDecodedVal(Int32, Int32)
  DOpenArgDecodedCodeFn(Int32, Int32)
}

///|
pub extend DOpenIRArgKind with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DOpenIRArgKind with Eq::{not_equal, equal}

///|
#derive(Debug, Eq)
pub struct DOpenIRArg {
  name : String
  kind : DOpenIRArgKind
}

///|
pub extend DOpenIRArg with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DOpenIRArg with Eq::{not_equal, equal}

///|
pub fn dopen_arg_code(name : String) -> DOpenIRArg {
  DOpenIRArg::{ name, kind: DOpenArgCode, }
}

///|
pub fn dopen_arg_decoded_code_fn(
  name : String,
  source_arg : Int32,
  decoder_idx : Int32,
) -> DOpenIRArg {
  DOpenIRArg::{ name, kind: DOpenArgDecodedCodeFn(source_arg, decoder_idx), }
}

///|
#derive(Debug, Eq)
pub struct DOpenIRConstructor {
  name : String
  args : Array[DOpenIRArg]
}

///|
pub extend DOpenIRConstructor with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DOpenIRConstructor with Eq::{not_equal, equal}

///|
pub fn dopen_ir_constructor(
  name : String,
  args : Array[DOpenIRArg],
) -> DOpenIRConstructor {
  DOpenIRConstructor::{ name, args, }
}

///|
#derive(Debug, Eq)
pub struct DOpenIRDecoder {
  name : String
  decode_level : Int32
  cases : Array[DTerm]
}

///|
pub extend DOpenIRDecoder with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DOpenIRDecoder with Eq::{not_equal, equal}

///|
pub fn dopen_ir_decoder(
  name : String,
  decode_level : Int32,
  cases : Array[DTerm],
) -> DOpenIRDecoder {
  DOpenIRDecoder::{ name, decode_level, cases, }
}

///|
#derive(Debug, Eq)
pub struct DOpenSimultaneousIRSpec {
  name : String
  level : Int32
  constructors : Array[DOpenIRConstructor]
  decoders : Array[DOpenIRDecoder]
}

///|
pub extend DOpenSimultaneousIRSpec with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DOpenSimultaneousIRSpec with Eq::{not_equal, equal}

///|
pub fn dopen_simultaneous_ir_spec(
  name : String,
  level : Int32,
  constructors : Array[DOpenIRConstructor],
  decoders : Array[DOpenIRDecoder],
) -> DOpenSimultaneousIRSpec {
  DOpenSimultaneousIRSpec::{ name, level, constructors, decoders, }
}

///|
/// Inhabitant of an open simultaneous IR code universe `U`, paired with
/// constructor-argument values supporting higher-order code families.
pub(all) enum DOpenIRArgVal {
  DOpenValTerm(DTerm)
  DOpenValCode(DOpenIRCode)
  DOpenValCodeFn((DValue) -> DOpenIRCode)
}

///|
pub fn dopen_val_code(code : DOpenIRCode) -> DOpenIRArgVal {
  DOpenValCode(code)
}

///|
pub fn dopen_val_code_fn(f : (DValue) -> DOpenIRCode) -> DOpenIRArgVal {
  DOpenValCodeFn(f)
}

///|
pub struct DOpenIRCode {
  ctor_idx : Int32
  args : Array[DOpenIRArgVal]
}

///|
pub fn dopen_ir_intro(
  ctor_idx : Int32,
  args : Array[DOpenIRArgVal],
) -> DOpenIRCode {
  DOpenIRCode::{ ctor_idx, args, }
}

///|
/// Validate a Dybjer–Setzer open simultaneous IR declaration:
/// 1. `level >= 0`, non-empty distinct constructor & decoder names, and each
///    decoder supplies one clause per constructor with `decode_level >= 0`.
/// 2. In every constructor telescope, `DOpenArgExternal(ty)` is checked in the
///    preceding argument context at level `<= spec.level` and must be strictly
///    positive wrt `spec.name`; `DOpenArgDecodedVal(s, d)` and
///    `DOpenArgDecodedCodeFn(s, d)` must reference an earlier `DOpenArgCode`
///    slot `0 <= s < i` and valid decoder `0 <= d < m` whose `decode_level <=
///    spec.level` (universe predicativity of the code type `U`).
/// 3. Treating `U` as an opaque abstract type, every decoder clause
///    `decoders[r].cases[c]` typechecks against `DVUniv(decoders[r].decode_level)`
///    in the full simultaneous arg + IH telescope.
pub fn open_ir_validate(spec : DOpenSimultaneousIRSpec) -> Bool {
  let m = spec.decoders.length()
  let cc = spec.constructors.length()
  if spec.name == "" || spec.level < 0 || m == 0 || cc == 0 {
    return false
  }
  for i in 0..<cc {
    if spec.constructors[i].name == "" {
      return false
    }
    for j in (i + 1)..<cc {
      if spec.constructors[i].name == spec.constructors[j].name {
        return false
      }
    }
  }
  for r in 0..<m {
    let dec = spec.decoders[r]
    if dec.name == "" || dec.decode_level < 0 || dec.cases.length() != cc {
      return false
    }
    for s in (r + 1)..<m {
      if dec.name == spec.decoders[s].name {
        return false
      }
    }
  }
  // Abstract placeholder for `U : Type[spec.level]` so decoder bodies cannot
  // inspect codes non-parametrically.
  let u_abstract : DValue = DVNeutral(DNVar(94000))
  for c in 0..<cc {
    let ctor = spec.constructors[c]
    // Track both the arg-only context (for `DOpenArgExternal(ty)`) and the
    // expanded arg+IH context (for decoder clauses).
    let mut arg_ctx = denv_empty()
    let mut arg_env = denv_empty()
    let mut sim_ctx = denv_empty()
    let mut sim_env = denv_empty()
    let code_ihs : Array[Array[DValue]] = []
    let mut fresh_seed = 94100 + c * 200
    for i in 0..<ctor.args.length() {
      let arg = ctor.args[i]
      if arg.name == "" {
        return false
      }
      match arg.kind {
        DOpenArgExternal(ty) => {
          if !dterm_family_strictly_positive(ty, spec.name) {
            return false
          }
          let tv = match d_as_type(ty, arg_ctx, arg_env, ddim_empty()) {
            Some(v) => v
            None => return false
          }
          if tv.level > spec.level {
            return false
          }
          let fv : DValue = DVNeutral(DNVar(fresh_seed))
          fresh_seed = fresh_seed + 1
          arg_ctx = denv_cons(tv.value, arg_ctx)
          arg_env = denv_cons(fv, arg_env)
          sim_ctx = denv_cons(tv.value, sim_ctx)
          sim_env = denv_cons(fv, sim_env)
          code_ihs.push([])
        }
        DOpenArgCode => {
          let fv : DValue = DVNeutral(DNVar(fresh_seed))
          fresh_seed = fresh_seed + 1
          arg_ctx = denv_cons(u_abstract, arg_ctx)
          arg_env = denv_cons(fv, arg_env)
          sim_ctx = denv_cons(u_abstract, sim_ctx)
          sim_env = denv_cons(fv, sim_env)
          let ih_row : Array[DValue] = []
          for r in 0..<m {
            let ih_ty = DVUniv(spec.decoders[r].decode_level)
            let ih_val : DValue = DVNeutral(DNVar(fresh_seed))
            fresh_seed = fresh_seed + 1
            sim_ctx = denv_cons(ih_ty, sim_ctx)
            sim_env = denv_cons(ih_val, sim_env)
            ih_row.push(ih_val)
          }
          code_ihs.push(ih_row)
        }
        DOpenArgDecodedVal(src, dec_idx) => {
          if src < 0 ||
            src >= i ||
            dec_idx < 0 ||
            dec_idx >= m ||
            code_ihs[src].length() != m ||
            spec.decoders[dec_idx].decode_level > spec.level {
            return false
          }
          let dom_ty = code_ihs[src][dec_idx]
          let fv : DValue = DVNeutral(DNVar(fresh_seed))
          fresh_seed = fresh_seed + 1
          arg_ctx = denv_cons(dom_ty, arg_ctx)
          arg_env = denv_cons(fv, arg_env)
          sim_ctx = denv_cons(dom_ty, sim_ctx)
          sim_env = denv_cons(fv, sim_env)
          code_ihs.push([])
        }
        DOpenArgDecodedCodeFn(src, dec_idx) => {
          if src < 0 ||
            src >= i ||
            dec_idx < 0 ||
            dec_idx >= m ||
            code_ihs[src].length() != m ||
            spec.decoders[dec_idx].decode_level > spec.level {
            return false
          }
          let dom_ty = code_ihs[src][dec_idx]
          let fn_ty = DVPi(dom_ty, _ => u_abstract)
          let fv : DValue = DVNeutral(DNVar(fresh_seed))
          fresh_seed = fresh_seed + 1
          arg_ctx = denv_cons(fn_ty, arg_ctx)
          arg_env = denv_cons(fv, arg_env)
          sim_ctx = denv_cons(fn_ty, sim_ctx)
          sim_env = denv_cons(fv, sim_env)
          for r in 0..<m {
            let ih_ty = DVPi(dom_ty, _ => DVUniv(spec.decoders[r].decode_level))
            let ih_val : DValue = DVNeutral(DNVar(fresh_seed))
            fresh_seed = fresh_seed + 1
            sim_ctx = denv_cons(ih_ty, sim_ctx)
            sim_env = denv_cons(ih_val, sim_env)
          }
          code_ihs.push([])
        }
      }
    }
    for r in 0..<m {
      let dec = spec.decoders[r]
      match
        d_check(
          dec.cases[c],
          DVUniv(dec.decode_level),
          sim_ctx,
          sim_env,
          ddim_empty(),
        ) {
        Some(_) => ()
        None => return false
      }
    }
  }
  true
}

///|
fn open_ir_eval_all_decoders(
  spec : DOpenSimultaneousIRSpec,
  code : DOpenIRCode,
  dlevel : Int32,
) -> Array[DValue]? {
  let m = spec.decoders.length()
  if code.ctor_idx < 0 || code.ctor_idx >= spec.constructors.length() {
    return None
  }
  let ctor = spec.constructors[code.ctor_idx]
  if code.args.length() != ctor.args.length() {
    return None
  }
  let mut arg_env = denv_empty()
  let mut sim_env = denv_empty()
  let mut arg_ctx = denv_empty()
  let code_ihs : Array[Array[DValue]] = []
  let u_abstract : DValue = DVNeutral(DNVar(94000))
  for i in 0..<ctor.args.length() {
    match (ctor.args[i].kind, code.args[i]) {
      (DOpenArgExternal(ty), DOpenValTerm(tm)) => {
        let expected = match d_as_type(ty, arg_ctx, arg_env, ddim_empty()) {
          Some(tv) => tv.value
          None => return None
        }
        let val = match
          d_check(tm, expected, denv_empty(), denv_empty(), ddim_empty()) {
          Some(v) => v
          None => return None
        }
        arg_ctx = denv_cons(expected, arg_ctx)
        arg_env = denv_cons(val, arg_env)
        sim_env = denv_cons(val, sim_env)
        code_ihs.push([])
      }
      (DOpenArgCode, DOpenValCode(sub_code)) => {
        let sub_decs = match open_ir_eval_all_decoders(spec, sub_code, dlevel) {
          Some(ds) => ds
          None => return None
        }
        arg_ctx = denv_cons(u_abstract, arg_ctx)
        arg_env = denv_cons(DVUnit, arg_env)
        sim_env = denv_cons(DVUnit, sim_env)
        for r in 0..<m {
          sim_env = denv_cons(sub_decs[r], sim_env)
        }
        code_ihs.push(sub_decs)
      }
      (DOpenArgDecodedVal(src, dec_idx), DOpenValTerm(tm)) => {
        if src < 0 ||
          src >= i ||
          dec_idx < 0 ||
          dec_idx >= m ||
          code_ihs[src].length() != m {
          return None
        }
        let expected = code_ihs[src][dec_idx]
        let val = match
          d_check(tm, expected, denv_empty(), denv_empty(), ddim_empty()) {
          Some(v) => v
          None => return None
        }
        arg_ctx = denv_cons(expected, arg_ctx)
        arg_env = denv_cons(val, arg_env)
        sim_env = denv_cons(val, sim_env)
        code_ihs.push([])
      }
      (DOpenArgDecodedCodeFn(src, dec_idx), DOpenValCodeFn(f_code)) => {
        if src < 0 ||
          src >= i ||
          dec_idx < 0 ||
          dec_idx >= m ||
          code_ihs[src].length() != m {
          return None
        }
        let dom_ty = code_ihs[src][dec_idx]
        arg_ctx = denv_cons(DVPi(dom_ty, _ => u_abstract), arg_ctx)
        arg_env = denv_cons(DVUnit, arg_env)
        sim_env = denv_cons(DVUnit, sim_env)
        for r in 0..<m {
          let r_idx = r
          let fam_val = DVLam(x => {
            match open_ir_eval_all_decoders(spec, f_code(x), dlevel) {
              Some(ds) => ds[r_idx]
              None => DVUnitTy
            }
          })
          sim_env = denv_cons(fam_val, sim_env)
        }
        code_ihs.push([])
      }
      _ => return None
    }
  }
  let out : Array[DValue] = []
  for r in 0..<m {
    out.push(
      deval_dim(spec.decoders[r].cases[code.ctor_idx], sim_env, ddim_empty()),
    )
  }
  Some(out)
}

///|
/// Typecheck a closed `DOpenIRCode` value against a validated open
/// simultaneous IR declaration `spec` (including probing higher-order code
/// families at a fresh reflected neutral element of their decoded domain).
pub fn open_ir_check_code(
  spec : DOpenSimultaneousIRSpec,
  code : DOpenIRCode,
  seed~ : Int32 = 95000,
) -> Bool {
  if !open_ir_validate(spec) {
    return false
  }
  open_ir_check_code_rec(spec, code, seed)
}

///|
fn open_ir_check_code_rec(
  spec : DOpenSimultaneousIRSpec,
  code : DOpenIRCode,
  seed : Int32,
) -> Bool {
  if code.ctor_idx < 0 || code.ctor_idx >= spec.constructors.length() {
    return false
  }
  let ctor = spec.constructors[code.ctor_idx]
  if code.args.length() != ctor.args.length() {
    return false
  }
  let m = spec.decoders.length()
  let code_ihs : Array[Array[DValue]] = []
  let mut arg_ctx = denv_empty()
  let mut arg_env = denv_empty()
  let u_abstract : DValue = DVNeutral(DNVar(94000))
  for i in 0..<ctor.args.length() {
    match (ctor.args[i].kind, code.args[i]) {
      (DOpenArgExternal(ty), DOpenValTerm(tm)) => {
        let expected = match d_as_type(ty, arg_ctx, arg_env, ddim_empty()) {
          Some(tv) => tv.value
          None => return false
        }
        match d_check(tm, expected, denv_empty(), denv_empty(), ddim_empty()) {
          Some(v) => {
            arg_ctx = denv_cons(expected, arg_ctx)
            arg_env = denv_cons(v, arg_env)
            code_ihs.push([])
          }
          None => return false
        }
      }
      (DOpenArgCode, DOpenValCode(sub)) => {
        if !open_ir_check_code_rec(spec, sub, seed + (i + 1) * 31) {
          return false
        }
        match open_ir_eval_all_decoders(spec, sub, 0) {
          Some(ds) => {
            arg_ctx = denv_cons(u_abstract, arg_ctx)
            arg_env = denv_cons(DVUnit, arg_env)
            code_ihs.push(ds)
          }
          None => return false
        }
      }
      (DOpenArgDecodedVal(src, dec_idx), DOpenValTerm(tm)) => {
        if src < 0 ||
          src >= i ||
          dec_idx < 0 ||
          dec_idx >= m ||
          code_ihs[src].length() != m {
          return false
        }
        let expected = code_ihs[src][dec_idx]
        match d_check(tm, expected, denv_empty(), denv_empty(), ddim_empty()) {
          Some(v) => {
            arg_ctx = denv_cons(expected, arg_ctx)
            arg_env = denv_cons(v, arg_env)
            code_ihs.push([])
          }
          None => return false
        }
      }
      (DOpenArgDecodedCodeFn(src, dec_idx), DOpenValCodeFn(f_code)) => {
        if src < 0 ||
          src >= i ||
          dec_idx < 0 ||
          dec_idx >= m ||
          code_ihs[src].length() != m {
          return false
        }
        let dom_ty = code_ihs[src][dec_idx]
        let probe = reflect_var(seed + i * 17, dom_ty)
        if !open_ir_check_code_rec(spec, f_code(probe), seed + (i + 1) * 53) {
          return false
        }
        arg_ctx = denv_cons(DVPi(dom_ty, _ => u_abstract), arg_ctx)
        arg_env = denv_cons(DVUnit, arg_env)
        code_ihs.push([])
      }
      _ => return false
    }
  }
  true
}

///|
/// Evaluate simultaneous decoder `decoder_idx` (`T_{decoder_idx} : U -> Type`)
/// on a `DOpenIRCode` value.
pub fn open_ir_eval_decode(
  spec : DOpenSimultaneousIRSpec,
  decoder_idx : Int32,
  code : DOpenIRCode,
  dlevel~ : Int32 = 0,
) -> DValue? {
  if decoder_idx < 0 ||
    decoder_idx >= spec.decoders.length() ||
    !open_ir_validate(spec) {
    return None
  }
  match open_ir_eval_all_decoders(spec, code, dlevel) {
    Some(ds) => Some(ds[decoder_idx])
    None => None
  }
}

///|
/// Dependent elimination over `DOpenIRCode`: each step function `cases[c]`
/// receives an array of evaluated step arguments (external `DValue`s, recursive
/// results `M(sub)`, decoded inhabitants `v : T_d(a_s)`, or functional step
/// closures `DVLam(x => M(f(x)))`) and produces a `DValue`.
pub fn open_ir_elim_value(
  spec : DOpenSimultaneousIRSpec,
  cases : Array[(Array[DValue]) -> DValue],
  code : DOpenIRCode,
  dlevel~ : Int32 = 0,
) -> DValue? {
  if cases.length() != spec.constructors.length() ||
    !open_ir_check_code(spec, code) {
    return None
  }
  open_ir_elim_rec(spec, cases, code, dlevel)
}

///|
fn open_ir_elim_rec(
  spec : DOpenSimultaneousIRSpec,
  cases : Array[(Array[DValue]) -> DValue],
  code : DOpenIRCode,
  dlevel : Int32,
) -> DValue? {
  let ctor = spec.constructors[code.ctor_idx]
  let step_args : Array[DValue] = []
  let code_ihs : Array[Array[DValue]] = []
  let mut arg_ctx = denv_empty()
  let mut arg_env = denv_empty()
  let u_abstract : DValue = DVNeutral(DNVar(94000))
  for i in 0..<ctor.args.length() {
    match (ctor.args[i].kind, code.args[i]) {
      (DOpenArgExternal(ty), DOpenValTerm(tm)) => {
        let expected = match d_as_type(ty, arg_ctx, arg_env, ddim_empty()) {
          Some(tv) => tv.value
          None => return None
        }
        let v = match
          d_check(tm, expected, denv_empty(), denv_empty(), ddim_empty()) {
          Some(val) => val
          None => return None
        }
        step_args.push(v)
        arg_ctx = denv_cons(expected, arg_ctx)
        arg_env = denv_cons(v, arg_env)
        code_ihs.push([])
      }
      (DOpenArgCode, DOpenValCode(sub)) => {
        let ih = match open_ir_elim_rec(spec, cases, sub, dlevel) {
          Some(v) => v
          None => return None
        }
        let ds = match open_ir_eval_all_decoders(spec, sub, dlevel) {
          Some(v) => v
          None => return None
        }
        step_args.push(ih)
        arg_ctx = denv_cons(u_abstract, arg_ctx)
        arg_env = denv_cons(DVUnit, arg_env)
        code_ihs.push(ds)
      }
      (DOpenArgDecodedVal(src, dec_idx), DOpenValTerm(tm)) => {
        let expected = code_ihs[src][dec_idx]
        let v = match
          d_check(tm, expected, denv_empty(), denv_empty(), ddim_empty()) {
          Some(val) => val
          None => return None
        }
        step_args.push(v)
        arg_ctx = denv_cons(expected, arg_ctx)
        arg_env = denv_cons(v, arg_env)
        code_ihs.push([])
      }
      (DOpenArgDecodedCodeFn(_src, _dec_idx), DOpenValCodeFn(f_code)) => {
        step_args.push(
          DVLam(x => {
            match open_ir_elim_rec(spec, cases, f_code(x), dlevel) {
              Some(v) => v
              None => DVUnit
            }
          }),
        )
        arg_ctx = denv_cons(u_abstract, arg_ctx)
        arg_env = denv_cons(DVUnit, arg_env)
        code_ihs.push([])
      }
      _ => return None
    }
  }
  Some(cases[code.ctor_idx](step_args))
}

///|
/// When an open simultaneous IR specification has a single decoder (`m == 1`),
/// lower it directly to a kernel `DInductiveSpec` (`dinductive_recursive_spec`)
/// and verify `inductive_schema_validate`.
pub fn open_ir_lower_single_decoder(
  spec : DOpenSimultaneousIRSpec,
) -> DInductiveSpec? {
  if spec.decoders.length() != 1 || !open_ir_validate(spec) {
    return None
  }
  let dec = spec.decoders[0]
  let ctors : Array[DConstructorSpec] = []
  for c in 0..<spec.constructors.length() {
    let src_ctor = spec.constructors[c]
    let kargs : Array[DConstructorArg] = []
    for i in 0..<src_ctor.args.length() {
      let a = src_ctor.args[i]
      match a.kind {
        DOpenArgExternal(ty) => kargs.push(darg_external(a.name, ty))
        DOpenArgCode => kargs.push(darg_recursive(a.name))
        DOpenArgDecodedVal(src, 0) => kargs.push(darg_decoded(a.name, src))
        DOpenArgDecodedCodeFn(src, 0) =>
          kargs.push(darg_decoded_function(a.name, src))
        _ => return None
      }
    }
    ctors.push(dconstructor_spec(src_ctor.name, kargs))
  }
  let empty_entries : Array[DTelescopeEntry] = []
  let lowered = dinductive_recursive_spec(
    spec.name,
    spec.level,
    empty_entries,
    empty_entries,
    ctors,
    dec.cases,
    decode_level=dec.decode_level,
  )
  if inductive_schema_validate(lowered) {
    Some(lowered)
  } else {
    None
  }
}
