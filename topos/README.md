# `topos/` — Grothendieck 與初等 Topos：景、層、子物件分類子、幾何態射、上同調與神經同倫

> **架構位置**：`architecture.json` 中的 `topos`，**Layer 2**，依賴 `gcd`、`algebra`、`symlib`。
> 聯邦歸屬：**F4**（第四聯邦）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/topos`。

---

## 1. 定位

`topos` 把「拓撲斯」這門以**存在定理**為主的學科，翻譯成**有限、可窮舉、可執行**的判定程序：所有物件（景、篩、預層、層、群胚纖維化、神經）都以有限表格表示，因此泛性質（極限、伴隨、分類子、下降）可以**逐點計算**而不是引用。

七個 Layer（由下而上）：

```text
Layer 7  logic_classifying_categorify.mbt   幾何邏輯、分類 topos、範疇化
Layer 6  stacks_cohomology_homotopy.mbt      群胚棧、Čech/層上同調、神經同倫
Layer 5  geometric_morphism_local_properties 幾何態射、Diaconescu 點、local/connected/atomic
Layer 4  derived_structural_theorems.mbt     Ran 伴隨、開閉子拓撲斯、比較引理、G-主叢、杯積
Layer 3  sheaf_ccc_omega.mbt                層化、笛卡兒閉性、子物件分類子 Ω_J
Layer 2  site_presheaf.mbt                  有限範疇、景、篩、預層、自然變換、米田
Layer 1  @gcd / @algebra / @symlib          精確秩、有理消元、FinCat/預層/Kan
```

---

## 2. 檔案清單（7 檔，約 7.5k 行）

| 檔案 | 行數 | 主題 |
|---|---:|---|
| `site_presheaf.mbt` | 1409 | 有限範疇與景、篩（sieve）格、預層與自然變換、極限／餘極限、廣義米田引理（含群胚 `BG` 的多態射情形） |
| `sheaf_ccc_omega.mbt` | 1059 | 層判定與 `sheafify`、層 topos 的笛卡兒閉性（內冪對象）、子物件分類子 `Ω_J`、Lawvere–Tierney 核 |
| `geometric_morphism_local_properties.mbt` | 952 | 幾何態射 `f* ⊣ f_*`、Diaconescu 點（平坦 + `J`-連續）、local / connected / atomic / compact-coherent 判定、Deligne 足夠點 |
| `derived_structural_theorems.mbt` | 841 | 右 Kan 擴張 `Ran_{φ^op}`、本徵幾何態射三伴隨 `Lan ⊣ φ* ⊣ Ran`、開／閉子拓撲斯互補、比較引理、內蘊 `G`-主叢、Alexander–Whitney 杯積 |
| `stacks_cohomology_homotopy.mbt` | 1365 | 群胚纖維化與有效下降、`ℚ`-上同調（層／Čech／Roos group）、Snake Lemma 長正合、單純神經同倫型（`π₀`、`π₁` 自由秩與撓、Betti、`χ`） |
| `logic_classifying_categorify.mbt` | 1141 | 幾何公式與幾何邏輯、分類 topos、Sierpiński/圓周等具體景、範疇化摘要 |
| `double_negation_alexandrov.mbt` | 750 | 雙重否定核 `j(x) = ¬¬x` 預層層化模板、篩格雙 Heyting（co-Heyting 差 `⇐`、餘否定 `~`、邊界 `∂A`）、亞歷山德羅夫下閉開集對偶與 `Chu(Set, K)` 萬有自對偶 |

---

## 3. 逐檔精讀

### 3.1 `site_presheaf.mbt` — 一切的地基
* **景 `Site`**：`cat`（`@sym.FinCat`）+ 每個物件的覆蓋篩族。篩是 `y(u)` 的子預層，並在**篩格**上支援 `∧`/`∨`/`⊤`/`⊥`，因此「某篩是否覆蓋」是有限查表。
* **預層 `@sym.Presheaf` 與自然變換 `PresheafHom`**：`presheaf_hom_is_natural` 逐 `f : u → v`、逐 `x ∈ p(v)` 驗 `α_u(p.res[f](x)) == q.res[f](α_v(x))`。
* **極限／餘極限**：`presheaf_product`、`presheaf_coproduct`、`presheaf_pullback`、`presheaf_equalizer`、`presheaf_coequalizer` —— 全部逐物件委派給 `@sym`（`product_set`、`pullback_set`、`equalizer_set`）。
* **米田**：`yoneda_elem_to_hom` 給出 `p(a) → Hom_PSh(y(a), p)` 的正向雙射，`verify_general_yoneda_lemma` 驗證往返；特別支援**非 thin** 的有限範疇（如群胚 `BG`，有平行自同構）。
* **「厚度」的處理**：`presheaf_representable_with_table` 額外回傳 `hom_arrows[u][idx]`，因為在 `BG` 中「有幾個態射」本身就是要計算的資料。

### 3.2 `sheaf_ccc_omega.mbt` — 層、內冪、分類子
* **層判定**：對每個覆蓋篩做 equalizer 檢查 `F(u) → Π_i F(U_i) ⇉ Π_{ij} F(U_i ×_u U_j)`；失敗時回傳破壞等化的具體見證。
* **`sheafify`**：兩步層化（`+` 再 `++`），並驗證「層化後確實是層」與伴隨的單位。
* **笛卡兒閉性**：內冪對象 `Q^P` 以「`Q` 上的自然變換族」表示，並驗證 `Hom(P × Q, R) ≅ Hom(P, R^Q)` 的有限情形。
* **子物件分類子 `Ω_J`**：`Ω_J(u) = { J-閉篩 on u }`，`χ` 對每個子物件回傳其特徵篩；Lawvere–Tierney 核 `j` 由一個閉／密篩族決定，並驗證 `j∘j = j`、`j ⊣` 內蘊序、`j(⊤)=⊤`。

### 3.3 `geometric_morphism_local_properties.mbt` — 幾何態射與點
* `direct_image_presheaf`：`(f_* Q)(u) = Q(Φ(u))`；`inverse_image_presheaf = Lan_{Φ^op}`；`inverse_image_sheaf = a_K ∘ Lan`。
* `verify_geometric_morphism`：`f_*` 送 `K`-層到 `J`-層 + `f* ⊣ f_*` 的單位／餘單位在有限物件上成立。
* **Diaconescu 點**：`FlatPointFunctor`（協變 `C → FinSet`）；`is_flat_point_functor` 檢查元素範疇 `∫F` 是否餘濾（非空、對角填充、平行箭頭等化）；`is_diaconescu_point` 再加 `J`-連續（覆蓋篩的像聯合滿射）。`point_stalk_cardinality` 與 `point_skyscraper_sheaf` 給出 `p*`、`p_*` 的實際計算。
* **局部性等級**：`analyze_local_topos`（`Δ ⊣ Γ ⊣ Γ^!`）、`analyze_connected_topos`（`Π₀ ⊣ Δ ⊣ Γ`）、`analyze_atomic_topos`（原子與布林性）、`analyze_compact_coherent_topos`（緊緻／相干／空間性，含 Deligne 足夠點）。

### 3.4 `derived_structural_theorems.mbt` — 三伴隨、互補、比較、主叢、杯積
| 內容 | 關鍵函式 |
|---|---|
| 右 Kan 擴張預層 | `right_kan_presheaf`（`(Ran_{φ^op}P)(d) = lim_{(d ↓ φ^op)} P`，直接委派 `@sym.ran`） |
| 本徵幾何態射三伴隨 | `verify_essential_geometric_triple_adjunction`（`e_! ⊣ e* ⊣ e_*`）、`is_connected_essential_functor` |
| 拓撲格 | `topology_lattice_meet`（子拓撲斯**聯集**）、`topology_lattice_join`（子拓撲斯**交集**） |
| 開／閉子拓撲斯 | `open_subtopos_lt_operator`（`j_open(S) = (U ⇒ S)`）、`closed_subtopos_lt_operator`（`j_closed(S) = U ∪ S`）、`verify_open_closed_subtopos_complementarity` |
| 稠密比較引理 | `induced_dense_subsite_topology`、`verify_grothendieck_comparison_lemma`（`Sh(C,J_C) ≃ Sh(D,J_D)` 的 Morita 等價） |
| 內蘊 `G`-主叢 | `InternalGroupTorsor`、`is_internal_group_torsor_sheaf`、`build_mobius_internal_z2_torsor()`（圓周上的非平凡 `ℤ/2ℤ`-主叢） |
| Alexander–Whitney 杯積 | `simplicial_cup_1_1`、`verify_alexander_whitney_leibniz`、`simplicial_cup_h1_h1_rank` |

**兩個同 Betti 數但不同型的空間**（本檔的招牌對照）：

```text
T²（7 頂點 Möbius–Császár 三角化）        S¹ ∨ S¹ ∨ S²（∂Δ³ 加兩個中空三角形）
b = [1, 2, 1, 0], χ = 0        vs.        b = [1, 2, 1, 0], χ = 0
但 ⌣ : H¹ ⊗ H¹ → H² 在 T² 上的秩 = 1（辛形式），在楔上 = 0
```
⇒ 杯積環**區分**了這兩者，而 Betti 數不能。這正是 `bridge/geometry_logic_atlas.mbt` 引用的事實之一。

### 3.5 `stacks_cohomology_homotopy.mbt` — 下降與上同調
* `FiniteGroupoid`/`GroupoidFibration`：`M : base^op → Grpd` 的分裂纖維化，`pullbacks[f]` 是 `f*`。
* `CoverDescentDiagram`：覆蓋族的重疊拉回圖 + **偽函子裂解相干轉移** `θ_{f_i,p1}⁻¹ ∘ θ_{f_j,p2}`。
* `verify_descent_cocycle`（`φ_ii = id`、三重疊相干）與 `verify_stack_effective_descent`（每個全域物件都有典範下降資料；每個有效餘圈都來自全域物件 ⇒ **棧的有效下降公理**）。
* `build_circle_z2_torsor_stack()` + `circle_mobius_double_cover_sheaf()`：`S¹` 上的 Möbius `ℤ/2ℤ`-主叢 —— 局部同構於大小 2 的常數層，但 `S¹` 上有 **0 個全域截面**。
* `classify_group_torsor_cohomology`：任意神經 + 任意有限群（含非交換 `S₃`）的**非阿貝爾 Čech `H¹`** 分類。
* `RectQMat`/`CochainComplexQ`：精確有理上鏈複形；`cohomology_dimensions`、`verify_euler_poincare`（`Σ(-1)^k dim C^k = Σ(-1)^k dim H^k`）、`verify_snake_lemma_cohomology_les`（短正合列 ⇒ 長正合列）。
* `compute_nerve_homotopy_type`：抽出 `π₀`、`π₁` 自由秩與撓不變因子（用 `@gcd.zmat_snf` 抽 `∂₂` 的不變因子）、有理 Betti `[b₀,b₁,b₂,b₃]`、`χ`。測試物件：`boundary_simplex_nerve(d)`（`S^{d-1}` 的好覆蓋 Čech 神經）、`rp2_minimal_nerve()`（`H₁ = ℤ/2ℤ` 撓 `[2]` 而 `H^*(RP²;ℚ) ≅ ℚ[0]`）。

### 3.6 `logic_classifying_categorify.mbt` — 邏輯與分類 topos
幾何公式（`⊤/⊥/∧/∨/∃/⇒`）的語法與**幾何蘊含**判定；給定有限理論 `𝕋` 建分類 topos `B(𝕋)`；`Sh(0 → 1)`（Sierpiński topos，非布林）作為最小反例；`@snf.SExpr`（自由冪等半環表達式）與幾何公式的**四柱規範形式合一**（見 `bridge/logic_theory_translation.mbt` 的 `verify_quaternary_normal_forms`）。

---

## 4. 使用的具體景（測試與橋接都用它）

| 景 | 用途 |
|---|---|
| `site_circle_good_cover()` | `S¹` 的三弧好覆蓋，Möbius 主叢與 Čech `H¹` |
| `site_sierpinski()`（`0 → 1`） | 非布林 topos：Glivenko 雙否定、開閉子拓撲斯切除 |
| `site_interval_classifying()` | `CCHM` 區間的分類 topos（由 `bridge/logic_theory_translation.mbt` 建構） |
| 圓周開集偏序 / 非交叉弦森林景 | 與 `cubical`、`tensor` 的橋接點 |

---

## 5. 範例

```moonbit
// 幾何態射是否存在（需給兩側樣本預層以驗 f* ⊣ f_*）
let ok = @topos.verify_geometric_morphism(site_c, site_d, phi, p1, p2)

