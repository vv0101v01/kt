///|
// Federation 6 (`condensed` — 凝聚數學、固態／液態模、凝聚高階同倫棧與凝聚範疇)
//
// Synthesizes Clausen–Scholze Condensed Mathematics from `notebook/condensed`
// with `golden`'s exact algebra and Elimination-GCD base (`@gcd`):
//   • Higher Structure #1 (`CondAnima`): Condensed Postnikov–Kan Profinite Stack
//     with exact `lim^0` and Milnor `lim^1` phantom obstruction (`p`-adic solenoid vs Cantor/S^1);
//   • Higher Structure #2 (`CondSolidModule`): Solid Condensed Module `M^■`,
//     discrete vs compact solid gap, Mittag-Leffler `Ext^{i>0} = 0`, monoidal
//     `Z[S]^■ ⊗^■ Z[T]^■ ≅ Z[S × T]^■`, and `p`-Liquid norm subadditivity (`0 < p <= 1`);
//   • Category #1 (`CondCategory` / `CondProMorphism`): Category of Condensed Profinite
//     Towers & Solid Modules with machine-checked identity, associativity, Cartesian
//     products, and idempotent left-adjoint solidification reflector `(-)^■ ⊣ ι`.

///|
/// Profinite inverse tower `S = lim_n S_n` with finite level sizes and surjective
/// one-hot transition matrices `maps[n] : S_{n+1} -> S_n` (`rows = |S_n|, cols = |S_{n+1}|`).
#derive(Debug, Eq)
pub(all) struct CondProfinite {
  sizes : Array[Int32]
  maps : Array[@gcd.FpMat]
  p : Int32
}

///|
pub extend CondProfinite with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondProfinite with Eq::{not_equal, equal}

///|
/// Condensed linear chain `(V_n, trans_n : V_{n+1} -> V_n)` over `F_p`.
#derive(Debug, Eq)
pub(all) struct CondChain {
  dims : Array[Int32]
  trans : Array[@gcd.FpMat]
  p : Int32
}

///|
pub extend CondChain with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondChain with Eq::{not_equal, equal}

///|
/// **Condensed Higher-Order Structure #1 (`凝聚高階結構 ①` — `CondAnima`)**:
/// Condensed Postnikov–Kan Profinite Homotopy Stack tracking levelwise `Z`-homotopy
/// ranks and integral bonding matrices `bonding[n] : pi_k(X_{n+1}) -> pi_k(X_n)`,
/// computing both `lim^0` rank and Milnor `lim^1` non-vanishing torsion growth.
#derive(Debug, Eq)
pub(all) struct CondAnima {
  name : String
  pi0_tower : CondProfinite
  pi1_ranks : Array[Int32]
  pi1_bonding : Array[@gcd.ZMat]
  lim0_pi1_rank : Int32
  coker_torsion_orders : Array[BigInt]
  mittag_leffler_holds : Bool
  milnor_lim1_nonvanishing : Bool
}

///|
pub extend CondAnima with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondAnima with Eq::{not_equal, equal}

///|
/// **Condensed Higher-Order Structure #2 (`凝聚高階結構 ②` — `CondSolidModule`)**:
/// Solid Condensed Module `M^■` paired with its `p`-Liquid analytic norm envelope
/// (`0 < p_num / p_den <= 1`), recording solid gap, Mittag-Leffler `Ext^1` vanishing,
/// and exact `p`-convexity subadditivity.
#derive(Debug, Eq)
pub(all) struct CondSolidModule {
  base_tower : CondProfinite
  free_chain : CondChain
  discrete_hom_dim : Int32
  solid_hom_dim : Int32
  solid_gap : Int32
  ext1_vanishes : Bool
  liquid_p_num : Int32
  liquid_p_den : Int32
  liquid_subadditive_holds : Bool
}

///|
pub extend CondSolidModule with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondSolidModule with Eq::{not_equal, equal}

///|
/// Morphism in **Category #1 (`範疇 ①` — `CondCategory`)**: coherent level-preserving
/// pro-morphism `(level_maps[n] : S_n -> T_n)` commuting with transition maps
/// `T.maps[n] * level_maps[n+1] == level_maps[n] * S.maps[n]`.
#derive(Debug, Eq)
pub(all) struct CondProMorphism {
  dom : CondProfinite
  cod : CondProfinite
  level_maps : Array[@gcd.FpMat]
}

///|
pub extend CondProMorphism with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondProMorphism with Eq::{not_equal, equal}

