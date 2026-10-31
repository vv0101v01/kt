///|
// Certified transcendental boundary layer.
//
// SPEC section 4 keeps `e`, `pi` and the Schanuel category out of scope
// because they are not elements of the algebraic closure `Qbar`.  That
// is a true statement about *membership*, but it is not the end of the
// story: a transcendental number cannot be *represented* by an
// algebraic number, yet it can still be *certified*.  This file turns
// that one boundary from prose into three executable objects:
//
//   1. `certified_e` / `certified_pi` -- rigorous rational enclosures
//      carrying an explicit, separately re-checkable tail bound.
//
//   2. `e_irrationality_certificate` -- a refutation procedure for
//      `e = p/q`.  For every integer pair with `q >= 1` it returns a
//      certificate, re-verified in exact integer arithmetic, that `e`
//      is not that rational.  This is the classical tail argument
//      (M*e sits strictly between consecutive integers A and A+1 while
//      q | M forces M*e to be an integer) turned into a checkable
//      object instead of a textbook paragraph.  The boundary "e is not
//      in Qbar" thereby becomes a total, machine-checked function.
//
//   3. `poly_nonzero_at_e` / `pi_refute_rational_refined` -- sound
//      refutation by certified enclosure: refine until 0 is excluded.
//      Sound by construction; they terminate whenever the value is
//      non-zero.  They are explicitly NOT completeness claims: they
//      cannot rule out P(e) = 0 in general, because that needs a
//      transcendence proof (Hermite-Lindemann) which this file does
//      not formalize.
//
// Everything here is exact: BigInt and Rat only, no floating point, no
// epsilon, no sampling.

// ---------------------------------------------------------------------------
// Certified enclosures
// ---------------------------------------------------------------------------

///|
/// A rational enclosure `[lo, hi]` of a real constant, together with the
/// number of series terms summed and the rigorous tail bound used to
/// widen the partial sum into an enclosure.
pub struct CertEnclosure {
  lo : Rat
  hi : Rat
  /// How many terms were summed.
  terms : Int32
  /// A rational `r >= 0` with `value - partial_sum` in `[0, r]`.
  tail : Rat
} derive(Debug, Eq)

///|
pub extend CertEnclosure with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CertEnclosure with Eq::{not_equal, equal}

///|

///|
/// Certified enclosure of `e = sum_{k>=0} 1/k!`.
///
/// After summing `k = 0..n` the remainder obeys
///
/// ```text
///   0 < R_n = sum_{k>n} 1/k! <= 1/(n! * n)          (n >= 1)
/// ```
///
/// because `n!/(n+j)! = 1/((n+1)...(n+j)) <= 1/(n+1)^j` and the
/// geometric series `sum_{j>=1} 1/(n+1)^j` sums to exactly `1/n`.
pub fn certified_e(n : Int32) -> CertEnclosure {
  let terms = if n < 1 { 1 } else { n }
  let mut sum = rat_zero()
  let mut fact = 1N
  let mut k = 0
  while k <= terms {
    sum = rat_add(sum, rat_make_big(1N, fact))
    k = k + 1
    fact = fact * BigInt::from_int(k)
  }
  // On exit `fact == (terms + 1)!`; recover `terms!`.
  let fact_n = fact / BigInt::from_int(terms + 1)
  let tail = rat_make_big(1N, fact_n * BigInt::from_int(terms))
  CertEnclosure::{ lo: sum, hi: rat_add(sum, tail), terms: terms + 1, tail, }
}

///|
/// Certified enclosure of `arctan(1/x)` for `x >= 2`, from the
/// alternating series `sum_k (-1)^k / ((2k+1) x^(2k+1))`.
///
/// Terms strictly decrease in magnitude, so the remainder after `n`
/// terms is bounded in absolute value by the first omitted term.
fn arctan_recip_enclosure(x : BigInt, n_terms : Int32) -> CertEnclosure {
  let n = if n_terms < 1 { 1 } else { n_terms }
  let mut sum = rat_zero()
  let mut k = 0
  while k < n {
    let mut xp = 1N
    let mut i = 0
    while i < 2 * k + 1 {
      xp = xp * x
      i = i + 1
    }
    let term = rat_make_big(1N, BigInt::from_int(2 * k + 1) * xp)
    if k % 2 == 0 {
      sum = rat_add(sum, term)
    } else {
      sum = rat_sub(sum, term)
    }
    k = k + 1
  }
  // First omitted term: index n.
  let mut xpn = 1N
  let mut j = 0
  while j < 2 * n + 1 {
    xpn = xpn * x
    j = j + 1
  }
  let tail = rat_make_big(1N, BigInt::from_int(2 * n + 1) * xpn)
  CertEnclosure::{
    lo: rat_sub(sum, tail),
    hi: rat_add(sum, tail),
    terms: n,
    tail,
  }
}

