# kt (`cubical-hermitian` v2)

基於 MoonBit 建構的**九聯邦雙V形（`V₁ = @gcd → X = @condensed → V₂ = @bridge`）、X形交疊、星稜柱大一統與 CPU／瀏覽器免費 WebGPU（WGSL）硬體加速**數學計算與形式結構平台。

> **v2 治理與文檔說明**：v1 時期全套舊文檔與雙語附錄已完整封存於 Git 標籤 `v1-final`。自 v2 起，全倉僅保留本檔 `readme.v2.md`（系統全景與架構導覽）與 [`agent.v2.md`](agent.v2.md)（工程規範、`build/check + inspect` 局部即時測試制度、分波重構與硬體加速準則），並以 `architecture.json` 與各套件 `pkg.generated.mbti` 為唯一結構與介面真實來源。

---

## 一、九聯邦雙V形、星稜柱與硬體加速架構全景

```text
                    V₂ 上頂點：@bridge ── 星稜柱與硬體加速大一統（Layers 7–8）
          K₇ 完全圖 21/21 跨聯邦雙邊橋 · X形四葉對偶 · CPU+WebGPU 加速橋 · 47 項大一統證書
          ╱        ╱         ╱         ╱          ╲          ╲         ╲        ╲
   F1 cubical  F2 symlib  F3 semiring  F4 topos  F5 scheme  F6 condensed  F7 discovery  F8 accel
   (依賴立方)   (置換群)   (熱帶/星閉)  (層/神經)  (Gröbner)   (X 交疊樞紐) (張量/猜想)  (CPU SWAR/WebGPU)
          ╲        ╲         ╲         ╲          ╱          ╱         ╱        ╱
                    V₁ 下頂點：@gcd ── 五域泛消元新最大公因數（Layer 0）
                (ℤ 擴展歐幾里得 · F_p RREF · ℤ-格 HNF/SNF · 子空間雙零化子 · 自由群約化)
```

