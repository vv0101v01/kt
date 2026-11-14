# `cubical/` — 依賴立方可信核心（9 個子套件、76 檔、78,232 行）

> **架構位置**：`architecture.json` 中 `cubical/*` 共 **9 個 MoonBit 套件**（Layer 0–6，合計 76 個 `.mbt`、78,232 行），與根套件 `root`（Layer 7）、`algebra/`、`hostfs/` 同屬 **F1 第一聯邦**（該聯邦 119 檔、110,545 行）。本目錄本身**不含 `moon.pkg`**，是純粹的實體分層容器。
> 上游：`gcd`（Layer 0）；同聯邦另有 `algebra/`、`hostfs/`。
> 執行入口：`cmd/main`（135/135 定理總表）。

---

## 1. 七子套件的無環分層（SCC-Preserving Modularization）

```text
                        root（極薄精選門面 facade.mbt + 定理總表 verify.mbt）
          ┌──────────────────┼────────────────────┐
          ▼                  ▼                    ▼
   cubical/homotopy    cubical/store      cubical/elaborator     ◄── 三者彼此零依賴，正交平行
   (球面/單值性/Kₙ/    (二進位模組/WAL/    (雙向精緻化/Huet HOU/
    BM/Brunerie/HIT)    Ed25519 BFT/MVCC)  高階匹配/Goldfarb)
          └──────────────────┴────────────┬───────┘
                                          ▼
                                   cubical/kernel      ◄── 可信核心（零浮點、零代數耦合、
                              (NbE + Kan + Glue + DSystem     密封不變量、30,899 行)
                               + 歸納/HIT/Open-IR + ε₀/Mahlo)
                          ┌───────────────┴───────────────┐
                          ▼                               ▼
                   cubical/finite                  cubical/hermitian
                (η-NbE / Wiring /                (複矩陣 / 投影 P²=P=P† /
                 有限宇宙 PathP·Glue)              Karoubi / 子空間 Glue / 代數證書)
                          └───────────────┬───────────────┘
                                          ▼
                                  cubical/face_bdd
                   (區間 Dim/Face · ROBDD DAG · Watched CDCL/LRAT · 割寬 #SAT)
                                  @gcd（Layer 0 基底）
```

**三條硬規則**（`agent.v2.md` §三）：

1. **不強拆 SCC**：`NbE 求值 ↔ Kan 填充 ↔ Glue 等價 ↔ 歸納/HIT Schema` 這組互遞迴核心**完整封裝在 `kernel` 一個套件內**，避免跨包解環引入函式指標間接層或被迫 `pub(all)` 破壞封裝。
2. **編譯器級可信核心**：外圍六套件與 `kernel` **零循環依賴**；`kernel` 的不變量載體（`CheckedLine`、`CheckedDCube`、`CheckedSystem`、`SchemaRegistry`、`DClosure`、`DTermInterner`）是唯讀 `pub struct`，外圍**無法繞過檢驗器偽造**。
3. **零編年史命名債**：禁止 `phase*` 檔名；一律按數學結構或職責命名。

---

## 2. 子套件總表

| 子套件 | Layer | 檔案 | 行數 | 依賴 | 一句話 |
|---|---|---:|---:|---|---|
| `face_bdd` | 0 | 5 | 6,209 | — | De Morgan 區間、面公式、ROBDD/BDD-DAG、Watched CDCL（DRUP/DRAT/LRAT）、割寬 `#SAT` |
| `finite` | 1 | 4 | 1,828 | face_bdd | 簡單型別 η-NbE／HOAS、有限 Bool/Unit/積宇宙的 wiring、`ua`、`PathP`、`Glue`、`J` |
| `hermitian` | 2 | 9 | 3,199 | face_bdd, finite, algebra | 複線性代數、Hermitian 投影、向量偏系統、仿射立方體、Karoubi／句法範疇、子空間 Glue、精確代數證書 |
| `kernel` | 2 | 20 | **30,899** | face_bdd, finite | 可信依賴核心：依賴 NbE、AST Kan、Glue 等價、密封 `Checked*`、DSystem 相容、歸納/HIT/Open-IR Schema、Cantor/Mahlo 序數 |
| `elaborator` | 3 | 4 | 5,514 | kernel | 雙向表面精緻化、擴展 pattern 高階合一、Huet 延遲 flex-flex 串流、可判定高階匹配、Goldfarb 丟番圖 |
| `homotopy` | 3 | 14 | 12,281 | gcd, algebra, face_bdd, finite, kernel | 球面 `S¹/S²/S³`、伴隨等價、截斷、Stasheff `Kₙ`、Blakers–Massey、Brunerie `π₄(S³)=ℤ/2ℤ`、通用 HIT |
| `store` | 5 | 9 | 11,147 | condensed, face_bdd, kernel | 分離模組編譯、二進位編解碼、認證 WAL 工件庫、Ed25519 BFT 法定人數、Tarjan SCC MVCC 熱載入 |
| `autonomy` | 5 | 5 | 2,645 | gcd, face_bdd, kernel, elaborator, homotopy, symlib, topos, accel | 構造性泛代數自主類型論（Mal'cev 同餘／商代數／零元二分）、仿射與雙德摩根立方、Moore 自由路徑、退化樹與 5D 交錯邊界、雙向範式修剪、Kripke–亞歷山德羅夫有效性與雙重否定核預層黏合 |
| `structures` | 6 | 6 | 4,374 | gcd, face_bdd, kernel, elaborator, homotopy, autonomy, symlib, topos, accel | 全體 54 項高階立方結構（Swan 嚴格 `Id`、自由路徑纖維化、65,536 立方體 Eilenberg–Zilber 分裂、仿射雙向與 `LJF` 聚焦、多項式米田與 SIP、`S₃` 覆蓋伽羅瓦對應、`RP²` 二階撓率、動機重構、擬陣修補、內部反射）及 26×14 交互圖譜 |

