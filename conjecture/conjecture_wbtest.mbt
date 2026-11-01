///|
test "lakatosian conjecture atlas evolution lenses and creative synthesis" {
  let evos = discover_six_evolution_laws()
  assert_eq(evos.length(), 6)
  for e in evos {
    if !(e.target_derived_on_train &&
      e.target_holds_on_transfer &&
      e.mirage_rejected_on_transfer) {
      fail(
        "evolution failed on \{e.family_id}: derived=\{e.target_derived_on_train}, transfer=\{e.target_holds_on_transfer}, mirage=\{e.mirage_rejected_on_transfer}",
      )
    }
  }
  let summary = synthesize_and_verify_conjecture_engine()
  assert_true(summary.all_consistent)
  assert_eq(summary.total_conjectures, 12)
  assert_eq(summary.evolution_families_passed, 6)
}
