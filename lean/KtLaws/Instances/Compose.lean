/-
  KtLaws/Instances/Compose.lean — 組合、併攏、鏡像對偶、深度窗口
  對應 MoonBit `meta/instances/compose.mbt`

  前一檔把單一模組的實例解析做完，這一檔處理**多模組**：
    * 組合：哪些實例是「不可省的」？（擬陣的基；交換公理要量測，不假設）
    * 併攏：局部解能不能升級成全域解？（下降條件 / 單值化障礙）
    * 鏡像：head 與 body 反轉得到對偶系統，對偶是對合，且與原系統互證。

  併攏的模型（ℤ₂ 局部系統）：每個模組給出局部解 `section : Int`，在重疊處只要求
  `s_i = sign · s_j`（`sign = ±1`）。給定局部解能否黏 ⟺ 每條轉移都被滿足；
  若局部解只定義到差一個符號，能否挑出相容取向 ⟺ 每個圈乘積為 +1。
  幾何原型：Möbius 帶上不存在非零連續截面，但零截面永遠存在 ——
  這件事在下面以「sections = (1,1,1) 黏不起來；(0,0,0) 黏得起來」的形式出現。
-/
import KtLaws.Instances.Characterize
import KtLaws.Simplicial

namespace KtLaws.Instances

set_option maxRecDepth 100000

/-! ### 1. 最小實例基（極小，不保證最小） -/

/-- 反覆嘗試刪除規則，只要全部目標仍可解就刪。結果是**極小**基。 -/
def minimalInstanceBasis (e : Env) (goals : List UTerm) (depth : Nat) : List Nat :=
  (allRules e).foldl (fun keep i =>
    let cand := keep.filter (fun k => !(k == i))
    if solvesAll (restrict e cand) goals depth then cand else keep) (allRules e)

/-! ### 2. 併攏：貼片、轉移、單值化障礙 -/

/-- 一個模組（貼片）：覆蓋的元素與它給出的局部解。 -/
structure Patch where
  name : String
  covers : List Nat
  sect : Int
deriving Repr

/-- 轉移關係：`s_i = sign · s_j`。 -/
structure Transition where
  i : Nat
  j : Nat
  sign : Int
deriving Repr

/-- 建貼片。 -/
def patch (name : String) (covers : List Nat) (sect : Int) : Patch := { name, covers, sect }

/-- 建轉移。 -/
def transition (i j : Nat) (sign : Int) : Transition := { i, j, sign }

/-- 第 `k` 個貼片（越界給空貼片）。 -/
def patchAt (ps : List Patch) (k : Nat) : Patch :=
  (ps[k]?).getD { name := "", covers := [], sect := 0 }

/-- 兩片是否真的重疊（交集非空）。 -/
def patchesOverlap (a b : Patch) : Bool := !(interN a.covers b.covers).isEmpty

/-- 取第 `k` 個位勢。 -/
def potGet (p : List (Option Int)) (k : Nat) : Option Int := (p[k]?).getD none

/-- 設定第 `k` 個位勢。 -/
def potSet : List (Option Int) → Nat → Int → List (Option Int)
  | [], _, _ => []
  | x :: xs, 0, v => some v :: xs
  | x :: xs, k + 1, v => x :: potSet xs k v

/-- 鬆弛一條邊：兩端都有位勢就檢查一致，一端有就傳過去。 -/
def relaxEdge (p : List (Option Int)) (conflict : Option (Nat × Nat)) (t : Transition) :
    List (Option Int) × Option (Nat × Nat) :=
  match potGet p t.i, potGet p t.j with
  | some a, some b =>
    (p, if b == a * t.sign then conflict
        else match conflict with | some c => some c | none => some (t.i, t.j))
  | some a, none => (potSet p t.j (a * t.sign), conflict)
  | none, some b => (potSet p t.i (b * t.sign), conflict)
  | none, none => (p, conflict)

/-- 一輪鬆弛（走過全部轉移）。 -/
def relaxAll (trans : List Transition) (st : List (Option Int) × Option (Nat × Nat)) :
    List (Option Int) × Option (Nat × Nat) :=
  trans.foldl (fun acc t => relaxEdge acc.1 acc.2 t) st

