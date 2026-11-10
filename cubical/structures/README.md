# `cubical/structures/` — 54 項高階立方結構全譜、26 運算動詞與 14 範疇組合交互圖譜（Layer 5）

> **套件**：`vv0101v01/cubical-hermitian/cubical/structures` · **Package Layer 6 / Component Layer 10**
> **依賴**：`gcd`、`cubical-face-bdd`、`cubical-kernel`、`cubical-elaborator`、`cubical-homotopy`、`cubical-autonomy`、`symlib`、`topos`、`accel`
> **被依賴**：`root`、`bridge`、`cmd-showcase`
> 單包微測試實測 **1.6s**（54 項結構證書、26 個運算動詞、14 種範疇組合模式與 14 條交互定理 100% 通過）

---

## 1. 定位

本套件將傳統立方核心外圍的全體 **54 項高階幾何、代數與邏輯結構**（Swan 常數範圍相等類型 `Id`、自由路徑 Kan 纖維化、全體 65,536 個 4-立方體 Eilenberg–Zilber 規範分裂、極性聚焦 `LJF` 與仿射雙向類型檢查、函子多項式容器簽名、關係參數性自由定理、立方結構恆等原則 SIP、覆蓋空間伽羅瓦對應、塞弗特—范坎彭推出與環面／懸緯／實射影平面同倫同調、依賴動機重構、異質 `coe`/開盒擬陣自動修補及內部計算反射）實作為受信任核心 `cubical/kernel`、同倫層 `cubical/homotopy`、層論層 `topos`、對稱群庫 `symlib` 與 64-bit SWAR 加速層 `accel` 之上的頭等構造性演算法，並顯式驅動 **26 個運算動詞 × 14 種範疇組合模式** 的雙向交互定理與多項式時間（`P`）演算法導出。

| 證據等級 | 意思 | 本套件代表實例 |
|---|---|---|
| **核心計算** | 經 `cubical/kernel` NbE、`dcube_box_fill_verified`、`circle_encode_value` 或精確整數行化簡實際算出 | `swan_id_j_elim` 開放變數嚴格歸約、純 Kan 逆與對合逆之 `3D` 開盒同倫 `I³ → S¹`、開盒擬陣基底修補 `loop ⬝ loop²` 繞數 `+3`、`RP²` Smith 撓率 `[2]` |
| **顯式構造與窮舉定理** | 全體 `65,536` 個 `4`-立方體、`S₃` 子群格與極性推導空間之無遺漏雙路徑對帳 | Eilenberg–Zilber 分裂層計數 `[2, 8, 60, 872, 64594]`、聚焦證明搜尋 `5 → 1`、`S₃` 正規覆蓋自同構群階 `[6, 2, 1]` vs 非正規 `[1, 1, 1]` |
| **負對照反駁** | 明確構造違反公理／資源／幾何邊界之反例並檢驗判別器拒絕 | 普通 `Path` 開放變數 `J` 滯留中性 `coe`、仿射類型檢查拒絕維度對角複用 `λi. f i i`、角點矛盾邊界精確回傳 `UnsolvableConflictPair(0, 1)`、`S¹ ∨ S¹` 交換子升騰不閉合 |

---

## 2. 檔案清單

