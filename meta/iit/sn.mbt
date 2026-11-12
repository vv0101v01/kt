// ---------------------------------------------------------------------------
// meta/iit — STLC 逐項 SN 證書（全歸約樹窮舉，誠實三值）
// ---------------------------------------------------------------------------
//
// 本檔不是「強正規化被證明」的主張。普世陳述「每個良型 STLC 項都強正規化」
// （Tait–Girard 可歸約性）是後設定理，需要邏輯關係；本倉 Lean 凍結、
// MoonBit 也不能表達全稱命題的證明，所以這裡做的是**逐項憑證**：
//
//   `stlc_sn_depth(t, max_nodes)` ：窮舉 t 的完整 one-step 歸約樹
//   （β 與 η，ξ 規則基準，根在任何位置），回傳 Some(k) 表示
//   「每一條歸約路徑的長度都 ≤ k，且此上界由完整樹驗明」；
//   預算不夠 ⇒ None（不是「不 SN」，只是超界，絕不給假陽性）。
//
// 對 STLC 的每個實際項，歸約樹都有限，所以預算足夠時這是**完整**檢查；
// 對預算內無法窮盡的項，誠實回 None。對 Ω = (λx. x x)（λx. x x）這類非 SN
// 輸入（不管是否良型），樹無限 → 預算必超 → None，不會卡死也不會假裝。
//
//   `stlc_sn_tree_typed(s, t, max_nodes)`：窮舉樹上**每一個**節點
//   都跑 icheck，Some(true) = 全部良構；None = 預算超、不是「失敗」。
//   配合 subst_go 的索引保持，這是「型別保持沿所有路徑成立（在本項內）」的檢查。
//
// 邊界與限制（明示，寫進文件）：
//   1. 只檢查被呼叫的那項——不是對所有良型項的全稱定理。
//   2. 預算是「窮舉節點數」不是小步數；共享子項由記憶化命中（結構等式），
//      樹本質指數時只能回 None。
//   3. β∪η 皆納入；η 判準 X ∉ FV(f) 用 stlc_eta 既有的可判定形式。
//   4. 不輸出正規形的策略建議（哪條先約簡都無所謂，因為全部都查了）。

///|
/// 把 i 位置的子項換成 c。
fn replace_child(t : IVal, i : Int32, c : IVal) -> IVal {
  let next : Array[IVal] = []
  for j in 0..<t.args.length() {
    if j == i {
      next.push(c)
    } else {
      next.push(t.args[j])
    }
  }
  ival(t.ctor, next)
}

///|
/// 去除結構相同的重複項（相同的孩子收縮出相同的父項是可能的）。
fn dedupe_ival(ts : Array[IVal]) -> Array[IVal] {
  let out : Array[IVal] = []
  for t in ts {
    let mut seen = false
    for u in out {
      if ival_eq(u, t) {
        seen = true
      }
    }
    if !seen {
      out.push(t)
    }
  }
  out
}

///|
/// 一步歸約，位置不限：在節點自身試 β（stlc_beta）與 η（stlc_eta），
/// 再遞迴地在每個子位置試，以外一次性給出全部結果（去重）。
pub fn stlc_one_step_reducts(t : IVal) -> Array[IVal] {
  let found : Array[IVal] = []
  match stlc_beta(t) {
    Some(r) => found.push(r)
    None => ()
  }
  match stlc_eta(t) {
    Some(r) => found.push(r)
    None => ()
  }
  for i in 0..<t.args.length() {
    let child_reducts = stlc_one_step_reducts(t.args[i])
    for c in child_reducts {
      found.push(replace_child(t, i, c))
    }
  }
  dedupe_ival(found)
}

///|
/// 窮舉上下文：memo（結構等式）+ 節點預算（以 Array[Int32] 盒裝計數）。
priv struct SnCtx {
  memo : Array[(IVal, Int32)]
  budget : Array[Int32]
  max_nodes : Int32
}