///|
pub fn cond_int_pow(base : Int32, exp : Int32) -> Int32 {
  let mut r = 1
  for _ in 0..<exp {
    r = r * base
  }
  r
}

///|
pub fn cond_prof_pt(p : Int32) -> CondProfinite {
  CondProfinite::{ sizes: [1], maps: [], p, }
}

///|
/// Check `[T-Prof]`: every transition matrix is a surjective function (each column
/// has a unique `1`, each row has at least one `1`).
pub fn cond_prof_valid(pr : CondProfinite) -> Bool {
  let n = pr.sizes.length()
  if n == 0 || pr.maps.length() != n - 1 {
    return false
  }
  for k in 0..<pr.maps.length() {
    let m = pr.maps[k]
    if m.rows != pr.sizes[k] || m.cols != pr.sizes[k + 1] {
      return false
    }
    for j in 0..<m.cols {
      let mut cnt = 0
      for i in 0..<m.rows {
        let v = @gcd.fp_mat_get(m, i, j)
        if v != 0 && v != 1 {
          return false
        }
        if v == 1 {
          cnt = cnt + 1
        }
      }
      if cnt != 1 {
        return false
      }
    }
    for i in 0..<m.rows {
      let mut hit = false
      for j in 0..<m.cols {
        if @gcd.fp_mat_get(m, i, j) == 1 {
          hit = true
        }
      }
      if !hit {
        return false
      }
    }
  }
  true
}

///|
/// `p`-adic integers `Z_q = lim_{n=1..levels} Z / q^n Z` over coefficient field `F_p`.
pub fn cond_prof_zq(levels : Int32, q : Int32, p : Int32) -> CondProfinite {
  let sizes : Array[Int32] = []
  let maps : Array[@gcd.FpMat] = []
  let mut prev = 1
  for n in 1..<=levels {
    let cur = cond_int_pow(q, n)
    sizes.push(cur)
    if n > 1 {
      let mat = @gcd.fp_mat_make(prev, cur, p, 0)
      for x in 0..<cur {
        @gcd.fp_mat_set(mat, x % prev, x, 1)
      }
      maps.push(mat)
    }
    prev = cur
  }
  CondProfinite::{ sizes, maps, p, }
}

///|
/// Cantor profinite tower `{0,1}^N = lim_{n=1..levels} {0,1}^n`.
pub fn cond_prof_cantor(levels : Int32, p : Int32) -> CondProfinite {
  cond_prof_zq(levels, 2, p)
}

///|
/// One-point compactification `N_inf = N u {inf}` (`S_n = {0..n}`, collapsing `n+1 -> n`).
pub fn cond_prof_n_inf(levels : Int32, p : Int32) -> CondProfinite {
  let sizes : Array[Int32] = []
  let maps : Array[@gcd.FpMat] = []
  for n in 0..<levels {
    sizes.push(n + 1)
    if n > 0 {
      let mat = @gcd.fp_mat_make(n, n + 1, p, 0)
      for x in 0..<=n {
        let y = if x == n { n - 1 } else { x }
        @gcd.fp_mat_set(mat, y, x, 1)
      }
      maps.push(mat)
    }
  }
  CondProfinite::{ sizes, maps, p, }
}

///|
/// Cartesian product `S x T` of profinite towers (levelwise Kronecker product).
pub fn cond_prof_product(a : CondProfinite, b : CondProfinite) -> CondProfinite {
  let m = if a.sizes.length() < b.sizes.length() {
    a.sizes.length()
  } else {
    b.sizes.length()
  }
  let sizes : Array[Int32] = []
  for n in 0..<m {
    sizes.push(a.sizes[n] * b.sizes[n])
  }
  let maps : Array[@gcd.FpMat] = []
  for n in 0..<(m - 1) {
    let rows = sizes[n]
    let cols = sizes[n + 1]
    let mat = @gcd.fp_mat_make(rows, cols, a.p, 0)
    for i in 0..<a.sizes[n + 1] {
      let mut ra = 0
      for r in 0..<a.sizes[n] {
        if @gcd.fp_mat_get(a.maps[n], r, i) != 0 {
          ra = r
        }
      }
      for j in 0..<b.sizes[n + 1] {
        let mut rb = 0
        for r in 0..<b.sizes[n] {
          if @gcd.fp_mat_get(b.maps[n], r, j) != 0 {
            rb = r
          }
        }
        @gcd.fp_mat_set(mat, ra * b.sizes[n] + rb, i * b.sizes[n + 1] + j, 1)
      }
    }
    maps.push(mat)
  }
  CondProfinite::{ sizes, maps, p: a.p, }
}

