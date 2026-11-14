# kt (`cubical-hermitian` v2) — 現行架構入口

> 2026-11-14：以可重建資料取代過期的手抄全景。早期雙 V／X／完全 K₁₀ 說法只保留在歷史紀錄，不作現行契約。

## 一、三個真實來源

| 來源 | 負責甚麼 | 不負責甚麼 |
|---|---|---|
| [`architecture.json`](architecture.json) | 10 聯邦、57 實體套件、66 邏輯元件、各層及 import 白名單 | 不能證明某數學橋成立 |
| [`bridge/catalog.json`](bridge/catalog.json) | 45 歷史配對的 lifecycle、39 active 的功能／範圍、6 retired 的理由 | Active 不是自動 holds=true |
| 各包 `pkg.generated.mbti` | 編譯器產生的公開 API | 不包含行為或定理可靠性保證 |

[`tools/federation_docs.py`](tools/federation_docs.py) 從前兩者產生 `bridge/registry.mbt`、[分層清單](docs/FEDERATION_ARCHITECTURE.md)、[功能枚舉](docs/BRIDGE_CATALOG.md)、[全局圖](docs/federation-graph.svg)及[離線總覽](docs/FEDERATION_OVERVIEW.html)。CI 用 `--check` 禁止生成物過期。

## 二、現在住在甚麼層

- **pkgL0 七個業務基礎**：gcd、accel/swar、symlib/core、cubical/face_bdd、meta/core、ualg/core、ualg/site。
- **pkgL1–3**：輕核、領域引擎、有限模型及 metatheory/ualg/symdemo 等原生入口。
- **pkgL4–7**：condensed、accel、semiring 整合、自主與高階立方結構、猜想引擎和根門面。
- **bridge = pkgL8 / compL13**：observer，使用上游公開 API；任何底層聯邦不得反向依賴它。
- **showcase = pkgL9 / compL14**：建一次 active 比較快照，列印功能／見證及執行總閘。

六組輕／重分離仍保留：`symlib/core→symlib`、`algebra/core→algebra`、`condensed/core→condensed`、`topos/site→topos`、`conjecture/kernel→conjecture`、`accel/swar→accel`。

全部 57 套件的**路徑、擁有聯邦、package/component 層、直接依賴及職責**請讀[自動產生表](docs/FEDERATION_ARCHITECTURE.md)，不再於本檔複製另一套易漂移數字。

## 三、橋的功能與停用

- **39 active / 45 歷史配對**，不是完全圖。
- **6 條已刪橋**：K6-11、K6-13、K7-18、K7-21、K9-35、K9-36。僅留不可執行的理由；不再先運算後 `holds=false`。
- X-Overlap 和 Malcev/Presheaf/Autonomy 的獨立健康合取包裝也已刪除。
- 原生／atlas／輔助證書 **50 個**；它們不增加配對橋數。
- 新的實際產物：P¹ Laurent Čech 維數、VR→Topos 3-skeleton adapter、圖閉包／Laplacian SNF 對帳。
- 保留橋的有限範圍、負控制及仍欠一般化的部分，在[功能枚舉](docs/BRIDGE_CATALOG.md)逐項明示。

API 破壞性變更與替代用法見[遷移說明](docs/BRIDGE_MIGRATION.md)。

## 四、訊息與運算管線

root `check_pipeline.mbt` 把 139 條原有表達式包成可規劃的閉包；CLI → 預驗 → started/result → coverage summary。`tools/run_pipeline.py` 以時間 hints 做 bounded multi-process 平衡，不 cache 証明結果；BDD／精確 LLL 的工作區與增量重寫仍在原有底層 package。`showcase` 加階段／證書 callback；不新增業務 import 邊，不刪 kernel 獨立核驗。

詳見 [PERFORMANCE_PIPELINE](docs/PERFORMANCE_PIPELINE.md)。CI 以 `--require-full` 拒絕任何部分成功冒充全量；測量結果及限制見 `agent.v2.md#2026-11-14-performance-pipeline`。

## 五、重建與驗收

工具鏈固定於 `.moonbit-version`：`0.10.20+65efd5b93`。官方 latest 通道、SHA-256 核對及新語法說明見[工具鏈文件](docs/MOONBIT_TOOLCHAIN.md)。

```bash
moon update
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py
python3 tools/federation_docs.py --check
python3 tools/gen_laws.py
# 驗證登記產物未漂移
# git diff --exit-code -- 'meta/*/laws.mbt'
moon run cmd/metatheory --target wasm-gc
moon run cmd/ualg --target wasm-gc
moon run cmd/main --target wasm-gc
moon run cmd/showcase --target wasm-gc
```

遵守 `check/build → 檔尾臨時 inspect → 重跑 → 即刪 → info/fmt`；不保留常駐測試或新增 benchmark runner。實際輸出、量度方法及限制統一記入 [`agent.v2.md`](agent.v2.md#2026-11-14-federation-audit)。

完整專案入口見 [README](README.md)。
