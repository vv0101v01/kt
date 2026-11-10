///|
/// Scheme Hardware-SWAR Monomial Packing (`Mono64`), Yan Geobucket Priority Reducer,
/// Gebauer–Möller Critical-Pair Pruning, M4RI `GF(2)` Boolean Faugère F4, and
/// Multi-Prime Modular Faugère F4 Macaulay Elimination with Wang Rational Reconstruction.

// =============================================================================
// 1. Packed 64-bit SWAR Monomials (`Mono64`: 7 variables × 7-bit exponents + deg)
// =============================================================================

///|
let mono64_guard_mask : UInt64 = 0x8080808080808080UL

///|
/// Attempt to pack an exponent vector `exps` (`nvars <= 7`, `0 <= exps[i] <= 127`,
/// `total_deg <= 127`) into a single 64-bit SWAR word:
/// - Byte `i` (`0 <= i < 7`): `exps[i]` (`0..127`, bit 7 = `0`),
/// - Byte `7` (`bits 56..63`): `total_deg` (`0..127`, bit 63 = `0`).
pub fn mono64_try_pack(exps : Array[Int32]) -> UInt64? {
  let n = exps.length()
  if n > 7 {
    return None
  }
  let mut w = 0UL
  let mut deg = 0
  for i in 0..<n {
    let e = exps[i]
    if e < 0 || e > 127 {
      return None
    }
    deg = deg + e
    if deg > 127 {
      return None
    }
    w = w | (e.to_uint64() << (i * 8))
  }
  Some(w | (deg.to_uint64() << 56))
}

///|
/// Single-comparison `UInt64` order-preserving `GRevLex` key for `nvars <= 7`, `total_deg <= 127`:
/// `mono64_grevlex_key(a) > mono64_grevlex_key(b)` iff `monomial_cmp(GRevLex, a, b) > 0`!
pub fn mono64_try_grevlex_key(exps : Array[Int32]) -> UInt64? {
  let n = exps.length()
  if n > 7 {
    return None
  }
  let mut deg = 0
  for i in 0..<n {
    let e = exps[i]
    if e < 0 || e > 127 {
      return None
    }
    deg = deg + e
    if deg > 127 {
      return None
    }
  }
  let mut key = deg.to_uint64() << 56
  // In GRevLex, after total degree, we scan from `i = n - 1` down to `0`, and
  // smaller `exps[i]` means LARGER monomial -> store `(127 - exps[n - 1 - t])` at byte `6 - t`!
  for t in 0..<n {
    let inv_e = 127 - exps[n - 1 - t]
    key = key | (inv_e.to_uint64() << ((6 - t) * 8))
  }
  Some(key)
}

///|
/// Branchless 3-instruction SWAR monomial divisibility (`divisor | target`):
/// In each byte `0..7`, `128 + target_byte - divisor_byte` lies in `[1, 255]` (zero cross-byte borrow!),
/// keeping bit 7 equal to `1` iff `target_byte >= divisor_byte`.
pub fn mono64_divides(divisor : UInt64, target : UInt64) -> Bool {
  (((target | mono64_guard_mask) - divisor) & mono64_guard_mask) ==
  mono64_guard_mask
}

///|
/// Exact SWAR monomial quotient `target / divisor` (assuming `mono64_divides(divisor, target)`).
pub fn mono64_quot(target : UInt64, divisor : UInt64) -> UInt64 {
  target - divisor
}

///|
/// Exact SWAR coprimality test (`min(a_i, b_i) == 0` for all `0 <= i < 7`):
/// converts each nonzero byte (`1..127`) into bit-7 = `1` via `(x + 0x7F..7F) & 0x80..80`!
pub fn mono64_coprime(a : UInt64, b : UInt64) -> Bool {
  let var_mask = 0x00FFFFFFFFFFFFFFUL
  let nz_magic = 0x007F7F7F7F7F7F7FUL
  let hi_vars = 0x0080808080808080UL
  let na = ((a & var_mask) + nz_magic) & hi_vars
  let nb = ((b & var_mask) + nz_magic) & hi_vars
  (na & nb) == 0UL
}

// =============================================================================
// 2. `O(m log m)` GRevLex Merge-Sort & `O(|f| + |g|)` Sorted Linear Merge
// =============================================================================

