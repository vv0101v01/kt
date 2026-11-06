import KtLaws.Graph

/-
  KtLaws/Ramsey.lean  —  對應 MoonBit `meta/core/ramsey.mbt` / `meta/core/ramsey_ex.mbt`

  Ramsey 下界的**見證**部分：P₁₇（Paley）給 R(4,4) ≥ 18，Z₈ 的差集 {±1,4}
   circulant 著色給 R(3,4) ≥ 9。上界（R(4,4) ≤ 18、R(3,4) ≤ 9）不在這批裡。

  兩個技術決定，都寫在這裡以免日後誤讀：

  1. 沒有 Mathlib（core 沒有 `Finset`），所以團用「遞增四元組 + 六條邊全紅/全藍」表述。
  2. `Fin 17` 上的四變數量化在 kernel `decide` 下太慢（本機 > 5 分鐘），所以先用一個
     **Bool 檢查器** `monoFree4` 走 `native_decide`（0.5 秒），再證一條 soundness
     引理把檢查器的 `true` 翻譯回數學陳述。定理本身是數學陳述，檢查器只是證據的產生方式。
-/
namespace KtLaws.Ramsey

set_option maxRecDepth 100000
-- 鴿籠要對 9 個布林變數做 `native_decide`，預設的實例搜尋深度不夠
set_option synthInstance.maxSize 400

/-! ### 著色 -/

/-- mod 17 的二次剩餘（不含 0）。 -/
def inQR17 (n : Nat) : Bool :=
  n == 1 || n == 2 || n == 4 || n == 8 || n == 9 || n == 13 || n == 15 || n == 16

/-- Paley 圖 P₁₇ 的紅邊：`(j - i) mod 17` 是二次剩餘。 -/
def Paley (i j : Fin 17) : Bool := inQR17 ((j.val + 17 - i.val) % 17)

/-- 差集 `{±1, 4} ⊂ Z₈`。 -/
def inDiff8 (n : Nat) : Bool := n == 1 || n == 4 || n == 7

/-- `K₈` 的 circulant 紅邊。 -/
def Circ8 (i j : Fin 8) : Bool := inDiff8 ((j.val + 8 - i.val) % 8)

/-- 紅邊數（只數 `i < j`）。 -/
def countEdges {n : Nat} (c : Fin n → Fin n → Bool) : Nat :=
  ((List.finRange n).flatMap (fun i => (List.finRange n).map (fun j => (i, j)))).countP
    (fun p => p.1 < p.2 && c p.1 p.2)

/-! ### 單色子圖 -/

/-- 四點 `a < b < c < d` 全紅。 -/
def Red4 {n : Nat} (c : Fin n → Fin n → Bool) (a b d e : Fin n) : Bool :=
  c a b && c a d && c a e && c b d && c b e && c d e

/-- 四點 `a < b < c < d` 全藍。 -/
def Blue4 {n : Nat} (c : Fin n → Fin n → Bool) (a b d e : Fin n) : Bool :=
  !c a b && !c a d && !c a e && !c b d && !c b e && !c d e

/-- 三點 `a < b < c` 全紅。 -/
def Red3 {n : Nat} (c : Fin n → Fin n → Bool) (a b d : Fin n) : Bool :=
  c a b && c a d && c b d

/--
可計算的「沒有單色 K₄」檢查器：枚舉所有遞增四元組，要求至少一種顏色被破壞。
-/
def monoFree4 {n : Nat} (c : Fin n → Fin n → Bool) : Bool :=
  (List.finRange n).all fun a =>
    (List.finRange n).all fun b =>
      (List.finRange n).all fun d =>
        (List.finRange n).all fun e =>
          !(a < b && b < d && d < e) || (!(Red4 c a b d e) && !(Blue4 c a b d e))

/-- **檢查器 soundness**：`monoFree4 c = true` 等價於「沒有單色 K₄」。 -/
theorem monoFree4_sound {n : Nat} {c : Fin n → Fin n → Bool} (h : monoFree4 c = true)
    (a b d e : Fin n) (hab : a < b) (hbd : b < d) (hde : d < e) :
    Red4 c a b d e = false ∧ Blue4 c a b d e = false := by
  have h1 : ∀ x ∈ List.finRange n, ((List.finRange n).all fun b =>
      (List.finRange n).all fun d =>
        (List.finRange n).all fun e =>
          !(x < b && b < d && d < e) || (!(Red4 c x b d e) && !(Blue4 c x b d e))) = true :=
    List.all_eq_true.mp h
  have h2 : ∀ y ∈ List.finRange n, ((List.finRange n).all fun d =>
      (List.finRange n).all fun e =>
        !(a < y && y < d && d < e) || (!(Red4 c a y d e) && !(Blue4 c a y d e))) = true :=
    List.all_eq_true.mp (h1 a (List.mem_finRange a))
  have h3 : ∀ z ∈ List.finRange n, ((List.finRange n).all fun e =>
      !(a < b && b < z && z < e) || (!(Red4 c a b z e) && !(Blue4 c a b z e))) = true :=
    List.all_eq_true.mp (h2 b (List.mem_finRange b))
  have h4 : (!(a < b && b < d && d < e) || (!(Red4 c a b d e) && !(Blue4 c a b d e))) = true :=
    List.all_eq_true.mp (h3 d (List.mem_finRange d)) e (List.mem_finRange e)
  have hlt : (a < b && b < d && d < e) = true := by
    simp [hab, hbd, hde]
  rw [hlt, Bool.not_true] at h4
  simp only [Bool.false_or, Bool.and_eq_true] at h4
  exact ⟨by simpa using h4.1, by simpa using h4.2⟩

/-! ### Paley P₁₇ -/

/-- P₁₇ 有 `8 · 17 / 2 = 68` 條紅邊。 -/
theorem paley_red_edges : countEdges Paley = 68 := by native_decide

/-- 著色對稱（`r` 是二次剩餘 iff `17 - r` 也是；`7² = 49 ≡ -2` 這類配對都成對）。 -/
theorem paley_symm (i j : Fin 17) : Paley i j = Paley j i := by
  revert i j
  native_decide

/-- **R(4,4) ≥ 18**：P₁₇ 上沒有單色 K₄（檢查器 + soundness 引理）。 -/
theorem paley17_no_mono_K4 :
    (∀ a b c d : Fin 17, a < b → b < c → c < d → Red4 Paley a b c d = false) ∧
    (∀ a b c d : Fin 17, a < b → b < c → c < d → Blue4 Paley a b c d = false) := by
  have h : monoFree4 Paley = true := by native_decide
  exact ⟨fun a b c d hab hbc hcd => (monoFree4_sound h a b c d hab hbc hcd).1,
    fun a b c d hab hbc hcd => (monoFree4_sound h a b c d hab hbc hcd).2⟩

/-! ### Z₈ 的 circulant 著色 -/

/-- 12 條紅邊（`3 · 8 / 2`）。 -/
theorem circ8_red_edges : countEdges Circ8 = 12 := by native_decide

/-- 沒有紅色 K₃。 -/
theorem circ8_no_red3 : ∀ a b c : Fin 8, a < b → b < c → Red3 Circ8 a b c = false := by
  decide

/-- 沒有藍色 K₄。 -/
theorem circ8_no_blue4 :
    ∀ a b c d : Fin 8, a < b → b < c → c < d → Blue4 Circ8 a b c d = false := by
  decide

/-- **R(3,4) ≥ 9**：`K₈` 上既無紅色 K₃、也無藍色 K₄。 -/
theorem circ8_no_red3_no_blue4 :
    (∀ a b c : Fin 8, a < b → b < c → Red3 Circ8 a b c = false) ∧
    (∀ a b c d : Fin 8, a < b → b < c → c < d → Blue4 Circ8 a b c d = false) :=
  ⟨circ8_no_red3, circ8_no_blue4⟩

/-! ### 上界：`R(3,3) ≤ 6`（窮舉所有 2-著色）

下界靠見證（上面兩節），上界靠**窮舉**：`K₆` 有 15 條邊，所以 2-著色共 `2^15 = 32768` 種，
全部檢查一次就能斷言「任一 2-著色都含單色三角形」。這是本目錄第一個真正的「上界」定理，
也是 `R(4,4) ≤ 18` 那類遞迴上界所需的枚舉骨架的最小版本。

