# `bridge/` — 上 V 頂點 `V₂`：星稜柱、`K₉ = 36/36` 全配對橋、三大三元／四元合流管線與 47/47 大一統證書

> **架構位置**：`architecture.json` 中的 `bridge`，**Layer 8**（倒數第二層），依賴全部九大聯邦之上游公開介面（含 `meta` 四套件、`cubical-autonomy`、`cubical-structures`、`accel`、`condensed`、`scheme`、`topos`、`semiring-*`、`symlib`、`gcd`、`root`）。
> 角色：**雙 V 形的上頂點 `V₂`**，也是**唯一**被允許同時匯入全部九大聯邦的整合層（18 個 `.mbt` 檔，共 **6,627 行**）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/bridge`。執行入口：`cmd/showcase`。

---

## 1. 定位

下層每個聯邦只證明「自己的定理」；`bridge` 負責三件下層做不到的事：

1. **跨聯邦雙邊橋** —— 對 `n` 個聯邦的全部 `C(n,2)` 條邊給出**同一個量化見證**（不是「兩邊都對」，而是「兩邊算出的數字是同一件事」）；
2. **形狀定理** —— X 形交疊（`[T-X-Chiasmus]`）、雙 V 形、星稜柱；
3. **證書彙整** —— 把各聯邦原生證書壓成最小共通形狀 `BridgeCertificate`，輸出大一統總表。

聯邦數的演進史就寫在這兩個檔案裡：`five_federation_plan.mbt`（K₅ = 10 條 + 五聯邦五邊形定理）→ `double_v_chiasm.mbt`（K₆ = 15 條 + X 交疊）→ `discovery_k7_bridges.mbt`（K₇ = **21 條** + Lakatos 迴圈）。

---

## 2. 檔案清單（16 檔，約 5.5k 行）

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `certificates.mbt` | 137 | 最小共通證書 `BridgeCertificate`；各聯邦原生證書的轉換器；`bridge_certificates()` 總證書列 |
| `five_federation_plan.mbt` | 798 | 五聯邦描述子 + `K5-01..K5-10`（`C(5,2) = 10`）全橋 + 五聯邦五邊形大一統定理 |
| `double_v_chiasm.mbt` | 352 | 六聯邦描述子、`K6-11..K6-15`（實際含 `K5-*` 共 15 條）、`[T-X-Chiasmus]` X 形交疊、`DoubleVArchitectureReport` |
| `discovery_k7_bridges.mbt` | 291 | 七聯邦描述子、`K7-16..K7-21`（共 21 條）、`SevenFederationStarPrismReport` |
| `accel_bridge.mbt` | 22 | `@accel` ↔ F1/GCD/algebra/trop/tensor 的逐位等價橋 |
| `logic_theory_translation.mbt` | 577 | 邏輯理論轉譯引擎：CCHM 面 → Zariski 理想、`DTerm` → 幾何公式、Glivenko、四柱規範形式合一、Z/2Z-主叢 ↔ 二次平展 Kähler ↔ Galois 橋 |
| `geometry_logic_atlas.mbt` | 878 | **18 項精細圖譜 `ATLAS-01..18`**：每列都同時給「正向定理見證」＋「非平凡判別對照見證」 |
| `grand_unification.mbt` | 393 | 六柱圓／射影空間／Galois 大一統定理；`grand_unification_certificates()`；`run_grand_unification_system()` |
| `graph_symmetry.mbt` | 355 | `semiring` 的加權有向 CSR 圖 ↔ `symlib` 的著色自同構：真對稱群、群平均投影子、雙通道權重精確過濾 |
| `permutation_bridge.mbt` | 238 | `symlib.Perm` ↔ `cubical.CMat` 置換矩陣／有限宇宙 `Wiring`／一階 `Equiv` |
| `tropical_bridge.mbt` | 239 | 熱帶行列式 ↔ 置換最佳指派；`ℚ((t))` 的 `t`-進賦值 ↔ `@strop` 的 min-plus（Kapranov–Berkovich） |
| `face_semiring.mbt` | 173 | `cubical.Face` 商去語義等價（ROBDD 規範形）後，實作 `Semiring`/`IdempotentSemiring`/`StarSemiring`/`OrderedSemiring` |
| `free_category.mbt` | 95 | DAG 的自由範疇 → `@sym.FinCat` 的內部建構器（`free_category_to_fincat`） |
| `rotation_axis_bridge.mbt` | 465 | 共軛四元數凝聚中軸 ↔ Jacobi／Jordan／Hopf／Tamari 四族旋轉；逐族關係對齊、消元前後 `previous/current/deltas` 數值比較，以及 `11040→552→0` 相干角消元總報告 |
| `intuitive_conjecture_lab.mbt` | 415 | 五條由實際結構直覺提出的猜想與反例攻擊：1 條有界倖存、4 條反例後修正；完整人讀報告見 [`INTUITIVE_CONJECTURES.md`](INTUITIVE_CONJECTURES.md) |
| `malcev_presheaf_autonomy_bridge.mbt` | 91 | 構造性泛代數自主類型論 × 雙重否定核 `j(x)=¬¬x` 預層層化模板 × 64-bit SWAR 立方退化樹（`64594 + 942 = 65536`）× 54 項高階立方結構跨聯邦驗證橋 |
| `meta_k9_unification.mbt` | 536 | **九聯邦完全圖 `K₉ = 36/36` 全配對跨聯邦雙邊橋**（`K8-22..28` + `K9-29..36`）與 **`F7 → F9 → F4 → F1` 四聯邦定理自動晉升管線** |
| `f2_f3_f6_triad_bridge.mbt` | 296 | **`F2 ↔ F3 ↔ F6` 對稱—半環—凝聚三元合流橋**（`A₅` 序對 2-軌道 Burnside Möbius ↔ Four-Russians/M4RI/Hopcroft/Johnson/3D 牛頓細分 ↔ 構造性 Nöbeling 自由基底與 64× `@swar` Steenrod–Adams `η³=4ν`） |

---

## 3. 證書的最小共通形狀

```moonbit
pub(all) struct BridgeCertificate {
  source : String       // "cubical" / "symlib" / "semiring" / "atlas" / "bridge/unification" …
  name   : String       // 定理或定律名（對應 [T-…] 標籤）
  ok     : Bool
  detail : String       // 量化見證（"K7=21/21", "Ext^{1,2}=1 <-> |beta|=2" …）
}
```
轉換器：`certificate_of_cubical`、`certificate_of_symlib`、`certificate_of_semiring_law`。
`certificates_all_ok` 與 `certificate_summary` 供 `cmd/showcase` 印總表；`root` 的定理總表（129 條）與本檔的 47 條大一統證書是兩套互補視角。

---

## 4. K₇ 的 21 條橋（`discovery_k7_bridges.mbt`）

`verify_k7_federation_bridges()` 回傳 `Array[FederationPairBridge]`，每條含 `id`、`bridge_theorem`、`quantitative_witness`、`holds`。

| 世代 | 邊 | 代表見證 |
|---|---|---|
| `K5-01..10` | `cubical`·`symlib`·`semiring`·`topos`·`scheme` | 例如 `Face` 商格 ↔ 冪等半環定律；`symlib` 的 Burnside ↔ `semiring` 的 `ℤ_m` 冪集；`Gröbner` 消元 ↔ `cubical` 的 NbE 正規形 |
| `K6-11` | `Condensed ↔ Cubical` | 代數 `Ext_A^{1,2} = 1`（`η`）與 `Ext^{2,3} = 0`（`2η = 0`）↔ 幾何 Brunerie `\|β\| = 2`（`π₄(S³) = ℤ/2ℤ`）；`CondAnima` 的 `lim¹` |
| `K6-12` | `Condensed ↔ Symlib` | `CanonElimCategory` 在 `ℤ/2ℤ` 作用 `(0 1)(2 3)` 下的軌道數 `2` = `@sym.gset_burnside` |
| `K6-13` | `Condensed ↔ Semiring` | `CondAnalyticStack` 的熱帶折點 `{-1, 2}`（`@strop`）＋ `1/2`-液態次可加性 |
| `K6-14` | `Condensed ↔ Topos` | `[Ax-Cond-ExtDisc]` 餘積層下降 + Čech 扭曲障礙 `k¹ − r⁰ = 0` 於 `S³`（`E₂ = 4 → E₄ = 2`）↔ 神經同倫 |
| `K6-15` | `Condensed ↔ Scheme` | `Spa(ℚ⟨T,T⁻¹⟩, ℤ_p)` 的 Laurent 黏合 `h⁰ = 1, h¹ = 0` ↔ `ℙ¹` 賦值真性 + Serre 對偶 `h¹(ℙ¹, O(−2)) = 1` |
| `K7-16` | `Discovery ↔ Cubical` | 多邊形翻轉 `C₃ = 5`、`C₄ = 14` ↔ `assoc_fvector(4) = [5, 5, 1]` 的 Stasheff 面向量 |
| `K7-17` | `Discovery ↔ Symlib` | `@sym.aut_order` **否證** `Aut(K₄) ≅ S₄`（`10 = \|D₅\| ≠ 24`）；超行列式在 `3!` 軸置換下不變 |
| `K7-18` | `Discovery ↔ Semiring` | Viro–Krasner 超加法平手區間 ↔ `@strop.trop_det_tie_count`；蘊含閉包遞移 |
| `K7-19` | `Discovery ↔ Topos` | 非交叉弦森林景（`4` 邊形上 `48` 個開集）的 Grothendieck 等化器黏合；`VR(C₄,1)` 鏈／上鏈對偶 |
| `K7-20` | `Discovery ↔ Scheme` | 離散 Radon 平面 `𝔸²(𝔽₃)`（9 點 12 線 4 方向）完備化為 `ℙ²(𝔽₃)`：`\|ℙ²(𝔽₃)\| = 9 + 4 = 13` |
| `K7-21` | `Discovery ↔ Condensed` | 五透鏡把 5 條關係定理封入 `CondInvariantLedger`（雜湊鏈可驗）；Clifford 餘圈 `dim Z = \|rad\|` |

`verify_seven_federation_star_prism(k7_precomputed)` 把它們與 X 交疊、雙 V、12 條猜想合成 `SevenFederationStarPrismReport`（`cmd/showcase` 的 `K7=21/21` 就來自這裡）。

---

## 5. X 形交疊與雙 V 形（`double_v_chiasm.mbt`）

```text
                    V₂ 上頂點：@bridge
        ┌────────────── 星稜柱 + 硬體加速大一統（Layers 7–8）──────────────┐
         ╱        ╱        ╱        ╱        ╲        ╲        ╲        ╲
    F1 cubical  F2 symlib  F3 semiring  F4 topos  F5 scheme  F6 condensed  F7 discovery  F8 accel
         ╲        ╲        ╲        ╲        ╱        ╱        ╱        ╱
        └────────────── 對角線 D₁ 與 D₂ 在 @condensed + @gcd 交叉 ──────────────┘
                    V₁ 下頂點：@gcd（Layer 0）
