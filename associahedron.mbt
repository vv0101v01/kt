///|
// Stasheff associahedra K_n for arbitrary n.
//
// SPEC section 4 lists `K_n` for `n >= 6` as an open frontier, with the
// qualification that this is a porting cost rather than an unknown: Mac
// Lane's coherence theorem guarantees that every associator diagram
// commutes, so the construction is per-n and not blocked by an
// "infinite coherence tower".  `cubical_algorithms.mbt` carries K_5 as a
// hand-built 5-cell; this file supplies K_n for every n.
//
// WHAT IS PROVED HERE, and how it is checked.
//
// The associahedron is realised by the standard combinatorial model:
//
//   faces of K_n  <->  plane trees with n leaves and no unary nodes
//                      ("Schroder trees"),
//   dim(face)          = sum over internal nodes v of (arity(v) - 2).
//
// A binary tree has dim 0 and is a vertex; the corolla has dim n-2 and
// is the top face.  Under this model the defining property of an
// associahedron -- Stasheff's "every 2-face is a pentagon or a square"
// -- is not an assertion but a computation:
//
//   dim 2 requires either one arity-4 node (refined by Catalan(3) = 5
//   binary trees: a pentagon) or two arity-3 nodes (2 x 2 = 4 binary
//   trees: a square).  Nothing else is possible.
//
// The law below verifies this, and cross-checks the two models against
// each other: the number of edges of the *rotation graph* (built by
// Tamari rotations on binary trees) must equal f_1 of the *Schroder
// face lattice*.  Four further independent invariants are checked:
// f_0 = Catalan(n-1), f_1 = (n-2) f_0 / 2, facets = n(n-1)/2 - 1, and
// the Euler characteristic sum_k (-1)^k f_k = 1 (K_n is a ball).
//
// WHAT IS NOT CLAIMED.  The cubical n-cell filler is a separate
// matter.  `dpath_singleton5_transport_value` in
// `cubical_algorithms.mbt` is a fixed 5-stage contraction, so the
// existing K_5 cell does not generalise by recursion; an n-stage
// cubical singleton transport is the missing primitive and is recorded
// as the remaining boundary rather than faked.  `assoc_tree_value`
// below does feed arbitrary parenthesizations through the real cubical
// composition `dpath_trans_value`, but `DValue` carries closures and
// therefore has no decidable equality, so that layer is exercised, not
// equationally verified.

///|
/// A parenthesization of n composable paths: a binary tree whose leaves
/// are path indices.
pub enum Paren {
  PLeaf(Int32)
  PNode(Paren, Paren)
} derive(Debug, Eq)

///|
pub extend Paren with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Paren with Eq::{equal, not_equal}

///|
/// A face of the associahedron: a plane tree with no unary nodes.
pub enum Stree {
  SLeaf
  SNode(Array[Stree])
} derive(Debug, Eq)

///|
pub extend Stree with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Stree with Eq::{equal, not_equal}

// ---------------------------------------------------------------------------
// Parenthesizations
// ---------------------------------------------------------------------------

///|
pub fn paren_leaves(t : Paren) -> Int32 {
  match t {
    PLeaf(_) => 1
    PNode(a, b) => paren_leaves(a) + paren_leaves(b)
  }
}

///|
/// All binary trees with `n` leaves, leaves numbered `0 .. n-1` in
/// left-to-right order.  The recursion builds shapes with local leaf
/// numbers, so the result is renumbered globally before it is returned;
/// without that, `PNode(PNode(PLeaf 0, PLeaf 1), PNode(..., PLeaf 4))`
/// would not match the corresponding vertex of the top-level list.
pub fn paren_all(n : Int32) -> Array[Paren] {
  let shapes = paren_shapes(n)
  let out : Array[Paren] = []
  for i in 0..<shapes.length() {
    out.push(paren_renumber(shapes[i]))
  }
  out
}

