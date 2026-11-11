// ---------------------------------------------------------------------------
// ualg/core — 有限泛代數：簽名、運算表、項、子代數、直積、同態、自由代數
// ---------------------------------------------------------------------------
//
// [D-Alg]   代數 A = (A; f_1..f_k)：載體 {0..n-1}，每個 f 是 A^r → A 的全函數表。
// [D-Term]  項 = 變元 | f(t_1..t_r)；項運算 t^A 由 `term_eval` 給出。
// [D-Sg]    Sg(X) = 含 X 的最小子全域；`sg` 用工作表閉包，每個元素只展開一次。
// [T-Birk]  Birkhoff：V(A) 的 k 元自由代數 = A^(A^k) 中由 k 個投影生成的子代數
//           （`free_algebra`）；元素就是 k 元項運算，所以「項的等價」可判定。
// 邊界：元數 ≤ 3（`alg_ok` 會拒絕更高元數），載體大小受 n^r 表格限制。

///|
/// 運算表以小端 n 進位展開引數：f(a_0,…,a_{r-1}) = table[Σ a_k·n^k]。
pub(all) struct Op {
  name : String
  arity : Int32
  table : Array[Int32]
}

///|
pub(all) struct Alg {
  name : String
  n : Int32
  ops : Array[Op]
}

///|
pub(all) enum Term {
  TVar(Int32)
  TApp(Int32, Array[Term])
}

///|
pub fn ipow(b : Int32, e : Int32) -> Int32 {
  let mut r = 1
  for _ in 0..<e {
    r = r * b
  }
  r
}

///|
pub fn show_ints(xs : Array[Int32]) -> String {
  let sb = StringBuilder()
  sb.write_string("[")
  for i, x in xs {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string(x.to_string())
  }
  sb.write_string("]")
  sb.to_string()
}

///|
pub fn op_const(name : String, c : Int32) -> Op {
  { name, arity: 0, table: [c] }
}

///|
pub fn op_unary(name : String, n : Int32, f : (Int32) -> Int32) -> Op {
  { name, arity: 1, table: Array::makei(n, f) }
}

///|
pub fn op_binary(
  name : String,
  n : Int32,
  f : (Int32, Int32) -> Int32,
) -> Op {
  { name, arity: 2, table: Array::makei(n * n, i => f(i % n, i / n)) }
}

///|
pub fn op_ternary(
  name : String,
  n : Int32,
  f : (Int32, Int32, Int32) -> Int32,
) -> Op {
  {
    name,
    arity: 3,
    table: Array::makei(n * n * n, i => f(i % n, i / n % n, i / (n * n))),
  }
}

///|
pub fn ap2(op : Op, n : Int32, a : Int32, b : Int32) -> Int32 {
  op.table[a + n * b]
}

///|
pub fn ap3(op : Op, n : Int32, a : Int32, b : Int32, c : Int32) -> Int32 {
  op.table[a + n * (b + n * c)]
}

///|
pub fn op_apply(op : Op, n : Int32, args : Array[Int32]) -> Int32 {
  let mut idx = 0
  let mut w = 1
  for a in args {
    idx = idx + a * w
    w = w * n
  }
  op.table[idx]
}

///|
/// 良構性：元數 ≤ 3、表長 = n^r、值域在載體內。
pub fn alg_ok(a : Alg) -> Bool {
  if a.n <= 0 {
    return false
  }
  for op in a.ops {
    if op.arity < 0 || op.arity > 3 {
      return false
    }
    if op.table.length() != ipow(a.n, op.arity) {
      return false
    }
    for v in op.table {
      if v < 0 || v >= a.n {
        return false
      }
    }
  }
  true
}

///|
pub fn term_eval(a : Alg, t : Term, env : Array[Int32]) -> Int32 {
  match t {
    TVar(i) => env[i]
    TApp(k, args) => {
      let vals = args.map(s => term_eval(a, s, env))
      op_apply(a.ops[k], a.n, vals)
    }
  }
}

///|
pub fn term_show(a : Alg, t : Term) -> String {
  match t {
    TVar(i) => "x\{i}"
    TApp(k, args) => {
      let sb = StringBuilder()
      sb.write_string(a.ops[k].name)
      if args.length() > 0 {
        sb.write_string("(")
        for i, s in args {
          if i > 0 {
            sb.write_string(",")
          }
          sb.write_string(term_show(a, s))
        }
        sb.write_string(")")
      }
      sb.to_string()
    }
  }
}

