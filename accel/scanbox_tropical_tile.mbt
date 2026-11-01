// Scanbox Parallelized Decoupled Look-Back Prefix Scan (Contini 2025 + Khronos
// WebGPU Subgroups 2025/2026) & 3-Phase Blocked Shared-Memory Tropical `(min, +)`
// Kleene Closure + SWAR Morton Z-Order Cache-Oblivious Layout.

///|
/// Tile descriptor state machine tags for Scanbox / Merrill–Garland decoupled look-back:
/// `0 = STATUS_NOT_READY`, `1 = STATUS_AGGREGATE_AVAILABLE`, `2 = STATUS_PREFIX_AVAILABLE`.
pub struct ScanboxTileDescriptor {
  mut status : Int32
  mut aggregate : Int32
  mut inclusive_prefix : Int32
} derive(Debug, Eq)

///|
pub extend ScanboxTileDescriptor with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ScanboxTileDescriptor with Eq::{not_equal, equal}

///|
/// Execution telemetry & result of single-pass Scanbox Decoupled Look-Back Scan.
pub(all) struct ScanboxScanResult {
  inclusive : Array[Int32]
  exclusive : Array[Int32]
  num_tiles : Int32
  subgroup_size : Int32
  lookback_steps : Int32
} derive(Debug, Eq)

///|
pub extend ScanboxScanResult with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ScanboxScanResult with Eq::{not_equal, equal}

