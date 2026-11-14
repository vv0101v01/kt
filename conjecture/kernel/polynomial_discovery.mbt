///|
// Federation 7 (`discovery`) — `conjecture/kernel`, iteration 3:
// polynomial invariant discovery (`[E-Derive-Poly]`).
//
// `derive_invariant_relations` only sees relations that are LINEAR in the observed columns.
// Here the observation matrix is first pushed through the degree-`d` Veronese map
// (one column per monomial of total degree `<= d`), so the same nullspace engine now
// returns polynomial laws such as `z - x*y = 0` or `x^2 + y^2 - 25 = 0`.
//
// Three safeguards keep the output honest:
//   1. `[P-Inherit]` A degree-`d` relation that is just `monomial * (lower relation)` is
//      not a discovery. The report separates the inherited subspace from the new one.
//   2. `[P-Multi-Prime]` The nullity must agree over several primes; a rank drop modulo a
//      single prime is flagged instead of being reported as a law.
//   3. `[P-Transfer-Poly]` Out-of-sample testing is done on SUBSPACES (the nullspace of
//      train + transfer rows), not by filtering basis vectors one at a time: a true law
//      can hide inside a basis vector as `law + mirage`.

///|
/// Graded monomial basis in `num_vars` variables up to total degree `degree`:
/// degree 0 first, then degree 1 in column order, and so on. The basis of degree `d - 1`
/// is therefore a prefix of the basis of degree `d` (`prefix_counts[d]` monomials).
#derive(Debug, Eq)
pub(all) struct MonomialBasis {
  num_vars : Int32
  degree : Int32
  exponents : Array[Array[Int32]]
  names : Array[String]
  prefix_counts : Array[Int32]
}

///|
pub extend MonomialBasis with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend MonomialBasis with Eq::{not_equal, equal}

///|
/// Build the graded monomial basis over the named columns.
pub fn monomial_basis_build(
  columns : Array[String],
  degree : Int32,
) -> MonomialBasis {
  let k = columns.length()
  let exponents : Array[Array[Int32]] = []
  let prefix_counts : Array[Int32] = []
  let rec_fill = (d : Int32) => {
    // Enumerate exponent vectors of total degree exactly `d`, leading variables first.
    let cur = Array::make(k, 0)
    fn go(pos : Int32, left : Int32) -> Unit {
      if pos == k - 1 {
        cur[pos] = left
        exponents.push(cur.copy())
        return
      }
      for step in 0..<=left {
        cur[pos] = left - step
        go(pos + 1, step)
      }
    }

    if k == 0 {
      if d == 0 {
        exponents.push([])
      }
    } else {
      go(0, d)
    }
  }
  for d in 0..<=degree {
    rec_fill(d)
    prefix_counts.push(exponents.length())
  }
  let names : Array[String] = exponents.map(e => {
    let parts : Array[String] = []
    for i in 0..<k {
      if e[i] == 1 {
        parts.push(columns[i])
      } else if e[i] > 1 {
        parts.push("\{columns[i]}^\{e[i]}")
      }
    }
    if parts.length() == 0 {
      "1"
    } else {
      parts.join("*")
    }
  })
  MonomialBasis::{ num_vars: k, degree, exponents, names, prefix_counts, }
}

///|
/// Veronese lift: replace every observation row by the values of all monomials of degree
/// `<= degree`. Returns `None` if the basis would exceed `256` monomials, if a row has the
/// wrong width, or if a monomial value leaves the `Int32` range (never silently wrapped).
pub fn veronese_lift_rowset(
  rs : ObservationRowSet,
  degree : Int32,
) -> ObservationRowSet? {
  if degree < 0 {
    return None
  }
  let basis = monomial_basis_build(rs.columns, degree)
  if basis.exponents.length() > 256 {
    return None
  }
  let rows : Array[Array[Int32]] = []
  for row in rs.rows {
    if row.length() != basis.num_vars {
      return None
    }
    let lifted : Array[Int32] = []
    for e in basis.exponents {
      let mut v = 1L
      for i in 0..<basis.num_vars {
        for _ in 0..<e[i] {
          v = v * row[i].to_int64()
          if v > 2147483647L || v < -2147483647L {
            return None
          }
        }
      }
      lifted.push(v.to_int())
    }
    rows.push(lifted)
  }
  Some(ObservationRowSet::{
    name: "\{rs.name}@deg\{degree}",
    columns: basis.names,
    rows,
  })
}

