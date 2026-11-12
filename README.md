# cubical-hermitian — 一部可執行的數學工程史

> MoonBit · `vv0101v01/cubical-hermitian` v2.0.0 · `preferred_target = "wasm"`
> **10 聯邦 + `unification` 大一統頂點 · 57 套件 · 66 元件 · 321 個 `.mbt` · 202,287 行**
> `python3 tools/arch_check.py` → `architecture ok`（2026-11-11 合併截面實測）· `cmd/main` → **139/139 定理** · `cmd/metatheory` → **631/631 定律** · `cmd/showcase` → **48/48 證書 + 54/54 立方結構**
> 全倉靜態健檢（遠端 2026-11-10 `health_scan.py` v3）：`5,810` 函式／方法 `0` 死碼 — **合併截面未重跑**，以遠端實測為準

這個倉庫把「依賴立方型別論 × 精確代數 × 有限對稱 × 冪等／熱帶半環 × 格羅滕迪克拓撲斯 × 代數幾何概形 × 凝聚數學 × 多線性張量與猜想發現 × 64-bit SWAR／WebGPU 硬體加速 × 元理論三軸引擎」寫成一份**可編譯、可判定、可複驗**的程式。它不是論文附錄，而是一條**有年月、有瓶頸、有突破**的工程線。

本 README 是全倉規格書（SPEC）的**工程史與架構全景濃縮版**：只保留「為什麼要這樣做、卡在哪、怎麼破、留下什麼」。
逐條規格與逐符號登記（`158` 條規格、`1,649` 個唯一公開符號，`0` 幽靈條目）看根套件 `spec.mbt` 的 `spec_registry`；全倉 **57 個套件資料夾**皆配備獨立 `README.md` 供逐檔精讀。

---

## 30 秒驗證

```bash
python3 tools/arch_check.py                           # 10 聯邦 + 頂點、57 套件、66 元件、321 .mbt / 202,287 行
moon check --deny-warn --target wasm-gc               # 0 warnings, 0 errors（wasm-gc / wasm / js / native 四目標零警告；遠端 2026-11-10 實測）
moon run cmd/symdemo        --target wasm-gc          # F2 有限對稱、Schreier–Sims、衍生演算法與單子律快驗
moon run cmd/metatheory     --target wasm-gc          # 631/631 定律（104 個 law_*，逐條重算；本地 2026-11-12 實測）
moon run cmd/main           --target wasm-gc          # 139/139 立方與跨領域主定理總表（遠端實測）
moon run cmd/ualg           --target wasm-gc          # 第十聯邦：ualg/core、site、demorgan、cube 全命題重算（本地）
moon run cmd/showcase       --target wasm-gc          # 9/9 聯邦 · K_9=36/36 全配對橋 · 四大跨聯邦合流管線 · 48/48 證書（遠端實測）
moon run cmd/semiringreport --target native           # 19 節半環與圖演算法量測報告（含限制之精確量化邊界）
python3 tools/health_scan.py > tools/health_report.md # 合併截面未重跑（遠端 2026-11-10：5,810 函式／方法，0 死碼）
```

---

## 一、工程發展史

倉庫以「期」與「輪」推進。每一階段的驗收方式都一樣：**新增登記條目 + 可執行的 `check_*` / `verify_*` / `law_*` 函式 + 雙路徑與負對照見證**；沒有做完的部分明示量化邊界，絕不以代表元抽樣或浮點觀察冒充一般定理。

