///|
fn main {
  println(
    "Golden Grand Unification — Seven-Federation Double-V, X-Overlap & Lakatosian Discovery Synthesis",
  )
  println(
    "================================================================================================",
  )
  println("-- Seven Autonomous Mathematical Federations (7/7) --")
  let feds = @bridge.seven_federation_descriptors()
  let mut fed_passed = 0
  for fed in feds {
    if fed.live_health_ok {
      fed_passed = fed_passed + 1
    }
    let st = if fed.live_health_ok { "PASS" } else { "FAIL" }
    println("[\{st}] federation \{fed.slug}: \{fed.summary}")
  }
  println("-- Complete K_7 Cross-Federation Pairwise Bridges (21/21) --")
  let k7_edges = @bridge.verify_k7_federation_bridges()
  let mut k7_passed = 0
  for edge in k7_edges {
    if edge.holds {
      k7_passed = k7_passed + 1
    }
    let st = if edge.holds { "PASS" } else { "FAIL" }
    println("[\{st}] \{edge.id}: \{edge.bridge_theorem}")
    println("        \{edge.quantitative_witness}")
  }
  println(
    "-- X-Overlap Chiasmus, Double-V & Seven-Federation Star-Prism Discovery --",
  )
  let x_rep = @bridge.verify_x_overlap_chiasmus()
  let dv_rep = @bridge.verify_double_v_architecture()
  let sp_rep = @bridge.verify_seven_federation_star_prism(
    k7_precomputed=Some(k7_edges),
  )
  println(
    "[PASS=\{x_rep.chiasm_commutes}] X-Overlap Chiasmus: D1=\{x_rep.diagonal_d1_syntax_nonarch_ok}, D2=\{x_rep.diagonal_d2_analytic_homotopy_ok}, invariants=\{x_rep.shared_chiasm_invariants.0},\{x_rep.shared_chiasm_invariants.1},\{x_rep.shared_chiasm_invariants.2}",
  )
  println(
    "[PASS=\{dv_rep.upper_v_synthesis_apex_ok}] Double-V: V1_gcd=\{dv_rep.lower_v_gcd_apex_ok}, federations=\{dv_rep.six_federations_verified}/6, K6=\{dv_rep.k6_bridges_verified}/15, boundaries_7=\{dv_rep.seven_boundaries_breakthrough_ok}",
  )
  println(
    "[PASS=\{sp_rep.star_prism_commutes}] Star-Prism Discovery: federations=\{sp_rep.seven_federations_verified}/7, K7=\{sp_rep.k7_bridges_verified}/21, conjectures=\{sp_rep.conjectures_evaluated}/12, evolve=\{sp_rep.evolution_families_verified}/6, lakatos_refined=\{sp_rep.lakatos_refinements_verified}",
  )
  println("-- Unified Certificate Ledger --")
  let certificates = @bridge.bridge_certificates()
  let mut atlas_passed = 0
  let mut pentagon_ok = false
  let mut six_ok = false
  for cert in certificates {
    let status = if cert.ok { "PASS" } else { "FAIL" }
    println("[\{status}] \{cert.source}: \{cert.name}")
    if cert.detail != "" {
      println("        \{cert.detail}")
    }
    if cert.source == "atlas" && cert.ok {
      atlas_passed = atlas_passed + 1
    } else if cert.source == "bridge/unification" {
      if cert.name.contains("Pentagon") {
        pentagon_ok = cert.ok
      } else if cert.name.contains("Six-Pillar") {
        six_ok = cert.ok
      }
    }
  }
  println(@bridge.certificate_summary(certificates))
  let all_certs_ok = @bridge.certificates_all_ok(certificates)
  let unif_ok = fed_passed == 7 &&
    k7_passed == 21 &&
    pentagon_ok &&
    six_ok &&
    atlas_passed == 18 &&
    x_rep.chiasm_commutes &&
    dv_rep.upper_v_synthesis_apex_ok &&
    sp_rep.star_prism_commutes &&
    all_certs_ok
  println(
    "seven-federation star-prism unification: federations=\{fed_passed}/7, K7_bridges=\{k7_passed}/21, conjectures=\{sp_rep.conjectures_evaluated}/12, x_overlap=\{x_rep.chiasm_commutes}, star_prism=\{sp_rep.star_prism_commutes}, atlas=\{atlas_passed}/18, all_ok=\{unif_ok}",
  )
  let cycle = @sgraph.Graph::build(4, [0, 1, 2, 3], [1, 2, 3, 0], [1, 1, 1, 1])
  let report = @bridge.weighted_graph_report(cycle, 32)
  println(
    "directed weighted C4: weighted symmetries=\{report.weighted_symmetry_count}, reachable pairs=\{report.reachable_pairs}, finite-distance sum=\{report.finite_distance_sum}",
  )
  println(
    "symmetry-average projector: projector=\{@cub.is_projector(report.symmetry_projector)}, trace=\{@cub.mat_trace_re(report.symmetry_projector)}",
  )
  let rotation = @sym.Perm::from_img([1, 2, 3, 0])
  let wiring_ok = match
    @bridge.perm_of_wiring(@bridge.perm_equiv(rotation).wiring) {
    Some(back) => back.equal(rotation)
    None => false
  }
  println("Perm → cubical Equiv → Perm round trip: \{wiring_ok}")
  guard all_certs_ok && wiring_ok && unif_ok else { abort("showcase failed") }
}
