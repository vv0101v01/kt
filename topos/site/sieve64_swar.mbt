///|
// Topos Pillar (`topos/site`) — 64-Bit Register SWAR Bi-Heyting Sieve Kernel (`Sieve64`),
// Precomposition Bit-Matrix (`SitePrecomp64`), MAC Forward-Checking Matching-Family Solver,
// and Cubical SIP Representation-Isomorphism Certificate.
//
// Mathematical & Algorithmic Derivations:
//   1. [D-Sieve64] On any finite category `C` with `|Mor(C)| <= 64`, a sieve `S` on `u`
//      is uniquely encoded as a single `UInt64` word `mask ⊆ cod_masks[u]` satisfying
//      `f ∈ mask ⟹ downset_rows[f] ⊆ mask`.
//   2. [T-BiHeyting-SWAR] Under `@swar` bit-parallel primitives:
//        - Meet / Join / Inclusion: `s & t`, `s | t`, `(s & t) == s` in `O(1)` register ops;
//        - Heyting implication: `(S ⇒ T)` via `@swar.swar_heyting_impl64` (`O(popcnt)`);
//        - Lawvere–Tierney double-negation nucleus: `j_¬¬(S) = ¬_64(¬_64(S))`;
//        - Co-Heyting subtraction `(S ⇐ T)` (left adjoint `(S ⇐ T) ⊆ U ⟺ S ⊆ T ∪ U`):
//          equals the downset closure of `S & ¬T` (`@swar.swar_coheyting_sub64`),
//          yielding Lawvere boundary `∂S = S & (~_64 S)` in zero heap allocations!
//   3. [Alg-MAC-Matching] `enumerate_matching_families_mac64` propagates naturality
//      constraints `P.res[g](x_f) == x_{f ∘ g}` eagerly upon every arrow assignment,
//      pruning inconsistent partial families immediately while remaining 100% extensionally
//      identical to `enumerate_matching_families`.

///|
/// Register-level 64-bit sieve on `target` (`|Mor(C)| <= 64`).
#derive(Debug, Eq)
pub(all) struct Sieve64 {
  target : Int32
  mask : UInt64
}

///|
pub extend Sieve64 with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Sieve64 with Eq::{not_equal, equal}

///|
/// Precomputed 64-bit categorical composition & precomposition bit-tables on `cat`.
pub(all) struct SitePrecomp64 {
  cat : @sym.FinCat
  cod_masks : Array[UInt64]
  downset_rows : Array[UInt64]
}

///|
/// Build `SitePrecomp64` for any finite category with `cat.nmor <= 64`.
pub fn site_precomp64_build(c : @sym.FinCat) -> SitePrecomp64 {
  guard c.nmor <= 64 else { abort("site_precomp64_build: nmor > 64") }
  let cod_masks = Array::make(c.nobj, 0UL)
  let downset_rows = Array::make(c.nmor, 0UL)
  for f in 0..<c.nmor {
    let u = c.cod[f]
    cod_masks[u] = cod_masks[u] | (1UL << f)
    let mut row = 1UL << f
    for g in 0..<c.nmor {
      if c.cod[g] == c.dom[f] {
        let fg = c.comp[f * c.nmor + g]
        if fg >= 0 {
          row = row | (1UL << fg)
        }
      }
    }
    downset_rows[f] = row
  }
  SitePrecomp64::{ cat: c, cod_masks, downset_rows, }
}

///|
pub fn sieve64_of_sieve(s : Sieve) -> Sieve64 {
  let mut mask = 0UL
  for f in s.arrows {
    mask = mask | (1UL << f)
  }
  Sieve64::{ target: s.target, mask, }
}

///|
pub fn sieve_of_sieve64(s64 : Sieve64) -> Sieve {
  let arrows : Array[Int32] = []
  let mut rem = s64.mask
  while rem != 0UL {
    arrows.push(rem.ctz())
    rem = rem & (rem - 1UL)
  }
  Sieve::{ target: s64.target, arrows, }
}

///|
pub fn sieve64_empty(target : Int32) -> Sieve64 {
  Sieve64::{ target, mask: 0UL, }
}

///|
pub fn sieve64_maximal(sp : SitePrecomp64, target : Int32) -> Sieve64 {
  Sieve64::{ target, mask: sp.cod_masks[target], }
}

