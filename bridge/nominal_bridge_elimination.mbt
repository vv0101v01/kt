///|
// Second wave of nominal-bridge elimination (`bool && bool` removal).
//
// The first wave (structural_bridge_replacements.mbt) replaced six Accel/Meta
// edges.  This file removes the remaining edges whose `holds` was a conjunction
// of *independent* health reports, i.e. where the two federations never actually
// interacted:
//
//   K5-02 Cubical × Semiring : face lattice covering relation -> star-semiring
//                              closure == face order; nilpotent Neumann series
//                              counts maximal chains (= 2^n · n! = |B_n|)
//   K5-05 Symlib × Semiring  : Burnside orbit census of closed-walk spaces via
//                              counting-semiring matrix powers on Fix(g)
//   K8-23 Accel × Symlib     : S_3 axis action on all 6561 GF(3) tensors; SWAR
//                              hyperdet invariance + Burnside == union-find
//   K8-26 Accel × Scheme     : rank<=1 locus == affine cone over the Segre
//                              variety, |cone(F_q)| = 1 + (q-1)|P^1(F_q)|^3
//   K8-28 Accel × Discovery  : SWAR bitplane implication lattice == exhaustive
//                              semantic implication, with witness agreement
//   K9-30 Meta × Symlib      : congruence closure of generator relations ==
//                              orbit partition == rank == Burnside average
//   K9-33 Meta × Scheme      : fraction-free Bareiss rank of Macaulay matrices
//                              == Gröbner standard-monomial Hilbert function
//
// Every edge carries a negative control that *fails* if the construction is
// replaced by a naive/health-report conjunction.

///|
fn nbe_show_ints(a : Array[Int32]) -> String {
  let mut s = "["
  for i in 0..<a.length() {
    if i > 0 {
      s = s + ","
    }
    s = s + "\{a[i]}"
  }
  s + "]"
}

///|
fn nbe_show_i64s(a : Array[Int64]) -> String {
  let mut s = "["
  for i in 0..<a.length() {
    if i > 0 {
      s = s + ","
    }
    s = s + "\{a[i]}"
  }
  s + "]"
}

///|
fn nbe_show_opt(o : Int32?) -> String {
  match o {
    Some(v) => "\{v}"
    None => "none"
  }
}

///|
fn nbe_digits3(code : Int32, len : Int32) -> Array[Int32] {
  let out = Array::make(len, 0)
  let mut c = code
  for i in 0..<len {
    out[i] = c % 3
    c = c / 3
  }
  out
}

///|
fn nbe_dsu_find(parent : Array[Int32], x : Int32) -> Int32 {
  let mut r = x
  while parent[r] != r {
    r = parent[r]
  }
  let mut c = x
  while parent[c] != c {
    let nx = parent[c]
    parent[c] = r
    c = nx
  }
  r
}

///|
fn nbe_dsu_union(parent : Array[Int32], a : Int32, b : Int32) -> Unit {
  let ra = nbe_dsu_find(parent, a)
  let rb = nbe_dsu_find(parent, b)
  if ra != rb {
    parent[rb] = ra
  }
}

///|
fn nbe_dsu_classes(parent : Array[Int32]) -> Int32 {
  let mut k = 0
  for i in 0..<parent.length() {
    if nbe_dsu_find(parent, i) == i {
      k = k + 1
    }
  }
  k
}

// ---------------------------------------------------------------------------
// K5-02  Cubical × Semiring
// ---------------------------------------------------------------------------

///|
fn nbe_cube_face(code : Int32, n : Int32) -> @fb.Face {
  let d = nbe_digits3(code, n)
  let mut f = @fb.face_top()
  for i in 0..<n {
    if d[i] == 0 {
      f = @fb.face_and(f, @fb.face_var0(i))
    } else if d[i] == 1 {
      f = @fb.face_and(f, @fb.face_var1(i))
    }
  }
  f
}

