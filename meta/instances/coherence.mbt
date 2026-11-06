// ---------------------------------------------------------------------------
// meta/instances — 一致性的完備化：不再靠使用者給的 battery
// ---------------------------------------------------------------------------
//
// 上一版的一致性判準有兩個誠實的缺口：
//
//   (1) **battery 依賴**：`coherent(e, goals, d)` 的第二個條件只在「使用者給的那幾個目標」
//       上檢查。給一串沒踩到雷的目標，它就說「一致」。
//   (2) **看不見區域實例**：`critical_pairs(e)` 只掃 `e.rules`。可是真實系統裡還有
//       **區域實例**（模組內實例、假設、`where` 子句帶進來的字典）—— 它們不在規則表裡，
//       卻會在同一個目標上給出第二個見證。
//
// 這一檔把兩件事都補上：
//
//   * `reachable_closed_goals`：從規則的 head / body 出發，做**可達目標宇宙**的閉包
//     （BFS + mgu 實例化 + 具體化），得到一份**由程式自己算出來的** battery；
//   * `coherent_complete`：在這個算出來的宇宙上檢查「極大推導的見證唯一」＋臨界對可併合；
//   * `coherent_with_local`：把區域實例一起放進來檢查（舊 API 結構上看不見它們）；
//   * `stable_under`：**擴充穩定性**（COCHIS 的 stability property）——
//     加新實例後，已可解目標的典範見證是否改變；
//   * `newman`：終止 ∧ 局部合流 ⇒ 全域合流（Newman 引理）在本片段的實測版。
//
// 並且對帳一個**正面**結果：在純 Horn 規則的片段裡，局部尖峰與 head 重疊是同一組東西
// （`peak_overlap_agreement` 逐一驗）。也就是說：舊判準對「閉目標 + 純規則」其實是完備的，
// 缺的是區域實例與 battery —— 這兩點在這裡補完，而不是含糊宣稱「更完備了」。

// ---------------------------------------------------------------------------
// 0. 目標宇宙的基本工具
// ---------------------------------------------------------------------------

///|
/// 具體化：把剩下的變數換成常數（tag 98），得到一個**閉目標**。
pub fn ground(t : @core.UTerm) -> @core.UTerm {
  match t {
    @core.UVar(k) => @core.ufn(98, [@core.ufn(k, [])])
    @core.UFfn(f, xs) => {
      let ys : Array[@core.UTerm] = []
      for x in xs {
        ys.push(ground(x))
      }
      @core.ufn(f, ys)
    }
  }
}

///|
/// 目標宇宙的種子：每條規則的 head 與 body 目標（各自重新編號，避免變數串味）。
pub fn open_seeds(e : Env) -> Array[@core.UTerm] {
  let out : Array[@core.UTerm] = []
  let mut base = 1000
  for r in e.rules {
    let h = renumber(r.head, base)
    push_new(out, h)
    for b in r.body {
      push_new(out, renumber(b, base))
    }
    base = base + 1000
  }
  out
}

///|
fn push_new(dst : Array[@core.UTerm], t : @core.UTerm) -> Unit {
  for x in dst {
    if @core.u_eq(x, t) {
      return
    }
  }
  dst.push(t)
}

///|
/// 具體化池：三個具體型別 + 一個二階型別，足以讓泛型目標變成閉目標。
fn pool_ty(i : Int32) -> @core.UTerm {
  if i == 0 {
    ty_int()
  } else if i == 1 {
    ty_bool()
  } else if i == 2 {
    ty_array(ty_int())
  } else {
    ty_pair(ty_int(), ty_bool())
  }
}

///|
fn pool_size() -> Int32 {
  4
}

///|
/// 收集變數編號（去重，按出現順序）。
fn var_slots(t : @core.UTerm, acc : Array[Int32]) -> Unit {
  match t {
    @core.UVar(k) => if acc.contains(k) { () } else { acc.push(k) }
    @core.UFfn(_, xs) =>
      for x in xs {
        var_slots(x, acc)
      }
  }
}

