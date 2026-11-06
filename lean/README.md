# `lean/` — MoonBit 定律的 Lean 4 形式化

**狀態：492 條定理已證明並登記；MoonBit 側現有 485 條標籤，其中 437 條（本輪前的全部）有 Lean 對應（見 [`labels/coverage.md`](labels/coverage.md)）；本輪新增的 48 條能力定律（NbE 一般 β／SLD 完備性／匯入圖 SCC／QIIT 商良定義／實例修補終止序／真實 club 反射）尚未鏡射，`lake build` 綠。**

```
lean-toolchain    leanprover/lean4:v4.35.0      （2026-10-12 的穩定版，經 elan 安裝）
lakefile.toml     package KtLaws，buildDir = "build"（避免產物進快照）
KtLaws/Ramsey.lean      Ramsey 下界見證（P₁₇、Z₈、GG13）+ 上界 R(3,3) ≤ 6、R(3,4) ≤ 10、R(3,4) ≤ 9、R(4,3) ≤ 9、R(4,4) ≤ 18、R(3,5) ≤ 14 + 精確值 R(3,4) = 9、R(4,4) = 18、R(3,5) = 14  18 條
KtLaws/Graph.lean       有限圖的計數基礎：清單抽取、求和工具、**握手引理**  1 條
KtLaws/Matroid.lean     圖擬陣（秩公理／交換／貪心最優）、對偶秩（r** = r）、Q 上線性擬陣  14 條
KtLaws/Ordinal.lean     CNF 序數：比較的結構性、字典序遞移、ord_max 是 join 且結合、10 條 CNF 恆等式  31 條
KtLaws/Simplicial.lean  單純複形：Euler–Poincaré（全稱）、Betti 數、覆蓋的神經  19 條
KtLaws/IIT/Schema.lean   歸納-歸納：schema／索引檢查／消除器／Kleene 鏈的一般定理  35 條
KtLaws/IIT/Examples.lean Even/Odd、Nat/Fin、有限 schema 的定律（相位差、ι 律、依賴圖）  33 條
KtLaws/IIT/STLC.lean     STLC 的 β 與**索引傳輸**：上下文插入、弱化、代換、正規化  40 條
KtLaws/IIT/Extra.lean    佔位符被拒、有限互遞迴 schema 的穩定化                    6 條
KtLaws/Instances/UTerm.lean       一階項、替換、Robinson 合一（mgu）                1 條
KtLaws/Instances/Engine.lean      實例引擎：SLD 解析、終止、一致性（優先級）      22 條
KtLaws/Instances/Characterize.lean 可導性秩是不是擬陣的**判準**（交換公理太弱）     40 條
KtLaws/Instances/Compose.lean     最小基、覆蓋併攏（Möbius 障礙）、鏡像對偶、深度窗口 35 條
KtLaws/Instances/Coherence.lean   完備一致性、區域實例、擴充穩定性、Newman 引理    40 條
KtLaws/Reflect/Universe.lean      宇宙反射：保守性（可判定）＋ Mahlo 式反射（極限 vs 後繼）  23 條
KtLaws/Reflect/Nbe.lean           reify ⊣ reflect：β、η、冪等、保型（值域去函式化）        7 條
KtLaws/Reflect/Proof.lean         快（NbE 判定）＋ 慢（逐步憑證獨立重放）兩條路徑          16 條
KtLaws/Reflect/Link.lean          實例推導 → 憑證 → 不含搜尋的獨立檢查器                  13 條
KtLaws/Unify.lean                合一的正確性/普遍性/occurs check + 反合一 lgg 是 join   15 條
KtLaws/RamseyEx.lean             Ramsey 的界與夾擠：遞迴上界、Paley、精確值、深度窗口   46 條
KtLaws/Registry.lean    已證明定律的登記表，`#eval` 印出條數（492）
labels/coverage.md      437 個 MoonBit 標籤 ↔ Lean 定理的對照表（實測；本輪新增 48 條未列）
```

跑法：

```bash
cd lean && lake build                # 全綠才算數（型別檢查 = 證明檢查）
python3 tools/registry_audit.py      # 登記表對帳：登記筆數 / #check 條數 / 宣告長度三者相等
```

不需要 Mathlib：整套只用 Lean 4 核心函式庫（因此沒有 `Finset`，見下面「語言層筆記」）。

---

## 1. 為什麼是 Lean 而不是 `moon prove`

先做過 Why3 + Z3 的實測（[`../meta/prove_feasibility.md`](../meta/prove_feasibility.md)），
結論是 lowering 缺口正好卡在本倉定律的形狀上：`#proof_pure` 不支援遞迴（所以定律裡的函式
只能是 `.mbtp` 裡另寫的邏輯副本）、`Int` 沒有算術 variant、`.mbtp` 沒有條件式、
而 SMT 不做計算（連「四元素陣列上數到 2」都 timeout）。Lean 沒有這些限制：
遞迴、`decide`／`native_decide`、歸納、`simp` 全都在。

## 2. 已證明（492 條，kernel 檢查通過）

### 2.1 Ramsey（18 條）— 精確值 R(3,4) = 9、R(4,4) = 18、R(3,5) = 14

| 定律（對應 MoonBit 標籤） | Lean 名稱 | 手法 |
|---|---|---|
| Paley P₁₇ 有 68 條紅邊 | `paley_red_edges` | `native_decide` |
| Paley 著色對稱 | `paley_symm` | 逐點 `decide` |
| **P₁₇ 無單色 K₄ ⇒ R(4,4) ≥ 18** | `paley17_no_mono_K4` | Bool 檢查器 + soundness 引理 |
| K₈ circulant 12 條紅邊 | `circ8_red_edges` | `native_decide` |
| K₈ 無紅 K₃ / 無藍 K₄ / **R(3,4) ≥ 9** | `circ8_no_red3`, `circ8_no_blue4`, `circ8_no_red3_no_blue4` | `decide` |
| **R(3,3) ≤ 6（上界）** | `r33_le_6` | 邊用三角形索引 `j(j-1)/2 + i` 配位元 ⇒ 32768 種著色，`native_decide` 窮舉 |
| **R(3,4) ≤ 10（上界，組合論證）** | `r34_le_10` | 頂點 0 的 9 條邊：4 紅 ⇒ 鄰點之間無紅邊 ⇒ 藍 K₄；6 藍 ⇒ `six_star_step`（`R(3,3) ≤ 6` 的度數論證 + 「藍三角形 + v ⇒ 藍 K₄」）。只需一個 512 例的鴿籠 `native_decide` |
| **R(3,4) ≤ 9（上界，零窮舉）** | `r34_le_9` | 每個頂點紅度 ≤ 3（四個紅鄰點 ⇒ 藍 K₄）且 ≥ 3（紅度 ≤ 2 ⇒ 藍鄰點 6 個 ⇒ `six_star_step`），故紅色圖是 3-正則；但 `Σ deg = 27` 是奇數而握手引理說它是 `2 × 邊數`。**完全不用 `native_decide`** |
| **R(4,3) ≤ 9** | `r43_le_9` | 紅藍對調後即 `R(3,4) ≤ 9`（`triMono` 對調色不變） |
| **R(4,4) ≤ 18** | `r44_le_18` | 頂點 0 的 17 條邊 ⇒ 某色 ≥ 9 條；9 個同色鄰點上不能有同色三角形（否則與 0 湊成單色 K₄），限制著色與 `r34_le_9`／`r43_le_9` 矛盾。子圖用 `List.get`＋`idxOf` 造單射 `Fin 9 → Fin 18` |
| **R(3,4) = 9、R(4,4) = 18（精確值）** | `ramsey34_eq`, `ramsey44_eq` | 上界 ＋ 下界見證（`Z₈` circulant／Paley `P₁₇`）合併成單一定理 |
| **R(3,5) ≤ 14** | `r35_le_14` | 遞推 `R(2,5)+R(3,4) = 5+9`：五個紅鄰點 ⇒ 之間全藍 ⇒ 藍 K₅；九個藍鄰點 ⇒ 誘導著色無紅 K₃、無藍 K₄ ⇒ `R(3,4) ≤ 9` |
| **GG13 見證** | `gg13_no_red3`, `gg13_no_blue5` | `Z₁₃` 上差集 `{1,5,8,12}` 的 4-正則循環圖：無三角形、補圖獨立數 ≤ 4（`native_decide` 檢查 13⁵ 個五元組） |
| **R(3,5) = 14（精確值）** | `ramsey35_eq` | 上界 ＋ 13 點見證 |

