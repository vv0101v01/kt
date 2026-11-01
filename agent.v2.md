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
   - 跨聯邦重大變更完成後，可按需執行 `moon run --release cmd/showcase --target wasm-gc`（`47/47` 大一統證書）或 `moon run --release cmd/main --target wasm-gc`（`129/129` 定理總表）做端到端驗收。

---

## 二、宏觀架構治理（八聯邦雙V形＋星稜柱＋硬體加速 DAG）

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
   頂層 `facade.mbt` 僅以 `pub using` 重導出跨聯邦 `@bridge` 與執行檔實際使用的精選符號（根套件 `pkg.generated.mbti` 由重構前逾 `4,300` 行精簡 `90%` 至 `452` 行），內部定律檢驗匯入一律保持 `using` 私有化。

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

