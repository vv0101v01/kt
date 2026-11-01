# `cubical/elaborator/` — 雙向精緻化與高階合一／匹配（Layer 3）

> **套件**：`vv0101v01/cubical-hermitian/cubical/elaborator` · **Layer 3** · 依賴 `cubical-kernel`
> **被依賴**：`root`
> **4 檔 5,514 行** · 單包微測試實測 **0.35s**
> **與 `homotopy`、`store` 完全正交**：三者互不依賴，可平行開發／平行編譯。

---

## 1. 定位

把「人寫的表面語法」變成「核心接受項」，並處理其中不可避免的**元變數問題**：

```text
        UTerm（表面，帶 UMetaInfo）
              │  elab_check / elab_infer（雙向）
              ▼
        STerm / DTerm（核心，kernel 已檢）
```
而元變數的求解有三個不同難度的區域，本套件**分別用不同工具**處理，不混淆：

| 區域 | 可判定性 | 本套件的工具 |
|---|---|---|
| **高階匹配**（只有一邊有元變數） | **可判定** | `hou_match.mbt`（Miller pattern + 直接解法） |
| **合一於 pattern 片段** | 可判定 | `elaborator_bidir.mbt` 的 `hou_unify` / `hou_unify_mgu` |
| **一般高階合一** | **不可判定**（Goldfarb 1981，二階即不可判定） | `hou_unify_stream.mbt` 的**有界 Huet 搜索** + 延遲 flex-flex；`hou_goldfarb.mbt` 把不可判定性本身編譯成丟番圖問題 |

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `elaborator_bidir.mbt` | 2,158 | 雙向精緻化 + pattern 片段合一 + 語義最佳化 |
| `hou_match.mbt` | 597 | 高階**匹配**（可判定的那一側） |
| `hou_unify_stream.mbt` | 2,514 | 有界 Huet 搜索、殘餘約束、延遲 flex-flex、惰性合一器串流 |
| `hou_goldfarb.mbt` | 245 | `[T-HOU-InnerLam]` 內層 λ 匹配；`[T-Goldfarb-Diophantine]` 不可判定性歸約 |

---

## 3. `elaborator_bidir.mbt`（2,158 行）

```moonbit
pub(all) struct UTerm      { ... }          // 表面項
pub(all) struct UMetaInfo  { ... }          // 元變數資訊
pub(all) struct STerm      { ... }          // 核心表面（已解元變數）
pub(all) struct DTerm      { ... }          // 交回 kernel
pub(all) struct Elaborator { ... }
pub(all) struct ElabResult { ... }
```
| 群 | 函式 |
|---|---|
| 表面型別 | `uty_bool`、`uty_nat`、`uty_unit`、`uty_arrow` |
| 合一狀態 | `Unifier`、`hou_fresh_meta`、`uterm_whnf`、`uterm_contains_unsolved_meta` |
| pattern 片段 | `hou_unify`、`hou_unify_mgu`（回傳 `HouMguStatus`／`HouMguReport`／`HouConstraint`） |
| 語義最佳化 | `hou_semantic_optimize`（在純語法之外用語義資訊挑選較佳解） |
| 精緻化 | `elaborator_new`、`elab_check`（checking）、`elab_infer`（inferring）、`elab_result_to_dterm`、`elab_type_to_dterm` |
| 檢核 | `check_hou_elaborator()`、`check_hou_phase9_extensions()` |

**雙向的意義**：`elab_check(term, expected_ty)` 讓 η 展開與插入式（insertion）由型別驅動；`elab_infer` 產生元變數與約束，交由合一器求解。轉換檢查永遠在 `kernel` 進行，**精緻化器不自行判定相等**。

---

## 4. `hou_match.mbt`（597 行）— 可判定的匹配

```text
匹配 = 一邊是封閉項、另一邊含元變數
⇒ 元變數的解若存在，在 pattern 條件下是唯一的（可判定，且不需要搜索）
```
* `HouMatchResult`：匹配是否成功 + 解 + 失敗原因。
* `hou_match(pattern, target)`：主入口。
* `hou_match_solved_within(pattern, target, fuel)`：可在**有限步數內**完成（給出上界）。
* `hou_conv(t1, t2)`：把「轉換檢查」升級為「匹配 + kernel 轉換」的組合判定。
* `check_hou_matching()`：定型測例（含必須**失敗**的反例）。

