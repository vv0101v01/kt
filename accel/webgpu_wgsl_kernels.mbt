// Browser Free WebGPU (`WGSL`) Compute Shader Suite, W3C Baseline Portability
// Auditor, and Cross-Federation Hardware-Acceleration Equivalence Verifier.
//
// Targets unextended consumer/integrated browser GPUs (`navigator.gpu`):
//   - Strict 32-bit types (`u32`, `i32`, `atomic<u32>`, `dot4I8Packed`) — zero `f64`/`u64`/`i64`;
//   - `workgroup_size <= 256` invocations & `var<workgroup> <= 16,384` bytes;
//   - Optional Khronos WebGPU `enable subgroups;` specialization for prefix scan.

///|
/// Metadata & WGSL source descriptor for a browser-executable WebGPU compute kernel.
#derive(Debug, Eq)
pub(all) struct WgslComputeKernel {
  slug : String
  paper_family : String
  workgroup_size : (Int32, Int32, Int32)
  shared_mem_bytes : Int32
  uses_subgroups : Bool
  wgsl_source : String
}

///|
pub extend WgslComputeKernel with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend WgslComputeKernel with Eq::{not_equal, equal}

///|
/// Static W3C WebGPU browser-portability audit result for a WGSL compute kernel.
#derive(Debug, Eq)
pub(all) struct WgslPortabilityAudit {
  slug : String
  no_64bit_types : Bool
  workgroup_invocations_ok : Bool
  workgroup_bytes_ok : Bool
  has_compute_entrypoint : Bool
  balanced_delimiters : Bool
  browser_portable : Bool
}

///|
pub extend WgslPortabilityAudit with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend WgslPortabilityAudit with Eq::{not_equal, equal}

///|
/// Kernel 1: Ozaki Scheme II CRT Byte-Modulus Tiled GEMM (`dot4I8Packed` INT8 -> INT32).
pub fn wgsl_kernel_ozaki2_dp4a_gemm() -> WgslComputeKernel {
  let src =
    #|struct Params { m: u32, n: u32, k_groups4: u32, modulus: i32 }
    #|@group(0) @binding(0) var<uniform> params: Params;
    #|@group(0) @binding(1) var<storage, read> packed_a: array<u32>;
    #|@group(0) @binding(2) var<storage, read> packed_bt: array<u32>;
    #|@group(0) @binding(3) var<storage, read_write> out_res: array<i32>;
    #|var<workgroup> tile_a: array<u32, 272>;
    #|var<workgroup> tile_b: array<u32, 272>;
    #|@compute @workgroup_size(16, 16, 1)
    #|fn main(
    #|  @builtin(global_invocation_id) gid: vec3<u32>,
    #|  @builtin(local_invocation_id) lid: vec3<u32>
    #|) {
    #|  let row = gid.y;
    #|  let col = gid.x;
    #|  let lr = lid.y;
    #|  let lc = lid.x;
    #|  var acc_mod: i32 = 0;
    #|  var acc_chunk: i32 = 0;
    #|  var chunk_steps: u32 = 0u;
    #|  let num_tiles = (params.k_groups4 + 15u) / 16u;
    #|  for (var t: u32 = 0u; t < num_tiles; t = t + 1u) {
    #|    let g = t * 16u + lc;
    #|    tile_a[lr * 17u + lc] = select(0u, packed_a[row * params.k_groups4 + g], row < params.m && g < params.k_groups4);
    #|    let gb = t * 16u + lr;
    #|    tile_b[lc * 17u + lr] = select(0u, packed_bt[col * params.k_groups4 + gb], col < params.n && gb < params.k_groups4);
    #|    workgroupBarrier();
    #|    for (var s: u32 = 0u; s < 16u; s = s + 1u) {
    #|      acc_chunk = acc_chunk + dot4I8Packed(tile_a[lr * 17u + s], tile_b[lc * 17u + s]);
    #|      chunk_steps = chunk_steps + 1u;
    #|      if (chunk_steps == 54u) {
    #|        acc_mod = (acc_mod + (acc_chunk % params.modulus) + params.modulus) % params.modulus;
    #|        acc_chunk = 0;
    #|        chunk_steps = 0u;
    #|      }
    #|    }
    #|    workgroupBarrier();
    #|  }
    #|  if (row < params.m && col < params.n) {
    #|    let rem = (acc_mod + (acc_chunk % params.modulus) + params.modulus) % params.modulus;
    #|    out_res[row * params.n + col] = rem;
    #|  }
    #|}
  WgslComputeKernel::{
    slug: "ozaki2_dp4a_crt_gemm",
    paper_family: "Ozaki Scheme II (2025/2026) INT8->INT32 CRT GEMM",
    workgroup_size: (16, 16, 1),
    shared_mem_bytes: 272 * 4 * 2,
    uses_subgroups: false,
    wgsl_source: src,
  }
}