---

## 3. `cubical/face_bdd/`（Layer 0，6,209 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `interval.mbt` | 241 | `Dim`（De Morgan 區間：`0/1/變數/¬/∧/∨`）與 `Face`（共纖維化公式 `(r=0)`、`(r=1)`、`∧`、`∨`）；`eval_dim`、`face_holds`、`face_sat`、`face_le`、`face_eq_mod`、`interval_laws_hold` |
| `bdd.mbt` | 429 | 樹狀（非共享）ROBDD：`bdd_of_face`、`bdd_not/and/or`、`bdd_sat_face`、`bdd_face_le/eq`、`face_witness`、`dim_simplify`／`face_simplify`（化簡與替換）、`check_bdd_canonical` |
| `bdd_dag.mbt` | 2,495 | **可擴展主表示** `BddManager`：`(rank, low, high)` 節點在雜湊表中 intern，Boolean `apply` 記憶化 ⇒ **兩個面相等 ⟺ 同一個 manager 中根節點 ID 相等**。含 `bdd_dag_restrict/exists/forall`、`bdd_dag_dnf_face`、`bdd_dag_sat_count`、變數序候選與最佳/DP/剪枝/分解多種建構、`face_eq_within_budget`、`face_sat_dpll` |
| `face_sat_watched.mbt` | 2,832 | Watched-literal DPLL：面 + 原子內的維度式 = 一個布林公式，先用 Tseitin 擴展變數轉 CNF，再用 watched literals + saved phase + 衝突驅動變數活性搜索。含 **CDCL 報告與證明**：`face_sat_cdcl_proof`、`face_cdcl_proof_check`、`face_cdcl_drup_check`、`face_cdcl_drat_check`、`face_cdcl_drup_trim`、`face_cdcl_lrat_check`、`face_cdcl_elaborate_lrat`、`face_lrat_to_binary`／`face_lrat_from_binary` |
| `bdd_cutwidth.mbt` | 212 | `[T-Frontier-ROBDD]` 有界樹寬前沿 ROBDD：以割寬/BFS 前沿變數序處理連通 `chain22..26`（`n = 22..26`），模型數恰為 `2ⁿ − F_{n+2}`（Fibonacci 補集） |

**為什麼需要兩套決策：**ROBDD 給出**規範形**（等價判定 `O(1)`），CDCL 給出**證明**（DRUP/DRAT/LRAT 可被獨立檢查器複驗）。兩者互補：`kernel` 平時走 BDD，需要「為什麼不可滿足」時走 CDCL 取證。

---

## 4. `cubical/finite/`（Layer 1，1,828 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `nbe.mbt` | 350 | 簡單型別 NbE：`Term`/`Neutral`/`Value`/`HTm`；`eval`、`quote`、`quote_neutral`、`nf`、`def_eq`；`coe_rules_definitional`；HOAS 往返 `term_to_hoas`／`hoas_to_term`（`hoas_roundtrip_*`）；`nbe_single_valued` |
| `nbe_eta.mbt` | 472 | **η-long**：`η` 是型別引導的 —— 函數 `f ≡η λx. f x`、積 `p ≡η (fst p, snd p)`、Unit 所有居民皆典範 ⇒ `quote` 必須在每個子項（含中性脊）知道型別。`ty_infer`／`ty_check`、`quote_eta`、`nf_eta`、`def_eq_eta`、`eta_single_valued_on`、`check_eta_{function,product,unit,spine,all}` |
| `wiring.mbt` | 390 | 有限等價的**符號形式**：`Wiring`（每個輸出葉 = 某輸入葉 + 可選否定；Unit 輸出用 `−1`）。`wiring_id/not/swap/prod/comp/inv/assoc/left_unitor/right_unitor`、`wiring_wf`、`wiring_apply`、`check_wiring_category`（範疇公理）、`check_wiring_coherence` |
| `pathp_glue.mbt` | 616 | 有限宇宙（`Bool`／`Unit`／積）裡的 **`ua`、`coe`、`PathP`、`Glue`、`J`**：`Iso → Equiv → ua → Path U A B`，`coe_computes` 驗「沿 `ua` 搬運會計算」；`pathp_prod_exchange_roundtrip`、`disc_path_sym`、`j_roundtrip`、`glue_wf`／`make_glue`／`unglue`／`glue_sound` |

