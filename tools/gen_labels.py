#!/usr/bin/env python3
"""把 cmd/metatheory 實際跑出的定律標籤，依套件分族寫成 lean/labels/moonbit-labels.md。

用實際執行輸出（不是靜態解析），所以會漏登記的 `law_*` 在這裡一定看得出來。
用法：export PATH="$HOME/.moon/bin:$PATH" && python3 tools/gen_labels.py
"""
import glob
import re
import subprocess
import sys

PKGS = ["core", "instances", "iit", "reflect"]


def run_metatheory():
    out = subprocess.run(
        ["moon", "run", "cmd/metatheory", "--target", "wasm-gc"],
        capture_output=True, text=True, timeout=900,
    )
    return out.stdout + out.stderr


def labels(text):
    labs = []
    for line in text.splitlines():
        m = re.match(r"^ok\s+\[\s*\d+\]\s+(.*)$", line)
        if m:
            labs.append(m.group(1))
    return labs


def pkg_of(lab, src):
    parts = re.split(r"(?<= )\\\{", lab)
    cands = [lab] + ([parts[0]] if len(parts) > 1 else [])
    for c in cands:
        c2 = re.sub(r"\s+", " ", c).strip()
        for p, t in src.items():
            if c2 and c2 in t:
                return p
    for kw, p in [("nbe:", "reflect"), ("universe reflection:", "reflect"),
                  ("reflection:", "reflect"), ("link:", "reflect"),
                  ("iit:", "iit"), ("instances:", "instances")]:
        if lab.startswith(kw):
            return p
    return None


def family(lab):
    """標籤的族：去掉尾部 #n 與動態片段。"""
    base = re.sub(r"\s*#\d+$", "", lab)
    base = re.split(r"\\\{", base)[0].strip()
    return base.rstrip(" (#")


def main():
    src = {}
    for p in PKGS:
        txt = "".join(open(f).read() for f in glob.glob(f"meta/{p}/*.mbt"))
        src[p] = re.sub(r"\s+", " ", txt)
    text = run_metatheory()
    labs = labels(text)
    if not labs:
        sys.exit("沒有抓到任何標籤 —— metatheory 沒跑成功")
    groups = {}
    order = []
    for lab in labs:
        p = pkg_of(lab, src) or "?"
        fam = family(lab)
        key = (p, fam)
        if key not in groups:
            groups[key] = []
            order.append(key)
        groups[key].append(lab)
    uniq = len({re.sub(r"\\\{[^}]*\}", "#", l) for l in labs})
    lines = [
        f"## MoonBit 側 {len(labs)} 條定律標籤（逐條）",
        "",
        f"原始 {len(labs)} 條；去重後 {uniq} 條互異。這份清單由 `tools/gen_labels.py` "
        "讀 `cmd/metatheory` 的實際輸出產生，不是手抄。",
        "",
    ]
    for (p, fam) in order:
        items = groups[(p, fam)]
        lines.append(f"## {p} / {fam}  ({len(items)})")
        lines.append("")
        for it in items:
            lines.append(f"- {it}")
        lines.append("")
    open("lean/labels/moonbit-labels.md", "w").write("\n".join(lines))
    print(f"寫出 lean/labels/moonbit-labels.md：{len(labs)} 條、{uniq} 條互異、{len(order)} 族")
    per_pkg = {}
    for (p, _fam), items in groups.items():
        d = per_pkg.setdefault(p, [0, set()])
        d[0] += len(items)
        d[1].update(re.sub(r"\\\{[^}]*\\\}", "#", it) for it in items)
    for p in PKGS:
        if p in per_pkg:
            n, u = per_pkg[p]
            print(f"  {p}: {n} 條（互異 {len(u)}）")


if __name__ == "__main__":
    main()
