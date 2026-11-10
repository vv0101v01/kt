// ---------------------------------------------------------------------------
// cubical/structures — 一般泛覆蓋空間、甲板自同構態射群、覆蓋空間基本伽羅瓦對應、
// 同倫推出母構造與整係數史密斯正規形（SNF）撓元同調（圓／環面／懸置／射影平面）
// ---------------------------------------------------------------------------
//
// 落實《工作內容4.md》核心結構：
//   - #12 懸置與推出空間（同倫推出母構造 `A ⊔^h_C B` 統一導出懸置、楔和、映射錐與環面）
//   - #17 自同構態射群（覆蓋空間甲板變換群 `Aut_p(E)` 與 `@sym.Perm` 置換群精確計算）
//   - #25 泛覆蓋空間（離散 Grothendieck 纖維化、唯一路徑提升、2-胞同倫不變性、覆蓋伽羅瓦基本定理）
//   - #42/#43/#44/#45/#46 立方體高階歸納類型、點構造子、路徑構造子、環面與圓面 `T^2 ≃ S^1 × S^1`、懸置類型
//
// 交互運用之 26 動詞與 14 組範疇組合範例：
//   - [V05 嵌入 × V10 鏡像對稱 × C06 Grothendieck 纖維化 × C08 半直積／非阿貝爾群作用]：
//     構造非阿貝爾商基本群 `G = S_3`（6 階，由 `S^1 ∨ S^1` 附加 `a^2 = b^2 = (ab)^3 = 1` 呈示）之全部
//     **6 個子群**對應之基點連通覆蓋空間，機器證明 `[T-Galois-Covering]`：
//     - 子群格 `Sub(S_3)` 與基點覆蓋構成嚴格反序伽羅瓦雙射（階數 × 葉數 = 6）；
//     - 正規子群 `{e}, A_3, S_3` 滿足伽羅瓦正則性 `|Aut_p(E_N)| == [S_3 : N]`（`6, 2, 1`）；
//     - 3 個二階非正規子群滿足 `|Aut_p(E_H)| == [N_{S_3}(H) : H] == 1 < 3 == [S_3 : H]`（精確非正則負對照！）。
//   - [V06 聯動 × V13 複形 × C05 張量—加法對偶 × C07 推出 × C13 Ext 短正合列]：
//     聯動 `@gcd.zmat_snf` 計算整係數胞腔鏈複形史密斯正規形，精確抓出 `RP^2` 的二階撓同調
//     `H_1(RP^2; Z) ≅ Z/2Z`（不變因子 `2`）與 `T^2` 的 Künneth 張量積同調 `[1, 2, 1]`（`χ = 0`）。

///|
/// 覆蓋空間離散纖維化 `p : E -> B`：底空間生成迴圈 `a_0, ..., a_{r-1}` 透過單值（monodromy）置換
/// `gen_perms : Array[@sym.Perm]` 作用於纖維集 `{0 .. n_sheets - 1}`，並附帶 2-胞關係字組 `relators`
///（正整數 `+k` 表第 `k-1` 生成元，負整數 `-k` 表其逆元）。
#derive(Debug, Eq)
pub(all) struct DiscreteCoveringSpace {
  name : String
  n_sheets : Int32
  base_sheet : Int32
  gen_perms : Array[@sym.Perm]
  relators : Array[Array[Int32]]
}

///|
pub extend DiscreteCoveringSpace with @debug.Debug::{to_repr}

///|
pub extend DiscreteCoveringSpace with Eq::{not_equal, equal}

///|
/// 唯一路徑提升演算法（Unique Path Lifting）：給定起點葉 `start_sheet` 與底空間帶號生成元路徑字 `word`，
/// 計算唯一提升路徑之終點葉（`O(|word|)` 常數因子查表）。
pub fn covering_lift_word(
  cov : DiscreteCoveringSpace,
  start_sheet : Int32,
  word : Array[Int32],
) -> Int32 {
  let mut cur = start_sheet
  for step in word {
    if step > 0 {
      let g = cov.gen_perms[step - 1]
      cur = g.apply(cur)
    } else if step < 0 {
      let g_inv = cov.gen_perms[-step - 1].inverse()
      cur = g_inv.apply(cur)
    }
  }
  cur
}

