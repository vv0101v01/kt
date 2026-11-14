# `cmd/` — 七個生產執行入口

這些套件只消費下層 API，不供底層反向匯入。以下是 **2026-11-14 審計後**的入口及實體 package layer；不要把它與 component layer 混用。

## 入口與驗證範圍

| 子套件 | pkgL | 職責 | 本次實跑 |
|---|---:|---|---|
| [`main`](main/README.md) | 8 | root 定理／定律總表；失敗即 abort | wasm-gc：139/139 |
| [`metatheory`](metatheory/README.md) | 3 | meta 四個原生模組的定律總表，104 個 `law_*` 函式 | wasm-gc：631/631 |
| [`ualg`](ualg/README.md) | 3 | 泛代數、預層模板、De Morgan、cubical 定律總表 | wasm-gc：167/167 |
| [`showcase`](showcase/README.md) | 9 | 39 active 配對快照、50 證書、15 checker laws、6 retired 理由 | wasm-gc：exit 0；無 `[FAIL]` |
| [`symdemo`](symdemo/README.md) | 2 | symlib 群作用、軌道折疊、單子／範疇等演示 | 本輪未執行 |
| [`symbench`](symbench/README.md) | 2 | 同一問題的衍生演算法與直接演算法基準 | 本輪未執行 |
| [`semiringreport`](semiringreport/README.md) | 5 | 19 節演算法／成本／限制量測；需主機時鐘及 async | native-only，本輪未執行 |

「原生模組定律」指各學科自己的入口，不表示本次使用 MoonBit native 後端。四個驗收入口皆明確指定 `--target wasm-gc`；不把未跑後端列為通過。

## 驗收指令

```bash
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py
python3 tools/federation_docs.py --check

moon run cmd/metatheory --target wasm-gc
moon run cmd/ualg --target wasm-gc
moon run cmd/main --target wasm-gc
moon run cmd/showcase --target wasm-gc
```

本輪不加 `--release`，沒有使用全倉 `moon test`。入口內的正式純函式負責定律與正反對照；臨時單包微測試遵從 `agent.md` 的「寫→跑→核對→刪」程序。

## Showcase 的資料流

`verify_k10_ten_federation_bridges()` 建一份 active 配對結果，精確 registry validator 驗 ID／端點／覆蓋／見證，然後子圖摘要、列印、ualg 邊及 6+7 替換均重用這份快照。原生／atlas 套件仍可能各自重做部分底層核驗，並非整個行程每個函式都只跑一次。

- 39/45 是 **active / 歷史槽位**，不是失敗項從輸出隱藏。
- 6 條退役橋及 X／promotion／Malcev 健康包裝已實際刪除；只保留理由 metadata。
- 50 個原生／atlas／輔助證書與配對橋是不同集合，不混加。
- 3 個新增／強化的產物：P¹ Laurent Čech 維數、metric VR→Topos nerve、圖 components→Boolean closure→整數 Laplacian SNF。
- `Bool` report 及 `*_precomputed` 供可信同一行程使用，不是外部形式證書驗證器。

詳見 [showcase 入口文檔](showcase/README.md)、[全局分層](../docs/FEDERATION_ARCHITECTURE.md)、[逐橋功能](../docs/BRIDGE_CATALOG.md) 及 [API 遷移](../docs/BRIDGE_MIGRATION.md)。完整執行紀錄在 `agent.v2.md` 最新報告。

## 其他演示／基準

```bash
# 額外手動工作；以上驗收結果不涵蓋這三條
moon run cmd/symdemo --target native
moon run cmd/symbench --target native
moon run cmd/semiringreport --target native
```

量測結論應附版本、輸入、重複次數及機器環境；單次 `moon run` 的端到端時間包含可能的編譯與啟動成本，不足以宣稱某一橋演算法的加速比。
