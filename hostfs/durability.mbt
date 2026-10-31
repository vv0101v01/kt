///|
// An executable specification of crash-consistent durable writes.
//
// SPEC section 4 records that the storage layer deliberately keeps an
// abstract byte-store protocol rather than coupling to POSIX
// `flock`/`mmap`/`fsync`.  Keeping the core abstract is right, but it
// leaves the durability *recipe* as folklore.  This file makes the
// recipe a checkable object.
//
// The model distinguishes the two things a filesystem actually makes
// durable, because conflating them is exactly how torn files happen:
//
//   * content durability  -- the bytes of an inode (`fsync` of the file)
//   * dirent durability   -- the name -> inode link (`fsync` of the
//                            containing directory)
//
// A write is crash consistent only if the new inode's content is
// durable *before* the dirent that names it becomes durable.  If a
// crash lands between the two, the name resolves to an inode whose
// bytes were never flushed, and a reader sees a torn value.  That is
// the single failure mode this file exists to rule out.
//
// Everything here is target independent: it simulates the kernel's
// durability rules and checks protocols against them, so the property
// can be verified on wasm-gc even though the real backend is native
// only.

///|
/// One durability-relevant operation a backend may issue.
pub enum StoreOp {
  /// Write `content` to `path`.  Neither content nor dirent durable.
  OpWrite(String, Int32)
  /// `fsync(path)`: the inode at `path` has durable content.
  OpFsync(String)
  /// `rename(from, to)`: the inode moves; the new dirent is not durable.
  OpRename(String, String)
  /// `fsync` of the directory containing `path`: the dirent is durable.
  OpFsyncParent(String)
  /// `unlink(path)`; the removal is not durable until the parent is fsynced.
  OpUnlink(String)
  /// Advisory whole-store lock / unlock (`flock`).  No durability effect.
  OpLock(String)
  OpUnlock(String)
} derive(Debug, Eq)

///|
pub extend StoreOp with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend StoreOp with Eq::{not_equal, equal}

///|
/// What a reader finds at a key after a crash.
pub enum Recovery {
  /// The key is absent.
  RecoveredAbsent
  /// The key holds a complete value.
  RecoveredValue(Int32)
  /// The name resolves, but the bytes were never flushed: a torn read.
  /// No correct protocol may ever produce this.
  RecoveredTorn
} derive(Debug, Eq)

///|
pub extend Recovery with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Recovery with Eq::{not_equal, equal}

///|
/// The volatile + durable state of a tiny filesystem.
pub struct DiskState {
  /// path -> inode (volatile)
  mut inode_at : Array[(String, Int32)]
  /// inode -> content (volatile)
  mut inode_content : Array[(Int32, Int32)]
  /// inodes whose content has been fsynced
  durable_inode : Array[Int32]
  /// path -> inode, durable name->inode links
  mut durable_dirent : Array[(String, Int32)]
  /// next fresh inode id
  mut next_inode : Int32
} derive(Debug, Eq)

///|
pub extend DiskState with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend DiskState with Eq::{not_equal, equal}

///|
/// Start from a durable store in which `key` already holds `old`.
pub fn disk_state_new(key : String, old : Int32) -> DiskState {
  DiskState::{
    inode_at: [(key, 0)],
    inode_content: [(0, old)],
    durable_inode: [0],
    durable_dirent: [(key, 0)],
    next_inode: 1,
  }
}

///|
fn disk_lookup(pairs : Array[(String, Int32)], p : String) -> Int32? {
  for i in 0..<pairs.length() {
    if pairs[i].0 == p {
      return Some(pairs[i].1)
    }
  }
  None
}

///|
fn disk_remove(
  pairs : Array[(String, Int32)],
  p : String,
) -> Array[(String, Int32)] {
  let out : Array[(String, Int32)] = []
  for i in 0..<pairs.length() {
    if pairs[i].0 != p {
      out.push(pairs[i])
    }
  }
  out
}

///|
fn disk_inode_content(st : DiskState, inode : Int32) -> Int32? {
  for i in 0..<st.inode_content.length() {
    if st.inode_content[i].0 == inode {
      return Some(st.inode_content[i].1)
    }
  }
  None
}

///|
fn disk_has(xs : Array[Int32], v : Int32) -> Bool {
  for i in 0..<xs.length() {
    if xs[i] == v {
      return true
    }
  }
  false
}

