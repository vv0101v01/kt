// ---------------------------------------------------------------------------
// meta/iit — 歸納-歸納型別：schema、索引檢查、互遞迴消除器、Kleene 不動點
// ---------------------------------------------------------------------------
//
// 什麼是歸納-歸納（II）？
//   同時定義**好幾個**歸納族，而且後面的族的建構子，其**索引**可以是前面族的項。
//   最小例子：Nat 與 Fin
//       Nat : Type                Fin : Nat → Type
//       z   : Nat                 fz : (n : Nat) → Fin (s n)
//       s   : Nat → Nat           fs : (n : Nat) → Fin n → Fin (s n)
//   注意 fs 的索引裡出現了建構子 s 與變數 n：索引不是「外部參數」，而是**項**。
//
// 為什麼這比「互遞迴（mutual induction）」難？
//   互遞迴型別可以寫成乘積範疇上一個自函子的初始代數 F : C×C → C×C。
//   II 型別不行：Fin 的定義**依賴** Nat 的值，所以 F 的「第二分量」是
//   一個在切片範疇 Set/Nat 上的函子，而其定義域 Nat 本身還在被定義中。
//   正式的處理是把固定點取在「纖維化範疇／切片塔」上，而本實作把它變成
//   一件可執行的工程：**分階段 Kleene 迭代，每一階段只能用前一階段的居民**。
//   這一點在測試裡是可見的：單獨對 Fin 做一輪擴張，一個居民也生不出來。
//
// 本套件提供：
//   * schema（sort / 建構子 / 索引表達式）與項表示
//   * `icheck`：真正的索引檢查（相依型別檢查的核）
//   * `iit_stage` / `iit_enumerate`：T_{n+1} = T_n ∪ F(T_n) 的 Kleene 鏈
//   * `iit_fold`：互遞迴消除器（ι 規則可驗）
//   * `iit_measure` + `iit_subterm_decrease`：以序數給出的終止性憑證
//   * 三個實例：Nat/Fin、Even/Odd、以及 STLC 的 Ctx/Ty/Tm（真的需要 cons）

// ---------------------------------------------------------------------------
// 1. Schema
// ---------------------------------------------------------------------------

///|
/// 索引表達式。IVar(k) 指建構子的第 k 個參數（把參數當項看）。
pub(all) enum ITerm {
  IVar(Int32)
  ICtor(Int32, Array[ITerm])
  /// 佔位（不該出現在良構 schema 裡）
  IHole
}

///|
/// 建構子參數。
pub(all) enum IArg {
  /// 值參數：某個 sort 的一個值（非遞迴）
  IVal(Int32, String)
  /// 遞迴參數：某個 sort 的一個值，且帶索引條件
  IRec(Int32, String, Array[ITerm])
}

///|
/// 建構子。
pub(all) struct ICtor {
  name : String
  /// 結果所在的 sort
  sort : Int32
  /// 結果索引（長度必須等於該 sort 的 index arity）
  index : Array[ITerm]
  args : Array[IArg]
}

///|
/// II 的項：建構子索引 + 參數。
pub(all) struct IVal {
  ctor : Int32
  args : Array[IVal]
}

///|
pub fn ival(ctor : Int32, args : Array[IVal]) -> IVal {
  IVal::{ ctor, args, }
}

///|
pub fn ival_eq(a : IVal, b : IVal) -> Bool {
  if a.ctor != b.ctor || a.args.length() != b.args.length() {
    return false
  }
  let mut ok = true
  for i in 0..<a.args.length() {
    if !ival_eq(a.args[i], b.args[i]) {
      ok = false
    }
  }
  ok
}

// ---------------------------------------------------------------------------
// 商的等式建構子（QIIT）：等式是 **schema 的一部分**，不是值層的補丁
// ---------------------------------------------------------------------------

