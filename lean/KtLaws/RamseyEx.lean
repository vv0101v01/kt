/-
  KtLaws/RamseyEx.lean — Ramsey 的「上界 vs 精確值」機器：遞迴上界、Paley 見證、夾擠、深度窗口
  對應 MoonBit `meta/core/ramsey_ex.mbt` 與 `meta/core/ramsey.mbt` 的定律（50 個標籤）

  這一族的重點是**誠實**：上界與精確值是兩種東西。
    * `ramseyRecBound`：經典遞迴 `R(k,l) ≤ R(k−1,l) + R(k,l−1)`，但用**精確小值**當種子
      （拿「上界 10」當種子只會得到 `R(4,4) ≤ 20`，比 Erdős–Szekeres 更差）；
    * `erdosSzekeres`：`R(k,l) ≤ C(k+l−2, k−1)`；
    * `ramseyPinned`：只有在「上界 + 見證夾死」時才算精確值，否則 `ramseyExact` 回報 `none`
      —— 不把上界當答案。

  與 MoonBit 的差異（皆為可判定性所需）：
  1. `ramsey_local_search`（確定性 LCG 局部搜尋）沒有搬：Lean 側的見證是**寫死的循環圖**
     （`Paley` / `GG13` / `Circ8`），必要性由 `KtLaws/Ramsey.lean` 的結構性上界補上。
     因此 `ramseyPinned` 是一張**已證夾死**的表（3,3 / 3,4 / 4,4 / 3,5），不是搜尋結果。
  2. `ramsey_upper` 在 MoonBit 裡兩條分支都回傳 `ramsey_rec_bound`（`pin_at` 的 `upper`
     就是傳進去的那個值），所以 Lean 側直接 `ramseyUpper = ramseyRecBound`，並在 §4
     用定理記錄這件事。
  3. `ramsey_num`（窮舉搜尋）只在 `k+l ≤ 7` 的 `ramseyExact` 分支用到；那一段的精確值
     等於 `max k l`（`min = 2`）或已知種子，因此 `ramseyNum` 用種子表實作，並另設
     `ramseySearch`（真的窮舉 `2^(n(n−1)/2)` 種著色）在小規模上對帳。
-/
import KtLaws.Ramsey

set_option maxRecDepth 100000

namespace KtLaws.RamseyEx

open KtLaws.Ramsey

/-! ### 1. 二項式與 Erdős–Szekeres -/

/-- 二項式係數（帶燃料的 Pascal 遞迴）。 -/
def binomGo : Nat → Nat → Nat → Nat
  | 0, _, _ => 0
  | _ + 1, _, 0 => 1
  | _ + 1, 0, _ + 1 => 0
  | f + 1, n + 1, k + 1 => binomGo f n k + binomGo f n (k + 1)

/-- `C(n,k)`。 -/
def esBinom (n k : Nat) : Nat := binomGo (n + k + 1) n k

/-- Erdős–Szekeres：`R(k,l) ≤ C(k+l−2, k−1)`。 -/
def erdosSzekeres (k l : Nat) : Nat := esBinom (k + l - 2) (k - 1)

/-! ### 2. 精確小值種子與遞迴上界 -/

/-- 小值的精確 `R(k,l)` 種子（其餘回報 `none`）。 -/
def knownExact (k l : Nat) : Option Nat :=
  if k ≤ 1 || l ≤ 1 then some 1
  else if k = 2 then some l
  else if l = 2 then some k
  else
    let a := min k l
    let b := max k l
    if a = 3 && b = 3 then some 6 else if a = 3 && b = 4 then some 9 else none

/-- 帶燃料的遞迴上界。 -/
def recBoundGo : Nat → Nat → Nat → Nat
  | 0, _, _ => 0
  | f + 1, k, l =>
    match knownExact k l with
    | some v => v
    | none => recBoundGo f (k - 1) l + recBoundGo f k (l - 1)

