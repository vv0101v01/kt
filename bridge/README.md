# `bridge/` — 上 V 頂點 `V₂`：星稜柱、`K₁₀ = 40/45 active（5 條中止）` 全配對構造性橋、三大三元／四元合流管線、51/51 證書 ＋ K₁₀ 獨立證書

> **架構位置**：`architecture.json` 中的 `bridge`，**Layer 8**（倒數第二層），依賴全部十大聯邦之上游公開介面（含 `meta` 四套件、`cubical-autonomy`、`cubical-structures`、`accel`、`condensed`、`scheme`、`topos`、`semiring-*`、`symlib`、`gcd`、`root`）。
> 角色：**雙 V 形的上頂點 `V₂`**，也是**唯一**被允許同時匯入全部十大聯邦的整合層（23 個 `.mbt` 檔，共 **9,731 行**）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/bridge`。執行入口：`cmd/showcase`。

---

## 1. 定位

下層每個聯邦只證明「自己的定理」；`bridge` 負責三件下層做不到的事：

1. **跨聯邦雙邊橋** —— 對 `n` 個聯邦的全部 `C(n,2)` 條邊給出**同一個量化見證**（不是「兩邊都對」，而是「兩邊算出的數字是同一件事」）；
2. **形狀定理** —— X 形交疊（`[T-X-Chiasmus]`）、雙 V 形、星稜柱；
3. **證書彙整** —— 把各聯邦原生證書壓成最小共通形狀 `BridgeCertificate`，輸出大一統總表。

聯邦數的演進史：`five_federation_plan.mbt`（K₅ = 10）→ `double_v_chiasm.mbt`（K₆ = 15 + X 交疊）→ `discovery_k7_bridges.mbt`（K₇ = 21 + Lakatos）→ `meta_k9_unification.mbt`（K₉ = 36 + F7→F9→F4→F1 晉升）→ **`ualg_federation_constructions.mbt`（K₁₀ = 45，第十聯邦 `ualg` 的 9 條構造性邊）＋ `structural_bridge_replacements.mbt`（第一波 6 條名義弱橋替換）＋ `nominal_bridge_elimination.mbt`（第二波 7 條名義弱橋替換）＋ `audit.mbt`（第三輪誠實審計：5 條名義邊中止、複合邊拆分、獨立合取項降級為輔助證書）**。

> **誠實計數（2026-11-12 審計後）**：`K₆ = 13/15 active`、`K₇ = 17/21 active`、`K₉ = 31/36 active`、`K₁₀ = 40/45 active`；`ualg` 9/9 不變。被中止的邊仍留在註冊表供追溯，但 `holds=false` 且**不計入** verified。

---

## 2. 檔案清單（23 檔，9,731 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `audit.mbt` | 199 | **第三輪誠實審計 overlay**：`bridge_suspension_reason` / `suspended_bridge_ids` / `apply_bridge_audit`（中止邊強制 `holds=false` 且不得計入 verified）、`bridge_audit_counts`、`verify_bridge_auxiliary_theorems`（從複合邊拆出的獨立定理）、`replace_k5_10_zariski_nilpotent_topos`、`replace_k9_32_nerve_h1_bareiss` |
| `certificates.mbt` | 141 | 最小共通證書 `BridgeCertificate`；各聯邦原生證書的轉換器；`bridge_certificates()` 總證書列（含輔助定理） |
| `five_federation_plan.mbt` | 769 | 五聯邦描述子 + `K5-01..K5-10`（`C(5,2) = 10`）全橋 + 五聯邦五邊形大一統定理；`K5-10` 已拆為 Zariski 冪零不變性主邊 |
| `double_v_chiasm.mbt` | 392 | 六聯邦描述子、`K6-11..K6-15`（實際含 `K5-*` 共 15 條；**13 active / 2 suspended**）、`[T-X-Chiasmus]` X 形交疊、`DoubleVArchitectureReport` |
| `discovery_k7_bridges.mbt` | 404 | 七聯邦描述子、`K7-16..K7-21`（共 21 條；**17 active / 4 suspended**）、`SevenFederationStarPrismReport` |
| `accel_bridge.mbt` | 314 | `@accel` ↔ F1/GCD/algebra/trop/tensor 的逐位等價橋 |
| `logic_theory_translation.mbt` | 517 | 邏輯理論轉譯引擎：CCHM 面 → Zariski 理想、`DTerm` → 幾何公式、Glivenko、四柱規範形式合一、Z/2Z-主叢 ↔ 二次平展 Kähler ↔ Galois 橋 |
| `geometry_logic_atlas.mbt` | 899 | **18 項精細圖譜 `ATLAS-01..18`**：每列都同時給「正向定理見證」＋「非平凡判別對照見證」 |
| `grand_unification.mbt` | 401 | 六柱圓／射影空間／Galois 大一統定理；`grand_unification_certificates()`；`run_grand_unification_system()` |
| `graph_symmetry.mbt` | 355 | `semiring` 的加權有向 CSR 圖 ↔ `symlib` 的著色自同構：真對稱群、群平均投影子、雙通道權重精確過濾 |
| `permutation_bridge.mbt` | 238 | `symlib.Perm` ↔ `cubical.CMat` 置換矩陣／有限宇宙 `Wiring`／一階 `Equiv` |
| `tropical_bridge.mbt` | 239 | 熱帶行列式 ↔ 置換最佳指派；`ℚ((t))` 的 `t`-進賦值 ↔ `@strop` 的 min-plus（Kapranov–Berkovich） |
| `face_semiring.mbt` | 174 | `cubical.Face` 商去語義等價（ROBDD 規範形）後，實作 `Semiring`/`IdempotentSemiring`/`StarSemiring`/`OrderedSemiring` |
| `free_category.mbt` | 95 | DAG 的自由範疇 → `@sym.FinCat` 的內部建構器（`free_category_to_fincat`） |
| `rotation_axis_bridge.mbt` | 478 | 共軛四元數凝聚中軸 ↔ Jacobi／Jordan／Hopf／Tamari 四族旋轉；逐族關係對齊、消元前後 `previous/current/deltas` 數值比較，以及 `11040→552→0` 相干角消元總報告 |
| `intuitive_conjecture_lab.mbt` | 413 | 五條由實際結構直覺提出的猜想與反例攻擊：1 條有界倖存、4 條反例後修正；完整人讀報告見 [`INTUITIVE_CONJECTURES.md`](INTUITIVE_CONJECTURES.md) |
| `malcev_presheaf_autonomy_bridge.mbt` | 67 | 構造性泛代數自主類型論 × 雙重否定核 `j(x)=¬¬x` 預層層化模板 × 64-bit SWAR 立方退化樹（`64594 + 942 = 65536`）× 54 項高階立方結構跨聯邦驗證橋 |
| `meta_k9_unification.mbt` | 435 | **九聯邦完全圖 `K₉ = 31/36 active（5 suspended）`**（`K8-22..28` + `K9-29..36`；其中 11 條弱橋已改呼叫 `structural_bridge_replacements.mbt` / `nominal_bridge_elimination.mbt`）與 **`F7 → F9 → F4 → F1` 四聯邦定理自動晉升管線（探索性，不再作為 K9-35 橋或總閘）** |
| `f2_f3_f6_triad_bridge.mbt` | 207 | **`F2 ↔ F3 ↔ F6` 對稱—半環—凝聚三元合流橋**（`A₅` 序對 2-軌道 Burnside Möbius ↔ Four-Russians/M4RI/Hopcroft/Johnson/3D 牛頓細分 ↔ 構造性 Nöbeling 自由基底與 64× `@swar` Steenrod–Adams `η³=4ν`） |
| `frontier_7pillars_unification.mbt` | 245 | 七支柱五元橋（F1×F3×F4×F8×F9）：MTT 2-函子、Dual QTT SWAR、QIIT CwF 路徑、Artin Orton–Pitts、Merkle 記憶化雙向歸納 |
| `ualg_federation_constructions.mbt` | 1045 | **第十聯邦 `ualg` 的 9 條構造性跨聯邦邊 `K10-37..45`**：面格↔雙軌 CCHM BDD、B₂ marks/Burnside、Cg=Boolean-Kleene 最小不動點、□² 開集↔Sieve64 Heyting/¬¬、Stanley–Reisner/Hilbert、平移譜↔Smith 餘核 coinvariants、SWAR 蘊涵格、GF(2) RREF Betti、同餘/Mal'cev↔meta 關係代數；每條皆含量化見證＋獨立路徑＋負對照 |
| `structural_bridge_replacements.mbt` | 496 | **6 條名義弱橋的數學構造替換**：`K8-22` 16 元素布林面代數↔ROBDD sat_count/apply 同態、`K8-24` 四路熱帶 APSP/Kleene 一致＋負環、`K8-27` Ozaki-II CRT==schoolbook==BigInt ZMat（>2^53）＋SNF、`K9-29` STLC βη NBE↔DTerm 依賴 NBE 編譯、`K9-31` 一元 Horn 最小模型==Boolean Kleene star（Knaster–Tarski）＋二元 body 負控制、`K9-34` Möbius 符號單值化↔coinvariants([-1]) 2-撓 |
| `nominal_bridge_elimination.mbt` | 1208 | **第二波 7 條名義弱橋的數學構造替換**：`K5-02` □³ 面格覆蓋關係→Kleene 閉包==CCHM 序＋冪零 Neumann 級數數極大鏈（2³·3!=48=\|B₃\|）、`K5-05` Burnside 閉路軌道 census（計數半環 tr((A\|Fix(g))^k)）、`K8-23` S₃ 軸作用於全部 6561 張量＋SWAR 超行列式不變性＋Burnside==union-find、`K8-26` rank≤1 locus==Segre 仿射錐（1+(q−1)\|P¹\|³=129）、`K8-28` SWAR bitplane 蘊含格==窮舉語義（25 對＋最小反例一致＋篡改偵測）、`K9-30` 同餘閉包==軌道分割==rank==Burnside、`K9-33` Macaulay 矩陣 Bareiss rank==Gröbner 標準單項式 Hilbert 函數 |

---

## 2.1 名義橋消除（兩波共 13 條）與硬性原則

**原則（硬性）**：一條聯邦邊 `holds` **不得**是兩個*互相獨立*的健康報告布林合取
（`bool && bool`）。每條邊必須至少有一個**兩個數學結構相互作用而生的構造**，
並附**量化見證**與**負控制**（把構造換成天真版本時負控制必須失敗）。

* **第一波**（`structural_bridge_replacements.mbt`，6 條）：`K8-22 / K8-24 / K8-27 / K9-29 / K9-31 / K9-34`。
* **第二波**（`nominal_bridge_elimination.mbt`，7 條）：

| 邊 | 被消除的名義式 | 新構造（兩結構相互作用） | 負控制 |
|---|---|---|---|
| `K5-02` Cubical×Semiring | `check_face_semiring_bridge() && check_tropical_bridges()` | □³ 的 27 個面（CCHM 餘纖維格）→覆蓋關係；Boolean Kleene 閉包（blocked FW 與 Lehmann 兩算法）== `cchm_face_le` 全 729 對；計數半環上覆蓋矩陣冪零 `C⁴=0`，Neumann 級數數出 `2³·3! = 48` 條極大鏈（= 超八面體群 `B₃` 階） | 對稱化後閉包變全 1（序塌縮）、`C_sym⁴≠0`（star 發散） |
| `K5-05` Symlib×Semiring | `check_graph_symmetry_bridges() && check_free_category_bridge()` | `Aut(C₄)=D₄`（Schreier–Sims，8 元）作用於閉路空間；被 `g` 固定的閉路必全落在 `Fix(g)`，故 `tr((A|_{Fix(g)})^k)`（計數半環冪）經 Burnside 平均 == 暴力軌道枚舉（k=1..4） | `(01)∉Aut`：其像不是路（顯式見證），天真平均 5 ≠ 真軌道數 1 |
| `K8-23` Accel×Symlib | `\|S_3\|==6 && gf3_sub64(Δ,Δ)==0` | `S₃` 軸作用於全部 6561 個 `F_3^{2×2×2}` 張量；SWAR 超行列式 sweep 在**每一個**張量上對 6 個置換不變；Burnside `(1/6)Σ\|Fix\| = 1485` == union-find 軌道數 | 單項泛函 `t↦t[0,0,1]` 非不變（顯式 code），而同一 code 的 Det 不變 |
| `K8-26` Accel×Scheme | `det_zero==2241 && det_zero==atlas && \|P²(F_3)\|==13` | rank≤1 locus == Segre `σ(P¹×P¹×P¹)` 的仿射錐；由 scheme functor-of-points 取 `\|P¹(F_3)\|=4` 導出 `1+(q−1)·4³=129` == atlas census；projectivised `64` 與 `1120` 對帳；`\|P²(F_3)\|=(q³−1)/(q−1)=13` 亦為導出 | `V(Det)⊋Segre 錐`：rank2 且 Det=0 見證 code 12；**Det=0 也不等價 rank≤2**：rank3 且 Det=0 見證 code 93（1536 個） |
| `K8-28` Accel×Discovery | `check_discovery_kernel_laws() && det_zero==atlas.det_zero_count` | 5 個謂詞在 6561 樣本上的 SWAR bitplane 蘊含格（硬體 `ctz` 反例搜尋）== **獨立窮舉語義掃描** 全 25 對，且最小反例索引逐一相同、反例直接求值成立 | 天真 `Det=0⇒rank≤1` 被 code 12 否證；bitplane 篡改 1 bit 即被偵測（cex 0） |
| `K9-30` Meta×Symlib | `meta_laws_batch_ok(...) && \|Aut(C_4)\|==8` | `Aut(K₃⊔K₂)` 生成元圖的等價閉包（`@mcore.ua_equiv_join_closure`）== symlib 軌道分割；類數 == 軌道指示矩陣的 `rank_Q` == 不動子空間維 == Burnside 平均 | 刪一個生成元 → 閉包嚴格變細（4 類 > 2 類），且為真子關係 |
| `K9-33` Meta×Scheme | `cauchy7_cert && rank==3 && \|P²(F_3)\|==13` | `Q[x,y]/⟨x²+y²−1, x−y⟩` 的仿射 Hilbert 函數由 Macaulay 矩陣的**無分數 Bareiss rank** 算出（`HF = #monomials − rank`），與 Gröbner 標準單項式計數在 d=0..3 全等（1,2,2,2），每度攜 Bareiss 證書 | 胖點 `⟨x²,xy,y²⟩` HF=3 vs 其約化 `⟨x,y⟩` HF=1：rank 偵測到冪零（點集看不到） |

