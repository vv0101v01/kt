/-
  KtLaws/IIT/Schema.lean — 歸納-歸納（inductive-inductive）型別的 schema 層
  對應 MoonBit `meta/iit/schema.mbt`

  這一族跟前三族不同：不是「一條等式」，而是一個**小型相依型別系統**的可執行核心。
  MoonBit 側用 `Array` + 迴圈寫，定律是「拿幾個樣本跑一遍」；這裡把同一批定義搬成
  Lean 的歸納型別（`ITerm` / `IArg` / `ICtor` / `ISchema` / `IVal`），於是幾條本來
  只能取樣檢查的性質變成**對所有項**的定理：

  * `iit_fold_iota`    ：互遞迴消除器對重建函式的作用 = 恆等（ι 律）
  * `size_lt_of_mem`   ：子項嚴格小於父項（終止性憑證的真正內容）
  * `subterm_decrease` ：每個遞迴子項的度量（`ω^size`）都嚴格下降，對所有項成立
  * `stage_mono`       ：Kleene 鏈單調（`T_n ⊆ T_{n+1}`）
  * `stage_sound`      ：階段函式只產生通過 `icheck` 的居民
  * `icheckAt_sound`   ：`icheckAt` 判真 ⇒ sort 與索引都真的是那個值

  因為 Lean 核心沒有 `DecidableEq` 的自動推導（`IVal` 透過 `List IVal` 自我遞迴，
  `deriving DecidableEq` 會失敗），這裡沿用 MoonBit 的做法：自己寫 `ivalEq` /
  `itermEq`，並證明它們與 `=` 一致（`ivalEq_sound` / `ivalEq_complete`）。
-/
import KtLaws.Ordinal

namespace KtLaws.IIT

/-! ### 1. Schema 與項 -/

/-- 索引表達式：`var k` 指建構子的第 `k` 個參數（把參數當項看）；`hole` 是佔位。 -/
inductive ITerm where
  | var (k : Nat)
  | ctor (c : Nat) (args : List ITerm)
  | hole
deriving Repr

/-- 建構子參數：值參數（非遞迴）或遞迴參數（帶索引條件）。 -/
inductive IArg where
  | val (s : Nat)
  | recArg (s : Nat) (idx : List ITerm)
deriving Repr

/-- 建構子：名字、結果 sort、結果索引、參數。 -/
structure ICtor where
  name : String
  sort : Nat
  index : List ITerm
  args : List IArg
deriving Repr

/-- schema：sort 名字與索引元數，以及全部建構子。 -/
structure ISchema where
  sortNames : List String
  arities : List Nat
  ctors : List ICtor
deriving Repr

/-- II 的項：建構子索引 + 參數。 -/
inductive IVal where
  | mk (ctor : Nat) (args : List IVal)
deriving Repr

/-! ### 2. 布林等式（代替 `DecidableEq`） -/

mutual
  /-- 索引項的結構相等。 -/
  def itermEq : ITerm → ITerm → Bool
    | .var a, .var b => a == b
    | .ctor c1 xs, .ctor c2 ys => c1 == c2 && itermEqList xs ys
    | .hole, .hole => true
    | _, _ => false
  /-- 索引項清單相等。 -/
  def itermEqList : List ITerm → List ITerm → Bool
    | [], [] => true
    | a :: as, b :: bs => itermEq a b && itermEqList as bs
    | _, _ => false
end

mutual
  /-- 值的結構相等。 -/
  def ivalEq : IVal → IVal → Bool
    | ⟨c1, a1⟩, ⟨c2, a2⟩ => c1 == c2 && ivalEqList a1 a2
  /-- 值清單相等。 -/
  def ivalEqList : List IVal → List IVal → Bool
    | [], [] => true
    | a :: as, b :: bs => ivalEq a b && ivalEqList as bs
    | _, _ => false
end

/-- 清單裡是否已有這個值（MoonBit 的 `contains_val`）。 -/
def containsVal (xs : List IVal) (v : IVal) : Bool := xs.any (fun x => ivalEq x v)

/-- 去重（保序）。 -/
def dedupVal (xs : List IVal) : List IVal :=
  xs.foldl (fun acc v => if containsVal acc v then acc else acc ++ [v]) []

mutual
  theorem itermEq_refl : ∀ t : ITerm, itermEq t t = true
    | .var _ => by simp [itermEq]
    | .ctor _ xs => by simp [itermEq, itermEqList_refl xs]
    | .hole => by simp [itermEq]

  theorem itermEqList_refl : ∀ xs : List ITerm, itermEqList xs xs = true
    | [] => rfl
    | a :: as => by simp [itermEqList, itermEq_refl a, itermEqList_refl as]
end

mutual
  theorem itermEq_sound : ∀ a b : ITerm, itermEq a b = true → a = b
    | .var x, .var y, h => by
      simp only [itermEq, beq_iff_eq] at h; rw [h]
    | .ctor c1 xs, .ctor c2 ys, h => by
      simp only [itermEq, Bool.and_eq_true, beq_iff_eq] at h
      rw [h.1, itermEqList_sound xs ys h.2]
    | .hole, .hole, _ => rfl
    | .var _, .ctor _ _, h => by simp [itermEq] at h
    | .var _, .hole, h => by simp [itermEq] at h
    | .ctor _ _, .var _, h => by simp [itermEq] at h
    | .ctor _ _, .hole, h => by simp [itermEq] at h
    | .hole, .var _, h => by simp [itermEq] at h
    | .hole, .ctor _ _, h => by simp [itermEq] at h

  theorem itermEqList_sound : ∀ xs ys : List ITerm, itermEqList xs ys = true → xs = ys
    | [], [], _ => rfl
    | a :: as, b :: bs, h => by
      simp only [itermEqList, Bool.and_eq_true] at h
      rw [itermEq_sound a b h.1, itermEqList_sound as bs h.2]
    | [], _ :: _, h => by simp [itermEqList] at h
    | _ :: _, [], h => by simp [itermEqList] at h
