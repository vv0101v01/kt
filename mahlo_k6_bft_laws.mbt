///|
/// Unified executable law test for Phase 21 Boundaries §4.1, §4.2, and §4.5!
pub fn check_phase21_schema_dsystem_and_frontier_bdd() -> Bool {
  // 1. §4.1: Cantor Normal Form `< epsilon_0`, Mahlo Universe Reflection, & Indexed Container compiler
  let mahlo = verify_mahlo_universe_reflection()
  if !mahlo.strict_rank_descent || !mahlo.closed_under_pi_sigma_path_w {
    return false
  }
  let idx_spec = IndexedContainerSpec::{
    index_ty: DBoolTy,
    shape_ty: DBoolTy,
    pos_ty: DUnitTy,
    next_index: DBoolLit(true),
    requested_index: DTVar(0),
    constructor_out_index: DBoolLit(true),
  }
  let compiled_pf = compile_indexed_container_to_positive_functor(idx_spec)
  match compiled_pf {
    DFunctorSigma(DFunctorConst(DPath(_, _, _)), DFunctorContainer(_, _, idxs)) =>
      if idxs.length() != 1 {
        return false
      }
    _ => return false
  }

  // 2. §4.2A: Sheaf-glued ROBDD partition conversion over `n = 20` boolean variables
  //    (`1,048,576` point cases collapsed to `2` symbolic stalks!)
  let sheaf_conv = conv_sheaf_glued_boolean_partition(20, 0)
  if !sheaf_conv.all_stalks_convertible ||
    sheaf_conv.stalk_count != 2 ||
    sheaf_conv.equivalent_brute_force_cases != 1048576N {
    return false
  }

  // 3. §4.2B: Kernelized Max-Clique on a 36-vertex graph:
  //    6 universal apex vertices + 15 pairs `(u_i, v_i)` where `v_i` forms a `K_8` core (`i=0..7`)
  //    and `u_i` (`i=8..29`) has `N(u_i) subseteq N(v_{i%8})` and `!adj[u_i, v_{i%8}]`!
  //    Total max clique = 6 (apex) + 8 (`K_8` core) = 14, with dominated vertices stripped in O(V^3)!
  let nv = 36
  let adj : Array[Bool] = []
  for _ in 0..<(nv * nv) {
    adj.push(false)
  }
  let set_edge = (a : Int32, b : Int32) => {
    if a != b {
      adj[a * nv + b] = true
      adj[b * nv + a] = true
    }
  }
  // 0..5: universal apex vertices
  for u in 0..<6 {
    for v in 0..<nv {
      set_edge(u, v)
    }
  }
  // 6..13: K_8 clique
  for u in 6..<14 {
    for v in (u + 1)..<14 {
      set_edge(u, v)
    }
  }
  // 14..35: 22 dominated peripheral vertices (`u` connects only to a strict subset of `6 + (u % 8)`'s neighbors, NOT to `6 + (u % 8)`)
  for u in 14..<nv {
    let target = 6 + u % 8
    for w in 6..<14 {
      if w != target && (w + u) % 2 == 0 {
        set_edge(u, w)
      }
    }
  }
  let k_rep = dsystem_kernelized_max_clique(nv, adj)
  if !k_rep.valid_clique ||
    k_rep.universal_extracted < 6 ||
    k_rep.dominated_eliminated < 22 ||
    k_rep.max_clique_size != 14 {
    return false
  }

  // 4. §4.2C: Non-Abelian Figure-Eight `S^1 v S^1` (`pi_1 = F_2`) square filler vs Torus `[a, b]`:
  //    Boundary word around square is `left * bottom * right^{-1} * top^{-1}`:
  //    - Commutator square (`left = [a], bottom = [b], right = [a], top = [b]` -> `a * b * a^{-1} * b^{-1}`):
  //      fills in Torus (`wa=0, wb=0`) but REFUSED in `S^1 v S^1` (`reduced = [1, 2, -1, -2]`)!
  //    - Genuine cancelling square (`left = [a, b], bottom = [], right = [b], top = [a]` -> `a * b * b^{-1} * a^{-1} = 1`):
  //      fills in BOTH `S^1 v S^1` AND `T^2`!
  let comm_sq = wedge_square_filler_report([2], [2], [1], [1])
  let cancel_sq = wedge_square_filler_report([1], [], [1, 2], [2])
  if comm_sq.fills_in_wedge_s1_s1 ||
    !comm_sq.fills_in_abelianized_torus ||
    comm_sq.reduced_f2_boundary_word != [1, 2, -1, -2] {
    return false
  }
  if !cancel_sq.fills_in_wedge_s1_s1 || !cancel_sq.fills_in_abelianized_torus {
    return false
  }

  // 5. §4.5A: Connected `chain22` AND `chain26` (`26` coupled variables, `2^{26} = 67,108,864` states!)
  //    solved via `[T-Frontier-ROBDD]` with `connected_components == 1`, `frontier_cutwidth == 1`,
  //    and exact Fibonacci-complement model counts `2^{22} - F_{24} = 4,147,936` & `2^{26} - F_{28} = 66,791,053`!
  let build_chain = (m : Int32) => {
    let mut acc : Face = FBot
    for i in 0..<(m - 1) {
      let lk = FAnd(FEq1(DVar(i)), FEq1(DVar(i + 1)))
      acc = if i == 0 { lk } else { FOr(acc, lk) }
    }
    acc
  }
  let f_chain22 = build_chain(22)
  let f_chain26 = build_chain(26)
  let fb22 = bdd_dag_of_face_frontier_treewidth(f_chain22, 22)
  let fb26 = bdd_dag_of_face_frontier_treewidth(f_chain26, 26)
  if fb22.connected_components != 1 ||
    fb22.frontier_cutwidth != 1 ||
    fb22.sat_count != 4147936N ||
    fb22.essential_vars_lower_bound != 24 {
    return false
  }
  if fb26.connected_components != 1 ||
    fb26.frontier_cutwidth != 1 ||
    fb26.sat_count != 66791053N ||
    fb26.essential_vars_lower_bound != 28 ||
    fb26.reachable_nodes > 54 {
    return false
  }

  // 6. §4.5B: `O(1)` Generic-Point Semantic `24`-Cube Reification (`2^{24} = 16,777,216` vertices
  //    bypassed in `eval_calls == 1`!):
  //    Reify two De Morgan equivalent `24`-cubes on `Circle`:
  //      cube_a(d_0..d_23) = loop(d_0 ∧ (d_12 ∨ (d_0 ∧ d_12)))
  //      cube_b(d_0..d_23) = loop(d_0 ∧ d_12)
  //    Each takes `1` generic evaluation (`eval_calls == 1`) and `checked_dcube_extensional_eq`
  //    proves universal equality across all `16,777,216` vertices in `O(1)`!
  let mut calls_a = 0
  let (opt_ca, c1) = reify_natural_dcube_symbolic_o1(
    24,
    DVCircleTy,
    denv_empty(),
    denv_empty(),
    ddim_empty(),
    dims => {
      calls_a = calls_a + 1
      let r = DAnd(dims[0], DOr(dims[12], DAnd(dims[0], dims[12])))
      deval_dim(DAppDim(DCircleLoop, r), denv_empty(), ddim_empty())
    },
  )
  let (opt_cb, c2) = reify_natural_dcube_symbolic_o1(
    24,
    DVCircleTy,
    denv_empty(),
    denv_empty(),
    ddim_empty(),
    dims => {
      let r = DAnd(dims[0], dims[12])
      deval_dim(DAppDim(DCircleLoop, r), denv_empty(), ddim_empty())
    },
  )
  guard (opt_ca, opt_cb) is (Some(ca), Some(cb)) else { return false }
  calls_a == 1 && c1 == 1 && c2 == 1 && checked_dcube_extensional_eq(ca, cb)
}

