// HVM2-Style Flat-Arena Parallel Interaction Combinator Evaluator
// (Lafont 1997 Symmetric Interaction Combinators + Taelin 2024/2025 HVM2):
//   - Zero-GC flat port-indexed integer arena (`3 * node + port`, isomorphic to
//     WebGPU `var<storage, read_write> peer : array<u32>`);
//   - Parallel wave-synchronous active-pair (`port 0 <-> port 0`) reductions:
//     `ANNI` (annihilation), `COMM` (commutation), `ERAS` (erasure);
//   - Machine verification of Lafont's Strong Confluence Theorem across distinct
//     parallel wave schedules (Forward, Reversed, Odd-Even Interleaved).

///|
/// Node tags in the flat Interaction Combinator arena:
/// `0 = FREE`, `1 = ROOT`, `2 = ERA`, `3 = CON` (constructor / `λ` / `app`, label `0`),
/// `4 = DUP` (duplicator fan with integer label `>= 1`).
#derive(Debug, Eq)
pub struct INetArena {
  kinds : Array[Int32]
  labels : Array[Int32]
  peers : Array[Int32]
  mut anni_steps : Int32
  mut comm_steps : Int32
  mut eras_steps : Int32
  mut waves_executed : Int32
}

///|
pub extend INetArena with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend INetArena with Eq::{not_equal, equal}

///|
/// Wave scheduling policy for simulating parallel GPU redex execution orders.
#derive(Debug, Eq)
pub(all) enum INetWaveSchedule {
  ScheduleForward
  ScheduleReverse
  ScheduleOddEven
}

///|
pub extend INetWaveSchedule with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend INetWaveSchedule with Eq::{not_equal, equal}

///|
pub fn inet_new() -> INetArena {
  INetArena::{
    kinds: [],
    labels: [],
    peers: [],
    anni_steps: 0,
    comm_steps: 0,
    eras_steps: 0,
    waves_executed: 0,
  }
}

///|
pub fn inet_port(node : Int32, slot : Int32) -> Int32 {
  node * 3 + slot
}

///|
pub fn inet_alloc_node(net : INetArena, kind : Int32, label : Int32) -> Int32 {
  let id = net.kinds.length()
  net.kinds.push(kind)
  net.labels.push(label)
  let base = id * 3
  net.peers.push(base)
  net.peers.push(base + 1)
  net.peers.push(base + 2)
  id
}

///|
/// Symmetrically wire two ports `u <-> v` in `O(1)` (`peers[u] = v; peers[v] = u`).
pub fn inet_link(net : INetArena, u : Int32, v : Int32) -> Unit {
  net.peers[u] = v
  net.peers[v] = u
}

///|
fn inet_free_node(net : INetArena, id : Int32) -> Unit {
  net.kinds[id] = 0
  net.labels[id] = 0
  let b = id * 3
  net.peers[b] = b
  net.peers[b + 1] = b + 1
  net.peers[b + 2] = b + 2
}

///|
/// Rewire external neighbors originally attached to `(src_a, src_b)`:
/// handles the self-loop corner case (`peers[src_a] == src_b`) cleanly!
fn inet_splice_pair(net : INetArena, src_a : Int32, src_b : Int32) -> Unit {
  let pa = net.peers[src_a]
  let pb = net.peers[src_b]
  if pa == src_b {
    // Closed loop without external ports; nothing remains to connect
    ()
  } else if pa == src_a && pb == src_b {
    ()
  } else if pa == src_a {
    net.peers[pb] = pb
  } else if pb == src_b {
    net.peers[pa] = pa
  } else {
    inet_link(net, pa, pb)
  }
}

