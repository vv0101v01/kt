# 效能與訊息管線：入口、運算、出口

2026-11-14；工具鏈 `.moonbit-version` 的正式 **0.10.20+65efd5b93**，驗收後端 **wasm-gc debug**。本頁定義可重用接口與邊界；完整實跑數字、負控制及失敗紀錄集中在 [agent.v2.md 的效能報告](../agent.v2.md#2026-11-14-performance-pipeline)。

## 實測摘要（每種模式 3 次，median）

| 完整工作負載 | 改寫前 | 改寫後 | Wall time 減少 |
|---|---:|---:|---:|
| 139 項定理，單行程 | 240.239 s | 138.205 s | 42.47% |
| 139 項定理，新版雙 worker 管線對舊版單行程 | 240.239 s | 76.989 s | 67.95%（含並行收益） |
| Showcase：39 active／50 證書 | 91.951 s | 66.235 s | 27.97% |

這不是任意機器保證；Linux x86_64／2 logical CPU／固定 stable／wasm-gc debug，編譯排除但行程啟動、JIT、輸出計入，交錯順序、沒有丟掉首輪。原始三個樣本與 min/max 都公開於 [機讀結果](performance-results.json)及 `agent.v2.md`。Main 六次串行 stdout **逐位元相同**；Showcase 去除新增 START 行後相同。串行 main 首訊息 median 從 240.220 s 改為 **0.034777 s**，不是聲稱整體運算只需 35 ms。

## 1. 重新分工，而不是刪除慢檢核

```text
入口層                         排程／觀測層                      領域層（不懂 CLI）
cmd/main options ─────────→ root/check_pipeline.mbt ──────────→ 139 個原有檢核
                           ├─ manifest（閉包，零定理運算）       ├─ face_bdd：配對 restrict + DP
                           ├─ ID／預算完整預驗                  ├─ algebra：精確增量 LLL
                           ├─ started → result callbacks        └─ kernel／homotopy：保留獨立核驗
                           └─ coverage summary
                                      │
tools/run_pipeline.py                │ JSONL
  ├─ 讀 manifest + 純時間成本 ─────────┘
  ├─ LPT 分派至 1..8 個獨立 moonrun（預設 ≤2）
  └─ 嚴格事件／退出碼 reducer ──→ 即時進度 + full_verified／deferred_ids

cmd/showcase ─→ active 配對快照 ─→ 原生／atlas／輔助證書
                   保留原比較          on_stage → 計算 → on_certificate → 最終完整覆蓋閘
```

這是本機計算／訊息流，不是分散式聯邦網路；沒有引入新的業務 package import 邊。root 的 `registry` component 加入 `check_pipeline.mbt`。所有數學構造仍只向下依賴。

## 2. 演算法重寫

### BDD：每個請求共享共因子工作區

`cubical/face_bdd/bdd_dag.mbt::bdd_dag_of_face_optimal_dp`：

- 舊路徑：同一 residual 分別求 `restrict(false)`／`restrict(true)`，每次配置按整個 manager 大小的 memo，再線性掃描去重。
- 新路徑：同一遍遞迴同時求兩個共因子；**每個變數、每個 interned node ID** 在這次請求內記憶化；generation marks 取代 residual 集合的線性 membership scan。
- 仍計算同一個 subset DP、同一個最小節點數；沒有把精確路徑換成 heuristic，也沒有減少 14 變數兩條入口的獨立語義檢核。
- cache 只對**同一 manager、固定變數序、不可變 interned nodes**有效，不是全域／跨請求 cache，更不是 `Bool` 證明結果快取。

新增可選 `max_cofactor_entries`：`0` 保持舊有 unlimited residual 儲存行為；正數限制已保存的 residual ID 數，超限明確回退 `exact=false`；負數也回退非精確。這個限制**不涵蓋 manager、restrict cache、暫存配對或其他配置**，不是整個請求的硬記憶體上限。`max_nodes` 與 n≤16 的既有邊界不變。正預算比較以減法避免 Int32 加總溢位。

獨立驗證：全 256 個三變數真值表對公開 restrict／階乘枚舉最佳序；14 變數七對乘積的精確及預算回退路徑各對全部 16,384 個賦值；原生正式 law 保留完整雙路 14 變數檢核並新增 budget 負控制。

### LLL：精確增量 Gram–Schmidt

`algebra/lll_van_hoeij_rouche.mbt::qmat_lll_reduce`：

- 一次 size reduction `b[k] -= q*b[j]` 只更新 `mu[k][0..j]`，正交基及 norm² 不變。
- 相鄰 swap 以精確有理式更新 mu／norm²；`β = norm²[k] + mu[k,k−1]²*norm²[k−1]`。退化 β=0 路徑保留完整重算。
- 所有數仍是 BigInt 有理數；`U*basis`、Lovász 條件、size-reduction 條件及 checker 的獨立 Gram–Schmidt 重算皆保留。沒有浮點近似，也沒有 kernel proof bypass。
- 原有輸入契約仍是 Qᵈ 中線性獨立、矩形的 row basis；沒有新增任意 ragged／病態輸入的總正確性承諾。

局部獨立 oracle 是改寫前的「每一步完整重算」實作：32 個有理 2..5 維 row bases、共 630 次 size reductions／434 次 swaps；basis、整數 U、操作數完全相同，並逐元素驗 `U*basis`。空／單 row／dependent 負例及原有 Van Hoeij law 亦核驗；臨時 oracle 與測試已刪。

## 3. 公開入口與訊息格式

`check_pipeline_manifest()` 回 `(id,name)`，不執行定理。`run_check_pipeline(selected?,max_checks?,on_start?,on_result?)` 先完整驗輸入，再依指定次序呼叫閉包。`run_all_checks()` 仍返回原來的 `Array[CheckResult]`，但若內部協定失敗會 abort 而非回傳可能被 `all([])` 誤判的空陣列；`print_report()` 改為完成一項即輸出。

JSONL 每個物件佔一行，所有名稱用 JSON encoder 跳脫：

```json
{"event":"started","id":1,"name":"…"}
{"event":"result","id":1,"name":"…","ok":true,"elapsed_ms":1.25}
{"event":"summary","total":139,"requested":1,"completed":1,"passed":1,"deferred_ids":[],"selected_all_passed":true,"full_verified":false}
```

`elapsed_ms` 來自 `@bench.monotonic_clock_end / 1000`（core 原單位是微秒）；它包含該檢核及 start callback 的少量觀測開銷，不是硬即時保證。例子中的 1.25 是格式示意，不是測量數字。

`bridge_certificates`／`grand_unification_certificates` 新增可選 `on_stage` 和 `on_certificate`，舊呼叫不用改。重型證書在 check thunk 前發 stage，計算後立即發 result；輕量 native/base 與 auxiliary 群組按群組計算後逐筆發送。回傳陣列及最終 50 個證書／18 atlas 的檢核不變。呼叫者的 callback 可有副作用，故這是可信行程內 observer API；例外不會被包成成功。

## 4. 平衡點與資源政策

```bash
moon build --target wasm-gc
# CI／日常全量：只執行已建好的 artifact，不含 build
python3 tools/run_pipeline.py --jobs=2 --require-full --jsonl
# 重現串行次序：不按成本重新排列
python3 tools/run_pipeline.py --jobs=1 --require-full --jsonl
# 查看兩個 batch 的預測負載，不跑定理
python3 tools/run_pipeline.py --jobs=2 --plan --jsonl
# 只要求兩項；明示不是全量驗收
python3 tools/run_pipeline.py --checks=84,114 --jobs=2 --jsonl
# 在目前主機重新取得純時間 hints；只有全量成功才寫入
python3 tools/run_pipeline.py --jobs=1 --costs=none --require-full \
  --save-costs=tools/check_costs.json --jsonl
```

- `check_costs.json` 只保存 elapsed_ms、manifest SHA-256 及觀測 metadata，**不讀取或重播任何 ok／proof 結果**。標籤／ID 改變時舊 hints 被拒絕；可以 `--costs=none` 等權分派，再校準。
- Longest-processing-time-first 是**貪心估計**，不是全域最優排程。單一慢檢核不可被拆成多 worker；成本會受 JIT、主機負載及同時執行影響。總 CPU 工作量不會因並行自動下降。
- 每個 worker 一個 Wasm 實例；並行會增加記憶體與啟動成本。預設最多 2 個、可指定 1..8；不是總 RAM 配額。CPU 少／記憶體少時用 `--jobs=1`。
- MoonBit `--max-checks` 只在檢核之間停止。host `--timeout-seconds` 是每 worker 硬超時，預設 900 秒；超時／崩潰／中斷／非零退出都令本次 pipeline 失敗，不會留下 full_verified=true。
- host 驗 `started→result` 次序、manifest 名稱、exact ID coverage、摘要整數／布林型別及退出碼；重複 JSON key、NaN／Infinity、空輸出、漏項與自相矛盾 summary 均拒絕。完整 domain check 的正確性仍由原有獨立數學路徑負責。
- 局部成功 exit 0 **不代表**全量通過；CI 必須使用 `--require-full`。它也拒絕 `--plan` 及任何不足全量的配額。

## 5. 驗證與量測政策

- 暫時單包測試遵從 `agent.md`：加在被改檔案底部，update→讀取並獨立核對→non-update→立即刪除；沒有常駐 tests／benchmark loop。
- `tools/run_pipeline.py` 是執行正式 `check_*` 的日常運算入口，不是一套另存期望答案的測試框架。`check_pipeline_laws` 是正式的 synthetic protocol laws，每次管線都執行，不能代替任何 domain check。
- 性能比較固定編譯器、輸入、wasm-gc debug，預先建置 artifact，使用 fresh moonrun 行程；交錯 before／after，記錄全部樣本與 median／range。編譯時間排除，但 Wasm 啟動／JIT／輸出計入。
- 早期單次 instrumented profile 只用來定位熱點（BDD 084、精確代數 114、homotopy 102/108/110/115），不是加速百分比依據。`check_costs.json` 同樣只是單次排程校準。
- 有意未改：kernel conversion、開放上下文 section／retraction 的獨立檢核、所有原生負控制與 139 條原始表達式。剩餘 homotopy 熱點及一般輸入的記憶體界限留待後續，不宣稱全倉所有演算法已最佳化。
- 實測只涵蓋這台 Linux x86_64、2 logical CPU 的沙盒；native／release／JS／實體 GPU／Lean kernel 未在本輪執行，不能由此外推。
