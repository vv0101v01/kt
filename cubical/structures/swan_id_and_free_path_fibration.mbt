// ---------------------------------------------------------------------------
// cubical/structures — Swan/CCHM 嚴格 J 恆等型、異質合成、自由路徑纖維化與
// Eilenberg–Zilber 標準退化樹分解
// ---------------------------------------------------------------------------
//
// 落實《工作內容4.md》核心結構：
//   - #6  恆等類型（Swan / CCHM §9.1 `Id_A(x,y) = Σ(p : Path A x y). (φ : Face, φ ⇒ p ≡ refl)`）
//   - #10 異質相等（`PathP (λi. A i) a0 a1 ≃ Path (A 1) (coe A a0) a1`）
//   - #11 路徑連線（`i ∧ j`、`i ∨ j` 誘導單例路徑空間收縮與半伴隨等價相干胞）
//   - #29/#30/#34 合成運算、齊次合成、異質合成（`comp ≡ coe + hcomp` 雙路徑對帳）
//   - #31/#32/#33 路徑反轉（對合 `1-i` vs 無對合純 Kan 開盒反轉）、路徑串接、核心路徑類型
//   - #37/#38 等價性與半伴隨等價（`Id_A(x,y) ≃ Path_A(x,y)` 雙向往返）
//   - #41 自由路徑空間（對角映射纖維化分解 `X ->^{~} L_free(X) ->> X × X`）
//   - #50 立方體退化樹結構（Eilenberg–Zilber 唯一標準退化分解與全體 65,536 個 4-立方體分層對帳）
//
// 交互運用之 26 動詞與 14 組範疇組合範例：
//   - [V01 衍生 × V26 命題轉換 × C03 纖維積 × C06 Grothendieck 纖維化]：
//     由 `Path_A` 沿上纖維化分類子拉回導出嚴格計算 `J_Id(C, d, refl_Id) ≡ d`，並與一般 `Path`
//     上僅命題成立之 `J_Path` 作雙路徑分離比照（V24 比照）。
//   - [V05 嵌入 × V10 鏡像對稱 × C12 局部化／分解系]：
//     對角常數嵌入 `r : X -> L_free(X)` 與端點投影 `(ev0, ev1)` 構成同倫等價＋Kan 纖維化分解。
//   - [V07 計算 × V23 統計 × C09 Operad 槽位合成]：
//     以 64-bit SWAR 蝴蝶面萃取與退化插入實作 O(dim) Eilenberg–Zilber 標準分解，窮舉驗證
//     `∑_{k=0}^4 C(4,k) |X_{4-k}^{nondeg}| = 64594 + 872 + 60 + 8 + 2 = 65536`。

///|
/// Swan / CCHM 嚴格計算恆等型值：`path` 配備見證其為常數自反路徑之上纖維化範圍 `extent`。
/// 不變式：在面約束 `extent` 下，`path` 為常數路徑且兩端點定義相等。
pub struct SwanIdValue {
  carrier_ty : @kernel.DValue
  left_pt : @kernel.DValue
  right_pt : @kernel.DValue
  path_val : @kernel.DValue
  extent : @face_bdd.Face
}

///|
/// 構造自反恆等證書 `refl_Id(x) := (λi. x, ⊤)`（全域常數範圍 `FaceTop`）。
pub fn swan_id_refl(ty : @kernel.DValue, x : @kernel.DValue) -> SwanIdValue {
  SwanIdValue::{
    carrier_ty: ty,
    left_pt: x,
    right_pt: x,
    path_val: @homotopy.dpath_refl_value(x),
    extent: FTop,
  }
}

///|
/// 由一般立方路徑 `p : Path A x y` 嵌入至 `SwanIdValue`（常數保證範圍為 `⊥`，即一般非自反路徑）。
pub fn swan_id_of_path(
  ty : @kernel.DValue,
  x : @kernel.DValue,
  y : @kernel.DValue,
  p : @kernel.DValue,
) -> SwanIdValue {
  SwanIdValue::{
    carrier_ty: ty,
    left_pt: x,
    right_pt: y,
    path_val: p,
    extent: FBot,
  }
}

