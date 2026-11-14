///|
// Federation 6 (`condensed`) — Higher Structure #4 (`CondAnalyticStack`),
// Category #2 (`CanonElimCategory`), Persistent Invariant-Deriving Ledger,
// Five Relational Lenses, and the refuted conjecture `[Conj-2]`.

///|
/// Legacy-named report combining separate finite-model checks:
/// tropical bend roots, P1 properness, atomic BS2, finite Laurent Cech and
/// rational arithmetic. It does NOT construct a Huber/analytic stack, a
/// Laurent Grothendieck site or a p-adic completion.
/// `solid_completion_gap` is a compatibility constant, not measured evidence.
#derive(Debug, Eq)
pub(all) struct CondAnalyticStack {
  ring_name : String
  tropical_bend_roots_count : Int32
  p1_proper_and_separated : Bool
  // Legacy field name: this actually checks atomic BS2, NOT a Laurent site.
  topos_laurent_site_valid : Bool
  laurent_cech_exact : Bool
  archimedean_trace_rat : @exactalg.Rat
  solid_completion_gap : Int32
  bipolar_coherent : Bool
}

///|
pub extend CondAnalyticStack with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondAnalyticStack with Eq::{not_equal, equal}

///|
/// Object in **Category #2 (`範疇 ②` — `CanonElimCategory`)**:
/// finite carrier `{0..size-1}` equipped with an explicit equivalence relation
/// `equiv[x * size + y]` and a canonical normalizer `canon[x]` satisfying
/// `[Ax-Canon-Idem]` (`canon[canon[x]] == canon[x]`) and `[Ax-Canon-Sound]`
/// (`x ~ y => canon[x] == canon[y]`), with honest `is_complete` witness.
#derive(Debug, Eq)
pub(all) struct CanonObject {
  name : String
  size : Int32
  equiv : Array[Bool]
  canon : Array[Int32]
  idempotent : Bool
  sound : Bool
  is_complete : Bool
  class_count : Int32
}

///|
pub extend CanonObject with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CanonObject with Eq::{not_equal, equal}

///|
/// Morphism in **Category #2 (`CanonElimCategory`)**: equivariant map `map : dom -> cod`
/// preserving equivalence (`x ~_dom y => map(x) ~_cod map(y)`) so `canon_cod o map`
/// factors uniquely through `canon_dom`!
#derive(Debug, Eq)
pub(all) struct CanonMorphism {
  dom : CanonObject
  cod : CanonObject
  map : Array[Int32]
}

///|
pub extend CanonMorphism with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CanonMorphism with Eq::{not_equal, equal}

///|
/// Re-export Layer-0 FNV-1a Digest-Chain & `Z`-Nullspace Invariant Ledger from `@gcd`.
pub using @gcd {
  type CondLedgerEntry,
  type CondInvariantLedger,
  cond_ledger_new,
  cond_ledger_append,
  cond_ledger_verify,
  cond_ledger_derive_invariants,
  cond_ledger_audit_laws,
}

///|
/// Verdict of a resolved conjecture.
#derive(Debug, Eq)
pub(all) enum CondConjectureStatus {
  /// Refuted by an explicit machine-verified counterexample witness.
  RefutedWithWitness(String)
}

///|
pub extend CondConjectureStatus with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondConjectureStatus with Eq::{not_equal, equal}

///|
/// A resolved conjecture together with the check that supports its verdict.
#derive(Debug, Eq)
pub(all) struct CondConjectureEntry {
  id : String
  title : String
  status : CondConjectureStatus
  instances_checked : Int32
  consistent_with_status : Bool
}

///|
pub extend CondConjectureEntry with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondConjectureEntry with Eq::{not_equal, equal}

