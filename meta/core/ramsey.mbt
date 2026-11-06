// ---------------------------------------------------------------------------
// meta/core — Ramsey 理論：搜尋深度的組合上限
// ---------------------------------------------------------------------------
//
// 這裡的用途不是「知道 R(3,4)=9」這種冷知識，而是：
//   **實例解析樹的任何一條足夠長的路徑，必然出現重複的「局部型別簽名」。**
// 把簽名想成 K_n 邊的兩種顏色（「已解／未解」、「消耗深度／不消耗」），
// Ramsey 定理就給出「任憑怎麼著色都會冒出單色子圖」的門檻 n。
// 於是「路徑長度 ≥ R(k,k)」⇒「必有一條同色的 k-子結構」⇒ 可以安全剪枝／判環。
// 這是一個**只依賴深度的有限界**，不需要事先知道搜尋空間有多大。
//
// 本檔提供（窮舉路線；更大的值與更緊的上界在 ramsey_ex.mbt）：
//   ramsey(k,l)             : 逐頂點擴張 + 對稱剪枝的真搜尋（不是查表），只對極小值可行
//   erdos_szekeres(k,l)     : C(k+l−2, k−1) 上限（可證，能算到很大）
//   ramsey_find_witness     : 明確建構一個 K_n 的 (k,l)-free 著色（見證）
//   ramsey_check_coloring   : 獨立複驗一個見證（不信任搜尋器）
//   ramsey_window(d)        : 實例搜尋的深度窗口 = R(d+1,d+1) 的**可證上界**

///|
/// 二項式係數（小 n 精確）。
pub fn binom(n : Int32, k : Int32) -> Int32 {
  if k < 0 || k > n {
    return 0
  }
  let mut r = 1
  let mut i = 0
  while i < k {
    r = r * (n - i)
    i = i + 1
    r = r / i
  }
  r
}

///|
/// Erdős–Szekeres：R(k,l) ≤ C(k+l−2, k−1)。
pub fn erdos_szekeres(k : Int32, l : Int32) -> Int32 {
  binom(k + l - 2, k - 1)
}

// --- 內部：K_n 上 (k,l)-free 著色的存在性搜尋 --------------------------------
//
// 逐頂點擴張：新頂點 v 的紅色鄰居集合 R ⊆ {0..v-1}，其餘為藍色。
// 新產生的單色團必定包含 v，所以只需檢查
//   (a) R 內沒有紅色 (k−1)-團；
//   (b) B = 補集內沒有藍色 (l−1)-團。
// 這兩個檢查是**充分必要**的，因此搜尋是完備的（不會漏解）。

///|
priv struct RamseyState {
  n : Int32
  red : Array[Array[Bool]]
  k : Int32
  l : Int32
}

///|
fn rstate_new(n : Int32, k : Int32, l : Int32) -> RamseyState {
  let red : Array[Array[Bool]] = []
  for _i in 0..<n {
    let row : Array[Bool] = []
    for _j in 0..<n {
      row.push(false)
    }
    red.push(row)
  }
  RamseyState::{ n, red, k, l, }
}

///|
/// 在給定頂點集合中，是否存在大小 ≥ size 的紅色團。
fn has_red_clique(
  st : RamseyState,
  subset : Array[Int32],
  size : Int32,
) -> Bool {
  if size <= 1 {
    return subset.length() > 0
  }
  if subset.length() < size {
    return false
  }
  // 以第一個元素為錨，遞迴找
  let first = subset[0]
  let rest : Array[Int32] = []
  for i in 1..<subset.length() {
    rest.push(subset[i])
  }
  // 不用 first 的情形
  if has_red_clique(st, rest, size) {
    return true
  }
  // 用 first 的情形：鄰居 ∩ rest
  let nb : Array[Int32] = []
  for v in rest {
    if st.red[first][v] {
      nb.push(v)
    }
  }
  has_red_clique(st, nb, size - 1)
}

///|
/// 藍色團：紅色的補。
fn has_blue_clique(
  st : RamseyState,
  subset : Array[Int32],
  size : Int32,
) -> Bool {
  if size <= 1 {
    return subset.length() > 0
  }
  if subset.length() < size {
    return false
  }
  let first = subset[0]
  let rest : Array[Int32] = []
  for i in 1..<subset.length() {
    rest.push(subset[i])
  }
  if has_blue_clique(st, rest, size) {
    return true
  }
  let nb : Array[Int32] = []
  for v in rest {
    if !st.red[first][v] {
      nb.push(v)
    }
  }
  has_blue_clique(st, nb, size - 1)
}

///|
fn ramsey_assign(st : RamseyState, v : Int32) -> Bool {
  if v >= st.n {
    return true
  }
  let total = 1 << v
  for mask in 0..<total {
    // R = mask 指定的紅色鄰居
    let rset : Array[Int32] = []
    let bset : Array[Int32] = []
    for i in 0..<v {
      if (mask >> i) % 2 == 1 {
        rset.push(i)
      } else {
        bset.push(i)
      }
    }
    if st.k > 1 && has_red_clique(st, rset, st.k - 1) {
      continue
    }
    if st.l > 1 && has_blue_clique(st, bset, st.l - 1) {
      continue
    }
    // 寫入
    for i in 0..<v {
      let is_red = (mask >> i) % 2 == 1
      st.red[v][i] = is_red
      st.red[i][v] = is_red
    }
    if ramsey_assign(st, v + 1) {
      return true
    }
    for i in 0..<v {
      st.red[v][i] = false
      st.red[i][v] = false
    }
  }
  false
}

