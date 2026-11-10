///|
// L0 64-Bit Hardware Substrate for Memoized Type Checking & Dual-Context Resource Grading:
//   1. Bijective Stafford Mix13 `swar_mix64` / `swar_unmix64` & Merkle-DAG hash combiners;
//   2. `SwarMemoTable64`: O(1) epoch-invalidated flat open-addressing memoization cache;
//   3. 16-lane × 4-bit nibble SWAR saturating resource-semiring vector operations
//      (`0` = erased/type-level, `1` = linear, `2..14` = bounded grade, `15` = ω unrestricted).

///|
/// Bijective 64-bit Stafford Mix13 avalanche permutation on `UInt64`.
/// Provably invertible via `swar_unmix64` (zero entropy loss on 2^64 states).
pub fn swar_mix64(x0 : UInt64) -> UInt64 {
  let z1 = (x0 ^ (x0 >> 30)) * 0xBF58476D1CE4E5B9UL
  let z2 = (z1 ^ (z1 >> 27)) * 0x94D049BB133111EBUL
  z2 ^ (z2 >> 31)
}

///|
/// Exact 2-adic inverse of `swar_mix64` (`swar_unmix64(swar_mix64(x)) == x` for all `x`).
/// Uses `0xBF58476D1CE4E5B9 * 0x96DE1B173F119089 ≡ 1 (mod 2^64)` and
/// `0x94D049BB133111EB * 0x319642B2D24D8EC3 ≡ 1 (mod 2^64)`.
pub fn swar_unmix64(z : UInt64) -> UInt64 {
  let u2 = z ^ (z >> 31) ^ (z >> 62)
  let t2 = u2 * 0x319642B2D24D8EC3UL
  let u1 = t2 ^ (t2 >> 27) ^ (t2 >> 54)
  let t1 = u1 * 0x96DE1B173F119089UL
  t1 ^ (t1 >> 30) ^ (t1 >> 60)
}

///|
/// Combine an AST/judgment constructor `tag` with two 64-bit child Merkle digests.
/// Guarantees non-zero digest (`| 1UL` fallback only if raw == 0) for open-addressing keys.
pub fn swar_merkle_node64(tag : Int32, c0 : UInt64, c1 : UInt64) -> UInt64 {
  let seed = (tag.to_int64().reinterpret_as_uint64() + 1UL) *
    0x9E3779B97F4A7C15UL
  let h0 = swar_mix64(seed ^ c0)
  let h1 = swar_mix64(h0 + c1 + 0x517CC1B727220A95UL)
  if h1 == 0UL {
    1UL
  } else {
    h1
  }
}

///|
/// Fold an arbitrary-arity child digest sequence under `tag` into a non-zero 64-bit Merkle digest.
pub fn swar_merkle_seq64(tag : Int32, children : Array[UInt64]) -> UInt64 {
  let mut acc = swar_mix64(
    ((tag.to_int64().reinterpret_as_uint64() + 1UL) * 0xD6E8FEB86659FD93UL) ^
    children.length().to_int64().reinterpret_as_uint64(),
  )
  for i in 0..<children.length() {
    acc = swar_mix64(acc ^ (children[i] + 0x9E3779B97F4A7C15UL))
  }
  if acc == 0UL {
    1UL
  } else {
    acc
  }
}

///|
/// Flat open-addressing 64-bit memoization table with O(1) epoch invalidation.
#derive(Debug, Eq)
pub(all) struct SwarMemoTable64 {
  mask : Int32
  keys : FixedArray[UInt64]
  vals : FixedArray[Int32]
  epochs : FixedArray[Int32]
  mut cur_epoch : Int32
  mut hits : Int32
  mut misses : Int32
}

///|
pub extend SwarMemoTable64 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SwarMemoTable64 with Eq::{not_equal, equal}

///|
/// Allocate a flat `2^log2_cap`-slot memo table (`log2_cap` clamped to `4..16`).
pub fn swar_memo_new(log2_cap : Int32) -> SwarMemoTable64 {
  let p = if log2_cap < 4 { 4 } else if log2_cap > 16 { 16 } else { log2_cap }
  let cap = 1 << p
  SwarMemoTable64::{
    mask: cap - 1,
    keys: FixedArray::make(cap, 0UL),
    vals: FixedArray::make(cap, 0),
    epochs: FixedArray::make(cap, 0),
    cur_epoch: 1,
    hits: 0,
    misses: 0,
  }
}

