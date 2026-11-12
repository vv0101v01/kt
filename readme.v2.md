# kt (`cubical-hermitian` v2)

基於 MoonBit 建構的**十聯邦（全十聯邦入雙 V／K₁₀ 星稜柱，第十聯邦 `ualg` 已構造性接入）五基石 `L0` 地基、雙V形（`V₁ = @gcd + @swar → X = @condensed → V₂ = @bridge`）、X形交疊、`K₁₀ = 45/45` 全配對構造性星稜柱大一統與 CPU SWAR／瀏覽器免費 WebGPU（WGSL）硬體加速**數學計算與形式結構平台。

> **v2 治理與文檔說明**：v1 時期全套舊文檔與雙語附錄已完整封存於 Git 標籤 `v1-final`。自 v2 起，全倉以本檔 `readme.v2.md`（三輪全聯邦重構 `S1–S4`＋`R1–R4`＋`T1–T4`＋第十聯邦 `ualg` 構造性接入 K₁₀ 後之大局觀、系統全景與全倉 `57` 套件／`66` 元件配置導覽）、[`agent.v2.md`](agent.v2.md)（工程治理、零常駐測試制度、架構分層矩陣與重構工作報告）及 [`Dev.txt`](Dev.txt)（演進總帳）為核心綱領，並以 `architecture.json` 與各套件 `pkg.generated.mbti` 為唯一結構與介面真實來源。

---

## 一、三輪全聯邦重構（`S1–S4` ＋ `R1–R4` ＋ `T1–T4`）＋ 第十聯邦 `ualg` 構造性接入 `K₁₀` 後的大局觀與宏觀架構

經過第一輪 **F4 (`topos`) × F7 (`discovery`) × F9 (`meta`) × `K₉`**（`S1–S4`）、第二輪 **F1 (`cubical`) × F5 (`scheme`) × F8 (`accel`)**（`R1–R4`）與第三輪 **F2 (`symlib`) × F3 (`semiring`) × F6 (`gcd` + `condensed`)**（`T1–T4`）三輪縱向重構後，**全部九大聯邦（9/9）**皆完成硬體 SWAR 對齊、`pub using` 輕重解耦與多項式時間演算法升級，全倉形成 **「五基石零依賴 `L0` 地基 → 六組 `pub using` 無損輕重分離核心層（`L1–L3`） → 中央凝聚／自主／猜想交匯層（`L4–L7`） → `K₁₀ = 45/45` 構造性星稜柱與多聯邦三元合流頂點（`L8–L9`）」** 的嚴格單向無環圖（DAG）：

1. **五基石零依賴 `L0` 地基（反轉依賴倒置）**：
   - `gcd`（五域泛消元基底：16-lane 延遲取模 `fp_mat_mul`／單次取模 `fp_rref`、Havas–Majewski–Matthews 範數導引 `zmat_snf`、Bareiss 無分數行列式 `zmat_det_bareiss`、Domich–Kannan–Trotter 模行列式有界 `zmat_hnf_modular`、CRT、`ugcd_rat_recon_bigint` 與 FNV-1a 摘要鏈賬本）；
   - `accel/swar`（M4RI `GF(2)` GEMM + 64-bit RREF、雙軌 `GF(3)` 64-trit 超行列式、Ozaki-II `INT8 DP4A` CRT GEMM、32-bit RNS Stockham NTT、立方蝴蝶退化配對、Scanbox/Morton 前綴掃描與 HVM2 `INetArena`）；
   - `symlib/core`（硬體 `popcnt`／`and_popcount` `BitVec`、無度數上限 4-bit Nibble SWAR + SplitMix64 `PermLut`、零配置 Schreier 軌道檢查之 Schreier–Sims `PermGroup`、位向量 WL 等變顏色精煉與 McKay 個體化-精煉圖同構引擎）；
   - `cubical/face_bdd`（Kalman 雙軌自由 De Morgan `I_DM`、自由 CCHM 上纖維化格 `Cofib(n)`、64-bit SWAR 真值快徑與 ROBDD／CDCL-LRAT）；
   - `meta/core`（超限序數 `< ε₀`、`Int64` Bareiss、Paterson–Wegman 線性 DAG MGU 與 `L0` 有限模型窮舉元理論定律）；
   - **（第十聯邦 `L0`，已接入雙 V／K₁₀）** `ualg/core`（有限表格代數：項／恆等式／同餘生成／子代數與自由代數閉包／同餘格／商與同構定理／Mal'cev 項搜尋／零元與理想／極性與 NextClosure）、`ualg/site`（有限偏序上的 Alexandrov 拓撲、核子普查與 Isbell 稠密性、j = ¬¬、預層／匹配族／j-層／plus 構造、a ⊣ i 伴隨的自然變換計數驗證）。
