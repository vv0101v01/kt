// ---------------------------------------------------------------------------
// meta/reflect — 反射第一層：reify / reflect 這對伴隨
// ---------------------------------------------------------------------------
//
// 「反射」在型別論裡是一對映射：
//     reflect : 中性項 → 語義值         （把語法塞進語義）
//     reify   : 語義值 × 型別 → 正常形式（把語義拉回語法）
// 兩者互為逆（在值域上 up to 等價），於是「βη 相等」被判定成「reify 後語法相等」。
// 這正是 normalization by evaluation（NbE），也是「證明即計算」最實用的形式。
//
// 本檔給出小語言（基底型別、單位、函式型別）與它的 NbE。測試檢查：
//   1. 幂等：nf(nf(t)) = nf(t)
//   2. β 與 η：(\x.x) * ↦ *；λx. f x 與 f 同一個正常形式
//   3. 保型（以行為測試代替定理，明示邊界）
//
// 工程備註（MoonBit v0.10.14）：語義值用**單一**代數型別，
// 把「中性項」也放進值域（VNeutral / VApp），避免兩個型別互相遞迴
// 造成型別推導退化 —— 這是實測踩到的坑，寫在這裡以免後人重踩。

///|
pub(all) enum Ty {
  TBase(Int32)
  TArr(Ty, Ty)
  TOne
}

///|
pub(all) enum Term {
  TVar(Int32)
  TLam(Ty, Term)
  TApp(Term, Term)
  TStar
}

///|
pub(all) enum Val {
  /// 自由變數（中性）
  VNeutral(Int32)
  /// 停在非函式頭上的應用（中性），第三個欄位是參數型別
  VApp(Val, Val, Ty)
  /// 語義 β-閉包
  VClosure((Val) -> Val)
  VStar
}

///|
pub fn ty_eq(a : Ty, b : Ty) -> Bool {
  match (a, b) {
    (TBase(x), TBase(y)) => x == y
    (TArr(a1, b1), TArr(a2, b2)) => ty_eq(a1, a2) && ty_eq(b1, b2)
    (TOne, TOne) => true
    _ => false
  }
}

///|
pub fn term_eq(a : Term, b : Term) -> Bool {
  match (a, b) {
    (TVar(x), TVar(y)) => x == y
    (TLam(t1, b1), TLam(t2, b2)) => ty_eq(t1, t2) && term_eq(b1, b2)
    (TApp(f1, a1), TApp(f2, a2)) => term_eq(f1, f2) && term_eq(a1, a2)
    (TStar, TStar) => true
    _ => false
  }
}

///|
pub fn term_to_string(t : Term) -> String {
  match t {
    TVar(x) => "\{x}"
    TLam(_, b) => "(\\\{term_to_string(b)})"
    TApp(f, a) => "(\{term_to_string(f)} \{term_to_string(a)})"
    TStar => "*"
  }
}

///|
pub fn ty_to_string(t : Ty) -> String {
  match t {
    TBase(n) => "B\{n}"
    TArr(a, b) => "(\{ty_to_string(a)}->\{ty_to_string(b)})"
    TOne => "1"
  }
}

///|
fn vapp(f : Val, a : Val) -> Val {
  match f {
    VClosure(g) => g(a)
    VNeutral(_) => VApp(f, a, TOne)
    VApp(_, _, _) => VApp(f, a, TOne)
    VStar => VApp(f, a, TOne)
  }
}

///|
pub fn eval(env : Array[Val], t : Term) -> Val {
  match t {
    TVar(x) => if x >= 0 && x < env.length() { env[x] } else { VNeutral(x) }
    TLam(_ty, body) => {
      let captured = clone_vals(env)
      VClosure(fn(a : Val) -> Val {
        let env2 : Array[Val] = [a]
        for v in captured {
          env2.push(v)
        }
        eval(env2, body)
      })
    }
    TApp(f, a) => {
      let fv = eval(env, f)
      let av = eval(env, a)
      vapp(fv, av)
    }
    TStar => VStar
  }
}

///|
fn clone_vals(xs : Array[Val]) -> Array[Val] {
  let out : Array[Val] = []
  for x in xs {
    out.push(x)
  }
  out
}

///| 帶型別的應用：中性頭上要記住參數型別，否則 reify 會把參數讀錯型別。

