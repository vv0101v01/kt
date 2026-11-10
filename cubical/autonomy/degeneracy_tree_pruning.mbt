// ---------------------------------------------------------------------------
// cubical/autonomy — 立方退化樹結構、高維交錯面算子與立方範式雙向修剪
// ---------------------------------------------------------------------------
//
// 實作公理、定義與定理：
//   1. [D-Cubical-Degeneracy-Tree] 典範退化因子化決策樹：當第 k 軸兩側子樹全等時，
//      直接折疊為 DTDegenerate(k, child) 而非複製 2 倍子樹，達成退化立方體之 O(d)
//      壓縮表示，且其退化軸位元遮罩與 @accel.cube64_degeneracy_mask 逐位全等。
//   2. [T-HighDim-Alternating-Face-Laplacian] 在 d = 2..5 高維超立方體上實作交錯面微分
//      ∂_d = ∑_{k=0}^{d-1} (-1)^k (∂_{k,0} - ∂_{k,1})，驗證 ∂_{d-1} ∘ ∂_d = 0、
//      退化子複形閉包 ∂(D_d) ⊆ D_{d-1}（Moore 正規化商 C_•/D_• ≅ N_•），以及
//      3 維立方胞腔鏈複形 (C_0=8, C_1=12, C_2=6, C_3=1) 之精確秩-零化度譜不變量
//      β_0(I^3)=1, β_1=β_2=β_3=0（高階 Hodge 拉普拉斯無零特徵值共振 ⇔ 可縮性）。
//   3. [T-Bidirectional-Cubical-NF-Pruning] 結合「自頂向下上纖維化面約束傳播（剔除矛盾管枝）」
//      與「自底向上退化／同分支折疊 + DTermInternTable DAG 駐留」，並由受信任核心
//      @kernel.conv_at_under_face 證明修剪前後在活躍面約束下嚴格定義等價！

///|
/// 立方退化樹節點（軸索引由高至低 `d-1 .. 0` 規範排序）。
#derive(Debug, Eq)
pub(all) enum CubicalDegeneracyTree {
  DTLeaf(Bool)
  DTDegenerate(Int32, CubicalDegeneracyTree)
  DTSplit(Int32, CubicalDegeneracyTree, CubicalDegeneracyTree)
}

///|
pub extend CubicalDegeneracyTree with @debug.Debug::{to_repr}

///|
pub extend CubicalDegeneracyTree with Eq::{not_equal, equal}

///|
/// 高維交錯立方體面算子與胞腔 Hodge 譜審計報告。
#derive(Debug, Eq)
pub(all) struct HighDimAlternatingCubeReport {
  dtree_swar_mask_bijection_ok : Bool
  dtree_cubical_identities_ok : Bool
  d5_alternating_d_squared_zero_ok : Bool
  moore_degenerate_quotient_closed_ok : Bool
  cube3_betti_numbers : Array[Int32]
  cube3_higher_laplacian_nonsingular_ok : Bool
}

///|
pub extend HighDimAlternatingCubeReport with @debug.Debug::{to_repr}

///|
pub extend HighDimAlternatingCubeReport with Eq::{not_equal, equal}

///|
/// 立方範式雙向修剪報告。
#derive(Debug, Eq)
pub(all) struct BidirectionalNfPruneReport {
  raw_tree_nodes : Int32
  pruned_tree_nodes : Int32
  pruned_dag_unique_nodes : Int32
  raw_tube_branches : Int32
  pruned_tube_branches : Int32
  swar_face_prune_agreed : Bool
  kernel_conv_under_face_ok : Bool
  negative_wrong_branch_rejected : Bool
}

///|
pub extend BidirectionalNfPruneReport with @debug.Debug::{to_repr}

///|
pub extend BidirectionalNfPruneReport with Eq::{not_equal, equal}