///|
fn mpoly_normalize_terms_fast(nvars : Int32, raw : Array[MTerm]) -> MPoly {
  let filtered : Array[MTerm] = []
  let keys : Array[UInt64] = []
  let mut all_swar = nvars <= 7
  for t in raw {
    guard t.exps.length() == nvars else {
      abort("mpoly_from_terms: exponent length mismatch")
    }
    if !@exactalg.rat_is_zero(t.coeff) {
      let term_cp : MTerm = { coeff: t.coeff, exps: t.exps.copy(), }
      filtered.push(term_cp)
      if all_swar {
        match mono64_try_grevlex_key(term_cp.exps) {
          Some(k) => keys.push(k)
          None => all_swar = false
        }
      }
    }
  }
  let m = filtered.length()
  if m <= 1 {
    return { nvars, terms: filtered, }
  }
  // Bottom-up `O(m log m)` merge sort (descending GRevLex)
  let aux_t : Array[MTerm] = filtered.copy()
  let aux_k : Array[UInt64] = if all_swar { keys.copy() } else { [] }
  let mut width = 1
  while width < m {
    let mut left = 0
    while left < m {
      let mid = if left + width < m { left + width } else { m }
      let right = if left + 2 * width < m { left + 2 * width } else { m }
      let mut i = left
      let mut j = mid
      let mut out_p = left
      while i < mid && j < right {
        let take_left = if all_swar {
          keys[i] >= keys[j]
        } else {
          monomial_cmp(GRevLex, filtered[i].exps, filtered[j].exps) >= 0
        }
        if take_left {
          aux_t[out_p] = filtered[i]
          if all_swar {
            aux_k[out_p] = keys[i]
          }
          i = i + 1
        } else {
          aux_t[out_p] = filtered[j]
          if all_swar {
            aux_k[out_p] = keys[j]
          }
          j = j + 1
        }
        out_p = out_p + 1
      }
      while i < mid {
        aux_t[out_p] = filtered[i]
        if all_swar {
          aux_k[out_p] = keys[i]
        }
        i = i + 1
        out_p = out_p + 1
      }
      while j < right {
        aux_t[out_p] = filtered[j]
        if all_swar {
          aux_k[out_p] = keys[j]
        }
        j = j + 1
        out_p = out_p + 1
      }
      for p in left..<right {
        filtered[p] = aux_t[p]
        if all_swar {
          keys[p] = aux_k[p]
        }
      }
      left = left + 2 * width
    }
    width = width * 2
  }
  // Single linear coalesce pass
  let merged : Array[MTerm] = []
  let merged_k : Array[UInt64] = []
  for idx in 0..<m {
    let t = filtered[idx]
    let same = if merged.length() == 0 {
      false
    } else if all_swar {
      merged_k[merged_k.length() - 1] == keys[idx]
    } else {
      merged[merged.length() - 1].exps == t.exps
    }
    if same {
      guard merged.pop() is Some(last) else {
        abort("mpoly_normalize_terms_fast: empty merge stack")
      }
      if all_swar {
        ignore(merged_k.pop())
      }
      let sum_c = @exactalg.rat_add(last.coeff, t.coeff)
      if !@exactalg.rat_is_zero(sum_c) {
        merged.push({ coeff: sum_c, exps: last.exps, })
        if all_swar {
          merged_k.push(keys[idx])
        }
      }
    } else {
      merged.push(t)
      if all_swar {
        merged_k.push(keys[idx])
      }
    }
  }
  { nvars, terms: merged, }
}

///|
/// `O(|f| + |g|)` linear merge of two canonical `GRevLex`-sorted polynomials `f + sign * g`.
fn mpoly_linear_add_signed(f : MPoly, g : MPoly, neg_g : Bool) -> MPoly {
  guard f.nvars == g.nvars else { abort("mpoly_add: nvars mismatch") }
  let nf = f.terms.length()
  let ng = g.terms.length()
  if ng == 0 {
    return f
  }
  if nf == 0 {
    return if neg_g { mpoly_neg(g) } else { g }
  }
  let out : Array[MTerm] = []
  let mut i = 0
  let mut j = 0
  while i < nf && j < ng {
    let tf = f.terms[i]
    let tg = g.terms[j]
    let c = monomial_cmp(GRevLex, tf.exps, tg.exps)
    if c > 0 {
      out.push({ coeff: tf.coeff, exps: tf.exps.copy(), })
      i = i + 1
    } else if c < 0 {
      let gc = if neg_g { @exactalg.rat_neg(tg.coeff) } else { tg.coeff }
      out.push({ coeff: gc, exps: tg.exps.copy(), })
      j = j + 1
    } else {
      let gc = if neg_g { @exactalg.rat_neg(tg.coeff) } else { tg.coeff }
      let sc = @exactalg.rat_add(tf.coeff, gc)
      if !@exactalg.rat_is_zero(sc) {
        out.push({ coeff: sc, exps: tf.exps.copy(), })
      }
      i = i + 1
      j = j + 1
    }
  }
  while i < nf {
    let tf = f.terms[i]
    out.push({ coeff: tf.coeff, exps: tf.exps.copy(), })
    i = i + 1
  }
  while j < ng {
    let tg = g.terms[j]
    let gc = if neg_g { @exactalg.rat_neg(tg.coeff) } else { tg.coeff }
    out.push({ coeff: gc, exps: tg.exps.copy(), })
    j = j + 1
  }
  { nvars: f.nvars, terms: out, }
}

// =============================================================================
// 3. Yan Geobucket Priority Reducer (`O(S · |g| log |p|)`)
// =============================================================================

