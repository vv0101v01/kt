# cubical-hermitian 架構與依賴治理

[中文規格](SPEC.md) · [English specification](SPEC.en.md) · [中文指南](GUIDE.md) ·
[English guide](GUIDE.en.md) · [中文符號附錄](SPEC-APPENDIX.md) ·
[English appendix](SPEC-APPENDIX.en.md)

> English summary: MoonBit compiles each package as one mutually
> recursive unit, so files inside a package have no compilation
> order.  This project implements a governed **Double-V (`V₁ → X → V₂`),
> X-Overlap & Star-Prism 7-Federation Architecture + Unification Apex**
> (`cubical`, `symlib`, `semiring`, `topos`, `scheme`, `condensed`, `discovery` +
> `unification`) spanning **31 packages / 49 components across 7 package
> layers (`0..6`)**:
> - **Lower-V Apex `V₁` (Layer 0)**: `@gcd` (Universal Elimination-GCD: RREF, HNF, SNF, Bézout).
> - **Divergent Lower-V Arms (Layers 1–2)**: `@algebra`, `@sym`, `@hostfs`, `@semiring/*`, `@topos`, `@scheme`, `@tensor`.
> - **Central X-Overlap Pivot `X` (Layer 3)**: `@condensed` (Condensed Mathematics, 4 condensed higher structures, 2 categories `CondCategory` & `CanonElimCategory`, Steenrod–Adams cohomology, SNF conservation-law ledger, and 4 base conjectures).
> - **Convergent Upper-V Arms & Discovery Loop (Layer 4)**: `root` (`cubical` kernel + Phase 21 breakthroughs) and `@conjecture` (6 evolutionary transfer laws, 5 epistemic lenses, and Lakatosian 12-conjecture atlas `CONJ-01..CONJ-12`).
> - **Upper-V Apex `V₂` (Layers 5–6)**: `@bridge` (`K_7` = 21/21 bridges, `[T-X-Chiasmus]`, Star-Prism synthesis, 46/46 unification certificates) and `@cmd/showcase`.
> `architecture.json` partitions all 31 packages, assigns every `.mbt` file to
> exactly one component, and `tools/arch_check.py` enforces the DAG.

## 1. 先回答：「60+ 個檔案之間有沒有先後依賴？」

有**邏輯依賴**，但同一 MoonBit package 內沒有**檔案編譯先後**。
MoonBit 以 package 為編譯單位：同一目錄的 `.mbt` 宣告共同求解，
函數與型別可以互相遞迴，所以把 `a.mbt` 改名、與 `b.mbt` 交換
目錄次序，都不會改變語義。不過若完全不管依賴方向，核心、模型、
前端與登記表會彼此糾纏，日後任何盤點都要重新通讀六十多個檔案。

因此架構分成兩級：

1. **cubical 支柱實體 package 子圖（編譯器強制；全倉另有 symlib、semiring、bridge 與各 apps）**

   ```text
   vv0101v01/cubical-hermitian/cmd/main
                    │ imports
                    ▼
   vv0101v01/cubical-hermitian            （root package）
                    │ imports @algebra
                    ▼
   vv0101v01/cubical-hermitian/algebra
   ```

2. **邏輯 component DAG（`tools/arch_check.py` 守門）**：root 內部
   仍是一個 package，但每個檔案被指派到恰好一個 component。
   高層可依賴同層互遞迴群與低層；低層不得引用高層。登記表與
   laws/tests 是刻意置於頂層的「可看全局」層。

`architecture.json` 是唯一清單來源；本文件只解釋規則，不複製
每次都會變的總行數。

## 2. 雙V形（Double-V）＋X形交疊（X-Overlap）＋星稜柱七聯邦架構與 Component 層級

全倉於第二十一至二十二期升級為 **雙V形（`V₁ = @gcd` → `X = @condensed` → `V₂ = @bridge`）＋X形交疊＋Lakatos 發現迴圈七聯邦架構（7 Federations + Unification Apex）**，跨 **7 個套件層級（`0..6`）** 治理 **31 個套件、49 個 component**：

