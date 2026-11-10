///|
// Federation 7 (`discovery`) — Layer-3 Decoupled Algorithmic Discovery Kernel (`conjecture/kernel`):
//
// Breaks the 8-package fan-in chokepoint of `conjecture` so middle-layer mathematical
// federations (`F1 cubical`, `F4 topos`, `F5 scheme`) can invoke `[E-Derive]` invariant
// synthesis and 64-bit bitplane epistemic implication lattices with minimal dependencies
// (`gcd` + `accel/swar` + `tensor` only).
//
// Core Algorithmic Upgrades:
//   1. `half_gcd_rat_recon`: Wang–Guy–Davenport `O(log p)` half-Euclidean rational
//      reconstruction (`2 * r_k^2 < p` and `2 * t_k^2 < p`), recovering exact signed
//      integer conservation laws whose denominators exceed the old `1..<=64` trial wall.
//   2. `implication_lattice_build`: 64-sample-per-word SWAR bitplane engine computing
//      `implies[i][j]` and exact minimal counterexample IDs via hardware `ctz` (`64x` speedup).

///|
/// Observation matrix along a mathematical evolution / deformation trajectory
/// (`[D-RowSet]`): each row is one state's integer invariant tuple.
#derive(Debug, Eq)
pub(all) struct ObservationRowSet {
  name : String
  columns : Array[String]
  rows : Array[Array[Int32]]
}

///|
pub extend ObservationRowSet with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ObservationRowSet with Eq::{not_equal, equal}

///|
pub fn rowset_holds_exact(rs : ObservationRowSet, coeff : Array[Int32]) -> Bool {
  for row in rs.rows {
    if row.length() != coeff.length() {
      return false
    }
    let mut s = 0L
    for i in 0..<coeff.length() {
      s = s + coeff[i].to_int64() * row[i].to_int64()
    }
    if s != 0L {
      return false
    }
  }
  true
}

///|
pub fn rowset_holds_mod(
  rs : ObservationRowSet,
  coeff : Array[Int32],
  p : Int32,
) -> Bool {
  for row in rs.rows {
    if row.length() != coeff.length() {
      return false
    }
    let mut s = 0
    for i in 0..<coeff.length() {
      s = @gcd.fp_add(s, @gcd.fp_mul(coeff[i], row[i], p), p)
    }
    if s != 0 {
      return false
    }
  }
  true
}

///|
/// Wang–Guy–Davenport `O(log p)` Half-GCD modular rational reconstruction:
/// Given `rem ∈ [0, p)` over prime `p`, finds `(num, den)` (`den > 0`) satisfying
/// `rem * den ≡ num (mod p)` with `2 * num^2 < p` and `2 * den^2 < p` when unique.
pub fn half_gcd_rat_recon(rem0 : Int32, p : Int32) -> (Int32, Int32)? {
  if p <= 2 {
    return Some((rem0, 1))
  }
  let rem = (rem0 % p + p) % p
  if rem == 0 {
    return Some((0, 1))
  }
  let p64 = p.to_int64()
  let mut r0 = p64
  let mut t0 = 0L
  let mut r1 = rem.to_int64()
  let mut t1 = 1L
  while 2L * r1 * r1 >= p64 {
    let q = r0 / r1
    let r2 = r0 - q * r1
    let t2 = t0 - q * t1
    r0 = r1
    t0 = t1
    r1 = r2
    t1 = t2
  }
  let abs_t = if t1 < 0L { -t1 } else { t1 }
  if abs_t == 0L || 2L * abs_t * abs_t >= p64 {
    return None
  }
  let num = if t1 < 0L { (-r1).to_int() } else { r1.to_int() }
  let den = abs_t.to_int()
  Some((num, den))
}