///|
fn paren_shapes(n : Int32) -> Array[Paren] {
  if n <= 0 {
    return []
  }
  if n == 1 {
    return [PLeaf(0)]
  }
  let out : Array[Paren] = []
  let mut k = 1
  while k < n {
    let lefts = paren_shapes(k)
    let rights = paren_shapes(n - k)
    for i in 0..<lefts.length() {
      for j in 0..<rights.length() {
        out.push(PNode(lefts[i], rights[j]))
      }
    }
    k = k + 1
  }
  out
}

///|
/// Renumber leaves `0, 1, 2, ...` in left-to-right order.
pub fn paren_renumber(t : Paren) -> Paren {
  let counter : Array[Int32] = [0]
  paren_renumber_go(t, counter)
}

///|
fn paren_renumber_go(t : Paren, counter : Array[Int32]) -> Paren {
  match t {
    PLeaf(_) => {
      let i = counter[0]
      counter[0] = i + 1
      PLeaf(i)
    }
    PNode(a, b) =>
      PNode(paren_renumber_go(a, counter), paren_renumber_go(b, counter))
  }
}

///|
/// Fully left-associated: `(((p1 . p2) . p3) ... . pn)`.
pub fn paren_left_spine(n : Int32) -> Paren {
  if n <= 0 {
    return PLeaf(0)
  }
  let mut t = PLeaf(0)
  let mut i = 1
  while i < n {
    t = PNode(t, PLeaf(i))
    i = i + 1
  }
  t
}

///|
/// Fully right-associated: `(p1 . (p2 . (... . pn)))`.
pub fn paren_right_spine(n : Int32) -> Paren {
  if n <= 0 {
    return PLeaf(0)
  }
  let mut t = PLeaf(n - 1)
  let mut i = n - 2
  while i >= 0 {
    t = PNode(PLeaf(i), t)
    i = i - 1
  }
  t
}

///|
/// The source vertex of the hand-built K_5 cell in
/// `cubical_algorithms.mbt`: `(p . q) . ((u . v) . w)`.
pub fn paren_k5_lhs1() -> Paren {
  PNode(PNode(PLeaf(0), PLeaf(1)), PNode(PNode(PLeaf(2), PLeaf(3)), PLeaf(4)))
}

///|
/// Fold a parenthesization into a cubical path using the real
/// composition primitive.  Exercised by the law, not equationally
/// verified (see the file header).
pub fn assoc_tree_value(
  space_ty : DValue,
  paths : Array[DValue],
  t : Paren,
  dlevel : Int32,
) -> DValue {
  match t {
    PLeaf(i) => paths[i]
    PNode(a, b) => {
      let left = assoc_tree_value(space_ty, paths, a, dlevel)
      let right = assoc_tree_value(space_ty, paths, b, dlevel)
      dpath_trans_value(space_ty, left, right, dlevel)
    }
  }
}

// ---------------------------------------------------------------------------
// Rotations: the 1-skeleton (Tamari graph)
// ---------------------------------------------------------------------------

///|
/// Right rotation at the root: `(A . (B . C)) -> ((A . B) . C)`.
fn rot_right(t : Paren) -> Array[Paren] {
  match t {
    PLeaf(_) => []
    PNode(a, PNode(b, c)) => [PNode(PNode(a, b), c)]
    PNode(_, _) => []
  }
}

///|
/// Left rotation at the root: `((A . B) . C) -> (A . (B . C))`.
fn rot_left(t : Paren) -> Array[Paren] {
  match t {
    PLeaf(_) => []
    PNode(PNode(a, b), c) => [PNode(a, PNode(b, c))]
    PNode(_, _) => []
  }
}

