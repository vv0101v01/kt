///|
// Federation 6 (`condensed`) — Spectral Sequences, Steenrod–Adams `Ext_A(F_2, F_2)`,
// Serre Fibration Convergence, Koszul Derived `Tor`, & Higher Structure #3 (`CondSpectralSheaf`).
//
// Fuses `notebook/{ss, serre, adams, ahss, dtensor, grotop}` with `golden`'s
// homotopy/topos invariants:
//   • `SsPage`: bigraded spectral sequence engine (`d_r o d_r = 0`, `E_{r+1} = ker/im`);
//   • `SerreReport`: `S^1 -> S^3 -> S^2` & `S^n -> S^{2n+1} -> S^{n+1}` convergence + Hurewicz `H_2(S^2) = Z`;
//   • `AdamsExtReport`: Adem relations on `A(2)` + minimal free resolution `Ext_A^{s,t}(F_2, F_2)`
//     proving `Ext^{1,2} = 1` (`h_1 = eta`) and `Ext^{2,3} = 0` (`h_0*h_1 = 0 => 2*eta = 0`,
//     algebraically certifying `|pi_4(S^3)_{(2)}| = 2`, matching Brunerie `|beta| = 2`!);
//   • **Condensed Higher-Order Structure #3 (`凝聚高階結構 ③` — `CondSpectralSheaf`)**:
//     couples Grothendieck Čech twist gluing obstruction `k^1 - r^0` with Twisted AHSS
//     `d_3 = Sq^3 + H u (-)` on `S^3` and `T^3`!
//   • `KoszulTorReport`: computes both classical exterior `Tor_i^{F_2[x_1..x_g]}(F_2, F_2) = C(g, i)`
//     on `K_* ⊗_A F_2` and two-sided truncated polynomial `Tor_i = C(2g, i)` over `F_2[x_1..x_g]/(x_j^{N+1})`.

///|
/// Bigraded spectral sequence page `E_r^{p, q}` over `F_prime`.
pub(all) struct SsPage {
  r : Int32
  np : Int32
  nq : Int32
  dims : Array[Array[Int32]]
  diffs : Array[Array[@gcd.FpMat?]]
  prime : Int32
  qflip : Bool
} derive(Debug, Eq)

///|
pub extend SsPage with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SsPage with Eq::{not_equal, equal}

///|
/// Serre spectral sequence convergence report for sphere fibrations `F -> E -> B`.
pub(all) struct SerreReport {
  base_betti : Array[Int32]
  fiber_betti : Array[Int32]
  e2_totals : Array[Int32]
  e_inf_totals : Array[Int32]
  dd_zero : Bool
  converges_to_s3 : Bool
  hurewicz_h2_s2_rank : Int32
} derive(Debug, Eq)

///|
pub extend SerreReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend SerreReport with Eq::{not_equal, equal}

///|
/// Mod-2 Steenrod algebra minimal resolution report for Adams `E_2^{s,t} = Ext_A^{s,t}(F_2, F_2)`.
pub(all) struct AdamsExtReport {
  trunc_deg : Int32
  s_max : Int32
  t_max : Int32
  admissible_basis_count : Int32
  ext_dims : Array[Array[Int32]]
  stem0_h0_tower : Array[Int32]
  hopf_h1_ext12 : Int32
  two_eta_ext23 : Int32
  hopf_h2_ext14 : Int32
  koszul_e_sq1_diagonal_ok : Bool
} derive(Debug, Eq)

///|
pub extend AdamsExtReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend AdamsExtReport with Eq::{not_equal, equal}

///|
/// **Condensed Higher-Order Structure #3 (`凝聚高階結構 ③` — `CondSpectralSheaf`)**:
/// Sheaf of graded cochain algebras over a Grothendieck site coupled with Twisted
/// Atiyah–Hirzebruch Spectral Sequence `d_3 = Sq^3 + H u (-)`, measuring both local-to-global
/// Čech twist gluing obstruction `cech_obstruction = k^1 - r^0` and twisted `E_4` survivor ranks.
pub(all) struct CondSpectralSheaf {
  space_name : String
  betti : Array[Int32]
  h3_twist_active : Bool
  cech_k1_minus_r0 : Int32
  global_twist_glues : Bool
  e2_total_rank : Int32
  e4_total_rank : Int32
  dd_zero : Bool
} derive(Debug, Eq)

///|
pub extend CondSpectralSheaf with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend CondSpectralSheaf with Eq::{not_equal, equal}

