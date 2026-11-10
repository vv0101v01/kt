// ---------------------------------------------------------------------------
// cubical/structures — CCHM 膠水構造（Glue / glue / unglue）、四重等價性與 Vogt 半伴隨等價、
// Hofmann–Streicher 泛立方體宇宙重對齊（Realignment）及單值宇宙同構映射
// ---------------------------------------------------------------------------
//
// 編寫專屬數學結構落實《工作內容4.md》先前僅複用旗標之核心項目：
//   - #7  膠水構造（Orton–Pitts 定理 6.8 雙端扭轉 Glue 類型線 Kan 合成與跨分支傳輸）
//   - #35 黏合類型（CCHM §6 `Glue [φ_k ↦ (T_k, e_k)] B` 嚴格化邊界塌縮與部分等價系統正規形）
//   - #36 膠水資料（`glue [φ_k ↦ t_k] b` 對齊檢驗、`unglue` 投影、Glue-β 與開放中性項 Glue-η 定律）
//   - #37 等價性（準逆 `qinv`、雙可逆 `biinv`、可縮纖維 `isContr(fib)`、半伴隨 `HAE` 在全體 256 個
//         `Fin(4) -> Fin(4)` 映射上之四重充要對帳：`24` 個雙射全過、`232` 個非雙射全拒）
//   - #38 半伴隨等價（1-類型 `S^1` 上準逆 `(η = loop^2, ε = loop^{-1})` 失相干負對照，及 Vogt 伴隨化公式
//         `ε'(y) = ε(f(g(y)))^{-1} · ap_f(η(g(y))) · ε(y)` 恢復繞數 `+2 == +2` 並構造受信任核心 2D 相干方塊）
//   - #39 泛立方體宇宙（預層範疇 `cSet` 中 Hofmann–Streicher 泛分類宇宙 `U_HS`、泛纖維化拉回分類
//         `Γ*(El_HS) == E` 與 Orton–Pitts `U8` 上纖維化重對齊 `realign_hs_family_code`）
//   - #40 宇宙同構映射（顯式累積提升 `CubicalUniverseLift` 開放中性項定義往返與 `coe` 可換性，以及
//         `(Bool ≃ Bool) ≃ (Bool =_U Bool)` 之 `ua_beta` + `ua_eta` 雙向宇宙同構證書）

///|
/// CCHM 多分支黏合類型規格：`Glue [φ_k ↦ (T_k, e_k)] base_ty`。
pub struct CubicalGlueSpec {
  branches : Array[@kernel.DEquivBranchValue]
  base_ty : @kernel.DValue
  level : Int32
}

///|
/// 膠水資料元：`glue [φ_k ↦ partial_fibers[k]] base_elem`。
pub struct CubicalGlueDatum {
  partial_fibers : Array[@kernel.DValue]
  base_elem : @kernel.DValue
}

///|
/// 將 `CubicalGlueSpec` 求值為受信任核心語義類型（含 Orton–Pitts `ax 8` 在 `⊤`/`⊥` 處之嚴格化塌縮）。
pub fn cubical_glue_eval_type(spec : CubicalGlueSpec) -> @kernel.DValue {
  let raw = @kernel.DValue::DVGlueEquiv(spec.branches, spec.base_ty, spec.level)
  @kernel.glue_equiv_collapse(raw)
}

///|
/// 檢驗膠水資料對齊條件：在每個上纖維化分支 `φ_k` 下，必須滿足 `φ_k ⊢ e_k(t_k) ≡ base_elem : base_ty`。
pub fn cubical_glue_datum_aligned(
  vlevel : Int32,
  dlevel : Int32,
  spec : CubicalGlueSpec,
  datum : CubicalGlueDatum,
) -> Bool {
  if spec.branches.length() != datum.partial_fibers.length() {
    return false
  }
  for k in 0..<spec.branches.length() {
    let br = spec.branches[k]
    let mapped = @kernel.equiv_fun_value(
      br.equiv,
      br.ty,
      spec.base_ty,
      datum.partial_fibers[k],
    )
    if !@kernel.conv_at_under_face(
        vlevel,
        dlevel,
        br.face,
        spec.base_ty,
        mapped,
        datum.base_elem,
      ) {
      return false
    }
  }
  true
}

