# `semiring/cat/` — 去量化、自由範疇與集合矩陣（F3 · Layer 3）

> **套件**：`vv0101v01/cubical-hermitian/semiring/cat` · **Layer 3** · 依賴 `semiring-algebra`、`semiring-matrix`
> **被依賴**：`cmd-semiringreport`、`root`
> **3 檔 554 行**

---

## 1. 定位

半環上的矩陣是**範疇代數**的具體化；本套件把這句話反過來用：

```text
  集合範疇的態射集（SetMat）  ──decategorify──►  計數半環上的矩陣
  圖的自由範疇                ──hom_sets────►    態射集   ──►  路徑計數
  熱帶（min,+）              ──dequantize──►    「量化」的逆：把尺度 h 提出來
```
三檔分別對應三句口號：**去量化**（`dequant.mbt`）、**自由範疇**（`free.mbt`）、**集合矩陣**（`setmat.mbt`）。

---

## 2. `dequant.mbt`（165 行）— 尺度極限

```moonbit
pub fn dequantize(xs : Array[Double], h : Double) -> Double   // 數值穩定：先減 min
pub fn dequantize_naive(xs : Array[Double], h : Double) -> Double  // 教科書版（會溢位）
pub fn dequant_error(xs : Array[Double], h : Double) -> Double     // 兩者差距
pub fn minplus_mul(...)        // (min,+) 卷積
pub fn dequantized_mul(...)    // 去量化後的乘法與 min-plus 的對應
pub fn max_abs_diff(a, b)
```
* **數學內容**：`(min,+)` 代數取 `h` 為尺度時，`h·(a ⊗ b)` 在 `h → 0⁺` 的極限就是 min-plus 卷積的「去量化」版本 —— 這是 Maslov 去量化（dequantization）的核心。
* **工程內容**：`dequantize_naive` 直接算 `Σ exp(-xᵢ/h)`，`h` 小時整項下溢為 0；`dequantize` 先減去 `min xs` 再取指數，誤差被控制在小範圍。`dequant_error` 讓「穩定性」可量測。

---

## 3. `free.mbt`（253 行）— 圖的自由範疇

```moonbit
pub(all) struct DiGraph { ... }
```
| 群 | 函式 |
|---|---|
| 結構 | `DiGraph::new(n)`、`::edge(u,v)`、`::edge_count()`、`::is_dag()`、`::topo_order()` |
| **態射集** | `::hom_sets()` → `hom[u][v] = [路徑（邊序列）]` |
| 計數（三路一致） | `::path_counts()`、`::path_counts_by_powers()`（矩陣冪）、`::path_counts_by_closure()`（閉包） |
| 交接到矩陣 | `::adjacency()` → `Mat[Counting]`、`::hom_setmat()` → `SetMat` |

**重點**：`hom_sets` 給出**態射本身**（不只是數目），因此自由範疇的 `id`／`comp` 是可列舉、可檢查的；而 `path_counts`／`by_powers`／`by_closure` 三條路徑必須給出同一個數 ⇒ `check_free_category()` 三者交叉驗證。
DAG 上 `hom_sets` 是有限的（`topo_order` 保證），有環時會被 `is_dag` 擋下。

---

## 4. `setmat.mbt`（136 行）— 集合係數的矩陣

```moonbit
pub(all) struct SetMat { ... }     // 係數是「態射的集合」（以邊序列表示）
pub fn SetMat::new(rows, cols)
pub fn SetMat::get(i, j) -> Array[Array[Int32]]
pub fn SetMat::add(i, j, path)      // 加入一條路徑
pub fn smat_mul(a, b)               // ⊗ = 串接（笛卡兒積）
pub fn smat_plus(a, b)              // ⊕ = 聯集
pub fn decategorify(m) -> Mat[Counting]   // 基數化：|SetMat| = 計數矩陣
```
* `smat_mul` 是**集合級的串接**：`(a ⊗ b)[i][j] = ⋃_k { p ++ q | p ∈ a[i][k], q ∈ b[k][j] }`。
* `decategorify` 是範疇化／去範疇化的核心事實：**基數保持乘法** —— 先乘再取基數 = 先取基數再乘。`check_decategorification()` 用隨機圖驗證此交換律。

---

## 5. 範例

```moonbit
// 1) 圖的自由範疇：態射集與計數
let g = @cat.DiGraph::new(4)
g.edge(0, 1); g.edge(1, 2); g.edge(0, 2)
let homs = g.hom_sets()
assert_true(homs[0][2].length() == 2)          // 兩條路徑：直達、經 1
let c1 = g.path_counts()
let c2 = g.path_counts_by_powers()
assert_true(c1 == c2)

// 2) 集合矩陣與去範疇化
let sm = g.hom_setmat()
let cnt = @cat.decategorify(sm)                 // Mat[Counting]
assert_true(@cat.check_decategorification(g))

// 3) 去量化的數值穩定性
let err = @cat.dequant_error(xs, h=0.01)        // 穩定版 vs naive 的差距
```

---

## 6. 依賴邊界與驗證

* 依賴 `semiring-algebra`（`Counting`、`Rng`）、`semiring-matrix`（`Mat`）。
* `bridge/permutation_bridge.mbt` 用 `SetMat` 對接 `symlib` 的置換；`tensor` 的 `C₃ = 5` 與此處的路徑計數同源。

```bash
moon test semiring/cat --target wasm-gc
```
