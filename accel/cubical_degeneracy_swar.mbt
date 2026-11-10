///|
// Cross-Federation Cubical Degeneracy Face Pruning & Portable WGSL Verification

///|
/// Bidirectional SWAR face pruning under an ambient cofibration `ambient`:
///   1. top-down cofactor mask `restricted = face_word & ambient_word`;
///   2. bottom-up degeneracy elimination computing `(restricted, essential_axes_mask, model_count)`.
pub fn cube64_bidirectional_face_prune(
  face : @face_bdd.Face,
  ambient : @face_bdd.Face,
  dim : Int32,
) -> (UInt64, UInt64, Int32) {
  let active = cube64_active_mask(dim)
  let wf = face_truth_word64(face, dim) & active
  let wa = face_truth_word64(ambient, dim) & active
  let restricted = wf & wa
  let deg = cube64_degeneracy_mask(restricted, dim)
  let essential = (deg ^ ((1UL << dim) - 1UL)) & ((1UL << dim) - 1UL)
  (restricted, essential, swar_popcount64(restricted))
}

///|
/// Zero-extension browser-portable 32-bit WGSL compute kernel for batch 64-vertex
/// cubical degeneracy detection & face pruning (emulating 64-bit cubes via `vec2<u32>`
/// `(lo32, hi32)` and `16 × 17` conflict-free workgroup tile).
pub fn wgsl_kernel_cubical_degeneracy_prune() -> WgslComputeKernel {
  let src =
    #|struct CubeWord64 {
    #|  lo : u32,
    #|  hi : u32,
    #|}
    #|@group(0) @binding(0) var<storage, read> cubes_in : array<CubeWord64>;
    #|@group(0) @binding(1) var<storage, read> ambient_mask : array<CubeWord64>;
    #|@group(0) @binding(2) var<storage, read_write> deg_flags_out : array<u32>;
    #|var<workgroup> tile_pad : array<vec2<u32>, 272>;
    #|@compute @workgroup_size(64, 1, 1)
    #|fn main(@builtin(global_invocation_id) gid : vec3<u32>, @builtin(local_invocation_id) lid : vec3<u32>) {
    #|  let idx : u32 = gid.x;
    #|  let row : u32 = lid.x >> 4u;
    #|  let col : u32 = lid.x & 15u;
    #|  let slot : u32 = row * 17u + col;
    #|  let c : CubeWord64 = cubes_in[idx];
    #|  let a : CubeWord64 = ambient_mask[idx];
    #|  let w_lo : u32 = c.lo & a.lo;
    #|  let w_hi : u32 = c.hi & a.hi;
    #|  tile_pad[slot] = vec2<u32>(w_lo, w_hi);
    #|  workgroupBarrier();
    #|  let v : vec2<u32> = tile_pad[slot];
    #|  var deg : u32 = 0u;
    #|  if (((v.x ^ (v.x >> 1u)) & 0x55555555u) == 0u && ((v.y ^ (v.y >> 1u)) & 0x55555555u) == 0u) { deg = deg | 1u; }
    #|  if (((v.x ^ (v.x >> 2u)) & 0x33333333u) == 0u && ((v.y ^ (v.y >> 2u)) & 0x33333333u) == 0u) { deg = deg | 2u; }
    #|  if (((v.x ^ (v.x >> 4u)) & 0x0F0F0F0Fu) == 0u && ((v.y ^ (v.y >> 4u)) & 0x0F0F0F0Fu) == 0u) { deg = deg | 4u; }
    #|  if (((v.x ^ (v.x >> 8u)) & 0x00FF00FFu) == 0u && ((v.y ^ (v.y >> 8u)) & 0x00FF00FFu) == 0u) { deg = deg | 8u; }
    #|  if (((v.x ^ (v.x >> 16u)) & 0x0000FFFFu) == 0u && ((v.y ^ (v.y >> 16u)) & 0x0000FFFFu) == 0u) { deg = deg | 16u; }
    #|  if (v.x == v.y) { deg = deg | 32u; }
    #|  deg_flags_out[idx] = deg;
    #|}
  {
    slug: "cubical_degeneracy_prune_u32x2",
    paper_family: "SWAR Cubical Degeneracy Bitboard & Moore Boundary Pruning (arXiv:2410.09939 / arXiv:2207.12500)",
    workgroup_size: (64, 1, 1),
    shared_mem_bytes: 2176,
    uses_subgroups: false,
    wgsl_source: src,
  }
}

