#!/usr/bin/env python3
"""Regenerate meta/*/laws.mbt aggregators from the `pub fn law_*` definitions.

The repo's governance (tools/arch_check.py) forbids `*_test.mbt` and `^test ` blocks,
so every proposition lives in a `law_*` function and the aggregator lists them all.
This generator keeps that list in sync mechanically — no hand-maintained index.
"""
import re, glob, os, sys

PKGS = ["core", "instances", "iit", "reflect"]

HEADER = """// ---------------------------------------------------------------------------
// {pkg} — 定律登記（**由 tools/gen_laws.py 產生，請勿手改**）
// ---------------------------------------------------------------------------
// 每一條定律都是一個 `law_*` 函式；這裡只負責把它們串成一個清單，
// 由 `cmd/metatheory` 逐條執行並印出。要加定律就加 `pub fn law_*`，再跑一次產生器。
"""

CHK = '''
///| 定律登記：把一個可判定的命題收進報告（全聯邦唯一定義，其他套件用 `@core.chk`）。
pub fn chk(out : Array[(String, Bool)], label : String, cond : Bool) -> Unit {
  out.push((label, cond))
}
'''


def laws_of(path):
    src = open(path).read()
    # 簽名可能跨行（moonfmt 會把長簽名折行），所以空白一律當成可選。
    return re.findall(
        r"pub fn (law_[A-Za-z0-9_]+)\s*\(\s*\)\s*->\s*Array\[\s*\(\s*String\s*,\s*Bool\s*\)\s*,?\s*\]",
        src,
    )


def main():
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    total = 0
    for pkg in PKGS:
        names = []
        for f in sorted(glob.glob(os.path.join(root, "meta", pkg, "*.mbt"))):
            if f.endswith("laws.mbt"):
                continue
            for n in laws_of(f):
                if n not in names:
                    names.append(n)
        total += len(names)
        body = [HEADER.format(pkg=pkg)]
        if pkg == "core":
            body.append(CHK)
        body.append("///| %s 套件的全部定律。" % pkg)
        body.append("pub fn all_laws() -> Array[(String, Bool)] {")
        body.append("  let out : Array[(String, Bool)] = []")
        for n in sorted(names):
            body.append("  for (l, b) in %s() {" % n)
            body.append("    out.push((l, b))")
            body.append("  }")
        body.append("  out")
        body.append("}")
        open(os.path.join(root, "meta", pkg, "laws.mbt"), "w").write("\n".join(body) + "\n")
        print("meta/%s/laws.mbt: %d laws" % (pkg, len(names)))
    print("total law functions:", total)


if __name__ == "__main__":
    main()
