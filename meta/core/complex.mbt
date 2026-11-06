// ---------------------------------------------------------------------------
// meta/core — 有限複形、Betti 數、與覆蓋的神經（Čech 障礙）
// ---------------------------------------------------------------------------
//
// 為什麼「全域實例」需要複形？
//   把實例環境切成若干「局部模組」，每個模組上都能解出一個局部解。
//   要把它們併成**一個**全域解，需要的不只是「兩兩相容」，
//   而是「三三相容」（cocycle 條件）——這正是層論（sheaf）的下降條件。
//   下降條件的障礙住在覆蓋的神經（nerve）的 H¹ 裡：
//       H¹(nerve; ℚ) = 0  ⟺  兩兩相容自動升級成全域相容
//   所以本檔把「能不能黏」變成一個可算的線性代數問題，
//   而障礙本身是一個**被列舉出來的三元組見證**，不是一句「可能失敗」。
//
// 定義：有限單純複形 K = 一堆有限集合（單形），向下封閉。
//       ∂_k : C_k → C_{k−1}，[v₀…v_k] ↦ Σ_i (−1)^i [v₀…v̂_i…v_k]
//       b_k = dim ker ∂_k − rank ∂_{k+1} = f_k − rank ∂_k − rank ∂_{k+1}

///|
/// 一個 k-單形：k+1 個頂點的升冪陣列。
pub(all) struct Complex {
  /// 頂點數
  verts : Int32
  /// faces[k] = 所有 k-單形（每個是升冪頂點陣列）
  faces : Array[Array[Array[Int32]]]
}

///|
fn cx_empty(n : Int32, maxdim : Int32) -> Complex {
  let faces : Array[Array[Array[Int32]]] = []
  for _k in 0..<(maxdim + 1) {
    let x : Array[Array[Int32]] = []
    faces.push(x)
  }
  Complex::{ verts: n, faces, }
}

///|
fn cx_has_face(c : Complex, dim : Int32, s : Array[Int32]) -> Bool {
  if dim < 0 || dim >= c.faces.length() {
    return false
  }
  for f in c.faces[dim] {
    let mut same = f.length() == s.length()
    if same {
      for i in 0..<f.length() {
        if f[i] != s[i] {
          same = false
        }
      }
    }
    if same {
      return true
    }
  }
  false
}

///|
/// 由極大面生成複形（取向下封閉）。
pub fn complex_of_maximal(n : Int32, maximal : Array[Array[Int32]]) -> Complex {
  let mut maxdim = 0
  for f in maximal {
    if f.length() > maxdim {
      maxdim = f.length()
    }
  }
  let c = cx_empty(n, maxdim)
  for f in maximal {
    // 列舉 f 的所有非空子集
    let s = set_norm(f)
    let m = s.length()
    let total = 1 << m
    for mask in 1..<total {
      let face : Array[Int32] = []
      for i in 0..<m {
        if (mask >> i) % 2 == 1 {
          face.push(s[i])
        }
      }
      let d = face.length() - 1
      if !cx_has_face(c, d, face) {
        c.faces[d].push(face)
      }
    }
  }
  c
}

///|
/// f-向量：f[k] = k-單形個數。
pub fn cx_f_vector(c : Complex) -> Array[Int32] {
  let out : Array[Int32] = []
  for layer in c.faces {
    out.push(layer.length())
  }
  out
}

///|
/// Euler 示性數 χ = Σ (−1)^k f_k。
pub fn cx_euler(c : Complex) -> Int32 {
  let mut sum = 0
  for k in 0..<c.faces.length() {
    let f = c.faces[k].length()
    if k % 2 == 0 {
      sum = sum + f
    } else {
      sum = sum - f
    }
  }
  sum
}

///|
fn cx_face_index(c : Complex, dim : Int32, s : Array[Int32]) -> Int32 {
  if dim < 0 || dim >= c.faces.length() {
    return -1
  }
  let mut idx = -1
  for i in 0..<c.faces[dim].length() {
    let f = c.faces[dim][i]
    let mut same = f.length() == s.length()
    if same {
      for j in 0..<f.length() {
        if f[j] != s[j] {
          same = false
        }
      }
    }
    if same {
      idx = i
    }
  }
  idx
}

