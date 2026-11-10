///|
// Federation 7 (`discovery`) — Layer 2 Package `tensor`:
// Multilinear 3-Tensors, Cayley 2x2x2 Hyperdeterminant & Complete F_3 Rank Atlas,
// Discrete Finite-Plane Radon Transform (Gram, Inversion, Affine-Corrected Plancherel),
// and Twisted Group Algebras / Clifford Ramond Spinor Zero-Modes / Lattice Gauge Moduli.
// All linear elimination & modular arithmetic delegate directly to `@gcd` (`V_1`).

// ---------------------------------------------------------------------------
// 1. Order-3 Tensors, Flattening Rank Bounds, Cayley Hyperdeterminant & F_3 Atlas
// ---------------------------------------------------------------------------

///|
/// Order-3 tensor of shape `dim0 x dim1 x dim2` over prime field `F_p` (`field = p`).
#derive(Debug, Eq)
pub(all) struct Tensor3 {
  dim0 : Int32
  dim1 : Int32
  dim2 : Int32
  field : Int32
  data : Array[Int32]
}

///|
pub extend Tensor3 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Tensor3 with Eq::{not_equal, equal}

///|
/// Construct a zero-initialized `dim0 x dim1 x dim2` tensor over `F_p`.
pub fn t3_make(d0 : Int32, d1 : Int32, d2 : Int32, p : Int32) -> Tensor3 {
  let len = if d0 > 0 && d1 > 0 && d2 > 0 { d0 * d1 * d2 } else { 0 }
  Tensor3::{
    dim0: d0,
    dim1: d1,
    dim2: d2,
    field: p,
    data: Array::make(len, 0),
  }
}

///|
/// Construct an order-3 tensor from entry generator `f(i, j, k) mod p`.
pub fn t3_of(
  d0 : Int32,
  d1 : Int32,
  d2 : Int32,
  p : Int32,
  f : (Int32, Int32, Int32) -> Int32,
) -> Tensor3 {
  let t = t3_make(d0, d1, d2, p)
  for i in 0..<d0 {
    for j in 0..<d1 {
      for k in 0..<d2 {
        t.data[(i * d1 + j) * d2 + k] = @gcd.fp_norm(f(i, j, k), p)
      }
    }
  }
  t
}

///|
/// Read tensor entry `T[i, j, k]`.
pub fn t3_get(t : Tensor3, i : Int32, j : Int32, k : Int32) -> Int32 {
  t.data[(i * t.dim1 + j) * t.dim2 + k]
}

///|
/// Pointwise tensor addition over `F_p`.
pub fn t3_add(a : Tensor3, b : Tensor3) -> Tensor3 {
  let out = t3_make(a.dim0, a.dim1, a.dim2, a.field)
  for idx in 0..<out.data.length() {
    out.data[idx] = @gcd.fp_add(a.data[idx], b.data[idx], a.field)
  }
  out
}

///|
/// Pure rank-1 tensor `c * (u ⊗ v ⊗ w)` over `F_p`.
pub fn t3_rank1_scaled(
  c : Int32,
  u : Array[Int32],
  v : Array[Int32],
  w : Array[Int32],
  p : Int32,
) -> Tensor3 {
  t3_of(u.length(), v.length(), w.length(), p, (i, j, k) => {
    @gcd.fp_mul(c, @gcd.fp_mul(u[i], @gcd.fp_mul(v[j], w[k], p), p), p)
  })
}

///|
/// Matricization (mode-`k` unfolding, `mode in {0, 1, 2}`) into `@gcd.FpMat`.
pub fn t3_flatten(t : Tensor3, mode : Int32) -> @gcd.FpMat {
  let d0 = t.dim0
  let d1 = t.dim1
  let d2 = t.dim2
  match mode {
    0 => {
      let m = @gcd.fp_mat_make(d0, d1 * d2, t.field, 0)
      for i in 0..<d0 {
        for j in 0..<d1 {
          for k in 0..<d2 {
            @gcd.fp_mat_set(m, i, j * d2 + k, t3_get(t, i, j, k))
          }
        }
      }
      m
    }
    1 => {
      let m = @gcd.fp_mat_make(d1, d0 * d2, t.field, 0)
      for j in 0..<d1 {
        for i in 0..<d0 {
          for k in 0..<d2 {
            @gcd.fp_mat_set(m, j, i * d2 + k, t3_get(t, i, j, k))
          }
        }
      }
      m
    }
    _ => {
      let m = @gcd.fp_mat_make(d2, d0 * d1, t.field, 0)
      for k in 0..<d2 {
        for i in 0..<d0 {
          for j in 0..<d1 {
            @gcd.fp_mat_set(m, k, i * d1 + j, t3_get(t, i, j, k))
          }
        }
      }
      m
    }
  }
}

