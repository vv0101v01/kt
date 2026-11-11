# `ualg/core/` — 構造性泛代數

> **架構位置**：套件 `ualg-core`，聯邦 `ualg`，Layer 0，`depends_on: []`（只用 `moonbitlang/core`）。
> 被 `ualg/demorgan` 與 `cmd/ualg` 匯入。

## 1. 一句話定位

「構造性泛代數自主類型論」三個詞條——**同餘＋商代數、吸收元／零元、Mal'cev 算子**——在有限表格代數上的
可計算版本，加上核心公理要求的 **Galois 對應**與**譜**。每個判定都回傳憑證或完整的閉包，而不是只回傳布林。

## 2. 檔案

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `algebra.mbt` | 763 | `Op`／`Alg`／`Term`；求值、恆等式檢查；`Sg`、積、同態、`free_algebra`；代數動物園 |
| `congruence.mbt` | 596 | 分割運算、`cg`（Freese 併查集閉包）、`con_lattice`、`quotient`、`kernel`、同構定理 |
| `malcev.mbt` | 287 | Mal'cev 項的三個演算法與憑證檢查器 |
| `zero.mbt` | 356 | 單邊／雙邊吸收元與單位元、理想、Rees 商、核 K(S) |
| `galois.mbt` | 573 | 極性、NextClosure、`automorphisms`、Fix ⊣ Stab、Burnside、Mod ⊣ Th |
| `spectrum.mbt` | 360 | BigInt 特徵多項式（Faddeev–LeVerrier）、Bareiss 行列式、平移算子的譜 |
| `laws.mbt` | 22 | `all_laws()`：10 條定律的登記 |

## 3. 核心資料型別

```moonbit
pub(all) struct Op   { name : String; arity : Int32; table : Array[Int32] }   // 小端 n 進位索引
pub(all) struct Alg  { name : String; n : Int32; ops : Array[Op] }
pub(all) enum   Term { TVar(Int32); TApp(Int32, Array[Term]) }
pub(all) struct Closure { elems; origin; complete : Bool; hit : Int32 }       // 閉包＋每個元素的來歷
pub(all) struct MalcevVerdict { exists : Bool; complete : Bool; term : Term?; r_size : Int32 }
pub(all) struct Polarity { nx : Int32; ny : Int32; rel : Array[Array[Bool]] }
```

二元運算 `table[x + n*y]`。分割以「代表元陣列」表示（`p[i]` = 所在類的最小元）；**`part_leq`、`part_blocks`
要求輸入已是這個形式**，任意標號先過 `part_norm`（`cg` 回傳的是併查集根，比較前也要 `part_norm`）。

## 4. 得到的定理

| 標籤 | 敘述 | 重算出的數 |
|---|---|---|
| [T-Freese] | 主同餘閉包算出的同餘格 = 全部分割逐一檢查相容性 | 12 個代數：\|Con\| = 4,4,3,16,2,5,2,2,2,4,14,2 |
| [T-Zn] | \|Con(ℤ_n)\| = d(n)；\|Con(Chain_n)\| = 2^(n−1) | n = 2..9；n = 2..6 |
| [T-FN] | 格的同餘格分配（Funayama–Nakayama）；Con(ℤ₂²) ≅ M₃ 模而不分配 | Chain5、M3、N5 |
| [T-Iso1/2/3] | 商良構、π 同態、ker π = θ；第一、對應、第三同構定理 | 36 個同餘；ℤ12 的 11 個自同態；27 組 (A,θ) |
| [T-Mal] | Mal'cev 項存在 ⇔ F(2)² 中 (x,y) 在 {(x,x),(x,y),(y,y)} 的閉包內 | 12 個有（項大小 5..13），7 個無（\|R\| 完整算完） |
| [T-FV] | 冪等代數：Freese–Valeriote 局部判定 = 全域判定 | 10 個代數，4 有 6 無 |
| [T-Perm] | Mal'cev ⇒ 同餘可換 ⇒ 模 | \|Con(A²)\| = 15,8,10,4,6 |
| [T-Zero] | 左、右吸收元並存必重合（零元唯一）；單位元同理 | 19 683 個 3 元原群無例外；有零元 243、兩者皆有 18 |
| [T-Rees] | 理想 I 的 Rees 分割是同餘，S/I 的零元是類 I；S 有零元 ⇔ \|K(S)\| = 1 | 24 個理想 |
| [T-Gal] | 極性的 (↑,↓) 是 Galois 連接；閉集兩側等勢 | 12 個 6×7 關係，210 個概念 |
| [T-FTGT] | GF(2^k)/GF(2)：閉子群數 = d(k)，\|Fix(H)\| = 2^(k/\|H\|) | k = 2,3,4；軌道數 3,4,6 |
| [T-ModTh] | Th(𝟚) ⊋ Th(𝟛) ⊋ Th(𝟜)；7 個閉等式理論 | 8 條等式 × 5 個代數 |
| [T-Spec] | χ(T_f) = x^t·∏(x^{\|c\|} − 1)；θ ∈ Con(A) ⇒ χ(T_{f/θ}) ∣ χ(T_f) | 55 個平移；249 組 (A,θ,f) |

