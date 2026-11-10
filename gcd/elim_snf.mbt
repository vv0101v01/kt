///|
// Lower-V Base Vertex (`V_lower`): Exact Elimination, Smith/Hermite Normal Forms,
// Multi-Modular CRT, and Integer Nullspace Conservation Engine.
//
// Synthesizes `notebook/core` & `notebook/canon` with `golden`'s exact BigInt
// discipline so every higher federation (`algebra`, `topos`, `scheme`,
// `condensed`, `cubical`, `bridge`) shares a single canonical elimination base.

///|
/// Matrix over prime field `F_p` (`2 <= p <= 2_147_483_647`; intermediate products widen to `Int64`).
#derive(Debug, Eq)
pub(all) struct FpMat {
  rows : Int32
  cols : Int32
  p : Int32
  data : Array[Int32]
}

///|
pub extend FpMat with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FpMat with Eq::{not_equal, equal}

///|
/// Reduced row echelon form result over `F_p`.
#derive(Debug, Eq)
pub(all) struct FpRrefResult {
  rref : FpMat
  rank : Int32
  pivots : Array[Int32]
}

///|
pub extend FpRrefResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FpRrefResult with Eq::{not_equal, equal}

///|
/// Exact `BigInt` matrix over `Z`.
#derive(Debug, Eq)
pub(all) struct ZMat {
  rows : Int32
  cols : Int32
  data : Array[BigInt]
}

///|
pub extend ZMat with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ZMat with Eq::{not_equal, equal}

///|
/// Certified Smith Normal Form `U * M * V = D` over `Z` with unimodular `U, V`
/// and positive divisibility chain `diag[0] | diag[1] | ... | diag[rank - 1]`.
#derive(Debug, Eq)
pub(all) struct ZSnfResult {
  u : ZMat
  diag : Array[BigInt]
  v : ZMat
  rank : Int32
}

///|
pub extend ZSnfResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ZSnfResult with Eq::{not_equal, equal}

///|
pub fn fp_norm(v : Int32, p : Int32) -> Int32 {
  if p <= 0 {
    return 0
  }
  let pm = p.to_int64()
  let r = v.to_int64() % pm
  (if r < 0L { r + pm } else { r }).to_int()
}

///|
pub fn fp_add(a : Int32, b : Int32, p : Int32) -> Int32 {
  if p <= 0 {
    return 0
  }
  let pm = p.to_int64()
  let s = (fp_norm(a, p).to_int64() + fp_norm(b, p).to_int64()) % pm
  s.to_int()
}

///|
pub fn fp_sub(a : Int32, b : Int32, p : Int32) -> Int32 {
  if p <= 0 {
    return 0
  }
  let pm = p.to_int64()
  let d = (fp_norm(a, p).to_int64() - fp_norm(b, p).to_int64()) % pm
  (if d < 0L { d + pm } else { d }).to_int()
}

///|
pub fn fp_mul(a : Int32, b : Int32, p : Int32) -> Int32 {
  if p <= 0 {
    return 0
  }
  let pm = p.to_int64()
  let prod = fp_norm(a, p).to_int64() * fp_norm(b, p).to_int64() % pm
  prod.to_int()
}

///|
pub fn fp_inv(a : Int32, p : Int32) -> Int32 {
  if p <= 1 {
    return 0
  }
  let pm = p.to_int64()
  let mut t = 0L
  let mut new_t = 1L
  let mut r = pm
  let mut new_r = fp_norm(a, p).to_int64()
  while new_r != 0L {
    let q = r / new_r
    let tmp_t = t - q * new_t
    t = new_t
    new_t = tmp_t
    let tmp_r = r - q * new_r
    r = new_r
    new_r = tmp_r
  }
  if r > 1L {
    return 0
  }
  let adj = t % pm
  (if adj < 0L { adj + pm } else { adj }).to_int()
}

///|
/// Overflow-safe primality test for all 32-bit signed integers `p`.
pub fn ugcd_is_prime_int(p : Int32) -> Bool {
  if p < 2 {
    return false
  }
  if p % 2 == 0 {
    return p == 2
  }
  let pl = p.to_int64()
  let mut d = 3L
  while d * d <= pl {
    if pl % d == 0L {
      return false
    }
    d = d + 2L
  }
  true
}

