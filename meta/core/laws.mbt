// ---------------------------------------------------------------------------
// core — 定律登記（**由 tools/gen_laws.py 產生，請勿手改**）
// ---------------------------------------------------------------------------
// 每一條定律都是一個 `law_*` 函式；這裡只負責把它們串成一個清單，
// 由 `cmd/metatheory` 逐條執行並印出。要加定律就加 `pub fn law_*`，再跑一次產生器。


///| 定律登記：把一個可判定的命題收進報告（全聯邦唯一定義，其他套件用 `@core.chk`）。
pub fn chk(out : Array[(String, Bool)], label : String, cond : Bool) -> Unit {
  out.push((label, cond))
}

///| core 套件的全部定律。
pub fn all_laws() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  for (l, b) in law_algebra_exact_rational_rank() {
    out.push((l, b))
  }
  for (l, b) in law_complex_covers_gluing_criterion_via_h1_of_the_nerve() {
    out.push((l, b))
  }
  for (l, b) in law_complex_f_vector_alternating_sum_is_the_euler_characteristic() {
    out.push((l, b))
  }
  for (l, b) in law_complex_simplicial_complexes_betti_numbers_and_euler_poincar() {
    out.push((l, b))
  }
  for (l, b) in law_matroid_matroid_duality_is_an_involution() {
    out.push((l, b))
  }
  for (l, b) in law_matroid_matroid_greedy_is_optimal_on_a_graphic_matroid() {
    out.push((l, b))
  }
  for (l, b) in law_matroid_matroid_linear_matroid_over_q() {
    out.push((l, b))
  }
  for (l, b) in law_ordinal_ord_max_is_the_lattice_join() {
    out.push((l, b))
  }
  for (l, b) in law_ordinal_ordinal_cnf_laws() {
    out.push((l, b))
  }
  for (l, b) in law_ramsey_ex_paley_graph_gives_r44_ge_18() {
    out.push((l, b))
  }
  for (l, b) in law_ramsey_ex_r44_and_r35_are_pinned_exactly() {
    out.push((l, b))
  }
  for (l, b) in law_ramsey_ex_ramsey_recursion_bound_beats_erdos_szekeres() {
    out.push((l, b))
  }
  for (l, b) in law_ramsey_ex_ramsey_window_is_now_usable_up_to_d3() {
    out.push((l, b))
  }
  for (l, b) in law_ramsey_explicit_3_4_free_coloring_of_k8_is_verified() {
    out.push((l, b))
  }
  for (l, b) in law_ramsey_ramsey_numbers_computed_by_search() {
    out.push((l, b))
  }
  for (l, b) in law_unify_anti_unification_join_dual_of_mgu() {
    out.push((l, b))
  }
  for (l, b) in law_unify_unification_correctness_generality_uniqueness() {
    out.push((l, b))
  }
  out
}
