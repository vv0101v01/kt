# `cmd/` — 四個執行入口：定理總表、大一統展示、對稱演示／基準、半環量測報告

> **架構位置**：`architecture.json` 中本目錄包含 4 個**可執行套件**（`pkgtype(kind: "executable")`），位於 DAG 的最上層：
> `cmd-main`（Layer 7）、`cmd-showcase`（Layer 8）、`cmd-symdemo` / `cmd-symbench`（Layer 2）、`cmd-semiringreport`（Layer 5）。
> 它們**只消費、不生產**：任何下層套件都禁止匯入 `cmd/*`。

---

## 1. 總覽

| 子套件 | target | 依賴 | 用途 |
|---|---|---|---|
| `cmd/main` | 全 target | `root`（`vv0101v01/cubical-hermitian`） | 印出 **129/129 定理／定律總表** |
| `cmd/showcase` | 全 target | `bridge`、`semiring/graph`、`symlib`、`root`、`moonbitlang/core/debug` | 印出 **7/7 聯邦 · K₇ 21/21 · 47/47 大一統＋硬體加速證書** |
| `cmd/symdemo` | native 建議 | `symlib`、`moonbitlang/core/bench` | `symlib` 全功能演示（自同構群／作用／折疊／單子／範疇化） |
| `cmd/symbench` | native 建議 | `symlib`、`moonbitlang/core/bench` | 7 個**衍生演算法** vs 暴力／全搜索的對照基準 |
| `cmd/semiringreport` | **native only** | 15 個 `semiring/*` 子套件 + `moonbitlang/core/math` | 19 節量測報告（約 66 秒，屬**慢閘門**） |
| `cmd/ualg` | 全 target | `ualg/core`、`ualg/site`、`ualg/demorgan` | 第十聯邦定律總表：**141/141 個命題**（構造性泛代數 × 預層模板 × De Morgan 立方體），見 [`ualg/README.md`](ualg/README.md) |

一行指令速查：

```bash
moon run --release cmd/showcase      --target wasm-gc    # 大一統證書
moon run --release cmd/main          --target wasm-gc    # 定理總表
moon run --release cmd/symdemo       --target native     # 對稱演示
moon run --release cmd/symbench      --target native     # 對稱基準
moon run --release cmd/semiringreport --target native    # 半環量測（慢）
```

---

## 2. `cmd/main/`（6 行，最薄的入口）

```moonbit
///|
fn main {
  guard @lib.print_report() else { abort("theorem registry failed") }
}
```
`moon.pkg` 只有一個 import：`"vv0101v01/cubical-hermitian" @lib`（即根套件 `root`）。

* `@lib` 是**極薄精選門面**（`facade.mbt`，`pub using` 重導出 `@bridge` 與執行檔實際使用的符號；根 `pkg.generated.mbti` 已由重構前逾 4,300 行精簡 ~90% 至 484 行）。
* `print_report()` 由 `verify.mbt` 提供：逐條印 `定理名 → PASS/FAIL`，若任何一條失敗則回傳 `false`，`guard` 使程序以 `abort` 結束 ⇒ **CI 可直接用 exit code 判定**。
* `verify.mbt`（39.7 KB）是定理登記表本體，`spec.mbt`（147 KB）是規格；兩者都在根套件，不在本目錄。

---

## 3. `cmd/showcase/`（136 行）— 大一統展示

`main.mbt` 的輸出結構（依印出順序）：

```text
Golden Grand Unification — Seven-Federation Double-V, X-Overlap & Lakatosian Discovery Synthesis
================================================================================================
-- Seven Autonomous Mathematical Federations (7/7) --
[PASS] federation <slug>: <summary>
-- Complete K_7 Cross-Federation Pairwise Bridges (21/21) --
[PASS] K7-16: <bridge_theorem>
        <quantitative_witness>
...
-- X-Overlap Chiasmus, Double-V & Seven-Federation Star-Prism Discovery --
[PASS=..] X-Overlap Chiasmus: D1=.., D2=.., invariants=..
[PASS=..] Double-V: V1_gcd=.., federations=6/6, K6=15/15, boundaries_7=..
[PASS=..] Star-Prism Discovery: federations=7/7, K7=21/21, conjectures=12/12, evolve=6/6, lakatos_refined=..
[PASS=..] Conjugate-Quaternion Condensed Axis: families=4/4, integral_residual=.., RK4_order=.., conservation_laws=3/3
-- Unified Certificate Ledger --
[PASS] <source>: <name>
        <detail>
```

它呼叫的 7 個入口全部來自 `@bridge`：
`seven_federation_descriptors()`、`verify_k7_federation_bridges()`、`verify_x_overlap_chiasmus()`、`verify_double_v_architecture()`、`verify_seven_federation_star_prism()`、`verify_rotation_axis_bridge()`、`bridge_certificates()`。
另外統計 `source == "atlas"` 的通過數（幾何—邏輯 18 項圖譜）與 `source == "bridge/unification"` 的五邊形／六柱大一統證書；旋轉段亦輸出相干角 `11040→552→0`、276 個規範類與四族／中軸逐項數值差分；猜想段另印五條直覺猜想、實際搜索、反例與修正版（1 條有界倖存、4 條反例後修正）。

