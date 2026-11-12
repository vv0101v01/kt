// ---------------------------------------------------------------------------
// ualg/demorgan — 面格 𝔽(n)：DM(n) 的商、立方體的子複形、量詞
// ---------------------------------------------------------------------------
//
// [D-Face]  𝔽(n) = DM(n) / ⟨x_i ∧ ¬x_i ≈ 0⟩（只對 ∧、∨ 的格同餘）。
//           x_i ↔ (i=1)，¬x_i ↔ (i=0)；一致子句 ↔ 立方體 □ⁿ 的一個面。
// [T-F3]    三條路徑：ualg/core 的 Cg 商 = 刪去不一致子句的正規形
//           = ualg/site 的 O(Vⁿ)（面偏序的下閉集 = □ⁿ 的子複形）。
// [T-Bool]  若改用 De Morgan 同餘（連 ¬ 一起），商是自由布林代數 𝟚^(2ⁿ)，
//           它的同餘核恰是 ¬¬ 核子的核：DM 的布林反射 = ¬¬-層化在 Ω 上的影子。
// [T-Rec]   |𝔽(n)| = Σ_{φ,ψ∈𝔽(n−1)} |↓(φ∧ψ)|：2、5、48、…
// [T-Quant] ∃i ⊣ 弱化 ⊣ ∀i；Frobenius；∀i 同時保 ∧ 與 ∨（面是併質的）；
//           ∀i.φ ≤ φ(i0)∧φ(i1) 且一般不等（∀i.((i=0)∨(i=1)) = 0）。

///|
/// 子句是否一致（不同時含 x_i 與 ¬x_i）。
pub fn clause_consistent(c : Int32) -> Bool {
  (c & (c >> 1) & 0x15555555) == 0
}

///|
/// 𝔽 的正規形：刪去不一致子句。
pub fn face_norm(f : Array[Int32]) -> Array[Int32] {
  f.filter(clause_consistent)
}

///|
/// 一致子句 → 面的三進位編碼（位 i：0/1 = 固定在端點，2 = 自由），
/// 與 `@site.poset_cube(n)` 的元素序號相同。
pub fn clause_face(c : Int32, n : Int32) -> Int32 {
  let mut code = 0
  let mut w = 1
  for i in 0..<n {
    let d = if has(c, 2 * i) { 1 } else if has(c, 2 * i + 1) { 0 } else { 2 }
    code = code + d * w
    w = w * 3
  }
  code
}

///|
pub fn face_clause(code : Int32, n : Int32) -> Int32 {
  let mut c = 0
  let mut rest = code
  for i in 0..<n {
    let d = rest % 3
    rest = rest / 3
    if d == 1 {
      c = c | (1 << (2 * i))
    } else if d == 0 {
      c = c | (1 << (2 * i + 1))
    }
  }
  c
}

///|
/// 面公式 → 子複形（面偏序的下閉集）。
pub fn face_open(p : @site.Poset, f : Array[Int32], n : Int32) -> Int32 {
  let mut u = 0
  for c in f {
    u = u | p.down[clause_face(c, n)]
  }
  u
}

///|
/// 子複形 → 面公式（極大面各給一個子句）。
pub fn open_face(p : @site.Poset, u : Int32, n : Int32) -> Array[Int32] {
  let cs : Array[Int32] = []
  for x in 0..<p.n {
    if has(u, x) && (p.up[x] & u) == 1 << x {
      cs.push(face_clause(x, n))
    }
  }
  dnf_norm(cs)
}

///|
/// ∃i.φ：把每個子句裡關於 i 的字面抹掉（子複形沿 i 方向的投影柱）。
pub fn face_exists(f : Array[Int32], i : Int32) -> Array[Int32] {
  dnf_norm(f.map(c => c & (3 << (2 * i)).lnot()))
}

///|
/// ∀i.φ：只留下不提到 i 的子句（整條 i-稜柱都在 φ 內的面）。
pub fn face_forall(f : Array[Int32], i : Int32) -> Array[Int32] {
  f.filter(c => (c & (3 << (2 * i))) == 0)
}

///|
/// φ(i := b)。
pub fn face_at(f : Array[Int32], i : Int32, b : Int32) -> Array[Int32] {
  let agree = 1 << (2 * i + 1 - b)
  let clash = 1 << (2 * i + b)
  dnf_norm(f.filter(c => (c & clash) == 0).map(c => c & agree.lnot()))
}

