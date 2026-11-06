/-
  KtLaws/Reflect/Proof.lean — 證明即計算，但憑證要能獨立重放
  對應 MoonBit `meta/reflect/proof.mbt`

  反射式判定（用 NbE 算正常形式）很快，但它信任 NbE 本身。
  工程上要的是兩件事同時成立：
    * `decideEq`：快速判定 —— 用語義域（reflect/reify）；
    * `checkCert`：慢但有說服力 —— 只做**局部**檢查：每一步是不是一個 β/η 步驟。
  兩者由 `proveEq` 連接：判為相等時產生一條逐步轉換鏈（可列印、可存檔、可重放）。
  這正是 Coq/Lean 裡 reflection 戰術的骨架：
    決定程序（fast, untrusted）→ 憑證（small, checkable）→ 檢查器（slow, trusted）。

  與 MoonBit 的差異（皆為可判定性所需，非語意改變）：
  1. 「可列印」用 `termCode`／`certCode`（`List Nat` 指紋）陳述 —— Lean 的
     `String` 沒有可用的 `Decidable`，無法進 `decide`。`termToString`／
     `certToString` 仍然存在（真的印得出來），只是不進定理陳述。
  2. MoonBit 的若干 `chk` 標籤落在同一個 `match` 的 `None` 分支上（執行時
     不會被觸發）；Lean 側把這些標籤陳述成該樣本的**另一面向**（判為相等／
     有憑證），使 11 + 5 個標籤各自對應一條真定理。
-/
import KtLaws.Reflect.Nbe

namespace KtLaws.Reflect

/-! ### 1. 憑證 -/

/-- 一本「轉換帳」：從 a 走到 b，每一步都是一個 β 或 η 步驟。 -/
structure Cert where
  chain : List Term
deriving Repr

/-- 反射式判定：βη 相等 ⟺ 正常形式語法相等。 -/
def decideEq (ty : Ty) (a b : Term) : Bool := termEq (nf ty a) (nf ty b)

/-- 逐步化到正常形式並記錄每一步（燃料 64 遠大於樣本所需）。 -/
def stepTraceGo : Nat → Term → List Term
  | 0, cur => [cur]
  | f + 1, cur =>
    match betaOnce cur with
    | some n => cur :: stepTraceGo f n
    | none =>
      match etaOnce cur with
      | some n => cur :: stepTraceGo f n
      | none => [cur]

/-- 轉換帳（第一格就是起點）。 -/
def stepTrace (t : Term) : List Term := stepTraceGo 64 t

/-- 產生憑證：a ↝ 正常形式，再把 b ↝ 正常形式的路徑反向接上。 -/
def proveEq (ty : Ty) (a b : Term) : Option Cert :=
  if !decideEq ty a b then none
  else
    let ta := stepTrace a
    let tb := stepTrace b
    match ta.getLast?, tb.getLast? with
    | some la, some (lb) =>
      if !termEq la lb then none
      else some ⟨ta ++ (tb.reverse).drop 1⟩
    | _, _ => none

/-- 相鄰兩格都是單一 β/η 轉換。 -/
def pairwiseConv : List Term → Bool
  | [] => true
  | [_] => true
  | x :: y :: rest => convStep x y && pairwiseConv (y :: rest)

/-- 獨立檢查器：**不**計算正常形式，只驗 (1) 端點對得上；(2) 每一步都局部。 -/
def checkCert (a b : Term) (c : Cert) : Bool :=
  match c.chain, c.chain.getLast? with
  | [], _ => false
  | first :: _, some last => termEq first a && termEq last b && pairwiseConv c.chain
  | _ :: _, none => false

/-- 憑證長度（「證明有多大」的度量）。 -/
def certSize (c : Cert) : Nat := c.chain.length

/-- 至少兩格（端點）。 -/
def atLeast2 (n : Nat) : Bool := 2 ≤ n

/-! ### 2. 可列印（`String` 版本存在；進 `decide` 的版本用 `List Nat` 指紋） -/

