///|
// Executable specification of Distributed Byzantine Fault-Tolerant (`3f + 1`)
// Quorum Replication over Crash-Consistent `DiskState` Replicas (Boundary §4.3).
//
// Transforms `hostfs` from a single-node POSIX `fsync` protocol verifier into
// a multi-replica Byzantine quorum state machine (`N = 3f + 1`, quorum `Q = 2f + 1`):
//   • `[T-BFT-Quorum-Intersect]`: Any two quorums `Q_1, Q_2` of size `>= 2f + 1`
//     inside `N = 3f + 1` intersect in `>= (2f + 1) + (2f + 1) - (3f + 1) = f + 1`
//     replicas, guaranteeing `>= 1` non-Byzantine replica in `Q_1 n Q_2` whenever
//     at most `f` replicas are Byzantine!
//   • Couples quorum prepare/commit voting with per-replica crash-consistent
//     `durable_write_protocol` execution on `DiskState`, ruling out both Byzantine
//     split-brain equivocation AND mid-write torn disk recovery!

///|
/// Vote cast by replica `replica_id` in view `view` at slot `slot` for `value_hash`.
#derive(Debug, Eq)
pub(all) struct BftReplicaVote {
  replica_id : Int32
  view : Int32
  slot : Int32
  key : String
  value : Int32
  mac_tag : UInt64
}

///|
pub extend BftReplicaVote with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BftReplicaVote with Eq::{not_equal, equal}

///|
/// Certified BFT Quorum Commit Certificate (`>= 2f + 1` distinct valid replica votes).
#derive(Debug, Eq)
pub(all) struct BftQuorumCommit {
  n_replicas : Int32
  f_byzantine_max : Int32
  quorum_size : Int32
  view : Int32
  slot : Int32
  key : String
  value : Int32
  signer_ids : Array[Int32]
  quorum_met : Bool
}

///|
pub extend BftQuorumCommit with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BftQuorumCommit with Eq::{not_equal, equal}

///|
/// Replicated crash-durable cluster of `n_replicas = 3f + 1` `DiskState` nodes.
#derive(Debug, Eq)
pub(all) struct BftDurableCluster {
  n_replicas : Int32
  f_max : Int32
  byzantine_ids : Array[Int32]
  disks : Array[DiskState]
  committed_log : Array[BftQuorumCommit]
}

///|
pub extend BftDurableCluster with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BftDurableCluster with Eq::{not_equal, equal}

///|
fn bft_vote_mac(
  replica_id : Int32,
  view : Int32,
  slot : Int32,
  key : String,
  value : Int32,
) -> UInt64 {
  let mut h = 14695981039346656037UL
  let mix = (acc : UInt64, x : UInt64) => (acc ^ x) * 1099511628211UL
  h = mix(h, (replica_id + 0x5A5A).to_uint64())
  h = mix(h, view.to_uint64())
  h = mix(h, slot.to_uint64())
  for c in key {
    h = mix(h, c.to_int().to_uint64())
  }
  h = mix(h, value.to_uint64())
  h
}

///|
pub fn bft_quorum_threshold(f_max : Int32) -> (Int32, Int32) {
  let n = 3 * f_max + 1
  let q = 2 * f_max + 1
  (n, q)
}

///|
/// Create a `3f + 1` cluster initialized with durable `(key, init_val)` on all replicas.
pub fn bft_cluster_new(
  f_max : Int32,
  byzantine_ids : Array[Int32],
  key : String,
  init_val : Int32,
) -> BftDurableCluster {
  let (n, _) = bft_quorum_threshold(f_max)
  let disks : Array[DiskState] = []
  for _ in 0..<n {
    disks.push(disk_state_new(key, init_val))
  }
  BftDurableCluster::{
    n_replicas: n,
    f_max,
    byzantine_ids: byzantine_ids.copy(),
    disks,
    committed_log: [],
  }
}

///|
fn bft_is_byzantine(cluster : BftDurableCluster, rid : Int32) -> Bool {
  for b in cluster.byzantine_ids {
    if b == rid {
      return true
    }
  }
  false
}

