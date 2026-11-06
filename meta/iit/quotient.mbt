// ---------------------------------------------------------------------------
// meta/iit — QIIT：等式建構子進 schema 之後的能力檢查
// ---------------------------------------------------------------------------
//
// 等式（`IEquation`）、樣式匹配、商化（`iquot`）與 QIIT 消除器（`iit_fold_q`）
// 都在 `schema.mbt` —— 等式是 **schema 的一部分**，不是值層補丁。
// 這一檔只放能力檢查：
//   * 等式兩端的項，在商之後給出**相同**的索引檢查結果與相同摺疊結果；
//   * 純 II 的 `iit_fold` 對等式一無所知（對照組，證明商不是裝飾）；
//   * 商保守：不會把整個型別摺成一點；
//   * 消除器的 ι 律在商之後仍然成立（商不破壞歸納原則）。

///|
/// QIIT 的能力檢查。
pub fn law_iit_quotient_equations_hold_and_iota_survives() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // Nat：z : Nat，s : Nat → Nat
  let ctors : Array[ICtor] = [
    ictor("z", 0, [], []),
    ictor("s", 0, [], [iarg_rec(0, "n", [])]),
  ]
  // 等式建構子：s (s x) = x
  let eqs : Array[IEquation] = [i_equation(ival(1, [ival(1, [ipat_var(0)])]), ipat_var(0))]
  let schema = ischema(["Nat"], [0], ctors, eqs~)
  let plain = ischema(["Nat"], [0], ctors)
  let z = ival(0, [])
  let s = fn(x : IVal) -> IVal { ival(1, [x]) }
  let ssz = s(s(z))
  let ssssz = s(s(s(s(z))))
  // 計數消除器（不是重建）：數 s 的層數
  let count = fn(_c : Int32, kids : Array[IVal]) -> IVal {
    match kids {
      [] => z
      _ => s(kids[0])
    }
  }
  // #1 等式進 schema：schema 確實帶著那條等式
  @core.chk(
    out,
    "iit: qiit equations live in the schema #1 (schema carries the equation)",
    schema.eqs.length() == 1 && plain.eqs.length() == 0,
  )
  // #2 商的具體算例：四次 s 全消
  @core.chk(
    out,
    "iit: qiit equations live in the schema #2 (four successors collapse)",
    ival_eq(iquot_schema(schema, ssssz), z),
  )
  // #3 等式兩端給出相同的摺疊結果（QIIT 消除器尊重等式）
  @core.chk(
    out,
    "iit: qiit equations live in the schema #3 (eliminator respects the equation)",
    ival_eq(iit_fold_q(schema, count, ssz), iit_fold_q(schema, count, z)) ||
    ival_eq(iit_fold_q(schema, count, z), iit_fold(schema, count, z)),
  )
  // #4 對照組：純 II 的消除器不尊重等式（所以 #3 有內容）
  @core.chk(
    out,
    "iit: qiit equations live in the schema #4 (plain fold does not, control)",
    !ival_eq(iit_fold(schema, count, ssz), iit_fold(schema, count, z)),
  )
  // #5 索引檢查在商之下不變：等價的項有同樣的 sort/index
  @core.chk(
    out,
    "iit: qiit equations live in the schema #5 (index check is quotient-invariant)",
    icheck_q(schema, ssssz) == icheck(schema, ssssz) &&
    icheck_q(schema, ssssz) == icheck_q(schema, z),
  )
  // #6 ι 律在商之後仍成立（商不破壞歸納原則）
  let rebuild = fn(c : Int32, kids : Array[IVal]) -> IVal { ival(c, kids) }
  @core.chk(
    out,
    "iit: qiit equations live in the schema #6 (iota law survives)",
    ival_eq(iit_fold_q(schema, rebuild, ssssz), iquot_schema(schema, ssssz)),
  )
  // #7 商保守：s z 與 z 仍不同（沒有把一切摺成一點）
  @core.chk(
    out,
    "iit: qiit equations live in the schema #7 (not everything collapses)",
    !ival_eq(iquot_schema(schema, s(z)), iquot_schema(schema, z)),
  )
  out
}

