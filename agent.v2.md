# agent.v2 — 工程治理、即時驗證制度與架構重構總綱

本文件為專案 **v2 唯一開發與架構治理規範**（v1 舊文檔已永久封存於 Git 標籤 `v1-final`，不再維護任何雙語附錄或手工符號鏡像表）。所有參與開發與重構的 Agent 必須遵守以下準則，以**穩健、零警告、零技術債堆積**為最高原則。

---

## 一、v2 測試與驗證新制：全面廢除常駐單元／煙霧測試，改採 `build/check + inspect + 局部即時測試即刪`

### 1.1 明確禁令（由 `tools/arch_check.py` 自動強制攔截）
- **全面取消常駐黑白箱單元測試與煙霧測試**：禁止在倉庫中保留或新增任何 `*_test.mbt`、`*_wbtest.mbt`、煙霧測試檔、`moon.pkg` 中的 `for "test"`／`for "wbtest"` 匯入區塊，或常駐的頂層 `test { ... }` 區塊。
- **原因**：常駐單元／煙霧測試隨系統演進不斷膨脹，令單體套件每次 `wasm-gc` 測試耗時逾百秒，且在重構內部模組邊界時製造大量同步噪音；真正具有長期價值的數學不變量應直接寫成正式模組的一等純函式，而非散落於測試檔。

### 1.2 v2 標準驗證閉環（1 秒級開發回饋）

開發、除錯與重構時，統一採用以下**三層即時驗證閉環**：

1. **第一層：編譯器靜態與建置總閘（每次修改必跑，耗時 `< 3 秒`）**
   ```bash
   moon check --deny-warn --target wasm-gc
   moon build --target wasm-gc
   python3 tools/arch_check.py
   ```
   - 必須維持 **0 warnings, 0 errors**：任何未使用變數、未覆蓋分支、廢棄語法或跨層違規匯入皆視為失敗。

2. **第二層：`inspect` / `debug_inspect` 局部即時微測試（「寫在檔底 → 1 秒即測即知 → 驗證後即刪」）**
   - 當實作新演算法、驗證反例或拆包搬移某個目標套件 `<pkg>/<file>.mbt` 時，**直接在該檔案最底部**附加臨時 `test` 區塊（注意：在 `moonc v0.10.18+` 下，陣列、元組、結構體與枚舉統一優先使用 **`debug_inspect`** 以保持零警告；純字串或純量可用 `inspect`）：
     ```moonbit
     ///|
     test {
       debug_inspect(radon_invert_fp(r3, rf_mod), content="[1, 2, 0, 3, 1, 4, 2, 0, 1]")
       debug_inspect(f3_atlas.rank_counts, content="[1, 128, 4032, 2400]")
     }
     ```
   - **僅針對該局部套件執行測試**（若想直接探測輸出值，可先寫 `content=""` 並加上 `--update` 讓 MoonBit 自動填入真實運算結果）：
     ```bash
     moon test <pkg> --update --target wasm-gc   # 1 秒內自動填入實際結果供審閱
     moon test <pkg> --target wasm-gc            # 確認斷言 100% 吻合
     ```
   - **即測即知即刪**：確認數值、邊界條件與負控制完全正確後，**立即將檔底的臨時 `test` 區塊刪除**（寫測試 $\to$ 執行 $\to$ 知結果 $\to$ 刪測試全程僅需約 1 秒），絕不把臨時測試留在倉庫中。

3. **第三層：介面快照審計與里程碑展示**
   - 每次提交前執行：
     ```bash
     moon info --target wasm-gc && moon fmt
     moon check --deny-warn --target wasm-gc
     python3 tools/arch_check.py
     ```
   - 透過 `git diff *.mbti` 審視公開介面變化是否符合預期；若重構無意改變外部 API，`.mbti` 應保持零非預期變動。
   - 跨聯邦重大變更完成後，按需執行（嚴格不加 `--release`）`moon run cmd/showcase --target wasm-gc`（`47/47` 大一統證書＋`K_9=36/36`＋`F8↔F5↔F1`＋`F2↔F3↔F6` 雙三元橋）、`moon run cmd/main --target wasm-gc`（`137/137` 定理總表）或 `moon run cmd/metatheory --target wasm-gc`（`545/545` 元理論定律逐條重算）做端到端驗收。

---

## 二、宏觀架構治理（三輪重構 `S1–S4` ＋ `R1–R4` ＋ `T1–T4` 後之九聯邦五基石 DAG）

全倉受 `architecture.json`、`tools/arch_check.py` 與 `tools/health_scan.py` 嚴格守門，遵循單向無環依賴（現況 **`9` 聯邦＋`unification` 大一統頂點、`52` 套件、`61` 元件、`282` 個 `.mbt`、`182,929` 行、`5,745` 個函式／方法 `0` 死碼／`0` 無引用型別／`0` 空殼列舉／`0` 完全相同重複**）：

- **Package Layer 0（五基石零依賴地基 `V₁`）**：
  1. `gcd`（五域泛消元基底：16-lane 延遲取模 `F_p` GEMM/RREF、Havas–Majewski–Matthews `ℤ`-SNF、Bareiss 無分數行列式 `zmat_det_bareiss`、Domich–Kannan–Trotter 模有界 `zmat_hnf_modular`、CRT、`ugcd_rat_recon_bigint`、FNV-1a 64-bit 摘要鏈與 `ℤ`-零空間賬本）；
  2. `accel/swar`（64-bit 暫存器硬體底層：M4RI `GF(2)` GEMM + RREF、雙軌 `GF(3)` 64-trit 超行列式、Ozaki-II `INT8 DP4A` CRT GEMM、32-bit RNS Stockham NTT + Montgomery REDC、64-way 立方退化配對、Scanbox/Morton 前綴掃描、HVM2 扁平競技場 `INetArena` + 閉合 Peano `λ` 求值器、雙 Heyting 篩與位平面 `ctz` 核心）；
  3. `symlib/core`（64-bit 硬體 `popcnt`/`and_popcount` `BitVec`、無度數上限 4-bit Nibble SWAR + SplitMix64 `PermLut`、零配置 Schreier 篩選 Schreier–Sims `PermGroup`、位向量 WL 等變精煉與 McKay 圖同構引擎）；
  4. `cubical/face_bdd`（Kalman 雙軌自由 De Morgan 區間 `I_DM`、自由 CCHM 上纖維化格 `Cofib(n)`、64-bit `UInt64` SWAR 6 變量真值快徑、ROBDD DAG、CDCL-LRAT、前沿割寬 `#SAT`）；
  5. `meta/core`（超限序數 `< ε₀`、`Int64` 無除法 Bareiss 秩與零空間憑證、Paterson–Wegman 線性 DAG MGU、擬陣、Ramsey、單純複形、瑪爾切夫泛代數與有限模型論定律）。
- **Package Layers 1–3（六組 `pub using` 輕重分離核心層與領域引擎層）**：
  - **六組無損相容拆分**：`symlib/core` (`L0`) ⊂ `symlib` (`L1`)、`algebra/core` (`L1`) ⊂ `algebra` (`L2`)、`condensed/core` (`L1`) ⊂ `condensed` (`L4`)、`topos/site` (`L2`) ⊂ `topos` (`L3`)、`conjecture/kernel` (`L3`) ⊂ `conjecture` (`L5`)、`accel/swar` (`L0`) ⊂ `accel` (`L4`)；任何外圍元件呼叫經 `pub using` 重導出之符號時，必須在 `architecture.json` `components[*].depends_on` 顯式宣告原定義元件以通過 `arch_check.py` 擁有權檢驗。
  - **正交領域套件**：`symlib` (`L1`)、`semiring/*` (`L1–L3`)、`hostfs` (`L1`)、`cubical/finite` (`L1`)、`cubical/kernel` (`L2`)、`cubical/{elaborator,hermitian,homotopy,store}` (`L3`，其中 `cubical/store` 已解除 `condensed` 依賴由 `L5` 下沉至 `L3`)、`scheme` (`L3`)、`meta/{instances,iit,reflect}` (`L1–L2`)。
- **Package Layers 4–7（中央 `X` 形交疊樞紐、高階自主立方與根門面）**：
  - `condensed` (`L4`)、`accel` (`L4`，含 `8/8` 靜態審計對齊 `webgpu/index.html` 之 WGSL 著色器)、`semiring/par_host` (`L4`)；
  - `cubical/autonomy` (`L5`)、`conjecture` (`L5`)、`cmd/semiringreport` (`L5`)、`cubical/structures` (`L6`，全體 54 項高階立方結構 × 26 動詞 × 14 組合)、`root` (`L7`)。
- **Package Layers 8–9 / Component Layers 13–14（上頂點 `V₂` 大一統觀察層）**：
  - `bridge` (`pkgL8` / `compL13`) 與 `cmd/showcase` (`pkgL9` / `compL14`)：九聯邦完全圖 **`K₉ = 36/36`**、`F7 → F9 → F4 → F1` 四聯邦定理自動晉升、`F8 ↔ F5 ↔ F1` 三元合流證書、18 項幾何—邏輯圖譜與 `47/47` 大一統證書。**任何下層聯邦絕對禁止反向匯入 `bridge`**。

---

## 三、`cubical` 七子套件無環分層架構（Wave 1–4 全面完成）

### 3.1 核心設計準則（SCC-Preserving Modularization）
1. **保護強連通互遞迴核心（不強拆 SCC）**：
   依頂層符號 Tarjan 強連通分量（SCC）實證，`dependent-kernel` 的互遞迴核心（`NbE 求值 ↔ Kan 填充 ↔ Glue 等價 ↔ 歸納/HIT Schema`）完整封裝於單一 `cubical/kernel` 套件內，避免跨包解環引入函數指標間接層或被迫改為 `pub(all)` 破壞核心封裝。
2. **編譯器級可信核心（Trusted Kernel）**：
   外圍六大子系統（`face_bdd`、`finite`、`hermitian`、`elaborator`、`store`、`homotopy`）與核心之間**零循環依賴**，使 `cubical/kernel` 內部的不變量載體（`CheckedLine`、`CheckedDCube`、`CheckedSystem`、`SchemaRegistry`、`DClosure`、`DTermInterner`）受編譯器強制鎖定為唯讀 `pub struct`，任何外圍套件均無法繞過檢驗器直接偽造。
3. **根除編年史命名債（Zero `phase*` Filenames）**：
   全倉禁止新增任何以期數命名的檔案（如 `phase*`），一律按數學結構或系統職責命名，單檔維持高內聚且聚焦。
4. **極薄精選門面（Curated Thin Root Facade）**：
   頂層 `facade.mbt` 僅以 `pub using` 重導出跨聯邦 `@bridge` 與執行檔實際使用的精選符號（根套件 `pkg.generated.mbti` 由重構前逾 `4,300` 行精簡約 `89%` 至 `484` 行），內部定律檢驗匯入一律保持 `using` 私有化。

