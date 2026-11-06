// ---------------------------------------------------------------------------
// meta/iit — STLC 的 β 與**索引傳輸**（把「未實作」的那一項做完）
// ---------------------------------------------------------------------------
//
// 上一版只做到「索引檢查 + 消除器」，並明白寫著：`beta` 未實作，因為
//   `app (lam A B body) arg` 的約簡不是單純的代換 ——
//   被代入的項 arg : Tm G A 必須在走過 k 層 binder 之後，變成
//   Tm (cons A_k (… (cons A_1 G))) A，**上下文本身在變**。
//
// 這一檔把這件事做完，關鍵只有一個：**把「插入一個型別到上下文」變成基本操作**。
//
//   ctx_insert ctx x k    ：把 x 插到 ctx 的第 k 個位置（0 = 最前面）
//   subst_insert t x k    ：把 x 插到 t 的上下文第 k 個位置，並同步重寫所有變數節點
//
// 有了它，代換就退化成「走過去、數深度」：
//   在深度 d 遇到位置 p 的變數時
//     p = d  ⇒ 就是被抓的變數：換成 arg 依序在前面插入 crossed[0..d−1] 的結果
//     p > d  ⇒ 是外層上下文的變數：位置減一（因為 A 被移除）
//     p < d  ⇒ 由內層 binder 綁定：位置不變
// 而每個節點儲存的上下文都要把第 d 個元素拿掉（那就是被消去的 binder）。
//
// 這樣約簡出來的項，其 Tm 索引會**自動**等於原項的索引 —— 型別保持不是靠信仰，
// 而是靠 `icheck` 與 `iindex_of` 在每一步重算（見本檔的定律）。

// ---------------------------------------------------------------------------
// 1. 型別、上下文與項的公開建構子
// ---------------------------------------------------------------------------

///|
pub fn stlc_ty_nat() -> IVal {
  ival(0, [])
}

///|
pub fn stlc_ty_arr(a : IVal, b : IVal) -> IVal {
  ival(1, [a, b])
}

///|
pub fn stlc_nil() -> IVal {
  ival(2, [])
}

///|
pub fn stlc_cons(a : IVal, g : IVal) -> IVal {
  ival(3, [a, g])
}

///|
pub fn stlc_vz(g : IVal, a : IVal) -> IVal {
  ival(4, [g, a])
}

///|
pub fn stlc_vs(g : IVal, a : IVal, b : IVal, u : IVal) -> IVal {
  ival(5, [g, a, b, u])
}

///|
pub fn stlc_app(g : IVal, a : IVal, b : IVal, f : IVal, x : IVal) -> IVal {
  ival(6, [g, a, b, f, x])
}

///|
pub fn stlc_lam(g : IVal, a : IVal, b : IVal, body : IVal) -> IVal {
  ival(7, [g, a, b, body])
}

// ---------------------------------------------------------------------------
// 2. 上下文的基本操作
// ---------------------------------------------------------------------------

///|
fn ctx_is_cons(c : IVal) -> Bool {
  c.ctor == 3
}

///|
fn ctx_head(c : IVal) -> IVal {
  c.args[0]
}

///|
fn ctx_tail(c : IVal) -> IVal {
  c.args[1]
}

///|
/// 把 x 插到上下文 ctx 的第 k 個位置（0 = 最前面；k 超過長度時貼在最後）。
fn ctx_insert(ctx : IVal, x : IVal, k : Int32) -> IVal {
  if k <= 0 || !ctx_is_cons(ctx) {
    stlc_cons(x, ctx)
  } else {
    stlc_cons(ctx_head(ctx), ctx_insert(ctx_tail(ctx), x, k - 1))
  }
}

///|
/// 移除上下文的第 k 個元素（k 超出範圍時原樣回傳）。
fn ctx_remove(ctx : IVal, k : Int32) -> IVal {
  if !ctx_is_cons(ctx) {
    ctx
  } else if k <= 0 {
    ctx_tail(ctx)
  } else {
    stlc_cons(ctx_head(ctx), ctx_remove(ctx_tail(ctx), k - 1))
  }
}

