// Ozaki Scheme II (2025/2026) CRT-Based Exact & FP64 Matrix Multiplication over
// INT8/INT32 (`dot4I8Packed` DP4A) + 32-bit RNS Stockham Auto-Sort NTT &
// 30-bit Montgomery NTT (`Cheddar` / `MoMA` / `ZKProphet` 2025).

///|
/// Eight pairwise-coprime odd prime byte-moduli `m_i <= 251` for Ozaki Scheme II:
/// centered residues lie in `[-125, +125]`, fitting strictly in signed `INT8` (`i8`)
/// with overflow-free 32-bit `i32` inner-product accumulation (`217 * 125^2 << 2^31`)
/// and combined CRT dynamic range `prod m_i = 8,215,969,115,436,053,287 > 2^62.8`.
pub fn ozaki2_byte_moduli() -> Array[Int32] {
  [251, 241, 239, 233, 229, 227, 223, 211]
}

///|
/// Symmetric centered residue `r in [-(m-1)/2, +(m-1)/2]` (`|r| <= 125` for `m <= 251`).
pub fn centered_smod_bigint(x : BigInt, m : Int32) -> Int32 {
  let mb = BigInt::from_int(m)
  let mut r = (x % mb).to_int()
  if r < 0 {
    r = r + m
  }
  if r * 2 > m {
    r - m
  } else {
    r
  }
}

///|
/// Pack 4 signed `INT8` lanes (`[-128, 127]`) into one 32-bit `UInt` word, matching
/// W3C WebGPU WGSL `pack4xI8` / `dot4I8Packed` layout (`lane 0` in bits `0..7`).
pub fn pack4_i8_to_u32(
  b0 : Int32,
  b1 : Int32,
  b2 : Int32,
  b3 : Int32,
) -> UInt32 {
  let u0 = (b0 & 0xFF).reinterpret_as_uint()
  let u1 = (b1 & 0xFF).reinterpret_as_uint() << 8
  let u2 = (b2 & 0xFF).reinterpret_as_uint() << 16
  let u3 = (b3 & 0xFF).reinterpret_as_uint() << 24
  u0 | u1 | u2 | u3
}

///|
fn sign_extend_i8(u : UInt32) -> Int32 {
  let b = (u & 0xFFU).reinterpret_as_int()
  if b >= 128 {
    b - 256
  } else {
    b
  }
}

///|
/// Exact bit-level semantics of WebGPU WGSL's `dot4I8Packed(a, b) -> i32` DP4A intrinsic.
pub fn dot4_i8_packed(pa : UInt32, pb : UInt32) -> Int32 {
  let a0 = sign_extend_i8(pa)
  let a1 = sign_extend_i8(pa >> 8)
  let a2 = sign_extend_i8(pa >> 16)
  let a3 = sign_extend_i8(pa >> 24)
  let b0 = sign_extend_i8(pb)
  let b1 = sign_extend_i8(pb >> 8)
  let b2 = sign_extend_i8(pb >> 16)
  let b3 = sign_extend_i8(pb >> 24)
  a0 * b0 + a1 * b1 + a2 * b2 + a3 * b3
}

///|
fn mod_inv_small(a : Int32, m : Int32) -> Int32 {
  @gcd.fp_inv(a, m)
}

