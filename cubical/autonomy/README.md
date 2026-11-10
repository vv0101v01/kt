# `cubical/autonomy/` — 構造性泛代數自主類型論、雙重否定預層模板與全譜立方結構（Layer 5）

> **套件**：`vv0101v01/cubical-hermitian/cubical/autonomy` · **Package Layer 5 / Component Layer 9**
> **依賴**：`gcd`、`cubical-face-bdd`、`cubical-kernel`、`cubical-elaborator`、`cubical-homotopy`、`symlib`、`topos`、`accel`
> **被依賴**：`root`、`bridge`、`cmd-showcase`
> 單包微測試實測 **0.68s**（14 項核心定理證書全數通過）

---

## 1. 定位

本套件將**構造性泛代數自主類型論**（同餘關係、商代數、吸收元／中性零元與瑪爾切夫算子）、**雙重否定核 `j(x) = ¬¬x` 預層／層化模板**，以及傳統立方核心外圍的高階幾何與邏輯結構（**仿射立方體制分類、雙德摩根立方集、Kripke–亞歷山德羅夫類型有效性結構、立方退化樹、變長 Moore 自由路徑空間、高維交錯面微分與 Hodge 譜、立方範式雙向修剪、∞-群胚內部刻畫**）與既有受信任核心 `cubical/kernel`、同倫層 `cubical/homotopy`、層論層 `topos` 及 64-bit SWAR 硬體加速層 `accel` 無縫整合。

| 證據等級 | 意思 | 本套件代表實例 |
|---|---|---|
| **核心計算** | 經 `cubical/kernel` NbE、`circle_encode_value` 或精確整數行化簡實際算出 | `univalent_circle_winding`、`verify_bidirectional_cubical_nf_pruning`、`verify_high_dim_alternating_cube_and_dtree` |
| **顯式構造與窮舉定理** | 有限載體／篩格／立方體字組上無遺漏構造與雙路徑互驗 | `verify_absorbing_pointed_malcev_dichotomy`、`verify_bide_morgan_cubical_duality` |
| **負對照反駁** | 明確構造違反公理之反例並檢驗判別器拒絕 | 有向區間無相容瑪爾切夫算子、非單調截面遭有效性結構拒絕、矛盾管枝與偽基底遭 `conv_at_under_face` 拒絕 |

---

## 2. 檔案清單

| 檔案 | 主題 |
|---|---|
| `malcev_universal_algebra.mbt` | 泛代數平坦查表、並查集同餘閉包、瑪爾切夫一步可換、商代數第一同構、吸收零塌縮 vs 點化零 Eckmann–Hilton 可換群、Zappa–Szép 中國剩餘分解、Chu 同餘對偶 |
| `affine_bide_morgan_cubical.mbt` | 區間重數次結構分類（純 BCH 仿射／對合仿射／德摩根笛卡兒）、雙德摩根雙 Heyting 立方集、變長 Moore 自由路徑嚴格結合律與 Kan 結合子／五邊形橋接、∞-群胚四重內部刻畫 |
| `degeneracy_tree_pruning.mbt` | 規範退化因子化決策樹 `CubicalDegeneracyTree`、5 維交錯面微分 `∂² = 0`、Moore 退化子複形閉包、`I³` 胞腔 Hodge Betti 譜 `[1,0,0,0]`、立方語法範式雙向修剪 |
| `validity_presheaf_gluing.mbt` | Kripke–Joyal 遺傳類型有效性結構（`Bool`/`Π`/`Σ`/`Path`/`ua` 封閉）、正方形面偏序集 `F(I²)` 亞歷山德羅夫拓撲与頂點篩 `¬¬`-稠密性、HOU 高階合一截面合成 |
| `autonomy_audit.mbt` | 14 種範疇與代數組合管線總檢核及 `CubicalAutonomyMasterReport` 匯總入口 |

---

## 3. 構造性泛代數與瑪爾切夫二分定理（`malcev_universal_algebra.mbt`）

* **同餘與商代數**：`generate_congruence` 以路徑壓縮並查集與迭代工作列構造主同餘閉包 `Cg_A(S)`；`quotient_universal_algebra` 構造商代數 `A/θ` 並驗證第一同構雙射與瑪爾切夫繼承性。
* **一步同餘可換**：`malcev_relational_compose_one_step` 在不執行傳遞閉包的前提下計算關係積 `θ ∘ ψ`，驗證瑪爾切夫代數上 `θ ∘ ψ == ψ ∘ θ == θ ∨ ψ`。
* **吸收零 vs 點化零二分**：
  * 德摩根區間 `({0,1}, ∧, ∨, ¬)` 具吸收元 `0`，窮舉全體 `256` 個三元運算證明相容瑪爾切夫多態數目為 **`0`**（解釋原始區間 `I` 為何非 Kan 纖維化對象，唯有退化終端 `|A|=1` 同時容許吸收元與相容瑪爾切夫算子）；
  * 點化瑪爾切夫代數 `(ℤ/6ℤ, +, 0, x - y + z)` 以中性零元 `0` 唯一誘導 Eckmann–Hilton 阿貝爾群運算 `x +_EH y := p(x, 0, y)`，並實現互素同餘之 Zappa–Szép／中國剩餘分解 `ℤ/6ℤ ≅ ℤ/2ℤ × ℤ/3ℤ` 與 Chu 空間對偶對合。

