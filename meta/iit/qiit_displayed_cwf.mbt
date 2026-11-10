// ---------------------------------------------------------------------------
// meta/iit — 商歸納-歸納類型（QIIT）：內蘊四分類帶族範疇（Con, Ty, Sub, Tm）語法、
//            依商等式索引檢查、展示代數（Displayed Algebra）與依值截面消除器
// ---------------------------------------------------------------------------
//
// 參考文獻：
//   - Altenkirch & Kaposi (POPL 2016), "Type Theory in Type Theory using Quotient Inductive Types"
//   - Kaposi, Kovács & Altenkirch (POPL 2019), "Constructing Quotient Inductive-Inductive Types"
//
// 核心機制（為何必須是真 QIIT，而非普通 II 或單分類 QIT）：
//   1. 互歸納-歸納索引耦合：`Con` 由 `QExt(Γ, A)` 依賴 `Ty(Γ)`，而 `Ty`、`Sub`、`Tm` 反過來以 `Con` 與 `Ty` 為索引；
//   2. 跨分類商等式耦合：項代換結合律 `t[σ][τ] = t[σ ∘ τ]` 左端位於 `Tm(Γ, A[σ][τ])`，右端位於 `Tm(Γ, A[σ ∘ τ])`——
//      若無底層 `Ty` 商等式 `A[σ][τ] ≡ A[σ ∘ τ]` 先將兩個型別索引黏合，該項等式甚至無法良構陳述！
//   3. 展示代數與依值消除器：只有同時滿足全部點建構子與路徑（等式）建構子相干條件的展示代數 `Ω^D`，
//      才誘導出商不變之依值截面消除器 `qiit_cwf_elim_*`；違反商相干性的偽動機（如計算語法 `QTySub` 層數）必被拒絕。

///|
/// 分類 0：內蘊上下文 `Con`。
#derive(Eq)
pub(all) enum QiitCon {
  QEmp
  QExt(QiitCon, QiitTy)
}

///|
pub extend QiitCon with Eq::{not_equal, equal}

///|
/// 分類 1：內蘊型別族 `Ty(Γ)`。
#derive(Eq)
pub(all) enum QiitTy {
  /// 基底有限型別（基數 `card >= 1`，如 `Bool` 為 `2`）
  QBase(QiitCon, Int32)
  /// 依值函數型別 `Π(A, B)`，其中 `A : Ty(Γ)`，`B : Ty(Γ.A)`
  QPi(QiitCon, QiitTy, QiitTy)
  /// 顯式型別代換建構子 `A[σ] : Ty(Γ)`（`A : Ty(Δ), σ : Sub(Γ, Δ)`）
  QTySub(QiitCon, QiitCon, QiitTy, QiitSub)
}

///|
pub extend QiitTy with Eq::{not_equal, equal}

///|
/// 分類 2：內蘊代換態射 `Sub(Γ, Δ)`。
#derive(Eq)
pub(all) enum QiitSub {
  QSubId(QiitCon)
  QSubComp(QiitCon, QiitCon, QiitCon, QiitSub, QiitSub)
  QSubEps(QiitCon)
  QSubExt(QiitCon, QiitCon, QiitTy, QiitSub, QiitTm)
  QSubP(QiitCon, QiitTy)
}

///|
pub extend QiitSub with Eq::{not_equal, equal}

///|
/// 分類 3：內蘊良型項 `Tm(Γ, A)`（含沿型別商等式 `A ≡ B` 傳輸之 `QTmCoh`）。
#derive(Eq)
pub(all) enum QiitTm {
  /// 尾變數 `q : Tm(Γ.A, A[p])`
  QTmQ(QiitCon, QiitTy)
  /// 基底常數 `c ∈ 0..<card`
  QTmConst(QiitCon, Int32, Int32)
  /// 顯式項代換 `t[σ] : Tm(Γ, A[σ])`
  QTmSub(QiitCon, QiitCon, QiitTy, QiitTm, QiitSub)
  /// 沿 QIIT 型別商等式 `A₁ ≡_QIIT A₂` 之相干強制轉換 `coh(A₁, A₂, t) : Tm(Γ, A₂)`
  QTmCoh(QiitCon, QiitTy, QiitTy, QiitTm)
}