* **同輪另修兩條「假陳述／外掛布林」**：
  * `K7-17`：舊版把 `Graph::cycle(5)` 誤標為 `Aut(K_4)`（實為 `\|Aut(C_5)\|=10=\|D_5\|`，而 `\|Aut(K_4)\|=24`），且把無關的 invariance 旗標合取進來。新版改為 **S₃ 軌道上的張量秩分層**：秩在每個軌道上常值（窮舉 6561×6）、軌道 census 1485、秩直方圖 `[1,40,860,584]`、自由軌道 `\|orb\|·\|stab\|=6` 且穩定子對合成封閉；負控制為 **mode-0 flattening rank 在軌道內變動**（code 12：1≠2）。
  * `K6-15`：舊版外掛了無關的 `@exactalg` Berkowitz-CRT 健康旗標。新版移除，改為 condensed Laurent(Tate) 黏合 `h⁰=1,h¹=0` 與 scheme `O(0)` Čech 對帳，並把同一 Čech 引擎推過 `n=-4..3` 驗證 **Serre 對偶** `h¹(O(n))=h⁰(O(-2-n))` 與 **Riemann–Roch** `χ=n+1`；負控制為「proper ⇒ acyclic」之謬誤（`P¹` proper 但 `h¹(O(-2))=1`）。