///|
/// 規範建構單層立方退化樹節點：若 `lo == hi` 立即折疊為 `DTDegenerate(axis, lo)`。
pub fn mk_dtree_node(
  axis : Int32,
  lo : CubicalDegeneracyTree,
  hi : CubicalDegeneracyTree,
) -> CubicalDegeneracyTree {
  if lo == hi {
    DTDegenerate(axis, lo)
  } else {
    DTSplit(axis, lo, hi)
  }
}

///|
/// 由 64-bit 布林立方體真值字組（`dim ∈ 0..6`）建構規範 `CubicalDegeneracyTree`。
pub fn dtree_from_cube64(dim : Int32, word : UInt64) -> CubicalDegeneracyTree {
  fn build(ax : Int32, base_idx : Int32) -> CubicalDegeneracyTree {
    if ax < 0 {
      let bit = ((word >> base_idx) & 1UL) == 1UL
      DTLeaf(bit)
    } else {
      let stride = 1 << ax
      let lo = build(ax - 1, base_idx)
      let hi = build(ax - 1, base_idx + stride)
      mk_dtree_node(ax, lo, hi)
    }
  }
  build(dim - 1, 0)
}

///|
/// 將 `CubicalDegeneracyTree` 還原為 64-bit 立方體真值字組。
pub fn dtree_to_cube64(dim : Int32, tree : CubicalDegeneracyTree) -> UInt64 {
  fn eval_pt(t : CubicalDegeneracyTree, pt_mask : Int32) -> Bool {
    match t {
      DTLeaf(b) => b
      DTDegenerate(_, child) => eval_pt(child, pt_mask)
      DTSplit(ax, lo, hi) =>
        if ((pt_mask >> ax) & 1) == 0 {
          eval_pt(lo, pt_mask)
        } else {
          eval_pt(hi, pt_mask)
        }
    }
  }
  let n_verts = 1 << dim
  let mut w = 0UL
  for v in 0..<n_verts {
    if eval_pt(tree, v) {
      w = w | (1UL << v)
    }
  }
  w
}

///|
/// 計算 `CubicalDegeneracyTree` 之節點總數（衡量退化壓縮率）。
pub fn dtree_node_count(tree : CubicalDegeneracyTree) -> Int32 {
  match tree {
    DTLeaf(_) => 1
    DTDegenerate(_, ch) => 1 + dtree_node_count(ch)
    DTSplit(_, lo, hi) => 1 + dtree_node_count(lo) + dtree_node_count(hi)
  }
}

///|
/// 提取退化樹在全部軸上皆全等之退化軸位元遮罩（精確判定第 `k` 軸是否退化）。
pub fn dtree_degeneracy_mask(
  dim : Int32,
  tree : CubicalDegeneracyTree,
) -> Int32 {
  fn is_indep(t : CubicalDegeneracyTree, target_ax : Int32) -> Bool {
    match t {
      DTLeaf(_) => true
      DTDegenerate(ax, ch) =>
        if ax == target_ax {
          true
        } else {
          is_indep(ch, target_ax)
        }
      DTSplit(ax, lo, hi) =>
        if ax == target_ax {
          false
        } else {
          is_indep(lo, target_ax) && is_indep(hi, target_ax)
        }
    }
  }
  let mut mask = 0
  for k in 0..<dim {
    if is_indep(tree, k) {
      mask = mask | (1 << k)
    }
  }
  mask
}

///|
/// 在 `CubicalDegeneracyTree` 上直接執行面算子 `∂_{k, side}`（無需展開 2^d 真值表）。
pub fn dtree_face(
  tree : CubicalDegeneracyTree,
  k : Int32,
  side : Int32,
) -> CubicalDegeneracyTree {
  match tree {
    DTLeaf(b) => DTLeaf(b)
    DTDegenerate(ax, ch) =>
      if ax == k {
        ch
      } else if ax > k {
        DTDegenerate(ax - 1, dtree_face(ch, k, side))
      } else {
        DTDegenerate(ax, ch)
      }
    DTSplit(ax, lo, hi) =>
      if ax == k {
        if side == 0 {
          lo
        } else {
          hi
        }
      } else if ax > k {
        mk_dtree_node(ax - 1, dtree_face(lo, k, side), dtree_face(hi, k, side))
      } else {
        DTSplit(ax, lo, hi)
      }
  }
}

