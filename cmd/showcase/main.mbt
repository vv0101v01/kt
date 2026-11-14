///|
fn main {
  println("kt — Ten-federation constructive bridge inventory")
  println(
    "Active comparisons are bounded checks, not a complete K10 or universal proofs.",
  )
  let accel = @bridge.verify_accel_hardware_bridge()
  let feds = @bridge.ten_federation_descriptors(accel_precomputed=Some(accel))
  let mut fed_passed = 0
  for fed in feds {
    if fed.live_health_ok {
      fed_passed = fed_passed + 1
    }
    let status = if fed.live_health_ok { "PASS" } else { "FAIL" }
    println("[\{status}] federation \{fed.slug}: \{fed.summary}")
  }

  // Assemble the active pair snapshot ONCE for subgraph/report consumers.
  // Native/atlas suites may repeat primitives; retired code is never run.
  let edges = @bridge.verify_k10_ten_federation_bridges()
  let registry = @bridge.validate_bridge_registry(edges)
  println("-- Active bridge capabilities and quantitative witnesses --")
  for e in edges {
    let status = if e.holds { "PASS" } else { "FAIL" }
    println("[\{status}] \{e.id}: \{e.bridge_theorem}")
    println("        \{e.quantitative_witness}")
  }
  for error in registry.errors {
    println("[FAIL] registry: \{error}")
  }
  println(
    "active registry: \{registry.verified_count}/\{registry.expected_count}, present=\{registry.present_count}, all_holds=\{registry.all_holds}",
  )

  let checker_laws = @bridge.bridge_registry_laws()
  let mut checker_passed = 0
  for (name, ok) in checker_laws {
    if ok {
      checker_passed = checker_passed + 1
    } else {
      println("[FAIL] registry law: \{name}")
    }
  }
  println("registry checker laws: \{checker_passed}/\{checker_laws.length()}")

  let k6 = @bridge.bridge_edges_for_federations(edges, 6)
  let k7 = @bridge.bridge_edges_for_federations(edges, 7)
  let k9 = @bridge.bridge_edges_for_federations(edges, 9)
  let f6 = feds.filter(f => @bridge.federation_index(f.id) <= 6)
  let f7 = feds.filter(f => @bridge.federation_index(f.id) <= 7)
  let f9 = feds.filter(f => @bridge.federation_index(f.id) <= 9)
  let dv = @bridge.verify_double_v_architecture(
    k6_precomputed=Some(k6),
    federations_precomputed=Some(f6),
  )
  let sp = @bridge.verify_seven_federation_star_prism(
    k7_precomputed=Some(k7),
    federations_precomputed=Some(f7),
  )
  println(
    "historical active subgraphs: K6=\{dv.k6_bridges_verified}, K7=\{sp.k7_bridges_verified}; integration checks only, no X-commutativity claim",
  )

  let rotation = @bridge.verify_rotation_axis_bridge()
  println(
    "rotation relation alignment: \{rotation.families_passed}/4, holds=\{rotation.holds}, unresolved_coherence=\{rotation.coherence.remaining_after}",
  )
  for comparison in rotation.comparisons {
    println(
      "rotation \{comparison.family}: max_abs_delta=\{comparison.max_abs_delta}, holds=\{comparison.holds}",
    )
  }
  let intuition = @bridge.verify_intuitive_conjecture_lab()
  for record in intuition.records {
    println(
      "[\{@bridge.intuitive_conjecture_outcome_label(record.outcome)}; audit=\{record.audit_ok}] \{record.id}: \{record.title}",
    )
    println("        counterexample: \{record.counterexample}")
    println("        boundary: \{record.refined_statement}")
  }

  println(
    "-- Native / atlas / auxiliary certificates (NOT extra pairwise bridges) --",
  )
  let f851 = @bridge.verify_f8_f5_f1_triad_bridge()
  let frontier = @bridge.verify_frontier_7pillars_grand_unification()
  let certs = @bridge.bridge_certificates(
    accel_precomputed=Some(accel),
    triad_precomputed=Some(f851),
    frontier_precomputed=Some(frontier),
    k7_precomputed=Some(k7),
    federations_precomputed=Some(f7),
  )
  let mut atlas_passed = 0
  for cert in certs {
    let status = if cert.ok { "PASS" } else { "FAIL" }
    println("[\{status}] \{cert.source}: \{cert.name}")
    if cert.detail != "" {
      println("        \{cert.detail}")
    }
    if cert.source == "atlas" && cert.ok {
      atlas_passed = atlas_passed + 1
    }
  }
  println(@bridge.certificate_summary(certs))
  let certs_ok = @bridge.certificates_all_ok(certs) &&
    certs.length() == 50 &&
    atlas_passed == 18
  let legacy_ok = certs_ok &&
    dv.upper_v_synthesis_apex_ok &&
    sp.star_prism_commutes
  let nine = @bridge.verify_k9_meta_discovery_topos_unification(
    k9_precomputed=Some(k9),
    federations_precomputed=Some(f9),
    rotation_precomputed=Some(rotation),
    k5_preverified_ok=Some(legacy_ok),
  )
  let ten = @bridge.verify_k10_ten_federation_unification(
    k10_precomputed=Some(edges),
    federations_precomputed=Some(feds),
    rotation_precomputed=Some(rotation),
    k5_preverified_ok=Some(legacy_ok),
  )
  let wave1 = @bridge.verify_structural_bridge_replacements(
    precomputed=Some(edges),
  )
  let wave2 = @bridge.verify_nominal_bridge_elimination(precomputed=Some(edges))
  let replacements_ok = wave1.length() == 6 &&
    wave2.length() == 7 &&
    wave1.all(e => e.holds) &&
    wave2.all(e => e.holds)
  println(
    "historical K9 active=\{nine.k9_bridges_verified}; ten-federation active=\{ten.k10_bridges_verified}, ualg=\{ten.ualg_bridges_verified}/9, replacements=\{wave1.length()}+\{wave2.length()}, all_holds=\{ten.all_holds}",
  )

  let f236 = @bridge.verify_f2_f3_f6_triad_bridge()
  for report in f236.cases {
    println(
      "F2×F3×F6 shared graph: vertices=\{report.vertices}, components=\{report.components}, reach=\{report.reachable_pairs}, Laplacian_rank=\{report.laplacian_rank}, SNF_cert=\{report.snf_certificate_ok}, holds=\{report.all_holds}",
    )
  }
  println(
    "F2×F3×F6 disconnected negative control=\{f236.negative_control_detected}",
  )
  println(
    "F8×F5×F1 bounded comparisons=\{f851.all_holds}; WGSL static audit only (no GPU device execution)",
  )
  println(
    "frontier integration examples: holds=\{frontier.all_holds}, DAG visits=\{frontier.diamond_dag_unmemoized_visits}->\{frontier.diamond_dag_memoized_visits}",
  )

  let cycle = @sgraph.Graph::build(4, [0, 1, 2, 3], [1, 2, 3, 0], [1, 1, 1, 1])
  let weighted = @bridge.weighted_graph_report(cycle, 32)
  let perm = @sym.Perm::from_img([1, 2, 3, 0])
  let wiring_ok = match
    @bridge.perm_of_wiring(@bridge.perm_equiv(perm).wiring) {
    Some(back) => back.equal(perm)
    None => false
  }
  println(
    "weighted C4: symmetries=\{weighted.weighted_symmetry_count}, reach=\{weighted.reachable_pairs}, symmetry-average projector=\{@cub.is_projector(weighted.symmetry_projector)}, Perm/Wiring roundtrip=\{wiring_ok}",
  )

  println(
    "-- Retired metadata only; implementations and promotion pipeline deleted --",
  )
  for id in @bridge.retired_bridge_ids() {
    println("[RETIRED] \{id}: \{@bridge.bridge_retirement_reason(id)}")
  }
  guard registry.all_holds &&
    checker_passed == checker_laws.length() &&
    checker_passed > 0 &&
    fed_passed == 10 &&
    legacy_ok &&
    nine.all_holds &&
    ten.all_holds &&
    replacements_ok &&
    rotation.holds &&
    intuition.holds &&
    accel.all_ok &&
    f851.all_holds &&
    f236.all_holds &&
    frontier.all_holds &&
    wiring_ok else {
    abort(
      "showcase failed: see failed construction, coverage or negative control above",
    )
  }
}
