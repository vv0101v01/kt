# `condensed/` — 有限模型整合：凝聚數學、固態／液態模、Steenrod–Adams、持久不變量賬本

> **架構位置**：`architecture.json` 中的 `condensed`（**Layer 4**，依賴 `L1 condensed/core` 並透過 `reexport_core.mbt` 100% 重導出，聯同 `gcd`、`algebra-core`、`symlib`、`semiring-trop`、`topos`、`scheme`）—— 跨領域整合不等於已構造交換圖；舊 X-pivot 只是架構比喻。
> 聯邦歸屬：**F6**（第六聯邦：`gcd` + `condensed/core` + `condensed`，共 **3 套件**；現行檔數／行數見[生成架構清單](../docs/FEDERATION_ARCHITECTURE.md)）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/condensed`（純同調／Nöbeling／64× `@swar` Steenrod–Adams 輕核見 [`condensed/core/README.md`](core/README.md)）。

---

## 1. 定位：把 Clausen–Scholze 凝聚數學做成有限可算物件

`condensed` 用**有限逆系（profinite tower）**表示凝聚對象，於是 `lim⁰`、Milnor `lim¹`、Mittag-Leffler 條件、`Ext^{i>0} = 0`、固態化 `(-)^■` 全部變成**矩陣秩與滿射性檢查**。四個「凝聚高階結構」是它的骨架：

| # | 結構 | 一句話 |
|---|---|---|
| ① | `CondAnima` | 凝聚 Postnikov–Kan 有限同倫棧：逐層 `ℤ`-同倫秩 + 整數 bonding 矩陣；`p`-進 solenoid 的 `lim¹` 幽靈障礙 |
| ② | `CondSolidModule` | 固態凝聚模 `M^■`：離散 vs 緊緻的固態間隙、Mittag-Leffler ⇒ `Ext^{i>0}=0`、么半張量 `ℤ[S]^■ ⊗^■ ℤ[T]^■ ≅ ℤ[S×T]^■`、`p`-液態範數次可加性 `0 < p ≤ 1` |
| ③ | `CondSpectralSheaf` | 凝聚譜層：Grothendieck Čech 扭曲黏合障礙 `k¹ − r⁰` ＋ 扭曲 AHSS `d₃ = Sq³ + H·u(-)` |
| ④ | `CondAnalyticStack` | 舊名保留的有限模型健康報告；包含熱帶、P¹ 真性、有限 Laurent Čech 與 atomic BS2 的獨立檢查，**不是**已構造的 analytic stack |

外加兩個**範疇**（`CondCategory`、`CanonElimCategory`）、一份**雜湊鏈持久不變量賬本**（`CondInvariantLedger`）與**一項已否證猜想**（`Conj-2`）。

---

## 2. 檔案清單（4 檔，約 3.2k 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `profinite_solid.mbt` | 682 | 高階結構 ①② ＋ 範疇 ①（`CondCategory`）：`CondProfinite`、`CondChain`、`CondAnima`、`CondSolidModule`、`CondProMorphism` |
| `spectral_homotopy.mbt` | 1050 | 譜序列引擎、Serre 收斂、Steenrod–Adams `Ext_A(F₂,F₂)`、`2η = 0`、Koszul `Tor`、高階結構 ③（`CondSpectralSheaf`） |
| `analytic_stack_chiasm.mbt` | 715 | 高階結構 ④（`CondAnalyticStack`）、範疇 ②（`CanonElimCategory`）、`CondInvariantLedger`、五透鏡寫入、`Conj-2` |
| `quaternion_axis.mbt` | 802 | 共軛四元數、`Q₈/±1` 消元範疇、倒影／逆順向／反序列、瑕積分尾部界、RK4 常微分方程收斂與 Richardson 極限、精確守恆律賬本 |

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
| `adams_ext_f2_report` | 截斷 Steenrod 代數 `A_{≤d}` 的**最小自由分解** ⇒ `Ext_A^{s,t}(F₂,F₂)` 表；關鍵值 `Ext^{1,2} = 1`（`h₁ = η`）、`Ext^{2,3} = 0`（`h₀h₁ = 0`）；只有截斷 Ext 資料，**不能單憑它認證幾何 `2η = 0`** |
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
  topos_laurent_site_valid : Bool          // 舊名：實際只檢查 atomic BS2，不是 Laurent 景
  laurent_cech_exact : Bool                // Čech 正合（h⁰ = 1, h¹ = 0）
  archimedean_trace_rat : @exactalg.Rat    // 阿基米德跡／範數的精確有理界
  solid_completion_gap : Int32             // 固態 ℤ_p 完備化間隙
  bipolar_coherent : Bool
}
```
這個 record 合併多個獨立檢查，不構成 X 交換性或解析棧構造的證據。2026-11-14 已刪除把這些旗標當作橋定理的包裝。