///|
pub fn disk_apply(st : DiskState, op : StoreOp) -> Unit {
  match op {
    OpWrite(path, content) => {
      let inode = st.next_inode
      st.next_inode = st.next_inode + 1
      st.inode_at = disk_remove(st.inode_at, path)
      st.inode_at.push((path, inode))
      let c : Array[(Int32, Int32)] = []
      for i in 0..<st.inode_content.length() {
        if st.inode_content[i].0 != inode {
          c.push(st.inode_content[i])
        }
      }
      c.push((inode, content))
      st.inode_content = c
    }
    OpFsync(path) =>
      match disk_lookup(st.inode_at, path) {
        None => ()
        Some(inode) =>
          if !disk_has(st.durable_inode, inode) {
            st.durable_inode.push(inode)
          }
      }
    OpRename(from, to) =>
      match disk_lookup(st.inode_at, from) {
        None => ()
        Some(inode) => {
          st.inode_at = disk_remove(st.inode_at, from)
          st.inode_at = disk_remove(st.inode_at, to)
          st.inode_at.push((to, inode))
        }
      }
    OpFsyncParent(path) =>
      match disk_lookup(st.inode_at, path) {
        // The name now durably resolves to this inode.
        Some(inode) => {
          st.durable_dirent = disk_remove(st.durable_dirent, path)
          st.durable_dirent.push((path, inode))
        }
        // The name is gone; the removal becomes durable.
        None => st.durable_dirent = disk_remove(st.durable_dirent, path)
      }
    OpUnlink(path) => st.inode_at = disk_remove(st.inode_at, path)
    OpLock(_) | OpUnlock(_) => ()
  }
}

///|
/// What a reader sees at `key` after a power loss, given the durable
/// state accumulated so far.
pub fn disk_recover(st : DiskState, key : String) -> Recovery {
  match disk_lookup(st.durable_dirent, key) {
    None => RecoveredAbsent
    Some(inode) =>
      if !disk_has(st.durable_inode, inode) {
        // The name is durable but the bytes are not: a torn read.
        RecoveredTorn
      } else {
        match disk_inode_content(st, inode) {
          None => RecoveredAbsent
          Some(v) => RecoveredValue(v)
        }
      }
  }
}

///|
/// Run `ops[0 .. count)` and then pull the plug.
fn disk_run_crash(
  st0 : DiskState,
  ops : Array[StoreOp],
  count : Int32,
  key : String,
) -> Recovery {
  let st = st0
  let mut i = 0
  while i < count && i < ops.length() {
    disk_apply(st, ops[i])
    i = i + 1
  }
  disk_recover(st, key)
}

///|
/// The crash-consistent write protocol for one key.
///
/// ```text
///   lock -> write(staging) -> fsync(staging) -> rename(staging, key)
///        -> fsync(dir(key)) -> unlock
/// ```
///
/// The `fsync(staging)` before the rename is what makes the bytes
/// durable; the `fsync(dir)` after is what makes the new name durable.
/// Between them a crash simply leaves the previous value in place.
pub fn durable_write_protocol(key : String, new : Int32) -> Array[StoreOp] {
  let staging = key + ".staging"
  [
    OpLock(key),
    OpWrite(staging, new),
    OpFsync(staging),
    OpRename(staging, key),
    OpFsyncParent(key),
    OpUnlock(key),
  ]
}

///|
/// The classic mistake: rename the staging file over the target
/// without ever flushing its bytes.  On a crash the durable dirent
/// points at an inode whose content was never fsynced, so the reader
/// sees a torn value.  Exists as a negative control.
pub fn torn_write_protocol(key : String, new : Int32) -> Array[StoreOp] {
  let staging = key + ".staging"
  [
    OpLock(key),
    OpWrite(staging, new),
    OpRename(staging, key),
    OpFsyncParent(key),
    OpUnlock(key),
  ]
}

///|
/// Another classic mistake: flush the file but never the directory, so
/// the rename can be lost after a crash.  This one is *safe* (it
/// degrades to the old value) but it does not honour an acknowledged
/// write, which `durable_write_protocol` must be checked to do.
pub fn unacknowledged_write_protocol(
  key : String,
  new : Int32,
) -> Array[StoreOp] {
  let staging = key + ".staging"
  [
    OpLock(key),
    OpWrite(staging, new),
    OpFsync(staging),
    OpRename(staging, key),
    OpUnlock(key),
  ]
}

///|
/// Check a protocol against the model: at every possible crash point,
/// a reader must see either the old value or the new one, never a torn
/// one.
pub fn protocol_is_crash_consistent(
  ops : Array[StoreOp],
  key : String,
  old : Int32,
  new : Int32,
) -> Bool {
  let mut k = 0
  while k <= ops.length() {
    let r = disk_run_crash(disk_state_new(key, old), ops, k, key)
    match r {
      RecoveredTorn => return false
      RecoveredAbsent => return false
      RecoveredValue(v) => if v != old && v != new { return false }
    }
    k = k + 1
  }
  true
}