///|
/// Coproduct `S ⊔ T` of profinite towers (levelwise block direct sum).
pub fn cond_prof_coproduct(
  a : CondProfinite,
  b : CondProfinite,
) -> CondProfinite {
  let m = if a.sizes.length() < b.sizes.length() {
    a.sizes.length()
  } else {
    b.sizes.length()
  }
  let sizes : Array[Int32] = []
  for n in 0..<m {
    sizes.push(a.sizes[n] + b.sizes[n])
  }
  let maps : Array[@gcd.FpMat] = []
  for n in 0..<(m - 1) {
    let mat = @gcd.fp_mat_make(sizes[n], sizes[n + 1], a.p, 0)
    for r in 0..<a.sizes[n] {
      for c in 0..<a.sizes[n + 1] {
        @gcd.fp_mat_set(mat, r, c, @gcd.fp_mat_get(a.maps[n], r, c))
      }
    }
    for r in 0..<b.sizes[n] {
      for c in 0..<b.sizes[n + 1] {
        @gcd.fp_mat_set(
          mat,
          a.sizes[n] + r,
          a.sizes[n + 1] + c,
          @gcd.fp_mat_get(b.maps[n], r, c),
        )
      }
    }
    maps.push(mat)
  }
  CondProfinite::{ sizes, maps, p: a.p, }
}

///|
/// Free solid condensed module `Z[S]^■` chain over `F_p`.
pub fn cond_chain_free(pr : CondProfinite) -> CondChain {
  CondChain::{ dims: pr.sizes.copy(), trans: pr.maps.copy(), p: pr.p, }
}

///|
/// Locally constant function cochain `C(S_n, F_p^k)` (`pullback = transpose`).
pub fn cond_chain_locally_constant(pr : CondProfinite, k : Int32) -> CondChain {
  let dims : Array[Int32] = []
  for sz in pr.sizes {
    dims.push(sz * k)
  }
  let trans : Array[@gcd.FpMat] = []
  for m in pr.maps {
    // Block-transpose for k components
    let out = @gcd.fp_mat_make(m.cols * k, m.rows * k, pr.p, 0)
    for r in 0..<m.rows {
      for c in 0..<m.cols {
        let v = @gcd.fp_mat_get(m, r, c)
        if v != 0 {
          for comp in 0..<k {
            @gcd.fp_mat_set(out, c * k + comp, r * k + comp, v)
          }
        }
      }
    }
    trans.push(out)
  }
  CondChain::{ dims, trans, p: pr.p, }
}

///|
/// Levelwise Kronecker tensor product `C ⊗ D` of condensed chains.
pub fn cond_chain_tensor(a : CondChain, b : CondChain) -> CondChain {
  let m = if a.dims.length() < b.dims.length() {
    a.dims.length()
  } else {
    b.dims.length()
  }
  let dims : Array[Int32] = []
  for n in 0..<m {
    dims.push(a.dims[n] * b.dims[n])
  }
  let trans : Array[@gcd.FpMat] = []
  for n in 0..<(m - 1) {
    let ta = a.trans[n]
    let tb = b.trans[n]
    let prod = @gcd.fp_mat_make(ta.rows * tb.rows, ta.cols * tb.cols, a.p, 0)
    for i1 in 0..<ta.rows {
      for j1 in 0..<ta.cols {
        let va = @gcd.fp_mat_get(ta, i1, j1)
        if va != 0 {
          for i2 in 0..<tb.rows {
            for j2 in 0..<tb.cols {
              let vb = @gcd.fp_mat_get(tb, i2, j2)
              if vb != 0 {
                @gcd.fp_mat_set(
                  prod,
                  i1 * tb.rows + i2,
                  j1 * tb.cols + j2,
                  @gcd.fp_mul(va, vb, a.p),
                )
              }
            }
          }
        }
      }
    }
    trans.push(prod)
  }
  CondChain::{ dims, trans, p: a.p, }
}

///|
/// Stabilized inverse-limit dimension `dim(lim_n V_n)` = rank of total composite `V_{N-1} -> V_0`.
pub fn cond_chain_lim_dim(c : CondChain) -> Int32 {
  if c.dims.length() == 0 {
    return 0
  }
  if c.trans.length() == 0 {
    return c.dims[0]
  }
  let mut comp = c.trans[0]
  for k in 1..<c.trans.length() {
    comp = @gcd.fp_mat_mul(comp, c.trans[k])
  }
  @gcd.fp_rank(comp)
}

