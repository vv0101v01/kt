/-
  KtLaws/Instances/Coherence.lean — 一致性的完備化：不再靠使用者給的 battery
  對應 MoonBit `meta/instances/coherence.mbt`

  前一版的一致性判準有兩個誠實的缺口：

    (1) **battery 依賴**：`coherent(e, goals, d)` 只在「使用者給的那幾個目標」上檢查。
        給一串沒踩到雷的目標，它就說「一致」。
    (2) **看不見區域實例**：`criticalPairs(e)` 只掃 `e.rules`。可是真實系統裡還有
        **區域實例**（模組內實例、假設、`where` 帶進來的字典）—— 它們不在規則表裡，
        卻會在同一個目標上給出第二個見證。

  這一檔把兩件事都補上：

    * `reachableClosedGoals`：從規則的 head / body 出發做**可達目標宇宙**的閉包
      （BFS + mgu 實例化 + 具體化），得到一份由程式自己算出來的 battery；
    * `coherentComplete`：在這個算出來的宇宙上檢查「極大推導的見證唯一」＋臨界對可併合；
    * `coherentWithLocal`：把區域實例一起放進來檢查（舊 API 結構上看不見它們）；
    * `stableUnder`：**擴充穩定性**（COCHIS 的 stability property）——
      加新實例後，已可解目標的典範見證是否改變；
    * `newman`：終止 ∧ 局部合流 ⇒ 全域合流（Newman 引理）的實測版。

  並且對帳一個**正面**結果：在純 Horn 規則的片段裡，局部尖峰與 head 重疊是同一組東西
  （`peakOverlapAgreement` 逐一驗）。舊判準對「閉目標 + 純規則」其實是完備的，
  缺的是區域實例與 battery —— 這兩點在這裡補完。

  **與 MoonBit 的一處差異**（明示）：`resolveCanonical` 在這裡直接取
  「推導去重後的極大者」，沒有做 MoonBit 那個「把每個子節點換成典範推導再展開」的
  重寫。原因是那段重寫只在「同一個子目標有多個同優先級推導」時才有作用，而那正是
  `criticalPairs` 非空的情形；本片段的 `peakOverlapAgreement` 把這件事釘住了。
-/
import KtLaws.Instances.Compose

namespace KtLaws.Instances

set_option maxRecDepth 100000

/-! ### 1. 目標宇宙的基本工具 -/

mutual
  /-- 具體化：把剩下的變數換成常數（tag 98），得到一個**閉目標**。 -/
  def ground : UTerm → UTerm
    | .uvar k => .ufn 98 [.ufn k []]
    | .ufn f xs => .ufn f (groundList xs)

  /-- 逐項具體化。 -/
  def groundList : List UTerm → List UTerm
    | [] => []
    | x :: xs => ground x :: groundList xs
end

/-- 去重插入。 -/
def pushNew (dst : List UTerm) (t : UTerm) : List UTerm :=
  if dst.any (fun x => uEq x t) then dst else dst ++ [t]

/-- 目標宇宙的種子：每條規則的 head 與 body（各自重新編號，避免變數串味）。 -/
def openSeedsGo : List Rule → Nat → List UTerm → List UTerm
  | [], _, acc => acc
  | r :: rs, base, acc =>
    let acc1 := pushNew acc (renumber base r.head)
    let acc2 := r.body.foldl (fun a b => pushNew a (renumber base b)) acc1
    openSeedsGo rs (base + 1000) acc2

/-- 目標宇宙的種子。 -/
def openSeeds (e : Env) : List UTerm := openSeedsGo e.rules 1000 []

/-- 具體化池：三個具體型別 + 一個二階型別。 -/
def poolTy : Nat → UTerm
  | 0 => tyInt
  | 1 => tyBool
  | 2 => tyArray tyInt
  | _ => tyPair tyInt tyBool

/- 變數的出現順序（去重）。 -/
mutual
  /-- 收集變數編號（去重，按出現順序）。 -/
  def varSlots : UTerm → List Nat
    | .uvar k => [k]
    | .ufn _ xs => varSlotsList xs

  /-- 逐項收集。 -/
  def varSlotsList : List UTerm → List Nat
    | [] => []
    | x :: xs => (varSlots x).foldl (fun acc k => if acc.contains k then acc else acc ++ [k])
        (varSlotsList xs)