///|
fn sn_go(t : IVal, ctx : SnCtx) -> Int32? {
  for (k, v) in ctx.memo {
    if ival_eq(k, t) {
      return Some(v)
    }
  }
  if ctx.budget[0] + 1 > ctx.max_nodes {
    return None
  }
  ctx.budget[0] = ctx.budget[0] + 1
  let reducts = stlc_one_step_reducts(t)
  if reducts.length() == 0 {
    ctx.memo.push((t, 0))
    return Some(0)
  }
  let mut best = 0
  let mut cut = false
  for r in reducts {
    match sn_go(r, ctx) {
      None => cut = true
      Some(d) => if d + 1 > best { best = d + 1 }
    }
  }
  if cut {
    return None
  }
  ctx.memo.push((t, best))
  Some(best)
}

///|
/// 最長歸約路徑長度（β∪η，位置不限）。Some(k) = 完整樹驗明所有路徑 ≤ k；
/// None = 節點預算用完（不是「無法終止」）。
pub fn stlc_sn_depth(t : IVal, max_nodes : Int32) -> Int32? {
  let ctx = SnCtx::{ memo: [], budget: [0], max_nodes, }
  sn_go(t, ctx)
}

///|
/// 窮舉樹上每個節點 icheck 都通過 ⇒ Some(true)；任一失敗 ⇒ Some(false)；
/// 預算超 ⇒ None。
pub fn stlc_sn_tree_typed(s : ISchema, t : IVal, max_nodes : Int32) -> Bool? {
  let ctx = SnCtx::{ memo: [], budget: [0], max_nodes, }
  tree_typed_go(s, t, ctx)
}

///|
fn tree_typed_go(s : ISchema, t : IVal, ctx : SnCtx) -> Bool? {
  for (k, _) in ctx.memo {
    if ival_eq(k, t) {
      return Some(true)
    }
  }
  if ctx.budget[0] + 1 > ctx.max_nodes {
    return None
  }
  ctx.budget[0] = ctx.budget[0] + 1
  if !icheck(s, t) {
    return Some(false)
  }
  ctx.memo.push((t, 0))
  let mut fail = false
  for r in stlc_one_step_reducts(t) {
    match tree_typed_go(s, r, ctx) {
      None => return None
      Some(false) => fail = true
      Some(true) => ()
    }
  }
  Some(!fail)
}

// ---------------------------------------------------------------------------
// 範例項（只為定律服務；建構寫法即規格）
// ---------------------------------------------------------------------------

///|
/// `K = λx:nat→nat. λy:nat→nat. x`（ nat→nat 上的 K 組合子）。
pub fn stlc_ex_k() -> IVal {
  let nn = stlc_ty_arr(n(), n())
  stlc_lam(
    nil(),
    nn,
    stlc_ty_arr(nn, nn),
    stlc_lam(
      stlc_cons(nn, nil()),
      nn,
      nn,
      stlc_vs(stlc_cons(nn, nil()), nn, nn, stlc_vz(nil(), nn)),
    ),
  )
}

///|
/// `(K id) id` —— 兩步 β 後回到 id；根不是 redex，只能先約簡函式位置。
pub fn stlc_ex_k_app() -> IVal {
  let nn = stlc_ty_arr(n(), n())
  let k_id = stlc_app(nil(), nn, stlc_ty_arr(nn, nn), stlc_ex_k(), stlc_ex_id())
  stlc_app(nil(), nn, nn, k_id, stlc_ex_id())
}

