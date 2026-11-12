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
   - 跨聯邦重大變更完成後，按需執行（嚴格不加 `--release`）`moon run cmd/showcase --target wasm-gc`（`48/48` 大一統證書＋`K_9=36/36`＋`F8↔F5↔F1`＋`F2↔F3↔F6` 雙三元橋）、`moon run cmd/main --target wasm-gc`（`139/139` 定理總表）或 `moon run cmd/metatheory --target wasm-gc`（`631/631` 元理論定律逐條重算）做端到端驗收（本地 2026-11-12 實測）。

---

## 二、宏觀架構治理（三輪重構 `S1–S4` ＋ `R1–R4` ＋ `T1–T4` 後之九聯邦五基石 DAG；2026-11-11 合併第十聯邦 `ualg`）

全倉受 `architecture.json`、`tools/arch_check.py` 與 `tools/health_scan.py` 嚴格守門，遵循單向無環依賴（合併後現況 **`10` 聯邦（九聯邦入雙 V／K₉、第十聯邦 `ualg` 平行、未入 K₉）＋`unification` 大一統頂點、`57` 套件、`66` 元件、`318` 個 `.mbt`、`199,215` 行**；`health_scan` 數字係遠端 2026-11-10 實測（`5,810` 函式／方法 `0` 死碼），合併截面未重跑）：

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
  - `bridge` (`pkgL8` / `compL13`) 與 `cmd/showcase` (`pkgL9` / `compL14`)：九聯邦完全圖 **`K₉ = 36/36`**、`F7 → F9 → F4 → F1` 四聯邦定理自動晉升、`F8 ↔ F5 ↔ F1` 與 `F2 ↔ F3 ↔ F6` 雙三元合流證書、18 項幾何—邏輯圖譜與 `48/48` 大一統證書。**任何下層聯邦絕對禁止反向匯入 `bridge`**。

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
moon run  cmd/metatheory --target wasm-gc   # 通過 551 / 551 定律
moon run  cmd/main       --target wasm-gc   # passed 129/129
moon run  cmd/showcase   --target wasm-gc   # 47/47 證書 + 硬體加速 all_ok
python3 tools/arch_check.py                 # architecture ok: 49 packages, 58 components, 272 .mbt, 173,944 lines
python3 tools/gen_labels.py                 # 551 條 / 453 互異 / 146 族
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
| 定律 | `moon run cmd/metatheory --target wasm-gc` | `通過 631 / 631 定律`（本地 2026-11-12 實測） |
| 定理 | `moon run cmd/main --target wasm-gc` | `passed 139/139`（本地 2026-11-12 實測） |
| 證書 | `moon run cmd/showcase --target wasm-gc` | `48/48`、`K₁₀=45/45`（歷史 `K₉=36/36` 子圖）、硬體加速 `all_ok=true`（本地 2026-11-12 實測） |
| 架構 | `python3 tools/arch_check.py` | `architecture ok` |

觸發：`push` 到 `main`、`pull_request` 與 `workflow_dispatch`；`concurrency` 對同一 ref 取消舊跑，避免長跑堆積。

---

## 十、工作報告：2026-11-10 第十聯邦 `ualg/`（構造性泛代數 × 預層模板 × De Morgan 立方體）

輸入是四份文件（構造性泛代數自主類型論、預層模板、工作內容 4、組合範例）與工程約束／作業規範。流水帳在根目錄 `Dev.txt`（本輪新建）。

### 10.1 What changed

| 項目 | 內容 |
|---|---|
| 新聯邦 | `ualg`：`ualg/core`（L0）、`ualg/site`（L0）、`ualg/demorgan`（L1）、`cmd/ualg`（L2）。只匯入 `moonbitlang/core`，`allowed_external_packages` 為空 |
| 規模 | 18 個 `.mbt`、6,618 行；27 條 `law_*`、141 個命題 |
| 登記 | `architecture.json`（+1 聯邦、+4 套件、+4 元件）；`tools/arch_check.py` 的聯邦個數上限 9 → 10；CI 多一步 `moon run cmd/ualg --target wasm-gc` |
| 文件 | `ualg/README.md`、三個子套件 README、`cmd/ualg/README.md`、`Dev.txt`；`agent.md` Part II 與 `cmd/README.md` 各加一列 |

### 10.2 Why / invariant

三個跨模組的接點，每個都是「同一個對象、兩到三條獨立計算路徑」：

1. **[T-Kal]** DM(n) 的反鏈正規形 = 2n 個字面的單調真值表 = `ualg/core` 用泛代數閉包算出的 F_{V(𝟜)}(n)（6、168 逐元素對上）。
2. **[T-F3]** 面格 𝔽(n)：`core.cg` 的商 = 「刪去不一致子句」的核 = `site` 的 O(Vⁿ)（5、48；|𝔽(3)| = 15,936）。
3. **[T-Bool]** 同一個關係 x∧¬x ≈ 0 若當 De Morgan 同餘（連 ¬），其核恰是 ¬¬ 核子的核，商為 𝟚^(2ⁿ)。

### 10.3 本輪被計算否定或修正的（四條）

1. 猜想「D₄ 的 10 個子群在 DM(2) 上全部 Galois 閉」為假：9 個。例外是 C₄，Fix(C₄) = Fix(D₄)。定律改為陳述實際結果。
2. `face.mbt` 首版兩條 FAIL 來自把任意標號的分割直接交給 `part_leq`（要求代表元形式）；改為先 `part_norm`，前提寫進 README。
3. 層化定律首版的測試預層沒有一個是層，「F 是層 ⇔ η 同構」只驗到一邊；補了 4 個層並要求個數恰為 4。
4. 伴隨計數首版有一個 G 是終對象（計數恆為 1）；換成有鑑別力的層。

### 10.4 How verified

| 指令 | 結果 |
|---|---|
| `moon check --deny-warn --target wasm-gc`（全倉庫） | Finished，0 warning／0 error |
| `moon build --target wasm-gc`（全倉庫） | Finished，6 個執行檔 |
| `moon run cmd/ualg --target wasm-gc` | 通過 141 / 141 個命題 |
| `python3 tools/arch_check.py` | architecture ok: 10 federations + unification apex, 48 packages, 57 components, 266 .mbt files, 170,963 lines |

工具鏈 moon 0.1.20261104／moonc v0.10.20。未用 `--release`。既有的 `cmd/metatheory`、`cmd/main`、`cmd/showcase` **沒有在本機重跑**（工程約束：接手後不得對既有專案跑測試）；它們由遠端 CI 負責。**本輪沒有 push**（沙盒無憑證），所以遠端 CI 尚未對這個 commit 跑過。

### 10.5 Boundaries（明示）

* 本聯邦沒有型別檢查器、沒有 Kan 運算、沒有 HIT；Kan 填充、懸掛、推出、圓、環面只做到**立方複形的同調層**。
* DM(n) 完整列舉到 n = 2；Aut([3]) = B₃ 只驗「生成的 48 個都可逆」，沒有窮舉排除第 49 個。
* `tools/gen_laws.py` 只處理 `meta/*`；本聯邦的 `laws.mbt` 是手寫的，CI 的登記新鮮度檢查不涵蓋它。
* 與 `cubical/face_bdd`、`topos/`、`symlib/` 的橋接尚未做（列在 `Dev.txt` §九）。
* 根目錄 `spec.mbt` 的符號登記表沒有加入本聯邦的符號。

### 10.6 交付清單

1. 入口：`moon run cmd/ualg --target wasm-gc`。
2. 文件：`ualg/README.md`（總覽與界線）→ 三個子套件 README → `Dev.txt`（未完成與已定未開展）。
3. 下一步候選：`Dev.txt` §九 的三條橋接；[ACCRS] 等變 Kan 條件的 B_n 版本。

## 十一、工作報告：2026-11-10 第二輪 `ualg/cube/`（立方體上的層化 × 雙重否定核子）

輸入：使用者單行指令「實做這2個大項：立方體上層化，雙重否定既核子」。經 `ask_user` 確認：
範圍＝**新套件** `ualg/cube/`（聯邦內、Layer 2）；「層化」＝ sheafification（Sh_j(E) 左伴隨）；
「雙重否定既核子」＝「雙重否定**即**核子」（j = ¬¬、j(j(p)) = j(p)）。流水帳在 `Dev.txt` 第 2 節。

### 11.1 What changed

| 項目 | 內容 |
|---|---|
| 新套件 | `ualg/cube`（L2）：`faces.mbt`（面碼↔頂點遮罩雙重索引）、`sheaf.mbt`（F×G、F+G、F⊠G、ρ、`psh_vertex`、70 個預層窮舉、V² 拒絕採樣）、`cubical_sheaf.mbt`（大項一）、`dneg.mbt`（大項二）、`laws.mbt`。只匯入 `moonbitlang/core` + 本聯邦 |
| 規模 | 5 檔、1,194 行；2 章定律、26 個命題；`cmd/ualg` 擴充為 4 個套件、Layer 2 → **L3** |
| 登記 | `architecture.json`：+1 套件／+1 元件（49 packages、58 components）；`arch_check.py` 無需改動（都在 5..10 聯邦內）；CI 不變（`moon run cmd/ualg` 已涵蓋） |
| 文件 | `ualg/cube/README.md`（新）、`ualg/README.md`、`cmd/ualg/README.md`、`agent.md`、`Dev.txt`、本節 |

### 11.2 新得到的定理

大項二（雙重否定核子）：

* **[T-Cube-1]** 立方體上 j = ¬¬ 的兩條獨立路徑一致：Heyting 否定（`hneg∘hneg`）= 頂點閉包；15,989 個開集逐一比對（n ≤ 3）。
* **[T-Cube-3] Glivenko**：Fix(¬¬) = {u_S : S ⊆ 頂點}，S ↦ u_S 是 P(頂點) ≅ Fix(¬¬) 的布林代數同構（保補、保交；併 = j(u∨v)）；
  正則子複形數 **4、16、256**（|O(V³)| = 15,936 = `face_count_recursive(3)` 對帳）。
* **[T-Cube-4]** j ⊣ i（v 取正則開集；n ≤ 3）。**[T-Cube-5/T-Bool-cube]** DM(n) 布林反射的核 = j 的核（第三條路徑），類數 4、16。
* **[T-Cube-6]** dim ≥ 1 的面（25 個）：j(∂σ) = j(↓σ)（球面與填充在布林化下不可分）；j 不保併（484 組反例）；
  量詞與布林化不交換（j∃i ≠ ∃i j 4 組、j∀i ≠ ∀i j 44 組）。

