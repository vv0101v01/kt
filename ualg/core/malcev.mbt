// ---------------------------------------------------------------------------
// ualg/core — 瑪爾切夫（Mal'cev）算子：三條判定路徑與可重驗的項憑證
// ---------------------------------------------------------------------------
//
// [D-Mal]   Mal'cev 項 p(x,y,z)：p(x,y,y) ≈ x 且 p(x,x,y) ≈ y。
// [T-Mal]   Mal'cev (1954)：簇 V 同餘可換 ⇔ V 有 Mal'cev 項。
// [T-Glob]  V(A) 有 Mal'cev 項 ⇔ 在 F(2)² 中 (x,y) ∈ Sg{(x,x),(y,x),(y,y)}。
//           （p 作用在三個生成元上恰為 (p(x,y,y), p(x,x,y))。）一般情形 EXPTIME
//           完備（Freese–Valeriote 2009）；本檔在命中時回傳**項本身**當憑證，
//           由 `malcev_term_ok` 獨立重驗——肯定答案不必信任搜尋。
// [T-Loc]   冪等有限代數：有 Mal'cev 項 ⇔ ∀a,b,c,d: (a,d) ∈ Sg_{A²}{(a,c),(b,c),(b,d)}
//           （局部 Mal'cev 項可拼成全域；Freese–Valeriote 2009、Horowitz 2013）。
//           n⁴ 個 ≤ n² 元的閉包 ⇒ 多項式時間（困難度 P）。
// [L-Refl]  必要條件（局部公理）：A² 的每個自反子代數都對稱。失敗即給出反例配對。

///|
pub(all) struct MalcevVerdict {
  exists : Bool
  complete : Bool
  term : Term?
  r_size : Int32
}

///|
/// 憑證檢查器：對全部 (x,y) 驗 p(x,y,y) = x、p(x,x,y) = y。
pub fn malcev_term_ok(a : Alg, t : Term) -> Bool {
  for x in 0..<a.n {
    for y in 0..<a.n {
      if term_eval(a, t, [x, y, y]) != x || term_eval(a, t, [x, x, y]) != y {
        return false
      }
    }
  }
  true
}

///|
/// [T-Glob] 全域判定。座標 c ∈ 2·n²：前半塊是「第一分量的二元項函數」，
/// 後半塊是第二分量；x = π_0、y = π_1。
pub fn malcev_global(a : Alg, limit : Int32) -> MalcevVerdict {
  let n = a.n
  let m = n * n
  let xv = (c : Int32) => c % m % n
  let yv = (c : Int32) => c % m / n
  let g1 = Array::makei(2 * m, c => xv(c))
  let g2 = Array::makei(2 * m, c => if c < m { yv(c) } else { xv(c) })
  let g3 = Array::makei(2 * m, c => yv(c))
  let target = Array::makei(2 * m, c => if c < m { xv(c) } else { yv(c) })
  let cl = close_tuples(a, [g1, g2, g3], Some(target), limit)
  if cl.hit >= 0 {
    {
      exists: true,
      complete: true,
      term: Some(closure_term(cl, cl.hit)),
      r_size: cl.elems.length(),
    }
  } else {
    {
      exists: false,
      complete: cl.complete,
      term: None,
      r_size: cl.elems.length(),
    }
  }
}

///|
/// [L-Refl] 回傳（是否全部對稱, 反例 u, 反例 v）。
pub fn malcev_reflexive_symmetric(a : Alg) -> (Bool, Int32, Int32) {
  let n = a.n
  let sq = alg_product(a, a)
  for u in 0..<n {
    for v in 0..<n {
      if u != v {
        let gens = Array::makei(n, x => x + n * x)
        gens.push(u + n * v)
        if !sg(sq, gens).contains(v + n * u) {
          return (false, u, v)
        }
      }
    }
  }
  (true, -1, -1)
}