///|
pub fn sieve64_generate(
  sp : SitePrecomp64,
  target : Int32,
  seed_mask : UInt64,
) -> Sieve64 {
  let valid_seeds = seed_mask & sp.cod_masks[target]
  Sieve64::{
    target,
    mask: @swar.swar_downset_closure64(valid_seeds, sp.downset_rows),
  }
}

///|
pub fn sieve64_inter(s : Sieve64, t : Sieve64) -> Sieve64 {
  guard s.target == t.target else { abort("sieve64_inter: target mismatch") }
  Sieve64::{ target: s.target, mask: s.mask & t.mask, }
}

///|
pub fn sieve64_union(s : Sieve64, t : Sieve64) -> Sieve64 {
  guard s.target == t.target else { abort("sieve64_union: target mismatch") }
  Sieve64::{ target: s.target, mask: s.mask | t.mask, }
}

///|
pub fn sieve64_subset(s : Sieve64, t : Sieve64) -> Bool {
  s.target == t.target && (s.mask & t.mask) == s.mask
}

///|
pub fn sieve64_pullback(sp : SitePrecomp64, s : Sieve64, h : Int32) -> Sieve64 {
  let c = sp.cat
  guard c.cod[h] == s.target else {
    abort("sieve64_pullback: cod(h) != target")
  }
  let v = c.dom[h]
  let mut rem = sp.cod_masks[v]
  let mut mask = 0UL
  while rem != 0UL {
    let g = rem.ctz()
    let hg = c.comp[h * c.nmor + g]
    if hg >= 0 && ((s.mask >> hg) & 1UL) == 1UL {
      mask = mask | (1UL << g)
    }
    rem = rem & (rem - 1UL)
  }
  Sieve64::{ target: v, mask, }
}

///|
pub fn sieve64_heyting_implies(
  sp : SitePrecomp64,
  s : Sieve64,
  t : Sieve64,
) -> Sieve64 {
  guard s.target == t.target else {
    abort("sieve64_heyting_implies: target mismatch")
  }
  let dom_mask = sp.cod_masks[s.target]
  Sieve64::{
    target: s.target,
    mask: @swar.swar_heyting_impl64(dom_mask, s.mask, t.mask, sp.downset_rows),
  }
}

///|
pub fn sieve64_heyting_neg(sp : SitePrecomp64, s : Sieve64) -> Sieve64 {
  sieve64_heyting_implies(sp, s, sieve64_empty(s.target))
}

///|
pub fn sieve64_double_negation(sp : SitePrecomp64, s : Sieve64) -> Sieve64 {
  sieve64_heyting_neg(sp, sieve64_heyting_neg(sp, s))
}

///|
pub fn sieve64_coheyting_sub(
  sp : SitePrecomp64,
  s : Sieve64,
  t : Sieve64,
) -> Sieve64 {
  guard s.target == t.target else {
    abort("sieve64_coheyting_sub: target mismatch")
  }
  Sieve64::{
    target: s.target,
    mask: @swar.swar_coheyting_sub64(s.mask, t.mask, sp.downset_rows),
  }
}

///|
pub fn sieve64_coheyting_neg(sp : SitePrecomp64, s : Sieve64) -> Sieve64 {
  sieve64_coheyting_sub(sp, sieve64_maximal(sp, s.target), s)
}

///|
pub fn sieve64_coheyting_boundary(sp : SitePrecomp64, s : Sieve64) -> Sieve64 {
  sieve64_inter(s, sieve64_coheyting_neg(sp, s))
}

///|
/// Enumerate all `Sieve64` sieves on `target` via recursive branching with 64-bit downset closure.
pub fn enumerate_sieves64_on_obj(
  sp : SitePrecomp64,
  target : Int32,
) -> Array[Sieve64] {
  let out : Array[Sieve64] = []
  let seen : Map[UInt64, Bool] = Map([])
  let arrows : Array[Int32] = []
  let mut rem = sp.cod_masks[target]
  while rem != 0UL {
    arrows.push(rem.ctz())
    rem = rem & (rem - 1UL)
  }
  fn dfs(
    idx : Int32,
    cur_mask : UInt64,
    arrows : Array[Int32],
    sp : SitePrecomp64,
    target : Int32,
    seen : Map[UInt64, Bool],
    out : Array[Sieve64],
  ) -> Unit {
    if idx >= arrows.length() {
      if !seen.contains(cur_mask) {
        seen[cur_mask] = true
        out.push(Sieve64::{ target, mask: cur_mask, })
      }
      return
    }
    let f = arrows[idx]
    if ((cur_mask >> f) & 1UL) == 1UL {
      dfs(idx + 1, cur_mask, arrows, sp, target, seen, out)
    } else {
      // Branch 0: omit `f`
      dfs(idx + 1, cur_mask, arrows, sp, target, seen, out)
      // Branch 1: include `f` and its entire precomposition downset in O(1)
      dfs(idx + 1, cur_mask | sp.downset_rows[f], arrows, sp, target, seen, out)
    }
  }
  dfs(0, 0UL, arrows, sp, target, seen, out)
  out
}

