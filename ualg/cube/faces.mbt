// ---------------------------------------------------------------------------
// ualg/cube — 面與頂點的雙重索引：子複形、正則閉包的獨立實作
// ---------------------------------------------------------------------------
//
// [D-Code]  面以三進位編碼（位 i：0/1 = 固定在端點，2 = 自由），與
//           `@site.poset_cube(n)` 的元素序號相同；真值表之外另用
//           「頂點遮罩」Int32（位 v = 二進位讀法的頂點 v）做第二種計數。
// [T-DN-C]  立方體上 ¬¬u = { f : f 的全部頂點都在 u 裡 }——「頂點決定」。
//           這是 site 的 hneg∘hneg 之外的一條獨立路徑；兩者在 n = 1, 2, 3
//           的全部開集上逐一比對（見 laws.mbt）。
// [D-Reg]   正則子複形 = 由頂點集合決定的子複形 u_S = { f : verts(f) ⊆ S }；
//           映射 S ↦ u_S 是 布林代數 P(頂點) ≅ Fix(¬¬) 的同構。
// [D-∂]     ∂σ = ↓σ ∖ {σ}：球面與其填充在 ¬¬ 下不可分（verts 相同）。

///|
/// 三進位面碼 → 二進位頂點索引（低位 = 第 0 個座標）。前提：碼裡沒有 2。
pub fn vertex_index(code : Int32, n : Int32) -> Int32 {
  let mut idx = 0
  for i in 0..<n {
    idx = idx | (@demorgan.face_digit(code, i) << i)
  }
  idx
}

///|
/// 二進位頂點索引 → 三進位面碼（全 0/1 位）。
pub fn vertex_code(v : Int32, n : Int32) -> Int32 {
  let mut code = 0
  for i in 0..<n {
    code = code + ((v >> i) & 1) * @demorgan.pow3(i)
  }
  code
}

///|
/// 面所含頂點的遮罩（位 v ↔ 頂點 v）。
pub fn face_vertices(code : Int32, n : Int32) -> Int32 {
  let mut base = 0
  let free : Array[Int32] = []
  for i in 0..<n {
    let d = @demorgan.face_digit(code, i)
    if d == 2 {
      free.push(i)
    } else {
      base = base + d * @demorgan.pow3(i)
    }
  }
  let mut m = 0
  for bits in 0..<(1 << free.length()) {
    let mut c = base
    for k in 0..<free.length() {
      if ((bits >> k) & 1) == 1 {
        c = c + @demorgan.pow3(free[k])
      }
    }
    m = m | (1 << vertex_index(c, n))
  }
  m
}

///|
/// 開集 u（子複形）裡的頂點集合。
pub fn open_vertex_mask(n : Int32, u : Int32) -> Int32 {
  let mut s = 0
  for v in 0..<(1 << n) {
    if ((u >> vertex_code(v, n)) & 1) == 1 {
      s = s | (1 << v)
    }
  }
  s
}

///|
/// 由頂點集合 S 生成的最小正則子複形：{ f : verts(f) ⊆ S }。
pub fn vertex_closure(n : Int32, s : Int32) -> Int32 {
  let full = (1 << (1 << n)) - 1
  let mut u = 0
  for c in 0..<@demorgan.pow3(n) {
    if (face_vertices(c, n) & (full ^ s)) == 0 {
      u = u | (1 << c)
    }
  }
  u
}

///|
/// [T-DN-C] ¬¬u 的頂點路徑：與 `@site.j_dneg(poset_cube(n))` 是獨立的兩條。
pub fn dneg_vertex(n : Int32, u : Int32) -> Int32 {
  vertex_closure(n, open_vertex_mask(n, u))
}

///|
/// ∂σ = ↓σ 去掉 σ 本身（球面；σ = 頂點時是 ∅）。
pub fn face_boundary(p : @site.Poset, sigma : Int32) -> Int32 {
  p.down[sigma] ^ (1 << sigma)
}

