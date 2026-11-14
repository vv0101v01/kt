# `cmd/main/` — 定理登記表的串流 CLI

**位置：pkgL8 / compL12。** 只消費 root 的登記／管線 API；數學演算法仍在各下層 package。core `env/string/json/bench` 只負責入口解析、退出碼、JSON 編碼及觀測時間。

## 1. 預設全量契約不變

```bash
moon run cmd/main --target wasm-gc
```

執行 **139 個原有檢核**，完成一項便印一項；結尾 `passed 139/139`。任何失敗仍非零退出。`run_all_checks()` 保留收集 API，`print_report()` 改用同一個串流 runner，沒有另一套會漏檢的快速清單。

不要把 `cmd/main` 的 139 個檢核與 `cmd/showcase` 的 50 個證書混加。兩者皆是 CI 的必要驗收入口。

## 2. 訊息入口 → 運算 → 出口

```text
CLI options → 完整驗 ID／重複／預算 → CheckTask 閉包清單（尚未運算）
    → started(id,name) → 真正呼叫原有檢核 → result(id,name,ok,elapsed_ms)
    → coverage-aware summary → exit code
```

```bash
moon build --target wasm-gc
WASM=_build/wasm-gc/debug/build/cmd/main/main.wasm

moonrun "$WASM" -- --list --jsonl                 # 只讀 manifest，不跑定理
moonrun "$WASM" -- --progress                     # 全量，即時 START/PASS/FAIL
moonrun "$WASM" -- --jsonl                        # 全量，機讀事件
moonrun "$WASM" -- --checks=84,114 --jsonl         # 指定次序的局部執行
moonrun "$WASM" -- --checks=1,2 --max-checks=1 --jsonl
moonrun "$WASM" -- --max-checks=0 --jsonl          # 全數 deferred，沒有執行
```

- ID 是當前 manifest 的 **1-based 位置**；標籤／登記改變後應重新讀取 manifest。不是永久的數學定理識別碼。
- 無效、空、重複、越界 ID 或負預算在任何檢核開始前拒絕，exit **2**。
- `max_checks` 是**檢核之間**的合作式配額，不能中斷一個正在執行的慢檢核，不是毫秒 deadline 或記憶體上限。
- `selected_all_passed=true` 只代表要求的範圍全部完成且通過；只要有 deferred 就是 false。
- `full_verified=true` 必須涵蓋當前 manifest 的每個 ID、沒有失敗。局部成功可以 exit **0**，但必須明列 `full_verified=false`；不可只看退出碼當全量成功。
- 實際檢核失敗 exit **1**（預設相容入口以 abort 非零退出）。時間只作觀測，沒有按快慢判定數學結果的閾值。

## 3. 平衡的多行程執行

```bash
python3 tools/run_pipeline.py --jobs=2 --plan --jsonl
python3 tools/run_pipeline.py --jobs=2 --require-full --jsonl
```

host runner 先查 manifest，再按**只含時間**的 `tools/check_costs.json` 作 longest-processing-time-first 分派；每個 worker 是獨立 `moonrun`，不分享可變 BDD manager 或 kernel 狀態。預設最多 2 個、硬限制 1..8 個 worker，並不保證更多 worker 更快或記憶體峰值更低。

它逐筆拒絕漏項、重複、錯序、錯標籤、無 start 的 result、錯誤摘要、非零退出、超時及非有限時間。只有精確完整覆蓋才能給出全量成功。**CI 使用 `--require-full`，會預先拒絕局部／plan-only 請求。**

host 配額、機讀格式、成本校準、演算法重寫及實測限制見 [管線與效能設計](../../docs/PERFORMANCE_PIPELINE.md)。所有後端驗收及數值以 `agent.v2.md` 最新報告為準；本輪只驗 wasm-gc debug，不聲稱 native／release／JS 已通過。