///|
/// Render a relation over a monomial basis, e.g. `z - x*y = 0`.
pub fn poly_relation_to_string(
  names : Array[String],
  coeff : Array[Int32],
) -> String {
  let sb = StringBuilder()
  let mut first = true
  for i in 0..<coeff.length() {
    let c = coeff[i]
    if c != 0 && i < names.length() {
      let mag = if c < 0 { -c } else { c }
      if first {
        if c < 0 {
          sb.write_string("-")
        }
      } else {
        sb.write_string(if c < 0 { " - " } else { " + " })
      }
      if names[i] == "1" {
        sb.write_string("\{mag}")
      } else if mag == 1 {
        sb.write_string(names[i])
      } else {
        sb.write_string("\{mag}*\{names[i]}")
      }
      first = false
    }
  }
  if first {
    sb.write_string("0")
  }
  sb.write_string(" = 0")
  sb.to_string()
}

///|
/// Incremental row-echelon basis over `F_p`: `insert` costs one reduction instead of two
/// full rank computations per candidate.
priv struct FpEchelon {
  p : Int32
  rows : Array[Array[Int32]]
  pivots : Array[Int32]
}

///|
fn FpEchelon::insert(self : FpEchelon, v : Array[Int32]) -> Bool {
  let p = self.p
  let cur : Array[Int32] = v.map(x => @gcd.fp_norm(x, p))
  for r in 0..<self.rows.length() {
    let c = cur[self.pivots[r]]
    if c != 0 {
      let row = self.rows[r]
      for j in 0..<cur.length() {
        cur[j] = @gcd.fp_sub(cur[j], @gcd.fp_mul(c, row[j], p), p)
      }
    }
  }
  for j in 0..<cur.length() {
    if cur[j] != 0 {
      let inv = @gcd.fp_inv(cur[j], p)
      for t in 0..<cur.length() {
        cur[t] = @gcd.fp_mul(cur[t], inv, p)
      }
      self.rows.push(cur)
      self.pivots.push(j)
      return true
    }
  }
  false
}

///|
/// Result of polynomial invariant discovery.
///
/// For each degree `d` (array index): `nullity_by_degree[d]` is the dimension of the space
/// of relations of degree `<= d`, `inherited_by_degree[d]` the part generated by the
/// relations of degree `<= d - 1` and their multiples by one variable, and
/// `new_by_degree[d]` the difference, i.e. the laws that first appear in degree `d`.
/// `relations` is an exact integer basis candidate at the top degree (every entry holds
/// over `Z` on all rows); `relations_complete` says whether it spans the whole nullspace.
#derive(Debug, Eq)
pub(all) struct PolyInvariantReport {
  degree : Int32
  monomials : Array[String]
  nullity_by_degree : Array[Int32]
  inherited_by_degree : Array[Int32]
  new_by_degree : Array[Int32]
  relations : Array[Array[Int32]]
  relations_complete : Bool
  primes_agree : Bool
}

///|
pub extend PolyInvariantReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PolyInvariantReport with Eq::{not_equal, equal}

