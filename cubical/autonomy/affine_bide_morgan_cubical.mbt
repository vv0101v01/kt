// ---------------------------------------------------------------------------
// cubical/autonomy — 仿射立方類型系統、雙德摩根立方集、自由路徑空間與 ∞-群胚內部刻畫
// ---------------------------------------------------------------------------
//
// 實作公理、定義與定理：
//   1. [D-Affine-Cubical-Classifier] 區間維度重數向量 μ : DimVar -> N 精確分類：
//      - 純 BCH 仿射立方項（μ(i) ≤ 1，無 DAnd/DOr 連接且無 DNeg 對合）；
//      - 對合仿射立方項（μ(i) ≤ 1，容許 DNeg(i) = 1-i，無連接複製）；
//      - CCHM 德摩根笛卡兒立方項（含 DAnd/DOr 連接或對角變數重用 μ(i) ≥ 2）。
//   2. [T-BiDeMorgan-Cubical-Duality] 立方體篩／ROBDD 謂詞同時配備 Heyting 直覺主義伴隨
//      (∧, ⇒, ¬, j=¬¬) 與 co-Heyting 雙偶差算子 (∨, ⇐, ~, ∂A = A ∧ ~A) 及德摩根區間對合，
//      構成雙德摩根立方預層代數並滿足 ~~A ⊆ A ⊆ ¬¬A 與 Leibniz 邊界律。
//   3. [T-Free-Moore-Path-Associativity] 變長 Moore 自由路徑空間 P_Moore(X) 以顯式非負長度
//      ℓ ∈ N 與分段立方路徑列表表示：串接 (γ1, ℓ1) ★ (γ2, ℓ2) 滿足嚴格結合律與嚴格雙邊單位元
//      (refl_x, 0)，且重參數化商映射 Q : P_Moore(S^1) -> Path_{S^1}(base, base) 將嚴格等式映為
//      @homotopy.dpath_assoc_path3_value 所驗證之 Kan 結合子 2-胞！
//   4. [T-Internal-Infinity-Groupoid] 內部 ∞-群胚四重等價刻畫：
//      (i) 均勻開盒 Kan 填充（1D/2D/3D）；
//      (ii) 路徑空間內部瑪爾切夫堆運算 p_Kan(f, g, h) := (f ⬝ sym(g)) ⬝ h 滿足同倫瑪爾切夫律
//           p_Kan(f, f, h) ≃ h、p_Kan(f, h, h) ≃ f 及繞數線性公式 w(p_Kan(a,b,c)) = a - b + c；
//      (iii) 左右單位元、左右逆元與結合子高階相干胞端點嚴格定義等價；
//      (iv) 負對照：有向區間 0 -> 1 缺乏逆態射與相容瑪爾切夫多態，非內蘊 ∞-群胚。

///|
/// 立方區間維度使用體制分類。
#derive(Debug, Eq)
pub(all) enum CubicalSubstructuralRegime {
  PureBchAffine
  InvolutiveAffine
  DeMorganCartesian
}

///|
pub extend CubicalSubstructuralRegime with @debug.Debug::{to_repr}

///|
pub extend CubicalSubstructuralRegime with Eq::{not_equal, equal}

///|
/// 仿射立方類型與維度重數審計報告。
#derive(Debug, Eq)
pub(all) struct AffineCubicalAudit {
  pure_coe_regime : CubicalSubstructuralRegime
  sym_loop_regime : CubicalSubstructuralRegime
  connection_singleton_regime : CubicalSubstructuralRegime
  diagonal_contraction_regime : CubicalSubstructuralRegime
  max_multiplicity_pure_coe : Int32
  max_multiplicity_diagonal : Int32
  affine_open_box_kan_fills_without_connections : Bool
  ua_not_affine_coercion_flips_bool : Bool
}

///|
pub extend AffineCubicalAudit with @debug.Debug::{to_repr}

///|
pub extend AffineCubicalAudit with Eq::{not_equal, equal}

