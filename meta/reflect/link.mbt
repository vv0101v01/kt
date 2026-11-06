// ---------------------------------------------------------------------------
// meta/reflect — 聯動：把「實例推導」反射成可獨立複驗的憑證
// ---------------------------------------------------------------------------
//
// meta/instances 的解析器會**搜尋**；搜尋器的輸出不可信（可能有 bug）。
// 所以這裡把搜尋結果「反射」成一份不含搜尋的物件：
//     ProofNode = （目標, 用了哪條規則, 每個子目標的 ProofNode）
// 檢查器只做局部工作：
//   * 目標與規則頭可合一（一次合一，不搜尋）；
//   * 規則 body 被這次合一實例化後，逐個與子節點的目標 α-等價；
//   * 遞迴檢查子節點。
// 這就是「信任邊界」的分割：快的一方（搜尋）不必被信任，慢的一方（檢查）不必聰明。

///|
/// 一份實例證明憑證。
pub(all) struct ProofNode {
  goal : @core.UTerm
  rule : Int32
  kids : Array[ProofNode]
}

///|
fn to_node(d : @instances.Deriv) -> ProofNode {
  let kids : Array[ProofNode] = []
  for k in d.kids {
    kids.push(to_node(k))
  }
  ProofNode::{ goal: d.goal, rule: d.rule, kids, }
}

///|
/// 反射：從搜尋器的輸出產生憑證（取典範推導）。
pub fn prove_instance(
  e : @instances.Env,
  goal : @core.UTerm,
  depth : Int32,
) -> ProofNode? {
  let ds = @instances.resolve_all(e, goal, depth)
  match @instances.canonical(ds, e) {
    Some(d) => Some(to_node(d))
    None => None
  }
}

///|
/// 新變數基準：取所有變數編號之上的安全偏移，避免與目標變數串味。
fn fresh_base(t : @core.UTerm) -> Int32 {
  let vs = @core.u_vars(t)
  let mut mx = 0
  for v in vs {
    if v > mx {
      mx = v
    }
  }
  mx + 10000
}

///|
/// 獨立檢查器：不搜尋、不猜，只做局部合一與比對。
pub fn check_instance_proof(e : @instances.Env, node : ProofNode) -> Bool {
  if node.rule < 0 || node.rule >= e.rules.length() {
    return false
  }
  let r = e.rules[node.rule]
  let base = fresh_base(node.goal)
  let head = @instances.renumber(r.head, base)
  let sub : Array[@core.UTerm?] = []
  if !@core.u_unify(sub, head, node.goal) {
    return false
  }
  if node.kids.length() != r.body.length() {
    return false
  }
  for i in 0..<r.body.length() {
    let want = @core.u_apply(sub, @instances.renumber(r.body[i], base))
    if !@core.u_variant_eq(want, node.kids[i].goal) {
      return false
    }
    if !check_instance_proof(e, node.kids[i]) {
      return false
    }
  }
  true
}

///|
/// 憑證深度（報告用）。
pub fn proof_depth(n : ProofNode) -> Int32 {
  let mut best = 0
  for k in n.kids {
    let d = proof_depth(k)
    if d > best {
      best = d
    }
  }
  best + 1
}

///|
/// 憑證轉字串（報告用）。
pub fn proof_to_string(e : @instances.Env, n : ProofNode) -> String {
  let mut head = "?"
  if n.rule >= 0 && n.rule < e.rules.length() {
    head = e.rules[n.rule].name
  }
  if n.kids.length() == 0 {
    head
  } else {
    let parts : Array[String] = []
    for k in n.kids {
      parts.push(proof_to_string(e, k))
    }
    "\{head}(\{parts.join(", ")})"
  }
}

///|
pub fn law_link_link_instance_proofs_are_checkable_without_search() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let e = @instances.env_show()
  let goal = @instances.cls_show(@instances.ty_array(@instances.ty_int()))
  match prove_instance(e, goal, 8) {
    Some(cert) => {
      @core.chk(
        out,
        "link: instance proofs are checkable without search #1",
        check_instance_proof(e, cert),
      )
      @core.chk(
        out,
        "link: instance proofs are checkable without search #2",
        proof_depth(cert) == 2,
      )
      @core.chk(
        out,
        "link: instance proofs are checkable without search #3",
        proof_to_string(e, cert) == "showArray(showInt)",
      )
    }
    None =>
      @core.chk(
        out, "link: instance proofs are checkable without search #4", false,
      )
  }
  // 巢狀目標
  let goal2 = @instances.cls_show(
    @instances.ty_pair(
      @instances.ty_int(),
      @instances.ty_array(@instances.ty_bool()),
    ),
  )
  match prove_instance(e, goal2, 8) {
    Some(cert) => {
      @core.chk(
        out,
        "link: instance proofs are checkable without search #5",
        check_instance_proof(e, cert),
      )
      @core.chk(
        out,
        "link: instance proofs are checkable without search #6",
        proof_depth(cert) == 3,
      )
    }
    None =>
      @core.chk(
        out, "link: instance proofs are checkable without search #7", false,
      )
  }
  // 無解的目標：沒有憑證
  match prove_instance(e, @instances.cls_eq(@instances.ty_int()), 8) {
    Some(_) =>
      @core.chk(
        out, "link: instance proofs are checkable without search #8", false,
      )
    None =>
      @core.chk(
        out, "link: instance proofs are checkable without search #9", true,
      )
  }
  // 篡改：把根節點的規則換成不相容的一條，檢查器必須拒絕
  match prove_instance(e, goal, 8) {
    Some(cert) => {
      let tampered = ProofNode::{ goal: cert.goal, rule: 3, kids: cert.kids, }
      // rule 3 是 showPair，頭與 Show(Array Int) 不可合一
      @core.chk(
        out,
        "link: instance proofs are checkable without search #10",
        !check_instance_proof(e, tampered),
      )
      // 篡改子節點：換成不相容的規則
      if cert.kids.length() == 1 {
        let kid = cert.kids[0]
        let bad_kid = ProofNode::{ goal: kid.goal, rule: 3, kids: [], }
        let tampered2 = ProofNode::{
          goal: cert.goal,
          rule: cert.rule,
          kids: [bad_kid],
        }
        @core.chk(
          out,
          "link: instance proofs are checkable without search #11",
          !check_instance_proof(e, tampered2),
        )
      } else {
        @core.chk(
          out, "link: instance proofs are checkable without search #12", false,
        )
      }
    }
    None =>
      @core.chk(
        out, "link: instance proofs are checkable without search #13", false,
      )
  }
  out
}