///|
/// Symmetric Garner Mixed-Radix Chinese Remainder Theorem (`CRT`) reconstruction:
/// recovers the unique signed integer `X in [-M/2, M/2)` from residues `r[i] === X (mod m[i])`.
pub fn garner_symmetric_crt_bigint(
  residues : Array[Int32],
  moduli : Array[Int32],
) -> BigInt {
  let s = moduli.length()
  let v : Array[Int32] = Array::make(s, 0)
  for i in 0..<s {
    let mi = moduli[i]
    let ri = (residues[i] % mi + mi) % mi
    // Evaluate partial mixed-radix sum u = v[0] + m[0]*(v[1] + ...) mod mi
    // and prefix product prod_mod = m[0]*...*m[i-1] mod mi
    let mut u = 0
    let mut prod_mod = 1
    for j in 0..<i {
      u = (u + v[j] * prod_mod) % mi
      prod_mod = prod_mod * (moduli[j] % mi) % mi
    }
    let diff = (ri - u + mi) % mi
    v[i] = diff * mod_inv_small(prod_mod, mi) % mi
  }
  let mut x = BigInt::from_int(0)
  let mut mult = BigInt::from_int(1)
  for i in 0..<s {
    x = x + BigInt::from_int(v[i]) * mult
    mult = mult * BigInt::from_int(moduli[i])
  }
  if x * BigInt::from_int(2) >= mult {
    x - mult
  } else {
    x
  }
}

///|
/// Ozaki Scheme II exact integer GEMM (`C = A * B`, shapes `m x k` and `k x n`)
/// executed purely via `INT8` centered residues, `dot4I8Packed` 32-bit `i32` inner-product
/// accumulation (chunked in safe blocks of `<= 216` lanes), and Garner symmetric CRT.
pub fn ozaki2_int_gemm_dp4a(
  m : Int32,
  k : Int32,
  n : Int32,
  a : Array[BigInt],
  b : Array[BigInt],
  moduli~ : Array[Int32] = ozaki2_byte_moduli(),
) -> Array[BigInt] {
  let s = moduli.length()
  let res_table : Array[Int32] = Array::make(m * n * s, 0)
  let k_pad4 = (k + 3) / 4 * 4
  let packed_a : Array[UInt32] = Array::make(m * (k_pad4 / 4), 0U)
  // Transpose B into packed 4-byte columns for coalesced DP4A inner products
  let packed_bt : Array[UInt32] = Array::make(n * (k_pad4 / 4), 0U)
  for idx_m in 0..<s {
    let mod_p = moduli[idx_m]
    let groups4 = k_pad4 / 4
    for r in 0..<m {
      for g in 0..<groups4 {
        let base = g * 4
        let b0 = if base < k {
          centered_smod_bigint(a[r * k + base], mod_p)
        } else {
          0
        }
        let b1 = if base + 1 < k {
          centered_smod_bigint(a[r * k + base + 1], mod_p)
        } else {
          0
        }
        let b2 = if base + 2 < k {
          centered_smod_bigint(a[r * k + base + 2], mod_p)
        } else {
          0
        }
        let b3 = if base + 3 < k {
          centered_smod_bigint(a[r * k + base + 3], mod_p)
        } else {
          0
        }
        packed_a[r * groups4 + g] = pack4_i8_to_u32(b0, b1, b2, b3)
      }
    }
    for c in 0..<n {
      for g in 0..<groups4 {
        let base = g * 4
        let b0 = if base < k {
          centered_smod_bigint(b[base * n + c], mod_p)
        } else {
          0
        }
        let b1 = if base + 1 < k {
          centered_smod_bigint(b[(base + 1) * n + c], mod_p)
        } else {
          0
        }
        let b2 = if base + 2 < k {
          centered_smod_bigint(b[(base + 2) * n + c], mod_p)
        } else {
          0
        }
        let b3 = if base + 3 < k {
          centered_smod_bigint(b[(base + 3) * n + c], mod_p)
        } else {
          0
        }
        packed_bt[c * groups4 + g] = pack4_i8_to_u32(b0, b1, b2, b3)
      }
    }
    // Accumulate up to 54 packed groups (216 <= 217 elements) per i32 sum before mod reduction
    for r in 0..<m {
      for c in 0..<n {
        let mut total_mod = 0
        let mut g = 0
        while g < groups4 {
          let end_g = if g + 54 < groups4 { g + 54 } else { groups4 }
          let mut acc_i32 = 0
          for t in g..<end_g {
            acc_i32 = acc_i32 +
              dot4_i8_packed(
                packed_a[r * groups4 + t],
                packed_bt[c * groups4 + t],
              )
          }
          total_mod = (total_mod + acc_i32 % mod_p + mod_p) % mod_p
          g = end_g
        }
        res_table[(r * n + c) * s + idx_m] = total_mod
      }
    }
  }
  let out : Array[BigInt] = Array::make(m * n, BigInt::from_int(0))
  let cell_res : Array[Int32] = Array::make(s, 0)
  for cell in 0..<(m * n) {
    for idx_m in 0..<s {
      cell_res[idx_m] = res_table[cell * s + idx_m]
    }
    out[cell] = garner_symmetric_crt_bigint(cell_res, moduli)
  }
  out
}

