/-
  KtLaws/IIT/STLC.lean — 歸納-歸納（iii）的 STLC 實例：**β 的索引傳輸**
  對應 MoonBit `meta/iit/stlc.mbt` 與 `meta/iit/examples.mbt` 的 `schema_stlc`

  這裡要處理的是 iit 最微妙的一件事：`app (lam A B body) arg` 的約簡不是單純代換。
  被代入的項 `arg : Tm G A` 在走過 k 層 binder 之後，型別必須變成
  `Tm (cons A_k (… (cons A_1 G))) A` —— **上下文本身在變**。

  關鍵是把「插入一個型別到上下文」變成基本操作：

  * `ctxInsert ctx x k` ：把 `x` 插到 `ctx` 的第 `k` 個位置（0 = 最前面）
  * `substInsert t x k`：把 `x` 插到 `t` 的上下文第 `k` 個位置，並同步重寫所有變數節點

  有了它，代換就退化成「走過去、數深度」，而型別保持不是靠信仰：
  `iindexOf` 在每一步重算索引，定律用 `sameIndex` 把它比出來。

  **Lean 的實作限制**（見 `README.md` §4）：kernel 無法約簡 well-founded 遞迴，
  所以凡是 `decide` 要算的函式（`varDepth`、`substInsert`、`substGo`、`stepOK`）
  都改寫成「對 `Nat` 燃料的結構遞迴」。
-/
import KtLaws.IIT.Examples

namespace KtLaws.IIT

/-! ### 1. STLC schema（對應 MoonBit `schema_stlc`） -/

/-- `Ty` 的 `nat`。 -/
def stNat : IVal := IVal.mk 0 []

/-- 函式型別。 -/
def stArr (a b : IVal) : IVal := IVal.mk 1 [a, b]

/-- 空上下文。 -/
def stNil : IVal := IVal.mk 2 []

/-- 上下文擴充。 -/
def stCons (a g : IVal) : IVal := IVal.mk 3 [a, g]

/-- 位置 0 的變數：`vz(G, A) : Tm (cons A G) A`。 -/
def stVz (g a : IVal) : IVal := IVal.mk 4 [g, a]

/-- 位置的後繼：`vs(G, A, B, u) : Tm (cons B G) A`。 -/
def stVs (g a b u : IVal) : IVal := IVal.mk 5 [g, a, b, u]

/-- 應用：`app(G, A, B, f, x) : Tm G B`。 -/
def stApp (g a b f x : IVal) : IVal := IVal.mk 6 [g, a, b, f, x]

/-- λ：`lam(G, A, B, body) : Tm G (arr A B)`。 -/
def stLam (g a b body : IVal) : IVal := IVal.mk 7 [g, a, b, body]

/-- STLC 的 schema：`Ty`（0）、`Ctx`（1）、`Tm`（2，索引 = 上下文與型別）。 -/
def schemaSTLC : ISchema :=
  { sortNames := ["Ty", "Ctx", "Tm"]
    arities := [0, 0, 2]
    ctors :=
      [ ⟨"nat", 0, [], []⟩
      , ⟨"arr", 0, [], [.val 0, .val 0]⟩
      , ⟨"nil", 1, [], []⟩
      , ⟨"cons", 1, [], [.val 0, .val 1]⟩
      -- vz : (G : Ctx)(A : Ty) → Tm (cons A G) A
      , ⟨"vz", 2, [.ctor 3 [.var 1, .var 0], .var 1], [.val 1, .val 0]⟩
      -- vs : (G)(A)(B) → Tm G A → Tm (cons B G) A
      , ⟨"vs", 2, [.ctor 3 [.var 2, .var 0], .var 1],
          [.val 1, .val 0, .val 0, .recArg 2 [.var 0, .var 1]]⟩
      -- app : (G)(A)(B) → Tm G (arr A B) → Tm G A → Tm G B
      , ⟨"app", 2, [.var 0, .var 2],
          [.val 1, .val 0, .val 0,
           .recArg 2 [.var 0, .ctor 1 [.var 1, .var 2]],
           .recArg 2 [.var 0, .var 1]]⟩
      -- lam : (G)(A)(B) → Tm (cons A G) B → Tm G (arr A B)
      , ⟨"lam", 2, [.var 0, .ctor 1 [.var 1, .var 2]],
          [.val 1, .val 0, .val 0,
           .recArg 2 [.ctor 3 [.var 1, .var 0], .var 2]]⟩ ] }