### 2.2 擬陣（14 條）— 秩公理、交換公理、貪心最優、對偶、Q 上的線性擬陣

MoonBit 側的 `law_matroid_*` 是「在具體小擬陣上把公理與演算法跑一遍」；這裡把同一批
物件搬成 Lean 定義，並把**取樣**升級成**全稱**（對所有 `Fin 16` 的位元遮罩、
所有 `Fin 4⁴` 的權重向量）。

| 定律（對應 MoonBit 標籤） | Lean 名稱 | 手法 |
|---|---|---|
| 補集對合 | `compl_compl` | `funext` + 逐點 `cases` |
| **`M** = M`** | `dual_dual` | 特徵函數 + `List.map_map` |
| 對偶後基底逐一相等 | `dual_dual_bases` | `rw [dual_dual]` |
| **圖擬陣的秩 = 3**（三角形 `(0,1),(1,2),(0,2)` + 尾 `(2,3)`） | `graphic_rank_full` | 連通分量數 `numComp`，`r = 4 − c`，`decide` |
| **秩公理 R1/R2/R3**（`r(∅) = 0`、單調、次模） | `graphic_rank_axioms` | `unionS`／`interS` 上逐點 `decide` |
| **獨立集交換公理** | `graphic_exchange` | 全部 `Fin 16 × Fin 16` 的 `decide` |
| **貪心在圖擬陣上最優** | `graphic_greedy_optimal` | `pickMax`／`greedyAux` 算出的權重總和 = `bruteMax`（暴力枚舉全部獨立集），對 `4⁴ = 256` 種權重逐一比對；附帶 `r(貪心結果) = 3` |
| **對偶秩 `r*(E) = \|E\| − r(E)`** | `dual_rank_complement` | `numComp` 與補集的關係，`decide` |
| **`r** = r`**（對偶的對偶回到原秩） | `dual_dual_rank` | 全部 16 個子集逐一比對 |
| 對偶擬陣滿足交換公理 | `dual_exchange` | 全部 `Fin 16 × Fin 16` 的 `decide` |
| **Q 上線性擬陣的秩 = 2**（行 `(1,0)`、`(0,1)`、`(1,1)`） | `linear_rank_full` | 叉積判平行，`lRank` 取 0/1/2 |
| `{0,1}` 獨立、`{0,1,2}` 相依 | `linear_indep` | `decide` |
| **`{0,1}` 的閉包是全部三點** | `linear_closure` | `inClosure e s = (r(s ∪ {e}) = r(s))`，三點全查 |
| 線性擬陣滿足交換公理 | `linear_exchange` | `Fin 8 × Fin 8` 的 `decide` |

三塊都是**零 `native_decide`**：`decide` 在 kernel 裡跑，公理只有 `propext` /
`Classical.choice` / `Quot.sound`。

### 2.3 序數（31 條）— 字典序遞移、`ord_max` 是 lattice join 與 CNF 恆等式

MoonBit 側的 16 條是「4 個樣本 × 4 條性質」的取樣檢查；這裡換成**對所有序數**的定理，
另外把 `ord_probe_laws()` 裡的 10 條恆等式逐條變成定理。

| 群 | 內容 | Lean 名稱 |
|---|---|---|
| 比較的結構性 | CNF 唯一性：`cmp a b = eq ↔ a = b`；`cmp b a = (cmp a b).swap` | `cmp_eq_iff`, `cmp_swap`（用 `cmp.induct` 做雙重歸納） |
| 自然數比較（自帶） | `cmpNat` 判等、交換 | `cmpNat_eq_iff`, `cmpNat_swap` |
| 全序 | `≤` 自反／全序／反對稱 | `leq_refl`, `leq_total`, `leq_antisymm` |
| **字典序遞移** | `cmpNat a b = lt → a < b`；自然數比較遞移；**`cmp a b = lt ∧ cmp b c = lt ⇒ cmp a c = lt`**；`≤` 遞移 | `cmpNat_lt`, `cmpNat_lt_trans`, `cmp_lt_trans`, `leq_trans`（雙重歸納，7 個分支） |
| **`ord_max` 是 join** | 上界（左右）、恰為兩者之一、對稱、冪等、**最小上界**、上確界判準、**結合律** | `max_upper_left`, `max_upper_right`, `max_is_one`, `max_comm`, `max_idem`, `max_is_join`, `max_le_iff`, `max_assoc`, `max_assoc_eq` |
| CNF 恆等式 | `1+ω=ω`、`ω<ω+1`、`ω+ω=ω·2`、`1+(ω+1)=ω+1`、`ω+ω²=ω²`、`ω·10⁶<ω^ω`、結合律、`ω^{ω^ω}` 範式且更大、加法保持範式、`ω²·ω=ω³` | `cnf_absorption` … `cnf_mul_omega` |

關鍵一步是 `cmp_eq_iff`：它說「比較相等 iff 結構相等」，也就是 CNF 的唯一性；
有了它和 `cmp_swap`，`ord_max` 的每一條性質都變成 `cmp a b` 的三種情形（`lt`/`eq`/`gt`）
的有限分類討論，不需要任何樣本。

### 2.4 Simplicial / covers（19 條）— Euler–Poincaré 全稱化、Betti 數、神經的 H¹

MoonBit 側 `complex.mbt` 是三組取樣：一個圓、一個實心三角形、三個覆蓋。
這裡把**取樣升級成定理**：Euler–Poincaré 對所有 f-向量成立，Betti 數改用秩的定義
（最大非零子式）算，覆蓋的黏合判準則是把神經真的建出來算 `b₁`。