///|
/// Single-pass Chained Scan with Parallelized Decoupled Look-Back + Subgroup Raking
/// over an arbitrary associative monoid `(identity, op)`:
///   1. Partitions `input` into workgroup tiles of `tile_size` (`default = 64`),
///      each subdivided into `subgroup_size` (`default = 16`) SIMD lanes;
///   2. Computes intra-subgroup inclusive scans, rakes subgroup aggregates across
///      the workgroup spine, publishes `STATUS_AGGREGATE (1)` (or `STATUS_PREFIX (2)`
///      for tile `0`), walks predecessor descriptors backward until encountering
///      `STATUS_PREFIX (2)` to form the exclusive tile prefix in `O(1)` amortized steps,
///      publishes `STATUS_PREFIX (2)`, and broadcasts into lane outputs.
pub fn scanbox_decoupled_scan(
  input : Array[Int32],
  identity : Int32,
  op : (Int32, Int32) -> Int32,
  tile_size~ : Int32 = 64,
  subgroup_size~ : Int32 = 16,
) -> ScanboxScanResult {
  let n = input.length()
  if n == 0 {
    return ScanboxScanResult::{
      inclusive: [],
      exclusive: [],
      num_tiles: 0,
      subgroup_size,
      lookback_steps: 0,
    }
  }
  let num_tiles = (n + tile_size - 1) / tile_size
  let num_subgroups = (tile_size + subgroup_size - 1) / subgroup_size
  let descriptors : Array[ScanboxTileDescriptor] = Array::makei(num_tiles, _ => ScanboxTileDescriptor::{
    status: 0,
    aggregate: identity,
    inclusive_prefix: identity,
  })
  let inclusive : Array[Int32] = Array::make(n, identity)
  let exclusive : Array[Int32] = Array::make(n, identity)
  let local_inc : Array[Int32] = Array::make(tile_size, identity)
  let sg_totals : Array[Int32] = Array::make(num_subgroups, identity)
  let sg_excl : Array[Int32] = Array::make(num_subgroups, identity)
  let mut lookback_steps = 0
  // Interleave aggregate publication before prefix resolution on non-initial tiles
  // to exercise both `STATUS_AGGREGATE (1)` and `STATUS_PREFIX (2)` look-back paths!
  for tile in 0..<num_tiles {
    let base = tile * tile_size
    for sg in 0..<num_subgroups {
      let mut run = identity
      for lane in 0..<subgroup_size {
        let local_idx = sg * subgroup_size + lane
        if local_idx < tile_size {
          let g_idx = base + local_idx
          let v = if g_idx < n { input[g_idx] } else { identity }
          run = op(run, v)
          local_inc[local_idx] = run
        }
      }
      sg_totals[sg] = run
    }
    let mut tile_agg = identity
    for sg in 0..<num_subgroups {
      sg_excl[sg] = tile_agg
      tile_agg = op(tile_agg, sg_totals[sg])
    }
    descriptors[tile].aggregate = tile_agg
    if tile == 0 {
      descriptors[tile].inclusive_prefix = tile_agg
      descriptors[tile].status = 2
    } else {
      descriptors[tile].status = 1
    }
    // Resolve decoupled look-back in chunks of 2 tiles so odd tiles walk across an
    // uncommitted `STATUS_AGGREGATE` predecessor before hitting `STATUS_PREFIX`!
    if tile == 0 || tile % 2 == 1 || tile == num_tiles - 1 {
      let start_resolve = if tile == 0 {
        0
      } else if tile % 2 == 1 {
        tile
      } else {
        tile
      }
      let resolve_list = if tile > 0 && tile % 2 == 0 && tile == num_tiles - 1 {
        [tile]
      } else if tile > 0 && tile % 2 == 1 {
        if tile == 1 {
          [1]
        } else {
          [tile - 1, tile]
        }
      } else {
        [start_resolve]
      }
      // Resolve in reverse inside the pair (`tile` first, then `tile - 1`)!
      let mut idx_r = resolve_list.length() - 1
      while idx_r >= 0 {
        let t = resolve_list[idx_r]
        let t_base = t * tile_size
        // Recompute local subgroup structure for tile `t`
        for sg in 0..<num_subgroups {
          let mut run = identity
          for lane in 0..<subgroup_size {
            let local_idx = sg * subgroup_size + lane
            if local_idx < tile_size {
              let g_idx = t_base + local_idx
              let v = if g_idx < n { input[g_idx] } else { identity }
              run = op(run, v)
              local_inc[local_idx] = run
            }
          }
          sg_totals[sg] = run
        }
        let mut cur_excl = identity
        for sg in 0..<num_subgroups {
          sg_excl[sg] = cur_excl
          cur_excl = op(cur_excl, sg_totals[sg])
        }
        let mut excl_tile_prefix = identity
        if t > 0 {
          // Walk backward collecting right-to-left suffix until hitting STATUS_PREFIX (2)
          let suffix_stack : Array[Int32] = []
          let mut pred = t - 1
          while pred >= 0 {
            lookback_steps = lookback_steps + 1
            if descriptors[pred].status == 2 {
              excl_tile_prefix = descriptors[pred].inclusive_prefix
              break
            } else {
              suffix_stack.push(descriptors[pred].aggregate)
              pred = pred - 1
            }
          }
          let mut si = suffix_stack.length() - 1
          while si >= 0 {
            excl_tile_prefix = op(excl_tile_prefix, suffix_stack[si])
            si = si - 1
          }
          descriptors[t].inclusive_prefix = op(
            excl_tile_prefix,
            descriptors[t].aggregate,
          )
          descriptors[t].status = 2
        }
        for local_idx in 0..<tile_size {
          let g_idx = t_base + local_idx
          if g_idx < n {
            let sg = local_idx / subgroup_size
            let lane = local_idx % subgroup_size
            let base_prefix = op(excl_tile_prefix, sg_excl[sg])
            let inc_val = op(base_prefix, local_inc[local_idx])
            let exc_val = if lane == 0 {
              base_prefix
            } else {
              op(base_prefix, local_inc[local_idx - 1])
            }
            inclusive[g_idx] = inc_val
            exclusive[g_idx] = exc_val
          }
        }
        idx_r = idx_r - 1
      }
    }
  }
  ScanboxScanResult::{
    inclusive,
    exclusive,
    num_tiles,
    subgroup_size,
    lookback_steps,
  }
}

///|
fn part1_by1_u32(x0 : UInt32) -> UInt32 {
  let mut x = x0 & 0x0000FFFFU
  x = (x | (x << 8)) & 0x00FF00FFU
  x = (x | (x << 4)) & 0x0F0F0F0FU
  x = (x | (x << 2)) & 0x33333333U
  (x | (x << 1)) & 0x55555555U
}

///|
fn compact1_by1_u32(x0 : UInt32) -> UInt32 {
  let mut x = x0 & 0x55555555U
  x = (x | (x >> 1)) & 0x33333333U
  x = (x | (x >> 2)) & 0x0F0F0F0FU
  x = (x | (x >> 4)) & 0x00FF00FFU
  (x | (x >> 8)) & 0x0000FFFFU
}