編碼：邊 `{i,j}`（`i < j`）用三角形索引 `j*(j-1)/2 + i`（0…14）配一個位元。 -/

/-- 邊 `{i,j}`（`i < j`）在 15 個位元中的位置。 -/
def eIdx (i j : Nat) : Nat := j * (j - 1) / 2 + i

/-- 第 `code` 號著色下邊 `{i,j}` 的顏色（`true` = 紅）。 -/
def eCol (code i j : Nat) : Bool := (code / 2 ^ eIdx i j) % 2 == 1

/-- **R(3,3) ≤ 6**：`K₆` 的任一 2-著色都含單色三角形。 -/
theorem r33_le_6 (code : Fin 32768) :
    ∃ i j k : Fin 6, i < j ∧ j < k ∧
      eCol code.val i.val j.val = eCol code.val i.val k.val ∧
      eCol code.val i.val k.val = eCol code.val j.val k.val := by
  revert code
  native_decide

/-! ### 上界：`R(3,4) ≤ 10`（組合論證，非窮舉） -/
/-- 把五個值當成 `Fin 5 → α`（好讓鴿籠變成可判定命題）。 -/
def mk5 {α : Type} (a b c d e : α) : Fin 5 → α :=
  Fin.cases a <| Fin.cases b <| Fin.cases c <| Fin.cases d <| Fin.cases e Fin.elim0

/-- 把九個值當成 `Fin 9 → α`。 -/
def mk9 {α : Type} (a b c d e g h i j : α) : Fin 9 → α :=
  Fin.cases a <| Fin.cases b <| Fin.cases c <| Fin.cases d <| Fin.cases e <|
  Fin.cases g <| Fin.cases h <| Fin.cases i <| Fin.cases j Fin.elim0

/-- 五個布林值中必有三個同色。 -/
theorem pigeon5 (b0 b1 b2 b3 b4 : Bool) :
    ∃ i j k : Fin 5, i ≠ j ∧ j ≠ k ∧ i ≠ k ∧
      mk5 b0 b1 b2 b3 b4 i = mk5 b0 b1 b2 b3 b4 j ∧
      mk5 b0 b1 b2 b3 b4 j = mk5 b0 b1 b2 b3 b4 k := by
  revert b0 b1 b2 b3 b4
  decide

/-- 九個布林值中必有四個為 `true`，或六個為 `false`。 -/
theorem pigeon9 (b0 b1 b2 b3 b4 b5 b6 b7 b8 : Bool) :
    (∃ i₁ i₂ i₃ i₄ : Fin 9,
      i₁ ≠ i₂ ∧ i₁ ≠ i₃ ∧ i₁ ≠ i₄ ∧ i₂ ≠ i₃ ∧ i₂ ≠ i₄ ∧ i₃ ≠ i₄ ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₁ = true ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₂ = true ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₃ = true ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₄ = true) ∨
    (∃ i₁ i₂ i₃ i₄ i₅ i₆ : Fin 9,
      i₁ ≠ i₂ ∧ i₁ ≠ i₃ ∧ i₁ ≠ i₄ ∧ i₁ ≠ i₅ ∧ i₁ ≠ i₆ ∧
      i₂ ≠ i₃ ∧ i₂ ≠ i₄ ∧ i₂ ≠ i₅ ∧ i₂ ≠ i₆ ∧
      i₃ ≠ i₄ ∧ i₃ ≠ i₅ ∧ i₃ ≠ i₆ ∧
      i₄ ≠ i₅ ∧ i₄ ≠ i₆ ∧ i₅ ≠ i₆ ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₁ = false ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₂ = false ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₃ = false ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₄ = false ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₅ = false ∧
      mk9 b0 b1 b2 b3 b4 b5 b6 b7 b8 i₆ = false) := by
  native_decide +revert

/-- 函數版五取三。 -/
theorem pigeon5_f (f : Fin 5 → Bool) :
    ∃ i j k : Fin 5, i ≠ j ∧ j ≠ k ∧ i ≠ k ∧ f i = f j ∧ f j = f k := by
  obtain ⟨i, j, k, h1, h2, h3, h4, h5⟩ := pigeon5 (f 0) (f 1) (f 2) (f 3) (f 4)
  have key : ∀ t : Fin 5, mk5 (f 0) (f 1) (f 2) (f 3) (f 4) t = f t := by
    intro t
    match t with
    | ⟨0, _⟩ => rfl
    | ⟨1, _⟩ => rfl
    | ⟨2, _⟩ => rfl
    | ⟨3, _⟩ => rfl
    | ⟨4, _⟩ => rfl
  exact ⟨i, j, k, h1, h2, h3, by rw [← key i, ← key j]; exact h4,
    by rw [← key j, ← key k]; exact h5⟩

/-- 三角形三邊同色。 -/
def triMono {α : Type} (c : α → α → Bool) (a b d : α) : Bool :=
  (c a b == c b d) && (c b d == c a d)

/-- 四點六邊全為 `col` 色。 -/
def quadMono {α : Type} (c : α → α → Bool) (col : Bool) (a b d e : α) : Bool :=
  (c a b == col) && (c a d == col) && (c a e == col) &&
  (c b d == col) && (c b e == col) && (c d e == col)

theorem triMono_of {α : Type} {c : α → α → Bool} {a b d : α}
    (h1 : c a b = true) (h2 : c b d = true) (h3 : c a d = true) : triMono c a b d = true := by
  simp [triMono, h1, h2, h3]

/-- 紅色三角形（三條邊全是紅）。 -/
def triRed {α : Type} (c : α → α → Bool) (a b d : α) : Bool := c a b && c b d && c a d

/-- 藍色三角形（三條邊全是藍）。 -/
def triBlue {α : Type} (c : α → α → Bool) (a b d : α) : Bool :=
  !(c a b) && !(c b d) && !(c a d)

theorem triRed_of {α : Type} {c : α → α → Bool} {a b d : α}
    (h1 : c a b = true) (h2 : c b d = true) (h3 : c a d = true) : triRed c a b d = true := by
  simp [triRed, h1, h2, h3]

theorem triBlue_of {α : Type} {c : α → α → Bool} {a b d : α}
    (h1 : c a b = false) (h2 : c b d = false) (h3 : c a d = false) : triBlue c a b d = true := by
  simp [triBlue, h1, h2, h3]

theorem quadMono_of {α : Type} {c : α → α → Bool} {a b d e : α}
    (h1 : c a b = false) (h2 : c a d = false) (h3 : c a e = false)
    (h4 : c b d = false) (h5 : c b e = false) (h6 : c d e = false) :
    quadMono c false a b d e = true := by
  simp [quadMono, h1, h2, h3, h4, h5, h6]

/-- **星形六點引理**：`v` 到六個互異的點全是藍邊時，要嘛出現紅色三角形，
要嘛出現含 `v` 的藍色 `K₄`。