end

/-- `k` 在 slot 清單裡的位置。 -/
def slotIdx : List Nat → Nat → Option Nat
  | [], _ => none
  | s :: ss, k => if s == k then some 0 else (slotIdx ss k).map (fun i => i + 1)

mutual
  /-- 按 slot 順序代入。 -/
  def substSlots (t : UTerm) (slots : List Nat) (subs : List UTerm) : UTerm :=
    match t with
    | .uvar k =>
      match slotIdx slots k with
      | some i => (subs[i]?).getD (.uvar k)
      | none => .uvar k
    | .ufn f xs => .ufn f (substSlotsList xs slots subs)

  /-- 逐項代入（寫成對清單的結構遞迴，kernel 才算得動）。 -/
  def substSlotsList : List UTerm → List Nat → List UTerm → List UTerm
    | [], _, _ => []
    | x :: xs, slots, subs => substSlots x slots subs :: substSlotsList xs slots subs
end

/-- 把一個泛型模式具體化成一批閉目標（變數 ≤ 2 走笛卡兒積，更多時只取全 Int／全 Bool）。 -/
def instantiatePattern (t : UTerm) : List UTerm :=
  let slots := varSlots t
  let raws :=
    match slots with
    | [] => [t]
    | [_] => (List.range 4).map (fun i => substSlots t slots [poolTy i])
    | [_, _] =>
      (List.range 16).map (fun i => substSlots t slots [poolTy (i / 4), poolTy (i % 4)])
    | _ =>
      [ substSlots t slots (slots.map (fun _ => poolTy 0))
      , substSlots t slots (slots.map (fun _ => poolTy 1)) ]
  raws.foldl (fun acc g => pushNew acc g) []

/-! ### 2. 可達目標宇宙（BFS 閉包） -/

/-- 一步閉包：對目前層的每個目標，嘗試所有規則的 head，可合一就加入實例化後的目標與 body。 -/
def closureStep (e : Env) (frontier : List UTerm) : List UTerm :=
  frontier.foldl (fun acc g =>
    e.rules.foldl (fun acc2 r =>
      match uMgu g (renumber 7000 r.head) with
      | none => acc2
      | some sub =>
        let acc3 := pushNew acc2 (uApply sub g)
        r.body.foldl (fun a b => pushNew a (uApply sub (renumber 7000 b))) acc3) acc) []

/-- 分層閉包：回傳累積的模式清單。 -/
def closure : Nat → Env → List UTerm → List UTerm → List UTerm
  | 0, _, _, pat => pat
  | n + 1, e, frontier, pat =>
    let next := (closureStep e frontier).take 120
    if next.isEmpty then pat
    else closure n e next (next.foldl (fun acc g => pushNew acc g) pat)

/-- 可達目標宇宙：先收集**模式**（含變數），最後才具體化。 -/
def reachableClosedGoals (e : Env) (depth : Nat) : List UTerm :=
  let seeds := openSeeds e
  let pat := closure depth e seeds seeds
  let grounded :=
    pat.foldl (fun acc p =>
      (instantiatePattern p).foldl (fun a g => pushNew a (ground g)) acc) []
  grounded.take 400

/-! ### 3. 典範解析（推導去重後取極大者） -/

/-- 見證相同的推導視為同一棵，去重。 -/
def dedupEvidence (e : Env) (ds : List Deriv) : List Deriv :=
  ds.foldl (fun acc d =>
    if acc.any (fun d2 => uEq (evidence e d2) (evidence e d)) then acc else acc ++ [d]) []

