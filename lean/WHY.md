# 為什麼會有 `lean/`（形式的**原因**、範圍、與可處置性）

> 這是一份**決策文件**，不是成果宣稱。它回答四件事：當初為何走形式化、按那個理由**只應該做哪一部分**、
> 現在實際做了什麼、以及「能不能用／能不能刪」。日期：2026-11-07（2026-11-10 更新三次：①O4 完成為誠實版本；②使用者裁決「不另作保存、決定刪除多餘物」→ **`Reflect/Universe.lean` 實際刪除**，O1–O6 全部成為 kernel 綠義務；③11-11 O1 第一半邊落地（`nf_beta_normal`），冪等半邊仍待 logical relation，見 §4／§6）。

---

## 1. 原因（文檔原文，逐條可查）

### 1.1 觸發點：`moon prove`（Why3 + Z3）在此倉定律的形狀上不可行

出處：[`../meta/prove_feasibility.md`](../meta/prove_feasibility.md)（2026-11-04，決策文件，數字為本機實測）。
該文件第 4 節列了**三個決定性的 lowering 缺口**：

1. **`#proof_pure` 不支援遞迴、也不支援契約** —— 它是「同一份實作同時給程式端與邏輯端看」的唯一橋樑；
   而 `meta/*` 幾乎每個函式都是對 ADT／`Array` 的遞迴。結果定律裡的 `f(...)` 只能是 `.mbtp` 裡另寫的**邏輯副本**，
   也就是「證明的是副本，不是跑得動的程式」。
2. **`Int` 上沒有算術 variant，`.mbtp` 也沒有條件式** —— 本倉定律大量是 `if/match` 分支 + 遞迴累加。
3. **SMT 不做計算** —— 實測 `pinned`（四元素陣列完全釘死、後置條件 `result == 2`）Z3 直接 timeout；
   本倉 44/54 個 law 函式含字面值比較、13 個驅動列舉迴圈。

### 1.2 結論句（就是「走形式化」的理由）

同文件第 6 節第 3 點，原文：

> 若目標是「metatheorem 級」的可信度，長期還是得走 Agda/Lean（§10 第 5 條），
> Why3 適合的是**演算法層**的性質，不是型別論的歸納定義。

以及第 5 節的判詞：

> 這與「把定律搬進證明助手」原本的意圖（提高可信度）**方向相反**：證明的是副本，不是跑得動的程式。

### 1.3 目的層的限制（本倉的既有定調）

出處：[`../meta/CAPABILITIES.md`](../meta/CAPABILITIES.md) 首段：

> **目的不是形式化。** Lean 只在「推進能力時順帶需要證明」才寫（那是證明義務，不是產品）。

**把 1.1–1.3 合起來，理由只有一句：**
> kt 的三個能力（反射／全域實例／歸納-歸納）裡，有一批主張是 **metatheorem 級的**——
> 「對所有項／所有環境／所有 schema 成立」，而這種主張**既算不出來（取樣只能否證），SMT 又證不動**。
> 走 Lean 的唯一正當理由，就是補上這批**全稱且需要歸納**的命題。

---

## 2. 由理由推出的範圍：「原因部份」＝全稱＋歸納，不含具體計算

按 1.2 的判準，形式化**只應該覆蓋**同時滿足兩條的命題：
(a) kt 的執行檢查**確立不了**（樣本／有界域／取樣）；(b) 那個全稱命題是**能力推進所需**。
其餘（具體值、見證、精確常數、對照組）kt 自己算得出來，形式化沒有增益。

### 2.1 實測：現有宣告裡，多少屬於「原因部份」（2026-11-10 起含 `Instances/Termination.lean`；同日刪除 `Reflect/Universe.lean`；2026-11-11 起含 `Reflect/NfNormal.lean`；同日重計補錄 `Instances/ImportGraph.lean` 7 條全稱（未入桶、未登記 Registry，獨立 `lake env lean` 綠）；`Instances/SldComplete.lean` 紅、不計入）

以證明形狀客觀分類（`native_decide`／`decide` 為主體 ⇒ 具體計算；`induction`／`wellFounded`／顯式參數 ⇒ 全稱歸納）：

