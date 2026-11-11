/-
  KtLaws/Instances/Termination.lean — 全域實例修補系統的重寫終止性（O4 義務的誠實版本）

  Lean WHY.md §3 的 O4 寫的是：`orientable e → WellFounded (Rewrites e)`，
  想像「每條規則 head 節點數嚴格大於 body 節點數（kt 側 `orientable`）」就夠證明終止。

  本檔直接駁回了那個想像，並給出**真正可證的部分**：

  1. `Rewrites`：一階項上的規則重寫（規則實例化後在**任意位置**收縮；
     每一步恰好改變一個節點，變數代入走完整條替換鏈）。
  2. `measureDecreasing`：足夠條件（body 各變數的出現次數點式不增於 head、
     head 的 ufn 節點嚴格多於 body）⇒ **每一步**嚴格減少 `uSize` ⇒ 終止。
     `envShow` 滿足此條件（四條規則逐條驗明）——這就是 kt 真正倚賴的那部分。
  3. `kt_node_measure_not_decreasing_on_steps`：**反例**。
     規則 `h(f x, y) → g(y, y)` 在 `uSize` 上是定向的（4 > 3），
     卻存在一步重寫把項從 6 放大到 7。換言之 kt/moon 用的
     「head 節點數 > body 節點數」只是啟發式，不是終止性證明；
     完整主張需要簡化序（RPO/KBO），在此凍結記檔。
-/
import KtLaws.Instances.Engine

namespace KtLaws.Instances

/-! ### 1. 非變數節點數與變數多重集 -/

mutual
  /-- 非變數節點（`ufn` 應用）個數。 -/
  def ufnCount : UTerm → Nat
    | .uvar _ => 0
    | .ufn _ xs => 1 + ufnCountList xs

  def ufnCountList : List UTerm → Nat
    | [] => 0
    | x :: xs => ufnCount x + ufnCountList xs
end

mutual
  /-- `t` 出現的變數（每次出現列出一次，重複保留）。 -/
  def varsOf : UTerm → List Nat
    | .uvar v => [v]
    | .ufn _ xs => varsOfList xs

  def varsOfList : List UTerm → List Nat
    | [] => []
    | x :: xs => varsOf x ++ varsOfList xs
end

/-! ### 2. `uSize` 對代入的精確公式 -/

private theorem sum_map_append {l₁ l₂ : List Nat} (f : Nat → Nat) :
    ((l₁ ++ l₂).map f).sum = (l₁.map f).sum + (l₂.map f).sum := by
  simp [List.map_append, List.sum_append]

private theorem sum_map_flatten (f : Nat → Nat) (xs : List UTerm) :
    ((varsOfList xs).map f).sum
      = (xs.map (fun x => ((varsOf x).map f).sum)).sum := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [varsOfList, List.map_append, List.sum_append, List.map_cons,
      List.sum_cons] at *
    rw [← ih]
mutual
  /-- `uSize (uApply σ t)` 的精確展開（def 證明，繞過嵌套歸納對 tactic 的限制）：
      每個 ufn 貢獻 1，每個變數出現貢獻代入後的大小。 -/
  def uSize_apply_eq (σ : Subst) : ∀ t : UTerm,
      uSize (uApply σ t)
        = ufnCount t + ((varsOf t).map (fun v => uSize (uApply σ (.uvar v)))).sum
    | .uvar v => by simp [varsOf, ufnCount]
    | .ufn f xs => by
      show 1 + uSizeList (uApplyList σ xs) = (1 + ufnCountList xs) + _
      simp only [uSize_apply_eq_list, varsOf]
      omega

  def uSize_apply_eq_list (σ : Subst) : ∀ xs : List UTerm,
      uSizeList (uApplyList σ xs)
        = ufnCountList xs
          + ((varsOfList xs).map (fun v => uSize (uApply σ (.uvar v)))).sum
    | [] => rfl
    | x :: xs => by
      have hx := uSize_apply_eq σ x
      have hxs := uSize_apply_eq_list σ xs
      simp only [uApplyList, uSizeList, ufnCountList, varsOfList,
        List.map_append, List.sum_append] at *
      rw [hx, hxs]
      omega