///|
/// 按 slot 順序代入（slot i 用 subs[i]）。
fn subst_slots(
  t : @core.UTerm,
  slots : Array[Int32],
  subs : Array[@core.UTerm],
) -> @core.UTerm {
  match t {
    @core.UVar(k) => {
      let mut r = t
      for i in 0..<slots.length() {
        if slots[i] == k {
          r = subs[i]
        }
      }
      r
    }
    @core.UFfn(f, xs) => {
      let ys : Array[@core.UTerm] = []
      for x in xs {
        ys.push(subst_slots(x, slots, subs))
      }
      @core.ufn(f, ys)
    }
  }
}

///|
/// 把一個泛型模式**具體化**成一批閉目標（最多 4^k 個，k 為變數個數；k > 2 時只取前三種組合）。
pub fn instantiate_pattern(t : @core.UTerm) -> Array[@core.UTerm] {
  let slots : Array[Int32] = []
  var_slots(t, slots)
  let out : Array[@core.UTerm] = []
  if slots.length() == 0 {
    out.push(t)
    return out
  }
  if slots.length() > 2 {
    // 變數太多：只做「全 Int」與「全 Bool」兩種，避免爆炸
    for c in 0..<2 {
      let subs : Array[@core.UTerm] = []
      for _i in 0..<slots.length() {
        subs.push(pool_ty(c))
      }
      push_new(out, subst_slots(t, slots, subs))
    }
    return out
  }
  // 一般情形：笛卡兒積
  let mut idx = 0
  let total = if slots.length() == 1 {
    pool_size()
  } else {
    pool_size() * pool_size()
  }
  while idx < total {
    let subs : Array[@core.UTerm] = []
    if slots.length() == 1 {
      subs.push(pool_ty(idx))
    } else {
      subs.push(pool_ty(idx / pool_size()))
      subs.push(pool_ty(idx % pool_size()))
    }
    push_new(out, subst_slots(t, slots, subs))
    idx = idx + 1
  }
  out
}

///|
/// 可達目標宇宙：BFS 閉包。每一步對目前層的每個目標，嘗試所有規則的 head：
/// 可合一就加入 (i) mgu 實例化後的目標、(ii) 該規則 body 目標的實例化。
/// 只保留**閉目標的具體化版本**（`ground`），所以結果可以直接餵給 `resolve_all`。
pub fn reachable_closed_goals(e : Env, depth : Int32) -> Array[@core.UTerm] {
  let mut frontier = open_seeds(e)
  // 先收集**模式**（含變數），最後才具體化 —— 太早 ground 會讓變數消失，宇宙就貧乏了。
  let pat : Array[@core.UTerm] = []
  for g in frontier {
    push_new(pat, g)
  }
  for _layer in 0..<depth {
    let next : Array[@core.UTerm] = []
    for g in frontier {
      for r in e.rules {
        let h = renumber(r.head, 7000)
        match @core.u_mgu(g, h) {
          None => ()
          Some(sub) => {
            push_new(next, @core.u_apply(sub, g))
            for b in r.body {
              push_new(next, @core.u_apply(sub, renumber(b, 7000)))
            }
          }
        }
      }
      if next.length() > 120 {
        break
      }
    }
    if next.length() == 0 {
      break
    }
    for g in next {
      push_new(pat, g)
    }
    frontier = next
  }
  let out : Array[@core.UTerm] = []
  for p in pat {
    for g in instantiate_pattern(p) {
      push_new(out, ground(g))
    }
    if out.length() > 400 {
      break
    }
  }
  out
}

// ---------------------------------------------------------------------------
// 0b. 典範解析：每個節點只留最高優先級的子推導
// ---------------------------------------------------------------------------
//
// `resolve_all` 會回傳**所有**推導樹，包括「父規則相同、但子推導用了較低優先級實例」
// 的那些。它們不是真的不一致 —— 一個正常的解析器在每個節點都會先典範化。
// 所以一致性必須在**典範樹**上比對，否則會把「子目標的優先級」誤報成衝突。
// 這個修正是完備化的另一半：少了它，`Show(Array Int)` 會被誤判為歧義。

