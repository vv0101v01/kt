// CPU 64-bit SWAR Bit-Slicing & Method of Four Russians (M4RI) Engine:
//   1. GF(2) 64-bit word-packed matrices + Kronrod k=4 Gray-code M4RI GEMM & RREF;
//   2. GF(3) 64-trit Dual-Rail branchless SWAR arithmetic & 6,561-tensor Cayley
//      hyperdeterminant sweep (103 UInt64 pairs vs 6,561 scalar calls);
//   3. 64-assignment bit-parallel De Morgan `Face` hypercube truth-vector sweep.

///|
/// Bit-packed dense matrix over `GF(2)` storing 64 columns per `UInt64` word.
#derive(Debug, Eq)
pub struct Gf2BitMatrix {
  rows : Int32
  cols : Int32
  words_per_row : Int32
  data : Array[UInt64]
}

///|
pub extend Gf2BitMatrix with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Gf2BitMatrix with Eq::{not_equal, equal}

///|
pub fn gf2_bit_matrix_zero(rows : Int32, cols : Int32) -> Gf2BitMatrix {
  let wpr = if cols <= 0 { 0 } else { (cols + 63) / 64 }
  Gf2BitMatrix::{
    rows,
    cols,
    words_per_row: wpr,
    data: Array::make(rows * wpr, 0UL),
  }
}

///|
pub fn gf2_bit_matrix_from_ints(
  rows : Int32,
  cols : Int32,
  entries : Array[Int32],
) -> Gf2BitMatrix {
  let m = gf2_bit_matrix_zero(rows, cols)
  for r in 0..<rows {
    for c in 0..<cols {
      if (entries[r * cols + c] & 1) != 0 {
        let w = c / 64
        let b = c % 64
        let idx = r * m.words_per_row + w
        m.data[idx] = m.data[idx] | (1UL << b)
      }
    }
  }
  m
}

///|
pub fn gf2_bit_matrix_get(m : Gf2BitMatrix, r : Int32, c : Int32) -> Int32 {
  let w = c / 64
  let b = c % 64
  let word = m.data[r * m.words_per_row + w]
  if ((word >> b) & 1UL) != 0UL {
    1
  } else {
    0
  }
}

///|
/// Method of Four Russians (`M4RI` / `M4RM`, Kronrod–Arlazarov–Albrecht–Pernet)
/// matrix multiplication over `GF(2)` with Gray-code table width `k = 4`:
/// precomputes all `2^4 = 16` row combinations of each 4-row strip of `B` using
/// 1 word-XOR per Gray step, then accumulates each row of `A` via a single
/// table lookup per 4 inner products (`O(n^3 / (64 * 4))` word XORs).
pub fn gf2_matmul_m4ri(a : Gf2BitMatrix, b : Gf2BitMatrix) -> Gf2BitMatrix {
  let m = a.rows
  let k_dim = a.cols
  let n = b.cols
  let out = gf2_bit_matrix_zero(m, n)
  if m == 0 || k_dim == 0 || n == 0 {
    return out
  }
  let wpr_b = b.words_per_row
  let wpr_a = a.words_per_row
  // Reusable 16-row Gray-code lookup table (16 * wpr_b UInt64 words)
  let table : Array[UInt64] = Array::make(16 * wpr_b, 0UL)
  let mut strip = 0
  while strip < k_dim {
    let rem = k_dim - strip
    let width = if rem < 4 { rem } else { 4 }
    let t_size = 1 << width
    for w in 0..<wpr_b {
      table[w] = 0UL
    }
    let mut prev_gray = 0
    for step in 1..<t_size {
      let gray = step ^ (step >> 1)
      let diff = gray ^ prev_gray
      let bit = diff.ctz()
      let b_row_off = (strip + bit) * wpr_b
      let prev_off = prev_gray * wpr_b
      let cur_off = gray * wpr_b
      for w in 0..<wpr_b {
        table[cur_off + w] = table[prev_off + w] ^ b.data[b_row_off + w]
      }
      prev_gray = gray
    }
    // Extract the `width`-bit index at column `strip` for each row `r` of `A`
    let w_idx = strip / 64
    let b_off = strip % 64
    let mask = ((1 << width) - 1).to_uint64()
    for r in 0..<m {
      let mut code_u64 = (a.data[r * wpr_a + w_idx] >> b_off) & mask
      if b_off + width > 64 && w_idx + 1 < wpr_a {
        let hi_shift = 64 - b_off
        code_u64 = (code_u64 | (a.data[r * wpr_a + w_idx + 1] << hi_shift)) &
          mask
      }
      let code = code_u64.to_int()
      if code != 0 {
        let out_off = r * wpr_b
        let t_off = code * wpr_b
        for w in 0..<wpr_b {
          out.data[out_off + w] = out.data[out_off + w] ^ table[t_off + w]
        }
      }
    }
    strip = strip + 4
  }
  out
}