| 聯邦／頂層 | 幾何位置 | 套件數 | 實體套件 | 跨聯邦允許匯入 | 核心職責 |
|---|---|---:|---|---|---|
| **F1 `cubical`** | 上 `V₂` 左翼同倫核心 | 4 | `algebra`（L1）、`hostfs`（L1）、`root`（L4）、`cmd-main`（L5） | `condensed:gcd`、`condensed:condensed` | 精確代數與超越數認證、Ed25519 BFT 持久層、立方依賴型別論與原 §四七大邊界突破 |
| **F2 `symlib`** | 右翼離散對稱臂 | 3 | `symlib`（L1）、`cmd-symdemo`、`cmd-symbench` | `[]` | 有限置換群、著色規範標號、Burnside 標記、`G-Set` 單子、有限範疇與 Kan 擴張 |
| **F3 `semiring`** | 右翼熱帶冪等臂 | 17 | `semiring/*`（16 包，L1–L3）＋`cmd-semiringreport` | `[]` | 冪等／星閉／熱帶半環、分塊／Lehmann 矩陣閉包、加權 CSR 圖與 Brzozowski DFA 正規形 |
| **F4 `topos`** | 左翼層化邏輯臂 | 1 | `topos`（L2） | `condensed:gcd`、`cubical:algebra`、`symlib:symlib` | Grothendieck 與初等 Topos、子 Topos 核、Kripke–Joyal 語義、群胚疊與神經上同調（SNF 撓率委派 `@gcd`） |
| **F5 `scheme`** | 左翼代數幾何臂 | 1 | `scheme`（L2） | `cubical:algebra` | 多變量 Gröbner 理想、黏合概形、Kähler 微分與 Eisenbud Fitting 平滑性、Serre 對偶、吹脹與動機 |
| **F6 `condensed`** | **下 `V₁` 基底＋中央 `X` 形交疊樞紐** | 2 | `gcd`（L0）、`condensed`（L3） | `cubical:algebra`、`symlib:symlib`、`semiring:semiring-trop`、`topos:topos`、`scheme:scheme` | 下 `V₁` 泛消元新最大公因數（RREF/HNF/SNF/六路對帳證書）、凝聚範疇 `CondCategory`、規範消元範疇 `CanonElimCategory`、凝聚高階結構×4、Steenrod–Adams `2η=0`、SNF 守恆律賬本與基礎猜想實驗室 |
| **F7 `discovery`** | **多線性幾何翼（L2）＋Lakatos 發現迴圈（L4）** | 2 | `tensor`（L2）、`conjecture`（L4） | `condensed:gcd`、`condensed:condensed`、`cubical:algebra`、`symlib:symlib`、`semiring:semiring-trop`、`topos:topos`、`scheme:scheme` | $\mathbb{F}_3$ 全體 6,561 張量伽羅瓦分類 `[1,128,4032,2400]`、離散 Radon 精確反演、Clifford 旋量／$T^2$ 規範場、非交叉層景與 VR 持續同調、6 組跨尺度演化轉移定律、5 大認識論關係透鏡與更新後 Lakatos 十二猜想圖譜（`CONJ-01..12`） |
| **Apex `unification`** | **上 `V₂` 星稜柱收斂頂點** | 2 | `bridge`（L5）、`cmd-showcase`（L6） | 單向觀察全部七聯邦（禁止反向匯入） | 七聯邦 `K_7` 完全圖全 21 條跨聯邦橋、`[T-X-Chiasmus]` X 形四葉對偶定理、星稜柱猜想合成與 46 項大一統證書 |

下表詳列 `cubical` 聯邦的 13 個 component；其餘聯邦與 `unification` 頂層 component 的即時明細以
`architecture.json` 與 `tools/arch_check.py` 輸出為唯一來源。

