// ---------------------------------------------------------------------------
// reflect — 定律登記（**由 tools/gen_laws.py 產生，請勿手改**）
// ---------------------------------------------------------------------------
// 每一條定律都是一個 `law_*` 函式；這裡只負責把它們串成一個清單，
// 由 `cmd/metatheory` 逐條執行並印出。要加定律就加 `pub fn law_*`，再跑一次產生器。

///|
/// reflect 套件的全部定律。
pub fn all_laws() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  for (l, b) in law_link_link_instance_proofs_are_checkable_without_search() {
    out.push((l, b))
  }
  for (l, b) in law_nbe_general_beta_over_all_terms() {
    out.push((l, b))
  }
  for (l, b) in law_nbe_nbe_beta_eta_idempotence_type_preservation() {
    out.push((l, b))
  }
  for (l, b) in law_nbe_nf_reaches_a_normal_form() {
    out.push((l, b))
  }
  for (l, b) in law_proof_certificates_are_printable_and_still_check() {
    out.push((l, b))
  }
  for (l, b) in law_proof_reflection_decide_fast_check_independently() {
    out.push((l, b))
  }
  for (l, b) in law_universe_ackermann_bit_isomorphism_and_v5_reflection() {
    out.push((l, b))
  }
  for (l, b) in law_universe_clubs_intersect_by_diagonal_iteration() {
    out.push((l, b))
  }
  for (l, b) in law_universe_finitely_many_formulas_reflect_together() {
    out.push((l, b))
  }
  for (l, b) in law_universe_reflection_levels_form_a_club() {
    out.push((l, b))
  }
  out
}
