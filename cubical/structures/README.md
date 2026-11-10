# `cubical/structures/` — 54 項高階立方結構獨立實現全譜、26 運算動詞與 14 範疇組合交互圖譜

> **套件**：`vv0101v01/cubical-hermitian/cubical/structures` · **Package Layer 6 / Component Layer 10**（`cubical` 聯邦）
> **規模**：`9` 個 `.mbt` 源檔，共 **`7,017` 行**
> **依賴**：`gcd`、`cubical-face-bdd`、`cubical-kernel`、`cubical-elaborator`、`cubical-homotopy`、`cubical-autonomy`、`symlib`、`topos`、`accel`
> **被依賴**：根套件 `root`、`bridge`、`cmd-showcase`

---

## 1. 架構定位與資料夾視角依賴／內部數據流圖

本套件將 **`工作內容4.md` 全部 54 項高階立方類型論、同倫代數拓撲與結構語義專題**逐項實現為**無別名搭便車（zero piggybacking）之獨立構造性演算法與可驗證數學結構**，並耦合 **`作業規範.md` 之 26 個運算動詞**與 **`組合範例.md` 之 14 種範疇組合模式**。

### 1.1 資料夾視角依賴關係圖

```text
[L0] gcd · cubical/face_bdd · accel/swar · symlib/core
  │
  ▼
[L1–L5] symlib · topos · accel · cubical/{kernel, elaborator, homotopy, autonomy}
  │
  ▼
[L6 / compL10] cubical/structures  (9 files, 7,017 lines)
  ├── glue_hae_universe_classifier.mbt      (#7, #35, #36, #37, #38, #39, #40)
  ├── cubical_hits_pushout_torus.mbt        (#12, #42, #43, #44, #45, #46)
  ├── cubical_nbe_subst_connections_kan.mbt (#1,#3,#4,#5,#11,#13,#14,#28,#29,#30,#33,#47,#51,#54)
  ├── swan_id_and_free_path_fibration.mbt   (#2, #6, #9, #10, #16)
  ├── affine_bidirectional_focusing.mbt     (#8, #15, #17, #27, #31, #32)
  ├── functorial_poly_signatures_sip.mbt    (#18, #19, #20, #21, #34, #41)
  ├── covering_space_pushout_torus.mbt      (#48, #49)
  ├── type_reconstruction_repair_reflection.mbt (#50, #52, #53)
  └── verb26_comp14_atlas.mbt               (匯流以上 8 檔 + @autonomy #22..#26 -> 54/54 獨立證書 + 26×14 交互定理)
  │
  ▼
[L7–L9] root (facade.mbt / verify.mbt / spec.mbt) ──► bridge ──► cmd/{main, showcase}
```

### 1.2 套件內部數據流

1. **雙分類語法與正規化流**（`cubical_nbe_subst_connections_kan.mbt` + `affine_bidirectional_focusing.mbt`）：
   `CwfCubicalTerm` × `CwfParallelSubst` $\xrightarrow{\text{De Morgan NNF}}$ 代換結合么半群 $\xrightarrow{\text{反射—再化 NbE}}$ 無紅ex 長 $\eta$ 正規形 `CubicalNf`；同時聯動 `@kernel.conv_at_under_face_in`、`quote_at`、`d_check`/`d_infer` 驗證上纖維化層黏合轉換與雙向型別形成規則。
2. **膠水、單值性、半伴隨與宇宙分類流**（`glue_hae_universe_classifier.mbt`）：
   `CubicalGlueSpec` $\xrightarrow{\varphi \equiv \top/\bot}$ 嚴格邊界塌縮與 `CubicalGlueDatum` 對齊守衛 $\xrightarrow{\text{入口/出口 Glue 線}}$ `@kernel.coe_value` 雙扭曲 `Bool` 往返；`256` 個 `Fin(4) -> Fin(4)` 映射經 `classify_finite_map_equivalences` 四重對帳（`24` 個雙射），`S^1` 失相干準逆 $(\mathrm{loop}^2, \mathrm{loop}^{-1})$ 經 `@homotopy.adjointify_equiv_value` 與 `circle_decode_encode_retr_value` 修復繞數 `+2` 並構造可轉換 2D Vogt 三角相干胞；`HsCubicalFamily2D` 經 `hs_classify_family_2d` 與 Orton–Pitts `realign_hs_family_code_2d` 完成泛立方體宇宙分類拉回與嚴格重對齊。
