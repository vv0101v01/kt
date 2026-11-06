/-
  KtLaws/Ordinal.lean — Cantor 範式（CNF）序數，對應 MoonBit `meta/core/ordinal.mbt`

  與 MoonBit 側的差別（這是有意的強化）：

  * MoonBit 的 `ord_max is the lattice join` 是 **4 個樣本 × 4 條性質**；
    這裡把「max 是 join」證成對**所有**序數成立：上界、恰為兩者之一、對稱、
    idempotent、associative、以及 join 的定義性質（最小上界）。
  * 為此需要「CNF 唯一 ⇒ 比較是結構性的」，即 `cmp_eq_iff`：`cmp a b = eq ↔ a = b`。
    它在**任意表示**上都成立（不需要範式不變量），因為 `cmp` 只是字典序。
  * 另一個關鍵是 `cmp_swap`：`cmp b a = (cmp a b).swap`。有了它，全序性（totality）與
    對稱性才不是「對樣本驗算」而是定理。

  只用 Lean 4 核心函式庫；沒有 `Finset`/Mathlib。
-/
namespace KtLaws.Ordinal

/-! ### 自然數比較（自帶，因為 core 只給了 `compare` 與 `compare_eq_eq`） -/

/-- 三向比較：`lt` / `eq` / `gt`（與 MoonBit `ord_cmp` 的 -1/0/1 對應）。 -/
def cmpNat (a b : Nat) : Ordering := if a < b then .lt else if a = b then .eq else .gt

/-- `cmpNat` 判等 iff 相等。 -/
theorem cmpNat_eq_iff (a b : Nat) : cmpNat a b = .eq ↔ a = b := by
  unfold cmpNat
  by_cases h : a < b
  · have hne : a ≠ b := by omega
    simp [h, hne]
  · by_cases h2 : a = b
    · simp [h, h2]
    · simp [h, h2]

