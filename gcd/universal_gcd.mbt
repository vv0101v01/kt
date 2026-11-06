///|
// Universal Structural Greatest Common Divisor (`新最大公因數` / `UniversalGcd`)
//
// Axiom `[Ax-UnivGCD-Pullback]`:
//   Across arithmetic, homological algebra, tropical geometry, canonical normal
//   forms, and subspace lattices, the Greatest Common Divisor is the universal
//   pullback / coarsest-quotient meet fitting into the generalized Bézout–Mayer–Vietoris
//   duality `GCD(A, B) * LCM(A, B) == A * B` (multiplicative) or
//   `dim(U ∩ V) + dim(U + V) == dim U + dim V` (additive).
//
// Theorem `[T-UnivGCD-SixFold]`:
//   For positive integers `(m, n)`, six independent mathematical engines compute
//   the exact same invariant pair `(gcd(m, n), lcm(m, n))`:
//     1. Euclidean ring GCD/LCM over `Z`;
//     2. Determinantal minor / Smith Normal Form invariant factors `(d_1, d_2)` of `diag(m, n)`;
//     3. Two-sided free `Z`-resolution derived tensor `Tor_0^Z(Z/m, Z/n)` & `Tor_1^Z(Z/m, Z/n)`;
//     4. Non-Archimedean `p`-adic valuation `v_p(gcd) = min(v_p(m), v_p(n)) = v_p(m) ⊕_trop v_p(n)`;
//     5. Quotient lattice meet `c_m ∧ c_n` and join `c_m ∨ c_n` of idempotent canonical normalizers;
//     6. Grassmannian subspace intersection/sum exactness over `F_p`.

///|
/// Six-domain Universal GCD certificate for a pair `(m, n)`.
#derive(Debug, Eq)
pub(all) struct UgcdSixFoldCertificate {
  m : Int32
  n : Int32
  arith_gcd : BigInt
  arith_lcm : BigInt
  snf_d1 : BigInt
  snf_d2 : BigInt
  tor0_order : BigInt
  tor1_order : BigInt
  tropical_valuation_homomorphic : Bool
  canon_meet_classes : Int32
  canon_join_classes : Int32
  bezout_product_holds : Bool
  all_six_agree : Bool
}

///|
pub extend UgcdSixFoldCertificate with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend UgcdSixFoldCertificate with Eq::{not_equal, equal}

///|
/// `p`-adic valuation `v_p(x)` for nonzero `x` (`-1` if `x == 0`).
pub fn ugcd_padic_valuation(x : BigInt, p : Int32) -> Int32 {
  let mut cur = ugcd_bigint_abs(x)
  if cur == 0N || p < 2 {
    return -1
  }
  let pb = BigInt::from_int(p)
  let mut v = 0
  while cur % pb == 0N {
    cur = cur / pb
    v = v + 1
  }
  v
}

///|
/// Compute `( |Tor_0^Z(Z/m, Z/n)|, |Tor_1^Z(Z/m, Z/n)| )` genuinely via the
/// total tensor complex `T_* = K(m) ⊗_Z K(n)`:
///   `0 -> Z --d_2=(-n, m)^T--> Z^2 --d_1=(m, n)--> Z -> 0`
/// using Smith Normal Form elimination without calling `gcd` directly!
pub fn ugcd_derived_tor_z_orders(m : Int32, n : Int32) -> (BigInt, BigInt) {
  let mb = BigInt::from_int(m)
  let nb = BigInt::from_int(n)
  // H_0 = coker(d_1 : Z^2 -> Z) where d_1 = [[m, n]]
  let d1 = zmat_from_rows([[mb, nb]])
  let snf1 = zmat_snf(d1)
  let tor0 = if snf1.rank == 0 { 0N } else { snf1.diag[0] }

  // ker(d_1) basis has rank 1 when (m, n) != (0, 0), given by column 1 of snf1.v!
  // Check chain law d_1 * d_2 == 0 and express im(d_2) inside ker(d_1) to get Tor_1 = |ker(d_1) / im(d_2)|
  let d2 = zmat_from_rows([[-nb], [mb]])
  let chain_prod = zmat_mul(d1, d2)
  if zmat_get(chain_prod, 0, 0) != 0N {
    return (-1N, -1N)
  }
  let ker_basis = ugcd_z_nullspace_basis(d1)
  if ker_basis.length() != 1 {
    return (tor0, 0N)
  }
  let k0 = ker_basis[0][0]
  let k1 = ker_basis[0][1]
  // Since (-n, m) = ratio * (k0, k1) over Z, extract exact ratio via SNF/quotient
  let tor1 = if k0 != 0N {
    ugcd_bigint_abs(-nb / k0)
  } else if k1 != 0N {
    ugcd_bigint_abs(mb / k1)
  } else {
    0N
  }
  (tor0, tor1)
}

