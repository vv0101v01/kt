/-
  KtLaws/Matroid.lean  —  對應 MoonBit `meta/core/matroid.mbt` 的「duality is an involution」

  MoonBit 側的擬陣用 `Array[Array[Int32]]` 表示基底並在執行期檢查公理；這裡用
  **特徵函數** `Fin n → Bool` 表示子集，於是有兩個好處：

  * 取補集就是 `!`，對合性是 `funext` + 逐點 `cases`，不需要集合重複/排序的簿記；
  * 對偶擬陣 `M*` 的定義（基底取補集）在型別上就是 `List.map compl`，於是
    `dual ∘ dual = id` 是 `List.map_map` 的一行推論。
-/
namespace KtLaws.Matroid

/-- 在 `Fin n` 上的子集，用特徵函數表示。 -/
abbrev Subset (n : Nat) := Fin n → Bool

/-- 取補集。 -/
def Subset.compl {n : Nat} (s : Subset n) : Subset n := fun i => !(s i)

/-- 補集是對合（這是對偶性的一切）。 -/
theorem compl_compl {n : Nat} (s : Subset n) : s.compl.compl = s := by
  funext i
  simp only [Subset.compl]
  cases s i <;> rfl

/-- 子集的大小。 -/
def Subset.card {n : Nat} (s : Subset n) : Nat :=
  (List.finRange n).countP (fun i => s i)

/-- 擬陣：只留基底族（公理在 MoonBit 側以 `check_matroid` 執行期檢查）。 -/
structure Matroid (n : Nat) where
  bases : List (Subset n)

/-- 對偶擬陣：基底取補集。 -/
def Matroid.dual {n : Nat} (M : Matroid n) : Matroid n := ⟨M.bases.map Subset.compl⟩

/-- **對偶是對合**：`M** = M`。 -/
theorem dual_dual {n : Nat} (M : Matroid n) : M.dual.dual = M := by
  obtain ⟨bs⟩ := M
  simp [Matroid.dual, List.map_map, Function.comp_def, compl_compl]

/-- 對偶兩次之後基底逐一相等（不需要結構外延）。 -/
theorem dual_dual_bases {n : Nat} (M : Matroid n) : M.dual.dual.bases = M.bases := by
  rw [dual_dual]

/-- 具體例子：`Fin 2` 上只有一個基底 `{0}` 的擬陣，對偶的基底是 `{1}`。 -/
def tiny : Matroid 2 := ⟨[fun i => i == 0]⟩

/-- `tiny` 的對偶基底就是補集。 -/
theorem tiny_dual : tiny.dual.bases = [fun i => !(i == 0)] := rfl

/-- `tiny** = tiny`，並且基底大小守恆（`0` 補成 `1`）。 -/
theorem tiny_involution : tiny.dual.dual = tiny := dual_dual tiny


/-! ### 具體擬陣：圖擬陣（貪心最優）、對偶秩、Q 上的線性擬陣 -/

/-- 以位元遮罩表示的 4 元子集（`Fin 16 → Subset 4`）。 -/
def mask4 (m : Fin 16) : Subset 4 := fun i => (m.val / 2 ^ i.val) % 2 == 1

/-- 三角形 + 一條尾巴：4 頂點 4 邊。 -/
def gsrc : Fin 4 → Nat
  | ⟨0, _⟩ => 0
  | ⟨1, _⟩ => 1
  | ⟨2, _⟩ => 0
  | ⟨3, _⟩ => 2

def gdst : Fin 4 → Nat
  | ⟨0, _⟩ => 1
  | ⟨1, _⟩ => 2
  | ⟨2, _⟩ => 2
  | ⟨3, _⟩ => 3

/-- 單條邊的相鄰關係（無向）。 -/
def adj1 (s : Subset 4) (i j : Fin 4) : Bool :=
  (List.finRange 4).any (fun e =>
    s e && (((gsrc e == i.val) && (gdst e == j.val)) ||
            ((gsrc e == j.val) && (gdst e == i.val))))

/-- 走 `k` 步內可達。 -/
def reachIter (s : Subset 4) : Nat → Fin 4 → Fin 4 → Bool
  | 0 => fun i j => i == j
  | k + 1 => fun i j =>
      reachIter s k i j ||
        ((List.finRange 4).any (fun m => reachIter s k i m && adj1 s m j))

/-- 連通（4 個頂點走 4 步足夠）。 -/
def conn (s : Subset 4) (i j : Fin 4) : Bool := reachIter s 4 i j

