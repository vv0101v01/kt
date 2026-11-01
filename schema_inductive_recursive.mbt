// ---------------------------------------------------------------------------
// Simultaneous induction-recursion (semantic layer)
// ---------------------------------------------------------------------------

///|
/// One simultaneously defined recursive function.  `result_type`
/// is a type term in the context of the family parameters, indices,
/// and the code itself.  `cases[c]` is read in the context of the
/// parameters and constructor arguments, where after every
/// recursive/function/nested argument there is one recursive
/// hypothesis for every function of the simultaneous block, in
/// declaration order; constraint proofs come last.
pub struct DSimultaneousFunction {
  name : String
  result_type : DTerm
  cases : Array[DTerm]
}

///|
pub struct DSimultaneousIRSpec {
  base : DInductiveSpec
  functions : Array[DSimultaneousFunction]
}

///|
pub fn dsimultaneous_function(
  name : String,
  result_type : DTerm,
  cases : Array[DTerm],
) -> DSimultaneousFunction {
  DSimultaneousFunction::{ name, result_type, cases, }
}

///|
pub fn dsimultaneous_ir_spec(
  base : DInductiveSpec,
  functions : Array[DSimultaneousFunction],
) -> DSimultaneousIRSpec {
  DSimultaneousIRSpec::{ base, functions, }
}

///|
fn simultaneous_result_type(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
  params : Array[DValue],
  indices : Array[DValue],
  code : DValue,
) -> DValue {
  if function_index < 0 || function_index >= spec.functions.length() {
    return DVUnitTy
  }
  let values = schema_concat_values(schema_concat_values(params, indices), [
    code,
  ])
  deval_dim(
    spec.functions[function_index].result_type,
    schema_env(values),
    ddim_empty(),
  )
}

///|
/// Evaluate one function of a simultaneous induction-recursive
/// block by structural recursion.  Cases receive, for each
/// recursive position, the values of *all* functions at that
/// position (pointwise for function arguments and through
/// `positive_functor_map` for nested arguments), so the functions
/// may genuinely call one another on subterms.
pub fn eval_simultaneous_ir(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
  params : Array[DValue],
  indices : Array[DValue],
  code : DValue,
  dlevel : Int32,
) -> DValue {
  if function_index < 0 || function_index >= spec.functions.length() {
    return DVUnit
  }
  match force_value(code) {
    DVIntro(spec2, ctor, params2, args) =>
      if spec2 != spec.base ||
        ctor < 0 ||
        ctor >= spec.base.constructors.length() ||
        ctor >= spec.functions[function_index].cases.length() {
        DVUnit
      } else {
        let ctor_spec = spec.base.constructors[ctor]
        let env_values : Array[DValue] = []
        for i in 0..<params2.length() {
          env_values.push(params2[i])
        }
        let prior : Array[DValue] = []
        for i in 0..<args.length() {
          if i >= ctor_spec.args.length() {
            break
          }
          let arg_spec = ctor_spec.args[i]
          let arg = args[i]
          env_values.push(arg)
          match arg_spec.kind {
            DArgRecursive => {
              let idx = schema_eval_index_terms(params2, prior, arg_spec.index)
              for g in 0..<spec.functions.length() {
                env_values.push(
                  eval_simultaneous_ir(spec, g, params2, idx, arg, dlevel),
                )
              }
            }
            DArgFunction => {
              let dom = schema_eval_under(
                arg_spec.ty,
                schema_concat_values(params2, prior),
                [],
              )
              let prior_copy = schema_concat_values([], prior)
              for g in 0..<spec.functions.length() {
                env_values.push(
                  DVLam(a => {
                    let idx = schema_eval_index_terms(
                      params2,
                      schema_concat_values(prior_copy, [a]),
                      arg_spec.index,
                    )
                    eval_simultaneous_ir(
                      spec,
                      g,
                      params2,
                      idx,
                      dapp_typed(arg, a, dom),
                      dlevel,
                    )
                  }),
                )
              }
            }
            DArgNested =>
              for g in 0..<spec.functions.length() {
                env_values.push(
                  positive_functor_map(
                    arg_spec.nested,
                    params2,
                    prior,
                    idx => DVInductive(spec.base, params2, idx),
                    (idx, x) => {
                      simultaneous_result_type(spec, g, params2, idx, x)
                    },
                    (idx, x) => {
                      eval_simultaneous_ir(spec, g, params2, idx, x, dlevel)
                    },
                    arg,
                  ),
                )
              }
            DArgDecodedFunction => {
              let prior_specs = schema_arg_spec_prefix(ctor_spec.args, i)
              let dom = eval_inductive_decode(
                spec.base,
                params2,
                schema_source_indices(arg_spec, prior_specs, params2, prior),
                schema_source_value(arg_spec, prior),
                dlevel,
              )
              let prior_copy = schema_concat_values([], prior)
              for g in 0..<spec.functions.length() {
                env_values.push(
                  DVLam(a => {
                    let idx = schema_eval_index_terms(
                      params2,
                      schema_concat_values(prior_copy, [a]),
                      arg_spec.index,
                    )
                    eval_simultaneous_ir(
                      spec,
                      g,
                      params2,
                      idx,
                      dapp_typed(arg, a, dom),
                      dlevel,
                    )
                  }),
                )
              }
            }
            DArgExternal | DArgDecoded => ()
          }
          prior.push(arg)
        }
        for i in 0..<ctor_spec.constraints.length() {
          let (_, lhs, _) = schema_constraint_parts(
            ctor_spec.constraints[i],
            params2,
            args,
          )
          env_values.push(DVPathLam(_ => lhs))
        }
        deval_dim(
          spec.functions[function_index].cases[ctor],
          schema_env(env_values),
          ddim_empty(),
        )
      }
    DVNeutral(DNComp(line, branches, base)) =>
      elim_over_comp(
        line,
        branches,
        base,
        v => simultaneous_result_type(spec, function_index, params, indices, v),
        v => {
          eval_simultaneous_ir(spec, function_index, params, indices, v, dlevel)
        },
        dlevel,
      )
    DVNeutral(DNHComp(ty, branches, base)) =>
      elim_over_comp(
        _ => ty,
        branches,
        base,
        v => simultaneous_result_type(spec, function_index, params, indices, v),
        v => {
          eval_simultaneous_ir(spec, function_index, params, indices, v, dlevel)
        },
        dlevel,
      )
    DVNeutral(DNVar(n)) =>
      // A stuck simultaneous application at a fresh variable.  The
      // distinct level keeps hypotheses for different functions and
      // codes apart during case validation.
      DVNeutral(DNVar(24000 + function_index * 1000 + n % 1000))
    DVNeutral(n) => DVNeutral(n)
    _ => DVUnit
  }
}