---

## 4. `cmd/symdemo/`（309 行）— 對稱全功能演示

`main.mbt` 的輔助結構：
* `timed(label, f)`：計時並印出；
* `versus(label, a, b)`：「衍生演算法 vs 直接演算法」的**同一結果、兩條路徑**對照；
* `list_monad_laws_ok()` / `state_monad_laws_ok()`：`ListM`（左單位／右單位／結合）與 `StateM` 的單子律。

覆蓋範圍：圖自同構群、群作用、軌道折疊、G-集單子、規範形式、（co)limit 泛性質、米田與 Kan 擴張。
設計要點：**全部演算法在同一作用域，一次搜索多模組消費** —— 這正是 `symlib` 的架構主張。

---

## 5. `cmd/symbench/`（594 行）— 衍生演算法基準

`main.mbt`（52 行）：完整管線計時（一次搜索 → Schreier–Sims → 群作用 → 軌道折疊），時間以**毫秒**呈現（`monotonic_clock_end` 原生回微秒，各處除以 1000）。

`derived.mbt`（542 行）：`btime(f)` 同時量「耗時」與「成本比 ×」，每項都**同時**驗「結果一致（OK/FAIL）」與「成本比」：

| 節 | 基準 | 賣點 |
|---|---|---|
| A | `bench_decomp`：分量分解 ⇒ `\|Aut\|` 積公式 | 免全搜索 |
| B | `bench_line`：Whitney 線圖定理 | 免對 `L(G)` 搜索 |
| C | `bench_dual`：補圖對偶雙通道 | 複雜度中性，賣點是**自我驗證** |
| D | `bench_marks`：標記向量是 G-集完全不變量 | 免階乘級枚舉 |
| E | `bench_permset`：`PermSet` 規範形可雜湊 | 資料庫級去重 `O(1)`/對（單次判定成本與暴力同階，但可快取重用） |
| F | `bench_fold`：規範折疊 | 一次搜索取代兩次 |
| G | `bench_cayley`：Cayley 定理 | `O(1)` 下界 `\|Aut(Cay(G,S))\| ≥ \|G\|` |

---

## 6. `cmd/semiringreport/`（2799 行）— 量測報告產生器

`moon.pkg` 顯式 `options(supported_targets: "native")`（需要單調時鐘、檔案系統與 async 主機後端）。

**設計原則（寫在 `main.mbt` 的檔頭）**：每一個數字都來自本次執行的真實計算 ——
時間取重複執行的最小值；運算量是半環 `⊕`/`⊗` 的實際呼叫次數（`Ops`）；記憶體把演算法實際發出的存取序列餵給兩層快取模擬器（`Tracer`）；正確性靠每節附帶的獨立實作交叉檢查。

| 檔案 | 行數 | 節 |
|---|---:|---|
| `main.mbt` | 185 | §1–§9 主控；`section(id, f)` 記錄每節耗時；`round_to` 是全報告唯一的格式化實作 |
| `report_sections.mbt` | 954 | §1–§9 主體。含兩個**負面對照**半環：`ReportBroken`（`times(a,b) = a+b+1`，破壞分配律）、`ReportLying`（謊稱冪等但 `⊕` 是普通加法）；另有 `counting_inplace_demo`（把非冪等半環硬塞進原地 Warshall 以示範「冪等前提是實質的」）、`brute_paths`（暴力列舉簡單路徑做交叉驗證） |
| `report_extra.mbt` | 590 | §10 稀疏 CSR vs 稠密（SpGEMM、稀疏 Kleene、`n × sssp`）；§11 浮點熱帶；§12 由快取預算**自動選**分塊；§13 平行後端實測 |
| `report_v3.mbt` | 713 | §14 熱帶幾何、§15 規範形式、§16 範疇化、§17 演算法組合（含一致性仲裁）、§18 連帶相信（BP） |
| `report_v4.mbt` | 357 | **§19 誠實的限制**：19a 訊息傳遞 vs 暴力的交叉點、19b Maslov 解量化下溢邊界、19c `O(m⁴)` 細分實測成長、19d「可信度的價格」、19e 只有一個候選時錯誤**不會被發現**（截斷級數實例）、19f 限制總表 |

---

## 7. 驗證與 CI 用法

```bash
# 快速閘（< 3 秒）
moon check --deny-warn --target wasm-gc
python3 tools/arch_check.py

# 里程碑閘（可進 CI，兩個都靠 exit code）
moon run --release cmd/showcase --target wasm-gc   # 47/47 證書，任一 FAIL 應使 CI 失敗
moon run --release cmd/main     --target wasm-gc   # 129/129 定理表

# 慢閘（手動／夜間）
moon run --release cmd/semiringreport --target native
```