/-- 頂點 `i` 是其連通塊裡編號最小的點。 -/
def isFirst (s : Subset 4) (i : Fin 4) : Bool :=
  (List.finRange 4).all (fun j => !(conn s i j) || decide (i.val ≤ j.val))

/-- 連通塊個數。 -/
def numComp (s : Subset 4) : Nat := (List.finRange 4).countP (isFirst s)

/-- 圖擬陣的秩：`r(S) = |V| − #連通塊`。 -/
def gRank (s : Subset 4) : Nat := 4 - numComp s

/-- 子集大小。 -/
theorem card_eq (s : Subset 4) : s.card = (List.finRange 4).countP (fun i => s i) := rfl

/-- 獨立 = 秩等於大小（森林）。 -/
def indepG (s : Subset 4) : Bool := gRank s == s.card

/-- 子集包含（`s ⊆ t`）。 -/
def subsetLe (s t : Subset 4) : Bool := (List.finRange 4).all (fun i => !(s i) || t i)

/-- 聯集。 -/
def unionS (s t : Subset 4) : Subset 4 := fun i => s i || t i

/-- 交集。 -/
def interS (s t : Subset 4) : Subset 4 := fun i => s i && t i

/-- **圖擬陣的秩**：`r(E) = 3`（生成樹 3 條邊）。 -/
theorem graphic_rank_full : gRank (mask4 15) = 3 := by
  decide

/-- 秩公理（R1 空集秩為零、R2 單調、R3 次模）在圖擬陣上全部成立。 -/
theorem graphic_rank_axioms :
    (gRank (mask4 0) = 0) ∧
    (∀ m t : Fin 16, subsetLe (mask4 m) (mask4 t) = true → gRank (mask4 m) ≤ gRank (mask4 t)) ∧
    (∀ m t : Fin 16,
      gRank (mask4 m) + gRank (mask4 t)
        ≥ gRank (unionS (mask4 m) (mask4 t)) + gRank (interS (mask4 m) (mask4 t))) := by
  refine ⟨by decide, ?_, ?_⟩
  · decide
  · decide

/-- 獨立集交換公理（增廣）：`|I| < |J|` ⇒ 可把 `J \ I` 的某元素加進 `I` 保持獨立。 -/
theorem graphic_exchange :
    ∀ m t : Fin 16, indepG (mask4 m) = true → indepG (mask4 t) = true →
      (mask4 m).card < (mask4 t).card →
      ∃ e : Fin 4, mask4 t e = true ∧ mask4 m e = false ∧
        indepG (fun i => mask4 m i || decide (i = e)) = true := by
  decide


/-- 在「未考慮」的邊中挑權重最大者。 -/
def pickMax (cons : Subset 4) (w : Fin 4 → Nat) : Option (Fin 4) :=
  (List.finRange 4).foldl
    (fun acc e =>
      if cons e then acc
      else
        match acc with
        | none => some e
        | some b => if w b < w e then some e else acc)
    none

/-- 貪心的一步：挑權重最大的未考慮邊，能加就加。 -/
def greedyAux (w : Fin 4 → Nat) : Nat → Subset 4 → Subset 4 → Subset 4
  | 0, chosen, _ => chosen
  | k + 1, chosen, cons =>
      match pickMax cons w with
      | none => chosen
      | some e =>
          let cons' : Subset 4 := fun i => cons i || decide (i = e)
          let cand : Subset 4 := fun i => chosen i || decide (i = e)
          greedyAux w k (if indepG cand then cand else chosen) cons'

/-- 按權重非增的貪心。 -/
def greedy (w : Fin 4 → Nat) : Subset 4 := greedyAux w 4 (fun _ => false) (fun _ => false)

/-- 子集在權重下的總重。 -/
def weight (s : Subset 4) (w : Fin 4 → Nat) : Nat :=
  ((List.finRange 4).map (fun i => if s i then w i else 0)).sum

/-- 暴力最佳：枚舉全部 16 個子集。 -/
def bruteMax (w : Fin 4 → Nat) : Nat :=
  (List.finRange 16).foldl
    (fun best m => if indepG (mask4 m) then max best (weight (mask4 m) w) else best) 0

/-- 由四個數字造出權重函式。 -/
def wfun (a b c d : Nat) : Fin 4 → Nat
  | ⟨0, _⟩ => a
  | ⟨1, _⟩ => b
  | ⟨2, _⟩ => c
  | ⟨3, _⟩ => d

