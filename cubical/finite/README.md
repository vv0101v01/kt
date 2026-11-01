# `cubical/finite/` — 有限宇宙裡的 η-NbE、Wiring、`ua`、`PathP`、`Glue`、`J`（Layer 1）

> **套件**：`vv0101v01/cubical-hermitian/cubical/finite` · **Layer 1** · 依賴 `cubical-face-bdd`
> **被依賴**：`cubical-hermitian`、`cubical-kernel`、`cubical-homotopy`、`root`
> **4 檔 1,828 行** — 全倉最適合「先讀懂立方型別論」的入口。

---

## 1. 定位：為什麼先做「有限」

宇宙限定為 `Bool` / `Unit` / 積（`Ty`）。這不是閹割，而是**可判定性**的來源：

* 等價可以在**全部**元素上驗證（`Bool` 只有 2 個居民）⇒ 定理是被**判定**的，不是被抽樣的；
* 因此 `ua`、`coe`、`PathP`、`Glue`、`J` 這些在一般 HoTT 中需要繁重機制的東西，在這裡可以**一行一行算出答案**，作為 `cubical/kernel` 的規格與對照。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `nbe.mbt` | 350 | 簡單型別 NbE（β-π 等式）、定義性 `coe` 規則、HOAS 往返 |
| `nbe_eta.mbt` | 472 | **型別引導的 η-long** 正規化（函數／積／Unit／中性脊） |
| `wiring.mbt` | 390 | 有限等價的符號形式（帶號置換）與範疇／相干定律 |
| `pathp_glue.mbt` | 616 | `Iso → Equiv → ua → Path`、`coe` 計算、`PathP`、`Glue`、`J` |

---

## 3. `nbe.mbt` — β-π 等式

```moonbit
pub enum Term    { ... }      // 語法
pub enum Neutral { ... }      // 中性項（變數／stuck 應用）
pub enum Value   { ... }      // 語義
pub(all) struct HTm { ... }   // HOAS 表示
```
| 函式 | 作用 |
|---|---|
| `eval` / `quote` / `quote_neutral` / `nf` | 求值、語義 → 語法、正規形 |
| `def_eq` | **定義相等**（β-π）判定 |
| `nbe_single_valued` | NbE 的單值性（同一項的正規形唯一） |
| `coe_rules_definitional` | 立方 `coe` 的**定義性**規則在此片段成立 |
| `swap_involutive_on_element` | `swap` 在每個元素上對合 |
| `tm_id` / `tm_const` / `tm_swap` | 內建項 |
| `term_to_hoas` / `hoas_to_term` / `hoas_roundtrip_term` / `hoas_roundtrip_hoas` | 語法 ↔ HOAS 雙向往返 |
| `hoas_swap_example` / `hoas_const_example` | 可執行示例 |

---

## 4. `nbe_eta.mbt` — η 是「型別引導」的

```text
函數： f  ≡η  λx. f x
積：   p  ≡η  (fst p, snd p)
Unit： u  ≡η  ()
```
因此 `quote` 必須在**每個子項**知道型別 —— 包括中性脊內部（stuck 應用的引數本身可能需要 η 展開）。

| 型別 | 內容 |
|---|---|
| `LTy` | 簡單型別（含 `LBool`、`LUnit`、函數、積） |
| `TNeutral` / `TValue` | 帶型別的語義 |
| `TypedValue` | 型別 + 值 |
| 函式 | `ty_infer`、`ty_check`、`eval_infer_t`、`eval_check_t`、`quote_tneutral`、`quote_eta`、`nf_eta`、`def_eq_eta` |
| 性質 | `eta_single_valued_on`、`tm_swap_at`、`tm_coe_swap_at`、`tm_shift`、`tm_comp_closed`、`tm_id_at`、`tm_comp_at` |
| 檢核 | `check_eta_function`、`check_eta_product`、`check_eta_unit`、`check_eta_spine`、`check_eta_swap_involution`、`check_eta_all` |

**與 `nbe.mbt` 的差別**：`nbe.mbt` 只決定 β-π 等式；`nbe_eta.mbt` 加上 η ⇒ 正規形是**唯一**的（η-long β-normal），這是 `kernel` 的轉換檢查與 `quote` 正確性的基礎。