大項一（層化）：

* **[T-Cube-S1] Sh_¬¬(□ⁿ) ≃ Set^{頂點}**：ρ_x 逐點雙射；且 ρ 是**顯式自然同構** F ≅ F̂(F|頂點)（n = 1 的全部 10 個層、n = 2 的 16 個子終層）。
* **[T-Cube-S2]** 子複形 K 的層化 = 頂點閉包 a(K) = u_{verts K}（V¹、V² 全部子複形窮舉；V³ 抽 60 個 + 公式對帳）；
  **子終 ¬¬-層 = 正則子複形**，4、16、256 個。
* **[T-Cube-S3]** a(F)(x) = ∏_{v≤x}|F(v)|（V¹ 全部 **70** 個大小 ≤ 2 預層；V² 112 個；V³ 常數 Δ2、Δ3 算到頂纖維 256、6561）；
  冪等 a(aF) ≅ aF；**F 層 ⇔ η_F 同構**。
* **[T-Cube-S4] 層化只經由頂點決定**：a(aF⊠aG) = a(F⊠G)（Künneth）、a(F×G) = aF×aG、a(F+G) = a(aF+aG)。
* **[T-Cube-S5] |Ω_¬¬(x)| = 2^{2^{dim x}}**（n ≤ 3 全部面）；對照 id-核子 Ω_id：頂 = 48 ≠ 16。
* **[T-Cube-S6]** a ⊣ i 計數（V¹ 86 對；V² 32 對）；層 F、G 之間 |Nat(F,G)| = ∏_v |G(v)|^|F(v)|（100 對）；G = Ω（非層）時 16 ≠ 47。

### 11.3 本輪被計算否定或修正的（七條）

1. `a(F⊠G) ≅ aF⊠aG` 為假（F = G = Δ2：邊處 8 ≠ 16）→ 正確：a(aF⊠aG) = a(F⊠G)。
2. `a(F+G) ≅ aF+aG`（逐點）為假 → 正確：a(F+G) ≅ a(aF+aG)（a 左伴隨保 Sh-餘極限）。
3. Glivenko「Fix(¬¬) 保併」為假 → Fix 的併 = j(u∨v)（484 組對照）。
4. `∂σ ≡ ↓σ` 對 σ = 頂點不成立 → 限制 dim ≥ 1，頂點情形寫進標籤。
5. Ω_¬¬（V²）首版公式按錯誤元素序寫死 → 改為 `face_dim` 計算（與 V³ 同一段）。
6. V³ 不做 15,936 個子複形的 `is_sheaf` 全窮舉（太慢）→ n ≤ 2 全窮舉 + n = 3 以格刻畫窮舉 + 代表元直驗，標籤誠實標註。
7. a(Δk) 頂纖維的首版標籤字面數字寫錯（公式本身對）→ 已更正。

### 11.4 How verified

| 指令 | 結果 |
|---|---|
| `moon check --deny-warn --target wasm-gc`（全倉庫） | Finished，0 warning／0 error |
| `moon build --target wasm-gc`（全倉庫） | Finished（6 個執行檔含 cmd/ualg） |
| `moon run cmd/ualg --target wasm-gc` | 通過 **167 / 167** 個命題 |
| `python3 tools/arch_check.py` | architecture ok: 10 federations + unification apex, **49 packages, 58 components, 271 .mbt files, 173,471 lines** |

工具鏈同第 1 輪（moon 0.1.20261104／moonc v0.10.20），未用 `--release`。**既有套件未重跑**（工程約束）。**沒有 push**（沙盒無憑證），遠端 CI 未跑。

### 11.5 Boundaries（明示）

* V³ 二元核子公理只驗偽隨機 1,200 對（窮舉是 254M 對，沒做）。
* Sh_¬¬(□ⁿ) ≃ Set^{頂點} 是**對尺寸窮舉 + ρ 的顯式自然同構**；不是類型論意義的證明。
* Ω_¬¬ 只驗了逐面的大小公式；限制映射的具體形狀沒有驗。
* 量詞與布林化不交換只做了反例計數（4／44），沒有分類所有反例的形狀。
* 沒有與 `topos/`、`cubical/` 橋接；核子普查仍只在小偏序可行。
* 本輪網絡搜索：[GLIV]（代數版 Glivenko：¬¬ 同態到正則元布林代數上，Springer 2008）、[MDL]（Rijke–Shulman–Spitters, Modalities in HoTT §3.3：¬¬-模態 = 沿 ¬¬ 拓撲層化；只對 hProp 等於 ¬¬ 本身——本輪把 j 與 a 分成兩個大項正是為此）、[CAUS]（arXiv:2607.15629，旁證）、[SUBLOC]（MathOverflow 60380：X^{¬¬} 最小稠密子locale）。**日期更正**：本輪實測 HKT 為 2026-11-10，第 1 輪文件日期正確，先前「2026-11-09」的判斷是錯的。

### 11.6 交付清單

1. 入口：`moon run cmd/ualg --target wasm-gc`（167/167）。
2. 文件：`ualg/cube/README.md` → `ualg/README.md` → `Dev.txt` 第 2 輪。
3. 下一步：`Dev.txt` §九——橋接（face_bdd／topos）、[GLIV] 類 Glivenko 定理在 DM(n) 上的陳述、V³ 二元公理窮舉（約 254M 對，需 Poset 遮罩最佳化）。

## 十二、2026-11-10 第 3 輪：`meta/` 四個缺口的結案（MoonBit 側）

任務面：「重新對 meta 所有缺口動工」。只動 MoonBit 側（Lean 凍結、無 toolchain）；
不新增無關文件；既有 README／CAPABILITIES／agent 文件照舊同步；**不 push**。

### 12.1 交付（四個缺口，全部有機器複驗）

1. **STLC η-約簡**（`meta/iit/stlc.mbt`）：`stlc_eta` + `stlc_unweaken`（與 `subst_insert` 對稱的索引傳輸）。
   `x ∉ FV(f)` 的**可判定形式**：vz/vs 表示法中，相對 binder 深度 δ 的任何 `vz`（ctor 4）絕對位置恰為 δ，
   要命中「受綁變數」（f 根上下文位置 0）只可能是 `vz`——故「f 不含 `vz`」⟺「x ∉ FV(f)」。
   η 例（`λx. (λy. y) x ↝ λy. y`）保型由 `icheck`／`iindex_of` 重算複驗（9 條檢查：良構、索引相同、
   語法上等於 `stlc_ex_eta_rhs`、η 不再自動觸發、參數非受綁變數時不觸發、f 隔一層 binder 用到 x 時不觸發）。
   邊界：root-only，與 β 一致；強正規化（SN）仍未證——見 §12.3。
2. **matroidal_criterion (⇐) 的逐實例證書**（`meta/instances/characterize.mbt`）：
   `matroidal_certificate`（產生：可解目標 = 公理可解目標；每個可解目標一個區塊 = 覆蓋它的公理規則；
   區塊互斥檢查；合成規則 head 落在目標上 ⇒ 誠實回 `None`）+
   `verify_matroidal_certificate`（**不看產生器**：分割完備性/互斥、區塊規則皆公理且 head 可合一其目標、
   loop 不覆蓋任何目標、可解清單與現場重算一致、**2^n 窮盡對帳**，n ≤ 12，與 `submodularity_witness`
   同一上限；n > 12 直接 false）。取代舊版「12 個樣本環境逐一對帳」。12 條檢查含：竄改證書（丟 loop、
   砍可解清單）必須被驗證器拒絕；判準成立時貪心刪除對 n ≤ 4 的**每一種**刪除順序都得到最優解。
   剩餘邊界寫在文件裡：Lean 側的全稱定理（原 O-義務）仍未做。
3. **mirror_rule 的多目標問題**（`meta/instances/compose.mbt`）：
   量測先行——⊨ 樸素鏡像在 ≥ 2 前提規則上**雙向都不對應**（`env_composite_chain`：
   SLD 說可導、樸素鏡像說不可導，定律 #3 釘住此反例）。故：
   (a) `mirror_exact(e)` 成為鏡像定理的**可執行前置條件**（≤ 1 前提）；
   (b) 多目標的正確餘衍生 = **正向最小模型** `forward_least_model`（pattern 對實例單向匹配 +
   吞併 collapse；∪ 項大小（目標大小 + 2）、原子數 256、輪數上限；三值誠實輸出：
   `Some(true)` / `Some(false)`（不動點才可說否）/ `None`（超限拒絕））。
   `forward_derivable` 的預算論證寫在函式註解：本系統每條規則的子目標實例都 ≤ 其結論，
   故 |f| ≤ |goal| 可證；預算外的原子不可能參與本目標的推導。
   7 個環境（含 `env_show` 的雙前提 `showPair`）× 4 個目標與 SLD 逐點一致（定律 #6）。
4. **R(4,5) ≥ 25**（`meta/core/ramsey_ex.mbt`）：以**發表見證**機器複驗下界——McKay–Radziszowski
   1995 完整目錄 `r45_24.g6`（352,366 張；CC BY 4.0）的**首張** (4,5,24)-graph 直接嵌入本倉
   （24 個遮罩，124 條邊，度數 9×2／10×12／11×10）。兩條獨立演算法複驗：`ramsey_check_coloring`
   （無紅 K₄、無藍 K₅）與 `g_clique_count` 遮罩交集（K₄ = 0；補圖 K₅ = 0 = 獨立 5-集）。
   Lean/HOL4 對照：Gauthier–Brown (LIPIcs ITP 2024, 16:1–16:18) 以同一目錄為 R(4,5) > 24 的見證完成形式化。
   上界仍為遞迴值 32（R(3,5)+R(4,4) = 14+18）——1995 年的 `R(4,5) = 25` 證明（3.2 CPU-years 窮舉）不在本倉範圍。

量化：`cmd/metatheory` **485 → 527**（+42 條檢查：η 9、證書 12、餘衍生 10、R(4,5) 11）；
`law_*` 63 → **67**；標籤 **485 → 527**（互異 **430**、**123** 族；core 126／instances 169／iit 173／reflect 59）；
`lean/labels/moonbit-labels.md` 已由 `tools/gen_labels.py` 讀實際輸出重生。