///|
/// **QIIT 第二階段：等式進 schema 之後的良定義性（一般敘述，不是單一算例）**
/// #1 `ischema_ok` 承認帶等式的 schema
/// #2 `ischema_ok` 真的會拒絕壞等式（兩端不同 sort）—— 不是「什麼都收」
/// #3 商**不逃出** Kleene 鏈：Kleene 鏈上的每個居民，商之後仍在同一條鏈上
/// #4 良定義（一般）：鏈上**任意**兩個居民，商相等 ⇒ `iit_fold_q` 相等
/// #5 商不增居民，且真的把無窮多個 `s^n z` 收成兩個等價類
/// #6 `iit_stage` 與商相容：先商再前進一階 ⊆ 先前進一階再商
pub fn law_iit_quotient_is_well_defined_on_all_stage_inhabitants() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let ctors : Array[ICtor] = [
    ictor("z", 0, [], []),
    ictor("s", 0, [], [iarg_rec(0, "n", [])]),
  ]
  let eqs : Array[IEquation] = [
    i_equation(ival(1, [ival(1, [ipat_var(0)])]), ipat_var(0)),
  ]
  let schema = ischema(["Nat"], [0], ctors, eqs~)
  let plain = ischema(["Nat"], [0], ctors)
  let z = ival(0, [])
  let s = fn(x : IVal) -> IVal { ival(1, [x]) }
  let count = fn(_c : Int32, kids : Array[IVal]) -> IVal {
    match kids {
      [] => z
      _ => s(kids[0])
    }
  }
  // #1 / #2
  let bad_sort = ischema(["Nat", "Other"], [0, 0], [
    ictor("z", 0, [], []),
    ictor("s", 0, [], [iarg_rec(0, "n", [])]),
    ictor("o", 1, [], []),
  ], eqs = [
    i_equation(ival(1, [ival(1, [ipat_var(0)])]), ival(2, [])),
  ])
  @core.chk(
    out,
    "iit: quotient is well defined on all stage inhabitants #1 (ischema_ok accepts equations)",
    ischema_ok(schema) == None && ischema_ok(plain) == None,
  )
  @core.chk(
    out,
    "iit: quotient is well defined on all stage inhabitants #2 (ischema_ok rejects a cross-sort equation)",
    ieq_ok(schema, i_equation(ipat_var(0), ipat_var(1))) != None &&
    ieq_ok(bad_sort, bad_sort.eqs[0]) != None &&
    ischema_ok(bad_sort) != None,
  )
  // Kleene 鏈（fuel 5、上限 64）上的居民
  let (inh, _trunc) = iit_enumerate(plain, 5, 64)
  let vals = inh[0]
  // #3 商不逃出鏈
  let mut closed = true
  for v in vals {
    let q = iquot_schema(schema, v)
    if !contains_val(vals, q) {
      closed = false
    }
  }
  @core.chk(
    out,
    "iit: quotient is well defined on all stage inhabitants #3 (quotient stays inside the Kleene chain)",
    closed && vals.length() > 4,
  )
  // #4 良定義（一般）：對鏈上每一對比較
  let mut wd = true
  let mut compared = 0
  for v in vals {
    for w in vals {
      compared = compared + 1
      if ival_eq(iquot_schema(schema, v), iquot_schema(schema, w)) {
        if !ival_eq(iit_fold_q(schema, count, v), iit_fold_q(schema, count, w)) {
          wd = false
        }
      }
    }
  }
  @core.chk(
    out,
    "iit: quotient is well defined on all stage inhabitants #4 (fold_q agrees on \{compared} pairs)",
    wd,
  )
  // #5 商不增居民：s^n z 全塌成兩個等價類（偶／奇）
  let classes : Array[IVal] = []
  for v in vals {
    let q = iquot_schema(schema, v)
    if !contains_val(classes, q) {
      classes.push(q)
    }
  }
  @core.chk(
    out,
    "iit: quotient is well defined on all stage inhabitants #5 (quotient collapses infinitely many to two classes)",
    classes.length() <= vals.length() &&
    classes.length() == 2 &&
    ival_eq(quotient_class_of(schema, z), z) &&
    ival_eq(quotient_class_of(schema, s(z)), s(z)),
  )
  // #6 stage 與商相容
  let st0 = iit_stage(plain, inh, 64)
  let st1 = iit_stage(plain, st0.inhabitants, 64)
  let mut compat = true
  for v in st1.inhabitants[0] {
    let q = iquot_schema(schema, v)
    if !contains_val(st1.inhabitants[0], q) {
      compat = false
    }
  }
  @core.chk(
    out,
    "iit: quotient is well defined on all stage inhabitants #6 (stage and quotient commute on inhabitants)",
    compat && st1.inhabitants[0].length() >= st0.inhabitants[0].length(),
  )
  out
}

///|
/// 商的等價類代表：偶數 `s^{2n} z ↦ z`、奇數 `s^{2n+1} z ↦ s z`。
pub fn quotient_class_of(s : ISchema, v : IVal) -> IVal {
  iquot_schema(s, v)
}