///|
/// Comprehensive verification report for the 64-bit SWAR cubical degeneracy,
/// butterfly face/degeneracy, Moore `∂² = 0`, and portable WGSL kernel suite.
#derive(Debug, Eq)
pub(all) struct CubicalSwarDegeneracyReport {
  all_65536_4cubes_pair_o1_exact : Bool
  nondegenerate_4cubes_count : Int32
  degenerate_4cubes_count : Int32
  butterfly_matches_ref_all_dims : Bool
  cubical_face_degeneracy_identities_ok : Bool
  moore_boundary_squared_zero_ok : Bool
  degenerate_subcomplex_closed_ok : Bool
  bidirectional_face_prune_ok : Bool
  wgsl_kernel_browser_portable : Bool
  all_ok : Bool
}

///|
pub extend CubicalSwarDegeneracyReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend CubicalSwarDegeneracyReport with Eq::{not_equal, equal}

///|
/// Verify all 64-bit SWAR cubical degeneracy, butterfly face/degeneracy,
/// Moore chain boundary `∂² = 0`, and WGSL browser-portability invariants.
pub fn verify_cubical_swar_degeneracy_suite() -> CubicalSwarDegeneracyReport {
  // 1. Precompute all 256 3-cube degeneracy masks, then sweep all 65,536 4-cubes
  //    checking O(1) paired update vs direct 4D SWAR mask bit-for-bit!
  let deg3 = Array::make(256, 0UL)
  for w in 0..<256 {
    deg3[w] = cube64_degeneracy_mask(w.to_uint64(), 3)
  }
  let mut pair_exact = true
  let mut nondeg4 = 0
  let mut deg4 = 0
  for a in 0..<256 {
    let wa = a.to_uint64()
    let da = deg3[a]
    for b in 0..<256 {
      let wb = b.to_uint64()
      let (w4, d4_o1) = cube64_pair_degeneracy_o1(wa, da, wb, deg3[b], 3)
      let d4_direct = cube64_degeneracy_mask(w4, 4)
      if d4_o1 != d4_direct {
        pair_exact = false
      }
      if d4_o1 == 0UL {
        nondeg4 = nondeg4 + 1
      } else {
        deg4 = deg4 + 1
      }
    }
  }

  // 2. Verify SWAR butterfly face extraction == vertex-by-vertex reference,
  //    and cubical face/degeneracy identities across dimensions 2..6
  let probes : Array[UInt64] = [
    0UL, 0xFFFFFFFFFFFFFFFFUL, 0xA5C3F0961E874B2DUL, 0x123456789ABCDEF0UL, 0x8000000000000001UL,
    0x0F0F33335555AAAAUL,
  ]
  let mut bfly_ok = true
  let mut ident_ok = true
  let mut boundary_sq_ok = true
  let mut deg_closed_ok = true

  for dim in 2..<=6 {
    for p in probes {
      let w = p & cube64_active_mask(dim)
      for axis in 0..<dim {
        for ep in 0..<2 {
          let f_swar = cube64_extract_face_swar(w, dim, axis, ep)
          let f_ref = cube64_extract_face_ref(w, dim, axis, ep)
          if f_swar != f_ref {
            bfly_ok = false
          }
        }
        // Check ∂_{axis, ep}(σ_axis(sub)) == sub and bit `axis` set in deg_mask(σ_axis(sub))
        let sub = p & cube64_active_mask(dim - 1)
        let expanded = cube64_insert_degeneracy_swar(sub, dim, axis)
        let f0 = cube64_extract_face_swar(expanded, dim, axis, 0)
        let f1 = cube64_extract_face_swar(expanded, dim, axis, 1)
        let exp_deg = cube64_degeneracy_mask(expanded, dim)
        if f0 != sub || f1 != sub || ((exp_deg >> axis) & 1UL) == 0UL {
          ident_ok = false
        }
        // Degenerate subcomplex closure: ∂_dim(σ_axis(sub)) has only degenerate terms!
        let d_exp = cube64_alternating_boundary_zchain(expanded, dim)
        for (term_w, _) in d_exp {
          if cube64_degeneracy_mask(term_w, dim - 1) == 0UL {
            deg_closed_ok = false
          }
        }
      }
      // Simplicial/cubical face commutation: for i < j, ∂_{i,α}(∂_{j,β}(w)) == ∂_{j-1,β}(∂_{i,α}(w))
      for i in 0..<dim {
        for j in (i + 1)..<dim {
          for a_ep in 0..<2 {
            for b_ep in 0..<2 {
              let lhs = cube64_extract_face_swar(
                cube64_extract_face_swar(w, dim, j, b_ep),
                dim - 1,
                i,
                a_ep,
              )
              let rhs = cube64_extract_face_swar(
                cube64_extract_face_swar(w, dim, i, a_ep),
                dim - 1,
                j - 1,
                b_ep,
              )
              if lhs != rhs {
                ident_ok = false
              }
            }
          }
        }
      }
      // Moore differential ∂_{dim-1}(∂_dim(w)) == 0 (empty normalized Z-chain)
      let d1 = cube64_alternating_boundary_zchain(w, dim)
      let d2 = cube64_chain_boundary(d1, dim - 1)
      if d2.length() != 0 {
        boundary_sq_ok = false
      }
    }
  }

  // 3. Bidirectional face pruning: under ambient `(i0 = 0)`, `(i0 = 0) ∨ (i1 = 1)`
  //    collapses to `(i0 = 0)` on `i0 = 0`, wait: `((i0=0) ∨ (i1=1)) ∧ (i0=0) == (i0=0)`
  //    so axes 1, 2, 3 become degenerate, leaving only essential axis `{0}` (mask `1UL`)!
  let i0_0 = @face_bdd.face_var0(0)
  let i1_1 = @face_bdd.face_var1(1)
  let phi = @face_bdd.FOr(i0_0, i1_1)
  let (_, ess_mask, cnt) = cube64_bidirectional_face_prune(phi, i0_0, 4)
  let prune_ok = ess_mask == 1UL && cnt == 8

  // 4. Audit W3C zero-extension browser WGSL kernel
  let audit = audit_wgsl_browser_portability(
    wgsl_kernel_cubical_degeneracy_prune(),
  )
  let wgsl_ok = audit.browser_portable

  // Exact Möbius inversion on Boolean 4-cube:
  // Σ_{k=0..4} (-1)^k C(4,k) 2^(2^(4-k)) = 65536 - 1024 + 96 - 16 + 2 = 64594
  let all_ok = pair_exact &&
    nondeg4 == 64594 &&
    deg4 == 942 &&
    bfly_ok &&
    ident_ok &&
    boundary_sq_ok &&
    deg_closed_ok &&
    prune_ok &&
    wgsl_ok
  {
    all_65536_4cubes_pair_o1_exact: pair_exact,
    nondegenerate_4cubes_count: nondeg4,
    degenerate_4cubes_count: deg4,
    butterfly_matches_ref_all_dims: bfly_ok,
    cubical_face_degeneracy_identities_ok: ident_ok,
    moore_boundary_squared_zero_ok: boundary_sq_ok,
    degenerate_subcomplex_closed_ok: deg_closed_ok,
    bidirectional_face_prune_ok: prune_ok,
    wgsl_kernel_browser_portable: wgsl_ok,
    all_ok,
  }
}