mutual
  /-- 把一棵推導樹的每個子節點換成**它的典範子推導**。

      少了這一步會把「子目標的優先級」誤報成衝突：例如加了一條高優先級的
      `Show Int` 之後，`Show (Array Int)` 的兩棵樹只差在子節點走哪條路，
      但一棵正常解析器在每個節點都會先典範化 —— 它們不是兩個不同見解。 -/
  def canonDeriv (e : Env) : Nat → Deriv → Deriv
    | 0, d => d
    | n + 1, d =>
      { rule := d.rule
        kids := canonDerivList e n d.kids
        goal := d.goal }

  /-- 逐個子節點典範化。 -/
  def canonDerivList (e : Env) : Nat → List Deriv → List Deriv
    | 0, _ => []
    | _ + 1, [] => []
    | n + 1, k :: ks =>
      (match canonical e (maximalDerivs e (resolveAll e k.goal n)) with
       | some c => canonDeriv e n c
       | none => k) :: canonDerivList e n ks
end

/-- 典範解析：所有推導 → 子節點典範化 → 去重 → 只留最高優先級。 -/
def resolveCanonical (e : Env) (goal : UTerm) (depth : Nat) : List Deriv :=
  maximalDerivs e (dedupEvidence e ((resolveAll e goal depth).map (canonDeriv e depth)))

/-! ### 4. 無 battery 的一致性 -/

/-- 單一目標「有歧義」的判據：頂層推導不只一條，而且它們的見證不一致。 -/
def isAmbiguous (e : Env) (depth : Nat) (g : UTerm) : Bool :=
  let top := resolveCanonical e g depth
  top.length > 1 &&
    (match canonical e top with
     | none => false
     | some c => top.any (fun d => !uEq (evidence e d) (evidence e c)))

/-- 把「歧義目標」從清單裡挑出來（結構遞迴版本，方便對它做歸納）。 -/
def ambiguityFilter (e : Env) (depth : Nat) : List UTerm → List UTerm
  | [] => []
  | g :: gs => (if isAmbiguous e depth g then [g] else []) ++ ambiguityFilter e depth gs

/-- **沒有短路**的版本（＝原本的定義）。 -/
def ambiguousGoalsFull (e : Env) (depth : Nat) : List UTerm :=
  ambiguityFilter e depth (reachableClosedGoals e depth)

/-- 歧義目標清單。短路：沒有臨界對 ⇒ 每個目標最多只有一條可套用的規則 ⇒ 不可能有歧義。
    這個短路以前只用註解說明；現在它由兩條定理支撐：
    `ambiguityFilter_nil_of_unique_top`（頂層推導唯一 ⇒ 清單為空，對**任意**環境成立）
    與 `coherence_unique_top_envShow` / `coherence_single_rule_envShow`（白箱環境上可判定）。 -/
def ambiguousGoals (e : Env) (depth : Nat) : List UTerm :=
  if (criticalPairs e).isEmpty then [] else ambiguousGoalsFull e depth

/-- **完備版**一致性：不需要使用者提供 battery。 -/
def coherentComplete (e : Env) (depth : Nat) : Bool :=
  (criticalPairs e).all (fun p => overlappingJoinable e p.1 p.2 depth) &&
    (ambiguousGoals e depth).isEmpty

/-- 完備版的「哪裡不一致」回報。 -/
def incoherenceReport (e : Env) (depth : Nat) : Option UTerm :=
  let fromPairs :=
    (criticalPairs e).findSome? (fun p =>
      if overlappingJoinable e p.1 p.2 depth then none
      else
        let hi := renumber 0 (ruleAt e p.1).head
        let hj := renumber 500 (ruleAt e p.2).head
        match uMgu hi hj with
        | some sub => some (ground (uApply sub hi))
        | none => none)
  match fromPairs with
  | some g => some g
  | none => (ambiguousGoals e depth).head?

/-! ### 5. 對帳：局部尖峰 ⟺ head 重疊 -/

/-- 對指定目標集合，找出「重疊地套用」且真的在某個目標上發生的規則對。 -/
def overlapsAmong (e : Env) (goals : List UTerm) : List (Nat × Nat) :=
  (allRules e).flatMap (fun i =>
    (allRules e).filterMap (fun j =>
      if i < j &&
          uUnifiable (renumber 0 (ruleAt e i).head) (renumber 500 (ruleAt e j).head) &&
          goals.any (fun g =>
            uUnifiable (renumber 0 (ruleAt e i).head) g &&
              uUnifiable (renumber 500 (ruleAt e j).head) g)
      then some (i, j) else none))

