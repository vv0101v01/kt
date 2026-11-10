// ---------------------------------------------------------------------------
// meta/iit — 三個實例：Nat/Fin、Even/Odd、STLC 的 Ctx/Ty/Tm
// ---------------------------------------------------------------------------
//
// 這三個例子刻意排成難度階梯：
//   Even/Odd  ：互遞迴（索引為空）→ 單一自函子的初始代數就夠
//   Nat/Fin   ：II（索引是前一族的**項**）→ 需要切片塔上的固定點
//   Ctx/Ty/Tm ：II（索引是多索引、且索引運算用到建構子 cons）→ 真正的相依索引
//               這正是 STLC 的定型判斷在 II 裡的寫法。

// ---------------------------------------------------------------------------
// A. Even / Odd（互遞迴，非 II）
// ---------------------------------------------------------------------------

///|
pub fn schema_even_odd() -> ISchema {
  ischema(["Even", "Odd"], [0, 0], [
    ictor("ez", 0, [], []),
    ictor("eo", 0, [], [iarg_rec(1, "o", [])]),
    ictor("oz", 1, [], []),
    ictor("oe", 1, [], [iarg_rec(0, "e", [])]),
  ])
}

// ---------------------------------------------------------------------------
// B. Nat / Fin（II 的最小例子）
// ---------------------------------------------------------------------------

///|
pub fn schema_nat_fin() -> ISchema {
  ischema(["Nat", "Fin"], [0, 1], [
    // Nat
    ictor("z", 0, [], []),
    ictor("s", 0, [], [iarg_rec(0, "n", [])]),
    // Fin : Nat → Type
    // fz : (n : Nat) → Fin (s n)
    ictor("fz", 1, [ictor_ix(1, [ivar(0)])], [iarg_val(0, "n")]),
    // fs : (n : Nat) → Fin n → Fin (s n)
    ictor("fs", 1, [ictor_ix(1, [ivar(0)])], [
      iarg_val(0, "n"),
      iarg_rec(1, "i", [ivar(0)]),
    ]),
  ])
}

///|
pub fn nat_z(_s : ISchema) -> IVal {
  ival(0, [])
}

///|
pub fn nat_s(_s : ISchema, n : IVal) -> IVal {
  ival(1, [n])
}

///|
pub fn nat_of_int(_s : ISchema, n : Int32) -> IVal {
  let mut v = ival(0, [])
  for _i in 0..<n {
    v = ival(1, [v])
  }
  v
}

// ---------------------------------------------------------------------------
// C. STLC：Ctx / Ty / Tm —— 索引裡真的需要 cons
// ---------------------------------------------------------------------------
//
//   Ty  : Type                       Ctx : Type                  Tm : Ctx → Ty → Type
//   nat : Ty                         nil : Ctx                   vz  : (G:Ctx)(A:Ty) → Tm (cons A G) A
//   arr : (A B:Ty) → Ty              cons : (A:Ty)(G:Ctx) → Ctx  vs  : (G)(A)(B) → Tm G A → Tm (cons B G) A
//                                                                lam : (G)(A)(B) → Tm (cons A G) B → Tm G (arr A B)
//                                                                app : (G)(A)(B) → Tm G (arr A B) → Tm G A → Tm G B

///|
pub fn schema_stlc() -> ISchema {
  ischema(["Ty", "Ctx", "Tm"], [0, 0, 2], [
    ictor("nat", 0, [], []),
    ictor("arr", 0, [], [iarg_val(0, "A"), iarg_val(0, "B")]),
    ictor("nil", 1, [], []),
    ictor("cons", 1, [], [iarg_val(0, "A"), iarg_val(1, "G")]),
    // vz : (G : Ctx)(A : Ty) → Tm (cons A G) A
    ictor("vz", 2, [ictor_ix(3, [ivar(1), ivar(0)]), ivar(1)], [
      iarg_val(1, "G"),
      iarg_val(0, "A"),
    ]),
    // vs : (G)(A)(B) → Tm G A → Tm (cons B G) A
    ictor("vs", 2, [ictor_ix(3, [ivar(2), ivar(0)]), ivar(1)], [
      iarg_val(1, "G"),
      iarg_val(0, "A"),
      iarg_val(0, "B"),
      iarg_rec(2, "t", [ivar(0), ivar(1)]),
    ]),
    // app : (G)(A)(B) → Tm G (arr A B) → Tm G A → Tm G B
    ictor("app", 2, [ivar(0), ivar(2)], [
      iarg_val(1, "G"),
      iarg_val(0, "A"),
      iarg_val(0, "B"),
      iarg_rec(2, "f", [ivar(0), ictor_ix(1, [ivar(1), ivar(2)])]),
      iarg_rec(2, "x", [ivar(0), ivar(1)]),
    ]),
    // lam : (G)(A)(B) → Tm (cons A G) B → Tm G (arr A B)
    ictor("lam", 2, [ivar(0), ictor_ix(1, [ivar(1), ivar(2)])], [
      iarg_val(1, "G"),
      iarg_val(0, "A"),
      iarg_val(0, "B"),
      iarg_rec(2, "body", [ictor_ix(3, [ivar(1), ivar(0)]), ivar(2)]),
    ]),
  ])
}