/-! ### 2. 取值小工具 -/

instance : Inhabited IVal := ⟨IVal.mk 0 []⟩
instance : Inhabited ITerm := ⟨.hole⟩

/-- 建構子索引（`inductive` 不生成投影函式，自己寫）。 -/
def ivalCtor (v : IVal) : Nat := match v with | ⟨c, _⟩ => c

/-- 參數清單。 -/
def ivalArgs (v : IVal) : List IVal := match v with | ⟨_, a⟩ => a

/-- 第 `k` 個參數（越界給 `IVal.mk 0 []`）。 -/
def ivArg (v : IVal) (k : Nat) : IVal := ((ivalArgs v)[k]?).getD (IVal.mk 0 [])

/-- 上下文是不是 `cons`。 -/
def ctxIsCons (c : IVal) : Bool := ivalCtor c == 3

/-- 上下文的頭。 -/
def ctxHead (c : IVal) : IVal := ivArg c 0

/-- 上下文的尾。 -/
def ctxTail (c : IVal) : IVal := ivArg c 1

/-! ### 3. 上下文的插入與移除 -/

/-- 把 `x` 插到上下文的第 `k` 個位置（`k` 超過長度時貼在最後）。燃料 = `k`。 -/
def ctxInsert (ctx x : IVal) : Nat → IVal
  | 0 => stCons x ctx
  | k + 1 =>
    match ctx with
    | ⟨3, [h, t]⟩ => stCons h (ctxInsert t x k)
    | _ => stCons x ctx

/-- 移除上下文的第 `k` 個元素（`k` 超出範圍時原樣回傳）。燃料 = `k`。 -/
def ctxRemove (ctx : IVal) : Nat → IVal
  | 0 =>
    match ctx with
    | ⟨3, [_, t]⟩ => t
    | _ => ctx
  | k + 1 =>
    match ctx with
    | ⟨3, [h, t]⟩ => stCons h (ctxRemove t k)
    | _ => ctx

/-! ### 4. 變數節點：位置、型別、完整上下文 -/

/-- 是不是變數節點。 -/
def isVar (t : IVal) : Bool := ivalCtor t == 4 || ivalCtor t == 5

/-- 變數節點的完整上下文：`vz` 的上下文是 `cons A G`。 -/
def varFullCtx (t : IVal) : IVal :=
  if ivalCtor t == 4 then stCons (ivArg t 1) (ivArg t 0) else stCons (ivArg t 2) (ivArg t 0)

/-- 變數節點的型別。 -/
def varTy (t : IVal) : IVal := ivArg t 1

/-- 變數的位置（帶燃料：沿 `vs` 鏈數下去）。 -/
def varDepthGo : Nat → IVal → Nat
  | 0, _ => 0
  | n + 1, t => if ivalCtor t == 4 then 0 else 1 + varDepthGo n (ivArg t 3)

/-- 變數的位置。 -/
def varDepth (t : IVal) : Nat := varDepthGo (ivalSize t) t

/-- 由（完整上下文, 位置, 型別）重建變數節點——所有「上下文改變」的收斂點。 -/
def makeVar (ctx : IVal) : Nat → IVal → IVal
  | 0, ty => stVz (ctxTail ctx) ty
  | d + 1, ty => stVs (ctxTail ctx) ty (ctxHead ctx) (makeVar (ctxTail ctx) d ty)

/-! ### 5. 上下文插入：弱化與索引傳輸的統一形式 -/

/-- 在項 `t` 的上下文第 `k` 個位置插入型別 `x`，並同步重寫所有子節點。

    Lean 版用燃料（`ivalSize t`）：每下降一層消耗一格，而子項的 `ivalSize`
    嚴格小於父項，所以 `ivalSize t` 一定夠。 -/
def substInsertGo : Nat → IVal → IVal → Nat → IVal
  | 0, t, _, _ => t
  | n + 1, t, x, k =>
    if isVar t then
      let ctx := ctxInsert (varFullCtx t) x k
      let p := varDepth t
      let np := if k ≤ p then p + 1 else p
      makeVar ctx np (varTy t)
    else
      match t with
      | ⟨7, [g, a0, b0, body]⟩ =>
        if k == 0 then stLam (ctxInsert g x 0) a0 b0 (substInsertGo n body x 1)
        else stLam (ctxInsert g x (k - 1)) a0 b0 (substInsertGo n body x k)
      | ⟨6, [g, a0, b0, f, a]⟩ =>
        stApp (ctxInsert g x k) a0 b0 (substInsertGo n f x k) (substInsertGo n a x k)
      | t => t

