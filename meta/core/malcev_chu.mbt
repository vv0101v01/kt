// ---------------------------------------------------------------------------
// meta/core — 構造性泛代數：同餘關係、商代數、吸收零／點化零與瑪爾切夫算子
// ---------------------------------------------------------------------------
//
// 核心定理（皆以有限載體窮舉重算，不引用外部假設）：
//   1. [T-Malcev-Permute] 瑪爾切夫算子 p(x,x,y)=y, p(x,y,y)=x 蘊含同餘一步可換
//      θ∘ψ = ψ∘θ，故同餘聯 θ∨ψ = θ∘ψ 免傳遞閉包；非瑪爾切夫格給出明確反例。
//   2. [T-Quotient-First-Iso] 同餘商代數 A/θ 良定義，且 A/ker(f) ≅ im(f)。
//   3. [T-Absorb-Zero-Dichotomy] 二元載體 {0,1} 上全體 256 個三元運算中恰有 4 個
//      瑪爾切夫算子；與具吸收元 0 之 ∧ 相容者為 0 個（吸收塌縮），與具中性零元 0
//      之 ⊕ 相容者恰有 1 個（x⊕y⊕z，Eckmann–Hilton 可加群結構）。
//   4. [T-Pol-Inv-Galois] 泛代數多態與不變關係構成反單調伽羅瓦連接 Pol ⊣ Inv。
//   5. [T-Malcev-Groupoid-Matroid-Ramsey] 瑪爾切夫內蘊自反圖誘導唯一內蘊群胚；
//      仿射瑪爾切夫生成秩滿足擬陣交換公理，且 K_6 主同餘著色必含單色三角形。

///|
/// 等價關係（n×n 布林矩陣）檢查：自反、對稱、遞移。
pub fn ua_is_equiv(n : Int32, rel : Array[Array[Bool]]) -> Bool {
  if rel.length() != n {
    return false
  }
  for i in 0..<n {
    if rel[i].length() != n || !rel[i][i] {
      return false
    }
    for j in 0..<n {
      if rel[i][j] != rel[j][i] {
        return false
      }
      for k in 0..<n {
        if rel[i][j] && rel[j][k] && !rel[i][k] {
          return false
        }
      }
    }
  }
  true
}

///|
/// 二元關係一步複合 `(r ∘ s)[x][z] = ∃y. r[x][y] ∧ s[y][z]`。
pub fn ua_rel_comp(
  n : Int32,
  r : Array[Array[Bool]],
  s : Array[Array[Bool]],
) -> Array[Array[Bool]] {
  let out : Array[Array[Bool]] = []
  for x in 0..<n {
    let row = Array::make(n, false)
    for z in 0..<n {
      let mut hit = false
      for y in 0..<n {
        if r[x][y] && s[y][z] {
          hit = true
          break
        }
      }
      row[z] = hit
    }
    out.push(row)
  }
  out
}

///|
/// 等價關係聯集之傳遞閉包 `r ∨ s`（一般對照組）。
pub fn ua_equiv_join_closure(
  n : Int32,
  r : Array[Array[Bool]],
  s : Array[Array[Bool]],
) -> Array[Array[Bool]] {
  let cur : Array[Array[Bool]] = []
  for i in 0..<n {
    let row = Array::make(n, false)
    for j in 0..<n {
      row[j] = i == j || r[i][j] || s[i][j]
    }
    cur.push(row)
  }
  for k in 0..<n {
    for i in 0..<n {
      for j in 0..<n {
        if cur[i][k] && cur[k][j] {
          cur[i][j] = true
        }
      }
    }
  }
  cur
}

///|
/// 檢查三元運算 `p` 是否滿足瑪爾切夫恆等式 `p(x,x,y)=y` 與 `p(x,y,y)=x`。
pub fn ua_is_malcev_op(n : Int32, p : (Int32, Int32, Int32) -> Int32) -> Bool {
  for x in 0..<n {
    for y in 0..<n {
      if p(x, x, y) != y || p(x, y, y) != x {
        return false
      }
    }
  }
  true
}

