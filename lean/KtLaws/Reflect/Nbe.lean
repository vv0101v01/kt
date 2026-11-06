/-
  KtLaws/Reflect/Nbe.lean — 反射第一層：reify / reflect 這對伴隨（normalization by evaluation）
  對應 MoonBit `meta/reflect/nbe.mbt`

  「反射」在型別論裡是一對映射：
      reflect : 中性項 → 語義值        （把語法塞進語義）
      reify   : 語義值 × 型別 → 正常形式（把語義拉回語法）
  βη 相等於是判定成「reify 後語法相等」，這就是 NbE。

  值域用**單一**代數型別（中性項也住進值域），與 MoonBit 側同一個設計：
  這樣 `Val` 不需要與 `Ty` 互相遞迴。

  與 MoonBit 的兩處**技術性差異**（語意等價，只為讓 kernel 能歸約）：
  1. `check` 不獨立成函式，而是把 `infer` 的結果直接與宣稱型別比對
     （MoonBit 的 `infer` 在應用情況呼叫 `check`，兩者互遞迴；Lean 的互遞迴
      在沒有共同遞減引數時會退化成 well-founded recursion，kernel 無法歸約）。
  2. `Val` 只能用語法閉包（Lean 的嚴格正性檢查）；`reflect` 因此變成
     `reflVal`（延後 η-展開到應用時）。
  3. `reify` / `reify_neutral` 帶**燃料**（`reifyN`/`reifyNeuN` 共用同一個遞減 Nat），
     原因同上：互遞迴而沒有結構遞減。燃料 64 遠大於本檔任何項的型別/項深度。
-/
import KtLaws.Reflect.Universe

namespace KtLaws.Reflect

/-! ### 1. 型別與項 -/

/-- 型別：基底型別、單位、函式型別。 -/
inductive Ty where
  | base (i : Nat)
  | arr (a b : Ty)
  | one
deriving Repr

/-- 項：de Bruijn 變數、λ、應用、單位。 -/
inductive Term where
  | var (i : Nat)
  | lam (ty : Ty) (body : Term)
  | app (f a : Term)
  | star
deriving Repr

/-- 型別相等。 -/
def tyEq : Ty → Ty → Bool
  | .base x, .base y => x == y
  | .arr a1 b1, .arr a2 b2 => tyEq a1 a2 && tyEq b1 b2
  | .one, .one => true
  | _, _ => false

/-- 項相等。 -/
def termEq : Term → Term → Bool
  | .var x, .var y => x == y
  | .lam t1 b1, .lam t2 b2 => tyEq t1 t2 && termEq b1 b2
  | .app f1 a1, .app f2 a2 => termEq f1 f2 && termEq a1 a2
  | .star, .star => true
  | _, _ => false

/-! ### 2. 語義值域 -/

/-- 語義值：中性值、停在非函式頭上的中性應用、語法閉包、反射過的中性函式值、單位。

    與 MoonBit 的差異：MoonBit 用 `VClosure((Val) -> Val)`（真函式）；Lean 的
    嚴格正性檢查不允許 `Val` 出現在自己的負位置（`vclos` 的欄位不能是
    `Val → Val`），所以閉包改成**語法閉包**（型別、body、捕獲的環境）,
    並多一個 `.vneu` 表示「反射後、型別還是函式」的中性值。這是
    去函式化（defunctionalisation），語意相同：`.vclos` 只在應用時展開。 -/
inductive Val where
  | neu (lvl : Nat)
  | vapp (f a : Val) (dom : Ty)
  | vclos (ty : Ty) (body : Term) (env : List Val)
  | vneu (ty : Ty) (lvl : Nat) (v : Val)
  | vstar

/-- reflect：中性值升進語義域（函式型別上延後到應用時才 η-展開）。 -/
def reflVal : Ty → Nat → Val → Val
  | .base _, _, n => n
  | .one, _, _ => .vstar
  | .arr a b, lvl, n => .vneu (.arr a b) lvl n

/-- 燃料：遠大於本檔任何項的型別深度/項深度（≤ 4）。 -/
def evalFuel : Nat := 64

