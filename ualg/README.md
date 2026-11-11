# `ualg/` — 第十聯邦：構造性泛代數 × 預層模板 × De Morgan 立方體

> **架構位置**：`architecture.json` 的聯邦 `ualg`，5 個套件——`ualg-core`（L0）、`ualg-site`（L0）、
> `ualg-demorgan`（L1）、`ualg-cube`（L2）、`cmd-ualg`（L3，執行檔，位於 `cmd/ualg/`）。
> **只匯入 `moonbitlang/core`**，不匯入本倉庫任何其他聯邦（`allowed_external_packages` 為空），
> 所以整個資料夾可以原封不動搬到獨立倉庫。與 `cubical/`、`topos/`、`symlib/` 的橋接列在 §7（尚未做）。

## 1. 一句話定位

把四份輸入——**構造性泛代數**（同餘／商、零元、Mal'cev 算子）、**預層模板**（j = ¬¬、Sh_j、左伴隨、
j(j(p)) = j(p)）、**工作內容 4**（De Morgan 立方體集合、仿射型別系統、自同構群、Kan 填充、懸掛與推出、
圓與環面、Alexandrov–Grothendieck 拓撲）與**組合範例**（商、層化、推出、局部化、Galois 對應）——
先各自做成獨立模組，再用三個定理把它們接起來。每個命題都由程式當場重算，並至少有兩條獨立路徑或一個反例對照。

## 2. 資料夾與依賴圖

```
moonbitlang/core
      │
      ├──────────────┐
      ▼              ▼
 ualg/core      ualg/site          ← L0，互不依賴
 （泛代數）     （預層模板）
      │              │
      └──────┬───────┘
             ▼
       ualg/demorgan               ← L1
     （De Morgan 立方體）
             │
             ▼
        ualg/cube                  ← L2
   （立方體上的層化 × 雙重否定核子）
             │
             ▼
        cmd/ualg                   ← L3，執行檔：印出全部命題
```

| 資料夾 | `.mbt` | 行數 | 定律／命題 | 內容 |
|---|---:|---:|---:|---|
| [`core/`](core/README.md) | 7 | 2,957 | 10 / 49 | 有限代數、同餘格、商、Mal'cev、零元與理想、Galois 連接、譜 |
| [`site/`](site/README.md) | 4 | 1,276 | 6 / 30 | Alexandrov 拓撲、Heyting 代數、核子、¬¬、預層、層化 |
| [`demorgan/`](demorgan/README.md) | 6 | 2,329 | 11 / 62 | DM(n)、立方體範疇、B_n、仿射片段、面格、立方同調、Hodge 譜 |
| [`cube/`](cube/README.md) | 5 | 1,194 | 2 / 26 | Sh_¬¬(□ⁿ) ≃ Set^{頂點}、子複形層化 = 頂點閉包、Glivenko Fix(¬¬) ≅ P(頂點)、Ω_¬¬ 公式 |
| [`../cmd/ualg/`](../cmd/ualg/README.md) | 1 | 57 | — | 定律總表執行檔 |
| **合計** | **23** | **7,813** | **29 / 167** | |

## 3. 得到的定理（跨模組的三個接點）

| 標籤 | 敘述 | 用到的模組 | 驗證方式 |
|---|---|---|---|
| **[T-Kal]** | DM(n) ≅ 自由有界分配格 FD(2n)，\|DM(n)\| = M(2n) = 6、168、7 828 354 | `demorgan` × `core` | 反鏈正規形閉包 = 單調真值表 = `core.free_algebra(𝟜, n)` 逐元素對上 |
| **[T-F3]** | 面格 𝔽(n) = DM(n)/⟨x_i∧¬x_i ≈ 0⟩ ≅ O(Vⁿ)（□ⁿ 的子複形格）；\|𝔽(0..3)\| = 2、5、48、15 936 | `demorgan` × `core` × `site` | `core.cg` 的商 = 刪不一致子句的核 = `site.opens_all` |
| **[T-Bool]** | DM(n) 的 De Morgan 同餘 ⟨x∧¬x ≈ 0⟩ 的核 = ¬¬ 核子的核；商是 𝟚^(2ⁿ) | `demorgan` × `core` × `site` | 兩個分割互相細化；類數 4、16 |
| **[T-Cube-1]** | 立方體上 j = ¬¬ 的兩條獨立路徑一致（Heyting 否定 = 頂點閉包）；Glivenko：Fix(¬¬) ≅ P(頂點)（4、16、256） | `cube` × `site` × `demorgan` | 15,989 個開集逐一比對；S ↦ u_S 雙射 |
| **[T-Cube-S1]** | Sh_¬¬(□ⁿ) ≃ Set^{頂點}：ρ 雙射且是顯式自然同構 | `cube` × `site` | V¹ 全部層窮舉；V² 子終層（16 個）逐一檢查 |