/-- 反覆鬆弛到不動點。 -/
def monoIter : Nat → List Transition → List (Option Int) → Option (Nat × Nat) →
    Option (Nat × Nat)
  | 0, _, _, found => found
  | n + 1, trans, pot, found =>
    let r := relaxAll trans (pot, found)
    match r.2 with
    | some c => some c
    | none => monoIter n trans r.1 none

/-- 單值化障礙：在貼片圖上傳播符號位勢，某點被要求同時有兩個不同位勢
    ⟺ 存在圈，其轉移乘積為 −1。回傳造成衝突的那條邊；`none` 表示平凡。

    實作：每個連通分量都以位勢 1 起算（等價於 MoonBit 的 BFS 種子），
    反覆鬆弛到不動點（`n + 1` 輪足夠：n 個點的圖，最長簡單路徑 n−1 條邊）。 -/
def monodromyWitness (patches : List Patch) (trans : List Transition) : Option (Nat × Nat) :=
  monoIter (patches.length + 1) trans (patches.map (fun _ => some (1 : Int))) none

/-- 黏合報告。 -/
structure GlueReport where
  glued : Option (List Int)
  obstruction : Option (Nat × Nat)
  structurallyOk : Bool
deriving Repr

/-- 黏合。單值化只在「非零局部解」上才會 obstruct：零截面在任何扭結下都存在
    （Möbius 帶上也一樣）。 -/
def glue (patches : List Patch) (trans : List Transition) : GlueReport :=
  let n := patches.length
  let structural :=
    trans.all (fun t => t.i < n && t.j < n && patchesOverlap (patchAt patches t.i) (patchAt patches t.j))
  let obstr :=
    trans.findSome? (fun t =>
      if (patchAt patches t.i).sect != t.sign * (patchAt patches t.j).sect
      then some (t.i, t.j) else none)
  let glued :=
    match obstr with
    | some _ => none
    | none =>
      if !structural then none
      else if patches.all (fun p => p.sect == 0) then some (patches.map (fun _ => 0))
      else match monodromyWitness patches trans with
        | some _ => none
        | none => some (patches.map (fun p => p.sect))
  { glued, obstruction := obstr, structurallyOk := structural }

/-- 只問「能不能黏」。 -/
def glues (patches : List Patch) (trans : List Transition) : Bool :=
  (glue patches trans).glued.isSome

/-! ### 3. 鏡像對偶：head/body 反轉、⊤ 與空 body 的互換 -/

/-- 真常數 ⊤。 -/
def topGoal : UTerm := .ufn 999 []

/-- 是不是 ⊤。 -/
def isTop (g : UTerm) : Bool := uEq g topGoal

/-- 鏡像一條規則。多目標規則需要真正的餘衍生，本版本明示不鏡像，原樣保留。 -/
def mirrorRule (r : Rule) : Rule :=
  let body := r.body.filter (fun b => !isTop b)
  match body with
  | [] => ⟨r.name, r.prio, topGoal, [r.head]⟩
  | [b] => ⟨r.name, r.prio, b, [r.head]⟩
  | _ => ⟨r.name, r.prio, r.head, body⟩

/-- 整個環境的鏡像。 -/
def mirrorEnv (e : Env) : Env := { rules := e.rules.map mirrorRule }

/-- 在環境上加入假設（當成公理）。 -/
def withHypotheses (e : Env) (hyps : List UTerm) : Env :=
  { rules := e.rules ++ hyps.map (fun h => ⟨"hyp", -1, h, []⟩) }

/-- 對偶互證：`E ⊢ G ⟺ mirror(E) + 假設 G ⊢ ⊤`。 -/
def dualDerivable (e : Env) (goal : UTerm) (depth : Nat) : Bool :=
  solvable (withHypotheses (mirrorEnv e) [goal]) topGoal depth

/- 項的扁平編碼（指紋用）。

   不用 `String`：Lean 核心的 `String` 操作對 kernel 是不透明的，`decide` 算不動；
   `List Nat` 的相等是結構性的，kernel 直接算。 -/
mutual
  /-- 項的扁平編碼。 -/
  def uFlatten : UTerm → List Nat
    | .uvar v => [0, v]
    | .ufn f xs => [1, f] ++ uFlattenList xs ++ [2]

  /-- 逐項扁平編碼。 -/
  def uFlattenList : List UTerm → List Nat
    | [] => []
    | x :: xs => uFlatten x ++ uFlattenList xs
end

