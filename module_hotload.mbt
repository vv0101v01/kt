///|
// Runtime hot-loading for the compiled module environment.
//
// SPEC section 4 keeps "module linking targets static acyclic DAGs
// rather than dynamic runtime hot-loading".  This file closes that
// half of the boundary, on the terms the rest of the project already
// uses: `CompiledModule` carries an `interface_hash` and an
// `implementation_hash`, and the linker resolves imports through
// `ModuleDependencyFingerprint{ path, interface_hash }`.  That is
// exactly the information needed to decide, at runtime, whether a
// replacement object can be swapped underneath live dependents.
//
// The invariant that makes this safe is stated and checked, not
// assumed:
//
//   CONSISTENCY.  For every installed module M and every dependency
//   fingerprint d of M, the installed object at d.path has
//   interface_hash == d.interface_hash.
//
// A swap that leaves the interface hash unchanged (an opaque
// implementation change) preserves consistency by construction and
// needs no dependent work.  A swap that changes the interface hash
// invalidates exactly its dependents, which must be supplied as
// replacement objects in the same transaction.  Every apply verifies
// consistency afterwards and rolls back if it does not hold, so a
// failed hot load can never leave the environment in a state the
// static linker would have rejected.
//
// What this deliberately does NOT do: it does not recompile from
// source (dependents arrive as already-compiled objects), it does not
// handle cycles (the DAG discipline is kept), and it does not make
// any claim about concurrent mutation from several threads.

///|
/// What a proposed hot load would do, decided before anything is
/// mutated.
pub enum HotLoadDecision {
  /// No object is installed at this path yet; this is a pure addition.
  HotAdd
  /// Interface hash unchanged: swap in place, dependents unaffected.
  HotOpaqueSwap
  /// Interface hash changed: the listed dependents are now stale and
  /// must be supplied as replacement objects.
  HotRelink(Array[String])
  /// Rejected before any mutation, with a reason.
  HotReject(String)
} derive(Debug, Eq)

///|
pub extend HotLoadDecision with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadDecision with Eq::{not_equal, equal}

///|
/// One entry in the hot-load audit log.
pub struct HotLoadRecord {
  path : String
  /// Epoch after a successful apply; the pre-apply epoch otherwise.
  epoch : Int32
  interface_changed : Bool
  /// How many replacement objects were installed alongside.
  replacements : Int32
  rolled_back : Bool
  /// Empty on success; the rejection or rollback reason otherwise.
  reason : String
} derive(Debug, Eq)

///|
pub extend HotLoadRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadRecord with Eq::{not_equal, equal}

///|
/// The outcome of one `hot_load_apply`.
pub struct HotLoadReport {
  accepted : Bool
  epoch_before : Int32
  epoch_after : Int32
  interface_changed : Bool
  /// Dependents that were stale after the change.
  stale : Array[String]
  replacements : Int32
  rolled_back : Bool
  reason : String
} derive(Debug, Eq)

///|
pub extend HotLoadReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadReport with Eq::{not_equal, equal}

///|
/// A live module environment that can be updated at runtime.
pub struct HotLoadEnv {
  mut modules : Array[CompiledModule]
  mut epoch : Int32
  mut history : Array[HotLoadRecord]
} derive(Debug, Eq)

///|
pub extend HotLoadEnv with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadEnv with Eq::{not_equal, equal}

// ---------------------------------------------------------------------------
// Construction and inspection
// ---------------------------------------------------------------------------

///|
pub fn hot_load_env_new(compiled_env : CompiledModuleEnv) -> HotLoadEnv {
  let modules : Array[CompiledModule] = []
  for i in 0..<compiled_env.modules.length() {
    modules.push(compiled_env.modules[i])
  }
  HotLoadEnv::{ modules, epoch: 0, history: [], }
}