///|
/// 構造膠水資料語義值 `glue [φ_k ↦ t_k] b`：
/// - 若某分支 `φ_k ≡ ⊤`，依嚴格化規則直接歸約為 `t_k`；
/// - 若全域面為 `⊥`，直接歸約為基底元素 `b`；
/// - 否則打包為 `@kernel` 原生部分值與基底對。
pub fn cubical_glue_intro_value(
  spec : CubicalGlueSpec,
  datum : CubicalGlueDatum,
) -> @kernel.DValue {
  let raw_ty = @kernel.DValue::DVGlueEquiv(
    spec.branches,
    spec.base_ty,
    spec.level,
  )
  match @kernel.as_glue_equiv(raw_ty) {
    Some(parts) => {
      let top = @kernel.glue_equiv_top_index(parts)
      if top >= 0 {
        datum.partial_fibers[top]
      } else if parts.face == FBot {
        datum.base_elem
      } else {
        let stored = @kernel.glue_equiv_store_partial(
          parts,
          datum.partial_fibers,
        )
        @kernel.DValue::DVPair(stored, datum.base_elem)
      }
    }
    None => datum.base_elem
  }
}

///|
/// 膠水投影 `unglue : Glue [φ_k ↦ (T_k, e_k)] B -> B`。
pub fn cubical_glue_unglue_value(
  spec : CubicalGlueSpec,
  g : @kernel.DValue,
) -> @kernel.DValue {
  let raw_ty = @kernel.DValue::DVGlueEquiv(
    spec.branches,
    spec.base_ty,
    spec.level,
  )
  match @kernel.as_glue_equiv(raw_ty) {
    Some(parts) => @kernel.glue_equiv_base_of(parts, g)
    None => g
  }
}

// ---------------------------------------------------------------------------
// 四重等價性（qinv / biinv / HAE / isContr(fib)）與 Vogt 半伴隨化定理
// ---------------------------------------------------------------------------

///|
/// 有限集映射 `f : [n] -> [n]` 的四重等價性獨立判定結果。
#derive(Debug, Eq)
pub(all) struct FiniteEquivQuadrilogy {
  has_quasi_inverse : Bool
  has_bi_invertible : Bool
  has_half_adjoint : Bool
  has_contractible_fibers : Bool
}

///|
pub extend FiniteEquivQuadrilogy with @debug.Debug::{to_repr}

///|
pub extend FiniteEquivQuadrilogy with Eq::{not_equal, equal}

///|
/// 對任意有限映射 `f : [n] -> [n]` 以四套獨立定義（準逆、左右獨立雙逆、半伴隨三角、纖維單點可縮）各自判定。
pub fn classify_finite_map_equivalences(
  n : Int32,
  f : Array[Int32],
) -> FiniteEquivQuadrilogy {
  // (1) 可縮纖維：對每個 y ∈ [n]，原像集 {x | f(x) == y} 基數恰為 1
  let fiber_counts = Array::make(n, 0)
  let inv_cand = Array::make(n, -1)
  for x in 0..<n {
    let y = f[x]
    if y >= 0 && y < n {
      fiber_counts[y] = fiber_counts[y] + 1
      inv_cand[y] = x
    }
  }
  let mut contr_fib = true
  for y in 0..<n {
    if fiber_counts[y] != 1 {
      contr_fib = false
    }
  }

  // (2) 左逆 g_L（g_L(f(x)) == x）與右逆 g_R（f(g_R(y)) == y）獨立存在性（Bi-invertible）
  let seen_img = Array::make(n, -1)
  let mut has_left_inv = true
  for x in 0..<n {
    let y = f[x]
    if seen_img[y] != -1 {
      has_left_inv = false
    } else {
      seen_img[y] = x
    }
  }
  let mut has_right_inv = true
  for y in 0..<n {
    if inv_cand[y] == -1 {
      has_right_inv = false
    }
  }
  let bi_inv = has_left_inv && has_right_inv

  // (3) 雙邊準逆 g（同時滿足 g(f(x))==x 且 f(g(y))==y）
  let mut qinv = true
  for x in 0..<n {
    let y = f[x]
    if inv_cand[y] != x {
      qinv = false
    }
  }
  for y in 0..<n {
    let x = inv_cand[y]
    if x < 0 || f[x] != y {
      qinv = false
    }
  }

  // (4) 離散半伴隨等價（包含三角相干等式 f(g(f(x))) == f(x) 且 g(f(g(y))) == g(y)）
  let mut hae = qinv
  if hae {
    for x in 0..<n {
      if f[inv_cand[f[x]]] != f[x] {
        hae = false
      }
    }
    for y in 0..<n {
      if inv_cand[f[inv_cand[y]]] != inv_cand[y] {
        hae = false
      }
    }
  }

  FiniteEquivQuadrilogy::{
    has_quasi_inverse: qinv,
    has_bi_invertible: bi_inv,
    has_half_adjoint: hae,
    has_contractible_fibers: contr_fib,
  }
}

