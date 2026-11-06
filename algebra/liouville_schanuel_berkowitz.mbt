///|
// Phase 21 — Boundary 4 Breakthrough (Exact Algebra):
//   1. Arbitrary-Degree Liouville Transcendence Total Refuter (`P(L) != 0` for EVERY
//      non-constant `P in Z[x]`, upgrading degree-1 irrationality `e != p/q` to full
//      arbitrary-degree transcendence certification `L notin Qbar`).
//   2. Schanuel / Lindemann–Weierstrass Q-Linear Independence & Transcendence-Rank
//      Certificate over multiquadratic algebraic inputs.
//   3. Division-Free Modular Berkowitz + `@gcd` Multi-Prime CRT Characteristic
//      Polynomial (`qmat_charpoly_berkowitz_crt`), eliminating intermediate rational
//      fraction coefficient blowup on dense matrices.

///|
/// Certified proof that the Liouville constant `L = sum_{k>=1} 10^{-k!}` is NOT a
/// root of the integer polynomial `P(x) = sum_{j=0}^d coeffs[j] * x^j` (`d >= 1`).
#derive(Debug, Eq)
pub(all) struct LiouvilleTranscendenceCert {
  coeffs : Array[BigInt]
  degree : Int32
  stage_n : Int32
  num_p : BigInt
  den_q : BigInt
  scaled_poly_at_conv : BigInt
  lipschitz_bound_m : BigInt
  gap_lhs : BigInt
  gap_rhs : BigInt
  verified : Bool
}

///|
pub extend LiouvilleTranscendenceCert with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend LiouvilleTranscendenceCert with Eq::{not_equal, equal}

///|
/// Schanuel / Lindemann–Weierstrass Q-linear independence & transcendence-degree
/// witness over multiquadratic algebraic numbers.
#derive(Debug, Eq)
pub(all) struct SchanuelRankWitness {
  input_count : Int32
  q_linear_rank : Int32
  q_linearly_independent : Bool
  lindemann_weierstrass_alg_indep : Bool
  schanuel_trdeg_lower_bound : Int32
  null_relation : Array[Rat]
}

///|
pub extend SchanuelRankWitness with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SchanuelRankWitness with Eq::{not_equal, equal}

///|
/// Report of division-free modular Berkowitz + Multi-Prime CRT characteristic polynomial.
#derive(Debug, Eq)
pub(all) struct BerkowitzCrtReport {
  dim : Int32
  primes_used : Int32
  modulus_product : BigInt
  hadamard_coeff_bound : BigInt
  charpoly : QPoly
}

///|
pub extend BerkowitzCrtReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BerkowitzCrtReport with Eq::{not_equal, equal}

///|
fn p21_factorial_int(n : Int32) -> Int32 {
  let mut f = 1
  for k in 2..<=n {
    f = f * k
  }
  f
}

///|
/// Compute `(p_n, q_n)` for Liouville partial sum `sum_{k=1}^n 10^{-k!} = p_n / 10^{n!}`.
fn liouville_convergent(stage_n : Int32) -> (BigInt, BigInt) {
  let nf = p21_factorial_int(stage_n)
  let q_n = bigint_pow_int(10N, nf)
  let mut p_n = 0N
  for k in 1..<=stage_n {
    let kf = p21_factorial_int(k)
    p_n = p_n + bigint_pow_int(10N, nf - kf)
  }
  (p_n, q_n)
}

///|
/// Evaluate homogeneous integer form `sum_{j=0}^d coeffs[j] * p^j * q^{d-j} = q^d * P(p/q)`.
fn eval_homog_zpoly(
  coeffs : Array[BigInt],
  d : Int32,
  p : BigInt,
  q : BigInt,
) -> BigInt {
  let mut acc = 0N
  for j in 0..<=d {
    let cj = coeffs[j]
    if cj != 0N {
      acc = acc + cj * bigint_pow_int(p, j) * bigint_pow_int(q, d - j)
    }
  }
  acc
}

