///|
// Layer-0 Zero-Dependency 64-Bit Method of Four Russians (`M4RI`) over `GF(2)`:
//   - Bit-packed dense `GF(2)` matrices (64 columns per `UInt64` word);
//   - Kronrod–Arlazarov `k = 4` Gray-code M4RI GEMM (`O(n^3 / 256)` word XORs);
//   - 64-bit word-parallel Reduced Row Echelon Form (`RREF`), rank, and pivot extraction
//     (directly callable by `F1` XOR-SAT / homology and `F5 scheme` Faugère F4 mod 2!).

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
pub fn gf2_bit_matrix_set(
  m : Gf2BitMatrix,
  r : Int32,
  c : Int32,
  val : Int32,
) -> Unit {
  let w = c / 64
  let b = c % 64
  let idx = r * m.words_per_row + w
  let mask = 1UL << b
  if (val & 1) != 0 {
    m.data[idx] = m.data[idx] | mask
  } else {
    m.data[idx] = m.data[idx] & mask.lnot()
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
/// Full 64-bit word-parallel Reduced Row Echelon Form (`RREF`) over `GF(2)`:
/// returns `(rref_matrix, pivot_columns)` in `O(rows * cols * min(rows, cols) / 64)` word XORs.
pub fn gf2_rref_eliminate_u64(a : Gf2BitMatrix) -> (Gf2BitMatrix, Array[Int32]) {
  let wpr = a.words_per_row
  let buf = a.data.copy()
  let rem_bits = a.cols % 64
  if rem_bits != 0 && wpr > 0 {
    let tail_mask = (1UL << rem_bits) - 1UL
    for r in 0..<a.rows {
      let idx = r * wpr + (wpr - 1)
      buf[idx] = buf[idx] & tail_mask
    }
  }
  let pivots : Array[Int32] = []
  let mut rank = 0
  for w in 0..<wpr {
    let max_b = if w == wpr - 1 && rem_bits != 0 { rem_bits } else { 64 }
    for b in 0..<max_b {
      if rank >= a.rows {
        break
      }
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
        pivots.push(w * 64 + b)
        rank = rank + 1
      }
    }
  }
  (
    Gf2BitMatrix::{ rows: a.rows, cols: a.cols, words_per_row: wpr, data: buf, },
    pivots,
  )
}

///|
/// 64-bit word-parallel Reduced Row Echelon Form (`RREF`) rank over `GF(2)`.
pub fn gf2_rref_rank_u64(a : Gf2BitMatrix) -> Int32 {
  let (_rref, pivots) = gf2_rref_eliminate_u64(a)
  pivots.length()
}
