// ---------------------------------------------------------------------------
// ualg/core — 特徵值譜 σ(T)：精確特徵多項式、函數圖譜、商的整除性
// ---------------------------------------------------------------------------
//
// 全域公理定調：系統表述為線性空間上的映射 T，其不變量集是譜 σ(T)。
// 這裡把它落成可計算的敘述（全部在 ℤ 上精確，無浮點）：
// [A-FL]    Faddeev–LeVerrier：M ← A·M + c·I，c_{n-k} = −tr(A·M)/k（整除精確）。
// [A-Bar]   Bareiss 免分式消元求 det——獨立路徑：在 n+1 個整點比對 det(xI−A)。
// [T-Fun]   映射 f : A → A 的線性化 T_f（T[f(a)][a] = 1）：
//           χ(T_f) = x^t · ∏_{圈 c} (x^{|c|} − 1)，t = 非循環元素數。
//           ⇒ 特徵值 1 的重數 = 圈數（置換時 = 軌道數）：「共振 ⇔ 不變量」。
// [T-Quot]  θ 與 f 相容 ⇒ χ(T_{f/θ}) | χ(T_f)：商代數的譜含於原代數的譜。

///|
pub fn mat_charpoly(a : Array[Array[BigInt]]) -> Array[BigInt] {
  let n = a.length()
  let c = Array::make(n + 1, 0N)
  c[n] = 1N
  let mut m = Array::makei(n, i => Array::makei(n, j => if i == j { 1N } else { 0N }))
  for k in 1..<=n {
    let am = Array::makei(n, i => Array::makei(n, j => {
      let mut s = 0N
      for l in 0..<n {
        s = s + a[i][l] * m[l][j]
      }
      s
    }))
    let mut tr = 0N
    for i in 0..<n {
      tr = tr + am[i][i]
    }
    let ck = -tr / BigInt::from_int(k)
    c[n - k] = ck
    for i in 0..<n {
      am[i][i] = am[i][i] + ck
    }
    m = am
  }
  c
}

///|
/// [A-Bar] Bareiss 行列式（免分式；每步除法精確）。
pub fn mat_det(a : Array[Array[BigInt]]) -> BigInt {
  let n = a.length()
  if n == 0 {
    return 1N
  }
  let m = a.map(r => r.copy())
  let mut sign = 1N
  let mut prev = 1N
  for k in 0..<(n - 1) {
    if m[k][k] == 0N {
      let mut sw = -1
      for i in (k + 1)..<n {
        if sw < 0 && m[i][k] != 0N {
          sw = i
        }
      }
      if sw < 0 {
        return 0N
      }
      let tmp = m[k]
      m[k] = m[sw]
      m[sw] = tmp
      sign = -sign
    }
    for i in (k + 1)..<n {
      for j in (k + 1)..<n {
        m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) / prev
      }
    }
    prev = m[k][k]
  }
  sign * m[n - 1][n - 1]
}

///|
pub fn poly_eval(p : Array[BigInt], x : BigInt) -> BigInt {
  let mut r = 0N
  let mut i = p.length() - 1
  while i >= 0 {
    r = r * x + p[i]
    i = i - 1
  }
  r
}

///|
pub fn poly_mul(p : Array[BigInt], q : Array[BigInt]) -> Array[BigInt] {
  let r = Array::make(p.length() + q.length() - 1, 0N)
  for i in 0..<p.length() {
    for j in 0..<q.length() {
      r[i + j] = r[i + j] + p[i] * q[j]
    }
  }
  r
}

///|
/// 以首一多項式 q 除 p；回傳（商, 餘式是否為零）。
pub fn poly_div_monic(
  p : Array[BigInt],
  q : Array[BigInt],
) -> (Array[BigInt], Bool) {
  let r = p.copy()
  let dq = q.length() - 1
  let dp = p.length() - 1
  if dp < dq {
    return ([], false)
  }
  let quo = Array::make(dp - dq + 1, 0N)
  let mut i = dp
  while i >= dq {
    let coef = r[i]
    quo[i - dq] = coef
    for j in 0..<=dq {
      r[i - dq + j] = r[i - dq + j] - coef * q[j]
    }
    i = i - 1
  }
  let mut zero = true
  for v in r {
    if v != 0N {
      zero = false
    }
  }
  (quo, zero)
}

///|
/// 整數根 r 在 p 中的重數（反覆綜合除法）。
pub fn root_multiplicity(p : Array[BigInt], r : Int32) -> Int32 {
  let lin = [-BigInt::from_int(r), 1N]
  let mut cur = p
  let mut m = 0
  while cur.length() > 1 {
    let (q, zero) = poly_div_monic(cur, lin)
    if !zero {
      break
    }
    cur = q
    m = m + 1
  }
  m
}

///|
/// xI − A 在整點 x 的行列式。
fn char_det_at(a : Array[Array[BigInt]], x : Int32) -> BigInt {
  let n = a.length()
  mat_det(
    Array::makei(n, i => Array::makei(n, j => if i == j {
      BigInt::from_int(x) - a[i][j]
    } else {
      -a[i][j]
    })),
  )
}

///|
/// 兩條路徑一致：FL 的多項式在 x = 0..n 的值 = Bareiss 的 det(xI − A)。
pub fn charpoly_cross_checked(a : Array[Array[BigInt]]) -> Bool {
  let p = mat_charpoly(a)
  for x in 0..<=a.length() {
    if poly_eval(p, BigInt::from_int(x)) != char_det_at(a, x) {
      return false
    }
  }
  true
}

///|
pub fn functional_matrix(f : Array[Int32]) -> Array[Array[BigInt]] {
  let n = f.length()
  Array::makei(n, i => Array::makei(n, j => if f[j] == i { 1N } else { 0N }))
}