///|
pub fn face_mentions(f : Array[Int32], i : Int32) -> Bool {
  for c in f {
    if (c & (3 << (2 * i))) != 0 {
      return true
    }
  }
  false
}

///|
/// [T-Rec] |𝔽(n)| 的遞推（n ≥ 1），以 𝔽(n−1) 的子複形遮罩計算。
pub fn face_count_recursive(n : Int32) -> Int64 {
  let opens = @site.opens_all(@site.poset_cube(n - 1))
  let down : Map[Int32, Int64] = Map([])
  for u in opens {
    let mut c = 0L
    for v in opens {
      if (v & u) == v {
        c = c + 1L
      }
    }
    down[u] = c
  }
  let mut total = 0L
  for u in opens {
    for v in opens {
      match down.get(u & v) {
        Some(c) => total = total + c
        None => return -1L
      }
    }
  }
  total
}

///|
fn lcg(s : Int64) -> Int64 {
  (s * 6364136223846793005L + 1442695040888963407L) & 0x7fffffffffffffffL
}

///|
/// 定律：面格的三條路徑與布林反射。
pub fn law_face_lattice_three_paths() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let lat_blocks : Array[Int32] = []
  let dm_blocks : Array[Int32] = []
  let mut kernel_ok = true
  let mut site_ok = true
  let mut bool_ok = true
  let mut iso = true
  for n in 1..<=2 {
    let elems = dm_elements(n)
    let m = elems.length()
    let index = dm_index(elems)
    let idx = (f : Array[Int32]) => {
      match index.get(dnf_key(f)) {
        Some(i) => i
        None => -1
      }
    }
    let meet = @core.op_binary("∧", m, (a, b) => {
      idx(dnf_meet(elems[a], elems[b]))
    })
    let join = @core.op_binary("∨", m, (a, b) => {
      idx(dnf_join(elems[a], elems[b]))
    })
    let neg = @core.op_unary("¬", m, a => idx(dnf_neg(elems[a])))
    let lat : @core.Alg = {
      name: "DM(\{n}) 的格約化",
      n: m,
      ops: [meet, join],
    }
    let dm : @core.Alg = { name: "DM(\{n})", n: m, ops: [meet, join, neg], }
    let pairs : Array[(Int32, Int32)] = []
    for i in 0..<n {
      pairs.push((idx(dnf_meet(dnf_var(i), dnf_nvar(i))), idx(dnf_zero())))
    }
    // 路徑一：泛代數的同餘生成
    let theta = @core.part_norm(@core.cg(lat, pairs))
    lat_blocks.push(@core.part_blocks(theta))
    // 路徑二：正規形的核
    let labels : Map[String, Int32] = Map([])
    let ker = @core.part_norm(
      Array::makei(m, i => {
        let k = dnf_key(face_norm(elems[i]))
        match labels.get(k) {
          Some(v) => v
          None => {
            let v = labels.length()
            labels[k] = v
            v
          }
        }
      }),
    )
    if !@core.part_leq(theta, ker) || !@core.part_leq(ker, theta) {
      kernel_ok = false
    }
    // 路徑三：site 的開集
    let p = @site.poset_cube(n)
    let opens = @site.opens_all(p)
    if opens.length() != labels.length() ||
      @site.opens_count(p) != labels.length().to_int64() {
      site_ok = false
    }
    // 𝔽(n) → O(Vⁿ) 是格同構
    let images : Map[Int32, Bool] = Map([])
    for f in elems {
      let ff = face_norm(f)
      let u = face_open(p, ff, n)
      images[u] = true
      if !@site.is_open(p, u) || open_face(p, u, n) != ff {
        iso = false
      }
      for g in elems {
        let gg = face_norm(g)
        let v = face_open(p, gg, n)
        if face_open(p, face_norm(dnf_meet(ff, gg)), n) != (u & v) ||
          face_open(p, face_norm(dnf_join(ff, gg)), n) != (u | v) {
          iso = false
        }
      }
    }
    if images.length() != opens.length() {
      iso = false
    }
    // 布林反射：De Morgan 同餘 vs ¬¬ 核子的核
    let theta_dm = @core.part_norm(@core.cg(dm, pairs))
    dm_blocks.push(@core.part_blocks(theta_dm))
    let j = @site.j_dneg(p)
    let jl : Map[Int32, Int32] = Map([])
    let jker = @core.part_norm(
      Array::makei(m, i => {
        let u = j(face_open(p, face_norm(elems[i]), n))
        match jl.get(u) {
          Some(v) => v
          None => {
            let v = jl.length()
            jl[u] = v
            v
          }
        }
      }),
    )
    if !@core.part_leq(theta_dm, jker) ||
      !@core.part_leq(jker, theta_dm) ||
      theta_dm[idx(dnf_join(dnf_var(0), dnf_nvar(0)))] !=
      theta_dm[idx(dnf_one())] ||
      theta[idx(dnf_join(dnf_var(0), dnf_nvar(0)))] == theta[idx(dnf_one())] {
      bool_ok = false
    }
  }
  chk(
    out,
    "路徑一（ualg/core 的 Cg）：DM(n) 的格約化對 ⟨x_i∧¬x_i ≈ 0⟩ 的商有 \{@core.show_ints(lat_blocks)} 個類（n = 1, 2）",
    lat_blocks == [5, 48],
  )
  chk(
    out, "路徑二：該同餘恰是「刪去不一致子句」的核（兩個分割互相細化）",
    kernel_ok,
  )
  chk(
    out, "路徑三（ualg/site）：類數 = 面偏序 Vⁿ 的開集數（列舉與遞推計數皆同）",
    site_ok,
  )
  chk(
    out, "𝔽(n) ≅ O(Vⁿ)：公式 ↦ 子複形是格同構（∧ ↦ ∩、∨ ↦ ∪、雙射、可逆）",
    iso,
  )
  chk(
    out,
    "布林反射：連 ¬ 一起的 De Morgan 同餘給 \{@core.show_ints(dm_blocks)} = 2^(2ⁿ) 個類，其核 = ¬¬ 核子的核；此時 x∨¬x ≈ 1，而格同餘下 x∨¬x ≉ 1",
    dm_blocks == [4, 16] && bool_ok,
  )
  let sizes : Array[Int64] = [2L]
  let mut rec_ok = true
  for n in 1..<=3 {
    let c = face_count_recursive(n)
    sizes.push(c)
    if c != @site.opens_count(@site.poset_cube(n)) {
      rec_ok = false
    }
  }
  chk(
    out,
    "|𝔽(0..3)| = \{sizes[0]}, \{sizes[1]}, \{sizes[2]}, \{sizes[3]}：遞推 Σ|↓(φ∧ψ)| = site 的極大元計數",
    rec_ok && sizes[1] == 5L && sizes[2] == 48L,
  )
  out
}

