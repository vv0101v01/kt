///|
/// SWAR 64-bit Truth-Word Fast-Path (`n <= 6`), Kalman Dual-Rail Free De Morgan
/// Interval Semantics (`I_DM`), and Free CCHM Cofibration Lattice (`Cofib(n)`).

///|
fn swar6_var_mask(k : Int32) -> UInt64 {
  match k {
    0 => 0xAAAAAAAAAAAAAAAAUL
    1 => 0xCCCCCCCCCCCCCCCCUL
    2 => 0xF0F0F0F0F0F0F0F0UL
    3 => 0xFF00FF00FF00FF00UL
    4 => 0xFFFF0000FFFF0000UL
    5 => 0xFFFFFFFF00000000UL
    _ => 0UL
  }
}

///|
fn swar6_domain_mask(n : Int32) -> UInt64 {
  if n <= 0 {
    1UL
  } else if n >= 6 {
    0xFFFFFFFFFFFFFFFFUL
  } else {
    let bits = 1 << n
    (1UL << bits) - 1UL
  }
}

///|
/// Pure register `UInt64` evaluation of `r` over `{0, 1}^6` (variables outside `[0, n)` evaluate to `0`).
pub fn dim_truth_u64(r : Dim, n : Int32) -> UInt64 {
  match r {
    DZero => 0UL
    DOne => 0xFFFFFFFFFFFFFFFFUL
    DVar(i) => if i >= 0 && i < n && i < 6 { swar6_var_mask(i) } else { 0UL }
    DNeg(a) => dim_truth_u64(a, n) ^ 0xFFFFFFFFFFFFFFFFUL
    DAnd(a, b) => dim_truth_u64(a, n) & dim_truth_u64(b, n)
    DOr(a, b) => dim_truth_u64(a, n) | dim_truth_u64(b, n)
  }
}

///|
/// Pure register `UInt64` evaluation of `f` over `{0, 1}^6` (variables outside `[0, n)` evaluate to `0`).
pub fn face_truth_u64(f : Face, n : Int32) -> UInt64 {
  match f {
    FTop => 0xFFFFFFFFFFFFFFFFUL
    FBot => 0UL
    FEq0(r) => dim_truth_u64(r, n) ^ 0xFFFFFFFFFFFFFFFFUL
    FEq1(r) => dim_truth_u64(r, n)
    FAnd(a, b) => face_truth_u64(a, n) & face_truth_u64(b, n)
    FOr(a, b) => face_truth_u64(a, n) | face_truth_u64(b, n)
  }
}

///|
fn dim_max_var_plus1(r : Dim) -> Int32 {
  match r {
    DZero | DOne => 0
    DVar(i) => if i >= 0 { i + 1 } else { 0 }
    DNeg(a) => dim_max_var_plus1(a)
    DAnd(a, b) | DOr(a, b) => {
      let ma = dim_max_var_plus1(a)
      let mb = dim_max_var_plus1(b)
      if ma > mb {
        ma
      } else {
        mb
      }
    }
  }
}

///|
fn face_max_var_plus1(f : Face) -> Int32 {
  match f {
    FTop | FBot => 0
    FEq0(r) | FEq1(r) => dim_max_var_plus1(r)
    FAnd(a, b) | FOr(a, b) => {
      let ma = face_max_var_plus1(a)
      let mb = face_max_var_plus1(b)
      if ma > mb {
        ma
      } else {
        mb
      }
    }
  }
}

///|
/// Linear-time `O(|r|)` zero-allocation Kleene/Belnap dual-rail evaluation at
/// all-top `(x⁺=1, x⁻=1)` and all-bottom `(x⁺=0, x⁻=0)`:
/// returns `(val_under_all_1, val_under_all_0)` in Negation Normal Form.
/// By Kalman's representation theorem for free De Morgan algebras:
/// - `r ≡ 0` in `I_DM` iff `val_under_all_1 == false` (since `0` is meet-prime at `(½,...,½)`),
/// - `r ≡ 1` in `I_DM` iff `val_under_all_0 == true`.
fn dim_demorgan_endpoint_rails(r : Dim, negated : Bool) -> (Bool, Bool) {
  match r {
    DZero => if negated { (true, true) } else { (false, false) }
    DOne => if negated { (false, false) } else { (true, true) }
    DVar(i) =>
      if i < 0 {
        if negated {
          (true, true)
        } else {
          (false, false)
        }
      } else {
        // Both positive literal `x_i⁺` and negative literal `x_i⁻` evaluate to `true`
        // under all-1 (`⊤_4`) and `false` under all-0 (`⊥_4`).
        (true, false)
      }
    DNeg(a) => dim_demorgan_endpoint_rails(a, !negated)
    DAnd(a, b) =>
      if !negated {
        let (a1, a0) = dim_demorgan_endpoint_rails(a, false)
        let (b1, b0) = dim_demorgan_endpoint_rails(b, false)
        (a1 && b1, a0 && b0)
      } else {
        let (a1, a0) = dim_demorgan_endpoint_rails(a, true)
        let (b1, b0) = dim_demorgan_endpoint_rails(b, true)
        (a1 || b1, a0 || b0)
      }
    DOr(a, b) =>
      if !negated {
        let (a1, a0) = dim_demorgan_endpoint_rails(a, false)
        let (b1, b0) = dim_demorgan_endpoint_rails(b, false)
        (a1 || b1, a0 || b0)
      } else {
        let (a1, a0) = dim_demorgan_endpoint_rails(a, true)
        let (b1, b0) = dim_demorgan_endpoint_rails(b, true)
        (a1 && b1, a0 && b0)
      }
  }
}