```

`[T-X-Chiasmus]` 的兩條對角線：
* **`D₁`（離散語法 ↔ 非阿基米德賦值）**：`cubical` 的 `Face`/`DTerm` 語法 → `@strop` 的熱帶賦值 → `@gcd` 的 `p`-進 `v_p`；
* **`D₂`（連續分析 ↔ 高階同倫）**：`@scheme` 的 `ℚ((t))` Laurent → 凝聚 `CondAnalyticStack` → `cubical` 的 `π₄(S³)`。

`verify_x_overlap_chiasmus()` 驗證兩條對角線在 `X`-樞紐（`@condensed` + `@gcd`）**乾淨相交**（共享不變量三元組相同），`DoubleVArchitectureReport` 則記錄 `lower_v_gcd_apex_ok`、`six_federations_verified/6`、`k6_bridges_verified/15`、`seven_boundaries_breakthrough_ok`。

### 5.1 四族旋轉的關係對齊（`rotation_axis_bridge.mbt`）

`verify_rotation_axis_bridge()` 以 `@condensed.cond_quaternion_axis_report()` 為共同參考，再呼叫四族真正的上游實作：

| 旋轉族 | 實際檢查的關係 | 量化見證 |
|---|---|---|
| Jacobi 酉區間旋轉 | 伴隨／逆元蘊含、8→16 bits 粗細區間、依序相似變換 | `U†U-I` 區間含零；非對角平方上界不增；兩種精度證書各自 sound |
| Jordan 實旋轉塊 | 逆順向、倒影負對照、有限離散階 | `R⁴=I`、`R²≠I`、`RR³=R³R=I`；`det R=1` 而倒影 `det=-1` |
| Hopf 相位旋轉 | 共軛相位、逆順向、相位合成與反序列、緊緻載體代表元 | `θ=0.37`、`φ=-0.11`；`S³/S²` 範數與纖維不變量，並跑精確有理及數值雙路 |
| Tamari 結合多面體旋轉 | 左右逆順向、有限圖、序列／反序列路徑 | `K₃` 根旋轉往返；`K₄` 有 5 頂點、5 條旋轉邊且圖連通 |

這是一張**關係對齊表**，不是宣稱四族物件彼此同構；不適用於某族的關係不會被強行填入。共同的瑕積分、RK4／Richardson 極限與 3 條精確守恆律由凝聚層提供。本輪固定消元前基準，逐族公開 `previous/current/deltas`，以 `1e-12` 為回歸容差並拒絕 NaN／Inf；相干角報告逐項列舉 `11040`，第一段消去 `10488` 後餘 `552`，第二段把這 `552` 全部解析到 `276` 個規範類，故未解角為 `0` 且類重數仍總和 `11040`。`rotation_axis_certificate()` 是獨立證書，不計入歷史 **47/47**，因此沒有暗改既有里程碑；`cmd/showcase` 另印本橋的 PASS 行並納入總成功條件。

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
| `ATLAS-03` | `T²` 的杯積秩 1 | 與 `S¹∨S¹∨S²`（秩 0）的判別 |
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
把 `@accel` 的 CPU SWAR / WebGPU 逐位等價檢驗（對 `@gcd`、`@face_bdd`、`@algebra`、`@semiring/trop`、`@tensor` 的主定義）納入證書列，使 `Cmd-showcase` 的 **47/47** 包含硬體加速部分。

`grand_unification.mbt` 的 `verify_six_pillar_circle_sphere_unification()` 是六柱定理：`S¹`、`S² ≃ ℙ¹(ℂ)`、`ℙ²`、`ℤ/2ℤ`、`S₃` 的基本拓撲／同調／Galois／熱帶／動機不變量在六個 pillar 中互相吻合。`run_grand_unification_system()` 回傳 `GrandUnificationReport`。

---

## 9. 範例

```moonbit
// 1) 全部 21 條 K_7 橋
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

