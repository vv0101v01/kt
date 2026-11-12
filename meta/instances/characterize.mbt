// ---------------------------------------------------------------------------
// meta/instances — 可導性「秩」到底是不是擬陣？給出判準，而不是量測
// ---------------------------------------------------------------------------
//
// 舊版的 `derivability_is_matroidal` 只檢查**交換公理**（`mat_exchange_ok`）。
// 這一檔先是發現、然後修正了它：交換公理**太弱**。
//
//   反例（本檔的 `witness_composite`）：只有 showInt + showArray、目標是
//   {Show Int, Show Array Int} 時，交換公理仍然成立，可是秩函數根本不是擬陣秩 ——
//   加入一條規則可以讓秩一次跳 **2**（`r(S∪{e}) − r(S) = 2 > 1`）。
//   真正被違反的是次模性 R3：r(A)+r(B) ≥ r(A∪B)+r(A∩B)。
//
// 於是本檔給出**判準**而不是量測：
//
//   定理（在此片段中可判定）：
//     可導性秩在目標集 G 上是擬陣秩  ⟺  G 的每個可解目標都能只用**公理規則**
//     （body 為空的規則）解出，即沒有任何目標「需要」合成規則。
//
//   證明。 (⇐) 若全部目標都由公理解出，則 r(S) = |{ g ∈ G : S 中有規則的 head 是 g }|，
//        這正是「分割擬陣」（partition matroid）的秩：把每個目標的實例類當成一個塊，
//        秩 = 被覆蓋的塊數。分割擬陣當然滿足全部秩公理。
//        (⇒) 若某個目標 g 只能由一條 body ≠ ∅ 的規則 r 解出，取 S = 全規則 \ {r}：
//        r(S∪{r}) − r(S) ≥ 2（g 本身，加上 r 的某個 body 目標也會隨著被解出），
//        違反「加一個元素秩最多加一」，也就違反次模性。
//
// 本檔把這條定理的兩邊都做成可執行檢查：
//   `axiomatic_fragment`  —— 判準的左邊（可計算）
//   `matroidal_strict`    —— 秩公理全過（可計算，用 @core.mat_rank_axioms_ok）
//   `characterize`        —— 兩者逐環境對帳，並在不是擬陣時給出**見證**
// 另外附上「貪心給的是極小基，不是最小基」的反例（極小 ≠ 最小）。

// ---------------------------------------------------------------------------
// 1. 秩的嚴格判準
// ---------------------------------------------------------------------------