///|
fn simultaneous_case_validate(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
  ctor_index : Int32,
  param_values : Array[DValue],
  param_types : Array[DValue],
) -> Bool {
  let ctor = spec.base.constructors[ctor_index]
  let types : Array[DValue] = []
  let values : Array[DValue] = []
  for i in 0..<param_types.length() {
    types.push(param_types[i])
    values.push(param_values[i])
  }
  let prior : Array[DValue] = []
  for i in 0..<ctor.args.length() {
    let arg = ctor.args[i]
    let prior_specs = schema_arg_spec_prefix(ctor.args, i)
    let arg_ty = inductive_arg_type_full(
      spec.base,
      arg,
      prior_specs,
      param_values,
      prior,
    )
    let fresh = DVNeutral(DNVar(10000 + ctor_index * 100 + i))
    types.push(arg_ty)
    values.push(fresh)
    match arg.kind {
      DArgRecursive => {
        let idx = schema_eval_index_terms(param_values, prior, arg.index)
        for g in 0..<spec.functions.length() {
          types.push(
            simultaneous_result_type(spec, g, param_values, idx, fresh),
          )
          values.push(
            eval_simultaneous_ir(spec, g, param_values, idx, fresh, 0),
          )
        }
      }
      DArgFunction => {
        let dom = schema_eval_under(
          arg.ty,
          schema_concat_values(param_values, prior),
          [],
        )
        let prior_copy = schema_concat_values([], prior)
        for g in 0..<spec.functions.length() {
          types.push(
            DVPi(dom, a => {
              simultaneous_result_type(
                spec,
                g,
                param_values,
                schema_eval_index_terms(
                  param_values,
                  schema_concat_values(prior_copy, [a]),
                  arg.index,
                ),
                dapp_typed(fresh, a, dom),
              )
            }),
          )
          values.push(
            DVLam(a => {
              eval_simultaneous_ir(
                spec,
                g,
                param_values,
                schema_eval_index_terms(
                  param_values,
                  schema_concat_values(prior_copy, [a]),
                  arg.index,
                ),
                dapp_typed(fresh, a, dom),
                0,
              )
            }),
          )
        }
      }
      DArgNested =>
        for g in 0..<spec.functions.length() {
          types.push(
            positive_functor_ih_type(
              arg.nested,
              param_values,
              prior,
              idx => DVInductive(spec.base, param_values, idx),
              (idx, x) => {
                simultaneous_result_type(spec, g, param_values, idx, x)
              },
              fresh,
            ),
          )
          values.push(
            positive_functor_map(
              arg.nested,
              param_values,
              prior,
              idx => DVInductive(spec.base, param_values, idx),
              (idx, x) => {
                simultaneous_result_type(spec, g, param_values, idx, x)
              },
              (idx, x) => eval_simultaneous_ir(spec, g, param_values, idx, x, 0),
              fresh,
            ),
          )
        }
      DArgDecodedFunction => {
        let dom = eval_inductive_decode(
          spec.base,
          param_values,
          schema_source_indices(arg, prior_specs, param_values, prior),
          schema_source_value(arg, prior),
          0,
        )
        let prior_copy = schema_concat_values([], prior)
        for g in 0..<spec.functions.length() {
          types.push(
            DVPi(dom, a => {
              simultaneous_result_type(
                spec,
                g,
                param_values,
                schema_eval_index_terms(
                  param_values,
                  schema_concat_values(prior_copy, [a]),
                  arg.index,
                ),
                dapp_typed(fresh, a, dom),
              )
            }),
          )
          values.push(
            DVLam(a => {
              eval_simultaneous_ir(
                spec,
                g,
                param_values,
                schema_eval_index_terms(
                  param_values,
                  schema_concat_values(prior_copy, [a]),
                  arg.index,
                ),
                dapp_typed(fresh, a, dom),
                0,
              )
            }),
          )
        }
      }
      DArgExternal | DArgDecoded => ()
    }
    prior.push(fresh)
  }
  for i in 0..<ctor.constraints.length() {
    let (ty, lhs, rhs) = schema_constraint_parts(
      ctor.constraints[i],
      param_values,
      prior,
    )
    types.push(DVPathTy(_ => ty, lhs, rhs))
    values.push(DVPathLam(_ => lhs))
  }
  let expected = simultaneous_result_type(
    spec,
    function_index,
    param_values,
    inductive_result_indices(ctor, param_values, prior),
    DVIntro(spec.base, ctor_index, param_values, prior),
  )
  match
    d_check(
      spec.functions[function_index].cases[ctor_index],
      expected,
      schema_env(types),
      schema_env(values),
      ddim_empty(),
    ) {
    Some(_) => true
    None => false
  }
}

///|
/// Validate a simultaneous induction-recursive block: the base
/// family, every result-type family in its full context, and every
/// case against the corresponding result type with all simultaneous
/// recursive hypotheses present.
pub fn simultaneous_ir_validate(spec : DSimultaneousIRSpec) -> Bool {
  if !inductive_schema_validate(spec.base) || spec.functions.length() == 0 {
    return false
  }
  let names : Array[String] = []
  for i in 0..<spec.functions.length() {
    if spec.functions[i].cases.length() != spec.base.constructors.length() {
      return false
    }
    names.push(spec.functions[i].name)
  }
  if !schema_names_unique(names) {
    return false
  }
  let param_values = schema_fresh_values(spec.base.params.length(), 9800)
  let param_types = inductive_param_types(spec.base, param_values)
  let index_values = schema_fresh_values(spec.base.indices.length(), 9850)
  let index_types = telescope_type_values(
    spec.base.indices,
    param_types,
    param_values,
    index_values,
  )
  let code_value = DVNeutral(DNVar(9900))
  let code_type = DVInductive(spec.base, param_values, index_values)
  for f in 0..<spec.functions.length() {
    let ctx_types = schema_concat_values(
      schema_concat_values(param_types, index_types),
      [code_type],
    )
    let ctx_values = schema_concat_values(
      schema_concat_values(param_values, index_values),
      [code_value],
    )
    match
      d_as_type(
        spec.functions[f].result_type,
        schema_env(ctx_types),
        schema_env(ctx_values),
        ddim_empty(),
      ) {
      Some(_) => ()
      None => return false
    }
    for c in 0..<spec.base.constructors.length() {
      if !simultaneous_case_validate(spec, f, c, param_values, param_types) {
        return false
      }
    }
  }
  true
}

