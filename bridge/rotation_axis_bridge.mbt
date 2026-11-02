///|
// Cross-federation rotation-relation atlas.
//
// This package does not reimplement the four upstream rotation algorithms.
// It calls their public witnesses and aligns only relations that are actually
// meaningful for each family.  The common conjugate-quaternion reference and
// its persistent conservation ledger live in @condensed/quaternion_axis.mbt.
// The alignment is structural, not a claim that Jacobi, Jordan, Hopf and
// Tamari rotations are isomorphic mathematical objects.

///|
/// One upstream `kt` rotation family and the relations verified for it.
pub(all) struct KtRotationFamilyAlignment {
  family : String
  relations : Array[String]
  quantitative_witness : String
  holds : Bool
} derive(Debug, Eq)

///|
pub extend KtRotationFamilyAlignment with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend KtRotationFamilyAlignment with Eq::{not_equal, equal}

///|
/// One family-wise numeric comparison against the pre-elimination baseline.
pub(all) struct RotationNumericComparison {
  family : String
  metrics : Array[String]
  previous : Array[Double]
  current : Array[Double]
  deltas : Array[Double]
  max_abs_delta : Double
  tolerance : Double
  shape_ok : Bool
  holds : Bool
} derive(Debug, Eq)

///|
pub extend RotationNumericComparison with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend RotationNumericComparison with Eq::{not_equal, equal}

///|
/// Four-family alignment, numeric before/after audits and coherence quotient.
pub(all) struct RotationAxisBridgeReport {
  families : Array[KtRotationFamilyAlignment]
  families_passed : Int32
  comparisons : Array[RotationNumericComparison]
  comparisons_passed : Int32
  axis_comparison : RotationNumericComparison
  coherence : @cub.CoherenceAngleEliminationReport
  axis : @condensed.CondQuaternionAxisReport
  holds : Bool
} derive(Debug, Eq)

///|
pub extend RotationAxisBridgeReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend RotationAxisBridgeReport with Eq::{not_equal, equal}

///|
fn rotation_array_close(
  a : Array[Double],
  b : Array[Double],
  tolerance : Double,
) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    let d = a[i] - b[i]
    if d.is_nan() || d.is_inf() || d * d > tolerance * tolerance {
      return false
    }
  }
  true
}

///|
fn rotation_norm2(values : Array[Double]) -> Double {
  let mut total = 0.0
  for x in values {
    total = total + x * x
  }
  total
}

///|
fn rotation_qmat_column_norm2(value : @exactalg.QMat) -> @exactalg.Rat {
  let mut total = @exactalg.rat_zero()
  for row in value.rows {
    total = @exactalg.rat_add(total, @exactalg.rat_mul(row[0], row[0]))
  }
  total
}

///|
/// Numeric arrays are captured from the same upstream algorithms before and
/// after coherence elimination.  Shape and finite-value checks prevent a
/// missing metric or NaN from being reported as a successful comparison.
fn rotation_numeric_comparison(
  family : String,
  metrics : Array[String],
  previous : Array[Double],
  current : Array[Double],
) -> RotationNumericComparison {
  let tolerance = 0.000000000001
  let shape_ok = metrics.length() == previous.length() &&
    previous.length() == current.length()
  let deltas : Array[Double] = []
  let mut max_abs_delta = 0.0
  let mut values_ok = true
  if shape_ok {
    for i in 0..<current.length() {
      let delta = current[i] - previous[i]
      deltas.push(delta)
      if delta.is_nan() || delta.is_inf() {
        values_ok = false
      } else if delta.abs() > max_abs_delta {
        max_abs_delta = delta.abs()
      }
    }
  }
  RotationNumericComparison::{
    family,
    metrics,
    previous,
    current,
    deltas,
    max_abs_delta,
    tolerance,
    shape_ok,
    holds: shape_ok && values_ok && max_abs_delta <= tolerance,
  }
}

