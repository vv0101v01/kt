// ---------------------------------------------------------------------------
// ualg/demorgan — 立方複形：同調、開盒、懸掛、推出、Künneth、Hodge 譜
// ---------------------------------------------------------------------------
//
// [D-Cx]    □ⁿ 的面以三進位編碼（位 i：0/1 = 固定端點，2 = 自由）；
//           子複形 = 對取面封閉的面集合（即 𝔽(n) 的元素）。
// [D-Bd]    ∂[f] = Σ_t (−1)^t ([f|第 t 個自由位:=1] − [f|第 t 個自由位:=0])。
// [T-Box]   開盒 ⊔ⁿ（邊界去掉一個面）無環，∂□ⁿ 有 β_{n−1} = 1：
//           Kan 填充的同調影子——開盒 ↪ □ⁿ 是同調等價，邊界 ↪ □ⁿ 不是。
// [T-Susp]  懸掛 ΣK = K×I ∪ □ⁿ×∂I：β̃_{k+1}(ΣK) = β̃_k(K)；Σᵏ S⁰ = Sᵏ。
// [T-Push]  推出：開盒 ∪_{S^{n−2}} 面 = ∂□ⁿ = S^{n−1}（兩個圓盤沿赤道黏合）。
// [T-Kun]   Künneth：P(K×L) = P(K)·P(L)；環面 T² = (1,2,1)、T³ = (1,3,3,1)。
// [T-Hodge] dim ker Δ_k = β_k；Δ_k(□ⁿ) 的譜 = {2(k+j) : 重數 C(n,k)·C(n−k,j)}。
// [A-Rank]  秩兩條路徑：Bareiss 無分數消去（ℚ 上精確）與 mod p 消去。

///|
pub fn pow3(n : Int32) -> Int32 {
  let mut r = 1
  for _ in 0..<n {
    r = r * 3
  }
  r
}

///|
pub fn face_digit(code : Int32, i : Int32) -> Int32 {
  code / pow3(i) % 3
}

///|
pub fn face_dim(code : Int32, n : Int32) -> Int32 {
  let mut d = 0
  for i in 0..<n {
    if face_digit(code, i) == 2 {
      d = d + 1
    }
  }
  d
}

///|
pub fn cx_full(n : Int32) -> Array[Bool] {
  Array::make(pow3(n), true)
}

///|
/// ∂□ⁿ：去掉頂面。
pub fn cx_boundary(n : Int32) -> Array[Bool] {
  Array::makei(pow3(n), c => c != pow3(n) - 1)
}

///|
/// 閉面 {x_i = b}。
pub fn cx_facet(n : Int32, i : Int32, b : Int32) -> Array[Bool] {
  Array::makei(pow3(n), c => face_digit(c, i) == b)
}

///|
/// 開盒：除了 {x_i = b} 以外的 2n−1 個閉面的聯集。
pub fn cx_open_box(n : Int32, i : Int32, b : Int32) -> Array[Bool] {
  Array::makei(pow3(n), c => {
    for k in 0..<n {
      for e in 0..<2 {
        if (k != i || e != b) && face_digit(c, k) == e {
          return true
        }
      }
    }
    false
  })
}

///|
pub fn cx_union(k : Array[Bool], l : Array[Bool]) -> Array[Bool] {
  Array::makei(k.length(), c => k[c] || l[c])
}

///|
pub fn cx_inter(k : Array[Bool], l : Array[Bool]) -> Array[Bool] {
  Array::makei(k.length(), c => k[c] && l[c])
}

///|
/// K ⊆ □ᵃ、L ⊆ □ᵇ 的積 K×L ⊆ □^{a+b}（編碼 c_K + 3ᵃ·c_L）。
pub fn cx_product(k : Array[Bool], l : Array[Bool]) -> Array[Bool] {
  let w = k.length()
  Array::makei(w * l.length(), c => k[c % w] && l[c / w])
}

///|
/// [T-Susp] 懸掛：新方向為端點時整個 □ⁿ 都在（兩個錐頂），自由時只留 K。
pub fn cx_suspension(k : Array[Bool]) -> Array[Bool] {
  let w = k.length()
  Array::makei(3 * w, c => c / w < 2 || k[c % w])
}

