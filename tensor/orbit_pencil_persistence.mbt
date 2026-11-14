///|
// Federation 7 (`discovery`) — Layer 2 Package `tensor`, iteration 3:
//
//   A. Mode-`k` products `g ._k T` and the full `GL_2^3` covariance of Cayley's
//      hyperdeterminant, `Det((g0, g1, g2) . T) = det(g0)^2 det(g1)^2 det(g2)^2 Det(T)`
//      (`[T-GL-Covariance]`), upgrading the shear-only `[P-Shear]` check.
//   B. Schläfli's slice-pencil construction: `Det(T)` is the discriminant of the binary
//      quadratic `det(x T_0 + y T_1)`. This is a second, structurally independent route to
//      the 12-term Cayley polynomial (`[T-Schlafli-Pencil]`).
//   C. The complete orbit classification of `F_3^{2x2x2}` under `GL_2(F_3)^3` and under
//      `GL_2(F_3)^3 ⋊ S_3`, computed by union-find and re-counted by Burnside's lemma
//      over conjugacy classes (`[T-F3-Orbits]`).
//   D. Vietoris–Rips persistent homology over `F_2`: one bit-packed matrix reduction with
//      Chen–Kerber clearing yields the whole barcode, i.e. the Betti numbers at every
//      scale at once (`[T-VR-Barcode]`).
//
// All field arithmetic and ranks still delegate to `@gcd`.

// ---------------------------------------------------------------------------
// A. Mode products and GL covariance
// ---------------------------------------------------------------------------

///|
/// Mode-`mode` product `g ._mode T`: contracts the columns of `g` with axis `mode` of `t`
/// (`mode in {0, 1, 2}`). Returns `None` when the shapes or the fields do not match.
pub fn t3_mode_product(t : Tensor3, mode : Int32, g : @gcd.FpMat) -> Tensor3? {
  let p = t.field
  let dims = [t.dim0, t.dim1, t.dim2]
  if mode < 0 || mode > 2 || g.p != p || g.cols != dims[mode] {
    return None
  }
  let out_dims = [t.dim0, t.dim1, t.dim2]
  out_dims[mode] = g.rows
  let out = t3_of(out_dims[0], out_dims[1], out_dims[2], p, (i, j, k) => {
    let mut acc = 0
    for a in 0..<dims[mode] {
      let (coef, entry) = match mode {
        0 => (@gcd.fp_mat_get(g, i, a), t3_get(t, a, j, k))
        1 => (@gcd.fp_mat_get(g, j, a), t3_get(t, i, a, k))
        _ => (@gcd.fp_mat_get(g, k, a), t3_get(t, i, j, a))
      }
      acc = @gcd.fp_add(acc, @gcd.fp_mul(coef, entry, p), p)
    }
    acc
  })
  Some(out)
}

///|
/// Simultaneous action `(g0, g1, g2) . T` of three matrices on the three axes.
pub fn t3_multilinear_transform(
  t : Tensor3,
  g0 : @gcd.FpMat,
  g1 : @gcd.FpMat,
  g2 : @gcd.FpMat,
) -> Tensor3? {
  match t3_mode_product(t, 0, g0) {
    None => None
    Some(a) =>
      match t3_mode_product(a, 1, g1) {
        None => None
        Some(b) => t3_mode_product(b, 2, g2)
      }
  }
}

///|
/// `[T-GL-Covariance]` for a `2x2x2` tensor and three `2x2` matrices (singular ones
/// included): `Det((g0, g1, g2) . T) == det(g0)^2 * det(g1)^2 * det(g2)^2 * Det(T)`.
pub fn t3_hyperdet_gl_covariance_ok(
  t : Tensor3,
  g0 : @gcd.FpMat,
  g1 : @gcd.FpMat,
  g2 : @gcd.FpMat,
) -> Bool {
  let p = t.field
  if t.dim0 != 2 || t.dim1 != 2 || t.dim2 != 2 {
    return false
  }
  if g0.rows != 2 || g1.rows != 2 || g2.rows != 2 {
    return false
  }
  match t3_multilinear_transform(t, g0, g1, g2) {
    None => false
    Some(moved) => {
      let sq = (x : Int32) => @gcd.fp_mul(x, x, p)
      let factor = @gcd.fp_mul(
        sq(@gcd.fp_det(g0)),
        @gcd.fp_mul(sq(@gcd.fp_det(g1)), sq(@gcd.fp_det(g2)), p),
        p,
      )
      t3_hyperdet222(moved) == @gcd.fp_mul(factor, t3_hyperdet222(t), p)
    }
  }
}

