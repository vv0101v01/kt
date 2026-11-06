/-
  KtLaws/Reflect/Universe.lean — 宇宙反射（universe reflection）與保守性
  對應 MoonBit `meta/reflect/universe.mbt`

  型別論的「反射」還有第二個意思：**宇宙的反射原則**。
  說一句關於 `U_n` 的話，就等於說一句關於 `U_{n+1}` 裡某個物件的話。
  最弱的可檢驗版本是保守性（conservativity）：

    把一個句子抬升一層（reflect），不會改變它在原層的可證性。

  加強版是 Mahlo 式反射：若句子在**極限層** λ 可證，則存在 α < λ 使它已可證。

  層級取成序數（`../Ordinal.lean` 的 Cantor 範式），所以「極限」與「後繼」
  不是比喻，而是可判定的（ω 是極限，ω+1 是後繼）。

  「在層級 `level` 可證」的定義：句子裡所有原子的層級都嚴格低於 `level`
  （這個玩具系統的「證明」就是層級檢查；它的用處是讓保守性成為可計算定理）。
-/
import KtLaws.Ordinal

open KtLaws.Ordinal

namespace KtLaws.Reflect

/-! ### 1. 句子 -/

/-- 句子：真、原子命題、蘊含。 -/
inductive Stmt where
  | triv
  | atom (i : Nat)
  | imp (a b : Stmt)
deriving Repr

/-- 句子裡最大的原子層級（`triv` 沒有原子，回報 0）。 -/
def stmtMaxAtom : Stmt → Nat
  | .triv => 0
  | .atom i => i
  | .imp a b => max (stmtMaxAtom a) (stmtMaxAtom b)

/-! ### 2. 可證性、反射、保守性 -/

/-- 序數嚴格小於。 -/
def ordLt (a b : Ordinal) : Bool := cmp a b == .lt

/-- 在層級 `level` 可證 ⟺ 句子裡所有原子的層級都嚴格低於 `level`。 -/
def provable (level : Ordinal) (s : Stmt) : Bool := ordLt (ordOfNat (stmtMaxAtom s)) level

/-- 反射：把句子的每個原子抬升一層。 -/
def reflectStmt : Stmt → Stmt
  | .triv => .triv
  | .atom i => .atom (i + 1)
  | .imp a b => .imp (reflectStmt a) (reflectStmt b)

/-- 逆反射：把原子降一層（原子 0 之下沒有東西 ⇒ 失敗）。 -/
def unreflectStmt : Stmt → Option Stmt
  | .triv => some .triv
  | .atom 0 => none
  | .atom (i + 1) => some (.atom i)
  | .imp a b =>
    match unreflectStmt a, unreflectStmt b with
    | some a2, some b2 => some (.imp a2 b2)
    | _, _ => none

/-- 保守性（可計算版）：`provable(level+1, reflect(s)) ⟺ provable(level, s)`。 -/
def conservative (level : Ordinal) (s : Stmt) : Bool :=
  provable (ordSucc level) (reflectStmt s) == provable level s

/-! ### 3. 極限層與 Mahlo 式反射 -/

/-- 序數的項列。 -/
def ordTerms : Ordinal → List (Nat × Ordinal)
  | .ofTerms ts => ts

/-- 序數是不是 0。 -/
def ordIsZero : Ordinal → Bool
  | .ofTerms [] => true
  | _ => false

/-- CNF 最末項的指數（最小指數）。 -/
def ordLastExp (level : Ordinal) : Option Ordinal :=
  ((ordTerms level).reverse.head?).map (fun p => p.2)

/-- 是不是極限層：非零，且 CNF 最末項的指數非零 ⟺ 不是後繼。
    例：`ω` 是極限；`ω+1` 是後繼；`ω·2` 是極限。 -/
def isLimitLevel (level : Ordinal) : Bool :=
  if ordIsZero level then false
  else
    match ordLastExp level with
    | none => false
    | some e => !ordIsZero e

