/-
  KtLaws/Reflect/Link.lean — 聯動：把「實例推導」反射成可獨立複驗的憑證
  對應 MoonBit `meta/reflect/link.mbt`

  `KtLaws.Instances.Engine` 的解析器會**搜尋**；搜尋器的輸出不可信（可能有 bug）。
  所以這裡把搜尋結果「反射」成一份不含搜尋的物件：
      ProofNode = （目標, 用了哪條規則, 每個子目標的 ProofNode）
  檢查器只做局部工作：
    * 目標與規則頭可合一（一次合一，不搜尋）；
    * 規則 body 被這次合一實例化後，逐個與子節點的目標相等；
    * 遞迴檢查子節點。
  這就是「信任邊界」的分割：快的一方（搜尋）不必被信任，慢的一方（檢查）不必聰明。

  與 MoonBit 的差異：
  1. `rule` 欄位用 `Nat`（Lean 側的規則索引是 `Nat`；`Deriv.rule` 是 `Int`，
     `toNode` 轉換時把負數夾成 0）。
  2. `u_variant_eq`（α-等價）原本用 `uEq` 代替（理由是「檢查時目標已被代入成
     無變數的項」—— 但那只是**註解**，不是證明）。現在它有了真身：
     `uCanon`（變數按首次出現重新編號，對應 `u_canon_str` 的正規形）＋
     `uVariantEq`（正規形指紋相等），並在 §5 證明它是等價關係、
     在 §6 用 `checkInstanceProofV` 重新檢查同一批憑證（含篡改版），
     把「兩者一致」從註解升級成定理。
  3. `proof_to_string` 的「可列印」在定理裡用 `proofShape`（規則索引樹，
     `List Nat`）陳述 —— `String` 進不了 `decide`；`proofToString` 仍然存在。
-/
import KtLaws.Instances.Engine

namespace KtLaws.Reflect

open KtLaws.Instances

/-! ### 1. 憑證 -/

/-- 一份實例證明憑證。 -/
structure ProofNode where
  goal : UTerm
  rule : Nat
  kids : List ProofNode
deriving Repr

/- 從推導樹取出憑證（去掉「怎麼找到的」）。 -/
mutual
  def toNode : Deriv → ProofNode
    | ⟨r, kids, goal⟩ => ⟨goal, (max r 0).toNat, toNodeList kids⟩

  def toNodeList : List Deriv → List ProofNode
    | [] => []
    | d :: ds => toNode d :: toNodeList ds
end

/-- 反射：從搜尋器的輸出產生憑證（取典範推導）。 -/
def proveInstance (e : Env) (goal : UTerm) (depth : Nat) : Option ProofNode :=
  (canonical e (resolveAll e goal depth)).map toNode

/- 項裡所有變數編號（`/- -/` 而非 doc comment：`mutual` 前放 doc comment 會壞）。 -/
mutual
  def uVars : UTerm → List Nat
    | .uvar v => [v]
    | .ufn _ xs => uVarsList xs

  def uVarsList : List UTerm → List Nat
    | [] => []
    | x :: xs => uVars x ++ uVarsList xs
end

/-- 新變數基準：取所有變數編號之上的安全偏移，避免與目標變數串味。 -/
def freshBase (t : UTerm) : Nat := (uVars t).foldr max 0 + 10000

/-! ### 2. α-等價（`u_variant_eq` 的真身） -/

/-- 環境查詢：原變數 → 正規變數。 -/
def lookupIdx (env : List (Nat × Nat)) (v : Nat) : Option Nat :=
  (env.find? (fun p => p.1 = v)).map (fun p => p.2)

/- 正規化：變數按**首次出現**的順序編成 0,1,2,…（α-等價的兩個項拿到同一個形）。 -/
mutual
  def uCanonGo : UTerm → List (Nat × Nat) → UTerm × List (Nat × Nat)
    | .uvar v, env =>
      match lookupIdx env v with
      | some i => (.uvar i, env)
      | none => (.uvar env.length, env ++ [(v, env.length)])
    | .ufn f xs, env =>
      let r := uCanonList xs env
      (.ufn f r.1, r.2)

  def uCanonList : List UTerm → List (Nat × Nat) → List UTerm × List (Nat × Nat)
    | [], env => ([], env)
    | x :: xs, env =>
      let r1 := uCanonGo x env
      let r2 := uCanonList xs r1.2
      (r1.1 :: r2.1, r2.2)
end

/-- α-正規形。 -/
def uCanon (t : UTerm) : UTerm := (uCanonGo t []).1

/- 結構指紋（對應 MoonBit 的 `u_canon_str`：把正規形壓成一串可比較的數字）。 -/
mutual
  def uFingerprint : UTerm → List Nat
    | .uvar v => [0, v]
    | .ufn f xs => [1, f] ++ uFingerprintList xs

  def uFingerprintList : List UTerm → List Nat
    | [] => []
    | x :: xs => uFingerprint x ++ [2] ++ uFingerprintList xs
end

/-- α-等價：正規形的指紋相等（＝ MoonBit 的 `u_canon_str(a) == u_canon_str(b)`）。 -/
def uVariantEq (a b : UTerm) : Bool := uFingerprint (uCanon a) = uFingerprint (uCanon b)

