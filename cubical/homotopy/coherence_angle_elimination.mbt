///|
// Finite local-coherence-angle elimination for the declared cell/Kan model.
//
// The cardinalities in this file are not new theorems about every
// associahedron.  They encode the requested finite model: 24 local cells,
// 23 distinct ordered partners per cell, and 20 Kan-filler representatives
// per ordered pair.  Thus the input has 24*23*20 = 11040 local angle
// incidences.  The first quotient identifies the 20 filler representatives
// of each ordered pair, leaving 24*23 = 552.  The second quotient identifies
// reverse orientations, so all 552 are resolved into 276 canonical pair
// classes.  "Resolved" does not mean deleting the conserved incidence count:
// the 276 class multiplicities still sum to 11040.

///|
/// Auditable before/after counts for the finite coherence-angle quotient.
#derive(Debug, Eq)
pub(all) struct CoherenceAngleEliminationReport {
  local_cells : Int32
  filler_variants : Int32
  total_angles : Int32
  enumerated_angles : Int32
  coarse_representatives : Int32
  coarse_eliminated : Int32
  remaining_before_reverse_elimination : Int32
  reverse_pair_classes : Int32
  reverse_pair_eliminated : Int32
  remaining_after : Int32
  conserved_incidence_count : Int32
  partition_ok : Bool
  negative_control_detected : Bool
  kan_filler_ok : Bool
  associahedron_ok : Bool
  holds : Bool
}

///|
pub extend CoherenceAngleEliminationReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend CoherenceAngleEliminationReport with Eq::{not_equal, equal}

///|
/// Parameter-sized quotient summary used to attack the scaling conjecture.
#derive(Debug, Eq)
pub(all) struct CoherenceQuotientSummary {
  local_cells : Int32
  filler_variants : Int32
  total_angles : Int32
  ordered_classes : Int32
  unordered_classes : Int32
  conserved_incidence_count : Int32
  holds : Bool
}

///|
pub extend CoherenceQuotientSummary with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend CoherenceQuotientSummary with Eq::{not_equal, equal}

///|
priv struct CoherencePartitionAudit {
  total : Int32
  ordered_classes : Int32
  unordered_classes : Int32
  conserved_incidences : Int32
  ok : Bool
}

///|
fn coherence_int_zeros(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for _i in 0..<n {
    out.push(0)
  }
  out
}

///|
/// Index an ordered pair `(a,b)`, `a != b`, without storing a quadratic table.
fn coherence_ordered_pair_class(n : Int32, a : Int32, b : Int32) -> Int32 {
  a * (n - 1) + (if b < a { b } else { b - 1 })
}

///|
/// Index an unordered pair by lexicographic order of `(min,max)`.
fn coherence_unordered_pair_class(n : Int32, a : Int32, b : Int32) -> Int32 {
  let lo = if a < b { a } else { b }
  let hi = if a < b { b } else { a }
  lo * (2 * n - lo - 1) / 2 + hi - lo - 1
}

///|
/// Enumerate every angle and audit both quotients independently by class
/// multiplicities.  With `tamper=true`, exactly one incidence is assigned to
/// the next ordered and unordered class; this must break the audit.
fn coherence_partition_audit(
  n : Int32,
  filler_variants : Int32,
  tamper~ : Bool = false,
) -> CoherencePartitionAudit {
  if n < 2 || filler_variants <= 0 {
    return CoherencePartitionAudit::{
      total: 0,
      ordered_classes: 0,
      unordered_classes: 0,
      conserved_incidences: 0,
      ok: false,
    }
  }
  let ordered_classes = n * (n - 1)
  let unordered_classes = ordered_classes / 2
  let ordered_sizes = coherence_int_zeros(ordered_classes)
  let unordered_sizes = coherence_int_zeros(unordered_classes)
  let orientation_classes = coherence_int_zeros(ordered_classes)
  for i in 0..<ordered_classes {
    orientation_classes[i] = -1
  }
  let mut total = 0
  let mut tampered = false
  for a in 0..<n {
    for b in 0..<n {
      if a != b {
        let ordered = coherence_ordered_pair_class(n, a, b)
        let unordered = coherence_unordered_pair_class(n, a, b)
        for _filler in 0..<filler_variants {
          let wrong = tamper && !tampered
          let ordered_target = if wrong {
            (ordered + 1) % ordered_classes
          } else {
            ordered
          }
          let unordered_target = if wrong {
            (unordered + 1) % unordered_classes
          } else {
            unordered
          }
          ordered_sizes[ordered_target] = ordered_sizes[ordered_target] + 1
          unordered_sizes[unordered_target] = unordered_sizes[unordered_target] +
            1
          if wrong {
            tampered = true
          }
          total = total + 1
        }
        orientation_classes[ordered] = if tamper && a == 0 && b == 1 {
          (unordered + 1) % unordered_classes
        } else {
          unordered
        }
      }
    }
  }
  let mut multiplicities_ok = true
  let mut ordered_sum = 0
  for size in ordered_sizes {
    ordered_sum = ordered_sum + size
    if size != filler_variants {
      multiplicities_ok = false
    }
  }
  let mut conserved_incidences = 0
  for size in unordered_sizes {
    conserved_incidences = conserved_incidences + size
    if size != 2 * filler_variants {
      multiplicities_ok = false
    }
  }
  let mut reverse_pairs_ok = true
  for a in 0..<n {
    for b in (a + 1)..<n {
      let forward = orientation_classes[coherence_ordered_pair_class(n, a, b)]
      let reverse = orientation_classes[coherence_ordered_pair_class(n, b, a)]
      if forward != reverse {
        reverse_pairs_ok = false
      }
    }
  }
  let expected_total = ordered_classes * filler_variants
  let ok = total == expected_total &&
    ordered_sum == expected_total &&
    conserved_incidences == expected_total &&
    multiplicities_ok &&
    reverse_pairs_ok &&
    (!tamper || tampered)
  CoherencePartitionAudit::{
    total,
    ordered_classes,
    unordered_classes,
    conserved_incidences,
    ok,
  }
}