| 定律（對應 MoonBit 標籤） | Lean 名稱 | 手法 |
|---|---|---|
| **Euler–Poincaré（全稱）** | `euler_poincare` | `altSum_pair`：`Σ(−1)^k(r_k + r_{k+1}) = r₀ − (−1)^n r_n`，兩端秩為 0 就望遠鏡化掉；`omega` + `Int.mul_add`／`Int.mul_sub` |
| **套到所有有限複形** | `euler_poincare_complex` | `rankF_zero`（`∂₀` 是空矩陣）＋ `rankF_top`（`maxdim_bound` ⇒ 頂層無面） |
| 三角形邊界（≅ S¹）χ = 0 / b₀ = 1 / b₁ = 1 | `circle_euler`, `circle_betti_zero`, `circle_betti_one` | `decide`（kernel 算 `rank ∂₁ = 2`） |
| 三角形邊界是鏈複形 | `circle_chain` | `decide`（真的做 `∂₁ · ∂₂` 矩陣乘） |
| 實心三角形 χ = 1 / b₁ = 0 / b₂ = 0 | `disk_euler`, `disk_betti_one`, `disk_betti_two` | `decide`（`rank ∂₁ = 2`, `rank ∂₂ = 1`） |
| f-向量長度 ≥ 3、`f₀ ≥ f₁`、交錯和 = χ | `disk_f_vector_len`, `disk_f0_ge_f1`, `disk_f_vector_alt` | `decide` |
| 兩個孤立點 χ = 2 | `twoPoints_euler` | `decide` |
| 兩片重疊可黏、無障礙 | `good_cover_glues`, `good_cover_no_obstruction` | `decide`（nerve 是一條邊，`H¹ = 0`） |
| 三片兩兩相交卻不可黏 | `bad_cover_not_glues` | `decide`（nerve ≅ S¹ ⇒ `b₁ = 1`） |
| **障礙見證 = (0,1,2)** | `bad_cover_obstruction` | `decide`（列舉三元組，只依賴 `propext`） |
| 三片共同相交可黏、無障礙 | `good2_cover_glues`, `good2_cover_no_obstruction` | `decide`（nerve 是實心三角形） |

秩的定義值得說明：這裡不用高斯消去，而是「**最大非零子式的階**」——秩的標準刻畫。
子式用整數 Laplace 展開（`detGo`）算，所以整條路徑不碰除法、不需要 Mathlib 的線性代數，
也讓 `decide` 在 kernel 裡就能把 `rank ∂₁` 算成 2（不是靠 `native_decide`）。

### 2.5 歸納-歸納（82 條；iit 家族共 151 個標籤，樣本級檢查整理成全稱定理）— ι 律、終止性與 β 的索引傳輸

MoonBit `meta/iit/` 的標籤數是 **151**（`cmd/lawcount` 實測：Even/Odd 29、互遞迴消除器 26、
Kleene 鏈 23、subject reduction 15、Nat/Fin 14、STLC 三族 27、正規化 6、依賴圖 5、有限 schema 4、
佔位符 2）。Lean 側是 82 條**全稱**定理（schema 35 + 樣本 7 + STLC 40）：MoonBit 的每個標籤
都是同一族定理在某個樣本上的實例，因此條數不對齊 —— 這裡搬的是族，不是標籤。
這一族的重點不是數字，而是**三件本來只能取樣的事變成定理**：

| 群 | 內容 | Lean 名稱 |
|---|---|---|
| schema／索引檢查 | `icheck`／`icheckAt`、索引求值 `ieval`、`isortOf`／`iindexOf`、良構性 `ichemaOK`、依賴圖 `sortEdges`／`indexEdges` | `icheckGo`、`icheckAt_sound`、`fin` 系列 |
| **ι 律（全稱）** | 互遞迴消除器 `iitFold` 套上重建函式 = 恆等，**對任意 `IVal`**（MoonBit 只在枚舉出來的一族樣本上逐一比對） | `iit_fold_iota`（用 `Nat.strongRecOn` + `foldArgs_rebuild`） |
| **終止性（全稱）** | 任一子項都嚴格小於父項 ⇒ `ω^{size}` 度量嚴格下降，**對任意項** | `ivalSize_lt_of_mem`、`subterm_decrease`、`measure_decrease` |
| **Kleene 鏈（全稱）** | 階段函式保留前一階段（`stage_inflates`）、只產生通過 `icheck` 的居民（`stage_sound`）、從空族枚舉出的居民全部良構且 sort 正確（`enumerate_sound`／`enumerate_sort`）、鏈單調（`enumerate_mono`） | 全部是 `∀ fuel cap srt v` 的定理 |
| Even/Odd | 第 1 階段 1/1、第 2 階段 2/2、第 6 階段 6、嚴格成長、良構、sort 正確 | `evenOdd_*` |
| 有限 schema | `A = a0 | a1(B)`、`B = b0` 在第 4 與第 7 階段都是（2 / 1）⇒ 鏈穩定 | `finite_stage4`、`finite_stage7` |
| Nat/Fin | 14 條：第 1 階段 `Fin` 空、第 2/3 階段的計數、`fz z : Fin (s z)` 的索引、`fs (s z) (fz z) : Fin (s s z)`、兩個刻意構造的錯項被拒、`icheckAt` 的認證與拒絕 | `natFin_*` |
| 索引依賴圖 | 三個 schema 的索引依賴圖都無環；對照組：**資料**依賴圖允許有環（Even/Odd 0↔1）；Even/Odd 沒有任何索引依賴 | `*_index_acyclic`、`evenOdd_data_cycle`、`evenOdd_no_index_edges` |

#### STLC：β 的索引傳輸（40 條）

`meta/iit/stlc.mbt` 的 40 個標籤，核心不是「β 會約簡」，而是
**`app (lam A B body) arg` 的約簡同時在改上下文**：被代入的 `arg : Tm G A`
走過 k 層 binder 之後型別必須變成 `Tm (cons A_k (… (cons A_1 G))) A`。

| 群 | 內容 | Lean 名稱 |
|---|---|---|
| 上下文操作 | `ctxInsert ctx x k`（把 x 插到第 k 個位置）、`ctxRemove`、`makeVar`（由（上下文, 位置, 型別）重建變數節點——所有上下文改變的收斂點） | `ctxInsert`、`ctxRemove`、`makeVar` |
| 弱化＝插入 | `stWeaken t x = substInsert t x 0`：同一個操作，`k = 0` 就是弱化 | `stWeaken` |
| **β（帶索引傳輸）** | `substGo`：深度 `d = crossed.length`；`p = d` ⇒ 被抓的變數（把 `arg` 依序在每個走過的 binder 後插回去）、`p > d` ⇒ 外層變數位置減一、`p < d` ⇒ 內層綁定不動；每個節點的上下文都移除第 `d` 個元素 | `stBeta`、`substGo` |
| 索引保持（11） | `(λx:nat→nat. x) (λy.y) ↝ λy.y` 與 `(λx:A. λy:nat. x) (λz.z)` 的**索引（上下文, 型別）逐項相同**（`sameIndex` 用 `iindexOf` 重算），且內層 `arg` 的上下文真的從 `nil` 變成 `cons nat nil` | `beta1_*`、`beta2_*` |
| 弱化一致（9） | 變數弱化＝包一層 `vs`；型別不變、上下文變；弱化兩次位置 = 2；型別錯的 `app` 被攔下 | `weaken_*` |
| 主體約簡（4） | 四個閉項的**每一步**都保持索引（`stepOK` 逐步驗，`batteryOK` 一次驗四個）；正規形仍良構 | `subject_reduction_battery` 等 |
| 正規化（7） | 停在卡住的值上；函式位置是變數時不 β（卡住的項不是值、但良構）；燃料 0 不假裝算出答案 | `norm_*`、`stuck_app_*` |
| `Tm` 需要 `cons`（9） | `icheckAt` 認證恆等項的索引 = `(nil, nat→nat)`、變數的索引 = `(上下文, 型別)`；換一個上下文、換一個型別、上下文長度不對，全被拒 | `stlc_*` |

