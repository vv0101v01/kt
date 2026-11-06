/-
  KtLaws/IIT/Extra.lean — 歸納-歸納剩下的兩個樣本族：佔位符被拒、有限 schema 的穩定化
  對應 MoonBit `meta/iit/schema.mbt` 的
    「iit: schema placeholders are rejected」(2) 與
    「iit: a finite mutual schema does stabilize」(4)

  為什麼獨立成一個檔：這兩族的樣本在 `Examples.lean` 之外（一個要造不良 schema，
  一個要看更後面的階段），但用的都是同一批全稱定義（`ichemaOK` / `iitEnumerate`）。
-/
import KtLaws.IIT.Examples

namespace KtLaws.IIT

/-! ### 1. 佔位符被拒（2 條） -/

/-- 把 `Nat/Fin` 的 `fz` 索引換成佔位符 `hole`：必須被判成不良構。 -/
def schemaNatFinHole : ISchema :=
  { sortNames := ["Nat", "Fin"], arities := [0, 1],
    ctors := [
      ⟨"z", 0, [], []⟩,
      ⟨"s", 0, [], [IArg.recArg 0 []]⟩,
      ⟨"fz", 1, [ITerm.hole], [IArg.val 0]⟩,
      ⟨"fs", 1, [ITerm.ctor 1 [ITerm.var 0]], [IArg.val 0, IArg.recArg 1 [ITerm.var 0]]⟩ ] }

/-- 佔位符 #1：正常的 `Nat/Fin` schema 通過良構性檢查。 -/
theorem hole_natFin_ok : ichemaOK schemaNatFin = none := natFin_schema_ok

/-- 佔位符 #2：把索引表達式換成佔位符之後，`ichemaOK` 一定回報錯誤（不是悄悄放行）。 -/
theorem hole_rejected : (ichemaOK schemaNatFinHole).isSome = true := by decide

/-! ### 2. 有限互遞迴 schema 會穩定下來（4 條） -/

/-- 穩定化 #1：第 4 階段（`A` 有 2 個、`B` 有 1 個居民）。 -/
theorem finite_stage4_stable :
    (iitEnumerate schemaFinite 4 64 0).length = 2 ∧
      (iitEnumerate schemaFinite 4 64 1).length = 1 := finite_stage4

/-- 穩定化 #2：第 7 階段（`a0`、`a1(b0)`）。 -/
theorem finite_stage7_stable :
    (iitEnumerate schemaFinite 7 64 0).length = 2 ∧
      (iitEnumerate schemaFinite 7 64 1).length = 1 := finite_stage7

/-- 穩定化 #3：再往後推不變 —— 第 8 階段的居民數與第 7 階段相同。 -/
theorem finite_stage8_same :
    (iitEnumerate schemaFinite 8 64 0).length =
      (iitEnumerate schemaFinite 7 64 0).length := by decide

/-- 穩定化 #4：第 10 階段仍然相同（有限 schema 的 Kleene 鏈真的停住）。 -/
theorem finite_stage10_same :
    (iitEnumerate schemaFinite 10 64 0).length =
      (iitEnumerate schemaFinite 8 64 0).length := by decide

end KtLaws.IIT