///|
/// `(λx:nat→nat. (λy:nat→nat. y) (weaken id)) id` ——
/// 箱內 `(λy. y) (weaken id)` 是獨立於根 β 的子項 redex；兩條路徑
/// 收縮到**不同**的項（差在 x 有無被用上），去重後恰好 2 個一步歸約。
/// （若子項參數直接用 x 本身，三條路徑會收斂到同一項、去重後長度 1——曾踩坑。）
pub fn stlc_ex_sn_two_positions() -> IVal {
  let nn = stlc_ty_arr(n(), n())
  let wid = stlc_weaken(stlc_ex_id(), nn)
  let inner_app = stlc_app(
    stlc_cons(nn, nil()),
    nn,
    nn,
    stlc_lam(stlc_cons(nn, nil()), nn, nn, stlc_vz(stlc_cons(nn, nil()), nn)),
    wid,
  )
  stlc_app(nil(), nn, nn, stlc_lam(nil(), nn, nn, inner_app), stlc_ex_id())
}

///|
/// `λh:nat→nat. λx:nat. h x` —— 內層 λ 是 η-redex（位置 1）；
/// 唯一一步歸約得 `λh. h`（＝`stlc_ex_id()`）。
pub fn stlc_ex_eta_deep() -> IVal {
  let nn = stlc_ty_arr(n(), n())
  let g1 = stlc_cons(nn, nil())
  let g2 = stlc_cons(n(), g1)
  let h = stlc_vs(g1, nn, n(), stlc_vz(nil(), nn))
  let x_var = stlc_vz(g1, n())
  let body = stlc_app(g2, n(), n(), h, x_var)
  let inner = stlc_lam(g1, n(), n(), body)
  stlc_lam(nil(), nn, stlc_ty_arr(n(), n()), inner)
}

///|
/// `λh:nat→nat. h` —— `stlc_ex_eta_deep()` 的 η-約簡結果。
pub fn stlc_ex_fid() -> IVal {
  let nn = stlc_ty_arr(n(), n())
  stlc_lam(nil(), nn, nn, stlc_vz(nil(), nn))
}

// ---------------------------------------------------------------------------
// 定律
// ---------------------------------------------------------------------------

///|
/// 對一批封閉良型項發 SN 證書：逐項 depth 非 None、且整棵樹每個節點 icheck 通過。
pub fn law_stlc_sn_certificates_cover_a_battery() -> Array[(String, Bool)] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  let battery : Array[(String, IVal)] = [
    ("id", stlc_ex_id()),
    ("app1", stlc_ex_app1()),
    ("app2", stlc_ex_app2()),
    ("k_app", stlc_ex_k_app()),
    ("eta_deep", stlc_ex_eta_deep()),
    ("open_var", stlc_ex_var()),
  ]
  let mut good_depth = true
  let mut good_typed = true
  for (nm, t) in battery {
    @core.chk(out, "iit: sn battery is well-formed (\{nm})", icheck(s, t))
    match stlc_sn_depth(t, 4096) {
      Some(_) => ()
      None => good_depth = false
    }
    match stlc_sn_tree_typed(s, t, 4096) {
      Some(true) => ()
      _ => good_typed = false
    }
  }
  @core.chk(
    out, "iit: sn battery: every term has a finite certificate", good_depth,
  )
  @core.chk(
    out, "iit: sn battery: every node of every path type-checks", good_typed,
  )
  out
}