///|
/// 在 `CubicalDegeneracyTree` 上直接插入退化軸 `σ_k`（O(depth) 結構共享）。
pub fn dtree_degeneracy(
  tree : CubicalDegeneracyTree,
  k : Int32,
) -> CubicalDegeneracyTree {
  fn shift_up(
    t : CubicalDegeneracyTree,
    target : Int32,
  ) -> CubicalDegeneracyTree {
    match t {
      DTLeaf(b) => DTDegenerate(target, DTLeaf(b))
      DTDegenerate(ax, ch) =>
        if ax >= target {
          DTDegenerate(ax + 1, shift_up(ch, target))
        } else {
          DTDegenerate(target, t)
        }
      DTSplit(ax, lo, hi) =>
        if ax >= target {
          mk_dtree_node(ax + 1, shift_up(lo, target), shift_up(hi, target))
        } else {
          DTDegenerate(target, t)
        }
    }
  }
  shift_up(tree, k)
}

///|
/// 計算整數矩陣（小規模精確高斯消去，使用有理分母無溢位行化簡）之秩 `rank(M)`。
fn exact_int_matrix_rank(
  rows : Int32,
  cols : Int32,
  mat_in : Array[Array[Int32]],
) -> Int32 {
  let m : Array[Array[Int64]] = []
  for r in 0..<rows {
    let row = Array::make(cols, 0L)
    for c in 0..<cols {
      row[c] = mat_in[r][c].to_int64()
    }
    m.push(row)
  }
  let mut rank = 0
  let mut pivot_row = 0
  for col in 0..<cols {
    if pivot_row >= rows {
      break
    }
    let mut sel = -1
    for r in pivot_row..<rows {
      if m[r][col] != 0L {
        sel = r
        break
      }
    }
    if sel >= 0 {
      if sel != pivot_row {
        let tmp = m[pivot_row]
        m[pivot_row] = m[sel]
        m[sel] = tmp
      }
      let pv = m[pivot_row][col]
      for r in 0..<rows {
        if r != pivot_row && m[r][col] != 0L {
          let factor = m[r][col]
          for c in col..<cols {
            m[r][c] = m[r][c] * pv - factor * m[pivot_row][c]
          }
          // 以列 GCD 約分，防止係數膨脹
          let mut g = 0L
          for c in col..<cols {
            let av = if m[r][c] < 0L { -m[r][c] } else { m[r][c] }
            if av != 0L {
              let mut a = g
              let mut b = av
              while b != 0L {
                let rem = a % b
                a = b
                b = rem
              }
              g = a
            }
          }
          if g > 1L {
            for c in col..<cols {
              m[r][c] = m[r][c] / g
            }
          }
        }
      }
      pivot_row = pivot_row + 1
      rank = rank + 1
    }
  }
  rank
}