| 類別 | 條數 | 佔比 | 對應理由 |
|---|---:|---:|---|
| 全稱／歸納（metatheorem 級） | **144**（134＋`Reflect/NfNormal.lean` 3＋`Instances/ImportGraph.lean` 7，2026-11-11 重計） | 25% | ✅ **這就是「原因部份」** |
| 具體計算（`decide`／`native_decide` 的封閉實例） | **382** | 67% | ❌ 超出理由：kt 執行時本來就算得到 |
| 其他（輔助、具體值斷言） | **47** | 8% | 多數超出理由 |
| 合計宣告 / 其中已登記 `Registry` | **573**（=144＋382＋47）/ **466**（2026-11-11 重計；`SldComplete.lean` 紅、1 條 theorem 不計入；`ImportGraph.lean` 11 條宣告計入但不登記 Registry） | — | 登記數 ≠ 全稱數 |

逐檔（行數／全稱／計算／其他）：

| 檔案 | 行 | 全稱 | 計算 | 其他 |
|---|---:|---:|---:|---:|
| `IIT/Schema.lean` | 903 | **38** | 1 | 0 |
| `Reflect/Nbe.lean` | 339 | **8** | 10 | 0 |
| `Reflect/NfNormal.lean` | 110 | **3** | 2 | 5 |
| `Matroid.lean` | 261 | **4** | 12 | 1 |
| `Ordinal.lean` | 539 | **14** | 11 | 11 |
| `Ramsey.lean` | 964 | **17** | 15 | 17 |
| `Graph.lean` | 217 | **11** | 4 | 1 |
| `Instances/Engine.lean` | 499 | **7** | 22 | 1 |
| `Instances/Termination.lean` | 316 | **9** | 3 | 1 |
| `Simplicial.lean` | 366 | **11** | 19 | 0 |
| `Reflect/Link.lean` | 327 | 3 | 19 | 0 |
| `Instances/Coherence.lean` | 544 | 1 | 45 | 1 |
| `IIT/Examples.lean` | 222 | 8 | 25 | 0 |
| `IIT/STLC.lean` | 459 | 0 | 40 | 0 |
| `Instances/Characterize.lean` | 436 | 0 | 40 | 0 |
| `Instances/Compose.lean` | 407 | 0 | 35 | 0 |
| `RamseyEx.lean` | 338 | 0 | 45 | 1 |
| `Unify.lean` | 209 | 0 | 15 | 0 |
| `IIT/Extra.lean` | 53 | 0 | 3 | 3 |
| `Instances/UTerm.lean` | 159 | 0 | 0 | 1 |
| `Reflect/Proof.lean` | 253 | **3** | 16 | 0 |
| `Registry.lean` | 1014 | 0 | 0 | 0 |
| `Instances/ImportGraph.lean`† | 83 | **7** | 0 | 4 |
| `Instances/SldComplete.lean`‡ | 308 | — | — | — |
| **合計** | **9,326**（=9,348 磁碟 − 22 桶檔；其中 9,018 行已編譯綠，308 行為紅檔 SldComplete 僅計行數） | **144**（=134＋NfNormal 3＋ImportGraph 7） | **382**（+2 decide 樣本） | **47**（+5 輔助＋4 ImportGraph 結構／歸納／定義） |

**判讀**：現有形式化的**三分之二**（382/573）證的是「kt 跑一次就知道」的封閉實例。
它們不是錯，只是**不屬於理由**——加一條也不會讓 kt 更被保證。真正的資產是那 144 條。
（†`Instances/ImportGraph.lean`：未入桶、未登記 Registry，獨立 `lake env lean` 綠；O5「誠實版本」的邏輯內核——無環 ⟺ 無互達二元組。‡`Instances/SldComplete.lean`：O2 未完成、`lake build` 紅，1 條 `sld_complete` 僅計行數、不計入宣告分類、不登記。）

---

## 3. 「原因部份」目前真正的缺口：本輪六個能力的 metatheorem（O4 已完成；O1 第一半邊已完成）

2026-11-05～07 這一輪把六個缺口做成了 kt 的可執行定律（第 4 輪後 551/551）；O4（2026-11-10）是六個義務中第一個完成的；O1 的 isBetaNormal 半邊於 2026-11-11 完成（詳下表）：

