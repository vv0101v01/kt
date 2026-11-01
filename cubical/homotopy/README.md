# `cubical/homotopy/` — 合成同倫與計算性單值性（Layer 3，13 檔 11,993 行）

> **套件**：`vv0101v01/cubical-hermitian/cubical/homotopy` · **Layer 3**
> **依賴**：`gcd`、`algebra`、`cubical-face-bdd`、`cubical-finite`、`cubical-kernel`
> **被依賴**：`root`（`bridge` 的 `K6-11`／`K7-16` 交叉驗證引用其結果）
> 單包微測試實測 **0.38s**

---

## 1. 定位

本套件把同倫論的定理做成**核心內可計算的物件**，並且嚴格區分三種「證據等級」（這是全倉的寫作規範）：

| 等級 | 意思 | 例子 |
|---|---|---|
| **核心計算** | 在 `kernel` 內以 NbE 真正算出 | `circle_encode_value`、`pi2_s2_hopf_hom_value`、`assoc_fvector` |
| **顯式資料** | 有具體等價／路徑資料，可逐點檢查 | `sphere3_swapped_equiv_value`、`loop_suspension_adjunction_equiv_value` |
| **引用標記** | 移植成本而非未知，以 `*_origins` 函式標明來源 | `pi4_s3_origins`、`pi3_s2_iso_pi3_s3_origins` |

---

## 2. 檔案清單

| 檔案 | 行數 | 主題 |
|---|---:|---|
| `cubical_algorithms.mbt` | 1,944 | Kan 盒、`transport`、`dpath_*` 族、Eckmann–Hilton、五邊形、`K₅` 胞 |
| `adjoint_equivalence.mbt` | 993 | 伴隨等價、可收縮纖維、`adjointify` |
| `univalence.mbt` | 778 | 兩層 `ua`（有限宇宙符號 / 依賴核心） |
| `circle_classify.mbt` | 1,558 | 圓周 encode/decode、泛覆蓋、`π₁(S¹) ≃ ℤ` |
| `sphere3.mbt` | 211 | 迭代懸垂造 `S²`、`S³` |
| `sphere_classification.mbt` | 827 | 內建整數、同倫群商型別、球面環路代表 |
| `sphere_homotopy.mbt` | 2,470 | 度映射、Hopf 映射（數值 + **精確有理**）、懸垂 ⊣ 環路伴隨、Freudenthal |
| `truncation.mbt` | 598 | 命題截斷／集合截斷（由參數面生成的 HIT） |
| `homotopy_universal.mbt` | 592 | join、wedge、`n`-截斷、James 構造 |
| `associahedron.mbt` | 650 | 任意 `n` 的 Stasheff `Kₙ` |
| `higher_coherence_k6.mbt` | 452 | `F₂` 非交換方形填充、`K₆` 相干、六項突破證書 |
| `blakers_massey.mbt` | 497 | Blakers–Massey、Freudenthal、球面低階同倫群 |
| `brunerie_pi4_s3.mbt` | 423 | `π₄(S³) ≅ ℤ/2ℤ` |

---

## 3. 基本同倫代數（`cubical_algorithms.mbt`）

* **Kan 盒**：`KanBox`、`kan_box`、`kan_box_fill`、`kan_box_comp`、`kan_box_pathp`。
* **transport**：`transport_value`、`transport_back_value`、`transport_checked_line_value`、`transport_filler_value`、`transport_pathp_value`、`dtransport_term`、`dtransport_back_term`。
* **依賴路徑族**：`dpath_refl/sym/trans/cong/funext`、`dpath_segment`、`dpath_prefix`、`dpath_trans_square`、`subst_value`、`subst_pathp_value`、`subst_refl_eq`、`subst_trans_eq`。
* **高階相干**（這一段是本檔的價值所在）：
  `dpath_left/right_unit3`、`dpath_left/right_inverse3`、`dpath_assoc3`、`dpath_sym_compose3`、
  `dpath_eckmann_hilton3`（`π₁` 在 `n ≥ 2` 時交換）、`dpath_pentagon4_value`（Mac Lane 五邊形）、
  `dpath_lr_unit_coherence4`、`dpathp_of_transport_eq`、`dpath_of_pathp`、`dpathp_eq_in_set_family`。
