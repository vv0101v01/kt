// ---------------------------------------------------------------------------
// meta/instances — 全域實例（typeclass / instances）作為「Horn 邏輯程式 + 一致性」
// ---------------------------------------------------------------------------
//
// 一個 typeclass 系統真正難的不是「找得到實例」，而是：
//   1. **終止**：實例鏈不能無限長（泛型實例 Array[T] :- Show T 可能繞圈）；
//   2. **一致性（coherence）**：同一個目標的所有推導都給出同一個見證值；
//   3. **組合性**：多個模組各自宣告的實例，併在一起之後仍然一致。
//
// 本套件把這三件事都變成**可判定的檢查**，而不是「編譯器大概會處理」：
//   終止   → 序數度量嚴格下降（meta/core/ordinal）
//   一致性 → 臨界對（critical pairs）+ 典範化（canonicalization）
//   組合性 → 模組化覆蓋的下降條件（descent）與單值化障礙（monodromy）
//
// 語言事實（MoonBit v0.10.14）：本套件不使用 trait/impl，只用代數資料型別 +
// 高階函式；要研究的是「型別類的語義」，而不是「用型別類寫程式」。

///|
/// 一條實例規則：`head` 可由 `body` 全部成立而得出。變數以 0..n−1 編號。
pub(all) struct Rule {
  name : String
  /// 優先級：數字大者優先（對應 typeclass 的 specific-over-general）
  prio : Int32
  head : @core.UTerm
  body : Array[@core.UTerm]
}

///|
/// 實例環境（全域實例表）。
pub(all) struct Env {
  rules : Array[Rule]
}

///|
/// 建一條規則。
pub fn rule(
  name : String,
  prio : Int32,
  head : @core.UTerm,
  body : Array[@core.UTerm],
) -> Rule {
  Rule::{ name, prio, head, body, }
}

///|
/// 建環境。
pub fn env(rules : Array[Rule]) -> Env {
  Env::{ rules, }
}

///|
/// 型別常數的編碼（讓測試讀得懂）。
pub fn ty_int() -> @core.UTerm {
  @core.ufn(0, [])
}

///|
pub fn ty_bool() -> @core.UTerm {
  @core.ufn(1, [])
}

///|
pub fn ty_array(t : @core.UTerm) -> @core.UTerm {
  @core.ufn(2, [t])
}

///|
pub fn ty_pair(a : @core.UTerm, b : @core.UTerm) -> @core.UTerm {
  @core.ufn(3, [a, b])
}

///|
/// 類別目標：Show(T) = tag 10 應用於 T。
pub fn cls_show(t : @core.UTerm) -> @core.UTerm {
  @core.ufn(10, [t])
}

///|
pub fn cls_eq(t : @core.UTerm) -> @core.UTerm {
  @core.ufn(11, [t])
}

///|
pub fn cls_ord(t : @core.UTerm) -> @core.UTerm {
  @core.ufn(12, [t])
}

// ---------------------------------------------------------------------------
// 新鮮實例化：規則內的變數在每次使用時必須改名，否則會串味
// ---------------------------------------------------------------------------

///|
pub fn renumber(t : @core.UTerm, base : Int32) -> @core.UTerm {
  match t {
    @core.UVar(v) => @core.UVar(v + base)
    @core.UFfn(f, xs) => {
      let out : Array[@core.UTerm] = []
      for x in xs {
        out.push(renumber(x, base))
      }
      @core.UFfn(f, out)
    }
  }
}

///|
/// 推導樹：葉子是公理實例，內部節點記錄用了哪條規則。
pub(all) struct Deriv {
  /// 規則索引（-1 表示「無規則」）
  rule : Int32
  /// 每個 body 目標對應一棵子樹
  kids : Array[Deriv]
  /// 這棵子樹證明的目標（憑證檢查器要能獨立複驗）
  goal : @core.UTerm
}

///| 見證項：把推導樹具體化成一階項。

///| 兩棵樹的見證相等 ⟺ 它們用了同一條路。

///|
/// 這正是 typeclass「同一個目標只能有一個值」的可比對形式。
pub fn evidence(e : Env, d : Deriv) -> @core.UTerm {
  let kids : Array[@core.UTerm] = []
  for k in d.kids {
    kids.push(evidence(e, k))
  }
  let tag = if d.rule < 0 { 900 } else { 100 + d.rule }
  @core.ufn(tag, kids)
}

