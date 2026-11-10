# `topos/site/` — 無線性代數輕量景、`Sieve64` SWAR 雙 Heyting 核與分類 Topos

> **架構位置**：`architecture.json` 中的 `topos-site`，**Package Layer 2 / Component Layer 3**，僅依賴 `gcd`、`symlib` 與 `accel-swar`（完全解除對有理線性代數 `algebra` 之耦合）。
> 聯邦歸屬：**F4 `topos`**（`L3 topos` 透過 `reexport_site.mbt` 之 `pub using @site` 100% 向後相容重導出全體 `27` 型別與 `125` 公開函式）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/topos/site`。

---

## 1. 一句話定位

將 Grothendieck 景、覆蓋篩、預層層化 `(−)⁺⁺`、笛卡兒閉指數 `G^F`、真值分類子 `Ω_J`、本徵幾何態射、Diaconescu `G`-主叢與一階幾何理論 Kripke–Joyal 力迫收斂為純組合與 64-bit 位元並行的獨立基礎套件。

---

## 2. 檔案清單（5 個 `.mbt`，共 5,046 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `sieve64_swar.mbt` | 356 | 單 `UInt64` 篩核心 `Sieve64` 與預計算景 `SitePrecomp64`（`\|Mor(C)\| ≤ 64`）：`O(1)` 交／聯／包含、`O(popcnt)` Heyting 蘊涵 `⇒_64`、餘 Heyting 差 `\_{co}`、Lawvere 邊界 `∂S`、雙重否定核 `¬¬_64`，以及 MAC 前向檢查相容族枚舉 `enumerate_matching_families_mac64` |
| `site_presheaf.mbt` | 1126 | Grothendieck 拓撲 `GrothTopology` 三公理驗證、預層限制、相容族黏合與 Grothendieck 兩趟加號構造層化 `sheafify` |
| `sheaf_ccc_omega.mbt` | 1168 | 預層／層範疇有限極限與餘極限、米田嵌入計算之指數對象 `G^F`、閉篩子物件分類子 `Ω_J` 與 Lawvere–Tierney 拓撲雙射 |
| `geometric_morphism_local_properties.mbt` | 1244 | 態射誘導本徵幾何態射 `Lan ⊣ u* ⊣ Ran`、局部連通／原子／布林／De Morgan 局部性質判定與點態 stalks 保正合性 |
| `logic_classifying_categorify.mbt` | 1152 | Kripke–Joyal 篩語義力迫、一階幾何理論模型檢驗 `model_satisfies_theory`、分類 Topos `Set[𝕋]` 泛性質與 Diaconescu `G`-torsor 定理 |

---

## 3. 核心定理與公開入口

| 標籤／定理 | 公開入口 |
|---|---|
| `[T-Sieve64-SIP]` `Sieve64` 暫存器雙 Heyting 核與陣列版 `Sieve` 全運算同構 | `verify_sieve64_swar_biheyting_bridge`、`sieve64_pullback` |
| `[T-MAC-Gluing]` 弧一致性前向檢查相容族枚舉與樸素回溯結果全等 | `enumerate_matching_families_mac64` |
| `[T-Sheafify-Exact]` 左伴隨層化 `a_J = (−)⁺⁺ ⊣ i` 保持有限極限 | `sheafify`、`verify_sheafification_universal` |
| `[T-Classifying-Diaconescu]` 幾何理論模型範疇等價 `Geom(E, Set[𝕋]) ≃ Mod_𝕋(E)` 與 `G`-主叢分類 | `model_satisfies_theory`、`verify_classifying_topos_universal` |

---

## 4. 依賴關係圖與驗證

* 上游依賴：`gcd` (`L0`)、`accel/swar` (`L0`)、`symlib` (`L1`)。
* 下游消費者：`topos` (`L3`)、`condensed` (`L4`)、`conjecture` (`L5`)、`bridge` (`L8`)。
* 驗證方式：`moon check --deny-warn --target wasm-gc` 零警告；由 `verify.mbt`、`bridge/meta_k9_unification.mbt` 與 `cmd/showcase` 常駐驗證。