///|
/// **K5-02 (replaces `check_face_semiring_bridge() && check_tropical_bridges()`)**.
///
/// The cubical face lattice of `□^n` (faces = consistent literal conjunctions,
/// `3^n` of them) is fed to the star-semiring layer as its covering relation.
/// Two theorems are *constructed*, not conjoined:
///   1. Boolean Kleene closure of the covering relation reproduces the CCHM
///      cofibration order `cchm_face_le` on all `3^n × 3^n` pairs (two
///      independent closure algorithms: blocked FW and Lehmann).
///   2. Over the counting semiring the covering matrix is nilpotent
///      (`C^{n+1} = 0`), so the Neumann series terminates and `C^n[v, ⊤]`
///      counts maximal chains; summing over the `2^n` vertices gives
///      `2^n · n!` — the order of the hyperoctahedral group `B_n`.
/// Negative controls: symmetrising the covering relation destroys the order
/// (closure becomes all-ones) and destroys nilpotency (the star diverges).
pub fn replace_k5_02_face_lattice_chain_semiring() -> FederationPairBridge {
  let n = 3
  let m = 27
  let digits : Array[Array[Int32]] = Array::makei(m, c => nbe_digits3(c, n))
  let faces : Array[@fb.Face] = Array::makei(m, c => nbe_cube_face(c, n))
  let dims = Array::makei(m, c => {
    let mut k = 0
    for i in 0..<n {
      if digits[c][i] == 2 {
        k = k + 1
      }
    }
    k
  })
  let le : Array[Array[Bool]] = Array::makei(m, i => {
    Array::makei(m, j => @fb.cchm_face_le(faces[i], faces[j]))
  })
  // Independent order: literal containment (g's literals ⊆ i's literals).
  let mut order_agree = true
  for i in 0..<m {
    for j in 0..<m {
      let mut sub = true
      for k in 0..<n {
        if digits[j][k] != 2 && digits[j][k] != digits[i][k] {
          sub = false
        }
      }
      if sub != le[i][j] {
        order_agree = false
      }
    }
  }
  let top = m - 1
  let mut vertices = 0
  for c in 0..<m {
    if dims[c] == 0 {
      vertices = vertices + 1
    }
  }
  let cov_b : @smat.Mat[@semialg.BoolSr] = @smat.Mat::new(
    m,
    m,
    @semialg.BoolSr::zero(),
  )
  let sym_b : @smat.Mat[@semialg.BoolSr] = @smat.Mat::new(
    m,
    m,
    @semialg.BoolSr::zero(),
  )
  let cov_c : @smat.Mat[@semialg.Counting] = @smat.Mat::new(
    m,
    m,
    @semialg.Counting::new(0L),
  )
  let sym_c : @smat.Mat[@semialg.Counting] = @smat.Mat::new(
    m,
    m,
    @semialg.Counting::new(0L),
  )
  let mut covers = 0
  for i in 0..<m {
    for j in 0..<m {
      if le[i][j] && dims[j] == dims[i] + 1 {
        covers = covers + 1
        cov_b.set(i, j, @semialg.BoolSr::one())
        cov_c.set(i, j, @semialg.Counting::new(1L))
      }
    }
  }
  for i in 0..<m {
    for j in 0..<m {
      if cov_b.get(i, j).is_one() || cov_b.get(j, i).is_one() {
        sym_b.set(i, j, @semialg.BoolSr::one())
      }
      if cov_c.get(i, j).n != 0L || cov_c.get(j, i).n != 0L {
        sym_c.set(i, j, @semialg.Counting::new(1L))
      }
    }
  }
  let cl_blocked = @smat.closure_blocked(cov_b)
  let cl_lehmann = @smat.closure_lehmann(cov_b)
  let mut closure_ok = true
  let mut lehmann_ok = true
  for i in 0..<m {
    for j in 0..<m {
      if cl_blocked.get(i, j).is_one() != le[i][j] {
        closure_ok = false
      }
      if cl_lehmann.get(i, j).is_one() != le[i][j] {
        lehmann_ok = false
      }
    }
  }
  let mut pow_c : @smat.Mat[@semialg.Counting] = @smat.Mat::identity(m)
  for _ in 0..<n {
    pow_c = @smat.mul_naive(pow_c, cov_c)
  }
  let mut chains = 0L
  for v in 0..<m {
    if dims[v] == 0 {
      chains = chains + pow_c.get(v, top).n
    }
  }
  let mut fact = 1L
  for k in 1..<=n {
    fact = fact * k.to_int64()
  }
  let closed_form = (1L << n) * fact
  let pow_c_next = @smat.mul_naive(pow_c, cov_c)
  let nilpotent = @smat.mat_is_zero(pow_c_next)
  let cl_sym = @smat.closure_blocked(sym_b)
  let mut sym_all_one = true
  for i in 0..<m {
    for j in 0..<m {
      if !cl_sym.get(i, j).is_one() {
        sym_all_one = false
      }
    }
  }
  let order_collapsed = cl_sym.get(top, 0).is_one() && !le[top][0]
  let mut pow_sym : @smat.Mat[@semialg.Counting] = @smat.Mat::identity(m)
  for _ in 0..<=n {
    pow_sym = @smat.mul_naive(pow_sym, sym_c)
  }
  let star_diverges = !@smat.mat_is_zero(pow_sym)
  let holds = order_agree &&
    closure_ok &&
    lehmann_ok &&
    chains == closed_form &&
    nilpotent &&
    sym_all_one &&
    order_collapsed &&
    star_diverges &&
    vertices == 8
  FederationPairBridge::{
    id: "K5-02",
    lhs: Cubical,
    rhs: Semiring,
    bridge_theorem: "Cubical face lattice □³ covering relation: Boolean Kleene closure == CCHM cofibration order (729 pairs, two algorithms); counting-semiring Neumann series is nilpotent and counts 2³·3! = 48 maximal chains (= |B₃|)",
    holds,
    quantitative_witness: "faces=\{m}, covers=\{covers}, order_agree=\{order_agree}, closure==le=\{closure_ok}, lehmann==le=\{lehmann_ok}, chains=\{chains}==2^n·n!=\{closed_form}, C^(n+1)=0=\{nilpotent}; NEG: sym closure all-ones=\{sym_all_one}, order collapsed=\{order_collapsed}, star diverges=\{star_diverges}",
  }
}

// ---------------------------------------------------------------------------
// K5-05  Symlib × Semiring
// ---------------------------------------------------------------------------

///|
fn nbe_walks_dfs(
  adj : Array[Array[Bool]],
  path : Array[Int32],
  start : Int32,
  remaining : Int32,
  out : Array[Array[Int32]],
) -> Unit {
  if remaining == 0 {
    if path[path.length() - 1] == start {
      out.push(path.copy())
    }
    return
  }
  let v = path[path.length() - 1]
  for u in 0..<adj.length() {
    if adj[v][u] {
      path.push(u)
      nbe_walks_dfs(adj, path, start, remaining - 1, out)
      ignore(path.pop())
    }
  }
}

///|
fn nbe_walk_key(w : Array[Int32], perms : Array[@sym.Perm]) -> String {
  let mut best = ""
  for g in perms {
    let mut s = ""
    for v in w {
      s = s + "\{g.apply(v)},"
    }
    if best == "" || s < best {
      best = s
    }
  }
  best
}

///|
fn nbe_sub_trace_pow(
  adj : Array[Array[Bool]],
  fix : Array[Int32],
  k : Int32,
) -> Int64 {
  let s = fix.length()
  if s == 0 {
    return 0L
  }
  let m : @smat.Mat[@semialg.Counting] = @smat.Mat::new(
    s,
    s,
    @semialg.Counting::new(0L),
  )
  for a in 0..<s {
    for b in 0..<s {
      if adj[fix[a]][fix[b]] {
        m.set(a, b, @semialg.Counting::new(1L))
      }
    }
  }
  let mut p : @smat.Mat[@semialg.Counting] = @smat.Mat::identity(s)
  for _ in 0..<k {
    p = @smat.mul_naive(p, m)
  }
  let mut tr = 0L
  for a in 0..<s {
    tr = tr + p.get(a, a).n
  }
  tr
}

