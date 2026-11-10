# `semiring/` — 冪等／星閉／熱帶半環代數，與「型別即定理」的演算法庫

> **架構位置**：`architecture.json` 中的 **F3 第三聯邦**，共 **16 個子套件**，Layer 1–4。
> 執行入口：`cmd/semiringreport`（native-only 量測報告產生器，約 66 秒，屬**慢閘門**，永不進快速／預設閘門）。
> 母套件名：`vv0101v01/cubical-hermitian/semiring/*`。

---

## 1. 這個聯邦的設計哲學

> **能在編譯期表達的前提，就不要放到執行期檢查。**

`semiring/algebra/semiring.mbt` 只放「結構 + 定律」（trait），不含任何演算法。所有上層演算法都以此為**約束（constraint）**，於是「這一招在某半環上是錯的」會變成**型別錯誤**，而不是文件裡的一句話：

| trait | 數學內容 | 被它擋下的錯誤 |
|---|---|---|
| `Semiring` | `(⊕, ⊗, 0, 1)` + 分配律 | — |
| `IdempotentSemiring` | `a ⊕ a = a` | 非冪等半環硬塞進**原地** Floyd–Warshall（`star.mbt` 定理 A） |
| `TropicalSemiring` | 選擇性、有自然序 | 熱帶專屬剪枝（`∞` 直接跳過） |
| `StarSemiring` | Kleene 星 `a*` | 沒有星就呼叫閉包 |
| `OrderedSemiring` | `meet` / `top` | 缺乏格結構就做格序推導 |
| `GroupElement` | 元素在有限子群內（`order_bound`） | 用 `O(m)` 展開算 `a*`（`group_star.mbt` 改 `O(log m)`） |
| `Monoid` / `IdempotentMonoid` / `GroupMonoid` | 么半群 / 冪等 / 群 | Sparse Table 誤用於非冪等、Fenwick 誤用於無逆元（`monoid.mbt`） |

再上一層是一組**互相驗證**的實作：同一個答案用兩三條路徑算，逐格比對才算「相信」（`app/portfolio.mbt` 的 N-version programming）。

---

## 2. 子套件總覽（16 個）

| # | 子套件 | Layer | 依賴 | 一行職責 |
|---|---|---|---:|---|
| 1 | `algebra/` | 1 | — | 半環 trait 階層、定律檢查器、熱帶／瓶頸／計數／機率實例、Pareto 與循環群格序半環、SplitMix64 |
| 2 | `nf/` | 1 | — | 正規形：Kleene 代數 ACI + Brzozowski 導數、最小 DFA（Myhill–Nerode）、自由冪等半環多項式正規形 |
| 3 | `sim/` | 1 | — | 量測模型：單調時鐘、兩層 set-associative LRU 快取模擬器、存取探針 |
| 4 | `par/` | 1 | — | 可移植平行接縫：`par_for` 唯一後端原語、確定性 `par_map_chunks`、`par_scan`、分片 I/O |
| 5 | `ratelimit/` | 1 | — | GCRA 限流 + 有界鍵表 + 階層（租戶）組合 |
| 6 | `matrix/` | 2 | algebra, par | 稠密 `Mat`/`Ops`/`Probe`、三種迴圈順序 GEMM、CSR 稀疏運算、Kleene 閉包、快取預算自動分塊、列區塊平行 |
| 7 | `monoid/` | 2 | algebra | SegTree / SparseTable / Fenwick 三種聚合結構（型別約束各異） |
| 8 | `trop/` | 2 | algebra | 熱帶幾何：單變數多項式與熱帶根、雙變數牛頓多邊形與正則細分、熱帶行列式 = 最佳指派 |
| 9 | `bp/` | 2 | algebra | 因子圖上的半環信念傳播（廣義分配律 GDL） |
| 10 | `io/` | 2 | algebra | 邊表剖析：單趟位元組掃描 vs 字串分割；合成圖輸入 |
| 11 | `graph/` | 3 | algebra, matrix | 加權有向 CSR 圖、傳遞閉包三層級、Dijkstra、多目標 Pareto 最短路 |
| 12 | `spline/` | 3 | monoid | B-spline 空間、帶狀線性求解、週期三次樣條插值 |
| 13 | `cat/` | 3 | algebra, matrix | 範疇化：集合值矩陣、DAG 自由範疇 = `ℕ` 半環 Kleene 星、Maslov 解量化 |
| 14 | `app/` | 3 | algebra, matrix, sim | 代數路徑問題（一份程式五種答案）+ 多實作一致性仲裁 |
| 15 | `par_host/` | 4 | par | **native-only** `moonbitlang/async` 結構化併發後端（與 `par` 同型別、同結果） |
| 16 | `cmd/semiringreport` | 5 | 全部 | native-only 量測報告產生器（§1–§19） |