end

theorem uSize_apply (σ : Subst) (t : UTerm) :
    uSize (uApply σ t)
      = ufnCount t + ((varsOf t).map (fun v => uSize (uApply σ (.uvar v)))).sum :=
  uSize_apply_eq σ t

/-! ### 3. 多重集包含 ⇒ 加權和不增 -/

theorem sum_map_le_of_count_le {ys xs : List Nat} (h : ∀ v, ys.count v ≤ xs.count v)
    (f : Nat → Nat) :
    (ys.map f).sum ≤ (xs.map f).sum := by
  induction ys generalizing xs with
  | nil => simp
  | cons v ys ih =>
    have hmem : v ∈ xs := List.count_pos_iff.mp (by
      have hc := h v
      simp only [List.count_cons_self] at hc
      omega)
    obtain ⟨s, t, rfl⟩ := List.mem_iff_append.mp hmem
    have hv' : ys.count v ≤ s.count v + t.count v := by
      have hc2 := h v
      simp [List.count_append, List.count_cons_self] at hc2
      omega
    have h' : ∀ w, ys.count w ≤ (s ++ t).count w := by
      intro w
      by_cases hw : w = v
      · subst hw
        simpa [List.count_append] using hv'
      · have hne : v ≠ w := fun e => hw e.symm
        have h2 := h w
        simpa [List.count_append, List.count_cons_of_ne hne] using h2
    have ih' := ih (xs := s ++ t) h'
    have hstep : ((v :: ys).map f).sum = f v + (ys.map f).sum := by
      simp [List.map_cons, List.sum_cons]
    have hxs : ((s ++ v :: t).map f).sum = f v + ((s ++ t).map f).sum := by
      simp only [List.map_append, List.map_cons, List.sum_append, List.sum_cons]
      omega
    omega

/-! ### 4. 重寫關係與「一步嚴格減少」-/