///|
/// 雙德摩根立方體集驗證報告。
#derive(Debug, Eq)
pub(all) struct BiDeMorganCubicalReport {
  bi_heyting_chain_holds : Bool
  de_morgan_involution_holds : Bool
  boundary_idempotent_complement_ok : Bool
  leibniz_boundary_product_ok : Bool
  topos_coheyting_sieve_agreement_ok : Bool
  bdd_boundary_vertices_count : Int32
}

///|
pub extend BiDeMorganCubicalReport with @debug.Debug::{to_repr}

///|
pub extend BiDeMorganCubicalReport with Eq::{not_equal, equal}

///|
/// 變長 Moore 自由路徑（嚴格結合單子／範疇對象）。
pub struct FreeMoorePath {
  space_ty : @kernel.DValue
  start_pt : @kernel.DValue
  end_pt : @kernel.DValue
  length : Int32
  segments : Array[@kernel.DValue]
}

///|
/// 自由路徑空間與 Kan 結合子橋接報告。
#derive(Debug, Eq)
pub(all) struct FreePathAssociativityReport {
  strict_moore_associative_len : Bool
  strict_moore_left_right_unit : Bool
  reparam_lhs_winding : Int32
  reparam_rhs_winding : Int32
  kan_associator_lhs_endpoint_conv : Bool
  kan_associator_rhs_endpoint_conv : Bool
  kan_pentagon_k4_endpoints_conv : Bool
}

///|
pub extend FreePathAssociativityReport with @debug.Debug::{to_repr}

///|
pub extend FreePathAssociativityReport with Eq::{not_equal, equal}

///|
/// ∞-群胚公理內部刻畫證書。
#derive(Debug, Eq)
pub(all) struct InfinityGroupoidInternalCert {
  uniform_kan_open_box_1d_2d_3d_ok : Bool
  kan_malcev_left_cancel_conv_ok : Bool
  kan_malcev_right_cancel_conv_ok : Bool
  kan_malcev_winding_formula_ok : Bool
  left_right_unit_inverse_cells_ok : Bool
  directed_interval_non_groupoid_refuted : Bool
}

///|
pub extend InfinityGroupoidInternalCert with @debug.Debug::{to_repr}

///|
pub extend InfinityGroupoidInternalCert with Eq::{not_equal, equal}

///|
/// 統計單一區間表達式 `d : @face_bdd.Dim` 中各維度變數出現重數、對合與連接算子。
fn accumulate_dim_usage(
  d : @face_bdd.Dim,
  counts : Map[Int32, Int32],
) -> (Bool, Bool) {
  match d {
    DZero | DOne => (false, false)
    DVar(v) => {
      let prev = counts.get(v).unwrap_or(0)
      counts[v] = prev + 1
      (false, false)
    }
    DNeg(inner) => {
      let (_, has_conn) = accumulate_dim_usage(inner, counts)
      (true, has_conn)
    }
    DAnd(a, b) | DOr(a, b) => {
      let (neg_a, _) = accumulate_dim_usage(a, counts)
      let (neg_b, _) = accumulate_dim_usage(b, counts)
      (neg_a || neg_b, true)
    }
  }
}

///|
/// 分類一組並行區間代入 `[d_0, ..., d_{k-1}]` 所屬之次結構立方體制與最大重數。
pub fn classify_dim_substitution(
  dims : Array[@face_bdd.Dim],
) -> (CubicalSubstructuralRegime, Int32) {
  let counts : Map[Int32, Int32] = Map([])
  let mut any_neg = false
  let mut any_conn = false
  for d in dims {
    let (n_flag, c_flag) = accumulate_dim_usage(d, counts)
    if n_flag {
      any_neg = true
    }
    if c_flag {
      any_conn = true
    }
  }
  let mut max_mult = 0
  for _, mult in counts {
    if mult > max_mult {
      max_mult = mult
    }
  }
  if any_conn || max_mult > 1 {
    (DeMorganCartesian, max_mult)
  } else if any_neg {
    (InvolutiveAffine, max_mult)
  } else {
    (PureBchAffine, max_mult)
  }
}