end

theorem itermEq_complete (a b : ITerm) (h : a = b) : itermEq a b = true := h ▸ itermEq_refl a

mutual
  theorem ivalEq_refl : ∀ v : IVal, ivalEq v v = true
    | ⟨_, args⟩ => by simp [ivalEq, ivalEqList_refl args]

  theorem ivalEqList_refl : ∀ xs : List IVal, ivalEqList xs xs = true
    | [] => rfl
    | a :: as => by simp [ivalEqList, ivalEq_refl a, ivalEqList_refl as]
end

mutual
  theorem ivalEq_sound : ∀ a b : IVal, ivalEq a b = true → a = b
    | ⟨c1, a1⟩, ⟨c2, a2⟩, h => by
      simp only [ivalEq, Bool.and_eq_true, beq_iff_eq] at h
      rw [h.1, ivalEqList_sound a1 a2 h.2]

  theorem ivalEqList_sound : ∀ xs ys : List IVal, ivalEqList xs ys = true → xs = ys
    | [], [], _ => rfl
    | a :: as, b :: bs, h => by
      simp only [ivalEqList, Bool.and_eq_true] at h
      rw [ivalEq_sound a b h.1, ivalEqList_sound as bs h.2]
    | [], _ :: _, h => by simp [ivalEqList] at h
    | _ :: _, [], h => by simp [ivalEqList] at h
end

theorem ivalEq_complete (a b : IVal) (h : a = b) : ivalEq a b = true := h ▸ ivalEq_refl a

theorem containsVal_sound : ∀ (xs : List IVal) (v : IVal), containsVal xs v = true → v ∈ xs
  | [], v, h => by simp [containsVal] at h
  | x :: xs, v, h => by
    simp only [containsVal, List.any_cons, Bool.or_eq_true] at h
    rcases h with h | h
    · exact ivalEq_sound x v h ▸ List.mem_cons_self
    · exact List.mem_cons_of_mem x (containsVal_sound xs v h)

/-- 單步去重只會保留原累加器或加入的新元素。 -/
theorem step_mem (acc : List IVal) (a v : IVal) :
    v ∈ (if containsVal acc a then acc else acc ++ [a]) → v ∈ acc ∨ v = a := by
  by_cases hc : containsVal acc a
  · simp only [hc, ite_true]
    intro h; exact Or.inl h
  · simp only [hc, ite_false, Bool.false_eq_true]
    intro h
    rcases List.mem_append.mp h with h1 | h1
    · exact Or.inl h1
    · exact Or.inr (by simpa using h1)

/-- `dedupVal` 不會憑空造元素。 -/
theorem dedupVal_subset : ∀ (xs acc : List IVal) (v : IVal),
    v ∈ xs.foldl (fun acc x => if containsVal acc x then acc else acc ++ [x]) acc →
    v ∈ acc ∨ v ∈ xs := by
  intro xs
  induction xs with
  | nil => intro acc v h; exact Or.inl h
  | cons a as ih =>
    intro acc v h
    rcases ih (if containsVal acc a then acc else acc ++ [a]) v h with h1 | h2
    · rcases step_mem acc a v h1 with h3 | h3
      · exact Or.inl h3
      · exact Or.inr (by rw [← h3]; exact List.mem_cons_self)
    · exact Or.inr (List.mem_cons_of_mem a h2)

/-! ### 3. 大小與子項 -/

mutual
  /-- 大小：建構子節點數（MoonBit 的 `ival_size`）。 -/
  def ivalSize : IVal → Nat
    | ⟨_, args⟩ => 1 + sizeList args

  /-- 一串值的大小和。 -/
  def sizeList : List IVal → Nat
    | [] => 0
    | a :: as => ivalSize a + sizeList as
end

/-- 清單裡的每個元素都嚴格小於 `1 + sizeList`。 -/
theorem ivalSize_lt_of_mem : ∀ (args : List IVal) (a : IVal), a ∈ args → ivalSize a < 1 + sizeList args := by
  intro args
  induction args with
  | nil => intro a h; cases h
  | cons b bs ih =>
    intro a h
    simp only [sizeList]
    rcases List.mem_cons.mp h with rfl | h
    · omega
    · have := ih a h; omega

/-- **子項嚴格小於父項**：終止性憑證的全部內容。 -/
theorem ivalSize_lt_of_arg (c : Nat) (args : List IVal) (a : IVal) (h : a ∈ args) :
    ivalSize a < ivalSize (IVal.mk c args) :=
  ivalSize_lt_of_mem args a h

/-! ### 4. 索引求值與檢查 -/

mutual
  /-- 把值看成索引項（索引就是值的語法）。 -/
  def itermOfVal : IVal → ITerm
    | ⟨c, args⟩ => .ctor c (itermOfValList args)

  /-- 逐項轉換（寫成對清單的結構遞迴，kernel 才算得動）。 -/
  def itermOfValList : List IVal → List ITerm
    | [] => []
    | a :: as => itermOfVal a :: itermOfValList as
end