///|
/// f 的圈長列表與非循環元素數。
pub fn cycle_type(f : Array[Int32]) -> (Array[Int32], Int32) {
  let n = f.length()
  // f^n 的像恰為循環元素
  let cyclic = Array::make(n, false)
  for a in 0..<n {
    let mut x = a
    for _ in 0..<n {
      x = f[x]
    }
    cyclic[x] = true
  }
  let seen = Array::make(n, false)
  let cycles : Array[Int32] = []
  let mut transient = 0
  for a in 0..<n {
    if !cyclic[a] {
      transient = transient + 1
    } else if !seen[a] {
      let mut len = 0
      let mut x = a
      while !seen[x] {
        seen[x] = true
        x = f[x]
        len = len + 1
      }
      cycles.push(len)
    }
  }
  cycles.sort()
  (cycles, transient)
}

///|
/// [T-Fun] 由圈型直接寫出 χ(T_f)。
pub fn functional_charpoly(f : Array[Int32]) -> Array[BigInt] {
  let (cycles, t) = cycle_type(f)
  let mut p = Array::make(t + 1, 0N)
  p[t] = 1N
  for len in cycles {
    let q = Array::make(len + 1, 0N)
    q[0] = -1N
    q[len] = 1N
    p = poly_mul(p, q)
  }
  p
}

///|
/// 代數的全部基本平移 x ↦ f(c̄, x, c̄')（去重）。
pub fn basic_translations(a : Alg) -> Array[Array[Int32]] {
  let n = a.n
  let seen : Map[String, Bool] = Map([])
  let out : Array[Array[Int32]] = []
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
        let t = Array::makei(n, x => op.table[base + x * w])
        let k = tuple_key(t)
        if !seen.contains(k) {
          seen[k] = true
          out.push(t)
        }
      }
      w = w * n
    }
  }
  out
}

///|
/// 定律：σ(T) 的三個可計算敘述。
pub fn law_spectrum_functional_and_quotient() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let zoo = [
    alg_zn(6),
    alg_zn_mul(6),
    alg_s3(),
    alg_dm4(),
    alg_chain(4),
    alg_gf2k(3, 11),
  ]
  let mut fl_ok = true
  let mut fun_ok = true
  let mut res_ok = true
  let mut maps = 0
  for a in zoo {
    for t in basic_translations(a) {
      let m = functional_matrix(t)
      let p = mat_charpoly(m)
      let (cycles, transient) = cycle_type(t)
      maps = maps + 1
      if !charpoly_cross_checked(m) {
        fl_ok = false
      }
      if p != functional_charpoly(t) {
        fun_ok = false
      }
      if root_multiplicity(p, 1) != cycles.length() ||
        root_multiplicity(p, 0) != transient {
        res_ok = false
      }
    }
  }
  chk(
    out,
    "特徵多項式兩條路徑：Faddeev–LeVerrier = Bareiss 在 n+1 個整點的 det(xI−T)（\{maps} 個基本平移）",
    fl_ok,
  )
  chk(
    out,
    "函數圖譜定理：χ(T_f) = x^t·∏(x^|c| − 1)，由圈型寫出的多項式與 FL 逐係數相同（\{maps} 個映射）",
    fun_ok,
  )
  chk(
    out,
    "共振 ⇔ 不變量：特徵值 1 的重數 = 圈數，特徵值 0 的重數 = 非循環元素數",
    res_ok,
  )
  // 商的整除性
  let mut div_ok = true
  let mut inst = 0
  for a in [alg_zn(6), alg_zn_mul(6), alg_s3(), alg_chain(4), alg_n5()] {
    for th in con_lattice(a) {
      let (q, pi) = quotient(a, th)
      for t in basic_translations(a) {
        // 平移降到商：t̄([x]) = [t(x)]（同餘保證良定義）
        let tq = Array::make(q.n, -1)
        for x in 0..<a.n {
          tq[pi[x]] = pi[t[x]]
        }
        inst = inst + 1
        let (_, zero) = poly_div_monic(
          functional_charpoly(t),
          functional_charpoly(tq),
        )
        if !zero {
          div_ok = false
        }
      }
    }
  }
  chk(
    out,
    "譜的商定理：θ ∈ Con(A) ⇒ χ(T_{f/θ}) 整除 χ(T_f)（\{inst} 組 (A,θ,f)，ℤ[x] 上餘式為零）",
    div_ok,
  )
  // 反例對照：x⁶−1 不被 x⁴−1 整除（ℤ6 沒有 4 元循環商）
  let c6 = functional_charpoly([1, 2, 3, 4, 5, 0])
  let c4 = functional_charpoly([1, 2, 3, 0])
  let c3 = functional_charpoly([1, 2, 0])
  chk(
    out,
    "反例對照：x³−1 整除 x⁶−1，但 x⁴−1 不整除 x⁶−1（整除性檢查會拒絕）",
    poly_div_monic(c6, c3).1 && !poly_div_monic(c6, c4).1,
  )
  // 一般整數矩陣上兩條路徑仍一致（不只 0/1 矩陣）
  let mut gen_ok = true
  let mut s = 20261110
  for n in 1..<=6 {
    let m = Array::makei(n, _ => Array::make(n, 0N))
    for i in 0..<n {
      for j in 0..<n {
        s = (s * 1103515245 + 12345) & 0x7fffffff
        m[i][j] = BigInt::from_int(((s >> 12) & 15) - 7)
      }
    }
    if !charpoly_cross_checked(m) {
      gen_ok = false
    }
  }
  chk(out, "一般整數矩陣（1×1 至 6×6，元素 −7..8）：FL 與 Bareiss 一致", gen_ok)
  out
}
