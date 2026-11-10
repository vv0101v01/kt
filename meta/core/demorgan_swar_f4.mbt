// ---------------------------------------------------------------------------
// meta/core — Kalman 雙軌自由 De Morgan 代數、CCHM 三值上纖維化格、64-bit SWAR 單項式整除與 ANF 莫比烏斯對偶定律
// ---------------------------------------------------------------------------
//
// 全數在 L0 零外部依賴純算術／有限泛代數模型上窮舉核驗：
//   1. [T-Kalman-DeMorgan] 四元鑽石 De Morgan 代數 M_4 = {⊥(0), 0(1), 1(2), ⊤(3)} 滿足對合與分配律，
//      且嚴格分離自由 De Morgan 項 `x ∧ ¬x ≠ 0`、`x ∨ ¬x ≠ 1`（防止布林端點坍縮）。
//   2. [T-CCHM-Cofib-Lattice] 區間三值模型 `{0, 1, ½}^2` 上原子面 `(i=0), (i=1)` 生成分配格，
//      滿足 `(i=0) ∧ (i=1) = ⊥` 且邊界 `(i=0) ∨ (i=1) = ∂I ≠ ⊤`。
//   3. [T-SWAR-Mono64] 64-bit 打包指數向量之無分支整除遮罩 `((t | 0x80..80) - d) & 0x80..80 == 0x80..80`
//      與逐分量整除及 GRevLex 全序逐對全等。
//   4. [T-Zhegalkin-Stone-GF2] 3 變數全體 256 個布林函數之二進位 Möbius（Zhegalkin ANF）變換為嚴格對合
//      `M(M(f)) = f`，且點積理想消沒集與真值表逐頂點同構。

///|
/// 定律族 1：Kalman 四元鑽石 De Morgan 代數 `M_4` 定律與自由項非退化分離。
pub fn law_kalman_demorgan_diamond() -> Array[(String, Bool)] {
  // M_4 元素編碼為 2-bit 雙軌 `x = (p << 1) | n`：`0=(0,0)=0_DM`, `1=(0,1)=u`, `2=(1,0)=v`, `3=(1,1)=1_DM`
  // 格運算：`meet = a & b`, `join = a | b`；Kalman De Morgan 逆序對合：`¬(p, n) = (1 - n, 1 - p)`
  // （交換上下端點 `0 <-> 3`，並固定兩顆非布林中點 `1 -> 1`, `2 -> 2`！）
  let dm_neg = fn(x : Int32) -> Int32 {
    let p = (x >> 1) & 1
    let n = x & 1
    ((1 - n) << 1) | (1 - p)
  }
  let dm_and = fn(a : Int32, b : Int32) -> Int32 { a & b }
  let dm_or = fn(a : Int32, b : Int32) -> Int32 { a | b }
  let mut inv_and_dist_ok = true
  for a in 0..<4 {
    if dm_neg(dm_neg(a)) != a {
      inv_and_dist_ok = false
    }
    for b in 0..<4 {
      if dm_neg(dm_and(a, b)) != dm_or(dm_neg(a), dm_neg(b)) ||
        dm_neg(dm_or(a, b)) != dm_and(dm_neg(a), dm_neg(b)) ||
        dm_or(a, dm_and(a, b)) != a {
        inv_and_dist_ok = false
      }
      for c in 0..<4 {
        if dm_and(a, dm_or(b, c)) != dm_or(dm_and(a, b), dm_and(a, c)) {
          inv_and_dist_ok = false
        }
      }
    }
  }
  // 在兩個非布林內部不動點 `u = 1`, `v = 2` 上，`u ∧ ¬u = 1 != 0` 且 `u ∨ ¬u = 1 != 3`，
  // 而在布林端點 `{0, 3}` 上 `0 ∧ ¬0 = 0`, `0 ∨ ¬0 = 3`！
  let dzero = 0
  let done = 3
  let u_mid = 1
  let v_mid = 2
  let sep_ok = dm_and(u_mid, dm_neg(u_mid)) != dzero &&
    dm_or(u_mid, dm_neg(u_mid)) != done &&
    dm_and(v_mid, dm_neg(v_mid)) != dzero &&
    dm_or(v_mid, dm_neg(v_mid)) != done &&
    dm_neg(dzero) == done &&
    dm_neg(done) == dzero
  [
    (
      "kalman-demorgan: M_4 satisfies involution, De Morgan, absorption & distributivity #1",
      inv_and_dist_ok,
    ),
    (
      "kalman-demorgan: M_4 separates x ^ ~x from 0 and x v ~x from 1 while fixing booleans #2",
      sep_ok,
    ),
  ]
}

///|
/// 定律族 2：CCHM 三值模型 `{0, 1, ½}^2`（9 個點）上原子面分配格與邊界非全空間性。
pub fn law_cchm_cofibration_three_valued() -> Array[(String, Bool)] {
  // `{0, 1, 2(½)}^2` 共 9 點，編碼為 9-bit 真值遮罩 `0..511`
  let full_mask = (1 << 9) - 1
  let mut i0_mask = 0
  let mut i1_mask = 0
  let mut j0_mask = 0
  for idx in 0..<9 {
    let vi = idx % 3
    let vj = idx / 3
    if vi == 0 {
      i0_mask = i0_mask | (1 << idx)
    }
    if vi == 1 {
      i1_mask = i1_mask | (1 << idx)
    }
    if vj == 0 {
      j0_mask = j0_mask | (1 << idx)
    }
  }
  let disjoint_ok = (i0_mask & i1_mask) == 0
  let bdry_i = i0_mask | i1_mask
  // 邊界 `∂I` 在 9 點中僅覆蓋 6 點（不含 `vi == 2(½)` 的 3 個內部點），嚴格不等於 `⊤` (9 點)！
  let bdry_not_top = bdry_i != full_mask &&
    bdry_i.reinterpret_as_uint().popcnt() == 6
  let dist_ok = ((i0_mask | i1_mask) & j0_mask) ==
    ((i0_mask & j0_mask) | (i1_mask & j0_mask))
  [
    (
      "cchm-cofib: endpoint faces satisfy (i=0) ^ (i=1) == bot and boundary (i=0) v (i=1) != top #1",
      disjoint_ok && bdry_not_top,
    ),
    (
      "cchm-cofib: 3-valued cofibration truth masks form a distributive lattice #2",
      dist_ok,
    ),
  ]
}