// ---------------------------------------------------------------------------
// B. Schläfli slice pencil
// ---------------------------------------------------------------------------

///|
/// Coefficients `(a, b, c)` of the binary quadratic `det(x T_0 + y T_1) = a x^2 + b xy + c y^2`
/// of the pencil spanned by the two slices of `t` along `axis`.
pub fn t3_slice_pencil_quadratic(
  t : Tensor3,
  axis : Int32,
) -> (Int32, Int32, Int32) {
  let p = t.field
  let e = (s : Int32, r : Int32, c : Int32) => {
    match axis {
      0 => t3_get(t, s, r, c)
      1 => t3_get(t, r, s, c)
      _ => t3_get(t, r, c, s)
    }
  }
  let mul = (x : Int32, y : Int32) => @gcd.fp_mul(x, y, p)
  let add = (x : Int32, y : Int32) => @gcd.fp_add(x, y, p)
  let sub = (x : Int32, y : Int32) => @gcd.fp_sub(x, y, p)
  let a = sub(mul(e(0, 0, 0), e(0, 1, 1)), mul(e(0, 0, 1), e(0, 1, 0)))
  let c = sub(mul(e(1, 0, 0), e(1, 1, 1)), mul(e(1, 0, 1), e(1, 1, 0)))
  let b = sub(
    add(mul(e(0, 0, 0), e(1, 1, 1)), mul(e(1, 0, 0), e(0, 1, 1))),
    add(mul(e(0, 0, 1), e(1, 1, 0)), mul(e(1, 0, 1), e(0, 1, 0))),
  )
  (a, b, c)
}

///|
/// `[T-Schlafli-Pencil]` Hyperdeterminant as the pencil discriminant `b^2 - 4ac`.
/// Returns `0` for shapes other than `2x2x2`, like `t3_hyperdet222`.
pub fn t3_hyperdet222_via_pencil(t : Tensor3, axis : Int32) -> Int32 {
  let p = t.field
  if p <= 1 || t.dim0 != 2 || t.dim1 != 2 || t.dim2 != 2 {
    return 0
  }
  let (a, b, c) = t3_slice_pencil_quadratic(t, axis)
  @gcd.fp_sub(@gcd.fp_mul(b, b, p), @gcd.fp_mul(4, @gcd.fp_mul(a, c, p), p), p)
}

// ---------------------------------------------------------------------------
// C. Orbits of F_3^{2x2x2} under GL_2(F_3)^3 and GL_2(F_3)^3 ⋊ S_3
// ---------------------------------------------------------------------------

///|
/// One orbit of `F_3^{2x2x2}`: its size, the smallest base-3 code it contains, and the two
/// invariants that are constant on it (tensor rank and Cayley hyperdeterminant).
#derive(Debug, Eq)
pub(all) struct F3OrbitClass {
  size : Int32
  representative_code : Int32
  rank : Int32
  hyperdet : Int32
}

///|
pub extend F3OrbitClass with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend F3OrbitClass with Eq::{not_equal, equal}

///|
/// Orbit classification report (`[T-F3-Orbits]`). `gl_orbits` / `gl_s3_orbits` are sorted
/// by representative code. `burnside_gl_orbit_count` is the independent Burnside count
/// `(1/|G|) sum_g |Fix(g)|` with `|G| = 48^3 = 110,592`.
#derive(Debug, Eq)
pub(all) struct F3OrbitReport {
  group_order : Int32
  gl_orbits : Array[F3OrbitClass]
  gl_s3_orbits : Array[F3OrbitClass]
  burnside_gl_orbit_count : Int32
  burnside_divides_exactly : Bool
  invariants_constant_on_orbits : Bool
  sizes_divide_group_order : Bool
  sizes_sum_to_total : Bool
}

///|
pub extend F3OrbitReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend F3OrbitReport with Eq::{not_equal, equal}