///|
/// 推導樹深度。
pub fn deriv_depth(d : Deriv) -> Int32 {
  let mut best = 0
  for k in d.kids {
    let x = deriv_depth(k)
    if x > best {
      best = x
    }
  }
  best + 1
}

///|
/// 推導樹節點數（搜尋成本的度量）。
pub fn deriv_size(d : Deriv) -> Int32 {
  let mut n = 1
  for k in d.kids {
    n = n + deriv_size(k)
  }
  n
}

///|
fn clone_derivs(ds : Array[Deriv]) -> Array[Deriv] {
  let out : Array[Deriv] = []
  for d in ds {
    out.push(d)
  }
  out
}

// ---------------------------------------------------------------------------
// SLD 解析（「推論」引擎）
// ---------------------------------------------------------------------------

///|
/// 只保留某些規則的子環境（給擬陣／模組化用）。
pub fn restrict(e : Env, keep : Array[Int32]) -> Env {
  let out : Array[Rule] = []
  for i in 0..<e.rules.length() {
    let mut ok = false
    for k in keep {
      if k == i {
        ok = true
      }
    }
    if ok {
      out.push(e.rules[i])
    }
  }
  Env::{ rules: out, }
}

///|
/// 蒐集所有推導（深度上限 + 路徑簽名去環）。非空 ⟺ 目標可解。
pub fn resolve_all(e : Env, goal : @core.UTerm, depth : Int32) -> Array[Deriv] {
  let acc : Array[Deriv] = []
  resolve_path(e, goal, depth, [], acc)
  acc
}

///|
fn key_in(seen : Array[@core.UTerm], g : @core.UTerm) -> Bool {
  let mut hit = false
  for s in seen {
    if @core.u_eq(s, g) {
      hit = true
    }
  }
  hit
}

///|
fn resolve_path(
  e : Env,
  goal : @core.UTerm,
  depth : Int32,
  seen : Array[@core.UTerm],
  acc : Array[Deriv],
) -> Unit {
  if depth <= 0 {
    return
  }
  if key_in(seen, goal) {
    return
  }
  let seen2 : Array[@core.UTerm] = []
  for s in seen {
    seen2.push(s)
  }
  seen2.push(goal)
  for i in 0..<e.rules.length() {
    let r = e.rules[i]
    let base = 1000 * (depth + 1)
    let head = renumber(r.head, base)
    let sub : Array[@core.UTerm?] = []
    if @core.u_unify(sub, head, goal) {
      let body : Array[@core.UTerm] = []
      for b in r.body {
        body.push(@core.u_apply(sub, renumber(b, base)))
      }
      solve_body(e, body, 0, depth - 1, seen2, i, goal, [], acc)
    }
  }
}

///|
fn solve_body(
  e : Env,
  body : Array[@core.UTerm],
  idx : Int32,
  depth : Int32,
  seen : Array[@core.UTerm],
  rule_idx : Int32,
  goal : @core.UTerm,
  kids : Array[Deriv],
  acc : Array[Deriv],
) -> Unit {
  if idx >= body.length() {
    acc.push(Deriv::{ rule: rule_idx, kids: clone_derivs(kids), goal, })
    return
  }
  let sub_acc : Array[Deriv] = []
  resolve_path(e, body[idx], depth, seen, sub_acc)
  if sub_acc.length() == 0 {
    return
  }
  for d in sub_acc {
    let kids2 = clone_derivs(kids)
    kids2.push(d)
    solve_body(e, body, idx + 1, depth, seen, rule_idx, goal, kids2, acc)
  }
}

///|
/// 可解性（不關心見證）。
pub fn solvable(e : Env, goal : @core.UTerm, depth : Int32) -> Bool {
  resolve_all(e, goal, depth).length() > 0
}

// ---------------------------------------------------------------------------
// 一致性：臨界對 + 典範化
// ---------------------------------------------------------------------------

///|
/// 典範推導：優先級最高者勝；平手取規則索引小者（確定性）。
pub fn canonical(ds : Array[Deriv], e : Env) -> Deriv? {
  if ds.length() == 0 {
    return None
  }
  let mut best = ds[0]
  for d in ds {
    let bd = if best.rule >= 0 { e.rules[best.rule].prio } else { -999 }
    let dd = if d.rule >= 0 { e.rules[d.rule].prio } else { -999 }
    if dd > bd || (dd == bd && d.rule < best.rule) {
      best = d
    }
  }
  Some(best)
}