///|
/// 驗證立方退化樹、5 維交錯立方體面微分 `∂² = 0`、Moore 退化子複形商與 3 維立方體 Hodge 譜不變量。
pub fn verify_high_dim_alternating_cube_and_dtree() -> HighDimAlternatingCubeReport {
  // 1. 對 3 維全體 2^(2^3) = 256 個立方體逐一檢驗退化樹遮罩與 @accel.cube64_degeneracy_mask 全等
  let mut bij_ok = true
  for w_i in 0..<256 {
    let w = w_i.to_uint64()
    let dt = dtree_from_cube64(3, w)
    let w_back = dtree_to_cube64(3, dt)
    let m_tree = dtree_degeneracy_mask(3, dt)
    let m_swar = @accel.cube64_degeneracy_mask(w, 3).to_int()
    if w_back != w || m_tree != m_swar {
      bij_ok = false
    }
  }
  // 完全常數 5-立方體（32 頂點全 true）在退化樹中僅佔 6 個節點（5 層 DTDegenerate + 1 葉），而非 63 節點滿二元樹！
  let const5 = dtree_from_cube64(5, 0xFFFFFFFFUL)
  if dtree_node_count(const5) != 6 {
    bij_ok = false
  }

  // 2. 退化樹直接面算子與退化算子滿足全套立方恆等式並與 SWAR 逐位一致
  let mut cid_ok = true
  let sample4 : UInt64 = 0x9669_A55AUL & 0xFFFFUL
  let t4 = dtree_from_cube64(4, sample4)
  for j in 0..<4 {
    for i in 0..<j {
      for e1 in 0..<2 {
        for e2 in 0..<2 {
          if dtree_face(dtree_face(t4, j, e1), i, e2) !=
            dtree_face(dtree_face(t4, i, e2), j - 1, e1) {
            cid_ok = false
          }
        }
      }
    }
  }
  for k in 0..<4 {
    let deg_t = dtree_degeneracy(t4, k)
    if dtree_face(deg_t, k, 0) != t4 || dtree_face(deg_t, k, 1) != t4 {
      cid_ok = false
    }
    let swar_deg = @accel.cube64_insert_degeneracy_swar(sample4, 5, k)
    if dtree_to_cube64(5, deg_t) != swar_deg {
      cid_ok = false
    }
  }

  // 3. 高維 d = 5（32 頂點超立方體）交錯面算子 ∂_4 ∘ ∂_5 == 0 驗證
  let sample5 : UInt64 = 0xCAFE_BABEUL
  let bd5 = @accel.cube64_alternating_boundary_zchain(sample5, 5)
  let bd4 = @accel.cube64_chain_boundary(bd5, 4)
  let d5_ok = bd4.length() == 0

  // 4. Moore 退化子複形閉包：對任意退化 5-立方體 σ_k(t4)，其交錯邊界之每一殘留項皆仍為退化 4-立方體
  let mut moore_ok = true
  for k in 0..<5 {
    let deg5 = @accel.cube64_insert_degeneracy_swar(sample4, 5, k)
    let chain4 = @accel.cube64_alternating_boundary_zchain(deg5, 5)
    for item in chain4 {
      if @accel.cube64_degeneracy_mask(item.0, 4) == 0UL {
        moore_ok = false
      }
    }
  }

  // 5. 3 維幾何立方體胞腔複形 I^3：8 個 0-胞（頂點）、12 個 1-胞（邊）、6 個 2-胞（面）、1 個 3-胞（體）
  //    建構精確邊界矩陣 B1 (8×12), B2 (12×6), B3 (6×1)，驗證 B1·B2=0, B2·B3=0 與 Betti 數 [1, 0, 0, 0]！
  // 邊編碼：(axis ∈ 0..2, 固定其餘兩軸之 2-bit mask ∈ 0..3)，共 3*4 = 12 邊
  let b1 : Array[Array[Int32]] = []
  for _ in 0..<8 {
    b1.push(Array::make(12, 0))
  }
  for ax in 0..<3 {
    for rem in 0..<4 {
      let eid = ax * 4 + rem
      let insert_bit = fn(r : Int32, bit : Int32) -> Int32 {
        let lo = r & ((1 << ax) - 1)
        let hi = r >> ax
        lo | (bit << ax) | (hi << (ax + 1))
      }
      let v0 = insert_bit(rem, 0)
      let v1 = insert_bit(rem, 1)
      // ∂_1(e) = ∂_{0,0}(e) - ∂_{0,1}(e) = v0 - v1
      b1[v0][eid] = 1
      b1[v1][eid] = -1
    }
  }
  // 2-胞編碼：(固定軸 fixed_ax ∈ 0..2, side ∈ 0..1)，共 6 個正方形面
  // 每個 2-胞有兩條自由軸 (a < b)，其交錯邊界為 (∂_{0,0} - ∂_{0,1}) - (∂_{1,0} - ∂_{1,1})
  let b2 : Array[Array[Int32]] = []
  for _ in 0..<12 {
    b2.push(Array::make(6, 0))
  }
  for fixed_ax in 0..<3 {
    let free_axes : Array[Int32] = []
    for x in 0..<3 {
      if x != fixed_ax {
        free_axes.push(x)
      }
    }
    let a = free_axes[0]
    let b = free_axes[1]
    for side in 0..<2 {
      let fid = fixed_ax * 2 + side
      // local k=0 固定 a=e_s，剩下自由軸為 b；local k=1 固定 b=e_s，剩下自由軸為 a
      for local_k in 0..<2 {
        let sign_k = if local_k == 0 { 1 } else { -1 }
        let cut_ax = if local_k == 0 { a } else { b }
        let rem_ax = if local_k == 0 { b } else { a }
        for e_s in 0..<2 {
          let coeff = if e_s == 0 { sign_k } else { -sign_k }
          // 計算此 1-胞在全體 12 邊中的 (rem_ax, rem_2bits)
          let other_bits : Array[Int32] = []
          for x in 0..<3 {
            if x != rem_ax {
              if x == fixed_ax {
                other_bits.push(side)
              } else if x == cut_ax {
                other_bits.push(e_s)
              }
            }
          }
          let rem_mask = other_bits[0] | (other_bits[1] << 1)
          let eid = rem_ax * 4 + rem_mask
          b2[eid][fid] = coeff
        }
      }
    }
  }
  // 3-胞邊界 B3 (6×1)：∑_{k=0..2} (-1)^k (F_{k,0} - F_{k,1})
  let b3 : Array[Array[Int32]] = []
  for fixed_ax in 0..<3 {
    let sgn = if fixed_ax % 2 == 0 { 1 } else { -1 }
    b3.push([sgn])
    b3.push([-sgn])
  }

  let mut chain_zero_ok = true
  for v in 0..<8 {
    for f in 0..<6 {
      let mut s = 0
      for e in 0..<12 {
        s = s + b1[v][e] * b2[e][f]
      }
      if s != 0 {
        chain_zero_ok = false
      }
    }
  }
  for e in 0..<12 {
    let mut s = 0
    for f in 0..<6 {
      s = s + b2[e][f] * b3[f][0]
    }
    if s != 0 {
      chain_zero_ok = false
    }
  }

  let r1 = exact_int_matrix_rank(8, 12, b1)
  let r2 = exact_int_matrix_rank(12, 6, b2)
  let r3 = exact_int_matrix_rank(6, 1, b3)
  let betti0 = 8 - r1
  let betti1 = 12 - r1 - r2
  let betti2 = 6 - r2 - r3
  let betti3 = 1 - r3
  let betti = [betti0, betti1, betti2, betti3]

  HighDimAlternatingCubeReport::{
    dtree_swar_mask_bijection_ok: bij_ok,
    dtree_cubical_identities_ok: cid_ok,
    d5_alternating_d_squared_zero_ok: d5_ok,
    moore_degenerate_quotient_closed_ok: moore_ok,
    cube3_betti_numbers: betti,
    cube3_higher_laplacian_nonsingular_ok: chain_zero_ok &&
    betti == [1, 0, 0, 0],
  }
}