| 階段 | 主題 | 關鍵突破 | 留下的核心模組 |
|---|---|---|---|
| 早期 §1.1–1.5 | 地基與依賴化 | η-long βπη 正規化；有限宇宙端點 `comp`；ROBDD／wiring／first-match 範形；NbE 與 Kan 擴至 Π／Σ／宇宙 | `cubical/finite`、`cubical/face_bdd`、`cubical/kernel/{nbe_dep,kan_dep}.mbt` |
| 早期 §1.6–1.8 | 立方 AST 與生成器 | 符號特徵值／投影子／仿射填充；Path、HIT 與 `hcomp` 按型別化簡；**通用 schema 生成器**（一份宣告同時生成 checker／eval／conv／quote／Kan） | `cubical/hermitian`、`cubical/kernel/{kan_ast,schema}.mbt` |
| **第六～十期** | 代數完備、單值性與商同倫 | 正性函子／互歸納／商／高維 HIT；一等 `Equiv`/`ua`/`Glue`；計算性單值性；`BigInt` 有理數、Sturm 實根隔離、Rouché 認證、分裂域塔；一般準逆自動伴隨化（adjointification）；核內 `IntegerS` 與 `π_n` 商型；有界 Huet 與模組位元組格式 | `cubical/kernel/{dsystem_compat,equiv_ast,univalence,schema_universe_poly}.mbt`、`algebra/`、`cubical/homotopy/{adjoint_equivalence,sphere_classification}.mbt`、`cubical/elaborator`、`cubical/store` |
| **第十一～十六期** | 開放同時 IR、同倫極限與 BFT 持久層 | 開放同時歸納—遞迴（Open IR）與容器正性；case-split 轉換、DAG 編解碼與主合一子 MGU；Hensel／LLL／Van Hoeij 多項式分解；Cuthill–McKee ROBDD 割寬與 CDCL DRUP/DRAT/LRAT；`π₁(S¹)≃ℤ`、`π₂(S²)≃ℤ`、Freudenthal 懸掛、Blakers–Massey、Brunerie `π₄(S³)≅ℤ/2ℤ` 與 `K₆` 相干胞；RFC 8032 Ed25519 + `3f+1` BFT 法定人數 WAL 與 Tarjan SCC 無鎖 MVCC 熱替換 | `cubical/kernel/schema_open_ir.mbt`、`algebra/lll_van_hoeij_rouche.mbt`、`cubical/face_bdd/bdd_cutwidth.mbt`、`cubical/homotopy/{associahedron,brunerie_pi4_s3}.mbt`、`cubical/store/module_bft_mvcc.mbt` |
| **第二十一～二十二期 + v2 拆包** | 雙 V + X 形架構與第九聯邦三軸 | 七項能力邊界全數突破；建立下頂點 `@gcd`、X 樞紐 `@condensed` 與上頂點 `@bridge`；建立零外部依賴**第九聯邦 `meta/`**（反射 NbE `decide_eq` + `check_cert`、全域實例 Horn/SLD + 臨界對 + 擬陣判準、歸納—歸納 Kleene 切片塔 + STLC β 索引傳輸、Paley `R(4,4)=18` / `R(3,5)=14`）；`cubical` 拆分為無環子套件 | `gcd/`、`condensed/`、`meta/`、`bridge/`、`architecture.json` |
| **自主泛代數 × 雙重否定預層 × 54 高階立方結構** | 構造性泛代數、`¬¬` 層化與全譜立方結構 | 馬爾采夫一步同餘可換 `θ∘ψ=ψ∘θ=θ∨ψ`、吸收零塌縮 vs 點化零阿貝爾二分；雙重否定核 `j(x)=¬¬x` 布林反射子 Topos 與亞歷山德羅夫／雙 Heyting／Chu 對偶；**Swan/CCHM 嚴格計算 `J` 恆等型 `Id_A(x,y)`**、極化聚焦 `LJF_cub`、函子多項式米田與單值 SIP、`S₃` 非阿貝爾覆蓋伽羅瓦對應、全體 `65,536` 個 4-立方體 `O(1)` SWAR Eilenberg–Zilber 標準分解（`[2,8,60,872,64594]`）與 `26 動詞 × 14 組合` 交互圖譜 | `cubical/autonomy/`、`cubical/structures/`、`topos/double_negation_alexandrov.mbt`、`accel/cubical_degeneracy_swar.mbt`、`bridge/malcev_presheaf_autonomy_bridge.mbt` |
| **縱向重構第一輪 `S1–S4`** | `F4 × F7 × F9 × accel/swar × K₉` | 修補 `meta` 巢狀集合剖析、升級 `Int64` Bareiss、雙向 E-graph QIIT、**Paterson–Wegman 線性 DAG MGU**、SLG 記憶化與 **`V₅ = 65,536` HF64 遺傳有限集宇宙**；提取零依賴 `L0 accel/swar`（64-trit `GF(3)`、MRV/MAC 精確 Gromov–Hausdorff、Half-GCD 有理重構）；拆出無線性代數 `topos/site` 與 `Sieve64` 雙 Heyting 核；打通 **`K₉ = 36/36` 九聯邦完全配對橋**與 `F7 → F9 → F4 → F1` 自動晉升鏈 | `accel/swar/`、`topos/site/`、`conjecture/kernel/`、`meta/{core,instances,iit,reflect}/`、`bridge/meta_k9_unification.mbt` |
| **縱向重構第二輪 `R1–R4`** | `F1 × F5 × F8` 底層下沉與三元合流 | M4RI `GF(2)` RREF、Ozaki-II DP4A CRT、Stockham NTT、Scanbox 與 HVM2 `INetArena` 下沉至 `L0 accel/swar`（對齊 `8/8` WGSL 著色器）；拆出 `L1 algebra/core`（`Rat` `Int64` 快徑、Ozaki-II `QMat`）；**Kalman 正負雙軌自由 De Morgan 區間 `I_DM` 與自由 CCHM 上纖維化格 `Cofib(n)`** 修補布林坍縮；HOU `O(Δ)` Trail-Stack 增量回溯；`scheme` 實作 **64-bit `Mono64` SWAR、Yan Geobuckets、Lazard–Macaulay M4RI 布林 F4、三素數 CRT 模 F4 與 Grassmann–Plücker 行列式**；建立 `F8 ↔ F5 ↔ F1` 三元橋 | `accel/swar/{m4ri_gf2,ozaki2_ntt_rns,hvm2_inet_arena}.mbt`、`algebra/core/`、`cubical/face_bdd/demorgan_cchm_swar.mbt`、`scheme/f4_macaulay_swar.mbt`、`bridge/accel_bridge.mbt` |
| **縱向重構第三輪 `T1–T4` ＋ 54 項高階立方結構全獨立實現 ＋ 全倉健檢清零** | `F2 × F3 × F6` 收官、`工作內容4` 無別名全實現與 `0` 死碼認證 | `gcd` 16-lane 延遲取模 `F_p`、HMM 範數導引 `ℤ`-SNF、Domich–Kannan–Trotter 模有界 `ℤ`-HNF；拆出第五 `L0` 基石 `symlib/core`（無度數上限 `PermLut`、**Holt 任意生成元秩子群共軛類格 `A₅:9, B₃:33`**、Burnside Möbius、群胚一般米田雙射）；`semiring` 串接 `@swar` Four-Russians/M4RI 矩陣乘、**3D 脊邊禮品包裝牛頓細分 `O(n log n + n·#Faces)`**、Karp 熱帶特徵對、Johnson 負權 APSP、Min-Fill 精確變數消去與 Valmari–Hopcroft `O(|Σ||Q|log|Q|)` 最小 DFA；拆出 `L1 condensed/core` 實作**構造性 Nöbeling 自由整數基底（`|det(B_ℤ)|=1`）**與 **64× `@swar` Steenrod–Adams 極小分解（直抵 `h₃=σ` 與 `Ext_A^{3,6}=1` `η³=4ν`）**；於 `cubical/structures` 完成 **CCHM `Glue`、Vogt 半伴隨 2-胞、Hofmann–Streicher `U8` 重對齊、Klein 瓶推出撓率、`Σ⊣Ω`、開放 2-立方 `T²≃S¹×S¹`、雙分類 CwF 代換、無歸約 NbE、連接對偶與 `I³→S¹` 3D 開放盒**獨立實現（`54/54` 零搭便車）；達成 **`5,794` 函式 `0` 死碼／`0` 無引用型別／`0` 空殼列舉／`0` 完全重複** | `symlib/core/`、`semiring/{matrix,trop,graph,bp,nf,app}/`、`condensed/core/`、`cubical/structures/{glue_hae_universe_classifier,cubical_hits_pushout_torus,cubical_nbe_subst_connections_kan}.mbt`、`meta/core/glue_vogt_realignment.mbt`、`tools/health_scan.py` |
| **第十聯邦 `ualg`**（2026-11-10～11，本地第五～七輪） | 構造性泛代數 × `¬¬` 雙重否定預層 × De Morgan／立方層化 | 有限表格代數上的項／恆等式／同餘生成與同餘格（泛代數：子代數／同餘格／商與同構定理／Mal'cev 項搜尋）、有限偏序上的 Alexandrov 拓撲／核子普查／Isbell 稠密性／`a ⊣ i` 計數驗證、自由 De Morgan 代數 DM(n)（反鏈正規形、Kalman 𝟜-語義、Dedekind 數）、面格 𝔽(n) 與量詞 ∃ ⊣ w ⊣ ∀、立方雙重否定核子 j = ¬¬（Glivenko：`Fix(¬¬) ≅ P(頂點)`；`j 不保併`；`∃i 4／∀i 44` 反例）、層化只經頂點決定 | `ualg/{core,site,demorgan,cube}/`、`cmd/ualg/`（全命題重算執行檔；本地落倉未登記 Lean） |

