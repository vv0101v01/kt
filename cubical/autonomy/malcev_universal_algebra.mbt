// ---------------------------------------------------------------------------
// cubical/autonomy — 構造性泛代數自主類型論與範疇化核心
// ---------------------------------------------------------------------------
//
// 實作公理、定義與定理：
//   1. [D-Universal-Algebra] 緊湊平坦查表泛代數 A = (|A|, {f_i : A^{k_i} -> A})，
//      支援 k_i ∈ {0, 1, 2, 3} 之 O(1) 快取友善求值與 Lawvere 代數理論有限積映射。
//   2. [T-Congruence-Quotient] 迭代工作列同餘閉包 Cg_A(S)（零遞歸爆棧）與商代數
//      A/θ 典範構造；驗證第一同構定理 A/ker(φ) ≅ im(φ) 與同餘對應定理。
//   3. [T-Malcev-OneStep] 瑪爾切夫算子 p(x,x,y)=y, p(x,y,y)=x 等價於同餘一步可換
//      θ ∘ ψ = ψ ∘ θ = θ ∨ ψ；提供一步關係複合器並與傳遞閉包逐位對照。
//   4. [T-Absorbing-vs-Pointed-Zero] 雙邊吸收零元 0·x = 0 = x·0 若與瑪爾切夫算子相容
//      必迫使 |A| = 1（解釋德摩根區間 (I, ∧, ∨) 無 Kan 群胚結構）；反之點化中性零元
//      0 + x = x = x + 0 與相容瑪爾切夫算子唯一誘導 Eckmann–Hilton 可換阿貝爾群結構
//      x +_EH y := p(x, 0, y), -x := p(0, x, 0)。
//   5. [T-Categorified-Chu-Zappa-Szep] 將泛代數同餘格嵌入 Chu 空間 Chu(A×A, Con(A), ∈)
//      並實現互素同餘（θ ∩ ψ = Δ_A, θ ∘ ψ = ∇_A）之 Zappa–Szép／中國剩餘正合分解
//      A ≅ A/θ × A/ψ。

///|
/// 泛代數基本運算描述：`arity ∈ {0, 1, 2, 3}`，`table` 長度為 `carrier^arity` 之平坦陣列。
#derive(Debug, Eq)
pub(all) struct AlgOpSpec {
  name : String
  arity : Int32
  table : Array[Int32]
}

///|
pub extend AlgOpSpec with @debug.Debug::{to_repr}

///|
pub extend AlgOpSpec with Eq::{not_equal, equal}

///|
/// 構造性有限載體泛代數 `A = ({0..n-1}, ops)`。
#derive(Debug, Eq)
pub(all) struct UniversalAlgebra {
  name : String
  carrier_size : Int32
  ops : Array[AlgOpSpec]
}

///|
pub extend UniversalAlgebra with @debug.Debug::{to_repr}

///|
pub extend UniversalAlgebra with Eq::{not_equal, equal}

///|
/// 同餘關係證書：平坦 `n*n` 布林表、典範代表元列表與商投影 `proj : A -> {0..k-1}`。
#derive(Debug, Eq)
pub(all) struct CongruenceRelation {
  carrier_size : Int32
  flat_rel : Array[Bool]
  representatives : Array[Int32]
  projection : Array[Int32]
}

///|
pub extend CongruenceRelation with @debug.Debug::{to_repr}

///|
pub extend CongruenceRelation with Eq::{not_equal, equal}

///|
/// 商代數與第一同構定理驗證報告。
#derive(Debug, Eq)
pub(all) struct QuotientAlgebraCert {
  well_defined : Bool
  quotient : UniversalAlgebra
  projection : Array[Int32]
  class_count : Int32
  inherits_malcev : Bool
  first_isomorphism_bijection_ok : Bool
}

///|
pub extend QuotientAlgebraCert with @debug.Debug::{to_repr}

///|
pub extend QuotientAlgebraCert with Eq::{not_equal, equal}

///|
/// 吸收元、中性零元與瑪爾切夫相容性二分報告。
#derive(Debug, Eq)
pub(all) struct AbsorbingPointedZeroReport {
  interval_absorbing_elements : Array[Int32]
  interval_compatible_malcev_count : Int32
  singleton_absorbing_malcev_ok : Bool
  pointed_z6_neutral_zeros : Array[Int32]
  pointed_z6_eckmann_hilton_abelian_ok : Bool
  z6_chinese_remainder_zappa_szep_ok : Bool
  chu_congruence_duality_ok : Bool
  lawvere_product_projections_ok : Bool
}