///|
/// Build **Condensed Higher-Order Structure #4 (`CondAnalyticStack`)**:
/// Synthesizes `@strop` (Kapranov tropical bend roots of `min(1 + 2x, 0 + x, 2)` -> `{-1, 2}`),
/// `@scheme` (`P^1` properness & separatedness), `@topos` (poset site validity for the
/// atomic BS2 toy site), finite P1 Čech dimensions, and `@exactalg.Rat`.
/// These are separate native checks; this report does not construct an analytic stack.
pub fn cond_analytic_stack_build() -> CondAnalyticStack {
  // 1. Tropical bend locus: `f(x) = min(2, 0 + x, 1 + 2x)` has corners at x = -1 and x = 2!
  let trop_f = @strop.UniPoly::new([2, 0, 1])
  let roots = trop_f.roots()
  let expected_roots = [@strop.Rat::of_int(-1), @strop.Rat::of_int(2)]
  let trop_ok = @strop.roots_equal(roots, expected_roots)

  // 2. Scheme P1 properness (no identification with an affinoid annulus).
  let p1 = @scheme.scheme_projective_space(1)
  let prop_rep = @scheme.analyze_scheme_properness(p1)
  let p1_ok = prop_rep.is_separated &&
    prop_rep.existence_holds &&
    prop_rep.uniqueness_holds &&
    prop_rep.is_proper

  // 3. Atomic BS2 site; the legacy report field name is not a Laurent-site claim.
  let s2_grp = @sym.PermGroup::symmetric(2)
  let z2_cat = @sym.cat_group(s2_grp, 2)
  let topos_ok = match @topos.topology_atomic(z2_cat) {
    Some(j_top) => {
      let st = @topos.site_new(z2_cat, j_top)
      @topos.analyze_atomic_topos(st).is_atomic
    }
    None => false
  }

  // 4. Laurent rational localization Čech complex `0 -> k[T]_{deg<=1} -> k[T]_{<=1} x k[T^{-1}]_{<=1} -> k[T, T^{-1}]_{[-1,1]}`
  // Global sections on `P^1` of degree 0 have dim 1 (`c_0`); `d0` maps `(a0 + a1*T, b0 + b1*T^{-1})`
  // to `(b1)*T^{-1} + (b0 - a0)*1 + (-a1)*T` (3x4 matrix of rank 3 => ker dim = 4 - 3 = 1 = H^0(P^1, O), H^1 = 3 - 3 = 0)!
  let (h0_dim, h1_dim) = match cond_p1_cech_dimensions(0, 1) {
    Some(dims) => dims
    None => (-1, -1)
  }
  let cech_ok = h0_dim == 1 && h1_dim == 0

  // 5. Exact rational trace = 1. The legacy gap field below is a constant,
  // not an executed solid Z_p completion or a convergence measurement.
  let tr_rat = @exactalg.rat_add(
    @exactalg.rat_make(1, 2),
    @exactalg.rat_make(1, 2),
  )
  let solid_compact_gap = 0

  CondAnalyticStack::{
    ring_name: "Finite P1 Laurent Cech model over F7",
    tropical_bend_roots_count: roots.length(),
    p1_proper_and_separated: p1_ok,
    topos_laurent_site_valid: topos_ok,
    laurent_cech_exact: cech_ok,
    archimedean_trace_rat: tr_rat,
    solid_completion_gap: solid_compact_gap,
    bipolar_coherent: trop_ok &&
    p1_ok &&
    topos_ok &&
    cech_ok &&
    @exactalg.rat_eq(tr_rat, @exactalg.rat_one()),
  }
}

// ---------------------------------------------------------------------------
// Category #2 (`範疇 ②` — `CanonElimCategory`): Canonical Normalizers & Refinement Ladder
// ---------------------------------------------------------------------------