///|
/// 把一棵樹的每個子節點換成**它的典範推導**，展開成所有可能的組合。
/// 關鍵：典範化必須在「同一個子目標的候選推導」之間做，
/// 而不是在一棵樹自己的 kids 清單裡做 —— 後者在一棵樹只有一個 kid 時什麼都沒做。
fn canon_rewrite(e : Env, d : Deriv, depth : Int32) -> Array[Deriv] {
  if d.kids.length() == 0 || depth <= 0 {
    return [d]
  }
  // 每個子節點的典範候選
  let per_kid : Array[Array[Deriv]] = []
  for k in d.kids {
    let opts = resolve_canonical(e, k.goal, depth - 1)
    if opts.length() == 0 {
      // 子目标在原樹上可解，但典範化後不可解：保留原 kid（保守）
      per_kid.push([k])
    } else {
      per_kid.push(opts)
    }
  }
  // 笛卡兒積（上限 8 個組合，避免爆炸）
  let mut combos : Array[Array[Deriv]] = [[]]
  for opts in per_kid {
    let next : Array[Array[Deriv]] = []
    for c in combos {
      for o in opts {
        if next.length() >= 8 {
          break
        }
        let nc : Array[Deriv] = []
        for x in c {
          nc.push(x)
        }
        nc.push(o)
        next.push(nc)
      }
    }
    combos = next
  }
  let out : Array[Deriv] = []
  for c in combos {
    out.push(Deriv::{ rule: d.rule, kids: c, goal: d.goal, })
  }
  out
}

///|
/// 典範解析：先解出所有推導，再把每個子節點換成它的典範推導，
/// 最後在**同一目標**的候選之間只保留最高優先級者。
pub fn resolve_canonical(
  e : Env,
  goal : @core.UTerm,
  depth : Int32,
) -> Array[Deriv] {
  // 1) 展開：每個子節點用典範推導
  let expanded : Array[Deriv] = []
  for d in resolve_all(e, goal, depth) {
    for v in canon_rewrite(e, d, depth) {
      expanded.push(v)
    }
  }
  // 2) 去重（見證相同者視為同一棵）
  let uniq : Array[Deriv] = []
  let seen : Array[String] = []
  for d in expanded {
    let key = @core.u_to_string(evidence(e, d))
    if !seen.contains(key) {
      seen.push(key)
      uniq.push(d)
    }
  }
  // 3) 只留最高優先級
  maximal_derivs(e, uniq)
}

// ---------------------------------------------------------------------------
// 1. 無 battery 的一致性
// ---------------------------------------------------------------------------

///|
/// 在**可達目標宇宙**上有兩個（以上）極大推導卻給出不同見證的目標。
pub fn ambiguous_goals(e : Env, depth : Int32) -> Array[@core.UTerm] {
  let out : Array[@core.UTerm] = []
  for g in reachable_closed_goals(e, depth) {
    let top = resolve_canonical(e, g, depth)
    if top.length() > 1 {
      match canonical(top, e) {
        None => ()
        Some(c) => {
          let ce = evidence(e, c)
          for d in top {
            if !@core.u_eq(evidence(e, d), ce) {
              push_new(out, g)
              break
            }
          }
        }
      }
    }
  }
  out
}

///|
/// 完備版一致性：**不需要使用者提供 battery**。
///   (1) 每個臨界對都可併合（法層面）；
///   (2) 可達目標宇宙上沒有歧義目標（用法層面）。
pub fn coherent_complete(e : Env, depth : Int32) -> Bool {
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      return false
    }
  }
  ambiguous_goals(e, depth).length() == 0
}