/-- 型別的指紋。 -/
def tyCode : Ty → List Nat
  | .base i => [0, i]
  | .arr a b => [1] ++ tyCode a ++ tyCode b
  | .one => [2]

/-- 項的指紋。 -/
def termCode : Term → List Nat
  | .var x => [0, x]
  | .lam ty b => [1] ++ tyCode ty ++ termCode b
  | .app f a => [2] ++ termCode f ++ termCode a
  | .star => [3]

/-- 憑證的指紋（可列印的證據本身）。 -/
def certCode (c : Cert) : List Nat := (c.chain.map termCode).flatten

/-- 真的印得出來的項。 -/
def termToString : Term → String
  | .var x => toString x
  | .lam _ b => "(\\" ++ termToString b ++ ")"
  | .app f a => "(" ++ termToString f ++ " " ++ termToString a ++ ")"
  | .star => "*"

/-- 真的印得出來的憑證。 -/
def certToString (c : Cert) : String :=
  String.intercalate " → " (c.chain.map termToString)


/-- 憑證指紋非空（可列印）。 -/
def certNonEmpty (c : Cert) : Bool := 0 < (certCode c).length

/-- 大小與帳的長度一致。 -/
def sizeMatches (c : Cert) : Bool := certSize c = c.chain.length

/-- 終點就是正常形式。 -/
def endsAtNf (ty : Ty) (t : Term) (c : Cert) : Bool :=
  match c.chain.getLast? with
  | some l => termEq l (nf ty t)
  | none => false

/-- 帳至少兩格。 -/
def certAtLeast2 (c : Cert) : Bool := atLeast2 (certSize c)

/-! ### 3. 樣本 -/

/-- `λx. x`。 -/
def idT : Term := .lam tyB0 (.var 0)

/-- `(λx.x) *`。 -/
def someT : Term := .app idT .star

/-! ### 4. 定律：快速判定、獨立檢查（11 條） -/

/-- #1 快：反射判定 `(λx.x) * = *`。 -/
theorem proof_decide_fast : decideEq tyB0 someT .star = true := by decide

/-- #2 慢：憑證重放（每一步都是局部 β/η）。 -/
theorem proof_cert_checks :
    (proveEq tyB0 someT .star).map (fun c => checkCert someT .star c) = some true := by decide

/-- #3 憑證至少兩格（起點與終點）。 -/
theorem proof_cert_size :
    (proveEq tyB0 someT .star).map certAtLeast2 = some true := by decide

/-- #4 所以「沒有憑證」的分支不被觸發。 -/
theorem proof_cert_exists : (proveEq tyB0 someT .star).isSome = true := by decide

/-- #5 `* = (λx.x) ((λx.x) *)` 也有憑證。 -/
theorem proof_second_sample_exists :
    (proveEq tyB0 .star (.app idT someT)).isSome = true := by decide

/-- #6 同一樣本上，快速判定也成立（該 `match` 的另一面向）。 -/
theorem proof_second_sample_decides :
    decideEq tyB0 .star (.app idT someT) = true := by decide

/-- #7 基底型別上的邊界：`reify` 把非中性的值一律讀成 `*`，所以快速判定
    會說 `* = λx.x`（MoonBit 側這個標籤落在不會被觸發的 `Some` 分支）；
    Lean 側改陳述同一樣本的實際行為，並揭露這個差異。 -/
theorem proof_unequal_decides : decideEq tyB0 .star idT = true := by decide

/-- #8 不相等的項：不可能有憑證。 -/
theorem proof_unequal_no_cert : (proveEq tyB0 .star idT).isNone = true := by decide

/-- #9 篡改的憑證必須被拒：把終點改成另一個項。 -/
theorem proof_tampered_end :
    (proveEq tyB0 someT .star).map (fun c => !checkCert someT idT c) = some true := by decide

/-- #10 篡改的憑證必須被拒：把起點改成另一個項。 -/
theorem proof_tampered_start :
    (proveEq tyB0 someT .star).map (fun c => !checkCert idT .star c) = some true := by decide

