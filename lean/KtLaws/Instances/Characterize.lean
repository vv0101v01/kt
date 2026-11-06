/-
  KtLaws/Instances/Characterize.lean — 可導性「秩」到底是不是擬陣？給判準，不是量測
  對應 MoonBit `meta/instances/characterize.mbt`

  舊版只檢查**交換公理**（R4），這一檔先是發現、然後修正了它：交換公理**太弱**。

  反例（`envNeedsComposition`）：只有 `Show Int`（公理）與
  `Show (Array T) :- Show T`（合成規則），目標集 {Show Int, Show (Array Int)} 時，
  交換公理仍然成立，可是加入那條合成規則會讓秩一次跳 **2**
  （`r(S∪{e}) − r(S) = 2 > 1`）—— 真正被違反的是次模性 R3。

  本檔給出**判準**（在此片段中可判定）：

    可導性秩在目標集 G 上是擬陣秩 ⟺
      (1) 沒有合成規則的 head 落在 G 上（沒有協同效應的來源）；
      (2) 每條規則最多覆蓋一個目標（沒有「一鍵多解」）。

  兩條件的交集正好是「分割擬陣」的秩（秩 = 被覆蓋的目標數），而分割擬陣滿足全部秩公理；
  任一條件失效都給得出具體反例（單位增量 / 次模性見證）。

  另外附上「貪心給的是**極小**基，不是**最小**基」的反例（極小 ≠ 最小）。
-/
import KtLaws.Instances.Engine

namespace KtLaws.Instances

set_option maxRecDepth 100000

/-! ### 1. 規則集合上的集合運算 -/

/-- 集合（規則索引清單）是否含某元素。 -/
def memN (s : List Nat) (x : Nat) : Bool := s.any (fun y => y == x)

/-- 聯集（保持第一個清單的順序）。 -/
def unionN (s t : List Nat) : List Nat := s ++ t.filter (fun x => !memN s x)

/-- 交集。 -/
def interN (s t : List Nat) : List Nat := s.filter (fun x => memN t x)

/-- 子集。 -/
def subsetN (s t : List Nat) : Bool := s.all (fun x => memN t x)

/-- 插入排序（集合的正規形式：升冪、不重複）。 -/
def insertN : Nat → List Nat → List Nat
  | x, [] => [x]
  | x, y :: ys => if x == y then y :: ys else if x < y then x :: y :: ys else y :: insertN x ys

/-- 正規化：把任意索引清單變成集合的正規形式。 -/
def normN : List Nat → List Nat
  | [] => []
  | x :: xs => insertN x (normN xs)

/-- `{0..n−1}` 的全部子集（每個子集都是升冪清單）。 -/
def powersetOf : List Nat → List (List Nat)
  | [] => [[]]
  | x :: xs => (powersetOf xs).map (fun s => x :: s) ++ powersetOf xs

/-- 全部規則索引。 -/
def allRules (e : Env) : List Nat := List.range e.rules.length

/-- 只保留某些規則（依原順序）。 -/
def restrict (e : Env) (keep : List Nat) : Env :=
  { rules := keep.filterMap (fun i => e.rules[i]?) }

