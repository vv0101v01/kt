///|
// Lower-V Base Vertex (`V_lower`): Exact Elimination, Smith/Hermite Normal Forms,
// Multi-Modular CRT, and Integer Nullspace Conservation Engine.
//
// Synthesizes `notebook/core` & `notebook/canon` with `golden`'s exact BigInt
// discipline so every higher federation (`algebra`, `topos`, `scheme`,
// `condensed`, `cubical`, `bridge`) shares a single canonical elimination base.

///|
/// Matrix over prime field `F_p` (`2 <= p <= 2_147_483_647`; intermediate products widen to `Int64`).
pub(all) struct FpMat {
  rows : Int32
  cols : Int32
  p : Int32
  data : Array[Int32]
} derive(Debug, Eq)

///|
pub extend FpMat with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FpMat with Eq::{not_equal, equal}

///|
/// Reduced row echelon form result over `F_p`.
pub(all) struct FpRrefResult {
  rref : FpMat
  rank : Int32
  pivots : Array[Int32]
} derive(Debug, Eq)

///|
pub extend FpRrefResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FpRrefResult with Eq::{not_equal, equal}

///|
/// Exact `BigInt` matrix over `Z`.
pub(all) struct ZMat {
  rows : Int32
  cols : Int32
  data : Array[BigInt]
} derive(Debug, Eq)

///|
pub extend ZMat with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ZMat with Eq::{not_equal, equal}

///|
/// Certified Smith Normal Form `U * M * V = D` over `Z` with unimodular `U, V`
/// and positive divisibility chain `diag[0] | diag[1] | ... | diag[rank - 1]`.
pub(all) struct ZSnfResult {
  u : ZMat
  diag : Array[BigInt]
  v : ZMat
  rank : Int32
} derive(Debug, Eq)

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
pub fn fp_mat_mul(a : FpMat, b : FpMat) -> FpMat {
  let out = fp_mat_make(a.rows, b.cols, a.p, 0)
  for i in 0..<a.rows {
    for k in 0..<a.cols {
      let aik = fp_mat_get(a, i, k)
      if aik != 0 {
        for j in 0..<b.cols {
          let cur = fp_mat_get(out, i, j)
          let prod = fp_mul(aik, fp_mat_get(b, k, j), a.p)
          fp_mat_set(out, i, j, fp_add(cur, prod, a.p))
        }
      }
    }
  }
  out
}

///|
/// `[D-Gauss]` Gauss-Jordan elimination over `F_p` producing canonical RREF.
pub fn fp_rref(m : FpMat) -> FpRrefResult {
  let a = FpMat::{ rows: m.rows, cols: m.cols, p: m.p, data: m.data.copy(), }
  let pivots : Array[Int32] = []
  let mut r = 0
  for c in 0..<a.cols {
    if r >= a.rows {
      break
    }
    let mut piv = -1
    for i in r..<a.rows {
      if fp_mat_get(a, i, c) != 0 {
        piv = i
        break
      }
    }
    if piv < 0 {
      continue
    }
    if piv != r {
      for j in 0..<a.cols {
        let tmp = fp_mat_get(a, r, j)
        fp_mat_set(a, r, j, fp_mat_get(a, piv, j))
        fp_mat_set(a, piv, j, tmp)
      }
    }
    let inv_p = fp_inv(fp_mat_get(a, r, c), a.p)
    for j in c..<a.cols {
      fp_mat_set(a, r, j, fp_mul(fp_mat_get(a, r, j), inv_p, a.p))
    }
    for i in 0..<a.rows {
      if i != r {
        let factor = fp_mat_get(a, i, c)
        if factor != 0 {
          for j in c..<a.cols {
            let sub = fp_mul(factor, fp_mat_get(a, r, j), a.p)
            fp_mat_set(a, i, j, fp_sub(fp_mat_get(a, i, j), sub, a.p))
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
    // Find minimum non-zero |a[i, j]| in submatrix [p.., p..]
    let mut best_i = -1
    let mut best_j = -1
    let mut best_abs = 0N
    for i in p..<a.rows {
      for j in p..<a.cols {
        let av = ugcd_bigint_abs(zmat_get(a, i, j))
        if av != 0N && (best_i < 0 || av < best_abs) {
          best_i = i
          best_j = j
          best_abs = av
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
