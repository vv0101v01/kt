# `ualg/demorgan/` — De Morgan 立方體

> **架構位置**：套件 `ualg-demorgan`，聯邦 `ualg`，Layer 1，`depends_on: [ualg-core, ualg-site]`。
> 被 `cmd/ualg` 匯入。

## 1. 一句話定位

CCHM 立方型別論底下的**純組合層**：區間的代數（自由 De Morgan 代數）、維度代換構成的範疇、面格、
以及立方體的子複形——全部做成可列舉、可計數、可對帳的有限對象。它把 `ualg/core`（商、Galois、譜）
與 `ualg/site`（¬¬、開集）用在同一個對象上。

## 2. 檔案

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `term.mbt` | 490 | DM(n) 的反鏈正規形、單調真值表、𝟜-語義、Dedekind 數 |
| `cube.mbt` | 584 | 代換、立方體範疇、可逆判準、B_n、仿射（read-once）片段 |
| `face.mbt` | 418 | 面格 𝔽(n)、公式 ↔ 子複形、∃／∀、遞推計數 |
| `complex.mbt` | 632 | 立方鏈複形、秩（Bareiss／mod p）、Betti 數、懸掛、積、Laplace 算子 |
| `symmetry.mbt` | 184 | B₂ 在 DM(2)、𝔽(2)、仿射片段上的作用；Fix ⊣ Stab |
| `laws.mbt` | 21 | `all_laws()`：11 條定律的登記 |

## 3. 核心表示

| 對象 | 表示 |
|---|---|
| DM(n) 的元素 | `Array[Int32]`：⊆-極小子句的排序清單；子句是字面遮罩（位 2i = x_i，位 2i+1 = ¬x_i）。`[]` = 0，`[0]` = 1 |
| 同一元素的語義 | `UInt64`：2n 個字面當獨立變數的單調真值表（n ≤ 3） |
| 態射 [m] → [n] | `Array[Array[Int32]]`：n 個 m 元正規形 |
| 面公式 | 同正規形，但每個子句一致（不同時含 x_i 與 ¬x_i）；x_i ↔ (i=1)，¬x_i ↔ (i=0) |
| □ⁿ 的面 | 三進位碼（位 i：0/1 固定，2 自由），與 `@site.poset_cube(n)` 的元素序號相同 |
| 子複形 | `Array[Bool]`（長 3ⁿ）；n ≤ 3 時也可用 `@site` 的開集遮罩 |

## 4. 得到的定理