* **`K₅` 的顯式胞**：`dpath_k5_lhs1/rhs1`、`dpath_k5_route_outer3/inner3`、`dpath_k5_hemi_north4/south4`、`dpath_associahedron_k5_cell5_value`。
* η／σ 型別：`sigma_path_equiv_value`、`sigma_cong_snd_equiv_value`、`fibration_loop_equiv_fiber_path_value`。

---

## 4. 等價與單值性

### 4.1 `adjoint_equivalence.mbt`
一般等價只有 section/retraction；**伴隨等價**多一個三角相干
`τ(x) : Path (Path B (f (g (f x))) (f x))`。

* 型別：`fiber_type_term`、`is_contr_type_term`、`contractible_fibers_type_term`、`equiv_triangle_type`。
* 構造：`equiv_improved_sect_value`（把 section 改善為相干）、`equiv_with_improved_sect`、`adjoint_equiv_type_term`、`adjoint_id_value`。
* 定理：`singleton_contraction_value`、`equiv_fiber_center_value`、`equiv_fiber_path_value`、`equiv_contractible_fibers_value`、`adjointify_equiv_value`（**任意等價都可伴隨化**）。
* 檢核：`check_adjoint_equivalence_and_fibers()`、`check_general_adjointification_and_contractible_fibers()`、`check_glue_equiv_quote_preserves_syntax()`、`check_lemiso_generic_points()`。

### 4.2 `univalence.mbt`
兩層實作，理由是成本：
1. **有限宇宙**（`pathp_glue.mbt` 的 wiring）：宇宙路徑 = wiring 等價，`ua` 與 `pathToEquiv` 以 wiring 相等互逆，**transport 以符號方式決定**（不枚舉立方體）。`upath_to_equiv`、`upath_refl/sym/trans`、`finite_transport`、`check_finite_univalence()`。
2. **依賴核心**：`path_to_equiv_value`、`equiv_to_universe_path_value`、`ua_transport_value`、`ua_beta_path_value`、`ua_beta_back_path_value`、`univalence_retr_path_value`、`univalence_sect_square_value`、`univalence_equiv_value`、`universe_path_of_checked_line`、`universe_path_normal_form`、`universe_path_transport_conv`、`path_to_equiv_term`、`ua_map_term`。
* 另附 `equiv_bidirectional_certified(_in)`：雙向認證的等價。

---

## 5. 圓周與球面

### 5.1 `circle_classify.mbt`（1,558 行，招牌結果）
圓周 HIT 的**泛覆蓋（螺旋）**在內部定義：對圓周歸納到宇宙，`base` 上的纖維 = 整數型別，`loop` 上的纖維 = 後繼等價的 `ua` 線。

* `circle_hit_type_value`、`circle_loop_space_type_value`、`circle_cover_value`。
* **encode**：`circle_encode_value`、`circle_encode_pieces_value`、`circle_encode_x_value`。
* **decode**：`circle_decode_value`、`circle_decode_step_value`、`circle_decode_x_value`。
* **互逆**：`circle_encode_decode_sect_value`（encode∘decode = id）、`circle_decode_encode_retr_value`、`circle_encode_decode_x_sect_with_zset_value`。
* **結論**：`circle_loop_space_equiv_integer_value`、`pi1_set_circle_equiv_integer_value` —— `π₁(S¹) ≃ ℤ` 是**算出來的**。
* 副產物：`integer_succ_equiv_value`、`integer_pred_succ_retr_value`、`integer_is_set_value`（`ℤ` 是集合）、`empty_inductive_*`。
* `check_circle_encode_decode()`。