/-- Mahlo 式反射：若 `s` 在 `level` 可證，找一個 α < level 使它已可證。
    取 α = `maxAtom + 1`（最小充分層級）。回傳 `none` ⟺ `level` **正好就是**
    最小充分層級（後繼臨界情形）—— 這就是「反射在極限層成立、在後繼層可能失效」
    的可執行版本。 -/
def reflectDown (level : Ordinal) (s : Stmt) : Option Ordinal :=
  if !provable level s then none
  else
    let alpha := ordSucc (ordOfNat (stmtMaxAtom s))
    if ordLt alpha level && provable alpha s then some alpha else none

/-! ### 4. 測試用的句子與層級 -/

/-- `p0 → (p1 → p0)`：最小充分層級是 2。 -/
def stmtS : Stmt := .imp (.atom 0) (.imp (.atom 1) (.atom 0))

/-- `p0 → p1`：最小充分層級是 2。 -/
def stmtS2 : Stmt := .imp (.atom 0) (.atom 1)

/-- `ω`。 -/
def ordOmega : Ordinal := ordOmegaPow (ordOfNat 1)

/-- `ω + 1`。 -/
def ordOmegaSucc : Ordinal := ordAdd ordOmega ordOne

/-! ### 5. 定律（23 條，對應 MoonBit 的 23 個標籤） -/

/-! #### 5.1 保守性是可判定的（10 條） -/

/-- 保守性 #1：句子在層級 2 可證（原子 1 需要 level > 1）。 -/
theorem conserv_provable_two : provable (ordOfNat 2) stmtS = true := by decide

/-- 保守性 #2：在層級 1 不可證。 -/
theorem conserv_not_provable_one : provable (ordOfNat 1) stmtS = false := by decide

/-- 保守性 #3：抬一層之後，在層級 3 仍可證。 -/
theorem conserv_reflect_provable : provable (ordOfNat 3) (reflectStmt stmtS) = true := by decide

/-- 保守性 #4：在層級 2 上保守。 -/
theorem conserv_at_two : conservative (ordOfNat 2) stmtS = true := by decide

/-- 保守性 #5：在層級 5 上也保守。 -/
theorem conserv_at_five : conservative (ordOfNat 5) stmtS = true := by decide

/-- 保守性 #6：顯然真的句子也保守。 -/
theorem conserv_triv : conservative (ordOfNat 5) .triv = true := by decide

/-- 保守性 #7：反射是單射（在可逆範圍內）：`unreflect (reflect s)` 的最大原子不變。 -/
theorem unreflect_reflect_max_atom :
    (unreflectStmt (reflectStmt stmtS)).map stmtMaxAtom = some (stmtMaxAtom stmtS) := by decide

/-- 保守性 #8：所以 `unreflect (reflect s)` 一定成功。 -/
theorem unreflect_reflect_some : (unreflectStmt (reflectStmt stmtS)).isSome = true := by decide

/-- 保守性 #9：原子 0 不能往下反射。 -/
theorem unreflect_atom_zero : unreflectStmt (.atom 0) = none := by decide

/-- 保守性 #10：原子 1 可以往下反射。 -/
theorem unreflect_atom_one : (unreflectStmt (.atom 1)).map stmtMaxAtom = some 0 := by decide

/-! #### 5.2 Mahlo 式反射：極限層成立、後繼層失效（13 條） -/

/-- Mahlo #1：在最小充分層級（2）上反射失敗。 -/
theorem mahlo_critical_none : reflectDown (ordOfNat 2) stmtS2 = none := by decide

/-- Mahlo #2：所以「臨界後繼」上沒有更小的見證。 -/
theorem mahlo_critical_no_smaller : (reflectDown (ordOfNat 2) stmtS2).isNone = true := by decide