///|
pub fn nat_parity_double_ir() -> DSimultaneousIRSpec {
  dsimultaneous_ir_spec(nat_schema(), [
    dsimultaneous_function("parity", DBoolTy, [
      DBoolLit(true),
      // Context: pred, parity(pred), double(pred); DTVar(1) is the
      // parity hypothesis.
      DBoolElim(DBoolTy, DBoolLit(false), DBoolLit(true), DTVar(1)),
    ]),
    dsimultaneous_function("double", DNatTy, [
      DNatZero,
      // DTVar(0) is the double hypothesis.
      DSucc(DSucc(DTVar(0))),
    ]),
  ])
}

///|
pub fn check_simultaneous_induction_recursion() -> Bool {
  let spec = nat_parity_double_ir()
  let mut three : DValue = DVIntro(spec.base, 0, [], [])
  for _i in 0..<3 {
    three = DVIntro(spec.base, 1, [], [three])
  }
  simultaneous_ir_validate(spec) &&
  conv_at(
    0,
    0,
    DVBoolTy,
    eval_simultaneous_ir(spec, 0, [], [], three, 0),
    DVBool(false),
  ) &&
  conv_at(
    0,
    0,
    DVNatTy,
    eval_simultaneous_ir(spec, 1, [], [], three, 0),
    dv_nat_lit(6),
  )
}

///|
/// A composition whose base is the base point (a face of `loop`)
/// and whose tube traverses the loop cell itself now computes in
/// the lifted cell instead of remaining a formal composition.
pub fn check_hit_moving_dimension_lift() -> Bool {
  let circle = circle_schema()
  let ty = DVHitType(circle, [], [])
  let base = hit_cell_value(circle, 1, [], [], [DZero])
  let branches = dsystem_singleton(FEq0(DVar(0)), j => {
    DVHitCell(circle, 1, [], [], [j])
  })
  let result = hcomp_value(ty, branches, base, 1)
  let canonical = match force_value(result) {
    DVNeutral(_) => false
    _ => true
  }
  canonical && conv_at(0, 1, ty, result, base)
}

// ---------------------------------------------------------------------------
// Compiling one simultaneous function into a plain decode
// ---------------------------------------------------------------------------

///|
/// The universe level of a simultaneous function whose result
/// type computes (at fresh parameters, indices, and a neutral
/// code) to a universe, or -1.  Result types that genuinely
/// depend on the code do not reduce at the neutral probe and are
/// rejected here even when universe-valued.
pub fn simultaneous_ir_function_universe_level(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
) -> Int32 {
  if function_index < 0 || function_index >= spec.functions.length() {
    return -1
  }
  let param_values = schema_fresh_values(spec.base.params.length(), 10600)
  let index_values = schema_fresh_values(spec.base.indices.length(), 10650)
  match
    force_value(
      simultaneous_result_type(
        spec,
        function_index,
        param_values,
        index_values,
        DVNeutral(DNVar(10700)),
      ),
    ) {
    DVUniv(level) => level
    _ => -1
  }
}

///|
fn simultaneous_arg_has_hypothesis(kind : DArgKind) -> Bool {
  match kind {
    DArgExternal | DArgDecoded => false
    _ => true
  }
}

///|
/// Map each position of the simultaneous case context for one
/// constructor (parameters; then per argument the value followed
/// by one hypothesis per function; then constraint proofs) to
/// the corresponding plain-decode context position for
/// `function_index`, with -1 for other functions' hypotheses.
/// Also returns the decode context length.
fn simultaneous_decode_layout(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
  ctor : DConstructorSpec,
) -> (Array[Int32], Int32) {
  let map : Array[Int32] = []
  let mut dec = 0
  for _i in 0..<spec.base.params.length() {
    map.push(dec)
    dec = dec + 1
  }
  for i in 0..<ctor.args.length() {
    map.push(dec)
    dec = dec + 1
    if simultaneous_arg_has_hypothesis(ctor.args[i].kind) {
      for g in 0..<spec.functions.length() {
        map.push(if g == function_index { dec } else { -1 })
      }
      dec = dec + 1
    }
  }
  for _i in 0..<ctor.constraints.length() {
    map.push(dec)
    dec = dec + 1
  }
  (map, dec)
}

///|
/// Whether some case of `function_index` mentions another
/// function's hypothesis (and therefore cannot be compiled to a
/// plain single decode).
pub fn simultaneous_ir_uses_other_hypotheses(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
) -> Bool {
  if function_index < 0 || function_index >= spec.functions.length() {
    return true
  }
  for c in 0..<spec.base.constructors.length() {
    if c >= spec.functions[function_index].cases.length() {
      return true
    }
    let (map, _) = simultaneous_decode_layout(
      spec,
      function_index,
      spec.base.constructors[c],
    )
    let sim_len = map.length()
    let mut foreign = false
    ignore(
      dterm_map_vars_at(spec.functions[function_index].cases[c], 0, (v, depth) => {
        if v >= depth {
          let pos = sim_len - 1 - (v - depth)
          if pos >= 0 && pos < sim_len && map[pos] < 0 {
            foreign = true
          }
        }
        DTVar(v)
      }),
    )
    if foreign {
      return true
    }
  }
  false
}

///|
/// Compile one universe-valued function of a simultaneous
/// induction-recursive block into the plain decode of a copy of
/// the base family (renamed `Base#function`), so the ordinary
/// `DDecode` former, constructor typing with decoded arguments,
/// and `eval_inductive_decode` can consume it.  Compilation is a
/// de Bruijn renumbering of the case terms from the simultaneous
/// case context to the decode case context; it is refused when
/// the block does not validate, when the function is not
/// universe-valued, when any case uses another function's
/// hypothesis (genuine interdependence has no single-decode
/// form), or when the resulting schema fails validation.
pub fn simultaneous_ir_compile_decode(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
) -> DInductiveSpec? {
  if function_index < 0 || function_index >= spec.functions.length() {
    return None
  }
  if !simultaneous_ir_validate(spec) ||
    simultaneous_ir_uses_other_hypotheses(spec, function_index) {
    return None
  }
  let level = simultaneous_ir_function_universe_level(spec, function_index)
  if level < 0 {
    return None
  }
  let decode_cases : Array[DTerm] = []
  for c in 0..<spec.base.constructors.length() {
    let (map, dec_len) = simultaneous_decode_layout(
      spec,
      function_index,
      spec.base.constructors[c],
    )
    let sim_len = map.length()
    let rewritten = dterm_map_vars_at(
      spec.functions[function_index].cases[c],
      0,
      (v, depth) => {
        if v < depth {
          DTVar(v)
        } else {
          let pos = sim_len - 1 - (v - depth)
          if pos >= 0 && pos < sim_len && map[pos] >= 0 {
            DTVar(dec_len - 1 - map[pos] + depth)
          } else {
            DTVar(v)
          }
        }
      },
    )
    decode_cases.push(rewritten)
  }
  let compiled = DInductiveSpec::{
    name: spec.base.name + "#" + spec.functions[function_index].name,
    level: spec.base.level,
    params: spec.base.params,
    indices: spec.base.indices,
    constructors: spec.base.constructors,
    decode_cases,
    decode_level: level,
  }
  if inductive_schema_validate(compiled) &&
    inductive_decode_cases_validate(compiled) {
    Some(compiled)
  } else {
    None
  }
}