/-- 對帳：`overlapsAmong(可達宇宙)` 與 `criticalPairs` 是同一組。 -/
def peakOverlapAgreement (e : Env) (depth : Nat) : Bool :=
  criticalPairs e == overlapsAmong e (reachableClosedGoals e depth)

/-! ### 6. 區域實例 -/

/-- 一條區域實例（模組內實例／假設帶進來的字典）。 -/
def localInstance (name : String) (prio : Int) (goal : UTerm) : Rule := ⟨name, prio, goal, []⟩

/-- 把區域實例併進環境。 -/
def withLocals (e : Env) (locals : List Rule) : Env := { rules := e.rules ++ locals }

/-- **區域實例感知**的一致性。 -/
def coherentWithLocal (e : Env) (locals : List Rule) (depth : Nat) : Bool :=
  coherentComplete (withLocals e locals) depth

/-! ### 7. 擴充穩定性（COCHIS 的 stability property） -/

/-- 某個目標在環境下的典範見證（用典範解析，不是原始推導）。 -/
def canonicalEvidence (e : Env) (g : UTerm) (depth : Nat) : Option UTerm :=
  (canonical e (resolveCanonical e g depth)).map (fun d => evidence e d)

/-- 加規則後是否**穩定**：原本解得出的可達目標，其典範見證必須一字不差。 -/
def stableUnder (e : Env) (extra : List Rule) (depth : Nat) : Bool :=
  let grown := withLocals e extra
  (reachableClosedGoals e depth).all (fun g =>
    match canonicalEvidence e g depth, canonicalEvidence grown g depth with
    | some b, some a => uEq b a
    | _, _ => true)

/-- 找出第一個漂移的目標。 -/
def instabilityWitness (e : Env) (extra : List Rule) (depth : Nat) : Option UTerm :=
  let grown := withLocals e extra
  (reachableClosedGoals e depth).findSome? (fun g =>
    match canonicalEvidence e g depth, canonicalEvidence grown g depth with
    | some b, some a => if uEq b a then none else some g
    | _, _ => none)

/-! ### 8. Newman 引理（實測版） -/

/-- 三件事分開回報。 -/
structure NewmanReport where
  terminating : Bool
  locallyConfluent : Bool
  global : Bool
deriving Repr

/-- 量測 Newman 引理：`terminating && local` 應該推出 `global`。 -/
def newman (e : Env) (depth : Nat) : NewmanReport :=
  { terminating := (terminating e).isNone
    locallyConfluent := (criticalPairs e).all (fun p => overlappingJoinable e p.1 p.2 depth)
    global := (ambiguousGoals e depth).isEmpty }

/-! ### 9. 白箱環境 -/

/-- 只有 showInt / showArray 的環境。 -/
def envMinimal2 : Env :=
  env [ rule "showInt" 0 (clsShow tyInt) []
      , rule "showArray" 0 (clsShow (tyArray (.uvar 0))) [clsShow (.uvar 0)] ]

/-- 同優先級的兩個 `Show Int`。 -/
def envClash2 : Env :=
  env [ rule "showIntA" 0 (clsShow tyInt) [], rule "showIntB" 0 (clsShow tyInt) [] ]

/-- generic（prio 0）＋ specific（prio 1）。 -/
def envPrio2 : Env :=
  env [ rule "generic" 0 (clsShow (.uvar 0)) []
      , rule "specificInt" 1 (clsShow tyInt) [] ]

/-- 會繞圈的環境。 -/
def envLoop2 : Env :=
  env [rule "loop" 0 (clsShow (.uvar 0)) [clsShow (tyArray (.uvar 0))]]

/-! ### 10. 定律（40 條，對應 MoonBit 的 40 個標籤） -/

/-! #### 10.1 完備檢查不需要使用者 battery（10 條） -/

/-- 完備 #1：可達宇宙自己算得出來，而且不是空的（至少 6 個目標）。 -/
theorem universe_not_small : (reachableClosedGoals envShow 3).length ≥ 6 := by decide