最有代表性的一條是 `beta2_arg_weakened`：

```lean
theorem beta2_arg_weakened :
    betaProp exApp2 (fun r => ivalEq (ivArg (ivArg r 3) 0) (stCons stNat stNil)) = true := by decide
```

它說的是：`(λx:A. λy:nat. x) (λz.z)` 約簡後，**內層那個 `λz.z` 的上下文被插進了 `nat`**
—— 型別保持不是靠信仰，而是 `iindexOf` 在每一步重算出來的。

關鍵的搬運經驗寫進 §4 了：**well-founded 遞迴的定義 kernel 算不動**，
所以凡是要用 `decide` 算的函式（`icheck`、`itermOfVal`、`ieval`、`iindexOf`、`ichemaOK`、`collectIndexEdges`）
都得改寫成「對 `Nat` 燃料或對清單做結構遞迴」的形式。

### 2.6 全域實例（138 條；instances 家族 123 個標籤，Lean 側另有 15 條更強的形式）

`meta/instances/` 的主題是：**一個 typeclass 系統真正難的不是「找得到實例」，而是
終止、一致性、組合性**。四件事在這裡都變成可判定的檢查，而且都不是「大概會處理」：

| 群 | 內容 | Lean 名稱 |
|---|---|---|
| 底層（`UTerm.lean`） | 一階項、替換、occurs check、Robinson 合一（`uMgu`／`uUnifiable`）；替換用 `(變數, 項)` 關聯清單——稀疏陣列會讓變數編號 `9000` 每次查詢都走 9000 步 | `uEq`、`uApply`、`uMgu` |
| SLD 解析（22 條） | 取證型 `resolveAll`（蒐集全部推導樹）＋短路的 `solvable`（只問存不存在）；`evidence` 把推導具體化成見證項 | `sld_show_pair`、`sld_depth_and_size` |
| 終止 | 序數度量 `ω^{uDepth}` 嚴格下降；繞圈的 `Show T :- Show (Array T)` 被同一個檢查擋下 | `terminating_env_loop`、`measure_decreases_show` |
| 一致性 | 臨界對 + 典範化（優先級高者勝、平手取索引小者）+ 不一致見證；**終止與一致性是兩件事** | `overlap_*`、`clash_*` |
| **判準（40 條）** | 可導性秩是擬陣秩 ⟺ 沒有合成規則落在目標上 **且** 每條規則最多覆蓋一個目標；交換公理**太弱**（反例：秩一次跳 2，違反次模性 R3） | `axiomatic_*`、`failure_reason_is_R3`、`criterion_agrees` |
| 組合（35 條） | 貪心給**極小**不給最小；覆蓋併攏的下降條件與 ℤ₂ 單值化障礙（**Möbius 帶上非零截面黏不起來，零截面永遠黏得起來**）；鏡像對偶是對合且互證；`R(4,4) = 18` 比 `C(6,3) = 20` 更緊 | `mobius_*`、`mirror_*`、`ramsey_window_4_beats_erdos_szekeres` |
| 完備化（40 條） | 不用使用者 battery：從規則的 head/body 做**可達目標宇宙**閉包（BFS + mgu 實例化 + 具體化），在宇宙上檢查見證唯一；區域實例是舊 API 看不見的那一半；擴充穩定性（COCHIS）可判定；Newman 引理（終止 ∧ 局部合流 ⇒ 全域合流）實測 | `universe_*`、`local_instance_*`、`stable_*`、`newman_*` |

三條最有價值的：

* **`failure_reason_is_R3`** —— 舊判準只測交換公理（R4），這裡示範它**不夠**：
  `Show Int`（公理）＋ `Show (Array T) :- Show T`（合成）對目標集 {Show Int, Show (Array Int)}
  仍然通過 R4，但加入合成規則讓秩一次跳 2，違反次模性 R3。
* **`mobius_zero_glues` 對上 `mobius_not_glues`** —— 同樣三片、同樣 −1 扭結，
  非零截面黏不起來、零截面黏得起來；這是 Möbius 帶的拓撲事實，不是類比。
* **`criterion_agrees`** —— 六個環境 × 兩組目標集，判準與**嚴格秩公理檢查**（R1/R2/R3）
  逐一一致；判準不是猜的。

### 2.7 反射（59 條；reflect 家族 48 個標籤）— 快／慢兩條路徑、保守性、Mahlo、獨立重放

`meta/reflect/` 的四個檔案對應四個 Lean 模組。實測標籤數：universe reflection 18、
reflection 15、link 8、nbe 7 = **48**；Lean 側 59 條（多出來的是 MoonBit 裡落在
`match` 未觸發分支上的標籤，Lean 側改陳述成同一樣本的**另一面向**，並在檔案頭註明）。

| 家族 | 定律 | Lean 名稱（節選） | 手法 |
|---|---|---|---|
| 宇宙反射（23） | 句子在層級 l 可證 ⟺ 所有原子 < l；抬一層不改可證性 | `conserv_at_two`、`conserv_at_five`、`unreflect_reflect_max_atom` | `decide`（序數比較用 `Ordinal.cmp`） |
| Mahlo 式（13） | 極限層上必存在更小的見證；**臨界後繼上失效** | `mahlo_omega_some`、`mahlo_critical_none`、`succ_omega_not_limit` | `decide`；`isLimitLevel` = CNF 末項指數非零 |
| NbE（7） | β、η、冪等、保型 | `nbe_beta`、`nbe_eta`、`nbe_idempotent`、`nbe_check_preserved` | `decide`（值域去函式化，見 §4） |
| 憑證（16） | 快判定與慢重放一致；篡改起點／終點都被拒 | `proof_decide_fast`、`proof_decide_agrees`、`proof_tampered_end` | `decide`（憑證指紋用 `List Nat`） |
| 聯動（13） | 實例憑證不靠搜尋就能複驗；深度 2 / 3；形狀 `[2,0]` / `[3,0,2,1]` | `link_checks`、`link_nested_depth`、`link_tampered_kid` | `decide`（合一 + 規則頭的局部檢查） |

三個值得記住的事實：
* **保守性是定理，不是口號**：`provable (ordSucc l) (reflectStmt s) = provable l s` 在樣本上是 `decide`；
* **反射在極限層成立、在臨界後繼上失效**：`reflectDown (ordOfNat 2) stmtS2 = none`，而
  `reflectDown ordOmega stmtS2 = some 2` —— 「極限」是可判定的，不是比喻；