---

## 5. `wiring.mbt` — 有限等價的符號形式

把有限型別 `Ty` 攤平成葉序列（`Bool` / `Unit` 依序）。由 `id`、`not`、`swap`、積、複合、逆生成的等價，在葉上都是**帶號置換**：

```moonbit
pub(all) struct LeafMap { src_index : Int32; neg : Bool }   // 每個輸出葉的來源與否定旗標
pub(all) struct Wiring  { ... }                              // Array[LeafMap]
pub(all) enum LeafKind { LKBool; LKUnit }
```
* 建構／運算：`wiring_id`、`wiring_not`、`wiring_swap`、`wiring_prod`、`wiring_comp`、`wiring_inv`。
* 範疇定律：`wiring_assoc`、`wiring_left_unitor`、`wiring_right_unitor`、`wiring_wf`、`wiring_eq`。
* 求值：`leaves_of_ty`、`leaf_count`、`flatten_pval`、`wiring_apply`。
* 檢核：`check_wiring_category()`（範疇公理）、`check_wiring_coherence()`（相干）。

**用途**：`bridge/permutation_bridge.mbt` 用它在 `symlib.Perm` ↔ `cubical.Wiring` 之間來回；`homotopy/univalence.mbt` 用它把有限宇宙的路徑（`ua`）表示成**可比較的符號物件**，於是 transport 不必枚舉立方體。

---

## 6. `pathp_glue.mbt` — `ua`、`coe`、`PathP`、`Glue`、`J`

```text
Iso A B  --iso_to_equiv-->  A ≃ B  --ua-->  Path U A B
```
| 型別 | 說明 |
|---|---|
| `Ty` / `PVal` | 型別與其居民（`PVBool`、`PVUnit`、積） |
| `Iso` / `Equiv` | 同構（兩函數 + 兩邊等式，可**全元素**驗證）／等價 |
| `UPath` | 宇宙路徑 = `wiring` |
| `PathPVal` / `DiscPath` | 依賴路徑族／離散路徑 |
| `Family` / `GlueData` / `GlueElem` | 族、Glue 資料、Glue 元素 |

| 群 | 函式 |
|---|---|
| 等價 | `equiv_id`、`equiv_swap`、`equiv_bool_not`、`equiv_prod`、`equiv_comp`、`equiv_inv`、`equiv_wf`、`equiv_ext_eq`；`iso_wf`、`iso_to_equiv`、`iso_of_wiring`、`equiv_of_wiring` |
| `ua` | `ua`、`iso_to_path`、`upath_left`、`upath_right`、`upath_eq` |
| `coe` | `coe_upath`、`coe_computes`（**沿 `ua` 搬運會計算**）、`swap_naturality` |
| `PathP` | `pathp_canonical`、`pathp_wf`、`pathp_prod`、`pathp_fst`、`pathp_snd`、`pathp_prod_exchange_roundtrip` |
| 離散路徑 | `disc_path_wf`、`disc_path_sym`、`refl_path`、`disc_samples` |
| `J` | `j_elim_disc`、`j_roundtrip` |
| `Glue` | `glue_wf`、`make_glue`、`unglue`、`glue_restrict`、`glue_from_base`、`glue_sound` |

**這是 `kernel` 的規格書**：`kernel` 的依賴版（`equiv_ast.mbt`、`kan_ast.mbt`）必須在泛化後仍然滿足此處有限情形驗證過的等式。

---

## 7. 範例

```moonbit
// 1) η 等式
assert_true(@finite.def_eq_eta(fn_term, eta_expanded))   // f ≡η λx. f x

// 2) 等價 → ua → 沿路徑搬運
let e  = @finite.equiv_bool_not()
let p  = @finite.ua(e)
let b2 = @finite.coe_upath(p, @finite.PVBool(true))      // 逐位算出結果
assert_true(@finite.coe_computes(e, @finite.PVBool(true)))

// 3) Glue 型別
let g = @finite.make_glue(glue_data)
assert_true(@finite.glue_wf(g))
assert_true(@finite.glue_sound(e, @finite.PVBool(false)))
```

---

## 8. 驗證

```bash
moon test cubical/finite --target wasm-gc      # 單包微測試實測 0.22s（Wave 2 最快）
```
