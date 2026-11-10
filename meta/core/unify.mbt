// ---------------------------------------------------------------------------
// meta/core — 一階合一（Robinson 演算法）：實例搜尋的「共性」算子
// ---------------------------------------------------------------------------
//
// 三個主題的共同底座是「同一個目標的兩個解法要能併攏」。
// 併攏的最小單位就是合一子（unifier）：
//   σ 合一 t₁,t₂ ⟺ σt₁ = σt₂，
//   mgu 是偏序下的**meet**（最大下界）：任何合一子 σ 都分解成 σ = τ∘mgu。
// 所以「共性／併攏／相容」在本專案不是形容詞，而是 mgu 的三個可測性質：
//   1. 正確性 mgu(t₁,t₂) 確實合一；
//   2. 普遍性 任何合一子都通過它分解；
//   3. 唯一性 up to 變數重命名（測試：兩個獨立計算的 mgu 同構）。
//
// 這是後面 typeclass 全域實例解析（Horn 子句 SLD）與 II 型別索引相等的核心。

///|
/// 一階項：變數或函式符號應用。
pub(all) enum UTerm {
  UVar(Int32)
  UFfn(Int32, Array[UTerm])
}

///|
/// 建構變數。
pub fn uvar(i : Int32) -> UTerm {
  UVar(i)
}

///|
/// 建構函式應用。
pub fn ufn(f : Int32, args : Array[UTerm]) -> UTerm {
  UFfn(f, args)
}

///|
/// 結構相等（自己寫，避免依賴 derive 的版本差異）。
pub fn u_eq(a : UTerm, b : UTerm) -> Bool {
  match (a, b) {
    (UVar(x), UVar(y)) => x == y
    (UFfn(f, xs), UFfn(g, ys)) =>
      if f != g || xs.length() != ys.length() {
        false
      } else {
        let mut ok = true
        for i in 0..<xs.length() {
          if !u_eq(xs[i], ys[i]) {
            ok = false
          }
        }
        ok
      }
    _ => false
  }
}

///|
/// 項大小（終止性度量、搜尋剪枝都用得到）。
pub fn u_size(t : UTerm) -> Int32 {
  match t {
    UVar(_) => 1
    UFfn(_, xs) => {
      let mut s = 1
      for x in xs {
        s = s + u_size(x)
      }
      s
    }
  }
}

///|
/// 變數集合（升冪、去重）。
pub fn u_vars(t : UTerm) -> Array[Int32] {
  let out : Array[Int32] = []
  u_collect_vars(t, out)
  out
}