///|
/// `[P-Flat]` Flattening rank lower bound `max_{m in 0..2} rank(flatten_m(T))`.
pub fn t3_flatten_rank_lower_bound(t : Tensor3) -> Int32 {
  let r0 = @gcd.fp_rank(t3_flatten(t, 0))
  let r1 = @gcd.fp_rank(t3_flatten(t, 1))
  let r2 = @gcd.fp_rank(t3_flatten(t, 2))
  let m01 = if r0 > r1 { r0 } else { r1 }
  if m01 > r2 {
    m01
  } else {
    r2
  }
}

///|
/// Cayley's 12-term `2x2x2` hyperdeterminant `Det(T) mod p` using overflow-safe `Int64`:
/// `Det = sum_4 (diag)^2 - 2 * sum_6 (rect) + 4 * sum_2 (tetra)`.
pub fn t3_hyperdet222(t : Tensor3) -> Int32 {
  let p = t.field
  if p <= 1 || t.dim0 != 2 || t.dim1 != 2 || t.dim2 != 2 {
    return 0
  }
  let g = (i : Int32, j : Int32, k : Int32) => t3_get(t, i, j, k)
  let mul = (a : Int32, b : Int32) => @gcd.fp_mul(a, b, p)
  let add = (a : Int32, b : Int32) => @gcd.fp_add(a, b, p)
  let sub = (a : Int32, b : Int32) => @gcd.fp_sub(a, b, p)
  let mono4 = (a : Int32, b : Int32, c : Int32, d : Int32) => {
    mul(mul(a, b), mul(c, d))
  }
  let sq = (x : Int32) => mul(x, x)
  let dg = add(
    add(sq(mul(g(0, 0, 0), g(1, 1, 1))), sq(mul(g(0, 0, 1), g(1, 1, 0)))),
    add(sq(mul(g(0, 1, 0), g(1, 0, 1))), sq(mul(g(0, 1, 1), g(1, 0, 0)))),
  )
  let rc1 = add(
    mono4(g(0, 0, 0), g(0, 0, 1), g(1, 1, 0), g(1, 1, 1)),
    mono4(g(0, 0, 0), g(0, 1, 0), g(1, 0, 1), g(1, 1, 1)),
  )
  let rc2 = add(
    mono4(g(0, 0, 0), g(0, 1, 1), g(1, 0, 0), g(1, 1, 1)),
    mono4(g(0, 0, 1), g(0, 1, 0), g(1, 0, 1), g(1, 1, 0)),
  )
  let rc3 = add(
    mono4(g(0, 0, 1), g(0, 1, 1), g(1, 0, 0), g(1, 1, 0)),
    mono4(g(0, 1, 0), g(0, 1, 1), g(1, 0, 0), g(1, 0, 1)),
  )
  let rc = add(add(rc1, rc2), rc3)
  let tet = add(
    mono4(g(0, 0, 0), g(0, 1, 1), g(1, 0, 1), g(1, 1, 0)),
    mono4(g(0, 0, 1), g(0, 1, 0), g(1, 0, 0), g(1, 1, 1)),
  )
  add(sub(dg, mul(2, rc)), mul(4, tet))
}

