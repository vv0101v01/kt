# `cubical/kernel/` — 可信依賴立方核心（Layer 2，20 檔 30,899 行）

> **套件**：`vv0101v01/cubical-hermitian/cubical/kernel` · **Layer 2** · 依賴 `cubical-face-bdd`、`cubical-finite`
> **被依賴**：`cubical-elaborator`、`cubical-homotopy`、`cubical-store`、`root`
> **封印原則**：**零浮點、零代數耦合**；不變量載體是唯讀 `pub struct`，外圍套件**無法繞過檢驗器偽造**。
> 單包微測試實測 **0.95s**（Wave 3 基準）。

---

## 1. 定位

這裡是整個系統的**唯一信任邊界**。它同時承擔四組**互遞迴**的職責（Tarjan SCC 實證為一個強連通分量，因此**不允許拆包**）：

```text
        ┌─────────────────────────────────────────────┐
        │  NbE 求值  ⇄  Kan 填充  ⇄  Glue 等價         │
        │      ⇅              ⇅            ⇅          │
        │  DSystem 相容   歸納/HIT/Open-IR Schema       │
        └─────────────────────────────────────────────┘
```

如果強行拆成多個套件，會被迫引入函式指標間接層或把核心展開為 `pub(all)`，兩者都會破壞封裝。

---

## 2. 檔案地圖

| 組 | 檔案 | 行數 |
|---|---|---:|
| **語法／語義基礎** | `dterm_transform.mbt` | 445 |
| | `dterm_intern.mbt` | 616 |
| | `nbe_dep.mbt` | **4,555** |
| | `checked_line.mbt` | 286 |
| | `conv_case_split.mbt` | 785 |
| **Kan 運算** | `kan_dep.mbt` | 625 |
| | `kan_ast.mbt` | 1,838 |
| | `equiv_ast.mbt` | 1,271 |
| | `dcube_filler.mbt` | 1,350 |
| **DSystem** | `dsystem_compat.mbt` | 2,506 |
| | `dsystem_sheaf_reify.mbt` | 272 |
| **Schema 生成器** | `schema.mbt` | **4,459** |
| | `schema_positivity.mbt` | 2,033 |
| | `schema_functor.mbt` | 2,623 |
| | `schema_inductive_recursive.mbt` | 2,045 |
| | `schema_open_ir.mbt` | 1,844 |
| | `schema_extensions.mbt` | 728 |
| | `schema_universe_poly.mbt` | 1,816 |
| | `schema_registry.mbt` | 585 |
| **序數／能力邊界** | `ordinal_mahlo.mbt` | 217 |

---

## 3. 語法與語義

### 3.1 `dterm_transform.mbt`
`DTerm` 的結構操作：`dterm_children`（子項序列）、`dterm_rebuild`（**精確逆**）、`dterm_shift`、`dterm_substitute`、`dterm_map_vars_at`、`dterm_dim_vars`。`d_nat_lit` / `dv_nat_lit` / `dv_is_nat` / `dv_is_bool_dep`。

### 3.2 `dterm_intern.mbt`
**雜湊 consing**：`DTermInternTable` 自底向上 intern；節點鍵是「本地 stamp」= 把子節點換成其 id 後的快取鍵。
`dterm_intern_table_new/size`、`dterm_intern_table_term`、`dterm_intern_lookup_id`、`dterm_intern_node`、`dterm_intern`、`dterm_local_shell`、`dterm_tree_node_count`（樹大小）vs `dterm_distinct_subterm_count`（DAG 大小）—— 兩者差距就是共享帶來的省下量。
快照／導入：`dterm_dag_snapshot`、`dterm_intern_table_snapshot`、`dterm_dag_snapshot_validate`、`dterm_dag_import`（`cubical-store` 的 `dterm_dag_binary.mbt` 在此之上做持久化）。

### 3.3 `nbe_dep.mbt`（4,555 行 — 全倉最大的單一檔案）
核心型別：`DTerm`／`DValue`／`DNeutral`／`DThunk`（惰性求值 + `force_value`／`lazy_force_count`）／`DEnv`／`DDimEnv`；`DSystem`／`DSystemNF`；`DInfer`／`DTypeVal`／`DFamilyParts`／`DPathParts`／`DGlueParts`。