### 3.2 `cubical` 子套件物理拓撲結構（全倉 38 套件）

```text
                root（極薄精選門面 facade.mbt + 定理／定律總控 verify.mbt）
          ┌──────────────┼───────────────────┐
          ▼              ▼                   ▼
  cubical/homotopy   cubical/store   cubical/elaborator   ◄── 三者彼此零依賴正交平行！
  (球面/單值性/Kn/   (二進位模組/WAL/  (雙向精緻化/Huet HOU/
   BM/Brunerie/HIT)   Ed25519 BFT/     高階匹配/Goldfarb)
          │           Tarjan 熱載入)          │
          └──────────────┴─────────┬─────────┘
                                   ▼
                            cubical/kernel  ◄── 可信核心（零浮點、零代數耦合、密封不變量）
                       (NbE + Kan + Glue + DSystem + 歸納/HIT/Open-IR + ε₀/Mahlo)
                                   │
                ┌──────────────────┼──────────────────┐
                ▼                  │                  ▼
         cubical/finite ◄──────────┴────────── cubical/hermitian
      (η-NbE / Wiring /                     (複矩陣 / 投影 P²=P=P† /
       有限宇宙 PathP·Glue)                  Karoubi·子空間 Glue / 代數證書影子)
                └──────────────────┬──────────────────┘
                                   ▼
                           cubical/face_bdd
                  (區間 Dim/Face · ROBDD DAG · Watched CDCL/LRAT · 割寬 #SAT)
```

### 3.3 四波段重構完成紀錄與 `< 1 秒` 單包微測試實測基準

- **Wave 1（✅ 已完成）**：全倉 `*phase*` 編年史檔名 100% 清零、大雜燴與巨檔（`schema_*`、`elaborator_*`、`bdd_cutwidth`、`ordinal_mahlo`、`higher_coherence_k6`、`hou_goldfarb`、`module_bft_mvcc`、`adjoint_equivalence`）精準拆解、純 `Dim`/`Face` 語義謂詞下沉與元件 DAG 單調正序。
- **Wave 2（✅ 已完成）**：自底向上實體抽離無環基礎三包 `cubical/face_bdd`（`0.38s`）、`cubical/finite`（`0.22s`）、`cubical/hermitian`（`0.57s`）。
- **Wave 3（✅ 已完成）**：實體抽離 `30.9k` 行可信依賴核心 `cubical/kernel`（零浮點與代數依賴，編譯器密封核心不變量，單包微測試實測 `0.95s`）。
- **Wave 4（✅ 已完成）**：平行抽離彼此零耦合之上層三大子套件 `cubical/elaborator`（`0.35s`）、`cubical/homotopy`（`0.38s`）、`cubical/store`（`0.58s`），並將頂層 `root` 收斂為精選門面＋定理總表（`root` 單包微測試由 `11.05s` 降至 **`0.63s`**，`pkg.generated.mbti` 精簡 `90%`，`cmd/showcase` `46/46` 大一統證書全數通過）。

---

## 四、MoonBit v2 編碼與安全規範

1. **區塊風格**：所有頂層宣告以 `///|` 分隔，方便按區塊獨立搬移與重構。
2. **可見性最小化**：
   - 核心不變量型別使用 `pub enum`／`pub struct`（對包外隱藏構造子與欄位，強制經由智慧構造子檢驗）；
   - 純資料傳輸報告（Report / Summary / Config）方使用 `pub(all) struct`／`pub(all) enum`。
3. **零警告 Trait 導出（`moonc v0.10.18+`）**：
   公開型別若 `derive(Debug, Eq)`，需顯式補齊：
   ```moonbit
   pub extend MyType with @moonbitlang/core/debug.Debug::{to_repr}
   pub extend MyType with Eq::{not_equal, equal}
   ```
   以確保 `moon info` 與 `moon check --deny-warn` 零警告。
4. **憑證安全**：GitHub PAT 等認證資訊僅能以單次指令記憶體參數（`git -c http.https://github.com/.extraheader=...`）傳遞，嚴禁寫入 `.git/config` 或任何工作區檔案。

---

## 五、CPU SWAR 與瀏覽器免費 WebGPU（`WGSL`）硬體加速規範（`accel/`）

1. **瀏覽器免費消費者級 GPU 嚴格基線（Zero-Extension Baseline）**：
   - 所有產出之 `WGSL` 計算著色器必須通過 `audit_wgsl_browser_portability` 靜態審計：**嚴禁依賴 `f64`、`u64`、`i64` 等非標準硬體擴充型別**；高精度或大整數運算一律透過 **Ozaki Scheme II 位元組模數 CRT（`dot4I8Packed` `INT8→INT32`）** 或 **WebGPU 安全質數（$p < 46340$）多模 RNS Stockham NTT** 精確重構。
   - 每個工作群組調用數上限維持 `workgroup_size <= 256`，`var<workgroup>` 共享記憶體維持 `<= 16,384` bytes，且二維共享區塊統一採用 `16 × 17`（`+1` 欄填充）消除 32-bank 記憶體衝突；`subgroups` 特性必須同時提供 `enable subgroups;` 特化版與純共享記憶體可移植回退版。
2. **以逐位數學等價證書取代環境敏感基準測試**：
   - 因沙盒或雲端容器環境欠缺穩定實體 GPU 時脈，不設常駐效能基準測試腳本；所有 CPU SWAR（`UInt64` 位切片、M4RI、扁平競技場）與 WebGPU 32 位核心一律以 `verify_accel_federation()` 與跨聯邦主定義（`@gcd`、`@face_bdd`、`@algebra`、`@semiring/trop`、`@tensor`）作 **100% 逐位數學等價檢驗**（單包 `accel` 即時微測試耗時約 `0.24s`）。

---

## 六、工作報告：2026-11-02 共軛四元數 × 消元範疇 × 四族旋轉凝聚中軸

### 6.1 What changed

* 新增 `condensed/quaternion_axis.mbt`（802 行）：Hamilton 積與共軛、單位四元數旋轉、Householder 倒影、`Q₈/±1` 規範消元範疇、順／逆序列、瑕積分、RK4 常微分方程、Richardson 極限與持久守恆賬本。
* 新增 `bridge/rotation_axis_bridge.mbt`（278 行）：直接呼叫 Jacobi、Jordan、Hopf、Tamari 上游公開實作，逐族登記實際成立的關係；不把四族旋轉誤稱為同構。
* `facade.mbt` 精選重導出 Hopf 與 Tamari 公開函式；`cmd/showcase/main.mbt` 新增中軸定量 PASS 行並納入總成功條件；`condensed/moon.pkg` 只新增 `moonbitlang/core/math`，沒有新增業務套件邊。
* 更新 3 份 `.mbti`、各層 README 與統計。套件／元件數不變（39／48），`.mbt` 由 218 增至 220。

### 6.2 Why / invariant

* 對偶是反自同構 `conj(pq)=conj(q)conj(p)`；單位範數才蘊含 `q⁻¹=conj(q)`，非單位例子必須拒絕反推。
* 共軛旋轉保持方向（det `+1`），倒影是獨合且反向（det `-1`）；順向乘積 `q₃q₂q₁` 的逆必須是反序列共軛乘積。
* `Q₈` 的 8 元素經正負號消元成 4 類，所有共軛 morphism 保持該等價關係；16 筆整數範數觀測應有 3 條獨立 `ℤ`-線性守恆律。
* 數值層必須公開尾部、步長與誤差：RK4 不正規化，讓範數漂移可被量到；舊賬本快照不可因追加而改變，篡改必須使驗鏈失敗。

### 6.3 How verified

* 官方安裝器 `https://cli.moonbitlang.com/install/unix.sh` 安裝最新 stable：`moon 0.1.20261029`、`moonc v0.10.19+97801ee1b (2026-10-30)`。語法按現行 `extend ... with Trait::{...}`、顯式寬度整數與 `pub(all)` 報告型別撰寫。
* Tier A／C：`moon info --target wasm-gc && moon fmt`、`moon check --deny-warn --target wasm-gc`、`moon build --target wasm-gc` 全部通過，0 warnings／0 errors。`.mbti` 是預期新增 API：`condensed +100`、`bridge +25`、root `+22` 行，無意外刪改。
* `python3 tools/arch_check.py`：`architecture ok: 8 federations + unification apex, 39 packages, 48 components, 220 .mbt files, 151961 .mbt lines`；federation `condensed = 6 files / 4445 lines`，apex `= 15 files / 4935 lines`。
* Tier B 局部即時測試（皆已刪除）：`condensed` 與 `bridge` 各 1/1；四族結果為 Jacobi／Jordan／Hopf／Tamari `true,true,true,true`，總橋 `4/4`。
* 瑕積分：`B=64, panels=4096`，`finite Simpson + atan(1/B) = 1.5707963267949048`，對 `π/2` 殘差 `8.215650382226158e-15`，尾部上界 `1/64`。
* ODE：步數 `4,8,16,32` 的誤差為 `[9.72437828532119e-6, 6.079483412572543e-7, 3.799949714550167e-8, 2.3750111597599967e-9]`；實測階數 `3.9999741296849374`，Richardson 極限誤差 `5.181372564008819e-11`；範數平方漂移由 `3.168168945855143e-6` 降至 `9.71454028331209e-11`。
* 獨立第二路徑：Python 複平面 `z'=iz` RK4 給出相同階數與 Richardson 值；獨立 Simpson 得相同積分；整數守恆三條獨立 nullspace 見證逐列點積為零。賬本 `20` 筆（16 觀測＋3 定律＋1 摘要），`3/3` 定律審核通過，舊快照持久且篡改負對照被抓住。
* 端到端：`cmd/showcase` 印出 `families=4/4 ... conservation_laws=3/3, ledger_entries=20`，原有 `47/47 certificates passed`、`all_ok=true`；`cmd/main` 為 `passed 129/129`。
* 如實記錄開發失敗：第一版以粗步最大漂移作 `1e-8` 閾值，得到 `conserved=false`；改成公開整條漂移序列並檢查細步漂移後才通過。另一次臨時測試在迴圈內更新同一 `debug_inspect`，觸發 256 update passes；改成單一 `statuses` 陣列後 1/1。兩個臨時測試塊均未留存。

### 6.4 Still open / boundaries

* 「永續守恆」只指**有限精確離散模型的守恆律＋不可變雜湊鏈證據**；浮點 ODE 只有指定步長與容差的收斂證據，不是無限時間、無誤差或實數域形式化定理。
* `S³`／profinite 的緊湊拓撲是模型背景；程式驗的是有限代表元、範數與固態間隙，不宣稱用數值計算證明緊緻性。
* 四族旋轉是關係對齊而非彼此同構；不適用於某族的關係不強行登記。
* `rotation_axis_certificate()` 獨立輸出，歷史 `47/47` 不改成 `48/48`；本次只建立工作樹變更，未提交或推送 Git。

---

## 七、工作報告：2026-11-02 局部相干角消元、四族數值差分與全倉健檢