///|
pub fn cx_is_complex(k : Array[Bool], n : Int32) -> Bool {
  for c in 0..<k.length() {
    if k[c] {
      for i in 0..<n {
        if face_digit(c, i) == 2 &&
          (!k[c - pow3(i)] || !k[c - 2 * pow3(i)]) {
          return false
        }
      }
    }
  }
  true
}

///|
/// 依維數分組的胞腔清單。
pub fn cx_cells(k : Array[Bool], n : Int32) -> Array[Array[Int32]] {
  let cells : Array[Array[Int32]] = Array::makei(n + 1, _ => [])
  for c in 0..<k.length() {
    if k[c] {
      cells[face_dim(c, n)].push(c)
    }
  }
  cells
}

///|
/// [D-Bd] ∂_d 的矩陣：列 = (d−1)-胞腔，行 = d-胞腔。
pub fn cx_boundary_matrix(
  cells : Array[Array[Int32]],
  n : Int32,
  d : Int32,
) -> Array[Array[Int64]] {
  let rows = cells[d - 1]
  let cols = cells[d]
  let index : Map[Int32, Int32] = Map([])
  for i, c in rows {
    index[c] = i
  }
  let m = Array::makei(rows.length(), _ => Array::make(cols.length(), 0L))
  for j, f in cols {
    let mut sign = 1L
    for i in 0..<n {
      if face_digit(f, i) == 2 {
        match (index.get(f - pow3(i)), index.get(f - 2 * pow3(i))) {
          (Some(hi), Some(lo)) => {
            m[hi][j] = m[hi][j] + sign
            m[lo][j] = m[lo][j] - sign
          }
          _ => ()
        }
        sign = -sign
      }
    }
  }
  m
}