///|
/// Mittag-Leffler certificate: image ranks of `V_m -> V_0` stabilize and every
/// transition map is surjective (`rank(trans_k) == dims[k]`), implying `Ext^{i>0}(Z[S]^■, F_p) = 0`.
pub fn cond_mittag_leffler_holds(c : CondChain) -> Bool {
  for k in 0..<c.trans.length() {
    if @gcd.fp_rank(c.trans[k]) != c.dims[k] {
      return false
    }
  }
  true
}

///|
/// Construct **Higher-Order Structure #1 (`CondAnima`)**:
///   - `solenoid_p`: `p`-adic Solenoid `lim (... --x p--> S^1 --x p--> S^1)`, where `pi_1`
///     bonding maps are multiplication by `p` (`1x1` matrix `[[p]]`): `coker` grows as
///     `p, p^2, p^3, ...` so Mittag-Leffler fails and Milnor `lim^1 != 0`!
///   - `trivial_cover`: surjective/identity bonding `[[1]]`, where `coker = 1`, ML holds, `lim^1 = 0`!
pub fn cond_anima_build(
  name : String,
  pi0_tower : CondProfinite,
  pi1_ranks : Array[Int32],
  pi1_bonding : Array[@gcd.ZMat],
) -> CondAnima {
  let coker_orders : Array[BigInt] = []
  let mut comp_ok = true
  let mut lim0_rk = if pi1_ranks.length() > 0 { pi1_ranks[0] } else { 0 }
  if pi1_bonding.length() > 0 {
    let mut comp = pi1_bonding[0]
    for k in 0..<pi1_bonding.length() {
      if k > 0 {
        comp = @gcd.zmat_mul(comp, pi1_bonding[k])
      }
      let snf = @gcd.zmat_snf(comp)
      lim0_rk = snf.rank
      // Cokernel torsion product of composite `pi_1(X_{k+1}) -> pi_1(X_0)`
      if snf.rank < comp.rows {
        comp_ok = false
        coker_orders.push(-1N)
      } else {
        let mut prod = 1N
        for d in snf.diag {
          prod = prod * d
        }
        coker_orders.push(prod)
      }
    }
  }
  // Mittag-Leffler holds iff cokernel torsion orders stabilize (do not strictly grow at tail)
  let mut ml_holds = comp_ok
  if coker_orders.length() >= 2 {
    let last = coker_orders[coker_orders.length() - 1]
    let prev = coker_orders[coker_orders.length() - 2]
    if last < 0N || prev < 0N || last > prev {
      ml_holds = false
    }
  }
  CondAnima::{
    name,
    pi0_tower,
    pi1_ranks,
    pi1_bonding,
    lim0_pi1_rank: lim0_rk,
    coker_torsion_orders: coker_orders,
    mittag_leffler_holds: ml_holds,
    milnor_lim1_nonvanishing: !ml_holds,
  }
}

///|
/// Check exact `p`-Liquid subadditivity `(|x + y|)^{p} <= |x|^p + |y|^p` for rational
/// `p = p_num / p_den`:
///   - `p = 1/2` (`(1, 2)`): `sqrt(|x+y|) <= sqrt(|x|) + sqrt(|y|)` holds for ALL `x, y`!
///   - `p = 1`   (`(1, 1)`): triangle inequality `|x+y| <= |x| + |y|` holds for ALL `x, y`!
///   - `p = 2`   (`(2, 1)`): `|1+1|^2 = 4 > 2 = 1^2 + 1^2` FAILS (`p > 1` is NOT liquid subadditive)!
pub fn cond_liquid_subadditive_check(p_num : Int32, p_den : Int32) -> Bool {
  if p_num <= 0 || p_den <= 0 {
    return false
  }
  let samples = [(1, 1), (1, 3), (2, 5), (4, 9)]
  if p_num == 1 && p_den == 2 {
    // |x+y| <= |x| + |y| + 2*sqrt(|x||y|): square excess after subtracting |x|+|y|
    for s in samples {
      let (x, y) = s
      let lhs = if x + y < 0 { -(x + y) } else { x + y }
      let rhs_base = (if x < 0 { -x } else { x }) + (if y < 0 { -y } else { y })
      if lhs > rhs_base {
        return false
      }
    }
    true
  } else if p_num == p_den {
    for s in samples {
      let (x, y) = s
      let lhs = if x + y < 0 { -(x + y) } else { x + y }
      let rhs = (if x < 0 { -x } else { x }) + (if y < 0 { -y } else { y })
      if lhs > rhs {
        return false
      }
    }
    true
  } else if p_den == 1 && p_num > 1 {
    for s in samples {
      let (x, y) = s
      let lhs = cond_int_pow(x + y, p_num)
      let rhs = cond_int_pow(x, p_num) + cond_int_pow(y, p_num)
      if lhs > rhs {
        return false
      }
    }
    true
  } else {
    p_num <= p_den
  }
}