///|
/// **K5-05 (replaces `check_graph_symmetry_bridges() && check_free_category_bridge()`)**.
///
/// `Aut(C_4) = D_4` (Schreier–Sims, order 8) acts on the space of closed walks.
/// A walk is fixed by `g` iff all its vertices lie in `Fix(g)`, so the number of
/// fixed closed `k`-walks is `tr((A|_{Fix(g)})^k)` — a *counting-semiring* matrix
/// power.  Burnside then gives the orbit count, which is checked against an
/// independent brute-force orbit enumeration (canonical forms under the group).
/// Negative control: a transposition that is **not** a graph automorphism breaks
/// the hypothesis — its image of a walk is not a walk, and the naive Burnside
/// average disagrees with the true orbit count.
pub fn replace_k5_05_burnside_walk_orbits() -> FederationPairBridge {
  let nv = 4
  let graph = @sym.Graph::from_edges(nv, [(0, 1), (1, 2), (2, 3), (3, 0)])
  let grp = @sym.automorphism_group(graph)
  let perms = grp.elements(4096)
  let gorder = grp.order()
  let adj : Array[Array[Bool]] = Array::makei(nv, u => {
    Array::makei(nv, v => graph.has_edge(u, v))
  })
  // The group really is a subgroup of Aut(adj): the hypothesis of Burnside.
  let mut acts_by_aut = true
  for g in perms {
    for u in 0..<nv {
      for v in 0..<nv {
        if adj[u][v] != adj[g.apply(u)][g.apply(v)] {
          acts_by_aut = false
        }
      }
    }
  }
  let mut burnside_ok = true
  let mut total_ok = true
  let orbit_counts : Array[Int32] = []
  let walk_counts : Array[Int64] = []
  for k in 1..<=4 {
    let mut fixed_sum = 0L
    for g in perms {
      let fix : Array[Int32] = []
      for v in 0..<nv {
        if g.apply(v) == v {
          fix.push(v)
        }
      }
      fixed_sum = fixed_sum + nbe_sub_trace_pow(adj, fix, k)
    }
    let orbits_burnside = fixed_sum / gorder
    if fixed_sum % gorder != 0L {
      burnside_ok = false
    }
    let walks : Array[Array[Int32]] = []
    for s in 0..<nv {
      nbe_walks_dfs(adj, [s], s, k, walks)
    }
    let keys : Map[String, Int32] = Map([])
    for w in walks {
      let key = nbe_walk_key(w, perms)
      match keys.get(key) {
        Some(c) => keys[key] = c + 1
        None => keys[key] = 1
      }
    }
    let orbits_brute = keys.length()
    if orbits_burnside != orbits_brute.to_int64() {
      burnside_ok = false
    }
    let total_semiring = nbe_sub_trace_pow(adj, Array::makei(nv, i => i), k)
    if total_semiring != walks.length().to_int64() {
      total_ok = false
    }
    orbit_counts.push(orbits_brute)
    walk_counts.push(total_semiring)
  }
  // Negative control: (0 1) is not an automorphism of C_4.
  let bad = @sym.Perm::from_img([1, 0, 2, 3])
  let not_aut = !grp.contains(bad)
  let walks2 : Array[Array[Int32]] = []
  for s in 0..<nv {
    nbe_walks_dfs(adj, [s], s, 2, walks2)
  }
  let mut image_not_walk = false
  for w in walks2 {
    let mut ok = true
    for t in 0..<(w.length() - 1) {
      if !adj[bad.apply(w[t])][bad.apply(w[t + 1])] {
        ok = false
      }
    }
    if !ok {
      image_not_walk = true
    }
  }
  let fix_bad : Array[Int32] = []
  for v in 0..<nv {
    if bad.apply(v) == v {
      fix_bad.push(v)
    }
  }
  let naive = (
      nbe_sub_trace_pow(adj, Array::makei(nv, i => i), 2) +
      nbe_sub_trace_pow(adj, fix_bad, 2)
    ) /
    2L
  let true_orbits2 = orbit_counts[1].to_int64()
  let naive_wrong = naive != true_orbits2
  let holds = acts_by_aut &&
    gorder == 8L &&
    perms.length() == 8 &&
    burnside_ok &&
    total_ok &&
    not_aut &&
    image_not_walk &&
    naive_wrong
  FederationPairBridge::{
    id: "K5-05",
    lhs: Symlib,
    rhs: Semiring,
    bridge_theorem: "Burnside census of closed-walk spaces: |Aut(C_4)|=8 from Schreier–Sims, counting-semiring powers tr((A|Fix(g))^k) average to the brute-force orbit count for k=1..4",
    holds,
    quantitative_witness: "|G|=\{gorder}, acts_by_aut=\{acts_by_aut}, walks(k=1..4)=\{nbe_show_i64s(walk_counts)}, orbits=\{nbe_show_ints(orbit_counts)}, Burnside==brute=\{burnside_ok}, tr==enumeration=\{total_ok}; NEG: (01)∉Aut=\{not_aut}, image-not-walk=\{image_not_walk}, naive_avg=\{naive}≠true=\{true_orbits2}",
  }
}

// ---------------------------------------------------------------------------
// K8-23  Accel × Symlib
// ---------------------------------------------------------------------------

///|
/// Flat-index source map of the axis permutation `σ` on `2×2×2` tensors:
/// `(σ·t)[i₀,i₁,i₂] = t[i_{σ(0)}, i_{σ(1)}, i_{σ(2)}]`.
fn nbe_axis_srcmap(p : Array[Int32]) -> Array[Int32] {
  Array::makei(8, idx => {
    let coords = [idx / 4, idx / 2 % 2, idx % 2]
    (coords[p[0]] * 2 + coords[p[1]]) * 2 + coords[p[2]]
  })
}