有限性是特徵而非限制：等價可以在**全部**元素上驗證，因此這裡的定理是被**判定**的，不是被抽樣的。

---

## 5. `cubical/hermitian/`（Layer 2，3,199 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `complex.mbt` | 300 | 複數／向量／方陣 `Complex`/`CVec`/`CMat`；`cx_approx_eq`、`inner`、`mat_adjoint`、`is_hermitian`、`is_idempotent`、`is_projector`、`mat_commutes` |
| `projector.mbt` | 174 | `P² = P`、`P† = P` ⇒ `ℂⁿ = im(P) ⊕ ker(P)` **正交**直和 ⇒ `im(P)` 是 `λ=1`、`ker(P)` 是 `λ=0` ⇒ 唯一分解 `v = Pv + (I−P)v`、`⟨Pv,(I−P)v⟩ = 0`；`projector_from_orthonormal`、`decompose`、`commuting_projectors_compatible`、`pruning_is_retraction` |
| `cube.mbt` | 326 | 語義 `n`-立方體 `Iⁿ → ℂᵐ` 與 Kan 合成（retraction 版）：`restrict_face`、`open_box_wf`、`square_fill`、`filler_respects_box`、`kan_comp_path`、`path_trans`、`prune_cube`、`kan_fill_eigenspace`、`eigenspace_kan_sound`、`pruning_repairs_filler` |
| `system.mbt` | 182 | 系統（偏元素）`[φ₁↦a₁,…,φₖ↦aₖ]`：相容性（重疊處值相同）、`system_eq_mod`（面商）、`prune_system`、`system_union`、`compatibility_respects_quotient` |
| `system_symbolic.mbt` | 103 | 系統的**符號正規形**：first-match 語義 ⇒ 有效區 `effᵢ = φᵢ ∧ ¬(φ₁∨…∨φᵢ₋₁)`（用 BDD 算）；按值分組 + 字典序排序 ⇒ 商類的**典範代表** `SystemNF`；`system_eq_mod_sym` |
| `glue_comp.mbt` | 587 | 一般 **Glue 合成 `comp`**，兩個模型：(1) 有限宇宙端點演算法（`GlueLineFinite`、`glue_line_coherent`、`glue_comp_finite`）；(2) 向量模型（`GlueLineVec`、`fill_subline`、`map_cube_equiv_line`、`glue_comp_vec`）；`check_glue_comp_all` |
| `certified_numeric.mbt` | 856 | `QuadC`（二次代數標量）上的**認證數值層**：`CertVec`/`CertMat`/`ProjectorCertificate`/`CertPath`/`CertSquare`；`certify_projector`、`cert_in_image`、`cert_in_kernel`、`cert_filler_respects_box`、`cert_eigenspace_kan_sound`、`cert_pruning_repairs_filler`、`certify_numeric_projector`、`double_dyadic_interval` |
| `certified_algebraic.mbt` | 381 | 解除上一檔的兩項限制：標量改為 `AlgC`（實虛部同屬一個代數擴張 `ℚ[X]/(m)`），立方體改為任意次多項式 ⇒ `alg_cert_is_projector`、`alg_cert_path_in_image`、`alg_cert_square_in_image`、`cube_root_two_modulus`（以 `∛2` 為例） |
| `categories.mbt` | 290 | 讓「每個結構都是某個範疇的影子」可執行：**Karoubi 包絡**（物件 = Hermitian 冪等 `P`，態射 `A` 滿足 `QAP = A`）、面的 meet/join 泛性質（面偏序範疇）、退化立方體的範疇恆等式、句法範疇；`check_categories_all` |

---

## 6. `cubical/kernel/`（Layer 2，20 檔，30,899 行）— 可信核心