///|
/// 是否存在 K_n 的 (k,l)-free 二著色。
pub fn ramsey_free_exists(k : Int32, l : Int32, n : Int32) -> Bool {
  if n < k && n < l {
    return true
  }
  let st = rstate_new(n, k, l)
  ramsey_assign(st, 0)
}

///| R(k,l)：最小的 n 使任何二著色都含紅色 K_k 或藍色 K_l。

///|
/// 由定義 R(k,l) = 1 + max{ n | K_n 有 (k,l)-free 著色 }。
pub fn ramsey(k : Int32, l : Int32) -> Int32 {
  // 上界：Erdős–Szekeres（保證終止）
  let bound = erdos_szekeres(k, l)
  let mut n = 1
  while n <= bound {
    if !ramsey_free_exists(k, l, n) {
      return n
    }
    n = n + 1
  }
  bound + 1
}

///| 搜尋見證：回傳 K_n 的一組 (k,l)-free 紅色邊集（找不到回 None）。

///| 這是「R(k,l) > n」的可複驗物件：任何讀者都可以用

///|
/// `ramsey_check_coloring` 獨立驗一次，不必相信搜尋器。
pub fn ramsey_find_witness(
  k : Int32,
  l : Int32,
  n : Int32,
) -> Array[(Int32, Int32)]? {
  let st = rstate_new(n, k, l)
  if ramsey_assign(st, 0) {
    let out : Array[(Int32, Int32)] = []
    for i in 0..<n {
      for j in (i + 1)..<n {
        if st.red[i][j] {
          out.push((i, j))
        }
      }
    }
    Some(out)
  } else {
    None
  }
}

///| 經典的 (3,4)-free K_8 著色（紅色邊，共 10 條）。

///| 這組邊不是抄來的常數表，而是 `ramsey_find_witness(3,4,8)` 的輸出，

///|
/// 再由 `ramsey_check_coloring` 獨立複驗。
pub fn ramsey_3_4_free_k8() -> Array[(Int32, Int32)] {
  [
    (0, 3),
    (0, 5),
    (1, 4),
    (1, 6),
    (2, 5),
    (2, 6),
    (2, 7),
    (3, 6),
    (3, 7),
    (4, 7),
  ]
}

///|
/// 驗證一組紅色邊集確實讓 K_n 沒有紅色 K_k 也沒有藍色 K_l。
pub fn ramsey_check_coloring(
  k : Int32,
  l : Int32,
  n : Int32,
  red_edges : Array[(Int32, Int32)],
) -> Bool {
  let st = rstate_new(n, k, l)
  for (i, j) in red_edges {
    st.red[i][j] = true
    st.red[j][i] = true
  }
  let all = set_full(n)
  (k <= 1 || !has_red_clique(st, all, k)) &&
  (l <= 1 || !has_blue_clique(st, all, l))
}

// ---------------------------------------------------------------------------
// 對實例搜尋的用處：Ramsey 深度界
// ---------------------------------------------------------------------------

///| 若一條搜尋路徑上有 d+1 個「狀態簽名」，簽名只有 2 種顏色，

///| 則路徑長度 ≥ R(d+1,d+1) 時必然出現同色 d-子結構 —— 也就是必然重複。

///|
/// 於是搜尋只需保留長度為 R(d+1,d+1) 的歷史窗口：**有限記憶體迴圈偵測**。
pub fn ramsey_window(d : Int32) -> Int32 {
  ramsey_upper(d + 1, d + 1)
}

///|
pub fn law_ramsey_ramsey_numbers_computed_by_search() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // 由定義可算的小值（不查表）
  chk(out, "ramsey numbers computed by search #1", ramsey(2, 2) == 2)
  chk(out, "ramsey numbers computed by search #2", ramsey(2, 5) == 5)
  chk(out, "ramsey numbers computed by search #3", ramsey(3, 3) == 6)
  // 經典值：R(3,4)=9（R(4,4)=18 見 ramsey_ex.mbt：Paley 見證 + 遞迴上界夾死）
  chk(out, "ramsey numbers computed by search #4", ramsey(3, 4) == 9)
  // Erdős–Szekeres 上限
  chk(out, "ramsey numbers computed by search #5", erdos_szekeres(3, 4) == 10)
  chk(out, "ramsey numbers computed by search #6", erdos_szekeres(4, 4) == 20)
  chk(
    out,
    "ramsey numbers computed by search #7",
    erdos_szekeres(3, 3) >= ramsey(3, 3),
  )
  out
}

///|
pub fn law_ramsey_explicit_3_4_free_coloring_of_k8_is_verified() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let r = ramsey_3_4_free_k8()
  chk(
    out,
    "explicit (3,4)-free coloring of K8 is verified #1",
    ramsey_check_coloring(3, 4, 8, r),
  )
  // 搜尋器自己也要能生出見證，而且與常數表獨立地一致（不要求同一組邊）
  match ramsey_find_witness(3, 4, 8) {
    Some(w) =>
      chk(
        out,
        "explicit (3,4)-free coloring of K8 is verified #2",
        ramsey_check_coloring(3, 4, 8, w),
      )
    None => chk(out, "explicit (3,4)-free coloring of K8 is verified #3", false)
  }
  // K_9 沒有見證 ⇒ R(3,4) ≥ 9（配合 ramsey(3,4)=9 就是等式）
  chk(
    out,
    "explicit (3,4)-free coloring of K8 is verified #4",
    ramsey_free_exists(3, 4, 8),
  )
  match ramsey_find_witness(3, 4, 9) {
    Some(_) =>
      chk(out, "explicit (3,4)-free coloring of K8 is verified #5", false)
    None => chk(out, "explicit (3,4)-free coloring of K8 is verified #6", true)
  }
  out
}
