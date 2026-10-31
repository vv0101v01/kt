///|
test "condensed federation: 4 condensed higher structures, 2 categories, adams/serre/koszul, ledger, and 4 conjectures" {
  assert_true(cond_check_structures_1_2_and_category_1())
  assert_true(cond_check_structure_3_and_spectral_homotopy())
  assert_true(cond_check_structure_4_category_2_ledger_and_conjectures())
  assert_true(cond_check_federation_all())
}