四大函式族（彼此交錯）：
* `eval_*`：求值（含 `eval_dim_expr`、`eval_under`）；
* `infer_*`：型別推導；
* `quote_*`：語義 → 語法（含 `quote_neutral`、`dim_quote`）；
* `conv_*`：轉換（定義相等）檢查。

輔助：`fresh_dim`、`dim_cache_key`、`dterm_cache_key`、`memo_dim_line`、`memo_family`（維度線與族的記憶化）、`dapp_typed`／`dfst_typed`／`dsnd_typed`（帶型別投影）、`reflect_neutral_at_type`。

### 3.4 `checked_line.mbt` — 可替換的語義型別線
裸線是宿主函數 `Dim → DValue`，**理論上**可以窺看維度語法而不尊重替換。`DCheckedTypeLine` 改為儲存 `DTerm` 本體 + 持久環境，在**一個新維度綁定子**下檢型；於是在 `i` 求值就等於把 `i` 代入該本體。
`checked_type_line(_closed)`、`checked_constant_type_line(_closed)`、`checked_ua_line`、`checked_line_at/fn/level/is_constant/endpoints`、`checked_line_quote_body`、`checked_coe_value`、`checked_line_reify_closed`、`dvalue_subst_dims`、`checked_line_reparam_closed`、`check_semantic_dimension_substitution()`。

### 3.5 `conv_case_split.mbt` — 離散情境的個案分裂
`if x then 0 else 0` 與 `0` 對中性 `Bool` 變數 `x` **不**可轉換（語義比較是結構的），但 `Bool` 是離散型別 ⇒ 在 `x = true` 與 `x = false` 兩支都相等時才判等。
`conv_terms_case_split`、`conv_terms_case_split_report`（`CaseSplitReport`）、`conv_difference_variables`、`conv_terms_plain`（對照組）、`cs_finite_closed_inhabitants`、`conv_terms_finite_case_split(_report)`。

---

## 4. Kan 運算

| 檔案 | 內容 |
|---|---|
| `kan_dep.mbt` | 抽象 `DLine`（`at` / `coe` / `fill`）與各型別形成子的線：`dline_const/bool/unit/univ/pi/sigma/pi_constfam/sigma_constfam/from_maps/rev/subst`；`dcoe`、`dfill`、`dcomp`；嵌入 `dline_of_lty`／`dvalue_of_ty`／`dline_of_upath`；檢核 `check_kan_coe_pi_sigma`、`check_kan_coe_dependent`、`check_kan_comp_tube`、`check_kan_embeddings`、`check_kan_dep_all` |
| `kan_ast.mbt` | `DCoe`/`DComp`/`DHComp`/`DHFill` 的**計算內容**：`coe_value`、`comp_value`、`hcomp_value`、`fill_value`、`hfill_value`；按線在泛維度取樣的形狀分派：`comp_pi_value`、`comp_sigma_value`、`comp_path_value`、`comp_univ_value`、`comp_glue_value`、`comp_bool_value`、`comp_nat_value`、`comp_list_value`、`comp_circle_value`、`comp_torus_value`；HIT 見證：`circle_path_winding_int`、`circle_square_glued_cap`、`torus_square_glued_cap`（`CircleSquareWindingReport`） |
| `equiv_ast.mbt` | `DVEquiv`（兩型別 + 兩函數 + section/retraction 路徑）與 `DVGlueEquiv`（語義 Glue，合成直接用 `equivFun`/`equivInv`）⇒ `ua`：`ua_type_at`、`ua_line_value`、`ua_value`、`eval_ua_term`、`infer_ua`；`glue_equiv_collapse`、`glue_equiv_partial_values`、`comp_glue_equiv_value`、`d_check_glue_equiv_partial`、`glue_equiv_systems_conv`；部分性檢查 `d_check_glue_equiv_partial` |
| `dcube_filler.mbt` | 外延式 `DCubeFunction`（一軸一個維度式）、`DCubeOpenBox`（供應除 cap 外的所有面）、`dcube_box_fill`（沿最後一軸單一齊性合成）；驗證 `dcube_filler_faces_ok`、`dcube_box_fill_verified`；進階 `_stratified`（分層）、`_covering`（覆蓋）、`dcube_phf_5colors`（5 色完美雜湊族）、`checked_dcube_make`／`checked_dcube_extensional_eq`、**`dcube_yoneda_audit_report`**（`O(1)` 泛點 reification 審計） |

