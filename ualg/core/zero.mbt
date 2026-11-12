// ---------------------------------------------------------------------------
// ualg/core — 吸收元與零元、單位元、理想、Rees 商
// ---------------------------------------------------------------------------
//
// [D-Abs]  z 是左吸收元：z·x = z；右吸收元：x·z = z；零元 = 兩者皆是。
// [T-Zero] 左吸收元 l 與右吸收元 r 並存 ⇒ l = l·r = r；故零元唯一。
//          （只有單邊時可以有很多個：左零帶每個元素都是左吸收元。）
// [T-Rees] 半群 S 的理想 I：ρ_I = (I×I) ∪ Δ 是同餘，S/ρ_I 以類 I 為零元。
//          「吸收元＋零元」與「同餘＋商代數」在這裡是同一件事。
// [T-Ker]  有限半群有最小理想 K(S)；S 有零元 ⇔ |K(S)| = 1。

///|
pub fn left_absorbing(table : Array[Int32], n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for z in 0..<n {
    let mut ok = true
    for x in 0..<n {
      if table[z + n * x] != z {
        ok = false
      }
    }
    if ok {
      out.push(z)
    }
  }
  out
}

///|
pub fn right_absorbing(table : Array[Int32], n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for z in 0..<n {
    let mut ok = true
    for x in 0..<n {
      if table[x + n * z] != z {
        ok = false
      }
    }
    if ok {
      out.push(z)
    }
  }
  out
}

///|
pub fn left_identities(table : Array[Int32], n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for e in 0..<n {
    let mut ok = true
    for x in 0..<n {
      if table[e + n * x] != x {
        ok = false
      }
    }
    if ok {
      out.push(e)
    }
  }
  out
}

///|
pub fn right_identities(table : Array[Int32], n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for e in 0..<n {
    let mut ok = true
    for x in 0..<n {
      if table[x + n * e] != x {
        ok = false
      }
    }
    if ok {
      out.push(e)
    }
  }
  out
}

///|
fn both(xs : Array[Int32], ys : Array[Int32]) -> Array[Int32] {
  xs.filter(x => ys.contains(x))
}

///|
/// 零元（雙邊吸收元）；至多一個。
pub fn zeros(table : Array[Int32], n : Int32) -> Array[Int32] {
  both(left_absorbing(table, n), right_absorbing(table, n))
}

///|
pub fn identities(table : Array[Int32], n : Int32) -> Array[Int32] {
  both(left_identities(table, n), right_identities(table, n))
}

///|
pub fn is_associative(table : Array[Int32], n : Int32) -> Bool {
  for x in 0..<n {
    for y in 0..<n {
      for z in 0..<n {
        if table[table[x + n * y] + n * z] != table[x + n * table[y + n * z]] {
          return false
        }
      }
    }
  }
  true
}

///|
/// I（位元遮罩）是雙邊理想：非空且 S·I ∪ I·S ⊆ I。
pub fn is_ideal(table : Array[Int32], n : Int32, mask : Int32) -> Bool {
  if mask == 0 {
    return false
  }
  for i in 0..<n {
    if ((mask >> i) & 1) != 0 {
      for s in 0..<n {
        if ((mask >> table[s + n * i]) & 1) == 0 ||
          ((mask >> table[i + n * s]) & 1) == 0 {
          return false
        }
      }
    }
  }
  true
}

///|
/// 主理想 S¹xS¹。
pub fn principal_ideal(table : Array[Int32], n : Int32, x : Int32) -> Int32 {
  let mut mask = 1 << x
  let mut changed = true
  while changed {
    changed = false
    for i in 0..<n {
      if ((mask >> i) & 1) != 0 {
        for s in 0..<n {
          let l = table[s + n * i]
          let r = table[i + n * s]
          if ((mask >> l) & 1) == 0 {
            mask = mask | (1 << l)
            changed = true
          }
          if ((mask >> r) & 1) == 0 {
            mask = mask | (1 << r)
            changed = true
          }
        }
      }
    }
  }
  mask
}

///|
/// 全部理想 = 主理想在聯集下的閉包。
pub fn ideals(table : Array[Int32], n : Int32) -> Array[Int32] {
  let seen : Map[Int32, Bool] = Map([])
  let list : Array[Int32] = []
  let prin : Array[Int32] = []
  for x in 0..<n {
    let p = principal_ideal(table, n, x)
    if !seen.contains(p) {
      seen[p] = true
      list.push(p)
      prin.push(p)
    }
  }
  let mut i = 0
  while i < list.length() {
    for p in prin {
      let u = list[i] | p
      if !seen.contains(u) {
        seen[u] = true
        list.push(u)
      }
    }
    i = i + 1
  }
  list.sort()
  list
}

///|
/// 獨立路徑：窮舉 2^n − 1 個非空子集。
pub fn ideals_bruteforce(table : Array[Int32], n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for mask in 1..<(1 << n) {
    if is_ideal(table, n, mask) {
      out.push(mask)
    }
  }
  out
}

///|
/// Rees 分割：I 塌成一塊，其餘為單點。
pub fn rees_partition(n : Int32, mask : Int32) -> Array[Int32] {
  part_norm(Array::makei(n, i => if ((mask >> i) & 1) != 0 { n } else { i }))
}

