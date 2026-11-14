///|
// Federation 7 (`discovery`) — Layer 4 Package `conjecture` (Part 3, iteration 3):
// polynomial evolution laws with subspace transfer and Lakatos refinement.
//
// The six linear families of Part 1 fix the parameter (`p = 3`, `n = 5`, ...) and discover
// a relation with numeric coefficients. Here the parameter itself is an observed column,
// so the engine has to find the law as a polynomial in the parameter:
//
//   1. `[E-Poly-Radon]`   `c - n*b - a^2 = 0`  (affine Plancherel on `Z_n^2`, `n` prime),
//                          from `@tensor`'s Radon transform;
//   2. `[E-Poly-Hensel]`  `w - q*u = 0`        (`|S_{k+2}| = q |S_k|` for `x^2 ≡ 0 mod q^k`),
//                          from `@condensed`'s solution towers;
//   3. `[E-Barcode]`      `m - 3*d = 0`        (death scale of the circle class of `C_m`),
//                          from `@tensor`'s persistence barcodes, with its refinement
//                          `m - 3*d + r = 0`, `r = (-m) mod 3`, for arbitrary `m`.
//
// Training on two parameter values always admits the interpolation mirage
// `(param - v1)(param - v2) = 0`; the transfer value removes it. Every surviving law is
// committed to a `CondInvariantLedger` and re-checked through a Merkle inclusion proof.

///|
pub using @dkernel {
  type MonomialBasis,
  type PolyInvariantReport,
  type PolyTransferReport,
  monomial_basis_build,
  veronese_lift_rowset,
  poly_relation_to_string,
  derive_polynomial_invariants,
  polynomial_transfer_experiment,
  check_polynomial_discovery_laws,
}

///|
/// One polynomial discovery-and-transfer experiment.
///
/// * `law` — the single surviving relation, rendered over the monomial basis
///   (empty when the experiment did not end with exactly one survivor);
/// * `mirages_killed` — dimension of the relations that held on the training rows only;
/// * `matches_expected` — the survivor is the law predicted by the theory;
/// * `boundary_counterexample` — the law was observed to FAIL outside its hypothesis
///   (composite `n`, `3 ∤ m`, ...), so the hypothesis is not decorative;
/// * `refinement` — the repaired statement that also covers the counterexamples, or the
///   hypothesis that excludes them.
#derive(Debug, Eq)
pub(all) struct PolynomialLawReport {
  family_id : String
  degree : Int32
  law : String
  train_nullity : Int32
  mirages_killed : Int32
  matches_expected : Bool
  boundary_counterexample : Bool
  refinement : String
}

///|
pub extend PolynomialLawReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PolynomialLawReport with Eq::{not_equal, equal}

///|
/// All polynomial experiments plus their ledger commitment.
#derive(Debug, Eq)
pub(all) struct PolynomialDiscoverySummary {
  reports : Array[PolynomialLawReport]
  ledger : @gcd.CondInvariantLedger
  merkle_root : UInt64
  ledger_chain_ok : Bool
  inclusion_proofs_ok : Bool
  all_ok : Bool
}

///|
pub extend PolynomialDiscoverySummary with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend PolynomialDiscoverySummary with Eq::{not_equal, equal}

///|
let poly_primes : Array[Int32] = [65521, 10007, 32749]

///|
/// Radon energy observations `(n, a, b, c) = (n, sum f, sum f^2, sum (Rf)^2)` on `Z_n^2`
/// for `count` deterministic test functions with values in `0..3`.
fn radon_energy_rows(n : Int32, count : Int32) -> Array[Array[Int32]] {
  let r = @tensor.radon_make(n, 10007)
  let rows : Array[Array[Int32]] = []
  let mut seed = 2024 + n
  for _ in 0..<count {
    let f : Array[Int32] = Array::makei(n * n, _ => {
      seed = (seed * 1103 + 12345) % 1000003
      seed / 7 % 4
    })
    let rf = @tensor.radon_apply_exact(r, f)
    let mut a = 0
    let mut b = 0
    let mut c = 0
    for v in f {
      a = a + v
      b = b + v * v
    }
    for v in rf {
      c = c + v * v
    }
    rows.push([n, a, b, c])
  }
  rows
}