---

## 二、十二大能力邊界：瓶頸 → 演算法突破 → 可複驗見證

每一條「這裡原本做不到或會退化」都被追到具體的代數／組合／記憶體瓶頸，再以可複驗定理與多項式時間／硬體字組並行演算法打穿：

| # | 領域 | 原本的瓶頸 | 突破與演算法 | 可複驗見證 |
|---:|---|---|---|---|
| 1 | **Schema 與大宇宙** | 宇宙層級僅有限整數；容器不能帶路徑索引 | 直至 `ε₀` 的 Cantor 範式超限序數；索引容器降階為正性函子；Tarski–Mahlo 反射與一等 `DLevelDecl` 驗證 | `verify_mahlo_universe_reflection`、`check_level_polymorphic_declarations` |
| 2 | **DSystem 與自由 De Morgan 區間** | 高維布林枚舉 `2ⁿ`；樸素布林指派誤將 `i ∧ ¬i` 塌縮為 `0`、將 `(i=0)∨(i=1)` 塌縮為 `⊤` | ROBDD 餘因子不交莖黏合（2 個規範莖覆蓋 `2²⁰` 點）；**Kalman 雙軌自由 De Morgan `I_DM` 與自由 CCHM `Cofib(n)`** 保持 `loop(i ∧ ¬i) ≠ base` 及 `∂I ≠ ⊤_F` | `conv_sheaf_glued_boolean_partition`、`dim_eq_demorgan`、`cchm_face_entails` |
| 3 | **持久層與拜占庭共識** | 單機 `fsync` 撕裂模型無跨節點共識；模組儲存耦合高層凝聚套件 | `3f+1` BFT 狀態機 + RFC 8032 Ed25519 法定人數封緘 + `CHWALJRN` 崩潰恢復；摘要鏈下沉 `L0 gcd` 使 `cubical/store` 降至 `pkgL3` | `bft_ed25519_quorum_commit_to_wal`、`ugcd_digest_chain_verify` |
| 4 | **精確代數與無分數消元** | 高斯消元遇有理數分子分母指數爆炸；`Rat` 小整數頻繁配置 `BigInt` | `Rat` `Int64` 無溢位快徑；**Sylvester–Bareiss `O(n³)` 行列式**；**無除法 Berkowitz + 多素數 CRT** 特徵多項式；**Ozaki-II INT8 DP4A CRT** `QMat` 乘法；Liouville／Schanuel 超越分離 | `qmat_det`、`qmat_charpoly_berkowitz_crt`、`qmat_mul_ozaki2_crt`、`liouville_transcendence_certificate` |
| 5 | **BDD／SAT 與泛點具體化** | 自然宿主立方需 `2ⁿ` 次探針 | **泛點 Yoneda `O(1)` 具體化**（`n=24` 僅 1 次求值，省 `16,777,216` 次探針）；Cuthill–McKee 前沿割寬（26 變量鏈 51 節點、`#SAT = 66,791,053`）＋ `n ≤ 6` 單 `UInt64` SWAR 面快徑 | `reify_natural_dcube_symbolic_o1`、`bdd_dag_of_face_frontier_treewidth` |
| 6 | **球面同倫與凝聚 Steenrod–Adams** | 單例傳輸硬上限 5 階；稠密 `F₂` 矩陣使 Adams 分解卡在低次數 | 任意 `n` 階單例收縮與六維 `K₆`（42 頂點、9 小面）；`condensed/core` 以**內部次數 `t` 齊次分塊 + `@swar.gf2_rref_eliminate_u64` 64× 加速**直抵 `trunc_deg=12`，機器證明 `h₀, h₁=η, h₂=ν, h₃=σ` 與 **`Ext_A^{3,6}=1`（`η³ = 4ν`）** | `dpath_associahedron_k6_coherence_value`、`adams_ext_swar_frontier_report` |
| 7 | **HOU 高階合一與模組熱替換** | Huet 分支回溯每次複製整張代換表 `O(\|subst\|)`；熱替換禁互遞迴 | **`O(Δ)` Trail-Stack 增量回溯**；內層 `ULam` 高階匹配；Tarjan SCC + 無鎖 MVCC 原子熱替換；核心內 Goldfarb 丟番圖不可判定性見證 | `hou_unify`、`hou_match_higher_order_lambda`、`hot_load_mvcc_commit_atomic` |
| 8 | **代數幾何 Gröbner 基與行列式** | Buchberger 氣泡排序與線性減法 `O(\|p\|³)`；Fitting 行列式 `O(k!)` Laplace 展開 | **64-bit `Mono64` 無分支 3 指令單項式整除**、Yan 對數地理桶、Gebauer–Möller 判準、**M4RI `GF(2)` 布林 F4**、**三素數 CRT + Wang 有理重構模 F4**，以及 **Grassmann–Plücker `O(k·2^k)`／Berkowitz `O(k⁴)` 行列式** | `f4_boolean_groebner_gf2`、`f4_groebner_rat_modular`、`verify_f8_f5_f1_triad_bridge` |
| 9 | **有限對稱與 Burnside 子群格** | `perm_key64` 在 `n > 12` 溢位；雙生成元掃描漏掉秩 `≥ 3` 子群（如 `(C₂)³ ≤ B₃`） | **無度數上限 `PermLut`**（`n ≤ 15` 4-bit Nibble SWAR、`n > 15` SplitMix64 + 原像核對）；**Holt 陪集剪枝逐層擴張子群格**（`A₅(60)` 精確得 `9` 類、`B₃(48)` 精確得 `33` 類）＋ Burnside Möbius 上三角回代 | `subgroup_classes`、`burnside_mobius_solve`、`verify_general_yoneda_bijection` |
| 10 | **熱帶幾何、負權最短路與最小 DFA** | 牛頓多胞形下凸包 `O(n⁴)` 四重迴圈；APSP 不支援負權；Moore `O(\|Q\|²)` 最小化 | **3D 脊邊禮品包裝 BFS `O(n log n + n·#Faces)`**；Karp 最小環平均熱帶特徵對；Bellman–Ford + **Johnson 稀疏負權 APSP**；有環因子圖 **Min-Fill 精確半環變數消去**；**Valmari–Hopcroft `O(\|Σ\|\|Q\|log\|Q\|)` 最小 DFA** | `BPoly::subdivision`、`trop_eigenvalue_karp`、`apsp_johnson`、`dfa_minimize` |
| 11 | **凝聚固態對偶與整數格正規形** | 射影塔自由性僅有秩對帳無基底矩陣；`ℤ`-HNF 尾端主元相消退化 | Havas–Majewski–Matthews 範數導引 `ℤ`-SNF 與 Domich–Kannan–Trotter 模有界 `ℤ`-HNF；**構造性 Nöbeling 分層纖維單模基底 `B_ℤ`（`|det(B_ℤ)| = 1`）** 證明 `C(S,ℤ) ≅ ⨁ ℤ` 與 `ℤ[S]^■ ≅ ∏ ℤ` | `nobeling_unimodular_basis_zmat`、`verify_nobeling_free_solid_duality` |
| 12 | **元理論合一、解析與有限集合宇宙** | 樹狀 Robinson 合一遇深度 `d` 項指數爆炸 `2^d`；`V_n` 受字串枚舉限制 | **Paterson–Wegman 線性時間 DAG MGU**（深度 16 指數項零展開合一）；SLG 表格化記憶解析；雙向 E-graph QIIT；**Ackermann 64-bit 位元雙射實算全體 `V₅ = 65,536` 個遺傳有限集** | `unify_dag_linear`、`resolve_indexed_tabled`、`hf64_v5_rank_census` |