///|
/// Verify `[P-Shear]` & `[T-Dual-Tensor]`: `t3_hyperdet222(T)` is invariant under
/// all 6 elementary `SL_2(F_p)` shears across modes `{0, 1, 2}` AND all `3! = 6`
/// permutations of the three tensor axes.
pub fn t3_check_sl2_shear_and_s3_invariance(t : Tensor3) -> Bool {
  let base = t3_hyperdet222(t)
  let p = t.field
  for mode in 0..<3 {
    for dir in 0..<2 {
      let s = t3_of(2, 2, 2, p, (i, j, k) => {
        let keep = t3_get(t, i, j, k)
        let bit = match mode {
          0 => i
          1 => j
          _ => k
        }
        let other = match mode {
          0 => t3_get(t, 1 - i, j, k)
          1 => t3_get(t, i, 1 - j, k)
          _ => t3_get(t, i, j, 1 - k)
        }
        if (dir == 0 && bit == 0) || (dir == 1 && bit == 1) {
          @gcd.fp_add(keep, other, p)
        } else {
          keep
        }
      })
      if t3_hyperdet222(s) != base {
        return false
      }
    }
  }
  for perm in 0..<6 {
    let q = t3_of(2, 2, 2, p, (i, j, k) => {
      match perm {
        0 => t3_get(t, i, j, k)
        1 => t3_get(t, i, k, j)
        2 => t3_get(t, j, i, k)
        3 => t3_get(t, j, k, i)
        4 => t3_get(t, k, i, j)
        _ => t3_get(t, k, j, i)
      }
    })
    if t3_hyperdet222(q) != base {
      return false
    }
  }
  true
}

///|
/// Complete exhaustive classification of all `3^8 = 6,561` `2x2x2` tensors over `F_3`
/// (`[T-Strassen-F3]`): stores exact tensor rank (`0..3`), unordered 2-term rank-1
/// decomposition multiplicity, and Cayley hyperdeterminant for every base-3 code `0..6560`.
#derive(Debug, Eq)
pub(all) struct F3Tensor222Atlas {
  total_tensors : Int32
  rank_counts : Array[Int32]
  det_zero_count : Int32
  det_nonzero_count : Int32
  rank2_det_zero_count : Int32
  rank2_det_nonzero_count : Int32
  rank3_det_zero_count : Int32
  rank3_det_nonzero_count : Int32
  ranks : Array[Int32]
  rank2_decomp_counts : Array[Int32]
  hyperdets : Array[Int32]
}

///|
pub extend F3Tensor222Atlas with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend F3Tensor222Atlas with Eq::{not_equal, equal}

///|
/// Decode base-3 code `0..6560` into a `2x2x2` tensor over `F_3`.
pub fn f3_tensor_of_code(code : Int32) -> Tensor3 {
  let t = t3_make(2, 2, 2, 3)
  let mut r = code
  for idx in 0..<8 {
    t.data[idx] = r % 3
    r = r / 3
  }
  t
}

///|
/// Encode a `2x2x2` tensor over `F_3` into base-3 code `0..6560`.
pub fn f3_tensor_code(t : Tensor3) -> Int32 {
  let mut code = 0
  let mut mult = 1
  for idx in 0..<8 {
    code = code + t.data[idx] * mult
    mult = mult * 3
  }
  code
}