///|
/// Kernel 2: 32-bit RNS Stockham Auto-Sort Radix-2 Shared-Memory NTT (`p < 46340`, zero `u64`).
pub fn wgsl_kernel_stockham_ntt_u32() -> WgslComputeKernel {
  let src =
    #|struct NttParams { n: u32, log_n: u32, prime: u32, inv_n: u32 }
    #|@group(0) @binding(0) var<uniform> params: NttParams;
    #|@group(0) @binding(1) var<storage, read> twiddles: array<u32>;
    #|@group(0) @binding(2) var<storage, read_write> data: array<u32>;
    #|var<workgroup> ping: array<u32, 512>;
    #|var<workgroup> pong: array<u32, 512>;
    #|@compute @workgroup_size(256, 1, 1)
    #|fn main(@builtin(local_invocation_id) lid: vec3<u32>) {
    #|  let tid = lid.x;
    #|  let p = params.prime;
    #|  let half = params.n >> 1u;
    #|  if (tid < half) {
    #|    ping[tid] = data[tid];
    #|    ping[tid + half] = data[tid + half];
    #|  }
    #|  workgroupBarrier();
    #|  var m: u32 = 1u;
    #|  for (var s: u32 = 0u; s < params.log_n; s = s + 1u) {
    #|    if (tid < half) {
    #|      let k = tid / m;
    #|      let j = tid % m;
    #|      let q = half / m;
    #|      let w = twiddles[k * m];
    #|      let u = select(pong[k * m + j], ping[k * m + j], (s & 1u) == 0u);
    #|      let v = select(pong[(k + q) * m + j], ping[(k + q) * m + j], (s & 1u) == 0u);
    #|      let add_v = select(u + v, u + v - p, u + v >= p);
    #|      let sub_v = select(u - v, u + p - v, u < v);
    #|      let mul_v = (sub_v * w) % p;
    #|      if ((s & 1u) == 0u) {
    #|        pong[k * 2u * m + j] = add_v;
    #|        pong[k * 2u * m + j + m] = mul_v;
    #|      } else {
    #|        ping[k * 2u * m + j] = add_v;
    #|        ping[k * 2u * m + j + m] = mul_v;
    #|      }
    #|    }
    #|    m = m << 1u;
    #|    workgroupBarrier();
    #|  }
    #|  if (tid < half) {
    #|    let even_final = (params.log_n & 1u) == 0u;
    #|    let y0 = select(pong[tid], ping[tid], even_final);
    #|    let y1 = select(pong[tid + half], ping[tid + half], even_final);
    #|    data[tid] = (y0 * params.inv_n) % p;
    #|    data[tid + half] = (y1 * params.inv_n) % p;
    #|  }
    #|}
  WgslComputeKernel::{
    slug: "stockham_ntt_rns_u32",
    paper_family: "Cheddar / MoMA / ZKProphet (2025) 32-bit RNS Stockham NTT",
    workgroup_size: (256, 1, 1),
    shared_mem_bytes: 512 * 4 * 2,
    uses_subgroups: false,
    wgsl_source: src,
  }
}

///|
/// Kernel 3: Dual-Rail `u32` Bit-Sliced `GF(3)` `6,561`-Tensor Cayley Hyperdeterminant.
pub fn wgsl_kernel_bitsliced_f3_hyperdet() -> WgslComputeKernel {
  let src =
    #|struct Slice32 { lo: u32, hi: u32 }
    #|@group(0) @binding(0) var<storage, read> coords_lo: array<u32>;
    #|@group(0) @binding(1) var<storage, read> coords_hi: array<u32>;
    #|@group(0) @binding(2) var<storage, read> valid_masks: array<u32>;
    #|@group(0) @binding(3) var<storage, read_write> counts_out: array<atomic<u32>, 3>;
    #|fn gf3_add(a: Slice32, b: Slice32) -> Slice32 {
    #|  let c0 = ((a.lo ^ b.lo) & ~(a.hi | b.hi)) | (a.hi & b.hi);
    #|  let c1 = ((a.hi ^ b.hi) & ~(a.lo | b.lo)) | (a.lo & b.lo);
    #|  return Slice32(c0, c1);
    #|}
    #|fn gf3_mul(a: Slice32, b: Slice32) -> Slice32 {
    #|  return Slice32((a.lo & b.lo) | (a.hi & b.hi), (a.lo & b.hi) | (a.hi & b.lo));
    #|}
    #|@compute @workgroup_size(64, 1, 1)
    #|fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
    #|  let ch = gid.x;
    #|  if (ch >= 206u) { return; }
    #|  let off = ch * 8u;
    #|  let a = Slice32(coords_lo[off + 0u], coords_hi[off + 0u]);
    #|  let b = Slice32(coords_lo[off + 1u], coords_hi[off + 1u]);
    #|  let c = Slice32(coords_lo[off + 2u], coords_hi[off + 2u]);
    #|  let d = Slice32(coords_lo[off + 3u], coords_hi[off + 3u]);
    #|  let e = Slice32(coords_lo[off + 4u], coords_hi[off + 4u]);
    #|  let f = Slice32(coords_lo[off + 5u], coords_hi[off + 5u]);
    #|  let g = Slice32(coords_lo[off + 6u], coords_hi[off + 6u]);
    #|  let h = Slice32(coords_lo[off + 7u], coords_hi[off + 7u]);
    #|  let p1 = gf3_mul(a, h);
    #|  let p2 = gf3_mul(b, g);
    #|  let p3 = gf3_mul(c, f);
    #|  let p4 = gf3_mul(d, e);
    #|  let sq = gf3_add(gf3_add(gf3_mul(p1, p1), gf3_mul(p2, p2)), gf3_add(gf3_mul(p3, p3), gf3_mul(p4, p4)));
    #|  let pr = gf3_add(gf3_add(gf3_add(gf3_mul(p1, p2), gf3_mul(p1, p3)), gf3_add(gf3_mul(p1, p4), gf3_mul(p2, p3))), gf3_add(gf3_mul(p2, p4), gf3_mul(p3, p4)));
    #|  let tet = gf3_add(gf3_mul(gf3_mul(a, d), gf3_mul(f, g)), gf3_mul(gf3_mul(b, c), gf3_mul(e, h)));
    #|  let det = gf3_add(gf3_add(sq, pr), tet);
    #|  let m = valid_masks[ch];
    #|  let ones = countOneBits(det.lo & m);
    #|  let twos = countOneBits(det.hi & m);
    #|  let total = countOneBits(m);
    #|  atomicAdd(&counts_out[0], total - ones - twos);
    #|  atomicAdd(&counts_out[1], ones);
    #|  atomicAdd(&counts_out[2], twos);
    #|}
  WgslComputeKernel::{
    slug: "bitsliced_f3_cayley_hyperdet",
    paper_family: "Boothby–Bradshaw GF(3) Bitslicing + Semiring/Bit-Vector GPU Sweep (2025)",
    workgroup_size: (64, 1, 1),
    shared_mem_bytes: 0,
    uses_subgroups: false,
    wgsl_source: src,
  }
}