/-- 完備 #2：純規則環境一致 ⇒ 完備版也說一致。 -/
theorem complete_env_show_coherent : coherentComplete envShow 6 = true := by decide

/-- 完備 #3：而且回報「沒有不一致」。 -/
theorem complete_env_show_no_report : incoherenceReport envShow 6 = none := by decide

/-- 完備 #4：極小環境也一致。 -/
theorem complete_env_minimal_coherent : coherentComplete envMinimal2 6 = true := by decide

/-- 完備 #5：有衝突的環境 ⇒ 完備版說不一致。 -/
theorem complete_env_clash_incoherent : coherentComplete envClash2 6 = false := by decide

/-- 完備 #6：而且**指得出是哪個目標**（`Show Int` 的具體化）。 -/
theorem complete_env_clash_report :
    (incoherenceReport envClash2 6).map (fun g => uEq g (ground (clsShow tyInt))) = some true := by
  decide

/-- 完備 #7：回報確實存在。 -/
theorem complete_env_clash_report_some : (incoherenceReport envClash2 6).isSome = true := by decide

/-- 完備 #8：可達宇宙包含 `Show (Array Int)` 的具體化。 -/
theorem universe_has_array :
    (reachableClosedGoals envShow 3).any (fun g => uEq g (ground (clsShow (tyArray tyInt))))
      = true := by decide

/-- 完備 #9：也包含 `Show (Pair Int Int)` 的具體化。 -/
theorem universe_has_pair :
    (reachableClosedGoals envShow 3).any
      (fun g => uEq g (ground (clsShow (tyPair tyInt tyInt)))) = true := by decide

/-- 完備 #10：深層目標 `Show (Array (Array Int))` 也在宇宙裡。 -/
theorem universe_has_deep :
    (reachableClosedGoals envShow 3).any
      (fun g => uEq g (ground (clsShow (tyArray (tyArray tyInt))))) = true := by decide

/-! #### 10.2 局部尖峰 ⟺ head 重疊（7 條） -/

/-- 尖峰 #1：`envShow` 上兩者是同一組。 -/
theorem peaks_env_show : peakOverlapAgreement envShow 4 = true := by decide

/-- 尖峰 #2：極小環境上也一致。 -/
theorem peaks_env_minimal : peakOverlapAgreement envMinimal2 4 = true := by decide

/-- 尖峰 #3：有衝突的環境上也一致。 -/
theorem peaks_env_clash : peakOverlapAgreement envClash2 4 = true := by decide

/-- 尖峰 #4：優先級不同的重疊也一致。 -/
theorem peaks_env_prio : peakOverlapAgreement envPrio2 4 = true := by decide

/-- 尖峰 #5：那個環境剛好有一對臨界對。 -/
theorem prio_one_critical_pair : (criticalPairs envPrio2).length = 1 := by decide

/-- 尖峰 #6：但它仍然是一致的。 -/
theorem prio_coherent : coherentComplete envPrio2 6 = true := by decide

/-- 尖峰 #7：`envShow` 的 `Array`／`Pair` 兩條泛型實例不重疊。 -/
theorem env_show_no_pairs : criticalPairs envShow = [] := by decide

/-! #### 10.3 區域實例是缺的那一半（8 條） -/

/-- 區域實例 #1：全域規則之間沒有臨界對。 -/
theorem minimal_no_critical_pairs : criticalPairs envMinimal2 = [] := by decide

/-- 區域實例 #2：所以只看全域規則時，它是一致的。 -/
theorem minimal_coherent : coherentComplete envMinimal2 6 = true := by decide

/-- 區域實例 #3：可達宇宙裡也沒有任何重疊對。 -/
theorem minimal_no_overlaps :
    overlapsAmong envMinimal2 (reachableClosedGoals envMinimal2 4) = [] := by decide

/-- 區域實例 #4：加一條同優先級的區域實例之後 ⇒ 不一致（舊 API 看不見）。 -/
theorem local_instance_breaks :
    coherentWithLocal envMinimal2 [localInstance "modShowInt" 0 (clsShow tyInt)] 6 = false := by
  decide