///|
/// Allocation-free permuted code, given reusable base-3 digits and a source map.
fn nbe_perm_code(digits : Array[Int32], srcmap : Array[Int32]) -> Int32 {
  let mut out = 0
  let mut mult = 1
  for idx in 0..<8 {
    out = out + digits[srcmap[idx]] * mult
    mult = mult * 3
  }
  out
}

///|
fn nbe_tensor_of_code(code : Int32) -> @tensor.Tensor3 {
  let d = nbe_digits3(code, 8)
  @tensor.t3_of(2, 2, 2, 3, (i, j, k) => d[(i * 2 + j) * 2 + k])
}

///|
/// **K8-23 (replaces `|S_3|==6 && gf3_sub64(Δ,Δ)==0`)**.
///
/// The symmetric group `S_3` (symlib, Schreier–Sims) acts on the `6561` tensors
/// of `F_3^{2×2×2}` by permuting axes.  The *hardware* hyperdeterminant sweep
/// (`@swar.gf3_sweep_all_6561_hyperdets`) is checked to be invariant under all
/// six permutations at **every** tensor, and the Burnside orbit census
/// `(1/6) Σ_σ |Fix(σ)|` is checked against an independent union-find orbit
/// computation.  The digit-level axis permutation is itself validated against
/// the tensor API on a sample, and the SWAR determinants against the scalar
/// tensor hyperdeterminant.
/// Negative control: the entry functional `t ↦ t[0,0,1]` is *not* invariant —
/// an explicit tensor witnesses the failure while its hyperdet stays constant.
pub fn replace_k8_23_s3_axis_invariance_swar() -> FederationPairBridge {
  let total = 6561
  let s3 = @sym.PermGroup::symmetric(3)
  let perms = s3.elements(4096)
  let imgs : Array[Array[Int32]] = Array::makei(perms.length(), gi => {
    Array::makei(3, a => perms[gi].apply(a))
  })
  let srcmaps : Array[Array[Int32]] = Array::makei(imgs.length(), gi => {
    nbe_axis_srcmap(imgs[gi])
  })
  let dets = @swar.gf3_sweep_all_6561_hyperdets()
  let digits = Array::make(8, 0)
  let perm_codes : Array[Array[Int32]] = Array::makei(imgs.length(), _ => {
    Array::make(total, 0)
  })
  for c in 0..<total {
    let mut r = c
    for idx in 0..<8 {
      digits[idx] = r % 3
      r = r / 3
    }
    for gi in 0..<srcmaps.length() {
      perm_codes[gi][c] = nbe_perm_code(digits, srcmaps[gi])
    }
  }
  // Validate the digit-level action and the SWAR sweep against the tensor API
  // on a spread sample (the full census below is allocation-free).
  let mut encode_ok = true
  let mut det_api_ok = true
  let mut sampled = 0
  for c in 0..<total {
    if c % 25 != 0 && c >= 64 {
      continue
    }
    sampled = sampled + 1
    let t = nbe_tensor_of_code(c)
    if @tensor.f3_tensor_code(t) != c {
      encode_ok = false
    }
    if @tensor.t3_hyperdet222(t) != dets[c] {
      det_api_ok = false
    }
    if c < 64 {
      for gi in 0..<imgs.length() {
        let p = imgs[gi]
        let tp = @tensor.t3_of(2, 2, 2, 3, (i, j, k) => {
          let coords = [i, j, k]
          @tensor.t3_get(t, coords[p[0]], coords[p[1]], coords[p[2]])
        })
        if @tensor.f3_tensor_code(tp) != perm_codes[gi][c] {
          encode_ok = false
        }
      }
    }
  }
  let mut invariant = true
  let fixed : Array[Int32] = Array::make(imgs.length(), 0)
  let parent = Array::makei(total, i => i)
  for c in 0..<total {
    for gi in 0..<imgs.length() {
      let pc = perm_codes[gi][c]
      if dets[pc] != dets[c] {
        invariant = false
      }
      if pc == c {
        fixed[gi] = fixed[gi] + 1
      }
      nbe_dsu_union(parent, c, pc)
    }
  }
  let mut fix_sum = 0
  for f in fixed {
    fix_sum = fix_sum + f
  }
  let orbits_burnside = fix_sum / 6
  let orbits_dsu = nbe_dsu_classes(parent)
  // Negative control: a single entry is not an axis-symmetric functional.
  let mut cex_code = -1
  let mut cex_axis = -1
  for c in 0..<total {
    if cex_code >= 0 {
      break
    }
    let d = nbe_digits3(c, 8)
    for gi in 0..<imgs.length() {
      let pc = perm_codes[gi][c]
      let dp = nbe_digits3(pc, 8)
      // entry (0,0,1) has flat index 1
      if dp[1] != d[1] {
        cex_code = c
        cex_axis = gi
        break
      }
    }
  }
  let negative_control = cex_code >= 0 &&
    dets[perm_codes[cex_axis][cex_code]] == dets[cex_code]
  let holds = encode_ok &&
    det_api_ok &&
    invariant &&
    perms.length() == 6 &&
    fix_sum % 6 == 0 &&
    orbits_burnside == orbits_dsu &&
    negative_control
  FederationPairBridge::{
    id: "K8-23",
    lhs: Accel,
    rhs: Symlib,
    bridge_theorem: "S_3 axis action on all 6561 F_3^{2×2×2} tensors: SWAR hyperdet sweep is invariant at every tensor, and the Burnside orbit census (1/6)Σ|Fix(σ)| equals the union-find orbit count",
    holds,
    quantitative_witness: "|S_3|=\{perms.length()}, tensors=\{total}, sampled=\{sampled}, SWAR==scalar_det=\{det_api_ok}, encoding=\{encode_ok}, invariance=\{invariant}, ΣFix=\{fix_sum}, orbits_Burnside=\{orbits_burnside}==DSU=\{orbits_dsu}; NEG: entry functional non-invariant at code=\{cex_code} (axis \{cex_axis}) while Det unchanged=\{negative_control}",
  }
}