///|
/// Build the exact `6,561`-tensor `F_3^{2x2x2}` rank & hyperdeterminant atlas in `O(|R_1|^2)`
/// (`128` projectively normalized pure tensors => `8,128` pairs).
pub fn f3_tensor222_atlas_build() -> F3Tensor222Atlas {
  let total = 6561
  let ranks = Array::make(total, 3)
  let decomp2 = Array::make(total, 0)
  ranks[0] = 0

  // Canonical P^1(F_3) lines: [1,0], [0,1], [1,1], [1,2]
  let p1 : Array[Array[Int32]] = [[1, 0], [0, 1], [1, 1], [1, 2]]
  let pure_tensors : Array[Tensor3] = []
  for c in 1..<=2 {
    for u in p1 {
      for v in p1 {
        for w in p1 {
          let t = t3_rank1_scaled(c, u, v, w, 3)
          let code = f3_tensor_code(t)
          ranks[code] = 1
          pure_tensors.push(t)
        }
      }
    }
  }

  let n_pure = pure_tensors.length()
  for i in 0..<n_pure {
    for j in (i + 1)..<n_pure {
      let s = t3_add(pure_tensors[i], pure_tensors[j])
      let code = f3_tensor_code(s)
      decomp2[code] = decomp2[code] + 1
      if ranks[code] > 2 {
        ranks[code] = 2
      }
    }
  }

  let rank_counts = [0, 0, 0, 0]
  let dets = @swar.gf3_sweep_all_6561_hyperdets()
  let mut det_zero = 0
  let mut det_nz = 0
  let mut r2_d0 = 0
  let mut r2_dnz = 0
  let mut r3_d0 = 0
  let mut r3_dnz = 0
  for code in 0..<total {
    let d = dets[code]
    let rk = ranks[code]
    rank_counts[rk] = rank_counts[rk] + 1
    if d == 0 {
      det_zero = det_zero + 1
      if rk == 2 {
        r2_d0 = r2_d0 + 1
      } else if rk == 3 {
        r3_d0 = r3_d0 + 1
      }
    } else {
      det_nz = det_nz + 1
      if rk == 2 {
        r2_dnz = r2_dnz + 1
      } else if rk == 3 {
        r3_dnz = r3_dnz + 1
      }
    }
  }

  F3Tensor222Atlas::{
    total_tensors: total,
    rank_counts,
    det_zero_count: det_zero,
    det_nonzero_count: det_nz,
    rank2_det_zero_count: r2_d0,
    rank2_det_nonzero_count: r2_dnz,
    rank3_det_zero_count: r3_d0,
    rank3_det_nonzero_count: r3_dnz,
    ranks,
    rank2_decomp_counts: decomp2,
    hyperdets: dets,
  }
}

// ---------------------------------------------------------------------------
// 2. Discrete Finite-Plane Radon Transform (`Z_n^2 -> F_p`)
// ---------------------------------------------------------------------------

///|
/// Discrete Radon transform parameters on finite grid `Z_n^2` with values in `F_p`.
#derive(Debug, Eq)
pub(all) struct DiscreteRadon {
  n : Int32
  p : Int32
  dirs : Int32
}

///|
pub extend DiscreteRadon with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DiscreteRadon with Eq::{not_equal, equal}

///|
pub fn radon_make(n : Int32, p : Int32) -> DiscreteRadon {
  DiscreteRadon::{ n, p, dirs: n + 1, }
}

///|
/// Points `(x, y)` (encoded `x * n + y`) lying on affine line `(dir, t)` in `Z_n^2`.
pub fn radon_line_points(
  r : DiscreteRadon,
  dir : Int32,
  t : Int32,
) -> Array[Int32] {
  let n = r.n
  let out : Array[Int32] = []
  if dir == n {
    for y in 0..<n {
      out.push(t * n + y)
    }
  } else {
    for x in 0..<n {
      let yy = ((dir * x + t) % n + n) % n
      out.push(x * n + yy)
    }
  }
  out
}

///|
/// Incidence matrix `R` (`(n+1)*n` lines by `n^2` points) over `F_p`.
pub fn radon_incidence_matrix(r : DiscreteRadon) -> @gcd.FpMat {
  let nr = r.dirs * r.n
  let nc = r.n * r.n
  let m = @gcd.fp_mat_make(nr, nc, r.p, 0)
  for line_idx in 0..<nr {
    let dir = line_idx / r.n
    let t = line_idx % r.n
    for pt in radon_line_points(r, dir, t) {
      @gcd.fp_mat_set(m, line_idx, pt, 1)
    }
  }
  m
}

///|
/// Apply Radon transform `(Rf)(line)` over `Z` (exact integer sums) for energy/ratio checks.
pub fn radon_apply_exact(r : DiscreteRadon, f : Array[Int32]) -> Array[Int32] {
  let nr = r.dirs * r.n
  let out = Array::make(nr, 0)
  for line_idx in 0..<nr {
    let dir = line_idx / r.n
    let t = line_idx % r.n
    let mut s = 0
    for pt in radon_line_points(r, dir, t) {
      s = s + f[pt]
    }
    out[line_idx] = s
  }
  out
}