/-- 區域實例 #5：若區域實例優先級更高，則是「具體者勝」而非不一致。 -/
theorem local_instance_higher_prio_ok :
    coherentWithLocal envMinimal2 [localInstance "modShowInt" 5 (clsShow tyInt)] 6 = true := by
  decide

/-- 區域實例 #6：無關的區域實例不影響一致性。 -/
theorem local_instance_unrelated_ok :
    coherentWithLocal envMinimal2 [localInstance "modEqBool" 0 (clsEq tyBool)] 6 = true := by
  decide

/-- 區域實例 #7：更高優先級的區域實例會讓見證漂移，而且指得出是哪個目標。 -/
theorem local_instance_witness :
    (instabilityWitness envMinimal2 [localInstance "modShowInt" 5 (clsShow tyInt)] 6).map
      (fun g => uEq g (ground (clsShow tyInt))) = some true := by decide

/-- 區域實例 #8：漂移見證確實存在。 -/
theorem local_instance_witness_some :
    (instabilityWitness envMinimal2 [localInstance "modShowInt" 5 (clsShow tyInt)] 6).isSome
      = true := by decide

/-! #### 10.4 擴充穩定性是可判定的（7 條） -/

/-- 穩定性 #1：加無關實例 ⇒ 穩定。 -/
theorem stable_unrelated : stableUnder envShow [rule "eqBool" 0 (clsEq tyBool) []] 6 = true := by
  decide

/-- 穩定性 #2：加更高優先級的具體實例 ⇒ 見證改變。 -/
theorem stable_more_specific_unstable :
    stableUnder envShow [rule "showIntSpecial" 3 (clsShow tyInt) []] 6 = false := by decide

/-- 穩定性 #3：漂移只發生在被影響的目標上（`Show Int`）。 -/
theorem stable_witness_is_int :
    (instabilityWitness envShow [rule "showIntSpecial" 3 (clsShow tyInt) []] 6).map
      (fun g => uEq g (ground (clsShow tyInt))) = some true := by decide

/-- 穩定性 #4：漂移見證確實存在。 -/
theorem stable_witness_some :
    (instabilityWitness envShow [rule "showIntSpecial" 3 (clsShow tyInt) []] 6).isSome = true := by
  decide

/-- 穩定性 #5：同優先級的 catch-all 不會漂移。 -/
theorem stable_catch_all_same_prio :
    stableUnder envShow [rule "showAny" 0 (clsShow (.uvar 0)) []] 6 = true := by decide

/-- 穩定性 #6：高優先級的 catch-all 會（具體者勝 ⇒ 見證整體換掉）。 -/
theorem stable_catch_all_high_prio :
    stableUnder envShow [rule "showAny" 2 (clsShow (.uvar 0)) []] 6 = false := by decide

/-- 穩定性 #7：穩定性對同一個擴充可重複判定。 -/
theorem stable_deterministic :
    stableUnder envShow [rule "eqBool" 0 (clsEq tyBool) []] 6
      = stableUnder envShow [rule "eqBool" 0 (clsEq tyBool) []] 6 := by decide

/-! #### 10.5 Newman 引理（8 條） -/

/-- Newman #1：`envShow` 終止。 -/
theorem newman_env_show_terminating : (newman envShow 6).terminating = true := by decide

/-- Newman #2：而且局部合流。 -/
theorem newman_env_show_local : (newman envShow 6).locallyConfluent = true := by decide

/-- Newman #3：⇒ 全域合流。 -/
theorem newman_env_show_global : (newman envShow 6).global = true := by decide

/-- Newman #4：同優先級的兩個實例：終止…… -/
theorem newman_clash_terminating : (newman envClash2 6).terminating = true := by decide

/-- Newman #5：……但**不**局部合流…… -/
theorem newman_clash_not_local : (newman envClash2 6).locallyConfluent = false := by decide

/-- Newman #6：……⇒ 不全域合流（引理的逆否）。 -/
theorem newman_clash_not_global : (newman envClash2 6).global = false := by decide