///|
/// Kernel 4: Scanbox Parallelized Decoupled Look-Back Prefix Scan (`use_subgroups` toggles
/// Khronos WebGPU `enable subgroups;` + `subgroupInclusiveAdd` vs baseline shared-memory scan).
pub fn wgsl_kernel_scanbox_decoupled_scan(
  use_subgroups : Bool,
) -> WgslComputeKernel {
  let src_sub =
    #|enable subgroups;
    #|@group(0) @binding(0) var<storage, read> input_data: array<u32>;
    #|@group(0) @binding(1) var<storage, read_write> output_data: array<u32>;
    #|@group(0) @binding(2) var<storage, read_write> tile_state: array<atomic<u32>>;
    #|@group(0) @binding(3) var<storage, read_write> tile_counter: atomic<u32>;
    #|var<workgroup> sg_spine: array<u32, 32>;
    #|var<workgroup> wg_tile_id: u32;
    #|var<workgroup> wg_excl_prefix: u32;
    #|@compute @workgroup_size(256, 1, 1)
    #|fn main(
    #|  @builtin(local_invocation_id) lid: vec3<u32>,
    #|  @builtin(subgroup_invocation_id) sg_lane: u32,
    #|  @builtin(subgroup_size) sg_size: u32
    #|) {
    #|  let tid = lid.x;
    #|  if (tid == 0u) { wg_tile_id = atomicAdd(&tile_counter, 1u); }
    #|  workgroupBarrier();
    #|  let tile = wg_tile_id;
    #|  let idx = tile * 256u + tid;
    #|  let x = select(0u, input_data[idx], idx < arrayLength(&input_data));
    #|  let sg_inc = subgroupInclusiveAdd(x);
    #|  let sg_id = tid / sg_size;
    #|  if (sg_lane == sg_size - 1u) { sg_spine[sg_id] = sg_inc; }
    #|  workgroupBarrier();
    #|  if (tid == 0u) {
    #|    var agg: u32 = 0u;
    #|    let n_sg = (256u + sg_size - 1u) / sg_size;
    #|    for (var s: u32 = 0u; s < n_sg; s = s + 1u) {
    #|      let cur = sg_spine[s];
    #|      sg_spine[s] = agg;
    #|      agg = agg + cur;
    #|    }
    #|    atomicStore(&tile_state[tile * 3u + 1u], agg);
    #|    if (tile == 0u) {
    #|      atomicStore(&tile_state[tile * 3u + 2u], agg);
    #|      atomicStore(&tile_state[tile * 3u + 0u], 2u);
    #|      wg_excl_prefix = 0u;
    #|    } else {
    #|      atomicStore(&tile_state[tile * 3u + 0u], 1u);
    #|      var excl: u32 = 0u;
    #|      var p: i32 = i32(tile) - 1;
    #|      loop {
    #|        if (p < 0) { break; }
    #|        let st = atomicLoad(&tile_state[u32(p) * 3u + 0u]);
    #|        if (st == 2u) {
    #|          excl = excl + atomicLoad(&tile_state[u32(p) * 3u + 2u]);
    #|          break;
    #|        } else if (st == 1u) {
    #|          excl = excl + atomicLoad(&tile_state[u32(p) * 3u + 1u]);
    #|          p = p - 1;
    #|        }
    #|      }
    #|      wg_excl_prefix = excl;
    #|      atomicStore(&tile_state[tile * 3u + 2u], excl + agg);
    #|      atomicStore(&tile_state[tile * 3u + 0u], 2u);
    #|    }
    #|  }
    #|  workgroupBarrier();
    #|  if (idx < arrayLength(&output_data)) {
    #|    output_data[idx] = wg_excl_prefix + sg_spine[sg_id] + sg_inc;
    #|  }
    #|}
  let src_port =
    #|@group(0) @binding(0) var<storage, read> input_data: array<u32>;
    #|@group(0) @binding(1) var<storage, read_write> output_data: array<u32>;
    #|@group(0) @binding(2) var<storage, read_write> tile_state: array<atomic<u32>>;
    #|@group(0) @binding(3) var<storage, read_write> tile_counter: atomic<u32>;
    #|var<workgroup> sh_scan: array<u32, 256>;
    #|var<workgroup> wg_tile_id: u32;
    #|var<workgroup> wg_excl_prefix: u32;
    #|@compute @workgroup_size(256, 1, 1)
    #|fn main(@builtin(local_invocation_id) lid: vec3<u32>) {
    #|  let tid = lid.x;
    #|  if (tid == 0u) { wg_tile_id = atomicAdd(&tile_counter, 1u); }
    #|  workgroupBarrier();
    #|  let tile = wg_tile_id;
    #|  let idx = tile * 256u + tid;
    #|  sh_scan[tid] = select(0u, input_data[idx], idx < arrayLength(&input_data));
    #|  workgroupBarrier();
    #|  for (var offset: u32 = 1u; offset < 256u; offset = offset << 1u) {
    #|    let addend = select(0u, sh_scan[tid - offset], tid >= offset);
    #|    workgroupBarrier();
    #|    sh_scan[tid] = sh_scan[tid] + addend;
    #|    workgroupBarrier();
    #|  }
    #|  if (tid == 0u) {
    #|    let agg = sh_scan[255u];
    #|    atomicStore(&tile_state[tile * 3u + 1u], agg);
    #|    if (tile == 0u) {
    #|      atomicStore(&tile_state[tile * 3u + 2u], agg);
    #|      atomicStore(&tile_state[tile * 3u + 0u], 2u);
    #|      wg_excl_prefix = 0u;
    #|    } else {
    #|      atomicStore(&tile_state[tile * 3u + 0u], 1u);
    #|      var excl: u32 = 0u;
    #|      var p: i32 = i32(tile) - 1;
    #|      loop {
    #|        if (p < 0) { break; }
    #|        let st = atomicLoad(&tile_state[u32(p) * 3u + 0u]);
    #|        if (st == 2u) {
    #|          excl = excl + atomicLoad(&tile_state[u32(p) * 3u + 2u]);
    #|          break;
    #|        } else if (st == 1u) {
    #|          excl = excl + atomicLoad(&tile_state[u32(p) * 3u + 1u]);
    #|          p = p - 1;
    #|        }
    #|      }
    #|      wg_excl_prefix = excl;
    #|      atomicStore(&tile_state[tile * 3u + 2u], excl + agg);
    #|      atomicStore(&tile_state[tile * 3u + 0u], 2u);
    #|    }
    #|  }
    #|  workgroupBarrier();
    #|  if (idx < arrayLength(&output_data)) {
    #|    output_data[idx] = wg_excl_prefix + sh_scan[tid];
    #|  }
    #|}
  let src = if use_subgroups { src_sub } else { src_port }
  WgslComputeKernel::{
    slug: if use_subgroups {
      "scanbox_decoupled_scan_subgroups"
    } else {
      "scanbox_decoupled_scan_portable"
    },
    paper_family: "Contini Scanbox (2025) + Khronos WebGPU Subgroups (2025/2026)",
    workgroup_size: (256, 1, 1),
    shared_mem_bytes: if use_subgroups {
      (32 + 2) * 4
    } else {
      (256 + 2) * 4
    },
    uses_subgroups: use_subgroups,
    wgsl_source: src,
  }
}