///|
/// Reduce a single active pair `(a, b)` meeting head-to-head at principal ports
/// (`inet_port(a, 0) <-> inet_port(b, 0)`).
fn inet_interact_pair(net : INetArena, a : Int32, b : Int32) -> Unit {
  let ka = net.kinds[a]
  let kb = net.kinds[b]
  if ka == 0 || kb == 0 || ka == 1 || kb == 1 {
    return
  }
  if net.peers[inet_port(a, 0)] != inet_port(b, 0) {
    return
  }
  // Rule 1: ERA <-> ERA vanishes in O(1)
  if ka == 2 && kb == 2 {
    inet_free_node(net, a)
    inet_free_node(net, b)
    net.eras_steps = net.eras_steps + 1
    return
  }
  // Rule 2: ERA <-> Binary (CON or DUP_L) propagates two ERA nodes to aux ports 1 & 2
  if ka == 2 || kb == 2 {
    let era_id = if ka == 2 { a } else { b }
    let bin_id = if ka == 2 { b } else { a }
    let p1 = net.peers[inet_port(bin_id, 1)]
    let p2 = net.peers[inet_port(bin_id, 2)]
    inet_free_node(net, era_id)
    inet_free_node(net, bin_id)
    let e1 = inet_alloc_node(net, 2, 0)
    let e2 = inet_alloc_node(net, 2, 0)
    if p1 == inet_port(bin_id, 2) {
      // Binary node had its aux1 and aux2 connected in a self-loop -> e1 <-> e2!
      inet_link(net, inet_port(e1, 0), inet_port(e2, 0))
    } else {
      inet_link(net, inet_port(e1, 0), p1)
      inet_link(net, inet_port(e2, 0), p2)
    }
    net.eras_steps = net.eras_steps + 1
    return
  }
  // Both a and b are binary nodes (CON=3 or DUP=4)
  let same_tag = ka == kb && net.labels[a] == net.labels[b]
  if same_tag {
    // Rule 3: ANNI (Annihilation): a.1 <-> b.1 and a.2 <-> b.2
    let a1_peer = net.peers[inet_port(a, 1)]
    let a2_peer = net.peers[inet_port(a, 2)]
    let b1_peer = net.peers[inet_port(b, 1)]
    let b2_peer = net.peers[inet_port(b, 2)]
    // Handle self-loops cleanly before freeing a and b
    if a1_peer == inet_port(a, 2) && b1_peer == inet_port(b, 2) {
      inet_free_node(net, a)
      inet_free_node(net, b)
    } else if a1_peer == inet_port(a, 2) {
      inet_free_node(net, a)
      inet_free_node(net, b)
      inet_link(net, b1_peer, b2_peer)
    } else if b1_peer == inet_port(b, 2) {
      inet_free_node(net, a)
      inet_free_node(net, b)
      inet_link(net, a1_peer, a2_peer)
    } else {
      inet_splice_pair(net, inet_port(a, 1), inet_port(b, 1))
      inet_splice_pair(net, inet_port(a, 2), inet_port(b, 2))
      inet_free_node(net, a)
      inet_free_node(net, b)
    }
    net.anni_steps = net.anni_steps + 1
  } else {
    // Rule 4: COMM (Commutation): ka/la commutes through kb/lb via 4 fresh nodes
    let la = net.labels[a]
    let lb = net.labels[b]
    let ext_a1 = net.peers[inet_port(a, 1)]
    let ext_a2 = net.peers[inet_port(a, 2)]
    let ext_b1 = net.peers[inet_port(b, 1)]
    let ext_b2 = net.peers[inet_port(b, 2)]
    let a_self = ext_a1 == inet_port(a, 2)
    let b_self = ext_b1 == inet_port(b, 2)
    inet_free_node(net, a)
    inet_free_node(net, b)
    // Two copies of B (`b1`, `b2`) facing A's external aux ports,
    // and two copies of A (`a1`, `a2`) facing B's external aux ports:
    let b1 = inet_alloc_node(net, kb, lb)
    let b2 = inet_alloc_node(net, kb, lb)
    let a1 = inet_alloc_node(net, ka, la)
    let a2 = inet_alloc_node(net, ka, la)
    if a_self {
      inet_link(net, inet_port(b1, 0), inet_port(b2, 0))
    } else {
      inet_link(net, inet_port(b1, 0), ext_a1)
      inet_link(net, inet_port(b2, 0), ext_a2)
    }
    if b_self {
      inet_link(net, inet_port(a1, 0), inet_port(a2, 0))
    } else {
      inet_link(net, inet_port(a1, 0), ext_b1)
      inet_link(net, inet_port(a2, 0), ext_b2)
    }
    // Internal 2x2 biclique cross-wiring:
    inet_link(net, inet_port(b1, 1), inet_port(a1, 1))
    inet_link(net, inet_port(b1, 2), inet_port(a2, 1))
    inet_link(net, inet_port(b2, 1), inet_port(a1, 2))
    inet_link(net, inet_port(b2, 2), inet_port(a2, 2))
    net.comm_steps = net.comm_steps + 1
  }
}