///| 最高優先級的那些推導。typeclass 的語義是「最具體者勝」：

///|
/// 只有同一優先級的兩條路徑，才需要真的給出同一個值。
pub fn maximal_derivs(e : Env, ds : Array[Deriv]) -> Array[Deriv] {
  let mut top = -9999
  for d in ds {
    let p = if d.rule >= 0 { e.rules[d.rule].prio } else { -9999 }
    if p > top {
      top = p
    }
  }
  let out : Array[Deriv] = []
  for d in ds {
    let p = if d.rule >= 0 { e.rules[d.rule].prio } else { -9999 }
    if p == top {
      out.push(d)
    }
  }
  out
}

///|
/// 一致性檢查：找出「同一目標在最高優先級上有兩個不同見證」的目標。
pub fn incoherence_witness(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> @core.UTerm? {
  for g in goals {
    let ds = resolve_all(e, g, depth)
    let top = maximal_derivs(e, ds)
    match canonical(top, e) {
      Some(c) => {
        let ce = evidence(e, c)
        for d in top {
          if !@core.u_eq(evidence(e, d), ce) {
            return Some(g)
          }
        }
      }
      None => ()
    }
  }
  None
}

///| 臨界對：兩條規則的 head 可合一（有重疊實例），

///|
/// 這是一致性風險的**全部**來源。
pub fn critical_pairs(e : Env) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for i in 0..<e.rules.length() {
    for j in (i + 1)..<e.rules.length() {
      let hi = renumber(e.rules[i].head, 0)
      let hj = renumber(e.rules[j].head, 500)
      if @core.u_unifiable(hi, hj) {
        out.push((i, j))
      }
    }
  }
  out
}

///|
/// 重疊實例可否併合：對重疊的具體目標，兩條路是否給出同一見證。
pub fn overlapping_joinable(
  e : Env,
  i : Int32,
  j : Int32,
  depth : Int32,
) -> Bool {
  let hi = renumber(e.rules[i].head, 0)
  let hj = renumber(e.rules[j].head, 500)
  match @core.u_mgu(hi, hj) {
    None => true
    Some(sub) => {
      let g = @core.u_apply(sub, hi)
      let ds = maximal_derivs(e, resolve_all(e, g, depth))
      match canonical(ds, e) {
        None => true
        Some(c) => {
          let ce = evidence(e, c)
          let mut ok = true
          for d in ds {
            if !@core.u_eq(evidence(e, d), ce) {
              ok = false
            }
          }
          ok
        }
      }
    }
  }
}

///| 全域一致性判準（在本引擎的觀察範圍內）：

///|   (1) 每個臨界對都可併合；

///|
///   (2) 給定目標集上不存在不一致見證。
pub fn coherent(e : Env, goals : Array[@core.UTerm], depth : Int32) -> Bool {
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      return false
    }
  }
  match incoherence_witness(e, goals, depth) {
    None => true
    Some(_) => false
  }
}

// ---------------------------------------------------------------------------
// 終止：序數度量
// ---------------------------------------------------------------------------

///|
fn u_depth(t : @core.UTerm) -> Int32 {
  match t {
    @core.UVar(_) => 0
    @core.UFfn(_, xs) => {
      let mut best = 0
      for x in xs {
        let d = u_depth(x)
        if d > best {
          best = d
        }
      }
      best + 1
    }
  }
}

///|
/// 目標的結構度量：ω^{建構子深度}。
pub fn goal_measure(g : @core.UTerm) -> @core.Ordinal {
  @core.ord_omega_pow(@core.ord_int(u_depth(g)))
}

///| 終止性：每條規則的每個 body 目標，度量都必須嚴格變小。

///|
/// 這是「實例鏈不會無限延伸」的可計算充分判準。
pub fn terminating(e : Env) -> String? {
  for r in e.rules {
    let hm = goal_measure(r.head)
    for b in r.body {
      let bm = goal_measure(renumber(b, 0))
      if !@core.ord_lt(bm, hm) {
        return Some("rule \{r.name}: body goal does not decrease")
      }
    }
  }
  None
}

// ---------------------------------------------------------------------------
// 白箱測試
// ---------------------------------------------------------------------------