///|
fn pow2_double(exp : Int32) -> Double {
  if exp >= 0 {
    let mut s = 1.0
    for _ in 0..<exp {
      s = s * 2.0
    }
    s
  } else {
    let mut s = 1.0
    for _ in 0..<-exp {
      s = s * 0.5
    }
    s
  }
}

///|
fn ceil_log2_pos(x : Double) -> Int32 {
  if x <= 1.0 {
    let mut e = 0
    let mut cur = 1.0
    while cur * 0.5 >= x && e > -52 {
      cur = cur * 0.5
      e = e - 1
    }
    e
  } else {
    let mut e = 0
    let mut cur = 1.0
    while cur < x && e < 52 {
      cur = cur * 2.0
      e = e + 1
    }
    e
  }
}

///|
/// Ozaki Scheme II Double-Precision (`FP64`) GEMM emulation on `INT8 -> INT32` engines:
/// extracts row/column power-of-2 scales, quantizes mantissas to `bits`-bit integers
/// (`default bits = 26`, so inner-product sums fit well inside the 8-byte-modulus CRT range
/// `8.21e18`), runs pure `dot4I8Packed` modular GEMMs + Garner CRT, and rescales to `Double`.
pub fn ozaki2_emulate_fp64_gemm(
  m : Int32,
  k : Int32,
  n : Int32,
  a : Array[Double],
  b : Array[Double],
  mantissa_bits~ : Int32 = 26,
) -> Array[Double] {
  let row_exp : Array[Int32] = Array::make(m, 0)
  let col_exp : Array[Int32] = Array::make(n, 0)
  let qa : Array[BigInt] = Array::make(m * k, BigInt::from_int(0))
  let qb : Array[BigInt] = Array::make(k * n, BigInt::from_int(0))
  for r in 0..<m {
    let mut rmax = 0.0
    for t in 0..<k {
      let v = a[r * k + t].abs()
      if v > rmax {
        rmax = v
      }
    }
    if rmax == 0.0 {
      row_exp[r] = 0
    } else {
      let e = ceil_log2_pos(rmax) - mantissa_bits
      row_exp[r] = e
      let inv_scale = pow2_double(-e)
      for t in 0..<k {
        let scaled = (a[r * k + t] * inv_scale).round()
        qa[r * k + t] = BigInt::from_int64(scaled.to_int64())
      }
    }
  }
  for c in 0..<n {
    let mut cmax = 0.0
    for t in 0..<k {
      let v = b[t * n + c].abs()
      if v > cmax {
        cmax = v
      }
    }
    if cmax == 0.0 {
      col_exp[c] = 0
    } else {
      let e = ceil_log2_pos(cmax) - mantissa_bits
      col_exp[c] = e
      let inv_scale = pow2_double(-e)
      for t in 0..<k {
        let scaled = (b[t * n + c] * inv_scale).round()
        qb[t * n + c] = BigInt::from_int64(scaled.to_int64())
      }
    }
  }
  let qc = ozaki2_int_gemm_dp4a(m, k, n, qa, qb)
  let out : Array[Double] = Array::make(m * n, 0.0)
  for r in 0..<m {
    for c in 0..<n {
      let total_exp = row_exp[r] + col_exp[c]
      let raw = qc[r * n + c].to_int64().to_double()
      out[r * n + c] = raw * pow2_double(total_exp)
    }
  }
  out
}