| 層 | Component | 實體套件 | 職責 | 可依賴 |
|---:|---|---|---|---|
| 0 | `foundation` | root | De Morgan 維度、面公式、ROBDD、DAG BDD、sifting／對稱軌道剪枝與連通分解精確序 DP，與 Tseitin／watched-literal DPLL、CDCL+DRUP/DRAT/索引化 LRAT（`CHLRATBN`） | — |
| 1 | `numeric-hermitian` | root | 浮點複線性代數、投影、向量系統、仿射立方體 | foundation |
| 1 | `exact-algebra` | **algebra** | BigInt 精確多項式、Hensel／LLL／Van Hoeij 因式分解與聯合圖樣證書、根隔離、`Q̄⊂ℂ` Rouché 代數閉包、分裂域、多二次塔與實代數根式、Q 線性代數、代數數、Jordan、譜恆等式、區塊消重根／自適應 Jacobi | —（Moon core 以外） |
| 2 | `finite-cubical` | root | 簡單型別 NbE/HOAS、有限宇宙、wiring、PathP、Glue、J | foundation |
| 3 | `dependent-kernel` | root | 一個刻意保留的 SCC：依賴 NbE、AST Kan（含 `0~1` 黏合圓／環面開盒）、Equiv/Glue、checked lines、DTerm transforms／intern 圖、DSATUR 最大團 DSystem 完成、schema 生成、語義容器正性憑證、一等層級與大宇宙／Dybjer–Setzer 開放同時宣告 | foundation、finite-cubical |
| 4 | `dependent-kan-lines` | root | 宿主層 `DLine`、維度代換與簡單／有限型別嵌入 | foundation、dependent-kernel、finite-cubical |
| 4 | `models` | root | 範疇模型、有限／子空間 Glue comp、認證數值影子與一般代數認證 | foundation、numeric、finite、exact-algebra |
| 5 | `frontend` | root | pattern／Huet 延遲 flex-flex 約束圖／惰性合一串流 elaborator、參數化模組、DAG 拓樸介面雜湊重連結、穩定 byte codec、CHDAGBIN 共圖、SHA-256/512＋RFC 8032 Ed25519 CHARTSIG、CHWALJRN 交易日誌與三方倉庫合併 | dependent-kernel、foundation（模組 codec 內的 `Dim`／`Face`） |
| 5 | `cubical` | root | S³／一般 `SuspS(A)`、環路—懸掛伴隨 `Σ⊣Ω`、Freudenthal 0-連通定理與圓楔連通、`π₁(S¹)≃ℤ`、纖維化環路序列、開放 Hopf–Freudenthal 收縮與 `π₂(S²)` 分裂截面、五維 Stasheff `K₅`、命題與集合截斷 `SetTruncS`、開放雙向雙射認證 `DVEquiv`、立方體演算法與計算性單值性 | foundation、finite、dependent-kernel、exact-algebra（精確有理 Hopf 的 `Rat`） |
| 6 | `laws` | mixed | `*_laws.mbt` 行為律見證 | 同套件內較低層 |
| 7 | `registry` | root | theorem/spec 登記表與 root→algebra 的集中匯入邊界 | 全部較低層 |
| 8 | `tests` | mixed | `*_wbtest.mbt` / `*_test.mbt` | 被測套件 |
| 9 | `app` | cmd-main | `moon run cmd/main` 執行入口 | registry 的公開介面 |

檔案明細不在此重複維護；執行：

```bash
python3 tools/arch_check.py
python3 tools/arch_check.py --list-edges
python3 tools/arch_check.py --json
```

第一條會輸出當下每個 package/component 的檔案與行數。

## 3. 為何只物理拆出 `algebra/`？

第八期的原則是 **hybrid**：先拆真正低耦合、可由編譯器守住邊界
的領域，不把互相遞迴核心硬切成多個 package。

