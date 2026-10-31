> **合併後位置**：本文由 algorithm01（`6a208f4`）原 README 遷移而來。
> 套件現位於 `semiring/<name>`，例如文中 `algebra/` 指
> `semiring/algebra/`，套件路徑為
> `vv0101v01/cubical-hermitian/semiring/algebra`。這與 cubical 的精確
> `algebra/` 是兩個不同套件。文中的 monoid 一律譯作**么半群**；
> symlib 的 monad 則譯作**單子／單子函子**。

# semiring-lab — 結構互動推導出的演算法庫（MoonBit）

以**冪等半環、完全正則半環、熱帶半環、格序半環、么半群（monoid）、樣條空間**六個結構為起點，
再加上四個把結構「推到另一個層次」的機制——**熱帶幾何（幾何側）、規範形式（可判定側）、
範疇化（解範疇化的另一側）、廣義分配律（消去側）**——把結構之間的互動推導成可執行的演算法，
並對複雜度、記憶體讀寫次數、載入時間做**實測**。

- 語言／工具鏈：MoonBit `moon 0.1.20261021`、`moonc v0.10.17`（+ `moonbitlang/async 0.22.5`）
- 套件：**15 個程式庫**（含 native 平台擴充 `par_host`）+ `examples` + 報告產生器
- 測試：**native 158 / js·wasm·wasm-gc 各 154，全部通過**（差的 4 個是 native-only 的主機後端測試）
- 編譯警告：**四個後端全部 0**（`moon check --target native|js|wasm-gc|wasm`）
- 每個數字都由 `moon run cmd/semiringreport --target native` 現場量測（見 [`REPORT.md`](REPORT.md)，19 節）

```
$ export PATH="$HOME/.moon/bin:$PATH"
$ moon test --target native semiring/algebra semiring/app semiring/bp semiring/cat semiring/examples semiring/graph semiring/io semiring/matrix semiring/monoid semiring/nf semiring/par semiring/par_host semiring/ratelimit semiring/sim semiring/spline semiring/trop  # 158/158
$ moon run cmd/semiringreport --target native > /tmp/REPORT.md  # 慢閘門；本機重跑約 68 s，docs 快照另加來源橫幅
```

---

## 1. 為什麼是「結構互動」而不是「一堆資料結構」

這些結構不是並排展示的，而是**互相作為對方的係數、索引或步進器**：