///|
/// Collect all currently active principal-to-principal pairs `(a < b)` in the arena.
/// Because each node has only ONE principal port (`slot 0`), active pairs in any wave
/// are strictly vertex-disjoint!
pub fn inet_collect_active_wave(net : INetArena) -> Array[(Int32, Int32)] {
  let wave : Array[(Int32, Int32)] = []
  let total = net.kinds.length()
  for a in 0..<total {
    let ka = net.kinds[a]
    if ka >= 2 {
      let peer_p = net.peers[inet_port(a, 0)]
      if peer_p % 3 == 0 {
        let b = peer_p / 3
        if b > a && net.kinds[b] >= 2 {
          wave.push((a, b))
        }
      }
    }
  }
  wave
}

///|
/// Execute parallel active-pair reduction waves until reaching full normal form
/// (or `max_waves` safety cap), using `schedule` to permute intra-wave firing order.
pub fn inet_normalize_waves(
  net : INetArena,
  schedule~ : INetWaveSchedule = ScheduleForward,
  max_waves~ : Int32 = 4096,
) -> Int32 {
  let mut w = 0
  while w < max_waves {
    let wave = inet_collect_active_wave(net)
    if wave.length() == 0 {
      break
    }
    let m = wave.length()
    match schedule {
      ScheduleForward =>
        for i in 0..<m {
          let (a, b) = wave[i]
          inet_interact_pair(net, a, b)
        }
      ScheduleReverse => {
        let mut i = m - 1
        while i >= 0 {
          let (a, b) = wave[i]
          inet_interact_pair(net, a, b)
          i = i - 1
        }
      }
      ScheduleOddEven => {
        let mut i = 1
        while i < m {
          let (a, b) = wave[i]
          inet_interact_pair(net, a, b)
          i = i + 2
        }
        let mut j = 0
        while j < m {
          let (a, b) = wave[j]
          inet_interact_pair(net, a, b)
          j = j + 2
        }
      }
    }
    net.waves_executed = net.waves_executed + 1
    w = w + 1
  }
  net.anni_steps + net.comm_steps + net.eras_steps
}

///|
/// Encode Church numeral `c_k = λf. λx. f^k(x)` into `net` using `dup_label >= 1`
/// for its fan tree, returning the principal port of the outer `λf` constructor.
pub fn inet_encode_church_nat(
  net : INetArena,
  k : Int32,
  dup_label : Int32,
) -> Int32 {
  let lam_f = inet_alloc_node(net, 3, 0)
  let lam_x = inet_alloc_node(net, 3, 0)
  inet_link(net, inet_port(lam_f, 2), inet_port(lam_x, 0))
  if k <= 0 {
    let era = inet_alloc_node(net, 2, 0)
    inet_link(net, inet_port(lam_f, 1), inet_port(era, 0))
    inet_link(net, inet_port(lam_x, 1), inet_port(lam_x, 2))
    return inet_port(lam_f, 0)
  }
  if k == 1 {
    let app = inet_alloc_node(net, 3, 0)
    inet_link(net, inet_port(lam_f, 1), inet_port(app, 0))
    inet_link(net, inet_port(lam_x, 1), inet_port(app, 1))
    inet_link(net, inet_port(app, 2), inet_port(lam_x, 2))
    return inet_port(lam_f, 0)
  }
  // Build k application nodes chained from x -> f_1(x) -> ... -> f_k(...(x)) -> body_out
  let apps : Array[Int32] = Array::makei(k, _ => inet_alloc_node(net, 3, 0))
  inet_link(net, inet_port(lam_x, 1), inet_port(apps[0], 1))
  for i in 0..<(k - 1) {
    inet_link(net, inet_port(apps[i], 2), inet_port(apps[i + 1], 1))
  }
  inet_link(net, inet_port(apps[k - 1], 2), inet_port(lam_x, 2))
  // Split `f` (`lam_f` port 1) into `k` function ports (`apps[i]` port 0) via `k - 1` DUP_L fans
  let mut cur_f_source = inet_port(lam_f, 1)
  for i in 0..<(k - 1) {
    if i == k - 2 {
      let dup = inet_alloc_node(net, 4, dup_label)
      inet_link(net, cur_f_source, inet_port(dup, 0))
      inet_link(net, inet_port(dup, 1), inet_port(apps[i], 0))
      inet_link(net, inet_port(dup, 2), inet_port(apps[i + 1], 0))
    } else {
      let dup = inet_alloc_node(net, 4, dup_label)
      inet_link(net, cur_f_source, inet_port(dup, 0))
      inet_link(net, inet_port(dup, 1), inet_port(apps[i], 0))
      cur_f_source = inet_port(dup, 2)
    }
  }
  inet_port(lam_f, 0)
}

