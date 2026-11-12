// ---------------------------------------------------------------------------
// ualg/core — 同餘關係、同餘格、商代數、同構定理
// ---------------------------------------------------------------------------
//
// [D-Part]  分割以典範陣列表示：p[i] = i 所在塊的最小元（相等即陣列相等）。
// [D-Cg]    Cg(X) = 含 X 的最小同餘。
// [T-Freese] Cg(X) = 「X 在全部基本平移下的像」生成的等價關係（Mal'cev 引理）。
//           演算法（Freese 2008）：併查集＋佇列；只有真正造成合併的配對才展開平移，
//           至多 n−1 次合併，每次 Σ_f r·n^{r-1} 次查表 ⇒ O(n·‖A‖)，困難度 P。
// [T-Con]   每個同餘都是主同餘的併 ⇒ Con(A) = {Δ} 在「併上主同餘」下的閉包。
// 第二條獨立路徑：`con_bruteforce` 窮舉全部集合分割（Bell 數）逐一檢查相容性。

///|
fn uf_find(parent : Array[Int32], x : Int32) -> Int32 {
  let mut r = x
  while parent[r] != r {
    parent[r] = parent[parent[r]]
    r = parent[r]
  }
  r
}

///|
/// 合併時讓較小的根當根 ⇒ 根恆為塊內最小元，分割自動是典範形。
fn uf_union(parent : Array[Int32], a : Int32, b : Int32) -> Bool {
  let ra = uf_find(parent, a)
  let rb = uf_find(parent, b)
  if ra == rb {
    return false
  }
  if ra < rb {
    parent[rb] = ra
  } else {
    parent[ra] = rb
  }
  true
}

///|
pub fn part_discrete(n : Int32) -> Array[Int32] {
  Array::makei(n, i => i)
}

///|
pub fn part_full(n : Int32) -> Array[Int32] {
  Array::make(n, 0)
}

///|
/// 任意標號 → 典範分割。
pub fn part_norm(lab : Array[Int32]) -> Array[Int32] {
  let n = lab.length()
  let first : Map[Int32, Int32] = Map([])
  let p = Array::make(n, 0)
  for i in 0..<n {
    match first.get(lab[i]) {
      Some(j) => p[i] = j
      None => {
        first[lab[i]] = i
        p[i] = i
      }
    }
  }
  p
}

///|
pub fn part_join(p : Array[Int32], q : Array[Int32]) -> Array[Int32] {
  let n = p.length()
  let parent = Array::makei(n, i => i)
  for i in 0..<n {
    ignore(uf_union(parent, i, p[i]))
    ignore(uf_union(parent, i, q[i]))
  }
  Array::makei(n, i => uf_find(parent, i))
}

///|
pub fn part_meet(p : Array[Int32], q : Array[Int32]) -> Array[Int32] {
  let n = p.length()
  part_norm(Array::makei(n, i => p[i] * n + q[i]))
}

///|
/// p ≤ q（p 比 q 細）。
pub fn part_leq(p : Array[Int32], q : Array[Int32]) -> Bool {
  for i in 0..<p.length() {
    if q[p[i]] != q[i] {
      return false
    }
  }
  true
}

///|
pub fn part_blocks(p : Array[Int32]) -> Int32 {
  let mut c = 0
  for i in 0..<p.length() {
    if p[i] == i {
      c = c + 1
    }
  }
  c
}

///|
/// [T-Freese] 由配對集合生成的同餘。
pub fn cg(a : Alg, pairs : Array[(Int32, Int32)]) -> Array[Int32] {
  let n = a.n
  let parent = Array::makei(n, i => i)
  let queue : Array[(Int32, Int32)] = pairs.copy()
  let mut head = 0
  while head < queue.length() {
    let (x, y) = queue[head]
    head = head + 1
    if uf_union(parent, x, y) {
      for op in a.ops {
        let r = op.arity
        if r == 0 {
          continue
        }
        let others = op.table.length() / n
        let mut w = 1
        for _ in 0..<r {
          for rest in 0..<others {
            let base = rest % w + rest / w * w * n
            let u = op.table[base + x * w]
            let v = op.table[base + y * w]
            if uf_find(parent, u) != uf_find(parent, v) {
              queue.push((u, v))
            }
          }
          w = w * n
        }
      }
    }
  }
  Array::makei(n, i => uf_find(parent, i))
}