///|
fn u_collect_vars(t : UTerm, out : Array[Int32]) -> Unit {
  match t {
    UVar(x) => {
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
    UFfn(_, xs) =>
      for x in xs {
        u_collect_vars(x, out)
      }
  }
}

///|
/// 印出項（報告用）。
pub fn u_to_string(t : UTerm) -> String {
  match t {
    UVar(x) => "?\{x}"
    UFfn(f, xs) =>
      if xs.length() == 0 {
        "c\{f}"
      } else {
        let parts : Array[String] = []
        for x in xs {
          parts.push(u_to_string(x))
        }
        "f\{f}(\{parts.join(",")})"
      }
  }
}

// --- 替換：Array[Option[UTerm]]，索引即變數編號 -------------------------------

///|
fn usub_ensure(sub : Array[UTerm?], v : Int32) -> Unit {
  while sub.length() <= v {
    sub.push(None)
  }
}

///|
fn usub_get(sub : Array[UTerm?], v : Int32) -> UTerm? {
  if v < sub.length() {
    sub[v]
  } else {
    None
  }
}

///|
fn usub_bind(sub : Array[UTerm?], v : Int32, t : UTerm) -> Unit {
  usub_ensure(sub, v)
  sub[v] = Some(t)
}

///|
/// 沿著綁定鏈走到底（路徑壓縮由呼叫端負責；此處只求簡單正確）。
pub fn u_walk(sub : Array[UTerm?], t : UTerm) -> UTerm {
  match t {
    UVar(x) =>
      match usub_get(sub, x) {
        Some(t2) => u_walk(sub, t2)
        None => t
      }
    _ => t
  }
}

///|
/// 套用替換。
pub fn u_apply(sub : Array[UTerm?], t : UTerm) -> UTerm {
  match u_walk(sub, t) {
    UVar(_) as v => v
    UFfn(f, xs) => {
      let ys : Array[UTerm] = []
      for x in xs {
        ys.push(u_apply(sub, x))
      }
      UFfn(f, ys)
    }
  }
}

///|
fn u_occurs(sub : Array[UTerm?], v : Int32, t : UTerm) -> Bool {
  match u_walk(sub, t) {
    UVar(x) => x == v
    UFfn(_, xs) => {
      let mut hit = false
      for x in xs {
        if u_occurs(sub, v, x) {
          hit = true
        }
      }
      hit
    }
  }
}

///|
/// Robinson 合一。成功時就地寫入 `sub`，回傳 true。
pub fn u_unify(sub : Array[UTerm?], a : UTerm, b : UTerm) -> Bool {
  let x = u_walk(sub, a)
  let y = u_walk(sub, b)
  match (x, y) {
    (UVar(p), UVar(q)) =>
      if p == q {
        true
      } else {
        usub_bind(sub, p, UVar(q))
        true
      }
    (UVar(p), _) =>
      if u_occurs(sub, p, y) {
        false
      } else {
        usub_bind(sub, p, y)
        true
      }
    (_, UVar(_)) => u_unify(sub, y, x)
    (UFfn(f, xs), UFfn(g, ys)) =>
      if f != g || xs.length() != ys.length() {
        false
      } else {
        let mut ok = true
        let mut i = 0
        while i < xs.length() && ok {
          if !u_unify(sub, xs[i], ys[i]) {
            ok = false
          }
          i = i + 1
        }
        ok
      }
  }
}

///|
/// 計算 mgu：只回傳「作用在輸入項上會用到的」那一小段替換。
pub fn u_mgu(a : UTerm, b : UTerm) -> Array[UTerm?]? {
  let sub : Array[UTerm?] = []
  if u_unify(sub, a, b) {
    // 收斂成範式替換，去掉中介變數
    let out : Array[UTerm?] = []
    for i in 0..<sub.length() {
      match sub[i] {
        Some(t) => {
          usub_ensure(out, i)
          out[i] = Some(u_apply(sub, t))
        }
        None => ()
      }
    }
    Some(out)
  } else {
    None
  }
}

///|
/// 兩個項是否可合一（只問可不可，不要見證）。
pub fn u_unifiable(a : UTerm, b : UTerm) -> Bool {
  match u_mgu(a, b) {
    Some(_) => true
    None => false
  }
}

///|
/// t 是否為 p 的一個實例（存在替換 σ 使 σp = t）。
pub fn u_is_instance(pattern : UTerm, t : UTerm) -> Bool {
  let sub : Array[UTerm?] = []
  u_unify(sub, pattern, t)
}

///| 變數正規化字串：以首次出現順序重新命名變數後序列化。

///|
/// 用途：判斷兩個項是否只差變數改名（α-等價）—— 憑證檢查需要它。
pub fn u_canon_str(t : UTerm) -> String {
  let names : Array[Int32] = []
  u_canon_go(t, names)
}

///|
fn u_canon_go(t : UTerm, names : Array[Int32]) -> String {
  match t {
    UVar(x) => {
      let mut idx = -1
      for i in 0..<names.length() {
        if names[i] == x {
          idx = i
        }
      }
      if idx < 0 {
        names.push(x)
        idx = names.length() - 1
      }
      "?\{idx}"
    }
    UFfn(f, xs) => {
      let parts : Array[String] = []
      for y in xs {
        parts.push(u_canon_go(y, names))
      }
      "f\{f}(\{parts.join(",")})"
    }
  }
}

///|
/// α-等價：只差變數改名。
pub fn u_variant_eq(a : UTerm, b : UTerm) -> Bool {
  u_canon_str(a) == u_canon_str(b)
}

///| 兩個項的「共性」：最小公共推廣（anti-unification, lgg）。

///| 這是「共性」一詞的可執行版本：lgg 是 join（最小上界），

///|
/// 與 mgu 的 meet 對偶 —— 也就是本檔案標題說的鏡像對稱。
pub fn u_lgg(a : UTerm, b : UTerm, next_var : Array[Int32]) -> UTerm {
  let state : Array[(Int32, Int32, UTerm)] = []
  u_lgg_go(a, b, next_var, state)
}

///|
fn u_lgg_go(
  a : UTerm,
  b : UTerm,
  next_var : Array[Int32],
  memo : Array[(Int32, Int32, UTerm)],
) -> UTerm {
  match (a, b) {
    (UFfn(f, xs), UFfn(g, ys)) =>
      if f == g && xs.length() == ys.length() {
        let out : Array[UTerm] = []
        for i in 0..<xs.length() {
          out.push(u_lgg_go(xs[i], ys[i], next_var, memo))
        }
        UFfn(f, out)
      } else {
        u_fresh_var(next_var)
      }
    _ => {
      // 先查記憶表：同一個 pair 要拿到同一個新變數
      let mut found : UTerm? = None
      let ka = u_key(a)
      let kb = u_key(b)
      for e in memo {
        if e.0 == ka && e.1 == kb {
          found = Some(e.2)
        }
      }
      match found {
        Some(v) => v
        None => {
          let fresh = u_fresh_var(next_var)
          memo.push((ka, kb, fresh))
          fresh
        }
      }
    }
  }
}

///|
fn u_fresh_var(next_var : Array[Int32]) -> UTerm {
  if next_var.length() == 0 {
    next_var.push(100)
  }
  let v = next_var[0]
  next_var[0] = v + 1
  UVar(v)
}

///|
/// 給記憶表用的結構鍵（小項才用；夠用即可）。
fn u_key(t : UTerm) -> Int32 {
  match t {
    UVar(x) => x * 7919
    UFfn(f, xs) => {
      let mut h = 104729 + f * 31
      for x in xs {
        h = (h * 3 + u_key(x)) % 1000003
      }
      h
    }
  }
}

///|
pub fn law_unify_unification_correctness_generality_uniqueness() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // f(x, b) 與 f(a, y) 的 mgu = {x ↦ a, y ↦ b}
  let a = ufn(0, [uvar(1), ufn(1, [])])
  let b = ufn(0, [ufn(2, []), uvar(2)])
  match u_mgu(a, b) {
    Some(sub) => {
      chk(
        out,
        "unification: correctness + generality + uniqueness #1",
        u_eq(u_apply(sub, a), u_apply(sub, b)),
      )
      // 普遍性：σ' = {x↦a, y↦b} 必須是 mgu 的實例
      chk(
        out,
        "unification: correctness + generality + uniqueness #2",
        u_eq(u_apply(sub, uvar(1)), ufn(2, [])),
      )
      chk(
        out,
        "unification: correctness + generality + uniqueness #3",
        u_eq(u_apply(sub, uvar(2)), ufn(1, [])),
      )
    }
    None =>
      chk(out, "unification: correctness + generality + uniqueness #4", false)
  }
  // occurs check
  let sub2 : Array[UTerm?] = []
  chk(
    out,
    "unification: correctness + generality + uniqueness #5",
    !u_unify(sub2, uvar(0), ufn(3, [uvar(0)])),
  )
  // 不可合一
  chk(
    out,
    "unification: correctness + generality + uniqueness #6",
    !u_unifiable(ufn(0, []), ufn(1, [])),
  )
  // 對稱性：mgu(a,b) 與 mgu(b,a) 給出同構結果
  let c = ufn(4, [uvar(0), uvar(0)])
  let d = ufn(4, [ufn(5, []), uvar(1)])
  match (u_mgu(c, d), u_mgu(d, c)) {
    (Some(s1), Some(s2)) => {
      chk(
        out,
        "unification: correctness + generality + uniqueness #7",
        u_eq(u_apply(s1, c), u_apply(s2, c)),
      )
      chk(
        out,
        "unification: correctness + generality + uniqueness #8",
        u_eq(u_apply(s1, d), u_apply(s2, d)),
      )
    }
    _ =>
      chk(out, "unification: correctness + generality + uniqueness #9", false)
  }
  out
}