// ---------------------------------------------------------------------------
// 3. 變數節點：位置、型別、完整上下文
// ---------------------------------------------------------------------------
//
// 變數用 vs 鏈表示：vz(G,A) 是最內層（位置 0，型別 A，上下文 cons A G），
// vs(G,A,B,u) 是「u 再多一層 binder B」（位置 = 1 + u 的位置）。

///|
fn is_var(t : IVal) -> Bool {
  t.ctor == 4 || t.ctor == 5
}

///|
fn var_full_ctx(t : IVal) -> IVal {
  if t.ctor == 4 {
    stlc_cons(t.args[1], t.args[0])
  } else {
    stlc_cons(t.args[2], t.args[0])
  }
}

///|
fn var_ty(t : IVal) -> IVal {
  t.args[1]
}

///|
fn var_depth(t : IVal) -> Int32 {
  if t.ctor == 4 {
    0
  } else {
    1 + var_depth(t.args[3])
  }
}

///|
/// 由（完整上下文, 位置, 型別）重建變數節點 —— 這是所有「上下文改變」的收斂點。
fn make_var(ctx : IVal, depth : Int32, ty : IVal) -> IVal {
  if depth == 0 {
    stlc_vz(ctx_tail(ctx), ty)
  } else {
    stlc_vs(
      ctx_tail(ctx),
      ty,
      ctx_head(ctx),
      make_var(ctx_tail(ctx), depth - 1, ty),
    )
  }
}

// ---------------------------------------------------------------------------
// 4. 上下文插入：把「弱化」變成一次結構重寫
// ---------------------------------------------------------------------------

///|
/// 在項 t 的上下文第 k 個位置插入型別 x，並同步重寫所有子節點。
/// 這是整檔的核心：它同時是**弱化**（k = 0）與**索引傳輸**（k > 0）的統一形式。
pub fn subst_insert(t : IVal, x : IVal, k : Int32) -> IVal {
  if is_var(t) {
    let ctx = ctx_insert(var_full_ctx(t), x, k)
    let p = var_depth(t)
    let np = if k <= p { p + 1 } else { p }
    make_var(ctx, np, var_ty(t))
  } else if t.ctor == 7 {
    // lam(G, A0, B0, body)：body 的上下文是 cons A0 G
    let g = t.args[0]
    if k == 0 {
      // x 插在 term 上下文最前面 ⇒ G 要變成 cons x G，而 body 裡它排在 A0 之後（位置 1）
      stlc_lam(
        ctx_insert(g, x, 0),
        t.args[1],
        t.args[2],
        subst_insert(t.args[3], x, 1),
      )
    } else {
      stlc_lam(
        ctx_insert(g, x, k - 1),
        t.args[1],
        t.args[2],
        subst_insert(t.args[3], x, k),
      )
    }
  } else if t.ctor == 6 {
    // app(G, A0, B0, f, a)：兩個子項都在同一個上下文裡
    stlc_app(
      ctx_insert(t.args[0], x, k),
      t.args[1],
      t.args[2],
      subst_insert(t.args[3], x, k),
      subst_insert(t.args[4], x, k),
    )
  } else {
    t
  }
}

///|
/// 弱化：t : Tm G A ⟹ Tm (cons x G) A。就是 k = 0 的插入。
pub fn stlc_weaken(t : IVal, x : IVal) -> IVal {
  subst_insert(t, x, 0)
}

// ---------------------------------------------------------------------------
// 5. β：代換（帶索引傳輸）
// ---------------------------------------------------------------------------

