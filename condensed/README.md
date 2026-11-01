# `condensed/` — X 形交疊樞紐：凝聚數學、固態／液態模、Steenrod–Adams、持久不變量賬本

> **架構位置**：`architecture.json` 中的 `condensed`，**Layer 3**，依賴 `gcd`、`algebra`、`symlib`、`semiring-trop`、`topos`、`scheme` —— 它是全倉**唯一同時匯入五個聯邦**的套件，因此正是雙 V 形架構中的 **X 形交疊樞紐（X-pivot）**。
> 聯邦歸屬：**F6**（第六聯邦：下 V 基底 `@gcd` ＋ X 交疊凝聚樞紐）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/condensed`。

---

## 1. 定位：把 Clausen–Scholze 凝聚數學做成有限可算物件

`condensed` 用**有限逆系（profinite tower）**表示凝聚對象，於是 `lim⁰`、Milnor `lim¹`、Mittag-Leffler 條件、`Ext^{i>0} = 0`、固態化 `(-)^■` 全部變成**矩陣秩與滿射性檢查**。四個「凝聚高階結構」是它的骨架：

| # | 結構 | 一句話 |
|---|---|---|
| ① | `CondAnima` | 凝聚 Postnikov–Kan 有限同倫棧：逐層 `ℤ`-同倫秩 + 整數 bonding 矩陣；`p`-進 solenoid 的 `lim¹` 幽靈障礙 |
| ② | `CondSolidModule` | 固態凝聚模 `M^■`：離散 vs 緊緻的固態間隙、Mittag-Leffler ⇒ `Ext^{i>0}=0`、么半張量 `ℤ[S]^■ ⊗^■ ℤ[T]^■ ≅ ℤ[S×T]^■`、`p`-液態範數次可加性 `0 < p ≤ 1` |
| ③ | `CondSpectralSheaf` | 凝聚譜層：Grothendieck Čech 扭曲黏合障礙 `k¹ − r⁰` ＋ 扭曲 AHSS `d₃ = Sq³ + H·u(-)` |
| ④ | `CondAnalyticStack` | Huber–Zariski 雙極解析棧 `Spa(A, A⁺)`：非阿基米德熱帶折點 ＋ `ℙ¹` 真性 ＋ 阿基米德精確有理跡／範數界 ＋ 固態 `ℤ_p` 完備化 |

外加兩個**範疇**（`CondCategory`、`CanonElimCategory`）、一份**雜湊鏈持久不變量賬本**（`CondInvariantLedger`）與**四項新猜想**（`Conj-1..4`）。

---

## 2. 檔案清單（3 檔，約 2.4k 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `profinite_solid.mbt` | 682 | 高階結構 ①② ＋ 範疇 ①（`CondCategory`）：`CondProfinite`、`CondChain`、`CondAnima`、`CondSolidModule`、`CondProMorphism` |
| `spectral_homotopy.mbt` | 1050 | 譜序列引擎、Serre 收斂、Steenrod–Adams `Ext_A(F₂,F₂)`、`2η = 0`、Koszul `Tor`、高階結構 ③（`CondSpectralSheaf`） |
| `analytic_stack_chiasm.mbt` | 715 | 高階結構 ④（`CondAnalyticStack`）、範疇 ②（`CanonElimCategory`）、`CondInvariantLedger`、五透鏡寫入、`Conj-1..4` |

---

## 3. 逐檔精讀

### 3.1 `profinite_solid.mbt` — 塔、鏈、Anima、Solid

**有限逆系**
```moonbit
pub(all) struct CondProfinite {
  levels : Int32
  sizes  : Array[Int32]                  // |S_n|
  maps   : Array[@gcd.FpMat]             // maps[n] : S_{n+1} -> S_n（one-hot 滿射矩陣）
}
```
* `cond_prof_valid`（`[T-Prof]`）：每個轉移矩陣是**滿射函數**（每列唯一 `1`、每行至少一個 `1`）。
* 具體塔：`cond_prof_pt`、`cond_prof_zq(q, levels)`（`ℤ_q = lim ℤ/qⁿℤ`）、`cond_prof_cantor`（`{0,1}^ℕ`）、`cond_prof_n_inf`（`ℕ ∪ {∞}`）。
* 運算：`cond_prof_product`（逐層 Kronecker 積）、`cond_prof_coproduct`（逐層塊對角和）。

**凝聚鏈 `CondChain`**（`F_p` 上的 `(V_n, trans_n)`）
* `cond_chain_free(pr)`：自由固態模 `ℤ[S]^■`；`cond_chain_locally_constant(pr, k)`：局部常數上鏈 `C(S_n, F_p^k)`（拉回 = 轉置）；
* `cond_chain_tensor`：逐層 Kronecker ⇒ 驗 `ℤ[S]^■ ⊗^■ ℤ[T]^■ ≅ ℤ[S×T]^■`；
* `cond_chain_lim_dim(c)`：穩定逆限維度 = 總複合 `V_{N-1} → V_0` 的秩；
* `cond_mittag_leffler_holds(c)`：像秩穩定 + 每個轉移皆滿射 ⇒ `Ext^{i>0}(ℤ[S]^■, F_p) = 0`。

**`CondAnima`（高階結構 ①）**
`cond_anima_build` 建兩類對象做**對照**：
* `solenoid_p`：`p`-進 solenoid `lim(… --×p--> S¹ --×p--> S¹)`，`π₁` bonding 為 `[[p]]` ⇒ coker 隨層增長 ⇒ **Milnor `lim¹` 非零**（幽靈障礙）；
* `cantor` / `n_inf`：`lim¹ = 0`。
於是「`lim⁰` 相同但 `lim¹` 不同」這件事被**實際算出**而不是引用。

**`CondSolidModule`（高階結構 ②）**
* `cond_solid_module_build(base_tower, k, p_num/p_den)`：記錄固態間隙 `discrete vs compact`、Mittag-Leffler `Ext¹` 消沒；
* `cond_liquid_subadditive_check(p_num, p_den)`：對有理 `p` 精確檢查 `(|x+y|)^p ≤ |x|^p + |y|^p`。`p = 1/2` 時**對所有** `x, y` 成立；`p = 2` 時**失效** ⇒ 這是「`p`-液態只在 `0 < p ≤ 1` 有意義」的可執行證明。

**範疇 ① `CondCategory`**
`cond_cat_id`、`cond_cat_comp`（複合相干要求 `T.maps[n]·g[n+1] == g[n]·S.maps[n]`）、`cond_cat_proj1`；以及冪等左伴隨的固態化反射子 `(-)^■ ⊣ ι`。

### 3.2 `spectral_homotopy.mbt` — 譜序列與 Steenrod–Adams

| 物件 | 要點 |
|---|---|
| `SsPage` | 雙分次頁 `E_r^{p,q}`；`ss_page_dd_zero` 驗 `d_r ∘ d_r = 0`；`ss_page_next` 算 `E_{r+1} = ker(d_out)/im(d_in)`；`ss_total_by_degree` 給總次數維度 |
| `serre_hopf_fibration_report` | Hopf 纖維化 `S¹ → S³ → S²`：`E₂^{p,q} = H^p(S²) ⊗ H^q(S¹)`，越化 `d₂ : E₂^{0,1} → E₂^{2,0}`（`×1`），收斂到 `H^*(S³) = [1,0,0,1]`；另有 `Sⁿ → S^{2n+1} → S^{n+1}` 與 Hurewicz `H₂(S²) = ℤ` |
| `cond_steenrod_adem_pair(i,j)` | `[E-Adem]` 把 `Sq^i Sq^j` 展開為 `mod 2` 容許單項式 |
| `adams_ext_f2_report` | 截斷 Steenrod 代數 `A_{≤d}` 的**最小自由分解** ⇒ `Ext_A^{s,t}(F₂,F₂)` 表；關鍵值 `Ext^{1,2} = 1`（`h₁ = η`）、`Ext^{2,3} = 0`（`h₀h₁ = 0`）⇒ **代數地認證 `2η = 0`** |
| `koszul_tor_report(g, N)` | `K_*(F₂[x₁..x_g])`：`d² = 0` + 正同調度正合；古典 `Tor_i = C(g,i)`、雙邊截斷多項式環 `Tor_i = C(2g,i)` |

**高階結構 ③ `CondSpectralSheaf`**
`cond_spectral_sheaf_build` 同時算兩件事：
1. 覆蓋景上局部 `H³`-扭曲資料的 **Čech 黏合障礙** `k¹ − r⁰`（`0` ⇒ 可黏合）；
2. **扭曲 AHSS** `d₃ = Sq³ + H·u(-)`（`dim X ≤ 5` ⇒ `Sq³ = 0`，只剩 `H∧u`）在 `S³` 與 `T³` 上的實際頁面演化（例如 `E₂ = 4 → E₄ = 2`）。

### 3.3 `analytic_stack_chiasm.mbt` — 解析棧、規範消元範疇、賬本、猜想

**高階結構 ④ `CondAnalyticStack`**
```moonbit
pub(all) struct CondAnalyticStack {
  ring_name : String
  tropical_bend_roots_count : Int32        // @strop.UniPoly 的熱帶折點數
  p1_proper_and_separated : Bool           // @scheme 的 ℙ¹ 賦值真判定
  topos_laurent_site_valid : Bool          // @topos：U₊ ∪ U₋ 的 Laurent 有理覆蓋是景
  laurent_cech_exact : Bool                // Čech 正合（h⁰ = 1, h¹ = 0）
  archimedean_trace_rat : @exactalg.Rat    // 阿基米德跡／範數的精確有理界
  solid_completion_gap : Int32             // 固態 ℤ_p 完備化間隙
  bipolar_coherent : Bool
}
```
它是**唯一同時引用 `@strop`、`@scheme`、`@topos`、`@exactalg`、`@gcd` 的型別**，因此 `CondAnalyticStack` 本身就是 X 形交疊的「物證」。

**範疇 ② `CanonElimCategory`（規範消元範疇）**
* `CanonObject`：有限載體 + 顯式等價關係 `equiv[x·size + y]` + 規範化子 `canon[x]`（滿足 `[Ax-Canon-Idem]` 冪等與 `[Ax-Canon-Sound]` 完備）；
* `CanonMorphism`：**等變**映射（`x ~_dom y ⇒ map x ~_cod map y`），故 `canon_cod ∘ map` 唯一穿過 `canon_dom`；
* `canon_cat_id`、`canon_cat_comp`、`canon_morphism_valid` 驗證範疇公理。

**持久不變量賬本 `CondInvariantLedger`**
```moonbit
pub(all) struct CondLedgerEntry { seq; kind; values; parents; prev_hash; hash }
```
* `kind`：`0 = 觀測`、`1 = 導出定律`、`2 = 定理`；
* `cond_ledger_append` 逐筆雜湊鏈（`prev_hash` 串接），`cond_ledger_verify` 從頭重算整條鏈 ⇒ **任何篡改都會被抓出來**；
* `cond_ledger_derive_invariants` 由已驗證條目導出新不變量；`cond_ledger_audit_laws` 稽核全域定律。
* `conjecture/evolution_lenses.mbt` 的五個認識論透鏡**直接寫入這個賬本**（見 `evaluate_five_epistemic_lenses_into_ledger`）。

**四項新猜想（`[Conj-1..4]`）**

| 編號 | 內容 |
|---|---|
| `Conj-1` | 凝聚固態間隙 vs 熱帶虧格的 `p`-進縮放猜想 |
| `Conj-2` | 「`H₁`-繞數 = 0 就足以在任意 0-連通 HIT 中填充 2-盒」—— 被 `F₂` 非交換反例**否證** |
| `Conj-3` | Stasheff 結合多面體正規化二項式係數的超對數凹性 |
| `Conj-4` | 有界頻寬鏈 vs 交叉開關置換的縮放交叉點 |

`cond_evaluate_new_conjectures` 逐條給出 `CondConjectureStatus`（含反例見證），`conjecture/` 再把其中可轉移者提升為 12 條跨聯邦猜想的一部分。

---

## 4. 主檢核入口

| 函式 | 範圍 |
|---|---|
| `cond_check_structures_1_2_and_category_1()` | `[Ax-Cond-ExtDisc]` 餘積層下降、`CondAnima` 的 `lim¹` 分離、`CondSolidModule` 固態間隙與液態範數、`CondCategory` 公理 |
| `cond_check_structure_3_and_spectral_homotopy()` | Serre、Steenrod–Adams（`2η = 0`）、`CondSpectralSheaf`、Koszul `Tor` |
| `cond_check_structure_4_category_2_ledger_and_conjectures()` | 解析棧、`CanonElimCategory`、賬本鏈驗、四猜想 |
| `cond_check_federation_all()` | 本聯邦總開關（`cmd/showcase` 與 `bridge` 會呼叫） |

---

## 5. 範例

```moonbit
// 1) p-進整數塔 + 自由固態模 + mittag-leffler
let z3 = @condensed.cond_prof_zq(4, 3, 5)          // levels=4, Z_3 = lim Z/3^n, 係數 F_5
assert_true(@condensed.cond_prof_valid(z3))
let ch = @condensed.cond_chain_free(z3)
assert_true(@condensed.cond_mittag_leffler_holds(ch))

// 2) p-液態次可加性：p = 1/2 成立、p = 2 失效
assert_true(@condensed.cond_liquid_subadditive_check(1, 2))
assert_false(@condensed.cond_liquid_subadditive_check(2, 1))

// 3) 賬本：寫入 → 驗鏈
let l = @condensed.cond_ledger_new()
let l2 = @condensed.cond_ledger_append(l, 1, [1, 2, 0, 3], [])
assert_true(@condensed.cond_ledger_verify(l2))      // 逐筆重算雜湊鏈
```

---

## 6. 依賴與被依賴

* **依賴（全倉最廣）**：`gcd`、`algebra`、`symlib`、`semiring-trop`、`topos`、`scheme`。
* **被依賴**：`cubical/store`（`artifact_repository` 需 `condensed` 層）、`conjecture`（寫入賬本）、`bridge`、`root`。
* **限制**：`architecture.json` 明確禁止 `condensed` 匯入 `cubical`；凝聚的立方／HIT 相關內容放在 `bridge` 的 `K6-11` 才交會。

---

## 7. 驗證

```bash
moon test condensed --target wasm-gc
moon run --release cmd/showcase --target wasm-gc   # 印出 47/47 證書中的 condensed 部分
```
