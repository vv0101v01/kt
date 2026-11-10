# `cubical/face_bdd/` — 區間與面的決策引擎（Layer 0）

> **套件**：`vv0101v01/cubical-hermitian/cubical/face_bdd` · **Layer 0** · 零依賴（只有 `moonbitlang/core/debug`）
> **上游**：無（全倉最底層之一，與 `gcd/` 同層）
> **被依賴**：`cubical-finite`、`cubical-hermitian`、`cubical-kernel`、`cubical-homotopy`、`cubical-store`、`accel`、`root`
> **5 檔 6,209 行**

---

## 1. 定位

整個立方型別論的「面」是**共纖維化（cofibration）**公式；本套件提供兩種互補的決策程序：

| 決策 | 表示 | 給出什麼 | 何時用 |
|---|---|---|---|
| **ROBDD（規範形）** | 共享 DAG，節點 intern | 「兩個面是否相等」變成**根節點 ID 相等** ⇒ `O(1)` | `kernel` 的日常轉換檢查 |
| **CDCL（證明）** | Tseitin CNF + watched literals | 可獨立複驗的 **DRUP / DRAT / LRAT** 證明 | 需要「為什麼不可滿足」時取證 |

另有第三條：**SWAR 真值字**（`accel` 用 64 個賦值同時求值）與**有界樹寬前沿 BDD**（`n = 22..26`）。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `interval.mbt` | 241 | De Morgan 區間 `Dim` 與面公式 `Face` 的語法、語義與基本定律 |
| `bdd.mbt` | 429 | 樹狀 ROBDD：`Bdd`、`bdd_of_face`、布林運算、語義化簡與替換 |
| `bdd_dag.mbt` | 2,495 | 可擴展主表示 `BddManager`（intern + apply 記憶化）、restrict/exists/forall、DNF 回寫、`#SAT`、變數序最佳化 |
| `face_sat_watched.mbt` | 2,832 | Watched-literal DPLL / CDCL，含 DRUP、DRAT、LRAT 證明之產生與檢查 |
| `bdd_cutwidth.mbt` | 212 | `[T-Frontier-ROBDD]` 有界樹寬前沿變數序 |

---

## 3. `interval.mbt` — 語法與語義

```moonbit
pub(all) enum Dim  { DZero; DOne; DVar(Int32); DNeg(Dim); DMin(Dim, Dim); DMax(Dim, Dim) }
pub(all) enum Face { FTop; FBot; FEq0(Dim); FEq1(Dim); FAnd(Face, Face); FOr(Face, Face) }
```
* `Dim` 是 **De Morgan 代數**：`∧ = min`、`∨ = max`、`¬(x) = 1 − x`；語義 `eval_dim : Dim → Iⁿ → I`，在端點上退化成布林函數。
* `Face` 是共纖維化：`(r = 0)`、`(r = 1)`、`∧`、`∨`。
* 判定原語：`face_sat`（有無端點賦值使其成立）、`face_unsat`、`face_le`（蘊含）、`face_eq_mod`（面商相等）、`face_holds`。
* 定律：`interval_laws_hold()` 驗 De Morgan 律、分配律、端點互斥 `(i=0) ∧ (i=1) = ⊥`。
* 便利建構子：`dim_var`、`dmin`、`dmax`、`face_top`、`face_bot`、`face_eq0`、`face_eq1`、`face_and`、`face_or`、`face_var0`、`face_var1`。
* `pow2`、`assignment_of_mask`：`2ⁿ` 個端點賦值的列舉（語義版的裁判）。

---

## 4. `bdd.mbt` — 樹狀 ROBDD（教學與小規模基準）

* `Bdd`：變數按遞增順序、相同子節點消除 ⇒ **規範形**；`bdd_of_face` 由語法建 BDD。
* `bdd_not` / `bdd_and` / `bdd_or`：以 `bdd_tree_cofactor` 做 Shannon 展開。
* `bdd_sat_face`、`bdd_face_le`、`bdd_face_eq`：可滿足、蘊含、相等。
* `face_witness`：不可滿足／不蘊含時**回傳具體見證賦值**（不是只回 `false`）。
* `dim_simplify` / `face_simplify` / `dim_subst` / `face_subst`：語法化簡與維度替換。
* `check_bdd_canonical()`：驗「同語義 ⇒ 同 BDD 結構」。
* 語義對照：`dim_vars_of`、`dim_nvars_sem`、`dim_eq_sem`、`face_nvars_sem`、`face_is_top_sem`、`face_is_bot_sem`、`face_is_sat_sem`（全部以 `2ⁿ` 賦值列舉為真相）。

> 樹狀版的問題：相同子圖重複出現，結構遞迴可能**指數次**重訪。這正是 `bdd_dag.mbt` 存在的理由。

---

## 5. `bdd_dag.mbt` — 生產用表示（2,495 行）

```moonbit
pub struct BddManager        // hash-consing：每個 (rank, low, high) 只存一份
pub(all) struct BddDagNode { rank; low; high }
```
* **intern**：`bdd_manager_new` / `bdd_manager_with_order`；`bdd_dag_false/true/var/not/and/or/xor`；`bdd_dag_build_face`、`bdd_dag_of_face`。
* **資源診斷**：`bdd_manager_node_count`、`bdd_manager_cache_stats`、`bdd_worst_case_nodes`、`bdd_dag_reachable_count`。
* **可逆**：`bdd_tree_of_dag`（DAG → 樹）、`bdd_dag_dnf_face`（→ 面的 DNF 語法）、`bdd_dag_witness`。
* **判定**：`bdd_dag_face_eq`、`bdd_dag_face_le`、`bdd_dag_sat_face`、`bdd_dag_sat_count`（精確 `#SAT`）、`bdd_dag_eval`。
* **量化**：`bdd_dag_restrict`、`bdd_dag_exists`、`bdd_dag_forall`。
* **變數序**：`bdd_var_order_candidates`，以及四種建構策略 `bdd_dag_of_face_best` / `_optimized` / `_optimal` / `_optimal_dp` / `_optimal_pruned` / `_optimal_decomposed`（DP 與剪枝／分解）。
* **與 DPLL 的仲裁**：`face_eq_within_budget`、`face_sat_decide`、`face_eq_decide`。
* 自檢：`check_bdd_dag_native_operations()`、`check_bdd_cost_optimizations()`。

