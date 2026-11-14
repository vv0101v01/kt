# kt — MoonBit 數學聯邦與可核驗的結構轉換

本專案把立方型別論、精確代數、對稱群、半環、Topos、概形、凝聚有限模型、發現引擎、硬體原語、元理論及泛代數分層組合。

**這裡的「聯邦」是程式／數學領域的責任邊界，不是分散式網路節點。** 橋的 `holds` 是實作所列範圍內的核驗結果，不能一律解讀為普世定理或任意輸入的形式證明。

## 當前狀態（2026-11-14 審計）

- **10 聯邦 + observer 頂點；57 packages、66 components。** 檔數、行數及每層完整配置由[架構清單](docs/FEDERATION_ARCHITECTURE.md)自動產生。
- **39 條 active 配對橋，6 條已刪除。** 歷史 45 個配對槽位仍可追溯，但執行圖是 **K₁₀ 的子圖**，不是 45/45 完全圖。
- `cmd/showcase` 產生 **50 個原生／圖譜／輔助證書**（含 18 個 atlas），與配對橋數分開。原來的 X 交換性「證書」已移除，沒有用其他旗標填回數目。
- 最新非 nightly 官方通道在本次核對為 **`moonc v0.10.20+65efd5b93`**；CI 以同一版本固定重建。
- 歷史工作紀錄留在 [`agent.v2.md`](agent.v2.md) 與 [`Dev.txt`](Dev.txt)。舊日期的 45/45、40 active、51/51 等數字是歷史截面，不是當前承諾。

## 全局圖與閱讀入口

| 需要查甚麼 | 文件 |
|---|---|
| 全局圖、分層與可篩選功能清單 | [離線總覽](docs/FEDERATION_OVERVIEW.html) |
| 十聯邦語義橋圖 | [SVG 全局圖](docs/federation-graph.svg) |
| 每一層住甚麼、57 包／66 元件、所有直接 import | [完整架構清單](docs/FEDERATION_ARCHITECTURE.md)／[實體 DAG](docs/package-dependencies.mmd) |
| 每條橋產出甚麼、真正收益、輸入範圍及限制 | [39 active + 6 retired 功能枚舉](docs/BRIDGE_CATALOG.md) |
| 刪除原因與破壞性 API 遷移 | [遷移說明](docs/BRIDGE_MIGRATION.md) |
| 最新工具鏈、語法與重建 | [MoonBit 工具鏈](docs/MOONBIT_TOOLCHAIN.md) |
| 模組入口及重用方式 | [`bridge/README.md`](bridge/README.md) |
| 工程規則及本次實跑結果 | [`agent.md`](agent.md)／[`agent.v2.md`](agent.v2.md#2026-11-14-federation-audit) |

## 分層摘要

| 實體層 | 職責 | 代表套件 |
|---|---|---|
| pkgL0 | 七個獨立業務基礎 | `gcd`、`accel/swar`、`symlib/core`、`cubical/face_bdd`、`meta/core`、`ualg/core`、`ualg/site` |
| pkgL1–3 | 輕核、領域演算法與原生驗證入口 | `algebra/core`、`condensed/core`、`cubical/kernel`、`topos/site`、`scheme`、`semiring/*`、`meta/*`、`ualg/*` |
| pkgL4–7 | 領域整合、高階結構及根門面 | `condensed`、`accel`、`conjecture`、`cubical/autonomy`、`cubical/structures`、root |
| pkgL8 / compL13 | 跨表示轉換與核驗 observer | `bridge` |
| pkgL9 / compL14 | 功能枚舉與驗收輸出 | `cmd/showcase` |

Package layer 和 component layer **是兩套座標**。實體 import 圖無環；把它按聯邦收縮後可能出現雙向依賴。語義橋圖則是另一張無向比較圖，不能拿來推導 import 方向。

## 本輪改進

1. **真的刪橋，而非計算後標為失敗。** 移除 `K6-11/13`、`K7-18/21`、`K9-35/36` 的執行路徑。再移除沒有共享構造的 X-Overlap 與 Malcev/Presheaf/Autonomy 健康合取包裝；底層原生 API 保留。
2. **驗收不再只數 true。** `validate_bridge_registry` 要求精確 ID 集合、唯一配對、正確端點、完整覆蓋、非空見證及成功結果；15 條 checker 定律包括空表、重複、漏項、退役 ID、錯配及空白見證等負控制。
3. **三項可重用產物。** Laurent Čech 矩陣維數、metric VR→Topos 神經轉換、圖 components→Boolean closure→整數 Laplacian SNF 對帳。對應橋核驗同一物件，不只比較無關旗標。
4. **一份快照，多處使用。** `showcase` 只組裝一次 39 條配對快照；K6/K7/K9/K10 報告、列印及兩波替換清單重用該快照。張量 atlas 在三個 active 消費點共享，列印／總閘重用硬體與前沿報告。原生／圖譜套件仍可能各自重做部分底層核驗，並非全程零重複計算。
5. **防止文檔再漂移。** `architecture.json` + `bridge/catalog.json` 生成執行註冊表、全局圖及文檔；`tools/federation_docs.py --check` 納入 CI。

## 安裝及驗證

```bash
# 與本次審計相同的官方正式發佈版本；不使用 nightly
curl -fsSL https://cli.moonbitlang.com/install/unix.sh -o /tmp/install-moonbit.sh
bash /tmp/install-moonbit.sh "$(cat .moonbit-version)"
export PATH="$HOME/.moon/bin:$PATH"
moon version --all
moon update

# 靜態／架構／生成物閘
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py
python3 tools/federation_docs.py --check

# 原生與跨聯邦驗收；順序執行，不加 --release
moon run cmd/metatheory --target wasm-gc    # 631 / 631
moon run cmd/ualg --target wasm-gc          # 167 / 167
moon run cmd/main --target wasm-gc          # 139 / 139
moon run cmd/showcase --target wasm-gc      # 39 active、6 retired、50 certificates
```

修改來源後的生成順序：

```bash
moon info --target wasm-gc
moon fmt
python3 tools/gen_laws.py
python3 tools/federation_docs.py
python3 tools/federation_docs.py --check
```

`moon test` 只用作單包檔尾臨時微測試，核驗後即刪；耐久負控制寫成正式純函式，見工程規則。

## 邊界

- 保留的橋有些是有限模型、指定域或指定階數的交叉核驗；個別橋仍沒有一般化 transport。逐項範圍見功能清單，**不宣稱全部技術債已清零**。
- 公開 report 的 `Bool` 不等於不可偽造的證明。`*_precomputed` 供可信呼叫者在同一行程重用，不是外部證書驗證協定。
- 這次驗收涵蓋 MoonBit wasm-gc。沒有把 Lean、其他後端或實體 GPU 執行說成已通過；WGSL 本次只核對靜態可移植性。
- 本次修改與證據在本地工作區；GitHub 遠端提交／PR／Actions 狀態另行處理，不把本地成功當成遠端 CI 成功。

## 授權

Apache-2.0，見 [LICENSE](LICENSE)。