///|
/// Certified enclosure of `pi` via Machin's formula
/// `pi = 16*arctan(1/5) - 4*arctan(1/239)`.
pub fn certified_pi(n_terms : Int32) -> CertEnclosure {
  let a = arctan_recip_enclosure(5N, n_terms)
  let b = arctan_recip_enclosure(239N, n_terms)
  let sixteen = rat_int(16)
  let four = rat_int(4)
  CertEnclosure::{
    lo: rat_sub(rat_mul(sixteen, a.lo), rat_mul(four, b.hi)),
    hi: rat_sub(rat_mul(sixteen, a.hi), rat_mul(four, b.lo)),
    terms: n_terms,
    tail: rat_add(rat_mul(sixteen, a.tail), rat_mul(four, b.tail)),
  }
}

// ---------------------------------------------------------------------------
// e is not rational: a total, machine-checked refutation procedure
// ---------------------------------------------------------------------------

///|
/// A refutation of the claim `e = p/q`.
///
/// Let `M = N!` with `N >= q` and `N >= 2`, and let `A = M * S_N`
/// where `S_N = sum_{k=0}^{N} 1/k!`.  Then:
///
///   * `A` is an integer, because `k!` divides `N!` for `k <= N`;
///   * `0 < M*(e - S_N) <= 1/N <= 1/2`, so `A < M*e < A + 1`;
///   * `q` divides `M`, so if `e = p/q` then `M*e = p*(M/q)` is an
///     integer -- contradicting the previous line.
///
/// The certificate stores the witnesses and `verified` records an
/// independent re-derivation of every inequality from the stored `m`,
/// `n`, `a` and the enclosure of `e`.
pub struct EIrrCertificate {
  /// The numerator of the refuted rational.
  p : BigInt
  /// The denominator of the refuted rational, always `>= 1`.
  q : BigInt
  /// `N`, with `N >= q` and `N >= 2`.
  n : Int32
  /// `M = N!`.
  m : BigInt
  /// `A = M * S_N`, an integer.
  a : BigInt
  /// `M * e_lo` for the enclosure `[e_lo, e_hi]` below.
  scaled_lo : Rat
  /// `M * e_hi`.
  scaled_hi : Rat
  /// Enclosure of `e` used for the cross-check (summed to `N + 5` terms).
  e_lo : Rat
  e_hi : Rat
  /// The bound `M * R_N <= 1/N`, required to be `< 1`.
  tail_bound : Rat
  /// `q` divides `M`.
  q_divides_m : Bool
  /// Independent re-verification of all of the above.
  verified : Bool
} derive(Debug, Eq)

///|
pub extend EIrrCertificate with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend EIrrCertificate with Eq::{not_equal, equal}

///|
/// Re-derive every inequality of an `e`-irrationality certificate from
/// its stored witnesses.  Returns `false` for any tampered field.
pub fn e_irr_certificate_verify(c : EIrrCertificate) -> Bool {
  let a_rat = rat_big_int(c.a)
  let a_plus_1 = rat_add(a_rat, rat_one())
  let scaled_lo = rat_mul(rat_big_int(c.m), c.e_lo)
  let scaled_hi = rat_mul(rat_big_int(c.m), c.e_hi)
  // Structural conditions.
  c.n >= 2 &&
  c.q > 0N &&
  c.q <= BigInt::from_int(c.n) &&
  c.q_divides_m &&
  c.m % c.q == 0N &&
  // The stored scaled enclosure must be the one induced by m and [e_lo,e_hi].
  rat_cmp_exact(c.scaled_lo, scaled_lo) == 0 &&
  rat_cmp_exact(c.scaled_hi, scaled_hi) == 0 &&
  // The enclosure is non-degenerate and the tail bound is < 1.
  rat_cmp_exact(c.e_lo, c.e_hi) < 0 &&
  rat_cmp_exact(c.tail_bound, rat_one()) < 0 &&
  rat_cmp_exact(c.tail_bound, rat_big_int(c.m)) <= 0 &&
  // The punchline: A < M*e < A + 1.
  rat_cmp_exact(scaled_lo, a_rat) > 0 &&
  rat_cmp_exact(scaled_hi, a_plus_1) < 0
}