///|
/// Master Phase 21 verification for Boundaries §4.6, §4.7, and §4.3!
pub fn check_phase21_homotopy_hou_and_bft_mvcc() -> Bool {
  // 1. §4.6A: Stasheff `K_6` combinatorics (`C_5 = 42`, `f = [42, 84, 56, 14, 1]`, `chi = 1`)
  //    + `6`-stage `dpath_singleton_n_transport_value` coherence on nontrivial `Circle` loops!
  if catalan(5) != 42 ||
    assoc_fvector(6) != [42, 84, 56, 14, 1] ||
    assoc_euler_characteristic(6) != 1 ||
    !paren_rotation_graph_connected(6) {
    return false
  }
  let s1_ty = circle_hit_type_value()
  let base_v = circle_hit_base_value()
  let lp = circle_hit_loop_path_value()
  let inv_lp = dpath_sym_value(lp)
  let coh6 = dpath_associahedron_k6_coherence_value(
    s1_ty, base_v, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  // Verify endpoints of 5-cell `coh6` (`I^5 -> Circle`, 6-path coherence!) match `hemi_north4` at `0` and `hemi_south4` at `1`!
  let end0 = dapp_dim(coh6, DZero)
  let end1 = dapp_dim(coh6, DOne)
  let want_n4 = dpath_k6_hemi_north4_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let want_s4 = dpath_k6_hemi_south4_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let path1_ty = DVPathTy(_ => s1_ty, base_v, base_v)
  let lhs6 = dpath_k6_lhs1_value(s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2)
  let rhs6 = dpath_k6_rhs1_value(s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2)
  let path2_ty = DVPathTy(_ => path1_ty, lhs6, rhs6)
  let rn2 = dpath_k6_route_north2_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let rs2 = dpath_k6_route_south2_value(
    s1_ty, lp, inv_lp, lp, lp, inv_lp, lp, 2,
  )
  let path3_ty = DVPathTy(_ => path2_ty, rn2, rs2)
  if !conv_at(0, 0, path3_ty, end0, want_n4) ||
    !conv_at(0, 0, path3_ty, end1, want_s4) {
    return false
  }

  // 2. §4.6B: Variable-endpoint HITs (`PropTruncBool` squash & `SuspBool` meridians)
  if !check_variable_endpoint_hits() {
    return false
  }

  // 3. §4.6C: Condensed Steenrod–Adams `2*eta = 0` (`Ext_A^{2,3}(F_2, F_2) = 0`)
  //    locked to geometric Brunerie `beta_3 -> NormalisesTo(-2)` (`|beta_3| = 2`, `pi_4(S^3) = Z/2Z`) + Serre Hopf!
  let adams = @condensed.adams_ext_f2_report(8, 3, 8)
  let serre = @condensed.serre_hopf_fibration_report(5)
  let b_fam = brunerie_new_family()
  let beta3_val = match b_fam[2].norm {
    NormalisesTo(v) => v
    _ => 0
  }
  let beta_abs = if beta3_val < 0 { -beta3_val } else { beta3_val }
  if adams.hopf_h1_ext12 != 1 ||
    adams.two_eta_ext23 != 0 ||
    !serre.converges_to_s3 ||
    beta_abs != 2 ||
    !brunerie_norm_establishes(beta3_val) ||
    pi4_s3_group(beta3_val) != fg_zmod(2) {
    return false
  }

  // 4. §4.7A: Higher-order inner-`λ` matching (`hou_match_higher_order_lambda`):
  //    Case A (Arrow return type): `?F a == \z. h a z` (`extra_return_types = [B]`) -> `F = \x. \z. h x z`!
  //    Case B (Second-order spine + inner lambda): `?F (\g. g (g c)) == f (f c)` -> `F = \H. H (\x. f x)`!
  let u = unifier_new()
  let b_ty = UType(0)
  let arrow_res = hou_match_higher_order_lambda(
    u,
    [UConst("a")],
    ULam(b_ty, UApp(UApp(UConst("h"), UConst("a")), UVar(0))),
    [b_ty],
    [b_ty],
    size_bound=5,
    inner_lambda_budget=0,
  )
  match arrow_res {
    HouMatchSolved(_) => ()
    _ => return false
  }
  // `\g. g (g c)` has `UVar(0) = g`: `ULam(UPi(b_ty, b_ty), UApp(UVar(0), UApp(UVar(0), UConst("c"))))`
  let ho_arg = ULam(UPi(b_ty, b_ty), UApp(UVar(0), UApp(UVar(0), UConst("c"))))
  let ho_rhs = UApp(UConst("f"), UApp(UConst("f"), UConst("c")))
  let inner_lam_res = hou_match_higher_order_lambda(
    u,
    [ho_arg],
    ho_rhs,
    [UPi(UPi(b_ty, b_ty), b_ty)],
    [],
    size_bound=6,
    inner_lambda_budget=1,
  )
  match inner_lam_res {
    HouMatchSolved(_) => ()
    _ => return false
  }

  // 5. §4.7B: Goldfarb (1981) second-order Diophantine multiplication compiler (`2 * 3 = 6`, `3 * 4 = 12`)
  let gf23 = goldfarb_verify_diophantine_encoding(2, 3)
  let gf34 = goldfarb_verify_diophantine_encoding(3, 4)
  if !gf23.commutes_with_succ_a ||
    !gf23.addition_eq_holds ||
    !gf23.multiplication_eq_holds ||
    !gf23.wrong_product_refuted ||
    !gf34.multiplication_eq_holds ||
    gf34.c_prod != 12 {
    return false
  }

  // 6. §4.3A: RFC 8032 Ed25519 BFT Quorum + `ArtifactWalStore` + `@hostfs` BFT Crash Durability
  let bft_ed = bft_ed25519_quorum_commit_to_wal()
  if bft_ed.valid_signatures != 3 ||
    !bft_ed.forged_signature_rejected ||
    !bft_ed.wal_committed_and_recovered ||
    !bft_ed.condensed_ledger_verified ||
    !bft_check_consensus_and_crash_durability() {
    return false
  }

  // 7. §4.3B: Tarjan SCC + Atomic MVCC Hot-Load on cyclic mutual recursion
  //    Graph: `Core` (0, leaf), `ModEven` (1 -> [0, 2]), `ModOdd` (2 -> [1]), `App` (3 -> [1, 2])
  //    Tarjan SCCs in dependency-first order: `[["Core"], ["ModOdd", "ModEven"], ["App"]]` (3 SCCs, one size-2 cycle!)
  let mod_names = ["Core", "ModEven", "ModOdd", "App"]
  let mod_adj = [[], [0, 2], [1], [1, 2]]
  let sccs = hot_load_tarjan_scc(mod_names, mod_adj)
  if sccs.length() != 3 ||
    sccs[0] != ["Core"] ||
    sccs[1].length() != 2 ||
    sccs[2] != ["App"] {
    return false
  }
  let mvcc0 = HotLoadMvccStore::{
    snapshots: [
      HotLoadMvccSnapshot::{
        epoch: 0,
        modules: [("Core", 1), ("ModEven", 1), ("ModOdd", 1), ("App", 1)],
        scc_groups: sccs,
      },
    ],
  }
  // Failed typecheck rolls back cleanly without creating epoch 1
  let (mvcc_fail, ok_fail) = hot_load_mvcc_commit_atomic(
    mvcc0,
    mod_names,
    mod_adj,
    [("ModEven", 2)],
    false,
  )
  if ok_fail || mvcc_fail.snapshots.length() != 1 {
    return false
  }
  // Valid atomic SCC swap creates epoch 1 while pinned reader on epoch 0 still sees version 1!
  let (mvcc1, ok1) = hot_load_mvcc_commit_atomic(
    mvcc0,
    mod_names,
    mod_adj,
    [("ModEven", 2), ("ModOdd", 2), ("App", 2)],
    true,
  )
  ok1 &&
  hot_load_mvcc_read(mvcc1, 0, "ModEven") == Some(1) &&
  hot_load_mvcc_read(mvcc1, 1, "ModEven") == Some(2) &&
  hot_load_mvcc_read(mvcc1, 1, "ModOdd") == Some(2)
}
