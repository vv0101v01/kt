# `cubical/hermitian/` — Hermitian 投影子與可認證的立方填充（Layer 2）

> **套件**：`vv0101v01/cubical-hermitian/cubical/hermitian` · **Layer 2**
> **依賴**：`cubical-face-bdd`、`cubical-finite`、`algebra`（精確有理／代數計算）
> **被依賴**：`root`（`bridge` 亦透過 `@cub` 使用 `CMat`）
> **9 檔 3,199 行**

---

## 1. 定位

本套件是全倉名字的來源：**Hermitian 投影子 × 依賴立方核心**。

主線是一條等式鏈：

```text
P† = P ,  P² = P
   ⇒  ℂⁿ = im(P) ⊕ ker(P)            （正交直和）
   ⇒  im(P) 是 λ = 1 特徵空間，ker(P) 是 λ = 0
   ⇒  v = Pv + (I − P)v              （唯一分解，⟨Pv,(I−P)v⟩ = 0）
   ⇒  「投影到特徵空間」就是一個 retraction ⇒ Kan 填充可被**修正**
```

每一環都提供三種精度層次：`Double`（快）→ `QuadC` 認證數值 → `AlgC` 一般代數擴張（精確）。

---

## 2. 檔案清單

| 檔案 | 行數 | 層 | 內容 |
|---|---:|---|---|
| `complex.mbt` | 300 | 浮點 | 複數／向量／方陣與 `is_hermitian`、`is_idempotent`、`is_projector` |
| `projector.mbt` | 174 | 浮點 | 投影子的特徵空間分解、正交性、可交換投影子、剪枝 retraction |
| `cube.mbt` | 326 | 浮點 | 語義 `n`-立方體、開盒、Kan `comp`（retraction 版）、特徵空間填充 |
| `system.mbt` | 182 | 浮點 | 系統（偏元素）與面商、相容性、剪枝 |
| `system_symbolic.mbt` | 103 | 符號 | 系統的 BDD 正規形（first-match 有效區） |
| `glue_comp.mbt` | 587 | 浮點 | 一般 Glue 合成的兩個模型（有限宇宙端點 / 向量） |
| `certified_numeric.mbt` | 856 | 認證 | `QuadC` 上的證書層（`ProjectorCertificate` 等） |
| `certified_algebraic.mbt` | 381 | 精確 | `AlgC`／多項式立方體，解除 `QuadC` 與次數限制 |
| `categories.mbt` | 290 | 範疇 | Karoubi 包絡、面偏序範疇、句法範疇的定律檢核 |

---

## 3. 浮點層（`complex` / `projector` / `cube`）

### 3.1 `complex.mbt`
`Complex`、`CVec`、`CMat`；`cx`、`cx_add/sub/mul/conj/scale`、`vec_zero/add/sub/scale_c`、`inner`、`vec_norm2`、`vec_orthogonal`、`mat_identity/zero/from_rows/add/sub/mul/vec/adjoint`、`mat_approx_eq`、`mat_trace_re`、`mat_commutes`。
判定核心：`is_hermitian`（`P† = P`）、`is_idempotent`（`P·P = P`）、`is_projector`（兩者）。

### 3.2 `projector.mbt`（數學的可執行版）
`outer`、`projector_from_orthonormal`、`complement`（`I − P`）、`decompose`（`v ↦ Pv + (I−P)v`）、`in_image`、`in_kernel`、`eigen_equations_hold`、`eigenspace_well_formed`、`commuting_product`、`commuting_projectors_compatible`（可交換 ⇒ `PQ` 仍是投影子）、`prune_to_eigenspace`、`pruning_is_retraction`（**剪枝是收縮**：`P(Pv) = Pv`）。

### 3.3 `cube.mbt`（立方語義與 Kan）
* `Cube`：`Iⁿ → ℂᵐ` 的外延式表示；`cube_const`、`cube_eval`、`path_eval/start/end/line/refl/sym`、`restrict_face`、`face_maps_commute`。
* 開盒：`open_box_wf`（`l(0)=b(0)`、`r(0)=b(1)` 的相容條件）、`square_fill`（仿射空間的顯式填充）、`filler_respects_box`、`kan_comp_path`、`path_trans`。
* **投影子版本**：`prune_cube`、`cube_in_eigenspace`、`kan_fill_eigenspace`、`kan_comp_eigenspace`、`eigenspace_kan_sound`、`bumped_filler`、`pruning_repairs_filler`（被剪壞的填充可由投影修正回合法填充）。

---

## 4. 系統與其符號正規形

### 4.1 `system.mbt`
系統 `[φ₁ ↦ a₁, …, φₖ ↦ aₖ]` 是**偏元素**；相容性：重疊 `φᵢ ∧ φⱼ` 上 `aᵢ = aⱼ`。
`system_of`、`branch`、`system_lookup`、`system_compatible`、`system_eq_mod`（面商相等）、`prune_system`、`pruning_respects_quotient`、`system_union`、`union_commutes_mod`、`compatibility_respects_quotient`、`system_extend_top`。