2. **六組 `pub using` 100% 向後相容的「輕核 vs 重擴張」雙層解耦**：
   透過 `symlib/core` (`L0`) ⊂ `symlib` (`L1`)、`algebra/core` (`L1`) ⊂ `algebra` (`L2`)、`condensed/core` (`L1`) ⊂ `condensed` (`L4`)、`topos/site` (`L2`) ⊂ `topos` (`L3`)、`conjecture/kernel` (`L3`) ⊂ `conjecture` (`L5`)、`accel/swar` (`L0`) ⊂ `accel` (`L4`) 六組配對拆分，徹底切斷跨聯邦重依賴的傳遞膨脹。
3. **九聯邦全覆蓋之多項式時間（`P`）與硬體 SWAR 演算法升級**：
   - **`F2 symlib`**：以 Holt 陪集剪枝逐層擴張演算法（`subgroup_classes`）完整支援任意生成元秩有限群（如 `A₅(60)` 9 類、含 3-生成 `(C₂)³` 之超八面體群 `B₃(48)` 33 類），實作 Burnside 環上三角標記矩陣 Möbius 精確回代求解器 `burnside_mobius_solve`，並建立非薄範疇／單對象群胚 `BG` 上之一般米田雙射 `verify_general_yoneda_bijection`；
   - **`F3 semiring`**：串接 `L0 @swar` 實作 Four-Russians `k=8` 64-bit 布林矩陣乘 `mul_bool_swar`、`GF(2)` M4RI `mul_gf2_m4ri_swar`、字組並聯布林閉包 `closure_bool_swar` 與分塊熱帶閉包 `closure_trop_swar`；以 3D 脊邊禮品包裝 BFS 將牛頓多邊形正則細分自 `O(n⁴)` 降至 `O(n log n + n·#Faces)`；實作 Karp 最小環平均熱帶特徵值 `trop_eigenvalue_karp`＋臨界特徵向量、Johnson 負權稀疏全源最短路 `apsp_johnson`、有環因子圖 Min-Fill 精確半環變數消去 `bp_exact_all_marginals_ve`、64-bit 結構雜湊導數自動機與 Hopcroft–Valmari `O(|Σ||Q|log|Q|)` 最小 DFA，並建立免 `par_host` 之全目標 `wasm-gc` 驗證套件 `verify_semiring_wasm_suite`；
   - **`F6 gcd + condensed`**：實作緊緻函數型射影塔 `CompactProfiniteTower`、構造性 Nöbeling 分層纖維單模整數基底 `nobeling_unimodular_basis_zmat`（機器證明 `|det(B_ℤ)| = 1`、`C(S,ℤ)` 自由無撓與 `ℤ[S]^■ ≅ ∏ ℤ`）、Roos–Milnor `rlim_zmat_endomorphism`，並以齊次分塊 `@swar.gf2_rref_eliminate_u64` + 64-bit `ctz` 稀疏分解將 Steenrod–Adams 極小自由分解推進至 `A_{≤12}`，機器證明四個經典 Hopf 不變量一元素 `h₀, h₁=η, h₂=ν, h₃=σ`（直抵八元數 Hopf 纖維化）與穩定 3-幹著名恆等式 **`h₁³ = h₀²h₂`（`η³ = 4ν ∈ π₃ˢ ≅ ℤ/24`）**；
   - 結合先前 `F1`（Kalman De Morgan／CCHM／Trail-Stack HOU）、`F4`（`Sieve64` 雙 Heyting 核）、`F5`（`Mono64` SWAR、M4RI 布林 F4、CRT 模 F4、Grassmann–Plücker／Berkowitz 行列式）、`F7`（64-trit `GF(3)` 張量圖譜、64-bit GH 距離、Half-GCD 與位平面 `ctz`）與 `F9`（Bareiss、Paterson–Wegman MGU、SLG、`V₅ = 65,536` HF64），全倉九聯邦實現零短板對齊。
