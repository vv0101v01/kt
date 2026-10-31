///|
test "six-federation double-v grand unification system and 43-certificate ledger" {
  let rep = run_grand_unification_system()
  assert_true(rep.five_federations_ok)
  assert_eq(rep.federations_verified_count, 5)
  assert_true(rep.k5_pairwise_bridges_ok)
  assert_eq(rep.k5_bridges_verified_count, 10)
  assert_true(rep.five_federation_pentagon_ok)
  assert_true(rep.six_pillar_circle_sphere_ok)
  assert_true(rep.logic_translation_ok)
  assert_true(rep.geometry_logic_atlas_ok)
  assert_eq(rep.atlas_verified_count, 18)
  assert_eq(rep.total_certificates_count, 43)
  assert_eq(rep.total_certificates_passed, 43)
  assert_true(rep.all_ok)
  let feds6 = six_federation_descriptors()
  assert_eq(feds6.length(), 6)
  assert_true(feds6[5].live_health_ok)
}