///|
/// Apply generator `gen` to base-3 code `code`. Generators `0..5` are, per axis, the upper
/// shear and the coordinate swap (together they generate `GL_2(F_3)` on that axis);
/// generators `6` and `7` transpose axes `(0 1)` and `(1 2)` (together they generate `S_3`).
fn f3_orbit_apply_generator(code : Int32, gen : Int32) -> Int32 {
  let d = Array::make(8, 0)
  let mut r = code
  for idx in 0..<8 {
    d[idx] = r % 3
    r = r / 3
  }
  let out = Array::make(8, 0)
  if gen < 6 {
    // Data index is `(i * 2 + j) * 2 + k`, so axis 0/1/2 owns bit 4/2/1.
    let bit = 4 >> (gen / 2)
    for idx in 0..<8 {
      out[idx] = if gen % 2 == 1 {
        d[idx ^ bit]
      } else if (idx & bit) == 0 {
        (d[idx] + d[idx ^ bit]) % 3
      } else {
        d[idx]
      }
    }
  } else {
    for idx in 0..<8 {
      let i = (idx >> 2) & 1
      let j = (idx >> 1) & 1
      let k = idx & 1
      let src = if gen == 6 { (j * 2 + i) * 2 + k } else { (i * 2 + k) * 2 + j }
      out[idx] = d[src]
    }
  }
  let mut res = 0
  for idx in 0..<8 {
    res = res * 3 + out[7 - idx]
  }
  res
}

///|
fn f3_orbit_find(parent : Array[Int32], x : Int32) -> Int32 {
  let mut root = x
  while parent[root] != root {
    root = parent[root]
  }
  let mut cur = x
  while parent[cur] != root {
    let next = parent[cur]
    parent[cur] = root
    cur = next
  }
  root
}

///|
/// Union-find orbit partition of the `6,561` codes under the first `num_gens` generators.
/// Returns the orbit list and whether rank and hyperdeterminant are constant on each orbit.
fn f3_orbit_partition(
  atlas : F3Tensor222Atlas,
  num_gens : Int32,
) -> (Array[F3OrbitClass], Bool) {
  let total = atlas.total_tensors
  let parent : Array[Int32] = Array::makei(total, i => i)
  for code in 0..<total {
    for gen in 0..<num_gens {
      let a = f3_orbit_find(parent, code)
      let b = f3_orbit_find(parent, f3_orbit_apply_generator(code, gen))
      if a != b {
        // The smaller code stays the root, so every root is its orbit's minimum.
        if a < b {
          parent[b] = a
        } else {
          parent[a] = b
        }
      }
    }
  }
  let sizes = Array::make(total, 0)
  let mut constant = true
  for code in 0..<total {
    let root = f3_orbit_find(parent, code)
    sizes[root] = sizes[root] + 1
    if atlas.ranks[code] != atlas.ranks[root] ||
      atlas.hyperdets[code] != atlas.hyperdets[root] {
      constant = false
    }
  }
  let classes : Array[F3OrbitClass] = []
  for code in 0..<total {
    if sizes[code] > 0 {
      classes.push(F3OrbitClass::{
        size: sizes[code],
        representative_code: code,
        rank: atlas.ranks[code],
        hyperdet: atlas.hyperdets[code],
      })
    }
  }
  (classes, constant)
}