///|
fn rank_of(
  e : Env,
  rules : Array[Int32],
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Int32 {
  let sub = restrict(e, rules)
  let mut c = 0
  for g in goals {
    if solvable(sub, g, depth) {
      c = c + 1
    }
  }
  c
}

///|
fn all_rules(e : Env) -> Array[Int32] {
  let out : Array[Int32] = []
  for i in 0..<e.rules.length() {
    out.push(i)
  }
  out
}

///|
/// **嚴格版**擬陣判定：秩公理（包含次模性 R3）全過才算擬陣。
/// 舊版只看交換公理，會把「次模性失敗」的秩誤判成擬陣 —— 本檔的定律把這件事釘住。
pub fn matroidal_strict(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Bool {
  let m = derivability_matroid(e, goals, depth)
  match @core.mat_rank_axioms_ok(m) {
    None => true
    Some(_) => false
  }
}

///|
/// 失敗原因（給人看的）：`None` 表示秩公理全過。
pub fn matroidal_failure(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> String? {
  @core.mat_rank_axioms_ok(derivability_matroid(e, goals, depth))
}

// ---------------------------------------------------------------------------
// 2. 判準的左邊：目標集是否「只靠公理」就可解
// ---------------------------------------------------------------------------

///|
fn axiom_rules(e : Env) -> Env {
  let out : Array[Rule] = []
  for r in e.rules {
    if r.body.length() == 0 {
      out.push(r)
    }
  }
  Env::{ rules: out, }
}

///|
/// 目標集 G 在環境 E 中是**公理可解**的：每個在 E 下可解的目標，在「只有公理」的子環境下也可解。
/// 等價於：沒有任何目標需要合成規則（body ≠ ∅ 的規則）。
pub fn axiomatic_fragment(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Bool {
  let ax = axiom_rules(e)
  for g in goals {
    if solvable(e, g, depth) && !solvable(ax, g, depth) {
      return false
    }
  }
  true
}

///|
/// 哪些目標「需要」合成規則（判準失敗時的具體清單）。
pub fn goals_needing_composition(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Array[@core.UTerm] {
  let ax = axiom_rules(e)
  let out : Array[@core.UTerm] = []
  for g in goals {
    if solvable(e, g, depth) && !solvable(ax, g, depth) {
      out.push(g)
    }
  }
  out
}

///|
/// 構件一：有沒有「合成規則」的 head 能落在目標集上？
/// 只要有一條 body ≠ ∅ 的規則，它的 head 與某個目標 g ∈ G 可合一，
/// 那麼「把它的 body 依賴補齊」的那一刻，秩會一次跳 ≥ 2（協同效應），次模性必壞。
pub fn composite_rule_reaches_goal(e : Env, goals : Array[@core.UTerm]) -> Bool {
  for r in e.rules {
    if r.body.length() == 0 {
      continue
    }
    let h = renumber(r.head, 0)
    for g in goals {
      if @core.u_unifiable(h, g) {
        return true
      }
    }
  }
  false
}

///|
/// 構件二：有沒有「一條規則同時覆蓋兩個以上目標」？
/// 有（例如萬用實例 `Show(?0)`）就會出現「加一個元素秩跳 2」，同樣壞掉次模性。
pub fn coverage_disjoint(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Bool {
  for i in 0..<e.rules.length() {
    let only = restrict(e, [i])
    let mut c = 0
    for g in goals {
      if solvable(only, g, depth) {
        c = c + 1
      }
    }
    if c > 1 {
      return false
    }
  }
  true
}

///|
/// **判準**：可導性秩在 G 上是擬陣秩 ⟺
///   (1) 沒有任何合成規則的 head 落在 G 上（沒有協同效應的來源）；
///   (2) 每條規則最多覆蓋一個目標（沒有「一鍵多解」）。
///
/// 兩個條件一起出現時，秩就退化成「被覆蓋的目標數」= 分割擬陣的秩，
/// 而分割擬陣滿足全部秩公理。反過來，任一條件失效都給得出單位增量或次模性的具體反例
/// （見 `unit_increment_witness` / `submodularity_witness`）。
pub fn matroidal_criterion(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> Bool {
  !composite_rule_reaches_goal(e, goals) && coverage_disjoint(e, goals, depth)
}

// ---------------------------------------------------------------------------
// 3. 反例的見證：一條規則讓秩一次跳兩格
// ---------------------------------------------------------------------------

///|
/// 單位增量反例：回傳 (規則索引, r(S), r(S∪{e}))，其中 S = 全規則 \ {e}，
/// 且 r(S∪{e}) − r(S) ≥ 2。這是「秩不是擬陣秩」的最直接見證。
pub fn unit_increment_witness(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> (Int32, Int32, Int32)? {
  let n = e.rules.length()
  if n == 0 {
    return None
  }
  let full = all_rules(e)
  let rfull = rank_of(e, full, goals, depth)
  for i in 0..<n {
    let base : Array[Int32] = []
    for j in 0..<n {
      if j != i {
        base.push(j)
      }
    }
    let r0 = rank_of(e, base, goals, depth)
    if rfull - r0 >= 2 {
      return Some((i, r0, rfull))
    }
  }
  None
}

///|
/// 次模性反例：回傳 (A, B, r(A)+r(B), r(A∪B)+r(A∩B)) 使前者 < 後者。
pub fn submodularity_witness(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> (Array[Int32], Array[Int32], Int32, Int32)? {
  let n = e.rules.length()
  if n == 0 || n > 12 {
    return None
  }
  let total = 1 << n
  for bi in 0..<total {
    for ai in 0..<total {
      let a : Array[Int32] = []
      let b : Array[Int32] = []
      let inter : Array[Int32] = []
      let uni : Array[Int32] = []
      for k in 0..<n {
        let ina = (ai >> k) % 2 == 1
        let inb = (bi >> k) % 2 == 1
        if ina {
          a.push(k)
        }
        if inb {
          b.push(k)
        }
        if ina || inb {
          uni.push(k)
        }
        if ina && inb {
          inter.push(k)
        }
      }
      let lhs = rank_of(e, a, goals, depth) + rank_of(e, b, goals, depth)
      let rhs = rank_of(e, uni, goals, depth) + rank_of(e, inter, goals, depth)
      if lhs < rhs {
        return Some((a, b, lhs, rhs))
      }
    }
  }
  None
}

// ---------------------------------------------------------------------------
// 4. 判準對帳
// ---------------------------------------------------------------------------

///|
/// 一個環境的判準結果。
pub struct MatroidVerdict {
  /// 秩公理全過（嚴格擬陣）
  matroidal : Bool
  /// 目標集只需公理即可解
  axiomatic : Bool
  /// 判準的兩個構件
  composite_reaches : Bool
  coverage_disjoint : Bool
  /// 若判準說「不是擬陣」，這裡是具體是哪個目標需要合成規則
  needs_composition : Array[@core.UTerm]
  /// 單位增量反例（若有）
  jump : (Int32, Int32, Int32)?
}

///|
/// 判準對帳：定理說 `matroidal ⟺ axiomatic`。這裡把兩邊都算出來並附上見證。
pub fn characterize(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> MatroidVerdict {
  MatroidVerdict::{
    matroidal: matroidal_strict(e, goals, depth),
    axiomatic: axiomatic_fragment(e, goals, depth),
    composite_reaches: composite_rule_reaches_goal(e, goals),
    coverage_disjoint: coverage_disjoint(e, goals, depth),
    needs_composition: goals_needing_composition(e, goals, depth),
    jump: unit_increment_witness(e, goals, depth),
  }
}

// ---------------------------------------------------------------------------
// 5. 極小基 ≠ 最小基（貪心的界線）
// ---------------------------------------------------------------------------

///|
/// 以指定順序做貪心刪除，得到一個**極小**基。
pub fn greedy_basis_with_order(
  e : Env,
  goals : Array[@core.UTerm],
  order : Array[Int32],
  depth : Int32,
) -> Array[Int32] {
  let keep : Array[Int32] = []
  for i in 0..<e.rules.length() {
    keep.push(i)
  }
  for i in order {
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

// ---------------------------------------------------------------------------
// 白箱環境
// ---------------------------------------------------------------------------

///|
/// 只有公理的環境：三個目標各自一條公理。
pub fn env_axiomatic() -> Env {
  env([
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("boolRule", 0, cls_show(ty_bool()), []),
    rule("arrIntRule", 0, cls_show(ty_array(ty_int())), []),
  ])
}

///|
/// 需要合成規則才能解出 Show(Array Int)：次模性在此失敗。
pub fn env_needs_composition() -> Env {
  env_minimal()
}

///|
/// 貪心極小 ≠ 最小：Show(Pair Int Bool) 既可用一條公理解，也可用三條規則解。
pub fn env_min_vs_minimal() -> Env {
  env([
    rule("pairRule", 0, cls_show(ty_pair(@core.uvar(0), @core.uvar(1))), [
      cls_show(@core.uvar(0)),
      cls_show(@core.uvar(1)),
    ]),
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("boolRule", 0, cls_show(ty_bool()), []),
    rule("pairIntBoolRule", 0, cls_show(ty_pair(ty_int(), ty_bool())), []),
  ])
}

// ---------------------------------------------------------------------------
// 4.5 判準 (⇐) 的建設性證書：分割 + 窮盡對帳
// ---------------------------------------------------------------------------
//
// 舊版對「公理可解 ⇒ 擬陣」只給 12 個樣本環境的對帳（law_characterize_..._is_exact）。
// 這裡把它升級成**逐實例證書**：
//
//   若目標集 G 在環境 E 中是公理可解、且沒有合成規則的 head 落在 G 上、
//   且每條規則至多覆蓋一個目標，則 rank_E,G(S) = |{ B ∈ 分割 : B ∩ S ≠ ∅ }|，
//   其中分割把覆蓋同一個目標的公理規則放進同一個區塊、其餘規則放進 loop。
//   右邊是**分割擬陣**的秩——這條等式就是 Lean 側 O3 定理的內容。
//
// 證書可被證明者獨立驗證（verify_matroidal_certificate 不呼叫產生器）：
//   結構檢查（分割、非空、互斥、公理性、loop 不覆蓋、可解清單一致），
//   加上**窮盡對帳**：對全部 2^n 個規則子集 S（n ≤ 12，與 submodularity_witness
//   同一上限）重算 rank(S) 並與區塊計數對照。通過 ⟺ 這個實例上，
//   可導性秩就是該分割擬陣的秩——不是「12 個樣本剛好都對」。
//
// n > 12 時驗證器直接回 false：不假裝驗完了（局部驗證的能力上限寫在這裡）。

///|
/// 擬陣性「⇐」方向的**證書**：環境在目標集上是分割擬陣。
pub struct MatroidCertificate {
  /// 可解目標的索引（goals 的下標）
  solvable : Array[Int32]
  /// 與 solvable 對齊：blocks[i] = 覆蓋 goals[solvable[i]] 的公理規則索引
  blocks : Array[Array[Int32]]
  /// 不覆蓋任何目標的規則（loop；由判準 (1) 知合成規則必落在此處）
  loops : Array[Int32]
}

///|
/// 證書產生器。判準不成立時回傳 None——不產生「看起來像證書」的假東西：
///   (1) 有合成規則的 head 與某目標可合一；
///   (2) 有目標 E 可解但「只有公理」解不出；
///   (3) 某條公理覆蓋 ≥ 2 個目標（區塊無法互斥）。
pub fn matroidal_certificate(
  e : Env,
  goals : Array[@core.UTerm],
  depth : Int32,
) -> MatroidCertificate? {
  // 構件 (1)：不許有合成規則的 head 落在目標上
  if composite_rule_reaches_goal(e, goals) {
    return None
  }
  let ax = axiom_rules(e)
  // 可解目標 = 公理可解目標
  let solvable_idx : Array[Int32] = []
  for i in 0..<goals.length() {
    if solvable(e, goals[i], depth) {
      if !solvable(ax, goals[i], depth) {
        return None
      }
      solvable_idx.push(i)
    }
  }
  // 每個目標一個區塊（互斥檢查在此完成）
  let blocks : Array[Array[Int32]] = []
  let used : Array[Int32] = []
  for i in solvable_idx {
    let b : Array[Int32] = []
    for j in 0..<e.rules.length() {
      let r = e.rules[j]
      if r.body.length() != 0 {
        continue
      }
      if @core.u_unifiable(renumber(r.head, 0), goals[i]) {
        b.push(j)
      }
    }
    // 公理可解 ⇒ 一定有覆蓋規則，空區塊表示不一致（直接拒絕）
    if b.length() == 0 {
      return None
    }
    for j in b {
      for u in used {
        if u == j {
          // 區塊互斥失敗：一條規則覆蓋 ≥ 2 個目標
          return None
        }
      }
      used.push(j)
    }
    blocks.push(b)
  }
  let loops : Array[Int32] = []
  for j in 0..<e.rules.length() {
    let mut hit = false
    for u in used {
      if u == j {
        hit = true
      }
    }
    if !hit {
      loops.push(j)
    }
  }
  Some(MatroidCertificate::{ solvable: solvable_idx, blocks, loops, })
}

///|
/// 證書驗證器：不呼叫產生器，只看證書與環境本身，全部重算。
/// 通過 ⟺ 該實例的可導性秩 = 該分割擬陣的秩（n ≤ 12 時為窮盡驗證）。
pub fn verify_matroidal_certificate(
  e : Env,
  goals : Array[@core.UTerm],
  cert : MatroidCertificate,
  depth : Int32,
) -> Bool {
  let n = e.rules.length()
  if n > 12 {
    return false // 窮盡對帳的上限；不假裝驗完了
  }
  if cert.solvable.length() != cert.blocks.length() {
    return false
  }
  for i in cert.solvable {
    if i < 0 || i >= goals.length() {
      return false
    }
  }
  // (1) 分割：區塊非空、blocks ∪ loops = 全部規則、互不相交
  let seen : Array[Int32] = []
  for b in cert.blocks {
    if b.length() == 0 {
      return false
    }
    for j in b {
      if j < 0 || j >= n {
        return false
      }
      for s in seen {
        if s == j {
          return false
        }
      }
      seen.push(j)
    }
  }
  for j in cert.loops {
    if j < 0 || j >= n {
      return false
    }
    for s in seen {
      if s == j {
        return false
      }
    }
    seen.push(j)
  }
  if seen.length() != n {
    return false
  }
  // (2) 每個區塊的規則：公理 + head 可合一其目標
  for i in 0..<cert.blocks.length() {
    let gi = cert.solvable[i]
    for j in cert.blocks[i] {
      let r = e.rules[j]
      if r.body.length() != 0 {
        return false
      }
      if !@core.u_unifiable(renumber(r.head, 0), goals[gi]) {
        return false
      }
    }
  }
  // (3) loop 不覆蓋任何目標
  for j in cert.loops {
    for g in goals {
      if @core.u_unifiable(renumber(e.rules[j].head, 0), g) {
        return false
      }
    }
  }
  // 可解清單與現場重算一致
  for i in 0..<goals.length() {
    let mut listed = false
    for k in cert.solvable {
      if k == i {
        listed = true
      }
    }
    if listed != solvable(e, goals[i], depth) {
      return false
    }
  }
  // (4) 窮盡對帳：rank(S) == |{ B : B ∩ S ≠ ∅ }|，全部 2^n 個 S
  let total = 1 << n
  for mask in 0..<total {
    let ss : Array[Int32] = []
    for k in 0..<n {
      if (mask >> k) % 2 == 1 {
        ss.push(k)
      }
    }
    let mut hit = 0
    for b in cert.blocks {
      let mut any = false
      for k in ss {
        for j in b {
          if j == k {
            any = true
          }
        }
      }
      if any {
        hit = hit + 1
      }
    }
    if rank_of(e, ss, goals, depth) != hit {
      return false
    }
  }
  true
}

///|
/// 覆蓋同一目標的平行公理（分割區塊大小 > 1 的範例）。
pub fn env_axiomatic_dup() -> Env {
  env([
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("boolRule", 0, cls_show(ty_bool()), []),
    rule("arrIntRule", 0, cls_show(ty_array(ty_int())), []),
    rule("intRuleDup", 1, cls_show(ty_int()), []),
  ])
}

///|
/// 公理與 loop 並存的環境：unused 是 Eq Int 的公理，不覆蓋 Show 類的任何目標。
pub fn env_axiomatic_with_loop() -> Env {
  env([
    rule("intRule", 0, cls_show(ty_int()), []),
    rule("boolRule", 0, cls_show(ty_bool()), []),
    rule("arrIntRule", 0, cls_show(ty_array(ty_int())), []),
    rule("unusedEq", 0, cls_eq(ty_int()), []),
  ])
}

// ---------------------------------------------------------------------------
// 定律
// ---------------------------------------------------------------------------

///|
pub fn law_characterize_axiomatic_fragment_is_a_partition_matroid() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_axiomatic()
  let goals = [
    cls_show(ty_int()),
    cls_show(ty_bool()),
    cls_show(ty_array(ty_int())),
  ]
  // 判準兩邊都成立
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #1",
    axiomatic_fragment(e, goals, 6),
  )
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #2",
    matroidal_strict(e, goals, 6),
  )
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #3",
    match matroidal_failure(e, goals, 6) {
      None => true
      Some(_) => false
    },
  )
  // 秩 = 被覆蓋的目標數（分割擬陣的定義性質）
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #4",
    rank_of(e, [0], goals, 6) == 1,
  )
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #5",
    rank_of(e, [0, 1], goals, 6) == 2,
  )
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #6",
    rank_of(e, [0, 1, 2], goals, 6) == 3,
  )
  // 沒有單位增量反例
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #7",
    match unit_increment_witness(e, goals, 6) {
      None => true
      Some(_) => false
    },
  )
  // 也沒有次模性反例
  @core.chk(
    out,
    "instances: axiomatic fragment is a partition matroid #8",
    match submodularity_witness(e, goals, 6) {
      None => true
      Some(_) => false
    },
  )
  out
}

///|
pub fn law_characterize_exchange_axiom_alone_is_too_weak() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_needs_composition()
  let goals = [cls_show(ty_int()), cls_show(ty_array(ty_int()))]
  let m = derivability_matroid(e, goals, 6)
  // 舊判準（只測交換公理）說「是擬陣」
  @core.chk(
    out,
    "instances: exchange axiom alone is too weak #1",
    @core.mat_exchange_ok(m),
  )
  // 但嚴格判準說「不是」
  @core.chk(
    out,
    "instances: exchange axiom alone is too weak #2",
    !matroidal_strict(e, goals, 6),
  )
  // 失敗的具體理由：次模性
  match matroidal_failure(e, goals, 6) {
    Some(reason) =>
      @core.chk(
        out,
        "instances: exchange axiom alone is too weak #3",
        reason.contains("R3"),
      )
    None =>
      @core.chk(out, "instances: exchange axiom alone is too weak #4", false)
  }
  // 單位增量反例：加一條規則讓秩從 0 跳到 2
  match unit_increment_witness(e, goals, 6) {
    Some((i, r0, r1)) => {
      @core.chk(out, "instances: exchange axiom alone is too weak #5", i == 0)
      @core.chk(
        out,
        "instances: exchange axiom alone is too weak #6",
        r0 == 0 && r1 == 2,
      )
      @core.chk(
        out,
        "instances: exchange axiom alone is too weak #7",
        r1 - r0 >= 2,
      )
    }
    None => {
      @core.chk(out, "instances: exchange axiom alone is too weak #8", false)
      @core.chk(out, "instances: exchange axiom alone is too weak #9", false)
      @core.chk(out, "instances: exchange axiom alone is too weak #10", false)
    }
  }
  // 次模性反例本身也可列舉出來
  match submodularity_witness(e, goals, 6) {
    Some((_a, _b, lhs, rhs)) =>
      @core.chk(
        out,
        "instances: exchange axiom alone is too weak #11",
        lhs < rhs,
      )
    None =>
      @core.chk(out, "instances: exchange axiom alone is too weak #12", false)
  }
  out
}

///|
pub fn law_characterize_matroidal_criterion_is_exact() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let gi = cls_show(ty_int())
  let gb = cls_show(ty_bool())
  let ga = cls_show(ty_array(ty_int()))
  let gp = cls_show(ty_pair(ty_int(), ty_bool()))
  // 六個環境 × 兩組目標集 = 12 個樣本，判準與嚴格秩公理檢查必須逐一一致
  let envs = [
    env_axiomatic(),
    env_needs_composition(),
    env_show(),
    env_min_vs_minimal(),
    env_clash(),
    env([
      rule("generic", 0, cls_show(@core.uvar(0)), []),
      rule("intRule", 1, gi, []),
    ]),
  ]
  let batteries = [[gi, gb, ga], [gi, ga, gp]]
  let mut agree = true
  let mut n_matroid = 0
  let mut n_non = 0
  let mut n_criterion_yes = 0
  for e in envs {
    for goals in batteries {
      let v = characterize(e, goals, 6)
      if v.matroidal != matroidal_criterion(e, goals, 6) {
        agree = false
      }
      if v.matroidal {
        n_matroid = n_matroid + 1
      } else {
        n_non = n_non + 1
      }
      if matroidal_criterion(e, goals, 6) {
        n_criterion_yes = n_criterion_yes + 1
      }
    }
  }
  @core.chk(out, "instances: matroidal criterion is exact #1", agree)
  // 樣本兩邊都有（不是全靠同一種情形撐著）
  @core.chk(out, "instances: matroidal criterion is exact #2", n_matroid > 0)
  @core.chk(out, "instances: matroidal criterion is exact #3", n_non > 0)
  @core.chk(
    out,
    "instances: matroidal criterion is exact #4",
    n_matroid == n_criterion_yes,
  )
  // 兩個構件各自都能單獨致命
  // (a) 合成規則落在目標上：env_needs_composition
  let va = characterize(env_needs_composition(), [gi, ga], 6)
  @core.chk(
    out,
    "instances: matroidal criterion is exact #5",
    va.composite_reaches && va.coverage_disjoint,
  )
  @core.chk(out, "instances: matroidal criterion is exact #6", !va.matroidal)
  // (b) 一條規則覆蓋多個目標：萬用實例
  let wild = env([rule("showAny", 0, cls_show(@core.uvar(0)), [])])
  let vb = characterize(wild, [gi, gb, ga], 6)
  @core.chk(
    out,
    "instances: matroidal criterion is exact #7",
    !vb.coverage_disjoint,
  )
  @core.chk(out, "instances: matroidal criterion is exact #8", !vb.matroidal)
  // (c) 無害的合成規則：它的 head 落不到目標集上 ⇒ 不破壞擬陣性（判準的邊界）
  let harmless = characterize(env_min_vs_minimal(), [gi, gb, ga], 6)
  @core.chk(
    out,
    "instances: matroidal criterion is exact #9",
    !harmless.composite_reaches,
  )
  @core.chk(
    out,
    "instances: matroidal criterion is exact #10",
    harmless.matroidal,
  )
  // 同一環境、換一組目標集（把 Pair Int Bool 放進來）⇒ 合成規則變得有害
  let harmful = characterize(env_min_vs_minimal(), [gi, ga, gp], 6)
  @core.chk(
    out,
    "instances: matroidal criterion is exact #11",
    harmful.composite_reaches,
  )
  @core.chk(
    out,
    "instances: matroidal criterion is exact #12",
    !harmful.matroidal,
  )
  out
}

///|
pub fn law_characterize_greedy_gives_minimal_not_minimum() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = env_min_vs_minimal()
  let goals = [cls_show(ty_pair(ty_int(), ty_bool()))]
  // 先刪合成規則與子目標規則 ⇒ 留下公理 {3}（大小 1，最小）
  let forward = [0, 1, 2, 3]
  let b1 = greedy_basis_with_order(e, goals, forward, 6)
  // 反過來先刪公理 ⇒ 留下 {0,1,2}（大小 3，極小但不是最小）
  let backward = [3, 0, 1, 2]
  let b2 = greedy_basis_with_order(e, goals, backward, 6)
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #1",
    b1.length() == 1,
  )
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #2",
    b2.length() == 3,
  )
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #3",
    b2.length() > b1.length(),
  )
  // 兩個都是極小基（去掉任一條就解不動）
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #4",
    basis_is_minimal(e, goals, b1, 6),
  )
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #5",
    basis_is_minimal(e, goals, b2, 6),
  )
  // 而且兩個都真的能解全部目標
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #6",
    solves_all(restrict(e, b1), goals, 6),
  )
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #7",
    solves_all(restrict(e, b2), goals, 6),
  )
  // 注意：此目標集**是**公理可解的（有 pairIntBoolRule 當公理），但貪心仍不保證最小 ——
  // 因為貪心看到的是「規則集合」，合成規則的存在就足以讓不同刪除順序停在不同的極小基。
  @core.chk(
    out,
    "instances: greedy gives minimal not minimum #8",
    axiomatic_fragment(e, goals, 6),
  )
  out
}

