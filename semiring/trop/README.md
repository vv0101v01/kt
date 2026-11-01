# `semiring/trop/` — 熱帶幾何：多項式、牛頓多面體、熱帶行列式（F3 · Layer 3，3 檔 1,307 行）

> **套件**：`vv0101v01/cubical-hermitian/semiring/trop` · **Layer 3** · 依賴 `semiring-algebra`、`semiring-matrix`
> **被依賴**：`cmd-semiringreport`、`root`
> **聯邦中數學密度最高的一包**：把 (min,+) 從「演算法工具」升級成「幾何物件」。

---

## 1. 定位

```text
  熱帶多項式  f = ⊕ c ⊗ x^a          （min, +）
      │
      ├─ 牛頓多面體 Newton(f) = conv{ a | c_a ≠ +∞ }       ← 幾何側
      │      └─ 對偶曲線 / 細分（dual subdivision）        ← 格點幾何側
      │
      ├─ 根（roots_with_mult）                             ← 代數側
      │      └─ 根 = 對偶曲線的頂點（Fundamental Theorem）  ← 兩側對接
      │
      └─ 熱帶行列式 trop_det = min over 置換 Σ a_{i,σ(i)}   ← 組合側
```

三檔一個圓：`poly.mbt`（多項式與根）→ `newton.mbt`（牛頓多面體與對偶細分）→ `tla.mbt`（熱帶線性代數）。

---

## 2. `poly.mbt`（325 行）— 熱帶多項式與根

| 型別 | 說明 |
|---|---|
| `Rat` | 精確有理數（`Rat::new(n,d)`、`::of_int`、`::to_double`）—— 根是**有理數**，不用浮點 |
| `UniPoly` | 單變量熱帶多項式（係數 `Array[Int32]`，`+∞` 以飽和值表示） |

| 函式 | 作用 |
|---|---|
| `sat_add_i32` / `sat_mul_i32` | **飽和**算術：熱帶的 `0 = +∞`，任何運算碰到它必須是 `+∞`，不能溢位回有限值 |
| `UniPoly::new`、`::degree`、`::eval(x)` | 建構、次數、求值（`min`） |
| `UniPoly::argmin_at(x : Rat)` | 在 `x` 處達到最小值的**項索引集合**（可能是多項） |
| `UniPoly::lower_hull()` | 下包絡的線段（牛頓多邊形的 1D 版本） |
| **`UniPoly::roots_with_mult()`** | 根與**重數**（有理數） |
| `UniPoly::roots()` | 只取根 |
| `UniPoly::multiplicity_sum()` | 重數總和 = 次數（**基本定理的可執行版**） |
| `trop_poly_mul(f, g)` | 熱帶乘法 = 係數的 `min-plus` 卷積 |
| `roots_equal` / `sort_rats` / `rat_gt` | 比較與排序（根是多重集） |

`argmin_at` 是核心：熱帶多項式的「根」就是**下包絡的折點**，也就是 `argmin` 由單元素變成多元素的位置。

---

## 3. `newton.mbt`（725 行）— 牛頓多面體與對偶細分

| 型別 | 說明 |
|---|---|
| `Pt2` | 格點 `Pt2::new(x,y)`、`::cross(a,b)`（`Int64`，防溢位）、`::prim()`（本原化）、`::lattice_len()`、`::rot90()` |
| `BTerm` | 雙變量項 `c · x^i y^j` |
| `BPoly` | 熱帶雙變量多項式 |
| `Face` | 對偶細分的面 |

| 群 | 函式 |
|---|---|
| 求值 | `BPoly::new`、`::eval(wx, wy)`、`::minima_scaled(...)`（縮放格點 ⇒ 精確整數比較） |
| **牛頓多面體** | `BPoly::newton_hull()`（凸包頂點）、`::newton_area2()`（**兩倍面積**，整數 ⇒ 無捨入） |
| **對偶細分** | `BPoly::subdivision()` → `Array[Face]`、`::hull_of(idx)`、`::face_area2(f)`、`::subdivision_area2(faces)` |
| **對偶曲線** | `BPoly::dual_curve(faces)` → `Array[DualEdge]` |
| 對偶性檢核 | `balancing_residuals(...)`（每條邊的平衡條件）、`BPoly::check_duality(...)`（**面積守恆 + 對偶性**）、`BPoly::check_ties_on_faces(...)` |

**為什麼全部用整數**：`area2`（兩倍面積 by shoelace）在格點多邊形上**恆為整數**；`cross` 用 `Int64`；`minima_scaled` 先乘上公分母。因此「對偶細分是否真的細分」（面積相加必須等於原多面體面積）是一個**精確等式**，不是近似。
這正是全倉的精神轉移：`condensed`/`topos` 用 `Rat`/`AlgNum`，此處用格點整數 —— 兩者都是「不讓浮點混進證明」。

---

## 4. `tla.mbt`（257 行）— 熱帶線性代數

```text
trop_det(A) = min over σ ∈ S_n  Σ_i A[i][ σ(i) ]        （min, + 上的行列式）
```
| 函式 | 算法 | 複雜度 |
|---|---|---|
| `trop_det_bruteforce(A)` | 枚舉 `n!` 個置換 | `O(n!)` —— **裁判** |
| `trop_det_dp(A)` | 子集 DP（Held–Karp 形狀） | `O(2ⁿ · n)` |
| `trop_det(A)` | 正式入口（擇優） | — |
| `trop_assignment(A)` | 回傳 `(值, 置換)` | — |

**三路必須一致**：`trop_det_bruteforce` 是 `n ≤ 8` 的真理來源，`trop_det_dp` 在 `n ≤ 20` 可用，`trop_det` 依 `n` 自動選。

---

## 5. 範例

```moonbit
// 1) 根與重數（有理數，精確）
let f = @trop.UniPoly::new([0, 3, 1, 4])        // 係數（+∞ 表示缺項）
let rs = f.roots_with_mult()                     // Array[(Rat, Int32)]
assert_true(f.multiplicity_sum() == f.degree())

// 2) 牛頓多面體與對偶細分（面積守恆）
let g = @trop.BPoly::new([...])
assert_true(g.check_duality(g.subdivision()))    // 精確整數等式

// 3) 熱帶行列式（三路一致，小 n）
let a = [[0L, 5L, 9L], [5L, 0L, 3L], [9L, 3L, 0L]]
assert_true(@trop.trop_det(a) == @trop.trop_det_bruteforce(a))
let (val, perm) = @trop.trop_assignment(a)       // 順便拿到最佳置換
```

---

## 6. 依賴邊界與驗證

* 依賴 `semiring-algebra`（`Trop`/`TropF` 與半環 trait）、`semiring-matrix`（`Mat`）。
* `bridge` 的 K– 系列用本套件的 `trop_det` 對接 `symlib` 的置換符號與 `topos` 的組合不變量。

```bash
moon test semiring/trop --target wasm-gc
```
