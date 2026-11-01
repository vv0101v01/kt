# `cmd/symbench/` — `symlib` 效能基準與七族衍生演算法（2 檔 594 行）

> **套件**：`vv0101v01/cubical-hermitian/cmd/symbench` · `pkgtype(kind: "executable")`
> **依賴**：`symlib`、`moonbitlang/core/bench`（`@mbench`）
> **建議**：`moon run cmd/symbench --target native --release`

---

## 1. 定位

> 每個「更快」都要附上**同一份輸入下的實測毫秒數**，以及**同一結果的檢查**。

本套件分兩層：

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `main.mbt` | 52 | 12 個具名案例的全管線計時（搜索 → Schreier–Sims → 群作用 → 軌道折疊） |
| `derived.mbt` | 542 | **七族衍生演算法**：由規範形式／範疇化導出 vs 暴力全搜索 |

---

## 2. `main.mbt` — 12 個案例的全管線

```text
for each Case { name, g : Graph, expect : Int64 }:
    search_graph(g, true)           → r.aut_gens, r.nodes, r.leaves, r.ties
    PermGroup::new(g.order(), gens) → grp.order()  vs  expect  ⇒ OK/FAIL
    fold_graph(g, grp)              → folded.k / g.order()
```
每一行輸出：
```text
Petersen: |Aut|=120(OK) nodes=... leaves=... ties=... fold=.../10 search=...ms sgs=...ms fold=...ms
```
* `expect` 是**已知的群階**（數學事實），因此每個案例都是「演算法算出 `|Aut|` 是否等於定理的值」。
* 三個階段各自計時，因此「慢在哪一段」是看得見的。

| 案例 | `expect` `|Aut|` | 為什麼選它 |
|---|---:|---|
| `P5` | 2 | 路徑的自同構只有反轉 |
| `C6` | 12 | 二面體群 |
| `Petersen` | 120 | `S₅` 的理想代表 |
| `K5` | 120 | 完全圖 = `S₅` |
| `K10` | 3,628,800 | `10!` —— 搜索規模的壓力測試 |
| `K3,3` | 72 | 二部完全圖（`S₃ × S₃ ⋊ C₂`） |
| `star4` | 24 | `S₄` |
| `Q3` / `Q4` / `Q5` | 48 / 384 / 3840 | 超立方體（`2ⁿ ⋊ Sₙ`），`n` 增大時的尺度 |
| `C60` | 120 | 大 `n` 但群小（buckminsterfullerene 的骨架） |
| `P40` | 2 | 大 `n`、群極小 —— 搜索的最壞形狀 |

**單位只在一處換算**：`monotonic_clock_end` 回傳**微秒**，全檔只在 `bench_one` 內除以 1000 得毫秒（`derived.mbt` 頂註明寫「全庫計時只在此一點換算，避免單位散落」）。

---

## 3. `derived.mbt` — 七族衍生演算法（A–G）

每一族都是「**公式／定理導出的演算法** vs **暴力全搜索**」，並同時輸出 `OK/FAIL`（結果一致）與 `×`（成本比）。

| 族 | 函式 | 用什麼定理免去搜索 |
|---|---|---|
| **A. 分量分解** | `bench_decomp` | `|Aut(G₁ ⊔ G₂)| = |Aut(G₁)| · |Aut(G₂)|` ⇒ 免全搜索 |
| **B. Whitney 線圖** | `bench_line` | `|Aut(L(G))|` 由 `|Aut(G)|` 與核階推出 ⇒ **不用搜索 `L(G)`** |
| **C. 補圖對偶** | `bench_dual` | 雙通道交叉驗證（複雜度中性；賣點是**自我驗證**，不是加速） |
| **D. 標記向量** | `bench_marks` | 標記向量是 `G`-集的**完全不變量** ⇒ 免階乘級枚舉判定 `G`-集同構 |
| **E. 置換集** | `bench_permset` | 置換集代數 ⇒ 直接算出 `|Aut|` 而不枚舉 |
| **F. 軌道折疊** | `bench_fold` | 軌道分解 ⇒ 圖折疊後規模 `k/n`，後續成本依 `k` 而非 `n` |
| **G. Cayley** | `bench_cayley` | `Cayley(G,S)` 的自同構由 `S` 的穩定性推出 ⇒ **定理下界 `O(1)`（免搜索）** vs 全搜索的毫秒數 |

`bench_derived()` 依序跑 A→G。

### 3.1 誠實的一族：C
`bench_dual` 的輸出會在複雜度上**沒有優勢**（補圖與原圖一樣大）。它被保留，因為它的價值是**兩個獨立的實作給出同一個答案** —— 這正是全倉的驗證哲學（`bridge` 亦然）。

---

## 4. 執行與讀法

```bash
moon run cmd/symbench --target native --release
```
輸出三段：
```text
=== symlib bench (native release) ===
...12 行案例...
=== 衍生演算法基準（規範形式 × 範疇化）===
...A–G...
=== 衍生演算法基準結束 ===
```
**注意**：時間數字隨機器浮動，`|Aut|` 與 `OK/FAIL` 不浮動。因此 CI 只需檢查後者（見 `cmd/main` 的分工原則）。