* **兩個判斷來自不同程式路徑**：`decideEq` 走語義域，`checkCert` 只驗相鄰兩格的 β/η，
  而 `proof_decide_agrees` 說它們在五個樣本上不衝突；`proof_unequal_decides` 更揭露
  基底型別上 `reify` 把非中性值讀成 `*` 的邊界（MoonBit 側那一格落在未觸發分支）。

### 2.8 合一與反合一（15 條）— mgu 是 meet、lgg 是 join

`meta/core/unify.mbt` 的 11 個標籤搬成 `KtLaws/Unify.lean` 的 15 條：

| 群 | 定理 | 內容 |
|---|---|---|
| 正確性／普遍性 | `unify_correct`、`unify_generality_x`、`unify_generality_y` | `σ` 讓 `f0(x1,f1)` 與 `f0(f2,x2)` 相等，且 `σ(x1)=f2`、`σ(x2)=f1` |
| 存在性／occurs check | `unify_exists`、`unify_occurs`、`unify_constants` | `x0 =? f3(x0)` 不可合一（不是「大概會停」）；`f0`／`f1` 一定失敗 |
| 對稱性 | `unify_symm_left`、`unify_symm_right`、`unify_symm_both` | `mgu(a,b)` 與 `mgu(b,a)` 代換後給出同一個項 |
| 反合一 | `lgg_shape`、`lgg_first_child`、`lgg_second_child_one_var`、`lgg_second_child_fresh`、`lgg_vars_are_fresh`、`lgg_is_join` | 共同結構保留、不同子項被抽象成**新**變數（≥100）、`lgg(x0,x1)` 同時是兩邊的推廣 |

`u_lgg` 的記憶表在 MoonBit 是可變 `Array`；Lean 側改成狀態對（計數器 + 記憶表），
語意相同（同一個 key 對拿同一個新變數）。

### 2.9 Ramsey 的界與夾擠（46 條）— 上界不是答案，夾死才是

`meta/core/ramsey_ex.mbt` 的 50 個標籤搬成 `KtLaws/RamseyEx.lean` 的 46 條：

* **遞迴上界比 Erdős–Szekeres 緊**（10 條）：`R(3,4) ≤ 9` 而 `C(5,2) = 10`；
  種子必須是**精確值**（拿上界 10 當種子只會得到 `R(4,4) ≤ 20`）；
  25 與 36 個點上的「永不更差」與對稱性都是 `decide`。
* **Paley 見證**（9 條）：`P₁₇` 自補（`2·|QR| = 16`、`2·|E| = 136`）、68 條紅邊、
  (4,4)-free 而且是 (4,5)/(5,4)-free；檢查器不是橡皮章（全紅 `K₁₇` 立刻被否決）。
* **夾擠**（14 條）：`R(4,4) = 18`、`R(3,5) = 14` 被「上界 + 見證」夾死；
  `R(3,6)` 夾不死就**誠實回報 `none`**，而上界 20 照樣給。
* **深度窗口**（6 條）：`ramseyWindow 3 = 18`（舊版會去窮舉 `R(4,4)`）。
* **由搜尋算出的值**（7 條）：`R(2,2)=2`、`R(2,5)=5`、`R(3,3)=6`，以及 Erdős–Szekeres 的
  `C(5,2)=10`、`C(6,3)=20`。

與 MoonBit 的差異：確定性局部搜尋（LCG）沒有搬，見證改成**寫死的循環圖**
（`Paley`／`GG13`／`Circ8`），必要性由 `KtLaws/Ramsey.lean` 的結構性上界補上；
所以 `ramseyPinned` 是一張**已證夾死**的表，不是搜尋結果。

### 2.10 三族審查：把「替代品」換成定理（26 條）

前一輪為了讓 kernel 歸約，有五處是「替代品 + 註解」撐住的。這一輪全部換成真證明：

| 原本的替代品 | 換成的定理 | 位置 |
|---|---|---|
| η 收縮不做事後位移（`Nat` 沒有負數） | `shiftDn` ＋ `eta_contracts_star`、`eta_blocked`、`eta_contract_shifts` | `Reflect/Nbe.lean` §7 |
| §6 的 η 定律只是樣本 | `nbe_reify_refl_neutral`（對所有型別、深度、中性值）＋ `nbe_reify_reflect_fuel`（燃料 64） | `Reflect/Nbe.lean` §8 |
| α-等價（`u_variant_eq`）用 `uEq` 代替 | `uCanon`/`uFingerprint`/`uVariantEq` ＋ `variant_refl/symm/trans/renames/distinguishes` ＋ α-等價版檢查器 `checkInstanceProofV` 的四條對帳 | `Reflect/Link.lean` §2, §3b, §5–6 |
| 「可列印」只用 `List Nat` 指紋 | `termText`/`certText`（`List Char`）＋ `termText_pos`、`certTextAux_ge`、`certText_pos` | `Reflect/Proof.lean` §6 |
| `triv` 的最大原子用 0（MoonBit 是 −1） | `stmtMaxAtomI` ＋ `max_atom_triv_int`、`max_atom_bridge` | `Reflect/Universe.lean` §6 |
| `ambiguousGoals` 的短路只有一句註解 | `ambiguityFilter_nil_of_unique_top`（一般引理）＋ 六條白箱／對照組定理 | `Instances/Coherence.lean` §12 |

兩件順帶查清的事：

* **437 個舊標籤裡只有 340 個互異**：同一個 `chk` 會在迴圈裡被 push 多次
  （iit 的 Even/Odd `#6`/`#7` 各出現 13 次），所以「437 條」不是 437 個不同主張。
  互異之後 iit 只剩 74 條，12 族全部有全稱定理（見 `labels/coverage.md` 的 iit 逐族表）。
* **短路不是無條件成立的**：`coherence_shortcut_needs_hypothesis` 給出對照組 ——
  `envClash2` 有臨界對，而且**真的**有歧義目標。

### 2.11 前沿對帳：反射技術／全域實例／歸納-歸納（38 條）

對照文獻逐條補的是「**一般化**」而不是補功能（詳見 [`../meta/CAPABILITIES.md`](../meta/CAPABILITIES.md)）：

* **反射原理的 club 結構**（Lévy–Montagne）：保守性從三個樣本升級成 `conserv_general`（所有 n ≥ 1、
  所有句子），並補上 club 三要件 —— 閉（`provable_mono`）、無界（`reflects_unbounded`）、
  有限交（`reflects_finite_fragment`），以及最小反射層（`reflects_minimal`）。
  邊界反例 `conserv_at_zero_is_false` 說明 n = 0 為什麼不能省。
* **全域實例「不造假」**：`canonical_mem`（典範化只挑不造）、`criticalPairs_complete`（臨界對不漏）、
  `criticalPairs_lt`（有序無自環）、`incoherenceWitness_mem`（見證是目標之一）。
* **IIT 的可判定範圍與初始代數**：`itermScopeOK_sound`（索引範圍檢查可靠）、
  `itermSize_lt_ctor`（簽名層良基）、`itermScopeOK_complete`（與可靠方向合起來精確刻畫索引範圍）、`iitFold_unique`（消除器是唯一與簽名交換的映射 ——
  §5 的 ι 律正是 `φ = ivalRebuild` 的特例）。

## 3. 尚未搬的（明示）