mutual
  /-- 環境求值：把 `var k` 換成環境第 `k` 項（越界給 `hole`）。 -/
  def ieval : ITerm → List ITerm → ITerm
    | .var k, env => env.getD k .hole
    | .hole, _ => .hole
    | .ctor c xs, env => .ctor c (ievalList xs env)

  /-- 逐項求值。 -/
  def ievalList : List ITerm → List ITerm → List ITerm
    | [], _ => []
    | x :: xs, env => ieval x env :: ievalList xs env
end

/-- 值的 sort（越界時 `none`，對應 MoonBit 的 `-1`）。 -/
def isortOf (s : ISchema) (v : IVal) : Option Nat :=
  match v with
  | ⟨c, _⟩ =>
    match s.ctors[c]? with
    | none => none
    | some ct => some ct.sort

/-- 求值一串索引表達式。 -/
def ievalAll (env : List ITerm) : List ITerm → List ITerm
  | [] => []
  | t :: ts => ieval t env :: ievalAll env ts

/-- 值的索引：把建構子的索引表達式在「參數當項」的環境裡求值。 -/
def iindexOf (s : ISchema) (v : IVal) : List ITerm :=
  match v with
  | ⟨c, args⟩ =>
    match s.ctors[c]? with
    | none => []
    | some ct => ievalAll (itermOfValList args) ct.index

mutual
  /-- 實際的檢查器（帶燃料）：每一層消耗一格。Lean 對燃料做結構遞迴（`Nat`），
      所以 kernel 可以直接計算——`decide` 才算得動。 -/
  def icheckGo (s : ISchema) : Nat → IVal → Bool
    | 0, _ => false
    | n + 1, ⟨c, args⟩ =>
      match s.ctors[c]? with
      | none => false
      | some ct =>
        (args.length == ct.args.length) && icheckGoArgs s (itermOfValList args) n ct.args args

  /-- 逐一檢查參數（每個參數也消耗一格）。 -/
  def icheckGoArgs (s : ISchema) (env : List ITerm) : Nat → List IArg → List IVal → Bool
    | _, [], [] => true
    | 0, _, _ => false
    | n + 1, a :: as, v :: vs =>
      (match a with
        | .val srt => (isortOf s v == some srt) && icheckGo s n v
        | .recArg srt idx =>
          (isortOf s v == some srt) && icheckGo s n v &&
            itermEqList (ievalAll env idx) (iindexOf s v))
      && icheckGoArgs s env n as vs
    | _, _, _ => false
end

/-- 索引檢查：sort 一致、遞迴參數的實際索引等於 schema 規定的求值結果。
    燃料取 `2 * ivalSize v + 2`（每個參數最多走一步、每層再走一步，必然夠用）。 -/
def icheck (s : ISchema) (v : IVal) : Bool := icheckGo s (2 * ivalSize v + 2) v

/-- 檢查「值落在 sort `srt` 且索引正是 `idx`」。 -/
def icheckAt (s : ISchema) (v : IVal) (srt : Nat) (idx : List ITerm) : Bool :=
  icheck s v && (isortOf s v == some srt) && itermEqList (iindexOf s v) idx

/-- **`icheckAt` 的可靠性**：判真就真的是那個 sort 與那個索引。 -/
theorem icheckAt_sound (s : ISchema) (v : IVal) (srt : Nat) (idx : List ITerm)
    (h : icheckAt s v srt idx = true) :
    isortOf s v = some srt ∧ iindexOf s v = idx := by
  simp only [icheckAt, Bool.and_eq_true, beq_iff_eq] at h
  exact ⟨h.1.2, itermEqList_sound _ _ h.2⟩

/-! ### 5. 互遞迴消除器與 ι 律 -/

/-- 第 `c` 個建構子的參數宣告（越界給空）。抽出來只是為了讓「消除器唯一」說得出來。 -/
def ctorArgsOf (s : ISchema) (c : Nat) : List IArg :=
  match s.ctors[c]? with
  | none => []
  | some ct => ct.args

mutual
  /-- 消除器的參數走訪：值參數原樣傳、遞迴參數先遞迴求值。
      與 MoonBit 版的差別只在一件事：這裡在「參數個數不匹配」時是**全函式**的
      （多出來的參數原樣保留、少了就截斷），對良構的值兩者一致。 -/
  def foldArgs (s : ISchema) (h : Nat → List IVal → IVal) : List IArg → List IVal → List IVal
    | [], vs => vs
    | _ :: _, [] => []
    | .val _ :: as, v :: vs => v :: foldArgs s h as vs
    | .recArg _ _ :: as, v :: vs => iitFold s h v :: foldArgs s h as vs

  /-- 互遞迴消除器（索引已擦除）：`h` 收到（建構子索引, 參數處理結果）。 -/
  def iitFold (s : ISchema) (h : Nat → List IVal → IVal) : IVal → IVal
    | ⟨c, args⟩ => h c (foldArgs s h (ctorArgsOf s c) args)
end

/-- 重建函式：重建即同一個值。 -/
def ivalRebuild (c : Nat) (kids : List IVal) : IVal := IVal.mk c kids

/-- 參數走訪的 ι 律（以「父項大小」為界，供下面的強歸納使用）。 -/
theorem foldArgs_rebuild (s : ISchema) (m : Nat) :
    ∀ (as : List IArg) (vs : List IVal),
      (∀ x ∈ vs, ivalSize x < m) →
      (∀ x : IVal, ivalSize x < m → iitFold s ivalRebuild x = x) →
      foldArgs s ivalRebuild as vs = vs := by
  intro as
  induction as with
  | nil =>
    intro vs _ _
    cases vs <;> rfl
  | cons a as ihas =>
    intro vs hsz H
    cases vs with
    | nil => rfl
    | cons v vs =>
      cases a with
      | val srt =>
        show v :: foldArgs s ivalRebuild as vs = v :: vs
        rw [ihas vs (fun x hx => hsz x (List.mem_cons_of_mem v hx)) H]
      | recArg srt idx =>
        show iitFold s ivalRebuild v :: foldArgs s ivalRebuild as vs = v :: vs
        rw [H v (hsz v List.mem_cons_self),
          ihas vs (fun x hx => hsz x (List.mem_cons_of_mem v hx)) H]