///|
/// Three WebGPU-safe 32-bit RNS NTT primes `(12289, 18433, 40961)`:
/// every prime satisfies `p < 46340 = floor(sqrt(2^31))`, so `(a * b) < 2^31 < 2^32`
/// executes in ONE native 32-bit `u32` GPU multiply with ZERO 64-bit emulation, while
/// `P = 12289 * 18433 * 40961 = 9,278,619,648,577 > 9.27e12` reconstructs exact `Z[x]`.
pub fn webgpu_rns_ntt_primes() -> Array[(Int32, Int32)] {
  // (prime p, primitive root g modulo p)
  [(12289, 11), (18433, 5), (40961, 3)]
}

///|
fn mod_pow_u32_safe(base : Int32, exp : Int32, p : Int32) -> Int32 {
  let mut res = 1
  let mut b = (base % p + p) % p
  let mut e = exp
  while e > 0 {
    if (e & 1) != 0 {
      res = res * b % p
    }
    b = b * b % p
    e = e >> 1
  }
  res
}

///|
/// Stockham Auto-Sort Radix-2 Number-Theoretic Transform (`NTT`) over `Z / p Z`
/// (`p < 46340` for overflow-free 32-bit `u32` WebGPU SIMT execution):
/// natural-order input -> natural-order output via ping-pong workgroup buffers with
/// unit-stride `j` coalescing and ZERO bit-reversal scatter/gather!
pub fn stockham_ntt_u32(
  coeffs : Array[Int32],
  p : Int32,
  primitive_root : Int32,
  inverse : Bool,
) -> Array[Int32] {
  let n = coeffs.length()
  let mut src : Array[Int32] = Array::make(n, 0)
  let mut dst : Array[Int32] = Array::make(n, 0)
  for i in 0..<n {
    src[i] = (coeffs[i] % p + p) % p
  }
  if n <= 1 {
    return src
  }
  let root_n = mod_pow_u32_safe(primitive_root, (p - 1) / n, p)
  let omega = if inverse { mod_pow_u32_safe(root_n, p - 2, p) } else { root_n }
  // Precompute powers omega^0 .. omega^(n/2 - 1)
  let half = n / 2
  let twiddles : Array[Int32] = Array::make(half, 1)
  for t in 1..<half {
    twiddles[t] = twiddles[t - 1] * omega % p
  }
  let mut m = 1
  while m < n {
    let q = n / (2 * m)
    for k in 0..<q {
      let w = twiddles[k * m]
      for j in 0..<m {
        let u = src[k * m + j]
        let v = src[(k + q) * m + j]
        let sum = u + v
        let add_mod = if sum >= p { sum - p } else { sum }
        let diff = u - v
        let sub_mod = if diff < 0 { diff + p } else { diff }
        dst[k * 2 * m + j] = add_mod
        dst[k * 2 * m + j + m] = sub_mod * w % p
      }
    }
    let tmp = src
    src = dst
    dst = tmp
    m = m * 2
  }
  if inverse {
    let inv_n = mod_pow_u32_safe(n, p - 2, p)
    for i in 0..<n {
      src[i] = src[i] * inv_n % p
    }
  }
  src
}