///|
/// 完備版的「哪裡不一致」回報。
pub fn incoherence_report(e : Env, depth : Int32) -> @core.UTerm? {
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      let hi = renumber(e.rules[i].head, 0)
      let hj = renumber(e.rules[j].head, 500)
      match @core.u_mgu(hi, hj) {
        Some(sub) => return Some(ground(@core.u_apply(sub, hi)))
        None => ()
      }
    }
  }
  let bad = ambiguous_goals(e, depth)
  if bad.length() > 0 {
    return Some(bad[0])
  }
  None
}

// ---------------------------------------------------------------------------
// 2. 對帳：局部尖峰 ⟺ head 重疊
// ---------------------------------------------------------------------------
//
// 純 Horn 片段裡，兩條推導在「同一個子目標」上分岔，若且唯若兩條被用規則的 head
// 可互相合一。所以 head 重疊就是局部尖峰的全集 —— 這是**正面**結論，
// 也是為什麼舊判準的「臨界對」部分本來就夠，缺的只是宇宙與區域實例。

///|
/// 對指定目標集合，找出「重疊地套用」的規則對（兩條 head 都能套到同一個目標上）。
pub fn overlaps_among(
  e : Env,
  goals : Array[@core.UTerm],
) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for i in 0..<e.rules.length() {
    for j in (i + 1)..<e.rules.length() {
      let hi = renumber(e.rules[i].head, 0)
      let hj = renumber(e.rules[j].head, 500)
      if !@core.u_unifiable(hi, hj) {
        continue
      }
      // 確認這個重疊真的在某個可達目標上發生（而不是只在抽象層面）
      let mut witness = false
      for g in goals {
        if @core.u_unifiable(hi, g) && @core.u_unifiable(hj, g) {
          witness = true
          break
        }
      }
      if witness {
        out.push((i, j))
      }
    }
  }
  out
}