### 7.1 What changed

* 新增 `cubical/homotopy/coherence_angle_elimination.mbt`（238 行）：逐項枚舉指定有限模型的 `24×23×20=11040` 個局部相干角索引；先把每個有序胞腔對的 20 個 Kan 填充代表商成 `552`，再將逆向有序對配對到 `276` 個規範類。報告同時呼叫現有 `check_kan_dep_all()` 與 `check_assoc_faces()`，不是只寫常數 PASS。
* 第一段消去 `10488` 個重複代表，第二段再消去 `276` 個逆向重複；最後 `remaining_after=0`，而 `276` 個規範類的重數總和仍為 `11040`。因此「未解局部角歸零」不等於把守恆基數刪成零，也不等於規範類數必須是零。
* 錯配一個索引會同時破壞類重數與逆向配對審計，負對照必須被抓住；正常與篡改分割都逐項重算，不用硬編布林值取代檢查。
* `bridge/rotation_axis_bridge.mbt` 擴為 465 行：四族與凝聚中軸都公開 `previous/current/deltas/max_abs_delta`，以固定消元前基準及 `1e-12` 回歸容差比較；形狀不符、NaN 或 Inf 均不得通過。Jordan 另加入精確 `norm² 25→25` 守恆檢查。
* 健檢修正：`rotation_array_close` 不再讓 NaN 因浮點比較皆 false 而誤過；Tamari 見證輸出實際 `connected`，並移除重複連通計算。另清除不存在的規格附錄與外部審計腳本斷鏈，改為如實描述現有 `spec_registry_sound()` 的非空與唯一性檢查。
* `facade.mbt` 精選導出相干角報告，`cmd/showcase` 印出消元與逐項數值差分；新檔登記入 `architecture.json` 的 `associahedron` 元件。舊 `47/47` 與 `129/129` 里程碑不變。

### 7.2 消元前後數值

* Jacobi `[粗區間總寬, 細區間總寬, 初始非對角平方上界, 最終非對角平方上界]`：`[0.2578125, 0.001007080078125, 2, 0.002471923828125] → 同值`，四項差值皆 `0`。
* Jordan `[det R, 旋轉前 norm², 旋轉後 norm², 倒影 det]`：`[1, 25, 25, -1] → 同值`，四項差值皆 `0`。
* Hopf `[S³ 原範數², S³ 相位合成後範數², S² 原像範數², S² 相位合成後像範數²]`：`[1, 1.0000000000000002, 1, 1.0000000000000004] → 同值`，四項差值皆 `0`。
* Tamari `[K₄ 頂點數, 旋轉邊數, 連通旗標]`：`[5, 5, 1] → 同值`，三項差值皆 `0`。
* 凝聚中軸 `[積分殘差, RK4 階數, Richardson 誤差, 細步範數漂移, 精確守恆律, 賬本筆數]`：`[8.215650382226158e-15, 3.9999741296849374, 5.181372564008819e-11, 9.71454028331209e-11, 3, 20] → 同值`，六項差值皆 `0`。

### 7.3 How verified

* 在修改消元前先用一次性橋接測試擷取舊基準，隨即刪除；其後 homotopy 分割報告與 bridge 總報告各做局部即時測試，包含錯配與 NaN 負對照，全部通過且所有臨時 `test` 區塊均已刪除。
* 最終 `moon info --target wasm-gc && moon fmt`、`moon check --deny-warn --target wasm-gc`、`moon build --target wasm-gc` 全數成功，0 warnings／0 errors。
* `python3 tools/arch_check.py`：`architecture ok: 8 federations + unification apex, 39 packages, 48 components, 221 .mbt files, 152400 .mbt lines`；cubical federation `108 files / 103043 lines`，apex `15 files / 5133 lines`。
* 全倉掃描：TODO／FIXME／XXX／HACK、合併衝突標記、行尾空白、Tab、常駐測試檔／頂層測試塊皆為 `0`；完全重複的 `.mbt` 函式區塊為 `0`。三組內容相同的 `moon.pkg` 是不同套件恰好使用相同依賴，並非可刪死碼；公開但未於倉內呼叫的 API 也未被貿然刪除。
* 最終 `cmd/main` 為 `passed 129/129`；`cmd/showcase` 為 `47/47 certificates passed`、`all_ok=true`、硬體加速 `all_ok=true`。輸出保存於 `_build/final-main.out`、`_build/final-showcase.out`、`_build/final-arch.out`。

### 7.4 Boundaries

* `11040` 在本次是使用者指定的胞腔細分／高維 Kan **局部相干角幾何組合基數**，不是弧度、百分比或技術債數量。`24` 個局部胞腔與每對 `20` 個填充代表是為此指定基數建立的有限索引模型；現有 associahedron f-vector 並未自行推出這兩個參數，故不得宣稱這是所有胞腔複形的通用定理。
* `276` 是消元後保留重數的規範相干類數，不是未處理角；`remaining_after=0` 指 552 個剩餘局部角全部完成解析。
* 四族差分是固定有限代表元與指定容差下的回歸證據；精確整數／有理結果不依賴浮點容差，但 Hopf、積分與 ODE 仍不構成無限時間或整個實數域的一般形式化定理。四族仍是關係對齊而非彼此同構。
* 本輪沙盒當時沒有可用 `.git` 歷史；基準由消元前第一手源碼即時擷取，未聲稱使用 `git diff`，當時亦未提交或推送。

---

## 八、工作報告：2026-11-02 五條直覺猜想、反例攻擊與修正

### 8.1 方法與交付

* 新增 `bridge/intuitive_conjecture_lab.mbt`（415 行）與人讀報告 `bridge/INTUITIVE_CONJECTURES.md`。每條記錄都保留直覺、原猜想、搜索範圍、反例、修正版與機驗證據；`audit_ok` 只表示實驗結果成立，不表示原猜想為真。
* 新增任意 `(n,m)` 的 `coherence_quotient_summary`，讓第一條猜想真的重新枚舉不同規模，而非只重算 24/20 的固定報告。五條猜想是獨立實驗，不改既有 12 條猜想圖譜或 47 份證書的數量。

### 8.2 五條結果

1. **C-INT-01 相干角兩段商消元的規模守恆**：猜想總角數 `n(n−1)m`、規範類 `n(n−1)/2` 且重數守恆。窮舉 `2≤n≤32、1≤m≤9` 共 279 點，全部通過；狀態是**有界倖存**，不是一般證明。
2. **C-INT-02 Tamari 旋轉圖都是二分圖**：被 **K₄=C₅** 否證；5 頂點、5 邊、2-正則、連通且非二分。修正為保留連通與 `(n−2)`-正則而刪去二分性，修正版於 `n=3..8` 全過。
3. **C-INT-03 det=+1 足以保持歐氏範數**：剪切 `S=[[1,1],[0,1]]` 給出精確反例，`det=1` 但 `norm² 1→2`。修正為要求 `RᵀR=I`（複數則要求酉性）。
4. **C-INT-04 Jacobi 從 8 到 16 bits 必嚴格縮短區間**：`diag(1,2)` 的粗細總寬都是精確 `0` 且無旋轉，否證嚴格性。修正為一般只主張非增；非對角樣本的嚴格 `0.2578125→0.001007080078125` 只是一個正面實例。
5. **C-INT-05 Hopf 任意長浮點相位序列共用固定 1e-12 範數界**：在 `θ=0.37` 下第 **9650** 步首次越界，漂移 `1.000088900582341e-12`；第 9000 步仍為 `9.339196083146817e-13`。修正為使用步數相關誤差預算或另行分析正規化，不外推短序列證據。

### 8.3 最終驗證

* 一次性探索與正式報告的局部測試均在驗證後刪除；正式五項審計為 `true,true,true,true,true`，結果為 **1 條有界倖存、4 條反例後修正**。
* `moon info/fmt`、`moon check --deny-warn --target wasm-gc`、`moon build --target wasm-gc` 全過；`python3 tools/arch_check.py` 為 **44 套件、53 元件、245 個 `.mbt`、162396 行**。
* `cmd/main` 最終為 **129/129**；`cmd/showcase` 為 **47/47**、`intuition_lab=5/5`、`all_ok=true`，硬體加速亦全過。輸出見 `_build/final-main.out`、`_build/final-showcase.out`、`_build/final-arch.out`。
* 提交前掃描無 GitHub token 字樣、無常駐臨時測試、無 whitespace 錯誤；登錄資訊不得寫入倉庫或 Git 設定。


---

## 九、工作報告：2026-11-07 第九聯邦三軸的能力補完（QIIT 等式進 schema × NbE 一般 β × SLD 完備性 × 匯入圖 SCC × 真實 club 反射）

本輪全部落在 `meta/`（kt 側），`lean/` 一行未改（仍凍結在 492 條定理）。目標是「把淌欠真做掉」而不是寫進 TODO：六個缺口逐條落地為可執行定律，並同步修掉三條工具與文件缺陷。

### 9.1 What changed

| 檔案 | 變更 |
|---|---|
| `meta/iit/schema.mbt` | 等式進 schema：`ISchema.eqs`、`ischema(..., eqs? = [])`、`ipat_vars`、**`ieq_ok`（至少一端是建構子／兩端若都是建構子則同 sort／樣式變數集合相同／非空洞）**，`ischema_ok` 逐條驗證等式並回報壞在哪一條 |
| `meta/iit/quotient.mbt` | 兩條定律：`law_iit_quotient_equations_hold_and_iota_survives`（7 檢查）＋`law_iit_quotient_is_well_defined_on_all_stage_inhabitants`（6 檢查）；後者是**一般敘述**：對 Kleene 鏈上每一對居民檢查「商相等 ⇒ `iit_fold_q` 相等」（25 對）、商不逃出鏈、`sⁿz` 無窮多項收成 2 個等價類、`iit_stage` 與商在居民上交換 |
| `meta/instances/engine.mbt` | 終止序：`rule_oriented`／`orientable`／`repair_step_oriented`／`complete_oriented`＋6 檢查；SLD 完備性：`enum_uterms`（目標窮舉）、`derivable_bruteforce`（**無剪枝**對照搜尋）、`env_chain`／`env_loop`＋6 檢查 |
| `meta/instances/modules.mbt`（新增 11.7 KB） | `Module`／`ImportGraph`、迭代版 **Tarjan `scc`**、`cyclic_components`、`cycle_witness`（真迴路）、**`resolve_modules`**（DAG ⇒ 反拓撲典範序；有環 ⇒ 拒絕＋見證）＋6 檢查 |
| `meta/reflect/nbe.mbt` | `enum_terms`（型別導向**窮舉**項）、`nf_in`（帶上下文的 `nf`）、`subst` 修正、`law_nbe_general_beta_over_all_terms`（5 檢查、316 個項） |
| `meta/reflect/universe.mbt`（整檔替換） | 刪除玩具層級模型；改為真實集合論反射：`HFSet`（規範編碼）、`hf_mem`／`hf_power`／`v_level`、公式 `F` 與真滿足 `sat`、`absolute_at`、`reflects`／`reflecting_levels`、`unbounded_in_window`／`closed_upward_in_window`＋2 定律（6+6 檢查） |
| `meta/reflect/club.mbt`（新增 7.2 KB） | `OrdFun`、`fun_omega_pow`（`ω^{1+α}`）、`fun_omega_omega_pow`（`ω^{ω+α}`）、`in_range`／`preimage`、`diagonal`（12.3 對角迭代）、`range_subset`＋6 檢查 |
| `tools/gen_labels.py`（新增） | 讀 `cmd/metatheory` 的**實際輸出**重生 `lean/labels/moonbit-labels.md`（485 條／388 互異／119 族） |
| `spec.mbt` | 符號登記同步到新現實（刪 `provable`/`reflect_stmt`/`reflect_down`/`is_limit_level`；加 `nf_in`/`enum_terms`/`v_level`/`sat`/`absolute_at`/`reflects`/`reflecting_levels`/`diagonal`/`derivable_bruteforce`/`complete_oriented`/`resolve_modules`/`scc`/`ieq_ok`/`iquot`/`iquot_schema`/`icheck_q`/`iit_fold_q`） |
| 文件 | `meta/CAPABILITIES.md`（新建並改寫為能力三段式對帳＋淌欠結案表）、`meta/{reflect,instances,iit}/README.md`、`meta/README.md`、`README.md`、`lean/README.md`、`lean/labels/coverage.md`、`readme.v2.md`、本檔 |