///|
fn poly_report_from_transfer(
  family_id : String,
  degree : Int32,
  tr : PolyTransferReport?,
  expected : String,
  boundary_counterexample : Bool,
  refinement : String,
) -> (PolynomialLawReport, Array[Int32]) {
  match tr {
    Some(t) if t.surviving_nullity == 1 &&
      t.surviving.length() == 1 &&
      t.primes_agree => {
      let law = poly_relation_to_string(t.monomials, t.surviving[0])
      (
        PolynomialLawReport::{
          family_id,
          degree,
          law,
          train_nullity: t.train_nullity,
          mirages_killed: t.mirages_killed,
          matches_expected: law == expected,
          boundary_counterexample,
          refinement,
        },
        t.surviving[0],
      )
    }
    Some(t) =>
      (
        PolynomialLawReport::{
          family_id,
          degree,
          law: "",
          train_nullity: t.train_nullity,
          mirages_killed: t.mirages_killed,
          matches_expected: false,
          boundary_counterexample,
          refinement,
        },
        [],
      )
    None =>
      (
        PolynomialLawReport::{
          family_id,
          degree,
          law: "",
          train_nullity: 0,
          mirages_killed: 0,
          matches_expected: false,
          boundary_counterexample,
          refinement,
        },
        [],
      )
  }
}

///|
/// Death scale of the 1-dimensional class of `VR(C_m)` born at scale 1, or `-1`.
fn cycle_h1_death(m : Int32) -> Int32 {
  match
    @tensor.metric_vr_persistence_barcode(@tensor.metric_cycle_graph(m), 2) {
    Some(rep) => {
      let mut death = -1
      let mut seen = 0
      for bar in rep.bars {
        if bar[0] == 1 {
          seen = seen + 1
          if bar[1] == 1 {
            death = bar[2]
          }
        }
      }
      if seen == 1 {
        death
      } else {
        -1
      }
    }
    None => -1
  }
}