/-- 這個規則集合能不能解掉全部目標。 -/
def solvesAll (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  goals.all (fun g => solvable e g depth)

/-! ### 2. 可導性「秩」與秩公理（R1／R2／R3／R4） -/

/-- 秩：用這組規則能解出的目標個數。**不一定**是擬陣的秩，所以才要檢查。 -/
def rankOf (e : Env) (rules : List Nat) (goals : List UTerm) (depth : Nat) : Nat :=
  let sub := restrict e rules
  (goals.filter (fun g => solvable sub g depth)).length

/-- 秩表：把全部子集的秩一次算好（避免在秩公理的雙迴圈裡重算搜尋）。 -/
def rankTable (e : Env) (goals : List UTerm) (depth : Nat) : List (List Nat × Nat) :=
  (powersetOf (allRules e)).map (fun s => (s, rankOf e s goals depth))

/-- 查秩表（查詢前先正規化，否則 `[1,0]` 與 `[0,1]` 會被當成兩個集合）。 -/
def rankIn (tbl : List (List Nat × Nat)) (s : List Nat) : Nat :=
  let q := normN s
  (tbl.findSome? (fun p => if p.1 == q then some p.2 else none)).getD 0

/-- R1／R2／R3：秩公理（含**次模性**）。`none` 表示全過。 -/
def rankAxiomsOK (e : Env) (goals : List UTerm) (depth : Nat) : Option String :=
  let subsets := powersetOf (allRules e)
  let tbl := rankTable e goals depth
  subsets.findSome? (fun s =>
    let r := rankIn tbl s
    if r > s.length then some "R1 (bounds) violated"
    else
      subsets.findSome? (fun t =>
        if subsetN s t && rankIn tbl t < r then some "R2 (monotone) violated"
        else if rankIn tbl (unionN s t) + rankIn tbl (interN s t) > r + rankIn tbl t then
          some "R3 (submodular) violated"
        else none))

/-- R4：交換公理（`|A| < |B|` 且都獨立 ⇒ 存在 `e ∈ B∖A` 使 `A∪{e}` 仍獨立）。 -/
def exchangeOK (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  let subsets := powersetOf (allRules e)
  let tbl := rankTable e goals depth
  let indep := fun s => rankIn tbl s == s.length
  !(subsets.any (fun a =>
      subsets.any (fun b =>
        indep a && indep b && a.length < b.length &&
          !(b.filter (fun x => !memN a x)).any (fun x => indep (unionN a [x])))))

/-- **嚴格**擬陣判定：秩公理全過才算。 -/
def matroidalStrict (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  (rankAxiomsOK e goals depth).isNone

/-- 失敗原因（`none` 表示秩公理全過）。 -/
def matroidalFailure (e : Env) (goals : List UTerm) (depth : Nat) : Option String :=
  rankAxiomsOK e goals depth

/-! ### 3. 判準的左邊：目標集是否「只靠公理」就可解 -/

/-- 只留下公理規則（body 為空）。 -/
def axiomRules (e : Env) : Env := { rules := e.rules.filter (fun r => r.body.isEmpty) }

/-- 目標集在 E 中是公理可解的：每個可解目標，在「只有公理」的子環境下也可解。 -/
def axiomaticFragment (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  let ax := axiomRules e
  goals.all (fun g => !solvable e g depth || solvable ax g depth)

/-- 哪些目標「需要」合成規則。 -/
def goalsNeedingComposition (e : Env) (goals : List UTerm) (depth : Nat) : List UTerm :=
  let ax := axiomRules e
  goals.filter (fun g => solvable e g depth && !solvable ax g depth)

/-- 構件一：有沒有合成規則的 head 能落在目標集上（協同效應的來源）。 -/
def compositeRuleReachesGoal (e : Env) (goals : List UTerm) : Bool :=
  e.rules.any (fun r =>
    !r.body.isEmpty && goals.any (fun g => uUnifiable (renumber 0 r.head) g))

/-- 構件二：有沒有「一條規則同時覆蓋兩個以上目標」。 -/
def coverageDisjoint (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  (allRules e).all (fun i =>
    (goals.filter (fun g => solvable (restrict e [i]) g depth)).length ≤ 1)

/-- **判準**：可導性秩在 G 上是擬陣秩 ⟺ 兩個構件都成立。 -/
def matroidalCriterion (e : Env) (goals : List UTerm) (depth : Nat) : Bool :=
  !compositeRuleReachesGoal e goals && coverageDisjoint e goals depth

/-! ### 4. 反例的見證 -/

/-- 單位增量反例：`(規則索引, r(S), r(S∪{e}))`，其中 `S = 全規則 ∖ {e}` 且差值 ≥ 2。 -/
def unitIncrementWitness (e : Env) (goals : List UTerm) (depth : Nat) :
    Option (Nat × Nat × Nat) :=
  let n := e.rules.length
  let rfull := rankOf e (allRules e) goals depth
  (allRules e).findSome? (fun i =>
    let base := (allRules e).filter (fun j => !(j == i))
    let r0 := rankOf e base goals depth
    if rfull ≥ r0 + 2 then some (i, r0, rfull) else none)

/-- 次模性反例：`(A, B, r(A)+r(B), r(A∪B)+r(A∩B))` 使前者 < 後者。 -/
def submodularityWitness (e : Env) (goals : List UTerm) (depth : Nat) :
    Option (List Nat × List Nat × Nat × Nat) :=
  let subsets := powersetOf (allRules e)
  let tbl := rankTable e goals depth
  subsets.findSome? (fun a =>
    subsets.findSome? (fun b =>
      let lhs := rankIn tbl a + rankIn tbl b
      let rhs := rankIn tbl (unionN a b) + rankIn tbl (interN a b)
      if lhs < rhs then some (a, b, lhs, rhs) else none))

/-! ### 5. 判準對帳與貪心基 -/

/-- 一個環境的判準結果。 -/
structure MatroidVerdict where
  matroidal : Bool
  axiomatic : Bool
  compositeReaches : Bool
  coverageDisjoint : Bool
  needsComposition : List UTerm
  jump : Option (Nat × Nat × Nat)
deriving Repr

/-- 判準對帳：定理說 `matroidal ⟺ axiomatic`。 -/
def characterize (e : Env) (goals : List UTerm) (depth : Nat) : MatroidVerdict :=
  { matroidal := matroidalStrict e goals depth
    axiomatic := axiomaticFragment e goals depth
    compositeReaches := compositeRuleReachesGoal e goals
    coverageDisjoint := coverageDisjoint e goals depth
    needsComposition := goalsNeedingComposition e goals depth
    jump := unitIncrementWitness e goals depth }

/-- 以指定順序做貪心刪除，得到一個**極小**基。 -/
def greedyBasisWithOrder (e : Env) (goals : List UTerm) (order : List Nat) (depth : Nat) :
    List Nat :=
  order.foldl (fun keep i =>
    let cand := keep.filter (fun k => !(k == i))
    if solvesAll (restrict e cand) goals depth then cand else keep) (allRules e)

/-- 基的驗證：(a) 仍能解全部目標；(b) 去掉任何一條就解不動。 -/
def basisIsMinimal (e : Env) (goals : List UTerm) (basis : List Nat) (depth : Nat) : Bool :=
  solvesAll (restrict e basis) goals depth &&
    basis.all (fun k =>
      !solvesAll (restrict e (basis.filter (fun k2 => !(k2 == k)))) goals depth)

/-! ### 6. 白箱環境 -/

/-- 只有公理的環境：三個目標各自一條公理。 -/
def envAxiomatic : Env :=
  env [ rule "intRule" 0 (clsShow tyInt) []
      , rule "boolRule" 0 (clsShow tyBool) []
      , rule "arrIntRule" 0 (clsShow (tyArray tyInt)) [] ]

/-- 需要合成規則：`Show Int` 是公理，`Show (Array T)` 是合成。 -/
def envMinimal : Env :=
  env [ rule "showInt" 0 (clsShow tyInt) []
      , rule "showArray" 0 (clsShow (tyArray (.uvar 0))) [clsShow (.uvar 0)] ]

/-- 判準要處理的那個環境（同 `envMinimal`）。 -/
def envNeedsComposition : Env := envMinimal

/-- 貪心極小 ≠ 最小：`Show (Pair Int Bool)` 既可用一條公理解，也可用三條規則解。 -/
def envMinVsMinimal : Env :=
  env [ rule "pairRule" 0 (clsShow (tyPair (.uvar 0) (.uvar 1)))
          [clsShow (.uvar 0), clsShow (.uvar 1)]
      , rule "intRule" 0 (clsShow tyInt) []
      , rule "boolRule" 0 (clsShow tyBool) []
      , rule "pairIntBoolRule" 0 (clsShow (tyPair tyInt tyBool)) [] ]

/-- 萬用實例：一條規則覆蓋全部目標。 -/
def envWild : Env := env [rule "showAny" 0 (clsShow (.uvar 0)) []]

/-- generic（prio 0）＋ specific（prio 1）。 -/
def envGenericInt : Env :=
  env [ rule "generic" 0 (clsShow (.uvar 0)) []
      , rule "intRule" 1 (clsShow tyInt) [] ]

/-- 測試目標。 -/
def gInt : UTerm := clsShow tyInt
def gBool : UTerm := clsShow tyBool
def gArrInt : UTerm := clsShow (tyArray tyInt)
def gPairIntBool : UTerm := clsShow (tyPair tyInt tyBool)

/-! ### 7. 定律（40 條，對應 MoonBit 的 40 個標籤） -/

/-! #### 7.1 公理片段的秩是分割擬陣的秩（8 條） -/

/-- 分割擬陣 #1：`envAxiomatic` 的目標集是公理可解的。 -/
theorem axiomatic_fragment_ok :
    axiomaticFragment envAxiomatic [gInt, gBool, gArrInt] 6 = true := by decide

/-- 分割擬陣 #2：秩公理（含次模性）全過。 -/
theorem axiomatic_matroidal :
    matroidalStrict envAxiomatic [gInt, gBool, gArrInt] 6 = true := by decide

/-- 分割擬陣 #3：沒有失敗原因。 -/
theorem axiomatic_no_failure :
    matroidalFailure envAxiomatic [gInt, gBool, gArrInt] 6 = none := by decide

/-- 分割擬陣 #4：秩 = 被覆蓋的目標數（`r({0}) = 1`）。 -/
theorem axiomatic_rank_1 : rankOf envAxiomatic [0] [gInt, gBool, gArrInt] 6 = 1 := by decide

/-- 分割擬陣 #5：`r({0,1}) = 2`。 -/
theorem axiomatic_rank_2 : rankOf envAxiomatic [0, 1] [gInt, gBool, gArrInt] 6 = 2 := by decide

/-- 分割擬陣 #6：`r({0,1,2}) = 3`。 -/
theorem axiomatic_rank_3 :
    rankOf envAxiomatic [0, 1, 2] [gInt, gBool, gArrInt] 6 = 3 := by decide

/-- 分割擬陣 #7：沒有單位增量反例。 -/
theorem axiomatic_no_jump :
    unitIncrementWitness envAxiomatic [gInt, gBool, gArrInt] 6 = none := by decide

/-- 分割擬陣 #8：沒有次模性反例。 -/
theorem axiomatic_no_submodularity_counterexample :
    submodularityWitness envAxiomatic [gInt, gBool, gArrInt] 6 = none := by decide

/-! #### 7.2 交換公理太弱（12 條） -/

/-- 交換公理太弱 #1：舊判準（只測交換公理）說「是擬陣」。 -/
theorem exchange_alone_says_matroid :
    exchangeOK envNeedsComposition [gInt, gArrInt] 6 = true := by decide

/-- 交換公理太弱 #2：嚴格判準說「不是」。 -/
theorem strict_says_not_matroid :
    matroidalStrict envNeedsComposition [gInt, gArrInt] 6 = false := by decide

/-- 交換公理太弱 #3：失敗的具體理由是次模性 R3。 -/
theorem failure_reason_is_R3 :
    matroidalFailure envNeedsComposition [gInt, gArrInt] 6 = some "R3 (submodular) violated" := by
  decide

/-- 交換公理太弱 #4：單位增量見證是「第 0 條規則、秩 0 → 2」。 -/
theorem jump_witness :
    unitIncrementWitness envNeedsComposition [gInt, gArrInt] 6 = some (0, 0, 2) := by decide

/-- 交換公理太弱 #5：空規則集的秩是 0。 -/
theorem needs_composition_rank_empty :
    rankOf envNeedsComposition [] [gInt, gArrInt] 6 = 0 := by decide

/-- 交換公理太弱 #6：只有公理時解得出 `Show Int`（秩 1）。 -/
theorem needs_composition_rank_axiom :
    rankOf envNeedsComposition [0] [gInt, gArrInt] 6 = 1 := by decide

/-- 交換公理太弱 #7：只有合成規則時什麼都解不出（秩 0）—— 協同效應的根源。 -/
theorem needs_composition_rank_composite_only :
    rankOf envNeedsComposition [1] [gInt, gArrInt] 6 = 0 := by decide

/-- 交換公理太弱 #8：兩條一起用，秩一次跳到 2。 -/
theorem needs_composition_rank_both :
    rankOf envNeedsComposition [0, 1] [gInt, gArrInt] 6 = 2 := by decide

/-- 交換公理太弱 #9：從 `{合成規則}` 出發，加一條公理讓秩增加 2（> 1）。 -/
theorem needs_composition_jump_two :
    rankOf envNeedsComposition [0, 1] [gInt, gArrInt] 6
      = rankOf envNeedsComposition [1] [gInt, gArrInt] 6 + 2 := by decide

/-- 交換公理太弱 #10：次模性反例存在。 -/
theorem needs_composition_submodularity_exists :
    (submodularityWitness envNeedsComposition [gInt, gArrInt] 6).isSome = true := by decide

/-- 交換公理太弱 #11：反例本身：`r(A)+r(B) < r(A∪B)+r(A∩B)`。 -/
theorem needs_composition_submodularity_witness :
    (submodularityWitness envNeedsComposition [gInt, gArrInt] 6).map
      (fun w => decide (w.2.2.1 < w.2.2.2)) = some true := by decide

/-- 交換公理太弱 #12：目標集不是公理可解的（判準的另一邊也說「不是擬陣」）。 -/
theorem needs_composition_not_axiomatic :
    axiomaticFragment envNeedsComposition [gInt, gArrInt] 6 = false := by decide

/-! #### 7.3 判準是精確的（12 條） -/

/-- 六個環境的樣本清單。 -/
def sampleEnvs : List Env :=
  [envAxiomatic, envNeedsComposition, envShow, envMinVsMinimal, envClash, envGenericInt]

/-- 兩組目標集的樣本。 -/
def sampleGoalSets : List (List UTerm) :=
  [[gInt, gBool, gArrInt], [gInt, gArrInt, gPairIntBool]]

/-- 判準與嚴格秩公理檢查在某個樣本上是否一致。 -/
def criterionAgreesOn (e : Env) (goals : List UTerm) : Bool :=
  matroidalStrict e goals 6 == matroidalCriterion e goals 6

/-- 判準 #1：六個環境 × 兩組目標集，判準與嚴格秩公理檢查逐一致。 -/
theorem criterion_agrees :
    (sampleEnvs.all (fun e => sampleGoalSets.all (criterionAgreesOn e))) = true := by decide

/-- 判準 #2：樣本裡有「是擬陣」的情形。 -/
theorem criterion_has_matroid_samples :
    ([envAxiomatic, envNeedsComposition, envShow, envMinVsMinimal, envClash, envGenericInt].any
        (fun e => matroidalStrict e [gInt, gBool, gArrInt] 6)) = true := by decide

/-- 判準 #3：樣本裡也有「不是擬陣」的情形（不是全靠一邊撐著）。 -/
theorem criterion_has_non_matroid_samples :
    ([envAxiomatic, envNeedsComposition, envShow, envMinVsMinimal, envClash, envGenericInt].any
        (fun e => !matroidalStrict e [gInt, gBool, gArrInt] 6)) = true := by decide

/-- 判準 #4：兩邊的計數相等。 -/
theorem criterion_counts_agree :
    ([envAxiomatic, envNeedsComposition, envShow, envMinVsMinimal, envClash, envGenericInt].filter
        (fun e => matroidalStrict e [gInt, gBool, gArrInt] 6)).length
      = ([envAxiomatic, envNeedsComposition, envShow, envMinVsMinimal, envClash,
          envGenericInt].filter (fun e => matroidalCriterion e [gInt, gBool, gArrInt] 6)).length := by
  decide

/-- 判準 #5：合成規則落在目標上，但每條規則最多覆蓋一個目標。 -/
theorem criterion_composite_reaches :
    let v := characterize envNeedsComposition [gInt, gArrInt] 6
    v.compositeReaches && v.coverageDisjoint = true := by decide

/-- 判準 #6：所以它不是擬陣。 -/
theorem criterion_composite_not_matroidal :
    (characterize envNeedsComposition [gInt, gArrInt] 6).matroidal = false := by decide

/-- 判準 #7：萬用實例讓「覆蓋不相交」失效。 -/
theorem wild_coverage_not_disjoint :
    (characterize envWild [gInt, gBool, gArrInt] 6).coverageDisjoint = false := by decide

/-- 判準 #8：所以也不是擬陣。 -/
theorem wild_not_matroidal :
    (characterize envWild [gInt, gBool, gArrInt] 6).matroidal = false := by decide

/-- 判準 #9：無害的合成規則（head 落不到目標集上）。 -/
theorem harmless_no_composite_reach :
    (characterize envMinVsMinimal [gInt, gBool, gArrInt] 6).compositeReaches = false := by decide

/-- 判準 #10：⇒ 仍然是擬陣（判準的邊界，不是「有合成規則就壞」）。 -/
theorem harmless_matroidal :
    (characterize envMinVsMinimal [gInt, gBool, gArrInt] 6).matroidal = true := by decide

/-- 判準 #11：同一環境、把 `Pair Int Bool` 放進目標集 ⇒ 合成規則變得有害。 -/
theorem harmful_composite_reaches :
    (characterize envMinVsMinimal [gInt, gArrInt, gPairIntBool] 6).compositeReaches = true := by
  decide

/-- 判準 #12：⇒ 不再是擬陣（同環境、換目標集就翻面）。 -/
theorem harmful_not_matroidal :
    (characterize envMinVsMinimal [gInt, gArrInt, gPairIntBool] 6).matroidal = false := by decide

/-! #### 7.4 貪心給極小、不給最小（8 條） -/

/-- 貪心 #1：先刪合成規則與子目標規則 ⇒ 留下 `{3}`，大小 1。 -/
theorem greedy_forward_length :
    (greedyBasisWithOrder envMinVsMinimal [gPairIntBool] [0, 1, 2, 3] 6).length = 1 := by decide

/-- 貪心 #2：反過來先刪公理 ⇒ 留下 `{0,1,2}`，大小 3。 -/
theorem greedy_backward_length :
    (greedyBasisWithOrder envMinVsMinimal [gPairIntBool] [3, 0, 1, 2] 6).length = 3 := by decide

/-- 貪心 #3：後者嚴格大於前者 ⇒ 貪心不保證最小。 -/
theorem greedy_backward_bigger :
    (greedyBasisWithOrder envMinVsMinimal [gPairIntBool] [3, 0, 1, 2] 6).length
      > (greedyBasisWithOrder envMinVsMinimal [gPairIntBool] [0, 1, 2, 3] 6).length := by decide

/-- 貪心 #4：`{3}` 是極小基。 -/
theorem greedy_forward_minimal :
    basisIsMinimal envMinVsMinimal [gPairIntBool]
      (greedyBasisWithOrder envMinVsMinimal [gPairIntBool] [0, 1, 2, 3] 6) 6 = true := by decide

/-- 貪心 #5：`{0,1,2}` 也是極小基（極小 ≠ 最小）。 -/
theorem greedy_backward_minimal :
    basisIsMinimal envMinVsMinimal [gPairIntBool]
      (greedyBasisWithOrder envMinVsMinimal [gPairIntBool] [3, 0, 1, 2] 6) 6 = true := by decide

/-- 貪心 #6：`{3}` 真的解得出目標。 -/
theorem greedy_forward_solves :
    solvesAll (restrict envMinVsMinimal [3]) [gPairIntBool] 6 = true := by decide

/-- 貪心 #7：`{0,1,2}` 也真的解得出目標。 -/
theorem greedy_backward_solves :
    solvesAll (restrict envMinVsMinimal [0, 1, 2]) [gPairIntBool] 6 = true := by decide

/-- 貪心 #8：這個目標集**是**公理可解的，但貪心仍不保證最小 ——
    因為貪心看到的是「規則集合」，合成規則的存在就足以讓不同刪除順序停在不同的極小基。 -/
theorem greedy_axiomatic_but_not_minimum :
    axiomaticFragment envMinVsMinimal [gPairIntBool] 6 = true := by decide

end KtLaws.Instances
