///|
// Four intuition-driven conjectures, each refuted by an explicit counterexample and
// paired with a refined statement. (The former bounded-survival entry C-INT-01 had no
// verdict and was removed; identifiers C-INT-02..05 are kept.)
//
// This is a standalone Lakatosian lab, separate from the historical 12-entry
// conjecture atlas and the 48-certificate historical ledger.  A record's `audit_ok`
// means that its reported outcome is supported by the stated finite search;
// it does not mean that the original conjecture is true.  In particular,
// `RefutedAndRefined` records deliberately preserve the failed statement and
// its counterexample instead of silently rewriting history.

///|
#derive(Debug, Eq)
pub(all) enum IntuitiveConjectureOutcome {
  RefutedAndRefined
}

///|
pub extend IntuitiveConjectureOutcome with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend IntuitiveConjectureOutcome with Eq::{not_equal, equal}

///|
/// One conjecture, the intuition that suggested it, and the outcome of an
/// actual bounded counterexample search.
#derive(Debug, Eq)
pub(all) struct IntuitiveConjectureRecord {
  id : String
  title : String
  intuition : String
  statement : String
  search_scope : String
  outcome : IntuitiveConjectureOutcome
  counterexample : String
  refined_statement : String
  evidence : String
  audit_ok : Bool
}

///|
pub extend IntuitiveConjectureRecord with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend IntuitiveConjectureRecord with Eq::{not_equal, equal}

///|
/// The records plus the refutation count.  `holds` audits the experiment, not the
/// truth of every original statement.
#derive(Debug, Eq)
pub(all) struct IntuitiveConjectureLabReport {
  records : Array[IntuitiveConjectureRecord]
  refuted_and_refined : Int32
  holds : Bool
}

///|
pub extend IntuitiveConjectureLabReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend IntuitiveConjectureLabReport with Eq::{not_equal, equal}

///|
pub fn intuitive_conjecture_outcome_label(
  outcome : IntuitiveConjectureOutcome,
) -> String {
  match outcome {
    RefutedAndRefined => "REFUTED + REFINED"
  }
}

///|
/// Return `(bipartite, rotation_closed)` for the actual Tamari rotation graph.
fn conjecture_tamari_bipartition(n : Int32) -> (Bool, Bool) {
  let vertices = @cub.paren_all(n)
  let colors : Array[Int32] = []
  for _i in 0..<vertices.length() {
    colors.push(-1)
  }
  let mut bipartite = true
  let mut rotation_closed = true
  for start in 0..<vertices.length() {
    if colors[start] < 0 {
      colors[start] = 0
      let queue = [start]
      let mut head = 0
      while head < queue.length() {
        let i = queue[head]
        head = head + 1
        for candidate in @cub.paren_rotations(vertices[i]) {
          let mut j = 0
          while j < vertices.length() && vertices[j] != candidate {
            j = j + 1
          }
          if j == vertices.length() {
            rotation_closed = false
          } else if colors[j] < 0 {
            colors[j] = 1 - colors[i]
            queue.push(j)
          } else if colors[j] == colors[i] {
            bipartite = false
          }
        }
      }
    }
  }
  (bipartite, rotation_closed)
}

///|
fn conjecture_tamari_connected_regular(n : Int32) -> Bool {
  let vertices = @cub.paren_all(n)
  if !@cub.paren_rotation_graph_connected(n) {
    return false
  }
  for vertex in vertices {
    if @cub.paren_rotations(vertex).length() != n - 2 {
      return false
    }
  }
  @cub.paren_rotation_edge_count(n) == (n - 2) * vertices.length() / 2
}