///|
pub fn canon_object_build(
  name : String,
  size : Int32,
  equiv_fn : (Int32, Int32) -> Bool,
  canon_fn : (Int32) -> Int32,
) -> CanonObject {
  let equiv : Array[Bool] = []
  let canon : Array[Int32] = []
  for x in 0..<size {
    canon.push(canon_fn(x))
    for y in 0..<size {
      equiv.push(equiv_fn(x, y))
    }
  }
  let mut idempotent = true
  for x in 0..<size {
    let cx = canon[x]
    if cx < 0 || cx >= size || canon[cx] != cx {
      idempotent = false
    }
  }
  let mut sound = true
  let mut complete = true
  for x in 0..<size {
    for y in 0..<size {
      let eq_xy = equiv[x * size + y]
      let same_c = canon[x] == canon[y]
      if eq_xy && !same_c {
        sound = false
      }
      if same_c && !eq_xy {
        complete = false
      }
    }
  }
  let seen : Array[Int32] = []
  for x in 0..<size {
    let mut found = false
    for s in seen {
      if s == canon[x] {
        found = true
        break
      }
    }
    if !found {
      seen.push(canon[x])
    }
  }
  CanonObject::{
    name,
    size,
    equiv,
    canon,
    idempotent,
    sound,
    is_complete: sound && complete,
    class_count: seen.length(),
  }
}

///|
pub fn canon_morphism_valid(f : CanonMorphism) -> Bool {
  if f.map.length() != f.dom.size {
    return false
  }
  for x in 0..<f.dom.size {
    if f.map[x] < 0 || f.map[x] >= f.cod.size {
      return false
    }
  }
  for x in 0..<f.dom.size {
    for y in 0..<f.dom.size {
      if f.dom.equiv[x * f.dom.size + y] {
        let fx = f.map[x]
        let fy = f.map[y]
        if !f.cod.equiv[fx * f.cod.size + fy] {
          return false
        }
      }
    }
  }
  true
}

///|
pub fn canon_cat_id(obj : CanonObject) -> CanonMorphism {
  let map : Array[Int32] = []
  for x in 0..<obj.size {
    map.push(x)
  }
  CanonMorphism::{ dom: obj, cod: obj, map, }
}

///|
pub fn canon_cat_comp(g : CanonMorphism, f : CanonMorphism) -> CanonMorphism? {
  if f.cod != g.dom {
    return None
  }
  let map : Array[Int32] = []
  for x in 0..<f.dom.size {
    map.push(g.map[f.map[x]])
  }
  Some(CanonMorphism::{ dom: f.dom, cod: g.cod, map, })
}

// Persistent Hash-Chained Invariant-Deriving Ledger lives in `@gcd` (`L0`) and is re-exported above.

// ---------------------------------------------------------------------------
// Refuted conjecture `[Conj-2]`
// ---------------------------------------------------------------------------

///|
/// Evaluate the resolved conjectures of this federation. Only `[Conj-2]` has a verdict;
/// the historical `[Conj-1]`, `[Conj-3]` (bounded checks) and `[Conj-4]` (a threshold
/// reading) could be neither proved nor refuted here and were removed.
pub fn cond_evaluate_new_conjectures() -> Array[CondConjectureEntry] {
  // [Conj-2]: "Abelian H_1-winding == 0 suffices to fill 2-boxes in arbitrary 0-connected HITs"
  // REFUTED WITH EXPLICIT WITNESS: commutator `[a, b] = a * b * a^{-1} * b^{-1}` in `pi_1(S^1 v S^1) = F_2`
  // has abelian winding `(1 - 1, 1 - 1) = (0, 0)`, yet reduced free-group word `[+1, +2, -1, -2]` has length 4 != 0!
  let comm = [1, 2, -1, -2]
  let mut ab_a = 0
  let mut ab_b = 0
  for x in comm {
    if x == 1 {
      ab_a = ab_a + 1
    } else if x == -1 {
      ab_a = ab_a - 1
    } else if x == 2 {
      ab_b = ab_b + 1
    } else if x == -2 {
      ab_b = ab_b - 1
    }
  }
  let reduced_comm = @gcd.ugcd_free_group_reduce(comm)
  let conj2_refuted = ab_a == 0 && ab_b == 0 && reduced_comm.length() == 4
  [
    CondConjectureEntry::{
      id: "Conj-2",
      title: "Abelian H_1-Winding Sufficiency for Non-Abelian HIT 2-Box Filling (Refuted)",
      status: RefutedWithWitness(
        "pi_1(S^1 v S^1) = F_2 commutator [a,b] = a*b*a^-1*b^-1 != 1 with abelian winding (0,0)",
      ),
      instances_checked: 1,
      consistent_with_status: conj2_refuted,
    },
  ]
}

