# `gcd/` — 下 V 頂點 `V₁`：五域泛消元新最大公因數（Universal Elimination-GCD）

> **架構位置**：`architecture.json` 中的 `gcd`，**Layer 0**，零依賴（`depends_on: []`）。
> 它是整個 `kt` 倉庫雙 V 形架構的**下頂點**：`algebra`、`topos`、`scheme`、`condensed`、`tensor`、`cubical/homotopy`、`accel`、`bridge` 全部把「矩陣消元、整數 GCD、正規形」下沉到這裡，禁止各自重寫。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/gcd`。

---

## 1. 這個套件在做什麼

`gcd/` 用**同一個「最大公因數」概念**統一五個看起來不同的數學領域：

| 領域 | 「GCD」的樣子 | 本套件提供的物件 |
|---|---|---|
| 整數環 `ℤ` | `gcd(m, n)`、`lcm(m, n)`、Bézout 係數 | `ugcd_bigint_gcd` / `ugcd_bigint_lcm` / `ugcd_bigint_ext_gcd` |
| 多項式環 `F_p[x]` | 多生成元 Bézout 主理想 `⟨a, b, …⟩` | 由 `algebra/` 在同介面上使用；核心消元基礎在本套件 |
| 有限體 `F_p` 子空間 | `dim(U ∩ V) + dim(U + V) = dim U + dim V` | `ugcd_grassmann_subspace_duality` |
| `ℤ`-格 | Smith / Hermite 正規形的不變因子鏈 `d₁ \| d₂ \| …` | `zmat_snf` / `zmat_hnf` |
| 商格（canonical normalizer） | meet = 最細共同粗化（GCD）、join = LCM | `ugcd_canon_meet_join_counts` |

一句話：**GCD 是「泛拉回 / 最粗商 meet」**，乘法律 `GCD·LCM = A·B` 的加法版就是 `dim(U∩V) + dim(U+V) = dim U + dim V`。

---

## 2. 檔案清單

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `elim_snf.mbt` | 818 | `F_p` 精確線性代數（RREF、秩、零空間、行列式）＋ `BigInt` 整數矩陣、Smith 正規形 `U·M·V = D`、Hermite 正規形、擴展歐幾里得、CRT 對稱重建、`ℤ`-整數零空間基底 |
| `universal_gcd.mbt` | 378 | 六域泛 GCD 證書 `[T-UnivGCD-SixFold]`、`p`-進賦值、導出 Tor 群階、自由群 `F₂` 字約化、canon 商格 meet/join、Grassmann 對偶、主定律檢查 |
| `moon.pkg` | — | 只有 `moonbitlang/core/debug` 一個外部依賴（幾乎零依賴的基底） |
| `pkg.generated.mbti` | — | 對外介面快照（由 `moon info` 產生） |

---

## 3. 核心資料型別（`elim_snf.mbt`）

```moonbit
pub(all) struct FpMat { rows : Int32; cols : Int32; p : Int32; data : Array[Int32] }
pub(all) struct FpRrefResult { rref : FpMat; rank : Int32; pivots : Array[Int32] }
pub(all) struct ZMat { rows : Int32; cols : Int32; data : Array[BigInt] }
pub(all) struct ZSnfResult { u : ZMat; diag : Array[BigInt]; v : ZMat; rank : Int32 }
```

* `FpMat` 限定 `2 ≤ p ≤ 2_147_483_647`，所有中間乘積先**加寬到 `Int64`** 再取模 ⇒ 不會因溢位得到「悄悄錯」的答案。
* `ZSnfResult` 是**帶憑證**的正規形：`U·M·V = diag(d₁,…,d_r,0,…)`，`U, V` 么模（`±1` 行列式），且 `d₁ | d₂ | … | d_r`，可用 `zmat_snf_verify` 獨立核驗。

---

## 4. 逐函式精讀

### 4.1 `F_p` 層（有限體、`Int32` 域）

| 函式 | 說明 |
|---|---|
| `fp_norm` / `fp_add` / `fp_sub` / `fp_mul` | 以 `Int64` 中間運算做四則，`fp_mul` 對 `p` 接近 `2³¹` 仍安全 |
| `fp_inv` | 擴展歐幾里得求模逆（`a` 不可逆時回 0，呼叫端職責） |
| `ugcd_is_prime_int(p)` | **全 32 位元整數**的無溢位質數判定（`d·d` 先加寬，避開 `46341²` 溢位） |
| `fp_rref(m)` | `[D-Gauss]` Gauss–Jordan 消元，輸出**唯一** RREF + 主元位置（規範形，可直接當不變量） |
| `fp_rank` / `fp_nullspace_basis` / `fp_det` | 秩、`ker(m)` 基底、以列消元求行列式 |
| `fp_mat_mul` / `fp_mat_transpose` / `fp_mat_get/set` | 基本矩陣算術 |

被誰用：`accel`（M4RI 對照組）、`tensor`（張量展平 `t3_flatten` 回傳 `@gcd.FpMat`）、`topos`（Čech 上同調矩陣）、`bridge`（跨聯邦證書）。

### 4.2 `ℤ` 層（`BigInt` 精確）

| 函式 | 說明 |
|---|---|
| `ugcd_bigint_gcd/lcm/abs` | Euclid 演算法與 `lcm = a·b / gcd` |
| `ugcd_euclid_div(a,b)` | 樓層除法，保證 `0 ≤ r < abs(b)`（負數亦正確） |
| `ugcd_bigint_ext_gcd(a,b)` | 回 `(g, x, y)` 滿足 `a·x + b·y = g ≥ 0` |
| `zmat_snf(m)` | `[D-SNF]/[T-SNF]` 全程么模列／行變換的 Smith 正規形 |
| `zmat_snf_verify(m, res)` | 重算 `U·M·V` 並檢查整除鏈 ⇒ SNF 是**可驗證**而非「相信」 |
| `zmat_hnf(m)` | 列 Hermite 正規形 = 列 `ℤ`-格的規範不變量 |
| `ugcd_crt_reconstruct_signed(residues, moduli)` | 對稱中國剩餘定理，把模 `M` 的殘差重建成 `(-M/2, M/2]` 內的整數 |
| `ugcd_z_nullspace_basis(m)` | **巧妙用法**：`ℤ` 上整數零空間的基底，直接取自 `U·M·V = D` 中 `V` 的後 `cols - rank` 行 ⇒ 不需再解一次線性方程 |

被誰用：`algebra`（Berkowitz–CRT 特徵多項式、LLL、Van Hoeij 重組合）、`topos`（`integer_smith_torsion_factors` 由 `∂₂` 抽出 `π₁` 撓元，例如 `RP²` 的 `ℤ/2ℤ`）、`scheme`（`Fitting` 理想與正合性）、`condensed`、`accel`（Ozaki Scheme II 的 Garner CRT 對照）。

### 4.3 六域證書（`universal_gcd.mbt`）

`ugcd_certify_pair(m, n)` 產生 `UgcdSixFoldCertificate`，六條路徑**必須同答案**：

1. `arith_gcd` / `arith_lcm`：`ℤ` 歐幾里得；
2. `snf_d1` / `snf_d2`：`diag(m,n)` 的奇異值不變因子；
3. `tor0_order` / `tor1_order`：由總張量複形 `T_* = K(m) ⊗_ℤ K(n)` 得到的 `|Tor₀^ℤ(ℤ/m, ℤ/n)|`、`|Tor₁^ℤ|`；
4. `tropical_valuation_homomorphic`：`v_p(gcd) = min(v_p(m), v_p(n)) = v_p(m) ⊕_trop v_p(n)`；
5. `canon_meet_classes` / `canon_join_classes`：冪等規範化子（union–find 求最細共同粗化）；
6. `bezout_product_holds`：`dim(U∩V) + dim(U+V) = dim U + dim V`（Grassmann 精確性）。

`all_six_agree` 就是這六條的合取。另附 `ugcd_free_group_reduce(word)`：自由群 `F₂` 的字約化（`+k` 與相鄰 `-k` 對消，`0` 為單位元）——這是 `cubical/homotopy` 判別 `π₁(S¹∨S¹) = F₂` 真正非交換、而非 `H₁ = ℤ²` 的關鍵工具。

### 4.4 主定律開關

```moonbit
pub fn check_universal_gcd_laws() -> Bool
```
一次跑完本套件所有不變量（RREF 規範性、SNF 憑證、HNF、CRT、六域證書、自由群約化）。上層 `verify.mbt`（root）與 `cmd/main` 會把它列入總表。

---

## 5. 使用範例

```moonbit
// F_7 上的 RREF 與秩
let m = @gcd.fp_mat_from_rows([[1, 2, 3], [4, 5, 6], [7, 8, 9]], 7)
let r = @gcd.fp_rref(m)
println(r.rank)                       // 主元數

