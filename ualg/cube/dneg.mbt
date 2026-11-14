// ---------------------------------------------------------------------------
// ualg/cube — 大項二：面格 𝔽(n) 上的雙重否定核子（cubical double negation）
// ---------------------------------------------------------------------------
//
// 預層模板裡的 j = ¬¬ 在這裡不是比喻，而是立方體子複形格上的具體算子：
//   j(u) = { f ∈ □ⁿ : f 的全部頂點都屬於 u }（頂點閉包）。
// [T-Cube-1]  j = hneg∘hneg（site 的 Heyting 路徑）= 頂點閉包（獨立路徑），
//             n = 1, 2, 3 的全部開集逐一比對。
// [T-Cube-2]  j 是核子：u ≤ j(u)、j(j(u)) = j(u)、j(u∧v) = j(u)∧j(v)
//             （n ≤ 2 窮舉全部開集對；n = 3 二元交以 1200 對偽隨機抽樣）。
// [T-Cube-3]  Glivenko：Fix(¬¬) = { u_S : S ⊆ 頂點 }，S ↦ u_S 是
//             P(頂點) ≅ Fix(¬¬) 的布林代數同構；補元 ¬u_S = u_{~S}。
//             正則子複形數 4、16、256（n = 1, 2, 3）。
// [T-Cube-4]  j ⊣ i（i = Fix(¬¬) ↪ Ω）：j(u) ≤ v ⇔ u ≤ v（v 取正則開集）。
// [T-Cube-5]  [T-Bool] 的第三條路徑：DM(n) 的布林反射同餘 = j 的核
//             （hneg-路徑 = 頂點路徑）；類數 4、16。
// [T-Cube-6]  ∂σ 與 ↓σ 有相同的 ¬¬（球面與填充不可分）；j 不保併（反例計數）；
//             量詞與 j 的交換實驗（∃i、∀i，誠實回報反例數）。

///|
fn chk(out : Array[(String, Bool)], label : String, cond : Bool) -> Unit {
  out.push((label, cond))
}

///|
fn lcg(s : Int64) -> Int64 {
  (s * 6364136223846793005L + 1442695040888963407L) & 0x7fffffffffffffffL
}