///|
/// 遺忘常數範圍投影 `SwanId A x y -> Path A x y`。
pub fn swan_id_to_path(w : SwanIdValue) -> @kernel.DValue {
  w.path_val
}

///|
/// 檢驗 `SwanIdValue` 的常數範圍不變式：在給定變數層數 `vlevel` 與維度層數 `dlevel` 下，
/// `p(0) ≡ left_pt`、`p(1) ≡ right_pt`，且在 `w.extent` 面約束下 `p(i) ≡ left_pt`。
pub fn swan_id_well_formed_at(
  vlevel : Int32,
  w : SwanIdValue,
  dlevel : Int32,
) -> Bool {
  let p0 = @kernel.dapp_dim(w.path_val, DZero)
  let p1 = @kernel.dapp_dim(w.path_val, DOne)
  let pi = @kernel.dapp_dim(w.path_val, DVar(dlevel))
  let endpoints_ok = @kernel.conv_at(
      vlevel,
      dlevel,
      w.carrier_ty,
      p0,
      w.left_pt,
    ) &&
    @kernel.conv_at(vlevel, dlevel, w.carrier_ty, p1, w.right_pt)
  let extent_const_ok = @kernel.conv_at_under_face(
    vlevel,
    dlevel + 1,
    w.extent,
    w.carrier_ty,
    pi,
    w.left_pt,
  )
  endpoints_ok && extent_const_ok
}

///|
pub fn swan_id_well_formed(w : SwanIdValue, dlevel : Int32) -> Bool {
  swan_id_well_formed_at(0, w, dlevel)
}

///|
/// Swan / CCHM 嚴格計算 `J` 消去子：
/// 給定動機族 `motive : (y : A) -> SwanIdValue(x, y) -> DValue` 與自反基底值 `base_d : motive x refl_Id(x)`，
/// 使用偏系統 `[w.extent ↦ λi. base_d]` 驅動依賴 `comp_value`：
/// - 當 `w = refl_Id(x)`（`w.extent == FaceTop`）時，系統在 `⊤` 上直接命中並**嚴格定義歸約**回傳 `base_d`！
/// - 當 `w` 為非自反路徑（如 `ua(not)` 或 `S^1` 迴圈）時，沿連線單例收縮 `(p(i), (λj. p(i ∧ j), extent ∨ (i=0)))`
///   執行 Kan 合成傳輸。
pub fn swan_id_j_elim(
  motive : (@kernel.DValue, SwanIdValue) -> @kernel.DValue,
  base_d : @kernel.DValue,
  w : SwanIdValue,
  dlevel : Int32,
) -> @kernel.DValue {
  let bdd_ext = @face_bdd.bdd_of_face(w.extent, dlevel + 1)
  if bdd_ext == BddOne {
    return base_d
  }
  let type_line = fn(i : @face_bdd.Dim) -> @kernel.DValue {
    let yi = @kernel.dapp_dim(w.path_val, i)
    let prefix_path = @kernel.DValue::DVPathLam(fn(j) {
      @kernel.dapp_dim(w.path_val, DAnd(i, j))
    })
    let prefix_ext = @face_bdd.face_or(w.extent, @face_bdd.face_eq0(i))
    let wi = SwanIdValue::{
      carrier_ty: w.carrier_ty,
      left_pt: w.left_pt,
      right_pt: yi,
      path_val: prefix_path,
      extent: prefix_ext,
    }
    motive(yi, wi)
  }
  let sys = if bdd_ext == BddZero {
    @kernel.dsystem_empty()
  } else {
    @kernel.dsystem_singleton(w.extent, fn(_) { base_d })
  }
  @kernel.comp_value(type_line, sys, base_d, dlevel)
}

