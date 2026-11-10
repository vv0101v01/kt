# `algebra/` — 精確有理／代數計算塔（Exact Rational & Algebraic Algebra Tower）

> **架構位置**：`architecture.json` 中的 `algebra`，**Layer 1**，依賴 `gcd`。
> 聯邦歸屬：F1 `cubical` 的數值／代數後盾（`cubical/hermitian` 的精確證書層、`topos` 的 `ℚ`-上同調、`scheme` 的 Gröbner／Kähler／Serre 對偶全部靠它）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/algebra`。**零浮點**是本套件的中心教條：需要「認證」的數字一律是 `BigInt` 有理數或帶憑證的區間。

---

## 1. 定位：把「浮點近似」換成「可核驗的等式」

`cubical/hermitian/complex.mbt` 用 `Double` 做複矩陣（快速、但有 `eps`）；本套件是它的**精確對偶**：

| 問題 | 浮點做法 | 本套件的精確做法 |
|---|---|---|
| `A·v = λv`？ | 殘差 `< 1e-9` | `QMat` 有理消元 + Jordan 鏈 + 主譜投影子（精確等式） |
| `√2` 的符號 | 近似比較 | `QuadNum`／`MultiQuadNum` 在 `ℚ(√d)` 內的**精確符號判定** |
| 特徵多項式 | 數值 | Berkowitz 無除法 + 多模 CRT（`qmat_charpoly_berkowitz_crt`） |
| 不可約性 | 隨機測試 | Kronecker 插值 + Hensel + LLL/Van Hoeij + 可獨立核驗憑證 |
| `e` 是否無理 | 「應該不是」 | `EIrrCertificate` 級的連分數認證（`transcendental.mbt`） |

---

## 2. 檔案清單（22 檔，約 18.8k 行）

| 層 | 檔案 | 行數 | 職責 |
|---|---|---:|---|
| 標量 | `symalg.mbt` | 1007 | `BigInt` 有理數 `Rat`、多元多項式 `Poly`、符號分式 `SymFrac`、符號複數 `SymC`、`SymVec`/`SymMat`、`UPoly` |
| 標量 | `qpoly.mbt` | 1070 | `QPoly` 單變數有理多項式：除法、gcd/extgcd、導數、Yun 平方自由分解、有理根 |
| 標量 | `qmat.mbt` | 576 | `QVec`/`QMat`/`QRref`：`ℚ` 線性代數（RREF、秩、零空間、行列式、Newton 恆等式特徵多項式、Krylov 最小多項式） |
| 代數數 | `algnum.mbt` | 1165 | `QuadNum`（`a + b√d` 規範二次形）與 `AlgNum`（`ℚ[X]/(m)` 一般代數數）＋`AlgMat`/`AlgVec` 及其 Jordan 理論 |
| 代數數 | `biquad_denest.mbt` | 773 | `ℚ(√d₁, √d₂)` 雙二次體：`ℚ*/ℚ*²` 平方類對齊、精確符號、根式去巢 |
| 代數數 | `tower_fields.mbt` | 1087 | `CubicNum`（純三次 `ℚ(∛m)`）與 `TriquadNum`（三二次體） |
| 代數數 | `multiquad_tower.mbt` | 988 | `MultiQuadNum`：`ℚ(√d₁,…,√d_k)`（`k ≤ 4`，次數 ≤ 16）乘積基底 |
| 代數數 | `hensel_multiquad_deflation.mbt` | 2099 | Cantor–Zassenhaus + 二次 Hensel（`ℤ/p^{2^r}`）+ Landau–Mignotte 重組合；`k ≤ 6`（64 基底槽）多二次塔；`RealAlgRadical` 實代數根式規範形；Jacobi 分塊降維 |
| 代數數 | `splitting_field.mbt` | 703 | `K = ℚ(α)` 上的 `AlgPoly`、Trager 範數法分解、逐步擴張的分裂域 `SplittingField` |
| 代數數 | `radical_denest.mbt` | 477 | 根式去巢：BigInt 完全次方抽取、二次體內立方根的範數／預解式去巢、一般單代數體內的 `n` 次根 |
| 因式分解 | `qpoly_factor.mbt` | 965 | Yun 平方自由 + Kronecker 插值**完整**分解（含 `mod p` 次數模式剪枝） |
| 因式分解 | `qpoly_certificate.mbt` | 394 | 可獨立核驗的不可約性憑證 `QPolyIrreducibilityCertificate` |
| 因式分解 | `lll_van_hoeij_rouche.mbt` | 1215 | `δ = 3/4` 精確有理 LLL、Van Hoeij 冪和跡格重組合、`ComplexAlgNum` 與 Rouché 圓盤 |
| 譜理論 | `Jordan.mbt` | 363 | 廣義特徵空間、Weyr 特徵、Jordan 鏈、主譜投影子 |
| 譜理論 | `spectral_symbolic.mbt` | 621 | 符號譜分解：`RPoly`（形式特徵值為原子）、Lagrange 投影子公式、譜恆等式 |
| 譜理論 | `poly_cube.mbt` | 570 | `n` 維多項式立方體 `PolyCube`／`PolyBoxFace`／`PolyOpenBox`：可檢查的面限制與 Kan 填充 |
| 譜理論 | `root_isolation.mbt` | 1745 | Sturm 序列實根隔離（保重數）＋精確 Newton 於 `ℚ(i)` 的複根圓盤 + Rouché 認證 + Hermitian 特徵值隔離 |
| 譜理論 | `Jacobi_interval.mbt` | 1499 | 有理區間算術（外擴平方根）認證 Hermitian Jacobi 迭代：`RatInterval`→`CInterval`→`QCIntervalMat`→`JacobiCertificate` |
| 超越 | `transcendental.mbt` | 457 | 認證 `e`、`π` 的連分數區間 `CertEnclosure`、`e` 無理憑證、`π` 的有理否證 |
| 超越 | `liouville_schanuel_berkowitz.mbt` | 518 | Liouville 任意次全否證器（`P(L) ≠ 0`）、Schanuel 秩見證、Berkowitz + CRT 特徵多項式 |
| 檢核 | `algebraic_laws.mbt` | 274 | `check_algebraic_extensions_and_Jordan`：代數擴張與 Jordan 理論總開關 |
| 檢核 | `lll_rouche_laws.mbt` | 231 | `check_lll_lattice_and_van_hoeij_factor`、`check_complex_algebraic_closure_rouche` |

---

## 3. 分層架構（由下而上）

```text
                        ┌───────────────────────────────────────────┐
  超越邊界層            │ transcendental.mbt                        │
                        │ liouville_schanuel_berkowitz.mbt          │
                        └───────────────────────────────────────────┘
                        ┌───────────────────────────────────────────┐
  譜／認證層            │ Jacobi_interval.mbt  root_isolation.mbt   │
                        │ spectral_symbolic.mbt Jordan.mbt          │
                        │ poly_cube.mbt (符號 Kan 填充)             │
                        └───────────────────────────────────────────┘
                        ┌───────────────────────────────────────────┐
  因式分解／域擴張      │ qpoly_factor  qpoly_certificate           │
                        │ hensel_multiquad_deflation  splitting_field│
                        │ lll_van_hoeij_rouche  radical_denest      │
                        └───────────────────────────────────────────┘
                        ┌───────────────────────────────────────────┐
  數體層                │ algnum  biquad_denest  tower_fields       │
                        │ multiquad_tower                          │
                        └───────────────────────────────────────────┘
                        ┌───────────────────────────────────────────┐
  基層                  │ symalg (Rat/Poly/SymC/SymMat)  qpoly  qmat │
                        └───────────────────────────────────────────┘
                                   @gcd (FpMat / ZMat / BigInt SNF·CRT)
