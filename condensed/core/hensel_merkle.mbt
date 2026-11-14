///|
// Federation 6 (`condensed`) — Layer-1 light core, iteration 3:
//
//   A. Solution towers. For a polynomial `f` over `Z` and a base `q`, the root sets
//      `S_n = { x mod q^n : f(x) ≡ 0 }` form an inverse system whose transition maps are
//      usually NOT surjective. Its limit is the profinite set of roots of `f` in `Z_q`.
//      `cond_solution_tower_build` computes the system by lifting roots level by level
//      (cost `O(q * |S_n|)` per level instead of `O(q^n)`), separates the roots with unit
//      derivative (Hensel: exactly one lift at every level, `[T-Hensel-Thread]`) from the
//      singular ones, and extracts the Mittag-Leffler stable images
//      `Im(S_L -> S_n)` as a genuine `CompactProfiniteTower` (`[T-ML-Stable-Image]`), ready
//      for the Nöbeling / solid-duality machinery of `profinite_solid.mbt`.
//   B. Teichmüller lifts: the roots of `x^{q-1} - 1` in `Z_q` form a multiplicative group
//      that reduces bijectively onto `F_q^*` (`[T-Teichmuller]`).
//   C. A Merkle tree over `@gcd.CondInvariantLedger`: one 64-bit root commits to every
//      entry, and membership of a single entry is checked in `O(log n)` hash steps instead
//      of re-walking the whole chain (`[T-Ledger-Merkle]`).
//
// The digests are 64-bit mixing hashes from `@swar`. They give tamper evidence against
// accidental or careless modification; they are not a cryptographic commitment.

// ---------------------------------------------------------------------------
// A. Solution towers and Hensel threads
// ---------------------------------------------------------------------------

///|
/// Root-set inverse system of `f(x) = sum_i coeffs[i] * x^i` modulo `q, q^2, .., q^levels`.
///
/// * `roots[n]` — sorted roots modulo `q^{n+1}`;
/// * `stable_image_sizes[n]` — `|Im(S_levels -> S_{n+1})|`, the roots that survive to the
///   top computed level. This is an upper bound for the number of roots modulo `q^{n+1}`
///   that extend to `Z_q`, and equals it once the system has stabilised;
/// * `unit_derivative_roots` — roots `x mod q` with `f'(x)` a unit modulo `q`. By Hensel's
///   lemma each of them extends to exactly one root in `Z_q`, so this is an exact lower
///   bound for the number of roots in `Z_q`;
/// * `unit_threads_unique` — the uniqueness half of Hensel's lemma, observed at every level.
#derive(Debug, Eq)
pub(all) struct CondSolutionTower {
  q : Int32
  levels : Int32
  coeffs : Array[Int32]
  roots : Array[Array[Int32]]
  stable_image_sizes : Array[Int32]
  unit_derivative_roots : Int32
  unit_threads_unique : Bool
}

///|
pub extend CondSolutionTower with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondSolutionTower with Eq::{not_equal, equal}

///|
/// Horner evaluation of `sum_i coeffs[i] * x^i` modulo `m` (`2 <= m < 2^31`), result in `[0, m)`.
pub fn cond_poly_eval_mod(coeffs : Array[Int32], x : Int32, m : Int32) -> Int32 {
  let m64 = m.to_int64()
  let x64 = (x.to_int64() % m64 + m64) % m64
  let mut acc = 0L
  for i in 0..<coeffs.length() {
    let c = (coeffs[coeffs.length() - 1 - i].to_int64() % m64 + m64) % m64
    acc = (acc * x64 + c) % m64
  }
  acc.to_int()
}