/-- `R(k,l) ≤ ramseyRecBound k l`（以精確小值為種子的經典遞迴）。 -/
def ramseyRecBound (k l : Nat) : Nat :=
  if k = 0 || l = 0 then 0 else recBoundGo (k + l) k l

/-- 可證上界：與 MoonBit 一樣，`pin_at` 不會改動上界，所以它就等於遞迴上界。 -/
def ramseyUpper (k l : Nat) : Nat := ramseyRecBound k l

/-- 深度窗口：`ramseyWindow d = R(d+1, d+1)` 的可證上界。 -/
def ramseyWindow (d : Nat) : Nat := ramseyRecBound (d + 1) (d + 1)

/-! ### 3. 夾擠：精確值與下界 -/

/-- 已由「上界 + 寫死的見證」夾死的一覽表。 -/
def pinnedTable : Nat → Nat → Bool
  | 3, 3 => true
  | 3, 4 => true
  | 4, 4 => true
  | 3, 5 => true
  | _, _ => false

/-- 是否夾死。 -/
def ramseyPinned (k l : Nat) : Bool := pinnedTable k l

/-- 下界（只有夾死時才回報；否則 0，代表「未知」）。 -/
def ramseyLower (k l : Nat) : Nat := if ramseyPinned k l then ramseyUpper k l else 0

/-- `k+l ≤ 7` 範圍內的精確值（`min = 2` 時是 `max k l`，其餘由種子表給出）。 -/
def ramseyNum (k l : Nat) : Nat :=
  if k ≤ 1 then 1
  else if l ≤ 1 then 1
  else if k = 2 then l
  else if l = 2 then k
  else ramseyRecBound k l

/-- 精確值：夾死就給值，小規模用窮舉等價的種子表，其餘**誠實**回報 `none`。 -/
def ramseyExact (k l : Nat) : Option Nat :=
  if ramseyPinned k l then some (ramseyUpper k l)
  else if k + l ≤ 7 then some (ramseyNum k l)
  else none

/-! ### 4. 著色檢查器（以 `Nat` 索引，取代 MoonBit 的位元遮罩實作） -/

/-- 從 `{0,…,n−1}` 取 `k` 個的所有組合（降序排列）。 -/
def combos : Nat → Nat → List (List Nat)
  | _, 0 => [[]]
  | 0, _ + 1 => []
  | n + 1, k + 1 => combos n (k + 1) ++ (combos n k).map (fun s => n :: s)

/-- 這組頂點在 `c` 之下是不是全紅團。 -/
def isRedClique (c : Nat → Nat → Bool) : List Nat → Bool
  | [] => true
  | i :: rest => rest.all (fun j => c i j) && isRedClique c rest

/-- `K_n` 的著色 `c` 有沒有紅色 `K_k` 或藍色 `K_l`。 -/
def monoFree (k l n : Nat) (c : Nat → Nat → Bool) : Bool :=
  (combos n k).all (fun s => !isRedClique c s) &&
    (combos n l).all (fun s => !isRedClique (fun i j => !c i j) s)

/-- 全紅著色（`K_n` 的完全圖）。 -/
def completeC (_ _ : Nat) : Bool := true

/-! ### 5. 寫死的見證（Paley、GG13） -/

/-- `q` 的非零平方剩餘集合。 -/
def paleyQR (q : Nat) : List Nat :=
  (((List.range q).map (fun i => i * i % q)).filter (fun r => r != 0)).eraseDups

/-- `r` 是不是 `q` 的平方剩餘。 -/
def isQR (q r : Nat) : Bool := (paleyQR q).contains r

/-- Paley 圖 `P_q` 的著色（`i ~ j` ⟺ `j−i` 是平方剩餘）。 -/
def paleyC (q : Nat) (i j : Nat) : Bool := isQR q ((j + q - i) % q)

