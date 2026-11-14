# `cmd/showcase/` — 單次快照的聯邦功能與驗收

位置：**pkgL9 / compL14**。直接 import `bridge`、`semiring/graph`、`symlib`、root；沒有底層 package 依賴本入口。

```bash
moon run cmd/showcase --target wasm-gc
```

不加 `--release`；本輪只聲稱已驗 wasm-gc，沒有把其他後端或實體 GPU 實跑列作完成。

## 輸出與真正做的事

1. 十聯邦原生健康描述子。
2. **39 條 active 配對**：一次組裝配對快照，列出實際核驗的 ID、功能與量化見證。
3. 嚴格 inventory report：39/39、ID／端點／覆蓋完整；15/15 checker laws 含負控制。
4. 歷史 active 子圖：K6=13、K7=17、K9=30；這些不是完整 K6/K7/K9。
5. 旋轉關係對齊及 4 個反例後修正的直覺猜想。
6. **50 個原生／atlas／輔助證書**，其中 atlas=18；它們不增加配對橋數。
7. ualg 9 條與第一／二波 6+7 替換，都從同一配對快照選取。
8. F2×F3×F6 真正共享圖構造；F8×F5×F1 及前沿有限案例整合。
9. **6 個 `[RETIRED]` 理由**，僅列 metadata，沒有失敗占位橋或退役計算。

X-Overlap、沒有可靠性傳輸的 promotion、Malcev/Presheaf/Autonomy 獨立旗標包裝已刪。不要再把舊的 `45/45` 或 `chiasm_commutes` 當成現行輸出。

## 重型證書的即時出口

`bridge_certificates` 的 `on_stage` 在重型運算前發出 `[START]`，`on_certificate` 在結果可用時即列印 PASS/FAIL 與見證；不必再等 50 個證書全部完成。grand 部分逐項包裝 check thunk，輕量 base／auxiliary 仍按群組計算。回傳的完整陣列仍供原來總閘核對 50 個證書及 18 atlas；callback 不會代替計算，也不 cache proof 結果。

參數皆可省略，其他 API 呼叫者維持原有收集行為。[設計及測量限制](../../docs/PERFORMANCE_PIPELINE.md)明列尚未拆分的 homotopy 慢檢核。

## 快照與總閘

```text
verify_k10_ten_federation_bridges()    一次
    ↓
validate_bridge_registry(edges)
    ├─ 全量列印
    ├─ K6/K7/K9/K10 各自再次驗 coverage
    ├─ wave1 / wave2 選取
    └─ final guard
```

描述子、硬體 report、三元 report、前沿 report 同樣供列印／總閘重用。原生／atlas 套件仍可能各自重做部分底層核驗；例如 atlas-12/13 及六柱入口會再次核對 Zariski／Kapranov，因此不宣稱全程每個驗證函式只執行一次。預算資料只供可信的同一行程呼叫者；公開 `Bool` 不是不可偽造的形式證明。

任何 active 構造、registry、負控制或保留的原生檢核失敗，入口會 `abort`，而不靠硬編通過數字掩蓋。

完整層表及所有功能見 [`docs/`](../../docs/FEDERATION_ARCHITECTURE.md)；刪除／遷移見 [BRIDGE_MIGRATION](../../docs/BRIDGE_MIGRATION.md)。實跑記錄由 `agent.v2.md` 統一保存。