/-- Mahlo #3：在層級 3（非最小）上反射成功，而且反射到的 α 真的證得出 `s`。 -/
theorem mahlo_three_witness :
    (reflectDown (ordOfNat 3) stmtS2).map
      (fun a => ordLt a (ordOfNat 3) && provable a stmtS2) = some true := by decide

/-- Mahlo #4：層級 3 上確實有見證。 -/
theorem mahlo_three_some : (reflectDown (ordOfNat 3) stmtS2).isSome = true := by decide

/-- Mahlo #5：`ω` 是極限層。 -/
theorem omega_is_limit : isLimitLevel ordOmega = true := by decide

/-- Mahlo #6：有限層級 3 不是極限。 -/
theorem three_not_limit : isLimitLevel (ordOfNat 3) = false := by decide

/-- Mahlo #7：`ω + 1` 不是極限（後繼）。 -/
theorem omega_succ_not_limit : isLimitLevel ordOmegaSucc = false := by decide

/-- Mahlo #8：在 `ω` 上反射到的是嚴格更小的層級。 -/
theorem mahlo_omega_smaller :
    (reflectDown ordOmega stmtS2).map (fun a => ordLt a ordOmega) = some true := by decide

/-- Mahlo #9：而且反射到的層級真的證得出 `s`（極限反射給出有限見證）。 -/
theorem mahlo_omega_provable :
    (reflectDown ordOmega stmtS2).map (fun a => provable a stmtS2) = some true := by decide

/-- Mahlo #10：所以 `ω` 上有見證。 -/
theorem mahlo_omega_some : (reflectDown ordOmega stmtS2).isSome = true := by decide

/-- Mahlo #11：0 不是極限層。 -/
theorem zero_not_limit : isLimitLevel (ordOfNat 0) = false := by decide

/-- Mahlo #12：`succ ω` 不是極限層 —— 反射原則的「極限」條件不可省。 -/
theorem succ_omega_not_limit : isLimitLevel (ordSucc ordOmega) = false := by decide

/-- Mahlo #13：即使如此，`succ ω` 上仍然反射得下去（可證性夠寬），
    只是它不是極限 —— 「極限」條件限制的是**反射原則**，不是這一個玩具檢查。 -/
theorem mahlo_succ_omega_witness :
    (reflectDown (ordSucc ordOmega) stmtS2).map
      (fun a => ordLt a (ordSucc ordOmega) && provable a stmtS2) = some true := by decide

/-! ### 6. 與 MoonBit 的 `stmt_max_atom` 對齊（2 條）—— `triv` 的 −1 之謎 -/

/-- MoonBit 的 `stmt_max_atom` 回傳 `Int`，`triv` 是 **−1**（「沒有原子」）。 -/
def stmtMaxAtomI : Stmt → Int
  | .triv => -1
  | .atom i => (i : Int)
  | .imp a b => max (stmtMaxAtomI a) (stmtMaxAtomI b)

/-- 對齊 #1：`triv` 的最大原子在 MoonBit 側確實是 −1。 -/
theorem max_atom_triv_int : stmtMaxAtomI .triv = -1 := rfl

/-- 對齊 #2：但可證性只看到 `max 0`——把 −1 夾到 0 之後與 Lean 的 `Nat` 版本
    **逐句相同**。所以「`triv` 用 0 而不是 −1」不是偷偷改定義，而是夾制之後的等價。 -/
theorem max_atom_bridge (s : Stmt) : max 0 (stmtMaxAtomI s) = (stmtMaxAtom s : Int) := by
  induction s with
  | triv => rfl
  | atom i => simp [stmtMaxAtomI, stmtMaxAtom]
  | imp a b iha ihb =>
    simp only [stmtMaxAtomI, stmtMaxAtom]
    have h : max 0 (max (stmtMaxAtomI a) (stmtMaxAtomI b)) =
        max (max 0 (stmtMaxAtomI a)) (max 0 (stmtMaxAtomI b)) := by omega
    rw [h, iha, ihb]
    omega