---

## 三、十大聯邦 ＋ 大一統頂點全景（`57` 套件 · `66` 元件 · `321` 檔 · `202,287` 行）

| 聯邦 | 規模（`arch_check.py` 實測） | 所屬套件（`pkgL0 .. pkgL9`） | 核心數學結構與代表演算法 |
|---|---|---|---|
| **F1 `cubical`** | `14` 套件<br>`126` 檔 / `116,167` 行 | `cubical-face-bdd`(`L0`), `algebra-core`(`L1`), `cubical-finite`(`L1`), `hostfs`(`L1`), `algebra`(`L2`), `cubical-kernel`(`L2`), `cubical-elaborator`(`L3`), `cubical-hermitian`(`L3`), `cubical-homotopy`(`L3`), `cubical-store`(`L3`), `cubical-autonomy`(`L5`), `cubical-structures`(`L6`), `root`(`L7`), `cmd-main`(`L8`) | Kalman 自由 De Morgan `I_DM` 與 CCHM `Cofib(n)`、ROBDD／CDCL-LRAT；可信依賴立方核心（NbE、Kan、Glue、Open-IR、`ε₀`/Mahlo）；`O(Δ)` Trail-Stack HOU 與 `O(d)` 記憶化雙向依值／歸納（鑽石 DAG `170×`）；`π₁(S¹)`/`π₂(S²)`/Brunerie `π₄(S³)`/`K₆`；瑪爾切夫泛代數自主層、**54 項高階立方結構獨立實現**與多模態 2-範疇／雙上下文 SWAR QTT；`algebra/core` Ozaki-II／Bareiss；Ed25519 BFT／MVCC 模組庫（`cmd/main` **`139/139`**） |
| **F2 `symlib`** | `4` 套件<br>`30` 檔 / `9,830` 行 | `symlib-core`(`L0`), `symlib`(`L1`), `cmd-symdemo`(`L2`), `cmd-symbench`(`L2`) | **`L0 symlib/core`**：硬體 `popcnt`/`and_popcount` `BitVec`、無度數上限 `PermLut`、零配置 Schreier–Sims（含 `A_n`, `B_n`）、位向量 1-WL 與 McKay 同構引擎；**`L1 symlib`**：Holt 陪集剪枝任意秩子群格（`A₅:9, B₃:33`）、Burnside Möbius 分解、`G-Set` 單子、Warshall `cat_thin`、Kan 擴張與非薄／群胚一般米田雙射 |
| **F3 `semiring`** | `16` 套件<br>`45` 檔 / `13,885` 行 | `semiring-{algebra,nf,par,ratelimit,sim}`(`L1`), `semiring-{bp,io,matrix,monoid,trop}`(`L2`), `semiring-{cat,graph,spline}`(`L3`), `semiring-{app,par-host}`(`L4`), `cmd-semiringreport`(`L5`) | `@swar` Four-Russians 64-bit 布林矩陣乘 `mul_bool_swar`、M4RI `mul_gf2_m4ri_swar`、64-bit 布林／分塊熱帶閉包；`LinUsage` 與泛型雙上下文半模 `DualResourceCtx[R]`；3D 脊邊禮品包裝牛頓正則細分；Karp 熱帶特徵值與臨界特徵向量；Bellman–Ford＋Johnson 負權 APSP；Min-Fill 精確變數消去；Valmari–Hopcroft `O(\|Σ\|\|Q\|log\|Q\|)` 最小 DFA 與 19 節實測報告 |
| **F4 `topos`** | `2` 套件<br>`10` 檔 / `8,607` 行 | `topos-site`(`L2`), `topos`(`L3`) | **`L2 topos/site`**：零線性代數耦合景、`Sieve64` 64-bit 雙 Heyting 核、MAC 相容族枚舉、本徵幾何態射 `Lan ⊣ u* ⊣ Ran`、Diaconescu `G`-主叢與一階幾何理論 Kripke–Joyal 力迫 `model_satisfies_theory`；**`L3 topos`**：**Artin 膠合逗號範疇 `Gl(Γ)`**、SGA4 開閉重黏合、雙重否定 `Sh_{¬¬}` 布林層化、亞歷山德羅夫／Chu 對偶、`RP²` 模撓率上同調與杯積 |
| **F5 `scheme`** | `1` 套件<br>`6` 檔 / `6,150` 行 | `scheme`(`L3`) | 64-bit `Mono64` SWAR 單項式整除／`GRevLex`、Yan 地理桶、Gebauer–Möller、M4RI 布林 F4、三素數 CRT 模 F4、Grassmann–Plücker／Berkowitz 行列式、黏合概形、仿射纖維積、`Ω¹_{B/A}`、Fitting 平滑性、吹脹解消、Serre 對偶與 Chow 動機 `h(ℙ¹) = 1 ⊕ 𝕃` |
| **F6 `condensed`** | `3` 套件<br>`8` 檔 / `5,059` 行 | `gcd`(`L0`), `condensed-core`(`L1`), `condensed`(`L4`) | **下頂點 `V₁` (`gcd`)**：16-lane 延遲取模 `F_p`、HMM `ℤ`-SNF、Bareiss 行列式、DKT 模有界 `ℤ`-HNF、CRT、`ugcd_rat_recon_bigint` 與摘要鏈；**`L1 condensed/core`**：`CompactProfiniteTower`、構造性 Nöbeling 自由基底、Roos–Milnor `R¹lim`、`CondAnima`、`CondSolidModule` 與 **64× `@swar` Steenrod–Adams 極小分解**；**`L4 condensed`**：`CondAnalyticStack`、共軛四元數消元中軸與凝聚四猜想 |
| **F7 `discovery`** | `3` 套件<br>`5` 檔 / `3,587` 行 | `tensor`(`L2`), `discovery-kernel`(`L3`), `conjecture`(`L5`) | `tensor`：64-trit `GF(3)` 全體 `6,561` 張量秩圖譜 `[1, 128, 4032, 2400]`、64-bit MRV/MAC Gromov–Hausdorff 距離、支配坍縮 VR 同調、Radon 反演、Clifford 旋量；`conjecture/kernel`：Half-GCD 有理重構與 64-bit `ctz` 位平面蘊含格；`conjecture`：6 演化轉移律與 12 項 Lakatos 猜想 |
| **F8 `accel`** | `2` 套件<br>`11` 檔 / `3,887` 行 | `accel-swar`(`L0`), `accel`(`L4`) + `webgpu/index.html` | **`L0 accel/swar`**：64-bit 硬體原語全集（M4RI RREF、64-trit `GF(3)`、Ozaki-II DP4A CRT、Stockham NTT、立方蝴蝶、Scanbox、HVM2 `INetArena`、Stafford Mix13 Merkle 時代快取 `SwarMemoTable64`、16×4-bit 飽和半模 `swar_grade16_*`）；**`L4 accel`**：跨聯邦加速見證與 **8/8 靜態可移植性審計通過之瀏覽器零依賴 WebGPU WGSL 著色器** |
| **F9 `meta`** | `5` 套件<br>`34` 檔 / `17,246` 行 | `meta-core`(`L0`), `meta-instances`(`L1`), `meta-iit`(`L1`), `meta-reflect`(`L2`), `cmd-metatheory`(`L3`) | **零外部業務依賴之元理論地板與三軸引擎（`631/631` 定律、`104` 個 `law_*`）**：反射（NbE + 逐步憑證 + `V₅ = 65,536` HF64 + Mahlo）、全域實例（SLG 記憶解析 + 臨界對 + 擬陣判準）、歸納—歸納（Kleene 切片塔 + 雙向 E-graph QIIT + **4-分類內蘊 CwF QIIT 展示消除器** + STLC β），以及嚴格模式 2-範疇 MTT、Paley `R(4,4)=18` / `R(3,5)=14`、Burnside Möbius、Karp 對偶、Nöbeling 單模反演、Vogt 伴隨化與 HS 重對齊定律 |
| **F10 `ualg`** | `5` 套件<br>`23` 檔 / `7,813` 行 | `ualg-core`(`L0`), `ualg-site`(`L0`), `ualg-demorgan`(`L1`), `ualg-cube`(`L2`), `cmd-ualg`(`L3`) | **構造性泛代數**：項／恆等式／同餘生成／商與同構定理／Mal'cev 項搜尋；**有限偏序預層**：Alexandrov 拓撲、核子普查、Isbell 稠密性、`a ⊣ i` 自然變換計數驗證；**自由 De Morgan 代數** `DM(n)`（反鏈正規形、Kalman 𝟜-語義、Dedekind 數）、面格 `𝔽(n)` 與 `∃ ⊣ w ⊣ ∀`；**立方雙重否定核子** `j = ¬¬`：Glivenko `Fix(¬¬) ≅ P(頂點)`、`j 不保併`（V、V² 共 484 反例）、`∃i 4／∀i 44` 反例；**層化只經頂點決定** `a(aF⊠aG) = a(F⊠G)`；`cmd/ualg` 全命題重算執行檔 |
| **頂點 `unification`** | `2` 套件<br>`20` 檔 / `6,984` 行 | `bridge`(`L8`), `cmd-showcase`(`L9`) | **九聯邦完全圖 `K₉ = 36/36` 全配對跨聯邦雙邊橋**、`F7 → F9 → F4 → F1` 四聯邦定理自動晉升管線、**`F8 ↔ F5 ↔ F1` 三元橋**、**`F2 ↔ F3 ↔ F6` 三元橋**、**`F1 × F3 × F4 × F8 × F9` 七大前沿支柱五元合流**、`ATLAS-01..18` 幾何—邏輯圖譜、旋轉差分與 **`48/48` 大一統證書** |