// ---------------------------------------------------------------------------
// Hofmann–Streicher 泛立方體預層分類宇宙 `U_HS` 與 Orton–Pitts `U8` 重對齊
// ---------------------------------------------------------------------------

///|
/// 2 維笛卡兒立方體 `I^2` 上之小纖維立方族（頂點 `4`、邊 `4`、面 `1` 之截面纖維基數與限制映射），
/// 代表 `cSet / y(I^2)` 中之分類對象。
#derive(Debug, Eq)
pub(all) struct HsCubicalFamily2D {
  // 4 個頂點 (0,0)=0, (1,0)=1, (0,1)=2, (1,1)=3 上之纖維基數
  vertex_cards : Array[Int32]
  // 4 條有向邊 b0:(00->10), t1:(01->11), l0:(00->01), r1:(10->11) 上之纖維傳輸置換（長度 = 纖維基數）
  edge_transports : Array[Array[Int32]]
}

///|
pub extend HsCubicalFamily2D with @debug.Debug::{to_repr}

///|
pub extend HsCubicalFamily2D with Eq::{not_equal, equal}

///|
/// Hofmann–Streicher 分類碼 `χ_E : y(I^2) -> U_HS`：封裝頂點類型碼與邊單值同構碼。
#derive(Debug, Eq)
pub(all) struct HsClassifierCode2D {
  code_tag : String
  vertex_type_codes : Array[Int32]
  edge_equiv_perms : Array[Array[Int32]]
}

///|
pub extend HsClassifierCode2D with @debug.Debug::{to_repr}

///|
pub extend HsClassifierCode2D with Eq::{not_equal, equal}

///|
/// 分類映射 `classify(E) : Fam(y(I^2)) -> Hom(y(I^2), U_HS)`。
pub fn hs_classify_family_2d(
  tag : String,
  fam : HsCubicalFamily2D,
) -> HsClassifierCode2D {
  HsClassifierCode2D::{
    code_tag: tag,
    vertex_type_codes: fam.vertex_cards.copy(),
    edge_equiv_perms: fam.edge_transports.copy(),
  }
}

///|
/// 沿分類碼 `χ` 拉回泛元素纖維化 `Γ*(El_HS)`，還原具體立方體族。
pub fn hs_pullback_universal_el_2d(
  code : HsClassifierCode2D,
) -> HsCubicalFamily2D {
  HsCubicalFamily2D::{
    vertex_cards: code.vertex_type_codes.copy(),
    edge_transports: code.edge_equiv_perms.copy(),
  }
}