// Diaconescu 點
for p in @topos.enumerate_canonical_points(site) {
  println(@topos.is_diaconescu_point(site, p))
}

// T² 的杯積秩（區分 S¹∨S¹∨S² 的同 Betti 反例）
let t2 = @topos.torus_t2_minimal_nerve()
println(@topos.simplicial_cup_h1_h1_rank(t2))                    // 1
let ht = @topos.compute_nerve_homotopy_type(t2)
println(ht.betti_numbers, ht.euler_characteristic)               // [1, 2, 1, 0], 0
```

---

## 6. 依賴與被依賴

* **兩層架構拆分**：
  * `topos/site`（`L2`）：僅依賴 `symlib` 與 `accel/swar`（零線性代數依賴），承載景、篩、`Sieve64` 64-bit SWAR 雙 Heyting 核、MAC 前向檢查相容族、層化、CCC 指數、Kan 擴張、Diaconescu G-主叢與 Kripke–Joyal 幾何邏輯。
  * `topos`（`L3`）：透過 `pub using @site` 完整重導出 `topos/site` 全體 `27` 型別與 `126` 函式，並結合 `gcd`（`FpMat`、`fp_rank`、`zmat_snf`）與 `algebra`（`@exactalg.qrows_nullspace`/`qmat_rank`）提供廣群棧、單趟秩快取層上同調、模 `F_p` 撓率躍遷上同調、杯積環與神經同倫型。
* **被依賴**：`condensed`、`conjecture`、`cubical/autonomy`、`cubical/structures`、`bridge`（含 `K8-25`、`K9-32` 與 `F7→F9→F4→F1` 晉升管線）。
* **注意**：`topos` 不依賴 `scheme`；兩者在 `bridge/logic_theory_translation.mbt` 交會（Stone–Zariski–CCHM 面 → 理想轉譯）。

---

## 7. 驗證與 Artin 膠合逗號範疇（`artin_gluing_geometric.mbt`）

* **`artin_gluing_geometric.mbt`**：在 `@sym.Presheaf` 與 `topos/site` 全域截面函子 `Γ = Hom(1, -)` 上建構 **Artin 膠合逗號範疇 `Gl(Γ) = Set ↓ Γ`**（`ArtinGluedObject`、`ArtinGluedMorphism`、`artin_glued_terminal`、`artin_glued_product`、`artin_glued_booleans`、`artin_glued_enumerate_global_elements`），機器證明在非連通雙點景 `Discrete(2)` 上將純語法預層 `1 + 1` 的 `4` 個全域截面精確篩為 `2` 個規範布林元（綜合 Tait 可計算性 STC 正規性），並實作謝爾賓斯基箭頭範疇 `0 -> 1` 之 **SGA4 開—閉重黏合** `sga4_recollement_reconstruct_arrow` 與有限函子幾何拉回水平複合律 `compose_fin_functors`（由 `verify_artin_gluing_and_geometric_composition_suite()` 完整核驗，並於 `cubical/structures` 及 `bridge` 與 Orton–Pitts 扭轉 `Glue` 對帳）。

```bash
moon check --deny-warn --target wasm-gc
```
每一檔結尾都有 `verify_*` / `check_*` 一等函式（非測試檔），例如
`verify_general_yoneda_lemma`、`analyze_local_topos`、`verify_essential_geometric_triple_adjunction`、`verify_stack_effective_descent`、`verify_euler_poincare`、`verify_artin_gluing_and_geometric_composition_suite`。