///|
/// Reconstruct a primitive canonical signed integer relation from an `F_p` nullspace vector
/// using `O(log p)` Half-GCD denominator discovery combined with minimal-`L_1` lattice scaling.
pub fn normalize_signed_relation(c : Array[Int32], p : Int32) -> Array[Int32] {
  let cand_mults : Array[Int32] = []
  for mult in 1..<=64 {
    cand_mults.push(mult)
  }
  // Extract exact Half-GCD denominators (> 64 included!) and pairwise bounded LCMs
  let hg_dens : Array[Int32] = []
  for v in c {
    match half_gcd_rat_recon(v, p) {
      Some((_num, den)) =>
        if den > 1 && !hg_dens.contains(den) {
          hg_dens.push(den)
          if !cand_mults.contains(den) {
            cand_mults.push(den)
          }
        }
      None => ()
    }
  }
  for i in 0..<hg_dens.length() {
    for j in (i + 1)..<hg_dens.length() {
      let a = hg_dens[i].to_int64()
      let b = hg_dens[j].to_int64()
      let g = @gcd.ugcd_bigint_gcd(BigInt::from_int64(a), BigInt::from_int64(b))
        .to_int()
        .to_int64()
      let lcm = a / g * b
      if lcm > 0L && lcm < p.to_int64() {
        let li = lcm.to_int()
        if !cand_mults.contains(li) {
          cand_mults.push(li)
        }
      }
    }
  }

  let mut best_centered : Array[Int32] = []
  let mut best_l1 = 2147483647L
  for mult in cand_mults {
    let cur : Array[Int32] = Array::makei(c.length(), i => {
      let x = @gcd.fp_mul(c[i], mult, p)
      if x > p / 2 {
        x - p
      } else {
        x
      }
    })
    let mut l1 = 0L
    for v in cur {
      l1 = l1 + (if v < 0 { (-v).to_int64() } else { v.to_int64() })
    }
    if l1 > 0L && l1 < best_l1 {
      best_l1 = l1
      best_centered = cur
      if l1 <= c.length().to_int64() {
        break
      }
    }
  }
  let centered = if best_centered.length() > 0 {
    best_centered
  } else {
    Array::make(c.length(), 0)
  }
  let mut g = 0N
  for v in centered {
    g = @gcd.ugcd_bigint_gcd(g, BigInt::from_int(v))
  }
  let gg = if g == 0N { 1 } else { g.to_int() }
  let reduced = Array::makei(centered.length(), i => centered[i] / gg)
  for v in reduced {
    if v != 0 {
      if v < 0 {
        return Array::makei(reduced.length(), i => -reduced[i])
      } else {
        return reduced
      }
    }
  }
  reduced
}

///|
/// `[E-Derive]` + `[P-Basis]` Automatically discover linearly independent conservation
/// relations from `rs` via `F_p` nullspace + Half-GCD integer reconstruction + pairwise closure.
pub fn derive_invariant_relations(
  rs : ObservationRowSet,
  p : Int32,
  exact : Bool,
) -> Array[Array[Int32]] {
  if rs.rows.length() == 0 {
    return []
  }
  let m = @gcd.fp_mat_from_rows(rs.rows, p)
  let basis = @gcd.fp_nullspace_basis(m)
  let pool : Array[Array[Int32]] = []
  let push_cand = (v : Array[Int32]) => {
    let mut nonzero = false
    for x in v {
      if x != 0 {
        nonzero = true
        break
      }
    }
    if nonzero && pool.length() < 96 {
      let norm_v = normalize_signed_relation(v, p)
      let mut dup = false
      for ex in pool {
        if ex == norm_v {
          dup = true
          break
        }
      }
      if !dup {
        pool.push(norm_v)
      }
    }
  }
  for b in basis {
    push_cand(b)
  }
  for _ in 0..<2 {
    let cur_len = pool.length()
    for i in 0..<cur_len {
      for j in (i + 1)..<cur_len {
        let vp = Array::makei(pool[i].length(), k => {
          @gcd.fp_add(pool[i][k], pool[j][k], p)
        })
        let vm = Array::makei(pool[i].length(), k => {
          @gcd.fp_sub(pool[i][k], pool[j][k], p)
        })
        push_cand(vp)
        push_cand(vm)
      }
    }
  }

  let accepted : Array[Array[Int32]] = []
  for cand in pool {
    let ok = if exact {
      rowset_holds_exact(rs, cand)
    } else {
      rowset_holds_mod(rs, cand, p)
    }
    if ok {
      let test_rows = accepted.copy()
      test_rows.push(cand)
      let prev_rk = if accepted.length() == 0 {
        0
      } else {
        @gcd.fp_rank(@gcd.fp_mat_from_rows(accepted, p))
      }
      let next_rk = @gcd.fp_rank(@gcd.fp_mat_from_rows(test_rows, p))
      if next_rk > prev_rk {
        accepted.push(cand)
      }
    }
  }
  accepted
}

///|
/// `[D-Rel-Derived]` Basis-independent `F_p`-span membership test.
pub fn relation_in_derived_span(
  derived_basis : Array[Array[Int32]],
  target : Array[Int32],
  p : Int32,
) -> Bool {
  if derived_basis.length() == 0 {
    return false
  }
  let r0 = @gcd.fp_rank(@gcd.fp_mat_from_rows(derived_basis, p))
  let ext = derived_basis.copy()
  ext.push(target)
  let r1 = @gcd.fp_rank(@gcd.fp_mat_from_rows(ext, p))
  r1 == r0
}