///|
/// 檢驗 2-胞同倫提升不變性：底空間每個 2-胞邊界關係字 `r ∈ relators` 從任意葉提升後必回到同一葉
///（即單值置換群作用良定義於商基本群 `π_1(B)`）。
pub fn covering_2cell_homotopy_invariant(cov : DiscreteCoveringSpace) -> Bool {
  for r in cov.relators {
    for s in 0..<cov.n_sheets {
      if covering_lift_word(cov, s, r) != s {
        return false
      }
    }
  }
  true
}

///|
/// 判定覆蓋空間 `E` 是否道路連通（從 `base_sheet` 出發經生成元與逆元 BFS 可達全部 `n_sheets` 葉）。
pub fn covering_is_connected(cov : DiscreteCoveringSpace) -> Bool {
  if cov.n_sheets <= 0 {
    return false
  }
  let visited = Array::make(cov.n_sheets, false)
  let queue : Array[Int32] = [cov.base_sheet]
  visited[cov.base_sheet] = true
  let mut head = 0
  while head < queue.length() {
    let u = queue[head]
    head = head + 1
    for g in cov.gen_perms {
      let v1 = g.apply(u)
      if !visited[v1] {
        visited[v1] = true
        queue.push(v1)
      }
      let v2 = g.inverse().apply(u)
      if !visited[v2] {
        visited[v2] = true
        queue.push(v2)
      }
    }
  }
  queue.length() == cov.n_sheets
}

///|
/// 計算連通覆蓋空間之甲板自同構態射群 `Aut_p(E)`（所有與全部單值生成元可交換之纖維雙射 `τ : F -> F`）。
/// 定理：因 `E` 連通，任何甲板變換由其在 `base_sheet` 之影像 `τ(base_sheet)` 唯一決定，
/// 故可在 `O(n_sheets^2 · |gens|)` 多項式時間內精確構造完整甲板自同構群（絕不需枚舉 `n!`）！
pub fn covering_deck_automorphisms(
  cov : DiscreteCoveringSpace,
) -> Array[@sym.Perm] {
  let n = cov.n_sheets
  let autos : Array[@sym.Perm] = []
  for target0 in 0..<n {
    let img = Array::make(n, -1)
    img[cov.base_sheet] = target0
    let queue : Array[Int32] = [cov.base_sheet]
    let mut head = 0
    let mut consistent = true
    while head < queue.length() && consistent {
      let u = queue[head]
      head = head + 1
      let tu = img[u]
      for g in cov.gen_perms {
        let gu = g.apply(u)
        let g_tu = g.apply(tu)
        if img[gu] == -1 {
          img[gu] = g_tu
          queue.push(gu)
        } else if img[gu] != g_tu {
          consistent = false
          break
        }
        let gi = g.inverse()
        let gi_u = gi.apply(u)
        let gi_tu = gi.apply(tu)
        if img[gi_u] == -1 {
          img[gi_u] = gi_tu
          queue.push(gi_u)
        } else if img[gi_u] != gi_tu {
          consistent = false
          break
        }
      }
    }
    if consistent {
      // 驗證滿射（雙射性）
      let seen = Array::make(n, false)
      let mut bij = true
      for x in img {
        if x < 0 || x >= n || seen[x] {
          bij = false
          break
        }
        seen[x] = true
      }
      if bij {
        autos.push(@sym.Perm::from_img(img))
      }
    }
  }
  autos
}

///|
/// 整係數有限胞腔複形（由點／路徑／高維面構造子導出之同倫推出複形）：
/// `dims_ranks` 為各維度自由阿貝爾鏈群秩 `[c_0, c_1, c_2, ...]`，
/// `boundaries[k]` 為 `∂_{k+1} : C_{k+1} -> C_k` 之 `c_k × c_{k+1}` 整數矩陣。
#derive(Debug, Eq)
pub(all) struct IntegralCellularComplex {
  name : String
  cell_ranks : Array[Int32]
  boundaries : Array[Array[Array[Int32]]]
}