| 檔案 | 主題 |
|---|---|
| `swan_id_and_free_path_fibration.mbt` | Swan 常數範圍相等類型 `SwanIdValue`（開放中性項嚴格定義 `J` 與 `Id ≃ Path`）、自由路徑空間 `ev₀`/`ev₀₁` Kan 纖維化截面、全體 `65,536` 個 `4`-立方體 `O(1)` SWAR Eilenberg–Zilber 退化分裂、異質 `comp ≡ hcomp ∘ coe`、無對合純 Kan 逆與對合逆之 `3D` 開盒同倫 |
| `affine_bidirectional_focusing.mbt` | 仿射區間線性資源雙向類型檢查（拒絕 `i` 重用與偽洩漏，通過線性置換）、極性化立方公式（正極同步焦點鎖定 vs 負極非同步可逆分解）與 `LJF` 聚焦搜尋（消除 `5 → 1` 交錯排列爆炸） |
| `functorial_poly_signatures_sip.mbt` | 函子多項式容器簽名與米田自然雙射 `Nat(⟦P⟧, Id) ≅ P(1)`（`9` 個規範居留元）、二元關係提升與 Wadler 多態自由定理、鑽石同餘推出並查集商融合、立方結構恆等原則（SIP：`(Bool, ⊕, false) ↦ (Bool, ↔, true)` 經 `ua(not)` 傳輸）及宇宙層級提升 `Lift` |
| `covering_space_pushout_torus.mbt` | 覆蓋空間伽羅瓦基本定理（聯動 `@sym.PermGroup` 驗證 `S₃` 正規覆蓋自同構群 `[6, 2, 1]` 與非正規覆蓋 `[1, 1, 1]`、透鏡空間覆蓋指數因子分解）、`T²` vs `S¹ ∨ S¹` 萬有覆蓋交換子升騰判準、懸緯 `Susp(S¹) ≃ S²` 與 `T²` Betti 數、`RP²` 整係數 Smith 正規形 `2`-撓率 `[2]` |
| `type_reconstruction_repair_reflection.mbt` | 聯動 `@elaborator.hou_unify` 之依賴消去隱式動機重構、異質端點自動插入 `coe` 修補、正方形邊界 `5 → 3` 擬陣獨立基底抽取與缺失頂蓋 Kan 合成修補（含角點最小衝突對診斷）、自由群／阿貝爾群棧式線性時間內部計算反射 |
| `verb26_comp14_atlas.mbt` | 全部 `54` 項結構證書註冊表、`26` 個運算動詞索引、`14` 種範疇組合模式與 `14` 條交互定理執行引擎 `verify_work4_all_54_structures_and_interactions` |

---

## 3. Swan 嚴格相等類型、自由路徑纖維化與 Eilenberg–Zilber 分裂（`swan_id_and_free_path_fibration.mbt`）

* **Swan 嚴格 `Id` vs 普通 `Path` 分離定理**：`SwanIdValue` 以 `(path_val, extent : Face)` 記錄常數範圍上同調約束，`refl_Id(x) = (λi.x, ⊤)`。在開放中性變數 `x₀ : S¹`（`DNVar(0)`）上，`swan_id_j_elim(circle_cover, 0, refl_Id(x₀))` 在定義上**嚴格歸約為 `0 : ℤ`**，而無 `extent` 標記之普通 `path_kan_j_elim` 滯留於中性 `coe`，同時透過單例可縮證明 `Id_A(x,y) ≃ Path_A(x,y)`。
* **Eilenberg–Zilber 退化分裂**：`ez_split_cube64_canonical` 以 `@accel.cube64_degeneracy_mask` 與 `cube64_face_swar`/`cube64_insert_degeneracy_swar` 將全體 `65,536` 個布林 `4`-立方體無碰撞唯一分解為核心維度 `0..4` 之非退化核與嚴格遞增退化軸序列，層計數精確對帳史特靈／Möbius 公式 `[2, 8, 60, 872, 64594]`。
* **純 Kan 逆與對合逆之 3D 同倫**：在 `@kernel` 中直接組裝 `3D` 開盒填充器 `I³ → S¹`（經 `dcube_box_fill_verified` 與 `dcube_filler_faces_ok` 驗證全 `5` 面與 `10` 條交稜），其頂蓋給出無對合純 Kan 開盒逆路徑與對合逆 `λi. loop(1-i)` 的顯式立方同倫。

---

## 4. 仿射雙向類型檢查與極性聚焦證明搜尋（`affine_bidirectional_focusing.mbt`）

* **次結構仿射區間紀律**：`affine_bidir_infer` 與 `affine_bidir_check` 以 64-bit 線性區間遮罩追蹤每個維度變數重數 `μ(i) ≤ 1`，接受線性置換並拒絕維度對角複用 `λi.λj. f i i`。
* **極性聚焦 `LJF`**：將正極（`⊗, ⊕, 1, Path⁺, ↓N⁻`）與負極（`→, &, ⊤, ∀_𝕀, ↑P⁺`）算子分離，使複合目標之無聚焦交錯推導數由 `5` 精確收斂為**唯一 `1` 棵規範聚焦證明樹**，同時對全體測試命題保持可靠性與完備性雙向一致。