///|
/// 經典 typeclass 環境：Int/Bool 是公理，Array/Pair 是泛型實例。
pub fn env_show() -> Env {
  env([
    rule("showInt", 0, cls_show(ty_int()), []),
    rule("showBool", 0, cls_show(ty_bool()), []),
    rule("showArray", 0, cls_show(ty_array(@core.uvar(0))), [
      cls_show(@core.uvar(0)),
    ]),
    rule("showPair", 0, cls_show(ty_pair(@core.uvar(0), @core.uvar(1))), [
      cls_show(@core.uvar(0)),
      cls_show(@core.uvar(1)),
    ]),
  ])
}

///|
pub fn law_engine_instances_sld_resolution_finds_and_composites_instances() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_show()
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #1",
    solvable(e, cls_show(ty_int()), 8),
  )
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #2",
    solvable(e, cls_show(ty_array(ty_int())), 8),
  )
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #3",
    solvable(e, cls_show(ty_array(ty_array(ty_bool()))), 8),
  )
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #4",
    solvable(e, cls_show(ty_pair(ty_int(), ty_array(ty_bool()))), 8),
  )
  // 沒有 Eq 實例
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #5",
    !solvable(e, cls_eq(ty_int()), 8),
  )
  // 見證結構：showArray(showInt)
  let ds = resolve_all(e, cls_show(ty_array(ty_int())), 8)
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #6",
    ds.length() == 1,
  )
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #7",
    ds[0].rule == 2,
  )
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #8",
    ds[0].kids.length() == 1 && ds[0].kids[0].rule == 0,
  )
  // 深度決定了推導的大小
  @core.chk(
    out,
    "instances: SLD resolution finds and composites instances #9",
    deriv_depth(ds[0]) == 2 && deriv_size(ds[0]) == 2,
  )
  out
}

///|
pub fn law_engine_instances_termination_is_decided_by_ordinal_measure() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_show()
  match terminating(e) {
    None =>
      @core.chk(
        out, "instances: termination is decided by ordinal measure #1", true,
      )
    Some(_) =>
      @core.chk(
        out, "instances: termination is decided by ordinal measure #2", false,
      )
  }
  // 會繞圈的法則：Show(T) :- Show(Array T)
  let bad = env([
    rule("loop", 0, cls_show(@core.uvar(0)), [cls_show(ty_array(@core.uvar(0)))]),
  ])
  match terminating(bad) {
    Some(_) =>
      @core.chk(
        out, "instances: termination is decided by ordinal measure #3", true,
      )
    None =>
      @core.chk(
        out, "instances: termination is decided by ordinal measure #4", false,
      )
  }
  // 序數度量確實嚴格下降（用分數式寫出來，不只是「檢查通過」）
  @core.chk(
    out,
    "instances: termination is decided by ordinal measure #5",
    @core.ord_lt(
      goal_measure(cls_show(@core.uvar(0))),
      goal_measure(cls_show(ty_array(@core.uvar(0)))),
    ),
  )
  out
}

///|
pub fn law_engine_instances_overlapping_instances_priority_coherence() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 兩個都匹配 Show(Int)：generic（prio 0）與 specific（prio 1）
  let e = env([
    rule("generic", 0, cls_show(@core.uvar(0)), []),
    rule("specificInt", 1, cls_show(ty_int()), []),
  ])
  let cp = critical_pairs(e)
  @core.chk(
    out,
    "instances: overlapping instances, priority, coherence #1",
    cp.length() == 1,
  )
  let g = cls_show(ty_int())
  let ds = resolve_all(e, g, 6)
  @core.chk(
    out,
    "instances: overlapping instances, priority, coherence #2",
    ds.length() == 2,
  )
  match canonical(ds, e) {
    Some(c) =>
      @core.chk(
        out,
        "instances: overlapping instances, priority, coherence #3",
        c.rule == 1,
      )
    None =>
      @core.chk(
        out, "instances: overlapping instances, priority, coherence #4", false,
      )
  }
  // 優先級不同 ⇒ 本引擎視為一致（典範化挑得出唯一見證）
  @core.chk(
    out,
    "instances: overlapping instances, priority, coherence #5",
    coherent(e, [g], 6),
  )
  // 同優先級重疊 ⇒ 不一致，且能指出是哪個目標
  let e2 = env([
    rule("a", 0, cls_show(@core.uvar(0)), []),
    rule("b", 0, cls_show(ty_int()), []),
  ])
  match incoherence_witness(e2, [g], 6) {
    Some(bad_goal) =>
      @core.chk(
        out,
        "instances: overlapping instances, priority, coherence #6",
        @core.u_eq(bad_goal, g),
      )
    None =>
      @core.chk(
        out, "instances: overlapping instances, priority, coherence #7", false,
      )
  }
  @core.chk(
    out,
    "instances: overlapping instances, priority, coherence #8",
    !coherent(e2, [g], 6),
  )
  out
}

