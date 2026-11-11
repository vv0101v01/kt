///|
/// cmd/metatheory — 三大主題（反射 / 全域實例 / 歸納-歸納）的定律總表。
///
/// 跑法：
///   moon run cmd/metatheory --target wasm-gc
///
/// 這不是「測試通過」四個字，而是逐一印出**被機器重算的命題**：
/// 每一行都是一個可判定的事實，例如
///   - 1 + ω = ω < ω + 1
///   - R(3,4) = 9（由搜尋算出，不是查表）
///   - 三個覆蓋的 nerve 有 H¹ = ℚ ⇒ 局部解黏不起來
///   - fs(s z, fz z) : Fin (s (s z)) 且 fs(z, fz z) 被拒
///   - decide_eq（NbE）與 check_cert（逐步重放）對同一批樣本給出相同答案
fn main {
  let all : Array[(String, Bool)] = []
  collect(all, @core.all_laws())
  collect(all, @instances.all_laws())
  collect(all, @iit.all_laws())
  collect(all, @reflect.all_laws())
  let mut pass = 0
  let mut fail = 0
  println("=== meta/metatheory — 定律總表 ===")
  println("")
  for i in 0..<all.length() {
    let (label, ok) = all[i]
    if ok {
      pass = pass + 1
    } else {
      fail = fail + 1
    }
    let mark = if ok { "ok  " } else { "FAIL" }
    println("\{mark} [\{pad(i + 1, 3)}] \{label}")
  }
  println("")
  println(
    "--- 三大主題的最小見證（重新計算，不是引用） ---",
  )
  println(demo_ordinal())
  println(demo_ramsey())
  println(demo_stlc())
  println(demo_gluing())
  println(demo_iit())
  println(demo_reflection())
  println("")
  println("通過 \{pass} / \{pass + fail} 定律")
  if fail > 0 {
    abort("metatheory laws failed")
  }
}

///|
fn collect(dst : Array[(String, Bool)], src : Array[(String, Bool)]) -> Unit {
  for x in src {
    dst.push(x)
  }
}

///|
fn pad(n : Int32, w : Int32) -> String {
  let s = "\{n}"
  let mut out = s
  while out.length() < w {
    out = " " + out
  }
  out
}

// ---------------------------------------------------------------------------
// 五個最小見證：把「定理」印成人看得懂的一行
// ---------------------------------------------------------------------------

///|
fn demo_ordinal() -> String {
  let w = @core.ord_omega_pow(@core.ord_one())
  let a = @core.ord_add(@core.ord_one(), w)
  let b = @core.ord_add(w, @core.ord_one())
  "序數：1 + ω = \{@core.ord_to_string(a)}  <  ω + 1 = \{@core.ord_to_string(b)}  （吸收律，非交換）"
}

///|
fn demo_ramsey() -> String {
  let r33 = @core.ramsey(3, 3)
  let r34 = @core.ramsey(3, 4)
  let p44 = @core.ramsey_pin(4, 4)
  let p35 = @core.ramsey_pin(3, 5)
  "Ramsey：R(3,3) = \{r33}，R(3,4) = \{r34}（搜尋算出）；R(4,4) = \{p44.upper}（Paley 圖 P₁₇ 的 \{p44.witness.length()} 條紅邊給下界 + 遞迴上界 9+9 給上界，兩邊夾死）；R(3,5) = \{p35.upper}（K₁₃ 見證）；R(4,5) ≥ 25（McKay–Radziszowski 目錄第一張 (4,5,24)-graph，124 條邊，機器複驗無 K₄ 無獨立 5-集）；Erdős–Szekeres 的 C(6,3) = \{@core.erdos_szekeres(4, 4)} 已被嚴格優於"
}

///|
fn demo_stlc() -> String {
  let s = @iit.schema_stlc()
  let t = @iit.stlc_ex_app2()
  let r = match @iit.stlc_beta(t) {
    Some(x) => x
    None => t
  }
  let t2 = @iit.stlc_ex_sn_two_positions()
  let n_reducts = @iit.stlc_one_step_reducts(t2).length()
  let d_kid = match @iit.stlc_sn_depth(@iit.stlc_ex_k_app(), 1024) {
    Some(d) => "\{d}"
    None => "None"
  }
  "歸納-歸納的 STLC：β 約簡 (λx.λy.x) arg ↝ 仍良構 = \{@iit.icheck(s, r)}，且索引（上下文, 型別）完全不變 = \{@iit.stlc_same_index(s, t, r)}（走入一層 binder 時的索引傳輸是重算出來的）\nSTLC 逐項 SN 證書（窮舉 β∪η 歸約樹，**不是**全稱定理）：two_positions 一步歸約數 = \{n_reducts}，k_app 深度 = \{d_kid}"
}

///|
fn demo_gluing() -> String {
  let good : Array[Array[Int32]] = [[0, 1], [1, 2]]
  let bad : Array[Array[Int32]] = [[0, 1], [1, 2], [2, 0]]
  "併攏：可縮覆蓋 H¹ = 0 ⇒ 黏合 \{if @core.cover_glues(good) { "成功" } else { "失敗" }}；圈狀覆蓋 H¹ = ℚ ⇒ 黏合 \{if @core.cover_glues(bad) { "成功" } else { "失敗" }}（障礙是三元組）"
}

///|
fn demo_iit() -> String {
  let s = @iit.schema_nat_fin()
  let (fam, _t) = @iit.iit_enumerate(s, 4, 256)
  "歸納-歸納：4 階 Kleene 鏈後 Nat 有 \{fam[0].length()} 個居民、Fin 有 \{fam[1].length()} 個；Fin 的索引是項（例：fz(z) : Fin (s z)），索引檢查逐個通過"
}

///|
fn demo_reflection() -> String {
  let b0 = @reflect.TBase(0)
  let idt = @reflect.TLam(b0, @reflect.TVar(0))
  let some = @reflect.TApp(idt, @reflect.TStar)
  let d = @reflect.decide_eq(b0, some, @reflect.TStar)
  let checked = match @reflect.prove_eq(b0, some, @reflect.TStar) {
    Some(c) => @reflect.check_cert(some, @reflect.TStar, c)
    None => false
  }
  "反射：NbE 判定 (\\x.x) * = * 為 \{d}；同一件事的**逐步憑證**獨立重放為 \{checked}（兩個判斷來自不同程式路徑）"
}