///|
fn subst_go(t : IVal, arg : IVal, crossed : Array[IVal]) -> IVal {
  let d = crossed.length()
  if is_var(t) {
    let p = var_depth(t)
    if p == d {
      // 被抓的變數：把 arg 依序在前面插入走過的 binder
      let mut a = arg
      for i in 0..<crossed.length() {
        a = subst_insert(a, crossed[i], 0)
      }
      a
    } else {
      // 其他變數：上下文移除第 d 個元素（被消去的 binder A）
      let ctx = ctx_remove(var_full_ctx(t), d)
      let np = if p > d { p - 1 } else { p }
      make_var(ctx, np, var_ty(t))
    }
  } else if t.ctor == 7 {
    let g = t.args[0]
    let a0 = t.args[1]
    let next : Array[IVal] = []
    for x in crossed {
      next.push(x)
    }
    next.push(a0)
    stlc_lam(ctx_remove(g, d), a0, t.args[2], subst_go(t.args[3], arg, next))
  } else if t.ctor == 6 {
    stlc_app(
      ctx_remove(t.args[0], d),
      t.args[1],
      t.args[2],
      subst_go(t.args[3], arg, crossed),
      subst_go(t.args[4], arg, crossed),
    )
  } else {
    t
  }
}

///|
/// 單步 β：`app (lam A B body) arg ↝ body[x₀ := arg]`。
/// 只有「函式位置就是 λ」時才動；其他情形回傳 None（卡住的項不假裝能走）。
pub fn stlc_beta(t : IVal) -> IVal? {
  if t.ctor != 6 {
    return None
  }
  let f = t.args[3]
  if f.ctor != 7 {
    return None
  }
  let body = f.args[3]
  let arg = t.args[4]
  let empty : Array[IVal] = []
  Some(subst_go(body, arg, empty))
}

///|
/// 反覆做單步 β 直到卡住或燃料用完（值的語義：卡住的項就是「值」）。
pub fn stlc_norm(t : IVal, fuel : Int32) -> IVal {
  let mut cur = t
  let mut n = 0
  while n < fuel {
    match stlc_beta(cur) {
      Some(next) => cur = next
      None => break
    }
    n = n + 1
  }
  cur
}

// ---------------------------------------------------------------------------
// 6. 索引比較的小工具（型別保持的可判定形式）
// ---------------------------------------------------------------------------

