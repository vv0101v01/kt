# `semiring/bp/` — 廣義分配律上的連帶相信（F3 · Layer 3）

> **套件**：`vv0101v01/cubical-hermitian/semiring/bp` · **Layer 3** · 依賴 `semiring-algebra`
> **被依賴**：`cmd-semiringreport`、`root`
> **1 檔 354 行** —— 全聯邦「一段程式、多個語義」最純粹的示範。

---

## 1. 定位

Aji–McEliece **廣義分配律（GDL）**：

```text
只要 ⊕ 對 ⊗ 分配（也就是半環），因子圖上的邊緣化就可以「局部」做：
    ⊕_x [ f(x,y) ⊗ g(x,z) ]  =  ( ⊕_y f(x,y) ) ⊗ ( ⊕_z g(x,z) )
```
左邊要 `q³` 次運算、右邊只要 `2q²`。對 `n` 個變數、每個 `q` 個取值：暴力 `qⁿ`，樹上訊息傳遞只要 `Σ_f q^{|scope(f)|}`。**差別不是常數，是指數。**

本檔把這件事寫成對**任意半環**都成立的程式：
* 換 `Prob`（+,×）⇒ **sum-product**，得到邊緣機率；
* 換 `TropMax`（max,+）⇒ **max-product**（取對數即 Viterbi），得到 MAP。

---

## 2. 檔案與 API

| 型別 | 說明 |
|---|---|
| `Factor[E]` | 因子：`vars : Array[Int32]` + `table : Array[E]` |
| `FactorGraph[E]` | `nvar`、`card : Array[Int32]`、`factors` |
| `BpResult[E]` | 收斂旗標 + 邊緣 + 迭代數 |

| 函式 | 作用 |
|---|---|
| `Factor::new(vars, table)` | 建構 |
| `table_index(f, card, assign)` | 混合進位索引（最後一個座標最快） |
| `factor_size(f, card)` | `Π card[v]`（與 `table.length()` 對照即為不變量檢查） |
| `decode_assign(idx, card)` | 索引 → 賦值（反向） |
| `total_assignments(card)` | `qⁿ`（暴力法的分母） |
| `is_tree(g)` | 是否為樹（**精確性**的前提） |
| **`bp_marginals(g)`** | 通用訊息傳遞（任意 `Semiring`） |
| `marginals_sum_product(g)` | `Prob` 上的具體化包裝 |
| `brute_force_sum_product(g)` | `qⁿ` 暴力法 —— **裁判** |

---

## 3. 誠實的部分（§18 會印出來）

| 情形 | 結論 |
|---|---|
| **樹上** | 訊息傳遞**精確**，與 `qⁿ` 暴力法**逐位元相同**（`check_bp_tree_exact()`） |
| **有環** | BP 只是**近似**（固定點 ≠ 真邊緣）。本庫**不掩蓋**，而是量出誤差值並在文件寫明有環要改用 junction tree / cutset conditioning |

這是全倉反覆出現的態度：**能證的就證，不能證的就量，並把「量到的」寫在報告裡。**

---

## 4. 範例

```moonbit
// 1) 樹上的 sum-product：與暴力法逐位元相同
let g = tree_factor_graph()          // FactorGraph[@alg.Prob]
assert_true(@bp.is_tree(g))
let bp = @bp.marginals_sum_product(g)
let bf = @bp.brute_force_sum_product(g)
assert_true(@bp.max_abs_diff_between(bp, bf) == 0.0)

// 2) 換半環即換語義：同一段 bp_marginals
let gmax = factor_graph_max()        // FactorGraph[@alg.TropMax]
let map  = @bp.bp_marginals(gmax)    // max-product ⇒ MAP
```

---

## 5. 依賴邊界與驗證

* 只依賴 `semiring-algebra`（trait 與 `Prob`/`TropMax`）—— 不依賴 `matrix`、不依賴 `graph`。
* `bridge` 的 `K–` 系列用它的 `brute_force_sum_product` 作為「精確性裁判」的標準工具。

```bash
moon test semiring/bp --target wasm-gc
```
