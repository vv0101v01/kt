# `conjecture/` — Lakatos 猜想演化與定理創造引擎

> **架構位置**：`architecture.json` 中的 `conjecture`，**Layer 5**，依賴 `gcd`、`algebra`、`symlib`、`semiring-trop`、`topos`、`scheme`、`condensed`、`tensor` —— 它是全倉**倒數第二層的匯流點**（僅次於 `bridge`）。
> 聯邦歸屬：**F7 `discovery`**（與 `tensor/` 成對）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/conjecture`。

---

## 1. 定位：不是「證明定理」，而是「自動發現並轉移定律」

`conjecture/` 實作一條**可執行的科學方法**，分三段：

```text
[E-Derive]               [P-Basis]                 [P-Transfer]
在一條演化／形變軌跡上    由觀測矩陣的 F_p 零空間     把在第一段軌跡上
收集不變量 → 觀測矩陣     自動抽出線性無關的守恆關係   發現的關係，拿到
                        （不預設目標公式！）        未見過的轉移域上驗證
```

全部通過才算 `LcDerivedAndTransferred`（自動發現 + 樣本外驗證），並把結果**寫進 `@condensed.CondInvariantLedger` 的雜湊鏈賬本**，成為可稽核的持久不變量。

再加上**五個認識論關係透鏡**（`相對`、`對偶`、`對比`、`蘊含`、`比率`），系統化地把已知結論轉成新定理、反例與前提條件；最後彙整成 **7 條已決猜想圖譜（`CONJ-02..06`、`CONJ-09`、`CONJ-10`；沿用歷史編號）**。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `evolution_lenses.mbt` | 844 | 演化不變量發現引擎（`[E-Derive]`/`[P-Basis]`/`[P-Transfer]`）、6 條跨聯邦演化轉移定律、五個認識論透鏡、蘊含格 |
| `conjecture_atlas.mbt` | 447 | 猜想生命週期列舉、12 條跨聯邦更新猜想圖譜、創造性定理合成總摘要 |

---

## 3. `evolution_lenses.mbt` 精讀

### 3.1 觀測與發現

```moonbit
pub(all) struct ObservationRowSet { rows : Array[Array[Int32]]; p : Int32 }
```

| 函式 | 作用 |
|---|---|
| `rowset_holds_exact(rs, coeff)` | 某線性關係在**整數上**精確成立 |
| `rowset_holds_mod(rs, coeff, p)` | 在 `F_p` 上成立（用於浮點／大數場景的模檢核） |
| `derive_invariant_relations(rs, p)` | **`[E-Derive]` + `[P-Basis]`**：對觀測矩陣取 `@gcd.fp_nullspace_basis`，得到線性無關的守恆關係族；**不需要事先知道目標公式** |
| `relation_in_derived_span(basis, target)` | `[D-Rel-Derived]`：以**秩檢定**判斷 `target` 是否落在已導出關係的 `F_p`-張成空間內（避免「向量成比例」這種幼稚判準：`(1,1,0)` 與 `(1,1,1)` 都不在彼此的張成裡，但都不成比例） |

### 3.2 六條跨聯邦演化轉移定律（`discover_six_evolution_laws`）

| 軌跡 | 內容 | 跨聯邦來源 |
|---|---|---|
| `[E-Flip]` | 多邊形三角化翻轉遊走（`n = 5 → 6`），並**主動否證** `max_deg == 2` 這種假關係 | `@tensor` ↔ `@cubical`（Stasheff） |
| `[E-Gauge]` | 扭群代數餘邊界規範流（`d = 3 → 4`），不變量 `dim Z == \|rad\|` | `@tensor` ↔ `@condensed` |
| 其餘四條 | 分別在 `@gcd`／`@exactalg`／`@symlib`／`@strop`／`@topos` 的軌跡上做同樣的「發現 → 樣本外轉移」 | 六聯邦 |

回傳 `EvolutionTransferReport`（含 `derived_relations`、`transfer_holds`、反例見證、`ledger_hash`）。

### 3.3 五個認識論透鏡

```moonbit
pub(all) enum EpistemicLensKind { LkRelative; LkDual; LkContrast; LkImplication; LkScaleRatio }
```
| 透鏡 | 做的事 | 產出型別 |
|---|---|---|
| `相對` | 兩個結構在同一基準下的比值關係 | 新不變量／守恆律 |
| `對偶` | 對偶陳述的互相蘊含（例：`T²` 杯積 vs 楔和） | 判別性定理 |
| `對比` | 找出「A 成立而 B 不成立」的最小差異 | **反例 + 前提條件** |
| `蘊含` | 謂詞之間的蘊含格與反例矩陣 | `ImplicationLatticeReport` |
| `比率` | 縮放律（頻寬 vs 交叉開關交叉點的精確比值） | 縮放律 |

**蘊含格的機器化**（`implication_lattice_build`）：
* 對 `k` 個謂詞在 `num_samples` 個實例上求值；
* 建 `k × k` 遞移蘊含矩陣 `implies[i][j]`；
* 對 `i ⇏ j` 給出**明確最小反例樣本 ID** `counterexample[i][j] = id`（`-1` 表示真蘊含）；
* 用 **Floyd–Warshall** 驗遞移閉包。

`evaluate_five_epistemic_lenses_into_ledger(ledger)`：在 `@gcd`、`@exactalg`、`@tensor`、`@condensed` 上跑完五透鏡，把每張通過的關係記錄**附加到 `CondInvariantLedger`**，並回傳新賬本（`cond_ledger_verify` 可獨立驗鏈）。

---

## 4. `conjecture_atlas.mbt` 精讀

### 4.1 猜想生命週期

```moonbit
pub(all) enum ConjectureLifecycle {
  LcDerivedAndTransferred   // [E-Derive] 自動發現 + [P-Transfer] 樣本外驗證
  LcConjecture              // 有證據但未轉移
  LcRefuted                 // 有反例
  ...
}
```

### 4.2 7 條已決猜想圖譜（`CONJ-02..06`、`CONJ-09`、`CONJ-10`）

> **收錄準則**：圖譜只保留**已有裁決**的條目——被明確反例否證並改寫成可驗證修正版（`LcRefutedAndRefined`，5 條），或由引擎自動導出並通過樣本外驗證（`LcDerivedAndTransferred`，2 條）。只能「有界驗證」、「量到相變」或「開放前沿」而無法定對錯的舊條目（`CONJ-01/07/08/11/12`）已移除，不再作為題目保留。

`evaluate_updated_conjecture_atlas()` 逐條回傳 `UpdatedConjectureRecord`（編號、陳述、生命週期、見證、跨聯邦來源、賬本雜湊），。其中包含：

* 由 `@condensed` 的 `Conj-2` 升級／修正而來的條目（例如「`H₁`-繞數為 0 即可填充 2-盒」被 `F₂` 非交換反例**否證**後改寫為正確的 `π₁` 條件）；
* 由 `@tensor` 的 `6,561` 張量圖譜與 Cataln 翻轉圖歸納出的組合猜想；
* 由 `@topos`／`@scheme` 對偶性導出的判別性猜想。

### 4.3 總合成入口

```moonbit
pub fn synthesize_and_verify_conjecture_engine() -> ConjectureSynthesisSummary
pub fn check_conjecture_discovery_federation() -> Bool
```
`ConjectureSynthesisSummary` 彙整：6 條演化實驗、5 個透鏡（含賬本密封狀態）、7 條已決猜想，以及總計通過數。`cmd/showcase` 會把這份摘要印在「Star-Prism Discovery」段落。

---

## 5. 為什麼這是「Lakatos 式」而不是「隨機猜」

Lakatos 的「證明與反駁」有三個要件，本套件一一對應成程式結構：

| Lakatos | 本套件 |
|---|---|
| 從一個「證明」中抽出**引理** | `[P-Basis]`：由觀測矩陣零空間抽出線性無關關係 |
| 用**反例**修正引理（monster-barring / exception-barring） | `對比` 透鏡 → `ImplicationLatticeReport.counterexample` |
| 把修正後的猜想**推廣到新領域** | `[P-Transfer]`：在未參與發現的轉移域上驗證 |
| 承認某些猜想「仍在審查中」 | `ConjectureLifecycle` 的多態（未轉移 / 被否證 / 已轉移） |
| 知識必須可稽核 | `@condensed.CondInvariantLedger` 雜湊鏈 |

---

## 6. 範例

```moonbit
// 1) 從一條軌跡自動發現守恆律（不預設目標公式）
let rs : @conjecture.ObservationRowSet = {
  name: "flip-walk",
  columns: ["n", "catalan", "flips", "max_deg"],
  rows: rows,
}
let basis = @conjecture.derive_invariant_relations(rs, 10007, true)
println(basis.length())                          // 自動找到的獨立關係數