```
            ┌──────────────────────────────────────────────────┐
            │  半環 (S, ⊕, ⊗)                                  │
            │   ├─ 冪等  ──► 自然序、原地 Kleene 迭代合法       │──► 矩陣閉包（稠密）
            │   ├─ 星閉  ──► x* = 1 ⊕ x·x*                      │
            │   ├─ 完全正則 ──► 子群逆 ⇒ star = O(log m)        │──► 循環群、矩陣星
            │   ├─ 格序  ──► join/meet ⇒ 多目標支配關係          │──► Pareto 最短路
            │   └─ 熱帶 (min,+) ──► 最短／最寬路徑               │──► 圖演算法
            │        ├─ Int32 版 `Trop`   （精確代數）           │
            │        └─ Double 版 `TropF` （僅在 ULP 內封閉）    │
            └───────────────┬──────────────────────────────────┘
                            │ 係數環
                 ┌──────────▼───────────┐        ┌──────────────────────┐
                 │  矩陣 Mat[S]  (稠密)  │◄──────►│  圖（CSR）           │
                 │  Csr[S]  (稀疏)       │        │  ├ Dijkstra          │
                 │  ├ SpGEMM (SPA 累加) │        │  ├ 位元並行閉包       │
                 │  ├ 稀疏 Kleene 消去   │        │  ├ 功能圖 O(n) 分解   │
                 │  └ n × sssp           │        │  └ Pareto 標籤        │
                 └──────────┬───────────┘        └──────────────────────┘
                            │ 分塊大小由 L1/L2 預算推導（不寫死常數）
                 ┌──────────▼───────────┐
                 │  平行後端（par/）     │  列區塊任務 / 對數深度掃描
                 │  par_for = 唯一接縫   │  native: async task group
                 └──────────────────────┘  其他: 序列

   么半群 (M, ⊗, e) ──► segment tree（任意 M）、sparse table（冪等 M）、Fenwick（群 M）
                    └──► 前綴掃描 ──► 樣條的兩段一階遞推（仿射么半群）
   樣條空間 ──► 配點矩陣是循環矩陣 ⇒ 極點分解 ⇒ 兩個 IIR 遞推 ⇒ O(n)

   ── 四個「把結構推到另一層」的機制 ─────────────────────────────────────
   熱帶幾何 (trop/)   半環 (min,+) ──► 值域 = 多面體 ──► 牛頓多邊形 / 正則細分 / 對偶曲線
                      └─ 平衡條件 Σ w·ν = 0 是**整數恆等式**，可直接驗證
                      └─ 熱帶行列式 = 最佳指派的 min-plus 版本 = 匈牙利演算法
   規範形式 (nf/)     半環等式 ──► 自由冪等半環 ⇒ 有限語言 ⇒ 最小 DFA
                      └─ Brzozowski 導數（ACI 正規形）+ Moore 細化 + 樸素字串比較三路互照
   範疇化 (cat/)      矩陣 ──► 集合值矩陣（保留見證）──► 基數／Maslov 解量化回純量
                      └─ 自由範疇 = ℕ 半環的 Kleene 星；span 的合成 = 拉回 = 範疇化矩陣乘
   廣義分配律 (app/bp) A* 只有一份程式 ──► 換半環就換演算法（5 個實例逐格對照）
                      └─ 因子圖：⊕/⊗ 的交換律 + 分配律 ⇒ 訊息傳遞；樹上精確、有環近似
```

每條箭頭都對應一個定理與一段可執行程式；推導寫在 [`DESIGN.md`](DESIGN.md)。

## 2. 專案結構

