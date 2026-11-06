/-
  KtLaws/Simplicial.lean — 有限單純複形、Betti 數、覆蓋的神經
  對應 MoonBit `meta/core/complex.mbt`（18 條定律）

  兩件事在這裡被「從取樣升級成定理」：

  * **Euler–Poincaré**：`χ = Σ(−1)^k f_k = Σ(−1)^k b_k`。MoonBit 側是在兩個具體複形上
    各跑一次；這裡`euler_poincare` 對**任意** f-向量與秩序列證明（只要最低秩與最高秩為 0，
    也就是「鏈複形集中在中間維度」），並用 `euler_poincare_complex` 套到所有有限複形。
  * **Betti 數**：MoonBit 用高斯消去算 `rank_int`；這裡改用**秩的定義本身**——
    「最大非零子式的階」，行列式用整數 Laplace 展開算，於是完全不碰除法與浮點，
    也不需要 Mathlib 的線性代數。
-/
namespace KtLaws.Simplicial

abbrev Face := List Nat
abbrev Mat := List (List Int)

/-- 正負號 `(+1, −1, +1, …)`。 -/
def sgn : Nat → Int
  | 0 => 1
  | n + 1 => -sgn n

/-- 交替和 `Σ_{k<n} (−1)^k g k`（尾端遞迴，所以 `altSum (n+1) g = altSum n g + sgn n * g n` 是定義展開）。 -/
def altSumF : Nat → (Nat → Int) → Int
  | 0, _ => 0
  | n + 1, g => altSumF n g + sgn n * g n

/-- 對清單取交替和。 -/
def altSumL (l : List Int) : Int := altSumF l.length (fun k => l.getD k 0)

/-! ### 面與複形 -/

/-- 移除第 `i` 個元素。 -/
def eraseAt {α} : List α → Nat → List α
  | [], _ => []
  | _ :: t, 0 => t
  | a :: t, n + 1 => a :: eraseAt t n

/-- 全部子集（輸入升冪 ⇒ 每個子集也升冪）。 -/
def subsets : Face → List Face
  | [] => [[]]
  | a :: t => let s := subsets t; s ++ s.map (fun x => a :: x)

/-- 由極大面取向下封閉得到的全部非空面（去重、保序）。 -/
def allFaces (maximal : List Face) : List Face :=
  (maximal.map (fun f => (subsets f).filter (fun s => !s.isEmpty))).flatten.eraseDups

/-- 有限單純複形：頂點數＋全部面。 -/
structure Complex where
  verts : Nat
  faces : List Face

/-- 由極大面建複形（向下封閉）。 -/
def ofMaximal (n : Nat) (maximal : List Face) : Complex :=
  { verts := n, faces := allFaces maximal }

/-- 第 `k` 層：所有 `k`-單形（恰有 `k+1` 個頂點）。 -/
def layer (c : Complex) (k : Nat) : List Face :=
  c.faces.filter (fun f => f.length == k + 1)

/-- 最高維度。 -/
def maxdim (c : Complex) : Nat :=
  c.faces.foldl (fun m f => Nat.max m (f.length - 1)) 0

/-- `f_k`（以整數表示，方便取交替和）。 -/
def fF (c : Complex) (k : Nat) : Int := ((layer c k).length : Int)

/-- f-向量。 -/
def fVector (c : Complex) : List Nat :=
  (List.range (maxdim c + 1)).map (fun k => (layer c k).length)

/-- Euler 示性數 `χ = Σ (−1)^k f_k`。 -/
def euler (c : Complex) : Int := altSumF (maxdim c + 1) (fF c)

/-! ### 邊界算子與秩 -/

/-- `k`-面 `f` 對 `(k−1)`-面 `r` 的邊界係數 `Σ_i (−1)^i [f∖i = r]`。 -/
def bEntry (f r : Face) : Int :=
  ((List.range f.length).map (fun i => if eraseAt f i = r then sgn i else 0)).sum

/-- 轉置（各行等長）。 -/
def transpose (M : Mat) : Mat :=
  (List.range (M.headD []).length).map (fun j => M.map (fun r => r.getD j 0))

/-- 邊界矩陣 `∂_k`：列 = `(k−1)`-面，行 = `k`-面（`k = 0` 時為空矩陣）。 -/
def boundary (c : Complex) (k : Nat) : Mat :=
  match k with
  | 0 => []
  | k + 1 => transpose ((layer c (k + 1)).map (fun f => (layer c k).map (fun r => bEntry f r)))

/-- 兩向量的內積。 -/
def dot (u v : List Int) : Int := (u.zipWith (fun a b => a * b) v).sum