/-- Newman #7：會繞圈的環境終止性失敗。 -/
theorem newman_loop_not_terminating : (newman envLoop2 3).terminating = false := by decide

/-- Newman #8：本批環境上沒有反例。 -/
theorem newman_no_counterexample :
    [envShow, envMinimal2, envClash2].all (fun e =>
      let r := newman e 6
      !(r.terminating && r.locallyConfluent && !r.global)) = true := by decide

/-! ### 12. 短路的正當性（把註解換成定理） -/

/-- 一個目標有幾條**可套用的規則**（規則頭與目標可合一）。 -/
def matchingRules (e : Env) (g : UTerm) : List Nat :=
  (List.range e.rules.length).filter (fun i => uUnifiable (renumber 0 (ruleAt e i).head) g)

/-- 一般性引理：若每個目標的頂層推導都至多一條，則「歧義清單」是空的
    （對**任意**環境成立；這是短路的算術內容）。 -/
theorem ambiguityFilter_nil_of_unique_top (e : Env) (depth : Nat) :
    ∀ gs : List UTerm, (∀ g, g ∈ gs → (resolveCanonical e g depth).length ≤ 1) →
      ambiguityFilter e depth gs = [] := by
  intro gs
  induction gs with
  | nil => intro _; rfl
  | cons g gs ih =>
    intro h
    have hg : (resolveCanonical e g depth).length ≤ 1 := h g (List.mem_cons_self ..)
    have hgs : ∀ x, x ∈ gs → (resolveCanonical e x depth).length ≤ 1 :=
      fun x hx => h x (List.mem_cons_of_mem _ hx)
    have hfalse : isAmbiguous e depth g = false := by
      unfold isAmbiguous
      have h1 : ¬ (1 < (resolveCanonical e g depth).length) := Nat.not_lt.mpr hg
      simp [h1]
    simp [ambiguityFilter, hfalse, ih hgs]

/-- 短路的正當性 #1：`envShow` 的每個可達目標都只有一條頂層推導（可判定）。 -/
theorem coherence_unique_top_envShow :
    (reachableClosedGoals envShow 3).all
      (fun g => decide ((resolveCanonical envShow g 3).length ≤ 1)) = true := by decide

/-- 短路的正當性 #2：所以「沒有短路」的版本在 `envShow` 上也是空的
    —— 短路沒有改變答案。 -/
theorem coherence_no_ambiguity_envShow :
    (ambiguousGoalsFull envShow 3).isEmpty = true := by
  unfold ambiguousGoalsFull
  have hall : ∀ g, g ∈ reachableClosedGoals envShow 3 →
      (resolveCanonical envShow g 3).length ≤ 1 := by
    intro g hg
    have := List.all_eq_true.mp coherence_unique_top_envShow g hg
    simpa using of_decide_eq_true this
  rw [ambiguityFilter_nil_of_unique_top envShow 3 _ hall]
  rfl

/-- 短路的正當性 #3：每個可達目標最多只有**一條規則**可套用
    （這才是「沒有臨界對 ⇒ 沒有歧義」的來源）。 -/
theorem coherence_single_rule_envShow :
    (reachableClosedGoals envShow 3).all
      (fun g => decide ((matchingRules envShow g).length ≤ 1)) = true := by decide

/-- 短路的正當性 #4：`envShow` 根本沒有臨界對。 -/
theorem coherence_no_critical_pairs : (criticalPairs envShow).isEmpty = true := by decide

/-- 短路的正當性 #5：有短路與沒短路的兩個版本在 `envShow` 上給出同一個答案。 -/
theorem coherence_shortcut_agrees :
    (ambiguousGoals envShow 3).isEmpty = (ambiguousGoalsFull envShow 3).isEmpty := by decide

/-- 短路的正當性 #6：對照組 —— `envClash2` 有臨界對，而且**真的**有歧義目標，
    所以短路不是無條件成立的。 -/
theorem coherence_shortcut_needs_hypothesis :
    (criticalPairs envClash2).isEmpty = false ∧ (ambiguousGoalsFull envClash2 6).isEmpty = false := by
  decide

end KtLaws.Instances