///|
pub extend QiitTm with Eq::{not_equal, equal}

///|
/// 規範化輔助：計算經代換消元後之正規型別與正規代換（決定性商代表元投影）。
pub fn qiit_norm_con(c : QiitCon) -> QiitCon {
  match c {
    QEmp => QEmp
    QExt(g, a) => QExt(qiit_norm_con(g), qiit_norm_ty(a))
  }
}

///|
/// 沿正規代換將正規型別推入基底／Π 結構（實作 `QBase(Δ, k)[σ] ≡ QBase(Γ, k)`、`A[id] ≡ A`、`A[σ][τ] ≡ A[σ ∘ τ]`）。
pub fn qiit_norm_ty(ty : QiitTy) -> QiitTy {
  match ty {
    QBase(g, k) => QBase(qiit_norm_con(g), k)
    QPi(g, a, b) => QPi(qiit_norm_con(g), qiit_norm_ty(a), qiit_norm_ty(b))
    QTySub(g, d, a, s) => {
      let gn = qiit_norm_con(g)
      let dn = qiit_norm_con(d)
      let an = qiit_norm_ty(a)
      let sn = qiit_norm_sub(s)
      match sn {
        QSubId(_) => an
        _ =>
          match an {
            QBase(_, k) => QBase(gn, k)
            QTySub(_, d2, a2, s2) =>
              qiit_norm_ty(
                QTySub(gn, d2, a2, qiit_norm_sub(QSubComp(gn, dn, d2, s2, sn))),
              )
            _ => QTySub(gn, dn, an, sn)
          }
      }
    }
  }
}

///|
/// 正規化代換態射（實作範疇律 `id ∘ σ ≡ σ`、`σ ∘ id ≡ σ`、結合律、終端唯一性 `!: Γ -> · ≡ ε` 及 `p ∘ ⟨σ, t⟩ ≡ σ`）。
pub fn qiit_norm_sub(s : QiitSub) -> QiitSub {
  match s {
    QSubId(g) =>
      match qiit_norm_con(g) {
        QEmp => QSubEps(QEmp)
        gn => QSubId(gn)
      }
    QSubEps(g) => QSubEps(qiit_norm_con(g))
    QSubP(g, a) => QSubP(qiit_norm_con(g), qiit_norm_ty(a))
    QSubExt(g, d, a, sub0, tm0) =>
      QSubExt(
        qiit_norm_con(g),
        qiit_norm_con(d),
        qiit_norm_ty(a),
        qiit_norm_sub(sub0),
        qiit_norm_tm(tm0),
      )
    QSubComp(g, d, e, s_de, s_gd) => {
      let gn = qiit_norm_con(g)
      let dn = qiit_norm_con(d)
      let en = qiit_norm_con(e)
      if en == QEmp {
        return QSubEps(gn)
      }
      let lhs = qiit_norm_sub(s_de)
      let rhs = qiit_norm_sub(s_gd)
      match (lhs, rhs) {
        (QSubId(_), _) => rhs
        (_, QSubId(_)) => lhs
        (QSubEps(_), _) => QSubEps(gn)
        (QSubP(_, _), QSubExt(_, _, _, sigma, _)) => sigma
        (QSubExt(_, d0, a0, sigma, t0), tau) =>
          qiit_norm_sub(
            QSubExt(
              gn,
              d0,
              a0,
              QSubComp(gn, dn, d0, sigma, tau),
              QTmSub(gn, dn, QTySub(dn, d0, a0, sigma), t0, tau),
            ),
          )
        (QSubComp(_, m, _, s1, s2), tau) =>
          qiit_norm_sub(QSubComp(gn, m, en, s1, QSubComp(gn, dn, m, s2, tau)))
        _ => QSubComp(gn, dn, en, lhs, rhs)
      }
    }
  }
}