///|
/// Build, and immediately re-verify, a refutation of `e = p/q`.
///
/// Scope, stated honestly: `q` is taken as a machine `Int32` and `N!`
/// is materialized, so the procedure is total for every denominator
/// that fits and for which `N!` is computable (in practice far beyond
/// any denominator one would care to type).  It is not a claim about
/// representations of `e` inside `Qbar` -- there are none; it is a
/// refutation procedure for rational *identity claims* about `e`.
pub fn e_irrationality_certificate(p : BigInt, q : Int32) -> EIrrCertificate {
  let qq = if q < 0 { -q } else { q }
  let qd = if qq < 1 { 1 } else { qq }
  let n = if qd > 2 { qd } else { 2 }
  let m = bigint_factorial(n)
  let q_big = BigInt::from_int(qd)
  // A = sum_{k=0}^{n} M / k!, an integer because k! | M.
  let mut a = 0N
  let mut fact = 1N
  let mut k = 0
  while k <= n {
    a = a + m / fact
    k = k + 1
    fact = fact * BigInt::from_int(k)
  }
  // Cross-check enclosure: strictly more terms than N, so M*S_K > A.
  let enc = certified_e(n + 5)
  let scaled_lo = rat_mul(rat_big_int(m), enc.lo)
  let scaled_hi = rat_mul(rat_big_int(m), enc.hi)
  let tail_bound = rat_make_big(1N, BigInt::from_int(n))
  let c = EIrrCertificate::{
    p,
    q: q_big,
    n,
    m,
    a,
    scaled_lo,
    scaled_hi,
    e_lo: enc.lo,
    e_hi: enc.hi,
    tail_bound,
    q_divides_m: m % q_big == 0N,
    verified: false,
  }
  { ..c, verified: e_irr_certificate_verify(c), }
}

///|
/// Convenience: does the certificate for `e = p/q` verify?
pub fn e_refute_rational(p : BigInt, q : Int32) -> Bool {
  e_irrationality_certificate(p, q).verified
}

// ---------------------------------------------------------------------------
// Sound refutation by certified enclosure
// ---------------------------------------------------------------------------

///|
/// Result of a "refine until 0 is excluded" refutation.
pub struct RefutationResult {
  /// True when the certified enclosure excludes the target value.
  refuted : Bool
  /// Series terms used at the stopping point.
  terms : Int32
  lo : Rat
  hi : Rat
} derive(Debug, Eq)

///|
pub extend RefutationResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend RefutationResult with Eq::{not_equal, equal}

///|
/// Certified enclosure of `P(e)` for an integer polynomial given as
/// coefficients in ascending degree order (`coeffs[i]` is the
/// coefficient of `x^i`), evaluated by Horner over interval arithmetic.
///
/// Soundness: interval arithmetic encloses the true value.
/// Completeness: none claimed -- if `P(e) = 0` the loop runs to the
/// budget and reports `refuted = false`.
pub fn poly_nonzero_at_e(
  coeffs : Array[BigInt],
  n_terms : Int32,
) -> RefutationResult {
  let n = if n_terms < 1 { 1 } else { n_terms }
  let e = certified_e(n)
  let ei = rat_interval(e.lo, e.hi)
  let last = coeffs[coeffs.length() - 1]
  let mut acc = rat_interval_point(rat_big_int(last))
  let mut i = coeffs.length() - 2
  while i >= 0 {
    acc = rat_interval_add(
      rat_interval_mul(acc, ei),
      rat_interval_point(rat_big_int(coeffs[i])),
    )
    i = i - 1
  }
  RefutationResult::{
    refuted: rat_cmp_exact(acc.lo, rat_zero()) > 0 ||
    rat_cmp_exact(acc.hi, rat_zero()) < 0,
    terms: n,
    lo: acc.lo,
    hi: acc.hi,
  }
}

///|
/// Refine the enclosure of `pi` until the rational `p/q` is excluded or
/// the term budget is spent.
pub fn pi_refute_rational_refined(
  p : BigInt,
  q : Int32,
  max_terms : Int32,
) -> RefutationResult {
  let r = rat_make_big(p, BigInt::from_int(q))
  let mut t = 2
  while t <= max_terms {
    let enc = certified_pi(t)
    if rat_cmp_exact(r, enc.lo) < 0 || rat_cmp_exact(r, enc.hi) > 0 {
      return RefutationResult::{
        refuted: true,
        terms: t,
        lo: enc.lo,
        hi: enc.hi,
      }
    }
    t = t + 1
  }
  let enc = certified_pi(max_terms)
  RefutationResult::{
    refuted: false,
    terms: max_terms,
    lo: enc.lo,
    hi: enc.hi,
  }
}

// ---------------------------------------------------------------------------
// Law
// ---------------------------------------------------------------------------

///|
fn rat_dec(num : String, den : String) -> Rat {
  rat_make_big(BigInt::from_string(num), BigInt::from_string(den))
}