| 套件 | 內容 | 關鍵想法 |
|---|---|---|
| `algebra/` | `Semiring` / `IdempotentSemiring` / `StarSemiring` / `OrderedSemiring` / `TropicalSemiring` / `GroupElement` / `Monoid` 等特徵；熱帶（Int32 + **Double**）、瓶頸、布林、計數、機率、Pareto、循環群七個實例；定律檢查器；SplitMix64 | 定律是**可執行的**；浮點實例用近似檢查 + 負面對照 |
| `matrix/` | 三種迴圈順序的通用乘法、熱帶剪枝乘、原地 Warshall、Lehmann、分塊遞迴閉包、級數逼近、**CSR 稀疏路徑**（SpGEMM / 稀疏消去 / n×sssp）、**由快取預算推出分塊大小**、**列區塊平行** | 「冪等」寫進型別 ⇒ 非冪等半環編譯期就被擋在原地演算法之外 |
| `monoid/` | `SegTree`、`SparseTable`（要求冪等）、`Fenwick`（要求群）、Hillis–Steele 前綴掃描、仿射么半群、反么半群 | 三種聚合結構對應三種代數強度 |
| `graph/` | CSR 圖、Dijkstra、全源最短路、位元平行 Warshall、功能圖分解、Pareto 最短路 | 位元並行把 O(n³) 壓成 O(n³/64)；功能圖用完全正則性換到 O(n) |
| `spline/` | 均勻三次 B 樣條、de Boor、稠密／帶狀／遞迴三種配點解法、極點與增益 | 循環矩陣 ⇒ 極點分解 ⇒ O(n) 遞推 |
| `ratelimit/` | GCRA、有界鍵表、全域閘門、階層（租戶）限流 | 單點狂按 vs 多點齊發兩種攻擊面；preview/commit 避免額度被幽靈消耗 |
| `io/` | 單趟位元組掃描的邊列表載入器 + 字串分割對照組 | 冷啟動延遲：8.3× 的載入加速 |
| `sim/` | 兩層 set-associative LRU 快取模擬器、存取探針、單調時鐘 | 讓「記憶體讀寫次數」變成可量測、可否證的數字 |
| `par/` | 平行後端接縫（`par_for`）、分段 map、確定性歸約、對數深度掃描（序列實作，四個 target 都可編譯） | 演算法只依賴一個 primitive；換後端不改演算法 |
| `par_host/` | native 平台擴充：`moonbitlang/async` 的結構化併發與真實檔案 I/O 重疊量測 | 用 `supported_targets` 隔離，讓 `par/` 在 js/wasm 上零警告；兩邊共用同一個 `ShardIO` 型別 |
| `examples/` | README 用法片段的**可編譯**版本 | 文件與 API 不會漂移（`moon check` 驗證） |
| `trop/` | **熱帶幾何**：單變數熱帶根（下凸包）、min-plus 卷積、雙變數牛頓多邊形、抬升 + 下凸包的正則細分、對偶熱帶曲線、平衡條件檢查、熱帶行列式（匈牙利 / 子集 DP / 暴力三路對照） | 幾何側的每個宣稱都是**整數恆等式**：細分面積 = 牛頓多邊形面積，Σ w·ν = 0 |
| `nf/` | **規範形式**：正規表示式的 ACI 正規形、Brzozowski 導數、最小 DFA（Moore 細化）、canonical 字串、半環等式判定的多項式正規形 | 「相等」變成「正規形字串相同」，而且有兩條互不相依的判定路徑互相對照 |
| `cat/` | **範疇化**：集合值矩陣（見證保留）、基數同態、圖的自由範疇（= ℕ 上 Kleene 星，四條獨立算法）、Maslov 解量化（穩定的 log-sum-exp 版 + 樸素版對照） | 「解範疇化」有兩種：取基數（集合→數）與 h→0（普通→熱帶），兩者都寫成誤差曲線 |
| `app/` | **代數路徑問題**：一份 `app_closure` 跑五個半環（Bool/Trop/Bottleneck/Counting/Prob）；**演算法組合仲裁**（5 個獨立實作 + 注入錯誤候選的負面對照） | 同一個 A* 在五個半環上分別是 BFS / Floyd–Warshall / 最寬路徑 / 路徑計數 / 機率總和 |
| `bp/` | **連帶相信**：因子圖、廣義分配律的訊息傳遞（`Prob` = sum-product、`TropMax` = max-product）、q^n 暴力對照、樹/有環判定 | 樹上精確、有環近似——差多少如實印出來，不假裝精確 |
| `cmd/semiringreport/` | 19 節量測報告產生器 | 每一節都附交叉驗證 |

## 3. 主要量測結果（節錄自 `REPORT.md` 的一次實測）

> 計數類（op 數、cache miss、放行數、nnz）是確定性的；時間類會隨機器與排程浮動（同一台機器上 10–40% 的變動都出現過）。
> 下表取自 [`REPORT.md`](REPORT.md) 現存的那一次執行，與報告逐項對齊。