///|
/// O(1) generation bump invalidating all stale entries without zeroing memory.
pub fn swar_memo_bump_epoch(tbl : SwarMemoTable64) -> Unit {
  tbl.cur_epoch = tbl.cur_epoch + 1
}

///|
/// Lookup `key` in `tbl` within the active epoch (bounded 8-step linear probe).
pub fn swar_memo_get(tbl : SwarMemoTable64, key : UInt64) -> Int32? {
  let k = if key == 0UL { 1UL } else { key }
  let base = k.reinterpret_as_int64().to_int() & tbl.mask
  for step in 0..<8 {
    let idx = (base + step) & tbl.mask
    if tbl.epochs[idx] != tbl.cur_epoch {
      tbl.misses = tbl.misses + 1
      return None
    }
    if tbl.keys[idx] == k {
      tbl.hits = tbl.hits + 1
      return Some(tbl.vals[idx])
    }
  }
  tbl.misses = tbl.misses + 1
  None
}

///|
/// Insert or update `(key, val)` in the active epoch (bounded 8-step probe, evicting last slot if full).
pub fn swar_memo_put(tbl : SwarMemoTable64, key : UInt64, val : Int32) -> Unit {
  let k = if key == 0UL { 1UL } else { key }
  let base = k.reinterpret_as_int64().to_int() & tbl.mask
  for step in 0..<8 {
    let idx = (base + step) & tbl.mask
    if tbl.epochs[idx] != tbl.cur_epoch || tbl.keys[idx] == k {
      tbl.keys[idx] = k
      tbl.vals[idx] = val
      tbl.epochs[idx] = tbl.cur_epoch
      return
    }
  }
  let evict = (base + 7) & tbl.mask
  tbl.keys[evict] = k
  tbl.vals[evict] = val
  tbl.epochs[evict] = tbl.cur_epoch
}

///|
/// Extract 4-bit resource grade `0..15` (`15 = ω` unrestricted) at variable slot `idx ∈ 0..<16`.
pub fn swar_grade16_get(vec : UInt64, idx : Int32) -> Int32 {
  if idx < 0 || idx >= 16 {
    return 0
  }
  let shift = idx * 4
  ((vec >> shift) & 0xFUL).reinterpret_as_int64().to_int()
}

///|
/// Set 4-bit resource grade `g` (clamped to `0..15`) at variable slot `idx ∈ 0..<16`.
pub fn swar_grade16_set(vec : UInt64, idx : Int32, g : Int32) -> UInt64 {
  if idx < 0 || idx >= 16 {
    return vec
  }
  let clamped = if g < 0 { 0 } else if g > 15 { 15 } else { g }
  let shift = idx * 4
  let clear_mask = (0xFUL << shift).lnot()
  (vec & clear_mask) | (clamped.to_int64().reinterpret_as_uint64() << shift)
}

///|
/// Parallel 16-lane × 4-bit saturating resource addition `Δ₁ + Δ₂` (saturating at `15 = ω`).
/// Uses even/odd nibble split (`0x0F0F...`) so carry bits never bleed into adjacent lanes!
pub fn swar_grade16_add_sat(a : UInt64, b : UInt64) -> UInt64 {
  let mask_lo = 0x0F0F0F0F0F0F0F0FUL
  let sum_even = (a & mask_lo) + (b & mask_lo)
  let ovf_even = (sum_even & 0x1010101010101010UL) >> 4
  let sat_even = (sum_even | (ovf_even * 0xFUL)) & mask_lo

  let sum_odd = ((a >> 4) & mask_lo) + ((b >> 4) & mask_lo)
  let ovf_odd = (sum_odd & 0x1010101010101010UL) >> 4
  let sat_odd = (sum_odd | (ovf_odd * 0xFUL)) & mask_lo

  sat_even | (sat_odd << 4)
}