///|
/// Exact `O(|r|)` zero-allocation test for `r ≡ 0` in the Free De Morgan Interval `I_DM`
/// (soundly returns `false` on `i ∧ ¬i`, unlike Boolean endpoint `dim_eq_sem`).
pub fn dim_is_zero_demorgan(r : Dim) -> Bool {
  let (v_top, _) = dim_demorgan_endpoint_rails(r, false)
  !v_top
}

///|
/// Exact `O(|r|)` zero-allocation test for `r ≡ 1` in the Free De Morgan Interval `I_DM`
/// (soundly returns `false` on `i ∨ ¬i`, unlike Boolean endpoint `dim_eq_sem`).
pub fn dim_is_one_demorgan(r : Dim) -> Bool {
  let (_, v_bot) = dim_demorgan_endpoint_rails(r, false)
  v_bot
}

///|
fn dim_demorgan_swar3_word(r : Dim, negated : Bool) -> UInt64 {
  match r {
    DZero => if negated { 0xFFFFFFFFFFFFFFFFUL } else { 0UL }
    DOne => if negated { 0UL } else { 0xFFFFFFFFFFFFFFFFUL }
    DVar(i) =>
      if i < 0 {
        if negated {
          0xFFFFFFFFFFFFFFFFUL
        } else {
          0UL
        }
      } else if !negated {
        swar6_var_mask(2 * i)
      } else {
        swar6_var_mask(2 * i + 1)
      }
    DNeg(a) => dim_demorgan_swar3_word(a, !negated)
    DAnd(a, b) =>
      if !negated {
        dim_demorgan_swar3_word(a, false) & dim_demorgan_swar3_word(b, false)
      } else {
        dim_demorgan_swar3_word(a, true) | dim_demorgan_swar3_word(b, true)
      }
    DOr(a, b) =>
      if !negated {
        dim_demorgan_swar3_word(a, false) | dim_demorgan_swar3_word(b, false)
      } else {
        dim_demorgan_swar3_word(a, true) & dim_demorgan_swar3_word(b, true)
      }
  }
}

///|
fn dim_demorgan_dag_build(m : BddManager, r : Dim, negated : Bool) -> Int32 {
  match r {
    DZero => if negated { bdd_dag_true(m) } else { bdd_dag_false(m) }
    DOne => if negated { bdd_dag_false(m) } else { bdd_dag_true(m) }
    DVar(i) =>
      if i < 0 {
        if negated {
          bdd_dag_true(m)
        } else {
          bdd_dag_false(m)
        }
      } else if !negated {
        bdd_dag_var(m, 2 * i)
      } else {
        bdd_dag_var(m, 2 * i + 1)
      }
    DNeg(a) => dim_demorgan_dag_build(m, a, !negated)
    DAnd(a, b) =>
      if !negated {
        bdd_dag_and(
          m,
          dim_demorgan_dag_build(m, a, false),
          dim_demorgan_dag_build(m, b, false),
        )
      } else {
        bdd_dag_or(
          m,
          dim_demorgan_dag_build(m, a, true),
          dim_demorgan_dag_build(m, b, true),
        )
      }
    DOr(a, b) =>
      if !negated {
        bdd_dag_or(
          m,
          dim_demorgan_dag_build(m, a, false),
          dim_demorgan_dag_build(m, b, false),
        )
      } else {
        bdd_dag_and(
          m,
          dim_demorgan_dag_build(m, a, true),
          dim_demorgan_dag_build(m, b, true),
        )
      }
  }
}

