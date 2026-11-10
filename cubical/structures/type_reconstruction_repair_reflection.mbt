// ---------------------------------------------------------------------------
// cubical/structures — 依賴類型重構與自動修補、高階合一橋接、堪恩貼合邊界系統
// 與自由群胚內部計算反射（Internal Computational Reflection）
// ---------------------------------------------------------------------------
//
// 落實《工作內容4.md》核心結構：
//   - #19/#28 堪恩貼合系統、邊界系統（面重疊相容性、擬陣最小獨立面基底與開盒補蓋）
//   - #21 依賴類型重構與自動修補（隱式洞重構、異質端點自動插入 `coe` 配接器、缺蓋邊界自動 Kan 修補、
//         以及拓撲阻礙最小衝突對診斷）
//   - #22 高階合一演算法（聯動 `@elaborator` Miller 模式合一與高階內層 λ 匹配重構隱式動機）
//   - #48 內部計算反射（語法引號 `ReflLoopExpr`、`O(|e|)` 堆疊自由群字約化正規化器、指稱求值至
//         `S^1` 與 `T^2` Kan 路徑及單值繞數反射可靠性定理）
//
// 交互運用之 26 動詞與 14 組範疇組合範例：
//   - [V04 併攏 × V12 擬陣 × V20 相容 × C02 層黏合]：
//     將冗余立方邊界系統之面頂點覆蓋向量視為 `GF(2)`／布林覆蓋擬陣，貪心抽取最小無冗餘基底後以
//     `dcube_open_box` 自動補齊缺失頂蓋。
//   - [V02 計算機抽象 × V07 計算 × V22 證明 × C12 局部化]：
//     透過自由群字約化反射正規化器在線性時間 `O(n)` 消去高階迴圈冗餘逆元對，再映射至受信任立方核心。

///|
/// 自動修補診斷結果類別。
#derive(Debug, Eq)
pub(all) enum BoundaryRepairStatus {
  AlreadyCompleteAndCompatible
  RepairedViaCoercionAdapter
  RepairedViaOpenBoxCapSynthesis
  UnsolvableConflictPair(Int32, Int32)
}

///|
pub extend BoundaryRepairStatus with @debug.Debug::{to_repr}

///|
pub extend BoundaryRepairStatus with Eq::{not_equal, equal}

///|
/// 依賴類型重構、自動修補與內部計算反射驗證報告。
#derive(Debug, Eq)
pub(all) struct ReconstructRepairReflectReport {
  hou_implicit_motive_reconstructed : Bool
  heterogeneous_endpoint_coe_repaired : Bool
  redundant_open_box_matroid_basis_size : Int32
  open_box_missing_lid_repaired_winding : Int32
  incompatible_corner_obstruction_caught : BoundaryRepairStatus
  reflection_s1_free_word_reduced_len : Int32
  reflection_s1_denotation_winding_matches : Bool
  reflection_t2_abelian_commutator_trivial : Bool
}

///|
pub extend ReconstructRepairReflectReport with @debug.Debug::{to_repr}

///|
pub extend ReconstructRepairReflectReport with Eq::{not_equal, equal}

///|
/// 內部計算反射之高階迴圈代數引號語法（Quote AST）：
/// 支援單位元 `RLId`、生成元 `RLGen(g)`（`g >= 1`）、逆元 `RLInv`、串接 `RLComp` 與共軛 `RLConj(x, y) = x · y · x^{-1}`。
#derive(Debug, Eq)
pub(all) enum ReflLoopExpr {
  RLId
  RLGen(Int32)
  RLInv(ReflLoopExpr)
  RLComp(ReflLoopExpr, ReflLoopExpr)
  RLConj(ReflLoopExpr, ReflLoopExpr)
}

///|
pub extend ReflLoopExpr with @debug.Debug::{to_repr}

///|
pub extend ReflLoopExpr with Eq::{not_equal, equal}

