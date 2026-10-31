# cubical-hermitian

A governed **Double-V (`V₁ = @gcd` → `X = @condensed` → `V₂ = @bridge`) &
X-Overlap Six-Federation Architecture + Grand Unification** MoonBit platform
for structural algorithms, geometry, condensed mathematics, and logic
(`6 federations + unification apex`, `29 packages`, `47 components`):

1. **Federation 1 — `cubical`: Cubical paths, univalence, exact spectra & BFT persistence**
   (the root package, `algebra/`, `hostfs/`, and `cmd/main`):
   a dependent cubical kernel, Kan operations, computational univalence,
   exact BigInt algebra, Liouville transcendence & Berkowitz–CRT certificates,
   Ed25519 BFT quorum persistence, and Hermitian spectral certificates.
2. **Federation 2 — `symlib`: Finite symmetry and categorical Kan extensions**
   (`symlib/`, `cmd/symdemo`, `cmd/symbench`): graph canonical forms, automorphism
   groups, finite categories, presheaves, G-sets and executable certificates.
3. **Federation 3 — `semiring`: Semiring path algebra and tropical geometry**
   (`semiring/*`, `cmd/semiringreport`): semiring traits, generic
   dense/CSR matrices and star closure, weighted directed graphs, tropical
   geometry, regular-language and idempotent-semiring normal forms, factor
   graphs and measured performance infrastructure.
4. **Federation 4 — `topos`: Grothendieck & elementary toposes** (`topos/`): sites, sieves,
   two-step Plus sheafification, Cartesian closedness, subobject classifiers,
   Lawvere–Tierney & co-Heyting open/closed subtopos nuclei (`J_o(U) ∧ J_c(U) = J_triv`,
   `J_o(U) ∨ J_c(U) = J_⊥`), geometric & essential morphisms (`Lan_{u^{op}} ⊣ u* ⊣ Ran_{u^{op}}`
   via `@sym.lan` and `@sym.ran`), Grothendieck–Verdier dense subsite Comparison
   Lemma, Diaconescu points & internal `G`-torsor sheaves (`T × G ≅ T × T`),
   local/connected/atomic/compact-coherent invariants, Kripke–Joyal semantics,
   Joyal–Reyes geometric normal forms, classifying toposes,
   category-of-elements categorification, groupoid stacks, general non-abelian
   `G`-torsor Čech 1-cohomology (`H^1(U, G)`), Roos/Čech sheaf cohomology,
   Alexander–Whitney simplicial cup-product DG-algebras (`H^1 ⌣ H^1 -> H^2`,
   separating `T^2` from `S^1 ∨ S^1 ∨ S^2`) and order-independent simplicial
   nerve homotopy types (`∂Δ^d` spheres, `RP^2`, `T^2`).
5. **Federation 5 — `scheme`: Algebraic schemes and motives** (`scheme/`): Buchberger reduced Gröbner
   bases, elimination/saturation/radical ideals, Zariski partition-of-unity
   gluing, reduced schemes (`X_red ↪ X`), Kähler differentials (`Ω^1_{B/A}`),
   general `i`-th Fitting ideals (`Fitt_i(M)`) & Eisenbud Theorem 20.8 pure-dimensional
   smoothness (rejecting mixed-dimension schemes alongside singularities),
   Tjurina singularity numbers (`τ = 0, 1, 2, 3`), unramified/smooth/étale morphism
   criteria, general `n`-dimensional projective gluing (`P^n`, projective subschemes,
   `A^n`, `A^2 \ {0}`, doubled-origin line) and morphisms, affine morphisms,
   diagonal separatedness, `Q[[t]] ⊂ Q((t))` DVR valuative properness,
   Macaulay–Taylor symbolic Hilbert polynomials `P_X(t) ∈ Q[t]` (degree & arithmetic
   genus in arbitrary codimension, including the twisted cubic in `P^3`), Rees blow-up
   `Bl_{(0,0)}(A^2)` curve desingularization, rational equivalence (`CH^1`, Bézout),
   Grothendieck–Serre dualizing complexes (`ω_{P^1} = O(-2)[1]`, `ω_{P^2} = O(-3)[2]`,
   and plane-curve `ω_C = O_C(d-3)[1]`), functor of points (`h_X(R)` including
   `F_p[ε]` tangents and `F_3 ⊂ F_9` Galois–Frobenius descent) and 6-variable
   multi-projective Gröbner Chow correspondences (`h(P^1) ≅ 1 ⊕ L`).