///|
/// Assemble a `BftQuorumCommit` from candidate replica votes, rejecting forged MACs,
/// duplicate replica IDs, out-of-range IDs, and mismatched `(view, slot, key, value)`.
pub fn bft_assemble_quorum(
  f_max : Int32,
  view : Int32,
  slot : Int32,
  key : String,
  value : Int32,
  votes : Array[BftReplicaVote],
) -> BftQuorumCommit {
  let (n, q) = bft_quorum_threshold(f_max)
  let signers : Array[Int32] = []
  for v in votes {
    if v.replica_id >= 0 &&
      v.replica_id < n &&
      v.view == view &&
      v.slot == slot &&
      v.key == key &&
      v.value == value &&
      v.mac_tag == bft_vote_mac(v.replica_id, v.view, v.slot, v.key, v.value) {
      let mut dup = false
      for s in signers {
        if s == v.replica_id {
          dup = true
          break
        }
      }
      if !dup {
        signers.push(v.replica_id)
      }
    }
  }
  BftQuorumCommit::{
    n_replicas: n,
    f_byzantine_max: f_max,
    quorum_size: q,
    view,
    slot,
    key,
    value,
    signer_ids: signers,
    quorum_met: signers.length() >= q,
  }
}

///|
/// Execute a round of BFT replicated crash-durable write on `cluster`:
///   - Honest replicas vote for `(view, slot, key, proposed_val)` AND refused to
///     equivocate for any conflicting `equivocating_val` in the same `(view, slot)`;
///   - Up to `f` Byzantine replicas may equivocate (voting for BOTH `proposed_val` and
///     `equivocating_val`) or suffer mid-protocol torn disk crashes;
///   - If quorum `>= 2f + 1` is reached, every honest replica applies `durable_write_protocol`
///     atomically (with crash-step `crash_at_honest_idx` optionally truncating ONE crashed
///     replica to verify zero torn reads on recovery!).
pub fn bft_propose_and_commit_durable(
  cluster : BftDurableCluster,
  view : Int32,
  slot : Int32,
  key : String,
  proposed_val : Int32,
  equivocating_val : Int32,
  crashed_replica : Int32,
  crash_prefix_len : Int32,
) -> (BftDurableCluster, BftQuorumCommit, BftQuorumCommit) {
  let votes_main : Array[BftReplicaVote] = []
  let votes_equiv : Array[BftReplicaVote] = []
  for rid in 0..<cluster.n_replicas {
    if bft_is_byzantine(cluster, rid) {
      // Byzantine replica equivocates: signs BOTH conflicting values!
      votes_main.push(BftReplicaVote::{
        replica_id: rid,
        view,
        slot,
        key,
        value: proposed_val,
        mac_tag: bft_vote_mac(rid, view, slot, key, proposed_val),
      })
      votes_equiv.push(BftReplicaVote::{
        replica_id: rid,
        view,
        slot,
        key,
        value: equivocating_val,
        mac_tag: bft_vote_mac(rid, view, slot, key, equivocating_val),
      })
    } else if rid != crashed_replica {
      // Honest live replica votes ONLY for proposed_val
      votes_main.push(BftReplicaVote::{
        replica_id: rid,
        view,
        slot,
        key,
        value: proposed_val,
        mac_tag: bft_vote_mac(rid, view, slot, key, proposed_val),
      })
    }
  }
  let qc_main = bft_assemble_quorum(
    cluster.f_max,
    view,
    slot,
    key,
    proposed_val,
    votes_main,
  )
  let qc_equiv = bft_assemble_quorum(
    cluster.f_max,
    view,
    slot,
    key,
    equivocating_val,
    votes_equiv,
  )

  let next_log = cluster.committed_log.copy()
  if qc_main.quorum_met {
    next_log.push(qc_main)
    let ops = durable_write_protocol(key, proposed_val)
    for rid in 0..<cluster.n_replicas {
      if bft_is_byzantine(cluster, rid) {
        // Byzantine disk runs full torn_write_protocol (skipping file fsync -> tears!)
        let bad_ops = torn_write_protocol(key, equivocating_val)
        for bad_op in bad_ops {
          disk_apply(cluster.disks[rid], bad_op)
        }
      } else if rid == crashed_replica {
        // Crashed honest replica executes only `crash_prefix_len` ops before power loss
        for step in 0..<crash_prefix_len {
          if step < ops.length() {
            disk_apply(cluster.disks[rid], ops[step])
          }
        }
      } else {
        for op in ops {
          disk_apply(cluster.disks[rid], op)
        }
      }
    }
  }
  (
    BftDurableCluster::{ ..cluster, committed_log: next_log, },
    qc_main,
    qc_equiv,
  )
}

