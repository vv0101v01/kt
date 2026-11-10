// ===========================================================================
// 完全正則半環上的 star：以子群階倍增計算
//
// 定理（docs/DESIGN.md §3.2）：
//   若 a 落在一個階為 ord 的有限子群中，則
//       a* = 1 ⊕ a ⊕ a² ⊕ … ⊕ a^{ord-1}
//   且對任意 m 為 ord 的倍數，a* = ⊕_{k=0}^{m-1} a^k。
//   因此 star 只需 O(log m) 次 ⊗ 與 ⊕，而非 O(m) 次。
// ===========================================================================

///|
/// 平方求冪：a^k，k ≥ 0。O(log k) 次乘法。
pub fn[E : Semiring] pow_squaring(a : E, k : Int32) -> E {
  let mut result = Semiring::one()
  let mut base = a
  let mut n = k
  while n > 0 {
    if n % 2 == 1 {
      result = Semiring::times(result, base)
    }
    base = Semiring::times(base, base)
    n = n / 2
  }
  result
}

///|
/// 群版本幾何級數：以 a 的子群單位元為 1，避免跨宇宙的單位元混用。
pub fn[E : GroupElement] geom_sum_group(a : E, n : Int32) -> E {
  // 以 a 的「子群單位元」為乘法單位元，避免與 a 不同宇宙的單位元混用
  // （CyclicSet 的 one() 並不帶群階資訊）。
  if n <= 0 {
    return Semiring::zero()
  }
  let e = GroupElement::group_id(a)
  let mut acc = Semiring::zero()
  let mut ap = e
  let mut blk = e
  let mut pb = a
  let mut k = n
  while k > 0 {
    if k % 2 == 1 {
      acc = Semiring::plus(acc, Semiring::times(ap, blk))
      ap = Semiring::times(ap, pb)
    }
    blk = Semiring::plus(blk, Semiring::times(pb, blk))
    pb = Semiring::times(pb, pb)
    k = k / 2
  }
  acc
}

///|
pub fn[E : GroupElement] star_by_doubling(a : E) -> E {
  let m = GroupElement::order_bound(a)
  if m <= 0 {
    abort(
      "star_by_doubling: element has unbounded subgroup order; use an explicit StarSemiring",
    )
  }
  if m > 0x3FFF_FFFF {
    abort("star_by_doubling: subgroup order too large")
  }
  geom_sum_group(a, m)
}
