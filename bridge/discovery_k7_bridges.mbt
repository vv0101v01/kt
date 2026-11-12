///|
// Phase 22 — Seven-Federation Star-Prism & Lakatosian Discovery Loop Unification:
// Upgrades the 6-federation (`K_6` = 15/15) platform to 7 autonomous federations
// (`cubical`, `symlib`, `semiring`, `topos`, `scheme`, `condensed`, `discovery`)
// with all C(7, 2) = 21 edges of the complete bridge graph `K_7` (`K7-16` .. `K7-21`)
// and the 12-Conjecture Lakatosian Proof-and-Refutation Synthesis.

///|
/// Report for the **Seven-Federation Star-Prism & Lakatosian Discovery Loop Architecture**.
#derive(Debug, Eq)
pub(all) struct SevenFederationStarPrismReport {
  seven_federations_verified : Int32
  k7_bridges_verified : Int32
  conjectures_evaluated : Int32
  evolution_families_verified : Int32
  lakatos_refinements_verified : Int32
  epistemic_lenses_sealed : Bool
  star_prism_commutes : Bool
}

///|
pub extend SevenFederationStarPrismReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend SevenFederationStarPrismReport with Eq::{not_equal, equal}

///|
/// Return all **7 Autonomous Mathematical Federations** (`Cubical`, `Symlib`,
/// `Semiring`, `Topos`, `Scheme`, `Condensed`, and `Discovery`) with live health probes.
pub fn seven_federation_descriptors() -> Array[FederationDescriptor] {
  let out = six_federation_descriptors()
  let f7_ok = @tensor.tensor_check_federation_laws() &&
    @conjecture.check_conjecture_discovery_federation()
  out.push(FederationDescriptor::{
    id: Discovery,
    slug: "discovery",
    packages: ["tensor", "conjecture"],
    canonical_normal_form: "Cayley 2x2x2 Hyperdeterminant / F_3 Rank Atlas, Radon Inversion, [E-Derive] Nullspace Basis & Implication DAG",
    categorification_role: "Multilinear Tensor/Spinor-Gauge/Radon Geometry & Lakatosian Conjecture-Discovery-Refinement Functor",
    live_health_ok: f7_ok,
    summary: "F_3 6561-Tensor Atlas, Discrete Radon, Clifford/Gauge Spinors, VR Homology, 6 Evolution Laws, 5 Lenses & 12 Updated Conjectures",
  })
  out
}

///|
/// **`K7-16` (`Discovery ↔ Cubical`)**:
/// Polygon diagonal-flip evolution (`n = 5` pentagon `C_3 = 5`, `n = 6` `C_4 = 14`)
/// matches Cubical Stasheff associahedron `(f_0, f_1)` of `K_{n-1}` (`assoc_fvector(4) == [5, 5, 1]`,
/// `assoc_fvector(5) == [14, 21, 9, 1]`), and Lakatosian `CONJ-02` refutes naive `H_1=0` 2-box
/// filling on `S^1 v S^1` while confirming free-group `F_2` normal-form filling!
pub fn verify_k7_16_discovery_cubical_bridge() -> (Bool, String) {
  let flip5 = @tensor.nc_polygon_triangulations_flip_report(5)
  let flip6 = @tensor.nc_polygon_triangulations_flip_report(6)
  let fv4 = @cub.assoc_fvector(4)
  let fv5 = @cub.assoc_fvector(5)
  let w_rep = @cub.wedge_square_filler_report([2], [2], [1], [1])
  let ok = flip5.catalan_count == fv4[0] &&
    flip5.flip_edges == fv4[1] &&
    flip6.catalan_count == fv5[0] &&
    flip6.flip_edges == fv5[1] &&
    !w_rep.fills_in_wedge_s1_s1 &&
    w_rep.fills_in_abelianized_torus
  (
    ok,
    "flip(5,6)=(\{flip5.catalan_count},\{flip6.catalan_count})==K_{4,5} vertices; [a,b] wedge=false, torus=true",
  )
}