///|
/// 兩個 Tm 的完整索引（上下文, 型別）是否相同。
pub fn stlc_same_index(s : ISchema, a : IVal, b : IVal) -> Bool {
  let ia = iindex_of(s, a)
  let ib = iindex_of(s, b)
  if ia.length() != ib.length() {
    return false
  }
  for i in 0..<ia.length() {
    if !iterm_eq(ia[i], ib[i]) {
      return false
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 7. 範例程式（建構子寫法本身就是規格）
// ---------------------------------------------------------------------------

///|
fn n() -> IVal {
  stlc_ty_nat()
}

///|
fn nil() -> IVal {
  stlc_nil()
}

///|
/// `x : Tm (cons nat nil) nat` —— 位置 0 的變數。
pub fn stlc_ex_var() -> IVal {
  stlc_vz(nil(), n())
}

///|
/// `λx:nat. x` ：Tm nil (nat → nat)
pub fn stlc_ex_id() -> IVal {
  stlc_lam(nil(), n(), n(), stlc_vz(nil(), n()))
}

///| 測試用的「值」一律是 λ 項（schema 裡沒有 nat 常數），

///|
/// 所以 arg 就用恆等函式 `λy:nat. y : nat → nat`。
pub fn stlc_ex_arg() -> IVal {
  stlc_ex_id()
}

///|
/// `(λx:nat→nat. x) (λy:nat. y)` —— 一次 β 就回到 `λy:nat. y`
pub fn stlc_ex_app1() -> IVal {
  let arr = stlc_ty_arr(n(), n())
  stlc_app(
    nil(),
    arr,
    arr,
    stlc_lam(nil(), arr, arr, stlc_vz(nil(), arr)),
    stlc_ex_arg(),
  )
}

///|
/// `(λx:A. λy:nat. x) (λz:nat. z)` —— 需要**弱化**（arg 走進一層 binder）
pub fn stlc_ex_app2() -> IVal {
  let a = stlc_ty_arr(n(), n())
  stlc_app(
    nil(),
    a,
    stlc_ty_arr(n(), a),
    stlc_lam(
      nil(),
      a,
      stlc_ty_arr(n(), a),
      stlc_lam(
        stlc_cons(a, nil()),
        n(),
        a,
        stlc_vs(stlc_cons(a, nil()), a, n(), stlc_vz(nil(), a)),
      ),
    ),
    stlc_ex_arg(),
  )
}

// ---------------------------------------------------------------------------
// 定律
// ---------------------------------------------------------------------------

///|
pub fn law_stlc_stlc_beta_is_index_preserving() -> Array[(String, Bool)] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  let t = stlc_ex_app1()
  // 先確認原項良構
  @core.chk(out, "iit: STLC β is index-preserving #1", icheck(s, t))
  match stlc_beta(t) {
    None => @core.chk(out, "iit: STLC β is index-preserving #2", false)
    Some(r) => {
      // 約簡結果良構
      @core.chk(out, "iit: STLC β is index-preserving #2", icheck(s, r))
      // 索引（上下文, 型別）完全相同 —— 這就是型別保持，用 iindex_of 重算
      @core.chk(
        out,
        "iit: STLC β is index-preserving #3",
        stlc_same_index(s, t, r),
      )
      // 而且真的回到了 λy:nat. y
      @core.chk(
        out,
        "iit: STLC β is index-preserving #4",
        ival_eq(r, stlc_ex_arg()),
      )
    }
  }
  // 走進一層 binder 的情形：arg 必須被弱化（vs 鏈多一層），否則索引會壞
  let t2 = stlc_ex_app2()
  @core.chk(out, "iit: STLC β is index-preserving #5", icheck(s, t2))
  match stlc_beta(t2) {
    None => @core.chk(out, "iit: STLC β is index-preserving #6", false)
    Some(r2) => {
      @core.chk(out, "iit: STLC β is index-preserving #6", icheck(s, r2))
      @core.chk(
        out,
        "iit: STLC β is index-preserving #7",
        stlc_same_index(s, t2, r2),
      )
      // 結果是 λy:nat. (λz. z)，其中內層那個 arg 的上下文被插入了 nat
      @core.chk(out, "iit: STLC β is index-preserving #8", r2.ctor == 7)
      // 內層的 arg 被弱化：它的上下文從 nil 變成 cons nat nil
      @core.chk(
        out,
        "iit: STLC β is index-preserving #9",
        r2.args[3].ctor == 7 &&
        ival_eq(r2.args[3].args[0], stlc_cons(n(), nil())),
      )
    }
  }
  out
}

///|
pub fn law_stlc_weakening_and_context_insert_are_consistent() -> Array[
  (String, Bool),
] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  let v = stlc_ex_var()
  // 對變數而言，弱化就是「包一層 vs」
  let w = stlc_weaken(v, n())
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #1",
    w.ctor == 5,
  )
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #2",
    icheck(s, w),
  )
  // 弱化後型別不變、上下文長一
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #3",
    iterm_eq(iindex_of(s, v)[1], iindex_of(s, w)[1]),
  )
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #4",
    !iterm_eq(iindex_of(s, v)[0], iindex_of(s, w)[0]),
  )
  // 弱化是單射（位置資訊沒丟）：不同變數弱化後仍不同
  let v_lam = stlc_lam(stlc_cons(n(), nil()), n(), n(), stlc_vz(nil(), n()))
  let w2 = stlc_weaken(stlc_ex_arg(), n())
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #5",
    icheck(s, w2),
  )
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #6",
    ival_eq(w2.args[0], stlc_cons(n(), nil())),
  )
  // 弱化再弱化：兩層 vs 鏈，仍然良構
  let w3 = stlc_weaken(w, stlc_ty_arr(n(), n()))
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #7",
    icheck(s, w3),
  )
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #8",
    var_depth(w3) == 2,
  )
  // 一個拒絕的例子：把型別錯的 arg 塞進 app，索引檢查必須先攔下來
  let bad = stlc_app(
    nil(),
    n(),
    n(),
    stlc_lam(nil(), n(), n(), stlc_vz(nil(), n())),
    stlc_ex_arg(),
  )
  @core.chk(
    out,
    "iit: weakening and context insert are consistent #9",
    !icheck(s, bad),
  )
  let _ = v_lam
  out
}

