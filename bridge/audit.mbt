///|
// Fail-closed inventory validation. This checks coverage and reported results,
// not the truth of caller-supplied mathematical evidence. Precomputed records
// are an in-process optimisation for trusted callers, not proof objects.
#derive(Debug, Eq)
pub(all) struct BridgeRegistryReport {
  expected_count : Int32
  present_count : Int32
  verified_count : Int32
  errors : Array[String]
  all_holds : Bool
}

///|
pub extend BridgeRegistryReport with @debug.Debug::{to_repr}

///|
pub extend BridgeRegistryReport with Eq::{not_equal, equal}

///|
/// Select a historical subgraph; this function does not validate it.
pub fn bridge_edges_for_federations(
  edges : Array[FederationPairBridge],
  federation_count : Int32,
) -> Array[FederationPairBridge] {
  edges.filter(e => {
    federation_index(e.lhs) <= federation_count &&
    federation_index(e.rhs) <= federation_count
  })
}

///|
fn federation_health_valid(
  feds : Array[FederationDescriptor],
  count : Int32,
) -> Bool {
  if count < 5 || count > 10 || feds.length() != count {
    return false
  }
  let seen : Array[FederationId] = []
  for f in feds {
    if !f.live_health_ok ||
      federation_index(f.id) > count ||
      seen.contains(f.id) {
      return false
    }
    seen.push(f.id)
  }
  true
}

///|
fn bridge_holds_by_id(edges : Array[FederationPairBridge], id : String) -> Bool {
  let mut found = 0
  let mut holds = false
  for e in edges {
    if e.id == id {
      found = found + 1
      holds = e.holds
    }
  }
  found == 1 && holds
}

///|
/// Validate the EXACT active set for 5..10 federations. Missing, duplicate,
/// retired and unknown IDs, wrong endpoints, empty witnesses and failed
/// constructions all fail. Endpoint order is immaterial: these are undirected
/// semantic comparisons, not directed imports.
pub fn validate_bridge_registry(
  edges : Array[FederationPairBridge],
  federation_count~ : Int32 = 10,
) -> BridgeRegistryReport {
  let specs = active_bridge_specs().filter(s => {
    federation_index(s.1) <= federation_count &&
    federation_index(s.2) <= federation_count
  })
  let errors : Array[String] = []
  let seen : Array[String] = []
  let mut verified = 0
  if federation_count < 5 || federation_count > 10 {
    errors.push("unsupported federation count: \{federation_count}")
  }
  if edges.length() != specs.length() {
    errors.push("coverage: expected \{specs.length()}, got \{edges.length()}")
  }
  for e in edges {
    let errors_before = errors.length()
    if seen.contains(e.id) {
      errors.push("duplicate id: " + e.id)
    }
    seen.push(e.id)
    let mut known = false
    for s in specs {
      if s.0 == e.id {
        known = true
        if !((e.lhs == s.1 && e.rhs == s.2) || (e.lhs == s.2 && e.rhs == s.1)) {
          errors.push("endpoint mismatch: " + e.id)
        }
      }
    }
    if !known {
      let reason = bridge_retirement_reason(e.id)
      errors.push(
        if reason == "" {
          "unknown or out-of-scope id: " + e.id
        } else {
          "retired id: " + e.id + " — " + reason
        },
      )
    }
    if !e.holds {
      errors.push("construction failed: " + e.id)
    }
    if e.bridge_theorem.trim().is_empty() ||
      e.quantitative_witness.trim().is_empty() {
      errors.push("empty theorem or witness: " + e.id)
    }
    if errors.length() == errors_before {
      verified = verified + 1
    }
  }
  for s in specs {
    if !seen.contains(s.0) {
      errors.push("missing id: " + s.0)
    }
  }
  {
    expected_count: specs.length(),
    present_count: edges.length(),
    verified_count: verified,
    errors,
    all_holds: errors.is_empty() && !specs.is_empty(),
  }
}