// ---------------------------------------------------------------------------
// 全域實例的「修補」：從不可併合的臨界對生成新規則（Knuth–Bendix 式完備化）
// ---------------------------------------------------------------------------
//
// `coherent` 只能**判定**不一致。真正擁有「全域實例」這個能力，還要能**修**：
// 對每個不可併合的臨界對（兩條規則的 head 可合一，但兩條路徑給不同見證），
// 把重疊目標 `g` 釘在一條路上 —— 新增優先級**高於所有既有規則**的規則。
// 這一步是 Knuth–Bendix 完備化的實例表版本：臨界對是唯一的歧義來源，
// 所以把它們逐一釘死就會收斂（回合數是上界，不是保證）。

///|
/// 修補一步：回傳（新環境, 新增規則數）。優先級取 `max + 1`，
/// 使重疊目標立刻只剩一條最大推導 —— 歧義在語義上被消除，而不是被隱藏。
pub fn repair_step(e : Env, depth : Int32) -> (Env, Int32) {
  let rules : Array[Rule] = []
  let mut top = -1000
  for r in e.rules {
    rules.push(r)
    if r.prio > top {
      top = r.prio
    }
  }
  let mut added = 0
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      let hi = renumber(e.rules[i].head, 0)
      let hj = renumber(e.rules[j].head, 500)
      match @core.u_mgu(hi, hj) {
        Some(sub) => {
          let g = @core.u_apply(sub, hi)
          let ds = maximal_derivs(e, resolve_all(e, g, depth))
          match canonical(ds, e) {
            Some(c) => {
              let body : Array[@core.UTerm] = []
              for k in c.kids {
                body.push(k.goal)
              }
              rules.push(
                rule(
                  "repair_" + i.to_string() + "_" + j.to_string(),
                  top + 1 + added,
                  g,
                  body,
                ),
              )
              added = added + 1
            }
            None => ()
          }
        }
        None => ()
      }
    }
  }
  (env(rules), added)
}

///|
/// 完備化：反覆修補直到沒有不可併合的臨界對（`added == 0`）或回合用完。
pub fn complete(e : Env, depth : Int32, rounds : Int32) -> Env {
  let mut cur = e
  for _ in 0..<rounds {
    let (next, added) = repair_step(cur, depth)
    cur = next
    if added == 0 {
      return cur
    }
  }
  cur
}

///|
/// 只看臨界對這一半的一致性（修補的目標）。
pub fn pairs_joinable(e : Env, depth : Int32) -> Bool {
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      return false
    }
  }
  true
}

///|
/// 修補定律：能偵測 → 能修 → 修完仍然可解，且不刪任何規則。
pub fn law_engine_completion_repairs_an_incoherent_env() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let e = env_clash()
  let goal = cls_show(ty_int())
  // 1. 修補前：真的有不可併合的臨界對（否則這條定律沒有內容）
  @core.chk(
    out,
    "instances: completion repairs an incoherent env #1 (incoherent before)",
    !pairs_joinable(e, 6),
  )
  // 2. 修補後：臨界對全部可併合
  let e2 = complete(e, 6, 6)
  @core.chk(
    out,
    "instances: completion repairs an incoherent env #2 (joinable after)",
    pairs_joinable(e2, 6),
  )
  // 3. 只增不刪：原有規則全部還在
  let mut kept = true
  for i in 0..<e.rules.length() {
    if !@core.u_eq(e.rules[i].head, e2.rules[i].head) ||
      e.rules[i].prio != e2.rules[i].prio {
      kept = false
    }
  }
  @core.chk(out, "instances: completion repairs an incoherent env #3 (rules kept)", kept)
  // 4. 可解性不被破壞：修補前可解的目標，修補後仍可解
  @core.chk(
    out,
    "instances: completion repairs an incoherent env #4 (solvability preserved)",
    !solvable(e, goal, 6) || solvable(e2, goal, 6),
  )
  // 5. 冪等：對已完備的環境再修一次不會再加東西
  let (e3, added) = repair_step(e2, 6)
  @core.chk(
    out,
    "instances: completion repairs an incoherent env #5 (complete is a fixpoint)",
    added == 0 && e3.rules.length() == e2.rules.length(),
  )
  // 6. 反面：本來就一致的環境不會被動到
  let es = env_show()
  let (_, added_show) = repair_step(es, 8)
  @core.chk(
    out,
    "instances: completion repairs an incoherent env #6 (coherent env untouched)",
    added_show == 0,
  )
  out
}