///|
/// Canonical free-group word reduction (`+k` cancels adjacent `-k`, `0` is identity).
pub fn ugcd_free_group_reduce(word : Array[Int32]) -> Array[Int32] {
  let st : Array[Int32] = []
  for g in word {
    if g != 0 {
      if st.length() > 0 && st[st.length() - 1] == -g {
        let _ = st.pop()
      } else {
        st.push(g)
      }
    }
  }
  st
}

///|
/// `[D-CanonMeetJoin]` Given two idempotent canonical normalizers `c1, c2` on
/// `{0..size-1}` (`c_i(c_i(x)) == c_i(x)`), computes:
///   - `meet` (finest common coarsening = GCD in quotient poset) class count via union-find;
///   - `join` (coarsest common refinement = LCM in quotient poset) class count via pair signatures.
pub fn ugcd_canon_meet_join_counts(
  size : Int32,
  c1 : (Int32) -> Int32,
  c2 : (Int32) -> Int32,
) -> (Int32, Int32, Bool) {
  if size <= 0 {
    return (0, 0, false)
  }
  let mut idempotent_ok = true
  for x in 0..<size {
    let y1 = c1(x)
    let y2 = c2(x)
    if y1 < 0 || y1 >= size || y2 < 0 || y2 >= size {
      return (0, 0, false)
    }
    if c1(y1) != y1 || c2(y2) != y2 {
      idempotent_ok = false
    }
  }
  // Union-find for coarsening meet: merge x ~ c1(x) and x ~ c2(x)
  let parent : Array[Int32] = []
  for i in 0..<size {
    parent.push(i)
  }
  fn find_root(par : Array[Int32], x : Int32) -> Int32 {
    let mut cur = x
    while par[cur] != cur {
      par[cur] = par[par[cur]]
      cur = par[cur]
    }
    cur
  }
  for x in 0..<size {
    let r_x = find_root(parent, x)
    let r_1 = find_root(parent, c1(x))
    if r_x != r_1 {
      parent[r_1] = r_x
    }
    let r_x2 = find_root(parent, x)
    let r_2 = find_root(parent, c2(x))
    if r_x2 != r_2 {
      parent[r_2] = r_x2
    }
  }
  let mut meet_classes = 0
  for x in 0..<size {
    if find_root(parent, x) == x {
      meet_classes = meet_classes + 1
    }
  }

  // Distinct pair keys (c1(x), c2(x)) for refinement join
  let seen_pairs : Array[(Int32, Int32)] = []
  for x in 0..<size {
    let pair = (c1(x), c2(x))
    let mut found = false
    for q in seen_pairs {
      if q == pair {
        found = true
        break
      }
    }
    if !found {
      seen_pairs.push(pair)
    }
  }
  (meet_classes, seen_pairs.length(), idempotent_ok)
}