| 項目 | 結果 |
|---|---|
| 定律驗證 | 7 個半環實例 × 512–960 次檢查全過；3 個負面對照全部被抓出；`TropF` 精確檢查**必須失敗**、近似檢查通過 |
| min-plus 乘法 n=384 | naive 1.74e6 µs → ikj 1.24e6（1.41×）→ 熱帶剪枝 5.36e5 µs（**3.25×**），⊗ 次數 56.6M → 20.2M（2.8× 少） |
| 快取（n=192, L1 32 KiB / L2 512 KiB，皆 8-way） | naive 7,225,188 miss → ikj 446,976（**16×**）→ 32×32 分塊 29,952（再 15×） |
| 閉包（n=256） | 原地 / Lehmann / 分塊遞迴三者逐位元相同（347 / 373 / 285 ms）；op 數 99.2M / 98.9M / 100.6M |
| 非冪等反例（n=8） | 路徑計數：暴力 3、Lehmann 3、硬塞原地 Warshall **60** |
| 圖（n=320, m=3103） | Kleene 4.38e5 µs、n×Dijkstra 1.33e5 µs、位元閉包 1.01e3 µs（**435×**） |
| 功能圖（n=20000） | 結構分解 O(n) ≈ 1.96e3 µs；位元閉包在 n=600 就要 4.1e2 µs |
| **CSR SpGEMM（n=128, degree=4）** | 稠密剪枝 477 µs → CSR 268 µs（**1.78×**），⊗ 次數相同（純記憶體差距） |
| **CSR 稀疏 APSP（樹，n=512）** | 稠密 FW 11.3 ms → n×sssp 3.54 ms（**3.2×**）；稀疏消去反而慢 3.6×（負面結果，見 §10） |
| **浮點 min-plus（n=160）** | 泛型 1.23e7 ⊗ → 剪枝 3.76e6 ⊗（**3.27×**），逐位元相同；浮點 APSP vs 稠密 FW 誤差 1.4e-14 |
| **自動分塊（n=192）** | 由 L1 預算得 b=48，L1 miss 為追蹤器最優值的 **1.19×**；b=8 是最優值的 3×、b≥n 是 12–15× |
| 樣條（n=1024） | 稠密 9.08e4 µs → 遞迴 **28.3 µs**（3211×），殘差 ≈ 7e-16 |
| 限流 | 單點狂按 20 萬次 → 放行 620（上限 2020）；多點齊發 5 萬鍵 → 雜湊前丟棄 49,900 |
| 載入（20,000 邊 / 236 KB） | 位元組掃描 3.99e3 µs vs 字串分割 2.90e4 µs（**7.27×**） |
| 聚合（n=131072, 20k 查詢） | segment tree 778 ns/查詢、sparse table 110 ns、Fenwick 546 ns；線性掃描 201 µs/查詢 ⇒ **51.7×** |
| **平行：CPU 密集** | 同一內核 chunks=1/4/16/64 → 1.00/1.01/1.00/0.99×（**沒有加速**，原因見 §13） |
| **平行：I/O** | 12 個 shard 循序讀 → 併發讀 **1.32×**；端到端 1.03×（解析是序列 CPU，攤薄了收益） |
| **BP 的真實交叉點** | n=4…8 訊息傳遞**輸**給暴力（n=4：396 vs 48 次乘法）；**n=9 才轉正**，n=16 時 115.5× |
| **熱帶幾何（2 變數、6 支撐點）** | 5 個面 / 10 條細分邊（5 有界 + 5 射線）；細分面積 = 牛頓面積 = 10/2；對偶性 5/5 通過；**平衡殘差全部為 0**；20000 個隨機方向的打平全部落面內 |
| **熱帶根（乘法定理）** | 200/200 組隨機多項式滿足 roots(f⊗g) = roots(f) ⊔ roots(g)（共 1000 個根）；求根 1.35 µs |
| **熱帶行列式** | n=11：匈牙利 25.3 µs vs 子集 DP 564.9 µs；n=7 時 O(n!) 暴力 820.8 µs 只為對照；三者一致 |
| **規範形式** | (a* b*)* 的導數 DFA 4 狀態 → 最小 2 狀態；(a+b)* (a+b)* 3→2；300 組隨機表示式兩條判定路徑 **100% 一致** |
| **自由範疇** | n=7、31 條路徑：列舉 15.8 µs、拓撲 DP 4.4 µs、矩陣冪級數 81.4 µs、Lehmann 5.4 µs，四條路徑逐格相同 |
| **解量化** | h=1 誤差 0.69 → h=0.1 6.7e-4 → h≤0.01 落至機器精度；樸素版在 h=0.001 就 `ln 0` 下溢 |
| **APP（n=8）** | 同一個閉包在 Bool/Trop/Bottleneck 上與 BFS / FW / max-min FW 逐格相同 |
| **演算法組合（n=40）** | 5 個候選全部一致；最快 596 µs、總成本 70,592 µs（**可信度的價格 118×**）；注入錯候選 ⇒ 一致 = false |

## 4. 用法

### 4.1 熱帶半環做最短路（整數與浮點同一份內核）