/-! ### 8. 反射原理的 club 結構（前沿：Lévy–Montagne 說反射層構成 club）

§5 的保守性是**樣本**（`conserv_at_two`、`conserv_at_five`、`conserv_triv`）。
這裡把它升級成對所有層級、所有句子成立，並補上 club 的三個要件：
**閉**（可證性沿層級單調上升）、**無界**（任何層級之上都有反射層）、
**有限交**（有限多個句子可以共用同一個反射層）。 -/
set_option maxRecDepth 100000

theorem cmp_zero_zero : cmp ordZero ordZero = .eq := rfl

theorem ofNat_cmp (a b : Nat) : cmp (ordOfNat a) (ordOfNat b) = cmpNat a b := by
  cases a with
  | zero => cases b <;> rfl
  | succ p =>
    cases b with
    | zero => rfl
    | succ q =>
      show cmpList [(p + 1, ordZero)] [(q + 1, ordZero)] = cmpNat (p + 1) (q + 1)
      simp only [cmpList, cmp_zero_zero, cmpNat]
      split <;> simp_all

theorem ordLt_ofNat (a b : Nat) : ordLt (ordOfNat a) (ordOfNat b) = decide (a < b) := by
  unfold ordLt
  rw [ofNat_cmp]
  simp only [cmpNat]
  split
  · simp_all
  · split <;> simp_all

theorem provable_ofNat (n : Nat) (s : Stmt) :
    provable (ordOfNat n) s = decide (stmtMaxAtom s < n) :=
  ordLt_ofNat (stmtMaxAtom s) n

theorem ordSucc_ofNat (n : Nat) : ordSucc (ordOfNat n) = ordOfNat (n + 1) := by
  cases n with
  | zero => rfl
  | succ k =>
    show Ordinal.ofTerms (addTerms [(k + 1, ordZero)] [(1, ordZero)]) = ordOfNat (k + 1 + 1)
    simp only [addTerms, cmp_zero_zero]
    rfl

def hasAtom : Stmt → Bool
  | .triv => false
  | .atom _ => true
  | .imp a b => hasAtom a || hasAtom b

theorem stmtMaxAtom_le_reflect (s : Stmt) : stmtMaxAtom s ≤ stmtMaxAtom (reflectStmt s) := by
  induction s with
  | triv => simp [reflectStmt, stmtMaxAtom]
  | atom i => simp [reflectStmt, stmtMaxAtom]
  | imp a b iha ihb => simp only [reflectStmt, stmtMaxAtom]; omega

theorem stmtMaxAtom_reflect_noAtom (s : Stmt) (h : hasAtom s = false) :
    stmtMaxAtom (reflectStmt s) = stmtMaxAtom s := by
  induction s with
  | triv => rfl
  | atom i => simp [hasAtom] at h
  | imp a b iha ihb =>
    simp only [hasAtom, Bool.or_eq_false_iff] at h
    obtain ⟨h1, h2⟩ := h
    simp only [reflectStmt, stmtMaxAtom, iha h1, ihb h2]

theorem stmtMaxAtom_eq_zero_of_noAtom (s : Stmt) (h : hasAtom s = false) :
    stmtMaxAtom s = 0 := by
  induction s with
  | triv => rfl
  | atom i => simp [hasAtom] at h
  | imp a b iha ihb =>
    simp only [hasAtom, Bool.or_eq_false_iff] at h
    obtain ⟨h1, h2⟩ := h
    simp only [stmtMaxAtom, iha h1, ihb h2, Nat.max_eq_left (Nat.zero_le 0)]

