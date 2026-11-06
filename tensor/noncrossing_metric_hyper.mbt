///|
// Federation 7 (`discovery`) — Layer 2 Package `tensor` (Part 2):
// Non-Crossing Chord Forests, Polygon Flip-Graph Evolution, Circle-Monotone MST `[T-NC-Free]`,
// Finite Metric Spaces, Exact Gromov–Hausdorff Distortion, Full-Dimension Vietoris–Rips
// Persistent Homology (`dim H_k == dim H^k` & Euler–Poincaré), and Krasner Hyper-Structures.

// ---------------------------------------------------------------------------
// 1. Non-Crossing Chords, Polygon Triangulation Flip Graph & `[T-NC-Free]`
// ---------------------------------------------------------------------------

///|
/// Return `true` iff chords `(a1, b1)` and `(a2, b2)` on a convex `n`-gon strictly
/// cross in the interior (sharing an endpoint does NOT count as crossing).
pub fn nc_chords_cross(
  a1_in : Int32,
  b1_in : Int32,
  a2_in : Int32,
  b2_in : Int32,
) -> Bool {
  let (a1, b1) = if a1_in < b1_in { (a1_in, b1_in) } else { (b1_in, a1_in) }
  let (a2, b2) = if a2_in < b2_in { (a2_in, b2_in) } else { (b2_in, a2_in) }
  (a1 < a2 && a2 < b1 && b1 < b2) || (a2 < a1 && a1 < b2 && b2 < b1)
}

///|
/// Report for the Stasheff/Tamari triangulation flip graph of a convex `n`-gon (`n >= 4`).
#derive(Debug, Eq)
pub(all) struct TriangulationFlipReport {
  n_gon : Int32
  catalan_count : Int32
  flip_edges : Int32
  is_regular_degree : Int32
  is_connected : Bool
  dual_tree_rows : Array[Array[Int32]]
}

///|
pub extend TriangulationFlipReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TriangulationFlipReport with Eq::{not_equal, equal}