///|
/// Project back to the static compiled environment the linker wants.
pub fn hot_load_env_to_compiled(env : HotLoadEnv) -> CompiledModuleEnv {
  let out = compiled_module_env_new()
  for i in 0..<env.modules.length() {
    ignore(compiled_module_env_add(out, env.modules[i]))
  }
  out
}

///|
pub fn hot_load_env_epoch(env : HotLoadEnv) -> Int32 {
  env.epoch
}

///|
pub fn hot_load_env_history(env : HotLoadEnv) -> Array[HotLoadRecord] {
  env.history
}

///|
pub fn hot_load_env_modules(env : HotLoadEnv) -> Array[CompiledModule] {
  env.modules
}

///|
fn hot_load_find(env : HotLoadEnv, path : String) -> CompiledModule? {
  for i in 0..<env.modules.length() {
    if env.modules[i].module_path == path {
      return Some(env.modules[i])
    }
  }
  None
}

///|
/// Modules installed at runtime that import `path`.
pub fn hot_load_dependents(env : HotLoadEnv, path : String) -> Array[String] {
  let out : Array[String] = []
  for i in 0..<env.modules.length() {
    let m = env.modules[i]
    if m.module_path == path {
      continue
    }
    for j in 0..<m.dependencies.length() {
      if m.dependencies[j].path == path {
        out.push(m.module_path)
        break
      }
    }
  }
  out
}

// ---------------------------------------------------------------------------
// The invariant
// ---------------------------------------------------------------------------

///|
/// CONSISTENCY: every installed module's dependency fingerprints match
/// the interface hashes actually installed.  A static linker would
/// accept exactly the environments for which this holds.
pub fn hot_load_consistent(env : HotLoadEnv) -> Bool {
  for i in 0..<env.modules.length() {
    if !compiled_module_validate(env.modules[i]) {
      return false
    }
    let deps = env.modules[i].dependencies
    for j in 0..<deps.length() {
      match hot_load_find(env, deps[j].path) {
        None => return false
        Some(installed) =>
          if installed.interface_hash != deps[j].interface_hash {
            return false
          }
      }
    }
  }
  true
}

///|
/// Modules that are stale under the current environment, i.e. those
/// whose recorded dependency interface hash no longer matches.
pub fn hot_load_stale_modules(env : HotLoadEnv) -> Array[String] {
  let out : Array[String] = []
  for i in 0..<env.modules.length() {
    let deps = env.modules[i].dependencies
    for j in 0..<deps.length() {
      match hot_load_find(env, deps[j].path) {
        None => {
          out.push(env.modules[i].module_path)
          break
        }
        Some(installed) =>
          if installed.interface_hash != deps[j].interface_hash {
            out.push(env.modules[i].module_path)
            break
          }
      }
    }
  }
  out
}

// ---------------------------------------------------------------------------
// Planning and applying
// ---------------------------------------------------------------------------

///|
fn hot_load_dependency_problem(
  env : HotLoadEnv,
  incoming : CompiledModule,
) -> String? {
  for i in 0..<incoming.dependencies.length() {
    let dep = incoming.dependencies[i]
    match hot_load_find(env, dep.path) {
      None => return Some("missing dependency: " + dep.path)
      Some(installed) =>
        if installed.interface_hash != dep.interface_hash {
          return Some("stale dependency interface: " + dep.path)
        }
    }
  }
  None
}

///|
/// Decide what a proposed replacement would do, without mutating
/// anything.
pub fn hot_load_plan(
  env : HotLoadEnv,
  incoming : CompiledModule,
) -> HotLoadDecision {
  if incoming.module_path.length() == 0 {
    return HotReject("empty module path")
  }
  if !compiled_module_validate(incoming) {
    return HotReject("object failed validation")
  }
  match hot_load_dependency_problem(env, incoming) {
    Some(reason) => return HotReject(reason)
    None => ()
  }
  match hot_load_find(env, incoming.module_path) {
    None => HotAdd
    Some(installed) =>
      if installed.interface_hash == incoming.interface_hash {
        HotOpaqueSwap
      } else {
        HotRelink(hot_load_dependents(env, incoming.module_path))
      }
  }
}