///|
/// 正規化內蘊項（實作 `q[⟨σ, t⟩] ≡ t`、`c[σ] ≡ c`、`t[id] ≡ t`、`t[σ][τ] ≡ t[σ ∘ τ]` 與擦除 `QTmCoh`）。
pub fn qiit_norm_tm(tm : QiitTm) -> QiitTm {
  match tm {
    QTmQ(g, a) => QTmQ(qiit_norm_con(g), qiit_norm_ty(a))
    QTmConst(g, k, c) => QTmConst(qiit_norm_con(g), k, c)
    QTmCoh(_, _, _, inner) => qiit_norm_tm(inner)
    QTmSub(g, d, a, t0, s0) => {
      let gn = qiit_norm_con(g)
      let dn = qiit_norm_con(d)
      let an = qiit_norm_ty(a)
      let tn = qiit_norm_tm(t0)
      let sn = qiit_norm_sub(s0)
      match sn {
        QSubId(_) => tn
        _ =>
          match (tn, sn) {
            (QTmConst(_, k, c), _) => QTmConst(gn, k, c)
            (QTmQ(_, _), QSubExt(_, _, _, _, rhs_tm)) => rhs_tm
            (QTmSub(_, d2, a2, inner_t, s2), _) =>
              qiit_norm_tm(
                QTmSub(
                  gn,
                  d2,
                  a2,
                  inner_t,
                  qiit_norm_sub(QSubComp(gn, dn, d2, s2, sn)),
                ),
              )
            _ => QTmSub(gn, dn, an, tn, sn)
          }
      }
    }
  }
}

///|
/// 四分類互依商索引檢查器：同時驗證 `Con`、`Ty(Γ)`、`Sub(Γ, Δ)` 與 `Tm(Γ, A)`，
/// 其中索引相等一律在 QIIT 商關係 `≡_QIIT` 下判定！
pub fn qiit_check_con(c : QiitCon) -> Bool {
  match c {
    QEmp => true
    QExt(g, a) => qiit_check_con(g) && qiit_check_ty(g, a)
  }
}

///|
pub fn qiit_check_ty(expected_ctx : QiitCon, ty : QiitTy) -> Bool {
  if !qiit_check_con(expected_ctx) {
    return false
  }
  let exp_n = qiit_norm_con(expected_ctx)
  match ty {
    QBase(g, k) => k >= 1 && qiit_check_con(g) && qiit_norm_con(g) == exp_n
    QPi(g, a, b) =>
      qiit_check_con(g) &&
      qiit_norm_con(g) == exp_n &&
      qiit_check_ty(g, a) &&
      qiit_check_ty(QExt(g, a), b)
    QTySub(g, d, a, s) =>
      qiit_check_con(g) &&
      qiit_norm_con(g) == exp_n &&
      qiit_check_con(d) &&
      qiit_check_ty(d, a) &&
      qiit_check_sub(g, d, s)
  }
}

///|
pub fn qiit_check_sub(
  expected_dom : QiitCon,
  expected_cod : QiitCon,
  s : QiitSub,
) -> Bool {
  if !qiit_check_con(expected_dom) || !qiit_check_con(expected_cod) {
    return false
  }
  let dom_n = qiit_norm_con(expected_dom)
  let cod_n = qiit_norm_con(expected_cod)
  match s {
    QSubId(g) =>
      qiit_check_con(g) &&
      qiit_norm_con(g) == dom_n &&
      qiit_norm_con(g) == cod_n
    QSubEps(g) =>
      qiit_check_con(g) && qiit_norm_con(g) == dom_n && cod_n == QEmp
    QSubP(g, a) =>
      qiit_check_con(g) &&
      qiit_check_ty(g, a) &&
      qiit_norm_con(QExt(g, a)) == dom_n &&
      qiit_norm_con(g) == cod_n
    QSubComp(g, d, e, s_de, s_gd) =>
      qiit_check_con(g) &&
      qiit_check_con(d) &&
      qiit_check_con(e) &&
      qiit_norm_con(g) == dom_n &&
      qiit_norm_con(e) == cod_n &&
      qiit_check_sub(d, e, s_de) &&
      qiit_check_sub(g, d, s_gd)
    QSubExt(g, d, a, sigma, t) =>
      qiit_check_con(g) &&
      qiit_check_con(d) &&
      qiit_check_ty(d, a) &&
      qiit_norm_con(g) == dom_n &&
      qiit_norm_con(QExt(d, a)) == cod_n &&
      qiit_check_sub(g, d, sigma) &&
      qiit_check_tm(g, QTySub(g, d, a, sigma), t)
  }
}

