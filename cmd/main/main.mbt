///|
fn argument_error(message : String) -> Unit {
  println(
    @json.Json::object({
      "event": @json.to_json("error"),
      "message": @json.to_json(message),
    }).stringify(),
  )
  @env.exit(2)
}

///|
fn parse_integer(text : StringView) -> Int32? {
  Some(@string.parse_int(text)) catch {
    _ => None
  }
}

///|
fn main {
  let args = @env.args()
  // env.args includes the executable prefix; Node adds the script path too.
  let first = if args.is_empty() || args[0].has_prefix("--") {
    0
  } else if args[0] == "node" ||
    args[0].has_suffix("/node") ||
    args[0].has_suffix("node.exe") {
    2
  } else {
    1
  }
  let mut selected : Array[Int32]? = None
  let mut max_checks = 2147483647
  let mut limit_seen = false
  let mut jsonl = false
  let mut progress = false
  let mut list_only = false
  for i in first..<args.length() {
    let arg = args[i]
    if arg == "--" {
      continue
    } else if arg == "--jsonl" {
      jsonl = true
    } else if arg == "--progress" {
      progress = true
    } else if arg == "--list" {
      list_only = true
    } else if arg == "--help" {
      println(
        "Usage: main [--list] [--checks=1,2,...] [--max-checks=N] [--progress] [--jsonl]",
      )
      println(
        "Default: all checks. Selection/budget is PARTIAL, never a full-verification claim.",
      )
      @env.exit(0)
    } else if arg.strip_prefix("--checks=") is Some(values) {
      if selected is Some(_) {
        argument_error("--checks repeated")
      }
      let ids : Array[Int32] = []
      for text in values.to_owned().split(",") {
        guard parse_integer(text) is Some(id) else {
          argument_error("invalid check ID")
        }
        ids.push(id)
      }
      selected = Some(ids)
    } else if arg.strip_prefix("--max-checks=") is Some(value) {
      if limit_seen {
        argument_error("--max-checks repeated")
      }
      guard parse_integer(value) is Some(limit) else {
        argument_error("invalid task budget")
      }
      if limit < 0 {
        argument_error("task budget must be nonnegative")
      }
      max_checks = limit
      limit_seen = true
    } else {
      argument_error("unknown argument: " + arg)
    }
  }
  if list_only {
    if selected is Some(_) || limit_seen {
      argument_error("--list cannot execute a selection")
    }
    for (id, name) in @lib.check_pipeline_manifest() {
      if jsonl {
        println(
          @json.Json::object({
            "event": @json.to_json("manifest"),
            "id": @json.to_json(id),
            "name": @json.to_json(name),
          }).stringify(),
        )
      } else {
        println("\{id}: \{name}")
      }
    }
    @env.exit(0)
  }
  if selected is None && !limit_seen && !jsonl && !progress {
    guard @lib.print_report() else { abort("theorem registry failed") }
    return
  }
  let timer = [@bench.monotonic_clock_start()]
  guard @lib.run_check_pipeline(
      selected~,
      max_checks~,
      on_start=(id, name) => {
        timer[0] = @bench.monotonic_clock_start()
        if jsonl {
          println(
            @json.Json::object({
              "event": @json.to_json("started"),
              "id": @json.to_json(id),
              "name": @json.to_json(name),
            }).stringify(),
          )
        } else if progress {
          println("[START] \{id}: \{name}")
        }
      },
      on_result=(id, result) => {
        let elapsed_ms = @bench.monotonic_clock_end(timer[0]) / 1000.0
        if jsonl {
          println(
            @json.Json::object({
              "event": @json.to_json("result"),
              "id": @json.to_json(id),
              "name": @json.to_json(result.name),
              "ok": @json.to_json(result.ok),
              "elapsed_ms": @json.to_json(elapsed_ms),
            }).stringify(),
          )
        } else {
          let status = if result.ok { "PASS" } else { "FAIL" }
          println("[\{status}] \{id}: \{result.name}")
          if progress {
            println("        elapsed_ms=\{elapsed_ms}")
          }
        }
      },
    )
    is Some(report) else {
    argument_error("invalid, empty or duplicate check selection")
  }
  let passed = report.results.filter(r => r.ok).length()
  if jsonl {
    println(
      @json.Json::object({
        "event": @json.to_json("summary"),
        "total": @json.to_json(report.total_checks),
        "requested": @json.to_json(report.requested_checks),
        "completed": @json.to_json(report.completed_ids.length()),
        "passed": @json.to_json(passed),
        "deferred_ids": @json.to_json(report.deferred_ids),
        "selected_all_passed": @json.to_json(report.selected_all_passed),
        "full_verified": @json.to_json(report.full_verified),
      }).stringify(),
    )
  } else if report.full_verified {
    println("passed \{passed}/\{report.total_checks}")
  } else {
    println(
      "partial: \{passed}/\{report.requested_checks} requested checks passed; deferred=\{report.deferred_ids.length()}, full_verified=false",
    )
  }
  if passed != report.results.length() ||
    (
      report.requested_checks == report.total_checks &&
      max_checks >= report.total_checks &&
      !report.full_verified
    ) {
    @env.exit(1)
  }
}
