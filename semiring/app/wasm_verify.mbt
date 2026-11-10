// ===========================================================================
// `wasm-gc` 全目標可攜半環聯邦整合驗證套件（免 `par_host` / `async/fs` 原生依賴）
//
// 覆蓋 Federation 3 (`semiring`) 之全套硬體 SWAR 與多項式時間演算法核心：
//   1. `mul_bool_swar` / `mul_gf2_m4ri_swar` / `closure_bool_swar` / `closure_trop_swar`
//   2. `BPoly::subdivision` 3D 脊邊禮品包裝下凸包 vs 牛頓面積守恆與熱帶曲線平衡律
//   3. `trop_eigenvalue_karp` + `trop_critical_eigenvector` 熱帶譜特徵方程
//   4. `apsp_johnson` 負權邊稀疏全源最短路 vs 原地 Floyd–Warshall + 負環偵測
//   5. `bp_exact_all_marginals_ve` 有環因子圖 Min-Fill 精確半環變數消去
//   6. `dfa_of_regex` 64-bit 結構雜湊 + Hopcroft–Valmari `O(|Σ||Q|log|Q|)` 最小 DFA 正規形
// ===========================================================================

///|
/// 執行全目標可攜之半環聯邦核心機器驗證證書。
pub fn verify_semiring_wasm_suite() -> Bool {
  // 1. 64-bit Four-Russians 布林乘法、GF(2) M4RI 與傳遞閉包對照
  let n_b = 70
  let ma = @mat.Mat::new(n_b, n_b, @alg.BoolSr::of(false))
  let mb = @mat.Mat::new(n_b, n_b, @alg.BoolSr::of(false))
  for i in 0..<n_b {
    ma.set(i, (i + 1) % n_b, @alg.BoolSr::of(true))
    ma.set(i, (i * 7 + 3) % n_b, @alg.BoolSr::of(true))
    mb.set(i, (i * 5 + 2) % n_b, @alg.BoolSr::of(true))
  }
  let prod_swar = @mat.mul_bool_swar(ma, mb)
  let prod_ref = @mat.mul_ikj(ma, mb)
  if !@mat.mat_equal(prod_swar, prod_ref) {
    return false
  }
  let gf2_prod = @mat.mul_gf2_m4ri_swar(ma, mb)
  // 奇偶路徑 ≤ 布林存在路徑：凡 GF(2) 為 1 者，布林乘積必為 true
  for idx in 0..<(n_b * n_b) {
    if gf2_prod.d[idx].b && !prod_swar.d[idx].b {
      return false
    }
  }
  let (cl_swar, reach_cnt) = @mat.closure_bool_swar(ma)
  let cl_ref = @mat.closure_fw_inplace(ma)
  if !@mat.mat_equal(cl_swar, cl_ref) || reach_cnt <= n_b {
    return false
  }

  // 2. 熱帶快取分塊 Kleene 星 (@swar) vs 原地 Warshall
  let tm = @mat.Mat::new(20, 20, @alg.Trop::inf())
  for i in 0..<20 {
    tm.set(i, (i + 1) % 20, @alg.Trop::new(3 + i % 5))
    tm.set(i, (i + 4) % 20, @alg.Trop::new(7 + i % 3))
  }
  let tcl_swar = @mat.closure_trop_swar(tm, tile_size=8)
  let tcl_ref = @mat.closure_fw_inplace(tm)
  if !@mat.mat_equal(tcl_swar, tcl_ref) {
    return false
  }

  // 3. 3D 脊邊禮品包裝牛頓細分：含共面格點與邊界共線點之三次熱帶曲線（虧格 g = 1）
  let terms : Array[@trop.BTerm] = []
  for i in 0..<=3 {
    for j in 0..<=3 {
      if i + j <= 3 {
        let c = i * i * 2 + j * j * 3 + i * j - 4 * i - 3 * j + 10
        terms.push(@trop.BTerm::new(c, i, j))
      }
    }
  }
  let bp = @trop.BPoly::new(terms)
  let faces = bp.subdivision()
  if faces.length() == 0 {
    return false
  }
  // 細分多邊形面積總和 == 牛頓凸包面積（2 倍整數面積 = 9）
  let mut sub_area2 = 0L
  for f in faces {
    // 每個面的平面法向 argmin 必須精確等於 f.members
    let argm = bp.minima_scaled(f.plane.nx, f.plane.ny, f.plane.nz)
    if argm != f.members {
      return false
    }
    let poly = f.polygon
    let mut fa = 0L
    for q in 0..<poly.length() {
      let p1 = bp.terms[poly[q]]
      let p2 = bp.terms[poly[(q + 1) % poly.length()]]
      fa = fa +
        p1.i.to_int64() * p2.j.to_int64() -
        p2.i.to_int64() * p1.j.to_int64()
    }
    if fa < 0L {
      fa = -fa
    }
    sub_area2 = sub_area2 + fa
  }
  if sub_area2 != bp.newton_area2() {
    return false
  }

  // 4. Karp 熱帶最小環平均特徵值與臨界特徵向量 + 子集 DP 行列式
  let inf64 = 1_000_000_000_000_000_000L
  let a_karp : Array[Array[Int64]] = [
    [inf64, 4L, 9L, inf64],
    [inf64, inf64, 2L, 7L],
    [1L, inf64, inf64, 3L],
    [6L, 1L, inf64, inf64],
  ]
  // 環 0->1->2->0 權重 4+2+1 = 7，長度 3 => λ = 7/3；
  // 環 1->2->3->1 權重 2+3+1 = 6，長度 3 => λ = 6/3 = 2/1！
  let (num, den) = @trop.trop_eigenvalue_karp(a_karp)
  if num != 2L || den != 1L {
    return false
  }
  match @trop.trop_critical_eigenvector(a_karp) {
    None => return false
    Some((en, ed, ev)) =>
      if en != 2L ||
        ed != 1L ||
        !@trop.verify_trop_eigenpair(a_karp, en, ed, ev) {
        return false
      }
  }
  let a_det : Array[Array[Int64]] = [
    [3L, 8L, 2L, 7L],
    [5L, 1L, 6L, 4L],
    [9L, 4L, 3L, 2L],
    [2L, 6L, 5L, 8L],
  ]
  if @trop.trop_det(a_det) != @trop.trop_det_dp(a_det) ||
    @trop.trop_det_tie_count(a_det) < 1 {
    return false
  }

  // 5. Johnson 負權邊稀疏全源最短路 vs Floyd–Warshall + 負環拒絕
  let g_neg = @graph.Graph::build(4, [0, 0, 1, 2, 3], [1, 2, 2, 3, 1], [
    4, 5, -2, 3, 1,
  ])
  let dense_neg = @mat.Mat::new(4, 4, @alg.Trop::inf())
  dense_neg.set(0, 1, @alg.Trop::new(4))
  dense_neg.set(0, 2, @alg.Trop::new(5))
  dense_neg.set(1, 2, @alg.Trop::new(-2))
  dense_neg.set(2, 3, @alg.Trop::new(3))
  dense_neg.set(3, 1, @alg.Trop::new(1))
  let fw_neg = @mat.closure_fw_inplace(dense_neg)
  for i in 0..<4 {
    // apsp_johnson 不自動補 0 自環（源點自身距離為 0）
    fw_neg.set(i, i, @alg.Trop::new(0))
  }
  match @graph.apsp_johnson(g_neg) {
    None => return false
    Some(j_mat) => if !@mat.mat_equal(j_mat, fw_neg) { return false }
  }
  let g_neg_cyc = @graph.Graph::build(3, [0, 1, 2], [1, 2, 0], [1, -4, 2])
  match @graph.apsp_johnson(g_neg_cyc) {
    Some(_) => return false
    None => ()
  }

  // 6. 有環 4-環因子圖 Min-Fill 精確變數消去 vs 全賦值精確和
  let card = [2, 2, 2, 2]
  let f01 = @bp.Factor::new([0, 1], [
    @alg.Counting::new(2L),
    @alg.Counting::new(1L),
    @alg.Counting::new(1L),
    @alg.Counting::new(3L),
  ])
  let f12 = @bp.Factor::new([1, 2], [
    @alg.Counting::new(3L),
    @alg.Counting::new(2L),
    @alg.Counting::new(1L),
    @alg.Counting::new(4L),
  ])
  let f23 = @bp.Factor::new([2, 3], [
    @alg.Counting::new(1L),
    @alg.Counting::new(2L),
    @alg.Counting::new(3L),
    @alg.Counting::new(1L),
  ])
  let f30 = @bp.Factor::new([3, 0], [
    @alg.Counting::new(4L),
    @alg.Counting::new(1L),
    @alg.Counting::new(2L),
    @alg.Counting::new(3L),
  ])
  let fg_loopy : @bp.FactorGraph[@alg.Counting] = {
    nvar: 4,
    card,
    factors: [f01, f12, f23, f30],
  }
  if @bp.is_tree(fg_loopy) {
    return false
  }
  let ve_res = @bp.bp_exact_all_marginals_ve(fg_loopy)
  // 獨立枚舉 2^4 = 16 組聯合賦值驗證變數 0 與變數 2 的精確邊緣
  let brute0 = [0L, 0L]
  let brute2 = [0L, 0L]
  for x0 in 0..<2 {
    for x1 in 0..<2 {
      for x2 in 0..<2 {
        for x3 in 0..<2 {
          let w = f01.table[x0 * 2 + x1].value() *
            f12.table[x1 * 2 + x2].value() *
            f23.table[x2 * 2 + x3].value() *
            f30.table[x3 * 2 + x0].value()
          brute0[x0] = brute0[x0] + w
          brute2[x2] = brute2[x2] + w
        }
      }
    }
  }
  if ve_res.marginal[0][0].value() != brute0[0] ||
    ve_res.marginal[0][1].value() != brute0[1] ||
    ve_res.marginal[2][0].value() != brute2[0] ||
    ve_res.marginal[2][1].value() != brute2[1] {
    return false
  }

  // 7. Hopcroft–Valmari O(|Σ||Q|log|Q|) DFA 最小化：Kleene 代數恆等式 `(a + b)* == a* (b a*)*`
  let a_ch = @nf.RChar(0)
  let b_ch = @nf.RChar(1)
  let r_lhs = @nf.r_star(@nf.r_sum(a_ch, b_ch))
  let r_rhs = @nf.r_prod(
    @nf.r_star(a_ch),
    @nf.r_star(@nf.r_prod(b_ch, @nf.r_star(a_ch))),
  )
  if !@nf.regex_equiv(r_lhs, r_rhs, [0, 1]) {
    return false
  }
  // 非平凡多狀態語言：倒數第 3 位為 0 的二進位字串 `(0+1)* 0 (0+1) (0+1)` 最小 DFA 恰有 2^3 = 8 個狀態
  let any = @nf.RStar(@nf.RSum(a_ch, b_ch))
  let one_step = @nf.RSum(a_ch, b_ch)
  let nth3 = @nf.r_prod(@nf.r_prod(@nf.r_prod(any, a_ch), one_step), one_step)
  let d_raw = @nf.dfa_of_regex(nth3, [0, 1])
  let d_min = @nf.dfa_minimize(d_raw)
  if d_min.nstates() != 8 ||
    !@nf.dfa_equiv(d_raw, d_min) ||
    !d_min.accepts([1, 0, 1, 1]) ||
    d_min.accepts([0, 1, 1, 1]) {
    return false
  }

  // 8. 稀疏 CSR × 稠密矩陣同態、分塊乘法、熱帶指派與星半環定律覆蓋
  let csr_a = @mat.Csr::from_dense(ma)
  let csr_b = @mat.Csr::from_dense(mb)
  let (r0_lo, r0_hi) = csr_a.row_range(0)
  if r0_hi - r0_lo != 2 ||
    !@mat.mat_equal(@mat.csr_mul(csr_a, csr_b).to_dense(), prod_swar) ||
    !@mat.mat_equal(@mat.mul_blocked_auto(ma, mb), prod_swar) {
    return false
  }
  let flat2 : FixedArray[@alg.BoolSr] = [
    @alg.BoolSr::of(true),
    @alg.BoolSr::of(false),
    @alg.BoolSr::of(false),
    @alg.BoolSr::of(true),
  ]
  let m2 = @mat.Mat::from_flat(2, 2, flat2)
  let reg_buf : FixedArray[@alg.BoolSr] = [
    @alg.BoolSr::of(false),
    @alg.BoolSr::of(false),
  ]
  @mat.copy_region_out(m2, 0, 0, reg_buf, 1, 2)
  let z2 = @mat.Mat::new(2, 2, @alg.BoolSr::of(false))
  if !@mat.mat_equal(m2.transpose().transpose(), m2) ||
    m2.byte_size() <= 0 ||
    !reg_buf[0].b ||
    reg_buf[1].b ||
    !@mat.mat_is_zero(z2) ||
    !@mat.mat_equal(@mat.closure_fw_par(ma, 16), cl_swar) ||
    !@mat.mat_equal(@mat.mul_trop_plain(tm, tm), @mat.mul_ikj(tm, tm)) {
    return false
  }
  let (asgn_cost, _) = @trop.trop_assignment([[1L, 5L], [4L, 2L]])
  let up = @trop.UniPoly::new([0, 1, 4])
  let cset = @alg.CyclicSet::of_range(5, [1, 3, 1])
  let star_rep = @alg.check_star(
    "BoolSr",
    fn() { @alg.BoolSr::of(true) },
    samples=2,
  )
  if asgn_cost != 3L ||
    up.argmin_at(@trop.Rat::of_int(-1)).length() != 2 ||
    cset.cardinality() != 2 ||
    !star_rep.ok() {
    return false
  }
  true
}