| 聯邦／層級 | 核心套件路徑 | 數學與演算法職責 |
|---|---|---|
| **基底 `V₁`** | `gcd/` | 整數／多項式／有限體 RREF／`ℤ`-矩陣 Hermite 與 Smith 正規形（SNF）／CRT 多模重構／雙零化子 Grassmann 交和對偶／自由群 $F_2$ 字約化 |
| **F1 `cubical`** | `cubical/{face_bdd,finite,hermitian,kernel,elaborator,homotopy,store}`、`algebra/`、`hostfs/`、`.`（薄門面＋定理總表）、`cmd/main` | 依賴立方可信核心（NbE、`coe`/`comp`/`hcomp`、Glue、歸納—遞迴與高階歸納型 HIT）、計算性單值性與合成同倫（$S^n$、$K_n$、Blakers–Massey、Brunerie $\pi_4(S^3)\cong\mathbb{Z}/2\mathbb{Z}$）、雙向精緻化與 Huet/Goldfarb 高階合一、ROBDD／CDCL-LRAT、精確代數與超越數認證、Ed25519 BFT 與 MVCC 熱載入持久層 |
| **F2 `symlib`** | `symlib/`、`cmd/symdemo`、`cmd/symbench` | 有限置換群 Schreier–Sims、著色圖規範形與自同構群、Burnside 軌道計數、`G-Set` 單子、有限範疇與左／右 Kan 擴張 |
| **F3 `semiring`** | `semiring/*`（16 套件）、`cmd/semiringreport` | 冪等／星閉／熱帶半環、稠密與 CSR 稀疏矩陣 Kleene 閉包、加權有向圖、熱帶多項式與指派、Brzozowski 正規形與因子圖 |
| **F4 `topos`** | `topos/` | Grothendieck 景與篩、兩步層化、子物件分類子 $\Omega_J$ 與開閉子拓撲斯核、Kripke–Joyal 語義、分類 Topos、非阿貝爾 $G$-主叢 Čech 上同調、單純神經同倫與上積 DG-代數 |
| **F5 `scheme`** | `scheme/` | 多變量 Buchberger 約化 Gröbner 基、Zariski 黏合概形、Kähler 微分與 Eisenbud Fitting 平滑判準、Tjurina 奇點數、吹脹奇點解消、DVR 賦值真概形、Hilbert 多項式、Grothendieck–Serre 對偶與 Chow 動機 |
| **F6 `condensed`** | `condensed/`（含 `gcd/`） | 凝聚範疇 `CondCategory` 與規範消元範疇 `CanonElimCategory`、四大凝聚高階結構（`CondAnima`、`CondSolidModule`、`CondSpectralSheaf`、`CondAnalyticStack`）、Steenrod–Adams $2\eta=0$、雜湊鏈守恆律賬本 `CondInvariantLedger` |
| **F7 `discovery`** | `tensor/`、`conjecture/` | $\mathbb{F}_3^{2\times 2\times 2}$ 全體 `6,561` 張量伽羅瓦軌道分類 `[1, 128, 4032, 2400]` 與 Cayley 超行列式、離散 Radon 精確反演、Clifford 旋量與 $T^2$ 規範場、非交叉弦森林層景與 Vietoris–Rips 同調對偶、6 組跨尺度演化轉移定律、5 大認識論透鏡與 Lakatos 十二猜想圖譜（`CONJ-01..12`） |
| **F8 `accel`** | `accel/`、`webgpu/index.html` | **CPU 64 位 SWAR 與瀏覽器免費 WebGPU（WGSL）六大前沿加速引擎**：(1) M4RI $\mathbb{F}_2$ 格雷碼矩陣乘與 64 位 RREF；(2) 雙軌 64-trit $\mathbb{F}_3$ 無分支位切片（`103` 個雙軌字掃描全體 `6,561` 張量超行列式 `2241+3456+864`）與 64 路 `Face` 超立方體 `#SAT`；(3) Ozaki Scheme II `INT8→INT32`（`dot4I8Packed`）中國剩餘定理精確／`FP64` 矩陣乘模擬；(4) 32 位 RNS Stockham 免位反轉自動排序 NTT 與 30 位 Montgomery 規約；(5) Scanbox 解耦回看單遍前綴掃描（支援 `subgroups`）、Morton Z-序與 `16×17` 無衝突共享記憶體三相熱帶閉包；(6) HVM2 扁平競技場並行交互組合子強合流求值器與 7 個通過 W3C 基線靜態審計之 WGSL 計算著色器 |
| **F9 `meta`** | `meta/{core,instances,iit,reflect}`、`cmd/metatheory` | **型別論機制的三根軸（橫向加入，不接雙 V 的任一端），現況 `485/485` 定律、63 個 `law_*` 函式**：(1) **反射**——NbE 的 `reify ⊣ reflect`、**一般 β（在 6 個型別上窮舉 316 個大小 ≤ 10 的項逐一檢查 β-正規/冪等/一步 β/η 收縮/保型）**、快判定 `decide_eq` 與慢而可信的逐步憑證 `check_cert` 兩路互證、**集合論反射換成真實表述**（規範編碼的遺傳有限集合 HF、`V_0=∅`／`V_{n+1}=P(V_n)` 物化到 `V_4`、真滿足關係 `sat`、絕對性 `absolute_at`、反射層級**無界且對更大層級封閉**、`φ∧ψ` 的反射層級＝交集 ⇒ 有限公式集同時反射）＋**club 組合學**（`α ↦ ω^{1+α}`、`α ↦ ω^{ω+α}` 為 normal function、連續性 `f(sup)=sup f=ω^ω`、12.3 對角迭代、以及「無界但不封閉不是 club」的反例）、實例憑證的無搜尋檢查；(2) **全域實例**——Horn/SLD 解析與見證項、**SLD 完備性以無剪枝暴力搜尋對照（`21672` 組目標/深度全一致）**、序數度量 `ω^{深度}` 判終止、臨界對一致性、**Knuth–Bendix 式修補＋終止序定向（新規則須 head > body，定向不了就報告）**、**模組匯入圖 Tarjan SCC：有環拒絕並給真迴路見證、DAG 給典範解析序**、覆蓋黏合的 $H^1$ 障礙（Möbius 障礙三元組）、`mirror_env` 對合與對偶互證、Ramsey 深度窗口；(3) **歸納-歸納**——切片範疇初始代數的 Kleene 鏈（`Fin` 落後 `Nat` 一階）、索引表達式逐參數檢查、互遞迴消除器與 $\omega^{size}$ 終止憑證、**QIIT 等式建構子進 schema（`ISchema.eqs`＋`ieq_ok` 檢查 head/sort/樣式變數/非空洞）、商對整條 Kleene 鏈良定義（商相等 ⇒ `iit_fold_q` 相等，25 對全過）**；數學地板為超限序數、一階合一／反合一、擬陣、有限複形與 Ramsey |
| **頂點 `V₂`** | `bridge/`、`cmd/showcase` | 七聯邦 $K_7$ 完全圖全部 $\binom{7}{2}=21$ 條雙邊橋、`@accel` 硬體加速逐位等價證書、X形交疊四葉對偶定理 `[T-X-Chiasmus]`、幾何—邏輯 18 項精細圖譜（`ATLAS-01..18`）與 `47/47` 大一統證書 |