///|
/// 相容性：對每個運算、每個位置、每組其餘引數，把 i 換成其代表元後結果同塊。
pub fn is_congruence(a : Alg, p : Array[Int32]) -> Bool {
  let n = a.n
  for op in a.ops {
    let r = op.arity
    if r == 0 {
      continue
    }
    let others = op.table.length() / n
    let mut w = 1
    for _ in 0..<r {
      for rest in 0..<others {
        let base = rest % w + rest / w * w * n
        for i in 0..<n {
          if p[i] != i &&
            p[op.table[base + i * w]] != p[op.table[base + p[i] * w]] {
            return false
          }
        }
      }
      w = w * n
    }
  }
  true
}

///|
/// [T-Con] 同餘格（Δ 在前；其餘依發現順序）。
pub fn con_lattice(a : Alg) -> Array[Array[Int32]] {
  let n = a.n
  let seen : Map[String, Bool] = Map([])
  let list : Array[Array[Int32]] = []
  let prin : Array[Array[Int32]] = []
  let d = part_discrete(n)
  seen[tuple_key(d)] = true
  list.push(d)
  for x in 0..<n {
    for y in (x + 1)..<n {
      let c = cg(a, [(x, y)])
      let k = tuple_key(c)
      if !seen.contains(k) {
        seen[k] = true
        list.push(c)
        prin.push(c)
      }
    }
  }
  let mut i = 0
  while i < list.length() {
    for g in prin {
      let j = part_join(list[i], g)
      let k = tuple_key(j)
      if !seen.contains(k) {
        seen[k] = true
        list.push(j)
      }
    }
    i = i + 1
  }
  list
}

///|
/// 獨立路徑：以受限成長字串窮舉全部集合分割，留下相容者。
pub fn con_bruteforce(a : Alg) -> Array[Array[Int32]] {
  let n = a.n
  let out : Array[Array[Int32]] = []
  let lab = Array::make(n, 0)
  fn rec(i : Int32, maxlab : Int32) -> Unit {
    if i == n {
      let p = part_norm(lab)
      if is_congruence(a, p) {
        out.push(p)
      }
      return
    }
    for l in 0..<=(maxlab + 1) {
      lab[i] = l
      rec(i + 1, if l > maxlab { l } else { maxlab })
    }
  }

  rec(0, -1)
  out
}

///|
/// 兩個同餘族是否為同一個集合。
pub fn same_family(xs : Array[Array[Int32]], ys : Array[Array[Int32]]) -> Bool {
  if xs.length() != ys.length() {
    return false
  }
  let seen : Map[String, Bool] = Map([])
  for x in xs {
    seen[tuple_key(x)] = true
  }
  for y in ys {
    if !seen.contains(tuple_key(y)) {
      return false
    }
  }
  true
}

///|
/// 商代數 A/θ 與自然映射 π（元素 ↦ 類的序號）。
pub fn quotient(a : Alg, p : Array[Int32]) -> (Alg, Array[Int32]) {
  let n = a.n
  let cls = Array::make(n, -1)
  let reps : Array[Int32] = []
  for i in 0..<n {
    if p[i] == i {
      cls[i] = reps.length()
      reps.push(i)
    }
  }
  for i in 0..<n {
    cls[i] = cls[p[i]]
  }
  let m = reps.length()
  let ops : Array[Op] = []
  for op in a.ops {
    let r = op.arity
    let table = Array::makei(ipow(m, r), idx => {
      let ds = digits(idx, m, r)
      cls[op_apply(op, n, ds.map(d => reps[d]))]
    })
    ops.push({ name: op.name, arity: r, table, })
  }
  ({ name: a.name + "/θ", n: m, ops, }, cls)
}

///|
/// 映射的核。
pub fn kernel(f : Array[Int32]) -> Array[Int32] {
  part_norm(f)
}

///|
/// θ∘ψ = ψ∘θ ⇔ θ∘ψ = θ∨ψ：對併中同塊的 (x,z) 找中介 y。
pub fn part_permute(p : Array[Int32], q : Array[Int32]) -> Bool {
  let n = p.length()
  let j = part_join(p, q)
  for x in 0..<n {
    for z in 0..<n {
      if j[x] == j[z] {
        let mut found = false
        for y in 0..<n {
          if p[x] == p[y] && q[y] == q[z] {
            found = true
            break
          }
        }
        if !found {
          return false
        }
      }
    }
  }
  true
}

///|
/// 同餘可換：Con(A) 中任兩個同餘的合成可交換。
pub fn con_permutable(con : Array[Array[Int32]]) -> Bool {
  for i in 0..<con.length() {
    for j in (i + 1)..<con.length() {
      if !part_permute(con[i], con[j]) {
        return false
      }
    }
  }
  true
}

///|
/// 分配律 x∧(y∨z) = (x∧y)∨(x∧z) 在給定的分割格上是否成立。
pub fn con_distributive(con : Array[Array[Int32]]) -> Bool {
  for x in con {
    for y in con {
      for z in con {
        if part_meet(x, part_join(y, z)) !=
          part_join(part_meet(x, y), part_meet(x, z)) {
          return false
        }
      }
    }
  }
  true
}

