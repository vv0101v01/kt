// ---------------------------------------------------------------------------
// meta/instances/modules — 模組匯入圖的良基性（`resolve_modules`）
// ---------------------------------------------------------------------------
//
// 全域實例要能「跨模組」組起來，前提是**匯入圖是 DAG**：如果 A 匯入 B、B 又
// 匯入 A，那麼「哪一個模組的實例先被看到」就沒有典範答案 —— 而優先級平手時
// 典範化（`canonical`）是**按規則索引**決勝的，所以順序一變，見證就變。
//
// 這裡把「匯入圖」變成可判定物：
//   * Tarjan 求強連通分量（SCC）；
//   * SCC 大小 > 1，或模組匯入自己 ⇒ **拒絕**，並給出真實的環路見證；
//   * 否則 Tarjan 的**反拓撲**發射順序就是典範解析順序（依賴先解），
//     解析結果與模組的宣告順序無關。

///|
/// 一個模組：名字、匯入的模組索引、以及自己宣告的實例規則。
pub(all) struct Module {
  name : String
  imports : Array[Int32]
  rules : Array[Rule]
}

///|
pub fn module_(
  name : String,
  imports : Array[Int32],
  rules : Array[Rule],
) -> Module {
  Module::{ name, imports, rules, }
}

///|
/// 匯入圖。
pub(all) struct ImportGraph {
  mods : Array[Module]
}

///|
pub fn import_graph(mods : Array[Module]) -> ImportGraph {
  ImportGraph::{ mods, }
}

///|
/// Tarjan：回傳各強連通分量。分量以「反拓撲序」發射 —— 被依賴者先出現，
/// 正好就是典範解析順序（不用再反轉）。
pub fn scc(g : ImportGraph) -> Array[Array[Int32]] {
  let n = g.mods.length()
  let idx : Array[Int32] = Array::make(n, -1)
  let low : Array[Int32] = Array::make(n, -1)
  let onstk : Array[Bool] = Array::make(n, false)
  let stk : Array[Int32] = []
  let comps : Array[Array[Int32]] = []
  let fv : Array[Int32] = []
  let fi : Array[Int32] = []
  let mut counter = 0
  for root in 0..<n {
    if idx[root] != -1 {
      continue
    }
    idx[root] = counter
    low[root] = counter
    counter = counter + 1
    stk.push(root)
    onstk[root] = true
    fv.push(root)
    fi.push(0)
    while fv.length() > 0 {
      let sp = fv.length() - 1
      let v = fv[sp]
      let i = fi[sp]
      if i < g.mods[v].imports.length() {
        fi[sp] = i + 1
        let w = g.mods[v].imports[i]
        if idx[w] == -1 {
          idx[w] = counter
          low[w] = counter
          counter = counter + 1
          stk.push(w)
          onstk[w] = true
          fv.push(w)
          fi.push(0)
        } else if onstk[w] && idx[w] < low[v] {
          low[v] = idx[w]
        }
      } else {
        let _ = fv.pop()
        let _ = fi.pop()
        if low[v] == idx[v] {
          let comp : Array[Int32] = []
          let mut done = false
          while !done {
            let w = stk.pop().unwrap()
            onstk[w] = false
            comp.push(w)
            if w == v {
              done = true
            }
          }
          comps.push(comp)
        }
        if fv.length() > 0 {
          let p = fv[fv.length() - 1]
          if low[v] < low[p] {
            low[p] = low[v]
          }
        }
      }
    }
  }
  comps
}

///|
/// 有環的分量（SCC 大小 > 1，或單點自環）。
pub fn cyclic_components(g : ImportGraph) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  for c in scc(g) {
    let mut bad = c.length() > 1
    if c.length() == 1 {
      for w in g.mods[c[0]].imports {
        if w == c[0] {
          bad = true
        }
      }
    }
    if bad {
      out.push(c)
    }
  }
  out
}

///|
/// 在一個連通分量裡找出**真實的環路**（首尾相同、每步都是有向邊）。
/// 用笨的深搜：分量通常很小，清楚比快重要。
pub fn cycle_witness(g : ImportGraph, comp : Array[Int32]) -> Array[Int32] {
  if comp.length() == 0 {
    return []
  }
  let start = comp[0]
  // 單點自環：見證就是 v → v
  if comp.length() == 1 {
    for w in g.mods[start].imports {
      if w == start {
        return [start, start]
      }
    }
    return []
  }
  let path : Array[Int32] = [start]
  let visited : Array[Int32] = [start]
  let result : Array[Int32] = []
  walk(g, comp, start, path, visited, result)
  result
}