///|
fn code_schema_for_simultaneous() -> DInductiveSpec {
  dinductive_spec("CodeS", 0, [], [], [
    dconstructor_spec("cnat", []),
    dconstructor_spec("cbool", []),
    dconstructor_spec("cpair", [
      darg_recursive("first"),
      darg_recursive("second"),
    ]),
    dconstructor_spec("carrow", [darg_recursive("dom"), darg_recursive("cod")]),
  ])
}

///|
/// A small Tarski-style universe given simultaneously with a
/// size function.  The interpretation does not use the size
/// hypotheses, so it compiles to a plain decode (verified in
/// `check_simultaneous_ir_compiled_decode`); the variant whose
/// pair case mentions a size hypothesis does not.
pub fn code_interpretation_ir(use_size : Bool) -> DSimultaneousIRSpec {
  // Binary constructor context positions: a, El a, size a, b,
  // El b, size b (length 6).  El a is DTVar(4); under one binder
  // El b is DTVar(2); size a is DTVar(3).
  let pair_case = if use_size {
    DApp(DLam(DNatTy, DSigma(DTVar(5), DTVar(3))), DTVar(3))
  } else {
    DSigma(DTVar(4), DTVar(2))
  }
  dsimultaneous_ir_spec(code_schema_for_simultaneous(), [
    dsimultaneous_function("El", DUniv(0), [
      DNatTy,
      DBoolTy,
      pair_case,
      DPi(DTVar(4), DTVar(2)),
    ]),
    dsimultaneous_function("size", DNatTy, [
      DSucc(DNatZero),
      DSucc(DNatZero),
      DSucc(DTVar(3)),
      DSucc(DTVar(3)),
    ]),
  ])
}

///|
pub fn check_simultaneous_ir_compiled_decode() -> Bool {
  let spec = code_interpretation_ir(false)
  if !simultaneous_ir_validate(spec) ||
    simultaneous_ir_function_universe_level(spec, 0) != 0 ||
    simultaneous_ir_function_universe_level(spec, 1) != -1 ||
    simultaneous_ir_uses_other_hypotheses(spec, 0) {
    return false
  }
  let compiled = match simultaneous_ir_compile_decode(spec, 0) {
    Some(s) => s
    None => return false
  }
  if compiled.name != "CodeS#El" ||
    compiled.decode_level != 0 ||
    compiled.decode_cases.length() != 4 {
    return false
  }
  // The non-universe function and the size-using variant refuse.
  match simultaneous_ir_compile_decode(spec, 1) {
    Some(_) => return false
    None => ()
  }
  let dependent = code_interpretation_ir(true)
  if !simultaneous_ir_validate(dependent) ||
    !simultaneous_ir_uses_other_hypotheses(dependent, 0) {
    return false
  }
  match simultaneous_ir_compile_decode(dependent, 0) {
    Some(_) => return false
    None => ()
  }
  // Compiled decode agrees with the simultaneous evaluation on
  // concrete codes, semantically and at the term level.
  let cnat_b : DValue = DVIntro(spec.base, 0, [], [])
  let cbool_b : DValue = DVIntro(spec.base, 1, [], [])
  let code_b : DValue = DVIntro(spec.base, 3, [], [
    cnat_b,
    DVIntro(spec.base, 2, [], [cbool_b, cnat_b]),
  ])
  let cnat_c : DValue = DVIntro(compiled, 0, [], [])
  let cbool_c : DValue = DVIntro(compiled, 1, [], [])
  let code_c : DValue = DVIntro(compiled, 3, [], [
    cnat_c,
    DVIntro(compiled, 2, [], [cbool_c, cnat_c]),
  ])
  let expected : DValue = DVPi(DVNatTy, _ => DVSigma(DVBoolTy, _ => DVNatTy))
  if !conv_ty(0, 0, eval_simultaneous_ir(spec, 0, [], [], code_b, 0), expected) ||
    !conv_ty(0, 0, eval_inductive_decode(compiled, [], [], code_c, 0), expected) {
    return false
  }
  let cnat_t = schema_intro_term(compiled, 0, [], [])
  let cbool_t = schema_intro_term(compiled, 1, [], [])
  let code_t = schema_intro_term(compiled, 3, [], [
    cnat_t,
    schema_intro_term(compiled, 2, [], [cbool_t, cnat_t]),
  ])
  dep_check_closed(code_t, schema_type_term(compiled, [])) &&
  dep_nf_closed(decode_term(compiled, [], [], code_t), DUniv(0)) ==
  Some(DPi(DNatTy, DSigma(DBoolTy, DNatTy)))
}

// ---------------------------------------------------------------------------
// Phase 12: simultaneous IR compilation to eliminators over the
// base family.
//
// `simultaneous_ir_compile_decode` cannot express cases that
// mention another function's hypotheses: the compiled decode
// lives on a renamed copy of the base family, and a nested
// `DDecode` over a different copy would be ill-typed (family
// identity is the whole spec).  The eliminator route compiles
// the whole block, in declaration order, to closed terms
// over the *original* base spec:
//
//   λ params. λ indices. λ code.
//     DInductiveElim(base, λ indices code. Type_l, cases, ...)
//
// Another function's hypothesis slot is substituted by that
// function's compiled eliminator term applied to the recursive
// argument (under a lambda for function arguments) -- family
// identity matches throughout because everything stays over
// `base`.  Forward or cyclic interdependence, hypotheses of
// non-universe functions, and constructors with nested or
// decoded arguments are refused.  The eliminator motive is
// predicative: a function landing in `Type_l` needs
// `l < base.level` (the motive's codomain universe is the
// base family's level), unlike the decode route, whose cases
// are checked directly as types.  Every produced term is
// verified before being returned: `dep_check_closed` against
// its advertised Pi type, plus a forcing check that applies
// the (lazily checked) motive and case lambdas to fresh
// neutrals so their bodies are actually typechecked.
// ---------------------------------------------------------------------------