3. **高階歸納類型、推出、懸置與環面流**（`cubical_hits_pushout_torus.mbt` + `covering_space_pushout_torus.mbt`）：
   `CubicalPushoutSpan` $\xrightarrow{\text{pushout\_span\_to\_hit2}}$ `CubicalHit2Presentation` $\xrightarrow{\text{integer\_matrix\_smith\_invariants}}$ 整係數同調與撓率（Klein 瓶 $H_1 \cong \mathbb{Z} \oplus \mathbb{Z}/2\mathbb{Z}$、`RP^2` 2-撓率 `[2]`）；核心 Schema `S^1` 與 `T^2` 上實算度數映射函子性 $\deg_3 \circ \deg_2 \simeq \deg_6$、懸置 $\Sigma\mathsf{Bool} \simeq S^1$、指點伴隨 $\Sigma \dashv \Omega$ 以及開放中性 2-立方體上 $T^2 \simeq S^1 \times S^1$ 定義往返。
4. **連接方塊、結構化 Kan 填充、自動修補與全譜匯總流**（`swan_id_and_free_path_fibration.mbt` + `type_reconstruction_repair_reflection.mbt` + `verb26_comp14_atlas.mbt`）：
   連接交聯方塊 `connection_meet_square_value` / `connection_join_square_value`、結構化 $\Pi/\Sigma/\mathsf{Path}$ `hcomp`、開放盒 `I^3 -> S^1` 3D 填充器（5 面 8 稜核驗）與 Swan 嚴格 `Id` 匯入 `verb26_comp14_atlas.mbt`，為 `#1..#54` 每一個編號建立專屬布林不變量。

---

## 2. 檔案清單（9 檔，7,017 行）

| 檔案 | 行數 | 對應 `工作內容4.md` 項目與核心職責 |
|---|---:|---|
| `glue_hae_universe_classifier.mbt` | 706 | `#7, #35, #36, #37, #38, #39, #40`：CCHM `Glue` 類型嚴格邊界塌縮、`glue`/`unglue` 對齊守衛與 Kan `coe`；`Fin(4)` 256 映射四重等價與 `S¹` 失相干準逆檢測；Vogt 半伴隨化 `+2` 繞數修復與 2D 三角相干方塊；Hofmann–Streicher 2D 泛立方宇宙分類拉回與 Orton–Pitts `U8` 重對齊；中性 `Lift` β/η 與 `ua(not)` 宇宙同構 |
| `cubical_hits_pushout_torus.mbt` | 803 | `#12, #42, #43, #44, #45, #46`：核心 HIT Schema 良構與 2D 胞腔複形歐幾里得 Smith 整同調（Klein 瓶 `H₁ ≅ ℤ ⊕ ℤ/2ℤ`）；同倫推出跨度轉譯與 `27 == 27` 泛餘錐雙射；圓形度數映射 `deg_k` 點-β、路徑-β 與複合函子性（`+6, -6`）；`ΣBool ≃ S¹` 與 `Σ ⊣ Ω` 指點伴隨；開放 2-立方 `T² ≃ S¹ × S¹` 定義往返與交換子頂蓋 |
| `cubical_nbe_subst_connections_kan.mbt` | 1,083 | `#1, #3, #4, #5, #11, #13, #14, #28, #29, #30, #33, #47, #51, #54`：雙分類 CwF 平行項／維度代換么半群；上纖維化局部層黏合轉換；無紅ex `CubicalNf`/`CubicalNe` NbE 與核心 `quote_at` 代換自然性；雙向型別形成與錯配攔截；依值柯里化 `(Σx:A.B)→C ≃ Πx:A.B→C` 與依值 `funext`/`happly`；De Morgan NNF 對合與連接方塊 8 律；`Π`/`Σ`/`Path` 結構化 `hcomp`；`hfill` 路徑與 `I³ → S¹` 3D 開放盒填充 |
| `swan_id_and_free_path_fibration.mbt` | 452 | `#2, #6, #9, #10, #16`：Swan 常數範圍相等類型 `SwanIdValue` 開放變數嚴格 `J` 與 `Id ≃ Path`；自由路徑空間 `ev₀`/`ev₀₁` Kan 纖維化；全體 `65,536` 個 4-立方體 SWAR Eilenberg–Zilber 分裂 `[2,8,60,872,64594]`；異質 `comp ≡ hcomp ∘ coe`；無對合純 Kan 逆 3D 同倫 |
| `affine_bidirectional_focusing.mbt` | 1,532 | `#8, #15, #17, #27, #31, #32`：正／負極性立方公式、64-bit 線性遮罩仿射雙向類型檢查（攔截維度對角複用）、`LJF` 極性聚焦證明搜尋（`5 → 1` 唯一規範證明樹）與聚焦完備性對帳 |
| `functorial_poly_signatures_sip.mbt` | 622 | `#18, #19, #20, #21, #34, #41`：函子多項式容器簽名與米田雙射 `Nat(⟦P⟧, Id) ≅ P(1)`（9 個居留元）、二元關係提升與 Wadler 多態自由定理、鑽石同餘並查集推出融合與立方 SIP 單值代數傳輸 |
| `covering_space_pushout_torus.mbt` | 504 | `#48, #49`：`S₃` 子群格覆蓋空間伽羅瓦基本定理（正規覆蓋 `[6,2,1]` vs 非正規 `[1,1,1]`、透鏡空間因子分解）、`T²` vs `S¹ ∨ S¹` 萬有覆蓋交換子升騰判準與 `RP²` 整係數 2-撓率 `[2]` |
| `type_reconstruction_repair_reflection.mbt` | 343 | `#50, #52, #53`：高階模式合一 `?M(x)` 隱式動機重構、異質端點自動 `coe` 插入、正方形邊界 `5 → 3` 擬陣基底縮減與開盒缺失頂蓋合成（含角點衝突對 `(0,1)` 攔截）及棧式自由群／阿貝爾內部計算反射 |
| `verb26_comp14_atlas.mbt` | 972 | 全部 `54` 項無重疊結構證書註冊表、`26` 個運算動詞索引、`14` 種範疇組合模式、`14` 條交互定理與第二階段專屬總檢核 `check_work4_stage2_dedicated_structures` |