///|
/// Exact equality `r ≡ s` in the Free De Morgan Algebra `I_DM` (Kalman dual-rail theorem):
/// uses zero-allocation `UInt64` SWAR for `<= 3` dimension variables (`<= 6` dual rails)
/// and canonical `2n`-variable `BddManager` ROBDDs for arbitrary `n`.
pub fn dim_eq_demorgan(r : Dim, s : Dim) -> Bool {
  if r == s {
    return true
  }
  let nr = dim_max_var_plus1(r)
  let ns = dim_max_var_plus1(s)
  let n = if nr > ns { nr } else { ns }
  if n <= 3 {
    return dim_demorgan_swar3_word(r, false) ==
      dim_demorgan_swar3_word(s, false)
  }
  let mgr = bdd_manager_new(2 * n)
  dim_demorgan_dag_build(mgr, r, false) == dim_demorgan_dag_build(mgr, s, false)
}

// ---------------------------------------------------------------------------
// Free CCHM Cofibration Lattice `Cofib(n)` (Cohen–Coquand–Huber–Mörtberg §4.1)
// ---------------------------------------------------------------------------

///|
fn cchm_swar3_valid_mask(n : Int32) -> UInt64 {
  let mut mask = 0xFFFFFFFFFFFFFFFFUL
  let lim = if n < 3 { n } else { 3 }
  for k in 0..<lim {
    let u0 = swar6_var_mask(2 * k)
    let u1 = swar6_var_mask(2 * k + 1)
    mask = mask & ((u0 & u1) ^ 0xFFFFFFFFFFFFFFFFUL)
  }
  mask
}

///|
fn cchm_dim_eq_swar3(r : Dim, want_one : Bool) -> UInt64 {
  match r {
    DZero => if want_one { 0UL } else { 0xFFFFFFFFFFFFFFFFUL }
    DOne => if want_one { 0xFFFFFFFFFFFFFFFFUL } else { 0UL }
    DVar(i) =>
      if i < 0 {
        if want_one {
          0UL
        } else {
          0xFFFFFFFFFFFFFFFFUL
        }
      } else if !want_one {
        swar6_var_mask(2 * i)
      } else {
        swar6_var_mask(2 * i + 1)
      }
    DNeg(a) => cchm_dim_eq_swar3(a, !want_one)
    DAnd(a, b) =>
      if want_one {
        // (a ∧ b = 1) ⇔ (a = 1) ∧ (b = 1)
        cchm_dim_eq_swar3(a, true) & cchm_dim_eq_swar3(b, true)
      } else {
        // (a ∧ b = 0) ⇔ (a = 0) ∨ (b = 0)
        cchm_dim_eq_swar3(a, false) | cchm_dim_eq_swar3(b, false)
      }
    DOr(a, b) =>
      if want_one {
        // (a ∨ b = 1) ⇔ (a = 1) ∨ (b = 1)
        cchm_dim_eq_swar3(a, true) | cchm_dim_eq_swar3(b, true)
      } else {
        // (a ∨ b = 0) ⇔ (a = 0) ∧ (b = 0)
        cchm_dim_eq_swar3(a, false) & cchm_dim_eq_swar3(b, false)
      }
  }
}

///|
fn cchm_face_swar3(f : Face) -> UInt64 {
  match f {
    FTop => 0xFFFFFFFFFFFFFFFFUL
    FBot => 0UL
    FEq0(r) => cchm_dim_eq_swar3(r, false)
    FEq1(r) => cchm_dim_eq_swar3(r, true)
    FAnd(a, b) => cchm_face_swar3(a) & cchm_face_swar3(b)
    FOr(a, b) => cchm_face_swar3(a) | cchm_face_swar3(b)
  }
}

///|
fn cchm_dim_eq_dag(m : BddManager, r : Dim, want_one : Bool) -> Int32 {
  match r {
    DZero => if want_one { bdd_dag_false(m) } else { bdd_dag_true(m) }
    DOne => if want_one { bdd_dag_true(m) } else { bdd_dag_false(m) }
    DVar(i) =>
      if i < 0 {
        if want_one {
          bdd_dag_false(m)
        } else {
          bdd_dag_true(m)
        }
      } else if !want_one {
        bdd_dag_var(m, 2 * i)
      } else {
        bdd_dag_var(m, 2 * i + 1)
      }
    DNeg(a) => cchm_dim_eq_dag(m, a, !want_one)
    DAnd(a, b) =>
      if want_one {
        bdd_dag_and(m, cchm_dim_eq_dag(m, a, true), cchm_dim_eq_dag(m, b, true))
      } else {
        bdd_dag_or(
          m,
          cchm_dim_eq_dag(m, a, false),
          cchm_dim_eq_dag(m, b, false),
        )
      }
    DOr(a, b) =>
      if want_one {
        bdd_dag_or(m, cchm_dim_eq_dag(m, a, true), cchm_dim_eq_dag(m, b, true))
      } else {
        bdd_dag_and(
          m,
          cchm_dim_eq_dag(m, a, false),
          cchm_dim_eq_dag(m, b, false),
        )
      }
  }
}