///|
/// Koszul resolution & derived tensor report over `F_2[x_1, ..., x_g]`.
pub(all) struct KoszulTorReport {
  generators_g : Int32
  dd_zero_all_degrees : Bool
  exact_in_positive_degrees : Bool
  tor_classical_ranks : Array[Int32]
  tor_two_sided_ranks : Array[Int32]
} derive(Debug, Eq)

///|
pub extend KoszulTorReport with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend KoszulTorReport with Eq::{not_equal, equal}

///|
pub fn ss_dq(page : SsPage) -> Int32 {
  if page.qflip {
    page.r - 1
  } else {
    -(page.r - 1)
  }
}

///|
pub fn ss_page_make(
  r : Int32,
  dims : Array[Array[Int32]],
  prime : Int32,
  qflip~ : Bool = false,
) -> SsPage {
  let np = dims.length()
  let nq = if np == 0 { 0 } else { dims[0].length() }
  let diffs : Array[Array[@gcd.FpMat?]] = []
  for _ in 0..<np {
    let row : Array[@gcd.FpMat?] = []
    for _ in 0..<nq {
      row.push(None)
    }
    diffs.push(row)
  }
  SsPage::{ r, np, nq, dims, diffs, prime, qflip, }
}

///|
pub fn ss_set_diff(
  page : SsPage,
  p_idx : Int32,
  q_idx : Int32,
  mat : @gcd.FpMat,
) -> Unit {
  if p_idx >= 0 && p_idx < page.np && q_idx >= 0 && q_idx < page.nq {
    page.diffs[p_idx][q_idx] = Some(mat)
  }
}

///|
/// Check `d_r o d_r == 0` at every bigraded cell `(p, q)`.
pub fn ss_page_dd_zero(page : SsPage) -> Bool {
  let dq = ss_dq(page)
  for p in 0..<page.np {
    for q in 0..<page.nq {
      let tp = p + page.r
      let tq = q + dq
      if tp >= 0 && tp < page.np && tq >= 0 && tq < page.nq {
        match (page.diffs[p][q], page.diffs[tp][tq]) {
          (Some(d1), Some(d2)) => {
            if d2.cols != d1.rows {
              return false
            }
            let prod = @gcd.fp_mat_mul(d2, d1)
            for v in prod.data {
              if v != 0 {
                return false
              }
            }
          }
          _ => ()
        }
      }
    }
  }
  true
}

///|
/// Turn the spectral sequence page: `E_{r+1}^{p,q} = ker(d_out) / im(d_in)` with zeroed differentials.
pub fn ss_page_next(page : SsPage) -> SsPage {
  let dq = ss_dq(page)
  let next_dims : Array[Array[Int32]] = []
  for p in 0..<page.np {
    let row : Array[Int32] = []
    for q in 0..<page.nq {
      let cur_dim = page.dims[p][q]
      let out_rk = match page.diffs[p][q] {
        Some(m) => @gcd.fp_rank(m)
        None => 0
      }
      let ker_dim = cur_dim - out_rk
      let sp = p - page.r
      let sq = q - dq
      let in_rk = if sp >= 0 && sp < page.np && sq >= 0 && sq < page.nq {
        match page.diffs[sp][sq] {
          Some(m) => @gcd.fp_rank(m)
          None => 0
        }
      } else {
        0
      }
      row.push(ker_dim - in_rk)
    }
    next_dims.push(row)
  }
  ss_page_make(page.r + 1, next_dims, page.prime, qflip=page.qflip)
}

///|
pub fn ss_total_by_degree(page : SsPage, max_n : Int32) -> Array[Int32] {
  let totals : Array[Int32] = []
  for n in 0..<=max_n {
    let mut sum = 0
    for p in 0..<page.np {
      let q = n - p
      if q >= 0 && q < page.nq {
        sum = sum + page.dims[p][q]
      }
    }
    totals.push(sum)
  }
  totals
}