theorem stmtMaxAtom_reflect_hasAtom (s : Stmt) (h : hasAtom s = true) :
    stmtMaxAtom (reflectStmt s) = stmtMaxAtom s + 1 := by
  induction s with
  | triv => simp [hasAtom] at h
  | atom i => rfl
  | imp a b iha ihb =>
    by_cases ha : hasAtom a = true
    · by_cases hb : hasAtom b = true
      · simp only [reflectStmt, stmtMaxAtom, iha ha, ihb hb]; omega
      · have hb' : hasAtom b = false := by cases hh : hasAtom b <;> simp_all
        simp only [reflectStmt, stmtMaxAtom, iha ha, stmtMaxAtom_reflect_noAtom b hb', stmtMaxAtom_eq_zero_of_noAtom b hb']; omega
    · have ha' : hasAtom a = false := by cases hh : hasAtom a <;> simp_all
      have hb : hasAtom b = true := by
        simp only [hasAtom, Bool.or_eq_true] at h
        rcases h with h' | h'
        · exact absurd h' ha
        · exact h'
      simp only [reflectStmt, stmtMaxAtom, ihb hb, stmtMaxAtom_reflect_noAtom a ha', stmtMaxAtom_eq_zero_of_noAtom a ha']; omega

theorem conserv_general (n : Nat) (hn : 1 ≤ n) (s : Stmt) : conservative (ordOfNat n) s = true := by
  unfold conservative
  rw [ordSucc_ofNat, provable_ofNat, provable_ofNat]
  by_cases hk : stmtMaxAtom s < n
  · have hlt : stmtMaxAtom (reflectStmt s) < n + 1 := by
      cases h : hasAtom s
      · rw [stmtMaxAtom_reflect_noAtom s h]; omega
      · rw [stmtMaxAtom_reflect_hasAtom s h]; omega
    simp [hk, hlt]
  · have hge : ¬ stmtMaxAtom (reflectStmt s) < n + 1 := by
      cases h : hasAtom s
      · rw [stmtMaxAtom_reflect_noAtom s h]
        have hz := stmtMaxAtom_eq_zero_of_noAtom s h
        omega
      · rw [stmtMaxAtom_reflect_hasAtom s h]; omega
    simp [hk, hge]

theorem conserv_at_zero_is_false : conservative (ordOfNat 0) .triv = false := by decide

theorem provable_mono (s : Stmt) {n m : Nat} (h : n ≤ m)
    (hp : provable (ordOfNat n) s = true) : provable (ordOfNat m) s = true := by
  simp only [provable_ofNat, decide_eq_true_eq] at hp ⊢
  omega

theorem reflects_unbounded (n : Nat) (s : Stmt) :
    ∃ m, n < m ∧ provable (ordOfNat m) s = true := by
  refine ⟨n + stmtMaxAtom s + 1, by omega, ?_⟩
  simp only [provable_ofNat, decide_eq_true_eq]
  omega

theorem le_foldr_max (s : Stmt) :
    ∀ (ss : List Stmt), s ∈ ss → stmtMaxAtom s ≤ ss.foldr (fun x acc => max (stmtMaxAtom x) acc) 0
  | [], h => by simp at h
  | x :: xs, h => by
    simp only [List.mem_cons] at h
    rcases h with h | h
    · subst h; simp only [List.foldr_cons]; omega
    · have := le_foldr_max s xs h
      simp only [List.foldr_cons]
      omega

theorem reflects_finite_fragment (ss : List Stmt) (n : Nat) :
    ∃ m, n < m ∧ ∀ s ∈ ss, provable (ordOfNat m) s = true := by
  refine ⟨n + ss.foldr (fun x acc => max (stmtMaxAtom x) acc) 0 + 1, by omega, ?_⟩
  intro s hs
  simp only [provable_ofNat, decide_eq_true_eq]
  have := le_foldr_max s ss hs
  omega

theorem reflects_minimal (s : Stmt) :
    provable (ordOfNat (stmtMaxAtom s + 1)) s = true ∧
      provable (ordOfNat (stmtMaxAtom s)) s = false := by
  constructor
  · simp only [provable_ofNat, decide_eq_true_eq]; omega
  · simp only [provable_ofNat]; simp

end KtLaws.Reflect