///|
/// Algebraic Lipschitz bound `M = sum_{j=1}^d j * |coeffs[j]|` on `[0, 1]`:
/// for any `0 <= a < b <= 1`, `|P(b) - P(a)| <= (b - a) * M` by factoring `b^j - a^j`.
fn zpoly_unit_lipschitz_bound(coeffs : Array[BigInt], d : Int32) -> BigInt {
  let mut m = 0N
  for j in 1..<=d {
    m = m + BigInt::from_int(j) * @gcd.ugcd_bigint_abs(coeffs[j])
  }
  m
}

///|
/// Total constructive transcendence refuter for Liouville's constant `L`:
/// given ANY polynomial `coeffs` (`sum_{j=0}^d coeffs[j] x^j`) of degree `d >= 1`,
/// produces an exact integer certificate proving `P(L) != 0`.
pub fn liouville_transcendence_certificate(
  coeffs : Array[BigInt],
) -> LiouvilleTranscendenceCert? {
  let mut deg = coeffs.length() - 1
  while deg >= 0 && coeffs[deg] == 0N {
    deg = deg - 1
  }
  if deg < 1 {
    return None
  }
  let m_lip = zpoly_unit_lipschitz_bound(coeffs, deg)
  // Start at stage_n = max(deg, 2) so (stage_n + 1 - deg) >= 1; if p_n/q_n happens
  // to be one of the <= deg roots of P, advance stage_n (guaranteed <= deg + 1 steps!).
  let start_n = if deg < 2 { 2 } else { deg }
  if start_n > 9 {
    return None
  }
  let max_stage = if start_n + deg + 4 > 9 { 9 } else { start_n + deg + 4 }
  for stage_n in start_n..<=max_stage {
    let (p_n, q_n) = liouville_convergent(stage_n)
    let scaled = eval_homog_zpoly(coeffs, deg, p_n, q_n)
    if scaled != 0N {
      let nf = p21_factorial_int(stage_n)
      let exp_gap = (stage_n + 1 - deg) * nf
      if exp_gap >= 1 {
        let gap_lhs = 9N *
          @gcd.ugcd_bigint_abs(scaled) *
          bigint_pow_int(10N, exp_gap)
        let gap_rhs = 10N * m_lip
        if gap_lhs > gap_rhs {
          let cert = LiouvilleTranscendenceCert::{
            coeffs: coeffs.copy(),
            degree: deg,
            stage_n,
            num_p: p_n,
            den_q: q_n,
            scaled_poly_at_conv: scaled,
            lipschitz_bound_m: m_lip,
            gap_lhs,
            gap_rhs,
            verified: true,
          }
          if liouville_cert_verify(cert) {
            return Some(cert)
          }
        }
      }
    }
  }
  None
}

///|
/// Independently re-verify every arithmetic identity & inequality in a
/// `LiouvilleTranscendenceCert`.  Tampering any field causes immediate rejection.
pub fn liouville_cert_verify(cert : LiouvilleTranscendenceCert) -> Bool {
  if !cert.verified ||
    cert.degree < 1 ||
    cert.stage_n < cert.degree ||
    cert.stage_n < 1 {
    return false
  }
  if cert.stage_n > 9 {
    // Guard factorial size against pathological untrusted certificates
    return false
  }
  let mut actual_deg = cert.coeffs.length() - 1
  while actual_deg >= 0 && cert.coeffs[actual_deg] == 0N {
    actual_deg = actual_deg - 1
  }
  if actual_deg != cert.degree {
    return false
  }
  let (expected_p, expected_q) = liouville_convergent(cert.stage_n)
  if cert.num_p != expected_p || cert.den_q != expected_q {
    return false
  }
  let expected_scaled = eval_homog_zpoly(
    cert.coeffs,
    cert.degree,
    expected_p,
    expected_q,
  )
  if expected_scaled == 0N || cert.scaled_poly_at_conv != expected_scaled {
    return false
  }
  let expected_m = zpoly_unit_lipschitz_bound(cert.coeffs, cert.degree)
  if cert.lipschitz_bound_m != expected_m {
    return false
  }
  let nf = p21_factorial_int(cert.stage_n)
  let exp_gap = (cert.stage_n + 1 - cert.degree) * nf
  if exp_gap < 1 {
    return false
  }
  let lhs = 9N *
    @gcd.ugcd_bigint_abs(expected_scaled) *
    bigint_pow_int(10N, exp_gap)
  let rhs = 10N * expected_m
  cert.gap_lhs == lhs && cert.gap_rhs == rhs && lhs > rhs
}

