///|
// Conjugate-quaternion rotation axis over the condensed X-pivot.
//
// The file deliberately separates three epistemic levels:
//   1. exact finite mathematics: Q_8, its quotient by +/-1, signed integer
//      rotations, and Z-linear conservation laws in CondInvariantLedger;
//   2. numerical convergence: an improper Lorentzian integral with an
//      explicit tail bound and an RK4 quaternion ODE refinement sequence;
//   3. persistent evidence: immutable hash-chained ledger snapshots.
//
// No floating-point calculation is promoted to an infinite-time or exact
// real-number theorem.  "Conserved" below means exact on the finite discrete
// model plus tolerance-bounded convergence on the stated numerical model.

///|
/// Quaternion `w + x i + y j + z k` used by the condensed rotation axis.
#derive(Debug, Eq)
pub(all) struct CondQuaternion {
  w : Double
  x : Double
  y : Double
  z : Double
}

///|
pub extend CondQuaternion with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondQuaternion with Eq::{not_equal, equal}

///|
/// Three-dimensional vector acted on by quaternion conjugation/reflection.
#derive(Debug, Eq)
pub(all) struct CondVector3 {
  x : Double
  y : Double
  z : Double
}

///|
pub extend CondVector3 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondVector3 with Eq::{not_equal, equal}

///|
/// Converging truncated integrals of `1 / (1 + x^2)` on `[0, B]`.
/// The tail is exactly `atan(1/B)` and is bounded above by `1/B`.
#derive(Debug, Eq)
pub(all) struct CondImproperIntegralReport {
  cutoff : Double
  panels : Int32
  finite_part : Double
  tail_estimate : Double
  tail_upper_bound : Double
  coarse_limit_estimate : Double
  limit_estimate : Double
  cauchy_delta : Double
  target : Double
  residual : Double
  converged : Bool
}

///|
pub extend CondImproperIntegralReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend CondImproperIntegralReport with Eq::{not_equal, equal}

///|
/// Step-doubling report for `q' = (1/2) q omega`, `omega^2 = -|omega|^2`.
/// RK4 states are deliberately NOT renormalized: norm drift remains visible.
#derive(Debug, Eq)
pub(all) struct CondQuaternionOdeReport {
  steps : Array[Int32]
  errors : Array[Double]
  norm_drifts : Array[Double]
  observed_order : Double
  richardson_limit_error : Double
  max_norm_drift : Double
  fine_norm_drift : Double
  reverse_roundtrip_error : Double
  converged : Bool
}

///|
pub extend CondQuaternionOdeReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondQuaternionOdeReport with Eq::{not_equal, equal}

///|
/// Full relational and conservation report for the condensed rotation axis.
#derive(Debug, Eq)
pub(all) struct CondQuaternionAxisReport {
  dual_ok : Bool
  implication_ok : Bool
  reflection_ok : Bool
  forward_reverse_ok : Bool
  coarse_fine_ok : Bool
  discrete_compact_ok : Bool
  sequence_antisequence_ok : Bool
  elimination_category_ok : Bool
  integral : CondImproperIntegralReport
  ode : CondQuaternionOdeReport
  conservation_laws_passed : Int32
  conservation_laws_failed : Int32
  ledger_entries : Int32
  ledger_tip : UInt64
  persistent_snapshot_ok : Bool
  tamper_detected : Bool
  conserved : Bool
}

///|
pub extend CondQuaternionAxisReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend CondQuaternionAxisReport with Eq::{not_equal, equal}

///|
fn cond_q_add(a : CondQuaternion, b : CondQuaternion) -> CondQuaternion {
  CondQuaternion::{ w: a.w + b.w, x: a.x + b.x, y: a.y + b.y, z: a.z + b.z, }
}

///|
fn cond_q_sub(a : CondQuaternion, b : CondQuaternion) -> CondQuaternion {
  CondQuaternion::{ w: a.w - b.w, x: a.x - b.x, y: a.y - b.y, z: a.z - b.z, }
}

///|
fn cond_q_scale(s : Double, a : CondQuaternion) -> CondQuaternion {
  CondQuaternion::{ w: s * a.w, x: s * a.x, y: s * a.y, z: s * a.z, }
}

