// ===========================================================================
// 熱帶幾何 III：熱帶線性代數（熱帶行列式 = 最佳指派）
//
// 熱帶行列式（min-plus 版）：
//     tropdet(A) = min_{σ ∈ S_n} Σ_i A[i][σ(i)]
//
// 這個定義本身是 O(n!)；但它同時也是**最小成本完美匹配**的問題，
// 因此可用匈牙利演算法的 O(n³) 版本計算。這是一個典型的
// 「代數定義 → 組合演算法」的推導：
//
//   熱帶行列式  ≡  指派問題  ≡  匈牙利演算法
//
// 本檔案提供三個**獨立**實作，互相對照：
//   * `trop_det`            匈牙利 O(n³)
//   * `trop_det_dp`         子集 DP O(n·2ⁿ)（不用匈牙利，用位元遮罩）
//   * `trop_det_bruteforce` 直接列舉 n!（只用於 n ≤ 8 的對照）
//
// 另外提供 `trop_det_tie_count`：達到最小值的排列個數。
// 熱帶幾何的用語是「矩陣是否熱帶奇異」——最小值被**多於一個**排列達成時，
// 對應的熱帶超曲面在此處不光滑（tropdet 的牛頓多面體在該方向上退化）。
// ===========================================================================

///|
/// 內部哨兵（比任何合法成本都大，且相加不會溢位）。
fn tla_inf() -> Int64 {
  1_000_000_000_000_000_000L
}

///|
/// 匈牙利演算法（最小成本完美匹配），O(n³)。
///
/// 前提：`a` 是 n×n、元素有限（`+∞` 條目請先以足夠大的有限值代替）。
/// 回傳最小總成本；同時可取得指派（見 `trop_assignment`）。
fn hungarian(
  a : Array[Array[Int64]],
  want_perm : Bool,
) -> (Int64, Array[Int32]) {
  let n = a.length()
  let inf = tla_inf()
  let u : Array[Int64] = Array::make(n + 1, 0L)
  let v : Array[Int64] = Array::make(n + 1, 0L)
  let p : Array[Int32] = Array::make(n + 1, 0)
  let way : Array[Int32] = Array::make(n + 1, 0)
  let mut i = 1
  while i <= n {
    p[0] = i
    let mut j0 = 0
    let minv : Array[Int64] = Array::make(n + 1, inf)
    let used : Array[Bool] = Array::make(n + 1, false)
    let mut alive = true
    while alive {
      used[j0] = true
      let i0 = p[j0]
      let mut delta = inf
      let mut j1 = 0
      let mut j = 1
      while j <= n {
        if !used[j] {
          let cur = a[i0 - 1][j - 1] - u[i0] - v[j]
          if cur < minv[j] {
            minv[j] = cur
            way[j] = j0
          }
          if minv[j] < delta {
            delta = minv[j]
            j1 = j
          }
        }
        j = j + 1
      }
      let mut k = 0
      while k <= n {
        if used[k] {
          u[p[k]] = u[p[k]] + delta
          v[k] = v[k] - delta
        } else {
          minv[k] = minv[k] - delta
        }
        k = k + 1
      }
      j0 = j1
      if p[j0] == 0 {
        alive = false
      }
    }
    // 沿交替路回推
    let mut run = true
    while run {
      let j1 = way[j0]
      p[j0] = p[j1]
      j0 = j1
      if j0 == 0 {
        run = false
      }
    }
    i = i + 1
  }
  let perm : Array[Int32] = Array::make(n, 0)
  if want_perm {
    let mut j = 1
    while j <= n {
      perm[p[j] - 1] = j - 1
      j = j + 1
    }
  }
  (-v[0], perm)
}

///|
/// 熱帶行列式：`min_σ Σ_i A[i][σ(i)]`，以匈牙利演算法 O(n³) 計算。
pub fn trop_det(a : Array[Array[Int64]]) -> Int64 {
  let (cost, _) = hungarian(a, false)
  cost
}

///|
/// 熱帶行列式 + 達到最小值的排列（一個 witness）。
pub fn trop_assignment(a : Array[Array[Int64]]) -> (Int64, Array[Int32]) {
  hungarian(a, true)
}