計量：`cmd/metatheory` **455 → 485**（+30 條能力定律，`law_*` 函式 56 → **63**）；標籤分佈 core 115（互異 102）／instances 147（144）／iit 164（87）／reflect 59（55）；`cmd/main` **129/129**；`cmd/showcase` **47/47**；`arch_check` → 44 套件、53 元件、**248** `.mbt`、**164,345** 行。

### 9.2 Why / invariant

* **QIIT**：純 II 只能同時定義互索引的族；QIIT 還要等式建構子。不變式：等式是 schema 的一部分且**必須通過 `ieq_ok`**（否則商的定義沒有意義）；商對**整條 Kleene 鏈**良定義（商相等 ⇒ 摺疊相等）、商不逃出鏈、ι 律在商後仍成立、純 `iit_fold` 不尊重等式（對照組證明差別有內容）、商保守（不把一切摺成一點）。
* **全域實例**：`resolve_all` 有兩個剪枝（深度界、路徑去環）會影響完備性，所以用**刻意笨的**無剪枝 DFS 對照；修補必須產生**終止**的重寫系統，所以新規則要定向（head 節點數 > 每個 body），定向不了就報告而不是硬塞；跨模組組合的典範性要求匯入圖**無環**，有環就拒絕並給真迴路，無環則 Tarjan 的反拓撲發射序即典範解析序（與宣告順序無關）。
* **反射**：舊版把「句子裡最大的原子編號 < 層級」當成可證性，等於用編碼遊戲繞過集合、∈ 與量詞。新版的不變式是模型論的：`V_α` 是真的累積層級、`sat` 是真的滿足關係、反射＝對所有 `x ∈ V_α` 的絕對性；club 的兩半（無界、對更大層級封閉）與「交集仍是 club」都是算出來的。
* **NbE**：正規形能力不能靠樣本。不變式升級為「型別上大小 ≤ 10 的**所有**項都 β-正規、冪等、一步 β 與 η 收縮不改變 `nf`、且保型」。

### 9.3 本輪抓到的真 bug（四條）

1. **`nf` 不知道自由變數的型別**：中性應用的參數型別掉成 `TOne`，於是開項的正規形不冪等。修法：新增 `nf_in(ctx, ty, t)`，`eval_typed` 把超出環境的變數換回**原始上下文索引**（`x - env.length()`），並在應用點用 `infer(ctx, …)` 恢復參數型別。
2. **`subst` 在開項上的 β 是錯的**：`((λ. #2) #0)` 應 β 化為 `#1`，舊碼給 `#2`（拿掉一層 binder 後索引 > j 的變數沒有減一）。樣本全是閉項所以從未被打到；修好後 #3「一步 β 保持 `nf`」才真的成立。
3. **`spec.mbt` 的符號登記必須全倉唯一**：把 `nf` 加進反射條目後與立方體 NbE 條目重複，`spec_registry_sound` 失敗，`cmd/main` 由 129/129 掉成 **128/129 並在結尾 wasm trap**。修法：移除重複符號，`cmd/main` 回到 129/129。
4. **`ord_mul_omega` 是右乘（`a·ω`）不是左乘**：俱樂部 normal function 若寫成 `ω·(1+α)` 會全部塌成 `ω`。改用 `α ↦ ω^{1+α}` 與 `α ↦ ω^{ω+α}`；並記錄 `α ↦ α·2` **不連續**，`ω^{ω+α}·2` 不是 club（`club.mbt` #6 正是這個現象的正面版本）。

另外兩條工程教訓：MoonBit 同 package 內 top-level 識別字不得重複（`IEquation` 搬進 `schema.mbt` 後舊檔必須同時刪）；`moon build` 有快取，只 `tail -2` 會誤判成功，必須 grep `Error` 並實際 `moon run`。

### 9.4 How verified

```bash
export PATH="$HOME/.moon/bin:$PATH"
moon build --target wasm-gc                 # Finished, 0 errors
moon run  cmd/metatheory --target wasm-gc   # 通過 485 / 485 定律
moon run  cmd/main       --target wasm-gc   # passed 129/129
moon run  cmd/showcase   --target wasm-gc   # 47/47 證書 + 硬體加速 all_ok
python3 tools/arch_check.py                 # architecture ok: 44 packages, 53 components, 248 .mbt, 164,345 lines
python3 tools/gen_labels.py                 # 485 條 / 388 互異 / 119 族
```

* 關鍵量化證據：NbE 一般 β **316 個項**；SLD 完備性 **21,672 組**目標/深度對照；QIIT 良定義 **25 對**居民；`s(s x)=x` 下 `s⁴z = z`、無限多 `sⁿz` 收成 **2 類**。
* 工具鏈可重建性：本輪開始時沙盒的 `~/.moon` 已隨快照消失，重跑 `install/unix.sh` 並 `moon update`（registry 索引）後 `moonbitlang/async` 才可解析，`moon build` 回到 0 error —— 已在 `readme.v2.md` §2.2 記錄，避免下次誤判為程式碼壞掉。

### 9.5 Boundaries（明示）

* **集合論反射是有限視窗版**：`universe.mbt` 的「`V`」是物化的 `V_4`（16 個集合），不是全部 HF 集合；`club.mbt` 用探針集與具體極限（`sup_n (1+n) = ω`），不是對所有序數的全稱量化。
* **QIIT 良定義**是在一條 Kleene 鏈（fuel 5、上限 64）的居民上逐對檢查，不是對所有 QIIT 項的全稱定理；商用燃料上界（32），互觸等式用完即停，不假裝等價閉包。
* **SLD 完備性**是在窮舉出的目標空間（簽名 `Int/Bool/Array/Pair/Show`、大小 ≤ 6）內與無剪枝搜尋對照，不是所有 Horn 程式的全稱完備性定理。
* **實例修補**用節點數度量定向（不是完整 RPO/KBO），存在「節點數不定向但其實終止」的系統會被報告為未定向；回合數是上界。
* **Lean 側仍凍結在 492 條定理**，本輪新增的 48 條能力定律尚未鏡射（`lean/labels/coverage.md` 已標明只涵蓋遷移前的 437 條）；`lean/KtLaws/Reflect/Universe.lean` 仍是**舊玩具模型**的鏡射，屬留檔、不代表能力 —— kt 側的玩具已刪除。

### 9.6 交付清單（給下一次接手）

1. 新能力入口：`meta/instances/modules.mbt`（匯入圖）、`meta/reflect/club.mbt`（club 組合學）、`meta/reflect/universe.mbt`（HF 語意）。
2. 對帳主文件：`meta/CAPABILITIES.md`（能力三段式＋淌欠結案表＋驗證指令）。
3. 可重跑工具：`tools/gen_laws.py`（定律登記）、`tools/gen_labels.py`（標籤重生）。
4. 下一步（若要繼續推進）：把「等式進 schema」的良定義性提升為對任意 QIIT 項的全稱敘述（需要 signed 表示與 logical relation，屬證明義務）；把 Lean 側的玩具宇宙鏡射換成 HF 版本或明確標為廢棄。

### 9.7 持續整合（`/.github/workflows/ci.yml`）

2026-11-07 之前的遠端倉庫**沒有任何 workflow**（`actions/workflows` 為 0），所以「CI 通過」只能靠本機人肉複跑。本輪補上一條真實可跑的閘門，步驟與本機驗證完全一致：

| 步驟 | 指令 | 通過條件 |
|---|---|---|
| 工具鏈 | 官方 `cli.moonbitlang.com/install/unix.sh`＋`moon update` | `moon version` 有輸出（不依賴第三方 action，避免 marketplace 依賴漂移） |
| 靜態 | `moon check --deny-warn --target wasm-gc` | 0 warning／0 error |
| 建置 | `moon build --target wasm-gc` | `Finished` |
| 登記新鮮度 | `python3 tools/gen_laws.py && git diff --exit-code -- 'meta/*/laws.mbt'` | 重新產生後工作區無差異（防「加了 `law_*` 卻忘記重生 `laws.mbt`」） |
| 定律 | `moon run cmd/metatheory --target wasm-gc` | `通過 485 / 485 定律` |
| 定理 | `moon run cmd/main --target wasm-gc` | `passed 129/129` |
| 證書 | `moon run cmd/showcase --target wasm-gc` | `47/47`、硬體加速 `all_ok=true` |
| 架構 | `python3 tools/arch_check.py` | `architecture ok` |

觸發：`push` 到 `main`、`pull_request` 與 `workflow_dispatch`；`concurrency` 對同一 ref 取消舊跑，避免長跑堆積。

---

## 十、2026-11-10 工作報告：構造性泛代數自主類型論 × 雙重否定核預層模板 × 全譜立方結構與 64-Bit SWAR 退化樹

### 10.1 What changed（變更範圍與行數）