///|
fn cchm_face_dag(m : BddManager, f : Face) -> Int32 {
  match f {
    FTop => bdd_dag_true(m)
    FBot => bdd_dag_false(m)
    FEq0(r) => cchm_dim_eq_dag(m, r, false)
    FEq1(r) => cchm_dim_eq_dag(m, r, true)
    FAnd(a, b) => bdd_dag_and(m, cchm_face_dag(m, a), cchm_face_dag(m, b))
    FOr(a, b) => bdd_dag_or(m, cchm_face_dag(m, a), cchm_face_dag(m, b))
  }
}

///|
fn cchm_valid_mask_dag(m : BddManager, n : Int32) -> Int32 {
  let mut acc = bdd_dag_true(m)
  for k in 0..<n {
    let both = bdd_dag_and(m, bdd_dag_var(m, 2 * k), bdd_dag_var(m, 2 * k + 1))
    acc = bdd_dag_and(m, acc, bdd_dag_not(m, both))
  }
  acc
}

///|
/// Exact equality `f ≡ g` in the Free CCHM Cofibration Lattice `Cofib(n)`:
/// `(i = 0) ∧ (i = 1) = ⊥_F` holds, while `(i = 0) ∨ (i = 1) = ∂I ≠ ⊤_F` is preserved!
pub fn cchm_face_eq(f : Face, g : Face) -> Bool {
  if f == g {
    return true
  }
  let nf = face_max_var_plus1(f)
  let ng = face_max_var_plus1(g)
  let n = if nf > ng { nf } else { ng }
  if n <= 3 {
    let vm = cchm_swar3_valid_mask(n)
    return (cchm_face_swar3(f) & vm) == (cchm_face_swar3(g) & vm)
  }
  let mgr = bdd_manager_new(2 * n)
  let vm = cchm_valid_mask_dag(mgr, n)
  bdd_dag_and(mgr, cchm_face_dag(mgr, f), vm) ==
  bdd_dag_and(mgr, cchm_face_dag(mgr, g), vm)
}

///|
/// Exact entailment `f ≤ g` in the Free CCHM Cofibration Lattice `Cofib(n)`.
pub fn cchm_face_le(f : Face, g : Face) -> Bool {
  cchm_face_eq(FAnd(f, g), f)
}

///|
/// Test `f ≡ ⊥_F` in the Free CCHM Cofibration Lattice.
pub fn cchm_face_is_bot(f : Face) -> Bool {
  cchm_face_eq(f, FBot)
}

///|
/// Test `f ≡ ⊤_F` in the Free CCHM Cofibration Lattice (`(i=0) ∨ (i=1)` returns `false`!).
pub fn cchm_face_is_top(f : Face) -> Bool {
  cchm_face_eq(f, FTop)
}

// ---------------------------------------------------------------------------
// Zero-Reflection Canonical Face Key (`face_bdd_canon_key`)
// ---------------------------------------------------------------------------

///|
fn u64_to_hex16(w : UInt64) -> String {
  let hex = "0123456789abcdef"
  let sb = StringBuilder()
  sb.write_string("W:")
  for s in 0..<16 {
    let nib = ((w >> ((15 - s) * 4)) & 0xFUL).to_int()
    sb.write_char(hex[nib].to_int().unsafe_to_char())
  }
  sb.to_string()
}

///|
fn bdd_write_canon(sb : StringBuilder, b : Bdd) -> Unit {
  match b {
    BddZero => sb.write_char('0')
    BddOne => sb.write_char('1')
    BddNode(v, lo, hi) => {
      sb.write_char('(')
      sb.write_string(v.to_string())
      sb.write_char(',')
      bdd_write_canon(sb, lo)
      sb.write_char(',')
      bdd_write_canon(sb, hi)
      sb.write_char(')')
    }
  }
}

///|
/// Injective canonical key for a face modulo Boolean endpoint equivalence:
/// uses a zero-BDD 64-bit SWAR truth-word key (`W:<16 hex>`) whenever `max_var <= 6`,
/// and compact prefix-free canonical ROBDD serialization for `max_var > 6`
/// (eliminating `Repr(bdd_of_face(...)).to_string()`).
pub fn face_bdd_canon_key(f : Face) -> String {
  let n = face_max_var_plus1(f)
  if n <= 6 {
    return u64_to_hex16(face_truth_u64(f, 6))
  }
  let sb = StringBuilder()
  sb.write_string("B:")
  bdd_write_canon(sb, bdd_of_face(f, n))
  sb.to_string()
}