///|
/// Grassmannian subspace GCD/LCM dimension duality over `F_p`:
/// returns `(dim U, dim V, dim(U ∩ V), dim(U + V), exact_holds)`.
pub fn ugcd_grassmann_subspace_duality(
  u_basis_rows : Array[Array[Int32]],
  v_basis_rows : Array[Array[Int32]],
  ambient_dim : Int32,
  p : Int32,
) -> (Int32, Int32, Int32, Int32, Bool) {
  let u_mat = if u_basis_rows.length() == 0 {
    fp_mat_make(0, ambient_dim, p, 0)
  } else {
    fp_mat_from_rows(u_basis_rows, p)
  }
  let v_mat = if v_basis_rows.length() == 0 {
    fp_mat_make(0, ambient_dim, p, 0)
  } else {
    fp_mat_from_rows(v_basis_rows, p)
  }
  let dim_u = fp_rank(u_mat)
  let dim_v = fp_rank(v_mat)
  let stacked : Array[Array[Int32]] = []
  for r in u_basis_rows {
    stacked.push(r)
  }
  for r in v_basis_rows {
    stacked.push(r)
  }
  let sum_mat = if stacked.length() == 0 {
    fp_mat_make(0, ambient_dim, p, 0)
  } else {
    fp_mat_from_rows(stacked, p)
  }
  let dim_sum = fp_rank(sum_mat)
  // Intersection U ∩ V = (U^perp + V^perp)^perp via dual nullspaces!
  let u_perp = fp_nullspace_basis(u_mat)
  let v_perp = fp_nullspace_basis(v_mat)
  let perp_stacked : Array[Array[Int32]] = []
  for r in u_perp {
    perp_stacked.push(r)
  }
  for r in v_perp {
    perp_stacked.push(r)
  }
  let perp_mat = if perp_stacked.length() == 0 {
    fp_mat_make(0, ambient_dim, p, 0)
  } else {
    fp_mat_from_rows(perp_stacked, p)
  }
  let dim_inter = ambient_dim - fp_rank(perp_mat)
  (dim_u, dim_v, dim_inter, dim_sum, dim_inter + dim_sum == dim_u + dim_v)
}

///|
/// Construct and verify the complete 6-domain Universal GCD certificate on `(m, n)`.
pub fn ugcd_certify_pair(m : Int32, n : Int32) -> UgcdSixFoldCertificate {
  let mb = BigInt::from_int(m)
  let nb = BigInt::from_int(n)
  let arith_gcd = ugcd_bigint_gcd(mb, nb)
  let arith_lcm = ugcd_bigint_lcm(mb, nb)

  // 2. SNF of diag(m, n)
  let diag_mn = zmat_from_rows([[mb, 0N], [0N, nb]])
  let snf = zmat_snf(diag_mn)
  let snf_ok = zmat_snf_verify(diag_mn, snf) && snf.rank == 2
  let snf_d1 = if snf.rank >= 1 { snf.diag[0] } else { 0N }
  let snf_d2 = if snf.rank >= 2 { snf.diag[1] } else { 0N }

  // 3. Derived Tor_0 and Tor_1 over Z
  let (tor0_order, tor1_order) = ugcd_derived_tor_z_orders(m, n)

  // 4. Tropical / p-adic valuation homomorphism across primes {2, 3, 5, 7, 11}
  let primes = [2, 3, 5, 7, 11]
  let mut trop_ok = true
  for p in primes {
    let vm = ugcd_padic_valuation(mb, p)
    let vn = ugcd_padic_valuation(nb, p)
    let vg = ugcd_padic_valuation(arith_gcd, p)
    let vl = ugcd_padic_valuation(arith_lcm, p)
    let trop_min = if vm < vn { vm } else { vn }
    let trop_max = if vm > vn { vm } else { vn }
    if vg != trop_min || vl != trop_max {
      trop_ok = false
    }
  }

  // 5. Canonical normalizer lattice meet & join on Z/(|m|*|n|)Z
  let am = if m < 0 { -m } else { m }
  let an = if n < 0 { -n } else { n }
  if am == 0 || an == 0 {
    return UgcdSixFoldCertificate::{
      m,
      n,
      arith_gcd,
      arith_lcm,
      snf_d1,
      snf_d2,
      tor0_order,
      tor1_order,
      tropical_valuation_homomorphic: false,
      canon_meet_classes: 0,
      canon_join_classes: 0,
      bezout_product_holds: false,
      all_six_agree: false,
    }
  }
  let carrier = am * an
  let (canon_meet_classes, canon_join_classes, idem_ok) = ugcd_canon_meet_join_counts(
    carrier,
    x => x % am,
    x => x % an,
  )

  let bezout_product_holds = snf_d1 * snf_d2 == ugcd_bigint_abs(mb * nb) &&
    arith_gcd * arith_lcm == ugcd_bigint_abs(mb * nb)
  let all_six_agree = snf_ok &&
    idem_ok &&
    trop_ok &&
    bezout_product_holds &&
    snf_d1 == arith_gcd &&
    snf_d2 == arith_lcm &&
    tor0_order == arith_gcd &&
    tor1_order == arith_gcd &&
    BigInt::from_int(canon_meet_classes) == arith_gcd &&
    BigInt::from_int(canon_join_classes) == arith_lcm

  UgcdSixFoldCertificate::{
    m,
    n,
    arith_gcd,
    arith_lcm,
    snf_d1,
    snf_d2,
    tor0_order,
    tor1_order,
    tropical_valuation_homomorphic: trop_ok,
    canon_meet_classes,
    canon_join_classes,
    bezout_product_holds,
    all_six_agree,
  }
}