1. **第四聯邦 `topos/`（+1 檔，`750` 行）**：新增 `topos/double_negation_alexandrov.mbt`，實作篩格 Heyting 否定 `sieve_heyting_neg`、雙重否定核 `sieve_double_negation`（`j(x)=¬¬x`）、`O(|S|·|Mor(C)|)` 精確 co-Heyting 差 `sieve_coheyting_sub`（`(S ⇐ T) = ↓(S \ T)`）、餘否定 `~A` 與拓撲邊界 `∂A = A ∧ ~A`、Lawvere–Tierney 核 `double_negation_lt_operator` 與反射布林層景 `double_negation_sheaf_site`、算子奇異譜共振偵測 `operator_singular_spectrum_fp`、亞歷山德羅夫空間 `AlexandrovSpace`（`PSh(P) ≃ Sh(X_P, O_Alex(P))`）以及 `ChuSpace` 萬有自對偶。
2. **第八聯邦 `accel/`（+1 檔，`464` 行）**：新增 `accel/cubical_degeneracy_swar.mbt`，實作 64 位元無分支立方蝴蝶面萃取 `cube64_extract_face_swar`、退化插入 `cube64_insert_degeneracy_swar`、軸退化位元遮罩 `cube64_degeneracy_mask`、`O(1)` 配對退化遞推 `cube64_pair_degeneracy_o1`（`deg(pair(A,B)) = (deg(A) & deg(B)) | ((A == B) << n)`）、整係數 Moore 交錯邊界鏈 `cube64_alternating_boundary_zchain`、雙向面修剪 `cube64_bidirectional_face_prune` 與通過 W3C 瀏覽器基線審計之 `wgsl_kernel_cubical_degeneracy_prune`（不變動既有 7 核 `webgpu_frontier_kernel_suite` 計數）。
3. **第九聯邦 `meta/core/`（+1 檔 `546` 行 + 重生 `laws.mbt` 與 `lean/labels/moonbit-labels.md`）**：新增 `meta/core/malcev_chu.mbt`，實作等價關係併閉包、瑪爾切夫三元多態、核同餘與商類，並登記 5 個 `law_malcev_*` 函式（共 **+20 條定律**，`cmd/metatheory` 由 `485/485` 升至 **`505/505`**，標籤清單 `408` 互異、`139` 族）。
4. **第一聯邦新子套件 `cubical/autonomy/`（Layer 5，5 個 `.mbt` 共 `2,645` 行 + 9 節 `README.md` `85` 行）**：
   * `malcev_universal_algebra.mbt`（`728` 行）：`UniversalAlgebra`、並查集同餘閉包 `generate_congruence`、商代數與第一同構定理、瑪爾切夫一步同餘可換 `θ∘ψ=ψ∘θ=θ∨ψ`、吸收零 vs 點化零二分定理、`ℤ/6ℤ ≅ ℤ/2ℤ × ℤ/3ℤ` Zappa–Szép 中國剩餘分解、Pol–Inv 伽羅瓦對偶與 Lawvere 有限積理論範疇化。
   * `affine_bide_morgan_cubical.mbt`（`718` 行）：區間代入三體系分類（`PureBchAffine` / `InvolutiveAffine` / `DeMorganCartesian`）、無連接 2D `dcube_open_box` 在 `S¹` HIT 與 `ua(not)` 上的仿射 Kan 計算、雙德摩根立方集與超八面體群 `B₃`（`48` 個帶號立方對稱）、變長 Moore 自由路徑嚴格結合單子與 Stasheff `K₃/K₄` 相干橋、內蘊 `∞`-群胚四重刻畫與單值圓周覆蓋瑪爾切夫繞數公式 `w(p_Kan(a,b,c)) = a - b + c`。
   * `degeneracy_tree_pruning.mbt`（`648` 行）：`CubicalDegeneracyTree` 即時折疊與 SWAR 遮罩同構、正規化 `5` 維立方交錯面微分 `∂₄ ∘ ∂₅ = 0` 與 `I³` Hodge Betti 譜 `[1,0,0,0]`、基於 `@face_bdd` ROBDD 面蘊含與 `DTermInterner` 的雙向立方範式修剪（經 `@kernel.conv_at_under_face` 核驗面下定義等價）。
   * `validity_presheaf_gluing.mbt`（`339` 行）與 `autonomy_audit.mbt`（`212` 行）：Kripke–Joyal 類型有效性結構、雙重否定核預層黏合、14 類範疇組合管線與 14 欄位總驗報告 `CubicalAutonomyMasterReport`。
5. **架構、根門面與頂點橋接**：更新 `architecture.json`（`44 → 45` 套件、`53 → 54` 元件）、根 `moon.pkg`／`facade.mbt`／`spec.mbt`（+4 條規格登記，符號全倉唯一）／`verify.mbt`（`129/129 → 132/132`）、新增 `bridge/malcev_presheaf_autonomy_bridge.mbt`（`58` 行，保持 `47/47` 歷史證書不動）並接線 `cmd/showcase/main.mbt`。

### 10.2 Why（不變式與數學定理）

* **吸收零元與點化零元在瑪爾切夫多態下的結構二分**：在具備雙邊吸收零元 `0·x=0=x·0` 且冪等的二元代數（如 De Morgan 區間 `(I, ∧, 0)`）上，任何保持該運算的瑪爾切夫多態必使載體塌縮為單點（`0 = 0·x = p(0,0,1)·p(x,x,x) = p(0·x, 0·x, 1·x) = p(0,0,x) = x`）；反之在具備中性零元 `e+x=x=x+e` 的點化代數上，相容瑪爾切夫多態由 Eckmann–Hilton 論證強制誘導唯一阿貝爾群結構 `x +_p y = p(x, e, y)`。這解釋了為何立方型別論中群胚結構住在纖維路徑空間 `Path_A(x,y)`（Kan 堆算子 `p_Kan(f,g,h) = f · g⁻¹ · h`）而非區間連接半格本身。
* **可信核心邊界不鬆動**：`cubical/kernel` 未做任何破壞封裝的修改；`cubical/autonomy` 嚴格位於 Layer 5，透過公開 `CheckedDCube`、`conv_at`、`conv_at_under_face` 與 `@homotopy.circle_encode_value`（單值性 `ua(succ)` 覆蓋傳輸）驗證高階立方路徑等價。

### 10.3 How verified（Tier A / B / C 實測數據）

* **Tier B 單包即時測試（全部暫態 `test` 區塊已於驗證後立即刪除）**：
  * `moon test topos --target wasm-gc`（`1/1` passed）：Sierpiński `0→1` 子物件分類子共 `5` 個篩，`¬¬`-穩定篩 `4` 個（剔除唯一中間非布林篩 `{id_1}`），`F_p` 奇異譜投影特徵值 `[0, 1]`，雙 Heyting 伴隨、亞歷山德羅夫對偶與 Chu 自對偶全為 `true`。
  * `moon test accel --target wasm-gc`（`1/1` passed）：窮舉全部 `2¹⁶ = 65,536` 個 4-立方體，`O(1)` 配對退化遮罩與 4D 直接 SWAR 遮罩逐位一致，非退化 `64,594` 個、退化 `942` 個（精確吻合布林函數 Möbius 反演公式）。
  * `moon test meta/core --target wasm-gc`（`1/1` passed）：窮舉 `{0,1}` 上全部 `256` 個三元運算，瑪爾切夫算子恰 `4` 個，與吸收 `AND` 相容者 `0` 個，與點化 `XOR` 相容者唯一 `1` 個（`x ⊕ y ⊕ z`）。
  * `moon test cubical/autonomy --target wasm-gc`（`1/1` passed，`0.68s`）：`CubicalAutonomyMasterReport` 全部 `14/14` 欄位 `true`（含 `w(p_Kan(loop², loop¹, loop³)) = 2 - 1 + 3 = 4`、`5D` `∂₄∘∂₅ = 0`、雙向修剪 `25 → 5` 樹節點／`4` DAG 節點／`3 → 1` 管分支）。
* **Tier A & Tier C 全倉閘門（不使用 `--release`）**：
  * `moon info --target wasm-gc && moon fmt`、`moon check --deny-warn --target wasm-gc`（0 warnings / 0 errors）、`moon build --target wasm-gc`（Finished）。
  * `python3 tools/arch_check.py`：`architecture ok: 9 federations + unification apex, 45 packages, 54 components, 257 .mbt files, 169004 .mbt lines`（零殘留 `*_test.mbt` 或 `test { ... }`）。
  * `moon run cmd/metatheory --target wasm-gc`：`通過 505 / 505 定律`；`python3 tools/gen_labels.py`：`505 條、408 條互異、139 族`。
  * `moon run cmd/main --target wasm-gc`：`passed 132/132`（含 `spec_registry_sound` 符號全倉唯一核驗）。
  * `moon run cmd/showcase --target wasm-gc`：`47/47 certificates passed`、`wgsl_portable=7/7`、`Constructive Universal Algebra + ¬¬ Presheaf + Cubical Autonomy: holds=true, 4cubes=64594+942=65536, nn_sieves=4/5`。

### 10.4 What is still open（已知邊界）

* `topos/double_negation_alexandrov.mbt` 與 `cubical/autonomy/malcev_universal_algebra.mbt` 的一階普遍檢查在有限載體與有限景上逐點窮舉（如 `|A| ≤ 8`、`|Mor(C)| ≤ 16`）；無窮載體泛代數需透過自由項代數商（QIIT）與局部有限引理歸約。
* Lean 側 `lean/` 鏡射目錄仍維持遷移前凍結狀態，尚未鏡射本輪新增之 20 條 `law_malcev_*` 定律（標籤已同步寫入 `lean/labels/moonbit-labels.md`）。

---

## 十一、2026-11-10 工作報告（第二輪）：全體 54 項高階立方結構完足落地 × 26 運算動詞 × 14 範疇組合交互圖譜

### 11.1 What changed（變更範圍與行數）