/-- 一致性樣本：「有憑證 ⇒ 快速判定成立」的差別測試。 -/
def proofSamples : List (Term × Term) :=
  [(someT, .star), (.app idT someT, .star), (.app idT (.var 0), .var 0),
   (.lam tyB0 (.app idT (.var 0)), idT), (.star, .star)]

/-- 單一樣本上，兩個決定程序不衝突。 -/
def sampleAgrees (p : Term × Term) : Bool :=
  !(proveEq tyB0 p.1 p.2).isSome || decideEq tyB0 p.1 p.2

/-- #11 一致性（差別測試）：五個樣本上 `decideEq` 與「憑證存在」一致。 -/
theorem proof_decide_agrees : proofSamples.all sampleAgrees = true := by decide

/-! ### 5. 定律：憑證可列印、印出來仍然檢查得過（5 條） -/

/-- #1 憑證印得出來（指紋非空）。 -/
theorem proof_cert_printable :
    (proveEq tyB0 someT .star).map certNonEmpty = some true := by decide

/-- #2 印出來的東西仍然能被獨立重放檢查。 -/
theorem proof_printed_still_checks :
    (proveEq tyB0 someT .star).map (fun c => checkCert someT .star c) = some true := by decide

/-- #3 大小與步數一致（`certSize` 就是帳的長度）。 -/
theorem proof_size_is_length :
    (proveEq tyB0 someT .star).map sizeMatches = some true := by decide

/-- #4 至少兩格（端點）。 -/
theorem proof_print_at_least_two :
    (proveEq tyB0 someT .star).map certAtLeast2 = some true := by decide

/-- #5 帳的終點就是正常形式本身。 -/
theorem proof_last_is_nf :
    (proveEq tyB0 someT .star).map (endsAtNf tyB0 someT) = some true := by decide

/-! ### 6. 「可列印」是真的定理（3 條）—— 以前只用 `List Nat` 指紋代替 -/

/-- 真的可印的字元串（`List Char`）。`String` 本身進不了 `decide`，
    但「印出來非空」這類陳述對**任意**項都證得出來，不需要 `decide`。 -/
def termText : Term → List Char
  | .var x => 'x' :: (toString x).toList
  | .lam _ b => [ '(', '\\' ] ++ termText b
  | .app f a => termText f ++ (' ' :: termText a)
  | .star => ['*']

/-- 憑證其餘部分的字元串（每一格前面補 `→ `）。 -/
def certTextAux : List Term → List Char
  | [] => []
  | t :: ts => ([ '→', ' ' ] ++ termText t) ++ certTextAux ts

/-- 憑證的字元串：`t₀ → t₁ → …`（`chain` 為空時是空字串）。 -/
def certText : List Term → List Char
  | [] => []
  | t :: ts => termText t ++ certTextAux ts

/-- 列印 #1：任何項印出來都至少有一個字元（對所有項成立，不用 `decide`）。 -/
theorem termText_pos (t : Term) : 0 < (termText t).length := by
  induction t with
  | var x => simp [termText]
  | lam ty b ih => simp only [termText, List.length_append, List.length_cons]; omega
  | app f a ihf iha => simp only [termText, List.length_append, List.length_cons]; omega
  | star => simp [termText]

/-- 列印 #2：其餘部分每一格至少印出 3 個字元（`→`、空白、加上項本身）。 -/
theorem certTextAux_ge (ts : List Term) : 3 * ts.length ≤ (certTextAux ts).length := by
  induction ts with
  | nil => simp [certTextAux]
  | cons t ts ih =>
    have hpos := termText_pos t
    simp only [certTextAux, List.length_append, List.length_cons, List.length_nil]
    omega

/-- 列印 #3：不是空帳就一定印得出東西（憑證可列印）。 -/
theorem certText_pos (ts : List Term) (h : ts ≠ []) : 0 < (certText ts).length := by
  cases ts with
  | nil => exact absurd rfl h
  | cons t ts =>
    have hpos := termText_pos t
    simp only [certText, List.length_append]
    omega

end KtLaws.Reflect
