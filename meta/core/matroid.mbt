// ---------------------------------------------------------------------------
// meta/core — 擬陣（matroid）：實例集合的「獨立性」幾何
// ---------------------------------------------------------------------------
//
// 為什麼是擬陣？
//   全域實例解析的關鍵量不是「能推出什麼」，而是「哪一組實例是不可省的」。
//   若可導性閉包滿足交換公理，這一組就有擬陣結構：
//     基（basis）= 極小生成集、秩（rank）= 最少需要的實例數、
//     對偶（dual）= 把目標與規則反轉後的同一個問題。
//   **交換公理不是理所當然的**，所以本檔提供 `mat_exchange_ok` 去「檢查」它，
//   而不是假設它。這是本專案的方法論：能證的就證，不能證的就量。
//
// 擬陣的等價刻畫用秩函數：
//   (R1) 0 ≤ r(S) ≤ |S|
//   (R2) S ⊆ T ⇒ r(S) ≤ r(T)                      （單調）
//   (R3) r(S∪T) + r(S∩T) ≤ r(S) + r(T)            （次模）
//   (R4) 交換：|A| < |B| ⇒ ∃e∈B\A. r(A∪{e}) > r(A)
// 三個具體模型：圖擬陣、線性擬陣、以及「由秩函數直接給定的」抽象擬陣。

///|
/// 集合（升冪整數陣列）工具 -------------------------------------------------
pub fn set_norm(s : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in s {
    let mut dup = false
    for y in out {
      if x == y {
        dup = true
      }
    }
    if !dup {
      out.push(x)
    }
  }
  // 插入排序
  let r : Array[Int32] = []
  for x in out {
    let tmp : Array[Int32] = []
    let mut placed = false
    for y in r {
      if !placed && x < y {
        tmp.push(x)
        placed = true
      }
      tmp.push(y)
    }
    if !placed {
      tmp.push(x)
    }
    r.clear()
    for y in tmp {
      r.push(y)
    }
  }
  r
}

///|
/// a ⊆ b。
pub fn set_subset(a : Array[Int32], b : Array[Int32]) -> Bool {
  for x in a {
    let mut hit = false
    for y in b {
      if x == y {
        hit = true
      }
    }
    if !hit {
      return false
    }
  }
  true
}

///|
/// 併集。
pub fn set_union(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in a {
    out.push(x)
  }
  for x in b {
    out.push(x)
  }
  set_norm(out)
}

///|
/// 交集。
pub fn set_inter(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in a {
    if set_subset([x], b) {
      out.push(x)
    }
  }
  set_norm(out)
}

///|
/// 差集 a \ b。
pub fn set_diff(a : Array[Int32], b : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in a {
    if !set_subset([x], b) {
      out.push(x)
    }
  }
  set_norm(out)
}

///|
/// 0..<n 的全集。
pub fn set_full(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<n {
    out.push(i)
  }
  out
}

// ---------------------------------------------------------------------------
// 秩函數表示的擬陣
// ---------------------------------------------------------------------------

///|
/// 秩函數就是擬陣：所有結構（基、閉包、對偶）都可以從它算回來。
pub(all) struct Matroid {
  ground : Int32
  rankf : (Array[Int32]) -> Int32
}

///|
/// 由秩函數建擬陣。
pub fn mat_from_rank(n : Int32, rankf : (Array[Int32]) -> Int32) -> Matroid {
  Matroid::{ ground: n, rankf, }
}

///|
/// 秩。
pub fn mat_rank(m : Matroid, s : Array[Int32]) -> Int32 {
  (m.rankf)(set_norm(s))
}

///|
/// 獨立：秩等於元素個數。
pub fn mat_indep(m : Matroid, s : Array[Int32]) -> Bool {
  mat_rank(m, s) == set_norm(s).length()
}

///|
/// 基：極大獨立集（這裡檢查「獨立且秩等於全域秩」）。
pub fn mat_is_basis(m : Matroid, s : Array[Int32]) -> Bool {
  mat_indep(m, s) && mat_rank(m, s) == mat_rank(m, set_full(m.ground))
}

///|
/// 閉包 cl(S) = { e | r(S∪{e}) = r(S) }。
pub fn mat_closure(m : Matroid, s : Array[Int32]) -> Array[Int32] {
  let r = mat_rank(m, s)
  let out : Array[Int32] = []
  for e in 0..<m.ground {
    if mat_rank(m, set_union(s, [e])) == r {
      out.push(e)
    }
  }
  out
}

///| 貪心：權重由大到小，秩會增加才收。

///| 這是擬陣的定義性定理（Rado–Edmonds）：貪心對**所有**權重都給出最大權基，

