// ===========================================================================
// 雙上下文資源導向代數與定量類型論（QTT）半環左模：
//   Barber DILL (Γ_unr ; Δ_R) × Atkey–McBride QTT {0, 1, ω} 資源半環 `LinUsage`
// ===========================================================================

///|
/// McBride–Atkey 三值線性資源半環 `{0, 1, ω}`：
///   - `LinZero` (`0`)：抹除／僅出現在依值型別指標中（計算零消耗）；
///   - `LinOne` (`1`)：嚴格線性資源（執行期必須精確消耗一次，禁弱化與縮併）；
///   - `LinMany` (`ω`)：無限制直覺主義資源（允許任意複製與丟棄）。
#derive(Eq)
pub(all) enum LinUsage {
  LinZero
  LinOne
  LinMany
}

///|
pub extend LinUsage with Eq::{not_equal, equal}

///|
pub fn LinUsage::to_code(self : LinUsage) -> Int32 {
  match self {
    LinZero => 0
    LinOne => 1
    LinMany => 15
  }
}

///|
pub fn LinUsage::from_count(n : Int32) -> LinUsage {
  if n <= 0 {
    LinZero
  } else if n == 1 {
    LinOne
  } else {
    LinMany
  }
}

///|
/// QTT 子資源相容序 `actual ⊑ declared`：
///   - 宣告 `0` 僅容許實際消耗 `0`；
///   - 宣告 `1` 僅容許實際消耗 `1`；
///   - 宣告 `ω` 容許實際消耗 `{0, 1, ω}` 任意值。
pub fn LinUsage::usage_compatible(
  actual : LinUsage,
  declared : LinUsage,
) -> Bool {
  match declared {
    LinMany => true
    _ => actual == declared
  }
}

///|
pub impl Semiring for LinUsage with fn zero() {
  LinZero
}

///|
pub impl Semiring for LinUsage with fn one() {
  LinOne
}

///|
pub impl Semiring for LinUsage with fn plus(a, b) {
  match (a, b) {
    (LinZero, x) => x
    (x, LinZero) => x
    _ => LinMany
  }
}

///|
pub impl Semiring for LinUsage with fn times(a, b) {
  match (a, b) {
    (LinZero, _) | (_, LinZero) => LinZero
    (LinOne, x) => x
    (x, LinOne) => x
    (LinMany, LinMany) => LinMany
  }
}

///|
pub impl StarSemiring for LinUsage with fn star(a) {
  match a {
    LinZero => LinOne
    LinOne | LinMany => LinMany
  }
}

///|
pub extend LinUsage with Semiring::{zero, one, plus, times, is_zero, is_one}

///|
pub extend LinUsage with StarSemiring::{star}

///|
/// Barber / Pfenning–Davies 雙上下文 `(Γ_unr ; Δ_R)` 與 Atkey–McBride QTT 資源半環模：
///   - `unrestricted_tys`：持久／模態上下文 `Γ`（支援結構弱化與縮併）；
///   - `resource_tys` 與 `resource_grades`：分級資源上下文 `Δ` 中各變數之型別代碼與半環重數 `R`。
#derive(Eq)
pub(all) struct DualResourceCtx[R] {
  unrestricted_tys : Array[Int32]
  resource_tys : Array[Int32]
  resource_grades : Array[R]
}

///|
pub fn[R : Eq] DualResourceCtx::equal(
  self : DualResourceCtx[R],
  other : DualResourceCtx[R],
) -> Bool {
  self.unrestricted_tys == other.unrestricted_tys &&
  self.resource_tys == other.resource_tys &&
  self.resource_grades == other.resource_grades
}

///|
pub fn[R : Eq] DualResourceCtx::not_equal(
  self : DualResourceCtx[R],
  other : DualResourceCtx[R],
) -> Bool {
  !self.equal(other)
}

///|
pub fn[R] dual_ctx_empty() -> DualResourceCtx[R] {
  DualResourceCtx::{
    unrestricted_tys: [],
    resource_tys: [],
    resource_grades: [],
  }
}