///|
/// Branchless 5-shift SWAR 2D Morton Z-Order curve encoding (`(row, col) -> z_code`)
/// for cache-oblivious 2D tile locality (`0 <= row, col < 65536`).
pub fn morton_encode_2d(row : Int32, col : Int32) -> UInt32 {
  part1_by1_u32(col.reinterpret_as_uint()) |
  (part1_by1_u32(row.reinterpret_as_uint()) << 1)
}

///|
/// Inverse branchless SWAR 2D Morton Z-Order decoding (`z_code -> (row, col)`).
pub fn morton_decode_2d(z : UInt32) -> (Int32, Int32) {
  let col = compact1_by1_u32(z).reinterpret_as_int()
  let row = compact1_by1_u32(z >> 1).reinterpret_as_int()
  (row, col)
}

///|
/// Infinity sentinel for 32-bit tropical `(min, +)` shortest-path / Kleene closure
/// (`1_000_000_000`, matching `@trop.sat_add_i32` overflow-free semantics).
pub let trop_inf_i32 : Int32 = 1000000000

///|
fn trop_add_edge(a : Int32, b : Int32) -> Int32 {
  if a >= trop_inf_i32 || b >= trop_inf_i32 {
    trop_inf_i32
  } else {
    let s = @trop.sat_add_i32(a, b)
    if s >= trop_inf_i32 {
      trop_inf_i32
    } else {
      s
    }
  }
}

///|
fn trop_min_i32(a : Int32, b : Int32) -> Int32 {
  if a <= b {
    a
  } else {
    b
  }
}