### 6.1 語法與語義基礎

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `dterm_transform.mbt` | 445 | `DTerm` 的結構操作：`dterm_shift`、`dterm_substitute`、`dterm_children`、`dterm_map_vars_at`、`dterm_dim_vars`、`d_nat_lit`/`dv_nat_lit` |
| `dterm_intern.mbt` | 616 | **雜湊 consing**：`dterm_rebuild` 是 `dterm_children` 的**精確逆**；`DTermInternTable` 自底向上 intern，節點以「本地 stamp（以子節點 id 取代後的快取鍵）」為鍵；`dterm_dag_snapshot`／`dterm_dag_import`、`dterm_tree_node_count` vs `dterm_distinct_subterm_count` |
| `nbe_dep.mbt` | **4,555** | 依賴 NbE 本體：`DValue`／`DNeutral`／`DThunk`（惰性）／`DEnv`／`DDimEnv`；`DSystem`/`DSystemNF`（第一匹配正規形）；`DInfer`/`DTypeVal` 的型別推導；`eval_*`／`infer_*`／`quote_*`／`conv_*` 四大族；`face_eval_env`、`dim_quote`、`fresh_dim`、`memo_dim_line` |
| `checked_line.mbt` | 286 | **可替換語義型別線**：裸線是 `Dim → DValue`（可能不尊重維度替換）；`DCheckedTypeLine` 存 `DTerm` 本體 + 持久環境，在**一個新維度綁定子**下檢型 ⇒ `checked_line_at`、`checked_line_fn`、`checked_line_quote_body`、`checked_coe_value`、`dvalue_subst_dims`、`check_semantic_dimension_substitution` |
| `conv_case_split.mbt` | 785 | **離散（Bool）情境的個案分裂轉換**：`if x then 0 else 0` 與 `0` 對中性 `x` **不可轉換**（語義比較是結構的），但 Bool 是離散型別 ⇒ 在 `x = true/false` 兩支都成立時才判定相等。`conv_terms_case_split`、`conv_difference_variables`、`cs_finite_closed_inhabitants`、`conv_terms_finite_case_split_report` |

### 6.2 Kan 運算

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `kan_dep.mbt` | 625 | 型別導向 Kan 結構的抽象 `DLine`：`at(i)` 型別、`coe(r,s,v)` 異質搬運、`fill(tube,base)` 填充。`dline_at/bool/unit/univ/pi/sigma/constfam/from_maps/rev/subst`；`dcoe`、`dfill`、`dcomp`；`check_kan_coe_pi_sigma`、`check_kan_coe_dependent`、`check_kan_comp_tube`、`check_dline_dimension_substitution` |
| `kan_ast.mbt` | 1,838 | `DCoe`/`DComp`/`DHComp`/`DHFill` 的**計算內容**：`coe_value`、`comp_value`、`hcomp_value`、`fill_value`、`hfill_value`，並對每個型別形成子分派 `comp_pi_value`、`comp_sigma_value`、`comp_path_value`、`comp_univ_value`、`comp_glue_value`、`comp_bool_value`、`comp_nat_value`、`comp_list_value`、`comp_circle_value`、`comp_torus_value`；另含 `circle_path_winding_int`、`circle_square_glued_cap`、`torus_square_glued_cap` |
| `equiv_ast.mbt` | 1,271 | **一階等價**：`DVEquiv`（兩型別 + 兩函數 + section/retraction 路徑函數）、`DVGlueEquiv`（原始語義 Glue 型別，分支直接帶等價，合成用 `equivFun`/`equivInv`）；`equiv_make_value`、`ua_type_at`、`ua_line_value`、`as_glue_equiv`、`comp_glue_equiv_value`、`infer_equiv_*`／`eval_ua_term`、`d_check_glue_equiv_partial`、`glue_equiv_systems_conv` |
| `dcube_filler.mbt` | 1,350 | `n` 維開盒與**組裝填充**：`DCubeFunction`（外延式，一軸一個維度式）、`DCubeBoxFace`、`DCubeOpenBox`；`dcube_box_fill`（沿最後一軸做單一齊性合成）、`dcube_filler_faces_ok`、`dcube_box_fill_verified`；進階：`dcube_cubes_conv_stratified`（分層）、`dcube_cubes_conv_covering`（覆蓋）、`dcube_phf_5colors`（5 色完美雜湊族）、`checked_dcube_make`、**`dcube_yoneda_audit_report`**（`O(1)` 泛點 reification 的審計） |

### 6.3 DSystem 相容與修補

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `dsystem_compat.mbt` | 2,506 | 宿主可直接以任意管分支造出 `DSystem`，故需「檢查邊界」：`dsystem_pairwise_compatible`、`dsystem_compatible_with_base`、`dsystem_compatibility_report`、`dsystem_checked`；**第一匹配正規形** `dsystem_first_match_normal_form`／`dsystem_of_first_match_nf`／`dsystem_first_match_eq`；**修補**：`dsystem_repair_to_base`、`dsystem_repair_to_base_exact`、`dsystem_repair_with_candidates`、`dsystem_repair_maximum`、`dsystem_repair_all_maxima`、`dsystem_repair_all_maxima_dsatur`（DSATUR 著色序）；`conv_at_under_face_report`、`tube_paths_conv_under_face`、`bdd_satisfying_cubes`、`face_agreement_face` |
| `dsystem_sheaf_reify.mbt` | 272 | `[T-Sheaf-Bool-Glue]` 以互斥 ROBDD 共因子分割做轉換（繞過 `2^k` 分裂）；`[T-Clique-Kernel]` 以孤立／被支配／單純頂點核化求 `DSystem` 最大團；`[T-Generic-Cube-O1]` 自然 `n`-立方體的 `O(1)` 單泛點 reification（`n = 24` 免去 `2²⁴ = 16,777,216` 頂點探測） |