| 缺口 | 為什麼還沒做 |
|---|---|
| ~~序數 `≤` 的遞移性、`ord_max` 結合律~~ | ✅ 已完成（`cmp_lt_trans`、`leq_trans`、`max_assoc`）。 |
| ~~擬陣剩 8 條（圖擬陣貪心、Q 上線性擬陣）~~ | ✅ 已完成：`Matroid.lean` 共 14 條（見 §2.2）。 |
| ~~complex：f-向量交錯和 = Euler 特徵數~~ | ✅ 已完成：`Simplicial.lean` 共 19 條，含**全稱** Euler–Poincaré 與覆蓋神經的 H¹ 判準（見 §2.4）。 |
| ~~iit（77 條）~~ | ✅ 已完成（見 §2.5）：schema 層 + Even/Odd + Nat/Fin + 有限 schema + STLC 的 β 與索引傳輸。42 條一般定理／定律 + 40 條 STLC 定律。 |
| ~~instances（123 條）~~ | ✅ 已完成 138 條（見 §2.6）：合一、SLD 解析、終止、一致性、擬陣判準、覆蓋併攏、鏡像對偶、完備化與 Newman。 |
| ~~reflect（48 條）~~ | ✅ 已完成 59 條（見 §2.7）：保守性、Mahlo、NbE、憑證重放、實例憑證的獨立複驗。 |
| ~~unification / anti-unification（11 標籤）~~ | ✅ 已完成 15 條（見 §2.8）。 |
| ~~ramsey 的樣本級標籤~~ | ✅ 已完成：`KtLaws/RamseyEx.lean` 46 條把 50 個 ramsey 標籤全部對上（見 §2.9）。 |
| ~~iit 的樣本級標籤~~ | ✅ 12 族全部有全稱定理；最後兩個樣本族（佔位符 2、有限 schema 穩定化 4）補在 `KtLaws/IIT/Extra.lean`。逐族對照見 `labels/coverage.md`。 |
| `ord_to_string`（`+` 變 `w` 的那條字串定律） | Lean 側沒有 port 列印函式；數學會等價於 `cnf_absorption`。 |
| `isNormal` 的定義 | 這裡用「每項指數大於**其後所有**項」的版本（比 MoonBit 的相鄰檢查更強）；兩者在有遞移性時等價；遞移性已補上，之後可改回相鄰版本並證等價。 |
| Ramsey 家族 | ✅ 完整：`R(3,3) ≤ 6`、`R(3,4) = 9`、`R(4,4) = 18`、`R(3,5) = 14`（上界全部是結構性證明，下界是循環圖見證）。剩下 `R(4,5)` 這類更大的值未做。 |
| ~~逐標籤對應表~~ | ✅ 已寫成 [`labels/coverage.md`](labels/coverage.md)（437 個標籤逐族對照；`labels/moonbit-labels.md` 是 485 條的原始清單）。 |

## 3. 標籤的分佈與搬遷路線

以 `cmd/lawcount`（`moon run`，讀四個 `all_laws()`）**實測**的標籤分佈：

| 模組 | 標籤數 | 家族細分 |
|---|---|---|
| `meta/core` | 115 | ramsey 39 + 搜尋出的 Ramsey 值 7 + K₈ 顯式著色 4、ordinal 16 + CNF 2、matroid 13 + 有理秩 5、simplicial 9 + covers 5 + complex 4、unification 7 + anti-unification 4 |
| `meta/instances` | 123 | SLD 解析、終止、一致性、擬陣判準、覆蓋併攏、鏡像對偶、完備化與 Newman |
| `meta/iit` | 151 | Even/Odd 29、互遞迴消除器 26、Kleene 鏈 23、subject reduction 15、Nat/Fin 14、STLC 27、正規化 6、依賴圖 5、有限 schema 4、佔位符 2 |
| `meta/reflect` | 48 | universe reflection 18（Mahlo 10 + 保守性 8）、reflection 15、link 8、nbe 7 |
| **合計** | **485**（互異 **388**；本輪 +48） | Lean 側已登記 **492** 條定理（覆蓋前 437 條） |

Lean 側與 MoonBit 側的條數不對齊是**刻意的**：MoonBit 的標籤多半是同一族定理在樣本上的
實例，Lean 側則把族寫成全稱定理（序數 31 ≥ 18、實例 138 ≥ 123、simplicial 19 ≥ 18、
iit 82 對 151 個標籤但族全覆蓋、reflect 59 ≥ 48）。

建議順序（每步都要 `lake build` 綠才往下）：

1. ~~**ordinal**（18 條）~~ ✅ 已完成：31 條（比 MoonBit 的 18 條更強，樣本改成全稱），
   含同族的**字典序遞移**與 **`ord_max` 結合律**。
2. ~~**matroid 剩 8 條**~~ ✅ 已完成：14 條（圖擬陣的秩公理／交換公理／貪心最優、
   對偶秩 `r*(E) = |E| − r(E)` 與 `r** = r`、Q 上線性擬陣的秩／獨立／閉包／交換）。
3. **ramsey** ✅：`R(3,3) ≤ 6`、`R(3,4) ≤ 10`、`R(3,4) ≤ 9`、`R(4,3) ≤ 9`、`R(4,4) ≤ 18`、`R(3,5) ≤ 14`，
   並合併成精確值 **`R(3,4) = 9`**、**`R(4,4) = 18`**、**`R(3,5) = 14`**。
4. ~~**complex**~~ ✅ 已完成：19 條。`euler_poincare` 對任意 f-向量與秩序列成立（不只樣本），
   `euler_poincare_complex` 再套到所有有限複形；覆蓋的黏合判準、障礙見證也都搬過來了。
5. **~~iit~~**（151 標籤）— ✅ 完成（§2.5）：索引層用自訂 `IVal`／`ITerm`（不用 `Fin`），
   終止性用 `ω^{ivalSize}`，β 的索引傳輸用「上下文插入」當基本操作。
6. **~~instances~~**（123 標籤）— ✅ 完成（§2.6），138 條。
7. **~~reflect~~**（48 標籤）— ✅ 完成（§2.7），59 條：保守性、Mahlo、NbE、憑證、聯動。
8. ~~**合一／反合一 11 標籤**~~ ✅ 完成：`KtLaws/Unify.lean` 15 條（§2.8）。
9. ~~**ramsey 樣本級標籤**~~ ✅ 完成：`KtLaws/RamseyEx.lean` 46 條（§2.9）。
10. **iit 樣本級標籤**：151 個標籤都落在 12 個族裡，族已全部有全稱定理；
    逐標籤對照見 `labels/coverage.md`。

## 4. 語言層筆記（踩過的坑，寫下來免得重踩）

- **core 沒有 `Finset`／`Fintype`。** 要用就得加 Mathlib（本目錄刻意不依賴）；
  所以「團」「子集」都用 Bool 檢查器或特徵函數表達。
- **`decide` 跑在 kernel 裡，慢。** `Fin 17` 上的四變數量化（83521 個組合）在本機
  > 5 分鐘；同一件事寫成 Bool 檢查器 + `native_decide` 只要 0.5 秒。
  折衷做法：**檢查器 + soundness 引理**（見 `monoFree4_sound`），定理仍然是數學陳述。