///|
/// 對照組：一般立方路徑 `Path A x y` 的 Kan `J` 消去子（無 `extent` 面標記，只能對整個路徑做 `coe_value`）。
/// 在開放中性項 `x0 : A` 上對 `refl(x0)` 執行非平凡類型族傳輸時會經過 `coe` 步，展現與 `SwanId` 的計算分離。
pub fn path_kan_j_elim(
  motive_on_endpoint : (@kernel.DValue) -> @kernel.DValue,
  base_d : @kernel.DValue,
  p : @kernel.DValue,
  dlevel : Int32,
) -> @kernel.DValue {
  let line = fn(i : @face_bdd.Dim) -> @kernel.DValue {
    motive_on_endpoint(@kernel.dapp_dim(p, i))
  }
  @kernel.coe_value(line, DZero, DOne, base_d, dlevel)
}

///|
/// Eilenberg–Zilber 標準退化分解證書：任意 `d` 維立方體字組唯一分解為
/// 非退化核心 `(core_word, core_dim)` 與嚴格遞增退化軸序列 `degen_axes`（`0 ≤ i_1 < ... < i_k < d`）。
#derive(Debug, Eq)
pub(all) struct EilenbergZilberCubeFactor {
  ambient_dim : Int32
  core_dim : Int32
  core_word : UInt64
  degen_axes : Array[Int32]
}

///|
pub extend EilenbergZilberCubeFactor with @debug.Debug::{to_repr}

///|
pub extend EilenbergZilberCubeFactor with Eq::{not_equal, equal}

///|
/// 以 64-bit SWAR 退化遮罩與蝴蝶面萃取在 `O(dim)` 時間計算立方體之唯一 Eilenberg–Zilber 標準退化分解。
/// 定理：若 `deg_mask` 標記所有退化軸 `i_1 < ... < i_k`，由高軸至低軸依序取 `∂_{i_r, 0}` 所得核心必完全非退化，
/// 且由低軸至高軸依序插入 `s_{i_r}` 逐位精確還原原立方體！
pub fn ez_canonical_cube64_factor(
  word : UInt64,
  dim : Int32,
) -> EilenbergZilberCubeFactor {
  let clean = word & @accel.cube64_active_mask(dim)
  let mask = @accel.cube64_degeneracy_mask(clean, dim)
  let axes : Array[Int32] = []
  for ax in 0..<dim {
    if ((mask >> ax) & 1UL) == 1UL {
      axes.push(ax)
    }
  }
  let mut cur_word = clean
  let mut cur_dim = dim
  let k = axes.length()
  for step in 0..<k {
    let ax = axes[k - 1 - step]
    cur_word = @accel.cube64_extract_face_swar(cur_word, cur_dim, ax, 0)
    cur_dim = cur_dim - 1
  }
  EilenbergZilberCubeFactor::{
    ambient_dim: dim,
    core_dim: cur_dim,
    core_word: cur_word,
    degen_axes: axes,
  }
}

///|
/// 由 Eilenberg–Zilber 標準分解逆向重構 `ambient_dim` 維立方體字組。
pub fn ez_reconstruct_cube64(fac : EilenbergZilberCubeFactor) -> UInt64 {
  let mut cur_word = fac.core_word
  let mut cur_dim = fac.core_dim
  for ax in fac.degen_axes {
    cur_word = @accel.cube64_insert_degeneracy_swar(cur_word, cur_dim + 1, ax)
    cur_dim = cur_dim + 1
  }
  cur_word & @accel.cube64_active_mask(fac.ambient_dim)
}

///|
/// Swan 恆等型、異質合成、自由路徑纖維化與 Eilenberg–Zilber 退化分解綜合驗證報告。
#derive(Debug, Eq)
pub(all) struct SwanIdFreePathEzReport {
  swan_refl_strict_definitional_j : Bool
  swan_nontrivial_s1_winding_transport : Bool
  swan_id_path_roundtrip_equiv : Bool
  heterogeneous_pathp_coe_bridge_ok : Bool
  heterogeneous_comp_equals_coe_hcomp : Bool
  involutive_vs_pure_kan_sym_agree : Bool
  free_path_diagonal_hae_retraction_ok : Bool
  ez_4cube_stratum_counts : Array[Int32]
  ez_all_65536_unique_roundtrip_ok : Bool
}