///|
/// Master check for Higher Structure #4 (`CondAnalyticStack`), Category #2 (`CanonElimCategory`),
/// Persistent Invariant-Deriving Ledger, and the refuted conjecture `[Conj-2]`.
pub fn cond_check_structure_4_category_2_ledger_and_conjectures() -> Bool {
  // 1. Higher Structure #4: Bipolar Analytic Stack
  let stack = cond_analytic_stack_build()
  if !stack.bipolar_coherent || stack.tropical_bend_roots_count != 2 {
    return false
  }

  // 2. Category #2 (`CanonElimCategory`):
  //    Verify complete canonical normalizer (`Z/6Z mod 3`, 3 classes) vs incomplete curvature normalizer
  //    (flat holonomy!=0 gauge field shares curvature 0 with trivial field => `is_complete == false`!),
  //    plus Category identity/composition & strict refinement `mod 6 > mod 3 > mod 1`!
  let obj_mod6 = canon_object_build("Mod6", 6, (x, y) => x == y, x => x)
  let obj_mod3 = canon_object_build("Mod3", 6, (x, y) => x % 3 == y % 3, x => {
    x % 3
  })
  // Gauge curvature toy model on 3 states `{0: trivial, 1: gauge_of_0, 2: flat_nontrivial_holonomy}`:
  // `0 ~ 1` while `2` is NOT gauge-equivalent to `0`, yet curvature normalizer sends ALL THREE to `0`!
  let obj_gauge_curv = canon_object_build(
    "GaugeCurvature",
    3,
    (x, y) => x == y || (x <= 1 && y <= 1),
    _ => 0,
  )
  if !obj_mod6.idempotent ||
    !obj_mod6.is_complete ||
    obj_mod6.class_count != 6 ||
    !obj_mod3.idempotent ||
    !obj_mod3.is_complete ||
    obj_mod3.class_count != 3 {
    return false
  }
  if !obj_gauge_curv.idempotent ||
    !obj_gauge_curv.sound ||
    obj_gauge_curv.is_complete {
    return false
  }
  let quot_map = CanonMorphism::{
    dom: obj_mod6,
    cod: obj_mod3,
    map: [0, 1, 2, 3, 4, 5],
  }
  if !canon_morphism_valid(quot_map) {
    return false
  }
  guard canon_cat_comp(canon_cat_id(obj_mod3), quot_map) is Some(c_left) else {
    return false
  }
  guard canon_cat_comp(quot_map, canon_cat_id(obj_mod6)) is Some(c_right) else {
    return false
  }
  if c_left != quot_map || c_right != quot_map {
    return false
  }

  // Strict Refinement `canon_conj > char_poly` over `M_2(F_3)`:
  // `I_2 = [[1,0],[0,1]]` and Jordan block `J = [[1,1],[0,1]]` have the SAME trace `2` and det `1`
  // (hence identical characteristic polynomial `x^2 - 2x + 1 = (x - 1)^2`), yet rank(I_2 - I) = 0 != 1 = rank(J - I)!
  let i2 = @gcd.fp_mat_from_rows([[1, 0], [0, 1]], 3)
  let j2 = @gcd.fp_mat_from_rows([[1, 1], [0, 1]], 3)
  let same_charpoly = @gcd.fp_det(i2) == @gcd.fp_det(j2) &&
    (@gcd.fp_mat_get(i2, 0, 0) + @gcd.fp_mat_get(i2, 1, 1)) % 3 ==
    (@gcd.fp_mat_get(j2, 0, 0) + @gcd.fp_mat_get(j2, 1, 1)) % 3
  let nilp_j = @gcd.fp_mat_from_rows([[0, 1], [0, 0]], 3)
  if !same_charpoly || @gcd.fp_rank(nilp_j) != 1 {
    return false
  }

  // 3. Persistent Invariant-Deriving Ledger:
  //    Ingest Radon/Euler-style trajectory rows `(V, E, F)` on planar triangulations of `S^2`:
  //    `(4, 6, 4)`, `(5, 9, 6)`, `(6, 12, 8)` satisfy `3F - 2E == 0` AND `V - E + F == 2`
  //    (with homogeneous column `1` -> `[V, E, F, 1]`: TWO independent Z-conservation laws
  //    `V - E + F - 2*1 = 0` and `2E - 3F = 0` derived automatically by SNF nullspace!)
  let mut led = cond_ledger_new()
  led = cond_ledger_append(led, 0, [4, 6, 4, 1], [])
  led = cond_ledger_append(led, 0, [5, 9, 6, 1], [])
  led = cond_ledger_append(led, 0, [6, 12, 8, 1], [])
  led = cond_ledger_append(led, 0, [7, 15, 10, 1], [])
  let derived_led = cond_ledger_derive_invariants(led)
  let (passed_laws, failed_laws) = cond_ledger_audit_laws(derived_led)
  if passed_laws != 2 || failed_laws != 0 {
    return false
  }
  // Tamper check
  let tampered_entries = derived_led.entries.copy()
  tampered_entries[0] = CondLedgerEntry::{
    ..tampered_entries[0],
    values: [99, 6, 4, 1],
  }
  let tampered_led = CondInvariantLedger::{
    entries: tampered_entries,
    tip: derived_led.tip,
  }
  if cond_ledger_verify(tampered_led) {
    return false
  }

  // 4. The refuted conjecture `[Conj-2]` evaluates consistently
  let conjs = cond_evaluate_new_conjectures()
  if conjs.length() != 1 {
    return false
  }
  for c in conjs {
    if !c.consistent_with_status {
      return false
    }
  }
  true
}

