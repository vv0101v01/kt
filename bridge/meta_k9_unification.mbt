///|
// Nine-federation active subgraph: 30 comparisons out of 36 historical pairs.
// K9-35 promotion and K9-36 nominal hardware edge are deleted.
// The native Meta law engines remain independently available.

///|
/// Native health plus the exact active nine-federation registry.
/// No theorem-promotion pipeline or complete-graph claim is implied.
#derive(Debug, Eq)
pub(all) struct NineFederationUnificationReport {
  nine_federations_verified : Int32
  k9_bridges_verified : Int32
  v5_ackermann_65536_sets_verified : Bool
  rotation_axis_cert_ok : Bool
  legacy_k5_dispatch_ok : Bool
  all_holds : Bool
}

///|
pub extend NineFederationUnificationReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend NineFederationUnificationReport with Eq::{not_equal, equal}

///|
fn meta_laws_batch_ok(pairs : Array[(String, Bool)]) -> Bool {
  if pairs.length() == 0 {
    return false
  }
  for pair in pairs {
    let (_label, ok) = pair
    if !ok {
      return false
    }
  }
  true
}

///|
/// Fast live health probe for Federation 9 (`meta`: `core` + `instances` + `iit` + `reflect`).
pub fn check_meta_federation_fast_probe() -> Bool {
  meta_laws_batch_ok(@mcore.law_algebra_bareiss64_sylvester_exactness()) &&
  meta_laws_batch_ok(@mcore.law_unify_dag_paterson_wegman_equivalence()) &&
  meta_laws_batch_ok(
    @minstances.law_engine_indexed_tabling_and_orientable_coherence(),
  ) &&
  meta_laws_batch_ok(
    @miit.law_iit_egraph_bidirectional_congruence_and_algebra_coherence(),
  ) &&
  meta_laws_batch_ok(
    @mreflect.law_universe_ackermann_bit_isomorphism_and_v5_reflection(),
  )
}

///|
/// Return all **9 Autonomous Mathematical Federations** (`Cubical`, `Symlib`,
/// `Semiring`, `Topos`, `Scheme`, `Condensed`, `Discovery`, `Accel`, and `Meta`)
/// with live native health probes.
pub fn nine_federation_descriptors(
  accel_precomputed~ : @accel.AccelFederationReport? = None,
) -> Array[FederationDescriptor] {
  let out = seven_federation_descriptors()
  let acc_rep = match accel_precomputed {
    Some(r) => r
    None => @accel.verify_accel_federation()
  }
  out.push(FederationDescriptor::{
    id: Accel,
    slug: "accel",
    packages: ["accel-swar", "accel"],
    canonical_normal_form: "64-Bit SWAR Bitplanes, Dual-Rail GF(3), M4RI GF(2), Stockham RNS-NTT & Portable WGSL",
    categorification_role: "Register-Level Bit-Parallel & Browser-Portable Hardware Realizability Functor",
    live_health_ok: acc_rep.all_ok,
    summary: "L0 64-Bit SWAR Substrate (`accel/swar`) + 6-Pillar CPU/WGSL Exactness (8 static WGSL kernels; no GPU runtime assertion)",
  })
  let meta_ok = check_meta_federation_fast_probe()
  out.push(FederationDescriptor::{
    id: Meta,
    slug: "meta",
    packages: [
      "meta-core", "meta-instances", "meta-iit", "meta-reflect", "cmd-metatheory",
    ],
    canonical_normal_form: "Int64 Sylvester–Bareiss, Paterson–Wegman DAG MGU, SLG Tabling, E-Graph QIIT & Ackermann V_5",
    categorification_role: "Zero-Dependency Constructive Metatheory, Horn Coherence, QIIT & Lévy–Montague Reflection Floor",
    live_health_ok: meta_ok,
    summary: "5-Package Trusted Metatheory Floor (`631/631` Laws, `V_5` = 65,536 HF Sets, E-Graph QIIT & Indexed Tabling)",
  })
  out
}

