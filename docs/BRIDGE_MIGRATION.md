# 2026-11-14 聯邦橋 API 遷移

基線 commit：`2d8f6866b44d01f291ab5ea07bfcc3732afdf652`。這是有意義的行為／公開 API 變更，**不是聲稱完全相容的內部重構**。

## 1. 真正刪除，不保留假成功相容層

| 移除的入口／資料 | 理由及處置 |
|---|---|
| `verify_k6_11_condensed_cubical_bridge` | 沒有 Adams→Brunerie 比較映射；各原生核驗保留 |
| `verify_k6_13_condensed_semiring_bridge` | 熱帶與 liquid 檢查互相獨立 |
| `verify_k7_18_discovery_semiring_bridge` | Viro tie 與張量蘊涵格無 transport |
| `verify_k7_21_discovery_condensed_bridge` | 雜湊封裝不是數學橋 |
| `promote_discovered_implication_to_focused_theorem` / `FourFederationPromotionReport` | K9-35 沒有語義可靠性傳輸；`promotion_pipeline` 欄位從九／十聯邦 report 移除 |
| K9-36 assembler 分支 | 原分支只呼叫 meta/reflect，沒有 Accel 物件／獨立硬體對照；Meta 原生 V5 檢核保留 |
| `verify_x_overlap_chiasmus` / `XOverlapChiasmReport` | 獨立旗標加巧合數組 `(1,2,1)`，不能推出交換圖；對應證書從 ledger 刪除 |
| `verify_malcev_presheaf_autonomy_bridge` / `MalcevPresheafAutonomyBridgeReport` 及來源檔 | 獨立健康檢查包裝，沒有共享構造；底層 autonomy/structures/topos/accel API 保留 |
| `apply_bridge_audit` / `bridge_suspension_reason` / `suspended_bridge_ids` / `bridge_audit_counts` / `bridge_audit_all_active_hold` | 不再需要「執行後標成 suspended」overlay；改用 retired metadata 與精確 validator |

舊 ID 不重編號。`retired_bridge_ids()` / `bridge_retirement_reason(id)` 只供追溯，沒有可執行占位橋。

## 2. Active 集合的契約

| 聯邦 scope | active 數 | 歷史配對槽位 |
|---|---:|---:|
| 5 | 10 | 10 |
| 6 | 13 | 15 |
| 7 | 17 | 21 |
| 8 | 24 | 28 |
| 9 | 30 | 36 |
| 10 | 39 | 45 |

不要再檢查 `edges.length()==45` 或只數 `holds=true`。

```moonbit
let edges = @bridge.verify_k10_ten_federation_bridges()
let audit = @bridge.validate_bridge_registry(edges, federation_count=10)
// 需要 audit.all_holds，而不是「true 的個數剛好是 39」
```

空表、漏項、同長度重複替換、超出 scope、退役 ID、錯端點及空白見證均失敗。允許無向邊端點反轉。

## 3. 報告欄位及相容的增量參數

- `DoubleVArchitectureReport` 不再有 `x_overlap_ok` / `seven_boundaries_breakthrough_ok`，改報 `registry_ok`。舊函式名為避免無謂改名仍保留，但只描述整合健康，不是 X 定理。
- `SevenFederationStarPrismReport.star_prism_commutes` 是保留的舊欄位名，現在只表示 registry／原生健康／已解決猜想檢核通過，**不是交換圖定理**。
- `NineFederationUnificationReport` / `TenFederationUnificationReport` 刪除 `promotion_pipeline`。
- `F2F3F6TriadBridgeReport` 改為 `cases`、`negative_control_detected`、`all_holds`；不再攜帶與共同圖物件無關的健康旗標。
- 新增 `GraphClosureSnfReport` 及三個參數化產物（詳見功能清單）。
- K7-17／K8-26／K8-28 增加可選 atlas 重用參數；預設仍自行構造，數學核驗不被跳過。
- 九／十聯邦整合 report 可接收已計算的邊與描述子；**每次仍驗精確 coverage**。
- 證書函式增加可選預算結果，讓列印與 guard 重用同一份硬體／三元／前沿 report；不是可信外部證書接口。
- `certificates_all_ok([])` 現在回傳 false，避免空 ledger 的 vacuous success。
- `CondAnalyticStack.ring_name` 的舊 Spa 標籤改為實際的有限 P¹ Laurent Čech 模型；欄位結構未改。`topos_laurent_site_valid` 名稱為舊相容欄位，實際只檢查 atomic BS2，文件已明示；`solid_completion_gap=0` 仍是相容常數，不能當成完成 p-adic completion 的證據。

## 4. 引用與驗證成本

`bridge` 不再直接 import `cubical/autonomy` 和 `semiring/app`；`moon.pkg` 與 `architecture.json` 同步。它們仍可能由其他原生路徑傳遞使用，**不宣稱刪除了整個聯邦或完全消除了傳遞依賴**。

CLI 只組裝一次 active snapshot，所有子圖與兩波替換讀同一批結果；三個 atlas 消費者讀同一 atlas。獨立參考演算法本身仍各自執行，沒有用共用答案假扮獨立對照。原生／atlas 套件仍可能重做底層核驗，例如 atlas-12/13 及六柱入口的 Zariski／Kapranov；不宣稱全程零重複。

## 5. 本次沒有做的事

- 沒有把每一條 bounded comparison 一律提升為一般形式證明。
- 沒有刪除所有「未被 repo 內呼叫」的公開 API；單靠靜態引用數不足以判斷外部用戶。
- 沒有全倉刪除既有數學健康檢核；本輪刪的是已確認無構造／重複的橋包裝。
- 沒有執行 Lean、實體 GPU 或遠端 GitHub Actions；本地驗收與遠端狀態分開報告。

實跑輸出、效能量度方法及已知邊界見 `agent.v2.md` 最新工作報告。