///|
/// Rewrite a term from a source scope (positions given by
/// `target_pos`, with -2 denoting one distinguished extra
/// binder) into a target context of length `total_len`.
fn sim_elim_rewrite(
  term : DTerm,
  scope_len : Int32,
  target_pos : Array[Int32],
  total_len : Int32,
) -> DTerm {
  dterm_map_vars_at(term, 0, (v, depth) => {
    if v < depth {
      DTVar(v)
    } else {
      let pos = scope_len - 1 - (v - depth)
      if pos >= 0 && pos < target_pos.length() {
        let tp = target_pos[pos]
        if tp == -2 {
          DTVar(depth)
        } else if tp >= 0 {
          DTVar(total_len - 1 - tp + depth)
        } else {
          DTVar(v)
        }
      } else {
        DTVar(v)
      }
    }
  })
}

///|
fn sim_elim_vars_at(
  total_len : Int32,
  positions : Array[Int32],
) -> Array[DTerm] {
  let out : Array[DTerm] = []
  for i in 0..<positions.length() {
    out.push(DTVar(total_len - 1 - positions[i]))
  }
  out
}

///|
fn sim_elim_positions(count : Int32, offset : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<count {
    out.push(offset + i)
  }
  out
}

///|
/// The Pi type of the compiled eliminator term for one
/// universe-valued function: parameters, indices, code, then
/// the universe at the function's level.  `None` for
/// non-universe-valued functions.
pub fn simultaneous_ir_eliminator_type(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
) -> DTerm? {
  let level = simultaneous_ir_function_universe_level(spec, function_index)
  if level < 0 {
    return None
  }
  let param_count = spec.base.params.length()
  let index_count = spec.base.indices.length()
  let outer = param_count + index_count
  let code_ty = DInductive(
    spec.base,
    sim_elim_vars_at(outer, sim_elim_positions(param_count + index_count, 0)),
  )
  let mut ty = DPi(code_ty, DUniv(level))
  let mut j = index_count - 1
  while j >= 0 {
    ty = DPi(spec.base.indices[j].ty, ty)
    j = j - 1
  }
  let mut p = param_count - 1
  while p >= 0 {
    ty = DPi(spec.base.params[p].ty, ty)
    p = p - 1
  }
  Some(ty)
}

///|
fn sim_elim_motive(spec : DSimultaneousIRSpec, level : Int32) -> DTerm {
  let param_count = spec.base.params.length()
  let index_count = spec.base.indices.length()
  let outer = param_count + index_count + 1
  // Scrutinee binder domain, at context outer + index_count.
  let scrut_total = outer + index_count
  let scrut_args : Array[DTerm] = []
  for p in 0..<param_count {
    scrut_args.push(DTVar(scrut_total - 1 - p))
  }
  for t in 0..<index_count {
    scrut_args.push(DTVar(index_count - 1 - t))
  }
  let mut motive = DLam(DInductive(spec.base, scrut_args), DUniv(level))
  let mut j = index_count - 1
  while j >= 0 {
    // Index telescope types are in scope (params, prior
    // indices); at motive binder j the context is the ambient
    // outer context followed by j motive index binders.
    let target_pos : Array[Int32] = []
    for p in 0..<param_count {
      target_pos.push(p)
    }
    for t in 0..<j {
      target_pos.push(outer + t)
    }
    let dom = sim_elim_rewrite(
      spec.base.indices[j].ty,
      param_count + j,
      target_pos,
      outer + j,
    )
    motive = DLam(dom, motive)
    j = j - 1
  }
  motive
}

///|
/// Apply the compiled term of foreign function `g` (closed,
/// universe-valued) to the ambient parameters, rewritten
/// indices, and one recursive value, in a context of length
/// `total` whose first positions are the base parameters.
fn sim_elim_apply_g(
  g_term : DTerm,
  param_count : Int32,
  total : Int32,
  indices : Array[DTerm],
  code : DTerm,
) -> DTerm {
  let mut app = g_term
  for p in 0..<param_count {
    app = DApp(app, DTVar(total - 1 - p))
  }
  for i in 0..<indices.length() {
    app = DApp(app, indices[i])
  }
  DApp(app, code)
}

///|
fn sim_elim_rewrite_all(
  terms : Array[DTerm],
  target_pos : Array[Int32],
  total : Int32,
) -> Array[DTerm] {
  let out : Array[DTerm] = []
  for i in 0..<terms.length() {
    out.push(sim_elim_rewrite(terms[i], target_pos.length(), target_pos, total))
  }
  out
}

///|
fn sim_elim_extend_pos(target_pos : Array[Int32], pos : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<target_pos.length() {
    out.push(target_pos[i])
  }
  out.push(pos)
  out
}