///|
/// 3-Phase GPU-Style Blocked Shared-Memory Tropical `(min, +)` Kleene Closure (`A*`):
/// partitions the `n x n` distance matrix into `B x B` tiles with `(B + 1)`-stride
/// bank-conflict-free shared-memory padding (`B * (B + 1)` elements per tile),
/// executing for each pivot tile `K`:
///   - Phase 1: self-dependent diagonal block `(K, K)` Kleene closure;
///   - Phase 2: pivot row `(K, J)` and pivot column `(I, K)` panel updates (`I, J != K`);
///   - Phase 3: independent off-diagonal blocks `(I, J)` (`I != K, J != K`) via tiled
///              tropical min-plus MMA!
pub fn tropical_blocked_kleene_closure(
  n : Int32,
  adj : Array[Int32],
  block_size~ : Int32 = 8,
) -> Array[Int32] {
  let b = if block_size <= 0 { 8 } else { block_size }
  let pad_stride = b + 1 // +1 column padding eliminates 32-bank GPU shared-memory conflicts
  let dist : Array[Int32] = Array::make(n * n, trop_inf_i32)
  for i in 0..<n {
    for j in 0..<n {
      let v = adj[i * n + j]
      dist[i * n + j] = if i == j { trop_min_i32(0, v) } else { v }
    }
  }
  let num_blocks = (n + b - 1) / b
  let sh_piv : Array[Int32] = Array::make(b * pad_stride, trop_inf_i32)
  let sh_a : Array[Int32] = Array::make(b * pad_stride, trop_inf_i32)
  let sh_b : Array[Int32] = Array::make(b * pad_stride, trop_inf_i32)
  let sh_c : Array[Int32] = Array::make(b * pad_stride, trop_inf_i32)
  for kb in 0..<num_blocks {
    let k0 = kb * b
    // Phase 1: Load & close diagonal pivot tile (kb, kb) in padded shared memory
    for r in 0..<b {
      for c in 0..<b {
        let gr = k0 + r
        let gc = k0 + c
        sh_piv[r * pad_stride + c] = if gr < n && gc < n {
          dist[gr * n + gc]
        } else if gr == gc {
          0
        } else {
          trop_inf_i32
        }
      }
    }
    for m in 0..<b {
      for r in 0..<b {
        let rm = sh_piv[r * pad_stride + m]
        for c in 0..<b {
          let cand = trop_add_edge(rm, sh_piv[m * pad_stride + c])
          if cand < sh_piv[r * pad_stride + c] {
            sh_piv[r * pad_stride + c] = cand
          }
        }
      }
    }
    for r in 0..<b {
      for c in 0..<b {
        let gr = k0 + r
        let gc = k0 + c
        if gr < n && gc < n {
          dist[gr * n + gc] = sh_piv[r * pad_stride + c]
        }
      }
    }
    // Phase 2A: Pivot row blocks (kb, jb) for jb != kb
    for jb in 0..<num_blocks {
      if jb != kb {
        let j0 = jb * b
        for r in 0..<b {
          for c in 0..<b {
            let gr = k0 + r
            let gc = j0 + c
            sh_b[r * pad_stride + c] = if gr < n && gc < n {
              dist[gr * n + gc]
            } else {
              trop_inf_i32
            }
          }
        }
        for m in 0..<b {
          for r in 0..<b {
            let rm = sh_piv[r * pad_stride + m]
            for c in 0..<b {
              let cand = trop_add_edge(rm, sh_b[m * pad_stride + c])
              if cand < sh_b[r * pad_stride + c] {
                sh_b[r * pad_stride + c] = cand
              }
            }
          }
        }
        for r in 0..<b {
          for c in 0..<b {
            let gr = k0 + r
            let gc = j0 + c
            if gr < n && gc < n {
              dist[gr * n + gc] = sh_b[r * pad_stride + c]
            }
          }
        }
      }
    }
    // Phase 2B: Pivot column blocks (ib, kb) for ib != kb
    for ib in 0..<num_blocks {
      if ib != kb {
        let i0 = ib * b
        for r in 0..<b {
          for c in 0..<b {
            let gr = i0 + r
            let gc = k0 + c
            sh_a[r * pad_stride + c] = if gr < n && gc < n {
              dist[gr * n + gc]
            } else {
              trop_inf_i32
            }
          }
        }
        for m in 0..<b {
          for r in 0..<b {
            for c in 0..<b {
              let cand = trop_add_edge(
                sh_a[r * pad_stride + m],
                sh_piv[m * pad_stride + c],
              )
              if cand < sh_a[r * pad_stride + c] {
                sh_a[r * pad_stride + c] = cand
              }
            }
          }
        }
        for r in 0..<b {
          for c in 0..<b {
            let gr = i0 + r
            let gc = k0 + c
            if gr < n && gc < n {
              dist[gr * n + gc] = sh_a[r * pad_stride + c]
            }
          }
        }
      }
    }
    // Phase 3: Independent off-diagonal tiles (ib, jb) for ib != kb && jb != kb
    for ib in 0..<num_blocks {
      if ib != kb {
        let i0 = ib * b
        for r in 0..<b {
          for c in 0..<b {
            let gr = i0 + r
            let gc = k0 + c
            sh_a[r * pad_stride + c] = if gr < n && gc < n {
              dist[gr * n + gc]
            } else {
              trop_inf_i32
            }
          }
        }
        for jb in 0..<num_blocks {
          if jb != kb {
            let j0 = jb * b
            for r in 0..<b {
              for c in 0..<b {
                let gr_b = k0 + r
                let gc_b = j0 + c
                sh_b[r * pad_stride + c] = if gr_b < n && gc_b < n {
                  dist[gr_b * n + gc_b]
                } else {
                  trop_inf_i32
                }
                let gr_c = i0 + r
                let gc_c = j0 + c
                sh_c[r * pad_stride + c] = if gr_c < n && gc_c < n {
                  dist[gr_c * n + gc_c]
                } else {
                  trop_inf_i32
                }
              }
            }
            for r in 0..<b {
              for c in 0..<b {
                let mut acc = sh_c[r * pad_stride + c]
                for m in 0..<b {
                  let cand = trop_add_edge(
                    sh_a[r * pad_stride + m],
                    sh_b[m * pad_stride + c],
                  )
                  if cand < acc {
                    acc = cand
                  }
                }
                sh_c[r * pad_stride + c] = acc
              }
            }
            for r in 0..<b {
              for c in 0..<b {
                let gr = i0 + r
                let gc = j0 + c
                if gr < n && gc < n {
                  dist[gr * n + gc] = sh_c[r * pad_stride + c]
                }
              }
            }
          }
        }
      }
    }
  }
  dist
}