///|
/// 64-bit word-parallel Reduced Row Echelon Form (`RREF`) rank over `GF(2)`
/// using hardware count-trailing-zeros (`ctz`) pivot scan and full-word XOR row sweeps.
pub fn gf2_rref_rank_u64(a : Gf2BitMatrix) -> Int32 {
  let wpr = a.words_per_row
  let buf : Array[UInt64] = Array::make(a.data.length(), 0UL)
  for i in 0..<a.data.length() {
    buf[i] = a.data[i]
  }
  // Mask any unused trailing bits in the last word of each row
  let rem_bits = a.cols % 64
  if rem_bits != 0 && wpr > 0 {
    let tail_mask = (1UL << rem_bits) - 1UL
    for r in 0..<a.rows {
      let idx = r * wpr + (wpr - 1)
      buf[idx] = buf[idx] & tail_mask
    }
  }
  let mut rank = 0
  for w in 0..<wpr {
    let max_b = if w == wpr - 1 && rem_bits != 0 { rem_bits } else { 64 }
    for b in 0..<max_b {
      let bit_mask = 1UL << b
      let mut piv = -1
      for r in rank..<a.rows {
        if (buf[r * wpr + w] & bit_mask) != 0UL {
          piv = r
          break
        }
      }
      if piv >= 0 {
        if piv != rank {
          for k in w..<wpr {
            let tmp = buf[rank * wpr + k]
            buf[rank * wpr + k] = buf[piv * wpr + k]
            buf[piv * wpr + k] = tmp
          }
        }
        for r in 0..<a.rows {
          if r != rank && (buf[r * wpr + w] & bit_mask) != 0UL {
            for k in w..<wpr {
              buf[r * wpr + k] = buf[r * wpr + k] ^ buf[rank * wpr + k]
            }
          }
        }
        rank = rank + 1
        if rank == a.rows {
          return rank
        }
      }
    }
  }
  rank
}

///|
/// Dual-rail bit-sliced vector of 64 elements in `GF(3) = {0, 1, 2}`:
/// lane `i` encodes `0` as `(0, 0)`, `1` as `(1, 0)`, and `2` as `(0, 1)`
/// with canonical invariant `(lo & hi) == 0UL`.
#derive(Debug, Eq)
pub struct Gf3Slice64 {
  lo : UInt64
  hi : UInt64
}

///|
pub extend Gf3Slice64 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Gf3Slice64 with Eq::{not_equal, equal}

///|
pub fn gf3_slice64_get(s : Gf3Slice64, lane : Int32) -> Int32 {
  let b0 = (s.lo >> lane) & 1UL
  let b1 = (s.hi >> lane) & 1UL
  if b0 != 0UL {
    1
  } else if b1 != 0UL {
    2
  } else {
    0
  }
}

///|
/// Branchless 64-trit `GF(3)` addition (Boothby–Bradshaw dual-rail Boolean circuit):
/// computes `(a + b) mod 3` across all 64 lanes simultaneously with zero branches
/// and zero integer divisions.
pub fn gf3_add64(a : Gf3Slice64, b : Gf3Slice64) -> Gf3Slice64 {
  let a0 = a.lo
  let a1 = a.hi
  let b0 = b.lo
  let b1 = b.hi
  let c0 = ((a0 ^ b0) & (a1 | b1).lnot()) | (a1 & b1)
  let c1 = ((a1 ^ b1) & (a0 | b0).lnot()) | (a0 & b0)
  Gf3Slice64::{ lo: c0, hi: c1, }
}

