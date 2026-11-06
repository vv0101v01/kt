#!/usr/bin/env python3
"""登記表的機械對帳（`lake build` 之外的便宜檢查）。

兩件事：
  1. `provedLaws` 的字串條數 == `example : provedLaws.length = N` 的 N；
  2. 每一筆登記都有一個 `#check`（否則「登記了但不存在」的防線就破了一個洞）。

用法：python3 tools/registry_audit.py   （離開碼 0 = 對得上）
"""
import re, sys, pathlib

src = pathlib.Path(__file__).resolve().parent.parent / "KtLaws" / "Registry.lean"
text = src.read_text(encoding="utf-8")

head = text.split("\nsection Checks")[0]
laws = [l for l in head.splitlines() if l.strip().startswith('"')]
declared = re.search(r"provedLaws\.length = (\d+) := rfl", text)
checks = re.findall(r"^#check @(\S+)$", text, re.M)

if not declared:
    sys.exit("找不到 `example : provedLaws.length = N := rfl`")
n = int(declared.group(1))

ok = True
if len(laws) != n:
    print(f"✗ provedLaws 有 {len(laws)} 筆，但宣告 length = {n}"); ok = False
if len(checks) != n:
    print(f"✗ #check 有 {len(checks)} 條，但登記 {n} 筆"); ok = False
if len(set(checks)) != len(checks):
    print("✗ #check 有重複"); ok = False

print(("✔" if ok else "✗") + f" registry: {len(laws)} 筆登記 / {len(checks)} 條 #check / 宣告 {n}")
sys.exit(0 if ok else 1)