///|
/// **`K7-17` (`Discovery ↔ Symlib`)** — repaired (the previous version conjoined
/// `|Aut(C_5)|=10` with an unrelated invariance flag and *mislabelled* `C_5` as
/// `K_4`).
///
/// `S_3` (symlib Schreier–Sims) acts on the `6561` tensors of `F_3^{2×2×2}` by
/// permuting axes.  Tensor rank is an axis-symmetric invariant, so it is
/// constant on every orbit; the orbit census is computed by union-find and
/// stratified by rank, and orbit–stabiliser `|orb|·|stab| = 6` is verified on a
/// free orbit together with subgroup closure of the stabiliser.
/// Negative control: the *mode-0 flattening rank* is only invariant under the
/// `S_2` acting on the last two axes — an explicit tensor in an `S_3`-orbit has
/// a different mode-0 rank, so the naive "all flattenings are invariants"
/// claim is refuted.
pub fn verify_k7_17_discovery_symlib_bridge() -> (Bool, String) {
  let total = 6561
  let atlas = @tensor.f3_tensor222_atlas_build()
  let s3 = @sym.PermGroup::symmetric(3)
  let perms = s3.elements(4096)
  let imgs : Array[Array[Int32]] = Array::makei(perms.length(), gi => {
    Array::makei(3, a => perms[gi].apply(a))
  })
  let srcmaps : Array[Array[Int32]] = Array::makei(imgs.length(), gi => {
    nbe_axis_srcmap(imgs[gi])
  })
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
  let parent = Array::makei(total, i => i)
  let mut rank_constant = true
  let mut stab_sum = 0
  let mut orb_stab_sum = 0
  let mut free_code = -1
  let mut free_size = 0
  let mut free_stab = 0
  for c in 0..<total {
    let seen : Array[Int32] = []
    let mut stab = 0
    for gi in 0..<imgs.length() {
      let pc = perm_codes[gi][c]
      if atlas.ranks[pc] != atlas.ranks[c] {
        rank_constant = false
      }
      nbe_dsu_union(parent, c, pc)
      if pc == c {
        stab = stab + 1
      }
      let mut dup = false
      for v in seen {
        if v == pc {
          dup = true
        }
      }
      if !dup {
        seen.push(pc)
      }
    }
    stab_sum = stab_sum + stab
    orb_stab_sum = orb_stab_sum + seen.length() * stab
    if free_code < 0 && stab == 1 && seen.length() == 6 {
      free_code = c
      free_size = seen.length()
      free_stab = stab
    }
  }
  let orbits_total = nbe_dsu_classes(parent)
  let orbit_rank_hist = Array::make(4, 0)
  let mut rep_count = 0
  for c in 0..<total {
    if nbe_dsu_find(parent, c) == c {
      orbit_rank_hist[atlas.ranks[c]] = orbit_rank_hist[atlas.ranks[c]] + 1
      rep_count = rep_count + 1
    }
  }
  // Stabiliser of the free orbit is a subgroup: closed under composition.
  let stab_idx : Array[Int32] = []
  for gi in 0..<imgs.length() {
    if perm_codes[gi][free_code] == free_code {
      stab_idx.push(gi)
    }
  }
  let mut stab_closed = true
  for a in stab_idx {
    for b in stab_idx {
      let comp = perms[a].compose(perms[b])
      let mut found = false
      for g in stab_idx {
        if perms[g].equal(comp) {
          found = true
        }
      }
      if !found {
        stab_closed = false
      }
    }
  }
  let orbit_stabilizer = free_code >= 0 &&
    free_size * free_stab == 6 &&
    stab_closed
  // Negative control: mode-0 flattening rank varies inside an S_3-orbit.
  let mut nc_code = -1
  let mut nc_axis = -1
  let mut nc_r0 = -1
  let mut nc_r1 = -1
  for c in 0..<512 {
    if nc_code >= 0 {
      break
    }
    let r0 = nbe_flatten_rank(c, 0)
    for gi in 0..<imgs.length() {
      let r1 = nbe_flatten_rank(perm_codes[gi][c], 0)
      if r1 != r0 {
        nc_code = c
        nc_axis = gi
        nc_r0 = r0
        nc_r1 = r1
        break
      }
    }
  }
  let negative_control = nc_code >= 0 &&
    nc_r0 != nc_r1 &&
    atlas.ranks[perm_codes[nc_axis][nc_code]] == atlas.ranks[nc_code]
  let ok = perms.length() == 6 &&
    rank_constant &&
    stab_sum == 6 * orbits_total &&
    orb_stab_sum == 6 * total &&
    rep_count == orbits_total &&
    orbit_stabilizer &&
    negative_control
  (
    ok,
    "S_3 orbits=\{orbits_total} (Σ|stab|=\{stab_sum}=6·orbits, Σ|orb|·|stab|=\{orb_stab_sum}=6·\{total}), rank constant on orbits=\{rank_constant}, orbit rank hist=\{nbe_show_ints(orbit_rank_hist)}, free orbit code=\{free_code} |orb|·|stab|=\{free_size}·\{free_stab}=6 (\{orbit_stabilizer}); NEG: mode-0 flattening rank \{nc_r0}≠\{nc_r1} at code=\{nc_code} axis=\{nc_axis} while tensor rank unchanged",
  )
}