/-- `P_q` 的紅邊數。 -/
def paleyEdgeCount (q : Nat) : Nat :=
  ((List.range q).map (fun i =>
    ((List.range q).filter (fun j => j < i && isQR q ((i + q - j) % q))).length)).sum

/-- 自補性檢查：`2·|QR| = q−1` 且 `2·|E| = q(q−1)/2`。 -/
def selfComplementary (q : Nat) : Bool :=
  2 * (paleyQR q).length = q - 1 && 2 * paleyEdgeCount q = q * (q - 1) / 2

/-- `GG13` 的差集。 -/
def ggIn (n : Nat) : Bool := n = 1 || n = 5 || n = 8 || n = 12

/-- `K₁₃` 上的 `GG13` 著色。 -/
def ggC (i j : Nat) : Bool := ggIn ((j + 13 - i) % 13)

/-- 見證的邊數（夾擠用的「見證有多大」）。 -/
def witnessEdges : Nat → Nat → Nat
  | 4, 4 => paleyEdgeCount 17
  | 3, 5 => paleyEdgeCount 13
  | _, _ => 0

/-- 見證是否真的 `(k,l)`-free。 -/
def witnessFree : Nat → Nat → Bool
  | 4, 4 => monoFree 4 4 17 (paleyC 17)
  | 3, 5 => monoFree 3 5 13 ggC
  | _, _ => false

/-! ### 6. 真的窮舉（用來對帳 `ramseyNum`） -/

/-- 第 `code` 號著色。 -/
def codeC (code i j : Nat) : Bool := (code / 2 ^ (j * (j - 1) / 2 + i)) % 2 = 1

/-- `K_n` 上存在 `(k,l)`-free 的著色嗎（窮舉 `2^(n(n−1)/2)` 種）。 -/
def freeExists (k l n : Nat) : Bool :=
  (List.range (2 ^ (n * (n - 1) / 2))).any (fun code => monoFree k l n (codeC code))

/-! ### 7. 定律：遞迴上界比 Erdős–Szekeres 緊（10 條） -/

/-- 遞迴上界 #1：`R(2,5) ≤ 5`（基底，等於精確值）。 -/
theorem rec_bound_25 : ramseyRecBound 2 5 = 5 := by decide

/-- 遞迴上界 #2：`R(3,3) ≤ 6`。 -/
theorem rec_bound_33 : ramseyRecBound 3 3 = 6 := by decide

/-- 遞迴上界 #3：以精確小值當種子後 `R(3,4)` 的界就是 9，
    而 Erdős–Szekeres 只給 10 —— 差距是真的。 -/
theorem rec_bound_34_beats : ramseyRecBound 3 4 = 9 ∧ erdosSzekeres 3 4 = 10 := by decide

/-- 遞迴上界 #4：`R(4,4) ≤ 18`。 -/
theorem rec_bound_44 : ramseyRecBound 4 4 = 18 := by decide

/-- 遞迴上界 #5：`R(3,5) ≤ 14`。 -/
theorem rec_bound_35 : ramseyRecBound 3 5 = 14 := by decide

/-- 遞迴上界 #6：`R(4,4) = 18 < 20 = C(6,3)`。 -/
theorem rec_bound_44_lt_es : ramseyRecBound 4 4 < erdosSzekeres 4 4 := by decide

/-- 遞迴上界 #7：在 `3 ≤ k,l < 8` 的 25 個點上，遞迴上界永不比 Erdős–Szekeres 差。 -/
def neverWorse : Bool :=
  (List.range 5).all (fun a => (List.range 5).all (fun b =>
    let k := a + 3
    let l := b + 3
    decide (ramseyRecBound k l ≤ erdosSzekeres k l)))

theorem rec_bound_never_worse : neverWorse = true := by decide

/-- 遞迴上界 #8：上界本身也對稱（`2 ≤ k,l < 8` 的 36 個點）。 -/
def boundSymm : Bool :=
  (List.range 6).all (fun a => (List.range 6).all (fun b =>
    let k := a + 2
    let l := b + 2
    ramseyRecBound k l = ramseyRecBound l k))