---

## 5. 函子多項式簽名、關係參數性與結構恆等原則 SIP（`functorial_poly_signatures_sip.mbt`）

* **米田自然雙射與多態自由定理**：在多項式容器 `⟦P⟧(X) = Σ_{s:S} X^{ar(s)}` 上構造並窮舉驗證 `Nat(⟦P⟧, Id) ≅ P(1)`（`3 × 3 = 9` 個規範自然變換），並在全部二元關係上驗證多態重排函數之關係參數性自然交換律 `map_R(f(xs)) == f(map_R(xs))`。
* **鑽石同餘推出與立方 SIP**：以並查集推出融合驗證雙路徑交換圖；以單值線 `ua(not)` 將同構 `(Bool, ⊕, false) ≃ (Bool, ↔, true)` 提升為代數簽名空間中的路徑，直接以 `coe` 計算傳輸二元運算表與單位元並自動繼承單群公理。

---

## 6. 覆蓋空間伽羅瓦對應、推出與環面／射影平面同倫同調（`covering_space_pushout_torus.mbt`）

* **覆蓋空間伽羅瓦基本定理**：在 `@sym.PermGroup` 的三階對稱群 `S₃`（階 `6`）上計算陪集覆蓋纖維與覆蓋自同構群 `Aut_p(E_H) ≅ N_G(H)/H`：正規子群 `{e}, A₃, S₃` 給出正則伽羅瓦覆蓋 `[6, 2, 1]`（自同構數等於葉數），非正規二階子群給出 `[1, 1, 1]`。
* **萬有覆蓋升騰與整係數撓率**：以交換子 `[a, b] = a b a⁻¹ b⁻¹` 在 `ℤ²`（環面 `T²` 萬有覆蓋，端點 `(0,0)` 閉合）與自由群 `F₂`（楔和 `S¹ ∨ S¹` 萬有覆蓋，約化字長 `4` 不閉合）之升騰差異刻畫 `2`-胞腔面貼附；以精確整數行／列初等變換計算 `Susp(S¹)` Betti `[1,0,1]`、`T²` Betti `[1,2,1]` 與 `RP²` Smith 不變因子 `[2]`（捕捉域係數無法看見的 `ℤ/2ℤ` 撓率）。

---

## 7. 依賴動機重構、自動邊界修補與內部計算反射（`type_reconstruction_repair_reflection.mbt`）

* **隱式動機重構與異質修補**：調用 `@elaborator.hou_unify` 解出高階模式統一元 `?M(x) ≡ Pair(x, x)`；對異質端點自動插入 `coe` 修補；對含冗餘重複面（`5` 個輸入面）之正方形邊界執行擬陣獨立基底縮減（`3` 個正交面）並以 `dcube_box_fill_verified` 自動合成缺失頂蓋 `loop ⬝ loop²`（繞數 `+3`），對角點不相容邊界精確回報最小衝突對 `(0, 1)`。
* **內部計算反射**：線性時間棧式自由群反射正規化器將 `7` 構造子迴圈項消元為規範字 `[1, 1]`，經 `@kernel` 單值覆蓋獨立驗證繞數同為 `+2`；阿貝爾反射將環面交換子直接歸零為 `(0, 0)`。

---

## 8. 公開入口範例

```moonbit
let rep = @structures.verify_work4_all_54_structures_and_interactions()
// rep.verified_structure_count == 54
// rep.distinct_verbs_covered == 26
// rep.distinct_patterns_covered == 14
// rep.interaction_theorems_count == 14
// rep.all_54_structures_and_interactions_ok == true
let ok = @structures.check_work4_54_structures_26_verbs_14_patterns()
```

---

## 9. 驗證方式

開發期間使用單包微測試 `moon test cubical/structures --target wasm-gc` 執行 `debug_inspect` 對帳與負對照驗證後立即移除臨時 `test` 塊；常駐全倉閘門由 `cmd/metatheory`、`cmd/main`、`cmd/showcase`、`verify.mbt` 與 `bridge/malcev_presheaf_autonomy_bridge.mbt` 持續執行。