---

## 3. 核心資料型別與輸入／輸出介面

### 3.1 主要資料結構

| 型別 | 定義位置 | 用途 |
|---|---|---|
| `CubicalGlueSpec` / `CubicalGlueDatum` | `glue_hae_universe_classifier.mbt` | CCHM 部分等價系統 `[φ_k ↦ (T_k, e_k)] B` 與對齊膠水元素 `(partials, base_val)` |
| `FiniteEquivQuadrilogy` | `glue_hae_universe_classifier.mbt` | 有限映射之準逆／雙可逆／半伴隨／可縮纖維四重獨立布林判定與見證 |
| `HsCubicalFamily2D` / `HsClassifierCode2D` | `glue_hae_universe_classifier.mbt` | `I²` 預層上之有限纖維族、泛宇宙分類碼與 Orton–Pitts 重對齊輸出 |
| `CubicalHit2Presentation` / `CubicalPushoutSpan` / `Hit2HomologySummary` | `cubical_hits_pushout_torus.mbt` | 2D 高階歸納類型胞腔表示、有限同倫推出跨度與整係數 Betti／撓率摘要 |
| `CwfCubicalTerm` / `CwfParallelSubst` / `CubicalNf` / `CubicalNe` | `cubical_nbe_subst_connections_kan.mbt` | 雙分類 de Bruijn 立方項、平行項／維度代換與無紅ex 正規形／中性項文法 |
| `SwanIdValue` / `EilenbergZilberCubeFactor` | `swan_id_and_free_path_fibration.mbt` | Swan 常數範圍相等對 `(path, extent)` 與 64-bit 4-立方體唯一非退化核分解 |
| `PolarCubicalFormula` / `CubicalBidirType` / `CubicalBidirTerm` | `affine_bidirectional_focusing.mbt` | 正負極性立方命題與仿射資源雙向類型語法 |
| `PolyFunctor` / `DepSignature` / `DepStructure` | `functorial_poly_signatures_sip.mbt` | 多項式容器函子與依值代數簽名／結構實例 |
| `DiscreteCoveringSpace` | `covering_space_pushout_torus.mbt` | 點化連通覆蓋空間與覆蓋自同構群表示 |
| `Work4ItemCertificate` / `Work4Complete54Report` | `verb26_comp14_atlas.mbt` | 單項專題證書與 `54 × 26 × 14` 全譜彙總報告 |

### 3.2 關鍵公開函式輸入／輸出介面