///|
/// Compute the Serre spectral sequence for the Hopf fibration `S^1 -> S^3 -> S^2`:
/// `E_2^{p,q} = H^p(S^2) ⊗ H^q(S^1)` with transgression `d_2 : E_2^{0,1} --1--> E_2^{2,0}`,
/// converging to `H^*(S^3) = [1, 0, 0, 1]`.
pub fn serre_hopf_fibration_report(prime : Int32) -> SerreReport {
  let base_b = [1, 0, 1] // S^2
  let fiber_b = [1, 1] // S^1
  let dims : Array[Array[Int32]] = []
  for p in 0..<4 {
    let row : Array[Int32] = []
    for q in 0..<3 {
      let bp = if p < base_b.length() { base_b[p] } else { 0 }
      let fq = if q < fiber_b.length() { fiber_b[q] } else { 0 }
      row.push(bp * fq)
    }
    dims.push(row)
  }
  let e2 = ss_page_make(2, dims, prime)
  // Transgression d_2(generator of H^1(S^1)) = Euler class 1 in H^2(S^2)
  ss_set_diff(e2, 0, 1, @gcd.fp_mat_from_rows([[1]], prime))
  let dd_ok = ss_page_dd_zero(e2)
  let e2_tot = ss_total_by_degree(e2, 3)
  let e3 = ss_page_next(e2)
  let einfty_tot = ss_total_by_degree(e3, 3)
  SerreReport::{
    base_betti: base_b,
    fiber_betti: fiber_b,
    e2_totals: e2_tot,
    e_inf_totals: einfty_tot,
    dd_zero: dd_ok,
    converges_to_s3: einfty_tot == [1, 0, 0, 1],
    hurewicz_h2_s2_rank: base_b[2],
  }
}

// ---------------------------------------------------------------------------
// Steenrod Algebra A(2) Adem Reducer & Minimal Free Resolution `Ext_A(F_2, F_2)`
// ---------------------------------------------------------------------------

///|
fn lucas_binom_mod2(n : Int32, k : Int32) -> Int32 {
  if k < 0 || k > n {
    return 0
  }
  let mut nn = n
  let mut kk = k
  while nn > 0 || kk > 0 {
    if kk % 2 > nn % 2 {
      return 0
    }
    nn = nn / 2
    kk = kk / 2
  }
  1
}

///|
fn sq_mono_norm(m : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in m {
    if x > 0 {
      out.push(x)
    }
  }
  out
}

///|
/// `[E-Adem]` Expand `Sq^i Sq^j` into admissible Steenrod monomials mod 2.
pub fn cond_steenrod_adem_pair(i : Int32, j : Int32) -> Array[Array[Int32]] {
  if i >= 2 * j {
    return [sq_mono_norm([i, j])]
  }
  let out : Array[Array[Int32]] = []
  for k in 0..<=(i / 2) {
    if lucas_binom_mod2(j - k - 1, i - 2 * k) == 1 {
      out.push(sq_mono_norm([i + j - k, k]))
    }
  }
  out
}

///|
fn sq_xor_terms(xs : Array[Array[Int32]]) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let drop : Array[Bool] = []
  for _ in 0..<xs.length() {
    drop.push(false)
  }
  for i in 0..<xs.length() {
    if !drop[i] {
      let a = sq_mono_norm(xs[i])
      for j in (i + 1)..<xs.length() {
        if !drop[j] && sq_mono_norm(xs[j]) == a {
          drop[i] = true
          drop[j] = true
          break
        }
      }
    }
  }
  for i in 0..<xs.length() {
    if !drop[i] {
      out.push(sq_mono_norm(xs[i]))
    }
  }
  out
}

///|
fn sq_mono_mul(a : Array[Int32], b : Array[Int32]) -> Array[Array[Int32]] {
  let x = sq_mono_norm(a)
  let y = sq_mono_norm(b)
  if x.length() == 0 {
    return [y]
  }
  if y.length() == 0 {
    return [x]
  }
  let i = x[x.length() - 1]
  let j = y[0]
  if i >= 2 * j {
    let cat : Array[Int32] = []
    for t in x {
      cat.push(t)
    }
    for t in y {
      cat.push(t)
    }
    return [cat]
  }
  let lhs : Array[Int32] = []
  for t in 0..<(x.length() - 1) {
    lhs.push(x[t])
  }
  let rhs : Array[Int32] = []
  for t in 1..<y.length() {
    rhs.push(y[t])
  }
  let acc : Array[Array[Int32]] = []
  for term in cond_steenrod_adem_pair(i, j) {
    let t1 = if term.length() > 1 { term[1] } else { 0 }
    let left = sq_mono_mul(lhs, [term[0]])
    let right = sq_mono_mul([t1], rhs)
    for p in left {
      for q in right {
        for r in sq_mono_mul(p, q) {
          acc.push(r)
        }
      }
    }
  }
  sq_xor_terms(acc)
}

///|
fn sq_mono_deg(m : Array[Int32]) -> Int32 {
  let mut s = 0
  for x in m {
    s = s + x
  }
  s
}

