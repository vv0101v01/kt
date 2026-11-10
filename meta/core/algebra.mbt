// ---------------------------------------------------------------------------
// meta/core — 精確整數矩陣秩（真 Int64 無除法 Bareiss–Sylvester 消元 + Int64 有理互驗）
// ---------------------------------------------------------------------------
//
// 用途：切空間／Čech 上同調的障礙類、擬陣秩、覆蓋的神經（nerve）。
// 這些都要「秩」，而秩一定要精確 —— 浮點秩會把「有障礙」誤判成「可黏合」。
//
// 演算法定理（Sylvester–Bareiss 免除式恆等式）：
// 設 A^{(0)} = A 為整數矩陣，p_{(-1)} = 1。在第 k 步選取非零樞軸 p_k = A^{(k)}_{k,c_k} 後，
// 對所有列 i ≠ k 與行 j ≥ c_k 更新：
//     A^{(k+1)}_{i,j} = (p_k · A^{(k)}_{i,j} - A^{(k)}_{i,c_k} · A^{(k)}_{k,j}) / p_{k-1}
// 由 Sylvester 行列式恆等式，分子必為原矩陣之 (k+1)×(k+1) 子式與 p_{k-1} 的乘積，
// 故除以 p_{k-1} 恆為**精確整除**（餘數必為 0），無須每格執行 gcd 約分，亦消除 Int32 分數相乘溢位。

///|
priv struct QRat64 {
  num : Int64
  den : Int64
}

///|
fn gcd_i64(a : Int64, b : Int64) -> Int64 {
  let mut m = if a < 0L { -a } else { a }
  let mut n = if b < 0L { -b } else { b }
  while n != 0L {
    let r = m % n
    m = n
    n = r
  }
  if m == 0L {
    1L
  } else {
    m
  }
}

///|
fn qrat64(n : Int64, d : Int64) -> QRat64 {
  if d == 0L {
    return QRat64::{ num: 0L, den: 1L, }
  }
  let s = if d < 0L { -1L } else { 1L }
  let g = gcd_i64(n, d)
  QRat64::{ num: n / g * s, den: d / g * s, }
}

///|
fn qrat64_int(n : Int32) -> QRat64 {
  QRat64::{ num: n.to_int64(), den: 1L, }
}

///|
fn qrat64_is_zero(a : QRat64) -> Bool {
  a.num == 0L
}

///|
fn qrat64_sub(a : QRat64, b : QRat64) -> QRat64 {
  let g = gcd_i64(a.den, b.den)
  let bd = b.den / g
  let ad = a.den / g
  qrat64(a.num * bd - b.num * ad, ad * b.den)
}

///|
fn qrat64_mul(a : QRat64, b : QRat64) -> QRat64 {
  let g1 = gcd_i64(a.num, b.den)
  let g2 = gcd_i64(b.num, a.den)
  qrat64(a.num / g1 * (b.num / g2), a.den / g2 * (b.den / g1))
}

///|
fn qrat64_div(a : QRat64, b : QRat64) -> QRat64 {
  if qrat64_is_zero(b) {
    qrat64(0L, 1L)
  } else {
    qrat64_mul(a, QRat64::{ num: b.den, den: b.num, })
  }
}

///|
/// 真 Int64 免除式（Fraction-Free）兩側 Jordan–Bareiss 矩陣秩與精確整除憑證：
/// 回傳 `(rank, exact_division_witness)`，其中 `exact_division_witness` 驗證每一步
/// Sylvester 除法餘數皆嚴格為 0。
pub fn matrix_rank_bareiss64_with_cert(
  m : Array[Array[Int32]],
) -> (Int32, Bool) {
  let rows = m.length()
  if rows == 0 {
    return (0, true)
  }
  let cols = m[0].length()
  if cols == 0 {
    return (0, true)
  }
  // 一維連續列主序緩衝（消除鋸齒指標陣列）
  let buf : Array[Int64] = Array::make(rows * cols, 0L)
  for i in 0..<rows {
    let base = i * cols
    let row = m[i]
    for j in 0..<cols {
      buf[base + j] = row[j].to_int64()
    }
  }
  let mut rank = 0
  let mut prev_pivot = 1L
  let mut exact_ok = true
  for col in 0..<cols {
    if rank >= rows {
      break
    }
    let mut pivot = -1
    for r in rank..<rows {
      if buf[r * cols + col] != 0L {
        pivot = r
        break
      }
    }
    if pivot >= 0 {
      if pivot != rank {
        let b1 = pivot * cols
        let b2 = rank * cols
        for j in 0..<cols {
          let tmp = buf[b1 + j]
          buf[b1 + j] = buf[b2 + j]
          buf[b2 + j] = tmp
        }
      }
      let pv = buf[rank * cols + col]
      let rank_base = rank * cols
      for i in 0..<rows {
        if i != rank {
          let i_base = i * cols
          let a_ic = buf[i_base + col]
          for j in col..<cols {
            let num = pv * buf[i_base + j] - a_ic * buf[rank_base + j]
            if num % prev_pivot != 0L {
              exact_ok = false
            }
            buf[i_base + j] = num / prev_pivot
          }
          buf[i_base + col] = 0L
        }
      }
      prev_pivot = pv
      rank = rank + 1
    }
  }
  (rank, exact_ok)
}