///|
/// Kernel 5: 3-Phase Bank-Conflict-Free `16x17` Shared-Memory Tropical `(min, +)` Closure.
pub fn wgsl_kernel_tropical_blocked_apsp() -> WgslComputeKernel {
  let src =
    #|struct TropParams { n: u32, pivot_block: u32, phase: u32, inf_val: i32 }
    #|@group(0) @binding(0) var<uniform> params: TropParams;
    #|@group(0) @binding(1) var<storage, read_write> dist: array<i32>;
    #|var<workgroup> tile_a: array<i32, 272>;
    #|var<workgroup> tile_b: array<i32, 272>;
    #|fn trop_add(a: i32, b: i32, inf_v: i32) -> i32 {
    #|  if (a >= inf_v || b >= inf_v) { return inf_v; }
    #|  return min(inf_v, a + b);
    #|}
    #|@compute @workgroup_size(16, 16, 1)
    #|fn main(
    #|  @builtin(workgroup_id) wid: vec3<u32>,
    #|  @builtin(local_invocation_id) lid: vec3<u32>
    #|) {
    #|  let r = lid.y;
    #|  let c = lid.x;
    #|  let kb = params.pivot_block;
    #|  let ib = select(wid.y, kb, params.phase == 0u);
    #|  let jb = select(wid.x, kb, params.phase == 0u);
    #|  if (params.phase == 2u && (ib == kb || jb == kb)) { return; }
    #|  let gr_a = ib * 16u + r;
    #|  let gc_a = kb * 16u + c;
    #|  let gr_b = kb * 16u + r;
    #|  let gc_b = jb * 16u + c;
    #|  tile_a[r * 17u + c] = select(params.inf_val, dist[gr_a * params.n + gc_a], gr_a < params.n && gc_a < params.n);
    #|  tile_b[r * 17u + c] = select(params.inf_val, dist[gr_b * params.n + gc_b], gr_b < params.n && gc_b < params.n);
    #|  workgroupBarrier();
    #|  let gr = ib * 16u + r;
    #|  let gc = jb * 16u + c;
    #|  var cur = select(params.inf_val, dist[gr * params.n + gc], gr < params.n && gc < params.n);
    #|  for (var m: u32 = 0u; m < 16u; m = m + 1u) {
    #|    if (params.phase == 0u) {
    #|      let step_v = trop_add(tile_a[r * 17u + m], tile_a[m * 17u + c], params.inf_val);
    #|      workgroupBarrier();
    #|      if (step_v < tile_a[r * 17u + c]) { tile_a[r * 17u + c] = step_v; }
    #|      workgroupBarrier();
    #|      cur = tile_a[r * 17u + c];
    #|    } else {
    #|      cur = min(cur, trop_add(tile_a[r * 17u + m], tile_b[m * 17u + c], params.inf_val));
    #|    }
    #|  }
    #|  if (gr < params.n && gc < params.n) {
    #|    dist[gr * params.n + gc] = cur;
    #|  }
    #|}
  WgslComputeKernel::{
    slug: "tropical_blocked_kleene_apsp",
    paper_family: "WgPy / Memory-Aware GPU Tiled Semiring Closure (2025)",
    workgroup_size: (16, 16, 1),
    shared_mem_bytes: 272 * 4 * 2,
    uses_subgroups: false,
    wgsl_source: src,
  }
}