///|
fn gen_admissible_monomials(max_d : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = [[]]
  let mut frontier : Array[Array[Int32]] = [[]]
  for _ in 0..<max_d {
    let next : Array[Array[Int32]] = []
    for m in frontier {
      let cur_sum = sq_mono_deg(m)
      let cap = if m.length() == 0 { max_d } else { m[m.length() - 1] / 2 }
      for i in 1..<=cap {
        if cur_sum + i <= max_d {
          let nm = m.copy()
          nm.push(i)
          out.push(nm)
          next.push(nm)
        }
      }
    }
    frontier = next
  }
  // Sort by (degree, lexicographic) so index 0 is [] (degree 0)
  for idx in 1..<out.length() {
    let key = out[idx]
    let kd = sq_mono_deg(key)
    let mut j = idx - 1
    while j >= 0 {
      let cd = sq_mono_deg(out[j])
      let greater = if cd > kd {
        true
      } else if cd < kd {
        false
      } else {
        out[j] > key
      }
      if greater {
        out[j + 1] = out[j]
        j = j - 1
      } else {
        break
      }
    }
    out[j + 1] = key
  }
  out
}

///|
fn f2_echelon_rows(
  rows : Array[Array[Int32]],
  dim : Int32,
) -> (Array[Array[Int32]], Array[Int32]) {
  let basis : Array[Array[Int32]] = []
  let pivots : Array[Int32] = []
  for r in rows {
    let v = r.copy()
    let mut changed = true
    while changed {
      changed = false
      let mut lead = -1
      for i in 0..<dim {
        if v[i] % 2 != 0 {
          lead = i
          break
        }
      }
      if lead >= 0 {
        for k in 0..<pivots.length() {
          if pivots[k] == lead {
            for t in 0..<dim {
              v[t] = (v[t] + basis[k][t]) % 2
            }
            changed = true
            break
          }
        }
      }
    }
    let mut final_lead = -1
    for i in 0..<dim {
      if v[i] % 2 != 0 {
        final_lead = i
        break
      }
    }
    if final_lead >= 0 {
      basis.push(v)
      pivots.push(final_lead)
    }
  }
  (basis, pivots)
}