///|
/// Int64 有理消元對照秩（用於雙軌互驗與超大規模子式退避）。
pub fn matrix_rank_qrat64(m : Array[Array[Int32]]) -> Int32 {
  let rows = m.length()
  if rows == 0 {
    return 0
  }
  let cols = m[0].length()
  let a : Array[QRat64] = Array::make(rows * cols, QRat64::{ num: 0L, den: 1L, })
  for i in 0..<rows {
    for j in 0..<cols {
      a[i * cols + j] = qrat64_int(m[i][j])
    }
  }
  let mut rank = 0
  for col in 0..<cols {
    if rank >= rows {
      break
    }
    let mut pivot = -1
    for r in rank..<rows {
      if !qrat64_is_zero(a[r * cols + col]) {
        pivot = r
        break
      }
    }
    if pivot >= 0 {
      if pivot != rank {
        for j in 0..<cols {
          let tmp = a[pivot * cols + j]
          a[pivot * cols + j] = a[rank * cols + j]
          a[rank * cols + j] = tmp
        }
      }
      let pv = a[rank * cols + col]
      for i in 0..<rows {
        if i != rank && !qrat64_is_zero(a[i * cols + col]) {
          let f = qrat64_div(a[i * cols + col], pv)
          for j in col..<cols {
            a[i * cols + j] = qrat64_sub(
              a[i * cols + j],
              qrat64_mul(f, a[rank * cols + j]),
            )
          }
        }
      }
      rank = rank + 1
    }
  }
  rank
}

///|
/// ℚ 上矩陣秩（預設走真 Int64 無除法 Bareiss 連續緩衝核心）。空矩陣秩為 0。
pub fn matrix_rank(m : Array[Array[Int32]]) -> Int32 {
  let (r, _) = matrix_rank_bareiss64_with_cert(m)
  r
}

///|
/// 整數矩陣秩：只做 rank 的整數版本（給呼叫端少一層型別轉換）。
pub fn rank_int(m : Array[Array[Int32]]) -> Int32 {
  matrix_rank(m)
}

///|
/// 整數矩陣右零空間維數（nullity = cols - rank）。
pub fn integer_nullity(m : Array[Array[Int32]]) -> Int32 {
  if m.length() == 0 {
    return 0
  }
  m[0].length() - matrix_rank(m)
}

///|
/// 矩陣轉置。
pub fn mat_transpose(m : Array[Array[Int32]]) -> Array[Array[Int32]] {
  if m.length() == 0 {
    return []
  }
  let cols = m[0].length()
  let out : Array[Array[Int32]] = []
  for j in 0..<cols {
    let row : Array[Int32] = []
    for i in 0..<m.length() {
      row.push(m[i][j])
    }
    out.push(row)
  }
  out
}

///|
/// 矩陣乘積（內部以 Int64 累加避免中繼點積溢位）。
pub fn mat_mul(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  if a.length() == 0 || b.length() == 0 {
    return out
  }
  let n = a.length()
  let k = b.length()
  let mcols = b[0].length()
  for i in 0..<n {
    let row : Array[Int32] = []
    for j in 0..<mcols {
      let mut s = 0L
      for t in 0..<k {
        s = s + a[i][t].to_int64() * b[t][j].to_int64()
      }
      row.push(s.to_int())
    }
    out.push(row)
  }
  out
}

///|
/// 單位矩陣。
pub fn mat_identity(n : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  for i in 0..<n {
    let row : Array[Int32] = []
    for j in 0..<n {
      row.push(if i == j { 1 } else { 0 })
    }
    out.push(row)
  }
  out
}

///|
pub fn law_algebra_exact_rational_rank() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // [[1,2],[2,4]] 秩 1
  chk(out, "exact rational rank #1", rank_int([[1, 2], [2, 4]]) == 1)
  // 3×3 滿秩
  chk(
    out,
    "exact rational rank #2",
    rank_int([[1, 0, 0], [0, 2, 0], [0, 0, 3]]) == 3,
  )
  // 邊界矩陣型態：[[1,-1,0],[0,1,-1]] 秩 2
  chk(out, "exact rational rank #3", rank_int([[1, -1, 0], [0, 1, -1]]) == 2)
  // 乘積保秩上限
  let a = [[1, 2, 3], [4, 5, 6]]
  let b = mat_transpose(a)
  chk(out, "exact rational rank #4", rank_int(mat_mul(a, b)) == 2)
  chk(out, "exact rational rank #5", mat_identity(3)[2][2] == 1)
  out
}

///|
/// Sylvester–Bareiss 免除式整除恆等式與高階子式零溢位互驗定律。
pub fn law_algebra_bareiss64_sylvester_exactness() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // 7×7 質數偏移 Cauchy-Vandermonde 型高成長整數矩陣（傳統 Int32 分母通分必溢位）
  let hi : Array[Array[Int32]] = []
  for i in 0..<7 {
    let row : Array[Int32] = []
    for j in 0..<7 {
      let base = i + 2
      let mut p = 1
      for _ in 0..<j {
        p = p * base
      }
      row.push(p + (if i == j { 1 } else { 0 }))
    }
    hi.push(row)
  }
  let (r_hi, cert_hi) = matrix_rank_bareiss64_with_cert(hi)
  chk(
    out,
    "bareiss64 sylvester exactness #1 (7x7 high-minor exact division & full rank)",
    cert_hi && r_hi == 7 && matrix_rank_qrat64(hi) == 7,
  )
  // 退化鏈複形邊界矩陣 d_1 ∘ d_2 = 0：rank + nullity == cols 且整除憑證成立
  let d1 : Array[Array[Int32]] = [
    [-1, -1, -1, 0, 0, 0],
    [1, 0, 0, -1, -1, 0],
    [0, 1, 0, 1, 0, -1],
    [0, 0, 1, 0, 1, 1],
  ]
  let (r_d1, cert_d1) = matrix_rank_bareiss64_with_cert(d1)
  chk(
    out,
    "bareiss64 sylvester exactness #2 (K4 boundary rank=3, nullity=3, zero remainder)",
    cert_d1 &&
    r_d1 == 3 &&
    integer_nullity(d1) == 3 &&
    matrix_rank_qrat64(d1) == 3,
  )
  out
}