* **第三輪誠實審計（`audit.mbt`，2026-11-12）**：逐條覆核全部 45 條 K₁₀ 邊後，
  **中止（suspend）5 條**無法用真構造支持的邊，強制 `holds=false` 且不計入 verified：

| 中止邊 | 理由（誠實） |
|---|---|
| `K6-11` Condensed×Cubical | 截斷 Adams Ext 與 Brunerie π₄(S³) 之間**沒有構造出的比較映射**；`Ext^{2,3}=0` 本身不是 `2η=0` 的證明，solenoid lim¹ 檢查亦獨立 |
| `K6-13` Condensed×Semiring | 熱帶折點與 p-liquid 次可加性是**獨立檢查**，無共享物件或傳輸定理 |
| `K7-18` Discovery×Semiring | Viro 平手遮罩與張量蘊涵格**獨立**，無超域結構傳輸蘊涵序 |
| `K7-21` Discovery×Condensed | 雜湊鏈知識帳本與 Clifford 餘圈中心**獨立**；密碼式封裝不是數學橋 |
| `K9-35` Meta×Discovery | 晉升管線各階段**缺乏從發現蘊涵到 Horn/聚焦證明的可靠性定理**；符號規則使用無關型別項 |

  同輪**保留並強化**（非中止）：`K6-14`（Serre 底/纖維 Betti 全量對帳 topos 神經）、
  `K6-15`（移除冒稱 Laurent diamond 的 BS₂ 原子景合取項；保留 Laurent Čech O(0) 對帳＋Serre/RR）、
  `K7-19`（VR(C₄)≃S¹ 神經＋非交叉森林層景）、`K10-41`（□² 子複形→Stanley–Reisner 理想→Hilbert）。
  修正誤名：`rlim_zmat_endomorphism` → **`coinvariants_zmat_endomorphism`**（`coker(I−f)` 的 Smith 餘核，**不是**逆極限）。
  因此目前 honest 計數為 **K₆=13/15、K₇=17/21、K₉=31/36、K₁₀=40/45 active**，ualg 9/9 不變。