```moonbit
using @alg { type Trop, type TropF }
using @graph { type Graph, apsp_dijkstra, apsp_kleene }
using @mat { type Mat, mul_trop_generic }

let g = Graph::random(@alg.Rng::new(42UL), 200, 5, 30)
let dist = apsp_dijkstra(g)                    // Mat[Trop]，O(n·m log n)
let (d2, has_neg) = apsp_kleene(g)             // Kleene 閉包，任何封閉半環
println(dist.d[0 * 200 + 7].value())           // 0 → 7 的最短距離（Int）

// 浮點權重：同一個剪枝內核，元素型別換成 Double
let a = Mat::new(64, 64, TropF::inf())
let b = Mat::new(64, 64, TropF::inf())
let c = mul_trop_generic(a, b)                 // 剪枝、Double 加權，逐位元等於未剪枝版
```

### 4.2 CSR 稀疏路徑：單源、SpGEMM、閉包

```moonbit
using @mat { type Csr, csr_sssp, csr_apsp, csr_mul_minplus, csr_closure }

let g = Csr::from_triplets(n, n, from, to, weights)   // 重複邊以 ⊕ 合併
let (dist, neg) = csr_sssp(g, 0)                      // Θ(m log n)
let all = csr_apsp(g)                                 // n × sssp
let sq = csr_mul_minplus(g, g)                        // SpGEMM（SPA 累加器）
let (closed, neg2) = csr_closure(g)                   // 稀疏 Kleene 消去
```

### 4.3 分塊大小：由快取預算推導

```moonbit
using @mat {
  mul_blocked, closure_blocked, closure_blocked_auto,
  choose_block_l1, choose_panel_l2, default_l1_bytes, default_l2_bytes,
}

let closed = closure_blocked_auto(edges)                    // 門檻自動選定
let b = choose_block_l1(default_l1_bytes, 4, n)             // 4 bytes 元素 ⇒ 48
let panel = choose_panel_l2(default_l2_bytes, 4, n)         // L2 面板 ⇒ 176
```

### 4.4 平行層：只依賴一個 primitive

```moonbit
using @par { par_map_chunks, par_sum, par_scan, backend }
using @mat { mul_rows_par, closure_fw_par }

let c = mul_rows_par(a, b, 8)        // 8 個列區塊任務，結果與 mul_ikj 逐位元相同
let d = closure_fw_par(edges, 8)     // 每輪快照第 k 列後，所有 i 獨立更新
let s = par_sum(1_000_000, 4096, fn(i) { i.to_int64() })   // 固定順序的確定性歸約
println(backend())                   // "async(single-thread, structured)" 或 "serial"
```

### 4.5 多目標最短路（格序半環）

```moonbit
using @graph { type Graph, pareto_sssp, total_labels }

let g = Graph::random_two(rng, 40, 25, 20)
let (labels, converged) = pareto_sssp(g, 0)
println(total_labels(labels))   // 互不支配的標籤總數
```

### 4.6 樣條插值：O(n) 遞迴

```moonbit
using @spline { interp_cubic_periodic, interp_cubic_banded, eval_deboor, uniform_knots }

let c = interp_cubic_periodic(y)                  // 週期三次配點，O(n)
let c2 = interp_cubic_banded(y)                   // 開放邊界，O(n·p²)
let v = eval_deboor(c, uniform_knots(3, c.length()), 3, 5.0)
```

### 4.7 區間聚合：三種代數強度對應三種結構

```moonbit
using @mon { type SegTree, type SparseTable, type Fenwick }

let tree = SegTree::build(data)      // 任意么半群，O(log n) 查詢
let sp = SparseTable::build(maxs)    // 需要冪等，O(1) 查詢
let fen = Fenwick::build(sums)       // 需要群（有逆元），O(log n) 查詢
```

### 4.8 限流：單點狂按 + 多點齊發

```moonbit
using @rl { type Limiter, type Decision }

// 每鍵 1000 req/s（burst 20）＋ 全域 50000 req/s（burst 100）＋ 4096 格鍵表
let lim = Limiter::with_gate(1000.0, 20, 50000.0, 100, 4096)
match lim.admit(key, now_us) {
  Allowed => serve()
  Throttled(retry_after_us) => respond_429(retry_after_us)
  Shedded => drop_silently()      // 全域閘門在雜湊前擋掉
}
```