---

## 4. 仿射立方、雙德摩根、自由路徑與 ∞-群胚（`affine_bide_morgan_cubical.mbt`）

* **次結構維度分類**：`classify_dim_substitution` 與 `classify_dterm_dim_regime` 精確區分 `PureBchAffine`（`μ(i) ≤ 1` 且無對合／連接）、`InvolutiveAffine` 與 `DeMorganCartesian`，並驗證無連接 `2D` 開盒 Kan 填充在 `S¹` 上合成 `loop ⬝ loop`（經單值覆蓋 `circle_encode_value` 算出繞數 `+2`）。
* **雙德摩根立方集**：`verify_bide_morgan_cubical_duality` 在區間篩格與 ROBDD 面格上驗證雙 Heyting 鏈 `~~A ⊆ A ⊆ ¬¬A`、co-Heyting 伴隨 `(A ⇐ B) ⊆ R ⇔ A ⊆ B ∨ R` 及邊界算子 Leibniz 律 `∂(A ∧ B) = (∂A ∧ B) ∨ (A ∧ ∂B)`。
* **變長 Moore 自由路徑與 ∞-群胚內部刻畫**：`FreeMoorePath` 具嚴格結合串接與嚴格零長單位元；重參數化商映射對接 `@homotopy.dpath_assoc_path3_value` 與五邊形端點；內部路徑瑪爾切夫算子 `kan_path_malcev_op(s1, loop², loop¹, loop³)` 經單值覆蓋精確算出繞數 `2 - 1 + 3 = 4`。

---

## 5. 立方退化樹、高維交錯面微分與雙向範式修剪（`degeneracy_tree_pruning.mbt`）

* **退化樹壓縮**：`CubicalDegeneracyTree` 將相同子樹即時折疊為 `DTDegenerate(axis, child)`（常數 `5`-立方體僅需 `6` 節點而非 `63` 節點），其退化軸遮罩與 `@accel.cube64_degeneracy_mask` 在全體 `256` 個 `3`-立方體上逐位全等。
* **高維交錯邊界與譜特徵**：驗證 `5` 維超立方體 `∂₄ ∘ ∂₅ = 0`、Moore 退化子複形閉包 `∂(D₅) ⊆ D₄`，並建構 `I³` 胞腔邊界矩陣 `(B₁, B₂, B₃)` 算出 Betti 數 `[1, 0, 0, 0]`（高階拉普拉斯無零特徵值共振等價於立方體可縮）。
* **雙向範式修剪**：`bidirectional_prune_cubical_dterm` 自頂向下傳播活躍面約束剔除矛盾管枝、自底向上折疊冗餘 `DBoolElim` 與退化維度應用並駐留至 `DTermInternTable`（節點由 `25` 降至 `5`，DAG 唯一節點 `4`），經 `@kernel.conv_at_under_face` 認證面下定義等價。

---

## 6. 類型的有效性結構與雙重否定預層模板（`validity_presheaf_gluing.mbt`）

* **遺傳有效性結構**：`TypeValidityStructure` 驗證階段單調性與 `Bool`、`Π`、`Σ`、`Path`、單值 `ua(not)` 線之封閉性，並拒絕非單調偽截面。
* **正方形面偏序集 `F(I²)` 與 `¬¬`-層化**：在 `9` 對象正方形面偏序集上驗證 `4` 個頂點生成之邊界篩滿足 `¬S_verts = ∅` 與 `¬¬S_verts = ⊤`，對接 `@topos.verify_double_negation_presheaf_template` 與 `@elaborator.hou_unify`。

---

## 7. 14 類範疇與代數組合管線（`autonomy_audit.mbt`）

`verify_categorical_14_composition_patterns()` 將 Kan 稠密延拓、`¬¬`-層黏合、同倫推出繞數、Moore 單子分配律、`ua(not)` Grothendieck 笛卡兒提升、Chu 對偶、Morita／商同餘不變性、Moore 局部化商、短正合中國剩餘分裂、Operad 退化槽複合、Zappa–Szép 分解與博弈雙向修剪串聯為單一可執行管線。

---

## 8. 公開入口範例

```moonbit
let rep = @autonomy.verify_cubical_autonomy_master_suite()
// rep.all_theorems_verified == true
let ok = @autonomy.check_cubical_autonomy_all()
```

---

## 9. 驗證方式

開發期間使用單包微測試 `moon test cubical/autonomy --target wasm-gc` 執行 `debug_inspect` 驗證後移除臨時 `test` 塊；常駐全倉閘門由 `cmd/main`、`cmd/showcase`、`verify.mbt` 與 `bridge/malcev_presheaf_autonomy_bridge.mbt` 持續執行。