* **複合邊拆分**：`K5-10`（Topos×Scheme）不再把三個定理合取在同一邊。主邊只保留
  **Zariski classifying topos 冪零不變性 vs 點函子**（`replace_k5_10_zariski_nilpotent_topos`）；
  二次 étale torsor Galois 與 excision/blow-up 已有獨立 translation 證書。
  另把 `K5-03` 的 Glivenko、`K5-06` 的反序 S¹ 神經、`K7-16` 的 wedge filler、`K7-20` 的
  Hironaka–Serre 曲線轉移等**獨立合取項**拆出為 `verify_bridge_auxiliary_theorems()` 輔助證書，
  不再 inflate 雙邊橋。證書總表因此由 48 增至 **51/51**。

## 3. 證書的最小共通形狀

```moonbit
pub(all) struct BridgeCertificate {
  source : String       // "cubical" / "symlib" / "semiring" / "atlas" / "bridge/unification" / "auxiliary/*" …
  name   : String       // 定理或定律名（對應 [T-…] 標籤）
  ok     : Bool
  detail : String       // 量化見證（"K7=17/17 active", "Ext^{1,2}=1 <-> |beta|=2" …）
}
```
轉換器：`certificate_of_cubical`、`certificate_of_symlib`、`certificate_of_semiring_law`。
`certificates_all_ok` 與 `certificate_summary` 供 `cmd/showcase` 印總表；`root` 的定理總表（139 條）與本檔的 51 條大一統／輔助證書是兩套互補視角；K₁₀ 另發獨立證書（40/45 active 橋、9/9 ualg 邊、13 替換）。

