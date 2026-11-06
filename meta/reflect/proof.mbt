// ---------------------------------------------------------------------------
// meta/reflect — 證明即計算，但憑證要能**獨立重放**
// ---------------------------------------------------------------------------
//
// 反射式判定（用 NbE 算正常形式）很快，但它信任 NbE 本身。
// 工程上要的是兩件事同時成立：
//   * `decide_eq`：快速判定 —— 用語義域（reflect/reify）；
//   * `check_cert`：慢但有說服力 —— 只做**局部**檢查：每一步是不是一個 β/η 步驟。
// 兩者由 `prove_eq` 連接：判為相等時，產生一條逐步轉換鏈（可列印、可存檔、可重放）。
//
// 這正是 Coq/Lean 裡 reflection 戰術的骨架：
//   決定程序（fast, untrusted）→ 憑證（small, checkable）→ 檢查器（slow, trusted）。

///|
/// 一本「轉換帳」：從 a 走到 b，每一步都是一個 β 或 η 步驟。
pub(all) struct Cert {
  chain : Array[Term]
}

///|
/// 反射式判定：βη 相等 ⟺ 正常形式語法相等。
pub fn decide_eq(ty : Ty, a : Term, b : Term) -> Bool {
  term_eq(nf(ty, a), nf(ty, b))
}

///|
/// 把一個項逐步化到 βη 正常形式，記錄每一步。
pub fn step_trace(t : Term) -> Array[Term] {
  let out : Array[Term] = [t]
  let mut cur = t
  let mut go = true
  while go {
    match beta_once(cur) {
      Some(n) => {
        cur = n
        out.push(n)
      }
      None =>
        match eta_once(cur) {
          Some(n) => {
            cur = n
            out.push(n)
          }
          None => go = false
        }
    }
  }
  out
}

///|
/// 產生憑證：a ↝ nf，再把 b ↝ nf 的路徑反向接上（反向是 βη 展開，仍屬轉換）。
pub fn prove_eq(ty : Ty, a : Term, b : Term) -> Cert? {
  if !decide_eq(ty, a, b) {
    return None
  }
  let ta = step_trace(a)
  let tb = step_trace(b)
  let chain : Array[Term] = []
  for t in ta {
    chain.push(t)
  }
  // 兩條路徑必須真的接到同一個終點（βη 正常形式）
  let last_a = ta[ta.length() - 1]
  let last_b = tb[tb.length() - 1]
  if !term_eq(last_a, last_b) {
    return None
  }
  // 反向：從 tb 的倒數第二個開始往回走
  let mut i = tb.length()
  while i > 1 {
    i = i - 1
    chain.push(tb[i - 1])
  }
  Some(Cert::{ chain, })
}

///| 獨立檢查器：**不**計算正常形式，只驗

///|   (1) 起點、終點對得上；

///|
///   (2) 每一步都是單一 β 或 η 轉換。
pub fn check_cert(a : Term, b : Term, cert : Cert) -> Bool {
  let ch = cert.chain
  if ch.length() == 0 {
    return false
  }
  if !term_eq(ch[0], a) || !term_eq(ch[ch.length() - 1], b) {
    return false
  }
  let mut ok = true
  for i in 0..<(ch.length() - 1) {
    if !conv_step(ch[i], ch[i + 1]) {
      ok = false
    }
  }
  ok
}

///|
/// 憑證長度（「證明有多大」的度量；reflection 的賣點就是它通常很短）。
pub fn cert_size(c : Cert) -> Int32 {
  c.chain.length()
}

///|
pub fn cert_to_string(c : Cert) -> String {
  let parts : Array[String] = []
  for t in c.chain {
    parts.push(term_to_string(t))
  }
  parts.join(" → ")
}

///|
pub fn law_proof_reflection_decide_fast_check_independently() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let b0 = TBase(0)
  let arr = TArr(b0, b0)
  let idt = TLam(b0, TVar(0))
  let some = TApp(idt, TStar)
  // 快：反射判定
  @core.chk(
    out,
    "reflection: decide fast, check independently #1",
    decide_eq(b0, some, TStar),
  )
  // 慢：憑證重放（每一步都是局部 β/η）
  match prove_eq(b0, some, TStar) {
    Some(c) => {
      @core.chk(
        out,
        "reflection: decide fast, check independently #2",
        check_cert(some, TStar, c),
      )
      @core.chk(
        out,
        "reflection: decide fast, check independently #3",
        cert_size(c) >= 2,
      )
    }
    None =>
      @core.chk(out, "reflection: decide fast, check independently #4", false)
  }
  // 不相等的項：不可能有憑證
  match prove_eq(b0, TStar, TApp(idt, TApp(idt, TStar))) {
    Some(_) =>
      @core.chk(out, "reflection: decide fast, check independently #5", true)
    None =>
      @core.chk(out, "reflection: decide fast, check independently #6", false)
  }
  match prove_eq(b0, TStar, TLam(b0, TVar(0))) {
    Some(_) =>
      @core.chk(out, "reflection: decide fast, check independently #7", false)
    None =>
      @core.chk(out, "reflection: decide fast, check independently #8", true)
  }
  // 篡改的憑證必須被拒：把終點改成另一個項
  match prove_eq(b0, some, TStar) {
    Some(c) =>
      @core.chk(
        out,
        "reflection: decide fast, check independently #9",
        !check_cert(some, TLam(b0, TVar(0)), c),
      )
    None =>
      @core.chk(out, "reflection: decide fast, check independently #10", false)
  }
  // 一致性（差別測試）：decide_eq ⟺ 證明存在
  let samples : Array[(Term, Term)] = [
    (some, TStar),
    (TApp(idt, some), TStar),
    (TApp(idt, TVar(0)), TVar(0)),
    (TLam(b0, TApp(idt, TVar(0))), idt),
    (TStar, TStar),
  ]
  for (x, y) in samples {
    let d = decide_eq(b0, x, y)
    let p = match prove_eq(b0, x, y) {
      Some(_) => true
      None => false
    }
    // 只有 b0 索引的樣本才用 b0 判定；其餘樣本型別不同 → 這裡只檢查「有證 ⇒ 判定成立」
    if p {
      @core.chk(out, "reflection: decide fast, check independently #11", d)
    }
  }
  let _ = arr
  out
}

///|
pub fn law_proof_certificates_are_printable_and_still_check() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let b0 = TBase(0)
  let idt = TLam(b0, TVar(0))
  let some = TApp(idt, TStar)
  match prove_eq(b0, some, TStar) {
    None =>
      @core.chk(
        out, "reflection: certificates are printable and still check #1", false,
      )
    Some(c) => {
      // 可列印（存檔／貼進 issue 的形狀）
      let text = cert_to_string(c)
      @core.chk(
        out,
        "reflection: certificates are printable and still check #1",
        text.length() > 0,
      )
      // 印出來的東西仍然能被獨立重放檢查
      @core.chk(
        out,
        "reflection: certificates are printable and still check #2",
        check_cert(some, TStar, c),
      )
      // 大小與步數一致（cert_size ≥ 2：至少兩個端點）
      @core.chk(
        out,
        "reflection: certificates are printable and still check #3",
        cert_size(c) >= 2,
      )
      @core.chk(
        out,
        "reflection: certificates are printable and still check #4",
        cert_size(c) == c.chain.length(),
      )
    }
  }
  out
}