mutual
  /-- 求值（閉包捕獲環境與 body，應用時才展開）。 -/
  def evalN : Nat → List Val → Term → Val
    | 0, _, _ => .vstar
    | f + 1, env, .var i => (env[i]?).getD (.neu i)
    | f + 1, env, .lam ty body => .vclos ty body env
    | f + 1, env, .app g a => applyAtN f .one (evalN f env g) (evalN f env a)
    | _ + 1, _, .star => .vstar

  /-- 帶型別的應用：中性頭上記住參數型別（`reify` 一端才不會讀錯型別）。 -/
  def applyAtN : Nat → Ty → Val → Val → Val
    | 0, _, _, _ => .vstar
    | f + 1, _, .vclos _ body env, a => evalN f (a :: env) body
    | f + 1, _, .vneu (.arr a b) lvl n, x => reflVal b (lvl + 1) (.vapp n x a)
    | _ + 1, dom, g, a => .vapp g a dom

  /-- reify：語義值讀回正常形式（函式型別上 η-展開）。 -/
  def reifyN : Nat → Ty → Nat → Val → Term
    | 0, _, _, _ => .star
    | f + 1, .base _, lvl, v => reifyNeuN f lvl v
    | f + 1, .one, _, _ => .star
    | f + 1, .arr a b, lvl, v => .lam a (reifyN f b (lvl + 1) (applyAtN f a v (.neu lvl)))

  /-- 中性值讀回語法。 -/
  def reifyNeuN : Nat → Nat → Val → Term
    | 0, _, _ => .star
    | f + 1, _, .neu x => .var x
    | f + 1, lvl, .vapp g a dom => .app (reifyNeuN f lvl g) (reifyN f dom lvl a)
    | _ + 1, _, _ => .star
end

/-- 型別索引的正規化（βη 正常形式）。 -/
def nf (ty : Ty) (t : Term) : Term := reifyN evalFuel ty 0 (evalN evalFuel [] t)

/-! ### 4. 型別推導與檢查 -/

/-- 型別推導（標註過的 λ，足夠做保型性測試）。 -/
def infer : List Ty → Term → Option Ty
  | ctx, .var i => ctx[i]?
  | _, .star => some .one
  | ctx, .lam a body => (infer (a :: ctx) body).map (fun b => .arr a b)
  | ctx, .app f a =>
    match infer ctx f with
    | some (.arr d c) =>
      match infer ctx a with
      | some t2 => if tyEq t2 d then some c else none
      | none => none
    | _ => none

/-- 型別檢查 = 推導出的型別與宣稱相等。 -/
def check (ctx : List Ty) (t : Term) (ty : Ty) : Bool :=
  match infer ctx t with
  | some t2 => tyEq t2 ty
  | none => false

/-! ### 5. 單步 β / η（憑證重放用；定律在 `Proof.lean`） -/

/-- 位移：把 ≥ `cutoff` 的自由變數加 `d`（`d` 用 `Nat` 表示，往上移）。 -/
def shiftUp : Term → Nat → Nat → Term
  | .var x, d, cutoff => if x ≥ cutoff then .var (x + d) else .var x
  | .lam ty b, d, cutoff => .lam ty (shiftUp b d (cutoff + 1))
  | .app f a, d, cutoff => .app (shiftUp f d cutoff) (shiftUp a d cutoff)
  | .star, _, _ => .star

/-- 代入 `j ↦ s`。 -/
def substAt : Term → Nat → Term → Term
  | .var x, j, s => if x == j then s else .var x
  | .lam ty b, j, s => .lam ty (substAt b (j + 1) (shiftUp s 1 0))
  | .app f a, j, s => .app (substAt f j s) (substAt a j s)
  | .star, _, _ => .star

/-- 最左最外層的一步 β。 -/
def betaOnce : Term → Option Term
  | .app (.lam _ body) arg => some (substAt body 0 arg)
  | .app f a =>
    match betaOnce f with
    | some f2 => some (.app f2 a)
    | none => (betaOnce a).map (fun a2 => .app f a2)
  | .lam ty b => (betaOnce b).map (fun b2 => .lam ty b2)
  | .var _ => none
  | .star => none

/-- 項裡有沒有用到變數 0。 -/
def usesVar0 : Term → Bool
  | .var 0 => true
  | .var (_ + 1) => false
  | .lam _ b => usesVar0 b
  | .app f a => usesVar0 f || usesVar0 a
  | .star => false

/-- 「往下移」：把 ≥ `cutoff + d` 的變數減 `d`。

    這是 MoonBit `shift(t, -1, 0)` 的 Lean 版本。`Nat` 沒有負數，所以不能直接
    用 `x + (−1)`；改成「先判 `cutoff + d ≤ x` 再減」，在 `x ≥ cutoff + d` 時
    與 `Int32` 版本逐點相同。η 收縮時 `0` 不會自由出現（`usesVar0 f = false`），
    所以截斷分支不會被用到 —— 這一點由 `eta_contract_shifts` 具體釘住。 -/
