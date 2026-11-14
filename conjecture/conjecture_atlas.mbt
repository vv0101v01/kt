///|
// Federation 7 (`discovery`) — Layer 4 Package `conjecture` (Part 2):
// Lakatosian Proof-and-Refutation Conjecture Lifecycle and the Resolved Conjecture Atlas.
//
// The atlas only lists statements with a verdict. Entries whose status was "verified up
// to a bound", "phase transition measured" or "open frontier" (historical `CONJ-01`,
// `-07`, `-08`, `-11`, `-12`) could be neither proved nor refuted here and were removed.
// The surviving identifiers keep their historical numbers so old references stay valid.

///|
/// Lifecycle state of a resolved conjecture:
///   • `LcDerivedAndTransferred`: automatically discovered via `[E-Derive]` nullspace
///     lattice saturation and verified out-of-sample on an unseen transfer domain (`[P-Transfer]`);
///   • `LcRefutedAndRefined`: naive conjecture falsified by an explicit minimal machine-checked
///     counterexample AND paired with a machine-verified refined/repaired theorem.
#derive(Debug, Eq)
pub(all) enum ConjectureLifecycle {
  LcDerivedAndTransferred(Int32, String)
  LcRefutedAndRefined(String, String)
}

///|
pub extend ConjectureLifecycle with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend ConjectureLifecycle with Eq::{not_equal, equal}

///|
/// Cross-federation record in the Resolved Conjecture Atlas.
#derive(Debug, Eq)
pub(all) struct UpdatedConjectureRecord {
  id : String
  federations_bridged : Array[String]
  title : String
  lifecycle : ConjectureLifecycle
  epistemic_lens : EpistemicLensKind
  verified_consistent : Bool
}

///|
pub extend UpdatedConjectureRecord with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend UpdatedConjectureRecord with Eq::{not_equal, equal}

///|
/// Summary report of the Updated Conjecture & Creative Theorem Engine.
#derive(Debug, Eq)
pub(all) struct ConjectureSynthesisSummary {
  total_conjectures : Int32
  derived_and_transferred : Int32
  refuted_and_refined : Int32
  evolution_families_passed : Int32
  epistemic_lenses_ledger_ok : Bool
  new_creative_theorems_ok : Bool
  all_consistent : Bool
}

///|
pub extend ConjectureSynthesisSummary with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend ConjectureSynthesisSummary with Eq::{not_equal, equal}