///|
pub fn qiit_check_tm(
  expected_ctx : QiitCon,
  expected_ty : QiitTy,
  tm : QiitTm,
) -> Bool {
  if !qiit_check_ty(expected_ctx, expected_ty) {
    return false
  }
  let ctx_n = qiit_norm_con(expected_ctx)
  let ty_n = qiit_norm_ty(expected_ty)
  match tm {
    QTmQ(g, a) => {
      let ext_c = QExt(g, a)
      let wk_a = QTySub(ext_c, g, a, QSubP(g, a))
      qiit_check_ty(g, a) &&
      qiit_norm_con(ext_c) == ctx_n &&
      qiit_norm_ty(wk_a) == ty_n
    }
    QTmConst(g, k, c) =>
      c >= 0 &&
      c < k &&
      qiit_check_con(g) &&
      qiit_norm_con(g) == ctx_n &&
      qiit_norm_ty(QBase(g, k)) == ty_n
    QTmSub(g, d, a, t0, s0) =>
      qiit_check_sub(g, d, s0) &&
      qiit_check_tm(d, a, t0) &&
      qiit_norm_con(g) == ctx_n &&
      qiit_norm_ty(QTySub(g, d, a, s0)) == ty_n
    QTmCoh(g, a1, a2, inner) =>
      // 關鍵 QIIT 規則：僅當商正規形證明 a1 ≡_QIIT a2 時，才允許將 Tm(Γ, a1) 傳輸至 Tm(Γ, a2)！
      qiit_check_ty(g, a1) &&
      qiit_check_ty(g, a2) &&
      qiit_norm_con(g) == ctx_n &&
      qiit_norm_ty(a1) == qiit_norm_ty(a2) &&
      qiit_norm_ty(a2) == ty_n &&
      qiit_check_tm(g, a1, inner)
  }
}

///|
/// Kaposi–Kovács–Altenkirch 展示代數（Displayed Algebra `Ω^D`）在標準集合模型上之截面消除器規格：
/// 將每個良構 `Con`、`Ty`、環境下之 `Sub` 與 `Tm` 映射為具體語義不變量，並接受等式建構子相干性審計。
pub(all) struct QiitDisplayedCwfAlgebra {
  con_card : (QiitCon) -> Int32
  ty_fiber_card : (QiitCon, QiitTy) -> Int32
  eval_sub : (QiitSub, Array[Int32]) -> Array[Int32]
  eval_tm : (QiitTm, Array[Int32]) -> Int32
}

///|
fn qiit_std_eval_sub(s : QiitSub, env : Array[Int32]) -> Array[Int32] {
  match s {
    QSubId(_) => env.copy()
    QSubEps(_) => []
    QSubP(_, _) => {
      let out : Array[Int32] = []
      for i in 0..<(env.length() - 1) {
        out.push(env[i])
      }
      out
    }
    QSubComp(_, _, _, s_de, s_gd) =>
      qiit_std_eval_sub(s_de, qiit_std_eval_sub(s_gd, env))
    QSubExt(_, _, _, sigma, t) => {
      let base = qiit_std_eval_sub(sigma, env)
      base.push(qiit_std_eval_tm(t, env))
      base
    }
  }
}

///|
fn qiit_std_eval_tm(t : QiitTm, env : Array[Int32]) -> Int32 {
  match t {
    QTmQ(_, _) => if env.length() > 0 { env[env.length() - 1] } else { 0 }
    QTmConst(_, _, c) => c
    QTmCoh(_, _, _, inner) => qiit_std_eval_tm(inner, env)
    QTmSub(_, _, _, inner, sigma) =>
      qiit_std_eval_tm(inner, qiit_std_eval_sub(sigma, env))
  }
}