///|
/// 對帳：`overlaps_among(可達宇宙)` 與 `critical_pairs` 是同一組。
pub fn peak_overlap_agreement(e : Env, depth : Int32) -> Bool {
  let cp = critical_pairs(e)
  let ov = overlaps_among(e, reachable_closed_goals(e, depth))
  if cp.length() != ov.length() {
    return false
  }
  // 兩邊都是按 (i,j) 遞增產生，逐位比對即可
  for k in 0..<cp.length() {
    if cp[k].0 != ov[k].0 || cp[k].1 != ov[k].1 {
      return false
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 3. 區域實例：舊 API 結構上看不見的那一半
// ---------------------------------------------------------------------------

///|
/// 一條區域實例（模組內實例／假設帶進來的字典）：目標成立，且有名可查。
pub fn local_instance(name : String, prio : Int32, goal : @core.UTerm) -> Rule {
  rule(name, prio, goal, [])
}

///|
fn with_locals(e : Env, locals : Array[Rule]) -> Env {
  let out : Array[Rule] = []
  for r in e.rules {
    out.push(r)
  }
  for l in locals {
    out.push(l)
  }
  Env::{ rules: out, }
}

///|
/// **區域實例感知**的一致性：把 locals 併進去看整體。這正是舊 API 缺的那一半 ——
/// `critical_pairs(e)` 掃不到 locals，所以只看全域規則時永遠回報一致。
pub fn coherent_with_local(
  e : Env,
  locals : Array[Rule],
  depth : Int32,
) -> Bool {
  coherent_complete(with_locals(e, locals), depth)
}

// ---------------------------------------------------------------------------
// 4. 擴充穩定性（COCHIS 的 stability property）
// ---------------------------------------------------------------------------

///|
/// 加規則後是否**穩定**：所有「原本就解得出」的可達目標，
/// 其典範見證（`evidence`）必須一字不差。新變得可解的目標不算不穩定（那是擴充，不是漂移）。
pub fn stable_under(e : Env, extra : Array[Rule], depth : Int32) -> Bool {
  let grown = with_locals(e, extra)
  for g in reachable_closed_goals(e, depth) {
    let before = canonical(maximal_derivs(e, resolve_all(e, g, depth)), e)
    let after = canonical(
      maximal_derivs(grown, resolve_all(grown, g, depth)),
      grown,
    )
    match (before, after) {
      (Some(b), Some(a)) =>
        if !@core.u_eq(evidence(e, b), evidence(grown, a)) {
          return false
        }
      _ => ()
    }
  }
  true
}

///|
/// 找出第一個漂移的目標（不穩定時回報證據）。
pub fn instability_witness(
  e : Env,
  extra : Array[Rule],
  depth : Int32,
) -> @core.UTerm? {
  let grown = with_locals(e, extra)
  for g in reachable_closed_goals(e, depth) {
    match
      (
        canonical(maximal_derivs(e, resolve_all(e, g, depth)), e),
        canonical(maximal_derivs(grown, resolve_all(grown, g, depth)), grown),
      ) {
      (Some(b), Some(a)) =>
        if !@core.u_eq(evidence(e, b), evidence(grown, a)) {
          return Some(g)
        }
      _ => ()
    }
  }
  None
}

// ---------------------------------------------------------------------------
// 5. Newman：終止 ∧ 局部合流 ⇒ 合流
// ---------------------------------------------------------------------------

///|
/// 三件事分開回報，讓「引理成立」與「系統性質成立」不會被混為一談：
///   `terminating`  — 序數度量嚴格下降；
///   `local`        — 所有臨界對都可併合（局部合流）；
///   `global`       — 可達宇宙上每個目標的極大推導見證唯一（合流）。
pub struct NewmanReport {
  terminating : Bool
  locally_confluent : Bool
  global : Bool
}

///|
/// 量測 Newman 引理：在此片段中，`terminating && local` 應該推出 `global`。
pub fn newman(e : Env, depth : Int32) -> NewmanReport {
  let term = match terminating(e) {
    None => true
    Some(_) => false
  }
  let mut lc = true
  for (i, j) in critical_pairs(e) {
    if !overlapping_joinable(e, i, j, depth) {
      lc = false
    }
  }
  let global = ambiguous_goals(e, depth).length() == 0
  NewmanReport::{ terminating: term, locally_confluent: lc, global, }
}

// ---------------------------------------------------------------------------
// 定律
// ---------------------------------------------------------------------------

///|
/// 只有 showInt / showArray 的環境：每個目標唯一（因為只有一條能套上）。
pub fn env_minimal() -> Env {
  env([
    rule("showInt", 0, cls_show(ty_int()), []),
    rule("showArray", 0, cls_show(ty_array(@core.uvar(0))), [
      cls_show(@core.uvar(0)),
    ]),
  ])
}

///|
/// 同優先級的兩個 Show(Int)：經典的不一致（head 直接重疊）。
pub fn env_clash() -> Env {
  env([
    rule("showIntA", 0, cls_show(ty_int()), []),
    rule("showIntB", 0, cls_show(ty_int()), []),
  ])
}

///|
pub fn law_coherence_complete_checking_needs_no_user_battery() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 1) 基本：可達宇宙自己算得出來，而且不是空的
  let e = env_show()
  let univ = reachable_closed_goals(e, 3)
  @core.chk(
    out,
    "instances: complete checking needs no user battery #1",
    univ.length() >= 6,
  )
  // 2) 純規則環境一致 ⇒ 完備版也說一致
  @core.chk(
    out,
    "instances: complete checking needs no user battery #2",
    coherent_complete(e, 6),
  )
  @core.chk(
    out,
    "instances: complete checking needs no user battery #3",
    match incoherence_report(e, 6) {
      None => true
      Some(_) => false
    },
  )
  // 3) 極小環境也一致
  @core.chk(
    out,
    "instances: complete checking needs no user battery #4",
    coherent_complete(env_minimal(), 6),
  )
  // 4) 有衝突的環境 ⇒ 完備版說不一致，而且**指得出是哪個目標**
  let c = env_clash()
  @core.chk(
    out,
    "instances: complete checking needs no user battery #5",
    !coherent_complete(c, 6),
  )
  match incoherence_report(c, 6) {
    Some(g) =>
      @core.chk(
        out,
        "instances: complete checking needs no user battery #6",
        @core.u_eq(g, ground(cls_show(ty_int()))),
      )
    None =>
      @core.chk(
        out, "instances: complete checking needs no user battery #7", false,
      )
  }
  // 5) 可達宇宙包含泛型目標的具體化（Array/Pair 都被走過）
  let mut saw_array = false
  let mut saw_pair = false
  for g in univ {
    if @core.u_eq(g, ground(cls_show(ty_array(ty_int())))) {
      saw_array = true
    }
    if @core.u_eq(g, ground(cls_show(ty_pair(ty_int(), ty_int())))) {
      saw_pair = true
    }
  }
  @core.chk(
    out, "instances: complete checking needs no user battery #8", saw_array,
  )
  @core.chk(
    out, "instances: complete checking needs no user battery #9", saw_pair,
  )
  // 6) 深層目標（Array(Array(Int))）也在宇宙裡 —— 這是 battery 容易漏掉的那類
  let mut deep = false
  for g in univ {
    if @core.u_eq(g, ground(cls_show(ty_array(ty_array(ty_int()))))) {
      deep = true
    }
  }
  @core.chk(out, "instances: complete checking needs no user battery #10", deep)
  out
}

///|
pub fn law_coherence_local_peaks_coincide_with_head_overlaps() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 純 Horn 片段：可達宇宙上的重疊對 == 臨界對（正面結論，不是缺口）
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #1",
    peak_overlap_agreement(env_show(), 4),
  )
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #2",
    peak_overlap_agreement(env_minimal(), 4),
  )
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #3",
    peak_overlap_agreement(env_clash(), 4),
  )
  // 優先級不同的重疊：仍是一個臨界對，但可併合（典範化挑得出唯一見證）
  let prio = env([
    rule("generic", 0, cls_show(@core.uvar(0)), []),
    rule("specificInt", 1, cls_show(ty_int()), []),
  ])
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #4",
    peak_overlap_agreement(prio, 4),
  )
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #5",
    critical_pairs(prio).length() == 1,
  )
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #6",
    coherent_complete(prio, 6),
  )
  // 兩個泛型實例互相重疊（Array 與 Pair 不重疊，所以臨界對為 0）
  @core.chk(
    out,
    "instances: local peaks coincide with head overlaps #7",
    critical_pairs(env_show()).length() == 0,
  )
  out
}