///|
/// Compute minimal free resolution `Ext_B^{s,t}(F_2, F_2)` for a finite-dimensional
/// connected graded `F_2`-algebra given by basis degrees `deg` and multiplication table `tab`.
fn minimal_resolution_ext_f2(
  deg : Array[Int32],
  tab : Array[Array[Array[Int32]]],
  s_max : Int32,
  t_max : Int32,
) -> Array[Array[Int32]] {
  let nb = deg.length()
  let ext : Array[Array[Int32]] = []
  for _ in 0..<=s_max {
    let r : Array[Int32] = []
    for _ in 0..<=t_max {
      r.push(0)
    }
    ext.push(r)
  }
  ext[0][0] = 1
  let mut vgen : Array[Int32] = [0]
  let mut vrep : Array[Array[Int32]] = [[1]]
  let mut prev_dim = 1
  let mut prev_xa : Array[Int32] = [0]
  let mut prev_xv : Array[Int32] = [0]
  let mut prev_idx : Array[Array[Int32]] = []
  for _ in 0..<nb {
    prev_idx.push([0])
  }

  for s in 1..<=s_max {
    let ng = vgen.length()
    let fs_deg : Array[Int32] = []
    let fs_a : Array[Int32] = []
    let fs_v : Array[Int32] = []
    for v in 0..<ng {
      for i in 0..<nb {
        if deg[i] + vgen[v] <= t_max {
          fs_deg.push(deg[i] + vgen[v])
          fs_a.push(i)
          fs_v.push(v)
        }
      }
    }
    let dimfs = fs_deg.length()
    let idx : Array[Array[Int32]] = []
    for _ in 0..<nb {
      let r : Array[Int32] = []
      for _ in 0..<ng {
        r.push(-1)
      }
      idx.push(r)
    }
    for k in 0..<dimfs {
      idx[fs_a[k]][fs_v[k]] = k
    }
    let phi = @gcd.fp_mat_make(prev_dim, dimfs, 2, 0)
    for k in 0..<dimfs {
      let ai = fs_a[k]
      let v = fs_v[k]
      if s == 1 {
        if ai == 0 {
          @gcd.fp_mat_set(phi, 0, k, 1)
        }
      } else {
        let rep = vrep[v]
        for x in 0..<rep.length() {
          if rep[x] % 2 == 1 {
            for k2 in tab[ai][prev_xa[x]] {
              let tgt = prev_idx[k2][prev_xv[x]]
              if tgt >= 0 {
                @gcd.fp_mat_set(
                  phi,
                  tgt,
                  k,
                  (@gcd.fp_mat_get(phi, tgt, k) + 1) % 2,
                )
              }
            }
          }
        }
      }
    }

    let kdeg : Array[Array[Array[Int32]]] = []
    for _ in 0..<=t_max {
      kdeg.push([])
    }
    for t in 0..<=t_max {
      let cols : Array[Int32] = []
      for k in 0..<dimfs {
        if fs_deg[k] == t {
          cols.push(k)
        }
      }
      if cols.length() > 0 {
        let sub = @gcd.fp_mat_make(prev_dim, cols.length(), 2, 0)
        for c in 0..<cols.length() {
          for r in 0..<prev_dim {
            @gcd.fp_mat_set(sub, r, c, @gcd.fp_mat_get(phi, r, cols[c]))
          }
        }
        let ker = @gcd.fp_nullspace_basis(sub)
        for kv in ker {
          let vec : Array[Int32] = []
          for _ in 0..<dimfs {
            vec.push(0)
          }
          for c in 0..<cols.length() {
            vec[cols[c]] = kv[c] % 2
          }
          kdeg[t].push(vec)
        }
      }
    }

    let nextdeg : Array[Int32] = []
    let nextrep : Array[Array[Int32]] = []
    for t in 0..<=t_max {
      let rows : Array[Array[Int32]] = []
      for ai in 1..<nb {
        let src = t - deg[ai]
        if src >= 0 {
          for kv in kdeg[src] {
            let outv : Array[Int32] = []
            for _ in 0..<dimfs {
              outv.push(0)
            }
            for x in 0..<dimfs {
              if kv[x] % 2 == 1 {
                for k2 in tab[ai][fs_a[x]] {
                  let at = idx[k2][fs_v[x]]
                  if at >= 0 {
                    outv[at] = (outv[at] + 1) % 2
                  }
                }
              }
            }
            rows.push(outv)
          }
        }
      }
      let (wb, wp) = f2_echelon_rows(rows, dimfs)
      ext[s][t] = kdeg[t].length() - wb.length()
      if kdeg[t].length() > 0 {
        let cur_b = wb.copy()
        let cur_p = wp.copy()
        for kv in kdeg[t] {
          let (aug_b, aug_p) = f2_echelon_rows([kv], dimfs)
          // Reduce kv against cur_b
          let v = kv.copy()
          let mut ch = true
          while ch {
            ch = false
            let mut ld = -1
            for i in 0..<dimfs {
              if v[i] % 2 != 0 {
                ld = i
                break
              }
            }
            if ld >= 0 {
              for k in 0..<cur_p.length() {
                if cur_p[k] == ld {
                  for u in 0..<dimfs {
                    v[u] = (v[u] + cur_b[k][u]) % 2
                  }
                  ch = true
                  break
                }
              }
            }
          }
          let mut rem_ld = -1
          for i in 0..<dimfs {
            if v[i] % 2 != 0 {
              rem_ld = i
              break
            }
          }
          if rem_ld >= 0 && aug_b.length() >= 0 && aug_p.length() >= 0 {
            cur_b.push(v)
            cur_p.push(rem_ld)
            nextdeg.push(t)
            nextrep.push(kv)
          }
        }
      }
    }
    vgen = nextdeg
    vrep = nextrep
    prev_dim = dimfs
    prev_xa = fs_a
    prev_xv = fs_v
    prev_idx = idx
  }
  ext
}