///|
/// C-INT-02: an apparent left/right alternation suggests bipartiteness.  The
/// attack uses two-coloring, while the repair checks the surviving regularity
/// and connectedness rather than merely deleting the conjecture.
fn conjecture_tamari_bipartite() -> IntuitiveConjectureRecord {
  let mut first_non_bipartite = -1
  let mut rotation_closed = true
  for n in 3..<=8 {
    let (bipartite, closed) = conjecture_tamari_bipartition(n)
    rotation_closed = rotation_closed && closed
    if !bipartite && first_non_bipartite < 0 {
      first_non_bipartite = n
    }
  }
  let mut refined_ok = true
  for n in 3..<=8 {
    refined_ok = refined_ok && conjecture_tamari_connected_regular(n)
  }
  let (k4_bipartite, k4_closed) = conjecture_tamari_bipartition(4)
  let k4_c5 = !k4_bipartite &&
    k4_closed &&
    @cub.paren_all(4).length() == 5 &&
    @cub.paren_rotation_edge_count(4) == 5 &&
    conjecture_tamari_connected_regular(4)
  let audit_ok = first_non_bipartite == 4 &&
    rotation_closed &&
    refined_ok &&
    k4_c5
  IntuitiveConjectureRecord::{
    id: "C-INT-02",
    title: "Tamari 旋轉圖的二分性直覺",
    intuition: "根旋轉看似在左傾與右傾括號化之間交替，因此容易猜測每一次旋轉都會切換一個二分顏色。",
    statement: "所有 n≥3 的 Tamari 旋轉圖都是二分圖。",
    search_scope: "對 n=3..8 的全部頂點做 BFS 二著色，另檢查旋轉封閉性；修正版另窮舉連通性與 (n−2)-正則性。",
    outcome: RefutedAndRefined,
    counterexample: "K₄：5 頂點、5 邊、2-正則、連通且非二分，故就是奇環 C₅。",
    refined_statement: "保留「連通且 (n−2)-正則」；刪去二分性。任何含 K₄ 奇環的一般二分猜想都必須另加排除奇環的前提。",
    evidence: "首個反例 n=\{first_non_bipartite}；K₄ 奇環見證=\{k4_c5}；n=3..8 的修正版全部通過=\{refined_ok}。",
    audit_ok,
  }
}

///|
/// C-INT-03: rotation and reflection both have unit-modulus determinant, but
/// the shear matrix isolates why determinant alone cannot conserve norm.
fn conjecture_determinant_norm() -> IntuitiveConjectureRecord {
  let shear = @exactalg.qmat_from_int_rows([[1, 1], [0, 1]])
  let vector = @exactalg.qmat_from_int_rows([[0], [1]])
  let rotated = @exactalg.qmat_mul(shear, vector)
  let determinant = @exactalg.qmat_det(shear)
  let norm_before = rotation_qmat_column_norm2(vector)
  let norm_after = rotation_qmat_column_norm2(rotated)
  let audit_ok = @exactalg.rat_eq(determinant, @exactalg.rat_int(1)) &&
    @exactalg.rat_eq(norm_before, @exactalg.rat_int(1)) &&
    @exactalg.rat_eq(norm_after, @exactalg.rat_int(2))
  IntuitiveConjectureRecord::{
    id: "C-INT-03",
    title: "行列式與歐氏範數守恆",
    intuition: "Jordan 旋轉與倒影的行列式絕對值都是 1，也都保持長度，因此直覺上容易把體積守恆誤當成長度守恆的充分條件。",
    statement: "任意 2×2 實矩陣若 det=+1，就保持歐氏範數平方。",
    search_scope: "直接攻擊最簡單的保面積非等距變換：剪切矩陣 S=[[1,1],[0,1]]，並以精確有理矩陣運算核算。",
    outcome: RefutedAndRefined,
    counterexample: "S 的 det=1，但 S[0,1]ᵀ=[1,1]ᵀ，norm² 由 1 變成 2。",
    refined_statement: "把前提加強為正交性 RᵀR=I（複數情形則為酉性）；det=+1 只能是必要線索，不能單獨推出範數守恆。",
    evidence: "精確值 det=\{@exactalg.rat_to_double(determinant)}, norm²=\{@exactalg.rat_to_double(norm_before)}→\{@exactalg.rat_to_double(norm_after)}。",
    audit_ok,
  }
}