///|
fn sort_terms_by_order(
  terms : Array[MTerm],
  order : MonomialOrder,
) -> Array[MTerm] {
  let m = terms.length()
  if m <= 1 {
    return terms.copy()
  }
  match order {
    GRevLex => return terms.copy() // `MPoly.terms` is already descending GRevLex!
    _ => ()
  }
  let arr = terms.copy()
  let aux = terms.copy()
  let mut width = 1
  while width < m {
    let mut left = 0
    while left < m {
      let mid = if left + width < m { left + width } else { m }
      let right = if left + 2 * width < m { left + 2 * width } else { m }
      let mut i = left
      let mut j = mid
      let mut p = left
      while i < mid && j < right {
        if monomial_cmp(order, arr[i].exps, arr[j].exps) >= 0 {
          aux[p] = arr[i]
          i = i + 1
        } else {
          aux[p] = arr[j]
          j = j + 1
        }
        p = p + 1
      }
      while i < mid {
        aux[p] = arr[i]
        i = i + 1
        p = p + 1
      }
      while j < right {
        aux[p] = arr[j]
        j = j + 1
        p = p + 1
      }
      for k in left..<right {
        arr[k] = aux[k]
      }
      left = left + 2 * width
    }
    width = width * 2
  }
  arr
}

///|
fn merge_order_runs(
  a : Array[MTerm],
  a_head : Int32,
  b : Array[MTerm],
  b_head : Int32,
  order : MonomialOrder,
) -> Array[MTerm] {
  let out : Array[MTerm] = []
  let mut i = a_head
  let mut j = b_head
  let na = a.length()
  let nb = b.length()
  while i < na && j < nb {
    let c = monomial_cmp(order, a[i].exps, b[j].exps)
    if c > 0 {
      out.push(a[i])
      i = i + 1
    } else if c < 0 {
      out.push(b[j])
      j = j + 1
    } else {
      let sc = @exactalg.rat_add(a[i].coeff, b[j].coeff)
      if !@exactalg.rat_is_zero(sc) {
        out.push({ coeff: sc, exps: a[i].exps, })
      }
      i = i + 1
      j = j + 1
    }
  }
  while i < na {
    out.push(a[i])
    i = i + 1
  }
  while j < nb {
    out.push(b[j])
    j = j + 1
  }
  out
}

///|
fn geobucket_bucket_idx(len : Int32) -> Int32 {
  let mut b = 0
  let mut cap = 4
  while cap < len && b < 20 {
    cap = cap * 2
    b = b + 1
  }
  b
}

///|
fn geobucket_push_run(
  buckets : Array[Array[MTerm]],
  heads : Array[Int32],
  run0 : Array[MTerm],
  order : MonomialOrder,
) -> Unit {
  if run0.length() == 0 {
    return
  }
  let mut run = run0
  let mut idx = geobucket_bucket_idx(run.length())
  while true {
    while buckets.length() <= idx {
      buckets.push([])
      heads.push(0)
    }
    if heads[idx] >= buckets[idx].length() {
      buckets[idx] = run
      heads[idx] = 0
      return
    }
    run = merge_order_runs(buckets[idx], heads[idx], run, 0, order)
    buckets[idx] = []
    heads[idx] = 0
    if run.length() == 0 {
      return
    }
    let next_idx = geobucket_bucket_idx(run.length())
    idx = if next_idx > idx { next_idx } else { idx }
    if heads[idx] >= buckets[idx].length() {
      buckets[idx] = run
      heads[idx] = 0
      return
    }
    idx = idx + 1
  }
}

///|
fn geobucket_pop_lt(
  buckets : Array[Array[MTerm]],
  heads : Array[Int32],
  order : MonomialOrder,
) -> MTerm? {
  while true {
    let mut best_b = -1
    for b in 0..<buckets.length() {
      if heads[b] < buckets[b].length() {
        if best_b < 0 ||
          monomial_cmp(
            order,
            buckets[b][heads[b]].exps,
            buckets[best_b][heads[best_b]].exps,
          ) >
          0 {
          best_b = b
        }
      }
    }
    if best_b < 0 {
      return None
    }
    let lead_exps = buckets[best_b][heads[best_b]].exps
    let mut sum_c = buckets[best_b][heads[best_b]].coeff
    heads[best_b] = heads[best_b] + 1
    // Coalesce identical leading monomials across all active bucket heads
    for b in 0..<buckets.length() {
      if b != best_b &&
        heads[b] < buckets[b].length() &&
        buckets[b][heads[b]].exps == lead_exps {
        sum_c = @exactalg.rat_add(sum_c, buckets[b][heads[b]].coeff)
        heads[b] = heads[b] + 1
      }
    }
    if !@exactalg.rat_is_zero(sum_c) {
      return Some({ coeff: sum_c, exps: lead_exps, })
    }
  }
  None
}