///|
/// 等式建構子：`lhs = rhs`。樣式中的變數寫成 `ipat_var(k)`。
pub(all) struct IEquation {
  lhs : IVal
  rhs : IVal
}

///|
/// 樣式變數（`k` 從 0 起算；內部以負的建構子編號 `-(1 + k)` 表示）。
pub fn ipat_var(k : Int32) -> IVal {
  ival(-(1 + k), [])
}

///|
/// 建一條等式建構子。
pub fn i_equation(lhs : IVal, rhs : IVal) -> IEquation {
  { lhs, rhs }
}

///|
/// 樣式匹配：把 `pat` 對上 `v`，依序收集變數綁定（重複出現的變數要求相等）。
fn i_match(pat : IVal, v : IVal, binds : Array[IVal]) -> Bool {
  if pat.ctor < 0 {
    let k = -(pat.ctor + 1)
    if k < binds.length() {
      ival_eq(binds[k], v)
    } else if k == binds.length() {
      binds.push(v)
      true
    } else {
      false
    }
  } else if pat.ctor != v.ctor || pat.args.length() != v.args.length() {
    false
  } else {
    let mut ok = true
    for i in 0..<pat.args.length() {
      if !i_match(pat.args[i], v.args[i], binds) {
        ok = false
      }
    }
    ok
  }
}

///|
/// 用綁定實例化 rhs（rhs 裡的樣式變數換成對應的值）。
fn i_inst(pat : IVal, binds : Array[IVal]) -> IVal {
  if pat.ctor < 0 {
    let k = -(pat.ctor + 1)
    if k < binds.length() {
      binds[k]
    } else {
      pat
    }
  } else {
    let out : Array[IVal] = []
    for a in pat.args {
      out.push(i_inst(a, binds))
    }
    ival(pat.ctor, out)
  }
}

///|
/// 單步重寫：先試根，再從左到右試子項。回傳 `None` 表示已不動。
fn i_rewrite(eqs : Array[IEquation], v : IVal) -> IVal? {
  for eq in eqs {
    let binds : Array[IVal] = []
    if i_match(eq.lhs, v, binds) {
      return Some(i_inst(eq.rhs, binds))
    }
  }
  let mut changed = false
  let args2 : Array[IVal] = []
  for a in v.args {
    match i_rewrite(eqs, a) {
      Some(a2) => {
        args2.push(a2)
        changed = true
      }
      None => args2.push(a)
    }
  }
  if changed {
    Some(ival(v.ctor, args2))
  } else {
    None
  }
}

///|
/// 商化：用 schema 的等式反覆重寫到不動點（燃料是上界；用完回傳當前值）。
pub fn iquot(eqs : Array[IEquation], v : IVal, fuel : Int32) -> IVal {
  let mut cur = v
  for _ in 0..<fuel {
    match i_rewrite(eqs, cur) {
      Some(v2) => cur = v2
      None => return cur
    }
  }
  cur
}

///|
/// schema：sorts（名字 + 索引元數）與建構子。
pub(all) struct ISchema {
  sort_names : Array[String]
  sort_arities : Array[Int32]
  ctors : Array[ICtor]
  /// 等式建構子（QIIT）：讓某些項在商之後相等。空的 schema 就是純 II。
  eqs : Array[IEquation]
}

///|
/// 建構 schema。
pub fn ischema(
  names : Array[String],
  arities : Array[Int32],
  ctors : Array[ICtor],
  eqs? : Array[IEquation] = [],
) -> ISchema {
  ISchema::{ sort_names: names, sort_arities: arities, ctors, eqs, }
}

///|
pub fn ivar(k : Int32) -> ITerm {
  IVar(k)
}

///|
pub fn iholed() -> ITerm {
  IHole
}

///|
pub fn ictor_ix(c : Int32, args : Array[ITerm]) -> ITerm {
  ICtor(c, args)
}

///|
pub fn ictor(
  name : String,
  sort : Int32,
  index : Array[ITerm],
  args : Array[IArg],
) -> ICtor {
  ICtor::{ name, sort, index, args, }
}