///|
pub fn term_size(t : Term) -> Int32 {
  match t {
    TVar(_) => 1
    TApp(_, args) => {
      let mut s = 1
      for x in args {
        s = s + term_size(x)
      }
      s
    }
  }
}

///|
/// 把 idx 以 n 進位解成 k 位。
pub fn digits(idx : Int32, n : Int32, k : Int32) -> Array[Int32] {
  let out = Array::make(k, 0)
  let mut rest = idx
  for i in 0..<k {
    out[i] = rest % n
    rest = rest / n
  }
  out
}

///|
/// A ⊨ lhs ≈ rhs：窮舉全部 n^nvars 組賦值。
pub fn satisfies(a : Alg, lhs : Term, rhs : Term, nvars : Int32) -> Bool {
  for idx in 0..<ipow(a.n, nvars) {
    let env = digits(idx, a.n, nvars)
    if term_eval(a, lhs, env) != term_eval(a, rhs, env) {
      return false
    }
  }
  true
}

///|
/// [D-Sg] 子全域閉包。每個元素出列時與「已在表中、序號不大於它」的元素配對，
/// 因此每個引數組恰在其最大序號出列時被計算一次。
pub fn sg(a : Alg, gens : Array[Int32]) -> Array[Int32] {
  let n = a.n
  let inside = Array::make(n, false)
  let list : Array[Int32] = []
  fn add(x : Int32) -> Unit {
    if !inside[x] {
      inside[x] = true
      list.push(x)
    }
  }

  for g in gens {
    add(g)
  }
  for op in a.ops {
    if op.arity == 0 {
      add(op.table[0])
    }
  }
  let mut i = 0
  while i < list.length() {
    let x = list[i]
    for op in a.ops {
      if op.arity == 1 {
        add(op.table[x])
      } else if op.arity == 2 {
        for j in 0..<=i {
          let y = list[j]
          add(ap2(op, n, x, y))
          add(ap2(op, n, y, x))
        }
      } else if op.arity == 3 {
        for j in 0..<=i {
          for k in 0..<=i {
            let y = list[j]
            let z = list[k]
            add(ap3(op, n, x, y, z))
            add(ap3(op, n, y, x, z))
            add(ap3(op, n, y, z, x))
          }
        }
      }
    }
    i = i + 1
  }
  list.sort()
  list
}

///|
/// 子全域 S 上的誘導代數；回傳（代數, 原元素 → 新序號，不在 S 內為 -1）。
pub fn subalgebra(a : Alg, elems : Array[Int32]) -> (Alg, Array[Int32]) {
  let m = elems.length()
  let pos = Array::make(a.n, -1)
  for i, e in elems {
    pos[e] = i
  }
  let ops : Array[Op] = []
  for op in a.ops {
    let r = op.arity
    let table = Array::makei(ipow(m, r), idx => {
      let ds = digits(idx, m, r)
      pos[op_apply(op, a.n, ds.map(d => elems[d]))]
    })
    ops.push({ name: op.name, arity: r, table })
  }
  ({ name: "Sub(" + a.name + ")", n: m, ops }, pos)
}

///|
/// 直積 A×B（同型簽名，逐位對應）；(a,b) ↦ a + |A|·b。
pub fn alg_product(a : Alg, b : Alg) -> Alg {
  let n = a.n * b.n
  let ops : Array[Op] = []
  for k in 0..<a.ops.length() {
    let f = a.ops[k]
    let g = b.ops[k]
    let r = f.arity
    let table = Array::makei(ipow(n, r), idx => {
      let ds = digits(idx, n, r)
      let ia = op_apply(f, a.n, ds.map(d => d % a.n))
      let ib = op_apply(g, b.n, ds.map(d => d / a.n))
      ia + a.n * ib
    })
    ops.push({ name: f.name, arity: r, table })
  }
  { name: "(" + a.name + "×" + b.name + ")", n, ops }
}

///|
/// f : A → B 是同態 ⇔ 對每個運算與每組引數 f(op_A(ā)) = op_B(f(ā))。
pub fn is_hom(a : Alg, b : Alg, f : Array[Int32]) -> Bool {
  if a.ops.length() != b.ops.length() {
    return false
  }
  for k in 0..<a.ops.length() {
    let op = a.ops[k]
    let oq = b.ops[k]
    let r = op.arity
    if r != oq.arity {
      return false
    }
    for idx in 0..<op.table.length() {
      let mut rest = idx
      let mut jb = 0
      let mut w = 1
      for _ in 0..<r {
        jb = jb + f[rest % a.n] * w
        rest = rest / a.n
        w = w * b.n
      }
      if f[op.table[idx]] != oq.table[jb] {
        return false
      }
    }
  }
  true
}