```

---

## 4. 關鍵機制細讀

### 4.1 `symalg.mbt` — 一切的標量基礎
`Rat` 是 `(BigInt 分子, BigInt 分母)` 且恆常約分；`Poly` 是「合併同類項、去零、字典序排序」的**規範形**多元多項式，因此 `poly_eq` 就是結構相等（O(項數)），不需要展開。`SymC` 是 `SymFrac` 對的複數，`SymMat` 於是支援 `sym_mat_mul`、`sym_det`、`sym_is_hermitian`、`sym_is_idempotent`、`sym_projector_rank_one`、`charpoly_sym` ⇒ **Hermitian 投影子的 `P² = P = P†` 可以在符號層直接判定**，這正是 `cubical/hermitian/certified_*` 的後端。

### 4.2 `qmat.mbt` — 有理線性代數
`qrows_rref` / `qmat_rank` / `qmat_nullspace` 是全倉「精確秩」的唯一入口（`topos` 的 Betti 數、`scheme` 的 Čech 上同調維度、`condensed` 的 `lim` 維度都呼叫它）。`qmat_charpoly` 用 Newton 恆等式（`p_k = tr(A^k)`）搭配冪和，避免行列式展開的 `n!`；`qmat_minimal_polynomial` 用 Krylov 消去子求消去多項式。

### 4.3 數體家族（Denesting 的層層堆疊）
本套件用「乘積基底」表示數體，並用 `ℚ*/ℚ*²` 平方類群做**基底對齊**：

* `QuadNum{a + b√d}` → `BiquadNum` → `TriquadNum` → `MultiQuadNum(k ≤ 4)` → `multiquad_make_upto(k ≤ 6)`；
* 對齊失敗（需要第五／第七個獨立生成元）時**明確拒絕**，不會偷偷降級成近似；
* `radical_denest.mbt` 在此之上做根式化簡：`∛(a + b√d)` 用範數預解式去巢，`alg_nth_root_in_field` 在任意單代數體 `ℚ(α)` 內抽 `n` 次根；
* `real_alg_sign` / `real_alg_nth_root` 提供**實代數數的規範形**與精確符號。

### 4.4 因式分解的三條互補路線
1. **Kronecker 插值**（`qpoly_factor.mbt`）：理論完備但代價由除數枚舉驅動；`qpoly_mod_degree_patterns` 先用 `mod p` 的次數模式把不可能的次數砍掉。
2. **Hensel 提升**（`hensel_multiquad_deflation.mbt`）：`Cantor–Zassenhaus` 等次分解 + 二次 Hensel 到 `ℤ/p^{2^r}` + Landau–Mignotte 子集重組合，並附每因子憑證 `QPolyFactorCertificate`。
3. **LLL / Van Hoeij**（`lll_van_hoeij_rouche.mbt`）：以冪和跡格取代指數級子集搜索；`qmat_lll_reduce` 同時回傳麼模變換 `U`（`det U = ±1`）與 `qmat_is_lll_reduced` 的認證。

三者共用 `qpoly_irreducibility_certificate` 的短證路徑（Eisenstein、模 `p` 不可約、次數模式），可用 `qpoly_irreducible_certified` 任選最快的一條。

### 4.5 根隔離與譜認證（`root_isolation.mbt` + `Jacobi_interval.mbt`）
* 實根：Yun 平方自由分解 → 每個因子建 Sturm 序列 → 變號數給出**精確**根數並二分到有理區間；重數原樣保留。
* 複根：`Double` 的 Durand–Kerner **只當搜索啟發式**；候選圓盤必須通過 `ℚ(i)` 上的精確 Newton 收縮 + **Rouché 憑證**才被輸出（`complex_root_isolations_are_certified`）。
* Hermitian：`qmat_symmetric_eigenvalue_isolations` 對稱矩陣、`qcpx_hermitian_eigenvalue_isolations` 複 Hermitian；`Jacobi_interval.mbt` 把旋轉係數換成**有理區間**（含外擴平方根 `rat_sqrt_interval`），逐步證明 `U†AU` 的相似性誤差仍包住零（`jacobi_unitary_residual_contains_zero`），最後 `JacobiCertificate` 給出每個特徵值的包含區間；`jacobi_interval_eigen_cluster_aware` 對重根群做叢集處理。

### 4.6 超越邊界（`transcendental.mbt`、`liouville_schanuel_berkowitz.mbt`）
SPEC 把 `e`、`π` 列為「不在 `ℚ̄` 內」而不處理。這兩檔把「不能表示」和「不能認證」分開：
* `certified_e(k)` / `certified_pi(k)`：回傳有理上下界區間（連分數收斂子），並自我驗證包含性；
* `e_irr_certificate_verify`：`e` 的無理性憑證（連分數分母的成長率），`e_refute_rational(p, q)` 給出否證；
* `liouville_transcendence_certificate`：對 Liouville 常數，對**任意給定次數**的非平凡 `P ∈ ℤ[x]` 證明 `P(L) ≠ 0` ⇒ 超越性認證（不只是 `e ≠ p/q` 的 1 次版）；
* `schanuel_linear_independence_cert`：多二次代數輸入上的 `ℚ`-線性獨立／超越秩見證；
* `qmat_charpoly_berkowitz_crt`：除法自由 Berkowitz 演算法 + `@gcd` 多質數 CRT，避免中間有理數爆炸。

---

## 5. 對外 API（最常用的 12 個）

| 函式 | 用途 |
|---|---|
| `rat_make(num, den)` / `rat_add` / `rat_mul` | `ℚ` 精確標量 |
| `poly_var(i)` / `poly_mul` / `poly_add` | 多元多項式（規範形） |
| `qrows_rref(rows)` / `qmat_rank` / `qmat_nullspace` | `ℚ` 線性代數 |
| `qmat_charpoly` / `qmat_minimal_polynomial` | 特徵／最小多項式 |
| `qmat_Jordan_decomposition` | Jordan 形 + 鏈 |
| `qmat_primary_projector` | 主譜投影子（`cubical` 的 eigenspace 用） |
| `qpoly_factor_complete` | `ℚ` 上完整因式分解 |
| `qpoly_irreducible_certified` | 帶憑證的不可約性 |
| `alg_make` / `alg_mul` / `alg_inv` | 一般代數數 `ℚ[X]/(m)` |
| `multiquad_make_upto(k)` | 多二次塔體（`k ≤ 6`） |
| `jacobi_interval_eigen(A)` | Hermitian 特徵值**區間**認證 |
| `certified_pi(k)` / `certified_e(k)` | 超越數區間認證 |

範例：

```moonbit
// 有理矩陣 → 特徵多項式 → Jordan 形
let a = @exactalg.qmat_from_int_rows([[2, 1], [0, 2]])
let cp = @exactalg.qmat_charpoly(a)                 // (x - 2)^2
let jd = @exactalg.qmat_Jordan_decomposition(a)