///|
/// 模律：x ≤ z ⇒ x∨(y∧z) = (x∨y)∧z。
pub fn con_modular(con : Array[Array[Int32]]) -> Bool {
  for x in con {
    for z in con {
      if part_leq(x, z) {
        for y in con {
          if part_join(x, part_meet(y, z)) != part_meet(part_join(x, y), z) {
            return false
          }
        }
      }
    }
  }
  true
}

///|
fn chk(out : Array[(String, Bool)], label : String, cond : Bool) -> Unit {
  out.push((label, cond))
}

///|
fn divisor_count(n : Int32) -> Int32 {
  let mut c = 0
  for d in 1..<=n {
    if n % d == 0 {
      c = c + 1
    }
  }
  c
}

///|
/// 定律：Freese 閉包與 Bell 窮舉給出同一個同餘格；並對上古典閉式。
pub fn law_congruence_lattice_two_paths() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let zoo = [
    alg_zn(6),
    alg_zn(8),
    alg_s3(),
    alg_chain(5),
    alg_m3(),
    alg_n5(),
    alg_bool2(),
    alg_kleene3(),
    alg_dm4(),
    alg_rect_band(2, 2),
    alg_zn_mul(6),
    alg_gf2k(2, 7),
  ]
  let sizes : Array[Int32] = []
  let mut agree = true
  for a in zoo {
    let c1 = con_lattice(a)
    let c2 = con_bruteforce(a)
    sizes.push(c1.length())
    if !same_family(c1, c2) {
      agree = false
    }
  }
  chk(
    out,
    "同餘格：Freese 主同餘閉包 = Bell 窮舉（12 個代數逐一相同），|Con| = \{show_ints(sizes)}",
    agree,
  )
  let mut zn_ok = true
  for n in 2..<=9 {
    if con_lattice(alg_zn(n)).length() != divisor_count(n) {
      zn_ok = false
    }
  }
  chk(
    out, "|Con(ℤ_n)| = d(n)（n = 2..9；同餘 ↔ 子群 ↔ 因數）", zn_ok,
  )
  let mut ch_ok = true
  for n in 2..<=6 {
    if con_lattice(alg_chain(n)).length() != 1 << (n - 1) {
      ch_ok = false
    }
  }
  chk(
    out, "|Con(Chain_n)| = 2^(n−1)（n = 2..6；每條覆蓋邊獨立塌縮）",
    ch_ok,
  )
  chk(
    out,
    "S3 的同餘 = 正規子群 {1, A3, S3}：|Con| = 3",
    con_lattice(alg_s3()).length() == 3,
  )
  chk(
    out,
    "𝟜（De Morgan）與 𝟛（Kleene）、M3 皆單（|Con| = 2）；N5 有 5 個同餘",
    con_lattice(alg_dm4()).length() == 2 &&
    con_lattice(alg_kleene3()).length() == 2 &&
    con_lattice(alg_m3()).length() == 2 &&
    con_lattice(alg_n5()).length() == 5,
  )
  // 主同餘的第二定義：Cg(x,y) = 所有含 (x,y) 的同餘之交
  let mut cg_ok = true
  let mut cg_count = 0
  for a in [alg_zn(6), alg_n5(), alg_chain(4), alg_zn_mul(6)] {
    let all = con_bruteforce(a)
    for x in 0..<a.n {
      for y in (x + 1)..<a.n {
        let mut m = part_full(a.n)
        for c in all {
          if c[x] == c[y] {
            m = part_meet(m, c)
          }
        }
        cg_count = cg_count + 1
        if m != cg(a, [(x, y)]) {
          cg_ok = false
        }
      }
    }
  }
  chk(
    out,
    "Cg(x,y)（Freese 併查集）= ⋂{θ ∈ Con : (x,y) ∈ θ}（\{cg_count} 個配對）",
    cg_ok,
  )
  // 格論性質
  chk(
    out,
    "Funayama–Nakayama：格的同餘格分配（Chain5、M3、N5）",
    con_distributive(con_lattice(alg_chain(5))) &&
    con_distributive(con_lattice(alg_m3())) &&
    con_distributive(con_lattice(alg_n5())),
  )
  let klein = con_lattice(alg_product(alg_zn(2), alg_zn(2)))
  chk(
    out,
    "Con(ℤ2×ℤ2) ≅ M3：5 個同餘、模、**不**分配（反例對照）",
    klein.length() == 5 && con_modular(klein) && !con_distributive(klein),
  )
  out
}