也就是：**「加上 x∧¬x = 0」這個代數動作有兩種做法**——只當格同餘做，得到 CCHM 的面格（幾何上是子複形）；
連 ¬ 一起做，得到布林代數，而它恰好是面格上 ¬¬-層化的像。預層模板裡的 `j(x) = ¬¬x` 在這裡不是比喻。

各模組內部的定理清單見各自的 README。

## 4. 核心公理在本聯邦的落點

| 核心公理（工程約束） | 落點 |
|---|---|
| 萬有奇點特徵（Grothendieck topos 的內在邏輯） | `site`：O(P) 是 Heyting 代數，排中律失敗 84 次；Ω_j、j-層、層化；`cube`：Sh_¬¬(□ⁿ) ≃ Set^{頂點}——¬¬-topos 的消去 |
| 局部公理 | `site`：匹配族與覆蓋篩；`core`：Freese–Valeriote 局部 Mal'cev 判定 = 全域判定 |
| Galois 對應（做成被證的定理） | `core`：Fix ⊣ Stab（GF(2^k)）、Mod ⊣ Th；`demorgan`：D₄ 在 DM(2) 上 10 個子群有 9 個閉 |
| 邏輯消去 | `demorgan`：∃i ⊣ w ⊣ ∀i（面格上的量詞消去）；`core`：商與 Rees 商；`cube`：量詞與布林化不交換（j∃i ≠ ∃i j 4 組、j∀i ≠ ∀i j 44 組） |
| 全域公理 σ(T) | `core`：平移算子 χ(T_f) = x^t·∏(x^{\|c\|} − 1)，商 ⇒ 整除；`demorgan`：Δ_k(□ⁿ) 的譜 |

## 5. 流程與輸入／輸出

```
輸入（全部是程式內建的有限對象，沒有外部檔案）
  有限代數的運算表 ──► core ──► 同餘格 / 商 / Mal'cev 憑證 / 閉集 / 特徵多項式
  有限偏序         ──► site ──► 開集 / 核子 / 預層 / 層化 (aF, η)
  變數個數 n       ──► demorgan ──► DM(n) 正規形 / 代換 / 面公式 / 複形 / Betti 數 / 譜

每個 law_*() : Array[(String, Bool)]      ← 標籤（含算出的數字）＋真假
每個套件 all_laws() : Array[(String, Array[(String, Bool)])]   ← (章節名, 命題清單)
cmd/ualg : 逐條印出；任一為假 ⇒ abort（非零結束碼）
```

## 6. 驗證

```bash
moon check --deny-warn --target wasm-gc     # 0 warning / 0 error
moon run cmd/ualg --target wasm-gc          # 通過 167 / 167 個命題
python3 tools/arch_check.py                 # architecture ok: 10 federations … 49 packages, 58 components
```

開發時的做法（依工程約束）：在檔尾寫一個臨時 `test` 區塊呼叫 `law_*()` 並印出，跑 `moon test <套件>`，
看完立刻刪除。倉庫內不留任何 `test` 區塊或 `*_test.mbt`（`arch_check.py` 會擋）。

## 7. 界線（做到哪裡、沒做到哪裡）

* **沒有型別檢查器**。工作內容 4 裡的 Π 型別、恆等型別、Glue、`hcomp`/`comp` 的計算規則、NbE、雙向檢查、
  高階合一、HIT 的消去子——本聯邦都沒有實作；那些在 `cubical/` 裡。這裡做的是它們底下的**組合與代數層**
  （區間代數、面格、立方體範疇、複形）。
* **Kan 填充只到同調層**：證的是「開盒無環、邊界有環」，這是填充存在的必要條件，不是填充運算本身。
* **懸掛、推出、圓、環面是立方複形**（□ⁿ 的子複形），不是 HIT；驗的是 Betti 數，不是同倫型。
* **規模**：DM(n) 可列舉到 n = 2（168 個）；n = 3 只算個數與抽樣。偏序 ≤ 30 點（Int32 遮罩）。
  立方複形到 □⁶（T³，729 個面碼）；V³ 有 15,936 個開集，全部只對一元運算窮舉；二元核子公理由偽隨機抽樣，不是全窮舉。
* **層化只到 Alexandrov 景**：Sh_¬¬(□ⁿ) 的等價是對尺寸的窮舉 + ρ 的顯式自然同構；不是類型論意義的證明。
* **未做的橋接**：`cubical/face_bdd`（面公式的 BDD 表示）、`topos/`（site 與層化的既有實作）、
  `symlib/`（自同構群）。目前三者與本聯邦各算各的，沒有互相對帳。
