///|
test "tensor multilinear radon gauge noncrossing metric hyper laws" {
  let atlas = f3_tensor222_atlas_build()
  assert_eq(atlas.total_tensors, 6561)
  assert_eq(atlas.rank_counts, [1, 128, 4032, 2400])
  assert_true(
    atlas.rank2_det_zero_count > 0 &&
    atlas.rank2_det_nonzero_count > 0 &&
    atlas.rank3_det_zero_count > 0 &&
    atlas.rank3_det_nonzero_count > 0,
  )
  let ghz = t3_of(2, 2, 2, 5, (i, j, k) => if i == j && j == k { 1 } else { 0 })
  assert_eq(t3_hyperdet222(ghz), 1)
  assert_true(t3_check_sl2_shear_and_s3_invariance(ghz))
  assert_eq(t3_flatten_rank_lower_bound(ghz), 2)

  let r3 = radon_make(3, 101)
  let r4 = radon_make(4, 101)
  assert_true(radon_check_gram_identity(r3))
  assert_false(radon_check_gram_identity(r4))
  let f_vec = [1, 2, 0, 3, 1, 4, 2, 0, 1]
  let rf_exact = radon_apply_exact(r3, f_vec)
  let rf_mod = rf_exact.map(v => @gcd.fp_norm(v, 101))
  assert_eq(radon_invert_fp(r3, rf_mod), f_vec)

  let tw_even = twisted_group_clifford_cocycle_report(2, 4)
  let tw_odd = twisted_group_clifford_cocycle_report(2, 3)
  assert_true(tw_even.coboundary_gauge_invariant && tw_even.center_dim == 1)
  assert_true(tw_odd.coboundary_gauge_invariant && tw_odd.center_dim == 2)
  assert_true(clifford_ramond_anticommutator_ok(4, 5))
  assert_true(clifford_ramond_anticommutator_ok(3, 5))
  assert_false(clifford_ramond_anticommutator_ok(2, 3))
  let (flat_c, hol_c, gauge_ok) = lattice_torus_gauge_moduli_verify(2)
  assert_true(gauge_ok && flat_c == 32 && hol_c == 4)

  let flip5 = nc_polygon_triangulations_flip_report(5)
  let flip6 = nc_polygon_triangulations_flip_report(6)
  assert_true(
    flip5.catalan_count == 5 && flip5.flip_edges == 5 && flip5.is_connected,
  )
  assert_true(
    flip6.catalan_count == 14 && flip6.flip_edges == 21 && flip6.is_connected,
  )
  let mono_k4 = [[0, 2, 3, 2], [2, 0, 2, 3], [3, 2, 0, 2], [2, 3, 2, 0]]
  let diag_k4 = [[0, 5, 1, 5], [5, 0, 5, 1], [1, 5, 0, 5], [5, 1, 5, 0]]
  let (m_mono, nc_mono) = nc_mst_vs_unconstrained_mst(4, mono_k4)
  let (m_diag, nc_diag) = nc_mst_vs_unconstrained_mst(4, diag_k4)
  assert_eq(m_mono, nc_mono)
  assert_eq(m_diag, 7)
  assert_eq(nc_diag, 11)
  let (nc4_cnt, site4_ok) = nc_forest_grothendieck_site_ok(4, 7)
  assert_eq(nc4_cnt, 48)
  assert_true(site4_ok)

  assert_true(tensor_check_federation_laws())
}