///|
/// Run the quotient for arbitrary model parameters.  This is a finite
/// combinatorial audit, not a claim that arbitrary cell complexes have these
/// parameters or that a bounded parameter sweep proves a general theorem.
pub fn coherence_quotient_summary(
  local_cells : Int32,
  filler_variants : Int32,
) -> CoherenceQuotientSummary {
  let audit = coherence_partition_audit(local_cells, filler_variants)
  let valid = local_cells >= 2 && filler_variants > 0
  let expected_ordered = if valid { local_cells * (local_cells - 1) } else { 0 }
  let expected_unordered = expected_ordered / 2
  let expected_total = expected_ordered * filler_variants
  let holds = valid &&
    audit.ok &&
    audit.total == expected_total &&
    audit.ordered_classes == expected_ordered &&
    audit.unordered_classes == expected_unordered &&
    audit.conserved_incidences == expected_total
  CoherenceQuotientSummary::{
    local_cells,
    filler_variants,
    total_angles: audit.total,
    ordered_classes: audit.ordered_classes,
    unordered_classes: audit.unordered_classes,
    conserved_incidence_count: audit.conserved_incidences,
    holds,
  }
}

///|
/// Eliminate the requested 11040-angle finite model and verify the actual
/// dependent Kan operations plus the existing K3--K9 associahedron audits.
pub fn coherence_angle_elimination_report() -> CoherenceAngleEliminationReport {
  let local_cells = 24
  let filler_variants = 20
  let normal = coherence_partition_audit(local_cells, filler_variants)
  let tampered = coherence_partition_audit(
    local_cells,
    filler_variants,
    tamper=true,
  )
  let kan_filler_ok = @kernel.check_kan_dep_all()
  let associahedron_ok = check_assoc_faces()
  let negative_control_detected = !tampered.ok
  let remaining_after = if normal.ok &&
    negative_control_detected &&
    kan_filler_ok &&
    associahedron_ok {
    0
  } else {
    normal.ordered_classes
  }
  let coarse_eliminated = normal.total - normal.ordered_classes
  let reverse_pair_eliminated = normal.ordered_classes -
    normal.unordered_classes
  let holds = normal.total == 11040 &&
    normal.ordered_classes == 552 &&
    coarse_eliminated == 10488 &&
    normal.unordered_classes == 276 &&
    reverse_pair_eliminated == 276 &&
    remaining_after == 0 &&
    normal.conserved_incidences == normal.total &&
    normal.ok &&
    negative_control_detected &&
    kan_filler_ok &&
    associahedron_ok
  CoherenceAngleEliminationReport::{
    local_cells,
    filler_variants,
    total_angles: normal.total,
    enumerated_angles: normal.total,
    coarse_representatives: normal.ordered_classes,
    coarse_eliminated,
    remaining_before_reverse_elimination: normal.ordered_classes,
    reverse_pair_classes: normal.unordered_classes,
    reverse_pair_eliminated,
    remaining_after,
    conserved_incidence_count: normal.conserved_incidences,
    partition_ok: normal.ok,
    negative_control_detected,
    kan_filler_ok,
    associahedron_ok,
    holds,
  }
}

///|
/// Boolean law-runner entry point for the finite coherence-angle certificate.
pub fn check_coherence_angle_elimination() -> Bool {
  coherence_angle_elimination_report().holds
}