### 6.4 歸納型、HIT 與 Schema 生成器

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `schema.mbt` | **4,459** | Schema 語言本體：`DPositiveFunctor`（identity/product/sum/list/pi/container）、`DTelescopeEntry`、`DConstructorArg`（external／recursive／function）、`DConstructorSpec`、`DInductiveSpec`、`DHitFaceExpr`/`DHitCellSpec`/`DHitSpec`；**泛型生成** checker/evaluator/conversion/quoting/Kan（`eval_inductive_type_term`、`infer_inductive_elim`、`quote_hit_cell_at`、`comp_inductive_value`、`comp_hit_value`…）；內建 `nat_schema`/`bool_schema`/`list_schema`/`vec_schema`/`fin_schema`/`tree_schema`/`w_schema`/`circle_schema`/`torus_schema`/`segment_schema` |
| `schema_positivity.mbt` | 2,033 | 以**極性 + 嚴格性上下文**走型別語法，β-歸約別名（帶 fuel，避免壞型的自我應用造成無限迴圈），並理解「間接出現」——透過已認證為正的既有家族。`dterm_family_strictly_positive`、`inductive_parameter_positivity`、`dpositivity_witness`／`_verify`、`dfunctorial_positivity_verify` |
| `schema_functor.mbt` | 2,623 | 嚴格正函子描述子 + 建構子約束 + **歸納—遞迴解碼**：`positive_functor_type`／`_ih_type`／`_map`、`schema_arg_type_full`、`schema_constraints_hold`／`_pi`、`eval_inductive_decode`／`decode_term`、`inductive_decode_cases_validate` |
| `schema_inductive_recursive.mbt` | 2,045 | **同時歸納—遞迴**（`DSimultaneousIRSpec`、`DSimultaneousFunction`）：`eval_simultaneous_ir`、`simultaneous_ir_compile_decode`、`code_schema_for_simultaneous`、`code_interpretation_ir`、`simultaneous_ir_eliminator_type`、`nat_parity_double_ir` 等實例 |
| `schema_open_ir.mbt` | 1,844 | **開放歸納—遞迴**：`DOpenIRArgKind`（external／code／decoded）、`DOpenIRConstructor`、`DOpenIRDecoder`、`DOpenIRCode`；`open_ir_validate`、`open_ir_eval_decode`、`open_ir_lower_single_decoder`、`simultaneous_ir_compile_joint` |
| `schema_extensions.mbt` | 728 | 由核心生成器拼出高階宣告：互歸納族（`compile_mutual_inductive`、`even_odd_family`、`tree_forest_family`）、宣告層宇宙方案（`dinductive_level_scheme`、`dhit_level_scheme`）、商 HIT（`quotient_schema`）、巢狀遞迴、Tarski 宇宙（`tarski_universe_schema`）、三維胞（`cube3_schema`） |
| `schema_universe_poly.mbt` | 1,816 | **宇宙多型成為宣告語法**：`DUnivLevel(expr)` 節點在套用宣告時被替換；`dlevel_inductive_decl`／`dlevel_hit_decl`／`dlevel_term_decl`、`instantiate_level_*`、`dtype_operator_decl` + `extract_positive_functor`、巢狀迭代 `dnested_iter_decl`／`compile_nested_iter_decl`（`bush_decl`）、互宣告正性 `mutual_decl_positivity` |
| `schema_registry.mbt` | 585 | 以 **plan** 形式 intern 描述子：驗證一次、telescope 在泛值上精緻化一次，之後結構相等的註冊直接回傳既有 plan；具體 telescope 精緻化以語義快取。`schema_registry_register_inductive/hit`、`schema_registry_validate_*`、`telescope_type_values_cached`、`schema_registry_snapshot`/`restore`/`merge_into`/`manifest` |

### 6.5 序數與能力邊界（`ordinal_mahlo.mbt`，217 行）

* `[D-Cantor-CNF]`：`CantorOrdinal` 的 Cantor 正規形序數算術 `< ε₀` —— `cantor_ord_nat`、`cantor_ord_omega_pow`、`cantor_ord_lt`、`cantor_ord_add`，認證超限 `W`-型別的結構下降；
* `[T-IdxContainer-Elim]`：`compile_indexed_container_to_positive_functor` 把索引容器 `(I,S,P,next_idx)` 編譯成 `DPositiveFunctor`（含 `DPath` 索引相干）；
* `[Ax-Mahlo-Reflect]`：`verify_mahlo_universe_reflection` 驗歸納—歸納型（inductively-inductive）的 Tarski 反射（`Ctx`/`Ty`）。

---