- `native_decide` 依賴 `Lean.ofReduceBool`（可信邊界），
  所以本目錄只把它用在**純可計算的有限檢查**上，並且旁邊一定附上能人工核對的定義。
- `set_option ... in` 不能夾在 docstring 與 `theorem` 之間；要嘛放檔案頂端，要嘛去掉 docstring。
- 遞迴深度：`revert` 之後對 `Fin 17 × Fin 17` 做 `decide` 會撞 `maxRecDepth`，
  本檔在 namespace 開頭放寬到 100000。
- **`lemma` 不是核心的關鍵字**（那是 Mathlib 的別名）；本目錄一律用 `theorem`。
- **核心沒有的常用戰術**：`by_contra`、`swap`、`fin_cases`、`interval_cases`、`lemma`（後者是 Mathlib 別名）。
  本目錄的替代寫法：`suffices h : ¬ P by omega` + `intro hP` 取代 `by_contra`；
  兩分支用 `by_cases`；逐點拆 `Fin` 用 `match t with | ⟨0,_⟩ => …`。
- **核心沒有 `Fintype (α → β)`**：
  所以「對所有著色／所有 `Fin n → Bool`」**不能**直接 `decide`。
  解法是把 `k` 個值攤成 `k` 個變數（`mk5`／`mk9` 用 `Fin.cases` 串起來），
  命題就變成對 `k` 個 `Bool` 的量化（可判定）；要用 `match t with | ⟨0,_⟩ => …` 逐點拆。
- **well-founded 遞迴 kernel 算不動。** 這是搬 iit 時最大的坑：`icheck` 一開始寫成
  「值 → 參數清單」的相互遞迴，Lean 用 `Acc.rec`（well-founded）編譯，於是 `decide`／`rfl`
  完全卡住（錯誤訊息是 `reduction got stuck at …`）。解法有兩個：
  (a) 把遞迴改成**對 `Nat` 燃料**的結構遞迴（`icheckGo s n v`，燃料 `2 * ivalSize v + 2`）；
  (b) 把 `List.map` 型的遞迴改寫成「對清單的結構遞迴」輔助函式（`itermOfValList`、`ievalList`）。
- **`sizeOf` 在自訂歸納型別上會炸**：`failed to find LCNF signature for IVal._sizeOf_inst`。
  改用自己寫的 `ivalSize`（互相遞迴的 `ivalSize`／`sizeList` 反而是可計算的）。
- **Lean 核心沒有 `List.get?`／`Nat.strong_induction_on`／`le_refl`**：用 `l[i]?`、
  `Nat.strongRecOn`、`Nat.le_refl`。`l[i]?` 需要 `Inhabited`，`IVal`／`ITerm` 要自己補
  `instance : Inhabited IVal := ⟨IVal.mk 0 []⟩`。
- **代換型遞迴一律要燃料**：`substInsert`、`substGo`、`varDepth`、`stepOK` 都是
  「燃料 = 某個 size」或「燃料 = 12」的 `Nat` 結構遞迴；子項 `ivalSize` 嚴格下降
  保證終止，而 kernel 才算得動。
- **`inductive` 不生成投影函式**（只有 `structure` 會）：`v.args` 在
  `inductive IVal | mk (ctor) (args)` 上不成立，要 `match v with | ⟨c, args⟩ => …`
  或自己寫存取子（`ivalCtor`／`ivalArgs`／`ivArg`）。注意 `(stWeaken …).ctor`
  這種寫法在沒有投影時連**解析**都會失敗，錯誤訊息是 `unexpected token '='`，
  很容易誤判成語法問題。
- **`prefix` 與 `from` 是保留字**，不能當參數名（`| a :: as, prefix =>` 會直接語法錯誤）。
- **`String` 的運算對 kernel 不透明。** `decide` 算不動 `s.length`、`s1 = s2` 這類式子
  （`String.append` 是 opaque 的）。所以「環境指紋」改成 `List Nat` 的扁平編碼：
  凡是要給 `decide` 比的資料，都不要用 `String`。
- **`List.map`／`flatMap` lambda 裡的自我遞迴不是結構遞迴。** `def substSlots … | .ufn f xs => … (xs.map (fun x => substSlots x))`
  會被編成 well-founded，kernel 就卡住；要另寫一個對清單的結構遞迴輔助函式
  （`substSlotsList`）。這和 iit 的 `itermOfValList` 是同一條規矩。
- **`mutual` 區塊必須共用同一個嚴格遞減的參數。** 搜尋器的呼叫鏈
  `resolvePath → resolveRuleList → solveBody → resolvePath` 若不共用同一個 `Nat` 燃料，
  Lean 會退回 well-founded，`decide` 就不能用。
- **`section` 是保留字**，不能當結構欄位名（`sect`）；**`Nat.choose` 不在核心**（自己寫 `binom`）；
  **`mutual` 上不能掛 doc comment**（`/-- … -/` 貼在 `mutual` 前面會直接語法錯誤，改用 `/- … -/`）。
- **`sgn`／`sgn (n+1)` 不會被 `rw` 展開**（它們是 `rfl` 等式，不是 `simp` 引理）：
  要嘛先 `show` 成展開形，要嘛 `have hs : sgn (n + 1) = -sgn n := rfl` 再 `rw [hs]`。
- **`omega` 把非線性項當原子**：`Int.mul_add`、`Int.mul_sub`、`Int.neg_mul` 要先手動 `rw`，
  之後 `omega` 才接得住加法重排（這樣就不需要 `ring`）。
- **最大非零子式**：`idxSets` 全部子集時務必篩 `rs.length == k`，否則空子式 `det []=1` 會讓
  任何矩陣的「秩」都等於上限（本輪踩過：`rank ∂₁` 算成 3）。
- **`List.foldl` 的遞迴度量**：用 `termination_by` 指 `List.length`，或（本輪做法）把遞迴改成
  對「剩幾列」這個 `Nat` 遞迴（`detGo`），終止性就自動成立。
- 鴿籠 `pigeon9`（9 個布林值 ⇒ 4 個 true 或 6 個 false）是 512 例的 `native_decide`；
  預設 `synthInstance.maxSize` 合成不出那個超大的 `Decidable`，要放寬到 400。

- **Lean 的嚴格正性檢查不允許值域自帶函式欄位**：`inductive Val | vclos (f : Val → Val)`
  會被拒（`non positive occurrence`）。NbE 的值域改成**語法閉包**（型別 + body + 環境）
  再補一個 `.vneu` 表示「反射後型別仍是函式」的中性值 —— 去函式化，語意相同。
- **互遞迴要有共同遞減的燃料**：`evalN`／`applyAtN`／`reifyN`／`reifyNeuN` 四個互相呼叫，
  共用同一個 `Nat` 燃料就 `decide` 得動；不給燃料而靠 `termination_by` 會退化成
  well-founded recursion，kernel 完全不動。
- **`mutual` 前面不能放 doc comment**（`unexpected token 'mutual'`）—— 用 `/- … -/`。
- **自我遞迴的函式不能直接丟進 `List.map` / `List.all` 的 lambda 裡**（
  `checkInstanceProof` 對子節點的遞迴、`toNode` 對 `kids` 的遞迴都是）：
  Lean 看不到「元素是子項」，終止性失敗或退化。寫成成對的 list helper
  （`toNode`/`toNodeList`、`checkInstanceProof`/`checkKidsList`）就恢復結構遞迴。