///|
/// Burnside count of `GL_2(F_3)^3`-orbits on `F_3^8`. `|Fix(g0 ⊗ g1 ⊗ g2)| = 3^{8 - rank(g0 ⊗ g1 ⊗ g2 - I)}`
/// is a class function, and a conjugacy class of `GL_2(F_3)` is determined by
/// `(trace, det, is_scalar)`, so only `8^3 = 512` ranks are needed instead of `110,592`.
/// Returns `(sum_g |Fix(g)|, |G|)`.
fn f3_orbit_burnside_sum() -> (Int64, Int64) {
  let reps : Array[Array[Int32]] = []
  let keys : Array[Int32] = []
  let class_sizes : Array[Int64] = []
  let mut group_order = 0L
  for code in 0..<81 {
    let a = code % 3
    let b = code / 3 % 3
    let c = code / 9 % 3
    let d = code / 27
    let det = ((a * d - b * c) % 3 + 3) % 3
    if det != 0 {
      group_order = group_order + 1L
      let scalar = if b == 0 && c == 0 && a == d { 1 } else { 0 }
      let key = ((a + d) % 3 * 3 + det) * 2 + scalar
      let mut found = -1
      for i in 0..<keys.length() {
        if keys[i] == key {
          found = i
          break
        }
      }
      if found >= 0 {
        class_sizes[found] = class_sizes[found] + 1L
      } else {
        keys.push(key)
        reps.push([a, b, c, d])
        class_sizes.push(1L)
      }
    }
  }
  let mut fix_sum = 0L
  for x in 0..<reps.length() {
    for y in 0..<reps.length() {
      for z in 0..<reps.length() {
        let m = @gcd.fp_mat_make(8, 8, 3, 0)
        for row in 0..<8 {
          for col in 0..<8 {
            let v = reps[x][((row >> 2) & 1) * 2 + ((col >> 2) & 1)] *
              reps[y][((row >> 1) & 1) * 2 + ((col >> 1) & 1)] *
              reps[z][(row & 1) * 2 + (col & 1)]
            let diag = if row == col { 1 } else { 0 }
            @gcd.fp_mat_set(m, row, col, v - diag)
          }
        }
        let mut fixed = 1L
        for _ in 0..<(8 - @gcd.fp_rank(m)) {
          fixed = fixed * 3L
        }
        fix_sum = fix_sum +
          class_sizes[x] * class_sizes[y] * class_sizes[z] * fixed
      }
    }
  }
  (fix_sum, group_order * group_order * group_order)
}

///|
/// `[T-F3-Orbits]` Classify all `6,561` tensors of `F_3^{2x2x2}` into `GL_2(F_3)^3`-orbits
/// and into `GL_2(F_3)^3 ⋊ S_3`-orbits, reusing an already built `atlas`.
pub fn f3_tensor222_orbit_report(atlas : F3Tensor222Atlas) -> F3OrbitReport {
  let (gl, gl_const) = f3_orbit_partition(atlas, 6)
  let (gl_s3, s3_const) = f3_orbit_partition(atlas, 8)
  let (fix_sum, order) = f3_orbit_burnside_sum()
  let mut divides = true
  let mut size_sum = 0
  for o in gl {
    size_sum = size_sum + o.size
    if order % o.size.to_int64() != 0L {
      divides = false
    }
  }
  let mut s3_sum = 0
  for o in gl_s3 {
    s3_sum = s3_sum + o.size
    if order * 6L % o.size.to_int64() != 0L {
      divides = false
    }
  }
  F3OrbitReport::{
    group_order: order.to_int(),
    gl_orbits: gl,
    gl_s3_orbits: gl_s3,
    burnside_gl_orbit_count: (fix_sum / order).to_int(),
    burnside_divides_exactly: fix_sum % order == 0L,
    invariants_constant_on_orbits: gl_const && s3_const,
    sizes_divide_group_order: divides,
    sizes_sum_to_total: size_sum == atlas.total_tensors &&
    s3_sum == atlas.total_tensors,
  }
}

// ---------------------------------------------------------------------------
// D. Vietoris–Rips persistence barcode over F_2
// ---------------------------------------------------------------------------

///|
/// Persistence barcode of the Vietoris–Rips filtration of a finite metric space over `F_2`.
/// Each bar is `[dim, birth, death]` with `death == -1` for a class that never dies.
/// Only bars of dimension `< valid_below_dim` are reported, because a `k`-class needs the
/// `(k+1)`-simplices to be present before its death can be seen.
#derive(Debug, Eq)
pub(all) struct VrPersistenceReport {
  n_points : Int32
  max_simplex_dim : Int32
  valid_below_dim : Int32
  simplex_count : Int32
  bars : Array[Array[Int32]]
  zero_length_pairs : Int32
  cleared_columns : Int32
}

///|
pub extend VrPersistenceReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend VrPersistenceReport with Eq::{not_equal, equal}