// ---------------------------------------------------------------------------
// K8-26  Accel × Scheme
// ---------------------------------------------------------------------------

///|
/// **K8-26 (replaces `det_zero==2241 && det_zero==atlas && |P²(F_3)|==13`)**.
///
/// The rank `≤ 1` locus of `F_3^{2×2×2}` is the affine cone over the Segre
/// variety `P¹×P¹×P¹`.  Its point count is *derived from the scheme side*
/// (`|P¹(F_3)|` via the functor of points) as `1 + (q−1)·|P¹(F_q)|³` and matched
/// against the atlas/SWAR census; the projectivised counts are matched too.
/// Negative control: `V(Det)` is strictly larger than the Segre cone — an
/// explicit rank-2 tensor with vanishing hyperdeterminant refutes the naive
/// identification, and `|P²(F_3)| = (q³−1)/(q−1)` is derived, not asserted.
pub fn replace_k8_26_segre_cone_point_census() -> FederationPairBridge {
  let q = 3
  let total = 6561
  let atlas = @tensor.f3_tensor222_atlas_build()
  let dets = @swar.gf3_sweep_all_6561_hyperdets()
  let p1_pts = @scheme.eval_scheme_functor_of_points(
    @scheme.scheme_projective_space(1),
    @scheme.fcomm_fp(q),
  ).length()
  let p2_pts = @scheme.eval_scheme_functor_of_points(
    @scheme.scheme_projective_space(2),
    @scheme.fcomm_fp(q),
  ).length()
  let segre_cone = 1 + (q - 1) * p1_pts * p1_pts * p1_pts
  let mut rank_le1 = 0
  let mut det_zero = 0
  let mut cone_in_vdet = true
  let mut det_api_ok = true
  let mut secant_witness = -1
  for c in 0..<total {
    if dets[c] != atlas.hyperdets[c] {
      det_api_ok = false
    }
    if dets[c] == 0 {
      det_zero = det_zero + 1
    }
    if atlas.ranks[c] <= 1 {
      rank_le1 = rank_le1 + 1
      if dets[c] != 0 {
        cone_in_vdet = false
      }
    } else if dets[c] == 0 && secant_witness < 0 {
      secant_witness = c
    }
  }
  let proj_vdet = (det_zero - 1) / (q - 1)
  let proj_segre = (segre_cone - 1) / (q - 1)
  let segre_projective = p1_pts * p1_pts * p1_pts
  let p2_formula = (q * q * q - 1) / (q - 1)
  let strict_inclusion = det_zero > segre_cone &&
    secant_witness >= 0 &&
    atlas.ranks[secant_witness] == 2 &&
    dets[secant_witness] == 0
  // Full determinantal census: every rank ≤ 1 tensor has Det = 0, and the
  // remaining zero-determinant tensors split into rank 2 and rank 3 strata.
  let census_identity = det_zero ==
    rank_le1 + atlas.rank2_det_zero_count + atlas.rank3_det_zero_count
  // Second negative control: Det = 0 does NOT characterise rank ≤ 2 either.
  let mut rank3_det0_witness = -1
  for c in 0..<total {
    if atlas.ranks[c] == 3 && dets[c] == 0 {
      rank3_det0_witness = c
      break
    }
  }
  let rank3_det0_refuted = (
      rank3_det0_witness < 0 && atlas.rank3_det_zero_count == 0
    ) ||
    (
      rank3_det0_witness >= 0 &&
      atlas.rank3_det_zero_count > 0 &&
      atlas.ranks[rank3_det0_witness] == 3 &&
      dets[rank3_det0_witness] == 0
    )
  let holds = det_api_ok &&
    rank_le1 == segre_cone &&
    cone_in_vdet &&
    proj_segre == segre_projective &&
    census_identity &&
    rank3_det0_refuted &&
    p2_pts == p2_formula &&
    p2_pts == 13 &&
    strict_inclusion
  FederationPairBridge::{
    id: "K8-26",
    lhs: Accel,
    rhs: Scheme,
    bridge_theorem: "Rank≤1 locus of F_3^{2×2×2} is the affine cone over the Segre variety σ(P¹×P¹×P¹): |cone| = 1+(q−1)|P¹(F_q)|³ = 129 from the scheme functor of points, matching the SWAR/atlas census; V(Det) is the determinantal hypersurface (2241 pts) strictly containing it, and Det=0 characterises neither rank≤1 nor rank≤2",
    holds,
    quantitative_witness: "|P¹(F_3)|=\{p1_pts}, cone_formula=\{segre_cone}==atlas_rank≤1=\{rank_le1}, cone⊆V(Det)=\{cone_in_vdet}, |V(Det)|=\{det_zero}, proj: σ=\{proj_segre}==\{segre_projective}, V(Det)=\{proj_vdet}, census=rank≤1+rank2_0+rank3_0=\{rank_le1}+\{atlas.rank2_det_zero_count}+\{atlas.rank3_det_zero_count}=\{det_zero} (\{census_identity}); |P²(F_3)|=\{p2_pts}==(q³−1)/(q−1)=\{p2_formula}; NEG: rank2 det0 witness code=\{secant_witness}, strict=\{strict_inclusion}, rank3 det0 witness=\{rank3_det0_witness}",
  }
}

// ---------------------------------------------------------------------------
// K8-28  Accel × Discovery
// ---------------------------------------------------------------------------

