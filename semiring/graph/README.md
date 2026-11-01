# `semiring/graph/` — 圖上的半環演算法（F3 · Layer 2）

> **套件**：`vv0101v01/cubical-hermitian/semiring/graph` · **Layer 2** · 依賴 `semiring-algebra`、`semiring-matrix`
> **被依賴**：`semiring-io`、`cmd-semiringreport`、`cmd-symbench`、`root`
> **4 檔 569 行**

---

## 1. 定位

`matrix` 是代數、本套件是**同一套代數在圖論上的四個落點**：

| 檔案 | 演算法 | 用的半環 | 關鍵事實 |
|---|---|---:|---|
| `graph.mbt` | 圖結構、隨機圖、`→Mat` | — | 所有基準的共同輸入 |
| `closure.mbt` | 傳遞閉包（位集 + 函數式分解 + Kleene） | `BoolSr` / `Trop` | 位並行 `÷64` |
| `dijkstra.mbt` | 單源最短路 + 全對 | `Trop` | 二元堆 |
| `pareto.mbt` | 多目標最短路 | `ParetoSet`（非支配集） | **非全序 ⇒ 不能用 Dijkstra** |

---

## 2. `graph.mbt` — 共同輸入

```moonbit
pub(all) struct Graph { ... }              // n, 邊陣列, 可選第二權重 w2
pub fn Graph::build(n, from, to, w) -> Graph
pub fn Graph::edges(self) -> Int32
pub fn Graph::with_second(self, w2) -> Graph   // 多目標（第二權重）
pub fn Graph::random(rng, n, m, max_w) -> Graph
pub fn Graph::random_two(rng, n, m, max_w) -> Graph
pub fn Graph::to_trop_mat(self) -> @mat.Mat[Trop]
```
`random`/`random_two` 吃 `@alg.Rng`（固定種子 ⇒ 基準可重現）；`to_trop_mat` 把圖丟進矩陣代數，於是閉包／Kleene 可直接複用。

---

## 3. `closure.mbt` — 三種閉包

| 型別／函式 | 內容 |
|---|---|
| `BitClosure` | 每列一個位集（`÷64` 位並行） |
| `BitClosure::get(i,j)`、`::row_count(i)` | 查詢與列基數 |
| `closure_bitset(g, row_ops?)` | 主入口；`row_ops` 計數實際 `⊕`/`⊗` 次數 |
| `FunctionalDecomp`、`functional_decompose(g)`、`::reach_count(...)` | **函數式分解**：把圖拆成「函數圖 + 少量邊」，對函數圖的閉包是 `O(n)`（沿鏈走） |
| `has_negative_cycle(m : Mat[Trop])` | 以 `min,` 代數偵測負環（對角線 < 0） |
| `apsp_kleene(g)` | Kleene 星 `A*` 全對最短路 → `(dist, has_neg_cycle)` |

**函數式分解的意義**：現實圖（尤其是置換群、自動機、記憶體指標圖）大多接近函數圖。偵測出「每個節點出度 ≤ 1 的最大子圖」後，那部分的閉包不需要 `O(n³)`。

---

## 4. `dijkstra.mbt` — 堆 + 兩層入口

```moonbit
pub(all) struct MinHeap { ... }
pub fn MinHeap::new(cap) / ::len() / ::push(dist, node) / ::pop() -> (Int32,Int32)?
pub fn dijkstra(g, src) -> (Array[Trop], Bool)    // Bool = 是否有可達
pub fn apsp_dijkstra(g) -> Mat[Trop]
```
`Trop` 的 `inf` 對應「不可達」（不是 `−1` 之類的哨兵值，因此不會與合法權重衝突）。
`apsp_dijkstra` 對每個源跑一次，複雜度 `O(n·m log n)`；與 `closure.mbt` 的 `apsp_kleene`（`O(n³)`）互為對照 —— `cmd/symbench` 對不同密度給出哪個更快的實測。

---

## 5. `pareto.mbt` — 為什麼多目標不能直接 Dijkstra

```text
Dijkstra 的正確性依賴「路徑延伸不會變好」：d(u) ≤ d(v) 時 u 可定案。
在 (ParetoSet, ⊆) 上這是**偏序**而非全序 ⇒ 沒有「下一個最小元素」
⇒ 必須保留每個節點的整個非支配標籤集（label-setting with dominance pruning）。
```
* `pareto_sssp(g, src)` → `Array[ParetoSet]`：每個節點一組非支配成本向量。
* `total_labels(d)`：全部標籤總數（**效能診斷**：多目標的實際成本就是標籤爆炸程度）。
* 內部用 `@alg.ParetoSet` 的 `⊕`（剪枝聯集）與 `⊗`（閔可夫斯基和 + 剪枝）。

---

## 6. 範例

```moonbit
let rng = @alg.Rng::new(7UL)
let g   = @graph.Graph::random(rng, n=64, m=256, max_w=100)

// 1) 位集傳遞閉包
let bc = @graph.closure_bitset(g)
assert_true(bc.get(3, 7) == @graph.closure_bitset(g).get(3, 7))

// 2) 單源最短路
let (dist, reached) = @graph.dijkstra(g, 0)
assert_true(reached[5] == false || !dist[5].is_inf())

// 3) 多目標
let g2 = @graph.Graph::random_two(rng, 40, 120, 50)
let labels = @graph.pareto_sssp(g2, 0)
println(@graph.total_labels(labels))          // 標籤爆炸程度
```

---

## 7. 驗證

```bash
moon test semiring/graph --target wasm-gc
```