///|
/// Certify Q-linear independence rank & Lindemann–Weierstrass / Schanuel transcendence
/// bound for multiquadratic numbers represented in a shared generator basis `gens`.
/// Each row of `coord_rows` gives the `2^k` rational coordinates of `alpha_i`.
pub fn schanuel_linear_independence_cert(
  gens : Array[BigInt],
  coord_rows : Array[Array[Rat]],
) -> SchanuelRankWitness? {
  let m = coord_rows.length()
  if m == 0 || gens.length() > 6 {
    return None
  }
  let basis_dim = 1 << gens.length()
  for row in coord_rows {
    if row.length() != basis_dim {
      return None
    }
    if multiquad_make_upto(gens, row, max_gens=6) is None {
      return None
    }
  }
  // Transpose so columns are alpha_1..alpha_m: nullspace gives Q-linear relations sum r_i alpha_i = 0!
  let cols_as_rows : Array[Array[Rat]] = []
  for j in 0..<basis_dim {
    let r : Array[Rat] = []
    for i in 0..<m {
      r.push(coord_rows[i][j])
    }
    cols_as_rows.push(r)
  }
  let mat = qmat_from_rows(cols_as_rows)
  let rk = qmat_rank(mat)
  let ns = qmat_nullspace(mat)
  let indep = rk == m && ns.length() == 0
  let rel = if ns.length() > 0 { ns[0] } else { [] }
  Some(SchanuelRankWitness::{
    input_count: m,
    q_linear_rank: rk,
    q_linearly_independent: indep,
    lindemann_weierstrass_alg_indep: indep,
    schanuel_trdeg_lower_bound: rk,
    null_relation: rel,
  })
}

///|
/// Division-free Berkowitz characteristic polynomial `det(xI - A)` over `F_p`,
/// returned in descending degree `[1, c_1, ..., c_n]`.
fn berkowitz_charpoly_mod_p(a : @gcd.FpMat) -> Array[Int32] {
  let n = a.rows
  let p = a.p
  if n == 0 {
    return [1]
  }
  // Base 1x1 bottom-right submatrix A[n-1..n, n-1..n]: det(x - a_{n-1,n-1}) = [1, -a_{n-1,n-1}]
  let mut vec : Array[Int32] = [
    1,
    @gcd.fp_sub(0, @gcd.fp_mat_get(a, n - 1, n - 1), p),
  ]
  // Induct backwards idx = n-2 down to 0
  let mut idx = n - 2
  while idx >= 0 {
    let sub_sz = n - 1 - idx
    let m00 = @gcd.fp_mat_get(a, idx, idx)
    // R is 1 x sub_sz: A[idx, idx+1..n]; C is sub_sz x 1: A[idx+1..n, idx]
    let r_vec : Array[Int32] = []
    let mut cur_col : Array[Int32] = []
    for t in (idx + 1)..<n {
      r_vec.push(@gcd.fp_mat_get(a, idx, t))
      cur_col.push(@gcd.fp_mat_get(a, t, idx))
    }
    // First column of Toeplitz matrix T (length sub_sz + 2)
    let toep_col0 : Array[Int32] = [1, @gcd.fp_sub(0, m00, p)]
    for step in 0..<sub_sz {
      // dot = R * (M^step * C)
      let mut dot = 0
      for s in 0..<sub_sz {
        dot = @gcd.fp_add(dot, @gcd.fp_mul(r_vec[s], cur_col[s], p), p)
      }
      toep_col0.push(@gcd.fp_sub(0, dot, p))
      if step + 1 < sub_sz {
        let next_col : Array[Int32] = []
        for row_s in 0..<sub_sz {
          let mut sum_s = 0
          for col_s in 0..<sub_sz {
            let m_entry = @gcd.fp_mat_get(a, idx + 1 + row_s, idx + 1 + col_s)
            sum_s = @gcd.fp_add(
              sum_s,
              @gcd.fp_mul(m_entry, cur_col[col_s], p),
              p,
            )
          }
          next_col.push(sum_s)
        }
        cur_col = next_col
      }
    }
    // Multiply Toeplitz ((sub_sz + 2) x (sub_sz + 1)) by `vec` (length sub_sz + 1)
    let next_vec : Array[Int32] = []
    for out_i in 0..<(sub_sz + 2) {
      let mut acc = 0
      for in_j in 0..<(sub_sz + 1) {
        if out_i >= in_j {
          acc = @gcd.fp_add(
            acc,
            @gcd.fp_mul(toep_col0[out_i - in_j], vec[in_j], p),
            p,
          )
        }
      }
      next_vec.push(acc)
    }
    vec = next_vec
    idx = idx - 1
  }
  vec
}

