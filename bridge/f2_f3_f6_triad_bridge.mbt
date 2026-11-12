///|
// Cross-Federation Triad Bridge: Federation 2 (`symlib`) × Federation 3 (`semiring`)
// × Federation 6 (`gcd` + `condensed`).
//
// Machine-certifies the `T1–T4` architectural, hardware-SWAR, and P-time upgrades:
//   1. F2 (`symlib` + `symlib/core`): Holt coset-pruned complete subgroup conjugacy
//      lattice on `A_5(60)` (`9` classes) & `B_3(48)` (`33` classes incl. 3-generated `(C_2)^3`),
//      Burnside Möbius orbit-type solver `burnside_mobius_solve`, unbounded-degree `PermLut`
//      on `n = 16 > 12`, and non-thin Groupoid Yoneda `Nat(Hom_BG(-,0), F) ≅ F(0)`;
//   2. F3 (`semiring`): `wasm-gc`-portable `verify_semiring_wasm_suite` covering 64-bit
//      Four-Russians `mul_bool_swar`, `@swar` M4RI `mul_gf2_m4ri_swar`, `closure_bool_swar`,
//      `closure_trop_swar`, 3D ridge gift-wrapping `BPoly::subdivision`, Karp `λ(A)` +
//      critical eigenvector, Johnson negative-edge APSP, Min-Fill `bp_exact_all_marginals_ve`,
//      and Hopcroft–Valmari `O(|Σ||Q|log|Q|)` minimal DFA;
//   3. F6 (`gcd` + `condensed` + `condensed/core`): Domich–Kannan–Trotter modular HNF,
//      Bareiss fraction-free determinant, Havas–Majewski–Matthews SNF, constructive
//      Nöbeling unimodular basis `C(S, Z) ≅ ⨁ Z`, Smith coinvariants `coinvariants_zmat_endomorphism`,
//      and `64×` `@swar` Steenrod–Adams `Ext_A` up to `h_3 = σ` & `h_1^3 = h_0^2 h_2`;
//   4. Cross-federation Cayley–Semiring–SNF triad invariant on `A_4`.

///|
/// Cross-federation verification report for Federations 2 × 3 × 6.
#derive(Debug, Eq)
pub(all) struct F2F3F6TriadBridgeReport {
  a5_subgroup_classes : Int32
  b3_subgroup_classes : Int32
  burnside_mobius_exact_ok : Bool
  nonthin_groupoid_yoneda_ok : Bool
  deg16_permlut_cayley_ok : Bool
  semiring_wasm_suite_ok : Bool
  modular_hnf_snf_ok : Bool
  nobeling_solid_duality_ok : Bool
  adams_h3_sigma_and_eta3_ok : Bool
  cayley_semiring_snf_triad_ok : Bool
  all_holds : Bool
}

///|
pub extend F2F3F6TriadBridgeReport with @debug.Debug::{to_repr}

///|
pub extend F2F3F6TriadBridgeReport with Eq::{not_equal, equal}