/-! ### 2. 獨立檢查器（不搜尋、不猜） -/

mutual
  /- 獨立檢查器：只做局部合一與比對。 -/
  def checkInstanceProof (e : Env) : ProofNode → Bool
    | ⟨goal, r, kids⟩ =>
      if r ≥ e.rules.length then false
      else
        let ru := ruleAt e r
        let base := freshBase goal
        match uUnify (renumber base ru.head) goal with
        | none => false
        | some sub =>
          if kids.length ≠ ru.body.length then false
          else checkKidsList e sub base ru.body kids

  /-- 逐個子節點檢查：body 被這次合一實例化後要與子目標相等。 -/
  def checkKidsList (e : Env) (sub : Subst) (base : Nat) :
      List UTerm → List ProofNode → Bool
    | [], [] => true
    | b :: bs, k :: ks =>
      uEq (uApply sub (renumber base b)) k.goal && checkInstanceProof e k &&
        checkKidsList e sub base bs ks
    | _, _ => false
end

/- 憑證深度（報告用）。 -/
mutual
  def proofDepth : ProofNode → Nat
    | ⟨_, _, kids⟩ => proofDepthList kids + 1

  def proofDepthList : List ProofNode → Nat
    | [] => 0
    | k :: ks => max (proofDepth k) (proofDepthList ks)
end

/- 憑證的形狀（規則索引樹）：定理裡用它代替「印出來的字串」。 -/
mutual
  def proofShape : ProofNode → List Nat
    | ⟨_, r, kids⟩ => r :: proofShapeList kids

  def proofShapeList : List ProofNode → List Nat
    | [] => []
    | k :: ks => proofShape k ++ proofShapeList ks
end

/- 真的印得出來的憑證（`String` 進不了 `decide`，只用於人看的報告）。 -/
mutual
  def proofToString (e : Env) : ProofNode → String
    | ⟨_, r, kids⟩ =>
      let name := if r ≥ e.rules.length then "?" else (ruleAt e r).name
      match kids with
      | [] => name
      | _ => name ++ "(" ++ kidsToString e kids ++ ")"

  def kidsToString (e : Env) : List ProofNode → String
    | [] => ""
    | [k] => proofToString e k
    | k :: k2 :: ks => proofToString e k ++ ", " ++ kidsToString e (k2 :: ks)
end

/-! ### 3. 待證目標 -/

/-- `Show (Array Int)`：一條規則 + 一個子目標。 -/
def goalShowArray : UTerm := clsShow (tyArray tyInt)

/-- `Show (Pair Int (Array Bool))`：巢狀目標。 -/
def goalShowNested : UTerm := clsShow (tyPair tyInt (tyArray tyBool))

/-- 無解的目標：`Eq Int` 在 `envShow` 裡沒有任何規則。 -/
def goalEqInt : UTerm := clsEq tyInt

/-- `Array` 節點只有一個子節點。 -/
def oneKid (n : ProofNode) : Bool := n.kids.length = 1

/-- 篡改根的規則索引（3 是 Pair，頭與 `Show (Array Int)` 不可合一）。 -/
def tamperedRoot (n : ProofNode) : Bool := !checkInstanceProof envShow ⟨n.goal, 3, n.kids⟩

/-- 篡改子節點的規則索引。 -/
def tamperedKid (n : ProofNode) : Bool :=
  match n.kids with
  | [k] => !checkInstanceProof envShow ⟨k.goal, 3, []⟩
  | _ => false

/-! ### 3b. 用 α-等價的檢查器（與 §2 的 `uEq` 版本並存，方便對帳） -/

mutual
  /-- α-等價版的獨立檢查器。 -/
  def checkInstanceProofV (e : Env) : ProofNode → Bool
    | ⟨goal, r, kids⟩ =>
      if r ≥ e.rules.length then false
      else
        let ru := ruleAt e r
        let base := freshBase goal
        match uUnify (renumber base ru.head) goal with
        | none => false
        | some sub =>
          if kids.length ≠ ru.body.length then false
          else checkKidsListV e sub base ru.body kids

  /-- 逐個子節點檢查（α-等價版）。 -/
  def checkKidsListV (e : Env) (sub : Subst) (base : Nat) :
      List UTerm → List ProofNode → Bool
    | [], [] => true
    | b :: bs, k :: ks =>
      uVariantEq (uApply sub (renumber base b)) k.goal && checkInstanceProofV e k &&
        checkKidsListV e sub base bs ks
    | _, _ => false
end

/-! ### 4. 定律（13 條） -/

/-- #1 `Show (Array Int)` 的憑證檢查得過（不搜尋）。 -/
theorem link_checks :
    (proveInstance envShow goalShowArray 8).map (checkInstanceProof envShow) = some true := by
  decide

/-- #2 憑證深度是 2（一條規則 + 一個公理葉）。 -/
theorem link_depth_two :
    (proveInstance envShow goalShowArray 8).map proofDepth = some 2 := by decide