// ---------------------------------------------------------------------------
// 冪代數中的閉包（元素是元組）與自由代數
// ---------------------------------------------------------------------------

///|
/// 閉包結果：elems[i] 的來源 origin[i] =（-1,[g]）表示第 g 個生成元，
/// 否則（運算序號, 引數在 elems 中的序號）。hit ≥ 0 表示目標元組的序號。
pub(all) struct Closure {
  elems : Array[Array[Int32]]
  origin : Array[(Int32, Array[Int32])]
  complete : Bool
  hit : Int32
}

///|
pub fn tuple_key(t : Array[Int32]) -> String {
  let sb = StringBuilder()
  for v in t {
    sb.write_string(v.to_string())
    sb.write_string(",")
  }
  sb.to_string()
}

///|
fn pointwise(
  a : Alg,
  op : Op,
  args : Array[Array[Int32]],
  len : Int32,
) -> Array[Int32] {
  let r = op.arity
  Array::makei(len, c => {
    let mut idx = 0
    let mut w = 1
    for k in 0..<r {
      idx = idx + args[k][c] * w
      w = w * a.n
    }
    op.table[idx]
  })
}

///|
/// 在 A^len 中由 gens 生成的子全域。給了 target 就在命中時提前停止；
/// 元素數超過 limit 時停止並回報 complete = false（不假裝算完）。
pub fn close_tuples(
  a : Alg,
  gens : Array[Array[Int32]],
  target : Array[Int32]?,
  limit : Int32,
) -> Closure {
  let elems : Array[Array[Int32]] = []
  let origin : Array[(Int32, Array[Int32])] = []
  let index : Map[String, Int32] = Map([])
  let len = if gens.length() > 0 { gens[0].length() } else { 0 }
  let tkey = match target {
    Some(t) => tuple_key(t)
    None => "?"
  }
  let mut hit = -1
  fn add(t : Array[Int32], org : (Int32, Array[Int32])) -> Unit {
    let key = tuple_key(t)
    if !index.contains(key) {
      if key == tkey {
        hit = elems.length()
      }
      index[key] = elems.length()
      elems.push(t)
      origin.push(org)
    }
  }

  for g, t in gens {
    add(t, (-1, [g]))
  }
  for k, op in a.ops {
    if op.arity == 0 {
      add(Array::make(len, op.table[0]), (k, []))
    }
  }
  let mut i = 0
  while i < elems.length() && hit < 0 && elems.length() <= limit {
    let x = elems[i]
    for k, op in a.ops {
      if op.arity == 1 {
        add(pointwise(a, op, [x], len), (k, [i]))
      } else if op.arity == 2 {
        for j in 0..<=i {
          let y = elems[j]
          add(pointwise(a, op, [x, y], len), (k, [i, j]))
          add(pointwise(a, op, [y, x], len), (k, [j, i]))
        }
      } else if op.arity == 3 {
        for j in 0..<=i {
          for l in 0..<=i {
            let y = elems[j]
            let z = elems[l]
            add(pointwise(a, op, [x, y, z], len), (k, [i, j, l]))
            add(pointwise(a, op, [y, x, z], len), (k, [j, i, l]))
            add(pointwise(a, op, [y, z, x], len), (k, [j, l, i]))
          }
        }
      }
    }
    i = i + 1
  }
  { elems, origin, complete: i == elems.length() && hit < 0, hit }
}

///|
/// [T-Birk] F_{V(A)}(k)：A^(n^k) 中由投影 π_0..π_{k-1} 生成。
pub fn free_algebra(a : Alg, k : Int32, limit : Int32) -> Closure {
  let len = ipow(a.n, k)
  let gens : Array[Array[Int32]] = []
  for j in 0..<k {
    gens.push(Array::makei(len, idx => digits(idx, a.n, k)[j]))
  }
  close_tuples(a, gens, None, limit)
}

///|
/// 把（已算完的）閉包做成表格代數；元素序號即 elems 的序號。
pub fn closure_to_alg(a : Alg, cl : Closure, name : String) -> Alg {
  let m = cl.elems.length()
  let len = if m > 0 { cl.elems[0].length() } else { 0 }
  let index : Map[String, Int32] = Map([])
  for i, t in cl.elems {
    index[tuple_key(t)] = i
  }
  let ops : Array[Op] = []
  for op in a.ops {
    let r = op.arity
    let table = Array::makei(ipow(m, r), idx => {
      let ds = digits(idx, m, r)
      let t = if r == 0 {
        Array::make(len, op.table[0])
      } else {
        pointwise(a, op, ds.map(d => cl.elems[d]), len)
      }
      match index.get(tuple_key(t)) {
        Some(j) => j
        None => -1
      }
    })
    ops.push({ name: op.name, arity: r, table })
  }
  { name, n: m, ops }
}