///|
/// `[T-Radon-Gram]` Check whether `R^T * R == n * I + J (mod p)`.
/// Holds iff `Z_n` is a field (`n` prime): fails at composite `n = 4` because two points can share 0 or 2 lines!
pub fn radon_check_gram_identity(r : DiscreteRadon) -> Bool {
  let m = radon_incidence_matrix(r)
  let g = @gcd.fp_mat_mul(@gcd.fp_mat_transpose(m), m)
  let nc = r.n * r.n
  let diag_exp = @gcd.fp_norm(r.n + 1, r.p)
  let off_exp = @gcd.fp_norm(1, r.p)
  for i in 0..<nc {
    for j in 0..<nc {
      let exp = if i == j { diag_exp } else { off_exp }
      if @gcd.fp_mat_get(g, i, j) != exp {
        return false
      }
    }
  }
  true
}

///|
/// `[T-Radon-Inv]` Explicit Sherman–Morrison inversion of `R` over `F_p` when `n` is prime
/// and `p` does not divide `n * (n + 1)`:
/// `f = (1/n) * (R^T (Rf) - (1/(n+1)) * sum_{pt} (R^T Rf)(pt))`.
pub fn radon_invert_fp(
  r : DiscreteRadon,
  rf_mod : Array[Int32],
) -> Array[Int32] {
  let p = r.p
  let nc = r.n * r.n
  let m = radon_incidence_matrix(r)
  let rt = @gcd.fp_mat_transpose(m)
  let back = Array::make(nc, 0)
  let mut total_back = 0
  for i in 0..<nc {
    let mut s = 0
    for j in 0..<rt.cols {
      s = @gcd.fp_add(
        s,
        @gcd.fp_mul(@gcd.fp_mat_get(rt, i, j), rf_mod[j], p),
        p,
      )
    }
    back[i] = s
    total_back = @gcd.fp_add(total_back, s, p)
  }
  // Since `(n*I + J) * 1 = (n + n^2) * 1 = n*(n+1) * 1`, we have `sum(f) = total_back / (n*(n+1))`,
  // and `n * f[i] = back[i] - sum(f)` => `f[i] = (back[i] - corr) / n (mod p)`!
  let inv_n = @gcd.fp_inv(r.n, p)
  let inv_n_np1 = @gcd.fp_inv(r.n * (r.n + 1), p)
  let corr = @gcd.fp_mul(total_back, inv_n_np1, p)
  let out = Array::make(nc, 0)
  for i in 0..<nc {
    out[i] = @gcd.fp_mul(inv_n, @gcd.fp_sub(back[i], corr, p), p)
  }
  out
}

///|
/// Compute exact integer quadratic observables `(sum f^2, sum (Rf)^2, (sum f)^2)`
/// verifying the affine-corrected Plancherel law `sum (Rf)^2 = n * sum f^2 + (sum f)^2` for prime `n`.
pub fn radon_energy_triple(
  r : DiscreteRadon,
  f : Array[Int32],
) -> (Int32, Int32, Int32) {
  let rf = radon_apply_exact(r, f)
  let mut sf = 0
  let mut sf2 = 0
  for v in f {
    sf = sf + v
    sf2 = sf2 + v * v
  }
  let mut srf2 = 0
  for w in rf {
    srf2 = srf2 + w * w
  }
  (sf2, srf2, sf * sf)
}

// ---------------------------------------------------------------------------
// 3. Twisted Group Algebras, Symplectic Cocycle Radical, Clifford Spinors & Gauge Moduli
// ---------------------------------------------------------------------------

///|
/// Report for twisted group algebra `k^omega[(Z/ell)^d]` under bilinear 2-cocycle
/// `omega(a, b) = sum_{i < j} B_{ij} a_i b_j (mod ell)`.
#derive(Debug, Eq)
pub(all) struct TwistedGroupReport {
  ell : Int32
  dim_d : Int32
  group_order : Int32
  radical_size : Int32
  center_dim : Int32
  cocycle_sum_mod_ell : Int32
  coboundary_gauge_invariant : Bool
}

///|
pub extend TwistedGroupReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TwistedGroupReport with Eq::{not_equal, equal}

///|
fn decode_elem_z_ell(code : Int32, d : Int32, ell : Int32) -> Array[Int32] {
  let out = Array::make(d, 0)
  let mut r = code
  for i in 0..<d {
    out[i] = r % ell
    r = r / ell
  }
  out
}