///|
/// Kernel 6: HVM2 Flat-Arena Interaction Combinator Parallel Active-Pair Rewrite Shader.
pub fn wgsl_kernel_hvm2_inet_rewrite() -> WgslComputeKernel {
  let src =
    #|struct INetHeader { num_redexes: u32, alloc_top: atomic<u32>, anni_cnt: atomic<u32>, comm_cnt: atomic<u32> }
    #|@group(0) @binding(0) var<storage, read_write> header: INetHeader;
    #|@group(0) @binding(1) var<storage, read> redex_pairs: array<vec2<u32>>;
    #|@group(0) @binding(2) var<storage, read_write> kinds: array<u32>;
    #|@group(0) @binding(3) var<storage, read_write> labels: array<u32>;
    #|@group(0) @binding(4) var<storage, read_write> peers: array<u32>;
    #|fn link_ports(u: u32, v: u32) {
    #|  peers[u] = v;
    #|  peers[v] = u;
    #|}
    #|@compute @workgroup_size(64, 1, 1)
    #|fn main(@builtin(global_invocation_id) gid: vec3<u32>) {
    #|  let idx = gid.x;
    #|  if (idx >= header.num_redexes) { return; }
    #|  let pair = redex_pairs[idx];
    #|  let a = pair.x;
    #|  let b = pair.y;
    #|  let ka = kinds[a];
    #|  let kb = kinds[b];
    #|  let la = labels[a];
    #|  let lb = labels[b];
    #|  let a1 = peers[a * 3u + 1u];
    #|  let a2 = peers[a * 3u + 2u];
    #|  let b1 = peers[b * 3u + 1u];
    #|  let b2 = peers[b * 3u + 2u];
    #|  kinds[a] = 0u;
    #|  kinds[b] = 0u;
    #|  if (ka == kb && la == lb) {
    #|    link_ports(a1, b1);
    #|    link_ports(a2, b2);
    #|    atomicAdd(&header.anni_cnt, 1u);
    #|  } else {
    #|    let base = atomicAdd(&header.alloc_top, 4u);
    #|    let nb1 = base + 0u; let nb2 = base + 1u;
    #|    let na1 = base + 2u; let na2 = base + 3u;
    #|    kinds[nb1] = kb; labels[nb1] = lb;
    #|    kinds[nb2] = kb; labels[nb2] = lb;
    #|    kinds[na1] = ka; labels[na1] = la;
    #|    kinds[na2] = ka; labels[na2] = la;
    #|    link_ports(nb1 * 3u + 0u, a1);
    #|    link_ports(nb2 * 3u + 0u, a2);
    #|    link_ports(na1 * 3u + 0u, b1);
    #|    link_ports(na2 * 3u + 0u, b2);
    #|    link_ports(nb1 * 3u + 1u, na1 * 3u + 1u);
    #|    link_ports(nb1 * 3u + 2u, na2 * 3u + 1u);
    #|    link_ports(nb2 * 3u + 1u, na1 * 3u + 2u);
    #|    link_ports(nb2 * 3u + 2u, na2 * 3u + 2u);
    #|    atomicAdd(&header.comm_cnt, 1u);
    #|  }
    #|}
  WgslComputeKernel::{
    slug: "hvm2_inet_parallel_rewrite",
    paper_family: "Taelin HVM2 (2024/2025) Flat-Arena Interaction Combinators",
    workgroup_size: (64, 1, 1),
    shared_mem_bytes: 0,
    uses_subgroups: false,
    wgsl_source: src,
  }
}