///|
/// Build truncated mod-2 Steenrod algebra `A_{<=trunc_deg}` and compute Adams `E_2`
/// table `Ext_A^{s,t}(F_2, F_2)` for `s <= s_max, t <= t_max`, plus Koszul control `E(Sq^1)`.
pub fn adams_ext_f2_report(
  trunc_deg : Int32,
  s_max : Int32,
  t_max : Int32,
) -> AdamsExtReport {
  let basis = gen_admissible_monomials(trunc_deg)
  let nb = basis.length()
  let deg : Array[Int32] = []
  for m in basis {
    deg.push(sq_mono_deg(m))
  }
  let tab : Array[Array[Array[Int32]]] = []
  for i in 0..<nb {
    let row : Array[Array[Int32]] = []
    for j in 0..<nb {
      let hits : Array[Int32] = []
      if deg[i] + deg[j] <= trunc_deg {
        for prod_m in sq_mono_mul(basis[i], basis[j]) {
          for k in 0..<nb {
            if basis[k] == prod_m {
              hits.push(k)
              break
            }
          }
        }
      }
      row.push(hits)
    }
    tab.push(row)
  }
  let ext_dims = minimal_resolution_ext_f2(deg, tab, s_max, t_max)
  let h0_tower : Array[Int32] = []
  for s in 0..<=s_max {
    if s <= t_max {
      h0_tower.push(ext_dims[s][s])
    }
  }

  // Koszul control: exterior algebra `E(Sq^1) = F_2[Sq^1]/(Sq^1)^2` has `Ext^{s,t} = delta_{s,t}`
  let ext_esq1 = minimal_resolution_ext_f2(
    [0, 1],
    [[[0], [1]], [[1], []]],
    s_max,
    s_max,
  )
  let mut koszul_ok = true
  for s in 0..<=s_max {
    for t in 0..<=s_max {
      let want = if s == t { 1 } else { 0 }
      if ext_esq1[s][t] != want {
        koszul_ok = false
      }
    }
  }

  AdamsExtReport::{
    trunc_deg,
    s_max,
    t_max,
    admissible_basis_count: nb,
    ext_dims,
    stem0_h0_tower: h0_tower,
    hopf_h1_ext12: if s_max >= 1 && t_max >= 2 {
      ext_dims[1][2]
    } else {
      -1
    },
    two_eta_ext23: if s_max >= 2 && t_max >= 3 {
      ext_dims[2][3]
    } else {
      -1
    },
    hopf_h2_ext14: if s_max >= 1 && t_max >= 4 {
      ext_dims[1][4]
    } else {
      -1
    },
    koszul_e_sq1_diagonal_ok: koszul_ok,
  }
}

///|
/// Construct **Condensed Higher-Order Structure #3 (`CondSpectralSheaf`)**:
/// computes Čech gluing obstruction `k^1 - r^0` for local `H^3`-twist data over a
/// covering site AND runs the Twisted AHSS `d_3 = Sq^3 + H u (-)` (`dim X <= 5 => Sq^3 = 0`)!
pub fn cond_spectral_sheaf_build(
  space_name : String,
  betti : Array[Int32],
  h3_active : Bool,
  cech_d0 : @gcd.FpMat,
  cech_d1 : @gcd.FpMat,
) -> CondSpectralSheaf {
  // Čech exactness `0 -> F(U) -> prod F(U_i) --d0--> prod F(U_ij) --d1--> ...`:
  // obstruction to gluing compatible 1-cochains is `dim(ker d1) - rank(d0) = k^1 - r^0`!
  let r0 = @gcd.fp_rank(cech_d0)
  let k1 = cech_d1.cols - @gcd.fp_rank(cech_d1)
  let obs = k1 - r0
  let glues = obs == 0

  // Build AHSS E_3 page in range p in 0..betti.length(), q in 0..3 (K-theory 2-periodic fiber: q=0, 2)
  let np = betti.length()
  let dims : Array[Array[Int32]] = []
  for p in 0..<np {
    // q = 0, 1, 2 (Z, 0, Z Bott periodicity)
    dims.push([betti[p], 0, betti[p]])
  }
  let e3 = ss_page_make(3, dims, 5)
  // Standard AHSS d_3 has bidegree (3, -2): maps (p, 2) -> (p + 3, 0) via cup with H in H^3(X)
  if h3_active && glues && np >= 4 && betti[0] > 0 && betti[3] > 0 {
    // Cup with fundamental/volume H^3 generator maps H^0 (dim 1) into H^3
    let cup_mat = @gcd.fp_mat_make(betti[3], betti[0], 5, 0)
    @gcd.fp_mat_set(cup_mat, 0, 0, 1)
    ss_set_diff(e3, 0, 2, cup_mat)
  }
  let dd_ok = ss_page_dd_zero(e3)
  let e4 = ss_page_next(e3)
  let mut e2_tot = 0
  let mut e4_tot = 0
  for p in 0..<np {
    for q in 0..<3 {
      e2_tot = e2_tot + e3.dims[p][q]
      e4_tot = e4_tot + e4.dims[p][q]
    }
  }
  CondSpectralSheaf::{
    space_name,
    betti,
    h3_twist_active: h3_active,
    cech_k1_minus_r0: obs,
    global_twist_glues: glues,
    e2_total_rank: e2_tot,
    e4_total_rank: e4_tot,
    dd_zero: dd_ok,
  }
}