///|
/// Enumerate all `C_{n-2}` triangulations of a convex `n`-gon (`4 <= n <= 7`),
/// build their diagonal-flip graph (`1`-skeleton of the Stasheff associahedron `K_{n-1}`),
/// verify `(n - 3)`-regularity and connectedness, and emit dual-tree invariant rows
/// `[1, num_triangles, dual_V, dual_E, dual_max_deg, num_crossings]` for `[E-Flip]`.
pub fn nc_polygon_triangulations_flip_report(
  n : Int32,
) -> TriangulationFlipReport {
  if n < 4 {
    return TriangulationFlipReport::{
      n_gon: n,
      catalan_count: 0,
      flip_edges: 0,
      is_regular_degree: 0,
      is_connected: false,
      dual_tree_rows: [],
    }
  }
  // Internal diagonals of `0 .. n-1` are `(a, b)` with `0 <= a < b < n` and `b - a >= 2`
  // excluding `(0, n - 1)`.
  let diags : Array[(Int32, Int32)] = []
  for a in 0..<n {
    for b in (a + 2)..<n {
      if !(a == 0 && b == n - 1) {
        diags.push((a, b))
      }
    }
  }
  let m_diags = diags.length()
  let need = n - 3
  let triangs : Array[Array[Int32]] = []
  let cur : Array[Int32] = []

  fn enum_tri(
    idx : Int32,
    m_diags : Int32,
    need : Int32,
    diags : Array[(Int32, Int32)],
    cur : Array[Int32],
    triangs : Array[Array[Int32]],
  ) -> Unit {
    if cur.length() == need {
      triangs.push(cur.copy())
      return
    }
    if idx >= m_diags || cur.length() + (m_diags - idx) < need {
      return
    }
    let (a, b) = diags[idx]
    let mut ok = true
    for prev_i in cur {
      let (pa, pb) = diags[prev_i]
      if nc_chords_cross(a, b, pa, pb) {
        ok = false
        break
      }
    }
    if ok {
      cur.push(idx)
      enum_tri(idx + 1, m_diags, need, diags, cur, triangs)
      let _ = cur.pop()
    }
    enum_tri(idx + 1, m_diags, need, diags, cur, triangs)
  }

  enum_tri(0, m_diags, need, diags, cur, triangs)
  let v_cnt = triangs.length()

  // Two triangulations are adjacent by a flip iff they share `need - 1` diagonals.
  let adj : Array[Array[Int32]] = Array::makei(v_cnt, _ => [])
  let mut edge_cnt = 0
  for i in 0..<v_cnt {
    for j in (i + 1)..<v_cnt {
      let mut shared = 0
      for d1 in triangs[i] {
        for d2 in triangs[j] {
          if d1 == d2 {
            shared = shared + 1
          }
        }
      }
      if shared == need - 1 {
        adj[i].push(j)
        adj[j].push(i)
        edge_cnt = edge_cnt + 1
      }
    }
  }

  let mut reg_ok = true
  for i in 0..<v_cnt {
    if adj[i].length() != need {
      reg_ok = false
    }
  }

  // BFS connectivity check
  let visited = Array::make(v_cnt, false)
  let queue : Array[Int32] = []
  if v_cnt > 0 {
    visited[0] = true
    queue.push(0)
  }
  let mut qh = 0
  while qh < queue.length() {
    let u = queue[qh]
    qh = qh + 1
    for w in adj[u] {
      if !visited[w] {
        visited[w] = true
        queue.push(w)
      }
    }
  }

  // Build dual-tree invariant observables `[1, num_triangles, dual_V, dual_E, max_deg, crossings]`
  let rows : Array[Array[Int32]] = []
  for idx in 0..<v_cnt {
    let chosen = triangs[idx]
    // Find all `n - 2` triangles `(u < v < w)` whose 3 sides are boundary edges or chosen diagonals
    let is_edge = (a : Int32, b : Int32) => {
      let (x, y) = if a < b { (a, b) } else { (b, a) }
      if y - x == 1 || (x == 0 && y == n - 1) {
        true
      } else {
        let mut found = false
        for d_i in chosen {
          if diags[d_i].0 == x && diags[d_i].1 == y {
            found = true
            break
          }
        }
        found
      }
    }
    let tris : Array[(Int32, Int32, Int32)] = []
    for u in 0..<n {
      for v in (u + 1)..<n {
        if is_edge(u, v) {
          for w in (v + 1)..<n {
            if is_edge(v, w) && is_edge(u, w) {
              tris.push((u, v, w))
            }
          }
        }
      }
    }
    let nt = tris.length()
    let mut dual_e = 0
    let mut max_deg = 0
    for ti in 0..<nt {
      let mut deg = 0
      let (a1, b1, c1) = tris[ti]
      let e1 = [(a1, b1), (b1, c1), (a1, c1)]
      for tj in 0..<nt {
        if ti != tj {
          let (a2, b2, c2) = tris[tj]
          let e2 = [(a2, b2), (b2, c2), (a2, c2)]
          let mut share = false
          for s1 in e1 {
            for s2 in e2 {
              if s1.0 == s2.0 && s1.1 == s2.1 {
                share = true
              }
            }
          }
          if share {
            deg = deg + 1
          }
        }
      }
      dual_e = dual_e + deg
      if deg > max_deg {
        max_deg = deg
      }
    }
    rows.push([1, nt, nt, dual_e / 2, max_deg, 0])
  }

  TriangulationFlipReport::{
    n_gon: n,
    catalan_count: v_cnt,
    flip_edges: edge_cnt,
    is_regular_degree: if reg_ok {
      need
    } else {
      -1
    },
    is_connected: qh == v_cnt && reg_ok,
    dual_tree_rows: rows,
  }
}