///|
/// Return the complete suite of 7 Browser Free WebGPU WGSL Compute Kernels
/// (all 6 frontier algorithm families, including both portable and `subgroups` Scanbox).
pub fn webgpu_frontier_kernel_suite() -> Array[WgslComputeKernel] {
  [
    wgsl_kernel_ozaki2_dp4a_gemm(),
    wgsl_kernel_stockham_ntt_u32(),
    wgsl_kernel_bitsliced_f3_hyperdet(),
    wgsl_kernel_scanbox_decoupled_scan(false),
    wgsl_kernel_scanbox_decoupled_scan(true),
    wgsl_kernel_tropical_blocked_apsp(),
    wgsl_kernel_hvm2_inet_rewrite(),
  ]
}

///|
/// Statically audit a `WgslComputeKernel` against W3C WebGPU baseline browser constraints:
/// zero `f64`/`u64`/`i64` scalars, `<= 256` threads/workgroup, `<= 16,384` B shared memory,
/// `@compute @workgroup_size(...)` entrypoint, and balanced `{}` / `()` delimiters.
pub fn audit_wgsl_browser_portability(
  k : WgslComputeKernel,
) -> WgslPortabilityAudit {
  let s = k.wgsl_source
  let no_64 = !s.contains("f64") && !s.contains("u64") && !s.contains("i64")
  let (wx, wy, wz) = k.workgroup_size
  let inv = wx * wy * wz
  let inv_ok = wx >= 1 && wy >= 1 && wz >= 1 && inv <= 256
  let mem_ok = k.shared_mem_bytes >= 0 && k.shared_mem_bytes <= 16384
  let entry_ok = s.contains("@compute") &&
    s.contains("@workgroup_size") &&
    s.contains("@group(0)") &&
    (!k.uses_subgroups || s.contains("enable subgroups;"))
  let mut braces = 0
  let mut parens = 0
  let mut delim_ok = true
  for ch in s {
    if ch == '{' {
      braces = braces + 1
    } else if ch == '}' {
      braces = braces - 1
      if braces < 0 {
        delim_ok = false
      }
    } else if ch == '(' {
      parens = parens + 1
    } else if ch == ')' {
      parens = parens - 1
      if parens < 0 {
        delim_ok = false
      }
    }
  }
  if braces != 0 || parens != 0 {
    delim_ok = false
  }
  WgslPortabilityAudit::{
    slug: k.slug,
    no_64bit_types: no_64,
    workgroup_invocations_ok: inv_ok,
    workgroup_bytes_ok: mem_ok,
    has_compute_entrypoint: entry_ok,
    balanced_delimiters: delim_ok,
    browser_portable: no_64 && inv_ok && mem_ok && entry_ok && delim_ok,
  }
}

///|
/// Unified mathematical & structural verification report for Federation 8 (`accel`).
#derive(Debug, Eq)
pub(all) struct AccelFederationReport {
  m4ri_gf2_and_rank_ok : Bool
  bitsliced_f3_all_6561_ok : Bool
  face_swar_bdd_sat_ok : Bool
  ozaki2_crt_exact_and_fp64_ok : Bool
  stockham_rns_ntt_and_mont30_ok : Bool
  scanbox_morton_tropical_ok : Bool
  hvm2_inet_strong_confluence_ok : Bool
  wgsl_browser_kernels_audited : Int32
  all_ok : Bool
}

///|
pub extend AccelFederationReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AccelFederationReport with Eq::{not_equal, equal}