/-- 在項的上下文第 `k` 個位置插入型別。 -/
def substInsert (t x : IVal) (k : Nat) : IVal := substInsertGo (ivalSize t) t x k

/-- **弱化**：`t : Tm G A ⟹ Tm (cons x G) A`。就是 `k = 0` 的插入。 -/
def stWeaken (t x : IVal) : IVal := substInsert t x 0

/-! ### 6. β：代換（帶索引傳輸） -/

/-- 依序把 `crossed` 的每個型別插到最前面（`arg` 走過 k 層 binder 的結果）。 -/
def insertAll (acc : IVal) : List IVal → IVal
  | [] => acc
  | x :: xs => insertAll (substInsert acc x 0) xs

/-- 代換（帶燃料）。在深度 `d = crossed.length` 遇到位置 `p` 的變數時：
    `p = d` ⇒ 被抓的變數（換成 `arg` 走過 binder 的結果）；
    `p > d` ⇒ 外層變數（位置減一，因為被消去一個 binder）；`p < d` ⇒ 內層綁定，位置不變。 -/
def substGoFuel : Nat → IVal → IVal → List IVal → IVal
  | 0, t, _, _ => t
  | n + 1, t, arg, crossed =>
    let d := crossed.length
    if isVar t then
      let p := varDepth t
      if p == d then insertAll arg crossed
      else
        let ctx := ctxRemove (varFullCtx t) d
        let np := if p > d then p - 1 else p
        makeVar ctx np (varTy t)
    else
      match t with
      | ⟨7, [g, a0, b0, body]⟩ =>
        stLam (ctxRemove g d) a0 b0 (substGoFuel n body arg (crossed ++ [a0]))
      | ⟨6, [g, a0, b0, f, a]⟩ =>
        stApp (ctxRemove g d) a0 b0 (substGoFuel n f arg crossed) (substGoFuel n a arg crossed)
      | t => t

/-- 代換。 -/
def substGo (t arg : IVal) (crossed : List IVal) : IVal :=
  substGoFuel (ivalSize t) t arg crossed

/-- 單步 β：`app (lam A B body) arg ↝ body[x₀ := arg]`。
    只有「函式位置就是 λ」時才動；其他情形回傳 `none`（卡住的項不假裝能走）。 -/
def stBeta (t : IVal) : Option IVal :=
  match t with
  | ⟨6, [_, _, _, f, arg]⟩ =>
    match f with
    | ⟨7, [_, _, _, body]⟩ => some (substGo body arg [])
    | _ => none
  | _ => none

/-- 反覆單步 β 直到卡住或燃料用完（值的語義：卡住的項就是「值」）。 -/
def stNorm : Nat → IVal → IVal
  | 0, t => t
  | n + 1, t =>
    match stBeta t with
    | some t' => stNorm n t'
    | none => t

/-! ### 7. 索引相同（型別保持的可判定形式） -/

/-- 兩個項的索引（上下文, 型別）完全相同。 -/
def sameIndex (s : ISchema) (a b : IVal) : Bool := itermEqList (iindexOf s a) (iindexOf s b)

/-- 索引的第 `k` 項（越界給 `hole`）。 -/
def idxAt (s : ISchema) (v : IVal) (k : Nat) : ITerm := ((iindexOf s v)[k]?).getD .hole

/-- `Tm G A` 的索引。 -/
def tmIndex (g a : IVal) : List ITerm := [itermOfVal g, itermOfVal a]

/-- 布林的便利函式：`stBeta t` 的結果是否等於 `r`。 -/
def betaIs (t r : IVal) : Bool := (stBeta t).map (fun t' => ivalEq t' r) |>.getD false

/-- `stBeta t` 的結果是否滿足 `p`。 -/
def betaProp (t : IVal) (p : IVal → Bool) : Bool := (stBeta t).map p |>.getD false

/-- `stBeta t` 是否卡住（不能動）。 -/
def betaStuck (t : IVal) : Bool := (stBeta t).isNone