### 12.2 How verified

| 指令 | 結果 |
|---|---|
| `moon run cmd/metatheory --target wasm-gc`（反覆跑直到全綠；中途兩次 FAIL：項大小預算論證、`env_show` 不在鏡像精確片段的斷言） | 通過 **527 / 527** 定律 |
| `python3 tools/arch_check.py` | architecture ok: 10 federations + unification apex, **49 packages, 58 components, 271 .mbt files, 173,471 lines** |
| `python3 tools/gen_laws.py` / `gen_labels.py` | laws.mbt 重生無漂移；標籤清單重生為 527／430／123 |
| `moon check --deny-warn --target wasm-gc`（修錯期間） | Finished，0 warning／0 error |

工具鏈同前（moon 0.1.20261104／moonc v0.10.20）；`/var/tmp/moonhome` 的 registry 曾被沙盒清空，
`moon update` 重建後 `moonbitlang/async` 恢復可解析（教訓：`.mooncakes` 在工作區會持久化，registry 索引不會）。
**沒有 push**（使用者指示：只在明示要求時推）；遠端 CI 對本輪 commit 未跑。
**本輪未跑 `cargo`／Lean（凍結）**；`cmd/ualg` 未重跑（本輪未動 `ualg/`）。

### 12.3 Boundaries（明示）

* STLC：η 已做、**強正規化仍未證**；β/η 皆 root-only；`subst_insert` 的索引傳輸不涵蓋相依型別。
* 擬陣證書：n ≤ 12 的**窮盡**對帳；n > 12 誠實 `false`；2^n 對帳成本寫在 `verify_*` 註解裡；
  Lean 全稱定理未做；`(⇒)` 方向只有反例族，沒有構造性證明。
* 餘衍生：有界（項大小／256 原子／燃料輪數）；`capped = true` 時「否」不可信（程式內三值處理）；
  「預算外原子不可能參與本目標推導」的論證依賴「子目標 ≤ 結論」的規則形狀，已明示寫在程式註解裡。
* R(4,5)：只有 **≥ 25**（發表見證機器複驗）；**不是 25 的證明**，更不是 `R(4,5) = 25`；
  完整證明（1995）與其 HOL4 形式化（2024）是外部工作，本倉不重現。
* R(5,5) 未動（43 ≤ R ≤ 48，雙邊超出本倉方法）；Lean 仍凍結。

### 12.4 交付清單

1. 入口：`moon run cmd/metatheory --target wasm-gc`（527/527）。
2. 文件：`meta/README.md`（§7 邊界／§10 缺口處理）、`meta/CAPABILITIES.md`（第 3 輪補記）、
   `lean/labels/moonbit-labels.md`（重生）、`README.md`／`readme.v2.md`（計數與 `--release` 修正）、
   `.github/workflows/ci.yml`（標籤 527/527）、`Dev.txt` 第 3 輪。
3. ~~下一步：STLC 強正規化~~（已由第 4 輪以「逐項 SN 證書」結案，見第十三節；普世定理仍屬 Lean 義務）、
   擬陣證書全稱版（signed 表示 + 邏輯關係，
   屬 Lean 義務）。R(4,5) 見證的上游逐邊交叉核對**已完成**（2026-11-10）：重新下載 `r45_24.g6`
   第 1 行，以獨立 Python 解码器解碼（n = 24、276 個資料位元恰好耗盡、124 條邊、
   度數 9×2／10×12／11×10），與 `meta/core/ramsey_ex.mbt` 嵌入的 24 個遮罩逐位一致。

## 十三、2026-11-10 第 4 輪：推送暫緩 ＋ STLC 逐項 SN 證書（MoonBit 側）

任務面：使用者要求「自已重新算過」→ 明示「我要求你先推」→（推送無法執行、使用者裁定暫緩）
→「跟進 agent.v2 待辦事項」並指定先做 **STLC 強正規化**（第十二節末「下一步 1」）。

### 13.1 交付（第十二節「下一步 1」結案；不是普世定理）

**`meta/iit/sn.mbt`** ——逐項 SN 證書，β∪η、**所有位置**（ξ 基準）：
* `stlc_one_step_reducts`：一步歸約窮舉（β∪η），結構等式去重。
* `stlc_sn_depth(t, max_nodes) : Int32?`：完整歸約樹窮舉（記憶化）；`Some(k)` = 全部路徑 ≤ k
  （完整樹驗明；對 STLC 項樹必有限故有預算即完整）；**預算超 ⇒ `None`（不是「不 SN」）**。
* `stlc_sn_tree_typed(s, t, max_nodes) : Bool?`：樹上每個節點重跑 `icheck`。
* 6 條新 `law_*`（73 總數）：電池良構＋有限證書（id/app1/app2/k_app/eta_deep/open_var）；
  精確深度（id=0、app1=1、app2=1、eta_deep=1、k_app=2）；two_positions 恰 2 個互異一步歸約；
  η-redex 探索（λh.λx. h x ⇒ λh. h）；預算三值；測度（最長路徑深度）沿每一步嚴格下降。

`cmd/metatheory` 輸出新增一行（**527 → 551 定律全綠**）：
`STLC 逐項 SN 證書（窮舉 β∪η 歸約樹，**不是**全稱定理）：two_positions 一步歸約數 = 2，k_app 深度 = 2`

**另：R(4,5) ≥ 25 見證的上游逐邊交叉核對完成**（第十二節「下一步 3」；第 4 輪開場）：n = 24、
124 邊、124×2 = 度數和 248、度數分佈 9×2／10×12／11×10、與嵌入遮罩逐位相等——
上界仍 32；這不是 R(4,5) = 25 的證明。

### 13.2 How verified

| 指令 | 結果 |
|---|---|
| `moon check --deny-warn --target wasm-gc` | 0 warning／0 error（曾捕獲 `SnCtx` 未標 `priv`） |
| `moon run cmd/metatheory --target wasm-gc` | 通過 **551 / 551** 定律 |
| `python3 tools/gen_laws.py` | total law functions: **73**；`laws.mbt` 重生無漂移 |
| `python3 tools/gen_labels.py` | **551 條／453 互異／146 族**（core 126／instances 169／iit 197／reflect 59）；工具現在也印出分套件統計 |
| `python3 tools/arch_check.py` | architecture ok: 10 聯邦 + apex，**49 packages / 58 components / 272 .mbt / 173,944 行** |
| `moon run cmd/ualg`（第 4 輪開場自算）、`cmd/main`、`cmd/showcase` | 167/167、129/129、47/47（本輪未動對應程式碼） |