///|
/// Master law check for the Lower-V Universal GCD & Elimination package.
pub fn check_universal_gcd_laws() -> Bool {
  // 1. Classical Smith Normal Form benchmark from `notebook`: [[2,4,4],[-6,6,12],[10,-4,-16]] -> [2, 6, 12]
  let classic = zmat_from_int_rows([[2, 4, 4], [-6, 6, 12], [10, -4, -16]])
  let snf_classic = zmat_snf(classic)
  if !zmat_snf_verify(classic, snf_classic) || snf_classic.diag != [2N, 6N, 12N] {
    return false
  }

  // 2. Hermite Normal Form lattice invariance under unimodular row operations
  let lat_a = zmat_from_int_rows([[2, 3, 1], [4, 1, 5]])
  let unimod = zmat_from_int_rows([[1, 2], [1, 3]])
  let lat_b = zmat_mul(unimod, lat_a)
  if zmat_hnf(lat_a) != zmat_hnf(lat_b) {
    return false
  }

  // 3. Six-fold Universal GCD across coprime, composite, and prime-power pairs
  let pairs = [(6, 10), (12, 18), (15, 28), (24, 36), (14, 21)]
  for pair in pairs {
    let (m, n) = pair
    if !ugcd_certify_pair(m, n).all_six_agree {
      return false
    }
  }

  // 4. Grassmannian subspace intersection/sum exactness over F_7
  // U = span([1,0,0,1], [0,1,1,0], [0,0,1,2]) (dim 3), V = span([1,1,1,1], [0,0,0,1]) (dim 2):
  // [1,1,1,1] = u0 + u1 in U, while [0,0,0,1] is outside U => dim(U ∩ V) = 1, dim(U + V) = 4!
  let (du, dv, di, ds, grass_ok) = ugcd_grassmann_subspace_duality(
    [[1, 0, 0, 1], [0, 1, 1, 0], [0, 0, 1, 2]],
    [[1, 1, 1, 1], [0, 0, 0, 1]],
    4,
    7,
  )
  if !grass_ok || du != 3 || dv != 2 || di != 1 || ds != 4 {
    return false
  }

  // 5. Signed Multi-Modular CRT reconstruction
  let target = -432109N
  let (rec_x, rec_m) = ugcd_crt_reconstruct_signed(
    [target % 101N, target % 103N, target % 107N],
    [101N, 103N, 107N],
  )
  rec_m == 1113121N && rec_x == target
}