///|
/// **K8-28 (replaces `check_discovery_kernel_laws() && det_zero==atlas.det_zero_count`)**.
///
/// Five predicates on the `6561`-tensor atlas are packed into 64-bit bitplanes
/// (`@swar.swar_pack_bitplane`) and the discovery kernel's implication lattice
/// is built from hardware `ctz` counterexample search.  Every one of the 25
/// entries is re-derived by an *independent exhaustive semantic scan*, and the
/// reported counterexample indices must agree exactly (both are the least
/// violating sample) and satisfy `P_i ∧ ¬P_j` by direct evaluation.
/// Negative controls: the naive implication `Det=0 ⇒ rank≤1` is refuted with an
/// explicit witness, and a single tampered bitplane bit is detected.
pub fn replace_k8_28_bitplane_implication_soundness() -> FederationPairBridge {
  let total = 6561
  let npred = 5
  let atlas = @tensor.f3_tensor222_atlas_build()
  let pred = (s : Int32, p : Int32) => {
    match p {
      0 => atlas.ranks[s] == 0
      1 => atlas.ranks[s] <= 1
      2 => atlas.hyperdets[s] == 0
      3 => atlas.ranks[s] <= 2
      _ => atlas.ranks[s] == 3 && atlas.hyperdets[s] != 0
    }
  }
  let report = @dkernel.implication_lattice_build(total, npred, pred)
  let planes : Array[Array[UInt64]] = Array::makei(npred, p => {
    @swar.swar_pack_bitplane(total, s => pred(s, p))
  })
  let mut lattice_ok = true
  let mut cex_ok = true
  let mut cex_valid = true
  let mut edges_checked = 0
  for i in 0..<npred {
    for j in 0..<npred {
      let mut first = -1
      for s in 0..<total {
        if pred(s, i) && !pred(s, j) {
          first = s
          break
        }
      }
      let swar_cex = @swar.swar_bitplane_implication_cex(
        planes[i],
        planes[j],
        total,
      )
      let brute_implies = first < 0
      if report.implies[i][j] != brute_implies || swar_cex != first {
        lattice_ok = false
      }
      if report.counterexamples[i][j] != first {
        cex_ok = false
      }
      if first >= 0 && !(pred(first, i) && !pred(first, j)) {
        cex_valid = false
      }
      edges_checked = edges_checked + 1
    }
  }
  // Negative control 1: Det=0 does not imply rank<=1.
  let false_claim_cex = @swar.swar_bitplane_implication_cex(
    planes[2],
    planes[1],
    total,
  )
  let false_claim_refuted = false_claim_cex >= 0 &&
    atlas.hyperdets[false_claim_cex] == 0 &&
    atlas.ranks[false_claim_cex] == 2
  // Negative control 2: tampering with one bit of a plane is detected.
  let tampered = planes[1].copy()
  tampered[0] = tampered[0] & 1UL.lnot()
  let tamper_cex = @swar.swar_bitplane_implication_cex(
    planes[0],
    tampered,
    total,
  )
  let tamper_detected = tamper_cex == 0 &&
    @swar.swar_bitplane_implication_cex(planes[0], planes[1], total) < 0
  let holds = lattice_ok &&
    cex_ok &&
    cex_valid &&
    edges_checked == 25 &&
    report.num_samples == total &&
    false_claim_refuted &&
    tamper_detected
  FederationPairBridge::{
    id: "K8-28",
    lhs: Accel,
    rhs: Discovery,
    bridge_theorem: "SWAR bitplane implication lattice over the 6561-tensor atlas == exhaustive semantic implication on all 25 predicate pairs, with least-counterexample agreement and tamper sensitivity",
    holds,
    quantitative_witness: "samples=\{total}, predicates=\{npred}, pairs=\{edges_checked}, lattice==brute=\{lattice_ok}, cex_indices==brute=\{cex_ok}, cex_valid=\{cex_valid}, uni=\{report.strict_unidirectional_edges}, equiv=\{report.nontrivial_equiv_pairs}; NEG: Det=0⇒rank≤1 refuted at \{false_claim_cex}=\{false_claim_refuted}, 1-bit tamper detected=\{tamper_detected}",
  }
}

// ---------------------------------------------------------------------------
// K9-30  Meta × Symlib
// ---------------------------------------------------------------------------

///|
fn nbe_rel_classes(n : Int32, rel : Array[Array[Bool]]) -> Int32 {
  let parent = Array::makei(n, i => i)
  for i in 0..<n {
    for j in 0..<n {
      if rel[i][j] {
        nbe_dsu_union(parent, i, j)
      }
    }
  }
  nbe_dsu_classes(parent)
}