| 函式 | 輸入 | 輸出 | 數學保證 |
|---|---|---|---|
| `cubical_glue_intro_value(spec, datum)` | `CubicalGlueSpec, CubicalGlueDatum` | `Option[@kernel.DValue]` | 僅當 `cubical_glue_datum_aligned` 核驗全部分支 `φ_k ⊢ e_k(t_k) ≡ b` 通過時建構膠水值；`φ_k ≡ ⊤` 時嚴格塌縮回 `t_k` |
| `classify_finite_map_equivalences(n, f)` | `Int32, Array[Int32]` | `FiniteEquivQuadrilogy` | 獨立計算 `qinv`、`biinv`、`hae` 與 `contr_fibers` 並驗證四者邏輯全等 |
| `realign_hs_family_code_2d(fam, mask, align_isos)` | `HsCubicalFamily2D, Int32, Array[Array[Int32]]` | `HsClassifierCode2D` | 滿足 Orton–Pitts `U8`：在 `mask` 頂點嚴格採用指定同構並在全方塊保持 `top ∘ left == right ∘ bottom` |
| `integer_matrix_smith_invariants(rows, cols, mat)` | `Int32, Int32, Array[Array[Int32]]` | `(Int32, Array[Int32])` | 行列歐幾里得初等變換計算整矩陣秩與大於 `1` 之不變撓率因子 |
| `circle_degree_map_value(k, dlevel)` | `Int32, Int32` | `@kernel.DValue` | 在核心 `circle_schema()` 上建構度數映射 `deg_k : S¹ → S¹`，滿足 `w(ap_{deg_k}(loop)) = k` |
| `torus_to_circle_product_value(dlevel)` / `circle_product_to_torus_value(dlevel)` | `Int32` | `@kernel.DValue` | 在核心 `torus_schema()` 與 `S¹ × S¹` 間建立互逆映射，對任意開放中性 2-立方定義恆等往返 |
| `cwf_subst_compose(tau, sigma)` | `CwfParallelSubst, CwfParallelSubst` | `CwfParallelSubst` | 滿足雙分類 CwF 結合律 `t[σ][τ] == t[τ ∘ σ]`（跨 `TmLam` 與 `TmPathLam` 綁定器） |
| `cubical_normalize_to_nf(ctx, dims, ty, tm)` | `Array[SimpleCubicalTy], Int32, SimpleCubicalTy, CwfCubicalTerm` | `CubicalNf` | 無步進歸約產出 `cubical_nf_is_canonical(...) == true` 之長 η 正規形 |
| `connection_meet_square_value(ty, a, p, dlevel)` / `connection_join_square_value(ty, b, p, dlevel)` | `@kernel.DValue × 3, Int32` | `@kernel.DValue` | 以 De Morgan NNF 建構連接方塊 `p(i ∧ j)` 與 `p(i ∨ j)`，滿足全部 8 條退化邊界與對合對偶律 |
| `verify_glue_hae_and_universe_classifier_suite()` | `()` | `GlueHaeUniverseClassifierReport` | 實算並驗證 `#7, #35..#40` 共 10 項指標全為 `true` |
| `verify_cubical_hits_pushout_torus_suite()` | `()` | `CubicalHitsPushoutTorusReport` | 實算並驗證 `#12, #42..#46` 共 7 項指標全為 `true` |
| `verify_cubical_nbe_subst_connections_kan_suite()` | `()` | `CubicalNbeSubstConnectionsKanReport` | 實算並驗證 `#1, #3..#5, #11, #13, #14, #28..#30, #33, #47, #51, #54` 共 10 項指標全為 `true` |
| `check_work4_stage2_dedicated_structures()` | `()` | `Bool` | 串聯三大專題報告與 `54/54` 全譜證書之總開關（供 `verify.mbt` 第 138 項與 `bridge` 調用） |
| `cubical_mtt_synth(cat, ctx, term)` / `cubical_mtt_check(cat, ctx, term, ty)` | `CubicalMode2Cat, CubicalMttCtx, CubicalMttTerm[, CubicalMttTerm]` | `CubicalMttTerm?` / `Bool` | 3-模式凝聚—守衛嚴格 2-範疇（`Set, Space, Clocked`）上具 Fitch 鎖正規化、2-胞腔鑰匙 `x^α` 與正極 `let mod_ν(mod_μ(x))` 之多模態依賴類型檢查 |
| `dual_swar_check_resource_term(n_modal, grades, term)` | `Int32, Array[UsageMult], DualSwarDepTerm` | `Bool` | 將 `UsageMult` 橋接至 `@accel.swar_grade16_*` 16 通道 4-bit 暫存器，執行 `0·Γ` 型別形成抹除與 `O(1)` 硬體線性資源檢查 |
| `cub_qiit_reify_id_sub_path(g, a)` | `CubQiitCon, CubQiitTy` | `(@kernel.DValue, Bool)` | 將互遞迴 `(Con, Ty)` 立方 QIIT 之一維路徑構造子 `A[id] ≡_{i} A` 消除為 `@kernel.DVPathLam` 並核驗 `DZero`/`DOne` 端點定義轉換 |
| `verify_frontier_7pillars_cubical_suite()` | `()` | `Frontier7PillarsCubicalReport` | 一舉聯動檢驗 MTT 2-範疇、Orton–Pitts `Glue` ↔ `@topos` Artin 膠合、SWAR 雙上下文 QTT、立方路徑 QIIT 與 `170×` 記憶化雙向依值／歸納引擎（供 `verify.mbt` 第 139 項與 `bridge` 調用） |