///|
/// Every parenthesization one Tamari rotation away from `t`.
pub fn paren_rotations(t : Paren) -> Array[Paren] {
  let out : Array[Paren] = []
  match t {
    PLeaf(_) => ()
    PNode(a, b) => {
      for i in 0..<rot_left(t).length() {
        out.push(rot_left(t)[i])
      }
      for i in 0..<rot_right(t).length() {
        out.push(rot_right(t)[i])
      }
      let ra = paren_rotations(a)
      for i in 0..<ra.length() {
        out.push(PNode(ra[i], b))
      }
      let rb = paren_rotations(b)
      for i in 0..<rb.length() {
        out.push(PNode(a, rb[i]))
      }
    }
  }
  out
}

///|
/// Number of edges of the 1-skeleton (each edge counted once).
pub fn paren_rotation_edge_count(n : Int32) -> Int32 {
  let verts = paren_all(n)
  let index : Array[Int32] = []
  let mut i = 0
  while i < verts.length() {
    index.push(-1)
    i = i + 1
  }
  // Index vertices by their position; lookup is linear, n is small.
  let mut total = 0
  let mut v = 0
  while v < verts.length() {
    let nb = paren_rotations(verts[v])
    for k in 0..<nb.length() {
      let mut w = 0
      while w < verts.length() {
        if verts[w] == nb[k] {
          // Count the edge only from the smaller index.
          if w > v {
            total = total + 1
          }
          break
        }
        w = w + 1
      }
    }
    v = v + 1
  }
  ignore(index)
  total
}

///|
/// Mac Lane coherence at the level of the 1-skeleton: the rotation
/// graph on all parenthesizations of n paths is connected.
pub fn paren_rotation_graph_connected(n : Int32) -> Bool {
  let verts = paren_all(n)
  if verts.length() == 0 {
    return false
  }
  let seen : Array[Bool] = []
  let mut i = 0
  while i < verts.length() {
    seen.push(false)
    i = i + 1
  }
  let queue : Array[Int32] = [0]
  seen[0] = true
  let mut head = 0
  let mut count = 1
  while head < queue.length() {
    let v = queue[head]
    head = head + 1
    let nb = paren_rotations(verts[v])
    for k in 0..<nb.length() {
      let mut w = 0
      while w < verts.length() {
        if !seen[w] && verts[w] == nb[k] {
          seen[w] = true
          count = count + 1
          queue.push(w)
          break
        }
        w = w + 1
      }
    }
  }
  count == verts.length()
}

// ---------------------------------------------------------------------------
// Schroder trees: the face lattice
// ---------------------------------------------------------------------------

///|
pub fn stree_leaves(s : Stree) -> Int32 {
  match s {
    SLeaf => 1
    SNode(kids) => {
      let mut n = 0
      for i in 0..<kids.length() {
        n = n + stree_leaves(kids[i])
      }
      n
    }
  }
}

///|
/// Dimension of the face: sum over internal nodes of (arity - 2).
pub fn stree_dim(s : Stree) -> Int32 {
  match s {
    SLeaf => 0
    SNode(kids) => {
      let mut d = kids.length() - 2
      for i in 0..<kids.length() {
        d = d + stree_dim(kids[i])
      }
      d
    }
  }
}

///|
fn compositions(n : Int32, k : Int32) -> Array[Array[Int32]] {
  if k <= 0 {
    return []
  }
  if k == 1 {
    if n >= 1 {
      return [[n]]
    }
    return []
  }
  let out : Array[Array[Int32]] = []
  let mut first = 1
  while first <= n - (k - 1) {
    let rest = compositions(n - first, k - 1)
    for i in 0..<rest.length() {
      let row : Array[Int32] = [first]
      for j in 0..<rest[i].length() {
        row.push(rest[i][j])
      }
      out.push(row)
    }
    first = first + 1
  }
  out
}