///|
/// Execute 30 active pairwise comparisons. K8 contributes 7 edges and K9
/// contributes 6, above the 17 active K7 edges. The shared tensor atlas is built
/// once for K7-17, K8-26 and K8-28 (the scalar/SWAR comparison stays independent).
pub fn verify_k9_federation_bridges(
  k7_precomputed~ : Array[FederationPairBridge]? = None,
  atlas_precomputed~ : @tensor.F3Tensor222Atlas? = None,
) -> Array[FederationPairBridge] {
  let atlas = match atlas_precomputed {
    Some(a) => a
    None => @tensor.f3_tensor222_atlas_build()
  }
  let base = match k7_precomputed {
    Some(es) => es.copy()
    None => verify_k7_federation_bridges(atlas_precomputed=Some(atlas))
  }
  // K8-22..K8-28: Federation 8 (`Accel`) ↔ Federations 1..7
  base.push(replace_k8_22_swar_face_bdd())

  base.push(replace_k8_23_s3_axis_invariance_swar())

  base.push(replace_k8_24_tropical_four_way())

  let sieve64_ok = @tsite.verify_sieve64_sip_biheyting_and_mac_equivalence()
  base.push(FederationPairBridge::{
    id: "K8-25",
    lhs: Accel,
    rhs: Topos,
    bridge_theorem: "@accel/swar 64-Bit Bi-Heyting Sieve Primitives ↔ @topos/site Sieve64 SIP Isomorphism",
    holds: sieve64_ok,
    quantitative_witness: "Sieve64_SIP_biHeyting_MAC=\{sieve64_ok}",
  })

  base.push(
    replace_k8_26_segre_cone_point_census(atlas_precomputed=Some(atlas)),
  )

  base.push(replace_k8_27_ozaki_crt_zmat_snf())

  base.push(
    replace_k8_28_bitplane_implication_soundness(atlas_precomputed=Some(atlas)),
  )

  // K9-29..K9-34: six retained Meta comparisons; K9-35/36 are retired.
  base.push(replace_k9_29_stlc_dterm_nbe())

  base.push(replace_k9_30_congruence_orbit_rank())

  base.push(replace_k9_31_horn_kleene_least_model())

  base.push(replace_k9_32_nerve_h1_bareiss())

  base.push(replace_k9_33_macaulay_hilbert_bareiss())

  base.push(replace_k9_34_mobius_glue_rlim_torsion())

  base
}

///|
/// Validate nine native health probes, the exact active registry and separate
/// rotation/legacy checks. Precomputed edge coverage is never inferred from a count.
pub fn verify_k9_meta_discovery_topos_unification(
  k7_precomputed~ : Array[FederationPairBridge]? = None,
  accel_precomputed~ : @accel.AccelFederationReport? = None,
  rotation_precomputed~ : RotationAxisBridgeReport? = None,
  k5_preverified_ok~ : Bool? = None,
  k9_precomputed~ : Array[FederationPairBridge]? = None,
  federations_precomputed~ : Array[FederationDescriptor]? = None,
) -> NineFederationUnificationReport {
  let feds = match federations_precomputed {
    Some(fs) => fs
    None => nine_federation_descriptors(accel_precomputed~)
  }
  let mut feds_ok = 0
  for f in feds {
    if f.live_health_ok {
      feds_ok = feds_ok + 1
    }
  }
  let k9 = match k9_precomputed {
    Some(es) => es
    None => verify_k9_federation_bridges(k7_precomputed~)
  }
  let registry = validate_bridge_registry(k9, federation_count=9)
  let mut k9_ok = 0
  for e in k9 {
    if e.holds {
      k9_ok = k9_ok + 1
    }
  }
  let (v5_rk, v5_cnts) = @mreflect.v5_ackermann_rank_spectrum()
  let v5_ok = v5_rk == 4 &&
    v5_cnts[0] + v5_cnts[1] + v5_cnts[2] + v5_cnts[3] + v5_cnts[4] == 65536
  let rot_cert = rotation_axis_certificate(precomputed=rotation_precomputed)
  let k5_disp = verify_legacy_k5_system_dispatch(
    preverified_ok=k5_preverified_ok,
  )
  let holds = federation_health_valid(feds, 9) &&
    registry.all_holds &&
    v5_ok &&
    rot_cert.ok &&
    k5_disp
  NineFederationUnificationReport::{
    nine_federations_verified: feds_ok,
    k9_bridges_verified: k9_ok,
    v5_ackermann_65536_sets_verified: v5_ok,
    rotation_axis_cert_ok: rot_cert.ok,
    legacy_k5_dispatch_ok: k5_disp,
    all_holds: holds,
  }
}
