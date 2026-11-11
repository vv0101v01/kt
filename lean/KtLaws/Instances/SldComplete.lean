/-
  KtLaws/Instances/SldComplete.lean — SLD 搜尋完備性（O2 義務，誠實版本）

  WHY.md §3 的 O2 草案：
    `sld_complete (e : Env) (g : UTerm) (d : Nat) : solvable e g d ↔ ∃ t : Deriv, deriv e g d t`

  本倉沒有獨立的 `Deriv` 歸納謂詞：SLD 搜尋就是 `resolveAll e g d`（窮舉所有推導）與
  `solvable e g d`（短路存在性搜尋）。`resolveAll e g d ≠ []` 正是「存在一條推導」的定義。
  兩者共用同一個燃料換算（`2 * d + 4`），因此落倉主定理為：

    `sld_complete (e : Env) (g : UTerm) (d : Nat) : resolveAll e g d ≠ [] ↔ solvable e g d = true`

  全部為 kernel 層級的歸納證明（不依賴 decide / 抽樣），無 `sorry`。
-/
import KtLaws.Instances.Engine

namespace KtLaws.Instances

/-- `xs ++ ys ≠ [] ↔ xs ≠ [] ∨ ys ≠ []`。 -/
private theorem append_ne_nil {α : Type} {xs ys : List α} :
    (xs ++ ys) ≠ [] ↔ xs ≠ [] ∨ ys ≠ [] := by
  by_cases hx : xs = []
  · subst hx; simp
  · by_cases hy : ys = []
    · subst hy; simp [hx]
    · simp [hx, hy]

/-- 非 nil 清單分解成 cons。 -/
private theorem exists_cons_of_ne_nil {α : Type} {l : List α} (h : l ≠ []) :
    ∃ (a : α) (rest : List α), l = a :: rest := by
  cases hc : l with
  | nil => exact absurd hc h
  | cons a rest => exact ⟨a, rest, rfl⟩

private theorem eq_solveBody_zero (e : Env) (bs seen : List UTerm) (i : Nat) (g : UTerm) (kids : List Deriv) :
    solveBody e 0 bs seen i g kids = [] := rfl
private theorem eq_solveBody_succ_nil (e : Env) (k : Nat) (seen : List UTerm) (i : Nat) (g : UTerm) (kids : List Deriv) :
    solveBody e (Nat.succ k) [] seen i g kids = [{ rule := i, kids := kids, goal := g }] := rfl
private theorem eq_solveBody_succ_cons (e : Env) (k : Nat) (b : UTerm) (bs seen : List UTerm) (i : Nat) (g : UTerm) (kids : List Deriv) :
    solveBody e (Nat.succ k) (b :: bs) seen i g kids
      = solveBodyFrom e k bs seen i g kids (resolvePath e k b seen) := rfl
private theorem eq_solveBodyFrom_zero (e : Env) (bs seen : List UTerm) (i : Nat) (g : UTerm) (kids ds : List Deriv) :
    solveBodyFrom e 0 bs seen i g kids ds = [] := rfl
private theorem eq_solveBodyFrom_succ_nil (e : Env) (k : Nat) (bs seen : List UTerm) (i : Nat) (g : UTerm) (kids : List Deriv) :
    solveBodyFrom e (Nat.succ k) bs seen i g kids [] = [] := rfl
private theorem eq_solveBodyFrom_succ_cons (e : Env) (k : Nat) (bs seen : List UTerm) (i : Nat) (g : UTerm)
    (kids : List Deriv) (d : Deriv) (ds : List Deriv) :
    solveBodyFrom e (Nat.succ k) bs seen i g kids (d :: ds)
      = solveBody e k bs seen i g (kids ++ [d]) ++ solveBodyFrom e k bs seen i g kids ds := rfl
private theorem eq_hasBody_zero (e : Env) (bs seen : List UTerm) : hasBody e 0 bs seen = false := rfl
private theorem eq_hasBody_succ_nil (e : Env) (k : Nat) (seen : List UTerm) :
    hasBody e (Nat.succ k) [] seen = true := rfl