///|
/// 若且唯若獨立系統是擬陣。測試裡用暴力法對拍。
pub fn mat_greedy(m : Matroid, weights : Array[Int32]) -> Array[Int32] {
  let order = set_full(m.ground)
  // 依權重降序插入排序
  let sorted : Array[Int32] = []
  for e in order {
    let tmp : Array[Int32] = []
    let mut placed = false
    for y in sorted {
      if !placed && weights[e] > weights[y] {
        tmp.push(e)
        placed = true
      }
      tmp.push(y)
    }
    if !placed {
      tmp.push(e)
    }
    sorted.clear()
    for y in tmp {
      sorted.push(y)
    }
  }
  let chosen : Array[Int32] = []
  let mut r = 0
  for e in sorted {
    let r2 = mat_rank(m, set_union(chosen, [e]))
    if r2 > r {
      chosen.push(e)
      r = r2
    }
  }
  set_norm(chosen)
}

///| 對偶擬陣：r*(S) = |S| − r(E) + r(E \ S)。

///|
/// 這是「鏡像對稱」在結構層的第一次出現：對偶是對合（r** = r）。
pub fn mat_dual(m : Matroid) -> Matroid {
  let n = m.ground
  let rE = mat_rank(m, set_full(n))
  let f = fn(s : Array[Int32]) -> Int32 {
    let ss = set_norm(s)
    ss.length() - rE + mat_rank(m, set_diff(set_full(n), ss))
  }
  Matroid::{ ground: n, rankf: f, }
}

///|
/// 秩公理 (R1)(R2)(R3) 的暴力檢查，回傳第一個反例（None = 全過）。
pub fn mat_rank_axioms_ok(m : Matroid) -> String? {
  let n = m.ground
  let all = 1 << n
  let mut bad : String? = None
  for mask in 0..<all {
    let s = mat_mask_to_set(mask)
    let r = mat_rank(m, s)
    if r < 0 || r > s.length() {
      bad = Some("R1 at \{s.length()} elems")
    }
    for mask2 in 0..<all {
      let t = mat_mask_to_set(mask2)
      if set_subset(s, t) && mat_rank(m, t) < r {
        bad = Some("R2 (monotone) violated")
      }
      let lhs = mat_rank(m, set_union(s, t)) + mat_rank(m, set_inter(s, t))
      let rhs = r + mat_rank(m, t)
      if lhs > rhs {
        bad = Some("R3 (submodular) violated")
      }
    }
  }
  bad
}

///| 交換公理 (R4)：|A| < |B| 且都獨立 ⇒ ∃e∈B\A. A∪{e} 仍獨立。

///|
/// 這是「擬陣」與「單純獨立系統」的分界線，測得出來就不必假設。
pub fn mat_exchange_ok(m : Matroid) -> Bool {
  let n = m.ground
  let all = 1 << n
  for m1 in 0..<all {
    let a = mat_mask_to_set(m1)
    if mat_indep(m, a) {
      for m2 in 0..<all {
        let b = mat_mask_to_set(m2)
        if mat_indep(m, b) && a.length() < b.length() {
          let mut ok = false
          for e in set_diff(b, a) {
            if mat_indep(m, set_union(a, [e])) {
              ok = true
            }
          }
          if !ok {
            return false
          }
        }
      }
    }
  }
  true
}

///|
fn mat_mask_to_set(mask : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut i = 0
  let mut x = mask
  while x > 0 {
    if x % 2 == 1 {
      out.push(i)
    }
    x = x / 2
    i = i + 1
  }
  out
}

// ---------------------------------------------------------------------------
// 具體模型一：圖擬陣（rank = 生成森林的邊數）
// ---------------------------------------------------------------------------

///|
/// 圖擬陣：ground = 邊，r(S) = |V| − S 所生成子圖的連通分量數。
pub fn mat_graphic(nv : Int32, edges : Array[(Int32, Int32)]) -> Matroid {
  let ne = edges.length()
  let f = fn(s : Array[Int32]) -> Int32 {
    let parent : Array[Int32] = []
    for i in 0..<nv {
      parent.push(i)
    }
    let find = fn(x : Int32) -> Int32 {
      let mut y = x
      while parent[y] != y {
        y = parent[y]
      }
      y
    }
    let mut used = 0
    for e in set_norm(s) {
      if e < ne {
        let (u, v) = edges[e]
        let ru = find(u)
        let rv = find(v)
        if ru != rv {
          parent[ru] = rv
          used = used + 1
        }
      }
    }
    used
  }
  Matroid::{ ground: ne, rankf: f, }
}

// ---------------------------------------------------------------------------
// 具體模型二：線性擬陣（rank = 選中行向量的秩）
// ---------------------------------------------------------------------------

