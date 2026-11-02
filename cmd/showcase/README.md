# `cmd/showcase/` — 七聯邦 × 雙 V 架構的敘事式驗證（136 行）

> **套件**：`vv0101v01/cubical-hermitian/cmd/showcase` · `pkgtype(kind: "executable")`
> **依賴**：`bridge`、`semiring-graph`（`@sgraph`）、`symlib`（`@sym`）、`root`（`@cub`）、`moonbitlang/core/debug`
> **1 檔 136 行** · 全 target 可編譯

---

## 1. 定位

`cmd/main` 回答「129 個定理對不對」；本套件回答**「這些定理為什麼應該放在一起看」**：

```text
  Seven Autonomous Mathematical Federations (7/7)
  Complete K₇ Cross-Federation Pairwise Bridges (21/21)
  X-Overlap Chiasmus, Double-V & Seven-Federation Star-Prism Discovery
  Unified Certificate Ledger
```

每個區塊都用 `[PASS]`／`[FAIL]` 加上**定量見證**（`quantitative_witness`），因此輸出本身就是一份可讀的摘要報告。

---

## 2. 輸出結構與對應 API

| 段落 | 呼叫 | 內容 |
|---|---|---|
| 七聯邦健康 | `@bridge.seven_federation_descriptors()` → `fed.live_health_ok`、`fed.slug`、`fed.summary` | 7 個聯邦各自的**現況**（不是規格，是「現在跑起來健不健康」） |
| `K₇` 橋 | `@bridge.verify_k7_federation_bridges()` → `edge.id`、`edge.bridge_theorem`、`edge.holds`、`edge.quantitative_witness` | 21 條兩兩橋接，每條附**定量見證**（例如兩側算出同一個整數） |
| X-Overlap | `@bridge.verify_x_overlap_chiasmus()` → `chiasm_commutes`、`diagonal_d1_syntax_nonarch_ok`、`diagonal_d2_analytic_homotopy_ok`、`shared_chiasm_invariants` | 「兩條對角線交換」的交錯圖；D1（語法／非阿基米德）、D2（解析／同倫） |
| 雙 V | `@bridge.verify_double_v_architecture()` → `upper_v_synthesis_apex_ok`、`lower_v_gcd_apex_ok`、`six_federations_verified`、`k6_bridges_verified`、`seven_boundaries_breakthrough_ok` | 上方 V（聯邦 → 合成 apex）、下方 V（聯邦 → `gcd` apex）；`K₆ = 15` |
| 星稜鏡 | `@bridge.verify_seven_federation_star_prism(k7_precomputed=Some(k7_edges))` → `star_prism_commutes`、`seven_federations_verified`、`k7_bridges_verified`、`conjectures_evaluated`、`evolution_families_verified`、`lakatos_refinements_verified` | 把 `K₇` 的 21 條邊當成稜鏡的稜；`conjectures = 12`、`evolve = 6` |
| 四元數凝聚中軸 | `@bridge.verify_rotation_axis_bridge()` → `families_passed`、`comparisons`、`coherence`、`axis` | 四族 `4/4`；相干角 `11040→552→0`（276 個規範類、總重數守恆），並逐項印出四族與中軸的消元前後數值及差值；不改 47 條歷史證書數 |
| 直覺猜想實驗 | `@bridge.verify_intuitive_conjecture_lab()` | 五條原猜想、直覺、搜索範圍、反例與修正版；1 條有界倖存、4 條反例後修正，納入總成功條件但不改既有 12 條猜想數 |
| 證書帳本 | `@bridge.bridge_certificates()` | 47 張證書的彙總（`ATLAS-01..18`、`pentagon` 等） |

`k7_precomputed=Some(k7_edges)` 是**避免重算**的設計：`K₇` 的 21 條邊在上面已算過，此處直接注入 ⇒ 整份報告只算一次。

---

## 3. 執行

```bash
moon run cmd/showcase                    # wasm
moon run cmd/showcase --target native --release
```

輸出樣本（節錄）：
```text
[PASS] federation gcd: ...
-- Complete K_7 Cross-Federation Pairwise Bridges (21/21) --
[PASS] K7-01: ...
        <quantitative_witness>
[PASS=True] Double-V: V1_gcd=True, federations=6/6, K6=15/15, boundaries_7=True
```

---

## 4. 為什麼它是 executable 而不是說明文件

三件事只有在**執行**時才知道：
1. 七聯邦的 `live_health_ok` 是**現況**，不是規格；
2. `quantitative_witness` 是本次算出來的數字（例如兩條獨立路徑算出同一個 `21`）；
3. `star_prism_commutes` 需要 21 條邊**同時**成立 —— 單獨看每條邊看不出這件事。

因此本套件是「架構文件」，只是它的語法是 MoonBit。
