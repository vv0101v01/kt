/-
  KtLaws/IIT/Examples.lean — 三個 II 實例與 MoonBit `meta/iit/examples.mbt` 的定律
  （STLC 專屬的 β／主體約簡／弱化／正規化在 `KtLaws/IIT/STLC.lean`）

  Even/Odd  ：互遞迴（索引為空）→ 單一自函子的初始代數就夠，族無限、不穩定
  Nat/Fin   ：II（索引是前一族的**項**）→ 需要切片塔上的固定點，`Fin` 落後 `Nat` 一階
  有限 schema：A = a0 | a1(B)，B = b0 → 鏈在第 3 階段後恆定

  這裡的具體計數（1/1、2/2、6、0、1、2、3…）與 MoonBit 側逐項相同；
  而「每個居民都良構」「落在正確的 sort」這兩件事不是逐項比對，而是
  由 `KtLaws/IIT/Schema.lean` 的 `enumerate_sound` / `enumerate_sort` **推**出來的。
-/
import KtLaws.IIT.Schema

namespace KtLaws.IIT

/-! ### 三個 schema -/

/-- `Even/Odd`：互遞迴但沒有索引（`ez : Even`、`eo : Odd → Even`、`oz : Odd`、`oe : Even → Odd`）。 -/
def schemaEvenOdd : ISchema :=
  { sortNames := ["Even", "Odd"], arities := [0, 0],
    ctors := [
      ⟨"ez", 0, [], []⟩,
      ⟨"eo", 0, [], [IArg.recArg 1 []]⟩,
      ⟨"oz", 1, [], []⟩,
      ⟨"oe", 1, [], [IArg.recArg 0 []]⟩ ] }

/-- `Nat/Fin`：II 的最小例子（`Fin` 的索引是 `Nat` 的**項**）。 -/
def schemaNatFin : ISchema :=
  { sortNames := ["Nat", "Fin"], arities := [0, 1],
    ctors := [
      ⟨"z", 0, [], []⟩,
      ⟨"s", 0, [], [IArg.recArg 0 []]⟩,
      ⟨"fz", 1, [ITerm.ctor 1 [ITerm.var 0]], [IArg.val 0]⟩,
      ⟨"fs", 1, [ITerm.ctor 1 [ITerm.var 0]],
        [IArg.val 0, IArg.recArg 1 [ITerm.var 0]]⟩ ] }

/-- 有限互遞迴 schema：`A = a0 | a1(B)`、`B = b0`。 -/
def schemaFinite : ISchema :=
  { sortNames := ["A", "B"], arities := [0, 0],
    ctors := [
      ⟨"a0", 0, [], []⟩,
      ⟨"a1", 0, [], [IArg.recArg 1 []]⟩,
      ⟨"b0", 1, [], []⟩ ] }

/-- `Nat` 的建構子。 -/
def natZ : IVal := IVal.mk 0 []

def natS (n : IVal) : IVal := IVal.mk 1 [n]

/-- 第 `n` 個自然數（`sⁿ z`）。 -/
def natOf : Nat → IVal
  | 0 => natZ
  | n + 1 => natS (natOf n)

/-! ### 索引依賴圖的可達性（Floyd–Warshall 的迭代版） -/

/-- 一步傳遞閉包。 -/
def rstep (n : Nat) (r : Nat → Nat → Bool) : Nat → Nat → Bool :=
  fun i j => r i j || ((List.range n).any (fun k => r i k && r k j))

/-- 自反傳遞閉包：跑 `n` 輪（`n` 是節點數就足夠）。 -/
def reachC (n : Nat) (edges : List (Nat × Nat)) : Nat → Nat → Bool :=
  Nat.rec (fun i j => edges.any (fun e => e.1 == i && e.2 == j))
    (fun _ r => rstep n r) n

/-- 依賴圖有沒有「跨節點的環」。 -/
def acyclic (n : Nat) (edges : List (Nat × Nat)) : Bool :=
  !((List.range n).any (fun i => (List.range n).any (fun j =>
      i != j && reachC n edges i j && reachC n edges j i)))

/-! ### 度量（`ω^{size}`） -/