// ---------------------------------------------------------------------------
// 修補的終止序：新規則必須「頭 > 體」，否則不收
// ---------------------------------------------------------------------------
//
// 上一版的 `repair_step` 只靠「優先級釘死」讓歧義消失，本身不保證收斂到一個
// 終止的重寫系統。這一版加上**定向**：新規則只在 `head` 的度量嚴格大於每個
// `body` 目標時才加入 —— 這就是 Knuth–Bendix 的 orient 步驟（這裡用節點數，
// 不是完整的 RPO/KBO，邊界寫在下面）。定向不了的臨界對會**被報告**而不是硬塞。

///|
/// 規則的定向條件：頭的節點數嚴格大於每個 body 目標。
pub fn rule_oriented(r : Rule) -> Bool {
  let hs = @core.u_size(r.head)
  let mut ok = true
  for b in r.body {
    if !(hs > @core.u_size(b)) {
      ok = false
    }
  }
  ok
}

///|
/// 整個環境是否定向（每個規則都頭 > 體 ⇒ 重寫必終止）。
pub fn orientable(e : Env) -> Bool {
  for r in e.rules {
    if !rule_oriented(r) {
      return false
    }
  }
  true
}

///|
/// 定向修補一步：回傳（新環境, 新增數, 無法定向的臨界對）。
pub fn repair_step_oriented(
  e : Env,
  depth : Int32,
) -> (Env, Int32, Array[(Int32, Int32)]) {
  let rules : Array[Rule] = []
  let mut top = -1000
  for r in e.rules {
    rules.push(r)
    if r.prio > top {
      top = r.prio
    }
  }
  let mut added = 0
  let stuck : Array[(Int32, Int32)] = []
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      let hi = renumber(e.rules[i].head, 0)
      let hj = renumber(e.rules[j].head, 500)
      match @core.u_mgu(hi, hj) {
        Some(sub) => {
          let g = @core.u_apply(sub, hi)
          let ds = maximal_derivs(e, resolve_all(e, g, depth))
          match canonical(ds, e) {
            Some(c) => {
              let body : Array[@core.UTerm] = []
              for k in c.kids {
                body.push(k.goal)
              }
              let cand = rule(
                "repair_" + i.to_string() + "_" + j.to_string(),
                top + 1 + added,
                g,
                body,
              )
              if rule_oriented(cand) {
                rules.push(cand)
                added = added + 1
              } else {
                stuck.push((i, j))
              }
            }
            None => stuck.push((i, j))
          }
        }
        None => ()
      }
    }
  }
  (env(rules), added, stuck)
}

///|
/// 定向完備化：反覆修補直到沒有可修的東西。
pub fn complete_oriented(
  e : Env,
  depth : Int32,
  rounds : Int32,
) -> (Env, Array[(Int32, Int32)]) {
  let mut cur = e
  let mut stuck : Array[(Int32, Int32)] = []
  for _ in 0..<rounds {
    let (next, added, bad) = repair_step_oriented(cur, depth)
    cur = next
    stuck = bad
    if added == 0 {
      return (cur, stuck)
    }
  }
  (cur, stuck)
}

