// ---------------------------------------------------------------------------
// iit — 定律登記（**由 tools/gen_laws.py 產生，請勿手改**）
// ---------------------------------------------------------------------------
// 每一條定律都是一個 `law_*` 函式；這裡只負責把它們串成一個清單，
// 由 `cmd/metatheory` 逐條執行並印出。要加定律就加 `pub fn law_*`，再跑一次產生器。

///|
/// iit 套件的全部定律。
pub fn all_laws() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  for (l, b) in law_examples_iit_a_finite_mutual_schema_does_stabilize() {
    out.push((l, b))
  }
  for
    (l, b) in law_examples_iit_even_odd_is_plain_mutual_induction_infinite_no_stabilization() {
    out.push((l, b))
  }
  for
    (l, b) in law_examples_iit_index_dependency_graph_is_acyclic_for_all_three_schemas() {
    out.push((l, b))
  }
  for
    (l, b) in law_examples_iit_kleene_chain_is_monotone_and_every_inhabitant_is_well_typed() {
    out.push((l, b))
  }
  for
    (l, b) in law_examples_iit_mutual_eliminator_satisfies_the_iota_law_and_termination_is_certified() {
    out.push((l, b))
  }
  for
    (l, b) in law_examples_iit_nat_fin_index_checking_and_the_one_stage_phase_lag() {
    out.push((l, b))
  }
  for
    (l, b) in law_examples_iit_stlc_tm_indexed_by_ctx_ty_really_needs_cons_in_the_index() {
    out.push((l, b))
  }
  for (l, b) in law_iit_egraph_bidirectional_congruence_and_algebra_coherence() {
    out.push((l, b))
  }
  for (l, b) in law_iit_quotient_equations_hold_and_iota_survives() {
    out.push((l, b))
  }
  for (l, b) in law_iit_quotient_is_well_defined_on_all_stage_inhabitants() {
    out.push((l, b))
  }
  for (l, b) in law_iit_schema_placeholders_are_rejected() {
    out.push((l, b))
  }
  for (l, b) in law_qiit_intrinsic_cwf_and_displayed_eliminator() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_normalization_reaches_a_stuck_value() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_sn_budget_is_three_valued() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_sn_certificates_cover_a_battery() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_sn_depth_is_exact_for_small_terms() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_sn_eta_redex_is_explored() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_sn_measure_decreases_along_every_step() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_sn_reducts_enumerate_all_positions() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_stlc_beta_is_index_preserving() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_stlc_eta_removes_a_trivial_binder() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_subject_reduction_on_a_battery() {
    out.push((l, b))
  }
  for (l, b) in law_stlc_weakening_and_context_insert_are_consistent() {
    out.push((l, b))
  }
  out
}
