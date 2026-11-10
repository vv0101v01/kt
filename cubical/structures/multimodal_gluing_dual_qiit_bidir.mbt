// ---------------------------------------------------------------------------
// cubical/structures/multimodal_gluing_dual_qiit_bidir.mbt
// ---------------------------------------------------------------------------
// Stage-3 Higher Cubical Frontier Synthesis (`F1: cubical-structures`, L6):
// Realizes and cross-wires all 7 frontier capabilities directly into the
// existing cubical kernel (`@kernel`), bidirectional elaborator (`@elaborator`),
// homotopy engine (`@homotopy`), Grothendieck topos engine (`@topos`), SWAR
// hardware substrate (`@accel`), and `cubical/structures` (`CubicalGlueSpec`,
// `UsageMult`):
//
//   1. Multimodal Dependent Type Theory (MTT): 3-mode Cohesive–Guarded–Discrete
//      strict 2-category (`Set`, `Space`, `Clocked`), Godement middle-four
//      interchange, Fitch-style left-adjoint context locks `Γ.lock_μ`, modal
//      types `⟨μ | A⟩`, contravariant 2-cell variable keys `x^α`, and positive
//      `let mod_ν(mod_μ(x)) = s in u` elimination;
//   2. Geometric Composition & Gluing Operations: Coupling Orton–Pitts twisted
//      `CubicalGlueSpec` Kan transport (`@kernel.coe_value`) with `@topos`
//      Artin comma gluing `Gl(Γ) = Set ↓ Γ`, STC Boolean canonicity on
//      `Discrete(2)`, SGA4 open–closed recollement, and horizontal geometric
//      morphism pullback composition;
//   3. Dual-Context Resource-Oriented Dependent Systems: Bridging `UsageMult`
//      (`UZero`, `UOne`, `UMany`) to `@accel`'s 16-lane 4-bit SWAR QTT register
//      (`swar_grade16_*`), enforcing `0 · Γ` compile-time type-formation erasure
//      alongside strict linear `1 · x` runtime consumption in `O(1)` instructions;
//   4. Cubical Quotient Inductive-Inductive Types (QIITs): Mutual `(Con, Ty)`
//      cubical QIIT with explicit 1D path constructors over `@face_bdd.Dim`
//      (`A[id] ≡_{i=0..1} A`) and displayed section elimination into `@kernel.DValue`
//      (`DVPathLam`) certified at endpoints `DZero` and `DOne`;
//   5–7. Memoized Type Checking + Bidirectional Induction + Bidirectional
//      Dependent Types: Hash-consed DAG + `@accel.SwarMemoTable64` `O(d)` vs
//      `O(2^d)` diamond checking, indexed `Vec` & motive-synthesizing `NatInd`
//      elaboration, and closed `@kernel.DTerm` certification.
// ---------------------------------------------------------------------------

// ===========================================================================
// Pillar 1: Multimodal Dependent Type Theory (3-Mode Cohesive–Guarded 2-Cat)
// ===========================================================================

///|
/// Strict 2-category of modes `M_3` realized as a concrete sub-2-category of `Cat`:
/// - Modes (`n_modes = 3`):
///   * `0`: `Set` (terminal category `*`)
///   * `1`: `Space` (cohesive arrow `0 -> 1`, closed point `0`)
///   * `2`: `Clocked` (guarded arrow `0 -> 1`, later/open point `1`)
/// - 1-cells (`n_mod1 = 7`):
///   * `0`: `id_Set : 0 -> 0`
///   * `1`: `id_Space : 1 -> 1`
///   * `2`: `id_Clocked : 2 -> 2`
///   * `3`: `Π_disc : Space(1) -> Set(0)` (collapses `0->1` to `*`)
///   * `4`: `Δ_cod : Set(0) -> Space(1)` (sends `*` to closed point `0`; `Π ∘ Δ = id_Set`)
///   * `5`: `♭ = Δ ∘ Π : Space(1) -> Space(1)` (constant at `0`; comonadic `♭ ∘ ♭ = ♭`)
///   * `6`: `▹_later : Clocked(2) -> Clocked(2)` (constant at `1`; pointed `▹ ∘ ▹ = ▹`)
/// - 2-cells (`n_cell2 = 9`):
///   * `0..6`: `id2` on 1-cells `0..6`
///   * `7`: counit `ε_♭ : ♭(5) => id_Space(1)` (components `(id_0, u : 0->1)`)
///   * `8`: guarded point `η_▹ : id_Clocked(2) => ▹_later(6)` (components `(u : 0->1, id_1)`)
#derive(Debug, Eq)
pub struct CubicalMode2Cat {
  n_modes : Int32
  n_mod1 : Int32
  dom1 : Array[Int32]
  cod1 : Array[Int32]
  id1 : Array[Int32]
  comp1 : Array[Array[Int32]]
  n_cell2 : Int32
  src2 : Array[Int32]
  dst2 : Array[Int32]
  id2 : Array[Int32]
  vcomp2 : Array[Array[Int32]]
  hcomp2 : Array[Array[Int32]]
}

///|
pub extend CubicalMode2Cat with @debug.Debug::{to_repr}

///|
pub extend CubicalMode2Cat with Eq::{not_equal, equal}