///|
/// Hamilton product.  Multiplication is associative, not commutative.
pub fn cond_q_mul(a : CondQuaternion, b : CondQuaternion) -> CondQuaternion {
  CondQuaternion::{
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
  }
}

///|
/// Quaternion conjugate, the anti-automorphism dual used throughout the axis.
pub fn cond_q_conj(a : CondQuaternion) -> CondQuaternion {
  CondQuaternion::{ w: a.w, x: -a.x, y: -a.y, z: -a.z, }
}

///|
/// Squared Euclidean norm; exactly multiplicative in real quaternion algebra.
pub fn cond_q_norm2(a : CondQuaternion) -> Double {
  a.w * a.w + a.x * a.x + a.y * a.y + a.z * a.z
}

///|
fn cond_q_inverse(a : CondQuaternion) -> CondQuaternion? {
  let n2 = cond_q_norm2(a)
  if n2 <= 0.0 {
    None
  } else {
    Some(cond_q_scale(1.0 / n2, cond_q_conj(a)))
  }
}

///|
fn cond_q_approx(
  a : CondQuaternion,
  b : CondQuaternion,
  tolerance~ : Double = 0.000000000001,
) -> Bool {
  cond_q_norm2(cond_q_sub(a, b)) <= tolerance * tolerance
}

///|
fn cond_v_approx(
  a : CondVector3,
  b : CondVector3,
  tolerance~ : Double = 0.000000000001,
) -> Bool {
  let dx = a.x - b.x
  let dy = a.y - b.y
  let dz = a.z - b.z
  dx * dx + dy * dy + dz * dz <= tolerance * tolerance
}

///|
fn cond_v_dot(a : CondVector3, b : CondVector3) -> Double {
  a.x * b.x + a.y * b.y + a.z * b.z
}

///|
fn cond_v_cross(a : CondVector3, b : CondVector3) -> CondVector3 {
  CondVector3::{
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  }
}

///|
fn cond_v_norm2(a : CondVector3) -> Double {
  cond_v_dot(a, a)
}

///|
fn cond_q_of_vector(v : CondVector3) -> CondQuaternion {
  CondQuaternion::{ w: 0.0, x: v.x, y: v.y, z: v.z, }
}

///|
fn cond_vector_of_pure(q : CondQuaternion) -> CondVector3 {
  CondVector3::{ x: q.x, y: q.y, z: q.z, }
}

///|
/// Rotate by `v |-> q v q*`; meaningful as an isometry when `|q| = 1`.
pub fn cond_q_rotate(q : CondQuaternion, v : CondVector3) -> CondVector3 {
  cond_vector_of_pure(
    cond_q_mul(cond_q_mul(q, cond_q_of_vector(v)), cond_q_conj(q)),
  )
}

///|
/// Householder reflection across the plane normal to a pure unit quaternion:
/// `v |-> n v n`.  It squares to identity and has determinant `-1`.
pub fn cond_q_reflect(n : CondQuaternion, v : CondVector3) -> CondVector3 {
  cond_vector_of_pure(cond_q_mul(cond_q_mul(n, cond_q_of_vector(v)), n))
}

///|
/// Unit quaternion for a right-handed axis-angle rotation.
pub fn cond_q_axis_angle(axis : CondVector3, angle : Double) -> CondQuaternion? {
  let norm = cond_v_norm2(axis).sqrt()
  if norm <= 0.0 {
    return None
  }
  let half = angle / 2.0
  let s = @math.sin(half) / norm
  Some(CondQuaternion::{
    w: @math.cos(half),
    x: s * axis.x,
    y: s * axis.y,
    z: s * axis.z,
  })
}

///|
/// Exact constant-angular-velocity flow `q0 exp(omega t/2)` for pure `omega`.
pub fn cond_q_exact_flow(
  q0 : CondQuaternion,
  omega : CondQuaternion,
  duration : Double,
) -> CondQuaternion? {
  let norm = cond_q_norm2(omega).sqrt()
  if omega.w != 0.0 || norm <= 0.0 {
    return None
  }
  let half = norm * duration / 2.0
  let s = @math.sin(half) / norm
  let exp_part = CondQuaternion::{
    w: @math.cos(half),
    x: s * omega.x,
    y: s * omega.y,
    z: s * omega.z,
  }
  Some(cond_q_mul(q0, exp_part))
}

