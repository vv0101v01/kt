#!/usr/bin/env python3
r"""Repo-wide health scan: dead functions/types + empty stubs + duplicated function bodies + near-duplicates.

Upgrades over v1:
  1. Parses generic `fn[...]` and qualified `Type::method` definitions in addition to plain `fn`.
  2. Strips `//` comments and string/char literals while preserving MoonBit `\{ ... }` interpolations,
     and excludes `reexport_*.mbt` / `using @pkg { ... }` shims from caller counts (while honoring
     executable specification symbols registered in `spec.mbt`).
  3. Scans `struct` / `enum` declarations for unreferenced types and empty-shell stub `enum`s.
  4. Hashes function bodies (excluding signatures) so renamed copy-pastes are detected.

Governance note: this is a *report generator*, not a gate. It never edits files.
Usage:  python3 tools/health_scan.py > tools/health_report.md
"""
import glob
import hashlib
import os
import re
from collections import defaultdict

SKIP_DIRS = {".mooncakes", "_build", "cmd/probe"}

FN_RE = re.compile(
    r"^(priv\s+|pub(?:\((?:all|open)\))?\s+|pub\s+)?fn(?:\[[^\]]*\])?\s+"
    r"(?:([A-Za-z_][A-Za-z0-9_]*)::)?([A-Za-z_][A-Za-z0-9_]*)"
)
TYPE_RE = re.compile(
    r"^(?:pub(?:\((?:all|open)\))?\s+|pub\s+|priv\s+)?(struct|enum)\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.M,
)
EMPTY_ENUM_RE = re.compile(r"\benum\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{\s*\}")


def files():
    for f in sorted(glob.glob("**/*.mbt", recursive=True)):
        if any(part in f for part in SKIP_DIRS):
            continue
        yield f


def strip_comments_keep_interp(text):
    """Strip `//` comments and string/char literals while keeping `\\{ ... }` code interpolations."""
    out = []
    i = 0
    n = len(text)
    mode = "code"
    interp_stack = []
    while i < n:
        ch = text[i]
        if mode == "code":
            if ch == "/" and i + 1 < n and text[i + 1] == "/":
                while i < n and text[i] != "\n":
                    out.append(" ")
                    i += 1
                continue
            if ch == "'" and i + 2 < n:
                if text[i + 1] == "\\" and i + 3 < n and text[i + 3] == "'":
                    out.append("    ")
                    i += 4
                    continue
                if text[i + 2] == "'":
                    out.append("   ")
                    i += 3
                    continue
            if ch == '"':
                mode = "str"
                out.append(" ")
                i += 1
                continue
            if interp_stack:
                if ch == "{":
                    interp_stack[-1] += 1
                elif ch == "}":
                    interp_stack[-1] -= 1
                    if interp_stack[-1] == 0:
                        interp_stack.pop()
                        mode = "str"
                        out.append(" ")
                        i += 1
                        continue
            out.append(ch)
            i += 1
        else:
            if ch == "\\" and i + 1 < n:
                if text[i + 1] == "{":
                    interp_stack.append(1)
                    mode = "code"
                    out.append("  ")
                    i += 2
                    continue
                out.append("  ")
                i += 2
                continue
            if ch == '"':
                mode = "code"
                out.append(" ")
                i += 1
                continue
            out.append("\n" if ch == "\n" else " ")
            i += 1
    return "".join(out)


def load_spec_symbols():
    syms = set()
    if not os.path.exists("spec.mbt"):
        return syms
    spec_txt = open("spec.mbt", encoding="utf-8").read()
    for m in re.finditer(r"Spec(?:Type|Operator|Structure|Theorem),\s*\[(.*?)\]", spec_txt, re.S):
        for sm in re.finditer(r'"([^"]+)"', m.group(1)):
            s = sm.group(1)
            syms.add(s)
            syms.add(s.split("::")[-1])
    return syms


def normalize(body):
    return re.sub(r"\s+", "", body)