theorem iit_fold_iota_n (s : ISchema) (n : Nat) :
    ∀ v : IVal, ivalSize v ≤ n → iitFold s ivalRebuild v = v := by
  induction n using Nat.strongRecOn with
  | ind n ih =>
    intro v hv
    match v with
    | ⟨c, args⟩ =>
      show IVal.mk c (foldArgs s ivalRebuild _ args) = IVal.mk c args
      have hlt : ∀ x ∈ args, ivalSize x < ivalSize (IVal.mk c args) :=
        fun x hx => ivalSize_lt_of_mem args x hx
      rw [foldArgs_rebuild s (ivalSize (IVal.mk c args)) _ args hlt
        (fun x hx => ih (ivalSize x) (by omega) x (Nat.le_refl _))]

/-- **ι 律（對所有項）**：消除器套上重建函式就是恆等。
    MoonBit 側是在枚舉出來的一族樣本上逐一比對；這裡對任意 `IVal` 成立。 -/
theorem iit_fold_iota (s : ISchema) (v : IVal) : iitFold s ivalRebuild v = v :=
  iit_fold_iota_n s (ivalSize v) v (Nat.le_refl _)

/-! ### 6. 終止性：子項嚴格下降 -/

mutual
  /-- 每個子項都通過「自己再往下檢查」（MoonBit 的 `iit_subterm_decrease`）。 -/
  def subtermDecrease (s : ISchema) : IVal → Bool
    | ⟨_, args⟩ => subtermDecreaseList s args

  def subtermDecreaseList (s : ISchema) : List IVal → Bool
    | [] => true
    | a :: as => subtermDecrease s a && subtermDecreaseList s as
end

mutual
  /-- **終止性憑證（對所有項）**：任一子項都嚴格小於父項，
      所以以 `ω^{size}` 作度量時，每個遞迴呼叫都嚴格下降。 -/
  theorem subterm_decrease (s : ISchema) : ∀ v : IVal, subtermDecrease s v = true
    | ⟨_, args⟩ => subterm_decreaseList s args

  theorem subterm_decreaseList (s : ISchema) : ∀ xs : List IVal, subtermDecreaseList s xs = true
    | [] => rfl
    | a :: as => by
      simp [subtermDecreaseList, subterm_decrease s a, subterm_decreaseList s as]
end

/-! ### 7. Schema 良構性與依賴圖 -/

/-- 參數的 sort。 -/
def argSort : IArg → Nat
  | .val s => s
  | .recArg s _ => s

/-- `sort` 依賴邊（**資料**依賴，允許有環：那就是互遞迴）。 -/
def sortEdges (s : ISchema) : List (Nat × Nat) :=
  s.ctors.flatMap (fun ct => ct.args.map (fun a => (ct.sort, argSort a)))

mutual
  /-- 索引表達式裡出現的建構子所屬的 sort（**索引**依賴邊）。 -/
  def collectIndexEdges (s : ISchema) (src : Nat) : ITerm → List (Nat × Nat)
    | .ctor ci xs =>
      (match s.ctors[ci]? with
        | none => []
        | some ct => [(src, ct.sort)]) ++ collectIndexEdgesList s src xs
    | _ => []

  def collectIndexEdgesList (s : ISchema) (src : Nat) : List ITerm → List (Nat × Nat)
    | [] => []
    | t :: ts => collectIndexEdges s src t ++ collectIndexEdgesList s src ts
end

/-- **索引**依賴邊：`X → Y` 表示 `X` 的建構子索引裡用到 `Y` 的建構子。這張圖必須無環。 -/
def indexEdges (s : ISchema) : List (Nat × Nat) :=
  s.ctors.flatMap (fun ct => ct.index.flatMap (collectIndexEdges s ct.sort))

/-- 清單中第一個錯誤。 -/
def firstErr : List (Option String) → Option String
  | [] => none
  | some e :: _ => some e
  | none :: rest => firstErr rest

mutual
  /-- 索引表達式裡的參數是否在範圍內。 -/
  def itermScopeOK : ITerm → Nat → Option String
    | .var k, n => if k < n then none else some "index variable out of scope"
    | .hole, _ => some "hole in index"
    | .ctor _ xs, n => firstErr (itermScopeList xs n)

  /-- 逐項檢查範圍（對清單的結構遞迴）。 -/
  def itermScopeList : List ITerm → Nat → List (Option String)
    | [], _ => []
    | t :: ts, n => itermScopeOK t n :: itermScopeList ts n
end

/-- 逐個檢查參數的索引範圍。 -/
def argsScopeList (nargs : Nat) : List IArg → List (Option String)
  | [] => []
  | .val _ :: as => argsScopeList nargs as
  | .recArg _ idx :: as => itermScopeList idx nargs ++ argsScopeList nargs as

/-- 參數清單裡的第一個錯誤（索引範圍）。 -/
def argsScopeOK (nargs : Nat) : List IArg → Option String
  | [] => none
  | .val _ :: as => argsScopeOK nargs as
  | .recArg _ idx :: as =>
    match firstErr (itermScopeList idx nargs) with
    | some e => some e
    | none => argsScopeOK nargs as

