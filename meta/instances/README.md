# meta/instances — 全域實例（typeclass）的語義與工程

**層級 1。** 一個實例系統 = Horn 子句集 + SLD 解析 + 一致性判準 + 模組匯入圖。

| 檔案 | 內容 |
|---|---|
| `engine.mbt` | `Rule`/`Env`、`resolve_all`（合一＋深度界＋環路偵測）、`derivable_bruteforce`（**不做**剪枝的對照搜尋）、`enum_uterms`（目標窮舉）、`evidence`、`terminating`（序數度量）、`critical_pairs`／`coherent`、`canonical`／`maximal_derivs`、`repair_step`／`complete`、**`rule_oriented`／`orientable`／`repair_step_oriented`／`complete_oriented`（帶終止序的修補）** |
| `modules.mbt` | **匯入圖**：`Module`／`ImportGraph`、`scc`（Tarjan，迭代版）、`cyclic_components`、`cycle_witness`、**`resolve_modules`（典範解析：DAG ⇒ 反拓撲序；有環 ⇒ 拒絕並給真迴路見證）** |
| `compose.mbt` | `derivability_matroid`／`derivability_is_matroidal`、`minimal_instance_basis`、`glue`／`glues`／`monodromy_witness`、`mirror_rule`／`mirror_env`／`dual_derivable`、`pigeonhole_window`／`ramsey_window` |
| `coherence.mbt` | 完備一致性 `coherent_complete`、`resolve_canonical`（逐目標的典範解析）、可達目標宇宙 |

**不變式**：`terminating(env_show) = None`；`coherent` 對典範實例系統恆真；`mirror_env ∘ mirror_env = id`。

## 這一輪補完的三件事

1. **SLD 完備性（不是宣稱）**：`resolve_all` 用深度界＋路徑去環兩個剪枝，會影響完備性。
   為了驗證它沒漏解、也沒加假解，另外寫了刻意笨的 `derivable_bruteforce`（純 DFS、無環路偵測、
   只靠深度遞減終止），並在**窮舉出來的目標空間**（簽名 `Int/Bool/Array/Pair/Show`、大小 ≤ 6）
   對 3 個環境 × 4 個深度逐一比對：**21672 組目標/深度對**上兩邊可解性完全一致。
   另外分別檢查深度單調（解在 d ⇒ 解在 d+1）、含環環境不發散、以及「深度界真的會咬人」
   （`Show (Array (Pair Int Int))` 在 d=2 無解、d=3 有解）。
2. **修補的終止序**：上一版 `repair_step` 只靠優先級釘死歧義，本身不保證收斂到**終止**的重寫系統。
   現在新規則只在「`head` 的節點數嚴格大於每個 `body` 目標」時才加入（Knuth–Bendix 的 orient），
   定向不了的臨界對會被**報告**而不是硬塞；`complete_oriented` 反覆到沒有可修的東西為止。
3. **`resolve_canonical` 的循環匯入（＝模組匯入圖的良基性）**：`resolve_modules` 對匯入圖跑 Tarjan，
   SCC 大小 > 1 或自環 ⇒ 拒絕並給**真實迴路**（每步都是有向邊、首尾相同）；
   無環 ⇒ Tarjan 的反拓撲發射序就是典範解析順序（依賴先解），且與模組**宣告順序無關**。

**邊界**：`coherent` 在「觀察到的目標 + 給定深度」內完備，不是全域合流判定程序；
定向用的是節點數度量（不是完整 RPO/KBO），存在「節點數不定向但其實終止」的系統會被報告為未定向。
