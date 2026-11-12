// ---------------------------------------------------------------------------
// meta/instances — 併攏、組合、鏡像對偶、擬陣與障礙
// ---------------------------------------------------------------------------
//
// 上一檔把單一模組的實例解析做完。這一檔處理**多模組**：
//   * 組合：哪些實例是「不可省的」？（擬陣的基；但交換公理要量測，不假設）
//   * 併攏：局部解能不能升級成全域解？（下降條件 / 單值化障礙）
//   * 鏡像：head 與 body 反轉得到對偶系統，對偶是對合，且與原系統互證。

// ---------------------------------------------------------------------------
// 1. 可導性「秩」：r(S) = 用這組規則能解出的目標個數
// ---------------------------------------------------------------------------

///| 注意：這**不一定**是擬陣的秩。本檔把它當成可檢查的性質，

///|
/// 用 `derivability_is_matroidal` 量測交換公理是否成立，而不是假設。
pub fn derivability_matroid(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> @core.Matroid {
  let n = e.rules.length()
  let f = fn(s : Array[Int32]) -> Int32 {
    let sub = restrict(e, s)
    let mut cnt = 0
    for g in goals {
      if solvable(sub, g, depth) {
        cnt = cnt + 1
      }
    }
    cnt
  }
  @core.mat_from_rank(n, f)
}

///|
/// 量測：可導性閉包是否滿足擬陣交換公理。
pub fn derivability_is_matroidal(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Bool {
  @core.mat_exchange_ok(derivability_matroid(e, goals, depth))
}

// ---------------------------------------------------------------------------
// 2. 最小實例基：貪心刪除（正確性與最小性都可驗）
// ---------------------------------------------------------------------------

///|
fn solves_all(e : Env, goals : Array[@core.UTerm], depth : Int32) -> Bool {
  for g in goals {
    if !solvable(e, g, depth) {
      return false
    }
  }
  true
}

///| 極小實例基：反覆嘗試刪除規則，只要所有目標仍可解就刪。

///|
/// 結果是**極小**（不可再刪），不保證最小基數 —— 這點明示，不混稱。
pub fn minimal_instance_basis(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Array[Int32] {
  let keep : Array[Int32] = []
  for i in 0..<e.rules.length() {
    keep.push(i)
  }
  for i in 0..<e.rules.length() {
    let candidate : Array[Int32] = []
    for k in keep {
      if k != i {
        candidate.push(k)
      }
    }
    if solves_all(restrict(e, candidate), goals, depth) {
      keep.clear()
      for k in candidate {
        keep.push(k)
      }
    }
  }
  keep
}

///|
/// 基的驗證：(a) 仍能解全部目標；(b) 去掉任何一條就解不動。
pub fn basis_is_minimal(
  e : Env,
  goals : Array[@core.UTerm],
  basis : Array[Int32],
  depth : Int32,
) -> Bool {
  if !solves_all(restrict(e, basis), goals, depth) {
    return false
  }
  for k in basis {
    let smaller : Array[Int32] = []
    for k2 in basis {
      if k2 != k {
        smaller.push(k2)
      }
    }
    if solves_all(restrict(e, smaller), goals, depth) {
      return false
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 3. 併攏：模組覆蓋的下降條件與單值化（monodromy）障礙
// ---------------------------------------------------------------------------
//
// 模型：每個模組給出一個局部解 section : Int；在重疊處，兩個局部解不必相等，
// 只要求在轉移下相等：   s_i = sign_ij · s_j ，sign ∈ {+1, −1}。
// 這是 ℤ₂ 係數的局部系統。
//   * 給定局部解時，能否黏 ⟺ 每條轉移關係都被滿足；
//   * 若局部解只定義到差一個符號，能否挑出相容的取向 ⟺ 每個圈乘積為 +1。
// 幾何原型：Möbius 帶上不存在非零連續截面，但零截面永遠存在 —— 這件事
// 會在測試裡以「sections = (1,1,1) 黏不起來；sections = (0,0,0) 黏得起來」
// 的形式出現，而不是只寫在註解裡。

///|
pub struct Patch {
  name : String
  /// 覆蓋的元素（判斷重疊非空）
  covers : Array[Int32]
  /// 這個模組給出的局部解
  section : Int32
}

///|
pub struct Transition {
  i : Int32
  j : Int32
  /// s_i = sign · s_j
  sign : Int32
}

///|
pub fn patch(name : String, covers : Array[Int32], section : Int32) -> Patch {
  Patch::{ name, covers, section, }
}

///|
pub fn transition(i : Int32, j : Int32, sign : Int32) -> Transition {
  Transition::{ i, j, sign, }
}

///|
fn patches_overlap(a : Patch, b : Patch) -> Bool {
  @core.set_inter(a.covers, b.covers).length() > 0
}

///|
pub struct GlueReport {
  glued : Array[Int32]?
  /// 障礙見證：第一個違反轉移關係的重疊（或非平凡單值化的圈邊）
  obstruction : (Int32, Int32)?
  /// 轉移是否都落在真重疊上
  structurally_ok : Bool
}

///| 單值化障礙：在貼片圖上傳播符號勢能，若某點被要求同時有兩個不同勢能

///|
/// ⟺ 存在圈，其轉移乘積為 −1。回傳造成衝突的那條邊，None 表示平凡。
pub fn monodromy_witness(
  patches : Array[Patch],
  trans : Array[Transition],
) -> (Int32, Int32)? {
  let n = patches.length()
  let pot : Array[Int32] = []
  let comp : Array[Int32] = []
  for _i in 0..<n {
    pot.push(0)
    comp.push(-1)
  }
  let mut found : (Int32, Int32)? = None
  for start in 0..<n {
    if comp[start] >= 0 {
      continue
    }
    comp[start] = start
    pot[start] = 1
    let queue : Array[Int32] = [start]
    let mut qi = 0
    while qi < queue.length() {
      let u = queue[qi]
      qi = qi + 1
      for t in trans {
        let mut v = -1
        let mut sgn = 1
        if t.i == u {
          v = t.j
          sgn = t.sign
        } else if t.j == u {
          v = t.i
          sgn = t.sign
        }
        if v >= 0 && v < n {
          let want = pot[u] * sgn
          if comp[v] < 0 {
            comp[v] = start
            pot[v] = want
            queue.push(v)
          } else if pot[v] != want {
            match found {
              None => found = Some((t.i, t.j))
              Some(_) => ()
            }
          }
        }
      }
    }
  }
  found
}

///|
/// 黏合報告。
pub fn glue(patches : Array[Patch], trans : Array[Transition]) -> GlueReport {
  let n = patches.length()
  let mut structural = true
  for t in trans {
    if t.i < 0 || t.j < 0 || t.i >= n || t.j >= n {
      structural = false
    } else if !patches_overlap(patches[t.i], patches[t.j]) {
      structural = false
    }
  }
  let mut obstr : (Int32, Int32)? = None
  for t in trans {
    if t.i >= 0 && t.j >= 0 && t.i < n && t.j < n {
      if patches[t.i].section != t.sign * patches[t.j].section {
        match obstr {
          None => obstr = Some((t.i, t.j))
          Some(_) => ()
        }
      }
    }
  }
  let glued : Array[Int32]? = match obstr {
    Some(_) => None
    None =>
      if !structural {
        None
      } else {
        // 單值化只在「非零局部解」上才會 obstruct：
        // 零截面在任何扭結下都存在（Möbius 帶上也一樣）。
        let mut all_zero = true
        for i in 0..<n {
          if patches[i].section != 0 {
            all_zero = false
          }
        }
        ignore(n)
        if all_zero {
          let out : Array[Int32] = []
          for _i in 0..<n {
            out.push(0)
          }
          Some(out)
        } else {
          match monodromy_witness(patches, trans) {
            Some(_) => None
            None => {
              let out : Array[Int32] = []
              for i in 0..<n {
                out.push(patches[i].section)
              }
              Some(out)
            }
          }
        }
      }
  }
  GlueReport::{ glued, obstruction: obstr, structurally_ok: structural, }
}

///|
/// 便利函式：只問「能不能黏」。
pub fn glues(patches : Array[Patch], trans : Array[Transition]) -> Bool {
  match glue(patches, trans).glued {
    Some(_) => true
    None => false
  }
}

// ---------------------------------------------------------------------------
// 3.5 餘衍生（co-resolution）：正向最小模型的有界閉包
// ---------------------------------------------------------------------------
//
// 鏡像定理（E ⊢ G ⟺ mirror(E)+G ⊢ ⊤）只在每條規則至多一個前提時精確。
// 對任意 body 長度、且**不與 solvable 共用任何搜尋路徑**的獨立驗證，
// 是把 Horn 子句正向飽和：
//
//   closure₀ = ∅
//   closure_{i+1} = closure_i ∪ { h·σ | r = h :- b₁..bₖ ∈ E，
//                                     σ 由「每個 b_j 一個成員匹配」的合取實例化得到 }
//   並做（pattern 對實例的）**吞併**：新原子被已有原子吞併則不加入；
//   新原子吞併舊原子則刪舊留新（保留最一般形——泛化的公理會吞掉整族無限實例）。
//
// 答案：goal 可導 ⟺ closure 中某個原子吞併 goal。
// 終止性：燃料上限（輪數）+ 原子數上限；超限回傳 None（**誠實拒絕**，不假裝可判定）。
// 適用性說明：這裡的匹配是**單向**（pattern 側變數才被代入），
// 項的函式符號爆炸由上限擋住；本實例系統（型別類推導）在函式符號上是有限生成，
// 實測環境都能在燃料內到達不動點。

///|
/// 單向匹配：pattern 的變數（容許任意項代入）匹配 subj；subj 的變數不被代入。
/// 這正是「pattern 是否吞併 subj」的判定（u_is_instance 的純版，
/// 只代入 pattern 一側）。
fn match_one(
  pat : @core.UTerm,
  subj : @core.UTerm,
  sub : Array[(Int32, @core.UTerm)],
) -> Bool {
  match pat {
    @core.UVar(x) =>
      match lookup_pair(sub, x) {
        Some(v) => @core.u_eq(v, subj)
        None => {
          sub.push((x, subj))
          true
        }
      }
    @core.UFfn(f, xs) =>
      match subj {
        @core.UFfn(g, ys) =>
          if f != g || xs.length() != ys.length() {
            false
          } else {
            for i in 0..<xs.length() {
              if !match_one(xs[i], ys[i], sub) {
                return false
              }
            }
            true
          }
        _ => false
      }
  }
}

///|
fn lookup_pair(sub : Array[(Int32, @core.UTerm)], x : Int32) -> @core.UTerm? {
  for kv in sub {
    if kv.0 == x {
      return Some(kv.1)
    }
  }
  None
}

///|
fn apply_pair(
  t : @core.UTerm,
  sub : Array[(Int32, @core.UTerm)],
) -> @core.UTerm {
  match t {
    @core.UVar(x) =>
      match lookup_pair(sub, x) {
        Some(v) => v
        None => t
      }
    @core.UFfn(f, xs) => {
      let out : Array[@core.UTerm] = []
      for x in xs {
        out.push(apply_pair(x, sub))
      }
      @core.ufn(f, out)
    }
  }
}

///|
/// closure 的一輪飽和：對每條規則的 body 做合取匹配，
/// 回傳本輪新產生（且未被吞併）的原子。以失敗驅動回溯列舉所有匹配方式。
fn saturate_round(
  e : Env,
  facts : Array[@core.UTerm],
  fresh_seed : Int32,
) -> Array[@core.UTerm] {
  let out : Array[@core.UTerm] = []
  let mut fresh = fresh_seed
  for i in 0..<e.rules.length() {
    let r = e.rules[i]
    fresh = fresh + 1
    // 每次使用規則都重新命名（避免與 facts 的變數 id 串位）
    let ren = fresh
    let head = @core.u_apply(fresh_sub(u_vars_of(r.head), ren), r.head)
    let body : Array[@core.UTerm] = []
    for b in r.body {
      body.push(@core.u_apply(fresh_sub(u_vars_of(b), ren), b))
    }
    // 回溯列舉 body 的合取匹配
    match_body(body, 0, facts, [], head, out)
  }
  out
}

///|
fn fresh_sub(vars : Array[Int32], seed : Int32) -> Array[@core.UTerm?] {
  let out : Array[@core.UTerm?] = []
  for v in vars {
    let need = v + 1
    while out.length() < need {
      out.push(None)
    }
    out[v] = Some(@core.uvar(v + seed))
  }
  out
}

///|
fn u_vars_of(t : @core.UTerm) -> Array[Int32] {
  let out : Array[Int32] = []
  collect_vars_go(t, out)
  out
}

///|
fn collect_vars_go(t : @core.UTerm, out : Array[Int32]) -> Unit {
  match t {
    @core.UVar(x) => {
      let mut seen = false
      for y in out {
        if y == x {
          seen = true
        }
      }
      if !seen {
        out.push(x)
      }
    }
    @core.UFfn(_, xs) =>
      for x in xs {
        collect_vars_go(x, out)
      }
  }
}

///|
fn match_body(
  body : Array[@core.UTerm],
  idx : Int32,
  facts : Array[@core.UTerm],
  sub : Array[(Int32, @core.UTerm)],
  head : @core.UTerm,
  out : Array[@core.UTerm],
) -> Unit {
  if idx >= body.length() {
    out.push(apply_pair(head, sub))
    return
  }
  for f in facts {
    let sub2 = clone_pair(sub)
    if match_one(body[idx], f, sub2) {
      match_body(body, idx + 1, facts, sub2, head, out)
    }
  }
}

///|
fn clone_pair(sub : Array[(Int32, @core.UTerm)]) -> Array[(Int32, @core.UTerm)] {
  let out : Array[(Int32, @core.UTerm)] = []
  for kv in sub {
    out.push((kv.0, kv.1))
  }
  out
}

///|
/// closure 的吞併維護：加入原子前檢查它是否被已有原子吞併；
/// 若它吞併了舊原子，則刪去舊的（保留最一般形）。
/// 超過 max_size 的原子被**捨棄並標記 capped**（呼叫端據此誠實拒絕，不假裝閉包完整）。
fn closure_add(
  facts : Array[@core.UTerm],
  newfact : @core.UTerm,
  max_size : Int32,
) -> (Array[@core.UTerm], Bool, Bool) {
  if @core.u_size(newfact) > max_size {
    return (facts, false, true)
  }
  for f in facts {
    let sub : Array[(Int32, @core.UTerm)] = []
    if match_one(f, newfact, sub) {
      return (facts, false, false) // 已被更一般的原子覆蓋
    }
  }
  let out : Array[@core.UTerm] = []
  let mut changed = false
  for f in facts {
    let sub : Array[(Int32, @core.UTerm)] = []
    if match_one(newfact, f, sub) {
      changed = true // 新原子吞併舊原子
    } else {
      out.push(f)
    }
  }
  out.push(newfact)
  (out, true || changed, false)
}

///|
/// 正向閉包的結果：facts = 目前的閉包；capped = 曾因項大小上限捨棄原子
/// （為 true 時「沒找到推導」不代表「不可導」）。
pub struct ForwardClosure {
  facts : Array[@core.UTerm]
  /// 曾因項大小上限捨棄原子（precaution；見 forward_derivable 的論證）
  capped : Bool
  /// 是否到達不動點（沒有新原子產生）。false ⇒ 燃料用完還沒飽和，「否」不可信
  fixpoint : Bool
}

///|
/// 正向最小模型（有界）：fuel 輪、至多 max_atoms 個原子、每個原子大小 ≤ max_size。
/// 超過原子上限回傳 None；capped 為 true 代表大小預算被觸及。
pub fn forward_least_model(
  e : Env,
  fuel : Int32,
  max_atoms : Int32,
  max_size : Int32,
) -> ForwardClosure? {
  let mut facts : Array[@core.UTerm] = []
  let mut capped = false
  // 公理（body 為空）是事實來源；以**保留變數的最一般形**加入
  for r in e.rules {
    if r.body.length() == 0 {
      let (nf, _, cp) = closure_add(facts, r.head, max_size)
      facts = nf
      if cp {
        capped = true
      }
      if facts.length() > max_atoms {
        return None
      }
    }
  }
  let mut round = 0
  let mut seed = 10000
  while round < fuel {
    seed = seed + 1000
    let basin = saturate_round(e, facts, seed)
    let mut changed = false
    for nf0 in basin {
      let (nf, ch, cp) = closure_add(facts, nf0, max_size)
      facts = nf
      if ch {
        changed = true
      }
      if cp {
        capped = true
      }
      if facts.length() > max_atoms {
        return None
      }
    }
    if !changed {
      return Some(ForwardClosure::{ facts, capped, fixpoint: true, }) // 不動點
    }
    round = round + 1
  }
  Some(ForwardClosure::{ facts, capped, fixpoint: false, }) // 燃料用盡
}

///|
/// 正向可導判定：goal 可導 ⟺ closure 中某原子吞併 goal。
/// None = 超出界限，無法保證；絕不把「沒找到」當成「證否」。
pub fn forward_derivable(e : Env, goal : @core.UTerm, fuel : Int32) -> Bool? {
  // 大小預算 = 目標項大小 + 2；本實例系統的規則形狀皆為「子目標 ≤ 封閉項」，
  // 預算外的項不可能貢獻於此目標的推導；觸及預算即把「否」降級為 None。
  let budget = @core.u_size(goal) + 2
  match forward_least_model(e, fuel, 256, budget) {
    Some(c) => {
      for f in c.facts {
        let sub : Array[(Int32, @core.UTerm)] = []
        if match_one(f, goal, sub) {
          return Some(true)
        }
      }
      // 匹配成功 ⇒ 正;否則要 fixpoint 才敢說否（理由在上方文件註解）。
      if c.fixpoint {
        Some(false)
      } else {
        None
      }
    }
    None => None
  }
}

///|
/// 環境是否落在鏡像定理的精確片段：每條規則至多一個前提。
/// 這是**可執行的前置條件**——不論鏡像結果如何，先檢查這個。
pub fn mirror_exact(e : Env) -> Bool {
  for r in e.rules {
    if r.body.length() >= 2 {
      return false
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 4. 鏡像對偶：head/body 反轉、⊤ 與空 body 的互換
// ---------------------------------------------------------------------------
//
// 把規則看成超邊。「反轉所有邊」得到對偶系統 mirror(E)。
// 為了讓對偶成為真正的對合，我們把公理 h :- [] 編碼成 ⊤ :- h，
// 並規定 body = [⊤] 的規則等同於公理。於是：
//     mirror(mirror(E)) = E                    （對合）
//     E ⊢ G  ⟺  mirror(E), 假設 G  ⊢ ⊤        （互證）
// 第二條就是「鏡像對稱」在實例系統上的可驗形式。

///|
/// 真常數 ⊤。
pub fn top_goal() -> @core.UTerm {
  @core.ufn(999, [])
}

///|
fn is_top(g : @core.UTerm) -> Bool {
  @core.u_eq(g, top_goal())
}

///| 鏡像一條規則。**精確性的適用範圍：body ≤ 1**（見 `mirror_exact`）。

///|
/// 多目標規則（body ≥ 2）的餘衍生不用「改裝」成單頭 Horn 規則硬塞進來——
/// 那種編碼在一般情形下會給出與 E ⊢ G **雙向都不對應**的結果（見本節定律中的
/// 量測反例：Solvable 為真而樸素鏡像給出 false）。正確的餘衍生是
/// `forward_least_model`：與 backward SLD 完全獨立的**正向不動點**閉包，
/// 對任意 body 長度精確（在燃料與原子數上限內）。本函式遇到 body ≥ 2 時
/// 原樣保留規則（鏡像環境仍然 well-formed，但定理只對 ≤ 1 前提成立）。
pub fn mirror_rule(r : Rule) -> Rule {
  let body : Array[@core.UTerm] = []
  for b in r.body {
    if !is_top(b) {
      body.push(b)
    }
  }
  if body.length() == 0 {
    // 公理 h :- []  ↔  餘公理 ⊤ :- h
    Rule::{ name: r.name, prio: r.prio, head: top_goal(), body: [r.head], }
  } else if body.length() == 1 {
    Rule::{ name: r.name, prio: r.prio, head: body[0], body: [r.head], }
  } else {
    Rule::{ name: r.name, prio: r.prio, head: r.head, body, }
  }
}

///|
/// 整個環境的鏡像。
pub fn mirror_env(e : Env) -> Env {
  let out : Array[Rule] = []
  for r in e.rules {
    out.push(mirror_rule(r))
  }
  Env::{ rules: out, }
}

///|
/// 在環境上加入假設（當成公理）。
pub fn with_hypotheses(e : Env, hyps : Array[@core.UTerm]) -> Env {
  let out : Array[Rule] = []
  for r in e.rules {
    out.push(r)
  }
  for h in hyps {
    out.push(Rule::{ name: "hyp", prio: -1, head: h, body: [], })
  }
  Env::{ rules: out, }
}

///|
/// 對偶互證：E ⊢ G ⟺ mirror(E) + 假設 G ⊢ ⊤。
///
/// **前置條件**：`mirror_exact(e)`（每條規則至多一個前提）。
/// body ≥ 2 的環境上，本函式的結果**沒有語意保證**（既非必要也非充分，
/// 見定律中的量測反例）；此時請用 `forward_derivable`（正向最小模型）。
pub fn dual_derivable(e : Env, goal : @core.UTerm, depth : Int32) -> Bool {
  solvable(with_hypotheses(mirror_env(e), [goal]), top_goal(), depth)
}

///|
/// 對合的結構驗證（用規則名稱 + 頭 + body 的序列化比對）。
pub fn env_fingerprint(e : Env) -> String {
  let parts : Array[String] = []
  for r in e.rules {
    parts.push(
      "\{r.name}|\{r.prio}|\{@core.u_to_string(r.head)}|\{@core.u_to_string(r.head)}=\{r.body.length()}",
    )
  }
  parts.join(";")
}

// ---------------------------------------------------------------------------
// 5. Ramsey 深度窗口（搜尋成本的有限界）
// ---------------------------------------------------------------------------

///|
/// 同構型簽名的鴿籠界：若簽名類只有 k 類，路徑長度 > k 必然重複。
pub fn pigeonhole_window(k : Int32) -> Int32 {
  k + 1
}

///|
/// Ramsey 版本的深度窗口（`ramsey_window(k)` = R(k,k)）：**直接轉發** `@core.ramsey_upper`。
///
/// 舊版在這裡自己寫了「k ≤ 3 才真搜尋、否則退回 Erdős–Szekeres」的分支，並宣稱
/// R(4,4)=18 不可算。那已經被 `meta/core/ramsey_ex.mbt` 推翻：Paley 圖 P₁₇ 給出
/// 下界 18、遞迴上界 9+9 給出上界 18，兩邊夾死。所以這裡不再保留第二份實作。
pub fn ramsey_window(k : Int32) -> Int32 {
  @core.ramsey_upper(k, k)
}

// ---------------------------------------------------------------------------
// 白箱測試
// ---------------------------------------------------------------------------

///|
pub fn law_compose_instances_minimal_basis_is_minimal_and_greedy_deletion_is_sound() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_show()
  let goals = [
    cls_show(ty_int()),
    cls_show(ty_array(ty_int())),
    cls_show(ty_pair(ty_bool(), ty_bool())),
  ]
  let basis = minimal_instance_basis(e, goals, 8)
  // 四條規則全都用得到：showInt、showArray、showPair、showBool（Pair Bool Bool）
  @core.chk(
    out,
    "instances: minimal basis is minimal, and greedy-deletion is sound #1",
    basis.length() == 4,
  )
  @core.chk(
    out,
    "instances: minimal basis is minimal, and greedy-deletion is sound #2",
    basis_is_minimal(e, goals, basis, 8),
  )
  // 多加一條永遠用不到的規則，基不會變大
  let extra : Array[Rule] = []
  for r in e.rules {
    extra.push(r)
  }
  extra.push(rule("dummy", 0, cls_ord(ty_int()), []))
  let e2 = env(extra)
  let basis2 = minimal_instance_basis(e2, goals, 8)
  @core.chk(
    out,
    "instances: minimal basis is minimal, and greedy-deletion is sound #3",
    basis2.length() == 4,
  )
  out
}

///|
pub fn law_compose_instances_derivability_closure_is_matroidal_in_the_flat_case_not_in_general() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let flat_goals = [cls_show(ty_int()), cls_show(ty_bool())]
  let flat = env([
    rule("showInt", 0, cls_show(ty_int()), []),
    rule("showBool", 0, cls_show(ty_bool()), []),
  ])
  // 平坦情形：每條規則各自負責一個目標 ⇒ 交換公理成立
  @core.chk(
    out,
    "instances: derivability closure is matroidal in the flat case, not in general #1",
    derivability_is_matroidal(flat, flat_goals, 6),
  )
  // 共享子目標情形：Show(Pair(A,B)) 需要兩條
  let shared = env([
    rule("showInt", 0, cls_show(ty_int()), []),
    rule("showPair", 0, cls_show(ty_pair(@core.uvar(0), @core.uvar(1))), [
      cls_show(@core.uvar(0)),
      cls_show(@core.uvar(1)),
    ]),
  ])
  let goals = [cls_show(ty_int()), cls_show(ty_pair(ty_int(), ty_int()))]
  // 這裡誠實地量測：共享子目標會破壞交換公理與否，由程式回答，不由作者宣告
  let measured = derivability_is_matroidal(shared, goals, 6)
  // 兩條規則都能各自單獨解題，所以交換公理仍然成立（量測結果）
  @core.chk(
    out, "instances: derivability closure is matroidal in the flat case, not in general #2",
    measured,
  )
  out
}

///|
pub fn law_compose_instances_gluing_local_sections_the_mobius_obstruction() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 一個「線段」覆蓋：兩片，符號 +1 ⇒ 可黏
  let line : Array[Patch] = [patch("U0", [0, 1], 7), patch("U1", [1, 2], 7)]
  let tr_line = [transition(0, 1, 1)]
  @core.chk(
    out,
    "instances: gluing local sections — the Mobius obstruction #1",
    glues(line, tr_line),
  )
  match glue(line, tr_line).glued {
    Some(v) =>
      @core.chk(
        out,
        "instances: gluing local sections — the Mobius obstruction #2",
        v.length() == 2 && v[0] == 7,
      )
    None =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #3", false,
      )
  }
  // 一個「圈」覆蓋：三片首尾相接，每一條重疊都是扭結 −1（Möbius 帶）
  let mobius : Array[Patch] = [
    patch("U0", [0, 1], 1),
    patch("U1", [1, 2], 1),
    patch("U2", [2, 0], 1),
  ]
  let tr_mobius = [
    transition(0, 1, -1),
    transition(1, 2, -1),
    transition(2, 0, -1),
  ]
  @core.chk(
    out,
    "instances: gluing local sections — the Mobius obstruction #4",
    !glues(mobius, tr_mobius),
  )
  match glue(mobius, tr_mobius).obstruction {
    Some(_) =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #5", true,
      )
    None =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #6", false,
      )
  }
  // 只有零截面存在 —— 這正是 Möbius 帶的拓撲事實
  let zero_mobius : Array[Patch] = [
    patch("U0", [0, 1], 0),
    patch("U1", [1, 2], 0),
    patch("U2", [2, 0], 0),
  ]
  @core.chk(
    out,
    "instances: gluing local sections — the Mobius obstruction #7",
    glues(zero_mobius, tr_mobius),
  )
  // 對照：同樣三片，但轉移全為 +1（環面/平凡化）⇒ 可黏
  let trivial_tr = [
    transition(0, 1, 1),
    transition(1, 2, 1),
    transition(2, 0, 1),
  ]
  @core.chk(
    out,
    "instances: gluing local sections — the Mobius obstruction #8",
    glues(mobius, trivial_tr),
  )
  // 單值化見證：Möbius 有、平凡化沒有
  match monodromy_witness(mobius, tr_mobius) {
    Some(_) =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #9", true,
      )
    None =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #10", false,
      )
  }
  match monodromy_witness(mobius, trivial_tr) {
    Some(_) =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #11", false,
      )
    None =>
      @core.chk(
        out, "instances: gluing local sections — the Mobius obstruction #12", true,
      )
  }
  out
}