///|
/// Verify Koszul complex `K_*(F_2[x_1..x_g])` (`d^2 = 0` and exactness in positive
/// homological degrees) and compute both classical `Tor_i = C(g, i)` and two-sided
/// `K ⊗_A K' ⊗_A F_2` `C(2g, i)` ranks!
pub fn koszul_tor_report(g : Int32, trunc_n : Int32) -> KoszulTorReport {
  // Generate all exponent vectors of total degree <= trunc_n
  let mut total_codes = 1
  for _ in 0..<g {
    total_codes = total_codes * (trunc_n + 1)
  }
  let mons : Array[Array[Int32]] = []
  for code in 0..<total_codes {
    let ex : Array[Int32] = []
    let mut c = code
    let mut sum = 0
    for _ in 0..<g {
      let digit = c % (trunc_n + 1)
      ex.push(digit)
      sum = sum + digit
      c = c / (trunc_n + 1)
    }
    if sum <= trunc_n {
      mons.push(ex)
    }
  }
  // Cells[i][t]: homological degree i, internal degree t = i + |m|
  let max_t = trunc_n + g
  let cells : Array[Array[Array[(Int32, Int32)]]] = []
  for _ in 0..<=g {
    let by_t : Array[Array[(Int32, Int32)]] = []
    for _ in 0..<=max_t {
      by_t.push([])
    }
    cells.push(by_t)
  }
  let num_masks = 1 << g
  for mask in 0..<num_masks {
    let mut pop = 0
    for j in 0..<g {
      if (mask >> j) % 2 == 1 {
        pop = pop + 1
      }
    }
    for mi in 0..<mons.length() {
      let mut mdeg = 0
      for x in mons[mi] {
        mdeg = mdeg + x
      }
      if mdeg + pop <= trunc_n {
        cells[pop][mdeg + pop].push((mask, mi))
      }
    }
  }
  let build_d = (i : Int32, t : Int32) => {
    let src = cells[i][t]
    let dst = cells[i - 1][t]
    let mat = @gcd.fp_mat_make(dst.length(), src.length(), 2, 0)
    for c in 0..<src.length() {
      let (mask, mi) = src[c]
      for j in 0..<g {
        if (mask >> j) % 2 == 1 {
          let nmask = mask - (1 << j)
          let want_m = mons[mi].copy()
          want_m[j] = want_m[j] + 1
          let mut nmi = -1
          for k in 0..<mons.length() {
            if mons[k] == want_m {
              nmi = k
              break
            }
          }
          if nmi >= 0 {
            for r in 0..<dst.length() {
              if dst[r] == (nmask, nmi) {
                @gcd.fp_mat_set(mat, r, c, (@gcd.fp_mat_get(mat, r, c) + 1) % 2)
                break
              }
            }
          }
        }
      }
    }
    mat
  }

  let mut dd_ok = true
  let mut exact_ok = true
  // Check exactness strictly below the truncation ceiling `t < trunc_n`
  for t in 1..<trunc_n {
    for i in 1..<=g {
      let di = build_d(i, t)
      let ker_dim = di.cols - @gcd.fp_rank(di)
      let im_next = if i + 1 <= g {
        let di1 = build_d(i + 1, t)
        let prod = @gcd.fp_mat_mul(di, di1)
        for v in prod.data {
          if v != 0 {
            dd_ok = false
          }
        }
        @gcd.fp_rank(di1)
      } else {
        0
      }
      if ker_dim != im_next {
        exact_ok = false
      }
    }
  }

  // Classical reduced complex `K_* ⊗_A F_2` (constant-term projection => zero differential on subsets of {1..g})
  let classical : Array[Int32] = []
  for i in 0..<=g {
    let mut cnt = 0
    for mask in 0..<num_masks {
      let mut pop = 0
      for j in 0..<g {
        if (mask >> j) % 2 == 1 {
          pop = pop + 1
        }
      }
      if pop == i {
        cnt = cnt + 1
      }
    }
    classical.push(cnt)
  }
  // Two-sided `K ⊗_A K' ⊗_A F_2` basis pairs `(S_1, S_2)` (`notebook/dtensor` `[E-Tor]`): `|S_1| + |S_2| = deg`
  let two_sided : Array[Int32] = []
  for tot_i in 0..<=(2 * g) {
    let mut sum = 0
    for i1 in 0..<=g {
      let i2 = tot_i - i1
      if i2 >= 0 && i2 <= g {
        sum = sum + classical[i1] * classical[i2]
      }
    }
    two_sided.push(sum)
  }
  KoszulTorReport::{
    generators_g: g,
    dd_zero_all_degrees: dd_ok,
    exact_in_positive_degrees: exact_ok,
    tor_classical_ranks: classical,
    tor_two_sided_ranks: two_sided,
  }
}

