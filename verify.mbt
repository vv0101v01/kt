///|
// Architecture boundary: the root package consumes the host-filesystem
// package only through this explicit import list.  The durability and BFT
// quorum protocols are simulated in pure MoonBit so that they verify on
// every target (`wasm-gc` and `native`).
using @hostfs {
  check_durable_write_protocol,
  bft_check_consensus_and_crash_durability,
}

///|
// The theorem registry: every requirement, as an executable check.
//
// Each entry returns a boolean computed from concrete instances, using
// only the public operations of the layers below.  Where the model is
// finite (face formulas, finite types) checks are exhaustive; where it
// is continuous (vectors, cubes) checks are equalities of explicit
// formulas verified on sample grids — the formulas themselves are the
// constructions (Kan filler, projector pruning), so the sample checks
// test the constructions' defining equations.

///|
pub(all) struct CheckResult {
  name : String
  ok : Bool
}

///|
/// Registry-level conjunction: every type family of the project has
/// a Kan structure.  This intentionally lives in the registry layer,
/// so the dependent-kernel layer does not depend upward on the
/// finite/vector Glue models.
pub fn check_kan_all_types() -> Bool {
  check_kan_dep_all() && check_glue_comp_all() && check_cube_comp()
}

///|
pub fn sample_vectors() -> Array[CVec] {
  [
    [cx_real(1.0), cx(0.0, 1.0), cx(2.0, -1.0)],
    [cx_zero(), cx_zero(), cx_zero()],
    [cx(-1.0, 2.0), cx(0.5, 0.25), cx(0.0, -3.0)],
    example_unit(),
    vec_e3(),
  ]
}

///|
pub fn grid() -> Array[Double] {
  [0.0, 0.25, 0.5, 0.75, 1.0]
}

///|
pub fn check_projector() -> Bool {
  let p = example_projector()
  is_hermitian(p) &&
  is_idempotent(p) &&
  is_projector(p) &&
  (mat_trace_re(p) - 1.0).abs() < 0.000001
}

///|
pub fn check_eigenspace() -> Bool {
  let p = example_projector()
  eigenspace_well_formed(p, sample_vectors()) &&
  pruning_is_retraction(p, sample_vectors()) &&
  is_projector(complement(p))
}

///|
pub fn check_commuting() -> Bool {
  let p = example_projector()
  let q = outer(vec_e3()) // orthogonal range: PQ = 0 = QP
  let r = outer([cx(inv_sqrt2(), 0.0), cx_zero(), cx(inv_sqrt2(), 0.0)])
  commuting_projectors_compatible(p, q) &&
  commuting_projectors_compatible(p, complement(p)) &&
  !mat_commutes(p, r) // non-commuting pair is detected as such
}

///|
pub fn check_interval_faces() -> Bool {
  let i0 = face_var0(0)
  let i1 = face_var1(0)
  let j0 = face_var0(1)
  interval_laws_hold(grid()) &&
  eval_dim(DZero, [0.5]) == 0.0 &&
  face_unsat(FBot, 2) &&
  face_eq_mod(FOr(i0, i0), i0, 2) &&
  face_unsat(FAnd(i0, i1), 2) &&
  face_le(FAnd(i0, j0), i0, 2) &&
  !face_le(i0, j0, 2) &&
  face_eq_mod(FAnd(FTop, i0), i0, 2)
}

///|
pub fn check_systems() -> Bool {
  let v1 : CVec = [cx_real(1.0), cx_zero(), cx_zero()]
  let v2 = vec_e3()
  let i0 = face_var0(0)
  let i1 = face_var1(0)
  let sys = system_of([
    branch(i0, v1),
    branch(i1, v2),
    branch(FAnd(i0, face_var0(1)), v1), // subsumed by branch 1
    branch(FAnd(i0, i1), v2), // unsatisfiable face
  ])
  let bad = system_of([branch(FTop, v1), branch(i0, v2)])
  let a = system_of([branch(i0, v1)])
  let b = system_of([branch(i1, v2)])
  let ext_ok = match system_extend_top(a, v1, 2) {
    Some(_) => true
    None => false
  }
  let ext_bad = match system_extend_top(a, v2, 2) {
    Some(_) => false
    None => true
  }
  system_compatible(sys, 2) &&
  !system_compatible(bad, 2) &&
  pruning_respects_quotient(sys, 2) &&
  prune_system(sys, 2).branches.length() == 2 &&
  union_commutes_mod(a, b, 2) &&
  compatibility_respects_quotient(sys, b, 2) &&
  ext_ok &&
  ext_bad
}

///|
pub fn check_cube_comp() -> Bool {
  let p = example_projector()
  let u = example_unit()
  let u2 = vec_scale(2.0, u)
  let u3 = vec_scale_c(cx(0.0, 1.0), u) // i·u, still in im P
  let u4 = vec_scale(3.0, u)
  let bottom = path_line(u, u2)
  let left = path_line(u, u3)
  let right = path_line(u2, u4)
  let filler = square_fill(bottom, left, right)
  open_box_wf(bottom, left, right) &&
  filler_respects_box(filler, bottom, left, right, grid()) &&
  face_maps_commute(filler, 0.0, 1.0) &&
  face_maps_commute(filler, 1.0, 0.0) &&
  eigenspace_kan_sound(p, bottom, left, right, grid()) &&
  path_trans_endpoints(bottom, path_line(u2, u3)) &&
  vec_approx_eq(path_start(path_sym(bottom)), u2) &&
  vec_approx_eq(path_end(path_sym(bottom)), u)
}

///|
pub fn check_kan_pruning() -> Bool {
  let p = example_projector()
  let u = example_unit()
  let bottom = path_line(u, vec_scale(2.0, u))
  let left = path_line(u, vec_scale_c(cx(0.0, 1.0), u))
  let right = path_line(vec_scale(2.0, u), vec_scale(3.0, u))
  pruning_repairs_filler(p, bottom, left, right, vec_e3(), grid())
}

///|
pub fn sample_terms() -> Array[Term] {
  [
    tm_id(),
    tm_const(),
    tm_swap(),
    TmApp(tm_id(), TmBool(true)),
    TmApp(TmApp(tm_const(), TmBool(true)), TmBool(false)),
    TmApp(tm_swap(), TmPair(TmBool(true), TmUnit)),
    TmCoeRefl,
    TmCoeUaSwap,
    TmApp(TmCoeUaSwap, TmPair(TmUnit, TmBool(false))),
    TmPair(TmFst(TmPair(TmBool(false), TmUnit)), TmUnit),
  ]
}

///|
pub fn check_nbe() -> Bool {
  let beta = Term::TmApp(
    Term::TmApp(tm_const(), Term::TmBool(true)),
    Term::TmBool(false),
  )
  let open_term = Term::TmPair(
    Term::TmSnd(Term::TmVar(0)),
    Term::TmFst(Term::TmVar(0)),
  )
  nbe_single_valued(sample_terms(), 0) &&
  nbe_single_valued([open_term], 1) &&
  nf(beta, 0) == TmBool(true) &&
  def_eq(TmApp(tm_id(), TmBool(false)), TmBool(false), 0) &&
  nf(tm_swap(), 0) == tm_swap()
}