///|
fn hot_load_modules_copy(env : HotLoadEnv) -> Array[CompiledModule] {
  let out : Array[CompiledModule] = []
  for i in 0..<env.modules.length() {
    out.push(env.modules[i])
  }
  out
}

///|
fn hot_load_upsert(
  modules : Array[CompiledModule],
  m : CompiledModule,
) -> Array[CompiledModule] {
  let out : Array[CompiledModule] = []
  let mut seen = false
  for i in 0..<modules.length() {
    if modules[i].module_path == m.module_path {
      out.push(m)
      seen = true
    } else {
      out.push(modules[i])
    }
  }
  if !seen {
    out.push(m)
  }
  out
}

///|
/// Apply a replacement transactionally.
///
/// `replacements` are already-compiled objects for dependents left
/// stale by an interface change.  The swap is committed only if the
/// resulting environment satisfies CONSISTENCY; otherwise the
/// previous environment is restored bit for bit and the report says
/// so.
pub fn hot_load_apply(
  env : HotLoadEnv,
  incoming : CompiledModule,
  replacements~ : Array[CompiledModule] = [],
) -> HotLoadReport {
  let epoch_before = env.epoch
  let decision = hot_load_plan(env, incoming)
  // A pre-mutation rejection still belongs in the audit log: the log
  // records every attempt, not only the ones that changed state.
  match decision {
    HotReject(reason) => {
      env.history.push(HotLoadRecord::{
        path: incoming.module_path,
        epoch: epoch_before,
        interface_changed: false,
        replacements: replacements.length(),
        rolled_back: false,
        reason,
      })
      return HotLoadReport::{
        accepted: false,
        epoch_before,
        epoch_after: epoch_before,
        interface_changed: false,
        stale: [],
        replacements: replacements.length(),
        rolled_back: false,
        reason,
      }
    }
    _ => ()
  }
  let stale : Array[String] = match decision {
    HotReject(_) => []
    HotAdd => []
    HotOpaqueSwap => []
    HotRelink(paths) => paths
  }
  let interface_changed = match decision {
    HotRelink(_) => true
    _ => false
  }
  // Snapshot for rollback.
  let snapshot = hot_load_modules_copy(env)
  let snapshot_history : Array[HotLoadRecord] = []
  for i in 0..<env.history.length() {
    snapshot_history.push(env.history[i])
  }
  // Mutate.
  let mut next = hot_load_upsert(snapshot, incoming)
  for i in 0..<replacements.length() {
    next = hot_load_upsert(next, replacements[i])
  }
  env.modules = next
  // Verify before committing.
  let ok = hot_load_consistent(env)
  if !ok {
    let reason = match hot_load_stale_modules(env).length() {
      0 => "post-swap environment failed validation"
      _ => {
        let stale_names = hot_load_stale_modules(env)
        "stale after swap: " + stale_names[0]
      }
    }
    // Roll back: restore modules and history exactly.
    let restored : Array[CompiledModule] = []
    for i in 0..<snapshot.length() {
      restored.push(snapshot[i])
    }
    env.modules = restored
    let hist : Array[HotLoadRecord] = []
    for i in 0..<snapshot_history.length() {
      hist.push(snapshot_history[i])
    }
    env.history = hist
    env.history.push(HotLoadRecord::{
      path: incoming.module_path,
      epoch: epoch_before,
      interface_changed,
      replacements: replacements.length(),
      rolled_back: true,
      reason,
    })
    return HotLoadReport::{
      accepted: false,
      epoch_before,
      epoch_after: epoch_before,
      interface_changed,
      stale,
      replacements: replacements.length(),
      rolled_back: true,
      reason,
    }
  }
  env.epoch = env.epoch + 1
  env.history.push(HotLoadRecord::{
    path: incoming.module_path,
    epoch: env.epoch,
    interface_changed,
    replacements: replacements.length(),
    rolled_back: false,
    reason: "",
  })
  HotLoadReport::{
    accepted: true,
    epoch_before,
    epoch_after: env.epoch,
    interface_changed,
    stale,
    replacements: replacements.length(),
    rolled_back: false,
    reason: "",
  }
}

