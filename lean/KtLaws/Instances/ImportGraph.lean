/-
  KtLaws/Instances/ImportGraph.lean — 全域實例系統的匯入圖理論（O5 義務，誠實版本）

  WHY.md §3 的 O5 草案：
    `imports_acyclic_iff (g : ImportGraph) : (∀ c ∈ scc g, c.length ≤ 1 ∧ ¬ selfLoop c) ↔ Acyclic g`

  原草案依賴 Tarjan/強連通分量機器（本倉無 mathlib，`scc` 不存在）。本檔落倉的是**同一個命題的
  純邏輯內核**，並完整證明——不依賴算法、不依賴取樣：

    `imports_acyclic_iff_mutuality : Acyclic g ↔ ∀ a b, ¬ (Reachable g a b ∧ Reachable g b a)`

  這也是 SCC 說法的邏輯本質（「每個環至多是單點環、且不自環」⟺「任意兩個互相可達的點相等」）。
  命題為 Prop、可對任意 `ImportGraph` 全稱量化、證明用歸納，不是封閉實例。

  殘留差距（誠實記錄）：端到端 Tarjan SCC 的「算法正確性」（對有限節點清單算出全部 SCC 並核對）
  未在此落倉——那屬於實作驗證，非 metatheorem；若日後需要，立案另議。
-/
import KtLaws.Instances.UTerm

namespace KtLaws.Instances

/-- 匯入圖：有限節點與有向邊。 -/
structure ImportGraph where
  nodes : List Nat
  edges : List (Nat × Nat)

/-- 匯入圖上的非空可達路（至少一條邊的傳遞閉包）。 -/
inductive Reachable (g : ImportGraph) : Nat → Nat → Prop where
  | single {a b} : (a, b) ∈ g.edges → Reachable g a b
  | trans {a b c} : Reachable g a b → Reachable g b c → Reachable g a c

/-- 有環：某節點經可達路回到自己。 -/
def Cycle (g : ImportGraph) : Prop := ∃ v, Reachable g v v

/-- 無環。 -/
def Acyclic (g : ImportGraph) : Prop := ¬ Cycle g

/-- 可達路的遞移律（就是 `trans` 構造器的對照組）。 -/
theorem imports_trans {g : ImportGraph} {a b c}
    (h₁ : Reachable g a b) (h₂ : Reachable g b c) : Reachable g a c :=
  Reachable.trans h₁ h₂

/-- 無環圖上不可能有自環邊。 -/
theorem acyclic_self_edge_absent (g : ImportGraph) (v : Nat) (h : Acyclic g) :
    ¬ ((v, v) ∈ g.edges) := by
  intro hmem
  exact h ⟨v, Reachable.single hmem⟩

/-- 無環 ⇒ 可達關係反對稱：兩點互達則相等。 -/
theorem reach_antisym_of_acyclic {g : ImportGraph} (h : Acyclic g) {a b : Nat}
    (hab : Reachable g a b) (hba : Reachable g b a) : a = b :=
  (h ⟨a, Reachable.trans hab hba⟩).elim

/-- 二元互達對在無環圖裡直接不成立（含 a = b 特例）。 -/
theorem no_mutual_reach_of_acyclic {g : ImportGraph} (h : Acyclic g)
    {a b : Nat} : ¬ (Reachable g a b ∧ Reachable g b a) := by
  rintro ⟨hab, hba⟩
  have e := reach_antisym_of_acyclic h hab hba
  subst e
  exact h ⟨a, hab⟩

/-- **O5 主定理**：無環 ⟺ 不存在互達二元組（自環邊與互達環都被涵蓋）。
    與草案 `(∀ c ∈ scc g, c.length ≤ 1 ∧ ¬ selfLoop c) ↔ Acyclic g` 邏輯等價——
    `∀ a b, ¬(Reach a b ∧ Reach b a)` 取 `a = b = v` 恰為「無自環也無非平凡環」。 -/
theorem imports_acyclic_iff_mutuality (g : ImportGraph) :
    Acyclic g ↔ ∀ a b, ¬ (Reachable g a b ∧ Reachable g b a) := by
  constructor
  · intro h a b hm
    exact no_mutual_reach_of_acyclic h hm
  · intro h
    intro ⟨v, hv⟩
    exact h v v ⟨hv, hv⟩

/-- 推論：若兩個不同模組互相匯入（達成閉環），則圖必有環。 -/
theorem cycle_of_distinct_mutual {g : ImportGraph} {a b : Nat} (hne : a ≠ b)
    (hab : Reachable g a b) (hba : Reachable g b a) : Cycle g :=
  ⟨a, Reachable.trans hab hba⟩

/-- 推論：含自環邊的模組必有環。 -/
theorem cycle_of_self_loop {g : ImportGraph} {v : Nat} (hmem : (v, v) ∈ g.edges) : Cycle g :=
  ⟨v, Reachable.single hmem⟩

end KtLaws.Instances
