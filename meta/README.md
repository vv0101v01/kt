# meta — 反射 × 全域實例 × 歸納-歸納：從數學結構長出來的三個型別論機制

> MoonBit `moonc v0.10.20` · `moon 0.1.20261104` · 第九聯邦（`meta-core` / `meta-instances` / `meta-iit` / `meta-reflect` / `cmd-metatheory`）
> `moon run cmd/metatheory --target wasm-gc` → **631/631 定律**（本地 2026-11-12 實測）· `python3 tools/arch_check.py` → `architecture ok`（10 聯邦／57 套件／66 元件／320 .mbt／201,027 行）

---

## 0. 30 秒驗證

```bash
python3 tools/arch_check.py                          # 10 聯邦 / 57 套件 / 66 元件 / 320 .mbt / 201,027 行（本地 2026-11-12 實測）
moon check --deny-warn --target wasm-gc              # 0 warnings, 0 errors（遠端 2026-11-10 四目標實測）
moon run cmd/metatheory --target wasm-gc             # 631/631 定律（逐條重算；本地 2026-11-12 實測）
moon run cmd/main       --target wasm-gc             # 139/139 定理（遠端實測，合併截面未重跑）
moon run cmd/showcase   --target wasm-gc             # 48/48 大一統證書 + K_9=36/36（遠端實測）
moon run cmd/ualg       --target wasm-gc             # 第十聯邦：ualg 全命題重算（本地落倉）
python3 tools/health_scan.py > tools/health_report.md # 合併截面未重跑（遠端 2026-11-10：5,810 函式／方法，0 死碼）
```

`cmd/metatheory` 印出的不是「測試通過」四個字，而是**每一條被機器重算的命題**，例如：

```
序數：1 + ω = w  <  ω + 1 = w + 1  （吸收律，非交換）
Ramsey：R(4,4) = 18（Paley 圖 P₁₇ 的 68 條紅邊給下界 + 遞迴上界 9+9 給上界，兩邊夾死）；
        R(3,5) = 14（K₁₃ 見證）；舊版的 Erdős–Szekeres 上界 C(6,3) = 20 已被嚴格優於
STLC：β 約簡 (λx.λy.x) arg ↝ 仍良構 = true，索引（上下文, 型別）完全不變 = true
併攏：可縮覆蓋 H¹ = 0 ⇒ 黏合 成功；圈狀覆蓋 H¹ = ℚ ⇒ 黏合 失敗（障礙是三元組）
歸納-歸納：4 階 Kleene 鏈後 Nat 有 4 個居民、Fin 有 6 個；Fin 的索引是項
反射：NbE 判定 (\x.x) * = * 為 true；同一步驟的**逐步憑證**獨立重放為 true
```

---

## 1. 版本事實（先查證，再動手）

這一批程式是在**當前最新穩定版** MoonBit 上寫的。查證到、且實際踩過的語法事實：