4. **全配對 `K₁₀ = 45/45` ＋ 四聯邦自動晉升 ＋ 雙三元合流橋 ＋ 6 條弱橋數學構造替換**：
   頂點 `@bridge` 同時驗證 `K₁₀ = 45/45`（含第十聯邦 `ualg` 的 9 條構造性邊 `K10-37..45`，以及 `K8-22/24/27`、`K9-29/31/34` 六條名義弱橋的真實數學構造替換）、`48/48` 歷史證書＋K₁₀ 獨立證書、`F7 → F9 → F4 → F1` 自動晉升管線、**`F8 ↔ F5 ↔ F1` 硬體—符號—型別三元橋**，以及新增之 **`F2 ↔ F3 ↔ F6` 對稱—半環—凝聚三元合流橋**（`verify_f2_f3_f6_triad_bridge`）。

```text
                 V₂ 大一統頂點：@bridge + cmd/showcase（Package Layers 8–9 / Component Layers 13–14）
     K₁₀ 45/45 · F7→F9→F4→F1 晉升 · F8↔F5↔F1 三元橋 · F2↔F3↔F6 三元橋 · 18 圖譜 · 48/48 歷史證書 + K₁₀ 證書
     （第十聯邦 ualg 已入此圖：9 條構造性邊 K10-37..45 + 6 條弱橋替換）
       ╱       ╱        ╱        ╱         │         ╲         ╲         ╲        ╲
  F1 cubical F2 symlib F3 semiring F4 topos F5 scheme F6 condensed F7 discovery F8 accel F9 meta F10 ualg
  (14 pkgs)  (4 pkgs)  (16 pkgs)   (2 pkgs) (1 pkg)   (3 pkgs)     (3 pkgs)    (2 pkgs) (5 pkgs)
       ╲       ╲        ╲        ╲         │         ╱         ╱         ╱        ╱
         L1–L3 輕量化共享核心：algebra/core · condensed/core · topos/site · conjecture/kernel
       ╲                 ╲                 │                 ╱                 ╱
     V₁ 五基石零依賴地基（Package Layer 0）：gcd · accel/swar · symlib/core · cubical/face_bdd · meta/core
```

---

## 二、十聯邦（九聯邦入雙 V／K₉）＋大一統頂點職責總覽（全倉 `57` 套件、`66` 元件、`318` 個 `.mbt`、`199,215` 行；靜態健檢合併截面未重跑）