---

## 3. 逐子套件精讀

### 3.1 `algebra/`（約 2.3k 行）
| 檔案 | 行數 | 內容 |
|---|---:|---|
| `semiring.mbt` | 222 | 上述 10 個 trait；`Ops` 計數器（`⊕`/`⊗` 呼叫次數） |
| `tropical.mbt` | 890 | `Trop`(min,+)、`TropMax`(max,+)、`Bottleneck`、`Counting`、`Prob`、`BoolSr`、`TropF`(Double min-plus) 七個實例；`Trop::star_checked` 回 `Result` 而非默默給錯答案 |
| `lattice_instances.mbt` | 607 | `ParetoSet`（多目標非支配集：`⊕` = 併集後支配剪枝、`⊗` = 閔可夫斯基和後剪枝）、`CyclicSet`（`ℤ_m` 冪集） |
| `laws.mbt` | 371 | `LawReport`：任何新實例都必須通過的定律檢查器，並接受**故意壞掉的實例**做 negative control |
| `group_star.mbt` | 120 | 完全正則半環上的 `a*`：以子群階倍增計算，`O(log m)` 次 `⊗`/`⊕` 取代 `O(m)` |
| `prng.mbt` | 55 | SplitMix64：測試／基準／壓力測試共用固定種子 |

### 3.2 `matrix/`（約 1.8k 行）
* `mat.mbt`：row-major 稠密 `Mat[E]`；元素型別由半環參數決定，同一份程式碼可以是 min-plus、max-min、機率、計數、甚至 Pareto 標籤集。**沒有隱藏配置** —— 所有演算法可傳入 `Ops` 計數器與 `Probe` 存取探針。
* `mul.mbt`：`naive(i,j,k)` / `ikj` / `blocked` 三種迴圈順序 + 熱帶特化 `mul_trop`；三者結果**逐位元相同**，差別只在記憶體存取順序。
* `blocking.mbt`：分塊大小由快取預算**推導**（`choose_block_l1`、`choose_panel_l2`、`choose_tile`），不是硬寫 32。
* `csr.mbt`：`Csr` 稀疏矩陣；`csr_mul`（一般 SpGEMM）、`csr_mul_minplus`（熱帶剪枝）、`csr_sssp`、`csr_apsp`、`csr_closure`。
* `star.mbt`：Kleene 閉包四種實作 —— `closure_fw_inplace`（受 `IdempotentSemiring` 約束）、`closure_lehmann`（`StarSemiring`，正確處理 `d[k][k]*`）、`closure_blocked`（2×2 遞迴分治，工作集隨深度縮小）、`closure_series`；另有 `fw_region` 子區塊與 `mat_equal`/`mat_all` 等輔助。
* `mul_par.mbt`：`mul_rows_par`（每個 task 只寫自己列區塊 ⇒ 無共享寫入）、`closure_fw_par`（每輪先快照第 `k` 列，標準 FW 平行化）。

### 3.3 `graph/`（約 570 行）
* `graph.mbt`：CSR 圖（`offsets`/`to`/`w`）+ 可重現生成器。
* `closure.mbt`：**傳遞閉包三個層級** — (1) 一般 Kleene `O(n³)`；(2) **位元平行 Warshall** `BitClosure` 把 64 個終點壓進 `UInt64` ⇒ `O(n³/64)`（定理 C：算的是**同一個**布林閉包，不是近似）；(3) 功能圖（出度 ≤ 1）`FunctionalDecomp` 分解成「尾巴 + 環」，`O(n)`。另有 `has_negative_cycle`、`apsp_kleene`。
* `dijkstra.mbt`：Gondran–Minoux 定理 —— 選擇性半環 + 非負權下，標籤設定法與 Kleene 閉包結果一致，但 `O(m log n)`；`MinHeap` + `dijkstra` + `apsp_dijkstra`。
* `pareto.mbt`：把 `ParetoSet` 放進鬆弛迴圈（`dist[v] ← dist[v] ⊕ (dist[u] ⊗ w)`），冪等性保證單調收斂。

