/-
  KtLaws/Instances/Engine.lean — 全域實例（typeclass）的引擎
  對應 MoonBit `meta/instances/engine.mbt`

  一個 typeclass 系統真正難的不是「找得到實例」，而是三件事：
    1. **終止**：實例鏈不能無限長；
    2. **一致性（coherence）**：同一目標的所有推導都給同一個見證值；
    3. **組合性**：多個模組的實例併起來仍然一致。

  這裡把三件事都變成可判定的檢查：
    終止   → 序數度量 `ω^{uDepth}` 嚴格下降（`terminating`）
    一致性 → 臨界對（`criticalPairs`）+ 典範化（`canonical`）+ 不一致見證（`incoherenceWitness`）
    組合性 → 在 `KtLaws/Instances/Compose.lean`（覆蓋黏合與 Möbius 障礙）

  所有遞迴都是「對 `Nat` 燃料」或「對清單」的結構遞迴（見 `../README.md` §4），
  所以 `decide` 算得動——這 22 條定律全部是 kernel 檢查，沒有 `native_decide`。
-/
import KtLaws.Instances.UTerm
import KtLaws.Ordinal

open KtLaws.Ordinal

namespace KtLaws.Instances

/- 搜尋器的約簡很深（每個規則 × 每個 body 目標 × 深度），把 kernel 的遞迴上限調高。 -/
set_option maxRecDepth 100000

/-! ### 1. 規則、環境、推導樹 -/

/-- 一條實例規則：`head` 可由 `body` 全部成立而得出。 -/
structure Rule where
  name : String
  /-- 優先級：數字大者優先（typeclass 的 specific-over-general）。 -/
  prio : Int
  head : UTerm
  body : List UTerm
deriving Repr

/-- 全域實例表。 -/
structure Env where
  rules : List Rule
deriving Repr

/-- 推導樹：葉子是公理實例，內部節點記錄用了哪條規則（`-1` 表示沒有規則）。 -/
structure Deriv where
  rule : Int
  kids : List Deriv
  goal : UTerm
deriving Repr

instance : Inhabited Deriv := ⟨{ rule := -1, kids := [], goal := UTerm.uvar 0 }⟩

/-- 建一條規則。 -/
def rule (name : String) (prio : Int) (head : UTerm) (body : List UTerm) : Rule :=
  { name, prio, head, body }

/-- 建環境。 -/
def env (rules : List Rule) : Env := { rules }

/-- 第 `i` 條規則（越界給空規則）。 -/
def ruleAt (e : Env) (i : Nat) : Rule :=
  (e.rules[i]?).getD { name := "", prio := 0, head := .uvar 0, body := [] }

/-! ### 2. 型別常數與目標的編碼（讓定律讀得懂） -/

def tyInt : UTerm := .ufn 0 []
def tyBool : UTerm := .ufn 1 []
def tyArray (t : UTerm) : UTerm := .ufn 2 [t]
def tyPair (a b : UTerm) : UTerm := .ufn 3 [a, b]
def clsShow (t : UTerm) : UTerm := .ufn 10 [t]
def clsEq (t : UTerm) : UTerm := .ufn 11 [t]
def clsOrd (t : UTerm) : UTerm := .ufn 12 [t]

/-! ### 3. 新鮮實例化（規則內的變數每次使用都要改名） -/

mutual
  /-- 把 `t` 的變數編號整體加上 `base`。 -/
  def renumber (base : Nat) : UTerm → UTerm
    | .uvar v => .uvar (v + base)
    | .ufn f xs => .ufn f (renumberList base xs)

  def renumberList (base : Nat) : List UTerm → List UTerm
    | [] => []
    | x :: xs => renumber base x :: renumberList base xs
end

/-! ### 4. 見證項與推導樹的度量 -/

mutual
  /-- 見證項：把推導樹具體化成一階項（`rule = -1` 用 900，否則 `100 + rule`）。 -/
  def evidence (e : Env) : Deriv → UTerm
    | ⟨r, kids, _⟩ => .ufn (if r < 0 then 900 else (100 + r).toNat) (evidenceList e kids)

  def evidenceList (e : Env) : List Deriv → List UTerm
    | [] => []
    | d :: ds => evidence e d :: evidenceList e ds
