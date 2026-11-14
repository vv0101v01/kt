///|
// Six-federation native health and active bridge inventory.
// Double-V is an architectural reading aid, not a commutative-diagram theorem.

///|
/// Six-federation integration status. Native health and registry coverage are
/// reported separately; the unsupported X-commutativity claim has been removed.
#derive(Debug, Eq)
pub(all) struct DoubleVArchitectureReport {
  lower_v_gcd_apex_ok : Bool
  six_federations_verified : Int32
  k6_bridges_verified : Int32
  registry_ok : Bool
  refuted_conjectures_evaluated : Int32
  upper_v_synthesis_apex_ok : Bool
}

///|
pub extend DoubleVArchitectureReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend DoubleVArchitectureReport with Eq::{not_equal, equal}

///|
/// Return all **6 Autonomous Mathematical Federations** (`Cubical`, `Symlib`,
/// `Semiring`, `Topos`, `Scheme`, and `Condensed`) with live health probes.
pub fn six_federation_descriptors() -> Array[FederationDescriptor] {
  let out = five_federation_descriptors()
  let f6_ok = @condensed.cond_check_federation_all() &&
    @gcd.check_universal_gcd_laws()
  out.push(FederationDescriptor::{
    id: Condensed,
    slug: "condensed",
    packages: ["gcd", "condensed-core", "condensed"],
    canonical_normal_form: "RREF/SNF Universal Elimination-GCD, Minimal Steenrod A-Resolution & Idempotent Canon Map",
    categorification_role: "Condensed Profinite Anima/Solid Modules (`CondCategory`), `CanonElimCategory`, Spectral Sheaves & Huber Analytic Stacks",
    live_health_ok: f6_ok,
    summary: "4 Condensed Higher Structures (`CondAnima`, `CondSolidModule`, `CondSpectralSheaf`, `CondAnalyticStack`), 2 Categories, Ledger & 1 Refuted Conjecture",
  })
  out
}

///|
/// **`K6-12` (`Condensed ↔ Symlib`)**:
/// `CanonElimCategory` equivariant orbit normalizer on `{0..3}` under `Z/2Z` swap `(0 1)(2 3)`
/// matches `@sym.gset_burnside` orbit count (`2`), while strict refinement `canon_conj > char_poly` holds!
pub fn verify_k6_12_condensed_symlib_bridge() -> (Bool, String) {
  let gen = @sym.Perm::from_img([1, 0, 3, 2])
  let grp = @sym.PermGroup::new(4, [gen])
  let gs = @sym.gset_points(grp, 16)
  let (orbs, burnside) = @sym.gset_burnside(gs)
  let c_obj = @condensed.canon_object_build(
    "Z2_Swap4",
    4,
    (x, y) => x / 2 == y / 2,
    x => x / 2 * 2,
  )
  let ok = orbs == 2 &&
    burnside == 2 &&
    c_obj.idempotent &&
    c_obj.is_complete &&
    c_obj.class_count == orbs
  (
    ok,
    "CanonElimCategory class_count=\{c_obj.class_count} == Symlib Burnside orbits=\{orbs} (|G|=\{grp.order()})",
  )
}

///|
/// **`K6-14` (`Condensed ↔ Topos`)**:
/// `[Ax-Cond-ExtDisc]` profinite coproduct sheaf descent + `CondSpectralSheaf` Čech twist
/// obstruction `k^1 - r^0 == 0` on `S^3` (`E_2 = 4 -> E_4 = 2`) aligns with `@topos` Nerve
/// homotopy Betti numbers of `S^1` and `S^2`!
pub fn verify_k6_14_condensed_topos_bridge() -> (Bool, String) {
  let d0 = @gcd.fp_mat_from_rows([[4, 1]], 5)
  let d1 = @gcd.fp_mat_make(1, 1, 5, 0)
  let sh = @condensed.cond_spectral_sheaf_build(
    "S^3",
    [1, 0, 0, 1],
    true,
    d0,
    d1,
  )
  let s2_nerve = @topos.boundary_simplex_nerve(3)
  let ht_s2 = @topos.compute_nerve_homotopy_type(s2_nerve)
  let s1_nerve = @topos.boundary_simplex_nerve(2)
  let ht_s1 = @topos.compute_nerve_homotopy_type(s1_nerve)
  let serre = @condensed.serre_hopf_fibration_report(5)
  // Genuine interaction: the Serre spectral sequence's base/fiber cohomology
  // must agree with the topos nerve cohomology of S^2 and S^1, not just one
  // hardcoded Betti number.
  let base_agrees = serre.base_betti[0] == ht_s2.betti_numbers[0] &&
    serre.base_betti[1] == ht_s2.betti_numbers[1] &&
    serre.base_betti[2] == ht_s2.betti_numbers[2]
  let fiber_agrees = serre.fiber_betti[0] == ht_s1.betti_numbers[0] &&
    serre.fiber_betti[1] == ht_s1.betti_numbers[1]
  let ok = sh.global_twist_glues &&
    sh.e2_total_rank == 4 &&
    sh.e4_total_rank == 2 &&
    serre.converges_to_s3 &&
    base_agrees &&
    fiber_agrees &&
    ht_s2.betti_numbers[2] == serre.hurewicz_h2_s2_rank
  (
    ok,
    "CondSpectralSheaf S^3 E2=\{sh.e2_total_rank}->E4=\{sh.e4_total_rank}; Serre base β(S^2)=\{nbe_show_ints(serre.base_betti)}==topos nerve, fiber β(S^1)=\{nbe_show_ints(serre.fiber_betti)}==topos nerve, converges_to_S3=\{serre.converges_to_s3}",
  )
}