///|
pub fn law_coherence_local_instances_are_the_missing_half() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_minimal()
  // 全域規則之間完全沒有衝突
  @core.chk(
    out,
    "instances: local instances are the missing half #1",
    critical_pairs(e).length() == 0,
  )
  @core.chk(
    out,
    "instances: local instances are the missing half #2",
    coherent_complete(e, 6),
  )
  // 但若模組裡還有一條同優先級的 Show(Int)（區域實例），
  // 只看 `e.rules` 的 `critical_pairs` 結構上看不見它
  let locals = [local_instance("modShowInt", 0, cls_show(ty_int()))]
  @core.chk(
    out,
    "instances: local instances are the missing half #3",
    critical_pairs(e).length() == 0,
  )
  // 併進來之後就抓到了 —— 這就是舊 API 的缺口
  @core.chk(
    out,
    "instances: local instances are the missing half #4",
    !coherent_with_local(e, locals, 6),
  )
  // 若區域實例優先級更高，則是「具具體者勝」而非不一致
  let strong = [local_instance("modShowInt", 5, cls_show(ty_int()))]
  @core.chk(
    out,
    "instances: local instances are the missing half #5",
    coherent_with_local(e, strong, 6),
  )
  // 無關的區域實例（Eq(Bool)）不影響一致性
  let unrelated = [local_instance("modEqBool", 0, cls_eq(ty_bool()))]
  @core.chk(
    out,
    "instances: local instances are the missing half #6",
    coherent_with_local(e, unrelated, 6),
  )
  // 不穩定時要指得出目標（用「更高優先級的區域實例」示範漂移）
  match instability_witness(e, strong, 6) {
    Some(g) =>
      @core.chk(
        out,
        "instances: local instances are the missing half #7",
        @core.u_eq(g, ground(cls_show(ty_int()))),
      )
    None =>
      @core.chk(
        out, "instances: local instances are the missing half #8", false,
      )
  }
  out
}