- **`List.get?` 不存在**：用 `l[i]?`（`(env[i]?).getD …`）。
- **`Option.map (fun c => a = b) x = some true` 會讓 `Decidable` 合成失敗**（右邊被解析成
  `do` 區塊）：把條件寫成具名的 `Bool` 函式（`sizeMatches`、`oneKid`、`certAtLeast2`）再 `map`。
- **`String` 進不了 `decide`**（`cert_to_string`、`proof_to_string` 這類）：定理裡用
  `List Nat` 指紋（`certCode`、`proofShape`），`String` 版本另外保留給人看。

## 5. 公理審計（不是「看起來綠」就好）

```lean
import KtLaws
#print axioms Ramsey.paley17_no_mono_K4
#print axioms Ramsey.circ8_no_red3_no_blue4
#print axioms Matroid.dual_dual
```

輸出：

```text
'KtLaws.Ramsey.paley17_no_mono_K4' depends on axioms:
  [propext, Quot.sound, Ramsey.paley17_no_mono_K4._native.native_decide.ax_1_1]
'KtLaws.Ramsey.circ8_no_red3_no_blue4' does not depend on any axioms
'KtLaws.Matroid.dual_dual' depends on axioms: [propext, Quot.sound]
'KtLaws.Ordinal.cmp_lt_trans' depends on axioms: [propext, Quot.sound]
'KtLaws.Ordinal.max_assoc' depends on axioms: [propext, Quot.sound]
'KtLaws.Ramsey.r33_le_6' depends on axioms:
  [propext, Quot.sound, Ramsey.r33_le_6._native.native_decide.ax_1_1]
'KtLaws.Ramsey.r34_le_10' depends on axioms:
  [propext, Quot.sound, Ramsey.pigeon9._native.native_decide.ax_1_1]
'KtLaws.Ramsey.six_star_step' depends on axioms: [propext, Quot.sound]
'KtLaws.Ramsey.r34_le_9' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Graph.handshake' depends on axioms: [propext, Quot.sound]
'KtLaws.Ramsey.r44_le_18' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Ramsey.r43_le_9' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Ramsey.r35_le_14' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Ramsey.gg13_no_blue5' depends on axioms: [Ramsey.gg13_no_blue5._native.native_decide.ax_1_1]
'KtLaws.Matroid.graphic_greedy_optimal' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Matroid.dual_dual_rank' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Matroid.linear_closure' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Simplicial.euler_poincare' depends on axioms: [propext, Quot.sound]
'KtLaws.Simplicial.euler_poincare_complex' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Simplicial.circle_betti_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Simplicial.bad_cover_obstruction' depends on axioms: [propext]
'KtLaws.IIT.iit_fold_iota' depends on axioms: [propext, Quot.sound]
'KtLaws.IIT.enumerate_sound' depends on axioms: [propext, Quot.sound]
'KtLaws.IIT.natFin_fs_ok' depends on axioms: [propext]
'KtLaws.IIT.natFin_stage3' depends on axioms: [propext]
'KtLaws.IIT.subject_reduction_battery' depends on axioms: [propext]
'KtLaws.IIT.beta1_index_preserved' depends on axioms: [propext]
'KtLaws.IIT.beta2_arg_weakened' depends on axioms: [propext]
'KtLaws.Instances.axiomatic_matroidal' depends on axioms: [propext]
'KtLaws.Instances.criterion_agrees' depends on axioms: [propext]
'KtLaws.Instances.mobius_not_glues' depends on axioms: [propext, Classical.choice, Quot.sound]
'KtLaws.Instances.complete_env_show_coherent' depends on axioms: [propext, Classical.choice, Quot.sound]
```

- 純 `decide` 的定理（`circ8_no_red3_no_blue4`）**不依賴任何公理**；
- 序數那批（`cmp_eq_iff`、`cmp_swap`、`max_is_join`、**`cmp_lt_trans`、`max_assoc`**…）
  只依賴 `propext` / `Quot.sound`，與 `native_decide` 無關——它們是真正的歸納證明；
- **`R(3,4) ≤ 9`、`R(4,3) ≤ 9`、`R(4,4) ≤ 18` 與握手引理完全沒有 `native_decide`**，
  只多一條 `Classical.choice`（來自 `List.filter`/`decide` 的可判定性）——
  這是這批裡「最乾淨」的定理，`R(4,4) = 18` 因此不依賴任何編譯後執行的信任邊界；
- `dual_dual` 只用 `propext` / `Quot.sound`（Lean 的標準等價關係公理）；
- 擬陣那 14 條全部是 kernel `decide`／結構性證明，**沒有一條走 `native_decide`**，
  只多 `Classical.choice`（來自可判定性）；
- instances 那 138 條也全是 kernel `decide`；`axiomatic_matroidal`、`criterion_agrees` 只依賴 `propext`，
  少數幾條因為用到 `List.findSome?`／`head?` 而多帶 `Classical.choice`（搜尋類函式的正常代價）。
- IIT 那 82 條也全是 kernel `decide` 或結構性歸納（STLC 的 40 條只依賴 `propext`）：`iit_fold_iota` 與 `enumerate_sound`
  只依賴 `propext`／`Quot.sound`，`natFin_fs_ok`、`natFin_stage3` 甚至只依賴 `propext`；
- `RamseyEx` 那 46 條全是 kernel `decide`（沒有 `native_decide`，因此不引入 `ofReduceBool`），
  包含 17 取 5 的 6188 個子集檢查，其中 `paley_free_45`、`rec_bound_never_worse`
  **連 `propext` 都不依賴**（純 kernel 計算）；`Unify` 那 15 條同樣只有 `decide` 帶來的 `propext`；
- reflect 那 59 條全是 kernel `decide`：`conserv_at_five`、`mahlo_omega_some`、`nbe_idempotent`、
  `proof_decide_agrees` 只依賴 `propext`；`link_checks` 因為用到 `Classical.choice`（`canonical`
  在空清單上的取捨）而多帶 `Classical.choice`／`Quot.sound`，沒有任何 `sorryAx`／`ofReduceBool`；
- 單純複形那 19 條同樣沒有 `native_decide`：`euler_poincare` 只依賴 `propext`／`Quot.sound`
  （`omega` 帶進來的），`bad_cover_obstruction`、`disk_f0_ge_f1` 甚至只依賴 `propext`；
- 走 `native_decide` 的兩條（P₁₇ 的檢查、著色對稱）多一條 `native_decide` 自家的
  reduce 公理——這是「編譯後執行」的信任邊界，已在 §4 標明，且只用於有限可計算檢查。
- 全目錄 `grep sorry` 為空。

## 6. 與 MoonBit 側的關係（重要）

Lean 這批證明**不會**取代 MoonBit 的 485 條執行期定律：兩邊各自是獨立的檢查，
重疊處（Ramsey 見證、擬陣對偶）現在有兩份互相印證的證據；不重疊處仍是 MoonBit 一家之言。
這也是這條路線誠實的價值所在——不是把 `moon check` 換掉，而是多加一層**不靠執行的**保證。