///|
fn cond_q_rhs(q : CondQuaternion, omega : CondQuaternion) -> CondQuaternion {
  cond_q_scale(0.5, cond_q_mul(q, omega))
}

///|
fn cond_q_rk4_step(
  q : CondQuaternion,
  omega : CondQuaternion,
  h : Double,
) -> CondQuaternion {
  let k1 = cond_q_rhs(q, omega)
  let k2 = cond_q_rhs(cond_q_add(q, cond_q_scale(h / 2.0, k1)), omega)
  let k3 = cond_q_rhs(cond_q_add(q, cond_q_scale(h / 2.0, k2)), omega)
  let k4 = cond_q_rhs(cond_q_add(q, cond_q_scale(h, k3)), omega)
  let increment = cond_q_add(
    cond_q_add(k1, cond_q_scale(2.0, k2)),
    cond_q_add(cond_q_scale(2.0, k3), k4),
  )
  cond_q_add(q, cond_q_scale(h / 6.0, increment))
}

///|
fn cond_q_rk4_flow(
  q0 : CondQuaternion,
  omega : CondQuaternion,
  duration : Double,
  steps : Int32,
) -> CondQuaternion {
  let h = duration / steps.to_double()
  let mut q = q0
  for _ in 0..<steps {
    q = cond_q_rk4_step(q, omega, h)
  }
  q
}

///|
fn cond_q_distance(a : CondQuaternion, b : CondQuaternion) -> Double {
  cond_q_norm2(cond_q_sub(a, b)).sqrt()
}

///|
fn cond_simpson_lorentzian(cutoff : Double, panels : Int32) -> Double {
  let h = cutoff / panels.to_double()
  let mut sum = 1.0 + 1.0 / (1.0 + cutoff * cutoff)
  for i in 1..<panels {
    let x = i.to_double() * h
    let weight = if i % 2 == 0 { 2.0 } else { 4.0 }
    sum = sum + weight / (1.0 + x * x)
  }
  sum * h / 3.0
}

///|
/// Compute the improper integral `integral_0^infinity dx/(1+x^2) = pi/2`
/// as a limit of Simpson truncations.  `panels` must be even and at least 4.
pub fn cond_q_improper_integral(
  cutoff~ : Double = 64.0,
  panels~ : Int32 = 4096,
) -> CondImproperIntegralReport {
  if cutoff <= 1.0 || panels < 4 || panels % 2 != 0 {
    return CondImproperIntegralReport::{
      cutoff,
      panels,
      finite_part: 0.0,
      tail_estimate: 0.0,
      tail_upper_bound: 0.0,
      coarse_limit_estimate: 0.0,
      limit_estimate: 0.0,
      cauchy_delta: 1.0,
      target: @math.PI / 2.0,
      residual: 1.0,
      converged: false,
    }
  }
  let finite_part = cond_simpson_lorentzian(cutoff, panels)
  let tail_estimate = @math.atan(1.0 / cutoff)
  let limit_estimate = finite_part + tail_estimate
  let coarse_cutoff = cutoff / 2.0
  let coarse_limit_estimate = cond_simpson_lorentzian(coarse_cutoff, panels / 2) +
    @math.atan(1.0 / coarse_cutoff)
  let target = @math.PI / 2.0
  let residual = (limit_estimate - target).abs()
  let cauchy_delta = (limit_estimate - coarse_limit_estimate).abs()
  CondImproperIntegralReport::{
    cutoff,
    panels,
    finite_part,
    tail_estimate,
    tail_upper_bound: 1.0 / cutoff,
    coarse_limit_estimate,
    limit_estimate,
    cauchy_delta,
    target,
    residual,
    converged: residual < 0.00000001 &&
    cauchy_delta < 0.00000001 &&
    finite_part > 0.0,
  }
}