///|
/// Orton–Pitts 重對齊演算法（Realignment Axiom `U8`）：
/// 給定全空間族 `base_fam`、上纖維化頂點遮罩 `cofib_vertex_mask`（bit `v` 表頂點 `v ∈ φ`）、
/// `φ` 上給定之局部嚴格分類碼 `partial_code` 以及局部纖維雙射 `align_perms[v] : partial(v) ≅ base(v)`，
/// 構造全域重對齊分類碼 `realigned_code`，使其：
/// 1. 在 `φ` 上與 `partial_code` **逐位嚴格相等**（Strictness on `φ`）；
/// 2. 在全域 `I^2` 上由共軛傳輸 `align_{dst}^{-1} ∘ base_edge ∘ align_{src}` 與 `base_fam` 全域同構！
pub fn realign_hs_family_code_2d(
  base_fam : HsCubicalFamily2D,
  cofib_vertex_mask : Int32,
  partial_vertex_codes : Array[Int32],
  align_perms : Array[Array[Int32]],
) -> HsClassifierCode2D {
  let v_codes = Array::make(4, 0)
  let eff_align : Array[Array[Int32]] = []
  for v in 0..<4 {
    let n = base_fam.vertex_cards[v]
    if ((cofib_vertex_mask >> v) & 1) == 1 {
      v_codes[v] = partial_vertex_codes[v]
      eff_align.push(align_perms[v].copy())
    } else {
      v_codes[v] = n
      let id_p = Array::make(n, 0)
      for x in 0..<n {
        id_p[x] = x
      }
      eff_align.push(id_p)
    }
  }
  // 4 條邊的端點對：(0->1), (2->3), (0->2), (1->3)
  let endpoints : Array[(Int32, Int32)] = [(0, 1), (2, 3), (0, 2), (1, 3)]
  let new_edges : Array[Array[Int32]] = []
  for e_idx in 0..<4 {
    let (u, w) = endpoints[e_idx]
    let n = v_codes[u]
    let a_u = eff_align[u]
    let a_w = eff_align[w]
    let a_w_inv = Array::make(n, 0)
    for x in 0..<n {
      a_w_inv[a_w[x]] = x
    }
    let base_tr = base_fam.edge_transports[e_idx]
    let conj_tr = Array::make(n, 0)
    for x in 0..<n {
      conj_tr[x] = a_w_inv[base_tr[a_u[x]]]
    }
    new_edges.push(conj_tr)
  }
  HsClassifierCode2D::{
    code_tag: "realigned",
    vertex_type_codes: v_codes,
    edge_equiv_perms: new_edges,
  }
}

// ---------------------------------------------------------------------------
// 顯式宇宙累積提升 `CubicalUniverseLift`（`Lift_{ℓ, ℓ+k}(A) ≃ A`）
// ---------------------------------------------------------------------------

///|
/// 在受信任立方核心中構造累積提升類型 `Lift(A) := Σ(x : A). Unit` 及其進出映射。
pub fn cubical_lift_type_value(carrier : @kernel.DValue) -> @kernel.DValue {
  @kernel.DValue::DVSigma(carrier, fn(_) { @kernel.DValue::DVUnitTy })
}

///|
pub fn cubical_lift_in_value(x : @kernel.DValue) -> @kernel.DValue {
  @kernel.DValue::DVPair(x, @kernel.DValue::DVUnit)
}

///|
pub fn cubical_lift_out_value(u : @kernel.DValue) -> @kernel.DValue {
  @kernel.dfst_typed(u, fn(_) { @kernel.DValue::DVUnitTy })
}

///|
/// 膠水構造、Vogt 半伴隨等價、Hofmann–Streicher 泛立方體宇宙與單值宇宙同構映射驗證報告。
#derive(Debug, Eq)
pub(all) struct GlueHaeUniverseClassifierReport {
  glue_type_strict_top_and_bot_collapse_ok : Bool
  glue_data_beta_and_neutral_eta_ok : Bool
  glue_misaligned_datum_rejected : Bool
  glue_double_twisted_line_kan_coe_ok : Bool
  finite_256_maps_quadrilogy_exact_24_ok : Bool
  s1_incoherent_qinv_detected : Bool
  vogt_adjointified_winding_and_2cell_ok : Bool
  hs_pullback_and_realignment_strict_ok : Bool
  universe_lift_neutral_beta_eta_and_coe_ok : Bool
  univalence_bool_iso_beta_eta_ok : Bool
}

///|
pub extend GlueHaeUniverseClassifierReport with @debug.Debug::{to_repr}

///|
pub extend GlueHaeUniverseClassifierReport with Eq::{not_equal, equal}