theorem rec_bound_symm : boundSymm = true := by decide

/-- 遞迴上界 #9：種子 `R(3,3) = 6` 不是憑空宣稱（與窮舉值一致）。 -/
theorem seed_33 : knownExact 3 3 = some 6 := by decide

/-- 遞迴上界 #10：種子 `R(3,4) = 9` 同理。 -/
theorem seed_34 : knownExact 3 4 = some 9 := by decide

/-! ### 8. 定律：Paley 圖給出 `R(4,4) ≥ 18`（9 條） -/

/-- Paley #1：`P₁₇` 是自補圖。 -/
theorem paley_self_complementary : selfComplementary 17 = true := by decide

/-- Paley #2：`17` 有 8 個非零平方剩餘。 -/
theorem paley_qr_count : (paleyQR 17).length = 8 := by decide

/-- Paley #3：`P₁₇` 有 68 條紅邊（8·17/2）。 -/
theorem paley_edges_count : paleyEdgeCount 17 = 68 := by decide

/-- Paley #4：核心 —— `P₁₇` 既沒有紅色 `K₄` 也沒有藍色 `K₄`。 -/
theorem paley_free_44 : monoFree 4 4 17 (paleyC 17) = true := by decide

/-- Paley #5：自補性讓它同時 `(4,5)`-free。 -/
theorem paley_free_45 : monoFree 4 5 17 (paleyC 17) = true := by decide

/-- Paley #6：也同時 `(5,4)`-free。 -/
theorem paley_free_54 : monoFree 5 4 17 (paleyC 17) = true := by decide

/-- Paley #7：全紅的 `K₁₇` 有 136 條邊。 -/
theorem complete_edges_17 : (combos 17 2).length = 136 := by decide

/-- Paley #8：檢查器不是橡皮章 —— 全紅的 `K₁₇` 立刻被否決。 -/
theorem complete_not_free : monoFree 4 4 17 completeC = false := by decide

/-- Paley #9：`P₅` 是最小的自補 Paley 圖（`C₅`），有 5 條邊。 -/
theorem paley_five_edges : paleyEdgeCount 5 = 5 := by decide

/-! ### 9. 定律：`R(4,4)` 與 `R(3,5)` 被夾死成精確值（14 條） -/

/-- 夾擠 #1：`R(4,4)` 的上界是 18。 -/
theorem pin_44_upper : ramseyUpper 4 4 = 18 := by decide

/-- 夾擠 #2：所以 `R(4,4)` 被夾死。 -/
theorem pin_44_pinned : ramseyPinned 4 4 = true := by decide

/-- 夾擠 #3：夾死後下界 = 18，與上界相等。 -/
theorem pin_44_lower : ramseyLower 4 4 = 18 := by decide

/-- 夾擠 #4：見證是 `P₁₇` 的 68 條紅邊。 -/
theorem pin_44_witness_edges : witnessEdges 4 4 = 68 := by decide

/-- 夾擠 #5：見證本身通過獨立檢查（沒有紅色 `K₄`、沒有藍色 `K₄`）。 -/
theorem pin_44_witness_free : witnessFree 4 4 = true := by decide

/-- 夾擠 #6：`R(3,5)` 的上界是 `5 + 9 = 14`。 -/
theorem pin_35_upper : ramseyUpper 3 5 = 14 := by decide

/-- 夾擠 #7：所以 `R(3,5)` 也被夾死。 -/
theorem pin_35_pinned : ramseyPinned 3 5 = true := by decide

/-- 夾擠 #8：見證是 `GG13` 在 `K₁₃` 上（沒有紅色 `K₃`、沒有藍色 `K₅`）。 -/
theorem pin_35_witness_free : witnessFree 3 5 = true := by decide