/-! ### 8. 範例程式（建構子寫法本身就是規格） -/

/-- `x : Tm (cons nat nil) nat`。 -/
def exVar : IVal := stVz stNil stNat

/-- `λx:nat. x`。 -/
def exId : IVal := stLam stNil stNat stNat exVar

/-- 測試用的值一律是 λ 項（schema 裡沒有 nat 常數），所以 `arg = λy:nat. y`。 -/
def exArg : IVal := exId

/-- `(λx:nat→nat. x) (λy:nat. y)` —— 一次 β 就回到 `λy:nat. y`。 -/
def exApp1 : IVal :=
  let arr := stArr stNat stNat
  stApp stNil arr arr (stLam stNil arr arr (stVz stNil arr)) exArg

/-- `(λx:A. λy:nat. x) (λz:nat. z)` —— 需要**弱化**（arg 走進一層 binder）。 -/
def exApp2 : IVal :=
  let a := stArr stNat stNat
  stApp stNil a (stArr stNat a)
    (stLam stNil a (stArr stNat a)
      (stLam (stCons a stNil) stNat a (stVs (stCons a stNil) a stNat (stVz stNil a))))
    exArg

/-- `λx:nat→nat. x`。 -/
def idAtArr : IVal :=
  let arr := stArr stNat stNat
  stLam stNil arr arr (stVz stNil arr)

/-- `(λx:nat. x) (λx:nat. x)` —— 型別錯的應用，索引檢查必須先攔下來。 -/
def badApp : IVal := stApp stNil stNat stNat exId exArg

/-- `((λf.f) (λx:nat. x))` —— 正確的應用。 -/
def goodApp : IVal := stApp stNil (stArr stNat stNat) (stArr stNat stNat) idAtArr exArg

/-- 卡住的項：函式位置是**變數**，不能 β。 -/
def stuckTerm : IVal :=
  let arr := stArr stNat stNat
  stApp (stCons stNat (stCons arr stNil)) stNat stNat
    (stVs (stCons arr stNil) arr stNat (stVz stNil arr))
    (stVz (stCons arr stNil) stNat)

/-- 電池第 3 項：`(λx:A. λy:A. y) (λz.z)`。 -/
def bat3 : IVal :=
  let a := stArr stNat stNat
  stApp stNil a (stArr a a)
    (stLam stNil a (stArr a a) (stLam (stCons a stNil) a a (stVz (stCons a stNil) a)))
    exArg

/-- 電池第 4 項：`(λx:A. x) ((λx:A. x) arg)` —— 內層先約簡、外層再套一次。 -/
def bat4 : IVal :=
  let a := stArr stNat stNat
  stApp stNil a a (stLam stNil a a (stVz stNil a))
    (stApp stNil a a (stLam stNil a a (stVz stNil a)) exArg)

/-! ### 9. 每一步都保持索引（可判定的電池） -/

/-- 走 `n` 步 β：每一步都要求約簡結果良構、且索引與前一步相同。 -/
def stepOK (s : ISchema) : Nat → IVal → Bool
  | 0, _ => true
  | n + 1, t =>
    match stBeta t with
    | none => true
    | some t' => icheck s t' && sameIndex s t t' && stepOK s n t'

/-- 電池：四個閉項，每一個都先驗良構，再逐步驗「每一步都保持索引」。 -/
def batteryOK (s : ISchema) : Bool :=
  ([exApp1, exApp2, bat3, bat4].map (fun t => icheck s t && stepOK s 12 t)).all (fun b => b)

/-- 電池的每一個成員都良構。 -/
def batteryTermsOK (s : ISchema) : Bool :=
  ([exApp1, exApp2, bat3, bat4].map (icheck s)).all (fun b => b)

/-! ### 10. 定律（40 條，對應 MoonBit 的 40 個標籤） -/

/-! #### 10.1 STLC β 的索引保持（11 條） -/

/-- β 索引保持 #1：原項 `(λx:nat→nat. x) (λy.y)` 良構。 -/
theorem beta1_src_checks : icheck schemaSTLC exApp1 = true := by decide

/-- β 索引保持 #2：一次 β 真的回到 `λy:nat. y`。 -/
theorem beta1_reduct_is_arg : betaIs exApp1 exArg = true := by decide