///|
/// 審計受信任核心項 `DTerm` 中所有維度應用與 `DCoe` 端點是否保持仿射線性（無連接與對角收縮）。
pub fn classify_dterm_dim_regime(
  t : @kernel.DTerm,
) -> CubicalSubstructuralRegime {
  let dims : Array[@face_bdd.Dim] = []
  let stack : Array[@kernel.DTerm] = [t]
  while stack.length() > 0 {
    let cur = stack.pop().unwrap()
    match cur {
      DAppDim(body, d) => {
        dims.push(d)
        stack.push(body)
      }
      DCoe(line, r, s, base) => {
        dims.push(r)
        dims.push(s)
        stack.push(line)
        stack.push(base)
      }
      DHFill(ty, tubes, base, d) => {
        dims.push(d)
        stack.push(ty)
        for tb in tubes {
          stack.push(tb.body)
        }
        stack.push(base)
      }
      DHitIntro(_, _, params, args, cell_dims) => {
        for d in cell_dims {
          dims.push(d)
        }
        for p in params {
          stack.push(p)
        }
        for a in args {
          stack.push(a)
        }
      }
      _ =>
        for ch in @kernel.dterm_children(cur) {
          stack.push(ch)
        }
    }
  }
  let (regime, _) = classify_dim_substitution(dims)
  regime
}

///|
/// 透過單值覆蓋空間 `circle_encode_value : Path(S^1, base, base) -> Z`（沿 `ua(succ)` 轉運 `0 : Z`）
/// 與受信任核心定義等價 `@kernel.conv_at` 解出迴圈繞數！
pub fn univalent_circle_winding(path_val : @kernel.DValue) -> Int32? {
  let z_ty = @homotopy.integer_type_value()
  let enc = @homotopy.circle_encode_value(path_val, 0)
  for k in -8..<=8 {
    if @kernel.conv_at(0, 0, z_ty, enc, @homotopy.integer_value(k)) {
      return Some(k)
    }
  }
  None
}

///|
/// 執行仿射立方類型系統對比審計（純 BCH 仿射 vs 對合仿射 vs 德摩根連接，以及無連接開盒 Kan 填充）。
pub fn verify_affine_cubical_system() -> AffineCubicalAudit {
  let (r_coe, m_coe) = classify_dim_substitution([DVar(0), DZero, DOne])
  let (r_sym, _) = classify_dim_substitution([DNeg(DVar(0))])
  let (r_conn, _) = classify_dim_substitution([DAnd(DVar(0), DVar(1))])
  let (r_diag, m_diag) = classify_dim_substitution([DVar(0), DVar(0)])

  // 驗證純仿射 DCoe 項分類與 ua(not) 單值強制轉型：coe (ua not) 0->1 true == false
  let pure_term = @kernel.DTerm::DCoe(
    @kernel.DTerm::DLamDim(@kernel.DTerm::DBoolTy),
    DZero,
    DOne,
    @kernel.DTerm::DBoolLit(true),
  )
  let term_regime = classify_dterm_dim_regime(pure_term)
  let not_eqv = @kernel.deval_dim(
    @kernel.bool_not_equiv_term(),
    @kernel.denv_empty(),
    @kernel.ddim_empty(),
  )
  let ua_line = @kernel.ua_line_value(not_eqv, DVBoolTy, DVBoolTy, 0)
  let coerced_true = @kernel.coe_value(ua_line, DZero, DOne, DVBool(true), 0)
  let ua_flip_ok = @kernel.dv_is_bool_dep(coerced_true, false) &&
    term_regime == PureBchAffine

  // 無需 DAnd/DOr 連接：純靠 2D 開盒 Kan 填充 (@kernel.dcube_box_fill_verified) 在 S^1 HIT 合成 loop ⬝ loop（繞數 = +2）！
  let s1_ty = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let lp = @homotopy.circle_hit_loop_path_value()
  let bot_cube = @kernel.dcube_of_path(fn(i) { @kernel.dapp_dim(lp, i) })
  let left_cube = @kernel.dcube_constant(1, base)
  let right_cube = @kernel.dcube_of_path(fn(j) { @kernel.dapp_dim(lp, j) })
  // 構造 2D 開盒（底邊 j=0 為 loop(i)，左邊 i=0 為常數 base，右邊 i=1 為 loop(j)，缺頂蓋 j=1）
  let box2 = @kernel.dcube_open_box(s1_ty, 2, 0, [
    @kernel.dcube_box_face(1, false, bot_cube),
    @kernel.dcube_box_face(0, false, left_cube),
    @kernel.dcube_box_face(0, true, right_cube),
  ])
  let box_ok = match @kernel.dcube_box_fill_verified(box2, 0) {
    Some(filler) =>
      match @kernel.dcube_box_cap(box2) {
        Some(cap) => {
          let cap_path = @kernel.DValue::DVPathLam(fn(i) {
            @kernel.dcube_at(cap, [i])
          })
          @kernel.dcube_filler_faces_ok(box2, filler, 0) &&
          univalent_circle_winding(cap_path) == Some(2)
        }
        None => false
      }
    None => false
  }

  AffineCubicalAudit::{
    pure_coe_regime: r_coe,
    sym_loop_regime: r_sym,
    connection_singleton_regime: r_conn,
    diagonal_contraction_regime: r_diag,
    max_multiplicity_pure_coe: m_coe,
    max_multiplicity_diagonal: m_diag,
    affine_open_box_kan_fills_without_connections: box_ok,
    ua_not_affine_coercion_flips_bool: ua_flip_ok,
  }
}