///|
/// Durable laws for the inventory checker, using deliberately synthetic
/// records. These exercise the checker, not any mathematical bridge itself.
pub fn bridge_registry_laws() -> Array[(String, Bool)] {
  let base = active_bridge_specs().map(s => FederationPairBridge::{
    id: s.0,
    lhs: s.1,
    rhs: s.2,
    bridge_theorem: "synthetic registry-check fixture",
    holds: true,
    quantitative_witness: "metadata only, not mathematical evidence",
  })
  let missing = base.filter(e => e.id != "K5-01")
  let duplicate = base.copy()
  duplicate[1] = duplicate[0]
  let extra = base.copy()
  extra.push(base[0])
  let changed = (
    id : String,
    lhs : FederationId,
    rhs : FederationId,
    holds : Bool,
    witness : String,
  ) => {
    let es = base.copy()
    es[0] = FederationPairBridge::{
      id,
      lhs,
      rhs,
      bridge_theorem: "synthetic registry-check fixture",
      holds,
      quantitative_witness: witness,
    }
    es
  }
  let good = "synthetic evidence"
  let mut prefixes_ok = true
  for n in 5..<11 {
    if !validate_bridge_registry(
        bridge_edges_for_federations(base, n),
        federation_count=n,
      ).all_holds {
      prefixes_ok = false
    }
  }
  [
    (
      "exact active inventory accepted",
      validate_bridge_registry(base).all_holds,
    ),
    ("all historical active prefixes accepted", prefixes_ok),
    ("empty inventory rejected", !validate_bridge_registry([]).all_holds),
    ("missing edge rejected", !validate_bridge_registry(missing).all_holds),
    (
      "same-length duplicate substitution rejected",
      !validate_bridge_registry(duplicate).all_holds,
    ),
    ("extra duplicate rejected", !validate_bridge_registry(extra).all_holds),
    (
      "wrong pair rejected",
      !validate_bridge_registry(changed("K5-01", Cubical, Topos, true, good)).all_holds,
    ),
    (
      "retired true edge rejected",
      !validate_bridge_registry(
        changed("K6-11", Condensed, Cubical, true, good),
      ).all_holds,
    ),
    (
      "unknown true edge rejected",
      !validate_bridge_registry(changed("K5-99", Cubical, Symlib, true, good)).all_holds,
    ),
    (
      "failed construction rejected",
      !validate_bridge_registry(changed("K5-01", Cubical, Symlib, false, good)).all_holds,
    ),
    (
      "blank witness rejected",
      !validate_bridge_registry(changed("K5-01", Cubical, Symlib, true, "  ")).all_holds,
    ),
    (
      "reversed pair accepted",
      validate_bridge_registry(changed("K5-01", Symlib, Cubical, true, good)).all_holds,
    ),
    (
      "unsupported generation rejected",
      !validate_bridge_registry(base, federation_count=11).all_holds,
    ),
    (
      "out-of-generation edges rejected",
      !validate_bridge_registry(base, federation_count=9).all_holds,
    ),
    ("empty certificate ledger rejected", !certificates_all_ok([])),
  ]
}

///|
/// Auxiliary theorems that were previously conjoined into bridge edges but are
/// not themselves the pairwise bridge construction.  They remain verified and
/// gated, but are reported separately so the bridge count is not inflated.
pub fn verify_bridge_auxiliary_theorems() -> Array[BridgeCertificate] {
  let rev_circle_bary = @sym.cat_poset(6, [
    (5, 2),
    (5, 1),
    (4, 1),
    (4, 0),
    (3, 0),
    (3, 2),
  ])
  let ht_rev = @topos.compute_nerve_homotopy_type(
    @topos.classifying_nerve_of_poset(rev_circle_bary),
  )
  let reverse_nerve = ht_rev.betti_numbers == [1, 1, 0, 0] &&
    ht_rev.pi1_free_rank == 1
  let w_rep = @cub.wedge_square_filler_report([2], [2], [1], [1])
  let wedge_filler = !w_rep.fills_in_wedge_s1_s1 &&
    w_rep.fills_in_abelianized_torus
  let evo = @conjecture.discover_six_evolution_laws()
  let curve_evo = evo[5]
  let curve_transfer = curve_evo.target_derived_on_train &&
    curve_evo.target_holds_on_transfer &&
    curve_evo.mirage_rejected_on_transfer
  [
    bridge_certificate(
      "auxiliary/topos",
      "Order-reversed S^1 cover nerve Betti=[1,1,0,0]",
      reverse_nerve,
      detail="split out of K5-06; not the G-Set ≃ Sh_at(BG) bridge",
    ),
    bridge_certificate(
      "auxiliary/cubical",
      "Wedge S^1∨S^1 commutator filler obstruction",
      wedge_filler,
      detail="split out of K7-16; not the polygon-flip/associahedron bridge",
    ),
    bridge_certificate(
      "auxiliary/scheme",
      "Hironaka-Serre p_a=delta+g_geom cubic-to-quartic transfer",
      curve_transfer,
      detail="split out of K7-20; not the Radon/projective completion bridge",
    ),
  ]
}