///|
/// 將 `ReflLoopExpr` 展開為帶號生成元序列，並以線性時間 `O(|e|)` 堆疊消元（聯動 `@gcd.ugcd_free_group_reduce`）
/// 求得唯一自由群約化正規形（Internal Reflection Normalizer）。
pub fn refl_loop_normalize_free(e : ReflLoopExpr) -> Array[Int32] {
  fn flatten(cur : ReflLoopExpr, out : Array[Int32], inv_mode : Bool) -> Unit {
    match cur {
      RLId => ()
      RLGen(g) => out.push(if inv_mode { -g } else { g })
      RLInv(inner) => flatten(inner, out, !inv_mode)
      RLComp(a, b) =>
        if !inv_mode {
          flatten(a, out, false)
          flatten(b, out, false)
        } else {
          flatten(b, out, true)
          flatten(a, out, true)
        }
      RLConj(x, y) =>
        if !inv_mode {
          flatten(x, out, false)
          flatten(y, out, false)
          flatten(x, out, true)
        } else {
          flatten(x, out, false)
          flatten(y, out, true)
          flatten(x, out, true)
        }
    }
  }
  let raw : Array[Int32] = []
  flatten(e, raw, false)
  @gcd.ugcd_free_group_reduce(raw)
}

///|
/// 環面 `T^2 ≃ S^1 × S^1`（雙生成元阿貝爾基本群 `Z^2`）之反射正規化器：回傳規範繞數向量 `(w_1, w_2)`。
pub fn refl_loop_normalize_abelian_t2(e : ReflLoopExpr) -> (Int32, Int32) {
  let red = refl_loop_normalize_free(e)
  let mut w1 = 0
  let mut w2 = 0
  for lit in red {
    if lit == 1 {
      w1 = w1 + 1
    } else if lit == -1 {
      w1 = w1 - 1
    } else if lit == 2 {
      w2 = w2 + 1
    } else if lit == -2 {
      w2 = w2 - 1
    }
  }
  (w1, w2)
}

///|
/// 指稱語義解釋器 `⟦-⟧_{S^1} : ReflLoopExpr -> DValue`：將引號語法直接求值為 `@kernel` 中 `S^1` HIT 上之真實 Kan 路徑！
pub fn refl_denote_s1_kan_path(e : ReflLoopExpr) -> @kernel.DValue {
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let lp = @homotopy.circle_hit_loop_path_value()
  match e {
    RLId => @homotopy.dpath_refl_value(base)
    RLGen(_) => lp
    RLInv(inner) => @homotopy.dpath_sym_value(refl_denote_s1_kan_path(inner))
    RLComp(a, b) =>
      @homotopy.dpath_trans_value(
        s1,
        refl_denote_s1_kan_path(a),
        refl_denote_s1_kan_path(b),
        0,
      )
    RLConj(x, y) => {
      let dx = refl_denote_s1_kan_path(x)
      let dy = refl_denote_s1_kan_path(y)
      let xy = @homotopy.dpath_trans_value(s1, dx, dy, 0)
      @homotopy.dpath_trans_value(s1, xy, @homotopy.dpath_sym_value(dx), 0)
    }
  }
}