> 為什麼值得單獨成檔：把不可判定的陰影從日常路徑移開。精緻化器 99% 的元變數問題都是匹配，全部走這條**可判定**的路，只有剩下的才進 Huet。

---

## 5. `hou_unify_stream.mbt`（2,514 行）— 有界搜索

### 5.1 主搜索
`hou_search_unify(a, b, depth_budget)` → `HouSearchReport`（`HouSearchStatus`：成功／耗盡／不可判定邊界）；`hou_search_unify_bool`（只問有無）；`hou_search_unify_iterative`（迭代加深，回 `HouIterativeReport`）。

### 5.2 殘餘與回溯
`hou_solve_constraints`（解一組 `HouConstraint`）、`hou_unify_residual`（`HouResidualSolveReport`）、`hou_solve_constraints_backtracking`（帶回溯）。

### 5.3 列舉
`hou_enumerate_unifiers(a, b, cap)` → `HouEnumerationReport`：**列舉多個**獨立合一子（而非只取第一個），供需要「挑最佳解」的場合。

### 5.4 延遲 flex-flex（本檔最精巧的部分）
`HouDelayedSolveStatus`、`HouFlexFlexEdge`、`HouDelayedGraphReport`：
1. flex-flex 等式（`?F x̄ = ?G ȳ`）先**延遲**，記錄成圖的邊；
2. 求解其他約束後，`hou_reify_delayed_flex_flex` 把延遲圖**具體化**回式子；
3. `hou_solve_with_delayed_flex_flex` 一次處理「先解殘餘，再回填 flex-flex」的順序。
這個「延遲 → 重放」的兩段式設計，是把 Huet 算法的搜尋空間壓回可管理規模的關鍵。

### 5.5 惰性串流
`HouLazyUnifierStream`：`hou_unifier_stream_new`、`hou_unifier_stream_next`、`hou_unifier_stream_is_exhausted`、`hou_unifier_stream_nodes` —— 呼叫端按需拉取合一器，不必一次算完整棵樹（`nodes` 讓成本可見）。

檢核：`check_hou_bounded_search()`、`check_hou_search_extensions()`。

---

## 6. `hou_goldfarb.mbt`（245 行）— 把理論邊界變成可執行證據

* `[T-HOU-InnerLam]` `hou_match_higher_order_lambda(...)`：把匹配擴展到**內層 λ**（巢狀抽象）的情形，仍然可判定。
* `[T-Goldfarb-Diophantine]` `goldfarb_verify_diophantine_encoding()`：把 Goldfarb 的不可判定性歸約**具體編譯成丟番圖方程**並驗證其不可解／可解性，因此「這裡是不可判定邊界」不是一句註解，而是一個可複驗的計算。
* 輔助：`goldfarb_church_unary`、`goldfarb_church_iterator`（Church 數編碼）、`GoldfarbDiophantineReport`。

---

## 7. 範例

```moonbit
// 1) 匹配（可判定）
let r = @elab.hou_match(pattern, target)
if r.succeeded { println(r.substitution) }

// 2) pattern 片段的合一 + 最佳解
let u = @elab.unifier_new()
let mgu = @elab.hou_unify_mgu(u, t1, t2)      // HouMguReport
let best = @elab.hou_semantic_optimize(mgu)

// 3) 超出片段時：有界搜索 + 惰性串流
let s = @elab.hou_unifier_stream_new(t1, t2, budget)
while !@elab.hou_unifier_stream_is_exhausted(s) {
  let unifier = @elab.hou_unifier_stream_next(s)   // 按需拉取
}

// 4) 雙向精緻化
let res = @elab.elab_check(uterm, expected_ty, env)
let core = @elab.elab_result_to_dterm(res)          // 交回 kernel 檢型
```

---

## 8. 驗證

```bash
moon test cubical/elaborator --target wasm-gc    # 單包微測試實測 0.35s
```
一等檢核：`check_hou_elaborator()`、`check_hou_matching()`、`check_hou_bounded_search()`、`check_hou_search_extensions()`、`check_hou_phase9_extensions()`。