///|
/// 線性擬陣：矩陣的每一**行**是一個元素。
pub fn mat_linear(rows : Array[Array[Int32]], ncols : Int32) -> Matroid {
  let f = fn(s : Array[Int32]) -> Int32 {
    let sel = set_norm(s)
    if sel.length() == 0 {
      return 0
    }
    let sub : Array[Array[Int32]] = []
    for r in rows {
      let row : Array[Int32] = []
      for c in sel {
        if c < ncols && c < r.length() {
          row.push(r[c])
        } else {
          row.push(0)
        }
      }
      sub.push(row)
    }
    rank_int(sub)
  }
  Matroid::{ ground: ncols, rankf: f, }
}

// ---------------------------------------------------------------------------
// 白箱檢查
// ---------------------------------------------------------------------------

///|
fn mat_brute_max_weight(m : Matroid, weights : Array[Int32]) -> Int32 {
  let n = m.ground
  let all = 1 << n
  let mut best = 0
  for mask in 0..<all {
    let s = mat_mask_to_set(mask)
    if mat_indep(m, s) {
      let mut w = 0
      for e in s {
        w = w + weights[e]
      }
      if w > best {
        best = w
      }
    }
  }
  best
}

///|
fn mat_weight(s : Array[Int32], weights : Array[Int32]) -> Int32 {
  let mut w = 0
  for e in s {
    w = w + weights[e]
  }
  w
}

///|
pub fn law_matroid_matroid_greedy_is_optimal_on_a_graphic_matroid() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 三角形 + 一條尾巴：4 頂點 4 邊
  let edges : Array[(Int32, Int32)] = [(0, 1), (1, 2), (0, 2), (2, 3)]
  let m = mat_graphic(4, edges)
  chk(
    out,
    "matroid: greedy is optimal on a graphic matroid #1",
    mat_rank(m, set_full(4)) == 3,
  ) // 生成樹 3 條邊
  chk(
    out,
    "matroid: greedy is optimal on a graphic matroid #2",
    mat_rank_axioms_ok(m) is None,
  )
  chk(
    out,
    "matroid: greedy is optimal on a graphic matroid #3",
    mat_exchange_ok(m),
  )
  // 對拍：所有 2^4 種權重
  let mut all_ok = true
  for w0 in 0..<4 {
    for w1 in 0..<4 {
      for w2 in 0..<4 {
        for w3 in 0..<4 {
          let w = [w0, w1, w2, w3]
          let g = mat_greedy(m, w)
          if mat_weight(g, w) != mat_brute_max_weight(m, w) {
            all_ok = false
          }
          if !mat_is_basis(m, set_union(g, [])) {
            // 貪心必須產出基（或許不是極大，但秩必須滿）
            if mat_rank(m, g) != 3 {
              all_ok = false
            }
          }
        }
      }
    }
  }
  chk(out, "matroid: greedy is optimal on a graphic matroid #4", all_ok)
  out
}

///|
pub fn law_matroid_matroid_duality_is_an_involution() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let edges : Array[(Int32, Int32)] = [(0, 1), (1, 2), (2, 3), (3, 0), (0, 2)]
  let m = mat_graphic(4, edges)
  let d = mat_dual(m)
  let dd = mat_dual(d)
  // r** = r
  let mut ok = true
  for mask in 0..<(1 << 5) {
    let s = mat_mask_to_set(mask)
    if mat_rank(dd, s) != mat_rank(m, s) {
      ok = false
    }
  }
  chk(out, "matroid: duality is an involution #1", ok)
  // 對偶公理也成立 ⇒ 對偶擬陣仍是擬陣
  chk(out, "matroid: duality is an involution #2", mat_exchange_ok(d))
  chk(
    out,
    "matroid: duality is an involution #3",
    mat_rank_axioms_ok(d) is None,
  )
  // 秩補公式：r*(E) = |E| − r(E)
  chk(
    out,
    "matroid: duality is an involution #4",
    mat_rank(d, set_full(5)) == 5 - mat_rank(m, set_full(5)),
  )
  out
}

///|
pub fn law_matroid_matroid_linear_matroid_over_q() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // 行向量 (1,0), (0,1), (1,1)：第三行落在前兩行的張成裡
  let m = mat_linear([[1, 0, 1], [0, 1, 1]], 3)
  chk(out, "matroid: linear matroid over Q #1", mat_rank(m, set_full(3)) == 2)
  chk(out, "matroid: linear matroid over Q #2", mat_indep(m, [0, 1]))
  chk(out, "matroid: linear matroid over Q #3", !mat_indep(m, [0, 1, 2]))
  chk(
    out,
    "matroid: linear matroid over Q #4",
    mat_closure(m, [0, 1]) == [0, 1, 2],
  )
  chk(out, "matroid: linear matroid over Q #5", mat_exchange_ok(m))
  out
}