///|
/// Instantiate a client module against the live environment.
pub fn hot_load_instantiate(
  env : HotLoadEnv,
  module_ : ModuleDef,
  args : Array[DTerm],
) -> ModuleInstance? {
  module_link_instantiate(hot_load_env_to_compiled(env), module_, args)
}

///|
/// Elaborate a client module against the live environment.
pub fn hot_load_signature(
  env : HotLoadEnv,
  module_ : ModuleDef,
) -> ModuleSignature? {
  module_link_signature(hot_load_env_to_compiled(env), module_)
}

// ---------------------------------------------------------------------------
// Law
// ---------------------------------------------------------------------------

///|
/// `Data.BoolOps` with a chosen body for `id`.
///
/// The key detail is that `id` is exported **opaquely**.  The compiled
/// `interface_encoding` writes `body=opaque` for opaque exports, so the
/// interface hash is invariant under a change to `id`'s body while the
/// implementation hash is not.  That is exactly the situation hot
/// loading must recognise: an implementation-only change.
fn hot_bool_ops_with_id(id_body : DTerm) -> ModuleDef {
  module_def("Data.BoolOps", decls=[
    module_decl("not", DPi(DBoolTy, DBoolTy), bool_not_term()),
    module_decl("id", DPi(DBoolTy, DBoolTy), id_body, transparent=false),
  ])
}

///|
/// Version 1: `id` is the identity.
fn hot_bool_ops_v1() -> ModuleDef {
  hot_bool_ops_with_id(DLam(DBoolTy, DTVar(0)))
}

///|
/// Version 2: `id` is double negation.  Same interface, different
/// implementation.
fn hot_bool_ops_v2() -> ModuleDef {
  // id := \x. not (not x)
  hot_bool_ops_with_id(DLam(DBoolTy, DApp(DTVar(1), DApp(DTVar(1), DTVar(0)))))
}

///|
/// Version 3: `id` becomes **transparent**.
///
/// Transparency is part of the interface: the compiled
/// `interface_encoding` records it, and it determines whether
/// dependents may unfold the definition.  Flipping it changes the
/// interface hash while leaving the export set and every type alone,
/// which is the minimal change that still invalidates dependents.
/// (Adding or removing an export would also work in principle, but
/// `generic_iterate_module`'s de Bruijn ordinals are pinned to a
/// two-export `Data.BoolOps`, so the export count is held fixed.)
fn hot_bool_ops_v3() -> ModuleDef {
  module_def("Data.BoolOps", decls=[
    module_decl("not", DPi(DBoolTy, DBoolTy), bool_not_term()),
    module_decl(
      "id",
      DPi(DBoolTy, DBoolTy),
      DLam(DBoolTy, DTVar(0)),
      transparent=true,
    ),
  ])
}

///|
/// A tiny dependency used to build a client object with a dangling
/// import.  v1 and v2 differ only in transparency, so the interface
/// hash changes while the export set and types stay put.
fn hot_absent_v1() -> ModuleDef {
  module_def("Data.Absent", decls=[
    module_decl("flag", DBoolTy, DBoolLit(true), transparent=false),
  ])
}

///|
fn hot_absent_v2() -> ModuleDef {
  module_def("Data.Absent", decls=[
    module_decl("flag", DBoolTy, DBoolLit(true), transparent=true),
  ])
}

///|
/// A client whose only import is `Data.Absent`.
fn hot_client_module() -> ModuleDef {
  module_def("Demo.Client", imports=[module_import("Data.Absent")], decls=[])
}

