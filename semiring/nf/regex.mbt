// ===========================================================================
// 規範形式 I：Kleene 代數的正規化（ACI 正規形 + Brzozowski 導數）
//
// 正規表示式在 Kleene 代數裡是同一個元素的許多種寫法。要把它們「壓成
// 唯一代表」，需要兩層：
//
//   1. **ACI 正規形**（本檔）：⊕ 滿足結合律、交換律、冪等律，所以每個
//      `RSum` 都攤平成一個**排序去重後的集合**；`RProd` 用 0/1 吸收律化簡；
//      `RStar` 用 0* = 1* = 1、(a*)* = a* 化簡。
//      沒有這一層，導數集合不會有限，自動機就建不出來。
//
//   2. **Myhill–Nerode 正規形**（dfa.mbt）：所有猜測同一語言的表示式，
//      其最小 DFA 在固定字母表順序下**逐位元相同**（canonical）。
//      於是「兩個表示式是否相等」變成「兩台最小 DFA 的字串是否相同」。
//
// 為什麼要用排序而不是雜湊：正規形必須是**結構相等**可判定的，
// 而且排序要是全序（不能依賴指標或插入順序），否則同一語言會有兩個正規形。
// ===========================================================================

///|
/// 正規表示式的語法樹（Kleene 代數的自由項）。
pub(all) enum Regex {
  RZero
  ROne
  RChar(Int32)
  RSum(Regex, Regex)
  RProd(Regex, Regex)
  RStar(Regex)
}

///|
/// 構造子的排序權重（用於建立結構全序）。
pub fn Regex::rank(self : Regex) -> Int32 {
  match self {
    RZero => 0
    ROne => 1
    RChar(_) => 2
    RSum(_, _) => 3
    RProd(_, _) => 4
    RStar(_) => 5
  }
}

///|
/// 結構全序：先比構造子，再比子項（左優先）。
/// 回傳 −1 / 0 / 1。這是 ⊕ 攤平後排序的依據。
pub fn regex_cmp(a : Regex, b : Regex) -> Int32 {
  let ra = a.rank()
  let rb = b.rank()
  if ra != rb {
    return if ra < rb { -1 } else { 1 }
  }
  match (a, b) {
    (RZero, RZero) => 0
    (ROne, ROne) => 0
    (RChar(x), RChar(y)) => if x == y { 0 } else if x < y { -1 } else { 1 }
    (RStar(x), RStar(y)) => regex_cmp(x, y)
    (RSum(x1, x2), RSum(y1, y2)) => {
      let c = regex_cmp(x1, y1)
      if c != 0 {
        c
      } else {
        regex_cmp(x2, y2)
      }
    }
    (RProd(x1, x2), RProd(y1, y2)) => {
      let c = regex_cmp(x1, y1)
      if c != 0 {
        c
      } else {
        regex_cmp(x2, y2)
      }
    }
    _ => 0
  }
}

///|
/// ACI 正規形的 ⊕：攤平 → 排序 → 去重 → 丟掉 0 → 右結合重建。
pub fn r_sum(a : Regex, b : Regex) -> Regex {
  let parts : Array[Regex] = []
  flatten_sum(a, parts)
  flatten_sum(b, parts)
  // 插入排序
  let mut i = 1
  while i < parts.length() {
    let key = parts[i]
    let mut j = i
    while j > 0 && regex_cmp(parts[j - 1], key) > 0 {
      parts[j] = parts[j - 1]
      j = j - 1
    }
    parts[j] = key
    i = i + 1
  }
  let uniq : Array[Regex] = []
  for p in parts {
    if p.rank() == 0 {
      continue
    }
    if uniq.length() == 0 || regex_cmp(uniq[uniq.length() - 1], p) != 0 {
      uniq.push(p)
    }
  }
  if uniq.length() == 0 {
    return RZero
  }
  if uniq.length() == 1 {
    return uniq[0]
  }
  let mut acc = uniq[uniq.length() - 1]
  let mut k = uniq.length() - 2
  while k >= 0 {
    acc = RSum(uniq[k], acc)
    k = k - 1
  }
  acc
}

///|
fn flatten_sum(r : Regex, out : Array[Regex]) -> Unit {
  match r {
    RSum(x, y) => {
      flatten_sum(x, out)
      flatten_sum(y, out)
    }
    _ => out.push(r)
  }
}

///|
/// ACI 正規形的 ⊗：0 吸收、1 單位、其餘原樣組合成右結合鏈。
pub fn r_prod(a : Regex, b : Regex) -> Regex {
  if a.rank() == 0 || b.rank() == 0 {
    return RZero
  }
  if a.rank() == 1 {
    return b
  }
  if b.rank() == 1 {
    return a
  }
  RProd(a, b)
}

///|
/// ACI 正規形的 *：0* = 1、1* = 1、(a*)* = a*。
pub fn r_star(a : Regex) -> Regex {
  match a {
    RZero => ROne
    ROne => ROne
    RStar(_) => a
    _ => RStar(a)
  }
}

///|
/// 是否接受空字（ε ∈ L(r)）。
pub fn nullable(r : Regex) -> Bool {
  match r {
    RZero => false
    ROne => true
    RChar(_) => false
    RSum(x, y) => nullable(x) || nullable(y)
    RProd(x, y) => nullable(x) && nullable(y)
    RStar(_) => true
  }
}

///|
/// Brzozowski 導數：`∂_c L = { w | cw ∈ L }`。
///
/// 四條規則（最後一條是關鍵）：
///   ∂(a) = 1 (a = c) / 0
///   ∂(x+y) = ∂x + ∂y
///   ∂(xy) = ∂x·y + ν(x)·∂y
///   ∂(x*) = ∂x·x*
///
/// 因為構造子會把結果壓回 ACI 正規形，導數的集合是有限的
/// ⇒ 可以把「表示式」當成狀態，直接做出 DFA。
pub fn deriv(r : Regex, c : Int32) -> Regex {
  match r {
    RZero => RZero
    ROne => RZero
    RChar(x) => if x == c { ROne } else { RZero }
    RSum(x, y) => r_sum(deriv(x, c), deriv(y, c))
    RProd(x, y) => {
      let dx = r_prod(deriv(x, c), y)
      if nullable(x) {
        r_sum(dx, deriv(y, c))
      } else {
        dx
      }
    }
    RStar(x) => r_prod(deriv(x, c), RStar(x))
  }
}