///|
/// QTT / Graded scalar multiplication `σ · Δ` on a 16-lane 4-bit resource vector:
///   - `σ <= 0` => `0UL` in O(1) (McBride's 0-usage dependent type formation rule!);
///   - `σ == 1` => `vec` unchanged;
///   - `σ >= 15` (`ω`) => every non-zero lane saturates to `15` (`ω · 0 = 0`, `ω · k = ω` for `k > 0`).
pub fn swar_grade16_scale_sat(vec : UInt64, sigma : Int32) -> UInt64 {
  if sigma <= 0 || vec == 0UL {
    return 0UL
  }
  if sigma == 1 {
    return vec
  }
  let mut acc = 0UL
  let mut cur = vec
  let mut k = if sigma > 15 { 15 } else { sigma }
  while k > 0 {
    if (k & 1) != 0 {
      acc = swar_grade16_add_sat(acc, cur)
    }
    cur = swar_grade16_add_sat(cur, cur)
    k = k >> 1
  }
  acc
}

///|
/// Verify QTT / Dual-Context sub-usaging across `num_vars` (`<= 16`) simultaneously:
///   - `decl == 0` (erased / intuitionistic-type-only): requires `actual == 0`;
///   - `decl == 1` (strict linear): requires `actual == 1` (no weakening, no contraction);
///   - `decl == 15` (`ω` unrestricted): any `actual ∈ 0..15` is valid;
///   - `decl ∈ 2..14` (bounded exact/affine resource budget): requires `actual <= decl`.
pub fn swar_grade16_usage_compatible(
  actual : UInt64,
  declared : UInt64,
  num_vars : Int32,
) -> Bool {
  let lim = if num_vars > 16 { 16 } else { num_vars }
  for i in 0..<lim {
    let a = swar_grade16_get(actual, i)
    let d = swar_grade16_get(declared, i)
    if d == 0 {
      if a != 0 {
        return false
      }
    } else if d == 1 {
      if a != 1 {
        return false
      }
    } else if d < 15 {
      if a > d {
        return false
      }
    }
  }
  true
}

///|
/// Verify Stafford Mix13 bijection, `SwarMemoTable64` O(1) epoch invalidation,
/// and 16-lane SWAR QTT resource semimodule laws (`0·v = 0`, `1·v = v`, saturating `ω = 15`).
pub fn verify_swar_memo_and_grade16_laws() -> Bool {
  // Law 1: Stafford Mix13 exact bijection on boundary & pseudorandom 64-bit keys
  let samples : Array[UInt64] = [
    0UL, 1UL, 0xFFFF_FFFF_FFFF_FFFFUL, 0x1234_5678_9ABC_DEF0UL,
  ]
  for x in samples {
    if swar_unmix64(swar_mix64(x)) != x {
      return false
    }
  }
  // Law 2: Epoch-stamped memo hit, O(1) epoch invalidation, and clean re-insertion
  let tbl = swar_memo_new(6)
  let k1 = swar_merkle_node64(7, 100UL, 200UL)
  swar_memo_put(tbl, k1, 42)
  let hit_ok = swar_memo_get(tbl, k1) == Some(42)
  swar_memo_bump_epoch(tbl)
  let inv_ok = swar_memo_get(tbl, k1) == None
  // Law 3: 16-lane SWAR QTT semimodule addition, scalar scaling, and usage compatibility
  let mut v = 0UL
  v = swar_grade16_set(v, 0, 1) // strict linear
  v = swar_grade16_set(v, 1, 0) // erased (type-only)
  v = swar_grade16_set(v, 2, 15) // unrestricted ω
  let sum_vv = swar_grade16_add_sat(v, v)
  let grade_ok = swar_grade16_get(sum_vv, 0) == 2 &&
    swar_grade16_get(sum_vv, 1) == 0 &&
    swar_grade16_get(sum_vv, 2) == 15 &&
    swar_grade16_scale_sat(v, 0) == 0UL &&
    swar_grade16_scale_sat(v, 1) == v &&
    swar_grade16_usage_compatible(v, v, 3) &&
    !swar_grade16_usage_compatible(sum_vv, v, 3)
  hit_ok && inv_ok && grade_ok
}