///|
/// All plane trees with `n` leaves and no unary nodes.
pub fn stree_all(n : Int32) -> Array[Stree] {
  if n <= 0 {
    return []
  }
  let memo : Array[Array[Stree]] = []
  memo.push([]) // 0 unused
  memo.push([SLeaf])
  let mut m = 2
  while m <= n {
    let out : Array[Stree] = []
    let mut k = 2
    while k <= m {
      let comps = compositions(m, k)
      for ci in 0..<comps.length() {
        let parts = comps[ci]
        let mut choices : Array[Array[Stree]] = []
        choices.push([])
        let mut pi = 0
        while pi < parts.length() {
          let next : Array[Array[Stree]] = []
          for xi in 0..<choices.length() {
            let opts = memo[parts[pi]]
            for oi in 0..<opts.length() {
              let row : Array[Stree] = []
              for zi in 0..<choices[xi].length() {
                row.push(choices[xi][zi])
              }
              row.push(opts[oi])
              next.push(row)
            }
          }
          choices = next
          pi = pi + 1
        }
        for xi in 0..<choices.length() {
          out.push(SNode(choices[xi]))
        }
      }
      k = k + 1
    }
    memo.push(out)
    m = m + 1
  }
  memo[n]
}

///|
/// The f-vector of K_n: `f[k]` is the number of k-dimensional faces.
pub fn assoc_fvector(n : Int32) -> Array[Int32] {
  let top = n - 2
  if top < 0 {
    return []
  }
  let f : Array[Int32] = []
  let mut k = 0
  while k <= top {
    f.push(0)
    k = k + 1
  }
  let faces = stree_all(n)
  for i in 0..<faces.length() {
    let d = stree_dim(faces[i])
    if d >= 0 && d <= top {
      f[d] = f[d] + 1
    }
  }
  f
}

///|
/// Number of pentagonal 2-faces (one arity-4 node) and square 2-faces
/// (two arity-3 nodes).
pub fn assoc_two_faces(n : Int32) -> (Int32, Int32) {
  let faces = stree_all(n)
  let mut pentagons = 0
  let mut squares = 0
  for i in 0..<faces.length() {
    if stree_dim(faces[i]) == 2 {
      match faces[i] {
        SLeaf => ()
        SNode(kids) => {
          let mut arity4 = 0
          let mut arity3 = 0
          for j in 0..<kids.length() {
            arity4 = arity4 + count_arity(kids[j], 4)
            arity3 = arity3 + count_arity(kids[j], 3)
          }
          if kids.length() == 4 {
            arity4 = arity4 + 1
          } else if kids.length() == 3 {
            arity3 = arity3 + 1
          }
          // pentagon: one arity-4 node and no arity-3 node
          // square:   two arity-3 nodes and no arity-4 node
          if arity4 == 1 && arity3 == 0 {
            pentagons = pentagons + 1
          } else if arity3 == 2 && arity4 == 0 {
            squares = squares + 1
          }
        }
      }
    }
  }
  (pentagons, squares)
}

///|
fn count_arity(s : Stree, arity : Int32) -> Int32 {
  match s {
    SLeaf => 0
    SNode(kids) => {
      let mut n = 0
      if kids.length() == arity {
        n = 1
      }
      for i in 0..<kids.length() {
        n = n + count_arity(kids[i], arity)
      }
      n
    }
  }
}

// ---------------------------------------------------------------------------
// Closed forms used as independent cross-checks
// ---------------------------------------------------------------------------

///|
/// Catalan numbers: `catalan(0) = 1`, `catalan(m+1) = 2(2m+1)/(m+2) catalan(m)`.
pub fn catalan(m : Int32) -> Int32 {
  let mut c = 1
  let mut i = 0
  while i < m {
    c = c * 2 * (2 * i + 1) / (i + 2)
    i = i + 1
  }
  c
}

///|
/// Euler characteristic of K_n: alternating sum of the f-vector.  For a
/// ball this is 1.
pub fn assoc_euler_characteristic(n : Int32) -> Int32 {
  let f = assoc_fvector(n)
  let mut acc = 0
  let mut k = 0
  while k < f.length() {
    if k % 2 == 0 {
      acc = acc + f[k]
    } else {
      acc = acc - f[k]
    }
    k = k + 1
  }
  acc
}