### 4.9 熱帶幾何：根、曲面、熱帶行列式

```moonbit
using @trop { type UniPoly, type BPoly, type BTerm, trop_det }

// 單變數：熱帶根 = 下凸包的斜率（含重數，以有理數精確表示）
let p = UniPoly::new([0, 10, 3, 7, 1, 9, 4])
let roots = p.roots()                 // [-1/4 ×4, -3/2 ×2]

// 雙變數：抬升 → 下凸包 → 正則細分 → 對偶曲線；平衡條件可直接檢查
let f = BPoly::new([BTerm::new(0, 0, 0), BTerm::new(1, 2, 0),
                    BTerm::new(2, 0, 2), BTerm::new(3, 2, 2), BTerm::new(-3, 1, 1)])
let faces = f.subdivision()           // 4 個面（= 熱帶曲線的 4 個頂點）
let edges = f.dual_curve(faces)       // 8 條邊（4 有界 + 4 射線）
// Σ weight·νector = 0，對每個頂點逐項驗證
let residual = @trop.balancing_residuals(edges, faces.length())

// 熱帶行列式 = 最小成本完美匹配
let d = trop_det([[3L, 1L, 4L], [1L, 5L, 9L], [2L, 6L, 5L]])   // 7
```

### 4.10 規範形式：表示式等價 = 最小 DFA 的正規形字串

```moonbit
using @nf { type Regex, type SExpr }

let a = RChar(0)
let b = RChar(1)
let lhs = r_star(r_sum(a, b))                       // (a+b)*
let rhs = r_star(r_prod(r_star(a), r_star(b)))      // (a* b*)*
let same = regex_equiv(lhs, rhs, [0, 1])            // true

// 半環等式判定（自由冪等半環）：多項式正規形
let x = SVar(0)
let y = SVar(1)
let z = SVar(2)
assert_true(idempotent_identity_holds(
  SProd(x, SSum(y, z)), SSum(SProd(x, y), SProd(x, z))))
```

### 4.11 範疇化：自由範疇 = ℕ 半環的 Kleene 星

```moonbit
using @cat { type DiGraph }

let g = DiGraph::new(4)
g.edge(0, 1); g.edge(0, 2); g.edge(1, 3); g.edge(2, 3); g.edge(1, 2)
g.path_counts()            // 拓撲 DP：0→3 有 3 條路徑
g.path_counts_by_closure() // Lehmann 消去：逐格相同（測試斷言）
g.hom_sets()               // 真正的見證：把所有路徑列舉出來
```

### 4.12 一份程式、五種代數 + 連帶相信

```moonbit
using @app { app_bool, app_minplus, app_widest, consensus_trop }
using @bp  { type FactorGraph, marginals_sum_product }

// 同一個 A*：可達性 / 最短路 / 最大瓶頸
let reach = app_bool(4, [(0, 1), (1, 2), (2, 3)])
let dist  = app_minplus(4, [(0, 1, 3), (1, 2, 4), (2, 3, 5)])
let wide  = app_widest(4, [(0, 1, 3), (1, 2, 4), (2, 3, 5)])

// 五個獨立實作同時跑，逐格仲裁；注入錯的候選必須被拒絕
let v = consensus_trop(mat, 1, inject_wrong=true)
assert_false(v.agree)

// GDL：樹上訊息傳遞 = 精確邊緣
let (marginal, ops) = marginals_sum_product(factor_graph)
```

---

## 5. 設計原則（也是 review 檢查清單）

1. **型別即前提**：`IdempotentSemiring` 才能原地 Warshall；`IdempotentMonoid` 才能 sparse table；
   `GroupMonoid` 才能 Fenwick；`TropicalSemiring` 才能用剪枝內核。前提違反不是「跑起來剛好對」，而是編譯不過。
2. **不能恆真**：每個定律檢查器都配故意做壞的實例（`BrokenSr`、`LyingIdem`）；
   浮點熱帶半環的**精確**檢查被斷言為 false（IEEE-754 加法不結合），只有近似檢查通過。