1. **第一聯邦新子套件 `cubical/structures/`（Package Layer 6 / Component Layer 10，6 個 `.mbt` 共 `4,374` 行 + 9 節 `README.md` `88` 行）**：
   * `swan_id_and_free_path_fibration.mbt`：Swan/CCHM 常數範圍相等類型 `SwanIdValue`（開放中性變數 `DNVar(0)` 上嚴格定義 `J_Id(C, d, refl_x) ≡ d` vs 普通 `Path` 滯留中性 `coe` 之分離定理，以及單例可縮誘導 `Id ≃ Path`）、自由路徑空間 `ev₀`／`ev₀₁` Kan 纖維化截面、全體 `65,536` 個布林 `4`-立方體 `O(1)` SWAR Eilenberg–Zilber 規範退化分裂（層計數 `[2, 8, 60, 872, 64594]` 全數無碰撞往返）、異質合成 `comp ≡ hcomp ∘ coe` 雙演算法對帳，以及無對合純 Kan 2D 開盒逆路徑與對合逆 `λi.lp(1-i)` 的 `3D` 開盒立方同倫（`I³ → S¹` 全 `5` 面與 `10` 條交稜經 `@kernel.dcube_box_fill_verified` 核驗）。
   * `affine_bidirectional_focusing.mbt`：帶資源重數向量 `u ∈ {0, 1, ω}ⁿ` 之仿射／德摩根雙向立方類型檢查器（含 Bellman–Ford 宇宙多態層級約束環偵測、`Π` 蘊涵／全稱角色分類、`PathP`、`Glue`/`unglue`、`hcomp` 邊界系統）與極性聚焦證明搜尋引擎 `LJF`（消除 `5 → 1` 交錯排列爆炸並保持完備可靠）。
   * `functorial_poly_signatures_sip.mbt`：多項式容器函子 `PolyFunctor`、米田自然變換計數（`9` 個規範居留元）、Reynolds 二元關係提升與 Wadler 多態自由定理、依賴簽名鑽石推出並查集共融合併、立方結構恆等原則 SIP（經 `ua(not)` 將 `(Bool, ⊕, false)` 計算傳輸為 `(Bool, ↔, true)`）與宇宙累積提升往返。
   * `covering_space_pushout_torus.mbt`：一般離散覆蓋空間唯一路徑／2-胞腔同倫提升、聯動 `@sym.PermGroup` 驗證非阿貝爾群 `S₃` 六子群完整伽羅瓦覆蓋對應（正規子群 Deck 群階 `[6, 2, 1]` vs 非正規 `[1, 1, 1]`）、透鏡空間覆蓋指數整除分解、`T²` vs `S¹ ∨ S¹` 萬有覆蓋交換子升騰判準，以及基於整數行列初等變換 Smith 正規形的整係數同調（`Susp(S¹)` `[1,0,1]`、`T²` `[1,2,1]`、`RP²` 二階撓率 `[2]`）。
   * `type_reconstruction_repair_reflection.mbt`：聯動 `@elaborator.hou_unify` 之高階合一隱式動機重構、異質端點自動插入 `coe` 修補、正方形邊界 `5 → 3` 擬陣獨立基底縮減與開盒缺失頂蓋合成修補（`loop ⬝ loop²` 繞數 `+3`，角點矛盾邊界精確回報 `UnsolvableConflictPair(0, 1)`），以及自由群／阿貝爾群棧式線性時間內部計算反射。
   * `verb26_comp14_atlas.mbt`：全部 **54 項高階立方結構**逐項證書註冊表、**26 個運算動詞**索引、**14 種範疇組合模式**與 **14 條交互衍生定理**執行引擎 `verify_work4_all_54_structures_and_interactions()`。
2. **第九聯邦 `meta/core/`（+1 檔 `covering_focusing.mbt` + 重生 `laws.mbt` 與 `lean/labels/moonbit-labels.md`）**：新增 5 個 `law_*` 函式（`S₃` 覆蓋伽羅瓦對應、3D/4D Eilenberg–Zilber 退化分層與 Möbius 反演、極性聚焦位移伴隨 `↓ ⊣ ↑`、多項式米田雙射與 16 個二元關係自由定理、有限區間預層 Swan 嚴格 `J`），共 **+12 條定律**，`cmd/metatheory` 由 `505/505` 升至 **`517/517`**（`73` 個 `law_*` 函式，`420` 條互異，`151` 族）。
3. **架構、根門面與頂點橋接**：更新 `architecture.json`（`45 → 46` 套件、`54 → 55` 元件，`257 → 264` 個 `.mbt`、`169,004 → 173,957` 行）、根 `moon.pkg`／`facade.mbt`／`spec.mbt`（+5 條規格登記，共 `154` 條，符號全倉唯一）／`verify.mbt`（`132/132 → 135/135`）、`bridge/malcev_presheaf_autonomy_bridge.mbt` 與 `cmd/showcase/main.mbt`。

### 11.2 Why（不變式與數學定理）

* **Swan 嚴格 `J` 與普通立方 `Path` 在開放項上的計算分離**：在 CCHM 立方預層中，普通 `Path_A(x,y)` 的單例收縮依賴連接 `p(i ∧ j)`，對開放中性變數 `x₀ : S¹` 執行 `coe` 時無法消除非退化 HIT 消除器包裝而滯留中性項；Swan 的常數範圍配對 `(p, φ : Face)` 將「何時嚴格為常數路徑」顯式上同調化為面公式 `φ`，使 `refl_Id(x₀) = (λi.x₀, ⊤)` 在 `φ = ⊤` 分支直接短路歸約為基底項，同時由單例可縮保持同倫型 `Id_A(x,y) ≃ Path_A(x,y)`。
* **26 運算動詞 × 14 範疇組合的正交演算法生成**：例如「聚焦 × 博弈張量策略」導出極性 `LJF` 無搜尋規範階段樹（`5 → 1`），「分裂 × 單子分配律」導出 64-bit SWAR Eilenberg–Zilber 唯一退化因子化，「對偶化 × 伽羅瓦覆蓋纖維化」導出 `Aut_p(E_H) ≅ N_G(H)/H` 正規性判準，「修補 × 擬陣交換基底」導出冗餘邊界去重與開盒缺蓋合成。

### 11.3 How verified（Tier A / B / C 實測數據）

* **Tier B 單包即時測試（暫態 `test` 區塊已於驗證後立即移除）**：
  * `moon test cubical/structures --target wasm-gc`（`1/1` passed，`1.6s`）：`54/54` 結構證書、`26/26` 動詞、`14/14` 組合模式、`14/14` 交互定理全數 `true`，`[2, 8, 60, 872, 64594]` 全 65,536 個 4-立方體唯一往返、聚焦 `5 → 1`、`S₃` Deck 群 `[6, 2, 1]` vs `[1, 1, 1]`、`RP²` 撓率 `[2]`、開盒修補繞數 `+3`。
* **Tier A & Tier C 全倉閘門（不使用 `--release`）**：
  * `moon info --target wasm-gc && moon fmt`、`moon check --deny-warn --target wasm-gc`（0 warnings / 0 errors）、`moon build --target wasm-gc`（Finished）。
  * `python3 tools/arch_check.py`：`architecture ok: 9 federations + unification apex, 46 packages, 55 components, 264 .mbt files, 173957 .mbt lines`。
  * `moon run cmd/metatheory --target wasm-gc`：`通過 517 / 517 定律`；`python3 tools/gen_labels.py`：`517 條、420 條互異、151 族`。
  * `moon run cmd/main --target wasm-gc`：`passed 135/135`。
  * `moon run cmd/showcase --target wasm-gc`：`47/47 certificates passed`、`Full-Spectrum Cubical Structures × 26 Verbs × 14 Compositions: structures=54/54, verbs=26/26, patterns=14/14, interactions=14/14, focus=5->1, ok=true`。

### 11.4 What is still open（已知邊界）

* 整係數胞腔同調與覆蓋空間伽羅瓦對應作用於有限生成 CW 2-骨架與有限商基本群（如 `ℤ/nℤ`、`S₃`）；對自由積無限覆蓋（如 `S¹ ∨ S¹` 萬有覆蓋樹 `F₂`）採有界字長截斷升騰判定。
* Lean 側 `lean/` 鏡射目錄維持凍結狀態，新增之 12 條 `covering_focusing.mbt` 定律已同步登記至 `lean/labels/moonbit-labels.md`。

---

## 十二、2026-11-10 工作報告（第三輪重構 `S1–S4`）：F4 (`topos`) × F7 (`discovery`) × F9 (`meta`) × `L0 accel/swar` × `K₉ = 36/36` 星稜柱大一統

### 12.1 架構、配置與演算法變更明細

1. **Stage `S1`（F9 `meta` 三項語義漏洞修補與多項式／64-bit 演算法升級，零外部依賴保持）**：
   * `meta/reflect/universe.mbt`：修補 `hf_elements` 巢狀逗號誤切，改為括號深度感知剖析；實作 64-bit Ackermann 位元雙射（`V₄` 16-bit、**`V₅ = 65,536` 個遺傳有限集暫存器級實算**，`rank 4` 精確 `65,520` 元素）。
   * `meta/core/algebra.mbt`：以 `Int64` 無除法 Sylvester–Bareiss 消元取代易溢位之 `Int32 QRat` 高斯消元，並輸出精確整數零空間正交見證向量。
   * `meta/iit/quotient.mbt`：修補 `|eqs| == 0 || nf_eq` 恆真判定缺陷，實作雙向有界同餘閉包 E-graph。
   * `meta/core/unify.mbt` & `meta/instances/engine.mbt`：新增 Paterson–Wegman 線性時間 DAG MGU（深度 `16` 指數級項零展開合一）與頂層函子索引＋SLG 記憶化解析 `resolve_indexed_tabled`。
2. **Stage `S2`（`L0 accel/swar` 初建 ＋ F7 `tensor` & `conjecture/kernel` 位平面與有理重構升級）**：
   * 新增 `L0 accel/swar`（`swar_primitives.mbt`）：雙軌 64-trit `GF(3)` `6,561` 張量超行列式掃描、64-bit 雙 Heyting 篩算子與 64 樣本位平面蘊含＋硬體 `ctz` 極小反例核心。
   * `tensor`：將 `metric_gh_twice_exact` 升級為二分搜尋＋64-bit 域遮罩 MRV/MAC 分支定界（突破 `|X||Y| ≤ 12` 至 **`|X||Y| ≤ 64`**），新增 Vietoris–Rips 支配頂點坍縮保持同調報告 `metric_vr_dominated_collapse_report`。
   * 新增 `L3 conjecture/kernel`（`discovery-kernel`）：實作 Half-GCD 模有理數重構（突破 `mult ≤ 64` 試乘上限）與位平面蘊含格，`conjecture` 以 `pub using @kernel` 無縫重導出。
3. **Stage `S3`（F4 `topos/site` 零線性代數拆分 ＋ `Sieve64` SWAR 雙 Heyting 核 ＋ 模 `F_p` 撓率上同調）**：
   * 拆出 `L2 topos/site`（僅依賴 `symlib` 與 `accel-swar`），`L3 topos` 以 `pub using @site` 相容重導出全體 `27` 型別與 `126` 函式；實作 `Sieve64` 64-bit 雙 Heyting 核、MAC 相容族枚舉 `enumerate_matching_families_mac64` 與 `nerve_cohomology_dimensions_fp`（實算 `RP²` `F₂` `[1,1,1,0]` vs `F₃` `[1,0,0,0]` 撓率躍遷）。
4. **Stage `S4`（`K₉ = 36/36` 九聯邦全配對星稜柱 ＋ `F7 → F9 → F4 → F1` 定理自動晉升）**：
   * `bridge/meta_k9_unification.mbt`：補齊 `K8-22..28` 與 `K9-29..36` 共 **36/36 條雙邊橋**，並打通 `F7` 位平面發現 → `F9` Horn KB 完備化／SLG／Bareiss `H¹=0` → `F4` `Sieve64` 全域真值截面 → `F1` `LJF_cub` 極化聚焦唯一正規證明。
   * 規模指標：`49` 套件、`58` 元件、`269` 個 `.mbt`、`177,283` 行；`cmd/metatheory` `532/532`；`health_scan.py` `5,536` 函式 `0` 死碼。

---

## 十三、2026-11-10 工作報告（第四輪重構 `R1–R4`）：F1 (`cubical`) × F5 (`scheme`) × F8 (`accel`) 縱向底層下沉、自由 De Morgan／CCHM 語義與 F4 Gröbner 三元合流