def scan():
    raw_src = {}
    clean_src = {}
    for f in files():
        txt = open(f, encoding="utf-8").read()
        raw_src[f] = txt
        clean_src[f] = strip_comments_keep_interp(txt)

    spec_syms = load_spec_symbols()

    # ---- 1. function bodies (brace matching on comment/string-stripped code) --
    funcs = []  # (file, qual_name, short_name, vis, lineno, body_only)
    for f, ct in clean_src.items():
        clines = ct.split("\n")
        for i, line in enumerate(clines):
            m = FN_RE.match(line)
            if not m:
                continue
            vis = (m.group(1) or "").strip()
            tname = m.group(2)
            fname = m.group(3)
            qual = f"{tname}::{fname}" if tname else fname
            depth = 0
            started = False
            sig_end = i
            j = i
            while j < len(clines):
                ln = clines[j]
                if not started and "{" in ln:
                    started = True
                    sig_end = j
                depth += ln.count("{") - ln.count("}")
                if started and depth <= 0:
                    break
                j += 1
            body_only = ""
            if started:
                fb = clines[sig_end].find("{")
                if sig_end == j:
                    body_only = clines[sig_end][fb:]
                else:
                    body_only = clines[sig_end][fb:] + "\n" + "\n".join(clines[sig_end + 1 : j + 1])
            funcs.append((f, qual, fname, vis, i + 1, body_only))

    # ---- 2. code-only reference counting (excluding reexport_* & using shims) -
    code_counts = defaultdict(int)
    for f, ct in clean_src.items():
        if os.path.basename(f).startswith("reexport_"):
            continue
        ct_no_using = re.sub(r"\b(?:pub\s+)?using\s+@[A-Za-z0-9_]+\s*\{[^}]*\}", " ", ct, flags=re.S)
        for ident in re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b", ct_no_using):
            code_counts[ident] += 1

    dead = []
    for f, qual, fname, vis, line, _body in funcs:
        if fname in ("main", "init"):
            continue
        is_pub = vis.startswith("pub")
        if is_pub and (fname in spec_syms or qual in spec_syms):
            continue
        if code_counts[fname] - 1 <= 0:
            dead.append((f, line, vis or "priv", qual))

    # ---- 3. unreferenced types & empty-shell stub enums -----------------------
    dead_types = []
    empty_enums = []
    for f, ct in clean_src.items():
        for m in TYPE_RE.finditer(ct):
            kind, tname = m.group(1), m.group(2)
            if code_counts[tname] - 1 <= 0:
                lineno = ct.count("\n", 0, m.start()) + 1
                dead_types.append((f, lineno, kind, tname))
        for m in EMPTY_ENUM_RE.finditer(ct):
            tname = m.group(1)
            lineno = ct.count("\n", 0, m.start()) + 1
            empty_enums.append((f, lineno, tname))

    # ---- 4. duplicated bodies (body-only hash, excluding signature) ----------
    same_pkg_groups = defaultdict(list)
    global_groups = defaultdict(list)
    for f, qual, _fname, _vis, line, body_only in funcs:
        norm = normalize(body_only)
        line_cnt = body_only.count("\n") + 1
        if line_cnt < 3 or len(norm) < 70:
            continue
        h = hashlib.sha1(norm.encode()).hexdigest()
        pkg = os.path.dirname(f) or "."
        same_pkg_groups[(pkg, h)].append((f, line, qual, len(norm)))
        if len(norm) >= 130:
            global_groups[h].append((f, line, qual, len(norm)))

    seen_dup_keys = set()
    dups = []
    for g in list(same_pkg_groups.values()) + list(global_groups.values()):
        if len(g) > 1:
            key = tuple((x[0], x[1], x[2]) for x in g)
            if key not in seen_dup_keys:
                seen_dup_keys.add(key)
                dups.append(g)
    dups.sort(key=lambda g: -g[0][3] * len(g))

    # ---- 5. near duplicates (same identifier set on substantial bodies) -------
    coarse = defaultdict(list)
    for f, qual, _fname, _vis, line, body_only in funcs:
        norm = normalize(body_only)
        if len(norm) < 200:
            continue
        ids = tuple(sorted(set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", body_only))))
        coarse[hashlib.sha1(str(ids).encode()).hexdigest()].append((f, line, qual, len(norm)))
    near = [v for v in coarse.values() if len(v) > 1 and len(v) <= 6]
    near.sort(key=lambda g: -g[0][3] * len(g))

    return funcs, dead, dead_types, empty_enums, dups, near


def main():
    funcs, dead, dead_types, empty_enums, dups, near = scan()
    print("# 全代碼健檢報告（自動產生）\n")
    print("由 `python3 tools/health_scan.py` 產生（含泛型 `fn[...]`、`Type::method`、`\\{...}` 字串插值保留、")
    print("排除 `reexport_*`／`using` 轉發虛假計數、無引用型別與空殼 `enum` 檢查、純函式體雜湊查重）。")
    print("此檔是**報告**，不是閘門；閘門仍是 `moon check --deny-warn` + `python3 tools/arch_check.py`。\n")

    print("## 0. 規模\n")
    print("| 項目 | 數量 |")
    print("|---|---|")
    print("| 掃描到的函式／方法定義 | %d |" % len(funcs))
    print("| 完全無引用函式（死碼候選） | %d |" % len(dead))
    print("| 完全無引用型別（`struct`/`enum`） | %d |" % len(dead_types))
    print("| 空殼列舉（`enum Foo {}`） | %d |" % len(empty_enums))
    print("| 完全相同函式體的重複組 | %d |" % len(dups))
    print("| 結構極相近的重複組 | %d |" % len(near))
    print()

    print("## 1. 死碼候選（全倉零引用函式／型別／空殼）\n")
    if not dead and not dead_types and not empty_enums:
        print("（無）\n")
    else:
        if dead:
            print("| 檔案 | 行 | 可見性 | 名稱 |")
            print("|---|---|---|---|")
            for f, line, vis, name in dead:
                print("| `%s` | %d | %s | `%s` |" % (f, line, vis, name))
            print()
        if dead_types:
            print("| 檔案 | 行 | 類別 | 型別 |")
            print("|---|---|---|---|")
            for f, line, kind, tname in dead_types:
                print("| `%s` | %d | %s | `%s` |" % (f, line, kind, tname))
            print()
        if empty_enums:
            for f, line, tname in empty_enums:
                print("- 空殼 `enum`：`%s:%d` `%s`" % (f, line, tname))
            print()

    print("## 2. 完全相同的函式體\n")
    if not dups:
        print("（無）\n")
    else:
        for g in dups:
            print("- 重複組（正規化長度 %d）：" % g[0][3])
            for f, line, name, _ in g:
                print("  - `%s:%d` `%s`" % (f, line, name))
        print()

    print("## 3. 結構極相近（同一組識別字集合，疑似複製貼上）\n")
    if not near:
        print("（無）\n")
    else:
        for g in near[:20]:
            print("- 近似組（長度 %d）：" % g[0][3])
            for f, line, name, _ in g:
                print("  - `%s:%d` `%s`" % (f, line, name))
        print()


if __name__ == "__main__":
    main()