工具鏈 moon 0.1.20261104／moonc v0.10.20／wasm-gc；`moon update` 重建過 registry（勿 rm /var/tmp/*-build）；
未用 --release；無 benchmark。

### 13.3 Boundaries（明示）

* **這不是全稱強正規化定理**：Tait–Girard 可歸約性／邏輯關係在本倉無法表達（Lean 凍結）；
  普世命題仍未證。`Some(k)` 是最長路徑上界，不是項大小的函數；樹本質指數時只能 `None`。
* 預算是「窮舉節點數」；共享子項經記憶化（結構等式）；`None` 不蘊含「項不終止」。
* SN 證書對**封閉的 STLC 項**設計；開放項電池項（stlc_ex_var）僅作為 ICHT 檢查旁路納入，
  未陳述開放項終止性的額外論述。
* R(4,5) 上界仍 32；R(5,5) 未動；lean/ 凍結；**未 push**（使用者裁定暫緩）。

### 13.4 交付清單

1. 入口：`moon run cmd/metatheory --target wasm-gc`（551/551）；`meta/iit/sn.mbt` + `cmd/metatheory` 新增一行輸出。
2. 文件：`meta/iit/README.md`（sn.mbt 行）、`meta/README.md`（§7 邊界表 β/η 行＋§10 第 1 項）、
   `meta/CAPABILITIES.md`（現況＋第 4 輪補記）、`README.md`／`readme.v2.md`（計數＋SN 能力列）、
   `lean/labels/moonbit-labels.md`（重生＋iit 分佈附註）、`lean/README.md`／`lean/WHY.md`／
   `lean/labels/coverage.md`（計數）、`.github/workflows/ci.yml`（551/551）、`Dev.txt` 第十三節。
3. 下一步（若繼續）：擬陣證書全稱版（需 Lean/signed 表示＋邏輯關係，**Lean 凍結**）；
   ualg/cube ↔ cubical/face_bdd、topos/site_presheaf 橋接對帳；[GLIV] 類 Glivenko 在 DM(n) 陳述；
   V³ 二元核子公理窮舉（≈254M 對，需 POSETT 遮罩最佳化）；Lean 全稱鏡射（解凍後）。

## 十四、2026-11-10 第 5 輪：Lean 全面複工 —— O4 交付（誠實版本 + 反例）／ Universe.lean DEPRECATED

任務面：使用者選定 Lean 解凍（「lean 全面複工，把積壓事項全部做」）。積壓範圍：賴 lean/WHY.md §3
六個 metatheorem 義務 O1–O6＋ Universe.lean 的 §5.3 處置＋相關文件同步。

### 14.1 交付物

| 義務 | 狀態 | 內容 |
|---|---|---|
| **O4** | ✅ **完成（誠實版本）** | 原命題 `orientable e → WellFounded (Rewrites e)` **為假**；落倉嚴格充分條件版 `measureDecreasing ⇒ WellFounded`＋`envShow_terminating`（`lean/KtLaws/Instances/Termination.lean`，316 行）。反例 kernel 驗明 `kt_node_measure_orientation_unsound` |
| O1 / O2 / O3 / O5 / O6 | ❌ **未完成（如實）** | 需要 logical relation／推導樹全歸納／signed QIIT／SCC 自建／club 交理論（無 mathlib）；預估 1–2／2–3／3–4／1／1–2 週；未動工。記錄於 WHY.md §6 |
| Universe.lean 處置 | ⏸ §5.3 A/B/C 等裁決 | 保留＋檔首 DEPRECATED 標記；不刪除（刪除需 §5.3 裁決；B 另倉受推送 deferral 限制） |
| 登記表／文件 | ✅ 同步 | Registry 492→**505**（+13：`uSize_apply`/`sum_map_le_of_count_le`/`root_size_decreases`/`uSizeList_rewrite_lt`/`rewrites_size_decreases`/`rewrites_restriction_wf`/`envShow_rules_measureDecreasing`/`envShow_terminating`/ct_*decide/ct_step/kt_node_measure_orientation_unsound）；UNIVERSAL 137→**146**；WHY/README/coverage 同步 |

### 14.2 How verified

| 指令 | 結果 |
|---|---|
| `lake build`（全倉，Lean v4.35.0） | 綠（25 jobs；`example : provedLaws.length = 505 := rfl` kernel 通過） |
| `lake env lean` 型別探測 | headσ = 6、bodyσ = 7 交叉確認（反例雙邊） |
| 文件計數一致性 | WHY.md/README.md/UNIVERSAL.md/coverage.md/根 README.md 全部更新到 505/146/593/9,286（用 wc 重算，非照抄舊值） |

### 14.3 Boundaries（明示）

* **沒有「假 O4」**：原 `orientable ⇒ WellFounded` 沒有被做出來，因為**它為假**（kernel 反例）；
  落倉的是更嚴的充分條件定理。完整主張需化簡序（RPO/KBO）。
* **O1/O2/O3/O5/O6 沒有任何 pseudo-done**：沒有 `sorry` 冒充義務完成；沒有新增假設蒙混。
* MoonBit 側未動；CI 未動；R(4,5)/R(5,5) 未動；**未 push**。
* 登記表手工同步（provedLaws/#check/length rfl/import）；`Registry.lean` header 過時「437」已修正。
* O4 的承載說明：`uSize_apply` 以 mutual **def** 承載證明（嵌套歸納對 tactic `induction` 不支援，
  結構遞迴仍由同一 equation compiler 編譯，kernel 檢查照實生效）。

### 14.4 交付清單

1. `lean/KtLaws/Instances/Termination.lean`（新，316 行）＋ `KtLaws.lean`／`KtLaws/Registry.lean` +import。
2. `lean/KtLaws/Reflect/Universe.lean`（DEPRECATED header；定理照舊建置）。
3. 文件：`lean/WHY.md`（O4 列重寫、§2.1 全表與表合計重算、§6 已授權清單/未完成清單）、
   `lean/README.md`、`lean/UNIVERSAL.md`、`lean/labels/coverage.md`、根 `README.md`、
   `Dev.txt` 第十四節、本節。
4. **工作區**現況：`lake build` 綠；git tree 乾淨（提交後）；未 push。

### 14.5 下一步（若繼續）

* 先決定 **§5.3 A/B/C** 處置（需使用者裁決；B 需先解除 push deferral）。
* 若繼續做義務：**O6（club_inter）** 需要 normal function 理論（含 CNF 遞歸上的 sup-closure）、
  **O5（imports_acyclic_iff）** SCC 自建——兩者都可在本倉完成但工作量遠超本輪；
  **O1** 是終端缺口（那才是「若只准做兩條」的另一條），預估 1–2 週、不宜在單輪內假裝完成。
* 義務工程治理建議：之後每做完一條義務，照本節模板更新 WHY §3／§6 與 Dev.txt 節號。

## 十五、2026-11-10 第 6 輪：使用者裁決——刪除 Universe.lean（不另作保存）；O1–O6 全做、kernel 綠為驗收

### 15.1 裁決（ask_user 確認）

| 項目 | 裁決 |
|---|---|
| 刪除範圍 | **universe_only**：只刪 `lean/KtLaws/Reflect/Universe.lean`；四個純 decide 檔保留 |
| 義務驗收 | **full_kernel**：每條義務 `lake build` 綠、無 `sorry`、登記表生效（「全都需要做，不要只做兩條」） |

### 15.2 交付

* **Universe.lean 刪除**：41 條登記／12 條全稱移除；Registry `#check` 與 `provedLaws` 各移除；
  `example : provedLaws.length = 464 := rfl`（kernel 綠）；`Nbe.lean` 死 import 除去；
  **無存檔**（§5.3 選項 C 減免存檔；B 另倉因 push deferral 未採行）。
* **環境事故**：`.elan` toolchain 整個遺失；上一回合 commit（3fc5d43/32f9399）物件不存在；
  HEAD 退回 2c0350b。工作區檔案（含 Termination.lean、docs、.gitignore）**全部倖存**；
  重裝 elan 4.2.4 + `leanprover/lean4:v4.35.0`；本回合重新提交。
* **計數**（wc 重算）：8,822 行／552 宣告／134 全稱／380 計算／38 其他／**464 登記**。
* **文件同步**：WHY、lean/README、UNIVERSAL、coverage、repo 根 README（505→464 等）。

### 15.3 O1–O6 狀態（無一假完成）

O4 已完成（第 5 輪，見 §十四）。**O1/O2/O3/O5/O6 仍未完成**；無 `sorry` 陳述任何義務為完成；
均已列於 WHY.md §6 與 Dev.txt 第十五節，含各自的成本評估與相依性。

### 15.4 下一步

逐條落倉（kernel 綠才算）：優先 O5（自建 SCC，~1 週級工作量，本倉既有 list 圖基礎設施可起步）→
O2（SLD 完備性；先讀 `solvable` 實作再逐案歸納）→ O6（club 交；CNF sup 封閉理論）→
O1（logical relation）→ O3（QIIT）。如預算耗盡，如實列未完成清單，不以任何方式包裝。

---

## 十六、2026-11-11 第 7 輪：使用者裁決——接著進行 O1（「接著進行O1，並在完成後更新相關檔案記錄」）

### 16.1 環境與範圍

* `.elan` 每輪被快照洗掉（前幾輪已反覆發生）；這一輪改裝到非隱藏路徑 `/home/user/toolchain`
  （`ELAN_HOME=/home/user/toolchain sh elan-init.sh`；`leanprover/lean4:v4.35.0` 已裝好），
  使用 `export ELAN_HOME=/home/user/toolchain PATH="/home/user/toolchain/bin:$PATH"`。
* 使用者指示：繼續做 O1，完成後更新相關檔案記錄。

### 16.2 本輪落地（O1 第一半邊，kernel 綠）

* 新檔 **`KtLaws/Reflect/NfNormal.lean`**（110 行）：
  * `isLamHead`／`isBetaNormal` 兩個可執行 Bool 定義；
  * `reifyN_isBetaNormal`：**對所有燃料／型別／語義值**，`reifyN`／`reifyNeuN` 的輸出恆
    β-正常、且 `reifyNeuN` 的輸出頭不為 `lam`（對燃料做同時歸納；不需要型別前提）；
  * `nf_isBetaNormal`：`nf A t` 恆 β-正常（丟掉了 `check` 前提——證明強於陳述）；
  * **`nf_beta_normal`**：`check Γ t A = true → isBetaNormal (nf A t) = true`——
    與 WHY.md §3 的 O1 陳述**同形**（`Γ : List Ty`；保留 `_h` 參數只為對齊原始陳述，
    證明中未用）；
  * 兩條 `decide` 樣本（`nf_beta_normal_sample_star/lam`）。
* 同步：`KtLaws.lean` 加 import；`Registry.lean` 加 2 登記＋2 `#check`；
  **`example : provedLaws.length = 466 := rfl`**（kernel 檢查通過）；
  `lake build KtLaws.Registry` 23 jobs 全綠；`lake env lean KtLaws/Registry.lean` 印出 466。
* **這不是 O1 整則完成**：O1 陳述還有冪等半邊 `nf (nf t) = nf t`——需要 NbE 相對 βη 的
  soundness（reducibility/logical relation），如 WHY.md §3 原估 1–2 週；本輪未動工、未以
  `sorry` 包裝；已如實記錄於 WHY.md §3／§4／§6 與 Dev.txt 十六。

### 16.3 其他義務狀態（不變，如實）

* **O2**：`Instances/SldComplete.lean` 仍**紅**。上一餐已定位 on-disk `hasBody_ne` 陳述**本身不可證**
  （`k = 0, bs = []`：LHS = true，RHS = `∀ i kids, [] ≠ []` = False）；修法＝改統一 fuel `n` 陳述＋
  children 同層歸納；**提交前未落地**；未計入任何登記，避免汙染 Registry。
* **O3、O5、O6**：未動工。
* **Registry 466 條中僅 2 條屬 O1；無任何 sorry；無任何義務被包裝成完成。**
* moon 側未動；CI 未動；未 push（仍 defer）。

### 16.4 下一步

O1 冪等半邊（完整 logical relation；預估 1–2 週）；或回到 O2 把 `hasBody_ne` 改統一 fuel 落地
（先 `lake env lean` 逐檔驗證再 `lake build` 全倉）。這次 `.elan` 改裝至非隱藏路徑
`/home/user/toolchain`，評估跨回合存活性；若失效就照上輪方法重裝（得到 15s 級重裝）。

### 16.5 同日重計與文件更正（2026-11-11，接 16.2 之後）

* **發現**：WHY.md 逐檔行數早已漂移（`Nbe` 340→339、`Engine` 502→499、`Registry` 1008→1014），
  且漏列 `Instances/ImportGraph.lean`（83 行，獨立 `lake env lean` 綠、未入桶、未登記 Registry；
  7 條 ImportGraph 全稱 Prop 定理，`Reachable` 歸納證明）與 `Instances/SldComplete.lean`
  （308 行，O2 紅、1 條 `sld_complete`，`lake env lean` exit 1，不計入任何統計）。
* **決策（如實計入）**：ImportGraph 7 條全稱計入清單，明確標註 未入桶／未登記。
* **修正後數字**：全稱 137→**144**（=134＋NfNormal 3＋ImportGraph 7）／宣告 562→**573**
  ／其他 43→**47**／具體計算維持 **382**／行數合計 8,932→**9,326**（=9,348 磁碟 − 22 桶檔；
  其中 9,018 已編譯綠，308 紅檔僅計行數）。WHY.md §2.1 表、UNIVERSAL.md（144 條，含
  ImportGraph 專節）、lean/README、lean/labels/coverage.md、root README.md（另刪除已刪除的
  Universe 玩具模型之慶功措辭、492/580/403/40 等舊數）、meta/CAPABILITIES.md 全部同步。
* **Dev.txt 第十六節說「lean/README、UNIVERSAL 已同步」時點其實尚未同步**——本節為更正記錄；
  Dev.txt 依慣例附追記而不塗改歷史。
* **未變**：Registry **466**、O1 冪等半邊未完成、O2 仍紅、MoonBit 側未動、未 push。

> **2026-11-11 合併註記**：本節及前述十..十六（本地輪次）與遠端 2026-11-10 的 S1–T4 重構工作報告併存。遠端段落原編號「十..十五」，合併後順延為「十七..二十二」；本地〔作者〕與遠端〔遠端〕的數字皆按當日實測記錄，兩側均未在合併截面上重跑驗證。

## 十七、2026-11-10 工作報告：構造性泛代數自主類型論 × 雙重否定核預層模板 × 全譜立方結構與 64-Bit SWAR 退化樹

### 17.1 What changed（變更範圍與行數）

1. **第四聯邦 `topos/`（+1 檔，`750` 行）**：新增 `topos/double_negation_alexandrov.mbt`，實作篩格 Heyting 否定 `sieve_heyting_neg`、雙重否定核 `sieve_double_negation`（`j(x)=¬¬x`）、`O(|S|·|Mor(C)|)` 精確 co-Heyting 差 `sieve_coheyting_sub`（`(S ⇐ T) = ↓(S \ T)`）、餘否定 `~A` 與拓撲邊界 `∂A = A ∧ ~A`、Lawvere–Tierney 核 `double_negation_lt_operator` 與反射布林層景 `double_negation_sheaf_site`、算子奇異譜共振偵測 `operator_singular_spectrum_fp`、亞歷山德羅夫空間 `AlexandrovSpace`（`PSh(P) ≃ Sh(X_P, O_Alex(P))`）以及 `ChuSpace` 萬有自對偶。
2. **第八聯邦 `accel/`（+1 檔，`464` 行）**：新增 `accel/cubical_degeneracy_swar.mbt`，實作 64 位元無分支立方蝴蝶面萃取 `cube64_extract_face_swar`、退化插入 `cube64_insert_degeneracy_swar`、軸退化位元遮罩 `cube64_degeneracy_mask`、`O(1)` 配對退化遞推 `cube64_pair_degeneracy_o1`（`deg(pair(A,B)) = (deg(A) & deg(B)) | ((A == B) << n)`）、整係數 Moore 交錯邊界鏈 `cube64_alternating_boundary_zchain`、雙向面修剪 `cube64_bidirectional_face_prune` 與通過 W3C 瀏覽器基線審計之 `wgsl_kernel_cubical_degeneracy_prune`（不變動既有 7 核 `webgpu_frontier_kernel_suite` 計數）。
3. **第九聯邦 `meta/core/`（+1 檔 `546` 行 + 重生 `laws.mbt` 與 `lean/labels/moonbit-labels.md`）**：新增 `meta/core/malcev_chu.mbt`，實作等價關係併閉包、瑪爾切夫三元多態、核同餘與商類，並登記 5 個 `law_malcev_*` 函式（共 **+20 條定律**，`cmd/metatheory` 由 `485/485` 升至 **`505/505`**，標籤清單 `408` 互異、`139` 族）。
4. **第一聯邦新子套件 `cubical/autonomy/`（Layer 5，5 個 `.mbt` 共 `2,645` 行 + 9 節 `README.md` `85` 行）**：
   * `malcev_universal_algebra.mbt`（`728` 行）：`UniversalAlgebra`、並查集同餘閉包 `generate_congruence`、商代數與第一同構定理、瑪爾切夫一步同餘可換 `θ∘ψ=ψ∘θ=θ∨ψ`、吸收零 vs 點化零二分定理、`ℤ/6ℤ ≅ ℤ/2ℤ × ℤ/3ℤ` Zappa–Szép 中國剩餘分解、Pol–Inv 伽羅瓦對偶與 Lawvere 有限積理論範疇化。
   * `affine_bide_morgan_cubical.mbt`（`718` 行）：區間代入三體系分類（`PureBchAffine` / `InvolutiveAffine` / `DeMorganCartesian`）、無連接 2D `dcube_open_box` 在 `S¹` HIT 與 `ua(not)` 上的仿射 Kan 計算、雙德摩根立方集與超八面體群 `B₃`（`48` 個帶號立方對稱）、變長 Moore 自由路徑嚴格結合單子與 Stasheff `K₃/K₄` 相干橋、內蘊 `∞`-群胚四重刻畫與單值圓周覆蓋瑪爾切夫繞數公式 `w(p_Kan(a,b,c)) = a - b + c`。
   * `degeneracy_tree_pruning.mbt`（`648` 行）：`CubicalDegeneracyTree` 即時折疊與 SWAR 遮罩同構、正規化 `5` 維立方交錯面微分 `∂₄ ∘ ∂₅ = 0` 與 `I³` Hodge Betti 譜 `[1,0,0,0]`、基於 `@face_bdd` ROBDD 面蘊含與 `DTermInterner` 的雙向立方範式修剪（經 `@kernel.conv_at_under_face` 核驗面下定義等價）。
   * `validity_presheaf_gluing.mbt`（`339` 行）與 `autonomy_audit.mbt`（`212` 行）：Kripke–Joyal 類型有效性結構、雙重否定核預層黏合、14 類範疇組合管線與 14 欄位總驗報告 `CubicalAutonomyMasterReport`。
5. **架構、根門面與頂點橋接**：更新 `architecture.json`（`44 → 45` 套件、`53 → 54` 元件）、根 `moon.pkg`／`facade.mbt`／`spec.mbt`（+4 條規格登記，符號全倉唯一）／`verify.mbt`（`129/129 → 132/132`）、新增 `bridge/malcev_presheaf_autonomy_bridge.mbt`（`58` 行，保持 `47/47` 歷史證書不動）並接線 `cmd/showcase/main.mbt`。

### 17.2 Why（不變式與數學定理）

* **吸收零元與點化零元在瑪爾切夫多態下的結構二分**：在具備雙邊吸收零元 `0·x=0=x·0` 且冪等的二元代數（如 De Morgan 區間 `(I, ∧, 0)`）上，任何保持該運算的瑪爾切夫多態必使載體塌縮為單點（`0 = 0·x = p(0,0,1)·p(x,x,x) = p(0·x, 0·x, 1·x) = p(0,0,x) = x`）；反之在具備中性零元 `e+x=x=x+e` 的點化代數上，相容瑪爾切夫多態由 Eckmann–Hilton 論證強制誘導唯一阿貝爾群結構 `x +_p y = p(x, e, y)`。這解釋了為何立方型別論中群胚結構住在纖維路徑空間 `Path_A(x,y)`（Kan 堆算子 `p_Kan(f,g,h) = f · g⁻¹ · h`）而非區間連接半格本身。
* **可信核心邊界不鬆動**：`cubical/kernel` 未做任何破壞封裝的修改；`cubical/autonomy` 嚴格位於 Layer 5，透過公開 `CheckedDCube`、`conv_at`、`conv_at_under_face` 與 `@homotopy.circle_encode_value`（單值性 `ua(succ)` 覆蓋傳輸）驗證高階立方路徑等價。

### 17.3 How verified（Tier A / B / C 實測數據）

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

### 17.4 What is still open（已知邊界）

* `topos/double_negation_alexandrov.mbt` 與 `cubical/autonomy/malcev_universal_algebra.mbt` 的一階普遍檢查在有限載體與有限景上逐點窮舉（如 `|A| ≤ 8`、`|Mor(C)| ≤ 16`）；無窮載體泛代數需透過自由項代數商（QIIT）與局部有限引理歸約。
* Lean 側 `lean/` 鏡射目錄仍維持遷移前凍結狀態，尚未鏡射本輪新增之 20 條 `law_malcev_*` 定律（標籤已同步寫入 `lean/labels/moonbit-labels.md`）。

---

## 十八、2026-11-10 工作報告（第二輪）：全體 54 項高階立方結構完足落地 × 26 運算動詞 × 14 範疇組合交互圖譜

### 18.1 What changed（變更範圍與行數）

1. **第一聯邦新子套件 `cubical/structures/`（Package Layer 6 / Component Layer 10，6 個 `.mbt` 共 `4,374` 行 + 9 節 `README.md` `88` 行）**：
   * `swan_id_and_free_path_fibration.mbt`：Swan/CCHM 常數範圍相等類型 `SwanIdValue`（開放中性變數 `DNVar(0)` 上嚴格定義 `J_Id(C, d, refl_x) ≡ d` vs 普通 `Path` 滯留中性 `coe` 之分離定理，以及單例可縮誘導 `Id ≃ Path`）、自由路徑空間 `ev₀`／`ev₀₁` Kan 纖維化截面、全體 `65,536` 個布林 `4`-立方體 `O(1)` SWAR Eilenberg–Zilber 規範退化分裂（層計數 `[2, 8, 60, 872, 64594]` 全數無碰撞往返）、異質合成 `comp ≡ hcomp ∘ coe` 雙演算法對帳，以及無對合純 Kan 2D 開盒逆路徑與對合逆 `λi.lp(1-i)` 的 `3D` 開盒立方同倫（`I³ → S¹` 全 `5` 面與 `10` 條交稜經 `@kernel.dcube_box_fill_verified` 核驗）。
   * `affine_bidirectional_focusing.mbt`：帶資源重數向量 `u ∈ {0, 1, ω}ⁿ` 之仿射／德摩根雙向立方類型檢查器（含 Bellman–Ford 宇宙多態層級約束環偵測、`Π` 蘊涵／全稱角色分類、`PathP`、`Glue`/`unglue`、`hcomp` 邊界系統）與極性聚焦證明搜尋引擎 `LJF`（消除 `5 → 1` 交錯排列爆炸並保持完備可靠）。
   * `functorial_poly_signatures_sip.mbt`：多項式容器函子 `PolyFunctor`、米田自然變換計數（`9` 個規範居留元）、Reynolds 二元關係提升與 Wadler 多態自由定理、依賴簽名鑽石推出並查集共融合併、立方結構恆等原則 SIP（經 `ua(not)` 將 `(Bool, ⊕, false)` 計算傳輸為 `(Bool, ↔, true)`）與宇宙累積提升往返。
   * `covering_space_pushout_torus.mbt`：一般離散覆蓋空間唯一路徑／2-胞腔同倫提升、聯動 `@sym.PermGroup` 驗證非阿貝爾群 `S₃` 六子群完整伽羅瓦覆蓋對應（正規子群 Deck 群階 `[6, 2, 1]` vs 非正規 `[1, 1, 1]`）、透鏡空間覆蓋指數整除分解、`T²` vs `S¹ ∨ S¹` 萬有覆蓋交換子升騰判準，以及基於整數行列初等變換 Smith 正規形的整係數同調（`Susp(S¹)` `[1,0,1]`、`T²` `[1,2,1]`、`RP²` 二階撓率 `[2]`）。
   * `type_reconstruction_repair_reflection.mbt`：聯動 `@elaborator.hou_unify` 之高階合一隱式動機重構、異質端點自動插入 `coe` 修補、正方形邊界 `5 → 3` 擬陣獨立基底縮減與開盒缺失頂蓋合成修補（`loop ⬝ loop²` 繞數 `+3`，角點矛盾邊界精確回報 `UnsolvableConflictPair(0, 1)`），以及自由群／阿貝爾群棧式線性時間內部計算反射。
   * `verb26_comp14_atlas.mbt`：全部 **54 項高階立方結構**逐項證書註冊表、**26 個運算動詞**索引、**14 種範疇組合模式**與 **14 條交互衍生定理**執行引擎 `verify_work4_all_54_structures_and_interactions()`。
2. **第九聯邦 `meta/core/`（+1 檔 `covering_focusing.mbt` + 重生 `laws.mbt` 與 `lean/labels/moonbit-labels.md`）**：新增 5 個 `law_*` 函式（`S₃` 覆蓋伽羅瓦對應、3D/4D Eilenberg–Zilber 退化分層與 Möbius 反演、極性聚焦位移伴隨 `↓ ⊣ ↑`、多項式米田雙射與 16 個二元關係自由定理、有限區間預層 Swan 嚴格 `J`），共 **+12 條定律**，`cmd/metatheory` 由 `505/505` 升至 **`517/517`**（`73` 個 `law_*` 函式，`420` 條互異，`151` 族）。
3. **架構、根門面與頂點橋接**：更新 `architecture.json`（`45 → 46` 套件、`54 → 55` 元件，`257 → 264` 個 `.mbt`、`169,004 → 173,957` 行）、根 `moon.pkg`／`facade.mbt`／`spec.mbt`（+5 條規格登記，共 `154` 條，符號全倉唯一）／`verify.mbt`（`132/132 → 135/135`）、`bridge/malcev_presheaf_autonomy_bridge.mbt` 與 `cmd/showcase/main.mbt`。

### 18.2 Why（不變式與數學定理）

* **Swan 嚴格 `J` 與普通立方 `Path` 在開放項上的計算分離**：在 CCHM 立方預層中，普通 `Path_A(x,y)` 的單例收縮依賴連接 `p(i ∧ j)`，對開放中性變數 `x₀ : S¹` 執行 `coe` 時無法消除非退化 HIT 消除器包裝而滯留中性項；Swan 的常數範圍配對 `(p, φ : Face)` 將「何時嚴格為常數路徑」顯式上同調化為面公式 `φ`，使 `refl_Id(x₀) = (λi.x₀, ⊤)` 在 `φ = ⊤` 分支直接短路歸約為基底項，同時由單例可縮保持同倫型 `Id_A(x,y) ≃ Path_A(x,y)`。
* **26 運算動詞 × 14 範疇組合的正交演算法生成**：例如「聚焦 × 博弈張量策略」導出極性 `LJF` 無搜尋規範階段樹（`5 → 1`），「分裂 × 單子分配律」導出 64-bit SWAR Eilenberg–Zilber 唯一退化因子化，「對偶化 × 伽羅瓦覆蓋纖維化」導出 `Aut_p(E_H) ≅ N_G(H)/H` 正規性判準，「修補 × 擬陣交換基底」導出冗餘邊界去重與開盒缺蓋合成。

### 18.3 How verified（Tier A / B / C 實測數據）

* **Tier B 單包即時測試（暫態 `test` 區塊已於驗證後立即移除）**：
  * `moon test cubical/structures --target wasm-gc`（`1/1` passed，`1.6s`）：`54/54` 結構證書、`26/26` 動詞、`14/14` 組合模式、`14/14` 交互定理全數 `true`，`[2, 8, 60, 872, 64594]` 全 65,536 個 4-立方體唯一往返、聚焦 `5 → 1`、`S₃` Deck 群 `[6, 2, 1]` vs `[1, 1, 1]`、`RP²` 撓率 `[2]`、開盒修補繞數 `+3`。
* **Tier A & Tier C 全倉閘門（不使用 `--release`）**：
  * `moon info --target wasm-gc && moon fmt`、`moon check --deny-warn --target wasm-gc`（0 warnings / 0 errors）、`moon build --target wasm-gc`（Finished）。
  * `python3 tools/arch_check.py`：`architecture ok: 9 federations + unification apex, 46 packages, 55 components, 264 .mbt files, 173957 .mbt lines`。
  * `moon run cmd/metatheory --target wasm-gc`：`通過 517 / 517 定律`；`python3 tools/gen_labels.py`：`517 條、420 條互異、151 族`。
  * `moon run cmd/main --target wasm-gc`：`passed 135/135`。
  * `moon run cmd/showcase --target wasm-gc`：`47/47 certificates passed`、`Full-Spectrum Cubical Structures × 26 Verbs × 14 Compositions: structures=54/54, verbs=26/26, patterns=14/14, interactions=14/14, focus=5->1, ok=true`。

### 18.4 What is still open（已知邊界）

* 整係數胞腔同調與覆蓋空間伽羅瓦對應作用於有限生成 CW 2-骨架與有限商基本群（如 `ℤ/nℤ`、`S₃`）；對自由積無限覆蓋（如 `S¹ ∨ S¹` 萬有覆蓋樹 `F₂`）採有界字長截斷升騰判定。
* Lean 側 `lean/` 鏡射目錄維持凍結狀態，新增之 12 條 `covering_focusing.mbt` 定律已同步登記至 `lean/labels/moonbit-labels.md`。

---

## 十九、2026-11-10 工作報告（第三輪重構 `S1–S4`）：F4 (`topos`) × F7 (`discovery`) × F9 (`meta`) × `L0 accel/swar` × `K₉ = 36/36` 星稜柱大一統

### 19.1 架構、配置與演算法變更明細

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

## 二十、2026-11-10 工作報告（第四輪重構 `R1–R4`）：F1 (`cubical`) × F5 (`scheme`) × F8 (`accel`) 縱向底層下沉、自由 De Morgan／CCHM 語義與 F4 Gröbner 三元合流

### 20.1 架構、配置與演算法變更明細

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

### 20.2 全倉 59 元件分層配置矩陣（Component Layers `L0–L14`）

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

## 二十一、第三輪重構工作報告（F2 `symlib` × F3 `semiring` × F6 `gcd`+`condensed` 縱向升級 `T1–T4`）

### 21.1 階段變更與演算法定錨明細

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

## 二十二、全倉深度健康檢查、除錯、去重、減債與死碼清理報告（2026-11-10）

### 22.1 掃描器盲區升級（`tools/health_scan.py` v2）
* 補強原版健檢腳本四項盲區：(1) 支援泛型 `fn[...]` 與限定方法 `Type::method` 剖析（掃描總數達 **`5,745` 個函式／方法**）；(2) 剝離 `//` 註解與字串字面量但**精確保留 MoonBit `\{ ... }` 字串插值表達式**，並排除 `reexport_*.mbt` 與 `using @pkg { ... }` 轉發計數造成的假陽性存活；(3) 新增無引用 `struct`/`enum` 型別與空殼列舉 `enum Foo {}` 偵測；(4) 改對剝離簽名後之純函式體計算雜湊，抓出改名複製貼上。

### 22.2 實質臭蟲修復（7 處）
1. **`symlib/fincat.mbt` (`cat_thin`)**：原版未檢查 `nobj >= 0` 且未對輸入生成箭頭取傳遞閉包，傳入非閉合生成關係（如 `[(0,1),(1,2)]`）即在 `idx.get(...).unwrap()` 崩潰；改以平坦 `O(1)` 陣列索引取代 `Map` 並補上 Roy–Warshall 自反傳遞閉包（對已閉合輸入保持完全相同的態射編號順序，徹底消除 `.unwrap()`）。
2. **`symlib/core/action.mbt` (`FinAction::on_edges`)**：將 `idx.get(...).unwrap()` 改為明確邊保持不變量檢查，並消除 `FinAction::derive` 內 `Pairs`/`Edges` 分支與 `pairs_img`/`edges_img` 之重複實作。
3. **`semiring/algebra/lattice_instances.mbt` (`CyclicSet`)**：修正負整數代表元 `x < 0` 下 `x % m` 產生負位移的錯誤（統一正規化為 `(x % m + m) % m`），並將手寫迴圈 `popcount64` 升級為硬體 `popcnt()` 指令。
4. **IEEE-754 `NaN` 比較反轉修復（4 檔）**：修補 `cubical/face_bdd/interval.mbt`（`dmin`/`dmax` 傳播 `NaN`，`interval_laws_hold` 改用 `!(... < eps)` 防止 `NaN >= eps == false` 誤判通過）、`cubical/homotopy/sphere_homotopy.mbt`（`hopf_vector_close`、`check_hopf_numeric`）、`bridge/graph_symmetry.mbt` 與 `bridge/rotation_axis_bridge.mbt`（拒絕 `NaN`/`Inf`/負容差）。

### 22.3 空殼／無引用型別消除、跨檔去重與死碼清零
* **消除全倉唯一空殼列舉與孤立型別**：將 `cubical/kernel/schema_universe_poly.mbt` 的空殼 `pub enum DLevelDecl {}` 補齊為真實三元餘積 `DLevelDeclInductive | DLevelDeclHit | DLevelDeclTerm` 與 `level_decl_validate` 並接入 `check_level_polymorphic_declarations`；補齊 `topos/site/logic_classifying_categorify.mbt` 之 `model_satisfies_theory` 並接入分類 Topos 泛性質驗證；為 `symlib/cat.mbt` 之 `FinSet` 補齊 `FinSet::id` 並接入冪集自然性驗證；刪除完全無操作之孤立結構 `AbelianPresheafQ` 與殘留懸空註解。
* **去重（7 組）**：合併 `symlib/yoneda.mbt` 中 78 行雙重貼上的 `comma_down`/`comma_up` 為共用 `comma_cat_build`；合併 `cubical/homotopy/sphere_classification.mbt` 的 `integer_succ_value`/`integer_pred_value` 為 `integer_step_value`；合併 `cubical/store` 的 `compiled_module_env_find`/`hot_load_find` 及 `bw_tube_terms`/`bw_face_terms`/`br_tube_terms`/`br_face_terms`；合併 `algebra` 的 `biquad_is_zero`/`multiquad_is_zero` 與 `jacobi_*_max_width`；將 `meta/iit` 的 `ie_find` 統一委派至 `@core.uf_find_halving`。
* **死碼清零與未驗 API 接線**：刪除舊版已被 `geom_sum_group` 取代且含無用局部變數 `mut p` 的 `geom_sum`、`star_by_iteration`、`check_coherence_angle_elimination`、`to_report_string`、`ints_to_string`、`key_lut_pairs`、`random_ints`、`gset_canon_key`、`gset_orbit_sizes` 等未引用冗餘包裝（同步 `reexport_*.mbt` 與 `.mbti`）；並將 `cchm_face_le`、`sieve64_generate`/`sieve64_pullback`、`cat_slice`、`presheaf_equalizer`、`scheme_morphism_compose`、`affine_fiber_product`、`mpoly_eval`、`csr_mul`、`Dfa::accepts`、`trop_assignment`、`UniPoly::argmin_at`、`hom_setmat`/`smat_plus`、`isomorphism_dual`、`coinduced_gset` 等核心演算法全數接入正式定理與 `wasm-gc` 驗證套件。
* **全目標驗證結果**：`moon check --deny-warn` 於 **`wasm-gc`、`wasm`、`js`、`native` 四大目標全數 `0` warnings / `0` errors**；`arch_check.py` 通過（`52` 套件、`61` 元件、`282` 檔、`182,929` 行）；`health_scan.py` 達成 **`5,745` 函式／方法：`0` 死碼、`0` 無引用型別、`0` 空殼列舉、`0` 完全重複**；`cmd/metatheory` **`545/545`**、`cmd/main` **`137/137`**、`cmd/showcase` **`47/47 + K₉=36/36 + 雙三元橋`**、`cmd/symdemo`／`cmd/symbench`／`cmd/semiringreport` 全數通過。

---

## 十五、K10 真正跨聯邦橋建設計劃與完成實錄（2026-11-12）

### 15.1 起點與審計結論

- 工具鏈：`moon 0.1.20261104`、`moonc v0.10.20+65efd5b93`；`moon update` 後 `moonbitlang/async@0.22.5` 解析成功。
-  inherited blocker 已修復：`cubical/kernel/nbe_dep.mbt` 恢復 `kernel_eval_closed_peano`（`force_value(deval_dim(...))` + fuel 100000 解碼 `DVZeroNat/DVSucc`）。Tier A 首次全綠：`moon check --deny-warn --target wasm-gc`、`moon build --target wasm-gc`、`python3 tools/arch_check.py` 皆 exit 0。未改 `facade.mbt` / `verify.mbt` / root `.mbti`。
- 審計發現「名義聯邦」弱橋（純布林合取或兩獨立報告拼在一起）：`K8-22`、`K8-24`、`K8-27`、`K9-29`、`K9-31`、`K9-34`。本輪以具體數學構造替換，不再用 `a_ok && b_ok` 當橋定理。
- 第十聯邦 `ualg` 已在 `architecture.json` 但不在 bridge 依賴圖；本輪把 `ualg-core/site/demorgan/cube` 接入 bridge，新增 9 條邊 `K10-37..K10-45`，使完全圖從 `K9=36` 升為 `K10=45`。

### 15.2 新增 9 條 K10 邊（每條都是構造＋定理＋量化見證＋負控制）

| ID | 邊 | 構造 | 定理/演算法 | 負控制 |
|---|---|---|---|---|
| K10-37 | Ualg×Cubical | DNF 面公式 → 雙軌 BDD（變數 `2i,2i+1`，valid mask 禁止 `p_i∧q_i`，允許 `p_i=q_i=0` 表自由座標） | `𝔽(2)` 48 個子複形與 CCHM cofibration lattice 忠實同構；`face_exists/face_forall` = 三值 valid domain 上的 Boolean ∃/∀；∃⊣弱化⊣∀ 全部 48×2 對帳 | `x∨¬x ≠ ⊤` 在面格；Boolean 反射（只禁 both-1 且把 free 當 endpoint）會塌縮，與面格區分 |
| K10-38 | Ualg×Symlib | `mor_group` B₂ 8 個代換在 48 個子複形上誘導置換 → `PermGroup::new` / `gset_points` / `mark_vector` / `table_of_marks` | Burnside 軌道數 15；marks 表與 formula 表逐項相等；軌道–穩定子 `|orb|·|stab|=8` | 平凡群作用有 48 軌道，非 B₂ 的 15 |
| K10-39 | Ualg×Semiring | 同餘生成 `Cg(R)` = 「Boolean SWAR Kleene star ∘ 基本平移像」的最小不動點（等價閉包與平移像交替迭代至穩定） | Mal'cev 引理的半環演算法：Freese `cg` == Boolean-Kleene 分割，對 Zn6/Chain3/M3/N5/𝟚/×Zn2² 全部主同餘對帳 | Chain3 配對 (0,2) 的原始等價分割不是同餘；Kleene 閉包後才是 full |
| K10-40 | Ualg×Topos | `poset_cube(2)` → `cat_poset` → `SitePrecomp64`；頂物件 sieves ↔ 48 個開集 | Heyting implication/negation/¬¬、union/inter 在 `ualg/site` 與 `topos/site` Sieve64 逐對同構；子終層化 = 頂點閉包 | ∂□² 與 □² 的 ¬¬ 相同但子複形不同；¬¬ 不保併 |
| K10-41 | Ualg×Scheme | 立方子複形 K → 頂點 simplicial complex Δ_K（S 是面 iff 其張成最小立方 face 在 K）→ Stanley–Reisner 理想 | ∂□² 的 Δ 是 C₄：I=(x0x2,x1x3)，Hilbert 多項式 4t，degree 4，p_a=1，Betti [1,1]（β₁=1，去尾零）；□² 的 Δ 是 full simplex：I=0，Hilbert cubic，degree 1，p_a=0，Betti [1] | 邊界與填充的 SR 理想/Hilbert 多項式/Betti 皆不同 |
| K10-42 | Ualg×Condensed | 有限代數平移/自同構 f → `functional_matrix` → `rlim_zmat_endomorphism` | 置換 f：lim0 rank = 圈數 = χ_f 在 1 的根重數，lim1 torsion 空；一般平移：rank = dim ker(I−f) ≤ 代數重數，SNF torsion 給 cokernel | 整數自同態 3·I₂：χ(1)≠0（根重數 0）但 SNF 餘核 (Z/2)²，分離譜與逆極限不變量；有限 endofunction 的 I−f 恆無撓且 rank=圈數，故負控制须用一般整數矩陣 |
| K10-43 | Ualg×Discovery | 48 個 □² 子複形上 4 個謂詞（Betti=[1]、χ=1、¬¬-正則、full）→ `implication_lattice_build` SWAR bitplane | 蘊含格與最小反例由 bitplane 算出，與暴力枚舉逐項相等；P0⇒P1、P3⇒P2/P0；P2⇒P0、P0⇒P2 被反例否證 | 兩 opposite vertices（正則但 β0=2）；open box（無環但非正則） |
| K10-44 | Ualg×Accel | `cx_boundary_matrix` mod 2 → `gf2_bit_matrix_from_ints` → `gf2_rref_rank_u64` → Betti | torsion-free 立方複形上 GF2 SWAR rank == Q Bareiss rank == mod-p rank；full/boundary/open boxes/suspension/T²=(ΣS⁰)×(ΣS⁰)（n=4）/S²=∂□³ 對帳；T² β=[1,2,1]、S² β=[1,0,1] | 本輪例子無撓；不宣稱一般 torsion 複形 mod2==Q |
| K10-45 | Ualg×Meta | ualg 分割同餘 ↔ `meta/core` Boolean relation；`ua_quotient_classes`/`ua_kernel_congruence`/`ua_equiv_join_closure`/`ua_rel_comp`；Mal'cev term → `ua_is_malcev_op` + `ua_is_ternary_congruence` | 商投影核 == θ；同餘聯/複合兩路徑一致；Mal'cev 項保所有同餘 | 非 Mal'cev 運算 (x+y)%3 在 Chain3 上既不是 Mal'cev 也不保非 congruence 分割 [0,1,0]；投影運算保所有等價關係故不能用作負控制 |

### 15.3 替換 6 條弱橋

| ID | 新構造 |
|---|---|
| K8-22 | SWAR truth-word Boolean algebra → ROBDD：`popcount(face_truth_u64)=bdd_dag_sat_count`，and/or/not 與 BDD apply 逐 face 同態 |
| K8-24 | weighted digraph → `tropical_blocked_kleene_closure` == `closure_trop_swar` == `apsp_kleene` == `apsp_dijkstra`（非負權）；負環控制 `has_negative_cycle` |
| K8-27 | profinite bonding ZMat → `qmat_mul_ozaki2_crt` == `qmat_mul` == `zmat_mul`；`rlim_zmat_endomorphism` SNF 對帳 |
| K9-29 | meta/reflect simply typed Term → cubical DTerm compilation；closed Unit 項的 βη nf 兩邊一致（id/const/apply/η-redex） |
| K9-31 | unary definite Horn program → dependency graph Boolean Kleene star == `forward_least_model`；SLG tabling diamond hits；binary-body 負控制顯示 reachability 不足 |
| K9-34 | meta/instances Möbius patch glue/monodromy ↔ condensed sign endomorphism `rlim_zmat_endomorphism([-1])` torsion [2]；trivial +1 rank 1；零截面恆可黏 |

### 15.4 接線與驗收

1. `bridge/moon.pkg` + `architecture.json packages[bridge].depends_on` 同步加入 `ualg-core`(@ucommon)、`ualg-site`(@usite)、`ualg-demorgan`(@udm)、`ualg-cube`(@ucube)（exact-match）。
2. `FederationId` 加 `Ualg`；新增 `ten_federation_descriptors()`、`verify_k10_ualg_federation_bridges()`、`TenFederationUnificationReport`、`verify_k10_ten_federation_unification()`。
3. `cmd/showcase` 改印 10-fed / K10=45/45 / atlas=18；保留歷史 48 證書 ledger，新增獨立 K10 certificate；final guard 納入 `k10_rep.all_holds`。
4. 同步 `bridge/README.md`、`ualg/README.md`、`agent.md`、`readme.v2.md`、`architecture.json` apex 措辭、CI labels、三處 frozen "47-entry" 註解。
5. Tier A 每次編輯後跑；Tier B 只在 bridge 檔尾臨時 `test` + `moon test bridge --target wasm-gc --update` → 讀值 → 重跑 → 即刪；Tier C `moon info && moon fmt` + `.mbti` diff。不跑 inherited suites、不用 `--release`、不做 benchmark。
6. 完成後 commit + push，讓 CI global compile gate 跑。

### 15.6 完成狀態（本輪實作，全部 Tier A/B/C 綠）

- **接線完成**：`bridge/moon.pkg` + `architecture.json` 加入 `ualg-core/site/demorgan/cube`（@ucommon/@usite/@udm/@ucube）、`cubical-face-bdd`（@fb）、`cubical-kernel`（@kernel）；`FederationId` 加 `Ualg`（無 match site 需改）。
- **9 條構造性邊全部 holds=true**（`bridge/ualg_federation_constructions.mbt`）：K10-37 faces=48/48 faithful/order/quantifiers/adjunction=true、boundary≠top；K10-38 |B₂|=8 orbits=15=Burnside=ualg marks==formula orbit_stabilizer=true；K10-39 principal_pairs=45 Freese==Kleene=true；K10-40 opens=sieves=48 bijective/ops/sheafify=true join_failures=482；K10-41 boundary(dim=1,deg=4,genus=1,H(2)=8,β=[1,1]) full(dim=3,deg=1,genus=0,H(2)=10,β=[1])；K10-42 GL(2,2) 6/6 perm rank=cycles=root_mult，3·I₂ torsion=2 contrast=true；K10-43 samples=48 brute==SWAR strict=3 equiv=1 兩個極小反例；K10-44 complexes=11 Q==F2==SWAR T²β=[1,2,1] S²β=[1,0,1]；K10-45 congruences=22 relation/quotient_kernel/join/Mal'cev=true negative=true。
- **6 條弱橋替換全部 holds=true**（`bridge/structural_bridge_replacements.mbt`，`meta_k9_unification.mbt` 已改呼叫）：K8-22 16/16 faces truth/sat_count/homomorphism=true；K8-24 four_way=true negative_cycle=true；K8-27 small_triple=true big_crt==school_beyond2^53=true torsion6=true；K9-29 closed_terms=5/5 meta_nf==dep_nf η/open_rejected=true；K9-31 unary_facts=2/2 Kleene_reach=3/3 binary_body 負控制=true；K9-34 mobius obstruction/monodromy=true rlim(-1) torsion=[2] rlim(+1) rank=1 zero/trivial glue=true。
- **showcase 實跑通過**：`moon run cmd/showcase --target wasm-gc` exit 0，印出 10/10 聯邦、K10=45/45、ualg=9/9、6/6 替換、48/48 歷史證書、atlas=18/18、K9=36/36 歷史子圖、F7→F9→F4→F1 晉升=true、七支柱五元=true，final guard 無 abort。
- **與計劃的如實偏差**：K10-41 Betti 以 `cx_betti` 去尾零輸出 [1,1]（非 [1,0,1]）；K10-42 負控制改用一般整數自同態 3·I₂（有限 endofunction 的 I−f 恆無撓，無法產生 torsion 對照）；K10-44 T² 以 ΣS⁰×ΣS⁰（n=4）構造、S²=∂□³ β=[1,0,1]；K10-45 負控制改用 (x+y)%3（投影保所有等價關係，不能當負控制）。K10-39 閉包改为 Kleene star 與平移像交替最小不動點（單步 Kleene star 不足以生成同餘）。
- **Tier C**：`moon info --target wasm-gc && moon fmt` 已跑；`.mbti` 同步（bridge 新增 pub 介面、cubical/kernel 恢復 kernel_eval_closed_peano、meta/ualg 等 fmt 重排）。`moon check --deny-warn`、`moon build`、`arch_check.py` 全 exit 0。
- **文檔同步**：bridge/README、ualg/README（§7 未做橋接→已完成 K10）、agent.md、readme.v2.md、architecture.json apex、CI labels（631/167/139/48+K10）、三處 frozen 47-entry 註解→48-entry 歷史 ledger。

### 15.7 CI 紅燈修復（同輪續）

- **根因**：`cubical/kernel/nbe_dep.mbt::conv_at` 對 `DVCircleTy`/`DVTorusTy` 座標使用 Boolean 真值表判等 `dim_eq_sem`，使自由 De Morgan 區間的 `i∧¬i` 被誤判為端點，`loop(i∧¬i)` 塌縮到 `base`，導致 `cmd/main` 第 139 條「Kalman 雙軌自由 De Morgan 區間」負控制失敗（CI 唯一紅步）。
- **修復**：circle/torus 座標判等改用 `dim_eq_demorgan`；不更改定理陳述、不放寬負控制。臨時 inspect probe 定位後即刪。
- **驗收**：`cmd/main` 139/139、`cmd/metatheory` 631/631、`cmd/ualg` 167/167、`cmd/showcase` 48/48 + K₁₀=45/45 + ualg 9/9 + 替換 6/6 + atlas 18/18 + pentad true；check/build/arch_check/gen_laws/gen_labels 全綠。
- **文檔**：現行定律數同步 565→631、`law_*` 94→104、arch 318/199215→320/201027；CI label 同步。

### 15.5 前沿搜索（本輪）

- Stanley–Reisner / Hochster：squarefree monomial ideal ↔ simplicial complex，Betti 由 induced subcomplex homology 決定（arXiv:math/0410107；arXiv:2607.10639）。
- Knaster–Tarski / Horn immediate consequence：definite program least model = lfp(T_P)，finite unary case = reachability closure（Imperial College KR notes；arXiv:cs/9511102）。
- ¬¬-sheafification / cubical sets：Lawvere–Tierney ¬¬ nucleus，sheafification 是 left adjoint，subterminal case = vertex closure（Swan HoTTEST 2023；finite Alexandrov sheaf literature）。


---

## 十六、第二波減技術債：名義布林橋消除與文檔對齊（2026-11-12）

### 16.1 硬性原則（新增，適用所有聯邦邊）

一條邊嘅 `holds` **严禁**係兩個*互相獨立*嘅健康報告布林合取。每條邊必須：
1. 至少一個**兩結構相互作用而生嘅構造**（新定理／新算法）；
2. 量化見證（實際數字，唔係淨 true/false）；
3. **負控制**：將構造換成天真版本時必須失敗。
複合邊（同一對聯邦嘅多個構造性定理）容許，但必須明文列出子定理，不得退化為健康報告合取。

### 16.2 本輪消除嘅 7 條名義邊（`bridge/nominal_bridge_elimination.mbt`）

| 邊 | 舊名義式 | 新構造 | 負控制 |
|---|---|---|---|
| K5-02 | face_semiring && tropical | □³ 面格→Kleene 閉包==CCHM 序（729 對、兩算法）；冪零 Neumann 級數數 48=2³·3! 極大鏈 | 對稱化序塌縮＋star 發散 |
| K5-05 | graph_symmetry && free_category | Aut(C₄) Burnside 閉路軌道 census == 計數半環 tr((A\|Fix(g))^k) 平均 | (01)∉Aut、像不是路、5≠1 |
| K8-23 | \|S_3\|==6 && Δ−Δ==0 | S₃ 軸作用全 6561 張量、SWAR Det 逐點不變、Burnside 1485==DSU | 單項泛函非不變 |
| K8-26 | 2241 && atlas && 13 | rank≤1==Segre 仿射錐 129=1+(q−1)\|P¹\|³（scheme 導出） | rank2 det0 code12；rank3 det0 code93 |
| K8-28 | dkern && det_zero | SWAR bitplane 蘊含格==窮舉語義 25 對＋最小反例一致 | Det=0⇒rank≤1 否證；1-bit 篡改偵測 |
| K9-30 | meta_laws && \|Aut(C_4)\|==8 | 同餘閉包==軌道分割==rank_Q==Burnside | 刪生成元→4 類>2 類 |
| K9-33 | cauchy7 && 13 | Macaulay Bareiss rank==Gröbner Hilbert HF=[1,2,2,2] | 胖點 HF3 vs 約化 HF1 |

### 16.3 假陳述／外掛布林／死代碼修復

- **K7-17 假陳述**：舊版以 `Graph::cycle(5)` 冒稱 `Aut(K_4)`（10 vs 24），docstring 數字與代碼不符。新版改為 S₃ 軌道秩分層（秩軌道常值、orbits 1485、hist [1,40,860,584]、Σ|stab|=6·orbits、Σ|orb|·|stab|=6·6561、自由軌道 orbit–stabilizer＋穩定子封閉），負控制為 mode-0 flattening rank 軌道內 1≠2。
- **K6-15 外掛**：移除無關 `@exactalg` 旗標；改為 Laurent h⁰/h¹ == scheme O(0)，並跨 n=-4..3 驗 Serre 對偶與 Riemann–Roch；負控制 proper≠acyclic。
- **死參數**：`verify_k9_federation_bridges` / `verify_k10_ten_federation_bridges` 嘅 `accel_precomputed~`（只 `ignore()`）已移除，三個呼叫點同步。
- **死計算**：被替換邊遺留嘅 swar_dets/det_zero/s3_ord/chunk0/sub_zero/p2_f3/dkern_ok/c4_aut/malcev_ok/cauchy7_* 全數刪除。

### 16.4 接線、閘與驗收

- `cmd/showcase` 新增 Wave-2 (7/7) 段落，`wave2_ok == 7` 納入 K10 證書與 final guard。
- 實跑：showcase exit 0（48/48、10/10、K10=45/45、ualg 9/9、wave1 6/6、wave2 7/7、atlas 18/18、七支柱 true）。
- 文檔：ci.yml 565→631；全倉 321 .mbt / 202,287 行；agent.md bridge 22/9,554、showcase 221；bridge/README §2.1 逐邊記錄名義式→構造→負控制。

### 16.5 剩餘債（如實，未宣稱清零）

- K5-10 複合邊（三個構造性合取）已透明化但未拆分；拆分需證書 ledger 48→50。
- K9-35 見證字串偏薄；K9-32 欠負控制（填充三角形 H¹=0）。下一輪補。