---

## 4. 已獲得之核心數學定理與演算法摘要

1. **`[T-Glue-Strict-Collapse-And-Kan-Coe]`（`#35, #36`）**：CCHM `Glue [φ ↦ (T, e)] B` 在 `φ ≡ ⊤` 時定義塌縮為 `T`、在 `φ ≡ ⊥` 時定義塌縮為 `B`；對不滿足 `e(t) ≡ b` 之偽膠水對精確拒絕；沿雙扭曲入口／出口 `ua(not)` 膠水線執行 `@kernel.coe_value` 精確計算 `not ∘ not = id`。
2. **`[T-Vogt-Adjointification-2Cell]`（`#37, #38`）**：`Fin(4)` 全體 `256` 個自映射中準逆、雙可逆、半伴隨與可縮纖維四重充要全等（精確篩出 `4! = 24` 個雙射）；在非截斷 1-群胚 `S¹` 上，故意構造之失相干準逆 `(id, id, η=loop², ε=loop⁻¹)` 被繞數檢測器精確捕獲（`w(ap_f(η)) = +2 ≠ -1 = w(ε)`），經 `@homotopy.adjointify_equiv_value` 修復為 `w(ε') = +2`，並由 `circle_decode_encode_retr_value` 合成端點經 `@kernel.conv_at` 核驗之 2D Vogt 三角相干胞 `Path (ΩS¹) (ap_f(η(base))) (ε'(base))`。
3. **`[T-HS-Universe-Realignment]`（`#39, #7, #40`）**：2D 立方預層有限族經 `hs_classify_family_2d` 分類拉回同構於原族，且 Orton–Pitts `U8` 重對齊算子在全體 `16` 種頂點上纖維化遮罩下嚴格採用指定局部同構並保持方塊交換性；開放中性項上 `Lift` 滿足定義 β/η 與 `coe` 交換。
4. **`[T-HIT2-Smith-Pushout-Susp-Torus]`（`#12, #42..#46`）**：Klein 瓶同倫推出呈現經整矩陣歐幾里得 Smith 正規形算出 `Betti = [1, 1, 0]` 與 `2`-撓率 `[2]`；非平凡跨度對 3 點目標集精確實現 `27 == 27` 泛餘錐雙射；圓形度數映射驗證 `w(deg_3 ∘ deg_2) = +6` 與 `w(deg_{-2} ∘ deg_3) = -6`；開放中性 2-立方體上 `T²` 與 `S¹ × S¹` 雙向定義恆等往返。
5. **`[T-CwF-NbE-Connections-3DBox]`（`#1, #3..#5, #11, #13, #14, #28..#30, #33, #47, #51, #54`）**：雙分類平行代換滿足跨綁定器結合律且與核心 `quote_at` 自然交換；上纖維化 `(i=0) ∨ (i=1)` 局部相等蘊含全域層黏合轉換；依值柯里化與依值 `funext`/`happly` 在開放中性項上定義往返；De Morgan NNF 連接方塊滿足 8 條邊界冪等律與對合對偶 `¬(¬i ∧ ¬j) ≡ i ∨ j`；`I³ → S¹` 3D 開放盒填充器通過全部 5 個二維面與 8 條交稜相容核驗。

---

## 5. 公開入口範例與驗證方式

```moonbit
let ok_stage2 = @structures.check_work4_stage2_dedicated_structures()
let rep = @structures.verify_work4_all_54_structures_and_interactions()
// ok_stage2 == true
// rep.verified_structure_count == 54
// rep.distinct_verbs_covered == 26
// rep.distinct_patterns_covered == 14
// rep.all_54_structures_and_interactions_ok == true
```

* **單包即時微測試**（開發期）：在受改檔底附加臨時 `test` + `debug_inspect`，執行 `moon test cubical/structures --target wasm-gc` 核驗通過後立即刪除 `test` 塊。
* **常駐全倉閘門**：`moon check --deny-warn`（`wasm-gc` / `wasm` / `js` / `native` 四目標零警告）、`python3 tools/arch_check.py`、`moon run cmd/main --target wasm-gc`（第 138 項檢核）與 `moon run cmd/showcase --target wasm-gc`。