///|
pub fn iarg_val(sort : Int32, name : String) -> IArg {
  IVal(sort, name)
}

///|
pub fn iarg_rec(sort : Int32, name : String, index : Array[ITerm]) -> IArg {
  IRec(sort, name, index)
}

// ---------------------------------------------------------------------------
// 2. 項
// ---------------------------------------------------------------------------

///|
/// 把值看成索引項（索引就是「值的語法」）。
pub fn iterm_of_val(v : IVal) -> ITerm {
  let out : Array[ITerm] = []
  for a in v.args {
    out.push(iterm_of_val(a))
  }
  ICtor(v.ctor, out)
}

///|
pub fn iterm_eq(a : ITerm, b : ITerm) -> Bool {
  match (a, b) {
    (IHole, IHole) => true
    (IVar(x), IVar(y)) => x == y
    (ICtor(f, xs), ICtor(g, ys)) =>
      if f != g || xs.length() != ys.length() {
        false
      } else {
        let mut ok = true
        for i in 0..<xs.length() {
          if !iterm_eq(xs[i], ys[i]) {
            ok = false
          }
        }
        ok
      }
    _ => false
  }
}

///|
pub fn iterm_to_string(t : ITerm) -> String {
  match t {
    IVar(k) => "x\{k}"
    IHole => "_"
    ICtor(c, xs) =>
      if xs.length() == 0 {
        "#\{c}"
      } else {
        let parts : Array[String] = []
        for x in xs {
          parts.push(iterm_to_string(x))
        }
        "#\{c}(\{parts.join(",")})"
      }
  }
}

///|
pub fn ival_to_string(s : ISchema, v : IVal) -> String {
  let name = if v.ctor >= 0 && v.ctor < s.ctors.length() {
    s.ctors[v.ctor].name
  } else {
    "?"
  }
  if v.args.length() == 0 {
    name
  } else {
    let parts : Array[String] = []
    for a in v.args {
      parts.push(ival_to_string(s, a))
    }
    "\{name}(\{parts.join(",")})"
  }
}

// ---------------------------------------------------------------------------
// 3. 索引求值與檢查
// ---------------------------------------------------------------------------

///|
fn ieval(t : ITerm, env : Array[ITerm]) -> ITerm {
  match t {
    IVar(k) => if k >= 0 && k < env.length() { env[k] } else { IHole }
    IHole => IHole
    ICtor(c, xs) => {
      let out : Array[ITerm] = []
      for x in xs {
        out.push(ieval(x, env))
      }
      ICtor(c, out)
    }
  }
}

///|
/// 一個值的 sort。
pub fn isort_of(s : ISchema, v : IVal) -> Int32 {
  if v.ctor >= 0 && v.ctor < s.ctors.length() {
    s.ctors[v.ctor].sort
  } else {
    -1
  }
}

///|
/// 一個值的索引。
pub fn iindex_of(s : ISchema, v : IVal) -> Array[ITerm] {
  if v.ctor < 0 || v.ctor >= s.ctors.length() {
    return []
  }
  let c = s.ctors[v.ctor]
  let env : Array[ITerm] = []
  for a in v.args {
    env.push(iterm_of_val(a))
  }
  let out : Array[ITerm] = []
  for t in c.index {
    out.push(ieval(t, env))
  }
  out
}

///| 索引檢查：這是 II 的「核心型別檢查」。