///|
/// `[E-Derive-Poly]` Discover all polynomial relations of degree `<= degree` among the
/// columns of `rs`. `primes` must be non-empty; the first prime drives the reconstruction
/// and the others are used for the `[P-Multi-Prime]` agreement check.
/// Returns `None` when the Veronese lift is refused or there is nothing to analyse.
pub fn derive_polynomial_invariants(
  rs : ObservationRowSet,
  degree : Int32,
  primes : Array[Int32],
) -> PolyInvariantReport? {
  if primes.length() == 0 || rs.rows.length() == 0 || degree < 1 {
    return None
  }
  let lifted = match veronese_lift_rowset(rs, degree) {
    None => return None
    Some(l) => l
  }
  let basis = monomial_basis_build(rs.columns, degree)
  let total = basis.exponents.length()
  let p0 = primes[0]
  let truncated = (count : Int32) => {
    lifted.rows.map(row => Array::makei(count, j => row[j]))
  }
  let index_of_exponent = (e : Array[Int32]) => {
    let mut res = -1
    for i in 0..<total {
      if basis.exponents[i] == e {
        res = i
        break
      }
    }
    res
  }
  let nullity : Array[Int32] = []
  let inherited : Array[Int32] = []
  let fresh : Array[Int32] = []
  let mut agree = true
  let mut prev_null : Array[Array[Int32]] = []
  for d in 0..<=degree {
    let count = basis.prefix_counts[d]
    let rows_d = truncated(count)
    let null_d = @gcd.fp_nullspace_basis(@gcd.fp_mat_from_rows(rows_d, p0))
    for q in primes {
      let rank_q = @gcd.fp_rank(@gcd.fp_mat_from_rows(rows_d, q))
      if count - rank_q != null_d.length() {
        agree = false
      }
    }
    // Inherited part: lower relations, padded, and their products with each variable.
    let ech = FpEchelon::{ p: p0, rows: [], pivots: [], }
    let mut inh = 0
    for r in prev_null {
      let padded = Array::makei(count, j => {
        if j < r.length() {
          r[j]
        } else {
          0
        }
      })
      if ech.insert(padded) {
        inh = inh + 1
      }
      for v in 0..<basis.num_vars {
        let shifted = Array::make(count, 0)
        for j in 0..<r.length() {
          if r[j] != 0 {
            let e = basis.exponents[j].copy()
            e[v] = e[v] + 1
            let target = index_of_exponent(e)
            if target >= 0 && target < count {
              shifted[target] = r[j]
            }
          }
        }
        if ech.insert(shifted) {
          inh = inh + 1
        }
      }
    }
    nullity.push(null_d.length())
    inherited.push(inh)
    fresh.push(null_d.length() - inh)
    prev_null = null_d
  }
  let relations = derive_invariant_relations(lifted, p0, true)
  Some(PolyInvariantReport::{
    degree,
    monomials: basis.names,
    nullity_by_degree: nullity,
    inherited_by_degree: inherited,
    new_by_degree: fresh,
    relations_complete: relations.length() == nullity[degree],
    relations,
    primes_agree: agree,
  })
}

///|
/// Outcome of a subspace-level transfer test (`[P-Transfer-Poly]`).
///
/// `train_nullity` relations hold on the training rows; `surviving_nullity` of them (as a
/// subspace) still hold once the transfer rows are added; `mirages_killed` is the
/// difference. `surviving` is an exact integer basis of the survivors.
#derive(Debug, Eq)
pub(all) struct PolyTransferReport {
  degree : Int32
  monomials : Array[String]
  train_nullity : Int32
  surviving_nullity : Int32
  mirages_killed : Int32
  surviving : Array[Array[Int32]]
  surviving_complete : Bool
  primes_agree : Bool
}

///|
pub extend PolyTransferReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PolyTransferReport with Eq::{not_equal, equal}

///|
/// Derive polynomial laws on `train`, then intersect with the laws of `transfer`
/// by solving for the nullspace of the stacked observations. Both row sets must have the
/// same columns.
pub fn polynomial_transfer_experiment(
  train : ObservationRowSet,
  transfer : ObservationRowSet,
  degree : Int32,
  primes : Array[Int32],
) -> PolyTransferReport? {
  if train.columns != transfer.columns {
    return None
  }
  let stacked = ObservationRowSet::{
    name: "\{train.name}+\{transfer.name}",
    columns: train.columns,
    rows: [..train.rows, ..transfer.rows],
  }
  match
    (
      derive_polynomial_invariants(train, degree, primes),
      derive_polynomial_invariants(stacked, degree, primes),
    ) {
    (Some(a), Some(b)) =>
      Some(PolyTransferReport::{
        degree,
        monomials: b.monomials,
        train_nullity: a.nullity_by_degree[degree],
        surviving_nullity: b.nullity_by_degree[degree],
        mirages_killed: a.nullity_by_degree[degree] -
        b.nullity_by_degree[degree],
        surviving: b.relations,
        surviving_complete: b.relations_complete,
        primes_agree: a.primes_agree && b.primes_agree,
      })
    _ => None
  }
}

