#!/usr/bin/env python3
"""Check the package/component architecture declared in architecture.json.

The checker is intentionally boring and fast:

* every .mbt file under the module (excluding _build) must be assigned
  to exactly one component;
* physical MoonBit package imports in moon.pkg must exactly match the
  manifest's package graph and must respect package layers;
* an approximate source-level reference graph (comments and strings
  stripped, declarations resolved package-locally first) must respect
  component layers/allowed edges, except for explicitly manifested
  exceptions.

The source graph is a guardrail, not a compiler: it reports the names
that caused an edge so a human can decide whether the edge is real.
Run after `moon check`; the compiler remains the source of truth.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "architecture.json"

IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
DECL = re.compile(
    r"^(?:pub(?:\((?:all|open)\))?\s+|priv\s+)?"
    r"(fn|struct|enum|type|let|trait)(?:\[[^\]]*\])?\s+"
    r"([A-Za-z_][A-Za-z0-9_]*)",
    re.M,
)
ENUM = re.compile(
    r"^(?:pub(?:\((?:all|open)\))?\s+|priv\s+)?enum\s+([A-Z][A-Za-z0-9_]*)\s*\{(.*?)^\}",
    re.M | re.S,
)
CTOR = re.compile(r"^\s{2}([A-Z][A-Za-z0-9_]*)\b", re.M)
# Moon package files may have ordinary imports and test-scoped imports:
#   import { "..." }
#   import { "..." } for "wbtest"
# Only the former is a production package edge.  Test-scoped imports are
# retained for source-name resolution, and still checked as manifested.
MOON_IMPORT = re.compile(r'import\s*\{(.*?)\}(?:\s*for\s*"([^"]+)")?', re.S)
QUOTED = re.compile(r'"([^"]+)"')
GENERATED_DIRS = {"_build", ".git", ".mooncakes", ".moonagent", "target"}


def strip_comments_strings(text: str) -> str:
    out: list[str] = []
    i = 0
    in_str = False
    esc = False
    while i < len(text):
        ch = text[i]
        if in_str:
            if esc:
                esc = False
                out.append(" ")
            elif ch == "\\":
                esc = True
                out.append(" ")
            elif ch == '"':
                in_str = False
                out.append(" ")
            else:
                out.append("\n" if ch == "\n" else " ")
            i += 1
            continue
        if ch == '"':
            in_str = True
            out.append(" ")
            i += 1
            continue
        if ch == "/" and i + 1 < len(text) and text[i + 1] == "/":
            while i < len(text) and text[i] != "\n":
                out.append(" ")
                i += 1
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def local_bindings(text: str) -> set[str]:
    names: set[str] = set()
    # let / for bindings
    names.update(re.findall(r"\blet\s+(?:mut\s+)?([a-z_][A-Za-z0-9_]*)\b", text))
    names.update(re.findall(r"\bfor\s+([a-z_][A-Za-z0-9_]*)\s+in\b", text))
    # Parameters and closure parameters:  name : Type   /   name =>
    names.update(re.findall(r"[(,]\s*([a-z_][A-Za-z0-9_]*)\s*:", text))
    names.update(re.findall(r"\b([a-z_][A-Za-z0-9_]*)\s*=>", text))
    # Tuple/pattern bindings written (name, ...) after let/match-ish code.
    for group in re.findall(r"\blet\s+(?:mut\s+)?\(([^)]*)\)", text):
        names.update(IDENT.findall(group))
    # Function names are declarations, not locals; removing lowercase
    # top-level names here would hide real edges, so only locals that
    # are also never declared at top level in the same file are used by
    # the caller filter.
    return names


def expand_files(patterns: list[str]) -> list[Path]:
    """Expand manifest file patterns in order.

    A pattern beginning with ``!`` removes previously matched files.  This
    keeps package components concise when tests live beside production files
    (``semiring/algebra/*.mbt`` followed by ``!semiring/algebra/*_test.mbt``).
    Generated and dependency-cache directories are never assignable.
    """

    out: list[Path] = []

    def candidates(pattern: str) -> list[Path]:
        found = (
            sorted(ROOT.glob(pattern))
            if any(c in pattern for c in "*?[")
            else [ROOT / pattern]
        )
        resolved: list[Path] = []
        for path in found:
            rp = path.resolve()
            try:
                parts = rp.relative_to(ROOT).parts
            except ValueError:
                continue
            if not GENERATED_DIRS.intersection(parts):
                resolved.append(rp)
        return resolved

    for pat in patterns:
        if pat.startswith("!"):
            excluded = set(candidates(pat[1:]))
            out = [p for p in out if p not in excluded]
            continue
        for path in candidates(pat):
            if path not in out:
                out.append(path)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="(default) check only")
    ap.add_argument("--json", action="store_true", help="print metrics as JSON")
    ap.add_argument("--list-edges", action="store_true", help="print component edges")
    args = ap.parse_args()

    manifest = json.loads(MANIFEST.read_text())
    packages = {p["id"]: p for p in manifest["packages"]}
    moon_to_pkg = {p["moon"]: p["id"] for p in manifest["packages"]}
    components = {c["id"]: c for c in manifest["components"]}
    federations = {f["id"]: f for f in manifest.get("federations", [])}
    unification = manifest.get("unification")

    errors: list[str] = []

    # ---- 5-federation + unification apex partition -----------------------
    pkg_to_fed: dict[str, str] = {}
    if federations or unification:
        if len(federations) not in (5, 6):
            errors.append(
                f"expected 5 or 6 federations in architecture.json, got {len(federations)}"
            )
        for fed_id, fed in federations.items():
            for pkg_id in fed["packages"]:
                if pkg_id not in packages:
                    errors.append(f"federation {fed_id}: unknown package {pkg_id}")
                elif pkg_id in pkg_to_fed:
                    errors.append(
                        f"package {pkg_id} assigned to both {pkg_to_fed[pkg_id]} and {fed_id}"
                    )
                else:
                    pkg_to_fed[pkg_id] = fed_id
        if unification is not None:
            u_id = unification["id"]
            for pkg_id in unification["packages"]:
                if pkg_id not in packages:
                    errors.append(f"unification {u_id}: unknown package {pkg_id}")
                elif pkg_id in pkg_to_fed:
                    errors.append(
                        f"package {pkg_id} assigned to both {pkg_to_fed[pkg_id]} and {u_id}"
                    )
                else:
                    pkg_to_fed[pkg_id] = u_id
        for pkg_id in packages:
            if pkg_id not in pkg_to_fed:
                errors.append(f"package {pkg_id} is not assigned to any federation or unification")

    # ---- file assignment -------------------------------------------------
    assigned: dict[Path, str] = {}
    for comp in manifest["components"]:
        for path in expand_files(comp["files"]):
            path = path.resolve()
            if not path.exists():
                errors.append(f"{comp['id']}: missing file {path.relative_to(ROOT)}")
                continue
            if path in assigned:
                errors.append(
                    f"{path.relative_to(ROOT)} assigned to both {assigned[path]} and {comp['id']}"
                )
            assigned[path] = comp["id"]

    all_mbt = sorted(
        p.resolve()
        for p in ROOT.rglob("*.mbt")
        if not GENERATED_DIRS.intersection(p.parts)
    )
    for path in all_mbt:
        if path not in assigned:
            errors.append(f"unassigned .mbt file: {path.relative_to(ROOT)}")

    # ---- physical package imports ---------------------------------------
    package_imports: dict[str, set[str]] = {}
    package_all_imports: dict[str, set[str]] = {}
    for pkg in manifest["packages"]:
        moon_pkg = ROOT / pkg["path"] / "moon.pkg"
        if not moon_pkg.exists():
            errors.append(f"package {pkg['id']}: missing {moon_pkg.relative_to(ROOT)}")
            package_imports[pkg["id"]] = set()
            package_all_imports[pkg["id"]] = set()
            continue
        text = moon_pkg.read_text()
        deps: set[str] = set()
        all_deps: set[str] = set()
        for block, scope in MOON_IMPORT.findall(text):
            for item in QUOTED.findall(block):
                if item in moon_to_pkg:
                    dep = moon_to_pkg[item]
                    if dep != pkg["id"]:
                        all_deps.add(dep)
                        if not scope:
                            deps.add(dep)
                elif item == manifest["module"] or item.startswith(
                    manifest["module"] + "/"
                ):
                    errors.append(f"package {pkg['id']}: unmanifested local import {item}")
        package_imports[pkg["id"]] = deps
        package_all_imports[pkg["id"]] = all_deps
        expected = set(pkg["depends_on"])
        if deps != expected:
            errors.append(
                f"package {pkg['id']}: moon.pkg local deps {sorted(deps)} != manifest {sorted(expected)}"
            )
        for dep in deps:
            if packages[dep]["layer"] >= pkg["layer"]:
                errors.append(f"package layer violation: {pkg['id']} -> {dep}")
            if pkg_to_fed:
                src_fed = pkg_to_fed.get(pkg["id"])
                dst_fed = pkg_to_fed.get(dep)
                if src_fed and dst_fed and src_fed != dst_fed:
                    if unification and dst_fed == unification["id"]:
                        errors.append(
                            f"reverse apex dependency forbidden: {pkg['id']} ({src_fed}) -> {dep} ({dst_fed})"
                        )
                    elif not (unification and src_fed == unification["id"]):
                        allowed_ext = set(
                            federations[src_fed].get("allowed_external_packages", [])
                        )
                        token = f"{dst_fed}:{dep}"
                        if token not in allowed_ext:
                            errors.append(
                                f"cross-federation import forbidden: {pkg['id']} ({src_fed}) -> {dep} ({dst_fed}); allow via {token}"
                            )

    # ---- source declarations, package-local first ------------------------
    root_package_id = next(
        (p["id"] for p in manifest["packages"] if p["path"] == "."),
        manifest["packages"][0]["id"],
    )
    package_paths = sorted(
        (
            (p["path"], p["id"])
            for p in manifest["packages"]
            if p["path"] not in {".", ""}
        ),
        key=lambda item: len(item[0]),
        reverse=True,
    )

    def package_of(path: Path) -> str:
        rel = path.relative_to(ROOT).as_posix()
        for prefix, pkg_id in package_paths:
            if rel == prefix or rel.startswith(prefix.rstrip("/") + "/"):
                return pkg_id
        return root_package_id

    texts: dict[Path, str] = {}
    owners: dict[str, dict[str, Path]] = defaultdict(dict)  # package -> name -> file
    kinds: dict[tuple[str, str], str] = {}
    declared_in_file: dict[Path, set[str]] = {}
    for path in all_mbt:
        raw = path.read_text()
        text = strip_comments_strings(raw)
        texts[path] = text
        pkg = package_of(path)
        names: set[str] = set()
        for kind, name in DECL.findall(text):
            names.add(name)
            owners[pkg].setdefault(name, path)
            kinds[(pkg, name)] = kind
        for typ, body in ENUM.findall(text):
            for ctor in CTOR.findall(body):
                names.add(ctor)
                owners[pkg].setdefault(ctor, path)
                kinds[(pkg, ctor)] = f"ctor:{typ}"
        declared_in_file[path] = names

    exceptions = {
        (e["from"], e["to"]): e for e in manifest.get("exceptions", [])
    }

    edges: dict[tuple[str, str], Counter] = defaultdict(Counter)
    violations: dict[tuple[str, str], list[str]] = defaultdict(list)

    # Package resolution order for names not declared locally.  It is the
    # breadth-first transitive closure of the package's production and
    # test-scoped local imports, always preferring the package itself.
    # Direct dependencies are visited by ascending declared layer so that
    # common names resolve to foundations before integration packages.
    def make_resolution_order(start: str) -> list[str]:
        order = [start]
        queue = [start]
        while queue:
            current = queue.pop(0)
            deps = sorted(
                package_all_imports.get(current, set()),
                key=lambda dep: (packages[dep]["layer"], dep),
            )
            for dep in deps:
                if dep not in order:
                    order.append(dep)
                    queue.append(dep)
        return order

    resolution_order = {
        pkg_id: make_resolution_order(pkg_id) for pkg_id in packages
    }

    for path in all_mbt:
        consumer = assigned.get(path)
        if consumer is None:
            continue
        pkg = package_of(path)
        text = texts[path]
        locals_here = local_bindings(text) - declared_in_file[path]
        counts: Counter = Counter()
        for m in IDENT.finditer(text):
            name = m.group(0)
            if name in locals_here:
                continue
            # Ignore field/method selections (`x.field`); the receiver
            # type/function references remain visible elsewhere.
            j = m.start() - 1
            while j >= 0 and text[j] in " \t":
                j -= 1
            if j >= 0 and text[j] == ".":
                continue
            # For lowercase function names, count direct calls only.
            # This keeps pattern variables that happen to share a
            # top-level function's name (e.g. `DNFst(inner, _)`) from
            # fabricating a component edge.  Types/constructors and
            # top-level lets are counted at every occurrence.
            k = m.end()
            while k < len(text) and text[k] in " \t\n":
                k += 1
            owner_candidates = [owners[c].get(name) for c in resolution_order[pkg]]
            if name[:1].islower() and not (k < len(text) and text[k] == "("):
                # Keep non-call occurrences only for a top-level let.
                is_let = False
                for cand_pkg in resolution_order[pkg]:
                    if kinds.get((cand_pkg, name)) == "let":
                        is_let = True
                        break
                if not is_let and any(owner_candidates):
                    continue
            counts[name] += 1
        for name, cnt in counts.items():
            owner = None
            owner_pkg = None
            for cand in resolution_order[pkg]:
                if name in owners[cand]:
                    owner = owners[cand][name]
                    owner_pkg = cand
                    break
            if owner is None or owner == path:
                continue
            provider = assigned.get(owner)
            if provider is None or provider == consumer:
                continue
            edges[(consumer, provider)][name] += cnt
            if consumer in {"laws", "registry", "tests", "app"}:
                continue
            if components[consumer].get("observer", False):
                continue
            allowed = components[consumer]["depends_on"]
            if "*" in allowed or provider in allowed:
                continue
            if (consumer, provider) in exceptions:
                continue
            if len(violations[(consumer, provider)]) < 24:
                violations[(consumer, provider)].append(
                    f"{name}:{kinds.get((owner_pkg, name), '?')}@{owner.relative_to(ROOT)}"
                )

    for (consumer, provider), names in sorted(violations.items()):
        errors.append(
            f"component edge {consumer} -> {provider} is not allowed; e.g. "
            + ", ".join(sorted(set(names)))
        )

    # ---- metrics ---------------------------------------------------------
    def count_lines(path: Path) -> int:
        return path.read_text().count("\n") + (0 if path.read_text().endswith("\n") else 1)

    metrics = {
        "federations": {},
        "packages": {},
        "components": {},
        "totals": {
            "mbt_files": len(all_mbt),
            "mbt_lines": sum(count_lines(p) for p in all_mbt),
        },
    }
    for fed_id, fed in federations.items():
        fed_pkgs = set(fed["packages"])
        files = [p for p in all_mbt if package_of(p) in fed_pkgs]
        metrics["federations"][fed_id] = {
            "packages": fed["packages"],
            "mbt_files": len(files),
            "mbt_lines": sum(count_lines(p) for p in files),
        }
    if unification is not None:
        u_pkgs = set(unification["packages"])
        u_files = [p for p in all_mbt if package_of(p) in u_pkgs]
        metrics["federations"][unification["id"]] = {
            "packages": unification["packages"],
            "observer": True,
            "mbt_files": len(u_files),
            "mbt_lines": sum(count_lines(p) for p in u_files),
        }
    for pkg_id, pkg in packages.items():
        files = [p for p in all_mbt if package_of(p) == pkg_id]
        metrics["packages"][pkg_id] = {
            "path": pkg["path"],
            "layer": pkg["layer"],
            "mbt_files": len(files),
            "mbt_lines": sum(count_lines(p) for p in files),
        }
    for comp_id, comp in components.items():
        files = [p for p, c in assigned.items() if c == comp_id]
        metrics["components"][comp_id] = {
            "layer": comp["layer"],
            "mbt_files": len(files),
            "mbt_lines": sum(count_lines(p) for p in files),
            "depends_on": comp["depends_on"],
        }

    if args.list_edges:
        print("component edges (consumer -> provider: distinct names)")
        for (a, b), counter in sorted(edges.items()):
            print(f"  {a} -> {b}: {len(counter)} ({sum(counter.values())} refs)")
    if args.json:
        print(json.dumps(metrics, ensure_ascii=False, indent=2, sort_keys=True))

    if errors:
        print("architecture check FAILED:", file=sys.stderr)
        for e in errors:
            print(" -", e, file=sys.stderr)
        return 1

    total = metrics["totals"]
    fed_label = (
        f"{len(federations)} federations + unification apex, "
        if federations
        else ""
    )
    print(
        f"architecture ok: {fed_label}{len(packages)} packages, {len(components)} components, "
        f"{total['mbt_files']} .mbt files, {total['mbt_lines']} .mbt lines"
    )
    for fed_id, fm in metrics["federations"].items():
        role = "apex" if fm.get("observer") else "federation"
        print(
            f"  {role} {fed_id} ({len(fm['packages'])} pkgs): "
            f"{fm['mbt_files']} files, {fm['mbt_lines']} lines"
        )
    for pkg_id in sorted(metrics["packages"], key=lambda k: metrics["packages"][k]["layer"]):
        m = metrics["packages"][pkg_id]
        print(f"  package {pkg_id}: {m['mbt_files']} files, {m['mbt_lines']} lines")
    for comp_id in sorted(metrics["components"], key=lambda k: metrics["components"][k]["layer"]):
        m = metrics["components"][comp_id]
        print(f"  L{m['layer']} {comp_id}: {m['mbt_files']} files, {m['mbt_lines']} lines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