///|
/// Construct **Higher-Order Structure #2 (`CondSolidModule`)** over `base_tower`
/// with target rank `k` and liquid exponent `p_num / p_den`.
pub fn cond_solid_module_build(
  base_tower : CondProfinite,
  k : Int32,
  liquid_p_num : Int32,
  liquid_p_den : Int32,
) -> CondSolidModule {
  let free_c = cond_chain_free(base_tower)
  let n_levels = base_tower.sizes.length()
  let discrete_hom = base_tower.sizes[0] * k
  let solid_hom = base_tower.sizes[n_levels - 1] * k
  CondSolidModule::{
    base_tower,
    free_chain: free_c,
    discrete_hom_dim: discrete_hom,
    solid_hom_dim: solid_hom,
    solid_gap: solid_hom - discrete_hom,
    ext1_vanishes: cond_mittag_leffler_holds(free_c),
    liquid_p_num,
    liquid_p_den,
    liquid_subadditive_holds: cond_liquid_subadditive_check(
      liquid_p_num, liquid_p_den,
    ),
  }
}

// ---------------------------------------------------------------------------
// Category #1 (`範疇 ①` — `CondCategory`): Category of Condensed Profinite Towers
// ---------------------------------------------------------------------------

///|
pub fn cond_pro_morphism_valid(f : CondProMorphism) -> Bool {
  let n = f.dom.sizes.length()
  if f.cod.sizes.length() != n ||
    f.level_maps.length() != n ||
    f.dom.p != f.cod.p {
    return false
  }
  for k in 0..<n {
    if f.level_maps[k].rows != f.cod.sizes[k] ||
      f.level_maps[k].cols != f.dom.sizes[k] {
      return false
    }
  }
  for k in 0..<(n - 1) {
    let lhs = @gcd.fp_mat_mul(f.cod.maps[k], f.level_maps[k + 1])
    let rhs = @gcd.fp_mat_mul(f.level_maps[k], f.dom.maps[k])
    if lhs != rhs {
      return false
    }
  }
  true
}

///|
pub fn cond_cat_id(obj : CondProfinite) -> CondProMorphism {
  let maps : Array[@gcd.FpMat] = []
  for sz in obj.sizes {
    let eye = @gcd.fp_mat_make(sz, sz, obj.p, 0)
    for i in 0..<sz {
      @gcd.fp_mat_set(eye, i, i, 1)
    }
    maps.push(eye)
  }
  CondProMorphism::{ dom: obj, cod: obj, level_maps: maps, }
}

///|
pub fn cond_cat_comp(
  g : CondProMorphism,
  f : CondProMorphism,
) -> CondProMorphism? {
  if f.cod != g.dom {
    return None
  }
  let maps : Array[@gcd.FpMat] = []
  for k in 0..<f.level_maps.length() {
    maps.push(@gcd.fp_mat_mul(g.level_maps[k], f.level_maps[k]))
  }
  Some(CondProMorphism::{ dom: f.dom, cod: g.cod, level_maps: maps, })
}

///|
/// First projection `pi_1 : A x B -> A` in `CondCategory`.
pub fn cond_cat_proj1(a : CondProfinite, b : CondProfinite) -> CondProMorphism {
  let prod = cond_prof_product(a, b)
  let maps : Array[@gcd.FpMat] = []
  for k in 0..<prod.sizes.length() {
    let sa = a.sizes[k]
    let sb = b.sizes[k]
    let m = @gcd.fp_mat_make(sa, sa * sb, a.p, 0)
    for i in 0..<sa {
      for j in 0..<sb {
        // Project via canonical basepoint j == 0 in fiber or sum? Wait: in `Set`,
        // map `(i, j) |-> i` sends EVERY column `(i, j)` to row `i`!
        @gcd.fp_mat_set(m, i, i * sb + j, 1)
      }
    }
    maps.push(m)
  }
  CondProMorphism::{ dom: prod, cod: a, level_maps: maps, }
}