/-- 優先級的有號編碼（`Int → Nat`，只為了讓指紋是純 `Nat`）。 -/
def prioCode (p : Int) : Nat := if p < 0 then 1000 + (0 - p).toNat else p.toNat

/-- 環境指紋（規則名稱長度 + 優先級 + head 編碼 + body 長度）。 -/
def envFingerprint (e : Env) : List Nat :=
  e.rules.flatMap (fun r => [r.name.length, prioCode r.prio] ++ uFlatten r.head ++ [r.body.length])

/-- 環境的 head 序列（編碼）。 -/
def envHeads (e : Env) : List (List Nat) := e.rules.map (fun r => uFlatten r.head)

/-! ### 4. Ramsey 深度窗口（搜尋成本的有限界） -/

/-- 鴿籠界：簽名類只有 `k` 類時，路徑長度 `> k` 必然重複。 -/
def pigeonholeWindow (k : Nat) : Nat := k + 1

/-- 二項係數（Lean 核心沒有 `Nat.choose`）。 -/
def binom : Nat → Nat → Nat
  | _, 0 => 1
  | 0, _ + 1 => 0
  | a + 1, b + 1 => binom a b + binom a (b + 1)

/-- Erdős–Szekeres 上界 `C(a+b−2, a−1)`。 -/
def erdosSzekeres (a b : Nat) : Nat := binom (a + b - 2) (a - 1)

/-- Ramsey 視窗 `R(k,k)`：小 `k` 用**已證明**的精確值（見 `../Ramsey.lean`：
    `ramsey33_eq`、`ramsey44_eq`），其餘退回 Erdős–Szekeres 上界。 -/
def ramseyWindow : Nat → Nat
  | 0 => 0
  | 1 => 1
  | 2 => 2
  | 3 => 6
  | 4 => 18
  | k => erdosSzekeres k k

/-- 已證明的 Ramsey 精確值（`R(3,3) = 6`、`R(3,4) = 9`、`R(4,4) = 18`、`R(3,5) = 14`）。 -/
def ramseyExact : Nat → Nat → Nat
  | 3, 3 => 6
  | 3, 4 => 9
  | 4, 3 => 9
  | 4, 4 => 18
  | 3, 5 => 14
  | 5, 3 => 14
  | a, b => erdosSzekeres a b

/-! ### 5. 白箱環境 -/

/-- 平坦情形：每條規則各自負責一個目標。 -/
def envFlat : Env :=
  env [rule "showInt" 0 (clsShow tyInt) [], rule "showBool" 0 (clsShow tyBool) []]

/-- 共享子目標情形：`Show (Pair A B)` 需要兩條。 -/
def envShared : Env :=
  env [ rule "showInt" 0 (clsShow tyInt) []
      , rule "showPair" 0 (clsShow (tyPair (.uvar 0) (.uvar 1)))
          [clsShow (.uvar 0), clsShow (.uvar 1)] ]

/-- 多一條永遠用不到的規則（`Ord Int`）。 -/
def envShowDummy : Env :=
  { rules := envShow.rules ++ [rule "dummy" 0 (clsOrd tyInt) []] }

/-- 線段覆蓋：兩片，符號 +1 ⇒ 可黏。 -/
def linePatches : List Patch :=
  [patch "U0" [0, 1] 7, patch "U1" [1, 2] 7]

/-- 線段的轉移。 -/
def lineTrans : List Transition := [transition 0 1 1]

/-- Möbius 帶：三片首尾相接，每條重疊都是扭結 −1。 -/
def mobiusPatch : List Patch :=
  [patch "U0" [0, 1] 1, patch "U1" [1, 2] 1, patch "U2" [2, 0] 1]

/-- Möbius 的轉移（三條都是 −1）。 -/
def mobiusTrans : List Transition :=
  [transition 0 1 (-1), transition 1 2 (-1), transition 2 0 (-1)]

/-- 同樣三片，但局部解全是 0（零截面）。 -/
def zeroMobiusPatch : List Patch :=
  [patch "U0" [0, 1] 0, patch "U1" [1, 2] 0, patch "U2" [2, 0] 0]

/-- 同樣三片，但轉移全為 +1（平凡化）⇒ 可黏。 -/
def trivialTrans : List Transition :=
  [transition 0 1 1, transition 1 2 1, transition 2 0 1]

/-! ### 6. 定律（35 條，對應 MoonBit 的 35 個標籤） -/

/-! #### 6.1 最小基是極小、貪心刪除是可靠的（3 條） -/

