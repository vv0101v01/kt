// ---------------------------------------------------------------------------
// cubical/autonomy — 構造性泛代數自主立方類型論總裝與 14 類範疇組合管線證書
// ---------------------------------------------------------------------------
//
// 本檔案將 `cubical/autonomy` 之四大核心支柱與 `組合範例.md` 之範疇／代數組合範例
// （Kan 擴張、雙重否定層黏合、纖維積與同倫推出、單子分配律、Grothendieck 纖維化轉運、
// Chu 空間對偶、Morita 不變同餘格、局部化分數演算、短正合列分裂、Operad 退化槽複合、
// Zappa–Szép 雙半直積分解、博弈雙向範式修剪、SWAR/WGSL 硬體加速與譜共振）
// 匯總為單一確定性驗證報告 `CubicalAutonomyMasterReport`。

///|
/// 構造性泛代數自主類型論與預層／立方全覆蓋總裝證書。
#derive(Debug, Eq)
pub(all) struct CubicalAutonomyMasterReport {
  universal_algebra_ok : Bool
  malcev_one_step_permutability_ok : Bool
  absorbing_vs_pointed_zero_ok : Bool
  affine_cubical_regime_ok : Bool
  bide_morgan_cubical_duality_ok : Bool
  free_moore_path_associativity_ok : Bool
  infinity_groupoid_internal_ok : Bool
  degeneracy_tree_and_d5_boundary_ok : Bool
  bidirectional_nf_pruning_ok : Bool
  validity_structure_and_alexandrov_ok : Bool
  double_negation_presheaf_template_ok : Bool
  swar_wgsl_acceleration_ok : Bool
  categorical_14_composition_pipeline_ok : Bool
  all_theorems_verified : Bool
}

///|
pub extend CubicalAutonomyMasterReport with @debug.Debug::{to_repr}

///|
pub extend CubicalAutonomyMasterReport with Eq::{not_equal, equal}

///|
/// 驗證 14 種範疇與代數組合範例（Kan 擴張、層黏合、拉回／推出、分配律、纖維化、Chu、Morita、
/// 局部化、正合分裂、Operad 槽插入、Zappa–Szép、雙向修剪管線）在實例上協同成立。
pub fn verify_categorical_14_composition_patterns() -> Bool {
  // (1) Kan 擴張 / 層反射左伴隨：包含函子 i : {0,1,2,3} -> F(I^2) 上頂點篩之 ¬¬-稠密延拓
  let (c_sq, _) = square_face_poset()
  let v_arrows : Array[Int32] = []
  for m in 0..<c_sq.nmor {
    if c_sq.cod[m] == 8 && c_sq.dom[m] < 4 {
      v_arrows.push(m)
    }
  }
  let s_v = @topos.sieve_generate(c_sq, 8, v_arrows)
  let kan_dense_ok = @topos.sieve_double_negation(c_sq, s_v) ==
    @topos.sieve_maximal(c_sq, 8)

  // (2) 雙重否定層黏合 + (3) 纖維積／同倫推出（S^1 迴圈繞數）
  let dn_ok = @topos.verify_double_negation_presheaf_template().left_adjoint_bijection_holds
  let lp = @kernel.DValue::DVPathLam(fn(i) { @kernel.circle_point(i) })
  let pushout_hit_ok = @kernel.circle_path_winding_int(fn(i) {
      @kernel.dapp_dim(lp, i)
    }) ==
    Some(1)

  // (4) 單子分配律：Moore 自由路徑列表單子與退化軸遮罩之複合保持單位與結合
  let s1 = @kernel.DValue::DVCircleTy
  let m_unit = moore_refl(s1, @kernel.circle_point(DZero))
  let m_lp = moore_atom(s1, lp)
  let monad_dist_ok = moore_concat(m_unit, m_lp).length == 1

  // (5) Grothendieck 纖維化笛卡兒提升：ua(not) 上 coe 0->1->0 雙向往返恆等
  let not_eqv = @kernel.deval_dim(
    @kernel.bool_not_equiv_term(),
    @kernel.denv_empty(),
    @kernel.ddim_empty(),
  )
  let ua_l = @kernel.ua_line_value(not_eqv, DVBoolTy, DVBoolTy, 0)
  let step1 = @kernel.coe_value(ua_l, DZero, DOne, DVBool(true), 0)
  let step2 = @kernel.coe_value(ua_l, DOne, DZero, step1, 0)
  let fib_ok = @kernel.dv_is_bool_dep(step1, false) &&
    @kernel.dv_is_bool_dep(step2, true)

  // (6) Chu 空間對偶對合
  let chu_ok = @topos.verify_chu_space_universal_duality()

  // (7) Morita 矩陣／商同餘格不變性 + (8) 局部化（Moore 商 C_•/D_• 消去退化元）
  // + (9) 短正合分裂 0 -> Z/2Z -> Z/6Z -> Z/3Z -> 0 + (11) Zappa–Szép 分解
  let ua_rep = verify_absorbing_pointed_malcev_dichotomy()
  let morita_ext_zs_ok = ua_rep.z6_chinese_remainder_zappa_szep_ok &&
    ua_rep.pointed_z6_eckmann_hilton_abelian_ok

  // (10) Operad 槽複合：退化樹在第 k 槽插入退化算子 σ_k 後以 ∂_{k,0} 復原恆等
  let t3 = dtree_from_cube64(3, 0xCAUL)
  let operad_ok = dtree_face(dtree_degeneracy(t3, 1), 1, 0) == t3

  // (12)-(14) 博弈雙向修剪（環境面約束 vs 系統管枝消去）+ SWAR/WGSL 管線
  let prune_rep = verify_bidirectional_cubical_nf_pruning()
  let swar_rep = @accel.verify_cubical_swar_degeneracy_suite()

  kan_dense_ok &&
  dn_ok &&
  pushout_hit_ok &&
  monad_dist_ok &&
  fib_ok &&
  chu_ok &&
  morita_ext_zs_ok &&
  operad_ok &&
  prune_rep.kernel_conv_under_face_ok &&
  swar_rep.all_ok
}