/-- 終止性度量：`ω^{size}`（與 MoonBit 的 `iit_measure` 相同）。 -/
def iitMeasure (v : IVal) : KtLaws.Ordinal.Ordinal := KtLaws.Ordinal.ordOmegaPow (KtLaws.Ordinal.ordOfNat (ivalSize v))

/-- 每個**遞迴**參數的度量都嚴格小於父項。 -/
def recArgsDecrease (s : ISchema) (v : IVal) : Bool :=
  match v with
  | ⟨c, args⟩ =>
    match s.ctors[c]? with
    | none => true
    | some ct =>
      (ct.args.zip args).all (fun p =>
        match p.1 with
        | .val _ => true
        | .recArg _ _ => KtLaws.Ordinal.cmp (iitMeasure p.2) (iitMeasure v) == .lt)

/-! ### Even/Odd 的定律（7 條） -/

theorem evenOdd_schema_ok : ichemaOK schemaEvenOdd = none := by decide

theorem evenOdd_stage1 :
    (iitEnumerate schemaEvenOdd 1 64 0).length = 1 ∧
    (iitEnumerate schemaEvenOdd 1 64 1).length = 1 := by decide

theorem evenOdd_stage2 :
    (iitEnumerate schemaEvenOdd 2 64 0).length = 2 ∧
    (iitEnumerate schemaEvenOdd 2 64 1).length = 2 := by decide

theorem evenOdd_stage6 : (iitEnumerate schemaEvenOdd 6 64 0).length = 6 := by decide

theorem evenOdd_grows : (iitEnumerate schemaEvenOdd 2 64 0).length
    < (iitEnumerate schemaEvenOdd 6 64 0).length := by decide

theorem evenOdd_sound : ∀ (fuel cap srt : Nat) (v : IVal),
    v ∈ iitEnumerate schemaEvenOdd fuel cap srt → icheck schemaEvenOdd v = true :=
  enumerate_sound schemaEvenOdd

theorem evenOdd_sorted : ∀ (fuel cap srt : Nat) (v : IVal),
    v ∈ iitEnumerate schemaEvenOdd fuel cap srt → isortOf schemaEvenOdd v = some srt :=
  enumerate_sort schemaEvenOdd

/-! ### 有限 schema 的定律（4 條）：鏈會穩定 -/

theorem finite_stage4 :
    (iitEnumerate schemaFinite 4 64 0).length = 2 ∧
    (iitEnumerate schemaFinite 4 64 1).length = 1 := by decide

theorem finite_stage7 :
    (iitEnumerate schemaFinite 7 64 0).length = 2 ∧
    (iitEnumerate schemaFinite 7 64 1).length = 1 := by decide

/-! ### Nat/Fin 的定律（14 條）：索引檢查與一階相位差 -/

theorem natFin_schema_ok : ichemaOK schemaNatFin = none := by decide

/-- 第 1 階段：`Fin` 一個居民也生不出來（`Nat` 還是空的）。 -/
theorem natFin_stage1_fin_empty : (iitEnumerate schemaNatFin 1 128 1).length = 0 := by decide

theorem natFin_stage2 :
    (iitEnumerate schemaNatFin 2 128 0).length = 2 ∧
    1 ≤ (iitEnumerate schemaNatFin 2 128 1).length := by decide

theorem natFin_stage3 :
    (iitEnumerate schemaNatFin 3 512 0).length = 3 ∧
    3 ≤ (iitEnumerate schemaNatFin 3 512 1).length := by decide

/-- `fz z : Fin (s z)` 通過索引檢查，且真的落在 `Fin`。 -/
theorem natFin_fz_z_checks :
    icheck schemaNatFin (IVal.mk 2 [natZ]) = true ∧
    isortOf schemaNatFin (IVal.mk 2 [natZ]) = some 1 := by decide

/-- `fz z` 的索引是 `s z`（只有一個分量）。 -/
theorem natFin_fz_z_index :
    itermEqList (iindexOf schemaNatFin (IVal.mk 2 [natZ])) [itermOfVal (natOf 1)] = true := by decide

/-- 內層索引不匹配的 `fs` 被拒。 -/
theorem natFin_fs_bad1_rejected :
    icheck schemaNatFin (IVal.mk 3 [natOf 1, IVal.mk 3 [natOf 0, IVal.mk 2 [natOf 0]]]) = false := by decide