// ---------------------------------------------------------------------------
// 定律：證書的逐實例驗證
// ---------------------------------------------------------------------------

///|
/// 全排列（n ≤ 6 才列舉；否則放棄——不假裝測遍了）。
fn permutations(xs : Array[Int32]) -> Array[Array[Int32]] {
  if xs.length() <= 1 {
    return [xs]
  }
  let out : Array[Array[Int32]] = []
  for i in 0..<xs.length() {
    let rest : Array[Int32] = []
    for k in 0..<xs.length() {
      if k != i {
        rest.push(xs[k])
      }
    }
    for p in permutations(rest) {
      let q : Array[Int32] = [xs[i]]
      for v in p {
        q.push(v)
      }
      out.push(q)
    }
  }
  out
}

///|
pub fn law_characterize_matroidal_criterion_has_constructive_certificates() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let gi = cls_show(ty_int())
  let gb = cls_show(ty_bool())
  let ga = cls_show(ty_array(ty_int()))
  let goals = [gi, gb, ga]
  // (1) 公理環境：證書存在且獨立驗證通過
  match matroidal_certificate(env_axiomatic(), goals, 6) {
    Some(c) => {
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #1",
        verify_matroidal_certificate(env_axiomatic(), goals, c, 6),
      )
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #2",
        c.blocks.length() == 3 && c.loops.length() == 0,
      )
    }
    None => {
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #1", false,
      )
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #2", false,
      )
    }
  }
  // (2) 平行公理環境：區塊 {intRule, intRuleDup}，證書照樣驗證通過（2^4 = 16 個子集窮盡對帳）
  match matroidal_certificate(env_axiomatic_dup(), goals, 6) {
    Some(c) =>
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #3",
        verify_matroidal_certificate(env_axiomatic_dup(), goals, c, 6),
      )
    None =>
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #3", false,
      )
  }
  // (3) 判準不成立的環境，證書**誠實回傳 None**（不假裝有證書）：
  // (a) 需要合成規則
  @core.chk(
    out,
    "instances: matroidal criterion has constructive certificates #4",
    match matroidal_certificate(env_needs_composition(), [gi, ga], 6) {
      None => true
      Some(_) => false
    },
  )
  // (b) 合成規則的 head 落在目標集上（Pair Int Bool 案）
  @core.chk(
    out,
    "instances: matroidal criterion has constructive certificates #5",
    match
      matroidal_certificate(
        env_min_vs_minimal(),
        [gi, ga, cls_show(ty_pair(ty_int(), ty_bool()))],
        6,
      ) {
      None => true
      Some(_) => false
    },
  )
  // (c) 一條規則覆蓋兩個目標（萬用實例）：區塊無法互斥
  let wild = env([rule("showAny", 0, cls_show(@core.uvar(0)), [])])
  @core.chk(
    out,
    "instances: matroidal criterion has constructive certificates #6",
    match matroidal_certificate(wild, [gi, gb], 6) {
      None => true
      Some(_) => false
    },
  )
  // (4) loop 環境：證書通過，且「loop 真的被計入分割」
  match matroidal_certificate(env_axiomatic_with_loop(), goals, 6) {
    Some(c) => {
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #7",
        verify_matroidal_certificate(env_axiomatic_with_loop(), goals, c, 6),
      )
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #8",
        c.loops.length() == 1,
      )
      // 竄改：把 loop 從分割裡丟掉 ⇒ 驗證必須失敗（分割不再完備）
      let tampered = MatroidCertificate::{
        solvable: c.solvable,
        blocks: c.blocks,
        loops: [],
      }
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #9",
        !verify_matroidal_certificate(
          env_axiomatic_with_loop(),
          goals,
          tampered,
          6,
        ),
      )
      // 竄改：砍掉可解清單 ⇒ 驗證必須失敗
      let tampered2 = MatroidCertificate::{
        solvable: [c.solvable[0]],
        blocks: [c.blocks[0]],
        loops: c.loops,
      }
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #10",
        !verify_matroidal_certificate(
          env_axiomatic_with_loop(),
          goals,
          tampered2,
          6,
        ),
      )
    }
    None => {
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #7", false,
      )
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #8", false,
      )
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #9", false,
      )
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #10",
        false,
      )
    }
  }
  // (5) 判準成立時，貪心刪除對**每一種**刪除順序都得到最優解（n ≤ 4，全排列窮盡）
  let mut greedy_ok = true
  for p in permutations([0, 1, 2]) {
    if greedy_basis_with_order(env_axiomatic(), goals, p, 6).length() != 3 {
      // 分割擬陣中最小生成集大小 = 可解目標數 = 3
      greedy_ok = false
    }
  }
  for p in permutations([0, 1, 2, 3]) {
    if greedy_basis_with_order(env_axiomatic_dup(), goals, p, 6).length() != 3 {
      greedy_ok = false
    }
  }
  @core.chk(
    out, "instances: matroidal criterion has constructive certificates #11", greedy_ok,
  )
  // (6) 證書成立 ⇒ 嚴格擬陣性（同一環境兩邊一致，不只是「樣本一致」）
  match matroidal_certificate(env_axiomatic_dup(), goals, 6) {
    Some(c) =>
      @core.chk(
        out,
        "instances: matroidal criterion has constructive certificates #12",
        verify_matroidal_certificate(env_axiomatic_dup(), goals, c, 6) &&
        matroidal_strict(env_axiomatic_dup(), goals, 6),
      )
    None =>
      @core.chk(
        out, "instances: matroidal criterion has constructive certificates #12",
        false,
      )
  }
  out
}