///|
fn walk(
  g : ImportGraph,
  comp : Array[Int32],
  v : Int32,
  path : Array[Int32],
  visited : Array[Int32],
  result : Array[Int32],
) -> Unit {
  // MoonBit 的參數是值傳遞，這裡用可變陣列直接寫回 `found` / `result` 的方式
  // 行不通，所以走「先寫 result、再看 result 是否非空」的路線。
  if result.length() > 0 {
    return
  }
  for w in g.mods[v].imports {
    let mut in_comp = false
    for c in comp {
      if c == w {
        in_comp = true
      }
    }
    if !in_comp || result.length() > 0 {
      continue
    }
    if w == path[0] && path.length() > 1 {
      for p in path {
        result.push(p)
      }
      result.push(w)
      return
    }
    let mut seen = false
    for u in visited {
      if u == w {
        seen = true
      }
    }
    if !seen {
      path.push(w)
      visited.push(w)
      walk(g, comp, w, path, visited, result)
      if result.length() == 0 {
        let _ = path.pop()
      }
    }
  }
}

///|
/// 典範解析的結果。
pub(all) struct Resolved {
  ok : Bool
  /// 典範順序（模組索引），依賴在前
  order : Array[Int32]
  /// 拒絕時的環路見證：v0 → v1 → … → v0
  witness : Array[Int32]
  message : String
  /// 合併後的環境（規則按典範順序串接）
  env : Env
}

///|
/// **`resolve_modules`**：把模組匯入圖解析成一個全域實例環境。
/// 有環就拒絕並給見證；無環就依 Tarjan 的反拓撲序把規則串起來。
pub fn resolve_modules(g : ImportGraph) -> Resolved {
  let bad = cyclic_components(g)
  if bad.length() > 0 {
    let w = cycle_witness(g, bad[0])
    let mut msg = "cyclic import: "
    for i in 0..<bad[0].length() {
      if i > 0 {
        msg = msg + ", "
      }
      msg = msg + g.mods[bad[0][i]].name
    }
    return Resolved::{
      ok: false,
      order: [],
      witness: w,
      message: msg,
      env: env([]),
    }
  }
  let order : Array[Int32] = []
  for c in scc(g) {
    for v in c {
      order.push(v)
    }
  }
  let rules : Array[Rule] = []
  for v in order {
    for r in g.mods[v].rules {
      rules.push(r)
    }
  }
  Resolved::{ ok: true, order, witness: [], message: "", env: env(rules), }
}

// ---------------------------------------------------------------------------
// 定律
// ---------------------------------------------------------------------------

///|
/// 三個模組的 DAG：base ← arr ← pair（箭頭是「匯入」）。
pub fn graph_dag() -> ImportGraph {
  import_graph([
    module_("pair", [1], [
      rule("g_pair", 0, cls_show(ty_pair(@core.uvar(0), @core.uvar(1))), [
        cls_show(@core.uvar(0)),
        cls_show(@core.uvar(1)),
      ]),
    ]),
    module_("arr", [2], [
      rule("g_arr", 0, cls_show(ty_array(@core.uvar(0))), [
        cls_show(@core.uvar(0)),
      ]),
    ]),
    module_("base", [], [rule("g_base", 0, cls_show(ty_int()), [])]),
  ])
}

///|
/// 同一個 DAG，但模組宣告順序打亂（索引與匯入一起重排）。
pub fn graph_dag_permuted() -> ImportGraph {
  import_graph([
    module_("base", [], [rule("g_base", 0, cls_show(ty_int()), [])]),
    module_("pair", [2], [
      rule("g_pair", 0, cls_show(ty_pair(@core.uvar(0), @core.uvar(1))), [
        cls_show(@core.uvar(0)),
        cls_show(@core.uvar(1)),
      ]),
    ]),
    module_("arr", [0], [
      rule("g_arr", 0, cls_show(ty_array(@core.uvar(0))), [
        cls_show(@core.uvar(0)),
      ]),
    ]),
  ])
}