// 2) 六條跨聯邦演化轉移定律
for rep in @conjecture.discover_six_evolution_laws() {
  println(rep.family_id, rep.target_holds_on_transfer, rep.mirage_rejected_on_transfer)
}

// 3) 五透鏡寫入賬本
let ledger = @conjecture.evaluate_five_epistemic_lenses_into_ledger(@condensed.cond_ledger_new())
assert_true(@condensed.cond_ledger_verify(ledger))

// 4) 7 條已決猜想圖譜 + 總合成
let atlas = @conjecture.evaluate_updated_conjecture_atlas()
let summary = @conjecture.synthesize_and_verify_conjecture_engine()
```

---

## 7. 依賴與被依賴

* **雙層拆分**：
  * `conjecture/kernel`（`discovery-kernel`，`L3`）：僅依賴 `gcd`、`accel/swar`、`tensor`，提供 Half-GCD 模有理重構、`[E-Derive]` 多素數零空間守恆律推導與 64-bit SWAR 位平面蘊含格（`ctz` 極小反例）。
  * `conjecture`（`L5`）：重導出 `conjecture/kernel` 並匯流 `gcd`、`algebra`、`symlib`、`semiring-trop`、`topos`、`scheme`、`condensed`、`tensor` 執行 6 大演化轉移定律、5 大認識論透鏡與 12 項跨聯邦猜想。
* **被依賴**：`bridge`（`seven_federation_star_prism`、`K8-28`、`K9-35` 與 `F7→F9→F4→F1` 晉升管線）。
* **禁止**：本套件不得被 `condensed`／`tensor` 反向匯入（否則破壞 DAG）；兩者的關係是「`conjecture` 讀取它們的實驗台並寫入 `condensed` 的賬本」。

---

## 8. 驗證

```bash
moon run cmd/showcase --target wasm-gc               # Star-Prism & K_9 段落：conjectures=12/12, evolve=6/6, K9=36/36
```

---

## 9. 迭代 3：`polynomial_transfer_laws.mbt`（381 行）

原有六條演化定律把參數固定（`p = 3`、`n = 5` …），發現的是數值係數的線性關係。這一輪把**參數本身當成觀測欄**，引擎必須把定律找成參數的多項式：

| 家族 | 發現的定律 | 訓練 → 轉移 | 被消除的幻象維數 | 邊界反例 | 來源 |
|---|---|---|---:|---|---|
| `[E-Poly-Radon]` | `c − n·b − a² = 0`（`a = Σf`、`b = Σf²`、`c = Σ(Rf)²`） | `n ∈ {2,3}` → `n = 5` | 1 | `n = 4`（合成數）失效 | `@tensor` Radon |
| `[E-Poly-Hensel]` | `w − q·u = 0`（`x² ≡ 0 mod q^k` 的根數 `|S_{k+2}| = q·|S_k|`） | `q ∈ {2,3}` → `q = 5` | 3 | `x² − 1`（單根）時 `w = u` | `@condensed` 解塔 |
| `[E-Barcode]` | `m − 3·d = 0`（`C_m` 圓類的死亡尺度 `d`） | `m ∈ {6,9}` → `m = 12` | 0 | `3 ∤ m` 時失效 | `@tensor` 條碼 |

`[E-Barcode]` 另做 Lakatos 式修補：加入餘數欄 `r = (−m) mod 3` 後，同一引擎在 `m = 6..12` 上找到精煉定律 `m − 3·d + r = 0`（即 `d = ⌈m/3⌉`）。

三條倖存定律各以一筆 `kind = 1` 條目寫入 `CondInvariantLedger`，再加一筆 `kind = 2` 定理條目；鏈驗證之外，每筆都通過 `@condensed.cond_ledger_verify_inclusion` 的 Merkle 路徑驗證。

入口：`discover_polynomial_transfer_laws() -> PolynomialDiscoverySummary`；`check_conjecture_discovery_federation()` 已要求其 `all_ok`。六條線性定律的計數不變（猜想圖譜其後已精簡為 7 條已決條目，見 §4.2）。

**範圍說明**：這些是有限樣本上的精確整數關係加上樣本外檢驗，屬於「發現並通過轉移」的證據，不是對所有 `n`、`q`、`m` 的證明。