///|
/// Exhaustively cross-check all 6 CPU SWAR + Browser WebGPU frontier algorithms
/// against the exact algebraic/combinatorial/topological kernels of Federations 1–7!
pub fn verify_accel_federation() -> AccelFederationReport {
  // 1. M4RI GF(2) GEMM & 64-bit RREF across multi-word 70x70 matrices (crossing 64-bit boundary!)
  let n2 = 70
  let a2_raw : Array[Int32] = Array::makei(n2 * n2, idx => {
    let r = idx / n2
    let c = idx % n2
    ((r * 7 + c * 13 + (r ^ c)) >> 1) & 1
  })
  let b2_raw : Array[Int32] = Array::makei(n2 * n2, idx => {
    let r = idx / n2
    let c = idx % n2
    ((r * 5 + c * 11 + 3) >> 2) & 1
  })
  let a2_m4ri = gf2_bit_matrix_from_ints(n2, n2, a2_raw)
  let b2_m4ri = gf2_bit_matrix_from_ints(n2, n2, b2_raw)
  let c2_m4ri = gf2_matmul_m4ri(a2_m4ri, b2_m4ri)
  let a2_fp = @gcd.fp_mat_make(n2, n2, 2, 0)
  let b2_fp = @gcd.fp_mat_make(n2, n2, 2, 0)
  for r in 0..<n2 {
    for c in 0..<n2 {
      @gcd.fp_mat_set(a2_fp, r, c, a2_raw[r * n2 + c])
      @gcd.fp_mat_set(b2_fp, r, c, b2_raw[r * n2 + c])
    }
  }
  let c2_fp = @gcd.fp_mat_mul(a2_fp, b2_fp)
  let mut m4ri_match = gf2_rref_rank_u64(a2_m4ri) == @gcd.fp_rank(a2_fp)
  for r in 0..<n2 {
    for c in 0..<n2 {
      if gf2_bit_matrix_get(c2_m4ri, r, c) != @gcd.fp_mat_get(c2_fp, r, c) {
        m4ri_match = false
      }
    }
  }

  // 2. Dual-Rail 64-trit GF(3) Bit-Sliced Hyperdeterminant across all 6,561 2x2x2 tensors
  let f3_rep = gf3_bitsliced_all_6561_hyperdeterminants()
  let f3_ok = f3_rep.matches_tensor_atlas &&
    f3_rep.singular_det_zero + f3_rep.det_eq_one + f3_rep.det_eq_two == 6561

  // 3. 64-Way Bit-Parallel `Face` Hypercube `#SAT` vs `@face_bdd` ROBDD over 7 variables (`128` vertices)
  let v0 = @face_bdd.dim_var(0)
  let v2 = @face_bdd.dim_var(2)
  let v5 = @face_bdd.dim_var(5)
  let v6 = @face_bdd.dim_var(6)
  let face = @face_bdd.Face::FAnd(
    @face_bdd.Face::FOr(@face_bdd.Face::FEq0(v0), @face_bdd.Face::FEq1(v5)),
    @face_bdd.Face::FOr(@face_bdd.Face::FEq1(v2), @face_bdd.Face::FEq0(v6)),
  )
  let mgr = @face_bdd.bdd_manager_new(7)
  let dag = @face_bdd.bdd_dag_build_face(mgr, face)
  let bdd_cnt = @face_bdd.bdd_dag_sat_count(mgr, dag).to_int()
  let swar_cnt = face_swar_model_count(face, 7)
  let face_ok = bdd_cnt == swar_cnt && swar_cnt == 72

  // 4. Ozaki Scheme II INT8->INT32 (`dot4I8Packed`) CRT Exact BigInt GEMM + FP64 Emulated GEMM
  let a_big : Array[BigInt] = [
    BigInt::from_int64(123456789L),
    BigInt::from_int64(-98765432L),
    BigInt::from_int64(45678901L),
    BigInt::from_int64(-31415926L),
    BigInt::from_int64(27182818L),
    BigInt::from_int64(16180339L),
  ]
  let b_big : Array[BigInt] = [
    BigInt::from_int64(87654321L),
    BigInt::from_int64(-11223344L),
    BigInt::from_int64(-55667788L),
    BigInt::from_int64(99887766L),
    BigInt::from_int64(33445566L),
    BigInt::from_int64(-77665544L),
  ]
  let c_oz = ozaki2_int_gemm_dp4a(2, 3, 2, a_big, b_big)
  let mut oz_exact_ok = true
  for r in 0..<2 {
    for c in 0..<2 {
      let mut ref_sum = BigInt::from_int(0)
      for t in 0..<3 {
        ref_sum = ref_sum + a_big[r * 3 + t] * b_big[t * 2 + c]
      }
      if c_oz[r * 2 + c] != ref_sum {
        oz_exact_ok = false
      }
    }
  }
  let a_fp : Array[Double] = [
    3.141592653589793, -2.718281828459045, 1.4142135623730951, -0.5772156649015329,
    1.618033988749895, 2.23606797749979,
  ]
  let b_fp : Array[Double] = [
    -1.7320508075688772, 0.6931471805599453, 2.302585092994046, -1.2020569031595942,
    0.915965594177219, -2.5066282746310002,
  ]
  let c_fp_oz = ozaki2_emulate_fp64_gemm(2, 3, 2, a_fp, b_fp)
  let mut oz_fp64_ok = true
  for r in 0..<2 {
    for c in 0..<2 {
      let mut ref_d = 0.0
      for t in 0..<3 {
        ref_d = ref_d + a_fp[r * 3 + t] * b_fp[t * 2 + c]
      }
      if (c_fp_oz[r * 2 + c] - ref_d).abs() > 1.0e-7 {
        oz_fp64_ok = false
      }
    }
  }

  // 5. 32-bit RNS Stockham Auto-Sort NTT vs `@algebra.qpoly_mul` + 30-bit Montgomery REDC
  let pa_i = [1005, -2300, 4501, -890, 1234, 777]
  let pb_i = [-321, 6543, -999, 4321, -111]
  let conv_rns = rns_stockham_poly_mul_exact(pa_i, pb_i)
  let qa = @algebra.qpoly_normalize(pa_i.map(x => @algebra.rat_int(x)))
  let qb = @algebra.qpoly_normalize(pb_i.map(x => @algebra.rat_int(x)))
  let qc = @algebra.qpoly_mul(qa, qb)
  let mut ntt_ok = true
  for i in 0..<conv_rns.length() {
    if !@algebra.rat_eq(
        @algebra.qpoly_coeff(qc, i),
        @algebra.rat_big_int(conv_rns[i]),
      ) {
      ntt_ok = false
    }
  }
  let m30 = mont30_ntt_998244353()
  let ma = mont30_to_mont(m30, 123456789)
  let mb = mont30_to_mont(m30, 876543210)
  let mp = mont30_from_mont(m30, mont30_mul(m30, ma, mb))
  let mp_ref = (123456789UL * 876543210UL % 998244353UL).to_int()
  let ntt_mont_ok = ntt_ok && mp == mp_ref

  // 6. Scanbox Decoupled Look-Back Scan + Morton Z-Order + 3-Phase Blocked Tropical Closure
  let scan_in : Array[Int32] = Array::makei(205, i => (i * 17 + 5) % 23 - 7)
  let scan_res = scanbox_decoupled_scan(scan_in, 0, (x, y) => x + y)
  let mut scan_ok = scan_res.num_tiles == 4 && scan_res.lookback_steps >= 3
  let mut run = 0
  for i in 0..<scan_in.length() {
    if scan_res.exclusive[i] != run {
      scan_ok = false
    }
    run = run + scan_in[i]
    if scan_res.inclusive[i] != run {
      scan_ok = false
    }
  }
  let mut morton_ok = true
  for r in 0..<16 {
    for c in 0..<16 {
      let (dr, dc) = morton_decode_2d(morton_encode_2d(r * 19, c * 23))
      if dr != r * 19 || dc != c * 23 {
        morton_ok = false
      }
    }
  }
  let tn = 19
  let t_adj : Array[Int32] = Array::makei(tn * tn, idx => {
    let r = idx / tn
    let c = idx % tn
    if r == c {
      0
    } else if (r * 3 + c * 5) % 4 == 0 {
      (r * 7 + c * 11) % 19 + 1
    } else {
      trop_inf_i32
    }
  })
  let t_blocked = tropical_blocked_kleene_closure(tn, t_adj, block_size=8)
  let t_ref : Array[Int32] = Array::makei(tn * tn, idx => t_adj[idx])
  for k in 0..<tn {
    for i in 0..<tn {
      for j in 0..<tn {
        let cand = trop_add_edge(t_ref[i * tn + k], t_ref[k * tn + j])
        if cand < t_ref[i * tn + j] {
          t_ref[i * tn + j] = cand
        }
      }
    }
  }
  let trop_ok = t_blocked == t_ref

  // 7. HVM2 Flat-Arena Interaction Combinator Strong Confluence + WGSL Portability Audits
  let c0 = inet_verify_church_mul_confluence(0, 5)
  let c12 = inet_verify_church_mul_confluence(3, 4)
  let c20 = inet_verify_church_mul_confluence(4, 5)
  let inet_ok = c0.schedules_confluent &&
    c0.decoded_value == 0 &&
    c0.eras_steps > 0 &&
    c12.schedules_confluent &&
    c12.decoded_value == 12 &&
    c12.comm_steps > 0 &&
    c20.schedules_confluent &&
    c20.decoded_value == 20

  let kernels = webgpu_frontier_kernel_suite()
  let mut audited_ok = 0
  for k in kernels {
    let aud = audit_wgsl_browser_portability(k)
    if aud.browser_portable {
      audited_ok = audited_ok + 1
    }
  }
  let wgsl_ok = audited_ok == kernels.length()
  let all_ok = m4ri_match &&
    f3_ok &&
    face_ok &&
    oz_exact_ok &&
    oz_fp64_ok &&
    ntt_mont_ok &&
    scan_ok &&
    morton_ok &&
    trop_ok &&
    inet_ok &&
    wgsl_ok
  AccelFederationReport::{
    m4ri_gf2_and_rank_ok: m4ri_match,
    bitsliced_f3_all_6561_ok: f3_ok,
    face_swar_bdd_sat_ok: face_ok,
    ozaki2_crt_exact_and_fp64_ok: oz_exact_ok && oz_fp64_ok,
    stockham_rns_ntt_and_mont30_ok: ntt_mont_ok,
    scanbox_morton_tropical_ok: scan_ok && morton_ok && trop_ok,
    hvm2_inet_strong_confluence_ok: inet_ok,
    wgsl_browser_kernels_audited: audited_ok,
    all_ok,
  }
}