///|
/// 定律：商代數良定義、自然映射是同態；三條同構定理。
pub fn law_quotient_and_isomorphism_theorems() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let zoo = [alg_zn(12), alg_s3(), alg_n5(), alg_chain(4), alg_zn_mul(6)]
  let mut q_ok = true
  let mut q_count = 0
  for a in zoo {
    for th in con_lattice(a) {
      let (q, pi) = quotient(a, th)
      q_count = q_count + 1
      if !alg_ok(q) || !is_hom(a, q, pi) || kernel(pi) != th {
        q_ok = false
      }
    }
  }
  chk(
    out,
    "商代數：對 \{q_count} 個同餘，A/θ 良構、π 是同態、ker π = θ",
    q_ok,
  )
  // 反例對照：非同餘的分割 ⇒ 自然映射不是同態
  let bad = part_norm([0, 0, 1, 2, 3, 4])
  let z6 = alg_zn(6)
  let (qb, pb) = quotient(z6, bad)
  chk(
    out,
    "反例：ℤ6 上的分割 {0,1|2|3|4|5} 不是同餘，「商」的自然映射不是同態",
    !is_congruence(z6, bad) && !is_hom(z6, qb, pb),
  )
  // 第一同構定理：A/ker f ≅ im f
  let mut iso1 = true
  let mut iso1_count = 0
  let z12 = alg_zn(12)
  for m in 1..<12 {
    // f(x) = m·x 是 ℤ12 的自同態
    let f = Array::makei(12, x => m * x % 12)
    if !is_hom(z12, z12, f) {
      iso1 = false
    }
    let image = sg(z12, f)
    let (im_alg, pos) = subalgebra(z12, image)
    let (q, pi) = quotient(z12, kernel(f))
    // 典範映射 [x] ↦ f(x)
    let phi = Array::make(q.n, -1)
    let mut well = true
    for x in 0..<12 {
      let v = pos[f[x]]
      if phi[pi[x]] >= 0 && phi[pi[x]] != v {
        well = false
      }
      phi[pi[x]] = v
    }
    let bij = part_blocks(kernel(phi)) == q.n && q.n == im_alg.n
    iso1_count = iso1_count + 1
    if !well || !bij || !is_hom(q, im_alg, phi) {
      iso1 = false
    }
  }
  chk(
    out,
    "第一同構定理：ℤ12 的 \{iso1_count} 個自同態 x↦mx，ℤ12/ker f ≅ im f（典範映射良定義、雙射、同態）",
    iso1,
  )
  // 對應定理：Con(A/θ) ≅ [θ, ∇]
  let mut corr = true
  let mut corr_count = 0
  for a in [alg_zn(12), alg_chain(5), alg_n5()] {
    let con = con_lattice(a)
    for th in con {
      let (q, pi) = quotient(a, th)
      let above : Array[Array[Int32]] = []
      for c in con {
        if part_leq(th, c) {
          above.push(c)
        }
      }
      let pulled : Array[Array[Int32]] = []
      for psi in con_lattice(q) {
        // 拉回：x ~ y ⇔ π(x) ψ π(y)
        pulled.push(part_norm(Array::makei(a.n, x => psi[pi[x]])))
      }
      corr_count = corr_count + 1
      if !same_family(above, pulled) {
        corr = false
      }
    }
  }
  chk(
    out,
    "對應定理：Con(A/θ) 沿 π 拉回恰為區間 [θ,∇]（\{corr_count} 組 (A,θ)）",
    corr,
  )
  // 第三同構定理：(A/θ)/(ψ/θ) ≅ A/ψ（比較塊數與運算表經典範映射）
  let mut iso3 = true
  let con12 = con_lattice(z12)
  for th in con12 {
    for psi in con12 {
      if part_leq(th, psi) {
        let (q1, pi1) = quotient(z12, th)
        let psi_over = part_norm(
          {
            let lab = Array::make(q1.n, 0)
            for x in 0..<12 {
              lab[pi1[x]] = psi[x]
            }
            lab
          },
        )
        let (q2, pi2) = quotient(q1, psi_over)
        let (q3, pi3) = quotient(z12, psi)
        let phi = Array::make(q2.n, -1)
        for x in 0..<12 {
          phi[pi2[pi1[x]]] = pi3[x]
        }
        if !is_congruence(q1, psi_over) || q2.n != q3.n || !is_hom(q2, q3, phi) {
          iso3 = false
        }
      }
    }
  }
  chk(
    out, "第三同構定理：θ ≤ ψ ⇒ (ℤ12/θ)/(ψ/θ) ≅ ℤ12/ψ（全部可比配對）",
    iso3,
  )
  out
}