### 13.1 架構、配置與演算法變更明細

1. **Stage `R1`（F8 `accel/swar` 全量 `L0` 下沉 ＋ `8/8` WGSL 註冊表與 `webgpu/index.html` 對齊）**：
   * 將 M4RI `GF(2)`（`m4ri_gf2.mbt`，新增 `gf2_rref_eliminate_u64`）、Ozaki-II `INT8 DP4A` CRT GEMM 與 32-bit RNS Stockham NTT（`ozaki2_ntt_rns.mbt`）、64-way 立方退化配對（`cubical_degeneracy_core.mbt`）、Scanbox/Morton 前綴掃描（`scanbox_morton_core.mbt`）、HVM2 扁平競技場 `INetArena` 與閉合 Peano `λ` 求值器（`hvm2_inet_arena.mbt`）全數下沉至 `L0 accel/swar`，`L4 accel` 以 `reexport_swar.mbt`（`pub using @swar`）重導出；全面改用硬體 `x.popcnt()`，並同步 `8/8` WGSL 靜態註冊表與 `webgpu/index.html`。
2. **Stage `R2`（F1 `cubical/store` 解耦、`L1 algebra/core` 實體拆分、Kalman 雙軌 De Morgan／CCHM 語義與 HOU `O(Δ)` 軌跡回滾）**：
   * `gcd/digest_chain_ledger.mbt`（`L0`）：承載 FNV-1a 64-bit 摘要鏈、`ℤ`-零空間賬本與任意精度 `ugcd_rat_recon_bigint`，使 `cubical/store` 完全脫離 `condensed`（套件層級 `L5 → L3`）。
   * `algebra/core/`（`pkgL=L1`, `compL=L1`）：拆出 `Rat`、`Poly`、`QPoly`、`QMat`（含 `Int64` 快徑、Ozaki-II CRT 矩陣乘 `qmat_mul_ozaki2_crt` 與無分數 Bareiss 行列式 `qmat_det`），`L2 algebra` 以 `reexport_core.mbt`（`pub using @acore`）100% 相容重導出，`topos`、`condensed`、`conjecture`、`accel`、`cubical/homotopy` 改為直接匯入 `algebra/core`。
   * `cubical/face_bdd/demorgan_cchm_swar.mbt` + `cubical/kernel/`：實作 Kalman 雙軌自由 De Morgan 區間（`dim_is_{zero,one}_demorgan`、`dim_eq_demorgan`，嚴格保持 `loop(i ∧ ¬i) ≠ base`）、自由 CCHM 上纖維化格（`cchm_face_*`，保持 `∂I = (i=0)∨(i=1) ≠ ⊤_F`）、`n ≤ 6` 單 `UInt64` SWAR 真值快徑與 `face_bdd_canon_key` 分支去重，並新增 `kernel_eval_closed_peano`。
   * `cubical/elaborator/hou_unify_stream.mbt`：於 `Unifier` 內建 `trail` 與 `HouTrailMark`（`hou_trail_{mark,rollback}`），將 Huet DFS／MGU／`HouLazyUnifierStream` 全部分支回溯由 `O(|subst|)` 複製降至 `O(Δ)` 原地復原。
3. **Stage `R3`（F5 `scheme` 64-bit `Mono64` SWAR、Yan 地理桶、M4RI／多素數 Faugère F4 與多項式時間行列式）**：
   * `scheme/f4_macaulay_swar.mbt` + `groebner_ideal.mbt`：7 變量 7-bit `Mono64` 3 指令無分支整除 `(((t | 0x80..80) - d) & 0x80..80) == 0x80..80`、單 `UInt64` `GRevLex` 比較、`O(m log m)` 歸併正規化、有序線性合併、Yan Geobuckets、Gebauer–Möller 判準、Lazard–Macaulay 不動點 M4RI `GF(2)` 布林 F4 `f4_boolean_groebner_gf2` 與三素數 `(65521, 65519, 65497)` CRT 模 F4 `f4_groebner_rat_modular`。
   * `scheme/derived_structural_theorems.mbt`：將 `mpoly_square_det` 自 `O(k!)` Laplace 餘子式遞迴重寫為 Grassmann–Plücker 外代數楔積 DP `O(k · 2^k)`（`k ≤ 10`）＋無除法 Samuelson–Berkowitz `O(k⁴)`（`k > 10`）。
4. **Stage `R4`（`F8 ↔ F5 ↔ F1` 三元合流證書、元理論窮舉定律與全倉驗收）**：
   * `bridge/accel_bridge.mbt`：新增 `verify_f8_f5_f1_triad_bridge()`（Stone–PolyBoRi 同構在初期實測即精準抓出布林 F4 未達 Lazard–Macaulay `x_v` 乘閉包前提前過濾非極小主項之微妙代數漏洞，修正後任意等價面表示皆收斂至唯一規範布林約化 Gröbner 基）。
   * `meta/core/demorgan_swar_f4.mbt`：新增 4 個 `law_*` 函式（+8 條定律，`cmd/metatheory` 達 **`540/540`**，`82` 個 `law_*`、`443` 條互異、`174` 族）。
   * 最終規模與閘門（零 `--release`）：**`50` 套件、`59` 元件、`277` 個 `.mbt`、`180,305` 行**；`health_scan.py` **`5,603` 函式 `0` 死碼／`0` 重複**；`cmd/showcase` **`47/47` 證書、`K₉=36/36`、三元橋全過（耗時由 `~90s` 降至 `37.2s`）**；`cmd/main` **`passed 136/136`（耗時降至 `1m47.7s`）**。

### 13.2 全倉 59 元件分層配置矩陣（Component Layers `L0–L14`）

| Comp Layer | 元件清單（`component_id` [`package_id`]） |
|---|---|
| **`L0`** | `foundation` [`cubical-face-bdd`]、`gcd-core` [`gcd`]、`meta-core` [`meta-core`]、`accel-swar` [`accel-swar`] |
| **`L1`** | `algebra-core` [`algebra-core`]、`finite-cubical` [`cubical-finite`]、`semiring-algebra`、`semiring-nf`、`semiring-ratelimit`、`semiring-sim`、`semiring-par`、`meta-instances`、`meta-iit` |
| **`L2`** | `numeric-hermitian` [`cubical-hermitian`]、`exact-algebra` [`algebra`]、`symlib-core` [`symlib`]、`semiring-matrix`、`semiring-monoid`、`semiring-trop`、`semiring-bp`、`semiring-io`、`hostfs-durability` [`hostfs`]、`meta-reflect` |
| **`L3`** | `models` [`cubical-hermitian`]、`transcendental` [`algebra`]、`topos-site` [`topos-site`]、`tensor-core` [`tensor`]、`semiring-graph`、`semiring-spline`、`semiring-cat`、`semiring-app`、`cmd-metatheory` |
| **`L4`** | `dependent-kernel` [`cubical-kernel`]、`topos-core` [`topos`]、`scheme-core` [`scheme`]、`discovery-kernel` [`discovery-kernel`]、`semiring-par-host` |
| **`L5`** | `dependent-kan-lines` [`cubical-kernel`]、`condensed-core` [`condensed`]、`accel-core` [`accel`] |
| **`L6`** | `elaborator-core` [`cubical-elaborator`]、`module-store` [`cubical-store`]、`cubical` [`cubical-homotopy`]、`blakers-massey` [`cubical-homotopy`]、`conjecture-core` [`conjecture`] |
| **`L7`** | `module-hotload` [`cubical-store`]、`hou-match` [`cubical-elaborator`]、`associahedron` [`cubical-homotopy`]、`brunerie-pi4-s3` [`cubical-homotopy`] |
| **`L8`** | `homotopy-universal` [`cubical-homotopy`] |
| **`L9`** | `laws` [`root`]、`cubical-autonomy` [`cubical-autonomy`] |
| **`L10`** | `cubical-structures` [`cubical-structures`] |
| **`L11`** | `registry` [`root`]、`symlib-apps` [`cmd-symdemo`+`cmd-symbench`]、`semiring-report-app` [`cmd-semiringreport`] |
| **`L12`** | `app` [`cmd-main`] |
| **`L13`** | `bridge` [`bridge`] |
| **`L14`** | `showcase-app` [`cmd-showcase`] |

---

## 十四、第三輪重構工作報告（F2 `symlib` × F3 `semiring` × F6 `gcd`+`condensed` 縱向升級 `T1–T4`）

### 14.1 階段變更與演算法定錨明細

1. **Stage `T1`（`L0 gcd` 延遲取模／HMM-SNF／模有界 HNF ＋ `L0 symlib/core` 實體拆分與 Holt 子群格／一般米田引理）**：
   * `gcd/elim_snf.mbt`（`pkgL0`）：`fp_mat_mul` 對 `p ≤ 46,340` 啟用轉置 16-lane `Int64` 延遲取模點積，`fp_rref` 改為單次 `% pm` 消元（消除每元素 7 次除法）；`zmat_snf` 升級為 Havas–Majewski–Matthews `(av, row_nnz · col_nnz, row_l1 + col_l1)` 範數導引主元選擇以抑制中間係數膨脹；新增無分數 Bareiss 行列式 `zmat_det_bareiss` 與 Domich–Kannan–Trotter 模行列式有界 `zmat_hnf_modular`（保持全域 `cur_mod = |det(B)|` 避免尾端主元相消退化）。
   * `symlib/core/`（`pkgL0` 第五基石，11 檔零外部依賴）與 `symlib/reexport_core.mbt`：`BitVec` 全面改用硬體 `popcnt` 與零配置 `and_popcount`；`lut.mbt` 新增無度數上限 `PermLut`（`n ≤ 15` 採無乘法 4-bit Nibble SWAR，`n > 15` 採 SplitMix64 + 原像核對，徹底解除 `fincat`/`gset`/`marks`/`yoneda` 之 `n ≤ 12` 硬上限）；`group.mbt` 新增 Schreier 對零配置恆等快篩與 `PermGroup::alternating`／`PermGroup::hyperoctahedral`；`partition.mbt` 將 `refine_colors` 升級為 `BitVec::and_popcount` 位向量 1-WL 精煉。
   * `symlib/marks.mbt` + `symlib/yoneda.mbt`：以 **Holt 陪集剪枝逐層擴張演算法** 重寫 `subgroup_classes`（對任意生成元秩完整，實測 `A₅(60)` 精確得 `9` 類、含 3-生成 `(C₂)³` 之 `B₃(48)` 精確得 `33` 類）；新增 Burnside 環上三角標記回代求解器 `burnside_mobius_solve`；新增一般非薄範疇／單對象群胚 `BG` 上之可表預層 `representable_presheaf`、`presheaf_from_gset` 與 `verify_general_yoneda_bijection`。