**反例對照**（每條都是「檢查器會拒絕」的實例）：ℤ6 上 {0,1\|2\|…} 不是同餘；(x·y)·z 不是 Mal'cev 項；
Chain3 的兩個同餘不可換；Rect2×2 自身同餘可換但其簇沒有 Mal'cev 項（L₃ 見證）；至少兩個左吸收元的 3 元原群有 79 個；
Aut(ℤ₂²) 的 A₃ 是子群但不 Galois 閉；x⁴−1 ∤ x⁶−1。

## 5. 實作的演算法

| 演算法 | 入口 | 複雜度／備註 |
|---|---|---|
| Freese 主同餘閉包（併查集＋工作佇列） | `cg(a, pairs)` | 每次合併掃一遍各運算的單變元平移；近線性於 Σ 表格大小 |
| 同餘格 = 主同餘在 ∨ 下的閉包 | `con_lattice(a)` | 與 `con_bruteforce`（Bell 窮舉）對帳 |
| 元組閉包（帶來歷，可還原成項） | `close_tuples`、`closure_term` | `limit` 截斷時 `complete = false`，不會把「沒算完」說成「不存在」 |
| Birkhoff 自由代數 F_{V(A)}(k) ⊆ A^(n^k) | `free_algebra(a, k, limit)` | |
| Mal'cev 全域判定（一次閉包同時追兩個分量） | `malcev_global(a, limit)` | 座標 2·n² |
| 自反子代數的對稱性判定 | `malcev_reflexive_symmetric(a)` | 回傳不對稱的反例配對 |
| Freese–Valeriote 局部判定（僅冪等） | `malcev_idempotent_local(a)` | 先檢查冪等，不冪等則拒絕回答 |
| NextClosure（Ganter） | `closed_sets_next_closure(p)` | 與冪集窮舉對帳 |
| 自同構：只枚舉生成元的像 | `automorphisms(a)` | `generating_set` 先求小生成集 |
| Burnside 與併查集兩種軌道計數 | `burnside_sum`、`orbit_count` | |
| Faddeev–LeVerrier（BigInt，無除法誤差） | `mat_charpoly(m)` | 與 Bareiss 在 n+1 個整點的行列式對帳 |

## 6. 用法（已對真實簽名編譯過）

```moonbit
let a = @core.alg_zn(6)
let theta = @core.cg(a, [(0, 3)])            // 由 0 ≈ 3 生成的同餘
let (q, _) = @core.quotient(a, theta)        // q.n == 3：ℤ6/θ ≅ ℤ3
@core.con_lattice(a).length()                // 4 = d(6)

let s3 = @core.alg_s3()
let v = @core.malcev_global(s3, 100000)
match v.term {
  Some(t) => @core.malcev_term_ok(s3, t)     // true；t = ∘(∘(x2,∘(x1,x1)),∘(∘(x1,x1),∘(x1,x0)))
  None => v.complete                         // true 才代表「確定不存在」
}
```

## 7. 流程與輸入／輸出

```
Alg（運算表）─┬─ cg / con_lattice ──► 分割（代表元陣列）──► quotient ──► (Alg, 類標號)
              ├─ free_algebra ──────► Closure ──► closure_to_alg / closure_term
              ├─ malcev_* ──────────► MalcevVerdict（項憑證 或 完整的 |R|）
              ├─ automorphisms ─────► 置換清單 ──► fixstab_polarity ──► closed_sets_next_closure
              └─ basic_translations ► 函數 ──► functional_charpoly ──► Array[BigInt]（低次在前）
```

## 8. 依賴界線

可匯入：無（僅 `moonbitlang/core`）。禁止匯入本倉庫任何套件。被匯入：`ualg/demorgan`、`cmd/ualg`。

## 9. 驗證與界線

`moon run cmd/ualg --target wasm-gc` 的前 49 個命題。界線：代數以完整運算表表示，三元運算在 n ≳ 40 時表格已達
64 000 項；`con_bruteforce` 只用在 n ≤ 8；`malcev_idempotent_local` 對非冪等代數不給答案。
