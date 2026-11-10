# `symlib/` — 有限對稱：規範形、Schreier–Sims、群作用、範疇化與米田引理

> **架構位置**：`architecture.json` 中的 `symlib`（**Layer 1**，依賴 `L0 symlib/core` 並透過 `reexport_core.mbt` 100% 重導出），零外部聯邦依賴（`allowed_external_packages: []`）。
> 聯邦歸屬：**F2**（第二聯邦：`symlib/core` + `symlib` + `cmd/symdemo` + `cmd/symbench`，共 **4 套件、30 個 `.mbt`、9,964 行**）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/symlib`。

---

## 1. 一句話定位

`symlib` 是「**同構 = 規範形相等**」與「**對稱 = 群作用**」的可執行版本：一個**個體化—精煉（individualization–refinement）搜索引擎**同時產出規範標號、自同構群、軌道與 Burnside 標記；再往上加三層範疇化（有限範疇、預層與米田引理、Kan 擴張）以及由定理導出的**衍生演算法**（分解積公式、補圖對偶、線圖 Whitney、標記向量）。

特點：**一次搜索，多模組消費**（`report.mbt` 的 `analyze`），且所有定理都以有限情形**逐點計算**成證書（`theorem.mbt` / `theorem_all.mbt`），是「用演算法證明演算法」的 cross-witness 設計。

---

## 2. 檔案清單（26 個 `.mbt`，共 8,768 行）

### 2.1 基礎層（無依賴）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `bitvec.mbt` | 204 | 64 位字組定長位向量 `BitVec`；集合交／併／差／計數全以字組並行，`O(n/64)` |
| `perm.mbt` | 272 | `Perm`（`img[i]` 為 `i` 的像，乘法約定 `a.compose(b)(x) = a(b(x))`）：生成、逆、冪、循環分解、由循環建構 |
| `random.mbt` | 68 | 確定性 LCG（Numerical Recipes 常數）+ Fisher–Yates + `G(n,p)`；同一 seed ⇒ 同一實例，測試與基準可重現 |
| `lut.mbt` | 127 | `KeyLut`：`Int64 → Int32` 開放定址（線性探測）查找表，取代 `Map` 熱路徑的裝箱與指標追逐 |
| `group.mbt` | 545 | `PermGroup`：增量 **Schreier–Sims**、強生成集（SGS）、`Π\|軌道_i\|` 群階、sifting 成員判定、穩定子、元素表 |
| `graph.mbt` | 350 | 簡單無向圖：排序鄰接表（走訪用）+ 鄰接位向量行（`O(1)` 邊查詢、`O(n/64)` 交集） |
| `partition.mbt` | 247 | 有序分割 `Part` 與**等變**精煉（簽名分裂至穩定），`graph_invariant` 提供不變量 |
| `action.mbt` | 329 | `FinAction`：群作用、軌道、軌道大小、不動點、Burnside 計數；`ActionDerive` 推導點／邊／序對作用 |
| `monad.mbt` | 226 | `ListM`（非決定性／冪集）與 `StateM`（狀態線程化）、`OptionM` 失敗傳播；附單子律檢查 |
| `csp.mbt` | 95 | 把 CSP 寫成圖的**極限**（`lim`）求解器；與 `ListM` 回溯互為第二條路徑 |

### 2.2 搜索引擎與不變量

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `search.mbt` | 755 | **核心引擎**：個體化—精煉；簽名 = (顏色, 各顏色類鄰居計數, 已放置前綴的鄰接位遮罩)，候選 = 未放置頂點中簽名最小者（等變 ⇒ 規範性），前綴編碼剪枝；`search_graph` / `_colored` / `_mode` / `_flags` |
| `canon.mbt` | 139 | 規範標號 `canonical_labeling`、規範形 `canonical_form`、`canon_digest`（十六進制指紋）、`isomorphic`（`O(n²/64)`）、`isomorphism`（合成顯式映射）、`colored_canonical_key` |
| `aut.mbt` | 56 | `automorphism_group`、`aut_order`（Schreier–Sims，免列舉）、`aut_generators`、`vertex_orbits`、`edge_orbits`、`automorphism_group_colored` |
| `permset.mbt` | 57 | `PermSet`（**非群**的置換集）之共軛規範形：`n!` 窮舉下取字典序最小編碼 |
| `fold.mbt` | 195 | `OrbitFold`／`FoldedGraph`：軌道折疊 `X → X/G`、商圖邊重數、`fundamental_domain`、`fold_candidates`（搜索空間壓縮因子 `Π\|分支軌道\|`） |

### 2.3 G-集、標記與衍生演算法（「由定理導出算法」）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `gset.mbt` | 477 | `GSetOf{x, imgs}` 表格式 G-集：左正則 `gset_points`、`gset_pairs`、`gset_edges`、自由／餘誘導 `gset_induced`/`gset_coinduced`、`gset_burnside`、Cayley 圖 `cayley_graph` + `cayley_cert`、G-集**單子** `η/μ/自然性` |
| `marks.mbt` | 605 | 子群共軛類 `Sub`、表徵向量 `mark_vector`、**table of marks**（Burnside 環）、`coset_gset`、`gset_isomorphic`（向量比較 `O(類數)`）、Frobenius 互反 |
| `decomp.mbt` | 447 | **衍生演算法 I**：連通分量分解 ⇒ `Aut(G) ≅ Π (Aut(C) ≀ S_m)` 積公式（免全搜索）、`decomp_key` 完全不變量 |
| `dual.mbt` | 267 | **衍生演算法 II**：補圖對偶 `Aut(G) = Aut(Ḡ)`、`enc_λ(Ḡ) = mask ⊕ enc_λ(G)`、雙通道交叉驗證 |
| `line.mbt` | 257 | **衍生演算法 III**：線圖 `L(G)`、`Whitney` 定理判準與例外（`K₃` / `K_{1,3}`），由 `\|Aut(G)\|` 與核階推 `\|Aut(L(G))\|` |

### 2.4 範疇化與米田

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `cat.mbt` | 293 | 範疇化：`FinSet`/`FinMap`（id、複合、單／滿／同構）、冪集單子 `P`（`η`、`μ`、自然性、單子律）、Kleisli 範疇、`Aut` 函子 `σ ↦ φσφ⁻¹` 的函子性 |
| `fincat.mbt` | 518 | `FinCat`（`nobj/nmor/dom/cod/id/comp`）與 `FinDiagram`：`is_category`、`is_functor`、(co)limit 泛性質與基數、`equalizer/pullback/product/coproduct`、內建建構子 `cat_thin/discrete/terminal/arrow/span/cospan/poset/parallel/group` |
| `yoneda.mbt` | 843 | 預層 `Presheaf`（反變，`res[m]`）、米田引理 `yoneda_extend/nats/roundtrip`、`FinFunctor`、comma 範疇 `comma_down/up`、**Kan 擴張** `lan/lan_map/ran/ran_map`、誘導／餘誘導 G-集 |

### 2.5 統一管線與證書

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `report.mbt` | 207 | `SymmetryReport` + `SearchStats`：一次 `search_graph` 餵給 canon／aut／action／fold／cat，並以 `StateM` 累積統計、`ListM` 列舉全部同構 |
| `theorem.mbt` | 644 | `Cert { name, holds, detail }` 與 `all_hold`、`cert_report`、`failed_certs`、`prove_graph`／`prove_pair`、`elements_cert` |
| `theorem_all.mbt` | 545 | `prove_all(cap)`：一次跑完 **20 條跨模組定理證書**（範疇公理、(co)limit 泛性質、米田、Kan = Lan/Ran、Frobenius、單子律、CSP=極限、Cayley、標記矩陣、SGS 元素表、文獻 `\|Aut\|` 值…） |

---

## 3. 核心流程圖

```text
                Graph (adjacency bitset rows)
                          │
                 search.mbt：個體化—精煉
                ┌─────────┴──────────┐
      canonical_labeling      automorphism generators
                │                    │
        canon.canonical_form   group.PermGroup (Schreier–Sims)
        canon.canon_digest           │
                │             ┌──────┴───────┐
        isomorphic / iso     aut.aut_order   action.FinAction
                │             │              │
        decomp（分量積公式）  fold（軌道折疊） ── gset.GSetOf ── marks（表徵向量 / Burnside 環）
        dual（補圖對偶）                                 │
        line（線圖 Whitney）                    cat / fincat / yoneda（範疇化）