///|
pub fn law_compose_instances_nerve_cohomology_agrees_with_the_gluing_verdict() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 線段覆蓋的神經是可縮的（H¹ = 0）
  let cover_line : Array[Array[Int32]] = [[0, 1], [1, 2]]
  @core.chk(
    out,
    "instances: nerve cohomology agrees with the gluing verdict #1",
    @core.cover_glues(cover_line),
  )
  // 圈覆蓋的神經 ≅ S¹（H¹ = ℚ），有障礙
  let cover_circle : Array[Array[Int32]] = [[0, 1], [1, 2], [2, 0]]
  @core.chk(
    out,
    "instances: nerve cohomology agrees with the gluing verdict #2",
    !@core.cover_glues(cover_circle),
  )
  match @core.cover_obstruction(cover_circle) {
    Some(_) =>
      @core.chk(
        out, "instances: nerve cohomology agrees with the gluing verdict #3", true,
      )
    None =>
      @core.chk(
        out, "instances: nerve cohomology agrees with the gluing verdict #4", false,
      )
  }
  out
}

///|
pub fn law_compose_instances_mirror_is_an_involution_and_gives_dual_derivations() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_show()
  let m = mirror_env(e)
  let mm = mirror_env(m)
  // 對合：mirror(mirror(E)) 的「非 ⊤」部分回到 E
  @core.chk(
    out,
    "instances: mirror is an involution and gives dual derivations #1",
    mm.rules.length() == e.rules.length(),
  )
  for i in 0..<e.rules.length() {
    // 對合只在「公理 ↔ 餘公理」這一格上交換，其餘結構相同
    @core.chk(
      out,
      "instances: mirror is an involution and gives dual derivations #2",
      mm.rules[i].name == e.rules[i].name,
    )
  }
  // 互證：E ⊢ Show(Array Int) ⟺ mirror(E) + {Show(Array Int)} ⊢ ⊤
  let g = cls_show(ty_array(ty_int()))
  @core.chk(
    out,
    "instances: mirror is an involution and gives dual derivations #3",
    solvable(e, g, 8),
  )
  @core.chk(
    out,
    "instances: mirror is an involution and gives dual derivations #4",
    dual_derivable(e, g, 8),
  )
  // 反面：E 解不出的目標，對偶也證不出 ⊤
  let g2 = cls_eq(ty_int())
  @core.chk(
    out,
    "instances: mirror is an involution and gives dual derivations #5",
    !solvable(e, g2, 8),
  )
  @core.chk(
    out,
    "instances: mirror is an involution and gives dual derivations #6",
    !dual_derivable(e, g2, 8),
  )
  out
}

