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
   - 跨聯邦重大變更完成後，可按需執行 `moon run --release cmd/showcase --target wasm-gc`（`46/46` 大一統證書）或 `moon run --release cmd/main --target wasm-gc`（`129/129` 定理總表）做端到端驗收。

---

## 二、宏觀架構治理（七聯邦雙V形＋星稜柱 DAG）

全倉受 `architecture.json` 與 `tools/arch_check.py` 嚴格守門，遵循單向無環依賴（DAG）：

- **Layer 0（下頂點 `V₁`）**：`gcd`（五域泛消元基底：`F_p` RREF、`ℤ` HNF/SNF、CRT、Grassmann 子空間交和對偶、自由群約化）。零外部業務依賴，禁止各聯邦重寫重複的矩陣消元或 GCD。
- **Layers 1–2（發散雙翼）**：`algebra`、`hostfs`、`symlib`、`semiring/*`、`topos`、`scheme`、`tensor`。
- **Layer 3（中央 `X` 形交疊樞紐）**：`condensed`（凝聚高階結構、Steenrod–Adams 上同調、雜湊鏈守恆律賬本）。
- **Layer 4（上翼收斂與猜想發現迴圈）**：`cubical` 核心層與 `conjecture`（6 大演化轉移定律、5 大認識論透鏡、Lakatos 十二猜想圖譜 `CONJ-01..12`）。
- **Layers 5–6（上頂點 `V₂`）**：`bridge`（$K_7 = 21/21$ 跨聯邦雙邊橋）與 `cmd/*` 執行入口。**任何下層聯邦絕對禁止反向匯入 `bridge`**。

---

## 三、`cubical` 根目錄（77 檔、`81.7k` 行）四波段穩健重構總藍圖

### 3.1 重構核心原則（SCC-Preserving Modularization）
1. **保護強連通互遞迴核心（不強拆 SCC）**：
   依頂層符號 Tarjan 強連通分量（SCC）實證，`dependent-kernel` 的互遞迴核心（`NbE 求值 ↔ Kan 填充 ↔ Glue 等價 ↔ 歸納/HIT Schema`）必須完整保留在單一 `cubical/kernel` 套件內，避免跨包解環引入函數指標間接層或被迫改為 `pub(all)` 破壞核心封裝。
2. **建立編譯器級可信核心（Trusted Kernel）**：
   外圍子系統（布林 BDD、厄米特投影、有限立方、合成同倫、雙向精緻化／高階合一、模組持久化與 BFT 熱載入）與核心之間**零循環依賴**，應拆為獨立子套件，使 `cubical/kernel` 內部的私有 `DValue`／`CheckedLine` 構造子受編譯器強制保護，不再被外圍模組直接穿透。
3. **根除編年史命名債（No `phase*` Filenames）**：
   全面廢除以歷史期數命名的檔案（如 `phase15_*`、`phase21_*`、`schema_phase9.mbt`、`equivalence_phase9/10.mbt`），一律按**數學結構或系統職責**命名，並將超過 `2,500` 行的巨型檔案按子主題拆分為高內聚模組。
4. **薄門面無縫相容（Thin Root Facade）**：
   外部套件（`bridge`、`cmd/main`、`cmd/showcase`）實際僅引用根套件 **85 個公開符號**。頂層 `root` 最終收斂為薄門面（透過 `pub using` 重導出所需符號＋`verify.mbt`），確保跨聯邦橋接 **100% 零破壞平滑演進**。

### 3.2 目標子套件拓撲結構

```text
                       root（薄門面 Facade + verify.mbt 總控）
          ┌──────────────┼───────────────────┐
          ▼              ▼                   ▼
  cubical/homotopy   cubical/store   cubical/elaborator
  (球面/單值性/Kn/   (二進位模組/WAL/  (雙向精緻化/Huet HOU/
   BM/Brunerie/HIT)   Ed25519 BFT/     高階匹配/Goldfarb)
          │           Tarjan 熱載入)          │
          └──────────────┴─────────┬─────────┘
                                   ▼
                            cubical/kernel  ◄── 可信核心（封裝私有 DValue / CheckedLine）
                       (NbE + Kan + Glue + DSystem + 歸納/HIT Schema + ε₀ 序數)
                                   │
                       ┌───────────┴───────────┐
                       ▼                       ▼
                cubical/finite          cubical/hermitian
             (η-NbE / Wiring /         (複矩陣 / 投影 P²=P=P† /
              有限 Glue / CCC)          開盒剪枝 / 精確代數證書影子)
                       └───────────┬───────────┘
                                   ▼
                           cubical/face_bdd
                  (區間 Dir/Face · ROBDD DAG · Watched CDCL/LRAT · 割寬 #SAT)
```