---

## 5. DSystem：相容性與修補

宿主可以從任意管分支直接造出 `DSystem`，**因此必須有一個受檢邊界**。

### 5.1 `dsystem_compat.mbt`（2,506 行）
* **判定**：`dsystem_pairwise_compatible`、`dsystem_compatible_with_base`（在 `dim 0` 與組成基底相符）、`dsystem_compatibility_report`（`DSystemIncompatibility` 列出**哪些面衝突**）、`dsystem_checked`（把裸系統提升為受檢物件）。
* **正規形**：`dsystem_first_match_normal_form`（`DTubeNF` / `DTubeNFClass`）、`dsystem_of_first_match_nf`、`dsystem_first_match_system`、`dsystem_first_match_checked`、`dsystem_first_match_eq` —— first-match 語義給出**唯一**代表。
* **修補**：`dsystem_repair_to_base`、`_exact`、`dsystem_repair_with_candidates`、`dsystem_repair_maximum`（最大相容子集）、`dsystem_repair_all_maxima`、`dsystem_repair_all_maxima_dsatur`（DSATUR 著色序求**全部**極大解）。
* **輔助**：`conv_at_under_face(_in)`、`conv_at_under_face_report(_in)`、`tube_paths_conv_under_face(_in)`、`bdd_satisfying_cubes`、`face_of_bdd`、`cubical_face_subcubes`、`face_agreement_region`、`face_agreement_face(_sound)`、`dsatur_color_order`。

### 5.2 `dsystem_sheaf_reify.mbt`（272 行，三個能力邊界突破）
* `[T-Sheaf-Bool-Glue]` `conv_sheaf_glued_boolean_partition`：以互斥 ROBDD 共因子分割做轉換，**繞過 `2^k` 分裂**；
* `[T-Clique-Kernel]` `dsystem_kernelized_max_clique`：以孤立／被支配／單純頂點**核化**求最大團（`KernelizedCliqueReport`）；
* `[T-Generic-Cube-O1]` `reify_natural_dcube_symbolic_o1`：自然 `n`-立方體的 `O(1)` 單泛點 reification（`n = 24` 時免去 `2²⁴ = 16,777,216` 頂點探測）。

---

## 6. Schema 生成器（歸納型、HIT、開放歸納—遞迴）

### 6.1 `schema.mbt`（4,459 行）— 語言本體
```moonbit
pub(all) enum DPositiveFunctor { identity; product; sum; list; pi; container; ... }
pub(all) struct DTelescopeEntry { ... }     // 參數／索引望遠鏡
pub(all) enum DArgKind { ... }              // external / recursive / function
pub(all) struct DConstructorSpec { ... }
pub(all) struct DInductiveSpec { ... }
pub(all) struct DHitSpec { ... }            // 含 DHitFaceExpr / DHitCellSpec
```
參數、索引、嚴格正建構子引數、（HIT 的）帶面表達式胞，全部用一個有限描述寫出；其 **checker／evaluator／conversion／quoting／Kan** 由描述**泛型生成**。
DTVar 索引規則：參數 → 較早的望遠鏡條目 → `DTVar(0)` 為最內層。
內建 schema：`nat_schema`、`bool_schema`、`list_schema`、`vec_schema`、`fin_schema`、`tree_schema`、`w_schema`、`circle_schema`、`torus_schema`、`segment_schema`。
主要生成入口：`eval_inductive_type_term`、`infer_inductive_elim`、`eval_intro_term`、`quote_intro_at`、`conv_intro_at`、`eval_hit_elim`、`hit_cell_value`、`comp_inductive_value`、`comp_hit_value`、`schema_motives_conv`。

### 6.2 其餘七檔的分工