///|
priv struct ConjectureJacobiProbe {
  coarse_width : @exactalg.Rat
  fine_width : @exactalg.Rat
  rotations : Int32
  sound : Bool
}

///|
fn conjecture_jacobi_probe(matrix : @exactalg.QMat) -> ConjectureJacobiProbe {
  let input = @exactalg.qcpx_mat_from_qmat(matrix)
  guard @exactalg.jacobi_interval_eigen(input, precision_bits=8) is Some(coarse) else {
    return ConjectureJacobiProbe::{
      coarse_width: @exactalg.rat_zero(),
      fine_width: @exactalg.rat_zero(),
      rotations: -1,
      sound: false,
    }
  }
  guard @exactalg.jacobi_interval_eigen(input, precision_bits=16) is Some(fine) else {
    return ConjectureJacobiProbe::{
      coarse_width: @exactalg.rat_zero(),
      fine_width: @exactalg.rat_zero(),
      rotations: -1,
      sound: false,
    }
  }
  let mut coarse_width = @exactalg.rat_zero()
  let mut fine_width = @exactalg.rat_zero()
  for interval in coarse.eigenvalues {
    coarse_width = @exactalg.rat_add(
      coarse_width,
      @exactalg.rat_sub(interval.hi, interval.lo),
    )
  }
  for interval in fine.eigenvalues {
    fine_width = @exactalg.rat_add(
      fine_width,
      @exactalg.rat_sub(interval.hi, interval.lo),
    )
  }
  ConjectureJacobiProbe::{
    coarse_width,
    fine_width,
    rotations: coarse.rotations.length(),
    sound: @exactalg.jacobi_certificate_sound(input, coarse) &&
    @exactalg.jacobi_certificate_sound(input, fine),
  }
}

///|
/// C-INT-04: outward intervals should not grow with precision, but strict
/// shrinkage is a stronger claim and fails on already-exact diagonal input.
fn conjecture_jacobi_strict_refinement() -> IntuitiveConjectureRecord {
  let probes : Array[ConjectureJacobiProbe] = []
  for
    matrix in [
      @exactalg.qmat_from_int_rows([[1, 0], [0, 2]]),
      @exactalg.qmat_from_int_rows([[1, 0], [0, 0]]),
      @exactalg.qmat_from_int_rows([[0, 0], [0, 0]]),
      @exactalg.qmat_from_int_rows([[2, 0], [0, 1]]),
      @exactalg.qmat_from_int_rows([[2, 1], [1, 2]]),
    ] {
    probes.push(conjecture_jacobi_probe(matrix))
  }
  let mut non_increasing = true
  for probe in probes {
    non_increasing = non_increasing &&
      probe.sound &&
      @exactalg.rat_le_exact(probe.fine_width, probe.coarse_width)
  }
  let diagonal = probes[0]
  let off_diagonal = probes[4]
  let counterexample_ok = diagonal.sound &&
    diagonal.rotations == 0 &&
    @exactalg.rat_eq(diagonal.coarse_width, @exactalg.rat_zero()) &&
    @exactalg.rat_eq(diagonal.fine_width, @exactalg.rat_zero())
  let off_diagonal_strict = off_diagonal.sound &&
    off_diagonal.rotations > 0 &&
    @exactalg.rat_le_exact(off_diagonal.fine_width, off_diagonal.coarse_width) &&
    !@exactalg.rat_eq(off_diagonal.fine_width, off_diagonal.coarse_width)
  let audit_ok = non_increasing && counterexample_ok && off_diagonal_strict
  IntuitiveConjectureRecord::{
    id: "C-INT-04",
    title: "Jacobi 精度加倍的嚴格細化",
    intuition: "更多精度位元通常給出更窄的外逼近，因此很自然把既有的非增觀察加強成嚴格下降。",
    statement: "每個實對稱有理矩陣從 8 到 16 bits 時，特徵值區間總寬都嚴格縮短。",
    search_scope: "五個 2×2 整數對稱矩陣：四個對角負對照與一個非對角旋轉樣本；逐個重算並核驗兩份區間證書。",
    outcome: RefutedAndRefined,
    counterexample: "diag(1,2) 沒有 Jacobi 旋轉，粗／細總寬都是精確的 0，故不可能嚴格下降。",
    refined_statement: "一般只主張向外區間非增；嚴格縮短必須另證非退化條件。非對角樣本確有 0.2578125→0.001007080078125，但不能取代一般前提。",
    evidence: "對角反例=\{counterexample_ok}；五樣本 sound 且非增=\{non_increasing}；非對角樣本嚴格縮短=\{off_diagonal_strict}。",
    audit_ok,
  }
}

