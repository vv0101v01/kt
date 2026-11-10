// ---------------------------------------------------------------------------
// meta/reflect/club — club 的組合學（normal function、無界、封閉、交）
// ---------------------------------------------------------------------------
//
// `universe.mbt` 給的是**語意**上的反射（`V_α ⊨ φ`）。反射定理的骨架是純組合學
// （Lévy–Montague）：
//
//   * `C ⊆ Ord` 是 club ⟺ `C` 無界且對 sup 封閉；
//   * 等價地：`C` 是某個 **normal function**（嚴格遞增＋連續）的像（Mostowski）；
//   * **兩個 club 的交仍是 club**，證明靠對角迭代：
//     `α₀ = 0`、`α_{n+1} = g(f(α_n))`，由連續性 `sup α_n = f(sup α_n) = g(sup α_n)`，
//     故 sup 落在交集裡；再由無界性往上重複 ⇒ 交集無界。
//
// 這裡把每一句都變成 `@core.Ordinal`（Cantor 範式）上的可計算檢查。
// 注意 `meta/core` 只有**右乘**（`ord_mul_int`、`ord_mul_omega`），所以 normal
// function 一律用 `ω^{…}` 造 —— `α ↦ ω^α` 本身就是最標準的 normal function。

///|
/// 序數函數（normal function 的候選）。
pub(all) struct OrdFun {
  name : String
  apply : (@core.Ordinal) -> @core.Ordinal
}

///|
/// 套用（MoonBit 的記錄欄位不能直接當函式呼叫）。
pub fn apply_ord(f : OrdFun, a : @core.Ordinal) -> @core.Ordinal {
  (f.apply)(a)
}

///|
/// `f(α) = ω^{1+α}`：嚴格遞增且連續，像是 `{ω^k : k ≥ 1}`。
pub fn fun_omega_pow() -> OrdFun {
  OrdFun::{
    name: "ω^{1+α}",
    apply: fn(a) { @core.ord_omega_pow(@core.ord_add(@core.ord_one(), a)) },
  }
}

///|
/// `g(α) = ω^{ω+α}`：也是 normal（嚴格遞增＋連續），像是 `{ω^λ : λ ≥ ω}`。
/// 注意 `α ↦ α·2` **不是** normal（右乘 2 不連續），用 `ω^{ω+α}·2` 當 club 是錯的
/// —— 下面 #6 的反例正是這個現象的正面版本。
pub fn fun_omega_omega_pow() -> OrdFun {
  OrdFun::{
    name: "ω^{ω·(1+α)}",
    apply: fn(a) {
      @core.ord_omega_pow(
        @core.ord_add(@core.ord_omega_pow(@core.ord_one()), a),
      )
    },
  }
}

///|
/// 探針集：後繼、極限、極限的極限都涵蓋。
pub fn probes() -> Array[@core.Ordinal] {
  let w = @core.ord_omega_pow(@core.ord_one()) // ω
  let w2 = @core.ord_omega_pow(@core.ord_int(2)) // ω²
  let w3 = @core.ord_omega_pow(@core.ord_int(3)) // ω³
  let ww = @core.ord_omega_pow(w) // ω^ω
  // 對角迭代會把指數推得很快，探針要跟上（否則「找不到原像」只是探針不夠）
  let d1 = @core.ord_omega_pow(@core.ord_mul_int(w, 2)) // ω^(ω·2)
  let d2 = @core.ord_omega_pow(d1)
  let d3 = @core.ord_omega_pow(d2)
  [
    @core.ord_zero(),
    @core.ord_one(),
    @core.ord_int(2),
    @core.ord_int(3),
    @core.ord_int(7),
    w,
    @core.ord_add(w, @core.ord_one()),
    @core.ord_mul_int(w, 2),
    w2,
    @core.ord_add(w2, @core.ord_one()),
    w3,
    ww,
    d1,
    d2,
    d3,
  ]
}

///|
/// `γ` 是否在 `f` 的像裡 —— 以探針裡的 `α` 作見證（存在性是真的在找見證）。
pub fn in_range(
  f : OrdFun,
  gamma : @core.Ordinal,
  ps : Array[@core.Ordinal],
) -> Bool {
  match preimage(f, gamma, ps) {
    Some(_) => true
    None => false
  }
}

///|
pub fn preimage(
  f : OrdFun,
  gamma : @core.Ordinal,
  ps : Array[@core.Ordinal],
) -> @core.Ordinal? {
  for a in ps {
    if @core.ord_cmp(apply_ord(f, a), gamma) == 0 {
      return Some(a)
    }
  }
  None
}