///|
/// Zero-cost 64-trit `GF(3)` negation (`-a mod 3` swaps `1 <-> 2`, i.e. `(hi, lo)`).
pub fn gf3_neg64(a : Gf3Slice64) -> Gf3Slice64 {
  Gf3Slice64::{ lo: a.hi, hi: a.lo, }
}

///|
pub fn gf3_sub64(a : Gf3Slice64, b : Gf3Slice64) -> Gf3Slice64 {
  gf3_add64(a, gf3_neg64(b))
}

///|
/// Branchless 64-trit `GF(3)` multiplication (`6` bitwise ops for 64 products).
pub fn gf3_mul64(a : Gf3Slice64, b : Gf3Slice64) -> Gf3Slice64 {
  let m0 = (a.lo & b.lo) | (a.hi & b.hi)
  let m1 = (a.lo & b.hi) | (a.hi & b.lo)
  Gf3Slice64::{ lo: m0, hi: m1, }
}

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
  let coords : Array[Gf3Slice64] = Array::make(8, Gf3Slice64::{
    lo: 0UL,
    hi: 0UL,
  })
  for ch in 0..<chunks {
    let base = ch * 64
    let valid = if base + 64 <= total { 64 } else { total - base }
    let valid_mask = if valid == 64 {
      0xFFFFFFFFFFFFFFFFUL
    } else {
      (1UL << valid) - 1UL
    }
    for k in 0..<8 {
      let mut lo = 0UL
      let mut hi = 0UL
      let mut div = 1
      for _ in 0..<k {
        div = div * 3
      }
      for lane in 0..<valid {
        let digit = (base + lane) / div % 3
        if digit == 1 {
          lo = lo | (1UL << lane)
        } else if digit == 2 {
          hi = hi | (1UL << lane)
        }
      }
      coords[k] = Gf3Slice64::{ lo, hi, }
    }
    // t000..t111 in standard lexicographic order
    let a = coords[0]
    let b = coords[1]
    let c = coords[2]
    let d = coords[3]
    let e = coords[4]
    let f = coords[5]
    let g = coords[6]
    let h = coords[7]
    // Cayley's hyperdeterminant over F_3 (note -2 == +1 mod 3 and -4 == +2 == -1 mod 3!):
    // d1 = a*h - b*g, d2 = c*f - d*e, cross = a*f - b*e + c*h - d*g
    // Delta = (a*h + b*g - c*f - d*e)^2 - 4*(a*f - c*h)*(d*e - b*g) ...
    // Let's use the exact symmetric form:
    //   p1 = a*h, p2 = b*g, p3 = c*f, p4 = d*e
    //   s = p1 + p2 + p3 + p4
    //   Delta = p1^2 + p2^2 + p3^2 + p4^2 - 2*(p1*p2 + p1*p3 + p1*p4 + p2*p3 + p2*p4 + p3*p4)
    //           + 4*(a*d*f*g + b*c*e*h)
    let p1 = gf3_mul64(a, h)
    let p2 = gf3_mul64(b, g)
    let p3 = gf3_mul64(c, f)
    let p4 = gf3_mul64(d, e)
    let sq = gf3_add64(
      gf3_add64(gf3_mul64(p1, p1), gf3_mul64(p2, p2)),
      gf3_add64(gf3_mul64(p3, p3), gf3_mul64(p4, p4)),
    )
    let pairs = gf3_add64(
      gf3_add64(
        gf3_add64(gf3_mul64(p1, p2), gf3_mul64(p1, p3)),
        gf3_add64(gf3_mul64(p1, p4), gf3_mul64(p2, p3)),
      ),
      gf3_add64(gf3_mul64(p2, p4), gf3_mul64(p3, p4)),
    )
    // -2 === +1 (mod 3), +4 === +1 (mod 3)
    let t_adfg = gf3_mul64(gf3_mul64(a, d), gf3_mul64(f, g))
    let t_bceh = gf3_mul64(gf3_mul64(b, c), gf3_mul64(e, h))
    let det = gf3_add64(gf3_add64(sq, pairs), gf3_add64(t_adfg, t_bceh))
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