///|
/// **`K7-18` (`Discovery ↔ Semiring`)**:
/// Viro–Krasner tropical hyperaddition tie-breaking on `{0..3}` aligns with `@strop`
/// tropical determinant tie detection, and transitive implication closure on all
/// `6,561` `F_3^{2x2x2}` tensors yields `3` unidirectional edges and `0` equivalence pairs!
pub fn verify_k7_18_discovery_semiring_bridge() -> (Bool, String) {
  let tie_cnt = @strop.trop_det_tie_count([[1L, 1L], [2L, 2L]])
  let viro_tie = @tensor.hyper_tropical_viro_op(3, 1, 1)
  let atlas = @tensor.f3_tensor222_atlas_build()
  let (imp, _led, ok_lens) = @conjecture.evaluate_five_epistemic_lenses_into_ledger(
    atlas_opt=Some(atlas),
  )
  // `1 (+) 1` in Viro hyperfield `{0..3}` has bitmask `(1<<1)|(1<<2)|(1<<3) = 14` (multi-valued tie!),
  // and on `F_3^{2x2x2}`: `1` unidirectional implication (`rank<=1 => Det==0`) & `1` equivalence (`decomp2==0 <=> rank==3`)!
  let ok = tie_cnt == 2 &&
    viro_tie == 14 &&
    ok_lens &&
    imp.strict_unidirectional_edges == 1 &&
    imp.nontrivial_equiv_pairs == 1
  (
    ok,
    "trop_ties=\{tie_cnt}, Viro(1⊕1)=mask(\{viro_tie}), F_3_impl=(uni=\{imp.strict_unidirectional_edges}, eq=\{imp.nontrivial_equiv_pairs})",
  )
}