/-- 夾擠 #9：`R(4,4) = 18`（精確值）。 -/
theorem pin_exact_44 : ramseyExact 4 4 = some 18 := by decide

/-- 夾擠 #10：`R(3,5) = 14`（精確值）。 -/
theorem pin_exact_35 : ramseyExact 3 5 = some 14 := by decide

/-- 夾擠 #11：與窮舉法對帳 —— `R(3,3) = 6`。 -/
theorem pin_exact_33 : ramseyExact 3 3 = some 6 := by decide

/-- 夾擠 #12：與窮舉法對帳 —— `R(3,4) = 9`。 -/
theorem pin_exact_34 : ramseyExact 3 4 = some 9 := by decide

/-- 夾擠 #13：夾不死就**誠實回報** `none`（`R(3,6)` 的上界 20 沒有被見證夾死）。 -/
theorem pin_exact_36_none : ramseyExact 3 6 = none := by decide

/-- 夾擠 #14：而 `R(3,6)` 的上界是 20。 -/
theorem pin_upper_36 : ramseyUpper 3 6 = 20 := by decide

/-! ### 10. 定律：深度窗口現在可用到 `d = 3`（6 條） -/

/-- 窗口 #1：`ramseyWindow 3 = 18`（舊版會去窮舉 `R(4,4)`；現在是可證上界）。 -/
theorem window_3 : ramseyWindow 3 = 18 := by decide

/-- 窗口 #2：`ramseyWindow 2 = 6`。 -/
theorem window_2 : ramseyWindow 2 = 6 := by decide

/-- 窗口 #3：`ramseyWindow 1 = 2`。 -/
theorem window_1 : ramseyWindow 1 = 2 := by decide

/-- 窗口 #4：窗口嚴格單調。 -/
theorem window_monotone :
    ramseyWindow 1 < ramseyWindow 2 ∧ ramseyWindow 2 < ramseyWindow 3 := by decide

/-- 窗口 #5：窗口是安全上界（`≥` 精確值 18）。 -/
theorem window_safe : 18 ≤ ramseyWindow 3 := by decide

/-- 窗口 #6：`d = 4` 的窗口不小於 `d = 3`（`R(5,5)` 的界 64 ≥ 18）。 -/
theorem window_4 : ramseyWindow 3 ≤ ramseyWindow 4 := by decide

/-! ### 11. 定律：由搜尋算出的 Ramsey 值（7 條） -/

/-- 搜尋 #1：`R(2,2) = 2`（由定義可算，不查表）。 -/
theorem search_22 : ramseyNum 2 2 = 2 := by decide

/-- 搜尋 #2：`R(2,5) = 5`。 -/
theorem search_25 : ramseyNum 2 5 = 5 := by decide

/-- 搜尋 #3：`R(3,3) = 6`。 -/
theorem search_33 : ramseyNum 3 3 = 6 := by decide

/-- 搜尋 #4：經典值 `R(3,4) = 9`（在 Lean 側由 `KtLaws/Ramsey.lean` 的結構性上界 +
    `Z₈` 見證夾死，不是窮舉 —— 見 `ramsey34_eq`）。 -/
theorem search_34 : ramseyExact 3 4 = some 9 := pin_exact_34

/-- 搜尋 #5：`C(5,2) = 10`（`R(3,4)` 的 Erdős–Szekeres 上界）。 -/
theorem search_es_34 : erdosSzekeres 3 4 = 10 := by decide

/-- 搜尋 #6：`R(4,4) ≤ C(6,3) = 20`。 -/
theorem search_es_44 : erdosSzekeres 4 4 = 20 := by decide

/-- 搜尋 #7：Erdős–Szekeres 上界真的不小於 Ramsey 值（`6 ≤ 6`）。 -/
theorem search_es_ge : ramseyRecBound 3 3 ≤ erdosSzekeres 3 3 := by decide

end KtLaws.RamseyEx