/-- 最小基 #1：`envShow` 對三個目標的極小基要用到 4 條規則。 -/
theorem minimal_basis_length :
    (minimalInstanceBasis envShow [gInt, gArrInt, clsShow (tyPair tyBool tyBool)] 8).length
      = 4 := by decide

/-- 最小基 #2：它真的是極小基（去掉任一條就解不動）。 -/
theorem minimal_basis_is_minimal :
    basisIsMinimal envShow [gInt, gArrInt, clsShow (tyPair tyBool tyBool)]
      (minimalInstanceBasis envShow [gInt, gArrInt, clsShow (tyPair tyBool tyBool)] 8) 8 = true := by
  decide

/-- 最小基 #3：多加一條永遠用不到的規則，基不會變大。 -/
theorem minimal_basis_ignores_useless :
    (minimalInstanceBasis envShowDummy [gInt, gArrInt, clsShow (tyPair tyBool tyBool)] 8).length
      = 4 := by decide

/-! #### 6.2 可導性閉包：平坦情形是擬陣（2 條，量測而非宣稱） -/

/-- 可導性 #1：平坦情形（每條規則各自負責一個目標）⇒ 交換公理成立。 -/
theorem derivability_flat_exchange :
    exchangeOK envFlat [gInt, gBool] 6 = true := by decide

/-- 可導性 #2：共享子目標情形 ⇒ 量測結果仍然是交換公理成立
    （本檔誠實地量，不由作者宣告；反例在 `Characterize.lean` 的次模性那組）。 -/
theorem derivability_shared_exchange :
    exchangeOK envShared [gInt, clsShow (tyPair tyInt tyInt)] 6 = true := by decide

/-! #### 6.3 併攏局部截面：Möbius 障礙（12 條） -/

/-- 併攏 #1：線段覆蓋（符號 +1）黏得起來。 -/
theorem line_glues : glues linePatches lineTrans = true := by decide

/-- 併攏 #2：黏出來的截面是 `[7,7]`。 -/
theorem line_glued_value : (glue linePatches lineTrans).glued = some [7, 7] := by decide

/-- 併攏 #3：結構上也合法（每條轉移都落在真重疊上）。 -/
theorem line_structurally_ok : (glue linePatches lineTrans).structurallyOk = true := by decide

/-- 併攏 #4：Möbius 帶（三條 −1）黏不起來。 -/
theorem mobius_not_glues : glues mobiusPatch mobiusTrans = false := by decide

/-- 併攏 #5：而且有具體的障礙見證。 -/
theorem mobius_obstruction_some : (glue mobiusPatch mobiusTrans).obstruction.isSome = true := by decide

/-- 併攏 #6：所以黏合結果是「沒有截面」。 -/
theorem mobius_glued_none : (glue mobiusPatch mobiusTrans).glued = none := by decide

/-- 併攏 #7：換成**零截面**就黏得起來 —— 這正是 Möbius 帶的拓撲事實。 -/
theorem mobius_zero_glues : glues zeroMobiusPatch mobiusTrans = true := by decide

/-- 併攏 #8：同樣三片、轉移全 +1（平凡化）⇒ 可黏。 -/
theorem mobius_trivial_glues : glues mobiusPatch trivialTrans = true := by decide

/-- 併攏 #9：Möbius 的單值化見證存在。 -/
theorem mobius_monodromy_some :
    (monodromyWitness mobiusPatch mobiusTrans).isSome = true := by decide

/-- 併攏 #10：平凡化的單值化障礙不存在。 -/
theorem trivial_monodromy_none :
    monodromyWitness mobiusPatch trivialTrans = none := by decide

/-- 併攏 #11：零截面黏出來的值全是 0。 -/
theorem mobius_zero_glued_value : (glue zeroMobiusPatch mobiusTrans).glued = some [0, 0, 0] := by
  decide

/-- 併攏 #12：平凡化的截面是 `[1,1,1]`。 -/
theorem mobius_trivial_glued_value : (glue mobiusPatch trivialTrans).glued = some [1, 1, 1] := by
  decide

/-! #### 6.4 神經上同調與黏合判定一致（4 條） -/

/-- 神經 #1：線段覆蓋的神經可縮（`H¹ = 0`）⇒ 可黏。 -/
theorem nerve_line_glues : Simplicial.coverGlues [[0, 1], [1, 2]] = true := by decide