---

## 4. K₇ 的 21 條橋（17 active / 4 suspended；`discovery_k7_bridges.mbt`）

`verify_k7_federation_bridges()` 回傳 `Array[FederationPairBridge]`，每條含 `id`、`bridge_theorem`、`quantitative_witness`、`holds`。

| 世代 | 邊 | 代表見證 |
|---|---|---|
| `K5-01..10` | `cubical`·`symlib`·`semiring`·`topos`·`scheme` | 例如 `Face` 商格 ↔ 冪等半環定律；`symlib` 的 Burnside ↔ `semiring` 的 `ℤ_m` 冪集；`Gröbner` 消元 ↔ `cubical` 的 NbE 正規形 |
| `K6-11` | `Condensed ↔ Cubical` | **[SUSPENDED]** 無構造比較映射；Ext 與 Brunerie 獨立 |
| `K6-12` | `Condensed ↔ Symlib` | `CanonElimCategory` 在 `ℤ/2ℤ` 作用 `(0 1)(2 3)` 下的軌道數 `2` = `@sym.gset_burnside` |
| `K6-13` | `Condensed ↔ Semiring` | **[SUSPENDED]** 熱帶折點與 liquid 次可加性獨立 |
| `K6-14` | `Condensed ↔ Topos` | Serre SS 底 `β(S²)=[1,0,1]`、纖維 `β(S¹)=[1,1]` **全量**對帳 topos 神經；`E₂=4→E₄=2` 收斂到 S³ |
| `K6-15` | `Condensed ↔ Scheme` | `Spa(ℚ⟨T,T⁻¹⟩, ℤ_p)` 的 Laurent 黏合 `h⁰ = 1, h¹ = 0` ↔ `ℙ¹` `O(0)` Čech＋Serre 對偶 `h¹(O(n))=h⁰(O(-2-n))`＋RR；負控制 proper≠acyclic |
| `K7-16` | `Discovery ↔ Cubical` | 多邊形翻轉 `C₃ = 5`、`C₄ = 14` ↔ `assoc_fvector(4) = [5, 5, 1]` 的 Stasheff 面向量 |
| `K7-17` | `Discovery ↔ Symlib` | S₃ 軌道秩分層（6561×6 窮舉）：秩軌道常值、orbits=1485、hist `[1,40,860,584]`、軌道–穩定子＋穩定子封閉；負控制 mode-0 flattening rank 軌道內 1≠2 |
| `K7-18` | `Discovery ↔ Semiring` | **[SUSPENDED]** Viro 平手與蘊涵格獨立 |
| `K7-19` | `Discovery ↔ Topos` | 非交叉弦森林景（`4` 邊形上 `48` 個開集）的 Grothendieck 等化器黏合；`VR(C₄,1)` 鏈／上鏈對偶 ≃ S¹ 神經 |
| `K7-20` | `Discovery ↔ Scheme` | 離散 Radon 平面 `𝔸²(𝔽₃)`（9 點 12 線 4 方向）完備化為 `ℙ²(𝔽₃)`：`\|ℙ²(₃)\| = 9 + 4 = 13` |
| `K7-21` | `Discovery ↔ Condensed` | **[SUSPENDED]** 帳本雜湊鏈與 Clifford 中心獨立 |