end

mutual
  /-- 推導樹深度。 -/
  def derivDepth : Deriv → Nat
    | ⟨_, kids, _⟩ => 1 + derivDepthList kids

  def derivDepthList : List Deriv → Nat
    | [] => 0
    | d :: ds => max (derivDepth d) (derivDepthList ds)
end

mutual
  /-- 推導樹節點數（搜尋成本的度量）。 -/
  def derivSize : Deriv → Nat
    | ⟨_, kids, _⟩ => 1 + derivSizeList kids

  def derivSizeList : List Deriv → Nat
    | [] => 0
    | d :: ds => derivSize d + derivSizeList ds
end

/-! ### 5. SLD 解析（「推論」引擎） -/

/-- 路徑簽名裡是否已經出現過這個目標（去環）。 -/
def keyIn (seen : List UTerm) (g : UTerm) : Bool := seen.any (fun s => uEq s g)

mutual
  /-- 一條路徑：對每個規則試一次。 -/
  def resolvePath (e : Env) : Nat → UTerm → List UTerm → List Deriv
    | 0, _, _ => []
    | n + 1, goal, seen =>
      if keyIn seen goal then [] else resolveRuleList e n goal (goal :: seen) 0 e.rules

  /-- 對規則清單逐一嘗試（`i` 是規則索引）。合一與 body 的處理直接寫在這裡，
      好讓整條呼叫鏈 `resolvePath → resolveRuleList → solveBody → resolvePath`
      每一環都嚴格減少同一個燃料 `n`（Lean 才看得出這是結構遞迴）。 -/
  def resolveRuleList (e : Env) : Nat → UTerm → List UTerm → Nat → List Rule → List Deriv
    | 0, _, _, _, _ => []
    | _ + 1, _, _, _, [] => []
    | n + 1, goal, seen, i, r :: rs =>
      (let base := 1000 * (n + 1)
       let head := renumber base r.head
       match uMgu head goal with
       | none => []
       | some sub =>
         solveBody e n (r.body.map (fun b => uApply sub (renumber base b))) seen i goal [])
      ++ resolveRuleList e n goal seen (i + 1) rs

  /-- 把 body 的目標依序解掉（每個解都接到 `kids`）。 -/
  def solveBody (e : Env) :
      Nat → List UTerm → List UTerm → Nat → UTerm → List Deriv → List Deriv
    | 0, _, _, _, _, _ => []
    | _ + 1, [], _, i, goal, kids => [⟨(i : Int), kids, goal⟩]
    | n + 1, b :: bs, seen, i, goal, kids =>
      solveBodyFrom e n bs seen i goal kids (resolvePath e n b seen)

  /-- 走訪「body 第一個目標的所有解」。 -/
  def solveBodyFrom (e : Env) :
      Nat → List UTerm → List UTerm → Nat → UTerm → List Deriv → List Deriv → List Deriv
    | 0, _, _, _, _, _, _ => []
    | _ + 1, _, _, _, _, _, [] => []
    | n + 1, bs, seen, i, goal, kids, d :: ds =>
      solveBody e n bs seen i goal (kids ++ [d])
        ++ solveBodyFrom e n bs seen i goal kids ds
end


mutual
  /-- 存在一條從 `goal` 出發的路。 -/
  def hasPath (e : Env) : Nat → UTerm → List UTerm → Bool
    | 0, _, _ => false
    | n + 1, goal, seen => if keyIn seen goal then false else hasRuleList e n goal (goal :: seen) e.rules

  def hasRuleList (e : Env) : Nat → UTerm → List UTerm → List Rule → Bool
    | 0, _, _, _ => false
    | _ + 1, _, _, [] => false
    | n + 1, goal, seen, r :: rs =>
      (let base := 1000 * (n + 1)
       match uMgu (renumber base r.head) goal with
       | none => false
       | some sub => hasBody e n (r.body.map (fun b => uApply sub (renumber base b))) seen)
      || hasRuleList e n goal seen rs

  /-- body 的每個目標都要解得掉。 -/
  def hasBody (e : Env) : Nat → List UTerm → List UTerm → Bool
    | 0, _, _ => false
    | _ + 1, [], _ => true
    | n + 1, b :: bs, seen => hasPath e n b seen && hasBody e n bs seen