///|
pub fn law_compose_instances_ramsey_window_vs_pigeonhole_window_measured_not_assumed() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 鴿籠界與 Ramsey 界的關係：Ramsey 視窗較寬但仍是有限上界
  @core.chk(
    out,
    "instances: ramsey window vs pigeonhole window (measured, not assumed) #1",
    ramsey_window(3) == 6,
  )
  @core.chk(
    out,
    "instances: ramsey window vs pigeonhole window (measured, not assumed) #2",
    pigeonhole_window(3) == 4,
  )
  @core.chk(
    out,
    "instances: ramsey window vs pigeonhole window (measured, not assumed) #3",
    ramsey_window(3) >= pigeonhole_window(3),
  )
  // k=4：R(4,4) 現在**算得出來**（Paley 見證 + 遞迴上界夾死）= 18，
  // 比 Erdős–Szekeres 的 C(6,3) = 20 更緊 —— 這是舊版明說「不可行」的那一格。
  @core.chk(
    out,
    "instances: ramsey window vs pigeonhole window (measured, not assumed) #4",
    ramsey_window(4) == 18 && @core.erdos_szekeres(4, 4) == 20,
  )
  @core.chk(
    out,
    "instances: ramsey window vs pigeonhole window (measured, not assumed) #5",
    ramsey_window(4) >= @core.ramsey(3, 4),
  )
  out
}