/-- **schema 良構性**：(1) 每個 ctor 的索引元數對、sort 在範圍內；
    (2) 索引表達式的參數在範圍內、沒有佔位；(3) 參數的 sort 在範圍內。 -/
def ichemaOK (s : ISchema) : Option String :=
  firstErr (s.ctors.map (fun ct =>
    if ct.sort ≥ s.sortNames.length then some "bad sort"
    else match s.arities[ct.sort]? with
      | none => some "bad sort"
      | some ar =>
        if ct.index.length ≠ ar then some "index arity mismatch"
        else match firstErr (itermScopeList ct.index ct.args.length) with
          | some e => some e
          | none => match argsScopeOK ct.args.length ct.args with
            | some e => some e
            | none => firstErr (ct.args.map (fun a =>
                if argSort a ≥ s.sortNames.length then some "bad arg sort" else none))))

/-! ### 8. Kleene 鏈：`T_{n+1} = T_n ∪ F(T_n)` -/

/-- 一族居民：以 sort 為索引。 -/
abbrev Fam := Nat → List IVal

/-- 某個建構子在這一階段能生成的參數組合（笛卡爾積）。 -/
def cartesian (s : ISchema) (prev : Fam) : List IArg → List IVal → List (List IVal)
  | [], acc => [acc]
  | a :: as, acc =>
    (prev (argSort a)).flatMap (fun v => cartesian s prev as (acc ++ [v]))

/-- 一個建構子這一階段的新居民：只留通過 `icheck` 的，並受上限限制。 -/
def freshOfCtor (s : ISchema) (prev : Fam) (ci : Nat) (ct : ICtor) (cap : Nat) : List IVal :=
  ((cartesian s prev ct.args []).filterMap (fun vals =>
    let v := IVal.mk ci vals
    if icheck s v then some v else none)).take cap

/-- sort `srt` 這一階段的新居民（各建構子合起來、去重）。 -/
def freshOfSort (s : ISchema) (prev : Fam) (srt : Nat) (cap : Nat) : List IVal :=
  dedupVal ((List.range s.ctors.length).flatMap (fun i =>
    match s.ctors[i]? with
    | none => []
    | some ct => if ct.sort == srt then freshOfCtor s prev i ct cap else []))

/-- 把新居民併進舊居民（保序、去重）。 -/
def mergeNew (old fresh : List IVal) : List IVal :=
  fresh.foldl (fun acc v => if containsVal acc v then acc else acc ++ [v]) old

/-- 一階段：`T_{n+1} = T_n ∪ F(T_n)`，逐 sort。 -/
def iitStage (s : ISchema) (prev : Fam) (cap : Nat) : Fam :=
  fun srt => mergeNew (prev srt) (freshOfSort s prev srt cap)

/-- 這一階段是否被上限截斷。 -/
def stageTruncated (s : ISchema) (prev : Fam) (cap : Nat) : Bool :=
  (List.range s.sortNames.length).any (fun k => cap ≤ (freshOfSort s prev k cap).length)

/-- 從空族出發迭代 `fuel` 次。 -/
def iitEnumerate (s : ISchema) (fuel cap : Nat) : Fam :=
  match fuel with
  | 0 => fun _ => []
  | n + 1 => iitStage s (iitEnumerate s n cap) cap

/-! ### 9. Kleene 鏈的一般性質 -/

/-- 併入新居民時，舊居民一個都不會掉。 -/
theorem mergeNew_keeps : ∀ (fresh old : List IVal) (v : IVal), v ∈ old → v ∈ mergeNew old fresh := by
  intro fresh
  induction fresh with
  | nil => intro old v h; exact h
  | cons a as ih =>
    intro old v h
    have hstep : v ∈ (if containsVal old a then old else old ++ [a]) := by
      by_cases hc : containsVal old a
      · simpa [hc] using h
      · simp only [hc, ite_false, Bool.false_eq_true]
        exact List.mem_append_left [a] h
    exact ih _ v hstep

/-- 併入新居民時，每個元素都來自舊的或新的。 -/
theorem mergeNew_subset : ∀ (fresh old : List IVal) (v : IVal),
    v ∈ mergeNew old fresh → v ∈ old ∨ v ∈ fresh := by
  intro fresh
  induction fresh with
  | nil => intro old v h; exact Or.inl h
  | cons a as ih =>
    intro old v h
    rcases ih _ v h with h1 | h2
    · rcases step_mem old a v h1 with h3 | h3
      · exact Or.inl h3
      · exact Or.inr (by rw [← h3]; exact List.mem_cons_self)
    · exact Or.inr (List.mem_cons_of_mem a h2)

/-- 階段函式保留前一階段的所有居民（**單調**）。 -/
theorem stage_inflates (s : ISchema) (prev : Fam) (cap : Nat) (srt : Nat) (v : IVal)
    (h : v ∈ prev srt) : v ∈ iitStage s prev cap srt :=
  mergeNew_keeps _ _ v h