6. **Federation 6 — `condensed`: Universal Elimination-GCD (`V₁`) & Condensed X-Overlap Pivot (`X`)**
   (`gcd/`, `condensed/`): `F_p` RREF, `ℤ`-matrix Hermite/Smith Normal Forms & six-fold
   universal GCD duality (`UgcdSixFoldCertificate`), the condensed category `CondCategory`
   and canonical elimination category `CanonElimCategory`, 4 condensed higher structures
   (`CondAnima`, `CondSolidModule`, `CondSpectralSheaf`, `CondAnalyticStack`),
   Steenrod–Adams cohomology (`Ext_A^{2,3}(F_2, F_2) = 0`, `2η = 0`), SNF conservation-law
   ledgers, and the 4-conjecture laboratory (`[Conj-1]` .. `[Conj-4]`).
7. **Unification Apex — `unification`: Complete `K_6` cross-federation bridges,
   Double-V & X-Overlap synthesis** (`bridge/`, `cmd/showcase`):
   all $\binom{6}{2} = 15$ pairwise cross-federation bridges (`K5-01` .. `K5-10`, `K6-11` .. `K6-15`),
   the X-Overlap Chiasmus theorem (`[T-X-Chiasmus]`), the Double-V architecture report,
   the Five-Federation Pentagon Quadratic Galois–Étale Double-Cover Unification
   Theorem, cross-pillar logical theory translations, the 18-entry Fine-Grained
   Geometry–Logic Correspondence Atlas (`ATLAS-01` .. `ATLAS-18`), and the
   `S^1` / `P^1` / `P^2` / Galois / motivic synthesis.

Cross-federation constructions live only in `bridge/`; no federation may import
`bridge/`, and `tools/arch_check.py` enforces strict inter-federation import
allowlists.  See the [architecture guide](ARCHITECTURE.md), the
[finite-symmetry document](docs/symlib.md), the
[semiring documents](docs/semiring/README.md), and the
[bridge guide](docs/BRIDGE.md).

## Verified federation snapshot

The governed manifest (`architecture.json` v2) partitions **6 federations +
1 unification apex, 29 packages, 47 components** across 7 layers (`0..6`),
and the generated bilingual appendices (`SPEC-APPENDIX.md` and
`SPEC-APPENDIX.en.md`) audit every public symbol across all packages
(`spec_registry`: **140** entries).  Fast local gates:
`moon check --deny-warn --target wasm-gc`,
`moon test --release --target wasm-gc` (**19/19** consolidated tests across all federations),
`moon run --release cmd/main --target wasm-gc` (**129/129** theorems),
`moon run --release cmd/showcase --target wasm-gc` (**6/6 federations, 15/15 `K_6` pairwise bridges,
43/43 grand-unification certificates**, including `[T-X-Chiasmus]`, Double-V synthesis, and all **18/18** Geometry–Logic
Atlas entries), `python3 tools/arch_check.py`, and
`moon info --target wasm-gc && python3 tools/audit_spec.py --check`.  The native
semiring report (`moon run cmd/semiringreport --target native`) is a
separate slow gate, not part of the fast gate.

## Cubical pillar in detail

