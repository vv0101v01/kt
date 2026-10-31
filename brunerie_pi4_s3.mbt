///|
// The fourth homotopy group of the 3-sphere: Brunerie's proof,
// formalised by Ljungstrom and Mortberg (LICS'23, arXiv:2302.00151).
//
// SPEC section 4 lists `pi_4(S^3) ~= Z/2Z` as boundary #6's hardest
// item: a porting cost of months, not an unknown.  Brunerie's 2016
// thesis gave the first synthetic HoTT proof; the LICS'23 paper gives
// a complete Cubical Agda formalisation.  This file carries the port
// as far as it honestly goes, reusing phase 18 throughout.
//
// THE SHAPE OF THE PROOF (from the paper, cited precisely).
//
//   * Brunerie's Definition 4.11 / 6: with `psi : pi_3(S^2) ~= Z` the
//     isomorphism and `[i_2, i_2]` the Whitehead product of the
//     identity of S^2 with itself, the Brunerie number is
//     `beta = psi[i_2, i_2] : Z`.
//   * Corollary 3 / 4.12: `pi_4(S^3) ~= Z/beta Z`.
//   * The map behind the Whitehead product factors as
//     `S^3 ~-> S^1 * S^1 -W-> S^2 \/ S^2`, using that the join of two
//     circles is the 3-sphere.
//   * Theorem 6.17 (new Brunerie numbers): a sequence
//     `beta_1, beta_2, beta_3 : Z` of decreasing complexity,
//         beta_1 = (xi . (F^-1)_* . F_* . (h_*)^-1) eta_1
//         beta_2 = (xi . (F^-1)_* . F_*)          eta_2
//         beta_3 = (xi . (F^-1)_*)                eta_3
//     and if *any* of them normalises to +-2 then
//     `pi_4(S^3) ~= Z/2Z`.
//   * An optimised `beta_3` normalises to `-2` in Cubical Agda in just
//     under 4 seconds.  `beta_1` and `beta_2` are far simpler than the
//     original but still do not normalise in reasonable time, and the
//     original `beta` still cannot be computed at all.
//
// WHAT IS PROVED HERE (executable, tested by `check_brunerie_pi4_s3`).
//
//   * Join arithmetic: `S^m * S^n ~= S^(m+n+1)`, hence `S^1 * S^1 ~= S^3`.
//     This is the dimension bookkeeping of the construction above and
//     it is integer arithmetic.
//   * The Whitehead product degree: `[alpha, beta] : pi_{p+q-1}` for
//     `alpha : pi_p`, `beta : pi_q`.  With `i_2 : pi_2(S^2)` this puts
//     `[i_2, i_2]` in `pi_3(S^2)` -- and `pi_3(S^2) ~= Z` was
//     established in phase 18, so `psi` is well typed.  The two phases
//     agree.
//   * The cellular structure of the James construction: `J(S^n)` has
//     exactly one cell in each dimension `0, n, 2n, 3n, ...`.
//   * `pi_4(S^3) ~= pi_4(S^2)`, by the Hopf fibration's long exact
//     sequence at `k = 4` (reusing `hopf_les_iso` from phase 18).
//   * The cyclic group arithmetic `Z / beta Z`, including the
//     degenerate cases: `Z/0 = Z` and `Z/+-1 = 0`.
//   * The decision rule of Theorem 6.17: a normalisation result `n`
//     establishes `pi_4(S^3) ~= Z/2Z` exactly when `|n| = 2`.
//   * Monotonicity of the new Brunerie numbers' complexity.
//
// WHAT IS IMPORTED.
//   The James construction and Whitehead products themselves (needed
//   to *define* beta), the isomorphism `pi_4(S^3) ~= Z/beta Z`, and the
//   normalisation of `beta_3` to `-2`.  The last of these is a
//   computation that runs in Cubical Agda in about 4 seconds; it is not
//   reproduced here, and this file says so rather than pretending to
//   have run it.
//
// MEASURED THRESHOLDS (from the paper, as the boundary's numbers).
//   Brunerie's original proof:          ~9,000 LOC; `beta` does not normalise.
//   Direct calculation of `beta`:         ~600 LOC.
//   Optimised `beta_3`:                 normalises to -2 in < 4 s.
//   `beta_1`, `beta_2`:                 simplified, but do not normalise.