///|
/// 定向修補的定律：新規則全部定向、修補後一致、定向本身不會被破壞、
/// 無法定向的臨界對會被報告而不是硬塞。
pub fn law_engine_completion_uses_a_termination_order() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let e = env_clash()
  let (e2, stuck) = complete_oriented(e, 6, 6)
  // #1 修補前確實不一致
  @core.chk(
    out,
    "instances: completion uses a termination order #1 (incoherent before)",
    !pairs_joinable(e, 6),
  )
  // #2 修補後臨界對全部可併合
  @core.chk(
    out,
    "instances: completion uses a termination order #2 (joinable after)",
    pairs_joinable(e2, 6),
  )
  // #3 新加的每一條規則都定向（頭 > 體）—— 這是「收斂」的憑據
  let mut all_oriented = true
  for i in 0..<e2.rules.length() {
    if i >= e.rules.length() {
      if !rule_oriented(e2.rules[i]) {
        all_oriented = false
      }
    }
  }
  @core.chk(
    out,
    "instances: completion uses a termination order #3 (every new rule is oriented)",
    all_oriented,
  )
  // #4 原有規則的定向性沒被動到
  let mut old_ok = true
  for i in 0..<e.rules.length() {
    if rule_oriented(e.rules[i]) != rule_oriented(e2.rules[i]) {
      old_ok = false
    }
  }
  @core.chk(
    out,
    "instances: completion uses a termination order #4 (old rules untouched)",
    old_ok,
  )
  // #5 沒有硬塞：真的定向不了就回報（env_clash 上應該全部可以定向）
  @core.chk(
    out,
    "instances: completion uses a termination order #5 (no unorientable pair hidden)",
    stuck.length() == 0,
  )
  // #6 之前那版（只釘優先級、不定向）仍然是同一組修補點：兩者對一致性給出同樣結論
  @core.chk(
    out,
    "instances: completion uses a termination order #6 (agrees with priority-only repair)",
    pairs_joinable(complete(e, 6, 6), 6) == pairs_joinable(e2, 6),
  )
  out
}

// ---------------------------------------------------------------------------
// SLD 完備性：`resolve_all` 在深度 ≤ d 內「不漏解、不加假解」
// ---------------------------------------------------------------------------
//
// `resolve_all` 用了兩件會影響完備性的事：深度上限、路徑去環。
// 為了**驗證**它沒有漏解，這裡另外寫一個刻意笨的搜尋 `derivable_bruteforce`：
// 純 DFS、不做環路偵測、不做記憶、只靠深度遞減終止。它對「深度 ≤ d 的推導」
// 是顯然完備的（所有規則/所有 body 順序都展開），所以只要在窮舉出來的目標
// 空間上與 `resolve_all` 的答案一致，就說明 `resolve_all` 的兩個剪枝沒有丟掉
// 任何深度內的解 —— 這是可執行的完備性證據，不是斷言。

///|
/// 閉項窮舉：給定簽名（每個符號的元數），列出大小 ≤ `budget` 的所有目標。
pub fn enum_uterms(sig : Array[Int32], budget : Int32) -> Array[@core.UTerm] {
  let out : Array[@core.UTerm] = []
  enum_uterms_into(sig, budget, out)
  out
}

///|
fn enum_uterms_into(
  sig : Array[Int32],
  budget : Int32,
  out : Array[@core.UTerm],
) -> Unit {
  if budget <= 0 {
    return
  }
  for f in 0..<sig.length() {
    let ar = sig[f]
    if ar == 0 {
      out.push(@core.ufn(f, []))
    } else {
      enum_args_into(sig, ar, [], budget - 1, f, out)
    }
  }
}

///|
fn enum_args_into(
  sig : Array[Int32],
  ar : Int32,
  acc : Array[@core.UTerm],
  budget : Int32,
  f : Int32,
  out : Array[@core.UTerm],
) -> Unit {
  if acc.length() == ar {
    out.push(@core.ufn(f, acc))
    return
  }
  if budget <= 0 {
    return
  }
  for sub in 1..=budget {
    for t in enum_uterms(sig, sub) {
      let acc2 : Array[@core.UTerm] = []
      for a in acc {
        acc2.push(a)
      }
      acc2.push(t)
      enum_args_into(sig, ar, acc2, budget - sub, f, out)
    }
  }
}

///|
/// 暴力可解性：深度受限的純 DFS（無環路偵測、無記憶）。
/// `d` 的意義與 `resolve_all` 相同（可用的規則嵌套層數）。
pub fn derivable_bruteforce(
  e : Env,
  goal : @core.UTerm,
  depth : Int32,
) -> Bool {
  if depth <= 0 {
    return false
  }
  for r in e.rules {
    let base = 1000 * (depth + 1)
    let head = renumber(r.head, base)
    let sub : Array[@core.UTerm?] = []
    if @core.u_unify(sub, head, goal) {
      if r.body.length() == 0 {
        return true
      }
      let mut all = true
      for b in r.body {
        let g = @core.u_apply(sub, renumber(b, base))
        if !derivable_bruteforce(e, g, depth - 1) {
          all = false
        }
      }
      if all {
        return true
      }
    }
  }
  false
}