///|
/// 定律：面格上的量詞（CCHM 的 ∀i.φ）。
pub fn law_face_quantifiers_adjoint() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let n = 2
  let p = @site.poset_cube(n)
  let opens = @site.opens_all(p)
  let forms = opens.map(u => open_face(p, u, n))
  let mut brute = true
  let mut adj = true
  let mut frob = true
  let mut lattice = true
  let mut bc = true
  let mut bound = true
  let mut ex_meet_fail = 0
  let mut differ = 0
  for i in 0..<n {
    let k = 1 - i
    for a, phi in forms {
      let ex = face_exists(phi, i)
      let fa = face_forall(phi, i)
      let ex_u = face_open(p, ex, n)
      let fa_u = face_open(p, fa, n)
      // 伴隨的定義式：以全部不含 i 的 ψ 窮舉
      let mut least = @site.full_mask(p)
      let mut greatest = 0
      for b, psi in forms {
        if !face_mentions(psi, i) {
          let v = opens[b]
          if (opens[a] & v) == opens[a] {
            least = least & v
          }
          if (v & opens[a]) == v {
            greatest = greatest | v
          }
          if ((ex_u & v) == ex_u) != ((opens[a] & v) == opens[a]) ||
            ((v & fa_u) == v) != ((v & opens[a]) == v) {
            adj = false
          }
          if face_exists(face_norm(dnf_meet(phi, psi)), i) !=
            face_norm(dnf_meet(ex, psi)) {
            frob = false
          }
        }
        if face_forall(face_norm(dnf_join(phi, psi)), i) !=
          dnf_join(fa, face_forall(psi, i)) ||
          face_forall(face_norm(dnf_meet(phi, psi)), i) !=
          face_norm(dnf_meet(fa, face_forall(psi, i))) ||
          face_exists(dnf_join(phi, psi), i) !=
          dnf_join(ex, face_exists(psi, i)) {
          lattice = false
        }
        if face_exists(face_norm(dnf_meet(phi, psi)), i) !=
          face_norm(dnf_meet(ex, face_exists(psi, i))) {
          ex_meet_fail = ex_meet_fail + 1
        }
      }
      if least != ex_u || greatest != fa_u {
        brute = false
      }
      let ends = face_norm(dnf_meet(face_at(phi, i, 0), face_at(phi, i, 1)))
      if !dnf_leq(fa, ends) {
        bound = false
      }
      if fa != ends {
        differ = differ + 1
      }
      for b in 0..<2 {
        if face_at(fa, k, b) != face_forall(face_at(phi, k, b), i) ||
          face_at(ex, k, b) != face_exists(face_at(phi, k, b), i) {
          bc = false
        }
      }
    }
  }
  chk(
    out, "∃i、∀i 的正規形公式 = 伴隨的定義（最小／最大的不含 i 的 ψ），𝔽(2) 全部 48 個公式 × 2 個方向",
    brute,
  )
  chk(
    out, "∃i ⊣ 弱化 ⊣ ∀i：∃i.φ ≤ ψ ⇔ φ ≤ ψ ⇔ …、ψ ≤ ∀i.φ ⇔ ψ ≤ φ（ψ 不含 i）",
    adj,
  )
  chk(
    out, "Frobenius：∃i.(φ ∧ ψ) = (∃i.φ) ∧ ψ（ψ 不含 i）", frob,
  )
  chk(
    out,
    "∀i 同時保 ∧ 與 ∨（面是併質元），∃i 保 ∨；對照：∃i 不保 ∧ 共 \{ex_meet_fail} 組",
    lattice && ex_meet_fail > 0,
  )
  chk(
    out,
    "∀i.φ ≤ φ(i0) ∧ φ(i1) 恆成立，但有 \{differ} 個 (φ,i) 嚴格小於——Kan 合成必須用 ∀i 而不是兩端的交",
    bound && differ > 0,
  )
  let i0 = dnf_nvar(0)
  let i1 = dnf_var(0)
  chk(
    out,
    "CCHM 表：∀i.(i=0) = ∀i.(i=1) = ∀i.((i=0)∨(i=1)) = 0、∀i.1 = 1、∀i.(j=1) = (j=1)",
    face_forall(i0, 0) == dnf_zero() &&
    face_forall(i1, 0) == dnf_zero() &&
    face_forall(dnf_join(i0, i1), 0) == dnf_zero() &&
    face_forall(dnf_one(), 0) == dnf_one() &&
    face_forall(dnf_var(1), 0) == dnf_var(1),
  )
  chk(
    out, "Beck–Chevalley：量詞與另一方向的面代換 (j := b) 交換",
    bc,
  )
  // n = 3：𝔽(3) 太大，改用確定性的偽隨機樣本
  let mut s = 20261110L
  let mut sample_ok = true
  let mut samples = 0
  let rand_form = () => {
    let cs : Array[Int32] = []
    s = lcg(s)
    let k = 1 + ((s >> 33) % 4L).to_int()
    for _ in 0..<k {
      s = lcg(s)
      let c = ((s >> 30) % 64L).to_int()
      if clause_consistent(c) {
        cs.push(c)
      }
    }
    dnf_norm(cs)
  }
  for _ in 0..<400 {
    let phi = rand_form()
    let psi0 = rand_form()
    for i in 0..<3 {
      samples = samples + 1
      let psi = face_forall(psi0, i)
      let ex = face_exists(phi, i)
      let fa = face_forall(phi, i)
      if dnf_leq(ex, psi) != dnf_leq(phi, psi) ||
        dnf_leq(psi, fa) != dnf_leq(psi, phi) ||
        face_exists(face_norm(dnf_meet(phi, psi)), i) !=
        face_norm(dnf_meet(ex, psi)) ||
        face_forall(dnf_join(phi, psi0), i) != dnf_join(fa, psi) {
        sample_ok = false
      }
    }
  }
  chk(
    out,
    "n = 3：\{samples} 組偽隨機 (φ,ψ,i) 上伴隨、Frobenius、∀ 保 ∨ 同樣成立",
    sample_ok,
  )
  out
}
