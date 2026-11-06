// ---------------------------------------------------------------------------
// meta/core — 精確有理數與整數矩陣秩（Bareiss 免除式消元）
// ---------------------------------------------------------------------------
//
// 用途：切空間／Čech 上同調的障礙類、擬陣秩、覆蓋的神經（nerve）。
// 這些都要「秩」，而秩一定要精確 —— 浮點秩會把「有障礙」誤判成「可黏合」。
// 所以這裡用 ℚ 上精確消元（分子分母 + gcd 約分），不引入任何近似。

///|
priv struct QRat {
  num : Int32
  den : Int32
}

///|
fn gcd_i(a : Int32, b : Int32) -> Int32 {
  let x = if a < 0 { -a } else { a }
  let y = if b < 0 { -b } else { b }
  let mut m = x
  let mut n = y
  while n != 0 {
    let r = m % n
    m = n
    n = r
  }
  if m == 0 {
    1
  } else {
    m
  }
}

///|
fn qrat(n : Int32, d : Int32) -> QRat {
  if d == 0 {
    return QRat::{ num: 0, den: 1, }
  }
  let s = if d < 0 { -1 } else { 1 }
  let g = gcd_i(n, d)
  QRat::{ num: n * s / g, den: d * s / g, }
}

///|
fn qrat_int(n : Int32) -> QRat {
  QRat::{ num: n, den: 1, }
}

///|
fn qrat_is_zero(a : QRat) -> Bool {
  a.num == 0
}

///|
fn qrat_sub(a : QRat, b : QRat) -> QRat {
  qrat(a.num * b.den - b.num * a.den, a.den * b.den)
}

///|
fn qrat_mul(a : QRat, b : QRat) -> QRat {
  qrat(a.num * b.num, a.den * b.den)
}

///|
fn qrat_div(a : QRat, b : QRat) -> QRat {
  if qrat_is_zero(b) {
    qrat(0, 1)
  } else {
    qrat(a.num * b.den, a.den * b.num)
  }
}

///|
/// ℚ 上矩陣秩（列階梯形，精確）。空矩陣秩為 0。
pub fn matrix_rank(m : Array[Array[Int32]]) -> Int32 {
  let rows = m.length()
  if rows == 0 {
    return 0
  }
  let cols = m[0].length()
  let a : Array[Array[QRat]] = []
  for i in 0..<rows {
    let row : Array[QRat] = []
    for j in 0..<cols {
      row.push(qrat_int(m[i][j]))
    }
    a.push(row)
  }
  let mut rank = 0
  let mut col = 0
  while col < cols && rank < rows {
    // 找樞軸
    let mut pivot = -1
    let mut r = rank
    while r < rows {
      if !qrat_is_zero(a[r][col]) {
        pivot = r
        r = rows
      } else {
        r = r + 1
      }
    }
    if pivot >= 0 {
      let tmp = a[pivot]
      a[pivot] = a[rank]
      a[rank] = tmp
      let pv = a[rank][col]
      for i in 0..<rows {
        if i != rank && !qrat_is_zero(a[i][col]) {
          let f = qrat_div(a[i][col], pv)
          for j in col..<cols {
            a[i][j] = qrat_sub(a[i][j], qrat_mul(f, a[rank][j]))
          }
        }
      }
      rank = rank + 1
    }
    col = col + 1
  }
  rank
}

///|
/// 整數矩陣秩：只做 rank 的整數版本（給呼叫端少一層型別轉換）。
pub fn rank_int(m : Array[Array[Int32]]) -> Int32 {
  matrix_rank(m)
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
/// 矩陣乘積。
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
      let mut s = 0
      for t in 0..<k {
        s = s + a[i][t] * b[t][j]
      }
      row.push(s)
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