### 4.2 `system_symbolic.mbt`（103 行，關鍵）
以 first-match 語義計算每個分支的**有效區**
`effᵢ = φᵢ ∧ ¬(φ₁ ∨ … ∨ φᵢ₋₁)`（用 `@face_bdd` 的 BDD 運算），再按值分組、字典序排序 ⇒ 商類的**典範代表** `SystemNF`（`Array[SymRegion]`）。
`system_normal_form`、`system_eq_mod_sym`（與 `system_eq_mod` 交叉驗證）、`system_domain_bdd`、`vec_lex_lt`。

---

## 5. `glue_comp.mbt` — Glue 合成的兩個模型

Glue 合成的資料是「一條等價線」`(A, T, e₀, e₁, φ₀, φ₁)`，`comp` 要把它沿一個方向黏起來。

| 模型 | 型別 | 入口 |
|---|---|---|
| (1) 有限宇宙、端點演算法 | `GlueLineFinite`、`SubLine`、`LinEquivLine` | `glue_data_at0/at1`、`glue_line_coherent`、`glue_comp_finite`、`glue_comp_finite_correct`、`subline_from_unit_path`、`lin_equiv_from_unit_paths` |
| (2) 向量模型 | `GlueLineVec`、`VecBox`、`GlueCompVecResult` | `vec_box`、`cube_in_subline`、`prune_cube_subline`、`fill_subline`、`map_cube_matrix`、`map_cube_equiv_line`、`glue_box_compatible`、`glue_comp_vec`、`glue_comp_vec_sound` |

`check_glue_comp_all()` 同時驗兩個模型給出同一個答案。

---

## 6. 認證層

### 6.1 `certified_numeric.mbt`（856 行）
標量 `QuadC`（`a + b√d`，`d` 為無平方因子整數）。型別：`CertVec`、`CertMat`、`ProjectorCertificate`、`CertPath`、`CertSquare`、`NumericProjectorCertificate`。

| 群 | 函式 |
|---|---|
| 標量／線性代數 | `qcc_*`、`cert_vec_*`、`cert_mat_*`、`cert_inner`、`cert_outer`、`cert_complement` |
| 投影子認證 | `cert_is_hermitian`、`cert_is_idempotent`、`cert_is_projector`、`cert_in_image`、`cert_in_kernel`、`certify_projector`、`projector_certificate_ok`、`certify_numeric_projector`、`numeric_projector_residual` |
| 立方 | `cert_path_line`、`cert_path_is_affine`、`cert_path_sym`、`cert_square_bilinear`、`cert_square_fill`、`cert_square_apply`、`cert_open_box_wf`、`cert_filler_respects_box`、`cert_eigenspace_kan_sound`、`cert_pruning_repairs_filler` |
| 與浮點對照 | `cert_mat_to_numeric`、`numeric_mat_max_deviation`、`double_dyadic_interval` |

### 6.2 `certified_algebraic.mbt`（381 行）
解除兩項限制：標量改為 `AlgC`（實虛部同屬 `ℚ[X]/(m)`），立方改為**任意次**多項式。
`AlgC`（`algc_zero/one/i/real/add/mul/conj/scale_alg/eq`）、`AlgCertVec`、`AlgCertMat`、`AlgCertPath`、`AlgCertSquare`；
`alg_cert_is_projector`、`alg_cert_in_image`、`alg_cert_path_in_image`、`alg_cert_square_in_image`、`cube_root_two_modulus`（以 `∛2` 為例的完整證書）。

---

## 7. `categories.mbt` — 讓範疇論可執行

1. **Karoubi 包絡**（冪等分裂）於有限維 Hilbert 空間：物件是 Hermitian 冪等 `P`，態射 `P → Q` 是滿足 `Q·A·P = A` 的矩陣 `A`，`id_P = P`。`karoubi_morphism`、`karoubi_wrap`、`karoubi_id`、`karoubi_comp`、`check_karoubi_category`。
2. **面偏序範疇**：`face_meet_universal`、`face_join_universal`、`check_face_poset_category`。
3. **退化立方體與立方恆等式**：`degenerate_cube`、`cube_ext_eq`、`check_cubical_identities`。
4. **句法範疇**：`check_syntactic_category`。
總開關：`check_categories_all()`。

---

## 8. 範例

```moonbit
// 1) 造一個投影子並驗證分解
let v = @hermitian.vec_e3()
let p = @hermitian.example_projector()
assert_true(@hermitian.is_projector(p))
let (x, y) = @hermitian.decompose(p, v)          // v = Pv + (I-P)v
assert_true(@hermitian.vec_orthogonal(x, y))     // 兩塊正交

// 2) 剪枝是收縮
assert_true(@hermitian.pruning_is_retraction(p, v))

// 3) 系統的符號正規形
let nf = @hermitian.system_normal_form(sys)
assert_true(@hermitian.system_eq_mod_sym(sys, other))
```

---

## 9. 依賴邊界與驗證

* **依賴**：`face_bdd`（BDD）、`finite`（有限宇宙等價）、`algebra`（`Rat`/`AlgNum` 精確算術）。
* **不依賴 `kernel`**：這是刻意的 —— 本套件是 `kernel` 的**語義樣板**，兩者平行開發、互相對照。
* `bridge/graph_symmetry.mbt` 的 `matrix_support_graph` / `matrix_permutation_symmetries` 會把 `CMat` 的支撐轉成 `symlib` 圖。

```bash
moon test cubical/hermitian --target wasm-gc     # 單包微測試實測 0.57s
```