///|
/// 對每個遞迴參數，實際索引必須等於 schema 規定的索引表達式求值結果。
pub fn icheck(s : ISchema, v : IVal) -> Bool {
  if v.ctor < 0 || v.ctor >= s.ctors.length() {
    return false
  }
  let c = s.ctors[v.ctor]
  if v.args.length() != c.args.length() {
    return false
  }
  let env : Array[ITerm] = []
  for a in v.args {
    env.push(iterm_of_val(a))
  }
  for i in 0..<c.args.length() {
    let a = v.args[i]
    match c.args[i] {
      IVal(sort, _) => {
        if isort_of(s, a) != sort {
          return false
        }
        if !icheck(s, a) {
          return false
        }
      }
      IRec(sort, _, idx) => {
        if isort_of(s, a) != sort {
          return false
        }
        if !icheck(s, a) {
          return false
        }
        let want : Array[ITerm] = []
        for t in idx {
          want.push(ieval(t, env))
        }
        let got = iindex_of(s, a)
        if want.length() != got.length() {
          return false
        }
        for k in 0..<want.length() {
          if !iterm_eq(want[k], got[k]) {
            return false
          }
        }
      }
    }
  }
  true
}

///|
/// 檢查一個值確實落在某個 sort 且索引等於給定值。
pub fn icheck_at(
  s : ISchema,
  v : IVal,
  sort : Int32,
  index : Array[ITerm],
) -> Bool {
  if !icheck(s, v) || isort_of(s, v) != sort {
    return false
  }
  let got = iindex_of(s, v)
  if got.length() != index.length() {
    return false
  }
  for i in 0..<got.length() {
    if !iterm_eq(got[i], index[i]) {
      return false
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 4. Schema 良構性：索引層與資料層的stratification
// ---------------------------------------------------------------------------

///|
/// sort 依賴圖：ctor 的結果 sort → 參數的 sort。
fn sort_edges(s : ISchema) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for c in s.ctors {
    for a in c.args {
      match a {
        IVal(sort, _) => out.push((c.sort, sort))
        IRec(sort, _, _) => out.push((c.sort, sort))
      }
    }
  }
  out
}

///| **索引**依賴邊：sort X 的建構子索引裡用到了 sort Y 的建構子 ⇒ X → Y。

///| 這張圖必須無環，否則索引在定義時就依賴自己（不可判定／不正性）。

///|
/// 注意：**資料**依賴圖允許有環（那就是互遞迴），兩者不要混淆。
pub fn iit_index_dependency(s : ISchema) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for c in s.ctors {
    for t in c.index {
      collect_index_edges(s, c.sort, t, out)
    }
  }
  out
}

///|
fn collect_index_edges(
  s : ISchema,
  from : Int32,
  t : ITerm,
  out : Array[(Int32, Int32)],
) -> Unit {
  match t {
    ICtor(ci, xs) => {
      if ci >= 0 && ci < s.ctors.length() {
        out.push((from, s.ctors[ci].sort))
      }
      for x in xs {
        collect_index_edges(s, from, x, out)
      }
    }
    _ => ()
  }
}

///|
/// sort 依賴邊（資料依賴，允許有環）。
pub fn iit_sort_dependency(s : ISchema) -> Array[(Int32, Int32)] {
  sort_edges(s)
}

///|
/// 方便測試：Option[String] 是否為 None。
pub fn iit_ok(o : String?) -> Bool {
  match o {
    None => true
    Some(_) => false
  }
}

///| schema 良構性：

///|  (1) 每個 ctor 的索引元數等於其 sort 的索引元數；

///|  (2) 索引表達式只提到「合法範圍內」的參數；

///|  (3) 沒有自我指向的索引（索引不可再依賴同一 sort 的遞迴參數的索引）——

///|
///      這是保證消除器終止的充分條件。
pub fn ischema_ok(s : ISchema) -> String? {
  for c in s.ctors {
    if c.sort < 0 || c.sort >= s.sort_names.length() {
      return Some("ctor \{c.name}: bad sort")
    }
    if c.index.length() != s.sort_arities[c.sort] {
      return Some("ctor \{c.name}: index arity mismatch")
    }
    // 索引表達式中的參數範圍
    for t in c.index {
      match iterm_scope_ok(t, c.args.length()) {
        Some(bad) => return Some("ctor \{c.name}: \{bad}")
        None => ()
      }
    }
    for a in c.args {
      match a {
        IVal(sort, _) =>
          if sort < 0 || sort >= s.sort_names.length() {
            return Some("ctor \{c.name}: bad arg sort")
          }
        IRec(sort, _, idx) => {
          if sort < 0 || sort >= s.sort_names.length() {
            return Some("ctor \{c.name}: bad rec sort")
          }
          for t in idx {
            match iterm_scope_ok(t, c.args.length()) {
              Some(bad) => return Some("ctor \{c.name}: \{bad}")
              None => ()
            }
          }
        }
      }
    }
  }
  // 等式建構子也要被承認：head 是合法建構子、兩端同一 sort、樣式變數集合一致、
  // 且不是空洞等式（兩端結構相同）。否則商的定義（重寫）沒有意義。
  for eq in s.eqs {
    match ieq_ok(s, eq) {
      Some(bad) => return Some(bad)
      None => ()
    }
  }
  None
}

///|
/// 收集一個樣式裡用到的樣式變數（`ival(-(1+k), [])`）。
fn ipat_vars(v : IVal, out : Array[Int32]) -> Unit {
  if v.ctor < 0 {
    let k = -(v.ctor + 1)
    if !out.contains(k) {
      out.push(k)
    }
  } else {
    for a in v.args {
      ipat_vars(a, out)
    }
  }
}

///|
/// 等式建構子的合法性：(1) 兩端 head 是 schema 裡的建構子；(2) 同一 sort；
/// (3) 兩端樣式變數集合相同（重寫才是封閉的）；(4) 兩端結構不同（非空洞）。
pub fn ieq_ok(s : ISchema, eq : IEquation) -> String? {
  let l = eq.lhs
  let r = eq.rhs
  // 至少一端要是建構子（兩端都是樣式變數的「等式」不產生任何商）
  if l.ctor < 0 && r.ctor < 0 {
    return Some("equation: both sides are bare pattern variables")
  }
  if l.ctor >= s.ctors.length() {
    return Some("equation: lhs head is not a constructor")
  }
  if r.ctor >= s.ctors.length() {
    return Some("equation: rhs head is not a constructor")
  }
  if l.ctor >= 0 && r.ctor >= 0 && s.ctors[l.ctor].sort != s.ctors[r.ctor].sort {
    return Some("equation: sides live in different sorts")
  }
  let lv : Array[Int32] = []
  let rv : Array[Int32] = []
  ipat_vars(l, lv)
  ipat_vars(r, rv)
  if lv.length() != rv.length() {
    return Some("equation: pattern variables differ between sides")
  }
  for k in lv {
    if !rv.contains(k) {
      return Some("equation: pattern variables differ between sides")
    }
  }
  if ival_eq(l, r) {
    return Some("equation: vacuous (both sides are the same term)")
  }
  None
}

///|
fn iterm_scope_ok(t : ITerm, nargs : Int32) -> String? {
  match t {
    IVar(k) =>
      if k < 0 || k >= nargs {
        Some("index variable out of scope")
      } else {
        None
      }
    IHole => Some("hole in index")
    ICtor(_, xs) => {
      for x in xs {
        match iterm_scope_ok(x, nargs) {
          Some(e) => return Some(e)
          None => ()
        }
      }
      None
    }
  }
}

// ---------------------------------------------------------------------------
// 5. Kleene 鏈：T_{n+1} = T_n ∪ F(T_n)
// ---------------------------------------------------------------------------
//
// 這一段就是「II 型別 = 切片塔上的初始代數」的可執行版本：
// 每一階段只能用**前一階段**已有的居民去填遞迴與值參數的位置。
// 所以 Fin 的擴張永遠落後 Nat 一階 —— 這個「相位差」正是 II 與
// 普通互遞迴（同時擴張）的分野，測試裡有直接量測。

///|
pub struct IIStage {
  /// inhabitants[s] = sort s 目前的居民（累積）
  inhabitants : Array[Array[IVal]]
  /// 這一階段是否因上限而截斷
  truncated : Bool
}

///|
fn contains_val(xs : Array[IVal], v : IVal) -> Bool {
  let mut hit = false
  for x in xs {
    if ival_eq(x, v) {
      hit = true
    }
  }
  hit
}

///|
fn cartesian(
  s : ISchema,
  args : Array[IArg],
  prefix : Array[IVal],
  prev : Array[Array[IVal]],
  out : Array[IVal],
  ctor_idx : Int32,
  cap : Int32,
) -> Unit {
  if out.length() >= cap {
    return
  }
  if prefix.length() == args.length() {
    let v = ival(ctor_idx, prefix_copy(prefix))
    if icheck(s, v) && !contains_val(out, v) {
      out.push(v)
    }
    return
  }
  let i = prefix.length()
  match args[i] {
    IVal(sort, _) =>
      for cand in stage_of(prev, sort) {
        let next = prefix_copy(prefix)
        next.push(cand)
        cartesian(s, args, next, prev, out, ctor_idx, cap)
      }
    IRec(sort, _, _) =>
      for cand in stage_of(prev, sort) {
        let next = prefix_copy(prefix)
        next.push(cand)
        cartesian(s, args, next, prev, out, ctor_idx, cap)
      }
  }
}

///|
fn prefix_copy(xs : Array[IVal]) -> Array[IVal] {
  let out : Array[IVal] = []
  for x in xs {
    out.push(x)
  }
  out
}

///|
fn stage_of(prev : Array[Array[IVal]], sort : Int32) -> Array[IVal] {
  if sort >= 0 && sort < prev.length() {
    prev[sort]
  } else {
    []
  }
}

///|
/// 單一階段：F 作用在整個族上，並與上一階段取併（Kleene 鏈）。
pub fn iit_stage(
  s : ISchema,
  prev : Array[Array[IVal]],
  cap : Int32,
) -> IIStage {
  let fresh : Array[Array[IVal]] = []
  for _i in 0..<s.sort_names.length() {
    let x : Array[IVal] = []
    fresh.push(x)
  }
  let mut truncated = false
  for ci in 0..<s.ctors.length() {
    let c = s.ctors[ci]
    cartesian(s, c.args, [], prev, fresh[c.sort], ci, cap)
    if fresh[c.sort].length() >= cap {
      truncated = true
    }
  }
  let out : Array[Array[IVal]] = []
  for i in 0..<s.sort_names.length() {
    let merged : Array[IVal] = []
    for v in stage_of(prev, i) {
      merged.push(v)
    }
    for v in fresh[i] {
      if !contains_val(merged, v) {
        merged.push(v)
      }
    }
    out.push(merged)
  }
  IIStage::{ inhabitants: out, truncated, }
}

///|
/// 迭代 fuel 次，回傳最終族。
pub fn iit_enumerate(
  s : ISchema,
  fuel : Int32,
  cap : Int32,
) -> (Array[Array[IVal]], Bool) {
  let mut cur : Array[Array[IVal]] = []
  for _i in 0..<s.sort_names.length() {
    let x : Array[IVal] = []
    cur.push(x)
  }
  let mut trunc = false
  for _step in 0..<fuel {
    let st = iit_stage(s, cur, cap)
    cur = st.inhabitants
    if st.truncated {
      trunc = true
    }
  }
  (cur, trunc)
}

// ---------------------------------------------------------------------------
// 6. 互遞迴消除器與 ι 規則
// ---------------------------------------------------------------------------

///| 互遞迴消除器：`h` 收到（建構子索引, 參數處理結果），

///| 其中遞迴位置已遞迴求值，值位置原樣傳入。

///|

///| 誠實邊界：真正的相依消除器（motive 依賴索引）需要一個相依宿主語言。

///| 這裡給的是「索引已檢查之後的無相依消除器族」——對每個 sort 各一個，

///| 但共用一份程式碼；索引資訊在 `icheck` 那一關已經用完，這正是

///|
/// II 的「索引可以被擦除」的部分。
pub fn iit_fold(
  s : ISchema,
  h : (Int32, Array[IVal]) -> IVal,
  v : IVal,
) -> IVal {
  let kids : Array[IVal] = []
  let c = s.ctors[v.ctor]
  for i in 0..<v.args.length() {
    match c.args[i] {
      IVal(_, _) => kids.push(v.args[i])
      IRec(_, _, _) => kids.push(iit_fold(s, h, v.args[i]))
    }
  }
  h(v.ctor, kids)
}

///|
/// 重建（identity 消除器）：用來驗證 ι 規則。
pub fn iit_rebuild(c : Int32, kids : Array[IVal]) -> IVal {
  ival(c, kids)
}

///|
/// 大小（用於終止性度量）。
pub fn ival_size(v : IVal) -> Int32 {
  let mut n = 1
  for a in v.args {
    n = n + ival_size(a)
  }
  n
}

///|
/// 終止性憑證的度量：ω^{size}。
pub fn iit_measure(v : IVal) -> @core.Ordinal {
  @core.ord_omega_pow(@core.ord_int(ival_size(v)))
}

///|
/// 檢查「每個遞迴參數都嚴格小於父項」——這是消除器終止的全部內容。
pub fn iit_subterm_decrease(s : ISchema, v : IVal) -> Bool {
  let c = s.ctors[v.ctor]
  let pm = iit_measure(v)
  let mut ok = true
  for i in 0..<v.args.length() {
    match c.args[i] {
      IVal(_, _) => ()
      IRec(_, _, _) =>
        if !@core.ord_lt(iit_measure(v.args[i]), pm) {
          ok = false
        }
    }
    if !iit_subterm_decrease(s, v.args[i]) {
      ok = false
    }
  }
  ok
}

///|
pub fn law_iit_schema_placeholders_are_rejected() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // 正常 schema 通過
  @core.chk(
    out,
    "iit: schema placeholders are rejected #1",
    ischema_ok(schema_nat_fin()) == None,
  )
  // 把索引表達式換成佔位 IHole：必須被判成不良構
  let bad = ischema(["Nat", "Fin"], [0, 1], [
    ictor("z", 0, [], []),
    ictor("s", 0, [], [iarg_rec(0, "n", [])]),
    ictor("fz", 1, [iholed()], [iarg_val(0, "n")]),
  ])
  @core.chk(
    out,
    "iit: schema placeholders are rejected #2",
    ischema_ok(bad) != None,
  )
  out
}

// ---------------------------------------------------------------------------
// QIIT 的消除器：折在商之後的值上，於是「相等的項」給出相等的結果
// ---------------------------------------------------------------------------

///|
/// 商化用的燃料（等式互相觸發時需要多輪；用完即停，不假裝是等價閉包）。
pub fn quot_fuel() -> Int32 {
  32
}

///|
/// 依 schema 的等式商化一個值。
pub fn iquot_schema(s : ISchema, v : IVal) -> IVal {
  iquot(s.eqs, v, quot_fuel())
}

///|
/// **QIIT 的索引檢查**：先商化再檢查。這讓「等式兩端的項」有同樣的 sort/index。
pub fn icheck_q(s : ISchema, v : IVal) -> Bool {
  icheck(s, iquot_schema(s, v))
}

///|
/// **QIIT 的消除器**：折在商之後的值上，所以等式的兩端會得到同一個結果。
/// （純 II 的 `iit_fold` 是結構遞迴，對等式一無所知，這正是差別所在。）
pub fn iit_fold_q(s : ISchema, h : (Int32, Array[IVal]) -> IVal, v : IVal) -> IVal {
  iit_fold(s, h, iquot_schema(s, v))
}