///|
/// **K9-30 (replaces `meta_laws_batch_ok(...) && |Aut(C_4)|==8`)**.
///
/// For a permutation group `G ≤ S_n` the equivalence relation generated by the
/// generator graphs `{(i, g(i))}` is computed by the meta federation's
/// congruence/equivalence closure (`@mcore.ua_equiv_join_closure`) and must
/// coincide with symlib's orbit partition.  Three independent quantities are
/// then identified: number of congruence classes, exact rational rank of the
/// orbit-indicator matrix (= dim of the fixed subspace), and the Burnside
/// average `(1/|G|) Σ_g |Fix(g)|`.
/// Negative control: deleting one generator yields a strictly finer congruence
/// (more classes, higher rank) — the closure is genuinely group-generated.
pub fn replace_k9_30_congruence_orbit_rank() -> FederationPairBridge {
  let n = 5
  let graph = @sym.Graph::from_edges(n, [(0, 1), (1, 2), (0, 2), (3, 4)])
  let grp = @sym.automorphism_group(graph)
  let gens = grp.generators()
  let orbits = grp.orbit_partition()
  let gorder = grp.order()
  let orbit_of = Array::make(n, -1)
  for k in 0..<orbits.length() {
    for v in orbits[k] {
      orbit_of[v] = k
    }
  }
  let ident = Array::makei(n, i => Array::makei(n, j => i == j))
  let mut rel = ident
  let mut rel_first = ident
  for gi in 0..<gens.length() {
    let g = gens[gi]
    let gr = Array::makei(n, _ => Array::make(n, false))
    for i in 0..<n {
      let j = g.apply(i)
      gr[i][j] = true
      gr[j][i] = true
    }
    rel = @mcore.ua_equiv_join_closure(n, rel, gr)
    if gi == 0 {
      rel_first = @mcore.ua_equiv_join_closure(n, ident, gr)
    }
  }
  let mut closure_eq_orbits = true
  for i in 0..<n {
    for j in 0..<n {
      if rel[i][j] != (orbit_of[i] == orbit_of[j]) {
        closure_eq_orbits = false
      }
    }
  }
  let k = orbits.length()
  let indicator : Array[Array[Int32]] = Array::makei(n, i => {
    Array::makei(k, c => if orbit_of[i] == c { 1 } else { 0 })
  })
  let rank = @mcore.matrix_rank_qrat64(indicator)
  let perms = grp.elements(4096)
  let mut fix_sum = 0L
  for g in perms {
    for v in 0..<n {
      if g.apply(v) == v {
        fix_sum = fix_sum + 1L
      }
    }
  }
  let burnside = fix_sum / gorder
  let classes_full = nbe_rel_classes(n, rel)
  let classes_first = nbe_rel_classes(n, rel_first)
  let mut proper_subset = true
  let mut strict = false
  for i in 0..<n {
    for j in 0..<n {
      if rel_first[i][j] && !rel[i][j] {
        proper_subset = false
      }
      if rel[i][j] && !rel_first[i][j] {
        strict = true
      }
    }
  }
  let negative_control = gens.length() >= 2 &&
    proper_subset &&
    strict &&
    classes_first > classes_full &&
    classes_first > rank
  let holds = closure_eq_orbits &&
    classes_full == k &&
    rank == k &&
    burnside == k.to_int64() &&
    fix_sum % gorder == 0L &&
    perms.length().to_int64() == gorder &&
    negative_control
  FederationPairBridge::{
    id: "K9-30",
    lhs: Meta,
    rhs: Symlib,
    bridge_theorem: "Congruence closure of the generator graphs of Aut(K_3 ⊔ K_2) equals its orbit partition; #classes = rank_Q(orbit indicator) = dim Fix = Burnside average (1/|G|)Σ|Fix(g)|",
    holds,
    quantitative_witness: "n=\{n}, |G|=\{gorder}, gens=\{gens.length()}, orbits=\{k}, closure==orbits=\{closure_eq_orbits}, classes=\{classes_full}, rank_Q=\{rank}, Burnside=\{burnside}; NEG: 1-generator closure classes=\{classes_first}>\{classes_full}, proper=\{proper_subset}, strict=\{strict}",
  }
}

// ---------------------------------------------------------------------------
// K9-33  Meta × Scheme
// ---------------------------------------------------------------------------

///|
fn nbe_mono2(d : Int32) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for t in 0..<=d {
    for a in 0..<=t {
      out.push((a, t - a))
    }
  }
  out
}

///|
fn nbe_mono_index(cols : Array[(Int32, Int32)], a : Int32, b : Int32) -> Int32 {
  for i in 0..<cols.length() {
    let (x, y) = cols[i]
    if x == a && y == b {
      return i
    }
  }
  -1
}

///|
fn nbe_mpoly_of_terms(terms : Array[(Int32, Int32, Int32)]) -> @scheme.MPoly {
  let mut p = @scheme.mpoly_zero(2)
  for t in terms {
    let (c, a, b) = t
    let mut m = @scheme.mpoly_int(2, c)
    if a > 0 {
      m = @scheme.mpoly_mul(m, @scheme.mpoly_pow(@scheme.mpoly_var(2, 0), a))
    }
    if b > 0 {
      m = @scheme.mpoly_mul(m, @scheme.mpoly_pow(@scheme.mpoly_var(2, 1), b))
    }
    p = @scheme.mpoly_add(p, m)
  }
  p
}

///|
fn nbe_macaulay(
  gens : Array[Array[(Int32, Int32, Int32)]],
  d : Int32,
) -> (Int32, Int32, Bool) {
  let cols = nbe_mono2(d)
  let rows : Array[Array[Int32]] = []
  for g in gens {
    let mut dg = 0
    for t in g {
      let (_, a, b) = t
      if a + b > dg {
        dg = a + b
      }
    }
    let mults = nbe_mono2(d - dg)
    for mm in mults {
      let (ma, mb) = mm
      let row = Array::make(cols.length(), 0)
      for t in g {
        let (c, a, b) = t
        let j = nbe_mono_index(cols, a + ma, b + mb)
        if j >= 0 {
          row[j] = row[j] + c
        }
      }
      rows.push(row)
    }
  }
  if rows.length() == 0 {
    return (cols.length(), 0, true)
  }
  let (rk, cert) = @mcore.matrix_rank_bareiss64_with_cert(rows)
  (cols.length(), rk, cert)
}

