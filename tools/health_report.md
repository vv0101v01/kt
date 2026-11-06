# 全代碼健檢報告（自動產生）

由 `python3 tools/health_scan.py` 產生。此檔是**報告**，不是閘門；閘門仍是
`moon check --deny-warn` + `python3 tools/arch_check.py`。

## 0. 規模

| 項目 | 數量 |
|---|---|
| 掃描到的函式定義 | 5229 |
| 完全無引用（死碼候選） | 4 |
| 完全相同函式體的重複組 | 0 |
| 結構極相近的重複組 | 0 |

## 1. 死碼候選（全倉零引用）

| 檔案 | 行 | 可見性 | 名稱 |
|---|---|---|---|
| `accel/bitslice_m4ri_f3.mbt` | 235 | pub | `gf3_sub64` |
| `bridge/grand_unification.mbt` | 326 | pub | `run_grand_unification_system` |
| `bridge/rotation_axis_bridge.mbt` | 460 | pub | `rotation_axis_certificate` |
| `condensed/quaternion_axis.mbt` | 805 | pub | `cond_quaternion_axis_conserved` |

## 2. 完全相同的函式體

（無）

## 3. 結構極相近（同一組識別字集合，疑似複製貼上）

（無）

## 4. 本輪處置（2026-11）

| 類別 | 動作 | 對象 |
|---|---|---|
| 重複實作 | 刪 | `ramsey_assign_witness`（與 `ramsey_assign` 同構）、`solvable_all`（同套件已有 `solves_all`） |
| 零引用轉發／佔位 | 刪 | `ramsey_loop_detect_window`、`stlc_ex_arg` 的獨立實作（改為轉發 `stlc_ex_id`） |
| 零引用但可救 | 接上定律 | `cx_f_vector`、`ord_max`、`iholed`、`env_fingerprint`、`cert_to_string` |
| 其他聯邦零引用且文檔未提及 | 刪 | `int_abs`、`gf3_slice64_pack`、`check_intuitive_conjecture_lab` |
| 其他聯邦零引用但文檔有提及 | 保留 | `gf3_sub64`、`run_grand_unification_system`、`rotation_axis_certificate`、`cond_quaternion_axis_conserved` |
| 同名不同實作 | 合併 | `meta/instances/compose.mbt` 的 `ramsey_window` → 轉發 `@core.ramsey_upper` |
| 格式 | `moon fmt` | 全倉 |

**結果**：死碼候選 14 → 4（且剩下的 4 個都有文檔引用）；完全相同函式體 0；結構極相近 0。
閘門狀態：`moon check --deny-warn` 0 warning / 0 error、`arch_check` ok、
`cmd/main` 129/129、`cmd/metatheory` 437/437、`cmd/showcase` 47/47。

### 仍待處理（明示，不假裝清完）

1. `meta/core/algebra.mbt` 與 `cubical/hermitian/complex.mbt` 各有一份 `mat_mul` / `mat_identity`。
   這是**聯邦邊界**問題（meta 不依賴 cubical），不是單純刪一份；需要 `architecture.json` 層級決定。
2. 全域零引用掃描是文字級的，抓不到「只被反射／動態調用」的情形；本倉沒有此類調用，但這是方法的邊界。
3. 同名函式跨檔 58 組，其中絕大多數是不同 struct 上的同名方法（`Graph::new` 等），不是重複邏輯；
   只有 `ramsey_window` 一組是真的重複，已合併。