///|
/// 精確深度：id / app1 / app2 / eta_deep（手算可覆核，錯誤就讓定律砸出來）。
pub fn law_stlc_sn_depth_is_exact_for_small_terms() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  @core.chk(
    out,
    "iit: sn depth(stlc_ex_id()) == Some(0)",
    match stlc_sn_depth(stlc_ex_id(), 16) {
      Some(0) => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn depth(stlc_ex_app1()) == Some(1)",
    match stlc_sn_depth(stlc_ex_app1(), 16) {
      Some(1) => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn depth(stlc_ex_app2()) == Some(1)",
    match stlc_sn_depth(stlc_ex_app2(), 16) {
      Some(1) => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn depth(stlc_ex_eta_deep()) == Some(1)",
    match stlc_sn_depth(stlc_ex_eta_deep(), 64) {
      Some(1) => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn depth(stlc_ex_k_app()) == Some(2)",
    match stlc_sn_depth(stlc_ex_k_app(), 256) {
      Some(2) => true
      _ => false
    },
  )
  out
}

///|
/// `stlc_one_step_reducts` 窮舉所有位置：根 redex 與任意深度的 redex 都被找到，
/// 且兩個不同位置的收縮給出**不同**的項（去過重）。
pub fn law_stlc_sn_reducts_enumerate_all_positions() -> Array[(String, Bool)] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  let t = stlc_ex_sn_two_positions()
  let rs = stlc_one_step_reducts(t)
  @core.chk(
    out,
    "iit: sn reducts of two_positions has exactly 2 results",
    rs.length() == 2,
  )
  for r in rs {
    @core.chk(
      out,
      "iit: sn reduct preserves the index (position law)",
      stlc_same_index(s, t, r),
    )
  }
  let rs1 = stlc_one_step_reducts(stlc_ex_app1())
  @core.chk(
    out,
    "iit: sn reducts of app1 is the single beta step",
    rs1.length() == 1,
  )
  out
}

///|
/// η 收縮納入歸約樹：λh. λx. h x 的唯一子代收縮是內層 η，得到 λh. h。
pub fn law_stlc_sn_eta_redex_is_explored() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let t = stlc_ex_eta_deep()
  let rs = stlc_one_step_reducts(t)
  @core.chk(
    out,
    "iit: sn eta_deep has exactly one one-step reduct",
    rs.length() == 1,
  )
  @core.chk(
    out,
    "iit: sn eta_deep reduces to stlc_ex_fid()",
    rs.length() == 1 && ival_eq(rs[0], stlc_ex_fid()),
  )
  out
}

///|
/// 預算是誠實的：預算超 ⇒ None（不是 false / 不是「不 SN」）；
/// 卡住（depth 0）或樹完全展開所需的預算 1 才勉強 ⇒ None 是正確回應。
pub fn law_stlc_sn_budget_is_three_valued() -> Array[(String, Bool)] {
  let s = schema_stlc()
  let out : Array[(String, Bool)] = []
  @core.chk(
    out,
    "iit: sn depth over budget is None (not false)",
    match stlc_sn_depth(stlc_ex_app1(), 1) {
      None => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn depth of irreducible term fits in budget 1",
    match stlc_sn_depth(stlc_ex_id(), 1) {
      Some(0) => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn tree_typed over budget is None",
    match stlc_sn_tree_typed(s, stlc_ex_app2(), 1) {
      None => true
      _ => false
    },
  )
  @core.chk(
    out,
    "iit: sn tree_typed of irreducible term fits in budget 1",
    match stlc_sn_tree_typed(s, stlc_ex_id(), 1) {
      Some(true) => true
      _ => false
    },
  )
  out
}

///|
/// 測度沿每一步嚴格下降：為每條邊 (t → r)，longest-path 深度必然遞減。
/// （這就是「以最長路徑為序的良好基底」的可執行影子。）
pub fn law_stlc_sn_measure_decreases_along_every_step() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let battery : Array[(String, IVal)] = [
    ("app1", stlc_ex_app1()),
    ("app2", stlc_ex_app2()),
    ("k_app", stlc_ex_k_app()),
    ("eta_deep", stlc_ex_eta_deep()),
    ("two_positions", stlc_ex_sn_two_positions()),
  ]
  let mut decreases = true
  for (_, t) in battery {
    match stlc_sn_depth(t, 4096) {
      None => decreases = false
      Some(d) =>
        for r in stlc_one_step_reducts(t) {
          match stlc_sn_depth(r, 4096) {
            Some(dr) => if d <= dr { decreases = false }
            None => decreases = false
          }
        }
    }
  }
  @core.chk(
    out, "iit: sn measure decreases along every one-step reduction (battery)", decreases,
  )
  out
}