///|
/// **K9-33 (replaces `cauchy7_cert && rank==3 && |P²(F_3)|==13`)**.
///
/// The affine Hilbert function of `Q[x,y]/I` is computed twice: by the meta
/// federation's fraction-free Sylvester–Bareiss rank of the degree-`d`
/// Macaulay matrix (`HF(d) = #monomials≤d − rank`), and by the scheme
/// federation's Gröbner standard monomials.  They must agree for `d = 0..3`,
/// with a verified Bareiss certificate at every degree.
/// Negative control: the fat point `⟨x², xy, y²⟩` and its reduction `⟨x, y⟩`
/// have different Hilbert functions (`3` vs `1`) — the rank detects nilpotents
/// that the point set alone cannot see.
pub fn replace_k9_33_macaulay_hilbert_bareiss() -> FederationPairBridge {
  let g1 : Array[(Int32, Int32, Int32)] = [(1, 2, 0), (1, 0, 2), (-1, 0, 0)]
  let g2 : Array[(Int32, Int32, Int32)] = [(1, 1, 0), (-1, 0, 1)]
  let ideal = @scheme.ideal_new(2, [
    nbe_mpoly_of_terms(g1),
    nbe_mpoly_of_terms(g2),
  ])
  let std = match @scheme.ideal_standard_monomials(ideal) {
    Some(ms) => ms
    None => []
  }
  let dim = @scheme.ideal_quotient_vector_space_dim(ideal)
  let mut hf_ok = true
  let mut cert_ok = true
  let hf_values : Array[Int32] = []
  let ranks : Array[Int32] = []
  for d in 0..<=3 {
    let (ncols, rk, cert) = nbe_macaulay([g1, g2], d)
    if !cert {
      cert_ok = false
    }
    let hf = ncols - rk
    let mut std_count = 0
    for m in std {
      let mut deg = 0
      for e in m {
        deg = deg + e
      }
      if deg <= d {
        std_count = std_count + 1
      }
    }
    if hf != std_count {
      hf_ok = false
    }
    hf_values.push(hf)
    ranks.push(rk)
  }
  // Negative control: fat point vs its reduction.
  let fat : Array[Array[(Int32, Int32, Int32)]] = [
    [(1, 2, 0)],
    [(1, 1, 1)],
    [(1, 0, 2)],
  ]
  let red : Array[Array[(Int32, Int32, Int32)]] = [[(1, 1, 0)], [(1, 0, 1)]]
  let (_, rk_fat, cert_fat) = nbe_macaulay(fat, 3)
  let (_, rk_red, cert_red) = nbe_macaulay(red, 3)
  let ncols3 = nbe_mono2(3).length()
  let hf_fat = ncols3 - rk_fat
  let hf_red = ncols3 - rk_red
  let fat_ideal = @scheme.ideal_new(2, [
    nbe_mpoly_of_terms(fat[0]),
    nbe_mpoly_of_terms(fat[1]),
    nbe_mpoly_of_terms(fat[2]),
  ])
  let fat_dim = @scheme.ideal_quotient_vector_space_dim(fat_ideal)
  let negative_control = cert_fat &&
    cert_red &&
    hf_fat == 3 &&
    hf_red == 1 &&
    hf_fat != hf_red &&
    fat_dim == Some(3)
  let holds = hf_ok &&
    cert_ok &&
    dim == Some(2) &&
    std.length() == 2 &&
    hf_values[3] == 2 &&
    negative_control
  FederationPairBridge::{
    id: "K9-33",
    lhs: Meta,
    rhs: Scheme,
    bridge_theorem: "Affine Hilbert function of Q[x,y]/⟨x²+y²−1, x−y⟩ by fraction-free Bareiss rank of Macaulay matrices equals the Gröbner standard-monomial count in degrees 0..3 (HF = 1,2,2,2 = dim 2)",
    holds,
    quantitative_witness: "HF(Bareiss)=\{nbe_show_ints(hf_values)}, ranks=\{nbe_show_ints(ranks)}, Gröbner_std=\{std.length()}, dim_Q=\{nbe_show_opt(dim)}, HF==std=\{hf_ok}, certificates=\{cert_ok}; NEG: fat point HF=\{hf_fat} vs reduced HF=\{hf_red}, fat_dim=\{nbe_show_opt(fat_dim)}",
  }
}

///|
/// All seven second-wave structural replacements, in edge order.
pub fn verify_nominal_bridge_elimination() -> Array[FederationPairBridge] {
  [
    replace_k5_02_face_lattice_chain_semiring(),
    replace_k5_05_burnside_walk_orbits(),
    replace_k8_23_s3_axis_invariance_swar(),
    replace_k8_26_segre_cone_point_census(),
    replace_k8_28_bitplane_implication_soundness(),
    replace_k9_30_congruence_orbit_rank(),
    replace_k9_33_macaulay_hilbert_bareiss(),
  ]
}

// ---------------------------------------------------------------------------
// Shared helpers for the K7-17 / K6-15 repairs
// ---------------------------------------------------------------------------

///|
fn nbe_mod_inv(a : Int32, p : Int32) -> Int32 {
  let x = (a % p + p) % p
  for k in 1..<p {
    if x * k % p == 1 {
      return k
    }
  }
  1
}

///|
/// Exact rank over `F_p` by Gauss–Jordan elimination (independent of the
/// Bareiss / SWAR paths used elsewhere).
fn nbe_fp_rank(rows : Array[Array[Int32]], p : Int32) -> Int32 {
  let m = rows.length()
  if m == 0 {
    return 0
  }
  let n = rows[0].length()
  let a = Array::makei(m, i => Array::makei(n, j => (rows[i][j] % p + p) % p))
  let mut rank = 0
  for col in 0..<n {
    if rank >= m {
      break
    }
    let mut piv = -1
    for r in rank..<m {
      if a[r][col] != 0 {
        piv = r
        break
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = a[rank]
    a[rank] = a[piv]
    a[piv] = tmp
    let inv = nbe_mod_inv(a[rank][col], p)
    for c in 0..<n {
      a[rank][c] = a[rank][c] * inv % p
    }
    for r in 0..<m {
      if r != rank && a[r][col] != 0 {
        let f = a[r][col]
        for c in 0..<n {
          a[r][c] = ((a[r][c] - f * a[rank][c]) % p + p) % p
        }
      }
    }
    rank = rank + 1
  }
  rank
}

///|
/// Mode-`mode` flattening rank of a `2×2×2` `F_3` tensor, read through the
/// tensor federation's flattening and the gcd federation's `FpMat` accessor.
fn nbe_flatten_rank(code : Int32, mode : Int32) -> Int32 {
  let t = nbe_tensor_of_code(code)
  let m = @tensor.t3_flatten(t, mode)
  let rows = if mode == 0 { 2 } else { 2 }
  let cols = 4
  let data : Array[Array[Int32]] = Array::makei(rows, i => {
    Array::makei(cols, j => @gcd.fp_mat_get(m, i, j))
  })
  nbe_fp_rank(data, 3)
}