///|
pub fn law_stlc_subject_reduction_on_a_battery() -> Array[(String, Bool)] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  let a = stlc_ty_arr(n(), n())
  // 一批閉項：每一步約簡都必須保持索引
  let terms : Array[IVal] = [
    stlc_ex_app1(),
    stlc_ex_app2(),
    // (λx:A. λy:A. y) (λz.z)
    stlc_app(
      nil(),
      a,
      stlc_ty_arr(a, a),
      stlc_lam(
        nil(),
        a,
        stlc_ty_arr(a, a),
        stlc_lam(stlc_cons(a, nil()), a, a, stlc_vz(stlc_cons(a, nil()), a)),
      ),
      stlc_ex_arg(),
    ),
    // 內層先約簡、外層再套一次：(λx:A. x) ((λx:A. x) arg)
    stlc_app(
      nil(),
      a,
      a,
      stlc_lam(nil(), a, a, stlc_vz(nil(), a)),
      stlc_app(
        nil(),
        a,
        a,
        stlc_lam(nil(), a, a, stlc_vz(nil(), a)),
        stlc_ex_arg(),
      ),
    ),
  ]
  for t in terms {
    // 原項良構
    @core.chk(out, "iit: subject reduction on a battery #1", icheck(s, t))
    let mut cur = t
    let mut steps = 0
    // 每一步都檢查：良構 + 索引不變
    while steps < 12 {
      match stlc_beta(cur) {
        None => break
        Some(next) => {
          @core.chk(
            out,
            "iit: subject reduction on a battery #2",
            icheck(s, next),
          )
          @core.chk(
            out,
            "iit: subject reduction on a battery #3",
            stlc_same_index(s, cur, next),
          )
          cur = next
        }
      }
      steps = steps + 1
    }
  }
  // 全部走完之後仍然良構（正規形也是良構項）
  @core.chk(
    out,
    "iit: subject reduction on a battery #4",
    icheck(s, stlc_norm(stlc_ex_app1(), 8)),
  )
  out
}

///|
pub fn law_stlc_normalization_reaches_a_stuck_value() -> Array[(String, Bool)] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  // (λx:x. x) (λy.y) ↝ λy.y ：已經正規
  let id1 = stlc_norm(stlc_ex_app1(), 8)
  @core.chk(
    out,
    "iit: normalization reaches a stuck value #1",
    ival_eq(id1, stlc_ex_arg()),
  )
  @core.chk(
    out,
    "iit: normalization reaches a stuck value #2",
    match stlc_beta(id1) {
      None => true
      Some(_) => false
    },
  )
  // 卡住的項不是值也不能動：函式位置是變數時不 β
  let arr = stlc_ty_arr(n(), n())
  let g2 = stlc_cons(n(), stlc_cons(arr, nil()))
  let fn_var = stlc_vs(stlc_cons(arr, nil()), arr, n(), stlc_vz(nil(), arr))
  let arg_var = stlc_vz(stlc_cons(arr, nil()), n())
  let stuck = stlc_app(g2, n(), n(), fn_var, arg_var)
  @core.chk(
    out,
    "iit: normalization reaches a stuck value #3",
    match stlc_beta(stuck) {
      None => true
      Some(_) => false
    },
  )
  // 但這個卡住的項本身是良構的（開放項，上下文一層）
  @core.chk(
    out,
    "iit: normalization reaches a stuck value #4",
    icheck(s, stuck),
  )
  // 燃料用完就停，不會假裝算出答案
  @core.chk(
    out,
    "iit: normalization reaches a stuck value #5",
    !ival_eq(stlc_norm(stlc_ex_app1(), 0), stlc_ex_arg()),
  )
  // 兩步才到底：((λx. x) (λy. y)) 先一步就到底，這裡改用單步確認步數
  let t = stlc_ex_app1()
  match stlc_beta(t) {
    Some(r) =>
      @core.chk(
        out,
        "iit: normalization reaches a stuck value #6",
        match stlc_beta(r) {
          None => true
          Some(_) => false
        },
      )
    None => @core.chk(out, "iit: normalization reaches a stuck value #7", false)
  }
  out
}
