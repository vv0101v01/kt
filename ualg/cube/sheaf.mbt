// ---------------------------------------------------------------------------
// ualg/cube — 大項一：立方體上的層化（cubical sheafification）
// ---------------------------------------------------------------------------
//
// 預層模板裡的 plus 構造／層化，在立方體 Vⁿ 上的具體計算：
//   a(F)(x) = ∏_{v ∈ Min, v ≤ x} F(v)（¬¬ 的場合）。
// [T-Cube-S1] Sh_¬¬(□ⁿ) ≃ Set^{頂點}：sheaves 由頂點上的值自由決定；
//             ρ_x : F(x) → ∏_{v ≤ x} F(v) 是雙射（n = 1 全窮舉；n = 2, 3 抽樣+子終）。
// [T-Cube-S2] 子終預層（= 子複形）的層化 = 頂點閉包：a(K) = u_{verts(K)}；
//             子終 ¬¬-層 = 正則子複形，計數 4、16、256（n = 1, 2, 3）。
// [T-Cube-S3] a(F) 的公式 ∏_{v≤x}|F(v)|（n = 1 全窮舉 70 個預層；n = 2, 3 抽樣）；
//             冪等 a(aF) ≅ aF；F 層 ⇔ η 同構。
// [T-Cube-S4] a(F ⊠ G) ≅ aF ⊠ aG（Künneth）；a(F × G) ≅ aF × aG；a(F + G) ≅ aF + aG
//             ——層化作為左伴隨保 colimits，乘積也保（在 ¬¬ 下）。
// [T-Cube-S5] Ω_¬¬ 的維數公式：|Ω_¬¬(x)| = 2^{2^{dim x}}（n ≤ 3）；
//             對照：id-核子的 Ω 不滿足此式。
// [T-Cube-S6] a ⊣ i 的計數（n = 1 全窮舉；n = 2 對小 F、Ω_¬¬(V²) 計數）；
//             |Nat(F,G)| = ∏_v |G(v)|^|F(v)|（層 F、G）。

///|
pub fn psh_times(
  p : @site.Poset,
  f : @site.Presheaf,
  g : @site.Presheaf,
) -> @site.Presheaf {
  @site.psh_make(p, Array::makei(p.n, x => f.size[x] * g.size[x]), (y, x, s) => {
    if y == x {
      return s
    }
    let j = s % g.size[y]
    let i = s / g.size[y]
    f.res[y][x][i] * g.size[x] + g.res[y][x][j]
  })
}

///|
pub fn psh_sum(
  p : @site.Poset,
  f : @site.Presheaf,
  g : @site.Presheaf,
) -> @site.Presheaf {
  @site.psh_make(p, Array::makei(p.n, x => f.size[x] + g.size[x]), (y, x, s) => {
    if y == x {
      return s
    }
    if s < f.size[y] {
      f.res[y][x][s]
    } else {
      f.size[x] + g.res[y][x][s - f.size[y]]
    }
  })
}

///|
/// 外部積 F ⊠ G，定義在 poset_product(p, q) 上（(a,b) ↦ a + |P|·b）。
pub fn psh_tensor(
  p : @site.Poset,
  q : @site.Poset,
  f : @site.Presheaf,
  g : @site.Presheaf,
) -> @site.Presheaf {
  let pn = p.n
  let pq = @site.poset_product(p, q)
  @site.psh_make(
    pq,
    Array::makei(pq.n, idx => f.size[idx % pn] * g.size[idx / pn]),
    (y, x, s) => {
      if y == x {
        return s
      }
      let a = y % pn
      let b = y / pn
      let u = x % pn
      let w = x / pn
      let j = s % g.size[b]
      let i = s / g.size[b]
      f.res[a][u][i] * g.size[w] + g.res[b][w][j]
    },
  )
}

///|
/// ≤ x 的最小元（頂點）清單。
pub fn min_below(p : @site.Poset, x : Int32) -> Array[Int32] {
  let mins : Array[Int32] = []
  for v in 0..<p.n {
    if p.down[v] == 1 << v && @site.leq(p, v, x) {
      mins.push(v)
    }
  }
  mins
}

///|
/// ρ 是逐點雙射 ⇔ ∏_{v ≤ x}|F(v)| = |F(x)| 且 ρ_x 單射（大小相同 ⇒ 雙射）。
pub fn rho_bijective(p : @site.Poset, f : @site.Presheaf) -> Bool {
  for x in 0..<p.n {
    let mins = min_below(p, x)
    let mut prod : Int64 = 1L
    for v in mins {
      prod = prod * f.size[v].to_int64()
    }
    if prod != f.size[x].to_int64() {
      return false
    }
    let seen : Map[Int64, Bool] = Map([])
    for t in 0..<f.size[x] {
      let mut code = 0L
      let mut w = 1L
      for v in mins {
        code = code + f.res[x][v][t].to_int64() * w
        w = w * f.size[v].to_int64()
      }
      seen[code] = true
    }
    if seen.length() != f.size[x] {
      return false
    }
  }
  true
}