| # | 證明義務（Lean 陳述草案） | 支撐的能力 | 難度／成本 | 需要的數學 |
|---|---|---|---|---|
| **O1** | `theorem nf_beta_normal (Γ : Ctx) (t : Term) (A : Ty) : check Γ t A → isBetaNormal (nf A t)`＋冪等 `nf (nf t) = nf t`。**isBetaNormal 半邊 ✅ 2026-11-11 完成**（`KtLaws/Reflect/NfNormal.lean`，比陳述更強：對所有項/Fuel/型別成立，不需要 `check` 前提；Registry 登記 466，+2）；**冪等半邊 ❌ 仍未完成**——需要 eval/reify soundness 的 reducibility/logical relation，仍如預估 | 反射（NbE） | 中｜1–2 週 | logical relation（β/η 全型別） |
| **O2** | `theorem sld_complete (e : Env) (g : UTerm) (d : Nat) : solvable e g d ↔ ∃ t : Deriv, deriv e g d t` | 全域實例（SLD） | 高｜2–3 週 | 推導樹歸納 + 路徑去環不改可解性 |
| **O3** | `theorem foldQ_wd (s : ISchema) (h : …) (v w : IVal) : quot s v = quot s w → foldQ s h v = foldQ s h w` | 歸納-歸納（QIIT） | 最高｜3–4 週 | signed representation／等式閉包 |
| **O4** | ✅ **已完成（誠實版本，2026-11-10）** `KtLaws/Instances/Termination.lean`：足夠條件 `measureDecreasing`（body 各變數出現次數點式不增於 head ＋ head 的 ufn 節點嚴格多）⇒ 每步嚴格減少 `uSize` ⇒ 重寫關係良基；`envShow` 四條規則逐一驗明 ⇒ `envShow_terminating`。**注意：原表述「`orientable e → WellFounded (Rewrites e)`」為假**——本倉 kernel 檢查反例 `kt_node_measure_orientation_unsound`：`h(f x, y) ⇒ g(y, y)` 在 `uSize` 上是定向的（4 > 3），一步重寫卻讓項從 6 長到 7。kt 側 `orientable` 只是啟發式，完整主張需化簡序（RPO/KBO） | 全域實例（修補） | DONE | 節點數度量 + 代入閉包公式 |
| **O5** | `theorem imports_acyclic_iff (g : ImportGraph) : (∀ c ∈ scc g, c.length ≤ 1 ∧ ¬ selfLoop c) ↔ Acyclic g`＋拓撲序存在 | 全域實例（模組） | 中｜約 1 週 | SCC／拓撲排序正確性 |
| **O6** | `theorem club_inter (C D : Set Ordinal) : Club C → Club D → Club (C ∩ D)` | 反射（club） | 中高｜1–2 週 | 序數 normal function（無 mathlib，需自建） |

**建議次序：O4 → O1 → O5 → O6 → O2 → O3。**
O4 已於 2026-11-10 完成（誠實版本＋反例）。O1 的 isBetaNormal 半邊已於 2026-11-11 完成
（結構定理，直接由 `reifyN`/`reifyNeuN` 對 Fuel 的同時歸納證得）；冪等半邊仍未完成——
那是 full logical relation（soundness of NbE under βη），工作量最大。**其餘按能力重要性排。**

⚠️ 注意：這六條全部是「**新陳述**」，不是「把 551 條搬過去」。這正是 §1.2 那句話的意思——
要把 kt 的檢查變成定理，靠的不是搬運，是重寫成 metatheorem。

---

## 4. 發生咩事（時間線，據實記錄）