///|
/// Build the closed Interaction Combinator net for Church multiplication applied
/// to Peano constructors `((λm. λn. λf. λx. m (n f) x) c_a c_b) (λz. S(z)) Z`,
/// where `S` has kind `5` (`port 0` = constructed value, `port 1` = predecessor,
/// `port 2` = `ERA`) and `Z` has kind `6` (`port 0` = value, `port 1 <-> port 2`).
/// Every active pair reduces strictly via local `ANNI`, `COMM`, and `ERAS` rules
/// to the closed normal form `S^{a * b}(Z)` attached to `root.0`!
pub fn inet_build_church_mul_net(a : Int32, b : Int32) -> (INetArena, Int32) {
  let net = inet_new()
  let root = inet_alloc_node(net, 1, 0)
  let ca = inet_encode_church_nat(net, a, 1)
  let cb = inet_encode_church_nat(net, b, 2)
  // Combinator B = λm. λn. λf. λx. m (n f) x
  let lam_m = inet_alloc_node(net, 3, 0)
  let lam_n = inet_alloc_node(net, 3, 0)
  let lam_f = inet_alloc_node(net, 3, 0)
  let lam_x = inet_alloc_node(net, 3, 0)
  inet_link(net, inet_port(lam_m, 2), inet_port(lam_n, 0))
  inet_link(net, inet_port(lam_n, 2), inet_port(lam_f, 0))
  inet_link(net, inet_port(lam_f, 2), inet_port(lam_x, 0))
  let app_nf = inet_alloc_node(net, 3, 0)
  let app_mnf = inet_alloc_node(net, 3, 0)
  let app_res = inet_alloc_node(net, 3, 0)
  inet_link(net, inet_port(lam_n, 1), inet_port(app_nf, 0))
  inet_link(net, inet_port(lam_f, 1), inet_port(app_nf, 1))
  inet_link(net, inet_port(lam_m, 1), inet_port(app_mnf, 0))
  inet_link(net, inet_port(app_nf, 2), inet_port(app_mnf, 1))
  inet_link(net, inet_port(app_mnf, 2), inet_port(app_res, 0))
  inet_link(net, inet_port(lam_x, 1), inet_port(app_res, 1))
  inet_link(net, inet_port(app_res, 2), inet_port(lam_x, 2))
  // Closed Peano step `λz. S(z)` (`kind 5` for constructor `S`) and base `Z` (`kind 6`)
  let lam_succ = inet_alloc_node(net, 3, 0)
  let ctr_s = inet_alloc_node(net, 5, 1)
  let era_s = inet_alloc_node(net, 2, 0)
  inet_link(net, inet_port(lam_succ, 1), inet_port(ctr_s, 1))
  inet_link(net, inet_port(ctr_s, 2), inet_port(era_s, 0))
  inet_link(net, inet_port(ctr_s, 0), inet_port(lam_succ, 2))
  let ctr_z = inet_alloc_node(net, 6, 0)
  inet_link(net, inet_port(ctr_z, 1), inet_port(ctr_z, 2))
  // Four top-level applications: (((B ca) cb) lam_succ) ctr_z -> root.0
  let call1 = inet_alloc_node(net, 3, 0)
  let call2 = inet_alloc_node(net, 3, 0)
  let call3 = inet_alloc_node(net, 3, 0)
  let call4 = inet_alloc_node(net, 3, 0)
  inet_link(net, inet_port(call1, 0), inet_port(lam_m, 0))
  inet_link(net, inet_port(call1, 1), ca)
  inet_link(net, inet_port(call1, 2), inet_port(call2, 0))
  inet_link(net, inet_port(call2, 1), cb)
  inet_link(net, inet_port(call2, 2), inet_port(call3, 0))
  inet_link(net, inet_port(call3, 1), inet_port(lam_succ, 0))
  inet_link(net, inet_port(call3, 2), inet_port(call4, 0))
  inet_link(net, inet_port(call4, 1), inet_port(ctr_z, 0))
  inet_link(net, inet_port(call4, 2), inet_port(root, 0))
  (net, root)
}