///|
/// 這是「untyped eval + typed reify」的標準補丁：型別資訊在 reify 一端恢復。
fn apply_at(dom : Ty, f : Val, a : Val) -> Val {
  match f {
    VClosure(g) => g(a)
    _ => VApp(f, a, dom)
  }
}

///|
/// reflect：中性值升進語義域（函式型別上逐一作用）。
pub fn reflect(ty : Ty, lvl : Int32, n : Val) -> Val {
  match ty {
    TBase(_) => n
    TOne => VStar
    TArr(a, b) =>
      VClosure(fn(x : Val) -> Val { reflect(b, lvl + 1, VApp(n, x, a)) })
  }
}

///|
/// reify：語義值讀回正常形式（函式型別上 η-展開）。
pub fn reify(ty : Ty, lvl : Int32, v : Val) -> Term {
  match ty {
    TBase(_) => reify_neu(lvl, v)
    TOne => TStar
    TArr(a, b) => {
      // 新綁定的變數用 `-1 - lvl` 標記（負數 = 綁定變數的層級），
      // 這樣才能和「自由變數用它原本的 de Bruijn 索引」區分開來。
      let x = VNeutral(-1 - lvl)
      let body = apply_at(a, v, x)
      TLam(a, reify(b, lvl + 1, body))
    }
  }
}

///|
fn reify_neu(lvl : Int32, v : Val) -> Term {
  match v {
    // 負數 = reify 自己綁的變數（層級 `-1 - x`），要換成 de Bruijn 索引；
    // 非負 = 自由變數，保留原索引但隨開啟的綁定數平移。
    VNeutral(x) => if x < 0 { TVar(lvl - 1 - (-1 - x)) } else { TVar(x + lvl) }
    VApp(f, a, ty) => TApp(reify_neu(lvl, f), reify(ty, lvl, a))
    _ => TStar
  }
}

// ---------------------------------------------------------------------------
// 型別檢查（保型性測試用）
// ---------------------------------------------------------------------------

///|
fn lookup(ctx : Array[Ty], x : Int32) -> Ty? {
  if x >= 0 && x < ctx.length() {
    Some(ctx[x])
  } else {
    None
  }
}

///|
/// 型別推導（標註過的 λ，足夠做保型性測試）。
pub fn infer(ctx : Array[Ty], t : Term) -> Ty? {
  match t {
    TVar(x) => lookup(ctx, x)
    TStar => Some(TOne)
    TLam(a, body) => {
      let ctx2 : Array[Ty] = [a]
      for x in ctx {
        ctx2.push(x)
      }
      match infer(ctx2, body) {
        Some(b) => Some(TArr(a, b))
        None => None
      }
    }
    TApp(f, a) =>
      match infer(ctx, f) {
        Some(TArr(d, c)) => if check(ctx, a, d) { Some(c) } else { None }
        _ => None
      }
  }
}

///|
/// 型別檢查 = 推導出的型別與宣稱相等。
pub fn check(ctx : Array[Ty], t : Term, ty : Ty) -> Bool {
  match infer(ctx, t) {
    Some(t2) => ty_eq(t2, ty)
    None => false
  }
}

///|
/// **帶型別的求值**：中性應用必須記住參數型別。
/// 這是 `nf` 冪等的關鍵 —— 舊版用 untyped `eval`，`vapp` 只能把參數型別填成
/// `TOne`，於是 `reify` 會把參數讀成 `*`，`nf(nf t) ≠ nf t`（實測：
/// `λf. (λx.x) f` 第一次得 `λλ(0 1)`、第二次得 `λλ(1 *)`）。
/// 型別在此由 `infer` 在應用點恢復，語義值因此不必自己帶推導。
fn eval_typed(env : Array[Val], ctx : Array[Ty], t : Term) -> Val {
  match t {
    // 環境裝的是**綁定變數**；超出環境的是自由變數，要換回它在原始上下文裡的索引
    // （`x - env.length()`），否則在 binder 底下會被多移一次。
    TVar(x) =>
      if x >= 0 && x < env.length() {
        env[x]
      } else {
        VNeutral(x - env.length())
      }
    TLam(ty, body) => {
      let captured = clone_vals(env)
      let ctx2 : Array[Ty] = [ty]
      for c in ctx {
        ctx2.push(c)
      }
      VClosure(fn(a : Val) -> Val {
        let env2 : Array[Val] = [a]
        for v in captured {
          env2.push(v)
        }
        eval_typed(env2, ctx2, body)
      })
    }
    TApp(f, a) => {
      let dom = match infer(ctx, f) {
        Some(TArr(d, _)) => d
        _ => TOne
      }
      let fv = eval_typed(env, ctx, f)
      let av = eval_typed(env, ctx, a)
      match fv {
        VClosure(g) => g(av)
        _ => VApp(fv, av, dom)
      }
    }
    TStar => VStar
  }
}

