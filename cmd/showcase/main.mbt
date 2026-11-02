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
  let rotation_axis = @bridge.verify_rotation_axis_bridge()
  println(
    "[PASS=\{rotation_axis.holds}] Conjugate-Quaternion Condensed Axis: families=\{rotation_axis.families_passed}/4, integral_residual=\{rotation_axis.axis.integral.residual}, RK4_order=\{rotation_axis.axis.ode.observed_order}, Richardson_error=\{rotation_axis.axis.ode.richardson_limit_error}, conservation_laws=\{rotation_axis.axis.conservation_laws_passed}/3, ledger_entries=\{rotation_axis.axis.ledger_entries}",
  )
  println(
    "[PASS=\{rotation_axis.coherence.holds}] Coherence angles: total=\{rotation_axis.coherence.total_angles}, coarse_eliminated=\{rotation_axis.coherence.coarse_eliminated}, before_reverse=\{rotation_axis.coherence.remaining_before_reverse_elimination}, reverse_eliminated=\{rotation_axis.coherence.reverse_pair_eliminated}, canonical_classes=\{rotation_axis.coherence.reverse_pair_classes}, remaining=\{rotation_axis.coherence.remaining_after}, conserved_incidences=\{rotation_axis.coherence.conserved_incidence_count}, negative_control=\{rotation_axis.coherence.negative_control_detected}",
  )
  for comparison in rotation_axis.comparisons {
    println(
      "[PASS=\{comparison.holds}] Numeric baseline \{comparison.family}: previous=\{@debug.to_string(comparison.previous)}, current=\{@debug.to_string(comparison.current)}, deltas=\{@debug.to_string(comparison.deltas)}, max_abs_delta=\{comparison.max_abs_delta}",
    )
  }
  println(
    "[PASS=\{rotation_axis.axis_comparison.holds}] Numeric baseline Condensed axis: previous=\{@debug.to_string(rotation_axis.axis_comparison.previous)}, current=\{@debug.to_string(rotation_axis.axis_comparison.current)}, deltas=\{@debug.to_string(rotation_axis.axis_comparison.deltas)}",
  )
  let intuitive_lab = @bridge.verify_intuitive_conjecture_lab()
  println(
    "-- Five Intuition-Driven Conjectures: Counterexample Attacks (survived=\{intuitive_lab.bounded_survivals}, refuted+refined=\{intuitive_lab.refuted_and_refined}) --",
  )
  for record in intuitive_lab.records {
    println(
      "[\{@bridge.intuitive_conjecture_outcome_label(record.outcome)}; audit=\{record.audit_ok}] \{record.id}: \{record.title}",
    )
    println("        直覺：\{record.intuition}")
    println("        猜想：\{record.statement}")
    println("        搜索：\{record.search_scope}")
    println("        反例：\{record.counterexample}")
    println("        修正／邊界：\{record.refined_statement}")
    println("        證據：\{record.evidence}")
  }
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
    rotation_axis.holds &&
    intuitive_lab.holds &&
    all_certs_ok
  println(
    "seven-federation star-prism unification: federations=\{fed_passed}/7, K7_bridges=\{k7_passed}/21, conjectures=\{sp_rep.conjectures_evaluated}/12, intuition_lab=\{intuitive_lab.records.length()}/5, x_overlap=\{x_rep.chiasm_commutes}, star_prism=\{sp_rep.star_prism_commutes}, atlas=\{atlas_passed}/18, all_ok=\{unif_ok}",
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
  let accel_rep = @bridge.verify_accel_hardware_bridge()
  println(
    "CPU SWAR + Browser Free WebGPU (WGSL) acceleration: all_ok=\{accel_rep.all_ok}, wgsl_portable=\{accel_rep.wgsl_browser_kernels_audited}/7",
  )
  guard all_certs_ok && wiring_ok && unif_ok && accel_rep.all_ok else {
    abort("showcase failed")
  }
}