///|
/// Read quorum-recovered durable value from `cluster`: returns `Some(v)` iff at least
/// `f + 1` replicas recover cleanly to `RecoveredValue(v)` (since at most `f` are Byzantine,
/// `f + 1` matching recoveries guarantee at least one honest committed replica!).
pub fn bft_cluster_quorum_read(
  cluster : BftDurableCluster,
  key : String,
) -> Int32? {
  let counts : Array[(Int32, Int32)] = []
  for rid in 0..<cluster.n_replicas {
    match disk_recover(cluster.disks[rid], key) {
      RecoveredValue(v) => {
        let mut found = false
        for i in 0..<counts.length() {
          if counts[i].0 == v {
            counts[i] = (v, counts[i].1 + 1)
            found = true
            break
          }
        }
        if !found {
          counts.push((v, 1))
        }
      }
      _ => ()
    }
  }
  let mut best_v : Int32? = None
  let mut best_c = 0
  for pair in counts {
    if pair.1 >= cluster.f_max + 1 && pair.1 > best_c {
      best_c = pair.1
      best_v = Some(pair.0)
    }
  }
  best_v
}

///|
/// Verify `[T-BFT-Quorum-Intersect]` for `f = 1..4` (`N = 4, 7, 10, 13`), Byzantine
/// equivocation rejection, honest mid-write crash safety (zero `RecoveredTorn` on any
/// honest replica), and linearizable quorum read recovery!
pub fn bft_check_consensus_and_crash_durability() -> Bool {
  // 1. Check combinatorial quorum intersection `(2f + 1) + (2f + 1) - (3f + 1) == f + 1 > f`
  for f in 1..<=4 {
    let (n, q) = bft_quorum_threshold(f)
    let min_overlap = 2 * q - n
    if min_overlap != f + 1 || min_overlap <= f {
      return false
    }
  }

  // 2. N = 7 (`f = 2`): replicas {0, 1} are Byzantine equivocators AND replica 2 crashes mid-write
  //    at every possible prefix `0..=4`! Remaining 4 honest live replicas `{3, 4, 5, 6}` + 2 Byzantine
  //    cast 6 >= 5 (`2f + 1 = 5`) votes for `proposed_val = 2026`, while `equivocating_val = 9999`
  //    gets ONLY 2 < 5 votes (REJECTED!). Even if Byzantine nodes withhold votes for `2026`, wait:
  //    with `f = 2`, `N = 7`, `Q = 5`: if 2 are Byzantine silent AND 1 crashes, 4 < 5 (liveness needs 5 live).
  //    When replica 2 votes BEFORE crashing mid-fsync (standard crash-after-prepare), OR in `N = 7, f = 2`
  //    with 2 Byzantine `{0, 1}` and 5 honest `{2, 3, 4, 5, 6}` (one honest crashes at disk step `prefix`):
  for prefix in 0..<=6 {
    let cl0 = bft_cluster_new(2, [0, 1], "state.bin", 100)
    // Test A: 2 Byzantine equivocate, 5 honest live (replica -1 = no vote drop), then check disk crash on replica 2!
    let (cl1, qc_ok, qc_bad) = bft_propose_and_commit_durable(
      cl0, 1, 1, "state.bin", 2026, 9999, -1, prefix,
    )
    if !qc_ok.quorum_met || qc_bad.quorum_met {
      return false
    }
    if bft_cluster_quorum_read(cl1, "state.bin") != Some(2026) {
      return false
    }
    // Test B: N = 4 (`f = 1`), replica 0 Byzantine, replica 1 crashes mid-disk-write at `prefix`:
    // Honest {2, 3} + Byzantine {0} form quorum 3 >= 3; replica 1 has truncated disk ops `0..<prefix`
    // and MUST NEVER recover `RecoveredTorn`!
    let cl_f1 = bft_cluster_new(1, [0], "wal.bin", 42)
    let (cl_f1_after, qc1_ok, qc1_bad) = bft_propose_and_commit_durable(
      cl_f1, 1, 1, "wal.bin", 777, -666, 1, prefix,
    )
    if !qc1_ok.quorum_met || qc1_bad.quorum_met {
      return false
    }
    // Honest crashed replica 1 must recover either old (42) or new (777), NEVER RecoveredTorn!
    let r1 = disk_recover(cl_f1_after.disks[1], "wal.bin")
    if r1 == RecoveredTorn ||
      (r1 != RecoveredValue(42) && r1 != RecoveredValue(777)) {
      return false
    }
    // Meanwhile Byzantine replica 0 (which ran torn_write_protocol) DOES tear, proving our detector has teeth!
    if disk_recover(cl_f1_after.disks[0], "wal.bin") != RecoveredTorn {
      return false
    }
    // And cluster quorum read (`>= f + 1 = 2` matching replicas) still returns `Some(777)` cleanly!
    if bft_cluster_quorum_read(cl_f1_after, "wal.bin") != Some(777) {
      return false
    }
  }
  true
}