///|
/// Execute the complete F2 × F3 × F6 triad bridge audit.
pub fn verify_f2_f3_f6_triad_bridge() -> F2F3F6TriadBridgeReport {
  // 1. F2 (`symlib`): A_5 (order 60 -> 9 classes), B_3 (order 48 -> 33 classes), Burnside Möbius
  let a5 = @sym.PermGroup::alternating(5)
  let a5_subs = @sym.subgroup_classes(a5, 120)
  let (mc_a, mc_b, mc_c, a5_ns, a5_ord) = @sym.marks_cert(a5, 120)
  let a5_tom = @sym.table_of_marks(a5, a5_subs, 120)
  let gs_a5_pts = @sym.gset_points(a5, 120)
  let gs_a5_pairs = @sym.gset_pairs(a5, 120)
  let burnside_ok = mc_a &&
    mc_b &&
    mc_c &&
    a5_ord == 60L &&
    a5_ns == 9 &&
    (match
      @sym.burnside_mobius_solve(a5_tom, @sym.mark_vector(gs_a5_pts, a5_subs)) {
      None => false
      Some(mults) => {
        // Transitive 5-point action of A_5 = single orbit A_5 / A_4 (index 7 in sorted 9 classes)
        let mut sum_orbits = 0
        let mut card_recon = 0L
        for j in 0..<mults.length() {
          sum_orbits = sum_orbits + mults[j]
          card_recon = card_recon +
            mults[j].to_int64() * (60L / a5_subs[j].order)
        }
        sum_orbits == 1 && card_recon == 5L
      }
    }) &&
    (match
      @sym.burnside_mobius_solve(a5_tom, @sym.mark_vector(gs_a5_pairs, a5_subs)) {
      None => false
      Some(mults2) => {
        // Ordered pairs V × V (5 × 5 = 25): A_5 is 2-transitive => 2 orbits: diagonal (size 5, A_5/A_4) + off-diagonal (size 20, A_5/C_3)
        let mut sum_o2 = 0
        let mut card2 = 0L
        for j in 0..<mults2.length() {
          sum_o2 = sum_o2 + mults2[j]
          card2 = card2 + mults2[j].to_int64() * (60L / a5_subs[j].order)
        }
        sum_o2 == 2 && card2 == 25L
      }
    })

  // B_3 hyperoctahedral group of cube (order 48, degree 6 on ±axes, contains 3-gen (C_2)^3!)
  let b3 = @sym.PermGroup::hyperoctahedral(3)
  let (b3_a, b3_b, b3_c, b3_ns, b3_ord) = @sym.marks_cert(b3, 120)
  let b3_ok = b3_a && b3_b && b3_c && b3_ord == 48L && b3_ns == 33

  // Non-thin Groupoid Yoneda on BG = cat_group(S_3) (|Hom(0, 0)| = 6 > 1!)
  let s3 = @sym.PermGroup::symmetric(3)
  let p_s3 = @sym.presheaf_from_gset(s3, @sym.gset_points(s3, 24), 24)
  let ya_s3 = @sym.representable_presheaf(p_s3.cat, 0)
  let e0_nat = @sym.gen_yoneda_extend(p_s3, 0, 1)
  let yoneda_ok = ya_s3.size[0] == 6 &&
    @sym.presheaf_nat_is_natural(ya_s3, p_s3, e0_nat) &&
    @sym.gen_yoneda_eval(p_s3, 0, e0_nat) == 1 &&
    @sym.verify_general_yoneda_bijection(p_s3, 0, 5000)

  // Unbounded-degree PermLut at degree n = 16 (> 12!)
  let c16 = @sym.PermGroup::cyclic(16)
  let cay16 = @sym.cayley_graph(c16, 32)
  let bg16 = @sym.cat_group(c16, 32)
  let reg16 = @sym.regular_perm(c16, 32, c16.generators()[0])
  let deg16_ok = cay16.order() == 16 && bg16.nmor == 16 && !reg16.is_identity()

  // 2. F3 (`semiring`): Full wasm-gc portable suite + DAG free category SetMat coproduct
  let dag3 = @scat.DiGraph::new(3)
  dag3.edge(0, 1)
  dag3.edge(1, 2)
  let sm = dag3.hom_setmat()
  let sm_coprod = @scat.smat_plus(sm, sm)
  let semi_ok = @sapp.verify_semiring_wasm_suite() &&
    sm_coprod.get(0, 2).length() == 2

  // 3. F6 (`gcd` + `condensed`): Modular HNF, Bareiss, Nöbeling basis, Smith coinvariants, 64x Adams Ext_A
  let m_hnf1 = @gcd.zmat_from_int_rows([[2, 1], [0, 3]])
  let m_hnf2 = @gcd.zmat_from_int_rows([
    [4, 6, 10],
    [6, 15, 21],
    [2, 9, 13],
    [8, 12, 23],
  ])
  let snf2 = @gcd.zmat_snf(m_hnf2)
  let hnf_ok = @gcd.zmat_hnf_modular(m_hnf1) == @gcd.zmat_hnf(m_hnf1) &&
    @gcd.zmat_hnf_modular(m_hnf2) == @gcd.zmat_hnf(m_hnf2) &&
    @gcd.zmat_det_bareiss(m_hnf1) == 6N &&
    @gcd.zmat_snf_verify(m_hnf2, snf2)

  let t_cantor4 = @condensed.compact_tower_cantor(4)
  let t_padic3 = @condensed.compact_tower_padic(3, 3)
  let cp_cantor4 = @condensed.compact_tower_to_cond_profinite(t_cantor4, 5)
  let (lim0_id, tor_id) = @condensed.coinvariants_zmat_endomorphism(
    @gcd.zmat_from_int_rows([[1]]),
  )
  let (lim0_m3, tor_m3) = @condensed.coinvariants_zmat_endomorphism(
    @gcd.zmat_from_int_rows([[3]]),
  )
  let nobeling_ok = @condensed.cond_prof_valid(cp_cantor4) &&
    @condensed.verify_nobeling_free_solid_duality(t_cantor4) &&
    @condensed.verify_nobeling_free_solid_duality(t_padic3) &&
    lim0_id == 1 &&
    tor_id == [] &&
    lim0_m3 == 0 &&
    tor_m3 == [2N]

  let adams = @condensed.adams_ext_swar_frontier_report()
  let adams_ok = adams.hopf_h0_ext11 == 1 &&
    adams.hopf_h1_ext12 == 1 &&
    adams.hopf_h2_ext14 == 1 &&
    adams.hopf_h3_ext18 == 1 &&
    adams.adem_non_pow2_vanish &&
    adams.eta_nu_zero_ext26 == 0 &&
    adams.nu_sq_ext28 == 1 &&
    adams.eta_cubed_eq_4nu_ext36 == 1

  // 4. Cross-Federation Triad Isomorphism (F2 A_4 Cayley × F3 Boolean/Tropical Closure × F6 Laplacian SNF)
  let a4 = @sym.PermGroup::alternating(4)
  let cay_a4 = @sym.cayley_graph(a4, 32)
  let n_v = cay_a4.order() // 12
  let bool_adj = @smat.Mat::new(n_v, n_v, @semialg.BoolSr::of(false))
  let lap_rows : Array[Array[Int32]] = Array::makei(n_v, i => {
    Array::makei(n_v, j => {
      if i == j {
        cay_a4.degree(i)
      } else if cay_a4.has_edge(i, j) {
        bool_adj.set(i, j, @semialg.BoolSr::of(true))
        -1
      } else {
        0
      }
    })
  })
  let (_, reach_pairs) = @smat.closure_bool_swar(bool_adj)
  let lap_snf = @gcd.zmat_snf(@gcd.zmat_from_int_rows(lap_rows))
  // Connected 12-vertex Cayley graph <=> all 12*12 = 144 pairs reachable in Boolean SWAR closure
  // <=> integral combinatorial Laplacian has corank 1 (rank == 11)!
  let triad_iso_ok = n_v == 12 && reach_pairs == 144 && lap_snf.rank == 11

  let all_holds = burnside_ok &&
    b3_ok &&
    yoneda_ok &&
    deg16_ok &&
    semi_ok &&
    hnf_ok &&
    nobeling_ok &&
    adams_ok &&
    triad_iso_ok

  F2F3F6TriadBridgeReport::{
    a5_subgroup_classes: a5_ns,
    b3_subgroup_classes: b3_ns,
    burnside_mobius_exact_ok: burnside_ok,
    nonthin_groupoid_yoneda_ok: yoneda_ok,
    deg16_permlut_cayley_ok: deg16_ok,
    semiring_wasm_suite_ok: semi_ok,
    modular_hnf_snf_ok: hnf_ok,
    nobeling_solid_duality_ok: nobeling_ok,
    adams_h3_sigma_and_eta3_ok: adams_ok,
    cayley_semiring_snf_triad_ok: triad_iso_ok,
    all_holds,
  }
}