### 3.4 `trop/`（約 1.3k 行）— 熱帶幾何
* `poly.mbt`：`UniPoly`（係數 `Rat`）、牛頓多邊形、熱帶根 `roots_equal`、`trop_poly_mul`；輸入輸出皆為飽和 I32（`sat_add_i32`/`sat_mul_i32`），溢位不會變成錯答案。
* `newton.mbt`：雙變數熱帶多項式 `BPoly`；把支撐集抬升取**下凸包**再投影 ⇒ 正則細分 `Plane`/`Face`/`DualEdge`，即「熱帶幾何基本定理」的可執行版；`balancing_residuals` 驗平衡條件。
* `tla.mbt`：`trop_det`（`min_σ Σ A[i][σ(i)]`）以匈牙利演算法 `O(n³)` 計算，並與 `trop_det_bruteforce`（`O(n!)`）、`trop_det_dp` 三方交叉；`trop_det_tie_count` 抓「最佳指派不唯一」。

### 3.5 `nf/`（865 行）— 規範形式
1. `regex.mbt`：ACI 正規形（`RSum` 攤平 + 排序去重、`RProd` 用 0/1 吸收律）+ **Brzozowski 導數** `deriv` 與可空判定 `nullable`。
2. `dfa.mbt`：`dfa_of_regex` → `dfa_minimize` → `dfa_canonical`（BFS 首次到達順序編號 + 固定符號序）⇒ **逐位元可比對的字串**；`dfa_equiv`/`regex_equiv` 於是只要比字串。
3. `sexpr.mbt`：自由冪等半環的等式判定：`normalize` 給多項式正規形，並以兩條獨立路徑驗證（`idempotent_identity_holds` vs `_via_dfa`）。

### 3.6 `monoid/`（467 行）
`SegTree`（任意么半群，`O(log n)` 查／改）、`SparseTable`（**冪等**么半群，`O(1)` 查、`O(n log n)` 建）、`Fenwick`（**群**，`O(n)` 建、`O(log n)` 前綴與區間）；附 `SumI64`/`MaxI64`/`AffineM`/`OppositeM` 實例。

### 3.7 `cat/`（約 550 行）— 範疇化三條路線
* `setmat.mbt`：數字 `a ↦ 集合 A`、`+ ↦ ⊔`、`× ↦ ×`；`decategorify` 取基數還原。
* `free.mbt`：有向圖生成的**自由範疇** = `ℕ` 半環上的 Kleene 星（物件 = 頂點、態射 = 路徑）。
* `dequant.mbt`：**Maslov 解量化** `a ↦ e^{−A/h}`，數值驗證「熱帶代數 = 普通代數的 `h → 0` 極限」，並量出下溢邊界。

### 3.8 `app/`、`bp/`、`spline/`、`io/`、`sim/`、`par/`、`ratelimit/`
* `app/closed.mbt`：**同一份閉包程式 `C = A* = I ⊕ A ⊕ A² ⊕ …`** 在五種半環上就是五種經典演算法：`app_bool`（`reach_bfs`，可達性）、`app_minplus`（`shortest_fw`）、`app_widest`（`widest_fw`）等。
* `app/portfolio.mbt`：`consensus_trop` 對同一問題跑 `k` 個獨立實作、逐格比對，全一致才「相信」（N-version programming）。
* `bp/factor.mbt`：`Factor`/`FactorGraph`/`BpResult`；用 Aji–McEliece 廣義分配律做局部邊緣化，並以 `brute_force_sum_product` 為獨立對照；`decode_assign` 取最大後驗指派。
* `spline/spline.mbt`：`bspline_basis`（局部支撐 ⇒ 配點矩陣帶狀）、`Banded` 求解器、`cubic_pole`（週期三次樣條的追趕法）、`interp_cubic_periodic/banded/open`。
* `io/loader.mbt`：`parse_edges_fast`（單趟位元組掃描、無中間 `String`）vs `parse_edges_naive`（`split` + `parse`），量出常數因子；`synth_edge_list`/`synth_edge_bytes` 產生可重現輸入。
* `sim/cache.mbt`：`Cache`（set-associative LRU）、`MemHierarchy`（L1/L2/DRAM 次數）、`Tracer`（把 `Probe` 序列餵進來）—— 純函式，無 OS、無計時器，結果完全可重現；`sim/clock.mbt` 的 `Timer` 取**重複執行最小值**。
* `par/par.mbt`：`par_for(chunks, f)` 是唯一與後端相關的原語；其上 `par_map_chunks`、`par_scan`（對數深度）、`scan_depth`/`scan_sequential` 對照。
* `par_host/backend_async.mbt`：`supported_targets` 限定 native，以 `moonbitlang/async` 的 task group 實作同一組 `ShardIO`/`par_for`，**結果與序列版逐位元相同**。
* `ratelimit/`：`Gcra` 只維護理論到達時間 TAT（`Int64` 微秒、8 bytes/鍵、`O(1)`、無漂移無背景計時器）；`Limiter` 的判定順序刻意「由便宜到昂貴」：全域閘門（一個整數比較，**在雜湊之前**）→ 租戶 → 鍵；`HierLimiter` 做階層組合。

