///|
/// # PermSet — 置換集（非群）之規範形式與同構判定
///
/// `PermSet { n, gens }` 只是一組置換（**不必**封閉），代表「有向標號結構」之自同構候選集；
/// 其規範形式 = 在所有重標號 λ 下取字典序最小之編碼 ⇒ 兩個置換集共軛 iff 規範形式相同。
///
/// 注意：`permset_canon` 內部窮舉 n! 個重標號 ⇒ 每項成本 O(n!)；
/// 與逐對暴力比較之交叉點約在 n=6 之 41 項 / n=7 之 23 項（見 bench E 節）。

///|
/// G-集之編碼（給定標號 λ 下之生成元像串接）：G-集規範形式之原料。
pub(all) struct PermSet {
  n : Int32
  gens : Array[Perm]
}

///|
/// 由生成元建構 G-集（同一抽象群、不同作用）。
pub fn permset(n : Int32, gens : Array[Perm]) -> PermSet {
  for p in gens {
    guard p.size() == n else { abort("permset: generator size mismatch") }
  }
  { n, gens, }
}

///|
/// 標號 λ（位置 → 原點）下之編碼：逐生成元串接 λ^{-1}∘p∘λ 之像。
pub fn permset_encoding(ps : PermSet, lambda : Perm) -> Array[Int32] {
  let linv = lambda.inverse()
  let out : Array[Int32] = []
  for p in ps.gens {
    let q = linv.compose(p).compose(lambda)
    for i in 0..<ps.n {
      out.push(q.apply(i))
    }
  }
  out
}

///|
/// G-集之規範形式：全部標號下編碼之字典序最小者（n ≤ 8 暴力）。
pub fn permset_canon(ps : PermSet, cap : Int32) -> Array[Int32] {
  let perms = all_perms(ps.n, cap)
  let mut best : Array[Int32] = []
  for l in perms {
    let enc = permset_encoding(ps, l)
    if best.length() == 0 || cmp_arr(enc, best) < 0 {
      best = enc
    }
  }
  best
}

///|
/// G-集規範形式之機器證書：
/// (a) 重標號不變性；(b) 冪等性（規範化後再規範化不變）；
/// (c) 與「共軛」判準一致：b = λ^{-1}∘a∘λ ⇒ 同構。