| 聯邦 | 套件數／規模 | 套件清單（含分層角色） | 核心數學結構與演算法職責 |
|---|---|---|---|
| **F1 `cubical`** | `14` 套件<br>`126` 檔 / `116,167` 行 | `cubical-face-bdd` (`L0`)、`algebra-core` (`L1`)、`cubical-finite` (`L1`)、`hostfs` (`L1`)、`algebra` (`L2`)、`cubical-kernel` (`L2`)、`cubical-elaborator` (`L3`)、`cubical-hermitian` (`L3`)、`cubical-homotopy` (`L3`)、`cubical-store` (`L3`)、`cubical-autonomy` (`L5`)、`cubical-structures` (`L6`)、`root` (`L7`)、`cmd-main` (`L8`) | Kalman 雙軌自由 De Morgan `I_DM` 與自由 CCHM `Cofib(n)`、64-bit SWAR 面真值快徑、ROBDD／CDCL-LRAT；可信依賴立方核心（NbE、Kan、Glue、HIT/Open-IR、`ε₀`/Mahlo）；`O(Δ)` Trail-Stack 高階合一；球面同倫、$K_n$、Blakers–Massey、Brunerie $\pi_4(S^3)\cong\mathbb{Z}/2\mathbb{Z}$；構造性泛代數自主類型論與 **54 項高階立方結構 × 26 動詞 × 14 組合**；`algebra/core` Ozaki-II CRT／Bareiss `QMat`；`L3` Ed25519 BFT／MVCC 模組庫（`cmd/main` **`137/137`**） |
| **F2 `symlib`** | `4` 套件<br>`30` 檔 / `9,830` 行 | `symlib-core` (`L0`)、`symlib` (`L1`)、`cmd-symdemo` (`L2`)、`cmd-symbench` (`L2`) | **`L0 symlib/core`**：硬體 `popcnt`/`and_popcount` `BitVec`、無度數上限 4-bit Nibble SWAR + SplitMix64 `PermLut`、零配置 Schreier 篩選 Schreier–Sims（含 `A_n`、`B_n`）、位向量 WL 顏色精煉與 McKay 圖同構引擎；**`L1 symlib`**：Holt 陪集剪枝任意生成元秩子群共軛類格（`A₅(60):9`、`B₃(48):33`）、Burnside Möbius 軌道分解 `burnside_mobius_solve`、`G-Set` 單子、有限範疇（含 Warshall 傳遞閉包 `cat_thin`）、Kan 擴張與非薄／群胚一般米田雙射 |
| **F3 `semiring`** | `16` 套件<br>`45` 檔 / `13,885` 行 | `semiring-{algebra,nf,par,ratelimit,sim}` (`L1`)、`semiring-{bp,io,matrix,monoid,trop}` (`L2`)、`semiring-{cat,graph,spline}` (`L3`)、`semiring-{app,par-host}` (`L4`)、`cmd-semiringreport` (`L5`) | Four-Russians 64-bit 布林矩陣乘 `mul_bool_swar`、`@swar` M4RI `mul_gf2_m4ri_swar`、64-bit 布林閉包與分塊熱帶閉包；3D 脊邊禮品包裝 BFS 牛頓正則細分 `O(n log n + n·#Faces)`；Karp 最小環平均熱帶特徵值 `λ(A)` 與臨界特徵向量；Bellman–Ford 勢＋Johnson 負權稀疏 APSP `O(nm log n)`；有環因子圖 Min-Fill 精確半環變數消去 `bp_exact_all_marginals_ve`；64-bit 結構雜湊導數 DFA＋Hopcroft–Valmari `O(|Σ||Q|log|Q|)` 最小 DFA 與全目標 `wasm-gc` 驗證套件 |
| **F4 `topos`** | `2` 套件<br>`10` 檔 / `8,607` 行 | `topos-site` (`L2`)、`topos` (`L3`) | `L2 topos/site` 零線性代數耦合景、`Sieve64` 64-bit 雙 Heyting 核、MAC 相容族枚舉、本徵幾何態射 `Lan ⊣ u* ⊣ Ran`、Diaconescu $G$-主叢與一階幾何理論 Kripke–Joyal 力迫 `model_satisfies_theory`；`L3 topos` 層上同調、$\mathbb{R}P^2$ 模撓率上同調、Alexander–Whitney 杯積、亞歷山德羅夫對偶與 Chu 自對偶 |
| **F5 `scheme`** | `1` 套件<br>`6` 檔 / `6,150` 行 | `scheme` (`L3`) | 64-bit `Mono64` SWAR 單項式整除／`GRevLex`、Yan 地理桶、Gebauer–Möller 判準、Lazard–Macaulay M4RI `GF(2)` 布林 F4、三素數 CRT 模 F4、Grassmann–Plücker／Samuelson–Berkowitz 行列式、Zariski 層化、仿射纖維積、$\Omega^1_{B/A}$、Fitting 平滑性、吹脹解消、Hilbert 多項式、Serre 對偶與 Chow 動機 |
| **F6 `condensed`** | `3` 套件<br>`8` 檔 / `5,059` 行 | `gcd` (`L0`)、`condensed-core` (`L1`)、`condensed` (`L4`) | **下頂點 `V₁` (`gcd`)**：16-lane 延遲取模 `F_p` GEMM/RREF、Havas–Majewski–Matthews `ℤ`-SNF、Bareiss 行列式、Domich–Kannan–Trotter 模有界 `ℤ`-HNF、CRT、`ugcd_rat_recon_bigint` 與摘要鏈；**`L1 condensed/core`**：`CompactProfiniteTower`、構造性 Nöbeling 自由整數基底（`|det(B_ℤ)|=1`）、Roos–Milnor `R¹lim`、`CondAnima`、`CondSolidModule`、`CondSpectralSheaf` 與 **64× `@swar` Steenrod–Adams 極小分解（直抵 `h₃=σ` 與 `h₁³=h₀²h₂` / `η³=4ν`）**；**`L4 condensed`**：`CondAnalyticStack`、共軛四元數消元中軸與凝聚四猜想 |
| **F7 `discovery`** | `3` 套件<br>`5` 檔 / `3,587` 行 | `tensor` (`L2`)、`discovery-kernel` (`L3`)、`conjecture` (`L5`) | `tensor`：64-trit `GF(3)` 全體 `6,561` 張量秩圖譜 `[1, 128, 4032, 2400]`、64-bit MRV/MAC Gromov–Hausdorff 距離、VR 坍縮、Radon 反演、Clifford 旋量；`conjecture/kernel`：Half-GCD 有理重構與位平面 `ctz` 蘊含格；`conjecture`：6 演化轉移律與 12 項 Lakatos 猜想 |
| **F8 `accel`** | `2` 套件<br>`11` 檔 / `3,887` 行 | `accel-swar` (`L0`)、`accel` (`L4`) + `webgpu/index.html` | **`L0 accel/swar`**：64-bit 暫存器硬體原語全集（直接賦能 `algebra/core`、`semiring/matrix`、`condensed/core`、`topos/site`、`scheme`、`tensor`、`conjecture/kernel`）；**`L4 accel`**：跨聯邦加速見證與 **8/8 靜態可移植性審計通過之瀏覽器免費 WebGPU WGSL 著色器** |
| **F9 `meta`** | `5` 套件<br>`34` 檔 / `17,246` 行 | `meta-core` (`L0`)、`meta-instances` (`L1`)、`meta-iit` (`L1`)、`meta-reflect` (`L2`)、`cmd-metatheory` (`L3`) | **零外部業務依賴之元理論地板與三軸引擎（`565/565` 定律、`94` 個 `law_*`；遠端 2026-11-10 實測，合併截面未重跑）**：新增 Burnside 上三角標記 Möbius 81 組分解、Karp 最小環平均對偶、Myhill–Nerode `2^k` 極小性與 Nöbeling 纖維單模反演定律，聯同 Bareiss、Paterson–Wegman MGU、SLG、QIIT E-graph、NbE 一般 β 與 `V₅ = 65,536` HF64 模型論反射 |
| **F10 `ualg`**（已接入雙 V／K₁₀） | `5` 套件<br>`23` 檔 / `7,813` 行 | `ualg-core`(`L0`)、`ualg-site`(`L0`)、`ualg-demorgan`(`L1`)、`ualg-cube`(`L2`)、`cmd-ualg`(`L3`) | **構造性泛代數**（項／恆等式／同餘格／商與同構定理／Mal'cev 項搜尋／`θ∘ψ=ψ∘θ=θ∨ψ`）、**有限偏序預層模板**（Alexandrov 拓撲、核子普查、Isbell 稠密性、`a ⊣ i` 計數驗證）、**自由 De Morgan 代數 `DM(n)`**（反鏈正規形、Kalman 𝟜-語義、Dedekind 數）、面格 `𝔽(n)` 與 `∃ ⊣ w ⊣ ∀`、**立方雙重否定核子 `j=¬¬`**（Glivenko：`Fix(¬¬) ≅ P(頂點)`；`j` 不保併；`∃i 4／∀i 44` 反例）、**層化只經頂點決定**；`cmd/ualg` 全命題重算執行檔（已入 CI；跨聯邦橋接見 `bridge/ualg_federation_constructions.mbt`） |
| **頂點 `unification`** | `2` 套件<br>`22` 檔 / `8,515` 行 | `bridge` (`L8`)、`cmd-showcase` (`L9`) | **十聯邦完全圖 `K₁₀ = 45/45` 全配對構造性跨聯邦橋**（9 條 `ualg` 邊＋6 條弱橋替換）、`F7 → F9 → F4 → F1` 自動晉升管線、**`F8 ↔ F5 ↔ F1` 三元橋**、**`F2 ↔ F3 ↔ F6` 對稱—半環—凝聚三元合流橋**、五聯邦五角大一統定理、18 項幾何—邏輯圖譜、旋轉差分與 5 直覺猜想實驗室、以及 **`48/48` 大一統證書** |