///|
pub fn check_coe_definitional() -> Bool {
  coe_rules_definitional() && swap_involutive_on_element()
}

///|
pub fn check_hoas() -> Bool {
  let terms = sample_terms()
  for i in 0..<terms.length() {
    if !hoas_roundtrip_term(terms[i], 0) {
      return false
    }
  }
  let beta_in_hoas = happ(hoas_swap_example(), HPair(HBool(true), HUnit))
  hoas_roundtrip_hoas(hoas_swap_example(), 0) &&
  hoas_roundtrip_hoas(hoas_const_example(), 0) &&
  hoas_to_term(0, hoas_swap_example()) == tm_swap() &&
  hoas_to_term(0, beta_in_hoas) == TmPair(TmUnit, TmBool(true))
}

///|
pub fn check_ua_coe() -> Bool {
  let iso = iso_swap(TyBool, TyUnit)
  let p = iso_to_path(iso)
  let x = PVal::PVPair(PVal::PVBool(true), PVal::PVUnit)
  iso_wf(iso) &&
  upath_left(p) == TyProd(TyBool, TyUnit) &&
  upath_right(p) == TyProd(TyUnit, TyBool) &&
  coe_computes(p) &&
  coe_upath(p, 0, 1, x) == PVPair(PVUnit, PVBool(true)) &&
  coe_computes(ua(equiv_bool_not())) &&
  equiv_wf(equiv_prod(equiv_bool_not(), equiv_swap(TyBool, TyUnit)))
}

///|
pub fn check_pathp_exchange() -> Bool {
  let e1 = equiv_bool_not()
  let e2 = equiv_id(TyUnit)
  let pp = pathp_prod(
    pathp_canonical(ua(e1), PVBool(true)),
    pathp_canonical(ua(e2), PVUnit),
  )
  swap_naturality(e1, e2) &&
  pathp_wf(pp) &&
  pp.at1 == PVPair(PVBool(false), PVUnit) &&
  pathp_prod_exchange_roundtrip(pp, e1, e2)
}

///|
pub fn check_glue() -> Bool {
  let g = GlueData::{
    base_ty: TyBool,
    partial_ty: TyBool,
    equiv: equiv_bool_not(),
    face: face_var0(0),
  }
  // not(true) = false: compatible on the face (i = 0).
  let good = make_glue(g, PVBool(true), PVBool(false), 1)
  let bad = make_glue(g, PVBool(true), PVBool(true), 1)
  let good_ok = match good {
    Some(e) => glue_sound(g, e, 1) && unglue(e) == PVBool(false)
    None => false
  }
  let bad_rejected = match bad {
    Some(_) => false
    None => true
  }
  // On the empty face there is no constraint: Glue[⊥ ↦ …] A behaves as A.
  let g_bot = GlueData::{
    base_ty: TyBool,
    partial_ty: TyBool,
    equiv: equiv_bool_not(),
    face: FAnd(face_var0(0), face_var1(0)),
  }
  let bot_ok = match make_glue(g_bot, PVBool(true), PVBool(true), 1) {
    Some(e) => glue_sound(g_bot, e, 1)
    None => false
  }
  good_ok && bad_rejected && bot_ok
}

///|
pub fn check_j() -> Bool {
  let fam = Family::{ fiber: _x => TyBool, }
  let p = refl_path(TyBool, PVBool(true))
  let ill = DiscPath::{
    ty: TyBool,
    lo: PVBool(true),
    hi: PVBool(false),
    point: _t => PVBool(true),
  }
  let ill_rejected = match j_elim_disc(fam, PVBool(false), ill) {
    Some(_) => false
    None => true
  }
  j_roundtrip(fam, PVBool(false), p) && ill_rejected
}

///|
/// Transport in a constant family respects, and is respected by, the
/// orthogonal eigenspace decomposition: decompose, transport each
/// component (identity, in a constant family), recompose — the round-trip
/// is the identity and the two directions stay orthogonal throughout.
pub fn check_orthogonal_roundtrip() -> Bool {
  let p = example_projector()
  let samples = sample_vectors()
  for s in 0..<samples.length() {
    let v = samples[s]
    let (v1, v0) = decompose(p, v)
    if !vec_orthogonal(v1, v0) {
      return false
    }
    // forth: split; back: recompose.  Each component is a fixed point of
    // its own projector, so the round-trip cannot drift between summands.
    let back = vec_add(mat_vec(p, v1), mat_vec(complement(p), v0))
    if !vec_approx_eq(back, v) {
      return false
    }
    if !vec_approx_eq(mat_vec(p, v0), vec_zero(v.length())) {
      return false
    }
  }
  true
}