| 日期 | 事件 | 判讀 |
|---|---|---|
| 2026-11-04 | 做 Why3/Z3 pilot（`meta/prove_feasibility.md`），判定「437 條全搬不可行，metatheorem 級要走 Lean」 | 決定正確，理由清楚 |
| 2026-11-04～05 | 建 `lean/` 骨架，開始逐族鏡射 | **偏離開始**：把「取樣升級為全稱」（對）與「逐標籤搬運」（錯）混在一起 |
| 2026-11-05 | 登記 437 個舊標籤「有對應」，492 條定理 | **驗收標準錯**：用定理條數當進度 |
| 2026-11-06 | 文件寫成「437 個舊標籤**全部有對應**」 | 措辭把「人讀對應」講成近似「已形式化」 |
| 2026-11-07 | 本輪 48 條新定律未鏡射；追問後實測：403/580 是具體計算、`Bool ≠ Prop` 無法「變成」 | 事實澄清：**七成工作量不屬於理由** |
| 2026-11-10 | 「Lean 全面複工，把積壓事項全部做」：**O4 完成（誠實版本）**——原命題為假（kernel 反例 `kt_node_measure_orientation_unsound`），落倉為更嚴的 `measureDecreasing ⇒ WellFounded`＋`envShow_terminating`；`Reflect/Universe.lean` 標記 DEPRECATED（§5.3 的 A/C 分支等裁決，未刪除）；Registry 492→505（+13）；docs／UNIVERSAL／賬目同步 | 第一個義務真正落地；**O1/O2/O3/O5/O6 仍未完成**（2026-11-10） |
| 2026-11-10（續） | 使用者裁決：「不另作保存，這是前代理飄離了的殘次工程遺物，由於已多個回合後仍係無用，決定刪除這些多餘物」⇒ **`lean/KtLaws/Reflect/Universe.lean` 實際刪除**（選項 C，無存檔；Nbe.lean 的死 import 一併移除；Registry 505→**464**；UNIVERSAL 146→**134**）。另外使用者明示「O1–O6 全部都要做，不要只做兩條」，驗收 = **每條義務 kernel 綠、無 sorry、登記生效** | 玩具模型結束；O1–O6 為全倉最高優先級未完成項 |
| 2026-11-11 | 使用者裁決「接著進行O1」：**O1 第一半邊落地**——`KtLaws/Reflect/NfNormal.lean`：`reifyN`/`reifyNeuN` 對所有燃料/型別/語義值恆產生 β-正常項（對燃料同時歸納）；`nf_isBetaNormal`（不需型別前提）、`nf_beta_normal`（`check Γ t A = true → isBetaNormal (nf A t)`，保留 O1 陳述形狀）；`KtLaws.lean`、Registry 466（+2 #check）登記生效。**冪等半邊 `nf (nf t) = nf t` 仍未完成**——需要 NbE 相對 βη 的 soundness（reducibility/logical relation），單輪做不完，如實擱置。O2 進行中（`SldComplete.lean` 仍紅、`hasBody_ne` 陳述本身有誤已定位修法，未落地） | O1 不是「整則義務完成」；466 條中 2 條屬性質陳述 |

根因兩條，都在我這邊：
1. **沒有把理由轉成範圍閘**——理由說「只做 metatheorem 級」，實際做了「全部標籤」。
2. **用錯度量**——「定理條數」可以無限增長而不增加對 kt 的約束；正確度量是「本文 §3 那種全稱義務的完成數」。

---

## 5. 能不能用？（判定）

### 5.1 可以用的四件事

1. **144 條全稱陳述 = kt 對應能力的權威規格**（可編譯、可人讀）。這是本倉形式化唯一不可替代的產物。
2. **§3 的六條證明義務清單**：直接告訴下一個人「缺哪裡、要什麼、多少錢」。
3. **邊界反例**（如 `conserv_at_zero_is_false`、「燃料 0 不假裝算出答案」）可當 kt 的負向測試樣板。
4. **骨架可重用**：`Schema.lean`（903 行、38 條全稱）、`Nbe.lean`、`Instances/UTerm.lean` 是日後做
   extraction 或 translation validation 的起點。

### 5.2 不可以用的三件事

1. **不能保證 kt 的執行**：`Bool` 檢查與 `Prop` 命題之間**沒有形式橋**（沒有 refinement、沒有 extraction、
   沒有 translation validation）。「Lean 綠」不蘊含「kt 綠」。
2. **不能放進 CI 當 kt 的閘**：`lake build` 通過與 `moon build` 通過是兩件獨立的事。
3. **不能當形式化進度**：條數（466）與必要性（144）無關；382 條具體計算加進去只會膨脹數字。

### 5.3 建議處置（三選一，等你決定）

| 方案 | 動作 | 本倉留下的東西 |
|---|---|---|
| **A 降級保留** | `lean/` 原地保留，但在 README 明寫「數學筆記，非 kt 的形式化」；只把 144 條全稱清單抽成 `lean/UNIVERSAL.md` | 9,326 行全留 |
| **B 另倉＋精簡（推薦）** | 另開 `kt-proofs` 存整批 9,326 行；本倉只留 `lean/WHY.md`（本檔）、`lean/UNIVERSAL.md`（144 條清單）、`lean/OBLIGATIONS.md`（§3 六條） | 約 3 份文件 |
| **C 全部刪除** | 判定「無用途」⇒ 先另倉存檔，再刪 `lean/`，本倉只留 `lean/WHY.md` 當記錄 | 1 份文件 |