// 5) 證書總表（歷史 47 條；旋轉中軸證書獨立輸出）
let certs = @bridge.bridge_certificates()
assert_true(@bridge.certificates_all_ok(certs))

// 6) 九聯邦 K_9 (36/36) 全配對橋與 F7 -> F9 -> F4 -> F1 定理自動晉升管線
let k9 = @bridge.verify_k9_meta_discovery_topos_unification()
assert_true(k9.all_holds)                // 9/9 聯邦 · K9=36/36 · 四聯邦晉升=true
```

---

## 10. 依賴規則（硬性）

* **本套件可匯入任何下層套件**，下層**一律禁止**匯入 `bridge`（`agent.v2.md` §二、`tools/arch_check.py` 會攔截）。
* `bridge` 只做「比較與彙整」，不重新實作演算法：任何見證都必須呼叫上游套件的公開函式（例如 `K7-17` 必須用 `@sym.aut_order`，`verify_f8_f5_f1_triad_bridge()` 直接聯動 `@swar`、`@scheme`、`@algebra` 與 `@cub` 交叉核驗 M4RI 布林 F4 ↔ ROBDD、CCHM 上纖維化 ↔ Zariski 根理想、多素數模 F4 ↔ Buchberger、以及 HVM2 `INetArena` 強合流 ↔ 依賴型 NbE；`verify_f2_f3_f6_triad_bridge()` 直接聯動 `@sym`、`@sapp`、`@gcd` 與 `@condensed` 交叉核驗 Holt 子群格／Burnside Möbius／非薄群胚米田、半環全目標 `wasm-gc` 套件、模有界 HNF／Nöbeling 自由對偶與 `h₃=σ, η³=4ν`）。

---

## 11. 驗證

```bash
moon run cmd/showcase --target wasm-gc               # 9/9 聯邦 · K9=36/36 · F8↔F5↔F1 + F2↔F3↔F6 + F1×F3×F4×F8×F9 七支柱五元橋 · F7->F9->F4->F1 晉升 · 48/48 證書
python3 tools/arch_check.py                          # 確認沒有任何下層反向匯入 bridge
```