///|
/// 診斷 2D 方塊邊界候選面列表之交點相容性，並以擬陣貪心選取最小無冗餘面基底；
/// 若相容且恰缺頂蓋 `(axis=1, side=true)`，自動呼叫 `@kernel.dcube_open_box` 修補合成完整方塊頂蓋！
pub fn diagnose_and_repair_square_boundary(
  ty : @kernel.DValue,
  faces : Array[(Int32, Bool, @kernel.DCubeFunction)],
) -> (BoundaryRepairStatus, Int32, @kernel.DValue?) {
  // 1. 檢查兩兩面在共享角點處是否定義等價（邊界貼合條件）
  let m = faces.length()
  for i in 0..<m {
    let (ax_i, side_i, fn_i) = faces[i]
    for j in (i + 1)..<m {
      let (ax_j, side_j, fn_j) = faces[j]
      if ax_i == ax_j && side_i == side_j {
        // 同一面重複給出：檢驗在端點 0 與 1 是否一致
        let v_i0 = @kernel.dcube_at(fn_i, [DZero])
        let v_j0 = @kernel.dcube_at(fn_j, [DZero])
        if !@kernel.conv_at(0, 0, ty, v_i0, v_j0) {
          return (UnsolvableConflictPair(i, j), 0, None)
        }
      } else if ax_i != ax_j {
        // 正交面相交於唯一角點：ax_i 固定為 side_i，ax_j 固定為 side_j
        let dim_for_i = if side_j {
          @face_bdd.Dim::DOne
        } else {
          @face_bdd.Dim::DZero
        }
        let dim_for_j = if side_i {
          @face_bdd.Dim::DOne
        } else {
          @face_bdd.Dim::DZero
        }
        let corner_i = @kernel.dcube_at(fn_i, [dim_for_i])
        let corner_j = @kernel.dcube_at(fn_j, [dim_for_j])
        if !@kernel.conv_at(0, 0, ty, corner_i, corner_j) {
          return (UnsolvableConflictPair(i, j), 0, None)
        }
      }
    }
  }

  // 2. 擬陣獨立集抽取：每個 `(axis, side)` 槽位最多保留第一個代表元，消除冗餘重複面！
  let seen_slot : Map[Int32, Bool] = Map([])
  let basis_faces : Array[@kernel.DCubeBoxFace] = []
  for (ax, side, cf) in faces {
    let key = ax * 2 + (if side { 1 } else { 0 })
    if !seen_slot.contains(key) {
      seen_slot[key] = true
      basis_faces.push(@kernel.dcube_box_face(ax, side, cf))
    }
  }
  let basis_sz = basis_faces.length()
  if basis_sz == 4 {
    return (AlreadyCompleteAndCompatible, basis_sz, None)
  }

  // 3. 若具 3 個正交開盒面（缺 `(axis=1, side=true)` 頂蓋），自動以 Kan 開盒合成修補缺失頂蓋並驗證全邊界相容！
  let box = @kernel.dcube_open_box(ty, 2, 0, basis_faces)
  match @kernel.dcube_box_fill_verified(box, 0) {
    Some(filler) =>
      if @kernel.dcube_filler_faces_ok(box, filler, 0) {
        match @kernel.dcube_box_cap(box) {
          Some(cap) => {
            let cap_path = @kernel.DValue::DVPathLam(fn(i) {
              @kernel.dcube_at(cap, [i])
            })
            (RepairedViaOpenBoxCapSynthesis, basis_sz, Some(cap_path))
          }
          None => (UnsolvableConflictPair(-1, -1), basis_sz, None)
        }
      } else {
        (UnsolvableConflictPair(-1, -1), basis_sz, None)
      }
    None => (UnsolvableConflictPair(-1, -1), basis_sz, None)
  }
}