///|
pub fn fp_mat_make(
  rows : Int32,
  cols : Int32,
  p : Int32,
  init : Int32,
) -> FpMat {
  let v = fp_norm(init, p)
  let data : Array[Int32] = []
  for _ in 0..<(rows * cols) {
    data.push(v)
  }
  FpMat::{ rows, cols, p, data, }
}

///|
pub fn fp_mat_from_rows(rows_arr : Array[Array[Int32]], p : Int32) -> FpMat {
  let r = rows_arr.length()
  let c = if r == 0 { 0 } else { rows_arr[0].length() }
  let data : Array[Int32] = []
  for i in 0..<r {
    for j in 0..<c {
      data.push(fp_norm(rows_arr[i][j], p))
    }
  }
  FpMat::{ rows: r, cols: c, p, data, }
}

///|
pub fn fp_mat_get(m : FpMat, i : Int32, j : Int32) -> Int32 {
  m.data[i * m.cols + j]
}

///|
pub fn fp_mat_set(m : FpMat, i : Int32, j : Int32, v : Int32) -> Unit {
  m.data[i * m.cols + j] = fp_norm(v, m.p)
}

///|
pub fn fp_mat_transpose(m : FpMat) -> FpMat {
  let out = fp_mat_make(m.cols, m.rows, m.p, 0)
  for i in 0..<m.rows {
    for j in 0..<m.cols {
      fp_mat_set(out, j, i, fp_mat_get(m, i, j))
    }
  }
  out
}

///|
pub fn fp_mat_mul(a : FpMat, b : FpMat) -> FpMat {
  let rows = a.rows
  let mid = a.cols
  let cols = b.cols
  let p = a.p
  let out = fp_mat_make(rows, cols, p, 0)
  if p <= 0 || rows == 0 || mid == 0 || cols == 0 {
    return out
  }
  let pm = p.to_int64()
  let ad = a.data
  let bd = b.data
  let od = out.data
  if p <= 46340 {
    // Delayed-modulus 64-bit accumulation: 16 products <= 16 * 46340^2 < 3.44e10 << 2^63 - 1
    let bt = fp_mat_transpose(b)
    let btd = bt.data
    for i in 0..<rows {
      let a_off = i * mid
      let o_off = i * cols
      for j in 0..<cols {
        let b_off = j * mid
        let mut acc = 0L
        let mut k = 0
        while k + 16 <= mid {
          let mut s = 0L
          for t in 0..<16 {
            s = s + ad[a_off + k + t].to_int64() * btd[b_off + k + t].to_int64()
          }
          acc = (acc + s) % pm
          k = k + 16
        }
        let mut tail = 0L
        while k < mid {
          tail = tail + ad[a_off + k].to_int64() * btd[b_off + k].to_int64()
          k = k + 1
        }
        od[o_off + j] = ((acc + tail) % pm).to_int()
      }
    }
    return out
  }
  for i in 0..<rows {
    let a_off = i * mid
    let o_off = i * cols
    for k in 0..<mid {
      let aik = ad[a_off + k].to_int64()
      if aik != 0L {
        let b_off = k * cols
        for j in 0..<cols {
          od[o_off + j] = ((
            od[o_off + j].to_int64() + aik * bd[b_off + j].to_int64()
          ) %
          pm).to_int()
        }
      }
    }
  }
  out
}