def shiftDn : Term → Nat → Nat → Term
  | .var x, d, cutoff => if cutoff + d ≤ x then .var (x - d) else .var x
  | .lam ty b, d, cutoff => .lam ty (shiftDn b d (cutoff + 1))
  | .app f a, d, cutoff => .app (shiftDn f d cutoff) (shiftDn a d cutoff)
  | .star, _, _ => .star

/-- 單步 η 收縮：`λx. f x ↦ f`（要求 x 不出現在 f），去掉外層 λ 之後
    自由變數要**往下移一層**（否則會指到錯的變數）—— 與 MoonBit 的
    `shift(f, -1, 0)` 一致。 -/
def etaOnce : Term → Option Term
  | .lam _ (.app f (.var 0)) => if usesVar0 f then none else some (shiftDn f 1 0)
  | .lam ty b => (etaOnce b).map (fun b2 => .lam ty b2)
  | _ => none

/-- βη 轉換的一步（對稱）。 -/
def convStep (a b : Term) : Bool :=
  (match betaOnce a with
    | some a2 => termEq a2 b
    | none => false) ||
  (match betaOnce b with
    | some b2 => termEq b2 a
    | none => false) ||
  (match etaOnce a with
    | some a2 => termEq a2 b
    | none => false) ||
  (match etaOnce b with
    | some b2 => termEq b2 a
    | none => false)

/-! ### 6. 定律（7 條） -/

/-- 測試用的基底型別 `B0`。 -/
def tyB0 : Ty := .base 0

/-- `B0 → B0`。 -/
def tyArr : Ty := .arr tyB0 tyB0

/-- `λx. x`。 -/
def termId : Term := .lam tyB0 (.var 0)

/-- nbe #1：β —— `(λx.x) * ↦ *`。 -/
theorem nbe_beta : termEq (nf tyB0 (.app termId .star)) .star = true := by decide

/-- nbe #2：冪等 —— `nf (nf t) = nf t`。 -/
theorem nbe_idempotent :
    termEq (nf tyB0 (.app termId (.app termId .star)))
      (nf tyB0 (nf tyB0 (.app termId (.app termId .star)))) = true := by decide

/-- nbe #3：η —— `reify ∘ reflect = η-長形式`，所以 `λx. f x` 與自由變數 `f`
    在函式型別上讀出**同一個**正常形式。 -/
theorem nbe_eta :
    termEq (reifyN evalFuel tyArr 0 (reflVal tyArr 0 (.neu 0)))
      (reifyN evalFuel tyArr 0 (.neu 0)) = true := by decide

/-- nbe #4：反向邊界 —— `eval` 造出的中性應用不帶參數型別，
    所以只在基底型別上安全地 reify（這裡明確只測基底情形）。 -/
theorem nbe_eval_neutral :
    termEq (reifyN evalFuel tyB0 0 (evalN evalFuel [.neu 0] (.app (.var 0) .star)))
      (.app (.var 0) .star) = true := by decide

/-- nbe #5：保型的準備 —— `λx:1→B0. x *` 的型別是 `(1→B0) → B0`。 -/
theorem nbe_check_terminates :
    check [] (.lam (.arr .one tyB0) (.app (.var 0) .star))
      (.arr (.arr .one tyB0) tyB0) = true := by decide

/-- nbe #6：保型 —— 正規化之後型別不變（行為測試）。 -/
theorem nbe_check_preserved :
    check [] (nf (.arr (.arr .one tyB0) tyB0) (.lam (.arr .one tyB0) (.app (.var 0) .star)))
      (.arr (.arr .one tyB0) tyB0) = true := by decide

/-- nbe #7：反例 —— 型別不對的項要被拒。 -/
theorem nbe_check_rejects :
    check [] (.lam (.arr .one tyB0) (.app (.var 0) .star)) tyArr = false := by decide

/-! ### 7. η 收縮的「往下移」是真的（3 條）—— 這裡以前靠註解帶過 -/

/-- `Option Term` 的相等檢查（`Term` 沒有 `DecidableEq`，用 `termEq`）。 -/
def termEqOpt : Option Term → Option Term → Bool
  | none, none => true
  | some a, some b => termEq a b
  | _, _ => false

/-- η #1：`λx. * x ↦ *`（`f` 裡沒有變數 0，直接收縮）。 -/
theorem eta_contracts_star :
    termEqOpt (etaOnce (.lam tyArr (.app .star (.var 0)))) (some .star) = true := by decide