// 整數 Smith 正規形 + 自我核驗
let z = @gcd.zmat_from_int_rows([[4, 6], [10, 15]])
let snf = @gcd.zmat_snf(z)
assert_true(@gcd.zmat_snf_verify(z, snf))

// 六域泛 GCD 證書
let cert = @gcd.ugcd_certify_pair(42, 30)
println(cert.all_six_agree)           // true
```

---

## 6. 依賴關係

* **對外依賴**：僅 `moonbitlang/core/debug`（為 `derive(Debug)` 的零警告導出）。
* **被依賴**：`algebra`、`cubical-face-bdd`（同層但無依賴）、`cubical-homotopy`、`cubical-store`、`topos`、`condensed`、`tensor`、`conjecture`、`accel`、`bridge`、`root`。
* **規範**：任何聯邦若重寫一份矩陣消元／GCD，`tools/arch_check.py` 與 `agent.v2.md` 都視為架構違規。新增 Ly 演算法請以 `FpMat` / `ZMat` / `BigInt` 為主體向上擴充。

---

## 7. `T1` 延遲取模、HMM-SNF 與模行列式有界 HNF 升級與驗證

- `fp_mat_mul`（`p ≤ 46,340` 啟用轉置 16-lane `Int64` 延遲取模點積）與 `fp_rref`（單次 `% pm` 消元）。
- `zmat_snf`（Havas–Majewski–Matthews `(av, row_nnz·col_nnz, row_l1+col_l1)` 範數導引主元）、`zmat_det_bareiss`（無分數 Bareiss 行列式）與 `zmat_hnf_modular`（Domich–Kannan–Trotter 模 `|det(B)|` 有界 Hermite 標準形）。

```bash
moon check --deny-warn --target wasm-gc
python3 tools/arch_check.py               # 確認無人繞過本套件重寫消元
```
