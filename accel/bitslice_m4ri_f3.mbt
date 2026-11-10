///|
// Cross-Federation GF(3) Atlas Verification & 64-Way Face Hypercube #SAT

///|
/// Report of batched 64-way SWAR bit-sliced `F_3^{2x2x2}` Cayley hyperdeterminant sweep.
#derive(Debug, Eq)
pub(all) struct BitslicedF3HyperdetReport {
  total_tensors : Int32
  u64_chunks_processed : Int32
  singular_det_zero : Int32
  det_eq_one : Int32
  det_eq_two : Int32
  matches_tensor_atlas : Bool
}

///|
pub extend BitslicedF3HyperdetReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend BitslicedF3HyperdetReport with Eq::{not_equal, equal}

///|
/// Evaluate Cayley's `2x2x2` hyperdeterminant across ALL `3^8 = 6,561` tensors over `F_3`
/// in just `103` branchless 64-trit bit-sliced SWAR iterations (`ceil(6561 / 64) = 103`),
/// using hardware `popcount` on `(lo, hi)` bitmasks to tally `{0, 1, 2}` values!
pub fn gf3_bitsliced_all_6561_hyperdeterminants() -> BitslicedF3HyperdetReport {
  let total = 6561
  let chunks = (total + 63) / 64
  let atlas = @tensor.f3_tensor222_atlas_build()
  let mut all_lanes_match = true
  let mut zero_cnt = 0
  let mut one_cnt = 0
  let mut two_cnt = 0
  for ch in 0..<chunks {
    let base = ch * 64
    let valid = if base + 64 <= total { 64 } else { total - base }
    let valid_mask = if valid == 64 {
      0xFFFFFFFFFFFFFFFFUL
    } else {
      (1UL << valid) - 1UL
    }
    let det = gf3_hyperdet222_chunk64(base, valid)
    for lane in 0..<valid {
      if gf3_slice64_get(det, lane) != atlas.hyperdets[base + lane] {
        all_lanes_match = false
      }
    }
    let ones = (det.lo & valid_mask).popcnt()
    let twos = (det.hi & valid_mask).popcnt()
    let zeros = valid - ones - twos
    zero_cnt = zero_cnt + zeros
    one_cnt = one_cnt + ones
    two_cnt = two_cnt + twos
  }
  BitslicedF3HyperdetReport::{
    total_tensors: total,
    u64_chunks_processed: chunks,
    singular_det_zero: zero_cnt,
    det_eq_one: one_cnt,
    det_eq_two: two_cnt,
    matches_tensor_atlas: all_lanes_match &&
    zero_cnt == atlas.det_zero_count &&
    one_cnt + two_cnt == atlas.det_nonzero_count,
  }
}

///|
/// 64-assignment SWAR truth-vector of a De Morgan `@face_bdd.Dim` on block `block_idx`
/// (each block covers 64 consecutive hypercube assignments `block_idx * 64 + lane`).
fn dim_truth_word64(d : @face_bdd.Dim, block_idx : Int32) -> UInt64 {
  match d {
    DZero => 0UL
    DOne => 0xFFFFFFFFFFFFFFFFUL
    DVar(v) =>
      if v < 0 {
        0UL
      } else if v == 0 {
        0xAAAAAAAAAAAAAAAAUL
      } else if v == 1 {
        0xCCCCCCCCCCCCCCCCUL
      } else if v == 2 {
        0xF0F0F0F0F0F0F0F0UL
      } else if v == 3 {
        0xFF00FF00FF00FF00UL
      } else if v == 4 {
        0xFFFF0000FFFF0000UL
      } else if v == 5 {
        0xFFFFFFFF00000000UL
      } else {
        let bit = (block_idx >> (v - 6)) & 1
        if bit != 0 {
          0xFFFFFFFFFFFFFFFFUL
        } else {
          0UL
        }
      }
    DNeg(x) => dim_truth_word64(x, block_idx).lnot()
    DAnd(x, y) =>
      dim_truth_word64(x, block_idx) & dim_truth_word64(y, block_idx)
    DOr(x, y) => dim_truth_word64(x, block_idx) | dim_truth_word64(y, block_idx)
  }
}

///|
/// Evaluate `@face_bdd.Face` across 64 hypercube vertices simultaneously in one `UInt64`.
pub fn face_truth_word64(f : @face_bdd.Face, block_idx : Int32) -> UInt64 {
  match f {
    FTop => 0xFFFFFFFFFFFFFFFFUL
    FBot => 0UL
    FEq0(d) => dim_truth_word64(d, block_idx).lnot()
    FEq1(d) => dim_truth_word64(d, block_idx)
    FAnd(a, b) =>
      face_truth_word64(a, block_idx) & face_truth_word64(b, block_idx)
    FOr(a, b) =>
      face_truth_word64(a, block_idx) | face_truth_word64(b, block_idx)
  }
}

///|
/// Exact `#SAT` model count over `{0, 1}^n_vars` via 64-way SWAR `UInt64` `popcnt()`.
pub fn face_swar_model_count(f : @face_bdd.Face, n_vars : Int32) -> Int32 {
  if n_vars <= 6 {
    let total = 1 << n_vars
    let mask = if total == 64 {
      0xFFFFFFFFFFFFFFFFUL
    } else {
      (1UL << total) - 1UL
    }
    (face_truth_word64(f, 0) & mask).popcnt()
  } else {
    let n_blocks = 1 << (n_vars - 6)
    let mut count = 0
    for blk in 0..<n_blocks {
      count = count + face_truth_word64(f, blk).popcnt()
    }
    count
  }
}