///|
/// 帶上下文的正規化：`ctx` 只用來在應用點恢復參數型別（自由變數的型別）。
pub fn nf_in(ctx : Array[Ty], ty : Ty, t : Term) -> Term {
  reify(ty, 0, eval_typed([], ctx, t))
}

///|
/// 型別索引的正規化（βη 正常形式）：型別導向的求值 + reify。
/// 對**開項**請用 `nf_in`，否則自由變數的型別無法恢復。
pub fn nf(ty : Ty, t : Term) -> Term {
  nf_in([], ty, t)
}

// ---------------------------------------------------------------------------
// 單步 β / η（給可重放憑證用，見 proof.mbt）
// ---------------------------------------------------------------------------

///|
fn shift(t : Term, d : Int32, cutoff : Int32) -> Term {
  match t {
    TVar(x) => if x >= cutoff { TVar(x + d) } else { TVar(x) }
    TLam(ty, b) => TLam(ty, shift(b, d, cutoff + 1))
    TApp(f, a) => TApp(shift(f, d, cutoff), shift(a, d, cutoff))
    TStar => TStar
  }
}

///|
fn subst(t : Term, j : Int32, s : Term) -> Term {
  match t {
    // 拿掉一層 binder 之後，索引 > j 的變數要**減一**（否則開項的 β 步驟是錯的；
    // 這個 bug 之前沒被樣本打到，因為樣本全是閉項）。
    TVar(x) => if x == j { s } else if x > j { TVar(x - 1) } else { TVar(x) }
    TLam(ty, b) => TLam(ty, subst(b, j + 1, shift(s, 1, 0)))
    TApp(f, a) => TApp(subst(f, j, s), subst(a, j, s))
    TStar => TStar
  }
}

///|
/// 最左最外層的一步 β 規約。
pub fn beta_once(t : Term) -> Term? {
  match t {
    TApp(TLam(_ty, body), arg) => Some(subst(body, 0, arg))
    TApp(f, a) =>
      match beta_once(f) {
        Some(f2) => Some(TApp(f2, a))
        None =>
          match beta_once(a) {
            Some(a2) => Some(TApp(f, a2))
            None => None
          }
      }
    TLam(ty, b) =>
      match beta_once(b) {
        Some(b2) => Some(TLam(ty, b2))
        None => None
      }
    TVar(_) => None
    TStar => None
  }
}

///|
fn uses_var0(t : Term) -> Bool {
  match t {
    TVar(0) => true
    TVar(_) => false
    TLam(_, b) => uses_var0(b)
    TApp(f, a) => uses_var0(f) || uses_var0(a)
    TStar => false
  }
}

///|
/// 單步 η 收縮：λx. (f x) ↦ f，要求 x 在 f 中不出現。
pub fn eta_once(t : Term) -> Term? {
  match t {
    TLam(_ty, TApp(f, TVar(0))) =>
      if uses_var0(f) {
        None
      } else {
        Some(shift(f, -1, 0))
      }
    TLam(ty, b) =>
      match eta_once(b) {
        Some(b2) => Some(TLam(ty, b2))
        None => None
      }
    _ => None
  }
}

///|
/// βη 轉換的一步（對稱）。可重放憑證的每一步都要通過這個檢查。
pub fn conv_step(a : Term, b : Term) -> Bool {
  match beta_once(a) {
    Some(a2) => if term_eq(a2, b) { return true }
    None => ()
  }
  match beta_once(b) {
    Some(b2) => if term_eq(b2, a) { return true }
    None => ()
  }
  match eta_once(a) {
    Some(a2) => if term_eq(a2, b) { return true }
    None => ()
  }
  match eta_once(b) {
    Some(b2) => if term_eq(b2, a) { return true }
    None => ()
  }
  false
}