---

## 四、里程碑數字一覽

| 項目 | 實測數字 | 驗證入口／出處 |
|---|---|---|
| **主定理總表** | **139 / 139**（`158` 條規格、`1,649` 個唯一公開符號，`O(N)` 雜湊核驗 `0` 幽靈條目） | `cmd/main`（`verify.mbt` + `spec.mbt`；遠端實測，合併截面未重跑） |
| **第九聯邦元理論定律** | **631 / 631**（`104` 個 `law_*` 函式，逐條重算） | `cmd/metatheory`（本地 2026-11-12 實測） |
| **大一統證書與全配對橋** | **48 / 48 證書** · **`K₉ = 36 / 36` 九聯邦完全雙邊橋** · **4 條跨聯邦三元／四元／五元合流管線** | `cmd/showcase`（`bridge/`） |
| **高階立方結構與範疇組合** | **54 / 54 獨立結構證書** × **26 個運算動詞** × **14 種範疇組合模式**（14 條交互定理，零別名搭便車） | `cubical/structures` |
| **第十聯邦 ualg 定律** | `cmd/ualg` 逐條重算 `ualg/{core,site,demorgan,cube}` 全部命題（本地落倉；未登記 Lean、未入 barrel；獨立 `lake env lean` 綠檔 `ImportGraph.lean` 為 O5 邏輯內核之 Lean 對照） | `moon run cmd/ualg`；[`ualg/`](ualg/) |
| **全倉靜態健檢（`health_scan.py` v3）** | **`5,810` 函式／方法：遞移死碼 `0`、無引用型別 `0`、空殼 `enum` `0`、完全與 α 等價重複 `0`**（遠端 2026-11-10 實測；合併截面未重跑） | [`tools/health_report.md`](tools/health_report.md) |
| **多目標零警告編譯閘** | **`wasm-gc` · `wasm` · `js` · `native` 四大目標皆 `0 warnings, 0 errors`**（遠端 2026-11-10 實測） | `moon check --deny-warn` |
| **同倫與凝聚 Steenrod–Adams** | `π₁(S¹)≃ℤ`、`π₂(S²)≃ℤ`、`π₄(S³)≅ℤ/2ℤ`；Adams 極小分解至 `t=12` 證出 `h₀,h₁,h₂,h₃` 與 **`Ext_A^{3,6}=1`（`η³=4ν`）** | `cubical/homotopy`、`condensed/core` |
| **有限對稱與 Burnside 環** | Holt 任意生成元秩子群共軛類格：`S₄(24):11`、**`A₅(60):9`**、**`B₃(48):33`**（含 3-生成元初等阿貝爾子群 `(C₂)³`） | `symlib/marks.mbt` |
| **立方退化分解與遺傳有限集宇宙** | 全體 `65,536` 個 4-立方體 Eilenberg–Zilber 唯一分層 `[2, 8, 60, 872, 64594]`；Ackermann 位元雙射實算 `V₅ = 65,536`（`rank 4` 佔 `65,520`） | `cubical/structures`、`meta/reflect` |
| **張量秩與精確度量幾何** | `𝔽₃` 全體 `6,561` 張量秩分佈 `[1, 128, 4032, 2400]`；MRV/MAC 分支定界實算 `2·d_GH(C₅,C₆)=1`、`2·d_GH(C₆,K₅)=2` | `tensor/`、`accel/swar/` |
| **幾何—邏輯圖譜與猜想實驗室** | `ATLAS-01..18`（正負雙見證） · `CONJ-01..12`（6 演化族） · 5 條直覺猜想與反例修正 | `bridge/`、`conjecture/`、[`bridge/INTUITIVE_CONJECTURES.md`](bridge/INTUITIVE_CONJECTURES.md) |
| **Ramsey 精確夾逼** | **`R(4,4) = 18`**、**`R(3,5) = 14`**（Paley 自補圖 `P₁₇` 下界 ＋ 遞迴上界夾死，免除 `2¹⁵³` 窮舉） | `meta/core/ramsey_ex.mbt` |
| **WebGPU 瀏覽器硬體著色器** | **`8 / 8` 註冊 WGSL 計算著色器**（`7 / 7` 前沿套件）通過無 `f64`/無遞迴靜態可移植性審計 | `accel/webgpu_wgsl_kernels.mbt`、`webgpu/index.html` |
| **歸納-歸納的相位差** | `Fin` 的擴張永遠落後 `Nat` 一階（第 1 階段 `Fin = ∅`、第 2 階段才出現） | `meta/iit/schema.mbt` |
| **Lean 4 獨立數學筆記對照** | Lean 4.35.0 中已證 **466** 條定理並登記（2026-11-11；含 O1 第一半邊 `nf_beta_normal`，冪等半邊未完成）：實測 573 條宣告中 **144 條全稱／歸納**（真正算不出來的那批；含 `Instances/ImportGraph.lean` 7 條未入桶未登記）、382 條具體計算、47 其他。與 `kt` 為人讀族對照（`Bool` 檢查與 `Prop` 命題之間無形式橋），六條證明義務見 [`lean/WHY.md`](lean/WHY.md) §3 | [`lean/README.md`](lean/README.md) |