/-- 矩陣乘法。 -/
def matMul (A B : Mat) : Mat :=
  A.map (fun row =>
    (List.range (B.headD []).length).map (fun j =>
      dot row (B.map (fun r => r.getD j 0))))

/-- 鏈複形條件 `∂_k ∘ ∂_{k+1} = 0`。 -/
def chainOK (c : Complex) : Bool :=
  (List.range (maxdim c + 2)).all (fun k =>
    (matMul (boundary c k) (boundary c (k + 1))).all (fun row => row.all (fun x => x == 0)))

/-- 刪掉第 `j` 行。 -/
def dropCol (M : Mat) (j : Nat) : Mat := M.map (fun r => eraseAt r j)

/-- 行列式（第一列 Laplace 展開）。以「剩幾列」當遞迴度量。 -/
def detGo : Nat → Mat → Int
  | 0, _ => 1
  | _ + 1, [] => 1
  | n + 1, row :: rest =>
    (List.range row.length).foldl (fun acc j =>
      acc + (if j % 2 == 0 then 1 else -1) * (row.getD j 0) * detGo n (dropCol rest j)) 0

/-- 行列式（方陣）。 -/
def det (M : Mat) : Int := detGo M.length M

/-- 依指標集取子矩陣。 -/
def subMat (M : Mat) (rows cols : List Nat) : Mat :=
  rows.map (fun i => cols.map (fun j => (M.getD i []).getD j 0))

/-- `{0,…,2^n−1}` → 全部指標子集。 -/
def idxSets (n : Nat) : List (List Nat) :=
  (List.range (2 ^ n)).map (fun m => (List.range n).filter (fun i => (m / 2 ^ i) % 2 == 1))

/-- 有沒有非零的 `k×k` 子式（只比較大小為 `k` 的指標集，否則空子式會恆為 1）。 -/
def hasMinor (M : Mat) (k : Nat) : Bool :=
  (idxSets M.length).any (fun rs => rs.length == k && (idxSets (M.headD []).length).any (fun cs =>
    cs.length == k && !(det (subMat M rs cs) == 0)))

/-- **秩 = 最大非零子式的階**。這是秩的標準刻畫（在 `ℚ` 上與「極大獨立列數」等價），
    用整數行列式算，所以不需要除法。 -/
def matRank (M : Mat) : Nat :=
  (List.range (Nat.min M.length (M.headD []).length + 1)).foldl
    (fun acc k => if hasMinor M k then k else acc) 0

/-- `rank ∂_k`（整數版）。 -/
def rankF (c : Complex) (k : Nat) : Int := (matRank (boundary c k) : Int)

/-- Betti 數 `b_k = f_k − rank ∂_k − rank ∂_{k+1}`。 -/
def bettiF (c : Complex) (k : Nat) : Int := fF c k - rankF c k - rankF c (k + 1)

/-- Betti 向量。 -/
def bettiVector (c : Complex) : List Int :=
  (List.range (maxdim c + 1)).map (fun k => bettiF c k)

/-- 由 Betti 數算的 χ。 -/
def eulerBetti (c : Complex) : Int := altSumF (maxdim c + 1) (bettiF c)

/-! ### 一般定理：交替和是線性的、成對項望遠鏡化、Euler–Poincaré -/

theorem altSum_add (n : Nat) (a b : Nat → Int) :
    altSumF n (fun k => a k + b k) = altSumF n a + altSumF n b := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show altSumF n (fun k => a k + b k) + sgn n * (a n + b n)
      = (altSumF n a + sgn n * a n) + (altSumF n b + sgn n * b n)
    rw [ih, Int.mul_add]
    omega

theorem altSum_sub (n : Nat) (a b : Nat → Int) :
    altSumF n (fun k => a k - b k) = altSumF n a - altSumF n b := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show altSumF n (fun k => a k - b k) + sgn n * (a n - b n)
      = (altSumF n a + sgn n * a n) - (altSumF n b + sgn n * b n)
    rw [ih, Int.mul_sub]
    omega

/-- 相鄰成對項：`Σ_{k<n} (−1)^k (r_k + r_{k+1}) = r_0 − (−1)^n r_n`。 -/
theorem altSum_pair (n : Nat) (r : Nat → Int) :
    altSumF n (fun k => r k + r (k + 1)) = r 0 - sgn n * r n := by
  induction n with
  | zero =>
    show (0 : Int) = r 0 - 1 * r 0
    simp
  | succ n ih =>
    show altSumF n (fun k => r k + r (k + 1)) + sgn n * (r n + r (n + 1))
      = r 0 - sgn (n + 1) * r (n + 1)
    rw [ih, Int.mul_add]
    have hs : sgn (n + 1) = -sgn n := rfl
    rw [hs, Int.neg_mul]
    omega