| 檔案 | 解決什麼問題 |
|---|---|
| `schema_positivity.mbt` | **嚴格正性**：以極性 + 嚴格性上下文走型別語法、β-歸約別名（帶 fuel 防無限迴圈）、理解「透過已認證家族」的間接出現。產出可驗的 `DPositivityWitness` 與 `DFunctorialPositivityCert` |
| `schema_functor.mbt` | 嚴格正**函子描述子**、建構子約束、**歸納—遞迴解碼**（`eval_inductive_decode`、`decode_term`、`inductive_decode_cases_validate`） |
| `schema_inductive_recursive.mbt` | **同時**歸納—遞迴（`DSimultaneousIRSpec`）：`eval_simultaneous_ir`、`simultaneous_ir_compile_decode`、`code_schema_for_simultaneous`、`simultaneous_ir_eliminator_type` |
| `schema_open_ir.mbt` | **開放**歸納—遞迴：`DOpenIRArgKind`（external／code／decoded）、`DOpenIRConstructor`、`DOpenIRDecoder`、`open_ir_validate`、`open_ir_lower_single_decoder` |
| `schema_extensions.mbt` | 高階宣告：互歸納族（`compile_mutual_inductive`、`even_odd_family`）、宣告層宇宙方案、商 HIT（`quotient_schema`）、巢狀遞迴、Tarski 宇宙、三維胞（`cube3_schema`） |
| `schema_universe_poly.mbt` | **宇宙多型進入宣告語法**：`DUnivLevel(expr)` 在套用時被替換；`dlevel_inductive_decl` / `dlevel_hit_decl` / `dlevel_term_decl`、`instantiate_level_*`、`dtype_operator_decl` + `extract_positive_functor`、巢狀迭代 `compile_nested_iter_decl`、互宣告正性 `mutual_decl_positivity` |
| `schema_registry.mbt` | 以 **plan** intern 描述子：驗證一次、telescope 在泛值上精緻化一次；後續結構相等註冊直接回傳既有 plan。`schema_registry_register_inductive/hit`、`schema_registry_validate_*`、`telescope_type_values_cached`、`schema_registry_snapshot/restore/merge_into/manifest`（`cubical-store/schema_registry_persist.mbt` 做持久化） |

---

## 7. `ordinal_mahlo.mbt` — 序數與能力邊界（217 行）

* `[D-Cantor-CNF]`：`CantorOrdinal` 的 Cantor 正規形算術 `< ε₀`（`cantor_ord_nat`、`cantor_ord_omega_pow`、`cantor_ord_lt`、`cantor_ord_add`）⇒ 認證超限 `W`-型別的結構下降終止。
* `[T-IdxContainer-Elim]`：`compile_indexed_container_to_positive_functor` 把索引容器 `(I, S, P, next_idx)` 編譯成 `DPositiveFunctor`（含 `DPath` 索引相干）。
* `[Ax-Mahlo-Reflect]`：`verify_mahlo_universe_reflection` 驗歸納—歸納型（inductively-inductive）的 Tarski 反射（`Ctx`／`Ty`）。

---

## 8. 範例

```moonbit
// 1) 由 schema 生成 Nat 型別與其消去子
let nat = @kernel.nat_schema()
let ty  = @kernel.eval_inductive_type_term(nat, env)
let z   = @kernel.eval_intro_term(nat, 0, args)     // zero
let s   = @kernel.eval_intro_term(nat, 1, args)     // succ

// 2) 不可交換系統的相容性與修補
let rep = @kernel.dsystem_compatibility_report(dsys)
if !rep.compatible { let fixed = @kernel.dsystem_repair_maximum(dsys) }

// 3) DAG 大小 vs 樹大小
println(@kernel.dterm_tree_node_count(t))        // 樹
println(@kernel.dterm_distinct_subterm_count(t)) // DAG（共享後）

// 4) ε₀ 以下的序數下降
assert_true(@kernel.cantor_ord_lt(@kernel.cantor_ord_nat(5), @kernel.cantor_ord_omega_pow(1)))
```

---

## 9. 驗證與邊界

```bash
moon test cubical/kernel --target wasm-gc     # 單包微測試實測 0.95s
```
一等檢核：`check_semantic_dimension_substitution()`、`check_kan_dep_all()`、`check_kan_coe_pi_sigma()`、`dsystem_first_match_eq`、`inductive_decode_cases_validate()`、`open_ir_validate()`、`check_level_polymorphic_declarations()`、`check_mutual_declaration_positivity()`。

**禁止事項**：本套件不得匯入 `algebra`、不得引入 `Double`、不得把 `CheckedLine`／`CheckedDCube`／`CheckedSystem`／`SchemaRegistry`／`DClosure`／`DTermInterner` 改成 `pub(all)`。