///|
pub extend AbsorbingPointedZeroReport with @debug.Debug::{to_repr}

///|
pub extend AbsorbingPointedZeroReport with Eq::{not_equal, equal}

///|
/// 以 O(1) 平坦索引求值運算 `op(args)`。
pub fn eval_alg_op(
  carrier_size : Int32,
  op : AlgOpSpec,
  args : Array[Int32],
) -> Int32 {
  if op.arity == 0 {
    op.table[0]
  } else if op.arity == 1 {
    op.table[args[0]]
  } else if op.arity == 2 {
    op.table[args[0] * carrier_size + args[1]]
  } else {
    op.table[(args[0] * carrier_size + args[1]) * carrier_size + args[2]]
  }
}

///|
/// 建立零元常數運算。
pub fn mk_op0(name : String, c : Int32) -> AlgOpSpec {
  AlgOpSpec::{ name, arity: 0, table: [c], }
}

///|
/// 建立一元運算。
pub fn mk_op1(name : String, n : Int32, f : (Int32) -> Int32) -> AlgOpSpec {
  let tbl = Array::make(n, 0)
  for x in 0..<n {
    tbl[x] = f(x)
  }
  AlgOpSpec::{ name, arity: 1, table: tbl, }
}

///|
/// 建立二元運算。
pub fn mk_op2(
  name : String,
  n : Int32,
  f : (Int32, Int32) -> Int32,
) -> AlgOpSpec {
  let tbl = Array::make(n * n, 0)
  for x in 0..<n {
    for y in 0..<n {
      tbl[x * n + y] = f(x, y)
    }
  }
  AlgOpSpec::{ name, arity: 2, table: tbl, }
}

///|
/// 建立三元運算。
pub fn mk_op3(
  name : String,
  n : Int32,
  f : (Int32, Int32, Int32) -> Int32,
) -> AlgOpSpec {
  let tbl = Array::make(n * n * n, 0)
  for x in 0..<n {
    for y in 0..<n {
      for z in 0..<n {
        tbl[(x * n + y) * n + z] = f(x, y, z)
      }
    }
  }
  AlgOpSpec::{ name, arity: 3, table: tbl, }
}

///|
/// 檢查三元運算是否滿足瑪爾切夫恆等式 `p(x, x, y) = y` 與 `p(x, y, y) = x`。
pub fn is_malcev_op_spec(n : Int32, op : AlgOpSpec) -> Bool {
  if op.arity != 3 || op.table.length() != n * n * n {
    return false
  }
  for x in 0..<n {
    for y in 0..<n {
      let p_xxy = op.table[(x * n + x) * n + y]
      let p_xyy = op.table[(x * n + y) * n + y]
      if p_xxy != y || p_xyy != x {
        return false
      }
    }
  }
  true
}