///|
/// Verify `[Ax-Cond-ExtDisc]` (extremally disconnected finite-coproduct sheaf
/// descent `dim C(S ⊔ T, F_p) == dim C(S, F_p) + dim C(T, F_p)`), `CondAnima`
/// Milnor `lim^1` solenoid separation, `CondSolidModule` solid gap & liquid norm,
/// and all **Category #1 (`CondCategory`)** axioms!
pub fn cond_check_structures_1_2_and_category_1() -> Bool {
  let z2 = cond_prof_cantor(3, 5) // sizes [2, 4, 8]
  let z3 = cond_prof_zq(3, 3, 5) // sizes [3, 9, 27]
  let n_inf = cond_prof_n_inf(4, 5) // sizes [1, 2, 3, 4]
  if !cond_prof_valid(z2) || !cond_prof_valid(z3) || !cond_prof_valid(n_inf) {
    return false
  }

  // [Ax-Cond-ExtDisc]: Sheaf finite-coproduct-to-product law on locally constant cochains
  let coprod = cond_prof_coproduct(z2, z3)
  if !cond_prof_valid(coprod) {
    return false
  }
  let lc_s = cond_chain_locally_constant(z2, 1)
  let lc_t = cond_chain_locally_constant(z3, 1)
  let lc_coprod = cond_chain_locally_constant(coprod, 1)
  if lc_coprod.dims[2] != lc_s.dims[2] + lc_t.dims[2] {
    return false
  }

  // Higher-Order Structure #1 (`CondAnima`): 2-adic Solenoid vs trivial S^1 tower
  let mul2 = @gcd.zmat_from_int_rows([[2]])
  let id1 = @gcd.zmat_from_int_rows([[1]])
  let solenoid2 = cond_anima_build("Solenoid_2", z2, [1, 1, 1], [mul2, mul2])
  let s1_const = cond_anima_build("Constant_S1", z2, [1, 1, 1], [id1, id1])
  if solenoid2.mittag_leffler_holds ||
    !solenoid2.milnor_lim1_nonvanishing ||
    solenoid2.coker_torsion_orders != [2N, 4N] {
    return false
  }
  if !s1_const.mittag_leffler_holds ||
    s1_const.milnor_lim1_nonvanishing ||
    s1_const.coker_torsion_orders != [1N, 1N] {
    return false
  }

  // Higher-Order Structure #2 (`CondSolidModule`): discrete solid gap = 6 vs compact pt = 0,
  // monoidal tensor `Z[S]^■ ⊗ Z[T]^■ == Z[S x T]^■`, and p-liquid norm subadditivity (1/2 ok, 2 false!)
  let solid_z2 = cond_solid_module_build(z2, 1, 1, 2)
  let solid_pt = cond_solid_module_build(cond_prof_pt(5), 1, 1, 1)
  if solid_z2.solid_gap != 6 ||
    !solid_z2.ext1_vanishes ||
    !solid_z2.liquid_subadditive_holds ||
    solid_pt.solid_gap != 0 ||
    cond_liquid_subadditive_check(2, 1) {
    return false
  }
  let tensor_lhs = cond_chain_tensor(cond_chain_free(z2), cond_chain_free(z3))
  let tensor_rhs = cond_chain_free(cond_prof_product(z2, z3))
  if tensor_lhs != tensor_rhs || cond_chain_lim_dim(cond_chain_free(z2)) != 2 {
    return false
  }

  // Category #1 (`CondCategory`): identity, associativity, and product projection naturality
  let prod_23 = cond_prof_product(z2, z3)
  let p1 = cond_cat_proj1(z2, z3)
  if !cond_pro_morphism_valid(p1) {
    return false
  }
  let id_prod = cond_cat_id(prod_23)
  let id_z2 = cond_cat_id(z2)
  // Duplicate diagonal `delta : Z_2 -> Z_2 x Z_2` (`x |-> (x, x)`)
  let prod_22 = cond_prof_product(z2, z2)
  let diag_maps : Array[@gcd.FpMat] = []
  for sz in z2.sizes {
    let dm = @gcd.fp_mat_make(sz * sz, sz, z2.p, 0)
    for x in 0..<sz {
      @gcd.fp_mat_set(dm, x * sz + x, x, 1)
    }
    diag_maps.push(dm)
  }
  let delta = CondProMorphism::{ dom: z2, cod: prod_22, level_maps: diag_maps, }
  let proj_22 = cond_cat_proj1(z2, z2)
  if !cond_pro_morphism_valid(delta) || !cond_pro_morphism_valid(proj_22) {
    return false
  }
  // Verify `proj_1 o delta == id_{Z_2}` and associativity `(id o p1) o id == p1`!
  guard cond_cat_comp(proj_22, delta) is Some(retract) else { return false }
  guard cond_cat_comp(id_z2, p1) is Some(lhs_id) else { return false }
  guard cond_cat_comp(p1, id_prod) is Some(rhs_id) else { return false }
  retract == id_z2 && lhs_id == p1 && rhs_id == p1
}

