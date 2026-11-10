///|
/// Zero-dependency FNV-1a 64-bit Digest-Chain & Exact `Z`-Nullspace Invariant Ledger (`@gcd`, Layer 0).

///|
/// Immutable entry in the Persistent Invariant-Deriving Ledger (`kind`: 0=obs, 1=derived_law, 2=theorem).
#derive(Debug, Eq)
pub(all) struct CondLedgerEntry {
  seq : Int32
  kind : Int32
  values : Array[Int32]
  parents : Array[Int32]
  prev_hash : UInt64
  hash : UInt64
}

///|
pub extend CondLedgerEntry with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondLedgerEntry with Eq::{not_equal, equal}

///|
/// Hash-chained persistent ledger capable of automatically deriving exact `Z`-linear
/// conservation laws (`ker_Z(observation_rows)`) and auditing them against provenance.
#derive(Debug, Eq)
pub(all) struct CondInvariantLedger {
  entries : Array[CondLedgerEntry]
  tip : UInt64
}

///|
pub extend CondInvariantLedger with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondInvariantLedger with Eq::{not_equal, equal}

///|
fn ledger_fnv1a_mix(h : UInt64, v : UInt64) -> UInt64 {
  (h ^ v) * 1099511628211UL
}

///|
fn hash_ledger_entry(
  seq : Int32,
  kind : Int32,
  values : Array[Int32],
  parents : Array[Int32],
  prev : UInt64,
) -> UInt64 {
  let mut h = 14695981039346656037UL
  h = ledger_fnv1a_mix(h, seq.to_uint64())
  h = ledger_fnv1a_mix(h, kind.to_uint64())
  h = ledger_fnv1a_mix(h, 0xFF00UL)
  for v in values {
    h = ledger_fnv1a_mix(h, v.to_uint64())
  }
  h = ledger_fnv1a_mix(h, 0xFF01UL)
  for p in parents {
    h = ledger_fnv1a_mix(h, p.to_uint64())
  }
  h = ledger_fnv1a_mix(h, prev)
  h
}

///|
pub fn cond_ledger_new() -> CondInvariantLedger {
  CondInvariantLedger::{ entries: [], tip: 0UL, }
}

///|
pub fn cond_ledger_append(
  l : CondInvariantLedger,
  kind : Int32,
  values : Array[Int32],
  parents : Array[Int32],
) -> CondInvariantLedger {
  let seq = l.entries.length()
  let h = hash_ledger_entry(seq, kind, values, parents, l.tip)
  let next_entries = l.entries.copy()
  next_entries.push(CondLedgerEntry::{
    seq,
    kind,
    values: values.copy(),
    parents: parents.copy(),
    prev_hash: l.tip,
    hash: h,
  })
  CondInvariantLedger::{ entries: next_entries, tip: h, }
}

///|
pub fn cond_ledger_verify(l : CondInvariantLedger) -> Bool {
  let mut expected_prev = 0UL
  for i in 0..<l.entries.length() {
    let e = l.entries[i]
    if e.seq != i || e.prev_hash != expected_prev {
      return false
    }
    let h = hash_ledger_entry(e.seq, e.kind, e.values, e.parents, e.prev_hash)
    if e.hash != h {
      return false
    }
    expected_prev = h
  }
  expected_prev == l.tip
}

///|
/// Automatically derive exact `Z`-nullspace conservation laws from all `kind == 0`
/// observation rows in `l` (`sum_j coeff_j * obs_j == 0`) and append them as `kind == 1` entries.
pub fn cond_ledger_derive_invariants(
  l : CondInvariantLedger,
) -> CondInvariantLedger {
  let obs_rows : Array[Array[Int32]] = []
  let parent_ids : Array[Int32] = []
  for e in l.entries {
    if e.kind == 0 {
      obs_rows.push(e.values)
      parent_ids.push(e.seq)
    }
  }
  if obs_rows.length() == 0 {
    return l
  }
  let zmat = zmat_from_int_rows(obs_rows)
  let null_vecs = ugcd_z_nullspace_basis(zmat)
  let mut cur = l
  for nv in null_vecs {
    let coeff_ints : Array[Int32] = []
    for c in nv {
      coeff_ints.push(c.to_int())
    }
    cur = cond_ledger_append(cur, 1, coeff_ints, parent_ids)
  }
  cur
}

///|
/// Audit every `kind == 1` derived conservation law against ALL of its parent `kind == 0` rows.
pub fn cond_ledger_audit_laws(l : CondInvariantLedger) -> (Int32, Int32) {
  if !cond_ledger_verify(l) {
    return (0, 1)
  }
  let mut passed = 0
  let mut failed = 0
  for e in l.entries {
    if e.kind == 1 {
      let mut ok = e.parents.length() > 0
      for pid in e.parents {
        if pid < 0 || pid >= l.entries.length() {
          ok = false
        } else {
          let row = l.entries[pid].values
          if row.length() != e.values.length() {
            ok = false
          } else {
            let mut dot = 0
            for j in 0..<row.length() {
              dot = dot + row[j] * e.values[j]
            }
            if dot != 0 {
              ok = false
            }
          }
        }
      }
      if ok {
        passed = passed + 1
      } else {
        failed = failed + 1
      }
    }
  }
  (passed, failed)
}

///|
/// Arbitrary-precision Wang–Pan–collins Euclidean Rational Reconstruction (`@gcd`, Layer 0):
/// Given `rem0 mod mod_m` (`mod_m > 2`), recovers the unique reduced `(num, den)` with `den > 0`,
/// `gcd(|num|, den) = 1`, `num ≡ rem0 * den (mod mod_m)`, and `2 * num^2 < mod_m`, `2 * den^2 < mod_m`
/// whenever such a rational exists.
pub fn ugcd_rat_recon_bigint(
  rem0 : BigInt,
  mod_m : BigInt,
) -> (BigInt, BigInt)? {
  if mod_m <= 2N {
    return Some((rem0, 1N))
  }
  let rem = (rem0 % mod_m + mod_m) % mod_m
  if rem == 0N {
    return Some((0N, 1N))
  }
  let mut r0 = mod_m
  let mut t0 = 0N
  let mut r1 = rem
  let mut t1 = 1N
  while 2N * r1 * r1 >= mod_m {
    let q = r0 / r1
    let r2 = r0 - q * r1
    let t2 = t0 - q * t1
    r0 = r1
    t0 = t1
    r1 = r2
    t1 = t2
  }
  let abs_t = if t1 < 0N { -t1 } else { t1 }
  if abs_t == 0N || 2N * abs_t * abs_t >= mod_m {
    return None
  }
  let num = if t1 < 0N { -r1 } else { r1 }
  let g = ugcd_bigint_gcd(if num < 0N { -num } else { num }, abs_t)
  if g != 1N {
    return None
  }
  Some((num, abs_t))
}