/-- **圖擬陣的貪心是最優的**：對所有 `4⁴` 種權重，貪心的總重 = 暴力最佳，
而且貪心一定數出一棵生成樹（秩 3）。 -/
theorem graphic_greedy_optimal :
    ∀ a b c d : Fin 4,
      weight (greedy (wfun a.val b.val c.val d.val)) (wfun a.val b.val c.val d.val)
          = bruteMax (wfun a.val b.val c.val d.val) ∧
      gRank (greedy (wfun a.val b.val c.val d.val)) = 3 := by
  decide

/-- 對偶秩：`r*(S) = |S| + r(E∖S) − r(E)`。 -/
def dualRank (r : Subset 4 → Nat) (s : Subset 4) : Nat :=
  s.card + r (fun i => !(s i)) - r (mask4 15)

/-- **秩補公式**：`r*(E) = |E| − r(E)`（`4 − 3 = 1`）。 -/
theorem dual_rank_complement : dualRank gRank (mask4 15) = 4 - gRank (mask4 15) := by
  decide

/-- **對偶是對合（秩函式版）**：`r** = r`。 -/
theorem dual_dual_rank : ∀ m : Fin 16, dualRank (dualRank gRank) (mask4 m) = gRank (mask4 m) := by
  decide

/-- 對偶擬陣也滿足獨立集交換公理（⇒ 它仍是擬陣）。 -/
theorem dual_exchange :
    ∀ m t : Fin 16,
      dualRank gRank (mask4 m) = (mask4 m).card →
      dualRank gRank (mask4 t) = (mask4 t).card →
      (mask4 m).card < (mask4 t).card →
      ∃ e : Fin 4, mask4 t e = true ∧ mask4 m e = false ∧
        dualRank gRank (fun i => mask4 m i || decide (i = e)) = (mask4 m).card + 1 := by
  decide


/-- 以位元遮罩表示的 3 元子集。 -/
def mask3 (m : Fin 8) : Subset 3 := fun i => (m.val / 2 ^ i.val) % 2 == 1

/-- 線性擬陣的三個行向量：(1,0)、(0,1)、(1,1) ∈ ℚ²（用整數對表示，避免除法簿記）。 -/
def col : Fin 3 → Int × Int
  | ⟨0, _⟩ => (1, 0)
  | ⟨1, _⟩ => (0, 1)
  | ⟨2, _⟩ => (1, 1)

/-- 二維叉積（判斷兩向量是否線性相依）。 -/
def crossZ (u v : Int × Int) : Int := u.1 * v.2 - u.2 * v.1

/-- 子集裡的第一個元素。 -/
def firstOf (s : Subset 3) : Option (Fin 3) := (List.finRange 3).find? (fun i => s i)

/-- 行向量的秩：空集 0；全與首個行平行 1；否則 2。 -/
def lRank (s : Subset 3) : Nat :=
  match firstOf s with
  | none => 0
  | some i =>
    if (List.finRange 3).all (fun j => !(s j) || (crossZ (col j) (col i) == 0)) then 1 else 2

/-- 線性獨立 = 秩等於個數。 -/
def indepL (s : Subset 3) : Bool := lRank s == s.card

/-- `x` 落在 `s` 的閉包裡（加上 `x` 不改變秩）。 -/
def inClosure (s : Subset 3) (x : Fin 3) : Bool :=
  lRank (fun i => s i || decide (i = x)) == lRank s

/-- **Q 上線性擬陣的秩**：三行整體的秩是 2（第三行落在前兩行的張成裡）。 -/
theorem linear_rank_full : lRank (mask3 7) = 2 := by
  decide

/-- `{0,1}` 獨立、`{0,1,2}` 相依。 -/
theorem linear_indep :
    indepL (mask3 3) = true ∧ indepL (mask3 7) = false := by
  decide

/-- `{0,1}` 的閉包是全部三點（`1·(1,0) + 1·(0,1) = (1,1)`）。 -/
theorem linear_closure : ∀ x : Fin 3, inClosure (mask3 3) x = true := by
  decide

/-- 線性擬陣滿足獨立集交換公理。 -/
theorem linear_exchange :
    ∀ m t : Fin 8, indepL (mask3 m) = true → indepL (mask3 t) = true →
      (mask3 m).card < (mask3 t).card →
      ∃ e : Fin 3, mask3 t e = true ∧ mask3 m e = false ∧
        indepL (fun i => mask3 m i || decide (i = e)) = true := by
  decide

end KtLaws.Matroid