---

## 二、日常快速指令（v2 極速驗證流）

```bash
# 1. 全倉靜態型別、零警告檢查與 Wasm-GC 編譯建置（常態主閘，< 3 秒）
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc

# 2. 架構層級、跨聯邦匯入白名單與 v2 零殘留測試檢查
python3 tools/arch_check.py

# 3. 介面更新與格式化
moon info --target wasm-gc && moon fmt

# 4. 重大里程碑可選執行檔展示與瀏覽器 WebGPU 頁
moon run --release cmd/showcase --target wasm-gc   # 九聯邦 47/47 大一統＋硬體加速證書展示
moon run --release cmd/metatheory --target wasm-gc # 第九聯邦 485/485 型別論機制定律（逐條重算）
moon run --release cmd/main --target wasm-gc       # Cubical 129/129 定理總表
# 瀏覽器免費 GPU 直接開啟：webgpu/index.html（自動偵測 navigator.gpu 並回退對照 CPU SWAR）
```

### 2.1 定律登記與標籤對帳（新增於 2026-11-07）

```bash
python3 tools/gen_laws.py    # 掃描所有 pub fn law_*，重生四個套件的 laws.mbt（跨行簽名容忍）
python3 tools/gen_labels.py  # 讀 cmd/metatheory 的**實際輸出**重生 lean/labels/moonbit-labels.md
```

* `gen_laws.py` 之前只認單行簽名，`moonfmt` 折行過的 `law_*` 會被漏掉（曾把 437 條漏成 128 條），現已修正。
* `gen_labels.py` 從執行輸出取標籤，因此「定律漏登記」在標籤清單裡一定看得出來（現況 485 條、388 條互異、119 族）。
* 第九聯邦的能力三段式對帳（能不能用／能不能自己檢查／邊界在哪）與淌欠結案表見 [`meta/CAPABILITIES.md`](meta/CAPABILITIES.md)。

### 2.2 工具鏈可重建性（沙盒實測）

`~/.moon` 不會跨沙盒快照保留；新環境需 `bash install/unix.sh` 重裝後執行一次 `moon update` 讓 registry 索引與 `moonbitlang/async` 依賴可解析，之後 `moon build --target wasm-gc` 即回到 0 error。

局部開發時的 **1 秒內（實測 `0.22s–0.95s`）`debug_inspect` 隨寫隨測隨刪工作流**、**`cubical` 七子套件無環分層規範** 與 **`accel` 硬體加速可移植設計準則（全倉 44 套件、53 元件）** 請參閱 [`agent.v2.md`](agent.v2.md)。