---

## 三、全倉配置明細總表（Package Layers `L0–L9` & Component Layers `L0–L14`）

### 3.1 物理套件分層與依賴配置（`57` Packages；`ualg-*` 為第十聯邦，已構造性接入雙 V／K₁₀，以 `※` 標示）

| Package Layer | 套件數 | 套件 ID（路徑 → 直接依賴 `depends_on`） |
|---|---|---|
| **`pkgL0`**（五基石零依賴地基；另有第十聯邦平行 `※ualg-core`、`※ualg-site` → `[]`） | `7` | `gcd` (`gcd` → `[]`)、`accel-swar` (`accel/swar` → `[]`)、`symlib-core` (`symlib/core` → `[]`)、`cubical-face-bdd` (`cubical/face_bdd` → `[]`)、`meta-core` (`meta/core` → `[]`)、※`ualg-core` (`ualg/core` → `[]`)、※`ualg-site` (`ualg/site` → `[]`) |
| **`pkgL1`**（一階核心代數／凝聚同倫核心／對稱與半環基底） | `13` | `algebra-core` (`algebra/core` → `[gcd, accel-swar]`)、`condensed-core` (`condensed/core` → `[gcd, accel-swar]`)、`symlib` (`symlib` → `[symlib-core]`)、`cubical-finite` (`cubical/finite` → `[cubical-face-bdd]`)、`hostfs` (`hostfs` → `[]`)、`semiring-{algebra,nf,par,ratelimit,sim}` (`→ []`)、`meta-{instances,iit}` (`→ [meta-core]`)、※`ualg-demorgan` (`ualg/demorgan` → `[ualg-core, ualg-site]`) |
| **`pkgL2`**（可信立方核心／無代數景／張量／半環矩陣與熱帶） | `13` | `algebra` (`→ [gcd, algebra-core]`)、`cubical-kernel` (`→ [cubical-face-bdd, cubical-finite]`)、`topos-site` (`→ [symlib, accel-swar]`)、`tensor` (`→ [gcd, accel-swar]`)、`meta-reflect` (`→ [meta-core, meta-instances]`)、`semiring-{bp,io,monoid,trop}` (`→ [semiring-algebra]`)、`semiring-matrix` (`→ [semiring-algebra, semiring-par, accel-swar]`)、`cmd-{symdemo,symbench}` (`→ [symlib]`)、※`ualg-cube` (`ualg/cube` → `[ualg-core, ualg-site, ualg-demorgan]`) |
| **`pkgL3`**（核心領域引擎層） | `12` | `cubical-elaborator` (`→ [cubical-kernel]`)、`cubical-hermitian` (`→ [cubical-face-bdd, cubical-finite, algebra]`)、`cubical-homotopy` (`→ [gcd, algebra-core, cubical-face-bdd, cubical-finite, cubical-kernel]`)、`cubical-store` (`→ [gcd, cubical-face-bdd, cubical-kernel]`)、`topos` (`→ [gcd, algebra-core, symlib, topos-site]`)、`scheme` (`→ [gcd, accel-swar, algebra]`)、`discovery-kernel` (`→ [gcd, accel-swar, tensor]`)、`semiring-{cat,graph}` (`→ [semiring-algebra, semiring-matrix]`)、`semiring-spline` (`→ [semiring-monoid]`)、`cmd-metatheory` (`→ [meta-*]`)、※`cmd-ualg` (`→ [ualg-core, ualg-site, ualg-demorgan, ualg-cube]`) |
| **`pkgL4`**（X 形凝聚樞紐、半環可攜整合與硬體整合層） | `4` | `condensed` (`→ [condensed-core, gcd, algebra-core, symlib, semiring-trop, topos, scheme]`)、`semiring-app` (`→ [semiring-algebra, semiring-matrix, semiring-sim, semiring-trop, semiring-graph, semiring-bp, semiring-nf]`)、`accel` (`→ [accel-swar, gcd, cubical-face-bdd, algebra-core, semiring-trop, tensor]`)、`semiring-par-host` (`→ [semiring-par]`) |
| **`pkgL5`**（自主代數／猜想演化／半環報告） | `3` | `cubical-autonomy`、`conjecture`、`cmd-semiringreport` |
| **`pkgL6`**（全譜高階立方結構層） | `1` | `cubical-structures` |
| **`pkgL7`**（極薄根相容門面與定理總控） | `1` | `root` (`.` → `[gcd, algebra, hostfs, condensed, cubical-*]`) |
| **`pkgL8–L9`**（大一統觀察頂點與主執行檔） | `3` | `bridge` (`L8`, observer, 匯流九聯邦 26 套件)、`cmd-main` (`L8` → `[root]`)、`cmd-showcase` (`L9` → `[bridge, semiring-graph, symlib, root]`) |