///|
pub fn law_coherence_extension_stability_is_decided() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let e = env_show()
  // 1) 加無關實例 ⇒ 穩定
  let unrelated = [rule("eqBool", 0, cls_eq(ty_bool()), [])]
  @core.chk(
    out,
    "instances: extension stability is decided #1",
    stable_under(e, unrelated, 6),
  )
  // 2) 加一條更高優先級的具體實例 ⇒ 見證改變（不穩定是**正確**行為：具體者勝）
  let more_specific = [rule("showIntSpecial", 3, cls_show(ty_int()), [])]
  @core.chk(
    out,
    "instances: extension stability is decided #2",
    !stable_under(e, more_specific, 6),
  )
  // 3) 漂移只發生在被影響的目標上
  match instability_witness(e, more_specific, 6) {
    Some(g) =>
      @core.chk(
        out,
        "instances: extension stability is decided #3",
        @core.u_eq(g, ground(cls_show(ty_int()))),
      )
    None =>
      @core.chk(out, "instances: extension stability is decided #4", false)
  }
  // 4) 同優先級的 catch-all 不會漂移（平手時典範化取規則索引小者，仍是 showInt）……
  let catch_all_same = [rule("showAny", 0, cls_show(@core.uvar(0)), [])]
  @core.chk(
    out,
    "instances: extension stability is decided #5",
    stable_under(e, catch_all_same, 6),
  )
  //    ……但高優先級的 catch-all 會（具體者勝 ⇒ 見證整體換掉）：這才是真漂移
  let catch_all_high = [rule("showAny", 2, cls_show(@core.uvar(0)), [])]
  @core.chk(
    out,
    "instances: extension stability is decided #5b",
    !stable_under(e, catch_all_high, 6),
  )
  // 5) 穩定性對同一個擴充是「可重複判定」的（同一輸入兩次答案相同）
  let a = stable_under(e, unrelated, 6)
  let b = stable_under(e, unrelated, 6)
  @core.chk(out, "instances: extension stability is decided #6", a == b)
  out
}

///|
pub fn law_coherence_newman_lemma_measured_on_the_fragment() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // (a) env_show：終止 + 局部合流 ⇒ 全域合流
  let r1 = newman(env_show(), 6)
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #1",
    r1.terminating,
  )
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #2",
    r1.locally_confluent,
  )
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #3",
    r1.global,
  )
  // (b) 兩個同優先級實例：終止但**不**局部合流 ⇒ 不全域合流（引理的逆否）
  let r2 = newman(env_clash(), 6)
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #4",
    r2.terminating,
  )
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #5",
    !r2.locally_confluent,
  )
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #6",
    !r2.global,
  )
  // (c) 會繞圈的環境：終止性失敗（引理的前提不成立，結論不得引用）
  let loop_env = env([
    rule("loop", 0, cls_show(@core.uvar(0)), [cls_show(ty_array(@core.uvar(0)))]),
  ])
  let r3 = newman(loop_env, 3)
  @core.chk(
    out,
    "instances: Newman lemma measured on the fragment #7",
    !r3.terminating,
  )
  // (d) 引理在本批環境上沒有反例：(terminating && local) ⇒ global
  let mut ok = true
  let battery = [env_show(), env_minimal(), env_clash()]
  for e in battery {
    let r = newman(e, 6)
    if r.terminating && r.locally_confluent && !r.global {
      ok = false
    }
  }
  @core.chk(out, "instances: Newman lemma measured on the fragment #8", ok)
  out
}