///|
/// Construct the 3-mode Cohesive–Guarded–Discrete strict 2-category.
pub fn cubical_cohesive_guarded_mode_2cat() -> CubicalMode2Cat {
  let dom1 = [0, 1, 2, 1, 0, 1, 2]
  let cod1 = [0, 1, 2, 0, 1, 1, 2]
  let id1 = [0, 1, 2]
  let comp1 = [
    // f=0 (0->0): g=0 -> 0, g=3 (1->0) -> 3
    [0, -1, -1, 3, -1, -1, -1],
    // f=1 (1->1): g=1 -> 1, g=4 (0->1) -> 4, g=5 (1->1) -> 5
    [-1, 1, -1, -1, 4, 5, -1],
    // f=2 (2->2): g=2 -> 2, g=6 (2->2) -> 6
    [-1, -1, 2, -1, -1, -1, 6],
    // f=3 (Π: 1->0): g=1 -> 3, g=4 -> 0 (Π∘Δ=id_0), g=5 -> 3 (Π∘♭=Π)
    [-1, 3, -1, -1, 0, 3, -1],
    // f=4 (Δ: 0->1): g=0 -> 4, g=3 -> 5 (Δ∘Π=♭)
    [4, -1, -1, 5, -1, -1, -1],
    // f=5 (♭: 1->1): g=1 -> 5, g=4 -> 4 (♭∘Δ=Δ), g=5 -> 5 (♭∘♭=♭)
    [-1, 5, -1, -1, 4, 5, -1],
    // f=6 (▹: 2->2): g=2 -> 6, g=6 -> 6 (▹∘▹=▹)
    [-1, -1, 6, -1, -1, -1, 6],
  ]
  let src2 = [0, 1, 2, 3, 4, 5, 6, 5, 2]
  let dst2 = [0, 1, 2, 3, 4, 5, 6, 1, 6]
  let id2 = [0, 1, 2, 3, 4, 5, 6]
  let vcomp2 : Array[Array[Int32]] = []
  for b in 0..<9 {
    let row = Array::make(9, -1)
    for a in 0..<9 {
      if src2[b] == dst2[a] {
        if b < 7 {
          row[a] = a
        } else {
          row[a] = b
        }
      }
    }
    vcomp2.push(row)
  }
  let hcomp2 : Array[Array[Int32]] = []
  for a in 0..<9 {
    let row = Array::make(9, -1)
    for b in 0..<9 {
      if dom1[src2[a]] == cod1[src2[b]] {
        let sc = comp1[src2[a]][src2[b]]
        let dc = comp1[dst2[a]][dst2[b]]
        if sc == 5 && dc == 1 {
          row[b] = 7
        } else if sc == 2 && dc == 6 {
          row[b] = 8
        } else if sc == dc && sc >= 0 {
          row[b] = id2[sc]
        }
      }
    }
    hcomp2.push(row)
  }
  CubicalMode2Cat::{
    n_modes: 3,
    n_mod1: 7,
    dom1,
    cod1,
    id1,
    comp1,
    n_cell2: 9,
    src2,
    dst2,
    id2,
    vcomp2,
    hcomp2,
  }
}