///|
fn encode_elem_z_ell(v : Array[Int32], ell : Int32) -> Int32 {
  let mut code = 0
  let mut mult = 1
  for x in v {
    code = code + (x % ell + ell) % ell * mult
    mult = mult * ell
  }
  code
}

///|
/// Analyze twisted group algebra `F_p^omega[(Z/ell)^d]` with strict upper-triangular
/// bilinear cocycle `omega(a, b) = sum_{i > j} a_i * b_j (mod ell)` (the Jordan–Wigner
/// Clifford cocycle at `ell = 2`), verifying:
///   1. Symplectic bicharacter `beta(a, b) = omega(a, b) - omega(b, a) (mod ell)`;
///   2. `dim Z(F_p^omega[G]) == |rad(beta)|` (`1` for even `d`, `ell` for odd `d`);
///   3. Invariance under coboundary gauge flow `omega' = omega + delta mu`!
pub fn twisted_group_clifford_cocycle_report(
  ell : Int32,
  d : Int32,
) -> TwistedGroupReport {
  let mut ord = 1
  for _ in 0..<d {
    ord = ord * ell
  }
  let omega = (a : Array[Int32], b : Array[Int32]) => {
    let mut s = 0
    for i in 0..<d {
      for j in 0..<i {
        s = s + a[i] * b[j]
      }
    }
    (s % ell + ell) % ell
  }

  // Symplectic radical: `a in G` such that `omega(a, b) == omega(b, a) (mod ell)` for all `b in G`.
  // In an abelian group, a basis element `e_a` lies in `Z(k^omega[G])` iff `omega(a, b) == omega(b, a)` for all `b`!
  // Let's also verify center dimension independently via commutator linear equations over `F_p` (`p = 101` when `ell = 2`)!
  let elems : Array[Array[Int32]] = []
  for code in 0..<ord {
    elems.push(decode_elem_z_ell(code, d, ell))
  }
  let mut rad_cnt = 0
  let mut omega_sum = 0
  for a in elems {
    let mut in_rad = true
    for b in elems {
      let wab = omega(a, b)
      let wba = omega(b, a)
      omega_sum = (omega_sum + wab) % ell
      if wab != wba {
        in_rad = false
      }
    }
    if in_rad {
      rad_cnt = rad_cnt + 1
    }
  }

  // Independent center calculation when `ell = 2` over `F_5` (`zeta_2 = -1 = 4 mod 5`):
  // `[sum c_a e_a, e_b] = sum_a c_a ((-1)^{omega(a,b)} - (-1)^{omega(b,a)}) e_{a+b} = 0`
  let p_alg = 5
  let eq_rows : Array[Array[Int32]] = []
  if ell == 2 {
    for b_idx in 0..<ord {
      let b = elems[b_idx]
      for a_idx in 0..<ord {
        let a = elems[a_idx]
        let s_ab = if omega(a, b) == 0 { 1 } else { p_alg - 1 }
        let s_ba = if omega(b, a) == 0 { 1 } else { p_alg - 1 }
        let diff = @gcd.fp_sub(s_ab, s_ba, p_alg)
        if diff != 0 {
          let row = Array::make(ord, 0)
          row[a_idx] = diff
          eq_rows.push(row)
        }
      }
    }
  }
  let center_dim = if ell == 2 {
    if eq_rows.length() == 0 {
      ord
    } else {
      ord - @gcd.fp_rank(@gcd.fp_mat_from_rows(eq_rows, p_alg))
    }
  } else {
    rad_cnt
  }

  // Coboundary gauge transformation: `mu(x) = (x_0 + 2 * code(x)) mod ell`
  // `(delta mu)(a, b) = mu(a) + mu(b) - mu(a + b)` is symmetric on abelian `G`,
  // so `omega'(a, b) - omega'(b, a) == omega(a, b) - omega(b, a)` and `sum_{a,b} (delta mu)(a,b) == ord * mu(0) (mod ell)`!
  let mu = (x : Array[Int32]) => {
    if x.length() == 0 {
      0
    } else {
      (x[0] + 2 * encode_elem_z_ell(x, ell)) % ell
    }
  }
  let add_g = (a : Array[Int32], b : Array[Int32]) => {
    let out = Array::make(d, 0)
    for i in 0..<d {
      out[i] = (a[i] + b[i]) % ell
    }
    out
  }
  let mut rad_after = 0
  let mut sum_after = 0
  for a in elems {
    let mut in_rad = true
    for b in elems {
      let ab = add_g(a, b)
      let dmu_ab = ((mu(a) + mu(b) - mu(ab)) % ell + ell) % ell
      let dmu_ba = ((mu(b) + mu(a) - mu(ab)) % ell + ell) % ell
      let wab2 = (omega(a, b) + dmu_ab) % ell
      let wba2 = (omega(b, a) + dmu_ba) % ell
      sum_after = (sum_after + wab2) % ell
      if wab2 != wba2 {
        in_rad = false
      }
    }
    if in_rad {
      rad_after = rad_after + 1
    }
  }

  TwistedGroupReport::{
    ell,
    dim_d: d,
    group_order: ord,
    radical_size: rad_cnt,
    center_dim,
    cocycle_sum_mod_ell: omega_sum,
    coboundary_gauge_invariant: rad_after == rad_cnt &&
    center_dim == rad_cnt &&
    sum_after == omega_sum,
  }
}