///|
/// MAC (Maintaining Arc Consistency) forward-checking solver for `Match(s, p)`:
/// Assigning `x_f ∈ P(dom(f))` immediately forces `x_{f ∘ g} = P.res[g](x_f)` along every
/// composable `g` and checks consistency against any previously assigned arrows `h`
/// where `h ∘ k == f` (`P.res[k](x_h) == x_f`), pruning dead search subtrees in `O(|Mor|)`.
pub fn enumerate_matching_families_mac64(
  p : @sym.Presheaf,
  s : Sieve,
  cap~ : Int32 = 4096,
) -> Array[MatchingFamily] {
  let k = s.arrows.length()
  if k == 0 {
    return [MatchingFamily::{ sieve: s, values: [], }]
  }
  let c = p.cat
  if c.nmor > 64 {
    return enumerate_matching_families(p, s, cap~)
  }
  let pos_of_mor = Array::make(c.nmor, -1)
  for i in 0..<k {
    pos_of_mor[s.arrows[i]] = i
  }
  // Precompute forward composition arcs `(pos_f, g, pos_fg)` for `f ∈ S`
  let fwd_arcs : Array[Array[(Int32, Int32)]] = Array::makei(k, i => {
    let f = s.arrows[i]
    let arcs : Array[(Int32, Int32)] = []
    for g in 0..<c.nmor {
      if c.cod[g] == c.dom[f] {
        let fg = c.comp[f * c.nmor + g]
        if fg >= 0 && pos_of_mor[fg] >= 0 {
          arcs.push((g, pos_of_mor[fg]))
        }
      }
    }
    arcs
  })
  let assigned = Array::make(k, -1)
  let out : Array[MatchingFamily] = []

  fn mac_search(
    idx : Int32,
    k : Int32,
    s : Sieve,
    p : @sym.Presheaf,
    c : @sym.FinCat,
    fwd_arcs : Array[Array[(Int32, Int32)]],
    assigned : Array[Int32],
    out : Array[MatchingFamily],
    cap : Int32,
  ) -> Unit {
    if out.length() >= cap {
      return
    }
    // Find first unassigned position
    let mut pos = idx
    while pos < k && assigned[pos] >= 0 {
      pos = pos + 1
    }
    if pos >= k {
      out.push(MatchingFamily::{ sieve: s, values: assigned.copy(), })
      return
    }
    let f = s.arrows[pos]
    let dom_sz = p.size[c.dom[f]]
    for val in 0..<dom_sz {
      // Check & propagate `assigned[pos] = val`
      let trail : Array[Int32] = [pos]
      assigned[pos] = val
      let mut ok = true
      // Propagate forward from `pos`
      for arc in fwd_arcs[pos] {
        let (g, pos_fg) = arc
        let req = p.res[g][val]
        if assigned[pos_fg] < 0 {
          assigned[pos_fg] = req
          trail.push(pos_fg)
        } else if assigned[pos_fg] != req {
          ok = false
          break
        }
      }
      // Also check backward compatibility with already-assigned `i < pos`
      if ok {
        for prev in 0..<k {
          if ok && assigned[prev] >= 0 {
            let pv = assigned[prev]
            for arc in fwd_arcs[prev] {
              let (g, pos_fg) = arc
              let req = p.res[g][pv]
              if assigned[pos_fg] >= 0 && assigned[pos_fg] != req {
                ok = false
                break
              }
            }
          }
        }
      }
      if ok {
        mac_search(pos + 1, k, s, p, c, fwd_arcs, assigned, out, cap)
      }
      for tpos in trail {
        assigned[tpos] = -1
      }
      if out.length() >= cap {
        return
      }
    }
  }

  mac_search(0, k, s, p, c, fwd_arcs, assigned, out, cap)
  out
}