`verify_seven_federation_star_prism(k7_precomputed)` 把它們與 X 交疊、雙 V、7 條已決猜想合成 `SevenFederationStarPrismReport`（`cmd/showcase` 的 `K7=17/17 active（21 attempted, 4 suspended）` 就來自這裡）。

---

## 5. X 形交疊與雙 V 形（`double_v_chiasm.mbt`）

```text
                    V₂ 上頂點：@bridge
        ┌────────────── 星稜柱 + 硬體加速大一統（Layers 7–8）──────────────┐
         ╱        ╱        ╱        ╱        ╲        ╲        ╲        ╲
    F1 cubical  F2 symlib  F3 semiring  F4 topos  F5 scheme  F6 condensed  F7 discovery  F8 accel
         ╲        ╲        ╲        ╲        ╱        ╱        ╱        ╱
        ────────────── 對角線 D₁ 與 D₂ 在 @condensed + @gcd 交叉 ──────────────┘
                    V₁ 下頂點：@gcd（Layer 0）
```

`[T-X-Chiasmus]` 的兩條對角線：
* **`D₁`（離散語法 ↔ 非阿基米德賦值）**：`cubical` 的 `Face`/`DTerm` 語法 → `@strop` 的熱帶賦值 → `@gcd` 的 `p`-進 `v_p`；
* **`D₂`（連續分析 ↔ 高階同倫）**：`@scheme` 的 `ℚ((t))` Laurent → 凝聚 `CondAnalyticStack` → `cubical` 的 `π₄(S³)`。

`verify_x_overlap_chiasmus()` 驗證兩條對角線在 `X`-樞紐（`@condensed` + `@gcd`）**乾淨相交**（共享不變量三元組相同），`DoubleVArchitectureReport` 則記錄 `lower_v_gcd_apex_ok`、`six_federations_verified/6`、`k6_bridges_verified/13 active（15 attempted, 2 suspended）`、`seven_boundaries_breakthrough_ok`。

### 5.1 四族旋轉的關係對齊（`rotation_axis_bridge.mbt`）

`verify_rotation_axis_bridge()` 以 `@condensed.cond_quaternion_axis_report()` 為共同參考，再呼叫四族真正的上游實作：

| 旋轉族 | 實際檢查的關係 | 量化見證 |
|---|---|---|
| Jacobi 酉區間旋轉 | 伴隨／逆元蘊含、8→16 bits 粗細區間、依序相似變換 | `U†U-I` 區間含零；非對角平方上界不增；兩種精度證書各自 sound |
| Jordan 實旋轉塊 | 逆順向、倒影負對照、有限離散階 | `R⁴=I`、`R²≠I`、`RR³=R³R=I`；`det R=1` 而倒影 `det=-1` |
| Hopf 相位旋轉 | 共軛相位、逆順向、相位合成與反序列、緊緻載體代表元 | `θ=0.37`、`φ=-0.11`；`S³/S²` 範數與纖維不變量，並跑精確有理及數值雙路 |
| Tamari 結合多面體旋轉 | 左右逆順向、有限圖、序列／反序列路徑 | `K₃` 根旋轉往返；`K₄` 有 5 頂點、5 條旋轉邊且圖連通 |

這是一張**關係對齊表**，不是宣稱四族物件彼此同構；不適用於某族的關係不會被強行填入。共同的瑕積分、RK4／Richardson 極限與 3 條精確守恆律由凝聚層提供。本輪固定消元前基準，逐族公開 `previous/current/deltas`，以 `1e-12` 為回歸容差並拒絕 NaN／Inf；相干角報告逐項列舉 `11040`，第一段消去 `10488` 後餘 `552`，第二段把這 `552` 全部解析到 `276` 個規範類，故未解角為 `0` 且類重數仍總和 `11040`。`rotation_axis_certificate()` 是獨立證書，不計入歷史 **51/51**，因此沒有暗改既有里程碑；`cmd/showcase` 另印本橋的 PASS 行並納入總成功條件。

