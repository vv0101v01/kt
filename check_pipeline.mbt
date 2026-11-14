///|
// Observer-layer scheduling only. Planning creates closures, not theorem
// results; domain engines remain below this layer and know nothing about CLI IO.
priv struct CheckTask {
  name : String
  run : () -> Bool
}

///|
/// Explicit separation between a successful selected batch and full coverage.
/// A task budget is cooperative: it stops BETWEEN checks, never during one.
pub(all) struct CheckPipelineReport {
  total_checks : Int32
  requested_checks : Int32
  completed_ids : Array[Int32]
  results : Array[CheckResult]
  deferred_ids : Array[Int32]
  selected_all_passed : Bool
  full_verified : Bool
}

///|
fn check_pipeline_selection(
  selected : Array[Int32]?,
  total : Int32,
) -> Array[Int32]? {
  match selected {
    None => Some(Array::makei(total, i => i + 1))
    Some(ids) => {
      if ids.is_empty() {
        return None
      }
      let seen = Array::make(total, false)
      for id in ids {
        if id < 1 || id > total || seen[id - 1] {
          return None
        }
        seen[id - 1] = true
      }
      Some(ids.copy())
    }
  }
}

///|
fn execute_check_tasks(
  tasks : Array[CheckTask],
  selected : Array[Int32]?,
  max_checks : Int32,
  on_start : (Int32, String) -> Unit,
  on_result : (Int32, CheckResult) -> Unit,
) -> CheckPipelineReport? {
  if max_checks < 0 || tasks.is_empty() {
    return None
  }
  guard check_pipeline_selection(selected, tasks.length()) is Some(ids) else {
    return None
  }
  let completed : Array[Int32] = []
  let deferred : Array[Int32] = []
  let results : Array[CheckResult] = []
  let mut all_ok = true
  for id in ids {
    if completed.length() >= max_checks {
      deferred.push(id)
      continue
    }
    let task = tasks[id - 1]
    on_start(id, task.name)
    let result = CheckResult::{ name: task.name, ok: (task.run)(), }
    all_ok = all_ok && result.ok
    results.push(result)
    completed.push(id)
    on_result(id, result)
  }
  Some({
    total_checks: tasks.length(),
    requested_checks: ids.length(),
    completed_ids: completed,
    results,
    deferred_ids: deferred,
    selected_all_passed: all_ok && !results.is_empty() && deferred.is_empty(),
    full_verified: all_ok && completed.length() == tasks.length(),
  })
}

///|
/// One-based stable registry positions and labels. No check is executed.
pub fn check_pipeline_manifest() -> Array[(Int32, String)] {
  let tasks = check_tasks()
  Array::makei(tasks.length(), i => (i + 1, tasks[i].name))
}

///|
/// Validate the entire request before executing any selected task. Duplicate,
/// unknown, zero and empty IDs are errors (None), not silently ignored inputs.
/// max_checks=0 is a planning-only batch; it never reports full verification.
pub fn run_check_pipeline(
  selected~ : Array[Int32]? = None,
  max_checks~ : Int32 = 2147483647,
  on_start~ : (Int32, String) -> Unit = (_, _) => (),
  on_result~ : (Int32, CheckResult) -> Unit = (_, _) => (),
) -> CheckPipelineReport? {
  if !check_pipeline_laws() {
    return None
  }
  execute_check_tasks(check_tasks(), selected, max_checks, on_start, on_result)
}

///|
/// Durable protocol laws use synthetic jobs, never substitute these for the
/// domain checks. They verify non-execution on bad input, ordering and coverage.
pub fn check_pipeline_laws() -> Bool {
  let calls : Array[Int32] = []
  let tasks : Array[CheckTask] = [
    {
      name: "first",
      run: () => {
        calls.push(1)
        true
      },
    },
    {
      name: "second",
      run: () => {
        calls.push(2)
        true
      },
    },
    {
      name: "failure",
      run: () => {
        calls.push(3)
        false
      },
    },
  ]
  let noop_start = (_, _) => ()
  let noop_result = (_, _) => ()
  for invalid in [[], [0], [4], [1, 1], [-1], [1, 99]] {
    if execute_check_tasks(tasks, Some(invalid), 3, noop_start, noop_result)
      is Some(_) {
      return false
    }
  }
  if !calls.is_empty() ||
    execute_check_tasks(tasks, None, -1, noop_start, noop_result) is Some(_) {
    return false
  }
  guard execute_check_tasks(tasks, None, 0, noop_start, noop_result)
    is Some(zero) else {
    return false
  }
  if !calls.is_empty() ||
    zero.full_verified ||
    zero.selected_all_passed ||
    zero.deferred_ids != [1, 2, 3] {
    return false
  }
  guard execute_check_tasks(tasks, Some([2, 1]), 1, noop_start, noop_result)
    is Some(partial) else {
    return false
  }
  if calls != [2] ||
    partial.full_verified ||
    partial.selected_all_passed ||
    partial.completed_ids != [2] ||
    partial.deferred_ids != [1] {
    return false
  }
  guard execute_check_tasks(tasks, None, 3, noop_start, noop_result)
    is Some(full) else {
    return false
  }
  if full.full_verified ||
    full.selected_all_passed ||
    full.completed_ids != [1, 2, 3] ||
    !full.deferred_ids.is_empty() ||
    calls != [2, 1, 2, 3] {
    return false
  }
  let events : Array[Int32] = []
  guard execute_check_tasks(
      tasks,
      Some([2, 1]),
      2,
      (id, _) => events.push(10 * id),
      (id, _) => events.push(10 * id + 1),
    )
    is Some(subset) else {
    return false
  }
  if !subset.selected_all_passed ||
    subset.full_verified ||
    events != [20, 21, 10, 11] {
    return false
  }
  if execute_check_tasks([], None, 0, noop_start, noop_result) is Some(_) {
    return false
  }
  guard execute_check_tasks(
      [tasks[0], tasks[1]],
      None,
      2,
      noop_start,
      noop_result,
    )
    is Some(positive) else {
    return false
  }
  positive.full_verified &&
  positive.selected_all_passed &&
  positive.completed_ids == [1, 2]
}