///|
/// `[T-VR-Barcode]` Compute the full barcode with one reduction of the filtered boundary
/// matrix. Columns are bit-packed into `UInt64` words (64 row operations per XOR) and the
/// Chen–Kerber clearing rule skips every column whose simplex already killed a class.
///
/// `max_simplex_dim` caps the simplices that are built (`n <= 16`); pass `ms.n - 1` or
/// larger for the complete complex. Returns `None` when `ms.n` is outside `1..=16`.
pub fn metric_vr_persistence_barcode(
  ms : FiniteMetricSpace,
  max_simplex_dim : Int32,
) -> VrPersistenceReport? {
  let n = ms.n
  if n < 1 || n > 16 || max_simplex_dim < 0 {
    return None
  }
  let top_dim = if max_simplex_dim > n - 1 { n - 1 } else { max_simplex_dim }
  // Filtration order: by diameter, then dimension, then vertex mask. A face never has a
  // larger diameter or dimension than its coface, so faces always come first.
  let keys : Array[Int64] = []
  for mask in 1..<(1 << n) {
    let dim = mask.popcnt() - 1
    if dim <= top_dim {
      let mut diam = 0
      let mut rest_i = mask
      while rest_i != 0 {
        let i = rest_i.ctz()
        rest_i = rest_i & (rest_i - 1)
        let mut rest_j = rest_i
        while rest_j != 0 {
          let j = rest_j.ctz()
          rest_j = rest_j & (rest_j - 1)
          if ms.dist[i][j] > diam {
            diam = ms.dist[i][j]
          }
        }
      }
      keys.push(
        (diam.to_int64() << 20) | (dim.to_int64() << 16) | mask.to_int64(),
      )
    }
  }
  keys.sort()
  let total = keys.length()
  let masks : Array[Int32] = Array::makei(total, i => {
    (keys[i] & 0xFFFFL).to_int()
  })
  let dims : Array[Int32] = Array::makei(total, i => {
    ((keys[i] >> 16) & 0xFL).to_int()
  })
  let diams : Array[Int32] = Array::makei(total, i => (keys[i] >> 20).to_int())
  let pos_of_mask : Array[Int32] = Array::make(1 << n, -1)
  for i in 0..<total {
    pos_of_mask[masks[i]] = i
  }

  let words = (total + 63) / 64
  let cols : Array[Array[UInt64]] = Array::makei(total, _ => [])
  let lowest_one = (col : Array[UInt64]) => {
    let mut res = -1
    for w in 0..<col.length() {
      let idx = col.length() - 1 - w
      if col[idx] != 0UL {
        res = idx * 64 + 63 - col[idx].clz()
        break
      }
    }
    res
  }
  // `killer[i]` is the column whose reduced lowest one sits in row `i`.
  let killer : Array[Int32] = Array::make(total, -1)
  let creates : Array[Bool] = Array::make(total, true)
  let mut cleared = 0
  for step in 0..<top_dim {
    let d = top_dim - step
    for j in 0..<total {
      if dims[j] == d {
        if killer[j] >= 0 {
          // Clearing: simplex `j` is already a pivot row, so its column reduces to zero.
          cleared = cleared + 1
        } else {
          let col : Array[UInt64] = Array::make(words, 0UL)
          let mut rest = masks[j]
          while rest != 0 {
            let v = rest.ctz()
            rest = rest & (rest - 1)
            let face = pos_of_mask[masks[j] & (1 << v).lnot()]
            col[face / 64] = col[face / 64] ^ (1UL << (face % 64))
          }
          let mut low = lowest_one(col)
          while low >= 0 && killer[low] >= 0 {
            let other = cols[killer[low]]
            for w in 0..<=(low / 64) {
              col[w] = col[w] ^ other[w]
            }
            low = lowest_one(col)
          }
          if low >= 0 {
            killer[low] = j
            creates[j] = false
            cols[j] = col
          }
        }
      }
    }
  }

  let valid_below = if top_dim == n - 1 { n } else { top_dim }
  let bar_keys : Array[Int64] = []
  let mut zero_pairs = 0
  for i in 0..<total {
    if dims[i] < valid_below {
      if killer[i] >= 0 {
        if diams[killer[i]] > diams[i] {
          bar_keys.push(
            (dims[i].to_int64() << 44) |
            (diams[i].to_int64() << 22) |
            diams[killer[i]].to_int64(),
          )
        } else {
          zero_pairs = zero_pairs + 1
        }
      } else if creates[i] {
        // Sorts after every finite bar with the same dimension and birth.
        bar_keys.push(
          (dims[i].to_int64() << 44) | (diams[i].to_int64() << 22) | 0x3FFFFFL,
        )
      }
    }
  }
  bar_keys.sort()
  let bars : Array[Array[Int32]] = []
  for key in bar_keys {
    let death = (key & 0x3FFFFFL).to_int()
    bars.push([
      (key >> 44).to_int(),
      ((key >> 22) & 0x3FFFFFL).to_int(),
      if death == 0x3FFFFF {
        -1
      } else {
        death
      },
    ])
  }
  Some(VrPersistenceReport::{
    n_points: n,
    max_simplex_dim: top_dim,
    valid_below_dim: valid_below,
    simplex_count: total,
    bars,
    zero_length_pairs: zero_pairs,
    cleared_columns: cleared,
  })
}