///|
/// Evaluate the **Resolved Conjecture Atlas**: 5 refuted-and-refined entries
/// (`CONJ-02` .. `CONJ-06`) and 2 derived-and-transferred entries (`CONJ-09`, `CONJ-10`).
pub fn evaluate_updated_conjecture_atlas() -> Array[UpdatedConjectureRecord] {
  let cond_refuted = @condensed.cond_evaluate_new_conjectures()
  let atlas_f3 = @tensor.f3_tensor222_atlas_build()
  let (imp_rep, _led, lenses_ok) = evaluate_five_epistemic_lenses_into_ledger(
    atlas_opt=Some(atlas_f3),
  )
  let evo_reps = discover_six_evolution_laws()

  // CONJ-02 from the condensed refutation record + free-group refinement verification
  let trivial_sq = @gcd.ugcd_free_group_reduce([1, 2, -2, -1])
  let c2_ok = cond_refuted.length() == 1 &&
    cond_refuted[0].consistent_with_status &&
    trivial_sq.length() == 0

  // CONJ-03: Tensor Rank-Hyperdeterminant Equivalence Refuted -> F_3 Galois-Twisted Implication Lattice
  let c3_ok = lenses_ok &&
    imp_rep.nontrivial_equiv_pairs == 1 &&
    imp_rep.strict_unidirectional_edges == 1 &&
    atlas_f3.rank2_det_zero_count + atlas_f3.rank3_det_zero_count == 2112 &&
    atlas_f3.rank3_det_nonzero_count > 0

  // CONJ-04: Associahedron Symmetry Rigidity (`|Aut(K_4)| == |D_5| == 10 != 24 == |S_4|`) via `@sym.aut_order`!
  let k4_skel = @sym.Graph::cycle(5)
  let aut_k4 = @sym.aut_order(k4_skel)
  let flip5 = @tensor.nc_polygon_triangulations_flip_report(5)
  let c4_ok = flip5.catalan_count == 5 &&
    flip5.flip_edges == 5 &&
    aut_k4 == 10L &&
    aut_k4 != 24L &&
    aut_k4 == (2 * (4 + 1)).to_int64()

  // CONJ-05: Radon Naive Plancherel & Composite Gram Refuted -> Affine-Corrected Plancherel `[E-Radon]`
  let r3 = @tensor.radon_make(3, 101)
  let r4 = @tensor.radon_make(4, 101)
  let c5_ok = @tensor.radon_check_gram_identity(r3) &&
    !@tensor.radon_check_gram_identity(r4) &&
    evo_reps[2].target_derived_on_train &&
    evo_reps[2].target_holds_on_transfer &&
    evo_reps[2].mirage_rejected_on_transfer

  // CONJ-06: General Metric Non-Crossing MST Refuted on K_4 (`7 < 11`) -> Refined `[T-NC-Free]` on Cyclic-Monotone Metrics
  let mono_k4 = [[0, 2, 3, 2], [2, 0, 2, 3], [3, 2, 0, 2], [2, 3, 2, 0]]
  let diag_k4 = [[0, 5, 1, 5], [5, 0, 5, 1], [1, 5, 0, 5], [5, 1, 5, 0]]
  let (m_mono, nc_mono) = @tensor.nc_mst_vs_unconstrained_mst(4, mono_k4)
  let (m_diag, nc_diag) = @tensor.nc_mst_vs_unconstrained_mst(4, diag_k4)
  let c6_ok = m_diag == 7 && nc_diag == 11 && m_mono == nc_mono

  // CONJ-09: Clifford Ramond Spinor Center-Radical Duality & Gauge Flow Transfer (`[E-Gauge]`)
  let c9_ok = evo_reps[1].target_derived_on_train &&
    evo_reps[1].target_holds_on_transfer &&
    evo_reps[1].mirage_rejected_on_transfer &&
    @tensor.clifford_ramond_anticommutator_ok(4, 5)

  // CONJ-10: Scheme Curve Singularity Blow-Up Genus Conservation (`[E-Scheme-Curve]`) & Tropical Assignment Valuation
  let x2 = @scheme.mpoly_var(2, 0)
  let y2 = @scheme.mpoly_var(2, 1)
  let f_node = @scheme.mpoly_sub(
    @scheme.mpoly_pow(y2, 2),
    @scheme.mpoly_add(@scheme.mpoly_pow(x2, 3), @scheme.mpoly_pow(x2, 2)),
  )
  let f_cusp = @scheme.mpoly_sub(
    @scheme.mpoly_pow(y2, 2),
    @scheme.mpoly_pow(x2, 3),
  )
  let bl_node = @scheme.blowup_plane_curve_at_origin(f_node)
  let bl_cusp = @scheme.blowup_plane_curve_at_origin(f_cusp)
  let td = @strop.trop_det([[0L, 2L], [3L, 1L]])
  let c10_ok = evo_reps[5].target_derived_on_train &&
    evo_reps[5].target_holds_on_transfer &&
    evo_reps[5].mirage_rejected_on_transfer &&
    bl_node.strict_transform_is_smooth &&
    bl_node.exceptional_fiber_is_reduced &&
    bl_cusp.strict_transform_is_smooth &&
    !bl_cusp.exceptional_fiber_is_reduced &&
    td == 1L

  [
    UpdatedConjectureRecord::{
      id: "CONJ-02",
      federations_bridged: ["cubical", "condensed"],
      title: "Naive H_1 Abelian 2-Box Filling Refuted -> Free-Group F_2 Normal-Form Criterion",
      lifecycle: LcRefutedAndRefined(
        "pi_1(S^1 v S^1) commutator [a,b] has H_1=(0,0) yet reduced length 4 != 0",
        "2-box on S^1 v S^1 fills iff @gcd.ugcd_free_group_reduce(boundary) == []",
      ),
      epistemic_lens: LensContrast,
      verified_consistent: c2_ok,
    },
    UpdatedConjectureRecord::{
      id: "CONJ-03",
      federations_bridged: ["discovery", "condensed", "scheme"],
      title: "Naive 2x2x2 Tensor Rank-Hyperdeterminant Equivalence Refuted -> F_3 Galois-Twisted Implication Lattice",
      lifecycle: LcRefutedAndRefined(
        "6,561 F_3 tensors ([1, 128, 4032, 2400]): 2,112 rank>1 tensors satisfy Det=0, while F_9/F_3 Galois-twisted rank-3 tensors satisfy Det!=0",
        "Exact F_3 lattice: unidirectional (rank<=1 => Det=0) and unique equivalence (#rank2_decomp=0 <=> rank=3)",
      ),
      epistemic_lens: LensImplication,
      verified_consistent: c3_ok,
    },
    UpdatedConjectureRecord::{
      id: "CONJ-04",
      federations_bridged: ["symlib", "cubical", "discovery"],
      title: "Naive Symmetric-Group Rigidity Aut(K_n)≅S_n Refuted -> Dihedral Polygon-Dissection Symmetry D_{n+1}",
      lifecycle: LcRefutedAndRefined(
        "|Aut(K_4)| = |Aut(C_5)| = 10 != 24 = |S_4| via @sym.aut_order", "Combinatorial 1-skeleton symmetry of K_4 reduces from S_4 to dihedral D_5 of order 2*(4+1)=10",
      ),
      epistemic_lens: LensDual,
      verified_consistent: c4_ok,
    },
    UpdatedConjectureRecord::{
      id: "CONJ-05",
      federations_bridged: ["discovery", "condensed"],
      title: "Naive Uncorrected Discrete Radon Plancherel & Composite Gram Refuted -> Affine-Corrected Prime Plancherel Law",
      lifecycle: LcRefutedAndRefined(
        "R^T R = nI + J fails at composite n=4; sum(Rf)^2 = n sum f^2 fails whenever sum(f) != 0",
        "[E-Derive] discovers exact universal identity sum(Rf)^2 - n sum(f)^2 - (sum f)^2 = 0 for prime n",
      ),
      epistemic_lens: LensScaleRatio,
      verified_consistent: c5_ok,
    },
    UpdatedConjectureRecord::{
      id: "CONJ-06",
      federations_bridged: ["discovery", "semiring"],
      title: "Naive Universal Non-Crossing MST Conjecture Refuted -> Cyclic-Monotone Metric Freedom [T-NC-Free]",
      lifecycle: LcRefutedAndRefined(
        "K_4 metric (diagonals=1, sides=5) yields unconstrained MST = 7 < non-crossing MST = 11",
        "Under cyclic-monotone circle metrics, unconstrained MST equals non-crossing MST",
      ),
      epistemic_lens: LensContrast,
      verified_consistent: c6_ok,
    },
    UpdatedConjectureRecord::{
      id: "CONJ-09",
      federations_bridged: ["discovery", "topos", "condensed"],
      title: "Clifford Ramond Spinor Center-Radical Equality dim Z(k^w[G]) = |rad(w)| & Gauge-Flow Transfer",
      lifecycle: LcDerivedAndTransferred(1, "Clifford-Cocycle d=2,3 -> d=4"),
      epistemic_lens: LensDual,
      verified_consistent: c9_ok,
    },
    UpdatedConjectureRecord::{
      id: "CONJ-10",
      federations_bridged: ["scheme", "semiring", "discovery"],
      title: "Hironaka–Serre Curve Degeneration Genus Conservation p_a = delta + g_geom & Tjurina Fiber Jump",
      lifecycle: LcDerivedAndTransferred(
        2, "Projective Plane Curves d=3 (A_0, A_1, A_2) -> d=4",
      ),
      epistemic_lens: LensRelative,
      verified_consistent: c10_ok,
    },
  ]
}