| 標籤 | 敘述 | 重算出的數 |
|---|---|---|
| [A-Ded] | Dedekind 數三條路徑（配對、區間公式、窮舉） | M(0..6) = 2, 3, 6, 20, 168, 7581, 7 828 354 |
| [T-Kal] | DM(n) ≅ FD(2n)；正規形 = 真值表 = `core.free_algebra(𝟜, n)` | \|DM(1)\| = 6、\|DM(2)\| = 168、\|DM(3)\| = 7 828 354 |
| [T-Sub] | 代入 = 真值表沿 Φ_σ 拉回；範疇公理；14 條立方恆等式 | 24 192 組 (f,σ)；27 648 組結合律 |
| [T-Aut] | σ 可逆 ⇔ Φ_σ 雙射；Aut([n]) = B_n | 2（6 中）、8（28 224 中）、48；階型 1,2,2,2,2,2,4,4 |
| [T-Gur] | 仿射元素：DP 生成 = Gurvich 判準篩選 | 4, 14, 96, 1146；a(k) = 1, 2, 8, 52（A006351） |
| [T-AffC] | 仿射態射對合成封閉；對角線與 x∧¬x 不在其中 | [2]→[2] 共 60 個，3600 組 |
| [T-F3] | 𝔽(n) = DM(n)/⟨x_i∧¬x_i ≈ 0⟩ ≅ O(Vⁿ) | 5、48；\|𝔽(3)\| = 15 936 |
| [T-Bool] | De Morgan 同餘的核 = ¬¬ 核子的核，商 = 𝟚^(2ⁿ) | 4、16 |
| [T-Quant] | ∃i ⊣ w ⊣ ∀i；Frobenius；Beck–Chevalley；∀i 保 ∧ **與** ∨ | 𝔽(2) 全部；n = 3 抽樣 1200 組 |
| [T-∀≠] | ∀i.φ ≤ φ(i0)∧φ(i1)，且嚴格小於的有 46 個 (φ,i) | ∀i.((i=0)∨(i=1)) = 0 |
| [T-Box] | 開盒無環；∂□ⁿ ≃ S^{n−1} | 20 個開盒；n = 1..4 |
| [T-Susp] | β̃_{k+1}(ΣK) = β̃_k(K)；Σᵏ S⁰ ≃ Sᵏ | 6 個 K；k = 1,2,3 |
| [T-Push] | 開盒 ∪_{S^{n−2}} 面 = ∂□ⁿ | n = 2,3,4 |
| [T-Kun] | P(K×L) = P(K)·P(L)；T² = (1,2,1)、T³ = (1,3,3,1) | 15 對 |
| [T-Hodge] | dim ker Δ_k = β_k（兩條路徑） | 17 個 (複形, k) |
| [T-SpecK] | χ(Δ_k(□ⁿ)) = ∏_j (x − 2(k+j))^{C(n,k)·C(n−k,j)} | 13 個 (n,k)，矩陣階 ≤ 24 |
| [T-Burn] | B₂ 的軌道數（Burnside = 併查集） | DM(2)：46；𝔽(2)：15；仿射：5 |
| [T-GalD4] | D₄ 的 10 個子群在 DM(2) 上有 **9 個** Galois 閉；例外是 C₄，Fix(C₄) = Fix(D₄) | \|Fix(H)\| = 8,8,12,20,28,28,28,50,50,168 |

**被計算否定的猜想**：原先預期 D₄ 的 10 個子群在 DM(2) 上全部 Galois 閉。算出來是 9 個——旋轉 (x,y) ↦ (y,¬x)
生成的 C₄ 與整個 D₄ 有相同的不動點集（8 個元素），也就是說**旋轉不變的二元 De Morgan 函數必然全對稱**。
定律已改成陳述實際結果並指出例外。

**反例對照**：x∧¬x ≠ 0、x∨¬x ≠ 1、x∧¬x ≰ y∨¬y；連接、對角、常值代換不可逆；多數函數與 P₄ 函數非仿射；
∃i 不保 ∧（748 組）；∂□ⁿ ↪ □ⁿ 不是同調等價；仿射片段上只有 6 個子群是閉的。

## 5. 實作的演算法

| 演算法 | 入口 | 備註 |
|---|---|---|
| 反鏈正規形的 ∧、∨、¬ | `dnf_meet`、`dnf_join`、`dnf_neg` | ¬ 用 De Morgan 律逐子句展開 |
| 正規形 ↔ 真值表 | `dnf_table`、`table_dnf`、`table_neg` | |
| Dedekind 數 | `dedekind_by_pairs`、`dedekind_by_intervals`、`monotone_count_bruteforce` | M(6) 的區間公式只需 168² 項 |
| 代入與合成 | `dnf_subst`、`mor_compose` | |
| 字面賦值的拉回 Φ_σ | `lit_pullback`、`table_pull` | 語義層的代入，每張表 4ᵐ 次查表 |
| 可逆判定 | `mor_is_iso(sigma, n)` | Φ_σ 是否為 4ⁿ 點上的置換；不需列舉 DM(n) |
| 群閉包 | `mor_group(gens, n)` | |
| 仿射判定（Gurvich） | `is_affine(f)`、`mor_is_affine` | 質蘊涵 × 對偶質蘊涵恰交於一個字面，且無雙極性變數 |
| 仿射元素生成 | `affine_elements(n)` | 依變數支撐作子集 DP |
| 面格量詞 | `face_exists`、`face_forall`、`face_at` | 正規形上各一次線性掃描 |
| 公式 ↔ 子複形 | `face_open`、`open_face` | 經 `@site.Poset` 的 `down`／`up` |
| \|𝔽(n)\| 遞推 | `face_count_recursive(n)` | Σ_{φ,ψ∈𝔽(n−1)} \|↓(φ∧ψ)\| |
| 邊界矩陣 | `cx_boundary_matrix(cells, n, d)` | |
| 秩 | `rank_exact`（Bareiss，BigInt）、`rank_mod(m, p)` | 兩條路徑互相對帳 |
| Betti 數 | `cx_betti(k, n, p)` | p = 0 ⇒ ℚ 上精確 |
| 懸掛、積、開盒 | `cx_suspension`、`cx_product`、`cx_open_box` | ΣK = K×I ∪ □ⁿ×∂I |
| Laplace 算子 | `cx_laplacian(cells, n, d)` | 特徵多項式交給 `@core.mat_charpoly` |