### 5.2 `sphere3.mbt` / `sphere_classification.mbt` / `sphere_homotopy.mbt`
* **造球**：`suspension_schema` → `sphere2_schema` → `sphere3_schema` → `sphere_schema(n)`；`sphere3_type_value`、`sphere3_north/south/meridian_value`。
* **內部整數與商**：`integer_schema`、`homotopy_group_type_term`、`sphere_type_term`、`loop_space_type_value`。
* **環路代表**：`suspend_loop_value`、`sphere_loop_power_value`、`sphere_loop_compose_value`、`sphere_loop_canonical_expr` / `_normal_form` / `_same_class`、`sphere_loop_expr_normalize3_value`。
* **度映射**：`circle_degree_value`、`suspension_map_value`、`sphere_degree_value`、`suspension_meridian_path_value`、`suspension_unit_loop_value`。
* **`S³` 的自等價資料**：`sphere3_swapped_schema`、`sphere3_to_swapped_value`、`sphere3_from_swapped_value`、`sphere3_swapped_retr_value`、`sphere3_swapped_sect_value`、`sphere3_swapped_equiv_value`。
* **Hopf 映射**：`hopf_map_s3_to_s2`、`hopf_phase_rotate`、`hopf_north_fiber`、`hopf_south_fiber`、`hopf_linking_number_numeric`（數值）／`hopf_map_rat`、`hopf_rotate_rat`（**精確有理**）、`check_hopf_numeric()`、`check_hopf_exact_rational()`、`hopf_invariant_value`、`hopf_total_loop_equiv_fiber_seq_value`、`hopf_freudenthal_retraction_value`。
* **懸垂 ⊣ 環路**：`susp_cocone_type_value`、`susp_universal_equiv_value`、`susp_based_to_cocone_equiv_value`、`cocone_to_based_loop_equiv_value`、`loop_suspension_adjunction_equiv_value`。
* **Freudenthal 的具體片段**：`circle_0_connected_value`、`susp_0_connected_of_pointed_value`、`freudenthal_pi1_susp_connected_equiv_unit_value`、`pi1_susp_circle_equiv_unit_value`、`pi1_susp2_circle_equiv_unit_value`、`freudenthal_susp_loop1_to_loop2_value`、`freudenthal_susp_loop1_preserves_refl_value`。
* **`π₂(S²) ≃ ℤ`**：`pi2_s2_type_value`、`pi2_s2_hopf_hom_value`、`integer_to_pi2_s2_value`、`pi2_s2_hopf_retract_sect_value`。

---

## 6. 截斷與通用 HIT

### 6.1 `truncation.mbt`
命題截斷由 kernel 的**參數面** `dhit_arg_face` 生成：
```text
‖A‖ ::= point (a : A)
      | squash (x y : ‖A‖) : x ⇝ y      ← 端點就是兩個引數本身
```
* `prop_trunc_schema(_at)`、`trunc_type_term`、`trunc_point_term`、`trunc_squash_term`、`trunc_squash_path_term`、`trunc_rec_unit_term`、`prop_trunc_elim_prop_value`、`check_propositional_truncation()`。
* **集合截斷**：`set_trunc_schema(_at)`、`set_trunc_type_value`、`set_trunc_hub_value`、`set_trunc_spoke_path_value`、`set_trunc_loop_trivial_value`、`set_trunc_is_set_value`、`set_trunc_rec_set_value`、`set_trunc_elim_set_value`、`set_trunc_elim_prop_value`、`set_trunc_equiv_of_equiv_set_value`（等價則截斷等價）。

### 6.2 `homotopy_universal.mbt`
邊界 #6 所缺的型別形成子，全部宣告成真正的立方 HIT 並附遞歸原則：
* **join**：`join_schema_at`、`join_type_value`、`join_inl/inr_value`、`join_push_value`、`join_cocone_type_value`、`join_rec_value`、`join_dim`；
* **wedge**：`wedge_schema_at`、`wedge_type_value`、`wedge_winl/winr_value`、`wedge_glue_value`、`wedge_rec_value`；
* **`n`-截斷**：`trunc_schema_at(n)`、`trunc_type_value`、`trunc_inc_value`、`trunc_rec_value`；
* **James 構造**：`james_schema_at`、`james_type_value`、`james_nil_value`、`james_cons_value`、`james_rec_value`、`james_cell_dim`；
* `homotopy_universal_remaining()` 誠實列出仍缺的項目。

---

## 7. 相干：`Kₙ` 與 `F₂`

### 7.1 `associahedron.mbt`（任意 `n`）
Mac Lane 相干定理保證每個結合子圖都交換 ⇒ 逐 `n` 建構即可，不是無限塔。
* 括號化：`Paren`/`Stree`、`paren_leaves`、`paren_all`、`paren_renumber`、`paren_left/right_spine`、`stree_leaves`、`stree_dim`、`stree_all`；
* 翻轉圖：`paren_rotations`、`paren_rotation_edge_count`、`paren_rotation_graph_connected`；
* 不變量：`assoc_fvector`、`assoc_two_faces`、`catalan`、`assoc_euler_characteristic`；
* 核心值：`assoc_tree_value`、`check_assoc_faces()`。
`bridge/K7-16` 用 `assoc_fvector(4) = [5, 5, 1]` 對接 `tensor` 的 `C₃ = 5`、`C₄ = 14`。