## 7. `cubical/elaborator/`（Layer 3，5,514 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `elaborator_bidir.mbt` | 2,158 | 雙向精緻化：表面項 `UTerm`（帶 `UMetaInfo`）→ 核心 `STerm`/`DTerm`；`elab_check`／`elab_infer`／`elab_result_to_dterm`；`Unifier` + `uterm_whnf`；`hou_unify`／`hou_unify_mgu`（Miller pattern 片段）；`hou_semantic_optimize`、`uterm_contains_unsolved_meta` |
| `hou_match.mbt` | 597 | **可判定的那一側**：`HouMatchResult`；`hou_conv`、`hou_match`、`hou_match_solved_within` —— 高階**匹配**（只有一邊有元變數）可判定，故與合一（不可判定，Goldfarb 1981）分開實作 |
| `hou_unify_stream.mbt` | 2,514 | 有界 **Huet 搜索**：`hou_search_unify`／`_bool`／`_iterative`、`hou_solve_constraints`、`hou_unify_residual`、`hou_enumerate_unifiers`、`hou_solve_constraints_backtracking`；延遲 **flex-flex**：`HouDelayedSolveStatus`、`hou_reify_delayed_flex_flex`、`hou_solve_with_delayed_flex_flex`、`HouDelayedGraphReport`；惰性列舉器 `hou_unifier_stream_new`／`_next`／`_is_exhausted`／`_nodes` |
| `hou_goldfarb.mbt` | 245 | `[T-HOU-InnerLam]` 內層 `λ` 的高階匹配；`[T-Goldfarb-Diophantine]` 把 Goldfarb 的不可判定性歸約**編譯成丟番圖問題**並驗證（`goldfarb_church_unary`、`goldfarb_church_iterator`、`goldfarb_verify_diophantine_encoding`）—— 把「這裡是理論邊界」變成可執行證據，而不是一句註解 |

---

## 8. `cubical/homotopy/`（Layer 3，12,281 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `cubical_algorithms.mbt` | 1,944 | Kan 盒與基本同倫代數：`transport_value`、`kan_box_fill`／`kan_box_comp`、`dpath_*`（`refl/sym/trans/cong/funext`）、`subst_*`、`dfunext_term`；**高階相干**：`dpath_eckmann_hilton3_value`、`dpath_pentagon4_value`（Mac Lane 五邊形）、`dpath_associahedron_k5_cell5_value` |
| `adjoint_equivalence.mbt` | 993 | **伴隨等價**（比擬逆多一個三角相干 `τ`）：`equiv_triangle_type`、`equiv_with_improved_sect`、`adjoint_equiv_type_term`、`is_contr_type_term`、`fiber_type_term`、`contractible_fibers_type_term`、`adjointify_equiv_value`、`check_general_adjointification_and_contractible_fibers` |
| `univalence.mbt` | 778 | **計算性單值性**，兩層：(1) 有限宇宙（wiring 表示，`upath_to_equiv`／`finite_transport` 符號決定，不枚舉立方體）；(2) 依賴核心（`path_to_equiv_value`、`equiv_to_universe_path_value`、`ua_transport_value`、`ua_beta_path_value`、`univalence_equiv_value`、`universe_path_normal_form`） |
| `sphere3.mbt` | 211 | 以迭代懸垂造球：`suspension_schema`、`sphere2_schema`、`sphere3_schema`、`sphere3_{north,south,meridian}_{term,value}` |
| `sphere_classification.mbt` | 827 | 內建整數型別、商呈現的同倫群、**典範球面環路代表**：`integer_schema`、`homotopy_group_type_term`、`sphere_loop_power_value`、`sphere_loop_canonical_expr`／`_normal_form`／`_same_class` |
| `sphere_homotopy.mbt` | 2,470 | 三類資料刻意分離（核心代表／顯式等價資料／數值見證）：`circle_degree_value`、`suspension_map_value`、`sphere_degree_value`、`hopf_map_s3_to_s2`、`hopf_linking_number_numeric`、`hopf_map_rat`（**精確有理**版）、`susp_bool_equiv_circle_value`、`loop_suspension_adjunction_equiv_value`、`freudenthal_*`、`pi2_s2_hopf_hom_value` |
| `circle_classify.mbt` | 1,558 | 圓周 HIT 的 **encode/decode**：泛覆蓋（螺旋）由圓周歸納內部定義（`base` 上的纖維 = 整數，`loop` 上的纖維 = 後繼等價的 `ua` 線）⇒ `circle_encode_value`／`circle_decode_value`、`circle_encode_decode_sect_value`、`circle_decode_encode_retr_value`、`pi1_set_circle_equiv_integer_value`、`integer_is_set_value` |
| `truncation.mbt` | 598 | **命題截斷**由「參數面」`dhit_arg_face` 生成：`‖A‖ ::= point(a) | squash(x y : ‖A‖) : x ⇝ y`；`prop_trunc_*`；集合截斷 `set_trunc_*`（`set_trunc_hub_value`、`set_trunc_loop_trivial_value`、`set_trunc_is_set_value`、`set_trunc_equiv_of_equiv_set_value`） |
| `homotopy_universal.mbt` | 557 | 邊界 #6 缺少的型別形成子：**join**、**wedge**、**`n`-截斷**、**James 構造**，都宣告成真正的立方 HIT 並附遞歸原則：`join_push_value`、`trunc_inc_value`、`homotopy_universal_remaining` |
| `associahedron.mbt` | 640 | **任意 `n` 的 Stasheff 結合多面體 `Kₙ`**：`Paren`（括號化）、`paren_all`、`paren_rotations`（翻轉圖）、`stree_all`、`assoc_fvector`、`assoc_two_faces`、`catalan`、`assoc_euler_characteristic`；Mac Lane 相干定理保證不需無限塔，逐 `n` 建構即可 |
| `coherence_angle_elimination.mbt` | 288 | 指定有限胞腔／Kan 模型的局部相干角消元：逐項列舉 `11040`，兩段商至 `552` 再到未解角 `0`，以 `276` 個規範類保存總重數，附錯配負對照 |
| `higher_coherence_k6.mbt` | 452 | 非交換「8 字形」`S¹∨S¹`（`π₁ = F₂ = ⟨a,b⟩`）的**方形邊界填充**：以 `@gcd.ugcd_free_group_reduce` 判 `top⁻¹·left·bottom·right⁻¹ = 1` **於 `F₂` 中**，而非只看阿貝爾化 `H₁ = ℤ²` 的繞數 `(0,0)`；另附指涉六項突破的證書（`[T-Singleton-N]`、`[T-Associahedron-K6]`、`[T-VarEndpoint-HIT]`、`[T-Adams-Brunerie-Bridge]`、`[T-HOU-InnerLam]`、`[T-Goldfarb-Diophantine]`、`[T-BFT-Ed25519-WAL]`、`[T-Tarjan-MVCC-HotLoad]`） |
| `blakers_massey.mbt` | 514 | `FgAb`（自由阿貝爾群帶撓及不變因子整除判準 `fg_rank_le`）、`les_middle_is_{injective,surjective,iso}`、`bm_gap`（連通度缺口）、`gap_equiv_below`、`freudenthal_status`、`pi3_s2_iso_pi3_s3`、`pi3_s3_iso_pi2_s2` |
| `brunerie_pi4_s3.mbt` | 423 | **Brunerie `π₄(S³) ≅ ℤ/2ℤ`**：`join_sphere_dim`、`s3_is_join_of_two_circles`、`whitehead_degree`、`james_cells`、`brunerie_original`／`brunerie_new_family`、`brunerie_family_decreasing`、`cyclic_of_beta`、`pi4_s3_group`、`pi4_s3_origins` |