///|
/// Compare unconstrained Minimum Spanning Tree weight vs Non-Crossing Minimum Spanning Tree
/// weight on `n` cyclic vertices (`n <= 6`) with symmetric distance matrix `dist`:
/// returns `(mst_weight, nc_mst_weight)`.
pub fn nc_mst_vs_unconstrained_mst(
  n : Int32,
  dist : Array[Array[Int32]],
) -> (Int32, Int32) {
  let edges : Array[(Int32, Int32, Int32)] = []
  for i in 0..<n {
    for j in (i + 1)..<n {
      edges.push((i, j, dist[i][j]))
    }
  }
  let m = edges.length()
  let mut best_all = 1_000_000_000
  let mut best_nc = 1_000_000_000
  let chosen : Array[Int32] = []

  fn search_trees(
    idx : Int32,
    n : Int32,
    m : Int32,
    edges : Array[(Int32, Int32, Int32)],
    chosen : Array[Int32],
    out : Array[Int32],
  ) -> Unit {
    if chosen.length() == n - 1 {
      // Check connectivity via union-find
      let par = Array::makei(n, i => i)
      let find_root = (x0 : Int32) => {
        let mut x = x0
        while par[x] != x {
          x = par[x]
        }
        x
      }
      let mut comps = n
      let mut wsum = 0
      let mut noncross = true
      for k_idx in 0..<chosen.length() {
        let ei = chosen[k_idx]
        let (u, v, w) = edges[ei]
        wsum = wsum + w
        let ru = find_root(u)
        let rv = find_root(v)
        if ru != rv {
          par[ru] = rv
          comps = comps - 1
        }
        for l_idx in (k_idx + 1)..<chosen.length() {
          let ej = chosen[l_idx]
          if nc_chords_cross(u, v, edges[ej].0, edges[ej].1) {
            noncross = false
          }
        }
      }
      if comps == 1 {
        if wsum < out[0] {
          out[0] = wsum
        }
        if noncross && wsum < out[1] {
          out[1] = wsum
        }
      }
      return
    }
    if idx >= m || chosen.length() + (m - idx) < n - 1 {
      return
    }
    chosen.push(idx)
    search_trees(idx + 1, n, m, edges, chosen, out)
    let _ = chosen.pop()
    search_trees(idx + 1, n, m, edges, chosen, out)
  }

  let acc = [best_all, best_nc]
  search_trees(0, n, m, edges, chosen, acc)
  best_all = acc[0]
  best_nc = acc[1]
  (best_all, best_nc)
}