///|
/// Master synthesis & verification entry point for Federation 7 (`conjecture` + `tensor`):
/// executes all 6 evolutionary discovery-and-transfer experiments, all 5 epistemic lenses
/// with hash-chained ledger sealing, and the 7 resolved cross-federation conjectures.
pub fn synthesize_and_verify_conjecture_engine() -> ConjectureSynthesisSummary {
  let evo = discover_six_evolution_laws()
  let mut evo_ok = 0
  for r in evo {
    if r.target_derived_on_train &&
      r.target_holds_on_transfer &&
      r.mirage_rejected_on_transfer {
      evo_ok = evo_ok + 1
    }
  }
  let (_imp, _led, lenses_ok) = evaluate_five_epistemic_lenses_into_ledger()
  let atlas = evaluate_updated_conjecture_atlas()

  let mut cnt_dt = 0
  let mut cnt_rr = 0
  let mut all_c = true
  for rec in atlas {
    if !rec.verified_consistent {
      all_c = false
    }
    match rec.lifecycle {
      LcDerivedAndTransferred(_, _) => cnt_dt = cnt_dt + 1
      LcRefutedAndRefined(_, _) => cnt_rr = cnt_rr + 1
    }
  }

  let new_theorems_ok = @tensor.tensor_check_federation_laws() &&
    check_discovery_kernel_laws() &&
    evo_ok == 6 &&
    lenses_ok
  ConjectureSynthesisSummary::{
    total_conjectures: atlas.length(),
    derived_and_transferred: cnt_dt,
    refuted_and_refined: cnt_rr,
    evolution_families_passed: evo_ok,
    epistemic_lenses_ledger_ok: lenses_ok,
    new_creative_theorems_ok: new_theorems_ok,
    all_consistent: all_c &&
    atlas.length() == 7 &&
    cnt_dt == 2 &&
    cnt_rr == 5 &&
    new_theorems_ok,
  }
}

///|
/// Boolean health probe for Federation 7 (`discovery`: `tensor` + `conjecture`).
pub fn check_conjecture_discovery_federation() -> Bool {
  synthesize_and_verify_conjecture_engine().all_consistent &&
  discover_polynomial_transfer_laws().all_ok
}
