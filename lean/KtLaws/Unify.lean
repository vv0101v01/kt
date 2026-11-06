/-
  KtLaws/Unify.lean — 合一的正確性/普遍性/唯一性，與反合一（lgg）是 mgu 的對偶
  對應 MoonBit `meta/core/unify.mbt`（11 個標籤：合一 7 ＋ 反合一 4）

  這一族的主題是**鏡像對稱**：
    * mgu（most general unifier）是 meet —— 比它更一般的解都更弱；
    * lgg（least general generalisation）是 join —— 比它更弱的推廣都更一般。
  `Unify.lean` 把兩邊都變成可計算的檢查，並用定理釘住：

  1. **正確性**：`σ` 真的讓兩項相等（`u_apply σ a = u_apply σ b`）；
  2. **普遍性**：樣本解 `{x↦a, y↦b}` 正好是 mgu 的實例；
  3. **唯一性（up to 重新命名）**：`mgu(a,b)` 與 `mgu(b,a)` 代換後給出同一個項；
  4. **occurs check**：`x =? f(x)` 不可合一（不是「大概會停」）；
  5. **不可合一的常數**：`f0` 與 `f1` 一定失敗；
  6. **lgg 是 join**：`lgg(p, q)` 同時是 `p`、`q` 的推廣，且共同結構被保留。

  與 MoonBit 的差異：
  1. `u_lgg` 的記憶表在 MoonBit 用 `Array` 可變狀態；Lean 側改成狀態對
     （`LggState`：計數器 + 記憶表），語意相同（新變數從 100 起跳、同一個 key 對拿同一個變數）。
  2. 有 4 個標籤（合一 #4、#9，反合一 #3、#5）落在 `match` 的**未觸發分支**上；
     Lean 側把它們改陳述成同一樣本的**另一面向**（存在性、新變數不相撞），
     因此這裡 15 條定理覆蓋 11 個標籤。
-/
import KtLaws.Instances.UTerm

namespace KtLaws.Unify

open KtLaws.Instances

/-! ### 1. lgg 的狀態（計數器 + 記憶表） -/

/-- lgg 的狀態：下一個新變數的序號、以及「key 對 → 新變數」的記憶表。 -/
structure LggState where
  next : Nat
  memo : List (Nat × Nat × UTerm)
deriving Repr

/- 結構鍵（只有小項才用；與 MoonBit 的 `u_key` 同一個雜湊）。 -/
mutual
  def uKey : UTerm → Nat
    | .uvar x => x * 7919
    | .ufn f xs => uKeyFold xs (104729 + f * 31)

  def uKeyFold : List UTerm → Nat → Nat
    | [], h => h
    | x :: xs, h => uKeyFold xs ((h * 3 + uKey x) % 1000003)
end

/-- 取一個新變數（從 100 起跳，與原項的變數空間分開）。 -/
def freshVar (st : LggState) : UTerm × LggState :=
  (.uvar (100 + st.next), { st with next := st.next + 1 })

/-- 記憶表查詢：同一個 key 對要拿到同一個新變數。 -/
def memoLookup (a b : UTerm) (st : LggState) : Option UTerm :=
  ((st.memo.filter (fun e => e.1 = uKey a && e.2.1 = uKey b)).getLast?).map (fun e => e.2.2)

/- 反合一：最小公共推廣（結構相同就往下遞迴，否則抽象成新變數）。 -/
mutual
  def lggGo : UTerm → UTerm → LggState → UTerm × LggState
    | .ufn f xs, .ufn g ys, st =>
      if f = g && xs.length = ys.length then
        let r := lggGoList xs ys st
        (.ufn f r.1, r.2)
      else freshVar st
    | a, b, st =>
      match memoLookup a b st with
      | some v => (v, st)
      | none =>
        let fr := freshVar st
        (fr.1, { fr.2 with memo := fr.2.memo ++ [(uKey a, uKey b, fr.1)] })

  def lggGoList : List UTerm → List UTerm → LggState → List UTerm × LggState
    | [], _, st => ([], st)
    | _ :: _, [], st => ([], st)
    | x :: xs, y :: ys, st =>
      let r1 := lggGo x y st
      let r2 := lggGoList xs ys r1.2
      (r1.1 :: r2.1, r2.2)
end

/-- 兩個項的最小公共推廣（join）。 -/
def uLgg (a b : UTerm) : UTerm := (lggGo a b ⟨0, []⟩).1

/-! ### 2. 輔助：變數清單與變數個數 -/

mutual
  def uVars : UTerm → List Nat
    | .uvar x => [x]
    | .ufn _ xs => uVarsList xs

  def uVarsList : List UTerm → List Nat
    | [] => []
    | x :: xs => uVars x ++ uVarsList xs
end

mutual
  def uVarCount : UTerm → Nat
    | .uvar _ => 1
    | .ufn _ xs => uVarCountList xs

  def uVarCountList : List UTerm → Nat
    | [] => 0
    | x :: xs => uVarCount x + uVarCountList xs
end

/-! ### 3. 合一族的樣本 -/

/-- `f0(x1, f1)`。 -/
def uA : UTerm := .ufn 0 [.uvar 1, .ufn 1 []]

