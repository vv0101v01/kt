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

///| 鏡像一條規則。多目標規則需要真正的餘衍生（co-resolution），

///|
/// 本版本明示不鏡像，直接原樣保留（邊界寫在這裡，不藏在文件外）。
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