///|
/// 由來源 DAG 還原第 i 個元素的項（變元 = 生成元序號）。
pub fn closure_term(cl : Closure, i : Int32) -> Term {
  let (k, args) = cl.origin[i]
  if k < 0 {
    TVar(args[0])
  } else {
    TApp(k, args.map(j => closure_term(cl, j)))
  }
}

// ---------------------------------------------------------------------------
// 代數動物園（全部由定義直接生成，不是手抄表）
// ---------------------------------------------------------------------------

///|
/// 循環群 (ℤ_n; +, −, 0)。
pub fn alg_zn(n : Int32) -> Alg {
  {
    name: "Z\{n}",
    n,
    ops: [
      op_binary("+", n, (a, b) => (a + b) % n),
      op_unary("-", n, a => (n - a) % n),
      op_const("0", 0),
    ],
  }
}

///|
/// 乘法么半群 (ℤ_n; ·)。
pub fn alg_zn_mul(n : Int32) -> Alg {
  { name: "(Z\{n},·)", n, ops: [op_binary("·", n, (a, b) => a * b % n)] }
}

///|
/// 仿射 Mal'cev 代數 (ℤ_n; p)，p(x,y,z) = x − y + z（冪等）。
pub fn alg_affine_zn(n : Int32) -> Alg {
  {
    name: "Aff(Z\{n})",
    n,
    ops: [op_ternary("p", n, (x, y, z) => ((x - y + z) % n + n) % n)],
  }
}

///|
let s3_perms : Array[Array[Int32]] = [
  [0, 1, 2],
  [1, 0, 2],
  [0, 2, 1],
  [2, 1, 0],
  [1, 2, 0],
  [2, 0, 1],
]

///|
fn s3_index(p : Array[Int32]) -> Int32 {
  for i, q in s3_perms {
    if q == p {
      return i
    }
  }
  -1
}

///|
/// 對稱群 (S_3; ∘, ⁻¹, e)。
pub fn alg_s3() -> Alg {
  let mul = (a : Int32, b : Int32) => s3_index(
    Array::makei(3, i => s3_perms[a][s3_perms[b][i]]),
  )
  let inv = (a : Int32) => {
    let q = Array::make(3, 0)
    for i in 0..<3 {
      q[s3_perms[a][i]] = i
    }
    s3_index(q)
  }
  {
    name: "S3",
    n: 6,
    ops: [op_binary("∘", 6, mul), op_unary("inv", 6, inv), op_const("e", 0)],
  }
}

///|
/// n 元鏈格 (∧ = min, ∨ = max)。
pub fn alg_chain(n : Int32) -> Alg {
  {
    name: "Chain\{n}",
    n,
    ops: [
      op_binary("∧", n, (a, b) => if a < b { a } else { b }),
      op_binary("∨", n, (a, b) => if a > b { a } else { b }),
    ],
  }
}

///|
/// 由 ≤ 關係（leq[a][b]）建有限格；meet/join 由定義搜尋得到。
pub fn alg_lattice_of_order(name : String, leq : Array[Array[Bool]]) -> Alg {
  let n = leq.length()
  let meet = (a : Int32, b : Int32) => {
    let mut best = -1
    for c in 0..<n {
      if leq[c][a] && leq[c][b] && (best < 0 || leq[best][c]) {
        best = c
      }
    }
    best
  }
  let join = (a : Int32, b : Int32) => {
    let mut best = -1
    for c in 0..<n {
      if leq[a][c] && leq[b][c] && (best < 0 || leq[c][best]) {
        best = c
      }
    }
    best
  }
  { name, n, ops: [op_binary("∧", n, meet), op_binary("∨", n, join)] }
}

///|
/// 由覆蓋關係取自反傳遞閉包。
pub fn order_from_covers(
  n : Int32,
  covers : Array[(Int32, Int32)],
) -> Array[Array[Bool]] {
  let leq = Array::makei(n, i => Array::makei(n, j => i == j))
  for c in covers {
    leq[c.0][c.1] = true
  }
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        if leq[i][k] && leq[k][j] {
          leq[i][j] = true
        }
      }
    }
  }
  leq
}