/-- `f0(f2, x2)`。 -/
def uB : UTerm := .ufn 0 [.ufn 2 [], .uvar 2]

/-- `f4(x0, x0)`。 -/
def uC : UTerm := .ufn 4 [.uvar 0, .uvar 0]

/-- `f4(f5, x1)`。 -/
def uD : UTerm := .ufn 4 [.ufn 5 [], .uvar 1]

/-! ### 4. 定律：合一（9 條，覆蓋 7 個標籤） -/

/-- 合一 #1 正確性：`σ` 讓 `f0(x1,f1)` 與 `f0(f2,x2)` 相等。 -/
theorem unify_correct :
    (uMgu uA uB).map (fun s => uEq (uApply s uA) (uApply s uB)) = some true := by decide

/-- 合一 #2 普遍性：`σ(x1) = f2`。 -/
theorem unify_generality_x :
    (uMgu uA uB).map (fun s => uEq (uApply s (.uvar 1)) (.ufn 2 [])) = some true := by decide

/-- 合一 #3 普遍性：`σ(x2) = f1`。 -/
theorem unify_generality_y :
    (uMgu uA uB).map (fun s => uEq (uApply s (.uvar 2)) (.ufn 1 [])) = some true := by decide

/-- 合一 #4（原標籤落在 `None` 分支）：這一對確實有 mgu。 -/
theorem unify_exists : (uMgu uA uB).isSome = true := by decide

/-- 合一 #5 occurs check：`x0 =? f3(x0)` 不可合一。 -/
theorem unify_occurs : uUnify (.uvar 0) (.ufn 3 [.uvar 0]) = none := by decide

/-- 合一 #6 不可合一：不同常數 `f0`／`f1` 一定失敗。 -/
theorem unify_constants : uUnifiable (.ufn 0 []) (.ufn 1 []) = false := by decide

/-- 合一 #7 對稱性（左）：兩個方向的 mgu 代換後給出同一個 `f4(x0,x0)`。 -/
theorem unify_symm_left :
    (match uMgu uC uD, uMgu uD uC with
      | some s1, some s2 => uEq (uApply s1 uC) (uApply s2 uC)
      | _, _ => false) = true := by decide

/-- 合一 #8 對稱性（右）：`f4(f5,x1)` 也一樣。 -/
theorem unify_symm_right :
    (match uMgu uC uD, uMgu uD uC with
      | some s1, some s2 => uEq (uApply s1 uD) (uApply s2 uD)
      | _, _ => false) = true := by decide

/-- 合一 #9（原標籤落在 `None` 分支）：兩個方向都真的有 mgu。 -/
theorem unify_symm_both :
    (match uMgu uC uD, uMgu uD uC with
      | some _, some _ => true
      | _, _ => false) = true := by decide

/-! ### 5. 定律：反合一 = join（6 條，覆蓋 4 個標籤） -/

/-- 反合一樣本左：`f0(f1, f2)`。 -/
def uS1 : UTerm := .ufn 0 [.ufn 1 [], .ufn 2 []]

/-- 反合一樣本右：`f0(f1, f3)`。 -/
def uS2 : UTerm := .ufn 0 [.ufn 1 [], .ufn 3 []]

/-- 反合一 #1 共同結構保留：最外層是 `f0` 的二元節點。 -/
theorem lgg_shape :
    (match uLgg uS1 uS2 with
      | .ufn f xs => f = 0 && xs.length = 2
      | _ => false) = true := by decide

/-- 反合一 #2 共同結構保留：第一個子項仍是 `f1` 節點。 -/
theorem lgg_first_child :
    (match uLgg uS1 uS2 with
      | .ufn _ (x :: _) =>
        (match x with
          | .ufn g _ => g = 1
          | _ => false)
      | _ => false) = true := by decide

/-- 反合一 #3（原標籤落在 `None` 分支）：被抽象出來的是**新**變數（≥ 100），
    因此不會與原項的 `x0..x2` 串味。 -/
theorem lgg_second_child_fresh :
    (match uLgg uS1 uS2 with
      | .ufn _ [_, y] =>
        (match y with
          | .uvar v => 100 ≤ v
          | _ => false)
      | _ => false) = true := by decide

/-- 反合一 #4：不同子項 `f2`／`f3` 被抽象成變數，第二個子項恰好帶一個變數。 -/
theorem lgg_second_child_one_var :
    (match uLgg uS1 uS2 with
      | .ufn _ [_, y] => uVarCount y = 1
      | _ => false) = true := by decide

/-- 反合一 #5（原標籤落在 `None` 分支）：整個 lgg 的變數都在新變數空間裡。 -/
theorem lgg_vars_are_fresh : (uVars (uLgg uS1 uS2)).all (fun v => 100 ≤ v) = true := by
  decide

/-- 反合一 #6 lgg 是 join：`lgg(x0, x1)` 同時是兩邊的推廣（兩邊都是它的實例）。 -/
theorem lgg_is_join :
    uIsInstance (uLgg (.uvar 0) (.uvar 1)) (.uvar 0) &&
      uIsInstance (uLgg (.uvar 0) (.uvar 1)) (.uvar 1) = true := by decide

end KtLaws.Unify