///|
/// Term for the *type* a positive functor assigns to the base
/// family, mirroring `positive_functor_type` for the fragment
/// the foreign-bundle builder covers.  `target_pos` maps the
/// functor's source scope (parameters, prior constructor
/// arguments, functor-local binders) to absolute positions in
/// a context of length `total`.  `None` outside the fragment
/// (sums and family applications).
fn sim_elim_functor_type_term(
  base : DInductiveSpec,
  functor : DPositiveFunctor,
  target_pos : Array[Int32],
  total : Int32,
) -> DTerm? {
  match functor {
    DFunctorIdentity(index) => {
      let args = sim_elim_vars_at(
        total,
        sim_elim_positions(base.params.length(), 0),
      )
      let idx = sim_elim_rewrite_all(index, target_pos, total)
      for i in 0..<idx.length() {
        args.push(idx[i])
      }
      Some(DInductive(base, args))
    }
    DFunctorConst(ty) =>
      Some(sim_elim_rewrite(ty, target_pos.length(), target_pos, total))
    DFunctorProduct(a, b) =>
      match
        (
          sim_elim_functor_type_term(base, a, target_pos, total),
          sim_elim_functor_type_term(base, b, target_pos, total),
        ) {
        (Some(ta), Some(tb)) => Some(DSigma(ta, dterm_shift(tb, 0, 1)))
        _ => None
      }
    DFunctorSigma(a, b) =>
      match
        (
          sim_elim_functor_type_term(base, a, target_pos, total),
          sim_elim_functor_type_term(
            base,
            b,
            sim_elim_extend_pos(target_pos, total),
            total + 1,
          ),
        ) {
        (Some(ta), Some(tb)) => Some(DSigma(ta, tb))
        _ => None
      }
    DFunctorPi(dom, inner) =>
      match
        sim_elim_functor_type_term(
          base,
          inner,
          sim_elim_extend_pos(target_pos, total),
          total + 1,
        ) {
        Some(tb) =>
          Some(
            DPi(
              sim_elim_rewrite(dom, target_pos.length(), target_pos, total),
              tb,
            ),
          )
        None => None
      }
    DFunctorList(inner) =>
      match sim_elim_functor_type_term(base, inner, target_pos, total) {
        Some(elem) => Some(DListTy(elem))
        None => None
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
      let args = sim_elim_vars_at(
        total + 2,
        sim_elim_positions(base.params.length(), 0),
      )
      let idx = sim_elim_rewrite_all(index, tp3, total + 2)
      for i in 0..<idx.length() {
        args.push(idx[i])
      }
      Some(DSigma(shape_t, DPi(pos_t, DInductive(base, args))))
    }
    DFunctorSum(a, b) =>
      match
        (
          sim_elim_functor_type_term(base, a, target_pos, total),
          sim_elim_functor_type_term(base, b, target_pos, total),
        ) {
        (Some(ta), Some(tb)) =>
          Some(
            DSigma(
              DBoolTy,
              DBoolElim(
                DUniv(base.level),
                dterm_shift(ta, 0, 1),
                dterm_shift(tb, 0, 1),
                DTVar(0),
              ),
            ),
          )
        _ => None
      }
    DFunctorFamily(_) | DFunctorSelfFamily(_) => None
  }
}