---

## 五、架構：`L0` 基石層 ＋ 六組輕重分離 ＋ 雙 V / X 樞紐 / `K₉` 完全星稜柱（第十聯邦 ualg 平行落倉，未接入 K 橋）

```text
         [ 上頂點 V₂ · L8–L9 unification：bridge + cmd/showcase ]
     48/48 證書 · K₉ = 36/36 全配對橋 · F7→F9→F4→F1 · F8×F5×F1 · F2×F3×F6
                  ▲                        ▲                        ▲
     (幾何—拓撲—同倫左翼)            (X 交疊凝聚樞紐)         (代數—對稱—半環—元理論右翼)
   F1 cubical · F4 topos          F6 condensed (L1/L4)       F2 symlib · F3 semiring
   F5 scheme  · F7 discovery      Nöbeling · Solid · Adams   F8 accel  · F9 meta (零業務依賴)
                  ▲                        ▲                        ▲
         ════ 六組 `pub using` 無損輕重分離（100% 向後相容 API）════
   algebra/core ⊂ algebra · symlib/core ⊂ symlib · condensed/core ⊂ condensed
   topos/site ⊂ topos     · conjecture/kernel ⊂ conjecture · accel/swar ⊂ accel
                  ▲                        ▲                        ▲
         [ 五大零外部依賴 L0 基石：gcd · accel/swar · cubical/face_bdd · symlib/core · meta/core ]
```

