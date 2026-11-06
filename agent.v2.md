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
   - 跨聯邦重大變更完成後，可按需執行 `moon run --release cmd/showcase --target wasm-gc`（`47/47` 大一統證書）或 `moon run --release cmd/main --target wasm-gc`（`129/129` 定理總表）或 `moon run --release cmd/metatheory --target wasm-gc`（第九聯邦型別論機制定律逐條重算）做端到端驗收。

---

## 二、宏觀架構治理（九聯邦雙V形＋星稜柱＋硬體加速 DAG）

全倉受 `architecture.json` 與 `tools/arch_check.py` 嚴格守門，遵循單向無環依賴（DAG，共 `39` 套件、`48` 元件）：

- **Layer 0（下頂點 `V₁`）**：`gcd`（五域泛消元基底：`F_p` RREF、`ℤ` HNF/SNF、CRT、Grassmann 子空間交和對偶、自由群約化）與 `cubical/face_bdd`。零外部業務依賴，禁止各聯邦重寫重複的矩陣消元或 GCD。
- **Layers 1–3（發散雙翼）**：`algebra`、`hostfs`、`symlib`、`semiring/*`、`topos`、`scheme`、`tensor`。
- **Layer 4（中央 `X` 形交疊樞紐與硬體加速引擎）**：
  - `condensed`：凝聚高階結構、Steenrod–Adams 上同調、雜湊鏈守恆律賬本；
  - `accel`：CPU 64 位 SWAR（M4RI `GF(2)`、雙軌 `GF(3)` 位切片、64 路 `Face` `#SAT`）、Ozaki Scheme II `INT8→INT32` CRT 矩陣乘、32 位 RNS Stockham 自動排序 NTT、Scanbox 解耦回看掃描、三相共享記憶體熱帶閉包、HVM2 扁平競技場交互組合子與 W3C 瀏覽器免費 WebGPU（`WGSL`）計算著色器。
- **Layers 5–6（上翼收斂與猜想發現迴圈）**：`cubical` 上層子套件與 `conjecture`（6 大演化轉移定律、5 大認識論透鏡、Lakatos 十二猜想圖譜 `CONJ-01..12`）。
- **Layers 7–8（上頂點 `V₂`）**：`bridge`（$K_7 = 21/21$ 跨聯邦雙邊橋＋`@accel` 硬體加速逐位等價證書）與 `cmd/*` 執行入口。**任何下層聯邦絕對禁止反向匯入 `bridge`**。

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

計量：`cmd/metatheory` **455 → 485**（+30 條能力定律，`law_*` 函式 56 → **63**）；標籤分佈 core 115（互異 102）／instances 147（144）／iit 164（87）／reflect 59（55）；`cmd/main` **129/129**；`cmd/showcase` **47/47**；`arch_check` → 44 套件、53 元件、**248** `.mbt`、**164,346** 行。

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
python3 tools/arch_check.py                 # architecture ok: 44 packages, 53 components, 248 .mbt, 164346 lines
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