證明就是 `R(3,3) ≤ 6` 的度數論證，外加「藍三角形 + `v` ⇒ 藍 `K₄`」。 -/
theorem six_star_step {α : Type} (c : α → α → Bool) (v x₁ x₂ x₃ x₄ x₅ x₆ : α)
    (hv1 : v ≠ x₁) (hv2 : v ≠ x₂) (hv3 : v ≠ x₃) (hv4 : v ≠ x₄) (hv5 : v ≠ x₅) (hv6 : v ≠ x₆)
    (hb1 : c v x₁ = false) (hb2 : c v x₂ = false) (hb3 : c v x₃ = false)
    (hb4 : c v x₄ = false) (hb5 : c v x₅ = false) (hb6 : c v x₆ = false)
    (h12 : x₁ ≠ x₂) (h13 : x₁ ≠ x₃) (h14 : x₁ ≠ x₄) (h15 : x₁ ≠ x₅) (h16 : x₁ ≠ x₆)
    (h23 : x₂ ≠ x₃) (h24 : x₂ ≠ x₄) (h25 : x₂ ≠ x₅) (h26 : x₂ ≠ x₆)
    (h34 : x₃ ≠ x₄) (h35 : x₃ ≠ x₅) (h36 : x₃ ≠ x₆)
    (h45 : x₄ ≠ x₅) (h46 : x₄ ≠ x₆) (h56 : x₅ ≠ x₆) :
    (∃ a b d : α, a ≠ b ∧ b ≠ d ∧ a ≠ d ∧ c a b = true ∧ c b d = true ∧ c a d = true) ∨
    (∃ a b d : α, a ≠ b ∧ b ≠ d ∧ a ≠ d ∧ a ≠ v ∧ b ≠ v ∧ d ≠ v ∧
      c v a = false ∧ c v b = false ∧ c v d = false ∧
      c a b = false ∧ c b d = false ∧ c a d = false) := by
  obtain ⟨i, j, k, hij, hjk, hik, hc1, hc2⟩ :=
    pigeon5_f (fun t => c x₁ (mk5 x₂ x₃ x₄ x₅ x₆ t))
  have hvne : ∀ t : Fin 5, v ≠ mk5 x₂ x₃ x₄ x₅ x₆ t := by
    intro t
    match t with
    | ⟨0, _⟩ => exact hv2
    | ⟨1, _⟩ => exact hv3
    | ⟨2, _⟩ => exact hv4
    | ⟨3, _⟩ => exact hv5
    | ⟨4, _⟩ => exact hv6
  have hbne : ∀ t : Fin 5, c v (mk5 x₂ x₃ x₄ x₅ x₆ t) = false := by
    intro t
    match t with
    | ⟨0, _⟩ => exact hb2
    | ⟨1, _⟩ => exact hb3
    | ⟨2, _⟩ => exact hb4
    | ⟨3, _⟩ => exact hb5
    | ⟨4, _⟩ => exact hb6
  have hxne : ∀ t : Fin 5, x₁ ≠ mk5 x₂ x₃ x₄ x₅ x₆ t := by
    intro t
    match t with
    | ⟨0, _⟩ => exact h12
    | ⟨1, _⟩ => exact h13
    | ⟨2, _⟩ => exact h14
    | ⟨3, _⟩ => exact h15
    | ⟨4, _⟩ => exact h16
  have hinj : ∀ s t : Fin 5, s ≠ t → mk5 x₂ x₃ x₄ x₅ x₆ s ≠ mk5 x₂ x₃ x₄ x₅ x₆ t := by
    intro s t hst h
    match s, t with
    | ⟨0, _⟩, ⟨0, _⟩ => exact hst rfl
    | ⟨0, _⟩, ⟨1, _⟩ => exact h23 h
    | ⟨0, _⟩, ⟨2, _⟩ => exact h24 h
    | ⟨0, _⟩, ⟨3, _⟩ => exact h25 h
    | ⟨0, _⟩, ⟨4, _⟩ => exact h26 h
    | ⟨1, _⟩, ⟨0, _⟩ => exact h23 h.symm
    | ⟨1, _⟩, ⟨1, _⟩ => exact hst rfl
    | ⟨1, _⟩, ⟨2, _⟩ => exact h34 h
    | ⟨1, _⟩, ⟨3, _⟩ => exact h35 h
    | ⟨1, _⟩, ⟨4, _⟩ => exact h36 h
    | ⟨2, _⟩, ⟨0, _⟩ => exact h24 h.symm
    | ⟨2, _⟩, ⟨1, _⟩ => exact h34 h.symm
    | ⟨2, _⟩, ⟨2, _⟩ => exact hst rfl
    | ⟨2, _⟩, ⟨3, _⟩ => exact h45 h
    | ⟨2, _⟩, ⟨4, _⟩ => exact h46 h
    | ⟨3, _⟩, ⟨0, _⟩ => exact h25 h.symm
    | ⟨3, _⟩, ⟨1, _⟩ => exact h35 h.symm
    | ⟨3, _⟩, ⟨2, _⟩ => exact h45 h.symm
    | ⟨3, _⟩, ⟨3, _⟩ => exact hst rfl
    | ⟨3, _⟩, ⟨4, _⟩ => exact h56 h
    | ⟨4, _⟩, ⟨0, _⟩ => exact h26 h.symm
    | ⟨4, _⟩, ⟨1, _⟩ => exact h36 h.symm
    | ⟨4, _⟩, ⟨2, _⟩ => exact h46 h.symm
    | ⟨4, _⟩, ⟨3, _⟩ => exact h56 h.symm
    | ⟨4, _⟩, ⟨4, _⟩ => exact hst rfl
  have hAB : mk5 x₂ x₃ x₄ x₅ x₆ i ≠ mk5 x₂ x₃ x₄ x₅ x₆ j := hinj i j hij
  have hJD : mk5 x₂ x₃ x₄ x₅ x₆ j ≠ mk5 x₂ x₃ x₄ x₅ x₆ k := hinj j k hjk
  have hID : mk5 x₂ x₃ x₄ x₅ x₆ i ≠ mk5 x₂ x₃ x₄ x₅ x₆ k := hinj i k hik
  have hvI : v ≠ mk5 x₂ x₃ x₄ x₅ x₆ i := hvne i
  have hvJ : v ≠ mk5 x₂ x₃ x₄ x₅ x₆ j := hvne j
  have hvK : v ≠ mk5 x₂ x₃ x₄ x₅ x₆ k := hvne k
  have hbI : c v (mk5 x₂ x₃ x₄ x₅ x₆ i) = false := hbne i
  have hbJ : c v (mk5 x₂ x₃ x₄ x₅ x₆ j) = false := hbne j
  have hbK : c v (mk5 x₂ x₃ x₄ x₅ x₆ k) = false := hbne k
  have hxI : x₁ ≠ mk5 x₂ x₃ x₄ x₅ x₆ i := hxne i
  have hxJ : x₁ ≠ mk5 x₂ x₃ x₄ x₅ x₆ j := hxne j
  have hxK : x₁ ≠ mk5 x₂ x₃ x₄ x₅ x₆ k := hxne k
  cases hcol : c x₁ (mk5 x₂ x₃ x₄ x₅ x₆ i) with
  | true =>
    have hJ : c x₁ (mk5 x₂ x₃ x₄ x₅ x₆ j) = true := by rw [← hc1]; exact hcol
    have hK : c x₁ (mk5 x₂ x₃ x₄ x₅ x₆ k) = true := by rw [← hc2, ← hc1]; exact hcol
    cases hAB' : c (mk5 x₂ x₃ x₄ x₅ x₆ i) (mk5 x₂ x₃ x₄ x₅ x₆ j) with
    | true => exact Or.inl ⟨x₁, _, _, hxI, hAB, hxJ, hcol, hAB', hJ⟩
    | false =>
      cases hBD' : c (mk5 x₂ x₃ x₄ x₅ x₆ j) (mk5 x₂ x₃ x₄ x₅ x₆ k) with
      | true => exact Or.inl ⟨x₁, _, _, hxJ, hJD, hxK, hJ, hBD', hK⟩
      | false =>
        cases hAD' : c (mk5 x₂ x₃ x₄ x₅ x₆ i) (mk5 x₂ x₃ x₄ x₅ x₆ k) with
        | true => exact Or.inl ⟨x₁, _, _, hxI, hID, hxK, hcol, hAD', hK⟩
        | false => exact Or.inr ⟨_, _, _, hAB, hJD, hID, hvI.symm, hvJ.symm, hvK.symm, hbI, hbJ, hbK, hAB', hBD', hAD'⟩
  | false =>
    have hJ : c x₁ (mk5 x₂ x₃ x₄ x₅ x₆ j) = false := by rw [← hc1]; exact hcol
    have hK : c x₁ (mk5 x₂ x₃ x₄ x₅ x₆ k) = false := by rw [← hc2, ← hc1]; exact hcol
    cases hAB' : c (mk5 x₂ x₃ x₄ x₅ x₆ i) (mk5 x₂ x₃ x₄ x₅ x₆ j) with
    | false => exact Or.inr ⟨x₁, _, _, hxI, hAB, hxJ, hv1.symm, hvI.symm, hvJ.symm, hb1, hbI, hbJ, hcol, hAB', hJ⟩
    | true =>
      cases hBD' : c (mk5 x₂ x₃ x₄ x₅ x₆ j) (mk5 x₂ x₃ x₄ x₅ x₆ k) with
      | false => exact Or.inr ⟨x₁, _, _, hxJ, hJD, hxK, hv1.symm, hvJ.symm, hvK.symm, hb1, hbJ, hbK, hJ, hBD', hK⟩
      | true =>
        cases hAD' : c (mk5 x₂ x₃ x₄ x₅ x₆ i) (mk5 x₂ x₃ x₄ x₅ x₆ k) with
        | false => exact Or.inr ⟨x₁, _, _, hxI, hID, hxK, hv1.symm, hvI.symm, hvK.symm, hb1, hbI, hbK, hcol, hAD', hK⟩
        | true => exact Or.inl ⟨_, _, _, hAB, hJD, hID, hAB', hBD', hAD'⟩