**範疇 ② `CanonElimCategory`（規範消元範疇）**
* `CanonObject`：有限載體 + 顯式等價關係 `equiv[x·size + y]` + 規範化子 `canon[x]`（滿足 `[Ax-Canon-Idem]` 冪等與 `[Ax-Canon-Sound]` 完備）；
* `CanonMorphism`：**等變**映射（`x ~_dom y ⇒ map x ~_cod map y`），故 `canon_cod ∘ map` 唯一穿過 `canon_dom`；
* `canon_cat_id`、`canon_cat_comp`、`canon_morphism_valid` 驗證範疇公理。

**持久不變量賬本 `CondInvariantLedger`**
```moonbit
pub(all) struct CondLedgerEntry { seq; kind; values; parents; prev_hash; hash }
```
* `kind`：`0 = 觀測`、`1 = 導出定律`、`2 = 定理`；
* `cond_ledger_append` 逐筆雜湊鏈（`prev_hash` 串接），`cond_ledger_verify` 從頭重算整條鏈 ；這是摘要一致性檢查，不是數學推論可靠性或抗碰撞密碼學保證；
* `cond_ledger_derive_invariants` 由已驗證條目導出新不變量；`cond_ledger_audit_laws` 稽核全域定律。
* `conjecture/evolution_lenses.mbt` 的五個認識論透鏡**直接寫入這個賬本**（見 `evaluate_five_epistemic_lenses_into_ledger`）。

**已否證猜想（`[Conj-2]`）**

只保留有裁決的條目；無法定對錯的 `Conj-1`、`Conj-3`、`Conj-4`（僅有界檢查／門檻量測）已移除。

| 編號 | 內容 |
|---|---|
| `Conj-2` | 「`H₁`-繞數 = 0 就足以在任意 0-連通 HIT 中填充 2-盒」—— 被 `F₂` 非交換反例**否證** |

`cond_evaluate_new_conjectures` 給出 `CondConjectureStatus::RefutedWithWitness`（含反例見證），`conjecture/` 再把它提升為已決猜想圖譜的 `CONJ-02`。

### 3.4 `quaternion_axis.mbt` — 共軛四元數與凝聚中軸守恆

這一檔把連續旋轉與有限消元放進同一個**有邊界的**證書，而不把兩者混為一談：

* **對偶／蘊含**：共軛是反自同構，`conj(pq)=conj(q)conj(p)`；只有單位範數才蘊含 `q⁻¹=conj(q)`，非單位四元數是負對照。
* **倒影／逆順向**：純單位四元數給 Householder 倒影 `v↦nvn`（行列式 `-1`、二次回到自身）；單位四元數共軛旋轉 `v↦qvq*` 的行列式是 `+1`，以 `q*` 逆向還原。
* **大／細、離散／緊緻**：`Q₈` 的 8 個元素經正負號消元得到 4 個射影類；同一報告另檢查 profinite／緊緻點的固態間隙。緊緻性是所用 `S³`／profinite 模型的數學背景，程式只計算其有限見證，不宣稱由浮點證出拓撲緊緻性。
* **序列／反序列**：順向作用 `q₁,q₂,q₃` 對應乘積 `q₃q₂q₁`，其逆是相反次序的共軛乘積。
* **瑕積分與極限**：以 composite Simpson 計算 `∫₀ᴮ dx/(1+x²)`，再加上精確尾部 `atan(1/B)`；尾部上界為 `1/B`，極限目標是 `π/2`。
* **常微分方程與收斂**：對 `q'=qω/2` 使用**不再正規化**的 RK4，讓範數漂移保持可見；步數 `4,8,16,32` 的誤差序列檢查四階收斂，並以 Richardson 外插估計步長趨零的極限。
* **永續守恆的精確範圍**：16 筆整數範數觀測在 `CondInvariantLedger` 自動產生 3 條獨立 `ℤ`-線性守恆律；舊快照不被追加操作修改，竄改負對照會使雜湊鏈驗證失敗。這是有限離散模型的精確守恆與持久證據，**不是無限時間浮點守恆定理**。