///|
pub fn law_nbe_nbe_beta_eta_idempotence_type_preservation() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let b0 = TBase(0)
  let arr = TArr(b0, b0)
  let idt = TLam(b0, TVar(0))
  // β：(\x.x) * → *
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #1",
    term_eq(nf(b0, TApp(idt, TStar)), TStar),
  )
  // 幂等
  let t1 = TApp(idt, TApp(idt, TStar))
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #2",
    term_eq(nf(b0, t1), nf(b0, nf(b0, t1))),
  )
  // η：reflect 在函式型別上做的正是 η-展開，所以 reify∘reflect = η-長形式；
  // 於是 λx. f x 與自由變數 f 讀出同一個正常形式。
  let f_val = VNeutral(0)
  let eta_val = reflect(arr, 0, f_val)
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #3",
    term_eq(reify(arr, 0, eta_val), reify(arr, 0, f_val)),
  )
  // 反向（untyped eval 的邊界）：eval 造出的中性應用不帶參數型別，
  // 所以只能在 base 型別上安全地 reify；這裡明確只測 base 情形。
  let env : Array[Val] = [f_val]
  let app_from_eval = eval(env, TApp(TVar(0), TStar))
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #4",
    term_eq(reify(b0, 0, app_from_eval), TApp(TVar(0), TStar)),
  )
  // 保型：nf 之後型別不變（行為測試）
  let ctx : Array[Ty] = []
  let f_one_b0 = TArr(TOne, b0)
  let terminates = TLam(f_one_b0, TApp(TVar(0), TStar))
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #5",
    check(ctx, terminates, TArr(f_one_b0, b0)),
  )
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #6",
    check(ctx, nf(TArr(f_one_b0, b0), terminates), TArr(f_one_b0, b0)),
  )
  // 反例：型別不對的項要被拒
  @core.chk(
    out,
    "nbe: beta, eta, idempotence, type preservation #7",
    !check(ctx, terminates, arr),
  )
  out
}

// ---------------------------------------------------------------------------
// 正規形保證：nf 真的算到正常形式（不是「大概是」）
// ---------------------------------------------------------------------------

///|
/// β 正規形判定：不能再做 β 收縮。
/// （**不**要求 η-短：NbE 的輸出是 η-**長**形式，`λx. f x` 在語義上就等於 `f`，
///  reify 會刻意把它展開。所以「正規形」在這裡的正確意思是 β-正規 + η-長 + 冪等。）
pub fn is_beta_normal(t : Term) -> Bool {
  match beta_once(t) {
    Some(_) => false
    None => true
  }
}

///|
/// `nf` 的不動點性質（獨立於型別的檢查點）。
pub fn nf_is_fixpoint(ty : Ty, t : Term) -> Bool {
  term_eq(nf(ty, t), nf(ty, nf(ty, t)))
}

///|
pub fn law_nbe_nf_reaches_a_normal_form() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let b0 = TBase(0)
  let arr = TArr(b0, b0)
  let arr2 = TArr(arr, arr)
  let idt = TLam(b0, TVar(0))
  let t1 = TApp(idt, TStar)
  let t2 = TApp(idt, TApp(idt, TStar))
  let eta_term = TLam(b0, TApp(TVar(0), TVar(0)))
  let hof = TLam(arr, TApp(idt, TVar(0)))
  @core.chk(
    out,
    "nbe: nf reaches a normal form #1 (beta redex becomes beta-normal, fixpoint)",
    is_beta_normal(nf(b0, t1)) && nf_is_fixpoint(b0, t1),
  )
  @core.chk(
    out,
    "nbe: nf reaches a normal form #2 (nested beta)",
    is_beta_normal(nf(b0, t2)) && nf_is_fixpoint(b0, t2),
  )
  @core.chk(
    out,
    "nbe: nf reaches a normal form #3 (self application)",
    is_beta_normal(nf(arr, eta_term)) && nf_is_fixpoint(arr, eta_term),
  )
  @core.chk(
    out,
    "nbe: nf reaches a normal form #4 (higher order, was a real bug)",
    is_beta_normal(nf(arr2, hof)) && nf_is_fixpoint(arr2, hof),
  )
  // 設計上的差別：nf 的輸出是 η-**長**形式，所以 η-短那一步仍然可以收縮 —— 這是刻意的。
  @core.chk(
    out,
    "nbe: nf reaches a normal form #5 (output is eta-long, not eta-short)",
    match eta_once(nf(arr, TVar(0))) {
      Some(_) => true
      None => false
    },
  )
  // 反向對照：原始 redex 不是 β-正規形，否則前面的檢查沒有內容
  @core.chk(
    out,
    "nbe: nf reaches a normal form #6 (redex is not beta-normal)",
    !is_beta_normal(t1),
  )
  out
}

