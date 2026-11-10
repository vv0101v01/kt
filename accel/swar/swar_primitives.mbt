///|
// Layer-0 Zero-Dependency 64-Bit SWAR Hardware Primitives (`accel/swar`):
//
// Provides register-level bit-parallel kernels shared downward by `F4 topos`,
// `F7 discovery` (`tensor` + `conjecture/kernel`), and `F8 accel`:
//   1. `Gf3Slice64`: Boothby–Bradshaw dual-rail 64-trit `GF(3)` arithmetic
//      (`gf3_add64`, `gf3_neg64`, `gf3_sub64`, `gf3_mul64`) and 64-lane
//      `F_3^{2x2x2}` Cayley hyperdeterminant sweep (`103` chunks for all `6,561` tensors).
//   2. `swar_downset_closure64`, `swar_heyting_impl64`, `swar_coheyting_sub64`:
//      register-level bi-Heyting sieve operations in `O(popcnt)` via `ctz` bit-stripping.
//   3. `swar_bitplane_implication_cex`: 64-sample-per-word implication & exact minimal
//      counterexample extraction (`(w << 6) + diff.ctz()`).

///|
/// Dual-rail bit-sliced vector of 64 elements in `GF(3) = {0, 1, 2}`:
/// lane `i` encodes `0` as `(0, 0)`, `1` as `(1, 0)`, and `2` as `(0, 1)`
/// with canonical invariant `(lo & hi) == 0UL`.
#derive(Debug, Eq)
pub(all) struct Gf3Slice64 {
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
/// Branchless 64-trit `GF(3)` subtraction `(a - b) mod 3 == a + (-b)`.
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
/// Compute 64 consecutive `F_3^{2x2x2}` Cayley hyperdeterminants starting at `base_code`
/// (`0 <= valid_lanes <= 64`) using the exact polynomial `dg - 2 * pairs + 4 * tet` over `GF(3)`
/// (exercising `gf3_add64`, `gf3_sub64`, and `gf3_mul64` across all 64 lanes simultaneously).
pub fn gf3_hyperdet222_chunk64(
  base_code : Int32,
  valid_lanes : Int32,
) -> Gf3Slice64 {
  let coords : Array[Gf3Slice64] = Array::make(8, Gf3Slice64::{
    lo: 0UL,
    hi: 0UL,
  })
  let mut div = 1
  for k in 0..<8 {
    let mut lo = 0UL
    let mut hi = 0UL
    for lane in 0..<valid_lanes {
      let digit = (base_code + lane) / div % 3
      if digit == 1 {
        lo = lo | (1UL << lane)
      } else if digit == 2 {
        hi = hi | (1UL << lane)
      }
    }
    coords[k] = Gf3Slice64::{ lo, hi, }
    div = div * 3
  }
  let a = coords[0]
  let b = coords[1]
  let c = coords[2]
  let d = coords[3]
  let e = coords[4]
  let f = coords[5]
  let g = coords[6]
  let h = coords[7]
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
  let two_pairs = gf3_add64(pairs, pairs)
  let t_adfg = gf3_mul64(gf3_mul64(a, d), gf3_mul64(f, g))
  let t_bceh = gf3_mul64(gf3_mul64(b, c), gf3_mul64(e, h))
  // Over GF(3), 4 * tet == 1 * tet, and sq - 2 * pairs uses `gf3_sub64` directly!
  gf3_add64(gf3_sub64(sq, two_pairs), gf3_add64(t_adfg, t_bceh))
}

///|
/// Sweep all `3^8 = 6,561` `2x2x2` tensors over `F_3` in `103` 64-wide SWAR iterations,
/// returning the flat array `hyperdets[0..6560]` with zero scalar `Tensor3` heap allocations.
pub fn gf3_sweep_all_6561_hyperdets() -> Array[Int32] {
  let total = 6561
  let out = Array::make(total, 0)
  let chunks = (total + 63) / 64
  for ch in 0..<chunks {
    let base = ch * 64
    let valid = if base + 64 <= total { 64 } else { total - base }
    let det = gf3_hyperdet222_chunk64(base, valid)
    for lane in 0..<valid {
      out[base + lane] = gf3_slice64_get(det, lane)
    }
  }
  out
}

///|
/// Compute the precomposition downset closure `⋃_{f ∈ seed_mask} downset_rows[f]`
/// in `O(popcnt(seed_mask))` register ops using `ctz` lowest-set-bit stripping.
pub fn swar_downset_closure64(
  seed_mask : UInt64,
  downset_rows : Array[UInt64],
) -> UInt64 {
  let mut rem = seed_mask
  let mut acc = 0UL
  let n = downset_rows.length()
  while rem != 0UL {
    let idx = rem.ctz()
    if idx < n {
      acc = acc | downset_rows[idx]
    }
    rem = rem & (rem - 1UL)
  }
  acc
}

///|
/// Register-level Heyting implication `(S ⇒ T)` over `domain_mask`:
/// arrow `f ∈ domain_mask` belongs to `(S ⇒ T)` iff `(downset_rows[f] & S & ¬T) == 0`.
pub fn swar_heyting_impl64(
  domain_mask : UInt64,
  s_mask : UInt64,
  t_mask : UInt64,
  downset_rows : Array[UInt64],
) -> UInt64 {
  let diff = s_mask & t_mask.lnot()
  if diff == 0UL {
    return domain_mask
  }
  let mut rem = domain_mask
  let mut out = 0UL
  let n = downset_rows.length()
  while rem != 0UL {
    let f = rem.ctz()
    if f < n && (downset_rows[f] & diff) == 0UL {
      out = out | (1UL << f)
    }
    rem = rem & (rem - 1UL)
  }
  out
}

///|
/// Register-level co-Heyting subtraction `(S ⇐ T)` (left adjoint `(S ⇐ T) ⊆ U ⟺ S ⊆ T ∪ U`):
/// equals the sieve generated by the set-theoretic difference `S \ T`, computed in
/// `O(popcnt(S \ T))` bitwise ORs!
pub fn swar_coheyting_sub64(
  s_mask : UInt64,
  t_mask : UInt64,
  downset_rows : Array[UInt64],
) -> UInt64 {
  swar_downset_closure64(s_mask & t_mask.lnot(), downset_rows)
}

///|
/// Pack boolean predicate evaluations `eval_fn(sample)` (`0 <= sample < num_samples`)
/// into contiguous 64-sample `UInt64` bitplanes.
pub fn swar_pack_bitplane(
  num_samples : Int32,
  eval_fn : (Int32) -> Bool,
) -> Array[UInt64] {
  let nwords = (num_samples + 63) / 64
  let words = Array::make(nwords, 0UL)
  for s in 0..<num_samples {
    if eval_fn(s) {
      let w = s >> 6
      let b = s & 63
      words[w] = words[w] | (1UL << b)
    }
  }
  words
}

///|
/// Bit-parallel implication test `P_i ⇒ P_j` across 64 samples per word:
/// returns `-1` iff `P_i(s) ⇒ P_j(s)` holds for all `0 <= s < num_samples`,
/// otherwise returns the **exact smallest counterexample sample index** `s` via hardware `ctz`!
pub fn swar_bitplane_implication_cex(
  plane_i : Array[UInt64],
  plane_j : Array[UInt64],
  num_samples : Int32,
) -> Int32 {
  let nwords = plane_i.length()
  let rem_bits = num_samples & 63
  for w in 0..<nwords {
    let valid_mask = if w == nwords - 1 && rem_bits != 0 {
      (1UL << rem_bits) - 1UL
    } else {
      0xFFFFFFFFFFFFFFFFUL
    }
    let violation = plane_i[w] & plane_j[w].lnot() & valid_mask
    if violation != 0UL {
      return (w << 6) + violation.ctz()
    }
  }
  -1
}