///|
/// 標準有限集 CwF 展示代數（滿足全部點與等式建構子，誘導良定義依值消除截面）。
pub fn qiit_standard_set_cwf_algebra() -> QiitDisplayedCwfAlgebra {
  let rec_ty = fn(ty : QiitTy) -> Int32 {
    let mut cur = ty
    for _ in 0..<16 {
      match cur {
        QBase(_, k) => return k
        QPi(_, a, b) => {
          let ca = match qiit_norm_ty(a) {
            QBase(_, ka) => ka
            _ => 1
          }
          let cb = match qiit_norm_ty(b) {
            QBase(_, kb) => kb
            _ => 1
          }
          let mut p = 1
          for _ in 0..<ca {
            p = p * cb
          }
          return p
        }
        QTySub(_, _, inner, _) => cur = inner
      }
    }
    1
  }
  let rec_con : (QiitCon) -> Int32 = fn(c) {
    let mut acc = 1
    let mut cur = c
    for _ in 0..<16 {
      match cur {
        QEmp => return acc
        QExt(rest, a) => {
          acc = acc * rec_ty(a)
          cur = rest
        }
      }
    }
    acc
  }
  QiitDisplayedCwfAlgebra::{
    con_card: rec_con,
    ty_fiber_card: fn(_g, a) { rec_ty(a) },
    eval_sub: qiit_std_eval_sub,
    eval_tm: qiit_std_eval_tm,
  }
}

///|
/// 審計展示代數 `alg` 在代表測試集上是否嚴格尊重全部 QIIT 商等式建構子
/// （`A[id] ≡ A`、`A[σ][τ] ≡ A[σ∘τ]`、`p ∘ ⟨σ, t⟩ ≡ σ`、`q[⟨σ, t⟩] ≡ t`、`t[σ][τ] ≡ t[σ∘τ]`）。
pub fn qiit_verify_displayed_coherence(alg : QiitDisplayedCwfAlgebra) -> Bool {
  let g0 = QEmp
  let b2 = QBase(g0, 2)
  let g1 = QExt(g0, b2) // ·.Bool
  let b3_g1 = QBase(g1, 3)
  let g2 = QExt(g1, b3_g1) // ·.Bool.Fin3

  // 1. Ty 等式：A[id] == A 且 A[p][⟨id, c⟩] == A[p ∘ ⟨id, c⟩]
  let a_id = QTySub(g1, g1, b3_g1, QSubId(g1))
  if (alg.ty_fiber_card)(g1, a_id) != (alg.ty_fiber_card)(g1, b3_g1) {
    return false
  }
  let sub_c1 = QSubExt(g0, g0, b2, QSubId(g0), QTmConst(g0, 2, 1))
  let wk_b2 = QTySub(g1, g0, b2, QSubP(g0, b2))
  let lhs_ty = QTySub(g0, g1, wk_b2, sub_c1)
  let rhs_ty = QTySub(g0, g0, b2, QSubComp(g0, g1, g0, QSubP(g0, b2), sub_c1))
  if (alg.ty_fiber_card)(g0, lhs_ty) != (alg.ty_fiber_card)(g0, rhs_ty) {
    return false
  }

  // 2. Sub 與 Tm β/η 與代換結合律：q[⟨id, 1⟩] == 1 且 t[σ][τ] == coh(t[σ ∘ τ])
  let q_var = QTmQ(g0, b2) // Tm(·.Bool, Bool[p])
  let beta_lhs = QTmSub(g0, g1, wk_b2, q_var, sub_c1)
  let beta_rhs = QTmConst(g0, 2, 1)
  if (alg.eval_tm)(beta_lhs, []) != (alg.eval_tm)(beta_rhs, []) {
    return false
  }

  // 在 g2 (環境 [x ∈ 0..2, y ∈ 0..3]) 上測試兩步代換結合律
  let p_g2_g1 = QSubP(g1, b3_g1) // g2 -> g1
  let lhs_tm = QTmSub(g2, g0, lhs_ty, beta_lhs, QSubEps(g2))
  let comp_sub = QSubComp(g2, g0, g1, sub_c1, QSubEps(g2))
  let raw_rhs_tm = QTmSub(g2, g1, wk_b2, q_var, comp_sub)
  let rhs_tm = QTmCoh(
    g2,
    QTySub(g2, g1, wk_b2, comp_sub),
    QTySub(g2, g0, lhs_ty, QSubEps(g2)),
    raw_rhs_tm,
  )
  for x in 0..<2 {
    for y in 0..<3 {
      let env = [x, y]
      if (alg.eval_tm)(lhs_tm, env) != (alg.eval_tm)(rhs_tm, env) {
        return false
      }
      if (alg.eval_sub)(QSubComp(g2, g1, g1, QSubId(g1), p_g2_g1), env) !=
        (alg.eval_sub)(p_g2_g1, env) {
        return false
      }
    }
  }
  true
}