///|
/// 「像的包含」：`g` 的像是否落在 `f` 的像裡 —— 以恆等式 `ω^{ω+α} = ω^{1+(ω+α)}`
/// 逐個探針驗證（這正是 12.3 對角迭代能同時落在兩個 club 裡的理由）。
pub fn range_subset(
  f : OrdFun,
  g : OrdFun,
  w : @core.Ordinal,
  ps : Array[@core.Ordinal],
) -> Bool {
  let mut ok = true
  for a in ps {
    let lhs = apply_ord(g, a)
    let rhs = apply_ord(f, @core.ord_add(w, a))
    if @core.ord_cmp(lhs, rhs) != 0 {
      ok = false
    }
  }
  ok
}

///|
/// 對角迭代 `α₀ = 0`、`α_{n+1} = g(f(α_n))`（12.3 的構造）。
pub fn diagonal(f : OrdFun, g : OrdFun, n : Int32) -> @core.Ordinal {
  let mut a = @core.ord_zero()
  for _ in 0..<n {
    a = apply_ord(g, apply_ord(f, a))
  }
  a
}

///|
/// **club 的組合學定律**
/// #1 `f`、`g` 嚴格遞增（在探針上全對）
/// #2 兩者的像都無界（每個探針都被某個像點超過）
/// #3 連續性：`f(sup_n (1+n)) = sup_n f(1+n) = ω^ω`
/// #4 交非空：`ω^ω` 同時在兩條 normal function 的像裡，且都有原像見證
/// #5 對角迭代：`h(n)` 嚴格遞增、每項都在**兩個** club 裡
/// #6 非空洞：`{ω^{1+n} : n<ω}` 無界但其 sup `ω^ω` 不在集合裡 ⇒ 不封閉就不是 club
pub fn law_universe_clubs_intersect_by_diagonal_iteration() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let f = fun_omega_pow()
  let g = fun_omega_omega_pow()
  let ps = probes()
  let w = @core.ord_omega_pow(@core.ord_one())
  let ww = @core.ord_omega_pow(w)
  // #1 嚴格遞增
  let mut incr = true
  for i in 0..<ps.length() {
    for j in 0..<ps.length() {
      if @core.ord_lt(ps[i], ps[j]) {
        if !@core.ord_lt(apply_ord(f, ps[i]), apply_ord(f, ps[j])) {
          incr = false
        }
        if !@core.ord_lt(apply_ord(g, ps[i]), apply_ord(g, ps[j])) {
          incr = false
        }
      }
    }
  }
  @core.chk(
    out, "universe reflection: clubs intersect by diagonal iteration #1 (normal functions are strictly increasing)",
    incr,
  )
  // #2 無界
  let mut unbdd = true
  for beta in ps {
    let mut hf = false
    let mut hg = false
    for a in ps {
      if @core.ord_lt(beta, apply_ord(f, a)) {
        hf = true
      }
      if @core.ord_lt(beta, apply_ord(g, a)) {
        hg = true
      }
    }
    if !hf || !hg {
      unbdd = false
    }
  }
  @core.chk(
    out, "universe reflection: clubs intersect by diagonal iteration #2 (ranges are unbounded)",
    unbdd,
  )
  // #3 連續性
  @core.chk(
    out,
    "universe reflection: clubs intersect by diagonal iteration #3 (continuity: f(sup) = sup f = ω^ω)",
    @core.ord_cmp(apply_ord(f, w), ww) == 0,
  )
  // #4 交非空 + 兩邊都有原像
  @core.chk(
    out,
    "universe reflection: clubs intersect by diagonal iteration #4 (ω^ω lies in both ranges, with preimages)",
    in_range(f, ww, ps) && in_range(g, ww, ps),
  )
  // #5 對角迭代
  let h1 = diagonal(f, g, 1)
  let h2 = diagonal(f, g, 2)
  let h3 = diagonal(f, g, 3)
  @core.chk(
    out,
    "universe reflection: clubs intersect by diagonal iteration #5 (diagonal points increase and stay in both clubs)",
    @core.ord_lt(@core.ord_zero(), h1) &&
    @core.ord_lt(h1, h2) &&
    @core.ord_lt(h2, h3) &&
    in_range(f, h1, ps) &&
    in_range(g, h1, ps) &&
    in_range(g, h2, ps) &&
    range_subset(f, g, w, ps),
  )
  // #6 無界但不封閉 ⇒ 不是 club
  let mut finite_in_set = false
  for n in 0..<16 {
    if @core.ord_cmp(apply_ord(f, @core.ord_int(n)), ww) == 0 {
      finite_in_set = true
    }
  }
  @core.chk(
    out,
    "universe reflection: clubs intersect by diagonal iteration #6 (unbounded but not closed is not a club)",
    !finite_in_set && in_range(f, ww, ps),
  )
  out
}