`algebra/`（`symalg`、`qpoly`、`qmat`、`algnum`、`Jordan`、
`spectral_symbolic`、`Jacobi_interval`、`qpoly_factor`、`qpoly_certificate`、
`root_isolation`、`splitting_field`、`radical_denest`、`biquad_denest`、
`tower_fields`、`multiquad_tower`、`poly_cube` 與其 laws/tests）原本就沒有
引用立方體核心，root 只是使用它，屬於教科書式單向依賴，所以
成為真正的 MoonBit 子套件。它只使用 MoonBit core 套件（debug/math 與 prelude BigInt）；
root 在 `moon.pkg` import 它為 `@algebra`，公開符號集中由
`algebra_imports.mbt` 以非公開 `using @algebra { ... }` 導入 root
真正需要的名稱。這不把 algebra 符號冒充 root 自身 API 重出口；
符號附錄會把套件欄標成 `algebra`。

`foundation` 暫不實體拆出，原因是 MoonBit 的可見性語義：
`using` 只導入型別、trait 與函數，不導入 enum 構造子；
一般 `pub` 型別在其他 package 是 readonly；若直接公開其構造子需
升成 `pub(all)`（合併時對 `Ty`/`Dim`/`Face` 改採窄域公開構造函數，
避免把表示全部公開）。`Dim`、`Face`、`Bdd` 的構造子在 root
有數百處直接使用，搬遷會變成大規模
`Dim::DZero` 式改寫，且等於把內部表示永久公開。收益
低於擾動，故 foundation 現為同 package 的邏輯 L0，由
arch check 禁止它向上引用；核心 `dependent-kernel` 亦同理
保留為一個 SCC。

## 4. 計數不再靠人工通讀

| 問題 | 權威來源 | 命令 |
|---|---|---|
| 有哪些 package、檔案屬哪一層？ | `architecture.json` | `python3 tools/arch_check.py --json` |
| 是否出現反向／跨層非法邊？ | checker 的 package 圖與 component 邊 | `python3 tools/arch_check.py` |
| 公開 API 有幾個符號、屬哪個套件？ | 各套件 `pkg.generated.mbti` | `moon info && python3 tools/audit_spec.py --check` |
| SPEC 逐符號附錄 | 由 mbti 生成的雙語附錄 | `tools/audit_spec.py --write` |
| 定理幾條、測試幾個？ | 登記表與測試執行器 | `moon run cmd/main`、`moon test` |

文件中的整數字面量（測試數、定理數、符號數）每次發版以工具
輸出回填；若文件與工具不一致，以工具與 `moon test` 為準。

## 5. Checker 保證甚麼、不保證甚麼

`tools/arch_check.py` 會：

- 從 manifest 展開每個 `.mbt`，要求每個檔案恰被登記一次；
  新增檔案若未歸位，立即失敗；
- 比對各 `moon.pkg` 的 package import 與 manifest 層級；
- 由原始碼近似抽取「型別／大寫識別字」全域引用與「小寫函數」
  直接呼叫，建立 component 邊，拒絕未核准的上行邊；
- 統計 package/component 的檔案數與行數。

它不是 MoonBit 類型檢查器：同名局部綁定、欄位名與模式變量
仍可能讓近似邊有誤判風險。checker 因此只採用較保守的呼叫
證據，並忽略點號後欄位；真正硬邊界仍是 package 圖與
`moon check --deny-warn`。若出現看似合法的新邊，處理順序是：

1. 若低層真的需要該概念，把小型通用 helper 下移到正確層；
2. 若是登記表才需要的全局檢查，把檢查移到 `verify.mbt`；
3. 只有經人工確認的特殊情況才可考慮在 manifest 加例外，
   且必須在同一變更中說明理由。現時 `exceptions` 為空。

## 6. 新增檔案的歸位流程