///|
/// 元理論定律族：驗證內蘊四分類 QIIT `(Con, Ty, Sub, Tm)` 之跨分類商索引檢查、展示代數相干消除與偽動機拒絕。
pub fn law_qiit_intrinsic_cwf_and_displayed_eliminator() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let g0 = QEmp
  let b2 = QBase(g0, 2)
  let g1 = QExt(g0, b2)
  let wk_b2 = QTySub(g1, g0, b2, QSubP(g0, b2))
  let q_var = QTmQ(g0, b2)
  let sub_c1 = QSubExt(g0, g0, b2, QSubId(g0), QTmConst(g0, 2, 1))

  // 跨分類 QIIT 強制轉換：t[σ][τ] : Tm(·, wk_b2[sub_c1][id]) 經 QTmCoh 轉換至 Tm(·, b2)
  let t_nested = QTmSub(
    g0,
    g0,
    QTySub(g0, g1, wk_b2, sub_c1),
    QTmSub(g0, g1, wk_b2, q_var, sub_c1),
    QSubId(g0),
  )
  let t_coerced = QTmCoh(
    g0,
    QTySub(g0, g0, QTySub(g0, g1, wk_b2, sub_c1), QSubId(g0)),
    b2,
    t_nested,
  )
  @core.chk(
    out,
    "qiit-cwf-4sort-cross-equation-index-check",
    qiit_check_tm(g0, b2, t_coerced) &&
    qiit_norm_tm(t_coerced) == QTmConst(g0, 2, 1),
  )

  // 負對照 1：將基數 2 與基數 3 的不相等型別強行放入 QTmCoh 必須被索引檢查器拒絕
  let bogus_coh = QTmCoh(g0, b2, QBase(g0, 3), QTmConst(g0, 2, 1))
  @core.chk(
    out,
    "qiit-cwf-rejects-incoherent-type-coercion",
    !qiit_check_tm(g0, QBase(g0, 3), bogus_coh),
  )

  // 標準展示代數通過全部 QIIT 等式相干審計
  let std_alg = qiit_standard_set_cwf_algebra()
  @core.chk(
    out,
    "qiit-cwf-standard-displayed-algebra-coherent",
    qiit_verify_displayed_coherence(std_alg) &&
    (std_alg.con_card)(QExt(g1, QBase(g1, 3))) == 6 &&
    (std_alg.eval_tm)(t_coerced, []) == 1,
  )

  // 負對照 2：破壞 `A[id] == A` 之語法深度計數偽代數必被相干審計器拒絕
  let rec_depth = fn(ty : QiitTy) -> Int32 {
    match ty {
      QTySub(_, _, _, _) => 99
      QBase(_, k) => k
      QPi(_, _, _) => 1
    }
  }
  let bad_alg = QiitDisplayedCwfAlgebra::{
    con_card: std_alg.con_card,
    ty_fiber_card: fn(_g, a) { rec_depth(a) },
    eval_sub: std_alg.eval_sub,
    eval_tm: std_alg.eval_tm,
  }
  @core.chk(
    out,
    "qiit-cwf-rejects-syntax-sensitive-incoherent-algebra",
    !qiit_verify_displayed_coherence(bad_alg),
  )
  out
}