> **誠實邊界**：`blakers_massey.mbt` 與 `brunerie_pi4_s3.mbt` 的檔頭都明說「這是**移植成本**而非未知」（引 HoTT-Agda arXiv:1605.03227、Ljungström–Mörtberg LICS'23 arXiv:2302.00151），並以 `*_origins` 函式標記每個成分的來源（自證 vs 引用）。這種「標記誠實度」是全倉的寫作規範。

---

## 9. `cubical/store/`（Layer 5，11,147 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `module_system.mbt` | 1,152 | 模組系統：`ModuleRename`/`ModuleImport`/`ModuleDecl`/`ModuleDef`/`ModuleEnv`/`ModuleSignature`/`ModuleInstance`；`module_validate`、`module_resolve`、`module_instantiate`、`module_instance_find` |
| `module_compilation.mbt` | 1,101 | **分離編譯與連結**：`CompiledModule`（含扁平化 telescope 條目 + `interface_hash` + `implementation_hash`）；`module_compile`、`compiled_module_to_module_def`（無需原始 import 即可作 import 目標）、`module_link_signature`／`module_link_instantiate`、`module_compile_cache_*`、`module_topological_plan`、`module_build_dag_incremental` |
| `module_binary.mbt` | 3,468 | **穩定磁碟格式 `CHMODBIN`**：魔數 0..8、`u16` 版本、`u16` flags；`compiled_module_to_binary`／`_v1`／`_for_peer`、`compiled_module_migrate_binary`、`compiled_module_load_binary_report`、hex 往返、`CompiledModuleStore`、`SharedDagBundle`、`ModuleTlvSection`、`CompiledModuleEnvelope` |
| `module_hotload.mbt` | 748 | **執行期熱載入**：以 `interface_hash` + `implementation_hash` + `ModuleDependencyFingerprint` 決定；`hot_load_plan`（哪些模組過期）、`hot_load_apply`、`hot_load_instantiate`、`hot_load_dependents`、`hot_load_consistent`、`hot_load_stale_modules` |
| `module_bft_mvcc.mbt` | 279 | `[T-BFT-Ed25519-WAL]` + `[T-Tarjan-MVCC-HotLoad]`：`bft_ed25519_quorum_commit_to_wal`（RFC 8032 簽章的法定人數提交寫入 WAL）、`hot_load_tarjan_scc`（強連通分量批次原子替換）、`hot_load_mvcc_read`／`hot_load_mvcc_commit_atomic` |
| `schema_registry_persist.mbt` | 373 | `CHREGBIN` 格式：registry snapshot 用與模組相同的全量二進位編碼；版本政策、`schema_registry_snapshot_to_binary_for_peer`、`schema_registry_binary_roundtrip_ok` |
| `dterm_dag_binary.mbt` | 646 | `CHDAGBIN`：in-process `DTerm` intern DAG 的持久二進位（含增量 delta：`dterm_dag_delta_compute`／`_apply`／`_validate`、`dterm_intern_table_prefix_digest`） |
| `artifact_crypto_wal.mbt` | 1,258 | **FIPS 180-4 SHA-256/512**（純實作）+ **RFC 8032 Ed25519**（GF(2²⁵⁵−19)、完整擴展扭曲 Edwards `(X:Y:Z:T)`）+ `CHARTSIG` v1 工件簽章 + **崩潰一致 WAL**：`artifact_wal_begin_tx`／`put`／`delete`／`commit_tx`／`abort_tx`／`checkpoint`／`recover` |
| `artifact_repository.mbt` | 2,122 | 抽象位元組儲存上的**耐久工件庫**：`ArtifactRecord`、內容雜湊鏈 `ArtifactChainEntry`、`artifact_repository_put/get/list/remove/recover/verify_all`、CAS 狀態、增量同步 `artifact_repository_sync_incremental`、三方合併 `artifact_repository_merge_three_way`（`ArtifactMergePolicy`） |