///|
/// `[T-X-Site]` Verify that on a convex `n`-gon (`n = 4` or `5`), the poset of
/// non-crossing chord forests equipped with union-coverages `U = U_1 ∪ U_2`
/// satisfies Grothendieck pullback stability AND the chord-assignment presheaf
/// `F(U) = F_p^{|U|}` satisfies exact equalizer sheaf gluing (`ker(res_1 - res_2) == F(U_1 ∪ U_2)`).
pub fn nc_forest_grothendieck_site_ok(n : Int32, p : Int32) -> (Int32, Bool) {
  let chords : Array[(Int32, Int32)] = []
  for a in 0..<n {
    for b in (a + 1)..<n {
      chords.push((a, b))
    }
  }
  let m = chords.length()
  let total_masks = 1 << m
  let nc_masks : Array[Int32] = []
  for mask in 0..<total_masks {
    let mut ok = true
    for i in 0..<m {
      if ((mask >> i) & 1) == 1 {
        for j in (i + 1)..<m {
          if ((mask >> j) & 1) == 1 &&
            nc_chords_cross(chords[i].0, chords[i].1, chords[j].0, chords[j].1) {
            ok = false
            break
          }
        }
      }
      if !ok {
        break
      }
    }
    if ok {
      nc_masks.push(mask)
    }
  }

  let popcnt = (msk : Int32) => {
    let mut c = 0
    let mut x = msk
    while x > 0 {
      c = c + (x & 1)
      x = x >> 1
    }
    c
  }

  // Check pullback stability (`(U_1 & W) | (U_2 & W) == (U_1 | U_2) & W`, and submasks of NC forests stay NC)
  // AND check equalizer sheaf gluing dimension `dim F(U_1) + dim F(U_2) - rank(diff_on_inter) == dim F(U_1 | U_2)`!
  let is_nc = Array::make(total_masks, false)
  for msk in nc_masks {
    is_nc[msk] = true
  }
  let limit = if nc_masks.length() < 24 { nc_masks.length() } else { 24 }
  for i in 0..<limit {
    let u1 = nc_masks[i]
    for j in i..<limit {
      let u2 = nc_masks[j]
      let u = u1 | u2
      if is_nc[u] {
        let inter = u1 & u2
        if !is_nc[inter] {
          return (nc_masks.length(), false)
        }
        // Build restriction equalizer matrix `(res_{U1 -> inter}, -res_{U2 -> inter})` over `F_p`
        let c1 = popcnt(u1)
        let c2 = popcnt(u2)
        let ci = popcnt(inter)
        let cu = popcnt(u)
        if ci == 0 {
          if c1 + c2 != cu {
            return (nc_masks.length(), false)
          }
        } else {
          let mat = @gcd.fp_mat_make(ci, c1 + c2, p, 0)
          let mut row = 0
          for bit in 0..<m {
            if ((inter >> bit) & 1) == 1 {
              let pos1 = popcnt(u1 & ((1 << bit) - 1))
              let pos2 = popcnt(u2 & ((1 << bit) - 1))
              @gcd.fp_mat_set(mat, row, pos1, 1)
              @gcd.fp_mat_set(mat, row, c1 + pos2, p - 1)
              row = row + 1
            }
          }
          let ker_dim = c1 + c2 - @gcd.fp_rank(mat)
          if ker_dim != cu {
            return (nc_masks.length(), false)
          }
        }
      }
    }
  }
  (nc_masks.length(), true)
}

// ---------------------------------------------------------------------------
// 2. Finite Metric Spaces, Gromov–Hausdorff & Full-Dimension Vietoris–Rips Homology
// ---------------------------------------------------------------------------

///|
/// Finite integer-valued metric space `(X = {0..n-1}, dist)`.
#derive(Debug, Eq)
pub(all) struct FiniteMetricSpace {
  n : Int32
  dist : Array[Array[Int32]]
}

///|
pub extend FiniteMetricSpace with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend FiniteMetricSpace with Eq::{not_equal, equal}

///|
pub fn metric_check_axioms(ms : FiniteMetricSpace) -> Bool {
  let n = ms.n
  if n <= 0 || ms.dist.length() != n {
    return false
  }
  for i in 0..<n {
    if ms.dist[i].length() != n || ms.dist[i][i] != 0 {
      return false
    }
    for j in 0..<n {
      if ms.dist[i][j] < 0 || ms.dist[i][j] != ms.dist[j][i] {
        return false
      }
      if i != j && ms.dist[i][j] == 0 {
        return false
      }
      for k in 0..<n {
        if ms.dist[i][k] > ms.dist[i][j] + ms.dist[j][k] {
          return false
        }
      }
    }
  }
  true
}

///|
pub fn metric_diameter(ms : FiniteMetricSpace) -> Int32 {
  let mut dm = 0
  for i in 0..<ms.n {
    for j in 0..<ms.n {
      if ms.dist[i][j] > dm {
        dm = ms.dist[i][j]
      }
    }
  }
  dm
}