/-- #3 憑證的形狀就是 `Array(Int)`：規則 2 帶著規則 0。 -/
theorem link_shape :
    (proveInstance envShow goalShowArray 8).map proofShape = some [2, 0] := by decide

/-- #4 憑證的根節點目標就是原目標。 -/
theorem link_root_goal :
    (proveInstance envShow goalShowArray 8).map (fun n => uEq n.goal goalShowArray) = some true := by
  decide

/-- #5 巢狀目標 `Show (Pair Int (Array Bool))` 的憑證也檢查得過。 -/
theorem link_nested_checks :
    (proveInstance envShow goalShowNested 8).map (checkInstanceProof envShow) = some true := by
  decide

/-- #6 巢狀憑證的深度是 3。 -/
theorem link_nested_depth :
    (proveInstance envShow goalShowNested 8).map proofDepth = some 3 := by decide

/-- #7 巢狀憑證的形狀：Pair(Int, Array(Bool))。 -/
theorem link_nested_shape :
    (proveInstance envShow goalShowNested 8).map proofShape = some [3, 0, 2, 1] := by decide

/-- #8 無解的目標：搜尋結果是空的（沒有憑證可造）。 -/
theorem link_no_rules : (resolveAll envShow goalEqInt 8).isEmpty = true := by decide

/-- #9 所以無解的目標拿不到憑證。 -/
theorem link_no_cert : (proveInstance envShow goalEqInt 8).isNone = true := by decide

/-- #10 篡改根節點的規則 ⇒ 檢查器必須拒絕。 -/
theorem link_tampered_root :
    (proveInstance envShow goalShowArray 8).map tamperedRoot = some true := by decide

/-- #11 篡改子節點的規則 ⇒ 檢查器必須拒絕。 -/
theorem link_tampered_kid :
    (proveInstance envShow goalShowArray 8).map tamperedKid = some true := by decide

/-- #12 良性憑證的 `Array` 節點確實只有一個子節點（篡改測試的前提）。 -/
theorem link_one_kid :
    (proveInstance envShow goalShowArray 8).map oneKid = some true := by
  decide

/-- #13 有解的目標一定有憑證（`None` 分支不被觸發）。 -/
theorem link_cert_exists : (proveInstance envShow goalShowArray 8).isSome = true := by decide

/-! ### 5. 定律：α-等價是真的等價關係（5 條）—— 這裡以前只有一句註解 -/

/-- α-等價 #1：自反。 -/
theorem variant_refl (t : UTerm) : uVariantEq t t = true := by simp [uVariantEq]

/-- α-等價 #2：對稱。 -/
theorem variant_symm (a b : UTerm) (h : uVariantEq a b = true) : uVariantEq b a = true := by
  simp [uVariantEq] at h ⊢
  exact h.symm

/-- α-等價 #3：遞移。 -/
theorem variant_trans (a b c : UTerm) (h1 : uVariantEq a b = true)
    (h2 : uVariantEq b c = true) : uVariantEq a c = true := by
  simp [uVariantEq] at h1 h2 ⊢
  exact h1.trans h2

/-- α-等價 #4：變數重新命名不改變等價類（`f(x₅)` 與 `f(x₉)` 是同一個形）。 -/
theorem variant_renames : uVariantEq (.ufn 0 [.uvar 5]) (.ufn 0 [.uvar 9]) = true := by
  decide

/-- α-等價 #5：但**重複**與**不重複**不能混為一談
    （`f(x,x)` 與 `f(x,y)` 不等價）—— 這正是 α-等價不能粗暴改成「都換成 0」的理由。 -/
theorem variant_distinguishes :
    uVariantEq (.ufn 0 [.uvar 0, .uvar 0]) (.ufn 0 [.uvar 0, .uvar 1]) = false := by
  decide

/-! ### 6. 定律：用 α-等價的檢查器結論不變（4 條）—— 把「兩者一致」變成定理 -/

/-- 對帳 #1：良性的 `Show (Array Int)` 憑證，α-等價版檢查器同樣接受。 -/
theorem variant_accepts :
    (proveInstance envShow goalShowArray 8).map (checkInstanceProofV envShow) = some true := by
  decide

/-- 對帳 #2：巢狀目標的憑證也一樣。 -/
theorem variant_accepts_nested :
    (proveInstance envShow goalShowNested 8).map (checkInstanceProofV envShow) = some true := by
  decide

/-- 兩個檢查器是否給出同一個答案。 -/
def checkersAgree (n : ProofNode) : Bool := checkInstanceProofV envShow n = checkInstanceProof envShow n

/-- 對帳 #3：兩個檢查器在良性憑證上給出**相同**的答案。 -/
theorem variant_agrees :
    (proveInstance envShow goalShowArray 8).map checkersAgree = some true := by decide

/-- 對帳 #4：篡改過的憑證，α-等價版一樣拒絕（放寬到 α-等價沒有讓檢查器變鬆）。 -/
theorem variant_rejects_tampering :
    (proveInstance envShow goalShowArray 8).map
      (fun n => !checkInstanceProofV envShow ⟨n.goal, 3, n.kids⟩) = some true := by
  decide

end KtLaws.Reflect