///|
/// Verify Cubical SIP representation isomorphism between `(Sieve, ∩, ∪, ⇒, ¬¬)` and
/// `(Sieve64, &, |, ⇒_64, ¬¬_64)`, bi-Heyting Galois adjunctions `(∧ ⊣ ⇒)` & `(⇐ ⊣ ∨)`,
/// Lawvere co-Heyting Leibniz boundary law, and MAC matching-family completeness!
pub fn verify_sieve64_sip_biheyting_and_mac_equivalence() -> Bool {
  // Diamond poset site: 0 -> 1, 0 -> 2, 1 -> 3, 2 -> 3 (with common composite 0 -> 3)
  let c = @sym.cat_poset(4, [(0, 1), (0, 2), (1, 3), (2, 3)])
  let sp = site_precomp64_build(c)
  for u in 0..<c.nobj {
    let s_list = all_sieves_on(c, u)
    let s64_list = enumerate_sieves64_on_obj(sp, u)
    if s_list.length() != s64_list.length() {
      return false
    }
    for s in s_list {
      let s64 = sieve64_of_sieve(s)
      if sieve_of_sieve64(s64) != s || sieve64_generate(sp, u, s64.mask) != s64 {
        return false
      }
      for h in 0..<c.nmor {
        if c.cod[h] == u &&
          sieve_of_sieve64(sieve64_pullback(sp, s64, h)) !=
          sieve_pullback(c, s, h) {
          return false
        }
      }
      let neg_s = sieve_heyting_implies(c, s, sieve_empty(u))
      let dneg_s = sieve_heyting_implies(c, neg_s, sieve_empty(u))
      if sieve_of_sieve64(sieve64_heyting_neg(sp, s64)) != neg_s ||
        sieve_of_sieve64(sieve64_double_negation(sp, s64)) != dneg_s {
        return false
      }
      for t in s_list {
        let t64 = sieve64_of_sieve(t)
        if sieve_of_sieve64(sieve64_inter(s64, t64)) != sieve_inter(s, t) ||
          sieve_of_sieve64(sieve64_union(s64, t64)) != sieve_union(s, t) ||
          sieve_of_sieve64(sieve64_heyting_implies(sp, s64, t64)) !=
          sieve_heyting_implies(c, s, t) {
          return false
        }
        // Verify co-Heyting Galois adjunction: `(s64 ⇐ t64) ⊆ w64 ⟺ s64 ⊆ (t64 | w64)`
        let sub_st = sieve64_coheyting_sub(sp, s64, t64)
        for w in s_list {
          let w64 = sieve64_of_sieve(w)
          if sieve64_subset(sub_st, w64) !=
            sieve64_subset(s64, sieve64_union(t64, w64)) {
            return false
          }
        }
        // Verify Lawvere co-Heyting Leibniz product rule: `∂(S ∧ T) == (∂S ∧ T) ∨ (S ∧ ∂T)`
        let bd_st = sieve64_coheyting_boundary(sp, sieve64_inter(s64, t64))
        let rhs = sieve64_union(
          sieve64_inter(sieve64_coheyting_boundary(sp, s64), t64),
          sieve64_inter(s64, sieve64_coheyting_boundary(sp, t64)),
        )
        if bd_st != rhs {
          return false
        }
      }
    }
  }
  // Verify MAC matching-family solver matches `enumerate_matching_families` on representable + product presheaves
  let y3 = presheaf_representable(c, 3)
  let id_y3 = presheaf_hom_id(y3)
  let (eq_psh, _) = presheaf_equalizer(y3, id_y3, id_y3)
  if !@sym.is_category(cat_slice(c, 3).slice_cat) || eq_psh.size != y3.size {
    return false
  }
  let (prod_psh, _, _) = presheaf_product(y3, y3)
  for s in all_sieves_on(c, 3) {
    let mf_ref = enumerate_matching_families(prod_psh, s)
    let mf_mac = enumerate_matching_families_mac64(prod_psh, s)
    if mf_ref.length() != mf_mac.length() {
      return false
    }
    for x in mf_mac {
      if !mf_ref.contains(x) {
        return false
      }
    }
  }
  true
}