///|
/// `[D-Gauss]` Gauss-Jordan elimination over `F_p` producing canonical RREF
/// with single-division 64-bit row-update inner loops.
pub fn fp_rref(m : FpMat) -> FpRrefResult {
  let rows = m.rows
  let cols = m.cols
  let p = m.p
  let ad = m.data.copy()
  let a = FpMat::{ rows, cols, p, data: ad, }
  let pivots : Array[Int32] = []
  if p <= 1 || rows == 0 || cols == 0 {
    return FpRrefResult::{ rref: a, rank: 0, pivots, }
  }
  let pm = p.to_int64()
  let mut r = 0
  for c in 0..<cols {
    if r >= rows {
      break
    }
    let mut piv = -1
    for i in r..<rows {
      if ad[i * cols + c] != 0 {
        piv = i
        break
      }
    }
    if piv < 0 {
      continue
    }
    if piv != r {
      let r_off = r * cols
      let p_off = piv * cols
      for j in 0..<cols {
        let tmp = ad[r_off + j]
        ad[r_off + j] = ad[p_off + j]
        ad[p_off + j] = tmp
      }
    }
    let r_off = r * cols
    let inv_p = fp_inv(ad[r_off + c], p).to_int64()
    ad[r_off + c] = 1
    for j in (c + 1)..<cols {
      let v = ad[r_off + j]
      if v != 0 {
        ad[r_off + j] = (v.to_int64() * inv_p % pm).to_int()
      }
    }
    for i in 0..<rows {
      if i != r {
        let i_off = i * cols
        let factor = ad[i_off + c]
        if factor != 0 {
          let fac64 = factor.to_int64()
          ad[i_off + c] = 0
          for j in (c + 1)..<cols {
            let rj = ad[r_off + j]
            if rj != 0 {
              let d = (ad[i_off + j].to_int64() - fac64 * rj.to_int64()) % pm
              ad[i_off + j] = (if d < 0L { d + pm } else { d }).to_int()
            }
          }
        }
      }
    }
    pivots.push(c)
    r = r + 1
  }
  FpRrefResult::{ rref: a, rank: r, pivots, }
}

///|
pub fn fp_rank(m : FpMat) -> Int32 {
  fp_rref(m).rank
}

///|
/// Basis of `ker(m)` over `F_p` (`m * v = 0`).
pub fn fp_nullspace_basis(m : FpMat) -> Array[Array[Int32]] {
  let g = fp_rref(m)
  let is_piv : Array[Bool] = []
  for _ in 0..<m.cols {
    is_piv.push(false)
  }
  for c in g.pivots {
    is_piv[c] = true
  }
  let basis : Array[Array[Int32]] = []
  for free_c in 0..<m.cols {
    if !is_piv[free_c] {
      let vec : Array[Int32] = []
      for _ in 0..<m.cols {
        vec.push(0)
      }
      vec[free_c] = 1
      for idx in 0..<g.pivots.length() {
        let pc = g.pivots[idx]
        let coeff = fp_mat_get(g.rref, idx, free_c)
        vec[pc] = fp_sub(0, coeff, m.p)
      }
      basis.push(vec)
    }
  }
  basis
}

///|
/// Determinant over `F_p` via row reduction.
pub fn fp_det(m : FpMat) -> Int32 {
  if m.rows != m.cols {
    return 0
  }
  let n = m.rows
  let a = FpMat::{ rows: n, cols: n, p: m.p, data: m.data.copy(), }
  let mut det = 1
  for c in 0..<n {
    let mut piv = -1
    for i in c..<n {
      if fp_mat_get(a, i, c) != 0 {
        piv = i
        break
      }
    }
    if piv < 0 {
      return 0
    }
    if piv != c {
      for j in c..<n {
        let tmp = fp_mat_get(a, c, j)
        fp_mat_set(a, c, j, fp_mat_get(a, piv, j))
        fp_mat_set(a, piv, j, tmp)
      }
      det = fp_sub(0, det, a.p)
    }
    let pv = fp_mat_get(a, c, c)
    det = fp_mul(det, pv, a.p)
    let inv_pv = fp_inv(pv, a.p)
    for i in (c + 1)..<n {
      let factor = fp_mul(fp_mat_get(a, i, c), inv_pv, a.p)
      if factor != 0 {
        for j in c..<n {
          let sub = fp_mul(factor, fp_mat_get(a, c, j), a.p)
          fp_mat_set(a, i, j, fp_sub(fp_mat_get(a, i, j), sub, a.p))
        }
      }
    }
  }
  det
}

// ---------------------------------------------------------------------------
// Exact BigInt Integer Matrices, Smith Normal Form & Hermite Normal Form
// ---------------------------------------------------------------------------

///|
pub fn ugcd_bigint_abs(x : BigInt) -> BigInt {
  if x < 0N {
    -x
  } else {
    x
  }
}