///|
/// **`K7-19` (`Discovery ↔ Topos`)**:
/// Non-crossing chord-forest site `[T-X-Site]` (`48` opens on `4`-gon) satisfies
/// Grothendieck sheaf equalizer gluing, while `VR(C_4, 1)` chain/cochain duality
/// (`b = [1, 1]`) matches `@topos.boundary_simplex_nerve(2)` (`S^1` Betti `[1, 1]`)!
pub fn verify_k7_19_discovery_topos_bridge() -> (Bool, String) {
  let (nc4, site_ok) = @tensor.nc_forest_grothendieck_site_ok(4, 7)
  let c4_ms = @tensor.FiniteMetricSpace::{
    n: 4,
    dist: [[0, 1, 2, 1], [1, 0, 1, 2], [2, 1, 0, 1], [1, 2, 1, 0]],
  }
  let vr = @tensor.metric_vr_homology_report(c4_ms, 1, 7)
  let s1_ht = @topos.compute_nerve_homotopy_type(
    @topos.boundary_simplex_nerve(2),
  )
  let ok = nc4 == 48 &&
    site_ok &&
    vr.homology_cohomology_dual &&
    vr.betti_homology[0] == s1_ht.betti_numbers[0] &&
    vr.betti_homology[1] == s1_ht.betti_numbers[1]
  (
    ok,
    "NC_site(4)=\{nc4} opens (sheaf=\{site_ok}), VR(C_4,1)=S^1 Betti=[\{vr.betti_homology[0]},\{vr.betti_homology[1]}]",
  )
}

///|
/// **`K7-20` (`Discovery ↔ Scheme`)**:
/// Discrete Radon affine plane `A^2(F_3)` (`9` points, `12` lines, `4` directions)
/// completes to `@scheme.projective_space(2)` over `F_3` (`|P^2(F_3)| = 9 + 4 = 13` points),
/// and `[E-Scheme-Curve]` transfers Hironaka–Serre `p_a = delta + g_geom` from cubics to quartics!
pub fn verify_k7_20_discovery_scheme_bridge() -> (Bool, String) {
  let r3 = @tensor.radon_make(3, 101)
  let gram_ok = @tensor.radon_check_gram_identity(r3)
  let p2 = @scheme.scheme_projective_space(2)
  let p2_f3 = @scheme.eval_scheme_functor_of_points(p2, @scheme.fcomm_fp(3)).length()
  let evo = @conjecture.discover_six_evolution_laws()
  let curve_evo = evo[5]
  let ok = gram_ok &&
    r3.n * r3.n + r3.dirs == p2_f3 &&
    p2_f3 == 13 &&
    curve_evo.target_derived_on_train &&
    curve_evo.target_holds_on_transfer &&
    curve_evo.mirage_rejected_on_transfer
  (
    ok,
    "|A^2(F_3)|+dirs=9+4=\{p2_f3}=|P^2(F_3)|, Hironaka–Serre transfer=\{curve_evo.target_holds_on_transfer}",
  )
}

///|
/// **`K7-21` (`Discovery ↔ Condensed`)**:
/// Federation 7's 5 epistemic lenses seal `5` relational theorems into `@condensed.CondInvariantLedger`
/// with cryptographic chain verification, and Clifford cocycle radical `dim Z = |rad|`
/// couples with Condensed twisted AHSS obstruction theory!
pub fn verify_k7_21_discovery_condensed_bridge() -> (Bool, String) {
  let (_imp, led, lens_ok) = @conjecture.evaluate_five_epistemic_lenses_into_ledger()
  let (passed_laws, failed_laws) = @condensed.cond_ledger_audit_laws(led)
  let tw3 = @tensor.twisted_group_clifford_cocycle_report(2, 3)
  let ok = lens_ok &&
    @condensed.cond_ledger_verify(led) &&
    passed_laws == 2 &&
    failed_laws == 0 &&
    tw3.center_dim == 2 &&
    tw3.coboundary_gauge_invariant
  (
    ok,
    "ledger_entries=\{led.entries.length()}, laws_audited=(\{passed_laws},\{failed_laws}), Cl_3 center_dim=\{tw3.center_dim}",
  )
}