/-- **Euler–Poincaré（一般形式）**：若秩序列在兩端為 0（`r_0 = 0`、`r_n = 0`），
    則由 `b_k = f_k − r_k − r_{k+1}` 定義的 Betti 數滿足 `Σ(−1)^k b_k = Σ(−1)^k f_k`。
    證明只是把 `r_k` 與 `r_{k+1}` 配對望遠鏡化，不需要任何維度理論。 -/
theorem euler_poincare (n : Nat) (f r : Nat → Int) (h0 : r 0 = 0) (hn : r n = 0) :
    altSumF n (fun k => f k - r k - r (k + 1)) = altSumF n f := by
  have hb : altSumF n (fun k => f k - r k - r (k + 1))
      = altSumF n (fun k => (f k - r k) - r (k + 1)) := rfl
  rw [hb, altSum_sub, altSum_sub]
  have hpair : altSumF n r + altSumF n (fun k => r (k + 1)) = 0 := by
    rw [← altSum_add n r (fun k => r (k + 1)), altSum_pair n r, h0, hn]
    simp
  omega

/-! ### 最高維度的界：`∂` 在頂端是空矩陣（把 Euler–Poincaré 套到所有複形上） -/

theorem le_foldl_max (init : Nat) (l : List Face) :
    init ≤ l.foldl (fun m f => Nat.max m (f.length - 1)) init := by
  induction l generalizing init with
  | nil => exact Nat.le_refl init
  | cons a t ih =>
    show init ≤ List.foldl (fun m f => Nat.max m (f.length - 1)) (Nat.max init (a.length - 1)) t
    exact Nat.le_trans (Nat.le_max_left init (a.length - 1)) (ih (Nat.max init (a.length - 1)))

theorem maxdim_bound (l : List Face) (init : Nat) :
    ∀ f ∈ l, f.length - 1 ≤ l.foldl (fun m g => Nat.max m (g.length - 1)) init := by
  induction l generalizing init with
  | nil => intro f hf; cases hf
  | cons a t ih =>
    intro f hf
    simp only [List.mem_cons] at hf
    rcases hf with rfl | hf'
    · show f.length - 1 ≤ List.foldl (fun m g => Nat.max m (g.length - 1)) (Nat.max init (f.length - 1)) t
      exact Nat.le_trans (Nat.le_max_right init (f.length - 1)) (le_foldl_max _ t)
    · exact ih (Nat.max init (a.length - 1)) f hf'

theorem filter_eq_nil {α : Type} (l : List α) (p : α → Bool) (h : ∀ x ∈ l, p x = false) :
    l.filter p = [] := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    have ha : p a = false := h a (by simp)
    cases hp : p a with
    | false =>
      have hstep : (a :: t).filter p = t.filter p := by simp [List.filter, hp]
      rw [hstep]
      exact ih (fun x hx => h x (by simp [hx]))
    | true =>
      rw [ha] at hp
      exact Bool.noConfusion hp

theorem layer_top (c : Complex) : layer c (maxdim c + 1) = [] := by
  unfold layer
  apply filter_eq_nil
  intro f hf
  have hb : f.length - 1 ≤ maxdim c := maxdim_bound c.faces 0 f hf
  have hne : f.length ≠ maxdim c + 1 + 1 := by omega
  cases h : (f.length == maxdim c + 1 + 1) with
  | false => rfl
  | true => exact absurd (beq_iff_eq.mp h) hne

theorem boundary_top (c : Complex) : boundary c (maxdim c + 1) = [] := by
  show transpose ((layer c (maxdim c + 1)).map
    (fun f => (layer c (maxdim c)).map (fun r => bEntry f r))) = []
  rw [layer_top]
  rfl

theorem matRank_empty : matRank ([] : Mat) = 0 := by decide

theorem rankF_zero (c : Complex) : rankF c 0 = 0 := by
  show ((matRank ([] : Mat) : Nat) : Int) = 0
  rw [matRank_empty]
  rfl

theorem rankF_top (c : Complex) : rankF c (maxdim c + 1) = 0 := by
  show ((matRank (boundary c (maxdim c + 1)) : Nat) : Int) = 0
  rw [boundary_top c, matRank_empty]
  rfl

/-- **Euler–Poincaré（所有有限複形）**：`Σ(−1)^k b_k = χ`。
    前提只有「`∂` 在 0 維與最高維為空矩陣」，上面兩個 `rankF_*` 給出。 -/