**核心不變量**（全倉都靠它）：在**同一個 manager** 內，`root₁ == root₂` ⟺ `face₁ ≡ face₂`（面商語義相等）。

---

## 6. `face_sat_watched.mbt` — CNF 與證明（2,832 行）

流程：`Face` + 原子內的維度式 → **Tseitin 擴展變數**轉 CNF → watched literals + saved phase + 衝突驅動變數活性搜索。

| 群 | 函式 |
|---|---|
| 統計 | `face_cnf_stats`（子句數、變數數、Tseitin 比例） |
| 搜索 | `face_sat_watched_dpll`、`face_eq_watched_dpll`、`cdcl_Luby`（Luby 重啟序列）、`face_sat_cdcl_report` |
| 經典入口 | `face_sat_cdcl`、`face_eq_cdcl` |
| **證明產生** | `face_sat_cdcl_proof` → `FaceCdclProofResult`（逐步 `FaceCdclProofStep`） |
| **證明檢查** | `face_cdcl_proof_check`（RUP 檢查）、`face_cdcl_drup_check`、`face_cdcl_drat_check`、`face_cdcl_drup_trim`（裁剪成核心）、`face_cdcl_lrat_check`（LRAT 逐步檢查）、`face_cdcl_elaborate_lrat`（DRUP → LRAT 精緻化） |
| 二進位 LRAT | `face_lrat_to_binary`、`face_lrat_from_binary`、`face_cdcl_lrat_check_binary` |

**為什麼要三種格式**：DRUP 好產生、DRAT 容忍刪除子句、LRAT 可以**逐行**被外部檢查器複驗（`FaceLratStep` 帶 antecedents）。`kernel` 只在需要「不可滿足的證據」時才付這筆成本。

---

## 7. `bdd_cutwidth.mbt` — `[T-Frontier-ROBDD]`

`bdd_dag_of_face_frontier_treewidth(face, n, order)`：以**割寬／BFS 前沿**變數序建 BDD。
* 示範實例：連通圖 `chain22 .. chain26`（`n = 22..26`），在樸素固定序下會爆，在前沿序下可得**精確**模型數
  `#SAT = 2ⁿ − F_{n+2}`（Fibonacci 補集）。
* 輸出 `BddFrontierBuild`（節點數、前峰值、是否超預算）。

---

## 8. 對外最常用 API

```moonbit
// 語義判定（小規模、教科書版）
@face_bdd.face_sat(f)            // Bool
@face_bdd.face_le(f, g)          // f ⊆ g ?
@face_bdd.face_eq_mod(f, g)      // 面商相等

// 規範形（生產版）
let mgr = @face_bdd.bdd_manager_new()
let r1 = @face_bdd.bdd_dag_of_face(mgr, f)
let r2 = @face_bdd.bdd_dag_of_face(mgr, g)
assert_true(@face_bdd.bdd_dag_face_eq(mgr, r1, r2))   // O(1) 的相等判定

// 精確模型計數
println(@face_bdd.bdd_dag_sat_count(mgr, r1))

// 不可滿足的證明
let pf = @face_bdd.face_sat_cdcl_proof(f)
assert_true(@face_bdd.face_cdcl_drat_check(pf))
let lrat = @face_bdd.face_cdcl_elaborate_lrat(pf)
assert_true(@face_bdd.face_cdcl_lrat_check(lrat))
```

---

## 9. Kalman 雙軌自由 De Morgan 區間、CCHM 上纖維化格與 64-Bit SWAR 真值快徑（`demorgan_cchm_swar.mbt`）

* **自由 De Morgan 區間 `I_DM`（Kalman 1958 嵌入定理）**：`dim_is_zero_demorgan`、`dim_is_one_demorgan`（Kleene 三值雙軌 `O(|r|)` 零配置端點判定，嚴格保持 `i ∧ ¬i ≠ 0`、`i ∨ ¬i ≠ 1`）與 `dim_eq_demorgan`（`2n` 單調生成元 `UInt64` SWAR／`bdd_dag` 自由分配格嵌入）。
* **自由 CCHM 上纖維化格 `Cofib(n)`**：`cchm_face_eq`、`cchm_face_is_top`、`cchm_face_is_bot`、`cchm_face_le`（嚴格保持邊界 `(i=0) ∨ (i=1) = ∂I ≠ ⊤_F` 與端點互斥 `(i=0) ∧ (i=1) = ⊥_F`）。
* **64-bit `UInt64` SWAR 6 變量真值快徑與規範面鍵**：`swar_face_truth_u64` 將 `n ≤ 6` 之 `bdd_face_eq`、`bdd_face_is_bot`、`bdd_face_is_top`、`bdd_face_entails` 加速為 `O(|f|)` 單暫存器位運算；`face_bdd_canon_key` 為依賴核心 `DSystem` 分支去重提供語義等價規範鍵。

---

## 10. 驗證

```bash
moon check --deny-warn --target wasm-gc
```
一等檢核函式：`interval_laws_hold()`、`check_bdd_canonical()`、`check_bdd_dag_native_operations()`、`check_bdd_cost_optimizations()`。