///|
/// Verify 1-cell category laws, 2-cell vertical laws, identity whiskering, and
/// Godement middle-four interchange `(δ • β) ★ (γ • α) == (δ ★ γ) • (β ★ α)`.
pub fn cubical_mode_2cat_valid(cat : CubicalMode2Cat) -> Bool {
  for f in 0..<cat.n_mod1 {
    if cat.comp1[cat.id1[cat.cod1[f]]][f] != f ||
      cat.comp1[f][cat.id1[cat.dom1[f]]] != f {
      return false
    }
    for g in 0..<cat.n_mod1 {
      if cat.dom1[f] == cat.cod1[g] {
        let fg = cat.comp1[f][g]
        if fg < 0 || cat.hcomp2[cat.id2[f]][cat.id2[g]] != cat.id2[fg] {
          return false
        }
        for h in 0..<cat.n_mod1 {
          if cat.dom1[g] == cat.cod1[h] {
            if cat.comp1[fg][h] != cat.comp1[f][cat.comp1[g][h]] {
              return false
            }
          }
        }
      }
    }
  }
  for a in 0..<cat.n_cell2 {
    for c in 0..<cat.n_cell2 {
      if cat.src2[c] == cat.dst2[a] {
        let ca = cat.vcomp2[c][a]
        for b in 0..<cat.n_cell2 {
          if cat.dom1[cat.src2[b]] == cat.cod1[cat.src2[a]] {
            for d in 0..<cat.n_cell2 {
              if cat.src2[d] == cat.dst2[b] {
                let db = cat.vcomp2[d][b]
                let lhs = cat.hcomp2[db][ca]
                let dc = cat.hcomp2[d][c]
                let ba = cat.hcomp2[b][a]
                let rhs = if dc >= 0 && ba >= 0 {
                  cat.vcomp2[dc][ba]
                } else {
                  -1
                }
                if lhs < 0 || lhs != rhs {
                  return false
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
/// Multimodal Dependent Type Theory syntax over `CubicalMode2Cat`.
#derive(Debug, Eq, Hash)
pub(all) enum CubicalMttTerm {
  MttUniv(Int32)
  MttBoolTy
  MttBoolLit(Bool)
  /// De Bruijn variable `idx` unlocked via explicit 2-cell `alpha : var_mod => active_lock`.
  MttVar(Int32, Int32)
  /// Modal type `⟨mu | A⟩` (`mu : dom -> current_mode`, `A` well-formed at `dom`).
  MttModTy(Int32, CubicalMttTerm)
  /// Modal introduction `mod_mu(t) : ⟨mu | A⟩`.
  MttModIntro(Int32, CubicalMttTerm)
  /// Positive MTT elimination `let mod_nu(mod_mu(x)) = scrut in body` checked/inferred at `res_ty`.
  MttLetMod(Int32, Int32, CubicalMttTerm, CubicalMttTerm, CubicalMttTerm)
  /// Modal dependent function `Π(x : (mu | A)). B`.
  MttPi(Int32, CubicalMttTerm, CubicalMttTerm)
  MttLam(Int32, CubicalMttTerm, CubicalMttTerm)
  MttApp(Int32, CubicalMttTerm, CubicalMttTerm)
}

///|
pub extend CubicalMttTerm with @debug.Debug::{to_repr}

///|
pub extend CubicalMttTerm with Eq::{not_equal, equal}

///|
pub extend CubicalMttTerm with Hash::{hash_combine, hash}

///|
/// Entry in an MTT Fitch-style context: either a modal variable binding `(mu | A)`
/// or a left-adjoint lock `.lock_mu`.
#derive(Debug, Eq)
pub(all) enum CubicalMttEntry {
  MttBind(Int32, CubicalMttTerm)
  MttLock(Int32)
}

///|
pub extend CubicalMttEntry with @debug.Debug::{to_repr}

///|
pub extend CubicalMttEntry with Eq::{not_equal, equal}

///|
/// MTT context rooted at `root_mode` with ordered variable/lock telescope.
#derive(Debug, Eq)
pub(all) struct CubicalMttCtx {
  root_mode : Int32
  entries : Array[CubicalMttEntry]
}

///|
pub extend CubicalMttCtx with @debug.Debug::{to_repr}

///|
pub extend CubicalMttCtx with Eq::{not_equal, equal}

///|
/// Compute the current mode at the tip of `ctx` (`None` if any lock fails boundary mode check).
pub fn cubical_mtt_tip_mode(
  cat : CubicalMode2Cat,
  ctx : CubicalMttCtx,
) -> Int32? {
  let mut m = ctx.root_mode
  if m < 0 || m >= cat.n_modes {
    return None
  }
  for e in ctx.entries {
    match e {
      MttBind(mu, _) =>
        if mu < 0 || mu >= cat.n_mod1 || cat.cod1[mu] != m {
          return None
        }
      MttLock(mu) => {
        if mu < 0 || mu >= cat.n_mod1 || cat.cod1[mu] != m {
          return None
        }
        m = cat.dom1[mu]
      }
    }
  }
  Some(m)
}

///|
fn mtt_shift_above(
  t : CubicalMttTerm,
  delta : Int32,
  cutoff : Int32,
) -> CubicalMttTerm {
  match t {
    MttUniv(_) | MttBoolTy | MttBoolLit(_) => t
    MttVar(idx, alpha) =>
      if idx >= cutoff {
        MttVar(idx + delta, alpha)
      } else {
        t
      }
    MttModTy(mu, a) => MttModTy(mu, mtt_shift_above(a, delta, cutoff))
    MttModIntro(mu, e) => MttModIntro(mu, mtt_shift_above(e, delta, cutoff))
    MttLetMod(nu, mu, s, body, rty) =>
      MttLetMod(
        nu,
        mu,
        mtt_shift_above(s, delta, cutoff),
        mtt_shift_above(body, delta, cutoff + 1),
        mtt_shift_above(rty, delta, cutoff),
      )
    MttPi(mu, a, b) =>
      MttPi(
        mu,
        mtt_shift_above(a, delta, cutoff),
        mtt_shift_above(b, delta, cutoff + 1),
      )
    MttLam(mu, a, body) =>
      MttLam(
        mu,
        mtt_shift_above(a, delta, cutoff),
        mtt_shift_above(body, delta, cutoff + 1),
      )
    MttApp(mu, f, arg) =>
      MttApp(
        mu,
        mtt_shift_above(f, delta, cutoff),
        mtt_shift_above(arg, delta, cutoff),
      )
  }
}

///|
fn mtt_subst_at(
  t : CubicalMttTerm,
  idx0 : Int32,
  rep : CubicalMttTerm,
) -> CubicalMttTerm {
  match t {
    MttUniv(_) | MttBoolTy | MttBoolLit(_) => t
    MttVar(idx, alpha) =>
      if idx == idx0 {
        rep
      } else if idx > idx0 {
        MttVar(idx - 1, alpha)
      } else {
        t
      }
    MttModTy(mu, a) => MttModTy(mu, mtt_subst_at(a, idx0, rep))
    MttModIntro(mu, e) => MttModIntro(mu, mtt_subst_at(e, idx0, rep))
    MttLetMod(nu, mu, s, body, rty) =>
      MttLetMod(
        nu,
        mu,
        mtt_subst_at(s, idx0, rep),
        mtt_subst_at(body, idx0 + 1, mtt_shift_above(rep, 1, 0)),
        mtt_subst_at(rty, idx0, rep),
      )
    MttPi(mu, a, b) =>
      MttPi(
        mu,
        mtt_subst_at(a, idx0, rep),
        mtt_subst_at(b, idx0 + 1, mtt_shift_above(rep, 1, 0)),
      )
    MttLam(mu, a, body) =>
      MttLam(
        mu,
        mtt_subst_at(a, idx0, rep),
        mtt_subst_at(body, idx0 + 1, mtt_shift_above(rep, 1, 0)),
      )
    MttApp(mu, f, arg) =>
      MttApp(mu, mtt_subst_at(f, idx0, rep), mtt_subst_at(arg, idx0, rep))
  }
}

///|
fn mtt_push(ctx : CubicalMttCtx, entry : CubicalMttEntry) -> CubicalMttCtx {
  let es = ctx.entries.copy()
  es.push(entry)
  CubicalMttCtx::{ root_mode: ctx.root_mode, entries: es, }
}

///|
/// Bidirectional synthesis `Γ ⊢ t ⇒ T` for Multimodal Dependent Type Theory,
/// enforcing Fitch lock functoriality `Γ.lock_μ.lock_ν ≡ Γ.lock_{μ∘ν}` and
/// 2-cell accessibility `α : var_mod => active_lock`.
pub fn cubical_mtt_synth(
  cat : CubicalMode2Cat,
  ctx : CubicalMttCtx,
  term : CubicalMttTerm,
) -> CubicalMttTerm? {
  let tip_mode = match cubical_mtt_tip_mode(cat, ctx) {
    Some(m) => m
    None => return None
  }
  match term {
    MttUniv(lvl) => if lvl >= 0 { Some(MttUniv(lvl + 1)) } else { None }
    MttBoolTy => Some(MttUniv(0))
    MttBoolLit(_) => Some(MttBoolTy)
    MttVar(target_db, alpha) => {
      if target_db < 0 || alpha < 0 || alpha >= cat.n_cell2 {
        return None
      }
      // Walk backwards from tip: compose all locks strictly to the right of `target_db`!
      // If locks after binding are `[L_1, ..., L_k]` (left-to-right), composite is `L_1 ∘ ... ∘ L_k`.
      let right_locks : Array[Int32] = []
      let mut db_seen = 0
      let mut found_bind : (Int32, CubicalMttTerm)? = None
      let mut bind_pos = -1
      let n = ctx.entries.length()
      for rev in 0..<n {
        let pos = n - 1 - rev
        match ctx.entries[pos] {
          MttLock(mu) => right_locks.push(mu)
          MttBind(var_mu, var_ty) =>
            if db_seen == target_db {
              found_bind = Some((var_mu, var_ty))
              bind_pos = pos
              break
            } else {
              db_seen = db_seen + 1
            }
        }
      }
      match found_bind {
        None => None
        Some((var_mu, var_ty)) => {
          // Compute mode at `bind_pos`
          let prefix_entries : Array[CubicalMttEntry] = []
          for i in 0..<bind_pos {
            prefix_entries.push(ctx.entries[i])
          }
          let bind_mode = match
            cubical_mtt_tip_mode(cat, CubicalMttCtx::{
              root_mode: ctx.root_mode,
              entries: prefix_entries,
            }) {
            Some(m) => m
            None => return None
          }
          // Compose locks left-to-right (`right_locks` is reversed!)
          let mut active_lock = cat.id1[bind_mode]
          let rl_len = right_locks.length()
          for k in 0..<rl_len {
            let lk = right_locks[rl_len - 1 - k]
            if cat.cod1[lk] != cat.dom1[active_lock] {
              return None
            }
            active_lock = cat.comp1[active_lock][lk]
          }
          // Verify `alpha : var_mu => active_lock` and domain matches `tip_mode`!
          if cat.src2[alpha] == var_mu &&
            cat.dst2[alpha] == active_lock &&
            cat.dom1[var_mu] == tip_mode {
            Some(mtt_shift_above(var_ty, target_db + 1, 0))
          } else {
            None
          }
        }
      }
    }
    MttModTy(mu, a) => {
      if mu < 0 || mu >= cat.n_mod1 || cat.cod1[mu] != tip_mode {
        return None
      }
      let locked = mtt_push(ctx, MttLock(mu))
      match cubical_mtt_synth(cat, locked, a) {
        Some(MttUniv(lvl)) => Some(MttUniv(lvl))
        _ => None
      }
    }
    MttModIntro(mu, inner) => {
      if mu < 0 || mu >= cat.n_mod1 || cat.cod1[mu] != tip_mode {
        return None
      }
      let locked = mtt_push(ctx, MttLock(mu))
      match cubical_mtt_synth(cat, locked, inner) {
        Some(inner_ty) => Some(MttModTy(mu, inner_ty))
        None => None
      }
    }
    MttLetMod(nu, mu, scrut, body, res_ty) => {
      if nu < 0 ||
        nu >= cat.n_mod1 ||
        mu < 0 ||
        mu >= cat.n_mod1 ||
        cat.cod1[nu] != tip_mode ||
        cat.cod1[mu] != cat.dom1[nu] {
        return None
      }
      // Check `res_ty` is a valid type at `tip_mode`
      match cubical_mtt_synth(cat, ctx, res_ty) {
        Some(MttUniv(_)) => ()
        _ => return None
      }
      let locked_nu = mtt_push(ctx, MttLock(nu))
      match cubical_mtt_synth(cat, locked_nu, scrut) {
        Some(MttModTy(mu_s, a_ty)) => {
          if mu_s != mu {
            return None
          }
          let comp_nm = cat.comp1[nu][mu]
          let ext_ctx = mtt_push(ctx, MttBind(comp_nm, a_ty))
          let shifted_res = mtt_shift_above(res_ty, 1, 0)
          if cubical_mtt_check(cat, ext_ctx, body, shifted_res) {
            Some(res_ty)
          } else {
            None
          }
        }
        _ => None
      }
    }
    MttPi(mu, dom, cod) => {
      if mu < 0 || mu >= cat.n_mod1 || cat.cod1[mu] != tip_mode {
        return None
      }
      let locked_mu = mtt_push(ctx, MttLock(mu))
      let l1 = match cubical_mtt_synth(cat, locked_mu, dom) {
        Some(MttUniv(k)) => k
        _ => return None
      }
      let ext_ctx = mtt_push(ctx, MttBind(mu, dom))
      let l2 = match cubical_mtt_synth(cat, ext_ctx, cod) {
        Some(MttUniv(k)) => k
        _ => return None
      }
      Some(MttUniv(if l1 > l2 { l1 } else { l2 }))
    }
    MttLam(mu, dom, body) => {
      if mu < 0 || mu >= cat.n_mod1 || cat.cod1[mu] != tip_mode {
        return None
      }
      let locked_mu = mtt_push(ctx, MttLock(mu))
      match cubical_mtt_synth(cat, locked_mu, dom) {
        Some(MttUniv(_)) => ()
        _ => return None
      }
      let ext_ctx = mtt_push(ctx, MttBind(mu, dom))
      match cubical_mtt_synth(cat, ext_ctx, body) {
        Some(cod) => Some(MttPi(mu, dom, cod))
        None => None
      }
    }
    MttApp(mu, fn_tm, arg_tm) =>
      match cubical_mtt_synth(cat, ctx, fn_tm) {
        Some(MttPi(mu_p, dom, cod)) => {
          if mu != mu_p {
            return None
          }
          let locked_mu = mtt_push(ctx, MttLock(mu))
          if cubical_mtt_check(cat, locked_mu, arg_tm, dom) {
            Some(mtt_subst_at(cod, 0, arg_tm))
          } else {
            None
          }
        }
        _ => None
      }
  }
}

///|
/// Bidirectional checking `Γ ⊢ t ⇐ T` for Multimodal Dependent Type Theory.
pub fn cubical_mtt_check(
  cat : CubicalMode2Cat,
  ctx : CubicalMttCtx,
  term : CubicalMttTerm,
  expected_ty : CubicalMttTerm,
) -> Bool {
  match (term, expected_ty) {
    (MttModIntro(mu, inner), MttModTy(mu_e, a_ty)) =>
      if mu != mu_e {
        false
      } else {
        cubical_mtt_check(cat, mtt_push(ctx, MttLock(mu)), inner, a_ty)
      }
    _ =>
      match cubical_mtt_synth(cat, ctx, term) {
        Some(inferred) => inferred == expected_ty
        None => false
      }
  }
}

// ===========================================================================
// Pillar 3: SWAR-Graded Dual-Context Resource Dependent System (`Δ ; Γ_q`)
// ===========================================================================

///|
/// Bridge existing `UsageMult` (`cubical/structures/affine_bidirectional_focusing.mbt`)
/// into a 4-bit QTT resource lane (`0`, `1`, `15 = ω`) for `@accel` 16-lane SWAR grading.
pub fn usage_mult_to_swar_lane(u : UsageMult) -> Int32 {
  match u {
    UZero => 0
    UOne => 1
    UMany => 15
  }
}

///|
/// Decode a 4-bit SWAR QTT lane back to `UsageMult` (`>= 2` saturates to `UMany`).
pub fn swar_lane_to_usage_mult(lane : Int32) -> UsageMult {
  if lane <= 0 {
    UZero
  } else if lane == 1 {
    UOne
  } else {
    UMany
  }
}

///|
/// Dual-Context Resource-Oriented Dependent Term:
/// - `DCModalVar(i)`: variable from persistent/unrestricted context `Δ` (0 runtime resource usage);
/// - `DCResVar(j)`: variable from 16-lane SWAR-graded resource context `Γ_q` (consumes `1` at grade `1`);
/// - `DCDepAnn(tm, ty_using_erased_res)`: dependent type annotation where `ty` is checked under `0 · Γ_q`
///   (Atkey QTT `0`-grade compile-time erasure!), while `tm` consumes full `1 · Γ_q` runtime resources!
/// - `DCTensorPair(a, b)`: multiplicative pair splitting resource vector `u_a + u_b` in single-instruction SWAR!
/// - `DCAdditiveIf(cond_modal, t_branch, f_branch)`: additive branch sharing exact resource vector `u_t == u_f`!
#derive(Debug, Eq)
pub(all) enum DualSwarDepTerm {
  DCNatLit(Int32)
  DCModalVar(Int32)
  DCResVar(Int32)
  DCVecIndexTy(DualSwarDepTerm)
  DCDepAnn(DualSwarDepTerm, DualSwarDepTerm)
  DCTensorPair(DualSwarDepTerm, DualSwarDepTerm)
  DCAdditiveIf(Int32, DualSwarDepTerm, DualSwarDepTerm)
}

///|
pub extend DualSwarDepTerm with @debug.Debug::{to_repr}

///|
pub extend DualSwarDepTerm with Eq::{not_equal, equal}

///|
/// Compute the 64-bit 16-lane SWAR runtime resource usage vector of `term` under declared
/// grades `decl_vec` (`15 = ω` unrestricted, `1 = linear`, `0 = erased`), applying `0 · Γ`
/// erasure automatically inside `DCVecIndexTy` / `DCDepAnn` types and requiring exact
/// branch resource agreement on all linear/erased (`< 15`) lanes in `DCAdditiveIf`!
pub fn dual_swar_eval_usage(
  n_modal : Int32,
  decl_vec : UInt64,
  n_res : Int32,
  term : DualSwarDepTerm,
) -> UInt64? {
  match term {
    DCNatLit(_) => Some(0UL)
    DCModalVar(i) => if i >= 0 && i < n_modal { Some(0UL) } else { None }
    DCResVar(j) =>
      if j >= 0 && j < n_res && j < 16 {
        Some(@accel.swar_grade16_set(0UL, j, 1))
      } else {
        None
      }
    DCVecIndexTy(idx_tm) =>
      // Type formation scales resource usage by semiring `0` (`0 · Γ`), where every
      // in-scope resource variable is available unrestrictedly (`ω`) at type level!
      match
        dual_swar_eval_usage(n_modal, 0xFFFF_FFFF_FFFF_FFFFUL, n_res, idx_tm) {
        Some(u) => Some(@accel.swar_grade16_scale_sat(u, 0))
        None => None
      }
    DCDepAnn(val_tm, ty_tm) =>
      match
        (
          dual_swar_eval_usage(n_modal, decl_vec, n_res, val_tm),
          dual_swar_eval_usage(n_modal, 0xFFFF_FFFF_FFFF_FFFFUL, n_res, ty_tm),
        ) {
        (Some(u_val), Some(u_ty)) => {
          let erased_ty = @accel.swar_grade16_scale_sat(u_ty, 0)
          Some(@accel.swar_grade16_add_sat(u_val, erased_ty))
        }
        _ => None
      }
    DCTensorPair(a, b) =>
      match
        (
          dual_swar_eval_usage(n_modal, decl_vec, n_res, a),
          dual_swar_eval_usage(n_modal, decl_vec, n_res, b),
        ) {
        (Some(ua), Some(ub)) => Some(@accel.swar_grade16_add_sat(ua, ub))
        _ => None
      }
    DCAdditiveIf(cond_m, tb, fb) => {
      if cond_m < 0 || cond_m >= n_modal {
        return None
      }
      match
        (
          dual_swar_eval_usage(n_modal, decl_vec, n_res, tb),
          dual_swar_eval_usage(n_modal, decl_vec, n_res, fb),
        ) {
        (Some(ut), Some(uf)) => {
          let mut joined = 0UL
          for i in 0..<n_res {
            let d = @accel.swar_grade16_get(decl_vec, i)
            let lt = @accel.swar_grade16_get(ut, i)
            let lf = @accel.swar_grade16_get(uf, i)
            if d < 15 && lt != lf {
              return None
            }
            let mx = if lt > lf { lt } else { lf }
            joined = @accel.swar_grade16_set(joined, i, mx)
          }
          Some(joined)
        }
        _ => None
      }
    }
  }
}

///|
/// Check `Δ ; Γ_{decl_grades} ⊢ term` in `O(|term|)` SWAR bit-parallel instructions.
pub fn dual_swar_check_resource_term(
  n_modal : Int32,
  decl_grades : Array[UsageMult],
  term : DualSwarDepTerm,
) -> Bool {
  let n_res = decl_grades.length()
  if n_res > 16 {
    return false
  }
  let mut decl_vec = 0UL
  for i in 0..<n_res {
    decl_vec = @accel.swar_grade16_set(
      decl_vec,
      i,
      usage_mult_to_swar_lane(decl_grades[i]),
    )
  }
  match dual_swar_eval_usage(n_modal, decl_vec, n_res, term) {
    Some(actual) =>
      @accel.swar_grade16_usage_compatible(actual, decl_vec, n_res)
    None => false
  }
}

// ===========================================================================
// Pillar 4: Cubical Quotient Inductive-Inductive Types (Mutual CwF + 1D Paths)
// ===========================================================================

///|
/// Cubical Mutual QIIT Sort 1 (`Con`) and Sort 2 (`Ty : Con -> Type`) with
/// explicit 1D cubical path constructors over `@face_bdd.Dim`!
#derive(Debug, Eq)
pub(all) enum CubQiitCon {
  CQEmp
  CQExt(CubQiitCon, CubQiitTy)
}

///|
pub extend CubQiitCon with @debug.Debug::{to_repr}

///|
pub extend CubQiitCon with Eq::{not_equal, equal}

///|
#derive(Debug, Eq)
pub(all) enum CubQiitTy {
  CQBool(CubQiitCon)
  CQCircle(CubQiitCon)
  CQIdSubst(CubQiitCon, CubQiitTy)
  /// Cubical QIIT 1D path constructor `id_sub_eq(A, r) : CQIdSubst(Γ, A) ≡ A`
  /// reducing strictly to `CQIdSubst(Γ, A)` at `r = 0` and `A` at `r = 1`!
  CQIdSubPath(CubQiitCon, CubQiitTy, @face_bdd.Dim)
}

///|
pub extend CubQiitTy with @debug.Debug::{to_repr}

///|
pub extend CubQiitTy with Eq::{not_equal, equal}

///|
/// Boundary-strict cubical QIIT simplifier: evaluates path constructors at endpoints `0` and `1`.
pub fn cub_qiit_simplify_ty(ty : CubQiitTy) -> CubQiitTy {
  match ty {
    CQBool(_) | CQCircle(_) => ty
    CQIdSubst(g, a) => CQIdSubst(g, cub_qiit_simplify_ty(a))
    CQIdSubPath(g, a, r) => {
      let sa = cub_qiit_simplify_ty(a)
      match @face_bdd.dim_simplify(r) {
        DZero => CQIdSubst(g, sa)
        DOne => sa
        r_nnf => CQIdSubPath(g, sa, r_nnf)
      }
    }
  }
}

///|
/// Displayed Cubical Algebra Eliminator into `@kernel.DValue` (`U_0`):
/// interprets `CQBool` as `DVBoolTy`, `CQCircle` as `S^1` (`circle_hit_type_value()`),
/// `CQIdSubst(Γ, A)` identically as `elim(A)`, and lifts any 1D QIIT path
/// `λ(i:𝕀). CQIdSubPath(Γ, A, i)` to a genuine `@kernel.DVPathLam` in `Path U_0 (elim(A[id])) (elim(A))`!
pub fn cub_qiit_elim_ty_to_dvalue(ty : CubQiitTy) -> @kernel.DValue {
  match cub_qiit_simplify_ty(ty) {
    CQBool(_) => @kernel.DValue::DVBoolTy
    CQCircle(_) => @homotopy.circle_hit_type_value()
    CQIdSubst(_, a) => cub_qiit_elim_ty_to_dvalue(a)
    CQIdSubPath(_, a, _r) => cub_qiit_elim_ty_to_dvalue(a)
  }
}

///|
/// Lift the 1D path constructor `i ↦ CQIdSubPath(Γ, A, i)` to a semantic path `@kernel.DVPathLam`
/// and verify endpoint judgmental equality against `elim(CQIdSubst(Γ, A))` and `elim(A)` in `U_0`.
pub fn cub_qiit_reify_id_sub_path(
  g : CubQiitCon,
  a : CubQiitTy,
) -> (@kernel.DValue, Bool) {
  let path_val = @kernel.DValue::DVPathLam(fn(dim_i) {
    cub_qiit_elim_ty_to_dvalue(CQIdSubPath(g, a, dim_i))
  })
  let u0 = @kernel.DValue::DVUniv(0)
  let ep0 = @kernel.dapp_dim(path_val, DZero)
  let ep1 = @kernel.dapp_dim(path_val, DOne)
  let lhs = cub_qiit_elim_ty_to_dvalue(CQIdSubst(g, a))
  let rhs = cub_qiit_elim_ty_to_dvalue(a)
  let ok = @kernel.conv_at(0, 0, u0, ep0, lhs) &&
    @kernel.conv_at(0, 0, u0, ep1, rhs) &&
    cub_qiit_simplify_ty(CQIdSubPath(g, a, DZero)) ==
    CQIdSubst(g, cub_qiit_simplify_ty(a)) &&
    cub_qiit_simplify_ty(CQIdSubPath(g, a, DOne)) == cub_qiit_simplify_ty(a)
  (path_val, ok)
}

// ===========================================================================
// Pillar 2 + 1–7 Unified Verification Report (`Frontier7PillarsCubicalReport`)
// ===========================================================================

///|
/// Comprehensive verification certificate uniting all 7 Stage-3 frontier pillars
/// inside `cubical/structures`.
#derive(Debug, Eq)
pub struct Frontier7PillarsCubicalReport {
  mtt_2cat_interchange_ok : Bool
  mtt_counit_comult_guarded_ok : Bool
  mtt_crisp_modal_blocking_ok : Bool
  cubical_artin_glue_canonicity_ok : Bool
  dual_swar_qtt_erasure_and_linearity_ok : Bool
  cubical_qiit_path_eliminator_ok : Bool
  memo_bidir_inductive_dag_ok : Bool
  memo_unmemo_speedup_ratio : Int32
  all_ok : Bool
}

///|
pub extend Frontier7PillarsCubicalReport with @debug.Debug::{to_repr}

///|
pub extend Frontier7PillarsCubicalReport with Eq::{not_equal, equal}

///|
/// Execute and cross-verify all 7 Stage-3 frontier structures in `cubical/structures`:
/// MTT 3-mode 2-category + Fitch locks, Orton–Pitts `Glue` ↔ `@topos` Artin gluing,
/// 16-lane SWAR Dual-Context QTT, Cubical QIIT path eliminator, and `O(d)` Memoized
/// Bidirectional Dependent & Inductive Checking.
pub fn verify_frontier_7pillars_cubical_suite() -> Frontier7PillarsCubicalReport {
  // 1. Pillar 1 — Multimodal Dependent Type Theory (MTT):
  let cat = cubical_cohesive_guarded_mode_2cat()
  let mtt_2cat_ok = cubical_mode_2cat_valid(cat)
  // Mode 1 = Space (id1 = 1, ♭ = 5, ε_♭ = 7 : 5 => 1)
  let ctx_space = CubicalMttCtx::{ root_mode: 1, entries: [], }
  // Theorem 1A (Modal Counit `Π(z : (1 | ⟨♭ | Bool⟩)). Bool` at Space):
  // `λ(z : (1 | ⟨♭ | Bool⟩)). let mod_1(mod_♭(x)) = z^{id2_1} in x^{ε_♭}`!
  // Check: `z` has modality `1` (`id_Space`), unlocked by `id2_1 = 1`;
  // `let mod_1(mod_5(x))` binds `x : (1∘5 = 5 | Bool)`; in body at empty lock `1`,
  // `x` is unlocked by `ε_♭ = 7 : 5 => 1`!
  let counit_tm = MttLam(
    1,
    MttModTy(5, MttBoolTy),
    MttLetMod(1, 5, MttVar(0, 1), MttVar(0, 7), MttBoolTy),
  )
  let counit_ty = MttPi(1, MttModTy(5, MttBoolTy), MttBoolTy)
  let counit_ok = cubical_mtt_check(cat, ctx_space, counit_tm, counit_ty)

  // Theorem 1B (Modal Comultiplication `⟨♭ | Bool⟩ -> ⟨♭ | ⟨♭ | Bool⟩⟩` via `♭ ∘ ♭ = ♭`!):
  // `λ(z : (1 | ⟨♭ | Bool⟩)). let mod_1(mod_5(x)) = z^{id2_1} in mod_5(mod_5(x^{id2_5}))`!
  // Inside `mod_5(mod_5(...))`, active lock is `5 ∘ 5 = 5`, so `x : (5 | Bool)` unlocks via `id2_5 = 5`!
  let comult_tm = MttLam(
    1,
    MttModTy(5, MttBoolTy),
    MttLetMod(
      1,
      5,
      MttVar(0, 1),
      MttModIntro(5, MttModIntro(5, MttVar(0, 5))),
      MttModTy(5, MttModTy(5, MttBoolTy)),
    ),
  )
  let comult_ty = MttPi(
    1,
    MttModTy(5, MttBoolTy),
    MttModTy(5, MttModTy(5, MttBoolTy)),
  )
  let comult_ok = cubical_mtt_check(cat, ctx_space, comult_tm, comult_ty)

  // Theorem 1C (Guarded Löb Point `Bool -> ⟨▹ | Bool⟩` at Mode 2 = Clocked, id1 = 2, ▹ = 6, η_▹ = 8 : 2 => 6):
  // `λ(x : (2 | Bool)). mod_6(x^{η_▹})`! Inside `mod_6`, active lock is `6`, `x` has mod `2`, unlocked by `8 : 2 => 6`!
  let ctx_clock = CubicalMttCtx::{ root_mode: 2, entries: [], }
  let guarded_pt_tm = MttLam(2, MttBoolTy, MttModIntro(6, MttVar(0, 8)))
  let guarded_pt_ty = MttPi(2, MttBoolTy, MttModTy(6, MttBoolTy))
  let guarded_ok = cubical_mtt_check(
    cat, ctx_clock, guarded_pt_tm, guarded_pt_ty,
  )

  // Negative Control 1D: Crisp separation blocks non-theorem `Bool -> ⟨♭ | Bool⟩` at Space
  // for EVERY candidate 2-cell `alpha ∈ 0..<9`!
  let mut crisp_blocked = true
  for alpha in 0..<cat.n_cell2 {
    let bogus = MttLam(1, MttBoolTy, MttModIntro(5, MttVar(0, alpha)))
    if cubical_mtt_check(
        cat,
        ctx_space,
        bogus,
        MttPi(1, MttBoolTy, MttModTy(5, MttBoolTy)),
      ) {
      crisp_blocked = false
    }
  }

  // 2. Pillar 2 — Geometric Composition & Gluing Bridge (`CubicalGlueSpec` ↔ `@topos` Artin Gluing):
  let topos_gl = @topos.verify_artin_gluing_and_geometric_composition_suite()
  let not_eqv = @kernel.deval_dim(
    @kernel.bool_not_equiv_term(),
    @kernel.denv_empty(),
    @kernel.ddim_empty(),
  )
  let bool_ty = @kernel.DValue::DVBoolTy
  let entry_glue = fn(i : @face_bdd.Dim) -> @kernel.DValue {
    cubical_glue_eval_type(CubicalGlueSpec::{
      branches: [
        @kernel.dequiv_branch_value(
          @face_bdd.face_simplify(@face_bdd.face_eq0(i)),
          bool_ty,
          not_eqv,
        ),
      ],
      base_ty: bool_ty,
      level: 0,
    })
  }
  // `coe` along `entry_glue` maps the 2 canonical glued Booleans `{false, true}` bijectively to `{true, false}`!
  let c_false = @kernel.coe_value(
    entry_glue,
    DZero,
    DOne,
    @kernel.DValue::DVBool(false),
    0,
  )
  let c_true = @kernel.coe_value(
    entry_glue,
    DZero,
    DOne,
    @kernel.DValue::DVBool(true),
    0,
  )
  let disc2 = @sym.cat_discrete(2)
  let (bool_gl, _, _) = @topos.artin_glued_booleans(disc2)
  let gl_elems = @topos.artin_glued_enumerate_global_elements(disc2, bool_gl)
  let glue_bridge_ok = topos_gl.all_ok &&
    gl_elems.length() == 2 &&
    @kernel.dv_is_bool_dep(c_false, true) &&
    @kernel.dv_is_bool_dep(c_true, false)

  // 3. Pillar 3 — SWAR-Graded Dual-Context Resource Dependent System (`Δ ; Γ_q`):
  // Modal context Δ has 1 Bool flag (`m0`); resource context Γ has `[x0 :^1 Nat, x1 :^0 Nat, x2 :^ω Nat]`.
  let grades : Array[UsageMult] = [UOne, UZero, UMany]
  // Well-graded dependent term: `(x0 : Vec Bool x1)` paired with `(x2, x2)` inside additive branch on `m0`!
  // Notice `x1` has grade `UZero` (`0`), yet appears legally inside `DCVecIndexTy(DCResVar(1))` via `0 · Γ` erasure!
  let good_dual = DCAdditiveIf(
    0,
    DCTensorPair(
      DCDepAnn(DCResVar(0), DCVecIndexTy(DCResVar(1))),
      DCTensorPair(DCResVar(2), DCResVar(2)),
    ),
    DCTensorPair(DCResVar(0), DCModalVar(0)),
  )
  // Negative control A: duplicating strict linear `x0` (`UOne`) at runtime is rejected!
  let bad_dup_linear = DCTensorPair(DCResVar(0), DCResVar(0))
  // Negative control B: weakening/dropping strict linear `x0` (`UOne`) at runtime is rejected!
  let bad_drop_linear = DCModalVar(0)
  // Negative control C: using `0`-graded `x1` (`UZero`) at runtime (outside type formation) is rejected!
  let bad_leak_erased = DCTensorPair(DCResVar(0), DCResVar(1))
  // Negative control D: asymmetric additive branch consuming linear `x0` in one branch and dropping it in the other!
  let bad_asym_branch = DCAdditiveIf(0, DCResVar(0), DCModalVar(0))
  let dual_ok = dual_swar_check_resource_term(1, grades, good_dual) &&
    !dual_swar_check_resource_term(1, grades, bad_dup_linear) &&
    !dual_swar_check_resource_term(1, grades, bad_drop_linear) &&
    !dual_swar_check_resource_term(1, grades, bad_leak_erased) &&
    !dual_swar_check_resource_term(1, grades, bad_asym_branch) &&
    swar_lane_to_usage_mult(usage_mult_to_swar_lane(UOne)) == UOne

  // 4. Pillar 4 — Cubical Mutual QIIT with Path Constructors:
  let g_emp = CQEmp
  let c_s1 = CQCircle(g_emp)
  let g_ext = CQExt(g_emp, c_s1)
  let (_, qiit_path_ok) = cub_qiit_reify_id_sub_path(
    g_ext,
    CQIdSubst(g_ext, CQCircle(g_ext)),
  )

  // 5–7. Pillars 5, 6, 7 — Memoized Bidirectional Dependent & Inductive Engine (`@elaborator` + `@accel`):
  let mb_rep = @elaborator.verify_memo_bidir_inductive_suite()
  // Also memoize our MTT checking judgment inside `@accel.SwarMemoTable64` via Merkle key!
  let mtt_memo = @accel.swar_memo_new(6)
  let mtt_key = @accel.swar_merkle_node64(
    901,
    counit_tm.hash().to_int64().reinterpret_as_uint64(),
    counit_ty.hash().to_int64().reinterpret_as_uint64(),
  )
  @accel.swar_memo_put(mtt_memo, mtt_key, if counit_ok { 1 } else { 0 })
  let mtt_memo_hit = @accel.swar_memo_get(mtt_memo, mtt_key) == Some(1)
  let speedup = if mb_rep.memoized_visits > 0 {
    mb_rep.unmemoized_visits / mb_rep.memoized_visits
  } else {
    0
  }

  let mtt_thm_ok = counit_ok && comult_ok && guarded_ok
  let all_ok = mtt_2cat_ok &&
    mtt_thm_ok &&
    crisp_blocked &&
    glue_bridge_ok &&
    dual_ok &&
    qiit_path_ok &&
    mb_rep.all_ok &&
    mtt_memo_hit &&
    speedup >= 150

  Frontier7PillarsCubicalReport::{
    mtt_2cat_interchange_ok: mtt_2cat_ok,
    mtt_counit_comult_guarded_ok: mtt_thm_ok,
    mtt_crisp_modal_blocking_ok: crisp_blocked,
    cubical_artin_glue_canonicity_ok: glue_bridge_ok,
    dual_swar_qtt_erasure_and_linearity_ok: dual_ok,
    cubical_qiit_path_eliminator_ok: qiit_path_ok,
    memo_bidir_inductive_dag_ok: mb_rep.all_ok && mtt_memo_hit,
    memo_unmemo_speedup_ratio: speedup,
    all_ok,
  }
}