///|
pub fn law_unify_anti_unification_join_dual_of_mgu() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let next : Array[Int32] = []
  let l = u_lgg(
    ufn(0, [ufn(1, []), ufn(2, [])]),
    ufn(0, [ufn(1, []), ufn(3, [])]),
    next,
  )
  // 共同結構保留：最外層 f0 與其第一個子項 f1
  match l {
    UFfn(f, xs) => {
      chk(
        out,
        "anti-unification = join (dual of mgu) #1",
        f == 0 && xs.length() == 2,
      )
      match xs[0] {
        UFfn(g, _) =>
          chk(out, "anti-unification = join (dual of mgu) #2", g == 1)
        _ => chk(out, "anti-unification = join (dual of mgu) #3", false)
      }
      // 不同子項被抽象成同一個新變數是不可能的（它們位置不同），但都必須是變數
      chk(
        out,
        "anti-unification = join (dual of mgu) #4",
        u_vars(xs[1]).length() == 1,
      )
    }
    _ => chk(out, "anti-unification = join (dual of mgu) #5", false)
  }
  // lgg 必須是兩者的公共推廣：兩邊都是它的實例
  let p = uvar(0)
  let q = uvar(1)
  let l2 = u_lgg(p, q, [])
  chk(
    out,
    "anti-unification = join (dual of mgu) #6",
    u_is_instance(l2, p) && u_is_instance(l2, q),
  )
  out
}

