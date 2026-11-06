// ---------------------------------------------------------------------------
// meta/core — 超限序數的 Cantor 範式（CNF）
// ---------------------------------------------------------------------------
//
// 為什麼先寫序數？
//   「歸納-歸納型別」與「全域實例搜尋」都要先回答一個問題：
//   **這個遞迴／這個搜尋為什麼會停？**
//   停機的標準答案不是「看起來在變小」，而是一個到 (ε₀, <) 的嚴格下降映射。
//   所以本層的第一個結構是序數：它以 Cantor 範式儲存
//       a = ω^{e₁}·c₁ + ω^{e₂}·c₂ + … + ω^{eₖ}·cₖ ,  e₁ > e₂ > … > eₖ,  cᵢ > 0
//   範式唯一 ⇒ 相等／比較都是結構性的，不需要數值近似。
//   1 + ω = ω < ω + 1 這類「非交換」事實因此在程式裡是可判定的。

///|
/// 單項：ω^{exp} · coef，其中 coef > 0。
pub(all) struct OrdTerm {
  coef : Int32
  exp : Ordinal
}

///|
/// Cantor 範式序數：指數嚴格遞減、係數為正整數的有限和。空和就是 0。
pub(all) struct Ordinal {
  terms : Array[OrdTerm]
}

///|
/// 0。
pub fn ord_zero() -> Ordinal {
  Ordinal::{ terms: [], }
}

///|
/// coef · ω^{e}（coef ≤ 0 時退化成 0）。
pub fn ord_term(coef : Int32, e : Ordinal) -> Ordinal {
  if coef <= 0 {
    ord_zero()
  } else {
    Ordinal::{ terms: [OrdTerm::{ coef, exp: e, }], }
  }
}

///|
/// 1。
pub fn ord_one() -> Ordinal {
  ord_term(1, ord_zero())
}

///|
/// 有限序數 n。
pub fn ord_int(n : Int32) -> Ordinal {
  ord_term(n, ord_zero())
}

///|
/// ω^{k}。
pub fn ord_omega_pow(k : Ordinal) -> Ordinal {
  ord_term(1, k)
}

///|
/// 是否為 0。
pub fn ord_is_zero(a : Ordinal) -> Bool {
  a.terms.length() == 0
}

///|
/// 三向比較：-1 / 0 / 1。CNF 唯一 ⇒ 這是序數的線性序。
pub fn ord_cmp(a : Ordinal, b : Ordinal) -> Int32 {
  let na = a.terms.length()
  let nb = b.terms.length()
  let mut i = 0
  while i < na && i < nb {
    let c = ord_cmp(a.terms[i].exp, b.terms[i].exp)
    if c != 0 {
      return c
    }
    let ca = a.terms[i].coef
    let cb = b.terms[i].coef
    if ca != cb {
      return if ca < cb { -1 } else { 1 }
    }
    i = i + 1
  }
  if na == nb {
    0
  } else if na < nb {
    -1
  } else {
    1
  }
}

///|
/// 嚴格小於。
pub fn ord_lt(a : Ordinal, b : Ordinal) -> Bool {
  ord_cmp(a, b) < 0
}

///| 序數加法。吸收律在這裡是結構性的：

///|
/// 若 b 的首項指數 > a 的最末項指數，a 的尾巴整段被吸收（1 + ω = ω）。
pub fn ord_add(a : Ordinal, b : Ordinal) -> Ordinal {
  if ord_is_zero(b) {
    return a
  }
  if ord_is_zero(a) {
    return b
  }
  let bhead = b.terms[0]
  let keep : Array[OrdTerm] = []
  for t in a.terms {
    if ord_cmp(t.exp, bhead.exp) >= 0 {
      keep.push(t)
    }
  }
  let out : Array[OrdTerm] = []
  let mut start = 0
  let nk = keep.length()
  if nk > 0 && ord_cmp(keep[nk - 1].exp, bhead.exp) == 0 {
    for i in 0..<(nk - 1) {
      out.push(keep[i])
    }
    out.push(OrdTerm::{ coef: keep[nk - 1].coef + bhead.coef, exp: bhead.exp, })
    start = 1
  } else {
    for t in keep {
      out.push(t)
    }
  }
  for i in start..<b.terms.length() {
    out.push(b.terms[i])
  }
  Ordinal::{ terms: out, }
}

///|
/// 後繼 a + 1。
pub fn ord_succ(a : Ordinal) -> Ordinal {
  ord_add(a, ord_one())
}

///|
/// 右乘有限數：Σ ω^{eᵢ}·cᵢ · n = Σ ω^{eᵢ}·(cᵢ·n)。
pub fn ord_mul_int(a : Ordinal, n : Int32) -> Ordinal {
  if n <= 0 || ord_is_zero(a) {
    return ord_zero()
  }
  let out : Array[OrdTerm] = []
  for t in a.terms {
    out.push(OrdTerm::{ coef: t.coef * n, exp: t.exp, })
  }
  Ordinal::{ terms: out, }
}

///| 左乘 ω，也就是「把整個序數往上升一格」：

///| a = ω^{e₀}c₀ + … ≠ 0 ⇒ a·ω = ω^{e₀+1}。

