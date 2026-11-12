///|
fn main {
  println(
    "Golden Grand Unification — Ten-Federation Double-V, X-Overlap & Lakatosian Discovery Synthesis",
  )
  println(
    "================================================================================================",
  )
  println("-- Ten Autonomous Mathematical Federations (10/10) --")
  let feds = @bridge.ten_federation_descriptors()
  let mut fed_passed = 0
  for fed in feds {
    if fed.live_health_ok {
      fed_passed = fed_passed + 1
    }
    let st = if fed.live_health_ok { "PASS" } else { "FAIL" }
    println("[\{st}] federation \{fed.slug}: \{fed.summary}")
  }
  println("-- Historical K_7 Cross-Federation Pairwise Bridges (21/21) --")
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
  let mut legacy_fed_passed = 0
  for i in 0..<7 {
    if feds[i].live_health_ok {
      legacy_fed_passed = legacy_fed_passed + 1
    }
  }
  let unif_ok = legacy_fed_passed == 7 &&
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
    "historical seven-federation star-prism unification: federations=\{legacy_fed_passed}/7, K7_bridges=\{k7_passed}/21, conjectures=\{sp_rep.conjectures_evaluated}/12, intuition_lab=\{intuitive_lab.records.length()}/5, x_overlap=\{x_rep.chiasm_commutes}, star_prism=\{sp_rep.star_prism_commutes}, atlas=\{atlas_passed}/18, all_ok=\{unif_ok}",
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
  let triad_rep = @bridge.verify_f8_f5_f1_triad_bridge()
  let triad_f236 = @bridge.verify_f2_f3_f6_triad_bridge()
  println(
    "CPU SWAR + Browser Free WebGPU (WGSL) acceleration: all_ok=\{accel_rep.all_ok}, triad(GF2_F4_ROBDD=\{triad_rep.gf2_f4_robdd_isomorphism_ok}, CCHM_Zariski=\{triad_rep.cchm_zariski_cofibration_duality_ok}, ModF4=\{triad_rep.modular_f4_matches_buchberger_ok}, INet_NbE=\{triad_rep.inet_nbe_peano_confluence_ok})=\{triad_rep.all_holds}, wgsl_portable=\{accel_rep.wgsl_browser_kernels_audited}/7(SSOT=8/8)",
  )
  println(
    "F2×F3×F6 Symmetry-Semiring-Condensed Triad: A5_classes=\{triad_f236.a5_subgroup_classes}, B3_classes=\{triad_f236.b3_subgroup_classes}, Burnside_Mobius=\{triad_f236.burnside_mobius_exact_ok}, Groupoid_Yoneda=\{triad_f236.nonthin_groupoid_yoneda_ok}, Semiring_Wasm=\{triad_f236.semiring_wasm_suite_ok}, ModHNF=\{triad_f236.modular_hnf_snf_ok}, Nobeling=\{triad_f236.nobeling_solid_duality_ok}, Adams_h3_eta3=\{triad_f236.adams_h3_sigma_and_eta3_ok}, all_holds=\{triad_f236.all_holds}",
  )
  let autonomy_rep = @bridge.verify_malcev_presheaf_autonomy_bridge()
  println(
    "Constructive Universal Algebra + ¬¬ Presheaf + Cubical Autonomy: holds=\{autonomy_rep.holds}, 4cubes=\{autonomy_rep.swar_cube.nondegenerate_4cubes_count}+\{autonomy_rep.swar_cube.degenerate_4cubes_count}=\{autonomy_rep.nondeg_plus_deg_4cubes}, nn_sieves=\{autonomy_rep.presheaf_dn.omega_nn_stable_sieves}/\{autonomy_rep.presheaf_dn.omega_total_sieves}",
  )
  let w4 = autonomy_rep.work4_atlas
  println(
    "Full-Spectrum Cubical Structures × 26 Verbs × 14 Compositions: structures=\{w4.verified_structure_count}/54, verbs=\{w4.distinct_verbs_covered}/26, patterns=\{w4.distinct_patterns_covered}/14, interactions=\{w4.interaction_theorems_count}/14, focus=\{w4.affine_bidir_focus.unfocused_interleavings_count}->\{w4.affine_bidir_focus.focused_canonical_derivations_count}, ok=\{w4.all_54_structures_and_interactions_ok}",
  )
  let k9_rep = @bridge.verify_k9_meta_discovery_topos_unification(
    k7_precomputed=Some(k7_edges),
    accel_precomputed=Some(accel_rep),
    rotation_precomputed=Some(rotation_axis),
    k5_preverified_ok=Some(unif_ok),
  )
  let pp = k9_rep.promotion_pipeline
  println(
    "Nine-Federation K_9 Star-Prism & F7->F9->F4->F1 Promotion: federations=\{k9_rep.nine_federations_verified}/9, K9_bridges=\{k9_rep.k9_bridges_verified}/36, V5_HF64=\{k9_rep.v5_ackermann_65536_sets_verified}, promote(F7_edges=\{pp.f7_bitplane_implications_found}, ctz_cex=\{pp.f7_hardware_ctz_counterexample}, F9_hits=\{pp.f9_slg_tabling_cache_hits}, H1_zero=\{pp.f9_bareiss_gluing_h1_zero}, F4_Sieve64=\{pp.f4_sieve64_global_truth_holds}, F1_LJF=\{pp.f1_ljf_focused_unique_proof})=\{k9_rep.all_holds}",
  )
  let k10_rep = @bridge.verify_k10_ten_federation_unification(
    k7_precomputed=Some(k7_edges),
    accel_precomputed=Some(accel_rep),
    rotation_precomputed=Some(rotation_axis),
    k5_preverified_ok=Some(unif_ok),
  )
  println(
    "Ten-Federation K_10 Constructive Unification: federations=\{k10_rep.ten_federations_verified}/10, K10_bridges=\{k10_rep.k10_bridges_verified}/45, ualg_bridges=\{k10_rep.ualg_bridges_verified}/9, V5_HF64=\{k10_rep.v5_ackermann_65536_sets_verified}, promotion=\{k10_rep.promotion_pipeline.pipeline_holds}, all_holds=\{k10_rep.all_holds}",
  )
  println("-- K10 Constructive ualg Federation Edges (9/9) --")
  for edge in @bridge.verify_k10_ualg_federation_bridges() {
    let st = if edge.holds { "PASS" } else { "FAIL" }
    println("[\{st}] \{edge.id}: \{edge.bridge_theorem}")
    println("        \{edge.quantitative_witness}")
  }
  println("-- K10 Structural Replacements of Nominal Bridges (6/6) --")
  for edge in @bridge.verify_structural_bridge_replacements() {
    let st = if edge.holds { "PASS" } else { "FAIL" }
    println("[\{st}] \{edge.id}: \{edge.bridge_theorem}")
    println("        \{edge.quantitative_witness}")
  }
  println("-- Nominal-Bridge Elimination, Wave 2 (7/7) --")
  let wave2 = @bridge.verify_nominal_bridge_elimination()
  let mut wave2_ok = 0
  for edge in wave2 {
    let st = if edge.holds { "PASS" } else { "FAIL" }
    if edge.holds {
      wave2_ok = wave2_ok + 1
    }
    println("[\{st}] \{edge.id}: \{edge.bridge_theorem}")
    println("        \{edge.quantitative_witness}")
  }
  let k10_cert_ok = k10_rep.all_holds &&
    k10_rep.ten_federations_verified == 10 &&
    k10_rep.k10_bridges_verified == 45 &&
    k10_rep.ualg_bridges_verified == 9 &&
    wave2_ok == 7
  println(
    "[PASS=\{k10_cert_ok}] bridge/k10: Ten-Federation K_10 Constructive Unification Certificate — 45/45 pairwise bridges, 9 constructive ualg edges, 13 structural replacements of nominal bridges (6 wave-1 + 7 wave-2), atlas=\{atlas_passed}/18",
  )
  let f7_pentad = @bridge.verify_frontier_7pillars_grand_unification()
  println(
    "Stage-3 Seven-Pillar Frontier Pentad (F1×F3×F4×F8×F9): MTT_2Functor=\{f7_pentad.f9_f1_mtt_2functor_embedding_ok}, DualQTT_SWAR=\{f7_pentad.f3_f8_f1_dual_qtt_swar_homomorphism_ok}, QIIT_CwF_Path=\{f7_pentad.f9_f1_qiit_cwf_displayed_path_coherence_ok}, Artin_OrtonPitts=\{f7_pentad.f4_f1_artin_gluing_orton_pitts_canonicity_ok}, Memo_Bidir_Ind=\{f7_pentad.f8_f1_merkle_memo_bidir_inductive_ok} (DAG \{f7_pentad.diamond_dag_unmemoized_visits}->\{f7_pentad.diamond_dag_memoized_visits}, \{f7_pentad.diamond_dag_speedup_ratio}x), all_holds=\{f7_pentad.all_holds}",
  )
  guard all_certs_ok &&
    wiring_ok &&
    unif_ok &&
    accel_rep.all_ok &&
    triad_rep.all_holds &&
    triad_f236.all_holds &&
    autonomy_rep.holds &&
    k9_rep.all_holds &&
    k10_rep.all_holds &&
    k10_cert_ok &&
    wave2_ok == 7 &&
    fed_passed == 10 &&
    f7_pentad.all_holds else {
    abort("showcase failed")
  }
}
