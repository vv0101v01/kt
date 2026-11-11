# `ualg/site/` — 預層模板：Alexandrov 景、核子與 j-層

> **架構位置**：套件 `ualg-site`，聯邦 `ualg`，Layer 0，`depends_on: []`（只用 `moonbitlang/core`）。
> 被 `ualg/demorgan` 與 `cmd/ualg` 匯入。

## 1. 一句話定位

「預層模板」那四行——`j(x) = ¬¬x`、`Sh_j(E)`、「層化是左伴隨」、`j(j(p)) = j(p)`——在有限偏序上逐條做成
可以數的東西：景是偏序 P，拓撲是 O(P) 上的核子 j，層條件按定義對**每個**覆蓋篩檢查，伴隨用窮舉自然變換的個數驗證。

## 2. 檔案

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `poset.mbt` | 430 | `Poset`（Int32 遮罩，≤ 30 點）、開集列舉與三種計數、Heyting 蘊涵與否定 |
| `nucleus.mbt` | 275 | 核子公理、¬¬、閉／開核子、全部核子的普查 |
| `presheaf.mbt` | 555 | `Presheaf`、匹配族、`is_sheaf`、`plus`、`sheafify`、`count_nat`、`psh_omega` |
| `laws.mbt` | 16 | `all_laws()`：6 條定律的登記 |

## 3. 核心資料型別

```moonbit
pub(all) struct Poset    { n : Int32; down : Array[Int32]; up : Array[Int32] }      // down[x] = ↓x 的遮罩
pub(all) struct Presheaf { size : Array[Int32]; res : Array[Array[Array[Int32]]] }  // res[y][x] : F(y) → F(x)，x ≤ y
```

開集 = 下閉集，以 Int32 遮罩表示；核子是閉包 `(Int32) -> Int32`。篩 S ⊆ ↓x 覆蓋 x ⇔ x ∈ j(S)。

## 4. 得到的定理

| 標籤 | 敘述 | 重算出的數 |
|---|---|---|
| [T-Alex] | 下閉集族是拓撲；特化序還原 ≤；連續 ⇔ 單調 | 開集數 5,8,5,6,48,30；43 個單調映射 |
| [T-Hey] | w∧u ≤ v ⇔ w ≤ (u→v)；內在邏輯非布林 | 138 570 組；排中律失敗 84 次、¬¬u = u 失敗 66 次 |
| [T-DN] | ¬¬ 是核子；¬¬u = {x : ↓x 的極小元全在 u} | V、V²、V×Chain3 全部開集 |
| [T-Gliv] | Fix(¬¬) 是布林代數，共 2^{#極小元} 個 | 4、16、4 |
| [T-Refl] | a = j ⊣ (Fix(j) ↪ Ω)，保有限交；**不**保併 | 併失敗 502 組 |
| [T-Subl] | O(P) 恰有 2^{\|P\|} 個核子 | 8,8,8,16,16 |
| [T-Isb] | 稠密核子都 ≤ ¬¬（Isbell）；稠密核子數 = 2^{\|P\|−#極小元} | 同上五個偏序 |
| [T-Shf] | aF = F⁺⁺ 是層；η 自然；a(aF) ≅ aF；F 是層 ⇔ η_F 同構 | 10 個預層，其中 4 個本來就是層 |
| [T-Adj] | 對層 G：\|Nat(aF, G)\| = \|Nat(F, G)\| | 30 組計數逐一相等 |
| [T-DNsh] | ¬¬-層化的公式 a(F)(x) = ∏_{極小 v ≤ x} F(v) | V 上 [a, b, a·b]；V² 上 2, 4, 16 |
| [T-Top] | j = id ⇒ Sh = PSh；j = ⊤ ⇒ Sh = {1}；閉核子 c ⇒ Sh_j ≃ PSh(P∖c) | V 上四個預層 |
| [T-Fill] | 在 V² 上 a(∂□²) = □²；9 個可表預層都是 ¬¬-層 | |

**反例對照**：Ω 本身不是 ¬¬-層，且此時伴隨計數不等（\|Nat(F,Ω)\| = 16 ≠ \|Nat(aF,Ω)\| = 47）；
Ω(e) = 5 而 Ω_¬¬(e) = 4；∂□² 不是層。

## 5. 實作的演算法

| 演算法 | 入口 | 備註 |
|---|---|---|
| 開集列舉（線性延拓上深搜） | `opens_all(p)` | 輸出排序 |
| 開集計數：N(S) = N(S∖x) + N(S∖↓x)（x 為極大元，記憶化） | `opens_count(p)` | 不需列舉；V³ 得 15 936 |
| Heyting 蘊涵 u→v = {x : ↓x ∩ u ⊆ v} | `imp`、`hneg` | |
| 核子普查：枚舉對 ∧ 與 (u→·) 封閉的子集 | `all_nuclei(p, opens)` | 2^{開集數} 個候選，只用於開集 ≤ 12 |
| 匹配族回溯 | `matching_families(p, f, s)` | 逐點指派並即時檢查相容 |
| 最小覆蓋篩 S_x = ⋂{覆蓋篩} | `least_cover(p, opens, j, x)` | 有限時存在（j 保有限交） |
| plus 構造 F⁺(x) = Match(S_x, F) 與單位 | `plus`、`sheafify` | 第三個回傳值回報前提 S_x ⊆ S_y 是否成立 |
| 自然變換計數（回溯＋即時剪枝） | `count_nat(p, f, g)` | |
| Ω_j（j-閉篩預層） | `psh_omega(p, opens, j)` | j = id 時即 Ω |

## 6. 用法（已對真實簽名編譯過）

```moonbit
let p = @site.poset_v()                       // 0、1 是端點，2 是邊
let opens = @site.opens_all(p)
let j = @site.j_dneg(p)
let (af, eta, ok) = @site.sheafify(p, opens, j, @site.psh_const(p, 2))
af.size                                       // [2, 2, 4]
ok && @site.is_sheaf(p, opens, j, af)         // true
@site.is_natural(p, @site.psh_const(p, 2), af, eta)
```

## 7. 流程與輸入／輸出

```
Poset ──► opens_all ──► Array[Int32]（開集遮罩）
   │            │
   │            ├─ j_dneg / j_closed / j_open ──► j : (Int32) -> Int32 ──► is_nucleus / fixed_points
   │            └─ all_nuclei ──► 每個核子在 opens 上的取值表
   └─ psh_make / psh_const / psh_sub / psh_omega ──► Presheaf
          └─ sheafify(p, opens, j, F) ──► (aF : Presheaf, η : Array[Array[Int32]], 前提成立? : Bool)
                 └─ is_sheaf / is_natural / is_iso / count_nat
```

## 8. 依賴界線

可匯入：無（僅 `moonbitlang/core`）。禁止匯入本倉庫任何套件。被匯入：`ualg/demorgan`、`cmd/ualg`。

## 9. 驗證與界線

`moon run cmd/ualg --target wasm-gc` 的第 50–79 個命題。界線：偏序 ≤ 30 點；預層取值於有限集；
景只有偏序（沒有非恆等的自同態，所以群作用、一般小範疇上的層不在範圍內）；`is_sheaf` 對每個 (x, 開集) 都列舉匹配族，
只適合小例子。與 `topos/site_presheaf.mbt` 的既有實作**尚未對帳**。