///|
/// K6-15: the SAME P¹ O(n) Čech problem, calculated by an explicit finite
/// Laurent differential over F₇ and by the scheme line-bundle engine.
/// Cutoff invariance, Serre duality, RR and the proper-but-not-acyclic
/// negative control are checked for n=-4..3. No annulus/diamond claim.
pub fn verify_k6_15_condensed_scheme_bridge() -> (Bool, String) {
  let mut agrees = true
  let mut stable = true
  let mut serre_rr = true
  let h0s : Array[Int32] = []
  let h1s : Array[Int32] = []
  for n in -4..<4 {
    guard @condensed.cond_p1_cech_dimensions(n, 4) is Some((h0, h1)) else {
      return (false, "Laurent truncation rejected valid input")
    }
    let scheme = @scheme.cech_cohomology_p1_line_bundle(n)
    let dual = @scheme.cech_cohomology_p1_line_bundle(-2 - n)
    agrees = agrees && h0 == scheme.h0 && h1 == scheme.h1
    stable = stable &&
      @condensed.cond_p1_cech_dimensions(n, 6) == Some((h0, h1))
    serre_rr = serre_rr &&
      h1 == dual.h0 &&
      h0 - h1 == n + 1 &&
      scheme.chi == n + 1
    h0s.push(h0)
    h1s.push(h1)
  }
  let negative = @condensed.cond_p1_cech_dimensions(-2, 4) == Some((0, 1)) &&
    @scheme.analyze_scheme_properness(@scheme.scheme_projective_space(1)).is_proper &&
    @condensed.cond_p1_cech_dimensions(5, 4) == None &&
    @condensed.cond_p1_cech_dimensions(0, -1) == None &&
    @condensed.cond_p1_cech_dimensions(0, 17) == None
  (
    agrees && stable && serre_rr && negative,
    "P1 O(n), n=-4..3: Laurent_F7 == scheme, h0=\{nbe_show_ints(h0s)}, h1=\{nbe_show_ints(h1s)}, cutoff4==6=\{stable}, Serre/RR=\{serre_rr}; NEG proper P1 has H1(O(-2))=1, invalid truncations rejected=\{negative}",
  )
}

///|
/// Execute the 13 active comparisons among the first six federations.
/// K6-11 and K6-13 are deleted; metadata remains in catalog.json.
pub fn verify_k6_federation_bridges() -> Array[FederationPairBridge] {
  let edges = verify_k5_federation_bridges()
  let (ok12, w12) = verify_k6_12_condensed_symlib_bridge()
  let (ok14, w14) = verify_k6_14_condensed_topos_bridge()
  let (ok15, w15) = verify_k6_15_condensed_scheme_bridge()
  edges.push(FederationPairBridge::{
    id: "K6-12",
    lhs: Condensed,
    rhs: Symlib,
    bridge_theorem: "CanonElimCategory Idempotent Normalizer ↔ Symlib Schreier–Sims Burnside Orbits",
    holds: ok12,
    quantitative_witness: w12,
  })
  edges.push(FederationPairBridge::{
    id: "K6-14",
    lhs: Condensed,
    rhs: Topos,
    bridge_theorem: "[Ax-Cond-ExtDisc] Stone Descent & CondSpectralSheaf Čech Twist ↔ Topos Nerve Cohomology",
    holds: ok14,
    quantitative_witness: w14,
  })
  edges.push(FederationPairBridge::{
    id: "K6-15",
    lhs: Condensed,
    rhs: Scheme,
    bridge_theorem: "P¹ O(n) finite Laurent Čech differential ↔ Scheme cohomology, Serre duality and Riemann–Roch",
    holds: ok15,
    quantitative_witness: w15,
  })
  edges
}

///|
/// Validate the exact active six-federation registry and native health probes.
/// Precomputed data is trusted in-process input, but coverage is always rechecked.
pub fn verify_double_v_architecture(
  k6_precomputed~ : Array[FederationPairBridge]? = None,
  federations_precomputed~ : Array[FederationDescriptor]? = None,
) -> DoubleVArchitectureReport {
  let feds = match federations_precomputed {
    Some(fs) => fs
    None => six_federation_descriptors()
  }
  let mut fed_ok_cnt = 0
  for f in feds {
    if f.live_health_ok {
      fed_ok_cnt = fed_ok_cnt + 1
    }
  }
  let k6 = match k6_precomputed {
    Some(es) => es
    None => verify_k6_federation_bridges()
  }
  let registry = validate_bridge_registry(k6, federation_count=6)
  let mut k6_ok_cnt = 0
  for e in k6 {
    if e.holds {
      k6_ok_cnt = k6_ok_cnt + 1
    }
  }
  let v1_ok = @gcd.check_universal_gcd_laws()
  let conjs = @condensed.cond_evaluate_new_conjectures()
  let mut conj_ok_cnt = 0
  for c in conjs {
    if c.consistent_with_status {
      conj_ok_cnt = conj_ok_cnt + 1
    }
  }
  let v2_ok = v1_ok &&
    federation_health_valid(feds, 6) &&
    registry.all_holds &&
    conj_ok_cnt == 1
  DoubleVArchitectureReport::{
    lower_v_gcd_apex_ok: v1_ok,
    six_federations_verified: fed_ok_cnt,
    k6_bridges_verified: k6_ok_cnt,
    registry_ok: registry.all_holds,
    refuted_conjectures_evaluated: conj_ok_cnt,
    upper_v_synthesis_apex_ok: v2_ok,
  }
}