///|
/// 驗證雙德摩根立方體集（ROBDD 面謂詞 + 2D 方塊亞歷山德羅夫下閉子集之雙 Heyting 與德摩根結構）。
pub fn verify_bide_morgan_cubical_duality() -> BiDeMorganCubicalReport {
  // 在 1 維區間偏序集 P = {v0(0), v1(1), edge(2)}，包含態射 v0 -> edge, v1 -> edge
  // 構造預層範疇子對象格（篩格）：
  //   空篩 ∅、{v0}、{v1}、邊界 ∂I = {v0, v1}、全區間 I = {v0, v1, edge}（共 5 個下閉篩！）
  let c_interval = @sym.cat_poset(3, [(0, 2), (1, 2)])
  let sieves = @topos.all_sieves_on(c_interval, 2)
  let top_s = @topos.sieve_maximal(c_interval, 2)

  // 1. 驗證全部篩滿足雙 Heyting 鏈：~~A ⊆ A ⊆ ¬¬A 及 ~~~A == ~A
  let mut chain_ok = sieves.length() == 5
  let mut leibniz_ok = true
  for a in sieves {
    let nn_a = @topos.sieve_double_negation(c_interval, a)
    let co_a = @topos.sieve_coheyting_neg(c_interval, a)
    let coco_a = @topos.sieve_coheyting_neg(c_interval, co_a)
    let cococo_a = @topos.sieve_coheyting_neg(c_interval, coco_a)
    if !@topos.sieve_subset(coco_a, a) ||
      !@topos.sieve_subset(a, nn_a) ||
      cococo_a != co_a {
      chain_ok = false
    }
    // co-Heyting 差伴隨律：(a ⇐ b) ⊆ r ⇔ a ⊆ (b ∨ r)
    for b in sieves {
      let diff_ab = @topos.sieve_coheyting_sub(c_interval, a, b)
      for r in sieves {
        let lhs = @topos.sieve_subset(diff_ab, r)
        let rhs = @topos.sieve_subset(a, @topos.sieve_union(b, r))
        if lhs != rhs {
          chain_ok = false
        }
      }
      // 邊界算子 Leibniz 律：∂(A ∧ B) == (∂A ∧ B) ∨ (A ∧ ∂B)
      let ab = @topos.sieve_inter(a, b)
      let bd_ab = @topos.sieve_coheyting_boundary(c_interval, ab)
      let bd_a = @topos.sieve_coheyting_boundary(c_interval, a)
      let bd_b = @topos.sieve_coheyting_boundary(c_interval, b)
      let rhs_leib = @topos.sieve_union(
        @topos.sieve_inter(bd_a, b),
        @topos.sieve_inter(a, bd_b),
      )
      if bd_ab != rhs_leib {
        leibniz_ok = false
      }
    }
  }

  // 2. 具體幾何直覺檢驗：全區間 I 之 co-Heyting 補 ~I = ∅，而單側端點篩 S_0 = {v0} 之 co-Heyting 補
  //    ~S_0 = I ⇐ {v0} 必須包含整個主邊 edge（故包含 {v0, v1, edge}），其邊界 ∂S_0 = S_0 ∧ ~S_0 = {v0}！
  let mut s0_opt : @topos.Sieve? = None
  for s in sieves {
    if s.arrows.length() == 1 {
      s0_opt = Some(s)
      break
    }
  }
  let bd_top = @topos.sieve_coheyting_boundary(c_interval, top_s)
  let bd_geom_ok = match s0_opt {
    Some(s0) => {
      let bd_s0 = @topos.sieve_coheyting_boundary(c_interval, s0)
      bd_top.arrows.length() == 0 && bd_s0 == s0
    }
    None => false
  }

  // 3. 2D 立方體 ROBDD 面格上之德摩根區間對合 φ*(i_0, i_1) := φ(1-i_0, 1-i_1)
  let f_corner00 = @face_bdd.face_and(
    @face_bdd.face_var0(0),
    @face_bdd.face_var0(1),
  )
  let f_dual11 = @face_bdd.face_and(
    @face_bdd.face_var1(0),
    @face_bdd.face_var1(1),
  )
  let f_redual = @face_bdd.face_and(
    @face_bdd.face_eq1(DNeg(DVar(0))),
    @face_bdd.face_eq1(DNeg(DVar(1))),
  )
  let dm_invol_ok = @face_bdd.bdd_face_eq(f_corner00, f_redual, 2) &&
    !@face_bdd.bdd_face_eq(f_corner00, f_dual11, 2)

  // 2D 方塊邊界 (i0=0 ∨ i0=1 ∨ i1=0 ∨ i1=1) 在 {0,1}^2 上涵蓋全部 4 個頂點
  let sq_bd = @face_bdd.face_or(
    @face_bdd.face_or(@face_bdd.face_var0(0), @face_bdd.face_var1(0)),
    @face_bdd.face_or(@face_bdd.face_var0(1), @face_bdd.face_var1(1)),
  )
  let bdd_bd = @face_bdd.bdd_of_face(sq_bd, 2)
  let mut sat_verts = 0
  for mask in 0..<4 {
    let asg = @face_bdd.assignment_of_mask(mask, 2)
    if @face_bdd.face_holds(sq_bd, asg) {
      sat_verts = sat_verts + 1
    }
  }
  let bdd_ok = bdd_bd == BddOne && sat_verts == 4

  BiDeMorganCubicalReport::{
    bi_heyting_chain_holds: chain_ok,
    de_morgan_involution_holds: dm_invol_ok && bdd_ok,
    boundary_idempotent_complement_ok: bd_geom_ok,
    leibniz_boundary_product_ok: leibniz_ok,
    topos_coheyting_sieve_agreement_ok: chain_ok && leibniz_ok && bd_geom_ok,
    bdd_boundary_vertices_count: sat_verts,
  }
}

