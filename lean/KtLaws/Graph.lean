/-
  KtLaws/Graph.lean  —  有限的圖論計數基礎（不依賴 Mathlib）

  這裡放的是「上界」型 Ramsey 定理真正需要的工具：

  1. 清單抽取：長度至少 `k` ⇒ 抽得出 `k` 個互異的見證（`exists_subset_len`）。
  2. 求和工具：`sum_map_add`、`sum_map_congr`、指標和 = 計數（`sum_indicator`）、
     常數和的 `length * c`（`sum_map_const`）。
  3. **握手引理**（`handshake`）：`Σ_v deg v = 2 × 邊數`，
     這是 `R(3,4) ≤ 9` 的奇偶矛盾（27 是奇數）唯一需要的「全域」事實。
-/

set_option maxRecDepth 100000

namespace KtLaws.Graph

/-! ### 清單的基本事實 -/

theorem nodup_filter {α : Type} (p : α → Bool) : ∀ {l : List α}, l.Nodup → (l.filter p).Nodup
  | [], _ => List.nodup_nil
  | a :: rest, hl => by
    obtain ⟨hna, hnd⟩ := List.nodup_cons.mp hl
    by_cases hpa : p a = true
    · rw [List.filter_cons_of_pos hpa]
      exact List.nodup_cons.mpr
        ⟨fun hc => hna ((List.mem_filter.mp hc).1), nodup_filter p hnd⟩
    · rw [List.filter_cons_of_neg hpa]
      exact nodup_filter p hnd

/-- 清單長度至少 `k` 時，可抽出 `k` 個互異元素組成的子清單。 -/
theorem exists_subset_len {α : Type} (vs : List α) (k : Nat) (hnd : vs.Nodup)
    (h : k ≤ vs.length) : ∃ ws : List α, ws.length = k ∧ ws.Nodup ∧ ∀ x ∈ ws, x ∈ vs := by
  induction vs generalizing k with
  | nil =>
    simp at h
    subst h
    exact ⟨[], rfl, List.nodup_nil, by simp⟩
  | cons a rest ih =>
    obtain ⟨hna, hnd'⟩ := List.nodup_cons.mp hnd
    simp only [List.length_cons] at h
    cases k with
    | zero => exact ⟨[], rfl, List.nodup_nil, by simp⟩
    | succ k' =>
      obtain ⟨ws, hlen, hndw, hmem⟩ := ih k' hnd' (by omega)
      refine ⟨a :: ws, by simp [hlen], ?_, ?_⟩
      · exact List.nodup_cons.mpr ⟨fun hc => hna (hmem a hc), hndw⟩
      · intro x hx
        rcases List.mem_cons.mp hx with h | h
        · subst h; exact List.mem_cons_self ..
        · exact List.mem_cons_of_mem a (hmem x h)

theorem eq_pair_of_len {α : Type} : ∀ (vs : List α), vs.length = 2 → ∃ a b, vs = [a, b]
  | [], h => by simp at h
  | [_], h => by simp at h
  | [a, b], _ => ⟨a, b, rfl⟩
  | _ :: _ :: _ :: _, h => by simp at h

theorem eq_quad_of_len {α : Type} : ∀ (vs : List α), vs.length = 4 → ∃ a b c d, vs = [a, b, c, d]
  | [], h => by simp at h
  | [_], h => by simp at h
  | [_, _], h => by simp at h
  | [_, _, _], h => by simp at h
  | [a, b, c, d], _ => ⟨a, b, c, d, rfl⟩
  | _ :: _ :: _ :: _ :: _ :: _, h => by simp at h

theorem eq_six_of_len {α : Type} : ∀ (vs : List α), vs.length = 6 → ∃ a b c d e g, vs = [a, b, c, d, e, g]
  | [], h => by simp at h
  | [_], h => by simp at h
  | [_, _], h => by simp at h
  | [_, _, _], h => by simp at h
  | [_, _, _, _], h => by simp at h
  | [_, _, _, _, _], h => by simp at h
  | [a, b, c, d, e, g], _ => ⟨a, b, c, d, e, g, rfl⟩
  | _ :: _ :: _ :: _ :: _ :: _ :: _ :: _, h => by simp at h