///|
pub fn is_idempotent(a : Alg) -> Bool {
  for op in a.ops {
    if op.arity == 0 && a.n > 1 {
      return false
    }
    for x in 0..<a.n {
      if op_apply(op, a.n, Array::make(op.arity, x)) != x {
        return false
      }
    }
  }
  true
}

///|
/// [T-Loc] 冪等代數的多項式時間判定；失敗時回傳反例 (a,b,c,d)。
pub fn malcev_idempotent_local(a : Alg) -> (Bool, Array[Int32]) {
  let n = a.n
  let sq = alg_product(a, a)
  for x in 0..<n {
    for b in 0..<n {
      for c in 0..<n {
        for d in 0..<n {
          let r = sg(sq, [x + n * c, b + n * c, b + n * d])
          if !r.contains(x + n * d) {
            return (false, [x, b, c, d])
          }
        }
      }
    }
  }
  (true, [])
}

///|
/// 定律：三條路徑彼此對帳，肯定答案附可重驗的項。
pub fn law_malcev_three_algorithms() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // (1) 有 Mal'cev 項的代數：全域搜尋命中 + 憑證重驗 + 自反⇒對稱
  let yes = [
    alg_zn(2),
    alg_zn(3),
    alg_zn(4),
    alg_zn(5),
    alg_s3(),
    alg_product(alg_zn(2), alg_zn(2)),
    alg_gf2k(2, 7),
    alg_bool2(),
    alg_affine_zn(3),
    alg_affine_zn(4),
    alg_affine_zn(5),
    alg_steiner3(),
  ]
  let mut yes_ok = true
  let sizes : Array[Int32] = []
  for a in yes {
    let v = malcev_global(a, 4000)
    let cert = match v.term {
      Some(t) => {
        sizes.push(term_size(t))
        malcev_term_ok(a, t)
      }
      None => false
    }
    if !v.exists || !cert || !malcev_reflexive_symmetric(a).0 {
      yes_ok = false
    }
  }
  chk(
    out,
    "Mal'cev 項存在（12 個代數：ℤ2..5、S3、ℤ2²、GF(4)、𝟚、Aff(ℤ3..5)、Steiner3）：全域搜尋命中且項憑證逐點重驗通過；項大小 \{show_ints(sizes)}",
    yes_ok,
  )
  // 古典項 x·y⁻¹·z 直接當憑證
  let classic = TApp(0, [TApp(0, [TVar(0), TApp(1, [TVar(1)])]), TVar(2)])
  chk(
    out,
    "群的古典 Mal'cev 項 p = (x·y⁻¹)·z 在 ℤ5 與非交換的 S3 上皆通過憑證檢查",
    malcev_term_ok(alg_zn(5), classic) && malcev_term_ok(alg_s3(), classic),
  )
  // 憑證檢查器的反例對照
  let wrong = TApp(0, [TApp(0, [TVar(0), TVar(1)]), TVar(2)])
  chk(
    out,
    "反例：(x·y)·z（少了逆元）與投影 x 都被憑證檢查器拒絕",
    !malcev_term_ok(alg_zn(5), wrong) && !malcev_term_ok(alg_zn(5), TVar(0)),
  )
  // (2) 沒有 Mal'cev 項：完整閉包給出否定
  let no = [
    alg_chain(2),
    alg_chain(3),
    alg_m3(),
    alg_n5(),
    alg_semilattice2(),
    alg_rect_band(2, 2),
    alg_zn_mul(4),
  ]
  let mut no_ok = true
  let rs : Array[Int32] = []
  for a in no {
    let v = malcev_global(a, 4000)
    rs.push(v.r_size)
    if v.exists || !v.complete {
      no_ok = false
    }
  }
  chk(
    out,
    "Mal'cev 項不存在（Chain2、Chain3、M3、N5、SL2、Rect2×2、(ℤ4,·)）：F(2)² 中的閉包 R 完整算完仍不含 (x,y)；|R| = \{show_ints(rs)}",
    no_ok,
  )
  // (3) 冪等代數：多項式局部判定 = 全域判定
  let idem = [
    alg_chain(2),
    alg_chain(3),
    alg_m3(),
    alg_n5(),
    alg_semilattice2(),
    alg_rect_band(2, 2),
    alg_affine_zn(3),
    alg_affine_zn(4),
    alg_affine_zn(5),
    alg_steiner3(),
  ]
  let mut idem_ok = true
  let mut pos = 0
  for a in idem {
    let loc = malcev_idempotent_local(a).0
    let glo = malcev_global(a, 4000)
    if loc {
      pos = pos + 1
    }
    if !is_idempotent(a) || loc != glo.exists || (!glo.exists && !glo.complete) {
      idem_ok = false
    }
  }
  chk(
    out,
    "冪等代數（10 個）：Freese–Valeriote 局部多項式判定與全域 F(2)² 判定逐一相同（\{pos} 個有、\{10 - pos} 個無）",
    idem_ok && pos == 4,
  )
  chk(
    out,
    "非冪等代數被局部判定的前提檢查擋下：ℤ3（有常元 0）、𝟚（有 ¬）皆非冪等",
    !is_idempotent(alg_zn(3)) && !is_idempotent(alg_bool2()),
  )
  // (4) 局部公理的反例：格序本身就是自反而不對稱的相容關係
  let (s4, u4, v4) = malcev_reflexive_symmetric(alg_dm4())
  let (s3, _, _) = malcev_reflexive_symmetric(alg_kleene3())
  let (sc, uc, vc) = malcev_reflexive_symmetric(alg_chain(2))
  chk(
    out,
    "De Morgan 型代數無 Mal'cev 項：𝟜² 有自反不對稱子代數（反例配對 (\{u4},\{v4})），𝟛 亦然；Chain2 的反例 (\{uc},\{vc}) 即格序 ≤",
    !s4 && !s3 && !sc,
  )
  out
}