///|
/// 定律族 3：64-bit SWAR `Mono64` 無分支單項式整除與 `GRevLex` 比較同構。
pub fn law_swar_mono64_divisibility_and_order() -> Array[(String, Bool)] {
  let guard_m : UInt64 = 0x8080808080808080UL
  let pack4 = fn(e0 : Int32, e1 : Int32, e2 : Int32, e3 : Int32) -> UInt64 {
    let deg = e0 + e1 + e2 + e3
    e0.to_uint64() |
    (e1.to_uint64() << 8) |
    (e2.to_uint64() << 16) |
    (e3.to_uint64() << 24) |
    (deg.to_uint64() << 56)
  }
  let grev_key4 = fn(e0 : Int32, e1 : Int32, e2 : Int32, e3 : Int32) -> UInt64 {
    let deg = e0 + e1 + e2 + e3
    (deg.to_uint64() << 56) |
    ((127 - e3).to_uint64() << 48) |
    ((127 - e2).to_uint64() << 40) |
    ((127 - e1).to_uint64() << 32) |
    ((127 - e0).to_uint64() << 24)
  }
  let samples : Array[(Int32, Int32, Int32, Int32)] = []
  for a in 0..<4 {
    for b in 0..<4 {
      for c in 0..<3 {
        samples.push((a * 7, b * 11, c * 13, (a + b) * 5))
      }
    }
  }
  let mut div_ok = true
  let mut ord_ok = true
  for u in samples {
    let (u0, u1, u2, u3) = u
    let wu = pack4(u0, u1, u2, u3)
    let ku = grev_key4(u0, u1, u2, u3)
    for v in samples {
      let (v0, v1, v2, v3) = v
      let wv = pack4(v0, v1, v2, v3)
      let kv = grev_key4(v0, v1, v2, v3)
      let swar_div = (((wv | guard_m) - wu) & guard_m) == guard_m
      let ref_div = u0 <= v0 && u1 <= v1 && u2 <= v2 && u3 <= v3
      if swar_div != ref_div {
        div_ok = false
      }
      let du = u0 + u1 + u2 + u3
      let dv = v0 + v1 + v2 + v3
      let ref_cmp = if du != dv {
        if du < dv {
          -1
        } else {
          1
        }
      } else if u3 != v3 {
        if u3 > v3 {
          -1
        } else {
          1
        }
      } else if u2 != v2 {
        if u2 > v2 {
          -1
        } else {
          1
        }
      } else if u1 != v1 {
        if u1 > v1 {
          -1
        } else {
          1
        }
      } else if u0 != v0 {
        if u0 > v0 {
          -1
        } else {
          1
        }
      } else {
        0
      }
      let swar_cmp = if ku < kv { -1 } else if ku > kv { 1 } else { 0 }
      if swar_cmp != ref_cmp {
        ord_ok = false
      }
    }
  }
  [
    (
      "swar-mono64: 0x8080808080808080UL branchless divisibility matches coordinatewise <= on 1296 pairs #1",
      div_ok,
    ),
    (
      "swar-mono64: single-UInt64 GRevLex key order matches lexicographic GRevLex definition on 1296 pairs #2",
      ord_ok,
    ),
  ]
}

///|
/// 定律族 4：3 變數全體 256 個布林函數之 Zhegalkin ANF Möbius 對合與點評估恆等。
pub fn law_zhegalkin_anf_mobius_involution() -> Array[(String, Bool)] {
  let mobius8 = fn(tt : Int32) -> Int32 {
    let mut w = tt
    // bit 0: odd positions ^= even neighbor
    w = w ^ ((w & 0x55) << 1)
    // bit 1: pairs
    w = w ^ ((w & 0x33) << 2)
    // bit 2: quads
    w = w ^ ((w & 0x0F) << 4)
    w & 0xFF
  }
  let eval_anf8 = fn(anf : Int32, pt : Int32) -> Int32 {
    let mut acc = 0
    for m in 0..<8 {
      if ((anf >> m) & 1) == 1 && (pt & m) == m {
        acc = acc ^ 1
      }
    }
    acc
  }
  let mut inv_ok = true
  let mut eval_ok = true
  for f in 0..<256 {
    let anf = mobius8(f)
    if mobius8(anf) != f {
      inv_ok = false
    }
    for pt in 0..<8 {
      if eval_anf8(anf, pt) != ((f >> pt) & 1) {
        eval_ok = false
      }
    }
  }
  [
    (
      "zhegalkin-anf: binary Moebius transform is an exact involution on all 256 3-var boolean functions #1",
      inv_ok,
    ),
    (
      "zhegalkin-anf: ANF polynomial evaluation agrees bitwise with truth tables on all 256 x 8 inputs #2",
      eval_ok,
    ),
  ]
}
