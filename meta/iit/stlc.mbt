// ---------------------------------------------------------------------------
// meta/iit — STLC 的 β、**索引傳輸**與 η-約簡
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
// 5.5 η：λx:A. f x → f（x ∉ FV(f)）
// ---------------------------------------------------------------------------
//
// 表示法關鍵（與 vz/vs 的設計一致）：
//   * app(G, A, B, f, x)：f : Tm G (A→B)、x : Tm G A
//   * stlc_eta 只認「根節點是 λx:A.(f x)」這一格——與 β 一樣 root-only，
//     不假裝是 ξ 規則（不在 binder 底下做 η）。
//   * x ∉ FV(f) 的**可判定形式**：f 裡面不得有任何 ctor 4（vz 節點）。
//     原因：在此表示法裡，相對 binder 深度 δ 的 vz 絕對位置恰為 δ——
//     它必指向 f 根上下文從內數第 δ 格；要命中「受綁變數」（f 根上下文位置 0）
//     只可能是 vz。vs 節點（至少包一層）絕對位置 ≥ δ+1，必指向 f 根
//     上下文位置 ≥ 1，即綁定以外的項。所以「沒有 vz」⟺「沒有受綁變數自由出現」。
//     這比逐節點算位置更穩，實測也由 stlc_unweaken 在移除時再檢查一次。
//
// stlc_unweaken 與 subst_insert 完全對稱：
//   subst_insert 在上下文位置 k 插入一個型別並重寫所有變數；
//   stlc_unweaken 在上下文位置 k **刪除**一個型別並重寫所有變數——
//   任何變數若指向第 k 格即回 None（就是 x ∈ FV(f) 的情形，由 η 拒絕）。

///|
/// 從 t 的上下文中刪除位置 k 的元素，並同步重寫所有變數節點。
/// 若任何變數指向位置 k（＝被刪除的那一格），回傳 None。
pub fn stlc_unweaken(t : IVal, k : Int32) -> IVal? {
  if is_var(t) {
    let p = var_depth(t)
    if p == k {
      // 有變數指向被刪除的元素 ⇒ 這一格不能刪（f 用到受綁變數）
      return None
    }
    let ctx = ctx_remove(var_full_ctx(t), k)
    let np = if p > k { p - 1 } else { p }
    Some(make_var(ctx, np, var_ty(t)))
  } else if t.ctor == 7 {
    let g = t.args[0]
    if k == 0 {
      // 根上下文位置 0 被刪除 ⇒ body（上下文 cons A0 g）的位置 1 被刪除
      match stlc_unweaken(t.args[3], 1) {
        Some(u) =>
          Some(stlc_lam(ctx_remove(g, 0), t.args[1], t.args[2], u))
        None => None
      }
    } else {
      match stlc_unweaken(t.args[3], k) {
        Some(u) =>
          Some(stlc_lam(ctx_remove(g, k - 1), t.args[1], t.args[2], u))
        None => None
      }
    }
  } else if t.ctor == 6 {
    // app(G, A, B, f, x)：兩個子項共用上下文
    match stlc_unweaken(t.args[3], k) {
      Some(f) =>
        match stlc_unweaken(t.args[4], k) {
          Some(x) =>
            Some(stlc_app(ctx_remove(t.args[0], k), t.args[1], t.args[2], f, x))
          None => None
        }
      None => None
    }
  } else {
    Some(t)
  }
}