///|
pub extend IntegralCellularComplex with @debug.Debug::{to_repr}

///|
pub extend IntegralCellularComplex with Eq::{not_equal, equal}

///|
/// 整係數同調群計算結果：每一維度 `k` 之自由秩 `betti_free[k]` 與大於 1 之史密斯撓元不變因子 `torsion[k]`。
#derive(Debug, Eq)
pub(all) struct IntegralHomologyReport {
  chain_boundary_sq_zero : Bool
  euler_characteristic : Int32
  betti_free : Array[Int32]
  torsion_factors : Array[Array[Int32]]
}

///|
pub extend IntegralHomologyReport with @debug.Debug::{to_repr}

///|
pub extend IntegralHomologyReport with Eq::{not_equal, equal}

///|
/// 聯動 `@gcd.zmat_snf` 史密斯正規形計算任意有限胞腔複形之精確整係數同調群
/// `H_k(X; Z) ≅ Z^{β_k} ⊕ ⨁_j (Z / d_{k,j} Z)`！
pub fn compute_integral_cellular_homology(
  cx : IntegralCellularComplex,
) -> IntegralHomologyReport {
  let max_d = cx.cell_ranks.length()
  let ranks = Array::make(max_d, 0)
  let torsions : Array[Array[Int32]] = []
  for _ in 0..<max_d {
    torsions.push([])
  }

  // 1. 檢驗 ∂_k ∘ ∂_{k+1} == 0
  let mut sq_zero = true
  for k in 0..<(cx.boundaries.length() - 1) {
    let dk = @gcd.zmat_from_int_rows(cx.boundaries[k])
    let dkp1 = @gcd.zmat_from_int_rows(cx.boundaries[k + 1])
    let prod = @gcd.zmat_mul(dk, dkp1)
    for entry in prod.data {
      if entry != @bigint.BigInt::from_int(0) {
        sq_zero = false
      }
    }
  }

  // 2. 對每個邊界矩陣 ∂_{k+1} 求史密斯正規形 SNF，取得秩 r_{k+1} 與撓不變因子 d_i > 1
  let bd_ranks = Array::make(max_d + 1, 0)
  for k in 0..<cx.boundaries.length() {
    let rows = cx.boundaries[k]
    if rows.length() > 0 && rows[0].length() > 0 {
      let zm = @gcd.zmat_from_int_rows(rows)
      let snf = @gcd.zmat_snf(zm)
      if !@gcd.zmat_snf_verify(zm, snf) {
        sq_zero = false
      }
      bd_ranks[k + 1] = snf.rank
      let one_bi = @bigint.BigInt::from_int(1)
      let zero_bi = @bigint.BigInt::from_int(0)
      for d_bi in snf.diag {
        let abs_d = @gcd.ugcd_bigint_abs(d_bi)
        if abs_d > one_bi && abs_d != zero_bi {
          torsions[k].push(abs_d.to_int())
        }
      }
    }
  }

  // 3. β_k = dim(ker ∂_k) - dim(im ∂_{k+1}) = (c_k - r_k) - r_{k+1}，以及歐拉示性數对帳
  let mut euler_cells = 0
  let mut euler_betti = 0
  for k in 0..<max_d {
    let sign = if k % 2 == 0 { 1 } else { -1 }
    ranks[k] = cx.cell_ranks[k] - bd_ranks[k] - bd_ranks[k + 1]
    euler_cells = euler_cells + sign * cx.cell_ranks[k]
    euler_betti = euler_betti + sign * ranks[k]
  }
  if euler_cells != euler_betti {
    sq_zero = false
  }

  IntegralHomologyReport::{
    chain_boundary_sq_zero: sq_zero,
    euler_characteristic: euler_cells,
    betti_free: ranks,
    torsion_factors: torsions,
  }
}