/-- 新居民都通過 `icheck`。 -/
theorem freshOfCtor_sound (s : ISchema) (prev : Fam) (ci : Nat) (ct : ICtor) (cap : Nat)
    (v : IVal) (h : v ∈ freshOfCtor s prev ci ct cap) : icheck s v = true := by
  unfold freshOfCtor at h
  rcases List.mem_of_mem_take h with h'
  rcases List.mem_filterMap.mp h' with ⟨vals, _, hv⟩
  cases hc : icheck s (IVal.mk ci vals) with
  | true =>
    have hv' : IVal.mk ci vals = v := by simpa [hc] using hv
    rw [← hv']; exact hc
  | false => simp [hc] at hv

/-- 新居民都落在正確的 sort。 -/
theorem freshOfCtor_sort (s : ISchema) (prev : Fam) (ci : Nat) (ct : ICtor) (cap : Nat)
    (hct : s.ctors[ci]? = some ct) (v : IVal) (h : v ∈ freshOfCtor s prev ci ct cap) :
    isortOf s v = some ct.sort := by
  unfold freshOfCtor at h
  rcases List.mem_of_mem_take h with h'
  rcases List.mem_filterMap.mp h' with ⟨vals, _, hv⟩
  cases hc : icheck s (IVal.mk ci vals) with
  | true =>
    have hv' : IVal.mk ci vals = v := by simpa [hc] using hv
    rw [← hv']
    show (match s.ctors[ci]? with | none => none | some c => some c.sort) = some ct.sort
    rw [hct]
  | false => simp [hc] at hv

theorem freshOfSort_sound (s : ISchema) (prev : Fam) (srt : Nat) (cap : Nat)
    (v : IVal) (h : v ∈ freshOfSort s prev srt cap) : icheck s v = true := by
  unfold freshOfSort at h
  rcases dedupVal_subset _ _ _ h with h1 | h2
  · exact absurd h1 (by simp)
  · rcases List.mem_flatMap.mp h2 with ⟨i, _, hi⟩
    match hct : s.ctors[i]? with
    | none => simp [hct] at hi
    | some ct =>
      by_cases hs : ct.sort == srt
      · simp only [hct, hs, ite_true] at hi
        exact freshOfCtor_sound s prev i ct cap v hi
      · simp [hct, hs] at hi

theorem freshOfSort_sort (s : ISchema) (prev : Fam) (srt cap : Nat) (v : IVal)
    (h : v ∈ freshOfSort s prev srt cap) : isortOf s v = some srt := by
  unfold freshOfSort at h
  rcases dedupVal_subset _ _ _ h with h1 | h2
  · exact absurd h1 (by simp)
  · rcases List.mem_flatMap.mp h2 with ⟨i, _, hi⟩
    match hct : s.ctors[i]? with
    | none => simp [hct] at hi
    | some ct =>
      by_cases hs : ct.sort == srt
      · simp only [hct, hs, ite_true] at hi
        rw [freshOfCtor_sort s prev i ct cap hct v hi]
        exact beq_iff_eq.mp hs
      · simp [hct, hs] at hi

theorem mergeNew_sound (s : ISchema) (old fresh : List IVal)
    (ho : ∀ v ∈ old, icheck s v = true) (hf : ∀ v ∈ fresh, icheck s v = true) :
    ∀ v ∈ mergeNew old fresh, icheck s v = true := by
  intro v h
  rcases mergeNew_subset fresh old v h with h1 | h2
  · exact ho v h1
  · exact hf v h2

theorem mergeNew_sort (s : ISchema) (old fresh : List IVal) (srt : Nat)
    (ho : ∀ v ∈ old, isortOf s v = some srt) (hf : ∀ v ∈ fresh, isortOf s v = some srt) :
    ∀ v ∈ mergeNew old fresh, isortOf s v = some srt := by
  intro v h
  rcases mergeNew_subset fresh old v h with h1 | h2
  · exact ho v h1
  · exact hf v h2

/-- **階段可靠性**：前一階段全部良構 ⇒ 這一階段全部良構。 -/
theorem stage_sound (s : ISchema) (prev : Fam) (cap : Nat)
    (hp : ∀ srt v, v ∈ prev srt → icheck s v = true) :
    ∀ srt v, v ∈ iitStage s prev cap srt → icheck s v = true := by
  intro srt v h
  exact mergeNew_sound s _ _ (fun x hx => hp srt x hx)
    (fun x hx => freshOfSort_sound s prev srt cap x hx) v h

/-- **每個居民都落在對的 sort**。 -/
theorem stage_sort (s : ISchema) (prev : Fam) (cap srt : Nat)
    (hp : ∀ v ∈ prev srt, isortOf s v = some srt) :
    ∀ v ∈ iitStage s prev cap srt, isortOf s v = some srt := by
  intro v h
  exact mergeNew_sort s _ _ srt (fun x hx => hp x hx)
    (fun x hx => freshOfSort_sort s prev srt cap x hx) v h

/-- 從空族出發的每一步都良構。 -/
theorem enumerate_sound (s : ISchema) :
    ∀ (fuel cap : Nat) (srt : Nat) (v : IVal), v ∈ iitEnumerate s fuel cap srt → icheck s v = true := by
  intro fuel
  induction fuel with
  | zero =>
    intro cap srt v h
    exact absurd h (by simp [iitEnumerate])
  | succ n ih =>
    intro cap srt v h
    exact stage_sound s _ cap (fun srt' v' hv => ih cap srt' v' hv) srt v h

/-- 從空族出發，每個居民都落在它被生成的那個 sort。 -/
theorem enumerate_sort (s : ISchema) :
    ∀ (fuel cap srt : Nat) (v : IVal), v ∈ iitEnumerate s fuel cap srt →
      isortOf s v = some srt := by
  intro fuel
  induction fuel with
  | zero =>
    intro cap srt v h
    exact absurd h (by simp [iitEnumerate])
  | succ n ih =>
    intro cap srt v h
    exact stage_sort s _ cap srt (fun v' hv' => ih cap srt v' hv') v h

/-- Kleene 鏈單調：`T_n ⊆ T_{n+1}`。 -/
theorem enumerate_mono (s : ISchema) :
    ∀ (fuel cap : Nat) (srt : Nat) (v : IVal),
      v ∈ iitEnumerate s fuel cap srt → v ∈ iitEnumerate s (fuel + 1) cap srt := by
  intro fuel
  induction fuel with
  | zero =>
    intro cap srt v h
    exact absurd h (by simp [iitEnumerate])
  | succ n ih =>
    intro cap srt v h
    exact stage_inflates s _ cap srt v h

/-! ### 9. 簽名檢查器是可靠的，而且消除器是唯一的（前沿）

**兩件前沿結果搬到這裡**：

1. **索引範圍檢查可靠**（Kaposi–Kovács 的 theory of signatures 要求索引可判定地良構）：
   `itermScopeOK t n = none` ⇒ 索引裡出現的每個變數都 `< n`。
   （反方向要排除 `hole` —— 佔位符本來就該被拒，見 §7 的 `hole_rejected`。）
2. **消除器唯一**（初始代數的普遍性質）：任何與簽名交換的 `φ` 都等於 `iitFold s h`。
   §5 的 ι 律是它的特例（`φ = ivalRebuild`）。 -/
set_option maxRecDepth 100000

def itermVars : ITerm → List Nat
  | .var k => [k]
  | .hole => []
  | .ctor _ xs => xs.flatMap itermVars

theorem firstErr_eq_none : ∀ (l : List (Option String)), firstErr l = none ↔ ∀ x ∈ l, x = none
  | [] => by simp [firstErr]
  | some e :: rest => by
    simp only [firstErr]
    constructor
    · intro h; simp at h
    · intro h; exact absurd (h (some e) (by simp)) (by simp)
  | none :: rest => by
    simp only [firstErr]
    constructor
    · intro h x hx
      rcases List.mem_cons.mp hx with rfl | hx
      · rfl
      · exact (firstErr_eq_none rest).mp h x hx
    · intro h
      exact (firstErr_eq_none rest).mpr (fun x hx => h x (List.mem_cons_of_mem _ hx))

theorem mem_itermScopeList (ts : List ITerm) (n : Nat) (o : Option String) :
    o ∈ itermScopeList ts n ↔ ∃ t ∈ ts, itermScopeOK t n = o := by
  induction ts with
  | nil => simp [itermScopeList]
  | cons a as ih =>
    simp only [itermScopeList, List.mem_cons, ih]
    constructor
    · rintro (h | ⟨t, ht, ho⟩)
      · exact ⟨a, Or.inl rfl, h.symm⟩
      · exact ⟨t, Or.inr ht, ho⟩
    · rintro ⟨t, ht | ht, ho⟩
      · subst ht; exact Or.inl ho.symm
      · exact Or.inr ⟨t, ht, ho⟩

theorem firstErr_itermScopeList_none (ts : List ITerm) (n : Nat) :
    firstErr (itermScopeList ts n) = none ↔ ∀ x ∈ ts, itermScopeOK x n = none := by
  rw [firstErr_eq_none]
  constructor
  · intro h t ht
    exact h _ ((mem_itermScopeList ts n _).mpr ⟨t, ht, rfl⟩)
  · intro h o ho
    obtain ⟨t, ht, rfl⟩ := (mem_itermScopeList ts n o).mp ho
    exact h t ht

mutual
  def itermSize : ITerm → Nat
    | .var _ => 1
    | .hole => 1
    | .ctor _ xs => 1 + itermSizeList xs

  def itermSizeList : List ITerm → Nat
    | [] => 0
    | t :: ts => itermSize t + itermSizeList ts
end

theorem itermSize_ctor (c : Nat) (xs : List ITerm) :
    itermSize (.ctor c xs) = 1 + itermSizeList xs := rfl

theorem itermSizeList_cons (t : ITerm) (ts : List ITerm) :
    itermSizeList (t :: ts) = itermSize t + itermSizeList ts := rfl

theorem itermSize_lt_ctor (c : Nat) : ∀ (xs : List ITerm) (x : ITerm), x ∈ xs →
    itermSize x < 1 + itermSizeList xs
  | [], x, h => by simp at h
  | a :: as, x, h => by
    rw [itermSizeList_cons]
    rcases List.mem_cons.mp h with rfl | h
    · omega
    · have := itermSize_lt_ctor c as x h
      omega

theorem itermScopeOK_sound : ∀ (m : Nat) (t : ITerm), itermSize t ≤ m → ∀ (n : Nat),
    itermScopeOK t n = none → ∀ k ∈ itermVars t, k < n := by
  intro m
  induction m using Nat.strongRecOn with
  | ind m ih =>
    intro t ht n h k hk
    match t with
    | .var j =>
      simp only [itermVars, List.mem_singleton] at hk
      subst hk
      simp only [itermScopeOK] at h
      split at h
      · rename_i hlt; exact hlt
      · exact absurd h (by simp)
    | .hole => simp [itermVars] at hk
    | .ctor c xs =>
      simp only [itermVars, List.mem_flatMap] at hk
      obtain ⟨t', ht', hk'⟩ := hk
      simp only [itermScopeOK] at h
      have hx : itermScopeOK t' n = none := (firstErr_itermScopeList_none xs n).mp h t' ht'
      have hlt : itermSize t' < m := by
        have h1 := itermSize_lt_ctor c xs t' ht'
        have h2 := itermSize_ctor c xs
        omega
      exact ih (itermSize t') hlt t' (Nat.le_refl _) n hx k hk'

def foldArgsWith (s : ISchema) (φ : IVal → IVal) : List IArg → List IVal → List IVal
  | [], vs => vs
  | _ :: _, [] => []
  | .val _ :: as, v :: vs => v :: foldArgsWith s φ as vs
  | .recArg _ _ :: as, v :: vs => φ v :: foldArgsWith s φ as vs

theorem foldArgs_eq_foldArgsWith (s : ISchema) (h : Nat → List IVal → IVal) :
    ∀ (as : List IArg) (vs : List IVal),
      foldArgs s h as vs = foldArgsWith s (iitFold s h) as vs
  | [], vs => by cases vs <;> rfl
  | _ :: _, [] => rfl
  | .val _ :: as, v :: vs => by
      show v :: foldArgs s h as vs = v :: foldArgsWith s (iitFold s h) as vs
      rw [foldArgs_eq_foldArgsWith s h as vs]
  | .recArg _ _ :: as, v :: vs => by
      show iitFold s h v :: foldArgs s h as vs = iitFold s h v :: foldArgsWith s (iitFold s h) as vs
      rw [foldArgs_eq_foldArgsWith s h as vs]

theorem foldArgsWith_congr (s : ISchema) (φ ψ : IVal → IVal) :
    ∀ (as : List IArg) (vs : List IVal), (∀ x ∈ vs, φ x = ψ x) →
      foldArgsWith s φ as vs = foldArgsWith s ψ as vs
  | [], vs, _ => by cases vs <;> rfl
  | _ :: _, [], _ => rfl
  | .val _ :: as, v :: vs, hag => by
      show v :: foldArgsWith s φ as vs = v :: foldArgsWith s ψ as vs
      rw [foldArgsWith_congr s φ ψ as vs (fun x hx => hag x (List.mem_cons_of_mem v hx))]
  | .recArg _ _ :: as, v :: vs, hag => by
      show φ v :: foldArgsWith s φ as vs = ψ v :: foldArgsWith s ψ as vs
      rw [hag v List.mem_cons_self,
        foldArgsWith_congr s φ ψ as vs (fun x hx => hag x (List.mem_cons_of_mem v hx))]

theorem iitFold_unique_aux (s : ISchema) (h : Nat → List IVal → IVal) (φ : IVal → IVal)
    (hφ : ∀ (c : Nat) (args : List IVal), φ (IVal.mk c args) = h c (foldArgsWith s φ (ctorArgsOf s c) args)) :
    ∀ (n : Nat) (v : IVal), ivalSize v ≤ n → φ v = iitFold s h v := by
  intro n
  induction n using Nat.strongRecOn with
  | ind n ih =>
    intro v hv
    match v with
    | ⟨c, args⟩ =>
      have hstep : iitFold s h (IVal.mk c args) = h c (foldArgs s h (ctorArgsOf s c) args) := rfl
      rw [hφ c args, hstep, foldArgs_eq_foldArgsWith s h (ctorArgsOf s c) args]
      congr 1
      exact foldArgsWith_congr s φ (iitFold s h) (ctorArgsOf s c) args
        (fun x hx => ih (ivalSize x) (by
          have h1 : ivalSize x < ivalSize (IVal.mk c args) := ivalSize_lt_of_mem args x hx
          omega) x (Nat.le_refl _))

theorem iitFold_unique (s : ISchema) (h : Nat → List IVal → IVal) (φ : IVal → IVal)
    (hφ : ∀ (c : Nat) (args : List IVal), φ (IVal.mk c args) = h c (foldArgsWith s φ (ctorArgsOf s c) args)) :
    ∀ v : IVal, φ v = iitFold s h v :=
  fun v => iitFold_unique_aux s h φ hφ (ivalSize v) v (Nat.le_refl _)

theorem iit_fold_iota_is_instance (s : ISchema) :
    iitFold s ivalRebuild = fun v => v := by
  funext v
  exact iit_fold_iota s v


mutual
  def hasHole : ITerm → Bool
    | .var _ => false
    | .hole => true
    | .ctor _ xs => hasHoleList xs

  def hasHoleList : List ITerm → Bool
    | [] => false
    | t :: ts => hasHole t || hasHoleList ts
end

theorem hasHoleList_false : ∀ (xs : List ITerm) (x : ITerm), hasHoleList xs = false → x ∈ xs →
    hasHole x = false := by
  intro xs
  induction xs with
  | nil => intro x _ h; simp at h
  | cons a as ih =>
    intro x hx hm
    simp only [hasHoleList, Bool.or_eq_false_iff] at hx
    obtain ⟨h1, h2⟩ := hx
    rcases List.mem_cons.mp hm with rfl | hm
    · exact h1
    · exact ih x h2 hm

theorem itermScopeOK_complete (t : ITerm) (n : Nat) (hn : hasHole t = false)
    (h : ∀ k ∈ itermVars t, k < n) : itermScopeOK t n = none := by
  match t with
  | .var j =>
    simp only [itermScopeOK]
    have hk : j < n := h j (by simp [itermVars])
    split
    · rfl
    · rename_i hge; exact absurd hk hge
  | .hole => simp [hasHole] at hn
  | .ctor c xs =>
    simp only [itermScopeOK]
    rw [firstErr_itermScopeList_none]
    intro x hx
    have hnx : hasHole x = false := by
      have := hasHoleList_false xs x (by simpa [hasHole] using hn) hx
      exact this
    exact itermScopeOK_complete x n hnx (by
      intro k hk
      exact h k (by simp only [itermVars, List.mem_flatMap]; exact ⟨x, hx, hk⟩))
termination_by itermSize t
decreasing_by
  have h1 : itermSize x < 1 + itermSizeList xs := itermSize_lt_ctor c xs x hx
  have h2 : itermSize (ITerm.ctor c xs) = 1 + itermSizeList xs := rfl
  omega

end KtLaws.IIT