**設計要點**：所有格式都自檢（magic + 版本 + 長度校驗），且版本政策函式（`*_version_policy`、`binary_negotiate_version`、`*_for_peer`）使「舊版可讀、新版可寫、對等方可協商」成為程式碼而非約定。

---

## 10. 根套件 `root`（Layer 6，18 檔 12,393 行）

不在本目錄內，但由 `cubical` 的七個子套件餵養：

* `facade.mbt`（20 KB）：**極薄精選門面**，只用 `pub using` 重導出跨聯邦 `@bridge` 與執行檔實際使用的符號；`pkg.generated.mbti` 由重構前 4,300+ 行精簡 ~90% 至 484 行。本次另精選導出 Hopf／Tamari 與相干角消元報告，供四族旋轉橋直接呼叫上游實作。
* `verify.mbt`（40 KB）：定理／定律總表，`print_report()` 逐條印 PASS/FAIL，`cmd/main` 的 `guard` 靠它決定 exit code（**129/129**）。
* `spec.mbt`（148 KB）：規格與主體宣告。
* 其餘 `*_laws.mbt`（`ast_laws`、`bdd_cdcl_dcube_laws`、`descent_drup_dag_laws`、`ed25519_k5_merge_laws`、`hopf_drat_cas_laws`、`lrat_yoneda_freudenthal_laws`、`mahlo_k6_bft_laws`、`positivity_ir_codec_laws`、`registry_persist_laws`、`schema_*_laws`、`semantic_system_laws`、`equiv_laws`、`dsystem_compat_laws`、`bdd_certified_laws`）：把子套件的不變量在**聯邦層**再核一次。

---

## 11. 四波段重構完成紀錄（`agent.v2.md` §3.3）

| Wave | 內容 | 實測單包微測試 |
|---|---|---|
| **1** | 全倉 `*phase*` 檔名 100% 清零；巨檔精準拆解；純 `Dim`/`Face` 語義謂詞下沉 | — |
| **2** | 自底向上抽離無環三包 `face_bdd`／`finite`／`hermitian` | `0.38s` / `0.22s` / `0.57s` |
| **3** | 抽離 30.9k 行可信核心 `kernel`（零浮點、零代數依賴，編譯器密封核心不變量） | `0.95s` |
| **4** | 平行抽離彼此零耦合的 `elaborator`／`homotopy`／`store`；`root` 收斂為精選門面 + 定理總表 | `0.35s` / `0.38s` / `0.58s`；root 由 `11.05s` → **`0.63s`** |

---

## 12. 驗證

```bash
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py

# 單包即時微測試（1 秒內；測完即刪，見 agent.v2.md §1.2）
moon test cubical/face_bdd   --target wasm-gc
moon test cubical/kernel     --target wasm-gc
moon test cubical/homotopy   --target wasm-gc

# 里程碑端到端
moon run --release cmd/main --target wasm-gc      # 129/129 定理總表
moon run --release cmd/showcase --target wasm-gc  # 47/47 證書
```