///|
fn hot_compile_all(sources : Array[ModuleDef]) -> CompiledModuleEnv? {
  let env = compiled_module_env_new()
  let src = module_env_new()
  for i in 0..<sources.length() {
    ignore(module_env_add(src, sources[i]))
  }
  for i in 0..<sources.length() {
    let deps : Array[ModuleDependencyFingerprint] = []
    for j in 0..<sources[i].imports.length() {
      let p = sources[i].imports[j].module_path
      match compiled_module_env_find(env, p) {
        None => ()
        Some(c) =>
          deps.push(
            module_dependency_fingerprint(c.module_path, c.interface_hash),
          )
      }
    }
    match module_compile(src, sources[i], deps) {
      None => return None
      Some(compiled) =>
        if !compiled_module_env_add(env, compiled) {
          return None
        }
    }
  }
  Some(env)
}

///|
fn hot_is_opaque(d : HotLoadDecision) -> Bool {
  match d {
    HotOpaqueSwap => true
    _ => false
  }
}

///|
fn hot_is_relink(d : HotLoadDecision, expect : Array[String]) -> Bool {
  match d {
    HotRelink(paths) => paths == expect
    _ => false
  }
}

///|
fn hot_reject_reason(d : HotLoadDecision) -> String {
  match d {
    HotReject(reason) => reason
    _ => ""
  }
}

///|
fn hot_load_links_generic(env : HotLoadEnv) -> Bool {
  match hot_load_signature(env, generic_iterate_module()) {
    Some(_) => true
    None => false
  }
}

