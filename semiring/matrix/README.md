# `semiring/matrix/` — 泛型半環矩陣與六種乘法（F3 · Layer 1，6 檔 1,594 行）

> **套件**：`vv0101v01/cubical-hermitian/semiring/matrix` · **Layer 1** · 依賴 `semiring-algebra`
> **被依賴**：`semiring-graph`、`semiring-cat`、`semiring-trop`、`cmd-semiringreport`、`cmd-symbench`、`root`
> **整個 F3 聯邦的重心**：`Mat[E]` 的 `E` 一換，演算法全部重寫 —— 這裡只寫一次。

---

## 1. 定位

```moonbit
pub(all) struct Mat[E] { rows; cols; data : Array[E] }    // row-major
```
六種乘法是**同一個抽象**的不同落點，而且每一種都有對應的「為什麼需要它」：

| 乘法 | 檔案 | 動機 |
|---|---|---|
| `mul_naive` | `mul.mbt` | 教科書版，`O(n³)` 最差 cache 行為（`i,j,k`） |
| `mul_ikj` | `mul.mbt` | 迴圈交換 ⇒ 連續寫入（`i,k,j`），同一算式快 2–4× |
| `mul_blocked` | `mul.mbt` | 分塊，讓工作集落在 cache |
| `mul_trop` | `mul.mbt` | 熱帶專用：`min,+` 可跳過 `+∞` 整列 |
| `mul_region` | `mul.mbt` | 只算指定子矩形（四俄羅斯人的基礎） |
| `mul_rows_par` | `mul_par.mbt` | 按列平行的後端抽象 |
| `csr_mul` / `csr_mul_minplus` | `csr.mbt` | 稀疏：只走非零（`O(nnz)`） |

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `mat.mbt` | 128 | `Mat[E]` 基本結構與取值／建構 |
| `mul.mbt` | 297 | 五種稠密乘法 + 區域複製 |
| `star.mbt` | 322 | 閉包與星運算（FW／Lehmann／分塊／級數） |
| `csr.mbt` | 624 | 稀疏 CSR：建構、`csr_mul`、熱帶 SSSP/APSP/閉包 |
| `blocking.mbt` | 116 | cache 參數自動選擇（`choose_tile`／`choose_block_l1`／`choose_panel_l2`） |
| `mul_par.mbt` | 107 | 平行後端（`mul_rows_par`、`closure_fw_par`） |

---

## 3. `mat.mbt`

`Mat::new(rows, cols, fill)`、`::zero`、`::identity(n)`、`::from_flat(rows, cols, flat)`、`::get`、`::set`、`::copy`、`::transpose`、`::is_square`、`::byte_size`。
`byte_size` 是**診斷用**的：它讓「這個矩陣放不進 L2」這類判斷變成數字而非直覺（`blocking.mbt` 就吃它）。
`Mat::from_flat` 的 `flat` 長度必須等於 `rows*cols`（唯一允許的 panic 條件）。

---

## 4. `mul.mbt` — 五種稠密乘法

```moonbit
pub fn[E : Semiring] mul_naive(a, b, c, ops?)            // i-j-k
pub fn[E : Semiring] mul_ikj(a, b, c, ops?)              // i-k-j（連續寫）
pub fn[E : Semiring] mul_blocked(a, b, c, ops?)          // 分塊
pub fn[E : TropicalSemiring] mul_trop_generic(a,b,c)     // 熱帶通式
pub fn mul_trop(a : Mat[Trop], b : Mat[Trop], ops?)      // 熱帶特化
pub fn mul_trop_plain(a, b, ops?)                        // 對照組
pub fn[E : Semiring] mul_region(a, b, c, r0, c0, k0, ...) // 子矩形
pub fn[E] copy_region_in(...) / copy_region_out(...)
```
* **`ops : Ops?`** 讓每一次 `⊕`/`⊗` 都被計數 —— 於是「`mul_ikj` 比 `mul_naive` 快」可以被證明是常數因子，而**運算次數完全相同**（`check_mul_agreement()` 驗所有乘法給出同一個結果）。
* `mul_trop` 的特化：`Trop.inf` 的列／欄可整段跳過，因此稀疏化在熱帶代數下幾乎免費。

---

## 5. `star.mbt` — 四種閉包