///|
/// Betti numbers `b_0 .. b_{valid_below_dim - 1}` of `VR(ms, scale_r)` over `F_2`, read off
/// the barcode: a bar `[birth, death)` contributes exactly when `birth <= scale_r < death`.
pub fn vr_barcode_betti_at(
  rep : VrPersistenceReport,
  scale_r : Int32,
) -> Array[Int32] {
  let betti = Array::make(rep.valid_below_dim, 0)
  for bar in rep.bars {
    if bar[1] <= scale_r && (bar[2] < 0 || scale_r < bar[2]) {
      betti[bar[0]] = betti[bar[0]] + 1
    }
  }
  betti
}

///|
/// Cross-check the barcode against the per-scale rank computation
/// `metric_vr_homology_report(ms, r, 2)` at every distinct distance `r` of `ms` and at `r = 0`.
/// Requires the complete complex (`ms.n <= 8`, the range of the per-scale routine).
pub fn vr_barcode_matches_per_scale_ranks(ms : FiniteMetricSpace) -> Bool {
  if ms.n < 1 || ms.n > 8 {
    return false
  }
  match metric_vr_persistence_barcode(ms, ms.n - 1) {
    None => false
    Some(rep) => {
      let scales : Array[Int32] = [0]
      for row in ms.dist {
        for v in row {
          if !scales.contains(v) {
            scales.push(v)
          }
        }
      }
      for r in scales {
        let direct = metric_vr_homology_report(ms, r, 2)
        if vr_barcode_betti_at(rep, r) != direct.betti_homology {
          return false
        }
      }
      true
    }
  }
}

// ---------------------------------------------------------------------------
// Health probe for iteration 3
// ---------------------------------------------------------------------------

///|
/// Path metric of the cycle graph `C_m`.
pub fn metric_cycle_graph(m : Int32) -> FiniteMetricSpace {
  let dist : Array[Array[Int32]] = Array::makei(m, i => {
    Array::makei(m, j => {
      let d = if i > j { i - j } else { j - i }
      if d > m - d {
        m - d
      } else {
        d
      }
    })
  })
  FiniteMetricSpace::{ n: m, dist, }
}