```

---

## 4. 幾個值得注意的設計

### 4.1 為什麼「一次搜索」能同時得到規範形與自同構群
精煉階段是**純等變**的（簽名按字典序編號，重標號後只是重新編號），所以候選規則「取簽名最小的未放置頂點」保證了輸出的標號是**規範標號**；而在同一棵搜索樹中，凡走到「等編碼葉」的路徑差本身就是一個自同構 —— 收集這些映射即得生成元，再驗證一次即可。因此 `search_graph` 回傳的 `SearchResult` 同時是規範化與群計算的來源。

### 4.2 群階不用列舉元素
`PermGroup` 以軌道—穩定子鏈 `G = G⁽⁰⁾ ⊵ G⁽¹⁾ ⊵ … ⊵ 1` 儲存 SGS，群階 = `Π_i |軌道_i|`（軌道—穩定子定理），成員判定用 sifting `O(深度 × n)`，穩定子用 Schreier 引理。這是 `Aut(G)` 能對 `n ≈ 10²` 的圖仍可算的原因。

### 4.3 衍生演算法：把定理變成省下搜索
`cmd/symbench/derived.mbt` 的七個基準正是本套件的賣點：

| 基準 | 定理 | 省下的東西 |
|---|---|---|
| A `bench_decomp` | 分量分解積公式 | 免對整圖全搜索 |
| B `bench_line` | Whitney 線圖定理 | 免對 `L(G)` 搜索 |
| C `bench_dual` | 補圖對偶 | 複雜度中性，賣點是**自我驗證** |
| D `bench_marks` | 表徵向量是 G-集的完全不變量 | 免階乘級枚舉判 G-集同構 |
| E `bench_permset` | `PermSet` 規範形可雜湊 | 資料庫級去重 `O(1)`/對 |
| F `bench_fold` | 規範折疊 | 一次搜索取代兩次 |
| G `bench_cayley` | Cayley 定理 | `O(1)` 下界 `\|Aut(Cay(G,S))\| ≥ \|G\|` |

### 4.4 與其他聯邦的接縫
* `bridge/permutation_bridge.mbt`：`Perm` ↔ `cubical` 的 `CMat` 置換矩陣 / 有限宇宙 `Wiring`（`perm_wiring`、`signed_perm_wiring`、`perm_of_wiring`）。
* `bridge/graph_symmetry.mbt`：`symlib` 的著色規範化 + `semiring/graph` 的 CSR 權重 → 加權有向圖的真對稱群與群平均投影子。
* `bridge/tropical_bridge.mbt`：`tropical_optimal_assignments` 用 `Perm` 表達熱帶行列式的最佳指派、對稱共軛封閉性。
* `topos/yoneda` 重用的 `@sym.lan` / `@sym.ran`：`topos` 的 `Lan_{φ^op} ⊣ φ* ⊣ Ran_{φ^op}` 三伴隨**直接委派**給本套件。

---

## 5. 使用範例

```moonbit
// 一次搜索：規範形 + 自同構群 + 軌道
let g = @sym.Graph::cycle(6)
let rep = @sym.analyze(g)                // SymmetryReport（canon / aut / fold / cat 摘要）
println(rep.order)                       // 12 (D6)
println(@sym.canon_digest(g))            // 十六進制指紋，可直接當資料庫鍵
println(@sym.isomorphic(g, @sym.Graph::path(6)))   // false