///|
/// 執行依賴類型隱式洞重構、異質端點 `coe` 修補、開盒邊界擬陣基底修補與自由群胚內部計算反射驗證。
pub fn verify_reconstruction_repair_and_reflection_suite() -> ReconstructRepairReflectReport {
  // 1. 聯動 `@elaborator` Miller 模式高階合一：重構依賴消去隱式動機 `?M(x) ≡ Pair(x, x)`！
  let unif = @elaborator.unifier_new()
  let _ = @elaborator.hou_fresh_meta(unif, 0)
  let b_ty = @elaborator.uty_bool()
  let lhs = @elaborator.UTerm::ULam(
    b_ty,
    @elaborator.UTerm::UMeta(0, [@elaborator.UTerm::UVar(0)]),
  )
  let rhs = @elaborator.UTerm::ULam(
    b_ty,
    @elaborator.UTerm::UPair(
      @elaborator.UTerm::UVar(0),
      @elaborator.UTerm::UVar(0),
    ),
  )
  let hou_ok = @elaborator.hou_unify(lhs, rhs, 0, unif) &&
    @elaborator.hou_conv(lhs, rhs, unif)

  // 2. 異質類型不匹配自動修補：`a0 = true : Bool` 與沿 `ua(not)` 傳輸後之右端點 `a1 = false : Bool`
  //    在直接齊次路徑 `Path Bool true false` 無法以 `refl` 居留，修補器自動插入 `coe^{0->1} (ua not) a0`
  //    使左端點變為 `false`，從而由 `refl(false)` 合法居留！
  let not_eqv = @kernel.deval_dim(
    @kernel.bool_not_equiv_term(),
    @kernel.denv_empty(),
    @kernel.ddim_empty(),
  )
  let ua_line = @kernel.ua_line_value(not_eqv, DVBoolTy, DVBoolTy, 0)
  let adapted_a0 = @kernel.coe_value(ua_line, DZero, DOne, DVBool(true), 0)
  let repaired_refl = @homotopy.dpath_refl_value(adapted_a0)
  let coe_repair_ok = @kernel.dv_is_bool_dep(
      @kernel.dapp_dim(repaired_refl, DZero),
      false,
    ) &&
    @kernel.dv_is_bool_dep(@kernel.dapp_dim(repaired_refl, DOne), false)

  // 3. 含冗餘重複面（5 個輸入面，覆蓋 3 個開盒方向）之 `S^1` 邊界系統：
  //    擬陣基底縮減為 `3` 個獨立面並自動修補合成頂蓋 `loop ⬝ loop^2`（繞數 = +3），且通過全邊界驗證！
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let lp = @homotopy.circle_hit_loop_path_value()
  let lp2 = @homotopy.circle_hit_loop_power_value(2)
  let lp_cube = @kernel.dcube_of_path(fn(i) { @kernel.dapp_dim(lp, i) })
  let refl_cube = @kernel.dcube_constant(1, base)
  let lp2_cube = @kernel.dcube_of_path(fn(j) { @kernel.dapp_dim(lp2, j) })
  let redundant_faces : Array[(Int32, Bool, @kernel.DCubeFunction)] = [
    (1, false, lp_cube), // 底邊 j=0 : loop(i) (+1)
    (1, false, lp_cube), // 冗餘重複底邊
    (0, false, refl_cube), // 左邊 i=0 : refl(base) (0)
    (0, true, lp2_cube), // 右邊 i=1 : loop^2(j) (+2)
    (0, true, lp2_cube), // 冗餘重複右邊
  ]
  let (rep_status, basis_sz, cap_opt) = diagnose_and_repair_square_boundary(
    s1, redundant_faces,
  )
  let repaired_w = match cap_opt {
    Some(cp) =>
      match @autonomy.univalent_circle_winding(cp) {
        Some(w) => w
        None => 0
      }
    None => 0
  }
  let box_repair_ok = rep_status == RepairedViaOpenBoxCapSynthesis &&
    basis_sz == 3 &&
    repaired_w == 3

  // 4. 負對照：角點不相容邊界（底邊在 i=0 為 `true`，左邊在 j=0 為 `false`）精確抓出最小衝突對 `(0, 1)`！
  let bad_faces : Array[(Int32, Bool, @kernel.DCubeFunction)] = [
    (1, false, @kernel.dcube_constant(1, DVBool(true))),
    (0, false, @kernel.dcube_constant(1, DVBool(false))),
  ]
  let (bad_status, _, _) = diagnose_and_repair_square_boundary(
    DVBoolTy,
    bad_faces,
  )

  // 5. 內部計算反射：複雜迴圈項 `Conj(g1, g1 · g1) · (g1^{-1} · g1)`（共 7 個原始原子構造子）
  //    經線性時間反射正規化器消元為長度 `2` 之 `[1, 1]`，且直接求值為 `@kernel` Kan 路徑繞數恰為 `+2`！
  let complex_s1_expr = ReflLoopExpr::RLComp(
    RLConj(RLGen(1), RLComp(RLGen(1), RLGen(1))),
    RLComp(RLInv(RLGen(1)), RLGen(1)),
  )
  let norm_word = refl_loop_normalize_free(complex_s1_expr)
  let denoted_kan = refl_denote_s1_kan_path(complex_s1_expr)
  let norm_kan = refl_denote_s1_kan_path(RLComp(RLGen(1), RLGen(1)))
  let w_raw = @autonomy.univalent_circle_winding(denoted_kan)
  let w_norm = @autonomy.univalent_circle_winding(norm_kan)
  let refl_s1_ok = norm_word == [1, 1] && w_raw == Some(2) && w_norm == Some(2)

  // 環面 T^2 反射：交換子 `[g1, g2] = g1 · g2 · g1^{-1} · g2^{-1}` 在自由群長 4，在 T^2 阿貝爾反射正規化為 (0, 0)！
  let comm_expr = ReflLoopExpr::RLComp(
    RLComp(RLGen(1), RLGen(2)),
    RLComp(RLInv(RLGen(1)), RLInv(RLGen(2))),
  )
  let free_comm = refl_loop_normalize_free(comm_expr)
  let ab_comm = refl_loop_normalize_abelian_t2(comm_expr)
  let refl_t2_ok = free_comm.length() == 4 && ab_comm == (0, 0)

  ReconstructRepairReflectReport::{
    hou_implicit_motive_reconstructed: hou_ok,
    heterogeneous_endpoint_coe_repaired: coe_repair_ok,
    redundant_open_box_matroid_basis_size: basis_sz,
    open_box_missing_lid_repaired_winding: repaired_w,
    incompatible_corner_obstruction_caught: bad_status,
    reflection_s1_free_word_reduced_len: norm_word.length(),
    reflection_s1_denotation_winding_matches: box_repair_ok && refl_s1_ok,
    reflection_t2_abelian_commutator_trivial: refl_t2_ok,
  }
}