///|
/// Read back the closed Peano normal form `S^k(Z)` attached to `root.0`:
/// walks principal ports `S.0 -> S.1 -> ... -> Z.0`, returning `k` (`-1` if malformed).
pub fn inet_readback_church_nat(net : INetArena, root : Int32) -> Int32 {
  let mut cur = net.peers[inet_port(root, 0)]
  let mut steps = 0
  let max_guard = net.kinds.length() + 4
  while steps < max_guard {
    let node = cur / 3
    let slot = cur % 3
    if slot != 0 {
      return -1
    }
    let k = net.kinds[node]
    if k == 6 {
      return steps
    }
    if k != 5 {
      return -1
    }
    cur = net.peers[inet_port(node, 1)]
    steps = steps + 1
  }
  -1
}

///|
/// Strong Confluence certificate comparing Forward, Reversed, and Odd-Even parallel
/// GPU wave schedules on `(c_a * c_b)`.
#derive(Debug, Eq)
pub(all) struct INetConfluenceCertificate {
  a : Int32
  b : Int32
  decoded_value : Int32
  anni_steps : Int32
  comm_steps : Int32
  eras_steps : Int32
  schedules_confluent : Bool
}

///|
pub extend INetConfluenceCertificate with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend INetConfluenceCertificate with Eq::{not_equal, equal}

///|
/// Verify Lafont's Strong Confluence Theorem on Church numeral multiplication `a * b`:
/// all three wave schedules (`Forward`, `Reverse`, `OddEven`) must yield the exact
/// numeral `a * b` AND identical `(anni_steps, comm_steps, eras_steps)` counts!
pub fn inet_verify_church_mul_confluence(
  a : Int32,
  b : Int32,
) -> INetConfluenceCertificate {
  let (net_f, root_f) = inet_build_church_mul_net(a, b)
  let _ = inet_normalize_waves(
    net_f,
    schedule=INetWaveSchedule::ScheduleForward,
  )
  let val_f = inet_readback_church_nat(net_f, root_f)

  let (net_r, root_r) = inet_build_church_mul_net(a, b)
  let _ = inet_normalize_waves(
    net_r,
    schedule=INetWaveSchedule::ScheduleReverse,
  )
  let val_r = inet_readback_church_nat(net_r, root_r)

  let (net_oe, root_oe) = inet_build_church_mul_net(a, b)
  let _ = inet_normalize_waves(
    net_oe,
    schedule=INetWaveSchedule::ScheduleOddEven,
  )
  let val_oe = inet_readback_church_nat(net_oe, root_oe)

  let ok = val_f == a * b &&
    val_r == a * b &&
    val_oe == a * b &&
    net_f.anni_steps == net_r.anni_steps &&
    net_f.anni_steps == net_oe.anni_steps &&
    net_f.comm_steps == net_r.comm_steps &&
    net_f.comm_steps == net_oe.comm_steps &&
    net_f.eras_steps == net_r.eras_steps &&
    net_f.eras_steps == net_oe.eras_steps
  INetConfluenceCertificate::{
    a,
    b,
    decoded_value: val_f,
    anni_steps: net_f.anni_steps,
    comm_steps: net_f.comm_steps,
    eras_steps: net_f.eras_steps,
    schedules_confluent: ok,
  }
}

