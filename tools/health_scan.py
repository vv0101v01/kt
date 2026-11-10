#!/usr/bin/env python3
r"""Repo-wide health scan (v3): transitive dead functions/methods/types + empty stubs + exact & alpha duplicates.

Upgrades over v2:
  1. Parses generic `fn[...]` and qualified `Type::method` definitions while skipping `impl ... with fn` headers.
  2. Strips `//` comments and string/char literals while preserving MoonBit `\{ ... }` interpolations.
  3. Eliminates all 5 v2 blind spots:
     - Excludes self-calls inside a function's own body (catches dead recursive functions).
     - Does NOT exempt `pub` functions merely because they appear in `spec.mbt` or `facade.mbt` / `reexport_*.mbt`.
     - Matches `Type::method` via `.method(` and `Type::method` (avoids collisions with unrelated field/local names).
     - Excludes own declaration span, `extend Type with ...`, and `impl ... for Type` headers when counting type uses
       (catches dead `#derive` structs/enums).
     - Detects alpha-equivalent intra-package private helper duplicates in addition to exact body hashes.

Governance note: this is a *report generator*, not a gate. It never edits files.
Usage:  python3 tools/health_scan.py > tools/health_report.md
"""
import glob
import hashlib
import os
import re
from collections import Counter, defaultdict

SKIP_DIRS = {".mooncakes", "_build", "cmd/probe"}

FN_RE = re.compile(
    r"^(priv\s+|pub(?:\((?:all|open)\))?\s+|pub\s+)?fn(?:\[[^\]]*\])?\s+"
    r"(?:([A-Za-z_][A-Za-z0-9_]*)::)?([A-Za-z_][A-Za-z0-9_]*)"
)
IMPL_RE = re.compile(r"^(?:pub\s+)?impl\b")
TYPE_RE = re.compile(
    r"^(?:pub(?:\((?:all|open)\))?\s+|pub\s+|priv\s+)?(struct|enum|type|trait)(?:\[[^\]]*\])?\s+([A-Z][A-Za-z0-9_]*)"
)
EMPTY_ENUM_RE = re.compile(r"\benum\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{\s*\}")
IDENT_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")

PROTECTED_ENTRYPOINTS = {
    ("cmd/main/main.mbt", "main"),
    ("cmd/metatheory/main.mbt", "main"),
    ("cmd/showcase/main.mbt", "main"),
    ("cmd/symdemo/main.mbt", "main"),
    ("cmd/semiringreport/main.mbt", "main"),
    ("verify.mbt", "run_all_checks"),
    ("verify.mbt", "print_report"),
    ("spec.mbt", "spec_registry_sound"),
}

ALPHA_KW = {
    "fn", "let", "mut", "if", "else", "match", "for", "in", "while", "loop",
    "break", "continue", "return", "struct", "enum", "type", "trait", "impl",
    "pub", "priv", "true", "false", "Self", "Int", "Int32", "Int64", "UInt",
    "UInt64", "Double", "Float", "Bool", "String", "Bytes", "Char", "Unit",
    "Array", "FixedArray", "Map", "Option", "Some", "None", "Result", "Ok",
    "Err", "BigInt",
}


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


def normalize(body):
    return re.sub(r"\s+", "", body)


def alpha_canon(sig_text, body):
    # Extract parameter types + return type from signature so distinct concrete types stay distinct
    sig_types = "::".join(re.findall(r":\s*([A-Za-z0-9_\[\],\s\?]+?)(?=[,\)])|->\s*([A-Za-z0-9_\[\],\s\?]+?)(?=\{|$)", sig_text) and [
        re.sub(r"\s+", "", m.group(1) or m.group(2))
        for m in re.finditer(r":\s*([^,\)=\{]+)|->\s*([^\{]+)", sig_text)
    ])
    toks = re.findall(r"[A-Za-z_][A-Za-z0-9_]*|\d+|==|!=|<=|>=|&&|\|\||->|=>|[^\s]", body)
    mapping = {}
    out = [sig_types]
    for idx, t in enumerate(toks):
        prev_tok = toks[idx - 1] if idx > 0 else ""
        next_tok = toks[idx + 1] if idx + 1 < len(toks) else ""
        # Keep keywords, field/method names (`.foo`), and called function names (`foo(`) intact;
        # alpha-rename only bound parameters and local variables.
        if (
            re.match(r"^[a-z_][A-Za-z0-9_]*$", t)
            and t not in ALPHA_KW
            and prev_tok != "."
            and next_tok != "("
        ):
            if t not in mapping:
                mapping[t] = f"v{len(mapping)}"
            out.append(mapping[t])
        else:
            out.append(t)
    return " ".join(out)