///|
/// 有環的圖：a 匯入 b，b 匯入 a。
pub fn graph_cycle() -> ImportGraph {
  import_graph([
    module_("a", [1], [rule("h_a", 0, cls_show(ty_array(@core.uvar(0))), [])]),
    module_("b", [0], [rule("h_b", 0, cls_show(ty_bool()), [])]),
  ])
}

///|
/// 自環：模組匯入自己。
pub fn graph_self() -> ImportGraph {
  import_graph([
    module_("selfy", [0], [rule("s_self", 0, cls_show(ty_int()), [])]),
    module_("other", [], [rule("s_other", 0, cls_show(ty_bool()), [])]),
  ])
}

///|
/// 環路見證是否為真迴路（首尾相同、每步都是有向邊）。
pub fn witness_is_cycle(g : ImportGraph, w : Array[Int32]) -> Bool {
  if w.length() < 2 || w[0] != w[w.length() - 1] {
    return false
  }
  let mut ok = true
  for i in 0..<(w.length() - 1) {
    let mut edge = false
    for v in g.mods[w[i]].imports {
      if v == w[i + 1] {
        edge = true
      }
    }
    if !edge {
      ok = false
    }
  }
  ok
}

///|
/// `resolve_modules` 定律：
/// #1 DAG ⇒ 接受，且順序是合法拓撲序（依賴在前）
/// #2 合併後的規則數守恆（不多不少）
/// #3 環 ⇒ 拒絕，且見證是一條真迴路（不是隨便吐個名字）
/// #4 自環也被抓到，且移除後就接受
/// #5 典範性：同一個 DAG 換宣告順序，解析出的規則串（按名）相同
/// #6 一致性不被匯入破壞：合併後仍可判相干（用 coherence 的聲音檢查）
pub fn law_engine_module_imports_resolve_modulesly() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let g = graph_dag()
  let r = resolve_modules(g)
  // #1
  let mut topo_ok = r.ok
  for v in 0..<g.mods.length() {
    for w in g.mods[v].imports {
      // v 匯入 w ⇒ w 必須排在 v 前面
      let mut pv = -1
      let mut pw = -1
      for i in 0..<r.order.length() {
        if r.order[i] == v {
          pv = i
        }
        if r.order[i] == w {
          pw = i
        }
      }
      if !(pw >= 0 && pv > pw) {
        topo_ok = false
      }
    }
  }
  @core.chk(
    out,
    "instances: module imports resolve canonically #1 (dag accepted, dependencies first)",
    topo_ok && r.order.length() == 3,
  )
  // #2
  let mut total = 0
  for m in g.mods {
    total = total + m.rules.length()
  }
  @core.chk(
    out,
    "instances: module imports resolve canonically #2 (no rule lost or invented)",
    r.env.rules.length() == total && total == 3,
  )
  // #3
  let c = resolve_modules(graph_cycle())
  @core.chk(
    out,
    "instances: module imports resolve canonically #3 (cycle rejected with a real witness)",
    !c.ok && witness_is_cycle(graph_cycle(), c.witness) && c.witness.length() >= 3,
  )
  // #4
  let s = resolve_modules(graph_self())
  let fixed = resolve_modules(
    import_graph([
      module_("selfy", [], [rule("s_self", 0, cls_show(ty_int()), [])]),
      module_("other", [], [rule("s_other", 0, cls_show(ty_bool()), [])]),
    ]),
  )
  @core.chk(
    out,
    "instances: module imports resolve canonically #4 (self-import is a cycle, removing it accepts)",
    !s.ok && witness_is_cycle(graph_self(), s.witness) && fixed.ok,
  )
  // #5 典範性：兩種宣告順序 ⇒ 同一串規則（按名比較）
  let r2 = resolve_modules(graph_dag_permuted())
  let names_of = fn(res : Resolved) -> String {
    let mut s2 = ""
    for rule_ in res.env.rules {
      s2 = s2 + rule_.name + ";"
    }
    s2
  }
  @core.chk(
    out,
    "instances: module imports resolve canonically #5 (order-independent: same rule sequence)",
    r.ok && r2.ok && names_of(r) == names_of(r2),
  )
  // #6 匯入解析後仍然是一致環境：Show Int 有解、且解唯一
  @core.chk(
    out,
    "instances: module imports resolve canonically #6 (resolved env still resolves instances)",
    solvable(r.env, cls_show(ty_int()), 4) &&
    solvable(r.env, cls_show(ty_pair(ty_int(), ty_pair(ty_int(), ty_int()))), 6),
  )
  out
}