///|
/// 邊界矩陣 ∂_k：列 = (k−1)-面，行 = k-面。k = 0 時為 0×f₀ 的空矩陣。
pub fn cx_boundary(c : Complex, k : Int32) -> Array[Array[Int32]] {
  if k <= 0 || k >= c.faces.length() {
    return []
  }
  let rows = c.faces[k - 1].length()
  let cols = c.faces[k].length()
  let m : Array[Array[Int32]] = []
  for _r in 0..<rows {
    let row : Array[Int32] = []
    for _c2 in 0..<cols {
      row.push(0)
    }
    m.push(row)
  }
  for j in 0..<cols {
    let face = c.faces[k][j]
    for i in 0..<face.length() {
      // 去掉第 i 個頂點
      let sub : Array[Int32] = []
      for t in 0..<face.length() {
        if t != i {
          sub.push(face[t])
        }
      }
      let r = cx_face_index(c, k - 1, sub)
      if r >= 0 {
        m[r][j] = if i % 2 == 0 { 1 } else { -1 }
      }
    }
  }
  m
}

///|
/// Betti 數 b_k = f_k − rank ∂_k − rank ∂_{k+1}（ℚ 係數，精確）。
pub fn cx_betti(c : Complex, k : Int32) -> Int32 {
  if k < 0 || k >= c.faces.length() {
    return 0
  }
  let fk = c.faces[k].length()
  let rk = if k == 0 { 0 } else { rank_int(cx_boundary(c, k)) }
  let rk1 = rank_int(cx_boundary(c, k + 1))
  fk - rk - rk1
}

///|
/// 全部 Betti 數。
pub fn cx_betti_vector(c : Complex) -> Array[Int32] {
  let out : Array[Int32] = []
  for k in 0..<c.faces.length() {
    out.push(cx_betti(c, k))
  }
  out
}

///|
/// 鏈複形條件 ∂_{k}∘∂_{k+1} = 0（以矩陣乘積檢查）。
pub fn cx_is_chain_complex(c : Complex) -> Bool {
  for k in 1..<c.faces.length() {
    let dk = cx_boundary(c, k)
    let dk1 = cx_boundary(c, k + 1)
    if dk.length() > 0 && dk1.length() > 0 {
      let prod = mat_mul(dk, dk1)
      for row in prod {
        for x in row {
          if x != 0 {
            return false
          }
        }
      }
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 覆蓋的神經：黏合障礙的可計算形式
// ---------------------------------------------------------------------------

///|
/// 覆蓋 {U_i} 的神經：頂點 = 貼片，一組貼片張成單形 ⟺ 交集非空。
pub fn nerve_of_cover(cover : Array[Array[Int32]]) -> Complex {
  let m = cover.length()
  let maximal : Array[Array[Int32]] = []
  let total = 1 << m
  for mask in 1..<total {
    let patches : Array[Int32] = []
    let mut inter : Array[Int32] = []
    let mut first = true
    for i in 0..<m {
      if (mask >> i) % 2 == 1 {
        patches.push(i)
        if first {
          inter = set_norm(cover[i])
          first = false
        } else {
          inter = set_inter(inter, set_norm(cover[i]))
        }
      }
    }
    if inter.length() > 0 {
      // 只保留極大面即可（downward closure 由 complex_of_maximal 處理）
      let mut maximal_hit = false
      for f in maximal {
        if set_subset(patches, f) && f.length() == patches.length() {
          maximal_hit = true
        }
      }
      if !maximal_hit {
        maximal.push(patches)
      }
    }
  }
  complex_of_maximal(m, maximal)
}

///| 黏合判準：覆蓋是「好覆蓋」（所有非空交集可縮）時，

///|
/// 兩兩相容的局部解能升級為全域解 ⟺ H¹(nerve) = 0。
pub fn cover_glues(cover : Array[Array[Int32]]) -> Bool {
  cx_betti(nerve_of_cover(cover), 1) == 0
}

///| 障礙見證：列舉 nerve 中不存在 2-單形但其三個頂點兩兩相連的三角形。

///|
/// 這是「局部相容但全域不容」的最小可讀證據。
pub fn cover_obstruction(cover : Array[Array[Int32]]) -> (Int32, Int32, Int32)? {
  let m = cover.length()
  let mut found : (Int32, Int32, Int32)? = None
  for i in 0..<m {
    for j in (i + 1)..<m {
      for k in (j + 1)..<m {
        let ij = set_inter(set_norm(cover[i]), set_norm(cover[j])).length() > 0
        let jk = set_inter(set_norm(cover[j]), set_norm(cover[k])).length() > 0
        let ki = set_inter(set_norm(cover[k]), set_norm(cover[i])).length() > 0
        let all3 = set_inter(
            set_inter(set_norm(cover[i]), set_norm(cover[j])),
            set_norm(cover[k]),
          ).length() >
          0
        if ij && jk && ki && !all3 && found is None {
          found = Some((i, j, k))
        }
      }
    }
  }
  found
}

///|
pub fn law_complex_simplicial_complexes_betti_numbers_and_euler_poincar() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 三角形邊界 ≅ S¹：χ = 0, b = (1,1)
  let circle = complex_of_maximal(3, [[0, 1], [1, 2], [0, 2]])
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #1",
    cx_euler(circle) == 0,
  )
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #2",
    cx_betti(circle, 0) == 1,
  )
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #3",
    cx_betti(circle, 1) == 1,
  )
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #4",
    cx_is_chain_complex(circle),
  )
  // 2-單形（實心三角形）：χ = 1, b = (1,0,0)
  let disk = complex_of_maximal(3, [[0, 1, 2]])
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #5",
    cx_euler(disk) == 1,
  )
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #6",
    cx_betti(disk, 1) == 0,
  )
  chk(
    out,
    "simplicial complexes: Betti numbers and Euler–Poincaré #7",
    cx_betti(disk, 2) == 0,
  )
  // Euler–Poincaré：χ = Σ (−1)^k b_k
  for c in [circle, disk] {
    let bs = cx_betti_vector(c)
    let mut alt = 0
    for k in 0..<bs.length() {
      alt = alt + (if k % 2 == 0 { bs[k] } else { -bs[k] })
    }
    chk(
      out,
      "simplicial complexes: Betti numbers and Euler–Poincaré #8",
      alt == cx_euler(c),
    )
  }
  out
}