///|
/// 立方語法範式雙向修剪器：
///   - 自頂向下（Top-Down）：傳播活躍上纖維化面約束 `ctx_face`，剔除與 `ctx_face` 矛盾之 `DHComp`/`DComp`/`DPartial` 管枝；
///   - 自底向上（Bottom-Up）：消去同分支 `DBoolElim` 冗餘分歧與常數維度應用。
pub fn bidirectional_prune_cubical_dterm(
  term : @kernel.DTerm,
  ctx_face : @face_bdd.Face,
  n_dims : Int32,
) -> @kernel.DTerm {
  fn go(t : @kernel.DTerm, phi : @face_bdd.Face) -> @kernel.DTerm {
    match t {
      DHComp(ty, tubes, base) => {
        let ty_p = go(ty, phi)
        let base_p = go(base, phi)
        let kept : Array[@kernel.DTubeTerm] = []
        for tb in tubes {
          let joint = @face_bdd.face_and(phi, tb.face)
          if @face_bdd.face_sat(joint, n_dims) {
            let body_p = go(tb.body, joint)
            // 若在活躍上下文下 φ ≤ tb.face，該管枝覆蓋整個上下文，後續被遮蔽分支無需保留
            if @face_bdd.face_le(phi, tb.face, n_dims) {
              kept.push(@kernel.d_tube(FTop, body_p))
              break
            } else {
              kept.push(@kernel.d_tube(tb.face, body_p))
            }
          }
        }
        DHComp(ty_p, kept, base_p)
      }
      DBoolElim(motive, tr_br, fa_br, scrut) => {
        let m_p = go(motive, phi)
        let t_p = go(tr_br, phi)
        let f_p = go(fa_br, phi)
        let s_p = go(scrut, phi)
        // 自底向上：若兩分支修剪後語法全等或判別式為字面量，直接收縮！
        match s_p {
          DBoolLit(true) => t_p
          DBoolLit(false) => f_p
          _ => if t_p == f_p { t_p } else { DBoolElim(m_p, t_p, f_p, s_p) }
        }
      }
      DAppDim(DLamDim(body), d) => {
        let d_simp = @face_bdd.dim_simplify(d)
        let body_p = go(body, phi)
        // 若 body 不引用維度變數 0，直接消去退化 DLamDim/DAppDim 往返！
        let used = @kernel.dterm_dim_vars(body_p)
        if !@face_bdd.contains_int(used, 0) {
          body_p
        } else {
          DAppDim(DLamDim(body_p), d_simp)
        }
      }
      _ => {
        let chs = @kernel.dterm_children(t)
        if chs.length() == 0 {
          t
        } else {
          let chs_p : Array[@kernel.DTerm] = []
          for c in chs {
            chs_p.push(go(c, phi))
          }
          @kernel.dterm_rebuild(t, chs_p)
        }
      }
    }
  }
  go(term, ctx_face)
}