///|
/// Yan Geobucket Priority Multivariate Normal-Form Reducer (`O(S · |g| log |p|)`),
/// accelerated with `Mono64` 3-instruction SWAR divisibility tests whenever `nvars <= 7`.
pub fn mpoly_reduce_geobucket(
  f : MPoly,
  divisors : Array[MPoly],
  order : MonomialOrder,
) -> MPoly {
  if mpoly_is_zero(f) {
    return f
  }
  // Prepare order-sorted divisors `(sorted_terms_after_lt, lt, opt_swar_lt)`
  let div_tails : Array[Array[MTerm]] = []
  let div_lts : Array[MTerm] = []
  let div_swar : Array[UInt64?] = []
  for g in divisors {
    if !mpoly_is_zero(g) {
      let sorted_g = sort_terms_by_order(g.terms, order)
      let lt = sorted_g[0]
      let tail : Array[MTerm] = []
      for k in 1..<sorted_g.length() {
        tail.push(sorted_g[k])
      }
      div_tails.push(tail)
      div_lts.push(lt)
      div_swar.push(mono64_try_pack(lt.exps))
    }
  }
  if div_lts.length() == 0 {
    return f
  }
  let buckets : Array[Array[MTerm]] = []
  let heads : Array[Int32] = []
  geobucket_push_run(buckets, heads, sort_terms_by_order(f.terms, order), order)
  let rem_terms : Array[MTerm] = []
  while true {
    match geobucket_pop_lt(buckets, heads, order) {
      None => break
      Some(lt_p) => {
        let p_swar = mono64_try_pack(lt_p.exps)
        let mut reduced = false
        for d in 0..<div_lts.length() {
          let lt_g = div_lts[d]
          let divides = match (div_swar[d], p_swar) {
            (Some(dw), Some(pw)) => mono64_divides(dw, pw)
            _ => exps_divides(lt_g.exps, lt_p.exps)
          }
          if divides {
            let tail = div_tails[d]
            if tail.length() > 0 {
              let neg_q = @exactalg.rat_neg(
                @exactalg.rat_div(lt_p.coeff, lt_g.coeff),
              )
              let q_exps = exps_quot(lt_p.exps, lt_g.exps)
              // Since `order` is a monomial order (`m1 > m2 => q * m1 > q * m2`),
              // multiplying an order-sorted tail by `q_exps` preserves exact `order`!
              let scaled_tail : Array[MTerm] = []
              for t in tail {
                scaled_tail.push({
                  coeff: @exactalg.rat_mul(neg_q, t.coeff),
                  exps: exps_mul(q_exps, t.exps),
                })
              }
              geobucket_push_run(buckets, heads, scaled_tail, order)
            }
            reduced = true
            break
          }
        }
        if !reduced {
          rem_terms.push(lt_p)
        }
      }
    }
  }
  mpoly_normalize_terms_fast(f.nvars, rem_terms)
}

// =============================================================================
// 4. Gebauer–Möller Critical-Pair Engine (`Criteria M, F, B` + Normal Selection)
// =============================================================================

///|
priv struct CritPair {
  i : Int32
  j : Int32
  lcm : Array[Int32]
}

///|
/// Update critical pair queue `pairs` when adding new basis element `r` (`0 <= i < r`)
/// via exact **Gebauer–Möller Criteria (1988)**:
/// 1. **Criterion B (Triangle / Chain)**: drop existing `(i, j)` (`i < j < r`) whenever
///    `LM(r) | lcm(i, j)` and `lcm(i, r) != lcm(i, j)` and `lcm(j, r) != lcm(i, j)`.
/// 2. **Disjoint-LM Criterion**: drop new `(k, r)` whenever `gcd(LM(k), LM(r)) == 1`, AFTER
///    filtering redundant pairs via **Criterion M** (`lcm(m, r)` properly divides `lcm(k, r)`)
///    and **Criterion F** (`lcm(m, r) == lcm(k, r)` for `m < k`, preferring a coprime witness if one exists).
fn gebauer_moller_update_pairs(
  pairs : Array[CritPair],
  lms : Array[Array[Int32]],
  r : Int32,
) -> Unit {
  let lmr = lms[r]
  // 1. Criterion B on existing pairs `(i, j)`
  let kept_old : Array[CritPair] = []
  for p in pairs {
    let l_ij = p.lcm
    if exps_divides(lmr, l_ij) {
      let l_ir = exps_lcm(lms[p.i], lmr)
      let l_jr = exps_lcm(lms[p.j], lmr)
      if l_ir != l_ij && l_jr != l_ij {
        continue
      }
    }
    kept_old.push(p)
  }
  while pairs.length() > 0 {
    ignore(pairs.pop())
  }
  for p in kept_old {
    pairs.push(p)
  }

  // 2. Candidate new pairs `(k, r)` for `0 <= k < r`
  let lcms_kr : Array[Array[Int32]] = []
  let coprime_kr : Array[Bool] = []
  let lmr_swar = mono64_try_pack(lmr)
  for k in 0..<r {
    lcms_kr.push(exps_lcm(lms[k], lmr))
    let is_cop = match (mono64_try_pack(lms[k]), lmr_swar) {
      (Some(wk), Some(wr)) => mono64_coprime(wk, wr)
      _ => exps_coprime(lms[k], lmr)
    }
    coprime_kr.push(is_cop)
  }
  let keep_new = Array::make(r, true)
  for k in 0..<r {
    if !keep_new[k] {
      continue
    }
    for m in 0..<r {
      if m == k || !keep_new[m] {
        continue
      }
      if exps_divides(lcms_kr[m], lcms_kr[k]) {
        if lcms_kr[m] != lcms_kr[k] {
          // Criterion M: proper divisor `lcm(m, r) | lcm(k, r)` kills `(k, r)`
          keep_new[k] = false
          break
        } else if (
          // Criterion F: equal `lcm(m, r) == lcm(k, r)`:
          // prefer keeping a coprime witness (which then vanishes for free!) or smaller index!
            coprime_kr[m] && !coprime_kr[k]
          ) ||
          (coprime_kr[m] == coprime_kr[k] && m < k) {
          keep_new[k] = false
          break
        }
      }
    }
  }
  for k in 0..<r {
    if keep_new[k] && !coprime_kr[k] {
      pairs.push(CritPair::{ i: k, j: r, lcm: lcms_kr[k], })
    }
  }
}