/-- 交換兩側就是 `swap`：全序的反對稱性在比較函式上的形式。 -/
theorem cmpNat_swap (a b : Nat) : cmpNat b a = (cmpNat a b).swap := by
  unfold cmpNat
  by_cases h : a < b
  · have h' : ¬ b < a := by omega
    have hne : ¬ b = a := by omega
    simp [h, h', hne]
  · by_cases h2 : a = b
    · simp [h, h2]
    · have h3 : b < a := by omega
      simp [h, h2, h3]

/-! ### CNF 序數 -/

/--
序數：項列 `[(c₁,e₁), …]` 表示 `ω^{e₁}·c₁ + …`。
範式不變量（指數嚴格遞減、係數為正）不寫進型別，與 MoonBit 側一致
（那邊是 `ord_is_normal` 執行期檢查）。
-/
inductive Ordinal where
  | ofTerms : List (Nat × Ordinal) → Ordinal

mutual
  /-- 字典序比較（與 MoonBit `ord_cmp` 同序：先指數、再係數、最後短的較小）。 -/
  def cmp : Ordinal → Ordinal → Ordering
    | .ofTerms as, .ofTerms bs => cmpList as bs

  /-- 項列比較。 -/
  def cmpList : List (Nat × Ordinal) → List (Nat × Ordinal) → Ordering
    | [], [] => .eq
    | [], _ => .lt
    | _, [] => .gt
    | (c1, e1) :: r1, (c2, e2) :: r2 =>
      match cmp e1 e2 with
      | .eq =>
        match cmpNat c1 c2 with
        | .eq => cmpList r1 r2
        | o => o
      | o => o
end

/-! ### 比較的兩條結構性定理 -/

/-- **CNF 唯一性**：比較相等 iff 結構相等。 -/
theorem cmp_eq_iff : ∀ a b : Ordinal, cmp a b = .eq ↔ a = b := by
  refine cmp.induct (motive_1 := fun a b => cmp a b = .eq ↔ a = b)
    (motive_2 := fun as bs => cmpList as bs = .eq ↔ as = bs) ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · intro as bs IH
    show cmpList as bs = .eq ↔ Ordinal.ofTerms as = Ordinal.ofTerms bs
    exact ⟨fun h => congrArg Ordinal.ofTerms (IH.mp h),
           fun h => IH.mpr (Ordinal.ofTerms.inj h)⟩
  · show cmpList [] [] = .eq ↔ ([] : List (Nat × Ordinal)) = []
    simp [cmpList]
  · intro x hx
    cases x with
    | nil => exact absurd rfl hx
    | cons hd tl => simp [cmpList]
  · intro t ht
    cases t with
    | nil => exact absurd rfl ht
    | cons hd tl => simp [cmpList]
  · intro c1 e1 r1 c2 e2 r2 h1 h2 IH1 IH2
    have hc : c1 = c2 := (cmpNat_eq_iff c1 c2).mp h2
    have he : e1 = e2 := IH1.mp h1
    subst hc he
    have hl : cmpList ((c1, e1) :: r1) ((c1, e1) :: r2) = cmpList r1 r2 := by
      simp [cmpList, h1, h2]
    rw [hl, IH2]
    simp
  · intro c1 e1 r1 c2 e2 r2 h1 h2 IH1
    have hl : cmpList ((c1, e1) :: r1) ((c2, e2) :: r2)
        = (match cmpNat c1 c2 with | .eq => cmpList r1 r2 | o => o) := by
      simp [cmpList, h1]
    constructor
    · intro h
      rw [hl] at h
      cases hc : cmpNat c1 c2 <;> simp_all
    · intro h
      exfalso
      have hp : (c1, e1) = (c2, e2) := (List.cons.inj h).1
      exact h2 ((cmpNat_eq_iff c1 c2).mpr (congrArg Prod.fst hp))
  · intro c1 e1 r1 c2 e2 r2 h1 IH1
    constructor
    · intro h
      exfalso
      have hl : cmpList ((c1, e1) :: r1) ((c2, e2) :: r2) = cmp e1 e2 := by
        simp [cmpList]
      rw [hl] at h
      exact h1 h
    · intro h
      exfalso
      have hp : (c1, e1) = (c2, e2) := (List.cons.inj h).1
      have he : e1 = e2 := congrArg Prod.snd hp
      exact h1 (IH1.mpr he)

/-- **反對稱**：換邊比較就是 `swap`。 -/
theorem cmp_swap : ∀ a b : Ordinal, cmp b a = (cmp a b).swap := by
  refine cmp.induct (motive_1 := fun a b => cmp b a = (cmp a b).swap)
    (motive_2 := fun as bs => cmpList bs as = (cmpList as bs).swap) ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · intro as bs IH
    show cmpList bs as = (cmpList as bs).swap
    exact IH
  · show cmpList ([] : List (Nat × Ordinal)) [] = (cmpList [] []).swap
    simp [cmpList]
  · intro x hx
    cases x with
    | nil => exact absurd rfl hx
    | cons hd tl => simp [cmpList]
  · intro t ht
    cases t with
    | nil => exact absurd rfl ht
    | cons hd tl => simp [cmpList]
  · intro c1 e1 r1 c2 e2 r2 h1 h2 IH1 IH2
    have he : cmp e2 e1 = .eq := by rw [IH1, h1]; rfl
    have hc : cmpNat c2 c1 = .eq := by rw [cmpNat_swap, h2]; rfl
    have hL : cmpList ((c2, e2) :: r2) ((c1, e1) :: r1) = cmpList r2 r1 := by
      simp [cmpList, he, hc]
    have hR : (cmpList ((c1, e1) :: r1) ((c2, e2) :: r2)).swap
        = (cmpList r1 r2).swap := by
      simp [cmpList, h1, h2]
    rw [hL, hR, IH2]
  · intro c1 e1 r1 c2 e2 r2 h1 h2 IH1
    have he : cmp e2 e1 = .eq := by rw [IH1, h1]; rfl
    have hc : cmpNat c2 c1 ≠ .eq := by
      rw [cmpNat_swap]
      cases h : cmpNat c1 c2 <;> simp_all
    have hL : cmpList ((c2, e2) :: r2) ((c1, e1) :: r1) = cmpNat c2 c1 := by
      simp [cmpList, he, hc]
    have hR : (cmpList ((c1, e1) :: r1) ((c2, e2) :: r2)).swap
        = (cmpNat c1 c2).swap := by
      simp [cmpList, h1, h2]
    rw [hL, hR]
    exact cmpNat_swap c1 c2
  · intro c1 e1 r1 c2 e2 r2 h1 IH1
    have hne : cmp e2 e1 ≠ .eq := by
      rw [IH1]
      cases h : cmp e1 e2 <;> simp_all
    have hL : cmpList ((c2, e2) :: r2) ((c1, e1) :: r1) = cmp e2 e1 := by
      simp [cmpList, hne]
    have hR : (cmpList ((c1, e1) :: r1) ((c2, e2) :: r2)).swap
        = (cmp e1 e2).swap := by
      simp [cmpList, h1]
    rw [hL, hR]
    exact IH1

/-! ### 字典序的遞移性 -/

theorem cmp_ofTerms (as bs : List (Nat × Ordinal)) :
    cmp (.ofTerms as) (.ofTerms bs) = cmpList as bs := rfl

theorem cmpList_nil_cons (x : Nat × Ordinal) (xs : List (Nat × Ordinal)) :
    cmpList [] (x :: xs) = .lt := by
  simp [cmpList]

theorem cmpList_cons_nil (x : Nat × Ordinal) (xs : List (Nat × Ordinal)) :
    cmpList (x :: xs) [] = .gt := by
  simp [cmpList]

theorem cmpList_nil_nil : cmpList ([] : List (Nat × Ordinal)) [] = .eq := by
  simp [cmpList]

theorem cmpList_cons_cons (c1 : Nat) (e1 : Ordinal) (r1 : List (Nat × Ordinal))
    (c2 : Nat) (e2 : Ordinal) (r2 : List (Nat × Ordinal)) :
    cmpList ((c1, e1) :: r1) ((c2, e2) :: r2) =
      (match cmp e1 e2 with
       | .eq => (match cmpNat c1 c2 with | .eq => cmpList r1 r2 | o => o)
       | o => o) := by
  simp [cmpList]

theorem cmpNat_lt (a b : Nat) (h : cmpNat a b = .lt) : a < b := by
  unfold cmpNat at h
  by_cases h1 : a < b
  · exact h1
  · by_cases h2 : a = b <;> simp [h1, h2] at h

theorem cmpNat_lt_trans (a b c : Nat) (h1 : cmpNat a b = .lt) (h2 : cmpNat b c = .lt) :
    cmpNat a c = .lt := by
  have hab : a < b := cmpNat_lt a b h1
  have hbc : b < c := cmpNat_lt b c h2
  unfold cmpNat
  by_cases h : a < c
  · simp [h]
  · simp [h]; omega

theorem cmp_lt_trans : ∀ a b : Ordinal, cmp a b = .lt → ∀ c : Ordinal, cmp b c = .lt → cmp a c = .lt := by
  refine cmp.induct
    (motive_1 := fun a b => cmp a b = .lt → ∀ c : Ordinal, cmp b c = .lt → cmp a c = .lt)
    (motive_2 := fun as bs => cmpList as bs = .lt → ∀ cs, cmpList bs cs = .lt → cmpList as cs = .lt)
    ?_ ?_ ?_ ?_ ?_ ?_ ?_
  · intro as bs IH h1 c h2
    cases c with
    | ofTerms cs => exact IH h1 cs h2
  · intro h1
    rw [cmpList_nil_nil] at h1
    exact absurd h1 (by simp)
  · intro x hx h1 cs h2
    cases cs with
    | nil =>
      cases x with
      | nil => exact absurd rfl hx
      | cons hd tl =>
        rw [cmpList_cons_nil] at h2
        exact absurd h2 (by simp)
    | cons hd tl => exact cmpList_nil_cons hd tl
  · intro t ht h1
    cases t with
    | nil => exact absurd rfl ht
    | cons hd tl =>
      rw [cmpList_cons_nil] at h1
      exact absurd h1 (by simp)
  · intro c1 e1 r1 c2 e2 r2 h1 h2 IH1 IH2 hlt cs h2'
    have hc : c1 = c2 := (cmpNat_eq_iff c1 c2).mp h2
    have he : e1 = e2 := (cmp_eq_iff e1 e2).mp h1
    subst hc he
    simp only [cmpList_cons_cons, h1, h2] at hlt
    cases cs with
    | nil =>
      rw [cmpList_cons_nil] at h2'
      exact absurd h2' (by simp)
    | cons hd tl =>
      obtain ⟨c3, e3⟩ := hd
      simp only [cmpList_cons_cons, h1] at h2'
      cases hY : cmp e1 e3 with
      | gt =>
        rw [hY] at h2'
        exact absurd h2' (by simp)
      | lt => simp only [cmpList_cons_cons, hY]
      | eq =>
        cases hnat3 : cmpNat c1 c3 with
        | lt => simp only [cmpList_cons_cons, hY, hnat3]
        | gt =>
          rw [hY, hnat3] at h2'
          exact absurd h2' (by simp)
        | eq =>
          rw [hY, hnat3] at h2'
          simp only [cmpList_cons_cons, hY, hnat3]
          exact IH2 hlt tl h2'
  · intro c1 e1 r1 c2 e2 r2 h1 h2 IH1 hlt cs h2'
    have he : e1 = e2 := (cmp_eq_iff e1 e2).mp h1
    subst he
    simp only [cmpList_cons_cons, h1] at hlt
    cases hnat : cmpNat c1 c2 with
    | eq => exact absurd hnat h2
    | gt =>
      rw [hnat] at hlt
      exact absurd hlt (by simp)
    | lt =>
      rw [hnat] at hlt
      cases cs with
      | nil =>
        rw [cmpList_cons_nil] at h2'
        exact absurd h2' (by simp)
      | cons hd tl =>
        obtain ⟨c3, e3⟩ := hd
        simp only [cmpList_cons_cons, h1] at h2'
        cases hY : cmp e1 e3 with
        | gt =>
          rw [hY] at h2'
          exact absurd h2' (by simp)
        | lt => simp only [cmpList_cons_cons, hY]
        | eq =>
          cases hnat3 : cmpNat c2 c3 with
          | lt =>
            have h13 : cmpNat c1 c3 = .lt := cmpNat_lt_trans c1 c2 c3 hnat hnat3
            simp only [cmpList_cons_cons, hY, h13]
          | gt =>
            rw [hY, hnat3] at h2'
            exact absurd h2' (by simp)
          | eq =>
            have hc23 : c2 = c3 := (cmpNat_eq_iff c2 c3).mp hnat3
            subst hc23
            rw [hY, hnat3] at h2'
            simp only [cmpList_cons_cons, hY, hnat]
  · intro c1 e1 r1 c2 e2 r2 h1 IH1 hlt
    simp only [cmpList_cons_cons] at hlt
    cases hX : cmp e1 e2 with
    | eq => exact absurd hX h1
    | gt =>
      rw [hX] at hlt
      exact absurd hlt (by simp)
    | lt =>
      rw [hX] at hlt
      intro cs h2'
      cases cs with
      | nil =>
        rw [cmpList_cons_nil] at h2'
        exact absurd h2' (by simp)
      | cons hd tl =>
        obtain ⟨c3, e3⟩ := hd
        simp only [cmpList_cons_cons] at h2'
        cases hY : cmp e2 e3 with
        | gt =>
          rw [hY] at h2'
          exact absurd h2' (by simp)
        | eq =>
          have he : e2 = e3 := (cmp_eq_iff e2 e3).mp hY
          subst he
          simp only [cmpList_cons_cons, hX]
        | lt =>
          have h13 : cmp e1 e3 = .lt := IH1 hX e3 hY
          simp only [cmpList_cons_cons, h13]

/-! ### 順序與 join -/

def leq (a b : Ordinal) : Prop := cmp a b ≠ .gt

def ordMax (a b : Ordinal) : Ordinal := match cmp a b with | .lt => b | _ => a

theorem cmp_self (a : Ordinal) : cmp a a = .eq := (cmp_eq_iff a a).mpr rfl

theorem leq_refl (a : Ordinal) : leq a a := by
  unfold leq; rw [cmp_self a]; simp

theorem leq_total (a b : Ordinal) : leq a b ∨ leq b a := by
  unfold leq
  cases h : cmp a b <;> simp_all [cmp_swap a b]

theorem leq_antisymm {a b : Ordinal} (h1 : leq a b) (h2 : leq b a) : a = b := by
  unfold leq at h1 h2
  cases h : cmp a b <;> simp_all [cmp_swap a b, cmp_eq_iff]

theorem max_upper_left (a b : Ordinal) : leq a (ordMax a b) := by
  unfold leq ordMax
  cases h : cmp a b <;> simp_all [cmp_self]

theorem max_upper_right (a b : Ordinal) : leq b (ordMax a b) := by
  unfold leq ordMax
  cases h : cmp a b <;> simp_all [cmp_swap a b, cmp_self, cmp_eq_iff]

theorem max_is_one (a b : Ordinal) : ordMax a b = a ∨ ordMax a b = b := by
  unfold ordMax
  cases h : cmp a b <;> simp_all

theorem max_comm (a b : Ordinal) : cmp (ordMax a b) (ordMax b a) = .eq := by
  unfold ordMax
  cases h : cmp a b <;> simp_all [cmp_swap a b, cmp_self]

theorem max_idem (a : Ordinal) : ordMax a a = a := by
  unfold ordMax; rw [cmp_self a]

theorem max_is_join {a b c : Ordinal} (ha : leq a c) (hb : leq b c) :
    leq (ordMax a b) c := by
  unfold leq at *; unfold ordMax
  cases h : cmp a b <;> simp_all


/-- `≤` 的遞移性（由 `lt` 的遞移性 + CNF 唯一性）。 -/
theorem leq_trans {a b c : Ordinal} (h1 : leq a b) (h2 : leq b c) : leq a c := by
  unfold leq at *
  cases hab : cmp a b with
  | gt => exact absurd hab h1
  | eq =>
    have hae : a = b := (cmp_eq_iff a b).mp hab
    subst hae
    exact h2
  | lt =>
    cases hbc : cmp b c with
    | gt => exact absurd hbc h2
    | eq =>
      have hbe : b = c := (cmp_eq_iff b c).mp hbc
      subst hbe
      exact h1
    | lt =>
      have h := cmp_lt_trans a b hab c hbc
      rw [h]
      simp

/-- `ordMax` 就是 `≤` 的上確界：`max a b ≤ c ↔ a ≤ c ∧ b ≤ c`。 -/
theorem max_le_iff (a b c : Ordinal) : leq (ordMax a b) c ↔ leq a c ∧ leq b c := by
  constructor
  · intro h
    exact ⟨leq_trans (max_upper_left a b) h, leq_trans (max_upper_right a b) h⟩
  · intro h
    exact max_is_join h.1 h.2

/-- **結合律**（`ordMax` 是 join ⇒ 結合）。 -/
theorem max_assoc (a b c : Ordinal) :
    cmp (ordMax (ordMax a b) c) (ordMax a (ordMax b c)) = .eq := by
  have hbc : leq b (ordMax a (ordMax b c)) :=
    leq_trans (max_upper_left b c) (max_upper_right a (ordMax b c))
  have hab : leq (ordMax a b) (ordMax (ordMax a b) c) := max_upper_left _ c
  have h1 : leq (ordMax (ordMax a b) c) (ordMax a (ordMax b c)) := by
    apply max_is_join
    · apply max_is_join
      · exact max_upper_left a (ordMax b c)
      · exact hbc
    · exact leq_trans (max_upper_right b c) (max_upper_right a (ordMax b c))
  have h2 : leq (ordMax a (ordMax b c)) (ordMax (ordMax a b) c) := by
    apply max_is_join
    · exact leq_trans (max_upper_left a b) hab
    · apply max_is_join
      · exact leq_trans (max_upper_right a b) hab
      · exact max_upper_right _ c
  exact (cmp_eq_iff _ _).mpr (leq_antisymm h1 h2)

/-- 結合律的等式形式（`cmp` 相等 ⇒ 結構相等）。 -/
theorem max_assoc_eq (a b c : Ordinal) :
    ordMax (ordMax a b) c = ordMax a (ordMax b c) :=
  (cmp_eq_iff _ _).mp (max_assoc a b c)

/-! ### CNF 加法與 MoonBit 的 10 條恆等式

`ord_add` 的規則與 MoonBit 一致：保留 `a` 中指數 ≥ `b` 首項指數的前綴；
最後一項指數相等就合併係數，否則 `a` 的尾巴整段被吸收（`1 + ω = ω`）。
-/

/-- 0。 -/
def ordZero : Ordinal := .ofTerms []

/-- `c · ω^e`（`c = 0` 時退化成 0，與 MoonBit `ord_term` 一致）。 -/
def ordTerm (c : Nat) (e : Ordinal) : Ordinal := if c = 0 then ordZero else .ofTerms [(c, e)]

/-- 1。 -/
def ordOne : Ordinal := ordTerm 1 ordZero

/-- 有限序數 `n`。 -/
def ordOfNat (n : Nat) : Ordinal := ordTerm n ordZero

/-- `ω`。 -/
def ordOmega : Ordinal := ordTerm 1 ordOne

/-- `ω^k`。 -/
def ordOmegaPow (k : Ordinal) : Ordinal := ordTerm 1 k

/-- 項列加法：指數 > 就繼續、= 就合併係數、< 就整段吸收。 -/
def addTerms : List (Nat × Ordinal) → List (Nat × Ordinal) → List (Nat × Ordinal)
  | [], bs => bs
  | as, [] => as
  | (c1, e1) :: r1, (c2, e2) :: r2 =>
    match cmp e1 e2 with
    | .gt => (c1, e1) :: addTerms r1 ((c2, e2) :: r2)
    | .eq => (c1 + c2, e1) :: r2
    | .lt => (c2, e2) :: r2

/-- 序數加法。 -/
def ordAdd (a b : Ordinal) : Ordinal :=
  match a, b with
  | .ofTerms as, .ofTerms bs => .ofTerms (addTerms as bs)

/-- 後繼 `a + 1`。 -/
def ordSucc (a : Ordinal) : Ordinal := ordAdd a ordOne

/-- 右乘有限數：係數相乘。 -/
def ordMulInt (a : Ordinal) (n : Nat) : Ordinal :=
  if n = 0 then ordZero
  else
    match a with
    | .ofTerms as => .ofTerms (as.map (fun p => (p.1 * n, p.2)))

/-- 右乘 `ω`：`a = ω^{e₀}c₀ + …` ⇒ `a·ω = ω^{e₀+1}`。 -/
def ordMulOmega (a : Ordinal) : Ordinal :=
  match a with
  | .ofTerms [] => ordZero
  | .ofTerms ((_, e) :: _) => ordTerm 1 (ordSucc e)

/-- 範式性：係數為正、指數遞減、且每項的指數大於其後所有項的指數。 -/
def isNormal : Ordinal → Bool
  | .ofTerms [] => true
  | .ofTerms ((c, e) :: rest) =>
    decide (0 < c) && isNormal e && isNormal (.ofTerms rest) &&
      rest.all (fun p => cmp e p.2 == .gt)

/-- CNF 定律 #1：`1 + ω = ω`（吸收律）。 -/
theorem cnf_absorption : cmp (ordAdd ordOne ordOmega) ordOmega = .eq := by decide

/-- CNF 定律 #2：`ω < ω + 1`（加法不交換）。 -/
theorem cnf_succ_gt : cmp ordOmega (ordAdd ordOmega ordOne) = .lt := by decide

/-- CNF 定律 #3：`ω + ω = ω · 2`。 -/
theorem cnf_omega_two : cmp (ordAdd ordOmega ordOmega) (ordMulInt ordOmega 2) = .eq := by
  decide

/-- CNF 定律 #4：`1 + (ω + 1) = ω + 1`。 -/
theorem cnf_one_plus_succ_omega :
    cmp (ordAdd ordOne (ordAdd ordOmega ordOne)) (ordAdd ordOmega ordOne) = .eq := by decide

/-- CNF 定律 #5：`ω + ω² = ω²`。 -/
theorem cnf_omega_plus_square :
    cmp (ordAdd ordOmega (ordOmegaPow (ordOfNat 2))) (ordOmegaPow (ordOfNat 2)) = .eq := by
  decide

/-- CNF 定律 #6：`ω · 1000000 < ω^ω`。 -/
theorem cnf_finite_below_tower :
    cmp (ordMulInt ordOmega 1000000) (ordOmegaPow ordOmega) = .lt := by decide

/-- CNF 定律 #7：加法結合律（實例）。 -/
theorem cnf_assoc :
    cmp (ordAdd (ordAdd (ordOfNat 3) ordOmega) ordOne)
      (ordAdd (ordOfNat 3) (ordAdd ordOmega ordOne)) = .eq := by decide

/-- CNF 定律 #8：`ω^(ω^ω)` 是範式且嚴格大於 `ω^ω`。 -/
theorem cnf_tower :
    isNormal (ordOmegaPow (ordOmegaPow ordOmega)) = true ∧
      cmp (ordOmegaPow ordOmega) (ordOmegaPow (ordOmegaPow ordOmega)) = .lt := by
  refine ⟨?_, ?_⟩ <;> native_decide

/-- CNF 定律 #9：範式性在加法下封閉（實例）。 -/
theorem cnf_normal_closed :
    isNormal (ordAdd (ordAdd (ordOmegaPow (ordOfNat 2)) (ordMulInt ordOmega 3)) (ordOfNat 7)) =
      true := by
  native_decide

/-- CNF 定律 #10：`ω² · ω = ω³`。 -/
theorem cnf_mul_omega :
    cmp (ordMulOmega (ordOmegaPow (ordOfNat 2))) (ordOmegaPow (ordOfNat 3)) = .eq := by decide

end KtLaws.Ordinal