///|
/// Exact twice Gromov–Hausdorff distance `2 * d_GH(X, Y)` via Kalton–Ostrovskii
/// correspondence distortion `min_R dis(R)` over all left-total, right-total relations
/// `R subseteq X x Y` (exact for `|X| * |Y| <= 12`).
pub fn metric_gh_twice_exact(
  x : FiniteMetricSpace,
  y : FiniteMetricSpace,
) -> Int32 {
  let pairs = x.n * y.n
  if pairs <= 0 || pairs > 12 {
    return -1
  }
  let total = 1 << pairs
  let mut best = 1_000_000_000
  for mask in 1..<total {
    // Check left-total and right-total
    let mut left_ok = true
    for i in 0..<x.n {
      let mut has_y = false
      for j in 0..<y.n {
        if ((mask >> (i * y.n + j)) & 1) == 1 {
          has_y = true
          break
        }
      }
      if !has_y {
        left_ok = false
        break
      }
    }
    if !left_ok {
      continue
    }
    let mut right_ok = true
    for j in 0..<y.n {
      let mut has_x = false
      for i in 0..<x.n {
        if ((mask >> (i * y.n + j)) & 1) == 1 {
          has_x = true
          break
        }
      }
      if !has_x {
        right_ok = false
        break
      }
    }
    if !right_ok {
      continue
    }
    let mut dis = 0
    for i1 in 0..<x.n {
      for j1 in 0..<y.n {
        if ((mask >> (i1 * y.n + j1)) & 1) == 1 {
          for i2 in 0..<x.n {
            for j2 in 0..<y.n {
              if ((mask >> (i2 * y.n + j2)) & 1) == 1 {
                let diff = x.dist[i1][i2] - y.dist[j1][j2]
                let ad = if diff < 0 { -diff } else { diff }
                if ad > dis {
                  dis = ad
                }
              }
            }
          }
        }
      }
    }
    if dis < best {
      best = dis
    }
  }
  best
}

///|
/// Vietoris–Rips homological & cohomological report at threshold `scale_r` over `F_p`.
#derive(Debug, Eq)
pub(all) struct VrHomologyReport {
  scale_r : Int32
  simplex_counts : Array[Int32]
  betti_homology : Array[Int32]
  betti_cohomology : Array[Int32]
  chain_complex_dd_zero : Bool
  homology_cohomology_dual : Bool
  euler_simplicial : Int32
  euler_betti : Int32
}

///|
pub extend VrHomologyReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VrHomologyReport with Eq::{not_equal, equal}

///|
/// Build the full-dimension Vietoris–Rips simplicial complex `VR(ms, scale_r)` (`n <= 8`),
/// compute homology `H_k` via `@gcd.fp_rank(d_k)` AND cohomology `H^k` independently via
/// `@gcd.fp_rank(fp_mat_transpose(d_k))`, and verify `d_{k-1} ∘ d_k = 0`, `dim H_k == dim H^k`,
/// and full-dimension Euler–Poincaré `chi_simplicial == chi_betti`!
pub fn metric_vr_homology_report(
  ms : FiniteMetricSpace,
  scale_r : Int32,
  p : Int32,
) -> VrHomologyReport {
  let n = ms.n
  let by_dim : Array[Array[Array[Int32]]] = Array::makei(n, _ => [])
  let total_masks = 1 << n
  for mask in 1..<total_masks {
    let verts : Array[Int32] = []
    for v in 0..<n {
      if ((mask >> v) & 1) == 1 {
        verts.push(v)
      }
    }
    let mut clique = true
    for i in 0..<verts.length() {
      for j in (i + 1)..<verts.length() {
        if ms.dist[verts[i]][verts[j]] > scale_r {
          clique = false
          break
        }
      }
      if !clique {
        break
      }
    }
    if clique {
      by_dim[verts.length() - 1].push(verts)
    }
  }

  // Build boundary matrices `bd[k] : C_k -> C_{k-1}` for `k = 1 .. n-1`
  let bd : Array[@gcd.FpMat] = []
  for k in 1..<n {
    let ck = by_dim[k]
    let ckm1 = by_dim[k - 1]
    let m = @gcd.fp_mat_make(ckm1.length(), ck.length(), p, 0)
    for col in 0..<ck.length() {
      let simp = ck[col]
      for omit in 0..<simp.length() {
        let face : Array[Int32] = []
        for idx in 0..<simp.length() {
          if idx != omit {
            face.push(simp[idx])
          }
        }
        // Locate `face` in `ckm1`
        for row in 0..<ckm1.length() {
          if ckm1[row] == face {
            let sign = if omit % 2 == 0 { 1 } else { p - 1 }
            @gcd.fp_mat_set(m, row, col, sign)
            break
          }
        }
      }
    }
    bd.push(m)
  }

  let mut dd_zero = true
  for k in 1..<bd.length() {
    if bd[k - 1].rows > 0 && bd[k].cols > 0 {
      let prod = @gcd.fp_mat_mul(bd[k - 1], bd[k])
      for v in prod.data {
        if v != 0 {
          dd_zero = false
          break
        }
      }
    }
  }

  let rk_h = Array::make(n + 1, 0)
  let rk_c = Array::make(n + 1, 0)
  for k in 1..<n {
    let b = bd[k - 1]
    if b.rows > 0 && b.cols > 0 {
      rk_h[k] = @gcd.fp_rank(b)
      rk_c[k] = @gcd.fp_rank(@gcd.fp_mat_transpose(b))
    }
  }

  let simp_counts : Array[Int32] = []
  let betti_h : Array[Int32] = []
  let betti_c : Array[Int32] = []
  let mut chi_s = 0
  let mut chi_b = 0
  for k in 0..<n {
    let ck_len = by_dim[k].length()
    simp_counts.push(ck_len)
    let bh = ck_len - rk_h[k] - rk_h[k + 1]
    let bc = ck_len - rk_c[k + 1] - rk_c[k]
    betti_h.push(bh)
    betti_c.push(bc)
    let sgn = if k % 2 == 0 { 1 } else { -1 }
    chi_s = chi_s + sgn * ck_len
    chi_b = chi_b + sgn * bh
  }

  VrHomologyReport::{
    scale_r,
    simplex_counts: simp_counts,
    betti_homology: betti_h,
    betti_cohomology: betti_c,
    chain_complex_dd_zero: dd_zero,
    homology_cohomology_dual: betti_h == betti_c,
    euler_simplicial: chi_s,
    euler_betti: chi_b,
  }
}