/-- `Fin.succ` 嚴格遞增，故不等於 `0`。 -/
theorem succ_ne_zero' {n : Nat} (i : Fin n) : Fin.succ i ≠ (0 : Fin (n + 1)) := by
  intro h
  have := congrArg Fin.val h
  simp at this

/-- `Fin.succ` 單射。 -/
theorem succ_ne {n : Nat} {s t : Fin n} (h : s ≠ t) : Fin.succ s ≠ Fin.succ t := by
  intro hs
  apply h
  have hv := congrArg Fin.val hs
  simp at hv
  exact Fin.ext (by omega)

/-- **R(3,4) ≤ 10**：`K₁₀` 的任一 2-著色都含紅色 `K₃` 或藍色 `K₄`。

這是走 Ramsey 遞迴 `R(3,4) ≤ R(2,4) + R(3,3) = 4 + 6` 的那條路，但直接展開：
頂點 `0` 的 9 條邊中必有 4 紅或 6 藍（`pigeon9`）。4 紅 ⇒ 鄰點之間不能有紅邊，
於是那 4 點是藍 `K₄`；6 藍 ⇒ 用星形六點引理（`six_star_step`）。 -/
theorem r34_le_10 (c : Fin 10 → Fin 10 → Bool)
    (hNoRed3 : ∀ a b d : Fin 10, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false)
    (hNoBlue4 : ∀ a b d e : Fin 10, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c false a b d e = false) : False := by
  have key : ∀ t : Fin 9,
      mk9 (c 0 1) (c 0 2) (c 0 3) (c 0 4) (c 0 5) (c 0 6) (c 0 7) (c 0 8) (c 0 9) t
        = c 0 (Fin.succ t) := by
    intro t
    match t with
    | ⟨0, _⟩ => rfl
    | ⟨1, _⟩ => rfl
    | ⟨2, _⟩ => rfl
    | ⟨3, _⟩ => rfl
    | ⟨4, _⟩ => rfl
    | ⟨5, _⟩ => rfl
    | ⟨6, _⟩ => rfl
    | ⟨7, _⟩ => rfl
    | ⟨8, _⟩ => rfl
  have no_red_of : ∀ a b : Fin 10, a ≠ 0 → b ≠ 0 → c 0 a = true → c 0 b = true → a ≠ b →
      c a b = false := by
    intro a b ha hb hca hcb hab
    cases h : c a b with
    | false => rfl
    | true =>
      have ht : triRed c 0 a b = true := by simp [triRed, hca, hcb, h]
      rw [hNoRed3 0 a b ha.symm hab hb.symm] at ht
      exact absurd ht (by simp)
  rcases pigeon9 (c 0 1) (c 0 2) (c 0 3) (c 0 4) (c 0 5) (c 0 6) (c 0 7) (c 0 8) (c 0 9) with
    ⟨i₁, i₂, i₃, i₄, hd12, hd13, hd14, hd23, hd24, hd34, h1, h2, h3, h4⟩ |
    ⟨i₁, i₂, i₃, i₄, i₅, i₆, hd12, hd13, hd14, hd15, hd16,
      hd23, hd24, hd25, hd26, hd34, hd35, hd36, hd45, hd46, hd56,
      h1, h2, h3, h4, h5, h6⟩
  · -- 四個紅鄰點 ⇒ 鄰點之間全藍 ⇒ 藍 K₄
    have hr1 : c 0 (Fin.succ i₁) = true := by rw [← key i₁]; exact h1
    have hr2 : c 0 (Fin.succ i₂) = true := by rw [← key i₂]; exact h2
    have hr3 : c 0 (Fin.succ i₃) = true := by rw [← key i₃]; exact h3
    have hr4 : c 0 (Fin.succ i₄) = true := by rw [← key i₄]; exact h4
    have hz1 : Fin.succ i₁ ≠ 0 := succ_ne_zero' i₁
    have hz2 : Fin.succ i₂ ≠ 0 := succ_ne_zero' i₂
    have hz3 : Fin.succ i₃ ≠ 0 := succ_ne_zero' i₃
    have hz4 : Fin.succ i₄ ≠ 0 := succ_ne_zero' i₄
    have e12 : c (Fin.succ i₁) (Fin.succ i₂) = false :=
      no_red_of _ _ hz1 hz2 hr1 hr2 (succ_ne hd12)
    have e13 : c (Fin.succ i₁) (Fin.succ i₃) = false :=
      no_red_of _ _ hz1 hz3 hr1 hr3 (succ_ne hd13)
    have e14 : c (Fin.succ i₁) (Fin.succ i₄) = false :=
      no_red_of _ _ hz1 hz4 hr1 hr4 (succ_ne hd14)
    have e23 : c (Fin.succ i₂) (Fin.succ i₃) = false :=
      no_red_of _ _ hz2 hz3 hr2 hr3 (succ_ne hd23)
    have e24 : c (Fin.succ i₂) (Fin.succ i₄) = false :=
      no_red_of _ _ hz2 hz4 hr2 hr4 (succ_ne hd24)
    have e34 : c (Fin.succ i₃) (Fin.succ i₄) = false :=
      no_red_of _ _ hz3 hz4 hr3 hr4 (succ_ne hd34)
    have hq : quadMono c false (Fin.succ i₁) (Fin.succ i₂) (Fin.succ i₃) (Fin.succ i₄) = true :=
      quadMono_of e12 e13 e14 e23 e24 e34
    rw [hNoBlue4 _ _ _ _ (succ_ne hd12) (succ_ne hd13) (succ_ne hd14)
      (succ_ne hd23) (succ_ne hd24) (succ_ne hd34)] at hq
    exact absurd hq (by simp)
  · -- 六個藍鄰點 ⇒ 星形六點引理
    have hb1 : c 0 (Fin.succ i₁) = false := by rw [← key i₁]; exact h1
    have hb2 : c 0 (Fin.succ i₂) = false := by rw [← key i₂]; exact h2
    have hb3 : c 0 (Fin.succ i₃) = false := by rw [← key i₃]; exact h3
    have hb4 : c 0 (Fin.succ i₄) = false := by rw [← key i₄]; exact h4
    have hb5 : c 0 (Fin.succ i₅) = false := by rw [← key i₅]; exact h5
    have hb6 : c 0 (Fin.succ i₆) = false := by rw [← key i₆]; exact h6
    have hz1 : (0 : Fin 10) ≠ Fin.succ i₁ := (succ_ne_zero' i₁).symm
    have hz2 : (0 : Fin 10) ≠ Fin.succ i₂ := (succ_ne_zero' i₂).symm
    have hz3 : (0 : Fin 10) ≠ Fin.succ i₃ := (succ_ne_zero' i₃).symm
    have hz4 : (0 : Fin 10) ≠ Fin.succ i₄ := (succ_ne_zero' i₄).symm
    have hz5 : (0 : Fin 10) ≠ Fin.succ i₅ := (succ_ne_zero' i₅).symm
    have hz6 : (0 : Fin 10) ≠ Fin.succ i₆ := (succ_ne_zero' i₆).symm
    rcases six_star_step c 0 (Fin.succ i₁) (Fin.succ i₂) (Fin.succ i₃) (Fin.succ i₄)
      (Fin.succ i₅) (Fin.succ i₆) hz1 hz2 hz3 hz4 hz5 hz6 hb1 hb2 hb3 hb4 hb5 hb6
      (succ_ne hd12) (succ_ne hd13) (succ_ne hd14) (succ_ne hd15) (succ_ne hd16)
      (succ_ne hd23) (succ_ne hd24) (succ_ne hd25) (succ_ne hd26)
      (succ_ne hd34) (succ_ne hd35) (succ_ne hd36)
      (succ_ne hd45) (succ_ne hd46) (succ_ne hd56) with
      ⟨a, b, d, hab, hbd, had, h1, h2, h3⟩ |
      ⟨a, b, d, hab, hbd, had, hav, hbv, hdv, hv1, hv2, hv3, h1, h2, h3⟩
    · have ht : triRed c a b d = true := triRed_of h1 h2 h3
      rw [hNoRed3 a b d hab hbd had] at ht
      exact absurd ht (by simp)
    · have hq : quadMono c false 0 a b d = true := quadMono_of hv1 hv2 hv3 h1 h3 h2
      rw [hNoBlue4 0 a b d hav.symm hbv.symm hdv.symm hab had hbd] at hq
      exact absurd hq (by simp)


/-! ### 度數與 `R(3,4) ≤ 9` -/

/-- `v` 的鄰點清單（排除 `v` 自己）。 -/
def nbhd {n : Nat} (c : Fin n → Fin n → Bool) (v : Fin n) (col : Bool) : List (Fin n) :=
  (List.finRange n).filter (fun w => (c v w == col) && decide (w ≠ v))

theorem degIn_eq_nbhd {n : Nat} (c : Fin n → Fin n → Bool) (v : Fin n) (col : Bool) :
    KtLaws.Graph.degIn c col (List.finRange n) v = (nbhd c v col).length := by
  unfold KtLaws.Graph.degIn nbhd
  rw [List.countP_eq_length_filter]

/-- 紅度 + 藍度 = `n - 1`。 -/
theorem deg_split {n : Nat} (c : Fin n → Fin n → Bool) (v : Fin n) :
    (nbhd c v true).length + (nbhd c v false).length = n - 1 := by
  rw [← degIn_eq_nbhd, ← degIn_eq_nbhd]
  unfold KtLaws.Graph.degIn
  have hdisj : ∀ x : Fin n, ((c v x == true) && decide (x ≠ v)) = true →
      ((c v x == false) && decide (x ≠ v)) = true → False := by
    intro x h1 h2
    simp at h1 h2
    rw [h1.1] at h2
    exact absurd h2.1 (by simp)
  rw [KtLaws.Graph.countP_or _ _ hdisj (List.finRange n)]
  have hpred : (fun x : Fin n => ((c v x == true) && decide (x ≠ v)) || ((c v x == false) && decide (x ≠ v)))
      = (fun x : Fin n => decide (x ≠ v)) := by
    funext x
    cases hx : c v x <;> simp
  rw [hpred, KtLaws.Graph.countP_finRange_ne v]


theorem mem_nbhd {n : Nat} {c : Fin n → Fin n → Bool} {v x : Fin n} {col : Bool}
    (h : x ∈ nbhd c v col) : c v x = col ∧ x ≠ v := by
  rw [nbhd] at h
  have hh := (List.mem_filter.mp h).2
  simp only [Bool.and_eq_true, decide_eq_true_eq] at hh
  exact ⟨beq_iff_eq.mp hh.1, hh.2⟩

/-- **紅度 ≤ 3**：四個紅鄰點若內部有紅邊，就與 `v` 構成紅三角形；否則它們是藍 `K₄`。 -/
theorem red_deg_le_three (c : Fin 9 → Fin 9 → Bool)
    (hNoRed3 : ∀ a b d : Fin 9, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false)
    (hNoBlue4 : ∀ a b d e : Fin 9, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c false a b d e = false)
    (v : Fin 9) : (nbhd c v true).length ≤ 3 := by
  suffices h : ¬ 4 ≤ (nbhd c v true).length by omega
  intro h4
  have hnd : (nbhd c v true).Nodup := KtLaws.Graph.nodup_filter _ (List.nodup_finRange 9)
  obtain ⟨ws, hlen, hndw, hmem⟩ := KtLaws.Graph.exists_subset_len (nbhd c v true) 4 hnd h4
  obtain ⟨a, b, d, e, rfl⟩ := KtLaws.Graph.eq_quad_of_len ws hlen
  obtain ⟨hva, hna⟩ := mem_nbhd (hmem a (by simp))
  obtain ⟨hvb, hnb⟩ := mem_nbhd (hmem b (by simp))
  obtain ⟨hvd, hnd2⟩ := mem_nbhd (hmem d (by simp))
  obtain ⟨hve, hne⟩ := mem_nbhd (hmem e (by simp))
  have hab : a ≠ b := by simp_all
  have had : a ≠ d := by simp_all
  have hae : a ≠ e := by simp_all
  have hbd : b ≠ d := by simp_all
  have hbe : b ≠ e := by simp_all
  have hde : d ≠ e := by simp_all
  have hb_ab : c a b = false := by
    cases hh : c a b with
    | false => rfl
    | true =>
      have ht : triRed c v a b = true := triRed_of hva hh hvb
      rw [hNoRed3 v a b hna.symm hab hnb.symm] at ht
      exact absurd ht (by simp)
  have hb_ad : c a d = false := by
    cases hh : c a d with
    | false => rfl
    | true =>
      have ht : triRed c v a d = true := triRed_of hva hh hvd
      rw [hNoRed3 v a d hna.symm had hnd2.symm] at ht
      exact absurd ht (by simp)
  have hb_ae : c a e = false := by
    cases hh : c a e with
    | false => rfl
    | true =>
      have ht : triRed c v a e = true := triRed_of hva hh hve
      rw [hNoRed3 v a e hna.symm hae hne.symm] at ht
      exact absurd ht (by simp)
  have hb_bd : c b d = false := by
    cases hh : c b d with
    | false => rfl
    | true =>
      have ht : triRed c v b d = true := triRed_of hvb hh hvd
      rw [hNoRed3 v b d hnb.symm hbd hnd2.symm] at ht
      exact absurd ht (by simp)
  have hb_be : c b e = false := by
    cases hh : c b e with
    | false => rfl
    | true =>
      have ht : triRed c v b e = true := triRed_of hvb hh hve
      rw [hNoRed3 v b e hnb.symm hbe hne.symm] at ht
      exact absurd ht (by simp)
  have hb_de : c d e = false := by
    cases hh : c d e with
    | false => rfl
    | true =>
      have ht : triRed c v d e = true := triRed_of hvd hh hve
      rw [hNoRed3 v d e hnd2.symm hde hne.symm] at ht
      exact absurd ht (by simp)
  have hq : quadMono c false a b d e = true := quadMono_of hb_ab hb_ad hb_ae hb_bd hb_be hb_de
  rw [hNoBlue4 a b d e hab had hae hbd hbe hde] at hq
  exact absurd hq (by simp)


/-- **紅度 ≥ 3**：若紅度 ≤ 2，藍鄰點至少六個，星形六點引理就給出紅三角形或藍 `K₄`。 -/
theorem red_deg_ge_three (c : Fin 9 → Fin 9 → Bool)
    (hNoRed3 : ∀ a b d : Fin 9, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false)
    (hNoBlue4 : ∀ a b d e : Fin 9, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c false a b d e = false)
    (v : Fin 9) : 3 ≤ (nbhd c v true).length := by
  suffices h : ¬ (nbhd c v true).length ≤ 2 by omega
  intro hle
  have hsplit : (nbhd c v true).length + (nbhd c v false).length = 8 := by
    have := deg_split c v
    omega
  have hblue : 6 ≤ (nbhd c v false).length := by omega
  have hnd : (nbhd c v false).Nodup := KtLaws.Graph.nodup_filter _ (List.nodup_finRange 9)
  obtain ⟨ws, hlen, hndw, hmem⟩ := KtLaws.Graph.exists_subset_len (nbhd c v false) 6 hnd hblue
  obtain ⟨x₁, x₂, x₃, x₄, x₅, x₆, rfl⟩ := KtLaws.Graph.eq_six_of_len ws hlen
  obtain ⟨hb1, hz1⟩ := mem_nbhd (hmem x₁ (by simp))
  obtain ⟨hb2, hz2⟩ := mem_nbhd (hmem x₂ (by simp))
  obtain ⟨hb3, hz3⟩ := mem_nbhd (hmem x₃ (by simp))
  obtain ⟨hb4, hz4⟩ := mem_nbhd (hmem x₄ (by simp))
  obtain ⟨hb5, hz5⟩ := mem_nbhd (hmem x₅ (by simp))
  obtain ⟨hb6, hz6⟩ := mem_nbhd (hmem x₆ (by simp))
  have d12 : x₁ ≠ x₂ := by simp_all
  have d13 : x₁ ≠ x₃ := by simp_all
  have d14 : x₁ ≠ x₄ := by simp_all
  have d15 : x₁ ≠ x₅ := by simp_all
  have d16 : x₁ ≠ x₆ := by simp_all
  have d23 : x₂ ≠ x₃ := by simp_all
  have d24 : x₂ ≠ x₄ := by simp_all
  have d25 : x₂ ≠ x₅ := by simp_all
  have d26 : x₂ ≠ x₆ := by simp_all
  have d34 : x₃ ≠ x₄ := by simp_all
  have d35 : x₃ ≠ x₅ := by simp_all
  have d36 : x₃ ≠ x₆ := by simp_all
  have d45 : x₄ ≠ x₅ := by simp_all
  have d46 : x₄ ≠ x₆ := by simp_all
  have d56 : x₅ ≠ x₆ := by simp_all
  rcases six_star_step c v x₁ x₂ x₃ x₄ x₅ x₆ hz1.symm hz2.symm hz3.symm hz4.symm hz5.symm hz6.symm
      hb1 hb2 hb3 hb4 hb5 hb6 d12 d13 d14 d15 d16 d23 d24 d25 d26 d34 d35 d36 d45 d46 d56 with
    ⟨a, b, d, hab, hbd, had, h1, h2, h3⟩ |
    ⟨a, b, d, hab, hbd, had, hav, hbv, hdv, hv1, hv2, hv3, h1, h2, h3⟩
  · have ht : triRed c a b d = true := triRed_of h1 h2 h3
    rw [hNoRed3 a b d hab hbd had] at ht
    exact absurd ht (by simp)
  · have hq : quadMono c false v a b d = true := quadMono_of hv1 hv2 hv3 h1 h3 h2
    rw [hNoBlue4 v a b d hav.symm hbv.symm hdv.symm hab had hbd] at hq
    exact absurd hq (by simp)

/-- **R(3,4) ≤ 9**：`K₉` 的任一 2-著色都含紅色 `K₃` 或藍色 `K₄`。

證明走「度數 + 握手引理」：每個頂點的紅度 ≤ 3（四個紅鄰點會逼出藍 `K₄`）且 ≥ 3
（紅度 ≤ 2 時藍鄰點有六個，星形六點引理給出矛盾），所以紅色圖是 3-正則；
但 9 個頂點的 3-正則圖不存在——`Σ deg = 27` 是奇數，而握手引理說它等於 `2 × 邊數`。 -/
theorem r34_le_9 (c : Fin 9 → Fin 9 → Bool)
    (hsymm : ∀ i j : Fin 9, c i j = c j i)
    (hNoRed3 : ∀ a b d : Fin 9, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false)
    (hNoBlue4 : ∀ a b d e : Fin 9, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c false a b d e = false) : False := by
  have hdeg : ∀ v : Fin 9, KtLaws.Graph.degIn c true (List.finRange 9) v = 3 := by
    intro v
    have h1 := red_deg_le_three c hNoRed3 hNoBlue4 v
    have h2 := red_deg_ge_three c hNoRed3 hNoBlue4 v
    rw [degIn_eq_nbhd]
    omega
  have hhand := KtLaws.Graph.handshake c true hsymm (List.finRange 9) (List.nodup_finRange 9)
  have hconst : ((List.finRange 9).map (fun v => KtLaws.Graph.degIn c true (List.finRange 9) v)).sum = 27 := by
    rw [KtLaws.Graph.sum_map_const _ _ 3 (fun x _ => hdeg x), List.length_finRange]
  omega


/-! ### `R(4,3) ≤ 9` 與 `R(4,4) ≤ 18`（Ramsey 遞推） -/

/-- 四點六邊全為 `col` 色（一般色版）。 -/
theorem quadMono_all {α : Type} {c : α → α → Bool} {col : Bool} {a b d e : α}
    (h1 : c a b = col) (h2 : c a d = col) (h3 : c a e = col)
    (h4 : c b d = col) (h5 : c b e = col) (h6 : c d e = col) :
    quadMono c col a b d e = true := by
  simp [quadMono, h1, h2, h3, h4, h5, h6]

theorem triRed_one {α : Type} {c : α → α → Bool} {a b d : α} (h : triRed c a b d = true) :
    c a b = true := by
  unfold triRed at h
  simp only [Bool.and_eq_true] at h
  exact h.1.1
theorem triRed_two {α : Type} {c : α → α → Bool} {a b d : α} (h : triRed c a b d = true) :
    c b d = true := by
  unfold triRed at h
  simp only [Bool.and_eq_true] at h
  exact h.1.2
theorem triRed_three {α : Type} {c : α → α → Bool} {a b d : α} (h : triRed c a b d = true) :
    c a d = true := by
  unfold triRed at h
  simp only [Bool.and_eq_true] at h
  exact h.2

theorem triBlue_one {α : Type} {c : α → α → Bool} {a b d : α} (h : triBlue c a b d = true) :
    c a b = false := by
  unfold triBlue at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.1
theorem triBlue_two {α : Type} {c : α → α → Bool} {a b d : α} (h : triBlue c a b d = true) :
    c b d = false := by
  unfold triBlue at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.2
theorem triBlue_three {α : Type} {c : α → α → Bool} {a b d : α} (h : triBlue c a b d = true) :
    c a d = false := by
  unfold triBlue at h
  simp only [Bool.and_eq_true] at h
  simpa using h.2


/-- **R(4,3) ≤ 9**：把紅藍對調，就由 `R(3,4) ≤ 9` 得到。 -/
theorem r43_le_9 (c : Fin 9 → Fin 9 → Bool)
    (hsymm : ∀ i j : Fin 9, c i j = c j i)
    (hNoRed4 : ∀ a b d e : Fin 9, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c true a b d e = false)
    (hNoBlue3 : ∀ a b d : Fin 9, a ≠ b → b ≠ d → a ≠ d → triBlue c a b d = false) : False := by
  apply r34_le_9 (fun i j => !(c i j))
  · intro i j
    simp [hsymm i j]
  · intro a b d hab hbd had
    have h := hNoBlue3 a b d hab hbd had
    simpa [triRed, triBlue] using h
  · intro a b d e h1 h2 h3 h4 h5 h6
    have h := hNoRed4 a b d e h1 h2 h3 h4 h5 h6
    cases q1 : c a b <;> cases q2 : c a d <;> cases q3 : c a e <;>
      cases q4 : c b d <;> cases q5 : c b e <;> cases q6 : c d e <;>
      simp_all [quadMono]


/-- **R(4,4) ≤ 18**：`K₁₈` 的任一 2-著色都含單色 `K₄`。

遞推 `R(4,4) ≤ R(3,4) + R(4,3) = 9 + 9`：頂點 `0` 的 17 條邊中必有一種顏色至少 9 條
（`9 + 8 < 17`）。取 9 個同色鄰點，限制過去的著色不能有同色的三角形（否則與 `0`
湊成單色 `K₄`），於是 `R(3,4) ≤ 9`／`R(4,3) ≤ 9` 立刻矛盾。 -/
theorem r44_le_18 (c : Fin 18 → Fin 18 → Bool)
    (hsymm : ∀ i j : Fin 18, c i j = c j i)
    (hNoRed4 : ∀ a b d e : Fin 18, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c true a b d e = false)
    (hNoBlue4 : ∀ a b d e : Fin 18, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
      quadMono c false a b d e = false) : False := by
  have hsplit : (nbhd c 0 true).length + (nbhd c 0 false).length = 17 := by
    have := deg_split c (0 : Fin 18)
    omega
  by_cases hA : 9 ≤ (nbhd c 0 true).length
  · obtain ⟨ws, hlen, hndw, hmem⟩ :=
      KtLaws.Graph.exists_subset_len (nbhd c 0 true) 9
        (KtLaws.Graph.nodup_filter _ (List.nodup_finRange 18)) hA
    obtain ⟨w, hwin, hinj⟩ := KtLaws.Graph.mkfun ws hndw 9 hlen
    have hred : ∀ i : Fin 9, c 0 (w i) = true := fun i => (mem_nbhd (hmem _ (hwin i))).1
    have hne : ∀ i : Fin 9, w i ≠ 0 := fun i => (mem_nbhd (hmem _ (hwin i))).2
    have hdist : ∀ i j : Fin 9, i ≠ j → w i ≠ w j := by
      intro i j hij heq
      exact hij (hinj i j heq)
    refine r34_le_9 (fun i j => c (w i) (w j)) (fun i j => hsymm _ _) ?_ ?_
    · intro a b d hab hbd had
      by_cases hq : triRed (fun i j => c (w i) (w j)) a b d = true
      · exfalso
        have h1 := triRed_one hq
        have h2 := triRed_two hq
        have h3 := triRed_three hq
        have hq4 : quadMono c true 0 (w a) (w b) (w d) = true :=
          quadMono_all (hred a) (hred b) (hred d) h1 h3 h2
        rw [hNoRed4 0 (w a) (w b) (w d) (hne a).symm (hne b).symm (hne d).symm
          (hdist a b hab) (hdist a d had) (hdist b d hbd)] at hq4
        exact absurd hq4 (by simp)
      · simpa using hq
    · intro a b d e h1 h2 h3 h4 h5 h6
      by_cases hq : quadMono (fun i j => c (w i) (w j)) false a b d e = true
      · exfalso
        have hq' : quadMono c false (w a) (w b) (w d) (w e) = true := by
          simpa [quadMono] using hq
        rw [hNoBlue4 (w a) (w b) (w d) (w e) (hdist a b h1) (hdist a d h2) (hdist a e h3)
          (hdist b d h4) (hdist b e h5) (hdist d e h6)] at hq'
        exact absurd hq' (by simp)
      · simpa using hq
  · obtain ⟨ws, hlen, hndw, hmem⟩ :=
      KtLaws.Graph.exists_subset_len (nbhd c 0 false) 9
        (KtLaws.Graph.nodup_filter _ (List.nodup_finRange 18)) (by omega)
    obtain ⟨w, hwin, hinj⟩ := KtLaws.Graph.mkfun ws hndw 9 hlen
    have hblue : ∀ i : Fin 9, c 0 (w i) = false := fun i => (mem_nbhd (hmem _ (hwin i))).1
    have hne : ∀ i : Fin 9, w i ≠ 0 := fun i => (mem_nbhd (hmem _ (hwin i))).2
    have hdist : ∀ i j : Fin 9, i ≠ j → w i ≠ w j := by
      intro i j hij heq
      exact hij (hinj i j heq)
    refine r43_le_9 (fun i j => c (w i) (w j)) (fun i j => hsymm _ _) ?_ ?_
    · intro a b d e h1 h2 h3 h4 h5 h6
      by_cases hq : quadMono (fun i j => c (w i) (w j)) true a b d e = true
      · exfalso
        have hq' : quadMono c true (w a) (w b) (w d) (w e) = true := by
          simpa [quadMono] using hq
        rw [hNoRed4 (w a) (w b) (w d) (w e) (hdist a b h1) (hdist a d h2) (hdist a e h3)
          (hdist b d h4) (hdist b e h5) (hdist d e h6)] at hq'
        exact absurd hq' (by simp)
      · simpa using hq
    · intro a b d hab hbd had
      by_cases hq : triBlue (fun i j => c (w i) (w j)) a b d = true
      · exfalso
        have h1 := triBlue_one hq
        have h2 := triBlue_two hq
        have h3 := triBlue_three hq
        have hq4 : quadMono c false 0 (w a) (w b) (w d) = true :=
          quadMono_all (hblue a) (hblue b) (hblue d) h1 h3 h2
        rw [hNoBlue4 0 (w a) (w b) (w d) (hne a).symm (hne b).symm (hne d).symm
          (hdist a b hab) (hdist a d had) (hdist b d hbd)] at hq4
        exact absurd hq4 (by simp)
      · simpa using hq


/-! ### 精確值：`R(3,4) = 9`、`R(4,4) = 18` -/

/-- **`R(3,4) = 9`**：上界（任何 `K₉` 的 2-著色都有紅 `K₃` 或藍 `K₄`）＋
下界（`Z₈` circulant 在 `K₈` 上既無紅 `K₃` 也無藍 `K₄`）。 -/
theorem ramsey34_eq :
    (∀ c : Fin 9 → Fin 9 → Bool, (∀ i j : Fin 9, c i j = c j i) →
      (∀ a b d : Fin 9, a ≠ b → b ≠ d → a ≠ d → triMono c a b d = true → False) →
      (∀ a b d : Fin 9, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false) →
      (∀ a b d e : Fin 9, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
        quadMono c false a b d e = false) → False) ∧
    (∀ a b c : Fin 8, a < b → b < c → Red3 Circ8 a b c = false) ∧
    (∀ a b c d : Fin 8, a < b → b < c → c < d → Blue4 Circ8 a b c d = false) :=
  ⟨fun c hsymm hMono hRed hBlue => r34_le_9 c hsymm hRed hBlue,
    circ8_no_red3, circ8_no_blue4⟩

/-- **`R(4,4) = 18`**：上界 `r44_le_18`（`K₁₈` 必有單色 `K₄`）＋
下界 Paley `P₁₇`（`K₁₇` 上有無單色 `K₄` 的 2-著色）。 -/
theorem ramsey44_eq :
    (∀ c : Fin 18 → Fin 18 → Bool, (∀ i j : Fin 18, c i j = c j i) →
      (∀ a b d e : Fin 18, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
        quadMono c true a b d e = false) →
      (∀ a b d e : Fin 18, a ≠ b → a ≠ d → a ≠ e → b ≠ d → b ≠ e → d ≠ e →
        quadMono c false a b d e = false) → False) ∧
    (∀ a b c d : Fin 17, a < b → b < c → c < d → Red4 Paley a b c d = false) ∧
    (∀ a b c d : Fin 17, a < b → b < c → c < d → Blue4 Paley a b c d = false) :=
  ⟨fun c hsymm hRed hBlue => r44_le_18 c hsymm hRed hBlue,
    paley17_no_mono_K4.1, paley17_no_mono_K4.2⟩


/-! ### `R(3,5) = 14` -/

/-- 差集 `{1,5,8,12} ⊂ Z₁₃`（Greenwood–Gleason 圖的循環差集）。 -/
def inGG13 (n : Nat) : Bool := n == 1 || n == 5 || n == 8 || n == 12

/-- **Greenwood–Gleason 圖** `GG(3,5;13)`：`K₁₃` 上無三角形、補圖無 `K₅` 的 2-著色。 -/
def GG13 (i j : Fin 13) : Bool := inGG13 ((j.val + 13 - i.val) % 13)

theorem quadFalse_one {α : Type} {c : α → α → Bool} {a b d e : α}
    (h : quadMono c false a b d e = true) : c a b = false := by
  unfold quadMono at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.1.1.1.1

theorem quadFalse_two {α : Type} {c : α → α → Bool} {a b d e : α}
    (h : quadMono c false a b d e = true) : c a d = false := by
  unfold quadMono at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.1.1.1.2

theorem quadFalse_three {α : Type} {c : α → α → Bool} {a b d e : α}
    (h : quadMono c false a b d e = true) : c a e = false := by
  unfold quadMono at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.1.1.2

theorem quadFalse_four {α : Type} {c : α → α → Bool} {a b d e : α}
    (h : quadMono c false a b d e = true) : c b d = false := by
  unfold quadMono at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.1.2

theorem quadFalse_five {α : Type} {c : α → α → Bool} {a b d e : α}
    (h : quadMono c false a b d e = true) : c b e = false := by
  unfold quadMono at h
  simp only [Bool.and_eq_true] at h
  simpa using h.1.2

theorem quadFalse_six {α : Type} {c : α → α → Bool} {a b d e : α}
    (h : quadMono c false a b d e = true) : c d e = false := by
  unfold quadMono at h
  simp only [Bool.and_eq_true] at h
  simpa using h.2

/-- 五點十邊全藍（藍色 `K₅`）。 -/
def fiveBlue {α : Type} (c : α → α → Bool) (a b d e g : α) : Bool :=
  !(c a b) && !(c a d) && !(c a e) && !(c a g) && !(c b d) && !(c b e) && !(c b g) &&
  !(c d e) && !(c d g) && !(c e g)

theorem fiveBlue_of {α : Type} {c : α → α → Bool} {a b d e g : α}
    (h1 : c a b = false) (h2 : c a d = false) (h3 : c a e = false) (h4 : c a g = false)
    (h5 : c b d = false) (h6 : c b e = false) (h7 : c b g = false)
    (h8 : c d e = false) (h9 : c d g = false) (h10 : c e g = false) :
    fiveBlue c a b d e g = true := by
  simp [fiveBlue, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10]

theorem gg13_symm (i j : Fin 13) : GG13 i j = GG13 j i := by
  revert i j
  decide

/-- `GG13` 在 `K₁₃` 上沒有紅色 `K₃`。 -/
theorem gg13_no_red3 : ∀ a b d : Fin 13, a < b → b < d → a < d → triRed GG13 a b d = false := by
  decide

/-- `GG13` 的補圖在 `K₁₃` 上沒有藍色 `K₅`。 -/
theorem gg13_no_blue5 :
    ∀ a b d e g : Fin 13, a < b → b < d → d < e → e < g → fiveBlue GG13 a b d e g = false := by
  native_decide


/-- **`R(3,5) ≤ 14`**：`K₁₄` 的任一 2-著色都含紅色 `K₃` 或藍色 `K₅`。

遞推 `R(3,5) ≤ R(2,5) + R(3,4) = 5 + 9`：頂點 `0` 的 13 條邊中，
要嘛有 5 條紅（那 5 個紅鄰點之間不能有紅邊，否則與 `0` 構成紅 `K₃`，於是全藍 ⇒ 藍 `K₅`），
要嘛有 9 條藍（那 9 個藍鄰點上不能有紅 `K₃`，也不能有藍 `K₄`——後者與 `0` 湊成藍 `K₅`——
於是 `R(3,4) ≤ 9` 給出矛盾）。 -/
theorem r35_le_14 (c : Fin 14 → Fin 14 → Bool)
    (hsymm : ∀ i j : Fin 14, c i j = c j i)
    (hNoRed3 : ∀ a b d : Fin 14, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false)
    (hNoBlue5 : ∀ a b d e g : Fin 14,
      a ≠ b → a ≠ d → a ≠ e → a ≠ g → b ≠ d → b ≠ e → b ≠ g → d ≠ e → d ≠ g → e ≠ g →
      fiveBlue c a b d e g = false) : False := by
  have hsplit : (nbhd c 0 true).length + (nbhd c 0 false).length = 13 := by
    have := deg_split c (0 : Fin 14)
    omega
  by_cases hA : 5 ≤ (nbhd c 0 true).length
  · -- 五個紅鄰點 ⇒ 它們之間全藍 ⇒ 藍 K₅
    obtain ⟨ws, hlen, hndw, hmem⟩ :=
      KtLaws.Graph.exists_subset_len (nbhd c 0 true) 5
        (KtLaws.Graph.nodup_filter _ (List.nodup_finRange 14)) hA
    obtain ⟨w, hwin, hinj⟩ := KtLaws.Graph.mkfun ws hndw 5 hlen
    have hred : ∀ i : Fin 5, c 0 (w i) = true := fun i => (mem_nbhd (hmem _ (hwin i))).1
    have hne : ∀ i : Fin 5, w i ≠ 0 := fun i => (mem_nbhd (hmem _ (hwin i))).2
    have hdist : ∀ i j : Fin 5, i ≠ j → w i ≠ w j := by
      intro i j hij heq
      exact hij (hinj i j heq)
    have hblue : ∀ i j : Fin 5, i ≠ j → c (w i) (w j) = false := by
      intro i j hij
      by_cases h : c (w i) (w j) = true
      · exfalso
        have ht : triRed c 0 (w i) (w j) = true := triRed_of (hred i) h (hred j)
        rw [hNoRed3 0 (w i) (w j) (hne i).symm (hdist i j hij) (hne j).symm] at ht
        exact absurd ht (by simp)
      · simpa using h
    have hq : fiveBlue c (w 0) (w 1) (w 2) (w 3) (w 4) = true :=
      fiveBlue_of (hblue 0 1 (by decide)) (hblue 0 2 (by decide)) (hblue 0 3 (by decide))
        (hblue 0 4 (by decide)) (hblue 1 2 (by decide)) (hblue 1 3 (by decide))
        (hblue 1 4 (by decide)) (hblue 2 3 (by decide)) (hblue 2 4 (by decide))
        (hblue 3 4 (by decide))
    rw [hNoBlue5 (w 0) (w 1) (w 2) (w 3) (w 4)
      (hdist 0 1 (by decide)) (hdist 0 2 (by decide)) (hdist 0 3 (by decide))
      (hdist 0 4 (by decide)) (hdist 1 2 (by decide)) (hdist 1 3 (by decide))
      (hdist 1 4 (by decide)) (hdist 2 3 (by decide)) (hdist 2 4 (by decide))
      (hdist 3 4 (by decide))] at hq
    exact absurd hq (by simp)
  · -- 九個藍鄰點 ⇒ 誘導著色無紅 K₃、無藍 K₄ ⇒ R(3,4) ≤ 9
    have hblue9 : 9 ≤ (nbhd c 0 false).length := by omega
    obtain ⟨ws, hlen, hndw, hmem⟩ :=
      KtLaws.Graph.exists_subset_len (nbhd c 0 false) 9
        (KtLaws.Graph.nodup_filter _ (List.nodup_finRange 14)) hblue9
    obtain ⟨w, hwin, hinj⟩ := KtLaws.Graph.mkfun ws hndw 9 hlen
    have hbl : ∀ i : Fin 9, c 0 (w i) = false := fun i => (mem_nbhd (hmem _ (hwin i))).1
    have hne : ∀ i : Fin 9, w i ≠ 0 := fun i => (mem_nbhd (hmem _ (hwin i))).2
    have hdist : ∀ i j : Fin 9, i ≠ j → w i ≠ w j := by
      intro i j hij heq
      exact hij (hinj i j heq)
    refine r34_le_9 (fun i j => c (w i) (w j)) (fun i j => hsymm _ _) ?_ ?_
    · intro a b d hab hbd had
      by_cases hq : triRed (fun i j => c (w i) (w j)) a b d = true
      · exfalso
        have h1 := triRed_one hq
        have h2 := triRed_two hq
        have h3 := triRed_three hq
        have ht : triRed c (w a) (w b) (w d) = true := by
          simp [triRed, h1, h2, h3]
        rw [hNoRed3 (w a) (w b) (w d) (hdist a b hab) (hdist b d hbd) (hdist a d had)] at ht
        exact absurd ht (by simp)
      · simpa using hq
    · intro a b d e h1 h2 h3 h4 h5 h6
      by_cases hq : quadMono (fun i j => c (w i) (w j)) false a b d e = true
      · exfalso
        have hq' : quadMono c false (w a) (w b) (w d) (w e) = true := by
          simpa [quadMono] using hq
        have q1 := quadFalse_one hq'
        have q2 := quadFalse_two hq'
        have q3 := quadFalse_three hq'
        have q4 := quadFalse_four hq'
        have q5 := quadFalse_five hq'
        have q6 := quadFalse_six hq'
        have hq5 : fiveBlue c 0 (w a) (w b) (w d) (w e) = true :=
          fiveBlue_of (hbl a) (hbl b) (hbl d) (hbl e) q1 q2 q3 q4 q5 q6
        rw [hNoBlue5 0 (w a) (w b) (w d) (w e)
          (hne a).symm (hne b).symm (hne d).symm (hne e).symm
          (hdist a b h1) (hdist a d h2) (hdist a e h3)
          (hdist b d h4) (hdist b e h5) (hdist d e h6)] at hq5
        exact absurd hq5 (by simp)
      · simpa using hq

/-- **`R(3,5) = 14`**：上界 `r35_le_14` ＋ 下界（`Z₁₃` 上差集 `{1,5,8,12}` 的循環圖）。 -/
theorem ramsey35_eq :
    (∀ c : Fin 14 → Fin 14 → Bool, (∀ i j : Fin 14, c i j = c j i) →
      (∀ a b d : Fin 14, a ≠ b → b ≠ d → a ≠ d → triRed c a b d = false) →
      (∀ a b d e g : Fin 14,
        a ≠ b → a ≠ d → a ≠ e → a ≠ g → b ≠ d → b ≠ e → b ≠ g → d ≠ e → d ≠ g → e ≠ g →
        fiveBlue c a b d e g = false) → False) ∧
    (∀ a b d : Fin 13, a < b → b < d → a < d → triRed GG13 a b d = false) ∧
    (∀ a b d e g : Fin 13, a < b → b < d → d < e → e < g → fiveBlue GG13 a b d e g = false) :=
  ⟨fun c hsymm h1 h2 => r35_le_14 c hsymm h1 h2, gg13_no_red3, gg13_no_blue5⟩

end KtLaws.Ramsey