///|
/// Jordan–Wigner Clifford algebra `Cl_d(F_p)` verification (`p == 1 mod 4`, e.g. `p = 5` or `13`):
/// constructs `2^{d/2} x 2^{d/2}` matrices `gamma_0 .. gamma_{d-1}` over `F_p` and checks
/// `{gamma_a, gamma_b} = 2 * delta_{ab} * I`! Rejects `p == 3 mod 4` (`clifford_available == false`).
pub fn clifford_ramond_anticommutator_ok(d : Int32, p : Int32) -> Bool {
  if d <= 0 || p <= 2 {
    return false
  }
  // Find imaginary unit `iu` with `iu^2 == p - 1 (mod p)`
  let mut iu = -1
  for x in 1..<p {
    if @gcd.fp_mul(x, x, p) == p - 1 {
      iu = x
      break
    }
  }
  if iu < 0 {
    return false
  }
  let kron = (a : @gcd.FpMat, b : @gcd.FpMat) => {
    let out = @gcd.fp_mat_make(a.rows * b.rows, a.cols * b.cols, p, 0)
    for r1 in 0..<a.rows {
      for c1 in 0..<a.cols {
        let v1 = @gcd.fp_mat_get(a, r1, c1)
        if v1 != 0 {
          for r2 in 0..<b.rows {
            for c2 in 0..<b.cols {
              let prod = @gcd.fp_mul(v1, @gcd.fp_mat_get(b, r2, c2), p)
              @gcd.fp_mat_set(out, r1 * b.rows + r2, c1 * b.cols + c2, prod)
            }
          }
        }
      }
    }
    out
  }
  let id2 = @gcd.fp_mat_from_rows([[1, 0], [0, 1]], p)
  let px = @gcd.fp_mat_from_rows([[0, 1], [1, 0]], p)
  let py = @gcd.fp_mat_from_rows([[0, p - iu], [iu, 0]], p)
  let pz = @gcd.fp_mat_from_rows([[1, 0], [0, p - 1]], p)

  let m = if d / 2 > 0 { d / 2 } else { 1 }
  let pauli_str = (ops : Array[Int32]) => {
    let mut acc = @gcd.fp_mat_from_rows([[1]], p)
    for op in ops {
      let piece = match op {
        1 => px
        2 => py
        3 => pz
        _ => id2
      }
      acc = kron(acc, piece)
    }
    acc
  }

  let gammas : Array[@gcd.FpMat] = []
  let mut j = 0
  while 2 * j + 1 < d {
    let ops_x = Array::make(m, 0)
    let ops_y = Array::make(m, 0)
    for q in 0..<m {
      if q < j {
        ops_x[q] = 3
        ops_y[q] = 3
      } else if q == j {
        ops_x[q] = 1
        ops_y[q] = 2
      }
    }
    gammas.push(pauli_str(ops_x))
    gammas.push(pauli_str(ops_y))
    j = j + 1
  }
  if d % 2 == 1 {
    gammas.push(pauli_str(Array::make(m, 3)))
  }

  let dim_s = gammas[0].rows
  for a in 0..<d {
    for b in 0..<d {
      let ab = @gcd.fp_mat_mul(gammas[a], gammas[b])
      let ba = @gcd.fp_mat_mul(gammas[b], gammas[a])
      for r in 0..<dim_s {
        for c in 0..<dim_s {
          let sum = @gcd.fp_add(
            @gcd.fp_mat_get(ab, r, c),
            @gcd.fp_mat_get(ba, r, c),
            p,
          )
          let exp = if a == b && r == c { 2 % p } else { 0 }
          if sum != exp {
            return false
          }
        }
      }
    }
  }
  true
}