---

## 6. 幾何—邏輯圖譜 `ATLAS-01..18`（`geometry_logic_atlas.mbt`）

```moonbit
pub(all) struct GeometryLogicAtlasEntry {
  id; domain;
  geometric_structure;      // topos / scheme 的具體不變量
  logical_counterpart;      // 型別論 / 邏輯的對應物
  correspondence_theorem;
  witness_holds;            // 正向見證
  contrast_holds;           // 判別性對照見證（必須也成立！）
  quantitative_summary;
}
```
每列都要求**兩個**見證同時成立：正向（對應確實存在）＋ 對照（這對應不是空洞的、有東西真的被區分開）。代表性列：

| ID | 幾何側 | 邏輯／型別側 |
|---|---|---|
| `ATLAS-03` | `T²` 的杯積秩 1 | 與 `S¹∨S¹S²`（秩 0）的判別 |
| `ATLAS-07` | 開／閉子拓撲斯切除（co-Heyting） | Glivenko 雙否定翻譯 |
| `ATLAS-11` | Zariski 拓撲不變性 | 點函子的無窮小敏感（`X_red` vs `X`） |
| `ATLAS-14` | `ℙ¹` 的 Serre 對偶 `h¹(O(−2)) = 1` | 線性對偶與伴隨 |
| `ATLAS-18` | Chow 動機 `h(ℙ¹) = 1 ⊕ L` | 型別和 `Unit ⊔ Bool` 的分解 |

---

## 7. 三個「小」橋，技術含量不低

### 7.1 `permutation_bridge.mbt`
* `permutation_matrix(p)`：`symlib.Perm` → `cubical.CMat`（列 `i` 的 1 在欄 `p(i)`）；
* `average_permutation_matrices(perms)`：**完整**有限置換群的平均 ⇒ 到群不變子空間的正交投影（不完整枚舉時**不作此宣稱**）；
* `perm_wiring` / `signed_perm_wiring` / `perm_of_wiring` / `wiring_output_signs`：`Perm` ↔ 有限宇宙 `Wiring`（含否定旗標）；
* `perm_equiv(p)`：置換提升為 `cubical` 的一階 `Equiv`；
* `check_perm_wiring_bridge()`：`S₄` 全部 `24` 個置換都可編成 well-formed wiring，在全部 `16` 個四 Bool 值上逐葉實現同一置換，再讀回同一置換。

### 7.2 `face_semiring.mbt`
`FaceClass::of_face(face, nvars)` **先過 `bdd_of_face`**：裸 `Face` AST 的結構相等**不是**語義相等（`φ ∨ φ ≠ φ` 在語法上），商去之後才是布林代數。於是 `⊕ = ∨`、`⊗ = ∧`、`a* = ⊤`、`meet/top` 有意義，並可用 `@semialg` 自己的定律檢查器核驗（`face_semiring_law_report()` 特別釘住 `φ∨φ = φ`、`⊤∧φ = φ`、`(i=0) = ¬(i=1)`）。

### 7.3 `tropical_bridge.mbt`
* `assignment_cost` / `tropical_optimal_assignments` / `tropical_matrix_symmetries`：把 `@strop.trop_det` 的最佳指派用 `@sym.Perm` 表達，並驗「最佳集在對稱共軛下封閉」；
* `exact_permanent_int64` / `exact_determinant_int64`：以 `@exactalg` 精確有理算永久式與行列式；
* `rat_padic_valuation` / `qpoly_tropicalize_padic`：`ℚ` 的 `p`-進賦值（零 → `None`，對應熱帶 `+∞`）把 `QPoly` 熱帶化成 `UniPoly`；
* `verify_kapranov_tropical_laurent_bridge()`：把 `@scheme` 用於真判定的 `v_t : ℚ((t))^× → ℤ` 與 `@strop` 的 min-plus 直接對接（Kapranov–Berkovich）。

---

## 8. `accel_bridge.mbt` 與大一統

```moonbit
pub fn verify_accel_hardware_bridge() -> @accel.AccelFederationReport
pub fn accel_hardware_certificate() -> BridgeCertificate
```
把 `@accel` 的 CPU SWAR / WebGPU 逐位等價檢驗（對 `@gcd`、`@face_bdd`、`@algebra`、`@semiring/trop`、`@tensor` 的主定義）納入證書列，使 `Cmd-showcase` 的 **51/51** 包含硬體加速部分。