1. 先判斷職責層，再寫程式：基礎謂詞不能偷偷呼叫前端。
2. 把檔案加入 `architecture.json` 恰一個 component；若沒有
   合適 component，先討論新增 component 及其層級。
3. 新公開符號執行 `moon info`，再為其在
   `tools/audit_spec.py` 分類並重新生成雙語附錄。
4. 新數學檢查接入 `verify.mbt` 與 `spec.mbt`，不得只存在於
   未登記的測試檔。
5. 提交前最小門檻：

   ```bash
   moon fmt
   moon check --deny-warn
   moon test --target wasm-gc
   moon run cmd/main
   moon run cmd/showcase
   python3 tools/arch_check.py
   python3 tools/audit_spec.py --check
   ```

## 7. 第八期依賴整理實際做了甚麼

- 抽出實體 `algebra/` package，並建立 root 集中匯入邊界。
- 把原本位於 Kan 核心的全局 `check_kan_all_types` 移到
  registry 層 `verify.mbt`，消除 kernel→models 的上行引用。
- 把 `eps` 下移至 foundation 的 `interval.mbt`；把
  Nat/Bool 值 helper 移至 kernel 的 `dterm_transform.mbt`；
  把範例投影量下移至 `projector.mbt`，使 numeric 層不依賴模型層。
- `cubical_algorithms.mbt` 與 `univalence.mbt` 登記在
  L5 `cubical`：只往下呼叫核心 `coe/comp/fill`、Equiv/Glue 與
  checked lines，覈心沒有反向呼叫它們。
- SPEC 的逐符號巨表已拆至生成的
  `SPEC-APPENDIX.md` / `SPEC-APPENDIX.en.md`，正文只保留設計
  規格；附錄新增 Package 欄，一個符號屬於 root 還是 algebra
  由產生的 mbti 決定。


## 8. 第九期新增檔案如何歸位

第九期沒有新增實體套件或邏輯層；新檔案按既有責任歸位：
`algebra/qpoly_factor.mbt`、`root_isolation.mbt`、
`splitting_field.mbt`、`radical_denest.mbt` 屬 L1 `exact-algebra`；
`schema_phase9.mbt` 因與 DTerm/schema 核心互呼叫而屬 L3
`dependent-kernel`；`certified_algebraic.mbt` 屬 L4 `models`；
`module_compilation.mbt` 屬 L5 `frontend`；
`sphere_homotopy.mbt`、`equivalence_phase9.mbt`、`truncation.mbt`
屬 L5 `cubical`。`dependent-kan-lines` 因新的 `DLine` 代換直接
使用 L0 的 `Dim` 求值，manifest 明示其對 `foundation` 的邊。
Root 的 `moon.pkg` 另加入 core `math` 供 Hopf 連結積分的三角函數；
它不是專案套件邊，實體圖仍是 `cmd/main → root → algebra`。

## 9. 第十期新增檔案如何歸位

第十期同樣沒有新增實體套件或邏輯元件：

- `face_sat_watched.mbt` 只使用 L0 的 `Dim`、`Face`，以及
  `bdd_dag.mbt` 既有的 face decision 型別，因此屬 L0
  `foundation`；它讓 foundation 自己提供 canonical BDD 之外的
  watched-literal 搜尋，不引入核心反向依賴。
- `equivalence_phase10.mbt` 與 `sphere_classification.mbt` 是建在
  dependent kernel 上的高層 cubical 構造，屬 L5 `cubical`。
  前者放一般 `lemIso`、纖維收縮與 adjointification；後者放
  `IntegerS`、π 商型與典範環路代表元。
- `module_binary.mbt` 屬 L5 `frontend`。其 DTerm codec 無可避免地
  要編碼核心項中的 `Dim` 與 `Face`，所以 manifest 新增了直接的
  `frontend → foundation` 邊；這是下行邊，不改變實體套件圖
  `cmd/main → root → algebra`。
