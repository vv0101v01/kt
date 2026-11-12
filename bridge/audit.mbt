///|
// Bridge audit overlay (2026-11-12 follow-up).
//
// A pairwise edge is *attempted* if it appears in the K10 registry.  It is
// *active* only when a genuine two-structure construction is verified.  Some
// historical edges are suspended: their previous `holds=true` was a conjunction
// of independent reports, a hardcoded model calculation, or a misnamed
// invariant.  Suspended edges are kept in the registry for traceability but are
// forced to `holds=false` and are NOT counted as verified bridges.
//
// This file deliberately does not try to force the complete graph K10 to be
// green.  The honest status is `active_verified / attempted`, with the
// suspended ids and reasons printed by the showcase and documented in README.

///|
pub fn bridge_suspension_reason(id : String) -> String {
  match id {
    "K6-11" =>
      "No constructed comparison map between truncated Adams Ext and Brunerie pi_4(S^3); Ext^{2,3}=0 is not a proof of 2*eta=0, and the solenoid lim^1 check is independent."
    "K6-13" =>
      "Tropical bend roots and p-liquid subadditivity are independent checks; no shared object or transport theorem couples them."
    "K7-18" =>
      "Viro tie mask and tensor implication lattice are independent; no hyperfield structure transports the implication order."
    "K7-21" =>
      "Hash-chained epistemic ledger and Clifford cocycle center are independent; cryptographic sealing is not a mathematical bridge."
    "K9-35" =>
      "Promotion pipeline stages lack a soundness theorem from the discovered tensor implication to the Horn/focused proof; symbolic rules use unrelated type terms."
    _ => ""
  }
}

///|
pub fn suspended_bridge_ids() -> Array[String] {
  ["K6-11", "K6-13", "K7-18", "K7-21", "K9-35"]
}

///|
/// Edges reviewed in this audit and KEPT (some strengthened, not suspended):
/// K6-14 (Serre base/fiber Betti vs topos nerves), K6-15 (Laurent Čech O(0)
/// agreement + Serre/RR; bogus BS_2 site conjunct removed), K7-19 (VR(C_4)≃S^1
/// nerve + non-crossing forest sheaf site), K10-41 (cubical → Stanley–Reisner
/// ideal → Hilbert report).  Independent conjuncts split out of K5-03/06/10,
/// K7-16/20 are auxiliary certificates below, not bridge edges.

///|
/// Idempotently mark suspended edges.  Active edges are untouched.
pub fn apply_bridge_audit(
  edges : Array[FederationPairBridge],
) -> Array[FederationPairBridge] {
  edges.map(e => {
    let reason = bridge_suspension_reason(e.id)
    if reason != "" && e.holds {
      FederationPairBridge::{
        id: e.id,
        lhs: e.lhs,
        rhs: e.rhs,
        bridge_theorem: "[SUSPENDED] " + e.bridge_theorem,
        holds: false,
        quantitative_witness: "SUSPENDED: " +
        reason +
        " | previous witness: " +
        e.quantitative_witness,
      }
    } else {
      e
    }
  })
}

///|
/// (attempted, active_verified, suspended).  `active_verified` counts only
/// non-suspended edges whose construction currently holds.
pub fn bridge_audit_counts(
  edges : Array[FederationPairBridge],
) -> (Int32, Int32, Int32) {
  let mut active = 0
  let mut suspended = 0
  for e in edges {
    if bridge_suspension_reason(e.id) != "" {
      suspended = suspended + 1
    } else if e.holds {
      active = active + 1
    }
  }
  (edges.length(), active, suspended)
}

///|
pub fn bridge_audit_all_active_hold(
  edges : Array[FederationPairBridge],
) -> Bool {
  let (attempted, active, suspended) = bridge_audit_counts(edges)
  attempted == active + suspended && active == attempted - suspended
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