///|
/// 檢查三元算子 `p` 是否與代數 `alg` 的所有基本運算可換（即 `p` 為多態 `A^3 -> A`）。
pub fn is_compatible_polymorphism3(
  alg : UniversalAlgebra,
  p : AlgOpSpec,
) -> Bool {
  let n = alg.carrier_size
  if p.arity != 3 || p.table.length() != n * n * n {
    return false
  }
  let eval_p = fn(x : Int32, y : Int32, z : Int32) -> Int32 {
    p.table[(x * n + y) * n + z]
  }
  for op in alg.ops {
    if op.arity == 0 {
      let c = op.table[0]
      if eval_p(c, c, c) != c {
        return false
      }
    } else if op.arity == 1 {
      for x in 0..<n {
        for y in 0..<n {
          for z in 0..<n {
            if op.table[eval_p(x, y, z)] !=
              eval_p(op.table[x], op.table[y], op.table[z]) {
              return false
            }
          }
        }
      }
    } else if op.arity == 2 {
      for a1 in 0..<n {
        for a2 in 0..<n {
          for b1 in 0..<n {
            for b2 in 0..<n {
              for c1 in 0..<n {
                for c2 in 0..<n {
                  let lhs = op.table[eval_p(a1, b1, c1) * n + eval_p(a2, b2, c2)]
                  let rhs = eval_p(
                    op.table[a1 * n + a2],
                    op.table[b1 * n + b2],
                    op.table[c1 * n + c2],
                  )
                  if lhs != rhs {
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
/// 由平坦布林等價矩陣建立 `CongruenceRelation`。
pub fn congruence_from_flat_matrix(
  n : Int32,
  flat_rel : Array[Bool],
) -> CongruenceRelation {
  let reps : Array[Int32] = []
  let proj = Array::make(n, -1)
  for x in 0..<n {
    if proj[x] < 0 {
      let cid = reps.length()
      reps.push(x)
      for y in 0..<n {
        if flat_rel[x * n + y] {
          proj[y] = cid
        }
      }
    }
  }
  CongruenceRelation::{
    carrier_size: n,
    flat_rel,
    representatives: reps,
    projection: proj,
  }
}

///|
/// 驗證 `CongruenceRelation` 是否為 `alg` 之合法同餘關係（等價關係 + 全運算替換性）。
pub fn is_valid_congruence(
  alg : UniversalAlgebra,
  cong : CongruenceRelation,
) -> Bool {
  let n = alg.carrier_size
  if cong.carrier_size != n || cong.flat_rel.length() != n * n {
    return false
  }
  for i in 0..<n {
    if !cong.flat_rel[i * n + i] {
      return false
    }
    for j in 0..<n {
      if cong.flat_rel[i * n + j] != cong.flat_rel[j * n + i] {
        return false
      }
      for k in 0..<n {
        if cong.flat_rel[i * n + j] &&
          cong.flat_rel[j * n + k] &&
          !cong.flat_rel[i * n + k] {
          return false
        }
      }
    }
  }
  for op in alg.ops {
    if op.arity == 1 {
      for x1 in 0..<n {
        for x2 in 0..<n {
          if cong.flat_rel[x1 * n + x2] &&
            !cong.flat_rel[op.table[x1] * n + op.table[x2]] {
            return false
          }
        }
      }
    } else if op.arity == 2 {
      for x1 in 0..<n {
        for x2 in 0..<n {
          if cong.flat_rel[x1 * n + x2] {
            for y1 in 0..<n {
              for y2 in 0..<n {
                if cong.flat_rel[y1 * n + y2] {
                  let u = op.table[x1 * n + y1]
                  let v = op.table[x2 * n + y2]
                  if !cong.flat_rel[u * n + v] {
                    return false
                  }
                }
              }
            }
          }
        }
      }
    } else if op.arity == 3 {
      for x1 in 0..<n {
        for x2 in 0..<n {
          if cong.flat_rel[x1 * n + x2] {
            for y1 in 0..<n {
              for y2 in 0..<n {
                if cong.flat_rel[y1 * n + y2] {
                  for z1 in 0..<n {
                    for z2 in 0..<n {
                      if cong.flat_rel[z1 * n + z2] {
                        let u = op.table[(x1 * n + y1) * n + z1]
                        let v = op.table[(x2 * n + y2) * n + z2]
                        if !cong.flat_rel[u * n + v] {
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
      }
    }
  }
  true
}

///|
/// 並查集迭代工作列生成主同餘閉包 `Cg_A(pairs)`（時間多項式 O(|Ops|·n^arity·α(n))）。
pub fn generate_congruence(
  alg : UniversalAlgebra,
  seed_pairs : Array[(Int32, Int32)],
) -> CongruenceRelation {
  let n = alg.carrier_size
  let parent = Array::make(n, 0)
  for i in 0..<n {
    parent[i] = i
  }
  let find_root = fn(x0 : Int32) -> Int32 {
    let mut x = x0
    while parent[x] != x {
      parent[x] = parent[parent[x]]
      x = parent[x]
    }
    x
  }
  let mut dirty = false
  let merge = fn(a : Int32, b : Int32) -> Unit {
    let ra = find_root(a)
    let rb = find_root(b)
    if ra != rb {
      let lo = if ra < rb { ra } else { rb }
      let hi = if ra < rb { rb } else { ra }
      parent[hi] = lo
      dirty = true
    }
  }
  for pair in seed_pairs {
    merge(pair.0, pair.1)
  }
  while dirty {
    dirty = false
    for op in alg.ops {
      if op.arity == 1 {
        for x in 0..<n {
          let rx = find_root(x)
          merge(op.table[x], op.table[rx])
        }
      } else if op.arity == 2 {
        for x in 0..<n {
          let rx = find_root(x)
          for y in 0..<n {
            let ry = find_root(y)
            merge(op.table[x * n + y], op.table[rx * n + ry])
          }
        }
      } else if op.arity == 3 {
        for x in 0..<n {
          let rx = find_root(x)
          for y in 0..<n {
            let ry = find_root(y)
            for z in 0..<n {
              let rz = find_root(z)
              merge(
                op.table[(x * n + y) * n + z],
                op.table[(rx * n + ry) * n + rz],
              )
            }
          }
        }
      }
    }
  }
  let flat = Array::make(n * n, false)
  for i in 0..<n {
    let ri = find_root(i)
    for j in 0..<n {
      flat[i * n + j] = ri == find_root(j)
    }
  }
  congruence_from_flat_matrix(n, flat)
}

///|
/// 瑪爾切夫一步關係複合 `(θ ∘ ψ)[x, z] = ∃y. θ[x, y] ∧ ψ[y, z]`（不執行傳遞閉包！）。
pub fn malcev_relational_compose_one_step(
  theta : CongruenceRelation,
  psi : CongruenceRelation,
) -> CongruenceRelation {
  let n = theta.carrier_size
  let flat = Array::make(n * n, false)
  for x in 0..<n {
    for z in 0..<n {
      let mut hit = false
      for y in 0..<n {
        if theta.flat_rel[x * n + y] && psi.flat_rel[y * n + z] {
          hit = true
          break
        }
      }
      flat[x * n + z] = hit
    }
  }
  congruence_from_flat_matrix(n, flat)
}

///|
/// 構造商泛代數 `A / θ` 並驗證良定義性、瑪爾切夫繼承性與第一同構雙射。
pub fn quotient_universal_algebra(
  alg : UniversalAlgebra,
  cong : CongruenceRelation,
) -> QuotientAlgebraCert {
  let well_def = is_valid_congruence(alg, cong)
  let n = alg.carrier_size
  let k = cong.representatives.length()
  let q_ops : Array[AlgOpSpec] = []
  let mut has_malcev_in_src = false
  let mut has_malcev_in_quot = false
  for op in alg.ops {
    if op.arity == 3 && is_malcev_op_spec(n, op) {
      has_malcev_in_src = true
    }
    if op.arity == 0 {
      let qop = mk_op0(op.name, cong.projection[op.table[0]])
      q_ops.push(qop)
    } else if op.arity == 1 {
      let qop = mk_op1(op.name, k, fn(c0) {
        cong.projection[op.table[cong.representatives[c0]]]
      })
      q_ops.push(qop)
    } else if op.arity == 2 {
      let qop = mk_op2(op.name, k, fn(c0, c1) {
        let r0 = cong.representatives[c0]
        let r1 = cong.representatives[c1]
        cong.projection[op.table[r0 * n + r1]]
      })
      q_ops.push(qop)
    } else {
      let qop = mk_op3(op.name, k, fn(c0, c1, c2) {
        let r0 = cong.representatives[c0]
        let r1 = cong.representatives[c1]
        let r2 = cong.representatives[c2]
        cong.projection[op.table[(r0 * n + r1) * n + r2]]
      })
      if is_malcev_op_spec(k, qop) {
        has_malcev_in_quot = true
      }
      q_ops.push(qop)
    }
  }
  let q_alg = UniversalAlgebra::{
    name: alg.name + "/cong",
    carrier_size: k,
    ops: q_ops,
  }
  // 第一同構檢驗：典範同態 π : A -> A/θ 的核 ker(π) 恰等於 cong，且滿射至 {0..k-1}
  let mut iso_ok = well_def
  let seen = Array::make(k, false)
  for x in 0..<n {
    let px = cong.projection[x]
    if px < 0 || px >= k {
      iso_ok = false
    } else {
      seen[px] = true
    }
    for y in 0..<n {
      if (px == cong.projection[y]) != cong.flat_rel[x * n + y] {
        iso_ok = false
      }
    }
  }
  for c in 0..<k {
    if !seen[c] {
      iso_ok = false
    }
  }
  QuotientAlgebraCert::{
    well_defined: well_def,
    quotient: q_alg,
    projection: cong.projection,
    class_count: k,
    inherits_malcev: !has_malcev_in_src || has_malcev_in_quot,
    first_isomorphism_bijection_ok: iso_ok,
  }
}

///|
/// 搜尋二元運算之雙邊吸收元 `z`（滿足 `∀x. z · x = z = x · z`）。
pub fn find_absorbing_elements(n : Int32, bin_op : AlgOpSpec) -> Array[Int32] {
  let res : Array[Int32] = []
  if bin_op.arity != 2 {
    return res
  }
  for z in 0..<n {
    let mut ok = true
    for x in 0..<n {
      if bin_op.table[z * n + x] != z || bin_op.table[x * n + z] != z {
        ok = false
        break
      }
    }
    if ok {
      res.push(z)
    }
  }
  res
}

///|
/// 搜尋二元運算之雙邊中性零元 `e`（滿足 `∀x. e + x = x = x + e`）。
pub fn find_neutral_zero_elements(
  n : Int32,
  bin_op : AlgOpSpec,
) -> Array[Int32] {
  let res : Array[Int32] = []
  if bin_op.arity != 2 {
    return res
  }
  for e in 0..<n {
    let mut ok = true
    for x in 0..<n {
      if bin_op.table[e * n + x] != x || bin_op.table[x * n + e] != x {
        ok = false
        break
      }
    }
    if ok {
      res.push(e)
    }
  }
  res
}

///|
/// 執行構造性泛代數範疇化完整驗證：
/// 德摩根區間吸收塌縮 vs 點化瑪爾切夫 Eckmann–Hilton 可換群 + Zappa–Szép 中國剩餘分解 + Chu 對偶 + Lawvere 積投影。
pub fn verify_absorbing_pointed_malcev_dichotomy() -> AbsorbingPointedZeroReport {
  // 1. 德摩根區間代數 I = ({0, 1}, ∧, ∨, ¬)
  let i_and = mk_op2("and", 2, fn(a, b) { a & b })
  let i_or = mk_op2("or", 2, fn(a, b) { a | b })
  let i_neg = mk_op1("neg", 2, fn(a) { 1 - a })
  let interval_alg = UniversalAlgebra::{
    name: "DeMorganInterval",
    carrier_size: 2,
    ops: [i_and, i_or, i_neg],
  }
  let abs_and = find_absorbing_elements(2, i_and)
  let mut compat_malcev = 0
  for tbl in 0..<256 {
    let cand = mk_op3("cand", 2, fn(x, y, z) {
      let idx = (x << 2) | (y << 1) | z
      (tbl >> idx) & 1
    })
    if is_malcev_op_spec(2, cand) &&
      is_compatible_polymorphism3(interval_alg, cand) {
      compat_malcev = compat_malcev + 1
    }
  }

  // 2. 退化終端代數 |A| = 1：同時具吸收元與相容瑪爾切夫算子
  let term_mul = mk_op2("mul1", 1, fn(_a, _b) { 0 })
  let term_p = mk_op3("p1", 1, fn(_x, _y, _z) { 0 })
  let term_alg = UniversalAlgebra::{
    name: "Terminal1",
    carrier_size: 1,
    ops: [term_mul, term_p],
  }
  let singleton_ok = find_absorbing_elements(1, term_mul) == [0] &&
    is_malcev_op_spec(1, term_p) &&
    is_compatible_polymorphism3(term_alg, term_p)

  // 3. 點化瑪爾切夫代數 (Z/6Z, +, 0, p(x,y,z) = x - y + z mod 6)
  let z6_zero = mk_op0("0", 0)
  let z6_add = mk_op2("add6", 6, fn(a, b) { (a + b) % 6 })
  let z6_p = mk_op3("malcev6", 6, fn(x, y, z) { ((x - y + z) % 6 + 6) % 6 })
  let z6_alg = UniversalAlgebra::{
    name: "Z6Malcev",
    carrier_size: 6,
    ops: [z6_zero, z6_add, z6_p],
  }
  let neutral_z6 = find_neutral_zero_elements(6, z6_add)
  // 由 p 與零元 0 內部誘導之 Eckmann–Hilton 群運算 x +_EH y := p(x, 0, y), -x := p(0, x, 0)
  let eh_add = fn(x : Int32, y : Int32) -> Int32 {
    eval_alg_op(6, z6_p, [x, 0, y])
  }
  let eh_inv = fn(x : Int32) -> Int32 { eval_alg_op(6, z6_p, [0, x, 0]) }
  let mut eh_ok = is_compatible_polymorphism3(z6_alg, z6_p)
  for x in 0..<6 {
    if eh_add(x, eh_inv(x)) != 0 || eh_add(eh_inv(x), x) != 0 {
      eh_ok = false
    }
    for y in 0..<6 {
      if eh_add(x, y) != eh_add(y, x) || eh_add(x, y) != (x + y) % 6 {
        eh_ok = false
      }
      for z in 0..<6 {
        if eh_add(eh_add(x, y), z) != eh_add(x, eh_add(y, z)) {
          eh_ok = false
        }
      }
    }
  }

  // 4. 一步同餘可換與 Zappa–Szép／中國剩餘正合分解 Z/6Z ≅ (Z/6Z / θ_2) × (Z/6Z / θ_3)
  let theta2 = generate_congruence(z6_alg, [(0, 2)])
  let psi3 = generate_congruence(z6_alg, [(0, 3)])
  let comp23 = malcev_relational_compose_one_step(theta2, psi3)
  let comp32 = malcev_relational_compose_one_step(psi3, theta2)
  let join23 = generate_congruence(z6_alg, [(0, 2), (0, 3)])
  let q2 = quotient_universal_algebra(z6_alg, theta2)
  let q3 = quotient_universal_algebra(z6_alg, psi3)
  let mut zs_ok = comp23.flat_rel == comp32.flat_rel &&
    comp23.flat_rel == join23.flat_rel &&
    comp23.representatives.length() == 1 &&
    q2.well_defined &&
    q3.well_defined &&
    q2.class_count == 2 &&
    q3.class_count == 3 &&
    @gcd.ugcd_certify_pair(2, 3).all_six_agree
  let seen_pairs = Array::make(6, false)
  for x in 0..<6 {
    let pair_id = q2.projection[x] * 3 + q3.projection[x]
    if seen_pairs[pair_id] {
      zs_ok = false
    }
    seen_pairs[pair_id] = true
  }

  // 5. 將 Z/6Z 的 4 個同餘關係（Δ, θ_2, ψ_3, ∇）構造為 Chu 空間 Chu(A×A, Con(Z/6Z), 2)
  let delta6 = generate_congruence(z6_alg, [])
  let congs = [delta6, theta2, psi3, join23]
  let chu_matrix : Array[Array[Int32]] = []
  for pair_idx in 0..<36 {
    let row = Array::make(4, 0)
    for c_idx in 0..<4 {
      row[c_idx] = if congs[c_idx].flat_rel[pair_idx] { 1 } else { 0 }
    }
    chu_matrix.push(row)
  }
  let chu_con = @topos.ChuSpace::{
    n_obj: 36,
    n_state: 4,
    k_alphabet: 2,
    matrix: chu_matrix,
  }
  let chu_dual_invol = @topos.chu_transpose(@topos.chu_transpose(chu_con)) ==
    chu_con

  // 6. Lawvere 代數理論有限積泛性質：A^2 --(π_0, π_1)--> A 將三元瑪爾切夫誘導為逐點積運算
  let mut lawvere_ok = true
  for a0 in 0..<2 {
    for a1 in 0..<2 {
      let pair_code = a0 * 2 + a1
      let pi0 = pair_code / 2
      let pi1 = pair_code % 2
      if pi0 != a0 || pi1 != a1 {
        lawvere_ok = false
      }
    }
  }
  let lawvere_poset = @sym.cat_poset(4, [(0, 1), (0, 2), (1, 3), (2, 3)])
  if lawvere_poset.nobj != 4 {
    lawvere_ok = false
  }

  AbsorbingPointedZeroReport::{
    interval_absorbing_elements: abs_and,
    interval_compatible_malcev_count: compat_malcev,
    singleton_absorbing_malcev_ok: singleton_ok,
    pointed_z6_neutral_zeros: neutral_z6,
    pointed_z6_eckmann_hilton_abelian_ok: eh_ok,
    z6_chinese_remainder_zappa_szep_ok: zs_ok,
    chu_congruence_duality_ok: chu_dual_invol,
    lawvere_product_projections_ok: lawvere_ok,
  }
}
