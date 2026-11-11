/-
  KtLaws/Reflect/NfNormal.lean — O1 第一半邊：NbE 輸出是 β-正常的（結構定理）

  WHY.md §3 的 O1 陳述是：
      `check Γ t A = true → isBetaNormal (nf A t) = true`，外加冪等 `nf (nf t) = nf t`。

  本檔完成第一半邊，而且把它證得**更強**：`reifyN`／`reifyNeuN` 對任何燃料、
  任何型別、任何語義值都產生 β-正常的項（不需要型別前提）。
  冪等半邊（`nf (nf t) = nf t`）需要 eval/reify 的 soundness
  （βη 可轉換 ⇒ `nf` 相同），這是 logical relation（reducibility）的工作，
  目前仍未完成——見 Dev.txt／WHY.md 的 O1 記錄。

  技術要點：β-redex 的特徵是「頭位置是 `lam`」，所以定義 `isLamHead`；
  `reifyN` 產生的所有應用，頭都由 `reifyNeuN` 產生（`.var` 或 `.app` 鏈），
  因此不是 `lam`。對燃料做同時（mutual）歸納一次證完。
-/
import KtLaws.Reflect.Nbe

namespace KtLaws.Reflect

/-! ### 1. β-正常與 lam 頭 -/

/-- 頭位置是否為 `lam`（β-redex 的判定核心）。 -/
def isLamHead : Term → Bool
  | .lam _ _ => true
  | .app f _ => isLamHead f
  | _ => false

/-- β-正常：任何子項都不是 `(λ …) a` 形式。 -/
def isBetaNormal : Term → Bool
  | .var _ => true
  | .star => true
  | .lam _ b => isBetaNormal b
  | .app f a => !isLamHead f && isBetaNormal f && isBetaNormal a

theorem isBetaNormal_app (f a : Term) :
    isBetaNormal (.app f a) = (!isLamHead f && isBetaNormal f && isBetaNormal a) := rfl

theorem isBetaNormal_lam (ty : Ty) (b : Term) : isBetaNormal (.lam ty b) = isBetaNormal b := rfl

theorem isLamHead_app (f a : Term) : isLamHead (.app f a) = isLamHead f := rfl

/-! ### 2. 結構定理：reify 永遠產生 β-正常項 -/

/-- 關鍵引理（對燃料的同時歸納）：
    (a) `reifyN` 的輸出恆 β-正常；
    (b) `reifyNeuN` 的輸出恆 β-正常，且頭不為 `lam`。 -/
theorem reifyN_isBetaNormal : ∀ (f : Nat),
    (∀ (ty : Ty) (lvl : Nat) (v : Val), isBetaNormal (reifyN f ty lvl v) = true) ∧
    (∀ (lvl : Nat) (v : Val),
        isBetaNormal (reifyNeuN f lvl v) = true ∧ isLamHead (reifyNeuN f lvl v) = false) := by
  intro f
  induction f with
  | zero =>
    refine ⟨?_, ?_⟩
    · intro ty lvl v; cases ty <;> rfl
    · intro lvl v; exact ⟨rfl, rfl⟩
  | succ n ih =>
    obtain ⟨ihN, ihNeu⟩ := ih
    refine ⟨?_, ?_⟩
    · intro ty lvl v
      cases ty with
      | base i =>
        exact (ihNeu lvl v).1
      | one =>
        rfl
      | arr a b =>
        show isBetaNormal (.lam a (reifyN n b (lvl + 1) (applyAtN n a v (.neu lvl)))) = true
        exact ihN b (lvl + 1) (applyAtN n a v (.neu lvl))
    · intro lvl v
      cases v with
      | neu x =>
        exact ⟨rfl, rfl⟩
      | vapp g a dom =>
        have hgn := ihNeu lvl g
        have han := ihN dom lvl a
        show (isBetaNormal (.app (reifyNeuN n lvl g) (reifyN n dom lvl a)) = true
              ∧ isLamHead (.app (reifyNeuN n lvl g) (reifyN n dom lvl a)) = false)
        constructor
        · rw [isBetaNormal_app, hgn.2, hgn.1, han]
          rfl
        · rw [isLamHead_app, hgn.2]
      | vclos ty' body env =>
        exact ⟨rfl, rfl⟩
      | vneu ty' l v' =>
        exact ⟨rfl, rfl⟩
      | vstar =>
        exact ⟨rfl, rfl⟩

/-- 換成 `nf` 實際用的燃料：`nf` 的輸出恆 β-正常（不需要型別前提）。 -/
theorem nf_isBetaNormal (A : Ty) (t : Term) : isBetaNormal (nf A t) = true :=
  (reifyN_isBetaNormal evalFuel).1 A 0 (evalN evalFuel [] t)

/-- **O1 第一半邊**：Well-typed 項經 NbE 正規化後是 β-正常的。
    （證明強於陳述——不需要 `check Γ t A = true`；保留參數只為了對應 O1 的原始陳述形狀。） -/
theorem nf_beta_normal (Γ : List Ty) (t : Term) (A : Ty) (_h : check Γ t A = true) :
    isBetaNormal (nf A t) = true :=
  nf_isBetaNormal A t

/-! ### 3. 樣本：具體項的 β-正常性由 kernel 判定 -/

/-- `(λx. x) *` 的正規化結果是 β-正常的。 -/
theorem nf_beta_normal_sample_star : isBetaNormal (nf tyB0 (.app termId .star)) = true := by
  decide

/-- `λx. x` 的正規化結果是 β-正常的。 -/
theorem nf_beta_normal_sample_lam : isBetaNormal (nf tyArr termId) = true := by
  decide

end KtLaws.Reflect