// Schreier–Sims 群階
let grp = @sym.automorphism_group(g)
println(@sym.PermGroup::order(grp))

// 米田引理 + Kan 擴張
assert_true(@sym.yoneda_roundtrip(p, a, cap))   // η ↦ Nat(h^a, F) ↦ η 往返
let lan = @sym.lan(k, f, cap)                   // 左 Kan 擴張（k : FinFunctor, f : FinDiagram）
```

---

## 6. 依賴／被依賴

* **依賴**：僅 `moonbitlang/core`（`debug`）。
* **被依賴**：`cmd-symdemo`、`cmd-symbench`、`topos`、`condensed`、`conjecture`、`bridge`、`root`（透過 `bridge`）。
* `architecture.json` 允許 `topos` 與 `condensed` 匯入 `symlib`；`semiring` 聯邦**不依賴** symlib（保持正交），兩者只在 `bridge/graph_symmetry.mbt` 交會。

---

## 7. `T1` 雙層架構（`L0 symlib/core` + `L1 symlib`）與驗證

- **`symlib/core`（`pkgL0` 零外部依賴）**：硬體 `popcnt`／`and_popcount` `BitVec`、無度數上限 `PermLut`（`n ≤ 15` 4-bit Nibble SWAR、`n > 15` SplitMix64 + 原像核對）、零配置 Schreier 篩選 `PermGroup`（含 `alternating`、`hyperoctahedral`）、位向量 1-WL `refine_colors` 與 McKay 搜索引擎；`symlib/reexport_core.mbt` 100% 向後相容重導出。
- **`symlib`（`pkgL1`）**：Holt 陪集剪枝任意生成元秩子群共軛類格 `subgroup_classes`（支援 `A₅(60):9`、`B₃(48):33`）、Burnside Möbius 精確軌道分解 `burnside_mobius_solve`，以及非薄／群胚一般米田雙射 `verify_general_yoneda_bijection`。

```bash
moon run cmd/symdemo --target wasm-gc     # 全功能演示（自同構群/作用/折疊/單子/範疇化）
moon check --deny-warn --target wasm-gc   # 零警告檢查
```

公共健康檢查（正式模組函式）：`@sym.prove_all(cap)` 回傳 20 張 `Cert`，用 `cert_report` 印表。