///|
/// 子集 DP 版本：`dp[mask] = 已用掉 mask 這些欄位、處理完前 popcount(mask) 列`的最小成本。
/// O(n·2ⁿ)，n ≤ 20 實用。與匈牙利演算法完全獨立。
pub fn trop_det_dp(a : Array[Array[Int64]]) -> Int64 {
  let n = a.length()
  if n == 0 {
    return 0L
  }
  if n > 22 {
    abort("trop_det_dp: n 太大（2^n 記憶體），請用 trop_det")
  }
  let size = 1 << n
  let inf = tla_inf()
  let dp : Array[Int64] = Array::make(size, inf)
  dp[0] = 0L
  let mut mask = 0
  while mask < size {
    if dp[mask] < inf {
      let row = popcount32(mask)
      if row < n {
        let mut j = 0
        while j < n {
          let bit = 1 << j
          if (mask & bit) == 0 {
            let cand = dp[mask] + a[row][j]
            if cand < dp[mask | bit] {
              dp[mask | bit] = cand
            }
          }
          j = j + 1
        }
      }
    }
    mask = mask + 1
  }
  dp[size - 1]
}

///|
/// 位元計數（硬體 `popcnt` 指令）。
fn popcount32(x : Int32) -> Int32 {
  x.reinterpret_as_uint().popcnt()
}

///|
/// 全排列遞迴（box 存放目前最小值）。
fn perm_walk(
  a : Array[Array[Int64]],
  n : Int32,
  row : Int32,
  used : Array[Bool],
  acc : Int64,
  best : Array[Int64],
) -> Unit {
  if row == n {
    if acc < best[0] {
      best[0] = acc
    }
    return
  }
  for j in 0..<n {
    if !used[j] {
      used[j] = true
      perm_walk(a, n, row + 1, used, acc + a[row][j], best)
      used[j] = false
    }
  }
}

///|
/// 暴力列舉所有排列（n ≤ 8）。純對照用：不做任何剪枝，直接 n! 條路徑。
pub fn trop_det_bruteforce(a : Array[Array[Int64]]) -> Int64 {
  let n = a.length()
  if n == 0 {
    return 0L
  }
  if n > 8 {
    abort("trop_det_bruteforce: n ≤ 8")
  }
  let used : Array[Bool] = Array::make(n, false)
  let best : Array[Int64] = [tla_inf()]
  perm_walk(a, n, 0, used, 0L, best)
  best[0]
}

///|
/// 達到最小值的排列個數（「熱帶奇異」的判據：> 1 表示退化）。
///
/// 以子集 DP 同時計算「最小值」與「達到最小值的排列數」，O(n·2ⁿ)。
/// 用 Int64 計數（n ≤ 20 時 n! < 2.6e18 會接近上限，實務上用 n ≤ 12 對照）。
pub fn trop_det_tie_count(a : Array[Array[Int64]]) -> Int32 {
  let n = a.length()
  if n == 0 {
    return 1
  }
  if n > 20 {
    abort("trop_det_tie_count: n 太大")
  }
  let size = 1 << n
  let inf = tla_inf()
  let dp : Array[Int64] = Array::make(size, inf)
  let cnt : Array[Int32] = Array::make(size, 0)
  dp[0] = 0L
  cnt[0] = 1
  let mut mask = 0
  while mask < size {
    if dp[mask] < inf {
      let row = popcount32(mask)
      if row < n {
        let mut j = 0
        while j < n {
          let bit = 1 << j
          if (mask & bit) == 0 {
            let cand = dp[mask] + a[row][j]
            let m2 = mask | bit
            if cand < dp[m2] {
              dp[m2] = cand
              cnt[m2] = cnt[mask]
            } else if cand == dp[m2] {
              cnt[m2] = cnt[m2] + cnt[mask]
            }
          }
          j = j + 1
        }
      }
    }
    mask = mask + 1
  }
  cnt[size - 1]
}

// ---------------------------------------------------------------------------
// 熱帶譜理論：Karp 最小環平均特徵值 `λ(A)` 與臨界特徵向量（Baccelli et al.）
// ---------------------------------------------------------------------------