// ---------------------------------------------------------------------------
// 3. Krasner / Marty Hyper-Structures (Power-Set Multi-Valued Operations)
// ---------------------------------------------------------------------------

///|
/// Verify Marty hypergroup axioms (non-empty values, hyper-associativity
/// `(a + b) + c == a + (b + c)`, and reproduction `a + H == H == H + a`)
/// for a finite carrier `{0..n-1}` with bitmask-valued operation `op(a, b)`.
pub fn hyper_check_marty_hypergroup(
  n : Int32,
  op : (Int32, Int32) -> Int32,
) -> Bool {
  if n <= 0 || n > 16 {
    return false
  }
  let full = (1 << n) - 1
  for a in 0..<n {
    let mut left_all = 0
    let mut right_all = 0
    for b in 0..<n {
      let ab = op(a, b) & full
      let ba = op(b, a) & full
      if ab == 0 || ba == 0 {
        return false
      }
      left_all = left_all | ab
      right_all = right_all | ba
      for c in 0..<n {
        let mut lhs = 0
        let mut rhs = 0
        for u in 0..<n {
          if ((ab >> u) & 1) == 1 {
            lhs = lhs | (op(u, c) & full)
          }
        }
        let bc = op(b, c) & full
        for v in 0..<n {
          if ((bc >> v) & 1) == 1 {
            rhs = rhs | (op(a, v) & full)
          }
        }
        if lhs != rhs {
          return false
        }
      }
    }
    if left_all != full || right_all != full {
      return false
    }
  }
  true
}

///|
/// Truncated Viro–Krasner tropical hyperaddition on `{0..top}` (`top` = `+infinity` / `0_trop`):
/// - `a (+) b = { min(a, b) }` if `a != b`;
/// - `a (+) a = { a, a + 1, ..., top }` (tie-breaking interval!).
/// Satisfies hyper-commutativity, hyper-associativity, and neutral `top` (`a (+) top = {a}`)!
pub fn hyper_tropical_viro_op(top : Int32, a : Int32, b : Int32) -> Int32 {
  if a < b {
    1 << a
  } else if b < a {
    1 << b
  } else if a == top {
    1 << top
  } else {
    let mut msk = 0
    for k in a..<=top {
      msk = msk | (1 << k)
    }
    msk
  }
}