| 事實 | 出處／影響 |
|---|---|
| `moonc v0.10.14`（2026-09-21）是目前穩定版；`moon 0.1.20261102` 為對應 CLI | [moonbitlang.com/updates](https://www.moonbitlang.com/updates/) |
| `} derive(Eq, Debug)` 已棄用，改用**宣告前**的 `#derive(Eq, Debug)` | 本倉庫舊碼 276 個警告全部來自這裡 —— 已全數遷移，現在 `--deny-warn` 乾淨 |
| `impl Trait for Type` 的方法不再自動變成 `.` 方法，要用 `extend Type with Trait::{f, g}` | 本聯邦刻意不用 trait/impl：研究對象是「型別類的語義」 |
| `for .. in` 支援模式解構：`for (a, b) in pairs` | `meta/core`、`cmd/metatheory` 大量使用 |
| list comprehension `[ for x in xs if g => e ]` | 同上 |
| `#non_exhaustive` enum 在跨套件 match 時需 `E::..` | 未用；但影響如何設計公開 enum |
| 常數字串插值／`Bytes` 插值 `b"..\{x}"`、`lhs <+ rhs` 模板寫入 | 本聯邦用一般 `"\{x}"` 插值即可 |
| `pub` 型別的建構子跨套件唯讀，需 `pub(all)`（或提供建構函式） | **實測踩到**：`meta/core` 的 `UTerm` 一開始無法在 `meta/instances` 建構，改 `pub(all)` 後解決 |
| 含函式欄位的遞迴 enum **不要**拆成兩個互相遞迴的型別 | **實測踩到**：`Val` / `Neu` 互遞迴時型別推導退化、match 分支被判成 statement；合併成單一 `Val`（把中性項放進值域）即解 |

最後兩條是這次真正的「語法工事」：它們不在 release note 裡，是編譯器用錯誤訊息教會我的。

---

## 2. 為什麼先做數學結構

三個主題表面上是三個語言特性；把它們拆到骨頭，其實只要**四件數學結構**：

| 結構 | 為什麼非它不可 | 落在哪 |
|---|---|---|
| **超限序數（Cantor 範式）** | 「這個遞迴／這個搜尋為什麼會停」需要一個到 `(ε₀,<)` 的嚴格下降映射，而不是「看起來在變小」 | `meta/core/ordinal.mbt` |
| **一階合一（mgu）／反合一（lgg）** | 「兩個解什麼時候是同一個解」＝ meet；「兩個目標的共性」＝ join。這對伴隨就是「併攏／相容／共性」的可執行版本 | `meta/core/unify.mbt` |
| **擬陣（秩、貪心、對偶）** | 「哪一組實例是不可省的」＝ 基；「反轉系統」＝ 對偶（對合）。但**交換公理不保證成立**，所以要做成可量測的 | `meta/core/matroid.mbt` |
| **有限複形＋神經（Betti 數、Čech 上同調）** | 「局部解能不能併成全域解」的障礙住在 H¹；障礙必須是**可列舉的三元組**，不是一句「可能失敗」 | `meta/core/complex.mbt` |
| **構造性泛代數與瑪爾切夫多態（同餘格、商代數、Pol–Inv 伽羅瓦）** | 同餘一步可換 `θ∘ψ=ψ∘θ=θ∨ψ`、吸收零 vs 點化零二分、自反圖內蘊群胚提升與三類核擬陣／Ramsey 見證 | `meta/core/malcev_chu.mbt` |

再加上兩個組合工具：`Ramsey`（搜尋深度的有限上界）與 `精確有理數矩陣秩`（上同調與擬陣共用的引擎）。
所有後續的定理都在這六個檔案的函式上被**算出**，而不是被引用。

---

## 3. 主題一：反射（`meta/reflect`）

### 3.1 數學結構

`reflect : 中性項 → 語義值`、`reify : 語義值 × 型別 → 正常形式` 是一對伴隨：

```
        reflect
  語法 ─────────▶ 語義            reify ∘ reflect = η-展開
        ◀─────────               reflect ∘ reify = 恆等（在值域上 up to 等價）
         reify
```

於是「`a ≡βη b`」被判定成「`reify a` 與 `reify b` 語法相等」——這是 NbE。

### 3.2 兩條互不信任的判斷路徑

| 路徑 | 函式 | 特性 |
|---|---|---|
| 快、語義 | `decide_eq` | O(大小)，但**信任 NbE 的正確實作** |
| 慢、語法 | `check_cert` | 只驗「每一步是不是單一 β/η 步驟」＋端點，**不做任何正常化推理** |

`prove_eq` 連接兩者：判為相等時產生逐步轉換鏈（可列印、可存檔、可重放）。
篡改的憑證會被 `check_cert` 拒絕（見 `meta/reflect/proof.mbt` 的定律 5–11）。
這正是 Boutin 式 reflection 戰術的骨架：*untrusted fast decision procedure + small checkable proof object*。

### 3.3 宇宙反射：保守性與 Mahlo

第二種「反射」是宇宙層級的：

* `provable(level, φ) ⟺ 所有原子層級 < level`；
* `reflect_stmt(φ)`：把每個原子抬一層；
* **保守性（可判定）**：`provable(l+1, reflect φ) = provable(l, φ)`；
* **Mahlo 式反射**：`provable(λ, φ)` 且 λ 是**極限層**（CNF 最末項指數 ≠ 0）時，存在 `α < λ` 使 `provable(α, φ)`；
  而在**最小充分層級**（後繼臨界情形）反射必然失敗 —— 這正是「反射在極限成立、在後繼可能失效」的可執行版本。

層級就是 `meta/core` 的 Cantor 範式序數，所以「極限 / 後繼」不是比喻而是判定：`ω` 是極限、`ω+1` 是後繼、`ω·2` 是極限。

---

## 4. 主題二：全域實例（`meta/instances`）

### 4.1 數學結構

一個 typeclass 系統 = 一組 Horn 子句 + 一個解析關係。真正難的三件事，各有對應結構：

| 難點 | 結構 | 可判定檢查 |
|---|---|---|
| **終止** | 序數度量 | 每條規則的 body 目標度量 `ω^{深度}` 嚴格小於 head（`terminating`） |
| **一致性** | 臨界對（重疊實例）＋典範化 | `critical_pairs` × `maximal_derivs`：同優先級兩條路只算一致若見證相同 |
| **組合性** | 覆蓋的下降條件（sheaf） | 神經的 `H¹ = 0` ⇒ 兩兩相容自動升級；否則障礙是可列舉的三元組 |

### 4.2 五個可執行結論

1. **實例合成**：`Show(Pair Int (Array Bool))` 的見證唯一，`showPair(showInt, showArray(showBool))`。
2. **終止**：`Show(T) :- Show(Array T)` 被判「不下降」；`Show(Array T) :- Show(T)` 被判下降（`ω³ > ω²`）。
3. **擬陣**：以「可解出的目標數」為秩，**平坦**實例系統滿足交換公理（量測通過），共享子目標的情形由程式回答而不是作者宣告；極小實例基用貪心刪除產生，並驗「去掉任一條就解不動」。
4. **黏合**：`[U0,U1]` 線段覆蓋可黏；三片首尾相接、轉移全是 `−1` 的 Möbius 覆蓋**不可黏**（除非取零截面，這正是 Möbius 帶的拓撲事實）；對照組 `+1` 全部可黏。
5. **鏡像對偶**：把 head/body 反轉、公理 `h :- []` 編成餘公理 `⊤ :- h`，得到**對合** `mirror(mirror(E)) = E`，且
   `E ⊢ G ⟺ mirror(E) + 假設 G ⊢ ⊤`（`dual_derivable`，兩方向都測）。

### 4.3 Ramsey 的位置（誠實版）

Ramsey 不是萬靈丹，它的確切作用是**有限記憶體的迴圈偵測**：

* 鴿籠界：簽名類有 `k` 類 ⇒ 路徑長 `> k` 必然重複（`pigeonhole_window`）；
* Ramsey 界：把「逐步關係」二色標記，長度到 `R(k,k)` 保證出現 `k` 個同色同構的步 ⇒ 窗口取 `R(k,k)` 一定安全，但**更寬**（`ramsey_window`）；
* 精確值只算到 `R(3,3)=6`（搜尋），`R(4,4)` 用**可證的 Erdős–Szekeres 上界** `C(6,3)=20`，程式不假裝算得出來。

---

## 5. 主題三：歸納-歸納（`meta/iit`）

### 5.1 為什麼 II 不是「互遞迴 + 換個名字」

互遞迴型別可以是乘積範疇上一個自函子的初始代數 `F : C×C → C×C`。
II 不行：`Fin : Nat → Type` 的索引是 **Nat 的項**，所以第二分量是切片範疇 `Set/Nat` 上的範子，而其定義域 Nat 還在被定義中。
Dybjer–Setzer 的正解是把固定點取在**切片範疇裡的初始代數**。本實作把它變成可執行的工程：

```moonbit
/// T₀ = ∅ ; T_{n+1} = T_n ∪ F(T_n)
let (fam, truncated) = iit_enumerate(schema, fuel, cap)
```

**關鍵實測**（測試化的，不是宣稱）：第 1 階段 `Nat = {z}`、`Fin = ∅`；第 2 階段 `Fin = {fz z}`。
Fin 的擴張**永遠落後 Nat 一階**——這個相位差就是「切片塔」與「同時擴張」的分野。

### 5.2 索引檢查（II 的核心型別檢查）

```moonbit
// fs : (n : Nat) → Fin n → Fin (s n)
ictor("fs", 1, [ictor_ix(1, [ivar(0)])], [iarg_val(0, "n"), iarg_rec(1, "i", [ivar(0)])])
```

`icheck` 逐個遞迴參數驗「實際索引 = schema 索引表達式求值」，於是

* `fs(s z, fz z) : Fin (s (s z))` ✅
* `fs(z, fz z)` ❌（`fz z : Fin (s z)`，不是 `Fin z`）

### 5.3 STLC：索引裡真的需要 `cons`

`Ty / Ctx / Tm : Ctx → Ty → Type`，

* `vz : (G : Ctx)(A : Ty) → Tm (cons A G) A`
* `lam : (G)(A)(B) → Tm (cons A G) B → Tm G (arr A B)`
* `app : (G)(A)(B) → Tm G (arr A B) → Tm G A → Tm G B`

於是 `λx:nat. x : Tm nil (arr nat nat)` 通過；同一個項宣稱成 `Tm nil nat` 被拒；`(λf.f)(λx.x)` 通過而其錯型版本被拒。
這是把 STLC 的定型判斷寫成**一個 II 型別**，而索引運算 `cons` 出現在索引裡——這正是 II 比 IR 多出來的那一塊。

### 5.4 消除器與終止憑證

`iit_fold` 是互遞迴消除器（索引在檢查階段用完即擦除），ι 律以「重建即恆等」驗證：`fold(v) = v`。
終止性用序數憑證：`measure(v) = ω^{size(v)}`，逐個遞迴參數驗 `measure(子項) < measure(父項)`（在序數上直接比，不只回傳布林）。

---

## 6. 二十五種方法：逐條落點

| 你列的方法 | 在這裡的具體形態 | 檔案 / 函式 |
|---|---|---|
| 衍生（derivation） | Horn 推導樹；`Deriv` → `evidence` 見證項 | `instances/engine.mbt` |
| 計算機抽象 | 語義值域（closure 即 β-閉包）；語法 ↔ 語義兩層 | `reflect/nbe.mbt` |
| 併攏（gluing） | 覆蓋的下降條件：`glue` / `cover_glues` | `instances/compose.mbt`、`core/complex.mbt` |
| 嵌入（embedding） | HF 集合的 `V_α` 塔、`sat`（真滿足關係）、絕對性與反射層級（club） | `reflect/universe.mbt`、`reflect/club.mbt` |
| 聯動（linkage） | 實例推導 → 憑證 → 獨立檢查器 | `reflect/link.mbt` |
| 計算（computation） | NbE 的 `eval`；Kleene 鏈 `iit_stage` | `nbe.mbt`、`iit/schema.mbt` |
| 推論（inference） | SLD 解析（合一 + 深度限制 + 去環），完備性以無剪枝暴力搜尋對照 | `instances/engine.mbt` |
| 共性（commonality） | 反合一 `u_lgg`（join）；mgu（meet） | `core/unify.mbt` |
| （鏡像）對稱性 | `mirror_env` 對合 + 對偶互證 `dual_derivable`；擬陣對偶 `r** = r` | `instances/compose.mbt`、`core/matroid.mbt` |
| Ramsey 理論 | `ramsey(k,l)` 真搜尋、見證建構、深度窗口 | `core/ramsey.mbt`、`instances/compose.mbt` |
| 擬陣 | 秩／貪心／對偶／交換公理量測 | `core/matroid.mbt`、`instances/compose.mbt` |
| 複形 | 單純複形、邊界矩陣、Betti、神經、障礙三元組 | `core/complex.mbt` |
| 邏輯推理 | Horn 子句、臨界對、典範化（Newman 式合流判準的位置） | `instances/engine.mbt` |
| 演變（evolution） | Kleene 鏈的階段成長／穩定；`Nat/Fin` 無限、有限 schema 穩定 | `iit/schema.mbt`、`iit/examples.mbt` |
| 借鑒（borrowing） | 把證明助手的三件套（decide / certify / check）借到實例系統 | `reflect/*` |
| 多合一（all-in-one） | 一個 `cmd/metatheory` 跑完 258 條定律＋五個最小見證 | `cmd/metatheory/main.mbt` |
| 溶合（fusion） | 擬陣貪心的正確性（Rado–Edmonds 的位置）＋極小基 | `instances/compose.mbt` |
| 合併（merge） | 多模組實例環境的限制 `restrict` 與覆蓋併合 | `instances/*` |
| 相容（compatibility） | `coherent`：臨界對可併合 + 無不一致見證；模組匯入圖的 SCC 判環與典範解析序 | `instances/engine.mbt`、`instances/modules.mbt` |
| 組合（composition） | 實例合成（`showArray(showInt)`）；索引組合（`cons` 在索引裡） | `instances`、`iit` |
| 對偶／伴隨 | reify ⊣ reflect；mgu ⊣ lgg | `nbe.mbt`、`unify.mbt` |
| 形式化保守性 | `conservative(level, φ)` | `universe.mbt` |
| 障礙理論 | `monodromy_witness`（ℤ₂ 扭結）＋ `cover_obstruction`（Čech） | `instances/compose.mbt`、`core/complex.mbt` |
| 憑證經濟學 | `cert_size`：reflection 的賣點是憑證短 | `reflect/proof.mbt` |
| 量測而非宣稱 | `terminating` / `matroidal_strict` / `ramsey_upper`：算不出來就回 `None`，不把上界當答案 | 各檔 |
| 構造 vs 窮舉 | Paley 圖 P₁₇ 給 R(4,4) 的下界；構造取代 2^153 的窮舉 | `ramsey_ex.mbt` |
| 索引傳輸 | `ctx_insert` / `subst_insert`：把「弱化」變成「插入一個型別到上下文第 k 位」 | `stlc.mbt` |
| 判準 vs 量測 | 擬陣性用判準決定（兩個語法條件），不是逐環境測交換公理 | `characterize.mbt` |

---

## 6.5 四項續作：從「已知未做」到「可執行」

上一版在文末列了五項未完成的工作。其中四項在這裡做完了，而且每一項都不是「補功能」，
而是**換一個數學結構**（否則只是把窮舉寫快一點）。

### (1) STLC 的 β 與索引傳輸 → `meta/iit/stlc.mbt`

舊版的難點寫得沒錯：`app (lam A B body) arg` 的代換要讓 `arg : Tm G A` 在走過 k 層
binder 之後變成 `Tm (cons A_k (… (cons A_1 G))) A`——**上下文本身在變**，所以
「代換」其實是「沿索引傳輸」。

解法只有一個操作：把「插入一個型別到上下文的第 k 個位置」變成基本操作

```moonbit
ctx_insert ctx x k     // 純資料操作
subst_insert t x k     // 同步重寫所有變數節點（vs 鏈的深度會跟著改）
```

有了它，代換退化成數深度：在深度 d 遇到位置 p 的變數時 `p = d` 換成弱化後的 `arg`、
`p > d` 位置減一、`p < d` 不動；每個節點儲存的上下文都把第 d 個元素拿掉。

於是型別保持不再是信仰：每一步都用 `icheck`（重建檢查）與 `iindex_of`（索引重算）驗。

### (2) 一致性判準的完備性 → `meta/instances/coherence.mbt`

三個缺口各自補掉，而且補法不同：

| 舊缺口 | 補法 |
|---|---|
| 只在**使用者給的 battery** 上檢查 | `reachable_closed_goals`：從規則 head/body 做 BFS 閉包（mgu 實例化 + 具體化池），battery 由程式自己算 |
| 看不見**區域實例**（模組內實例／假設） | `coherent_with_local(e, locals, d)`：locals 併進來一起檢查 |
| 子目標的優先級被誤報成衝突 | `resolve_canonical`：每個子節點換成它的**典範推導**後才比對 |

另外兩件事一併做成判定：(a) **擴充穩定性**（COCHIS 的 stability）——
`stable_under(e, extra, d)` 檢查「加實例後既有見證是否漂移」，並能指出漂移的目標；
(b) **Newman 引理**的實測版——`newman(e, d)` 分別回報終止、局部合流、全域合流。
並且對帳了一個**正面**結果：在純 Horn 片段裡，局部尖峰與 head 重疊是同一組東西
（`peak_overlap_agreement`），所以舊判準缺的是宇宙與區域實例，不是臨界對。

### (3) 可導性閉包「是不是擬陣」→ `meta/instances/characterize.mbt`

舊版只測**交換公理**，而這是**太弱**的判準：`Show(Int) + Show(Array T)` 的環境會通過
交換公理，但秩函數根本不是擬陣秩——加一條規則可以讓秩一次跳 **2**（次模性 R3 壞掉）。

現在的判準是：

> 可導性秩在目標集 G 上是擬陣秩 ⟺
> (1) 沒有合成規則（body ≠ ∅）的 head 落在 G 上；
> (2) 每條規則最多覆蓋一個目標。

兩條件同時成立時，秩退化成「被覆蓋的目標數」＝分割擬陣的秩；(⇐) 方向在 12 個
（環境 × 目標集）樣本上與嚴格秩公理檢查**逐一對帳**，(⇒) 反方向給得出單位增量與次模性的
具體反例。附帶釘住貪心的界線：**極小基 ≠ 最小基**，不同刪除順序會停在大小 1 與 3 的兩個極小基。

### (4) Ramsey 更大的值 → `meta/core/ramsey_ex.mbt`

舊版只到 R(3,4)=9，因為它用窮舉；R(4,4) 的窮舉要處理 2^153 張圖——**方向錯了**。
現在兩邊夾擠，而且兩邊都是可複驗物件：

* **下界（構造）**：Paley 圖 P₁₇（q ≡ 1 mod 4 質數，紅邊 ⇔ 差是二次剩餘）是 (4,4)-free
  ⇒ R(4,4) ≥ 18。任何人可用 `ramsey_check_coloring` 獨立複驗那 68 條邊。
* **上界（證明）**：經典遞迴 R(k,l) ≤ R(k−1,l) + R(k,l−1)，配小值精確種子 ⇒ R(4,4) ≤ 9+9 = 18。

兩邊一夾：**R(4,4) = 18**。同樣手法把 **R(3,5) = 14** 夾死（上界 5+9，下界 K₁₃ 的
確定性局部搜尋見證）。副產品：實例搜尋的深度窗口 `ramsey_window(3)` 從「跑不動」
變成 18，且 `ramsey_window(k) = R(k,k)` 的可證上界永遠 ≥ 真值。

---

## 7. 誠實邊界（寫進報告，不藏在文件外）

| 事項 | 狀態 |
|---|---|
| 「所有定律都通過」 | ✅ 631/631（本地 2026-11-12 實測），`moon run cmd/metatheory` 每次重算 |
| 「這些是形式化定理」 | ❌ 不是。它們是**機器可判定的具體實例 + 結構性論證**；沒有在 Coq/Agda 裡做 meta-theorem 的形式化 |
| 一致性判準 | 現在是「**可達目標宇宙**（程式生成）+ 區域實例 + 典範化子推導」上的判定；仍受深度上限約束，且不是完整的合流判定程序 |
| 可導性閉包是擬陣嗎 | **有判準，且已升級為逐實例證書**：`matroidal_criterion` + `matroidal_certificate`／`verify_matroidal_certificate`——分割（blocks/loops）結構檢查 + **2^n 窮盡對帳**（n ≤ 12，與 `submodularity_witness` 同一上限），取代舊版 12 樣本對帳；形式化證明（Lean）仍未做 |
| R(4,4) | **算出來了 = 18**（Paley 下界 + 遞迴上界夾死）。R(4,5)：**≥ 25 已以發表見證機器複驗**（McKay–Radziszowski 目錄 `r45_24.g6` 首張 (4,5,24)-graph：124 條邊、無 K₄、無獨立 5-集，兩條獨立演算法；2026-11-10 重下載以獨立解碼器逐邊交叉核對一致）；上界仍 ≤ 32（遞迴）。R(5,5) 仍未算 |
| II 消除器 | 是「索引擦除後」的互遞迴消除器；真正依賴 motive 的消除器需要相依宿主語言 |
| STLC 的 `beta`／`eta` | **皆已實作**（`stlc_beta` + `subst_insert` 索引傳輸；`stlc_eta`，`x ∉ FV(f)` 的可判定形式 = f 不含 `vz` 節點，機器複驗保型）。多步正規化：**逐項 SN 證書**（`meta/iit/sn.mbt`，β∪η、位置不限，窮舉歸約樹；`Some(k)` = 全路徑 ≤ k、預算超 ⇒ `None`；樹上每節點 `icheck` 通過）。仍未做：**全稱的強正規化定理**（Tait–Girard，Lean 凍結） |
| 多目標規則的鏡像 | `mirror_rule` 的 ≤ 1 前提精確性由 `mirror_exact` 可執行檢查；多目標規則用**餘衍生** `forward_least_model`（正向最小模型，∪ 項大小／原子數／輪數上限，超限誠實回 `None`）；樸素鏡像在 ≥ 2 前提下雙向不成立（量測反例已釘進定律 #3） |

---

## 8. 文獻（做完才回頭對照）

* **反射**：S. Boutin, *Using reflection to build efficient and certified decision procedures*, TACS'97；
  S. Allen, R. Constable, D. Howe, W. Aitken, *The semantics of reflected proof*, LICS'90；
  A. Chlipala, *Certified Programming with Dependent Types*（reflection 章）。
* **宇宙反射 / Mahlo**：P. Dybjer, A. Setzer, *Induction–recursion and initial algebras*, APAL 124 (2003)（切片範疇初始代數、Mahlo 宇宙）；
  A. Setzer, *Extending Martin-Löf Type Theory by one Mahlo-Universe*, AML 39 (2000)。
* **全域實例 / 一致性**：P. Wadler, S. Blott, *How to make ad-hoc polymorphism less ad hoc*, POPL'89；
  G.-J. Bottu et al., *Coherence of type class resolution*, ICFP'19（[arXiv:1907.00844](https://arxiv.org/pdf/1907.00844)）；
  D. Devriese, F. Piessens, *On the bright side of type classes: instance arguments in Agda*, ICFP'11；
  M. Sulzmann et al., *COCHIS: Coherent ImplicitS*（JFP 2019）。
  Agda 文件亦明示：開啟 overlapping instances 可能導致**指數級變慢與看似迴圈**——這正是本檔第 4.3 節要把深度界做成有限窗口的動機。
* **歸納-歸納**：F. Nordvall Forsberg, A. Setzer, *Inductive-inductive definitions*, CSL'10；
  F. Nordvall Forsberg, *Inductive-inductive definitions*（博士論文，[fredriknf.com/thesis](https://fredriknf.com/thesis/thesis.pdf)）；
  P. Dybjer, *A general formulation of simultaneous inductive-recursive definitions*, JSL 65 (2000)。

---

## 9. 檔案地圖

```
meta/core/                數學結構層（零外部依賴）
  ordinal.mbt             Cantor 範式序數：加法、吸收律、ω 左乘、極限判定、ord_max 的格論性質
  algebra.mbt             精確有理數 + 矩陣秩（消元）
  unify.mbt               一階合一/MGU、反合一/LGG、α-等價正規化
  matroid.mbt             秩函數擬陣、貪心、對偶、交換公理檢查
  ramsey.mbt              R(k,l) 窮舉搜尋、見證建構、Erdős–Szekeres 上界
  ramsey_ex.mbt           Paley 圖、遞迴上界、夾擠（R(4,4)=18、R(3,5)=14）、確定性局部搜尋
  complex.mbt             單純複形、邊界、Betti、神經、Čech 障礙
  laws.mbt                定律登記（**只由 tools/gen_laws.py 產生**；chk 全聯邦唯一定義在 core）

meta/instances/
  engine.mbt              Horn 規則、SLD 解析、見證、臨界對、一致性、序數終止
  compose.mbt             可導性擬陣、極小實例基、黏合與單值化障礙、鏡像對偶、Ramsey 窗口（轉發 core）
  coherence.mbt           可達目標宇宙、典範化子推導、區域實例、擴充穩定性、Newman 引導
  characterize.mbt        擬陣判準（無合成規則 + 每規則一覆蓋）、單位增量/次模性反例、極小≠最小
  laws.mbt

meta/iit/
  schema.mbt              II schema、索引求值/檢查、Kleene 鏈、互遞迴消除器、序數終止憑證
  examples.mbt            Even/Odd、Nat/Fin、STLC Ctx/Ty/Tm（建構子轉發到 stlc.mbt）
  stlc.mbt                STLC 的 β／η：ctx_insert / subst_insert 索引傳輸、弱化、單步與多步約簡、型別保持
  sn.mbt                  STLC 逐項 SN 證書：窮舉 β∪η 歸約樹（Some(k) = 全路徑 ≤ k、預算超 ⇒ None）、η 納入、樹逐節點 icheck
  laws.mbt

meta/reflect/
  nbe.mbt                 型別/項/值、eval、reflect/reify、β/η 單步、型別推導
  proof.mbt               decide_eq、prove_eq、check_cert（獨立重放）
  universe.mbt            序數層級、抬升、保守性、Mahlo 式反射
  link.mbt                實例推導 → ProofNode → 無搜尋檢查器
  laws.mbt

cmd/metatheory/main.mbt   551 條定律總表 + 七個最小見證（含 STLC β/η／SN 證書行與 R(4,5) ≥ 25）
tools/gen_laws.py         由 `pub fn law_*` 自動產生各套件 laws.mbt（取代手抄索引）
tools/gen_labels.py       讀 `cmd/metatheory` 的**實際輸出**重生 lean/labels/moonbit-labels.md（漏登記一定看得出來）
tools/health_scan.py      死碼 / 重複 / 債務掃描（報告，非閘門）
tools/health_report.md    最近一次健檢結果
```

---

## 9.5 三個能力的能力對帳（不是形式化對帳）

反射技術／全域實例／歸納-歸納這三個能力的「能不能用、能不能自己檢查、邊界在哪」，
逐條寫在 [`CAPABILITIES.md`](CAPABILITIES.md)。本輪在 kt 側補了三件事：
**NbE 的正規形保證**（順帶修掉高階項不冪等的真 bug）、**實例系統的自動修補**
（Knuth–Bendix 式）、**QIIT 的等式建構子（值層商化）**；並更正了 `meta/iit/README.md`
裡一條早就做完卻沒同步的待辦（STLC 的 β）。

## 10. 已知的下一步（不假裝做完）

已於先前輪次完成的四項（細節見 §6.5）：STLC 的 β 與索引傳輸、一致性判準的完備化、
可導性閉包的擬陣判準、Ramsey 的 R(4,4)=18 與 R(3,5)=14。
2026-11-10（第 3 輪）又結案四項：STLC 的 η（`stlc_eta`）、擬陣判準的逐實例證書（取代 12 樣本對帳）、
多目標規則的餘衍生（正向最小模型 + `mirror_exact` 前置條件）、R(4,5) ≥ 25 的發表見證複驗。

仍然沒做的（寫清楚，不用「未來工作」帶過）：

1. **多步正規化的終止性**：**逐項 SN 證書已做**（2026-11-10，`meta/iit/sn.mbt`：β∪η、位置不限，窮舉完整歸約樹；`Some(k)` = 所有路徑 ≤ k 由完整樹驗明；`stlc_sn_tree_typed` 對樹上每個節點重跑 `icheck`；預算超一律回 `None`）。**全稱的強正規化定理仍未證**——那是 Tait–Girard 可歸約性／邏輯關係，不是本倉 MoonBit 側能表達的命題（Lean 凍結）。入口見 §6.5；深度上界是「最長路徑」不是大小的線性函數，兩條都是實測值。
2. **判準的形式化證明**：`matroidal_criterion` 的 (⇐) 方向現有**逐實例證書**（`matroidal_certificate` 產生、
   `verify_matroidal_certificate` 獨立驗證，結構檢查 + 2^n 窮盡對帳，n ≤ 12）；
   證明助手裡的**全稱**定理仍未做（Lean 側 O-義務）；`(⇒)` 只給反例族。
3. **R(4,5)**：**≥ 25 已以發表見證機器複驗**（McKay–Radziszowski 1995 完整目錄 `r45_24.g6` 的首張
   (4,5,24)-graph，124 條邊；本檔嵌入 24 個遮罩，兩條獨立演算法複驗：`ramsey_check_coloring`
   與遮罩數 K₄／補圖數 K₅）。它仍是 **≥ 25、≤ 32** 的夾擠，不是精確值：
   1995 年 `R(4,5) = 25` 的證明窮舉了 25 點的所有候選（約 3.2 CPU-years），不在本專案範圍。
4. **Ramsey 更大值的工程極限**：R(5,5) 已知 43 ≤ R ≤ 48，兩邊都超出本檔的方法。
5. **把定律搬進證明助手**：`meta/*` 的結構性論證可望在 Agda/Lean 裡形式化成 meta-theorem，
   這會把「551 條具體定律」升級為「定理」。
   *進度*：Why3 + Z3 這條路已實測並排除（見 [`prove_feasibility.md`](prove_feasibility.md)）；
   改走 Lean 4.35.0，工程骨架在 [`../lean/`](../lean/README.md)，目前 **492** 條定理已證明登記（437 個舊標籤／340 個互異全覆蓋；本輪新增 48 條尚未鏡射）
   （Ramsey／圖 19 條含 `R(3,4) = 9`、`R(4,4) = 18`、`R(3,5) = 14` 三個精確值；
   擬陣 14 條含秩公理、交換公理、圖擬陣貪心最優、對偶 `r** = r` 與 Q 上的線性擬陣；
   單純複形／覆蓋 19 條含**全稱的 Euler–Poincaré**、Betti 數與神經 `H¹` 的黏合判準；
   歸納-歸納 82 條把 ι 律、終止性、Kleene 鏈單調與可靠性從樣本升級成**對所有項**的定理，
   並把 STLC 的 β 索引傳輸（上下文插入／弱化／代換）與主體約簡搬完；
   全域實例 138 條把 SLD 解析、終止（`ω^{uDepth}`）、一致性（臨界對＋典範化）、
   「可導性秩是擬陣秩」的**判準**、覆蓋併攏的 Möbius 障礙、鏡像對偶、
   區域實例與擴充穩定性、Newman 引理全部搬成可判定的檢查；
   序數 31 條，其中 `ord_max` 的 join 律已由樣本升級為全稱）。
6. **矩陣層的重複實作**：`meta/core/algebra.mbt` 與 `cubical/hermitian/complex.mbt` 各有一份
   `mat_mul` / `mat_identity`（健檢報告已列出）。聯邦邊界（meta 獨立於 cubical）讓共用變成
   架構決策，不是單純刪一份就好；目前明示保留，交由 `architecture.json` 的層級決定。

---

## 11. 全代碼健檢（本輪新增的一支工具）

`python3 tools/health_scan.py > tools/health_report.md` 會掃全倉 5,200+ 個函式定義，
輸出三張清單：**零引用死碼**、**完全相同函式體**、**結構極相近（疑似複製貼上）**。
它不是閘門（閘門仍是 `moon check --deny-warn` + `arch_check`），而是「債的盤點」。

本輪的處置（原則是「能救的救，不能救的刪，有文檔的留」）：

| 類別 | 處置 | 數量 |
|---|---|---|
| 完全重複的實作 | **刪**（`ramsey_assign_witness` 與 `ramsey_assign` 只差函式名；`solvable_all` 與 `solves_all` 同套件重複） | 2 |
| 零引用的轉發／佔位 | **刪**（`ramsey_loop_detect_window`、`stlc_ex_arg` 的獨立實作） | 2 |
| 零引用但有數學價值的工具 | **接上定律**變成被驗證的程式：`cx_f_vector`（f-向量的交錯和 = Euler 特徵）、`ord_max`（格論 join）、`iholed`（schema 佔位必須被拒）、`env_fingerprint`（`mirror²` 的 head 對合）、`cert_to_string`（憑證可列印且仍可重放） | 5 |
| 其他聯邦的零引用 pub 函式（文檔未提及） | **刪**（`int_abs`、`gf3_slice64_pack`、`check_intuitive_conjecture_lab`） | 3 |
| 其他聯邦的零引用 pub 函式（文檔有提及） | **保留**（`gf3_sub64`、`run_grand_unification_system`、`rotation_axis_certificate`、`cond_quaternion_axis_conserved`） | 4 |
| 同一套件的第二份 `ramsey_window` | **合併**：轉發 `@core.ramsey_upper`，並刪掉「R(4,4) 不可算」的過時說明 | 1 |
| 過時的說明文字 | 更新 `ramsey.mbt` 檔頭、`compose.mbt` 邊界註解、`meta/README` 誠實邊界表裡的「未實作 STLC β」標記 | 3 |

死碼候選：14 → 4 → **0**（全倉健檢升級後，掃描 `5,810` 個函式／方法達成 **0 死碼、0 無引用型別、0 空殼 `enum`、0 完全相同函式體**（遠端 2026-11-10 實測），`cmd/metatheory` 達 **631/631 定律**）。