theorem euler_poincare_complex (c : Complex) : eulerBetti c = euler c :=
  euler_poincare (maxdim c + 1) (fF c) (rankF c) (rankF_zero c) (rankF_top c)

/-! ### 覆蓋的神經 -/

/-- 兩集合交集。 -/
def inter (a b : Face) : Face := a.filter (fun x => b.contains x)

/-- 一組貼片的共同交集。 -/
def interAll (cover : List Face) (patches : List Nat) : Face :=
  match patches with
  | [] => []
  | p :: ps => ps.foldl (fun acc i => inter acc (cover.getD i [])) (cover.getD p [])

/-- 覆蓋的神經：貼片為頂點，交集非空的一組貼片張成單形。 -/
def nerve (cover : List Face) : Complex :=
  let m := cover.length
  ofMaximal m ((List.range (2 ^ m)).filterMap (fun mask =>
    let patches := (List.range m).filter (fun i => (mask / 2 ^ i) % 2 == 1)
    if patches.isEmpty then none
    else if (interAll cover patches).isEmpty then none
    else some patches))

/-- 黏合判準：`H¹(nerve) = 0 ⟺ 兩兩相容升級為全域相容`。 -/
def coverGlues (cover : List Face) : Bool := bettiF (nerve cover) 1 == 0

/-- 障礙見證：三個貼片兩兩相交、三者共交卻為空。 -/
def coverObstruction (cover : List Face) : Option (Nat × Nat × Nat) :=
  let m := cover.length
  ((List.range m).flatMap (fun i =>
    (List.range m).flatMap (fun j => (List.range m).map (fun k => (i, j, k))))).findSome?
    (fun t =>
      let (i, j, k) := t
      if decide (i < j ∧ j < k)
          && !(inter (cover.getD i []) (cover.getD j [])).isEmpty
          && !(inter (cover.getD j []) (cover.getD k [])).isEmpty
          && !(inter (cover.getD k []) (cover.getD i [])).isEmpty
          && (inter (inter (cover.getD i []) (cover.getD j [])) (cover.getD k [])).isEmpty
        then some t else none)

/-! ### 具體複形與覆蓋 -/

/-- 三角形邊界 ≅ S¹（3 頂點、3 邊）。 -/
def circle : Complex := ofMaximal 3 [[0, 1], [1, 2], [0, 2]]

/-- 實心三角形（2-單形）。 -/
def disk : Complex := ofMaximal 3 [[0, 1, 2]]

/-- 兩個孤立點。 -/
def twoPoints : Complex := ofMaximal 2 [[0], [1]]

/-- 兩片貼片、交集非空（nerve 是一條邊 ⇒ 收縮 ⇒ 可黏）。 -/
def triCover : List Face := [[0, 1, 2], [2, 3, 4]]

/-- 三片兩兩相交、三者共交為空（nerve ≅ S¹ ⇒ `H¹ = ℚ` ⇒ 不可黏）。 -/
def badCover : List Face := [[0, 1], [1, 2], [2, 0]]

/-- 三片共同相交（nerve 是實心三角形 ⇒ 可黏）。 -/
def goodCover : List Face := [[0, 1, 2], [1, 2, 3], [0, 2, 3]]

/-! ### 定理（對應 MoonBit `complex.mbt` 的 18 條標籤） -/

theorem circle_euler : euler circle = 0 := by decide

theorem circle_betti_zero : bettiF circle 0 = 1 := by decide

theorem circle_betti_one : bettiF circle 1 = 1 := by decide

theorem circle_chain : chainOK circle = true := by decide

theorem disk_euler : euler disk = 1 := by decide

theorem disk_betti_one : bettiF disk 1 = 0 := by decide

theorem disk_betti_two : bettiF disk 2 = 0 := by decide

theorem disk_f_vector_len : 3 ≤ (fVector disk).length := by decide

theorem disk_f0_ge_f1 : (fVector disk).getD 1 0 ≤ (fVector disk).getD 0 0 := by decide

theorem disk_f_vector_alt :
    altSumL ((fVector disk).map Int.ofNat) = euler disk := by decide

theorem twoPoints_euler : euler twoPoints = 2 := by decide

theorem good_cover_glues : coverGlues triCover = true := by decide

theorem good_cover_no_obstruction : coverObstruction triCover = none := by decide

theorem bad_cover_not_glues : coverGlues badCover = false := by decide

theorem bad_cover_obstruction : coverObstruction badCover = some (0, 1, 2) := by decide

theorem good2_cover_glues : coverGlues goodCover = true := by decide

theorem good2_cover_no_obstruction : coverObstruction goodCover = none := by decide

end KtLaws.Simplicial