///|
/// [A-Rank] 路徑一：Bareiss 無分數消去，ℚ 上的精確秩。
pub fn rank_exact(a : Array[Array[Int64]]) -> Int32 {
  let rows = a.length()
  if rows == 0 {
    return 0
  }
  let cols = a[0].length()
  let m = a.map(r => r.map(v => BigInt::from_int64(v)))
  let mut r = 0
  let mut prev = 1N
  for c in 0..<cols {
    if r == rows {
      break
    }
    let mut piv = -1
    for i in r..<rows {
      if piv < 0 && m[i][c] != 0N {
        piv = i
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = m[r]
    m[r] = m[piv]
    m[piv] = tmp
    for i in (r + 1)..<rows {
      for j in (c + 1)..<cols {
        m[i][j] = (m[i][j] * m[r][c] - m[i][c] * m[r][j]) / prev
      }
      m[i][c] = 0N
    }
    prev = m[r][c]
    r = r + 1
  }
  r
}

///|
fn pow_mod(b : Int64, e : Int64, p : Int64) -> Int64 {
  let mut result = 1L
  let mut base = b % p
  let mut k = e
  while k > 0L {
    if (k & 1L) == 1L {
      result = result * base % p
    }
    base = base * base % p
    k = k >> 1
  }
  result
}

///|
/// [A-Rank] 路徑二：𝔽_p 上的 Gauss 消去（p < 2³¹）。
pub fn rank_mod(a : Array[Array[Int64]], p : Int64) -> Int32 {
  let rows = a.length()
  if rows == 0 {
    return 0
  }
  let cols = a[0].length()
  let m = a.map(r => r.map(v => (v % p + p) % p))
  let mut r = 0
  for c in 0..<cols {
    if r == rows {
      break
    }
    let mut piv = -1
    for i in r..<rows {
      if piv < 0 && m[i][c] != 0L {
        piv = i
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = m[r]
    m[r] = m[piv]
    m[piv] = tmp
    let inv = pow_mod(m[r][c], p - 2L, p)
    for i in (r + 1)..<rows {
      if m[i][c] != 0L {
        let factor = m[i][c] * inv % p
        for j in c..<cols {
          m[i][j] = ((m[i][j] - factor * m[r][j]) % p + p) % p
        }
      }
    }
    r = r + 1
  }
  r
}

///|
fn trim(xs : Array[Int32]) -> Array[Int32] {
  let out = xs.copy()
  while out.length() > 1 && out[out.length() - 1] == 0 {
    ignore(out.pop())
  }
  out
}

///|
/// Betti 數（去尾零）；p = 0 表示 ℚ 上精確，否則在 𝔽_p 上。
pub fn cx_betti(k : Array[Bool], n : Int32, p : Int64) -> Array[Int32] {
  let cells = cx_cells(k, n)
  let ranks = Array::make(n + 2, 0)
  for d in 1..<=n {
    let m = cx_boundary_matrix(cells, n, d)
    ranks[d] = if p == 0L { rank_exact(m) } else { rank_mod(m, p) }
  }
  trim(Array::makei(n + 1, d => cells[d].length() - ranks[d] - ranks[d + 1]))
}

///|
pub fn cx_euler(k : Array[Bool], n : Int32) -> Int32 {
  let cells = cx_cells(k, n)
  let mut chi = 0
  for d in 0..<=n {
    chi = chi + (if d % 2 == 0 { 1 } else { -1 }) * cells[d].length()
  }
  chi
}

///|
/// 組合 Laplace 算子 Δ_d = ∂_{d+1}∂_{d+1}ᵀ + ∂_dᵀ∂_d。
pub fn cx_laplacian(
  cells : Array[Array[Int32]],
  n : Int32,
  d : Int32,
) -> Array[Array[BigInt]] {
  let size = cells[d].length()
  let m = Array::makei(size, _ => Array::make(size, 0L))
  if d >= 1 {
    let b = cx_boundary_matrix(cells, n, d)
    for r in 0..<b.length() {
      for i in 0..<size {
        if b[r][i] != 0L {
          for j in 0..<size {
            m[i][j] = m[i][j] + b[r][i] * b[r][j]
          }
        }
      }
    }
  }
  if d < n {
    let b = cx_boundary_matrix(cells, n, d + 1)
    for c in 0..<cells[d + 1].length() {
      for i in 0..<size {
        if b[i][c] != 0L {
          for j in 0..<size {
            m[i][j] = m[i][j] + b[i][c] * b[j][c]
          }
        }
      }
    }
  }
  m.map(r => r.map(v => BigInt::from_int64(v)))
}

///|
fn binom(n : Int32, k : Int32) -> Int32 {
  if k < 0 || k > n {
    return 0
  }
  let mut r = 1
  for i in 0..<k {
    r = r * (n - i) / (i + 1)
  }
  r
}

///|
fn sphere(d : Int32) -> Array[Int32] {
  if d == 0 {
    [2]
  } else {
    Array::makei(d + 1, i => if i == 0 || i == d { 1 } else { 0 })
  }
}

///|
/// 簡約 Betti 數（非空複形）。
fn reduced(b : Array[Int32]) -> Array[Int32] {
  let r = b.copy()
  r[0] = r[0] - 1
  r
}

///|
fn at(b : Array[Int32], i : Int32) -> Int32 {
  if i >= 0 && i < b.length() { b[i] } else { 0 }
}

///|
/// 定律：立方同調、開盒與邊界（Kan 填充的同調影子）。
pub fn law_cubical_homology_kan_boxes() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let mut dd = true
  let mut fvec = true
  let mut cube = true
  let mut bdry = true
  let mut box = true
  let mut modp = true
  let mut euler = true
  let mut boxes = 0
  let primes : Array[Int64] = [2L, 3L, 2147483647L]
  let audit = (k : Array[Bool], n : Int32, expect : Array[Int32]) => {
    let b = cx_betti(k, n, 0L)
    for p in primes {
      if cx_betti(k, n, p) != b {
        modp = false
      }
    }
    let mut alt = 0
    for d, v in b {
      alt = alt + (if d % 2 == 0 { v } else { -v })
    }
    if alt != cx_euler(k, n) || !cx_is_complex(k, n) {
      euler = false
    }
    b == expect
  }
  for n in 0..<=4 {
    let full = cx_full(n)
    let cells = cx_cells(full, n)
    for d in 0..<=n {
      if cells[d].length() != binom(n, d) * (1 << (n - d)) {
        fvec = false
      }
    }
    for d in 2..<=n {
      let a = cx_boundary_matrix(cells, n, d - 1)
      let b = cx_boundary_matrix(cells, n, d)
      for i in 0..<a.length() {
        for j in 0..<cells[d].length() {
          let mut s = 0L
          for k in 0..<b.length() {
            s = s + a[i][k] * b[k][j]
          }
          if s != 0L {
            dd = false
          }
        }
      }
    }
    if !audit(full, n, [1]) {
      cube = false
    }
    if n >= 1 {
      if !audit(cx_boundary(n), n, sphere(n - 1)) {
        bdry = false
      }
      for i in 0..<n {
        for b in 0..<2 {
          boxes = boxes + 1
          if !audit(cx_open_box(n, i, b), n, [1]) {
            box = false
          }
        }
      }
    }
  }
  chk(out, "∂∘∂ = 0（□ⁿ，n ≤ 4 的全部邊界矩陣）；f-向量 f_k = C(n,k)·2^{n−k}，總和 3ⁿ", dd && fvec)
  chk(out, "□ⁿ 可縮：Betti = (1)，n = 0..4", cube)
  chk(out, "∂□ⁿ ≃ S^{n−1}：Betti = (2)、(1,1)、(1,0,1)、(1,0,0,1)，n = 1..4", bdry)
  chk(
    out,
    "開盒無環：n = 1..4 的全部 \{boxes} 個開盒 Betti = (1)——開盒 ↪ □ⁿ 是同調等價（Kan 填充的必要條件）",
    box && boxes == 20,
  )
  chk(
    out,
    "反例對照：∂□ⁿ 有 β_{n−1} = 1，邊界 ↪ □ⁿ 不是同調等價——能填的是開盒，不是邊界",
    cx_betti(cx_boundary(3), 3, 0L) != cx_betti(cx_full(3), 3, 0L),
  )
  chk(
    out,
    "秩的兩條路徑：Bareiss（ℚ 上精確）= 𝔽₂ = 𝔽₃ = 𝔽_{2³¹−1} 上的 Gauss 消去（以上複形皆無撓）",
    modp,
  )
  chk(out, "Euler–Poincaré：Σ(−1)^k f_k = Σ(−1)^k β_k，且每個都是對取面封閉的複形", euler)
  out
}

///|
/// 定律：懸掛、推出、Künneth（圓、球面、環面）。
pub fn law_suspension_pushout_kunneth() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let big = 2147483647L
  let s0 = cx_boundary(1)
  let s1 = cx_boundary(2)
  let s2 = cx_boundary(3)
  // Σᵏ S⁰ = Sᵏ
  let mut spheres = true
  let mut k = s0
  for d in 1..<=3 {
    k = cx_suspension(k)
    if !cx_is_complex(k, d + 1) ||
      cx_betti(k, d + 1, 0L) != sphere(d) ||
      cx_betti(k, d + 1, 0L) != cx_betti(cx_boundary(d + 1), d + 1, 0L) {
      spheres = false
    }
  }
  chk(
    out,
    "Σᵏ S⁰ ≃ Sᵏ：懸掛 k 次的 Betti = ∂□^{k+1} 的 Betti（k = 1, 2, 3）——圓 S¹ = ΣS⁰",
    spheres,
  )
  let torus = cx_product(s1, s1)
  let four = cx_product(s0, s0)
  let list = [(s0, 1), (s1, 2), (s2, 3), (four, 2), (torus, 4), (cx_open_box(3, 0, 1), 3)]
  let mut shift = true
  for kn in list {
    let (c, n) = kn
    let b = reduced(cx_betti(c, n, big))
    let sb = reduced(cx_betti(cx_suspension(c), n + 1, big))
    if at(sb, 0) != 0 {
      shift = false
    }
    for d in 0..<=n {
      if at(sb, d + 1) != at(b, d) {
        shift = false
      }
    }
  }
  chk(
    out,
    "懸掛同構 β̃_{k+1}(ΣK) = β̃_k(K)：K = S⁰、S¹、S²、四點、T²、開盒（6 個）",
    shift,
  )
  let t2 = cx_betti(torus, 4, 0L)
  let t3 = cx_betti(cx_product(torus, s1), 6, big)
  chk(
    out,
    "環面 T² = S¹×S¹ ⊂ □⁴：Betti = \{@core.show_ints(t2)}，χ = \{cx_euler(torus, 4)}；T³ ⊂ □⁶：Betti = \{@core.show_ints(t3)}",
    t2 == [1, 2, 1] && cx_euler(torus, 4) == 0 && t3 == [1, 3, 3, 1],
  )
  let mut kunneth = true
  let mut pairs = 0
  for a in 0..<4 {
    for b in 0..<4 {
      let (ka, na) = list[a]
      let (kb, nb) = list[b]
      if na + nb > 5 {
        continue
      }
      pairs = pairs + 1
      let pa = cx_betti(ka, na, big)
      let pb = cx_betti(kb, nb, big)
      let conv = Array::make(pa.length() + pb.length() - 1, 0)
      for i, u in pa {
        for j, v in pb {
          conv[i + j] = conv[i + j] + u * v
        }
      }
      if cx_betti(cx_product(ka, kb), na + nb, big) != trim(conv) {
        kunneth = false
      }
    }
  }
  chk(
    out,
    "Künneth：P(K×L) = P(K)·P(L)，K、L 取自 S⁰、S¹、S²、四點（\{pairs} 對，至 □⁵）",
    kunneth,
  )
  let mut push = true
  for n in 2..<=4 {
    let kk = cx_open_box(n, 0, 1)
    let ll = cx_facet(n, 0, 1)
    let a = cx_inter(kk, ll)
    let u = cx_union(kk, ll)
    if u != cx_boundary(n) ||
      cx_betti(kk, n, 0L) != [1] ||
      cx_betti(ll, n, 0L) != [1] ||
      cx_betti(a, n, 0L) != sphere(n - 2) ||
      cx_betti(u, n, 0L) != sphere(n - 1) ||
      cx_euler(u, n) != cx_euler(kk, n) + cx_euler(ll, n) - cx_euler(a, n) {
      push = false
    }
  }
  chk(
    out,
    "推出：開盒 ∪_{S^{n−2}} 面 = ∂□ⁿ ≃ S^{n−1}（n = 2, 3, 4）——兩個可縮件沿赤道黏合 = 赤道的懸掛；χ 滿足容斥",
    push,
  )
  out
}

///|
/// 定律：Hodge 定理與立方體的 Laplace 譜（全域公理 σ(T) 的實例）。
pub fn law_hodge_laplacian_spectrum() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let list = [
    (cx_boundary(2), 2),
    (cx_boundary(3), 3),
    (cx_open_box(3, 0, 1), 3),
    (cx_full(2), 2),
    (cx_full(3), 3),
    (cx_product(cx_boundary(1), cx_boundary(2)), 3),
  ]
  let mut hodge = true
  let mut psd = true
  let mut count = 0
  for kn in list {
    let (c, n) = kn
    let cells = cx_cells(c, n)
    let betti = cx_betti(c, n, 0L)
    for d in 0..<=n {
      let size = cells[d].length()
      if size == 0 {
        continue
      }
      count = count + 1
      let lap = cx_laplacian(cells, n, d)
      let chi = @core.mat_charpoly(lap)
      let nullity = size -
        rank_exact(
          Array::makei(size, i => Array::makei(size, j => lap[i][j].to_int64())),
        )
      if nullity != at(betti, d) || @core.root_multiplicity(chi, 0) != at(betti, d) {
        hodge = false
      }
      // 實非負根 ⇒ 係數正負相間
      for i, coef in chi {
        if (size - i) % 2 == 0 && coef < 0N {
          psd = false
        }
        if (size - i) % 2 == 1 && coef > 0N {
          psd = false
        }
      }
    }
  }
  chk(
    out,
    "離散 Hodge：dim ker Δ_k = β_k，兩條路徑（Bareiss 零度；χ_Δ 在 0 的重數）——\{count} 個 (複形, k)",
    hodge,
  )
  chk(out, "Δ_k 半正定的必要條件：特徵多項式係數正負相間", psd)
  let mut graph = true
  let mut kun = true
  let mut cases = 0
  for n in 1..<=4 {
    let cells = cx_cells(cx_full(n), n)
    for k in 0..<=n {
      if cells[k].length() > 24 {
        continue
      }
      cases = cases + 1
      let mut expect : Array[BigInt] = [1N]
      for j in 0..<=(n - k) {
        for _ in 0..<(binom(n, k) * binom(n - k, j)) {
          expect = @core.poly_mul(expect, [BigInt::from_int(-2 * (k + j)), 1N])
        }
      }
      if @core.mat_charpoly(cx_laplacian(cells, n, k)) != expect {
        kun = false
        if k == 0 {
          graph = false
        }
      }
    }
  }
  chk(
    out,
    "超立方體圖 Q_n（n ≤ 4）：χ(Δ_0) = ∏_j (x − 2j)^{C(n,j)}——譜 {0, 2, …, 2n}",
    graph,
  )
  chk(
    out,
    "譜的 Künneth：χ(Δ_k(□ⁿ)) = ∏_j (x − 2(k+j))^{C(n,k)·C(n−k,j)}，\{cases} 個 (n,k)（矩陣階 ≤ 24）",
    kun,
  )
  out
}