///|
/// Run the three polynomial experiments and commit the surviving laws.
pub fn discover_polynomial_transfer_laws() -> PolynomialDiscoverySummary {
  let reports : Array[PolynomialLawReport] = []
  let committed : Array[Array[Int32]] = []

  // 1. [E-Poly-Radon]: train n in {2, 3}, transfer n = 5, boundary n = 4 (composite).
  let radon_cols = ["n", "a", "b", "c"]
  let radon_train = ObservationRowSet::{
    name: "radon_n2_n3",
    columns: radon_cols,
    rows: [..radon_energy_rows(2, 12), ..radon_energy_rows(3, 12)],
  }
  let radon_transfer = ObservationRowSet::{
    name: "radon_n5",
    columns: radon_cols,
    rows: radon_energy_rows(5, 8),
  }
  let mut composite_breaks = false
  for row in radon_energy_rows(4, 8) {
    if row[3] - row[0] * row[2] - row[1] * row[1] != 0 {
      composite_breaks = true
    }
  }
  let (radon_rep, radon_rel) = poly_report_from_transfer(
    "[E-Poly-Radon]",
    2,
    polynomial_transfer_experiment(radon_train, radon_transfer, 2, poly_primes),
    "c - n*b - a^2 = 0",
    composite_breaks,
    "hypothesis: n prime (Z_n^2 is an affine plane); fails at n = 4",
  )
  reports.push(radon_rep)
  committed.push(radon_rel)

  // 2. [E-Poly-Hensel]: root counts of x^2 modulo q^k, train q in {2, 3}, transfer q = 5.
  //    Boundary: for x^2 - 1 the count is eventually constant, so `w = q*u` is specific to
  //    the singular root.
  let hensel_rows = (coeffs : Array[Int32], q : Int32, levels : Int32) => {
    let rows : Array[Array[Int32]] = []
    match @condensed.cond_solution_tower_build(coeffs, q, levels) {
      Some(t) =>
        for k in 0..<(levels - 2) {
          rows.push([q, t.roots[k].length(), t.roots[k + 2].length()])
        }
      None => ()
    }
    rows
  }
  let hensel_cols = ["q", "u", "w"]
  let hensel_train = ObservationRowSet::{
    name: "hensel_q2_q3",
    columns: hensel_cols,
    rows: [..hensel_rows([0, 0, 1], 2, 8), ..hensel_rows([0, 0, 1], 3, 6)],
  }
  let hensel_transfer = ObservationRowSet::{
    name: "hensel_q5",
    columns: hensel_cols,
    rows: hensel_rows([0, 0, 1], 5, 6),
  }
  let mut simple_root_breaks = false
  for row in hensel_rows([-1, 0, 1], 5, 6) {
    if row[2] - row[0] * row[1] != 0 {
      simple_root_breaks = true
    }
  }
  let (hensel_rep, hensel_rel) = poly_report_from_transfer(
    "[E-Poly-Hensel]",
    2,
    polynomial_transfer_experiment(
      hensel_train, hensel_transfer, 2, poly_primes,
    ),
    "w - q*u = 0",
    simple_root_breaks,
    "hypothesis: double root (x^2); for x^2 - 1 Hensel gives w = u",
  )
  reports.push(hensel_rep)
  committed.push(hensel_rel)

  // 3. [E-Barcode]: death scale d of the circle class of C_m, train m in {6, 9},
  //    transfer m = 12. Off the multiples of 3 the law fails; adding the residue column
  //    r = (-m) mod 3 lets the same engine find the refined law for all m in 6..12.
  let bar_rows = (ms : Array[Int32]) => ms.map(m => [m, cycle_h1_death(m)])
  let bar_cols = ["m", "d"]
  let bar_train = ObservationRowSet::{
    name: "cycle_m6_m9",
    columns: bar_cols,
    rows: bar_rows([6, 9]),
  }
  let bar_transfer = ObservationRowSet::{
    name: "cycle_m12",
    columns: bar_cols,
    rows: bar_rows([12]),
  }
  let off_rows = bar_rows([7, 8, 10, 11])
  let mut off_breaks = false
  for row in off_rows {
    if row[1] < 0 {
      // No bar found: treat as failure of the experiment, not as a counterexample.
      off_breaks = false
      break
    }
    if row[0] - 3 * row[1] != 0 {
      off_breaks = true
    }
  }
  let refined_rows : Array[Array[Int32]] = []
  for m in 6..<=12 {
    refined_rows.push([m, cycle_h1_death(m), (3 - m % 3) % 3])
  }
  let refined = ObservationRowSet::{
    name: "cycle_refined",
    columns: ["m", "d", "r"],
    rows: refined_rows,
  }
  let refined_law = match
    derive_polynomial_invariants(refined, 1, poly_primes) {
    Some(rep) if rep.relations.length() == 1 && rep.nullity_by_degree[1] == 1 =>
      poly_relation_to_string(rep.monomials, rep.relations[0])
    _ => ""
  }
  let (bar_rep, bar_rel) = poly_report_from_transfer(
    "[E-Barcode]",
    1,
    polynomial_transfer_experiment(bar_train, bar_transfer, 1, poly_primes),
    "m - 3*d = 0",
    off_breaks,
    refined_law,
  )
  reports.push(bar_rep)
  committed.push(bar_rel)

  // Commit: one `kind = 1` (derived law) entry per surviving relation, then a theorem
  // entry pointing at them.
  let mut ledger = @gcd.cond_ledger_new()
  let parents : Array[Int32] = []
  for rel in committed {
    if rel.length() > 0 {
      parents.push(ledger.entries.length())
      ledger = @gcd.cond_ledger_append(ledger, 1, rel, [])
    }
  }
  ledger = @gcd.cond_ledger_append(ledger, 2, [reports.length()], parents)
  let root = @condensed.cond_ledger_merkle_root(ledger)
  let n = ledger.entries.length()
  let mut inclusion_ok = true
  for i in 0..<n {
    match @condensed.cond_ledger_inclusion_proof(ledger, i) {
      Some(proof) =>
        if !@condensed.cond_ledger_verify_inclusion(
            root,
            n,
            ledger.entries[i],
            proof,
          ) {
          inclusion_ok = false
        }
      None => inclusion_ok = false
    }
  }
  let chain_ok = @gcd.cond_ledger_verify(ledger)
  let mut all_ok = chain_ok && inclusion_ok && n == reports.length() + 1
  for rep in reports {
    if !rep.matches_expected || !rep.boundary_counterexample {
      all_ok = false
    }
  }
  // The two parameterised families must have had a mirage to reject, and the barcode
  // refinement must be the predicted one.
  if reports[0].mirages_killed < 1 ||
    reports[1].mirages_killed < 1 ||
    reports[2].refinement != "m - 3*d + r = 0" {
    all_ok = false
  }
  PolynomialDiscoverySummary::{
    reports,
    ledger,
    merkle_root: root,
    ledger_chain_ok: chain_ok,
    inclusion_proofs_ok: inclusion_ok,
    all_ok,
  }
}