///|
/// [T-Cube-S1-同構] 給每個頂點一個有限集大小 vert_sizes（位 v ↔ 頂點 v），
/// 構造對應的 ¬¬-層 F̂：F̂(x) = ∏_{v ≤ x} S_v，限制映射 = 投影。
pub fn psh_vertex(n : Int32, vert_sizes : Array[Int32]) -> @site.Presheaf {
  let p = @site.poset_cube(n)
  let min_lists : Array[Array[Int32]] = Array::makei(p.n, x => min_below(p, x))
  let sizes = Array::makei(p.n, x => {
    let mut prod : Int64 = 1L
    for v in min_lists[x] {
      prod = prod * vert_sizes[vertex_index(v, n)].to_int64()
    }
    prod.to_int()
  })
  @site.psh_make(p, sizes, (y, x, s) => {
    if y == x {
      return s
    }
    let my = min_lists[y]
    let mx = min_lists[x]
    let comp : Array[Int32] = []
    let mut rest = s
    for v in my {
      let sz = vert_sizes[vertex_index(v, n)]
      comp.push(rest % sz)
      rest = rest / sz
    }
    let mut code = 0
    let mut w = 1
    for v in mx {
      let mut k = -1
      for i, u in my {
        if u == v {
          k = i
        }
      }
      let sz = vert_sizes[vertex_index(v, n)]
      code = code + comp[k] * w
      w = w * sz
    }
    code
  })
}

///|
/// [T-Cube-S6] 層 F、G 的自然變換個數 = ∏_{頂點 v} |G(v)|^|F(v)|。
pub fn nat_product(
  p : @site.Poset,
  f : @site.Presheaf,
  g : @site.Presheaf,
) -> Int32 {
  let mut total : Int64 = 1L
  for v in 0..<p.n {
    if p.down[v] == 1 << v {
      let mut pw : Int64 = 1L
      for _ in 0..<f.size[v] {
        pw = pw * g.size[v].to_int64()
      }
      total = total * pw
    }
  }
  total.to_int()
}

///|
/// F 在頂點上的大小表（位 v ↔ 二進位頂點索引 v）。
pub fn vert_sizes_of(n : Int32, f : @site.Presheaf) -> Array[Int32] {
  let p = @site.poset_cube(n)
  let out = Array::make(1 << n, 0)
  for v in 0..<p.n {
    if p.down[v] == 1 << v {
      out[vertex_index(v, n)] = f.size[v]
    }
  }
  out
}

///|
/// ρ 作為自然變換（每點一張表：t ↦ ∏ 編碼）。用於檢查 ρ : F → F̂ 是同構。
pub fn rho_eta(p : @site.Poset, f : @site.Presheaf) -> Array[Array[Int32]] {
  Array::makei(p.n, x => {
    let mins = min_below(p, x)
    Array::makei(f.size[x], t => {
      let mut code = 0
      let mut w = 1
      for v in mins {
        code = code + f.res[x][v][t] * w
        w = w * f.size[v]
      }
      code
    })
  })
}

///|
/// LCG（確定性偽隨機）。
fn lcg64(s : Int64) -> Int64 {
  (s * 6364136223846793005L + 1442695040888963407L) & 0x7fffffffffffffffL
}

///|
/// V（3 個點）上全部大小 ≤ 2 的預層（含空纖維）：共 70 個。
fn all_presheaves_v() -> Array[@site.Presheaf] {
  let p = @site.poset_v()
  let out : Array[@site.Presheaf] = []
  let pow_i : Array[Array[Int32]] = Array::makei(3, c => {
    Array::makei(3, s => {
      let mut r = 1
      for _ in 0..<c {
        r = r * s
      }
      r
    })
  })
  for s0 in 0..<=2 {
    for s1 in 0..<=2 {
      for se in 0..<=2 {
        let m0 = pow_i[se][s0]
        let m1 = pow_i[se][s1]
        for c0 in 0..<m0 {
          let f0 : Array[Int32] = decode_digits(c0, se, s0)
          for c1 in 0..<m1 {
            let f1 : Array[Int32] = decode_digits(c1, se, s1)
            out.push(
              @site.psh_make(p, [s0, s1, se], (y, x, s) => {
                if y == x {
                  s
                } else if x == 0 {
                  f0[s]
                } else {
                  f1[s]
                }
              }),
            )
          }
        }
      }
    }
  }
  out
}

///|
fn decode_digits(code : Int32, len : Int32, base : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut rest = code
  for _ in 0..<len {
    out.push(rest % base)
    rest = rest / base
  }
  out
}

///|
/// V² 上大小 ≤ 2 的隨機預層（拒絕採樣；只保留滿足函子性的）。
fn random_presheaves_v2(count : Int32, seed : Int64) -> Array[@site.Presheaf] {
  let p = @site.poset_cube(2)
  let out : Array[@site.Presheaf] = []
  let mut s = seed
  let n = p.n
  // 所有可比對 (x ≤ y, x ≠ y)
  let pairs : Array[(Int32, Int32)] = []
  for y in 0..<n {
    for x in 0..<n {
      if x != y && @site.leq(p, x, y) {
        pairs.push((y, x))
      }
    }
  }
  let mut attempts = 0
  while out.length() < count && attempts < 4000 {
    attempts = attempts + 1
    let sizes = Array::makei(n, _ => {
      s = lcg64(s)
      ((s >> 33) % 3L).to_int()
    })
    let maps : Array[Array[Int32]] = []
    let mut feasible = true
    for pair in pairs {
      let (y, x) = pair
      if sizes[y] == 0 {
        maps.push([])
        continue
      }
      if sizes[x] == 0 {
        feasible = false
        break
      }
      let mut total = 1
      for _ in 0..<sizes[y] {
        total = total * sizes[x]
      }
      s = lcg64(s)
      maps.push(
        decode_digits(
          ((s >> 33) % total.to_int64()).to_int(),
          sizes[y],
          sizes[x],
        ),
      )
    }
    if !feasible {
      continue
    }
    let cand = @site.psh_make(p, sizes, (y, x, s) => {
      if y == x {
        return s
      }
      for k in 0..<pairs.length() {
        if pairs[k].0 == y && pairs[k].1 == x {
          return maps[k][s]
        }
      }
      0
    })
    if @site.psh_ok(p, cand) {
      out.push(cand)
    }
  }
  out
}