mutual
  /-- 一階項上的規則重寫：把規則的 head 實例替換成某個 body 實例，
      可在任意位置（ufn 參數內）發生。 -/
  inductive Rewrites (e : Env) : UTerm → UTerm → Prop where
    | root {r : Rule} (hrp : r ∈ e.rules) {σ : Subst} {b : UTerm} (hb : b ∈ r.body)
        {t t' : UTerm} (h1 : uApply σ r.head = t) (h2 : uApply σ b = t') :
        Rewrites e t t'
    | sub {f : Nat} {xs ys : List UTerm} (h : URewritesList e xs ys) :
        Rewrites e (.ufn f xs) (.ufn f ys)

  /-- 參數清單的重寫：每一步恰好改變一個位置（沒有「什麼都沒換」的退化）。 -/
  inductive URewritesList (e : Env) : List UTerm → List UTerm → Prop where
    | head {t t' : UTerm} {ts : List UTerm} (h : Rewrites e t t') :
        URewritesList e (t :: ts) (t' :: ts)
    | next {t : UTerm} {ts ts' : List UTerm} (h : URewritesList e ts ts') :
        URewritesList e (t :: ts) (t :: ts')
end

/-- 足夠條件：每條規則的 body，其每個變數的出現次數點式不增於 head，
    且 head 的 ufn 節點嚴格多於 body。 -/
def measureDecreasing (r : Rule) : Prop :=
  (∀ b ∈ r.body, ∀ v, (varsOf b).count v ≤ (varsOf r.head).count v)
  ∧ (∀ b ∈ r.body, ufnCount b < ufnCount r.head)

/-- 根重列減少：單一公式計算（不含遞迴）。 -/
theorem root_size_decreases {e : Env} (hmh : ∀ r ∈ e.rules, measureDecreasing r)
    {r : Rule} (hrp : r ∈ e.rules) {σ : Subst} {b : UTerm} (hb : b ∈ r.body) :
    uSize (uApply σ b) < uSize (uApply σ r.head) := by
  obtain ⟨hocc, hufn⟩ := hmh r hrp
  rw [uSize_apply, uSize_apply]
  have hsmall := hufn b hb
  have hsum : ((varsOf b).map (fun v => uSize (uApply σ (.uvar v)))).sum
      ≤ ((varsOf r.head).map (fun v => uSize (uApply σ (.uvar v)))).sum :=
    sum_map_le_of_count_le (hocc b hb) _
  omega

mutual
  theorem uSizeList_rewrite_lt {e : Env}
      (hmh : ∀ r ∈ e.rules, measureDecreasing r) {xs ys}
      (h : URewritesList e xs ys) :
      uSizeList ys < uSizeList xs := by
    cases h with
    | head hh =>
      simp only [uSizeList]
      have hrt := rewrites_size_decreases hmh hh
      omega
    | next hh =>
      simp only [uSizeList]
      have ih := uSizeList_rewrite_lt hmh hh
      omega

  theorem rewrites_size_decreases {e : Env}
      (hmh : ∀ r ∈ e.rules, measureDecreasing r) {t t'}
      (h : Rewrites e t t') : uSize t' < uSize t := by
    cases h with
    | root hrp hb h1 h2 =>
      subst h1; subst h2
      exact root_size_decreases hmh hrp hb
    | sub h =>
      show 1 + uSizeList _ < 1 + uSizeList _
      exact Nat.add_lt_add_left (uSizeList_rewrite_lt hmh h) 1
end

/-! ### 5. 重寫系統終止（足夠條件成立時） -/

theorem rewrites_restriction_wf (e : Env) (hmh : ∀ r ∈ e.rules, measureDecreasing r) :
    WellFounded (fun t' t => Rewrites e t t') := by
  have h₁ : Subrelation (fun t' t => Rewrites e t t') (InvImage (· < ·) uSize) :=
    fun {t' t} hh => rewrites_size_decreases hmh hh
  exact Subrelation.wf h₁ (InvImage.wf uSize Nat.lt_wfRel.wf)

/-- `envShow`（經典 typeclass 環境）滿足足夠條件 ⇒ 其重寫系統終止。 -/
private theorem count_of_ne_forall_ne {l : List Nat} {v : Nat} (h : ∀ x ∈ l, v ≠ x) :
    l.count v = 0 := by
  induction l with
  | nil => rfl
  | cons x l ih =>
    rw [List.count_cons_of_ne (fun e => h x List.mem_cons_self e.symm),
        ih (fun y hy => h y (List.mem_cons_of_mem x hy))]

/-- Array 規則（`1 個 var → 1 個 var`）：body 變數計數點式不增於 head。 -/
private theorem count_arr0 : ∀ v,
    (varsOf (clsShow (.uvar 0))).count v ≤ (varsOf (clsShow (tyArray (.uvar 0)))).count v :=
  fun _ => Nat.le_of_eq (by rfl)

/-- Pair 規則、第一個子目標（uvar 0）。 -/
private theorem count_pair0 : ∀ v,
    (varsOf (clsShow (.uvar 0))).count v ≤ (varsOf (clsShow (tyPair (.uvar 0) (.uvar 1)))).count v := by
  intro v
  by_cases h0 : v = 0
  · subst h0
    decide
  · rw [show varsOf (clsShow (.uvar 0)) = [0] from rfl,
        count_of_ne_forall_ne (l := [0])
          (fun x hx => by rcases List.mem_singleton.mp hx with rfl; exact fun e => h0 e)]
    exact Nat.zero_le _

/-- Pair 規則、第二個子目標（uvar 1）。 -/
private theorem count_pair1 : ∀ v,
    (varsOf (clsShow (.uvar 1))).count v ≤ (varsOf (clsShow (tyPair (.uvar 0) (.uvar 1)))).count v := by
  intro v
  by_cases h1 : v = 1
  · subst h1
    decide
  · rw [show varsOf (clsShow (.uvar 1)) = [1] from rfl,
        count_of_ne_forall_ne (l := [1])
          (fun x hx => by rcases List.mem_singleton.mp hx with rfl; exact fun e => h1 e)]
    exact Nat.zero_le _

theorem envShow_rules_measureDecreasing :
    ∀ r ∈ envShow.rules, measureDecreasing r := by
  intro r hr
  rcases (List.mem_cons.mp hr) with rfl | hr
  · exact ⟨fun b hb => (List.not_mem_nil hb).elim, fun b hb => (List.not_mem_nil hb).elim⟩
  · rcases (List.mem_cons.mp hr) with rfl | hr
    · exact ⟨fun b hb => (List.not_mem_nil hb).elim, fun b hb => (List.not_mem_nil hb).elim⟩
    · rcases (List.mem_cons.mp hr) with rfl | hr
      · -- Array 規則：body = [Show (uvar 0)]
        constructor
        · intro b hb v
          rcases (List.mem_singleton.mp hb) with rfl
          rw [show (rule "Array" 0 (clsShow (tyArray (.uvar 0)))
                [clsShow (.uvar 0)]).head = clsShow (tyArray (.uvar 0)) from rfl]
          exact count_arr0 v
        · intro b hb
          rcases (List.mem_singleton.mp hb) with rfl
          decide
      · rcases (List.mem_cons.mp hr) with rfl | hr
        · -- Pair 規則：body = [Show (uvar 0), Show (uvar 1)]
          constructor
          · intro b hb v
            rw [show (rule "Pair" 0 (clsShow (tyPair (.uvar 0) (.uvar 1)))
                [clsShow (.uvar 0), clsShow (.uvar 1)]).head =
                clsShow (tyPair (.uvar 0) (.uvar 1)) from rfl]
            rcases (List.mem_cons.mp hb) with rfl | hb'
            · exact count_pair0 v
            · rcases (List.mem_singleton.mp hb') with rfl
              exact count_pair1 v
          · intro b hb
            rcases (List.mem_cons.mp hb) with rfl | hb'
            · decide
            · rcases (List.mem_singleton.mp hb') with rfl
              decide
        · exact (List.not_mem_nil hr).elim

theorem envShow_terminating :
    WellFounded (fun t' t => Rewrites envShow t t') :=
  rewrites_restriction_wf envShow envShow_rules_measureDecreasing

/-! ### 6. 反例：節點數定向**不蘊含**重寫減少 -/

/-- 反例大項：ufn 7 [ufn 0 [], ufn 0 []]，uSize = 3。 -/
def ctBig : UTerm := .ufn 7 [.ufn 0 [], .ufn 0 []]

/-- 反例 body：g(y, y)。 -/
def ctBody : UTerm := .ufn 102 [.uvar 1, .uvar 1]

/-- 反例規則：head = h(f x, y)，uSize = 4 > 3 = uSize body；body 變數 {y} ⊆ head {x, y}。 -/
def ctHead : Rule :=
  { name := "kt-orientation-counterexample"
    prio := 0
    head := .ufn 100 [.ufn 101 [.uvar 0], .uvar 1]
    body := [ctBody] }

def ctEnv : Env := env [ctHead]

/-- 代入 σ：y ↦ ctBig（x 保持自由）。 -/
def ctSigma : Subst := [(1, ctBig)]

theorem ct_orientable_node_measure : uSize ctBody < uSize ctHead.head := by decide

theorem ct_headterm_size : uSize (uApply ctSigma ctHead.head) = 6 := by decide

theorem ct_bodyterm_size : uSize (uApply ctSigma ctBody) = 7 := by decide

theorem ct_step :
    Rewrites ctEnv (uApply ctSigma ctHead.head) (uApply ctSigma ctBody) := by
  have hrp : ctHead ∈ ctEnv.rules := by simp [ctEnv, env, ctHead]
  have hb : ctBody ∈ ctHead.body := by simp [ctHead]
  exact Rewrites.root hrp hb rfl rfl

/-- kt/moon 端 `orientable`（節點數定向）**不能**作為終止性證明：
    這條規則在該度量上被定向，但一步重寫把項從 6 放大到 7。 -/
theorem kt_node_measure_orientation_unsound :
    uSize ctBody < uSize ctHead.head
    ∧ Rewrites ctEnv (uApply ctSigma ctHead.head) (uApply ctSigma ctBody)
    ∧ uSize (uApply ctSigma ctHead.head) < uSize (uApply ctSigma ctBody) :=
  ⟨by decide, ct_step, by decide⟩
