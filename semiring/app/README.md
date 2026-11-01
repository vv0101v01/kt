# `semiring/app/` — 兩個「半環直接解應用的問題」樣板（F3 · Layer 4）

> **套件**：`vv0101v01/cubical-hermitian/semiring/app` · **Layer 4** · 依賴 `semiring-algebra`
> **被依賴**：`cmd-semiringreport`、`root`
> **2 檔 371 行** —— 整個 F3 聯邦中最小的套件，但它是**「半環不是數學玩具」**的證據。

---

## 1. 定位

`matrix` 給工具、`bp`／`io`／`graph` 給演算法，本套件把兩者接上**真實世界問題**，並且刻意選了兩個「換半環就換答案」的例子：

| 檔案 | 問題 | 用的半環 | 為什麼非它不可 |
|---|---|---:|---|
| `closed.mbt` | 傳遞閉包 | `BoolSr`（∨,∧） | 只需可達性；`ℤ` 版本會做無謂的加法 |
| `portfolio.mbt` | 資產配置 | `TropF`（min,+）／`Prob`（+,×） | 同一份資料，一個問最壞情況、一個問期望值 —— **同一個矩陣，兩個半環，兩個答案** |

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `closed.mbt` | 203 | 以 `BoolSr` 為係數的傳遞閉包，含三種算法對照 |
| `portfolio.mbt` | 168 | 投資組合的熱帶／機率雙解讀 |

---

## 3. `closed.mbt` — 傳遞閉包就是矩陣乘法

```text
R⁺ = R ⊕ R² ⊕ R³ ⊕ …  =  R ⊗ R*        （在 BoolSr 上，R* 收斂）
```
* 主入口：`reachability_closure(n, edges)`、`closure_from_matrix(mat)`、`closure_pair(n, edges, s, t)`。
* **三路對照**（結果必須完全一致，`check_closure_agreement()` 驗）：
  1. `closure_fw_inplace` — **Floyd–Warshall**（`O(n³)`，位元並行）；
  2. `closure_lehmann` — **Lehmann 的 `O(n³)` 但常數更小**，利用 `A* = (I ⊕ A)^{n−1}` 的三段分解；
  3. `closure_blocked` — **分塊 / 四俄羅斯人**寫法，`n` 較大時 cache 友善。
* 這三個名字在 `cmd/symbench` 裡是**基準測試的固定選項**（見 `semiring/matrix/README.md`）。
* 性質檢核：`closure_is_transitive`、`closure_is_reflexive_if_diag`、`closure_idempotent`（`(R⁺)⁺ = R⁺`）。

---

## 4. `portfolio.mbt` — 同一個矩陣，兩個半環

```text
  資料：n 個資產、m 個情境，報酬矩陣 R : m × n
  ├─ 半環 A = TropF（min, +）：求「最壞情境下的最大最小報酬」
  └─ 半環 B = Prob（+, ×）  ：求「情境機率下的期望報酬」
```
* API：`scenario_returns`、`worst_case_allocation`、`expected_return`、`tropical_vs_probabilistic`（回傳 `PortfolioDualReport`：兩個半環的答案 + 一致性判讀）。
* 這個檔案的教學價值：它讓「半環選擇」變成**白紙黑字的兩欄數字**，而不是抽象的 `S`。

---

## 5. 範例

```moonbit
// 1) 傳遞閉包（三算法一致）
let edges = [(0,1), (1,2)]
assert_true(@app.closure_pair(3, edges, 0, 2))
assert_true(@app.check_closure_agreement(3, edges))

// 2) 雙半環投資組合
let rep = @app.tropical_vs_probabilistic(returns, scenario_probs)
println(rep.worst_case)      // min,+ 的解
println(rep.expected_value)  // +,× 的解
```

---

## 6. 依賴邊界與驗證

* 只用 `semiring-algebra` 的 trait 與 `BoolSr`/`TropF`/`Prob` —— **不依賴 `matrix`**，因此可在 `matrix` 尚未編譯時獨立驗證（便於教學與最小重現）。
* 被 `cmd/semiringreport` 引用為「應用示範」小節。

```bash
moon test semiring/app --target wasm-gc
```