///|
/// Stronger: a protocol *honours* a write when, after running to
/// completion and then crashing, the new value is what comes back.
pub fn protocol_durable_on_completion(
  ops : Array[StoreOp],
  key : String,
  old : Int32,
  new : Int32,
) -> Bool {
  let r = disk_run_crash(disk_state_new(key, old), ops, ops.length(), key)
  match r {
    RecoveredValue(v) => v == new
    _ => false
  }
}

///|
/// The crash point at which a protocol first tears, if any.
pub fn protocol_first_tear(
  ops : Array[StoreOp],
  key : String,
  old : Int32,
) -> Int32 {
  let mut k = 0
  while k <= ops.length() {
    match disk_run_crash(disk_state_new(key, old), ops, k, key) {
      RecoveredTorn => return k
      _ => ()
    }
    k = k + 1
  }
  -1
}

///|
/// The crash-consistent delete protocol: unlink, then flush the
/// directory so the removal itself survives a crash.
pub fn durable_delete_protocol(key : String) -> Array[StoreOp] {
  [OpLock(key), OpUnlink(key), OpFsyncParent(key), OpUnlock(key)]
}

///|
/// A delete that never flushes the directory: safe, but the entry can
/// reappear after a crash, so the delete is not honoured.
pub fn unacknowledged_delete_protocol(key : String) -> Array[StoreOp] {
  [OpLock(key), OpUnlink(key), OpUnlock(key)]
}

///|
/// True when a completed run followed by a crash leaves the key gone.
pub fn protocol_deletes_on_completion(
  ops : Array[StoreOp],
  key : String,
  old : Int32,
) -> Bool {
  match disk_run_crash(disk_state_new(key, old), ops, ops.length(), key) {
    RecoveredAbsent => true
    _ => false
  }
}

///|
/// The crash-consistent durable-write protocol, as an executable law.
pub fn check_durable_write_protocol() -> Bool {
  let key = "objects/ab/cdef"
  let old = 11
  let new = 22
  let good = durable_write_protocol(key, new)
  let torn = torn_write_protocol(key, new)
  let unacked = unacknowledged_write_protocol(key, new)

  // (1) The correct protocol never tears, at any crash point.
  let good_ok = protocol_is_crash_consistent(good, key, old, new) &&
    // ... and it honours the write once it has run to completion.
    protocol_durable_on_completion(good, key, old, new) &&
    protocol_first_tear(good, key, old) == -1

  // (2) Dropping the file fsync tears.  The tear is detected exactly at
  //     the crash point right after the directory fsync, i.e. after
  //     the rename has been made durable.
  let tear_at = protocol_first_tear(torn, key, old)
  let torn_ok = !protocol_is_crash_consistent(torn, key, old, new) &&
    tear_at == 4

  // (3) Dropping the directory fsync is safe but loses the write.
  let unacked_ok = protocol_is_crash_consistent(unacked, key, old, new) &&
    !protocol_durable_on_completion(unacked, key, old, new)

  // (4) Every prefix of the correct protocol recovers to the old value
  //     until the directory fsync, and to the new value afterwards.
  let mut k = 0
  let mut prefix_ok = true
  while k <= good.length() {
    let expect = if k >= 5 { new } else { old }
    match disk_run_crash(disk_state_new(key, old), good, k, key) {
      RecoveredValue(v) => if v != expect { prefix_ok = false }
      _ => prefix_ok = false
    }
    k = k + 1
  }

  // (5) Locking is balanced and brackets the mutation.
  let mut locks = 0
  let mut balance = 0
  let mut balanced = true
  let mut i = 0
  while i < good.length() {
    match good[i] {
      OpLock(_) => {
        locks = locks + 1
        balance = balance + 1
        // The lock must come before any mutation.
        if i != 0 {
          balanced = false
        }
      }
      OpUnlock(_) => {
        balance = balance - 1
        if i != good.length() - 1 {
          balanced = false
        }
      }
      _ => ()
    }
    i = i + 1
  }
  let lock_ok = locks == 1 && balance == 0 && balanced

  // (6) Deletion: unlink + directory fsync removes the key for good,
  //     while dropping the directory fsync lets it reappear.
  let del = durable_delete_protocol(key)
  let del_unacked = unacknowledged_delete_protocol(key)
  let delete_ok = protocol_first_tear(del, key, old) == -1 &&
    protocol_deletes_on_completion(del, key, old) &&
    protocol_first_tear(del_unacked, key, old) == -1 &&
    !protocol_deletes_on_completion(del_unacked, key, old)

  good_ok && torn_ok && unacked_ok && prefix_ok && lock_ok && delete_ok
}