///|
/// Primary K5-10 edge after splitting the historical composite: only the
/// Zariski-topos nilpotent-invariance construction remains in the pairwise
/// bridge.  The étale-torsor and excision/blow-up theorems already have their
/// own translation certificates; they are not extra conjuncts inflating this edge.
pub fn replace_k5_10_zariski_nilpotent_topos() -> FederationPairBridge {
  let holds = verify_zariski_topos_invariance_vs_nilpotent_points()
  FederationPairBridge::{
    id: "K5-10",
    lhs: Topos,
    rhs: Scheme,
    bridge_theorem: "Zariski classifying topos is invariant under nilpotent thickening while the functor of points distinguishes X from X_red",
    holds,
    quantitative_witness: "X=Spec(Q[x]/<x^2(x-1)>): |X(F_3)|=|X_red(F_3)|=2, |X(F_3[ε])|=4 vs |X_red(F_3[ε])|=2; same propositional Zariski theory and 2 classifying-topos points",
  }
}

///|
/// K9-32 repaired: two-path H^1 agreement on S^1 plus a filled-triangle
/// negative control (H^1=0) and an S^2 control (H^1=0, H^2=1).
pub fn replace_k9_32_nerve_h1_bareiss() -> FederationPairBridge {
  let s1 = @topos.boundary_simplex_nerve(2)
  let s1_fp = @topos.nerve_cohomology_dimensions_fp(s1, 7)
  let d0_s1 : Array[Array[Int32]] = [[-1, 1, 0], [0, -1, 1], [-1, 0, 1]]
  let (rk0_s1, cert0_s1) = @mcore.matrix_rank_bareiss64_with_cert(d0_s1)
  let h1_s1_bareiss = 3 - rk0_s1
  let filled : @topos.SimplicialNerve = {
    num_vertices: 3,
    edges: [(0, 1), (0, 2), (1, 2)],
    triangles: [(0, 1, 2)],
    tetrahedra: [],
  }
  let filled_fp = @topos.nerve_cohomology_dimensions_fp(filled, 7)
  let d1_filled : Array[Array[Int32]] = [[1, -1, 1]]
  let (rk0_f, cert0_f) = @mcore.matrix_rank_bareiss64_with_cert(d0_s1)
  let (rk1_f, cert1_f) = @mcore.matrix_rank_bareiss64_with_cert(d1_filled)
  let h1_f_bareiss = 3 - rk0_f - rk1_f
  let s2 = @topos.boundary_simplex_nerve(3)
  let s2_fp = @topos.nerve_cohomology_dimensions_fp(s2, 7)
  let positive = cert0_s1 && h1_s1_bareiss == s1_fp[1] && s1_fp[1] == 1
  let negative = cert0_f &&
    cert1_f &&
    h1_f_bareiss == filled_fp[1] &&
    filled_fp[1] == 0 &&
    s2_fp[1] == 0 &&
    s2_fp[2] == 1
  let holds = positive && negative
  FederationPairBridge::{
    id: "K9-32",
    lhs: Meta,
    rhs: Topos,
    bridge_theorem: "Fraction-free Bareiss ranks of simplicial boundary matrices agree with topos nerve cohomology: H^1(S^1)=1, while the filled triangle and S^2 have H^1=0",
    holds,
    quantitative_witness: "S1: Bareiss_H1=\{h1_s1_bareiss}==nerve=\{s1_fp[1]}, cert=\{cert0_s1}; filled Δ2: Bareiss_H1=\{h1_f_bareiss}==nerve=\{filled_fp[1]}, certs=\{cert0_f && cert1_f}; S2 nerve β=\{nbe_show_ints(s2_fp)}",
  }
}