///|
/// What a Brunerie number does under normalisation.
pub enum BrunerieNorm {
  /// Normalises to the given integer.
  NormalisesTo(Int32)
  /// Simplified, but does not normalise in reasonable time.
  DoesNotNormalise
  /// Never successfully normalised.
  NeverNormalised
} derive(Debug, Eq)

///|
pub extend BrunerieNorm with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BrunerieNorm with Eq::{equal, not_equal}

///|
/// One Brunerie number: an integer `n` with `pi_4(S^3) ~= Z/n Z`.
/// `complexity` counts the maps composed to produce it, which is the
/// sense in which `beta_1, beta_2, beta_3` have decreasing complexity.
pub struct BrunerieNumber {
  name : String
  complexity : Int32
  norm : BrunerieNorm
} derive(Debug, Eq)

///|
pub extend BrunerieNumber with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BrunerieNumber with Eq::{equal, not_equal}

// ---------------------------------------------------------------------------
// Joins of spheres
// ---------------------------------------------------------------------------

///|
/// `S^m * S^n ~= S^(m+n+1)`.  The join of two spheres is a sphere one
/// dimension higher than the sum.
pub fn join_sphere_dim(m : Int32, n : Int32) -> Int32 {
  m + n + 1
}

///|
/// The instance Brunerie's construction uses: the join of two circles
/// is the 3-sphere.
pub fn s3_is_join_of_two_circles() -> Bool {
  join_sphere_dim(1, 1) == 3
}

// ---------------------------------------------------------------------------
// Whitehead products
// ---------------------------------------------------------------------------

///|
/// For `alpha : pi_p(X)` and `beta : pi_q(X)` the Whitehead product
/// `[alpha, beta]` lives in `pi_{p+q-1}(X)`.
pub fn whitehead_degree(p : Int32, q : Int32) -> Int32 {
  p + q - 1
}

///|
/// `[i_2, i_2]`, with `i_2 : pi_2(S^2)`, lands in `pi_3(S^2)`.  This is
/// the element `psi` is applied to in `beta = psi[i_2, i_2]`.
pub fn brunerie_whitehead_lives_in() -> Int32 {
  whitehead_degree(2, 2)
}

// ---------------------------------------------------------------------------
// The James construction
// ---------------------------------------------------------------------------

///|
/// `J(S^n)` has exactly one cell in each dimension `0, n, 2n, 3n, ...`.
pub fn james_cells(sphere_dim : Int32, max_dim : Int32) -> Array[Int32] {
  let out : Array[Int32] = [0]
  if sphere_dim <= 0 {
    return out
  }
  let mut k = sphere_dim
  while k <= max_dim {
    out.push(k)
    k = k + sphere_dim
  }
  out
}

// ---------------------------------------------------------------------------
// The Brunerie numbers
// ---------------------------------------------------------------------------

///|
/// The original Brunerie number `beta = psi[i_2, i_2]`.  Never
/// normalised: this is the whole difficulty, and after the LICS'23 work
/// it remains open whether Brunerie's own definition can be computed.
pub fn brunerie_original() -> BrunerieNumber {
  { name: "β", complexity: 0, norm: NeverNormalised, }
}

///|
/// The three new Brunerie numbers of Theorem 6.17, of decreasing
/// complexity:
///   beta_1 = (xi . (F^-1)_* . F_* . (h_*)^-1) eta_1   -- 4 maps
///   beta_2 = (xi . (F^-1)_* . F_*)          eta_2     -- 3 maps
///   beta_3 = (xi . (F^-1)_*)                eta_3     -- 2 maps
/// Only the optimised `beta_3` normalises, to -2.
pub fn brunerie_new_family() -> Array[BrunerieNumber] {
  [
    { name: "β₁", complexity: 4, norm: DoesNotNormalise, },
    { name: "β₂", complexity: 3, norm: DoesNotNormalise, },
    { name: "β₃", complexity: 2, norm: NormalisesTo(-2), },
  ]
}

///|
/// Theorem 6.17's decision rule: a normalisation result `n` establishes
/// `pi_4(S^3) ~= Z/2Z` exactly when `|n| = 2`.
pub fn brunerie_norm_establishes(n : Int32) -> Bool {
  n == 2 || n == -2
}