* **單向無環保證**：`architecture.json` 精確定義 **`52` 個套件（`pkgL0 .. pkgL9`）** 與 **`61` 個架構元件（`compL0 .. compL14`）**，由 `tools/arch_check.py` 同時強制檢驗 `moon.pkg` 實體匯入圖、跨聯邦白名單與源碼層級符號引用圖（`exceptions: []`）。
* **第九聯邦 `meta/` 的獨立性**：`meta/*` 對主倉其餘八個聯邦保持**零業務匯入**，所有跨聯邦機制（瑪爾切夫同餘、De Morgan `M₄`、`Mono64` SWAR、Burnside Möbius、Karp 熱帶對偶、Nöbeling 單模反演、覆蓋聚焦等）皆以獨立數學命題在 `meta/` 內逐點重算，再於 `bridge/meta_k9_unification.mbt` 與八大聯邦雙邊對帳。

---

## 六、從哪裡讀起（全倉 57 套件 README 全覆蓋導覽）

| 你想探索的主題 | 推薦閱讀路徑 |
|---|---|
| **全景與架構治理** | 本檔 → [`readme.v2.md`](readme.v2.md) → [`agent.md`](agent.md)（全倉 57 套件索引與交接規範）→ [`agent.v2.md`](agent.v2.md)（架構憲章與歷輪重構報告） |
| **依賴立方核心與高階結構** | [`cubical/finite/`](cubical/finite/README.md) → [`cubical/face_bdd/`](cubical/face_bdd/README.md) → [`cubical/kernel/`](cubical/kernel/README.md) → [`cubical/homotopy/`](cubical/homotopy/README.md) → [`cubical/autonomy/`](cubical/autonomy/README.md) → [`cubical/structures/`](cubical/structures/README.md) |
| **合一、模組庫與崩潰一致** | [`cubical/elaborator/`](cubical/elaborator/README.md) → [`cubical/store/`](cubical/store/README.md) → [`hostfs/`](hostfs/README.md) |
| **精確代數與泛消元 GCD** | [`gcd/`](gcd/README.md) → [`algebra/core/`](algebra/core/README.md) → [`algebra/`](algebra/README.md) → [`cubical/hermitian/`](cubical/hermitian/README.md) |
| **有限對稱、範疇與半環演算法** | [`symlib/core/`](symlib/core/README.md) → [`symlib/`](symlib/README.md) → [`semiring/`](semiring/README.md)（含 15 個子套件）→ [`cmd/semiringreport/`](cmd/semiringreport/README.md) |
| **拓撲斯、概形與凝聚數學** | [`topos/site/`](topos/site/README.md) → [`topos/`](topos/README.md) → [`scheme/`](scheme/README.md) → [`condensed/core/`](condensed/core/README.md) → [`condensed/`](condensed/README.md) |
| **第十聯邦 構造性泛代數 × `¬¬` 層化** | [`ualg/core/`](ualg/core/README.md) → [`ualg/site/`](ualg/site/README.md) → [`ualg/demorgan/`](ualg/demorgan/README.md) → [`ualg/cube/`](ualg/cube/README.md) → [`cmd/ualg/`](cmd/ualg/README.md) |
| **64-bit SWAR 與 WebGPU 加速** | [`accel/swar/`](accel/swar/README.md) → [`accel/`](accel/README.md) → [`webgpu/`](webgpu/README.md) |
| **張量幾何、猜想發現與大一統橋** | [`tensor/`](tensor/README.md) → [`conjecture/kernel/`](conjecture/kernel/README.md) → [`conjecture/`](conjecture/README.md) → [`bridge/`](bridge/README.md) → [`cmd/showcase/`](cmd/showcase/README.md) |
| **第九聯邦元理論與形式化對照** | [`meta/README.md`](meta/README.md) → [`cmd/metatheory/`](cmd/metatheory/README.md) → [`meta/CAPABILITIES.md`](meta/CAPABILITIES.md) → [`lean/README.md`](lean/README.md) → [`lean/WHY.md`](lean/WHY.md) |
| **程式碼健檢與規格總帳** | `spec.mbt`（`spec_registry`） · `verify.mbt` · [`tools/README.md`](tools/README.md) · [`tools/health_report.md`](tools/health_report.md) |