`grand_unification.mbt` 的 `verify_six_pillar_circle_sphere_unification()` 是六柱定理：`S¹`、`S² ≃ ℙ¹(ℂ)`、`ℙ²`、`ℤ/2ℤ`、`S₃` 的基本拓撲／同調／Galois／熱帶／動機不變量在六個 pillar 中互相吻合。`run_grand_unification_system()` 回傳 `GrandUnificationReport`。

---

## 9. 範例

```moonbit
// 1) 全部 21 條 K_7 橋（17 active / 4 suspended）
let edges = @bridge.verify_k7_federation_bridges()
for e in edges { println(e.id, e.holds, e.quantitative_witness) }

// 2) X 交疊與雙 V
let x  = @bridge.verify_x_overlap_chiasmus()
let dv = @bridge.verify_double_v_architecture(k7_precomputed=Some(edges))
println(x.chiasm_commutes, dv.k6_bridges_verified)

// 3) 18 項幾何—邏輯圖譜
let atlas = @bridge.build_fine_grained_geometry_logic_atlas()
for row in atlas { println(row.id, row.witness_holds, row.contrast_holds) }

// 4) 四族旋轉 × 共軛四元數凝聚中軸
let rotations = @bridge.verify_rotation_axis_bridge()
assert_true(rotations.holds)             // 4/4，含 3/3 精確守恆律

// 5) 證書總表（51 條；旋轉中軸證書獨立輸出）
let certs = @bridge.bridge_certificates()
assert_true(@bridge.certificates_all_ok(certs))

// 6) 九聯邦 K_9 (31/36 active, 5 suspended) 全配對橋；晉升管線僅探索性報告
let k9 = @bridge.verify_k9_meta_discovery_topos_unification()
assert_true(k9.all_holds)                // 9/9 聯邦 · K9=31/36 active

// 7) 十聯邦 K_10 (40/45 active, 5 suspended) 構造性全配對橋（含 ualg 9 條邊與 13 條名義橋替換）
let k10 = @bridge.verify_k10_ten_federation_unification()
assert_true(k10.all_holds)               // 10/10 聯邦 · K10=40/45 active · ualg=9/9
for e in @bridge.verify_k10_ualg_federation_bridges() { println(e.id, e.holds, e.quantitative_witness) }
for e in @bridge.verify_structural_bridge_replacements() { println(e.id, e.holds, e.quantitative_witness) }
for e in @bridge.verify_nominal_bridge_elimination() { println(e.id, e.holds, e.quantitative_witness) }

// 8) 審計 overlay：中止邊與輔助定理
for id in @bridge.suspended_bridge_ids() { println(id, @bridge.bridge_suspension_reason(id)) }
for c in @bridge.verify_bridge_auxiliary_theorems() { println(c.name, c.ok) }
```

---

## 10. 依賴規則（硬性）

* **本套件可匯入任何下層套件**，下層**一律禁止**匯入 `bridge`（`agent.v2.md` §二、`tools/arch_check.py` 會攔截）。
* `bridge` 只做「比較與彙整」，不重新實作演算法：任何見證都必須呼叫上游套件的公開函式（例如 `K7-17` 必須用 `@sym.PermGroup::symmetric` 與 `@tensor.f3_tensor222_atlas_build`，`verify_f8_f5_f1_triad_bridge()` 直接聯動 `@swar`、`@scheme`、`@algebra` 與 `@cub` 交叉核驗 M4RI 布林 F4 ↔ ROBDD、CCHM 上纖維化 ↔ Zariski 根理想、多素數模 F4 ↔ Buchberger、以及 HVM2 `INetArena` 強合流 ↔ 依賴型 NbE；`verify_f2_f3_f6_triad_bridge()` 直接聯動 `@sym`、`@sapp`、`@gcd` 與 `@condensed` 交叉核驗 Holt 子群格／Burnside Möbius／非薄群胚米田、半環全目標 `wasm-gc` 套件、模有界 HNF／Nöbeling 自由對偶與 `h₃=σ, η³=4ν`）。

---

## 11. 驗證

```bash
moon run cmd/showcase --target wasm-gc               # 10/10 聯邦 · K10=40/45 active（5 suspended；K9=31/36 active 歷史子圖）· ualg 9 構造邊 · 13 名義橋替換（6+7） · F8↔F5F1 + F2↔F3↔F6 + 七支柱五元橋 · 51/51 證書 + K10 證書 + 中止理由
python3 tools/arch_check.py                          # 確認沒有任何下層反向匯入 bridge
```