///|
fn cond_int_gcd(a : Int32, b : Int32) -> Int32 {
  let mut x = if a < 0 { -a } else { a }
  let mut y = if b < 0 { -b } else { b }
  while y != 0 {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
/// Build the solution tower of `f` over `Z_q` down to depth `levels`.
///
/// Returns `None` when `q < 2`, `levels < 1`, `q^levels` does not fit in 30 bits, or some
/// level has more than `4096` roots (for instance the zero polynomial), so that the result
/// is never silently truncated.
pub fn cond_solution_tower_build(
  coeffs : Array[Int32],
  q : Int32,
  levels : Int32,
) -> CondSolutionTower? {
  if q < 2 || levels < 1 {
    return None
  }
  let moduli : Array[Int32] = []
  let mut m = 1L
  for _ in 0..<levels {
    m = m * q.to_int64()
    if m > 1073741824L {
      return None
    }
    moduli.push(m.to_int())
  }
  let deriv : Array[Int32] = Array::makei(
    if coeffs.length() > 1 {
      coeffs.length() - 1
    } else {
      0
    },
    i => {
      let q64 = q.to_int64()
      let c = (coeffs[i + 1].to_int64() % q64 + q64) % q64
      (c * (i + 1).to_int64() % q64).to_int()
    },
  )
  let cap = 4096
  let roots : Array[Array[Int32]] = []
  let level0 : Array[Int32] = []
  for x in 0..<q {
    if cond_poly_eval_mod(coeffs, x, q) == 0 {
      level0.push(x)
    }
  }
  if level0.length() > cap {
    return None
  }
  roots.push(level0)
  // parent_of[n][i] = index in roots[n] of the reduction of roots[n + 1][i].
  let parent_of : Array[Array[Int32]] = []
  for n in 1..<levels {
    let prev = roots[n - 1]
    let lifted : Array[Int32] = []
    let parents : Array[Int32] = []
    // Enumerate `x + t * q^n` with `t` outermost so that the lifts come out sorted.
    for t in 0..<q {
      for i in 0..<prev.length() {
        let cand = prev[i] + t * moduli[n - 1]
        if cond_poly_eval_mod(coeffs, cand, moduli[n]) == 0 {
          lifted.push(cand)
          parents.push(i)
        }
      }
    }
    if lifted.length() > cap {
      return None
    }
    roots.push(lifted)
    parent_of.push(parents)
  }

  // Stable images: mark top-level roots, then push the marks down.
  let alive : Array[Array[Bool]] = Array::makei(levels, n => {
    Array::make(roots[n].length(), n == levels - 1)
  })
  for step in 1..<levels {
    let n = levels - step
    for i in 0..<roots[n].length() {
      if alive[n][i] {
        alive[n - 1][parent_of[n - 1][i]] = true
      }
    }
  }
  let stable_sizes : Array[Int32] = Array::makei(levels, n => {
    let mut cnt = 0
    for flag in alive[n] {
      if flag {
        cnt = cnt + 1
      }
    }
    cnt
  })

  // Hensel threads: a root with unit derivative has exactly one lift per level.
  let mut unit_roots = 0
  let mut unique = true
  let is_unit : Array[Bool] = Array::makei(roots[0].length(), i => {
    cond_int_gcd(cond_poly_eval_mod(deriv, roots[0][i], q), q) == 1
  })
  for flag in is_unit {
    if flag {
      unit_roots = unit_roots + 1
    }
  }
  // base_of[i] = index in roots[0] of the residue of the current level's root i.
  let mut base_of : Array[Int32] = Array::makei(roots[0].length(), i => i)
  for n in 1..<levels {
    let next_base : Array[Int32] = Array::makei(roots[n].length(), i => {
      base_of[parent_of[n - 1][i]]
    })
    let per_base = Array::make(roots[0].length(), 0)
    for b in next_base {
      per_base[b] = per_base[b] + 1
    }
    for b in 0..<per_base.length() {
      if is_unit[b] && per_base[b] != 1 {
        unique = false
      }
    }
    base_of = next_base
  }
  Some(CondSolutionTower::{
    q,
    levels,
    coeffs: coeffs.copy(),
    roots,
    stable_image_sizes: stable_sizes,
    unit_derivative_roots: unit_roots,
    unit_threads_unique: unique,
  })
}

///|
/// Per-level Mittag-Leffler defect `|S_n| - |Im(S_L -> S_n)|`: the roots modulo `q^n` that
/// are obstructed before depth `L`. A nonzero entry is a concrete non-surjective transition.
pub fn cond_solution_tower_ml_defect(t : CondSolutionTower) -> Array[Int32] {
  Array::makei(t.levels, n => t.roots[n].length() - t.stable_image_sizes[n])
}

///|
/// `[T-ML-Stable-Image]` The tower of stable images `Im(S_L -> S_n)` with the restricted
/// reduction maps. Unlike the raw root sets, its transitions are surjective by construction,
/// so it is a valid profinite tower. Returns `None` when there is no root at the top level
/// (the limit is empty, which `CompactProfiniteTower` cannot represent).
pub fn cond_solution_tower_stable(
  t : CondSolutionTower,
) -> CompactProfiniteTower? {
  let top = t.levels - 1
  if t.roots[top].length() == 0 {
    return None
  }
  let moduli : Array[Int32] = []
  let mut m = 1
  for _ in 0..<t.levels {
    m = m * t.q
    moduli.push(m)
  }
  // The stable roots at level n are exactly the distinct residues of the top-level roots.
  let stable : Array[Array[Int32]] = Array::makei(t.levels, n => {
    let seen : Array[Int32] = []
    for x in t.roots[top] {
      let r = x % moduli[n]
      if !seen.contains(r) {
        seen.push(r)
      }
    }
    seen.sort()
    seen
  })
  let sizes : Array[Int32] = stable.map(s => s.length())
  let surj : Array[Array[Int32]] = []
  for n in 0..<top {
    surj.push(
      stable[n + 1].map(x => {
        let r = x % moduli[n]
        let mut idx = 0
        for i in 0..<stable[n].length() {
          if stable[n][i] == r {
            idx = i
            break
          }
        }
        idx
      }),
    )
  }
  Some({ sizes, surj, })
}

// ---------------------------------------------------------------------------
// B. Teichmüller lifts
// ---------------------------------------------------------------------------

///|
/// `[T-Teichmuller]` For a prime `q`, the roots of `x^{q-1} - 1` modulo `q^levels`:
/// there are exactly `q - 1` of them, they are closed under multiplication, they reduce
/// bijectively onto `F_q^*`, and each satisfies `w^q = w`. Returns the roots, or `None`
/// when one of these properties fails or the tower cannot be built.
pub fn cond_teichmuller_lifts(q : Int32, levels : Int32) -> Array[Int32]? {
  if q < 2 || q > 64 {
    return None
  }
  let coeffs = Array::make(q, 0)
  coeffs[0] = -1
  coeffs[q - 1] = 1
  match cond_solution_tower_build(coeffs, q, levels) {
    None => None
    Some(t) => {
      let top = t.roots[levels - 1]
      if top.length() != q - 1 ||
        t.unit_derivative_roots != q - 1 ||
        !t.unit_threads_unique {
        return None
      }
      let mut modulus = 1L
      for _ in 0..<levels {
        modulus = modulus * q.to_int64()
      }
      let residues : Array[Int32] = []
      for i in 0..<top.length() {
        let r = top[i] % q
        if r == 0 || residues.contains(r) {
          return None
        }
        residues.push(r)
        let w = top[i].to_int64()
        let mut pw = 1L
        for _ in 0..<q {
          pw = pw * w % modulus
        }
        if pw != w {
          return None
        }
        for j in 0..<top.length() {
          let prod = (w * top[j].to_int64() % modulus).to_int()
          if !top.contains(prod) {
            return None
          }
        }
      }
      Some(top)
    }
  }
}

// ---------------------------------------------------------------------------
// C. Merkle commitment over the invariant ledger
// ---------------------------------------------------------------------------

///|
/// Leaf digest: binds every field of the entry, not only its chained hash.
fn cond_ledger_leaf_digest(e : @gcd.CondLedgerEntry) -> UInt64 {
  let words : Array[UInt64] = [
    e.seq.to_int64().reinterpret_as_uint64(),
    e.kind.to_int64().reinterpret_as_uint64(),
    e.values.length().to_int64().reinterpret_as_uint64(),
  ]
  for v in e.values {
    words.push(v.to_int64().reinterpret_as_uint64())
  }
  words.push(e.parents.length().to_int64().reinterpret_as_uint64())
  for p in e.parents {
    words.push(p.to_int64().reinterpret_as_uint64())
  }
  words.push(e.prev_hash)
  words.push(e.hash)
  @swar.swar_merkle_seq64(0x4C, words)
}

///|
/// One level up: pair neighbours, promote an unpaired last node unchanged.
fn cond_merkle_level_up(level : Array[UInt64]) -> Array[UInt64] {
  let up : Array[UInt64] = []
  let mut i = 0
  while i + 1 < level.length() {
    up.push(@swar.swar_merkle_node64(0x4E, level[i], level[i + 1]))
    i = i + 2
  }
  if i < level.length() {
    up.push(level[i])
  }
  up
}

///|
/// Seal a subtree root together with the leaf count, so that trees of different sizes
/// cannot share a root through the promotion rule.
fn cond_merkle_seal(top : UInt64, n : Int32) -> UInt64 {
  @swar.swar_merkle_node64(0x52, top, n.to_int64().reinterpret_as_uint64())
}

///|
/// `[T-Ledger-Merkle]` Merkle root committing to all entries of `l` (and to their number).
pub fn cond_ledger_merkle_root(l : @gcd.CondInvariantLedger) -> UInt64 {
  let n = l.entries.length()
  if n == 0 {
    return cond_merkle_seal(0UL, 0)
  }
  let mut level : Array[UInt64] = l.entries.map(cond_ledger_leaf_digest)
  while level.length() > 1 {
    level = cond_merkle_level_up(level)
  }
  cond_merkle_seal(level[0], n)
}

///|
/// Sibling path for entry `idx`, bottom-up (`<= ceil(log2 n)` digests). `None` if out of range.
pub fn cond_ledger_inclusion_proof(
  l : @gcd.CondInvariantLedger,
  idx : Int32,
) -> Array[UInt64]? {
  let n = l.entries.length()
  if idx < 0 || idx >= n {
    return None
  }
  let proof : Array[UInt64] = []
  let mut level : Array[UInt64] = l.entries.map(cond_ledger_leaf_digest)
  let mut pos = idx
  while level.length() > 1 {
    let sib = pos ^ 1
    if sib < level.length() {
      proof.push(level[sib])
    }
    level = cond_merkle_level_up(level)
    pos = pos / 2
  }
  Some(proof)
}

///|
/// Check that `entry` is the `entry.seq`-th of the `n` entries committed to by `root`,
/// using only the sibling path: `O(log n)` hash steps and no access to the ledger.
pub fn cond_ledger_verify_inclusion(
  root : UInt64,
  n : Int32,
  entry : @gcd.CondLedgerEntry,
  proof : Array[UInt64],
) -> Bool {
  if entry.seq < 0 || entry.seq >= n {
    return false
  }
  let mut acc = cond_ledger_leaf_digest(entry)
  let mut pos = entry.seq
  let mut size = n
  let mut used = 0
  while size > 1 {
    let sib = pos ^ 1
    if sib < size {
      if used >= proof.length() {
        return false
      }
      acc = if pos % 2 == 0 {
        @swar.swar_merkle_node64(0x4E, acc, proof[used])
      } else {
        @swar.swar_merkle_node64(0x4E, proof[used], acc)
      }
      used = used + 1
    }
    pos = pos / 2
    size = (size + 1) / 2
  }
  used == proof.length() && cond_merkle_seal(acc, n) == root
}

// ---------------------------------------------------------------------------
// Health probe for iteration 3
// ---------------------------------------------------------------------------

///|
/// Laws of iteration 3 of `condensed/core`.
pub fn cond_check_hensel_merkle_laws() -> Bool {
  // A1. sqrt(2) exists in Z_7 (two Hensel threads, ten levels deep) and not in Z_5.
  match
    (
      cond_solution_tower_build([-2, 0, 1], 7, 10),
      cond_solution_tower_build([-2, 0, 1], 5, 6),
    ) {
    (Some(z7), Some(z5)) => {
      if z7.unit_derivative_roots != 2 || !z7.unit_threads_unique {
        return false
      }
      for n in 0..<10 {
        if z7.roots[n].length() != 2 || z7.stable_image_sizes[n] != 2 {
          return false
        }
      }
      // The two roots are negatives of each other and really square to 2 modulo 7^10.
      let top = z7.roots[9]
      let m = 282475249L
      if top[0].to_int64() + top[1].to_int64() != m ||
        top[0].to_int64() * top[0].to_int64() % m != 2L {
        return false
      }
      if z5.roots[0].length() != 0 || cond_solution_tower_stable(z5) != None {
        return false
      }
    }
    _ => return false
  }
  // A2. x^2 over Z_3: |S_n| = 3^{floor(n/2)} grows, yet the only root in Z_3 is 0. The raw
  //     system is not surjective; the stable-image tower is, and at depth 1 it is a point.
  match cond_solution_tower_build([0, 0, 1], 3, 6) {
    Some(sq) => {
      if sq.roots.map(r => r.length()) != [1, 3, 3, 9, 9, 27] ||
        sq.unit_derivative_roots != 0 ||
        sq.stable_image_sizes != [1, 1, 1, 3, 9, 27] ||
        cond_solution_tower_ml_defect(sq) != [0, 2, 2, 6, 0, 0] {
        return false
      }
      match cond_solution_tower_stable(sq) {
        Some(st) =>
          if st.sizes != [1, 1, 1, 3, 9, 27] ||
            !cond_prof_valid(compact_tower_to_cond_profinite(st, 5)) {
            return false
          }
        None => return false
      }
    }
    None => return false
  }
  // A3. Idempotents x^2 = x: two in Z_5, four in "Z_6" = Z_2 x Z_3 (base 6 is not a prime,
  //     and the tower sees the product decomposition). The stable tower of the latter is
  //     a 4-point profinite set whose function ring has a unimodular Nöbeling basis.
  match
    (
      cond_solution_tower_build([0, -1, 1], 5, 5),
      cond_solution_tower_build([0, -1, 1], 6, 5),
    ) {
    (Some(e5), Some(e6)) => {
      if e5.stable_image_sizes != [2, 2, 2, 2, 2] ||
        e6.stable_image_sizes != [4, 4, 4, 4, 4] ||
        e6.unit_derivative_roots != 4 ||
        !e6.unit_threads_unique {
        return false
      }
      match cond_solution_tower_stable(e6) {
        Some(st) => if !verify_nobeling_free_solid_duality(st) { return false }
        None => return false
      }
    }
    _ => return false
  }
  // A4. Guard rails: the zero polynomial and oversized moduli are refused.
  if cond_solution_tower_build([0], 5, 8) != None ||
    cond_solution_tower_build([1, 1], 7, 12) != None ||
    cond_solution_tower_build([1, 1], 1, 3) != None {
    return false
  }
  // B. Teichmüller lifts in Z_5 and Z_7; i = sqrt(-1) is one of those in Z_5.
  match (cond_teichmuller_lifts(5, 6), cond_teichmuller_lifts(7, 5)) {
    (Some(w5), Some(w7)) => {
      let m5 = 15625L
      let mut has_i = false
      for w in w5 {
        if (w.to_int64() * w.to_int64() + 1L) % m5 == 0L {
          has_i = true
        }
      }
      if !has_i || w5.length() != 4 || w7.length() != 6 {
        return false
      }
    }
    _ => return false
  }
  // C. Merkle commitment: every entry of an 11-entry ledger (odd sizes exercise the
  //    promotion rule) verifies with at most 4 siblings; tampering, a wrong position, a
  //    truncated path and a stale root are all rejected.
  let mut ledger = @gcd.cond_ledger_new()
  for i in 0..<11 {
    ledger = @gcd.cond_ledger_append(ledger, i % 3, [i, i * i, 7 - i], [i / 2])
  }
  let root = cond_ledger_merkle_root(ledger)
  for i in 0..<11 {
    match cond_ledger_inclusion_proof(ledger, i) {
      Some(proof) => {
        let e = ledger.entries[i]
        if proof.length() > 4 ||
          !cond_ledger_verify_inclusion(root, 11, e, proof) {
          return false
        }
        let forged = @gcd.CondLedgerEntry::{ ..e, values: [i, i * i, 8 - i], }
        let moved = @gcd.CondLedgerEntry::{ ..e, seq: (i + 1) % 11, }
        if cond_ledger_verify_inclusion(root, 11, forged, proof) ||
          cond_ledger_verify_inclusion(root, 11, moved, proof) ||
          cond_ledger_verify_inclusion(root, 12, e, proof) {
          return false
        }
        if proof.length() > 0 {
          let short = Array::makei(proof.length() - 1, k => proof[k])
          if cond_ledger_verify_inclusion(root, 11, e, short) {
            return false
          }
        }
      }
      None => return false
    }
  }
  let grown = @gcd.cond_ledger_append(ledger, 2, [1], [])
  cond_ledger_inclusion_proof(ledger, 11) == None &&
  cond_ledger_merkle_root(grown) != root &&
  cond_ledger_merkle_root(@gcd.cond_ledger_new()) != root
}