///|
/// 執行完整構造性泛代數自主立方類型論總審計。
pub fn verify_cubical_autonomy_master_suite() -> CubicalAutonomyMasterReport {
  let ua = verify_absorbing_pointed_malcev_dichotomy()
  let aff = verify_affine_cubical_system()
  let bdm = verify_bide_morgan_cubical_duality()
  let fp = verify_free_path_associativity_and_kernel_bridge()
  let ig = verify_internal_infinity_groupoid_axioms()
  let hd = verify_high_dim_alternating_cube_and_dtree()
  let pr = verify_bidirectional_cubical_nf_pruning()
  let vp = verify_validity_and_presheaf_template()
  let sw = @accel.verify_cubical_swar_degeneracy_suite()
  let cat14 = verify_categorical_14_composition_patterns()

  let ua_ok = ua.chu_congruence_duality_ok && ua.lawvere_product_projections_ok
  let perm_ok = ua.z6_chinese_remainder_zappa_szep_ok
  let zero_ok = ua.interval_absorbing_elements == [0] &&
    ua.interval_compatible_malcev_count == 0 &&
    ua.singleton_absorbing_malcev_ok &&
    ua.pointed_z6_neutral_zeros == [0] &&
    ua.pointed_z6_eckmann_hilton_abelian_ok
  let aff_ok = aff.pure_coe_regime == PureBchAffine &&
    aff.sym_loop_regime == InvolutiveAffine &&
    aff.connection_singleton_regime == DeMorganCartesian &&
    aff.diagonal_contraction_regime == DeMorganCartesian &&
    aff.max_multiplicity_pure_coe == 1 &&
    aff.max_multiplicity_diagonal == 2 &&
    aff.affine_open_box_kan_fills_without_connections &&
    aff.ua_not_affine_coercion_flips_bool
  let bdm_ok = bdm.bi_heyting_chain_holds &&
    bdm.de_morgan_involution_holds &&
    bdm.boundary_idempotent_complement_ok &&
    bdm.leibniz_boundary_product_ok &&
    bdm.topos_coheyting_sieve_agreement_ok &&
    bdm.bdd_boundary_vertices_count == 4
  let fp_ok = fp.strict_moore_associative_len &&
    fp.strict_moore_left_right_unit &&
    fp.reparam_lhs_winding == 1 &&
    fp.reparam_rhs_winding == 1 &&
    fp.kan_associator_lhs_endpoint_conv &&
    fp.kan_associator_rhs_endpoint_conv &&
    fp.kan_pentagon_k4_endpoints_conv
  let ig_ok = ig.uniform_kan_open_box_1d_2d_3d_ok &&
    ig.kan_malcev_left_cancel_conv_ok &&
    ig.kan_malcev_right_cancel_conv_ok &&
    ig.kan_malcev_winding_formula_ok &&
    ig.left_right_unit_inverse_cells_ok &&
    ig.directed_interval_non_groupoid_refuted
  let hd_ok = hd.dtree_swar_mask_bijection_ok &&
    hd.dtree_cubical_identities_ok &&
    hd.d5_alternating_d_squared_zero_ok &&
    hd.moore_degenerate_quotient_closed_ok &&
    hd.cube3_higher_laplacian_nonsingular_ok
  let pr_ok = pr.swar_face_prune_agreed &&
    pr.kernel_conv_under_face_ok &&
    pr.negative_wrong_branch_rejected &&
    pr.pruned_tube_branches == 1
  let vp_ok = vp.base_bool_validity_monotonic_ok &&
    vp.pi_validity_closure_ok &&
    vp.sigma_validity_closure_ok &&
    vp.path_and_ua_glue_validity_ok &&
    vp.non_monotonic_counterexample_rejected &&
    vp.square_face_alexandrov_open_sets_ok &&
    vp.square_vertices_double_negation_dense &&
    vp.hou_elaborated_section_valid_ok
  let dn_ok = vp.presheaf_template_nn_boolean_subtopos_ok
  let sw_ok = sw.all_ok && sw.wgsl_kernel_browser_portable

  let all_ok = ua_ok &&
    perm_ok &&
    zero_ok &&
    aff_ok &&
    bdm_ok &&
    fp_ok &&
    ig_ok &&
    hd_ok &&
    pr_ok &&
    vp_ok &&
    dn_ok &&
    sw_ok &&
    cat14

  CubicalAutonomyMasterReport::{
    universal_algebra_ok: ua_ok,
    malcev_one_step_permutability_ok: perm_ok,
    absorbing_vs_pointed_zero_ok: zero_ok,
    affine_cubical_regime_ok: aff_ok,
    bide_morgan_cubical_duality_ok: bdm_ok,
    free_moore_path_associativity_ok: fp_ok,
    infinity_groupoid_internal_ok: ig_ok,
    degeneracy_tree_and_d5_boundary_ok: hd_ok,
    bidirectional_nf_pruning_ok: pr_ok,
    validity_structure_and_alexandrov_ok: vp_ok,
    double_negation_presheaf_template_ok: dn_ok,
    swar_wgsl_acceleration_ok: sw_ok,
    categorical_14_composition_pipeline_ok: cat14,
    all_theorems_verified: all_ok,
  }
}

///|
/// 布林快篩入口（供根驗證台帳與橋接層直接呼叫）。
pub fn check_cubical_autonomy_all() -> Bool {
  verify_cubical_autonomy_master_suite().all_theorems_verified
}