3. **每個「更快」都要有第二個實作對照**：三種乘法互照、位元閉包對照 BFS、分解對照位元閉包、
   Dijkstra 對照 Kleene、遞迴樣條對照稠密高斯消去、Lehmann 對照 DFS 列舉、
   CSR SpGEMM 對照稠密剪枝乘、稀疏 APSP 對照稠密 FW、平行版對照序列版。
4. **量測而非估算**：時間取重複最小值；運算量是半環 ⊕/⊗ 的真實呼叫次數；
   記憶體是把**實際存取序列**餵進快取模擬器；資料由固定種子 PRNG 產生 ⇒ 可重現。
5. **負面結果照實寫**：分塊在 wall clock 上沒有優勢卻把 L1 miss 降了 15×；
   稀疏消去在報告 §10 全程輸給稠密 FW（因為閉包變稠密 + 每次更新重建列）；
   Hillis–Steele 掃描慢 49× 但深度是 log n；平行層對 CPU 密集工作**沒有**加速（實測 1.0×）。
6. **不宣稱做不到的事**：平行只接到 MoonBit 目前唯一可用的執行環境（單執行緒協作式），
   因此報告把「I/O 重疊 ×1.32」與「CPU 加速 ×1.00」並列，而不是只挑好看的數字。
7. **同一件事至少兩條互不相依的路徑**（v4 擴充）：熱帶根 ↔ 逐點求值比大小；細分面積 ↔ 牛頓多邊形面積
   （Pick 定理）；對偶曲線 ↔ 平衡殘差；正規形 ↔ 最小 DFA；自由範疇 ↔ 冪級數 ↔ Lehmann ↔ DFS 列舉；
   熱帶行列式 ↔ 匈牙利 ↔ 子集 DP（↔ n! 暴力）；BP ↔ q^n 邊緣枚舉。任一路徑壞掉，報告會出現不一致格。
8. **死碼不留、重複不留**：每個 `pub fn` 至少被呼叫一次（`examples/` 的範例由 `examples_wbtest` 執行並斷言，
   不再只是「編得過」）；格式化只留 `round_to` 一個實作；`unused_package` 用平台套件隔離而不是靠忽略。
9. **近似就標成近似**：`Prob` 故意沒有 `StarSemiring`（星只在譜半徑 < 1 收斂，改用冪級數 + 收斂旗標）；
   BP 在有環的圖上只回傳量到的誤差，不宣稱精確。

## 6. 交叉點：什麼時候用哪一條路徑

| 情境 | 建議 | 依據（實測） |
|---|---|---|
| 稠密圖、n 小、需要所有源 | 稠密 FW / 分塊 FW | n=256：339 / 286 ms，三者逐位元相同 |
| 稀疏圖、閉包也稀疏 | **n × `csr_sssp`** | 樹 n=512：3.54 ms vs 稠密 11.3 ms（3.2×） |
| 稀疏 × 稀疏乘積 | **CSR SpGEMM** | n=128：268 µs vs 稠密剪枝 477 µs（1.78×） |
| 只需可達性 | 位元並行閉包 | n=320：1.01 ms（比 Kleene 快 435×） |
| 要「同一語言的唯一代表」 | 最小 DFA 的 canonical 字串 | 表示式等價判定 = 字串比較 |
| 要「在所有冪等半環上都成立的等式」 | 多項式正規形 | 300/300 與自動機路徑一致 |
| 要熱帶曲面的組合結構 | 抬升 + 下凸包 + 對偶 | 平衡條件是可直接檢查的整數恆等式 |
| 線性代數要「最佳指派」 | 熱帶行列式 = 匈牙利 O(n³) | n=11 比 2ⁿ DP 快 22×、比 n! 快得多 |
| 因子圖是樹 | 訊息傳遞（GDL） | n=16 時比 q^n 少 115× 次乘法 |
| 因子圖有環 | **不要**用 BP 當精確解 | 三角形圖上誤差 8.3e-3（實測） |
| 出度 ≤ 1 | 功能圖結構分解 | n=20000：2.3 ms，O(n) |
| 浮點權重 | `TropF` + 剪枝內核 | 3.27× 少 ⊗，結果逐位元相同 |
| 只需要「裝得下」的磚 | `choose_block_l1` | L1 miss 為追蹤器最優值的 1.19× |
| I/O 佔比高的載入 | 併發讀（`@par_host` I/O 路徑） | 讀取 1.53×；端到端 0.93×（解析是序列 CPU，把它攤平了） |

