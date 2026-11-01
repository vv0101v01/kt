# `cmd/semiringreport/` — 19 節量測報告產生器（5 檔 2,799 行，**native only**）

> **套件**：`vv0101v01/cubical-hermitian/cmd/semiringreport` · `pkgtype(kind: "executable")`
> `moon.pkg` 的 `supported_targets: "native"` —— 因為它需要**單調時鐘、檔案系統與 async 主機後端**。
> **依賴**：`semiring` 的全部 15 個子套件 + `moonbitlang/core/math`

---

## 1. 定位

整個 F3 聯邦的**唯一產出物**。執行一次，會生成一份完整的 markdown 量測報告：

> 「每個『正確』都配一個獨立實作／暴力法；每個『更快』都給實際數字；每個『不能保證』都明確寫出來。」

所有數字都是**本次執行**算出來的，沒有一個是抄文件的。輸入用固定種子 SplitMix64 ⇒ 重跑得到**相同的輸入與相同的正確性結論**（時間隨機器浮動）。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `main.mbt` | 185 | 排版工具 + `main`（依序呼叫 §1–§19） |
| `report_sections.mbt` | 954 | §1–§9 + 兩個「定律破壞者」實例 |
| `report_extra.mbt` | 590 | §10–§13（稀疏／浮點／自動分塊／平行後端） |
| `report_v3.mbt` | 713 | §14–§18（熱帶幾何／規範形式／範疇化／演算法組合／連帶相信） |
| `report_v4.mbt` | 357 | §19（**誠實的限制**：把每一個邊界量出來） |

---

## 3. 排版工具（`main.mbt`）

```moonbit
fn line(s : String)          fn ratio(a, b) : String
fn section(id, f : () -> Unit)      // 印 "## §id" 再執行 f
fn round_to(x, digits) / f2(x) / f1(x)
fn rand_trop(rng, n, density, maxw) -> Mat[Trop]   // 固定種子的隨機熱帶矩陣
fn main
```
`main` 的骨架：
```text
# 量測報告（semiring-lab）
> 由 `moon run cmd/semiringreport --target native` 產生；所有數字都是本次執行的實測值。
> 測試與基準使用固定種子的 SplitMix64 …
section("1", sec1_axioms) … section("19", sec19_limits)
報告總產生時間：… ms（含全部建表與交叉驗證）
```

---

## 4. 十九章的內容

### §1–§9（`report_sections.mbt`）
| 節 | 主題 | 交叉驗證方式 |
|---|---|---|
| 1 | **公理**（定律） | `check_semiring` / `check_star` / …；並用 `ReportBroken`（`times = a+b+1`，破壞分配律）與 `ReportLying`（謊稱冪等）當**負對照**，斷言檢查器**必須**報錯 |
| 2 | 矩陣乘法 | `mul_naive` / `mul_ikj` / `mul_blocked` / `mul_trop` 結果一致 + 計時 |
| 3 | 記憶體 | `@sim` 的 cache 模型 miss 率與 DRAM 字數 |
| 4 | 閉包 | FW / Lehmann / 分塊 / 級數 四路結果一致（`counting_inplace_demo`） |
| 5 | 圖 | Dijkstra vs Kleene vs 位集；`dec2_reach` 做獨立可達性判定 |
| 6 | 樣條 | 週期／稠密／帶狀 三路逐點相同 |
| 7 | 速率限制 | GCRA 決策統計 + 表淘汰 |
| 8 | 載入器 | `parse_edges_fast` vs `parse_edges_naive` |
| 9 | 么半群 | 前綴／段樹／稀疏表／Fenwick；`sp_checksum`、`brute_paths`、`count_paths` 為獨立裁判 |

### §10–§13（`report_extra.mbt`）
| 節 | 主題 |
|---|---|
| 10 | **稀疏**：`Csr` vs 稠密（`csr_to_trop_mat`／`trop_csr` 互相轉換後逐格比對） |
| 11 | **浮點**：`TropF` vs `Trop`；誤差與溢位邊界 |
| 12 | **自動分塊**：`mul_blocked_auto` / `closure_blocked_auto` 的參數選擇實測 |
| 13 | **平行後端**：`@par` / `@parh`，並誠實標示 native 後端是**單執行緒**（加速的是 I/O 等待，不是 CPU） |

### §14–§18（`report_v3.mbt`）
| 節 | 主題 | 亮點 |
|---|---|---|
| 14 | **熱帶幾何** | 牛頓多面體、對偶細分、`trop_det` 三路一致（`pct` 印比例） |
| 15 | **規範形式** | DFA 最小化 + 典範字串、Brzozowski 導數、么半群詞問題（`rand_sexpr` 隨機生成） |
| 16 | **範疇化** | `SetMat` → `decategorify` → 計數矩陣（基數保持乘法） |
| 17 | **演算法組合** | `@app` 的閉包與投資組合；`count_disagrees(@app.Verdict)` 統計兩半環的分歧數 |
| 18 | **連帶相信** | 樹上精確（與 `brute_force_sum_product` 逐位元相同）vs 有環的近似誤差 |

### §19（`report_v4.mbt`）— 誠實的限制
頂註已說明：**「這一節不是在道歉，而是在量測」**。

| 小節 | 量什麼 |
|---|---|
| 19a | 訊息傳遞 vs 暴力的**交叉點**在哪一個 `n`（不是「漸近更好」） |
| 19b | Maslov 去量化的**下溢邊界**在哪一個 `h` |
| 19c | 熱帶細分 `O(m⁴)` 在實測上長什麼樣 |
| 19d | 「可信度的價格」的結構：全跑 vs 只跑最便宜的兩個 |
| 19e | **只有一個候選時，錯誤不會被發現**（截斷級數的實例） —— 本節最重要的一條 |
| 19f | 限制總表：每一條限制對應哪一個量到的數字 |

輔助：`diff_cells(a, b)`（兩個熱帶矩陣逐格比對）、`chain_tree(n, seed)`（鏈狀樹的因子圖，供 §19a 用）、`f6`。

---

## 5. 執行

```bash
moon run cmd/semiringreport --target native          # 產出 markdown 到 stdout
moon run cmd/semiringreport --target native > report.md
```
其他 target 會**跳過整個套件**（`supported_targets: "native"`），因此全倉在 `wasm-gc` 上的編譯不受影響 —— 這正是 `semiringreport` 沒有污染主 CI 的原因。

---

## 6. 為什麼它值得 2,799 行

因為「證明一個半環庫是對的」不能只靠 `assert`。本套件把每條宣稱都變成**三方對照**：

```text
   宣稱「OO 演算法正確」  ⇔  獨立實作 / 暴力法 給出同一答案
   宣稱「XX 比較快」      ⇔  同一份輸入的實測毫秒數
   宣稱「YY 有限制」      ⇔  把限制的邊界數字印出來（§19）
```
第三條最罕見：大多數專案只做前兩條，然後在 README 寫「注意：有環時不保證」。這裡把它變成一個**可重跑的量測**。