///|
pub extend SwanIdFreePathEzReport with @debug.Debug::{to_repr}

///|
pub extend SwanIdFreePathEzReport with Eq::{not_equal, equal}

///|
/// 執行 Swan 恆等型、異質路徑／異質合成、無對合 Kan 反轉、自由路徑空間對角分解與 65,536 個 4-立方體
/// Eilenberg–Zilber 標準分解驗證。
pub fn verify_swan_id_free_path_and_ez_suite() -> SwanIdFreePathEzReport {
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let lp = @homotopy.circle_hit_loop_path_value()
  let z_ty = @homotopy.integer_type_value()
  let z0 = @homotopy.integer_value(0)
  let z1 = @homotopy.integer_value(1)

  // 1. Swan 嚴格 J 與 Path J 分離定理：在開放中性項 x0 : S^1（vlevel = 1）上，
  //    J_Id(C, z0, refl_Id(x0)) 嚴格定義歸約為 z0，而無 extent 標記之一般 Path J 滯留於中性 coe！
  let x0_neu = @kernel.reflect_neutral_at_type(@kernel.DNeutral::DNVar(0), s1)
  let refl_x0 = swan_id_refl(s1, x0_neu)
  let motive_cover = fn(
    y : @kernel.DValue,
    _w : SwanIdValue,
  ) -> @kernel.DValue {
    @homotopy.circle_cover_value(y)
  }
  let j_on_refl = swan_id_j_elim(motive_cover, z0, refl_x0, 0)
  let path_j_on_refl = path_kan_j_elim(
    fn(y) { @homotopy.circle_cover_value(y) },
    z0,
    @homotopy.dpath_refl_value(x0_neu),
    0,
  )
  let strict_q_lhs = @kernel.quote_at(1, 0, z_ty, j_on_refl)
  let strict_q_rhs = @kernel.quote_at(1, 0, z_ty, z0)
  let path_q_lhs = @kernel.quote_at(1, 0, z_ty, path_j_on_refl)
  let swan_strict_ok = swan_id_well_formed_at(1, refl_x0, 0) &&
    strict_q_lhs == strict_q_rhs &&
    path_q_lhs != strict_q_rhs

  // 2. 非自反路徑 w_loop = (loop, FaceBot) 上，J_Id 沿圓周萬有覆蓋將 0 傳輸為 +1！
  let w_loop = swan_id_of_path(s1, base, base, lp)
  let j_on_loop = swan_id_j_elim(motive_cover, z0, w_loop, 0)
  let swan_transport_ok = swan_id_well_formed(w_loop, 0) &&
    @kernel.conv_at(0, 0, z_ty, j_on_loop, z1)

  // 3. SwanId <-> Path 往返同倫等價驗證
  let rt_path = swan_id_to_path(swan_id_of_path(s1, base, base, lp))
  let loop_ty = @kernel.DValue::DVPathTy(fn(_) { s1 }, base, base)
  let id_path_rt_ok = @kernel.conv_at(0, 0, loop_ty, rt_path, lp)

  // 4. 異質相等 PathP (ua(not)) true false <-> Path Bool (coe (ua(not)) true) false
  let not_eqv = @kernel.deval_dim(
    @kernel.bool_not_equiv_term(),
    @kernel.denv_empty(),
    @kernel.ddim_empty(),
  )
  let ua_line = @kernel.ua_line_value(not_eqv, DVBoolTy, DVBoolTy, 0)
  let coe_true = @kernel.coe_value(ua_line, DZero, DOne, DVBool(true), 0)
  let het_pathp_as_hom = @homotopy.dpath_of_pathp_value(
    ua_line,
    @kernel.DValue::DVPathLam(fn(i) {
      @kernel.coe_value(ua_line, DZero, i, DVBool(true), 1)
    }),
    0,
  )
  let het_bridge_ok = @kernel.dv_is_bool_dep(coe_true, false) &&
    @kernel.dv_is_bool_dep(@kernel.dapp_dim(het_pathp_as_hom, DZero), false) &&
    @kernel.dv_is_bool_dep(@kernel.dapp_dim(het_pathp_as_hom, DOne), false)

  // 5. 異質合成 `comp_value` vs Kan 分解 `hcomp(A(1), [φ ↦ coe^{j->1} u(j)], coe^{0->1} u0)` 雙演算法對帳：
  //    在環境維度 dlevel = 1（側面約束 f0 = (i_0 = 0)，合成軸為 i_1）沿單值線 ua(not) 傳輸！
  let f0 = @face_bdd.face_var0(0)
  let sys_het = @kernel.dsystem_singleton(f0, fn(j) {
    @kernel.coe_value(ua_line, DZero, j, DVBool(true), 2)
  })
  let direct_het_comp = @kernel.comp_value(ua_line, sys_het, DVBool(true), 1)
  let decomp_base = @kernel.coe_value(ua_line, DZero, DOne, DVBool(true), 1)
  let decomp_sys = @kernel.dsystem_singleton(f0, fn(j) {
    let uj = @kernel.coe_value(ua_line, DZero, j, DVBool(true), 2)
    @kernel.coe_value(ua_line, j, DOne, uj, 2)
  })
  let decomp_het_comp = @kernel.hcomp_value(
    DVBoolTy,
    decomp_sys,
    decomp_base,
    1,
  )
  let het_comp_ok = @kernel.conv_at(
      0,
      1,
      DVBoolTy,
      direct_het_comp,
      decomp_het_comp,
    ) &&
    @kernel.dv_is_bool_dep(direct_het_comp, false)

  // 6. 對合路徑反轉 `sym_invol = λi. lp(1-i)`（繞數 -1）與無對合純 Kan 2D 開盒反轉 `pure_kan_inv`：
  //    直接在 `@kernel` 構造 3D 開盒填充器 `I^3 -> S^1`（全 5 面與 10 條交稜經 `dcube_box_fill_verified` 驗證），
  //    其頂蓋給出 `Path (ΩS^1) pure_kan_inv sym_invol` 的精確立方同倫見證！
  let sym_invol = @homotopy.dpath_sym_value(lp)
  let box_inv = @kernel.dcube_open_box(s1, 2, 0, [
    @kernel.dcube_box_face(1, false, @kernel.dcube_constant(1, base)),
    @kernel.dcube_box_face(
      0,
      false,
      @kernel.dcube_of_path(fn(j) { @kernel.dapp_dim(lp, j) }),
    ),
    @kernel.dcube_box_face(0, true, @kernel.dcube_constant(1, base)),
  ])
  let sym_kan_ok = match @kernel.dcube_box_fill_verified(box_inv, 0) {
    Some(filler_inv) =>
      match @kernel.dcube_box_cap(box_inv) {
        Some(cap_inv) => {
          let pure_kan_inv = @kernel.DValue::DVPathLam(fn(i) {
            @kernel.dcube_at(cap_inv, [i])
          })
          // 連接正方形 K(i, j) = lp((1 - i) ∧ j) 與 filler_inv(i, j) 共享相同三面開盒邊界，
          // 故在 3D 開盒 (i, k, j) 中給出頂蓋 j=1 : Path (ΩS^1) pure_kan_inv sym_invol！
          let k_sq = @kernel.dcube_function(2, fn(ds) {
            @kernel.dapp_dim(lp, DAnd(DNeg(ds[0]), ds[1]))
          })
          let lp_j_2d = @kernel.dcube_function(2, fn(ds) {
            @kernel.dapp_dim(lp, ds[1])
          })
          let box3_homotopy = @kernel.dcube_open_box(s1, 3, 0, [
            @kernel.dcube_box_face(2, false, @kernel.dcube_constant(2, base)),
            @kernel.dcube_box_face(0, false, lp_j_2d),
            @kernel.dcube_box_face(0, true, @kernel.dcube_constant(2, base)),
            @kernel.dcube_box_face(1, false, filler_inv),
            @kernel.dcube_box_face(1, true, k_sq),
          ])
          let h3_ok = match @kernel.dcube_box_fill_verified(box3_homotopy, 0) {
            Some(filler3) =>
              match @kernel.dcube_box_cap(box3_homotopy) {
                Some(cap3) => {
                  let lhs_i = @kernel.dcube_at(cap3, [DVar(0), DZero])
                  let rhs_i = @kernel.dcube_at(cap3, [DVar(0), DOne])
                  @kernel.dcube_filler_faces_ok(box3_homotopy, filler3, 0) &&
                  @kernel.conv_at(
                    0,
                    1,
                    s1,
                    lhs_i,
                    @kernel.dapp_dim(pure_kan_inv, DVar(0)),
                  ) &&
                  @kernel.conv_at(
                    0,
                    1,
                    s1,
                    rhs_i,
                    @kernel.dapp_dim(sym_invol, DVar(0)),
                  )
                }
                None => false
              }
            None => false
          }
          @kernel.dcube_filler_faces_ok(box_inv, filler_inv, 0) &&
          @autonomy.univalent_circle_winding(sym_invol) == Some(-1) &&
          h3_ok
        }
        None => false
      }
    None => false
  }

  // 7. 自由路徑空間 L_free(S^1) 對角收縮：連線單例同倫 η(j) = λi. lp(i ∧ j) 在 j=0 為 refl(base)、在 j=1 為 lp，
  //    且 2-相干胞在自反路徑上滿足 η(refl)(j)(i) ≡ base！
  let sing_at_0 = @kernel.DValue::DVPathLam(fn(i) {
    @kernel.dapp_dim(lp, DAnd(i, DZero))
  })
  let sing_at_1 = @kernel.DValue::DVPathLam(fn(i) {
    @kernel.dapp_dim(lp, DAnd(i, DOne))
  })
  let refl_base = @homotopy.dpath_refl_value(base)
  let tau_coh = @kernel.DValue::DVPathLam(fn(i) {
    @kernel.dapp_dim(refl_base, DAnd(i, DVar(0)))
  })
  let free_hae_ok = @kernel.conv_at(0, 0, loop_ty, sing_at_0, refl_base) &&
    @kernel.conv_at(0, 0, loop_ty, sing_at_1, lp) &&
    @kernel.conv_at(0, 1, loop_ty, tau_coh, refl_base)

  // 8. 窮舉全部 2^16 = 65,536 個 4-立方體，驗證 Eilenberg–Zilber 唯一分解往返與各核心維度分層計數：
  //    core_dim = 0..4 對應 [2, 8, 60, 872, 64594]，總和 65,536！
  let strata : Array[Int32] = [0, 0, 0, 0, 0]
  let mut ez_rt_ok = true
  for w in 0..<65536 {
    let word = w.reinterpret_as_uint().to_uint64()
    let fac = ez_canonical_cube64_factor(word, 4)
    let core_deg = @accel.cube64_degeneracy_mask(fac.core_word, fac.core_dim)
    let recon = ez_reconstruct_cube64(fac)
    if core_deg != 0UL ||
      recon != word ||
      fac.core_dim + fac.degen_axes.length() != 4 {
      ez_rt_ok = false
    }
    strata[fac.core_dim] = strata[fac.core_dim] + 1
  }
  let expected_strata : Array[Int32] = [2, 8, 60, 872, 64594]
  let ez_ok = ez_rt_ok && strata == expected_strata

  SwanIdFreePathEzReport::{
    swan_refl_strict_definitional_j: swan_strict_ok,
    swan_nontrivial_s1_winding_transport: swan_transport_ok,
    swan_id_path_roundtrip_equiv: id_path_rt_ok,
    heterogeneous_pathp_coe_bridge_ok: het_bridge_ok,
    heterogeneous_comp_equals_coe_hcomp: het_comp_ok,
    involutive_vs_pure_kan_sym_agree: sym_kan_ok,
    free_path_diagonal_hae_retraction_ok: free_hae_ok,
    ez_4cube_stratum_counts: strata,
    ez_all_65536_unique_roundtrip_ok: ez_ok,
  }
}
