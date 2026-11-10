// ---------------------------------------------------------------------------
// instances — 定律登記（**由 tools/gen_laws.py 產生，請勿手改**）
// ---------------------------------------------------------------------------
// 每一條定律都是一個 `law_*` 函式；這裡只負責把它們串成一個清單，
// 由 `cmd/metatheory` 逐條執行並印出。要加定律就加 `pub fn law_*`，再跑一次產生器。

///| instances 套件的全部定律。
pub fn all_laws() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  for (l, b) in law_characterize_axiomatic_fragment_is_a_partition_matroid() {
    out.push((l, b))
  }
  for (l, b) in law_characterize_exchange_axiom_alone_is_too_weak() {
    out.push((l, b))
  }
  for (l, b) in law_characterize_greedy_gives_minimal_not_minimum() {
    out.push((l, b))
  }
  for (l, b) in law_characterize_matroidal_criterion_is_exact() {
    out.push((l, b))
  }
  for (l, b) in law_coherence_complete_checking_needs_no_user_battery() {
    out.push((l, b))
  }
  for (l, b) in law_coherence_extension_stability_is_decided() {
    out.push((l, b))
  }
  for (l, b) in law_coherence_local_instances_are_the_missing_half() {
    out.push((l, b))
  }
  for (l, b) in law_coherence_local_peaks_coincide_with_head_overlaps() {
    out.push((l, b))
  }
  for (l, b) in law_coherence_newman_lemma_measured_on_the_fragment() {
    out.push((l, b))
  }
  for (l, b) in law_compose_instances_derivability_closure_is_matroidal_in_the_flat_case_not_in_general() {
    out.push((l, b))
  }
  for (l, b) in law_compose_instances_gluing_local_sections_the_mobius_obstruction() {
    out.push((l, b))
  }
  for (l, b) in law_compose_instances_minimal_basis_is_minimal_and_greedy_deletion_is_sound() {
    out.push((l, b))
  }
  for (l, b) in law_compose_instances_mirror_is_an_involution_and_gives_dual_derivations() {
    out.push((l, b))
  }
  for (l, b) in law_compose_instances_nerve_cohomology_agrees_with_the_gluing_verdict() {
    out.push((l, b))
  }
  for (l, b) in law_compose_instances_ramsey_window_vs_pigeonhole_window_measured_not_assumed() {
    out.push((l, b))
  }
  for (l, b) in law_compose_mirror_involution_preserves_the_env_fingerprint() {
    out.push((l, b))
  }
  for (l, b) in law_engine_completion_repairs_an_incoherent_env() {
    out.push((l, b))
  }
  for (l, b) in law_engine_completion_uses_a_termination_order() {
    out.push((l, b))
  }
  for (l, b) in law_engine_indexed_tabling_and_orientable_coherence() {
    out.push((l, b))
  }
  for (l, b) in law_engine_instances_overlapping_instances_priority_coherence() {
    out.push((l, b))
  }
  for (l, b) in law_engine_instances_sld_resolution_finds_and_composites_instances() {
    out.push((l, b))
  }
  for (l, b) in law_engine_instances_termination_is_decided_by_ordinal_measure() {
    out.push((l, b))
  }
  for (l, b) in law_engine_module_imports_resolve_modulesly() {
    out.push((l, b))
  }
  for (l, b) in law_engine_sld_resolution_is_complete_within_depth() {
    out.push((l, b))
  }
  out
}
