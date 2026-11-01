# cubical-hermitian 規格附錄（逐符號登記）

[English appendix](SPEC-APPENDIX.en.md) · [中文規格正本](SPEC.md) · [English specification](SPEC.en.md)

> 本檔案由 `tools/audit_spec.py --write` 自各套件的 `pkg.generated.mbti`
> （`moon info`）生成，**勿手改**附錄標記之間的內容。套件欄是
> `architecture.json` 登記的 MoonBit 套件。

<!-- APPENDIX:BEGIN -->
共 **7303** 個公共符號（宣告＋構造子＋欄位），分屬 101 個規格族；按套件：`algebra` 992、`bridge` 223、`cmd-semiringreport` 42、`condensed` 211、`conjecture` 78、`gcd` 86、`hostfs` 78、`root` 3510、`scheme` 299、`semiring-algebra` 287、`semiring-app` 21、`semiring-bp` 20、`semiring-cat` 30、`semiring-graph` 39、`semiring-io` 9、`semiring-matrix` 60、`semiring-monoid` 85、`semiring-nf` 41、`semiring-par` 17、`semiring-par-host` 4、`semiring-ratelimit` 64、`semiring-sim` 42、`semiring-spline` 15、`semiring-trop` 84、`symlib` 519、`tensor` 103、`topos` 344。

### 複數標量

- 規範形式：(re, im) 有序對
- 範疇化：交換環 C；共軛為對合
- 判定：eps 分量比較

| 符號 | 套件 | 類別 |
|---|---|---|
| `Complex` | root | 結構 |
| `Complex.im` | root | 欄位 |
| `Complex.re` | root | 欄位 |
| `Complex::equal` | root | 函數 |
| `Complex::not_equal` | root | 函數 |
| `Complex::to_repr` | root | 函數 |
| `cx` | root | 函數 |
| `cx_add` | root | 函數 |
| `cx_approx_eq` | root | 函數 |
| `cx_conj` | root | 函數 |
| `cx_mul` | root | 函數 |
| `cx_real` | root | 函數 |
| `cx_scale` | root | 函數 |
| `cx_sub` | root | 函數 |
| `cx_zero` | root | 函數 |
| `eps` | root | 常量 |

### 複向量與內積

- 規範形式：分量列
- 範疇化：Hilbert 空間 Hilb 的物件；內積誘導對偶
- 判定：分量運算

| 符號 | 套件 | 類別 |
|---|---|---|
| `CVec` | root | 型別別名 |
| `inner` | root | 函數 |
| `vec_add` | root | 函數 |
| `vec_approx_eq` | root | 函數 |
| `vec_norm2` | root | 函數 |
| `vec_orthogonal` | root | 函數 |
| `vec_scale` | root | 函數 |
| `vec_scale_c` | root | 函數 |
| `vec_sub` | root | 函數 |
| `vec_zero` | root | 函數 |

### 矩陣與伴隨

- 規範形式：列之列
- 範疇化：Hilb 態射；† 為 dagger 函子
- 判定：矩陣運算

| 符號 | 套件 | 類別 |
|---|---|---|
| `CMat` | root | 結構 |
| `CMat.n` | root | 欄位 |
| `CMat.rows` | root | 欄位 |
| `mat_add` | root | 函數 |
| `mat_adjoint` | root | 函數 |
| `mat_approx_eq` | root | 函數 |
| `mat_commutes` | root | 函數 |
| `mat_from_rows` | root | 函數 |
| `mat_get` | root | 函數 |
| `mat_identity` | root | 函數 |
| `mat_mul` | root | 函數 |
| `mat_sub` | root | 函數 |
| `mat_trace_re` | root | 函數 |
| `mat_vec` | root | 函數 |
| `mat_zero` | root | 函數 |

### 投影與特徵空間

- 規範形式：Σ vₖvₖ†；分解為正交對 (Pv,(I−P)v)
- 範疇化：自伴冪等態射及其在 Hilb 中的分裂（雙積）
- 判定：特徵值方程／正交性／跡整數性

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_commuting` | root | 函數 |
| `check_eigenspace` | root | 函數 |
| `check_orthogonal_roundtrip` | root | 函數 |
| `check_projector` | root | 函數 |
| `commuting_product` | root | 函數 |
| `commuting_projectors_compatible` | root | 函數 |
| `complement` | root | 函數 |
| `decompose` | root | 函數 |
| `eigen_equations_hold` | root | 函數 |
| `eigenspace_kan_sound` | root | 函數 |
| `eigenspace_well_formed` | root | 函數 |
| `in_image` | root | 函數 |
| `in_kernel` | root | 函數 |
| `is_hermitian` | root | 函數 |
| `is_idempotent` | root | 函數 |
| `is_projector` | root | 函數 |
| `outer` | root | 函數 |
| `projector_certificate_ok` | root | 函數 |
| `projector_from_orthonormal` | root | 函數 |
| `prune_to_eigenspace` | root | 函數 |
| `pruning_is_retraction` | root | 函數 |

### Karoubi 包絡

- 規範形式：物件 P；態射被夾緊矩陣 QAP=A
- 範疇化：冪完備化；恒等是 P 本身；dagger
- 判定：QAP=A 與合成律

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_karoubi_category` | root | 函數 |
| `karoubi_comp` | root | 函數 |
| `karoubi_id` | root | 函數 |
| `karoubi_morphism` | root | 函數 |
| `karoubi_wrap` | root | 函數 |

### 區間

- 規範形式：De Morgan 表達式；端點布林化
- 範疇化：De Morgan 代數（區間物件）
- 判定：求值與重寫簡化

| 符號 | 套件 | 類別 |
|---|---|---|
| `Dim` | root | 列舉 |
| `Dim::DAnd` | root | 構造子 |
| `Dim::DNeg` | root | 構造子 |
| `Dim::DOne` | root | 構造子 |
| `Dim::DOr` | root | 構造子 |
| `Dim::DVar` | root | 構造子 |
| `Dim::DZero` | root | 構造子 |
| `Dim::equal` | root | 函數 |
| `Dim::not_equal` | root | 函數 |
| `Dim::to_repr` | root | 函數 |
| `dmax` | root | 函數 |
| `dmin` | root | 函數 |
| `eval_dim` | root | 函數 |
| `eval_dim_bool` | root | 函數 |
| `interval_laws_hold` | root | 函數 |

### 面公式與 BDD

- 規範形式：由 interned DAG 展開的 ROBDD 樹（相容表示）；主判定在同一 manager 以 root 代表
- 範疇化：面格（自由有界分配格的商）的規範代表
- 判定：DAG apply/root 相等判定；樹形 API 為逐公式展開

| 符號 | 套件 | 類別 |
|---|---|---|
| `Bdd` | root | 列舉 |
| `Bdd::BddNode` | root | 構造子 |
| `Bdd::BddOne` | root | 構造子 |
| `Bdd::BddZero` | root | 構造子 |
| `Bdd::equal` | root | 函數 |
| `Bdd::not_equal` | root | 函數 |
| `Bdd::to_repr` | root | 函數 |
| `Face` | root | 列舉 |
| `Face::FAnd` | root | 構造子 |
| `Face::FBot` | root | 構造子 |
| `Face::FEq0` | root | 構造子 |
| `Face::FEq1` | root | 構造子 |
| `Face::FOr` | root | 構造子 |
| `Face::FTop` | root | 構造子 |
| `Face::equal` | root | 函數 |
| `Face::not_equal` | root | 函數 |
| `Face::to_repr` | root | 函數 |
| `assignment_of_mask` | root | 函數 |
| `bdd_and` | root | 函數 |
| `bdd_face_eq` | root | 函數 |
| `bdd_face_le` | root | 函數 |
| `bdd_not` | root | 函數 |
| `bdd_of_face` | root | 函數 |
| `bdd_or` | root | 函數 |
| `bdd_sat_face` | root | 函數 |
| `bdd_satisfying_cubes` | root | 函數 |
| `bdd_tree_cofactor` | root | 函數 |
| `check_bdd_canonical` | root | 函數 |
| `check_bdd_optimal_order_dp` | root | 函數 |
| `check_interval_faces` | root | 函數 |
| `contains_int` | root | 函數 |
| `dim_of_face` | root | 函數 |
| `dim_simplify` | root | 函數 |
| `dim_subst` | root | 函數 |
| `dim_var` | root | 函數 |
| `face_and` | root | 函數 |
| `face_bot` | root | 函數 |
| `face_bound` | root | 函數 |
| `face_cdcl_proof_check` | root | 函數 |
| `face_eq0` | root | 函數 |
| `face_eq1` | root | 函數 |
| `face_eq_decide` | root | 函數 |
| `face_eq_mod` | root | 函數 |
| `face_holds` | root | 函數 |
| `face_is_cubical_top` | root | 函數 |
| `face_join_universal` | root | 函數 |
| `face_le` | root | 函數 |
| `face_maps_commute` | root | 函數 |
| `face_meet_universal` | root | 函數 |
| `face_not` | root | 函數 |
| `face_of_bdd` | root | 函數 |
| `face_or` | root | 函數 |
| `face_sat` | root | 函數 |
| `face_sat_decide` | root | 函數 |
| `face_simplify` | root | 函數 |
| `face_subst` | root | 函數 |
| `face_top` | root | 函數 |
| `face_unsat` | root | 函數 |
| `face_var0` | root | 函數 |
| `face_var1` | root | 函數 |
| `face_vars` | root | 函數 |
| `face_witness` | root | 函數 |
| `pow2` | root | 函數 |
| `sort_ints` | root | 函數 |

### 面偏序範疇

- 規範形式：BDD 等價類
- 範疇化：偏序範疇：∧積、∨餘積、⊤/⊥ 終始
- 判定：bdd_face_le 與萬有性等式

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_face_poset_category` | root | 函數 |

### 系統與剪枝

- 規範形式：分支列；語義範形見系統符號範形
- 範疇化：面上 presheaf 的偏元素；聯集拼接
- 判定：重疊面的 BDD 可滿足性

| 符號 | 套件 | 類別 |
|---|---|---|
| `VecBranch` | root | 結構 |
| `VecBranch.face` | root | 欄位 |
| `VecBranch.value` | root | 欄位 |
| `VecSystem` | root | 結構 |
| `VecSystem.branches` | root | 欄位 |
| `branch` | root | 函數 |
| `check_systems` | root | 函數 |
| `compatibility_respects_quotient` | root | 函數 |
| `prune_system` | root | 函數 |
| `pruning_respects_quotient` | root | 函數 |
| `system_compatible` | root | 函數 |
| `system_domain_bdd` | root | 函數 |
| `system_eq_mod` | root | 函數 |
| `system_eq_mod_sym` | root | 函數 |
| `system_extend_top` | root | 函數 |
| `system_lookup` | root | 函數 |
| `system_normal_form` | root | 函數 |
| `system_of` | root | 函數 |
| `system_union` | root | 函數 |
| `union_commutes_mod` | root | 函數 |

### 系統符號範形

- 規範形式：值標記不交 BDD 分割＋未定義區域
- 範疇化：偏元素在面格切片中的像分解
- 判定：BDD 區域運算

| 符號 | 套件 | 類別 |
|---|---|---|
| `SymRegion` | root | 結構 |
| `SymRegion.region` | root | 欄位 |
| `SymRegion.value` | root | 欄位 |
| `SystemNF` | root | 結構 |
| `SystemNF.classes` | root | 欄位 |
| `SystemNF.undefined` | root | 欄位 |
| `vec_lex_lt` | root | 函數 |

### 立方體與 Kan 填充

- 規範形式：函數 Iⁿ→Cᵐ；填充用仿射公式；帽子為 comp 結果
- 範疇化：□ 上 cubical set 的實現；retract 的 Kan 結構
- 判定：邊界方程（網格）

| 符號 | 套件 | 類別 |
|---|---|---|
| `Cube` | root | 結構 |
| `Cube.cell` | root | 欄位 |
| `Cube.dim` | root | 欄位 |
| `bumped_filler` | root | 函數 |
| `check_cube3_and_moving_hit_comp` | root | 函數 |
| `check_cube_comp` | root | 函數 |
| `check_cubical_identities` | root | 函數 |
| `check_kan_pruning` | root | 函數 |
| `cube_const` | root | 函數 |
| `cube_eval` | root | 函數 |
| `cube_ext_eq` | root | 函數 |
| `cube_in_eigenspace` | root | 函數 |
| `degenerate_cube` | root | 函數 |
| `filler_respects_box` | root | 函數 |
| `kan_comp_eigenspace` | root | 函數 |
| `kan_comp_path` | root | 函數 |
| `kan_fill_eigenspace` | root | 函數 |
| `open_box_wf` | root | 函數 |
| `path_end` | root | 函數 |
| `path_eval` | root | 函數 |
| `path_line` | root | 函數 |
| `path_refl` | root | 函數 |
| `path_start` | root | 函數 |
| `path_sym` | root | 函數 |
| `path_trans` | root | 函數 |
| `path_trans_endpoints` | root | 函數 |
| `prune_cube` | root | 函數 |
| `pruning_repairs_filler` | root | 函數 |
| `restrict_face` | root | 函數 |
| `square_fill` | root | 函數 |

### 未型別 NbE

- 規範形式：βπ 正規形 nf
- 範疇化：句法範疇在 βπ 商下的態射代表
- 判定：eval/quote 後結構比較

| 符號 | 套件 | 類別 |
|---|---|---|
| `Neutral` | root | 列舉 |
| `Neutral::NeApp` | root | 構造子 |
| `Neutral::NeFst` | root | 構造子 |
| `Neutral::NeSnd` | root | 構造子 |
| `Neutral::NeVar` | root | 構造子 |
| `Term` | root | 列舉 |
| `Term::TmAnn` | root | 構造子 |
| `Term::TmApp` | root | 構造子 |
| `Term::TmBool` | root | 構造子 |
| `Term::TmCoeRefl` | root | 構造子 |
| `Term::TmCoeUaSwap` | root | 構造子 |
| `Term::TmFst` | root | 構造子 |
| `Term::TmLam` | root | 構造子 |
| `Term::TmPair` | root | 構造子 |
| `Term::TmSnd` | root | 構造子 |
| `Term::TmUnit` | root | 構造子 |
| `Term::TmVar` | root | 構造子 |
| `Term::equal` | root | 函數 |
| `Term::not_equal` | root | 函數 |
| `Term::to_repr` | root | 函數 |
| `Value` | root | 列舉 |
| `Value::VBool` | root | 構造子 |
| `Value::VClosure` | root | 構造子 |
| `Value::VNeutral` | root | 構造子 |
| `Value::VPair` | root | 構造子 |
| `Value::VUnit` | root | 構造子 |
| `check_nbe` | root | 函數 |
| `coe_rules_definitional` | root | 函數 |
| `def_eq` | root | 函數 |
| `eval` | root | 函數 |
| `eval_check_t` | root | 函數 |
| `eval_decode_term` | root | 函數 |
| `eval_glue_equiv_term` | root | 函數 |
| `eval_inductive_decode` | root | 函數 |
| `eval_infer_t` | root | 函數 |
| `eval_mk_equiv_term` | root | 函數 |
| `eval_mutual_elim` | root | 函數 |
| `eval_ua_term` | root | 函數 |
| `eval_unglue_equiv_term` | root | 函數 |
| `nbe_single_valued` | root | 函數 |
| `nf` | root | 函數 |
| `quote` | root | 函數 |
| `quote_decode_neutral` | root | 函數 |
| `quote_glue_equiv_type` | root | 函數 |
| `quote_neutral` | root | 函數 |
| `quote_schema_args_full` | root | 函數 |
| `quote_unglue_equiv_neutral` | root | 函數 |
| `swap_involutive_on_element` | root | 函數 |
| `tm_const` | root | 函數 |
| `tm_id` | root | 函數 |
| `tm_swap` | root | 函數 |
| `vapp` | root | 函數 |
| `vfst` | root | 函數 |
| `vsnd` | root | 函數 |

### HOAS

- 規範形式：經 reify 的 de Bruijn 範形
- 範疇化：函子範疇式綁定；與一階語法範疇等價（模定義相等）
- 判定：reflect/reify 往返

| 符號 | 套件 | 類別 |
|---|---|---|
| `HTm` | root | 列舉 |
| `HTm::HApp` | root | 構造子 |
| `HTm::HBool` | root | 構造子 |
| `HTm::HFst` | root | 構造子 |
| `HTm::HLam` | root | 構造子 |
| `HTm::HPair` | root | 構造子 |
| `HTm::HSnd` | root | 構造子 |
| `HTm::HUnit` | root | 構造子 |
| `HTm::HVar` | root | 構造子 |
| `check_hoas` | root | 函數 |
| `happ` | root | 函數 |
| `hfst` | root | 函數 |
| `hoas_const_example` | root | 函數 |
| `hoas_roundtrip_hoas` | root | 函數 |
| `hoas_roundtrip_term` | root | 函數 |
| `hoas_swap_example` | root | 函數 |
| `hoas_to_term` | root | 函數 |
| `hsnd` | root | 函數 |
| `term_to_hoas` | root | 函數 |

### 型別化 NbE 與 η

- 規範形式：η 長 βπ 範形 nf_eta
- 範疇化：自由笛卡兒閉範疇的態射代表
- 判定：雙向檢查＋按型別 quote

| 符號 | 套件 | 類別 |
|---|---|---|
| `LTy` | root | 列舉 |
| `LTy::LBool` | root | 構造子 |
| `LTy::LFun` | root | 構造子 |
| `LTy::LProd` | root | 構造子 |
| `LTy::LUnit` | root | 構造子 |
| `LTy::equal` | root | 函數 |
| `LTy::not_equal` | root | 函數 |
| `LTy::to_repr` | root | 函數 |
| `TNeutral` | root | 列舉 |
| `TNeutral::TNeApp` | root | 構造子 |
| `TNeutral::TNeFst` | root | 構造子 |
| `TNeutral::TNeSnd` | root | 構造子 |
| `TNeutral::TNeVar` | root | 構造子 |
| `TValue` | root | 列舉 |
| `TValue::TVBool` | root | 構造子 |
| `TValue::TVClosure` | root | 構造子 |
| `TValue::TVNeutral` | root | 構造子 |
| `TValue::TVPair` | root | 構造子 |
| `TValue::TVUnit` | root | 構造子 |
| `TypedValue` | root | 結構 |
| `TypedValue.ty` | root | 欄位 |
| `TypedValue.value` | root | 欄位 |
| `check_eta_all` | root | 函數 |
| `check_eta_function` | root | 函數 |
| `check_eta_product` | root | 函數 |
| `check_eta_spine` | root | 函數 |
| `check_eta_swap_involution` | root | 函數 |
| `check_eta_unit` | root | 函數 |
| `def_eq_eta` | root | 函數 |
| `eta_single_valued_on` | root | 函數 |
| `nf_eta` | root | 函數 |
| `quote_eta` | root | 函數 |
| `quote_tneutral` | root | 函數 |
| `tapp` | root | 函數 |
| `tfst` | root | 函數 |
| `tm_coe_swap_at` | root | 函數 |
| `tm_swap_at` | root | 函數 |
| `tsnd` | root | 函數 |
| `ty_check` | root | 函數 |
| `ty_infer` | root | 函數 |

### 依賴型別 NbE（Π/Σ/宇宙）

- 規範形式：按型別 quote 的 η 長依賴正規形；Π/Σ 第二分量為語義閉包族；累積 Typeᵢ 層級
- 範疇化：帶族範疇 (CwF) 模型：脈絡延伸與依賴代入是閉包施用
- 判定：雙向 elaboration＋型別導向轉換；相等=範形相等；項層級另有對離散 Bool 脈絡變量的差異導引 case-split 轉換加強（先比較兩側範形、優先切分實際差異變量，兩分支代入後遞迴判定，含相依型別代入並回報 nodes/probes；Nat 變量不切分），不改變覈心轉換

| 符號 | 套件 | 類別 |
|---|---|---|
| `CaseSplitReport` | root | 結構 |
| `CaseSplitReport.holds` | root | 欄位 |
| `CaseSplitReport.probes` | root | 欄位 |
| `CaseSplitReport.root_difference_variables` | root | 欄位 |
| `CaseSplitReport.split_nodes` | root | 欄位 |
| `DFamilyParts` | root | 結構 |
| `DFamilyParts.dom` | root | 欄位 |
| `DFamilyParts.fam` | root | 欄位 |
| `DInfer` | root | 結構 |
| `DInfer.ty` | root | 欄位 |
| `DInfer.value` | root | 欄位 |
| `DNeutral` | root | 列舉 |
| `DNeutral::DNApp` | root | 構造子 |
| `DNeutral::DNAppDim` | root | 構造子 |
| `DNeutral::DNBoolElim` | root | 構造子 |
| `DNeutral::DNCircleElim` | root | 構造子 |
| `DNeutral::DNComp` | root | 構造子 |
| `DNeutral::DNDecode` | root | 構造子 |
| `DNeutral::DNEquivAnn` | root | 構造子 |
| `DNeutral::DNEquivBwd` | root | 構造子 |
| `DNeutral::DNEquivFwd` | root | 構造子 |
| `DNeutral::DNEquivRetr` | root | 構造子 |
| `DNeutral::DNEquivSect` | root | 構造子 |
| `DNeutral::DNFst` | root | 構造子 |
| `DNeutral::DNHComp` | root | 構造子 |
| `DNeutral::DNHitElim` | root | 構造子 |
| `DNeutral::DNInductiveElim` | root | 構造子 |
| `DNeutral::DNListElim` | root | 構造子 |
| `DNeutral::DNNatElim` | root | 構造子 |
| `DNeutral::DNSnd` | root | 構造子 |
| `DNeutral::DNTorusElim` | root | 構造子 |
| `DNeutral::DNUnglueEquiv` | root | 構造子 |
| `DNeutral::DNVar` | root | 構造子 |
| `DTerm` | root | 列舉 |
| `DTerm::DAnn` | root | 構造子 |
| `DTerm::DApp` | root | 構造子 |
| `DTerm::DAppDim` | root | 構造子 |
| `DTerm::DBoolElim` | root | 構造子 |
| `DTerm::DBoolLit` | root | 構造子 |
| `DTerm::DBoolTy` | root | 構造子 |
| `DTerm::DCircleBase` | root | 構造子 |
| `DTerm::DCircleElim` | root | 構造子 |
| `DTerm::DCircleLoop` | root | 構造子 |
| `DTerm::DCircleTy` | root | 構造子 |
| `DTerm::DCoe` | root | 構造子 |
| `DTerm::DComp` | root | 構造子 |
| `DTerm::DCons` | root | 構造子 |
| `DTerm::DDecode` | root | 構造子 |
| `DTerm::DEquivBwd` | root | 構造子 |
| `DTerm::DEquivFwd` | root | 構造子 |
| `DTerm::DEquivRetr` | root | 構造子 |
| `DTerm::DEquivSect` | root | 構造子 |
| `DTerm::DEquivTy` | root | 構造子 |
| `DTerm::DFst` | root | 構造子 |
| `DTerm::DGlueEquiv` | root | 構造子 |
| `DTerm::DHComp` | root | 構造子 |
| `DTerm::DHFill` | root | 構造子 |
| `DTerm::DHitElim` | root | 構造子 |
| `DTerm::DHitIntro` | root | 構造子 |
| `DTerm::DHitType` | root | 構造子 |
| `DTerm::DInductive` | root | 構造子 |
| `DTerm::DInductiveElim` | root | 構造子 |
| `DTerm::DIntro` | root | 構造子 |
| `DTerm::DLam` | root | 構造子 |
| `DTerm::DLamDim` | root | 構造子 |
| `DTerm::DListElim` | root | 構造子 |
| `DTerm::DListTy` | root | 構造子 |
| `DTerm::DMkEquiv` | root | 構造子 |
| `DTerm::DNatElim` | root | 構造子 |
| `DTerm::DNatTy` | root | 構造子 |
| `DTerm::DNatZero` | root | 構造子 |
| `DTerm::DNil` | root | 構造子 |
| `DTerm::DPair` | root | 構造子 |
| `DTerm::DPartial` | root | 構造子 |
| `DTerm::DPath` | root | 構造子 |
| `DTerm::DPathP` | root | 構造子 |
| `DTerm::DPi` | root | 構造子 |
| `DTerm::DSigma` | root | 構造子 |
| `DTerm::DSnd` | root | 構造子 |
| `DTerm::DSucc` | root | 構造子 |
| `DTerm::DTVar` | root | 構造子 |
| `DTerm::DTorusBase` | root | 構造子 |
| `DTerm::DTorusElim` | root | 構造子 |
| `DTerm::DTorusLoopA` | root | 構造子 |
| `DTerm::DTorusLoopB` | root | 構造子 |
| `DTerm::DTorusSquare` | root | 構造子 |
| `DTerm::DTorusTy` | root | 構造子 |
| `DTerm::DUa` | root | 構造子 |
| `DTerm::DUnglueEquiv` | root | 構造子 |
| `DTerm::DUnitLit` | root | 構造子 |
| `DTerm::DUnitTy` | root | 構造子 |
| `DTerm::DUniv` | root | 構造子 |
| `DTerm::DUnivLevel` | root | 構造子 |
| `DTerm::equal` | root | 函數 |
| `DTerm::not_equal` | root | 函數 |
| `DTerm::to_repr` | root | 函數 |
| `DTypeVal` | root | 結構 |
| `DTypeVal.level` | root | 欄位 |
| `DTypeVal.value` | root | 欄位 |
| `DValue` | root | 列舉 |
| `DValue::DVBool` | root | 構造子 |
| `DValue::DVBoolTy` | root | 構造子 |
| `DValue::DVCirclePoint` | root | 構造子 |
| `DValue::DVCircleTy` | root | 構造子 |
| `DValue::DVCons` | root | 構造子 |
| `DValue::DVEquiv` | root | 構造子 |
| `DValue::DVEquivTy` | root | 構造子 |
| `DValue::DVGlue` | root | 構造子 |
| `DValue::DVGlueEquiv` | root | 構造子 |
| `DValue::DVHitCell` | root | 構造子 |
| `DValue::DVHitType` | root | 構造子 |
| `DValue::DVInductive` | root | 構造子 |
| `DValue::DVIntro` | root | 構造子 |
| `DValue::DVLam` | root | 構造子 |
| `DValue::DVListTy` | root | 構造子 |
| `DValue::DVNatTy` | root | 構造子 |
| `DValue::DVNeutral` | root | 構造子 |
| `DValue::DVNil` | root | 構造子 |
| `DValue::DVPair` | root | 構造子 |
| `DValue::DVPartial` | root | 構造子 |
| `DValue::DVPathLam` | root | 構造子 |
| `DValue::DVPathTy` | root | 構造子 |
| `DValue::DVPi` | root | 構造子 |
| `DValue::DVSigma` | root | 構造子 |
| `DValue::DVSucc` | root | 構造子 |
| `DValue::DVThunk` | root | 構造子 |
| `DValue::DVTorusPoint` | root | 構造子 |
| `DValue::DVTorusTy` | root | 構造子 |
| `DValue::DVUnit` | root | 構造子 |
| `DValue::DVUnitTy` | root | 構造子 |
| `DValue::DVUniv` | root | 構造子 |
| `DValue::DVZeroNat` | root | 構造子 |
| `SheafPartitionConvReport` | root | 結構 |
| `SheafPartitionConvReport.all_stalks_convertible` | root | 欄位 |
| `SheafPartitionConvReport.equivalent_brute_force_cases` | root | 欄位 |
| `SheafPartitionConvReport.n_bool_vars` | root | 欄位 |
| `SheafPartitionConvReport.partition_covers_top` | root | 欄位 |
| `SheafPartitionConvReport.stalk_count` | root | 欄位 |
| `SheafPartitionConvReport::equal` | root | 函數 |
| `SheafPartitionConvReport::not_equal` | root | 函數 |
| `SheafPartitionConvReport::to_repr` | root | 函數 |
| `as_pi` | root | 函數 |
| `as_sigma` | root | 函數 |
| `as_univ_level` | root | 函數 |
| `check_dep_all` | root | 函數 |
| `check_dep_pi` | root | 函數 |
| `check_dep_sigma` | root | 函數 |
| `check_dep_universe` | root | 函數 |
| `check_difference_guided_case_split` | root | 函數 |
| `conv_at` | root | 函數 |
| `conv_difference_variables` | root | 函數 |
| `conv_neutral` | root | 函數 |
| `conv_sheaf_glued_boolean_partition` | root | 函數 |
| `conv_terms_case_split` | root | 函數 |
| `conv_terms_case_split_report` | root | 函數 |
| `conv_terms_finite_case_split` | root | 函數 |
| `conv_terms_finite_case_split_report` | root | 函數 |
| `conv_terms_plain` | root | 函數 |
| `conv_ty` | root | 函數 |
| `cs_finite_closed_inhabitants` | root | 函數 |
| `d_as_type` | root | 函數 |
| `d_check` | root | 函數 |
| `d_infer` | root | 函數 |
| `dapp_typed` | root | 函數 |
| `dep_check_closed` | root | 函數 |
| `dep_id_term` | root | 函數 |
| `dep_id_type` | root | 函數 |
| `dep_nf_closed` | root | 函數 |
| `dep_type_of_closed` | root | 函數 |
| `dep_type_val_of` | root | 函數 |
| `dfst_typed` | root | 函數 |
| `dsnd_typed` | root | 函數 |
| `lty_to_dterm` | root | 函數 |
| `quote_at` | root | 函數 |
| `quote_dneutral` | root | 函數 |
| `quote_ty` | root | 函數 |
| `reflect_neutral_at_type` | root | 函數 |
| `reflect_var` | root | 函數 |

### 立方 AST 與維度 NbE

- 規範形式：DTerm 的項/維度雙 de Bruijn 索引；線與 tube body；帶 dlevel 的 quote
- 範疇化：帶區間脈絡的 cubical CwF；PathP 為依賴路徑物件，Glue 值為 (raw/DPartial partial,base) 對
- 判定：雙向檢查＋Dim/Face 簡化及 ROBDD 語義謂詞

| 符號 | 套件 | 類別 |
|---|---|---|
| `DGlueParts` | root | 結構 |
| `DGlueParts.base` | root | 欄位 |
| `DGlueParts.face` | root | 欄位 |
| `DGlueParts.level` | root | 欄位 |
| `DGlueParts.line` | root | 欄位 |
| `DGlueParts.system` | root | 欄位 |
| `DPathParts` | root | 結構 |
| `DPathParts.left` | root | 欄位 |
| `DPathParts.line` | root | 欄位 |
| `DPathParts.right` | root | 欄位 |
| `DTubeTerm` | root | 結構 |
| `DTubeTerm.body` | root | 欄位 |
| `DTubeTerm.face` | root | 欄位 |
| `DTubeTerm::equal` | root | 函數 |
| `DTubeTerm::not_equal` | root | 函數 |
| `DTubeTerm::to_repr` | root | 函數 |
| `as_glue` | root | 函數 |
| `as_list_elem` | root | 函數 |
| `as_path` | root | 函數 |
| `check_ast_paths` | root | 函數 |
| `d_tube` | root | 函數 |
| `dapp_dim` | root | 函數 |
| `dep_def_eq_closed` | root | 函數 |
| `deval_dim` | root | 函數 |
| `dim_quote` | root | 函數 |
| `dterm_dim_vars` | root | 函數 |
| `eval_dim_expr` | root | 函數 |
| `eval_tube_terms` | root | 函數 |
| `face_eval_env` | root | 函數 |
| `face_quote` | root | 函數 |
| `fresh_dim` | root | 函數 |
| `quote_tube_branches` | root | 函數 |

### AST Kan comp/hcomp

- 規範形式：分支一律攜帶為 DSystem；在一般維度按型別頭派遣；頂分支取帽、形式合成為 DNComp/DNHComp；CircleSquareWindingReport 記錄二維圓方塊四邊繞數與 H-空間黏合狀態
- 範疇化：各型別構造子保存 Kan 纖維化結構；hcompU 是 Glue 黏合；圓 S¹≃K(ℤ,1) 與環面 T²≃S¹×S¹ 的群胚 H-空間乘法把端點 0~1 黏合方塊邊界化約為整數纏繞數二上循環守恆條件
- 判定：系統 base/重疊相容＋型別遞迴；Circle/Torus 分支配帽由一般分支值的座標表式代入 1 讀出，二維端點黏合開盒在零淨纏繞時以 H-空間旋轉構造二維填充帽、非零淨纏繞阻礙時明示回傳 None；coe/fill 為 comp 線段限制

| 符號 | 套件 | 類別 |
|---|---|---|
| `CircleSquareWindingReport` | root | 結構 |
| `CircleSquareWindingReport.corners_compatible` | root | 欄位 |
| `CircleSquareWindingReport.filler` | root | 欄位 |
| `CircleSquareWindingReport.net_boundary_winding` | root | 欄位 |
| `CircleSquareWindingReport.used_hspace_glue` | root | 欄位 |
| `CircleSquareWindingReport.winding_i0` | root | 欄位 |
| `CircleSquareWindingReport.winding_i1` | root | 欄位 |
| `CircleSquareWindingReport.winding_j0` | root | 欄位 |
| `CircleSquareWindingReport.winding_j1` | root | 欄位 |
| `WedgeSquareFillerReport` | root | 結構 |
| `WedgeSquareFillerReport.abelian_winding_a` | root | 欄位 |
| `WedgeSquareFillerReport.abelian_winding_b` | root | 欄位 |
| `WedgeSquareFillerReport.fills_in_abelianized_torus` | root | 欄位 |
| `WedgeSquareFillerReport.fills_in_wedge_s1_s1` | root | 欄位 |
| `WedgeSquareFillerReport.reduced_f2_boundary_word` | root | 欄位 |
| `WedgeSquareFillerReport::equal` | root | 函數 |
| `WedgeSquareFillerReport::not_equal` | root | 函數 |
| `WedgeSquareFillerReport::to_repr` | root | 函數 |
| `check_ast_coe_terms` | root | 函數 |
| `check_ast_hcomp_data_terms` | root | 函數 |
| `check_ast_hcomp_hit_terms` | root | 函數 |
| `check_ast_hcomp_sigma_path_terms` | root | 函數 |
| `check_ast_hcomp_univ_term` | root | 函數 |
| `check_ast_kan_terms` | root | 函數 |
| `check_ast_kan_types` | root | 函數 |
| `check_circle_torus_point_comp` | root | 函數 |
| `check_circle_torus_square_comp` | root | 函數 |
| `check_phase14_decoupled_torus_and_semantic_circle_norm` | root | 函數 |
| `circle_path_winding_int` | root | 函數 |
| `circle_square_glued_cap` | root | 函數 |
| `coe_value` | root | 函數 |
| `comp_glue_value` | root | 函數 |
| `comp_path_value` | root | 函數 |
| `comp_pi_value` | root | 函數 |
| `comp_sigma_value` | root | 函數 |
| `comp_univ_value` | root | 函數 |
| `comp_value` | root | 函數 |
| `dim_eq_sem` | root | 函數 |
| `dim_nvars_sem` | root | 函數 |
| `dim_vars_of` | root | 函數 |
| `f2_invert_word` | root | 函數 |
| `f2_reduce_word` | root | 函數 |
| `face_is_bot_sem` | root | 函數 |
| `face_is_sat_sem` | root | 函數 |
| `face_is_top_sem` | root | 函數 |
| `face_nvars_sem` | root | 函數 |
| `fill_value` | root | 函數 |
| `hcomp_univ_value` | root | 函數 |
| `hcomp_value` | root | 函數 |
| `hfill_value` | root | 函數 |
| `torus_square_glued_cap` | root | 函數 |
| `wedge_square_filler_report` | root | 函數 |

### 資料型別與 HIT 消去

- 規範形式：Nat/List 構造子遞迴；Circle loop@r；Torus square@(i,j) 模對邊等同
- 範疇化：初始代數與 HIT 的依賴消去是 motive 截面，並與形式 composition 交換
- 判定：構造子模式遞迴、Dim 語義相等、motive 中的 comp

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_ast_bool_elim` | root | 函數 |
| `check_ast_data` | root | 函數 |
| `check_ast_hits` | root | 函數 |
| `check_ast_list_len` | root | 函數 |
| `check_ast_nat_dep` | root | 函數 |
| `check_ast_nat_pred` | root | 函數 |
| `circle_dim_of` | root | 函數 |
| `circle_point` | root | 函數 |
| `comp_bool_value` | root | 函數 |
| `comp_circle_value` | root | 函數 |
| `comp_list_value` | root | 函數 |
| `comp_nat_value` | root | 函數 |
| `comp_torus_value` | root | 函數 |
| `d_nat_lit` | root | 函數 |
| `dv_nat_lit` | root | 函數 |
| `eval_bool_elim` | root | 函數 |
| `eval_circle_elim` | root | 函數 |
| `eval_list_elim` | root | 函數 |
| `eval_nat_elim` | root | 函數 |
| `eval_torus_elim` | root | 函數 |
| `torus_dims_of` | root | 函數 |
| `torus_point` | root | 函數 |

### 持久環境、惰性與語義快取

- 規範形式：帶長度持久連結串列 DEnv/DDimEnv（de Bruijn 頭在最內）；DVThunk 最多強制一次；快取鍵為簡化維度/引文項 Debug 鍵；DTerm 全域 hash-consing 以子項 stamp 自底向上建立 intern 表，結構相等子項共享同一 intern id 而重建後項結構相等；intern 表另存每節點子 ID，DTermDagSnapshot 以 local shell＋child-id 邊輸出同一 DAG，CHDAGBIN v1 以逐節點 hash-cons 匯入並回報 added/reused
- 範疇化：CwF 脈絡延伸是共享尾部的 cons；惰性值是 call-by-need 語義值，memoized 族/維度線是外延函數的有限圖延伸
- 判定：環境索引、force_count 與快取鍵相等

| 符號 | 套件 | 類別 |
|---|---|---|
| `DDimEnv` | root | 列舉 |
| `DDimEnv::DDimEnvCons` | root | 構造子 |
| `DDimEnv::DDimEnvNil` | root | 構造子 |
| `DEnv` | root | 列舉 |
| `DEnv::DEnvCons` | root | 構造子 |
| `DEnv::DEnvNil` | root | 構造子 |
| `DTermDagBinaryLoad` | root | 結構 |
| `DTermDagBinaryLoad.snapshot` | root | 欄位 |
| `DTermDagBinaryLoad.status` | root | 欄位 |
| `DTermDagBinaryLoad::equal` | root | 函數 |
| `DTermDagBinaryLoad::not_equal` | root | 函數 |
| `DTermDagBinaryLoad::to_repr` | root | 函數 |
| `DTermDagDelta` | root | 結構 |
| `DTermDagDelta.base_digest_a` | root | 欄位 |
| `DTermDagDelta.base_digest_b` | root | 欄位 |
| `DTermDagDelta.base_node_count` | root | 欄位 |
| `DTermDagDelta.delta_nodes` | root | 欄位 |
| `DTermDagDelta.roots` | root | 欄位 |
| `DTermDagDelta::equal` | root | 函數 |
| `DTermDagDelta::not_equal` | root | 函數 |
| `DTermDagDelta::to_repr` | root | 函數 |
| `DTermDagDeltaBinaryLoad` | root | 結構 |
| `DTermDagDeltaBinaryLoad.delta` | root | 欄位 |
| `DTermDagDeltaBinaryLoad.status` | root | 欄位 |
| `DTermDagDeltaBinaryLoad::equal` | root | 函數 |
| `DTermDagDeltaBinaryLoad::not_equal` | root | 函數 |
| `DTermDagDeltaBinaryLoad::to_repr` | root | 函數 |
| `DTermDagImportReport` | root | 結構 |
| `DTermDagImportReport.added_nodes` | root | 欄位 |
| `DTermDagImportReport.node_ids` | root | 欄位 |
| `DTermDagImportReport.reused_nodes` | root | 欄位 |
| `DTermDagImportReport.root_ids` | root | 欄位 |
| `DTermDagImportReport::equal` | root | 函數 |
| `DTermDagImportReport::not_equal` | root | 函數 |
| `DTermDagImportReport::to_repr` | root | 函數 |
| `DTermDagNode` | root | 結構 |
| `DTermDagNode.children` | root | 欄位 |
| `DTermDagNode.shell` | root | 欄位 |
| `DTermDagNode::equal` | root | 函數 |
| `DTermDagNode::not_equal` | root | 函數 |
| `DTermDagNode::to_repr` | root | 函數 |
| `DTermDagSnapshot` | root | 結構 |
| `DTermDagSnapshot.nodes` | root | 欄位 |
| `DTermDagSnapshot.roots` | root | 欄位 |
| `DTermDagSnapshot::equal` | root | 函數 |
| `DTermDagSnapshot::not_equal` | root | 函數 |
| `DTermDagSnapshot::to_repr` | root | 函數 |
| `DTermInternTable` | root | 結構 |
| `DTermInternTable.ids` | root | 欄位 |
| `DTermInternTable.node_children` | root | 欄位 |
| `DTermInternTable.terms` | root | 欄位 |
| `DThunk` | root | 結構 |
| `DThunk.compute` | root | 欄位 |
| `DThunk.force_count` | root | 欄位 |
| `DThunk.forced` | root | 欄位 |
| `check_dterm_hash_consing` | root | 函數 |
| `check_interned_dag_byte_sharing` | root | 函數 |
| `check_persistent_env_lazy_cache` | root | 函數 |
| `check_phase14_incremental_dag_delta_and_shared_bundle` | root | 函數 |
| `ddim_at` | root | 函數 |
| `ddim_cons` | root | 函數 |
| `ddim_empty` | root | 函數 |
| `ddim_extend` | root | 函數 |
| `ddim_from_array` | root | 函數 |
| `ddim_len` | root | 函數 |
| `ddim_to_array` | root | 函數 |
| `denv_at` | root | 函數 |
| `denv_cons` | root | 函數 |
| `denv_empty` | root | 函數 |
| `denv_extend` | root | 函數 |
| `denv_from_array` | root | 函數 |
| `denv_len` | root | 函數 |
| `denv_tail` | root | 函數 |
| `denv_to_array` | root | 函數 |
| `dim_cache_key` | root | 函數 |
| `dterm_cache_key` | root | 函數 |
| `dterm_dag_binary_format_version` | root | 函數 |
| `dterm_dag_binary_supported_versions` | root | 函數 |
| `dterm_dag_binary_version_of` | root | 函數 |
| `dterm_dag_binary_version_policy` | root | 函數 |
| `dterm_dag_delta_apply` | root | 函數 |
| `dterm_dag_delta_compute` | root | 函數 |
| `dterm_dag_delta_import_binary` | root | 函數 |
| `dterm_dag_delta_load_binary_report` | root | 函數 |
| `dterm_dag_delta_to_binary` | root | 函數 |
| `dterm_dag_delta_validate` | root | 函數 |
| `dterm_dag_import` | root | 函數 |
| `dterm_dag_import_binary` | root | 函數 |
| `dterm_dag_snapshot` | root | 函數 |
| `dterm_dag_snapshot_from_binary` | root | 函數 |
| `dterm_dag_snapshot_load_binary_report` | root | 函數 |
| `dterm_dag_snapshot_to_binary` | root | 函數 |
| `dterm_dag_snapshot_validate` | root | 函數 |
| `dterm_distinct_subterm_count` | root | 函數 |
| `dterm_intern` | root | 函數 |
| `dterm_intern_id` | root | 函數 |
| `dterm_intern_lookup_id` | root | 函數 |
| `dterm_intern_node` | root | 函數 |
| `dterm_intern_table_new` | root | 函數 |
| `dterm_intern_table_prefix_digest` | root | 函數 |
| `dterm_intern_table_size` | root | 函數 |
| `dterm_intern_table_snapshot` | root | 函數 |
| `dterm_intern_table_term` | root | 函數 |
| `dterm_local_shell` | root | 函數 |
| `dterm_rebuild` | root | 函數 |
| `dterm_tree_node_count` | root | 函數 |
| `force_value` | root | 函數 |
| `lazy_deval` | root | 函數 |
| `lazy_force_count` | root | 函數 |
| `lazy_is_forced` | root | 函數 |
| `lazy_value` | root | 函數 |
| `memo_dim_line` | root | 函數 |
| `memo_family` | root | 函數 |

### 依賴語義系統與 partial 值

- 規範形式：DSystem 分支去 ⊥、按值合併同 body 並以引文排序；DPartialValue 的 BDD 有效區域分割 DSystemNF
- 範疇化：面格切片中的偏元素；多分支 Glue 為 partial type 系統與 base 的極限式配對
- 判定：BDD 區域運算＋分支 body 的型別導向轉換/引文鍵

| 符號 | 套件 | 類別 |
|---|---|---|
| `DFaceTerm` | root | 結構 |
| `DFaceTerm.body` | root | 欄位 |
| `DFaceTerm.face` | root | 欄位 |
| `DFaceTerm::equal` | root | 函數 |
| `DFaceTerm::not_equal` | root | 函數 |
| `DFaceTerm::to_repr` | root | 函數 |
| `DFaceValue` | root | 結構 |
| `DFaceValue.face` | root | 欄位 |
| `DFaceValue.value` | root | 欄位 |
| `DPartialValue` | root | 結構 |
| `DPartialValue.branches` | root | 欄位 |
| `DSystem` | root | 結構 |
| `DSystem.branches` | root | 欄位 |
| `DSystemClass` | root | 結構 |
| `DSystemClass.region` | root | 欄位 |
| `DSystemClass.value` | root | 欄位 |
| `DSystemNF` | root | 結構 |
| `DSystemNF.classes` | root | 欄位 |
| `DSystemNF.undefined` | root | 欄位 |
| `DTubeBranch` | root | 結構 |
| `DTubeBranch.face` | root | 欄位 |
| `DTubeBranch.path` | root | 欄位 |
| `check_dsystem_canonical_partial_nf` | root | 函數 |
| `check_dsystem_compatibility` | root | 函數 |
| `check_dsystem_structural_agreement_and_supplementation` | root | 函數 |
| `check_multibranch_glue_partial` | root | 函數 |
| `check_phase5_semantic_systems` | root | 函數 |
| `d_face_term` | root | 函數 |
| `dface_value` | root | 函數 |
| `dsystem_canonical` | root | 函數 |
| `dsystem_checked` | root | 函數 |
| `dsystem_compatibility_report` | root | 函數 |
| `dsystem_compatibility_report_in` | root | 函數 |
| `dsystem_compatible_with_base` | root | 函數 |
| `dsystem_compatible_with_base_in` | root | 函數 |
| `dsystem_domain_face` | root | 函數 |
| `dsystem_empty` | root | 函數 |
| `dsystem_first_match_checked` | root | 函數 |
| `dsystem_first_match_eq` | root | 函數 |
| `dsystem_first_match_normal_form` | root | 函數 |
| `dsystem_first_match_system` | root | 函數 |
| `dsystem_first_path` | root | 函數 |
| `dsystem_map` | root | 函數 |
| `dsystem_of` | root | 函數 |
| `dsystem_of_first_match_nf` | root | 函數 |
| `dsystem_pairwise_compatible` | root | 函數 |
| `dsystem_repair_to_base` | root | 函數 |
| `dsystem_repair_to_base_exact` | root | 函數 |
| `dsystem_repair_with_candidates` | root | 函數 |
| `dsystem_singleton` | root | 函數 |
| `glue_partial_values` | root | 函數 |
| `glue_store_partial` | root | 函數 |
| `map_branches` | root | 函數 |
| `partial_domain_bdd` | root | 函數 |
| `partial_empty` | root | 函數 |
| `partial_eq_at` | root | 函數 |
| `partial_normal_form` | root | 函數 |
| `partial_of` | root | 函數 |
| `partial_singleton` | root | 函數 |
| `tube_branch` | root | 函數 |
| `tube_system_nf_at` | root | 函數 |

### 通用歸納族 schema

- 規範形式：telescope＋完整 DTerm 引數型別（外部、直接/巢狀/函數遞迴與約束）；值為 DVIntro，中性消去按生成 case 型別引文
- 範疇化：結構化嚴格正性函子的依賴初始代數；消去子是 motive 截面，comp 沿先前引數 filler 遞迴
- 判定：schema 結構相等、telescope elaboration、極性正性判定與生成檢查

| 符號 | 套件 | 類別 |
|---|---|---|
| `DArgKind` | root | 列舉 |
| `DArgKind::DArgDecoded` | root | 構造子 |
| `DArgKind::DArgDecodedFunction` | root | 構造子 |
| `DArgKind::DArgExternal` | root | 構造子 |
| `DArgKind::DArgFunction` | root | 構造子 |
| `DArgKind::DArgNested` | root | 構造子 |
| `DArgKind::DArgRecursive` | root | 構造子 |
| `DArgKind::equal` | root | 函數 |
| `DArgKind::not_equal` | root | 函數 |
| `DArgKind::to_repr` | root | 函數 |
| `DConstructorArg` | root | 結構 |
| `DConstructorArg.index` | root | 欄位 |
| `DConstructorArg.kind` | root | 欄位 |
| `DConstructorArg.name` | root | 欄位 |
| `DConstructorArg.nested` | root | 欄位 |
| `DConstructorArg.target` | root | 欄位 |
| `DConstructorArg.ty` | root | 欄位 |
| `DConstructorArg::equal` | root | 函數 |
| `DConstructorArg::not_equal` | root | 函數 |
| `DConstructorArg::to_repr` | root | 函數 |
| `DConstructorSpec` | root | 結構 |
| `DConstructorSpec.args` | root | 欄位 |
| `DConstructorSpec.constraints` | root | 欄位 |
| `DConstructorSpec.name` | root | 欄位 |
| `DConstructorSpec.result_index` | root | 欄位 |
| `DConstructorSpec::equal` | root | 函數 |
| `DConstructorSpec::not_equal` | root | 函數 |
| `DConstructorSpec::to_repr` | root | 函數 |
| `DInductiveSpec` | root | 結構 |
| `DInductiveSpec.constructors` | root | 欄位 |
| `DInductiveSpec.decode_cases` | root | 欄位 |
| `DInductiveSpec.decode_level` | root | 欄位 |
| `DInductiveSpec.indices` | root | 欄位 |
| `DInductiveSpec.level` | root | 欄位 |
| `DInductiveSpec.name` | root | 欄位 |
| `DInductiveSpec.params` | root | 欄位 |
| `DInductiveSpec::equal` | root | 函數 |
| `DInductiveSpec::not_equal` | root | 函數 |
| `DInductiveSpec::to_repr` | root | 函數 |
| `DTelescopeEntry` | root | 結構 |
| `DTelescopeEntry.name` | root | 欄位 |
| `DTelescopeEntry.ty` | root | 欄位 |
| `DTelescopeEntry::equal` | root | 函數 |
| `DTelescopeEntry::not_equal` | root | 函數 |
| `DTelescopeEntry::to_repr` | root | 函數 |
| `bool_schema` | root | 函數 |
| `check_generated_inductive_schemas` | root | 函數 |
| `check_schema_indexed` | root | 函數 |
| `check_schema_inductive_comp` | root | 函數 |
| `check_schema_list` | root | 函數 |
| `check_schema_nat_add` | root | 函數 |
| `check_schema_nat_neutral_quote` | root | 函數 |
| `check_schema_tree` | root | 函數 |
| `check_schema_validation` | root | 函數 |
| `check_schema_vec_comp` | root | 函數 |
| `check_schema_w` | root | 函數 |
| `check_telescope_terms` | root | 函數 |
| `comp_inductive_value` | root | 函數 |
| `comp_schema_args` | root | 函數 |
| `conv_inductive_elim_neutral` | root | 函數 |
| `conv_inductive_type` | root | 函數 |
| `conv_intro_at` | root | 函數 |
| `conv_schema_args` | root | 函數 |
| `conv_telescope_values` | root | 函數 |
| `darg_decoded` | root | 函數 |
| `darg_decoded_function` | root | 函數 |
| `darg_external` | root | 函數 |
| `darg_function` | root | 函數 |
| `darg_mutual` | root | 函數 |
| `darg_nested` | root | 函數 |
| `darg_recursive` | root | 函數 |
| `dconstructor_constraint` | root | 函數 |
| `dconstructor_spec` | root | 函數 |
| `dconstructor_spec_constrained` | root | 函數 |
| `dinductive_level_scheme` | root | 函數 |
| `dinductive_recursive_spec` | root | 函數 |
| `dinductive_spec` | root | 函數 |
| `dtelescope_entry` | root | 函數 |
| `empty_inductive_elim_value` | root | 函數 |
| `empty_inductive_schema` | root | 函數 |
| `empty_inductive_type_value` | root | 函數 |
| `eval_inductive_elim` | root | 函數 |
| `eval_inductive_elim_term` | root | 函數 |
| `eval_inductive_type_term` | root | 函數 |
| `eval_intro_term` | root | 函數 |
| `fin_schema` | root | 函數 |
| `inductive_arg_type` | root | 函數 |
| `inductive_arg_type_full` | root | 函數 |
| `inductive_case_type` | root | 函數 |
| `inductive_decode_cases_validate` | root | 函數 |
| `inductive_index_types` | root | 函數 |
| `inductive_index_types_cached` | root | 函數 |
| `inductive_motive_type` | root | 函數 |
| `inductive_param_types` | root | 函數 |
| `inductive_param_types_cached` | root | 函數 |
| `inductive_parameter_positivity` | root | 函數 |
| `inductive_parameter_positivity_declared` | root | 函數 |
| `inductive_plan_type_term` | root | 函數 |
| `inductive_result_indices` | root | 函數 |
| `inductive_schema_key` | root | 函數 |
| `inductive_schema_validate` | root | 函數 |
| `infer_inductive_elim` | root | 函數 |
| `infer_inductive_type` | root | 函數 |
| `infer_intro` | root | 函數 |
| `list_schema` | root | 函數 |
| `nat_schema` | root | 函數 |
| `nat_schema_lit` | root | 函數 |
| `quote_inductive_elim_neutral` | root | 函數 |
| `quote_inductive_type` | root | 函數 |
| `quote_intro_at` | root | 函數 |
| `quote_schema_args` | root | 函數 |
| `quote_schema_motive` | root | 函數 |
| `quote_telescope_values` | root | 函數 |
| `schema_apply_constraint_proofs` | root | 函數 |
| `schema_arg_spec_prefix` | root | 函數 |
| `schema_arg_type` | root | 函數 |
| `schema_arg_type_full` | root | 函數 |
| `schema_concat_values` | root | 函數 |
| `schema_constraint_parts` | root | 函數 |
| `schema_constraints_hold` | root | 函數 |
| `schema_constraints_pi` | root | 函數 |
| `schema_elim_term` | root | 函數 |
| `schema_examples` | root | 函數 |
| `schema_expected_param_terms` | root | 函數 |
| `schema_intro_term` | root | 函數 |
| `schema_motives_conv` | root | 函數 |
| `schema_registry_binary_format_version` | root | 函數 |
| `schema_registry_binary_from_hex` | root | 函數 |
| `schema_registry_binary_roundtrip_ok` | root | 函數 |
| `schema_registry_binary_supported_versions` | root | 函數 |
| `schema_registry_binary_to_hex` | root | 函數 |
| `schema_registry_binary_version_of` | root | 函數 |
| `schema_registry_binary_version_policy` | root | 函數 |
| `schema_registry_from_binary` | root | 函數 |
| `schema_registry_hit_by_id` | root | 函數 |
| `schema_registry_hit_plan` | root | 函數 |
| `schema_registry_inductive_by_name` | root | 函數 |
| `schema_registry_inductive_plan` | root | 函數 |
| `schema_registry_manifest` | root | 函數 |
| `schema_registry_merge_into` | root | 函數 |
| `schema_registry_new` | root | 函數 |
| `schema_registry_register_hit` | root | 函數 |
| `schema_registry_register_inductive` | root | 函數 |
| `schema_registry_register_inductives` | root | 函數 |
| `schema_registry_restore` | root | 函數 |
| `schema_registry_snapshot` | root | 函數 |
| `schema_registry_snapshot_from_binary` | root | 函數 |
| `schema_registry_snapshot_load_binary_report` | root | 函數 |
| `schema_registry_snapshot_to_binary` | root | 函數 |
| `schema_registry_snapshot_to_binary_for_peer` | root | 函數 |
| `schema_registry_snapshot_to_binary_version` | root | 函數 |
| `schema_registry_stats` | root | 函數 |
| `schema_registry_to_binary` | root | 函數 |
| `schema_registry_validate_hit` | root | 函數 |
| `schema_registry_validate_inductive` | root | 函數 |
| `schema_telescope_family_occurs` | root | 函數 |
| `schema_type_term` | root | 函數 |
| `schema_value_prefix` | root | 函數 |
| `telescope_next_type` | root | 函數 |
| `telescope_type_values` | root | 函數 |
| `telescope_type_values_cached` | root | 函數 |
| `tree_schema` | root | 函數 |
| `vec_schema` | root | 函數 |
| `w_schema` | root | 函數 |

### 通用 HIT schema

- 規範形式：任意有限維 cell；任一端點按 face expression 逐維化簡；case 為逐維巢狀 PathP
- 範疇化：帶 face 映射的胞腔型高階初始代數；消去子保存各維 cells
- 判定：face 引數/索引檢查、多維角落雙路化簡轉換與維度語義相等

| 符號 | 套件 | 類別 |
|---|---|---|
| `DHitCellSpec` | root | 結構 |
| `DHitCellSpec.args` | root | 欄位 |
| `DHitCellSpec.constraints` | root | 欄位 |
| `DHitCellSpec.dim_count` | root | 欄位 |
| `DHitCellSpec.faces` | root | 欄位 |
| `DHitCellSpec.name` | root | 欄位 |
| `DHitCellSpec.result_index` | root | 欄位 |
| `DHitCellSpec::equal` | root | 函數 |
| `DHitCellSpec::not_equal` | root | 函數 |
| `DHitCellSpec::to_repr` | root | 函數 |
| `DHitFaceExpr` | root | 結構 |
| `DHitFaceExpr.args` | root | 欄位 |
| `DHitFaceExpr.cell` | root | 欄位 |
| `DHitFaceExpr.dims` | root | 欄位 |
| `DHitFaceExpr::equal` | root | 函數 |
| `DHitFaceExpr::not_equal` | root | 函數 |
| `DHitFaceExpr::to_repr` | root | 函數 |
| `DHitSpec` | root | 結構 |
| `DHitSpec.cells` | root | 欄位 |
| `DHitSpec.indices` | root | 欄位 |
| `DHitSpec.level` | root | 欄位 |
| `DHitSpec.name` | root | 欄位 |
| `DHitSpec.params` | root | 欄位 |
| `DHitSpec::equal` | root | 函數 |
| `DHitSpec::not_equal` | root | 函數 |
| `DHitSpec::to_repr` | root | 函數 |
| `check_generated_hit_schemas` | root | 函數 |
| `check_hit_endpoint_conversion` | root | 函數 |
| `check_hit_schema_arguments` | root | 函數 |
| `check_hit_schema_circle_segment` | root | 函數 |
| `check_hit_schema_torus_comp` | root | 函數 |
| `check_hit_schema_validation` | root | 函數 |
| `circle_schema` | root | 函數 |
| `comp_hit_value` | root | 函數 |
| `conv_hit_cell_at` | root | 函數 |
| `conv_hit_elim_neutral` | root | 函數 |
| `conv_hit_type` | root | 函數 |
| `dhit_arg_face` | root | 函數 |
| `dhit_cell_spec` | root | 函數 |
| `dhit_face` | root | 函數 |
| `dhit_level_scheme` | root | 函數 |
| `dhit_spec` | root | 函數 |
| `eval_hit_elim` | root | 函數 |
| `eval_hit_elim_term` | root | 函數 |
| `eval_hit_intro_term` | root | 函數 |
| `eval_hit_type_term` | root | 函數 |
| `hit_arg_type` | root | 函數 |
| `hit_case_type` | root | 函數 |
| `hit_cell_result_indices` | root | 函數 |
| `hit_cell_value` | root | 函數 |
| `hit_elim_term` | root | 函數 |
| `hit_index_types` | root | 函數 |
| `hit_index_types_cached` | root | 函數 |
| `hit_intro_term` | root | 函數 |
| `hit_param_types` | root | 函數 |
| `hit_param_types_cached` | root | 函數 |
| `hit_parameter_positivity` | root | 函數 |
| `hit_result_indices` | root | 函數 |
| `hit_schema_examples` | root | 函數 |
| `hit_schema_key` | root | 函數 |
| `hit_schema_validate` | root | 函數 |
| `infer_hit_elim` | root | 函數 |
| `infer_hit_intro` | root | 函數 |
| `infer_hit_type` | root | 函數 |
| `quote_hit_cell_at` | root | 函數 |
| `quote_hit_elim_neutral` | root | 函數 |
| `quote_hit_type` | root | 函數 |
| `segment_schema` | root | 函數 |
| `torus_schema` | root | 函數 |

### 依賴 Kan 線（coe/comp）

- 規範形式：DLine{at, coe, fill}，comp=fill(1)；coe 在 Π 定義域反向、在 Σ 沿第一分量路徑
- 範疇化：型別即 Kan 纖維化結構；依賴族為 (路徑)→DLine；與子空間/Glue 線共同覆蓋全型別族
- 判定：按型別構造子遞迴；coe(r,r) 定義恆等

| 符號 | 套件 | 類別 |
|---|---|---|
| `DLine` | root | 結構 |
| `DLine.at` | root | 欄位 |
| `DLine.coe_fn` | root | 欄位 |
| `DLine.fill_fn` | root | 欄位 |
| `check_dline_dimension_substitution` | root | 函數 |
| `check_kan_all_types` | root | 函數 |
| `check_kan_coe_dependent` | root | 函數 |
| `check_kan_coe_pi_sigma` | root | 函數 |
| `check_kan_comp_tube` | root | 函數 |
| `check_kan_dep_all` | root | 函數 |
| `check_kan_embeddings` | root | 函數 |
| `dbool_not` | root | 函數 |
| `dcoe` | root | 函數 |
| `dcomp` | root | 函數 |
| `dfill` | root | 函數 |
| `dline_at` | root | 函數 |
| `dline_bool` | root | 函數 |
| `dline_bool_not_ua` | root | 函數 |
| `dline_const` | root | 函數 |
| `dline_from_maps` | root | 函數 |
| `dline_of_lty` | root | 函數 |
| `dline_of_ty` | root | 函數 |
| `dline_of_upath` | root | 函數 |
| `dline_pi` | root | 函數 |
| `dline_pi_constfam` | root | 函數 |
| `dline_rev` | root | 函數 |
| `dline_sigma` | root | 函數 |
| `dline_sigma_constfam` | root | 函數 |
| `dline_subst` | root | 函數 |
| `dline_unit` | root | 函數 |
| `dline_univ` | root | 函數 |
| `dvalue_of_ty` | root | 函數 |
| `dvalue_subst_dims` | root | 函數 |
| `dvalue_to_pval` | root | 函數 |
| `path_from` | root | 函數 |

### 精確符號代數

- 規範形式：Q 上多變量多項式規範形（合併去零排序）；分式；複符號量 (re,im)
- 範疇化：多項式戒與分式體承載矩陣代數；共軛為對合
- 判定：多項式恆等／分式交叉相乘（精確）

| 符號 | 套件 | 類別 |
|---|---|---|
| `Poly` | algebra | 結構 |
| `Poly.terms` | algebra | 欄位 |
| `PolyTerm` | algebra | 結構 |
| `PolyTerm.coeff` | algebra | 欄位 |
| `PolyTerm.exps` | algebra | 欄位 |
| `Rat` | algebra | 結構 |
| `Rat.den` | algebra | 欄位 |
| `Rat.num` | algebra | 欄位 |
| `Rat::equal` | algebra | 函數 |
| `Rat::not_equal` | algebra | 函數 |
| `Rat::to_repr` | algebra | 函數 |
| `SymC` | algebra | 結構 |
| `SymC.im` | algebra | 欄位 |
| `SymC.re` | algebra | 欄位 |
| `SymFrac` | algebra | 結構 |
| `SymFrac.den` | algebra | 欄位 |
| `SymFrac.num` | algebra | 欄位 |
| `SymMat` | algebra | 結構 |
| `SymMat.n` | algebra | 欄位 |
| `SymMat.rows` | algebra | 欄位 |
| `SymVec` | algebra | 型別別名 |
| `UPoly` | algebra | 結構 |
| `UPoly.coeffs` | algebra | 欄位 |
| `charpoly_sym` | algebra | 函數 |
| `frac_add` | algebra | 函數 |
| `frac_div` | algebra | 函數 |
| `frac_eq` | algebra | 函數 |
| `frac_int` | algebra | 函數 |
| `frac_is_zero` | algebra | 函數 |
| `frac_make` | algebra | 函數 |
| `frac_mul` | algebra | 函數 |
| `frac_neg` | algebra | 函數 |
| `frac_one` | algebra | 函數 |
| `frac_poly` | algebra | 函數 |
| `frac_rat` | algebra | 函數 |
| `frac_sub` | algebra | 函數 |
| `frac_var` | algebra | 函數 |
| `frac_zero` | algebra | 函數 |
| `int_abs` | algebra | 函數 |
| `poly_add` | algebra | 函數 |
| `poly_const` | algebra | 函數 |
| `poly_drop_atom` | algebra | 函數 |
| `poly_eq` | algebra | 函數 |
| `poly_eval_point` | algebra | 函數 |
| `poly_eval_var` | algebra | 函數 |
| `poly_insert_atom` | algebra | 函數 |
| `poly_int` | algebra | 函數 |
| `poly_is_zero` | algebra | 函數 |
| `poly_mul` | algebra | 函數 |
| `poly_neg` | algebra | 函數 |
| `poly_normalize` | algebra | 函數 |
| `poly_one` | algebra | 函數 |
| `poly_open_box` | algebra | 函數 |
| `poly_sub` | algebra | 函數 |
| `poly_subst_all` | algebra | 函數 |
| `poly_var` | algebra | 函數 |
| `poly_zero` | algebra | 函數 |
| `rat_add` | algebra | 函數 |
| `rat_big_int` | algebra | 函數 |
| `rat_div` | algebra | 函數 |
| `rat_eq` | algebra | 函數 |
| `rat_int` | algebra | 函數 |
| `rat_inv` | algebra | 函數 |
| `rat_is_one` | algebra | 函數 |
| `rat_is_zero` | algebra | 函數 |
| `rat_make` | algebra | 函數 |
| `rat_make_big` | algebra | 函數 |
| `rat_mul` | algebra | 函數 |
| `rat_neg` | algebra | 函數 |
| `rat_nth_root_exact` | algebra | 函數 |
| `rat_one` | algebra | 函數 |
| `rat_sign` | algebra | 函數 |
| `rat_sqrt_if_square` | algebra | 函數 |
| `rat_sub` | algebra | 函數 |
| `rat_to_double` | algebra | 函數 |
| `rat_zero` | algebra | 函數 |
| `sc_add` | algebra | 函數 |
| `sc_conj` | algebra | 函數 |
| `sc_eq` | algebra | 函數 |
| `sc_int` | algebra | 函數 |
| `sc_is_zero` | algebra | 函數 |
| `sc_make` | algebra | 函數 |
| `sc_mul` | algebra | 函數 |
| `sc_neg` | algebra | 函數 |
| `sc_one` | algebra | 函數 |
| `sc_rat` | algebra | 函數 |
| `sc_real_frac` | algebra | 函數 |
| `sc_scale_frac` | algebra | 函數 |
| `sc_sub` | algebra | 函數 |
| `sc_var` | algebra | 函數 |
| `sc_zero` | algebra | 函數 |
| `sym_det` | algebra | 函數 |
| `sym_inner` | algebra | 函數 |
| `sym_is_hermitian` | algebra | 函數 |
| `sym_is_idempotent` | algebra | 函數 |
| `sym_mat_add` | algebra | 函數 |
| `sym_mat_adjoint` | algebra | 函數 |
| `sym_mat_eq` | algebra | 函數 |
| `sym_mat_from_rows` | algebra | 函數 |
| `sym_mat_identity` | algebra | 函數 |
| `sym_mat_mul` | algebra | 函數 |
| `sym_mat_scale` | algebra | 函數 |
| `sym_mat_sub` | algebra | 函數 |
| `sym_mat_vec` | algebra | 函數 |
| `sym_mat_zero` | algebra | 函數 |
| `sym_outer` | algebra | 函數 |
| `sym_projector_rank_one` | algebra | 函數 |
| `sym_vec_add` | algebra | 函數 |
| `sym_vec_eq` | algebra | 函數 |
| `sym_vec_scale` | algebra | 函數 |
| `sym_vec_sub` | algebra | 函數 |
| `upoly_add` | algebra | 函數 |
| `upoly_const` | algebra | 函數 |
| `upoly_eq` | algebra | 函數 |
| `upoly_mul` | algebra | 函數 |
| `upoly_neg` | algebra | 函數 |
| `upoly_normalize` | algebra | 函數 |
| `upoly_of_rpoly` | algebra | 函數 |
| `upoly_sub` | algebra | 函數 |
| `upoly_x` | algebra | 函數 |
| `upoly_zero` | algebra | 函數 |

### 譜投影與仿射唯一填充

- 規範形式：Pₖ=qₖ(A)/qₖ(λₖ)；雙線性角插值 k00+i k10+j k01+ij k11
- 範疇化：單位分解與譜分解；雙線性是兩仿射方向的張量黏合
- 判定：首一整除（模最小多項式）與在原子 i,j 的恆等

| 符號 | 套件 | 類別 |
|---|---|---|
| `RPoly` | algebra | 結構 |
| `RPoly.coeffs` | algebra | 欄位 |
| `RPolyDiv` | algebra | 結構 |
| `RPolyDiv.quotient` | algebra | 欄位 |
| `RPolyDiv.remainder` | algebra | 欄位 |
| `SymPath` | algebra | 型別別名 |
| `SymSquare` | algebra | 型別別名 |
| `check_spectral_identities` | algebra | 函數 |
| `check_spectral_matrices` | algebra | 函數 |
| `check_symbolic_affine_filler` | algebra | 函數 |
| `check_symbolic_algebra_all` | algebra | 函數 |
| `check_symbolic_nonlinear_boundary` | algebra | 函數 |
| `check_symbolic_pruning` | algebra | 函數 |
| `rpoly_add` | algebra | 函數 |
| `rpoly_degree` | algebra | 函數 |
| `rpoly_divisible_by` | algebra | 函數 |
| `rpoly_divmod_monic` | algebra | 函數 |
| `rpoly_eq` | algebra | 函數 |
| `rpoly_eval` | algebra | 函數 |
| `rpoly_eval_mat` | algebra | 函數 |
| `rpoly_factor` | algebra | 函數 |
| `rpoly_is_zero` | algebra | 函數 |
| `rpoly_mul` | algebra | 函數 |
| `rpoly_neg` | algebra | 函數 |
| `rpoly_normalize` | algebra | 函數 |
| `rpoly_one` | algebra | 函數 |
| `rpoly_scale` | algebra | 函數 |
| `rpoly_sub` | algebra | 函數 |
| `rpoly_x` | algebra | 函數 |
| `rpoly_zero` | algebra | 函數 |
| `spectral_denominator` | algebra | 函數 |
| `spectral_minpoly` | algebra | 函數 |
| `spectral_projector_sym` | algebra | 函數 |
| `spectral_q` | algebra | 函數 |
| `sym_affine_path` | algebra | 函數 |
| `sym_bilinear_ansatz` | algebra | 函數 |
| `sym_bilinear_from_corners` | algebra | 函數 |
| `sym_frac_one_minus` | algebra | 函數 |
| `sym_hermitian2` | algebra | 函數 |
| `sym_square_fill` | algebra | 函數 |

### 句法笛卡兒閉範疇

- 規範形式：帶註記閉箭頭，其 nf_eta
- 範疇化：自由 CCC：積與指數的萬有性
- 判定：def_eq_eta 驗證範疇律

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_syntactic_category` | root | 函數 |
| `tm_comp_at` | root | 函數 |
| `tm_comp_closed` | root | 函數 |
| `tm_id_at` | root | 函數 |
| `tm_shift` | root | 函數 |

### 有限宇宙型別與值

- 規範形式：葉序／葉值列
- 範疇化：有限集合範疇中由 Bool/Unit 以積生成
- 判定：樹遞迴

| 符號 | 套件 | 類別 |
|---|---|---|
| `PVal` | root | 列舉 |
| `PVal::PVBool` | root | 構造子 |
| `PVal::PVPair` | root | 構造子 |
| `PVal::PVUnit` | root | 構造子 |
| `PVal::equal` | root | 函數 |
| `PVal::not_equal` | root | 函數 |
| `PVal::to_repr` | root | 函數 |
| `Ty` | root | 列舉 |
| `Ty::TyBool` | root | 構造子 |
| `Ty::TyProd` | root | 構造子 |
| `Ty::TyUnit` | root | 構造子 |
| `Ty::equal` | root | 函數 |
| `Ty::not_equal` | root | 函數 |
| `Ty::to_repr` | root | 函數 |
| `elems_of` | root | 函數 |
| `in_ty` | root | 函數 |
| `pval_fst` | root | 函數 |
| `pval_snd` | root | 函數 |
| `pval_to_dvalue` | root | 函數 |
| `ty_bool` | root | 函數 |
| `ty_prod` | root | 函數 |

### Wiring 符號等價

- 規範形式：帶號置換（Unit 輸出 /(−1,false)）
- 範疇化：自由對稱冪冪範疇態射；⊗／換位／結合子／單位子
- 判定：置換性 O(#葉)；相等=結構相等

| 符號 | 套件 | 類別 |
|---|---|---|
| `LeafKind` | root | 列舉 |
| `LeafKind::LKBool` | root | 構造子 |
| `LeafKind::LKUnit` | root | 構造子 |
| `LeafKind::equal` | root | 函數 |
| `LeafKind::not_equal` | root | 函數 |
| `LeafKind::to_repr` | root | 函數 |
| `LeafMap` | root | 結構 |
| `LeafMap.neg` | root | 欄位 |
| `LeafMap.src_index` | root | 欄位 |
| `LeafMap::equal` | root | 函數 |
| `LeafMap::not_equal` | root | 函數 |
| `LeafMap::to_repr` | root | 函數 |
| `Wiring` | root | 結構 |
| `Wiring.dst` | root | 欄位 |
| `Wiring.mapping` | root | 欄位 |
| `Wiring.src` | root | 欄位 |
| `check_wiring_category` | root | 函數 |
| `check_wiring_coherence` | root | 函數 |
| `flatten_pval` | root | 函數 |
| `leaf_count` | root | 函數 |
| `leaves_of_ty` | root | 函數 |
| `wiring_apply` | root | 函數 |
| `wiring_assoc` | root | 函數 |
| `wiring_comp` | root | 函數 |
| `wiring_eq` | root | 函數 |
| `wiring_id` | root | 函數 |
| `wiring_inv` | root | 函數 |
| `wiring_left_unitor` | root | 函數 |
| `wiring_not` | root | 函數 |
| `wiring_prod` | root | 函數 |
| `wiring_right_unitor` | root | 函數 |
| `wiring_swap` | root | 函數 |
| `wiring_wf` | root | 函數 |

### 同構、等價、ua、coe

- 規範形式：wiring；coe 按端點計算
- 範疇化：ua 在有限宇宙；積交換為自然性方塊
- 判定：wiring_eq 與 w;w⁻¹=id

| 符號 | 套件 | 類別 |
|---|---|---|
| `Equiv` | root | 結構 |
| `Equiv.bwd` | root | 欄位 |
| `Equiv.dst` | root | 欄位 |
| `Equiv.fwd` | root | 欄位 |
| `Equiv.src` | root | 欄位 |
| `Equiv.wiring` | root | 欄位 |
| `Iso` | root | 結構 |
| `Iso.dst` | root | 欄位 |
| `Iso.from_fn` | root | 欄位 |
| `Iso.src` | root | 欄位 |
| `Iso.to_fn` | root | 欄位 |
| `Iso.wiring` | root | 欄位 |
| `UPath` | root | 結構 |
| `UPath.equiv` | root | 欄位 |
| `check_coe_definitional` | root | 函數 |
| `check_ua_coe` | root | 函數 |
| `coe_computes` | root | 函數 |
| `coe_upath` | root | 函數 |
| `equiv_bidirectional_certified` | root | 函數 |
| `equiv_bidirectional_certified_in` | root | 函數 |
| `equiv_bool_not` | root | 函數 |
| `equiv_bwd_value` | root | 函數 |
| `equiv_comp` | root | 函數 |
| `equiv_compose_value` | root | 函數 |
| `equiv_ext_eq` | root | 函數 |
| `equiv_fun_value` | root | 函數 |
| `equiv_fwd_value` | root | 函數 |
| `equiv_id` | root | 函數 |
| `equiv_id_value` | root | 函數 |
| `equiv_inv` | root | 函數 |
| `equiv_inv_fun_value` | root | 函數 |
| `equiv_make_value` | root | 函數 |
| `equiv_of_wiring` | root | 函數 |
| `equiv_parts` | root | 函數 |
| `equiv_prod` | root | 函數 |
| `equiv_retr_type` | root | 函數 |
| `equiv_retr_value` | root | 函數 |
| `equiv_sect_type` | root | 函數 |
| `equiv_sect_value` | root | 函數 |
| `equiv_swap` | root | 函數 |
| `equiv_wf` | root | 函數 |
| `iso_bool_not` | root | 函數 |
| `iso_of_wiring` | root | 函數 |
| `iso_swap` | root | 函數 |
| `iso_to_equiv` | root | 函數 |
| `iso_to_path` | root | 函數 |
| `iso_wf` | root | 函數 |
| `swap_naturality` | root | 函數 |
| `ua` | root | 函數 |
| `ua_line_value` | root | 函數 |
| `ua_type_at` | root | 函數 |
| `ua_value` | root | 函數 |
| `upath_eq` | root | 函數 |
| `upath_left` | root | 函數 |
| `upath_right` | root | 函數 |

### PathP、離散路徑與 J

- 規範形式：規範 PathP 元（遠端為 coe 像）；離散路徑常值
- 範疇化：依賴路徑物件；J 來自常值線 coe 的恆等性
- 判定：端點與點值檢驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `DiscPath` | root | 結構 |
| `DiscPath.hi` | root | 欄位 |
| `DiscPath.lo` | root | 欄位 |
| `DiscPath.point` | root | 欄位 |
| `DiscPath.ty` | root | 欄位 |
| `Family` | root | 結構 |
| `Family.fiber` | root | 欄位 |
| `PathPVal` | root | 結構 |
| `PathPVal.at0` | root | 欄位 |
| `PathPVal.at1` | root | 欄位 |
| `PathPVal.line` | root | 欄位 |
| `PathPVal.point` | root | 欄位 |
| `check_j` | root | 函數 |
| `check_jacobi_cluster_aware_iteration` | algebra | 函數 |
| `check_pathp_exchange` | root | 函數 |
| `disc_path_sym` | root | 函數 |
| `disc_path_wf` | root | 函數 |
| `disc_samples` | root | 函數 |
| `j_elim_disc` | root | 函數 |
| `j_roundtrip` | root | 函數 |
| `pathp_canonical` | root | 函數 |
| `pathp_fst` | root | 函數 |
| `pathp_prod` | root | 函數 |
| `pathp_prod_exchange_roundtrip` | root | 函數 |
| `pathp_snd` | root | 函數 |
| `pathp_wf` | root | 函數 |
| `refl_path` | root | 函數 |

### 有限 Glue

- 規範形式：(partial, base) 對；glue_from_base 由 base 範形
- 範疇化：沿等價黏合的極限式構造；unglue 為纖維化投影
- 判定：face_sat＋相容方程

| 符號 | 套件 | 類別 |
|---|---|---|
| `GlueData` | root | 結構 |
| `GlueData.base_ty` | root | 欄位 |
| `GlueData.equiv` | root | 欄位 |
| `GlueData.face` | root | 欄位 |
| `GlueData.partial_ty` | root | 欄位 |
| `GlueElem` | root | 結構 |
| `GlueElem.base` | root | 欄位 |
| `GlueElem.partial` | root | 欄位 |
| `check_glue` | root | 函數 |
| `check_glue_equiv_quote_preserves_syntax` | root | 函數 |
| `glue_equiv_base_of` | root | 函數 |
| `glue_equiv_collapse` | root | 函數 |
| `glue_equiv_domain_face` | root | 函數 |
| `glue_equiv_partial_values` | root | 函數 |
| `glue_equiv_restrict_arg_under_face` | root | 函數 |
| `glue_equiv_store_partial` | root | 函數 |
| `glue_equiv_systems_conv` | root | 函數 |
| `glue_equiv_top_index` | root | 函數 |
| `glue_from_base` | root | 函數 |
| `glue_restrict` | root | 函數 |
| `glue_sound` | root | 函數 |
| `glue_wf` | root | 函數 |
| `make_glue` | root | 函數 |
| `unglue` | root | 函數 |

### Glue comp（有限線）

- 規範形式：輸出 (t₁, e₁(t₁))
- 範疇化：箭頭範疇 Ty²：等價線是其態射，comp 是沿線合成
- 判定：自然性方塊 wiring_eq；不相干則拒絕

| 符號 | 套件 | 類別 |
|---|---|---|
| `GlueLineFinite` | root | 結構 |
| `GlueLineFinite.a_line` | root | 欄位 |
| `GlueLineFinite.e0` | root | 欄位 |
| `GlueLineFinite.e1` | root | 欄位 |
| `GlueLineFinite.face0` | root | 欄位 |
| `GlueLineFinite.face1` | root | 欄位 |
| `GlueLineFinite.t_line` | root | 欄位 |
| `check_glue_comp_all` | root | 函數 |
| `check_glue_comp_finite` | root | 函數 |
| `check_glue_comp_vec` | root | 函數 |
| `glue_comp_finite` | root | 函數 |
| `glue_comp_finite_correct` | root | 函數 |
| `glue_data_at0` | root | 函數 |
| `glue_data_at1` | root | 函數 |
| `glue_line_coherent` | root | 函數 |

### Glue comp（子空間線）

- 規範形式：校正方塊 k=1 邊
- 範疇化：變動 retract 線上的 Kan 提升；校正為 hcomp
- 判定：邊界／帽子／落點方程（網格）

| 符號 | 套件 | 類別 |
|---|---|---|
| `GlueCompVecResult` | root | 結構 |
| `GlueCompVecResult.a_cap` | root | 欄位 |
| `GlueCompVecResult.a_cap_raw` | root | 欄位 |
| `GlueCompVecResult.a_fill_raw` | root | 欄位 |
| `GlueCompVecResult.correction` | root | 欄位 |
| `GlueCompVecResult.t_cap` | root | 欄位 |
| `GlueCompVecResult.t_fill` | root | 欄位 |
| `GlueLineVec` | root | 結構 |
| `GlueLineVec.base_line` | root | 欄位 |
| `GlueLineVec.equiv` | root | 欄位 |
| `GlueLineVec.face_active` | root | 欄位 |
| `GlueLineVec.part_line` | root | 欄位 |
| `LinEquivLine` | root | 結構 |
| `LinEquivLine.bwd` | root | 欄位 |
| `LinEquivLine.fwd` | root | 欄位 |
| `SubLine` | root | 結構 |
| `SubLine.proj` | root | 欄位 |
| `VecBox` | root | 結構 |
| `VecBox.bottom` | root | 欄位 |
| `VecBox.left` | root | 欄位 |
| `VecBox.right` | root | 欄位 |
| `cube_in_subline` | root | 函數 |
| `fill_subline` | root | 函數 |
| `glue_box_compatible` | root | 函數 |
| `glue_comp_vec` | root | 函數 |
| `glue_comp_vec_sound` | root | 函數 |
| `lin_equiv_from_unit_paths` | root | 函數 |
| `map_cube_equiv_line` | root | 函數 |
| `map_cube_matrix` | root | 函數 |
| `outer2` | root | 函數 |
| `prune_cube_subline` | root | 函數 |
| `subline_from_unit_path` | root | 函數 |
| `vec_box` | root | 函數 |
| `vec_normalize` | root | 函數 |

### BDD DAG、預算與 DPLL

- 規範形式：hash-consed DAG 節點 ID；root 的 reachable node count 為 ROBDD 大小；apply cache 於 apply_misses 超過桶數四倍時 doubling rehash；sifting 逐變量試全部插入位置並以 reachable size 衡量 並回報 initial/final/attempts/improved；CNF 以 Tseitin 門變量線性編碼；LRAT 證明步驟為帶顯式傳播提示鏈的 LratAdd/LratDelete 及 CHLRATBN v1 二進位範形
- 範疇化：布林函數在固定變量次序下的共享規範圖；apply 是格運算的 memoized 實現；watched-literal DPLL/CDCL 是面格可滿足性的搜尋判定，DRAT→LRAT 精化則是到帶顯式見證鏈證明範疇的函子提升
- 判定：同 manager root-id 相等、root≠0 的 sat、節點預算 FaceDecision、或有步數預算的 DPLL（舊掃描式與 watched-literal）；另有候選變量次序最小化與 3ⁿ 最壞節點界；watched/list DPLL 以 2^n brute force 差分驗證，sifting 以恆等哨兵避免大小同分時誤稱改善；CDCL 在 watched 傳播上加 1-UIP 子句學習、VSIDS 與 Luby 重啟、LBD 子句刪除、DRUP/DRAT 核驗、反向核心裁剪，以及 DRAT→LRAT 精化器與索引化線性時間 LRAT 檢查器；精確最佳變量序結合啟發式上界剪枝、cofactor 對稱軌道剪枝（單連通分量達 n≤20）與變量共現交互圖連通支援分解（獨立支援分量各自精確求解並拼接，單分量超限明示 exact=false）

| 符號 | 套件 | 類別 |
|---|---|---|
| `BddApplyEntry` | root | 結構 |
| `BddApplyEntry.a` | root | 欄位 |
| `BddApplyEntry.b` | root | 欄位 |
| `BddApplyEntry.op` | root | 欄位 |
| `BddApplyEntry.result` | root | 欄位 |
| `BddBestBuild` | root | 結構 |
| `BddBestBuild.built` | root | 欄位 |
| `BddBestBuild.order` | root | 欄位 |
| `BddDagFace` | root | 結構 |
| `BddDagFace.manager` | root | 欄位 |
| `BddDagFace.ok` | root | 欄位 |
| `BddDagFace.root` | root | 欄位 |
| `BddDagNode` | root | 結構 |
| `BddDagNode.hi` | root | 欄位 |
| `BddDagNode.lo` | root | 欄位 |
| `BddDagNode.rank` | root | 欄位 |
| `BddDecomposedOptimalBuild` | root | 結構 |
| `BddDecomposedOptimalBuild.active_vars` | root | 欄位 |
| `BddDecomposedOptimalBuild.built` | root | 欄位 |
| `BddDecomposedOptimalBuild.component_count` | root | 欄位 |
| `BddDecomposedOptimalBuild.exact` | root | 欄位 |
| `BddDecomposedOptimalBuild.max_component_vars` | root | 欄位 |
| `BddDecomposedOptimalBuild.order` | root | 欄位 |
| `BddDecomposedOptimalBuild.pruned_subsets` | root | 欄位 |
| `BddDecomposedOptimalBuild.size` | root | 欄位 |
| `BddDecomposedOptimalBuild.tried` | root | 欄位 |
| `BddFrontierBuild` | root | 結構 |
| `BddFrontierBuild.connected_components` | root | 欄位 |
| `BddFrontierBuild.essential_vars_lower_bound` | root | 欄位 |
| `BddFrontierBuild.frontier_cutwidth` | root | 欄位 |
| `BddFrontierBuild.manager` | root | 欄位 |
| `BddFrontierBuild.n_vars` | root | 欄位 |
| `BddFrontierBuild.order` | root | 欄位 |
| `BddFrontierBuild.reachable_nodes` | root | 欄位 |
| `BddFrontierBuild.root` | root | 欄位 |
| `BddFrontierBuild.sat_count` | root | 欄位 |
| `BddManager` | root | 結構 |
| `BddManager.apply_buckets` | root | 欄位 |
| `BddManager.apply_hits` | root | 欄位 |
| `BddManager.apply_misses` | root | 欄位 |
| `BddManager.buckets` | root | 欄位 |
| `BddManager.exceeded` | root | 欄位 |
| `BddManager.max_nodes` | root | 欄位 |
| `BddManager.mk_calls` | root | 欄位 |
| `BddManager.n` | root | 欄位 |
| `BddManager.nodes` | root | 欄位 |
| `BddManager.order` | root | 欄位 |
| `BddManager.position` | root | 欄位 |
| `BddOptimalBuild` | root | 結構 |
| `BddOptimalBuild.built` | root | 欄位 |
| `BddOptimalBuild.exact` | root | 欄位 |
| `BddOptimalBuild.order` | root | 欄位 |
| `BddOptimalBuild.size` | root | 欄位 |
| `BddOptimalBuild.tried` | root | 欄位 |
| `BddOptimizedBuild` | root | 結構 |
| `BddOptimizedBuild.attempts` | root | 欄位 |
| `BddOptimizedBuild.built` | root | 欄位 |
| `BddOptimizedBuild.improved` | root | 欄位 |
| `BddOptimizedBuild.initial_reachable` | root | 欄位 |
| `BddOptimizedBuild.order` | root | 欄位 |
| `BddOptimizedBuild.reachable` | root | 欄位 |
| `BddPrunedOptimalBuild` | root | 結構 |
| `BddPrunedOptimalBuild.active_vars` | root | 欄位 |
| `BddPrunedOptimalBuild.built` | root | 欄位 |
| `BddPrunedOptimalBuild.exact` | root | 欄位 |
| `BddPrunedOptimalBuild.incumbent_size` | root | 欄位 |
| `BddPrunedOptimalBuild.order` | root | 欄位 |
| `BddPrunedOptimalBuild.pruned_subsets` | root | 欄位 |
| `BddPrunedOptimalBuild.size` | root | 欄位 |
| `BddPrunedOptimalBuild.tried` | root | 欄位 |
| `FaceCdclProofResult` | root | 結構 |
| `FaceCdclProofResult.decision` | root | 欄位 |
| `FaceCdclProofResult.original_clauses` | root | 欄位 |
| `FaceCdclProofResult.proof_clauses` | root | 欄位 |
| `FaceCdclProofResult.proof_steps` | root | 欄位 |
| `FaceCdclProofResult.stats` | root | 欄位 |
| `FaceCdclProofStep` | root | 列舉 |
| `FaceCdclProofStep::CdclProofAdd` | root | 構造子 |
| `FaceCdclProofStep::CdclProofDelete` | root | 構造子 |
| `FaceCdclProofStep::equal` | root | 函數 |
| `FaceCdclProofStep::not_equal` | root | 函數 |
| `FaceCdclProofStep::to_repr` | root | 函數 |
| `FaceCdclResult` | root | 結構 |
| `FaceCdclResult.decision` | root | 欄位 |
| `FaceCdclResult.stats` | root | 欄位 |
| `FaceCdclStats` | root | 結構 |
| `FaceCdclStats.conflicts` | root | 欄位 |
| `FaceCdclStats.decisions` | root | 欄位 |
| `FaceCdclStats.deleted` | root | 欄位 |
| `FaceCdclStats.learned` | root | 欄位 |
| `FaceCdclStats.propagations` | root | 欄位 |
| `FaceCdclStats.restarts` | root | 欄位 |
| `FaceCdclStats::equal` | root | 函數 |
| `FaceCdclStats::not_equal` | root | 函數 |
| `FaceCdclStats::to_repr` | root | 函數 |
| `FaceCnfStats` | root | 結構 |
| `FaceCnfStats.auxiliary_variables` | root | 欄位 |
| `FaceCnfStats.clauses` | root | 欄位 |
| `FaceCnfStats.literals` | root | 欄位 |
| `FaceCnfStats.variables` | root | 欄位 |
| `FaceCnfStats::equal` | root | 函數 |
| `FaceCnfStats::not_equal` | root | 函數 |
| `FaceCnfStats::to_repr` | root | 函數 |
| `FaceDecision` | root | 列舉 |
| `FaceDecision::FaceBudgetExceeded` | root | 構造子 |
| `FaceDecision::FaceDecided` | root | 構造子 |
| `FaceDecision::equal` | root | 函數 |
| `FaceDecision::not_equal` | root | 函數 |
| `FaceDecision::to_repr` | root | 函數 |
| `FaceDrupTrimReport` | root | 結構 |
| `FaceDrupTrimReport.original_steps` | root | 欄位 |
| `FaceDrupTrimReport.steps` | root | 欄位 |
| `FaceDrupTrimReport.trimmed_steps` | root | 欄位 |
| `FaceDrupTrimReport.valid` | root | 欄位 |
| `FaceLratElaborateReport` | root | 結構 |
| `FaceLratElaborateReport.input_steps` | root | 欄位 |
| `FaceLratElaborateReport.lrat_adds` | root | 欄位 |
| `FaceLratElaborateReport.lrat_deletes` | root | 欄位 |
| `FaceLratElaborateReport.original_clauses` | root | 欄位 |
| `FaceLratElaborateReport.steps` | root | 欄位 |
| `FaceLratElaborateReport.total_hints` | root | 欄位 |
| `FaceLratElaborateReport.valid` | root | 欄位 |
| `FaceLratElaborateReport::equal` | root | 函數 |
| `FaceLratElaborateReport::not_equal` | root | 函數 |
| `FaceLratElaborateReport::to_repr` | root | 函數 |
| `FaceLratStep` | root | 列舉 |
| `FaceLratStep::LratAdd` | root | 構造子 |
| `FaceLratStep::LratDelete` | root | 構造子 |
| `FaceLratStep::equal` | root | 函數 |
| `FaceLratStep::not_equal` | root | 函數 |
| `FaceLratStep::to_repr` | root | 函數 |
| `FaceSatDecision` | root | 列舉 |
| `FaceSatDecision::FaceSat` | root | 構造子 |
| `FaceSatDecision::FaceSearchBudgetExceeded` | root | 構造子 |
| `FaceSatDecision::FaceUnsat` | root | 構造子 |
| `FaceSatDecision::equal` | root | 函數 |
| `FaceSatDecision::not_equal` | root | 函數 |
| `FaceSatDecision::to_repr` | root | 函數 |
| `bdd_dag_and` | root | 函數 |
| `bdd_dag_build_face` | root | 函數 |
| `bdd_dag_dnf_face` | root | 函數 |
| `bdd_dag_eval` | root | 函數 |
| `bdd_dag_exists` | root | 函數 |
| `bdd_dag_face_eq` | root | 函數 |
| `bdd_dag_face_le` | root | 函數 |
| `bdd_dag_false` | root | 函數 |
| `bdd_dag_forall` | root | 函數 |
| `bdd_dag_not` | root | 函數 |
| `bdd_dag_of_face` | root | 函數 |
| `bdd_dag_of_face_best` | root | 函數 |
| `bdd_dag_of_face_frontier_treewidth` | root | 函數 |
| `bdd_dag_of_face_optimal` | root | 函數 |
| `bdd_dag_of_face_optimal_decomposed` | root | 函數 |
| `bdd_dag_of_face_optimal_dp` | root | 函數 |
| `bdd_dag_of_face_optimal_pruned` | root | 函數 |
| `bdd_dag_of_face_optimized` | root | 函數 |
| `bdd_dag_or` | root | 函數 |
| `bdd_dag_reachable_count` | root | 函數 |
| `bdd_dag_restrict` | root | 函數 |
| `bdd_dag_sat_count` | root | 函數 |
| `bdd_dag_sat_face` | root | 函數 |
| `bdd_dag_true` | root | 函數 |
| `bdd_dag_var` | root | 函數 |
| `bdd_dag_witness` | root | 函數 |
| `bdd_dag_xor` | root | 函數 |
| `bdd_manager_cache_stats` | root | 函數 |
| `bdd_manager_new` | root | 函數 |
| `bdd_manager_node_count` | root | 函數 |
| `bdd_manager_with_order` | root | 函數 |
| `bdd_tree_of_dag` | root | 函數 |
| `bdd_var_order_candidates` | root | 函數 |
| `bdd_worst_case_nodes` | root | 函數 |
| `check_bdd_cost_optimizations` | root | 函數 |
| `check_bdd_dag_native_operations` | root | 函數 |
| `check_bdd_optimal_order_dp_extended` | root | 函數 |
| `check_bdd_optimal_order_exact` | root | 函數 |
| `check_cdcl_clause_learning` | root | 函數 |
| `check_cdcl_drup_proof_with_deletions` | root | 函數 |
| `check_phase14_bdd_bnb_and_cdcl_drat` | root | 函數 |
| `check_phase15_bdd_symmetry_orbit_and_decomposed_optimal` | root | 函數 |
| `check_phase15_cdcl_lrat_elaboration_and_binary_codec` | root | 函數 |
| `face_cdcl_drat_check` | root | 函數 |
| `face_cdcl_drup_check` | root | 函數 |
| `face_cdcl_drup_trim` | root | 函數 |
| `face_cdcl_elaborate_lrat` | root | 函數 |
| `face_cdcl_lrat_check` | root | 函數 |
| `face_cdcl_lrat_check_binary` | root | 函數 |
| `face_cnf_stats` | root | 函數 |
| `face_eq_cdcl` | root | 函數 |
| `face_eq_dpll` | root | 函數 |
| `face_eq_watched_dpll` | root | 函數 |
| `face_eq_within_budget` | root | 函數 |
| `face_lrat_from_binary` | root | 函數 |
| `face_lrat_to_binary` | root | 函數 |
| `face_sat_cdcl` | root | 函數 |
| `face_sat_cdcl_proof` | root | 函數 |
| `face_sat_cdcl_report` | root | 函數 |
| `face_sat_dpll` | root | 函數 |
| `face_sat_watched_dpll` | root | 函數 |

### 原始 DSystem 相容性與 first-match 範形

- 規範形式：相容系統沿用 DSystem 型別導向範形；任意 first-match 系統化為不交有效區域 DTubeNF；兩值的合意區域同時給出布林 BDD 形與保留雙端點的 Face 值形，exact repair 以 Face 值合意面截斷分支而不動端點；DSystemDsaturCliqueReport 記錄著色上界與最大團枚舉統計
- 範疇化：面相對切片中的偏元素；checked 構造是進入 composition 系統子類的反射；正常著色數 χ(G[P]) 是最大團數 ω(G[P]) 的偶圖上界
- 判定：局部脈絡轉換只在分支實際提及的相關維度上枚舉（不相干維度由 BDD cofactor 結構剪去），檢查 base 與兩兩重疊；不相容回報首個衝突；exact repair 除截斷外可依序補入；maximum completion 另先 exact-restrict，再以分支相容圖的最大團或 DSATUR 飽和度著色上界剪枝枚舉全部最大相容子系統並回報 exact

| 符號 | 套件 | 類別 |
|---|---|---|
| `DFaceConvReport` | root | 結構 |
| `DFaceConvReport.holds` | root | 欄位 |
| `DFaceConvReport.leaf_checks` | root | 欄位 |
| `DFaceConvReport.nodes_visited` | root | 欄位 |
| `DFaceConvReport.pruned_nodes` | root | 欄位 |
| `DSystemCompatibility` | root | 結構 |
| `DSystemCompatibility.branch` | root | 欄位 |
| `DSystemCompatibility.compatible` | root | 欄位 |
| `DSystemCompatibility.other_branch` | root | 欄位 |
| `DSystemCompatibility.reason` | root | 欄位 |
| `DSystemCompatibility::equal` | root | 函數 |
| `DSystemCompatibility::not_equal` | root | 函數 |
| `DSystemCompatibility::to_repr` | root | 函數 |
| `DSystemDsaturCliqueReport` | root | 結構 |
| `DSystemDsaturCliqueReport.chromatic_root_bound` | root | 欄位 |
| `DSystemDsaturCliqueReport.color_pruned_branches` | root | 欄位 |
| `DSystemDsaturCliqueReport.dsatur_visited_nodes` | root | 欄位 |
| `DSystemDsaturCliqueReport.result` | root | 欄位 |
| `DSystemDsaturCliqueReport.uncolored_visited_nodes` | root | 欄位 |
| `DSystemIncompatibility` | root | 列舉 |
| `DSystemIncompatibility::DSystemBaseIncompatible` | root | 構造子 |
| `DSystemIncompatibility::DSystemBranchesIncompatible` | root | 構造子 |
| `DSystemIncompatibility::DSystemOk` | root | 構造子 |
| `DSystemIncompatibility::equal` | root | 函數 |
| `DSystemIncompatibility::not_equal` | root | 函數 |
| `DSystemIncompatibility::to_repr` | root | 函數 |
| `DSystemRepair` | root | 結構 |
| `DSystemRepair.base_removed_region` | root | 欄位 |
| `DSystemRepair.compatible` | root | 欄位 |
| `DSystemRepair.repaired_branches` | root | 欄位 |
| `DSystemRepair.system` | root | 欄位 |
| `DSystemRepairAllMaxima` | root | 結構 |
| `DSystemRepairAllMaxima.all_compatible` | root | 欄位 |
| `DSystemRepairAllMaxima.conflict_components` | root | 欄位 |
| `DSystemRepairAllMaxima.exact` | root | 欄位 |
| `DSystemRepairAllMaxima.max_branch_count` | root | 欄位 |
| `DSystemRepairAllMaxima.systems` | root | 欄位 |
| `DSystemRepairAllMaxima.total_maximum_count` | root | 欄位 |
| `DSystemRepairExact` | root | 結構 |
| `DSystemRepairExact.base_removed_region` | root | 欄位 |
| `DSystemRepairExact.compatible` | root | 欄位 |
| `DSystemRepairExact.repaired_branches` | root | 欄位 |
| `DSystemRepairExact.system` | root | 欄位 |
| `DSystemRepairMaximum` | root | 結構 |
| `DSystemRepairMaximum.added_branches` | root | 欄位 |
| `DSystemRepairMaximum.base_removed_region` | root | 欄位 |
| `DSystemRepairMaximum.compatible` | root | 欄位 |
| `DSystemRepairMaximum.exact` | root | 欄位 |
| `DSystemRepairMaximum.rejected_candidates` | root | 欄位 |
| `DSystemRepairMaximum.repaired_branches` | root | 欄位 |
| `DSystemRepairMaximum.system` | root | 欄位 |
| `DSystemRepairSupplemented` | root | 結構 |
| `DSystemRepairSupplemented.added_branches` | root | 欄位 |
| `DSystemRepairSupplemented.base_removed_region` | root | 欄位 |
| `DSystemRepairSupplemented.compatible` | root | 欄位 |
| `DSystemRepairSupplemented.rejected_candidates` | root | 欄位 |
| `DSystemRepairSupplemented.repaired_branches` | root | 欄位 |
| `DSystemRepairSupplemented.system` | root | 欄位 |
| `DTubeNF` | root | 結構 |
| `DTubeNF.classes` | root | 欄位 |
| `DTubeNF.undefined` | root | 欄位 |
| `DTubeNFClass` | root | 結構 |
| `DTubeNFClass.path` | root | 欄位 |
| `DTubeNFClass.region` | root | 欄位 |
| `KernelizedCliqueReport` | root | 結構 |
| `KernelizedCliqueReport.clique_vertices` | root | 欄位 |
| `KernelizedCliqueReport.dominated_eliminated` | root | 欄位 |
| `KernelizedCliqueReport.max_clique_size` | root | 欄位 |
| `KernelizedCliqueReport.original_vertices` | root | 欄位 |
| `KernelizedCliqueReport.residual_kernel_vertices` | root | 欄位 |
| `KernelizedCliqueReport.universal_extracted` | root | 欄位 |
| `KernelizedCliqueReport.valid_clique` | root | 欄位 |
| `KernelizedCliqueReport::equal` | root | 函數 |
| `KernelizedCliqueReport::not_equal` | root | 函數 |
| `KernelizedCliqueReport::to_repr` | root | 函數 |
| `check_conv_under_face_relevant_descent` | root | 函數 |
| `check_dsystem_first_match_nf` | root | 函數 |
| `check_dsystem_maximum_completion` | root | 函數 |
| `check_dsystem_repair_phase9` | root | 函數 |
| `check_face_agreement_and_exact_repair` | root | 函數 |
| `check_phase14_dsystem_all_maxima_and_finite_case_split` | root | 函數 |
| `check_phase16_dsatur_and_glued_cubical_comp` | root | 函數 |
| `conv_at_under_face` | root | 函數 |
| `conv_at_under_face_in` | root | 函數 |
| `conv_at_under_face_report` | root | 函數 |
| `conv_at_under_face_report_in` | root | 函數 |
| `cubical_face_subcubes` | root | 函數 |
| `dsatur_color_order` | root | 函數 |
| `dsystem_kernelized_max_clique` | root | 函數 |
| `dsystem_repair_all_maxima` | root | 函數 |
| `dsystem_repair_all_maxima_dsatur` | root | 函數 |
| `dsystem_repair_maximum` | root | 函數 |
| `face_agreement_face` | root | 函數 |
| `face_agreement_face_sound` | root | 函數 |
| `face_agreement_region` | root | 函數 |
| `tube_paths_conv_under_face` | root | 函數 |
| `tube_paths_conv_under_face_in` | root | 函數 |

### AST 一等 Equiv 與 GlueEquiv

- 規範形式：DEquiv 攜帶 fwd/bwd/sect/retr 四項；DVGlueEquiv 攜帶完整 Equiv 分支與 base/partial 對
- 範疇化：AST 內的等價是帶同倫逆證明的同構；ua 是通往宇宙路徑的函子，GlueEquiv 是沿 partial 等價系統的黏合
- 判定：雙向檢查四個分量與兩條 PathP 證明；conversion/quote 按 Equiv 分量與分支面遞迴；沿 ua 的 coe 定義地為 fwd/bwd

| 符號 | 套件 | 類別 |
|---|---|---|
| `DEquivBranch` | root | 結構 |
| `DEquivBranch.equiv` | root | 欄位 |
| `DEquivBranch.face` | root | 欄位 |
| `DEquivBranch.ty` | root | 欄位 |
| `DEquivBranch::equal` | root | 函數 |
| `DEquivBranch::not_equal` | root | 函數 |
| `DEquivBranch::to_repr` | root | 函數 |
| `DEquivBranchValue` | root | 結構 |
| `DEquivBranchValue.equiv` | root | 欄位 |
| `DEquivBranchValue.face` | root | 欄位 |
| `DEquivBranchValue.ty` | root | 欄位 |
| `DEquivParts` | root | 結構 |
| `DEquivParts.bwd` | root | 欄位 |
| `DEquivParts.dst` | root | 欄位 |
| `DEquivParts.fwd` | root | 欄位 |
| `DEquivParts.retr` | root | 欄位 |
| `DEquivParts.sect` | root | 欄位 |
| `DEquivParts.src` | root | 欄位 |
| `DEquivTypeParts` | root | 結構 |
| `DEquivTypeParts.dst` | root | 欄位 |
| `DEquivTypeParts.level` | root | 欄位 |
| `DEquivTypeParts.src` | root | 欄位 |
| `DGlueEquivParts` | root | 結構 |
| `DGlueEquivParts.base` | root | 欄位 |
| `DGlueEquivParts.branches` | root | 欄位 |
| `DGlueEquivParts.face` | root | 欄位 |
| `DGlueEquivParts.level` | root | 欄位 |
| `as_equiv_type` | root | 函數 |
| `as_glue_equiv` | root | 函數 |
| `bool_not_equiv_term` | root | 函數 |
| `bool_not_term` | root | 函數 |
| `check_equiv_ast` | root | 函數 |
| `comp_equiv_value` | root | 函數 |
| `comp_glue_equiv_value` | root | 函數 |
| `d_check_glue_equiv_partial` | root | 函數 |
| `d_equiv_branch` | root | 函數 |
| `dequiv_branch_value` | root | 函數 |
| `infer_equiv_projection` | root | 函數 |
| `infer_equiv_ty` | root | 函數 |
| `infer_glue_equiv` | root | 函數 |
| `infer_mk_equiv` | root | 函數 |
| `infer_ua` | root | 函數 |
| `infer_unglue_equiv` | root | 函數 |
| `mk_equiv_term` | root | 函數 |

### 受檢查語義型別線

- 規範形式：DCheckedTypeLine 保存已檢查的開放型別 body、脈絡、環境與宇宙層級，不保存裸宿主函數
- 範疇化：可代換的立方型別線由句法 body 在維度環境下求值，天然與維度代換交換
- 判定：構造時以新鮮維度檢查 body : Typeᵢ；at 以維度求值，coe/comp 直接派遣 AST Kan

| 符號 | 套件 | 類別 |
|---|---|---|
| `DCheckedTypeLine` | root | 結構 |
| `DCheckedTypeLine.body` | root | 欄位 |
| `DCheckedTypeLine.constant` | root | 欄位 |
| `DCheckedTypeLine.ctx` | root | 欄位 |
| `DCheckedTypeLine.denv` | root | 欄位 |
| `DCheckedTypeLine.env` | root | 欄位 |
| `DCheckedTypeLine.level` | root | 欄位 |
| `DCheckedTypeLine.line` | root | 欄位 |
| `check_phase6_infrastructure` | root | 函數 |
| `check_semantic_dimension_substitution` | root | 函數 |
| `checked_coe_value` | root | 函數 |
| `checked_comp_value` | root | 函數 |
| `checked_constant_type_line` | root | 函數 |
| `checked_constant_type_line_closed` | root | 函數 |
| `checked_line_at` | root | 函數 |
| `checked_line_endpoints` | root | 函數 |
| `checked_line_fn` | root | 函數 |
| `checked_line_is_constant` | root | 函數 |
| `checked_line_level` | root | 函數 |
| `checked_line_quote_body` | root | 函數 |
| `checked_line_reify_closed` | root | 函數 |
| `checked_line_reparam_closed` | root | 函數 |
| `checked_type_line` | root | 函數 |
| `checked_type_line_closed` | root | 函數 |
| `checked_ua_line` | root | 函數 |

### Schema 註冊與 elaboration 快取

- 規範形式：DSchemaRegistry 中以穩定 Debug 鍵 intern 的 DInductivePlan/DHitPlan 與 telescope 前綴鏈；位元組形 CHREGBIN v2＝magic＋版本＋長度＋校驗＋與 CHMODBIN v3 共享的 DAG DTerm/schema codec payload（v1 仍可讀）
- 範疇化：schema 描述子是可共享計劃；快取只保存同一 elaboration 函數的有限圖，不改變指稱
- 判定：驗證布爾值與語義 telescope 前綴按 (term,args,args) 鍵查表；hit/miss 計數可觀察

| 符號 | 套件 | 類別 |
|---|---|---|
| `DHitPlan` | root | 結構 |
| `DHitPlan.generic_index_types` | root | 欄位 |
| `DHitPlan.generic_param_types` | root | 欄位 |
| `DHitPlan.id` | root | 欄位 |
| `DHitPlan.key` | root | 欄位 |
| `DHitPlan.spec` | root | 欄位 |
| `DHitPlan.valid` | root | 欄位 |
| `DInductivePlan` | root | 結構 |
| `DInductivePlan.generic_index_types` | root | 欄位 |
| `DInductivePlan.generic_param_types` | root | 欄位 |
| `DInductivePlan.id` | root | 欄位 |
| `DInductivePlan.key` | root | 欄位 |
| `DInductivePlan.spec` | root | 欄位 |
| `DInductivePlan.valid` | root | 欄位 |
| `DSchemaRegistry` | root | 結構 |
| `DSchemaRegistry.hit_buckets` | root | 欄位 |
| `DSchemaRegistry.hits` | root | 欄位 |
| `DSchemaRegistry.inductive_buckets` | root | 欄位 |
| `DSchemaRegistry.inductives` | root | 欄位 |
| `DSchemaRegistry.telescope_hits` | root | 欄位 |
| `DSchemaRegistry.telescope_misses` | root | 欄位 |
| `DSchemaRegistry.telescopes` | root | 欄位 |
| `DSchemaRegistry.validation_hits` | root | 欄位 |
| `DSchemaRegistry.validation_misses` | root | 欄位 |
| `DSchemaRegistryBinaryLoad` | root | 結構 |
| `DSchemaRegistryBinaryLoad.snapshot` | root | 欄位 |
| `DSchemaRegistryBinaryLoad.status` | root | 欄位 |
| `DSchemaRegistrySnapshot` | root | 結構 |
| `DSchemaRegistrySnapshot.hit_specs` | root | 欄位 |
| `DSchemaRegistrySnapshot.hit_valid` | root | 欄位 |
| `DSchemaRegistrySnapshot.inductive_specs` | root | 欄位 |
| `DSchemaRegistrySnapshot.inductive_valid` | root | 欄位 |
| `DTelescopeCacheEntry` | root | 結構 |
| `DTelescopeCacheEntry.entries` | root | 欄位 |
| `DTelescopeCacheEntry.prefix_types` | root | 欄位 |
| `DTelescopeCacheEntry.prefix_values` | root | 欄位 |
| `DTelescopeCacheEntry.types` | root | 欄位 |
| `DTelescopeCacheEntry.values` | root | 欄位 |
| `check_family_functor_persistence` | root | 函數 |
| `check_schema_registry_byte_persistence` | root | 函數 |
| `check_schema_registry_persistence` | root | 函數 |
| `default_schema_registry` | root | 常量 |

### Schema 函子、正性與歸納遞迴

- 規範形式：DPositiveFunctor 的 Id/Const/Product/Sum/List/Pi/Container/DecodedFunction/Family/SelfFamily 語法（SelfFamily 為不攜帶規格的同規格自嵌標記，支援 Bush 型非均勻遞迴，參數的 Self 型別由已建立的宿主 Self 型別給出而非佔位）及其解碼型別；DPositivityReport 記錄出現與極性；DFunctorialPositivityCert 承載語義協變律或容器同構憑證
- 範疇化：正性型別函子的初始代數與 decoded induction hypothesis；DDecode 是 Tarski 宇宙的歸納—遞迴解碼函數；多項式容器同構 Equiv(F X, Σs:S.P(s)→X) 給出嚴格正性自函子的反循環語義刻畫
- 判定：在別名展開後的 DTerm 上做極性遞迴：巢狀函子與正位置接受、負位置拒絕、未知中性族應用在無宣告時拒絕；不透明中性算子可攜帶受信的 DPositivityDeclaration、λ 驗證版或經核心型別檢查的語義憑證（反循環容器同構授予 strict_args，僅協變律授予非嚴格 positive_args）；IH 由函子遞迴生成

| 符號 | 套件 | 類別 |
|---|---|---|
| `CantorOrdinal` | root | 列舉 |
| `CantorOrdinal::COSum` | root | 構造子 |
| `CantorOrdinal::COZero` | root | 構造子 |
| `CantorOrdinal::equal` | root | 函數 |
| `CantorOrdinal::not_equal` | root | 函數 |
| `CantorOrdinal::to_repr` | root | 函數 |
| `DFunctorParamArg` | root | 列舉 |
| `DFunctorParamArg::DFunctorParamSelf` | root | 構造子 |
| `DFunctorParamArg::DFunctorParamTerm` | root | 構造子 |
| `DFunctorParamArg::equal` | root | 函數 |
| `DFunctorParamArg::not_equal` | root | 函數 |
| `DFunctorParamArg::to_repr` | root | 函數 |
| `DFunctorPositivityEvidence` | root | 列舉 |
| `DFunctorPositivityEvidence::DFunctorContainerIso` | root | 構造子 |
| `DFunctorPositivityEvidence::DFunctorCovariantLaws` | root | 構造子 |
| `DFunctorPositivityEvidence::equal` | root | 函數 |
| `DFunctorPositivityEvidence::not_equal` | root | 函數 |
| `DFunctorPositivityEvidence::to_repr` | root | 函數 |
| `DFunctorialPositivityCert` | root | 結構 |
| `DFunctorialPositivityCert.claim_strict` | root | 欄位 |
| `DFunctorialPositivityCert.evidence` | root | 欄位 |
| `DFunctorialPositivityCert.level` | root | 欄位 |
| `DFunctorialPositivityCert.univ_level` | root | 欄位 |
| `DFunctorialPositivityCert::equal` | root | 函數 |
| `DFunctorialPositivityCert::not_equal` | root | 函數 |
| `DFunctorialPositivityCert::to_repr` | root | 函數 |
| `DPositiveFunctor` | root | 列舉 |
| `DPositiveFunctor::DFunctorConst` | root | 構造子 |
| `DPositiveFunctor::DFunctorContainer` | root | 構造子 |
| `DPositiveFunctor::DFunctorFamily` | root | 構造子 |
| `DPositiveFunctor::DFunctorIdentity` | root | 構造子 |
| `DPositiveFunctor::DFunctorList` | root | 構造子 |
| `DPositiveFunctor::DFunctorPi` | root | 構造子 |
| `DPositiveFunctor::DFunctorProduct` | root | 構造子 |
| `DPositiveFunctor::DFunctorSelfFamily` | root | 構造子 |
| `DPositiveFunctor::DFunctorSigma` | root | 構造子 |
| `DPositiveFunctor::DFunctorSum` | root | 構造子 |
| `DPositiveFunctor::equal` | root | 函數 |
| `DPositiveFunctor::not_equal` | root | 函數 |
| `DPositiveFunctor::to_repr` | root | 函數 |
| `DPositivityDeclaration` | root | 結構 |
| `DPositivityDeclaration.arity` | root | 欄位 |
| `DPositivityDeclaration.head` | root | 欄位 |
| `DPositivityDeclaration.positive_args` | root | 欄位 |
| `DPositivityDeclaration.scope` | root | 欄位 |
| `DPositivityDeclaration.strict_args` | root | 欄位 |
| `DPositivityDeclaration::equal` | root | 函數 |
| `DPositivityDeclaration::not_equal` | root | 函數 |
| `DPositivityDeclaration::to_repr` | root | 函數 |
| `DPositivityReport` | root | 結構 |
| `DPositivityReport.negative_polarity` | root | 欄位 |
| `DPositivityReport.occurs` | root | 欄位 |
| `DPositivityReport.positive_polarity` | root | 欄位 |
| `DPositivityReport.strictly_positive` | root | 欄位 |
| `DPositivityReport.unknown` | root | 欄位 |
| `DPositivityReport::equal` | root | 函數 |
| `DPositivityReport::not_equal` | root | 函數 |
| `DPositivityReport::to_repr` | root | 函數 |
| `DPositivityWitness` | root | 結構 |
| `DPositivityWitness.declaration` | root | 欄位 |
| `DPositivityWitness.definition` | root | 欄位 |
| `DPositivityWitness::equal` | root | 函數 |
| `DPositivityWitness::not_equal` | root | 函數 |
| `DPositivityWitness::to_repr` | root | 函數 |
| `IndexedContainerSpec` | root | 結構 |
| `IndexedContainerSpec.constructor_out_index` | root | 欄位 |
| `IndexedContainerSpec.index_ty` | root | 欄位 |
| `IndexedContainerSpec.next_index` | root | 欄位 |
| `IndexedContainerSpec.pos_ty` | root | 欄位 |
| `IndexedContainerSpec.requested_index` | root | 欄位 |
| `IndexedContainerSpec.shape_ty` | root | 欄位 |
| `IndexedContainerSpec::equal` | root | 函數 |
| `IndexedContainerSpec::not_equal` | root | 函數 |
| `IndexedContainerSpec::to_repr` | root | 函數 |
| `cantor_ord_add` | root | 函數 |
| `cantor_ord_lt` | root | 函數 |
| `cantor_ord_nat` | root | 函數 |
| `cantor_ord_omega_pow` | root | 函數 |
| `check_container_functor_tree` | root | 函數 |
| `check_family_nested_functors` | root | 函數 |
| `check_nested_rose_tree` | root | 函數 |
| `check_phase14_positivity_witness_certificates` | root | 函數 |
| `check_self_family_positivity_fixpoint` | root | 函數 |
| `check_structural_positivity` | root | 函數 |
| `check_tarski_induction_recursion` | root | 函數 |
| `comp_schema_args_decoded` | root | 函數 |
| `compile_indexed_container_to_positive_functor` | root | 函數 |
| `container_tree_schema` | root | 函數 |
| `conv_decode_neutral` | root | 函數 |
| `conv_schema_args_full` | root | 函數 |
| `decode_term` | root | 函數 |
| `dfunctor_container` | root | 函數 |
| `dfunctor_family` | root | 函數 |
| `dfunctor_identity` | root | 函數 |
| `dfunctor_list` | root | 函數 |
| `dfunctor_param_self` | root | 函數 |
| `dfunctor_param_term` | root | 函數 |
| `dfunctor_pi` | root | 函數 |
| `dfunctor_product` | root | 函數 |
| `dfunctor_self_family` | root | 函數 |
| `dfunctor_sum` | root | 函數 |
| `dfunctorial_positivity_container_cert` | root | 函數 |
| `dfunctorial_positivity_covariant_cert` | root | 函數 |
| `dfunctorial_positivity_verify` | root | 函數 |
| `dpositivity_declaration` | root | 函數 |
| `dpositivity_declaration_from_lambda` | root | 函數 |
| `dpositivity_report` | root | 函數 |
| `dpositivity_witness` | root | 函數 |
| `dpositivity_witness_verify` | root | 函數 |
| `dterm_children` | root | 函數 |
| `dterm_family_occurs` | root | 函數 |
| `dterm_family_positivity` | root | 函數 |
| `dterm_family_positivity_declared` | root | 函數 |
| `dterm_family_strictly_positive` | root | 函數 |
| `dterm_family_strictly_positive_certified` | root | 函數 |
| `dterm_family_strictly_positive_declared` | root | 函數 |
| `dterm_family_strictly_positive_functorial` | root | 函數 |
| `dterm_shift` | root | 函數 |
| `dterm_substitute` | root | 函數 |
| `infer_decode` | root | 函數 |
| `positive_functor_ih_type` | root | 函數 |
| `positive_functor_map` | root | 函數 |
| `positive_functor_type` | root | 函數 |

### Schema 擴展：互歸納、商與宇宙多態

- 規範形式：DMutualFamily 的 Sum-indexed 合併 schema；DLevelExpr 的層級 scheme；商即帶等式 1-cell 的 HIT
- 範疇化：互相歸納族是索引和上的單一初始代數；宇宙 scheme 是層級指派的函數；商構造為高階胞腔黏合
- 判定：互構子以分量索引約束編譯並以 Σ motive 消去；scheme 依層級向量求值並可再驗證；構造子等式以 Path 約束檢查

| 符號 | 套件 | 類別 |
|---|---|---|
| `DConstructorConstraint` | root | 結構 |
| `DConstructorConstraint.lhs` | root | 欄位 |
| `DConstructorConstraint.rhs` | root | 欄位 |
| `DConstructorConstraint.ty` | root | 欄位 |
| `DConstructorConstraint::equal` | root | 函數 |
| `DConstructorConstraint::not_equal` | root | 函數 |
| `DConstructorConstraint::to_repr` | root | 函數 |
| `DHitLevelScheme` | root | 結構 |
| `DHitLevelScheme.build` | root | 欄位 |
| `DHitLevelScheme.level_arity` | root | 欄位 |
| `DHitLevelScheme.name` | root | 欄位 |
| `DHitLevelScheme.result_level` | root | 欄位 |
| `DInductiveLevelScheme` | root | 結構 |
| `DInductiveLevelScheme.build` | root | 欄位 |
| `DInductiveLevelScheme.level_arity` | root | 欄位 |
| `DInductiveLevelScheme.name` | root | 欄位 |
| `DInductiveLevelScheme.result_level` | root | 欄位 |
| `DLevelExpr` | root | 列舉 |
| `DLevelExpr::DLevelConst` | root | 構造子 |
| `DLevelExpr::DLevelMax` | root | 構造子 |
| `DLevelExpr::DLevelSucc` | root | 構造子 |
| `DLevelExpr::DLevelVar` | root | 構造子 |
| `DLevelExpr::equal` | root | 函數 |
| `DLevelExpr::not_equal` | root | 函數 |
| `DLevelExpr::to_repr` | root | 函數 |
| `DMutualFamily` | root | 結構 |
| `DMutualFamily.combined` | root | 欄位 |
| `DMutualFamily.components` | root | 欄位 |
| `DMutualFamily.ctor_offsets` | root | 欄位 |
| `DMutualFamily.name` | root | 欄位 |
| `check_schema_extensions` | root | 函數 |
| `circle_level_scheme` | root | 函數 |
| `compile_mutual_inductive` | root | 函數 |
| `cube3_schema` | root | 函數 |
| `dlevel_eval` | root | 函數 |
| `dlevel_hit_decl` | root | 函數 |
| `dlevel_inductive_decl` | root | 函數 |
| `dlevel_term_decl` | root | 函數 |
| `equal_nat_pair_schema` | root | 函數 |
| `even_odd_components` | root | 函數 |
| `even_odd_family` | root | 函數 |
| `instantiate_hit_level_scheme` | root | 函數 |
| `instantiate_inductive_level_scheme` | root | 函數 |
| `instantiate_level_hit_decl` | root | 函數 |
| `instantiate_level_inductive_decl` | root | 函數 |
| `instantiate_level_term_decl` | root | 函數 |
| `list_level_scheme` | root | 函數 |
| `mutual_ctor_index` | root | 函數 |
| `mutual_decl_elaborate` | root | 函數 |
| `mutual_decl_positivity` | root | 函數 |
| `mutual_intro_term` | root | 函數 |
| `mutual_intro_value` | root | 函數 |
| `mutual_motive_function` | root | 函數 |
| `mutual_nat_term` | root | 函數 |
| `mutual_nat_value` | root | 函數 |
| `mutual_type_term` | root | 函數 |
| `quotient_eq_term` | root | 函數 |
| `quotient_schema` | root | 函數 |
| `rose_tree_schema` | root | 函數 |
| `tarski_universe_schema` | root | 函數 |
| `tree_forest_components` | root | 函數 |
| `tree_forest_family` | root | 函數 |

### 精確單變量多項式與有理矩陣

- 規範形式：QPoly 的升冪稠密係數（尾零去除）；QMat 的有理列之列；RREF 與 pivot 列
- 範疇化：Q[x] 歐氏環與 Qⁿ 線性範疇；特徵/最小多項式是矩陣代數的表示不變量
- 判定：乘法在稀疏輸入走非零卷積、稠密輸入走公分母 BigInt 整係數縮放（schoolbook/Karatsuba 視項數而定）再除回，冪次走平方乘法；primitive pseudo-remainder gcd、Yun 重因數分解、有理根定理、Faddeev–LeVerrier、RREF；相等全為有理結構相等

| 符號 | 套件 | 類別 |
|---|---|---|
| `BerkowitzCrtReport` | algebra | 結構 |
| `BerkowitzCrtReport.charpoly` | algebra | 欄位 |
| `BerkowitzCrtReport.dim` | algebra | 欄位 |
| `BerkowitzCrtReport.hadamard_coeff_bound` | algebra | 欄位 |
| `BerkowitzCrtReport.modulus_product` | algebra | 欄位 |
| `BerkowitzCrtReport.primes_used` | algebra | 欄位 |
| `BerkowitzCrtReport::equal` | algebra | 函數 |
| `BerkowitzCrtReport::not_equal` | algebra | 函數 |
| `BerkowitzCrtReport::to_repr` | algebra | 函數 |
| `QMat` | algebra | 結構 |
| `QMat.n` | algebra | 欄位 |
| `QMat.rows` | algebra | 欄位 |
| `QMat::equal` | algebra | 函數 |
| `QMat::not_equal` | algebra | 函數 |
| `QMat::to_repr` | algebra | 函數 |
| `QPoly` | algebra | 結構 |
| `QPoly.coeffs` | algebra | 欄位 |
| `QPoly::equal` | algebra | 函數 |
| `QPoly::not_equal` | algebra | 函數 |
| `QPoly::to_repr` | algebra | 函數 |
| `QPolyDiv` | algebra | 結構 |
| `QPolyDiv.quotient` | algebra | 欄位 |
| `QPolyDiv.remainder` | algebra | 欄位 |
| `QPolyExtGcd` | algebra | 結構 |
| `QPolyExtGcd.g` | algebra | 欄位 |
| `QPolyExtGcd.s` | algebra | 欄位 |
| `QPolyExtGcd.t` | algebra | 欄位 |
| `QPolyFactor` | algebra | 結構 |
| `QPolyFactor.factor` | algebra | 欄位 |
| `QPolyFactor.multiplicity` | algebra | 欄位 |
| `QPolyRationalFactorization` | algebra | 結構 |
| `QPolyRationalFactorization.multiplicities` | algebra | 欄位 |
| `QPolyRationalFactorization.residual` | algebra | 欄位 |
| `QPolyRationalFactorization.roots` | algebra | 欄位 |
| `QRref` | algebra | 結構 |
| `QRref.pivots` | algebra | 欄位 |
| `QRref.rank` | algebra | 欄位 |
| `QRref.rows` | algebra | 欄位 |
| `QVec` | algebra | 型別別名 |
| `check_qpoly_fast_arithmetic` | algebra | 函數 |
| `qmat_add` | algebra | 函數 |
| `qmat_charpoly` | algebra | 函數 |
| `qmat_charpoly_berkowitz_crt` | algebra | 函數 |
| `qmat_column_basis` | algebra | 函數 |
| `qmat_det` | algebra | 函數 |
| `qmat_eq` | algebra | 函數 |
| `qmat_from_columns` | algebra | 函數 |
| `qmat_from_int_rows` | algebra | 函數 |
| `qmat_from_rows` | algebra | 函數 |
| `qmat_identity` | algebra | 函數 |
| `qmat_inverse` | algebra | 函數 |
| `qmat_is_zero` | algebra | 函數 |
| `qmat_minimal_polynomial` | algebra | 函數 |
| `qmat_mul` | algebra | 函數 |
| `qmat_nullity` | algebra | 函數 |
| `qmat_nullspace` | algebra | 函數 |
| `qmat_poly_eval` | algebra | 函數 |
| `qmat_pow` | algebra | 函數 |
| `qmat_rank` | algebra | 函數 |
| `qmat_scalar` | algebra | 函數 |
| `qmat_scale` | algebra | 函數 |
| `qmat_sub` | algebra | 函數 |
| `qmat_trace` | algebra | 函數 |
| `qmat_vec` | algebra | 函數 |
| `qmat_zero` | algebra | 函數 |
| `qpoly_add` | algebra | 函數 |
| `qpoly_coeff` | algebra | 函數 |
| `qpoly_const` | algebra | 函數 |
| `qpoly_degree` | algebra | 函數 |
| `qpoly_derivative` | algebra | 函數 |
| `qpoly_div_exact` | algebra | 函數 |
| `qpoly_divmod` | algebra | 函數 |
| `qpoly_eq` | algebra | 函數 |
| `qpoly_eval` | algebra | 函數 |
| `qpoly_extgcd` | algebra | 函數 |
| `qpoly_factor` | algebra | 函數 |
| `qpoly_factor_degree_candidates` | algebra | 函數 |
| `qpoly_factor_rational_roots` | algebra | 函數 |
| `qpoly_gcd` | algebra | 函數 |
| `qpoly_int` | algebra | 函數 |
| `qpoly_integer_coeffs_big` | algebra | 函數 |
| `qpoly_irreducibility_certificate` | algebra | 函數 |
| `qpoly_irreducibility_certificate_check` | algebra | 函數 |
| `qpoly_irreducible_by_mod_patterns` | algebra | 函數 |
| `qpoly_irreducible_certified` | algebra | 函數 |
| `qpoly_is_one` | algebra | 函數 |
| `qpoly_is_squarefree` | algebra | 函數 |
| `qpoly_is_zero` | algebra | 函數 |
| `qpoly_leading` | algebra | 函數 |
| `qpoly_mod` | algebra | 函數 |
| `qpoly_mod_degree_patterns` | algebra | 函數 |
| `qpoly_monic` | algebra | 函數 |
| `qpoly_mul` | algebra | 函數 |
| `qpoly_neg` | algebra | 函數 |
| `qpoly_normalize` | algebra | 函數 |
| `qpoly_one` | algebra | 函數 |
| `qpoly_pow` | algebra | 函數 |
| `qpoly_primitive_part` | algebra | 函數 |
| `qpoly_pseudo_remainder` | algebra | 函數 |
| `qpoly_rational_roots` | algebra | 函數 |
| `qpoly_root_factor` | algebra | 函數 |
| `qpoly_root_multiplicity` | algebra | 函數 |
| `qpoly_scale` | algebra | 函數 |
| `qpoly_squarefree_factorization` | algebra | 函數 |
| `qpoly_squarefree_part` | algebra | 函數 |
| `qpoly_sub` | algebra | 函數 |
| `qpoly_x` | algebra | 函數 |
| `qpoly_zero` | algebra | 函數 |
| `qrows_nullspace` | algebra | 函數 |
| `qrows_rank` | algebra | 函數 |
| `qrows_rref` | algebra | 函數 |
| `qvec_add` | algebra | 函數 |
| `qvec_eq` | algebra | 函數 |
| `qvec_in_span` | algebra | 函數 |
| `qvec_independent_subset` | algebra | 函數 |
| `qvec_is_zero` | algebra | 函數 |
| `qvec_rank` | algebra | 函數 |
| `qvec_scale` | algebra | 函數 |
| `qvec_sub` | algebra | 函數 |
| `qvec_zero` | algebra | 函數 |

### 代數擴張與根式範形

- 規範形式：QuadNum 的 a+b√d（d 無平方因數）；CubicNum 的 a+b∛m+c∛m²（m 無立方因數）；TriquadNum 在三個平方類獨立生成元的 8 維基底；MultiQuadNum 在至多四個生成元的 16 維基底並以平方類 span 對齊；AlgNum 的 Q[x]/(m) 餘式多項式
- 範疇化：二次擴張與一般有限代數擴張體；範數/跡由乘法矩陣行列式/跡給出
- 判定：模極小多項式的剩餘算術與擴張歐氏求逆；multiquadratic 逆元以 Galois 共軛乘積、判號以二進區間細化；根式去巢以平方判別；相等為對齊基底後係數相等

| 符號 | 套件 | 類別 |
|---|---|---|
| `AlgNum` | algebra | 結構 |
| `AlgNum.modulus` | algebra | 欄位 |
| `AlgNum.poly` | algebra | 欄位 |
| `AlgNum::equal` | algebra | 函數 |
| `AlgNum::not_equal` | algebra | 函數 |
| `AlgNum::to_repr` | algebra | 函數 |
| `CubicNum` | algebra | 結構 |
| `CubicNum.a` | algebra | 欄位 |
| `CubicNum.b` | algebra | 欄位 |
| `CubicNum.c` | algebra | 欄位 |
| `CubicNum.m` | algebra | 欄位 |
| `CubicNum::equal` | algebra | 函數 |
| `CubicNum::not_equal` | algebra | 函數 |
| `CubicNum::to_repr` | algebra | 函數 |
| `MultiQuadNum` | algebra | 結構 |
| `MultiQuadNum.basis` | algebra | 欄位 |
| `MultiQuadNum.coeffs` | algebra | 欄位 |
| `MultiQuadNum::equal` | algebra | 函數 |
| `MultiQuadNum::not_equal` | algebra | 函數 |
| `MultiQuadNum::to_repr` | algebra | 函數 |
| `QuadNum` | algebra | 結構 |
| `QuadNum.a` | algebra | 欄位 |
| `QuadNum.b` | algebra | 欄位 |
| `QuadNum.d` | algebra | 欄位 |
| `QuadNum::equal` | algebra | 函數 |
| `QuadNum::not_equal` | algebra | 函數 |
| `QuadNum::to_repr` | algebra | 函數 |
| `RealAlgRadical` | algebra | 結構 |
| `RealAlgRadical.lower` | algebra | 欄位 |
| `RealAlgRadical.minpoly` | algebra | 欄位 |
| `RealAlgRadical.root_index` | algebra | 欄位 |
| `RealAlgRadical.upper` | algebra | 欄位 |
| `RealAlgRadical::equal` | algebra | 函數 |
| `RealAlgRadical::not_equal` | algebra | 函數 |
| `RealAlgRadical::to_repr` | algebra | 函數 |
| `TriquadNum` | algebra | 結構 |
| `TriquadNum.coeffs` | algebra | 欄位 |
| `TriquadNum.gens` | algebra | 欄位 |
| `TriquadNum::equal` | algebra | 函數 |
| `TriquadNum::not_equal` | algebra | 函數 |
| `TriquadNum::to_repr` | algebra | 函數 |
| `alg_add` | algebra | 函數 |
| `alg_coeffs` | algebra | 函數 |
| `alg_compatible` | algebra | 函數 |
| `alg_div` | algebra | 函數 |
| `alg_eq` | algebra | 函數 |
| `alg_eval_qpoly` | algebra | 函數 |
| `alg_ext_degree` | algebra | 函數 |
| `alg_generator` | algebra | 函數 |
| `alg_int` | algebra | 函數 |
| `alg_inv` | algebra | 函數 |
| `alg_is_zero` | algebra | 函數 |
| `alg_make` | algebra | 函數 |
| `alg_minimal_polynomial` | algebra | 函數 |
| `alg_mul` | algebra | 函數 |
| `alg_multiplication_matrix` | algebra | 函數 |
| `alg_neg` | algebra | 函數 |
| `alg_norm` | algebra | 函數 |
| `alg_nth_root_in_field` | algebra | 函數 |
| `alg_of_quad` | algebra | 函數 |
| `alg_one` | algebra | 函數 |
| `alg_pow` | algebra | 函數 |
| `alg_rat` | algebra | 函數 |
| `alg_rebase_to_minimal` | algebra | 函數 |
| `alg_scale_rat` | algebra | 函數 |
| `alg_sqrt_in_field` | algebra | 函數 |
| `alg_sqrt_rat` | algebra | 函數 |
| `alg_sub` | algebra | 函數 |
| `alg_trace` | algebra | 函數 |
| `alg_zero` | algebra | 函數 |
| `check_algebraic_radicals_and_rank6_multiquad` | algebra | 函數 |
| `check_multiquadratic_tower` | algebra | 函數 |
| `check_phase14_algebraic_radicals_and_rank6_multiquad` | root | 函數 |
| `cubic_add` | algebra | 函數 |
| `cubic_cuberoot_rat` | algebra | 函數 |
| `cubic_div` | algebra | 函數 |
| `cubic_eq` | algebra | 函數 |
| `cubic_generator` | algebra | 函數 |
| `cubic_inv` | algebra | 函數 |
| `cubic_is_rat` | algebra | 函數 |
| `cubic_is_zero` | algebra | 函數 |
| `cubic_make` | algebra | 函數 |
| `cubic_mul` | algebra | 函數 |
| `cubic_neg` | algebra | 函數 |
| `cubic_norm` | algebra | 函數 |
| `cubic_rat` | algebra | 函數 |
| `cubic_sign` | algebra | 函數 |
| `cubic_sub` | algebra | 函數 |
| `multiquad_add` | algebra | 函數 |
| `multiquad_add_upto` | algebra | 函數 |
| `multiquad_align` | algebra | 函數 |
| `multiquad_align_upto` | algebra | 函數 |
| `multiquad_div` | algebra | 函數 |
| `multiquad_eq` | algebra | 函數 |
| `multiquad_eq_upto` | algebra | 函數 |
| `multiquad_inv` | algebra | 函數 |
| `multiquad_is_zero` | algebra | 函數 |
| `multiquad_make` | algebra | 函數 |
| `multiquad_make_upto` | algebra | 函數 |
| `multiquad_mul` | algebra | 函數 |
| `multiquad_mul_upto` | algebra | 函數 |
| `multiquad_neg` | algebra | 函數 |
| `multiquad_rat` | algebra | 函數 |
| `multiquad_rational_square_adjustment` | algebra | 函數 |
| `multiquad_sign` | algebra | 函數 |
| `multiquad_sqrt_extended` | algebra | 函數 |
| `multiquad_sqrt_extended_upto` | algebra | 函數 |
| `multiquad_sqrt_in_field` | algebra | 函數 |
| `multiquad_sqrt_rat` | algebra | 函數 |
| `multiquad_sub` | algebra | 函數 |
| `multiquad_zero` | algebra | 函數 |
| `quad_add` | algebra | 函數 |
| `quad_compatible` | algebra | 函數 |
| `quad_denested_cuberoot` | algebra | 函數 |
| `quad_denested_sqrt` | algebra | 函數 |
| `quad_div` | algebra | 函數 |
| `quad_eq` | algebra | 函數 |
| `quad_int` | algebra | 函數 |
| `quad_inv` | algebra | 函數 |
| `quad_is_zero` | algebra | 函數 |
| `quad_make` | algebra | 函數 |
| `quad_make_big` | algebra | 函數 |
| `quad_mul` | algebra | 函數 |
| `quad_neg` | algebra | 函數 |
| `quad_norm` | algebra | 函數 |
| `quad_nth_root_in_field` | algebra | 函數 |
| `quad_one` | algebra | 函數 |
| `quad_pow` | algebra | 函數 |
| `quad_rat` | algebra | 函數 |
| `quad_sqrt_int` | algebra | 函數 |
| `quad_sqrt_rat` | algebra | 函數 |
| `quad_sub` | algebra | 函數 |
| `quad_to_double` | root | 函數 |
| `quad_trace` | algebra | 函數 |
| `quad_zero` | algebra | 函數 |
| `real_alg_add` | algebra | 函數 |
| `real_alg_div` | algebra | 函數 |
| `real_alg_eq` | algebra | 函數 |
| `real_alg_inv` | algebra | 函數 |
| `real_alg_mul` | algebra | 函數 |
| `real_alg_neg` | algebra | 函數 |
| `real_alg_nth_root` | algebra | 函數 |
| `real_alg_of_rat` | algebra | 函數 |
| `real_alg_sign` | algebra | 函數 |
| `real_alg_sub` | algebra | 函數 |
| `triquad_add` | algebra | 函數 |
| `triquad_align` | algebra | 函數 |
| `triquad_div` | algebra | 函數 |
| `triquad_embed_biquad` | algebra | 函數 |
| `triquad_eq` | algebra | 函數 |
| `triquad_inv` | algebra | 函數 |
| `triquad_is_zero` | algebra | 函數 |
| `triquad_make` | algebra | 函數 |
| `triquad_mul` | algebra | 函數 |
| `triquad_neg` | algebra | 函數 |
| `triquad_reembed` | algebra | 函數 |
| `triquad_sign` | algebra | 函數 |
| `triquad_sqrt_of_biquad` | algebra | 函數 |
| `triquad_sub` | algebra | 函數 |

### 廣義特徵空間與 Jordan 理論

- 規範形式：(A−λI) 冪次零化列、遞增 nullity、Jordan 塊大小與鏈底基；PJP⁻¹=A
- 範疇化：主分解是互質多項式因子的單位分解；Jordan 型是相似等價的完全不變量片斷
- 判定：以特徵多項式重數、冪次核維度與鏈提升精確判定；不可在 Q 完全分裂者回報殘餘因子，AlgMat 在擴張上續行

| 符號 | 套件 | 類別 |
|---|---|---|
| `AlgGeneralizedEigenspace` | algebra | 結構 |
| `AlgGeneralizedEigenspace.algebraic_multiplicity` | algebra | 欄位 |
| `AlgGeneralizedEigenspace.basis` | algebra | 欄位 |
| `AlgGeneralizedEigenspace.block_sizes` | algebra | 欄位 |
| `AlgGeneralizedEigenspace.eigenvalue` | algebra | 欄位 |
| `AlgGeneralizedEigenspace.geometric_multiplicity` | algebra | 欄位 |
| `AlgGeneralizedEigenspace.index` | algebra | 欄位 |
| `AlgGeneralizedEigenspace.nullities` | algebra | 欄位 |
| `AlgJordanDecomposition` | algebra | 結構 |
| `AlgJordanDecomposition.block_sizes` | algebra | 欄位 |
| `AlgJordanDecomposition.eigenvalues` | algebra | 欄位 |
| `AlgJordanDecomposition.j` | algebra | 欄位 |
| `AlgJordanDecomposition.p` | algebra | 欄位 |
| `AlgMat` | algebra | 結構 |
| `AlgMat.modulus` | algebra | 欄位 |
| `AlgMat.n` | algebra | 欄位 |
| `AlgMat.rows` | algebra | 欄位 |
| `AlgRref` | algebra | 結構 |
| `AlgRref.pivots` | algebra | 欄位 |
| `AlgRref.rank` | algebra | 欄位 |
| `AlgRref.rows` | algebra | 欄位 |
| `AlgVec` | algebra | 型別別名 |
| `QGeneralizedEigenspace` | algebra | 結構 |
| `QGeneralizedEigenspace.algebraic_multiplicity` | algebra | 欄位 |
| `QGeneralizedEigenspace.basis` | algebra | 欄位 |
| `QGeneralizedEigenspace.block_sizes` | algebra | 欄位 |
| `QGeneralizedEigenspace.eigenvalue` | algebra | 欄位 |
| `QGeneralizedEigenspace.geometric_multiplicity` | algebra | 欄位 |
| `QGeneralizedEigenspace.index` | algebra | 欄位 |
| `QGeneralizedEigenspace.nullities` | algebra | 欄位 |
| `QJordanDecomposition` | algebra | 結構 |
| `QJordanDecomposition.block_sizes` | algebra | 欄位 |
| `QJordanDecomposition.eigenvalues` | algebra | 欄位 |
| `QJordanDecomposition.j` | algebra | 欄位 |
| `QJordanDecomposition.p` | algebra | 欄位 |
| `QPrimaryProjector` | algebra | 結構 |
| `QPrimaryProjector.cofactor` | algebra | 欄位 |
| `QPrimaryProjector.complement` | algebra | 欄位 |
| `QPrimaryProjector.factor` | algebra | 欄位 |
| `QPrimaryProjector.polynomial` | algebra | 欄位 |
| `QPrimaryProjector.projector` | algebra | 欄位 |
| `algmat_Jordan_chains` | algebra | 函數 |
| `algmat_Jordan_decomposition` | algebra | 函數 |
| `algmat_charpoly` | algebra | 函數 |
| `algmat_eigenvalue_multiplicity` | algebra | 函數 |
| `algmat_eq` | algebra | 函數 |
| `algmat_from_columns` | algebra | 函數 |
| `algmat_from_qmat` | algebra | 函數 |
| `algmat_generalized_eigenspace` | algebra | 函數 |
| `algmat_identity` | algebra | 函數 |
| `algmat_mul` | algebra | 函數 |
| `algmat_nullity` | algebra | 函數 |
| `algmat_nullspace` | algebra | 函數 |
| `algmat_pow` | algebra | 函數 |
| `algmat_rank` | algebra | 函數 |
| `algmat_scalar` | algebra | 函數 |
| `algmat_sub` | algebra | 函數 |
| `algmat_trace` | algebra | 函數 |
| `algmat_vec` | algebra | 函數 |
| `algmat_zero` | algebra | 函數 |
| `algrows_nullspace` | algebra | 函數 |
| `algrows_rref` | algebra | 函數 |
| `algvec_in_span` | algebra | 函數 |
| `algvec_is_zero` | algebra | 函數 |
| `algvec_rank` | algebra | 函數 |
| `algvec_zero` | algebra | 函數 |
| `check_algebraic_extensions_and_Jordan` | algebra | 函數 |
| `qmat_Jordan_chains` | algebra | 函數 |
| `qmat_Jordan_decomposition` | algebra | 函數 |
| `qmat_Jordan_decomposition_auto` | algebra | 函數 |
| `qmat_diagonalizable_at` | algebra | 函數 |
| `qmat_eigen_nullities` | algebra | 函數 |
| `qmat_eigenvalue_multiplicity` | algebra | 函數 |
| `qmat_generalized_eigenspace` | algebra | 函數 |
| `qmat_generalized_projector` | algebra | 函數 |
| `qmat_is_diagonalizable_rational` | algebra | 函數 |
| `qmat_primary_projector` | algebra | 函數 |
| `qmat_primary_subspace_basis` | algebra | 函數 |
| `qmat_vector_annihilator` | algebra | 函數 |

### 認證數值影子與精確立方體

- 規範形式：QuadC=QuadNum+i·QuadNum；CertMat 與次數≤2 的 CertPath/CertSquare 係數
- 範疇化：精確複二次矩陣代數與多項式立方體；Double 矩陣只是精確影子的近似表示
- 判定：P²=P、P†=P、正交分解與盒邊界以精確結構相等驗證；數值一致性只量測對影子的偏差與浮點 residual

| 符號 | 套件 | 類別 |
|---|---|---|
| `AlgC` | root | 結構 |
| `AlgC.im` | root | 欄位 |
| `AlgC.re` | root | 欄位 |
| `AlgCertMat` | root | 結構 |
| `AlgCertMat.n` | root | 欄位 |
| `AlgCertMat.rows` | root | 欄位 |
| `AlgCertPath` | root | 結構 |
| `AlgCertPath.coeffs` | root | 欄位 |
| `AlgCertSquare` | root | 結構 |
| `AlgCertSquare.coeffs` | root | 欄位 |
| `AlgCertVec` | root | 型別別名 |
| `CertMat` | root | 結構 |
| `CertMat.n` | root | 欄位 |
| `CertMat.rows` | root | 欄位 |
| `CertPath` | root | 結構 |
| `CertPath.coeffs` | root | 欄位 |
| `CertSquare` | root | 結構 |
| `CertSquare.coeffs` | root | 欄位 |
| `CertVec` | root | 型別別名 |
| `NumericProjectorCertificate` | root | 結構 |
| `NumericProjectorCertificate.exact` | root | 欄位 |
| `NumericProjectorCertificate.max_deviation` | root | 欄位 |
| `NumericProjectorCertificate.numeric_residual` | root | 欄位 |
| `NumericProjectorCertificate.ok` | root | 欄位 |
| `NumericProjectorCertificate.tolerance` | root | 欄位 |
| `ProjectorCertificate` | root | 結構 |
| `ProjectorCertificate.complement_projector` | root | 欄位 |
| `ProjectorCertificate.hermitian` | root | 欄位 |
| `ProjectorCertificate.idempotent` | root | 欄位 |
| `ProjectorCertificate.matrix` | root | 欄位 |
| `ProjectorCertificate.orthogonal_split` | root | 欄位 |
| `ProjectorCertificate.trace` | root | 欄位 |
| `QuadC` | root | 結構 |
| `QuadC.im` | root | 欄位 |
| `QuadC.re` | root | 欄位 |
| `QuadC::equal` | root | 函數 |
| `QuadC::not_equal` | root | 函數 |
| `QuadC::to_repr` | root | 函數 |
| `alg_cert_in_image` | root | 函數 |
| `alg_cert_inner` | root | 函數 |
| `alg_cert_is_projector` | root | 函數 |
| `alg_cert_mat_adjoint` | root | 函數 |
| `alg_cert_mat_eq` | root | 函數 |
| `alg_cert_mat_mul` | root | 函數 |
| `alg_cert_mat_vec` | root | 函數 |
| `alg_cert_outer` | root | 函數 |
| `alg_cert_path_eval` | root | 函數 |
| `alg_cert_path_in_image` | root | 函數 |
| `alg_cert_square_eval` | root | 函數 |
| `alg_cert_square_in_image` | root | 函數 |
| `alg_cert_vec_eq` | root | 函數 |
| `alg_cert_vec_scale` | root | 函數 |
| `algc_add` | root | 函數 |
| `algc_conj` | root | 函數 |
| `algc_eq` | root | 函數 |
| `algc_i` | root | 函數 |
| `algc_mul` | root | 函數 |
| `algc_one` | root | 函數 |
| `algc_real` | root | 函數 |
| `algc_scale_alg` | root | 函數 |
| `algc_zero` | root | 函數 |
| `cert_complement` | root | 函數 |
| `cert_eigenspace_kan_sound` | root | 函數 |
| `cert_example_projector` | root | 函數 |
| `cert_example_unit` | root | 函數 |
| `cert_filler_respects_box` | root | 函數 |
| `cert_in_image` | root | 函數 |
| `cert_in_kernel` | root | 函數 |
| `cert_inner` | root | 函數 |
| `cert_is_hermitian` | root | 函數 |
| `cert_is_idempotent` | root | 函數 |
| `cert_is_projector` | root | 函數 |
| `cert_mat_add` | root | 函數 |
| `cert_mat_adjoint` | root | 函數 |
| `cert_mat_eq` | root | 函數 |
| `cert_mat_from_rows` | root | 函數 |
| `cert_mat_identity` | root | 函數 |
| `cert_mat_mul` | root | 函數 |
| `cert_mat_sub` | root | 函數 |
| `cert_mat_to_numeric` | root | 函數 |
| `cert_mat_trace` | root | 函數 |
| `cert_mat_vec` | root | 函數 |
| `cert_mat_zero` | root | 函數 |
| `cert_open_box_wf` | root | 函數 |
| `cert_outer` | root | 函數 |
| `cert_path_end` | root | 函數 |
| `cert_path_eq` | root | 函數 |
| `cert_path_in_image` | root | 函數 |
| `cert_path_is_affine` | root | 函數 |
| `cert_path_line` | root | 函數 |
| `cert_path_start` | root | 函數 |
| `cert_path_sym` | root | 函數 |
| `cert_pruning_repairs_filler` | root | 函數 |
| `cert_square_add` | root | 函數 |
| `cert_square_apply` | root | 函數 |
| `cert_square_bilinear` | root | 函數 |
| `cert_square_bump` | root | 函數 |
| `cert_square_face` | root | 函數 |
| `cert_square_fill` | root | 函數 |
| `cert_square_in_image` | root | 函數 |
| `cert_vec_add` | root | 函數 |
| `cert_vec_eq` | root | 函數 |
| `cert_vec_scale` | root | 函數 |
| `cert_vec_sub` | root | 函數 |
| `cert_vec_zero` | root | 函數 |
| `certify_numeric_projector` | root | 函數 |
| `certify_projector` | root | 函數 |
| `check_bdd_and_certified_numeric` | root | 函數 |
| `check_certified_algebraic_numeric` | root | 函數 |
| `cube_root_two_modulus` | root | 函數 |
| `cube_root_unit_vector` | root | 函數 |
| `double_dyadic_interval` | root | 函數 |
| `numeric_mat_max_deviation` | root | 函數 |
| `numeric_projector_residual` | root | 函數 |
| `qcc_add` | root | 函數 |
| `qcc_conj` | root | 函數 |
| `qcc_eq` | root | 函數 |
| `qcc_i` | root | 函數 |
| `qcc_is_zero` | root | 函數 |
| `qcc_mul` | root | 函數 |
| `qcc_neg` | root | 函數 |
| `qcc_one` | root | 函數 |
| `qcc_rat` | root | 函數 |
| `qcc_real` | root | 函數 |
| `qcc_sub` | root | 函數 |
| `qcc_to_complex` | root | 函數 |
| `qcc_zero` | root | 函數 |

### 球面與懸掛 HIT

- 規範形式：一般參數化懸掛 SuspS(A) 的 north/south 兩點與每點 a:A 一條 meridian；S²=Susp(S¹)、S³=Susp(S²)；Susp(Bool)≃S¹、餘錐 Cocone(A,B) 與基點環路—懸掛伴隨 (ΣA→*B)≃(A→*ΩB)
- 範疇化：懸掛是把 A×I 兩端各塌縮為一點的同倫推出 HIT 商，映出態射由餘錐萬有性分類；在基點類型範疇 Type* 中 Σ 與 Ω 構成典範同倫伴隨 Σ⊣Ω
- 判定：generic HIT schema 驗證、meridian 端點 face 化簡、依賴消去與 hcomp；0-連通空間的懸掛基本群由 Freudenthal 0-連通定理證為平凡群 ‖Ω¹(Susp(A))‖₀≃1（導出 π₁(S²)≃1 與 π₁(S³)≃1），並具圓楔連通延伸及相干見證

| 符號 | 套件 | 類別 |
|---|---|---|
| `based_map_type_value` | root | 函數 |
| `check_phase15_freudenthal_suspension_and_wedge_connectivity` | root | 函數 |
| `check_phase15_suspension_and_loop_suspension_adjunction` | root | 函數 |
| `check_sphere3` | root | 函數 |
| `circle_0_connected_value` | root | 函數 |
| `circle_to_susp_bool_value` | root | 函數 |
| `cocone_to_based_loop_equiv_value` | root | 函數 |
| `freudenthal_pi1_susp_connected_equiv_unit_value` | root | 函數 |
| `loop_suspension_adjunction_equiv_value` | root | 函數 |
| `pi1_susp2_circle_equiv_unit_value` | root | 函數 |
| `pi1_susp_circle_equiv_unit_value` | root | 函數 |
| `sphere2_meridian_path_value` | root | 函數 |
| `sphere2_north_term` | root | 函數 |
| `sphere2_north_value` | root | 函數 |
| `sphere2_schema` | root | 函數 |
| `sphere2_type_value` | root | 函數 |
| `sphere3_meridian_term` | root | 函數 |
| `sphere3_meridian_value` | root | 函數 |
| `sphere3_north_term` | root | 函數 |
| `sphere3_north_value` | root | 函數 |
| `sphere3_schema` | root | 函數 |
| `sphere3_south_term` | root | 函數 |
| `sphere3_south_value` | root | 函數 |
| `sphere3_type_term` | root | 函數 |
| `sphere3_type_value` | root | 函數 |
| `sphere_schema` | root | 函數 |
| `susp_0_connected_of_pointed_value` | root | 函數 |
| `susp_based_to_cocone_equiv_value` | root | 函數 |
| `susp_bool_equiv_circle_value` | root | 函數 |
| `susp_bool_to_circle_value` | root | 函數 |
| `susp_cocone_type_value` | root | 函數 |
| `susp_merid_path_value` | root | 函數 |
| `susp_north_value` | root | 函數 |
| `susp_south_value` | root | 函數 |
| `susp_type_schema` | root | 函數 |
| `susp_type_schema_at` | root | 函數 |
| `susp_type_value` | root | 函數 |
| `susp_universal_equiv_value` | root | 函數 |
| `suspension_schema` | root | 函數 |
| `wedge_connectivity_circle_left_coh_value` | root | 函數 |
| `wedge_connectivity_circle_right_coh_value` | root | 函數 |
| `wedge_connectivity_circle_set_ext_value` | root | 函數 |

### Jacobi 區間譜迭代

- 規範形式：RatInterval/CInterval 矩形包絡與 dyadic 外向捨入後的 Hermitian 區間矩陣；每次旋轉保存 before/after 與累積酉變換
- 範疇化：Hermitian 相似變換在區間矩陣包絡上的單調提升；Gershgorin 圓盤給出譜的像分解與重數簇
- 判定：精確有理平方比較證明 sqrt/相位/c/s 包絡包含真值；逐旋轉重算 J†J−I∋0 與 J†AJ⊆after，最終圓盤分簇計數；特徵值簇分離以平方自由部分（Sturm 鏈＋與導數 gcd）的 Sturm 區間對原多項式計數回多重數，區間重疊唯一匹配；區間迭代本身具簇感知精化：Gershgorin 簇在迭代內偵測、旋轉以簇懲罰改變 pivot 選擇、精度不足時升級重跑，並在迭代內把 count-2 簇分離為不交單點；自適應驅動在 Jacobi 包絡停滯時切換至精確特徵多項式分離，保留精確重數

| 符號 | 套件 | 類別 |
|---|---|---|
| `CInterval` | algebra | 結構 |
| `CInterval.im` | algebra | 欄位 |
| `CInterval.re` | algebra | 欄位 |
| `CInterval::equal` | algebra | 函數 |
| `CInterval::not_equal` | algebra | 函數 |
| `CInterval::to_repr` | algebra | 函數 |
| `EigenInterval` | algebra | 結構 |
| `EigenInterval.count` | algebra | 欄位 |
| `EigenInterval.hi` | algebra | 欄位 |
| `EigenInterval.lo` | algebra | 欄位 |
| `EigenInterval::equal` | algebra | 函數 |
| `EigenInterval::not_equal` | algebra | 函數 |
| `EigenInterval::to_repr` | algebra | 函數 |
| `JacobiAdaptiveReport` | algebra | 結構 |
| `JacobiAdaptiveReport.cluster_aware` | algebra | 欄位 |
| `JacobiAdaptiveReport.exact_fallback_used` | algebra | 欄位 |
| `JacobiAdaptiveReport.exact_width_bits` | algebra | 欄位 |
| `JacobiAdaptiveReport.max_interval_width` | algebra | 欄位 |
| `JacobiAdaptiveReport.separation` | algebra | 欄位 |
| `JacobiAdaptiveReport.target_met` | algebra | 欄位 |
| `JacobiAdaptiveReport::equal` | algebra | 函數 |
| `JacobiAdaptiveReport::not_equal` | algebra | 函數 |
| `JacobiAdaptiveReport::to_repr` | algebra | 函數 |
| `JacobiBlockDeflatedReport` | algebra | 結構 |
| `JacobiBlockDeflatedReport.block_reports` | algebra | 欄位 |
| `JacobiBlockDeflatedReport.blocks` | algebra | 欄位 |
| `JacobiBlockDeflatedReport.intervals` | algebra | 欄位 |
| `JacobiBlockDeflatedReport.max_block_dimension` | algebra | 欄位 |
| `JacobiBlockDeflatedReport.max_interval_width` | algebra | 欄位 |
| `JacobiBlockDeflatedReport.target_met` | algebra | 欄位 |
| `JacobiCertificate` | algebra | 結構 |
| `JacobiCertificate.eigenvalues` | algebra | 欄位 |
| `JacobiCertificate.final_matrix` | algebra | 欄位 |
| `JacobiCertificate.initial` | algebra | 欄位 |
| `JacobiCertificate.precision_bits` | algebra | 欄位 |
| `JacobiCertificate.rotations` | algebra | 欄位 |
| `JacobiCertificate.transform` | algebra | 欄位 |
| `JacobiCertificate::equal` | algebra | 函數 |
| `JacobiCertificate::not_equal` | algebra | 函數 |
| `JacobiCertificate::to_repr` | algebra | 函數 |
| `JacobiClusterAwareReport` | algebra | 結構 |
| `JacobiClusterAwareReport.certificate` | algebra | 欄位 |
| `JacobiClusterAwareReport.max_cluster_width` | algebra | 欄位 |
| `JacobiClusterAwareReport.precision_bits_used` | algebra | 欄位 |
| `JacobiClusterAwareReport.restarts` | algebra | 欄位 |
| `JacobiClusterAwareReport.separated` | algebra | 欄位 |
| `JacobiClusterAwareReport::equal` | algebra | 函數 |
| `JacobiClusterAwareReport::not_equal` | algebra | 函數 |
| `JacobiClusterAwareReport::to_repr` | algebra | 函數 |
| `JacobiClusterSeparation` | algebra | 結構 |
| `JacobiClusterSeparation.complete` | algebra | 欄位 |
| `JacobiClusterSeparation.intervals` | algebra | 欄位 |
| `JacobiClusterSeparation::equal` | algebra | 函數 |
| `JacobiClusterSeparation::not_equal` | algebra | 函數 |
| `JacobiClusterSeparation::to_repr` | algebra | 函數 |
| `JacobiCoefficients` | algebra | 結構 |
| `JacobiCoefficients.cosine` | algebra | 欄位 |
| `JacobiCoefficients.modulus` | algebra | 欄位 |
| `JacobiCoefficients.p` | algebra | 欄位 |
| `JacobiCoefficients.phase` | algebra | 欄位 |
| `JacobiCoefficients.q` | algebra | 欄位 |
| `JacobiCoefficients.sine` | algebra | 欄位 |
| `JacobiCoefficients::equal` | algebra | 函數 |
| `JacobiCoefficients::not_equal` | algebra | 函數 |
| `JacobiCoefficients::to_repr` | algebra | 函數 |
| `JacobiRotationCertificate` | algebra | 結構 |
| `JacobiRotationCertificate.after` | algebra | 欄位 |
| `JacobiRotationCertificate.after_off_sq_upper` | algebra | 欄位 |
| `JacobiRotationCertificate.before` | algebra | 欄位 |
| `JacobiRotationCertificate.before_off_sq_upper` | algebra | 欄位 |
| `JacobiRotationCertificate.coeffs` | algebra | 欄位 |
| `JacobiRotationCertificate.transform_after` | algebra | 欄位 |
| `JacobiRotationCertificate.transform_before` | algebra | 欄位 |
| `JacobiRotationCertificate.unitary_residual_contains_zero` | algebra | 欄位 |
| `JacobiRotationCertificate::equal` | algebra | 函數 |
| `JacobiRotationCertificate::not_equal` | algebra | 函數 |
| `JacobiRotationCertificate::to_repr` | algebra | 函數 |
| `QCIntervalMat` | algebra | 結構 |
| `QCIntervalMat.n` | algebra | 欄位 |
| `QCIntervalMat.rows` | algebra | 欄位 |
| `QCIntervalMat::equal` | algebra | 函數 |
| `QCIntervalMat::not_equal` | algebra | 函數 |
| `QCIntervalMat::to_repr` | algebra | 函數 |
| `QCpx` | algebra | 結構 |
| `QCpx.im` | algebra | 欄位 |
| `QCpx.re` | algebra | 欄位 |
| `QCpx::equal` | algebra | 函數 |
| `QCpx::not_equal` | algebra | 函數 |
| `QCpx::to_repr` | algebra | 函數 |
| `QCpxMat` | algebra | 結構 |
| `QCpxMat.n` | algebra | 欄位 |
| `QCpxMat.rows` | algebra | 欄位 |
| `QCpxMat::equal` | algebra | 函數 |
| `QCpxMat::not_equal` | algebra | 函數 |
| `QCpxMat::to_repr` | algebra | 函數 |
| `RatInterval` | algebra | 結構 |
| `RatInterval.hi` | algebra | 欄位 |
| `RatInterval.lo` | algebra | 欄位 |
| `RatInterval::equal` | algebra | 函數 |
| `RatInterval::not_equal` | algebra | 函數 |
| `RatInterval::to_repr` | algebra | 函數 |
| `SeparatedEigenInterval` | algebra | 結構 |
| `SeparatedEigenInterval.cluster` | algebra | 欄位 |
| `SeparatedEigenInterval.hi` | algebra | 欄位 |
| `SeparatedEigenInterval.lo` | algebra | 欄位 |
| `SeparatedEigenInterval.multiplicity` | algebra | 欄位 |
| `SeparatedEigenInterval::equal` | algebra | 函數 |
| `SeparatedEigenInterval::not_equal` | algebra | 函數 |
| `SeparatedEigenInterval::to_repr` | algebra | 函數 |
| `check_jacobi_adaptive_exact_fallback` | algebra | 函數 |
| `check_jacobi_block_deflation_and_multiplicity` | algebra | 函數 |
| `check_jacobi_cluster_separation` | algebra | 函數 |
| `check_phase14_jacobi_block_deflation_and_multiplicity` | root | 函數 |
| `cinterval_add` | algebra | 函數 |
| `cinterval_conj` | algebra | 函數 |
| `cinterval_contains` | algebra | 函數 |
| `cinterval_hull` | algebra | 函數 |
| `cinterval_midpoint` | algebra | 函數 |
| `cinterval_mul` | algebra | 函數 |
| `cinterval_neg` | algebra | 函數 |
| `cinterval_normalize` | algebra | 函數 |
| `cinterval_one` | algebra | 函數 |
| `cinterval_point` | algebra | 函數 |
| `cinterval_sub` | algebra | 函數 |
| `cinterval_subset` | algebra | 函數 |
| `cinterval_zero` | algebra | 函數 |
| `eigen_interval_contains` | algebra | 函數 |
| `jacobi_block_components` | algebra | 函數 |
| `jacobi_block_deflated_certified` | algebra | 函數 |
| `jacobi_block_deflated_eigen` | algebra | 函數 |
| `jacobi_certificate_sound` | algebra | 函數 |
| `jacobi_cluster_separation_certified` | algebra | 函數 |
| `jacobi_coefficients` | algebra | 函數 |
| `jacobi_interval_eigen` | algebra | 函數 |
| `jacobi_interval_eigen_adaptive` | algebra | 函數 |
| `jacobi_interval_eigen_cluster_aware` | algebra | 函數 |
| `jacobi_separate_clusters` | algebra | 函數 |
| `jacobi_similarity_interval` | algebra | 函數 |
| `jacobi_unitary_interval` | algebra | 函數 |
| `jacobi_unitary_residual_contains_zero` | algebra | 函數 |
| `qci_mat_adjoint` | algebra | 函數 |
| `qci_mat_contains` | algebra | 函數 |
| `qci_mat_from_point` | algebra | 函數 |
| `qci_mat_from_rows` | algebra | 函數 |
| `qci_mat_hermitian_hull` | algebra | 函數 |
| `qci_mat_identity` | algebra | 函數 |
| `qci_mat_is_hermitian` | algebra | 函數 |
| `qci_mat_midpoint` | algebra | 函數 |
| `qci_mat_mul` | algebra | 函數 |
| `qci_mat_normalize` | algebra | 函數 |
| `qci_mat_sub` | algebra | 函數 |
| `qci_mat_zero` | algebra | 函數 |
| `qci_off_frobenius_sq_upper` | algebra | 函數 |
| `qcpx` | algebra | 函數 |
| `qcpx_is_zero` | algebra | 函數 |
| `qcpx_mat_from_qmat` | algebra | 函數 |
| `qcpx_mat_from_rows` | algebra | 函數 |
| `qcpx_mat_is_hermitian` | algebra | 函數 |
| `qcpx_real` | algebra | 函數 |
| `rat_abs_exact` | algebra | 函數 |
| `rat_cmp_exact` | algebra | 函數 |
| `rat_interval` | algebra | 函數 |
| `rat_interval_abs` | algebra | 函數 |
| `rat_interval_add` | algebra | 函數 |
| `rat_interval_contains` | algebra | 函數 |
| `rat_interval_div` | algebra | 函數 |
| `rat_interval_hull` | algebra | 函數 |
| `rat_interval_midpoint` | algebra | 函數 |
| `rat_interval_mul` | algebra | 函數 |
| `rat_interval_neg` | algebra | 函數 |
| `rat_interval_normalize` | algebra | 函數 |
| `rat_interval_point` | algebra | 函數 |
| `rat_interval_recip` | algebra | 函數 |
| `rat_interval_sqrt` | algebra | 函數 |
| `rat_interval_sub` | algebra | 函數 |
| `rat_interval_subset` | algebra | 函數 |
| `rat_interval_width` | algebra | 函數 |
| `rat_le_exact` | algebra | 函數 |
| `rat_round_down_pow2` | algebra | 函數 |
| `rat_round_up_pow2` | algebra | 函數 |
| `rat_sqrt_interval` | algebra | 函數 |

### 高階合一與雙向 elaborator

- 規範形式：UTerm 的 Miller pattern spine `?F x₁…xₙ` 與 zonk 後 beta/投影簡化核心；表面 STerm 按名解析為 de Bruijn UTerm；HouSearchReport 記錄 status/nodes/branches/depth；HouDelayedGraphReport 保存 Huet 滯留 flex-flex 約束圖邊，HouLazyUnifierStream 保存拉取式顯式 continuation 堆疊
- 範疇化：pattern HOU 是高階合一的可判定片斷；Huet 預合一範疇以滯留 flex-flex 等式為態射商、惰性串流為搜尋樹的餘代數展開；雙向 elaboration 把隱含引數與 dependent motive 問題送入同一合一器再編譯至依賴覈心
- 判定：確定性層以 WHNF 後 rigid 分解、pattern 抽象、occurs/scope 檢查與閉項 fallback 判定；搜尋層在節點與證明項深度預算內求 solved/no-unifier，否則以 residual 或 budget-exceeded 明示未定；支援 Miller pattern 三態 MGU、跨約束殘差求解、Huet 延遲 flex-flex 約束圖自動喚醒與預合一具現，以及拉取式惰性正規形合一子串流

| 符號 | 套件 | 類別 |
|---|---|---|
| `ElabResult` | root | 結構 |
| `ElabResult.term` | root | 欄位 |
| `ElabResult.ty` | root | 欄位 |
| `ElabResult::equal` | root | 函數 |
| `ElabResult::not_equal` | root | 函數 |
| `ElabResult::to_repr` | root | 函數 |
| `ElabVar` | root | 結構 |
| `ElabVar.name` | root | 欄位 |
| `ElabVar.ty` | root | 欄位 |
| `ElabVar::equal` | root | 函數 |
| `ElabVar::not_equal` | root | 函數 |
| `ElabVar::to_repr` | root | 函數 |
| `Elaborator` | root | 結構 |
| `Elaborator.unifier` | root | 欄位 |
| `Elaborator.vars` | root | 欄位 |
| `Elaborator::equal` | root | 函數 |
| `Elaborator::not_equal` | root | 函數 |
| `Elaborator::to_repr` | root | 函數 |
| `GoldfarbDiophantineReport` | root | 結構 |
| `GoldfarbDiophantineReport.a` | root | 欄位 |
| `GoldfarbDiophantineReport.addition_eq_holds` | root | 欄位 |
| `GoldfarbDiophantineReport.b` | root | 欄位 |
| `GoldfarbDiophantineReport.c_prod` | root | 欄位 |
| `GoldfarbDiophantineReport.c_sum` | root | 欄位 |
| `GoldfarbDiophantineReport.commutes_with_succ_a` | root | 欄位 |
| `GoldfarbDiophantineReport.commutes_with_succ_b` | root | 欄位 |
| `GoldfarbDiophantineReport.multiplication_eq_holds` | root | 欄位 |
| `GoldfarbDiophantineReport.wrong_product_refuted` | root | 欄位 |
| `GoldfarbDiophantineReport::equal` | root | 函數 |
| `GoldfarbDiophantineReport::not_equal` | root | 函數 |
| `GoldfarbDiophantineReport::to_repr` | root | 函數 |
| `HouConstraint` | root | 結構 |
| `HouConstraint.depth` | root | 欄位 |
| `HouConstraint.lhs` | root | 欄位 |
| `HouConstraint.rhs` | root | 欄位 |
| `HouConstraint::equal` | root | 函數 |
| `HouConstraint::not_equal` | root | 函數 |
| `HouConstraint::to_repr` | root | 函數 |
| `HouDelayedGraphReport` | root | 結構 |
| `HouDelayedGraphReport.branches_tried` | root | 欄位 |
| `HouDelayedGraphReport.delayed_edges` | root | 欄位 |
| `HouDelayedGraphReport.nodes` | root | 欄位 |
| `HouDelayedGraphReport.status` | root | 欄位 |
| `HouDelayedGraphReport.substitution` | root | 欄位 |
| `HouDelayedGraphReport.woke_edges` | root | 欄位 |
| `HouDelayedGraphReport::equal` | root | 函數 |
| `HouDelayedGraphReport::not_equal` | root | 函數 |
| `HouDelayedGraphReport::to_repr` | root | 函數 |
| `HouDelayedSolveStatus` | root | 列舉 |
| `HouDelayedSolveStatus::HouDelayedBudgetExceeded` | root | 構造子 |
| `HouDelayedSolveStatus::HouDelayedNoUnifier` | root | 構造子 |
| `HouDelayedSolveStatus::HouDelayedPreUnifier` | root | 構造子 |
| `HouDelayedSolveStatus::HouDelayedSolved` | root | 構造子 |
| `HouDelayedSolveStatus::equal` | root | 函數 |
| `HouDelayedSolveStatus::not_equal` | root | 函數 |
| `HouDelayedSolveStatus::to_repr` | root | 函數 |
| `HouEnumerationReport` | root | 結構 |
| `HouEnumerationReport.branches_tried` | root | 欄位 |
| `HouEnumerationReport.capped` | root | 欄位 |
| `HouEnumerationReport.max_depth_reached` | root | 欄位 |
| `HouEnumerationReport.nodes` | root | 欄位 |
| `HouEnumerationReport.search_exhausted` | root | 欄位 |
| `HouEnumerationReport.solutions` | root | 欄位 |
| `HouEnumerationReport::equal` | root | 函數 |
| `HouEnumerationReport::not_equal` | root | 函數 |
| `HouEnumerationReport::to_repr` | root | 函數 |
| `HouFlexFlexEdge` | root | 結構 |
| `HouFlexFlexEdge.depth` | root | 欄位 |
| `HouFlexFlexEdge.lhs` | root | 欄位 |
| `HouFlexFlexEdge.lhs_arity` | root | 欄位 |
| `HouFlexFlexEdge.lhs_meta` | root | 欄位 |
| `HouFlexFlexEdge.rhs` | root | 欄位 |
| `HouFlexFlexEdge.rhs_arity` | root | 欄位 |
| `HouFlexFlexEdge.rhs_meta` | root | 欄位 |
| `HouFlexFlexEdge::equal` | root | 函數 |
| `HouFlexFlexEdge::not_equal` | root | 函數 |
| `HouFlexFlexEdge::to_repr` | root | 函數 |
| `HouIterativeReport` | root | 結構 |
| `HouIterativeReport.report` | root | 欄位 |
| `HouIterativeReport.rounds` | root | 欄位 |
| `HouIterativeReport.solved_at_depth` | root | 欄位 |
| `HouIterativeReport::equal` | root | 函數 |
| `HouIterativeReport::not_equal` | root | 函數 |
| `HouIterativeReport::to_repr` | root | 函數 |
| `HouLazyUnifierStream` | root | 結構 |
| `HouLazyUnifierStream.constraints` | root | 欄位 |
| `HouLazyUnifierStream.emitted` | root | 欄位 |
| `HouLazyUnifierStream.exhausted` | root | 欄位 |
| `HouLazyUnifierStream.initial` | root | 欄位 |
| `HouLazyUnifierStream.max_depth` | root | 欄位 |
| `HouLazyUnifierStream.max_nodes` | root | 欄位 |
| `HouLazyUnifierStream.max_projection_args` | root | 欄位 |
| `HouLazyUnifierStream.nodes_expanded` | root | 欄位 |
| `HouLazyUnifierStream.reify_flex_flex` | root | 欄位 |
| `HouLazyUnifierStream.root_started` | root | 欄位 |
| `HouLazyUnifierStream.round_budget` | root | 欄位 |
| `HouLazyUnifierStream.stack` | root | 欄位 |
| `HouMatchResult` | root | 列舉 |
| `HouMatchResult::HouMatchBudgetExceeded` | root | 構造子 |
| `HouMatchResult::HouMatchNoneWithinBound` | root | 構造子 |
| `HouMatchResult::HouMatchSolved` | root | 構造子 |
| `HouMatchResult::equal` | root | 函數 |
| `HouMatchResult::not_equal` | root | 函數 |
| `HouMatchResult::to_repr` | root | 函數 |
| `HouMguReport` | root | 結構 |
| `HouMguReport.residual` | root | 欄位 |
| `HouMguReport.status` | root | 欄位 |
| `HouMguReport.substitution` | root | 欄位 |
| `HouMguReport::equal` | root | 函數 |
| `HouMguReport::not_equal` | root | 函數 |
| `HouMguReport::to_repr` | root | 函數 |
| `HouMguStatus` | root | 列舉 |
| `HouMguStatus::HouMguNoUnifier` | root | 構造子 |
| `HouMguStatus::HouMguPrincipal` | root | 構造子 |
| `HouMguStatus::HouMguResidual` | root | 構造子 |
| `HouMguStatus::equal` | root | 函數 |
| `HouMguStatus::not_equal` | root | 函數 |
| `HouMguStatus::to_repr` | root | 函數 |
| `HouResidualSolveReport` | root | 結構 |
| `HouResidualSolveReport.branches_tried` | root | 欄位 |
| `HouResidualSolveReport.initial_constraints` | root | 欄位 |
| `HouResidualSolveReport.max_depth_reached` | root | 欄位 |
| `HouResidualSolveReport.nodes` | root | 欄位 |
| `HouResidualSolveReport.residual` | root | 欄位 |
| `HouResidualSolveReport.search_rounds` | root | 欄位 |
| `HouResidualSolveReport.solved_constraints` | root | 欄位 |
| `HouResidualSolveReport.status` | root | 欄位 |
| `HouResidualSolveReport.substitution` | root | 欄位 |
| `HouResidualSolveReport::equal` | root | 函數 |
| `HouResidualSolveReport::not_equal` | root | 函數 |
| `HouResidualSolveReport::to_repr` | root | 函數 |
| `HouSearchReport` | root | 結構 |
| `HouSearchReport.branches_tried` | root | 欄位 |
| `HouSearchReport.max_depth_reached` | root | 欄位 |
| `HouSearchReport.nodes` | root | 欄位 |
| `HouSearchReport.solved_metas` | root | 欄位 |
| `HouSearchReport.status` | root | 欄位 |
| `HouSearchReport::equal` | root | 函數 |
| `HouSearchReport::not_equal` | root | 函數 |
| `HouSearchReport::to_repr` | root | 函數 |
| `HouSearchStatus` | root | 列舉 |
| `HouSearchStatus::HouBudgetExceeded` | root | 構造子 |
| `HouSearchStatus::HouNoUnifier` | root | 構造子 |
| `HouSearchStatus::HouResidual` | root | 構造子 |
| `HouSearchStatus::HouSolved` | root | 構造子 |
| `HouSearchStatus::equal` | root | 函數 |
| `HouSearchStatus::not_equal` | root | 函數 |
| `HouSearchStatus::to_repr` | root | 函數 |
| `STerm` | root | 列舉 |
| `STerm::SAnn` | root | 構造子 |
| `STerm::SApp` | root | 構造子 |
| `STerm::SBoolLit` | root | 構造子 |
| `STerm::SFst` | root | 構造子 |
| `STerm::SHole` | root | 構造子 |
| `STerm::SLam` | root | 構造子 |
| `STerm::SNatElim` | root | 構造子 |
| `STerm::SNatZero` | root | 構造子 |
| `STerm::SPair` | root | 構造子 |
| `STerm::SSnd` | root | 構造子 |
| `STerm::SSucc` | root | 構造子 |
| `STerm::SUnitLit` | root | 構造子 |
| `STerm::SVar` | root | 構造子 |
| `STerm::equal` | root | 函數 |
| `STerm::not_equal` | root | 函數 |
| `STerm::to_repr` | root | 函數 |
| `UMetaInfo` | root | 結構 |
| `UMetaInfo.context_depth` | root | 欄位 |
| `UMetaInfo.solution` | root | 欄位 |
| `UMetaInfo::equal` | root | 函數 |
| `UMetaInfo::not_equal` | root | 函數 |
| `UMetaInfo::to_repr` | root | 函數 |
| `UTerm` | root | 列舉 |
| `UTerm::UApp` | root | 構造子 |
| `UTerm::UBoolLit` | root | 構造子 |
| `UTerm::UConst` | root | 構造子 |
| `UTerm::UFst` | root | 構造子 |
| `UTerm::UImplicitPi` | root | 構造子 |
| `UTerm::ULam` | root | 構造子 |
| `UTerm::UMeta` | root | 構造子 |
| `UTerm::UNatElim` | root | 構造子 |
| `UTerm::UNatZero` | root | 構造子 |
| `UTerm::UPair` | root | 構造子 |
| `UTerm::UPi` | root | 構造子 |
| `UTerm::USigma` | root | 構造子 |
| `UTerm::USnd` | root | 構造子 |
| `UTerm::USucc` | root | 構造子 |
| `UTerm::UType` | root | 構造子 |
| `UTerm::UVar` | root | 構造子 |
| `UTerm::equal` | root | 函數 |
| `UTerm::not_equal` | root | 函數 |
| `UTerm::to_repr` | root | 函數 |
| `Unifier` | root | 結構 |
| `Unifier.metas` | root | 欄位 |
| `Unifier.solved_count` | root | 欄位 |
| `Unifier::equal` | root | 函數 |
| `Unifier::not_equal` | root | 函數 |
| `Unifier::to_repr` | root | 函數 |
| `check_hou_bounded_search` | root | 函數 |
| `check_hou_elaborator` | root | 函數 |
| `check_hou_matching` | root | 函數 |
| `check_hou_phase9_extensions` | root | 函數 |
| `check_hou_residual_solver` | root | 函數 |
| `check_hou_search_extensions` | root | 函數 |
| `check_phase14_hou_backtracking_and_enumeration` | root | 函數 |
| `check_phase16_hou_stream_and_module_merge` | root | 函數 |
| `elab_check` | root | 函數 |
| `elab_infer` | root | 函數 |
| `elab_result_to_dterm` | root | 函數 |
| `elab_type_to_dterm` | root | 函數 |
| `elaborator_new` | root | 函數 |
| `goldfarb_church_iterator` | root | 函數 |
| `goldfarb_church_unary` | root | 函數 |
| `goldfarb_verify_diophantine_encoding` | root | 函數 |
| `hou_conv` | root | 函數 |
| `hou_enumerate_unifiers` | root | 函數 |
| `hou_fresh_meta` | root | 函數 |
| `hou_match` | root | 函數 |
| `hou_match_higher_order_lambda` | root | 函數 |
| `hou_match_solved_within` | root | 函數 |
| `hou_reify_delayed_flex_flex` | root | 函數 |
| `hou_search_unify` | root | 函數 |
| `hou_search_unify_bool` | root | 函數 |
| `hou_search_unify_iterative` | root | 函數 |
| `hou_semantic_optimize` | root | 函數 |
| `hou_solve_constraints` | root | 函數 |
| `hou_solve_constraints_backtracking` | root | 函數 |
| `hou_solve_with_delayed_flex_flex` | root | 函數 |
| `hou_unifier_stream_is_exhausted` | root | 函數 |
| `hou_unifier_stream_new` | root | 函數 |
| `hou_unifier_stream_next` | root | 函數 |
| `hou_unifier_stream_nodes` | root | 函數 |
| `hou_unify` | root | 函數 |
| `hou_unify_mgu` | root | 函數 |
| `hou_unify_residual` | root | 函數 |
| `unifier_new` | root | 函數 |
| `uterm_contains_unsolved_meta` | root | 函數 |
| `uterm_whnf` | root | 函數 |
| `uty_arrow` | root | 函數 |
| `uty_bool` | root | 函數 |
| `uty_nat` | root | 函數 |
| `uty_unit` | root | 函數 |

### 參數化模組與名字空間

- 規範形式：模組 telescope（參數→以 ModuleItem 交錯的 imports 與本地宣告；舊 decls-only 建構仍可讀，語義為全部 imports 前置）與分離的 name→ordinal bindings；實例是同時代換後的閉合宣告
- 範疇化：參數化模組是模組函子，import 是函子套用的內聯，open/alias/rename 是同一 telescope entry 的不同名字投影
- 判定：循環檢測、參數引數依賴檢查、import 選擇/隱藏/改名的歧義拒絕、opaque export 中性化，以及實例閉合後逐宣告 dep_check

| 符號 | 套件 | 類別 |
|---|---|---|
| `ModuleBinding` | root | 結構 |
| `ModuleBinding.name` | root | 欄位 |
| `ModuleBinding.ordinal` | root | 欄位 |
| `ModuleBinding::equal` | root | 函數 |
| `ModuleBinding::not_equal` | root | 函數 |
| `ModuleBinding::to_repr` | root | 函數 |
| `ModuleDecl` | root | 結構 |
| `ModuleDecl.body` | root | 欄位 |
| `ModuleDecl.exported` | root | 欄位 |
| `ModuleDecl.name` | root | 欄位 |
| `ModuleDecl.transparent` | root | 欄位 |
| `ModuleDecl.ty` | root | 欄位 |
| `ModuleDecl::equal` | root | 函數 |
| `ModuleDecl::not_equal` | root | 函數 |
| `ModuleDecl::to_repr` | root | 函數 |
| `ModuleDef` | root | 結構 |
| `ModuleDef.decls` | root | 欄位 |
| `ModuleDef.imports` | root | 欄位 |
| `ModuleDef.items` | root | 欄位 |
| `ModuleDef.opens` | root | 欄位 |
| `ModuleDef.params` | root | 欄位 |
| `ModuleDef.path` | root | 欄位 |
| `ModuleDef::equal` | root | 函數 |
| `ModuleDef::not_equal` | root | 函數 |
| `ModuleDef::to_repr` | root | 函數 |
| `ModuleEntry` | root | 結構 |
| `ModuleEntry.body` | root | 欄位 |
| `ModuleEntry.canonical_name` | root | 欄位 |
| `ModuleEntry.exported` | root | 欄位 |
| `ModuleEntry.local_name` | root | 欄位 |
| `ModuleEntry.source_module` | root | 欄位 |
| `ModuleEntry.transparent` | root | 欄位 |
| `ModuleEntry.ty` | root | 欄位 |
| `ModuleEntry::equal` | root | 函數 |
| `ModuleEntry::not_equal` | root | 函數 |
| `ModuleEntry::to_repr` | root | 函數 |
| `ModuleEnv` | root | 結構 |
| `ModuleEnv.modules` | root | 欄位 |
| `ModuleEnv::equal` | root | 函數 |
| `ModuleEnv::not_equal` | root | 函數 |
| `ModuleEnv::to_repr` | root | 函數 |
| `ModuleExport` | root | 結構 |
| `ModuleExport.name` | root | 欄位 |
| `ModuleExport.ordinal` | root | 欄位 |
| `ModuleExport.transparent` | root | 欄位 |
| `ModuleExport::equal` | root | 函數 |
| `ModuleExport::not_equal` | root | 函數 |
| `ModuleExport::to_repr` | root | 函數 |
| `ModuleImport` | root | 結構 |
| `ModuleImport.alias_name` | root | 欄位 |
| `ModuleImport.args` | root | 欄位 |
| `ModuleImport.hiding` | root | 欄位 |
| `ModuleImport.module_path` | root | 欄位 |
| `ModuleImport.only` | root | 欄位 |
| `ModuleImport.opened` | root | 欄位 |
| `ModuleImport.renames` | root | 欄位 |
| `ModuleImport::equal` | root | 函數 |
| `ModuleImport::not_equal` | root | 函數 |
| `ModuleImport::to_repr` | root | 函數 |
| `ModuleInstance` | root | 結構 |
| `ModuleInstance.bindings` | root | 欄位 |
| `ModuleInstance.decls` | root | 欄位 |
| `ModuleInstance.module_path` | root | 欄位 |
| `ModuleInstance::equal` | root | 函數 |
| `ModuleInstance::not_equal` | root | 函數 |
| `ModuleInstance::to_repr` | root | 函數 |
| `ModuleInstanceDecl` | root | 結構 |
| `ModuleInstanceDecl.body` | root | 欄位 |
| `ModuleInstanceDecl.canonical_name` | root | 欄位 |
| `ModuleInstanceDecl.exported` | root | 欄位 |
| `ModuleInstanceDecl.name` | root | 欄位 |
| `ModuleInstanceDecl.transparent` | root | 欄位 |
| `ModuleInstanceDecl.ty` | root | 欄位 |
| `ModuleInstanceDecl::equal` | root | 函數 |
| `ModuleInstanceDecl::not_equal` | root | 函數 |
| `ModuleInstanceDecl::to_repr` | root | 函數 |
| `ModuleItem` | root | 列舉 |
| `ModuleItem::ModuleItemDecl` | root | 構造子 |
| `ModuleItem::ModuleItemImport` | root | 構造子 |
| `ModuleItem::equal` | root | 函數 |
| `ModuleItem::not_equal` | root | 函數 |
| `ModuleItem::to_repr` | root | 函數 |
| `ModuleRename` | root | 結構 |
| `ModuleRename.from_name` | root | 欄位 |
| `ModuleRename.to_name` | root | 欄位 |
| `ModuleRename::equal` | root | 函數 |
| `ModuleRename::not_equal` | root | 函數 |
| `ModuleRename::to_repr` | root | 函數 |
| `ModuleSignature` | root | 結構 |
| `ModuleSignature.bindings` | root | 欄位 |
| `ModuleSignature.entries` | root | 欄位 |
| `ModuleSignature.exports` | root | 欄位 |
| `ModuleSignature.module_path` | root | 欄位 |
| `ModuleSignature::equal` | root | 函數 |
| `ModuleSignature::not_equal` | root | 函數 |
| `ModuleSignature::to_repr` | root | 函數 |
| `bool_ops_module` | root | 函數 |
| `check_module_interleaved_items` | root | 函數 |
| `check_module_system` | root | 函數 |
| `generic_iterate_module` | root | 函數 |
| `module_decl` | root | 函數 |
| `module_def` | root | 函數 |
| `module_env_add` | root | 函數 |
| `module_env_find` | root | 函數 |
| `module_env_new` | root | 函數 |
| `module_example_env` | root | 函數 |
| `module_import` | root | 函數 |
| `module_instance_find` | root | 函數 |
| `module_instantiate` | root | 函數 |
| `module_ref` | root | 函數 |
| `module_rename` | root | 函數 |
| `module_resolve` | root | 函數 |
| `module_signature` | root | 函數 |
| `module_validate` | root | 函數 |

### 立方體演算法

- 規範形式：KanBox 打包型別線、系統與 base；transport filler 是 PathP；路徑傳遞是 hcomp 方塊的頂邊；依賴和路徑分裂、纖維化環路等價與五維 Stasheff 結合多面體 K₅ 相干 5-胞
- 範疇化：cubical CwF 中由 Kan 纖維化結構生成的路徑物件運算、纖維化環路序列 Ω¹(ΣB P)≃Σ(p:Ω¹B).(subst P p e₀≡e₀) 與 A_∞ 環路空間五重結合的 K₅ 相干胞
- 判定：派遣至覈心 coe/comp/fill 並以轉換驗證端點；單位律 3-胞、Mac Lane 五邊形 4-胞與 Stasheff K₅ 南北雙五邊形路線間的 5-胞均經轉換核驗；閉項與開放認證等價由依賴檢查器驗收

| 符號 | 套件 | 類別 |
|---|---|---|
| `BrunerieNorm` | root | 列舉 |
| `BrunerieNorm::DoesNotNormalise` | root | 構造子 |
| `BrunerieNorm::NeverNormalised` | root | 構造子 |
| `BrunerieNorm::NormalisesTo` | root | 構造子 |
| `BrunerieNorm::equal` | root | 函數 |
| `BrunerieNorm::not_equal` | root | 函數 |
| `BrunerieNorm::to_repr` | root | 函數 |
| `BrunerieNumber` | root | 結構 |
| `BrunerieNumber.complexity` | root | 欄位 |
| `BrunerieNumber.name` | root | 欄位 |
| `BrunerieNumber.norm` | root | 欄位 |
| `BrunerieNumber::equal` | root | 函數 |
| `BrunerieNumber::not_equal` | root | 函數 |
| `BrunerieNumber::to_repr` | root | 函數 |
| `FgAb` | root | 結構 |
| `FgAb.rank` | root | 欄位 |
| `FgAb.torsion` | root | 欄位 |
| `FgAb::equal` | root | 函數 |
| `FgAb::not_equal` | root | 函數 |
| `FgAb::to_repr` | root | 函數 |
| `FreuStatus` | root | 列舉 |
| `FreuStatus::FreuEquiv` | root | 構造子 |
| `FreuStatus::FreuNone` | root | 構造子 |
| `FreuStatus::FreuSurj` | root | 構造子 |
| `FreuStatus::equal` | root | 函數 |
| `FreuStatus::not_equal` | root | 函數 |
| `FreuStatus::to_repr` | root | 函數 |
| `KanBox` | root | 結構 |
| `KanBox.base` | root | 欄位 |
| `KanBox.dlevel` | root | 欄位 |
| `KanBox.line` | root | 欄位 |
| `KanBox.system` | root | 欄位 |
| `Origin` | root | 列舉 |
| `Origin::Imported` | root | 構造子 |
| `Origin::Prior` | root | 構造子 |
| `Origin::Proved` | root | 構造子 |
| `Origin::equal` | root | 函數 |
| `Origin::not_equal` | root | 函數 |
| `Origin::to_repr` | root | 函數 |
| `Paren` | root | 列舉 |
| `Paren::PLeaf` | root | 構造子 |
| `Paren::PNode` | root | 構造子 |
| `Paren::equal` | root | 函數 |
| `Paren::not_equal` | root | 函數 |
| `Paren::to_repr` | root | 函數 |
| `Stree` | root | 列舉 |
| `Stree::SLeaf` | root | 構造子 |
| `Stree::SNode` | root | 構造子 |
| `Stree::equal` | root | 函數 |
| `Stree::not_equal` | root | 函數 |
| `Stree::to_repr` | root | 函數 |
| `assoc_euler_characteristic` | root | 函數 |
| `assoc_fvector` | root | 函數 |
| `assoc_tree_value` | root | 函數 |
| `assoc_two_faces` | root | 函數 |
| `bm_gap` | root | 函數 |
| `brunerie_family_decreasing` | root | 函數 |
| `brunerie_family_establishes` | root | 函數 |
| `brunerie_new_family` | root | 函數 |
| `brunerie_norm_establishes` | root | 函數 |
| `brunerie_original` | root | 函數 |
| `brunerie_whitehead_lives_in` | root | 函數 |
| `catalan` | root | 函數 |
| `check_assoc_faces` | root | 函數 |
| `check_blakers_massey` | root | 函數 |
| `check_brunerie_pi4_s3` | root | 函數 |
| `check_cubical_algorithms` | root | 函數 |
| `check_homotopy_universal` | root | 函數 |
| `check_phase14_eckmann_hilton_and_pentagon_coherence` | root | 函數 |
| `conn_of_sphere` | root | 函數 |
| `cyclic_of_beta` | root | 函數 |
| `dfunext_term` | root | 函數 |
| `dj_singleton_elim_value` | root | 函數 |
| `dpath_assoc3_value` | root | 函數 |
| `dpath_assoc_path3_value` | root | 函數 |
| `dpath_associahedron_k5_cell5_value` | root | 函數 |
| `dpath_associahedron_k6_coherence_value` | root | 函數 |
| `dpath_cong_term` | root | 函數 |
| `dpath_cong_value` | root | 函數 |
| `dpath_eckmann_hilton3_value` | root | 函數 |
| `dpath_funext_value` | root | 函數 |
| `dpath_k5_hemi_north4_value` | root | 函數 |
| `dpath_k5_hemi_south4_value` | root | 函數 |
| `dpath_k5_lhs1_value` | root | 函數 |
| `dpath_k5_rhs1_value` | root | 函數 |
| `dpath_k5_route_inner3_value` | root | 函數 |
| `dpath_k5_route_outer3_value` | root | 函數 |
| `dpath_k6_hemi_north4_value` | root | 函數 |
| `dpath_k6_hemi_south4_value` | root | 函數 |
| `dpath_k6_lhs1_value` | root | 函數 |
| `dpath_k6_rhs1_value` | root | 函數 |
| `dpath_k6_route_north2_value` | root | 函數 |
| `dpath_k6_route_south2_value` | root | 函數 |
| `dpath_left_inverse3_value` | root | 函數 |
| `dpath_left_unit3_value` | root | 函數 |
| `dpath_lr_unit_coherence4_value` | root | 函數 |
| `dpath_of_pathp_value` | root | 函數 |
| `dpath_pentagon4_value` | root | 函數 |
| `dpath_pentagon_bot3_value` | root | 函數 |
| `dpath_pentagon_path_bot3_value` | root | 函數 |
| `dpath_pentagon_path_top3_value` | root | 函數 |
| `dpath_pentagon_top3_value` | root | 函數 |
| `dpath_prefix_value` | root | 函數 |
| `dpath_refl_value` | root | 函數 |
| `dpath_right_inverse3_value` | root | 函數 |
| `dpath_right_unit3_value` | root | 函數 |
| `dpath_right_unit_general_value` | root | 函數 |
| `dpath_segment_value` | root | 函數 |
| `dpath_singleton_n_transport_value` | root | 函數 |
| `dpath_square_boundary3_value` | root | 函數 |
| `dpath_subst_trans_value` | root | 函數 |
| `dpath_sym_compose3_value` | root | 函數 |
| `dpath_sym_term` | root | 函數 |
| `dpath_sym_value` | root | 函數 |
| `dpath_trans_square_value` | root | 函數 |
| `dpath_trans_term` | root | 函數 |
| `dpath_trans_value` | root | 函數 |
| `dpath_triple_square_value` | root | 函數 |
| `dpathp_eq_in_set_family_value` | root | 函數 |
| `dpathp_of_transport_eq_value` | root | 函數 |
| `dtransport_back_term` | root | 函數 |
| `dtransport_term` | root | 函數 |
| `fg_is_trivial` | root | 函數 |
| `fg_rank_le` | root | 函數 |
| `fg_z` | root | 函數 |
| `fg_zero` | root | 函數 |
| `fg_zmod` | root | 函數 |
| `fibration_loop_equiv_fiber_path_value` | root | 函數 |
| `freudenthal_status` | root | 函數 |
| `gap_equiv_below` | root | 函數 |
| `gap_surj_at` | root | 函數 |
| `homotopy_universal_remaining` | root | 函數 |
| `hopf_les_injective` | root | 函數 |
| `hopf_les_iso` | root | 函數 |
| `hopf_les_surjective` | root | 函數 |
| `james_cell_dim` | root | 函數 |
| `james_cells` | root | 函數 |
| `james_cons_value` | root | 函數 |
| `james_nil_value` | root | 函數 |
| `james_rec_value` | root | 函數 |
| `james_schema` | root | 函數 |
| `james_schema_at` | root | 函數 |
| `james_type_value` | root | 函數 |
| `join_cocone_type_value` | root | 函數 |
| `join_dim` | root | 函數 |
| `join_inl_value` | root | 函數 |
| `join_inr_value` | root | 函數 |
| `join_push_value` | root | 函數 |
| `join_rec_value` | root | 函數 |
| `join_schema` | root | 函數 |
| `join_schema_at` | root | 函數 |
| `join_sphere_dim` | root | 函數 |
| `join_type_value` | root | 函數 |
| `kan_box` | root | 函數 |
| `kan_box_comp` | root | 函數 |
| `kan_box_fill` | root | 函數 |
| `kan_box_pathp` | root | 函數 |
| `les_middle_is_injective` | root | 函數 |
| `les_middle_is_iso` | root | 函數 |
| `les_middle_is_surjective` | root | 函數 |
| `paren_all` | root | 函數 |
| `paren_k5_lhs1` | root | 函數 |
| `paren_leaves` | root | 函數 |
| `paren_left_spine` | root | 函數 |
| `paren_renumber` | root | 函數 |
| `paren_right_spine` | root | 函數 |
| `paren_rotation_edge_count` | root | 函數 |
| `paren_rotation_graph_connected` | root | 函數 |
| `paren_rotations` | root | 函數 |
| `pathp_equiv_transport_eq_value` | root | 函數 |
| `pi2_s2_iso_z_halves` | root | 函數 |
| `pi2_s2_iso_z_origins` | root | 函數 |
| `pi3_s2_iso_pi3_s3` | root | 函數 |
| `pi3_s2_iso_pi3_s3_origins` | root | 函數 |
| `pi3_s3_iso_pi2_s2` | root | 函數 |
| `pi3_s3_iso_pi2_s2_origins` | root | 函數 |
| `pi4_s3_group` | root | 函數 |
| `pi4_s3_iso_pi4_s2` | root | 函數 |
| `pi4_s3_origins` | root | 函數 |
| `pi_circle` | root | 函數 |
| `s3_is_join_of_two_circles` | root | 函數 |
| `sigma_cong_snd_equiv_value` | root | 函數 |
| `sigma_path_equiv_subst_value` | root | 函數 |
| `sigma_path_equiv_value` | root | 函數 |
| `stree_all` | root | 函數 |
| `stree_dim` | root | 函數 |
| `stree_leaves` | root | 函數 |
| `subst_pathp_value` | root | 函數 |
| `subst_refl_eq_value` | root | 函數 |
| `subst_trans_eq_value` | root | 函數 |
| `subst_value` | root | 函數 |
| `suspension_gap` | root | 函數 |
| `transport_back_value` | root | 函數 |
| `transport_checked_line_value` | root | 函數 |
| `transport_filler_value` | root | 函數 |
| `transport_pathp_value` | root | 函數 |
| `transport_value` | root | 函數 |
| `trunc_inc_value` | root | 函數 |
| `trunc_rec_value` | root | 函數 |
| `trunc_schema` | root | 函數 |
| `trunc_schema_at` | root | 函數 |
| `trunc_type_value` | root | 函數 |
| `wedge_glue_value` | root | 函數 |
| `wedge_rec_value` | root | 函數 |
| `wedge_schema` | root | 函數 |
| `wedge_schema_at` | root | 函數 |
| `wedge_type_value` | root | 函數 |
| `wedge_winl_value` | root | 函數 |
| `wedge_winr_value` | root | 函數 |
| `whitehead_degree` | root | 函數 |

### 計算性單值性（univalence）

- 規範形式：有限宇宙路徑以 wiring 等價為範形；依賴宇宙路徑是受檢查型別線，pathToEquiv 取其 coe 等價，ua 取 Glue 線，uaβ 是 transport filler 的 unglue，往返由 Equiv 同倫與二維 Glue 方塊見證
- 範疇化：宇宙路徑範疇與等價之間的等價 (Equiv A B) ≃ Path U A B；Glue 沿等價黏合，transport 是其 coe 函子
- 判定：有限側以 wiring 相等；AST 側以 coe/comp 計算並以型別導向轉換驗證往返端點與方塊四邊；閉項 pathToEquiv 的 fill/coe 證明由依賴檢查器驗收

| 符號 | 套件 | 類別 |
|---|---|---|
| `UniversePath` | root | 結構 |
| `UniversePath.dst` | root | 欄位 |
| `UniversePath.level` | root | 欄位 |
| `UniversePath.line` | root | 欄位 |
| `UniversePath.src` | root | 欄位 |
| `check_finite_univalence` | root | 函數 |
| `check_univalence` | root | 函數 |
| `equiv_to_universe_path_value` | root | 函數 |
| `finite_transport` | root | 函數 |
| `path_to_equiv_map_term` | root | 函數 |
| `path_to_equiv_term` | root | 函數 |
| `path_to_equiv_value` | root | 函數 |
| `transport_roundtrip_path_value` | root | 函數 |
| `ua_beta_back_path_value` | root | 函數 |
| `ua_beta_path_value` | root | 函數 |
| `ua_map_term` | root | 函數 |
| `ua_transport_value` | root | 函數 |
| `univalence_equiv_value` | root | 函數 |
| `univalence_retr_path_value` | root | 函數 |
| `univalence_sect_square_value` | root | 函數 |
| `universe_path_normal_form` | root | 函數 |
| `universe_path_of_checked_line` | root | 函數 |
| `universe_path_of_ua_term_closed` | root | 函數 |
| `universe_path_to_equiv_value` | root | 函數 |
| `universe_path_transport_conv` | root | 函數 |
| `upath_refl` | root | 函數 |
| `upath_sym` | root | 函數 |
| `upath_to_equiv` | root | 函數 |
| `upath_trans` | root | 函數 |

### 完備精確代數與根隔離

- 規範形式：BigInt 有理數；Q[x] 不可約因式與重數；精確有理 LLL 約化格基與單模變換 U∈GLₙ(ℤ)；Van Hoeij 冪和跡格重組因式；Sturm 實根區間、不交 Rouché 複圓盤與複代數閉包元素 ComplexAlgNum∈Q̄⊂ℂ；雙二次數與去巢根式表達式
- 範疇化：Q[x] 唯一因式分解、GLₙ(ℤ) 格約化軌道、Frobenius/Hensel 冪和跡約束子格與代數閉包 Q̄⊂ℂ 的複嵌入正向極限
- 判定：不可約性證書 fast path、Hensel 提升結合 Fujiwara 根界 Van Hoeij LLL 冪和跡格因式重組（消除 Swinnerton-Dyer 型多項式組合爆炸）與 Kronecker 保底；Sturm 計數、Cauchy/Rouché 圓盤細分與結式消元實作 Q̄⊂ℂ 精確加減乘除、共軛、開方與判等

| 符號 | 套件 | 類別 |
|---|---|---|
| `AlgPoly` | algebra | 結構 |
| `AlgPoly.coeffs` | algebra | 欄位 |
| `AlgPoly.modulus` | algebra | 欄位 |
| `AlgPolyDiv` | algebra | 結構 |
| `AlgPolyDiv.quotient` | algebra | 欄位 |
| `AlgPolyDiv.remainder` | algebra | 欄位 |
| `AlgPolyFactor` | algebra | 結構 |
| `AlgPolyFactor.factor` | algebra | 欄位 |
| `AlgPolyFactor.multiplicity` | algebra | 欄位 |
| `BiquadNum` | algebra | 結構 |
| `BiquadNum.basis` | algebra | 欄位 |
| `BiquadNum.coeffs` | algebra | 欄位 |
| `BiquadNum::equal` | algebra | 函數 |
| `BiquadNum::not_equal` | algebra | 函數 |
| `BiquadNum::to_repr` | algebra | 函數 |
| `CertEnclosure` | algebra | 結構 |
| `CertEnclosure.hi` | algebra | 欄位 |
| `CertEnclosure.lo` | algebra | 欄位 |
| `CertEnclosure.tail` | algebra | 欄位 |
| `CertEnclosure.terms` | algebra | 欄位 |
| `CertEnclosure::equal` | algebra | 函數 |
| `CertEnclosure::not_equal` | algebra | 函數 |
| `CertEnclosure::to_repr` | algebra | 函數 |
| `ComplexAlgNum` | algebra | 結構 |
| `ComplexAlgNum.disk` | algebra | 欄位 |
| `ComplexAlgNum.minpoly` | algebra | 欄位 |
| `ComplexAlgNum.root_index` | algebra | 欄位 |
| `ComplexDisk` | algebra | 結構 |
| `ComplexDisk.im` | algebra | 欄位 |
| `ComplexDisk.radius` | algebra | 欄位 |
| `ComplexDisk.re` | algebra | 欄位 |
| `ComplexRootIsolation` | algebra | 結構 |
| `ComplexRootIsolation.disk` | algebra | 欄位 |
| `ComplexRootIsolation.multiplicity` | algebra | 欄位 |
| `ComplexRootIsolation.polynomial` | algebra | 欄位 |
| `EIrrCertificate` | algebra | 結構 |
| `EIrrCertificate.a` | algebra | 欄位 |
| `EIrrCertificate.e_hi` | algebra | 欄位 |
| `EIrrCertificate.e_lo` | algebra | 欄位 |
| `EIrrCertificate.m` | algebra | 欄位 |
| `EIrrCertificate.n` | algebra | 欄位 |
| `EIrrCertificate.p` | algebra | 欄位 |
| `EIrrCertificate.q` | algebra | 欄位 |
| `EIrrCertificate.q_divides_m` | algebra | 欄位 |
| `EIrrCertificate.scaled_hi` | algebra | 欄位 |
| `EIrrCertificate.scaled_lo` | algebra | 欄位 |
| `EIrrCertificate.tail_bound` | algebra | 欄位 |
| `EIrrCertificate.verified` | algebra | 欄位 |
| `EIrrCertificate::equal` | algebra | 函數 |
| `EIrrCertificate::not_equal` | algebra | 函數 |
| `EIrrCertificate::to_repr` | algebra | 函數 |
| `LiouvilleTranscendenceCert` | algebra | 結構 |
| `LiouvilleTranscendenceCert.coeffs` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.degree` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.den_q` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.gap_lhs` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.gap_rhs` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.lipschitz_bound_m` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.num_p` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.scaled_poly_at_conv` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.stage_n` | algebra | 欄位 |
| `LiouvilleTranscendenceCert.verified` | algebra | 欄位 |
| `LiouvilleTranscendenceCert::equal` | algebra | 函數 |
| `LiouvilleTranscendenceCert::not_equal` | algebra | 函數 |
| `LiouvilleTranscendenceCert::to_repr` | algebra | 函數 |
| `LllReductionReport` | algebra | 結構 |
| `LllReductionReport.reduced_basis` | algebra | 欄位 |
| `LllReductionReport.size_reductions` | algebra | 欄位 |
| `LllReductionReport.swaps` | algebra | 欄位 |
| `LllReductionReport.unimodular_u` | algebra | 欄位 |
| `QPolyCertifiedFactor` | algebra | 結構 |
| `QPolyCertifiedFactor.certificate` | algebra | 欄位 |
| `QPolyCertifiedFactor.factor` | algebra | 欄位 |
| `QPolyCertifiedFactor.multiplicity` | algebra | 欄位 |
| `QPolyCertifiedFactor::equal` | algebra | 函數 |
| `QPolyCertifiedFactor::not_equal` | algebra | 函數 |
| `QPolyCertifiedFactor::to_repr` | algebra | 函數 |
| `QPolyCompleteFactorization` | algebra | 結構 |
| `QPolyCompleteFactorization.factors` | algebra | 欄位 |
| `QPolyCompleteFactorization.leading` | algebra | 欄位 |
| `QPolyDegreePattern` | algebra | 結構 |
| `QPolyDegreePattern.degrees` | algebra | 欄位 |
| `QPolyDegreePattern.prime` | algebra | 欄位 |
| `QPolyFactorCertificate` | algebra | 結構 |
| `QPolyFactorCertificate.factors` | algebra | 欄位 |
| `QPolyFactorCertificate.hensel_exponent` | algebra | 欄位 |
| `QPolyFactorCertificate.hensel_prime` | algebra | 欄位 |
| `QPolyFactorCertificate.leading` | algebra | 欄位 |
| `QPolyFactorCertificate::equal` | algebra | 函數 |
| `QPolyFactorCertificate::not_equal` | algebra | 函數 |
| `QPolyFactorCertificate::to_repr` | algebra | 函數 |
| `QPolyIrreducibilityCertificate` | algebra | 列舉 |
| `QPolyIrreducibilityCertificate::CertEisenstein` | algebra | 構造子 |
| `QPolyIrreducibilityCertificate::CertLinear` | algebra | 構造子 |
| `QPolyIrreducibilityCertificate::CertLowDegreeNoRationalRoot` | algebra | 構造子 |
| `QPolyIrreducibilityCertificate::CertModDegreePatterns` | algebra | 構造子 |
| `QPolyIrreducibilityCertificate::CertModPrime` | algebra | 構造子 |
| `QPolyIrreducibilityCertificate::equal` | algebra | 函數 |
| `QPolyIrreducibilityCertificate::not_equal` | algebra | 函數 |
| `QPolyIrreducibilityCertificate::to_repr` | algebra | 函數 |
| `QPolyLllFactorReport` | algebra | 結構 |
| `QPolyLllFactorReport.factors` | algebra | 欄位 |
| `QPolyLllFactorReport.hensel_prime` | algebra | 欄位 |
| `QPolyLllFactorReport.leading` | algebra | 欄位 |
| `QPolyLllFactorReport.lll_short_dimension` | algebra | 欄位 |
| `QPolyLllFactorReport.modular_factor_count` | algebra | 欄位 |
| `QPolyLllFactorReport.used_lll_lattice` | algebra | 欄位 |
| `RadicalExpr` | algebra | 列舉 |
| `RadicalExpr::RAdd` | algebra | 構造子 |
| `RadicalExpr::RDiv` | algebra | 構造子 |
| `RadicalExpr::RMul` | algebra | 構造子 |
| `RadicalExpr::RNeg` | algebra | 構造子 |
| `RadicalExpr::RRat` | algebra | 構造子 |
| `RadicalExpr::RRoot` | algebra | 構造子 |
| `RadicalExpr::RSub` | algebra | 構造子 |
| `RealRootIsolation` | algebra | 結構 |
| `RealRootIsolation.lower` | algebra | 欄位 |
| `RealRootIsolation.multiplicity` | algebra | 欄位 |
| `RealRootIsolation.polynomial` | algebra | 欄位 |
| `RealRootIsolation.upper` | algebra | 欄位 |
| `RefutationResult` | algebra | 結構 |
| `RefutationResult.hi` | algebra | 欄位 |
| `RefutationResult.lo` | algebra | 欄位 |
| `RefutationResult.refuted` | algebra | 欄位 |
| `RefutationResult.terms` | algebra | 欄位 |
| `RefutationResult::equal` | algebra | 函數 |
| `RefutationResult::not_equal` | algebra | 函數 |
| `RefutationResult::to_repr` | algebra | 函數 |
| `SchanuelRankWitness` | algebra | 結構 |
| `SchanuelRankWitness.input_count` | algebra | 欄位 |
| `SchanuelRankWitness.lindemann_weierstrass_alg_indep` | algebra | 欄位 |
| `SchanuelRankWitness.null_relation` | algebra | 欄位 |
| `SchanuelRankWitness.q_linear_rank` | algebra | 欄位 |
| `SchanuelRankWitness.q_linearly_independent` | algebra | 欄位 |
| `SchanuelRankWitness.schanuel_trdeg_lower_bound` | algebra | 欄位 |
| `SchanuelRankWitness::equal` | algebra | 函數 |
| `SchanuelRankWitness::not_equal` | algebra | 函數 |
| `SchanuelRankWitness::to_repr` | algebra | 函數 |
| `SplittingField` | algebra | 結構 |
| `SplittingField.modulus` | algebra | 欄位 |
| `SplittingField.roots` | algebra | 欄位 |
| `SplittingRoot` | algebra | 結構 |
| `SplittingRoot.multiplicity` | algebra | 欄位 |
| `SplittingRoot.value` | algebra | 欄位 |
| `algpoly_add` | algebra | 函數 |
| `algpoly_degree` | algebra | 函數 |
| `algpoly_derivative` | algebra | 函數 |
| `algpoly_div_exact` | algebra | 函數 |
| `algpoly_divmod` | algebra | 函數 |
| `algpoly_eq` | algebra | 函數 |
| `algpoly_eval` | algebra | 函數 |
| `algpoly_factor_complete` | algebra | 函數 |
| `algpoly_from_qpoly` | algebra | 函數 |
| `algpoly_gcd` | algebra | 函數 |
| `algpoly_is_zero` | algebra | 函數 |
| `algpoly_mod` | algebra | 函數 |
| `algpoly_monic` | algebra | 函數 |
| `algpoly_mul` | algebra | 函數 |
| `algpoly_norm_shifted` | algebra | 函數 |
| `algpoly_one` | algebra | 函數 |
| `algpoly_pow` | algebra | 函數 |
| `algpoly_scale` | algebra | 函數 |
| `algpoly_squarefree_factorization` | algebra | 函數 |
| `algpoly_sub` | algebra | 函數 |
| `algpoly_zero` | algebra | 函數 |
| `bigint_abs` | algebra | 函數 |
| `bigint_divisors` | algebra | 函數 |
| `bigint_gcd` | algebra | 函數 |
| `bigint_lcm` | algebra | 函數 |
| `bigint_nth_root_exact` | algebra | 函數 |
| `bigint_nth_root_floor` | algebra | 函數 |
| `bigint_prime_factorization` | algebra | 函數 |
| `bigint_sqrt_exact` | algebra | 函數 |
| `bigint_sqrt_floor` | algebra | 函數 |
| `bigint_squarefree_decomp` | algebra | 函數 |
| `bigint_to_double` | algebra | 函數 |
| `biquad_add` | algebra | 函數 |
| `biquad_div` | algebra | 函數 |
| `biquad_eq` | algebra | 函數 |
| `biquad_inv` | algebra | 函數 |
| `biquad_mul` | algebra | 函數 |
| `biquad_neg` | algebra | 函數 |
| `biquad_of_quad` | algebra | 函數 |
| `biquad_rat` | algebra | 函數 |
| `biquad_sign` | algebra | 函數 |
| `biquad_sqrt` | algebra | 函數 |
| `biquad_sqrt_rat` | algebra | 函數 |
| `biquad_sub` | algebra | 函數 |
| `biquad_to_radical` | algebra | 函數 |
| `biquad_zero` | algebra | 函數 |
| `certified_e` | algebra | 函數 |
| `certified_pi` | algebra | 函數 |
| `check_biquadratic_denesting` | algebra | 函數 |
| `check_complex_algebraic_closure_rouche` | algebra | 函數 |
| `check_lll_lattice_and_van_hoeij_factor` | algebra | 函數 |
| `check_phase14_qpoly_hensel_factor_and_certificates` | root | 函數 |
| `check_qpoly_degree_pattern_certificates` | algebra | 函數 |
| `check_qpoly_factor_complete` | algebra | 函數 |
| `check_qpoly_hensel_factor_and_certificates` | algebra | 函數 |
| `check_qpoly_mod_pattern_pruning` | algebra | 函數 |
| `check_radical_denesting` | algebra | 函數 |
| `check_root_isolation` | algebra | 函數 |
| `check_splitting_field` | algebra | 函數 |
| `check_transcendental_boundary_layer` | algebra | 函數 |
| `complex_alg_add` | algebra | 函數 |
| `complex_alg_all_nth_roots` | algebra | 函數 |
| `complex_alg_conj` | algebra | 函數 |
| `complex_alg_div` | algebra | 函數 |
| `complex_alg_eq` | algebra | 函數 |
| `complex_alg_eval_poly` | algebra | 函數 |
| `complex_alg_i` | algebra | 函數 |
| `complex_alg_inv` | algebra | 函數 |
| `complex_alg_mul` | algebra | 函數 |
| `complex_alg_neg` | algebra | 函數 |
| `complex_alg_of_rat` | algebra | 函數 |
| `complex_alg_pow` | algebra | 函數 |
| `complex_alg_refine_disk` | algebra | 函數 |
| `complex_alg_roots_of` | algebra | 函數 |
| `complex_alg_sub` | algebra | 函數 |
| `complex_root_isolations_are_certified` | algebra | 函數 |
| `e_irr_certificate_verify` | algebra | 函數 |
| `e_irrationality_certificate` | algebra | 函數 |
| `e_refute_rational` | algebra | 函數 |
| `liouville_cert_verify` | algebra | 函數 |
| `liouville_transcendence_certificate` | algebra | 函數 |
| `pi_refute_rational_refined` | algebra | 函數 |
| `poly_nonzero_at_e` | algebra | 函數 |
| `qcpx_hermitian_charpoly` | algebra | 函數 |
| `qcpx_hermitian_eigenvalue_isolations` | algebra | 函數 |
| `qmat_is_lll_reduced` | algebra | 函數 |
| `qmat_lll_reduce` | algebra | 函數 |
| `qmat_symmetric_eigenvalue_isolations` | algebra | 函數 |
| `qpoly_complete_factorization_expand` | algebra | 函數 |
| `qpoly_factor_certificate_check` | algebra | 函數 |
| `qpoly_factor_certified` | algebra | 函數 |
| `qpoly_factor_complete` | algebra | 函數 |
| `qpoly_factor_complete_with_budget` | algebra | 函數 |
| `qpoly_factor_hensel` | algebra | 函數 |
| `qpoly_factor_lll` | algebra | 函數 |
| `qpoly_irreducible_upto3` | algebra | 函數 |
| `qpoly_is_irreducible` | algebra | 函數 |
| `qpoly_isolate_complex_roots` | algebra | 函數 |
| `qpoly_isolate_real_roots` | algebra | 函數 |
| `qpoly_real_root_count` | algebra | 函數 |
| `qpoly_splitting_field` | algebra | 函數 |
| `qpoly_sturm_sequence` | algebra | 函數 |
| `qpoly_sturm_variations` | algebra | 函數 |
| `radical_equal_algebraic` | algebra | 函數 |
| `radical_equal_exact` | algebra | 函數 |
| `radical_int` | algebra | 函數 |
| `radical_simplify` | algebra | 函數 |
| `radical_sqrt` | algebra | 函數 |
| `radical_to_biquad` | algebra | 函數 |
| `radical_to_cubic` | algebra | 函數 |
| `radical_to_multiquad` | algebra | 函數 |
| `radical_to_multiquad_upto` | algebra | 函數 |
| `radical_to_real_alg` | algebra | 函數 |
| `radical_to_triquad` | algebra | 函數 |
| `rat_round_nearest_bigint` | algebra | 函數 |
| `real_root_isolation_refine` | algebra | 函數 |
| `real_root_isolations_are_certified` | algebra | 函數 |
| `schanuel_linear_independence_cert` | algebra | 函數 |
| `splitting_field_is_certified` | algebra | 函數 |
| `van_hoeij_lll_recombine` | algebra | 函數 |

### 一等宇宙多態與同時宣告 schema

- 規範形式：DLevelDecl 的層級 binders 與實例化；透明算子展開後的正性函子；迭代編譯的非均勻巢狀族；聯合互歸納、跨宇宙累積同時 IR 與 Dybjer–Setzer 多解碼器開放同時 IR DOpenSimultaneousIRSpec
- 範疇化：宇宙 scheme、參數迭代初始代數、累積宇宙 Σ 聯合動機與多切片纖維範疇 Famₘ(Type) 上的開放同步歸納—遞迴初始代數
- 判定：層級作用域、正性報告、生成 telescope 與依賴轉換；同時 IR 以 joint_motive_level = maxᵢ function_universe_level(fᵢ) 聯合編譯跨宇宙大/小互賴區塊；開放多解碼器同時 IR 支援驗證、碼檢查、解碼求值、依賴消去與單解碼器核心降階

| 符號 | 套件 | 類別 |
|---|---|---|
| `DLevelDecl` | root | 列舉 |
| `DLevelHitDecl` | root | 結構 |
| `DLevelHitDecl.binders` | root | 欄位 |
| `DLevelHitDecl.result_level` | root | 欄位 |
| `DLevelHitDecl.template` | root | 欄位 |
| `DLevelInductiveDecl` | root | 結構 |
| `DLevelInductiveDecl.binders` | root | 欄位 |
| `DLevelInductiveDecl.decode_level` | root | 欄位 |
| `DLevelInductiveDecl.result_level` | root | 欄位 |
| `DLevelInductiveDecl.template` | root | 欄位 |
| `DLevelTermDecl` | root | 結構 |
| `DLevelTermDecl.binders` | root | 欄位 |
| `DLevelTermDecl.body` | root | 欄位 |
| `DLevelTermDecl.name` | root | 欄位 |
| `DLevelTermDecl.ty` | root | 欄位 |
| `DLevelTermInstance` | root | 結構 |
| `DLevelTermInstance.body` | root | 欄位 |
| `DLevelTermInstance.ty` | root | 欄位 |
| `DMutualDecl` | root | 結構 |
| `DMutualDecl.components` | root | 欄位 |
| `DMutualDecl.name` | root | 欄位 |
| `DMutualPositivityReport` | root | 結構 |
| `DMutualPositivityReport.cross_edges` | root | 欄位 |
| `DMutualPositivityReport.offending_component` | root | 欄位 |
| `DMutualPositivityReport.strictly_positive` | root | 欄位 |
| `DNestedArg` | root | 列舉 |
| `DNestedArg::DNestedExternal` | root | 構造子 |
| `DNestedArg::DNestedRecursive` | root | 構造子 |
| `DNestedConstructor` | root | 結構 |
| `DNestedConstructor.args` | root | 欄位 |
| `DNestedConstructor.constraints` | root | 欄位 |
| `DNestedConstructor.name` | root | 欄位 |
| `DNestedIterDecl` | root | 結構 |
| `DNestedIterDecl.constructors` | root | 欄位 |
| `DNestedIterDecl.level` | root | 欄位 |
| `DNestedIterDecl.name` | root | 欄位 |
| `DNestedIterDecl.param_level` | root | 欄位 |
| `DNestedIterDecl.param_name` | root | 欄位 |
| `DNestedIterDecl.transform` | root | 欄位 |
| `DNestedIterFamily` | root | 結構 |
| `DNestedIterFamily.auxiliary` | root | 欄位 |
| `DNestedIterFamily.decl` | root | 欄位 |
| `DOpenIRArg` | root | 結構 |
| `DOpenIRArg.kind` | root | 欄位 |
| `DOpenIRArg.name` | root | 欄位 |
| `DOpenIRArg::equal` | root | 函數 |
| `DOpenIRArg::not_equal` | root | 函數 |
| `DOpenIRArg::to_repr` | root | 函數 |
| `DOpenIRArgKind` | root | 列舉 |
| `DOpenIRArgKind::DOpenArgCode` | root | 構造子 |
| `DOpenIRArgKind::DOpenArgDecodedCodeFn` | root | 構造子 |
| `DOpenIRArgKind::DOpenArgDecodedVal` | root | 構造子 |
| `DOpenIRArgKind::DOpenArgExternal` | root | 構造子 |
| `DOpenIRArgKind::equal` | root | 函數 |
| `DOpenIRArgKind::not_equal` | root | 函數 |
| `DOpenIRArgKind::to_repr` | root | 函數 |
| `DOpenIRArgVal` | root | 列舉 |
| `DOpenIRArgVal::DOpenValCode` | root | 構造子 |
| `DOpenIRArgVal::DOpenValCodeFn` | root | 構造子 |
| `DOpenIRArgVal::DOpenValTerm` | root | 構造子 |
| `DOpenIRCode` | root | 結構 |
| `DOpenIRCode.args` | root | 欄位 |
| `DOpenIRCode.ctor_idx` | root | 欄位 |
| `DOpenIRConstructor` | root | 結構 |
| `DOpenIRConstructor.args` | root | 欄位 |
| `DOpenIRConstructor.name` | root | 欄位 |
| `DOpenIRConstructor::equal` | root | 函數 |
| `DOpenIRConstructor::not_equal` | root | 函數 |
| `DOpenIRConstructor::to_repr` | root | 函數 |
| `DOpenIRDecoder` | root | 結構 |
| `DOpenIRDecoder.cases` | root | 欄位 |
| `DOpenIRDecoder.decode_level` | root | 欄位 |
| `DOpenIRDecoder.name` | root | 欄位 |
| `DOpenIRDecoder::equal` | root | 函數 |
| `DOpenIRDecoder::not_equal` | root | 函數 |
| `DOpenIRDecoder::to_repr` | root | 函數 |
| `DOpenSimultaneousIRSpec` | root | 結構 |
| `DOpenSimultaneousIRSpec.constructors` | root | 欄位 |
| `DOpenSimultaneousIRSpec.decoders` | root | 欄位 |
| `DOpenSimultaneousIRSpec.level` | root | 欄位 |
| `DOpenSimultaneousIRSpec.name` | root | 欄位 |
| `DOpenSimultaneousIRSpec::equal` | root | 函數 |
| `DOpenSimultaneousIRSpec::not_equal` | root | 函數 |
| `DOpenSimultaneousIRSpec::to_repr` | root | 函數 |
| `DSimultaneousFunction` | root | 結構 |
| `DSimultaneousFunction.cases` | root | 欄位 |
| `DSimultaneousFunction.name` | root | 欄位 |
| `DSimultaneousFunction.result_type` | root | 欄位 |
| `DSimultaneousIRSpec` | root | 結構 |
| `DSimultaneousIRSpec.base` | root | 欄位 |
| `DSimultaneousIRSpec.functions` | root | 欄位 |
| `DTypeOperatorDecl` | root | 結構 |
| `DTypeOperatorDecl.body` | root | 欄位 |
| `DTypeOperatorDecl.head` | root | 欄位 |
| `DTypeOperatorDecl.name` | root | 欄位 |
| `MahloReflectionCert` | root | 結構 |
| `MahloReflectionCert.closed_under_pi_sigma_path_w` | root | 欄位 |
| `MahloReflectionCert.ctx_ty_mutual_well_founded` | root | 欄位 |
| `MahloReflectionCert.mahlo_code_rank` | root | 欄位 |
| `MahloReflectionCert.strict_rank_descent` | root | 欄位 |
| `MahloReflectionCert.super_universe_rank` | root | 欄位 |
| `MahloReflectionCert.universe_level` | root | 欄位 |
| `MahloReflectionCert::equal` | root | 函數 |
| `MahloReflectionCert::not_equal` | root | 函數 |
| `MahloReflectionCert::to_repr` | root | 函數 |
| `bush_decl` | root | 函數 |
| `bush_family` | root | 函數 |
| `check_hit_moving_dimension_lift` | root | 函數 |
| `check_level_polymorphic_declarations` | root | 函數 |
| `check_mutual_declaration_positivity` | root | 函數 |
| `check_nested_iter_datatype` | root | 函數 |
| `check_phase14_joint_simultaneous_ir_mutual` | root | 函數 |
| `check_phase16_schema_large_open_positivity` | root | 函數 |
| `check_simultaneous_induction_recursion` | root | 函數 |
| `check_simultaneous_ir_compiled_decode` | root | 函數 |
| `check_simultaneous_ir_nested_foreign` | root | 函數 |
| `check_type_operator_positivity_extraction` | root | 函數 |
| `circle_level_decl` | root | 函數 |
| `code_interpretation_ir` | root | 函數 |
| `compile_nested_iter_decl` | root | 函數 |
| `darg_nested_from_type` | root | 函數 |
| `dlevel_expr_in_scope` | root | 函數 |
| `dmutual_decl` | root | 函數 |
| `dnested_constructor` | root | 函數 |
| `dnested_external` | root | 函數 |
| `dnested_iter_decl` | root | 函數 |
| `dnested_recursive` | root | 函數 |
| `dopen_arg_code` | root | 函數 |
| `dopen_arg_decoded_code_fn` | root | 函數 |
| `dopen_arg_decoded_val` | root | 函數 |
| `dopen_arg_external` | root | 函數 |
| `dopen_ir_constructor` | root | 函數 |
| `dopen_ir_decoder` | root | 函數 |
| `dopen_ir_intro` | root | 函數 |
| `dopen_simultaneous_ir_spec` | root | 函數 |
| `dopen_val_code` | root | 函數 |
| `dopen_val_code_fn` | root | 函數 |
| `dopen_val_term` | root | 函數 |
| `dsimultaneous_function` | root | 函數 |
| `dsimultaneous_ir_spec` | root | 函數 |
| `dterm_instantiate_levels` | root | 函數 |
| `dterm_levels_in_scope` | root | 函數 |
| `dtype_operator_decl` | root | 函數 |
| `eval_simultaneous_ir` | root | 函數 |
| `extract_positive_functor` | root | 函數 |
| `level_hit_decl_validate` | root | 函數 |
| `level_identity_decl` | root | 函數 |
| `level_inductive_decl_validate` | root | 函數 |
| `level_term_decl_validate` | root | 函數 |
| `list_level_decl` | root | 函數 |
| `nat_parity_double_ir` | root | 函數 |
| `nested_iter_intro_term_at` | root | 函數 |
| `nested_iter_type_term` | root | 函數 |
| `open_ir_check_code` | root | 函數 |
| `open_ir_elim_value` | root | 函數 |
| `open_ir_eval_decode` | root | 函數 |
| `open_ir_lower_single_decoder` | root | 函數 |
| `open_ir_validate` | root | 函數 |
| `simultaneous_ir_compile_decode` | root | 函數 |
| `simultaneous_ir_compile_eliminator` | root | 函數 |
| `simultaneous_ir_compile_eliminator_block` | root | 函數 |
| `simultaneous_ir_compile_joint` | root | 函數 |
| `simultaneous_ir_compile_joint_block` | root | 函數 |
| `simultaneous_ir_eliminator_type` | root | 函數 |
| `simultaneous_ir_function_universe_level` | root | 函數 |
| `simultaneous_ir_general_eliminator_type` | root | 函數 |
| `simultaneous_ir_joint_motive_level` | root | 函數 |
| `simultaneous_ir_uses_other_hypotheses` | root | 函數 |
| `simultaneous_ir_validate` | root | 函數 |
| `type_operator_is_strictly_positive` | root | 函數 |
| `type_operator_positivity` | root | 函數 |
| `verify_mahlo_universe_reflection` | root | 函數 |

### Adjoint 等價、纖維與命題截斷

- 規範形式：quasi-inverse 上加三角形 Path(Path)；improved counit；一般 fiber 的 Σ 點、lemIso 路徑與中心的收縮 (center, contraction)；PropTrunc 的 point/squash HIT；SetTruncS 的 point/hub/spoke 集合截斷 ‖A‖₀ 與開放雙向雙射認證 DVEquiv
- 範疇化：half-adjoint equivalence、contractible fiber 的等價刻畫、到命題與到 h-set（0-群胚）的左伴隨截斷反射
- 判定：adjointify_equiv_value、equiv_bidirectional_certified_in 與 equiv_contractible_fibers_value 由 hfill/hcomp/dpath 在開放脈絡構造並以依賴轉換核驗；SetTruncS 具內部 h-set 證書與向任意 h-set 的萬有消去及 ‖X‖₀≃B 等價提升

| 符號 | 套件 | 類別 |
|---|---|---|
| `DAdjointEquivParts` | root | 結構 |
| `DAdjointEquivParts.equiv` | root | 欄位 |
| `DAdjointEquivParts.triangle` | root | 欄位 |
| `adjoint_equiv_type_term` | root | 函數 |
| `adjoint_id_value` | root | 函數 |
| `adjointify_equiv_value` | root | 函數 |
| `check_adjoint_equivalence_and_fibers` | root | 函數 |
| `check_general_adjointification_and_contractible_fibers` | root | 函數 |
| `check_lemiso_generic_points` | root | 函數 |
| `check_propositional_truncation` | root | 函數 |
| `contractible_fibers_type_term` | root | 函數 |
| `dprop_is_set_value` | root | 函數 |
| `equiv_contractible_fibers_value` | root | 函數 |
| `equiv_fiber_center_value` | root | 函數 |
| `equiv_fiber_contraction_value` | root | 函數 |
| `equiv_fiber_path_value` | root | 函數 |
| `equiv_fiber_type_value` | root | 函數 |
| `equiv_improved_sect_value` | root | 函數 |
| `equiv_triangle_type` | root | 函數 |
| `equiv_with_improved_sect` | root | 函數 |
| `fiber_type_term` | root | 函數 |
| `is_contr_type_term` | root | 函數 |
| `prop_trunc_elim_prop_value` | root | 函數 |
| `prop_trunc_point_value` | root | 函數 |
| `prop_trunc_schema` | root | 函數 |
| `prop_trunc_schema_at` | root | 函數 |
| `prop_trunc_squash_path_value` | root | 函數 |
| `prop_trunc_type_value` | root | 函數 |
| `set_trunc_elim_prop_value` | root | 函數 |
| `set_trunc_elim_set_value` | root | 函數 |
| `set_trunc_equiv_of_equiv_set_value` | root | 函數 |
| `set_trunc_hub_value` | root | 函數 |
| `set_trunc_is_set_value` | root | 函數 |
| `set_trunc_loop_trivial_value` | root | 函數 |
| `set_trunc_point_term` | root | 函數 |
| `set_trunc_point_value` | root | 函數 |
| `set_trunc_rec_set_value` | root | 函數 |
| `set_trunc_schema` | root | 函數 |
| `set_trunc_schema_at` | root | 函數 |
| `set_trunc_spoke_path_value` | root | 函數 |
| `set_trunc_type_term` | root | 函數 |
| `set_trunc_type_value` | root | 函數 |
| `singleton_contraction_value` | root | 函數 |
| `trunc_point_term` | root | 函數 |
| `trunc_rec_unit_term` | root | 函數 |
| `trunc_squash_path_term` | root | 函數 |
| `trunc_squash_term` | root | 函數 |
| `trunc_type_term` | root | 函數 |

### 球面同倫代表元與 Hopf 不變量

- 規範形式：Ωⁿ 的巢狀 Path；懸掛迭代的整數度數映射；極交換 S³ 的 HIT；幾何與內部單值 Hopf 纖維叢 H:S²→Type₀ 及全空間 E_Hopf=Σ(x:S²)H(x)；IntegerS 規範整數與內部 h-set 證書；π₂(S²)=‖Ω²(S²)‖₀ 與 π₃ 商呈現
- 範疇化：懸掛函子、纖維化長精確環路序列 Ω¹(E_Hopf)≃Σ(p:Ω¹(S²))Path(S¹,subst H p base,base) 與連接映射在懸掛環路上的 Hopf–Freudenthal 恆等收縮 ∂_Hopf(σ_{S²}(p))≡p
- 判定：代表元群律、Ω² Eckmann–Hilton 與五邊形相干胞逐面驗證；Hopf 全空間環路等價經雙向認證，開放自由環路 p:Ω¹(S¹) 上證明 ∂_Hopf(σ_{S²}(p))≡p 並導出開放整數脈絡下 π₂(S²) 到 ℤ 的認證分裂收縮截面

| 符號 | 套件 | 類別 |
|---|---|---|
| `SphereLoopExpr` | root | 列舉 |
| `SphereLoopExpr::SphereLoopCompose` | root | 構造子 |
| `SphereLoopExpr::SphereLoopGenerator` | root | 構造子 |
| `SphereLoopExpr::SphereLoopInverse` | root | 構造子 |
| `SphereLoopExpr::SphereLoopRefl` | root | 構造子 |
| `SphereLoopExpr::equal` | root | 函數 |
| `SphereLoopExpr::not_equal` | root | 函數 |
| `SphereLoopExpr::to_repr` | root | 函數 |
| `based_map_type_term` | root | 函數 |
| `check_hopf_numeric` | root | 函數 |
| `check_loop_inverse_assoc_and_classification` | root | 函數 |
| `check_phase14_internal_circle_sect_and_hopf_invariant` | root | 函數 |
| `check_phase16_sphere_homotopy_and_k5` | root | 函數 |
| `check_sphere_homotopy_representatives` | root | 函數 |
| `check_sphere_loop_representatives_internal` | root | 函數 |
| `circle_degree_value` | root | 函數 |
| `circle_hit_base_value` | root | 函數 |
| `circle_hit_loop_path_value` | root | 函數 |
| `circle_hit_loop_power_value` | root | 函數 |
| `circle_rot_equiv_value` | root | 函數 |
| `circle_rot_eval_base_eq_value` | root | 函數 |
| `circle_self_loop_value` | root | 函數 |
| `dpath_trans_sym_cancel_value` | root | 函數 |
| `freudenthal_susp_loop1_preserves_refl_value` | root | 函數 |
| `freudenthal_susp_loop1_to_loop2_value` | root | 函數 |
| `homotopy_group_type_term` | root | 函數 |
| `hopf_connecting_loop_value` | root | 函數 |
| `hopf_family_value` | root | 函數 |
| `hopf_freudenthal_retraction_value` | root | 函數 |
| `hopf_invariant_susp_retraction_value` | root | 函數 |
| `hopf_invariant_value` | root | 函數 |
| `hopf_linking_number_numeric` | root | 函數 |
| `hopf_map_rat` | root | 函數 |
| `hopf_map_s3_to_s2` | root | 函數 |
| `hopf_north_fiber` | root | 函數 |
| `hopf_phase_rotate` | root | 函數 |
| `hopf_rotate_rat` | root | 函數 |
| `hopf_south_fiber` | root | 函數 |
| `hopf_total_loop_equiv_fiber_seq_value` | root | 函數 |
| `hopf_total_space_type_value` | root | 函數 |
| `hopf_unit_subst_eq_value` | root | 函數 |
| `integer_pred_value` | root | 函數 |
| `integer_schema` | root | 函數 |
| `integer_succ_value` | root | 函數 |
| `integer_term` | root | 函數 |
| `integer_to_pi2_s2_value` | root | 函數 |
| `integer_type_term` | root | 函數 |
| `integer_type_value` | root | 函數 |
| `integer_value` | root | 函數 |
| `iterated_refl_term` | root | 函數 |
| `iterated_refl_value` | root | 函數 |
| `loop_space_type_term` | root | 函數 |
| `loop_space_type_value` | root | 函數 |
| `pi2_s2_hopf_hom_value` | root | 函數 |
| `pi2_s2_hopf_retract_sect_value` | root | 函數 |
| `pi2_s2_type_value` | root | 函數 |
| `pi3_sphere_type_term` | root | 函數 |
| `sphere2_susp_loop1_to_loop2_value` | root | 函數 |
| `sphere3_from_swapped_value` | root | 函數 |
| `sphere3_swapped_equiv_value` | root | 函數 |
| `sphere3_swapped_meridian_value` | root | 函數 |
| `sphere3_swapped_north_value` | root | 函數 |
| `sphere3_swapped_retr_value` | root | 函數 |
| `sphere3_swapped_schema` | root | 函數 |
| `sphere3_swapped_sect_value` | root | 函數 |
| `sphere3_swapped_south_value` | root | 函數 |
| `sphere3_to_swapped_value` | root | 函數 |
| `sphere_degree_value` | root | 函數 |
| `sphere_loop_canonical_expr` | root | 函數 |
| `sphere_loop_canonical_value` | root | 函數 |
| `sphere_loop_compose_value` | root | 函數 |
| `sphere_loop_expr_degree` | root | 函數 |
| `sphere_loop_expr_normal_form` | root | 函數 |
| `sphere_loop_expr_normalize3_value` | root | 函數 |
| `sphere_loop_expr_of_integer` | root | 函數 |
| `sphere_loop_expr_same_class` | root | 函數 |
| `sphere_loop_expr_value` | root | 函數 |
| `sphere_loop_power_value` | root | 函數 |
| `sphere_north_term` | root | 函數 |
| `sphere_north_value` | root | 函數 |
| `sphere_type_term` | root | 函數 |
| `sphere_type_value` | root | 函數 |
| `suspend_loop_value` | root | 函數 |
| `suspension_map_value` | root | 函數 |
| `suspension_meridian_path_value` | root | 函數 |
| `suspension_unit_loop_value` | root | 函數 |

### 模組分離編譯與連結

- 規範形式：CompiledModule 的展平已檢查 telescope、exports、依賴指紋與介面公共投影；CHMODBIN v1–v3／TLV 信封與共享 DAG 項 codec；拓樸建置計畫與增量重連結報告；ArtifactRepository 結合 FIPS 180-4 SHA-256/512、RFC 8032 Pure-Ed25519 CHARTSIG 非對稱封緘、CHWALJRN 預寫式崩潰一致日誌與基於最近共同祖先（LCA）的三方合併報告
- 範疇化：模組函子的已編譯物件、簽章商不變增量重連結、唯讀公鑰驗證態射、預寫式原子提交單子與歷史圖上相對 LCA 的三方推出合併
- 判定：介面 hash 忽略 opaque body 實現下游零重編譯並以 module_instantiate 重連結；SHA-256/512 與 RFC 8032 Ed25519 逐位核驗防偽與防延展；CHWALJRN 以 SHA-256 幀校驗回滾未提交交易與斷尾位元組並冪等重放；三方合併支援收斂合併、墓碑傳播與三種衝突策略

| 符號 | 套件 | 類別 |
|---|---|---|
| `ArtifactAuthKey` | root | 結構 |
| `ArtifactAuthKey.key_id` | root | 欄位 |
| `ArtifactAuthKey.secret_a` | root | 欄位 |
| `ArtifactAuthKey.secret_b` | root | 欄位 |
| `ArtifactAuthKey::equal` | root | 函數 |
| `ArtifactAuthKey::not_equal` | root | 函數 |
| `ArtifactAuthKey::to_repr` | root | 函數 |
| `ArtifactByteStore` | root | 結構 |
| `ArtifactByteStore.list` | root | 欄位 |
| `ArtifactByteStore.read` | root | 欄位 |
| `ArtifactByteStore.remove` | root | 欄位 |
| `ArtifactByteStore.write` | root | 欄位 |
| `ArtifactCasStatus` | root | 列舉 |
| `ArtifactCasStatus::ArtifactCasAuthFailed` | root | 構造子 |
| `ArtifactCasStatus::ArtifactCasCommitted` | root | 構造子 |
| `ArtifactCasStatus::ArtifactCasConflict` | root | 構造子 |
| `ArtifactCasStatus::ArtifactCasIoError` | root | 構造子 |
| `ArtifactCasStatus::equal` | root | 函數 |
| `ArtifactCasStatus::not_equal` | root | 函數 |
| `ArtifactCasStatus::to_repr` | root | 函數 |
| `ArtifactChainEntry` | root | 結構 |
| `ArtifactChainEntry.entry_a` | root | 欄位 |
| `ArtifactChainEntry.entry_b` | root | 欄位 |
| `ArtifactChainEntry.previous_a` | root | 欄位 |
| `ArtifactChainEntry.previous_b` | root | 欄位 |
| `ArtifactChainEntry.record` | root | 欄位 |
| `ArtifactChainEntry.removed` | root | 欄位 |
| `ArtifactChainEntry.sequence` | root | 欄位 |
| `ArtifactChainEntry::equal` | root | 函數 |
| `ArtifactChainEntry::not_equal` | root | 函數 |
| `ArtifactChainEntry::to_repr` | root | 函數 |
| `ArtifactChainReport` | root | 結構 |
| `ArtifactChainReport.covers_index` | root | 欄位 |
| `ArtifactChainReport.entries` | root | 欄位 |
| `ArtifactChainReport.head_a` | root | 欄位 |
| `ArtifactChainReport.head_b` | root | 欄位 |
| `ArtifactChainReport.live_records` | root | 欄位 |
| `ArtifactChainReport.valid` | root | 欄位 |
| `ArtifactChainReport::equal` | root | 函數 |
| `ArtifactChainReport::not_equal` | root | 函數 |
| `ArtifactChainReport::to_repr` | root | 函數 |
| `ArtifactMergeConflict` | root | 結構 |
| `ArtifactMergeConflict.base_blob_key` | root | 欄位 |
| `ArtifactMergeConflict.kind` | root | 欄位 |
| `ArtifactMergeConflict.left_blob_key` | root | 欄位 |
| `ArtifactMergeConflict.name` | root | 欄位 |
| `ArtifactMergeConflict.right_blob_key` | root | 欄位 |
| `ArtifactMergeConflict::equal` | root | 函數 |
| `ArtifactMergeConflict::not_equal` | root | 函數 |
| `ArtifactMergeConflict::to_repr` | root | 函數 |
| `ArtifactMergePolicy` | root | 列舉 |
| `ArtifactMergePolicy::ArtifactMergeAbortOnConflict` | root | 構造子 |
| `ArtifactMergePolicy::ArtifactMergePreferLeft` | root | 構造子 |
| `ArtifactMergePolicy::ArtifactMergePreferRight` | root | 構造子 |
| `ArtifactMergePolicy::equal` | root | 函數 |
| `ArtifactMergePolicy::not_equal` | root | 函數 |
| `ArtifactMergePolicy::to_repr` | root | 函數 |
| `ArtifactRecord` | root | 結構 |
| `ArtifactRecord.blob_key` | root | 欄位 |
| `ArtifactRecord.byte_length` | root | 欄位 |
| `ArtifactRecord.format_version` | root | 欄位 |
| `ArtifactRecord.hash_a` | root | 欄位 |
| `ArtifactRecord.hash_b` | root | 欄位 |
| `ArtifactRecord.kind` | root | 欄位 |
| `ArtifactRecord.name` | root | 欄位 |
| `ArtifactRecord::equal` | root | 函數 |
| `ArtifactRecord::not_equal` | root | 函數 |
| `ArtifactRecord::to_repr` | root | 函數 |
| `ArtifactRepository` | root | 結構 |
| `ArtifactRepository.prefix` | root | 欄位 |
| `ArtifactRepository.puts` | root | 欄位 |
| `ArtifactRepository.recoveries` | root | 欄位 |
| `ArtifactRepository.store` | root | 欄位 |
| `ArtifactRepositoryStats` | root | 結構 |
| `ArtifactRepositoryStats.puts` | root | 欄位 |
| `ArtifactRepositoryStats.records` | root | 欄位 |
| `ArtifactRepositoryStats.recoveries` | root | 欄位 |
| `ArtifactRepositoryStats.total_bytes` | root | 欄位 |
| `ArtifactRepositoryStats::equal` | root | 函數 |
| `ArtifactRepositoryStats::not_equal` | root | 函數 |
| `ArtifactRepositoryStats::to_repr` | root | 函數 |
| `ArtifactSyncReport` | root | 結構 |
| `ArtifactSyncReport.final_head_a` | root | 欄位 |
| `ArtifactSyncReport.final_head_b` | root | 欄位 |
| `ArtifactSyncReport.ok` | root | 欄位 |
| `ArtifactSyncReport.skipped_existing_blobs` | root | 欄位 |
| `ArtifactSyncReport.tombstones_applied` | root | 欄位 |
| `ArtifactSyncReport.transferred_blobs` | root | 欄位 |
| `ArtifactSyncReport::equal` | root | 函數 |
| `ArtifactSyncReport::not_equal` | root | 函數 |
| `ArtifactSyncReport::to_repr` | root | 函數 |
| `ArtifactThreeWayMergeReport` | root | 結構 |
| `ArtifactThreeWayMergeReport.conflicts` | root | 欄位 |
| `ArtifactThreeWayMergeReport.convergent_merges` | root | 欄位 |
| `ArtifactThreeWayMergeReport.final_head_a` | root | 欄位 |
| `ArtifactThreeWayMergeReport.final_head_b` | root | 欄位 |
| `ArtifactThreeWayMergeReport.lca_entries` | root | 欄位 |
| `ArtifactThreeWayMergeReport.left_applied` | root | 欄位 |
| `ArtifactThreeWayMergeReport.merged_records` | root | 欄位 |
| `ArtifactThreeWayMergeReport.ok` | root | 欄位 |
| `ArtifactThreeWayMergeReport.right_applied` | root | 欄位 |
| `ArtifactThreeWayMergeReport.tombstones_applied` | root | 欄位 |
| `ArtifactThreeWayMergeReport::equal` | root | 函數 |
| `ArtifactThreeWayMergeReport::not_equal` | root | 函數 |
| `ArtifactThreeWayMergeReport::to_repr` | root | 函數 |
| `ArtifactWalRecoveryReport` | root | 結構 |
| `ArtifactWalRecoveryReport.active_tx_rolled_back` | root | 欄位 |
| `ArtifactWalRecoveryReport.discarded_torn_bytes` | root | 欄位 |
| `ArtifactWalRecoveryReport.replayed_transactions` | root | 欄位 |
| `ArtifactWalRecoveryReport::equal` | root | 函數 |
| `ArtifactWalRecoveryReport::not_equal` | root | 函數 |
| `ArtifactWalRecoveryReport::to_repr` | root | 函數 |
| `ArtifactWalStore` | root | 結構 |
| `ArtifactWalStore.active_tx_id` | root | 欄位 |
| `ArtifactWalStore.backing` | root | 欄位 |
| `ArtifactWalStore.next_tx_id` | root | 欄位 |
| `ArtifactWalStore.staged` | root | 欄位 |
| `ArtifactWalStore.wal_key` | root | 欄位 |
| `BftDurableCluster` | hostfs | 結構 |
| `BftDurableCluster.byzantine_ids` | hostfs | 欄位 |
| `BftDurableCluster.committed_log` | hostfs | 欄位 |
| `BftDurableCluster.disks` | hostfs | 欄位 |
| `BftDurableCluster.f_max` | hostfs | 欄位 |
| `BftDurableCluster.n_replicas` | hostfs | 欄位 |
| `BftDurableCluster::equal` | hostfs | 函數 |
| `BftDurableCluster::not_equal` | hostfs | 函數 |
| `BftDurableCluster::to_repr` | hostfs | 函數 |
| `BftEd25519WalReport` | root | 結構 |
| `BftEd25519WalReport.condensed_ledger_verified` | root | 欄位 |
| `BftEd25519WalReport.forged_signature_rejected` | root | 欄位 |
| `BftEd25519WalReport.n_validators` | root | 欄位 |
| `BftEd25519WalReport.quorum_required` | root | 欄位 |
| `BftEd25519WalReport.valid_signatures` | root | 欄位 |
| `BftEd25519WalReport.wal_committed_and_recovered` | root | 欄位 |
| `BftEd25519WalReport::equal` | root | 函數 |
| `BftEd25519WalReport::not_equal` | root | 函數 |
| `BftEd25519WalReport::to_repr` | root | 函數 |
| `BftQuorumCommit` | hostfs | 結構 |
| `BftQuorumCommit.f_byzantine_max` | hostfs | 欄位 |
| `BftQuorumCommit.key` | hostfs | 欄位 |
| `BftQuorumCommit.n_replicas` | hostfs | 欄位 |
| `BftQuorumCommit.quorum_met` | hostfs | 欄位 |
| `BftQuorumCommit.quorum_size` | hostfs | 欄位 |
| `BftQuorumCommit.signer_ids` | hostfs | 欄位 |
| `BftQuorumCommit.slot` | hostfs | 欄位 |
| `BftQuorumCommit.value` | hostfs | 欄位 |
| `BftQuorumCommit.view` | hostfs | 欄位 |
| `BftQuorumCommit::equal` | hostfs | 函數 |
| `BftQuorumCommit::not_equal` | hostfs | 函數 |
| `BftQuorumCommit::to_repr` | hostfs | 函數 |
| `BftReplicaVote` | hostfs | 結構 |
| `BftReplicaVote.key` | hostfs | 欄位 |
| `BftReplicaVote.mac_tag` | hostfs | 欄位 |
| `BftReplicaVote.replica_id` | hostfs | 欄位 |
| `BftReplicaVote.slot` | hostfs | 欄位 |
| `BftReplicaVote.value` | hostfs | 欄位 |
| `BftReplicaVote.view` | hostfs | 欄位 |
| `BftReplicaVote::equal` | hostfs | 函數 |
| `BftReplicaVote::not_equal` | hostfs | 函數 |
| `BftReplicaVote::to_repr` | hostfs | 函數 |
| `BinaryVersionPolicy` | root | 結構 |
| `BinaryVersionPolicy.current` | root | 欄位 |
| `BinaryVersionPolicy.oldest_writable` | root | 欄位 |
| `BinaryVersionPolicy.supported` | root | 欄位 |
| `BinaryVersionPolicy::equal` | root | 函數 |
| `BinaryVersionPolicy::not_equal` | root | 函數 |
| `BinaryVersionPolicy::to_repr` | root | 函數 |
| `CompiledModule` | root | 結構 |
| `CompiledModule.dependencies` | root | 欄位 |
| `CompiledModule.entries` | root | 欄位 |
| `CompiledModule.exports` | root | 欄位 |
| `CompiledModule.format_version` | root | 欄位 |
| `CompiledModule.implementation_hash` | root | 欄位 |
| `CompiledModule.interface_encoding` | root | 欄位 |
| `CompiledModule.interface_hash` | root | 欄位 |
| `CompiledModule.module_path` | root | 欄位 |
| `CompiledModule.params` | root | 欄位 |
| `CompiledModule.producer` | root | 欄位 |
| `CompiledModule::equal` | root | 函數 |
| `CompiledModule::not_equal` | root | 函數 |
| `CompiledModule::to_repr` | root | 函數 |
| `CompiledModuleEnv` | root | 結構 |
| `CompiledModuleEnv.modules` | root | 欄位 |
| `CompiledModuleEnv::equal` | root | 函數 |
| `CompiledModuleEnv::not_equal` | root | 函數 |
| `CompiledModuleEnv::to_repr` | root | 函數 |
| `CompiledModuleEnvelopeLoad` | root | 結構 |
| `CompiledModuleEnvelopeLoad.module_` | root | 欄位 |
| `CompiledModuleEnvelopeLoad.recognized_sections` | root | 欄位 |
| `CompiledModuleEnvelopeLoad.skipped_noncritical_tags` | root | 欄位 |
| `CompiledModuleEnvelopeLoad.status` | root | 欄位 |
| `CompiledModuleEnvelopeLoad::equal` | root | 函數 |
| `CompiledModuleEnvelopeLoad::not_equal` | root | 函數 |
| `CompiledModuleEnvelopeLoad::to_repr` | root | 函數 |
| `CompiledModuleStore` | root | 結構 |
| `CompiledModuleStore.blobs` | root | 欄位 |
| `CompiledModuleStore.hits` | root | 欄位 |
| `CompiledModuleStore.misses` | root | 欄位 |
| `CompiledModuleStoreStats` | root | 結構 |
| `CompiledModuleStoreStats.entries` | root | 欄位 |
| `CompiledModuleStoreStats.hits` | root | 欄位 |
| `CompiledModuleStoreStats.misses` | root | 欄位 |
| `CompiledModuleStoreStats.total_bytes` | root | 欄位 |
| `CompiledModuleStoreStats::equal` | root | 函數 |
| `CompiledModuleStoreStats::not_equal` | root | 函數 |
| `CompiledModuleStoreStats::to_repr` | root | 函數 |
| `DiskState` | hostfs | 結構 |
| `DiskState.durable_dirent` | hostfs | 欄位 |
| `DiskState.durable_inode` | hostfs | 欄位 |
| `DiskState.inode_at` | hostfs | 欄位 |
| `DiskState.inode_content` | hostfs | 欄位 |
| `DiskState.next_inode` | hostfs | 欄位 |
| `DiskState::equal` | hostfs | 函數 |
| `DiskState::not_equal` | hostfs | 函數 |
| `DiskState::to_repr` | hostfs | 函數 |
| `Ed25519Keypair` | root | 結構 |
| `Ed25519Keypair.public_key` | root | 欄位 |
| `Ed25519Keypair.seed` | root | 欄位 |
| `Ed25519Keypair::equal` | root | 函數 |
| `Ed25519Keypair::not_equal` | root | 函數 |
| `Ed25519Keypair::to_repr` | root | 函數 |
| `Ed25519PublicKey` | root | 結構 |
| `Ed25519PublicKey.bytes` | root | 欄位 |
| `Ed25519PublicKey::equal` | root | 函數 |
| `Ed25519PublicKey::not_equal` | root | 函數 |
| `Ed25519PublicKey::to_repr` | root | 函數 |
| `Ed25519Signature` | root | 結構 |
| `Ed25519Signature.bytes` | root | 欄位 |
| `Ed25519Signature::equal` | root | 函數 |
| `Ed25519Signature::not_equal` | root | 函數 |
| `Ed25519Signature::to_repr` | root | 函數 |
| `HotLoadDecision` | root | 列舉 |
| `HotLoadDecision::HotAdd` | root | 構造子 |
| `HotLoadDecision::HotOpaqueSwap` | root | 構造子 |
| `HotLoadDecision::HotReject` | root | 構造子 |
| `HotLoadDecision::HotRelink` | root | 構造子 |
| `HotLoadDecision::equal` | root | 函數 |
| `HotLoadDecision::not_equal` | root | 函數 |
| `HotLoadDecision::to_repr` | root | 函數 |
| `HotLoadEnv` | root | 結構 |
| `HotLoadEnv.epoch` | root | 欄位 |
| `HotLoadEnv.history` | root | 欄位 |
| `HotLoadEnv.modules` | root | 欄位 |
| `HotLoadEnv::equal` | root | 函數 |
| `HotLoadEnv::not_equal` | root | 函數 |
| `HotLoadEnv::to_repr` | root | 函數 |
| `HotLoadMvccSnapshot` | root | 結構 |
| `HotLoadMvccSnapshot.epoch` | root | 欄位 |
| `HotLoadMvccSnapshot.modules` | root | 欄位 |
| `HotLoadMvccSnapshot.scc_groups` | root | 欄位 |
| `HotLoadMvccSnapshot::equal` | root | 函數 |
| `HotLoadMvccSnapshot::not_equal` | root | 函數 |
| `HotLoadMvccSnapshot::to_repr` | root | 函數 |
| `HotLoadMvccStore` | root | 結構 |
| `HotLoadMvccStore.snapshots` | root | 欄位 |
| `HotLoadMvccStore::equal` | root | 函數 |
| `HotLoadMvccStore::not_equal` | root | 函數 |
| `HotLoadMvccStore::to_repr` | root | 函數 |
| `HotLoadRecord` | root | 結構 |
| `HotLoadRecord.epoch` | root | 欄位 |
| `HotLoadRecord.interface_changed` | root | 欄位 |
| `HotLoadRecord.path` | root | 欄位 |
| `HotLoadRecord.reason` | root | 欄位 |
| `HotLoadRecord.replacements` | root | 欄位 |
| `HotLoadRecord.rolled_back` | root | 欄位 |
| `HotLoadRecord::equal` | root | 函數 |
| `HotLoadRecord::not_equal` | root | 函數 |
| `HotLoadRecord::to_repr` | root | 函數 |
| `HotLoadReport` | root | 結構 |
| `HotLoadReport.accepted` | root | 欄位 |
| `HotLoadReport.epoch_after` | root | 欄位 |
| `HotLoadReport.epoch_before` | root | 欄位 |
| `HotLoadReport.interface_changed` | root | 欄位 |
| `HotLoadReport.reason` | root | 欄位 |
| `HotLoadReport.replacements` | root | 欄位 |
| `HotLoadReport.rolled_back` | root | 欄位 |
| `HotLoadReport.stale` | root | 欄位 |
| `HotLoadReport::equal` | root | 函數 |
| `HotLoadReport::not_equal` | root | 函數 |
| `HotLoadReport::to_repr` | root | 函數 |
| `ModuleBinaryLoad` | root | 結構 |
| `ModuleBinaryLoad.module_` | root | 欄位 |
| `ModuleBinaryLoad.status` | root | 欄位 |
| `ModuleBinaryLoad::equal` | root | 函數 |
| `ModuleBinaryLoad::not_equal` | root | 函數 |
| `ModuleBinaryLoad::to_repr` | root | 函數 |
| `ModuleBinaryStatus` | root | 列舉 |
| `ModuleBinaryStatus::ModuleBinaryBadMagic` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryChecksumMismatch` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryMalformed` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryOk` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryTrailingBytes` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryTruncated` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryUnsupportedVersion` | root | 構造子 |
| `ModuleBinaryStatus::ModuleBinaryValidationFailed` | root | 構造子 |
| `ModuleBinaryStatus::equal` | root | 函數 |
| `ModuleBinaryStatus::not_equal` | root | 函數 |
| `ModuleBinaryStatus::to_repr` | root | 函數 |
| `ModuleBuildPlanReport` | root | 結構 |
| `ModuleBuildPlanReport.cycle_detected` | root | 欄位 |
| `ModuleBuildPlanReport.missing_dependency` | root | 欄位 |
| `ModuleBuildPlanReport.ok` | root | 欄位 |
| `ModuleBuildPlanReport.topological_order` | root | 欄位 |
| `ModuleBuildPlanReport::equal` | root | 函數 |
| `ModuleBuildPlanReport::not_equal` | root | 函數 |
| `ModuleBuildPlanReport::to_repr` | root | 函數 |
| `ModuleCompileCache` | root | 結構 |
| `ModuleCompileCache.entries` | root | 欄位 |
| `ModuleCompileCache::equal` | root | 函數 |
| `ModuleCompileCache::not_equal` | root | 函數 |
| `ModuleCompileCache::to_repr` | root | 函數 |
| `ModuleCompileCacheEntry` | root | 結構 |
| `ModuleCompileCacheEntry.compiled` | root | 欄位 |
| `ModuleCompileCacheEntry.fingerprint` | root | 欄位 |
| `ModuleCompileCacheEntry.module_path` | root | 欄位 |
| `ModuleCompileCacheEntry::equal` | root | 函數 |
| `ModuleCompileCacheEntry::not_equal` | root | 函數 |
| `ModuleCompileCacheEntry::to_repr` | root | 函數 |
| `ModuleDependencyFingerprint` | root | 結構 |
| `ModuleDependencyFingerprint.interface_hash` | root | 欄位 |
| `ModuleDependencyFingerprint.path` | root | 欄位 |
| `ModuleDependencyFingerprint::equal` | root | 函數 |
| `ModuleDependencyFingerprint::not_equal` | root | 函數 |
| `ModuleDependencyFingerprint::to_repr` | root | 函數 |
| `ModuleIncrementalBuildReport` | root | 結構 |
| `ModuleIncrementalBuildReport.cache_hit_paths` | root | 欄位 |
| `ModuleIncrementalBuildReport.compiled_env` | root | 欄位 |
| `ModuleIncrementalBuildReport.ok` | root | 欄位 |
| `ModuleIncrementalBuildReport.recompiled_paths` | root | 欄位 |
| `ModuleIncrementalBuildReport.relinked_instance` | root | 欄位 |
| `ModuleIncrementalBuildReport::equal` | root | 函數 |
| `ModuleIncrementalBuildReport::not_equal` | root | 函數 |
| `ModuleIncrementalBuildReport::to_repr` | root | 函數 |
| `ModuleTlvSection` | root | 結構 |
| `ModuleTlvSection.critical` | root | 欄位 |
| `ModuleTlvSection.payload` | root | 欄位 |
| `ModuleTlvSection.tag` | root | 欄位 |
| `ModuleTlvSection::equal` | root | 函數 |
| `ModuleTlvSection::not_equal` | root | 函數 |
| `ModuleTlvSection::to_repr` | root | 函數 |
| `Recovery` | hostfs | 列舉 |
| `Recovery::RecoveredAbsent` | hostfs | 構造子 |
| `Recovery::RecoveredTorn` | hostfs | 構造子 |
| `Recovery::RecoveredValue` | hostfs | 構造子 |
| `Recovery::equal` | hostfs | 函數 |
| `Recovery::not_equal` | hostfs | 函數 |
| `Recovery::to_repr` | hostfs | 函數 |
| `SharedDagBundle` | root | 結構 |
| `SharedDagBundle.modules` | root | 欄位 |
| `SharedDagBundle.registry` | root | 欄位 |
| `SharedDagBundleLoad` | root | 結構 |
| `SharedDagBundleLoad.bundle` | root | 欄位 |
| `SharedDagBundleLoad.interned_dag_nodes` | root | 欄位 |
| `SharedDagBundleLoad.reused_dag_nodes` | root | 欄位 |
| `SharedDagBundleLoad.shared_term_entries` | root | 欄位 |
| `SharedDagBundleLoad.status` | root | 欄位 |
| `StoreOp` | hostfs | 列舉 |
| `StoreOp::OpFsync` | hostfs | 構造子 |
| `StoreOp::OpFsyncParent` | hostfs | 構造子 |
| `StoreOp::OpLock` | hostfs | 構造子 |
| `StoreOp::OpRename` | hostfs | 構造子 |
| `StoreOp::OpUnlink` | hostfs | 構造子 |
| `StoreOp::OpUnlock` | hostfs | 構造子 |
| `StoreOp::OpWrite` | hostfs | 構造子 |
| `StoreOp::equal` | hostfs | 函數 |
| `StoreOp::not_equal` | hostfs | 函數 |
| `StoreOp::to_repr` | hostfs | 函數 |
| `abstract_point_module` | root | 函數 |
| `artifact_byte_store_new` | root | 函數 |
| `artifact_kind_compiled_module` | root | 函數 |
| `artifact_kind_dterm_dag` | root | 函數 |
| `artifact_kind_schema_registry` | root | 函數 |
| `artifact_memory_byte_store_new` | root | 函數 |
| `artifact_merge_policy_abort` | root | 函數 |
| `artifact_merge_policy_prefer_left` | root | 函數 |
| `artifact_merge_policy_prefer_right` | root | 函數 |
| `artifact_repository_chain_entries` | root | 函數 |
| `artifact_repository_chain_head` | root | 函數 |
| `artifact_repository_chain_report` | root | 函數 |
| `artifact_repository_common_ancestor_records` | root | 函數 |
| `artifact_repository_get` | root | 函數 |
| `artifact_repository_get_chained` | root | 函數 |
| `artifact_repository_get_compiled_module` | root | 函數 |
| `artifact_repository_get_dterm_dag_into` | root | 函數 |
| `artifact_repository_get_dterm_dag_snapshot` | root | 函數 |
| `artifact_repository_get_registry_snapshot` | root | 函數 |
| `artifact_repository_list` | root | 函數 |
| `artifact_repository_merge_three_way` | root | 函數 |
| `artifact_repository_new` | root | 函數 |
| `artifact_repository_put` | root | 函數 |
| `artifact_repository_put_cas_authenticated` | root | 函數 |
| `artifact_repository_put_compiled_module` | root | 函數 |
| `artifact_repository_put_dterm_dag_snapshot` | root | 函數 |
| `artifact_repository_put_dterm_dag_terms` | root | 函數 |
| `artifact_repository_put_registry_snapshot` | root | 函數 |
| `artifact_repository_record` | root | 函數 |
| `artifact_repository_recover` | root | 函數 |
| `artifact_repository_recover_chained` | root | 函數 |
| `artifact_repository_remove` | root | 函數 |
| `artifact_repository_seal_authenticated` | root | 函數 |
| `artifact_repository_seal_ed25519` | root | 函數 |
| `artifact_repository_stats` | root | 函數 |
| `artifact_repository_sync_incremental` | root | 函數 |
| `artifact_repository_verify_all` | root | 函數 |
| `artifact_repository_verify_authenticated` | root | 函數 |
| `artifact_repository_verify_ed25519` | root | 函數 |
| `artifact_wal_abort_tx` | root | 函數 |
| `artifact_wal_begin_tx` | root | 函數 |
| `artifact_wal_byte_store` | root | 函數 |
| `artifact_wal_checkpoint` | root | 函數 |
| `artifact_wal_commit_tx` | root | 函數 |
| `artifact_wal_delete` | root | 函數 |
| `artifact_wal_put` | root | 函數 |
| `artifact_wal_recover` | root | 函數 |
| `artifact_wal_store_open` | root | 函數 |
| `bft_assemble_quorum` | hostfs | 函數 |
| `bft_check_consensus_and_crash_durability` | hostfs | 函數 |
| `bft_cluster_new` | hostfs | 函數 |
| `bft_cluster_quorum_read` | hostfs | 函數 |
| `bft_ed25519_quorum_commit_to_wal` | root | 函數 |
| `bft_propose_and_commit_durable` | hostfs | 函數 |
| `bft_quorum_threshold` | hostfs | 函數 |
| `binary_negotiate_version` | root | 函數 |
| `check_artifact_manifest_integrity_chain` | root | 函數 |
| `check_durable_write_protocol` | hostfs | 函數 |
| `check_module_binary_format` | root | 函數 |
| `check_module_binary_versions_and_store` | root | 函數 |
| `check_module_compilation` | root | 函數 |
| `check_module_runtime_hot_loading` | root | 函數 |
| `check_phase14_tlv_envelope_cas_and_incremental_sync` | root | 函數 |
| `check_phase16_crypto_ed25519_and_wal` | root | 函數 |
| `compiled_module_binary_format_version` | root | 函數 |
| `compiled_module_binary_from_hex` | root | 函數 |
| `compiled_module_binary_negotiate_version` | root | 函數 |
| `compiled_module_binary_supported_versions` | root | 函數 |
| `compiled_module_binary_to_hex` | root | 函數 |
| `compiled_module_binary_version_of` | root | 函數 |
| `compiled_module_binary_version_policy` | root | 函數 |
| `compiled_module_env_add` | root | 函數 |
| `compiled_module_env_find` | root | 函數 |
| `compiled_module_env_new` | root | 函數 |
| `compiled_module_env_to_module_env` | root | 函數 |
| `compiled_module_envelope_load_binary` | root | 函數 |
| `compiled_module_envelope_to_binary` | root | 函數 |
| `compiled_module_format_version` | root | 函數 |
| `compiled_module_from_binary` | root | 函數 |
| `compiled_module_instantiate` | root | 函數 |
| `compiled_module_is_implementation` | root | 函數 |
| `compiled_module_load_binary` | root | 函數 |
| `compiled_module_load_binary_report` | root | 函數 |
| `compiled_module_migrate_binary` | root | 函數 |
| `compiled_module_producer_default` | root | 函數 |
| `compiled_module_specialize_prefix` | root | 函數 |
| `compiled_module_store_contains` | root | 函數 |
| `compiled_module_store_get` | root | 函數 |
| `compiled_module_store_new` | root | 函數 |
| `compiled_module_store_put` | root | 函數 |
| `compiled_module_store_stats` | root | 函數 |
| `compiled_module_to_binary` | root | 函數 |
| `compiled_module_to_binary_for_peer` | root | 函數 |
| `compiled_module_to_binary_v1` | root | 函數 |
| `compiled_module_to_binary_version` | root | 函數 |
| `compiled_module_to_module_def` | root | 函數 |
| `compiled_module_validate` | root | 函數 |
| `crypto_sha256` | root | 函數 |
| `crypto_sha256_hex` | root | 函數 |
| `crypto_sha512` | root | 函數 |
| `crypto_sha512_hex` | root | 函數 |
| `disk_apply` | hostfs | 函數 |
| `disk_recover` | hostfs | 函數 |
| `disk_state_new` | hostfs | 函數 |
| `durable_delete_protocol` | hostfs | 函數 |
| `durable_write_protocol` | hostfs | 函數 |
| `ed25519_keypair_from_seed` | root | 函數 |
| `ed25519_sign` | root | 函數 |
| `ed25519_verify` | root | 函數 |
| `hot_load_apply` | root | 函數 |
| `hot_load_consistent` | root | 函數 |
| `hot_load_dependents` | root | 函數 |
| `hot_load_env_epoch` | root | 函數 |
| `hot_load_env_history` | root | 函數 |
| `hot_load_env_modules` | root | 函數 |
| `hot_load_env_new` | root | 函數 |
| `hot_load_env_to_compiled` | root | 函數 |
| `hot_load_instantiate` | root | 函數 |
| `hot_load_mvcc_commit_atomic` | root | 函數 |
| `hot_load_mvcc_read` | root | 函數 |
| `hot_load_plan` | root | 函數 |
| `hot_load_signature` | root | 函數 |
| `hot_load_stale_modules` | root | 函數 |
| `hot_load_tarjan_scc` | root | 函數 |
| `module_build_dag_incremental` | root | 函數 |
| `module_compile` | root | 函數 |
| `module_compile_cache_lookup` | root | 函數 |
| `module_compile_cache_new` | root | 函數 |
| `module_compile_cache_size` | root | 函數 |
| `module_compile_cached` | root | 函數 |
| `module_compile_with_compiled` | root | 函數 |
| `module_decl_abstract` | root | 函數 |
| `module_dependency_fingerprint` | root | 函數 |
| `module_dependency_of_compiled` | root | 函數 |
| `module_link_instantiate` | root | 函數 |
| `module_link_signature` | root | 函數 |
| `module_source_fingerprint` | root | 函數 |
| `module_topological_plan` | root | 函數 |
| `point_client_module` | root | 函數 |
| `point_implementation_module` | root | 函數 |
| `protocol_deletes_on_completion` | hostfs | 函數 |
| `protocol_durable_on_completion` | hostfs | 函數 |
| `protocol_first_tear` | hostfs | 函數 |
| `protocol_is_crash_consistent` | hostfs | 函數 |
| `shared_dag_bundle_load_binary_report` | root | 函數 |
| `shared_dag_bundle_to_binary` | root | 函數 |
| `torn_write_protocol` | hostfs | 函數 |
| `unacknowledged_delete_protocol` | hostfs | 函數 |
| `unacknowledged_write_protocol` | hostfs | 函數 |

### 範疇化總檢

- 規範形式：範疇律的布爾合取
- 範疇化：彙總各範疇的身分／合成／相干律
- 判定：逐律求值

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_categories_all` | root | 函數 |

### 定理登記與範例

- 規範形式：(名稱, Bool) 登記列；具體見證向量／項
- 範疇化：可判定命題在見證上的實現
- 判定：moon test／登記表

| 符號 | 套件 | 類別 |
|---|---|---|
| `CheckResult` | root | 結構 |
| `CheckResult.name` | root | 欄位 |
| `CheckResult.ok` | root | 欄位 |
| `all_checks_pass` | root | 函數 |
| `check_Jacobi_arbitrary_precision` | algebra | 函數 |
| `check_Jacobi_interval` | algebra | 函數 |
| `check_artifact_repository_and_dag_codec` | root | 函數 |
| `check_case_split_conversion_and_path_comp` | root | 函數 |
| `check_cdcl_proof_and_reduction` | root | 函數 |
| `check_constructor_constraints` | root | 函數 |
| `check_dcube_stratified_extensionality` | root | 函數（差分測試 oracle，非判定路徑） |
| `check_hopf_exact_rational` | root | 函數 |
| `check_hou_pattern_mgu_and_residuals` | root | 函數 |
| `check_loop_unit_3cells_and_hopf_exact` | root | 函數 |
| `check_mutual_inductives` | root | 函數 |
| `check_phase21_homotopy_hou_and_bft_mvcc` | root | 函數 |
| `check_phase21_schema_dsystem_and_frontier_bdd` | root | 函數 |
| `check_phase21_transcendence_and_crt_charpoly` | algebra | 函數 |
| `check_positivity_declarations` | root | 函數 |
| `check_qpoly_irreducibility_certificates` | algebra | 函數 |
| `check_quotient_schema` | root | 函數 |
| `check_self_family_and_gather_shapes` | root | 函數 |
| `check_simultaneous_ir_eliminator_compilation` | root | 函數 |
| `check_tower_fields` | algebra | 函數 |
| `check_universe_schemes` | root | 函數 |
| `check_variable_endpoint_hits` | root | 函數 |
| `example_projector` | root | 函數 |
| `example_unit` | root | 函數 |
| `grid` | root | 函數 |
| `inv_sqrt2` | root | 函數 |
| `print_report` | root | 函數 |
| `run_all_checks` | root | 函數 |
| `sample_terms` | root | 函數 |
| `sample_vectors` | root | 函數 |
| `vec_e3` | root | 函數 |

### 規格登記

- 規範形式：SpecEntry 六元組
- 範疇化：規格之規格；完備性對產生介面核對
- 判定：spec_registry_sound＋本審計

| 符號 | 套件 | 類別 |
|---|---|---|
| `SpecEntry` | root | 結構 |
| `SpecEntry.canonical` | root | 欄位 |
| `SpecEntry.categorical` | root | 欄位 |
| `SpecEntry.decision` | root | 欄位 |
| `SpecEntry.kind` | root | 欄位 |
| `SpecEntry.name` | root | 欄位 |
| `SpecEntry.symbols` | root | 欄位 |
| `SpecKind` | root | 列舉 |
| `SpecKind::SpecOperator` | root | 構造子 |
| `SpecKind::SpecStructure` | root | 構造子 |
| `SpecKind::SpecTheorem` | root | 構造子 |
| `SpecKind::SpecType` | root | 構造子 |
| `SpecKind::equal` | root | 函數 |
| `SpecKind::not_equal` | root | 函數 |
| `SpecKind::to_repr` | root | 函數 |
| `spec_count` | root | 函數 |
| `spec_covers` | root | 函數 |
| `spec_registry` | root | 函數 |
| `spec_registry_sound` | root | 函數 |

### 圓的萬有覆疊與 encode/decode

- 規範形式：覆疊纖維在 base 是 IntegerS 規範整數、在 loop 點是 ua 線的 GlueEquiv 型別；環路代表元為 schema 圓的 DVHitCell 路徑，繞數為規範整數值；π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ 以認證 DVEquiv 呈現
- 範疇化：helix 是圓到宇宙的纖維化族；encode 是沿環路在覆疊中的 subst 提升端點，decode 是整數消去給出的環路冪；結合 ℤ 為 h-set 與集合截斷萬有性給出基本群同構
- 判定：base 纖維以宇宙層轉換等於 ℤ；生成元/逆/refl 及複合環路跨 trans 點的 subst 直接累積繞數；在自由環路與自由整數開放脈絡下內部構造雙向同倫 decode(encode(p))≡p 與 encode(decode(z))≡z，完成 Path S¹ base x ≃ Cover(x)、Ω¹(S¹)≃ℤ 與 π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ 的完整內部證明

| 符號 | 套件 | 類別 |
|---|---|---|
| `check_circle_encode_decode` | root | 函數 |
| `check_phase15_bidirectional_bijectivity_and_pi1_circle` | root | 函數 |
| `circle_cover_value` | root | 函數 |
| `circle_decode_encode_retr_value` | root | 函數 |
| `circle_decode_encode_x_retr_value` | root | 函數 |
| `circle_decode_step_value` | root | 函數 |
| `circle_decode_value` | root | 函數 |
| `circle_decode_x_value` | root | 函數 |
| `circle_encode_decode_sect_value` | root | 函數 |
| `circle_encode_decode_x_sect_value` | root | 函數 |
| `circle_encode_decode_x_sect_with_zset_value` | root | 函數 |
| `circle_encode_pieces_value` | root | 函數 |
| `circle_encode_value` | root | 函數 |
| `circle_encode_x_value` | root | 函數 |
| `circle_hit_type_value` | root | 函數 |
| `circle_loop_space_equiv_integer_value` | root | 函數 |
| `circle_loop_space_type_value` | root | 函數 |
| `circle_path_equiv_cover_value` | root | 函數 |
| `circle_path_equiv_cover_with_zset_value` | root | 函數 |
| `integer_is_set_value` | root | 函數 |
| `integer_pred_succ_retr_value` | root | 函數 |
| `integer_succ_equiv_value` | root | 函數 |
| `integer_succ_pred_sect_value` | root | 函數 |
| `pi1_set_circle_equiv_integer_value` | root | 函數 |

### 宿主不透明立方與開盒填充

- 規範形式：立方是宿主函數（維度列→語義值／有理多項式座標）或受型別檢查語法錨定的 CheckedDCube；開盒為缺一面的邊界資料，帽是填充在缺面的限制
- 範疇化：□ 上外部立方資料與 Kan 填充條件的宿主實作，自然變換由立方 Yoneda 引理在通用對角元上唯一決定；多項式立方是精確有理座標系中的立方映射，迭代開盒填充以 F += w·(S − F|face) 逐面修正
- 判定：邊界完整性與重疊相容以型別轉換／規範多項式相等逐面驗證；外延比較提供四層分層探針、基於 P¹(𝔽₈) 的強度 t≤4 正交覆蓋陣列與五色完美雜湊族 PHF、揭穿非自然閉包的 Yoneda 自然性與忠實度審計，以及 CheckedDCube 的無探針精確語法讀回判定

| 符號 | 套件 | 類別 |
|---|---|---|
| `CheckedDCube` | root | 結構 |
| `CheckedDCube.arity` | root | 欄位 |
| `CheckedDCube.body` | root | 欄位 |
| `CheckedDCube.ctx` | root | 欄位 |
| `CheckedDCube.cube` | root | 欄位 |
| `CheckedDCube.denv` | root | 欄位 |
| `CheckedDCube.env` | root | 欄位 |
| `CheckedDCube.ty` | root | 欄位 |
| `DCubeBoxFace` | root | 結構 |
| `DCubeBoxFace.axis` | root | 欄位 |
| `DCubeBoxFace.cube` | root | 欄位 |
| `DCubeBoxFace.hi` | root | 欄位 |
| `DCubeBoxReport` | root | 結構 |
| `DCubeBoxReport.complete` | root | 欄位 |
| `DCubeBoxReport.failed_overlaps` | root | 欄位 |
| `DCubeBoxReport.overlaps_ok` | root | 欄位 |
| `DCubeCoveringReport` | root | 結構 |
| `DCubeCoveringReport.complete_for_strength` | root | 欄位 |
| `DCubeCoveringReport.equal` | root | 欄位 |
| `DCubeCoveringReport.failed` | root | 欄位 |
| `DCubeCoveringReport.interaction_strength` | root | 欄位 |
| `DCubeCoveringReport.probes` | root | 欄位 |
| `DCubeFunction` | root | 結構 |
| `DCubeFunction.arity` | root | 欄位 |
| `DCubeFunction.at` | root | 欄位 |
| `DCubeOpenBox` | root | 結構 |
| `DCubeOpenBox.ambient_dlevel` | root | 欄位 |
| `DCubeOpenBox.arity` | root | 欄位 |
| `DCubeOpenBox.faces` | root | 欄位 |
| `DCubeOpenBox.ty` | root | 欄位 |
| `DCubeStratifiedReport` | root | 結構 |
| `DCubeStratifiedReport.complete` | root | 欄位 |
| `DCubeStratifiedReport.equal` | root | 欄位 |
| `DCubeStratifiedReport.failed` | root | 欄位 |
| `DCubeStratifiedReport.probes` | root | 欄位 |
| `DCubeYonedaReport` | root | 結構 |
| `DCubeYonedaReport.audited_substitutions` | root | 欄位 |
| `DCubeYonedaReport.failed_substitutions` | root | 欄位 |
| `DCubeYonedaReport.generic_reified_term` | root | 欄位 |
| `DCubeYonedaReport.natural` | root | 欄位 |
| `DCubeYonedaReport::equal` | root | 函數 |
| `DCubeYonedaReport::not_equal` | root | 函數 |
| `DCubeYonedaReport::to_repr` | root | 函數 |
| `PolyBoxFace` | algebra | 結構 |
| `PolyBoxFace.axis` | algebra | 欄位 |
| `PolyBoxFace.cube` | algebra | 欄位 |
| `PolyBoxFace.hi` | algebra | 欄位 |
| `PolyCube` | algebra | 結構 |
| `PolyCube.coords` | algebra | 欄位 |
| `PolyCube.dim` | algebra | 欄位 |
| `PolyOpenBox` | algebra | 結構 |
| `PolyOpenBox.dim` | algebra | 欄位 |
| `PolyOpenBox.faces` | algebra | 欄位 |
| `check_dcube_open_box_filler` | root | 函數 |
| `check_dcube_stratified_tier_d` | root | 函數 |
| `check_phase14_dcube_orthogonal_array_covering` | root | 函數 |
| `check_phase15_dcube_strength4_phf_and_yoneda_audit` | root | 函數 |
| `check_poly_cubes` | algebra | 函數 |
| `checked_dcube_closed` | root | 函數 |
| `checked_dcube_extensional_eq` | root | 函數（差分測試 oracle，非判定路徑） |
| `checked_dcube_make` | root | 函數 |
| `dcube_at` | root | 函數 |
| `dcube_box_cap` | root | 函數 |
| `dcube_box_complete` | root | 函數 |
| `dcube_box_face` | root | 函數 |
| `dcube_box_face_of` | root | 函數 |
| `dcube_box_fill` | root | 函數 |
| `dcube_box_fill_verified` | root | 函數 |
| `dcube_box_fill_verified_stratified` | root | 函數 |
| `dcube_box_validate` | root | 函數 |
| `dcube_box_validate_stratified` | root | 函數 |
| `dcube_constant` | root | 函數 |
| `dcube_cubes_conv` | root | 函數 |
| `dcube_cubes_conv_covering_phf_report` | root | 函數 |
| `dcube_cubes_conv_covering_report` | root | 函數 |
| `dcube_cubes_conv_stratified` | root | 函數 |
| `dcube_cubes_conv_stratified_report` | root | 函數 |
| `dcube_face` | root | 函數 |
| `dcube_filler_faces_ok` | root | 函數 |
| `dcube_filler_faces_ok_stratified` | root | 函數 |
| `dcube_function` | root | 函數 |
| `dcube_generic_dims` | root | 函數 |
| `dcube_of_path` | root | 函數 |
| `dcube_open_box` | root | 函數 |
| `dcube_phf_5colors` | root | 函數 |
| `dcube_yoneda_audit_report` | root | 函數 |
| `poly_box_face` | algebra | 函數 |
| `poly_box_face_of` | algebra | 函數 |
| `poly_box_fill` | algebra | 函數 |
| `poly_box_fill_verified` | algebra | 函數 |
| `poly_box_filler_faces_ok` | algebra | 函數 |
| `poly_box_validate` | algebra | 函數 |
| `poly_cube_add` | algebra | 函數 |
| `poly_cube_compose` | algebra | 函數 |
| `poly_cube_const` | algebra | 函數 |
| `poly_cube_degeneracy` | algebra | 函數 |
| `poly_cube_eq` | algebra | 函數 |
| `poly_cube_eval` | algebra | 函數 |
| `poly_cube_face` | algebra | 函數 |
| `poly_cube_scale` | algebra | 函數 |
| `poly_cube_sub` | algebra | 函數 |
| `reify_natural_dcube_symbolic_o1` | root | 函數 |

### 輔助工具

- 規範形式：整數／網格等具體值
- 範疇化：基礎集合層工具
- 判定：直接計算

| 符號 | 套件 | 類別 |
|---|---|---|
| `int_pow` | root | 函數 |

### 下V泛消元新最大公因數（@gcd）

- 規範形式：F_p 約化列梯形 RREF、ℤ-矩陣 Hermite 與 Smith 範式對角不變因子、首一餘式與多生成元 Bézout 線性組合證書
- 範疇化：交換整環／體上消元帶動的最大下界格結構（整數可除格、F_p[x] 首一多項式格、F_p 子空間模格、ℤ-格對偶零化與主理想和）
- 判定：擴張歐氏演算法、F_p 消元核空間對偶正交補、HNF/SNF 單模矩陣分解 U·A·V=D 與維數模律 dim(U∩W)+dim(U+W)=dim U+dim W 核驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `FpMat` | gcd | 結構 |
| `FpMat.cols` | gcd | 欄位 |
| `FpMat.data` | gcd | 欄位 |
| `FpMat.p` | gcd | 欄位 |
| `FpMat.rows` | gcd | 欄位 |
| `FpMat::equal` | gcd | 函數 |
| `FpMat::not_equal` | gcd | 函數 |
| `FpMat::to_repr` | gcd | 函數 |
| `FpRrefResult` | gcd | 結構 |
| `FpRrefResult.pivots` | gcd | 欄位 |
| `FpRrefResult.rank` | gcd | 欄位 |
| `FpRrefResult.rref` | gcd | 欄位 |
| `FpRrefResult::equal` | gcd | 函數 |
| `FpRrefResult::not_equal` | gcd | 函數 |
| `FpRrefResult::to_repr` | gcd | 函數 |
| `UgcdSixFoldCertificate` | gcd | 結構 |
| `UgcdSixFoldCertificate.all_six_agree` | gcd | 欄位 |
| `UgcdSixFoldCertificate.arith_gcd` | gcd | 欄位 |
| `UgcdSixFoldCertificate.arith_lcm` | gcd | 欄位 |
| `UgcdSixFoldCertificate.bezout_product_holds` | gcd | 欄位 |
| `UgcdSixFoldCertificate.canon_join_classes` | gcd | 欄位 |
| `UgcdSixFoldCertificate.canon_meet_classes` | gcd | 欄位 |
| `UgcdSixFoldCertificate.m` | gcd | 欄位 |
| `UgcdSixFoldCertificate.n` | gcd | 欄位 |
| `UgcdSixFoldCertificate.snf_d1` | gcd | 欄位 |
| `UgcdSixFoldCertificate.snf_d2` | gcd | 欄位 |
| `UgcdSixFoldCertificate.tor0_order` | gcd | 欄位 |
| `UgcdSixFoldCertificate.tor1_order` | gcd | 欄位 |
| `UgcdSixFoldCertificate.tropical_valuation_homomorphic` | gcd | 欄位 |
| `UgcdSixFoldCertificate::equal` | gcd | 函數 |
| `UgcdSixFoldCertificate::not_equal` | gcd | 函數 |
| `UgcdSixFoldCertificate::to_repr` | gcd | 函數 |
| `ZMat` | gcd | 結構 |
| `ZMat.cols` | gcd | 欄位 |
| `ZMat.data` | gcd | 欄位 |
| `ZMat.rows` | gcd | 欄位 |
| `ZMat::equal` | gcd | 函數 |
| `ZMat::not_equal` | gcd | 函數 |
| `ZMat::to_repr` | gcd | 函數 |
| `ZSnfResult` | gcd | 結構 |
| `ZSnfResult.diag` | gcd | 欄位 |
| `ZSnfResult.rank` | gcd | 欄位 |
| `ZSnfResult.u` | gcd | 欄位 |
| `ZSnfResult.v` | gcd | 欄位 |
| `ZSnfResult::equal` | gcd | 函數 |
| `ZSnfResult::not_equal` | gcd | 函數 |
| `ZSnfResult::to_repr` | gcd | 函數 |
| `check_universal_gcd_laws` | gcd | 函數 |
| `fp_add` | gcd | 函數 |
| `fp_det` | gcd | 函數 |
| `fp_inv` | gcd | 函數 |
| `fp_mat_from_rows` | gcd | 函數 |
| `fp_mat_get` | gcd | 函數 |
| `fp_mat_make` | gcd | 函數 |
| `fp_mat_mul` | gcd | 函數 |
| `fp_mat_set` | gcd | 函數 |
| `fp_mat_transpose` | gcd | 函數 |
| `fp_mul` | gcd | 函數 |
| `fp_norm` | gcd | 函數 |
| `fp_nullspace_basis` | gcd | 函數 |
| `fp_rank` | gcd | 函數 |
| `fp_rref` | gcd | 函數 |
| `fp_sub` | gcd | 函數 |
| `ugcd_bigint_abs` | gcd | 函數 |
| `ugcd_bigint_ext_gcd` | gcd | 函數 |
| `ugcd_bigint_gcd` | gcd | 函數 |
| `ugcd_bigint_lcm` | gcd | 函數 |
| `ugcd_canon_meet_join_counts` | gcd | 函數 |
| `ugcd_certify_pair` | gcd | 函數 |
| `ugcd_crt_reconstruct_signed` | gcd | 函數 |
| `ugcd_derived_tor_z_orders` | gcd | 函數 |
| `ugcd_free_group_reduce` | gcd | 函數 |
| `ugcd_grassmann_subspace_duality` | gcd | 函數 |
| `ugcd_is_prime_int` | gcd | 函數 |
| `ugcd_padic_valuation` | gcd | 函數 |
| `ugcd_z_nullspace_basis` | gcd | 函數 |
| `zmat_eye` | gcd | 函數 |
| `zmat_from_int_rows` | gcd | 函數 |
| `zmat_from_rows` | gcd | 函數 |
| `zmat_get` | gcd | 函數 |
| `zmat_hnf` | gcd | 函數 |
| `zmat_make` | gcd | 函數 |
| `zmat_mul` | gcd | 函數 |
| `zmat_set` | gcd | 函數 |
| `zmat_snf` | gcd | 函數 |
| `zmat_snf_verify` | gcd | 函數 |

### X形交疊凝聚數學、凝聚高階結構×4、範疇×2與新猜想（@condensed）

- 規範形式：有限逆系塔滿射轉移矩陣、自由固態模 Z[S]^■、最小 Steenrod A(2) 自由分解、大雙分次譜序列頁、冪等規範化射與雜湊鏈不變量賬本
- 範疇化：凝聚範疇 CondCategory（極端不連通下降與固態化左伴隨反射）、規範消元範疇 CanonElimCategory、凝聚高階同倫棧 CondAnima（Milnor lim¹）、固態與 p-液態模 CondSolidModule、凝聚譜層 CondSpectralSheaf 與 Huber–熱帶雙極解析棧 CondAnalyticStack
- 判定：Mittag-Leffler 秩穩定與餘核撓率增長判定、p∈(0,1] 液態次可加性、Adem 關係與 Ext_A^{2,3}(F_2,F_2)=0（證 2η=0）、Čech 扭曲阻礙 k¹−r⁰、SNF 整數守恆律自動推導與四項新猜想實驗核驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `AdamsExtReport` | condensed | 結構 |
| `AdamsExtReport.admissible_basis_count` | condensed | 欄位 |
| `AdamsExtReport.ext_dims` | condensed | 欄位 |
| `AdamsExtReport.hopf_h1_ext12` | condensed | 欄位 |
| `AdamsExtReport.hopf_h2_ext14` | condensed | 欄位 |
| `AdamsExtReport.koszul_e_sq1_diagonal_ok` | condensed | 欄位 |
| `AdamsExtReport.s_max` | condensed | 欄位 |
| `AdamsExtReport.stem0_h0_tower` | condensed | 欄位 |
| `AdamsExtReport.t_max` | condensed | 欄位 |
| `AdamsExtReport.trunc_deg` | condensed | 欄位 |
| `AdamsExtReport.two_eta_ext23` | condensed | 欄位 |
| `AdamsExtReport::equal` | condensed | 函數 |
| `AdamsExtReport::not_equal` | condensed | 函數 |
| `AdamsExtReport::to_repr` | condensed | 函數 |
| `CanonMorphism` | condensed | 結構 |
| `CanonMorphism.cod` | condensed | 欄位 |
| `CanonMorphism.dom` | condensed | 欄位 |
| `CanonMorphism.map` | condensed | 欄位 |
| `CanonMorphism::equal` | condensed | 函數 |
| `CanonMorphism::not_equal` | condensed | 函數 |
| `CanonMorphism::to_repr` | condensed | 函數 |
| `CanonObject` | condensed | 結構 |
| `CanonObject.canon` | condensed | 欄位 |
| `CanonObject.class_count` | condensed | 欄位 |
| `CanonObject.equiv` | condensed | 欄位 |
| `CanonObject.idempotent` | condensed | 欄位 |
| `CanonObject.is_complete` | condensed | 欄位 |
| `CanonObject.name` | condensed | 欄位 |
| `CanonObject.size` | condensed | 欄位 |
| `CanonObject.sound` | condensed | 欄位 |
| `CanonObject::equal` | condensed | 函數 |
| `CanonObject::not_equal` | condensed | 函數 |
| `CanonObject::to_repr` | condensed | 函數 |
| `CondAnalyticStack` | condensed | 結構 |
| `CondAnalyticStack.archimedean_trace_rat` | condensed | 欄位 |
| `CondAnalyticStack.bipolar_coherent` | condensed | 欄位 |
| `CondAnalyticStack.laurent_cech_exact` | condensed | 欄位 |
| `CondAnalyticStack.p1_proper_and_separated` | condensed | 欄位 |
| `CondAnalyticStack.ring_name` | condensed | 欄位 |
| `CondAnalyticStack.solid_completion_gap` | condensed | 欄位 |
| `CondAnalyticStack.topos_laurent_site_valid` | condensed | 欄位 |
| `CondAnalyticStack.tropical_bend_roots_count` | condensed | 欄位 |
| `CondAnalyticStack::equal` | condensed | 函數 |
| `CondAnalyticStack::not_equal` | condensed | 函數 |
| `CondAnalyticStack::to_repr` | condensed | 函數 |
| `CondAnima` | condensed | 結構 |
| `CondAnima.coker_torsion_orders` | condensed | 欄位 |
| `CondAnima.lim0_pi1_rank` | condensed | 欄位 |
| `CondAnima.milnor_lim1_nonvanishing` | condensed | 欄位 |
| `CondAnima.mittag_leffler_holds` | condensed | 欄位 |
| `CondAnima.name` | condensed | 欄位 |
| `CondAnima.pi0_tower` | condensed | 欄位 |
| `CondAnima.pi1_bonding` | condensed | 欄位 |
| `CondAnima.pi1_ranks` | condensed | 欄位 |
| `CondAnima::equal` | condensed | 函數 |
| `CondAnima::not_equal` | condensed | 函數 |
| `CondAnima::to_repr` | condensed | 函數 |
| `CondChain` | condensed | 結構 |
| `CondChain.dims` | condensed | 欄位 |
| `CondChain.p` | condensed | 欄位 |
| `CondChain.trans` | condensed | 欄位 |
| `CondChain::equal` | condensed | 函數 |
| `CondChain::not_equal` | condensed | 函數 |
| `CondChain::to_repr` | condensed | 函數 |
| `CondConjectureEntry` | condensed | 結構 |
| `CondConjectureEntry.consistent_with_status` | condensed | 欄位 |
| `CondConjectureEntry.id` | condensed | 欄位 |
| `CondConjectureEntry.instances_checked` | condensed | 欄位 |
| `CondConjectureEntry.status` | condensed | 欄位 |
| `CondConjectureEntry.title` | condensed | 欄位 |
| `CondConjectureEntry::equal` | condensed | 函數 |
| `CondConjectureEntry::not_equal` | condensed | 函數 |
| `CondConjectureEntry::to_repr` | condensed | 函數 |
| `CondConjectureStatus` | condensed | 列舉 |
| `CondConjectureStatus::RefutedWithWitness` | condensed | 構造子 |
| `CondConjectureStatus::ThresholdMeasured` | condensed | 構造子 |
| `CondConjectureStatus::VerifiedUpToBound` | condensed | 構造子 |
| `CondConjectureStatus::equal` | condensed | 函數 |
| `CondConjectureStatus::not_equal` | condensed | 函數 |
| `CondConjectureStatus::to_repr` | condensed | 函數 |
| `CondInvariantLedger` | condensed | 結構 |
| `CondInvariantLedger.entries` | condensed | 欄位 |
| `CondInvariantLedger.tip` | condensed | 欄位 |
| `CondInvariantLedger::equal` | condensed | 函數 |
| `CondInvariantLedger::not_equal` | condensed | 函數 |
| `CondInvariantLedger::to_repr` | condensed | 函數 |
| `CondLedgerEntry` | condensed | 結構 |
| `CondLedgerEntry.hash` | condensed | 欄位 |
| `CondLedgerEntry.kind` | condensed | 欄位 |
| `CondLedgerEntry.parents` | condensed | 欄位 |
| `CondLedgerEntry.prev_hash` | condensed | 欄位 |
| `CondLedgerEntry.seq` | condensed | 欄位 |
| `CondLedgerEntry.values` | condensed | 欄位 |
| `CondLedgerEntry::equal` | condensed | 函數 |
| `CondLedgerEntry::not_equal` | condensed | 函數 |
| `CondLedgerEntry::to_repr` | condensed | 函數 |
| `CondProMorphism` | condensed | 結構 |
| `CondProMorphism.cod` | condensed | 欄位 |
| `CondProMorphism.dom` | condensed | 欄位 |
| `CondProMorphism.level_maps` | condensed | 欄位 |
| `CondProMorphism::equal` | condensed | 函數 |
| `CondProMorphism::not_equal` | condensed | 函數 |
| `CondProMorphism::to_repr` | condensed | 函數 |
| `CondProfinite` | condensed | 結構 |
| `CondProfinite.maps` | condensed | 欄位 |
| `CondProfinite.p` | condensed | 欄位 |
| `CondProfinite.sizes` | condensed | 欄位 |
| `CondProfinite::equal` | condensed | 函數 |
| `CondProfinite::not_equal` | condensed | 函數 |
| `CondProfinite::to_repr` | condensed | 函數 |
| `CondSolidModule` | condensed | 結構 |
| `CondSolidModule.base_tower` | condensed | 欄位 |
| `CondSolidModule.discrete_hom_dim` | condensed | 欄位 |
| `CondSolidModule.ext1_vanishes` | condensed | 欄位 |
| `CondSolidModule.free_chain` | condensed | 欄位 |
| `CondSolidModule.liquid_p_den` | condensed | 欄位 |
| `CondSolidModule.liquid_p_num` | condensed | 欄位 |
| `CondSolidModule.liquid_subadditive_holds` | condensed | 欄位 |
| `CondSolidModule.solid_gap` | condensed | 欄位 |
| `CondSolidModule.solid_hom_dim` | condensed | 欄位 |
| `CondSolidModule::equal` | condensed | 函數 |
| `CondSolidModule::not_equal` | condensed | 函數 |
| `CondSolidModule::to_repr` | condensed | 函數 |
| `CondSpectralSheaf` | condensed | 結構 |
| `CondSpectralSheaf.betti` | condensed | 欄位 |
| `CondSpectralSheaf.cech_k1_minus_r0` | condensed | 欄位 |
| `CondSpectralSheaf.dd_zero` | condensed | 欄位 |
| `CondSpectralSheaf.e2_total_rank` | condensed | 欄位 |
| `CondSpectralSheaf.e4_total_rank` | condensed | 欄位 |
| `CondSpectralSheaf.global_twist_glues` | condensed | 欄位 |
| `CondSpectralSheaf.h3_twist_active` | condensed | 欄位 |
| `CondSpectralSheaf.space_name` | condensed | 欄位 |
| `CondSpectralSheaf::equal` | condensed | 函數 |
| `CondSpectralSheaf::not_equal` | condensed | 函數 |
| `CondSpectralSheaf::to_repr` | condensed | 函數 |
| `KoszulTorReport` | condensed | 結構 |
| `KoszulTorReport.dd_zero_all_degrees` | condensed | 欄位 |
| `KoszulTorReport.exact_in_positive_degrees` | condensed | 欄位 |
| `KoszulTorReport.generators_g` | condensed | 欄位 |
| `KoszulTorReport.tor_classical_ranks` | condensed | 欄位 |
| `KoszulTorReport.tor_two_sided_ranks` | condensed | 欄位 |
| `KoszulTorReport::equal` | condensed | 函數 |
| `KoszulTorReport::not_equal` | condensed | 函數 |
| `KoszulTorReport::to_repr` | condensed | 函數 |
| `SerreReport` | condensed | 結構 |
| `SerreReport.base_betti` | condensed | 欄位 |
| `SerreReport.converges_to_s3` | condensed | 欄位 |
| `SerreReport.dd_zero` | condensed | 欄位 |
| `SerreReport.e2_totals` | condensed | 欄位 |
| `SerreReport.e_inf_totals` | condensed | 欄位 |
| `SerreReport.fiber_betti` | condensed | 欄位 |
| `SerreReport.hurewicz_h2_s2_rank` | condensed | 欄位 |
| `SerreReport::equal` | condensed | 函數 |
| `SerreReport::not_equal` | condensed | 函數 |
| `SerreReport::to_repr` | condensed | 函數 |
| `SsPage` | condensed | 結構 |
| `SsPage.diffs` | condensed | 欄位 |
| `SsPage.dims` | condensed | 欄位 |
| `SsPage.np` | condensed | 欄位 |
| `SsPage.nq` | condensed | 欄位 |
| `SsPage.prime` | condensed | 欄位 |
| `SsPage.qflip` | condensed | 欄位 |
| `SsPage.r` | condensed | 欄位 |
| `SsPage::equal` | condensed | 函數 |
| `SsPage::not_equal` | condensed | 函數 |
| `SsPage::to_repr` | condensed | 函數 |
| `adams_ext_f2_report` | condensed | 函數 |
| `canon_cat_comp` | condensed | 函數 |
| `canon_cat_id` | condensed | 函數 |
| `canon_morphism_valid` | condensed | 函數 |
| `canon_object_build` | condensed | 函數 |
| `cond_analytic_stack_build` | condensed | 函數 |
| `cond_anima_build` | condensed | 函數 |
| `cond_cat_comp` | condensed | 函數 |
| `cond_cat_id` | condensed | 函數 |
| `cond_cat_proj1` | condensed | 函數 |
| `cond_chain_free` | condensed | 函數 |
| `cond_chain_lim_dim` | condensed | 函數 |
| `cond_chain_locally_constant` | condensed | 函數 |
| `cond_chain_tensor` | condensed | 函數 |
| `cond_check_federation_all` | condensed | 函數 |
| `cond_check_structure_3_and_spectral_homotopy` | condensed | 函數 |
| `cond_check_structure_4_category_2_ledger_and_conjectures` | condensed | 函數 |
| `cond_check_structures_1_2_and_category_1` | condensed | 函數 |
| `cond_evaluate_new_conjectures` | condensed | 函數 |
| `cond_ledger_append` | condensed | 函數 |
| `cond_ledger_audit_laws` | condensed | 函數 |
| `cond_ledger_derive_invariants` | condensed | 函數 |
| `cond_ledger_new` | condensed | 函數 |
| `cond_ledger_verify` | condensed | 函數 |
| `cond_liquid_subadditive_check` | condensed | 函數 |
| `cond_mittag_leffler_holds` | condensed | 函數 |
| `cond_pro_morphism_valid` | condensed | 函數 |
| `cond_prof_cantor` | condensed | 函數 |
| `cond_prof_coproduct` | condensed | 函數 |
| `cond_prof_n_inf` | condensed | 函數 |
| `cond_prof_product` | condensed | 函數 |
| `cond_prof_pt` | condensed | 函數 |
| `cond_prof_valid` | condensed | 函數 |
| `cond_prof_zq` | condensed | 函數 |
| `cond_solid_module_build` | condensed | 函數 |
| `cond_spectral_sheaf_build` | condensed | 函數 |
| `cond_steenrod_adem_pair` | condensed | 函數 |
| `koszul_tor_report` | condensed | 函數 |
| `serre_hopf_fibration_report` | condensed | 函數 |
| `ss_dq` | condensed | 函數 |
| `ss_page_dd_zero` | condensed | 函數 |
| `ss_page_make` | condensed | 函數 |
| `ss_page_next` | condensed | 函數 |
| `ss_set_diff` | condensed | 函數 |
| `ss_total_by_degree` | condensed | 函數 |

### 第七聯邦：多線性超行列式、離散 Radon 變換、Clifford 旋量規範場與 VR 持續同調（@tensor）

- 規範形式：F_3 全體 6561 個 2×2×2 張量秩與超行列式索引表、有限平面關聯矩陣與 Sherman–Morrison 顯式逆、Jordan–Wigner γ 矩陣與 T² 全純類、非交叉弦遮罩與全維度 VR 單純邊界複形
- 範疇化：SL₂³×S₃ 多線性不變量、有限幾何積分對偶、扭曲群代數辛根中心與離散主叢模空間、非交叉森林 Grothendieck 層景、Kalton–Ostrovskii 對應失真與 Viro–Krasner 熱帶超體
- 判定：O(|R₁|²) 精確秩分解 [1,128,5568,864]、仿射修正 Plancherel 能量恆等式、偶奇維旋量中心分裂、[T-NC-Free] 單調自由與 K₄ 反例、同調—上同調轉置秩對偶核驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `DiscreteRadon` | tensor | 結構 |
| `DiscreteRadon.dirs` | tensor | 欄位 |
| `DiscreteRadon.n` | tensor | 欄位 |
| `DiscreteRadon.p` | tensor | 欄位 |
| `DiscreteRadon::equal` | tensor | 函數 |
| `DiscreteRadon::not_equal` | tensor | 函數 |
| `DiscreteRadon::to_repr` | tensor | 函數 |
| `F3Tensor222Atlas` | tensor | 結構 |
| `F3Tensor222Atlas.det_nonzero_count` | tensor | 欄位 |
| `F3Tensor222Atlas.det_zero_count` | tensor | 欄位 |
| `F3Tensor222Atlas.hyperdets` | tensor | 欄位 |
| `F3Tensor222Atlas.rank2_decomp_counts` | tensor | 欄位 |
| `F3Tensor222Atlas.rank2_det_nonzero_count` | tensor | 欄位 |
| `F3Tensor222Atlas.rank2_det_zero_count` | tensor | 欄位 |
| `F3Tensor222Atlas.rank3_det_nonzero_count` | tensor | 欄位 |
| `F3Tensor222Atlas.rank3_det_zero_count` | tensor | 欄位 |
| `F3Tensor222Atlas.rank_counts` | tensor | 欄位 |
| `F3Tensor222Atlas.ranks` | tensor | 欄位 |
| `F3Tensor222Atlas.total_tensors` | tensor | 欄位 |
| `F3Tensor222Atlas::equal` | tensor | 函數 |
| `F3Tensor222Atlas::not_equal` | tensor | 函數 |
| `F3Tensor222Atlas::to_repr` | tensor | 函數 |
| `FiniteMetricSpace` | tensor | 結構 |
| `FiniteMetricSpace.dist` | tensor | 欄位 |
| `FiniteMetricSpace.n` | tensor | 欄位 |
| `FiniteMetricSpace::equal` | tensor | 函數 |
| `FiniteMetricSpace::not_equal` | tensor | 函數 |
| `FiniteMetricSpace::to_repr` | tensor | 函數 |
| `Tensor3` | tensor | 結構 |
| `Tensor3.data` | tensor | 欄位 |
| `Tensor3.dim0` | tensor | 欄位 |
| `Tensor3.dim1` | tensor | 欄位 |
| `Tensor3.dim2` | tensor | 欄位 |
| `Tensor3.field` | tensor | 欄位 |
| `Tensor3::equal` | tensor | 函數 |
| `Tensor3::not_equal` | tensor | 函數 |
| `Tensor3::to_repr` | tensor | 函數 |
| `TriangulationFlipReport` | tensor | 結構 |
| `TriangulationFlipReport.catalan_count` | tensor | 欄位 |
| `TriangulationFlipReport.dual_tree_rows` | tensor | 欄位 |
| `TriangulationFlipReport.flip_edges` | tensor | 欄位 |
| `TriangulationFlipReport.is_connected` | tensor | 欄位 |
| `TriangulationFlipReport.is_regular_degree` | tensor | 欄位 |
| `TriangulationFlipReport.n_gon` | tensor | 欄位 |
| `TriangulationFlipReport::equal` | tensor | 函數 |
| `TriangulationFlipReport::not_equal` | tensor | 函數 |
| `TriangulationFlipReport::to_repr` | tensor | 函數 |
| `TwistedGroupReport` | tensor | 結構 |
| `TwistedGroupReport.center_dim` | tensor | 欄位 |
| `TwistedGroupReport.coboundary_gauge_invariant` | tensor | 欄位 |
| `TwistedGroupReport.cocycle_sum_mod_ell` | tensor | 欄位 |
| `TwistedGroupReport.dim_d` | tensor | 欄位 |
| `TwistedGroupReport.ell` | tensor | 欄位 |
| `TwistedGroupReport.group_order` | tensor | 欄位 |
| `TwistedGroupReport.radical_size` | tensor | 欄位 |
| `TwistedGroupReport::equal` | tensor | 函數 |
| `TwistedGroupReport::not_equal` | tensor | 函數 |
| `TwistedGroupReport::to_repr` | tensor | 函數 |
| `VrHomologyReport` | tensor | 結構 |
| `VrHomologyReport.betti_cohomology` | tensor | 欄位 |
| `VrHomologyReport.betti_homology` | tensor | 欄位 |
| `VrHomologyReport.chain_complex_dd_zero` | tensor | 欄位 |
| `VrHomologyReport.euler_betti` | tensor | 欄位 |
| `VrHomologyReport.euler_simplicial` | tensor | 欄位 |
| `VrHomologyReport.homology_cohomology_dual` | tensor | 欄位 |
| `VrHomologyReport.scale_r` | tensor | 欄位 |
| `VrHomologyReport.simplex_counts` | tensor | 欄位 |
| `VrHomologyReport::equal` | tensor | 函數 |
| `VrHomologyReport::not_equal` | tensor | 函數 |
| `VrHomologyReport::to_repr` | tensor | 函數 |
| `clifford_ramond_anticommutator_ok` | tensor | 函數 |
| `f3_tensor222_atlas_build` | tensor | 函數 |
| `f3_tensor_code` | tensor | 函數 |
| `f3_tensor_of_code` | tensor | 函數 |
| `hyper_check_marty_hypergroup` | tensor | 函數 |
| `hyper_tropical_viro_op` | tensor | 函數 |
| `lattice_torus_gauge_moduli_verify` | tensor | 函數 |
| `metric_check_axioms` | tensor | 函數 |
| `metric_diameter` | tensor | 函數 |
| `metric_gh_twice_exact` | tensor | 函數 |
| `metric_vr_homology_report` | tensor | 函數 |
| `nc_chords_cross` | tensor | 函數 |
| `nc_forest_grothendieck_site_ok` | tensor | 函數 |
| `nc_mst_vs_unconstrained_mst` | tensor | 函數 |
| `nc_polygon_triangulations_flip_report` | tensor | 函數 |
| `radon_apply_exact` | tensor | 函數 |
| `radon_check_gram_identity` | tensor | 函數 |
| `radon_energy_triple` | tensor | 函數 |
| `radon_incidence_matrix` | tensor | 函數 |
| `radon_invert_fp` | tensor | 函數 |
| `radon_line_points` | tensor | 函數 |
| `radon_make` | tensor | 函數 |
| `t3_add` | tensor | 函數 |
| `t3_check_sl2_shear_and_s3_invariance` | tensor | 函數 |
| `t3_flatten` | tensor | 函數 |
| `t3_flatten_rank_lower_bound` | tensor | 函數 |
| `t3_get` | tensor | 函數 |
| `t3_hyperdet222` | tensor | 函數 |
| `t3_make` | tensor | 函數 |
| `t3_of` | tensor | 函數 |
| `t3_rank1_scaled` | tensor | 函數 |
| `tensor_check_federation_laws` | tensor | 函數 |
| `twisted_group_clifford_cocycle_report` | tensor | 函數 |

### 第七聯邦：Lakatos 十二猜想演化圖譜、守恆律自動發現與五大認識論透鏡（@conjecture）

- 規範形式：觀測軌跡 F_p 零空間成對加減飽和整數基、五謂詞蘊含閉包與最小反例矩陣、五態 Lakatos 猜想生命週期與持久雜湊鏈入賬紀錄
- 範疇化：跨尺度演化守恆律函子 [E-Derive]+[P-Transfer]、相對／對偶／對比／蘊含／比率五大認識論透鏡與七大聯邦 K₇ 完全圖星稜柱大一統
- 判定：6 組演化定律自動發現並剔除小規模巧合（含三次至四次平面曲線 Hironaka–Serre 虧格轉移）、5 項天真猜想反例推翻與精煉定理配對、共 12 項跨聯邦猜想（CONJ-01..12）機器核驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `ConjectureLifecycle` | conjecture | 列舉 |
| `ConjectureLifecycle::LcDerivedAndTransferred` | conjecture | 構造子 |
| `ConjectureLifecycle::LcOpenFrontier` | conjecture | 構造子 |
| `ConjectureLifecycle::LcPhaseTransition` | conjecture | 構造子 |
| `ConjectureLifecycle::LcRefutedAndRefined` | conjecture | 構造子 |
| `ConjectureLifecycle::LcVerifiedUpToBound` | conjecture | 構造子 |
| `ConjectureLifecycle::equal` | conjecture | 函數 |
| `ConjectureLifecycle::not_equal` | conjecture | 函數 |
| `ConjectureLifecycle::to_repr` | conjecture | 函數 |
| `ConjectureSynthesisSummary` | conjecture | 結構 |
| `ConjectureSynthesisSummary.all_consistent` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.derived_and_transferred` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.epistemic_lenses_ledger_ok` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.evolution_families_passed` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.new_creative_theorems_ok` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.open_frontiers` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.phase_transitions` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.refuted_and_refined` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.total_conjectures` | conjecture | 欄位 |
| `ConjectureSynthesisSummary.verified_bounded` | conjecture | 欄位 |
| `ConjectureSynthesisSummary::equal` | conjecture | 函數 |
| `ConjectureSynthesisSummary::not_equal` | conjecture | 函數 |
| `ConjectureSynthesisSummary::to_repr` | conjecture | 函數 |
| `EpistemicLensKind` | conjecture | 列舉 |
| `EpistemicLensKind::LensContrast` | conjecture | 構造子 |
| `EpistemicLensKind::LensDual` | conjecture | 構造子 |
| `EpistemicLensKind::LensImplication` | conjecture | 構造子 |
| `EpistemicLensKind::LensRelative` | conjecture | 構造子 |
| `EpistemicLensKind::LensScaleRatio` | conjecture | 構造子 |
| `EpistemicLensKind::equal` | conjecture | 函數 |
| `EpistemicLensKind::not_equal` | conjecture | 函數 |
| `EpistemicLensKind::to_repr` | conjecture | 函數 |
| `EvolutionTransferReport` | conjecture | 結構 |
| `EvolutionTransferReport.derived_count` | conjecture | 欄位 |
| `EvolutionTransferReport.family_id` | conjecture | 欄位 |
| `EvolutionTransferReport.mirage_rejected_on_transfer` | conjecture | 欄位 |
| `EvolutionTransferReport.target_derived_on_train` | conjecture | 欄位 |
| `EvolutionTransferReport.target_holds_on_transfer` | conjecture | 欄位 |
| `EvolutionTransferReport::equal` | conjecture | 函數 |
| `EvolutionTransferReport::not_equal` | conjecture | 函數 |
| `EvolutionTransferReport::to_repr` | conjecture | 函數 |
| `ImplicationLatticeReport` | conjecture | 結構 |
| `ImplicationLatticeReport.counterexamples` | conjecture | 欄位 |
| `ImplicationLatticeReport.implies` | conjecture | 欄位 |
| `ImplicationLatticeReport.nontrivial_equiv_pairs` | conjecture | 欄位 |
| `ImplicationLatticeReport.num_predicates` | conjecture | 欄位 |
| `ImplicationLatticeReport.num_samples` | conjecture | 欄位 |
| `ImplicationLatticeReport.strict_unidirectional_edges` | conjecture | 欄位 |
| `ImplicationLatticeReport::equal` | conjecture | 函數 |
| `ImplicationLatticeReport::not_equal` | conjecture | 函數 |
| `ImplicationLatticeReport::to_repr` | conjecture | 函數 |
| `ObservationRowSet` | conjecture | 結構 |
| `ObservationRowSet.columns` | conjecture | 欄位 |
| `ObservationRowSet.name` | conjecture | 欄位 |
| `ObservationRowSet.rows` | conjecture | 欄位 |
| `ObservationRowSet::equal` | conjecture | 函數 |
| `ObservationRowSet::not_equal` | conjecture | 函數 |
| `ObservationRowSet::to_repr` | conjecture | 函數 |
| `UpdatedConjectureRecord` | conjecture | 結構 |
| `UpdatedConjectureRecord.epistemic_lens` | conjecture | 欄位 |
| `UpdatedConjectureRecord.federations_bridged` | conjecture | 欄位 |
| `UpdatedConjectureRecord.id` | conjecture | 欄位 |
| `UpdatedConjectureRecord.lifecycle` | conjecture | 欄位 |
| `UpdatedConjectureRecord.title` | conjecture | 欄位 |
| `UpdatedConjectureRecord.verified_consistent` | conjecture | 欄位 |
| `UpdatedConjectureRecord::equal` | conjecture | 函數 |
| `UpdatedConjectureRecord::not_equal` | conjecture | 函數 |
| `UpdatedConjectureRecord::to_repr` | conjecture | 函數 |
| `check_conjecture_discovery_federation` | conjecture | 函數 |
| `derive_invariant_relations` | conjecture | 函數 |
| `discover_six_evolution_laws` | conjecture | 函數 |
| `evaluate_five_epistemic_lenses_into_ledger` | conjecture | 函數 |
| `evaluate_updated_conjecture_atlas` | conjecture | 函數 |
| `implication_lattice_build` | conjecture | 函數 |
| `relation_in_derived_span` | conjecture | 函數 |
| `rowset_holds_exact` | conjecture | 函數 |
| `rowset_holds_mod` | conjecture | 函數 |
| `synthesize_and_verify_conjecture_engine` | conjecture | 函數 |

### 有限對稱：圖規範形與自同構

- 規範形式：規範標號、鄰接編碼與指紋
- 範疇化：簡單無向圖同構類與自同構群作用
- 判定：個體化—精煉搜尋一次給規範形與自同構生成元

| 符號 | 套件 | 類別 |
|---|---|---|
| `BitVec` | symlib | 結構 |
| `BitVec.n` | symlib | 欄位 |
| `BitVec.words` | symlib | 欄位 |
| `BitVec::and_in_place` | symlib | 函數 |
| `BitVec::and_not_in_place` | symlib | 函數 |
| `BitVec::contains` | symlib | 函數 |
| `BitVec::copy` | symlib | 函數 |
| `BitVec::count_ones` | symlib | 函數 |
| `BitVec::each` | symlib | 函數 |
| `BitVec::equal` | symlib | 函數 |
| `BitVec::get` | symlib | 函數 |
| `BitVec::hash` | symlib | 函數 |
| `BitVec::is_empty` | symlib | 函數 |
| `BitVec::length` | symlib | 函數 |
| `BitVec::make` | symlib | 函數 |
| `BitVec::make_full` | symlib | 函數 |
| `BitVec::or_in_place` | symlib | 函數 |
| `BitVec::output` | symlib | 函數 |
| `BitVec::set` | symlib | 函數 |
| `BitVec::to_array` | symlib | 函數 |
| `BitVec::to_repr` | symlib | 函數 |
| `BitVec::to_string` | symlib | 函數 |
| `BitVec::unset` | symlib | 函數 |
| `Graph` | symlib | 結構 |
| `Graph.adj` | symlib | 欄位 |
| `Graph.m` | symlib | 欄位 |
| `Graph.n` | symlib | 欄位 |
| `Graph.rows` | symlib | 欄位 |
| `Graph::build` | symlib | 函數 |
| `Graph::complement` | symlib | 函數 |
| `Graph::complete` | symlib | 函數 |
| `Graph::complete_bipartite` | symlib | 函數 |
| `Graph::components` | symlib | 函數 |
| `Graph::cycle` | symlib | 函數 |
| `Graph::degree` | symlib | 函數 |
| `Graph::degree_seq` | symlib | 函數 |
| `Graph::disjoint_union` | symlib | 函數 |
| `Graph::edge_list` | symlib | 函數 |
| `Graph::empty` | symlib | 函數 |
| `Graph::equal` | symlib | 函數 |
| `Graph::from_edges` | symlib | 函數 |
| `Graph::has_edge` | symlib | 函數 |
| `Graph::hypercube` | symlib | 函數 |
| `Graph::induced_subgraph` | symlib | 函數 |
| `Graph::is_regular` | symlib | 函數 |
| `Graph::neighbors` | symlib | 函數 |
| `Graph::not_equal` | symlib | 函數 |
| `Graph::order` | symlib | 函數 |
| `Graph::output` | symlib | 函數 |
| `Graph::path` | symlib | 函數 |
| `Graph::petersen` | symlib | 函數 |
| `Graph::random` | symlib | 函數 |
| `Graph::relabel` | symlib | 函數 |
| `Graph::size` | symlib | 函數 |
| `Graph::star` | symlib | 函數 |
| `Graph::to_repr` | symlib | 函數 |
| `Graph::to_string` | symlib | 函數 |
| `KeyLut` | symlib | 結構 |
| `KeyLut.keys` | symlib | 欄位 |
| `KeyLut.mask` | symlib | 欄位 |
| `KeyLut.vals` | symlib | 欄位 |
| `KeyLut::at` | symlib | 函數 |
| `KeyLut::find` | symlib | 函數 |
| `Part` | symlib | 結構 |
| `Part.cell_of` | symlib | 欄位 |
| `Part.lab` | symlib | 欄位 |
| `Part.n` | symlib | 欄位 |
| `Part.ptn` | symlib | 欄位 |
| `Part::cell_count` | symlib | 函數 |
| `Part::cell_sizes` | symlib | 函數 |
| `Part::cells` | symlib | 函數 |
| `Part::copy` | symlib | 函數 |
| `Part::discrete` | symlib | 函數 |
| `Part::is_discrete` | symlib | 函數 |
| `Part::trivial` | symlib | 函數 |
| `SearchResult` | symlib | 結構 |
| `SearchResult.aut_gens` | symlib | 欄位 |
| `SearchResult.canon_enc` | symlib | 欄位 |
| `SearchResult.canon_lab` | symlib | 欄位 |
| `SearchResult.leaves` | symlib | 欄位 |
| `SearchResult.n` | symlib | 欄位 |
| `SearchResult.nodes` | symlib | 欄位 |
| `SearchResult.ties` | symlib | 欄位 |
| `SearchStats` | symlib | 結構 |
| `SearchStats.autos` | symlib | 欄位 |
| `SearchStats.leaves` | symlib | 欄位 |
| `SearchStats.nodes` | symlib | 欄位 |
| `analyze` | symlib | 函數 |
| `analyze_m` | symlib | 函數 |
| `aut_functorial` | symlib | 函數 |
| `aut_generators` | symlib | 函數 |
| `aut_map` | symlib | 函數 |
| `aut_on_line` | symlib | 函數 |
| `aut_order` | symlib | 函數 |
| `automorphism_group` | symlib | 函數 |
| `automorphism_group_colored` | symlib | 函數 |
| `automorphism_group_dual` | symlib | 函數 |
| `canon_digest` | symlib | 函數 |
| `canon_encoding` | symlib | 函數 |
| `canonical_dual` | symlib | 函數 |
| `canonical_form` | symlib | 函數 |
| `canonical_labeling` | symlib | 函數 |
| `cmp_arr` | symlib | 函數 |
| `colored_canonical_key` | symlib | 函數 |
| `digest_from` | symlib | 函數 |
| `elem_lut_fast` | symlib | 函數 |
| `enc_index` | symlib | 函數 |
| `graph_invariant` | symlib | 函數 |
| `impl Debug for BitVec` | symlib | trait 實作 |
| `impl Debug for Graph` | symlib | trait 實作 |
| `impl Eq for Graph` | symlib | trait 實作 |
| `impl Show for BitVec` | symlib | trait 實作 |
| `impl Show for Graph` | symlib | trait 實作 |
| `is_automorphism` | symlib | 函數 |
| `is_dual_side` | symlib | 函數 |
| `isolated_count` | symlib | 函數 |
| `isomorphic` | symlib | 函數 |
| `isomorphic_decomposed` | symlib | 函數 |
| `isomorphic_dual` | symlib | 函數 |
| `isomorphic_line` | symlib | 函數 |
| `isomorphism` | symlib | 函數 |
| `isomorphism_dual` | symlib | 函數 |
| `isomorphism_via_line` | symlib | 函數 |
| `isomorphisms_m` | symlib | 函數 |
| `key_lut` | symlib | 函數 |
| `key_lut_pairs` | symlib | 函數 |
| `labeling_perm` | symlib | 函數 |
| `pack_bits` | symlib | 函數 |
| `refine_colors` | symlib | 函數 |
| `search_graph` | symlib | 函數 |
| `search_graph_colored` | symlib | 函數 |
| `search_graph_flags` | symlib | 函數 |
| `search_graph_mode` | symlib | 函數 |

### 有限對稱：置換群與 Schreier–Sims

- 規範形式：置換像陣列、基與強生成集
- 範疇化：有限集對稱群的子群與陪集分解
- 判定：Schreier–Sims 階數、成員、穩定子與有界列舉

| 符號 | 套件 | 類別 |
|---|---|---|
| `Perm` | symlib | 結構 |
| `Perm.img` | symlib | 欄位 |
| `Perm.n` | symlib | 欄位 |
| `Perm::apply` | symlib | 函數 |
| `Perm::compose` | symlib | 函數 |
| `Perm::conjugate_by` | symlib | 函數 |
| `Perm::cycles` | symlib | 函數 |
| `Perm::equal` | symlib | 函數 |
| `Perm::fixed_point_count` | symlib | 函數 |
| `Perm::from_cycles` | symlib | 函數 |
| `Perm::from_img` | symlib | 函數 |
| `Perm::identity` | symlib | 函數 |
| `Perm::inverse` | symlib | 函數 |
| `Perm::is_identity` | symlib | 函數 |
| `Perm::moved_points` | symlib | 函數 |
| `Perm::nontrivial_cycles` | symlib | 函數 |
| `Perm::not_equal` | symlib | 函數 |
| `Perm::orbit_of` | symlib | 函數 |
| `Perm::order` | symlib | 函數 |
| `Perm::output` | symlib | 函數 |
| `Perm::pow` | symlib | 函數 |
| `Perm::random` | symlib | 函數 |
| `Perm::sign` | symlib | 函數 |
| `Perm::size` | symlib | 函數 |
| `Perm::to_repr` | symlib | 函數 |
| `Perm::to_string` | symlib | 函數 |
| `PermGroup` | symlib | 結構 |
| `PermGroup.base` | symlib | 欄位 |
| `PermGroup.gens` | symlib | 欄位 |
| `PermGroup.n` | symlib | 欄位 |
| `PermGroup.orbit_size` | symlib | 欄位 |
| `PermGroup.orbits` | symlib | 欄位 |
| `PermGroup.trans` | symlib | 欄位 |
| `PermGroup::conjugate_by` | symlib | 函數 |
| `PermGroup::contains` | symlib | 函數 |
| `PermGroup::cyclic` | symlib | 函數 |
| `PermGroup::dihedral` | symlib | 函數 |
| `PermGroup::elements` | symlib | 函數 |
| `PermGroup::fixed_point_count` | symlib | 函數 |
| `PermGroup::generators` | symlib | 函數 |
| `PermGroup::is_transitive` | symlib | 函數 |
| `PermGroup::new` | symlib | 函數 |
| `PermGroup::orbit` | symlib | 函數 |
| `PermGroup::orbit_partition` | symlib | 函數 |
| `PermGroup::orbit_rep` | symlib | 函數 |
| `PermGroup::order` | symlib | 函數 |
| `PermGroup::output` | symlib | 函數 |
| `PermGroup::pointwise_stabilizer` | symlib | 函數 |
| `PermGroup::size` | symlib | 函數 |
| `PermGroup::stabilizer` | symlib | 函數 |
| `PermGroup::symmetric` | symlib | 函數 |
| `PermGroup::to_repr` | symlib | 函數 |
| `PermGroup::to_string` | symlib | 函數 |
| `PermGroup::trivial` | symlib | 函數 |
| `all_perms` | symlib | 函數 |
| `impl Debug for Perm` | symlib | trait 實作 |
| `impl Debug for PermGroup` | symlib | trait 實作 |
| `impl Eq for Perm` | symlib | trait 實作 |
| `impl Show for Perm` | symlib | trait 實作 |
| `impl Show for PermGroup` | symlib | trait 實作 |
| `regular_perm` | symlib | 函數 |
| `symmetric_gen_set` | symlib | 函數 |

### 有限對稱：群作用、軌道與 Burnside

- 規範形式：軌道分割、marks 向量與表
- 範疇化：G-集範疇、誘導/共誘導與 Burnside 環片段
- 判定：不動點計數、軌道枚舉與 marks 同構判準

| 符號 | 套件 | 類別 |
|---|---|---|
| `ActionDerive` | symlib | 列舉 |
| `ActionDerive::Edges` | symlib | 構造子 |
| `ActionDerive::Pairs` | symlib | 構造子 |
| `ActionDerive::Points` | symlib | 構造子 |
| `FinAction` | symlib | 結構 |
| `FinAction.base` | symlib | 欄位 |
| `FinAction.gens` | symlib | 欄位 |
| `FinAction.size` | symlib | 欄位 |
| `FinAction.via` | symlib | 欄位 |
| `FinAction::burnside_orbit_count` | symlib | 函數 |
| `FinAction::card` | symlib | 函數 |
| `FinAction::fixed_points` | symlib | 函數 |
| `FinAction::fold_ratio` | symlib | 函數 |
| `FinAction::fundamental_domain` | symlib | 函數 |
| `FinAction::is_transitive` | symlib | 函數 |
| `FinAction::lift` | symlib | 函數 |
| `FinAction::new` | symlib | 函數 |
| `FinAction::of_group` | symlib | 函數 |
| `FinAction::on_edges` | symlib | 函數 |
| `FinAction::on_pairs` | symlib | 函數 |
| `FinAction::orbit` | symlib | 函數 |
| `FinAction::orbit_count` | symlib | 函數 |
| `FinAction::orbit_of` | symlib | 函數 |
| `FinAction::orbit_sizes` | symlib | 函數 |
| `FinAction::orbits` | symlib | 函數 |
| `FinAction::output` | symlib | 函數 |
| `FinAction::to_repr` | symlib | 函數 |
| `FinAction::to_string` | symlib | 函數 |
| `FinAction::with_derive` | symlib | 函數 |
| `GSet` | symlib | 結構 |
| `GSet.group` | symlib | 欄位 |
| `GSet::components` | symlib | 函數 |
| `GSet::groupoid_cardinality` | symlib | 函數 |
| `GSet::hom` | symlib | 函數 |
| `GSet::isotropy` | symlib | 函數 |
| `GSet::of` | symlib | 函數 |
| `GSet::orbit_sum_cardinality` | symlib | 函數 |
| `GSetOf` | symlib | 結構 |
| `GSetOf.imgs` | symlib | 欄位 |
| `GSetOf.x` | symlib | 欄位 |
| `PermSet` | symlib | 結構 |
| `PermSet.gens` | symlib | 欄位 |
| `PermSet.n` | symlib | 欄位 |
| `Sub` | symlib | 結構 |
| `Sub.group` | symlib | 欄位 |
| `Sub.members` | symlib | 欄位 |
| `Sub.order` | symlib | 欄位 |
| `cayley_cert` | symlib | 函數 |
| `cayley_graph` | symlib | 函數 |
| `coinduced_card` | symlib | 函數 |
| `coinduced_gset` | symlib | 函數 |
| `coinduced_lift` | symlib | 函數 |
| `coset_gset` | symlib | 函數 |
| `edge_orbits` | symlib | 函數 |
| `frobenius_reciprocity` | symlib | 函數 |
| `fundamental_domain` | symlib | 函數 |
| `gset_burnside` | symlib | 函數 |
| `gset_canon_key` | symlib | 函數 |
| `gset_coinduced` | symlib | 函數 |
| `gset_edges` | symlib | 函數 |
| `gset_fixed_points` | symlib | 函數 |
| `gset_from_action` | symlib | 函數 |
| `gset_global_fixed` | symlib | 函數 |
| `gset_induced` | symlib | 函數 |
| `gset_isomorphic` | symlib | 函數 |
| `gset_mark` | symlib | 函數 |
| `gset_monad_eta` | symlib | 函數 |
| `gset_monad_laws` | symlib | 函數 |
| `gset_monad_map` | symlib | 函數 |
| `gset_monad_mu` | symlib | 函數 |
| `gset_monad_naturality` | symlib | 函數 |
| `gset_orbit_sizes` | symlib | 函數 |
| `gset_orbits` | symlib | 函數 |
| `gset_pairs` | symlib | 函數 |
| `gset_points` | symlib | 函數 |
| `impl Debug for FinAction` | symlib | trait 實作 |
| `impl Show for FinAction` | symlib | trait 實作 |
| `induced_gset` | symlib | 函數 |
| `induced_lift` | symlib | 函數 |
| `mark_vector` | symlib | 函數 |
| `marks_cert` | symlib | 函數 |
| `permset` | symlib | 函數 |
| `permset_canon` | symlib | 函數 |
| `permset_encoding` | symlib | 函數 |
| `subgroup_classes` | symlib | 函數 |
| `table_of_marks` | symlib | 函數 |
| `table_of_marks_formula` | symlib | 函數 |
| `vertex_orbits` | symlib | 函數 |

### 有限對稱：圖分解、對偶與折疊

- 規範形式：連通/雙連通分解鍵、補圖與線圖規範形
- 範疇化：圖範疇的分解、補與線圖函子及軌道商
- 判定：分解與對偶雙路互校、Whitney 例外檢查

| 符號 | 套件 | 類別 |
|---|---|---|
| `Decomp` | symlib | 結構 |
| `Decomp.auts` | symlib | 欄位 |
| `Decomp.cls_count` | symlib | 欄位 |
| `Decomp.cls_of` | symlib | 欄位 |
| `Decomp.comps` | symlib | 欄位 |
| `Decomp.encs` | symlib | 欄位 |
| `Decomp.gens` | symlib | 欄位 |
| `Decomp.graphs` | symlib | 欄位 |
| `Decomp.labs` | symlib | 欄位 |
| `Decomp.n` | symlib | 欄位 |
| `Decomp.offsets` | symlib | 欄位 |
| `Decomp::aut_generators` | symlib | 函數 |
| `Decomp::aut_order` | symlib | 函數 |
| `Decomp::aut_order_double` | symlib | 函數 |
| `Decomp::automorphism_group` | symlib | 函數 |
| `Decomp::block_count` | symlib | 函數 |
| `Decomp::block_encoding` | symlib | 函數 |
| `Decomp::canonical_form` | symlib | 函數 |
| `Decomp::class_count` | symlib | 函數 |
| `Decomp::labeling` | symlib | 函數 |
| `Decomp::output` | symlib | 函數 |
| `Decomp::summary` | symlib | 函數 |
| `Decomp::to_repr` | symlib | 函數 |
| `Decomp::to_string` | symlib | 函數 |
| `DualCanon` | symlib | 結構 |
| `DualCanon.aut_gens` | symlib | 欄位 |
| `DualCanon.dual` | symlib | 欄位 |
| `DualCanon.enc` | symlib | 欄位 |
| `DualCanon.lab` | symlib | 欄位 |
| `DualCanon.m` | symlib | 欄位 |
| `DualCanon.n` | symlib | 欄位 |
| `DualCanon.nodes` | symlib | 欄位 |
| `DualCanon::output` | symlib | 函數 |
| `DualCanon::summary` | symlib | 函數 |
| `DualCanon::to_repr` | symlib | 函數 |
| `DualCanon::to_string` | symlib | 函數 |
| `FoldedGraph` | symlib | 結構 |
| `FoldedGraph.edge_total` | symlib | 欄位 |
| `FoldedGraph.k` | symlib | 欄位 |
| `FoldedGraph.m` | symlib | 欄位 |
| `FoldedGraph.mul` | symlib | 欄位 |
| `FoldedGraph.n` | symlib | 欄位 |
| `FoldedGraph.orbit_of` | symlib | 欄位 |
| `FoldedGraph.orbit_size` | symlib | 欄位 |
| `FoldedGraph.rep` | symlib | 欄位 |
| `FoldedGraph::is_single_orbit` | symlib | 函數 |
| `FoldedGraph::multiplicity` | symlib | 函數 |
| `FoldedGraph::orbit_count` | symlib | 函數 |
| `FoldedGraph::output` | symlib | 函數 |
| `FoldedGraph::ratio` | symlib | 函數 |
| `FoldedGraph::summary` | symlib | 函數 |
| `FoldedGraph::to_repr` | symlib | 函數 |
| `FoldedGraph::to_string` | symlib | 函數 |
| `decomp_cert` | symlib | 函數 |
| `decomp_key_equal` | symlib | 函數 |
| `decompose` | symlib | 函數 |
| `dual_cert` | symlib | 函數 |
| `dual_cross_check` | symlib | 函數 |
| `dual_pair` | symlib | 函數 |
| `fold_candidates` | symlib | 函數 |
| `fold_canonical` | symlib | 函數 |
| `fold_canonical_cert` | symlib | 函數 |
| `fold_edges` | symlib | 函數 |
| `fold_equal` | symlib | 函數 |
| `fold_graph` | symlib | 函數 |
| `fold_graph_by_orbits` | symlib | 函數 |
| `impl Debug for Decomp` | symlib | trait 實作 |
| `impl Debug for DualCanon` | symlib | trait 實作 |
| `impl Debug for FoldedGraph` | symlib | trait 實作 |
| `impl Show for Decomp` | symlib | trait 實作 |
| `impl Show for DualCanon` | symlib | trait 實作 |
| `impl Show for FoldedGraph` | symlib | trait 實作 |
| `k2_component_count` | symlib | 函數 |
| `line_embed_cert` | symlib | 函數 |
| `line_graph` | symlib | 函數 |
| `line_kernel_order` | symlib | 函數 |
| `whitney_applies` | symlib | 函數 |
| `whitney_cert` | symlib | 函數 |
| `whitney_exception` | symlib | 函數 |

### 有限對稱：有限範疇、預層與 Kan 擴展

- 規範形式：有限合成表、預層限制表與錐列舉
- 範疇化：有限範疇、FinSet 函子、Yoneda 嵌入與左右 Kan 擴展
- 判定：範疇/函子公理窮舉與極限/餘極限基數互校

| 符號 | 套件 | 類別 |
|---|---|---|
| `FinCat` | symlib | 結構 |
| `FinCat.cod` | symlib | 欄位 |
| `FinCat.comp` | symlib | 欄位 |
| `FinCat.dom` | symlib | 欄位 |
| `FinCat.id` | symlib | 欄位 |
| `FinCat.nmor` | symlib | 欄位 |
| `FinCat.nobj` | symlib | 欄位 |
| `FinDiagram` | symlib | 結構 |
| `FinDiagram.cat` | symlib | 欄位 |
| `FinDiagram.img` | symlib | 欄位 |
| `FinDiagram.size` | symlib | 欄位 |
| `FinFunctor` | symlib | 結構 |
| `FinFunctor.dst` | symlib | 欄位 |
| `FinFunctor.mor` | symlib | 欄位 |
| `FinFunctor.obj` | symlib | 欄位 |
| `FinFunctor.src` | symlib | 欄位 |
| `FinMap` | symlib | 結構 |
| `FinMap.cod` | symlib | 欄位 |
| `FinMap.dom` | symlib | 欄位 |
| `FinMap.img` | symlib | 欄位 |
| `FinMap::compose` | symlib | 函數 |
| `FinMap::equal` | symlib | 函數 |
| `FinMap::id` | symlib | 函數 |
| `FinMap::inverse` | symlib | 函數 |
| `FinMap::is_epi` | symlib | 函數 |
| `FinMap::is_iso` | symlib | 函數 |
| `FinMap::is_mono` | symlib | 函數 |
| `FinMap::new` | symlib | 函數 |
| `FinSet` | symlib | 結構 |
| `FinSet.size` | symlib | 欄位 |
| `LanResult` | symlib | 結構 |
| `LanResult.class_of` | symlib | 欄位 |
| `LanResult.f` | symlib | 欄位 |
| `LanResult.k` | symlib | 欄位 |
| `LanResult.proj` | symlib | 欄位 |
| `LanResult.size` | symlib | 欄位 |
| `Presheaf` | symlib | 結構 |
| `Presheaf.cat` | symlib | 欄位 |
| `Presheaf.res` | symlib | 欄位 |
| `Presheaf.size` | symlib | 欄位 |
| `RanResult` | symlib | 結構 |
| `RanResult.cones` | symlib | 欄位 |
| `RanResult.f` | symlib | 欄位 |
| `RanResult.k` | symlib | 欄位 |
| `RanResult.proj` | symlib | 欄位 |
| `RanResult.size` | symlib | 欄位 |
| `arrow_diagram` | symlib | 函數 |
| `cat_arrow` | symlib | 函數 |
| `cat_cospan` | symlib | 函數 |
| `cat_discrete` | symlib | 函數 |
| `cat_group` | symlib | 函數 |
| `cat_parallel` | symlib | 函數 |
| `cat_poset` | symlib | 函數 |
| `cat_span` | symlib | 函數 |
| `cat_terminal` | symlib | 函數 |
| `cat_thin` | symlib | 函數 |
| `coequalizer_card` | symlib | 函數 |
| `colimit` | symlib | 函數 |
| `colimit_card` | symlib | 函數 |
| `comma_down` | symlib | 函數 |
| `comma_up` | symlib | 函數 |
| `coproduct_card` | symlib | 函數 |
| `csp_limit` | symlib | 函數 |
| `diagram_new` | symlib | 函數 |
| `equalizer_set` | symlib | 函數 |
| `id_functor` | symlib | 函數 |
| `id_map` | symlib | 函數 |
| `is_category` | symlib | 函數 |
| `is_fin_functor` | symlib | 函數 |
| `is_functor` | symlib | 函數 |
| `is_presheaf` | symlib | 函數 |
| `lan` | symlib | 函數 |
| `lan_map` | symlib | 函數 |
| `limit` | symlib | 函數 |
| `limit_card` | symlib | 函數 |
| `pow_fmap` | symlib | 函數 |
| `pow_monad_laws` | symlib | 函數 |
| `pow_mult` | symlib | 函數 |
| `pow_naturality` | symlib | 函數 |
| `pow_obj` | symlib | 函數 |
| `pow_unit` | symlib | 函數 |
| `presheaf_new` | symlib | 函數 |
| `product_set` | symlib | 函數 |
| `pullback_set` | symlib | 函數 |
| `pushout_card` | symlib | 函數 |
| `queen_constraints` | symlib | 函數 |
| `ran` | symlib | 函數 |
| `ran_map` | symlib | 函數 |
| `yoneda_count` | symlib | 函數 |
| `yoneda_extend` | symlib | 函數 |
| `yoneda_nats` | symlib | 函數 |
| `yoneda_roundtrip` | symlib | 函數 |

### 有限對稱：單子與非確定搜尋

- 規範形式：ListM/StateM 計算與 Kleisli 箭
- 範疇化：FinSet 上的冪集單子與 Kleisli 範疇
- 判定：單子律、自然性與守衛式列舉

| 符號 | 套件 | 類別 |
|---|---|---|
| `ListM` | symlib | 結構 |
| `ListM.arr` | symlib | 欄位 |
| `ListM::bind` | symlib | 函數 |
| `ListM::filter` | symlib | 函數 |
| `ListM::fold` | symlib | 函數 |
| `ListM::from_array` | symlib | 函數 |
| `ListM::map` | symlib | 函數 |
| `ListM::mplus` | symlib | 函數 |
| `ListM::pure` | symlib | 函數 |
| `ListM::to_array` | symlib | 函數 |
| `StateM` | symlib | 結構 |
| `StateM.run` | symlib | 欄位 |
| `StateM::bind` | symlib | 函數 |
| `StateM::eval` | symlib | 函數 |
| `StateM::exec` | symlib | 函數 |
| `StateM::get` | symlib | 函數 |
| `StateM::map` | symlib | 函數 |
| `StateM::modify` | symlib | 函數 |
| `StateM::pure` | symlib | 函數 |
| `StateM::put` | symlib | 函數 |
| `kleisli_id` | symlib | 函數 |
| `kleisli_list` | symlib | 函數 |
| `kleisli_state` | symlib | 函數 |
| `nd_guard` | symlib | 函數 |
| `opt_bind` | symlib | 函數 |
| `opt_pure` | symlib | 函數 |
| `search_nd` | symlib | 函數 |

### 有限對稱：證書、隨機與報告

- 規範形式：Cert 記錄、確定性 LCG 與對稱報告
- 範疇化：可判定命題在有限見證集上的實現
- 判定：prove_graph/prove_pair/prove_all 證書電池

| 符號 | 套件 | 類別 |
|---|---|---|
| `Cert` | symlib | 結構 |
| `Cert.detail` | symlib | 欄位 |
| `Cert.holds` | symlib | 欄位 |
| `Cert.name` | symlib | 欄位 |
| `Cert::to_repr` | symlib | 函數 |
| `SymmetryReport` | symlib | 結構 |
| `SymmetryReport.aut_gens` | symlib | 欄位 |
| `SymmetryReport.canon_lab` | symlib | 欄位 |
| `SymmetryReport.digest` | symlib | 欄位 |
| `SymmetryReport.edge_orbit_sizes` | symlib | 欄位 |
| `SymmetryReport.edge_orbits` | symlib | 欄位 |
| `SymmetryReport.folded` | symlib | 欄位 |
| `SymmetryReport.group` | symlib | 欄位 |
| `SymmetryReport.leaves` | symlib | 欄位 |
| `SymmetryReport.m` | symlib | 欄位 |
| `SymmetryReport.n` | symlib | 欄位 |
| `SymmetryReport.nodes` | symlib | 欄位 |
| `SymmetryReport.order` | symlib | 欄位 |
| `SymmetryReport.vertex_orbits` | symlib | 欄位 |
| `SymmetryReport::output` | symlib | 函數 |
| `SymmetryReport::summary` | symlib | 函數 |
| `SymmetryReport::to_report_string` | symlib | 函數 |
| `SymmetryReport::to_repr` | symlib | 函數 |
| `SymmetryReport::to_string` | symlib | 函數 |
| `all_hold` | symlib | 函數 |
| `cert` | symlib | 函數 |
| `cert_report` | symlib | 函數 |
| `elements_cert` | symlib | 函數 |
| `failed_certs` | symlib | 函數 |
| `impl Debug for Cert` | symlib | trait 實作 |
| `impl Debug for SymmetryReport` | symlib | trait 實作 |
| `impl Show for SymmetryReport` | symlib | trait 實作 |
| `ints_to_string` | symlib | 函數 |
| `lcg_step` | symlib | 函數 |
| `prove_all` | symlib | 函數 |
| `prove_graph` | symlib | 函數 |
| `prove_pair` | symlib | 函數 |
| `random_ints` | symlib | 函數 |

### 半環實驗室：半環與么半群 traits

- 規範形式：trait 方法表、飽和熱帶元素、Pareto 前沿與 Ops 計數
- 範疇化：冪等/星閉/熱帶半環與么半群的型別類階梯
- 判定：隨機取樣定律檢查（含近似度量版）

| 符號 | 套件 | 類別 |
|---|---|---|
| `BoolSr` | semiring-algebra | 結構 |
| `BoolSr.b` | semiring-algebra | 欄位 |
| `BoolSr::equal` | semiring-algebra | 函數 |
| `BoolSr::group_id` | semiring-algebra | 函數 |
| `BoolSr::group_inv` | semiring-algebra | 函數 |
| `BoolSr::is_one` | semiring-algebra | 函數 |
| `BoolSr::is_zero` | semiring-algebra | 函數 |
| `BoolSr::le` | semiring-algebra | 函數 |
| `BoolSr::not_equal` | semiring-algebra | 函數 |
| `BoolSr::of` | semiring-algebra | 函數 |
| `BoolSr::one` | semiring-algebra | 函數 |
| `BoolSr::order_bound` | semiring-algebra | 函數 |
| `BoolSr::output` | semiring-algebra | 函數 |
| `BoolSr::plus` | semiring-algebra | 函數 |
| `BoolSr::star` | semiring-algebra | 函數 |
| `BoolSr::times` | semiring-algebra | 函數 |
| `BoolSr::to_string` | semiring-algebra | 函數 |
| `BoolSr::zero` | semiring-algebra | 函數 |
| `Bottleneck` | semiring-algebra | 結構 |
| `Bottleneck.w` | semiring-algebra | 欄位 |
| `Bottleneck::bottom` | semiring-algebra | 函數 |
| `Bottleneck::equal` | semiring-algebra | 函數 |
| `Bottleneck::is_one` | semiring-algebra | 函數 |
| `Bottleneck::is_zero` | semiring-algebra | 函數 |
| `Bottleneck::join` | semiring-algebra | 函數 |
| `Bottleneck::le` | semiring-algebra | 函數 |
| `Bottleneck::meet` | semiring-algebra | 函數 |
| `Bottleneck::new` | semiring-algebra | 函數 |
| `Bottleneck::not_equal` | semiring-algebra | 函數 |
| `Bottleneck::one` | semiring-algebra | 函數 |
| `Bottleneck::output` | semiring-algebra | 函數 |
| `Bottleneck::plus` | semiring-algebra | 函數 |
| `Bottleneck::star` | semiring-algebra | 函數 |
| `Bottleneck::times` | semiring-algebra | 函數 |
| `Bottleneck::to_string` | semiring-algebra | 函數 |
| `Bottleneck::top` | semiring-algebra | 函數 |
| `Bottleneck::value` | semiring-algebra | 函數 |
| `Bottleneck::zero` | semiring-algebra | 函數 |
| `CommutativeMonoid` | semiring-algebra | trait |
| `Counting` | semiring-algebra | 結構 |
| `Counting.n` | semiring-algebra | 欄位 |
| `Counting::equal` | semiring-algebra | 函數 |
| `Counting::is_one` | semiring-algebra | 函數 |
| `Counting::is_zero` | semiring-algebra | 函數 |
| `Counting::new` | semiring-algebra | 函數 |
| `Counting::not_equal` | semiring-algebra | 函數 |
| `Counting::one` | semiring-algebra | 函數 |
| `Counting::output` | semiring-algebra | 函數 |
| `Counting::plus` | semiring-algebra | 函數 |
| `Counting::star` | semiring-algebra | 函數 |
| `Counting::times` | semiring-algebra | 函數 |
| `Counting::to_string` | semiring-algebra | 函數 |
| `Counting::value` | semiring-algebra | 函數 |
| `Counting::zero` | semiring-algebra | 函數 |
| `CyclicSet` | semiring-algebra | 結構 |
| `CyclicSet.bits` | semiring-algebra | 欄位 |
| `CyclicSet.m` | semiring-algebra | 欄位 |
| `CyclicSet::cardinality` | semiring-algebra | 函數 |
| `CyclicSet::contains` | semiring-algebra | 函數 |
| `CyclicSet::empty` | semiring-algebra | 函數 |
| `CyclicSet::equal` | semiring-algebra | 函數 |
| `CyclicSet::group_id` | semiring-algebra | 函數 |
| `CyclicSet::group_inv` | semiring-algebra | 函數 |
| `CyclicSet::is_one` | semiring-algebra | 函數 |
| `CyclicSet::is_zero` | semiring-algebra | 函數 |
| `CyclicSet::le` | semiring-algebra | 函數 |
| `CyclicSet::not_equal` | semiring-algebra | 函數 |
| `CyclicSet::of_range` | semiring-algebra | 函數 |
| `CyclicSet::one` | semiring-algebra | 函數 |
| `CyclicSet::one_of` | semiring-algebra | 函數 |
| `CyclicSet::order_bound` | semiring-algebra | 函數 |
| `CyclicSet::output` | semiring-algebra | 函數 |
| `CyclicSet::plus` | semiring-algebra | 函數 |
| `CyclicSet::singleton` | semiring-algebra | 函數 |
| `CyclicSet::star` | semiring-algebra | 函數 |
| `CyclicSet::times` | semiring-algebra | 函數 |
| `CyclicSet::to_string` | semiring-algebra | 函數 |
| `CyclicSet::zero` | semiring-algebra | 函數 |
| `GroupElement` | semiring-algebra | trait |
| `GroupElement::group_id` | semiring-algebra | trait 方法 |
| `GroupElement::group_inv` | semiring-algebra | trait 方法 |
| `GroupElement::order_bound` | semiring-algebra | trait 方法 |
| `GroupMonoid` | semiring-algebra | trait |
| `GroupMonoid::invert` | semiring-algebra | trait 方法 |
| `IdempotentMonoid` | semiring-algebra | trait |
| `IdempotentSemiring` | semiring-algebra | trait |
| `IdempotentSemiring::le` | semiring-algebra | trait 方法 |
| `LawReport` | semiring-algebra | 結構 |
| `LawReport.checks` | semiring-algebra | 欄位 |
| `LawReport.violations` | semiring-algebra | 欄位 |
| `LawReport::ok` | semiring-algebra | 函數 |
| `LawReport::summary` | semiring-algebra | 函數 |
| `Monoid` | semiring-algebra | trait |
| `Monoid::combine` | semiring-algebra | trait 方法 |
| `Monoid::empty` | semiring-algebra | trait 方法 |
| `Ops` | semiring-algebra | 結構 |
| `Ops.plus` | semiring-algebra | 欄位 |
| `Ops.times` | semiring-algebra | 欄位 |
| `Ops::new` | semiring-algebra | 函數 |
| `Ops::output` | semiring-algebra | 函數 |
| `Ops::record_plus` | semiring-algebra | 函數 |
| `Ops::record_times` | semiring-algebra | 函數 |
| `Ops::to_string` | semiring-algebra | 函數 |
| `Ops::total` | semiring-algebra | 函數 |
| `OrderedSemiring` | semiring-algebra | trait |
| `OrderedSemiring::bottom` | semiring-algebra | trait 方法 |
| `OrderedSemiring::join` | semiring-algebra | trait 方法 |
| `OrderedSemiring::meet` | semiring-algebra | trait 方法 |
| `OrderedSemiring::top` | semiring-algebra | trait 方法 |
| `ParetoSet` | semiring-algebra | 結構 |
| `ParetoSet.dim` | semiring-algebra | 欄位 |
| `ParetoSet.pts` | semiring-algebra | 欄位 |
| `ParetoSet::bottom` | semiring-algebra | 函數 |
| `ParetoSet::empty` | semiring-algebra | 函數 |
| `ParetoSet::equal` | semiring-algebra | 函數 |
| `ParetoSet::is_identity` | semiring-algebra | 函數 |
| `ParetoSet::is_one` | semiring-algebra | 函數 |
| `ParetoSet::is_zero` | semiring-algebra | 函數 |
| `ParetoSet::join` | semiring-algebra | 函數 |
| `ParetoSet::label` | semiring-algebra | 函數 |
| `ParetoSet::le` | semiring-algebra | 函數 |
| `ParetoSet::meet` | semiring-algebra | 函數 |
| `ParetoSet::not_equal` | semiring-algebra | 函數 |
| `ParetoSet::one` | semiring-algebra | 函數 |
| `ParetoSet::one_of` | semiring-algebra | 函數 |
| `ParetoSet::output` | semiring-algebra | 函數 |
| `ParetoSet::plus` | semiring-algebra | 函數 |
| `ParetoSet::point` | semiring-algebra | 函數 |
| `ParetoSet::size` | semiring-algebra | 函數 |
| `ParetoSet::times` | semiring-algebra | 函數 |
| `ParetoSet::to_string` | semiring-algebra | 函數 |
| `ParetoSet::top` | semiring-algebra | 函數 |
| `ParetoSet::zero` | semiring-algebra | 函數 |
| `Prob` | semiring-algebra | 結構 |
| `Prob.p` | semiring-algebra | 欄位 |
| `Prob::equal` | semiring-algebra | 函數 |
| `Prob::is_one` | semiring-algebra | 函數 |
| `Prob::is_zero` | semiring-algebra | 函數 |
| `Prob::new` | semiring-algebra | 函數 |
| `Prob::not_equal` | semiring-algebra | 函數 |
| `Prob::one` | semiring-algebra | 函數 |
| `Prob::output` | semiring-algebra | 函數 |
| `Prob::plus` | semiring-algebra | 函數 |
| `Prob::star_checked` | semiring-algebra | 函數 |
| `Prob::times` | semiring-algebra | 函數 |
| `Prob::to_string` | semiring-algebra | 函數 |
| `Prob::value` | semiring-algebra | 函數 |
| `Prob::zero` | semiring-algebra | 函數 |
| `Rng` | semiring-algebra | 結構 |
| `Rng.state` | semiring-algebra | 欄位 |
| `Rng::chance` | semiring-algebra | 函數 |
| `Rng::new` | semiring-algebra | 函數 |
| `Rng::next_double` | semiring-algebra | 函數 |
| `Rng::next_int` | semiring-algebra | 函數 |
| `Rng::next_u64` | semiring-algebra | 函數 |
| `Rng::range` | semiring-algebra | 函數 |
| `Semiring` | semiring-algebra | trait |
| `Semiring::is_one` | semiring-algebra | trait 方法 |
| `Semiring::is_zero` | semiring-algebra | trait 方法 |
| `Semiring::one` | semiring-algebra | trait 方法 |
| `Semiring::plus` | semiring-algebra | trait 方法 |
| `Semiring::times` | semiring-algebra | trait 方法 |
| `Semiring::zero` | semiring-algebra | trait 方法 |
| `StarSemiring` | semiring-algebra | trait |
| `StarSemiring::star` | semiring-algebra | trait 方法 |
| `Trop` | semiring-algebra | 結構 |
| `Trop.v` | semiring-algebra | 欄位 |
| `Trop::closer` | semiring-algebra | 函數 |
| `Trop::equal` | semiring-algebra | 函數 |
| `Trop::group_id` | semiring-algebra | 函數 |
| `Trop::group_inv` | semiring-algebra | 函數 |
| `Trop::inf` | semiring-algebra | 函數 |
| `Trop::is_inf` | semiring-algebra | 函數 |
| `Trop::is_one` | semiring-algebra | 函數 |
| `Trop::is_zero` | semiring-algebra | 函數 |
| `Trop::le` | semiring-algebra | 函數 |
| `Trop::new` | semiring-algebra | 函數 |
| `Trop::not_equal` | semiring-algebra | 函數 |
| `Trop::one` | semiring-algebra | 函數 |
| `Trop::order_bound` | semiring-algebra | 函數 |
| `Trop::output` | semiring-algebra | 函數 |
| `Trop::plus` | semiring-algebra | 函數 |
| `Trop::star` | semiring-algebra | 函數 |
| `Trop::star_checked` | semiring-algebra | 函數 |
| `Trop::times` | semiring-algebra | 函數 |
| `Trop::to_string` | semiring-algebra | 函數 |
| `Trop::value` | semiring-algebra | 函數 |
| `Trop::zero` | semiring-algebra | 函數 |
| `TropF` | semiring-algebra | 結構 |
| `TropF.v` | semiring-algebra | 欄位 |
| `TropF::closer` | semiring-algebra | 函數 |
| `TropF::equal` | semiring-algebra | 函數 |
| `TropF::inf` | semiring-algebra | 函數 |
| `TropF::is_inf` | semiring-algebra | 函數 |
| `TropF::is_one` | semiring-algebra | 函數 |
| `TropF::is_zero` | semiring-algebra | 函數 |
| `TropF::le` | semiring-algebra | 函數 |
| `TropF::not_equal` | semiring-algebra | 函數 |
| `TropF::of` | semiring-algebra | 函數 |
| `TropF::one` | semiring-algebra | 函數 |
| `TropF::output` | semiring-algebra | 函數 |
| `TropF::plus` | semiring-algebra | 函數 |
| `TropF::star` | semiring-algebra | 函數 |
| `TropF::star_checked` | semiring-algebra | 函數 |
| `TropF::times` | semiring-algebra | 函數 |
| `TropF::to_string` | semiring-algebra | 函數 |
| `TropF::value` | semiring-algebra | 函數 |
| `TropF::zero` | semiring-algebra | 函數 |
| `TropMax` | semiring-algebra | 結構 |
| `TropMax.v` | semiring-algebra | 欄位 |
| `TropMax::equal` | semiring-algebra | 函數 |
| `TropMax::is_neg_inf` | semiring-algebra | 函數 |
| `TropMax::is_one` | semiring-algebra | 函數 |
| `TropMax::is_zero` | semiring-algebra | 函數 |
| `TropMax::le` | semiring-algebra | 函數 |
| `TropMax::new` | semiring-algebra | 函數 |
| `TropMax::not_equal` | semiring-algebra | 函數 |
| `TropMax::one` | semiring-algebra | 函數 |
| `TropMax::output` | semiring-algebra | 函數 |
| `TropMax::plus` | semiring-algebra | 函數 |
| `TropMax::star` | semiring-algebra | 函數 |
| `TropMax::times` | semiring-algebra | 函數 |
| `TropMax::to_string` | semiring-algebra | 函數 |
| `TropMax::value` | semiring-algebra | 函數 |
| `TropMax::zero` | semiring-algebra | 函數 |
| `TropicalSemiring` | semiring-algebra | trait |
| `TropicalSemiring::closer` | semiring-algebra | trait 方法 |
| `TropicalSemiring::inf` | semiring-algebra | trait 方法 |
| `TropicalSemiring::is_inf` | semiring-algebra | trait 方法 |
| `cap_max` | semiring-algebra | 常量 |
| `check_group_element` | semiring-algebra | 函數 |
| `check_idempotent` | semiring-algebra | 函數 |
| `check_monoid` | semiring-algebra | 函數 |
| `check_semiring` | semiring-algebra | 函數 |
| `check_semiring_approx` | semiring-algebra | 函數 |
| `check_star` | semiring-algebra | 函數 |
| `check_star_idem` | semiring-algebra | 函數 |
| `geom_sum` | semiring-algebra | 函數 |
| `geom_sum_group` | semiring-algebra | 函數 |
| `impl Eq for CyclicSet` | semiring-algebra | trait 實作 |
| `impl Eq for ParetoSet` | semiring-algebra | trait 實作 |
| `impl Eq for TropF` | semiring-algebra | trait 實作 |
| `impl GroupElement for BoolSr` | semiring-algebra | trait 實作 |
| `impl GroupElement for CyclicSet` | semiring-algebra | trait 實作 |
| `impl GroupElement for Trop` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for BoolSr` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for Bottleneck` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for CyclicSet` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for ParetoSet` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for Trop` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for TropF` | semiring-algebra | trait 實作 |
| `impl IdempotentSemiring for TropMax` | semiring-algebra | trait 實作 |
| `impl OrderedSemiring for Bottleneck` | semiring-algebra | trait 實作 |
| `impl OrderedSemiring for ParetoSet` | semiring-algebra | trait 實作 |
| `impl Semiring for BoolSr` | semiring-algebra | trait 實作 |
| `impl Semiring for Bottleneck` | semiring-algebra | trait 實作 |
| `impl Semiring for Counting` | semiring-algebra | trait 實作 |
| `impl Semiring for CyclicSet` | semiring-algebra | trait 實作 |
| `impl Semiring for ParetoSet` | semiring-algebra | trait 實作 |
| `impl Semiring for Prob` | semiring-algebra | trait 實作 |
| `impl Semiring for Trop` | semiring-algebra | trait 實作 |
| `impl Semiring for TropF` | semiring-algebra | trait 實作 |
| `impl Semiring for TropMax` | semiring-algebra | trait 實作 |
| `impl Show for BoolSr` | semiring-algebra | trait 實作 |
| `impl Show for Bottleneck` | semiring-algebra | trait 實作 |
| `impl Show for Counting` | semiring-algebra | trait 實作 |
| `impl Show for CyclicSet` | semiring-algebra | trait 實作 |
| `impl Show for Ops` | semiring-algebra | trait 實作 |
| `impl Show for ParetoSet` | semiring-algebra | trait 實作 |
| `impl Show for Prob` | semiring-algebra | trait 實作 |
| `impl Show for Trop` | semiring-algebra | trait 實作 |
| `impl Show for TropF` | semiring-algebra | trait 實作 |
| `impl Show for TropMax` | semiring-algebra | trait 實作 |
| `impl StarSemiring for BoolSr` | semiring-algebra | trait 實作 |
| `impl StarSemiring for Bottleneck` | semiring-algebra | trait 實作 |
| `impl StarSemiring for Counting` | semiring-algebra | trait 實作 |
| `impl StarSemiring for CyclicSet` | semiring-algebra | trait 實作 |
| `impl StarSemiring for Trop` | semiring-algebra | trait 實作 |
| `impl StarSemiring for TropF` | semiring-algebra | trait 實作 |
| `impl StarSemiring for TropMax` | semiring-algebra | trait 實作 |
| `impl TropicalSemiring for Trop` | semiring-algebra | trait 實作 |
| `impl TropicalSemiring for TropF` | semiring-algebra | trait 實作 |
| `pow_squaring` | semiring-algebra | 函數 |
| `star_by_doubling` | semiring-algebra | 函數 |
| `star_by_iteration` | semiring-algebra | 函數 |
| `trop_inf` | semiring-algebra | 常量 |
| `trop_neg_inf` | semiring-algebra | 常量 |

### 半環實驗室：泛型矩陣與星閉包

- 規範形式：row-major 稠密矩陣與 CSR 三元組正規序
- 範疇化：半環矩陣範疇與 Kleene 星閉包
- 判定：多種乘法/閉包實作逐元互校與操作計數

| 符號 | 套件 | 類別 |
|---|---|---|
| `Csr` | semiring-matrix | 結構 |
| `Csr.col` | semiring-matrix | 欄位 |
| `Csr.cols` | semiring-matrix | 欄位 |
| `Csr.row_ptr` | semiring-matrix | 欄位 |
| `Csr.rows` | semiring-matrix | 欄位 |
| `Csr.val` | semiring-matrix | 欄位 |
| `Csr::from_dense` | semiring-matrix | 函數 |
| `Csr::from_triplets` | semiring-matrix | 函數 |
| `Csr::get` | semiring-matrix | 函數 |
| `Csr::nnz` | semiring-matrix | 函數 |
| `Csr::row_nnz` | semiring-matrix | 函數 |
| `Csr::row_range` | semiring-matrix | 函數 |
| `Csr::to_dense` | semiring-matrix | 函數 |
| `Mat` | semiring-matrix | 結構 |
| `Mat.cols` | semiring-matrix | 欄位 |
| `Mat.d` | semiring-matrix | 欄位 |
| `Mat.rows` | semiring-matrix | 欄位 |
| `Mat::byte_size` | semiring-matrix | 函數 |
| `Mat::copy` | semiring-matrix | 函數 |
| `Mat::from_flat` | semiring-matrix | 函數 |
| `Mat::get` | semiring-matrix | 函數 |
| `Mat::identity` | semiring-matrix | 函數 |
| `Mat::is_square` | semiring-matrix | 函數 |
| `Mat::new` | semiring-matrix | 函數 |
| `Mat::set` | semiring-matrix | 函數 |
| `Mat::transpose` | semiring-matrix | 函數 |
| `Mat::zero` | semiring-matrix | 函數 |
| `Probe` | semiring-matrix | 型別別名 |
| `choose_block_l1` | semiring-matrix | 函數 |
| `choose_panel_l2` | semiring-matrix | 函數 |
| `choose_tile` | semiring-matrix | 函數 |
| `closure_blocked` | semiring-matrix | 函數 |
| `closure_blocked_auto` | semiring-matrix | 函數 |
| `closure_fw_inplace` | semiring-matrix | 函數 |
| `closure_fw_par` | semiring-matrix | 函數 |
| `closure_lehmann` | semiring-matrix | 函數 |
| `closure_series` | semiring-matrix | 函數 |
| `copy_region_in` | semiring-matrix | 函數 |
| `copy_region_out` | semiring-matrix | 函數 |
| `csr_apsp` | semiring-matrix | 函數 |
| `csr_closure` | semiring-matrix | 函數 |
| `csr_mul` | semiring-matrix | 函數 |
| `csr_mul_minplus` | semiring-matrix | 函數 |
| `csr_sssp` | semiring-matrix | 函數 |
| `default_l1_bytes` | semiring-matrix | 常量 |
| `default_l2_bytes` | semiring-matrix | 常量 |
| `fw_region` | semiring-matrix | 函數 |
| `mat_all` | semiring-matrix | 函數 |
| `mat_equal` | semiring-matrix | 函數 |
| `mat_is_zero` | semiring-matrix | 函數 |
| `mat_plus` | semiring-matrix | 函數 |
| `mul_blocked` | semiring-matrix | 函數 |
| `mul_blocked_auto` | semiring-matrix | 函數 |
| `mul_ikj` | semiring-matrix | 函數 |
| `mul_naive` | semiring-matrix | 函數 |
| `mul_region` | semiring-matrix | 函數 |
| `mul_rows_par` | semiring-matrix | 函數 |
| `mul_trop` | semiring-matrix | 函數 |
| `mul_trop_generic` | semiring-matrix | 函數 |
| `mul_trop_plain` | semiring-matrix | 函數 |

### 半環實驗室：么半群聚合

- 規範形式：仿射函數、Fenwick 樹、稀疏表與掃描結果
- 範疇化：么半群作用與函數合成的結合聚合
- 判定：暴力前綴/區間查詢差分互校

| 符號 | 套件 | 類別 |
|---|---|---|
| `AffineM` | semiring-monoid | 結構 |
| `AffineM.a` | semiring-monoid | 欄位 |
| `AffineM.b` | semiring-monoid | 欄位 |
| `AffineM::apply` | semiring-monoid | 函數 |
| `AffineM::combine` | semiring-monoid | 函數 |
| `AffineM::empty` | semiring-monoid | 函數 |
| `AffineM::equal` | semiring-monoid | 函數 |
| `AffineM::new` | semiring-monoid | 函數 |
| `AffineM::not_equal` | semiring-monoid | 函數 |
| `AffineM::output` | semiring-monoid | 函數 |
| `AffineM::to_string` | semiring-monoid | 函數 |
| `Fenwick` | semiring-monoid | 結構 |
| `Fenwick.d` | semiring-monoid | 欄位 |
| `Fenwick.n` | semiring-monoid | 欄位 |
| `Fenwick::add` | semiring-monoid | 函數 |
| `Fenwick::build` | semiring-monoid | 函數 |
| `Fenwick::prefix` | semiring-monoid | 函數 |
| `Fenwick::range` | semiring-monoid | 函數 |
| `MaxI64` | semiring-monoid | 結構 |
| `MaxI64.v` | semiring-monoid | 欄位 |
| `MaxI64::combine` | semiring-monoid | 函數 |
| `MaxI64::empty` | semiring-monoid | 函數 |
| `MaxI64::equal` | semiring-monoid | 函數 |
| `MaxI64::not_equal` | semiring-monoid | 函數 |
| `MaxI64::output` | semiring-monoid | 函數 |
| `MaxI64::to_string` | semiring-monoid | 函數 |
| `MinI64` | semiring-monoid | 結構 |
| `MinI64.v` | semiring-monoid | 欄位 |
| `MinI64::combine` | semiring-monoid | 函數 |
| `MinI64::empty` | semiring-monoid | 函數 |
| `MinI64::equal` | semiring-monoid | 函數 |
| `MinI64::not_equal` | semiring-monoid | 函數 |
| `MinI64::output` | semiring-monoid | 函數 |
| `MinI64::to_string` | semiring-monoid | 函數 |
| `OppositeM` | semiring-monoid | 結構 |
| `OppositeM.inner` | semiring-monoid | 欄位 |
| `OppositeM::combine` | semiring-monoid | 函數 |
| `OppositeM::empty` | semiring-monoid | 函數 |
| `OppositeM::equal` | semiring-monoid | 函數 |
| `OppositeM::not_equal` | semiring-monoid | 函數 |
| `OppositeM::of` | semiring-monoid | 函數 |
| `OppositeM::output` | semiring-monoid | 函數 |
| `OppositeM::to_string` | semiring-monoid | 函數 |
| `SegTree` | semiring-monoid | 結構 |
| `SegTree.d` | semiring-monoid | 欄位 |
| `SegTree.size` | semiring-monoid | 欄位 |
| `SegTree::build` | semiring-monoid | 函數 |
| `SegTree::len` | semiring-monoid | 函數 |
| `SegTree::query` | semiring-monoid | 函數 |
| `SegTree::set` | semiring-monoid | 函數 |
| `SparseTable` | semiring-monoid | 結構 |
| `SparseTable.levels` | semiring-monoid | 欄位 |
| `SparseTable.logs` | semiring-monoid | 欄位 |
| `SparseTable::build` | semiring-monoid | 函數 |
| `SparseTable::query` | semiring-monoid | 函數 |
| `SumI64` | semiring-monoid | 結構 |
| `SumI64.v` | semiring-monoid | 欄位 |
| `SumI64::combine` | semiring-monoid | 函數 |
| `SumI64::empty` | semiring-monoid | 函數 |
| `SumI64::equal` | semiring-monoid | 函數 |
| `SumI64::invert` | semiring-monoid | 函數 |
| `SumI64::not_equal` | semiring-monoid | 函數 |
| `SumI64::of` | semiring-monoid | 函數 |
| `SumI64::output` | semiring-monoid | 函數 |
| `SumI64::to_string` | semiring-monoid | 函數 |
| `impl CommutativeMonoid for MaxI64` | semiring-monoid | trait 實作 |
| `impl CommutativeMonoid for MinI64` | semiring-monoid | trait 實作 |
| `impl CommutativeMonoid for SumI64` | semiring-monoid | trait 實作 |
| `impl Eq for AffineM` | semiring-monoid | trait 實作 |
| `impl Eq for OppositeM[M]` | semiring-monoid | trait 實作 |
| `impl GroupMonoid for SumI64` | semiring-monoid | trait 實作 |
| `impl IdempotentMonoid for MaxI64` | semiring-monoid | trait 實作 |
| `impl IdempotentMonoid for MinI64` | semiring-monoid | trait 實作 |
| `impl Monoid for AffineM` | semiring-monoid | trait 實作 |
| `impl Monoid for MaxI64` | semiring-monoid | trait 實作 |
| `impl Monoid for MinI64` | semiring-monoid | trait 實作 |
| `impl Monoid for OppositeM[M]` | semiring-monoid | trait 實作 |
| `impl Monoid for SumI64` | semiring-monoid | trait 實作 |
| `impl Show for AffineM` | semiring-monoid | trait 實作 |
| `impl Show for MaxI64` | semiring-monoid | trait 實作 |
| `impl Show for MinI64` | semiring-monoid | trait 實作 |
| `impl Show for OppositeM[M]` | semiring-monoid | trait 實作 |
| `impl Show for SumI64` | semiring-monoid | trait 實作 |
| `prefix_scan` | semiring-monoid | 函數 |
| `prefix_scan_sequential` | semiring-monoid | 函數 |

### 半環實驗室：加權有向圖

- 規範形式：CSR 出邊列與熱帶距離矩陣
- 範疇化：加權有向圖的路徑半環與豐富範疇片段
- 判定：Dijkstra、Kleene 星、位元閉包與 Pareto 仲裁

| 符號 | 套件 | 類別 |
|---|---|---|
| `BitClosure` | semiring-graph | 結構 |
| `BitClosure.bits` | semiring-graph | 欄位 |
| `BitClosure.n` | semiring-graph | 欄位 |
| `BitClosure.words` | semiring-graph | 欄位 |
| `BitClosure::get` | semiring-graph | 函數 |
| `BitClosure::row_count` | semiring-graph | 函數 |
| `FunctionalDecomp` | semiring-graph | 結構 |
| `FunctionalDecomp.cycle_id` | semiring-graph | 欄位 |
| `FunctionalDecomp.cycle_len` | semiring-graph | 欄位 |
| `FunctionalDecomp.depth` | semiring-graph | 欄位 |
| `FunctionalDecomp.dist_to_cycle` | semiring-graph | 欄位 |
| `FunctionalDecomp::reach_count` | semiring-graph | 函數 |
| `Graph` | semiring-graph | 結構 |
| `Graph.n` | semiring-graph | 欄位 |
| `Graph.offsets` | semiring-graph | 欄位 |
| `Graph.to` | semiring-graph | 欄位 |
| `Graph.w` | semiring-graph | 欄位 |
| `Graph.w2` | semiring-graph | 欄位 |
| `Graph::build` | semiring-graph | 函數 |
| `Graph::edges` | semiring-graph | 函數 |
| `Graph::random` | semiring-graph | 函數 |
| `Graph::random_two` | semiring-graph | 函數 |
| `Graph::to_trop_mat` | semiring-graph | 函數 |
| `Graph::with_second` | semiring-graph | 函數 |
| `MinHeap` | semiring-graph | 結構 |
| `MinHeap.d` | semiring-graph | 欄位 |
| `MinHeap.v` | semiring-graph | 欄位 |
| `MinHeap::len` | semiring-graph | 函數 |
| `MinHeap::new` | semiring-graph | 函數 |
| `MinHeap::pop` | semiring-graph | 函數 |
| `MinHeap::push` | semiring-graph | 函數 |
| `apsp_dijkstra` | semiring-graph | 函數 |
| `apsp_kleene` | semiring-graph | 函數 |
| `closure_bitset` | semiring-graph | 函數 |
| `dijkstra` | semiring-graph | 函數 |
| `functional_decompose` | semiring-graph | 函數 |
| `has_negative_cycle` | semiring-graph | 函數 |
| `pareto_sssp` | semiring-graph | 函數 |
| `total_labels` | semiring-graph | 函數 |

### 半環實驗室：樣條

- 規範形式：均勻節點、帶狀系統與 de Boor 求值點
- 範疇化：仿射遞迴的么半群掃描與分段多項式函數
- 判定：插值性質、稠密/帶狀求解互校與極點量測

| 符號 | 套件 | 類別 |
|---|---|---|
| `Banded` | semiring-spline | 結構 |
| `Banded.a` | semiring-spline | 欄位 |
| `Banded.band` | semiring-spline | 欄位 |
| `Banded.n` | semiring-spline | 欄位 |
| `Banded::get` | semiring-spline | 函數 |
| `Banded::tridiag` | semiring-spline | 函數 |
| `affine_steps` | semiring-spline | 函數 |
| `bspline_basis` | semiring-spline | 函數 |
| `cubic_pole` | semiring-spline | 函數 |
| `interp_cubic_banded` | semiring-spline | 函數 |
| `interp_cubic_dense` | semiring-spline | 函數 |
| `interp_cubic_dense_open` | semiring-spline | 函數 |
| `interp_cubic_periodic` | semiring-spline | 函數 |
| `solve_banded` | semiring-spline | 函數 |
| `solve_dense` | semiring-spline | 函數 |

### 半環實驗室：熱帶幾何

- 規範形式：Newton 凸包、根及其重數、對偶細分面
- 範疇化：熱帶曲線與普通代數曲線的對偶/去量子化片段
- 判定：括號重合、balancing 殘差與熱帶行列式仲裁

| 符號 | 套件 | 類別 |
|---|---|---|
| `BPoly` | semiring-trop | 結構 |
| `BPoly.terms` | semiring-trop | 欄位 |
| `BPoly::check_duality` | semiring-trop | 函數 |
| `BPoly::check_ties_on_faces` | semiring-trop | 函數 |
| `BPoly::dual_curve` | semiring-trop | 函數 |
| `BPoly::eval` | semiring-trop | 函數 |
| `BPoly::face_area2` | semiring-trop | 函數 |
| `BPoly::hull_of` | semiring-trop | 函數 |
| `BPoly::minima_scaled` | semiring-trop | 函數 |
| `BPoly::new` | semiring-trop | 函數 |
| `BPoly::newton_area2` | semiring-trop | 函數 |
| `BPoly::newton_hull` | semiring-trop | 函數 |
| `BPoly::subdivision` | semiring-trop | 函數 |
| `BPoly::subdivision_area2` | semiring-trop | 函數 |
| `BTerm` | semiring-trop | 結構 |
| `BTerm.c` | semiring-trop | 欄位 |
| `BTerm.i` | semiring-trop | 欄位 |
| `BTerm.j` | semiring-trop | 欄位 |
| `BTerm::new` | semiring-trop | 函數 |
| `DualEdge` | semiring-trop | 結構 |
| `DualEdge.dir` | semiring-trop | 欄位 |
| `DualEdge.face_a` | semiring-trop | 欄位 |
| `DualEdge.face_b` | semiring-trop | 欄位 |
| `DualEdge.from_term` | semiring-trop | 欄位 |
| `DualEdge.to_term` | semiring-trop | 欄位 |
| `DualEdge.weight` | semiring-trop | 欄位 |
| `Face` | semiring-trop | 結構 |
| `Face.boundary` | semiring-trop | 欄位 |
| `Face.members` | semiring-trop | 欄位 |
| `Face.plane` | semiring-trop | 欄位 |
| `Face.polygon` | semiring-trop | 欄位 |
| `Plane` | semiring-trop | 結構 |
| `Plane.d` | semiring-trop | 欄位 |
| `Plane.nx` | semiring-trop | 欄位 |
| `Plane.ny` | semiring-trop | 欄位 |
| `Plane.nz` | semiring-trop | 欄位 |
| `Plane::equal` | semiring-trop | 函數 |
| `Plane::not_equal` | semiring-trop | 函數 |
| `Pt2` | semiring-trop | 結構 |
| `Pt2.x` | semiring-trop | 欄位 |
| `Pt2.y` | semiring-trop | 欄位 |
| `Pt2::cross` | semiring-trop | 函數 |
| `Pt2::equal` | semiring-trop | 函數 |
| `Pt2::lattice_len` | semiring-trop | 函數 |
| `Pt2::new` | semiring-trop | 函數 |
| `Pt2::not_equal` | semiring-trop | 函數 |
| `Pt2::output` | semiring-trop | 函數 |
| `Pt2::prim` | semiring-trop | 函數 |
| `Pt2::rot90` | semiring-trop | 函數 |
| `Pt2::to_string` | semiring-trop | 函數 |
| `Rat` | semiring-trop | 結構 |
| `Rat.d` | semiring-trop | 欄位 |
| `Rat.n` | semiring-trop | 欄位 |
| `Rat::equal` | semiring-trop | 函數 |
| `Rat::new` | semiring-trop | 函數 |
| `Rat::not_equal` | semiring-trop | 函數 |
| `Rat::of_int` | semiring-trop | 函數 |
| `Rat::output` | semiring-trop | 函數 |
| `Rat::to_double` | semiring-trop | 函數 |
| `Rat::to_string` | semiring-trop | 函數 |
| `UniPoly` | semiring-trop | 結構 |
| `UniPoly.coeffs` | semiring-trop | 欄位 |
| `UniPoly::argmin_at` | semiring-trop | 函數 |
| `UniPoly::degree` | semiring-trop | 函數 |
| `UniPoly::eval` | semiring-trop | 函數 |
| `UniPoly::lower_hull` | semiring-trop | 函數 |
| `UniPoly::multiplicity_sum` | semiring-trop | 函數 |
| `UniPoly::new` | semiring-trop | 函數 |
| `UniPoly::roots` | semiring-trop | 函數 |
| `UniPoly::roots_with_mult` | semiring-trop | 函數 |
| `balancing_residuals` | semiring-trop | 函數 |
| `impl Show for Pt2` | semiring-trop | trait 實作 |
| `impl Show for Rat` | semiring-trop | trait 實作 |
| `rat_gt` | semiring-trop | 函數 |
| `roots_equal` | semiring-trop | 函數 |
| `sat_add_i32` | semiring-trop | 函數 |
| `sat_mul_i32` | semiring-trop | 函數 |
| `sort_rats` | semiring-trop | 函數 |
| `trop_assignment` | semiring-trop | 函數 |
| `trop_det` | semiring-trop | 函數 |
| `trop_det_bruteforce` | semiring-trop | 函數 |
| `trop_det_dp` | semiring-trop | 函數 |
| `trop_det_tie_count` | semiring-trop | 函數 |
| `trop_poly_mul` | semiring-trop | 函數 |

### 半環實驗室：正則與冪等正規形

- 規範形式：ACI 正規式、最小 DFA 與單項式排序集
- 範疇化：正則語言與自由冪等半環的範疇/代數表達式
- 判定：Brzozowski 導數、DFA 等價與字串枚舉互校

| 符號 | 套件 | 類別 |
|---|---|---|
| `Dfa` | semiring-nf | 結構 |
| `Dfa.accept` | semiring-nf | 欄位 |
| `Dfa.alphabet` | semiring-nf | 欄位 |
| `Dfa.nsym` | semiring-nf | 欄位 |
| `Dfa.start` | semiring-nf | 欄位 |
| `Dfa.trans` | semiring-nf | 欄位 |
| `Dfa::accepts` | semiring-nf | 函數 |
| `Dfa::nstates` | semiring-nf | 函數 |
| `Regex` | semiring-nf | 列舉 |
| `Regex::RChar` | semiring-nf | 構造子 |
| `Regex::ROne` | semiring-nf | 構造子 |
| `Regex::RProd` | semiring-nf | 構造子 |
| `Regex::RStar` | semiring-nf | 構造子 |
| `Regex::RSum` | semiring-nf | 構造子 |
| `Regex::RZero` | semiring-nf | 構造子 |
| `Regex::rank` | semiring-nf | 函數 |
| `Regex::to_text` | semiring-nf | 函數 |
| `SExpr` | semiring-nf | 列舉 |
| `SExpr::SOne` | semiring-nf | 構造子 |
| `SExpr::SProd` | semiring-nf | 構造子 |
| `SExpr::SSum` | semiring-nf | 構造子 |
| `SExpr::SVar` | semiring-nf | 構造子 |
| `SExpr::SZero` | semiring-nf | 構造子 |
| `char_of` | semiring-nf | 函數 |
| `deriv` | semiring-nf | 函數 |
| `dfa_canonical` | semiring-nf | 函數 |
| `dfa_equiv` | semiring-nf | 函數 |
| `dfa_minimize` | semiring-nf | 函數 |
| `dfa_of_regex` | semiring-nf | 函數 |
| `idempotent_identity_holds` | semiring-nf | 函數 |
| `idempotent_identity_holds_via_dfa` | semiring-nf | 函數 |
| `mono_cmp` | semiring-nf | 函數 |
| `normalize` | semiring-nf | 函數 |
| `nullable` | semiring-nf | 函數 |
| `r_prod` | semiring-nf | 函數 |
| `r_star` | semiring-nf | 函數 |
| `r_sum` | semiring-nf | 函數 |
| `regex_cmp` | semiring-nf | 函數 |
| `regex_equiv` | semiring-nf | 函數 |
| `rx_accepts` | semiring-nf | 函數 |
| `sexpr_to_regex` | semiring-nf | 函數 |

### 半環實驗室：集合值矩陣、自由範疇與去量子化

- 規範形式：路徑證人集、DAG 路徑與 ε-變形矩陣
- 範疇化：集合值矩陣的豐富範疇、圖的自由範疇與 Maslov 去量子化
- 判定：路徑列舉/DP/矩陣冪/Lehmann 四路互校

| 符號 | 套件 | 類別 |
|---|---|---|
| `DiGraph` | semiring-cat | 結構 |
| `DiGraph.adj` | semiring-cat | 欄位 |
| `DiGraph.n` | semiring-cat | 欄位 |
| `DiGraph::adjacency` | semiring-cat | 函數 |
| `DiGraph::edge` | semiring-cat | 函數 |
| `DiGraph::edge_count` | semiring-cat | 函數 |
| `DiGraph::hom_setmat` | semiring-cat | 函數 |
| `DiGraph::hom_sets` | semiring-cat | 函數 |
| `DiGraph::is_dag` | semiring-cat | 函數 |
| `DiGraph::new` | semiring-cat | 函數 |
| `DiGraph::path_counts` | semiring-cat | 函數 |
| `DiGraph::path_counts_by_closure` | semiring-cat | 函數 |
| `DiGraph::path_counts_by_powers` | semiring-cat | 函數 |
| `DiGraph::topo_order` | semiring-cat | 函數 |
| `SetMat` | semiring-cat | 結構 |
| `SetMat.cells` | semiring-cat | 欄位 |
| `SetMat.cols` | semiring-cat | 欄位 |
| `SetMat.rows` | semiring-cat | 欄位 |
| `SetMat::add` | semiring-cat | 函數 |
| `SetMat::get` | semiring-cat | 函數 |
| `SetMat::new` | semiring-cat | 函數 |
| `decategorify` | semiring-cat | 函數 |
| `dequant_error` | semiring-cat | 函數 |
| `dequantize` | semiring-cat | 函數 |
| `dequantize_naive` | semiring-cat | 函數 |
| `dequantized_mul` | semiring-cat | 函數 |
| `max_abs_diff` | semiring-cat | 函數 |
| `minplus_mul` | semiring-cat | 函數 |
| `smat_mul` | semiring-cat | 函數 |
| `smat_plus` | semiring-cat | 函數 |

### 半環實驗室：代數路徑問題

- 規範形式：邊三元組矩陣與多候選 Run/Verdict
- 範疇化：以星半環統一的最短/可達/瓶頸/計數路徑問題
- 判定：專用算法與泛型閉包多數決仲裁

| 符號 | 套件 | 類別 |
|---|---|---|
| `Run` | semiring-app | 結構 |
| `Run.agrees` | semiring-app | 欄位 |
| `Run.name` | semiring-app | 欄位 |
| `Run.us` | semiring-app | 欄位 |
| `Verdict` | semiring-app | 結構 |
| `Verdict.agree` | semiring-app | 欄位 |
| `Verdict.cost_of_trust` | semiring-app | 欄位 |
| `Verdict.runs` | semiring-app | 欄位 |
| `Verdict.total_us` | semiring-app | 欄位 |
| `Verdict.winner` | semiring-app | 欄位 |
| `Verdict.winner_us` | semiring-app | 欄位 |
| `app_bool` | semiring-app | 函數 |
| `app_closure` | semiring-app | 函數 |
| `app_minplus` | semiring-app | 函數 |
| `app_widest` | semiring-app | 函數 |
| `build` | semiring-app | 函數 |
| `consensus_trop` | semiring-app | 函數 |
| `reach_bfs` | semiring-app | 函數 |
| `shortest_fw` | semiring-app | 函數 |
| `widest_fw` | semiring-app | 函數 |
| `wrong_candidate` | semiring-app | 函數 |

### 半環實驗室：因子圖推論

- 規範形式：因子表、訊息與邊際矩陣
- 範疇化：因子圖上的半環訊息傳遞與廣義分配律
- 判定：樹上 BP 對暴力邊際、環上不保證精確

| 符號 | 套件 | 類別 |
|---|---|---|
| `BpResult` | semiring-bp | 結構 |
| `BpResult.marginal` | semiring-bp | 欄位 |
| `BpResult.rounds` | semiring-bp | 欄位 |
| `BpResult.times_ops` | semiring-bp | 欄位 |
| `Factor` | semiring-bp | 結構 |
| `Factor.table` | semiring-bp | 欄位 |
| `Factor.vars` | semiring-bp | 欄位 |
| `Factor::new` | semiring-bp | 函數 |
| `FactorGraph` | semiring-bp | 結構 |
| `FactorGraph.card` | semiring-bp | 欄位 |
| `FactorGraph.factors` | semiring-bp | 欄位 |
| `FactorGraph.nvar` | semiring-bp | 欄位 |
| `bp_marginals` | semiring-bp | 函數 |
| `brute_force_sum_product` | semiring-bp | 函數 |
| `decode_assign` | semiring-bp | 函數 |
| `factor_size` | semiring-bp | 函數 |
| `is_tree` | semiring-bp | 函數 |
| `marginals_sum_product` | semiring-bp | 函數 |
| `table_index` | semiring-bp | 函數 |
| `total_assignments` | semiring-bp | 函數 |

### 半環實驗室：限流應用

- 規範形式：TAT、理論到達列與有界鍵表
- 範疇化：偏序時間窗上的單調配額更新
- 判定：虛擬時鐘事件重播、上下界與淘汰檢查

| 符號 | 套件 | 類別 |
|---|---|---|
| `Decision` | semiring-ratelimit | 列舉 |
| `Decision::Allowed` | semiring-ratelimit | 構造子 |
| `Decision::Shedded` | semiring-ratelimit | 構造子 |
| `Decision::Throttled` | semiring-ratelimit | 構造子 |
| `Decision::equal` | semiring-ratelimit | 函數 |
| `Decision::not_equal` | semiring-ratelimit | 函數 |
| `Decision::output` | semiring-ratelimit | 函數 |
| `Decision::to_string` | semiring-ratelimit | 函數 |
| `Gcra` | semiring-ratelimit | 結構 |
| `Gcra.burst` | semiring-ratelimit | 欄位 |
| `Gcra.interval_us` | semiring-ratelimit | 欄位 |
| `Gcra::backoff` | semiring-ratelimit | 函數 |
| `Gcra::commit` | semiring-ratelimit | 函數 |
| `Gcra::new` | semiring-ratelimit | 函數 |
| `Gcra::preview` | semiring-ratelimit | 函數 |
| `Gcra::tolerance` | semiring-ratelimit | 函數 |
| `HierLimiter` | semiring-ratelimit | 結構 |
| `HierLimiter.admitted` | semiring-ratelimit | 欄位 |
| `HierLimiter.gate` | semiring-ratelimit | 欄位 |
| `HierLimiter.gate_tat` | semiring-ratelimit | 欄位 |
| `HierLimiter.key_gcra` | semiring-ratelimit | 欄位 |
| `HierLimiter.keys` | semiring-ratelimit | 欄位 |
| `HierLimiter.last_now` | semiring-ratelimit | 欄位 |
| `HierLimiter.shedded` | semiring-ratelimit | 欄位 |
| `HierLimiter.tenant_gcra` | semiring-ratelimit | 欄位 |
| `HierLimiter.tenants` | semiring-ratelimit | 欄位 |
| `HierLimiter.throttled` | semiring-ratelimit | 欄位 |
| `HierLimiter::admit` | semiring-ratelimit | 函數 |
| `HierLimiter::new` | semiring-ratelimit | 函數 |
| `HierLimiter::stats` | semiring-ratelimit | 函數 |
| `HierLimiter::table_evictions` | semiring-ratelimit | 函數 |
| `HierLimiter::table_used` | semiring-ratelimit | 函數 |
| `KeyState` | semiring-ratelimit | 結構 |
| `KeyState.key` | semiring-ratelimit | 欄位 |
| `KeyState.occupied` | semiring-ratelimit | 欄位 |
| `KeyState.referenced` | semiring-ratelimit | 欄位 |
| `KeyState.strikes` | semiring-ratelimit | 欄位 |
| `KeyState.tat` | semiring-ratelimit | 欄位 |
| `KeyTable` | semiring-ratelimit | 結構 |
| `KeyTable.evictions` | semiring-ratelimit | 欄位 |
| `KeyTable.hand` | semiring-ratelimit | 欄位 |
| `KeyTable.mask` | semiring-ratelimit | 欄位 |
| `KeyTable.probes` | semiring-ratelimit | 欄位 |
| `KeyTable.slots` | semiring-ratelimit | 欄位 |
| `KeyTable.used` | semiring-ratelimit | 欄位 |
| `KeyTable::capacity` | semiring-ratelimit | 函數 |
| `KeyTable::get_or_insert` | semiring-ratelimit | 函數 |
| `KeyTable::new` | semiring-ratelimit | 函數 |
| `Limiter` | semiring-ratelimit | 結構 |
| `Limiter.admitted` | semiring-ratelimit | 欄位 |
| `Limiter.gate` | semiring-ratelimit | 欄位 |
| `Limiter.gate_tat` | semiring-ratelimit | 欄位 |
| `Limiter.key_gcra` | semiring-ratelimit | 欄位 |
| `Limiter.last_now` | semiring-ratelimit | 欄位 |
| `Limiter.shedded` | semiring-ratelimit | 欄位 |
| `Limiter.table` | semiring-ratelimit | 欄位 |
| `Limiter.throttled` | semiring-ratelimit | 欄位 |
| `Limiter::admit` | semiring-ratelimit | 函數 |
| `Limiter::new` | semiring-ratelimit | 函數 |
| `Limiter::stats` | semiring-ratelimit | 函數 |
| `Limiter::table_evictions` | semiring-ratelimit | 函數 |
| `Limiter::table_used` | semiring-ratelimit | 函數 |
| `Limiter::with_gate` | semiring-ratelimit | 函數 |
| `impl Show for Decision` | semiring-ratelimit | trait 實作 |

### 半環實驗室：邊表輸入

- 規範形式：原始邊位元組與剖析後三元組
- 範疇化：圖資料的具體表示與載入函數
- 判定：快速/朴素剖析器逐邊互校與吞吐量測

| 符號 | 套件 | 類別 |
|---|---|---|
| `ParsedEdges` | semiring-io | 結構 |
| `ParsedEdges.from` | semiring-io | 欄位 |
| `ParsedEdges.n` | semiring-io | 欄位 |
| `ParsedEdges.to` | semiring-io | 欄位 |
| `ParsedEdges.w` | semiring-io | 欄位 |
| `parse_edges_fast` | semiring-io | 函數 |
| `parse_edges_naive` | semiring-io | 函數 |
| `synth_edge_bytes` | semiring-io | 函數 |
| `synth_edge_list` | semiring-io | 函數 |

### 半環實驗室：量測與快取模擬

- 規範形式：存取追蹤、快取組與時鐘讀數
- 範疇化：記憶階層的有限狀態模型
- 判定：真實存取探針輸入模擬器並比較策略

| 符號 | 套件 | 類別 |
|---|---|---|
| `Cache` | semiring-sim | 結構 |
| `Cache.clock` | semiring-sim | 欄位 |
| `Cache.hits` | semiring-sim | 欄位 |
| `Cache.line_bytes` | semiring-sim | 欄位 |
| `Cache.misses` | semiring-sim | 欄位 |
| `Cache.sets` | semiring-sim | 欄位 |
| `Cache.shift` | semiring-sim | 欄位 |
| `Cache.stamp` | semiring-sim | 欄位 |
| `Cache.tags` | semiring-sim | 欄位 |
| `Cache.ways` | semiring-sim | 欄位 |
| `Cache::access` | semiring-sim | 函數 |
| `Cache::accesses` | semiring-sim | 函數 |
| `Cache::new` | semiring-sim | 函數 |
| `Cache::reset` | semiring-sim | 函數 |
| `MemHierarchy` | semiring-sim | 結構 |
| `MemHierarchy.dram_reads` | semiring-sim | 欄位 |
| `MemHierarchy.dram_writes` | semiring-sim | 欄位 |
| `MemHierarchy.l1` | semiring-sim | 欄位 |
| `MemHierarchy.l2` | semiring-sim | 欄位 |
| `MemHierarchy::access` | semiring-sim | 函數 |
| `MemHierarchy::dram_words` | semiring-sim | 函數 |
| `MemHierarchy::reset` | semiring-sim | 函數 |
| `MemHierarchy::typical` | semiring-sim | 函數 |
| `Timer` | semiring-sim | 結構 |
| `Timer.t0` | semiring-sim | 欄位 |
| `Timer::elapsed_us` | semiring-sim | 函數 |
| `Timer::start` | semiring-sim | 函數 |
| `Tracer` | semiring-sim | 結構 |
| `Tracer.base` | semiring-sim | 欄位 |
| `Tracer.cols` | semiring-sim | 欄位 |
| `Tracer.elem_bytes` | semiring-sim | 欄位 |
| `Tracer.next_base` | semiring-sim | 欄位 |
| `Tracer.sim` | semiring-sim | 欄位 |
| `Tracer::dram_words` | semiring-sim | 函數 |
| `Tracer::l1_accesses` | semiring-sim | 函數 |
| `Tracer::l1_misses` | semiring-sim | 函數 |
| `Tracer::l2_misses` | semiring-sim | 函數 |
| `Tracer::new` | semiring-sim | 函數 |
| `Tracer::probe` | semiring-sim | 函數 |
| `Tracer::register` | semiring-sim | 函數 |
| `Tracer::reset` | semiring-sim | 函數 |
| `time_min` | semiring-sim | 函數 |

### 半環實驗室：平行接縫

- 規範形式：分塊區間、掃描樹與 shard I/O 描述
- 範疇化：結合聚合在工作/深度模型下的後端接縫
- 判定：序行 oracle 互校；非原生 target 明示序行後端

| 符號 | 套件 | 類別 |
|---|---|---|
| `ShardIO` | semiring-par | 結構 |
| `ShardIO.bytes` | semiring-par | 欄位 |
| `ShardIO.files` | semiring-par | 欄位 |
| `ShardIO.par_data` | semiring-par | 欄位 |
| `ShardIO.par_us` | semiring-par | 欄位 |
| `ShardIO.same` | semiring-par | 欄位 |
| `ShardIO.seq_data` | semiring-par | 欄位 |
| `ShardIO.seq_us` | semiring-par | 欄位 |
| `backend` | semiring-par | 函數 |
| `backend_name` | semiring-par | 函數 |
| `chunk_size` | semiring-par | 函數 |
| `par_for` | semiring-par | 函數 |
| `par_map_chunks` | semiring-par | 函數 |
| `par_scan` | semiring-par | 函數 |
| `scan_depth` | semiring-par | 函數 |
| `scan_sequential` | semiring-par | 函數 |
| `shard_io_bench` | semiring-par | 函數 |

### 半環實驗室：原生宿主後端

- 規範形式：結構化 async 任務與分片讀取結果
- 範疇化：原生宿主效果在平行接縫之下封裝
- 判定：僅 native 編譯與測試，其餘 target 整包跳過

| 符號 | 套件 | 類別 |
|---|---|---|
| `backend_name` | semiring-par-host | 函數 |
| `is_host_backend` | semiring-par-host | 函數 |
| `par_for` | semiring-par-host | 函數 |
| `shard_io_bench` | semiring-par-host | 函數 |

### 半環實驗室：量測報告

- 規範形式：章節函數輸出的量測表與裁決摘要
- 範疇化：半環支柱各演算法在原生主機上的可重現量測敘事
- 判定：native 慢閘門完整重跑並保存輸出快照；永不進快速閘門

| 符號 | 套件 | 類別 |
|---|---|---|
| `ReportBroken` | cmd-semiringreport | 結構 |
| `ReportBroken.v` | cmd-semiringreport | 欄位 |
| `ReportBroken::equal` | cmd-semiringreport | 函數 |
| `ReportBroken::is_one` | cmd-semiringreport | 函數 |
| `ReportBroken::is_zero` | cmd-semiringreport | 函數 |
| `ReportBroken::not_equal` | cmd-semiringreport | 函數 |
| `ReportBroken::of` | cmd-semiringreport | 函數 |
| `ReportBroken::one` | cmd-semiringreport | 函數 |
| `ReportBroken::output` | cmd-semiringreport | 函數 |
| `ReportBroken::plus` | cmd-semiringreport | 函數 |
| `ReportBroken::times` | cmd-semiringreport | 函數 |
| `ReportBroken::to_string` | cmd-semiringreport | 函數 |
| `ReportBroken::zero` | cmd-semiringreport | 函數 |
| `ReportLying` | cmd-semiringreport | 結構 |
| `ReportLying.v` | cmd-semiringreport | 欄位 |
| `ReportLying::equal` | cmd-semiringreport | 函數 |
| `ReportLying::is_one` | cmd-semiringreport | 函數 |
| `ReportLying::is_zero` | cmd-semiringreport | 函數 |
| `ReportLying::le` | cmd-semiringreport | 函數 |
| `ReportLying::not_equal` | cmd-semiringreport | 函數 |
| `ReportLying::of` | cmd-semiringreport | 函數 |
| `ReportLying::one` | cmd-semiringreport | 函數 |
| `ReportLying::output` | cmd-semiringreport | 函數 |
| `ReportLying::plus` | cmd-semiringreport | 函數 |
| `ReportLying::times` | cmd-semiringreport | 函數 |
| `ReportLying::to_string` | cmd-semiringreport | 函數 |
| `ReportLying::zero` | cmd-semiringreport | 函數 |
| `impl IdempotentSemiring for ReportLying` | cmd-semiringreport | trait 實作 |
| `impl Semiring for ReportBroken` | cmd-semiringreport | trait 實作 |
| `impl Semiring for ReportLying` | cmd-semiringreport | trait 實作 |
| `impl Show for ReportBroken` | cmd-semiringreport | trait 實作 |
| `impl Show for ReportLying` | cmd-semiringreport | trait 實作 |
| `sec10_sparse` | cmd-semiringreport | 函數 |
| `sec11_float` | cmd-semiringreport | 函數 |
| `sec12_blocking` | cmd-semiringreport | 函數 |
| `sec13_parallel` | cmd-semiringreport | 函數 |
| `sec14_tropical_geometry` | cmd-semiringreport | 函數 |
| `sec15_normal_forms` | cmd-semiringreport | 函數 |
| `sec16_categorification` | cmd-semiringreport | 函數 |
| `sec17_app_portfolio` | cmd-semiringreport | 函數 |
| `sec18_belief` | cmd-semiringreport | 函數 |
| `sec19_limits` | cmd-semiringreport | 函數 |

### 三方橋接

- 規範形式：跨支柱轉換後的規範矩陣、圖、範疇或統一證書
- 範疇化：cubical、有限對稱與半環路徑代數之間的顯式橋接構造
- 判定：每一橋接均以來源支柱的判定器重驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `BridgeCertificate` | bridge | 結構 |
| `BridgeCertificate.detail` | bridge | 欄位 |
| `BridgeCertificate.name` | bridge | 欄位 |
| `BridgeCertificate.ok` | bridge | 欄位 |
| `BridgeCertificate.source` | bridge | 欄位 |
| `FaceClass` | bridge | 結構 |
| `FaceClass.bdd` | bridge | 欄位 |
| `FaceClass::bottom` | bridge | 函數 |
| `FaceClass::complement` | bridge | 函數 |
| `FaceClass::equal` | bridge | 函數 |
| `FaceClass::is_bottom` | bridge | 函數 |
| `FaceClass::is_one` | bridge | 函數 |
| `FaceClass::is_top` | bridge | 函數 |
| `FaceClass::is_zero` | bridge | 函數 |
| `FaceClass::join` | bridge | 函數 |
| `FaceClass::le` | bridge | 函數 |
| `FaceClass::meet` | bridge | 函數 |
| `FaceClass::not_equal` | bridge | 函數 |
| `FaceClass::of_face` | bridge | 函數 |
| `FaceClass::one` | bridge | 函數 |
| `FaceClass::output` | bridge | 函數 |
| `FaceClass::plus` | bridge | 函數 |
| `FaceClass::star` | bridge | 函數 |
| `FaceClass::times` | bridge | 函數 |
| `FaceClass::to_string` | bridge | 函數 |
| `FaceClass::top` | bridge | 函數 |
| `FaceClass::zero` | bridge | 函數 |
| `WeightedGraphReport` | bridge | 結構 |
| `WeightedGraphReport.candidate_group_order` | bridge | 欄位 |
| `WeightedGraphReport.canonical_colors` | bridge | 欄位 |
| `WeightedGraphReport.canonical_encoding` | bridge | 欄位 |
| `WeightedGraphReport.directed_edges` | bridge | 欄位 |
| `WeightedGraphReport.distance_matrix` | bridge | 欄位 |
| `WeightedGraphReport.finite_distance_sum` | bridge | 欄位 |
| `WeightedGraphReport.n` | bridge | 欄位 |
| `WeightedGraphReport.reachable_pairs` | bridge | 欄位 |
| `WeightedGraphReport.support_characteristic_poly` | bridge | 欄位 |
| `WeightedGraphReport.symmetry_projector` | bridge | 欄位 |
| `WeightedGraphReport.weighted_symmetry_count` | bridge | 欄位 |
| `assignment_cost` | bridge | 函數 |
| `average_permutation_matrices` | bridge | 函數 |
| `bool_tuple_type` | bridge | 函數 |
| `bridge_certificate` | bridge | 函數 |
| `bridge_certificates` | bridge | 函數 |
| `certificate_of_cubical` | bridge | 函數 |
| `certificate_of_semiring_law` | bridge | 函數 |
| `certificate_of_symlib` | bridge | 函數 |
| `certificate_summary` | bridge | 函數 |
| `certificates_all_ok` | bridge | 函數 |
| `check_face_semiring_bridge` | bridge | 函數 |
| `check_free_category_bridge` | bridge | 函數 |
| `check_graph_symmetry_bridges` | bridge | 函數 |
| `check_perm_wiring_bridge` | bridge | 函數 |
| `check_square_cell_symmetry` | bridge | 函數 |
| `check_tropical_bridges` | bridge | 函數 |
| `exact_determinant_int64` | bridge | 函數 |
| `exact_permanent_int64` | bridge | 函數 |
| `face_semiring_law_report` | bridge | 函數 |
| `fincat_hom_counts` | bridge | 函數 |
| `free_category_to_fincat` | bridge | 函數 |
| `impl IdempotentSemiring for FaceClass` | bridge | trait 實作 |
| `impl OrderedSemiring for FaceClass` | bridge | trait 實作 |
| `impl Semiring for FaceClass` | bridge | trait 實作 |
| `impl Show for FaceClass` | bridge | trait 實作 |
| `impl StarSemiring for FaceClass` | bridge | trait 實作 |
| `matrix_permutation_symmetries` | bridge | 函數 |
| `matrix_support_graph` | bridge | 函數 |
| `perm_equiv` | bridge | 函數 |
| `perm_of_wiring` | bridge | 函數 |
| `perm_preserves_matrix` | bridge | 函數 |
| `perm_preserves_semiring_graph` | bridge | 函數 |
| `perm_wiring` | bridge | 函數 |
| `permutation_matrix` | bridge | 函數 |
| `qpoly_tropicalize_padic` | bridge | 函數 |
| `rat_padic_valuation` | bridge | 函數 |
| `semiring_graph_candidate_order` | bridge | 函數 |
| `semiring_graph_support` | bridge | 函數 |
| `semiring_graph_symmetries` | bridge | 函數 |
| `semiring_graph_symmetry_projector` | bridge | 函數 |
| `semiring_graph_vertex_colors` | bridge | 函數 |
| `signed_perm_wiring` | bridge | 函數 |
| `square_cell_incidence` | bridge | 函數 |
| `tropical_matrix_symmetries` | bridge | 函數 |
| `tropical_optimal_assignments` | bridge | 函數 |
| `weighted_graph_report` | bridge | 函數 |
| `wiring_output_signs` | bridge | 函數 |

### 拓撲斯：景、篩、Grothendieck 拓撲與預層

- 規範形式：排序無重態射篩、覆蓋篩閉包、自然變換分量表與相容匹配族
- 範疇化：小範疇景 (C,J)、米田嵌入 C↪PSh(C) 與預層極限／餘極限雙完備結構
- 判定：篩右理想律、Grothendieck 拓撲三公理（極大／穩定／傳遞）與一般米田雙射窮舉檢驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `GrothendieckTopology` | topos | 結構 |
| `GrothendieckTopology.covers` | topos | 欄位 |
| `GrothendieckTopology.nobj` | topos | 欄位 |
| `GrothendieckTopology::equal` | topos | 函數 |
| `GrothendieckTopology::not_equal` | topos | 函數 |
| `GrothendieckTopology::to_repr` | topos | 函數 |
| `MatchingFamily` | topos | 結構 |
| `MatchingFamily.sieve` | topos | 欄位 |
| `MatchingFamily.values` | topos | 欄位 |
| `MatchingFamily::equal` | topos | 函數 |
| `MatchingFamily::not_equal` | topos | 函數 |
| `MatchingFamily::to_repr` | topos | 函數 |
| `PresheafHom` | topos | 結構 |
| `PresheafHom.cat` | topos | 欄位 |
| `PresheafHom.cod_size` | topos | 欄位 |
| `PresheafHom.components` | topos | 欄位 |
| `PresheafHom.dom_size` | topos | 欄位 |
| `Sieve` | topos | 結構 |
| `Sieve.arrows` | topos | 欄位 |
| `Sieve.target` | topos | 欄位 |
| `Sieve::equal` | topos | 函數 |
| `Sieve::not_equal` | topos | 函數 |
| `Sieve::to_repr` | topos | 函數 |
| `Site` | topos | 結構 |
| `Site.cat` | topos | 欄位 |
| `Site.topology` | topos | 欄位 |
| `all_sieves_on` | topos | 函數 |
| `cat_circle_open_poset` | topos | 函數 |
| `cat_has_pullbacks` | topos | 函數 |
| `cat_opposite` | topos | 函數 |
| `cat_satisfies_right_ore` | topos | 函數 |
| `enumerate_matching_families` | topos | 函數 |
| `presheaf_are_isomorphic` | topos | 函數 |
| `presheaf_coequalizer` | topos | 函數 |
| `presheaf_constant_raw` | topos | 函數 |
| `presheaf_coproduct` | topos | 函數 |
| `presheaf_equalizer` | topos | 函數 |
| `presheaf_hom_compose` | topos | 函數 |
| `presheaf_hom_enumerate` | topos | 函數 |
| `presheaf_hom_eq` | topos | 函數 |
| `presheaf_hom_id` | topos | 函數 |
| `presheaf_hom_is_iso` | topos | 函數 |
| `presheaf_hom_is_mono` | topos | 函數 |
| `presheaf_hom_is_natural` | topos | 函數 |
| `presheaf_initial` | topos | 函數 |
| `presheaf_of_sieve` | topos | 函數 |
| `presheaf_product` | topos | 函數 |
| `presheaf_product_hom` | topos | 函數 |
| `presheaf_pullback` | topos | 函數 |
| `presheaf_representable` | topos | 函數 |
| `presheaf_representable_with_table` | topos | 函數 |
| `presheaf_terminal` | topos | 函數 |
| `section_to_matching_family` | topos | 函數 |
| `sieve_contains` | topos | 函數 |
| `sieve_empty` | topos | 函數 |
| `sieve_generate` | topos | 函數 |
| `sieve_heyting_implies` | topos | 函數 |
| `sieve_inter` | topos | 函數 |
| `sieve_is_j_closed` | topos | 函數 |
| `sieve_is_valid` | topos | 函數 |
| `sieve_j_closure` | topos | 函數 |
| `sieve_maximal` | topos | 函數 |
| `sieve_pullback` | topos | 函數 |
| `sieve_subset` | topos | 函數 |
| `sieve_union` | topos | 函數 |
| `site_circle_good_cover` | topos | 函數 |
| `site_is_valid` | topos | 函數 |
| `site_new` | topos | 函數 |
| `topology_atomic` | topos | 函數 |
| `topology_covers` | topos | 函數 |
| `topology_dense` | topos | 函數 |
| `topology_from_coverage` | topos | 函數 |
| `topology_is_valid` | topos | 函數 |
| `topology_trivial` | topos | 函數 |
| `verify_general_yoneda_lemma` | topos | 函數 |
| `yoneda_elem_to_hom` | topos | 函數 |

### 拓撲斯：層化、笛卡兒閉性、子物件分類子與一般拓撲斯

- 規範形式：J-閉篩真值格 Ω_J、兩步 Grothendieck Plus 層化 a(P)=(P^+)^+ 與米田指數 G^F
- 範疇化：Grothendieck 層拓撲斯 Sh(C,J)、笛卡兒閉結構、子物件分類子拉回與 Lawvere–Tierney 子拓撲斯雙射
- 判定：分離／黏合層條件、層化泛性質、CCC 柯里化同構、特徵態射拉回與 Giraud 不交餘積穩定性判定

| 符號 | 套件 | 類別 |
|---|---|---|
| `ExponentialData` | topos | 結構 |
| `ExponentialData.eval_hom` | topos | 欄位 |
| `ExponentialData.exp` | topos | 欄位 |
| `ExponentialData.prod_exp_dom` | topos | 欄位 |
| `ExponentialData.thetas_by_obj` | topos | 欄位 |
| `SheafificationResult` | topos | 結構 |
| `SheafificationResult.plus_once` | topos | 欄位 |
| `SheafificationResult.sheaf` | topos | 欄位 |
| `SheafificationResult.unit` | topos | 欄位 |
| `SubobjectClassifierData` | topos | 結構 |
| `SubobjectClassifierData.closed_sieves` | topos | 欄位 |
| `SubobjectClassifierData.omega` | topos | 欄位 |
| `SubobjectClassifierData.terminal` | topos | 欄位 |
| `SubobjectClassifierData.true_hom` | topos | 欄位 |
| `characteristic_morphism` | topos | 函數 |
| `exponential_curry` | topos | 函數 |
| `exponential_uncurry` | topos | 函數 |
| `is_boolean_topos` | topos | 函數 |
| `is_de_morgan_topos` | topos | 函數 |
| `is_lawvere_tierney_operator` | topos | 函數 |
| `is_separated_presheaf` | topos | 函數 |
| `is_sheaf` | topos | 函數 |
| `lawvere_tierney_of_site` | topos | 函數 |
| `omega_j_join` | topos | 函數 |
| `omega_j_neg` | topos | 函數 |
| `plus_construction` | topos | 函數 |
| `presheaf_exponential` | topos | 函數 |
| `sheafify` | topos | 函數 |
| `subobject_classifier_presheaf` | topos | 函數 |
| `subobject_classifier_sheaf` | topos | 函數 |
| `topology_of_lawvere_tierney` | topos | 函數 |
| `verify_elementary_and_giraud_topos` | topos | 函數 |
| `verify_sheaf_cartesian_closed` | topos | 函數 |
| `verify_sheafification_universal_property` | topos | 函數 |
| `verify_subobject_classifier_pullback` | topos | 函數 |

### 拓撲斯：幾何態射、局部／連通／原子／緊緻相干性質

- 規範形式：左正合逆像 f^*=a∘Lan_{u^{op}}、右伴隨直像 f_*、平坦張量點函子與局部焦點
- 範疇化：幾何態射伴隨 f^*⊣f_*、局部 Topos 三重伴隨 Δ⊣Γ⊣Γ^!、π_0 連通性、原子 Galois 群胚與相干緊緻覆蓋
- 判定：伴隨雙射、左正合極限保持、Diaconescu 點平坦／覆蓋保持判準、局部／連通／原子／De Morgan／Boolean 性質檢定

| 符號 | 套件 | 類別 |
|---|---|---|
| `AtomicToposReport` | topos | 結構 |
| `AtomicToposReport.is_atomic` | topos | 欄位 |
| `AtomicToposReport.is_boolean` | topos | 欄位 |
| `AtomicToposReport.representable_atom_count` | topos | 欄位 |
| `AtomicToposReport.site_right_ore` | topos | 欄位 |
| `CompactCoherentReport` | topos | 結構 |
| `CompactCoherentReport.has_enough_points` | topos | 欄位 |
| `CompactCoherentReport.is_coherent` | topos | 欄位 |
| `CompactCoherentReport.is_compact` | topos | 欄位 |
| `CompactCoherentReport.max_minimal_cover_arity` | topos | 欄位 |
| `CompactCoherentReport.point_count` | topos | 欄位 |
| `CompactCoherentReport.site_has_pullbacks` | topos | 欄位 |
| `CompactCoherentReport.terminal_irredundant_cover_degree` | topos | 欄位 |
| `ConnectedToposReport` | topos | 結構 |
| `ConnectedToposReport.clopen_subobjects_of_one` | topos | 欄位 |
| `ConnectedToposReport.connected_components` | topos | 欄位 |
| `ConnectedToposReport.delta_two_global_sections` | topos | 欄位 |
| `ConnectedToposReport.is_connected` | topos | 欄位 |
| `FlatPointFunctor` | topos | 結構 |
| `FlatPointFunctor.cat` | topos | 欄位 |
| `FlatPointFunctor.map` | topos | 欄位 |
| `FlatPointFunctor.size` | topos | 欄位 |
| `LocalToposReport` | topos | 結構 |
| `LocalToposReport.focal_point` | topos | 欄位 |
| `LocalToposReport.global_initial_sections` | topos | 欄位 |
| `LocalToposReport.global_terminal_sections` | topos | 欄位 |
| `LocalToposReport.is_local` | topos | 欄位 |
| `LocalToposReport.preserves_coequalizers` | topos | 欄位 |
| `LocalToposReport.preserves_coproducts` | topos | 欄位 |
| `LocalToposReport.triple_adjunction_holds` | topos | 欄位 |
| `analyze_atomic_topos` | topos | 函數 |
| `analyze_compact_coherent_topos` | topos | 函數 |
| `analyze_connected_topos` | topos | 函數 |
| `analyze_local_topos` | topos | 函數 |
| `covariant_representable_point` | topos | 函數 |
| `direct_image_presheaf` | topos | 函數 |
| `enumerate_canonical_points` | topos | 函數 |
| `global_sections_count` | topos | 函數 |
| `inverse_image_presheaf` | topos | 函數 |
| `inverse_image_sheaf` | topos | 函數 |
| `is_atom_sheaf` | topos | 函數 |
| `is_covariant_point_functor` | topos | 函數 |
| `is_diaconescu_point` | topos | 函數 |
| `is_flat_point_functor` | topos | 函數 |
| `point_skyscraper_sheaf` | topos | 函數 |
| `point_stalk_cardinality` | topos | 函數 |
| `verify_geometric_morphism` | topos | 函數 |

### 拓撲斯：幾何邏輯規範形式、分類 Topos 與範疇化

- 規範形式：Joyal–Reyes 析取存在合取幾何規範形 ⋁∃⋀、伴隨量詞 Σ_f⊣f^*⊣Π_f 與命題分類景
- 範疇化：Kripke–Joyal 層語義、分類 Topos B(T)（Pt(B(T))≃Mod_Set(T)）與元素範疇範疇化 PSh(C)/P≃PSh(∫P)
- 判定：Kripke–Joyal 強迫語義、幾何規範形等價性、Beck–Chevalley 正合方塊、分類 Topos 點與模型雙射及切片範疇化檢驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `ClassifyingToposData` | topos | 結構 |
| `ClassifyingToposData.generic_prop_sheaves` | topos | 欄位 |
| `ClassifyingToposData.obj_theories` | topos | 欄位 |
| `ClassifyingToposData.site` | topos | 欄位 |
| `ClassifyingToposData.theory` | topos | 欄位 |
| `GeoAtom` | topos | 列舉 |
| `GeoAtom::AtomEq` | topos | 構造子 |
| `GeoAtom::AtomPred` | topos | 構造子 |
| `GeoAtom::equal` | topos | 函數 |
| `GeoAtom::not_equal` | topos | 函數 |
| `GeoAtom::to_repr` | topos | 函數 |
| `GeoConjClause` | topos | 結構 |
| `GeoConjClause.atoms` | topos | 欄位 |
| `GeoConjClause.num_exists` | topos | 欄位 |
| `GeoConjClause::equal` | topos | 函數 |
| `GeoConjClause::not_equal` | topos | 函數 |
| `GeoConjClause::to_repr` | topos | 函數 |
| `GeoFormula` | topos | 列舉 |
| `GeoFormula::GAnd` | topos | 構造子 |
| `GeoFormula::GEq` | topos | 構造子 |
| `GeoFormula::GExists` | topos | 構造子 |
| `GeoFormula::GFalse` | topos | 構造子 |
| `GeoFormula::GForall` | topos | 構造子 |
| `GeoFormula::GImplies` | topos | 構造子 |
| `GeoFormula::GOr` | topos | 構造子 |
| `GeoFormula::GPred` | topos | 構造子 |
| `GeoFormula::GTrue` | topos | 構造子 |
| `GeoFormula::equal` | topos | 函數 |
| `GeoFormula::not_equal` | topos | 函數 |
| `GeoFormula::to_repr` | topos | 函數 |
| `GeoNormalForm` | topos | 結構 |
| `GeoNormalForm.clauses` | topos | 欄位 |
| `GeoNormalForm.free_arity` | topos | 欄位 |
| `GeoNormalForm::equal` | topos | 函數 |
| `GeoNormalForm::not_equal` | topos | 函數 |
| `GeoNormalForm::to_repr` | topos | 函數 |
| `GeoSequent` | topos | 結構 |
| `GeoSequent.arity` | topos | 欄位 |
| `GeoSequent.conclusion` | topos | 欄位 |
| `GeoSequent.premise` | topos | 欄位 |
| `GeoSequent::equal` | topos | 函數 |
| `GeoSequent::not_equal` | topos | 函數 |
| `GeoSequent::to_repr` | topos | 函數 |
| `GeometricTheory` | topos | 結構 |
| `GeometricTheory.axioms` | topos | 欄位 |
| `GeometricTheory.pred_arities` | topos | 欄位 |
| `PropGeoAxiom` | topos | 結構 |
| `PropGeoAxiom.branches` | topos | 欄位 |
| `PropGeoAxiom.premise_atoms` | topos | 欄位 |
| `PropGeoAxiom::equal` | topos | 函數 |
| `PropGeoAxiom::not_equal` | topos | 函數 |
| `PropGeoAxiom::to_repr` | topos | 函數 |
| `PropGeoTheory` | topos | 結構 |
| `PropGeoTheory.axioms` | topos | 欄位 |
| `PropGeoTheory.num_props` | topos | 欄位 |
| `SheafStructure` | topos | 結構 |
| `SheafStructure.carrier` | topos | 欄位 |
| `SheafStructure.pred_arities` | topos | 欄位 |
| `SheafStructure.relations` | topos | 欄位 |
| `SliceCategoryData` | topos | 結構 |
| `SliceCategoryData.obj_arrow` | topos | 欄位 |
| `SliceCategoryData.proj_mor` | topos | 欄位 |
| `SliceCategoryData.proj_obj` | topos | 欄位 |
| `SliceCategoryData.slice_cat` | topos | 欄位 |
| `Subpresheaf` | topos | 結構 |
| `Subpresheaf.ambient` | topos | 欄位 |
| `Subpresheaf.members` | topos | 欄位 |
| `build_propositional_classifying_topos` | topos | 函數 |
| `cat_slice` | topos | 函數 |
| `category_of_elements` | topos | 函數 |
| `enumerate_set_models_prop` | topos | 函數 |
| `geo_normal_form_to_formula` | topos | 函數 |
| `geometric_normal_form` | topos | 函數 |
| `is_valid_subpresheaf` | topos | 函數 |
| `kripke_joyal_forces` | topos | 函數 |
| `model_satisfies_sequent` | topos | 函數 |
| `subpresheaf_exists` | topos | 函數 |
| `subpresheaf_forall` | topos | 函數 |
| `subpresheaf_pullback` | topos | 函數 |
| `verify_beck_chevalley_quantifiers` | topos | 函數 |
| `verify_classifying_topos_universal_property` | topos | 函數 |
| `verify_elements_slice_categorification` | topos | 函數 |
| `verify_geometric_normal_form_soundness` | topos | 函數 |

### 拓撲斯：廣群棧、下降理論、層上同調與同倫類型

- 規範形式：Čech 下降上閉鏈 g_{ij}·g_{jk}=g_{ik}、Roos／單純上鏈複形與整數 Smith 撓率不變因子
- 範疇化：纖維化廣群棧與 G-主叢下降、有理阿貝爾層上同調 H^•(C;F)、蛇引理長正合序列與神經同倫類型
- 判定：2-範疇下降上閉鏈相容、有效下降黏合雙射、d^{n+1}∘d^n=0、Euler–Poincaré 恆等式、蛇引理連接同態正合性與 Betti／π_1 計算

| 符號 | 套件 | 類別 |
|---|---|---|
| `AbelianPresheafQ` | topos | 結構 |
| `AbelianPresheafQ.cat` | topos | 欄位 |
| `AbelianPresheafQ.dims` | topos | 欄位 |
| `AbelianPresheafQ.res_mats` | topos | 欄位 |
| `CochainComplexQ` | topos | 結構 |
| `CochainComplexQ.differentials` | topos | 欄位 |
| `CochainComplexQ.dims` | topos | 欄位 |
| `CoverDescentDiagram` | topos | 結構 |
| `CoverDescentDiagram.cleavage_transitions` | topos | 欄位 |
| `CoverDescentDiagram.cover_arrows` | topos | 欄位 |
| `CoverDescentDiagram.overlap_obj` | topos | 欄位 |
| `CoverDescentDiagram.proj1` | topos | 欄位 |
| `CoverDescentDiagram.proj12` | topos | 欄位 |
| `CoverDescentDiagram.proj13` | topos | 欄位 |
| `CoverDescentDiagram.proj2` | topos | 欄位 |
| `CoverDescentDiagram.proj23` | topos | 欄位 |
| `CoverDescentDiagram.target` | topos | 欄位 |
| `CoverDescentDiagram.triple_obj` | topos | 欄位 |
| `DescentDatum` | topos | 結構 |
| `DescentDatum.local_objs` | topos | 欄位 |
| `DescentDatum.transitions` | topos | 欄位 |
| `DescentDatum::equal` | topos | 函數 |
| `DescentDatum::not_equal` | topos | 函數 |
| `DescentDatum::to_repr` | topos | 函數 |
| `FiniteGroupoid` | topos | 結構 |
| `FiniteGroupoid.cat` | topos | 欄位 |
| `FiniteGroupoid.inv` | topos | 欄位 |
| `GroupoidFibration` | topos | 結構 |
| `GroupoidFibration.base` | topos | 欄位 |
| `GroupoidFibration.fibers` | topos | 欄位 |
| `GroupoidFibration.pullbacks` | topos | 欄位 |
| `HomotopyTypeSummary` | topos | 結構 |
| `HomotopyTypeSummary.betti_numbers` | topos | 欄位 |
| `HomotopyTypeSummary.euler_characteristic` | topos | 欄位 |
| `HomotopyTypeSummary.pi0_components` | topos | 欄位 |
| `HomotopyTypeSummary.pi1_free_rank` | topos | 欄位 |
| `HomotopyTypeSummary.pi1_torsion_invariants` | topos | 欄位 |
| `HomotopyTypeSummary::equal` | topos | 函數 |
| `HomotopyTypeSummary::not_equal` | topos | 函數 |
| `HomotopyTypeSummary::to_repr` | topos | 函數 |
| `RectQMat` | topos | 結構 |
| `RectQMat.ncols` | topos | 欄位 |
| `RectQMat.nrows` | topos | 欄位 |
| `RectQMat.rows` | topos | 欄位 |
| `RectQMat::equal` | topos | 函數 |
| `RectQMat::not_equal` | topos | 函數 |
| `RectQMat::to_repr` | topos | 函數 |
| `SimplicialNerve` | topos | 結構 |
| `SimplicialNerve.edges` | topos | 欄位 |
| `SimplicialNerve.num_vertices` | topos | 欄位 |
| `SimplicialNerve.tetrahedra` | topos | 欄位 |
| `SimplicialNerve.triangles` | topos | 欄位 |
| `boundary_simplex_nerve` | topos | 函數 |
| `build_circle_z2_torsor_stack` | topos | 函數 |
| `canonical_descent_datum` | topos | 函數 |
| `circle_mobius_double_cover_sheaf` | topos | 函數 |
| `classify_group_torsor_cohomology` | topos | 函數 |
| `classifying_nerve_of_poset` | topos | 函數 |
| `cochain_complex_is_valid` | topos | 函數 |
| `cohomology_dimensions` | topos | 函數 |
| `compute_nerve_homotopy_type` | topos | 函數 |
| `descent_data_isomorphic` | topos | 函數 |
| `groupoid_of_fincat` | topos | 函數 |
| `nerve_constant_cochain_complex_q` | topos | 函數 |
| `rect_qmat_id` | topos | 函數 |
| `rect_qmat_zero` | topos | 函數 |
| `rp2_minimal_nerve` | topos | 函數 |
| `verify_descent_cocycle` | topos | 函數 |
| `verify_euler_poincare` | topos | 函數 |
| `verify_snake_lemma_cohomology_les` | topos | 函數 |
| `verify_stack_effective_descent` | topos | 函數 |

### 拓撲斯：第2輪結構導出演算法（本徵三重伴隨、開閉子拓撲斯核、稠密比較引理、內蘊主叢與杯積環）

- 規範形式：右 Kan 擴展預層 Ran_{u^{op}}、開閉 Lawvere–Tierney 核算子 j_o/j_c、誘導子景拓撲 J_C、內蘊置換群作用與 Alexander–Whitney 2-上鏈杯積
- 範疇化：本徵幾何態射 Lan_{u^{op}}⊣u^*⊣Ran_{u^{op}}、餘 Heyting 開閉子拓撲斯互補分解、Grothendieck–Verdier 稠密子景 Morita 等價、Diaconescu 內蘊 G-主叢層與分次微分代數 H^•(U;Q)
- 判定：三重伴隨 Hom 雙射、無排中律下 J_o∧J_c=J_triv 與 J_o∨J_c=J_⊥ 互補、稠密層重構同構、剪映射雙射 T×G≅T×T 與 Koszul 符號 Leibniz 律及 T^2 對 S^1∨S^1∨S^2 杯積秩區分

| 符號 | 套件 | 類別 |
|---|---|---|
| `InternalGroupTorsor` | topos | 結構 |
| `InternalGroupTorsor.action` | topos | 欄位 |
| `InternalGroupTorsor.carrier` | topos | 欄位 |
| `InternalGroupTorsor.group_elems` | topos | 欄位 |
| `InternalGroupTorsor.site` | topos | 欄位 |
| `SubtoposComplementReport` | topos | 結構 |
| `SubtoposComplementReport.closed_lt_valid` | topos | 欄位 |
| `SubtoposComplementReport.internal_lem_holds` | topos | 欄位 |
| `SubtoposComplementReport.join_is_inconsistent` | topos | 欄位 |
| `SubtoposComplementReport.meet_is_ambient` | topos | 欄位 |
| `SubtoposComplementReport.open_lt_valid` | topos | 欄位 |
| `SubtoposComplementReport.subtopos_boolean_complement_holds` | topos | 欄位 |
| `SubtoposComplementReport::equal` | topos | 函數 |
| `SubtoposComplementReport::not_equal` | topos | 函數 |
| `SubtoposComplementReport::to_repr` | topos | 函數 |
| `build_mobius_internal_z2_torsor` | topos | 函數 |
| `closed_subtopos_lt_operator` | topos | 函數 |
| `induced_dense_subsite_topology` | topos | 函數 |
| `is_connected_essential_functor` | topos | 函數 |
| `is_internal_group_torsor_sheaf` | topos | 函數 |
| `open_subtopos_lt_operator` | topos | 函數 |
| `right_kan_presheaf` | topos | 函數 |
| `simplicial_cup_1_1` | topos | 函數 |
| `simplicial_cup_h1_h1_rank` | topos | 函數 |
| `topology_lattice_join` | topos | 函數 |
| `topology_lattice_meet` | topos | 函數 |
| `torus_t2_minimal_nerve` | topos | 函數 |
| `verify_alexander_whitney_leibniz` | topos | 函數 |
| `verify_essential_geometric_triple_adjunction` | topos | 函數 |
| `verify_grothendieck_comparison_lemma` | topos | 函數 |
| `verify_open_closed_subtopos_complementarity` | topos | 函數 |
| `wedge_s1_s1_s2_nerve` | topos | 函數 |

### 概形：多元多項式、約化 Gröbner 基規範形與根理想

- 規範形式：稀疏規範多元多項式 MPoly、單ic 完全互約 Gröbner 基與標準單項式商基底
- 範疇化：多元多項式環 Q[x_1,…,x_n] 上的理想運算（和／積／交／商／飽和／消元／根理想）
- 判定：Buchberger S-多項式演算法、多元除法餘式唯一性、Rabinowitsch 根理想成員與 Hilbert–Krull 維數判定

| 符號 | 套件 | 類別 |
|---|---|---|
| `Ideal` | scheme | 結構 |
| `Ideal.nvars` | scheme | 欄位 |
| `Ideal.rgb` | scheme | 欄位 |
| `Ideal::equal` | scheme | 函數 |
| `Ideal::not_equal` | scheme | 函數 |
| `Ideal::to_repr` | scheme | 函數 |
| `MPoly` | scheme | 結構 |
| `MPoly.nvars` | scheme | 欄位 |
| `MPoly.terms` | scheme | 欄位 |
| `MPoly::equal` | scheme | 函數 |
| `MPoly::not_equal` | scheme | 函數 |
| `MPoly::to_repr` | scheme | 函數 |
| `MTerm` | scheme | 結構 |
| `MTerm.coeff` | scheme | 欄位 |
| `MTerm.exps` | scheme | 欄位 |
| `MTerm::equal` | scheme | 函數 |
| `MTerm::not_equal` | scheme | 函數 |
| `MTerm::to_repr` | scheme | 函數 |
| `MonomialOrder` | scheme | 列舉 |
| `MonomialOrder::Elim` | scheme | 構造子 |
| `MonomialOrder::GRevLex` | scheme | 構造子 |
| `MonomialOrder::Lex` | scheme | 構造子 |
| `MonomialOrder::equal` | scheme | 函數 |
| `MonomialOrder::not_equal` | scheme | 函數 |
| `MonomialOrder::to_repr` | scheme | 函數 |
| `ReducedGroebnerBasis` | scheme | 結構 |
| `ReducedGroebnerBasis.gens` | scheme | 欄位 |
| `ReducedGroebnerBasis.nvars` | scheme | 欄位 |
| `ReducedGroebnerBasis.order` | scheme | 欄位 |
| `ReducedGroebnerBasis::equal` | scheme | 函數 |
| `ReducedGroebnerBasis::not_equal` | scheme | 函數 |
| `ReducedGroebnerBasis::to_repr` | scheme | 函數 |
| `ideal_add` | scheme | 函數 |
| `ideal_contains` | scheme | 函數 |
| `ideal_eliminate_first_k` | scheme | 函數 |
| `ideal_eq` | scheme | 函數 |
| `ideal_intersect` | scheme | 函數 |
| `ideal_is_unit` | scheme | 函數 |
| `ideal_is_zero` | scheme | 函數 |
| `ideal_krull_dimension` | scheme | 函數 |
| `ideal_new` | scheme | 函數 |
| `ideal_normal_form` | scheme | 函數 |
| `ideal_quotient_poly` | scheme | 函數 |
| `ideal_quotient_vector_space_dim` | scheme | 函數 |
| `ideal_radical` | scheme | 函數 |
| `ideal_radical_contains` | scheme | 函數 |
| `ideal_saturate` | scheme | 函數 |
| `ideal_standard_monomials` | scheme | 函數 |
| `monomial_cmp` | scheme | 函數 |
| `mpoly_add` | scheme | 函數 |
| `mpoly_const` | scheme | 函數 |
| `mpoly_dehomogenize` | scheme | 函數 |
| `mpoly_div_exact` | scheme | 函數 |
| `mpoly_eval` | scheme | 函數 |
| `mpoly_extend_vars` | scheme | 函數 |
| `mpoly_from_terms` | scheme | 函數 |
| `mpoly_int` | scheme | 函數 |
| `mpoly_is_zero` | scheme | 函數 |
| `mpoly_leading_term` | scheme | 函數 |
| `mpoly_monic` | scheme | 函數 |
| `mpoly_mul` | scheme | 函數 |
| `mpoly_neg` | scheme | 函數 |
| `mpoly_of_poly` | scheme | 函數 |
| `mpoly_partial_deriv` | scheme | 函數 |
| `mpoly_pow` | scheme | 函數 |
| `mpoly_reduce` | scheme | 函數 |
| `mpoly_scale` | scheme | 函數 |
| `mpoly_sub` | scheme | 函數 |
| `mpoly_subst` | scheme | 函數 |
| `mpoly_to_poly` | scheme | 函數 |
| `mpoly_to_qpoly_univariate` | scheme | 函數 |
| `mpoly_total_degree` | scheme | 函數 |
| `mpoly_var` | scheme | 函數 |
| `mpoly_zero` | scheme | 函數 |
| `qpoly_to_mpoly_var` | scheme | 函數 |
| `reduced_groebner_basis` | scheme | 函數 |
| `s_polynomial` | scheme | 函數 |

### 概形：座標環、Zariski 層化、既約概形與準凝聚模

- 規範形式：模約化 Gröbner 基商餘式規範形、主開集局部化截面 a/f^m 與冪零根簡化理想 √I
- 範疇化：仿射概形 Spec(Q[x]/I)、Zariski 結構層 O_X、既約伴隨概形 X_red↪X 與準凝聚模局部化範疇
- 判定：Zariski 開覆蓋 1∈⟨f_i⟩ 單位分解、局部截面相容與全局多項式黏合唯一性、冪零見證搜尋與既約泛性質檢驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `AffineScheme` | scheme | 結構 |
| `AffineScheme.ring` | scheme | 欄位 |
| `AffineScheme::equal` | scheme | 函數 |
| `AffineScheme::not_equal` | scheme | 函數 |
| `AffineScheme::to_repr` | scheme | 函數 |
| `CoordRing` | scheme | 結構 |
| `CoordRing.ideal` | scheme | 欄位 |
| `CoordRing.nvars` | scheme | 欄位 |
| `CoordRing::equal` | scheme | 函數 |
| `CoordRing::not_equal` | scheme | 函數 |
| `CoordRing::to_repr` | scheme | 函數 |
| `LocalizedSection` | scheme | 結構 |
| `LocalizedSection.den_base` | scheme | 欄位 |
| `LocalizedSection.exp` | scheme | 欄位 |
| `LocalizedSection.num` | scheme | 欄位 |
| `LocalizedSection::equal` | scheme | 函數 |
| `LocalizedSection::not_equal` | scheme | 函數 |
| `LocalizedSection::to_repr` | scheme | 函數 |
| `QuasiCoherentModule` | scheme | 結構 |
| `QuasiCoherentModule.ncols` | scheme | 欄位 |
| `QuasiCoherentModule.nrows` | scheme | 欄位 |
| `QuasiCoherentModule.rel_matrix` | scheme | 欄位 |
| `QuasiCoherentModule.ring` | scheme | 欄位 |
| `RingHom` | scheme | 結構 |
| `RingHom.dst` | scheme | 欄位 |
| `RingHom.src` | scheme | 欄位 |
| `RingHom.var_images` | scheme | 欄位 |
| `RingHom::equal` | scheme | 函數 |
| `RingHom::not_equal` | scheme | 函數 |
| `RingHom::to_repr` | scheme | 函數 |
| `affine_is_reduced` | scheme | 函數 |
| `affine_reduction` | scheme | 函數 |
| `affine_scheme` | scheme | 函數 |
| `coord_ring_eq` | scheme | 函數 |
| `coord_ring_new` | scheme | 函數 |
| `coord_ring_nf` | scheme | 函數 |
| `glue_zariski_structure_sections` | scheme | 函數 |
| `is_zariski_open_cover` | scheme | 函數 |
| `localize_quasicoherent_module` | scheme | 函數 |
| `localized_section_eq` | scheme | 函數 |
| `principal_open_subset` | scheme | 函數 |
| `ring_hom_apply` | scheme | 函數 |
| `ring_hom_compose` | scheme | 函數 |
| `ring_hom_id` | scheme | 函數 |
| `ring_hom_is_surjective` | scheme | 函數 |
| `ring_hom_is_valid` | scheme | 函數 |
| `solve_ideal_linear_combination` | scheme | 函數 |
| `verify_affine_reduction_universal_property` | scheme | 函數 |

### 概形：黏合概形、概形態射、仿射態射與 DVR 真概形

- 規範形式：局部仿射圖冊 (U_i,U_{ij})、圖冊回拉同態環圖與截斷形式 Laurent 級數 Q((t)) 賦值展開
- 範疇化：一般黏合概形範疇 Sch/Q（A^n, P^n, 射影閉子概形, A^2\0, 雙重原點線）、纖維積、仿射態射與對角浸入 Δ_X
- 判定：上閉鏈黏合相容、仿射開逆像覆蓋局部性、對角閉浸入分離性與離散賦值環 Q[[t]]⊂Q((t)) 真概形唯一延拓判準

| 符號 | 套件 | 類別 |
|---|---|---|
| `ChartOverlap` | scheme | 結構 |
| `ChartOverlap.from_i` | scheme | 欄位 |
| `ChartOverlap.from_j` | scheme | 欄位 |
| `ChartOverlap.is_empty` | scheme | 欄位 |
| `ChartOverlap.ring` | scheme | 欄位 |
| `ChartOverlap::equal` | scheme | 函數 |
| `ChartOverlap::not_equal` | scheme | 函數 |
| `ChartOverlap::to_repr` | scheme | 函數 |
| `LaurentSeries` | scheme | 結構 |
| `LaurentSeries.coeffs` | scheme | 欄位 |
| `LaurentSeries.prec` | scheme | 欄位 |
| `LaurentSeries.val` | scheme | 欄位 |
| `LaurentSeries::equal` | scheme | 函數 |
| `LaurentSeries::not_equal` | scheme | 函數 |
| `LaurentSeries::to_repr` | scheme | 函數 |
| `PropernessReport` | scheme | 結構 |
| `PropernessReport.existence_holds` | scheme | 欄位 |
| `PropernessReport.is_proper` | scheme | 欄位 |
| `PropernessReport.is_separated` | scheme | 欄位 |
| `PropernessReport.uniqueness_holds` | scheme | 欄位 |
| `PropernessReport::equal` | scheme | 函數 |
| `PropernessReport::not_equal` | scheme | 函數 |
| `PropernessReport::to_repr` | scheme | 函數 |
| `Scheme` | scheme | 結構 |
| `Scheme.charts` | scheme | 欄位 |
| `Scheme.overlaps` | scheme | 欄位 |
| `Scheme::equal` | scheme | 函數 |
| `Scheme::not_equal` | scheme | 函數 |
| `Scheme::to_repr` | scheme | 函數 |
| `SchemeMorphism` | scheme | 結構 |
| `SchemeMorphism.chart_map` | scheme | 欄位 |
| `SchemeMorphism.dst` | scheme | 欄位 |
| `SchemeMorphism.ring_maps` | scheme | 欄位 |
| `SchemeMorphism.src` | scheme | 欄位 |
| `SchemeMorphism::equal` | scheme | 函數 |
| `SchemeMorphism::not_equal` | scheme | 函數 |
| `SchemeMorphism::to_repr` | scheme | 函數 |
| `affine_fiber_product` | scheme | 函數 |
| `analyze_scheme_properness` | scheme | 函數 |
| `global_sections_dimension_upto_deg` | scheme | 函數 |
| `is_affine_morphism` | scheme | 函數 |
| `is_separated_scheme` | scheme | 函數 |
| `laurent_add` | scheme | 函數 |
| `laurent_const` | scheme | 函數 |
| `laurent_inv` | scheme | 函數 |
| `laurent_is_integral_dvr` | scheme | 函數 |
| `laurent_is_zero` | scheme | 函數 |
| `laurent_monomial` | scheme | 函數 |
| `laurent_mul` | scheme | 函數 |
| `laurent_sub` | scheme | 函數 |
| `morphism_hopf_punctured_plane_to_p1` | scheme | 函數 |
| `morphism_punctured_plane_to_a2` | scheme | 函數 |
| `morphism_to_spec_q` | scheme | 函數 |
| `mpoly_eval_laurent` | scheme | 函數 |
| `scheme_affine_space` | scheme | 函數 |
| `scheme_doubled_origin_line` | scheme | 函數 |
| `scheme_from_affine` | scheme | 函數 |
| `scheme_is_valid` | scheme | 函數 |
| `scheme_morphism_compose` | scheme | 函數 |
| `scheme_morphism_is_valid` | scheme | 函數 |
| `scheme_projective_space` | scheme | 函數 |
| `scheme_projective_subscheme` | scheme | 函數 |
| `scheme_punctured_plane` | scheme | 函數 |
| `valuative_extension_classes_for_arc` | scheme | 函數 |

### 概形：有理等價、對偶複形、點函子法與動機範疇化

- 規範形式：P^1 正規化 Weil 除子與有理等價類 CH^1、P^1/P^2/平面曲線 Čech 上同調維數、雙齊次對應理想與有限交換環點集
- 範疇化：有理函數主除子商群、Grothendieck–Serre 對偶複形 ω_{P^1}≅O(-2)[1]／ω_{P^2}≅O(-3)[2]／ω_C≅O_C(d-3)[1]、米田點函子 h_X:CRing→Set 與多射影 Gröbner Chow 對應動機範疇
- 判定：有理等價顯式函數 f/g 構造、局部重數 Bézout 定理、Riemann–Roch 與 Serre 對偶配對、F_p[ε] 切空間維數與 6 變元 Gröbner 飽和消元 h(P^1)=1⊕L 動機分解檢驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `FiniteCommRing` | scheme | 結構 |
| `FiniteCommRing.add_table` | scheme | 欄位 |
| `FiniteCommRing.mul_table` | scheme | 欄位 |
| `FiniteCommRing.neg_table` | scheme | 欄位 |
| `FiniteCommRing.one` | scheme | 欄位 |
| `FiniteCommRing.size` | scheme | 欄位 |
| `FiniteCommRing.zero` | scheme | 欄位 |
| `FiniteCommRing::equal` | scheme | 函數 |
| `FiniteCommRing::not_equal` | scheme | 函數 |
| `FiniteCommRing::to_repr` | scheme | 函數 |
| `FiniteRingHom` | scheme | 結構 |
| `FiniteRingHom.dst` | scheme | 欄位 |
| `FiniteRingHom.src` | scheme | 欄位 |
| `FiniteRingHom.values` | scheme | 欄位 |
| `FiniteRingHom::equal` | scheme | 函數 |
| `FiniteRingHom::not_equal` | scheme | 函數 |
| `FiniteRingHom::to_repr` | scheme | 函數 |
| `P1LineBundleCohomology` | scheme | 結構 |
| `P1LineBundleCohomology.chi` | scheme | 欄位 |
| `P1LineBundleCohomology.h0` | scheme | 欄位 |
| `P1LineBundleCohomology.h1` | scheme | 欄位 |
| `P1LineBundleCohomology.twist` | scheme | 欄位 |
| `P1LineBundleCohomology::equal` | scheme | 函數 |
| `P1LineBundleCohomology::not_equal` | scheme | 函數 |
| `P1LineBundleCohomology::to_repr` | scheme | 函數 |
| `P2LineBundleCohomology` | scheme | 結構 |
| `P2LineBundleCohomology.chi` | scheme | 欄位 |
| `P2LineBundleCohomology.h0` | scheme | 欄位 |
| `P2LineBundleCohomology.h1` | scheme | 欄位 |
| `P2LineBundleCohomology.h2` | scheme | 欄位 |
| `P2LineBundleCohomology.twist` | scheme | 欄位 |
| `P2LineBundleCohomology::equal` | scheme | 函數 |
| `P2LineBundleCohomology::not_equal` | scheme | 函數 |
| `P2LineBundleCohomology::to_repr` | scheme | 函數 |
| `PlaneCurveDualizingReport` | scheme | 結構 |
| `PlaneCurveDualizingReport.arithmetic_genus` | scheme | 欄位 |
| `PlaneCurveDualizingReport.canonical_twist` | scheme | 欄位 |
| `PlaneCurveDualizingReport.degree` | scheme | 欄位 |
| `PlaneCurveDualizingReport.h0_oc` | scheme | 欄位 |
| `PlaneCurveDualizingReport.h0_omega` | scheme | 欄位 |
| `PlaneCurveDualizingReport.h1_oc` | scheme | 欄位 |
| `PlaneCurveDualizingReport.h1_omega` | scheme | 欄位 |
| `PlaneCurveDualizingReport.serre_duality_holds` | scheme | 欄位 |
| `PlaneCurveDualizingReport::equal` | scheme | 函數 |
| `PlaneCurveDualizingReport::not_equal` | scheme | 函數 |
| `PlaneCurveDualizingReport::to_repr` | scheme | 函數 |
| `PrimeDivisorP1` | scheme | 列舉 |
| `PrimeDivisorP1::FiniteIrreducible` | scheme | 構造子 |
| `PrimeDivisorP1::PointAtInfinity` | scheme | 構造子 |
| `PrimeDivisorP1::equal` | scheme | 函數 |
| `PrimeDivisorP1::not_equal` | scheme | 函數 |
| `PrimeDivisorP1::to_repr` | scheme | 函數 |
| `WeilDivisorP1` | scheme | 結構 |
| `WeilDivisorP1.terms` | scheme | 欄位 |
| `WeilDivisorP1::equal` | scheme | 函數 |
| `WeilDivisorP1::not_equal` | scheme | 函數 |
| `WeilDivisorP1::to_repr` | scheme | 函數 |
| `are_rationally_equivalent_p1` | scheme | 函數 |
| `bezout_intersection_number_p2` | scheme | 函數 |
| `cech_cohomology_p1_line_bundle` | scheme | 函數 |
| `cech_cohomology_p2_line_bundle` | scheme | 函數 |
| `compose_p1_correspondences_groebner` | scheme | 函數 |
| `eval_affine_functor_of_points` | scheme | 函數 |
| `eval_scheme_functor_of_points` | scheme | 函數 |
| `fcomm_dual_numbers` | scheme | 函數 |
| `fcomm_fp` | scheme | 函數 |
| `finite_ring_hom_is_valid` | scheme | 函數 |
| `mpoly_eval_finite_ring` | scheme | 函數 |
| `p1_correspondence_bidegree` | scheme | 函數 |
| `plane_curve_dualizing_complex` | scheme | 函數 |
| `plane_curve_line_bundle_cohomology` | scheme | 函數 |
| `principal_divisor_p1` | scheme | 函數 |
| `pushforward_affine_point` | scheme | 函數 |
| `quasicoherent_fitting_ideal` | scheme | 函數 |
| `rational_equivalence_witness_p1` | scheme | 函數 |
| `verify_bezout_theorem_p2` | scheme | 函數 |
| `verify_motivic_p1_categorification` | scheme | 函數 |
| `verify_serre_duality_and_riemann_roch_p1` | scheme | 函數 |
| `verify_serre_duality_p2` | scheme | 函數 |
| `weil_divisor_p1_degree` | scheme | 函數 |
| `weil_divisor_p1_normalize` | scheme | 函數 |
| `weil_divisor_p1_sub` | scheme | 函數 |
| `zariski_tangent_dimension_fp` | scheme | 函數 |

### 概形：第2輪結構導出演算法（Kähler 微分、平展判準、Hilbert 多項式、爆炸奇點解消與 Frobenius 下降）

- 規範形式：Kähler 微分呈現矩陣 Ω^1_{B/A}、零階 Fitting 與 Jacobi 子式理想、符號 Hilbert 多項式 P_X(t)∈Q[t]、雙圖冊嚴格變換概形與二次有限域 F_{p^2} 乘法表
- 範疇化：相對微分模與無分歧／光滑／平展態射、Tjurina 孤立奇點代數 τ(X)、任意餘維射影度數與算術虧格、Rees 爆炸 Bl_{(0,0)}(A^2) 奇點解消及 Galois–Frobenius 點計數下降
- 判定：Fitting 零化 1∈Fitt_0(Ω^1) 局部化交換性、Macaulay 初理想容斥與齊次單項式計數互校、Gröbner 飽和嚴格變換光滑性與例外纖維既約性區分及 F_3⊂F_9 算術有理點跳躍檢驗

| 符號 | 套件 | 類別 |
|---|---|---|
| `PlaneCurveBlowupReport` | scheme | 結構 |
| `PlaneCurveBlowupReport.exceptional_fiber_is_reduced` | scheme | 欄位 |
| `PlaneCurveBlowupReport.exceptional_fiber_length` | scheme | 欄位 |
| `PlaneCurveBlowupReport.origin_was_singular` | scheme | 欄位 |
| `PlaneCurveBlowupReport.strict_transform` | scheme | 欄位 |
| `PlaneCurveBlowupReport.strict_transform_is_smooth` | scheme | 欄位 |
| `ProjectiveHilbertReport` | scheme | 結構 |
| `ProjectiveHilbertReport.ambient_dim` | scheme | 欄位 |
| `ProjectiveHilbertReport.arithmetic_genus` | scheme | 欄位 |
| `ProjectiveHilbertReport.degree` | scheme | 欄位 |
| `ProjectiveHilbertReport.hilbert_poly` | scheme | 欄位 |
| `ProjectiveHilbertReport.matches_hilbert_function` | scheme | 欄位 |
| `ProjectiveHilbertReport.projective_dim` | scheme | 欄位 |
| `affine_is_smooth` | scheme | 函數 |
| `affine_jacobian_ideal` | scheme | 函數 |
| `affine_kahler_differentials` | scheme | 函數 |
| `affine_tjurina_number` | scheme | 函數 |
| `blowup_plane_curve_at_origin` | scheme | 函數 |
| `fcomm_fp2` | scheme | 函數 |
| `is_etale_ring_hom_between_smooth` | scheme | 函數 |
| `is_unramified_ring_hom` | scheme | 函數 |
| `kahler_differentials_module` | scheme | 函數 |
| `projective_hilbert_function` | scheme | 函數 |
| `projective_hilbert_report` | scheme | 函數 |
| `quasicoherent_fitting_zero_ideal` | scheme | 函數 |
| `quasicoherent_module_is_zero` | scheme | 函數 |
| `verify_weil_zeta_and_galois_frobenius_descent` | scheme | 函數 |

### 六支柱大一統：邏輯理論轉譯與幾何邏輯精細圖譜

- 規範形式：跨立方類型論／Topos／概形／熱帶半環之規範形與幾何公式轉譯及 18 項精細圖譜條目
- 範疇化：Glivenko ¬¬ 稠密布林子拓撲斯、Stone–Zariski 分類景對偶、Kapranov 熱帶賦值、平展主叢 Galois 橋、子拓撲斯與爆炸切除橋及 S^1/P^1/Galois/動機六支柱合成
- 判定：跨支柱語義保持、見證與反例雙向非平凡檢驗及 30 項統一大一統證書全數實算裁決

| 符號 | 套件 | 類別 |
|---|---|---|
| `DoubleVArchitectureReport` | bridge | 結構 |
| `DoubleVArchitectureReport.four_conjectures_evaluated` | bridge | 欄位 |
| `DoubleVArchitectureReport.k6_bridges_verified` | bridge | 欄位 |
| `DoubleVArchitectureReport.lower_v_gcd_apex_ok` | bridge | 欄位 |
| `DoubleVArchitectureReport.seven_boundaries_breakthrough_ok` | bridge | 欄位 |
| `DoubleVArchitectureReport.six_federations_verified` | bridge | 欄位 |
| `DoubleVArchitectureReport.upper_v_synthesis_apex_ok` | bridge | 欄位 |
| `DoubleVArchitectureReport.x_overlap_ok` | bridge | 欄位 |
| `DoubleVArchitectureReport::equal` | bridge | 函數 |
| `DoubleVArchitectureReport::not_equal` | bridge | 函數 |
| `DoubleVArchitectureReport::to_repr` | bridge | 函數 |
| `FederationDescriptor` | bridge | 結構 |
| `FederationDescriptor.canonical_normal_form` | bridge | 欄位 |
| `FederationDescriptor.categorification_role` | bridge | 欄位 |
| `FederationDescriptor.id` | bridge | 欄位 |
| `FederationDescriptor.live_health_ok` | bridge | 欄位 |
| `FederationDescriptor.packages` | bridge | 欄位 |
| `FederationDescriptor.slug` | bridge | 欄位 |
| `FederationDescriptor.summary` | bridge | 欄位 |
| `FederationDescriptor::equal` | bridge | 函數 |
| `FederationDescriptor::not_equal` | bridge | 函數 |
| `FederationDescriptor::to_repr` | bridge | 函數 |
| `FederationId` | bridge | 列舉 |
| `FederationId::Condensed` | bridge | 構造子 |
| `FederationId::Cubical` | bridge | 構造子 |
| `FederationId::Discovery` | bridge | 構造子 |
| `FederationId::Scheme` | bridge | 構造子 |
| `FederationId::Semiring` | bridge | 構造子 |
| `FederationId::Symlib` | bridge | 構造子 |
| `FederationId::Topos` | bridge | 構造子 |
| `FederationId::equal` | bridge | 函數 |
| `FederationId::not_equal` | bridge | 函數 |
| `FederationId::to_repr` | bridge | 函數 |
| `FederationPairBridge` | bridge | 結構 |
| `FederationPairBridge.bridge_theorem` | bridge | 欄位 |
| `FederationPairBridge.holds` | bridge | 欄位 |
| `FederationPairBridge.id` | bridge | 欄位 |
| `FederationPairBridge.lhs` | bridge | 欄位 |
| `FederationPairBridge.quantitative_witness` | bridge | 欄位 |
| `FederationPairBridge.rhs` | bridge | 欄位 |
| `FederationPairBridge::equal` | bridge | 函數 |
| `FederationPairBridge::not_equal` | bridge | 函數 |
| `FederationPairBridge::to_repr` | bridge | 函數 |
| `GeometryLogicAtlasEntry` | bridge | 結構 |
| `GeometryLogicAtlasEntry.contrast_holds` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.correspondence_theorem` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.domain` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.geometric_structure` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.id` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.logical_counterpart` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.quantitative_summary` | bridge | 欄位 |
| `GeometryLogicAtlasEntry.witness_holds` | bridge | 欄位 |
| `GeometryLogicAtlasEntry::equal` | bridge | 函數 |
| `GeometryLogicAtlasEntry::not_equal` | bridge | 函數 |
| `GeometryLogicAtlasEntry::to_repr` | bridge | 函數 |
| `GrandUnificationReport` | bridge | 結構 |
| `GrandUnificationReport.all_ok` | bridge | 欄位 |
| `GrandUnificationReport.atlas_verified_count` | bridge | 欄位 |
| `GrandUnificationReport.federations_verified_count` | bridge | 欄位 |
| `GrandUnificationReport.five_federation_pentagon_ok` | bridge | 欄位 |
| `GrandUnificationReport.five_federations_ok` | bridge | 欄位 |
| `GrandUnificationReport.geometry_logic_atlas_ok` | bridge | 欄位 |
| `GrandUnificationReport.k5_bridges_verified_count` | bridge | 欄位 |
| `GrandUnificationReport.k5_pairwise_bridges_ok` | bridge | 欄位 |
| `GrandUnificationReport.logic_translation_ok` | bridge | 欄位 |
| `GrandUnificationReport.six_pillar_circle_sphere_ok` | bridge | 欄位 |
| `GrandUnificationReport.total_certificates_count` | bridge | 欄位 |
| `GrandUnificationReport.total_certificates_passed` | bridge | 欄位 |
| `GrandUnificationReport::equal` | bridge | 函數 |
| `GrandUnificationReport::not_equal` | bridge | 函數 |
| `GrandUnificationReport::to_repr` | bridge | 函數 |
| `SevenFederationStarPrismReport` | bridge | 結構 |
| `SevenFederationStarPrismReport.conjectures_evaluated` | bridge | 欄位 |
| `SevenFederationStarPrismReport.epistemic_lenses_sealed` | bridge | 欄位 |
| `SevenFederationStarPrismReport.evolution_families_verified` | bridge | 欄位 |
| `SevenFederationStarPrismReport.k7_bridges_verified` | bridge | 欄位 |
| `SevenFederationStarPrismReport.lakatos_refinements_verified` | bridge | 欄位 |
| `SevenFederationStarPrismReport.seven_federations_verified` | bridge | 欄位 |
| `SevenFederationStarPrismReport.star_prism_commutes` | bridge | 欄位 |
| `SevenFederationStarPrismReport::equal` | bridge | 函數 |
| `SevenFederationStarPrismReport::not_equal` | bridge | 函數 |
| `SevenFederationStarPrismReport::to_repr` | bridge | 函數 |
| `XOverlapChiasmReport` | bridge | 結構 |
| `XOverlapChiasmReport.chiasm_commutes` | bridge | 欄位 |
| `XOverlapChiasmReport.diagonal_d1_syntax_nonarch_ok` | bridge | 欄位 |
| `XOverlapChiasmReport.diagonal_d2_analytic_homotopy_ok` | bridge | 欄位 |
| `XOverlapChiasmReport.shared_chiasm_invariants` | bridge | 欄位 |
| `XOverlapChiasmReport.x_pivot_2_categories_ok` | bridge | 欄位 |
| `XOverlapChiasmReport.x_pivot_condensed_4_structures_ok` | bridge | 欄位 |
| `XOverlapChiasmReport.x_pivot_gcd_lattice_ok` | bridge | 欄位 |
| `XOverlapChiasmReport::equal` | bridge | 函數 |
| `XOverlapChiasmReport::not_equal` | bridge | 函數 |
| `XOverlapChiasmReport::to_repr` | bridge | 函數 |
| `build_cchm_interval_classifying_topos` | bridge | 函數 |
| `build_fine_grained_geometry_logic_atlas` | bridge | 函數 |
| `five_federation_descriptors` | bridge | 函數 |
| `glivenko_double_negation_formula` | bridge | 函數 |
| `grand_unification_certificates` | bridge | 函數 |
| `run_grand_unification_system` | bridge | 函數 |
| `seven_federation_descriptors` | bridge | 函數 |
| `six_federation_descriptors` | bridge | 函數 |
| `translate_coord_ring_to_zariski_theory` | bridge | 函數 |
| `translate_cubical_dim_to_mpoly` | bridge | 函數 |
| `translate_cubical_dterm_to_geo_formula` | bridge | 函數 |
| `translate_cubical_face_to_geo_formula` | bridge | 函數 |
| `translate_cubical_face_to_zariski_ideal` | bridge | 函數 |
| `translate_sexpr_to_geo_formula` | bridge | 函數 |
| `verify_cubical_algebra_scheme_bridge` | bridge | 函數 |
| `verify_dependent_cubical_topos_bridge` | bridge | 函數 |
| `verify_double_v_architecture` | bridge | 函數 |
| `verify_excision_subtopos_blowup_bridge` | bridge | 函數 |
| `verify_five_federation_pentagon_unification` | bridge | 函數 |
| `verify_glivenko_topos_subtopos_bridge` | bridge | 函數 |
| `verify_k5_federation_bridges` | bridge | 函數 |
| `verify_k6_11_condensed_cubical_bridge` | bridge | 函數 |
| `verify_k6_12_condensed_symlib_bridge` | bridge | 函數 |
| `verify_k6_13_condensed_semiring_bridge` | bridge | 函數 |
| `verify_k6_14_condensed_topos_bridge` | bridge | 函數 |
| `verify_k6_15_condensed_scheme_bridge` | bridge | 函數 |
| `verify_k6_federation_bridges` | bridge | 函數 |
| `verify_k7_16_discovery_cubical_bridge` | bridge | 函數 |
| `verify_k7_17_discovery_symlib_bridge` | bridge | 函數 |
| `verify_k7_18_discovery_semiring_bridge` | bridge | 函數 |
| `verify_k7_19_discovery_topos_bridge` | bridge | 函數 |
| `verify_k7_20_discovery_scheme_bridge` | bridge | 函數 |
| `verify_k7_21_discovery_condensed_bridge` | bridge | 函數 |
| `verify_k7_federation_bridges` | bridge | 函數 |
| `verify_kapranov_tropical_laurent_bridge` | bridge | 函數 |
| `verify_quadratic_etale_torsor_galois_bridge` | bridge | 函數 |
| `verify_quaternary_normal_forms` | bridge | 函數 |
| `verify_semiring_kleene_alexandroff_topos_bridge` | bridge | 函數 |
| `verify_seven_federation_star_prism` | bridge | 函數 |
| `verify_six_pillar_circle_sphere_unification` | bridge | 函數 |
| `verify_symlib_galois_topos_bridge` | bridge | 函數 |
| `verify_symlib_symmetric_scheme_bridge` | bridge | 函數 |
| `verify_x_overlap_chiasmus` | bridge | 函數 |
| `verify_zariski_topos_invariance_vs_nilpotent_points` | bridge | 函數 |
<!-- APPENDIX:END -->