```text
A* = 1 ⊕ A ⊕ A² ⊕ A³ ⊕ …      （在冪等半環上收斂為傳遞閉包）
```
| 函式 | 算法 | 型別約束 | 複雜度／常數 |
|---|---|---|---|
| `fw_region(m, ...)` | Floyd–Warshall 的單一「轉軸」步驟 | `IdempotentSemiring` | 四俄羅斯人的積木 |
| `closure_fw_inplace(edges)` | 經典 FW | `IdempotentSemiring` | `O(n³)`，原地 |
| `closure_lehmann(edges, ops?)` | **Lehmann** | **`StarSemiring`** | `O(n³)` 但常數更小；用 `A* = (1 ⊕ A)^{n−1}` |
| `closure_blocked(edges)` | 分塊 FW | `IdempotentSemiring` | cache 友善 |
| `closure_series(edges, k)` | 級數 `1 ⊕ … ⊕ Aᵏ` | `Semiring` | 非冪等也可（如 `Counting`） |

輔助：`mat_all(m, f)`、`mat_plus`、`mat_is_zero`、`mat_equal`。
**關鍵的型別細節**：`closure_lehmann` 需要 `StarSemiring`（因為它真的用 `star`），而其他三者只需冪等 —— 這個差別是**編譯期就檢查的**，不會在執行期才發現「這個半環沒有星」。

---

## 6. `csr.mbt` — 稀疏

```moonbit
pub(all) struct Csr[E] { ... }
pub fn[E] Csr::nnz()        pub fn[E] Csr::row_range(i) -> (lo,hi)
pub fn[E] Csr::get(i,j) -> E?          // 缺席 ⇒ None（不是 zero！）
pub fn[E : Semiring] Csr::from_triplets(...) / ::from_dense(m) / ::to_dense()
pub fn[E : Semiring] csr_mul(a,b,ops?) -> Csr[E]
pub fn[E : TropicalSemiring] csr_mul_minplus(a,b)      // 熱帶的稀疏乘法
pub fn[E : TropicalSemiring] csr_sssp(g, src)         // 單源
pub fn[E : TropicalSemiring] csr_apsp(g)              // 全對
pub fn[E : TropicalSemiring] csr_closure(g)           // 閉包（稀疏 FW）
```
`Csr::get` 回 `Option` 而非 `zero`：**「這條邊不存在」與「這條邊的權重是 0」是不同的事**。熱帶半環上 `zero = +∞`，混淆兩者會讓「權重為 0 的邊」被當成缺邊，熱帶 SSSP 給出錯答案。

---

## 7. `blocking.mbt` — 讓 cache 參數成為計算

```moonbit
pub fn choose_tile(...)          // 依 n 與元素大小挑 tile
pub fn choose_block_l1(...)      // L1 容量 → 分塊邊長
pub fn choose_panel_l2(...)      // L2 容量 → panel 寬度
pub fn[E : Semiring] mul_blocked_auto(a, b, ops?)      // 自動挑參數的分塊乘法
pub fn[E : IdempotentSemiring] closure_blocked_auto(m, ops?)
```
常數（L1/L2 容量、元素位元組數）是**輸入**而非硬編碼假設；`mul_blocked_auto` 在所有 target 上都會給出正確結果，只影響速度。

---

## 8. `mul_par.mbt` — 平行只是一個後端

```moonbit
pub fn[E : Semiring] mul_rows_par(a, b, rows_per_task, ops?)
pub fn[E : IdempotentSemiring] closure_fw_par(m, tasks, ops?)
```
沒有執行緒時退化為序列版本（同一個結果、同一個 `Ops` 計數）。真正的平行後端在 `semiring/par`、`semiring/par_host`（`accel` 的 GPU 路徑再往上）。

---

## 9. 範例

```moonbit
let ops = @alg.Ops::new()

// 1) 同一算式、三種乘法、同一結果
let a = @mat.Mat::from_flat(3, 3, [@alg.Trop::new(0), ..., ])
let b = ... 
let c1 = @mat.mul_naive(a, b, ops)
let c2 = @mat.mul_ikj(a, b, ops)
let c3 = @mat.mul_blocked(a, b, ops)
assert_true(@mat.mat_equal(c1, c2) && @mat.mat_equal(c2, c3))
println(ops.total())                  // 運算次數完全相同

// 2) 閉包：FW vs Lehmann（Lehmann 只需 StarSemiring）
let r = @mat.closure_blocked(edge_mat)
let s = @mat.closure_lehmann(edge_mat)

// 3) 稀疏熱帶 SSSP
let g = @mat.Csr::from_triplets(rows, cols, from, to, weight)
let d = @mat.csr_sssp(g, 0)
```

---

## 10. 驗證

```bash
moon test semiring/matrix --target wasm-gc
```
`cmd/semiringreport` 對 `mul_naive` / `mul_ikj` / `mul_blocked` / `mul_trop` / `csr_mul` 給出**同一份輸入下的實測時間與運算計數表**。