///|
/// Runtime hot-loading of the compiled module environment.
pub fn check_module_runtime_hot_loading() -> Bool {
  // Build v1: BoolOps(v1) + Generic.Iterate compiled against it.
  let cenv1 = match
    hot_compile_all([hot_bool_ops_v1(), generic_iterate_module()]) {
    None => return false
    Some(e) => e
  }
  let env = hot_load_env_new(cenv1)
  let v1 = match compiled_module_env_find(cenv1, "Data.BoolOps") {
    None => return false
    Some(m) => m
  }
  let gen_v1 = match compiled_module_env_find(cenv1, "Generic.Iterate") {
    None => return false
    Some(m) => m
  }
  let v2_compiled = match hot_compile_all([hot_bool_ops_v2()]) {
    None => return false
    Some(e) =>
      match compiled_module_env_find(e, "Data.BoolOps") {
        None => return false
        Some(m) => m
      }
  }
  let v3_compiled = match hot_compile_all([hot_bool_ops_v3()]) {
    None => return false
    Some(e) =>
      match compiled_module_env_find(e, "Data.BoolOps") {
        None => return false
        Some(m) => m
      }
  }
  let gen_v3 = match
    hot_compile_all([hot_bool_ops_v3(), generic_iterate_module()]) {
    None => return false
    Some(e) =>
      match compiled_module_env_find(e, "Generic.Iterate") {
        None => return false
        Some(m) => m
      }
  }

  // ---- (0) The starting environment is consistent and links. ----
  let start_ok = hot_load_consistent(env) &&
    hot_load_env_epoch(env) == 0 &&
    hot_load_stale_modules(env).length() == 0 &&
    hot_load_links_generic(env) &&
    hot_load_dependents(env, "Data.BoolOps") == ["Generic.Iterate"]

  // ---- (1) Opaque swap: same interface, different implementation. ----
  let swap1_plan = hot_load_plan(env, v2_compiled)
  let swap1 = hot_load_apply(env, v2_compiled)
  let gen_still_v1 = match hot_load_find(env, "Generic.Iterate") {
    Some(m) => m.interface_hash == gen_v1.interface_hash
    None => false
  }
  let swap1_ok = v2_compiled.interface_hash == v1.interface_hash &&
    v2_compiled.implementation_hash != v1.implementation_hash &&
    hot_is_opaque(swap1_plan) &&
    swap1.accepted &&
    !swap1.interface_changed &&
    swap1.epoch_after == 1 &&
    swap1.replacements == 0 &&
    !swap1.rolled_back &&
    hot_load_consistent(env) &&
    hot_load_stale_modules(env).length() == 0 &&
    gen_still_v1 &&
    hot_load_links_generic(env)

  // ---- (2) Breaking swap without replacements: rolled back. ----
  let break_plan = hot_load_plan(env, v3_compiled)
  let breaking = hot_load_apply(env, v3_compiled)
  let still_v1 = match hot_load_find(env, "Data.BoolOps") {
    Some(m) => m.interface_hash == v1.interface_hash
    None => false
  }
  let breaking_ok = v3_compiled.interface_hash != v1.interface_hash &&
    hot_is_relink(break_plan, ["Generic.Iterate"]) &&
    !breaking.accepted &&
    breaking.rolled_back &&
    breaking.stale == ["Generic.Iterate"] &&
    breaking.epoch_after == breaking.epoch_before &&
    hot_load_env_epoch(env) == 1 &&
    hot_load_consistent(env) &&
    still_v1 &&
    hot_load_links_generic(env)

  // ---- (3) Breaking swap WITH a rebuilt dependent: committed. ----
  let with_repl = hot_load_apply(env, v3_compiled, replacements=[gen_v3])
  let now_v3 = match hot_load_find(env, "Data.BoolOps") {
    Some(m) => m.interface_hash == v3_compiled.interface_hash
    None => false
  }
  let relink_ok = with_repl.accepted &&
    with_repl.interface_changed &&
    with_repl.replacements == 1 &&
    with_repl.epoch_after == 2 &&
    !with_repl.rolled_back &&
    hot_load_consistent(env) &&
    hot_load_stale_modules(env).length() == 0 &&
    now_v3 &&
    hot_load_links_generic(env)

  // ---- (4) Rejections decided before any mutation. ----
  // Build a client object that genuinely depends on Data.Absent in a
  // side environment, so the object itself is valid.
  let client_compiled = match
    hot_compile_all([hot_absent_v1(), hot_client_module()]) {
    None => return false
    Some(e) =>
      match compiled_module_env_find(e, "Demo.Client") {
        None => return false
        Some(m) => m
      }
  }
  let absent_v2 = match hot_compile_all([hot_absent_v2()]) {
    None => return false
    Some(e) =>
      match compiled_module_env_find(e, "Data.Absent") {
        None => return false
        Some(m) => m
      }
  }
  // (4a) The dependency is not installed at all.
  let missing_report = hot_load_apply(env, client_compiled)
  let missing_ok = hot_reject_reason(hot_load_plan(env, client_compiled)) ==
    "missing dependency: Data.Absent" &&
    !missing_report.accepted &&
    missing_report.reason == "missing dependency: Data.Absent" &&
    hot_load_env_epoch(env) == 2

  // (4b) The dependency is installed, but with a different interface.
  let env_absent = hot_load_env_new(cenv1)
  let absent_added = hot_load_apply(env_absent, absent_v2)
  let stale_ok = absent_added.accepted &&
    hot_reject_reason(hot_load_plan(env_absent, client_compiled)) ==
    "stale dependency interface: Data.Absent"

  // ---- (5) The audit log records successes and rollbacks alike. ----
  let hist = hot_load_env_history(env)
  let history_ok = hist.length() == 4 &&
    !hist[0].rolled_back &&
    hist[1].rolled_back &&
    hist[1].interface_changed &&
    !hist[2].rolled_back &&
    hist[2].replacements == 1 &&
    !hist[3].rolled_back &&
    hist[3].reason.length() > 0

  start_ok &&
  swap1_ok &&
  breaking_ok &&
  relink_ok &&
  missing_ok &&
  stale_ok &&
  history_ok
}
