// Cross-Federation Hardware-Acceleration Bridge (`@accel` <-> Federations 1, 3, 6, 7):
// Certifies bit-exact equivalence between CPU 64-bit SWAR / RNS-CRT / flat-arena
// kernels + W3C Browser Free WebGPU (`WGSL`) compute shaders and the canonical
// mathematical definitions in `@gcd`, `@face_bdd`, `@algebra`, `@semiring/trop`, `@tensor`.

///|
pub fn verify_accel_hardware_bridge() -> @accel.AccelFederationReport {
  @accel.verify_accel_federation()
}

///|
pub fn accel_hardware_certificate() -> BridgeCertificate {
  let rep = @accel.verify_accel_federation()
  let f3 = @accel.gf3_bitsliced_all_6561_hyperdeterminants()
  let detail = "M4RI_GF2=\{rep.m4ri_gf2_and_rank_ok}, GF3_bitslice_6561=\{f3.singular_det_zero}+\{f3.det_eq_one}+\{f3.det_eq_two}, Face_SWAR=\{rep.face_swar_bdd_sat_ok}, Ozaki2_DP4A_CRT=\{rep.ozaki2_crt_exact_and_fp64_ok}, Stockham_RNS_NTT=\{rep.stockham_rns_ntt_and_mont30_ok}, Scanbox_Tropical=\{rep.scanbox_morton_tropical_ok}, HVM2_INet=\{rep.hvm2_inet_strong_confluence_ok}, WGSL_portable=\{rep.wgsl_browser_kernels_audited}/7"
  bridge_certificate(
    "accel/webgpu+cpu",
    "Frontier CPU SWAR & Browser Free WebGPU (WGSL) 6-Pillar Exactness & Portability Suite",
    rep.all_ok,
    detail~,
  )
}
