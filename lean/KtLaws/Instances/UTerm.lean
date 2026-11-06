/-
  KtLaws/Instances/UTerm.lean — 一階項、替換、合一
  對應 MoonBit `meta/core/unify.mbt`（`UTerm` / `u_apply` / `u_unify` / `u_mgu`）

  `meta/instances` 的四個檔案（engine / compose / coherence / characterize）共用這一層：
  一個實例系統 = Horn 子句集 + SLD 解析 + 一致性判準，而 SLD 的核心就是合一的 mgu。

  照本專案在 iit 學到的規矩（見 `../README.md` §4）：kernel 無法約簡 well-founded
  遞迴，所以凡是 `decide` 要算的函式都寫成「對 `Nat` 燃料的結構遞迴」或
  「對清單的結構遞迴」。替換用 `List (Option UTerm)`（等同 MoonBit 的稀疏陣列）。
-/
namespace KtLaws.Instances

/-! ### 1. 一階項 -/

/-- 一階項：變數（`uvar n`）或函式符號應用（`ufn f args`）。 -/
inductive UTerm where
  | uvar (n : Nat)
  | ufn (f : Nat) (args : List UTerm)
deriving Repr

instance : Inhabited UTerm := ⟨.uvar 0⟩
instance : Inhabited (Option UTerm) := ⟨none⟩

/-! ### 2. 結構相等（`inductive` 沒有 `deriving DecidableEq` 的自我遞迴情形） -/

mutual
  /-- 兩個項的結構相等。 -/
  def uEq : UTerm → UTerm → Bool
    | .uvar a, .uvar b => a == b
    | .ufn f xs, .ufn g ys => f == g && uEqList xs ys
    | _, _ => false

  /-- 逐項相等。 -/
  def uEqList : List UTerm → List UTerm → Bool
    | [], [] => true
    | a :: as, b :: bs => uEq a b && uEqList as bs
    | _, _ => false
end

/-- `uEq` 對變數的化簡。 -/
theorem uEq_uvar_iff (a b : Nat) : uEq (.uvar a) (.uvar b) = true ↔ a = b := by
  simp [uEq, beq_iff_eq]

/-! ### 3. 大小與深度 -/

mutual
  /-- 項的大小（`u_size`）。 -/
  def uSize : UTerm → Nat
    | .uvar _ => 1
    | .ufn _ xs => 1 + uSizeList xs

  def uSizeList : List UTerm → Nat
    | [] => 0
    | x :: xs => uSize x + uSizeList xs
end

mutual
  /-- 建構子深度（`u_depth`）。 -/
  def uDepth : UTerm → Nat
    | .uvar _ => 0
    | .ufn _ xs => 1 + uDepthList xs

  /-- 參數的最大深度。 -/
  def uDepthList : List UTerm → Nat
    | [] => 0
    | x :: xs => max (uDepth x) (uDepthList xs)
end

/-! ### 4. 替換（`List (Option UTerm)`，索引 = 變數編號） -/

/-- 替換：`(變數, 綁定項)` 的關聯清單（比稀疏陣列便宜得多 —— 變數編號可以很大）。 -/
abbrev Subst := List (Nat × UTerm)

/-- 取變數 `i` 的綁定。 -/
def substGet (s : Subst) (i : Nat) : Option UTerm :=
  s.findSome? (fun p => if p.1 == i then some p.2 else none)

/-- 把變數 `i` 綁到 `t`（覆寫舊綁定）。 -/
def substBind (s : Subst) (i : Nat) (t : UTerm) : Subst :=
  (i, t) :: s.filter (fun p => !(p.1 == i))

/-- 沿替換走到底（燃料 = 替換長度，長度不足時視為未綁定）。 -/
def uWalk (s : Subst) : Nat → UTerm → UTerm
  | 0, t => t
  | n + 1, .uvar v =>
    match substGet s v with
    | some t' => uWalk s n t'
    | none => .uvar v
  | _, t@(.ufn _ _) => t

mutual
  /-- 套用替換。 -/
  def uApply (s : Subst) : UTerm → UTerm
    | .uvar v => uWalk s (s.length + 1) (.uvar v)
    | .ufn f xs => .ufn f (uApplyList s xs)

  def uApplyList (s : Subst) : List UTerm → List UTerm
    | [] => []
    | x :: xs => uApply s x :: uApplyList s xs
end

mutual
  /-- 變數 `v` 是否出現在 `t` 裡（occurs check）。 -/
  def uOccurs (s : Subst) (v : Nat) : UTerm → Bool
    | .uvar x =>
      match uWalk s (s.length + 1) (.uvar x) with
      | .uvar y => y == v
      | .ufn _ _ => false
    | .ufn _ xs => uOccursList s v xs

  def uOccursList (s : Subst) (v : Nat) : List UTerm → Bool
    | [] => false
    | x :: xs => uOccurs s v x || uOccursList s v xs
end

/-! ### 5. Robinson 合一 -/

/-- 合一的燃料：兩個項的大小加上替換長度（每一步都會消耗一格）。 -/
def unifyFuel (a b : UTerm) (s : Subst) : Nat := 2 * (uSize a + uSize b) + s.length + 4

mutual
/-- 逐對合一（替換往後傳）。**兩個函式都只對燃料做結構遞迴**，這樣 kernel 才算得動。 -/
def uUnifyListGo : Nat → Subst → List UTerm → List UTerm → Option Subst
  | 0, _, _, _ => none
  | _ + 1, s, [], [] => some s
  | n + 1, s, a :: as, b :: bs =>
    match uUnifyGo n s a b with
    | none => none
    | some s' => uUnifyListGo n s' as bs
  | _ + 1, _, _, _ => none

/-- Robinson 合一（帶燃料）：成功時回傳更新後的替換。 -/
def uUnifyGo : Nat → Subst → UTerm → UTerm → Option Subst
  | 0, _, _, _ => none
  | n + 1, s, a, b =>
    let x := uWalk s (s.length + 1) a
    let y := uWalk s (s.length + 1) b
    match x, y with
    | .uvar p, .uvar q => if p == q then some s else some (substBind s p (.uvar q))
    | .uvar p, _ => if uOccurs s p y then none else some (substBind s p y)
    | _, .uvar _ => uUnifyGo n s y x
    | .ufn f xs, .ufn g ys =>
      if f == g then uUnifyListGo n s xs ys else none
end

/-- 合一兩個項。 -/
def uUnify (a b : UTerm) : Option Subst := uUnifyGo (unifyFuel a b []) [] a b

/-- 計算 mgu（與 MoonBit 的差別：不做範式化；`uApply` 會沿鏈走到底，兩者結果一致）。 -/
def uMgu (a b : UTerm) : Option Subst := uUnify a b

/-- 兩個項是否可合一。 -/
def uUnifiable (a b : UTerm) : Bool := (uMgu a b).isSome

/-- `pattern` 是否是 `t` 的推廣（存在替換使 `σ pattern = t`）。 -/
def uIsInstance (pattern t : UTerm) : Bool := uUnifiable pattern t

end KtLaws.Instances