///|
/// Jacobi: adjoint/inverse implication, ordered similarity certificates and
/// coarse/fine outward-interval refinement.  No discrete/Tamari relation is claimed.
fn verify_jacobi_rotation_alignment() -> (Bool, String, Array[Double]) {
  let input = @exactalg.qcpx_mat_from_qmat(
    @exactalg.qmat_from_int_rows([[2, 1], [1, 2]]),
  )
  guard @exactalg.jacobi_interval_eigen(input, precision_bits=8) is Some(coarse) else {
    return (false, "Jacobi coarse certificate was not constructed", [])
  }
  guard @exactalg.jacobi_interval_eigen(input, precision_bits=16) is Some(fine) else {
    return (false, "Jacobi fine certificate was not constructed", [])
  }
  let mut unitary_and_monotone = coarse.rotations.length() > 0
  for rotation in coarse.rotations {
    unitary_and_monotone = unitary_and_monotone &&
      rotation.unitary_residual_contains_zero &&
      @exactalg.rat_le_exact(
        rotation.after_off_sq_upper,
        rotation.before_off_sq_upper,
      )
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
  let ok = @exactalg.jacobi_certificate_sound(input, coarse) &&
    @exactalg.jacobi_certificate_sound(input, fine) &&
    unitary_and_monotone &&
    @exactalg.rat_le_exact(fine_width, coarse_width)
  let mut initial_off_sq = 0.0
  let mut final_off_sq = 0.0
  if coarse.rotations.length() > 0 {
    initial_off_sq = @exactalg.rat_to_double(
      coarse.rotations[0].before_off_sq_upper,
    )
    final_off_sq = @exactalg.rat_to_double(
      coarse.rotations[coarse.rotations.length() - 1].after_off_sq_upper,
    )
  }
  (
    ok,
    "Jacobi rotations=\{coarse.rotations.length()}, unitary-residual-contains-0=\{unitary_and_monotone}, interval bits 8→16 and ordered similarity certificate",
    [
      @exactalg.rat_to_double(coarse_width),
      @exactalg.rat_to_double(fine_width),
      initial_off_sq,
      final_off_sq,
    ],
  )
}

///|
/// Jordan's real irreducible block `R = [[0,-1],[1,0]]`: finite order four,
/// forward/reverse inverses, and a determinant-negative reflection contrast.
fn verify_jordan_rotation_alignment() -> (Bool, String, Array[Double]) {
  let r = @exactalg.qmat_from_int_rows([[0, -1], [1, 0]])
  let reflection = @exactalg.qmat_from_int_rows([[-1, 0], [0, 1]])
  let identity = @exactalg.qmat_identity(2)
  let r2 = @exactalg.qmat_pow(r, 2)
  let r3 = @exactalg.qmat_pow(r, 3)
  let r4 = @exactalg.qmat_pow(r, 4)
  let det_r = @exactalg.qmat_det(r)
  let det_reflection = @exactalg.qmat_det(reflection)
  let forward_reverse = @exactalg.qmat_eq(@exactalg.qmat_mul(r, r3), identity) &&
    @exactalg.qmat_eq(@exactalg.qmat_mul(r3, r), identity)
  let reflection_contrast = @exactalg.rat_eq(det_r, @exactalg.rat_int(1)) &&
    @exactalg.rat_eq(det_reflection, @exactalg.rat_int(-1)) &&
    @exactalg.qmat_eq(@exactalg.qmat_pow(reflection, 2), identity)
  let finite_order = @exactalg.qmat_eq(r4, identity) &&
    !@exactalg.qmat_eq(r2, identity)
  let vector = @exactalg.qmat_from_int_rows([[3], [4]])
  let rotated = @exactalg.qmat_mul(r, vector)
  let norm_before = rotation_qmat_column_norm2(vector)
  let norm_after = rotation_qmat_column_norm2(rotated)
  let norm_ok = @exactalg.rat_eq(norm_before, norm_after)
  let ok = @exactalg.check_algebraic_extensions_and_Jordan() &&
    forward_reverse &&
    reflection_contrast &&
    finite_order &&
    norm_ok
  (
    ok,
    "Jordan R⁴=I, R²≠I, R R³=R³R=I; det(R)=+1 versus reflection det=-1; norm²=25",
    [
      @exactalg.rat_to_double(det_r),
      @exactalg.rat_to_double(norm_before),
      @exactalg.rat_to_double(norm_after),
      @exactalg.rat_to_double(det_reflection),
    ],
  )
}

///|
/// Hopf phase: conjugate phase `-theta`, forward/reverse round trip,
/// phase-addition composition and exact/numerical S³/S² norm representatives.
fn verify_hopf_rotation_alignment() -> (Bool, String, Array[Double]) {
  let point = [0.6, 0.0, 0.8, 0.0]
  let theta = 0.37
  let phi = -0.11
  let forward = @cub.hopf_phase_rotate(point, theta)
  let roundtrip = @cub.hopf_phase_rotate(forward, -theta)
  let sequential = @cub.hopf_phase_rotate(forward, phi)
  let combined = @cub.hopf_phase_rotate(point, theta + phi)
  let reverse_sequence = @cub.hopf_phase_rotate(
    @cub.hopf_phase_rotate(sequential, -phi),
    -theta,
  )
  let base_image = @cub.hopf_map_s3_to_s2(point)
  let sequential_image = @cub.hopf_map_s3_to_s2(sequential)
  let norm_ok = (rotation_norm2(point) - 1.0).abs() < 0.000000000001 &&
    (rotation_norm2(sequential) - 1.0).abs() < 0.000000000001 &&
    (rotation_norm2(base_image) - 1.0).abs() < 0.000000000001
  let ok = rotation_array_close(roundtrip, point, 0.000000000001) &&
    rotation_array_close(sequential, combined, 0.000000000001) &&
    rotation_array_close(reverse_sequence, point, 0.000000000001) &&
    rotation_array_close(base_image, sequential_image, 0.000000000001) &&
    norm_ok &&
    @cub.check_hopf_exact_rational() &&
    @cub.check_hopf_numeric()
  (
    ok,
    "Hopf phase θ=0.37, φ=-0.11: θ+φ composition, −θ/−φ reverse sequence, S³/S² norm=1 and fiber invariance",
    [
      rotation_norm2(point),
      rotation_norm2(sequential),
      rotation_norm2(base_image),
      rotation_norm2(sequential_image),
    ],
  )
}

///|
/// Tamari: actual root left/right rotation inverses on three leaves and a
/// finite connected sequence graph on the five binary trees with four leaves.
fn verify_tamari_rotation_alignment() -> (Bool, String, Array[Double]) {
  let left = @cub.paren_left_spine(3)
  let right = @cub.paren_right_spine(3)
  let mut left_to_right = false
  for candidate in @cub.paren_rotations(left) {
    if candidate == right {
      left_to_right = true
    }
  }
  let mut right_to_left = false
  for candidate in @cub.paren_rotations(right) {
    if candidate == left {
      right_to_left = true
    }
  }
  let finite_count = @cub.paren_all(4).length()
  let edge_count = @cub.paren_rotation_edge_count(4)
  let connected = @cub.paren_rotation_graph_connected(4)
  let ok = left_to_right &&
    right_to_left &&
    @cub.paren_leaves(left) == 3 &&
    finite_count == 5 &&
    edge_count == 5 &&
    connected
  (
    ok,
    "Tamari K₃ left↔right round trip; K₄ Catalan vertices=\{finite_count}, rotation edges=\{edge_count}, connected=\{connected}",
    [
      finite_count.to_double(),
      edge_count.to_double(),
      if connected {
        1.0
      } else {
        0.0
      },
    ],
  )
}

///|
/// Align the four actual `kt` rotation families through the condensed axis.
pub fn verify_rotation_axis_bridge() -> RotationAxisBridgeReport {
  let axis = @condensed.cond_quaternion_axis_report()
  let (jacobi_ok, jacobi_witness, jacobi_values) = verify_jacobi_rotation_alignment()
  let (jordan_ok, jordan_witness, jordan_values) = verify_jordan_rotation_alignment()
  let (hopf_ok, hopf_witness, hopf_values) = verify_hopf_rotation_alignment()
  let (tamari_ok, tamari_witness, tamari_values) = verify_tamari_rotation_alignment()
  let families = [
    KtRotationFamilyAlignment::{
      family: "Jacobi unitary interval rotation",
      relations: [
        "對偶／蘊含：U†=U⁻¹", "大／細：8→16 bits", "序列：ordered similarity",
      ],
      quantitative_witness: jacobi_witness,
      holds: jacobi_ok,
    },
    KtRotationFamilyAlignment::{
      family: "Jordan real rotation block",
      relations: [
        "逆向／順向：R,R³", "倒影：det=-1 negative control", "離散：order 4",
      ],
      quantitative_witness: jordan_witness,
      holds: jordan_ok,
    },
    KtRotationFamilyAlignment::{
      family: "Hopf rational/numerical phase rotation",
      relations: [
        "對偶：−θ", "逆向／順向", "緊緻載體：S³", "序列／反序列：θ,φ",
      ],
      quantitative_witness: hopf_witness,
      holds: hopf_ok,
    },
    KtRotationFamilyAlignment::{
      family: "Tamari associahedron rotation",
      relations: [
        "逆向／順向：left/right", "離散：Catalan graph", "序列／反序列：connected paths",
      ],
      quantitative_witness: tamari_witness,
      holds: tamari_ok,
    },
  ]
  let mut families_passed = 0
  for family in families {
    if family.holds {
      families_passed = families_passed + 1
    }
  }
  // Fixed before the coherence-elimination change on 2026-11-02.  These are
  // regression baselines, not knobs to update when a numerical result moves.
  let comparisons = [
    rotation_numeric_comparison(
      "Jacobi",
      [
        "coarse total eigeninterval width", "fine total eigeninterval width", "initial off-diagonal square upper",
        "final off-diagonal square upper",
      ],
      [0.2578125, 0.001007080078125, 2.0, 0.002471923828125],
      jacobi_values,
    ),
    rotation_numeric_comparison(
      "Jordan",
      ["det(R)", "norm² before", "norm² after", "det(reflection)"],
      [1.0, 25.0, 25.0, -1.0],
      jordan_values,
    ),
    rotation_numeric_comparison(
      "Hopf",
      [
        "S³ norm² before", "S³ norm² after θ+φ", "S² norm² before", "S² norm² after θ+φ",
      ],
      [1.0, 1.0000000000000002, 1.0, 1.0000000000000004],
      hopf_values,
    ),
    rotation_numeric_comparison(
      "Tamari",
      ["K₄ vertices", "K₄ rotation edges", "connected (1/0)"],
      [5.0, 5.0, 1.0],
      tamari_values,
    ),
  ]
  let mut comparisons_passed = 0
  for comparison in comparisons {
    if comparison.holds {
      comparisons_passed = comparisons_passed + 1
    }
  }
  let axis_comparison = rotation_numeric_comparison(
    "Condensed quaternion axis",
    [
      "integral residual", "RK4 observed order", "Richardson limit error", "fine norm² drift",
      "exact conservation laws", "ledger entries",
    ],
    [
      8.215650382226158e-15, 3.9999741296849374, 5.181372564008819e-11, 9.71454028331209e-11,
      3.0, 20.0,
    ],
    [
      axis.integral.residual,
      axis.ode.observed_order,
      axis.ode.richardson_limit_error,
      axis.ode.fine_norm_drift,
      axis.conservation_laws_passed.to_double(),
      axis.ledger_entries.to_double(),
    ],
  )
  let coherence = @cub.coherence_angle_elimination_report()
  RotationAxisBridgeReport::{
    families,
    families_passed,
    comparisons,
    comparisons_passed,
    axis_comparison,
    coherence,
    axis,
    holds: families_passed == 4 &&
    comparisons_passed == 4 &&
    axis_comparison.holds &&
    coherence.holds &&
    axis.conserved,
  }
}

///|
/// Standalone certificate; it is intentionally separate from the historical
/// 47-certificate ledger so existing milestone counts remain unchanged.
pub fn rotation_axis_certificate() -> BridgeCertificate {
  let report = verify_rotation_axis_bridge()
  bridge_certificate(
    "condensed/quaternion-axis",
    "Conjugate Quaternion × CanonElimCategory × Jacobi/Jordan/Hopf/Tamari Rotation Relations",
    report.holds,
    detail="families=\{report.families_passed}/4, numeric comparisons=\{report.comparisons_passed}/4 + axis=\{report.axis_comparison.holds}, coherence 11040→552→0 (276 canonical classes), integral residual=\{report.axis.integral.residual}, RK4 order=\{report.axis.ode.observed_order}, Richardson error=\{report.axis.ode.richardson_limit_error}, exact conservation laws=\{report.axis.conservation_laws_passed}/3, ledger entries=\{report.axis.ledger_entries}",
  )
}