///|
/// Among a family, whether some member's normalisation establishes the
/// result -- and the value that does it.
pub fn brunerie_family_establishes(
  fam : Array[BrunerieNumber],
) -> (Bool, Int32) {
  let mut found = false
  let mut value = 0
  for i in 0..<fam.length() {
    match fam[i].norm {
      NormalisesTo(n) =>
        if brunerie_norm_establishes(n) {
          found = true
          value = n
        }
      DoesNotNormalise | NeverNormalised => ()
    }
  }
  (found, value)
}

///|
/// Complexity is strictly decreasing along the new family.
pub fn brunerie_family_decreasing(fam : Array[BrunerieNumber]) -> Bool {
  let mut i = 1
  while i < fam.length() {
    if fam[i].complexity >= fam[i - 1].complexity {
      return false
    }
    i = i + 1
  }
  true
}

// ---------------------------------------------------------------------------
// The group arithmetic
// ---------------------------------------------------------------------------

///|
/// `Z / beta Z`.  Degenerate cases matter and are handled explicitly:
/// `Z / 0 = Z` (the quotient by the zero subgroup), `Z / +-1 = 0`, and
/// `Z / -beta = Z / beta`.
pub fn cyclic_of_beta(beta : Int32) -> FgAb {
  let n = if beta < 0 { -beta } else { beta }
  if n == 0 {
    fg_z()
  } else if n == 1 {
    fg_zero()
  } else {
    fg_zmod(n)
  }
}

///|
/// `pi_4(S^3) ~= pi_4(S^2)`, by the Hopf fibration's long exact
/// sequence at `k = 4`: both neighbours `pi_4(S^1)` and `pi_3(S^1)`
/// vanish.  This reuses phase 18's `hopf_les_iso`.
pub fn pi4_s3_iso_pi4_s2() -> Bool {
  hopf_les_iso(4)
}

///|
/// The group `pi_4(S^3)`, from the normalised Brunerie number.
pub fn pi4_s3_group(beta : Int32) -> FgAb {
  cyclic_of_beta(beta)
}

// ---------------------------------------------------------------------------
// Provenance
// ---------------------------------------------------------------------------

///|
pub fn pi4_s3_origins() -> Array[Origin] {
  [
    Proved("join_sphere_dim：S^m * S^n ≃ S^(m+n+1)，故 S¹ * S¹ ≃ S³"),
    Proved(
      "whitehead_degree：[α,β] ∈ π_{p+q−1}，故 [i₂,i₂] ∈ π₃(S²)",
    ),
    Prior(
      "第十八期：π₃(S²) ≃ π₃(S³) ≃ ℤ，故 ψ : π₃(S²) ≃ ℤ 類型正確",
    ),
    Proved(
      "pi4_s3_iso_pi4_s2：Hopf LES 在 k=4（複用第十八期 hopf_les_iso）",
    ),
    Proved(
      "cyclic_of_beta：ℤ/βℤ 的循環群算術，含 β=0 與 |β|=1 退化情形",
    ),
    Proved("brunerie_norm_establishes：定理 6.17 的判準 |n| = 2"),
    Imported(
      "Brunerie 定義 4.11：β = ψ[i₂,i₂]，涉及 James 構造與 Whitehead 積",
    ),
    Imported("Brunerie 推論 4.12：π₄(S³) ≃ ℤ/βℤ"),
    Imported(
      "定理 6.17：β₁,β₂,β₃ 任一 normalize 至 ±2 即給出 π₄(S³) ≃ ℤ/2ℤ",
    ),
    Imported(
      "LICS'23：優化版 β₃ 在 Cubical Agda 約 4 秒 normalize 至 −2（本庫未重跑）",
    ),
  ]
}

///|
fn is_norm_to(n : BrunerieNorm, k : Int32) -> Bool {
  match n {
    NormalisesTo(v) => v == k
    _ => false
  }
}

///|
fn count_imported(o : Array[Origin]) -> Int32 {
  let mut c = 0
  for i in 0..<o.length() {
    match o[i] {
      Imported(_) => c = c + 1
      _ => ()
    }
  }
  c
}

///|
fn count_proved(o : Array[Origin]) -> Int32 {
  let mut c = 0
  for i in 0..<o.length() {
    match o[i] {
      Proved(_) => c = c + 1
      _ => ()
    }
  }
  c
}