///|
/// 鑽石格 M3：0 < a,b,c < 1（模而不分配）。
pub fn alg_m3() -> Alg {
  alg_lattice_of_order(
    "M3",
    order_from_covers(5, [(0, 1), (0, 2), (0, 3), (1, 4), (2, 4), (3, 4)]),
  )
}

///|
/// 五邊形格 N5：0 < a < b < 1，0 < c < 1（非模）。
pub fn alg_n5() -> Alg {
  alg_lattice_of_order(
    "N5",
    order_from_covers(5, [(0, 1), (1, 2), (2, 4), (0, 3), (3, 4)]),
  )
}

///|
/// 二元半格 ({0,1}; ∧)。
pub fn alg_semilattice2() -> Alg {
  { name: "SL2", n: 2, ops: [op_binary("∧", 2, (a, b) => a & b)] }
}

///|
/// 矩形帶 m×k：(i,j)(i',j') = (i,j')。
pub fn alg_rect_band(m : Int32, k : Int32) -> Alg {
  let n = m * k
  {
    name: "Rect\{m}x\{k}",
    n,
    ops: [op_binary("·", n, (a, b) => a % m + m * (b / m))],
  }
}

///|
/// 冪等擬群 (ℤ_3; x∗y = −x−y)（Steiner 擬群）。
pub fn alg_steiner3() -> Alg {
  {
    name: "Steiner3",
    n: 3,
    ops: [op_binary("∗", 3, (a, b) => (6 - a - b) % 3)],
  }
}

///|
/// 有界分配格＋對合的簽名 (∧, ∨, ¬, 0, 1)：De Morgan 型代數共用此簽名。
fn dm_sig(
  name : String,
  n : Int32,
  meet : (Int32, Int32) -> Int32,
  join : (Int32, Int32) -> Int32,
  neg : (Int32) -> Int32,
  top : Int32,
) -> Alg {
  {
    name,
    n,
    ops: [
      op_binary("∧", n, meet),
      op_binary("∨", n, join),
      op_unary("¬", n, neg),
      op_const("0", 0),
      op_const("1", top),
    ],
  }
}

///|
/// 二元布林代數 𝟚。
pub fn alg_bool2() -> Alg {
  dm_sig("𝟚", 2, (a, b) => a & b, (a, b) => a | b, a => 1 - a, 1)
}

///|
/// 三元 Kleene 代數 𝟛：0 < a < 1，¬a = a。
pub fn alg_kleene3() -> Alg {
  dm_sig(
    "𝟛",
    3,
    (a, b) => if a < b { a } else { b },
    (a, b) => if a > b { a } else { b },
    a => 2 - a,
    2,
  )
}

///|
/// 四元 De Morgan 代數 𝟜 = 𝟚×𝟚，元素 (p,q) ↦ p + 2q，¬(p,q) = (¬q,¬p)。
/// Kalman (1958)：𝟜 生成整個 De Morgan 簇。
pub fn alg_dm4() -> Alg {
  dm_sig(
    "𝟜",
    4,
    (a, b) => a & b,
    (a, b) => a | b,
    a => (1 - a / 2) + 2 * (1 - a % 2),
    3,
  )
}

///|
/// 三元 Stone 代數：鏈 0<a<1 配偽補（¬0=1, ¬a=¬1=0）——不是 De Morgan 代數。
pub fn alg_stone3() -> Alg {
  dm_sig(
    "Stone3",
    3,
    (a, b) => if a < b { a } else { b },
    (a, b) => if a > b { a } else { b },
    a => if a == 0 { 2 } else { 0 },
    2,
  )
}

///|
/// 有限體 GF(2^k) = 𝔽_2[x]/(poly)，元素是位元遮罩；簽名 (+, ·, 0, 1)。
pub fn alg_gf2k(k : Int32, poly : Int32) -> Alg {
  let n = 1 << k
  let mul = (a : Int32, b : Int32) => {
    let mut r = 0
    let mut x = a
    let mut y = b
    while y != 0 {
      if (y & 1) != 0 {
        r = r ^ x
      }
      y = y >> 1
      x = x << 1
      if (x & n) != 0 {
        x = x ^ poly
      }
    }
    r
  }
  {
    name: "GF(\{n})",
    n,
    ops: [
      op_binary("+", n, (a, b) => a ^ b),
      op_binary("·", n, mul),
      op_const("0", 0),
      op_const("1", 1),
    ],
  }
}