### 7.2 `higher_coherence_k6.mbt`（`F₂` 非交換）
「8 字形」`S¹ ∨ S¹` 的方形邊界填充：`top⁻¹ · left · bottom · right⁻¹ = 1` 必須在**自由群 `F₂`** 中判等（用 `@gcd.ugcd_free_group_reduce`），**不能**只看阿貝爾化 `H₁ = ℤ²` 的繞數 `(0,0)` —— 後者會給出錯誤的「可填充」。
* `f2_reduce_word`、`f2_invert_word`、`wedge_square_filler_report`（`WedgeSquareFillerReport`）；
* `dpath_k6_*` 系列（`K₆` 的半球與路線）；
* `check_variable_endpoint_hits()`；
* 同時印出六項突破的證書標籤：`[T-Singleton-N]`、`[T-Associahedron-K6]`、`[T-VarEndpoint-HIT]`、`[T-Adams-Brunerie-Bridge]`、`[T-HOU-InnerLam]`、`[T-Goldfarb-Diophantine]`、`[T-BFT-Ed25519-WAL]`、`[T-Tarjan-MVCC-HotLoad]`。

---

## 8. Blakers–Massey 與 Brunerie

### 8.1 `blakers_massey.mbt`
* `FgAb`（有限生成阿貝爾群帶撓：`fg_zero`、`fg_z`、`fg_zmod`、`fg_is_trivial`、`fg_rank_le`）；
* 長正合片段：`les_middle_is_injective/surjective/iso`；
* 連通度缺口：`bm_gap`、`gap_equiv_below`、`gap_surj_at`、`conn_of_sphere`；
* 具體結論：`pi_circle`、`hopf_les_iso/injective/surjective`、`freudenthal_status`、`suspension_gap`、`pi3_s2_iso_pi3_s3`、`pi3_s3_iso_pi2_s2`、`pi2_s2_iso_z_halves`；
* 誠實標記：`*_origins`（每個成分註明「自證」或「引用」），`check_blakers_massey()`。

### 8.2 `brunerie_pi4_s3.mbt`
* `join_sphere_dim`、`s3_is_join_of_two_circles`（`S³ = S¹ * S¹`）；
* `whitehead_degree`、`brunerie_whitehead_lives_in`、`james_cells`；
* `BrunerieNorm` / `BrunerieNumber`；`brunerie_original`、`brunerie_new_family`；
* `brunerie_norm_establishes`、`brunerie_family_establishes`、`brunerie_family_decreasing`；
* `cyclic_of_beta`、`pi4_s3_iso_pi4_s2`、`pi4_s3_group`；`pi4_s3_origins`、`check_brunerie_pi4_s3()`。

> **與 `condensed` 的交叉驗證**：代數側 `Ext_A^{2,3}(F₂,F₂) = 0`（即 `2η = 0`）與此處幾何側 `|β| = 2` 由 `bridge/K6-11` 對接 —— 兩條完全獨立的計算得到同一個 `ℤ/2ℤ`。

---

## 9. 範例

```moonbit
// 1) π₁(S¹) ≃ ℤ：encode/decode 互逆
assert_true(@homotopy.check_circle_encode_decode())

// 2) 任意 n 的結合多面體面向量
let fv = @homotopy.assoc_fvector(4)        // [5, 5, 1]
assert_true(@homotopy.check_assoc_faces())

// 3) F₂ 判等而非 H₁：非交換繞數
let rep = @homotopy.wedge_square_filler_report()
assert_true(rep.free_group_holds)          // 真判準
assert_false(@homotopy.abelian_winding_zero_suffices())  // 反例

// 4) π₄(S³) = Z/2Z
assert_true(@homotopy.check_brunerie_pi4_s3())
```

---

## 10. 驗證

```bash
moon test cubical/homotopy --target wasm-gc      # 單包微測試實測 0.38s
```
一等檢核：`check_cubical_algorithms()`、`check_finite_univalence()`、`check_univalence()`、`check_circle_encode_decode()`、`check_sphere_homotopy_representatives()`、`check_sphere_loop_representatives_internal()`、`check_propositional_truncation()`、`check_assoc_faces()`、`check_variable_endpoint_hits()`、`check_blakers_massey()`、`check_brunerie_pi4_s3()`、`check_homotopy_universal()`。