// STLC 的建構子在 stlc.mbt 有唯一定義（這裡只轉發，避免第二份實作漂移）

///|
fn st_nat() -> IVal {
  stlc_ty_nat()
}

///|
fn st_arr(a : IVal, b : IVal) -> IVal {
  stlc_ty_arr(a, b)
}

///|
fn st_nil() -> IVal {
  stlc_nil()
}

///|
fn st_cons(a : IVal, g : IVal) -> IVal {
  stlc_cons(a, g)
}

///|
fn st_vz(g : IVal, a : IVal) -> IVal {
  stlc_vz(g, a)
}

///|
fn st_lam(g : IVal, a : IVal, b : IVal, body : IVal) -> IVal {
  stlc_lam(g, a, b, body)
}

///|
fn st_app(g : IVal, a : IVal, b : IVal, f : IVal, x : IVal) -> IVal {
  stlc_app(g, a, b, f, x)
}

///|
/// Tm 的索引：[(上下文), (型別)] 以 ITerm 表示。
fn tm_index(ctx : IVal, ty : IVal) -> Array[ITerm] {
  [iterm_of_val(ctx), iterm_of_val(ty)]
}

// ---------------------------------------------------------------------------
// 測試
// ---------------------------------------------------------------------------

///|
pub fn law_examples_iit_even_odd_is_plain_mutual_induction_infinite_no_stabilization() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let s = schema_even_odd()
  @core.chk(
    out,
    "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #1",
    iit_ok(ischema_ok(s)),
  )
  // Kleene 鏈：第 1 階段只有兩個零元建構子
  let (e1, _t1) = iit_enumerate(s, 1, 64)
  @core.chk(
    out,
    "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #2",
    e1[0].length() == 1 && e1[1].length() == 1,
  )
  let (e2, _t2) = iit_enumerate(s, 2, 64)
  @core.chk(
    out,
    "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #3",
    e2[0].length() == 2 && e2[1].length() == 2,
  )
  // 互遞迴族是無限的：每一階段都嚴格成長，**不會**穩定
  let (e6, _t6) = iit_enumerate(s, 6, 64)
  @core.chk(
    out,
    "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #4",
    e6[0].length() == 6,
  )
  @core.chk(
    out,
    "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #5",
    e6[0].length() > e2[0].length(),
  )
  // 每個居民都通過索引檢查（索引為空，檢查退化成 sort 檢查）
  for sort_i in 0..<2 {
    for v in e6[sort_i] {
      @core.chk(
        out,
        "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #6",
        icheck(s, v),
      )
      @core.chk(
        out,
        "iit: Even/Odd is plain mutual induction (infinite, no stabilization) #7",
        isort_of(s, v) == sort_i,
      )
    }
  }
  out
}

///|
pub fn law_examples_iit_a_finite_mutual_schema_does_stabilize() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // A = a0 | a1(B) ，B = b0 ：A 有 2 個元素、B 有 1 個 ⇒ 鏈在第 3 階段後恆定
  let s = ischema(["A", "B"], [0, 0], [
    ictor("a0", 0, [], []),
    ictor("a1", 0, [], [iarg_rec(1, "b", [])]),
    ictor("b0", 1, [], []),
  ])
  let (st4, _) = iit_enumerate(s, 4, 64)
  let (st7, _) = iit_enumerate(s, 7, 64)
  @core.chk(
    out,
    "iit: a finite mutual schema does stabilize #1",
    st4[0].length() == 2,
  )
  @core.chk(
    out,
    "iit: a finite mutual schema does stabilize #2",
    st4[1].length() == 1,
  )
  @core.chk(
    out,
    "iit: a finite mutual schema does stabilize #3",
    st7[0].length() == st4[0].length(),
  )
  @core.chk(
    out,
    "iit: a finite mutual schema does stabilize #4",
    st7[1].length() == st4[1].length(),
  )
  out
}