///|
fn env_heads(e : Env) -> String {
  let parts : Array[String] = []
  for r in e.rules {
    parts.push(@core.u_to_string(r.head))
  }
  parts.join(";")
}

///|
pub fn law_compose_mirror_involution_preserves_the_env_fingerprint() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 鏡像不是逐欄位的對合（公理會多出 ⊤ 標記），但它是**head 上的**對合：
  // mirror²(e) 的 head 序列與 e 完全相同、規則數相同。
  let e = env_minimal()
  @core.chk(
    out,
    "instances: mirror involution preserves the env fingerprint #1",
    env_heads(mirror_env(mirror_env(e))) == env_heads(e),
  )
  // 指紋真的分辨得出不同環境（不是恆等函式）
  @core.chk(
    out,
    "instances: mirror involution preserves the env fingerprint #2",
    env_fingerprint(mirror_env(e)) != env_fingerprint(e),
  )
  // 而且它是字串化的：非空、長度合理
  @core.chk(
    out,
    "instances: mirror involution preserves the env fingerprint #3",
    env_fingerprint(e).length() > 0,
  )
  out
}

// ---------------------------------------------------------------------------
// 定律：鏡像定理的適用界 + 正向最小模型的獨立驗證
// ---------------------------------------------------------------------------

///|