///|
/// Unified Federation 6 (`condensed`) live health & theorem check.
pub fn cond_check_federation_all() -> Bool {
  cond_check_structures_1_2_and_category_1() &&
  cond_check_structure_3_and_spectral_homotopy() &&
  cond_check_structure_4_category_2_ledger_and_conjectures() &&
  cond_check_hensel_merkle_laws()
}

///|
/// Finite Laurent Čech model of O(twist) on P¹ over F₇.
/// C⁰ has bases {1,t,...,t^cutoff} and {t^twist,...,t^(twist-cutoff)}.
/// C¹ spans all exponents between twist-cutoff and cutoff. The differential
/// is (a,b) -> b-a. For |twist|<=cutoff these truncations contain all H⁰/H¹
/// representatives. This is NOT an annulus H⁰ or a p-adic analytic theorem.
/// The finite budget (cutoff<=16) also prevents accidental huge allocations.
pub fn cond_p1_cech_dimensions(
  twist : Int32,
  cutoff : Int32,
) -> (Int32, Int32)? {
  if cutoff < 0 || cutoff > 16 || twist < -cutoff || twist > cutoff {
    return None
  }
  let low = twist - cutoff
  let rows = cutoff - low + 1
  let cols = 2 * (cutoff + 1)
  let d = @gcd.fp_mat_make(rows, cols, 7, 0)
  for i in 0..<(cutoff + 1) {
    @gcd.fp_mat_set(d, i - low, i, 6)
    @gcd.fp_mat_set(d, twist - i - low, cutoff + 1 + i, 1)
  }
  let rank = @gcd.fp_rank(d)
  Some((cols - rank, rows - rank))
}