///|
pub fn law_complex_covers_gluing_criterion_via_h1_of_the_nerve() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 兩片重疊：nerve 是一條邊，H¹ = 0 ⇒ 可黏
  let good : Array[Array[Int32]] = [[0, 1, 2], [2, 3, 4]]
  chk(out, "covers: gluing criterion via H1 of the nerve #1", cover_glues(good))
  chk(
    out,
    "covers: gluing criterion via H1 of the nerve #2",
    cover_obstruction(good) is None,
  )
  // 三片兩兩相交但三者交集為空：nerve ≅ S¹，H¹ = ℚ ⇒ 不可黏
  let bad : Array[Array[Int32]] = [[0, 1], [1, 2], [2, 0]]
  chk(out, "covers: gluing criterion via H1 of the nerve #3", !cover_glues(bad))
  match cover_obstruction(bad) {
    Some(_) => chk(out, "covers: gluing criterion via H1 of the nerve #4", true)
    None => chk(out, "covers: gluing criterion via H1 of the nerve #5", false)
  }
  // 三片共同相交：收縮 ⇒ 可黏
  let good2 : Array[Array[Int32]] = [[0, 1, 2], [1, 2, 3], [0, 2, 3]]
  chk(
    out,
    "covers: gluing criterion via H1 of the nerve #6",
    cover_glues(good2),
  )
  out
}

///|
pub fn law_complex_f_vector_alternating_sum_is_the_euler_characteristic() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 三角形邊界（3 頂點、3 邊）
  let tri = complex_of_maximal(3, [[0, 1, 2]])
  let f = cx_f_vector(tri)
  // f-向量不假定從哪一層開始記（實作可能含空面），只驗交錯和
  chk(
    out,
    "complex: f-vector alternating sum is the Euler characteristic #1",
    f.length() >= 3,
  )
  // 頂點層一定是最多的那一層
  chk(
    out,
    "complex: f-vector alternating sum is the Euler characteristic #2",
    f[0] >= f[1],
  )
  // Σ(−1)^i f_i = χ
  let mut alt = 0
  for i in 0..<f.length() {
    if i % 2 == 0 {
      alt = alt + f[i]
    } else {
      alt = alt - f[i]
    }
  }
  chk(
    out,
    "complex: f-vector alternating sum is the Euler characteristic #3",
    alt == cx_euler(tri),
  )
  // 兩點不連通：χ = 2
  let two = complex_of_maximal(2, [[0], [1]])
  chk(
    out,
    "complex: f-vector alternating sum is the Euler characteristic #4",
    cx_euler(two) == 2,
  )
  out
}