Hermitian idempotent projectors and orthogonal eigenspace decomposition;
cubical interval, faces and systems modulo quotient with pruning; Kan comp
by retraction; NbE in three layers (beta-pi, typed eta-long, and dependent
Pi/Sigma with a cumulative universe hierarchy); persistent shared
environments, call-by-need semantic thunks and memoized dimension lines /
type families; a cubical AST with PathP, data types (Bool/Nat/List),
Circle/Torus HITs and coe/comp/hcomp/hfill term constructors whose Kan
operations reduce by type (Pi, Sigma, PathP, Glue, data, HITs and
universes); DSystem composition systems with checked compatibility for raw systems,
first-match normal forms and multi-branch Glue partial values; first-class
AST equivalences, ua and GlueEquiv; checked substitution-respecting type
lines and a schema registry with elaboration caches; generic
strictly-positive inductive-family and arbitrary finite-dimensional HIT
schema generators (nested container functors, mutual families, Tarski induction-recursion,
quotient cells and universe schemes); HOAS on normal forms; symbolic
decision (interned DAG ROBDDs with budgets/DPLL, wirings); exact rational
and algebraic-extension algebra with generalized eigenspaces and Jordan
decompositions; certified exact shadows of the numeric projector/cube
layer; general Glue comp; spheres by iterated suspension (including S3);
certified Hermitian Jacobi iteration by symbolic interval inclusion;
complete BigInt factorization/root isolation/splitting fields and radical
denesting; first-class level-polymorphic, mutual, non-uniform-nested and
simultaneous induction-recursion declarations; a higher-order-unification
bidirectional elaborator extending Miller patterns to repeated-variable,
constructor-spine and distinct flex-flex cases; parameterized modules with
abstract declarations, separate interface compilation/linking and incremental
caching; spherical degree representatives and a classical Hopf linking check; a general
semantic lemIso construction for contractible fibers and automatic
adjointification; internal IntegerS and pi3 quotient presentations with a
canonical spherical-loop representative calculus (not an arbitrary-element
pi3 classification); transactional bounded Huet search; a stable versioned
compiled-module byte/hex codec; and cost controls comprising BDD sifting and
growing apply caches, watched-literal DPLL fallback, sparse/common-denominator
BigInt Karatsuba polynomial multiplication and binary powers; cross-family
nested positive functors (`DFunctorFamily`) with a simultaneous-IR-to-decode
compiler; Face-valued agreement regions with exact DSystem repair;
generic-point lemIso validation and point-valued Circle/Torus composition;
byte-persistent schema registries (`CHREGBIN`) with global DTerm
hash-consing; adaptive mod-p factor-pattern pruning and biquadratic-field
radical denesting; host-opaque cube open-box filling (semantic and exact
polynomial variants), provably optimal BDD variable orders for small n and
CDCL clause learning; the schema circle's universal cover with
encode-by-substitution and decode-by-integer-elimination; exact Jacobi
eigenvalue-cluster separation; deeper HOU search with iterative deepening;
interleaved import/local module items with v1-to-v2 binary migration and an
in-process compiled-module store; same-spec non-uniform recursion
(`DFunctorSelfFamily`) with trusted or lambda-verified positivity
declarations for opaque operators; simultaneous-IR compilation onto base
eliminators in a predicative fragment; relevant-dimension structural
DSystem agreement and repair by verified supplementation; term-level Bool
case-split conversion and path-valued Circle/Torus composition keeping
winding data; an artifact repository over an abstract byte store with
shared DAG module/registry codecs (v3/v2) and version negotiation;
irreducibility certificates, pure-cubic and triquadratic radical towers
and cluster-aware interval Jacobi iteration; subset-DP exact BDD orders
(n<=12), CDCL with LBD clause deletion and replayable RUP proofs;
stratified extensionality checks for host cube functions; single
substitutions accumulating circle windings; connection-rotation unit-law
3-cells on sphere representatives and exact rational Hopf identities; and
a three-state principal-unifier semantics for Miller patterns; a least-fixed-point decision for SelfFamily parameter positivity and term-level functor maps for nested foreign simultaneous-IR hypotheses; relevant-dimension descent and maximum-clique DSystem completion; difference-guided Bool case splitting and face-verified square-valued Circle/Torus composition; a persistent `CHDAGBIN` form sharing the live DTerm intern DAG; jointly checked mod-p degree-pattern irreducibility certificates and multiquadratic fields with up to four independent generators; exact BDD orders to n<=16, chronological DRUP proofs with clause deletions, deep-connection Tier-D host-cube probes and adaptive Jacobi with exact Sturm fallback; inverse, associativity and symmetry-of-composite loop 3-cells with normalization of closed sphere-loop expressions to canonical degree words; a solver for whole residual HOU constraint sets; an append-only `CHARTCHN` artifact-manifest integrity chain with externally anchored recovery; Phase-14 joint `Σ`-tuple simultaneous IR, unfolded positivity witnesses, Hensel polynomial factorization certificates, rank-6 multiquadratic + real algebraic radicals, Hermitian block-deflated Jacobi certificates, `Ω²` Eckmann–Hilton 3-cells, Mac Lane pentagon 4-cells, Brunerie's internal univalent Hopf fibration & integer invariant, transactional cross-constraint HOU backtracking/enumeration, and `CHMODENV`/`CHARTAUT` authenticated CAS + incremental sync; and Phase-15 symmetry-orbit + connected-support decomposed exact ROBDD ordering (up to 28-variable multi-component formulas), linear-time indexed LRAT proof checking + DRAT→LRAT elaboration + `CHLRATBN` v1 binary codec, strength-4 `ℙ¹(𝔽₈)` covering arrays + 5-color PHF + `CheckedDCube` & cubical Yoneda naturality/faithfulness audit, general open-variable bidirectional bijectivity (`DVEquiv`), set truncation `‖A‖₀`, the complete internal circle fundamental-group isomorphism `π₁(S¹) = ‖Ω¹(S¹)‖₀ ≃ ℤ`, parameterized suspension `SuspS(A)` with the pointed loop-suspension adjunction `(ΣA →* B) ≃ (A →* ΩB)`, and the 0-connected Freudenthal suspension theorem `‖Ω¹(Susp(A))‖₀ ≃ 1` (`π₁(S²) ≃ 1`, `π₁(S³) ≃ 1`) with circle wedge connectivity; and Phase-16 cumulative large-universe & Dybjer–Setzer open multi-decoder simultaneous IR with anti-circular container positivity certificates, DSATUR chromatic max-clique pruning & `0 ~ 1` glued Circle/Torus open-box composition, FIPS 180-4 SHA-256/512 + RFC 8032 Pure-Ed25519 `CHARTSIG` sealing + `CHWALJRN` crash-consistent WAL journaling, exact rational LLL lattice reduction + Van Hoeij trace-lattice factor recombination + `Q̄ ⊂ ℂ` Rouché-disk algebraic closure, open-variable fibration loop equivalences + open Hopf–Freudenthal retraction `∂_Hopf(σ_{S²}(p)) ≡ p` + `π₂(S²)` split section + Stasheff's 5D `K₅` coherence 5-cell, and Huet delayed flex-flex constraint graphs + pull-based lazy unifier streams + DAG interface-hash relinking + LCA-based 3-way repository merge; host-level
cubical algorithms (KanBox transport/fillers, path algebra, funext and subst);
computational univalence (decidable finite-universe wiring univalence and
checked ua/pathToEquiv, ua-beta, and round-trip certificates for the dependent
AST); a federated multi-package architecture governed by
`architecture.json`; and audited bilingual per-symbol
canonical-form/categorification specifications.

Run: `moon check --deny-warn --target wasm-gc`, `moon test --release --target wasm-gc` (19 consolidated tests across all 6 federations + apex),
`moon run --release cmd/main --target wasm-gc` (expected: 129/129 cubical & Phase 21 registry checks),
`moon run --release cmd/showcase --target wasm-gc` (expected: 43/43 grand-unification certificates across `K_6` `15/15` bridges), `python3 tools/arch_check.py`, and
`moon info --target wasm-gc && python3 tools/audit_spec.py --check` (the generated
appendices are the authoritative public-symbol count).  Documentation:
[English guide](GUIDE.en.md), [English specification](SPEC.en.md),
[中文指南](GUIDE.md), [中文規格](SPEC.md), [architecture](ARCHITECTURE.md),
[finite symmetry](docs/symlib.md), [semiring lab](docs/semiring/README.md), and [bridge guide](docs/BRIDGE.md).
