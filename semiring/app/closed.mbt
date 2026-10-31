// ===========================================================================
// 代數路徑問題（Algebraic Path Problem, APP）：一份程式，五種答案
//
// 同一個閉包程式
//       C = A*  =  I ⊕ A ⊕ A² ⊕ …
// 在不同半環上就是不同的經典演算法：
//
//   半環             ⊕ / ⊗              A* 的意義            對應的教科書演算法
//   ─────────────────────────────────────────────────────────────────────────
//   BoolSr           or / and            可達性               Warshall / BFS
//   Counting         + / ×               路徑數               DAG 上 DP / 矩陣冪級數
//   Trop             min / +             最短距離             Floyd–Warshall
//   Bottleneck       max / min           最大瓶頸（最寬路徑） Floyd–Warshall 的 max-min 版
//   Prob             + / ×               最可能路徑           各路徑機率相加
//
// 本檔的立場：**這不是類比，是同一段程式**。`app_closure` 只寫一次，
// 型別參數 E 決定它是哪一個演算法。這也是「結構嵌套」在本庫最直接的體現。
//
// 誠實的部分：
//   * 每個半環另外寫一個**專門的**實作（BFS / DP / FW / 列舉），逐格比對；
//   * Counting 的閉包只在 DAG 上收斂（有環時路徑數無限），所以只對 DAG 驗；
//   * 浮點（Prob）用容差比對，並在報告裡標明容差。
// ===========================================================================

///|
using @alg {
  trait Semiring,
  trait StarSemiring,
  type Trop,
  type BoolSr,
  type Bottleneck,
}

///|
/// 由邊三元組建立稠密矩陣（其餘為零元）。
pub fn[E : Semiring] build(
  n : Int32,
  es : Array[(Int32, Int32, E)],
) -> @mat.Mat[E] {
  let m = @mat.Mat::zero(n, n)
  for e in es {
    m.set(e.0, e.1, Semiring::plus(m.get(e.0, e.1), e.2))
  }
  m
}

///|
/// 唯一的 APP 實作：對任意星閉半環計算 A*。
///
/// 這裡刻意用 Lehmann 消去（`closure_lehmann`）而不是原地 Floyd–Warshall，
/// 因為前者對**非冪等**半環（Counting、Prob）也正確；後者不行。
/// 這條型別約束寫在 matrix/star.mbt 裡，不是靠註解提醒。
pub fn[E : StarSemiring] app_closure(
  n : Int32,
  es : Array[(Int32, Int32, E)],
) -> @mat.Mat[E] {
  @mat.closure_lehmann(build(n, es))
}

// ---------------------------------------------------------------------------
// 專門的對照實作（每一條都與上面的泛型程式無關）
// ---------------------------------------------------------------------------

///|
/// 可達性：BFS。與矩陣無關。
pub fn reach_bfs(n : Int32, es : Array[(Int32, Int32)]) -> Array[Array[Bool]] {
  let adj : Array[Array[Int32]] = []
  for _ in 0..<n {
    adj.push([])
  }
  for e in es {
    adj[e.0].push(e.1)
  }
  let out : Array[Array[Bool]] = []
  for s in 0..<n {
    let seen : Array[Bool] = Array::make(n, false)
    let q : Array[Int32] = [s]
    seen[s] = true
    let mut head = 0
    while head < q.length() {
      let u = q[head]
      for v in adj[u] {
        if !seen[v] {
          seen[v] = true
          q.push(v)
        }
      }
      head = head + 1
    }
    out.push(seen)
  }
  out
}

///|
/// 最短距離：本地版 Floyd–Warshall（min-plus），與矩陣套件無關。
pub fn shortest_fw(
  n : Int32,
  es : Array[(Int32, Int32, Int32)],
) -> Array[Array[Int32]] {
  let inf = 0x3FFF_FFFF
  let d : Array[Array[Int32]] = []
  for i in 0..<n {
    let row : Array[Int32] = Array::make(n, inf)
    row[i] = 0
    d.push(row)
  }
  for e in es {
    if e.2 < d[e.0][e.1] {
      d[e.0][e.1] = e.2
    }
  }
  for k in 0..<n {
    for i in 0..<n {
      if d[i][k] >= inf {
        continue
      }
      for j in 0..<n {
        if d[k][j] >= inf {
          continue
        }
        let cand = d[i][k] + d[k][j]
        if cand < d[i][j] {
          d[i][j] = cand
        }
      }
    }
  }
  d
}

///|
/// 最大瓶頸：本地版 FW（max-min）。
pub fn widest_fw(
  n : Int32,
  es : Array[(Int32, Int32, Int32)],
) -> Array[Array[Int32]] {
  let d : Array[Array[Int32]] = []
  for i in 0..<n {
    let row : Array[Int32] = Array::make(n, 0)
    row[i] = 0x3FFF_FFFF
    d.push(row)
  }
  for e in es {
    if e.2 > d[e.0][e.1] {
      d[e.0][e.1] = e.2
    }
  }
  for k in 0..<n {
    for i in 0..<n {
      if d[i][k] <= 0 {
        continue
      }
      for j in 0..<n {
        let cand = if d[i][k] < d[k][j] { d[i][k] } else { d[k][j] }
        if cand > d[i][j] {
          d[i][j] = cand
        }
      }
    }
  }
  d
}

///|
pub fn app_bool(n : Int32, es : Array[(Int32, Int32)]) -> @mat.Mat[BoolSr] {
  let triples : Array[(Int32, Int32, BoolSr)] = []
  for e in es {
    triples.push((e.0, e.1, BoolSr::of(true)))
  }
  app_closure(n, triples)
}

///|

///|
pub fn app_minplus(
  n : Int32,
  es : Array[(Int32, Int32, Int32)],
) -> @mat.Mat[Trop] {
  let triples : Array[(Int32, Int32, Trop)] = []
  for e in es {
    triples.push((e.0, e.1, Trop::new(e.2)))
  }
  app_closure(n, triples)
}

///|
pub fn app_widest(
  n : Int32,
  es : Array[(Int32, Int32, Int32)],
) -> @mat.Mat[Bottleneck] {
  let triples : Array[(Int32, Int32, Bottleneck)] = []
  for e in es {
    triples.push((e.0, e.1, Bottleneck::new(e.2)))
  }
  app_closure(n, triples)
}

///|
/// 最可能路徑：`Prob` 沒有 `StarSemiring` 實例——這不是遺漏，而是**正確的設計**：
/// 機率半環的星只在譜半徑 < 1 時收斂，隨機圖上可能發散。
/// 因此這裡走「冪級數 + 收斂旗標」，把收斂性變成回傳值而不是默默假設。