private theorem eq_hasBody_succ_cons (e : Env) (k : Nat) (b : UTerm) (bs seen : List UTerm) :
    hasBody e (Nat.succ k) (b :: bs) seen = (hasPath e k b seen && hasBody e k bs seen) := rfl
private theorem eq_hasPath_zero (e : Env) (g : UTerm) (seen : List UTerm) : hasPath e 0 g seen = false := rfl
private theorem eq_hasPath_succ (e : Env) (k : Nat) (g : UTerm) (seen : List UTerm) :
    hasPath e (Nat.succ k) g seen = if keyIn seen g = true then false else hasRuleList e k g (g :: seen) e.rules 0 := rfl
private theorem eq_resolvePath_zero (e : Env) (g : UTerm) (seen : List UTerm) : resolvePath e 0 g seen = [] := rfl
private theorem eq_resolvePath_succ (e : Env) (k : Nat) (g : UTerm) (seen : List UTerm) :
    resolvePath e (Nat.succ k) g seen = if keyIn seen g = true then [] else resolveRuleList e k g (g :: seen) 0 e.rules := rfl
private theorem eq_hasRuleList_zero (e : Env) (g : UTerm) (seen : List UTerm) (rs : List Rule) (i : Nat) :
    hasRuleList e 0 g seen rs i = false := rfl
private theorem eq_hasRuleList_succ_nil (e : Env) (k : Nat) (g : UTerm) (seen : List UTerm) (i : Nat) :
    hasRuleList e (Nat.succ k) g seen [] i = false := rfl
private theorem eq_resolveRuleList_zero (e : Env) (g : UTerm) (seen : List UTerm) (i : Nat) (rs : List Rule) :
    resolveRuleList e 0 g seen i rs = [] := rfl
private theorem eq_resolveRuleList_succ_nil (e : Env) (k : Nat) (g : UTerm) (seen : List UTerm) (i : Nat) :
    resolveRuleList e (Nat.succ k) g seen i [] = [] := rfl