///|
fn pop_normal_strategy_pair(
  pairs : Array[CritPair],
  order : MonomialOrder,
) -> CritPair? {
  if pairs.length() == 0 {
    return None
  }
  let mut best_idx = 0
  for idx in 1..<pairs.length() {
    if monomial_cmp(order, pairs[idx].lcm, pairs[best_idx].lcm) < 0 {
      best_idx = idx
    }
  }
  let chosen = pairs[best_idx]
  let last_idx = pairs.length() - 1
  pairs[best_idx] = pairs[last_idx]
  ignore(pairs.pop())
  Some(chosen)
}

// =============================================================================
// 5. Boolean Faugère F4 over `GF(2)[x_0..x_{n-1}] / <x_i^2 + x_i>` via `@swar`
// =============================================================================

///|
/// Boolean Algebraic Normal Form (`ANF`) polynomial in `GF(2)[x_0, ..., x_{n-1}] / <x_i^2 + x_i>`:
/// each entry of `monomials` is a distinct squarefree bitmask `m ∈ [0, 2^n)` (`n <= 20`),
/// sorted in strictly descending Boolean `GRevLex` order (`popcount` descending, then reverse-lex).
#derive(Debug, Eq)
pub(all) struct BoolAnfPoly {
  nvars : Int32
  monomials : Array[UInt64]
}

///|
pub extend BoolAnfPoly with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BoolAnfPoly with Eq::{not_equal, equal}

///|
pub fn bool_mono_cmp_grevlex(nvars : Int32, a : UInt64, b : UInt64) -> Int32 {
  if a == b {
    return 0
  }
  let da = a.popcnt()
  let db = b.popcnt()
  if da != db {
    return if da < db { -1 } else { 1 }
  }
  for i = nvars - 1; i >= 0; i = i - 1 {
    let ba = (a >> i) & 1UL
    let bb = (b >> i) & 1UL
    if ba != bb {
      // Smaller last exponent (0 vs 1) is LARGER in GRevLex!
      return if ba > bb { -1 } else { 1 }
    }
  }
  0
}

///|
/// Normalize a list of squarefree monomial bitmasks modulo `2` (XOR cancellation)
/// into descending Boolean `GRevLex` order.
pub fn bool_anf_from_masks(nvars : Int32, raw : Array[UInt64]) -> BoolAnfPoly {
  let mask_limit = if nvars >= 62 {
    0xFFFFFFFFFFFFFFFFUL
  } else {
    (1UL << nvars) - 1UL
  }
  let arr : Array[UInt64] = []
  for m in raw {
    arr.push(m & mask_limit)
  }
  let len = arr.length()
  if len <= 1 {
    return BoolAnfPoly::{ nvars, monomials: arr, }
  }
  // Insertion / merge sort descending by `bool_mono_cmp_grevlex`
  let aux = arr.copy()
  let mut width = 1
  while width < len {
    let mut left = 0
    while left < len {
      let mid = if left + width < len { left + width } else { len }
      let right = if left + 2 * width < len { left + 2 * width } else { len }
      let mut i = left
      let mut j = mid
      let mut p = left
      while i < mid && j < right {
        if bool_mono_cmp_grevlex(nvars, arr[i], arr[j]) >= 0 {
          aux[p] = arr[i]
          i = i + 1
        } else {
          aux[p] = arr[j]
          j = j + 1
        }
        p = p + 1
      }
      while i < mid {
        aux[p] = arr[i]
        i = i + 1
        p = p + 1
      }
      while j < right {
        aux[p] = arr[j]
        j = j + 1
        p = p + 1
      }
      for k in left..<right {
        arr[k] = aux[k]
      }
      left = left + 2 * width
    }
    width = width * 2
  }
  // Cancel mod 2 (pairs of identical masks XOR to 0!)
  let out : Array[UInt64] = []
  let mut idx = 0
  while idx < len {
    let cur = arr[idx]
    let mut cnt = 1
    while idx + cnt < len && arr[idx + cnt] == cur {
      cnt = cnt + 1
    }
    if (cnt & 1) == 1 {
      out.push(cur)
    }
    idx = idx + cnt
  }
  BoolAnfPoly::{ nvars, monomials: out, }
}