///|
/// 檢查等價關係 `rel` 是否為三元運算 `p` 的同餘關係。
pub fn ua_is_ternary_congruence(
  n : Int32,
  rel : Array[Array[Bool]],
  p : (Int32, Int32, Int32) -> Int32,
) -> Bool {
  if !ua_is_equiv(n, rel) {
    return false
  }
  for x1 in 0..<n {
    for x2 in 0..<n {
      if rel[x1][x2] {
        for y1 in 0..<n {
          for y2 in 0..<n {
            if rel[y1][y2] {
              for z1 in 0..<n {
                for z2 in 0..<n {
                  if rel[z1][z2] && !rel[p(x1, y1, z1)][p(x2, y2, z2)] {
                    return false
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  true
}

///|
/// 由函數核 `ker(f)` 產生等價關係：`x ~ y ⇔ f(x) == f(y)`。
pub fn ua_kernel_congruence(
  n : Int32,
  f : (Int32) -> Int32,
) -> Array[Array[Bool]] {
  let out : Array[Array[Bool]] = []
  for i in 0..<n {
    let row = Array::make(n, false)
    for j in 0..<n {
      row[j] = f(i) == f(j)
    }
    out.push(row)
  }
  out
}

///|
/// 商代數典範代表元列表與投影映射 `π : A -> {0..k-1}`。
pub fn ua_quotient_classes(
  n : Int32,
  rel : Array[Array[Bool]],
) -> (Array[Int32], Array[Int32]) {
  let reps : Array[Int32] = []
  let proj = Array::make(n, -1)
  for x in 0..<n {
    if proj[x] < 0 {
      let cid = reps.length()
      reps.push(x)
      for y in 0..<n {
        if rel[x][y] {
          proj[y] = cid
        }
      }
    }
  }
  (reps, proj)
}

///|
pub fn law_malcev_congruence_permutability_and_one_step_join() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // Z/6Z 上的仿射瑪爾切夫算子 p(x,y,z) = (x - y + z) mod 6
  let n = 6
  let p_z6 = fn(x : Int32, y : Int32, z : Int32) -> Int32 {
    ((x - y + z) % 6 + 6) % 6
  }
  chk(
    out,
    "malcev: Z/6Z affine p(x,y,z)=x-y+z is Mal'cev #1",
    ua_is_malcev_op(n, p_z6),
  )

  // 兩個非平凡正規子群同餘：mod 2 與 mod 3
  let theta = ua_kernel_congruence(n, fn(x) { x % 2 })
  let psi = ua_kernel_congruence(n, fn(x) { x % 3 })
  chk(
    out,
    "malcev: mod 2 and mod 3 are ternary congruences on Z/6Z #2",
    ua_is_ternary_congruence(n, theta, p_z6) &&
    ua_is_ternary_congruence(n, psi, p_z6),
  )

  let tp = ua_rel_comp(n, theta, psi)
  let pt = ua_rel_comp(n, psi, theta)
  let join_cl = ua_equiv_join_closure(n, theta, psi)
  chk(
    out,
    "malcev: congruences permute theta o psi == psi o theta #3",
    tp == pt,
  )
  chk(
    out,
    "malcev: 1-step composition equals transitive-closure join #4",
    tp == join_cl && ua_is_ternary_congruence(n, tp, p_z6),
  )

  // 負對照：4 元鏈格 ({0<1<2<3}, min, max) 非瑪爾切夫，同餘不可換！
  // θ 將 {0,1}、{2}、{3} 分塊；ψ 將 {0}、{1,2}、{3} 分塊（皆保持 min/max）
  let c_theta = ua_kernel_congruence(4, fn(x) { if x <= 1 { 0 } else { x } })
  let c_psi = ua_kernel_congruence(4, fn(x) {
    if x == 1 || x == 2 {
      1
    } else {
      x
    }
  })
  let c_tp = ua_rel_comp(4, c_theta, c_psi)
  let c_pt = ua_rel_comp(4, c_psi, c_theta)
  // (0, 2) ∈ θ∘ψ（經 1），但 (0, 2) ∉ ψ∘θ！
  chk(
    out,
    "malcev: non-Mal'cev chain lattice refutes congruence permutability #5",
    c_tp != c_pt && c_tp[0][2] && !c_pt[0][2] && !ua_is_equiv(4, c_tp),
  )
  out
}

///|
pub fn law_malcev_quotient_algebra_and_first_isomorphism() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // f : Z/6Z -> Z/3Z, f(x) = x mod 3
  let n = 6
  let add6 = fn(a : Int32, b : Int32) -> Int32 { (a + b) % 6 }
  let p_z6 = fn(x : Int32, y : Int32, z : Int32) -> Int32 {
    ((x - y + z) % 6 + 6) % 6
  }
  let f = fn(x : Int32) -> Int32 { x % 3 }
  let ker_f = ua_kernel_congruence(n, f)
  let (reps, proj) = ua_quotient_classes(n, ker_f)
  let q_n = reps.length()
  chk(out, "quotient: |Z/6Z / ker(mod 3)| == |im(f)| == 3 #1", q_n == 3)

  // 商三元瑪爾切夫算子在商集上仍滿足瑪爾切夫恆等式
  let q_p = fn(c1 : Int32, c2 : Int32, c3 : Int32) -> Int32 {
    proj[p_z6(reps[c1], reps[c2], reps[c3])]
  }
  chk(
    out,
    "quotient: quotient inherits Mal'cev axioms #2",
    ua_is_malcev_op(q_n, q_p),
  )

  // 第一同構定理雙射 φ([x]) = f(x) 保持加法與瑪爾切夫運算
  let mut hom_ok = true
  for a in 0..<q_n {
    for b in 0..<q_n {
      let q_sum = proj[add6(reps[a], reps[b])]
      if f(reps[q_sum]) != (f(reps[a]) + f(reps[b])) % 3 {
        hom_ok = false
      }
      for c in 0..<q_n {
        let q_m = q_p(a, b, c)
        let img_m = ((f(reps[a]) - f(reps[b]) + f(reps[c])) % 3 + 3) % 3
        if f(reps[q_m]) != img_m {
          hom_ok = false
        }
      }
    }
  }
  chk(
    out, "quotient: first isomorphism A/ker(f) ≅ im(f) preserves ops #3", hom_ok,
  )

  // 負對照：非同餘等價關係（將 {0,1} 合併但 {2..5} 單點）使商加法依代表元而變
  let bad_rel = ua_kernel_congruence(n, fn(x) { if x <= 1 { 0 } else { x } })
  chk(
    out,
    "quotient: non-congruence equivalence rejected by ternary congruence test #4",
    ua_is_equiv(n, bad_rel) && !ua_is_ternary_congruence(n, bad_rel, p_z6),
  )
  out
}

///|
pub fn law_malcev_absorbing_zero_collapse_vs_pointed_additivity() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 窮舉二元載體 {0, 1} 上全部 2^(2^3) = 256 個三元布林運算 table ∈ 0..255
  let mut malcev_count = 0
  let mut commute_with_and = 0
  let mut commute_with_xor = 0
  for tbl in 0..<256 {
    let eval_p = fn(x : Int32, y : Int32, z : Int32) -> Int32 {
      let idx = (x << 2) | (y << 1) | z
      (tbl >> idx) & 1
    }
    if ua_is_malcev_op(2, eval_p) {
      malcev_count = malcev_count + 1
      let mut ok_and = true
      let mut ok_xor = true
      for a1 in 0..<2 {
        for a2 in 0..<2 {
          for b1 in 0..<2 {
            for b2 in 0..<2 {
              for c1 in 0..<2 {
                for c2 in 0..<2 {
                  if eval_p(a1 & a2, b1 & b2, c1 & c2) !=
                    (eval_p(a1, b1, c1) & eval_p(a2, b2, c2)) {
                    ok_and = false
                  }
                  if eval_p(a1 ^ a2, b1 ^ b2, c1 ^ c2) !=
                    (eval_p(a1, b1, c1) ^ eval_p(a2, b2, c2)) {
                    ok_xor = false
                  }
                }
              }
            }
          }
        }
      }
      if ok_and {
        commute_with_and = commute_with_and + 1
      }
      if ok_xor {
        commute_with_xor = commute_with_xor + 1
      }
    }
  }
  chk(
    out,
    "absorbing-zero: {0,1} has 4 Mal'cev ternary operations out of 256 #1",
    malcev_count == 4,
  )
  chk(
    out,
    "absorbing-zero: 0 Mal'cev ops commute with absorbing AND (interval non-fibrancy) #2",
    commute_with_and == 0,
  )
  chk(
    out,
    "absorbing-zero: unique Mal'cev op x^y^z commutes with pointed XOR #3",
    commute_with_xor == 1,
  )

  // 單點退化代數 {0}（0 為吸收元且載體塌縮 |A|=1）是唯一同時容許吸收元與相容瑪爾切夫算子之模型
  let p1 = fn(_x : Int32, _y : Int32, _z : Int32) -> Int32 { 0 }
  chk(
    out,
    "absorbing-zero: collapsed singleton |A|=1 vacuously admits absorbing Mal'cev #4",
    ua_is_malcev_op(1, p1),
  )
  out
}

///|
/// 一元運算 `f : {0,1,2} -> {0,1,2}`（共 27 個，編碼 0..26）與二元關係（9 bits，編碼 0..511）
/// 之 Pol–Inv 保持判定。
fn ua_preserves_unary_rel3(op_code : Int32, rel_mask : Int32) -> Bool {
  let f0 = op_code % 3
  let f1 = op_code / 3 % 3
  let f2 = op_code / 9 % 3
  let f = [f0, f1, f2]
  for x in 0..<3 {
    for y in 0..<3 {
      let bit_in = (rel_mask >> (x * 3 + y)) & 1
      if bit_in == 1 {
        let bit_out = (rel_mask >> (f[x] * 3 + f[y])) & 1
        if bit_out == 0 {
          return false
        }
      }
    }
  }
  true
}

///|
pub fn law_malcev_pol_inv_galois_correspondence() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let pol = fn(rels : Array[Int32]) -> Array[Int32] {
    let res : Array[Int32] = []
    for op in 0..<27 {
      let mut ok = true
      for r in rels {
        if !ua_preserves_unary_rel3(op, r) {
          ok = false
          break
        }
      }
      if ok {
        res.push(op)
      }
    }
    res
  }
  let inv = fn(ops : Array[Int32]) -> Array[Int32] {
    let res : Array[Int32] = []
    for r in 0..<512 {
      let mut ok = true
      for op in ops {
        if !ua_preserves_unary_rel3(op, r) {
          ok = false
          break
        }
      }
      if ok {
        res.push(r)
      }
    }
    res
  }

  // 樣本：循環平移 σ(x)=(x+1) mod 3 與輪換關係 {(0,1),(1,2),(2,0)}
  let f_set = [1 + 2 * 3 + 0 * 9] // [1, 2, 0]
  let r_set = [(1 << 1) | (1 << 5) | (1 << 6)]
  let lhs = set_subset(r_set, inv(f_set))
  let rhs = set_subset(f_set, pol(r_set))
  chk(
    out,
    "pol-inv: Galois adjunction R <= Inv(F) <=> F <= Pol(R) #1",
    lhs && rhs && lhs == rhs,
  )
  chk(
    out,
    "pol-inv: inflationary F <= Pol(Inv(F)) and R <= Inv(Pol(R)) #2",
    set_subset(f_set, pol(inv(f_set))) && set_subset(r_set, inv(pol(r_set))),
  )
  chk(
    out,
    "pol-inv: triple closure Pol(Inv(Pol(R))) == Pol(R) #3",
    pol(inv(pol(r_set))) == pol(r_set) && inv(pol(inv(f_set))) == inv(f_set),
  )
  // 反單調：R1 ⊆ R2 ⇒ Pol(R2) ⊆ Pol(R1)
  let r2_set = [r_set[0], 1 | (1 << 4) | (1 << 8)]
  chk(
    out,
    "pol-inv: antitone R1 <= R2 => Pol(R2) <= Pol(R1) #4",
    set_subset(pol(r2_set), pol(r_set)),
  )
  out
}

///|
pub fn law_malcev_reflexive_graph_internal_groupoid_and_matroid_ramsey() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  // 1. 內蘊自反圖 (G1 = Z/4Z × Z/4Z, G0 = Z/4Z)：d0(a,b)=a, d1(a,b)=b, s0(a)=(a,a)
  //    由點態瑪爾切夫算子 p(u,v,w) = u - v + w mod 4 唯一合成：
  //    m((b,c), (a,b)) = p((b,c), s0(b), (a,b)) = (b-b+a, c-b+b) = (a, c)！
  //    inv(a,b) = p(s0(b), (a,b), s0(a)) = (b-a+a, b-b+a) = (b, a)！
  let p4 = fn(x : Int32, y : Int32, z : Int32) -> Int32 {
    ((x - y + z) % 4 + 4) % 4
  }
  let comp_g = fn(f : (Int32, Int32), g : (Int32, Int32)) -> (Int32, Int32) {
    // g : a -> b, f : b -> c (d0(f) == b == d1(g))
    let b = f.0
    (p4(f.0, b, g.0), p4(f.1, b, g.1))
  }
  let inv_g = fn(f : (Int32, Int32)) -> (Int32, Int32) {
    let a = f.0
    let b = f.1
    (p4(b, f.0, a), p4(b, f.1, a))
  }
  let mut grpd_ok = true
  for a in 0..<4 {
    for b in 0..<4 {
      let g = (a, b)
      let ig = inv_g(g)
      if comp_g(ig, g) != (a, a) || comp_g(g, ig) != (b, b) {
        grpd_ok = false
      }
      for c in 0..<4 {
        for d in 0..<4 {
          let f = (b, c)
          let h = (c, d)
          if comp_g(h, comp_g(f, g)) != comp_g(comp_g(h, f), g) {
            grpd_ok = false
          }
        }
      }
    }
  }
  chk(
    out, "malcev-groupoid: reflexive graph in Mal'cev algebra forms internal groupoid #1",
    grpd_ok,
  )

  // 2. 仿射瑪爾切夫空間 (Z/2Z)^2（4 元素：0=(0,0), 1=(1,0), 2=(0,1), 3=(1,1)）
  //    仿射張成秩 r(S) = dim_aff(S) + 1（空集 0，單點 1，相異兩點 2，不共線三點 3）
  //    形成嚴格擬陣（Fano 平面之子仿射擬陣 AG(2, 2)）！
  let aff_rank = fn(s : Array[Int32]) -> Int32 {
    let ns = set_norm(s)
    let k = ns.length()
    if k <= 2 {
      k
    } else if k == 3 {
      // AG(2,2) 中任意三相異點皆仿射獨立（因直線恰有 2 點！）
      3
    } else {
      // 4 點滿足 x0 ⊕ x1 ⊕ x2 ⊕ x3 = 0（瑪爾切夫四元組依賴 p(x0,x1,x2)=x3）
      3
    }
  }
  let m_aff = Matroid::{ ground: 4, rankf: aff_rank, }
  chk(
    out,
    "malcev-matroid: affine Mal'cev closure AG(2,2) satisfies matroid rank & exchange #2",
    mat_rank_axioms_ok(m_aff) is None && mat_exchange_ok(m_aff),
  )

  // 3. Ramsey × 同餘關係：將 Z/6Z 的 K_6 邊 (x, y) 依「是否落在 mod 2 主同餘類」二著色，
  //    由 R(3,3)=6 必存在單色三角形（此處偶數類 {0,2,4} 與奇數類 {1,3,5} 皆為同餘單色 K_3）！
  let mod2_color = fn(u : Int32, v : Int32) -> Bool { u % 2 == v % 2 }
  let mut mono_k3 = 0
  for i in 0..<6 {
    for j in (i + 1)..<6 {
      for k in (j + 1)..<6 {
        let c1 = mod2_color(i, j)
        let c2 = mod2_color(j, k)
        let c3 = mod2_color(i, k)
        if c1 == c2 && c2 == c3 {
          mono_k3 = mono_k3 + 1
        }
      }
    }
  }
  chk(
    out,
    "malcev-ramsey: congruence 2-coloring on Z/6Z K_6 yields monochromatic K_3s #3",
    mono_k3 == 2,
  )
  out
}