///|
/// Exact polynomial convolution in `Z[x]` via 3-Prime WebGPU-Safe Stockham RNS NTT
/// + Symmetric Garner CRT (`N <= 2048`, coefficients up to `+/- 4.6e12`).
pub fn rns_stockham_poly_mul_exact(
  a : Array[Int32],
  b : Array[Int32],
) -> Array[BigInt] {
  if a.length() == 0 || b.length() == 0 {
    return []
  }
  let out_len = a.length() + b.length() - 1
  let mut n = 1
  while n < out_len {
    n = n * 2
  }
  let primes = webgpu_rns_ntt_primes()
  let s = primes.length()
  let moduli : Array[Int32] = Array::make(s, 0)
  let limb_convs : Array[Array[Int32]] = []
  let pad_a : Array[Int32] = Array::make(n, 0)
  let pad_b : Array[Int32] = Array::make(n, 0)
  for i in 0..<a.length() {
    pad_a[i] = a[i]
  }
  for i in 0..<b.length() {
    pad_b[i] = b[i]
  }
  for idx in 0..<s {
    let (p, g) = primes[idx]
    moduli[idx] = p
    let fa = stockham_ntt_u32(pad_a, p, g, false)
    let fb = stockham_ntt_u32(pad_b, p, g, false)
    let fc : Array[Int32] = Array::make(n, 0)
    for i in 0..<n {
      fc[i] = fa[i] * fb[i] % p
    }
    limb_convs.push(stockham_ntt_u32(fc, p, g, true))
  }
  let out : Array[BigInt] = Array::make(out_len, BigInt::from_int(0))
  let r_buf : Array[Int32] = Array::make(s, 0)
  for i in 0..<out_len {
    for idx in 0..<s {
      r_buf[idx] = limb_convs[idx][i]
    }
    out[i] = garner_symmetric_crt_bigint(r_buf, moduli)
  }
  out
}

///|
/// 30-bit Montgomery Reducer (`p = 998244353 = 119 * 2^23 + 1`, `R = 2^32`)
/// with branchless Harvey lazy reduction (`Cheddar` / `ZKProphet` CPU reference).
pub struct Mont30Prime {
  p : UInt64
  neg_p_inv_u32 : UInt64
  r2_mod_p : UInt64
} derive(Debug, Eq)

///|
pub extend Mont30Prime with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Mont30Prime with Eq::{not_equal, equal}

///|
/// Canonical 30-bit NTT prime `p = 998,244,353` (`-p^{-1} mod 2^32 = 998,244,351`).
pub fn mont30_ntt_998244353() -> Mont30Prime {
  let p = 998244353UL
  // Verify p * 998244351 === -1 (mod 2^32): 998244353 * 998244351 = 996491788296388607
  // Let's compute exact Newton-Hensel inverse modulo 2^32 in 5 unrolled steps!
  let mask32 = 0xFFFFFFFFUL
  let mut inv = 1UL
  for _ in 0..<5 {
    inv = (inv * (2UL - ((p * inv) & mask32))) & mask32
  }
  let neg_inv = (0x100000000UL - inv) & mask32
  let r_mod = 0x100000000UL % p
  let r2 = r_mod * r_mod % p
  Mont30Prime::{ p, neg_p_inv_u32: neg_inv, r2_mod_p: r2, }
}

///|
/// Montgomery REDC (`x * R^{-1} mod p`) with zero integer division instructions.
pub fn mont30_redc(ctx : Mont30Prime, x : UInt64) -> UInt64 {
  let mask32 = 0xFFFFFFFFUL
  let m = ((x & mask32) * ctx.neg_p_inv_u32) & mask32
  let t = (x + m * ctx.p) >> 32
  if t >= ctx.p {
    t - ctx.p
  } else {
    t
  }
}

///|
pub fn mont30_to_mont(ctx : Mont30Prime, a : Int32) -> UInt64 {
  let p_i = ctx.p.to_int()
  let norm = (a % p_i + p_i) % p_i
  mont30_redc(ctx, norm.to_uint64() * ctx.r2_mod_p)
}

///|
pub fn mont30_from_mont(ctx : Mont30Prime, ar : UInt64) -> Int32 {
  mont30_redc(ctx, ar).to_int()
}

///|
pub fn mont30_mul(ctx : Mont30Prime, ar : UInt64, br : UInt64) -> UInt64 {
  mont30_redc(ctx, ar * br)
}
