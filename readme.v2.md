# kt (`cubical-hermitian` v2)

基於 MoonBit 建構的**七聯邦雙V形（`V₁ = @gcd → X = @condensed → V₂ = @bridge`）、X形交疊與星稜柱大一統**數學計算與形式結構平台。

> **v2 治理與文檔說明**：v1 時期全套舊文檔與雙語附錄已完整封存於 Git 標籤 `v1-final`。自 v2 起，全倉僅保留本檔 `readme.v2.md`（系統全景與架構導覽）與 [`agent.v2.md`](agent.v2.md)（工程規範、`build/check + inspect` 局部即時測試制度與分波重構藍圖），並以 `architecture.json` 與各套件 `pkg.generated.mbti` 為唯一結構與介面真實來源。

---

## 一、七聯邦雙V形與星稜柱架構全景

```text
                    V₂ 上頂點：@bridge ── 七聯邦星稜柱大一統（Layers 5–6）
              K₇ 完全圖 21/21 跨聯邦雙邊橋 · X形四葉對偶 · 46 項大一統證書
              ╱        ╱         ╱          │          ╲         ╲        ╲
       F1 cubical  F2 symlib  F3 semiring  F4 topos  F5 scheme  F6 condensed  F7 discovery
       (依賴立方)   (置換群)   (熱帶/星閉)  (層/神經)  (Gröbner)   (X 交疊樞紐) (張量/猜想引擎)
              ╲        ╲         ╲          │          ╱         ╱        ╱
                    V₁ 下頂點：@gcd ── 五域泛消元新最大公因數（Layer 0）
                (ℤ 擴展歐幾里得 · F_p RREF · ℤ-格 HNF/SNF · 子空間雙零化子 · 自由群約化)
```

| 聯邦／層級 | 核心套件路徑 | 數學與演算法職責 |
|---|---|---|
| **基底 `V₁`** | `gcd/` | 整數／多項式／有限體 RREF／`ℤ`-矩陣 Hermite 與 Smith 正規形（SNF）／CRT 多模重構／雙零化子 Grassmann 交和對偶／自由群 $F_2$ 字約化 |
| **F1 `cubical`** | `cubical/face_bdd`、`cubical/finite`、`cubical/hermitian`、`cubical/kernel`、`.`（演進至 `elaborator`/`store`/`homotopy`）、`algebra/`、`hostfs/`、`cmd/main` | 依賴立方型別核心（NbE、`coe`/`comp`/`hcomp`、Glue、歸納—遞迴與高階歸納型 HIT）、計算性單值性、合成同倫（$S^n$、$K_n$、Blakers–Massey、Brunerie $\pi_4(S^3)\cong\mathbb{Z}/2\mathbb{Z}$）、ROBDD／CDCL-LRAT、精確代數與超越數認證、Ed25519 BFT 持久層 |
| **F2 `symlib`** | `symlib/`、`cmd/symdemo`、`cmd/symbench` | 有限置換群 Schreier–Sims、著色圖規範形與自同構群、Burnside 軌道計數、`G-Set` 單子、有限範疇與左／右 Kan 擴張 |
| **F3 `semiring`** | `semiring/*`（16 套件）、`cmd/semiringreport` | 冪等／星閉／熱帶半環、稠密與 CSR 稀疏矩陣 Kleene 閉包、加權有向圖、熱帶多項式與指派、Brzozowski 正規形與因子圖 |
| **F4 `topos`** | `topos/` | Grothendieck 景與篩、兩步層化、子物件分類子 $\Omega_J$ 與開閉子拓撲斯核、Kripke–Joyal 語義、分類 Topos、非阿貝爾 $G$-主叢 Čech 上同調、單純神經同倫與上積 DG-代數 |
| **F5 `scheme`** | `scheme/` | 多變量 Buchberger 約化 Gröbner 基、Zariski 黏合概形、Kähler 微分與 Eisenbud Fitting 平滑判準、Tjurina 奇點數、吹脹奇點解消、DVR 賦值真概形、Hilbert 多項式、Grothendieck–Serre 對偶與 Chow 動機 |
| **F6 `condensed`** | `condensed/`（含 `gcd/`） | 凝聚範疇 `CondCategory` 與規範消元範疇 `CanonElimCategory`、四大凝聚高階結構（`CondAnima`、`CondSolidModule`、`CondSpectralSheaf`、`CondAnalyticStack`）、Steenrod–Adams $2\eta=0$、雜湊鏈守恆律賬本 `CondInvariantLedger` |
| **F7 `discovery`** | `tensor/`、`conjecture/` | $\mathbb{F}_3^{2\times 2\times 2}$ 全體 `6,561` 張量伽羅瓦軌道分類 `[1, 128, 4032, 2400]` 與 Cayley 超行列式、離散 Radon 精確反演、Clifford 旋量與 $T^2$ 規範場、非交叉弦森林層景與 Vietoris–Rips 同調對偶、6 組跨尺度演化轉移定律、5 大認識論透鏡與 Lakatos 十二猜想圖譜（`CONJ-01..12`） |
| **頂點 `V₂`** | `bridge/`、`cmd/showcase` | 七聯邦 $K_7$ 完全圖全部 $\binom{7}{2}=21$ 條雙邊橋、X形交疊四葉對偶定理 `[T-X-Chiasmus]`、幾何—邏輯 18 項精細圖譜（`ATLAS-01..18`）與星稜柱大一統證書 |

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

# 4. 重大里程碑可選執行檔展示
moon run --release cmd/showcase --target wasm-gc   # 七聯邦 K_7 星稜柱 46/46 大一統展示
moon run --release cmd/main --target wasm-gc       # Cubical 129/129 定理總表
```

局部開發時的 **1 秒級 `debug_inspect` 隨寫隨測隨刪工作流** 與 **`cubical` 根目錄四波段重構進度（Wave 1–3 ✅ 已完成，僅餘最終波 Wave 4）** 請參閱 [`agent.v2.md`](agent.v2.md)。
