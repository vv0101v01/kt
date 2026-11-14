# `tools/` — 架構、功能清單與介面治理

這些是 Python 基礎設施腳本，不是 MoonBit package。現行全倉為 10 聯邦＋observer、57 packages、66 components；精確統計以生成架構清單及 `arch_check.py` 實跑為準。

## 工具分工

| 工具 | 用途 | 是否是閘門 |
|---|---|---|
| `run_pipeline.py` | 正式定理閉包的多行程平衡執行、串流事件及嚴格 coverage reducer；只讀時間 hints，不 cache proof | `--require-full` 為 CI 全量閘 |
| `check_costs.json` | manifest hash 綁定的單次計時校準；不是驗證結果 | 否，只影響排程 |
| `arch_check.py` | 檔案恰歸一個 component、package import exact-match、聯邦白名單、兩套分層、禁止常駐測試；附規模統計 | 是 |
| `federation_docs.py` | 驗 45 歷史配對唯一性、active 生產入口存在、retired 實作已移除；生成 registry、SVG、完整層表、功能清單及離線 HTML | `--check` 是只讀漂移閘 |
| `health_scan.py` | 靜態近似的遞移死碼／重複／空殼候選 | 否；不可僅憑 pub API 在倉內零引用就刪除 |
| `gen_laws.py` | 從公開 `law_*` 重生 metatheory laws 登記 | CI 生成後要求無差異 |
| `gen_labels.py` | 從 metatheory 實際輸出重生 Lean 對帳標籤 | 不能代替執行 Lean kernel |

## 日常命令

```bash
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py

# 修改來源、catalog 或 architecture 後
moon info --target wasm-gc
moon fmt
python3 tools/gen_laws.py
python3 tools/federation_docs.py
python3 tools/federation_docs.py --check

# 健檢報告，不是自動刪除器
python3 tools/health_scan.py > tools/health_report.md
```

## 正式運算管線

```bash
moon build --target wasm-gc
python3 tools/run_pipeline.py --jobs=2 --plan --jsonl
python3 tools/run_pipeline.py --jobs=2 --require-full --jsonl
```

這是 **139 個已出貨 `check_*` 的運算入口**，不新增測試答案或 benchmark loop。1..8 個獨立 `moonrun`、預設 ≤2；預算及局部執行不能冒充全量成功。只保存成本 hints，不保存可重用的 true。所有選項、訊息契約、時間校準及記憶體限制見 [管線設計](../docs/PERFORMANCE_PIPELINE.md)。

## `arch_check.py`

```bash
python3 tools/arch_check.py --check
python3 tools/arch_check.py --json
python3 tools/arch_check.py --list-edges
```

- 生產 imports 與 `architecture.json` 的 `packages[].depends_on` 完全一致。
- 同一 `.mbt` 恰好歸一 component；component 層與 package 層分別檢查。
- 頂點 observer 可以匯入上游，但任何底層都不能反向匯入 bridge。
- `*_test.mbt`、`*_wbtest.mbt` 和殘留頂層 `test` 均不容許；臨時局部測試核驗後即刪。
- 原始碼引用圖是近似守門，不是完整語義分析；編譯器仍是語法／型別真實來源。
- `--json` 目前先印 JSON 再印文字摘要；消費者不可把整段 stdout 直接當純 JSON。

## `federation_docs.py`

無第三方依賴。來源：

1. `architecture.json`：實體套件／元件分層和依賴；
2. `bridge/catalog.json`：每一歷史配對的狀態、入口、產物、範圍及刪除理由；
3. `.moonbit-version`：離線總覽顯示的工具鏈 pin；
4. 目前來源：行數及 active／retired 定義存在性。

生成物：

- `bridge/registry.mbt`：metadata，**不自動把 active 標為 true**；
- `docs/FEDERATION_ARCHITECTURE.md`：所有 package 的位置、擁有者、層與直接 import；
- `docs/package-dependencies.mmd`：provider→consumer 的實體 DAG；
- `docs/BRIDGE_CATALOG.md`：39 active 的功能與限制、6 retired 的理由；
- `docs/federation-graph.svg`：語義橋圖，不是 import 或網路圖；
- `docs/FEDERATION_OVERVIEW.html`：嵌入 SVG/CSS/JS，離線可搜尋的文檔。

先完成 `moon fmt` 及 `gen_laws.py` 再生成層表，避免格式化／定律生成器的行數差異令統計漂移。

`--check` **不寫任何檔案**；漏生成、內容漂移、重複配對、缺欄位、缺 active producer 或退役 producer 再出現均退出非零。它不能證明數學構造；`showcase` 的 runtime validator 和原生定律才負責實際執行。

## 變更紀錄

所有工作的變更／理由／實測／剩餘限制統一記錄到 `agent.v2.md`，不是另外堆積測試 runner 或沒有驗證的「全綠」宣告。