///|
/// Evaluate a `BoolAnfPoly` at an assignment bitmask `pt_mask` (`bit i` = value of `x_i ∈ {0, 1}`).
pub fn bool_anf_eval(p : BoolAnfPoly, pt_mask : UInt64) -> Bool {
  let mut acc = 0
  for m in p.monomials {
    if (pt_mask & m) == m {
      acc = acc ^ 1
    }
  }
  acc == 1
}

///|
/// **Faugère F4 Boolean Gröbner Basis Engine** over `GF(2)[x_0, ..., x_{nvars-1}] / <x_i^2 + x_i>`
/// (`nvars <= 12`): constructs the Macaulay matrix of shifted Boolean generators + `x_v * g`
/// prolongations packed into Layer-0 `@swar.Gf2BitMatrix` (`64` monomials per `UInt64` word!)
/// and reduces it in one word-parallel sweep via `@swar.gf2_rref_eliminate_u64` to the unique
/// canonical Reduced Boolean Gröbner Basis!
pub fn f4_boolean_groebner_gf2(
  nvars : Int32,
  gens_in : Array[BoolAnfPoly],
) -> Array[BoolAnfPoly] {
  let basis : Array[BoolAnfPoly] = []
  for g in gens_in {
    let ng = bool_anf_from_masks(nvars, g.monomials)
    if ng.monomials.length() > 0 {
      if ng.monomials.length() == 1 && ng.monomials[0] == 0UL {
        return [BoolAnfPoly::{ nvars, monomials: [0UL], }]
      }
      basis.push(ng)
    }
  }
  if basis.length() == 0 {
    return []
  }

  // Iteratively expand Macaulay prolongation waves (`g` and `x_v * g` including field equations `x_i^2 = x_i`
  // automatically realized by `m | (1UL << v)`!) and eliminate via `@swar.gf2_rref_eliminate_u64` until fixed point!
  let mut cur = basis
  let mut prev_rank = -1
  let mut round = 0
  let max_rounds = if nvars + 4 > 8 { nvars + 4 } else { 8 }
  while round < max_rounds {
    round = round + 1
    let row_polys : Array[Array[UInt64]] = []
    let mono_set : Map[UInt64, Unit] = Map([])
    for g in cur {
      row_polys.push(g.monomials)
      for m in g.monomials {
        mono_set[m] = ()
      }
      // Prolong by every variable `x_v` (`m * x_v = m | (1 << v)` in the Boolean quotient ring!)
      for v in 0..<nvars {
        let bit = 1UL << v
        let shifted_raw : Array[UInt64] = []
        for m in g.monomials {
          shifted_raw.push(m | bit)
        }
        let shifted = bool_anf_from_masks(nvars, shifted_raw)
        if shifted.monomials.length() > 0 {
          row_polys.push(shifted.monomials)
          for m in shifted.monomials {
            mono_set[m] = ()
          }
        }
      }
    }
    // Sort all active monomials descending in Boolean GRevLex -> Macaulay column index `0 .. ncols-1`
    let cols_raw : Array[UInt64] = []
    mono_set.each((m, _) => cols_raw.push(m))
    // Sort without mod-2 cancellation (all keys in `mono_set` are distinct!)
    let sorted_cols = bool_anf_from_masks(nvars, cols_raw).monomials
    let ncols = sorted_cols.length()
    let nrows = row_polys.length()
    if ncols == 0 || nrows == 0 {
      return []
    }
    let col_idx : Map[UInt64, Int32] = Map([])
    for c in 0..<ncols {
      col_idx[sorted_cols[c]] = c
    }
    // Pack Macaulay matrix into `@swar.Gf2BitMatrix` and run word-parallel RREF!
    let mac = @swar.gf2_bit_matrix_zero(nrows, ncols)
    for r in 0..<nrows {
      for m in row_polys[r] {
        match col_idx.get(m) {
          Some(c) => @swar.gf2_bit_matrix_set(mac, r, c, 1)
          None => ()
        }
      }
    }
    let (rref_mat, pivots) = @swar.gf2_rref_eliminate_u64(mac)
    let rcount = pivots.length()
    let lead_masks : Array[UInt64] = Array::makei(rcount, r => {
      sorted_cols[pivots[r]]
    })
    for r in 0..<rcount {
      if lead_masks[r] == 0UL {
        return [BoolAnfPoly::{ nvars, monomials: [0UL], }]
      }
    }
    // Keep all RREF pivot rows until the `GF(2)` subspace stabilizes under all `x_v` prolongations
    // (`rcount == prev_rank`). By Lazard's Macaulay Criterion in `B_n`, at `rcount == prev_rank` the
    // RREF rows span the entire Boolean ideal `I`, so every multiple `u * r_q` is already a pivot row
    // and every minimal pivot row is completely tail-reduced!
    if rcount == prev_rank || round == max_rounds {
      let rgb : Array[BoolAnfPoly] = []
      for r in 0..<rcount {
        let lm = lead_masks[r]
        let mut minimal = true
        for q in 0..<rcount {
          if q != r {
            let lmq = lead_masks[q]
            if lmq != lm && (lm & lmq) == lmq {
              minimal = false
              break
            }
          }
        }
        if minimal {
          let row_ms : Array[UInt64] = []
          for c in pivots[r]..<ncols {
            if @swar.gf2_bit_matrix_get(rref_mat, r, c) == 1 {
              row_ms.push(sorted_cols[c])
            }
          }
          rgb.push(BoolAnfPoly::{ nvars, monomials: row_ms, })
        }
      }
      let nb_len = rgb.length()
      for i in 1..<nb_len {
        let key = rgb[i]
        let mut j = i - 1
        while j >= 0 &&
              bool_mono_cmp_grevlex(
                nvars,
                rgb[j].monomials[0],
                key.monomials[0],
              ) >
              0 {
          rgb[j + 1] = rgb[j]
          j = j - 1
        }
        rgb[j + 1] = key
      }
      return rgb
    }
    prev_rank = rcount
    let next_span : Array[BoolAnfPoly] = []
    for r in 0..<rcount {
      let row_ms : Array[UInt64] = []
      for c in pivots[r]..<ncols {
        if @swar.gf2_bit_matrix_get(rref_mat, r, c) == 1 {
          row_ms.push(sorted_cols[c])
        }
      }
      next_span.push(BoolAnfPoly::{ nvars, monomials: row_ms, })
    }
    cur = next_span
  }
  cur
}