///|
/// Master check for Serre, Steenrod–Adams (`2*eta = 0`), Higher Structure #3 (`CondSpectralSheaf`), and Koszul `Tor`.
pub fn cond_check_structure_3_and_spectral_homotopy() -> Bool {
  // 1. Serre on Hopf `S^1 -> S^3 -> S^2`
  let serre = serre_hopf_fibration_report(7)
  if !serre.dd_zero || !serre.converges_to_s3 || serre.hurewicz_h2_s2_rank != 1 {
    return false
  }

  // 2. Steenrod Adem identities (`Sq^1 Sq^1 = 0`, `Sq^1 Sq^2 = Sq^3`, `Sq^2 Sq^2 = Sq^3 Sq^1`)
  if cond_steenrod_adem_pair(1, 1) != [] ||
    cond_steenrod_adem_pair(1, 2) != [[3]] ||
    cond_steenrod_adem_pair(2, 2) != [[3, 1]] {
    return false
  }

  // 3. Adams `Ext_A(F_2, F_2)` at `D = 8, s <= 3, t <= 8`:
  //    `Ext^{1,2} = 1` (`h_1 = eta`), `Ext^{2,3} = 0` (`h_0*h_1 = 0 => 2*eta = 0`!),
  //    `Ext^{1,4} = 1` (`h_2 = nu`), `Ext^{s,s} = 1` (`h_0^s`), `Ext^{3,6} = 1`!
  let adams = adams_ext_f2_report(8, 3, 8)
  if !adams.koszul_e_sq1_diagonal_ok ||
    adams.stem0_h0_tower != [1, 1, 1, 1] ||
    adams.hopf_h1_ext12 != 1 ||
    adams.two_eta_ext23 != 0 ||
    adams.hopf_h2_ext14 != 1 ||
    adams.ext_dims[2][4] != 1 ||
    adams.ext_dims[2][5] != 1 ||
    adams.ext_dims[3][6] != 1 {
    return false
  }

  // 4. Higher-Order Structure #3 (`CondSpectralSheaf`):
  //    Good sheaf cover (2 patches, d0 = [[-1, 1]], d1 = 0x1 -> k^1 - r^0 = 1 - 1 = 0) glues twist on S^3 and kills H^0/H^3!
  //    Bad fake cover (d0 = [[0, 0]], d1 = 0x1 -> k^1 - r^0 = 1 - 0 = 1 > 0) obstructs global twist!
  let good_d0 = @gcd.fp_mat_from_rows([[4, 1]], 5) // (-1, 1) mod 5
  let zero_d1 = @gcd.fp_mat_make(1, 1, 5, 0)
  let s3_twisted = cond_spectral_sheaf_build(
    "S^3",
    [1, 0, 0, 1],
    true,
    good_d0,
    zero_d1,
  )
  let bad_d0 = @gcd.fp_mat_from_rows([[0, 0]], 5)
  let s3_obstructed = cond_spectral_sheaf_build(
    "S^3_bad",
    [1, 0, 0, 1],
    true,
    bad_d0,
    zero_d1,
  )
  let s2_untwistable = cond_spectral_sheaf_build(
    "S^2",
    [1, 0, 1],
    true,
    good_d0,
    zero_d1,
  )
  if !s3_twisted.dd_zero ||
    !s3_twisted.global_twist_glues ||
    s3_twisted.cech_k1_minus_r0 != 0 ||
    s3_twisted.e2_total_rank != 4 ||
    s3_twisted.e4_total_rank != 2 {
    return false
  }
  if s3_obstructed.global_twist_glues || s3_obstructed.cech_k1_minus_r0 != 1 {
    return false
  }
  // `dim S^2 <= 5` and `H^3(S^2) = 0` => twist invisible (`e4 == e2`)!
  if s2_untwistable.e4_total_rank != s2_untwistable.e2_total_rank {
    return false
  }

  // 5. Koszul Derived Tensor `Tor` on `F_2[x, y]` (`g = 2`): classical `[1, 2, 1]`, two-sided `[1, 4, 6, 4, 1]`
  let kos = koszul_tor_report(2, 4)
  kos.dd_zero_all_degrees &&
  kos.exact_in_positive_degrees &&
  kos.tor_classical_ranks == [1, 2, 1] &&
  kos.tor_two_sided_ranks == [1, 4, 6, 4, 1]
}