end

/-- 蒐集所有推導（深度上限 + 路徑簽名去環）。非空 ⟺ 目標可解。

    **燃料換算**：Lean 版的燃料是「步數」，而每一層巢狀要花兩步
    （`resolveRuleList` 一格、`solveBody` 一格），所以把 MoonBit 的「深度」
    換成 `2 * depth + 4` 步。這只影響搜尋上界，不影響判定結果。 -/
def resolveAll (e : Env) (goal : UTerm) (depth : Nat) : List Deriv :=
  if depth = 0 then [] else resolvePath e (2 * depth + 4) goal []

/-- 短路的存在性搜尋：找到第一條路就停。與 `resolveAll` 非空等價，但 kernel 便宜得多。 -/
def solvableFast (e : Env) (goal : UTerm) (depth : Nat) : Bool :=
  if depth = 0 then false else hasPath e (2 * depth + 4) goal []

/-- 可解性（不關心見證）。定義用短路搜尋；與「`resolveAll` 非空」等價。 -/
def solvable (e : Env) (goal : UTerm) (depth : Nat) : Bool := solvableFast e goal depth

/-! ### 6. 一致性：臨界對 + 典範化 -/

/-- 規則的優先級。 -/
def rulePrio (e : Env) (r : Int) (dflt : Int) : Int :=
  if r < 0 then dflt else (e.rules[r.toNat]?).map (fun x => x.prio) |>.getD dflt

/-- 一條推導的優先級。 -/
def derivPrio (e : Env) (d : Deriv) : Int := rulePrio e d.rule (-9999)

/-- 典範化的單步比較：優先級高者勝；平手取規則索引小者（確定性）。

    抽成具名函式只是為了讓「典範化不會無中生有」可以寫成定理
    （`canonical_mem`）—— 語意與原本的內聯 lambda 完全相同。 -/
def pick (e : Env) (best x : Deriv) : Deriv :=
  let bd := rulePrio e best.rule (-999)
  let dd := rulePrio e x.rule (-999)
  if dd > bd || (dd == bd && x.rule < best.rule) then x else best

/-- 典範推導：優先級最高者勝；平手取規則索引小者（確定性）。 -/
def canonical (e : Env) : List Deriv → Option Deriv
  | [] => none
  | d :: ds => some (ds.foldl (pick e) d)

/-- 最高優先級的那些推導（typeclass 的語義是「最具體者勝」）。 -/
def maximalDerivs (e : Env) (ds : List Deriv) : List Deriv :=
  let top := ds.foldl (fun m d => max m (derivPrio e d)) (-9999)
  ds.filter (fun d => derivPrio e d == top)

/-- 一致性檢查：找出「同一目標在最高優先級上有兩個不同見證」的目標。 -/
def incoherenceWitness (e : Env) (goals : List UTerm) (depth : Nat) : Option UTerm :=
  goals.findSome? (fun g =>
    let ds := maximalDerivs e (resolveAll e g depth)
    match canonical e ds with
    | none => none
    | some c =>
      let ce := evidence e c
      if ds.any (fun d => !uEq (evidence e d) ce) then some g else none)

/-- 臨界對：兩條規則的 head 可合一（有重疊實例）——一致性風險的**全部**來源。 -/
def criticalPairs (e : Env) : List (Nat × Nat) :=
  (List.range e.rules.length).flatMap (fun i =>
    (List.range e.rules.length).filterMap (fun j =>
      if i < j && uUnifiable (renumber 0 (ruleAt e i).head) (renumber 500 (ruleAt e j).head)
      then some (i, j) else none))

/-- 重疊實例可否併合：對重疊的具體目標，兩條路是否給出同一見證。 -/
def overlappingJoinable (e : Env) (i j : Nat) (depth : Nat) : Bool :=
  let hi := renumber 0 (ruleAt e i).head
  let hj := renumber 500 (ruleAt e j).head
  match uMgu hi hj with
  | none => true
  | some sub =>
    let g := uApply sub hi
    let ds := maximalDerivs e (resolveAll e g depth)
    match canonical e ds with
    | none => true
    | some c => ds.all (fun d => uEq (evidence e d) (evidence e c))