///|
pub fn run_all_checks() -> Array[CheckResult] {
  [
    CheckResult::{
      name: "幂等 Hermitian 矩陣 P²=P, P†=P（正交投影）",
      ok: check_projector(),
    },
    CheckResult::{
      name: "特徵空間良構性 Cⁿ=im(P)⊕ker(P)，特徵值 1/0，正交分解",
      ok: check_eigenspace(),
    },
    CheckResult::{
      name: "可交換投影相容性 PQ=QP ⇒ PQ 為投影（不交換者被檢出）",
      ok: check_commuting(),
    },
    CheckResult::{
      name: "區間 De Morgan 律與面公式商（蘊含／等價可判定）",
      ok: check_interval_faces(),
    },
    CheckResult::{
      name: "系統商：剪枝保商、聯集可交換、相容性保商、擴張可行性判定",
      ok: check_systems(),
    },
    CheckResult::{
      name: "立方體在區間上 comp：開盒填充邊界方程、面映射交換、路徑傳遞",
      ok: check_cube_comp(),
    },
    CheckResult::{
      name: "特徵空間 Kan 纖維化剪枝：P∘fill 保持邊界並落入 im(P)",
      ok: check_kan_pruning(),
    },
    CheckResult::{
      name: "NbE 單值性：nf(nf t)=nf t，定義相等由正規形判定",
      ok: check_nbe(),
    },
    CheckResult::{
      name: "coe 定義相等：coe^refl ≡ id，coe^(ua swap) ≡ swap（NbE）",
      ok: check_coe_definitional(),
    },
    CheckResult::{
      name: "HOAS 同構：往返一周 = NbE 正規形，正規形上嚴格相等",
      ok: check_hoas(),
    },
    CheckResult::{
      name: "同構即相等 ua：Iso→Equiv→Path，coe 計得 equivFun（wiring 符號驗證）",
      ok: check_ua_coe(),
    },
    CheckResult::{
      name: "PathP 積交換：swap∘(e₁×e₂)=(e₂×e₁)∘swap；PathP 積分解往返",
      ok: check_pathp_exchange(),
    },
    CheckResult::{
      name: "Glue 可靠性：φ ⊢ equivFun(partial)=unglue；不相容 glue 被拒",
      ok: check_glue(),
    },
    CheckResult::{
      name: "J 計算規則與往返：J(refl)=d 且沿 p、sym p 往返回 d",
      ok: check_j(),
    },
    CheckResult::{
      name: "往返正交：常值族 transport 在 im(P)⊕ker(P) 分量正交且往返恆等",
      ok: check_orthogonal_roundtrip(),
    },
    CheckResult::{
      name: "NbE 加 η：函數/積/單位 η 長正規形，swap∘swap ≡ id（函數層面）",
      ok: check_eta_all(),
    },
    CheckResult::{
      name: "符號判定：面公式 ROBDD 規範形（sat/≤/≡ 不再枚舉 2ⁿ）",
      ok: check_bdd_canonical(),
    },
    CheckResult::{
      name: "符號判定：有限等價 wiring 規範形（置換性、合成、逆，範疇＋相干性）",
      ok: check_wiring_category() && check_wiring_coherence(),
    },
    CheckResult::{
      name: "一般 Glue comp：有限等價線端點算法＋子空間線開盒 hcomp 校正",
      ok: check_glue_comp_all(),
    },
    CheckResult::{
      name: "範疇化：Karoubi／面偏序／立方體範疇／句法笛卡兒閉範疇律",
      ok: check_categories_all(),
    },
    CheckResult::{
      name: "規格登記健全：逐條範形/範疇/判定齊備，名稱與符號不重複",
      ok: spec_registry_sound(),
    },
    CheckResult::{
      name: "依賴 NbE：Π/Σ 與累積宇宙 Typeᵢ，依賴代入與型別導向轉換/η",
      ok: check_dep_all(),
    },
    CheckResult::{
      name: "Kan 結構全型別化：Π/Σ/Universe 的 coe/comp 遞迴，連同 LTy/Ty/子空間/Glue",
      ok: check_kan_all_types(),
    },
    CheckResult::{
      name: "完全符號代數：特徵多項式、譜投影 Lagrange 公式恆等、仿射唯一填充恆等",
      ok: check_symbolic_algebra_all(),
    },
    CheckResult::{
      name: "立方 AST：PathP、Nat/List 與 Circle/Torus 的語法、檢查、NbE 及依賴消去",
      ok: check_ast_paths() && check_ast_data() && check_ast_hits(),
    },
    CheckResult::{
      name: "Kan 項構造子：coe/comp/hcomp/hfill 與多分支系統在 AST 中計算，hcompU 產生 Glue",
      ok: check_ast_kan_terms(),
    },
    CheckResult::{
      name: "hcomp 按型別化簡：Π 反變、Σ 沿填充、Path 端點分支、資料構造子、HIT 形式點與 Universe",
      ok: check_ast_kan_types(),
    },
    CheckResult::{
      name: "語義系統重構：持久共享環境、惰性求值、語義快取、DSystem 按值合併排序與多分支 Glue",
      ok: check_phase5_semantic_systems(),
    },
    CheckResult::{
      name: "通用歸納族生成器：telescope、嚴格正性、Nat/Bool/List/Vec/Fin/Tree/W 的檢查、消去與 comp",
      ok: check_generated_inductive_schemas(),
    },
    CheckResult::{
      name: "通用 HIT 生成器：0/1/2 維 cells、face 化簡、巢狀 PathP 消去、Circle/Segment/Torus 與同 cell comp",
      ok: check_generated_hit_schemas(),
    },
    CheckResult::{
      name: "Schema 擴展：結構化正性、容器函子巢狀/互歸納/歸納遞迴、商 HIT、宇宙多態與任意維 cells",
      ok: check_schema_extensions(),
    },
    CheckResult::{
      name: "原始 DSystem：面相對轉換判定相容性，first-match 系統有精確不交範形",
      ok: check_dsystem_compatibility() && check_dsystem_first_match_nf(),
    },
    CheckResult::{
      name: "AST 一等 Equiv：Equiv/ua/GlueEquiv 的檢查、轉換、引文與 Kan 計算",
      ok: check_equiv_ast(),
    },
    CheckResult::{
      name: "受檢查型別線與 schema 註冊：維度代換封閉、驗證與 telescope elaboration 快取",
      ok: check_phase6_infrastructure(),
    },
    CheckResult::{
      name: "精確代數擴展：廣義特徵空間、Jordan 分解、代數數與根式範形",
      ok: check_algebraic_extensions_and_Jordan(),
    },
    CheckResult::{
      name: "BDD DAG 與認證數值：hash-consing/預算/DPLL，精確投影與多項式填充證書",
      ok: check_bdd_and_certified_numeric(),
    },
    CheckResult::{
      name: "球面 S³：S¹ 兩次懸掛 HIT，meridian 端點、依賴消去與 hcomp",
      ok: check_sphere3(),
    },
    CheckResult::{
      name: "Jacobi 譜迭代：每次酉旋轉的符號區間包含證書與 Gershgorin 特徵區間",
      ok: check_Jacobi_interval(),
    },
    CheckResult::{
      name: "高階合一 elaborator：Miller pattern 求解隱含引數與 Nat motive，核心編譯至 DTerm",
      ok: check_hou_elaborator(),
    },
    CheckResult::{
      name: "參數化模組：函子實例化抽象整段宣告，import/open/alias/rename 與歧義拒絕",
      ok: check_module_system(),
    },
    CheckResult::{
      name: "立方體演算法：transport/filler、路徑代數、funext、subst 與 Kan box",
      ok: check_cubical_algorithms(),
    },
    CheckResult::{
      name: "計算性單值性：ua/pathToEquiv、uaβ、兩條往返同倫與 Glue 方塊",
      ok: check_univalence(),
    },
    CheckResult::{
      name: "精確代數完備化：Q 因式分解、實複根隔離、分裂域、去巢與任意精度 Jacobi",
      ok: check_qpoly_factor_complete() &&
      check_root_isolation() &&
      check_splitting_field() &&
      check_radical_denesting() &&
      check_Jacobi_arbitrary_precision(),
    },
    CheckResult::{
      name: "Schema 第九期：一等宇宙多態、透明算子正性、非均勻巢狀、原始互歸納、同時歸納遞迴與 HIT 移動維度",
      ok: check_level_polymorphic_declarations() &&
      check_type_operator_positivity_extraction() &&
      check_nested_iter_datatype() &&
      check_mutual_declaration_positivity() &&
      check_simultaneous_induction_recursion() &&
      check_hit_moving_dimension_lift(),
    },
    CheckResult::{
      name: "原始 DSystem 第九期：面下剪枝轉換、合意區域、受限修復與命題截斷",
      ok: check_dsystem_repair_phase9() && check_propositional_truncation(),
    },
    CheckResult::{
      name: "等價相干資料：improved counit、adjoint 三角形型別、fiber center、singleton 收縮與 GlueEquiv 引文保真",
      ok: check_adjoint_equivalence_and_fibers() &&
      check_glue_equiv_quote_preserves_syntax(),
    },
    CheckResult::{
      name: "維度代換與持久註冊：裸 DLine／語義封閉代換、bucket hash-cons、snapshot/merge/manifest",
      ok: check_dline_dimension_substitution() &&
      check_semantic_dimension_substitution() &&
      check_schema_registry_persistence(),
    },
    CheckResult::{
      name: "一般代數認證與 BDD DAG 原生操作：任意擴張投影／路徑、DAG eval/count/quantify 與 DPLL 總判定",
      ok: check_certified_algebraic_numeric() &&
      check_bdd_dag_native_operations(),
    },
    CheckResult::{
      name: "球面同倫代表元：懸掛函子、整數度數映射、單位環路、極交換 S³ 等價資料與 Hopf 連結數",
      ok: check_sphere_homotopy_representatives() && check_hopf_numeric(),
    },
    CheckResult::{
      name: "非 Miller HOU 片斷：重複變量、構造子 spine、相異 flex-flex 交集與受限同頭情形",
      ok: check_hou_phase9_extensions(),
    },
    CheckResult::{
      name: "模組分離編譯：抽象宣告、已編譯介面連結、前綴特化與增量快取",
      ok: check_module_compilation(),
    },
    CheckResult::{
      name: "一般 adjointification 與可收縮纖維：任意 quasi-inverse 的 lemIso 收縮與自動三角形",
      ok: check_general_adjointification_and_contractible_fibers(),
    },
    CheckResult::{
      name: "有界 Huet 高階合一搜尋：imitation、projection、任意 rigid spine、同頭置換剪枝與交易式預算",
      ok: check_hou_bounded_search(),
    },
    CheckResult::{
      name: "穩定模組二進位格式：版本標頭、checksum、全 DTerm/schema codec、解析驗證與連結",
      ok: check_module_binary_format(),
    },
    CheckResult::{
      name: "極端成本優化：BDD sifting/cache、watched-literal DPLL 與 Karatsuba 精確多項式乘法",
      ok: check_bdd_cost_optimizations() && check_qpoly_fast_arithmetic(),
    },
    CheckResult::{
      name: "核內整數與球面環路代表元：IntegerS、π₃ 商型別、懸掛環路生成元與代表元範式分類",
      ok: check_sphere_loop_representatives_internal(),
    },
    CheckResult::{
      name: "Schema 跨家族函子與同時 IR 編譯：DFunctorFamily 巢狀實例化、gather 驗證與 simultaneous→decode 位置編譯",
      ok: check_family_nested_functors() &&
      check_simultaneous_ir_compiled_decode() &&
      check_family_functor_persistence(),
    },
    CheckResult::{
      name: "原始 DSystem 面值合意與精確修復：雙端點合意面、exact repair、宿主不透明立方開盒與多項式立方填充",
      ok: check_face_agreement_and_exact_repair() &&
      check_dcube_open_box_filler() &&
      check_poly_cubes(),
    },
    CheckResult::{
      name: "lemIso 一般點驗證與圓環面點值合成：中性點與中性路徑兩端的收縮、Circle/Torus De Morgan 點合成計算",
      ok: check_lemiso_generic_points() && check_circle_torus_point_comp(),
    },
    CheckResult::{
      name: "註冊字節持久化與全域 hash-consing：CHREGBIN 往返與拒絕損壞、DTerm intern 子項共享且檢查/正規形不變",
      ok: check_schema_registry_byte_persistence() && check_dterm_hash_consing(),
    },
    CheckResult::{
      name: "精確代數第十一期：自適應 mod-p 因式圖樣剪枝、雙二次域去巢與判等、Jacobi 特徵值簇分離",
      ok: check_qpoly_mod_pattern_pruning() &&
      check_biquadratic_denesting() &&
      check_jacobi_cluster_separation(),
    },
    CheckResult::{
      name: "CDCL 子句學習與 BDD 精確最佳順序：1-UIP 斷言子句、Luby 重啟、全排列最優變量序恰勝啟發式",
      ok: check_cdcl_clause_learning() && check_bdd_optimal_order_exact(),
    },
    CheckResult::{
      name: "圓的 encode/decode：helix 萬有覆疊（base↦ℤ、loop↦ua succ）、subst 繞數、整數消去環路冪與代表元往返轉換",
      ok: check_circle_encode_decode(),
    },
    CheckResult::{
      name: "HOU 搜尋擴展與模組交錯遷移：深 imitation 與 identification、import/本地宣告交錯、v1→v2 遷移與 artifact store",
      ok: check_hou_search_extensions() &&
      check_module_interleaved_items() &&
      check_module_binary_versions_and_store(),
    },
    CheckResult::{
      name: "第十二期 BDD/SAT：子集 DP 精確最佳變量序（n≤12）、CDCL LBD 子句刪除與 RUP 可驗證證明",
      ok: check_bdd_optimal_order_dp() && check_cdcl_proof_and_reduction(),
    },
    CheckResult::{
      name: "第十二期 Schema：DFunctorSelfFamily 同規格非均勻遞迴（Bush）、真實 Self 參數型別、不透明算子正性宣告",
      ok: check_self_family_and_gather_shapes() &&
      check_positivity_declarations(),
    },
    CheckResult::{
      name: "第十二期同時 IR eliminator 編譯：互賴函數塊編為同一 base 家族的 eliminator 閉項（函數層級嚴格低於 base 層級）",
      ok: check_simultaneous_ir_eliminator_compilation(),
    },
    CheckResult::{
      name: "第十二期 DSystem：相關維度結構合意剪枝、exact repair 候選分支補入",
      ok: check_dsystem_structural_agreement_and_supplementation(),
    },
    CheckResult::{
      name: "第十二期轉換與路徑合成：Bool 變量 case-split 轉換、Circle/Torus 路徑值 comp（一般座標讀法保留繞數）",
      ok: check_case_split_conversion_and_path_comp(),
    },
    CheckResult::{
      name: "第十二期持久層與版本協商：抽象 artifact repository 原子提交與損壞復原、CHMODBIN v3/CHREGBIN v2 共享 DAG codec、peer 版本協商",
      ok: check_artifact_repository_and_dag_codec(),
    },
    CheckResult::{
      name: "第十二期精確代數：不可約證書 fast path（Eisenstein 平移）、三次與三二次塔體、Jacobi 迭代內簇感知精化",
      ok: check_qpoly_irreducibility_certificates() &&
      check_tower_fields() &&
      check_jacobi_cluster_aware_iteration(),
    },
    CheckResult::{
      name: "第十二期 HOU 語意：Miller pattern 主合一子（MGU）、無合一子與殘留約束三態",
      ok: check_hou_pattern_mgu_and_residuals(),
    },
    CheckResult::{
      name: "第十二期宿主立方分層外延檢查：面內部、對角與連接層探針與分層開盒驗證",
      ok: check_dcube_stratified_extensionality(),
    },
    CheckResult::{
      name: "第十二期球面代表元 3-胞與精確 Hopf：環路單位律連接旋轉 3-胞、Hopf 恆等式精確有理驗證",
      ok: check_loop_unit_3cells_and_hopf_exact(),
    },
    CheckResult::{
      name: "第十三期 Schema 正性：SelfFamily 同規格自嵌參數嚴格正性以最小不動點判定，Bush 通過、phantom 不出現、深層負性傳播",
      ok: check_self_family_positivity_fixpoint(),
    },
    CheckResult::{
      name: "第十三期同時 IR 巢狀 foreign IH：積／函數／積含 List 的 foreign bundle 經項層函子映射搬運並與同步語義一致",
      ok: check_simultaneous_ir_nested_foreign(),
    },
    CheckResult::{
      name: "第十三期面下轉換相關維度下降：在合取八變量 parity 面下僅沿實際提及的 i9 探測，i9 自由時正確拒絕",
      ok: check_conv_under_face_relevant_descent(),
    },
    CheckResult::{
      name: "第十三期 DSystem 最大相容補入：exact-restrict 後以相容圖最大團找出大小 3 最大集，勝過順序貪心的大小 2",
      ok: check_dsystem_maximum_completion(),
    },
    CheckResult::{
      name: "第十三期 Circle/Torus 非點值 comp：逐候選驗證座標帽，方塊在 tube 面轉換為原 loop、端點閉合且內部為點值",
      ok: check_circle_torus_square_comp(),
    },
    CheckResult::{
      name: "第十三期差異導引 Bool case-split：由兩側範形差異只切分真正不同的一個 Bool 變量，錯誤候選仍拒絕",
      ok: check_difference_guided_case_split(),
    },
    CheckResult::{
      name: "第十三期 intern DAG 與位元組共圖：同一 DAG 經 CHDAGBIN 往返並逐節點匯入，第二次匯入新增 0、畸形前向邊預先拒絕",
      ok: check_interned_dag_byte_sharing(),
    },
    CheckResult::{
      name: "第十三期聯合不可約證書：mod 2 的 [1,3] 與 mod 3 的 [2,2] 合併排除一次／二次因式，證書可攜帶且獨立重驗",
      ok: check_qpoly_degree_pattern_certificates(),
    },
    CheckResult::{
      name: "第十三期多二次塔體：至多四個平方類獨立生成元的 16 維 Q 體、基底對齊、逆元、精確判號、同域與加一根開方",
      ok: check_multiquadratic_tower(),
    },
    CheckResult::{
      name: "第十三期精確最佳 BDD 順序：增量 cofactor 子集 DP 擴至 n≤16，14 變量例 tried=114688，17 變量明示非精確",
      ok: check_bdd_optimal_order_dp_extended(),
    },
    CheckResult::{
      name: "第十三期 CDCL DRUP：學習／刪除步驟在演進子句庫上時序核驗，已刪子句不可再用，PHP(6,5) 與 PHP(7,6) 證明對帳",
      ok: check_cdcl_drup_proof_with_deletions(),
    },
    CheckResult::{
      name: "第十三期宿主立方分層 Tier D：逐軸深層連接探針揭穿舊層同形異值的立方，二維相等對共 105 探針",
      ok: check_dcube_stratified_tier_d(),
    },
    CheckResult::{
      name: "第十三期自適應 Jacobi：包絡停滯時切換精確特徵多項式 Sturm 分離，仍以目標寬度分開 ±1/4096",
      ok: check_jacobi_adaptive_exact_fallback(),
    },
    CheckResult::{
      name: "第十三期環路代數與球面分類：逆元、結合律與 sym 複合反同態 3-胞，閉代表式遞迴正規化至其次數典範字",
      ok: check_loop_inverse_assoc_and_classification(),
    },
    CheckResult::{
      name: "第十三期 HOU 殘差求解器：principal MGU 傳播與 transactional 迭代加深搜尋交錯續解整個殘留約束集",
      ok: check_hou_residual_solver(),
    },
    CheckResult::{
      name: "第十三期工件 manifest 完整性鏈：put/remove 以前條摘要連結成鏈，舊鏈頭、竄改與重播皆拒，銷毀 index 後以信任錨鏈頭復原",
      ok: check_artifact_manifest_integrity_chain(),
    },
    CheckResult::{
      name: "第十四期可攜正性見證證書：定義展開核驗 DPositivityWitness，雙重否定非嚴格正性與負性偽證均被拒絕",
      ok: check_phase14_positivity_witness_certificates(),
    },
    CheckResult::{
      name: "第十四期聯合 Σ 動機同時歸納遞迴：DFunctorSum 餘積函子與循環互遞迴小值域編譯至依賴核心並通過正規形核驗",
      ok: check_phase14_joint_simultaneous_ir_mutual(),
    },
    CheckResult::{
      name: "第十四期 DSystem 全體最大相容集與有限型別分案轉換：無順序偏倚列舉全部最大團，Fin3 閉居留元自動分案並排除無限 Nat",
      ok: check_phase14_dsystem_all_maxima_and_finite_case_split(),
    },
    CheckResult::{
      name: "第十四期語義圓周纏繞正規化與解耦環面 comp：loop·sym(loop) 語義歸零，T² 雙座標獨立選擇閉合方塊",
      ok: check_phase14_decoupled_torus_and_semantic_circle_norm(),
    },
    CheckResult::{
      name: "第十四期增量 DAG 差分與跨格式共圖封包：CHDAGDLT 僅傳新增節點並驗基底摘要，CHSHRBUN 跨模組與註冊表共享項表",
      ok: check_phase14_incremental_dag_delta_and_shared_bundle(),
    },
    CheckResult::{
      name: "第十四期 Hensel 提升有理因式分解：Swinnerton-Dyer 四次式與高次多項式經 p-adic 提升分解並攜無平方自由證書重驗",
      ok: check_phase14_qpoly_hensel_factor_and_certificates(),
    },
    CheckResult::{
      name: "第十四期一般實代數根式與六生成元多二次塔：∛2、∜5、∛(1+√2) 精確算術判號與 64 維 Q(√2,…,√13) 逆元核驗",
      ok: check_phase14_algebraic_radicals_and_rank6_multiquad(),
    },
    CheckResult::{
      name: "第十四期 Hermitian 分塊降維與高重數特徵認證：精確特徵多項式無平方分解結合 Sturm 根計數認證重數 [2,1,1]",
      ok: check_phase14_jacobi_block_deflation_and_multiplicity(),
    },
    CheckResult::{
      name: "第十四期 BDD 下界剪枝與 CDCL DRAT／DRUP 精簡：18 變量交錯公式剪枝壓縮，八子句純 RAT 步驟核驗與後向刪除精簡",
      ok: check_phase14_bdd_bnb_and_cdcl_drat(),
    },
    CheckResult::{
      name: "第十四期高維宿主立方 P¹(F₈) 覆蓋陣列探測：729 列三階正交覆蓋陣列揭穿 5 維三軸耦合不等價立方",
      ok: check_phase14_dcube_orthogonal_array_covering(),
    },
    CheckResult::{
      name: "第十四期 Eckmann–Hilton 交換 3-胞與 Mac Lane 五邊形 4-胞：Ω²(S²) 二階環路交換同倫與四重結合兩路徑相干連通",
      ok: check_phase14_eckmann_hilton_and_pentagon_coherence(),
    },
    CheckResult::{
      name: "第十四期圓周內部截面族與單值 Hopf 不變量：中性整數 encode(decode(n))=n 截面，S²→Type₀ Hopf 纖維化算出次數 0,1,-1,2",
      ok: check_phase14_internal_circle_sect_and_hopf_invariant(),
    },
    CheckResult::{
      name: "第十四期跨約束回溯 HOU 與完備正規形枚舉：非 pattern 雙約束回溯避開衝突投影，有界窮盡枚舉全部正規形合一子",
      ok: check_phase14_hou_backtracking_and_enumeration(),
    },
    CheckResult::{
      name: "第十四期 TLV 前向相容封裝與鑑別式 CAS 增量同步：未知非關鍵區段安全略過、關鍵區段拒絕，MAC 鏈防偽與增量同步僅傳缺頁",
      ok: check_phase14_tlv_envelope_cas_and_incremental_sync(),
    },
    CheckResult::{
      name: "第十五期對稱軌道 BDD 最優序與連通分量分解：19 變量軌道剪枝精確最佳化，28 變量四分量加性下界精確分解並誠實拒絕 22 變量單鏈",
      ok: check_phase15_bdd_symmetry_orbit_and_decomposed_optimal(),
    },
    CheckResult::{
      name: "第十五期 CDCL LRAT 索引證明精煉與零搜尋核驗：PHP(6,5) 與八子句 RAT 編譯為 CHLRATBN v1，錯序提示與重用已刪子句皆拒",
      ok: check_phase15_cdcl_lrat_elaboration_and_binary_codec(),
    },
    CheckResult::{
      name: "第十五期四階 PHF 覆蓋陣列與立方 Yoneda 外延審計：10 維四軸耦合偽立方揭穿、預層自然性檢驗與 24 維 CheckedDCube 單探針判等",
      ok: check_phase15_dcube_strength4_phf_and_yoneda_audit(),
    },
    CheckResult::{
      name: "第十五期全滿單射雙向一般性核驗與圓基本群同構：開放反射變數認證 Ω¹(S¹)≃ℤ、萬有覆疊與 π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ，偽 refl 逆元皆拒",
      ok: check_phase15_bidirectional_bijectivity_and_pi1_circle(),
    },
    CheckResult::{
      name: "第十五期多態懸掛與環路—懸掛伴隨雙向等價：SuspS(BoolS)≃S¹、無基點餘錐與開放帶點脈絡 Map*(SuspS A,B)≃Map*(A,ΩB)",
      ok: check_phase15_suspension_and_loop_suspension_adjunction(),
    },
    CheckResult::{
      name: "第十五期一般 Freudenthal 懸掛定理與楔連通延拓：開放 0-連通脈絡認證 ‖Ω¹(SuspS A)‖₀≃1（含 π₁(S²)≃1、π₁(S³)≃1）、S¹∨S¹→S¹×S¹ 延拓與 Hopf 往返",
      ok: check_phase15_freudenthal_suspension_and_wedge_connectivity(),
    },
    CheckResult::{
      name: "第十六期大宇宙累積同時 IR、Dybjer–Setzer 開放同時 IR 與語義容器正性憑證：跨宇宙聯合動機編譯、多解碼器開放規約與反循環容器同構核驗",
      ok: check_phase16_schema_large_open_positivity(),
    },
    CheckResult::{
      name: "第十六期 DSATUR 著色上界最大團修復與高維 0~1 黏合圓／環面開盒合成：飽和度上界剪枝、二維圓與環面黏合方塊轉換及二上循環纏繞阻礙拒絕",
      ok: check_phase16_dsatur_and_glued_cubical_comp(),
    },
    CheckResult::{
      name: "第十六期標準 SHA-256/512、RFC 8032 Pure-Ed25519 非對稱封緘與崩潰一致 WAL 日誌：NIST/RFC 向量逐位核驗、CHARTSIG 防偽與 CHWALJRN 斷尾回滾恢復",
      ok: check_phase16_crypto_ed25519_and_wal(),
    },
    CheckResult::{
      name: "第十六期精確有理 LLL 格約化、Van Hoeij 跡格因式重組與 Q̄⊂ℂ Rouché 圓盤代數閉包：八次 Swinnerton-Dyer 因式重組與非實複代數根算術及韋達恆等式",
      ok: check_lll_lattice_and_van_hoeij_factor() &&
      check_complex_algebraic_closure_rouche(),
    },
    CheckResult::{
      name: "第十六期纖維化環路序列等價、開放變量 Hopf–Freudenthal 收縮與五維 Stasheff K₅ 相干胞：開放脈絡 ∂_Hopf(σ_{S²}(p))≡p、π₂(S²) 分裂收縮 ℤ 與 K₅ 南北半球五維填充",
      ok: check_phase16_sphere_homotopy_and_k5(),
    },
    CheckResult::{
      name: "第十六期 Huet 延遲 flex-flex 約束圖、拉取式惰性合一串流、模組 DAG 介面雜湊重連結與三方倉庫合併：按需枚舉、不透明實作零重編譯重連結與 LCA 三方衝突判定",
      ok: check_phase16_hou_stream_and_module_merge(),
    },
    CheckResult::{
      name: "第十六期後 §四邊界收束·超越數認證層：e 與 π 的嚴格有理包絡、e≠p/q 的可複核否證證書（含篡改證書必拒）、P(e)≠0 的區間算術認證與預算不足時如實不宣稱",
      ok: check_transcendental_boundary_layer(),
    },
    CheckResult::{
      name: "第十七期 a 段模組執行期熱載入：介面雜湊不變的透明替換零重連結、介面變更精確列出陳舊依賴並交易式回滾、攜替換物件則提交、缺失／陳舊依賴在變動前拒絕且稽核日誌記錄每次嘗試",
      ok: check_module_runtime_hot_loading(),
    },
    CheckResult::{
      name: "第十七期 a 段崩潰一致寫入協定：內容 fsync 先於目錄 fsync 的耐久性模型，逐崩潰點驗證只會回到舊值或新值、絕不撕裂，且缺目錄 fsync 的寫入如實判定為未被承認",
      ok: check_durable_write_protocol(),
    },
    CheckResult::{
      name: "第十七期 b 段高階匹配：單側無元變數片斷的判定——相異變數脊柱給出唯一解、重複脊柱解經驗證、bound 不足如實回報不宣稱無解，且每個回傳解皆以 βη 轉換重新核驗",
      ok: check_hou_matching(),
    },
    CheckResult::{
      name: "第十七期 c 段 Stasheff 結合多面體 K_n（n ≥ 6）：Schröder 樹面格 f-向量、Euler 示性數為 1、二維面必為五邊形或正方形，且旋轉圖邊數與面格 f_1 互相對帳",
      ok: check_assoc_faces(),
    },
    CheckResult::{
      name: "第十八期 Blakers–Massey 與 Freudenthal：連接度間隙算術、由 bm_gap 推導穩定範圍、Hopf 纖維序列恰當序列代數，得出 π₃(S²) ≃ π₃(S³) 與 π₃(S³) ≃ π₂(S²)，並明示 π₂(S²) ≃ ℤ 的滿射半邊係 import 而非自證",
      ok: check_blakers_massey(),
    },
    CheckResult::{
      name: "第十九期 π₄(S³) ≃ ℤ/2ℤ：join 維度算術（S¹*S¹ ≃ S³）、Whitehead 積次數 [i₂,i₂] ∈ π₃(S²) 與第十八期 ψ 定義域一致、James 構造胞結構、Hopf LES 得 π₄(S³) ≃ π₄(S²)、ℤ/βℤ 循環群算術含退化情形，以及定理 6.17 判準 |β|=2",
      ok: check_brunerie_pi4_s3(),
    },
    CheckResult::{
      name: "第二十期 a 段 通用型別構造子：join、wedge、n-截斷、James 構造以 DHitSpec 宣告為真正的 HIT，並給出其遞迴原則與計算規則；join 維度算術 S^m*S^n ≃ S^(m+n+1)；如實列出仍然 import 的連接度引理",
      ok: check_homotopy_universal(),
    },
    CheckResult::{
      name: "第二十一期 下V頂點新最大公因數與泛消元基底（@gcd）：整數／F_p[x] 多項式／F_p 線性子空間（維數模律 dim(U∩W)+dim(U+W)=dim U+dim W）／ℤ-格 Hermite–Smith 範式與多生成元 Bézout 主理想泛 GCD",
      ok: @gcd.check_universal_gcd_laws(),
    },
    CheckResult::{
      name: "第二十一期 凝聚數學聯邦（凝聚高階結構×4、範疇×2、不變量賬本與已反駁猜想×1）：CondAnima（Milnor lim¹ 螺線管分離）、CondSolidModule（固態間隙與 p-液態次可加性）、CondSpectralSheaf（Steenrod–Adams Ext_A 證 2η=0、Serre、扭曲 AHSS 與 Koszul Tor）、CondAnalyticStack（Huber–熱帶—P¹—Topos 雙極棧）、CondCategory、CanonElimCategory 與 [Conj-1..4]",
      ok: @condensed.cond_check_federation_all(),
    },
    CheckResult::{
      name: "第二十一期 §4.4 任意次數 Liouville 代數無理數可複核否證證書、Schanuel ℚ-線性無關秩見證與 Berkowitz–CRT 無除法特徵多項式重構",
      ok: check_phase21_transcendence_and_crt_charpoly(),
    },
    CheckResult::{
      name: "第二十一期 §4.1/§4.2/§4.5 超限 Cantor 範式（<ε₀）與 Mahlo 宇宙反射、索引容器編譯、層黏合布林轉換（20變量 2 莖覆蓋）、核化最大團、F₂ 楔和方塊交換子阻礙、前沿割寬 ROBDD（連通 26 變量精確 SAT 計數）與 O(1) 泛點 24 維方塊具體化",
      ok: check_phase21_schema_dsystem_and_frontier_bdd(),
    },
    CheckResult::{
      name: "第二十一期 §4.6/§4.7/§4.3 任意 n 階路徑單例收縮、六維 Stasheff K₆ 相干胞、變端點 HIT（命題截斷與懸掛）、高階內層 λ 匹配、Goldfarb 二階合一丟番圖乘法編譯、RFC 8032 Ed25519 拜占庭法定人數 WAL 與 Tarjan 強連通分量 MVCC 原子熱替換",
      ok: check_phase21_homotopy_hou_and_bft_mvcc(),
    },
    CheckResult::{
      name: "構造性泛代數自主類型論：同餘閉包、商代數第一同構、瑪爾切夫一步可換（θ∘ψ=ψ∘θ=θ∨ψ）、德摩根區間吸收零塌縮 vs 點化零 Eckmann–Hilton 可換群、Zappa–Szép 中國剩餘分解與 Chu 同餘對偶",
      ok: {
        let rep = verify_absorbing_pointed_malcev_dichotomy()
        rep.interval_compatible_malcev_count == 0 &&
        rep.singleton_absorbing_malcev_ok &&
        rep.pointed_z6_eckmann_hilton_abelian_ok &&
        rep.z6_chinese_remainder_zappa_szep_ok &&
        rep.chu_congruence_duality_ok &&
        rep.lawvere_product_projections_ok
      },
    },
    CheckResult::{
      name: "仿射與雙德摩根立方體系、變長 Moore 自由路徑嚴格結合律、單值覆蓋瑪爾切夫繞數公式 w(p_Kan(a,b,c))=a-b+c 與 ∞-群胚四重內部公理刻畫",
      ok: {
        let aff = verify_affine_cubical_system()
        let bdm = verify_bide_morgan_cubical_duality()
        let fp = verify_free_path_associativity_and_kernel_bridge()
        let ig = verify_internal_infinity_groupoid_axioms()
        aff.affine_open_box_kan_fills_without_connections &&
        aff.ua_not_affine_coercion_flips_bool &&
        bdm.topos_coheyting_sieve_agreement_ok &&
        fp.strict_moore_associative_len &&
        fp.kan_associator_lhs_endpoint_conv &&
        fp.kan_associator_rhs_endpoint_conv &&
        ig.uniform_kan_open_box_1d_2d_3d_ok &&
        ig.kan_malcev_winding_formula_ok
      },
    },
    CheckResult::{
      name: "立方退化樹 SWAR 對帳（65,536 個 4-立方體）、5 維交錯面微分 ∂²=0 與 I³ Betti 譜 [1,0,0,0]、立方範式雙向修剪、Kripke–亞歷山德羅夫類型有效性結構、雙重否定核 j(x)=¬¬x 預層層化模板與 14 類範疇組合管線",
      ok: check_cubical_autonomy_all(),
    },
    CheckResult::{
      name: "Swan 常數範圍相等類型嚴格開放變數 J 歸約、自由路徑 Kan 纖維化、全體 65,536 個 4-立方體 Eilenberg–Zilber 分裂 [2,8,60,872,64594]、純 Kan 逆 3D 同倫、仿射雙向類型檢查與極性聚焦證明搜尋（5 -> 1）",
      ok: {
        let m = verify_work4_all_54_structures_and_interactions()
        m.swan_free_ez.ez_4cube_stratum_counts == [2, 8, 60, 872, 64594] &&
        m.swan_free_ez.ez_all_65536_unique_roundtrip_ok &&
        m.affine_bidir_focus.unfocused_interleavings_count == 5 &&
        m.affine_bidir_focus.focused_canonical_derivations_count == 1 &&
        m.all_54_structures_and_interactions_ok
      },
    },
    CheckResult::{
      name: "函子多項式容器米田雙射（9 居留元）、關係參數性自由定理、立方結構恆等原則 SIP（⊕ ↦ ↔）、S₃ 覆蓋空間伽羅瓦基本定理（[6,2,1] vs [1,1,1]）、T² vs S¹∨S¹ 交換子升騰與 RP² 整係數 2-撓率 [2]",
      ok: {
        let p = verify_functorial_polymorphism_and_sip_suite()
        let c = verify_covering_pushout_and_torus_suite()
        p.yoneda_vec3_to_vec2_inhabitant_count == 9 &&
        p.wadler_free_theorem_naturality_holds &&
        p.sip_bool_xor_to_xnor_ua_transport_ok &&
        c.s3_galois_normal_deck_orders == [6, 2, 1] &&
        c.s3_nonnormal_deck_orders == [1, 1, 1] &&
        c.rp2_h1_two_torsion_factors == [2]
      },
    },
    CheckResult::{
      name: "依賴類型高階合一動機重構、異質端點 coe 與開盒擬陣基底自動修補（繞數 +3）、自由群胚內部計算反射及全體 54 項高階立方結構 × 26 運算動詞 × 14 範疇組合交互圖譜",
      ok: {
        let r = verify_reconstruction_repair_and_reflection_suite()
        let m = verify_work4_all_54_structures_and_interactions()
        r.hou_implicit_motive_reconstructed &&
        r.open_box_missing_lid_repaired_winding == 3 &&
        m.verified_structure_count == 54 &&
        m.distinct_verbs_covered == 26 &&
        m.distinct_patterns_covered == 14 &&
        m.interaction_theorems_count == 14 &&
        check_work4_54_structures_26_verbs_14_patterns()
      },
    },
    CheckResult::{
      name: "Kalman 雙軌自由 De Morgan 區間（loop(i∧¬i) ≠ base）、CCHM 上纖維化格（∂I ≠ ⊤_F）、64-bit SWAR 面真值快徑、algebra/core Bareiss 與 Ozaki-II CRT 矩陣乘及閉合 Peano λ 項 NbE 正規化",
      ok: {
        let di = dim_var(0)
        let dj = dim_var(1)
        let tent = Dim::DAnd(di, Dim::DNeg(di))
        let cap = Dim::DOr(di, Dim::DNeg(di))
        let dm_ok = !dim_eq_demorgan(tent, Dim::DZero) &&
          !dim_eq_demorgan(cap, Dim::DOne) &&
          !dim_is_zero_demorgan(tent) &&
          !dim_is_one_demorgan(cap) &&
          dim_eq_demorgan(
            Dim::DNeg(Dim::DAnd(di, dj)),
            Dim::DOr(Dim::DNeg(di), Dim::DNeg(dj)),
          ) &&
          dim_eq_demorgan(Dim::DOr(di, Dim::DAnd(di, dj)), di) &&
          !@kernel.conv_at(
            0,
            1,
            @kernel.DValue::DVCircleTy,
            @kernel.circle_point(tent),
            @kernel.DValue::DVCirclePoint(Dim::DZero),
          )
        let f_bdry = face_or(face_var0(0), face_var1(0))
        let cchm_ok = cchm_face_is_bot(face_and(face_var0(0), face_var1(0))) &&
          !cchm_face_is_top(f_bdry) &&
          cchm_face_le(f_bdry, Face::FTop) &&
          !cchm_face_le(Face::FTop, f_bdry) &&
          cchm_face_eq(face_eq0(tent), f_bdry) &&
          face_bdd_canon_key(face_or(face_var0(0), face_var0(0))) ==
          face_bdd_canon_key(face_var0(0))
        let qm1 = @algebra.QMat::{
          n: 3,
          rows: [
            [@algebra.rat_int(2), @algebra.rat_int(-1), @algebra.rat_int(3)],
            [@algebra.rat_int(5), @algebra.rat_int(4), @algebra.rat_int(-2)],
            [@algebra.rat_int(1), @algebra.rat_int(3), @algebra.rat_int(7)],
          ],
        }
        let qm2 = @algebra.QMat::{
          n: 3,
          rows: [
            [@algebra.rat_make(1, 2), @algebra.rat_int(3), @algebra.rat_int(-1)],
            [@algebra.rat_int(2), @algebra.rat_make(-3, 4), @algebra.rat_int(5)],
            [@algebra.rat_int(-4), @algebra.rat_int(1), @algebra.rat_make(2, 3)],
          ],
        }
        let expected_det = @algebra.rat_int(
          2 * (28 + 6) + 1 * (35 + 2) + 3 * (15 - 4),
        )
        let qmat_ok = @algebra.rat_eq(@algebra.qmat_det(qm1), expected_det) &&
          @algebra.qmat_eq(
            @algebra.qmat_mul_ozaki2_crt(qm1, qm2),
            @algebra.qmat_mul(qm1, qm2),
          )
        let d_id_succ2 = DTerm::DApp(
          DTerm::DLam(
            DTerm::DNatTy,
            DTerm::DSucc(DTerm::DSucc(DTerm::DTVar(0))),
          ),
          DTerm::DSucc(DTerm::DNatZero),
        )
        dm_ok &&
        cchm_ok &&
        qmat_ok &&
        kernel_eval_closed_peano(d_id_succ2) == Some(3)
      },
    },
    CheckResult::{
      name: "T1–T4 泛消元／凝聚核心升級：Domich–Kannan–Trotter 模行列式有界 HNF、Bareiss 無分數行列式、構造性 Nöbeling 單模整數基底（C(S,ℤ) 自由性与 Z[S]^■ 對偶積）、Smith 餘核 coinvariants 自同態撓因子與 64-bit @swar Steenrod–Adams 極小分解（h₀,h₁,h₂,h₃ 八元數 Hopf 類與 η³=4ν 代數恆等式 Ext_A^{3,6}=1）",
      ok: {
        let mh = @gcd.zmat_from_int_rows([
          [4, 6, 10],
          [6, 15, 21],
          [2, 9, 13],
          [8, 12, 23],
        ])
        let hnf_ok = @gcd.zmat_hnf_modular(mh) == @gcd.zmat_hnf(mh) &&
          @gcd.zmat_det_bareiss(@gcd.zmat_from_int_rows([[2, 1], [0, 3]])) == 6N
        let nob_ok = @condensed.verify_nobeling_free_solid_duality(
            @condensed.compact_tower_cantor(4),
          ) &&
          @condensed.verify_nobeling_free_solid_duality(
            @condensed.compact_tower_padic(3, 3),
          )
        let (r0, rtor) = @condensed.coinvariants_zmat_endomorphism(
          @gcd.zmat_from_int_rows([[3]]),
        )
        let ad = @condensed.adams_ext_swar_frontier_report()
        hnf_ok &&
        nob_ok &&
        r0 == 0 &&
        rtor == [2N] &&
        ad.hopf_h0_ext11 == 1 &&
        ad.hopf_h1_ext12 == 1 &&
        ad.hopf_h2_ext14 == 1 &&
        ad.hopf_h3_ext18 == 1 &&
        ad.adem_non_pow2_vanish &&
        ad.eta_cubed_eq_4nu_ext36 == 1
      },
    },
    CheckResult::{
      name: "工作內容4全專題獨立實現：CCHM 膠水/Vogt 半伴隨/HS 重對齊/推出餘錐/Σ⊣Ω/T²≃S¹×S¹/CwF 代換/無歸約 NbE/連接對偶/3D 開放盒",
      ok: check_work4_stage2_dedicated_structures(),
    },
    CheckResult::{
      name: "七大前沿類型論支柱：多模態 2-範疇與 Fitch 鎖、Artin 膠合與幾何複合、16 通道 SWAR 雙上下文 QTT、立方路徑 QIIT、O(d) 記憶化雙向依值與雙向歸納",
      ok: {
        let r7 = verify_frontier_7pillars_cubical_suite()
        let mb = verify_memo_bidir_inductive_suite()
        r7.all_ok && mb.all_ok && r7.memo_unmemo_speedup_ratio >= 150
      },
    },
  ]
}

///|
pub fn print_report() -> Bool {
  let results = run_all_checks()
  let mut passed = 0
  println("cubical-hermitian — 定理登記表")
  for i in 0..<results.length() {
    let r = results[i]
    if r.ok {
      passed = passed + 1
      println("[PASS] \{r.name}")
    } else {
      println("[FAIL] \{r.name}")
    }
  }
  println("passed \{passed}/\{results.length()}")
  passed == results.length()
}