## 7. 已知限制（含工具鏈層面）

每一條限制在 [`REPORT.md`](REPORT.md) §19 都對應一個**現場量出來的數字**（不是形容詞）：

| 限制 | 量到的數字 |
|---|---|
| BP 只在樹上精確 | 三角形圖誤差 0.0083（§18） |
| BP 不是「小圖也快」 | 交叉點在 **n = 9**；n=4 時 396 vs 48 次乘法 |
| 解量化只是極限 | 樸素版在 h < 0.987（= x_min/709）就 `ln 0` 下溢；穩定版仍在誤差曲線內 |
| 熱帶細分只有上界 O(m⁴) | m = 6…14 的 log-log 實測斜率 2.5 |
| 交叉驗證不便宜 | 全跑 132×、只跑最便宜兩個 2.13× |
| 仲裁抓不到共同錯誤 | 截斷級數單看「合理」，1022/1600 格是錯的 |


- **沒有 CPU 平行**：MoonBit 0.10.17 的 `moonbitlang/async` 是單執行緒協作式（官方 README 明載
  「user code can only utilize one hardware processor」）。`par/` 的結構是為真正執行緒後端準備的；
  目前只有 I/O 重疊有效。第三方 `Milky2018/pthread` 自述「Don't use it in production」，因此不採用。
- **主機後端只在 native 上存在**：`par_host/` 用 `options(supported_targets: "native")` 隔離，
  其他 target 整個跳過這個套件（而不是「編譯後留著未使用的 import」）。這是 0.10.17 唯一能讓
  多 target 模組零警告的做法：`moon.pkg` 的 import 不能按 target 條件化，但整個套件可以。
- `matrix/` 的稠密部分只支援 row-major 平面陣列；稀疏本體是 `Csr[E]`。
- 稀疏 Kleene 消去每次更新都會重建列陣列，常數偏大 ⇒ 在可測範圍內不如稠密 FW；
  改進方向（預留容量 + 免配置合併）已寫在報告 §10，但尚未實作。
- `Trop` 以 `Int` 表示權重（±2³⁰，飽和）；浮點請用 `TropF`（Double，NaN 正規化為 +∞）。
- 分塊模型假設 fill=3/4、磚數 2（L1）與 3（L2）；未做線上 auto-tuning。
- 限流器需要呼叫端提供單調時鐘；本庫不管理計時器執行緒。
- 平行掃描（Hillis–Steele）在單核上比序列慢 49×；它存在的理由是深度 O(log n)，不是當下的效能。
- **BP 只在樹上精確**：有環時是近似（實測三角形圖誤差 8.3e-3），正解需要 junction tree / cutset conditioning；本庫不提供。
- **解量化只是極限**：h→0 在浮點上不可達，我們給的是誤差曲線與下溢邊界（`h < 1/709` 時 `e^(−x/h)` 歸零）。
- **正規形式的能力邊界**：`nf/` 判定的是 Kleene 代數等式與**自由冪等半環**等式；不是所有半環上的等式理論都可判定，星以外的推論（如交換半環）不在此列。
- **熱帶幾何的細分上界是 O(m⁴)**（三點枚舉 + 全點檢查）：m = 6…14 的 log-log 實測斜率只有 2.5（常數項仍顯著）；
  支援點數 m 只到幾十；這不是生產級的凸包程式庫。
- `Prob` 沒有 `StarSemiring` 實例——機率星只在譜半徑 < 1 收斂，因此走「冪級數 + 收斂旗標」，收斂性是可檢查的回傳值而不是假設。

## 8. 授權

Apache-2.0。