/-- 正確的 `fs (s z) (fz z) : Fin (s (s z))`。 -/
theorem natFin_fs_ok :
    icheck schemaNatFin (IVal.mk 3 [natOf 1, IVal.mk 2 [natOf 0]]) = true := by decide

theorem natFin_fs_ok_index :
    itermEqList (iindexOf schemaNatFin (IVal.mk 3 [natOf 1, IVal.mk 2 [natOf 0]])) [itermOfVal (natOf 2)] = true := by decide

/-- `fs (z, fz z)` 被拒：`fz z : Fin (s z)`，不是 `Fin z`。 -/
theorem natFin_fs_bad2_rejected :
    icheck schemaNatFin (IVal.mk 3 [natOf 0, IVal.mk 2 [natOf 0]]) = false := by decide

/-- `icheckAt` 說「`fz z` 就是 `Fin` 的那個索引」。 -/
theorem natFin_fz_z_at :
    icheckAt schemaNatFin (IVal.mk 2 [natZ]) 1 [itermOfVal (natOf 1)] = true := by decide

/-- 同一個值不能宣稱另一個索引。 -/
theorem natFin_fz_z_at_wrong :
    icheckAt schemaNatFin (IVal.mk 2 [natZ]) 1 [itermOfVal (natOf 2)] = false := by decide

/-! ### Kleene 鏈的定律（4 條） -/

theorem natFin_monotone : ∀ (cap srt : Nat) (v : IVal),
    v ∈ iitEnumerate schemaNatFin 2 cap srt → v ∈ iitEnumerate schemaNatFin 4 cap srt :=
  fun cap srt v h => enumerate_mono schemaNatFin 3 cap srt v (enumerate_mono schemaNatFin 2 cap srt v h)

theorem natFin_chain_sound : ∀ (fuel cap srt : Nat) (v : IVal),
    v ∈ iitEnumerate schemaNatFin fuel cap srt → icheck schemaNatFin v = true :=
  enumerate_sound schemaNatFin

theorem natFin_chain_sorted : ∀ (fuel cap srt : Nat) (v : IVal),
    v ∈ iitEnumerate schemaNatFin fuel cap srt → isortOf schemaNatFin v = some srt :=
  enumerate_sort schemaNatFin

theorem natFin_chain_grows :
    (iitEnumerate schemaNatFin 2 256 0).length < (iitEnumerate schemaNatFin 4 256 0).length := by
  decide

/-! ### 消除器的 ι 律與終止性（3 條） -/

/-- ι 律：對**任意**項成立（不只枚舉出來的樣本）。 -/
theorem iota_law (v : IVal) : iitFold schemaNatFin ivalRebuild v = v :=
  iit_fold_iota schemaNatFin v

/-- 每個子項都通過「自己再往下檢查」。 -/
theorem termination_certified (v : IVal) : subtermDecrease schemaNatFin v = true :=
  subterm_decrease schemaNatFin v

/-- **父項度量嚴格大於子項**：`iitMeasure = ω^{ivalSize}`，而 `ω^·` 嚴格單調，
    所以終止性憑證的內容就是下面的嚴格下降——對任意建構子、任意參數成立，
    不需要枚舉樣本。 -/
theorem measure_decrease (c : Nat) (args : List IVal) (a : IVal) (h : a ∈ args) :
    ivalSize a < ivalSize (IVal.mk c args) :=
  ivalSize_lt_of_mem args a h

/-! ### 索引依賴圖的定律（3 條） -/

theorem evenOdd_index_acyclic : acyclic 2 (indexEdges schemaEvenOdd) = true := by decide

theorem natFin_index_acyclic : acyclic 2 (indexEdges schemaNatFin) = true := by decide

theorem finite_index_acyclic : acyclic 2 (indexEdges schemaFinite) = true := by decide

/-- 對照：**資料**依賴圖允許有環（Even/Odd 就是互遞迴）。 -/
theorem evenOdd_data_cycle :
    (sortEdges schemaEvenOdd).any (fun e => e.1 == 0 && e.2 == 1) = true ∧
    (sortEdges schemaEvenOdd).any (fun e => e.1 == 1 && e.2 == 0) = true := by decide

/-- Even/Odd 完全沒有索引依賴。 -/
theorem evenOdd_no_index_edges : indexEdges schemaEvenOdd = [] := by decide

end KtLaws.IIT
