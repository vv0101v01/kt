// ===========================================================================
// §4.3 — RFC 8032 Ed25519 BFT Quorum + WAL + Tarjan SCC Atomic MVCC Hot-Load
// ===========================================================================

///|
/// Cryptographic RFC 8032 Ed25519 `2f+1`-of-`3f+1` BFT Quorum Certificate & WAL Commit Report.
pub(all) struct BftEd25519WalReport {
  n_validators : Int32
  quorum_required : Int32
  valid_signatures : Int32
  forged_signature_rejected : Bool
  wal_committed_and_recovered : Bool
  condensed_ledger_verified : Bool
} derive(Debug, Eq)

///|
pub extend BftEd25519WalReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BftEd25519WalReport with Eq::{not_equal, equal}

///|
/// Execute a cryptographic `N = 4` (`f = 1`, quorum `Q = 3`) BFT commit round:
///   1. Generate 4 deterministic RFC 8032 Ed25519 validator keypairs;
///   2. Honest validators `{0, 1, 2}` sign canonical SHA-256 commit payload while
///      Byzantine validator `3` signs an equivocating payload (verified REJECTED against commit msg);
///   3. Once `>= 3` valid `Ed25519Signature`s verify against validator public keys,
///      atomically commit the payload + quorum certificate into `ArtifactWalStore`,
///      re-open/recover from crash-consistent WAL bytes, and anchor the digest in `@condensed.CondInvariantLedger`!
pub fn bft_ed25519_quorum_commit_to_wal() -> BftEd25519WalReport {
  let kps : Array[Ed25519Keypair] = []
  for vid in 0..<4 {
    let seed : Array[Int32] = []
    for b in 0..<32 {
      seed.push(((vid + 1) * 37 + b * 13) & 0xff)
    }
    match ed25519_keypair_from_seed(seed) {
      Some(kp) => kps.push(kp)
      None =>
        return BftEd25519WalReport::{
          n_validators: 4,
          quorum_required: 3,
          valid_signatures: 0,
          forged_signature_rejected: false,
          wal_committed_and_recovered: false,
          condensed_ledger_verified: false,
        }
    }
  }
  let commit_msg = crypto_sha256([0x42, 0x46, 0x54, 0x01, 0x21])
  let equiv_msg = crypto_sha256([0x42, 0x46, 0x54, 0x01, 0xFF])

  let mut valid_sigs = 0
  for vid in 0..<3 {
    match ed25519_sign(kps[vid], commit_msg) {
      Some(sig) =>
        if ed25519_verify(kps[vid].public_key, commit_msg, sig) {
          valid_sigs = valid_sigs + 1
        }
      None => ()
    }
  }
  // Validator 3 equivocates (signs equiv_msg); verify it is rejected against commit_msg!
  let forged_rejected = match ed25519_sign(kps[3], equiv_msg) {
    Some(bad_sig) => !ed25519_verify(kps[3].public_key, commit_msg, bad_sig)
    None => false
  }

  // Commit to crash-durable `ArtifactWalStore` iff `valid_sigs >= 3`
  let mem_store = artifact_memory_byte_store_new()
  let mut wal_ok = false
  if valid_sigs >= 3 {
    match artifact_wal_store_open(mem_store) {
      Some((wal, _)) =>
        match artifact_wal_begin_tx(wal) {
          Some(_) =>
            if artifact_wal_put(wal, "bft/slot_1", commit_msg) &&
              artifact_wal_commit_tx(wal) {
              // Simulate restart: reopen WAL on underlying byte store and verify durable payload!
              match artifact_wal_store_open(mem_store) {
                Some((wal2, _)) => {
                  let bs = artifact_wal_byte_store(wal2)
                  wal_ok = (bs.read)("bft/slot_1") == Some(commit_msg)
                }
                None => ()
              }
            }
          None => ()
        }
      None => ()
    }
  }

  // Anchor quorum vote vector in `@condensed.CondInvariantLedger`
  let mut led = @condensed.cond_ledger_new()
  led = @condensed.cond_ledger_append(
    led,
    2,
    [4, 3, valid_sigs, commit_msg[0]],
    [],
  )
  let led_ok = @condensed.cond_ledger_verify(led)

  BftEd25519WalReport::{
    n_validators: 4,
    quorum_required: 3,
    valid_signatures: valid_sigs,
    forged_signature_rejected: forged_rejected,
    wal_committed_and_recovered: wal_ok,
    condensed_ledger_verified: led_ok,
  }
}

///|
/// Tarjan Strongly Connected Components (SCC) + Atomic Multi-Version Concurrency
/// Control (`MVCC`) Snapshot Store for Cyclic Module Hot-Swapping (Boundary §4.3).
pub(all) struct HotLoadMvccSnapshot {
  epoch : Int32
  modules : Array[(String, Int32)]
  scc_groups : Array[Array[String]]
} derive(Debug, Eq)

