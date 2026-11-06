#!/usr/bin/env python3
"""Repo-wide health scan: dead code candidates + duplicated function bodies + size debt.

Governance note: this is a *report generator*, not a gate. It never edits files.
Usage:  python3 tools/health_scan.py > tools/health_report.md
"""
import glob
import hashlib
import os
import re
import sys
from collections import defaultdict

SKIP_DIRS = {".mooncakes", "_build", "cmd/probe"}


def files():
    for f in sorted(glob.glob("**/*.mbt", recursive=True)):
        if any(part in f for part in SKIP_DIRS):
            continue
        yield f


FN_RE = re.compile(r"^(priv\s+|pub(?:\(all\))?\s+|pub\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)")


def normalize(body):
    """Strip comments and whitespace so formatting differences do not hide duplicates."""
    out = []
    for line in body.split("\n"):
        s = line.split("//")[0]
        out.append(re.sub(r"\s+", "", s))
    return "".join(out)


def scan():
    src = {}
    for f in files():
        src[f] = open(f, encoding="utf-8").read()

    # ---- 1. function bodies (brace matching, depth-aware) --------------------
    funcs = []  # (file, name, visibility, lineno, body)
    for f, text in src.items():
        lines = text.split("\n")
        for i, line in enumerate(lines):
            m = FN_RE.match(line)
            if not m:
                continue
            vis = (m.group(1) or "").strip()
            name = m.group(2)
            # gather body by brace matching from the signature line
            depth = 0
            started = False
            chunk = []
            j = i
            while j < len(lines):
                ln = lines[j]
                chunk.append(ln)
                stripped = ln.split("//")[0]
                depth += stripped.count("{") - stripped.count("}")
                if "{" in stripped:
                    started = True
                if started and depth <= 0:
                    break
                j += 1
            funcs.append((f, name, vis, i + 1, "\n".join(chunk)))

    # ---- 2. reference counting (single pass per file) ----------------------
    per_file = {}
    total = defaultdict(int)
    for f, text in src.items():
        c = defaultdict(int)
        for ident in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", text):
            c[ident] += 1
        per_file[f] = c
        for k, v in c.items():
            total[k] += v

    dead = []
    for f, name, vis, line, body in funcs:
        others = total[name] - per_file[f][name]
        local = per_file[f][name] - 1
        if others == 0 and local == 0:
            dead.append((f, line, vis or "priv", name))

    # ---- 3. duplicated bodies ---------------------------------------------
    groups = defaultdict(list)
    for f, name, vis, line, body in funcs:
        norm = normalize(body)
        if len(norm) < 90:  # trivial one-liners are not interesting
            continue
        groups[hashlib.sha1(norm.encode()).hexdigest()].append((f, line, name, len(norm)))

    dups = [v for v in groups.values() if len(v) > 1]
    dups.sort(key=lambda g: -g[0][3] * len(g))

    # ---- 4. near duplicates (coarse: same multiset of identifiers) ---------
    coarse = defaultdict(list)
    for f, name, vis, line, body in funcs:
        norm = normalize(body)
        if len(norm) < 200:
            continue
        ids = tuple(sorted(set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", body))))
        coarse[hashlib.sha1(str(ids).encode()).hexdigest()].append((f, line, name, len(norm)))
    near = [v for v in coarse.values() if len(v) > 1 and len(v) <= 6]
    near.sort(key=lambda g: -g[0][3] * len(g))

    return funcs, dead, dups, near


def main():
    funcs, dead, dups, near = scan()
    print("# 全代碼健檢報告（自動產生）\n")
    print("由 `python3 tools/health_scan.py` 產生。此檔是**報告**，不是閘門；閘門仍是")
    print("`moon check --deny-warn` + `python3 tools/arch_check.py`。\n")

    print("## 0. 規模\n")
    print("| 項目 | 數量 |")
    print("|---|---|")
    print("| 掃描到的函式定義 | %d |" % len(funcs))
    print("| 完全無引用（死碼候選） | %d |" % len(dead))
    print("| 完全相同函式體的重複組 | %d |" % len(dups))
    print("| 結構極相近的重複組 | %d |" % len(near))
    print()

    print("## 1. 死碼候選（全倉零引用）\n")
    if not dead:
        print("（無）\n")
    else:
        print("| 檔案 | 行 | 可見性 | 名稱 |")
        print("|---|---|---|---|")
        for f, line, vis, name in dead:
            print("| `%s` | %d | %s | `%s` |" % (f, line, vis, name))
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