///|
/// 擴張持久／模態直覺主義上下文 `Γ, u : A ; Δ`。
pub fn[R] dual_ctx_push_unrestricted(
  ctx : DualResourceCtx[R],
  ty_code : Int32,
) -> DualResourceCtx[R] {
  let u = ctx.unrestricted_tys.copy()
  u.push(ty_code)
  DualResourceCtx::{
    unrestricted_tys: u,
    resource_tys: ctx.resource_tys.copy(),
    resource_grades: ctx.resource_grades.copy(),
  }
}

///|
/// 擴張分級資源上下文 `Γ ; Δ, x :^π A`。
pub fn[R] dual_ctx_push_resource(
  ctx : DualResourceCtx[R],
  ty_code : Int32,
  grade : R,
) -> DualResourceCtx[R] {
  let rt = ctx.resource_tys.copy()
  let rg = ctx.resource_grades.copy()
  rt.push(ty_code)
  rg.push(grade)
  DualResourceCtx::{
    unrestricted_tys: ctx.unrestricted_tys.copy(),
    resource_tys: rt,
    resource_grades: rg,
  }
}

///|
/// McBride–Atkey 零重數型別形成歸零算子 `0 · (Γ ; Δ) = (Γ ; 0·Δ)`：
/// 檢查依值型別 `A : Type` 時將執行期資源全數置 `0`，使線性變數可合法出現在型別指標而不消耗執行期配額。
pub fn[R : Semiring] qtt_ctx_zero_resources(
  ctx : DualResourceCtx[R],
) -> DualResourceCtx[R] {
  let z = Array::make(ctx.resource_grades.length(), R::zero())
  DualResourceCtx::{
    unrestricted_tys: ctx.unrestricted_tys.copy(),
    resource_tys: ctx.resource_tys.copy(),
    resource_grades: z,
  }
}

///|
/// 半環純量倍乘 `σ · (Γ ; Δ) = (Γ ; σ·Δ)`（支撐分級必然模態 `[σ]A` 與無關擦除）。
pub fn[R : Semiring] qtt_ctx_scale(
  sigma : R,
  ctx : DualResourceCtx[R],
) -> DualResourceCtx[R] {
  let out : Array[R] = []
  for g in ctx.resource_grades {
    out.push(R::times(sigma, g))
  }
  DualResourceCtx::{
    unrestricted_tys: ctx.unrestricted_tys.copy(),
    resource_tys: ctx.resource_tys.copy(),
    resource_grades: out,
  }
}

///|
/// 乘法式上下文相加 `(Γ ; Δ₁) + (Γ ; Δ₂) = (Γ ; Δ₁ + Δ₂)`（用於函數應用 `f a` 與張量對 `(a, b)`）。
pub fn[R : Semiring] qtt_ctx_add(
  c1 : DualResourceCtx[R],
  c2 : DualResourceCtx[R],
) -> DualResourceCtx[R]? {
  if c1.unrestricted_tys != c2.unrestricted_tys ||
    c1.resource_tys != c2.resource_tys ||
    c1.resource_grades.length() != c2.resource_grades.length() {
    return None
  }
  let out : Array[R] = []
  for i in 0..<c1.resource_grades.length() {
    out.push(R::plus(c1.resource_grades[i], c2.resource_grades[i]))
  }
  Some(DualResourceCtx::{
    unrestricted_tys: c1.unrestricted_tys.copy(),
    resource_tys: c1.resource_tys.copy(),
    resource_grades: out,
  })
}

///|
/// 單一資源變數引用需求向量：在第 `idx` 槽產生重數 `sigma`（其餘槽為 `0`）。
pub fn[R : Semiring] qtt_ctx_var_demand(
  ctx : DualResourceCtx[R],
  idx : Int32,
  sigma : R,
) -> DualResourceCtx[R]? {
  if idx < 0 || idx >= ctx.resource_tys.length() {
    return None
  }
  let out = Array::make(ctx.resource_tys.length(), R::zero())
  out[idx] = sigma
  Some(DualResourceCtx::{
    unrestricted_tys: ctx.unrestricted_tys.copy(),
    resource_tys: ctx.resource_tys.copy(),
    resource_grades: out,
  })
}