///|
/// 定律：Mal'cev 定理的兩個方向在具體代數上的可觀測後果。
pub fn law_malcev_theorem_permutability() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  // (⇒) 有 Mal'cev 項 ⇒ A 與 A² 同餘可換
  let mut perm_ok = true
  let cons : Array[Int32] = []
  for a in [alg_zn(4), alg_zn(5), alg_s3(), alg_bool2(), alg_steiner3()] {
    let sq = alg_product(a, a)
    let c1 = con_lattice(a)
    let c2 = con_lattice(sq)
    cons.push(c2.length())
    if !con_permutable(c1) || !con_permutable(c2) || !con_modular(c2) {
      perm_ok = false
    }
  }
  chk(
    out,
    "Mal'cev ⇒ 同餘可換 ⇒ 模：ℤ4、ℤ5、S3、𝟚、Steiner3 的 A 與 A² 全部同餘兩兩可換且同餘格模；|Con(A²)| = \{show_ints(cons)}",
    perm_ok,
  )
  // (⇐ 的逆否) 無 Mal'cev 項 ⇒ 簇裡有同餘不可換的成員
  let c3 = con_lattice(alg_chain(3))
  chk(
    out,
    "Chain3 的兩個同餘 {01|2}、{0|12} 不可換（格簇不同餘可換的最小見證）",
    c3.length() == 4 && !con_permutable(c3),
  )
  // 「A 自己同餘可換」不等於「V(A) 有 Mal'cev 項」
  let rect = alg_rect_band(2, 2)
  let l3 = alg_rect_band(3, 1)
  let cl3 = con_lattice(l3)
  chk(
    out,
    "陷阱：Rect2×2 自身同餘可換，但 V(Rect2×2) 無 Mal'cev 項——同簇的左零帶 L3 有 \{cl3.length()} 個同餘（全部分割）且不可換",
    con_permutable(con_lattice(rect)) &&
    !malcev_global(rect, 4000).exists &&
    cl3.length() == 5 &&
    !con_permutable(cl3) &&
    satisfies(l3, TApp(0, [TVar(0), TVar(1)]), TVar(0), 2),
  )
  out
}