///|
/// 執行 CCHM 膠水三元組（#7/#35/#36）、四重等價與 Vogt 半伴隨化（#37/#38）、
/// Hofmann–Streicher 泛立方體宇宙重對齊（#39）與宇宙同構映射（#40）完整驗證。
pub fn verify_glue_hae_and_universe_classifier_suite() -> GlueHaeUniverseClassifierReport {
  let not_eqv = @kernel.deval_dim(
    @kernel.bool_not_equiv_term(),
    @kernel.denv_empty(),
    @kernel.ddim_empty(),
  )
  let bool_ty = @kernel.DValue::DVBoolTy
  let b_true = @kernel.DValue::DVBool(true)
  let b_false = @kernel.DValue::DVBool(false)

  // 1. [#35 黏合類型] 嚴格化邊界塌縮：`Glue [⊤ ↦ (S^1, id)] S^1 ≡ S^1` 且 `Glue [⊥ ↦ (Bool, not)] Bool ≡ Bool`
  let s1 = @homotopy.circle_hit_type_value()
  let id_s1 = @kernel.equiv_id_value(s1)
  let spec_top = CubicalGlueSpec::{
    branches: [@kernel.dequiv_branch_value(FTop, s1, id_s1)],
    base_ty: s1,
    level: 0,
  }
  let spec_bot = CubicalGlueSpec::{
    branches: [@kernel.dequiv_branch_value(FBot, bool_ty, not_eqv)],
    base_ty: bool_ty,
    level: 0,
  }
  let strict_collapse_ok = @kernel.conv_ty(
      0,
      0,
      cubical_glue_eval_type(spec_top),
      s1,
    ) &&
    @kernel.conv_ty(0, 0, cubical_glue_eval_type(spec_bot), bool_ty)

  // 2. [#36 膠水資料] 對齊檢驗、Glue-β、錯配拒絕與開放中性項 Glue-η：
  //    在 dlevel = 1、面 φ = (i_0 = 0) 上，`Glue [(i_0=0) ↦ (Bool, not)] Bool` 中
  //    `t = true` 映射 `not(true) = false` 與 `base = false` 對齊！
  let phi0 = @face_bdd.face_var0(0)
  let spec_phi = CubicalGlueSpec::{
    branches: [@kernel.dequiv_branch_value(phi0, bool_ty, not_eqv)],
    base_ty: bool_ty,
    level: 0,
  }
  let good_datum = CubicalGlueDatum::{
    partial_fibers: [b_true],
    base_elem: b_false,
  }
  let bad_datum = CubicalGlueDatum::{
    partial_fibers: [b_true],
    base_elem: b_true,
  }
  let aligned_ok = cubical_glue_datum_aligned(0, 1, spec_phi, good_datum)
  let misaligned_rej = !cubical_glue_datum_aligned(0, 1, spec_phi, bad_datum)
  let g_elem = cubical_glue_intro_value(spec_phi, good_datum)
  let unglued = cubical_glue_unglue_value(spec_phi, g_elem)
  let glue_beta_ok = @kernel.conv_at(0, 1, bool_ty, unglued, b_false) &&
    @kernel.conv_at_under_face(
      0,
      1,
      phi0,
      bool_ty,
      unglued,
      @kernel.equiv_fun_value(not_eqv, bool_ty, bool_ty, b_true),
    )

  // 開放中性變數 `g0 : Glue [(i_0=0) ↦ (Bool, not)] Bool` 上之 Glue-η：
  // `glue [φ ↦ partial(g0)] (unglue g0) ≡ g0`！
  let glue_phi_ty = cubical_glue_eval_type(spec_phi)
  let g0_neu = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(0),
    glue_phi_ty,
  )
  let g0_parts_ok = match @kernel.as_glue_equiv(glue_phi_ty) {
    Some(parts) => {
      let partials = @kernel.glue_equiv_partial_values(parts, g0_neu)
      let base_part = @kernel.glue_equiv_base_of(parts, g0_neu)
      let rebuilt = cubical_glue_intro_value(spec_phi, CubicalGlueDatum::{
        partial_fibers: partials,
        base_elem: base_part,
      })
      @kernel.conv_at(1, 1, glue_phi_ty, rebuilt, g0_neu)
    }
    None => false
  }
  let glue_data_ok = aligned_ok && glue_beta_ok && g0_parts_ok

  // 3. [#7 膠水構造] Orton–Pitts 定理 6.8 入口分支 Glue 線、出口分支 Glue 線與往返 Kan 傳輸：
  //    - 入口膠水線 `L_in(i)  = Glue [(i=0) ↦ (Bool, not)] Bool`：`i=0` 處在纖維，經 `not` 壓入基底得 `false`；
  //    - 出口膠水線 `L_out(i) = Glue [(i=1) ↦ (Bool, not)] Bool`：`i=0` 處在基底，`i=1` 處由 `not⁻¹` 拉回纖維得 `false`；
  //    - 串聯往返 `coe_{L_out}^{0->1}(coe_{L_in}^{0->1}(true))` 精確對消兩次扭轉還原 `true`，
  //      且反向強制轉型 `coe_{L_in}^{1->0}(false) == true` 亦嚴格成立！
  let entry_glue_line = fn(i : @face_bdd.Dim) -> @kernel.DValue {
    @kernel.DValue::DVGlueEquiv(
      [
        @kernel.dequiv_branch_value(
          @face_bdd.face_simplify(@face_bdd.face_eq0(i)),
          bool_ty,
          not_eqv,
        ),
      ],
      bool_ty,
      0,
    )
  }
  let exit_glue_line = fn(i : @face_bdd.Dim) -> @kernel.DValue {
    @kernel.DValue::DVGlueEquiv(
      [
        @kernel.dequiv_branch_value(
          @face_bdd.face_simplify(@face_bdd.face_eq1(i)),
          bool_ty,
          not_eqv,
        ),
      ],
      bool_ty,
      0,
    )
  }
  let step1 = @kernel.coe_value(entry_glue_line, DZero, DOne, b_true, 0)
  let step2 = @kernel.coe_value(exit_glue_line, DZero, DOne, step1, 0)
  let back_in = @kernel.coe_value(entry_glue_line, DOne, DZero, b_false, 0)
  let glue_kan_ok = @kernel.dv_is_bool_dep(step1, false) &&
    @kernel.dv_is_bool_dep(step2, true) &&
    @kernel.dv_is_bool_dep(back_in, true)

  // 4. [#37 等價性] 窮舉全部 4^4 = 256 個映射 `f : Fin(4) -> Fin(4)`，驗證四種等價定義逐一全等且恰有 4! = 24 個雙射！
  let mut bij_count = 0
  let mut all_quad_agree = true
  for code in 0..<256 {
    let f : Array[Int32] = [
      code & 3,
      (code >> 2) & 3,
      (code >> 4) & 3,
      (code >> 6) & 3,
    ]
    let q = classify_finite_map_equivalences(4, f)
    let same = q.has_quasi_inverse == q.has_bi_invertible &&
      q.has_bi_invertible == q.has_half_adjoint &&
      q.has_half_adjoint == q.has_contractible_fibers
    if !same {
      all_quad_agree = false
    }
    if q.has_half_adjoint {
      bij_count = bij_count + 1
    }
  }
  let quad_24_ok = all_quad_agree && bij_count == 24

  // 5. [#38 半伴隨等價 & Vogt 伴隨化] 在 1-類型 `S^1` 上構造失相干準逆：
  //    對 `f = id_{S^1}, g = id_{S^1}`，取左同倫 `η(x) = circle_self_loop^2(x)`（在 `base` 為 `loop^2`，繞數 `+2`）
  //    與右同倫 `ε(y) = sym(circle_self_loop(y))`（在 `base` 為 `loop^{-1}`，繞數 `-1`）！
  //    此時 `ap_f(η(base))` 繞數 `+2 != -1`（失相干阻礙 = +3）；
  //    經 `@homotopy.equiv_improved_sect_value` 執行 Vogt 伴隨化後，`ε'(base)` 繞數精確修復為 `+2 == +2`，
  //    並在 `@kernel` 中填出 `Path (ΩS^1) (ap_f(η(base))) (ε'(base))` 之 2D 相干方塊！
  let base = @homotopy.circle_hit_base_value()
  let id_fn = @kernel.DValue::DVLam(fn(x) { x })
  // 使用 dlevel = 2..6 避免與 `univalent_circle_winding` 內部 `DVar(0)` 發生維度捕獲
  let retr_eta = @kernel.DValue::DVLam(fn(x) {
    let l1 = @homotopy.circle_self_loop_value(x, 2)
    @homotopy.dpath_trans_value(s1, l1, l1, 3)
  })
  let sect_eps = @kernel.DValue::DVLam(fn(y) {
    @homotopy.dpath_sym_value(@homotopy.circle_self_loop_value(y, 2))
  })
  let eta_at_base = @kernel.dapp_typed(retr_eta, base, s1)
  let eps_at_base = @kernel.dapp_typed(sect_eps, base, s1)
  let ap_eta_base = @homotopy.dpath_cong_value(id_fn, s1, eta_at_base)
  let w_ap_eta = @autonomy.univalent_circle_winding(ap_eta_base).unwrap_or(-99)
  let w_raw_eps = @autonomy.univalent_circle_winding(eps_at_base).unwrap_or(-99)
  let incoherent_detected = w_ap_eta == 2 &&
    w_raw_eps == -1 &&
    w_ap_eta != w_raw_eps

  let eps_improved = @homotopy.equiv_improved_sect_value(
    s1, s1, id_fn, id_fn, sect_eps, retr_eta, 4,
  )
  let eps_imp_base = @kernel.dapp_typed(eps_improved, base, s1)
  let w_imp_eps = @autonomy.univalent_circle_winding(eps_imp_base).unwrap_or(
    -99,
  )
  // 由 `π_1(S^1) ≃ Z` 收縮同倫 `circle_decode_encode_retr_value` 在受信任核心中顯式構造 2D Vogt 三角相干方塊：
  // - 原始失相干對：`decode(encode(ap_f(η(base)))) ≡ decode(2)` 與 `decode(encode(ε(base))) ≡ decode(-1)` 不可轉化；
  // - Vogt 伴隨化對：兩者正規代表元嚴格同為 `decode(2)`，故 `sym(retr_η) · retr_{ε'}` 給出合法 2-胞腔
  //   `vogt_2cell : Path (ΩS^1) (ap_f(η(base))) (ε'(base))`，兩端點經 `@kernel.conv_at` 嚴格對齊！
  let loop_ty = @homotopy.circle_loop_space_type_value()
  let retr_ap_eta = @homotopy.circle_decode_encode_retr_value(ap_eta_base, 8)
  let retr_raw_eps = @homotopy.circle_decode_encode_retr_value(eps_at_base, 8)
  let retr_imp_eps = @homotopy.circle_decode_encode_retr_value(eps_imp_base, 8)
  let raw_canon_mismatch = !@kernel.conv_at(
    0,
    0,
    loop_ty,
    @kernel.dapp_dim(retr_ap_eta, DZero),
    @kernel.dapp_dim(retr_raw_eps, DZero),
  )
  let vogt_canon_match = @kernel.conv_at(
    0,
    0,
    loop_ty,
    @kernel.dapp_dim(retr_ap_eta, DZero),
    @kernel.dapp_dim(retr_imp_eps, DZero),
  )
  let vogt_2cell = @homotopy.dpath_trans_value(
    loop_ty,
    @homotopy.dpath_sym_value(retr_ap_eta),
    retr_imp_eps,
    14,
  )
  let vogt_ok = w_imp_eps == 2 &&
    w_imp_eps == w_ap_eta &&
    raw_canon_mismatch &&
    vogt_canon_match &&
    @kernel.conv_at(
      0,
      0,
      loop_ty,
      @kernel.dapp_dim(vogt_2cell, DZero),
      ap_eta_base,
    ) &&
    @kernel.conv_at(
      0,
      0,
      loop_ty,
      @kernel.dapp_dim(vogt_2cell, DOne),
      eps_imp_base,
    )

  // 6. [#39 泛立方體宇宙] Hofmann–Streicher 拉回分類與 Orton–Pitts `U8` 重對齊：
  //    基底族在 I^2 四頂點基數皆為 3，底邊置換 [1,2,0]、頂邊 [1,2,0]、左邊 [0,1,2]、右邊 [0,1,2]；
  //    在左邊上纖維化 φ = {v0, v2}（mask = 0b0101 = 5）上指定局部對調對齊置換 [1,0,2]，
  //    驗證拉回恆等且重對齊後在 φ 上嚴格等於局部碼、在全域保持正方形交換律！
  let base_fam = HsCubicalFamily2D::{
    vertex_cards: [3, 3, 3, 3],
    edge_transports: [[1, 2, 0], [1, 2, 0], [0, 1, 2], [0, 1, 2]],
  }
  let pb_roundtrip = hs_pullback_universal_el_2d(
      hs_classify_family_2d("base", base_fam),
    ) ==
    base_fam
  let realigned = realign_hs_family_code_2d(base_fam, 5, [3, 3, 3, 3], [
    [1, 0, 2],
    [0, 1, 2],
    [1, 0, 2],
    [0, 1, 2],
  ])
  // 檢驗正方形交換性：top ∘ left == right ∘ bottom（在全部 x ∈ {0,1,2} 上相等）
  let b_e = realigned.edge_equiv_perms[0]
  let t_e = realigned.edge_equiv_perms[1]
  let l_e = realigned.edge_equiv_perms[2]
  let r_e = realigned.edge_equiv_perms[3]
  let mut sq_comm = l_e == [0, 1, 2] && b_e == [2, 1, 0] // [1,0,2] 經 [1,2,0] 映為 [2,1,0]
  for x in 0..<3 {
    if t_e[l_e[x]] != r_e[b_e[x]] {
      sq_comm = false
    }
  }
  let hs_ok = pb_roundtrip &&
    realigned.vertex_type_codes == [3, 3, 3, 3] &&
    sq_comm

  // 7. [#40 宇宙同構映射] (a) `Lift(S^1)` 在開放中性項上之嚴格定義 β/η 往返與沿 `Lift(ua(not))` 之 `coe` 可換性；
  //    (b) `(Bool ≃ Bool) ≃ Path_U Bool Bool` 之 `ua_beta` 與 `ua_eta` 雙向驗證！
  let lift_s1 = cubical_lift_type_value(s1)
  let x0_s1 = @kernel.reflect_neutral_at_type(@kernel.DNeutral::DNVar(0), s1)
  let u0_lift = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(0),
    lift_s1,
  )
  let lift_beta = @kernel.conv_at(
    1,
    0,
    s1,
    cubical_lift_out_value(cubical_lift_in_value(x0_s1)),
    x0_s1,
  )
  let lift_eta = @kernel.conv_at(
    1,
    0,
    lift_s1,
    cubical_lift_in_value(cubical_lift_out_value(u0_lift)),
    u0_lift,
  )
  let lift_ua_line = fn(i : @face_bdd.Dim) -> @kernel.DValue {
    cubical_lift_type_value(@kernel.ua_type_at(not_eqv, bool_ty, bool_ty, 0, i))
  }
  let coe_lifted = @kernel.coe_value(
    lift_ua_line,
    DZero,
    DOne,
    cubical_lift_in_value(b_true),
    0,
  )
  let lift_coe_comm = @kernel.dv_is_bool_dep(
    cubical_lift_out_value(coe_lifted),
    false,
  )
  let lift_all_ok = lift_beta && lift_eta && lift_coe_comm

  // `(Bool ≃ Bool) ≃ (Bool =_U Bool)`：`ua_beta_path_value` 見證 `Path Bool (coe (ua not) b) (not b)`，
  // 且 `ua(id)` 與 `ua(not)` 在 `U_0` 中不等價（區分全部 2 個自同構）！
  let id_bool = @kernel.equiv_id_value(bool_ty)
  let p_id = @kernel.ua_value(id_bool, bool_ty, bool_ty, 0)
  let p_not = @kernel.ua_value(not_eqv, bool_ty, bool_ty, 0)
  let univ0 = @kernel.DValue::DVUniv(0)
  let path_u_ty = @kernel.DValue::DVPathTy(fn(_) { univ0 }, bool_ty, bool_ty)
  let beta_path_t = @homotopy.ua_beta_path_value(
    not_eqv, bool_ty, bool_ty, 0, b_true, 0,
  )
  let ua_iso_ok = !@kernel.conv_at(0, 0, path_u_ty, p_id, p_not) &&
    @kernel.dv_is_bool_dep(@kernel.dapp_dim(beta_path_t, DZero), false) &&
    @kernel.dv_is_bool_dep(@kernel.dapp_dim(beta_path_t, DOne), false) &&
    @kernel.conv_ty(0, 0, @kernel.dapp_dim(p_not, DZero), bool_ty) &&
    @kernel.conv_ty(0, 0, @kernel.dapp_dim(p_not, DOne), bool_ty)

  GlueHaeUniverseClassifierReport::{
    glue_type_strict_top_and_bot_collapse_ok: strict_collapse_ok,
    glue_data_beta_and_neutral_eta_ok: glue_data_ok,
    glue_misaligned_datum_rejected: misaligned_rej,
    glue_double_twisted_line_kan_coe_ok: glue_kan_ok,
    finite_256_maps_quadrilogy_exact_24_ok: quad_24_ok,
    s1_incoherent_qinv_detected: incoherent_detected,
    vogt_adjointified_winding_and_2cell_ok: vogt_ok,
    hs_pullback_and_realignment_strict_ok: hs_ok,
    universe_lift_neutral_beta_eta_and_coe_ok: lift_all_ok,
    univalence_bool_iso_beta_eta_ok: ua_iso_ok,
  }
}