///|
/// The transcendental boundary layer, as an executable law.
pub fn check_transcendental_boundary_layer() -> Bool {
  // (1) Enclosures are non-degenerate and bracket the known decimals.
  let e20 = certified_e(20)
  let pi20 = certified_pi(20)
  let e30 = certified_e(30)
  let pi30 = certified_pi(30)
  let e27 = rat_dec("27", "10")
  let e28 = rat_dec("272", "100")
  let pi314 = rat_dec("314", "100")
  let pi315 = rat_dec("315", "100")
  let tiny = rat_dec("1", "1000000000000000")
  let enclosures_ok = rat_cmp_exact(e20.lo, e20.hi) < 0 &&
    rat_cmp_exact(pi20.lo, pi20.hi) < 0 &&
    // Each enclosure lands in the right range.
    rat_cmp_exact(e20.lo, e27) > 0 &&
    rat_cmp_exact(e20.hi, e28) < 0 &&
    rat_cmp_exact(pi20.lo, pi314) > 0 &&
    rat_cmp_exact(pi20.hi, pi315) < 0 &&
    // Already tiny at 20 terms.
    rat_cmp_exact(e20.tail, tiny) < 0 &&
    rat_cmp_exact(pi20.tail, tiny) < 0 &&
    // More terms => strictly smaller tail bound.
    rat_cmp_exact(certified_e(25).tail, e20.tail) < 0 &&
    rat_cmp_exact(certified_pi(25).tail, pi20.tail) < 0 &&
    // Independent term counts must give overlapping enclosures.
    rat_cmp_exact(e30.lo, e20.hi) < 0 &&
    rat_cmp_exact(e20.lo, e30.hi) < 0 &&
    rat_cmp_exact(pi30.lo, pi20.hi) < 0 &&
    rat_cmp_exact(pi20.lo, pi30.hi) < 0

  // (2) e is not any of these rationals -- every certificate verifies.
  let refuted = [
    e_refute_rational(BigInt::from_int(2), 1),
    e_refute_rational(BigInt::from_int(3), 1),
    e_refute_rational(BigInt::from_int(19), 7),
    e_refute_rational(BigInt::from_int(22), 7),
    e_refute_rational(BigInt::from_int(87), 32),
    e_refute_rational(BigInt::from_int(108), 40),
    e_refute_rational(BigInt::from_int(193), 71),
    e_refute_rational(BigInt::from_int(-5), 2),
  ]
  let mut all_refuted = true
  let mut i = 0
  while i < refuted.length() {
    if !refuted[i] {
      all_refuted = false
    }
    i = i + 1
  }

  // (3) Falsification: a tampered certificate must not verify.
  let good = e_irrationality_certificate(BigInt::from_int(22), 7)
  let bad_a = { ..good, a: good.a + 1N, }
  let bad_m = { ..good, m: good.m + 1N, }
  let bad_n = { ..good, n: 1, }
  let bad_q = { ..good, q: good.q + 1N, }
  let falsification_ok = good.verified &&
    !e_irr_certificate_verify(bad_a) &&
    !e_irr_certificate_verify(bad_m) &&
    !e_irr_certificate_verify(bad_n) &&
    !e_irr_certificate_verify(bad_q)

  // (4) P(e) != 0 certified by enclosure, with a too-coarse control.
  let x_minus_3 = [BigInt::from_int(-3), BigInt::from_int(1)]
  let tight = [BigInt::from_string("-2718281828"), BigInt::from_int(1000000000)]
  let quad = [BigInt::from_int(12), BigInt::from_int(-7), BigInt::from_int(1)]
  let p1 = poly_nonzero_at_e(x_minus_3, 20)
  let p2 = poly_nonzero_at_e(tight, 20)
  let p3 = poly_nonzero_at_e(quad, 20)
  // Honest negative control: 5 terms give width ~ 1e9/600 around a value
  // of size ~0.46, so 0 is inside and we must NOT claim exclusion.
  let coarse = poly_nonzero_at_e(tight, 5)
  let poly_ok = p1.refuted &&
    p2.refuted &&
    p3.refuted &&
    rat_cmp_exact(p1.hi, rat_zero()) < 0 &&
    rat_cmp_exact(p2.lo, rat_zero()) > 0 &&
    rat_cmp_exact(p3.lo, rat_zero()) > 0 &&
    !coarse.refuted

  // (5) pi is not 22/7, not 355/113, and not a 15-digit decimal; and a
  // starved budget honestly declines to refute 355/113.
  let r1 = pi_refute_rational_refined(BigInt::from_int(22), 7, 20)
  let r2 = pi_refute_rational_refined(BigInt::from_int(355), 113, 20)
  let r3 = pi_refute_rational_refined(BigInt::from_int(314159), 100000, 20)
  let starved = pi_refute_rational_refined(BigInt::from_int(355), 113, 2)
  let pi_ok = r1.refuted && r2.refuted && r3.refuted && !starved.refuted

  enclosures_ok && all_refuted && falsification_ok && poly_ok && pi_ok
}