///|
pub fn law_examples_iit_nat_fin_index_checking_and_the_one_stage_phase_lag() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let s = schema_nat_fin()
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #1",
    iit_ok(ischema_ok(s)),
  )
  // 單獨擴張 Fin（第 1 階段）：Fin 一個居民也生不出來，因為 Nat 還是空的
  let (st1, _) = iit_enumerate(s, 1, 128)
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #2",
    st1[1].length() == 0,
  )
  // 第 2 階段：Nat 有 2 個（z, s z），Fin 開始出現
  let (st2, _) = iit_enumerate(s, 2, 128)
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #3",
    st2[0].length() == 2,
  )
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #4",
    st2[1].length() >= 1,
  )
  // 第 3 階段：Fin 有 fz(z)、fz(s z)、fs(z, fz z) 等
  let (st3, _) = iit_enumerate(s, 3, 512)
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #5",
    st3[0].length() == 3,
  )
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #6",
    st3[1].length() >= 3,
  )
  // 關鍵：Fin 的居民索引**確實**是 s(s(...z)) 這種項，且被檢查過
  let fz_of_z = ival(2, [nat_z(s)])
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #7",
    icheck(s, fz_of_z),
  )
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #8",
    isort_of(s, fz_of_z) == 1,
  )
  // fz z : Fin (s z)
  let idx = iindex_of(s, fz_of_z)
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #9",
    idx.length() == 1,
  )
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #10",
    iterm_eq(idx[0], iterm_of_val(nat_of_int(s, 1))),
  )
  // fs z (fz z) : Fin (s z)，索引也對
  let fs_val = ival(3, [
    nat_of_int(s, 1),
    ival(3, [nat_of_int(s, 0), ival(2, [nat_of_int(s, 0)])]),
  ])
  // 上面這個是刻意構造的錯項（內層索引不匹配），必須被拒
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #11",
    !icheck(s, fs_val),
  )
  // 正確版本：fs(s z, fz z) : Fin (s (s z))  —— 注意 n 必須是 s z，不是 z
  let fs_ok = ival(3, [nat_of_int(s, 1), ival(2, [nat_of_int(s, 0)])])
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #12",
    icheck(s, fs_ok),
  )
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #13",
    iterm_eq(iindex_of(s, fs_ok)[0], iterm_of_val(nat_of_int(s, 2))),
  )
  // 而 fs(z, fz z) 必須被拒：fz z 的索引是 s z，不是 z
  let fs_bad = ival(3, [nat_of_int(s, 0), ival(2, [nat_of_int(s, 0)])])
  @core.chk(
    out,
    "iit: Nat/Fin — index checking and the one-stage phase lag #14",
    !icheck(s, fs_bad),
  )
  out
}

///|
pub fn law_examples_iit_kleene_chain_is_monotone_and_every_inhabitant_is_well_typed() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let s = schema_nat_fin()
  let (a, _) = iit_enumerate(s, 2, 256)
  let (b, _) = iit_enumerate(s, 4, 256)
  // 單調：前一段的居民全在後一段
  for v in a[0] {
    let mut hit = false
    for w in b[0] {
      if ival_eq(v, w) {
        hit = true
      }
    }
    @core.chk(
      out, "iit: Kleene chain is monotone and every inhabitant is well-typed #1",
      hit,
    )
  }
  for sort_i in 0..<2 {
    for v in b[sort_i] {
      @core.chk(
        out,
        "iit: Kleene chain is monotone and every inhabitant is well-typed #2",
        icheck(s, v),
      )
      @core.chk(
        out,
        "iit: Kleene chain is monotone and every inhabitant is well-typed #3",
        isort_of(s, v) == sort_i,
      )
    }
  }
  // Nat 的大小隨階段嚴格增加（無限型別的症狀）
  @core.chk(
    out,
    "iit: Kleene chain is monotone and every inhabitant is well-typed #4",
    b[0].length() > a[0].length(),
  )
  out
}

///|
pub fn law_examples_iit_mutual_eliminator_satisfies_the_iota_law_and_termination_is_certified() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let s = schema_nat_fin()
  let (fam, _) = iit_enumerate(s, 4, 256)
  // ι 規則：消除器對建構子的作用 = 對應分支作用在子項的消除結果上
  for sort_i in 0..<2 {
    for v in fam[sort_i] {
      let folded = iit_fold(s, iit_rebuild, v)
      @core.chk(
        out,
        "iit: mutual eliminator satisfies the iota law, and termination is certified #1",
        ival_eq(folded, v),
      )
      // 終止性憑證：每個遞迴子項的序數度量嚴格下降
      @core.chk(
        out,
        "iit: mutual eliminator satisfies the iota law, and termination is certified #2",
        iit_subterm_decrease(s, v),
      )
      // 父項度量嚴格大於子項（直接在序數上比，不只靠布林值）
      let c = s.ctors[v.ctor]
      for i in 0..<v.args.length() {
        match c.args[i] {
          IRec(_, _, _) =>
            @core.chk(
              out,
              "iit: mutual eliminator satisfies the iota law, and termination is certified #3",
              @core.ord_lt(iit_measure(v.args[i]), iit_measure(v)),
            )
          IVal(_, _) => ()
        }
      }
    }
  }
  out
}