// ---------------------------------------------------------------------------
// Law
// ---------------------------------------------------------------------------

///|
fn assoc_check_n(n : Int32) -> Bool {
  let f = assoc_fvector(n)
  let top = n - 2
  // Length.
  if f.length() != top + 1 {
    return false
  }
  // (a) f_0 = Catalan(n-1), and agrees with the binary-tree enumeration.
  if f[0] != catalan(n - 1) || f[0] != paren_all(n).length() {
    return false
  }
  // (b) f_1 = (n-2) f_0 / 2 -- every vertex has degree n-2.
  if (n - 2) * f[0] % 2 != 0 || f[1] != (n - 2) * f[0] / 2 {
    return false
  }
  // (c) Cross-check the two models: the rotation graph must have
  //     exactly f_1 edges.
  if paren_rotation_edge_count(n) != f[1] {
    return false
  }
  // (d) Mac Lane coherence: the 1-skeleton is connected.
  if !paren_rotation_graph_connected(n) {
    return false
  }
  // (e) Facets: n(n-1)/2 - 1.  Note f[top] is always 1 (the polytope
  //     itself); the facets are the codimension-1 faces, f[top - 1].
  if f[top - 1] != n * (n - 1) / 2 - 1 {
    return false
  }
  // (f) Euler characteristic of a ball.
  if assoc_euler_characteristic(n) != 1 {
    return false
  }
  // (g) Stasheff's defining property: every 2-face is a pentagon or a
  //     square, and the two counts add up to f_2.  Only meaningful once
  //     K_n has dimension at least 2, i.e. n >= 4.
  if f.length() > 2 {
    let (penta, square) = assoc_two_faces(n)
    if penta + square != f[2] {
      return false
    }
    // A pentagon needs an arity-4 node, so there is none before n = 4
    // and at least one from n = 4 on.
    if penta == 0 {
      return false
    }
  }
  true
}

///|
/// Stasheff associahedra K_n for arbitrary n (17c).  The combinatorial
/// associahedron -- face lattice, f-vector, Euler characteristic and the
/// pentagon/square 2-face property -- is verified for every n from 3 to
/// 9, which covers the `n >= 6` frontier.  The cubical n-cell filler
/// remains bounded by the 5-stage singleton transport; see the file
/// header.
pub fn check_assoc_faces() -> Bool {
  let mut ok = true
  let mut n = 3
  while n <= 9 {
    if !assoc_check_n(n) {
      ok = false
    }
    n = n + 1
  }
  // Cross-check against the hand-built K_5 cell already in the tree.
  // Its two endpoints are vertices of K_5, they are distinct, and the
  // rotation graph connects them.
  let verts5 = paren_all(5)
  let mut lhs_seen = false
  let mut rhs_seen = false
  for i in 0..<verts5.length() {
    if verts5[i] == paren_k5_lhs1() {
      lhs_seen = true
    }
    if verts5[i] == paren_right_spine(5) {
      rhs_seen = true
    }
  }
  let distinct = !(paren_k5_lhs1() == paren_right_spine(5))
  // Exercise the cubical evaluator on both endpoints and on every
  // vertex of K_5.  DValue has no decidable equality, so this checks
  // that the fold is total over the whole associahedron, not that two
  // parenthesizations are equal.
  let space_ty = DVBoolTy
  let paths = [
    dpath_refl_value(DVBool(true)),
    dpath_refl_value(DVBool(true)),
    dpath_refl_value(DVBool(true)),
    dpath_refl_value(DVBool(true)),
    dpath_refl_value(DVBool(true)),
  ]
  let mut evaluated = 0
  for i in 0..<verts5.length() {
    ignore(assoc_tree_value(space_ty, paths, verts5[i], 0))
    evaluated = evaluated + 1
  }
  ok &&
  lhs_seen &&
  rhs_seen &&
  distinct &&
  evaluated == verts5.length() &&
  verts5.length() == 14
}