---

## 四、標準驗證與執行指令（零 `--release`、零常駐測試）

```bash
# 1. 全倉零警告型別檢查與單向架構閘門（< 2s）
moon check --deny-warn --target wasm-gc
python3 tools/arch_check.py
python3 tools/health_scan.py

# 2. 四大可執行驗證入口（wasm-gc 順序執行）
moon run cmd/symdemo --target wasm-gc       # F2 有限對稱群、McKay 規範形與 Burnside 標記展示
moon run cmd/metatheory --target wasm-gc    # F9 元理論三軸引擎：565 / 565 定律（遠端 2026-11-10 實測；合併截面未重跑）
moon run cmd/ualg --target wasm-gc          # 第十聯邦：ualg 全命題重算（167/167，已入 CI）
moon run cmd/showcase --target wasm-gc      # V₂ 十聯邦大一統：48/48 歷史證書 + K₁₀=45/45 + ualg 9 構造邊 + 6 弱橋替換 + F8↔F5F1 + F2↔F3↔F6
moon run cmd/main --target wasm-gc          # F1+F6 定理總控登記表：passed 139/139（遠端實測，合併截面未重跑）
# 3. 介面更新與格式化
moon info --target wasm-gc && moon fmt

# 4. 重大里程碑可選執行檔展示與瀏覽器 WebGPU 頁
# 瀏覽器免費 GPU 直接開啟：webgpu/index.html（自動偵測 navigator.gpu 並回退對照 CPU SWAR）
```