///|
/// Verify fourth-order convergence and a Richardson limit for the quaternion ODE.
pub fn cond_q_ode_convergence() -> CondQuaternionOdeReport {
  let q0 = CondQuaternion::{ w: 1.0, x: 0.0, y: 0.0, z: 0.0, }
  let omega = CondQuaternion::{ w: 0.0, x: 0.0, y: 0.0, z: 2.0, }
  let duration = @math.PI / 4.0
  let exact = match cond_q_exact_flow(q0, omega, duration) {
    Some(q) => q
    None => q0
  }
  let steps = [4, 8, 16, 32]
  let errors : Array[Double] = []
  let norm_drifts : Array[Double] = []
  let states : Array[CondQuaternion] = []
  let mut max_norm_drift = 0.0
  for n in steps {
    let qn = cond_q_rk4_flow(q0, omega, duration, n)
    states.push(qn)
    errors.push(cond_q_distance(qn, exact))
    let drift = (cond_q_norm2(qn) - cond_q_norm2(q0)).abs()
    norm_drifts.push(drift)
    if drift > max_norm_drift {
      max_norm_drift = drift
    }
  }
  let last = steps.length() - 1
  let observed_order = @math.ln(errors[last - 1] / errors[last]) / @math.ln(2.0)
  let richardson = cond_q_add(
    states[last],
    cond_q_scale(1.0 / 15.0, cond_q_sub(states[last], states[last - 1])),
  )
  let richardson_limit_error = cond_q_distance(richardson, exact)
  let backward = cond_q_rk4_flow(
    states[last],
    cond_q_scale(-1.0, omega),
    duration,
    steps[last],
  )
  let reverse_roundtrip_error = cond_q_distance(backward, q0)
  let mut decreasing = true
  let mut drift_decreasing = true
  for i in 1..<errors.length() {
    if errors[i] >= errors[i - 1] {
      decreasing = false
    }
    if norm_drifts[i] >= norm_drifts[i - 1] {
      drift_decreasing = false
    }
  }
  let fine_norm_drift = norm_drifts[last]
  CondQuaternionOdeReport::{
    steps,
    errors,
    norm_drifts,
    observed_order,
    richardson_limit_error,
    max_norm_drift,
    fine_norm_drift,
    reverse_roundtrip_error,
    converged: decreasing &&
    drift_decreasing &&
    observed_order > 3.5 &&
    observed_order < 4.5 &&
    richardson_limit_error < errors[last] &&
    richardson_limit_error < 0.00000001 &&
    fine_norm_drift < 0.00000001 &&
    reverse_roundtrip_error < 0.00000001,
  }
}

// ---------------------------------------------------------------------------
// Exact Q_8 elimination category and signed integer rotations
// ---------------------------------------------------------------------------