///|
/// Closed higher-order Peano λ-term AST compiled into `INetArena` symmetric
/// interaction combinators (`CON` / `DUP_L` / `ERA` / `S` / `Z`):
///   - `ILVar(idx)`: de Bruijn variable (`0` = innermost binder);
///   - `ILLam(body)`: abstraction `λx. body`;
///   - `ILApp(fn_t, arg_t)`: application `fn_t arg_t`;
///   - `ILZero`: Peano zero constructor `Z`;
///   - `ILSucc(t)`: Peano successor constructor `S(t)`.
#derive(Debug, Eq)
pub(all) enum InetClosedLam {
  ILVar(Int32)
  ILLam(InetClosedLam)
  ILApp(InetClosedLam, InetClosedLam)
  ILZero
  ILSucc(InetClosedLam)
}

///|
pub extend InetClosedLam with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend InetClosedLam with Eq::{not_equal, equal}

///|
fn inet_compile_closed_into(
  net : INetArena,
  term : InetClosedLam,
  dest_port : Int32,
  scope : Array[Array[Int32]],
  next_dup_label : Array[Int32],
) -> Unit {
  match term {
    ILVar(idx) => {
      let slot = scope.length() - 1 - idx
      scope[slot].push(dest_port)
    }
    ILZero => {
      let z = inet_alloc_node(net, 6, 0)
      inet_link(net, inet_port(z, 1), inet_port(z, 2))
      inet_link(net, inet_port(z, 0), dest_port)
    }
    ILSucc(inner) => {
      let s = inet_alloc_node(net, 5, 1)
      let e = inet_alloc_node(net, 2, 0)
      inet_link(net, inet_port(s, 2), inet_port(e, 0))
      inet_link(net, inet_port(s, 0), dest_port)
      inet_compile_closed_into(
        net,
        inner,
        inet_port(s, 1),
        scope,
        next_dup_label,
      )
    }
    ILApp(f, arg) => {
      let app = inet_alloc_node(net, 3, 0)
      inet_link(net, inet_port(app, 2), dest_port)
      inet_compile_closed_into(net, f, inet_port(app, 0), scope, next_dup_label)
      inet_compile_closed_into(
        net,
        arg,
        inet_port(app, 1),
        scope,
        next_dup_label,
      )
    }
    ILLam(body) => {
      let lam = inet_alloc_node(net, 3, 0)
      inet_link(net, inet_port(lam, 0), dest_port)
      scope.push([])
      inet_compile_closed_into(
        net,
        body,
        inet_port(lam, 2),
        scope,
        next_dup_label,
      )
      let uses = scope.pop().unwrap()
      if uses.length() == 0 {
        let era = inet_alloc_node(net, 2, 0)
        inet_link(net, inet_port(lam, 1), inet_port(era, 0))
      } else if uses.length() == 1 {
        inet_link(net, inet_port(lam, 1), uses[0])
      } else {
        let lbl = next_dup_label[0]
        next_dup_label[0] = lbl + 1
        let mut cur_src = inet_port(lam, 1)
        for k in 0..<(uses.length() - 1) {
          let dup = inet_alloc_node(net, 4, lbl)
          inet_link(net, cur_src, inet_port(dup, 0))
          inet_link(net, inet_port(dup, 1), uses[k])
          cur_src = inet_port(dup, 2)
        }
        inet_link(net, cur_src, uses[uses.length() - 1])
      }
    }
  }
}

///|
/// Compile a closed `InetClosedLam` term into `INetArena`, execute parallel wave
/// normalization under `schedule`, and read back the resulting Peano `Nat` (`-1` if stuck).
pub fn inet_eval_closed_peano_lam(
  term : InetClosedLam,
  schedule~ : INetWaveSchedule = INetWaveSchedule::ScheduleForward,
) -> (Int32, Int32) {
  let net = inet_new()
  let root = inet_alloc_node(net, 1, 0)
  let scope : Array[Array[Int32]] = []
  let next_lbl : Array[Int32] = [10]
  inet_compile_closed_into(net, term, inet_port(root, 0), scope, next_lbl)
  let waves = inet_normalize_waves(net, schedule~)
  (inet_readback_church_nat(net, root), waves)
}