// ---------------------------------------------------------------------------
// 線性／近線性並查集 DAG 合一器（Paterson–Wegman / Martelli–Montanari Union-Find）
// ---------------------------------------------------------------------------
//
// 傳統樹狀 Robinson 合一在指數共享對（如 f(x_0,...,x_{n-1}) 與 f(g(x_1,x_1),...,g(x_n,x_n))）
// 會因重複展開子樹退化為 O(2^n)。
// 本引擎將輸入項扁平化入連續節點池，在壓入子問題**之前**先行合併並查集等價類（`uf_parent[rx] = ry`），
// 使所有共享變數分支於 O(α(n)) 內短路跳過；最後以單趟三色 DFS（0=未訪, 1=堆疊中, 2=無環完畢）
// 在 O(V + E) 內完成精確 occurs-check。

///|
priv enum UDagNode {
  DVar(Int32)
  DFfn(Int32, Array[Int32])
}

///|
fn udag_intern(
  t : UTerm,
  nodes : Array[UDagNode],
  parent : Array[Int32],
  var_slot : Map[Int32, Int32],
) -> Int32 {
  match t {
    UVar(v) =>
      match var_slot.get(v) {
        Some(id) => id
        None => {
          let id = nodes.length()
          nodes.push(DVar(v))
          parent.push(id)
          var_slot[v] = id
          id
        }
      }
    UFfn(f, xs) => {
      let child_ids : Array[Int32] = []
      for x in xs {
        child_ids.push(udag_intern(x, nodes, parent, var_slot))
      }
      let id = nodes.length()
      nodes.push(DFfn(f, child_ids))
      parent.push(id)
      id
    }
  }
}

///|
/// Path-halving Disjoint-Set representative lookup (`O(α(n))` amortized).
pub fn uf_find_halving(parent : Array[Int32], x0 : Int32) -> Int32 {
  let mut x = x0
  while parent[x] != x {
    parent[x] = parent[parent[x]]
    x = parent[x]
  }
  x
}