2. **Stage `T2`（F3 `semiring` 硬體 `@swar` 串接、3D 脊邊禮品包裝牛頓細分、Karp 熱帶譜、Johnson 負權 APSP、Min-Fill 變數消去與 Hopcroft 最小 DFA）**：
   * `semiring/matrix/{mul,star}.mbt`：串接 `L0 @swar`，新增 Four-Russians `k=8` 64-bit 布林矩陣乘 `mul_bool_swar`（單次 `UInt64` OR 涵蓋 `8×64=512` 次標量運算）、`GF(2)` M4RI `mul_gf2_m4ri_swar`、字組並聯布林閉包 `closure_bool_swar` 與分塊熱帶閉包 `closure_trop_swar`。
   * `semiring/trop/{newton,tla}.mbt`：`BPoly::subdivision` 自 `O(n⁴)` 四重迴圈重寫為 **3D 脊邊禮品包裝 BFS** `O(n log n + n·#Faces)`（精確比較左半平面有理斜率並支援任意多點共面與格點共線）；`tla.mbt` 升級硬體 `popcnt` 並新增 Karp 最小環平均熱帶特徵值 `trop_eigenvalue_karp`、臨界特徵向量 `trop_critical_eigenvector` 與 `verify_trop_eigenpair`。
   * `semiring/graph/dijkstra.mbt`：新增 Bellman–Ford 勢函數 `bellman_ford_potentials` 與支援負權邊（含精確負環拒絕）之稀疏全源最短路 `apsp_johnson` `O(nm log n)`。
   * `semiring/bp/factor.mbt`：新增對任意半環與有環因子圖皆精確之 Min-Fill 變數消去 `bp_exact_marginal_ve`／`bp_exact_all_marginals_ve` `O(n·q^{tw+1})`。
   * `semiring/nf/dfa.mbt`：`dfa_of_regex` 改用 64-bit 結構雜湊桶 `O(|Q||Σ|)`；`dfa_minimize` 升級為扁平反向轉移 CSR + Valmari–Hopcroft 分裂工作列演算法 `O(|Σ||Q|log|Q|)`（含自塊分裂前快照緩衝 `sp_buf`）。
   * `semiring/app/wasm_verify.mbt`：建立不依賴 `par_host` 之全目標 `wasm-gc` 驗證入口 `verify_semiring_wasm_suite()`。
3. **Stage `T3`（F6 `L1 condensed/core` 實體拆分、構造性 Nöbeling 自由整數基底、Roos–Milnor `R¹lim` 與 64× `@swar` Steenrod–Adams 前沿）**：
   * `condensed/core/`（`pkgL1`, `compL2`）與 `condensed/reexport_core.mbt`：將 `profinite_solid.mbt` 與 `spectral_homotopy.mbt`（`1,949` 行，僅依賴 `gcd` + `accel-swar`）拆為獨立輕核，使純代數／同倫下游免除 `scheme`/`topos`/`symlib` 耦合。
   * `condensed/core/profinite_solid.mbt`：新增緊緻函數型射影塔 `CompactProfiniteTower`、構造性 Nöbeling 分層纖維單模整數基底 `nobeling_unimodular_basis_zmat` 與 `verify_nobeling_free_solid_duality`（Bareiss `|det(B_ℤ)|=1` + SNF 全 `1` 證明 `C(S,ℤ) ≅ ⨁ ℤ` 與 `ℤ[S]^■ ≅ ∏ ℤ`），以及 `rlim_zmat_endomorphism`。
   * `condensed/core/spectral_homotopy.mbt`：將 `minimal_resolution_ext_f2` 重構為**內部次數 `t` 齊次分塊 `@swar.gf2_rref_eliminate_u64` + 64-bit `UInt64` `ctz` 位元列梯形化 + 稀疏生成元表示**，新增 `adams_ext_swar_frontier_report()`（`trunc_deg=12, s_max=4, t_max=12`），毫秒級機器證明 `h₀, h₁=η, h₂=ν, h₃=σ` 四個 Hopf 類、Adem 非 2-冪消滅定理及 **`Ext_A^{3,6} = 1`（`h₁³ = h₀²h₂` / `η³ = 4ν`）**。
4. **Stage `T4`（`F2 ↔ F3 ↔ F6` 三元合流橋、元理論定律擴充與全倉閘門驗收）**：
   * `bridge/f2_f3_f6_triad_bridge.mbt`：新增 `verify_f2_f3_f6_triad_bridge()` 並接入 `cmd/showcase`（初期實測即精確驗證 `A₅` 在序對 `V×V` 上 2-可遷軌道數 `sum_o2 = 2` 而非無序對 `1`）；`verify.mbt` 新增第 **137** 項檢核；`meta/core/triad_f2_f3_f6_spec.mbt` 新增 4 個 `law_*` 函式（+5 條定律，`cmd/metatheory` 達 **`545/545`**，`86` 個 `law_*`、`448` 互異、`179` 族）。
   * 全倉最終規模：**`52` 套件、`61` 元件（新增 `L0 symlib-base` 與 `L2 condensed-base`）、`282` 個 `.mbt`、`182,929` 行、`5,745` 個函式／方法 `0` 死碼／`0` 重複**；四大 `wasm-gc` 閘門（`cmd/symdemo`、`cmd/metatheory` `545/545`、`cmd/showcase` `47/47 + K₉=36/36 + 雙三元橋`、`cmd/main` `137/137`）全數通過。

---

## 十五、全倉深度健康檢查、除錯、去重、減債與死碼清理報告（2026-11-10）

### 15.1 掃描器盲區升級（`tools/health_scan.py` v2）
* 補強原版健檢腳本四項盲區：(1) 支援泛型 `fn[...]` 與限定方法 `Type::method` 剖析（掃描總數達 **`5,745` 個函式／方法**）；(2) 剝離 `//` 註解與字串字面量但**精確保留 MoonBit `\{ ... }` 字串插值表達式**，並排除 `reexport_*.mbt` 與 `using @pkg { ... }` 轉發計數造成的假陽性存活；(3) 新增無引用 `struct`/`enum` 型別與空殼列舉 `enum Foo {}` 偵測；(4) 改對剝離簽名後之純函式體計算雜湊，抓出改名複製貼上。

### 15.2 實質臭蟲修復（7 處）
1. **`symlib/fincat.mbt` (`cat_thin`)**：原版未檢查 `nobj >= 0` 且未對輸入生成箭頭取傳遞閉包，傳入非閉合生成關係（如 `[(0,1),(1,2)]`）即在 `idx.get(...).unwrap()` 崩潰；改以平坦 `O(1)` 陣列索引取代 `Map` 並補上 Roy–Warshall 自反傳遞閉包（對已閉合輸入保持完全相同的態射編號順序，徹底消除 `.unwrap()`）。
2. **`symlib/core/action.mbt` (`FinAction::on_edges`)**：將 `idx.get(...).unwrap()` 改為明確邊保持不變量檢查，並消除 `FinAction::derive` 內 `Pairs`/`Edges` 分支與 `pairs_img`/`edges_img` 之重複實作。
3. **`semiring/algebra/lattice_instances.mbt` (`CyclicSet`)**：修正負整數代表元 `x < 0` 下 `x % m` 產生負位移的錯誤（統一正規化為 `(x % m + m) % m`），並將手寫迴圈 `popcount64` 升級為硬體 `popcnt()` 指令。
4. **IEEE-754 `NaN` 比較反轉修復（4 檔）**：修補 `cubical/face_bdd/interval.mbt`（`dmin`/`dmax` 傳播 `NaN`，`interval_laws_hold` 改用 `!(... < eps)` 防止 `NaN >= eps == false` 誤判通過）、`cubical/homotopy/sphere_homotopy.mbt`（`hopf_vector_close`、`check_hopf_numeric`）、`bridge/graph_symmetry.mbt` 與 `bridge/rotation_axis_bridge.mbt`（拒絕 `NaN`/`Inf`/負容差）。

### 15.3 空殼／無引用型別消除、跨檔去重與死碼清零
* **消除全倉唯一空殼列舉與孤立型別**：將 `cubical/kernel/schema_universe_poly.mbt` 的空殼 `pub enum DLevelDecl {}` 補齊為真實三元餘積 `DLevelDeclInductive | DLevelDeclHit | DLevelDeclTerm` 與 `level_decl_validate` 並接入 `check_level_polymorphic_declarations`；補齊 `topos/site/logic_classifying_categorify.mbt` 之 `model_satisfies_theory` 並接入分類 Topos 泛性質驗證；為 `symlib/cat.mbt` 之 `FinSet` 補齊 `FinSet::id` 並接入冪集自然性驗證；刪除完全無操作之孤立結構 `AbelianPresheafQ` 與殘留懸空註解。
* **去重（7 組）**：合併 `symlib/yoneda.mbt` 中 78 行雙重貼上的 `comma_down`/`comma_up` 為共用 `comma_cat_build`；合併 `cubical/homotopy/sphere_classification.mbt` 的 `integer_succ_value`/`integer_pred_value` 為 `integer_step_value`；合併 `cubical/store` 的 `compiled_module_env_find`/`hot_load_find` 及 `bw_tube_terms`/`bw_face_terms`/`br_tube_terms`/`br_face_terms`；合併 `algebra` 的 `biquad_is_zero`/`multiquad_is_zero` 與 `jacobi_*_max_width`；將 `meta/iit` 的 `ie_find` 統一委派至 `@core.uf_find_halving`。
* **死碼清零與未驗 API 接線**：刪除舊版已被 `geom_sum_group` 取代且含無用局部變數 `mut p` 的 `geom_sum`、`star_by_iteration`、`check_coherence_angle_elimination`、`to_report_string`、`ints_to_string`、`key_lut_pairs`、`random_ints`、`gset_canon_key`、`gset_orbit_sizes` 等未引用冗餘包裝（同步 `reexport_*.mbt` 與 `.mbti`）；並將 `cchm_face_le`、`sieve64_generate`/`sieve64_pullback`、`cat_slice`、`presheaf_equalizer`、`scheme_morphism_compose`、`affine_fiber_product`、`mpoly_eval`、`csr_mul`、`Dfa::accepts`、`trop_assignment`、`UniPoly::argmin_at`、`hom_setmat`/`smat_plus`、`isomorphism_dual`、`coinduced_gset` 等核心演算法全數接入正式定理與 `wasm-gc` 驗證套件。
* **全目標驗證結果**：`moon check --deny-warn` 於 **`wasm-gc`、`wasm`、`js`、`native` 四大目標全數 `0` warnings / `0` errors**；`arch_check.py` 通過（`52` 套件、`61` 元件、`282` 檔、`182,929` 行）；`health_scan.py` 達成 **`5,745` 函式／方法：`0` 死碼、`0` 無引用型別、`0` 空殼列舉、`0` 完全重複**；`cmd/metatheory` **`545/545`**、`cmd/main` **`137/137`**、`cmd/showcase` **`47/47 + K₉=36/36 + 雙三元橋`**、`cmd/symdemo`／`cmd/symbench`／`cmd/semiringreport` 全數通過。