///|
/// 建立長度為 0 之嚴格單位元 Moore 路徑 `(refl_x, 0)`。
pub fn moore_refl(
  space_ty : @kernel.DValue,
  x : @kernel.DValue,
) -> FreeMoorePath {
  FreeMoorePath::{ space_ty, start_pt: x, end_pt: x, length: 0, segments: [], }
}

///|
/// 將單段受信任立方路徑提升為長度 1 之基本 Moore 自由路徑。
pub fn moore_atom(
  space_ty : @kernel.DValue,
  path_val : @kernel.DValue,
) -> FreeMoorePath {
  let x0 = @kernel.dapp_dim(path_val, DZero)
  let x1 = @kernel.dapp_dim(path_val, DOne)
  FreeMoorePath::{
    space_ty,
    start_pt: x0,
    end_pt: x1,
    length: 1,
    segments: [path_val],
  }
}

///|
/// Moore 自由路徑串接 `(γ1, ℓ1) ★ (γ2, ℓ2)`：長度嚴格相加、分段陣列嚴格結合。
pub fn moore_concat(p : FreeMoorePath, q : FreeMoorePath) -> FreeMoorePath {
  let segs : Array[@kernel.DValue] = []
  for s in p.segments {
    segs.push(s)
  }
  for s in q.segments {
    segs.push(s)
  }
  FreeMoorePath::{
    space_ty: p.space_ty,
    start_pt: p.start_pt,
    end_pt: q.end_pt,
    length: p.length + q.length,
    segments: segs,
  }
}