///|
/// Karp 最小環平均定理（`O(n³)` 精確最簡有理數 `(num, den)`）：
/// 對 `n × n` min-plus 矩陣 `A`（不可達邊以 `>= tla_inf() / 4` 表示），
/// 計算步長動態規劃 `D[k][v] = min_u (D[k-1][u] + A[u][v])`（`D[0][v] = 0`），
/// 則全體有向環之最小平均權重（即熱帶主特徵值）精確等於
/// `λ(A) = min_{v : D[n][v] < ∞} max_{0 ≤ k < n} (D[n][v] - D[k][v]) / (n - k)`。
/// 若圖無有向環則回傳 `(tla_inf(), 0L)`。
pub fn trop_eigenvalue_karp(a : Array[Array[Int64]]) -> (Int64, Int64) {
  let n = a.length()
  if n == 0 {
    return (tla_inf(), 0L)
  }
  let inf_cut = tla_inf() / 4L
  let inf = tla_inf()
  let d : Array[Array[Int64]] = Array::makei(n + 1, k => {
    if k == 0 {
      Array::make(n, 0L)
    } else {
      Array::make(n, inf)
    }
  })
  for k in 1..<=n {
    for u in 0..<n {
      let du = d[k - 1][u]
      if du >= inf_cut {
        continue
      }
      for v in 0..<n {
        let w = a[u][v]
        if w < inf_cut {
          let cand = du + w
          if cand < d[k][v] {
            d[k][v] = cand
          }
        }
      }
    }
  }
  let mut has_best = false
  let mut best_num = 0L
  let mut best_den = 1L
  for v in 0..<n {
    let dnv = d[n][v]
    if dnv >= inf_cut {
      continue
    }
    let mut v_has = false
    let mut v_num = 0L
    let mut v_den = 1L
    for k in 0..<n {
      let dkv = d[k][v]
      if dkv >= inf_cut {
        continue
      }
      let num = dnv - dkv
      let den = (n - k).to_int64()
      if !v_has || num * v_den > v_num * den {
        v_has = true
        v_num = num
        v_den = den
      }
    }
    if v_has {
      if !has_best || v_num * best_den < best_num * v_den {
        has_best = true
        best_num = v_num
        best_den = v_den
      }
    }
  }
  if !has_best {
    return (inf, 0L)
  }
  let g = gcd64(best_num, best_den)
  let gg = if g == 0L { 1L } else { g }
  (best_num / gg, best_den / gg)
}

///|
/// 求精確整數尺度化熱帶特徵對 `(num, den, x)`：
/// 構造正規化矩陣 `A'[i][j] = den · A[i][j] - num`（最小環權重恰為 `0`、無負環），
/// 以 Kleene 正閉包 `(A')⁺` 定位臨界環頂點 `v*`（`(A')⁺[v*][v*] == 0`），
/// 取星矩陣列 `x[i] = (A')*[i][v*]`，對強連通圖滿足精確特徵方程
/// `min_j (den · A[i][j] + x[j]) == num + x[i]`。
pub fn trop_critical_eigenvector(
  a : Array[Array[Int64]],
) -> (Int64, Int64, Array[Int64])? {
  let n = a.length()
  let (num, den) = trop_eigenvalue_karp(a)
  if den <= 0L {
    return None
  }
  let inf_cut = tla_inf() / 4L
  let inf = tla_inf()
  let plus : Array[Array[Int64]] = Array::makei(n, i => {
    Array::makei(n, j => {
      if a[i][j] >= inf_cut {
        inf
      } else {
        den * a[i][j] - num
      }
    })
  })
  for k in 0..<n {
    for i in 0..<n {
      if plus[i][k] >= inf_cut {
        continue
      }
      for j in 0..<n {
        if plus[k][j] >= inf_cut {
          continue
        }
        let cand = plus[i][k] + plus[k][j]
        if cand < plus[i][j] {
          plus[i][j] = cand
        }
      }
    }
  }
  let mut crit = -1
  for v in 0..<n {
    if plus[v][v] == 0L {
      crit = v
      break
    }
  }
  if crit < 0 {
    return None
  }
  let x = Array::makei(n, i => {
    if i == crit {
      if plus[i][crit] < 0L {
        plus[i][crit]
      } else {
        0L
      }
    } else {
      plus[i][crit]
    }
  })
  Some((num, den, x))
}

///|
/// 驗證整數尺度化熱帶特徵方程 `∀i (x[i] < ∞) : min_j (den·A[i][j] + x[j]) == num + x[i]`。
pub fn verify_trop_eigenpair(
  a : Array[Array[Int64]],
  num : Int64,
  den : Int64,
  x : Array[Int64],
) -> Bool {
  let n = a.length()
  if den <= 0L || x.length() != n {
    return false
  }
  let inf_cut = tla_inf() / 4L
  let mut finite_count = 0
  for i in 0..<n {
    if x[i] >= inf_cut {
      continue
    }
    finite_count = finite_count + 1
    let mut best = tla_inf()
    for j in 0..<n {
      if a[i][j] < inf_cut && x[j] < inf_cut {
        let cand = den * a[i][j] + x[j]
        if cand < best {
          best = cand
        }
      }
    }
    if best != num + x[i] {
      return false
    }
  }
  finite_count > 0
}