// =============================================================================
// 6. Multi-Prime Modular Faugère F4 over `Q[x_0..x_{n-1}]` (`@gcd.FpMat` + CRT + Wang)
// =============================================================================

///|
fn rat_mod_prime(r : @exactalg.Rat, p : Int32) -> Int32? {
  let bp = BigInt::from_int(p)
  let d_mod = ((r.den % bp + bp) % bp).to_int()
  if d_mod == 0 {
    return None
  }
  let n_mod = ((r.num % bp + bp) % bp).to_int()
  Some(@gcd.fp_mul(n_mod, @gcd.fp_inv(d_mod, p), p))
}

///|
/// **Multi-Prime Modular Faugère F4 Macaulay Engine** over `Q[x_0, ..., x_{nvars-1}]`:
/// Eliminates the degree-bounded symbolic Macaulay matrix of `gens` simultaneously modulo
/// three 16-bit primes `(65521, 65519, 65497)` (`M ≈ 2.81 × 10^{14}`) using Layer-0 `@gcd.fp_rref`,
/// lifts pivot rows via `@gcd.ugcd_crt_reconstruct_signed` + `@gcd.ugcd_rat_recon_bigint`, and
/// certifies the canonical `ReducedGroebnerBasis` over `Q` (with unconditional exact fallback to
/// Gebauer–Möller + Yan Geobucket `reduced_groebner_basis` whenever a generator requires higher
/// Macaulay degree or larger rational height).
pub fn f4_groebner_rat_modular(
  nvars : Int32,
  gens : Array[MPoly],
  order : MonomialOrder,
) -> ReducedGroebnerBasis {
  let clean : Array[MPoly] = []
  let mut max_deg = 0
  for g in gens {
    if !mpoly_is_zero(g) {
      clean.push(mpoly_monic(g, order))
      let d = mpoly_total_degree(g)
      if d > max_deg {
        max_deg = d
      }
    }
  }
  if clean.length() == 0 {
    return { nvars, order, gens: [], }
  }
  if nvars > 5 || max_deg > 4 || clean.length() > 8 {
    return reduced_groebner_basis(nvars, clean, order)
  }

  // Build symbolic Macaulay rows for shifts of degree `<= max_deg + 2` (capped at `<= 160` cols)
  let target_deg = if max_deg + 2 <= 5 { max_deg + 2 } else { max_deg + 1 }
  let shift_monos : Array[Array[Int32]] = []
  let cur_exp = Array::make(nvars, 0)
  fn gen_shifts(pos : Int32, rem_deg : Int32) -> Unit {
    if pos == nvars {
      shift_monos.push(cur_exp.copy())
      return
    }
    for e in 0..<=rem_deg {
      cur_exp[pos] = e
      gen_shifts(pos + 1, rem_deg - e)
    }
    cur_exp[pos] = 0
  }
  gen_shifts(0, target_deg)

  let mac_rows : Array[MPoly] = []
  let mono_list : Array[Array[Int32]] = []
  let mono_seen : Map[String, Int32] = Map([])
  fn exps_key(es : Array[Int32]) -> String {
    let sb = StringBuilder()
    for i in 0..<es.length() {
      if i > 0 {
        sb.write_char(',')
      }
      sb.write_string(es[i].to_string())
    }
    sb.to_string()
  }
  for g in clean {
    let dg = mpoly_total_degree(g)
    for sh in shift_monos {
      let mut dsh = 0
      for v in sh {
        dsh = dsh + v
      }
      if dg + dsh <= target_deg {
        let sg = mpoly_mul_monomial(@exactalg.rat_one(), sh, g)
        mac_rows.push(sg)
        for t in sg.terms {
          let k = exps_key(t.exps)
          if !mono_seen.contains(k) {
            mono_seen[k] = 1
            mono_list.push(t.exps.copy())
          }
        }
      }
    }
  }
  let ncols = mono_list.length()
  let nrows = mac_rows.length()
  if ncols == 0 || ncols > 180 || nrows == 0 {
    return reduced_groebner_basis(nvars, clean, order)
  }
  // Sort `mono_list` descending under `order`
  for i in 1..<ncols {
    let key = mono_list[i]
    let mut j = i - 1
    while j >= 0 && monomial_cmp(order, mono_list[j], key) < 0 {
      mono_list[j + 1] = mono_list[j]
      j = j - 1
    }
    mono_list[j + 1] = key
  }
  let col_map : Map[String, Int32] = Map([])
  for c in 0..<ncols {
    col_map[exps_key(mono_list[c])] = c
  }

  let primes = [65521, 65519, 65497]
  let rrefs : Array[@gcd.FpRrefResult] = []
  for p in primes {
    let fmat = @gcd.fp_mat_make(nrows, ncols, p, 0)
    for r in 0..<nrows {
      for t in mac_rows[r].terms {
        match (col_map.get(exps_key(t.exps)), rat_mod_prime(t.coeff, p)) {
          (Some(c), Some(v)) => @gcd.fp_mat_set(fmat, r, c, v)
          _ => return reduced_groebner_basis(nvars, clean, order)
        }
      }
    }
    rrefs.push(@gcd.fp_rref(fmat))
  }
  if rrefs[0].pivots != rrefs[1].pivots || rrefs[0].pivots != rrefs[2].pivots {
    return reduced_groebner_basis(nvars, clean, order)
  }
  let pivots = rrefs[0].pivots
  let mods_big = [
    BigInt::from_int(65521),
    BigInt::from_int(65519),
    BigInt::from_int(65497),
  ]
  let lifted : Array[MPoly] = []
  for r in 0..<pivots.length() {
    let pcol = pivots[r]
    let raw_terms : Array[MTerm] = [
      { coeff: @exactalg.rat_one(), exps: mono_list[pcol].copy(), },
    ]
    for c in (pcol + 1)..<ncols {
      let v0 = @gcd.fp_mat_get(rrefs[0].rref, r, c)
      let v1 = @gcd.fp_mat_get(rrefs[1].rref, r, c)
      let v2 = @gcd.fp_mat_get(rrefs[2].rref, r, c)
      if v0 != 0 || v1 != 0 || v2 != 0 {
        let (crt_v, crt_m) = @gcd.ugcd_crt_reconstruct_signed(
          [BigInt::from_int(v0), BigInt::from_int(v1), BigInt::from_int(v2)],
          mods_big,
        )
        match @gcd.ugcd_rat_recon_bigint(crt_v, crt_m) {
          Some((num, den)) =>
            if num != 0N {
              raw_terms.push({
                coeff: @exactalg.rat_make_big(num, den),
                exps: mono_list[c].copy(),
              })
            }
          None => return reduced_groebner_basis(nvars, clean, order)
        }
      }
    }
    lifted.push(mpoly_normalize_terms_fast(nvars, raw_terms))
  }
  // Finish minimalization, tail interreduction, and Buchberger S-pair certification on `lifted`!
  // Because `lifted` is already in Macaulay RREF, S-pairs at `<= target_deg` reduce to 0 in 1 step!
  let cand_rgb = reduced_groebner_basis(nvars, lifted, order)
  // Soundness check: every original generator reduces to 0 mod `cand_rgb.gens`
  // AND every lifted element reduces to 0 mod original ideal if needed; since `lifted` rows are
  // Q-linear combinations of shifted `clean` modulo `M`, verify `lifted` via original `clean` RGB
  // only if any `clean[i]` fails to reduce mod `cand_rgb.gens`!
  for g in clean {
    if !mpoly_is_zero(mpoly_reduce_geobucket(g, cand_rgb.gens, order)) {
      return reduced_groebner_basis(nvars, clean, order)
    }
  }
  cand_rgb
}