**全倉 57 個套件資料夾**（含 `ualg/` 5 個、`cmd/ualg/` 1 個）皆配備獨立 `README.md`，
索引與表格在 [`agent.md`](agent.md) Part II。

---

## 七、工程紀律（摘要）

1. **零常駐單元測試、零煙霧測試**：開發時在受改 `.mbt` 檔案**最底部**寫臨時 `test { ... }`（搭配 `debug_inspect`）→ `moon test <單一套件> --target wasm-gc` 即驗 → **立即刪除臨時 `test` 塊**；具長期價值的驗證一律升格為正式純函式 `check_*` / `verify_*` / `law_*`（由 `arch_check.py` 強制檢查零殘留測試檔與零殘留 `test` 塊）。
2. **雙路徑獨立互證**：同一個數學量用兩條互不相關的演算法各算一次，結果逐位相等才算通過（如 Bareiss vs SNF、多素數模 F4 vs 有理 Buchberger、HVM2 交互網 vs 依賴型 NbE、幾何 `|β|=2` vs 代數 `Ext^{2,3}=0`）。
3. **強制負對照**：每個檢查器皆配備反例攻擊（Girard 宇宙悖論環、仿射對角變數複用、角點不相容邊界、`S₃` 非正規子群覆蓋、篡改證明憑證、破壞分配律半環皆必須被精確拒絕）。
4. **治理與流水紀錄**：架構治理與階段驗收報告統一歸檔於 [`agent.v2.md`](agent.v2.md)，開發進度與待辦流水帳維護於 [`Dev.txt`](Dev.txt)。

細節見 [`agent.md`](agent.md) Part I。

---

## 授權與狀態

授權見 [`LICENSE`](LICENSE)。本倉庫為研究級數學與系統工程：`139/139` 主定理、`631/631` 元理論定律、`167/167` 第十聯邦命題、`48/48` 歷史證書與 `K₁₀ = 45/45` 跨聯邦全橋為本地 2026-11-12 實測並已接入 CI；每一項演算法的前提與退化邊界皆量化記錄於 `cmd/semiringreport` §19 與各套件 `README.md` 中。