/-! ### 求和 -/

theorem sum_map_add {α : Type} (l : List α) (f g : α → Nat) :
    (l.map (fun x => f x + g x)).sum = (l.map f).sum + (l.map g).sum := by
  induction l with
  | nil => simp
  | cons a rest ih => simp [ih]; omega

theorem sum_map_congr {α : Type} (l : List α) (f g : α → Nat) (h : ∀ x ∈ l, f x = g x) :
    (l.map f).sum = (l.map g).sum := by
  induction l with
  | nil => simp
  | cons a rest ih =>
    simp only [List.map_cons, List.sum_cons]
    rw [h a (List.mem_cons_self ..), ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

theorem sum_indicator {α : Type} (l : List α) (p : α → Bool) :
    (l.map (fun x => if p x = true then 1 else 0)).sum = l.countP p := by
  induction l with
  | nil => simp
  | cons a rest ih =>
    rw [List.countP_cons, List.map_cons, List.sum_cons, ih]
    omega

/-- 清單中所有元素都等於 `c` 時，和的長度倍。 -/
theorem sum_map_const {α : Type} (l : List α) (f : α → Nat) (c : Nat) (h : ∀ x ∈ l, f x = c) :
    (l.map f).sum = l.length * c := by
  induction l with
  | nil => simp
  | cons a rest ih =>
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    rw [h a (List.mem_cons_self ..), ih (fun x hx => h x (List.mem_cons_of_mem a hx)),
      Nat.add_mul, Nat.one_mul]
    omega

/-! ### 度數與握手引理 -/

/-- 頂點 `v` 到清單 `vs` 中「其他點」的 `col` 色鄰點數。 -/
def degIn {n : Nat} (c : Fin n → Fin n → Bool) (col : Bool) (vs : List (Fin n)) (v : Fin n) : Nat :=
  vs.countP (fun w => (c v w == col) && decide (w ≠ v))

/-- 清單 `vs` 內部的 `col` 色無向邊數（遞迴定義：拿掉首點，數它到其餘各點的邊）。 -/
def edgeCnt {n : Nat} (c : Fin n → Fin n → Bool) (col : Bool) : List (Fin n) → Nat
  | [] => 0
  | v :: rest => rest.countP (fun w => (c v w == col) && decide (w ≠ v)) + edgeCnt c col rest

theorem self_not_nbr {n : Nat} (c : Fin n → Fin n → Bool) (col : Bool) (v : Fin n) :
    ((c v v == col) && decide (v ≠ v)) = false := by
  simp

theorem degIn_cons {n : Nat} (c : Fin n → Fin n → Bool) (col : Bool) (vs : List (Fin n))
    (a v : Fin n) :
    degIn c col (a :: vs) v = degIn c col vs v + (if (c v a == col) && decide (a ≠ v) then 1 else 0) := by
  unfold degIn
  rw [List.countP_cons]

/-- **握手引理**：`Σ deg = 2 × 邊數`。 -/
theorem handshake {n : Nat} (c : Fin n → Fin n → Bool) (col : Bool)
    (hsymm : ∀ i j : Fin n, c i j = c j i) :
    ∀ vs : List (Fin n), vs.Nodup →
      (vs.map (fun v => degIn c col vs v)).sum = 2 * edgeCnt c col vs := by
  intro vs
  induction vs with
  | nil => intro _; simp [edgeCnt]
  | cons a rest ih =>
    intro hnd
    -- 首點的自環不算
    have hself : degIn c col (a :: rest) a = degIn c col rest a := by
      rw [degIn_cons, self_not_nbr]
      simp
    -- 其餘各點：多出「到 a 的邊」這一項
    have hrest : (rest.map (fun v => degIn c col (a :: rest) v)).sum
        = (rest.map (fun v => degIn c col rest v)).sum
          + (rest.map (fun v => if (c v a == col) && decide (a ≠ v) then 1 else 0)).sum := by
      rw [← sum_map_add]
      exact sum_map_congr rest _ _ (fun v _ => degIn_cons c col rest a v)
    -- 「到 a 的邊」逐點用對稱性換成 `a` 到 `v`
    have hsym : (rest.map (fun v => if (c v a == col) && decide (a ≠ v) then 1 else 0)).sum
        = (rest.map (fun v => if (c a v == col) && decide (v ≠ a) then 1 else 0)).sum := by
      exact sum_map_congr rest _ _ (fun v _ => by
        simp [hsymm v a, ne_comm])
    have hind : (rest.map (fun v => if (c a v == col) && decide (v ≠ a) then 1 else 0)).sum
        = rest.countP (fun w => (c a w == col) && decide (w ≠ a)) :=
      sum_indicator rest _
    have hih := ih (List.nodup_cons.mp hnd).2
    simp only [List.map_cons, List.sum_cons] at *
    rw [hself, hrest, hsym, hind, hih]
    have hec : edgeCnt c col (a :: rest)
        = rest.countP (fun w => (c a w == col) && decide (w ≠ a)) + edgeCnt c col rest := rfl
    rw [hec]
    unfold degIn
    omega


theorem filter_ne_eq_erase {α : Type} [BEq α] [LawfulBEq α] [DecidableEq α] :
    ∀ (l : List α) (v : α), l.Nodup → l.filter (fun x => decide (x ≠ v)) = l.erase v
  | [], v, _ => rfl
  | a :: rest, v, hnd => by
    obtain ⟨hna, hnd'⟩ := List.nodup_cons.mp hnd
    by_cases hav : a = v
    · subst hav
      rw [List.erase_cons_head, List.filter_cons_of_neg (by simp)]
      exact List.filter_eq_self.mpr (fun x hx => by
        have hxa : x ≠ a := fun h => hna (h ▸ hx)
        simp [hxa])
    · rw [List.filter_cons_of_pos (by simp [hav])]
      rw [List.erase_cons_tail (by simp [hav])]
      rw [filter_ne_eq_erase rest v hnd']

theorem countP_finRange_ne {n : Nat} (v : Fin n) :
    (List.finRange n).countP (fun w => decide (w ≠ v)) = n - 1 := by
  rw [List.countP_eq_length_filter, filter_ne_eq_erase _ v (List.nodup_finRange n),
    List.length_erase_of_mem (List.mem_finRange v), List.length_finRange]


/-- 兩個互斥的謂詞：計數相加。 -/
theorem countP_or {α : Type} (p q : α → Bool)
    (h : ∀ x, p x = true → q x = true → False) :
    ∀ l : List α, l.countP p + l.countP q = l.countP (fun x => p x || q x)
  | [] => by simp
  | a :: rest => by
    rw [List.countP_cons, List.countP_cons, List.countP_cons]
    have ih := countP_or p q h rest
    cases hp : p a <;> cases hq : q a <;> simp_all <;> omega


/-- 從無重複清單造出**單射**的索引函式（用 `idxOf` 取回索引）。 -/
theorem mkfun {α : Type} (ws : List α) (hnd : ws.Nodup) [BEq α] [LawfulBEq α]
    (k : Nat) (hlen : ws.length = k) :
    ∃ w : Fin k → α, (∀ i, w i ∈ ws) ∧ (∀ i j, w i = w j → i = j) := by
  refine ⟨fun i => ws[i.val]'(by omega), ?_, ?_⟩
  · intro i; exact List.getElem_mem (by omega)
  · intro i j hij
    simp only [] at hij
    have h1 : List.idxOf (ws[i.val]'(by omega)) ws = i.val :=
      List.Nodup.idxOf_getElem hnd i.val (by omega)
    have h2 : List.idxOf (ws[j.val]'(by omega)) ws = j.val :=
      List.Nodup.idxOf_getElem hnd j.val (by omega)
    rw [hij] at h1
    exact Fin.ext (by omega)

end KtLaws.Graph