///|
/// Laws of iteration 3, given an already built atlas (so callers that hold one do not
/// pay for a second `6,561`-tensor sweep).
pub fn tensor_check_orbit_pencil_persistence_laws(
  atlas : F3Tensor222Atlas,
) -> Bool {
  // B. Schläfli pencil discriminant == Cayley polynomial on the whole F_3 universe, along
  //    every axis, and over a larger field on a deterministic sample.
  for code in 0..<atlas.total_tensors {
    let t = f3_tensor_of_code(code)
    for axis in 0..<3 {
      if t3_hyperdet222_via_pencil(t, axis) != atlas.hyperdets[code] {
        return false
      }
    }
  }
  let p = 10007
  let mut seed = 12345
  let next = () => {
    seed = (seed * 1103 + 12345) % 1000003
    seed % p
  }
  for _ in 0..<24 {
    let entries = Array::makei(8, _ => next())
    let t = t3_of(2, 2, 2, p, (i, j, k) => entries[(i * 2 + j) * 2 + k])
    let cayley = t3_hyperdet222(t)
    for axis in 0..<3 {
      if t3_hyperdet222_via_pencil(t, axis) != cayley {
        return false
      }
    }
    // A. GL covariance with arbitrary (possibly singular) matrices.
    let gs = Array::makei(3, _ => {
      @gcd.fp_mat_from_rows([[next(), next()], [next(), next()]], p)
    })
    if !t3_hyperdet_gl_covariance_ok(t, gs[0], gs[1], gs[2]) {
      return false
    }
  }
  // A singular factor must annihilate the hyperdeterminant.
  let ghz = t3_of(2, 2, 2, p, (i, j, k) => if i == j && j == k { 1 } else { 0 })
  let id2 = @gcd.fp_mat_from_rows([[1, 0], [0, 1]], p)
  let proj = @gcd.fp_mat_from_rows([[1, 0], [0, 0]], p)
  match t3_multilinear_transform(ghz, proj, id2, id2) {
    Some(flat) => if t3_hyperdet222(flat) != 0 { return false }
    None => return false
  }
  // Shape mismatch is refused instead of silently truncated.
  let wide = @gcd.fp_mat_from_rows([[1, 0, 0], [0, 1, 0]], p)
  if t3_mode_product(ghz, 0, wide) != None {
    return false
  }

  // C. Orbit classification. Every figure below is recomputed, not assumed: the sizes must
  //    add up to 6,561, divide the group order, and agree with Burnside's count.
  let orb = f3_tensor222_orbit_report(atlas)
  if orb.group_order != 110592 ||
    !orb.burnside_divides_exactly ||
    orb.burnside_gl_orbit_count != orb.gl_orbits.length() ||
    !orb.invariants_constant_on_orbits ||
    !orb.sizes_divide_group_order ||
    !orb.sizes_sum_to_total {
    return false
  }
  let gl_sizes = orb.gl_orbits.map(o => o.size)
  gl_sizes.sort()
  let s3_sizes = orb.gl_s3_orbits.map(o => o.size)
  s3_sizes.sort()
  if gl_sizes != [1, 128, 192, 192, 192, 864, 1536, 3456] ||
    s3_sizes != [1, 128, 576, 864, 1536, 3456] {
    return false
  }
  // The rank-3 stratum splits as 1536 (W-class, Det = 0) + 864 (F_9-twisted, Det = 2, the
  // non-square), and these agree with the atlas' own rank-3 counters.
  for o in orb.gl_s3_orbits {
    if o.rank == 3 {
      let expected = if o.hyperdet == 0 {
        atlas.rank3_det_zero_count
      } else {
        atlas.rank3_det_nonzero_count
      }
      let pinned = if o.hyperdet == 0 { 1536 } else { 864 }
      if o.size != expected || o.size != pinned || o.hyperdet == 1 {
        return false
      }
    }
  }
  // Rank and hyperdeterminant separate the S_3-extended orbits completely.
  for x in 0..<orb.gl_s3_orbits.length() {
    for y in (x + 1)..<orb.gl_s3_orbits.length() {
      let a = orb.gl_s3_orbits[x]
      let b = orb.gl_s3_orbits[y]
      if a.rank == b.rank && a.hyperdet == b.hyperdet {
        return false
      }
    }
  }

  // D. Barcodes. C_6: the circle class lives on [1, 2). Octahedron: a 2-sphere on [1, 2).
  let c6 = metric_cycle_graph(6)
  let octa = FiniteMetricSpace::{
    n: 6,
    dist: Array::makei(6, i => {
      Array::makei(6, j => if i == j { 0 } else if i + j == 5 { 2 } else { 1 })
    }),
  }
  if !vr_barcode_matches_per_scale_ranks(c6) ||
    !vr_barcode_matches_per_scale_ranks(octa) ||
    !vr_barcode_matches_per_scale_ranks(metric_cycle_graph(7)) {
    return false
  }
  match
    (
      metric_vr_persistence_barcode(c6, 5),
      metric_vr_persistence_barcode(octa, 5),
    ) {
    (Some(b6), Some(bo)) =>
      if !b6.bars.contains([1, 1, 2]) ||
        !b6.bars.contains([0, 0, -1]) ||
        !bo.bars.contains([2, 1, 2]) ||
        vr_barcode_betti_at(bo, 1) != [1, 0, 1, 0, 0, 0] {
        return false
      }
    _ => return false
  }
  // Truncated complex on 12 points (beyond the per-scale routine): H_1 of C_12 dies at 4.
  match metric_vr_persistence_barcode(metric_cycle_graph(12), 2) {
    Some(b12) =>
      b12.valid_below_dim == 2 &&
      b12.simplex_count == 298 &&
      b12.bars.contains([1, 1, 4]) &&
      vr_barcode_betti_at(b12, 3) == [1, 1] &&
      vr_barcode_betti_at(b12, 4) == [1, 0]
    None => false
  }
}