///|
/// 泛覆蓋空間伽羅瓦對應、甲板自同構群、同倫推出與整係數撓同調驗證報告。
#derive(Debug, Eq)
pub(all) struct CoveringPushoutTorusReport {
  s3_pointed_coverings_count : Int32
  s3_galois_normal_deck_orders : Array[Int32]
  s3_nonnormal_deck_orders : Array[Int32]
  galois_covering_theorem_holds : Bool
  torus_commutator_lifts_closed_vs_wedge_open : Bool
  torus_s1_product_winding_pair : (Int32, Int32)
  susp_s1_gives_s2_betti : Array[Int32]
  torus_betti_kunneth : Array[Int32]
  rp2_h1_two_torsion_factors : Array[Int32]
}

///|
pub extend CoveringPushoutTorusReport with @debug.Debug::{to_repr}

///|
pub extend CoveringPushoutTorusReport with Eq::{not_equal, equal}

///|
/// 執行泛覆蓋空間、非阿貝爾 `S_3` 伽羅瓦覆蓋對應、環面 `T^2 ≃ S^1 × S^1`、懸置 `ΣS^1 ≃ S^2` 與 `RP^2` 撓同調驗證。
pub fn verify_covering_pushout_and_torus_suite() -> CoveringPushoutTorusReport {
  // 1. 構造非阿貝爾群 G = S_3（由對換 g1 = (0 1)、g2 = (1 2) 生成，階數 6）之全部 6 個子群 H <= S_3，
  //    並由右陪集作用構造對應之 6 個基點連通覆蓋空間 E_H -> B！
  let s3 = @sym.PermGroup::symmetric(3)
  let elems = s3.elements(16) // 6 個置換
  let g1 = @sym.Perm::from_cycles(3, [[0, 1]])
  let g2 = @sym.Perm::from_cycles(3, [[1, 2]])
  let id_p = @sym.Perm::identity(3)
  let c3_a = @sym.Perm::from_cycles(3, [[0, 1, 2]])
  let c3_b = @sym.Perm::from_cycles(3, [[0, 2, 1]])
  let t02 = @sym.Perm::from_cycles(3, [[0, 2]])

  // S_3 完整子群列表（6 個）：{e}、3 個二階對換子群、三階正規交錯子群 A_3、全群 S_3
  let subgroups : Array[(String, Bool, Array[@sym.Perm])] = [
    ("Trivial_{e}_UniversalCover", true, [id_p]),
    ("H_swap01", false, [id_p, g1]),
    ("H_swap12", false, [id_p, g2]),
    ("H_swap02", false, [id_p, t02]),
    ("Normal_A3", true, [id_p, c3_a, c3_b]),
    ("Full_S3_Base", true, elems),
  ]

  // 關係字：g1^2 = 1, g2^2 = 1, (g1*g2)^3 = 1
  let s3_relators : Array[Array[Int32]] = [[1, 1], [2, 2], [1, 2, 1, 2, 1, 2]]

  let normal_deck_orders : Array[Int32] = []
  let nonnormal_deck_orders : Array[Int32] = []
  let mut galois_ok = elems.length() == 6
  let mut univ_cov_opt : DiscreteCoveringSpace? = None

  for (sub_name, is_normal, h_elems) in subgroups {
    // 劃分右陪集 H \ S_3（每個陪集以最小元素索引排序作為規範葉編號，含 id_p 的陪集為 base_sheet）
    let cosets : Array[Array[@sym.Perm]] = []
    for g in elems {
      let mut found = false
      for cs in cosets {
        // 檢查 g 是否在已有陪集 H * rep 中
        for x in cs {
          if x == g {
            found = true
            break
          }
        }
        if found {
          break
        }
      }
      if !found {
        let new_cs : Array[@sym.Perm] = []
        for h in h_elems {
          new_cs.push(h.compose(g))
        }
        cosets.push(new_cs)
      }
    }
    let n_sheets = cosets.length()
    let mut base_s = 0
    for idx in 0..<n_sheets {
      for p in cosets[idx] {
        if p == id_p {
          base_s = idx
        }
      }
    }
    // 右乘單值作用：(H * x) · gen = H * (x ∘ gen)
    let make_monodromy = fn(gen : @sym.Perm) -> @sym.Perm {
      let img = Array::make(n_sheets, 0)
      for idx in 0..<n_sheets {
        let rep = cosets[idx][0]
        let prod = rep.compose(gen)
        for j in 0..<n_sheets {
          let mut hit = false
          for q in cosets[j] {
            if q == prod {
              hit = true
              break
            }
          }
          if hit {
            img[idx] = j
            break
          }
        }
      }
      @sym.Perm::from_img(img)
    }
    let cov = DiscreteCoveringSpace::{
      name: sub_name,
      n_sheets,
      base_sheet: base_s,
      gen_perms: [make_monodromy(g1), make_monodromy(g2)],
      relators: s3_relators,
    }
    if h_elems.length() == 1 {
      univ_cov_opt = Some(cov)
    }
    let conn = covering_is_connected(cov)
    let hom_inv = covering_2cell_homotopy_invariant(cov)
    let deck = covering_deck_automorphisms(cov)
    let deck_ord = deck.length()
    // 驗證 Lagrange 指標：|H| * n_sheets == 6
    if !conn || !hom_inv || h_elems.length() * n_sheets != 6 {
      galois_ok = false
    }
    if is_normal {
      normal_deck_orders.push(deck_ord)
      // 伽羅瓦覆蓋正則判準：N ◁ G ⇔ |Aut_p(E_N)| == [G : N] == n_sheets！
      if deck_ord != n_sheets {
        galois_ok = false
      }
    } else {
      nonnormal_deck_orders.push(deck_ord)
      // S_3 的二階子群自正規化 N_{S_3}(H) = H，故 |Aut_p(E_H)| = [N(H):H] = 1 < 3！
      if deck_ord != 1 || deck_ord >= n_sheets {
        galois_ok = false
      }
    }
  }

  // 2. 交換子路徑 `[a, b] = a b a^{-1} b^{-1}` 在環面 T^2 的 (3,2)-覆蓋（6 葉阿貝爾覆蓋）必閉合，
  //    而在 S^1 ∨ S^1 的 S_3 泛覆蓋（6 葉非阿貝爾覆蓋）提升為開路徑（3-循環位移，終點 != 起點）！
  let t2_cov = DiscreteCoveringSpace::{
    name: "Torus_3x2_Cover",
    n_sheets: 6,
    base_sheet: 0,
    gen_perms: [
      @sym.Perm::from_img([2, 3, 4, 5, 0, 1]), // +1 mod 3 on first factor
      @sym.Perm::from_img([1, 0, 3, 2, 5, 4]), // +1 mod 2 on second factor
    ],
    relators: [[1, 2, -1, -2]],
  }
  let comm_word : Array[Int32] = [1, 2, -1, -2]
  let t2_end = covering_lift_word(t2_cov, 0, comm_word)
  let wedge_end = match univ_cov_opt {
    Some(uc) => covering_lift_word(uc, uc.base_sheet, comm_word)
    None => 0
  }
  let comm_sep_ok = covering_2cell_homotopy_invariant(t2_cov) &&
    t2_end == 0 &&
    wedge_end !=
    (match univ_cov_opt {
      Some(uc) => uc.base_sheet
      None => -1
    })

  // 3. 環面 T^2 ≃ S^1 × S^1 在受信任立方核心中之雙軸繞數對 (w_1, w_2) = (2, -1) 驗證
  let lp = @homotopy.circle_hit_loop_path_value()
  let s1 = @homotopy.circle_hit_type_value()
  let lp2 = @homotopy.dpath_trans_value(s1, lp, lp, 0)
  let lp_m1 = @homotopy.dpath_sym_value(lp)
  let w1 = match @autonomy.univalent_circle_winding(lp2) {
    Some(v) => v
    None => 0
  }
  let w2 = match @autonomy.univalent_circle_winding(lp_m1) {
    Some(v) => v
    None => 0
  }

  // 4. 同倫推出母構造之整係數胞腔同調（聯動 `@gcd.zmat_snf`）：
  //    (a) 懸置 ΣS^1 ≃ S^2（2 個 0-胞 N,S；2 個 1-胞 m_0, m_1 滿足 ∂m_0 = ∂m_1 = S - N；
  //        2 個半球 2-胞滿足 ∂(H_+ - H_-) = m_0 - m_1 => 簡約為 1 個 0-胞、0 個 1-胞、1 個 2-胞或顯式推出鏈）：
  let susp_s1_cx = IntegralCellularComplex::{
    name: "Susp(S^1)_Pushout",
    cell_ranks: [2, 2, 2],
    boundaries: [
      [[-1, -1], [1, 1]], // ∂_1 : Z^2 -> Z^2 (m_base, m_loop 皆由 N 到 S，但 loop 誘導 2-胞邊界 m_base - m_base = 0, H_2 = Z)
      [[1, 1], [-1, -1]], // ∂_2 : 兩個 2-胞沿赤道貼合，ker(∂_2) 秩 = 1 => β = [1, 0, 1]！
    ],
  }
  let h_s2 = compute_integral_cellular_homology(susp_s1_cx)

  //    (b) 環面 T^2 = D^2 ⊔_{[p,q]} (S^1 ∨ S^1)：1 個 0-胞、2 個 1-胞 p,q（∂_1=0）、1 個 2-胞 surf（阿貝爾化 ∂_2=[0,0]^T）
  let torus_cx = IntegralCellularComplex::{
    name: "Torus_T2",
    cell_ranks: [1, 2, 1],
    boundaries: [[[0, 0]], [[0], [0]]],
  }
  let h_t2 = compute_integral_cellular_homology(torus_cx)

  //    (c) 實射影平面 RP^2 = D^2 ⊔_{×2} S^1：1 個 0-胞、1 個 1-胞 γ（∂_1=0）、1 個 2-胞（∂_2=[2]）
  //        史密斯正規形精確抓出 H_1(RP^2; Z) ≅ Z/2Z（撓因子 `[2]`，自由秩 `[1, 0, 0]`）！
  let rp2_cx = IntegralCellularComplex::{
    name: "ProjectivePlane_RP2",
    cell_ranks: [1, 1, 1],
    boundaries: [[[0]], [[2]]],
  }
  let h_rp2 = compute_integral_cellular_homology(rp2_cx)

  let hom_all_ok = h_s2.chain_boundary_sq_zero &&
    h_s2.betti_free == [1, 0, 1] &&
    h_s2.euler_characteristic == 2 &&
    h_t2.chain_boundary_sq_zero &&
    h_t2.betti_free == [1, 2, 1] &&
    h_t2.euler_characteristic == 0 &&
    h_rp2.chain_boundary_sq_zero &&
    h_rp2.betti_free == [1, 0, 0] &&
    h_rp2.torsion_factors[1] == [2] &&
    h_rp2.euler_characteristic == 1

  CoveringPushoutTorusReport::{
    s3_pointed_coverings_count: subgroups.length(),
    s3_galois_normal_deck_orders: normal_deck_orders,
    s3_nonnormal_deck_orders: nonnormal_deck_orders,
    galois_covering_theorem_holds: galois_ok &&
    hom_all_ok &&
    (w1, w2) == (2, -1),
    torus_commutator_lifts_closed_vs_wedge_open: comm_sep_ok,
    torus_s1_product_winding_pair: (w1, w2),
    susp_s1_gives_s2_betti: h_s2.betti_free,
    torus_betti_kunneth: h_t2.betti_free,
    rp2_h1_two_torsion_factors: h_rp2.torsion_factors[1],
  }
}