### 2.1 定律登記與標籤對帳（新增於 2026-11-07）

```bash
python3 tools/gen_laws.py    # 掃描所有 pub fn law_*，重生四個套件的 laws.mbt（跨行簽名容忍）
python3 tools/gen_labels.py  # 讀 cmd/metatheory 的**實際輸出**重生 lean/labels/moonbit-labels.md
```

* `gen_laws.py` 之前只認單行簽名，`moonfmt` 折行過的 `law_*` 會被漏掉（曾把 437 條漏成 128 條），現已修正。
* `gen_labels.py` 從執行輸出取標籤，因此「定律漏登記」在標籤清單裡一定看得出來（現況 565 條；遠端 2026-11-10 實測，合併截面未重跑）。
* 第九聯邦的能力三段式對帳（能不能用／能不能自己檢查／邊界在哪）與淌欠結案表見 [`meta/CAPABILITIES.md`](meta/CAPABILITIES.md)。

### 2.2 工具鏈可重建性（沙盒實測）

`~/.moon` 不會跨沙盒快照保留；新環境需 `bash install/unix.sh` 重裝後執行一次 `moon update` 讓 registry 索引與 `moonbitlang/async` 依賴可解析，之後 `moon build --target wasm-gc` 即回到 0 error。

局部開發時的 **1 秒內（實測 `0.22s–0.95s`）`debug_inspect` 隨寫隨測隨刪工作流**、**`cubical` 七子套件無環分層規範** 與 **`accel` 硬體加速可移植設計準則（全倉 57 套件、66 元件）** 請參閱 [`agent.v2.md`](agent.v2.md)。