/-- 神經 #2：圈覆蓋的神經 ≅ S¹（`H¹ = ℚ`）⇒ 不可黏。 -/
theorem nerve_circle_not_glues : Simplicial.coverGlues [[0, 1], [1, 2], [2, 0]] = false := by
  decide

/-- 神經 #3：圈覆蓋有具體的障礙見證（三片兩兩相交、三者共交為空）。 -/
theorem nerve_circle_obstruction :
    Simplicial.coverObstruction [[0, 1], [1, 2], [2, 0]] = some (0, 1, 2) := by decide

/-- 神經 #4：線段覆蓋沒有障礙（對照組）。 -/
theorem nerve_line_no_obstruction :
    Simplicial.coverObstruction [[0, 1], [1, 2]] = none := by decide

/-! #### 6.5 鏡像是對合，且給出對偶推導（6 條） -/

/-- 鏡像 #1：`mirror(mirror(E))` 的規則數與 `E` 相同。 -/
theorem mirror_twice_length :
    (mirrorEnv (mirrorEnv envShow)).rules.length = envShow.rules.length := by decide

/-- 鏡像 #2：而且規則名稱逐條相同（對合在結構層面成立）。 -/
theorem mirror_twice_names :
    (mirrorEnv (mirrorEnv envShow)).rules.map (fun r => r.name)
      = envShow.rules.map (fun r => r.name) := by decide

/-- 鏡像 #3：`E ⊢ Show (Array Int)`。 -/
theorem mirror_forward_derivable : solvable envShow (clsShow (tyArray tyInt)) 8 = true := by decide

/-- 鏡像 #4：互證：`mirror(E) + {Show (Array Int)} ⊢ ⊤`。 -/
theorem mirror_dual_derivable :
    dualDerivable envShow (clsShow (tyArray tyInt)) 8 = true := by decide

/-- 鏡像 #5：反面：`E` 解不出 `Eq Int`。 -/
theorem mirror_forward_not_derivable : solvable envShow (clsEq tyInt) 8 = false := by decide

/-- 鏡像 #6：對偶也證不出 `⊤`（互證兩邊一起失敗）。 -/
theorem mirror_dual_not_derivable : dualDerivable envShow (clsEq tyInt) 8 = false := by decide

/-! #### 6.6 Ramsey 視窗 vs 鴿籠視窗（5 條，量測而非假設） -/

/-- 視窗 #1：`R(3,3) = 6`。 -/
theorem ramsey_window_3 : ramseyWindow 3 = 6 := by decide

/-- 視窗 #2：鴿籠視窗 `3 + 1 = 4`。 -/
theorem pigeonhole_window_3 : pigeonholeWindow 3 = 4 := by decide

/-- 視窗 #3：Ramsey 視窗不窄於鴿籠視窗。 -/
theorem ramsey_wider_than_pigeonhole : ramseyWindow 3 ≥ pigeonholeWindow 3 := by decide

/-- 視窗 #4：`R(4,4) = 18` 現在**算得出來**（Paley 見證 + 遞迴上界夾死），
    比 Erdős–Szekeres 的 `C(6,3) = 20` 更緊 —— 舊版明說「不可行」的那一格。 -/
theorem ramsey_window_4_beats_erdos_szekeres :
    ramseyWindow 4 = 18 ∧ erdosSzekeres 4 4 = 20 := by decide

/-- 視窗 #5：`R(4,4) = 18 ≥ R(3,4) = 9`（單調性的一個具體點）。 -/
theorem ramsey_window_4_ge_34 : ramseyWindow 4 ≥ ramseyExact 3 4 := by decide

/-! #### 6.7 鏡像對合保持環境指紋（3 條） -/

/-- 指紋 #1：`mirror²` 的 head 序列與原環境完全相同。 -/
theorem mirror_fingerprint_heads :
    envHeads (mirrorEnv (mirrorEnv envMinimal)) = envHeads envMinimal := by decide

/-- 指紋 #2：指紋真的分辨得出鏡像（不是恆等函式）。 -/
theorem mirror_fingerprint_differs :
    envFingerprint (mirrorEnv envMinimal) ≠ envFingerprint envMinimal := by decide

/-- 指紋 #3：指紋是字串化的、非空。 -/
theorem mirror_fingerprint_nonempty : (envFingerprint envMinimal).length > 0 := by decide

end KtLaws.Instances