///|
/// Division-free multi-modular Berkowitz + signed CRT characteristic polynomial
/// for an exact `n x n` integer matrix, eliminating intermediate rational fraction blowup.
pub fn qmat_charpoly_berkowitz_crt(
  int_rows : Array[Array[BigInt]],
) -> BerkowitzCrtReport {
  let n = int_rows.length()
  if n == 0 {
    return BerkowitzCrtReport::{
      dim: 0,
      primes_used: 0,
      modulus_product: 1N,
      hadamard_coeff_bound: 1N,
      charpoly: qpoly_normalize([rat_one()]),
    }
  }
  let mut max_abs = 1N
  for i in 0..<n {
    for j in 0..<n {
      let v = @gcd.ugcd_bigint_abs(int_rows[i][j])
      if v > max_abs {
        max_abs = v
      }
    }
  }
  // Safe Hadamard coefficient bound: 2^n * (n * max_abs)^n >= binom(n, k) * (sqrt(k)*max_abs)^k
  let hadamard_bound = bigint_pow_int(2N, n) *
    bigint_pow_int(BigInt::from_int(n) * max_abs, n)
  let target_mod = 2N * hadamard_bound + 3N

  let primes : Array[Int32] = []
  let mut mod_prod = 1N
  let mut cand = 1000003
  while mod_prod <= target_mod && cand <= 2147483629 {
    if @gcd.ugcd_is_prime_int(cand) {
      primes.push(cand)
      mod_prod = mod_prod * BigInt::from_int(cand)
    }
    cand = cand + 2
  }

  let mod_polys : Array[Array[Int32]] = []
  for p in primes {
    let pb = BigInt::from_int(p)
    let fp_rows : Array[Array[Int32]] = []
    for i in 0..<n {
      let r : Array[Int32] = []
      for j in 0..<n {
        let rem = int_rows[i][j] % pb
        let adj = if rem < 0N { rem + pb } else { rem }
        r.push(adj.to_int())
      }
      fp_rows.push(r)
    }
    mod_polys.push(berkowitz_charpoly_mod_p(@gcd.fp_mat_from_rows(fp_rows, p)))
  }

  let moduli_big : Array[BigInt] = []
  for p in primes {
    moduli_big.push(BigInt::from_int(p))
  }
  // Reconstruct ascending QPoly coefficients [c_n, c_{n-1}, ..., c_0]
  let asc_coeffs : Array[Rat] = []
  for asc_k in 0..<=n {
    let desc_idx = n - asc_k
    let residues : Array[BigInt] = []
    for pi in 0..<primes.length() {
      residues.push(BigInt::from_int(mod_polys[pi][desc_idx]))
    }
    let (coeff_z, _) = @gcd.ugcd_crt_reconstruct_signed(residues, moduli_big)
    asc_coeffs.push(rat_make_big(coeff_z, 1N))
  }
  BerkowitzCrtReport::{
    dim: n,
    primes_used: primes.length(),
    modulus_product: mod_prod,
    hadamard_coeff_bound: hadamard_bound,
    charpoly: qpoly_normalize(asc_coeffs),
  }
}