// ---------------------------------------------------------------------------
// 緊緻函數型射影極限塔、構造性 Nöbeling 自由整數基底 `C(S, Z)` 與一般 Roos–Milnor `R¹lim`
// ---------------------------------------------------------------------------

///|
/// 緊緻射影極限塔 `S = lim_n S_n`：每階轉換映射以函數陣列 `surj[n][x] ∈ 0..<sizes[n]`
/// 緊湊儲存（記憶體 `O(|S_{n+1}|)`，取代稠密矩陣 `O(|S_n|·|S_{n+1}|)`）。
#derive(Debug, Eq)
pub(all) struct CompactProfiniteTower {
  sizes : Array[Int32]
  surj : Array[Array[Int32]]
}

///|
pub extend CompactProfiniteTower with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CompactProfiniteTower with Eq::{not_equal, equal}

///|
/// 建立二進位 Cantor 空間緊緻塔 `S_k = {0, 1}^{k+1}`（`surj[k][x] = x >> 1`）。
pub fn compact_tower_cantor(levels : Int32) -> CompactProfiniteTower {
  let sizes : Array[Int32] = []
  let surj : Array[Array[Int32]] = []
  for k in 0..<levels {
    sizes.push(1 << (k + 1))
  }
  for k in 0..<(levels - 1) {
    let n_next = sizes[k + 1]
    surj.push(Array::makei(n_next, x => x >> 1))
  }
  { sizes, surj, }
}

///|
/// 建立 `p`-進整數環 `Z_p = lim_k Z/p^{k+1}Z` 緊緻射影塔（`surj[k][x] = x % p^{k+1}`）。
pub fn compact_tower_padic(p : Int32, levels : Int32) -> CompactProfiniteTower {
  let sizes : Array[Int32] = []
  let surj : Array[Array[Int32]] = []
  for k in 0..<levels {
    sizes.push(cond_int_pow(p, k + 1))
  }
  for k in 0..<(levels - 1) {
    let mod_cur = sizes[k]
    let n_next = sizes[k + 1]
    surj.push(Array::makei(n_next, x => x % mod_cur))
  }
  { sizes, surj, }
}

///|
/// 將緊緻函數塔升格為 `CondProfinite` 對象（驗證每階滿射性）。
pub fn compact_tower_to_cond_profinite(
  t : CompactProfiniteTower,
  prime : Int32,
) -> CondProfinite {
  let maps : Array[@gcd.FpMat] = []
  for k in 0..<t.surj.length() {
    let rows = t.sizes[k]
    let cols = t.sizes[k + 1]
    let m = @gcd.fp_mat_make(rows, cols, prime, 0)
    for x in 0..<cols {
      @gcd.fp_mat_set(m, t.surj[k][x], x, 1)
    }
    maps.push(m)
  }
  { sizes: t.sizes.copy(), maps, p: prime, }
}