- BDD cost 改動直接落在既有 L0 `bdd_dag.mbt`，QPoly 的
  sparse／Karatsuba 路徑直接落在既有 L1 `algebra/qpoly.mbt`，
  root 也只在既有 `algebra_imports.mbt` 邊界多匯入一支檢查函數。
- 新白箱測試由既有 L8 `tests` wildcard 收納；新增檢查均已接入
  L7 `verify.mbt`、`spec.mbt` 與雙語附錄審計，沒有只在測試檔
  存在的孤兒結果。


## 10. 第十一期新增檔案如何歸位

第十一期同樣沒有新增實體套件或邏輯元件：

- `algebra/biquad_denest.mbt`、`algebra/poly_cube.mbt` 屬 L1
  `exact-algebra`：前者只用同套件的 `QuadNum`/`AlgNum` 機械，
  後者是精確多項式座標的立方與開盒，不引入跨套件邊。
- `dcube_filler.mbt` 與 `dterm_intern.mbt` 屬 L3
  `dependent-kernel`：前者與 `dsystem_compat.mbt`、`kan_ast.mbt`
  互呼叫（開盒的相容檢查與 comp 填充本來就屬核心 SCC），後者是
  `DTerm` 自身的子項遍歷/重建，與 `dterm_transform.mbt` 同層。
- `schema_registry_persist.mbt` 屬 L5 `frontend`：它重用
  `module_binary.mbt` 的 codec 基礎設施（同一元件）編碼 L3 的
  registry；核心不需要知道位元組層。
- `circle_classify.mbt` 屬 L5 `cubical`，與
  `sphere_classification.mbt`、`sphere_homotopy.mbt` 並列：它是
  建在 kernel 之上的覆疊/分類構造。為其所做的
  `comp_glue_equiv_value` 端點合成改動落在既有 L3
  `equiv_ast.mbt`，且只在「端點無分支而一般點有分支」時生效。
- `phase11_laws.mbt` 由 L6 `laws` 的 `*_laws.mbt` wildcard 收納，
  承接原本只在白箱測試的第十一期斷言體，使 L7 registry 能直接
  執行；root 只在既有 `algebra_imports.mbt` 邊界多匯入四支代數
  檢查函數。實體套件圖仍是 `cmd/main → root → algebra`。


## 11. 第十三期新增檔案如何歸位

第十三期沒有新增實體套件、邏輯元件或 manifest 例外；兩個真正
新增的實作檔案按既有邊界歸位：

- `algebra/multiquad_tower.mbt` 屬 L1 `exact-algebra`。它只使用
  同套件的 `Rat`、二次/雙二次/三二次數與根式機械；root 若要把
  其總檢查納入定理表，只能經既有 `algebra_imports.mbt` 邊界
  新增 `check_multiquadratic_tower`（同批另加聯合證書與自適應
  Jacobi 兩支檢查），不把 `MultiQuadNum` API 偷渡成 root 依賴。
- `dterm_dag_binary.mbt` 屬 L5 `frontend`，不屬 L3 kernel：
  活 DAG 的節點/子邊仍由 L3 `dterm_intern.mbt` 擁有，但
  `CHDAGBIN` 的版次、checksum 與 byte reader/writer 重用同
  在 frontend 的 `module_binary.mbt` 基礎設施，且其主要消費者
  是同層的 `artifact_repository.mbt`。如此核心不反向知道持久
  格式，frontend 只向下讀取 kernel 的 intern snapshot。
- `phase13_laws.mbt` 由 L6 `laws` 的 `*_laws.mbt` wildcard
  收納，`phase13_wbtest.mbt` 及 algebra 的新增測試由 L8
  wildcard 收納；其餘第十三期工作（SelfFamily 正性、DSystem
  最大完成、方形 comp、BDD/CDCL、環路 3-胞、HOU 殘差求解與
  工件完整性鏈）均落在既有檔案與既有元件，未引入新上行邊。
  實體套件圖仍是 `cmd/main → root → algebra`。