///|
/// 定律：零元唯一性在 3 元集合上的**全部** 19,683 個二元運算上成立，並對上閉式計數。
pub fn law_zero_and_absorbing_census() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let n = 3
  let mut with_zero = 0
  let mut with_id = 0
  let mut with_both = 0
  let mut two_left = 0
  let mut clash = 0
  let mut multi_zero = 0
  let mut id_clash = 0
  for code in 0..<19683 {
    let t = digits(code, n, 9)
    let la = left_absorbing(t, n)
    let ra = right_absorbing(t, n)
    let z = both(la, ra)
    let li = left_identities(t, n)
    let ri = right_identities(t, n)
    let e = both(li, ri)
    if z.length() > 0 {
      with_zero = with_zero + 1
    }
    if z.length() > 1 {
      multi_zero = multi_zero + 1
    }
    if e.length() > 0 {
      with_id = with_id + 1
    }
    if z.length() > 0 && e.length() > 0 {
      with_both = with_both + 1
    }
    if la.length() >= 2 {
      two_left = two_left + 1
    }
    // 左吸收元與右吸收元並存卻不相等？（定理說不可能）
    if la.length() > 0 && ra.length() > 0 && (la.length() != 1 || la != ra) {
      clash = clash + 1
    }
    if li.length() > 0 && ri.length() > 0 && (li.length() != 1 || li != ri) {
      id_clash = id_clash + 1
    }
  }
  chk(
    out,
    "零元唯一：19,683 個 3 元原群中，左、右吸收元並存而不重合者 \{clash} 個；有兩個零元者 \{multi_zero} 個",
    clash == 0 && multi_zero == 0,
  )
  chk(
    out,
    "單位元唯一：左、右單位元並存而不重合者 \{id_clash} 個",
    id_clash == 0,
  )
  chk(
    out,
    "計數對閉式：有零元 \{with_zero} = 3·3⁴；有單位元 \{with_id} = 3·3⁴；兩者皆有 \{with_both} = 6·3",
    with_zero == 243 && with_id == 243 && with_both == 18,
  )
  chk(
    out,
    "反例對照：單邊吸收元不唯一——至少兩個左吸收元的原群有 \{two_left} = 3·27 − 2 個",
    two_left == 79,
  )
  // 有界格的對偶：0 是 ∧ 的零元、∨ 的單位元；1 反之
  let mut dual = true
  for
    a in [
      alg_bool2(),
      alg_kleene3(),
      alg_dm4(),
      alg_chain(5),
      alg_m3(),
      alg_n5(),
    ] {
    let m = a.ops[0].table
    let j = a.ops[1].table
    if zeros(m, a.n) != identities(j, a.n) ||
      zeros(j, a.n) != identities(m, a.n) ||
      zeros(m, a.n).length() != 1 {
      dual = false
    }
  }
  chk(
    out, "有界格對偶（𝟚、𝟛、𝟜、Chain5、M3、N5）：∧ 的零元 = ∨ 的單位元，∨ 的零元 = ∧ 的單位元",
    dual,
  )
  out
}

///|
/// 定律：理想的兩條列舉路徑、Rees 商、核與零元。
pub fn law_ideals_and_rees_quotient() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let zoo = [
    alg_zn_mul(6),
    alg_zn_mul(8),
    alg_zn_mul(12),
    alg_rect_band(2, 2),
    alg_chain(4),
    alg_s3(),
  ]
  let mut same = true
  let mut rees = true
  let mut ker = true
  let counts : Array[Int32] = []
  let mut total = 0
  for a in zoo {
    let t = a.ops[0].table
    let n = a.n
    let semigroup : Alg = { name: a.name, n, ops: [a.ops[0]], }
    let i1 = ideals(t, n)
    let i2 = ideals_bruteforce(t, n)
    counts.push(i1.length())
    if i1 != i2 || !is_associative(t, n) {
      same = false
    }
    let mut kernel_mask = (1 << n) - 1
    for mask in i1 {
      kernel_mask = kernel_mask & mask
      let p = rees_partition(n, mask)
      let (q, pi) = quotient(semigroup, p)
      total = total + 1
      // 類 I 的序號
      let mut zi = -1
      for i in 0..<n {
        if ((mask >> i) & 1) != 0 {
          zi = pi[i]
        }
      }
      if !is_congruence(semigroup, p) || zeros(q.ops[0].table, q.n) != [zi] {
        rees = false
      }
    }
    // 核是理想，且「有零元 ⇔ 核是單點」
    let has_zero = zeros(t, n).length() == 1
    if !is_ideal(t, n, kernel_mask) || has_zero != (kernel_mask.popcnt() == 1) {
      ker = false
    }
  }
  chk(
    out,
    "理想：主理想聯集閉包 = 2ⁿ 窮舉；各半群理想數 \{show_ints(counts)}（(ℤ6,·)、(ℤ8,·)、(ℤ12,·)、Rect2×2、(Chain4,∧)、S3）",
    same,
  )
  chk(
    out,
    "Rees 商：\{total} 個理想的 ρ_I 都是同餘，且 S/ρ_I 的零元恰為類 I",
    rees,
  )
  chk(
    out, "核 K(S) 是最小理想；S 有零元 ⇔ |K(S)| = 1（六個半群）",
    ker,
  )
  // 反例對照：非理想子集的 Rees 分割不是同餘
  let z6 = alg_zn_mul(6)
  let mask12 = 0b110
  chk(
    out,
    "反例：(ℤ6,·) 中 {1,2} 不是理想，其 Rees 分割不是同餘",
    !is_ideal(z6.ops[0].table, 6, mask12) &&
    !is_congruence(z6, rees_partition(6, mask12)),
  )
  out
}