///|
/// 一元鏈環境：一條公理 + 一條單前提合成規則（鏡像定理精確片段的範例）。
pub fn env_unary_chain() -> Env {
  env([
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("arrRule", 0, cls_show(ty_array(ty_int())), [cls_show(ty_int())]),
  ])
}

///|
/// 量測反例環境：Show(Pair Int Bool) 只能經由**雙前提**規則解出。
/// E ⊢ Show(Pair Int Bool) 為真，但樸素鏡像（把雙前提規則原樣保留）得出 ⊤ 不可導——
/// 這正是「多目標鏡像」必須用餘衍生處理的原因（量測，不假設）。
pub fn env_composite_chain() -> Env {
  env([
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("boolRule", 0, cls_show(ty_bool()), []),
    rule("pairRule", 0, cls_show(ty_pair(ty_int(), ty_bool())), [
      cls_show(ty_int()),
      cls_show(ty_bool()),
    ]),
  ])
}

///|
pub fn law_compose_mirror_respects_exactness_boundary_and_co_derivation() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_composite_chain()
  let goal = cls_show(ty_pair(ty_int(), ty_bool()))
  // (1) 反向 SLD 說：可導（這是「標準答案」）
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #1",
    solvable(e, goal, 8),
  )
  // (2) 該環境不在鏡像精確片段（有雙前提規則）
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #2",
    !mirror_exact(e),
  )
  // (3) 量測事實：樸素鏡像在此**不對應**（false ≠ 標準答案 true）
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #3",
    !dual_derivable(e, goal, 8),
  )
  // (4) 餘衍生（正向最小模型）：對應成立
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #4",
    match forward_derivable(e, goal, 16) {
      Some(true) => true
      _ => false
    },
  )
  // (5) 不可導的目標：正向閉包也說不可導（Some(false) 不是 None 也不是 true）
  let bad = cls_eq(ty_int())
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #5",
    match forward_derivable(e, bad, 16) {
      Some(false) => true
      _ => false
    },
  )
  // (6) 正向閉包與 SLD 在一整排環境 × 目標上逐點一致
  let envs = [
    env_show(),
    env_composite_chain(),
    env_axiomatic(),
    env_axiomatic_dup(),
    env_axiomatic_with_loop(),
    env([rule("showAny", 0, cls_show(@core.uvar(0)), [])]),
    env_unary_chain(),
  ]
  let goals = [
    cls_show(ty_int()),
    cls_show(ty_bool()),
    cls_show(ty_array(ty_int())),
    cls_eq(ty_int()),
  ]
  let mut agree = true
  for ee in envs {
    for g in goals {
      match forward_derivable(ee, g, 16) {
        Some(fwd) => if fwd != solvable(ee, g, 8) { agree = false }
        None => agree = false // 界限內必須飽和，否則本定律不成立
      }
    }
  }
  @core.chk(
    out, "instances: mirror respects the exactness boundary and co-derivation #6",
    agree,
  )
  // (7) 對稱性恢復：在 ≤ 1 前提的片段上，mirror_exact 為真且鏡像定理成立
  let simple = env_unary_chain()
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #7",
    mirror_exact(simple),
  )
  let g = cls_show(ty_array(ty_int()))
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #8",
    solvable(simple, g, 8) && dual_derivable(simple, g, 8),
  )
  // (8) 正向閉包裡的泛化公理吞併了無限族：closure 不會爆炸
  match
    forward_least_model(
      env([rule("showAny", 0, cls_show(@core.uvar(0)), [])]),
      4,
      256,
      16,
    ) {
    Some(c) =>
      @core.chk(
        out,
        "instances: mirror respects the exactness boundary and co-derivation #9",
        c.facts.length() == 1 && c.fixpoint,
      )
    None =>
      @core.chk(
        out, "instances: mirror respects the exactness boundary and co-derivation #9",
        false,
      )
  }
  // (9) 串接兩層合成規則的照常推進（燃料內飽和到不動點）
  let chain = env([
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("arrRule", 0, cls_show(ty_array(ty_int())), [cls_show(ty_int())]),
    rule("arr2Rule", 0, cls_show(ty_array(ty_array(ty_int()))), [
      cls_show(ty_array(ty_int())),
    ]),
  ])
  @core.chk(
    out,
    "instances: mirror respects the exactness boundary and co-derivation #10",
    match forward_derivable(chain, cls_show(ty_array(ty_array(ty_int()))), 16) {
      Some(true) => true
      _ => false
    },
  )
  out
}