## 6. 用法（已對真實簽名編譯過）

```moonbit
let x = @demorgan.dnf_var(0)
let y = @demorgan.dnf_var(1)
let f = @demorgan.dnf_neg(@demorgan.dnf_meet(x, y))
@demorgan.dnf_show(f)                                   // "¬x0 ∨ ¬x1"
@demorgan.is_affine(f)                                  // true

let phi = @demorgan.dnf_join(@demorgan.dnf_nvar(0), @demorgan.dnf_var(0))   // (i=0) ∨ (i=1)
@demorgan.face_forall(phi, 0)                           // []，即 0

@demorgan.cx_betti(@demorgan.cx_open_box(3, 0, 1), 3, 0L)   // [1]
@demorgan.cx_betti(@demorgan.cx_boundary(3), 3, 0L)         // [1, 0, 1]
@demorgan.dedekind_by_intervals(6)                          // 7828354
```

## 7. 流程與輸入／輸出

```
n ──► dm_elements(n) ──► 正規形清單 ──┬─ dnf_table ──► UInt64 ──► table_dm4_tuple ──► 與 @core.free_algebra 對帳
                                      ├─ @core.op_binary 建表 ──► @core.cg ──► 面格／布林反射的分割
                                      ├─ face_norm ──► face_open(@site.poset_cube(n), ·) ──► 開集遮罩 ──► @site.j_dneg
                                      └─ subst_action ──► 置換 ──► @core.fixstab_polarity ──► 閉子群

Array[Bool]（子複形）──► cx_cells ──► cx_boundary_matrix ──► rank_exact / rank_mod ──► cx_betti
                                   └─ cx_laplacian ──► @core.mat_charpoly ──► @core.root_multiplicity
```

## 8. 依賴界線

可匯入：`ualg/core`、`ualg/site`。禁止匯入其他聯邦。被匯入：`cmd/ualg`。

## 9. 驗證與界線

`moon run cmd/ualg --target wasm-gc` 的第 80–141 個命題。

* DM(n) 完整列舉只到 n = 2；n = 3 有 7 828 354 個元素，只算個數、生成元閉包與抽樣。
* `mor_is_iso` 的 Aut([3]) = B₃ 只驗「生成的 48 個都可逆」；「沒有第 49 個」在 n = 3 沒有窮舉（n ≤ 2 有）。
* 子句遮罩是 Int32，變數最多 15 個；真值表是 UInt64，n ≤ 3。
* 同調的例子都無撓，所以 ℚ 與 𝔽_p 的 Betti 數相等；這是對這些例子的觀察，不是一般性的斷言。
* T³（□⁶）的 Betti 數只在 𝔽_{2³¹−1} 上算。
* 這裡沒有 Kan 運算、沒有型別、沒有路徑——見 `ualg/README.md` §7。