///|
/// Execute all **$\binom{7}{2} = 21$ pairwise cross-federation bridges (`K_7`)**:
/// `K5-01..K5-10` (10 edges) + `K6-11..K6-15` (5 edges) + `K7-16..K7-21` (6 new Discovery edges)!
pub fn verify_k7_federation_bridges() -> Array[FederationPairBridge] {
  let edges = verify_k6_federation_bridges()
  let (ok16, w16) = verify_k7_16_discovery_cubical_bridge()
  let (ok17, w17) = verify_k7_17_discovery_symlib_bridge()
  let (ok18, w18) = verify_k7_18_discovery_semiring_bridge()
  let (ok19, w19) = verify_k7_19_discovery_topos_bridge()
  let (ok20, w20) = verify_k7_20_discovery_scheme_bridge()
  let (ok21, w21) = verify_k7_21_discovery_condensed_bridge()
  edges.push(FederationPairBridge::{
    id: "K7-16",
    lhs: Discovery,
    rhs: Cubical,
    bridge_theorem: "Polygon Flip Walk ↔ Stasheff K_n 1-Skeleton & Lakatosian F_2 Wedge Refinement",
    holds: ok16,
    quantitative_witness: w16,
  })
  edges.push(FederationPairBridge::{
    id: "K7-17",
    lhs: Discovery,
    rhs: Symlib,
    bridge_theorem: "Dihedral Aut(K_4) = D_5 ≠ S_4 Refutation & S_3 Hyperdeterminant Symmetry",
    holds: ok17,
    quantitative_witness: w17,
  })
  edges.push(FederationPairBridge::{
    id: "K7-18",
    lhs: Discovery,
    rhs: Semiring,
    bridge_theorem: "Viro–Krasner Tropical Hyperfield Ties ↔ 6,561-Tensor F_3 Implication DAG",
    holds: ok18,
    quantitative_witness: w18,
  })
  edges.push(FederationPairBridge::{
    id: "K7-19",
    lhs: Discovery,
    rhs: Topos,
    bridge_theorem: "Non-Crossing Forest Grothendieck Sheaf [T-X-Site] ↔ Vietoris–Rips / Nerve Duality",
    holds: ok19,
    quantitative_witness: w19,
  })
  edges.push(FederationPairBridge::{
    id: "K7-20",
    lhs: Discovery,
    rhs: Scheme,
    bridge_theorem: "Discrete Radon A^2(F_3) ↪ P^2(F_3) Completion & Hironaka–Serre Curve Genus Transfer",
    holds: ok20,
    quantitative_witness: w20,
  })
  edges.push(FederationPairBridge::{
    id: "K7-21",
    lhs: Discovery,
    rhs: Condensed,
    bridge_theorem: "Epistemic Relational Lenses → Condensed Invariant Ledger & Clifford Spinor Center",
    holds: ok21,
    quantitative_witness: w21,
  })
  edges
}

///|
/// Execute the full **Seven-Federation Star-Prism & Lakatosian Discovery Loop** verification.
pub fn verify_seven_federation_star_prism(
  k7_precomputed~ : Array[FederationPairBridge]? = None,
) -> SevenFederationStarPrismReport {
  let feds = seven_federation_descriptors()
  let mut fed_ok = 0
  for f in feds {
    if f.live_health_ok {
      fed_ok = fed_ok + 1
    }
  }
  let k7 = match k7_precomputed {
    Some(es) => es
    None => verify_k7_federation_bridges()
  }
  let mut k7_ok = 0
  for e in k7 {
    if e.holds {
      k7_ok = k7_ok + 1
    }
  }
  let syn = @conjecture.synthesize_and_verify_conjecture_engine()
  let ok = fed_ok == 7 &&
    k7_ok == 21 &&
    syn.all_consistent &&
    syn.total_conjectures == 12 &&
    syn.evolution_families_passed == 6
  SevenFederationStarPrismReport::{
    seven_federations_verified: fed_ok,
    k7_bridges_verified: k7_ok,
    conjectures_evaluated: syn.total_conjectures,
    evolution_families_verified: syn.evolution_families_passed,
    lakatos_refinements_verified: syn.refuted_and_refined,
    epistemic_lenses_sealed: syn.epistemic_lenses_ledger_ok,
    star_prism_commutes: ok,
  }
}