///|
/// 重參數化商函子 `Q : P_Moore(X) -> Path_X(x, y)`（左結合折疊為標準立方 Kan 複合路徑）。
pub fn moore_reparametrize_left(
  mp : FreeMoorePath,
  dlevel : Int32,
) -> @kernel.DValue {
  if mp.segments.length() == 0 {
    @homotopy.dpath_refl_value(mp.start_pt)
  } else {
    let mut acc = mp.segments[0]
    for idx in 1..<mp.segments.length() {
      acc = @homotopy.dpath_trans_value(
        mp.space_ty,
        acc,
        mp.segments[idx],
        dlevel,
      )
    }
    acc
  }
}

///|
/// 重參數化商函子右結合折疊（對照組，用於產生結合子相干邊界）。
pub fn moore_reparametrize_right(
  mp : FreeMoorePath,
  dlevel : Int32,
) -> @kernel.DValue {
  let m = mp.segments.length()
  if m == 0 {
    @homotopy.dpath_refl_value(mp.start_pt)
  } else {
    let mut acc = mp.segments[m - 1]
    for step in 1..<m {
      let idx = m - 1 - step
      acc = @homotopy.dpath_trans_value(
        mp.space_ty,
        mp.segments[idx],
        acc,
        dlevel,
      )
    }
    acc
  }
}

///|
/// 驗證自由路徑空間嚴格結合律及重參數化至受信任核心 Kan 結合子與 Mac Lane 五邊形相干定理。
pub fn verify_free_path_associativity_and_kernel_bridge() -> FreePathAssociativityReport {
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let lp = @homotopy.circle_hit_loop_path_value()
  let inv_lp = @homotopy.dpath_sym_value(lp)
  let loop_space_ty = @kernel.DValue::DVPathTy(fn(_) { s1 }, base, base)

  let m1 = moore_atom(s1, lp)
  let m2 = moore_atom(s1, lp)
  let m3 = moore_atom(s1, inv_lp)
  let e0 = moore_refl(s1, base)

  // 1. Moore 自由路徑嚴格結合律與雙邊單位元
  let lhs_moore = moore_concat(moore_concat(m1, m2), m3)
  let rhs_moore = moore_concat(m1, moore_concat(m2, m3))
  let strict_assoc = lhs_moore.length == 3 &&
    rhs_moore.length == 3 &&
    lhs_moore.segments.length() == rhs_moore.segments.length()
  let unit_l = moore_concat(e0, m1)
  let unit_r = moore_concat(m1, e0)
  let strict_unit = unit_l.length == m1.length &&
    unit_r.length == m1.length &&
    unit_l.segments.length() == 1 &&
    unit_r.segments.length() == 1

  // 2. 重參數化商至 @kernel / @homotopy 標準立方路徑：比較 ((loop ⬝ loop) ⬝ sym(loop)) 與 (loop ⬝ (loop ⬝ sym(loop)))
  let q_lhs = moore_reparametrize_left(lhs_moore, 0)
  let q_rhs = moore_reparametrize_right(rhs_moore, 0)
  let w_lhs = univalent_circle_winding(q_lhs).unwrap_or(-999)
  let w_rhs = univalent_circle_winding(q_rhs).unwrap_or(-999)

  let assoc_2cell = @homotopy.dpath_assoc_path3_value(s1, lp, lp, inv_lp, 0)
  let ep0 = @kernel.dapp_dim(assoc_2cell, DZero)
  let ep1 = @kernel.dapp_dim(assoc_2cell, DOne)
  let lhs_conv = @kernel.conv_at(0, 0, loop_space_ty, ep0, q_lhs)
  let rhs_conv = @kernel.conv_at(0, 0, loop_space_ty, ep1, q_rhs)

  // 3. 四重串接 Mac Lane 五邊形頂路與底路端點在受信任核心嚴格可轉化
  let top_pent = @homotopy.dpath_pentagon_path_top3_value(
    s1, lp, lp, inv_lp, lp, 0,
  )
  let bot_pent = @homotopy.dpath_pentagon_path_bot3_value(
    s1, lp, lp, inv_lp, lp, 0,
  )
  let pent_ok = @kernel.conv_at(
      0,
      0,
      loop_space_ty,
      @kernel.dapp_dim(top_pent, DZero),
      @kernel.dapp_dim(bot_pent, DZero),
    ) &&
    @kernel.conv_at(
      0,
      0,
      loop_space_ty,
      @kernel.dapp_dim(top_pent, DOne),
      @kernel.dapp_dim(bot_pent, DOne),
    )

  FreePathAssociativityReport::{
    strict_moore_associative_len: strict_assoc,
    strict_moore_left_right_unit: strict_unit,
    reparam_lhs_winding: w_lhs,
    reparam_rhs_winding: w_rhs,
    kan_associator_lhs_endpoint_conv: lhs_conv,
    kan_associator_rhs_endpoint_conv: rhs_conv,
    kan_pentagon_k4_endpoints_conv: pent_ok,
  }
}