///|
fn udag_find(parent : Array[Int32], x0 : Int32) -> Int32 {
  uf_find_halving(parent, x0)
}

///|
fn udag_acyclic_dfs(
  u0 : Int32,
  nodes : Array[UDagNode],
  parent : Array[Int32],
  color : Array[Int32],
) -> Bool {
  let u = udag_find(parent, u0)
  if color[u] == 2 {
    return true
  }
  if color[u] == 1 {
    return false
  }
  color[u] = 1
  match nodes[u] {
    DVar(_) => ()
    DFfn(_, kids) =>
      for k in kids {
        if !udag_acyclic_dfs(k, nodes, parent, color) {
          return false
        }
      }
  }
  color[u] = 2
  true
}

///|
fn udag_reify(
  u0 : Int32,
  nodes : Array[UDagNode],
  parent : Array[Int32],
  memo : Array[UTerm?],
) -> UTerm {
  let u = udag_find(parent, u0)
  match memo[u] {
    Some(t) => t
    None => {
      let res = match nodes[u] {
        DVar(v) => UVar(v)
        DFfn(f, kids) => {
          let out : Array[UTerm] = []
          for k in kids {
            out.push(udag_reify(k, nodes, parent, memo))
          }
          UFfn(f, out)
        }
      }
      memo[u] = Some(res)
      res
    }
  }
}

///|
/// O((|a|+|b|) α(n)) 並查集 DAG 可合一判定（處理深層變數共享無指數爆炸）。
pub fn u_unifiable_dag(a : UTerm, b : UTerm) -> Bool {
  let nodes : Array[UDagNode] = []
  let parent : Array[Int32] = []
  let var_slot : Map[Int32, Int32] = Map([])
  let ra = udag_intern(a, nodes, parent, var_slot)
  let rb = udag_intern(b, nodes, parent, var_slot)
  let work : Array[(Int32, Int32)] = [(ra, rb)]
  while work.length() > 0 {
    let (x0, y0) = match work.pop() {
      Some(p) => p
      None => break
    }
    let rx = udag_find(parent, x0)
    let ry = udag_find(parent, y0)
    if rx == ry {
      continue
    }
    match (nodes[rx], nodes[ry]) {
      (DVar(_), _) => parent[rx] = ry
      (_, DVar(_)) => parent[ry] = rx
      (DFfn(f, xs), DFfn(g, ys)) => {
        if f != g || xs.length() != ys.length() {
          return false
        }
        // 關鍵近線性不變量：先合併等價類再推入子對，消除共享子圖重複遍歷
        parent[rx] = ry
        for i in 0..<xs.length() {
          work.push((xs[i], ys[i]))
        }
      }
    }
  }
  let color = Array::make(nodes.length(), 0)
  for i in 0..<nodes.length() {
    if !udag_acyclic_dfs(i, nodes, parent, color) {
      return false
    }
  }
  true
}

///|
/// 以並查集 DAG 核心計算正規 mgu 替換（與 `u_mgu` 在所有可展開實例上 α-同構）。
pub fn u_mgu_dag(a : UTerm, b : UTerm) -> Array[UTerm?]? {
  let nodes : Array[UDagNode] = []
  let parent : Array[Int32] = []
  let var_slot : Map[Int32, Int32] = Map([])
  let ra = udag_intern(a, nodes, parent, var_slot)
  let rb = udag_intern(b, nodes, parent, var_slot)
  let work : Array[(Int32, Int32)] = [(ra, rb)]
  while work.length() > 0 {
    let (x0, y0) = match work.pop() {
      Some(p) => p
      None => break
    }
    let rx = udag_find(parent, x0)
    let ry = udag_find(parent, y0)
    if rx == ry {
      continue
    }
    match (nodes[rx], nodes[ry]) {
      (DVar(_), _) => parent[rx] = ry
      (_, DVar(_)) => parent[ry] = rx
      (DFfn(f, xs), DFfn(g, ys)) => {
        if f != g || xs.length() != ys.length() {
          return None
        }
        parent[rx] = ry
        for i in 0..<xs.length() {
          work.push((xs[i], ys[i]))
        }
      }
    }
  }
  let color = Array::make(nodes.length(), 0)
  for i in 0..<nodes.length() {
    if !udag_acyclic_dfs(i, nodes, parent, color) {
      return None
    }
  }
  let memo : Array[UTerm?] = Array::make(nodes.length(), None)
  let out : Array[UTerm?] = []
  for v, slot in var_slot {
    let root = udag_find(parent, slot)
    let term = udag_reify(root, nodes, parent, memo)
    match term {
      UVar(w) =>
        if w != v {
          usub_ensure(out, v)
          out[v] = Some(term)
        }
      _ => {
        usub_ensure(out, v)
        out[v] = Some(term)
      }
    }
  }
  Some(out)
}