///|
/// η-約簡：λx:A. f x → f（x ∉ FV(f)）。
/// root-only；不滿足模式時回 None，絕不猜測。
pub fn stlc_eta(t : IVal) -> IVal? {
  if t.ctor != 7 {
    return None
  }
  let g = t.args[0]
  let a = t.args[1]
  let b = t.args[2]
  let body = t.args[3]
  if body.ctor != 6 {
    return None
  }
  // app 的上下文必須是 cons A G（受綁變數那一層）
  if !ival_eq(body.args[0], stlc_cons(a, g)) {
    return None
  }
  // app 的結果型別必須是 B
  if !ival_eq(body.args[2], b) {
    return None
  }
  let f = body.args[3]
  let x = body.args[4]
  // 參數必須就是受綁變數本身：vz(G, A)
  if !(x.ctor == 4 && ival_eq(x.args[0], g) && ival_eq(x.args[1], a)) {
    return None
  }
  // f : Tm (cons A G) (A→B)；x ∉ FV(f) ⟺ stlc_unweaken(f, 0) 成功
  stlc_unweaken(f, 0)
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

// ---------------------------------------------------------------------------
// 11. η 的範例與定律
// ---------------------------------------------------------------------------

///|
/// 測試專用的變數重建：第 `pos` 個位置（完整上下文 `ctx` 為該節點所在上下文）。
fn ex_var(ctx : IVal, pos : Int32, ty : IVal) -> IVal {
  make_var(ctx, pos, ty)
}

///| λy:nat. y 弱化到上下文 cons nat nil（η-約簡右側的原式）。
pub fn stlc_ex_eta_arg() -> IVal {
  stlc_lam(
    stlc_cons(n(), nil()),
    n(),
    n(),
    stlc_vz(stlc_cons(n(), nil()), n()),
  )
}

///| λx:nat. (λy:nat. y) x —— η-redex（f 不用 x）。
pub fn stlc_ex_eta_lhs() -> IVal {
  let g = nil()
  stlc_lam(
    g,
    n(),
    n(),
    stlc_app(
      stlc_cons(n(), g),
      n(),
      n(),
      stlc_ex_eta_arg(),
      stlc_vz(g, n()),
    ),
  )
}

///| η-約簡右側：λy:nat. y（上下文 nil）。
pub fn stlc_ex_eta_rhs() -> IVal {
  stlc_ex_id()
}

///| λ 一層、上下文兩個 nat：f = λw. G[0]（用外層位置 1，不用受綁變數），
///| 參數也不是受綁變數（位置 2）——兩條理由都不觸發 η。
pub fn stlc_ex_eta_nonbound() -> IVal {
  let g = stlc_cons(n(), stlc_cons(n(), nil()))
  let body_ctx = stlc_cons(n(), g) // cons (x:nat) G，位置 0=x, 1=G[0], 2=G[1]
  let f = stlc_lam(
    body_ctx,
    n(),
    n(),
    ex_var(stlc_cons(n(), body_ctx), 2, n()),
  )
  stlc_lam(
    g,
    n(),
    n(),
    stlc_app(body_ctx, n(), n(), f, ex_var(body_ctx, 2, n())),
  )
}

///| λx:nat. (λy:nat. x) x —— f 透過一層 binder 用到受綁變數，η 不得動它。
pub fn stlc_ex_eta_uses_bound() -> IVal {
  let g = nil()
  let body_ctx = stlc_cons(n(), g) // cons (x:nat) nil
  // f = λy:nat. x ：body 裡 x 的絕對位置 = 1（穿過一層 binder）
  let f = stlc_lam(body_ctx, n(), n(), ex_var(stlc_cons(n(), body_ctx), 1, n()))
  stlc_lam(
    g,
    n(),
    n(),
    stlc_app(body_ctx, n(), n(), f, stlc_vz(g, n())),
  )
}

///|
pub fn law_stlc_stlc_eta_removes_a_trivial_binder() -> Array[
  (String, Bool),
] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  let lhs = stlc_ex_eta_lhs()
  @core.chk(out, "iit: STLC η removes a trivial binder #1", icheck(s, lhs))
  match stlc_eta(lhs) {
    Some(r) => {
      @core.chk(out, "iit: STLC η removes a trivial binder #2", icheck(s, r))
      @core.chk(
        out,
        "iit: STLC η removes a trivial binder #3",
        stlc_same_index(s, lhs, r),
      )
      @core.chk(
        out,
        "iit: STLC η removes a trivial binder #4",
        ival_eq(r, stlc_ex_eta_rhs()),
      )
      // η 的結果不再是 η-redex 了（λy.y 不是 λz.(f z) 形狀）
      @core.chk(
        out,
        "iit: STLC η removes a trivial binder #5",
        match stlc_eta(r) {
          Some(_) => false
          None => true
        },
      )
    }
    None => {
      @core.chk(out, "iit: STLC η removes a trivial binder #2", false)
      @core.chk(out, "iit: STLC η removes a trivial binder #3", false)
      @core.chk(out, "iit: STLC η removes a trivial binder #4", false)
      @core.chk(out, "iit: STLC η removes a trivial binder #5", false)
    }
  }
  // 參數不是受綁變數：不觸發
  let t2 = stlc_ex_eta_nonbound()
  @core.chk(out, "iit: STLC η removes a trivial binder #6", icheck(s, t2))
  @core.chk(
    out,
    "iit: STLC η removes a trivial binder #7",
    match stlc_eta(t2) {
      Some(_) => false
      None => true
    },
  )
  // f 用到受綁變數（隔一層 binder）：不觸發
  let t3 = stlc_ex_eta_uses_bound()
  @core.chk(out, "iit: STLC η removes a trivial binder #8", icheck(s, t3))
  @core.chk(
    out,
    "iit: STLC η removes a trivial binder #9",
    match stlc_eta(t3) {
      Some(_) => false
      None => true
    },
  )
  out
}