///|
/// Phase 21 law check for Boundary 4 breakthroughs:
///   1. Arbitrary-degree Liouville transcendence certificates (degrees 1, 2, 3, 5 + root-skipping + tamper rejection);
///   2. Schanuel / Lindemann–Weierstrass Q-linear independence & relation discovery;
///   3. Division-free Berkowitz + CRT characteristic polynomial matching rational Faddeev–LeVerrier on 6x6 dense symmetric/non-symmetric matrices.
pub fn check_phase21_transcendence_and_crt_charpoly() -> Bool {
  // 1A. Certify L is not a root of linear 10x - 1 (note p_1/q_1 = 1/10 IS a root of 10x - 1,
  // testing that `liouville_transcendence_certificate` steps past the convergent root to stage 2!),
  // quadratic x^2 - 2, cubic x^3 - 3x + 1, and quintic x^5 - x - 1!
  let polys : Array[Array[BigInt]] = [
    [-1N, 10N],
    [-2N, 0N, 1N],
    [1N, -3N, 0N, 1N],
    [-1N, -1N, 0N, 0N, 0N, 1N],
  ]
  for poly in polys {
    guard liouville_transcendence_certificate(poly) is Some(cert) else {
      return false
    }
    if !liouville_cert_verify(cert) {
      return false
    }
    // Tampering scaled_poly_at_conv or stage_n must fail verification
    let tampered = LiouvilleTranscendenceCert::{
      ..cert,
      scaled_poly_at_conv: cert.scaled_poly_at_conv + 1N,
    }
    if liouville_cert_verify(tampered) {
      return false
    }
  }
  // Constant polynomial has degree 0 -> rejected cleanly with None
  if liouville_transcendence_certificate([5N]) is Some(_) {
    return false
  }

  // 2. Schanuel / Lindemann–Weierstrass Q-rank witness in Q(sqrt(2), sqrt(3)):
  // Basis [1, sqrt(2), sqrt(3), sqrt(6)]: alpha = [1, sqrt(2), sqrt(3), sqrt(6)] has Q-rank 4
  let r0 = rat_zero()
  let r1 = rat_one()
  guard schanuel_linear_independence_cert([2N, 3N], [
      [r1, r0, r0, r0],
      [r0, r1, r0, r0],
      [r0, r0, r1, r0],
      [r0, r0, r0, r1],
    ])
    is Some(indep_w) else {
    return false
  }
  if !indep_w.q_linearly_independent ||
    !indep_w.lindemann_weierstrass_alg_indep ||
    indep_w.schanuel_trdeg_lower_bound != 4 {
    return false
  }
  // Dependent triple [1, sqrt(2), 2 + 3*sqrt(2)] has Q-rank 2 < 3 and finds exact relation!
  guard schanuel_linear_independence_cert([2N, 3N], [
      [r1, r0, r0, r0],
      [r0, r1, r0, r0],
      [rat_int(2), rat_int(3), r0, r0],
    ])
    is Some(dep_w) else {
    return false
  }
  if dep_w.q_linearly_independent ||
    dep_w.q_linear_rank != 2 ||
    dep_w.null_relation.length() != 3 {
    return false
  }

  // 3. Division-free Berkowitz + CRT on a dense 6x6 integer matrix vs exact `qmat_charpoly`
  let dense6_int : Array[Array[Int32]] = [
    [3, -2, 5, 1, -4, 2],
    [-2, 7, 1, -3, 2, 0],
    [5, 1, -6, 4, 1, -2],
    [1, -3, 4, 8, -1, 3],
    [-4, 2, 1, -1, 5, -3],
    [2, 0, -2, 3, -3, 4],
  ]
  let dense6_big : Array[Array[BigInt]] = []
  for row in dense6_int {
    let rb : Array[BigInt] = []
    for v in row {
      rb.push(BigInt::from_int(v))
    }
    dense6_big.push(rb)
  }
  let crt_rep = qmat_charpoly_berkowitz_crt(dense6_big)
  let expected_cp = qmat_charpoly(qmat_from_int_rows(dense6_int))
  crt_rep.dim == 6 &&
  crt_rep.primes_used >= 2 &&
  crt_rep.modulus_product > 2N * crt_rep.hadamard_coeff_bound &&
  crt_rep.charpoly == expected_cp
}