/-- β 索引保持 #3：約簡結果仍然良構。 -/
theorem beta1_reduct_checks : betaProp exApp1 (icheck schemaSTLC) = true := by decide

/-- β 索引保持 #4：約簡前後的索引（上下文, 型別）完全相同 —— 這就是型別保持。 -/
theorem beta1_index_preserved : betaProp exApp1 (sameIndex schemaSTLC exApp1) = true := by decide

/-- β 索引保持 #5：走進一層 binder 的項 `(λx:A. λy:nat. x) (λz.z)` 良構。 -/
theorem beta2_src_checks : icheck schemaSTLC exApp2 = true := by decide

/-- β 索引保持 #6：約簡結果是個 λ。 -/
theorem beta2_reduct_is_lam : betaProp exApp2 (fun r => ivalCtor r == 7) = true := by decide

/-- β 索引保持 #7：約簡結果仍然良構（`arg` 被弱化過才過得了檢查）。 -/
theorem beta2_reduct_checks : betaProp exApp2 (icheck schemaSTLC) = true := by decide

/-- β 索引保持 #8：約簡前後的索引完全相同。 -/
theorem beta2_index_preserved : betaProp exApp2 (sameIndex schemaSTLC exApp2) = true := by decide

/-- β 索引保持 #9：內層 `arg` 的上下文確實從 `nil` 變成 `cons nat nil`（弱化發生了）。 -/
theorem beta2_arg_weakened :
    betaProp exApp2 (fun r => ivalEq (ivArg (ivArg r 3) 0) (stCons stNat stNil)) = true := by decide

/-- β 索引保持 #10：燃料用完就停，不會假裝算出答案（0 步 = 原項）。 -/
theorem beta_zero_fuel_keeps_term : ivalEq (stNorm 0 exApp1) exApp1 = true := by decide

/-- β 索引保持 #11：λ 是值，β 不對它開火。 -/
theorem beta_lam_is_stuck : betaStuck exArg = true := by decide

/-! #### 10.2 弱化與上下文插入一致（9 條） -/

/-- 弱化 #1：對變數而言，弱化就是「包一層 `vs`」。 -/
theorem weaken_var_is_vs : ivalCtor (stWeaken exVar stNat) = 5 := by decide

/-- 弱化 #2：弱化後的變數仍然良構。 -/
theorem weaken_var_checks : icheck schemaSTLC (stWeaken exVar stNat) = true := by decide

/-- 弱化 #3：型別不變（索引的第二項相同）。 -/
theorem weaken_var_ty_preserved :
    itermEq (idxAt schemaSTLC exVar 1) (idxAt schemaSTLC (stWeaken exVar stNat) 1) = true := by decide

/-- 弱化 #4：上下文變了（索引的第一項不同）—— 這正是相依型別的味道。 -/
theorem weaken_var_ctx_changes :
    itermEq (idxAt schemaSTLC exVar 0) (idxAt schemaSTLC (stWeaken exVar stNat) 0) = false := by decide

/-- 弱化 #5：作用在 λ 上仍然良構。 -/
theorem weaken_lam_checks : icheck schemaSTLC (stWeaken exArg stNat) = true := by decide

/-- 弱化 #6：λ 的上下文被插入了 `nat`。 -/
theorem weaken_lam_ctx_inserted :
    ivalEq (ivArg (stWeaken exArg stNat) 0) (stCons stNat stNil) = true := by decide

/-- 弱化 #7：弱化兩次（兩層 `vs` 鏈）仍然良構。 -/
theorem weaken_twice_checks :
    icheck schemaSTLC (stWeaken (stWeaken exVar stNat) (stArr stNat stNat)) = true := by decide

/-- 弱化 #8：弱化兩次的位置 = 2。 -/
theorem weaken_twice_depth : varDepth (stWeaken (stWeaken exVar stNat) (stArr stNat stNat)) = 2 := by decide

/-- 弱化 #9：把型別錯的 `arg` 塞進 `app`，索引檢查必須先攔下來。 -/
theorem weaken_bad_app_rejected : icheck schemaSTLC badApp = false := by decide

/-! #### 10.3 主體約簡的電池（4 條） -/

/-- 主體約簡 #1：四個閉項的每一步約簡都保持索引（可判定的電池）。 -/
theorem subject_reduction_battery : batteryOK schemaSTLC = true := by decide