def scan():
    clean_src = {}
    for f in files():
        txt = open(f, encoding="utf-8").read()
        clean_src[f] = strip_comments_keep_interp(txt)

    # ---- 1. function bodies (brace matching on comment/string-stripped code) --
    funcs = []
    for f, ct in clean_src.items():
        clines = ct.split("\n")
        i = 0
        while i < len(clines):
            line = clines[i]
            if IMPL_RE.match(line):
                i += 1
                continue
            m = FN_RE.match(line)
            if not m:
                i += 1
                continue
            vis = (m.group(1) or "").strip() or "priv"
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
            sig_only = ""
            if started:
                fb = clines[sig_end].find("{")
                sig_only = ("\n".join(clines[i:sig_end]) + "\n" + clines[sig_end][:fb]).strip()
                if sig_end == j:
                    body_only = clines[sig_end][fb:]
                else:
                    body_only = clines[sig_end][fb:] + "\n" + "\n".join(clines[sig_end + 1 : j + 1])
            sig_after_name = sig_only[m.end() :] if len(sig_only) > m.end() else ""
            call_surface = sig_after_name + "\n" + body_only
            funcs.append({
                "id": len(funcs),
                "file": f,
                "start": i + 1,
                "end": j + 1,
                "vis": vis,
                "tname": tname,
                "fname": fname,
                "qual": qual,
                "sig": sig_only,
                "body": body_only,
                "toks": set(re.findall(r"(?<!\.)\b[a-z_][A-Za-z0-9_]*\b", call_surface)),
                "dots": set(mm.group(1) for mm in re.finditer(r"\.([a-z_][A-Za-z0-9_]*)\s*\(", call_surface)),
                "quals": set((mm.group(1), mm.group(2)) for mm in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)::([a-z_][A-Za-z0-9_]*)\b", call_surface)),
            })
            i = j + 1

    # ---- 2. transitive dead-function/method fixed point -----------------------
    top_toks, top_dots, top_quals = set(), set(), set()
    by_file_funcs = defaultdict(list)
    for fn in funcs:
        by_file_funcs[fn["file"]].append(fn)

    for f, ct in clean_src.items():
        if f in ("facade.mbt", "spec.mbt") or os.path.basename(f).startswith("reexport_"):
            continue
        masked = ct.split("\n")
        for fn in by_file_funcs[f]:
            for k in range(fn["start"] - 1, min(fn["end"], len(masked))):
                masked[k] = ""
        rem = re.sub(r"\b(?:pub\s+)?using\s+@[A-Za-z0-9_]+\s*\{[^}]*\}", " ", "\n".join(masked), flags=re.S)
        top_toks.update(re.findall(r"(?<!\.)\b[a-z_][A-Za-z0-9_]*\b", rem))
        top_dots.update(mm.group(1) for mm in re.finditer(r"\.([a-z_][A-Za-z0-9_]*)\s*\(", rem))
        top_quals.update((mm.group(1), mm.group(2)) for mm in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)::([a-z_][A-Za-z0-9_]*)\b", rem))

    alive = set(range(len(funcs)))
    while True:
        tok_holders = defaultdict(set)
        dot_holders = defaultdict(set)
        qual_holders = defaultdict(set)
        for fid in alive:
            fn = funcs[fid]
            for t in fn["toks"]:
                tok_holders[t].add(fid)
            for d in fn["dots"]:
                dot_holders[d].add(fid)
            for q in fn["quals"]:
                qual_holders[q].add(fid)
        newly_dead = []
        for fid in sorted(alive):
            fn = funcs[fid]
            if (fn["file"], fn["fname"]) in PROTECTED_ENTRYPOINTS:
                continue
            if fn["fname"] in ("main", "init", "equal", "not_equal", "to_repr", "output", "hash", "hash_combine"):
                continue
            if fn["tname"]:
                if not (dot_holders[fn["fname"]] - {fid}) and not (qual_holders[(fn["tname"], fn["fname"])] - {fid}) and fn["fname"] not in top_dots and (fn["tname"], fn["fname"]) not in top_quals:
                    newly_dead.append(fid)
            else:
                if not (tok_holders[fn["fname"]] - {fid}) and not (dot_holders[fn["fname"]] - {fid}) and fn["fname"] not in top_toks and fn["fname"] not in top_dots:
                    newly_dead.append(fid)
        if not newly_dead:
            break
        for fid in newly_dead:
            alive.remove(fid)

    dead = [
        (funcs[fid]["file"], funcs[fid]["start"], funcs[fid]["vis"], funcs[fid]["qual"])
        for fid in range(len(funcs))
        if fid not in alive
    ]

    # ---- 3. unreferenced types (excluding own span + extend/impl + facade) ----
    types = []
    for f, ct in clean_src.items():
        lines = ct.split("\n")
        i = 0
        while i < len(lines):
            m = TYPE_RE.match(lines[i])
            if not m:
                i += 1
                continue
            kind, tname = m.group(1), m.group(2)
            depth, started, j = 0, False, i
            if "{" not in lines[i] and kind == "type":
                j = i
            else:
                while j < len(lines):
                    if "{" in lines[j]:
                        started = True
                    depth += lines[j].count("{") - lines[j].count("}")
                    if started and depth <= 0:
                        break
                    j += 1
            span_txt = "\n".join(lines[i : j + 1])
            own_cnt = Counter(IDENT_RE.findall(span_txt))[tname]
            types.append((f, i + 1, kind, tname, own_cnt))
            i = j + 1

    global_type_cnt = Counter()
    empty_enums = []
    for f, ct in clean_src.items():
        for m in EMPTY_ENUM_RE.finditer(ct):
            empty_enums.append((f, ct.count("\n", 0, m.start()) + 1, m.group(1)))
        if f in ("facade.mbt",) or os.path.basename(f).startswith("reexport_"):
            continue
        t2 = re.sub(r"^(?:pub\s+)?extend\s+[A-Za-z0-9_]+\s+with[^\n]*", "", ct, flags=re.M)
        t2 = re.sub(r"^(?:pub\s+)?impl[^\n]*?\bfor\s+[A-Za-z0-9_]+(?:\[[^\]]*\])?[^\n{]*", "", t2, flags=re.M)
        t2 = re.sub(r"\b(?:pub\s+)?using\s+@[A-Za-z0-9_]+\s*\{[^}]*\}", " ", t2, flags=re.S)
        global_type_cnt.update(IDENT_RE.findall(t2))

    dead_types = [
        (f, line, kind, tname)
        for f, line, kind, tname, own_cnt in types
        if global_type_cnt[tname] - own_cnt <= 0
    ]

    # ---- 4. duplicated bodies (exact hash + intra-package priv alpha-equiv) ---
    same_pkg_groups = defaultdict(list)
    global_groups = defaultdict(list)
    priv_alpha_groups = defaultdict(list)
    for fn in funcs:
        f, qual, line, body_only = fn["file"], fn["qual"], fn["start"], fn["body"]
        norm = normalize(body_only)
        line_cnt = body_only.count("\n") + 1
        pkg = os.path.dirname(f) or "."
        if line_cnt >= 3 and len(norm) >= 70:
            h = hashlib.sha1(norm.encode()).hexdigest()
            same_pkg_groups[(pkg, h)].append((f, line, qual, len(norm)))
            if len(norm) >= 130:
                global_groups[h].append((f, line, qual, len(norm)))
        if fn["vis"] == "priv" and line_cnt >= 4 and len(norm) >= 70:
            ac = alpha_canon(fn["sig"], body_only)
            ah = hashlib.sha1(ac.encode()).hexdigest()
            priv_alpha_groups[(pkg, ah)].append((f, line, qual, len(norm)))

    seen_dup_keys = set()
    dups = []
    for g in list(same_pkg_groups.values()) + list(global_groups.values()) + list(priv_alpha_groups.values()):
        if len(g) > 1:
            key = tuple((x[0], x[1], x[2]) for x in g)
            if key not in seen_dup_keys:
                seen_dup_keys.add(key)
                dups.append(g)
    dups.sort(key=lambda g: -g[0][3] * len(g))

    # ---- 5. near duplicates (same identifier set on substantial bodies) -------
    coarse = defaultdict(list)
    for fn in funcs:
        f, qual, line, body_only = fn["file"], fn["qual"], fn["start"], fn["body"]
        norm = normalize(body_only)
        if len(norm) < 200:
            continue
        ids = tuple(sorted(set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", body_only))))
        coarse[hashlib.sha1(str(ids).encode()).hexdigest()].append((f, line, qual, len(norm)))
    near = [v for v in coarse.values() if len(v) > 1 and len(v) <= 6]
    near.sort(key=lambda g: -g[0][3] * len(g))

    func_records = [(fn["file"], fn["qual"], fn["fname"], fn["vis"], fn["start"], fn["body"]) for fn in funcs]
    return func_records, dead, dead_types, empty_enums, dups, near


def main():
    funcs, dead, dead_types, empty_enums, dups, near = scan()
    print("# 全代碼健檢報告（自動產生）\n")
    print("由 `python3 tools/health_scan.py`（v3）產生（含遞移死碼不動點、`Type::method` 精確呼叫匹配、")
    print("排除自遞迴／`spec.mbt`／`facade.mbt`／`reexport_*`／`extend` 虛假引用、純函式體與私有助手 α 等價查重）。")
    print("此檔是**報告**，不是閘門；閘門仍是 `moon check --deny-warn` + `python3 tools/arch_check.py`。\n")

    print("## 0. 規模\n")
    print("| 項目 | 數量 |")
    print("|---|---|")
    print("| 掃描到的函式／方法定義 | %d |" % len(funcs))
    print("| 完全無引用函式／方法（遞移死碼候選） | %d |" % len(dead))
    print("| 完全無引用型別（`struct`/`enum`/`type`/`trait`） | %d |" % len(dead_types))
    print("| 空殼列舉（`enum Foo {}`） | %d |" % len(empty_enums))
    print("| 完全相同或同包 α 等價函式體的重複組 | %d |" % len(dups))
    print("| 結構極相近的重複組 | %d |" % len(near))
    print()

    print("## 1. 死碼候選（全倉零引用函式／方法／型別／空殼）\n")
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

    print("## 2. 完全相同或同包 α 等價的函式體\n")
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