// ℚ 上完整分解：x^2 - 1 = (x-1)(x+1)
let x = @exactalg.qpoly_x()
let f = @exactalg.qpoly_sub(@exactalg.qpoly_mul(x, x), @exactalg.qpoly_int(1))
let fac = @exactalg.qpoly_factor_complete(f)
```

---

## 6. 依賴與被依賴

* **分層拆分（`L1 algebra/core` ＋ `L2 algebra`）**：
  * `algebra/core`（`pkgL=L1`，依賴 `gcd` 與 `accel-swar`）：承載 `Rat`、`Poly`、`QPoly`、`QMat`（含 `Int64` 快徑、Ozaki-II `INT8 DP4A` 多素數 CRT 矩陣乘 `qmat_mul_ozaki2_crt` 與無分數 Bareiss `O(n^3)` 行列式 `qmat_det`）及 `bigint_sqrt_{floor,exact}`。
  * `algebra`（`pkgL=L2`，依賴 `gcd` 與 `algebra-core`）：透過 `reexport_core.mbt`（`pub using @acore`）100% 向後相容重導出全體核心 API，並實作代數數擴張、Jordan 標準形、Rouché 複根隔離、LLL／Van Hoeij 因式分解與 Liouville／Berkowitz–CRT 超越認證。
* **被依賴**：`topos`、`condensed`、`conjecture`、`accel`、`cubical-homotopy` 直接依賴輕量 `algebra/core`；`cubical-hermitian`、`scheme`、`bridge`、`root` 依賴完整 `algebra`。

---

## 7. 驗證

```bash
moon check --deny-warn --target wasm-gc
```
四個總開關（正式模組的一等函式，非測試檔）：
`check_algebraic_extensions_and_Jordan()`、`check_lll_lattice_and_van_hoeij_factor()`、`check_complex_algebraic_closure_rouche()`、`check_phase21_transcendence_and_crt_charpoly()`。