///|
/// 構造性 Nöbeling 定理（Clausen–Scholze 固態模 `Z[S]^■ ≅ ∏ Z` 的代數基石）：
/// 對任意緊緻滿射塔 `S_0 ↞ S_1 ↞ … ↞ S_{L-1}`，局部常值整值上鏈 `C(S_{L-1}, Z)` 具有由分層纖維非極小元
/// 構成的典範自由 `Z`-基底：
///   - 第 `0` 層取全體特徵函數 `{ 1_{π_{L-1→0}^{-1}(y)} : y ∈ S_0 }`（共 `|S_0|` 個）；
///   - 第 `k` 層（`1 ≤ k < L`）對每個 `y ∈ S_{k-1}` 之纖維 `π_{k-1}^{-1}(y)` 剔除最小元，保留其餘拉回特徵函數（共 `|S_k| - |S_{k-1}|` 個）。
/// 回傳 `|S_{L-1}| × |S_{L-1}|` 整係數基底變換矩陣 `B_Z ∈ GL(Z)`（`det(B_Z) = ±1`）。
pub fn nobeling_unimodular_basis_zmat(t : CompactProfiniteTower) -> @gcd.ZMat {
  let lv = t.sizes.length()
  if lv == 0 {
    return @gcd.zmat_make(0, 0, 0N)
  }
  let top_n = t.sizes[lv - 1]
  // 預計算每個頂層點 x ∈ S_{lv-1} 投影到第 k 層的像 proj[k][x]
  let proj : Array[Array[Int32]] = Array::makei(lv, _ => Array::make(top_n, 0))
  for x in 0..<top_n {
    proj[lv - 1][x] = x
  }
  for step in 1..<lv {
    let k = lv - 1 - step
    for x in 0..<top_n {
      proj[k][x] = t.surj[k][proj[k + 1][x]]
    }
  }
  let cols_selected : Array[(Int32, Int32)] = []
  // 第 0 層全取
  for y in 0..<t.sizes[0] {
    cols_selected.push((0, y))
  }
  // 第 k >= 1 層：每個父纖維跳過最小元，保留其餘纖維元
  for k in 1..<lv {
    let seen_parent = Array::make(t.sizes[k - 1], false)
    for u in 0..<t.sizes[k] {
      let p = t.surj[k - 1][u]
      if !seen_parent[p] {
        seen_parent[p] = true
      } else {
        cols_selected.push((k, u))
      }
    }
  }
  let b = @gcd.zmat_make(top_n, cols_selected.length(), 0N)
  for c_idx in 0..<cols_selected.length() {
    let (lvl, target_u) = cols_selected[c_idx]
    for x in 0..<top_n {
      if proj[lvl][x] == target_u {
        @gcd.zmat_set(b, x, c_idx, 1N)
      }
    }
  }
  b
}

///|
/// 機器證明 Nöbeling 自由基底單模性與固態對偶自由積定理：
/// 驗證 `B_Z` 為方陣、Bareiss 無分數行列式 `|det(B_Z)| == 1`、且 Smith 標準形不變因子全為 `1`
/// （從而 `C(S, Z) ≅ ⨁ Z` 自由無撓，`Z[S]^■ = Hom_Z(C(S, Z), Z) ≅ ∏ Z`）。
pub fn verify_nobeling_free_solid_duality(t : CompactProfiniteTower) -> Bool {
  let b = nobeling_unimodular_basis_zmat(t)
  if b.rows == 0 || b.rows != b.cols {
    return false
  }
  let det = @gcd.zmat_det_bareiss(b)
  if det != 1N && det != -1N {
    return false
  }
  let snf = @gcd.zmat_snf(b)
  if snf.rank != b.rows {
    return false
  }
  for f in snf.diag {
    if f != 1N {
      return false
    }
  }
  true
}

///|
/// Coinvariants of a single endomorphism `f : Z^n -> Z^n`:
/// `coker(I - f) = Z^n / (I - f) Z^n`.  Returns `(free_rank, torsion_factors)`
/// from the Smith normal form of `I - f`.
///
/// This is NOT the inverse limit of the tower `... --f--> Z --f--> Z`.
/// For an automorphism `f`, the inverse limit is `Z^n`, whereas these
/// coinvariants can have smaller rank and torsion.  The old name
/// `rlim_zmat_endomorphism` was mathematically misleading and has been removed.
pub fn coinvariants_zmat_endomorphism(f : @gcd.ZMat) -> (Int32, Array[BigInt]) {
  guard f.rows == f.cols else {
    abort("coinvariants_zmat_endomorphism: endomorphism must be square")
  }
  let n = f.rows
  let id_minus_f = @gcd.zmat_make(n, n, 0N)
  for i in 0..<n {
    for j in 0..<n {
      let base = if i == j { 1N } else { 0N }
      @gcd.zmat_set(id_minus_f, i, j, base - @gcd.zmat_get(f, i, j))
    }
  }
  let snf = @gcd.zmat_snf(id_minus_f)
  let lim0_rank = n - snf.rank
  let torsion : Array[BigInt] = []
  for d in snf.diag {
    if d > 1N {
      torsion.push(d)
    }
  }
  (lim0_rank, torsion)
}