///|
/// Paterson–Wegman / Martelli–Montanari 並查集 DAG 合一定律：
/// #1 與樹狀 `u_mgu` 在可合一／不可合一／occurs-check 環上嚴格同構；
/// #2 在深度 16 之指數級變數共享階梯（樹展開大小 2^16 = 65,536）上無展開直接線性判定可合一與帶環失敗。
pub fn law_unify_dag_paterson_wegman_equivalence() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let t1 = ufn(1, [uvar(0), ufn(2, [uvar(1), ufn(3, [])])])
  let t2 = ufn(1, [ufn(2, [uvar(1), uvar(2)]), uvar(0)])
  let eq_ok = match (u_mgu(t1, t2), u_mgu_dag(t1, t2)) {
    (Some(s1), Some(s2)) =>
      u_canon_str(u_apply(s1, t1)) == u_canon_str(u_apply(s2, t1)) &&
      u_eq(u_apply(s2, t1), u_apply(s2, t2))
    _ => false
  }
  chk(out, "dag unification: α-equivalent mgu with Robinson #1", eq_ok)
  // Occurs-check 環：?0 = f(?1), ?1 = g(?0) 必須被三色 DFS 精確拒絕
  let cyc_l = ufn(0, [uvar(0), uvar(1)])
  let cyc_r = ufn(0, [ufn(1, [uvar(1)]), ufn(2, [uvar(0)])])
  let cyc_none = match u_mgu_dag(cyc_l, cyc_r) {
    None => true
    Some(_) => false
  }
  chk(
    out,
    "dag unification: 3-color DFS rejects indirect occurs cycle #2",
    !u_unifiable_dag(cyc_l, cyc_r) && cyc_none,
  )
  // 深度 16 Paterson–Wegman 指數共享階梯：
  // lhs = tup(x_0, x_1, ..., x_15), rhs = tup(pair(x_1,x_1), pair(x_2,x_2), ..., pair(x_16,x_16))
  let lhs_args : Array[UTerm] = []
  let rhs_args : Array[UTerm] = []
  for i in 0..<16 {
    lhs_args.push(uvar(i))
    rhs_args.push(ufn(9, [uvar(i + 1), uvar(i + 1)]))
  }
  let pw_lhs = ufn(8, lhs_args)
  let pw_rhs = ufn(8, rhs_args)
  // 追加 x_16 = x_0 即構成跨越 16 層共享之環，必須在 O(n) 拒絕
  let lhs_cyc : Array[UTerm] = []
  let rhs_cyc : Array[UTerm] = []
  for i in 0..<16 {
    lhs_cyc.push(uvar(i))
    rhs_cyc.push(ufn(9, [uvar(i + 1), uvar(i + 1)]))
  }
  lhs_cyc.push(uvar(16))
  rhs_cyc.push(uvar(0))
  chk(
    out,
    "dag unification: depth-16 Paterson-Wegman shared ladder & cycle #3",
    u_unifiable_dag(pw_lhs, pw_rhs) &&
    !u_unifiable_dag(ufn(8, lhs_cyc), ufn(8, rhs_cyc)),
  )
  out
}