// ---------------------------------------------------------------------------
// Law
// ---------------------------------------------------------------------------

///|
/// `pi_4(S^3) ~= Z/2Z` (phase 19).  The combinatorial, degree and group
/// arithmetic is proved here and reuses phase 18; the James
/// construction, the Whitehead product, the isomorphism
/// `pi_4(S^3) ~= Z/beta Z` and the normalisation of `beta_3` are
/// imported and counted explicitly, so the provenance split is part of
/// the answer rather than a remark in a comment.
pub fn check_brunerie_pi4_s3() -> Bool {
  // (1) Joins of spheres.
  let join_ok = s3_is_join_of_two_circles() &&
    join_sphere_dim(0, 1) == 2 &&
    join_sphere_dim(2, 2) == 5 &&
    join_sphere_dim(1, 3) == 5

  // (2) Whitehead products: [i_2, i_2] lives in pi_3(S^2), which phase
  //     18 established is Z -- so psi is well typed there.
  let wh_ok = brunerie_whitehead_lives_in() == 3 &&
    whitehead_degree(2, 3) == 4 &&
    whitehead_degree(1, 1) == 1 &&
    hopf_les_iso(3)

  // (3) The James construction's cells: one in each of 0, n, 2n, ...
  let j2 = james_cells(2, 9)
  let j3 = james_cells(3, 10)
  let james_ok = j2.length() == 5 &&
    j2[0] == 0 &&
    j2[1] == 2 &&
    j2[2] == 4 &&
    j2[3] == 6 &&
    j2[4] == 8 &&
    j3.length() == 4 &&
    j3[1] == 3 &&
    j3[2] == 6 &&
    j3[3] == 9 &&
    james_cells(1, 4).length() == 5

  // (4) The group arithmetic Z / beta Z, including degeneracies.
  let cyc_ok = cyclic_of_beta(-2) == fg_zmod(2) &&
    cyclic_of_beta(2) == fg_zmod(2) &&
    cyclic_of_beta(3) == fg_zmod(3) &&
    cyclic_of_beta(-3) == fg_zmod(3) &&
    cyclic_of_beta(1) == fg_zero() &&
    cyclic_of_beta(-1) == fg_zero() &&
    cyclic_of_beta(0) == fg_z() &&
    !fg_is_trivial(cyclic_of_beta(-2))

  // (5) The decision rule: |n| = 2, nothing else.
  let rule_ok = brunerie_norm_establishes(-2) &&
    brunerie_norm_establishes(2) &&
    !brunerie_norm_establishes(-3) &&
    !brunerie_norm_establishes(0) &&
    !brunerie_norm_establishes(1) &&
    !brunerie_norm_establishes(4)

  // (6) The new family: decreasing complexity, and exactly one member
  //     normalises -- to -2.
  let fam = brunerie_new_family()
  let (est, val) = brunerie_family_establishes(fam)
  let fam_ok = fam.length() == 3 &&
    brunerie_family_decreasing(fam) &&
    fam[0].complexity == 4 &&
    fam[1].complexity == 3 &&
    fam[2].complexity == 2 &&
    is_norm_to(fam[2].norm, -2) &&
    est &&
    val == -2

  // (7) The original beta never normalised; that has to stay visible
  //     rather than being quietly replaced by the family.
  let orig = brunerie_original()
  let orig_ok = !brunerie_family_establishes([orig]).0 &&
    brunerie_family_establishes([orig]).1 == 0

  // (8) pi_4(S^3) ~= pi_4(S^2) via the Hopf LES at k = 4.
  let les_ok = pi4_s3_iso_pi4_s2()

  // (9) The result itself.
  let group = pi4_s3_group(val)
  let result_ok = group == fg_zmod(2)

  // (10) Provenance is part of the answer: the imported ingredients
  //      must be counted and must not be zero.
  let origins = pi4_s3_origins()
  let prov_ok = count_imported(origins) == 4 &&
    count_proved(origins) == 5 &&
    origins.length() == 10

  join_ok &&
  wh_ok &&
  james_ok &&
  cyc_ok &&
  rule_ok &&
  fam_ok &&
  orig_ok &&
  les_ok &&
  result_ok &&
  prov_ok
}