/-- 全域一致性判準（在本引擎的觀察範圍內）：
    (1) 每個臨界對都可併合；(2) 給定目標集上不存在不一致見證。 -/
def coherent (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  (criticalPairs e).all (fun p => overlappingJoinable e p.1 p.2 depth) &&
    (incoherenceWitness e goals depth).isNone

/-! ### 7. 終止：序數度量 `ω^{uDepth}` -/

/-- 目標的結構度量：`ω^{建構子深度}`。 -/
def goalMeasure (g : UTerm) : Ordinal := ordOmegaPow (ordOfNat (uDepth g))

/-- 序數嚴格小於。 -/
def ordLt (a b : Ordinal) : Bool := cmp a b == .lt

/-- 終止性：每條規則的每個 body 目標，度量都必須嚴格變小。 -/
def terminating (e : Env) : Option String :=
  e.rules.findSome? (fun r =>
    let hm := goalMeasure r.head
    r.body.findSome? (fun b =>
      if ordLt (goalMeasure (renumber 0 b)) hm then none
      else some ("rule " ++ r.name ++ ": body goal does not decrease")))

/-! ### 8. 白箱測試環境 -/

/-- 經典 typeclass 環境：Int/Bool 是公理，Array/Pair 是泛型實例。 -/
def envShow : Env :=
  env [ rule "Int" 0 (clsShow tyInt) []
      , rule "Bool" 0 (clsShow tyBool) []
      , rule "Array" 0 (clsShow (tyArray (.uvar 0))) [clsShow (.uvar 0)]
      , rule "Pair" 0 (clsShow (tyPair (.uvar 0) (.uvar 1)))
          [clsShow (.uvar 0), clsShow (.uvar 1)] ]

/-- 會繞圈的法則：`Show T :- Show (Array T)`。 -/
def envLoop : Env :=
  env [rule "loop" 0 (clsShow (.uvar 0)) [clsShow (tyArray (.uvar 0))]]

/-- 兩個都匹配 `Show Int`：generic（prio 0）與 specific（prio 1）。 -/
def envPrio : Env :=
  env [rule "generic" 0 (clsShow (.uvar 0)) []
      , rule "specificInt" 1 (clsShow tyInt) []]

/-- 同優先級重疊 ⇒ 不一致。 -/
def envClash : Env :=
  env [rule "a" 0 (clsShow (.uvar 0)) []
      , rule "b" 0 (clsShow tyInt) []]

/-- 測試目標 `Show Int`。 -/
def goalShowInt : UTerm := clsShow tyInt

/-! ### 9. 定律（22 條，對應 MoonBit 的 22 個標籤） -/

/-! #### 9.1 SLD 解析找得到、也組合得出實例（9 條） -/

/-- SLD #1：`Show Int` 由公理直接解出。 -/
theorem sld_show_int : solvable envShow (clsShow tyInt) 8 = true := by decide

/-- SLD #2：泛型實例組合出 `Show (Array Int)`。 -/
theorem sld_show_array_int : solvable envShow (clsShow (tyArray tyInt)) 8 = true := by decide

/-- SLD #3：兩層組合 `Show (Array (Array Bool))`。 -/
theorem sld_show_array_array_bool :
    solvable envShow (clsShow (tyArray (tyArray tyBool))) 8 = true := by decide

/-- SLD #4：兩個 body 目標 `Show (Pair Int (Array Bool))`。 -/
theorem sld_show_pair :
    solvable envShow (clsShow (tyPair tyInt (tyArray tyBool))) 8 = true := by decide

/-- SLD #5：沒有 `Eq` 實例，所以解不出來（引擎不假裝成功）。 -/
theorem sld_no_eq_instance : solvable envShow (clsEq tyInt) 8 = false := by decide

/-- SLD #6：`Show (Array Int)` 只有一條推導。 -/
theorem sld_single_derivation :
    (resolveAll envShow (clsShow (tyArray tyInt)) 8).length = 1 := by decide

/-- SLD #7：那條推導用的規則就是 `Array`（索引 2）。 -/
theorem sld_rule_index :
    (resolveAll envShow (clsShow (tyArray tyInt)) 8).map (fun d => d.rule) = [2] := by decide

/-- SLD #8：它的唯一子推導用的是 `Int` 公理（索引 0）。 -/
theorem sld_kid_rule :
    (resolveAll envShow (clsShow (tyArray tyInt)) 8).map
      (fun d => d.kids.map (fun k => k.rule)) = [[0]] := by decide

/-- SLD #9：深度決定了推導的大小（深度 2、節點數 2）。 -/
theorem sld_depth_and_size :
    (resolveAll envShow (clsShow (tyArray tyInt)) 8).map
      (fun d => (derivDepth d, derivSize d)) = [(2, 2)] := by decide

/-! #### 9.2 終止由序數度量判定（5 條） -/

/-- 終止 #1：經典環境可終止。 -/
theorem terminating_env_show : terminating envShow = none := by decide

/-- 終止 #2：繞圈的法則被判為不終止。 -/
theorem terminating_env_loop :
    terminating envLoop = some "rule loop: body goal does not decrease" := by decide

/-- 終止 #3：不終止的判定是可判定的（`isSome`）。 -/
theorem terminating_env_loop_some : (terminating envLoop).isSome = true := by decide

/-- 終止 #4：度量確實嚴格下降（`ω^1 < ω^2`，用序數寫出來，不只是「檢查通過」）。 -/
theorem measure_decreases_show :
    ordLt (goalMeasure (clsShow (.uvar 0))) (goalMeasure (clsShow (tyArray (.uvar 0)))) = true := by
  decide

/-- 終止 #5：不一致的環境照樣通過終止檢查——終止與一致性是**兩件事**。 -/
theorem terminating_env_clash : terminating envClash = none := by decide

/-! #### 9.3 重疊實例、優先級、一致性（8 條） -/

/-- 一致性 #1：generic 與 specific 只有一對臨界對。 -/
theorem overlap_one_critical_pair : (criticalPairs envPrio).length = 1 := by decide

/-- 一致性 #2：`Show Int` 有兩條推導（重疊存在）。 -/
theorem overlap_two_derivations : (resolveAll envPrio goalShowInt 6).length = 2 := by decide

/-- 一致性 #3：典範化挑出的是 specific（索引 1）。 -/
theorem overlap_canonical_picks_specific :
    (canonical envPrio (resolveAll envPrio goalShowInt 6)).map (fun d => d.rule) = some 1 := by
  decide

/-- 一致性 #4：優先級不同 ⇒ 本引擎視為一致。 -/
theorem overlap_coherent : coherent envPrio [goalShowInt] 6 = true := by decide

/-- 一致性 #5：同優先級重疊 ⇒ 找得到不一致見證。 -/
theorem clash_witness_some : (incoherenceWitness envClash [goalShowInt] 6).isSome = true := by decide

/-- 一致性 #6：見證就是那個目標本身。 -/
theorem clash_witness_is_goal :
    (incoherenceWitness envClash [goalShowInt] 6).map (fun g => uEq g goalShowInt) = some true := by
  decide

/-- 一致性 #7：同優先級重疊 ⇒ 不一致。 -/
theorem clash_not_coherent : coherent envClash [goalShowInt] 6 = false := by decide

/-- 一致性 #8：經典環境沒有任何臨界對（沒有重疊 ⇒ 一致性風險為零）。 -/
theorem env_show_no_critical_pairs : criticalPairs envShow = [] := by decide

/-! ### 10. 全域實例的「不造假」性質（前沿：SLD 與一致性判準的可靠性）

一致性判準的每個零件都必須是**只做選擇、不做發明**的，否則「臨界對都可併合」
就只是把歧義藏起來。這裡把三件事寫成對所有環境、所有清單成立的定理：

1. `canonical_mem`：典範化的輸出一定來自輸入清單（挑一個，不是造一個）。
2. `criticalPairs_lt`／`criticalPairs_complete`：臨界對「不漏也不多」——
   每一對都是`i < j`，而且**任何**可重疊的規則對都會被列進去。
3. `incoherenceWitness_mem`：歧義見證一定是給定目標集裡的一個目標。 -/
set_option maxRecDepth 100000

theorem pick_eq_or (e : Env) (best x : Deriv) : pick e best x = x ∨ pick e best x = best := by
  unfold pick
  dsimp only
  split <;> simp

theorem foldl_pick_mem (e : Env) : ∀ (ds : List Deriv) (d : Deriv),
    ds.foldl (pick e) d ∈ d :: ds
  | [], d => by simp
  | x :: xs, d => by
    rw [List.foldl_cons]
    have ih := foldl_pick_mem e xs (pick e d x)
    have hstep : pick e d x ∈ d :: x :: xs := by
      rcases pick_eq_or e d x with h | h <;> simp [h]
    rcases List.mem_cons.mp ih with h | h
    · rw [h]; exact hstep
    · exact List.mem_cons_of_mem _ (List.mem_cons_of_mem _ h)

theorem canonical_mem (e : Env) (ds : List Deriv) (c : Deriv)
    (h : canonical e ds = some c) : c ∈ ds := by
  cases ds with
  | nil => simp [canonical] at h
  | cons d rest =>
    simp only [canonical, Option.some.injEq] at h
    subst h
    have := foldl_pick_mem e rest d
    rcases List.mem_cons.mp this with h | h
    · rw [h]; exact List.mem_cons_self
    · exact List.mem_cons_of_mem _ h

theorem maximalDerivs_subset (e : Env) (ds : List Deriv) (d : Deriv)
    (h : d ∈ maximalDerivs e ds) : d ∈ ds := by
  unfold maximalDerivs at h
  exact (List.mem_filter.mp h).1

theorem criticalPairs_lt (e : Env) (i j : Nat) (h : (i, j) ∈ criticalPairs e) : i < j := by
  unfold criticalPairs at h
  rw [List.mem_flatMap] at h
  obtain ⟨i', _, h2⟩ := h
  rw [List.mem_filterMap] at h2
  obtain ⟨j', _, h3⟩ := h2
  by_cases hc : (i' < j' && uUnifiable (renumber 0 (ruleAt e i').head) (renumber 500 (ruleAt e j').head)) = true
  · rw [if_pos hc] at h3
    simp only [Option.some.injEq, Prod.mk.injEq] at h3
    obtain ⟨rfl, rfl⟩ := h3
    simp only [Bool.and_eq_true, decide_eq_true_eq] at hc
    exact hc.1
  · rw [if_neg hc] at h3
    simp at h3

theorem criticalPairs_complete (e : Env) (i j : Nat) (hj : j < e.rules.length) (hij : i < j)
    (hu : uUnifiable (renumber 0 (ruleAt e i).head) (renumber 500 (ruleAt e j).head) = true) :
    (i, j) ∈ criticalPairs e := by
  unfold criticalPairs
  rw [List.mem_flatMap]
  refine ⟨i, List.mem_range.mpr (by omega), ?_⟩
  rw [List.mem_filterMap]
  refine ⟨j, List.mem_range.mpr hj, ?_⟩
  have hc : (i < j && uUnifiable (renumber 0 (ruleAt e i).head) (renumber 500 (ruleAt e j).head)) = true := by
    simp [hij, hu]
  simp [hc]

theorem mem_of_findSome?_self :
    ∀ (gs : List UTerm) (f : UTerm → Option UTerm), (∀ g x, f g = some x → x = g) →
      ∀ x, gs.findSome? f = some x → x ∈ gs
  | [], _, _, x, h => by simp at h
  | a :: as, f, hf, x, h => by
    have h' := h
    simp only [List.findSome?_cons] at h'
    cases hfa : f a with
    | none =>
      simp only [hfa] at h'
      exact List.mem_cons_of_mem _ (mem_of_findSome?_self as f hf x h')
    | some y =>
      simp only [hfa] at h'
      have hy : y = a := hf a y hfa
      rw [Option.some.injEq] at h'
      subst h'
      rw [hy]
      exact List.mem_cons_self

theorem incoherenceWitness_mem (e : Env) (gs : List UTerm) (d : Nat) (g : UTerm)
    (h : incoherenceWitness e gs d = some g) : g ∈ gs := by
  unfold incoherenceWitness at h
  refine mem_of_findSome?_self gs _ ?_ g h
  intro g' x hx
  dsimp only at hx
  split at hx
  · exact absurd hx (by simp)
  · split at hx
    · simp only [Option.some.injEq] at hx; exact hx.symm
    · exact absurd hx (by simp)

end KtLaws.Instances