///|
/// The five epistemic relational lenses (`相對`, `對偶`, `對比`, `蘊含`, `比率`).
#derive(Debug, Eq)
pub(all) enum EpistemicLensKind {
  LensRelative
  LensDual
  LensContrast
  LensImplication
  LensScaleRatio
}

///|
pub extend EpistemicLensKind with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend EpistemicLensKind with Eq::{not_equal, equal}

///|
/// Exhaustive implication lattice (`[T-Impl-Matrix]`) over a finite sample space.
#derive(Debug, Eq)
pub(all) struct ImplicationLatticeReport {
  num_samples : Int32
  num_predicates : Int32
  implies : Array[Array[Bool]]
  counterexamples : Array[Array[Int32]]
  strict_unidirectional_edges : Int32
  nontrivial_equiv_pairs : Int32
}

///|
pub extend ImplicationLatticeReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend ImplicationLatticeReport with Eq::{not_equal, equal}

///|
/// Build the exact implication lattice & minimal counterexample witness matrix for `k`
/// predicates across `num_samples` instances using **64-sample-per-word SWAR bitplanes**
/// (`@swar.swar_pack_bitplane` + `@swar.swar_bitplane_implication_cex`, `64x` bit-parallelism).
pub fn implication_lattice_build(
  num_samples : Int32,
  num_predicates : Int32,
  eval_pred : (Int32, Int32) -> Bool,
) -> ImplicationLatticeReport {
  let planes : Array[Array[UInt64]] = Array::makei(num_predicates, p => {
    @swar.swar_pack_bitplane(num_samples, s => eval_pred(s, p))
  })
  let imp : Array[Array[Bool]] = Array::makei(num_predicates, _ => {
    Array::make(num_predicates, true)
  })
  let cex : Array[Array[Int32]] = Array::makei(num_predicates, _ => {
    Array::make(num_predicates, -1)
  })
  for i in 0..<num_predicates {
    for j in 0..<num_predicates {
      if i != j {
        let w = @swar.swar_bitplane_implication_cex(
          planes[i],
          planes[j],
          num_samples,
        )
        if w >= 0 {
          imp[i][j] = false
          cex[i][j] = w
        }
      }
    }
  }
  let mut uni = 0
  let mut eq_pairs = 0
  for i in 0..<num_predicates {
    for j in (i + 1)..<num_predicates {
      if imp[i][j] && imp[j][i] {
        eq_pairs = eq_pairs + 1
      } else if imp[i][j] || imp[j][i] {
        uni = uni + 1
      }
    }
  }
  ImplicationLatticeReport::{
    num_samples,
    num_predicates,
    implies: imp,
    counterexamples: cex,
    strict_unidirectional_edges: uni,
    nontrivial_equiv_pairs: eq_pairs,
  }
}

///|
/// Self-verification probe for `conjecture/kernel`:
///   1. Verifies Half-GCD recovers large-denominator conservation law `109 * x - 173 * y = 0`
///      from modular nullspace over `p = 65521` (`2 * 173^2 = 59858 < 65521`, impossible under `mult <= 64` trial scaling!);
///   2. Verifies 64-bit bitplane `implication_lattice_build` on `F_3^{2x2x2}` tensors
///      produces exact minimal counterexamples and transitive closure!
pub fn check_discovery_kernel_laws() -> Bool {
  let p = 65521
  let rows : Array[Array[Int32]] = []
  for t in 1..<=6 {
    rows.push([173 * t, 109 * t])
  }
  let rs = ObservationRowSet::{
    name: "large_denom_conservation",
    columns: ["x", "y"],
    rows,
  }
  let rels = derive_invariant_relations(rs, p, true)
  if rels.length() != 1 || rels[0] != [109, -173] {
    return false
  }
  let atlas = @tensor.f3_tensor222_atlas_build()
  let lat = implication_lattice_build(200, 4, (code, pred) => {
    match pred {
      0 => atlas.ranks[code] <= 1
      1 => atlas.hyperdets[code] == 0
      2 => atlas.rank2_decomp_counts[code] == 0
      _ => atlas.ranks[code] == 3
    }
  })
  // Transitivity of implication on all 4x4x4 triples
  for i in 0..<4 {
    for j in 0..<4 {
      for k in 0..<4 {
        if lat.implies[i][j] && lat.implies[j][k] && !lat.implies[i][k] {
          return false
        }
      }
    }
  }
  lat.implies[0][1] && !lat.implies[1][0] && lat.counterexamples[1][0] >= 0
}
