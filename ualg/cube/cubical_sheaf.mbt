// ---------------------------------------------------------------------------
// ualg/cube — 大項一（續）：立方體上層化的定律
// ---------------------------------------------------------------------------

///|
/// 把 j 預先算好存進遮罩表（稠密核子：只碰 opens）。
fn memo_j(opens : Array[Int32], j : (Int32) -> Int32) -> (Int32) -> Int32 {
  let table : Map[Int32, Int32] = Map([])
  for u in opens {
    table[u] = j(u)
  }
  u => {
    match table.get(u) {
      Some(v) => v
      None => j(u)
    }
  }
}

///|
/// 定律：立方體上的層化。
pub fn law_cubical_sheafification() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let p1 = @site.poset_cube(1)
  let p2 = @site.poset_cube(2)
  let p3 = @site.poset_cube(3)
  let o1 = @site.opens_all(p1)
  let o2 = @site.opens_all(p2)
  let o3 = @site.opens_all(p3)
  let j1 = memo_j(o1, @site.j_dneg(p1))
  let j2 = memo_j(o2, @site.j_dneg(p2))
  let j3 = memo_j(o3, @site.j_dneg(p3))
  // ---- 1. 偏序的積 = 立方體 -------------------------------------------------
  let q12 = @site.poset_product(@site.poset_v(), @site.poset_v())
  let q13 = @site.poset_product(@site.poset_v(), q12)
  let prod_iso = q12.n == p2.n &&
    q13.n == p3.n &&
    q12.down == p2.down &&
    q12.up == p2.up &&
    q13.down == p3.down &&
    q13.up == p3.up
  chk(
    out, "偏序積：V×V ≅ V²、V×V² ≅ V³（down/up 遮罩逐一相同）",
    prod_iso,
  )
  let pool_v = all_presheaves_v()
  // ---- 2. Sub(1)(PSh) ≅ Ω 的子終 = 子複形；層 ⇔ 正則 -----------------------
  // n = 1, 2：對全部子複形直接驗 is_sheaf；n = 3：以 j(K) = K 的格刻畫驗
  // （15,936 個），並對 4 個代表元直接驗 is_sheaf。
  let mut sub_sheaf1 = 0
  let mut rho1 = true
  for u in o1 {
    let f = @site.psh_sub(p1, u)
    if @site.is_sheaf(p1, o1, j1, f) {
      sub_sheaf1 = sub_sheaf1 + 1
      if !rho_bijective(p1, f) {
        rho1 = false
      }
    }
  }
  let mut sub_sheaf2 = 0
  let mut rho2 = true
  for u in o2 {
    let f = @site.psh_sub(p2, u)
    if @site.is_sheaf(p2, o2, j2, f) {
      sub_sheaf2 = sub_sheaf2 + 1
      if !rho_bijective(p2, f) {
        rho2 = false
      }
    }
  }
  let mut sub_reg3 = 0
  for u in o3 {
    if dneg_vertex(3, u) == u {
      sub_reg3 = sub_reg3 + 1
    }
  }
  // V³ 的代表元直接檢查
  let top3 = @site.full_mask(p3)
  let boundary3 = top3 ^ (1 << (p3.n - 1))
  let regular3 = [0, vertex_closure(3, 0b10101010), top3]
  let mut spot3 = true
  for u in regular3 {
    if !@site.is_sheaf(p3, o3, j3, @site.psh_sub(p3, u)) {
      spot3 = false
    }
  }
  if @site.is_sheaf(p3, o3, j3, @site.psh_sub(p3, boundary3)) {
    spot3 = false
  }
  chk(
    out,
    "[T-Cube-S2] 子終預層 = 子複形：¬¬-層的個數 \{sub_sheaf1}、\{sub_sheaf2}、\{sub_reg3} = 2^{2ⁿ}（n = 1, 2 以 is_sheaf 窮舉；n = 3 以格刻畫窮舉 + 4 個代表元直接檢查）",
    sub_sheaf1 == 4 && sub_sheaf2 == 16 && sub_reg3 == 256 && spot3,
  )
  chk(
    out,
    "[T-Cube-S1] 層的 ρ 逐點雙射（V¹、V² 全部子終層）",
    rho1 && rho2,
  )
  // §2b. 顯式同構 F ≅ F̂(F|頂點)：ρ 是自然同構
  let mut explicit_iso = true
  let mut iso_count = 0
  for f in pool_v {
    if !@site.is_sheaf(p1, o1, j1, f) {
      continue
    }
    iso_count = iso_count + 1
    let fhat = psh_vertex(1, vert_sizes_of(1, f))
    if !@site.psh_ok(p1, fhat) ||
      !@site.is_natural(p1, f, fhat, rho_eta(p1, f)) ||
      !@site.is_iso(f, fhat, rho_eta(p1, f)) {
      explicit_iso = false
    }
  }
  for u in o2 {
    let f = @site.psh_sub(p2, u)
    if !@site.is_sheaf(p2, o2, j2, f) {
      continue
    }
    let fhat = psh_vertex(2, vert_sizes_of(2, f))
    if !@site.psh_ok(p2, fhat) ||
      !@site.is_natural(p2, f, fhat, rho_eta(p2, f)) ||
      !@site.is_iso(f, fhat, rho_eta(p2, f)) {
      explicit_iso = false
    }
  }
  chk(
    out,
    "[T-Cube-S1] 顯式同構 F ≅ F̂(F|頂點)：ρ 是自然同構（V¹ \{iso_count} 個層 + V² 16 個子終層）",
    explicit_iso,
  )
  // ---- 3. 子複形的層化 = 頂點閉包 -----------------------------------------
  let mut fill1 = true
  for u in o1 {
    let (af, _, valid) = @site.sheafify(p1, o1, j1, @site.psh_sub(p1, u))
    if !valid || af.size != sizes_of_vertex_closure(p1, 1, u) {
      fill1 = false
    }
  }
  let mut fill2 = true
  for u in o2 {
    let (af, _, valid) = @site.sheafify(p2, o2, j2, @site.psh_sub(p2, u))
    if !valid || af.size != sizes_of_vertex_closure(p2, 2, u) {
      fill2 = false
    }
  }
  // V³：代表元（4 個）+ 60 個 LCG 子複形
  let mut fill3 = true
  let mut s3 = 99173L
  let mut checked3 = 0
  let mut k = 0
  while k < 60 {
    s3 = lcg64(s3)
    let u = o3[((s3 >> 33) % o3.length().to_int64()).to_int()]
    s3 = lcg64(s3)
    let extra = o3[((s3 >> 33) % o3.length().to_int64()).to_int()]
    let cand = u & extra
    if @site.is_open(p3, cand) {
      k = k + 1
      checked3 = checked3 + 1
      let (af, _, valid) = @site.sheafify(p3, o3, j3, @site.psh_sub(p3, cand))
      if !valid || af.size != sizes_of_vertex_closure(p3, 3, cand) {
        fill3 = false
      }
    }
  }
  chk(
    out,
    "[T-Cube-S2] a(K) = 頂點閉包 u_{verts K}（V¹、V² 全部 5、48 個子複形；V³ \{checked3} 個樣本，含公式對帳）",
    fill1 && fill2 && fill3,
  )
  // ---- 4. a(F) 的公式 ∏_{v≤x}|F(v)|；冪等；層 ⇔ η 同構 ---------------------
  let mut formula_v = true
  let mut sheaf_v = true
  let mut idem_v = true
  let mut iff_v = true
  let mut eta_nat = true
  let mut n_sheaves_v = 0
  for f in pool_v {
    if !@site.psh_ok(p1, f) {
      formula_v = false
    }
    let (af, eta, valid) = @site.sheafify(p1, o1, j1, f)
    if !valid || af.size != formula_sizes(p1, f) {
      formula_v = false
    }
    if !@site.is_sheaf(p1, o1, j1, af) {
      sheaf_v = false
    }
    let (aaf, eta2, valid2) = @site.sheafify(p1, o1, j1, af)
    if !valid2 || !@site.is_iso(af, aaf, eta2) {
      idem_v = false
    }
    if !@site.is_natural(p1, f, af, eta) {
      eta_nat = false
    }
    let sh = @site.is_sheaf(p1, o1, j1, f)
    if sh {
      n_sheaves_v = n_sheaves_v + 1
    }
    if sh != @site.is_iso(f, af, eta) {
      iff_v = false
    }
  }
  chk(
    out,
    "[T-Cube-S3] a(F)(x) = ∏_{v≤x}|F(v)|（V¹ 全部 70 個大小 ≤ 2 的預層；其中 \{n_sheaves_v} 個本來就是層）；aF 是層、η 自然",
    formula_v && sheaf_v && eta_nat,
  )
  chk(
    out,
    "[T-Cube-S3] 冪等 a(aF) ≅ aF；F 是層 ⇔ η_F 是同構（70 個全部檢查）",
    idem_v && iff_v,
  )
  // V²：子終 + 常數 + LCG 隨機函子
  let mut formula_2 = true
  let mut idem_2 = true
  let mut n_2 = 0
  let pool2 : Array[@site.Presheaf] = []
  for u in o2 {
    pool2.push(@site.psh_sub(p2, u))
  }
  for k in 1..<=4 {
    pool2.push(@site.psh_const(p2, k))
  }
  for f in random_presheaves_v2(60, 42424243L) {
    pool2.push(f)
  }
  for f in pool2 {
    if !@site.psh_ok(p2, f) {
      formula_2 = false
      continue
    }
    n_2 = n_2 + 1
    let (af, _, valid) = @site.sheafify(p2, o2, j2, f)
    if !valid || af.size != formula_sizes(p2, f) {
      formula_2 = false
    }
    let (aaf, eta2, valid2) = @site.sheafify(p2, o2, j2, af)
    if !valid2 || !@site.is_iso(af, aaf, eta2) {
      idem_2 = false
    }
  }
  chk(
    out,
    "[T-Cube-S3] a(F) 的公式與冪等（V²：48 子終 + 4 常數 + 60 LCG 合法預層，共 \{n_2} 個）",
    formula_2 && idem_2,
  )
  // V³：常數（Δ2, Δ3）公式（a(Δk)(x) = k^{#頂點≤x}）
  let mut formula_3 = true
  for k in 2..<=3 {
    let f = @site.psh_const(p3, k)
    let (af, _, valid) = @site.sheafify(p3, o3, j3, f)
    let expected = Array::makei(p3.n, x => {
      let mins = min_below(p3, x)
      let mut prod = 1
      for _ in mins {
        prod = prod * k
      }
      prod
    })
    if !valid ||
      af.size != expected ||
      !@site.is_natural(p3, f, af, @site.sheafify(p3, o3, j3, f).1) {
      formula_3 = false
    }
  }
  chk(
    out, "[T-Cube-S3] a(Δ2)、a(Δ3) 在 V³：|F(x)| = k^{2^{dim x}}（頂點 2、3、棱 4、9、面 16、81、方體 256、6561——字面算出）",
    formula_3,
  )
  // ---- 5. Künneth：a(F ⊠ G) ≅ aF ⊠ aG；a(F × G)、a(F + G) -------------------
  let tensor_pool : Array[@site.Presheaf] = [
    @site.psh_const(p1, 1),
    @site.psh_const(p1, 2),
    @site.psh_sub(p1, 0b001),
    @site.psh_sub(p1, 0b010),
    @site.psh_sub(p1, 0b011),
    @site.psh_sub(p1, 0b111),
  ]
  let mut kunneth = true
  let mut tested = 0
  for f in pool_v {
    for g in tensor_pool {
      let fg = psh_tensor(p1, p1, f, g)
      if !@site.psh_ok(p2, fg) {
        kunneth = false
        continue
      }
      let (afg, _, v1) = @site.sheafify(p2, o2, j2, fg)
      let (af, _, v2) = @site.sheafify(p1, o1, j1, f)
      let (ag, _, v3) = @site.sheafify(p1, o1, j1, g)
      // a 只經由頂點決定：a(aF⊠aG) = a(F⊠G)
      let (a2, _, vB) = @site.sheafify(p2, o2, j2, psh_tensor(p1, p1, af, ag))
      if !(v1 && v2 && v3 && vB) || afg.size != a2.size {
        kunneth = false
      }
      // 逐點積：i 右伴隨保極限 ⇒ 層的積仍是層，且 a(F×G) ≅ aF×aG（頂點上相同）
      let ftg = psh_times(p1, f, g)
      if @site.psh_ok(p1, ftg) {
        let (aftg, _, v4) = @site.sheafify(p1, o1, j1, ftg)
        let (af2, _, v5) = @site.sheafify(p1, o1, j1, f)
        let (ag2, _, v6) = @site.sheafify(p1, o1, j1, g)
        let t = psh_times(p1, af2, ag2)
        if !(v4 && v5 && v6) || aftg.size != t.size {
          kunneth = false
        }
      }
      // 逐點餘積：a 左伴隨 ⇒ a 保 Sh-餘積：a(F+G) ≅ a(aF+aG)（不是 aF+aG！）
      let fsg = psh_sum(p1, f, g)
      let (afsg, _, v7) = @site.sheafify(p1, o1, j1, fsg)
      let (af3, _, v8) = @site.sheafify(p1, o1, j1, f)
      let (ag3, _, v9) = @site.sheafify(p1, o1, j1, g)
      let (fa3, _, vA) = @site.sheafify(p1, o1, j1, psh_sum(p1, af3, ag3))
      if !(v7 && v8 && v9 && vA) || afsg.size != fa3.size {
        kunneth = false
      }
      tested = tested + 1
    }
  }
  chk(
    out,
    "[T-Cube-S4] 層化只經由頂點決定：a(aF⊠aG) = a(F⊠G)（Künneth）、a(F×G) = aF×aG、a(F+G) = a(aF+aG)（Sh-餘積）（\{tested} 對）",
    kunneth,
  )
  // ---- 6. Ω_¬¬ 的維數公式 ---------------------------------------------------
  let omega1 = @site.psh_omega(p1, o1, j1)
  let omega2 = @site.psh_omega(p2, o2, j2)
  let omega3 = @site.psh_omega(p3, o3, j3)
  let formula1 : Array[Int32] = Array::makei(p1.n, x => {
    let d = @demorgan.face_dim(x, 1)
    1 << (1 << d)
  })
  let formula2 : Array[Int32] = Array::makei(p2.n, x => {
    let d = @demorgan.face_dim(x, 2)
    1 << (1 << d)
  })
  let formula3 : Array[Int32] = Array::makei(p3.n, x => {
    let d = @demorgan.face_dim(x, 3)
    1 << (1 << d)
  })
  let omega_id = @site.psh_omega(p2, o2, u => u)
  chk(
    out,
    "[T-Cube-S5] |Ω_¬¬(x)| = 2^{2^{dim x}}：V¹ → \{@core.show_ints(omega1.size)}、V² → \{@core.show_ints(omega2.size)}、V³ → \{@core.show_ints(formula3)}（字面算出）",
    omega1.size == formula1 &&
    omega2.size == formula2 &&
    omega3.size == formula3,
  )
  chk(
    out,
    "[T-Cube-S5] 對照：id-核子的 Ω_id(V²) 大小 = \{@core.show_ints(omega_id.size)} ≠ 2^{2^{dim·}}——維數公式是 ¬¬ 特有的",
    omega_id.size != formula2,
  )
  // ---- 7. a ⊣ i 的計數與 Nat 的頂點公式 -------------------------------------
  let mut adj = true
  let mut nat_count_v = 0
  let gs_v = [@site.psh_omega(p1, o1, j1), @site.psh_const(p1, 1)]
  for g in gs_v {
    for f in pool_v {
      let af = @site.sheafify(p1, o1, j1, f).0
      if af.size[2] > 6 {
        continue
      }
      if @site.count_nat(p1, af, g) != @site.count_nat(p1, f, g) {
        adj = false
      }
      nat_count_v = nat_count_v + 1
    }
  }
  chk(
    out,
    "[T-Cube-S6] a ⊣ i：|Nat(aF,G)| = |Nat(F,G)|（V¹，G = Ω_¬¬、Δ1，\{nat_count_v} 對計數）",
    adj,
  )
  // V²：子終層 F 對 G = Ω_¬¬(V²)、Δ1 的伴隨計數
  let mut adj2 = true
  let mut cnt2 = 0
  for u in o2 {
    let f = @site.psh_sub(p2, u)
    if !@site.is_sheaf(p2, o2, j2, f) {
      continue
    }
    let af = @site.sheafify(p2, o2, j2, f).0
    for g in [omega2, @site.psh_const(p2, 1)] {
      if @site.count_nat(p2, af, g) != @site.count_nat(p2, f, g) {
        adj2 = false
      }
      cnt2 = cnt2 + 1
    }
  }
  chk(
    out,
    "[T-Cube-S6] a ⊣ i（V²）：|Nat(aF,G)| = |Nat(F,G)|（F、G ∈ 子終層與 Δ1，\{cnt2} 對計數）",
    adj2,
  )
  // 反例對照
  let f_ctl = @site.psh_make(p1, [2, 2, 0], (y, x, s) => {
    if y == x {
      s
    } else if x == 0 {
      [0, 1][s]
    } else {
      [0, 0][s]
    }
  })
  let af_ctl = @site.sheafify(p1, o1, j1, f_ctl).0
  let n_f = @site.count_nat(p1, f_ctl, @site.psh_omega(p1, o1, u => u))
  let n_af = @site.count_nat(p1, af_ctl, @site.psh_omega(p1, o1, u => u))
  chk(
    out,
    "[T-Cube-S6] 反例對照：G = Ω（非層）時計數不等——|Nat(F,Ω)| = \{n_f} ≠ |Nat(aF,Ω)| = \{n_af}",
    n_f != n_af,
  )
  // Nat 的頂點公式（層 F、G）
  let sheaves_v : Array[@site.Presheaf] = []
  for f in pool_v {
    if @site.is_sheaf(p1, o1, j1, f) {
      sheaves_v.push(f)
    }
  }
  let mut natf = true
  let mut pairs = 0
  for f in sheaves_v {
    for g in sheaves_v {
      if @site.count_nat(p1, f, g) != nat_product(p1, f, g) {
        natf = false
      }
      pairs = pairs + 1
    }
  }
  chk(
    out,
    "[T-Cube-S6] 層 F、G：|Nat(F,G)| = ∏_{頂點 v} |G(v)|^|F(v)|（V¹，\{pairs} 對）",
    natf,
  )
  out
}

///|
/// 頂點閉包對應預層的逐點大小（層的候選）：|a(psh_sub K)(x)| ∈ {0,1}。
fn sizes_of_vertex_closure(
  p : @site.Poset,
  n : Int32,
  u : Int32,
) -> Array[Int32] {
  let vc = vertex_closure(n, open_vertex_mask(n, u))
  Array::makei(p.n, x => if ((vc >> x) & 1) == 1 { 1 } else { 0 })
}

///|
/// a(F) 的公式：∏_{v ∈ Min, v ≤ x} |F(v)|。
fn formula_sizes(p : @site.Poset, f : @site.Presheaf) -> Array[Int32] {
  Array::makei(p.n, x => {
    let mut prod = 1
    for v in min_below(p, x) {
      prod = prod * f.size[v]
    }
    prod
  })
}