///|
/// 定律：立方體面格上的雙重否定核子。
pub fn law_double_negation_nucleus_cubical() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let q1 = @site.poset_cube(1)
  let q2 = @site.poset_cube(2)
  let q3 = @site.poset_cube(3)
  let o1 = @site.opens_all(q1)
  let o2 = @site.opens_all(q2)
  let o3 = @site.opens_all(q3)
  // ---- 0. 規模對帳：V³ 的開集數 = 面格遞推 = 15,936 -----------------------
  chk(
    out,
    "規模：|O(V¹)| = \{o1.length()}、|O(V²)| = \{o2.length()}、|O(V³)| = \{o3.length()} = face_count_recursive(3) = \{@demorgan.face_count_recursive(3)}",
    o1.length() == 5 &&
    o2.length() == 48 &&
    o3.length() == 15936 &&
    @demorgan.face_count_recursive(3) == o3.length().to_int64(),
  )
  // ---- 1. 兩條路徑：hneg∘hneg（Heyting）= 頂點閉包 -------------------------
  let mut agree = true
  for pair in [(1, o1), (2, o2), (3, o3)] {
    let (n, opens) = pair
    let p = @site.poset_cube(n)
    let j = @site.j_dneg(p)
    for u in opens {
      if j(u) != dneg_vertex(n, u) {
        agree = false
      }
    }
  }
  chk(
    out,
    "[T-Cube-1] 兩條獨立路徑逐一相同：hneg∘hneg = 「f 的頂點全在 u」（n = 1, 2, 3，\{o1.length() + o2.length() + o3.length()} 個開集）",
    agree,
  )
  // ---- 2. 核子公理 ----------------------------------------------------------
  let mut unary = true
  for pair in [(1, o1), (2, o2), (3, o3)] {
    let (n, opens) = pair
    for u in opens {
      let ju = dneg_vertex(n, u)
      if (u & ju) != u || dneg_vertex(n, ju) != ju || (u != 0 && ju == 0) {
        unary = false
      }
    }
  }
  chk(
    out, "核子（一元）：u ≤ j(u) 且 j(j(u)) = j(u)（n = 1, 2, 3 全部開集；j(∅) = ∅）",
    unary,
  )
  let mut meet = true
  for u in o1 {
    for v in o1 {
      if dneg_vertex(1, u & v) != (dneg_vertex(1, u) & dneg_vertex(1, v)) {
        meet = false
      }
    }
  }
  for u in o2 {
    for v in o2 {
      if dneg_vertex(2, u & v) != (dneg_vertex(2, u) & dneg_vertex(2, v)) {
        meet = false
      }
    }
  }
  let mut s = 20261110L
  for _ in 0..<1200 {
    s = lcg(s)
    let u = o3[((s >> 33) % o3.length().to_int64()).to_int()]
    s = lcg(s)
    let v = o3[((s >> 33) % o3.length().to_int64()).to_int()]
    if dneg_vertex(3, u & v) != (dneg_vertex(3, u) & dneg_vertex(3, v)) {
      meet = false
    }
  }
  chk(
    out,
    "核子（二元）：j(u∧v) = j(u)∧j(v)（n ≤ 2 窮舉 \{o1.length() * o1.length() + o2.length() * o2.length()} 對；n = 3 偽隨機 1200 對）",
    meet,
  )
  // ---- 3. Glivenko：Fix(¬¬) ≅ P(頂點) -------------------------------------
  let reg_counts : Array[Int32] = []
  let mut gliv = true
  for pair in [(1, o1), (2, o2), (3, o3)] {
    let (n, opens) = pair
    let p = @site.poset_cube(n)
    let j = @site.j_dneg(p)
    let fixed = @site.fixed_points(opens, j)
    reg_counts.push(fixed.length())
    let full = (1 << (1 << n)) - 1
    let seen : Map[Int32, Bool] = Map([])
    let mut boolops = true
    for sv in 0..<(1 << (1 << n)) {
      let u_s = vertex_closure(n, sv)
      if !@site.is_open(p, u_s) || j(u_s) != u_s {
        boolops = false
      }
      seen[u_s] = true
      if @site.hneg(p, u_s) != vertex_closure(n, full ^ sv) {
        boolops = false
      }
      for tv in [0, 1, full ^ sv, full] {
        // Fix(j) 的併 = j(u∨v)（不是 u∨v：j 不保併，見下一條對照）
        if vertex_closure(n, sv | tv) != j(u_s | vertex_closure(n, tv)) {
          boolops = false
        }
        // 交被 j 保住，且就是 u_{S∩T}
        if vertex_closure(n, sv & tv) != (u_s & vertex_closure(n, tv)) {
          boolops = false
        }
      }
    }
    if seen.length() != 1 << (1 << n) ||
      !boolops ||
      fixed.length() != 1 << (1 << n) {
      gliv = false
    }
  }
  chk(
    out,
    "Glivenko：正則子複形數 \{@core.show_ints(reg_counts)} = 2^{2ⁿ}；S ↦ u_S 雙射、保補（¬u_S = u_{~S}）、交保住、併為 j(u∨v)——Fix(¬¬) ≅ P(頂點) 布林代數",
    gliv,
  )
  // ---- 4. j ⊣ i：層化在 Ω 上的伴隨（面格版） --------------------------------
  let mut adj = true
  for pair in [(1, o1), (2, o2), (3, o3)] {
    let (n, opens) = pair
    let p = @site.poset_cube(n)
    let j = @site.j_dneg(p)
    let fixed = @site.fixed_points(opens, j)
    for u in opens {
      for v in fixed {
        if ((j(u) & v) == j(u)) != ((u & v) == u) {
          adj = false
        }
      }
    }
  }
  chk(
    out, "j ⊣ i：j(u) ≤ v ⇔ u ≤ v（v 取遍全部正則開集；n ≤ 3）",
    adj,
  )
  // ---- 5. [T-Bool] 第三條路徑：DM(n) 的布林反射核 = j 的核 -----------------
  let kernel_counts : Array[Int32] = []
  let mut kernel_ok = true
  for n in 1..<=2 {
    let elems = @demorgan.dm_elements(n)
    let p = @site.poset_cube(n)
    let m = elems.length()
    let labels_hneg = Array::make(m, 0)
    let labels_vert = Array::make(m, 0)
    let map_h : Map[Int32, Int32] = Map([])
    let map_v : Map[Int32, Int32] = Map([])
    let jh = @site.j_dneg(p)
    for i, f in elems {
      let u = @demorgan.face_open(p, @demorgan.face_norm(f), n)
      let a = jh(u)
      let b = dneg_vertex(n, u)
      match map_h.get(a) {
        Some(v) => labels_hneg[i] = v
        None => {
          let v = map_h.length()
          map_h[a] = v
          labels_hneg[i] = v
        }
      }
      match map_v.get(b) {
        Some(v) => labels_vert[i] = v
        None => {
          let v = map_v.length()
          map_v[b] = v
          labels_vert[i] = v
        }
      }
    }
    kernel_counts.push(map_h.length())
    let ph = @core.part_norm(labels_hneg)
    let pv = @core.part_norm(labels_vert)
    if !@core.part_leq(ph, pv) ||
      !@core.part_leq(pv, ph) ||
      map_h.length() != 1 << (1 << n) {
      kernel_ok = false
    }
  }
  chk(
    out,
    "[T-Bool-cube] DM(n) 布林反射的核 = j 的核（hneg 路徑 = 頂點路徑）；類數 \{@core.show_ints(kernel_counts)} = 2^{2ⁿ}",
    kernel_ok,
  )
  // ---- 6. ∂σ 與 ↓σ 不可分；j 不保併 ----------------------------------------
  let mut sphere = true
  let mut sphere_cases = 0
  for n in 1..<=3 {
    let p = @site.poset_cube(n)
    let j = @site.j_dneg(p)
    for sigma in 0..<@demorgan.pow3(n) {
      if @demorgan.face_dim(sigma, n) == 0 {
        continue // σ 是頂點：∂σ = ∅ 而 ↓σ = {σ}，否定之見下一條對照
      }
      sphere_cases = sphere_cases + 1
      if j(face_boundary(p, sigma)) != j(p.down[sigma]) {
        sphere = false
      }
    }
  }
  let mut join_fail = 0
  for u in o1 {
    for v in o1 {
      if dneg_vertex(1, u | v) != (dneg_vertex(1, u) | dneg_vertex(1, v)) {
        join_fail = join_fail + 1
      }
    }
  }
  for u in o2 {
    for v in o2 {
      if dneg_vertex(2, u | v) != (dneg_vertex(2, u) | dneg_vertex(2, v)) {
        join_fail = join_fail + 1
      }
    }
  }
  chk(
    out,
    "∂σ 與 ↓σ 的 ¬¬ 相同（\{sphere_cases} 個維數 ≥ 1 的面，n ≤ 3；σ = 頂點時 ∂σ = ∅ ≠ {σ} = j(↓σ)）",
    sphere,
  )
  chk(
    out,
    "反例對照：j 不保併（n = 1, 2 的開集對中共 \{join_fail} 組 j(u∨v) ≠ j(u)∨j(v)）；j(∅) = ∅、j(⊤) = ⊤",
    join_fail > 0 &&
    dneg_vertex(2, 0) == 0 &&
    dneg_vertex(2, @site.full_mask(q2)) == @site.full_mask(q2),
  )
  // ---- 7. 量詞與 ¬¬ 的交換實驗（誠實回報，不預判方向） ----------------------
  let mut ex_diff = 0
  let mut fa_diff = 0
  for u in o2 {
    let phi = @demorgan.open_face(q2, u, 2)
    let jphi = @demorgan.open_face(q2, dneg_vertex(2, u), 2)
    for i in 0..<2 {
      // j(∃i u) ?= ∃i(j u)
      let a = dneg_vertex(
        2,
        @demorgan.face_open(q2, @demorgan.face_exists(phi, i), 2),
      )
      let b = @demorgan.face_open(q2, @demorgan.face_exists(jphi, i), 2)
      if a != b {
        ex_diff = ex_diff + 1
      }
      // j(∀i u) ?= ∀i(j u)
      let c = dneg_vertex(
        2,
        @demorgan.face_open(q2, @demorgan.face_forall(phi, i), 2),
      )
      let d = @demorgan.face_open(q2, @demorgan.face_forall(jphi, i), 2)
      if c != d {
        fa_diff = fa_diff + 1
      }
    }
  }
  chk(
    out,
    "量詞×¬¬（𝔽(2) 全部 48 個公式 × 2 個方向 i）：j∃i ≠ ∃i j 共 \{ex_diff} 組、j∀i ≠ ∀i j 共 \{fa_diff} 組——量詞不與布林化交換",
    ex_diff == 4 && fa_diff == 44,
  )
  out
}