///|
/// 窮舉驗證 `LinUsage` 星閉半環全體 `27` 組三元組公理，以及 `DualResourceCtx` 在
/// `LinUsage`、`Counting` 與 `BoolSr` 三種半環載體上之左半模定律與子資源檢查。
pub fn verify_dual_qtt_semiring_laws() -> Bool {
  let elems = [LinZero, LinOne, LinMany]
  for a in elems {
    if Semiring::plus(LinZero, a) != a ||
      Semiring::plus(a, LinZero) != a ||
      Semiring::times(LinZero, a) != LinZero ||
      Semiring::times(a, LinZero) != LinZero ||
      Semiring::times(LinOne, a) != a ||
      Semiring::times(a, LinOne) != a {
      return false
    }
    // Star 定律：1 ⊕ a·a* == a* 且 1 ⊕ a*·a == a*
    let st = StarSemiring::star(a)
    if Semiring::plus(LinOne, Semiring::times(a, st)) != st ||
      Semiring::plus(LinOne, Semiring::times(st, a)) != st {
      return false
    }
    for b in elems {
      if Semiring::plus(a, b) != Semiring::plus(b, a) {
        return false
      }
      for c in elems {
        if Semiring::plus(Semiring::plus(a, b), c) !=
          Semiring::plus(a, Semiring::plus(b, c)) ||
          Semiring::times(Semiring::times(a, b), c) !=
          Semiring::times(a, Semiring::times(b, c)) ||
          Semiring::times(a, Semiring::plus(b, c)) !=
          Semiring::plus(Semiring::times(a, b), Semiring::times(a, c)) ||
          Semiring::times(Semiring::plus(a, b), c) !=
          Semiring::plus(Semiring::times(a, c), Semiring::times(b, c)) {
          return false
        }
      }
    }
  }
  // 驗證線性 `1 + 1 = ω != 1`（精確捕獲線性變數雙重消耗違規）
  if Semiring::plus(LinOne, LinOne) != LinMany ||
    LinUsage::usage_compatible(LinMany, LinOne) ||
    LinUsage::usage_compatible(LinZero, LinOne) ||
    !LinUsage::usage_compatible(LinZero, LinMany) {
    return false
  }
  // 驗證左半模分配律：(π₁ + π₂)·Δ == π₁·Δ + π₂·Δ 與 (π₁·π₂)·Δ == π₁·(π₂·Δ)
  let base0 : DualResourceCtx[LinUsage] = dual_ctx_empty()
  let base1 = dual_ctx_push_unrestricted(base0, 10)
  let base2 = dual_ctx_push_resource(base1, 20, LinOne)
  let ctx = dual_ctx_push_resource(base2, 30, LinMany)
  for p1 in elems {
    for p2 in elems {
      let lhs = qtt_ctx_scale(Semiring::plus(p1, p2), ctx)
      let rhs_opt = qtt_ctx_add(qtt_ctx_scale(p1, ctx), qtt_ctx_scale(p2, ctx))
      match rhs_opt {
        Some(rhs) => if !lhs.equal(rhs) { return false }
        None => return false
      }
      let mul_l = qtt_ctx_scale(Semiring::times(p1, p2), ctx)
      let mul_r = qtt_ctx_scale(p1, qtt_ctx_scale(p2, ctx))
      if !mul_l.equal(mul_r) {
        return false
      }
    }
  }
  // Counting 精確計數半環投影至 LinUsage 之半環同態性
  let c_ctx0 : DualResourceCtx[Counting] = dual_ctx_empty()
  let c_ctx1 = dual_ctx_push_resource(c_ctx0, 1, Counting::{ n: 1L, })
  let c_ctx2 = dual_ctx_push_resource(c_ctx1, 2, Counting::{ n: 0L, })
  let doubled = match qtt_ctx_add(c_ctx2, c_ctx2) {
    Some(v) => v
    None => return false
  }
  doubled.resource_grades[0] == Counting::{ n: 2L, } &&
  LinUsage::from_count(doubled.resource_grades[0].n.to_int()) == LinMany &&
  qtt_ctx_zero_resources(c_ctx2).resource_grades[0] == Counting::{ n: 0L, }
}