///|
/// 執行立方範式雙向修剪與受信任核心面下定義等價驗證（含 SWAR 對照與負對照）。
pub fn verify_bidirectional_cubical_nf_pruning() -> BidirectionalNfPruneReport {
  let n_dims = 2
  // 活躍上下文面約束 φ := (i0 = 0)
  let ctx_face = @face_bdd.face_var0(0)

  // 構造含以下三類冗餘之未修剪立方項（開區間環境 dlevel = 2，含 i0=DVar(0), i1=DVar(1)）：
  //   1. 管枝 1（i0 = 1）：與活躍面 i0 = 0 矛盾，應被自頂向下剔除！
  //   2. 管枝 2（i0 = 0 ∧ i1 = 0）：在 i0 = 0 下可滿足，保留且其內部含退化維度應用與同分支 DBoolElim！
  //   3. 管枝 3（i0 = 1 ∧ i1 = 1）：與活躍面矛盾，應被剔除！
  let redundant_true = @kernel.DTerm::DBoolElim(
    @kernel.DTerm::DLam(@kernel.DTerm::DBoolTy, @kernel.DTerm::DBoolTy),
    @kernel.DTerm::DAppDim(
      @kernel.DTerm::DLamDim(@kernel.DTerm::DBoolLit(true)),
      DVar(1),
    ),
    @kernel.DTerm::DBoolLit(true),
    @kernel.DTerm::DBoolLit(true),
  )
  let f_contradict1 = @face_bdd.face_var1(0)
  let f_active2 = @face_bdd.face_and(
    @face_bdd.face_var0(0),
    @face_bdd.face_var0(1),
  )
  let f_contradict3 = @face_bdd.face_and(
    @face_bdd.face_var1(0),
    @face_bdd.face_var1(1),
  )
  // DTubeTerm.body 在求值時自動在前端壓入管軸變數 d，故管體直接為 Bool 項
  let raw_tubes = [
    @kernel.d_tube(f_contradict1, DBoolLit(false)),
    @kernel.d_tube(f_active2, redundant_true),
    @kernel.d_tube(f_contradict3, DBoolLit(false)),
  ]
  let raw_term = @kernel.DTerm::DHComp(DBoolTy, raw_tubes, redundant_true)
  let pruned_term = bidirectional_prune_cubical_dterm(
    raw_term, ctx_face, n_dims,
  )

  let raw_nodes = @kernel.dterm_tree_node_count(raw_term)
  let pruned_nodes = @kernel.dterm_tree_node_count(pruned_term)
  let intern_tbl = @kernel.dterm_intern_table_new()
  let _ = @kernel.dterm_intern(intern_tbl, pruned_term)
  let dag_unique = @kernel.dterm_intern_table_size(intern_tbl)

  let pruned_tubes_count = match pruned_term {
    DHComp(_, tbs, _) => tbs.length()
    _ => -1
  }

  // 與 @accel.cube64_bidirectional_face_prune SWAR 64-bit 雙向修剪結果對照
  let (_, _, cnt1) = @accel.cube64_bidirectional_face_prune(
    f_contradict1, ctx_face, n_dims,
  )
  let (_, ess2, cnt2) = @accel.cube64_bidirectional_face_prune(
    f_active2, ctx_face, n_dims,
  )
  let (_, _, cnt3) = @accel.cube64_bidirectional_face_prune(
    f_contradict3, ctx_face, n_dims,
  )
  let swar_ok = cnt1 == 0 && cnt2 == 1 && cnt3 == 0 && ess2 == 3UL

  // 受信任核心檢驗：在 denv = [DVar(0), DVar(1)] 與活躍面 ctx_face (i0 = 0) 下求值並執行 conv_at_under_face！
  let denv2 = @kernel.ddim_from_array([DVar(0), DVar(1)])
  let v_raw = @kernel.deval_dim(raw_term, @kernel.denv_empty(), denv2)
  let v_pruned = @kernel.deval_dim(pruned_term, @kernel.denv_empty(), denv2)
  let conv_ok = @kernel.conv_at_under_face(
    0,
    2,
    ctx_face,
    DVBoolTy,
    v_raw,
    v_pruned,
  )

  // 負對照：若將基底偽改為 false，受信任核心在 ctx_face 下必須拒絕定義等價！
  let wrong_term = @kernel.DTerm::DBoolLit(false)
  let v_wrong = @kernel.deval_dim(wrong_term, @kernel.denv_empty(), denv2)
  let wrong_rejected = !@kernel.conv_at_under_face(
    0,
    2,
    ctx_face,
    DVBoolTy,
    v_raw,
    v_wrong,
  )

  BidirectionalNfPruneReport::{
    raw_tree_nodes: raw_nodes,
    pruned_tree_nodes: pruned_nodes,
    pruned_dag_unique_nodes: dag_unique,
    raw_tube_branches: raw_tubes.length(),
    pruned_tube_branches: pruned_tubes_count,
    swar_face_prune_agreed: swar_ok,
    kernel_conv_under_face_ok: conv_ok && pruned_nodes < raw_nodes,
    negative_wrong_branch_rejected: wrong_rejected,
  }
}