///|
pub extend HotLoadMvccSnapshot with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadMvccSnapshot with Eq::{not_equal, equal}

///|
pub(all) struct HotLoadMvccStore {
  snapshots : Array[HotLoadMvccSnapshot]
} derive(Debug, Eq)

///|
pub extend HotLoadMvccStore with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend HotLoadMvccStore with Eq::{not_equal, equal}

///|
/// Exact `O(V + E)` Tarjan Strongly Connected Components algorithm on directed graph
/// `(names, edges_from_u_to_dep_v)`: returns SCCs in dependency-first (reverse topological)
/// order so every dependency SCC is updated atomically BEFORE its dependents!
pub fn hot_load_tarjan_scc(
  names : Array[String],
  adj : Array[Array[Int32]],
) -> Array[Array[String]] {
  let n = names.length()
  let index_of : Array[Int32] = []
  let lowlink : Array[Int32] = []
  let on_stack : Array[Bool] = []
  for _ in 0..<n {
    index_of.push(-1)
    lowlink.push(-1)
    on_stack.push(false)
  }
  let stack : Array[Int32] = []
  let sccs : Array[Array[String]] = []
  let timer : Array[Int32] = [0]

  fn strongconnect(
    v : Int32,
    names : Array[String],
    adj : Array[Array[Int32]],
    index_of : Array[Int32],
    lowlink : Array[Int32],
    on_stack : Array[Bool],
    stack : Array[Int32],
    sccs : Array[Array[String]],
    timer : Array[Int32],
  ) -> Unit {
    index_of[v] = timer[0]
    lowlink[v] = timer[0]
    timer[0] = timer[0] + 1
    stack.push(v)
    on_stack[v] = true

    if v < adj.length() {
      for w in adj[v] {
        if w >= 0 && w < n {
          if index_of[w] < 0 {
            strongconnect(
              w, names, adj, index_of, lowlink, on_stack, stack, sccs, timer,
            )
            if lowlink[w] < lowlink[v] {
              lowlink[v] = lowlink[w]
            }
          } else if on_stack[w] {
            if index_of[w] < lowlink[v] {
              lowlink[v] = index_of[w]
            }
          }
        }
      }
    }

    if lowlink[v] == index_of[v] {
      let comp : Array[String] = []
      let mut done = false
      while !done && stack.length() > 0 {
        guard stack.pop() is Some(w) else { break }
        on_stack[w] = false
        comp.push(names[w])
        if w == v {
          done = true
        }
      }
      sccs.push(comp)
    }
  }

  for v in 0..<n {
    if index_of[v] < 0 {
      strongconnect(
        v, names, adj, index_of, lowlink, on_stack, stack, sccs, timer,
      )
    }
  }
  sccs
}

///|
/// Read module version from pinned immutable MVCC `epoch` snapshot (`O(N)` lock-free read;
/// never torn by concurrent writers committing `epoch + 1`!).
pub fn hot_load_mvcc_read(
  store : HotLoadMvccStore,
  epoch : Int32,
  mod_name : String,
) -> Int32? {
  for snap in store.snapshots {
    if snap.epoch == epoch {
      for pair in snap.modules {
        if pair.0 == mod_name {
          return Some(pair.1)
        }
      }
    }
  }
  None
}

///|
/// Atomically commit a mutually-recursive SCC update (`updates`) as a new immutable MVCC
/// epoch snapshot iff `typecheck_passes` is true (rolling back with zero side effects on failure!).
pub fn hot_load_mvcc_commit_atomic(
  store : HotLoadMvccStore,
  names : Array[String],
  adj : Array[Array[Int32]],
  updates : Array[(String, Int32)],
  typecheck_passes : Bool,
) -> (HotLoadMvccStore, Bool) {
  if !typecheck_passes || store.snapshots.length() == 0 {
    return (store, false)
  }
  let latest = store.snapshots[store.snapshots.length() - 1]
  let next_mods = latest.modules.copy()
  for upd in updates {
    let mut replaced = false
    for i in 0..<next_mods.length() {
      if next_mods[i].0 == upd.0 {
        next_mods[i] = upd
        replaced = true
        break
      }
    }
    if !replaced {
      next_mods.push(upd)
    }
  }
  let sccs = hot_load_tarjan_scc(names, adj)
  let next_snap = HotLoadMvccSnapshot::{
    epoch: latest.epoch + 1,
    modules: next_mods,
    scc_groups: sccs,
  }
  let next_snaps = store.snapshots.copy()
  next_snaps.push(next_snap)
  (HotLoadMvccStore::{ snapshots: next_snaps, }, true)
}