///|
pub fn law_examples_iit_stlc_tm_indexed_by_ctx_ty_really_needs_cons_in_the_index() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let s = schema_stlc()
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #1",
    iit_ok(ischema_ok(s)),
  )
  let nat = st_nat()
  let nil = st_nil()
  let arr_nat_nat = st_arr(nat, nat)
  // 恆等項：λx:nat. x。vz 的參數是「上下文的尾巴 G」與 A，
  // 所以它的索引 = cons(A, G) = cons(nat, nil) —— 索引檢查會把這件事驗出來。
  let id_term = st_lam(nil, nat, nat, st_vz(nil, nat))
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #2",
    icheck(s, id_term),
  )
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #3",
    icheck_at(s, id_term, 2, tm_index(nil, arr_nat_nat)),
  )
  // 同一個項不能宣稱成另一種索引（相依型別檢查的核心）
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #4",
    !icheck_at(s, id_term, 2, tm_index(st_cons(nat, nil), arr_nat_nat)),
  )
  // 錯誤的應用：把 (λx:nat. x) 當成 Tm nil nat 使用
  let bad_app = st_app(nil, nat, nat, id_term, id_term)
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #5",
    !icheck(s, bad_app),
  )
  // 正確的應用：((λf.f) (λx:nat. x))，型別是 (arr X X) 作用在 X 上
  let id_at_arr = st_lam(nil, arr_nat_nat, arr_nat_nat, st_vz(nil, arr_nat_nat))
  let good_app = st_app(nil, arr_nat_nat, arr_nat_nat, id_at_arr, id_term)
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #6",
    icheck(s, good_app),
  )
  // 應用結果的索引是 [G, B] = [nil, arr nat nat]
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #7",
    icheck_at(s, good_app, 2, tm_index(nil, arr_nat_nat)),
  )
  // 變數的索引就是「上下文 + 型別」這對
  let v = st_vz(nil, nat)
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #8",
    icheck_at(s, v, 2, tm_index(st_cons(nat, nil), nat)),
  )
  // 錯的上下文長度：把 vz 宣稱成 Tm nil nat
  @core.chk(
    out,
    "iit: STLC — Tm indexed by (Ctx, Ty) really needs cons in the index #9",
    !icheck_at(s, v, 2, tm_index(nil, nat)),
  )
  out
}

///|
pub fn law_examples_iit_index_dependency_graph_is_acyclic_for_all_three_schemas() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  for s in [schema_even_odd(), schema_nat_fin(), schema_stlc()] {
    let edges = iit_index_dependency(s)
    // 自我邊（同一 sort 的遞迴）允許；跨 sort 的邊必須能拓撲排序
    let n = s.sort_names.length()
    let mut acyclic = true
    // Floyd–Warshall 傳遞閉包，檢查是否有「跨 sort 的環」
    let reach : Array[Array[Bool]] = []
    for _i in 0..<n {
      let row : Array[Bool] = []
      for _j in 0..<n {
        row.push(false)
      }
      reach.push(row)
    }
    for (from, to) in edges {
      reach[from][to] = true
    }
    for k in 0..<n {
      for i in 0..<n {
        for j in 0..<n {
          if reach[i][k] && reach[k][j] {
            reach[i][j] = true
          }
        }
      }
    }
    for i in 0..<n {
      for j in 0..<n {
        if i != j && reach[i][j] && reach[j][i] {
          acyclic = false
        }
      }
    }
    @core.chk(
      out, "iit: index-dependency graph is acyclic for all three schemas #1", acyclic,
    )
  }
  // 對照：**資料**依賴圖允許有環（Even/Odd 就是互遞迴），兩者不可混為一談
  let eo = schema_even_odd()
  let dedges = iit_sort_dependency(eo)
  let has_cycle = {
    let mut from0to1 = false
    let mut from1to0 = false
    for (a, b) in dedges {
      if a == 0 && b == 1 {
        from0to1 = true
      }
      if a == 1 && b == 0 {
        from1to0 = true
      }
    }
    from0to1 && from1to0
  }
  @core.chk(
    out, "iit: index-dependency graph is acyclic for all three schemas #2", has_cycle,
  )
  // 但 Even/Odd 沒有任何索引依賴
  @core.chk(
    out,
    "iit: index-dependency graph is acyclic for all three schemas #3",
    iit_index_dependency(eo).length() == 0,
  )
  out
}