///|
/// Verify discrete `Z/ell` lattice gauge moduli on `2x2` torus `T^2` (`[T-Gauge-Moduli-Bij]`):
/// - Total 1-cochain link configurations `= ell^8`;
/// - Flat connections (`plaquette curvature == 0` on all 4 faces; Bianchi `sum F == 0 mod ell`);
/// - Distinct gauge orbits of flat connections `== ell^2 == |H^1(T^2, Z/ell)|`, bijectively
///   indexed by Wilson loop holonomies `(hol_x, hol_y) in (Z/ell)^2`!
pub fn lattice_torus_gauge_moduli_verify(ell : Int32) -> (Int32, Int32, Bool) {
  // On a 2x2 torus: 4 vertices, 8 directed edges (4 horizontal h[x,y], 4 vertical v[x,y]), 4 plaquettes.
  // A flat connection satisfies F_{x,y} = h[x,y] + v[x+1,y] - h[x,y+1] - v[x,y] == 0 (mod ell).
  // Gauge group (Z/ell)^4 acts by (A_e -> A_e + g(head) - g(tail)), stabilizer = constant Z/ell (size ell),
  // so each gauge orbit of flat connections has size ell^3, and total flat connections = ell^5 => ell^5 / ell^3 = ell^2 orbits!
  // Let's enumerate all `ell^8` configurations for `ell = 2` (`256` configs) or `ell = 3` (`6,561` configs)!
  let mut total = 1
  for _ in 0..<8 {
    total = total * ell
  }
  let mut flat_count = 0
  let hol_seen = Array::make(ell * ell, 0)
  let mut bianchi_all_ok = true
  for code in 0..<total {
    let e = decode_elem_z_ell(code, 8, ell)
    // h(x,y) = e[2*x + y], v(x,y) = e[4 + 2*x + y] for x,y in {0, 1}
    let h = (x : Int32, y : Int32) => e[x % 2 * 2 + y % 2]
    let v = (x : Int32, y : Int32) => e[4 + x % 2 * 2 + y % 2]
    let mut f_sum = 0
    let mut is_flat = true
    for x in 0..<2 {
      for y in 0..<2 {
        let curv = ((h(x, y) + v(x + 1, y) - h(x, y + 1) - v(x, y)) % ell + ell) %
          ell
        f_sum = (f_sum + curv) % ell
        if curv != 0 {
          is_flat = false
        }
      }
    }
    if f_sum != 0 {
      bianchi_all_ok = false
    }
    if is_flat {
      flat_count = flat_count + 1
      let hx = (h(0, 0) + h(1, 0)) % ell
      let hy = (v(0, 0) + v(0, 1)) % ell
      hol_seen[hx * ell + hy] = hol_seen[hx * ell + hy] + 1
    }
  }
  let orbit_size = ell * ell * ell
  let mut distinct_hol = 0
  let mut uniform_fibers = true
  for cnt in hol_seen {
    if cnt > 0 {
      distinct_hol = distinct_hol + 1
      if cnt != orbit_size {
        uniform_fibers = false
      }
    }
  }
  let ok = bianchi_all_ok &&
    distinct_hol == ell * ell &&
    uniform_fibers &&
    flat_count == ell * ell * orbit_size
  (flat_count, distinct_hol, ok)
}