---

## 4. 量測報告（`cmd/semiringreport`）

`cmd/semiringreport/` 是整個聯邦的可執行論文：**每個數字都來自本次執行的真實計算**。

| 檔案 | 行數 | 節 |
|---|---:|---|
| `main.mbt` | 185 | §1–§9：`section()` 記錄每節耗時；`round_to` 是全報告唯一的格式化實作 |
| `report_extra.mbt` | 590 | §10 稀疏 CSR vs 稠密（SpGEMM、稀疏 Kleene、`n × sssp`）；§11 浮點熱帶；§12 由快取預算自動選分塊；§13 平行後端實測 |
| `report_sections.mbt` | 954 | §1–§9 主體；含 `ReportBroken`（`times(a,b) = a+b+1` 破壞分配律）、`ReportLying`（謊稱冪等）兩個**負面對照**半環 |
| `report_v3.mbt` | 713 | §14 熱帶幾何、§15 規範形式、§16 範疇化、§17 演算法組合、§18 連帶相信（BP） |
| `report_v4.mbt` | 357 | **§19 誠實的限制**：19a 訊息傳遞 vs 暴力的交叉點、19b Maslov 解量化下溢邊界、19c `O(m⁴)` 細分的實測成長、19d「可信度的價格」、19e 只有一個候選時錯誤**不會被發現**、19f 限制總表 |

```bash
moon run --release cmd/semiringreport --target native    # ≈66 秒（慢閘門）
```

---

## 5. 使用範例

```moonbit
// 熱帶最短路（同一份程式，不同半環 = 不同演算法）
let flat : Array[@alg.Trop] = [ ... ]              // 9 個元素，row-major
let a = @mat.Mat::from_flat(3, 3, flat)            // Mat[E]::new / zero / identity / from_flat
let d  = @mat.closure_lehmann(a)                   // 一般（StarSemiring，含 d[k][k]*）
let d2 = @mat.closure_fw_inplace(a)                // IdempotentSemiring 限定的原地 FW
let d3 = @mat.closure_blocked(a)                   // 2×2 分塊遞迴（Lehmann）

// 規範形：兩個正則表達式是否同語言
assert_true(@nf.regex_equiv(r1, r2))               // 走最小 DFA 正規形比字串

// 半環定律體檢（含負面對照）
let rep = @alg.check_star_idem("Trop", fn() { gen_trop() }, samples=64)
println(rep.ok(), rep.summary())                   // LawReport::ok / summary
```

---

## 6. 依賴與邊界

* **內部 DAG**：`algebra`/`nf`/`sim`/`par`/`ratelimit`（L1）→ `matrix`/`monoid`/`trop`/`bp`/`io`（L2）→ `graph`/`spline`/`cat`/`app`（L3）→ `par_host`（L4）→ `cmd/semiringreport`（L5）。
* **對外**：本聯邦**不依賴** `symlib`、`gcd`、`cubical`（保持正交）；`semiring-trop` 被 `condensed`、`conjecture`、`accel`、`bridge` 匯入，交會點一律在 `bridge/*`（例如 `bridge/graph_symmetry.mbt`、`bridge/tropical_bridge.mbt`）。
* **禁止**：任何層反向匯入 `par_host`（native-only）或 `cmd-*`。

---

## 7. `T2` 硬體 `@swar` 與多項式時間升級與驗證

- `semiring/matrix`：`mul_bool_swar`（Four-Russians `k=8` 64-bit OR）、`mul_gf2_m4ri_swar`、`closure_bool_swar`、`closure_trop_swar`（串接 `L0 @swar`）。
- `semiring/trop`：`BPoly::subdivision` 3D 脊邊禮品包裝 BFS `O(n log n + n·#Faces)`、`trop_eigenvalue_karp`＋`trop_critical_eigenvector`。
- `semiring/graph`：`bellman_ford_potentials`＋`apsp_johnson`（支援負權邊 `O(nm log n)`）；`semiring/bp`：有環精確變數消去 `bp_exact_all_marginals_ve`；`semiring/nf`：64-bit 結構雜湊 `dfa_of_regex` 與 Valmari–Hopcroft `O(|Σ||Q|log|Q|)` `dfa_minimize`；`semiring/app`：`verify_semiring_wasm_suite()`。

```bash
moon check --deny-warn --target wasm-gc
python3 tools/arch_check.py                     # 分層與匯入白名單
```