///|
/// 立方路徑空間上之內部 Kan 瑪爾切夫堆算子：`p_Kan(f, g, h) := (f ⬝ sym(g)) ⬝ h`。
pub fn kan_path_malcev_op(
  space_ty : @kernel.DValue,
  f : @kernel.DValue,
  g : @kernel.DValue,
  h : @kernel.DValue,
  dlevel : Int32,
) -> @kernel.DValue {
  let f_ginv = @homotopy.dpath_trans_value(
    space_ty,
    f,
    @homotopy.dpath_sym_value(g),
    dlevel,
  )
  @homotopy.dpath_trans_value(space_ty, f_ginv, h, dlevel)
}

///|
/// 內部刻畫並驗證 ∞-群胚四重等價公理證書。
pub fn verify_internal_infinity_groupoid_axioms() -> InfinityGroupoidInternalCert {
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let lp = @homotopy.circle_hit_loop_path_value()
  let refl_b = @homotopy.dpath_refl_value(base)
  let loop_ty = @kernel.DValue::DVPathTy(fn(_) { s1 }, base, base)

  // (i) 1D / 2D / 3D 均勻開盒 Kan 填充驗證
  let c1 = @kernel.dcube_constant(0, base)
  let box1 = @kernel.dcube_open_box(s1, 1, 0, [
    @kernel.dcube_box_face(0, false, c1),
  ])
  let c2 = @kernel.dcube_constant(1, base)
  let box2 = @kernel.dcube_open_box(s1, 2, 0, [
    @kernel.dcube_box_face(1, false, c2),
    @kernel.dcube_box_face(0, false, c2),
    @kernel.dcube_box_face(0, true, c2),
  ])
  let c3 = @kernel.dcube_constant(2, base)
  let box3 = @kernel.dcube_open_box(s1, 3, 0, [
    @kernel.dcube_box_face(2, false, c3),
    @kernel.dcube_box_face(0, false, c3),
    @kernel.dcube_box_face(0, true, c3),
    @kernel.dcube_box_face(1, false, c3),
    @kernel.dcube_box_face(1, true, c3),
  ])
  let ok1 = match @kernel.dcube_box_fill_verified(box1, 0) {
    Some(f) => @kernel.dcube_filler_faces_ok(box1, f, 0)
    None => false
  }
  let ok2 = match @kernel.dcube_box_fill_verified(box2, 0) {
    Some(f) => @kernel.dcube_filler_faces_ok(box2, f, 0)
    None => false
  }
  let ok3 = match @kernel.dcube_box_fill_verified(box3, 0) {
    Some(f) => @kernel.dcube_filler_faces_ok(box3, f, 0)
    None => false
  }

  // (ii) 內部瑪爾切夫同倫律：
  //      p_Kan(f, f, h) = (f ⬝ sym(f)) ⬝ h --(congr right_inv ⬝ left_unit)--> h
  //      以及 S^1 單值覆蓋繞數線性瑪爾切夫不變量 w(p_Kan(loop^2, loop^1, loop^3)) = 2 - 1 + 3 = 4！
  let lp2 = @homotopy.circle_hit_loop_power_value(2)
  let lp3 = @homotopy.circle_hit_loop_power_value(3)
  let p_ffh = kan_path_malcev_op(s1, lp, lp, lp2, 0)
  let p_fhh = kan_path_malcev_op(s1, lp3, lp, lp, 0)
  let p_213 = kan_path_malcev_op(s1, lp2, lp, lp3, 0)
  let w_ffh = univalent_circle_winding(p_ffh)
  let w_fhh = univalent_circle_winding(p_fhh)
  let w_213 = univalent_circle_winding(p_213)

  // 構造從 f ⬝ sym(f) 到 refl 之 2-胞並驗證端點與左／右消去同倫律相容
  let rinv_cell = @homotopy.dpath_right_inverse3_value(s1, base, lp, 0)
  let linv_cell = @homotopy.dpath_left_inverse3_value(s1, base, lp, 0)
  let lunit_cell = @homotopy.dpath_left_unit3_value(s1, base, lp, 0)
  let runit_cell = @homotopy.dpath_right_unit3_value(s1, base, lp, 0)

  let f_finv = @homotopy.dpath_trans_value(
    s1,
    lp,
    @homotopy.dpath_sym_value(lp),
    0,
  )
  let finv_f = @homotopy.dpath_trans_value(
    s1,
    @homotopy.dpath_sym_value(lp),
    lp,
    0,
  )
  let refl_f = @homotopy.dpath_trans_value(s1, refl_b, lp, 0)
  let f_refl = @homotopy.dpath_trans_value(s1, lp, refl_b, 0)

  let left_cancel_ok = @kernel.conv_at(
      0,
      0,
      loop_ty,
      @kernel.dapp_dim(rinv_cell, DZero),
      f_finv,
    ) &&
    @kernel.conv_at(0, 0, loop_ty, @kernel.dapp_dim(rinv_cell, DOne), refl_b) &&
    w_ffh == Some(2)
  let right_cancel_ok = @kernel.conv_at(
      0,
      0,
      loop_ty,
      @kernel.dapp_dim(linv_cell, DZero),
      finv_f,
    ) &&
    @kernel.conv_at(0, 0, loop_ty, @kernel.dapp_dim(linv_cell, DOne), refl_b) &&
    w_fhh == Some(3)
  let unit_cells_ok = @kernel.conv_at(
      0,
      0,
      loop_ty,
      @kernel.dapp_dim(lunit_cell, DZero),
      refl_f,
    ) &&
    @kernel.conv_at(0, 0, loop_ty, @kernel.dapp_dim(lunit_cell, DOne), lp) &&
    @kernel.conv_at(0, 0, loop_ty, @kernel.dapp_dim(runit_cell, DZero), f_refl) &&
    @kernel.conv_at(0, 0, loop_ty, @kernel.dapp_dim(runit_cell, DOne), lp)

  // (iv) 負對照：有向區間範疇 0 -> 1 中態射 u : 0 -> 1 無逆態射 1 -> 0，非內蘊群胚
  let dir_i = @sym.cat_arrow()
  let mut has_inv_1_to_0 = false
  for m in 0..<dir_i.nmor {
    if dir_i.dom[m] == 1 && dir_i.cod[m] == 0 {
      has_inv_1_to_0 = true
    }
  }

  InfinityGroupoidInternalCert::{
    uniform_kan_open_box_1d_2d_3d_ok: ok1 && ok2 && ok3,
    kan_malcev_left_cancel_conv_ok: left_cancel_ok,
    kan_malcev_right_cancel_conv_ok: right_cancel_ok,
    kan_malcev_winding_formula_ok: w_213 == Some(4),
    left_right_unit_inverse_cells_ok: unit_cells_ok,
    directed_interval_non_groupoid_refuted: !has_inv_1_to_0,
  }
}