---

## 4. 主檢核入口

| 函式 | 範圍 |
|---|---|
| `cond_check_structures_1_2_and_category_1()` | `[Ax-Cond-ExtDisc]` 餘積層下降、`CondAnima` 的 `lim¹` 分離、`CondSolidModule` 固態間隙與液態範數、`CondCategory` 公理 |
| `cond_check_structure_3_and_spectral_homotopy()` | Serre、Steenrod–Adams（`2η = 0`）、`CondSpectralSheaf`、Koszul `Tor` |
| `cond_check_structure_4_category_2_ledger_and_conjectures()` | 解析棧、`CanonElimCategory`、賬本鏈驗、四猜想 |
| `cond_check_federation_all()` | 本聯邦總開關（`cmd/showcase` 與 `bridge` 會呼叫） |
| `cond_quaternion_axis_report()` | 共軛／消元／倒影／逆順向／粗細／離散緊緻／反序列，以及瑕積分、ODE、極限與賬本總證書 |
| `cond_quaternion_axis_ledger()` | 16 筆精確觀測＋3 條導出守恆律＋1 筆定理摘要的持久雜湊鏈 |
| `cond_quaternion_axis_conserved()` | 給跨聯邦 law runner 使用的布林總開關 |

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

## 7. `T3` 輕核分離（`L1 condensed/core`）與 64× `@swar` 同倫前沿驗證

- **`condensed/core`（`pkgL1`，僅依賴 `gcd` + `accel-swar`）**：`CompactProfiniteTower`、構造性 Nöbeling 自由整數基底 `nobeling_unimodular_basis_zmat` / `verify_nobeling_free_solid_duality`（Bareiss `|det(B_ℤ)|=1`）、`rlim_zmat_endomorphism`，以及齊次分塊 `@swar` 64-bit Steenrod–Adams 極小分解 `adams_ext_swar_frontier_report()`（直抵八元數 Hopf `h₃=σ` 與 `h₁³=h₀²h₂` / `η³=4ν`）；`condensed/reexport_core.mbt` 完整重導出。

```bash
moon check --deny-warn --target wasm-gc
moon run cmd/showcase --target wasm-gc    # 印出 47/47 證書與 F2×F3×F6 三元橋中的 condensed 證書
```

---

## 8. 迭代 3：解塔、Teichmüller 提升與賬本 Merkle 承諾

新增於 `condensed/core/hensel_merkle.mbt`，經 `reexport_core.mbt` 重導出（詳見 `condensed/core/README.md` §6）：

* `cond_solution_tower_build(coeffs, q, levels)`：多項式在 `ℤ_q` 的根集作為射影極限，區分 Hensel 線與奇異根；
* `cond_solution_tower_stable`：Mittag-Leffler 穩定像塔，可接 Nöbeling 基底；
* `cond_teichmuller_lifts(q, levels)`；
* `cond_ledger_merkle_root` / `cond_ledger_inclusion_proof` / `cond_ledger_verify_inclusion`：`conjecture` 寫入賬本的定律現在可用 `O(log n)` 路徑個別驗證。

`cond_check_federation_all()` 多了第四個合取項 `cond_check_hensel_merkle_laws()`。

## 9. 2026-11-14：可重用的 P¹ Laurent Čech 維數

`cond_p1_cech_dimensions(twist, cutoff) -> (Int32, Int32)?` 建造 `(a,b) ↦ b-a` 的有限 Laurent 差分矩陣，在 F₇ 上獨立求秩，產出 H⁰/H¹。域為 `0≤cutoff≤16` 且 `|twist|≤cutoff`；其他輸入回傳 `None`。

對 n=-4..3、cutoff=4，結果依次 `(0,3),(0,2),(0,1),(0,0),(1,0),(2,0),(3,0),(4,0)`；cutoff=6 不變。`bridge` 的 K6-15 與 scheme 線叢引擎逐項比較，並驗 Serre/RR、proper≠acyclic。它不是 annulus 的 H⁰，亦不宣稱一般 p-adic 解析棧定理。`cond_analytic_stack_build` 的 Čech 欄位重用這個函式，`ring_name` 已改為真實有限模型標籤。`solid_completion_gap=0` 是舊相容常數，不是實際完成 solid Z_p 完備化的量測或證明。

上文早期檔名／規模及理論敘述保留作閱讀背景；當前實體配置以 `architecture.json` 和生成架構清單為準。