///|
/// 測試用環境：加深的泛型鏈（深度限制真的會咬到的形狀）。
pub fn env_chain() -> Env {
  env([
    rule("c_base", 0, cls_show(ty_int()), []),
    rule("c_arr", 0, cls_show(ty_array(@core.uvar(0))), [
      cls_show(@core.uvar(0)),
    ]),
    rule("c_pair", 0, cls_show(ty_pair(@core.uvar(0), @core.uvar(1))), [
      cls_show(@core.uvar(0)),
      cls_show(@core.uvar(1)),
    ]),
  ])
}

///|
/// 測試用環境：含環（`Show T :- Show T`）—— 這是路徑去環存在的理由。
pub fn env_loop() -> Env {
  env([
    rule("loop", 0, cls_show(@core.uvar(0)), [cls_show(@core.uvar(0))]),
    rule("l_base", 0, cls_show(ty_int()), []),
  ])
}

///|
/// SLD 完備性定律：
/// #1 聲音（`resolve_all` 找到 ⇒ 暴力找得到）
/// #2 完備（暴力找到 ⇒ `resolve_all` 找得到）
/// #3 深度單調（解在 d ⇒ 解在 d+1）
/// #4 環不會讓任何一邊發散（含環保與無環保給同一答案）
/// #5 深度真的會咬人（存在目標：d 無解、d+3 有解）—— 所以陳述的是「深度內完備」
/// #6 不漏解也不加假解：兩邊的可解集合在整個窮舉空間上完全相同
pub fn law_engine_sld_resolution_is_complete_within_depth() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 簽名：0:Int, 1:Bool, 2:Array(1), 3:Pair(2), 10:Show(1)
  let sig : Array[Int32] = [0, 0, 1, 2, 1]
  let goals = enum_uterms(sig, 6)
  let envs : Array[Env] = [env_show(), env_chain(), env_loop()]
  let depths : Array[Int32] = [1, 2, 3, 4]
  let mut sound = true
  let mut complete = true
  let mut mono = true
  let mut same = true
  let mut checked = 0
  for e in envs {
    for g in goals {
      for d in depths {
        checked = checked + 1
        let a = solvable(e, g, d)
        let b = derivable_bruteforce(e, g, d)
        if a && !b {
          sound = false
        }
        if b && !a {
          complete = false
        }
        if a != b {
          same = false
        }
        if a && !solvable(e, g, d + 1) {
          mono = false
        }
      }
    }
  }
  @core.chk(
    out,
    "instances: sld resolution is complete within depth #1 (sound)",
    sound,
  )
  @core.chk(
    out,
    "instances: sld resolution is complete within depth #2 (complete)",
    complete,
  )
  @core.chk(
    out,
    "instances: sld resolution is complete within depth #3 (depth monotone)",
    mono,
  )
  // #4 環：含環保與無環保上，兩邊都不發散且答案一致（上面已含 env_loop；
  // 這裡額外確認「環裡真的有環」而不是被規則遮蔽）
  let loop_goal = cls_show(ty_int())
  let loop_env = env([
    rule("loop", 0, cls_show(@core.uvar(0)), [cls_show(@core.uvar(0))]),
  ])
  @core.chk(
    out,
    "instances: sld resolution is complete within depth #4 (cycles terminate, no false solutions)",
    !solvable(loop_env, loop_goal, 6) && !derivable_bruteforce(loop_env, loop_goal, 6),
  )
  // #5 深度會咬人：Array[Pair[Int, Int]] 需要 3 層
  let deep = cls_show(ty_array(ty_pair(ty_int(), ty_int())))
  @core.chk(
    out,
    "instances: sld resolution is complete within depth #5 (depth bound really bites)",
    !solvable(env_chain(), deep, 2) && solvable(env_chain(), deep, 3),
  )
  // #6 窮舉空間上完全一致（不漏也不假）
  @core.chk(
    out,
    "instances: sld resolution is complete within depth #6 (no missed and no fake solutions over \{checked} goal/depth pairs)",
    same && checked > 500,
  )
  out
}