### 3.3 分波穩健推進路線（可分 2～4 次獨立提交完成，每波必過全套靜態與建置門檻）

- **Wave 1（✅ 已完成）：全倉去編年史化、大雜燴拆解與層號正序（同套件內零風險整備）**
  - 已拆解跨領域大雜燴檔 `phase21_homotopy_hou_bft.mbt` 與 `phase21_schema_dsystem_bdd.mbt` 為純領域模組（`bdd_cutwidth.mbt`、`ordinal_mahlo.mbt`、`dsystem_sheaf_reify.mbt`、`higher_coherence_k6.mbt`、`hou_goldfarb.mbt`、`module_bft_mvcc.mbt` 與 `mahlo_k6_bft_laws.mbt`），並將 `kan_ast.mbt` 中純 `Dim`/`Face` 語義輔助下沉至 `bdd.mbt`。
  - 已將 `equivalence_phase9/10.mbt` 合併為 `adjoint_equivalence.mbt`；將巨檔 `schema_phase9.mbt`（`5.7k` 行）拆分為 `schema_universe_poly.mbt`、`schema_inductive_recursive.mbt`、`schema_open_ir.mbt`（均 `< 2,050` 行）；將 `hou_elaborator.mbt`（`4.7k` 行）拆分為 `elaborator_bidir.mbt` 與 `hou_unify_stream.mbt`；摺疊移除空殼 `hostfs_imports.mbt` 與 `algebra_imports.mbt`；全倉根目錄與 `algebra/` 所有 `*phase*` 檔案已 100% 正名清零。
  - 已移除臨時觀察者元件 `phase21-breakthroughs` 與 `hostfs-imports`，將 `laws`（`L8`）與 `registry`（`L9`）置於所有核心與前端元件之上，消除全部反向層依賴（`pkg.generated.mbti` 位元組零差異驗證通過）。
- **Wave 2（✅ 已完成）：底層基礎三子套件抽離（`cubical/face_bdd`、`cubical/finite`、`cubical/hermitian`）**
  - 已按嚴格自底向上無環拓撲抽離三個獨立實體套件：`cubical/face_bdd`（`L0`，5 檔 `6,211` 行，零業務依賴，單包 `moon test` 實測 `0.38s`）、`cubical/finite`（`L1`，4 檔 `1,828` 行，僅依賴 `face_bdd`，零浮點／代數耦合，單包實測 `0.22s`）、`cubical/hermitian`（`L2`，9 檔 `3,199` 行，整合複矩陣投影、Karoubi／子空間 Glue 模型與精確代數證書影子，單包實測 `0.57s`）。
  - 內部不變量結構體（如 `BddManager`、`Wiring`、`Equiv`、`Complex`、`CMat`、`ProjectorCertificate` 等）維持唯讀 `pub struct` 封裝；頂層 `facade.mbt` 以 `pub using` 無縫轉發，`@bridge` 與四個 Wasm-GC 執行檔零破壞通過。
- **Wave 3（✅ 已完成）：可信依賴核心子套件獨立封裝（`cubical/kernel`）**
  - 已按自底向上無環拓撲將互遞迴核心 `dependent-kernel` ＋ `dependent-kan-lines`（20 檔 `30,899` 行）實體抽離為 `cubical/kernel`，全包僅依賴 `cubical/face_bdd` 與 `cubical/finite`（**零浮點、零有理數代數、零儲存／前端耦合**），單包 `moon test cubical/kernel` 實測僅 **`0.95s`**（`< 1 秒`！）。
  - 核心內部不變量載體（`CheckedLine`、`CheckedDCube`、`CheckedSystem`、`SchemaRegistry`、`DClosure`、`DTermInterner`、`PositivityReport` 等）由編譯器強制保護為唯讀 `pub struct`，任何外圍套件均無法繞過核心檢驗器直接偽造。
- **Wave 4（最終波・下一步）：上層三大子套件抽離與薄門面收斂（`cubical/elaborator` ＋ `cubical/store` ＋ `cubical/homotopy`）**
  - 在 `cubical/kernel` 之上平行抽離雙向精緻化與高階合一（`cubical/elaborator`）、模組持久化與 Ed25519 BFT／MVCC 熱載入（`cubical/store`）及合成同倫（`cubical/homotopy`），使頂層 `root` 最終收斂為極薄門面與定理總表。

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