///|
fn cond_q8_mul(a : Int32, b : Int32) -> Int32 {
  let basis_table = [[0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [3, 2, 1, 0]]
  let sign_table = [
    [1, 1, 1, 1],
    [1, -1, 1, -1],
    [1, -1, -1, 1],
    [1, 1, -1, -1],
  ]
  let aa = a % 4
  let bb = b % 4
  let sign_a = if a < 4 { 1 } else { -1 }
  let sign_b = if b < 4 { 1 } else { -1 }
  let result_basis = basis_table[aa][bb]
  let result_sign = sign_a * sign_b * sign_table[aa][bb]
  if result_sign > 0 {
    result_basis
  } else {
    result_basis + 4
  }
}

///|
fn cond_q8_inv(a : Int32) -> Int32 {
  if a % 4 == 0 {
    a
  } else {
    (a + 4) % 8
  }
}

///|
fn cond_q8_conj(g : Int32, x : Int32) -> Int32 {
  cond_q8_mul(cond_q8_mul(g, x), cond_q8_inv(g))
}

///|
/// Canonical-elimination object for `Q_8 / {+/-1}`: eight elements, four classes.
pub fn cond_q8_elimination_object() -> CanonObject {
  canon_object_build(
    "Q8/projective-sign-elimination",
    8,
    (x, y) => x % 4 == y % 4,
    x => x % 4,
  )
}

///|
fn cond_q8_category_ok(obj : CanonObject) -> Bool {
  if obj.size != 8 ||
    obj.class_count != 4 ||
    !obj.is_complete ||
    !obj.idempotent {
    return false
  }
  for g in 0..<8 {
    let map : Array[Int32] = []
    for x in 0..<8 {
      map.push(cond_q8_conj(g, x))
      if cond_q8_conj(cond_q8_inv(g), cond_q8_conj(g, x)) != x {
        return false
      }
    }
    if !canon_morphism_valid(CanonMorphism::{ dom: obj, cod: obj, map, }) {
      return false
    }
    for h in 0..<8 {
      for x in 0..<8 {
        if cond_q8_conj(g, cond_q8_conj(h, x)) !=
          cond_q8_conj(cond_q8_mul(g, h), x) {
          return false
        }
      }
    }
  }
  for a in 0..<8 {
    for b in 0..<8 {
      for c in 0..<8 {
        if cond_q8_mul(cond_q8_mul(a, b), c) !=
          cond_q8_mul(a, cond_q8_mul(b, c)) {
          return false
        }
      }
    }
  }
  true
}

///|
fn cond_q8_rotate_vec(g : Int32, v : Array[Int32]) -> Array[Int32] {
  let out = [0, 0, 0]
  for basis in 1..<4 {
    let image = cond_q8_conj(g, basis)
    let image_basis = image % 4
    let sign = if image < 4 { 1 } else { -1 }
    out[image_basis - 1] = out[image_basis - 1] + sign * v[basis - 1]
  }
  out
}

///|
fn cond_vec3_int_norm2(v : Array[Int32]) -> Int32 {
  v[0] * v[0] + v[1] * v[1] + v[2] * v[2]
}

///|
fn cond_vec3_int_eq(a : Array[Int32], b : Array[Int32]) -> Bool {
  a[0] == b[0] && a[1] == b[1] && a[2] == b[2]
}

///|
fn cond_q8_vector_rotation_ok() -> Bool {
  let samples = [[1, 2, 3], [-2, 5, 7]]
  for g in 0..<8 {
    for v in samples {
      let rotated = cond_q8_rotate_vec(g, v)
      let roundtrip = cond_q8_rotate_vec(cond_q8_inv(g), rotated)
      let reflected = [-v[0], v[1], v[2]]
      if !cond_vec3_int_eq(roundtrip, v) ||
        cond_vec3_int_norm2(rotated) != cond_vec3_int_norm2(v) ||
        cond_vec3_int_norm2(reflected) != cond_vec3_int_norm2(v) {
        return false
      }
    }
  }
  true
}

///|
/// Build exact norm observations and derive their Z-linear conservation laws.
pub fn cond_quaternion_axis_ledger() -> CondInvariantLedger {
  let samples = [[1, 2, 3], [-2, 5, 7]]
  let mut ledger = cond_ledger_new()
  for g in 0..<8 {
    for v in samples {
      let rotated = cond_q8_rotate_vec(g, v)
      let roundtrip = cond_q8_rotate_vec(cond_q8_inv(g), rotated)
      let reflected = [-v[0], v[1], v[2]]
      if !cond_vec3_int_eq(roundtrip, v) {
        // A failing witness is still recorded; the final report rejects it.
        ledger = cond_ledger_append(ledger, 0, [0, 0, 0, 1], [])
      } else {
        ledger = cond_ledger_append(
          ledger,
          0,
          [
            cond_vec3_int_norm2(v),
            cond_vec3_int_norm2(rotated),
            cond_vec3_int_norm2(roundtrip),
            cond_vec3_int_norm2(reflected),
          ],
          [],
        )
      }
    }
  }
  let derived = cond_ledger_derive_invariants(ledger)
  cond_ledger_append(derived, 2, [8, 4, 3], [0, derived.entries.length() - 1])
}

///|
fn cond_sample_unit_quaternion() -> CondQuaternion {
  match cond_q_axis_angle(CondVector3::{ x: 1.0, y: 2.0, z: 3.0, }, 0.6) {
    Some(q) => q
    None => CondQuaternion::{ w: 1.0, x: 0.0, y: 0.0, z: 0.0, }
  }
}

///|
fn cond_axis_numeric_dual_ok(q : CondQuaternion) -> Bool {
  let p = match
    cond_q_axis_angle(CondVector3::{ x: -2.0, y: 1.0, z: 0.5, }, -0.4) {
    Some(x) => x
    None => q
  }
  let anti = cond_q_approx(
    cond_q_conj(cond_q_mul(p, q)),
    cond_q_mul(cond_q_conj(q), cond_q_conj(p)),
  )
  let norm_product = (cond_q_norm2(cond_q_mul(p, q)) -
    cond_q_norm2(p) * cond_q_norm2(q)).abs() <
    0.000000000001
  anti && norm_product
}

///|
fn cond_axis_implication_ok(q : CondQuaternion) -> Bool {
  let unit_inverse = match cond_q_inverse(q) {
    Some(inv) => inv
    None => q
  }
  let nonunit = cond_q_scale(2.0, q)
  let nonunit_inverse = match cond_q_inverse(nonunit) {
    Some(inv) => inv
    None => nonunit
  }
  cond_q_approx(unit_inverse, cond_q_conj(q)) &&
  !cond_q_approx(nonunit_inverse, cond_q_conj(nonunit))
}

///|
fn cond_axis_reflection_ok(q : CondQuaternion, v : CondVector3) -> Bool {
  let n = CondQuaternion::{ w: 0.0, x: 1.0, y: 0.0, z: 0.0, }
  let reflected = cond_q_reflect(n, v)
  let twice = cond_q_reflect(n, reflected)
  let e1 = CondVector3::{ x: 1.0, y: 0.0, z: 0.0, }
  let e2 = CondVector3::{ x: 0.0, y: 1.0, z: 0.0, }
  let e3 = CondVector3::{ x: 0.0, y: 0.0, z: 1.0, }
  let r1 = cond_q_reflect(n, e1)
  let r2 = cond_q_reflect(n, e2)
  let r3 = cond_q_reflect(n, e3)
  let reflection_det = cond_v_dot(r1, cond_v_cross(r2, r3))
  let q1 = cond_q_rotate(q, e1)
  let q2 = cond_q_rotate(q, e2)
  let q3 = cond_q_rotate(q, e3)
  let rotation_det = cond_v_dot(q1, cond_v_cross(q2, q3))
  cond_v_approx(twice, v) &&
  (cond_v_norm2(reflected) - cond_v_norm2(v)).abs() < 0.000000000001 &&
  (reflection_det + 1.0).abs() < 0.000000000001 &&
  (rotation_det - 1.0).abs() < 0.000000000001
}

///|
fn cond_axis_sequence_ok(q : CondQuaternion, v : CondVector3) -> Bool {
  let q1 = q
  let q2 = match
    cond_q_axis_angle(CondVector3::{ x: 0.0, y: 1.0, z: 0.0, }, 0.3) {
    Some(x) => x
    None => q
  }
  let q3 = match
    cond_q_axis_angle(CondVector3::{ x: 0.0, y: 0.0, z: 1.0, }, -0.2) {
    Some(x) => x
    None => q
  }
  let sequential = cond_q_rotate(q3, cond_q_rotate(q2, cond_q_rotate(q1, v)))
  let forward_product = cond_q_mul(q3, cond_q_mul(q2, q1))
  let reverse_product = cond_q_mul(
    cond_q_conj(q1),
    cond_q_mul(cond_q_conj(q2), cond_q_conj(q3)),
  )
  let restored = cond_q_rotate(
    cond_q_conj(q1),
    cond_q_rotate(cond_q_conj(q2), cond_q_rotate(cond_q_conj(q3), sequential)),
  )
  let identity = CondQuaternion::{ w: 1.0, x: 0.0, y: 0.0, z: 0.0, }
  cond_v_approx(sequential, cond_q_rotate(forward_product, v)) &&
  cond_q_approx(cond_q_mul(forward_product, reverse_product), identity) &&
  cond_v_approx(restored, v)
}

///|
fn cond_axis_discrete_compact_ok() -> Bool {
  let compact_point = cond_solid_module_build(cond_prof_pt(5), 1, 1, 2)
  let profinite = cond_solid_module_build(cond_prof_cantor(3, 5), 1, 1, 2)
  compact_point.solid_gap == 0 &&
  profinite.solid_gap == 6 &&
  compact_point.ext1_vanishes &&
  profinite.ext1_vanishes
}

///|
/// Evaluate every requested relation and audit exact conservation on the X-pivot.
pub fn cond_quaternion_axis_report() -> CondQuaternionAxisReport {
  let q = cond_sample_unit_quaternion()
  let v = CondVector3::{ x: 1.0, y: 2.0, z: 3.0, }
  let obj = cond_q8_elimination_object()
  let elimination_category_ok = cond_q8_category_ok(obj) &&
    cond_q8_vector_rotation_ok()
  let dual_ok = cond_axis_numeric_dual_ok(q)
  let implication_ok = cond_axis_implication_ok(q)
  let reflection_ok = cond_axis_reflection_ok(q, v)
  let restored = cond_q_rotate(cond_q_conj(q), cond_q_rotate(q, v))
  let integral = cond_q_improper_integral()
  let ode = cond_q_ode_convergence()
  let forward_reverse_ok = cond_v_approx(restored, v) &&
    ode.reverse_roundtrip_error < 0.00000001
  let coarse_fine_ok = obj.size == 8 &&
    obj.class_count == 4 &&
    integral.cauchy_delta < 0.00000001 &&
    ode.converged
  let discrete_compact_ok = cond_axis_discrete_compact_ok()
  let sequence_antisequence_ok = cond_axis_sequence_ok(q, v) &&
    elimination_category_ok
  let ledger = cond_quaternion_axis_ledger()
  let (laws_passed, laws_failed) = cond_ledger_audit_laws(ledger)
  let snapshot_entries = ledger.entries.length()
  let snapshot_tip = ledger.tip
  let extended = cond_ledger_append(ledger, 0, [1, 1, 1, 1], [])
  let persistent_snapshot_ok = ledger.entries.length() == snapshot_entries &&
    ledger.tip == snapshot_tip &&
    extended.entries.length() == snapshot_entries + 1 &&
    extended.entries[snapshot_entries].prev_hash == snapshot_tip &&
    cond_ledger_verify(ledger) &&
    cond_ledger_verify(extended)
  let first = ledger.entries[0]
  let changed_values = first.values.copy()
  changed_values[0] = changed_values[0] + 1
  let tampered_entries = ledger.entries.copy()
  tampered_entries[0] = CondLedgerEntry::{
    seq: first.seq,
    kind: first.kind,
    values: changed_values,
    parents: first.parents,
    prev_hash: first.prev_hash,
    hash: first.hash,
  }
  let tampered = CondInvariantLedger::{
    entries: tampered_entries,
    tip: ledger.tip,
  }
  let tamper_detected = !cond_ledger_verify(tampered)
  let conserved = dual_ok &&
    implication_ok &&
    reflection_ok &&
    forward_reverse_ok &&
    coarse_fine_ok &&
    discrete_compact_ok &&
    sequence_antisequence_ok &&
    elimination_category_ok &&
    integral.converged &&
    integral.tail_upper_bound < 0.02 &&
    ode.converged &&
    laws_passed == 3 &&
    laws_failed == 0 &&
    ledger.entries.length() == 20 &&
    cond_ledger_verify(ledger) &&
    persistent_snapshot_ok &&
    tamper_detected
  CondQuaternionAxisReport::{
    dual_ok,
    implication_ok,
    reflection_ok,
    forward_reverse_ok,
    coarse_fine_ok,
    discrete_compact_ok,
    sequence_antisequence_ok,
    elimination_category_ok,
    integral,
    ode,
    conservation_laws_passed: laws_passed,
    conservation_laws_failed: laws_failed,
    ledger_entries: ledger.entries.length(),
    ledger_tip: ledger.tip,
    persistent_snapshot_ok,
    tamper_detected,
    conserved,
  }
}

///|
/// Boolean law-runner entry point used by cross-federation certificates.
pub fn cond_quaternion_axis_conserved() -> Bool {
  cond_quaternion_axis_report().conserved
}