mutual

  /-- `solveBody` 的 `kids` 不變式：推導樹只流進 `kids` 欄位，不進入任何合一或述詞。 -/
  theorem solveBody_kids_congr (e : Env) (n : Nat) : ∀
      (bs : List UTerm) (seen : List UTerm) (i : Nat) (g0 : UTerm)
      (kids₁ kids₂ : List Deriv),
      solveBody e n bs seen i g0 kids₁ ≠ [] ↔ solveBody e n bs seen i g0 kids₂ ≠ [] := by
    match n with
    | 0 => intro bs seen i g0 kids₁ kids₂; simp [eq_solveBody_zero]
    | Nat.succ k =>
      intro bs seen i g0 kids₁ kids₂
      cases bs with
      | nil => simp [eq_solveBody_succ_nil]
      | cons b bs =>
        rw [eq_solveBody_succ_cons, eq_solveBody_succ_cons]
        apply solveBodyFrom_kids_congr

  /-- `solveBodyFrom` 的 `kids` 不變式。 -/
  theorem solveBodyFrom_kids_congr (e : Env) (n : Nat) : ∀
      (bs : List UTerm) (seen : List UTerm) (i : Nat) (g0 : UTerm)
      (kids₁ kids₂ : List Deriv) (ds : List Deriv),
      solveBodyFrom e n bs seen i g0 kids₁ ds ≠ [] ↔ solveBodyFrom e n bs seen i g0 kids₂ ds ≠ [] := by
    match n with
    | 0 => intro bs seen i g0 kids₁ kids₂ ds; simp [eq_solveBodyFrom_zero]
    | Nat.succ k =>
      intro bs seen i g0 kids₁ kids₂ ds
      cases ds with
      | nil => simp [eq_solveBodyFrom_succ_nil]
      | cons d ds =>
        rw [eq_solveBodyFrom_succ_cons, eq_solveBodyFrom_succ_cons]
        rw [append_ne_nil, append_ne_nil]
        rw [solveBody_kids_congr e k bs seen i g0 (kids₁ ++ [d]) (kids₂ ++ [d])]
        exact or_congr Iff.rfl (solveBodyFrom_kids_congr e k bs seen i g0 kids₁ kids₂ ds)

  /-- `solveBody` 的規則索引 `i` 不變式：`i` 只流進 `Deriv.rule` 欄位。 -/
  theorem solveBody_i_congr (e : Env) (n : Nat) : ∀
      (bs : List UTerm) (seen : List UTerm) (i₁ i₂ : Nat) (g0 : UTerm)
      (kids : List Deriv),
      solveBody e n bs seen i₁ g0 kids ≠ [] ↔ solveBody e n bs seen i₂ g0 kids ≠ [] := by
    match n with
    | 0 => intro bs seen i₁ i₂ g0 kids; simp [eq_solveBody_zero]
    | Nat.succ k =>
      intro bs seen i₁ i₂ g0 kids
      cases bs with
      | nil => simp [eq_solveBody_succ_nil]
      | cons b bs =>
        rw [eq_solveBody_succ_cons, eq_solveBody_succ_cons]
        apply solveBodyFrom_i_congr

  /-- `solveBodyFrom` 的規則索引 `i` 不變式。 -/
  theorem solveBodyFrom_i_congr (e : Env) (n : Nat) : ∀
      (bs : List UTerm) (seen : List UTerm) (i₁ i₂ : Nat) (g0 : UTerm)
      (kids : List Deriv) (ds : List Deriv),
      solveBodyFrom e n bs seen i₁ g0 kids ds ≠ [] ↔ solveBodyFrom e n bs seen i₂ g0 kids ds ≠ [] := by
    match n with
    | 0 => intro bs seen i₁ i₂ g0 kids ds; simp [eq_solveBodyFrom_zero]
    | Nat.succ k =>
      intro bs seen i₁ i₂ g0 kids ds
      cases ds with
      | nil => simp [eq_solveBodyFrom_succ_nil]
      | cons d ds =>
        rw [eq_solveBodyFrom_succ_cons, eq_solveBodyFrom_succ_cons]
        rw [append_ne_nil, append_ne_nil]
        rw [solveBody_i_congr e k bs seen i₁ i₂ g0 (kids ++ [d])]
        exact or_congr Iff.rfl (solveBodyFrom_i_congr e k bs seen i₁ i₂ g0 kids ds)

  /-- body 全體可解性（context 自由的不變式）——「`hasBody e (Nat.succ k)` ↔ Ne @ level k」。
      對 `k` 歸納；呼叫鏈只沿構造子縮減（children 在子燃料）。 -/
  theorem hasBody_ne (e : Env) (g0 : UTerm) (k : Nat) : ∀ (bs : List UTerm) (seen : List UTerm),
      hasBody e (Nat.succ k) bs seen = true ↔ ∀ (i : Nat) (kids : List Deriv),
        solveBody e k bs seen i g0 kids ≠ [] := by
    match k with
    | 0 =>
      intro bs seen
      constructor
      · intro h _ _
        cases bs with
        | nil =>
          simp [eq_hasBody_succ_nil] at h
        | cons b bs =>
          rw [eq_hasBody_succ_cons, eq_hasPath_zero] at h
          simp at h
      · intro hall
        cases bs with
        | nil => exact rfl
        | cons b bs =>
          have h0 := hall 0 ([] : List Deriv)
          rw [eq_solveBody_zero] at h0
          exact absurd rfl h0
    | Nat.succ k' =>
      intro bs seen
      cases bs with
      | nil =>
        constructor
        · intro _ i kids; rw [eq_solveBody_succ_nil]; simp
        · intro _; rfl
      | cons b bs =>
        rw [eq_hasBody_succ_cons, eq_solveBody_succ_cons]
        constructor
        · intro h i kids
          have hp := (Bool.and_eq_true _ _).mp h
          have hrne : resolvePath e (Nat.succ k') b seen ≠ [] :=
            (hasPath_ne e (Nat.succ k') (g := b) (seen := seen)).mp hp.1
          obtain ⟨d, rest, hd⟩ := exists_cons_of_ne_nil hrne
          rw [hd, eq_solveBodyFrom_succ_cons, append_ne_nil]
          left
          exact (hasBody_ne e g0 k' bs seen).mp hp.2 i (kids ++ [d])
        · intro hhall
          have hrne : resolvePath e (Nat.succ k') b seen ≠ [] := by
            intro heq
            have h0 : solveBodyFrom e k' bs seen 0 g0 [] (resolvePath e k' b seen) ≠ [] :=
              hhall 0 ([] : List Deriv)
            rw [heq] at h0
            exact absurd rfl h0
          have hp : hasPath e (Nat.succ k') b seen = true :=
            (hasPath_ne e (Nat.succ k') (g := b) (seen := seen)).mpr hrne
          have hb : hasBody e (Nat.succ k') bs seen = true := by
            obtain ⟨d, rest, hd⟩ := exists_cons_of_ne_nil hrne
            have h0 : solveBodyFrom e k' bs seen 0 g0 [] (resolvePath e k' b seen) ≠ [] :=
              hhall 0 []
            rw [hd, eq_solveBodyFrom_succ_cons, append_ne_nil] at h0
            rcases h0 with hL | hR
            · exact (hasBody_ne e g0 k' bs seen).mpr (fun i' kids' =>
                (solveBody_i_congr e k' bs seen 0 i' g0 kids').mp
                  ((solveBody_kids_congr e k' bs seen 0 g0 ([] : List Deriv) kids').mp hL))
            · have hfit :=
                (solveBodyFrom_child e k' bs seen 0 g0 [] rest).mp hR
              exact (hasBody_ne e g0 k' bs seen).mpr hfit.2
          rw [hp, hb]; rfl
  /-- 路徑與路徑窮舉器的互譯。 -/
  theorem hasPath_ne (e : Env) (n : Nat) : ∀ {g : UTerm} {seen : List UTerm},
      hasPath e n g seen = true ↔ resolvePath e n g seen ≠ [] := by
    match n with
    | 0 => intro g seen; simp [eq_hasPath_zero, eq_resolvePath_zero]
    | Nat.succ k =>
      intro g seen
      rw [eq_hasPath_succ, eq_resolvePath_succ]
      by_cases hk : keyIn seen g = true
      · simp [hk]
      · simp [hk]
        exact hasRuleList_ne e k (g := g) (seen := g :: seen) (rs := e.rules) (i := 0)
    termination_by n
    decreasing_by
      · exact Nat.lt_succ_self _

  /-- 規則清單與規則窮舉器的互譯。 -/
  theorem hasRuleList_ne (e : Env) (n : Nat) : ∀ {g : UTerm} {seen : List UTerm}
      {rs : List Rule} {i : Nat},
      hasRuleList e n g seen rs i = true ↔ resolveRuleList e n g seen i rs ≠ [] := by
    match n with
    | 0 => intro g seen rs i; simp [eq_hasRuleList_zero, eq_resolveRuleList_zero]
    | Nat.succ k =>
      intro g seen rs i
      cases rs with
      | nil => simp [eq_hasRuleList_succ_nil, eq_resolveRuleList_succ_nil]
      | cons r rs =>
        rw [hasRuleList.eq_3, resolveRuleList.eq_3]
        split
        · next heq =>
          simp [List.nil_append]
          exact hasRuleList_ne e k (g := g) (seen := seen) (rs := rs) (i := i + 1)
        · next heq =>
          rw [append_ne_nil, Bool.or_eq_true]
          constructor
          · rintro h
            obtain h1 | h2 := (Bool.or_eq_true _ _).mp h
            · left
              exact (hasBody_ne e g k _ seen).mp h1 i ([] : List Deriv)
            · right
              exact (hasRuleList_ne e k (g := g) (seen := seen) (rs := rs) (i := i + 1)).mp h2
          · rintro (hL | hR)
            · have hL1 := (solveBody_i_congr e k _ seen i 0 g ([] : List Deriv)).mp hL
              have hCustoms : ∀ (i' : Nat) (kids' : List Deriv),
                  solveBody e k (r.body.map (fun b => uApply sub (renumber (1000 * (Nat.succ k)) b)))
                    seen i' g kids' ≠ [] := fun i' kids' =>
                (solveBody_i_congr e k _ seen 0 i' g kids').mp
                  ((solveBody_kids_congr e k _ seen 0 g ([] : List Deriv) kids').mp hL1)
              have hb := (hasBody_ne e g k _ seen).mpr hCustoms
              rw [hb]
              simp
            · rw [(hasRuleList_ne e k (g := g) (seen := seen) (rs := rs) (i := i + 1)).mpr hR]
              simp
    termination_by n
    decreasing_by
      · exact Nat.lt_succ_self _
      · exact Nat.lt_succ_self _

  /-- 子式非空不變式（供「同層」使用）：`solveBodyFrom e n` 非空 ⟺
      `ds ≠ []` ∧ ∀-context `solveBody e (n-1)` 非空（match-內部分開處理 n = 0）。 -/
  theorem solveBodyFrom_child (e : Env) (n : Nat) : ∀
      (bs : List UTerm) (seen : List UTerm) (i : Nat) (g0 : UTerm) (kids : List Deriv)
      (ds : List Deriv),
      solveBodyFrom e n bs seen i g0 kids ds ≠ [] ↔
        (match n with
         | 0 => False
         | k + 1 => ds ≠ [] ∧ ∀ (i' : Nat) (kids' : List Deriv),
             solveBody e k bs seen i' g0 kids' ≠ []) := by
    match n with
    | 0 => intro bs seen i g0 kids ds; simp [eq_solveBodyFrom_zero]
    | Nat.succ k =>
      intro bs seen i g0 kids ds
      cases ds with
      | nil => simp [eq_solveBodyFrom_succ_nil]
      | cons d ds =>
        rw [eq_solveBodyFrom_succ_cons, append_ne_nil]
        rw [solveBody_kids_congr e k bs seen i g0 (kids ++ [d]) ([] : List Deriv)]
        rw [solveBody_i_congr e k bs seen i 0 g0 ([] : List Deriv)]
        constructor
        · rintro (hNe | hNe)
          · refine ⟨?_, ?_⟩
            · simp
            · intro i' kids'
              exact (solveBody_i_congr e k bs seen 0 i' g0 kids').mp
                ((solveBody_kids_congr e k bs seen 0 g0 ([] : List Deriv) kids').mp hNe)
          · obtain ⟨hds, hall⟩ :=
              (solveBodyFrom_child e k bs seen 0 g0 ([] : List Deriv) ds).mp
                ((solveBodyFrom_i_congr e k bs seen i 0 g0 ([] : List Deriv) ds).mp
                  ((solveBodyFrom_kids_congr e k bs seen i g0 kids ([] : List Deriv) ds).mp hNe))
            obtain ⟨hds', hall'⟩ := hall
            exact ⟨by simp, hall'⟩
        · rintro ⟨_, hall⟩
          left
          exact hall 0 []
    termination_by n
    decreasing_by
      · exact Nat.lt_succ_self _
      · exact Nat.lt_succ_self _

end

/-- **O2 主定理**：SLD 搜尋完備性——窮舉器非空 ⟺ 短路搜尋成功。 -/
theorem sld_complete (e : Env) (g : UTerm) (d : Nat) :
    resolveAll e g d ≠ [] ↔ solvable e g d = true := by
  by_cases hd : d = 0
  · subst hd
    simp [resolveAll, solvable, solvableFast]
  · unfold resolveAll solvable solvableFast
    rw [if_neg hd, if_neg hd]
    exact (hasPath_ne e (2 * d + 4) (g := g) (seen := [])).symm