///|
/// 這是擴張式（expanding）終止性度量最常用的一步。
pub fn ord_mul_omega(a : Ordinal) -> Ordinal {
  if ord_is_zero(a) {
    ord_zero()
  } else {
    ord_term(1, ord_succ(a.terms[0].exp))
  }
}

///|
/// 取大（終止性度量併合時用）。
pub fn ord_max(a : Ordinal, b : Ordinal) -> Ordinal {
  if ord_lt(a, b) {
    b
  } else {
    a
  }
}

///|
/// 印成 ω 符號形式，僅供報告閱讀。
pub fn ord_to_string(a : Ordinal) -> String {
  if ord_is_zero(a) {
    return "0"
  }
  let parts : Array[String] = []
  for t in a.terms {
    let e = t.exp
    let base = if ord_is_zero(e) {
      "1"
    } else if ord_cmp(e, ord_one()) == 0 {
      "w"
    } else {
      "w^(\{ord_to_string(e)})"
    }
    if ord_is_zero(e) {
      parts.push("\{t.coef}")
    } else if t.coef == 1 {
      parts.push(base)
    } else {
      parts.push("\{t.coef}*\{base}")
    }
  }
  parts.join(" + ")
}

// ---------------------------------------------------------------------------
// 白箱檢查：CNF 的範式性與吸收律
// ---------------------------------------------------------------------------

///|
/// 範式不變量：指數嚴格遞減、係數為正。
pub fn ord_is_normal(a : Ordinal) -> Bool {
  if ord_is_zero(a) {
    return true
  }
  let mut i = 0
  while i < a.terms.length() {
    if a.terms[i].coef <= 0 {
      return false
    }
    if !ord_is_normal(a.terms[i].exp) {
      return false
    }
    if i > 0 && ord_cmp(a.terms[i - 1].exp, a.terms[i].exp) <= 0 {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// 檢查一組序數恆等式，回傳失敗的索引（-1 表示全過）。
pub fn ord_probe_laws() -> Int32 {
  let w = ord_omega_pow(ord_one()) // ω
  let w2 = ord_omega_pow(ord_int(2))
  let ww = ord_omega_pow(w)
  let wtower = ord_omega_pow(ww) // ω^(ω^ω)
  let cases : Array[Bool] = [
    // 吸收律：1 + ω = ω
    ord_cmp(ord_add(ord_one(), w), w) == 0,
    // 但 ω + 1 > ω
    ord_lt(w, ord_add(w, ord_one())),
    // ω·2 = ω + ω
    ord_cmp(ord_add(w, w), ord_mul_int(w, 2)) == 0,
    // 1 + (ω + 1) = ω + 1
    ord_cmp(ord_add(ord_one(), ord_add(w, ord_one())), ord_add(w, ord_one())) ==
    0,
    // ω + ω² = ω²
    ord_cmp(ord_add(w, w2), w2) == 0,
    // ω^ω > ω·n 對任何有限 n
    ord_lt(ord_mul_int(w, 1000000), ww),
    // 序數加法結合律（樣本）
    ord_cmp(
      ord_add(ord_add(ord_int(3), w), ord_one()),
      ord_add(ord_int(3), ord_add(w, ord_one())),
    ) ==
    0,
    // 塔：ω^{ω^ω} 是範式且嚴格大於 ω^ω
    ord_is_normal(wtower) && ord_lt(ww, wtower),
    // 範式性在加法下封閉
    ord_is_normal(ord_add(ord_add(w2, ord_mul_int(w, 3)), ord_int(7))),
    // ω 左乘把指數抬一格：ω^2 · ω = ω^3
    ord_cmp(ord_mul_omega(ord_omega_pow(ord_int(2))), ord_omega_pow(ord_int(3))) ==
    0,
  ]
  let mut bad = -1
  for i in 0..<cases.length() {
    if !cases[i] && bad < 0 {
      bad = i
    }
  }
  bad
}

///|
pub fn law_ordinal_ordinal_cnf_laws() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  chk(out, "ordinal CNF laws #1", ord_probe_laws() == -1)
  chk(
    out,
    "ordinal CNF laws #2",
    ord_to_string(ord_add(ord_one(), ord_omega_pow(ord_one()))) == "w",
  )
  out
}

///|
pub fn law_ordinal_ord_max_is_the_lattice_join() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let w = ord_omega_pow(ord_one())
  let cases : Array[(Ordinal, Ordinal)] = [
    (ord_zero(), ord_one()),
    (ord_one(), w),
    (w, ord_add(w, ord_one())),
    (ord_int(3), ord_int(7)),
  ]
  for (a, b) in cases {
    let m = ord_max(a, b)
    // 上界
    chk(
      out,
      "ordinal: ord_max is the lattice join #1",
      ord_lt(a, m) || ord_cmp(a, m) == 0,
    )
    chk(
      out,
      "ordinal: ord_max is the lattice join #2",
      ord_lt(b, m) || ord_cmp(b, m) == 0,
    )
    // 而且恰是兩者之一（全序）
    chk(
      out,
      "ordinal: ord_max is the lattice join #3",
      ord_cmp(m, a) == 0 || ord_cmp(m, b) == 0,
    )
    // 對稱
    chk(
      out,
      "ordinal: ord_max is the lattice join #4",
      ord_cmp(ord_max(a, b), ord_max(b, a)) == 0,
    )
  }
  out
}