/-- 主體約簡 #2：電池的每一個成員都良構。 -/
theorem battery_terms_check : batteryTermsOK schemaSTLC = true := by decide

/-- 主體約簡 #3：內層先約簡的項 `(λx.x) ((λx.x) arg)` 走完兩步回到 `arg`。 -/
theorem battery_bat4_nf : ivalEq (stNorm 12 bat4) exArg = true := by decide

/-- 主體約簡 #4：全部走完之後仍然良構（正規形也是良構項）。 -/
theorem battery_nf_checks : icheck schemaSTLC (stNorm 8 exApp1) = true := by decide

/-! #### 10.4 正規化停在卡住的值（7 條） -/

/-- 正規化 #1：`(λx.x) (λy.y)` 正規化到 `λy.y`。 -/
theorem norm_reaches_arg : ivalEq (stNorm 8 exApp1) exArg = true := by decide

/-- 正規化 #2：正規形已經不能再走。 -/
theorem norm_result_is_stuck : betaStuck (stNorm 8 exApp1) = true := by decide

/-- 正規化 #3：函式位置是變數時不 β（卡住的項不是值也不能動）。 -/
theorem stuck_app_does_not_beta : betaStuck stuckTerm = true := by decide

/-- 正規化 #4：但這個卡住的項本身是良構的（開放項，上下文兩層）。 -/
theorem stuck_app_checks : icheck schemaSTLC stuckTerm = true := by decide

/-- 正規化 #5：燃料為 0 時停在原項（不會假裝算出答案）。 -/
theorem norm_zero_fuel : ivalEq (stNorm 0 exApp1) exApp1 = true := by decide

/-- 正規化 #6：`exApp1` 一步就到底，之後就卡住。 -/
theorem norm_one_step_then_stuck : betaProp exApp1 (betaStuck) = true := by decide

/-- 正規化 #7：走進 binder 的項正規化後仍然良構。 -/
theorem norm_ex_app2_checks : icheck schemaSTLC (stNorm 8 exApp2) = true := by decide

/-! #### 10.5 `Tm` 索引真的需要 `cons`（9 條） -/

/-- `Tm` 需要 `cons` #1：STLC 的 schema 良構。 -/
theorem stlc_schema_ok : ichemaOK schemaSTLC = none := by decide

/-- `Tm` 需要 `cons` #2：恆等項 `λx:nat. x` 良構。 -/
theorem stlc_id_term_checks : icheck schemaSTLC exId = true := by decide

/-- `Tm` 需要 `cons` #3：它的索引正是 `(nil, nat → nat)`。 -/
theorem stlc_id_term_index :
    icheckAt schemaSTLC exId 2 (tmIndex stNil (stArr stNat stNat)) = true := by decide

/-- `Tm` 需要 `cons` #4：同一個項不能宣稱成另一個上下文。 -/
theorem stlc_id_term_wrong_ctx :
    icheckAt schemaSTLC exId 2 (tmIndex (stCons stNat stNil) (stArr stNat stNat)) = false := by decide

/-- `Tm` 需要 `cons` #5：`(λx:nat. x) (λx:nat. x)` 被拒（把 `Tm nil (nat→nat)` 當成 `Tm nil nat`）。 -/
theorem stlc_bad_app_rejected : icheck schemaSTLC badApp = false := by decide

/-- `Tm` 需要 `cons` #6：`((λf.f) (λx:nat. x))` 良構。 -/
theorem stlc_good_app_checks : icheck schemaSTLC goodApp = true := by decide

/-- `Tm` 需要 `cons` #7：應用結果的索引是 `(nil, nat → nat)`。 -/
theorem stlc_good_app_index :
    icheckAt schemaSTLC goodApp 2 (tmIndex stNil (stArr stNat stNat)) = true := by decide

/-- `Tm` 需要 `cons` #8：變數的索引就是「上下文 + 型別」這對。 -/
theorem stlc_var_index :
    icheckAt schemaSTLC exVar 2 (tmIndex (stCons stNat stNil) stNat) = true := by decide

/-- `Tm` 需要 `cons` #9：把 `vz` 宣稱成 `Tm nil nat` 被拒（上下文長度不對）。 -/
theorem stlc_var_wrong_index :
    icheckAt schemaSTLC exVar 2 (tmIndex stNil stNat) = false := by decide

end KtLaws.IIT