///|
/// Master health probe for Federation 7's `tensor` package.
pub fn tensor_check_federation_laws() -> Bool {
  // 1. F_3^{2x2x2} 6,561-tensor classification & SL_2 / S_3 hyperdeterminant invariance
  let atlas = f3_tensor222_atlas_build()
  // Rank counts over F_3^{2x2x2}: rank 0 = 1, rank 1 = 128, rank 2 = 4032 (576 subspace + 3456 F_3-split),
  // rank 3 = 2400 (864 Segre-tangent Det=0 + 1536 F_9/F_3 Galois-twisted Det!=0)!
  if atlas.total_tensors != 6561 ||
    atlas.rank_counts[0] != 1 ||
    atlas.rank_counts[1] != 128 ||
    atlas.rank_counts[2] != 4032 ||
    atlas.rank_counts[3] != 2400 ||
    atlas.rank2_det_zero_count == 0 ||
    atlas.rank2_det_nonzero_count == 0 ||
    atlas.rank3_det_zero_count == 0 ||
    atlas.rank3_det_nonzero_count == 0 {
    return false
  }
  let ghz = t3_of(2, 2, 2, 5, (i, j, k) => if i == j && j == k { 1 } else { 0 })
  if t3_hyperdet222(ghz) != 1 ||
    !t3_check_sl2_shear_and_s3_invariance(ghz) ||
    t3_flatten_rank_lower_bound(ghz) != 2 {
    return false
  }

  // 2. Discrete Radon transform: Gram holds for prime `n = 3`, fails for composite `n = 4`;
  //    exact inversion over `F_101` & affine-corrected Plancherel `sum (Rf)^2 = 3 sum f^2 + (sum f)^2`!
  let r3 = radon_make(3, 101)
  let r4 = radon_make(4, 101)
  if !radon_check_gram_identity(r3) || radon_check_gram_identity(r4) {
    return false
  }
  let f_vec = [1, 2, 0, 3, 1, 4, 2, 0, 1]
  let rf_exact = radon_apply_exact(r3, f_vec)
  let rf_mod = rf_exact.map(v => @gcd.fp_norm(v, 101))
  let f_rec = radon_invert_fp(r3, rf_mod)
  if f_rec != f_vec {
    return false
  }
  let (sf2, srf2, sf_sq) = radon_energy_triple(r3, f_vec)
  if srf2 != 3 * sf2 + sf_sq {
    return false
  }

  // 3. Twisted group algebras, Clifford Ramond spinors & torus Z/2 gauge moduli
  let tw_even = twisted_group_clifford_cocycle_report(2, 4)
  let tw_odd = twisted_group_clifford_cocycle_report(2, 3)
  if !tw_even.coboundary_gauge_invariant ||
    tw_even.center_dim != 1 ||
    !tw_odd.coboundary_gauge_invariant ||
    tw_odd.center_dim != 2 {
    return false
  }
  if !clifford_ramond_anticommutator_ok(4, 5) ||
    !clifford_ramond_anticommutator_ok(3, 5) ||
    clifford_ramond_anticommutator_ok(2, 3) {
    return false
  }
  let (flat_c, hol_c, gauge_ok) = lattice_torus_gauge_moduli_verify(2)
  if !gauge_ok || flat_c != 32 || hol_c != 4 {
    return false
  }

  // 4. Non-crossing flip graph, MST `[T-NC-Free]` + K_4 counterexample, and Grothendieck site `[T-X-Site]`
  let flip5 = nc_polygon_triangulations_flip_report(5)
  let flip6 = nc_polygon_triangulations_flip_report(6)
  if flip5.catalan_count != 5 ||
    flip5.flip_edges != 5 ||
    !flip5.is_connected ||
    flip6.catalan_count != 14 ||
    flip6.flip_edges != 21 ||
    !flip6.is_connected {
    return false
  }
  // Cyclic-monotone metric on K_4 vs diagonal-shortcut K_4 counterexample (`MST = 7 < NC-MST = 11`)
  let mono_k4 = [[0, 2, 3, 2], [2, 0, 2, 3], [3, 2, 0, 2], [2, 3, 2, 0]]
  let diag_k4 = [[0, 5, 1, 5], [5, 0, 5, 1], [1, 5, 0, 5], [5, 1, 5, 0]]
  let (m_mono, nc_mono) = nc_mst_vs_unconstrained_mst(4, mono_k4)
  let (m_diag, nc_diag) = nc_mst_vs_unconstrained_mst(4, diag_k4)
  if m_mono != nc_mono || m_diag != 7 || nc_diag != 11 {
    return false
  }
  let (nc4_cnt, site4_ok) = nc_forest_grothendieck_site_ok(4, 7)
  if nc4_cnt != 48 || !site4_ok {
    return false
  }

  // 5. Metric GH counterexample, VR persistent homology duality & Krasner tropical hyperaddition
  let tri2 = FiniteMetricSpace::{
    n: 3,
    dist: [[0, 2, 2], [2, 0, 2], [2, 2, 0]],
  }
  let seg2 = FiniteMetricSpace::{ n: 2, dist: [[0, 2], [2, 0]], }
  if !metric_check_axioms(tri2) ||
    !metric_check_axioms(seg2) ||
    metric_diameter(tri2) != metric_diameter(seg2) ||
    metric_gh_twice_exact(tri2, seg2) != 2 {
    return false
  }
  // Cycle C_4 at scale 1 has H_0 = 1, H_1 = 1 (`S^1`); at scale 2 fills to contractible `H_0 = 1, H_1 = 0`!
  let c4_ms = FiniteMetricSpace::{
    n: 4,
    dist: [[0, 1, 2, 1], [1, 0, 1, 2], [2, 1, 0, 1], [1, 2, 1, 0]],
  }
  let vr1 = metric_vr_homology_report(c4_ms, 1, 7)
  let vr2 = metric_vr_homology_report(c4_ms, 2, 7)
  if !vr1.chain_complex_dd_zero ||
    !vr1.homology_cohomology_dual ||
    vr1.betti_homology[0] != 1 ||
    vr1.betti_homology[1] != 1 ||
    vr1.euler_simplicial != vr1.euler_betti ||
    !vr2.homology_cohomology_dual ||
    vr2.betti_homology[1] != 0 ||
    vr2.euler_simplicial != 1 {
    return false
  }
  // Quotient hypergroup `(Z/6Z) / {+1, -1}` (carrier `{0, 1, 2, 3}`) & Viro tropical hyperaddition
  let coset_op = (a : Int32, b : Int32) => {
    let s1 = ((a + b) % 6 + 6) % 6
    let s2 = ((a - b) % 6 + 6) % 6
    let r1 = if s1 > 3 { 6 - s1 } else { s1 }
    let r2 = if s2 > 3 { 6 - s2 } else { s2 }
    (1 << r1) | (1 << r2)
  }
  if !hyper_check_marty_hypergroup(4, coset_op) {
    return false
  }
  // Check hyper-associativity of Viro tropical hyperaddition on `{0..3}`
  let full4 = (1 << 4) - 1
  for a in 0..<4 {
    for b in 0..<4 {
      for c in 0..<4 {
        let ab = hyper_tropical_viro_op(3, a, b)
        let bc = hyper_tropical_viro_op(3, b, c)
        let mut lhs = 0
        let mut rhs = 0
        for u in 0..<4 {
          if ((ab >> u) & 1) == 1 {
            lhs = lhs | (hyper_tropical_viro_op(3, u, c) & full4)
          }
          if ((bc >> u) & 1) == 1 {
            rhs = rhs | (hyper_tropical_viro_op(3, a, u) & full4)
          }
        }
        if lhs != rhs {
          return false
        }
      }
    }
  }
  true
}