// ---------------------------------------------------------------------------
// 一般 β：對「大小 ≤ N 的所有項」窮舉檢查（不是挑樣本）
// ---------------------------------------------------------------------------

///|
/// 在給定上下文中列舉某型別、大小不超過 `budget` 的**所有**項。
/// de Bruijn 索引：新綁定的變數是 0，既有的全部 +1（所以內層用 `ctx2` 遞迴）。
fn enum_terms(ctx : Array[Ty], ty : Ty, budget : Int32) -> Array[Term] {
  let out : Array[Term] = []
  if budget <= 0 {
    return out
  }
  // 變數（型別相符者）
  for i in 0..<ctx.length() {
    if ty_eq(ctx[i], ty) {
      out.push(TVar(i))
    }
  }
  match ty {
    TOne => if budget >= 1 { out.push(TStar) }
    TBase(_) => ()
    TArr(a, b) => {
      // λ 抽象
      let ctx2 : Array[Ty] = [a]
      for c in ctx {
        ctx2.push(c)
      }
      for body in enum_terms(ctx2, b, budget - 1) {
        out.push(TLam(a, body))
      }
      // 應用：預算切給函式與引數兩邊
      for sub in 1..<budget {
        for f in enum_terms(ctx, TArr(a, ty), sub) {
          for x in enum_terms(ctx, a, budget - 1 - sub) {
            out.push(TApp(f, x))
          }
        }
      }
    }
  }
  out
}

///|
/// **一般 β 的可執行版**：把「所有大小 ≤ 5 的項」窮舉出來逐個檢查
/// （β-正規、`nf` 冪等、一步 β 之後 `nf` 不變、η 收縮之後 `nf` 不變、型別保持）。
/// 這比樣本強得多，但不是「所有項」的定理 —— 邊界就寫在這裡。
pub fn law_nbe_general_beta_over_all_terms() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let b0 = TBase(0)
  let b1 = TBase(1)
  let arr = TArr(b0, b0)
  let ctx : Array[Ty] = [b0, arr, b1, TArr(b0, TOne)]
  let tys : Array[Ty] = [b0, TOne, b1, arr, TArr(b0, TOne), TArr(arr, b0)]
  let budget = 10
  let mut total = 0
  let mut beta_normal = true
  let mut idempotent = true
  let mut beta_step = true
  let mut eta_step = true
  let mut typed = true
  for ty in tys {
    for t in enum_terms(ctx, ty, budget) {
      total = total + 1
      let n = nf_in(ctx, ty, t)
      if !is_beta_normal(n) {
        println(
          "DBG1 " +
          ty_to_string(ty) +
          " t=" +
          term_to_string(t) +
          " nf=" +
          term_to_string(n),
        )
        beta_normal = false
      }
      if !term_eq(nf_in(ctx, ty, n), n) {
        idempotent = false
      }
      match beta_once(t) {
        Some(t2) =>
          if !term_eq(nf_in(ctx, ty, t2), n) {
            println(
              "DBG3 " +
              ty_to_string(ty) +
              " t=" +
              term_to_string(t) +
              " t2=" +
              term_to_string(t2) +
              " nf(t)=" +
              term_to_string(n) +
              " nf(t2)=" +
              term_to_string(nf_in(ctx, ty, t2)),
            )
            beta_step = false
          }
        None => ()
      }
      match eta_once(t) {
        Some(t2) => if !term_eq(nf_in(ctx, ty, t2), n) { eta_step = false }
        None => ()
      }
      if !check(ctx, n, ty) {
        typed = false
      }
    }
  }
  let tag = "(over \{total} terms)"
  @core.chk(
    out,
    "nbe: general beta #1 nf is beta-normal \{tag}",
    total > 200 && beta_normal,
  )
  @core.chk(out, "nbe: general beta #2 nf is idempotent \{tag}", idempotent)
  @core.chk(
    out,
    "nbe: general beta #3 one-step beta preserves nf \{tag}",
    beta_step,
  )
  @core.chk(
    out,
    "nbe: general beta #4 eta contraction preserves nf \{tag}",
    eta_step,
  )
  @core.chk(out, "nbe: general beta #5 nf preserves the type \{tag}", typed)
  out
}