///|
/// C-INT-05: exact phase rotation is orthogonal, but repeated floating-point
/// composition accumulates error.  The search stops at 10000 steps and records
/// the first actual violation rather than extrapolating from one step.
fn conjecture_hopf_fixed_tolerance() -> IntuitiveConjectureRecord {
  let tolerance = 0.000000000001
  let theta = 0.37
  let mut point = [0.6, 0.0, 0.8, 0.0]
  let initial_norm_error = (rotation_norm2(point) - 1.0).abs()
  let mut first_violation = -1
  let mut first_drift = 0.0
  let mut drift_at_9000 = 0.0
  let mut final_drift = 0.0
  for step in 1..<=10000 {
    point = @cub.hopf_phase_rotate(point, theta)
    final_drift = (rotation_norm2(point) - 1.0).abs()
    if step == 9000 {
      drift_at_9000 = final_drift
    }
    if first_violation < 0 && final_drift >= tolerance {
      first_violation = step
      first_drift = final_drift
    }
  }
  let audit_ok = initial_norm_error < tolerance &&
    first_violation > 0 &&
    first_violation <= 10000 &&
    first_drift >= tolerance &&
    drift_at_9000 < tolerance
  IntuitiveConjectureRecord::{
    id: "C-INT-05",
    title: "Hopf 任意長相位序列的固定容差守恆",
    intuition: "每次相位旋轉在實數上都是 S³ 等距映射；若只看單步或短序列，很容易期待同一個固定範數容差永遠有效。",
    statement: "從 [0.6,0,0.8,0] 出發，任意多次 θ=0.37 的浮點相位複合後，norm² 與 1 的誤差都小於 1e-12。",
    search_scope: "實際複合 1..10000 步，逐步計算 norm²，記錄首次達到或超過 1e-12 的步數，並檢查第 9000 步仍在界內。",
    outcome: RefutedAndRefined,
    counterexample: "第 \{first_violation} 步首次越界，漂移=\{first_drift}；第 10000 步漂移=\{final_drift}。",
    refined_statement: "必須使用隨步數累積的誤差預算，或另行分析正規化策略；單步／短序列證據不能外推成任意長序列的固定 1e-12 界。",
    evidence: "初始誤差=\{initial_norm_error}；第 9000 步漂移=\{drift_at_9000}；首次越界=\{first_violation}。",
    audit_ok,
  }
}

///|
/// Run all four independent counterexample attacks.  Historical atlas counts
/// and certificate counts are intentionally unchanged.
pub fn verify_intuitive_conjecture_lab() -> IntuitiveConjectureLabReport {
  let records = [
    conjecture_tamari_bipartite(),
    conjecture_determinant_norm(),
    conjecture_jacobi_strict_refinement(),
    conjecture_hopf_fixed_tolerance(),
  ]
  let mut refuted_and_refined = 0
  let mut audits_ok = true
  for record in records {
    match record.outcome {
      RefutedAndRefined => refuted_and_refined = refuted_and_refined + 1
    }
    audits_ok = audits_ok && record.audit_ok
  }
  IntuitiveConjectureLabReport::{
    records,
    refuted_and_refined,
    holds: records.length() == 4 && audits_ok && refuted_and_refined == 4,
  }
}