///|
pub fn ugcd_bigint_gcd(a : BigInt, b : BigInt) -> BigInt {
  let mut x = ugcd_bigint_abs(a)
  let mut y = ugcd_bigint_abs(b)
  while y != 0N {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
pub fn ugcd_bigint_lcm(a : BigInt, b : BigInt) -> BigInt {
  let xa = ugcd_bigint_abs(a)
  let xb = ugcd_bigint_abs(b)
  if xa == 0N || xb == 0N {
    0N
  } else {
    xa / ugcd_bigint_gcd(xa, xb) * xb
  }
}

///|
/// Euclidean floor division `a = q * b + r` with `0 <= r < |b|` (`b == 0` returns `(0, a)`).
fn ugcd_euclid_div(a : BigInt, b : BigInt) -> (BigInt, BigInt) {
  if b == 0N {
    return (0N, a)
  }
  let mut q = a / b
  let mut r = a - q * b
  if r < 0N {
    if b > 0N {
      q = q - 1N
      r = r + b
    } else {
      q = q + 1N
      r = r - b
    }
  }
  (q, r)
}

///|
pub fn zmat_make(rows : Int32, cols : Int32, init : BigInt) -> ZMat {
  let data : Array[BigInt] = []
  for _ in 0..<(rows * cols) {
    data.push(init)
  }
  ZMat::{ rows, cols, data, }
}

///|
pub fn zmat_eye(n : Int32) -> ZMat {
  let m = zmat_make(n, n, 0N)
  for i in 0..<n {
    m.data[i * n + i] = 1N
  }
  m
}

///|
pub fn zmat_from_rows(rows_arr : Array[Array[BigInt]]) -> ZMat {
  let r = rows_arr.length()
  let c = if r == 0 { 0 } else { rows_arr[0].length() }
  let data : Array[BigInt] = []
  for i in 0..<r {
    for j in 0..<c {
      data.push(rows_arr[i][j])
    }
  }
  ZMat::{ rows: r, cols: c, data, }
}

///|
pub fn zmat_from_int_rows(rows_arr : Array[Array[Int32]]) -> ZMat {
  let r = rows_arr.length()
  let c = if r == 0 { 0 } else { rows_arr[0].length() }
  let data : Array[BigInt] = []
  for i in 0..<r {
    for j in 0..<c {
      data.push(BigInt::from_int(rows_arr[i][j]))
    }
  }
  ZMat::{ rows: r, cols: c, data, }
}

///|
pub fn zmat_get(m : ZMat, i : Int32, j : Int32) -> BigInt {
  m.data[i * m.cols + j]
}

///|
pub fn zmat_set(m : ZMat, i : Int32, j : Int32, v : BigInt) -> Unit {
  m.data[i * m.cols + j] = v
}

///|
pub fn zmat_mul(a : ZMat, b : ZMat) -> ZMat {
  let out = zmat_make(a.rows, b.cols, 0N)
  for i in 0..<a.rows {
    for k in 0..<a.cols {
      let aik = zmat_get(a, i, k)
      if aik != 0N {
        for j in 0..<b.cols {
          zmat_set(out, i, j, zmat_get(out, i, j) + aik * zmat_get(b, k, j))
        }
      }
    }
  }
  out
}

///|
fn zmat_swap_rows(a : ZMat, r1 : Int32, r2 : Int32) -> Unit {
  if r1 == r2 {
    return
  }
  for j in 0..<a.cols {
    let tmp = zmat_get(a, r1, j)
    zmat_set(a, r1, j, zmat_get(a, r2, j))
    zmat_set(a, r2, j, tmp)
  }
}

///|
fn zmat_swap_cols(a : ZMat, c1 : Int32, c2 : Int32) -> Unit {
  if c1 == c2 {
    return
  }
  for i in 0..<a.rows {
    let tmp = zmat_get(a, i, c1)
    zmat_set(a, i, c1, zmat_get(a, i, c2))
    zmat_set(a, i, c2, tmp)
  }
}

///|
fn zmat_add_row_mul(
  a : ZMat,
  dst_row : Int32,
  src_row : Int32,
  factor : BigInt,
) -> Unit {
  if factor == 0N {
    return
  }
  for j in 0..<a.cols {
    zmat_set(
      a,
      dst_row,
      j,
      zmat_get(a, dst_row, j) + factor * zmat_get(a, src_row, j),
    )
  }
}

///|
fn zmat_add_col_mul(
  a : ZMat,
  dst_col : Int32,
  src_col : Int32,
  factor : BigInt,
) -> Unit {
  if factor == 0N {
    return
  }
  for i in 0..<a.rows {
    zmat_set(
      a,
      i,
      dst_col,
      zmat_get(a, i, dst_col) + factor * zmat_get(a, i, src_col),
    )
  }
}

///|
/// `[D-SNF]` / `[T-SNF]` Certified Smith Normal Form `U * M * V = D` over `Z`
/// maintaining unimodular transformations `U in GL_rows(Z)`, `V in GL_cols(Z)`.
pub fn zmat_snf(m : ZMat) -> ZSnfResult {
  let a = ZMat::{ rows: m.rows, cols: m.cols, data: m.data.copy(), }
  let u = zmat_eye(m.rows)
  let v = zmat_eye(m.cols)
  let limit = if m.rows < m.cols { m.rows } else { m.cols }
  let mut p = 0
  while p < limit {
    // Havas–Majewski–Matthews norm-guided pivot selection in submatrix `[p.., p..]`:
    // choose `(i, j)` minimizing `(|a[i,j]|, row_nnz[i] * col_nnz[j], row_l1[i] + col_l1[j])`
    // so sparse small-norm rows/columns eliminate first without spraying large coefficients!
    let row_nnz : Array[Int32] = Array::make(a.rows, 0)
    let col_nnz : Array[Int32] = Array::make(a.cols, 0)
    let row_l1 : Array[BigInt] = Array::make(a.rows, 0N)
    let col_l1 : Array[BigInt] = Array::make(a.cols, 0N)
    for i in p..<a.rows {
      for j in p..<a.cols {
        let av = ugcd_bigint_abs(zmat_get(a, i, j))
        if av != 0N {
          row_nnz[i] = row_nnz[i] + 1
          col_nnz[j] = col_nnz[j] + 1
          row_l1[i] = row_l1[i] + av
          col_l1[j] = col_l1[j] + av
        }
      }
    }
    let mut best_i = -1
    let mut best_j = -1
    let mut best_abs = 0N
    let mut best_fill = 0
    let mut best_l1 = 0N
    for i in p..<a.rows {
      for j in p..<a.cols {
        let av = ugcd_bigint_abs(zmat_get(a, i, j))
        if av != 0N {
          let fill = row_nnz[i] * col_nnz[j]
          let l1 = row_l1[i] + col_l1[j]
          let better = if best_i < 0 {
            true
          } else if av != best_abs {
            av < best_abs
          } else if fill != best_fill {
            fill < best_fill
          } else {
            l1 < best_l1
          }
          if better {
            best_i = i
            best_j = j
            best_abs = av
            best_fill = fill
            best_l1 = l1
          }
        }
      }
    }
    if best_i < 0 {
      break
    }
    zmat_swap_rows(a, p, best_i)
    zmat_swap_rows(u, p, best_i)
    zmat_swap_cols(a, p, best_j)
    zmat_swap_cols(v, p, best_j)

    // Reduce row p and col p, plus divisibility of remaining submatrix, until diagonalized at p
    let mut done_pivot = false
    while !done_pivot {
      // Clear column p (rows != p) and row p (cols != p) by Euclidean steps
      let mut changed = true
      while changed {
        changed = false
        for i in (p + 1)..<a.rows {
          let aip = zmat_get(a, i, p)
          if aip != 0N {
            let app = zmat_get(a, p, p)
            let q = aip / app
            zmat_add_row_mul(a, i, p, -q)
            zmat_add_row_mul(u, i, p, -q)
            if zmat_get(a, i, p) != 0N {
              zmat_swap_rows(a, p, i)
              zmat_swap_rows(u, p, i)
              changed = true
            }
          }
        }
        for j in (p + 1)..<a.cols {
          let apj = zmat_get(a, p, j)
          if apj != 0N {
            let app = zmat_get(a, p, p)
            let q = apj / app
            zmat_add_col_mul(a, j, p, -q)
            zmat_add_col_mul(v, j, p, -q)
            if zmat_get(a, p, j) != 0N {
              zmat_swap_cols(a, p, j)
              zmat_swap_cols(v, p, j)
              changed = true
            }
          }
        }
      }
      // Make pivot positive
      if zmat_get(a, p, p) < 0N {
        for j in 0..<a.cols {
          zmat_set(a, p, j, -zmat_get(a, p, j))
        }
        for j in 0..<u.cols {
          zmat_set(u, p, j, -zmat_get(u, p, j))
        }
      }
      // Check divisibility of submatrix [p+1.., p+1..] by a[p, p]
      let app = zmat_get(a, p, p)
      let mut bad_i = -1
      for i in (p + 1)..<a.rows {
        for j in (p + 1)..<a.cols {
          if zmat_get(a, i, j) % app != 0N {
            bad_i = i
            break
          }
        }
        if bad_i >= 0 {
          break
        }
      }
      if bad_i < 0 {
        done_pivot = true
      } else {
        // Add row bad_i to row p so non-divisible entry enters row p and next iteration strictly lowers |a[p, p]|
        zmat_add_row_mul(a, p, bad_i, 1N)
        zmat_add_row_mul(u, p, bad_i, 1N)
      }
    }
    p = p + 1
  }
  let diag : Array[BigInt] = []
  for k in 0..<p {
    diag.push(zmat_get(a, k, k))
  }
  ZSnfResult::{ u, diag, v, rank: p, }
}

///|
/// Verify `U * M * V == diag(d_1, ..., d_r, 0, ...)` and `d_1 | d_2 | ... | d_r`.
pub fn zmat_snf_verify(m : ZMat, res : ZSnfResult) -> Bool {
  let prod = zmat_mul(zmat_mul(res.u, m), res.v)
  if prod.rows != m.rows || prod.cols != m.cols {
    return false
  }
  for i in 0..<prod.rows {
    for j in 0..<prod.cols {
      let expected = if i == j && i < res.rank { res.diag[i] } else { 0N }
      if zmat_get(prod, i, j) != expected {
        return false
      }
    }
  }
  for k in 0..<res.rank {
    if res.diag[k] <= 0N {
      return false
    }
    if k + 1 < res.rank && res.diag[k + 1] % res.diag[k] != 0N {
      return false
    }
  }
  true
}

///|
/// `[D-HNF]` Row Hermite Normal Form: canonical invariant of the row `Z`-lattice.
pub fn zmat_hnf(m : ZMat) -> ZMat {
  let h = ZMat::{ rows: m.rows, cols: m.cols, data: m.data.copy(), }
  let mut r = 0
  for c in 0..<h.cols {
    if r >= h.rows {
      break
    }
    // Reduce all rows >= r in col c down to a single non-zero pivot at row r
    let mut active = true
    while active {
      let mut min_i = -1
      let mut min_abs = 0N
      let mut nonzeros = 0
      for i in r..<h.rows {
        let av = ugcd_bigint_abs(zmat_get(h, i, c))
        if av != 0N {
          nonzeros = nonzeros + 1
          if min_i < 0 || av < min_abs {
            min_i = i
            min_abs = av
          }
        }
      }
      if nonzeros == 0 {
        active = false
      } else {
        zmat_swap_rows(h, r, min_i)
        if zmat_get(h, r, c) < 0N {
          for j in c..<h.cols {
            zmat_set(h, r, j, -zmat_get(h, r, j))
          }
        }
        if nonzeros == 1 {
          active = false
        } else {
          let piv = zmat_get(h, r, c)
          for i in (r + 1)..<h.rows {
            let v = zmat_get(h, i, c)
            if v != 0N {
              let (q, _) = ugcd_euclid_div(v, piv)
              zmat_add_row_mul(h, i, r, -q)
            }
          }
        }
      }
    }
    if zmat_get(h, r, c) > 0N {
      let piv = zmat_get(h, r, c)
      for i in 0..<r {
        let v = zmat_get(h, i, c)
        if v != 0N {
          let (q, _) = ugcd_euclid_div(v, piv)
          zmat_add_row_mul(h, i, r, -q)
        }
      }
      r = r + 1
    }
  }
  h
}

///|
/// Exact fraction-free Sylvester–Bareiss determinant `det(m)` over `Z` in `O(n^3)`
/// exact `BigInt` divisions (zero rational fractions, zero intermediate GCDs).
pub fn zmat_det_bareiss(m : ZMat) -> BigInt {
  if m.rows != m.cols {
    return 0N
  }
  let n = m.rows
  if n == 0 {
    return 1N
  }
  let a = m.data.copy()
  let mut sign = 1N
  let mut prev_piv = 1N
  for k in 0..<(n - 1) {
    let mut piv_r = -1
    for i in k..<n {
      if a[i * n + k] != 0N {
        piv_r = i
        break
      }
    }
    if piv_r < 0 {
      return 0N
    }
    if piv_r != k {
      for j in k..<n {
        let tmp = a[k * n + j]
        a[k * n + j] = a[piv_r * n + j]
        a[piv_r * n + j] = tmp
      }
      sign = -sign
    }
    let akk = a[k * n + k]
    for i in (k + 1)..<n {
      let aik = a[i * n + k]
      for j in (k + 1)..<n {
        a[i * n + j] = (akk * a[i * n + j] - aik * a[k * n + j]) / prev_piv
      }
      a[i * n + k] = 0N
    }
    prev_piv = akk
  }
  sign * a[(n - 1) * n + (n - 1)]
}

///|
/// **Domich–Kannan–Trotter Determinant-Bounded Modular Row Hermite Normal Form** (`[T-HNF-Mod]`):
/// When `m` (`rows >= cols`) contains a full-rank `cols × cols` sublattice of determinant `D > 0`
/// (computed in `O(cols^3)` via `zmat_det_bareiss`), `D · Z^{cols}` is contained in `rowspace_Z(m)`
/// by Cramer's adjugate identity `adj(B) · B = det(B) · I`. Eliminating `(m ; D · I)` modulo `D`
/// keeps every intermediate `BigInt` strictly bounded by `O(D^2)` and produces the exact canonical
/// row HNF (`zmat_hnf_modular(m) == zmat_hnf(m)`). Falls back seamlessly to `zmat_hnf` when rank < cols.
pub fn zmat_hnf_modular(m : ZMat) -> ZMat {
  let rows = m.rows
  let cols = m.cols
  if rows == 0 || cols == 0 || rows < cols {
    return zmat_hnf(m)
  }
  // Pick `cols` linearly independent rows over F_65521 to form a nonsingular square block `B`
  let p_probe = 65521
  let fp_probe = fp_mat_make(rows, cols, p_probe, 0)
  for i in 0..<rows {
    for j in 0..<cols {
      let (_, rem) = ugcd_euclid_div(
        zmat_get(m, i, j),
        BigInt::from_int(p_probe),
      )
      fp_mat_set(fp_probe, i, j, rem.to_int())
    }
  }
  // Transpose so columns of `fp_probe^T` are the rows of `m`, and pivot columns give independent row indices!
  let rref_t = fp_rref(fp_mat_transpose(fp_probe))
  if rref_t.rank < cols {
    return zmat_hnf(m)
  }
  let sub_b = zmat_make(cols, cols, 0N)
  for r_idx in 0..<cols {
    let src_i = rref_t.pivots[r_idx]
    for j in 0..<cols {
      zmat_set(sub_b, r_idx, j, zmat_get(m, src_i, j))
    }
  }
  let det_d = ugcd_bigint_abs(zmat_det_bareiss(sub_b))
  if det_d == 0N {
    return zmat_hnf(m)
  }
  if det_d == 1N {
    let out = zmat_make(rows, cols, 0N)
    for c in 0..<cols {
      zmat_set(out, c, c, 1N)
    }
    return out
  }
  // Build `(rows + cols) × cols` working table reduced mod `det_d`, augmented by `det_d * I_{cols}`
  let work = zmat_make(rows + cols, cols, 0N)
  for i in 0..<rows {
    for j in 0..<cols {
      let (_, rem) = ugcd_euclid_div(zmat_get(m, i, j), det_d)
      zmat_set(work, i, j, rem)
    }
  }
  for c in 0..<cols {
    zmat_set(work, rows + c, c, det_d)
  }
  let mut r = 0
  let cur_mod = det_d
  for c in 0..<cols {
    // Combine all rows >= r in col c via extended GCD while reducing trailing columns mod `cur_mod`!
    let mut piv_row = -1
    for i in r..<work.rows {
      if zmat_get(work, i, c) != 0N {
        piv_row = i
        break
      }
    }
    if piv_row < 0 {
      continue
    }
    zmat_swap_rows(work, r, piv_row)
    if zmat_get(work, r, c) < 0N {
      for j in c..<cols {
        zmat_set(work, r, j, -zmat_get(work, r, j))
      }
    }
    for i in (r + 1)..<work.rows {
      let b_val = zmat_get(work, i, c)
      if b_val != 0N {
        let a_val = zmat_get(work, r, c)
        let (g, x, y) = ugcd_bigint_ext_gcd(a_val, b_val)
        let u_mul = -(b_val / g)
        let v_mul = a_val / g
        zmat_set(work, r, c, g)
        zmat_set(work, i, c, 0N)
        for j in (c + 1)..<cols {
          let rj = zmat_get(work, r, j)
          let ij = zmat_get(work, i, j)
          let (_, nr) = ugcd_euclid_div(x * rj + y * ij, cur_mod)
          let (_, ni) = ugcd_euclid_div(u_mul * rj + v_mul * ij, cur_mod)
          zmat_set(work, r, j, nr)
          zmat_set(work, i, j, ni)
        }
      }
    }
    let piv = zmat_get(work, r, c)
    // Reduce rows above `r` into `[0, piv)`
    for i in 0..<r {
      let v = zmat_get(work, i, c)
      if v != 0N {
        let (q, _) = ugcd_euclid_div(v, piv)
        for j in c..<cols {
          zmat_set(work, i, j, zmat_get(work, i, j) - q * zmat_get(work, r, j))
        }
      }
    }
    r = r + 1
  }
  let out = zmat_make(rows, cols, 0N)
  for i in 0..<cols {
    for j in 0..<cols {
      zmat_set(out, i, j, zmat_get(work, i, j))
    }
  }
  out
}

///|
/// Extended Euclidean algorithm over `BigInt`: returns `(g, x, y)` with `a*x + b*y = g >= 0`.
pub fn ugcd_bigint_ext_gcd(a : BigInt, b : BigInt) -> (BigInt, BigInt, BigInt) {
  let mut old_r = a
  let mut r = b
  let mut old_s = 1N
  let mut s = 0N
  let mut old_t = 0N
  let mut t = 1N
  while r != 0N {
    let q = old_r / r
    let tmp_r = old_r - q * r
    old_r = r
    r = tmp_r
    let tmp_s = old_s - q * s
    old_s = s
    s = tmp_s
    let tmp_t = old_t - q * t
    old_t = t
    t = tmp_t
  }
  if old_r < 0N {
    (-old_r, -old_s, -old_t)
  } else {
    (old_r, old_s, old_t)
  }
}

///|
/// Symmetric Chinese Remainder Theorem reconstruction modulo `M = prod moduli`:
/// returns `(x, M)` with `x in (-M/2, M/2]` and `x == residues[i] (mod moduli[i])`.
pub fn ugcd_crt_reconstruct_signed(
  residues : Array[BigInt],
  moduli : Array[BigInt],
) -> (BigInt, BigInt) {
  let mut x = 0N
  let mut big_m = 1N
  let n = if residues.length() < moduli.length() {
    residues.length()
  } else {
    moduli.length()
  }
  for i in 0..<n {
    let mi = ugcd_bigint_abs(moduli[i])
    if mi == 0N {
      return (0N, 0N)
    }
    let (_, r_mod) = ugcd_euclid_div(residues[i] - x, mi)
    let (g, inv_m, _) = ugcd_bigint_ext_gcd(big_m, mi)
    if g != 1N {
      return (0N, 0N)
    }
    let (_, step) = ugcd_euclid_div(r_mod * inv_m, mi)
    x = x + big_m * step
    big_m = big_m * mi
  }
  let (_, pos_x) = ugcd_euclid_div(x, big_m)
  let sym_x = if pos_x * 2N > big_m { pos_x - big_m } else { pos_x }
  (sym_x, big_m)
}

///|
/// Exact right integer nullspace basis of `m` (`m * v = 0` over `Z`), computed
/// from the last `cols - rank` columns of the unimodular matrix `V` in `U*M*V = D`!
pub fn ugcd_z_nullspace_basis(m : ZMat) -> Array[Array[BigInt]] {
  let snf = zmat_snf(m)
  let basis : Array[Array[BigInt]] = []
  for col in snf.rank..<m.cols {
    let vec : Array[BigInt] = []
    let mut g = 0N
    for row in 0..<m.cols {
      let val = zmat_get(snf.v, row, col)
      vec.push(val)
      g = ugcd_bigint_gcd(g, val)
    }
    if g > 1N {
      for row in 0..<vec.length() {
        vec[row] = vec[row] / g
      }
    }
    basis.push(vec)
  }
  basis
}