///|
/// Term for the foreign induction-hypothesis *bundle type* of
/// one nested value, mirroring `positive_functor_ih_type`.
/// The compiled eliminator's motive is constant, so every
/// identity leaf of the bundle type is the foreign function's
/// result universe itself (the leaf *value* is the computed
/// type; its type is that universe).  Dependent positions
/// that the semantic
/// bundle reads off the value (`Sigma` first components,
/// container shapes) are named by a beta-redex so the source
/// scope stays variable-only.  `None` outside the supported
/// functor fragment.
fn sim_elim_bundle_type_term(
  base : DInductiveSpec,
  g_level : Int32,
  functor : DPositiveFunctor,
  value : DTerm,
  target_pos : Array[Int32],
  total : Int32,
) -> DTerm? {
  match functor {
    DFunctorIdentity(_) => Some(DUniv(g_level))
    DFunctorConst(_) => Some(DUnitTy)
    DFunctorProduct(a, b) =>
      match
        (
          sim_elim_bundle_type_term(
            base,
            g_level,
            a,
            DFst(value),
            target_pos,
            total,
          ),
          sim_elim_bundle_type_term(
            base,
            g_level,
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
        sim_elim_bundle_type_term(
          base,
          g_level,
          a,
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let second = match
        sim_elim_bundle_type_term(
          base,
          g_level,
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
        sim_elim_bundle_type_term(
          base,
          g_level,
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
      ignore(tp3)
      ignore(index)
      Some(DApp(DLam(shape_t, DPi(pos_t, DUniv(g_level))), DFst(value)))
    }
    DFunctorList(inner) => {
      let elem = match
        sim_elim_functor_type_term(base, inner, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let head_ty = match
        sim_elim_bundle_type_term(
          base,
          g_level,
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
          DLam(DUniv(base.level), DSigma(head_ty, DTVar(1))),
        ),
      )
      // Eliminator motives in this kernel are open bodies
      // (the scrutinee is the bound variable), not lambdas.
      Some(DListElim(DUniv(base.level), DUnitTy, step, value))
    }
    DFunctorSum(a, b) =>
      match
        (
          sim_elim_bundle_type_term(
            base,
            g_level,
            a,
            DSnd(value),
            target_pos,
            total,
          ),
          sim_elim_bundle_type_term(
            base,
            g_level,
            b,
            DSnd(value),
            target_pos,
            total,
          ),
        ) {
        (Some(ta), Some(tb)) =>
          Some(DBoolElim(DUniv(base.level), ta, tb, DFst(value)))
        _ => None
      }
    DFunctorFamily(_) | DFunctorSelfFamily(_) => None
  }
}

///|
/// Term for the foreign induction-hypothesis bundle of one
/// nested value: the functorial map of the foreign compiled
/// eliminator over the value's recursive positions, mirroring
/// `positive_functor_map`.  Same fragment and conventions as
/// `sim_elim_bundle_type_term`.
fn sim_elim_bundle_map_term(
  base : DInductiveSpec,
  g_term : DTerm,
  g_level : Int32,
  functor : DPositiveFunctor,
  value : DTerm,
  target_pos : Array[Int32],
  total : Int32,
) -> DTerm? {
  let pc = base.params.length()
  match functor {
    DFunctorIdentity(index) =>
      Some(
        sim_elim_apply_g(
          g_term,
          pc,
          total,
          sim_elim_rewrite_all(index, target_pos, total),
          value,
        ),
      )
    DFunctorConst(_) => Some(DUnitLit)
    DFunctorProduct(a, b) =>
      match
        (
          sim_elim_bundle_map_term(
            base,
            g_term,
            g_level,
            a,
            DFst(value),
            target_pos,
            total,
          ),
          sim_elim_bundle_map_term(
            base,
            g_term,
            g_level,
            b,
            DSnd(value),
            target_pos,
            total,
          ),
        ) {
        (Some(x), Some(y)) => Some(DPair(x, y))
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
        sim_elim_bundle_map_term(
          base,
          g_term,
          g_level,
          a,
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let second = match
        sim_elim_bundle_map_term(
          base,
          g_term,
          g_level,
          b,
          DSnd(shifted),
          tp2,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      Some(DApp(DLam(ta, DPair(first, second)), DFst(value)))
    }
    DFunctorPi(dom, inner) => {
      let body = match
        sim_elim_bundle_map_term(
          base,
          g_term,
          g_level,
          inner,
          DApp(dterm_shift(value, 0, 1), DTVar(0)),
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
      let leaf = sim_elim_apply_g(
        g_term,
        pc,
        total + 2,
        sim_elim_rewrite_all(index, tp3, total + 2),
        DApp(DSnd(dterm_shift(value, 0, 2)), DTVar(0)),
      )
      Some(DApp(DLam(shape_t, DLam(pos_t, leaf)), DFst(value)))
    }
    DFunctorList(inner) => {
      let elem = match
        sim_elim_functor_type_term(base, inner, target_pos, total) {
        Some(v) => v
        None => return None
      }
      let motive_ty = match
        sim_elim_bundle_type_term(
          base,
          g_level,
          DFunctorList(inner),
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let tail_ty = match
        sim_elim_bundle_type_term(
          base,
          g_level,
          DFunctorList(inner),
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let head = match
        sim_elim_bundle_map_term(
          base,
          g_term,
          g_level,
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
          DLam(tail_ty, DPair(head, DTVar(0))),
        ),
      )
      Some(DListElim(motive_ty, DUnitLit, step, value))
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
      let ba_ty = match
        sim_elim_bundle_type_term(
          base,
          g_level,
          a,
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let bb_ty = match
        sim_elim_bundle_type_term(
          base,
          g_level,
          b,
          DTVar(0),
          target_pos,
          total + 2,
        ) {
        Some(v) => v
        None => return None
      }
      let ma = match
        sim_elim_bundle_map_term(
          base,
          g_term,
          g_level,
          a,
          DTVar(0),
          target_pos,
          total + 1,
        ) {
        Some(v) => v
        None => return None
      }
      let mb = match
        sim_elim_bundle_map_term(
          base,
          g_term,
          g_level,
          b,
          DTVar(0),
          target_pos,
          total + 1,
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
        DBoolElim(DUniv(base.level), ba_ty, bb_ty, DTVar(1)),
      )
      Some(
        DApp(
          DBoolElim(motive_sum, DLam(ta, ma), DLam(tb, mb), DFst(value)),
          DSnd(value),
        ),
      )
    }
    DFunctorFamily(_) | DFunctorSelfFamily(_) => None
  }
}

///|
fn sim_elim_foreign_term(
  spec : DSimultaneousIRSpec,
  compiled : Array[DTerm?],
  ctor : DConstructorSpec,
  arg_index : Int32,
  g : Int32,
  arg_bind_pos : Array[Int32],
  outer : Int32,
  body_total : Int32,
  depth : Int32,
) -> DTerm? {
  let g_term = match compiled[g] {
    Some(v) => v
    None => return None
  }
  let arg = ctor.args[arg_index]
  let param_count = spec.base.params.length()
  let target_pos : Array[Int32] = []
  for p in 0..<param_count {
    target_pos.push(p)
  }
  for j in 0..<arg_index {
    target_pos.push(outer + arg_bind_pos[j])
  }
  let apply_g = (total : Int32, indices : Array[DTerm], code : DTerm) => {
    let mut app = g_term
    for p in 0..<param_count {
      app = DApp(app, DTVar(total - 1 - p))
    }
    for i in 0..<indices.length() {
      app = DApp(app, indices[i])
    }
    DApp(app, code)
  }
  match arg.kind {
    DArgRecursive => {
      let total = body_total + depth
      let indices : Array[DTerm] = []
      for i in 0..<arg.index.length() {
        indices.push(
          sim_elim_rewrite(
            arg.index[i],
            param_count + arg_index,
            target_pos,
            total,
          ),
        )
      }
      Some(
        apply_g(
          total,
          indices,
          DTVar(total - 1 - (outer + arg_bind_pos[arg_index])),
        ),
      )
    }
    DArgFunction => {
      let total = body_total + depth
      let dom = sim_elim_rewrite(
        arg.ty,
        param_count + arg_index,
        target_pos,
        total,
      )
      let inner_total = total + 1
      let inner_target : Array[Int32] = []
      for i in 0..<target_pos.length() {
        inner_target.push(target_pos[i])
      }
      inner_target.push(-2)
      let indices : Array[DTerm] = []
      for i in 0..<arg.index.length() {
        indices.push(
          sim_elim_rewrite(
            arg.index[i],
            param_count + arg_index + 1,
            inner_target,
            inner_total,
          ),
        )
      }
      Some(
        DLam(
          dom,
          apply_g(
            inner_total,
            indices,
            DApp(
              DTVar(inner_total - 1 - (outer + arg_bind_pos[arg_index])),
              DTVar(0),
            ),
          ),
        ),
      )
    }
    DArgNested => {
      // The bundle is wrapped in a type annotation: pair
      // introductions are check-only in this kernel, so
      // without the annotation the substituted bundle could
      // never be *inferred* at the projections and
      // applications the case body performs on the hypothesis
      // variable it replaces.
      let value = DTVar(
        body_total + depth - 1 - (outer + arg_bind_pos[arg_index]),
      )
      let g_level = simultaneous_ir_function_universe_level(spec, g)
      if g_level < 0 {
        return None
      }
      match
        (
          sim_elim_bundle_map_term(
            spec.base,
            g_term,
            g_level,
            arg.nested,
            value,
            target_pos,
            body_total + depth,
          ),
          sim_elim_bundle_type_term(
            spec.base,
            g_level,
            arg.nested,
            value,
            target_pos,
            body_total + depth,
          ),
        ) {
        (Some(bundle), Some(bundle_ty)) => Some(DAnn(bundle, bundle_ty))
        _ => None
      }
    }
    _ => None
  }
}

///|
fn sim_elim_compile_one(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
  compiled : Array[DTerm?],
) -> DTerm? {
  let level = simultaneous_ir_function_universe_level(spec, function_index)
  if level < 0 {
    return None
  }
  let base = spec.base
  if level >= base.level {
    return None
  }
  let param_count = base.params.length()
  let index_count = base.indices.length()
  let outer = param_count + index_count + 1
  let function_count = spec.functions.length()
  let cases : Array[DTerm] = []
  for c in 0..<base.constructors.length() {
    let ctor = base.constructors[c]
    // Binder layout of the eliminator case telescope.
    let bind_kinds : Array[Int32] = [] // 0 arg, 1 IH, 2 constraint
    let bind_args : Array[Int32] = []
    let arg_bind_pos : Array[Int32] = []
    let ih_bind_pos : Array[Int32] = []
    for i in 0..<ctor.args.length() {
      let kind = ctor.args[i].kind
      match kind {
        DArgExternal | DArgRecursive | DArgFunction | DArgNested => ()
        _ => return None
      }
      arg_bind_pos.push(bind_kinds.length())
      bind_kinds.push(0)
      bind_args.push(i)
      if simultaneous_arg_has_hypothesis(kind) {
        ih_bind_pos.push(bind_kinds.length())
        bind_kinds.push(1)
        bind_args.push(i)
      } else {
        ih_bind_pos.push(-1)
      }
    }
    let constraint_bind_start = bind_kinds.length()
    for k in 0..<ctor.constraints.length() {
      bind_kinds.push(2)
      bind_args.push(k)
    }
    let binder_count = bind_kinds.length()
    let body_total = outer + binder_count
    // Domains, obtained by quoting the kernel's own case
    // type (with the constant universe motive the compiled
    // eliminator uses) binder by binder.  Parameters and case
    // binders are neutrals at their de Bruijn levels in the
    // target context, so quoting at `outer + r` places every
    // reference correctly; this uniformly covers nested
    // argument and bundle domains that have no simple manual
    // term form.
    let domains : Array[DTerm] = []
    {
      let param_values : Array[DValue] = []
      for p in 0..<param_count {
        param_values.push(DVNeutral(DNVar(p)))
      }
      let mut case_ty = inductive_case_type(
        base,
        (_idx, _code) => DVUniv(level),
        param_values,
        c,
      )
      let mut peel_failed = false
      for r in 0..<binder_count {
        match as_pi(case_ty) {
          Some(parts) => {
            domains.push(quote_at(outer + r, 0, DVUniv(base.level), parts.dom))
            case_ty = (parts.fam)(DVNeutral(DNVar(outer + r)))
          }
          None => peel_failed = true
        }
        if peel_failed {
          break
        }
      }
      if peel_failed {
        return None
      }
    }
    // Simultaneous-context layout for this constructor.
    let sim_pos_of_arg : Array[Int32] = []
    let sim_pos_of_ih : Array[Array[Int32]] = []
    let mut sim_len = param_count
    for i in 0..<ctor.args.length() {
      sim_pos_of_arg.push(sim_len)
      sim_len = sim_len + 1
      let slots : Array[Int32] = []
      if simultaneous_arg_has_hypothesis(ctor.args[i].kind) {
        for _g in 0..<function_count {
          slots.push(sim_len)
          sim_len = sim_len + 1
        }
      }
      sim_pos_of_ih.push(slots)
    }
    let sim_constraint_start = sim_len
    sim_len = sim_len + ctor.constraints.length()
    let mut failed = false
    let body = dterm_map_vars_at(spec.functions[function_index].cases[c], 0, (
      v,
      depth,
    ) => {
      if v < depth {
        DTVar(v)
      } else {
        let pos = sim_len - 1 - (v - depth)
        if pos < 0 || pos >= sim_len {
          DTVar(v)
        } else if pos < param_count {
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
                if g == function_index {
                  out = DTVar(body_total - 1 - (outer + ih_bind_pos[i]) + depth)
                } else {
                  match
                    sim_elim_foreign_term(
                      spec, compiled, ctor, i, g, arg_bind_pos, outer, body_total,
                      depth,
                    ) {
                    Some(term) => out = term
                    None => failed = true
                  }
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
      return None
    }
    let mut case_term = body
    let mut r = binder_count - 1
    while r >= 0 {
      case_term = DLam(domains[r], case_term)
      r = r - 1
    }
    cases.push(case_term)
  }
  let elim = DInductiveElim(
    base,
    sim_elim_motive(spec, level),
    cases,
    sim_elim_vars_at(outer, sim_elim_positions(param_count, 0)),
    sim_elim_vars_at(outer, sim_elim_positions(index_count, param_count)),
    DTVar(0),
  )
  let code_ty = DInductive(
    base,
    sim_elim_vars_at(
      param_count + index_count,
      sim_elim_positions(param_count + index_count, 0),
    ),
  )
  let mut term = DLam(code_ty, elim)
  let mut j = index_count - 1
  while j >= 0 {
    term = DLam(base.indices[j].ty, term)
    j = j - 1
  }
  let mut p = param_count - 1
  while p >= 0 {
    term = DLam(base.params[p].ty, term)
    p = p - 1
  }
  match simultaneous_ir_eliminator_type(spec, function_index) {
    Some(ty) =>
      if dep_check_closed(term, ty) && sim_elim_verify_cases(spec, level, cases) {
        Some(term)
      } else {
        None
      }
    None => None
  }
}

///|
/// Forcing verification of compiled eliminator cases: the
/// motive and the case lambdas (whose bodies the bidirectional
/// checker only validates on application) are applied to fresh
/// neutral arguments in the outer context, so every body is
/// genuinely typechecked.  A body whose check fails surfaces
/// as the `DVUnit` unwrap sentinel.
fn sim_elim_verify_cases(
  spec : DSimultaneousIRSpec,
  level : Int32,
  cases : Array[DTerm],
) -> Bool {
  let base = spec.base
  let param_values = schema_fresh_values(base.params.length(), 12100)
  let param_types = inductive_param_types(base, param_values)
  let index_values = schema_fresh_values(base.indices.length(), 12200)
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
  let code_value : DValue = DVNeutral(DNVar(12300))
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
    d_check(
      sim_elim_motive(spec, level),
      inductive_motive_type(base, param_values),
      ctx,
      env,
      ddim_empty(),
    ) {
    Some(v) => v
    None => return false
  }
  let motive_fn = inductive_motive_from_value(base, param_values, motive_value)
  match force_value(motive_fn(index_values, code_value)) {
    DVUniv(l) => if l != level { return false }
    _ => return false
  }
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
          let fresh : DValue = DVNeutral(DNVar(12400 + c * 40 + step))
          cur = dapp_typed(cur, fresh, parts.dom)
          ty = (parts.fam)(fresh)
          step = step + 1
        }
        None => break
      }
    }
    match force_value(cur) {
      DVUnit => return false
      _ => ()
    }
  }
  true
}

///|
/// Compile a simultaneous block to eliminator terms over the
/// base family, in declaration order (see the section doc).
/// The result aligns with `spec.functions`; uncompilable
/// functions are `None`, as is every entry when the block does
/// not validate.
pub fn simultaneous_ir_compile_eliminator_block(
  spec : DSimultaneousIRSpec,
) -> Array[DTerm?] {
  let compiled : Array[DTerm?] = []
  for _i in 0..<spec.functions.length() {
    compiled.push(None)
  }
  if !simultaneous_ir_validate(spec) {
    return compiled
  }
  for fi in 0..<spec.functions.length() {
    compiled[fi] = sim_elim_compile_one(spec, fi, compiled)
  }
  compiled
}

///|
pub fn simultaneous_ir_compile_eliminator(
  spec : DSimultaneousIRSpec,
  function_index : Int32,
) -> DTerm? {
  if function_index < 0 || function_index >= spec.functions.length() {
    return None
  }
  simultaneous_ir_compile_eliminator_block(spec)[function_index]
}