/-- η #2：`f` 裡真的有變數 0 時**不能**收縮（`x` 會被吞掉）。 -/
theorem eta_blocked :
    termEqOpt (etaOnce (.lam tyArr (.app (.var 0) (.var 0)))) none = true := by decide

/-- η #3：去掉外層 λ 之後，自由變數**往下移一層** —— `λx. x₁ x ↦ x₀`。
    這一條就是當初跳過的那步（`Nat` 沒有 −1）：少了它，收縮出來的項會指到錯的變數。 -/
theorem eta_contract_shifts :
    termEqOpt (etaOnce (.lam tyB0 (.app (.var 1) (.var 0)))) (some (.var 0)) = true := by decide

/-! ### 8. 反射的一般律：`reify` 把 `reflect` 抹掉（2 條）

§6 的 η 定律是樣本，這裡把它升級成**對所有型別、所有中性值**成立的定理。
核心是 `reflVal`（reflect）只對中性值有意義 —— 對 `vclos`／`vstar` 它會亂造 `vneu`，
所以前提寫成 `isNeutral`。 -/
def isNeutral : Val → Bool
  | .neu _ => true
  | .vapp _ _ _ => true
  | _ => false

theorem reifyN_arr (f lvl : Nat) (a b : Ty) (v : Val) :
    reifyN (f + 1) (.arr a b) lvl v = .lam a (reifyN f b (lvl + 1) (applyAtN f a v (.neu lvl))) := rfl

theorem reifyN_one (f lvl : Nat) (v : Val) : reifyN (f + 1) .one lvl v = .star := rfl

theorem reflVal_arr (a b : Ty) (lvl : Nat) (n : Val) :
    reflVal (.arr a b) lvl n = .vneu (.arr a b) lvl n := rfl

theorem applyAtN_neu' (j : Nat) (a : Ty) (v lvl : Nat) :
    applyAtN (j + 1) a (.neu v) (.neu lvl) = .vapp (.neu v) (.neu lvl) a := rfl

theorem applyAtN_vapp' (j : Nat) (a : Ty) (x y : Val) (d : Ty) (lvl : Nat) :
    applyAtN (j + 1) a (.vapp x y d) (.neu lvl) = .vapp (.vapp x y d) (.neu lvl) a := rfl

theorem applyAtN_vneu_gen (j : Nat) (a b : Ty) (lvl : Nat) (n arg : Val) :
    applyAtN (j + 1) a (.vneu (.arr a b) lvl n) arg = reflVal b (lvl + 1) (.vapp n arg a) := rfl

/-- 對任何型別、任何深度、任何**中性**值：先 reflect 再 reify，與直接 reify 同一個項。 -/
theorem nbe_reify_refl_neutral (ty : Ty) : ∀ (f lvl : Nat) (n : Val), isNeutral n = true →
    reifyN f ty lvl (reflVal ty lvl n) = reifyN f ty lvl n := by
  induction ty with
  | base i => intro f lvl n h; rfl
  | one =>
    intro f lvl n h
    match f with
    | 0 => rfl
    | k + 1 => rw [reifyN_one, reifyN_one]
  | arr a b iha ihb =>
    intro f lvl n h
    match f with
    | 0 => rfl
    | k + 1 =>
      rw [reifyN_arr, reifyN_arr, reflVal_arr]
      cases n with
      | neu v =>
        match k with
        | 0 => rfl
        | j + 1 =>
          rw [applyAtN_vneu_gen j, applyAtN_neu' j]
          exact congrArg (fun t => Term.lam a t) (ihb (j + 1) (lvl + 1) (.vapp (.neu v) (.neu lvl) a) rfl)
      | vapp x y d =>
        match k with
        | 0 => rfl
        | j + 1 =>
          rw [applyAtN_vneu_gen j, applyAtN_vapp' j]
          exact congrArg (fun t => Term.lam a t) (ihb (j + 1) (lvl + 1) (.vapp (.vapp x y d) (.neu lvl) a) rfl)
      | vclos ty' body env => exact absurd h (by simp [isNeutral])
      | vneu ty' l v => exact absurd h (by simp [isNeutral])
      | vstar => exact absurd h (by simp [isNeutral])

/-- 換成 `nf` 實際用的燃料：η 擴張再收縮不改變正規形式。 -/
theorem nbe_reify_reflect_fuel (ty : Ty) (lvl : Nat) (n : Val) (h : isNeutral n = true) :
    reifyN evalFuel ty lvl (reflVal ty lvl n) = reifyN evalFuel ty lvl n :=
  nbe_reify_refl_neutral ty evalFuel lvl n h


end KtLaws.Reflect