**我的建議是 B**：理由是 §5.1 的四項用途都只需要「全稱清單 + 義務清單 + 骨架引用」，
不需要把 9,326 行留在主倉裡（它現在最大的副作用是被誤讀成「kt 已被形式化」）。

**2026-11-10 裁決（使用者）：** 選項 C 減免存檔——`Reflect/Universe.lean`（41 條，對應的 kt 玩具模型已於
2026-11-07 刪除，現在**兩邊都沒有對應物**）**已刪除、不另作保存**。四個純 `decide` 檔
（`RamseyEx`、`IIT/STLC`、`Instances/Characterize`、`Instances/Compose`）保留。選項 B（另倉）受推送 deferral 限制、未採行。

---

## 6. 立即已做的（不需授權、且不新增任何形式化）

1. 修正三處會造成誤讀的措辭（`README.md`、`lean/README.md`、`lean/labels/coverage.md`）：
   把「437 個舊標籤全部有對應」改成「人讀的族對應；Lean 命題較強；**兩者之間無形式橋**」，
   並標明 403/580 為具體計算。
2. 建立本文件（原因、範圍、缺口、可用性、處置建議）。
3. 在 `meta/CAPABILITIES.md` 加一節指向本文件，避免下次又把「定理條數」當進度。

**已授權（2026-11-10，使用者原話：「lean 全面複工，把積壓事項全部做」；同日再確認：「進行O1,O2,O3,O4,O5,O6 全都需要做，不要只做兩條」）**：§3 的 O1–O6 與 §5.3 處置。驗收標準（同日選定）：**每條義務都要 `lake build` 綠、無 `sorry`、登記表生效**。
2026-11-10 已落實：
- **O4 完成（誠實版本）**：原命題 `orientable e → WellFounded (Rewrites e)` **被證假**——本倉有 kernel 反例。
  落倉為更嚴的充分條件定理（`KtLaws/Instances/Termination.lean`）；`envShow` 全部規則滿足 ⇒ 其重寫終止；
  反例本身成為負測資產 `kt_node_measure_orientation_unsound`。
- **`Reflect/Universe.lean` 已刪除**（2026-11-10 使用者裁決「不另作保存、決定刪除這些多餘物」；Registry 505→464）。
- **O1 的 isBetaNormal 半邊已完成（2026-11-11）**：見 `KtLaws/Reflect/NfNormal.lean`；Registry 464→**466**；docs 同步。
- Registry 492→**505**；UNIVERSAL.md 137→**146**；docs 同步（O1 半邊完成前）。

**仍未完成（2026-11，誠實記錄）**：
- **O1**（`nf_beta_normal`＋冪等）：**第一半邊已於 2026-11-11 完成**（見 `KtLaws/Reflect/NfNormal.lean`：
  `nf_beta_normal : check Γ t A = true → isBetaNormal (nf A t) = true`，kernel 綠、Registry 466 登記、無 sorry——
  實際上不需要 `check` 前提，只是保留 O1 陳述形狀）。**冪等半邊 `nf (nf t) = nf t` 仍未完成**——
  需要 NbE 相對 βη 的 soundness 的 reducibility/logical relation（β/η、全型別），預估 1–2 週。
- **O2**（`sld_complete`）：推導樹歸納＋路徑去環不改可解性，預估 2–3 週，未動工。
- **O3**（`foldQ_wd`）：signed representation／等式閉包，預估 3–4 週，未動工。
- **O5**（`imports_acyclic_iff`）：SCC／拓撲序存在性，無 mathlib 需自建，預估 1 週，未動工。
- **O6**（`club_inter`）：序數 normal function／club 交，無 mathlib 需自建，預估 1–2 週，未動工。
- **§5.3 A／B／C 處置**：未裁決，且 push 的 deferral 使方案 B（另倉）目前不可執行。
- **push**：使用者 2026-11-10 前明確 defer；本輪只本地提交。

分工判斷（避免誤解）：本輪**沒有**把任何 proof 義務「假完成」——`sorry` 沒有被用來粉飾任何義務；
O4 是「把為假原命題記錄為反例，再把可證的嚴格版落倉」的路徑；其餘為如實擱置。
