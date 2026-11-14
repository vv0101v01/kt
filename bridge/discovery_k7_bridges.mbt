///|
// Seven-federation active comparison graph and resolved-conjecture reports.
// 17 active edges, not a complete K7; K7-18 and K7-21 are deleted.

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
    packages: ["tensor", "discovery-kernel", "conjecture"],
    canonical_normal_form: "Cayley 2x2x2 Hyperdeterminant / F_3 Rank Atlas, Radon Inversion, [E-Derive] Nullspace Basis & Implication DAG",
    categorification_role: "Multilinear Tensor/Spinor-Gauge/Radon Geometry & Lakatosian Conjecture-Discovery-Refinement Functor",
    live_health_ok: f7_ok,
    summary: "F_3 6561-Tensor Atlas, Discrete Radon, Clifford/Gauge Spinors, VR Homology, 6 Evolution Laws, 5 Lenses & 7 Resolved Conjectures",
  })
  out
}

///|
/// K7-16: compare vertex/edge counts of 5/6-gon flip graphs and the
/// corresponding associahedron f-vectors. This is a bounded skeleton count
/// comparison, not a constructed equivalence of categories; wedge fillers are
/// separate auxiliary certificates.
pub fn verify_k7_16_discovery_cubical_bridge() -> (Bool, String) {
  let flip5 = @tensor.nc_polygon_triangulations_flip_report(5)
  let flip6 = @tensor.nc_polygon_triangulations_flip_report(6)
  let fv4 = @cub.assoc_fvector(4)
  let fv5 = @cub.assoc_fvector(5)
  let ok = flip5.catalan_count == fv4[0] &&
    flip5.flip_edges == fv4[1] &&
    flip6.catalan_count == fv5[0] &&
    flip6.flip_edges == fv5[1]
  (
    ok,
    "flip(5,6)=(\{flip5.catalan_count},\{flip6.catalan_count})==K_{4,5} vertices/edges; associahedron f-vectors agree",
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
pub fn verify_k7_17_discovery_symlib_bridge(
  atlas_precomputed~ : @tensor.F3Tensor222Atlas? = None,
) -> (Bool, String) {
  let total = 6561
  let atlas = match atlas_precomputed {
    Some(a) => a
    None => @tensor.f3_tensor222_atlas_build()
  }
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
/// K7-19: transport the same VR complex into a Topos nerve, rather than
/// comparing C₄'s homology to an unrelated triangle boundary's dimensions.
pub fn verify_k7_19_discovery_topos_bridge() -> (Bool, String) {
  let space = @tensor.metric_cycle_graph(4)
  let mut agrees = true
  let h0s : Array[Int32] = []
  let h1s : Array[Int32] = []
  for scale in 0..<3 {
    guard metric_vr_to_topos_nerve(space, scale) is Some(nerve) else {
      return (false, "valid VR complex rejected")
    }
    let vr = @tensor.metric_vr_homology_report(space, scale, 7)
    let cohomology = @topos.nerve_cohomology_dimensions_fp(nerve, 7)
    for degree in 0..<3 {
      agrees = agrees && vr.betti_homology[degree] == cohomology[degree]
    }
    agrees = agrees &&
      vr.chain_complex_dd_zero &&
      vr.homology_cohomology_dual &&
      vr.simplex_counts[0] == nerve.num_vertices &&
      vr.simplex_counts[1] == nerve.edges.length() &&
      vr.simplex_counts[2] == nerve.triangles.length() &&
      vr.simplex_counts[3] == nerve.tetrahedra.length()
    h0s.push(cohomology[0])
    h1s.push(cohomology[1])
  }
  guard metric_vr_to_topos_nerve(space, 2) is Some(full) else {
    return (false, "full simplex rejected")
  }
  let tampered : @topos.SimplicialNerve = {
    num_vertices: full.num_vertices,
    edges: full.edges.copy(),
    triangles: [],
    tetrahedra: [],
  }
  let bad_h1 = @topos.nerve_cohomology_dimensions_fp(tampered, 7)[1]
  let negative = h0s == [4, 1, 1] &&
    h1s == [0, 1, 0] &&
    bad_h1 == 3 &&
    metric_vr_to_topos_nerve({ n: 2, dist: [[0, 1], []], }, 1) is None &&
    metric_vr_to_topos_nerve(space, -1) is None
  (
    agrees && negative,
    "same VR(C4,r) complex, r=0/1/2: H0=\{nbe_show_ints(h0s)}, H1=\{nbe_show_ints(h1s)}, tensor==Topos in degrees0..2=\{agrees}; NEG deleting faces yields H1=\{bad_h1}, malformed inputs rejected=\{negative}",
  )
}

///|
/// K7-20: affine Radon point/direction count 9+4 agrees with P2(F3)
/// point enumeration. This is not an implementation of a general projective
/// incidence transport. Curve-genus transfer is a separate auxiliary certificate.
pub fn verify_k7_20_discovery_scheme_bridge() -> (Bool, String) {
  let r3 = @tensor.radon_make(3, 101)
  let gram_ok = @tensor.radon_check_gram_identity(r3)
  let p2 = @scheme.scheme_projective_space(2)
  let p2_f3 = @scheme.eval_scheme_functor_of_points(p2, @scheme.fcomm_fp(3)).length()
  let ok = gram_ok && r3.n * r3.n + r3.dirs == p2_f3 && p2_f3 == 13
  (
    ok,
    "|A^2(F_3)|+dirs=9+4=\{p2_f3}=|P^2(F_3)|; Radon Gram identity=\{gram_ok}",
  )
}

///|
/// Execute the 17 active comparisons of the historical seven-federation scope.
/// The optional atlas is shared read-only; no suspended/retired work is executed.
pub fn verify_k7_federation_bridges(
  atlas_precomputed~ : @tensor.F3Tensor222Atlas? = None,
) -> Array[FederationPairBridge] {
  let edges = verify_k6_federation_bridges()
  let (ok16, w16) = verify_k7_16_discovery_cubical_bridge()
  let (ok17, w17) = verify_k7_17_discovery_symlib_bridge(atlas_precomputed~)
  let (ok19, w19) = verify_k7_19_discovery_topos_bridge()
  let (ok20, w20) = verify_k7_20_discovery_scheme_bridge()
  edges.push(FederationPairBridge::{
    id: "K7-16",
    lhs: Discovery,
    rhs: Cubical,
    bridge_theorem: "Polygon Flip Walk ↔ Stasheff K_n 1-Skeleton",
    holds: ok16,
    quantitative_witness: w16,
  })
  edges.push(FederationPairBridge::{
    id: "K7-17",
    lhs: Discovery,
    rhs: Symlib,
    bridge_theorem: "S_3 orbit rank stratification of F_3^{2×2×2} tensors; orbit-stabilizer and flattening-rank negative control",
    holds: ok17,
    quantitative_witness: w17,
  })
  edges.push(FederationPairBridge::{
    id: "K7-19",
    lhs: Discovery,
    rhs: Topos,
    bridge_theorem: "Same Vietoris–Rips complex transported to a Topos nerve; scale and face-deletion controls",
    holds: ok19,
    quantitative_witness: w19,
  })
  edges.push(FederationPairBridge::{
    id: "K7-20",
    lhs: Discovery,
    rhs: Scheme,
    bridge_theorem: "Discrete Radon A^2(F_3) ↪ P^2(F_3) Completion",
    holds: ok20,
    quantitative_witness: w20,
  })
  edges
}

///|
/// Execute the full **Seven-Federation Star-Prism & Lakatosian Discovery Loop** verification.
pub fn verify_seven_federation_star_prism(
  k7_precomputed~ : Array[FederationPairBridge]? = None,
  federations_precomputed~ : Array[FederationDescriptor]? = None,
) -> SevenFederationStarPrismReport {
  let feds = match federations_precomputed {
    Some(fs) => fs
    None => seven_federation_descriptors()
  }
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
  let registry = validate_bridge_registry(k7, federation_count=7)
  let mut k7_ok = 0
  for e in k7 {
    if e.holds {
      k7_ok = k7_ok + 1
    }
  }
  let syn = @conjecture.synthesize_and_verify_conjecture_engine()
  let ok = federation_health_valid(feds, 7) &&
    registry.all_holds &&
    syn.all_consistent &&
    syn.total_conjectures == 7 &&
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

///|
/// Translate an integer metric's Vietoris–Rips flag complex to the SAME
/// vertex/edge/triangle/tetrahedron data consumed by Topos. n is limited to
/// 1..8, matching the tensor engine's documented finite domain. This is a
/// 3-skeleton: sufficient for H⁰..H², NOT full higher-dimensional homology.
/// Shape is checked before indexing and triangle sums use Int64 (no overflow).
pub fn metric_vr_to_topos_nerve(
  space : @tensor.FiniteMetricSpace,
  scale : Int32,
) -> @topos.SimplicialNerve? {
  let n = space.n
  if n < 1 || n > 8 || scale < 0 || space.dist.length() != n {
    return None
  }
  for row in space.dist {
    if row.length() != n {
      return None
    }
  }
  for i in 0..<n {
    for j in 0..<n {
      let d = space.dist[i][j]
      if d < 0 ||
        d != space.dist[j][i] ||
        (i == j && d != 0) ||
        (i != j && d == 0) {
        return None
      }
      for k in 0..<n {
        if space.dist[i][k].to_int64() >
          d.to_int64() + space.dist[j][k].to_int64() {
          return None
        }
      }
    }
  }
  let edges : Array[(Int32, Int32)] = []
  let triangles : Array[(Int32, Int32, Int32)] = []
  let tetrahedra : Array[(Int32, Int32, Int32, Int32)] = []
  for i in 0..<n {
    for j in (i + 1)..<n {
      if space.dist[i][j] > scale {
        continue
      }
      edges.push((i, j))
      for k in (j + 1)..<n {
        if space.dist[i][k] > scale || space.dist[j][k] > scale {
          continue
        }
        triangles.push((i, j, k))
        for l in (k + 1)..<n {
          if space.dist[i][l] <= scale &&
            space.dist[j][l] <= scale &&
            space.dist[k][l] <= scale {
            tetrahedra.push((i, j, k, l))
          }
        }
      }
    }
  }
  Some({ num_vertices: n, edges, triangles, tetrahedra, })
}
