# `semiring/spline/` — 週期性三次樣條，三種解法互相對照（F3 · Layer 3）

> **套件**：`vv0101v01/cubical-hermitian/semiring/spline` · **Layer 3** · 依賴 `semiring-algebra`（`AffineM`）
> **被依賴**：`cmd-semiringreport`、`root`
> **1 檔 348 行**

---

## 1. 定位

同一條週期性三次樣條方程，用三種完全不同的方式解，並要求**三者答案一致**：

| 解法 | 函式 | 複雜度 | 意義 |
|---|---|---|---|
| 稠密高斯消去 | `interp_cubic_dense` / `interp_cubic_dense_open` | `O(n³)` | 教科書版、最容易驗證 |
| 帶狀（三對角） | `interp_cubic_banded` / `solve_banded` | `O(n)` | 真正的生產版本 |
| 么半群（仿射複合） | `interp_cubic_periodic` / `affine_steps` | `O(n)` | **半環／么半群**的落點 |

第三條是本套件被放進 `semiring/` 的理由：`AffineM` 的複合是么半群，樣條的「極點 → 逐步傳遞」正是么半群上的前綴累積。

---

## 2. 檔案與 API

| 群 | 函式 |
|---|---|
| B 樣條基底 | `bspline_basis(...)` |
| 稠密 | `collocation_dense(n, periodic)`、`solve_dense(...)` |
| 帶狀 | `Banded::tridiag(n, diag, off)`、`Banded::get(i,j)`、`solve_banded(bm, b) -> Array[Double]?` |
| 極點 | `cubic_pole() -> Double`（連續三次樣條的 poles 係數，`≈ −2 + √3`） |
| 么半群路徑 | `affine_steps(zeta, ys) -> Array[AffineM]` |
| 三種入口 | `interp_cubic_periodic(y)`、`interp_cubic_dense(y)`、`interp_cubic_banded(y)`、`interp_cubic_dense_open(y)` |
| 檢核 | `check_spline_agreement()`（三者逐點相同） |

### 2.1 `cubic_pole` 與 `affine_steps`
週期性三次樣條的解可寫成
```text
  c_i = zeta · c_{i−1} + d_i ,       zeta = −2 + √3 ≈ −0.2679
```
即**一步仿射遞迴**；把它寫成 `AffineM` 序列後，整條樣條就是序列的么半群乘積 —— 因此 `interp_cubic_periodic` 不需要解任何線性系統。

`solve_banded` 回傳 `Array[Double]?`：主元過小時**回 `None`** 而不是給出被放大的噪聲答案。

---

## 3. 範例

```moonbit
let ys = [1.0, 4.0, 2.0, 7.0, 3.0]

// 三種解法必須一致
let p = @spline.interp_cubic_periodic(ys)
let b = @spline.interp_cubic_banded(ys)
let d = @spline.interp_cubic_dense(ys)
assert_true(@spline.check_spline_agreement(ys))

// 么半群形式：一步仿射遞迴
let steps = @spline.affine_steps(@spline.cubic_pole(), ys)
println(steps[0].apply(0.0))        // AffineM::apply
```

---

## 4. 依賴邊界與驗證

* 依賴 `semiring-algebra` 的 `AffineM`（么半群）；**不依賴 `matrix`** —— 稠密／帶狀解法自帶最小實作，因此本套件可獨立驗證。
* `cmd/semiringreport` 用它示範「么半群乘法 vs 線性系統」的等價。

```bash
moon test semiring/spline --target wasm-gc
```