///|
/// Laws of the polynomial discovery kernel.
pub fn check_polynomial_discovery_laws() -> Bool {
  let primes = [65521, 10007, 32749]
  // 1. A product law that is invisible to linear discovery.
  let prod_rows : Array[Array[Int32]] = []
  for x in 1..<=5 {
    for y in 2..<=5 {
      prod_rows.push([x, y + x % 2, x * (y + x % 2)])
    }
  }
  let prod = ObservationRowSet::{
    name: "product",
    columns: ["x", "y", "z"],
    rows: prod_rows,
  }
  if derive_invariant_relations(prod, 65521, true).length() != 0 {
    return false
  }
  match derive_polynomial_invariants(prod, 2, primes) {
    Some(rep) =>
      if rep.nullity_by_degree != [0, 0, 1] ||
        rep.new_by_degree != [0, 0, 1] ||
        !rep.primes_agree ||
        !rep.relations_complete ||
        rep.relations.length() != 1 ||
        poly_relation_to_string(rep.monomials, rep.relations[0]) !=
        "z - x*y = 0" {
        return false
      }
    None => return false
  }
  // 2. A linear law `x + y - z = 0` generates four quadratic relations (itself and its
  //    three multiples). All four are inherited: nothing new appears in degree 2.
  let sum_rows : Array[Array[Int32]] = []
  for x in 1..<=5 {
    for y in 1..<=4 {
      sum_rows.push([x, y * y - x, y * y])
    }
  }
  let sum = ObservationRowSet::{
    name: "sum",
    columns: ["x", "y", "z"],
    rows: sum_rows,
  }
  match derive_polynomial_invariants(sum, 2, primes) {
    Some(rep) =>
      if rep.nullity_by_degree != [0, 1, 4] ||
        rep.inherited_by_degree != [0, 0, 4] ||
        rep.new_by_degree != [0, 1, 0] ||
        !rep.primes_agree {
        return false
      }
    None => return false
  }
  // 3. A conic with a constant term, recovered exactly through Half-GCD (denominator 25).
  let circle = ObservationRowSet::{
    name: "circle",
    columns: ["x", "y"],
    rows: [
      [3, 4],
      [4, 3],
      [5, 0],
      [0, 5],
      [-3, 4],
      [-4, 3],
      [-5, 0],
      [3, -4],
      [-4, -3],
    ],
  }
  match derive_polynomial_invariants(circle, 2, primes) {
    Some(rep) =>
      if rep.new_by_degree != [0, 0, 1] ||
        rep.relations.length() != 1 ||
        poly_relation_to_string(rep.monomials, rep.relations[0]) !=
        "25 - x^2 - y^2 = 0" {
        return false
      }
    None => return false
  }
  // 4. Subspace transfer. Training only at t in {2, 3} creates the interpolation mirage
  //    `(t - 2)(t - 3) = 0`. A transfer row at t = 5 kills it and keeps `s - t*u = 0`.
  let mk = (ts : Array[Int32], name : String) => {
    let rows : Array[Array[Int32]] = []
    for t in ts {
      for u in 1..<=6 {
        rows.push([t, u + t, t * (u + t)])
      }
    }
    ObservationRowSet::{ name, columns: ["t", "u", "s"], rows, }
  }
  match
    polynomial_transfer_experiment(
      mk([2, 3], "train"),
      mk([5], "transfer"),
      2,
      primes,
    ) {
    Some(tr) =>
      if tr.train_nullity <= tr.surviving_nullity ||
        tr.surviving_nullity != 1 ||
        tr.mirages_killed != tr.train_nullity - 1 ||
        !tr.surviving_complete ||
        poly_relation_to_string(tr.monomials, tr.surviving[0]) != "s - t*u = 0" {
        return false
      }
    None => return false
  }
  // 5. Guard rails: overflow in the lift and mismatched columns are refused.
  let big = ObservationRowSet::{ name: "big", columns: ["x"], rows: [[70000]], }
  veronese_lift_rowset(big, 2) == None &&
  veronese_lift_rowset(big, 1) != None &&
  polynomial_transfer_experiment(prod, circle, 2, primes) == None
}
