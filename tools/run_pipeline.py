#!/usr/bin/env python3
"""Operational front-end for the shipped theorem registry, not a test suite.

Plan -> bounded independent moonrun workers -> validated streaming JSONL ->
coverage-aware reduction. Cost hints schedule work; proof results are NEVER read
from a cache. Build first. Python 3.11+, stdlib only, wasm-gc / moonrun.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import threading
import time

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WASM = ROOT / "_build/wasm-gc/debug/build/cmd/main/main.wasm"
DEFAULT_COSTS = Path(__file__).with_name("check_costs.json")


class PipelineError(ValueError):
    pass


def finite_nonnegative(value):
    return type(value) in (int, float) and 0 <= value <= 1e12 and math.isfinite(value)


def decode_json(text):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise PipelineError("duplicate JSON key: " + key)
            result[key] = value
        return result

    def invalid_constant(value):
        raise PipelineError("non-finite JSON number: " + value)

    return json.loads(text, object_pairs_hook=unique, parse_constant=invalid_constant)


def load_manifest(command):
    run = subprocess.run(command + ["--list", "--jsonl"], capture_output=True,
                         text=True, encoding="utf-8", timeout=30)
    if run.returncode:
        raise PipelineError("manifest command failed: " + run.stderr[-2000:])
    rows = [decode_json(line) for line in run.stdout.splitlines()]
    if not rows or any(not isinstance(row, dict) or row.get("event") != "manifest"
                       or type(row.get("id")) is not int or row["id"] != i
                       or not isinstance(row.get("name"), str) or not row["name"].strip()
                       for i, row in enumerate(rows, 1)):
        raise PipelineError("manifest must contain nonempty, contiguous one-based IDs")
    manifest = {row["id"]: row["name"] for row in rows}
    payload = json.dumps(list(manifest.items()), ensure_ascii=False, separators=(",", ":"))
    return manifest, hashlib.sha256(payload.encode()).hexdigest()


def load_costs(path, manifest, digest):
    costs = {i: 1.0 for i in manifest}
    if path is None:
        return costs
    data = decode_json(path.read_text(encoding="utf-8"))
    if (not isinstance(data, dict) or type(data.get("schema")) is not int
            or data["schema"] != 1 or data.get("manifest_sha256") != digest):
        raise PipelineError("stale/invalid cost hints; recalibrate or use --costs=none")
    values = data.get("elapsed_ms")
    if not isinstance(values, dict):
        raise PipelineError("cost hints need an elapsed_ms object, never cached booleans")
    for key, value in values.items():
        if (not key.isascii() or not key.isdecimal() or key != str(int(key))
                or int(key) not in manifest or not finite_nonnegative(value)):
            raise PipelineError("invalid cost hint")
        costs[int(key)] = max(0.001, value)
    return costs


def select_ids(text, manifest):
    if text is None:
        return list(manifest)
    fields = text.split(",")
    if any(not field.isascii() or not field.isdecimal() for field in fields):
        raise PipelineError("--checks requires comma-separated positive integer IDs")
    ids = [int(field) for field in fields]
    if len(set(ids)) != len(ids) or any(i not in manifest for i in ids):
        raise PipelineError("empty, duplicate or unknown check ID")
    return ids


def balance(ids, jobs, costs):
    if not ids:
        return []
    if jobs == 1:
        return [ids.copy()]  # Preserve input order for reproducible serial runs.
    bins = [[] for _ in range(min(jobs, len(ids)))]
    loads = [0.0] * len(bins)
    # Longest-processing-time-first is an advisory greedy schedule, not an
    # optimality claim. Tie breaks are deterministic. No check is dropped.
    for i in sorted(ids, key=lambda i: (-costs[i], i)):
        b = min(range(len(bins)), key=lambda b: (loads[b], len(bins[b]), b))
        bins[b].append(i)
        loads[b] += costs[i]
    return bins


def terminate(process):
    if process.poll() is None:
        try:
            if os.name == "posix":
                os.killpg(process.pid, signal.SIGKILL)
            else:
                process.kill()
        except ProcessLookupError:
            pass


def run_worker(worker, ids, command, manifest, timeout, emit, processes, lock, cancelled):
    if cancelled.is_set():
        raise PipelineError("worker cancelled before launch")
    expected = 0
    pending = None
    summary_seen = False
    results = []
    expired = threading.Event()
    with tempfile.TemporaryFile(mode="w+", encoding="utf-8") as errors:
        process = subprocess.Popen(command + ["--checks=" + ",".join(map(str, ids)), "--jsonl"],
                                   stdout=subprocess.PIPE, stderr=errors, text=True,
                                   encoding="utf-8", start_new_session=(os.name == "posix"))
        with lock:
            processes.append(process)
            if cancelled.is_set():
                terminate(process)

        def expire():
            if process.poll() is None:
                expired.set()
                terminate(process)

        timer = threading.Timer(timeout, expire)
        timer.daemon = True
        timer.start()
        try:
            for line in process.stdout:
                event = decode_json(line)
                if not isinstance(event, dict) or summary_seen:
                    raise PipelineError("invalid event or output after summary")
                kind = event.get("event")
                if kind in ("started", "result"):
                    i = event.get("id")
                    if (type(i) is not int or expected >= len(ids) or i != ids[expected]
                            or event.get("name") != manifest[i]):
                        raise PipelineError("unknown, duplicate, reordered or mislabeled result")
                    if kind == "started":
                        if pending is not None:
                            raise PipelineError("second start before result")
                        pending = i
                    else:
                        if (pending != i or type(event.get("ok")) is not bool
                                or not finite_nonnegative(event.get("elapsed_ms"))):
                            raise PipelineError("invalid result or missing start")
                        results.append(event)
                        pending = None
                        expected += 1
                    emit(dict(event, worker=worker))
                elif kind == "summary":
                    ok = all(row["ok"] for row in results)
                    wanted = {"total": len(manifest), "requested": len(ids),
                              "completed": len(ids), "passed": sum(row["ok"] for row in results)}
                    if (pending is not None or expected != len(ids)
                            or any(type(event.get(k)) is not int or event[k] != v for k, v in wanted.items())
                            or event.get("deferred_ids") != []
                            or event.get("selected_all_passed") is not ok
                            or event.get("full_verified") is not (ok and len(ids) == len(manifest))):
                        raise PipelineError("incomplete or inconsistent worker summary")
                    summary_seen = True
                    emit(dict(event, event="worker_summary", worker=worker))
                else:
                    raise PipelineError("unexpected worker event: " + str(kind))
            code = process.wait()
            if expired.is_set():
                raise PipelineError("worker timeout (no full-verification claim)")
            if code or not summary_seen:
                errors.seek(0)
                raise PipelineError(f"worker exit={code}, summary={summary_seen}: " + errors.read()[-2000:])
        finally:
            timer.cancel()
            terminate(process)
            process.wait()
            process.stdout.close()
            with lock:
                processes.remove(process)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wasm", type=Path, default=DEFAULT_WASM)
    parser.add_argument("--jobs", type=int, default=min(2, os.cpu_count() or 1), help="1..8 isolated workers (default <=2)")
    parser.add_argument("--checks", help="explicit subset; never implies full verification")
    parser.add_argument("--max-checks", type=int, help="cooperative batch budget; remaining IDs are deferred")
    parser.add_argument("--costs", default=str(DEFAULT_COSTS), help="timing-only hints, or none for equal costs")
    parser.add_argument("--save-costs", type=Path, help="write fresh timings ONLY after a complete successful run")
    parser.add_argument("--timeout-seconds", type=float, default=900, help="hard timeout per worker; kills are failures")
    parser.add_argument("--plan", action="store_true", help="plan only; executes no theorem checks")
    parser.add_argument("--require-full", action="store_true", help="reject partial/plan requests (CI)")
    parser.add_argument("--jsonl", action="store_true", help="machine-readable streaming events")
    args = parser.parse_args(argv)
    lock = threading.RLock()
    processes = []
    observed = {}
    cancelled = threading.Event()

    def emit(event):
        with lock:
            if event["event"] == "result":
                if event["id"] in observed:
                    raise PipelineError("duplicate result across workers")
                observed[event["id"]] = event
            if args.jsonl:
                print(json.dumps(event, ensure_ascii=False, allow_nan=False), flush=True)
            elif event["event"] == "started":
                print(f"[START w{event['worker']}] {event['id']}: {event['name']}", flush=True)
            elif event["event"] == "result":
                status = "PASS" if event["ok"] else "FAIL"
                print(f"[{status}] {event['id']}: {event['name']} ({event['elapsed_ms']:.3f} ms)", flush=True)
            elif event["event"] in ("plan", "summary", "error"):
                print(json.dumps(event, ensure_ascii=False, allow_nan=False), flush=True)

    def stop_all():
        with lock:
            cancelled.set()
            for process in processes:
                terminate(process)

    try:
        if not 1 <= args.jobs <= 8 or args.max_checks is not None and args.max_checks < 0:
            raise PipelineError("jobs must be 1..8; budget must be nonnegative")
        if not 0 < args.timeout_seconds <= 86400:
            raise PipelineError("timeout must be finite and in (0, 86400] seconds")
        if not args.wasm.is_file():
            raise PipelineError("build the wasm-gc executable first: moon build --target wasm-gc")
        command = ["moonrun", str(args.wasm.resolve()), "--"]
        manifest, digest = load_manifest(command)
        requested = select_ids(args.checks, manifest)
        scheduled = requested if args.max_checks is None else requested[:args.max_checks]
        if args.require_full and (args.plan or set(scheduled) != set(manifest)):
            raise PipelineError("--require-full forbids planning-only or incomplete coverage")
        cost_path = None if args.costs == "none" else Path(args.costs)
        costs = load_costs(cost_path, manifest, digest)
        batches = balance(scheduled, args.jobs, costs)
        assert sorted(i for batch in batches for i in batch) == sorted(scheduled)
        emit({"event": "plan", "protocol": 1, "manifest_sha256": digest, "total": len(manifest),
              "requested": len(requested), "scheduled": len(scheduled), "jobs": len(batches),
              "batches": batches, "estimated_batch_ms": [sum(costs[i] for i in batch) for batch in batches],
              "deferred_ids": requested[len(scheduled):], "executed": False, "full_verified": False})
        if args.plan:
            return 0
        start = time.perf_counter()
        failures = []
        interrupted = False
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = [pool.submit(run_worker, w, ids, command, manifest, args.timeout_seconds,
                                   emit, processes, lock, cancelled) for w, ids in enumerate(batches, 1)]
            try:
                for future in as_completed(futures):
                    try:
                        future.result()
                    except Exception as error:
                        failures.append(str(error))
                        emit({"event": "error", "message": str(error)})
                        stop_all()
            except KeyboardInterrupt:
                interrupted = True
                failures.append("interrupted")
                stop_all()
        passed = sum(row["ok"] for row in observed.values())
        selected_ok = not failures and bool(observed) and set(observed) == set(requested) and passed == len(requested)
        full = selected_ok and set(observed) == set(manifest)
        if args.save_costs and full:
            args.save_costs.parent.mkdir(parents=True, exist_ok=True)
            args.save_costs.write_text(json.dumps({
                "schema": 1, "manifest_sha256": digest, "target": "wasm-gc debug",
                "note": "Advisory single-run timings, not proof results or a speedup benchmark. Recalibrate on your host.",
                "jobs_at_capture": len(batches),
                "elapsed_ms": {str(i): round(observed[i]["elapsed_ms"], 6) for i in sorted(observed)},
            }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        emit({"event": "summary", "total": len(manifest), "requested": len(requested),
              "completed": len(observed), "passed": passed,
              "deferred_ids": [i for i in requested if i not in observed],
              "selected_all_passed": selected_ok, "full_verified": full,
              "worker_errors": failures, "elapsed_ms": (time.perf_counter() - start) * 1000})
        return 130 if interrupted else int(bool(failures) or passed != len(observed) or args.require_full and not full)
    except (PipelineError, OSError, ValueError, subprocess.SubprocessError) as error:
        stop_all()
        emit({"event": "error", "message": str(error)})
        return 2


if __name__ == "__main__":
    sys.exit(main())
