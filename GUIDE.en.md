# cubical-hermitian Guide (MoonBit implementation)

Language: **English** · [中文](GUIDE.md) · [中文規格](SPEC.md) · [Specification](SPEC.en.md) · [Architecture](ARCHITECTURE.md)

A set of intertwined concepts made into an **executable, testable computational model**:

- Idempotent Hermitian matrices (orthogonal projectors) and their orthogonal eigenspace decompositions;
- Kan-fibration **pruning** onto eigenspaces with a projector `P` as retraction (fill in the ambient space, then `P ∘ fill`);
- Cubical intervals, face formulas and system (partial element) **quotients**, commutativity and compatibility;
- Cubical `comp` over the interval (open-box filling formulas);
- **Univalence/unique normal forms for NbE** in the sense of unique representatives, with the typed version giving **η-long normal forms**;
- Definitional computation rules for `coe`, so `coe^refl ≡ id` and `coe^(ua swap) ≡ swap` hold definitionally;
- **Isomorphism** between HOAS and first-order syntax at normal forms;
- Finite-universe **ua**, product-swap `PathP`, Glue soundness, general Glue comp, the `J` law and orthogonality;
- **Symbolic decisions** on the finite side: ROBDDs (faces), BDD region normal forms (systems), and wirings (finite equivalences);
- One cubical AST carrying PathP, Bool/Nat/List, Circle/Torus, and `coe/comp/hcomp/hfill` term constructors, with `hcomp` reduced by type former;
- Dependent semantics evaluated with persistent shared environments, at-most-once thunks and quotation-key caches; composition branches are `DSystem`s that can be merged/sorted by value, and Glue stores complete multi-branch partial type/value systems;
- Finite schema descriptors generating generic inductive families and arbitrary finite-dimensional HITs (including quotient types): checking, dependent elimination, conversion, quotation and Kan comp;
- Exact compatibility decision and first-match normal forms for raw `DSystem`s; first-class `Equiv`/`ua`/`GlueEquiv` in the AST; checked semantic lines and a schema registry;
- Exact rational/algebraic-extension algebra for generalized eigenspaces and Jordan decompositions; hash-consed BDD DAGs with budgets/DPLL and exact certificate shadows of numeric projectors/cubes;
- Cubical algorithms on host values: Kan open boxes, transport fillers, path inversion/concatenation, prefixes/segments, congruence, function extensionality and dependent `subst`;
- Computational univalence: complete decidable wiring univalence in the finite universe, plus AST `ua`/`pathToEquiv`, `uaβ`, round-trip homotopies and a two-dimensional Glue-square certificate;
- A general semantic `lemIso` construction giving fiber paths/contractions and automatic adjointification for quasi-inverses, plus internal `IntegerS`, π₃ quotient types and canonical spherical loop representatives (not a classification theorem for arbitrary π₃ elements);
- Bounded Huet search, a versioned compiled-module byte codec, and BDD sifting/cache growth, watched-literal DPLL and sparse/Karatsuba `QPoly` multiplication;
- `SPEC.md`/`SPEC.en.md` and bilingual appendices give canonical forms and categorifications for every type, operation, specification and structure; across the Double-V six-federation repository the appendices contain **7,100 symbols**, while the specification registry has **140 entries**;
- A Double-V (`V₁=@gcd → X=@condensed → V₂=@bridge`) six-federation package DAG (`cubical`, `symlib`, `semiring`, `topos`, `scheme`, `condensed` plus `bridge`/apps) governed as **29 packages / 47 components** by `architecture.json` and `tools/arch_check.py`.

## Running and acceptance

```text
moon check --deny-warn --target wasm-gc            # whole project, zero warnings
moon test --release --target wasm-gc               # consolidated suite 19/19 across all 6 federations
moon run --release cmd/main --target wasm-gc       # theorem registry, expected 129/129
moon run --release cmd/showcase --target wasm-gc   # 6-federation K_6 grand unification, expected 43/43
python3 tools/arch_check.py                        # layers, unique file ownership, counts
moon info --target wasm-gc && python3 tools/audit_spec.py --check
                                                   # bilingual appendices + spec.mbt audit (7,100 symbols)
```

## Upgrade highlights

### NbE with η (`nbe_eta.mbt`)

Bidirectional type checking/evaluation; `quote_eta` produces η-long forms by type: functions `λx.f x`, products `(fst p, snd p)`, and Unit `()`. Neutral spines carry argument/sibling types, so the normal form of `f:(B→B)→B` is `λg. f (λx. g x)`. Product η makes `swap∘swap ≡ id` definitional at function type. Categorification: objects are `LTy`, morphisms are terms modulo βπη in the free cartesian closed category.

### General Glue comp (`glue_comp.mbt`)

- Finite-universe endpoint algorithm: arbitrary lines `A0≃A1`, `T0≃T1`, endpoint equivalences `e0/e1`, and faces `φ0/φ1`. It requires the naturality square `e₁∘coe_T = coe_A∘e₀` (a morphism of the arrow category, decided symbolically by wirings). Steps: compose `a_raw=coe_A(a0)` in `A`; compose `t1=coe_T(t0)` in `T` (when φ lights up only at 1, reconstruct the partial part by `e₁⁻¹(a_raw)`); correct with `a1=e₁(t1)`. When φ holds at both ends, coherence makes the correction constant; incoherent line data returns `None`.
- Eigensubspace lines: the type line is the image of a varying projector `P(j)`. Two compatible open boxes are filled in the ambient space and pruned pointwise; the cap is repaired by the correction square `(i,k)↦(1−k)a_cap(i)+k·U(1)(t_cap(i))` (an hcomp in `A`) to `U(1)(t_cap)`, without moving side endpoints.

### Symbolic decisions (`bdd.mbt`, `wiring.mbt`, `system_symbolic.mbt`)

- Faces: ROBDDs are canonical forms; `sat/≤/≡/witness` are symbolic.
- Systems: the BDD partition normal form `SystemNF` over effective regions `φᵢ∧¬previous coverage`; quotient equality is normal-form equality.
- Finite equivalences: signed-permutation wiring normal forms; well-formedness is an O(#leaves) permutation check, composition is substitution plus XOR, and equality is structural. Wirings are simultaneously morphisms of a free symmetric monoidal category whose pentagon/triangle/hexagon laws are checked.
- Enumeration remains only in `*_extensional` / `*_oracle` functions and white-box tests for differential checking; it is not on any decision path.

### Dependent NbE: Π, Σ, universes (`nbe_dep.mbt`)

Terms and types share `DTerm`; the bound second components of Π/Σ are closure families in the semantic domain, so dependent substitution such as `snd p : B(fst p)` computes directly. Universes are cumulative, `Typeᵢ : Typeᵢ₊₁`. Conversion and readback are by type, via `conv_at/quote_at` (with η) and `quote_ty`; the categorification is the syntactic model of categories with families (CwF).

### Kan coe/comp for every type (`kan_dep.mbt`)

A type line is `DLine{at,coe,fill}`, with `comp=fill(1)`. Bool/Unit/Universe are constant lines; Π transports backwards in the domain; Σ transports the second component along the path of the first; dependent families are presented as “path in A → DLine”. Simple and finite types embed non-dependently; finite ua gives non-constant lines. Together with subspace and Glue lines, every project type family has a Kan structure.

### Symbolic algebra for eigenvalues/projectors/affine filling (`algebra/symalg.mbt`, `algebra/spectral_symbolic.mbt`)

`SymC/SymMat` are represented exactly by multivariate polynomial normal forms over Q and fractions; equality is polynomial identity. Spectral projectors use the Lagrange formula `Pₖ=qₖ(A)/qₖ(λₖ)`; idempotence, orthogonality, resolution of identity and spectral decomposition are proved by monic division and polynomial identities; `det(XI−A)` gives the characteristic polynomial. Affine filling is determined uniquely in the bilinear class by four corners, with coefficient difference formulas and boundary equations proved as identities in coordinate atoms; projector pruning satisfies `(I−P)(PF)=0`.

### Cubical AST and type-directed hcomp (`nbe_dep.mbt`, `kan_ast.mbt`, `ast_laws.mbt`)

`DTerm` has separate de Bruijn spaces for terms and dimensions: `DLamDim/DAppDim` are `<i> e`/`e @ r`; type lines and tubes are bodies under dimension binders; `DComp/DHComp/DHFill` carry multi-branch `Array[DTubeTerm]` systems, and `DCoe` carries a line and two endpoints. The core dispatch of `comp_value` is:

| Type | Reduction mnemonic |
|---|---|
| Π | Fill the argument backwards along the domain, then compose in the transported codomain |
| Σ | Take the first-component filler, then compose the second component along it |
| PathP | Add left and right endpoint branches to the original tube |
| Universe | `hcompU` produces Glue; Glue then corrects by composing partials/base and an hcomp |
| Bool/Nat/List | Recurse only when constructors align (`succ`; `cons` head/tail) |
| Circle/Torus | All-base systems collapse to base; nontrivial systems remain formal hcomp points |

Bool/Nat/List/Circle/Torus have dependent eliminators; when the scrutinee is a formal composition, elimination composes again inside the motive instead of getting stuck on the eliminator. Circle point forms are `loop@r`; Torus point forms are `square@(i,j)` with opposite edges identified. Filling restricts `comp` to segments `j≤r`; arbitrary-endpoint `coe` is built from fill and segment reparameterization, and `coe(r,r)` is definitionally the identity.

### Semantic systems, persistent environments and laziness (`nbe_dep.mbt`, `semantic_system_laws.mbt`)

`DEnv/DDimEnv` are length-carrying persistent linked lists: context extension conses one node and shares the tail; arrays appear only at public boundaries. Constructor components, function arguments, cases and partial branches are delayed in `DVThunk`; after the first `force_value`, the result is stored, and `lazy_force_count` witnesses at-most-once evaluation. Dimension lines and Π/Σ families are memoized by simplified-dimension and quotation keys.

Semantic composition branches are packaged as `DSystem`. `dsystem_canonical` merges same-body branches by conversion along a type line (unioning their faces) and sorts by quotation; `DPartialValue.partial_normal_form` computes first-match effective regions with BDDs. `DVGlue` stores the complete partial type `DSystem`; multi-branch elements give values facewise as `DPartial/DVPartial`, and checking, conversion, quotation and Glue comp are branchwise.

### Generic inductive and HIT schema generators (`schema.mbt`, `schema_laws.mbt`)

`DInductiveSpec` describes a family by parameter/index telescopes, complete argument types, and decoding of strictly positive functor arguments; structural polarity handles aliases and nested recursion. The generator produces evaluation, bidirectional checking, motive/case types, induction hypotheses, conversion, quotation and comp with argumentwise fillers. Examples include `NatS/BoolS/ListS/VecS/FinS/TreeS/WS`.

`DHitSpec` describes HITs by finite-dimensional cells and face expressions. `hit_cell_value` substitutes endpoint faces recursively; generated case types are points, PathP, or nested PathP squares by dimension, with endpoints supplied by lower-face eliminations. Same-cell comp computes argumentwise; moving dimensions compute when endpoints are decidable and otherwise remain formal neutral compositions. Examples include `CircleS/SegmentS/TorusS`.

### Phase 6 boundary closure

- **Schemas**: mutual induction (Sum-indexed compilation), Tarski induction-recursion via `DDecode`, quotient HITs, universe level schemes, constructor Path constraints and higher cells.
- **Systems/equivalences**: raw `DSystem` compatibility is decided by face-relative conversion; AST `Equiv` carries fwd/bwd/section/retraction, and `ua` and `GlueEquiv` compute in the Kan engine.
- **Trusted boundary**: `DCheckedTypeLine` stores checked bodies; the schema registry caches validation and telescopes.
- **Exact algebra**: `QPoly/QMat`, quadratic and general algebraic extensions, primary projectors, generalized eigenspaces and Jordan decompositions.
- **Scalability/certification**: BDD DAGs (root decision, budgets, best candidate order, DPLL); `QuadC/CertMat/CertPath` replace numeric grids as the source of exact truth.

### Phase 7: container functors, S³, Jacobi, HOU and modules

- `DFunctorContainer(Shape, Positions, index)` writes arbitrary finite dependent polynomial functors as `Σ s, Positions(s)→X`, sharing the generator with mutual induction and `DDecode`.
- `sphere3.mbt` defines `S²/S³` by iterated suspension; meridian endpoints and elimination are generated HIT operations.
- `algebra/Jacobi_interval.mbt` stores recomputable symbolic interval certificates for every complex Jacobi unitary rotation and finishes by clustering Gershgorin discs.
- `hou_elaborator.mbt` drives a bidirectional elaborator with Miller-pattern HOU, solving implicit arguments and Nat motives before translating back to `DTerm`.
- `module_system.mbt` implements parameterized module functors, recursive inlined imports, only/hiding/open/alias/rename, ambiguity rejection and opaque boundaries.

### Phase 8: architecture governance, cubical algorithms and computational univalence

- **Dependency order**: files inside one MoonBit package have no compilation order; dependency direction is what matters. The cubical pillar retains the physical subgraph `cmd/main → root → algebra`, and `architecture.json` divides its root package into 13 logical components from L0 to L9; the same manifest also governs the symlib, semiring, bridge and application packages (25 packages / 34 components in total). `algebra/` is a separate package; `algebra_imports.mbt` centrally manages names imported into root, and `tools/arch_check.py` fails on unassigned files, duplicate ownership or upward edges. File and line counts are computed by the tool rather than maintained by hand (see `ARCHITECTURE.md`).
- **Cubical algorithms** (`cubical_algorithms.mbt`): `KanBox` packages a type line, system and base; `kan_box_fill`, `kan_box_comp` and `kan_box_pathp` expose the filler/cap. There are transports towards 1 and 0, checked-line transport, filler `PathP`, semantic and closed-term `refl/sym/prefix/segment`, transitivity by an explicit hcomp square, `cong/ap`, `funext`, and `subst/substPathP`. The gate is `check_cubical_algorithms`.
- **Computational univalence** (`univalence.mbt`): finite `UPath`s convert exactly both ways to wiring `Equiv`s and transport computes in both directions. For a semantic type line, `pathToEquiv` is formed from coe in both directions and filler round-trip paths; `uaβ` unglues the filler along the Glue line; a retraction homotopy and a Glue square witness `pathToEquiv(ua e)=e` and `ua(pathToEquiv L)=L`, packaged as `univalence_equiv_value`. Checked universe paths and closed-term `DMkEquiv` maps are also verified. The gate is `check_univalence`.

### Phase 9: complete algebra, first-class declarations and separate compilation

- **Exact algebra**: rational coefficients are now `BigInt`; complete factorization over Q, Sturm real-root isolation, completeness-guaranteed complex subdivision, automatic splitting fields, general radical denesting and arbitrary-precision Jacobi endpoints were added.
- **Schemas**: `schema_phase9.mbt` adds first-class level declarations, transparent type-operator positivity, Bush-style non-uniform nested iteration, primitive mutual declarations, simultaneous IR and HIT moving-dimension lifts.
- **Systems and equivalences**: raw `DSystem` conversion is BDD-pruned with agreement regions and restricted repair. Propositional truncation, adjoint types with improved counits, fiber centers/singleton contraction and syntax-preserving primitive `DGlueEquiv` quotation were added.
- **Infrastructure**: raw `DLine` and semantic values support dimension substitution; the schema registry has bucket hash-consing, snapshots/restore/merge and manifests.
- **Certification and BDDs**: `AlgC` certifies projectors and coefficient paths of arbitrary degree over general algebraic extensions. Native DAG BDD operations include evaluation, `BigInt` sat-counts, restriction, quantification and DPLL-backed total face decisions.
- **Spheres**: the suspension functor gives integer degree maps and unit loops; S³ has pole-swapped equivalence data. The classical Hopf fibers have Gauss linking integral of absolute value 1.
- **Front end**: HOU gains repeated-variable, constructor-spine and distinct flex-flex intersection fragments. Modules gain bodyless abstract declarations, `CompiledModule` interface linking, prefix specialization and an incremental cache. At that stage general adjoint triangles and general fiber contraction were still missing; Phase 10 supplies their semantic `lemIso` form. General homotopy-group classifications are still not claimed; see SPEC §4.


### Phase 10: general fibers, internal π₃ presentations, Huet search and stable module bytes

- **Equivalences**: `equivalence_phase10.mbt` implements the three-layer `lemIso` filler construction for arbitrary semantic quasi-inverse components, yielding `equiv_fiber_path_value` and `equiv_contractible_fibers_value`. It extracts a replacement retraction and triangle for `adjointify_equiv_value` from the diagonal fiber contraction. Validation is endpoint conversion on Bool negation and the circle identity; a generic circle midpoint is checked only under endpoint faces, so the documentation does not present this as one closed Π proof checked in every context.
- **Integers and spherical representatives**: the generated inductive `IntegerS` represents each integer uniquely by `zero/posSucc/negSucc`, with mutually inverse semantic `succ/pred` on representatives. `pi3_sphere_type_term(2/3)` is an internal QuotientS of `Ω³` by the propositionally truncated path relation. Suspended generator loops are rebased by `subst` along an explicit `p∙p⁻¹` cancellation square, and the integer degree classifies the resulting `SphereLoopExpr` representative calculus. This is not yet an encode/decode proof that `π₃(S³)≅ℤ` or `π₃(S²)≅ℤ` for arbitrary elements.
- **HOU**: besides deterministic `hou_unify`, transactional `hou_search_unify` first uses the deterministic solver and only then branches over imitation, projections, eta generation, constants and same-head invariant-coordinate pruning. It distinguishes solved/no-unifier/residual/budget-exceeded. A pruning solution is one specific unifier, not an MGU, and full HOU remains undecidable.
- **Module format**: `module_binary.mbt` provides the `CHMODBIN` version-1 byte-array/hex codec, with length and DJB2-xor checksum in its header and fixed-tag encodings of the whole `CompiledModule`. Structural parsing is separate from semantically validating load; tampering, truncation, version and trailing-byte failures have distinct statuses. There is still no filesystem service or version migration.
- **Costs**: BDDs gain bucket-doubling rehash, cache statistics and budgeted sifting through every insertion position; `face_sat_decide` falls back to a two-watched-literal DPLL over Tseitin CNF. `QPoly` uses zero-skipping convolution for sparse work and one common-denominator scaling to BigInt integer polynomials (schoolbook/Karatsuba) for dense work, with binary exponentiation. Worst-case BDD/SAT/algebra costs can still be exponential, and the checks make no general benchmark claim.

### Phase 11: cross-family functors, exact repair, generic points, persistence, biquadratic denesting, CDCL, the circle cover and interleaved modules

- **Schemas**: `DFunctorFamily` lets a nested argument instantiate *another* registered family (slots marked Term/Self by `DFunctorParamArg`), with gathered IH bundles and leaf-occurrence validation; simultaneous IR now compiles to decode specs (`simultaneous_ir_compile_decode`, genuine mutual dependence honestly refused).
- **DSystem**: `face_agreement_face` gives Face-valued agreement keeping both endpoints, and `dsystem_repair_to_base_exact` repairs against it; `DCubeFunction` open boxes turn host-opaque cubes into verifiably fillable objects (`algebra/poly_cube.mbt` is the exact-coordinate version).
- **Equivalences**: `lemIso` is validated at neutral points and both ends of neutral paths; primitive Circle/Torus composition computes on point-valued tubes by De Morgan selection.
- **Persistence**: `CHREGBIN` registry bytes with corruption rejection; genuine global `DTerm` hash-consing (shared subterms, stable ids, checking/normalization unchanged).
- **Algebra**: adaptive mod-p degree-pattern pruning before factorization; biquadratic `BiquadNum` denesting/equality/sign complete on its fragment; exact Jacobi eigenvalue-cluster separation via the squarefree part.
- **Costs**: provably optimal BDD variable orders by full enumeration for n≤8; SAT upgraded to CDCL (1-UIP learning, VSIDS, Luby restarts) that must actually learn on pigeonhole instances.
- **Circle classification**: the schema circle's helix cover (base↦ℤ, loop↦`ua(succ)`); encode is substitution, decode is integer elimination into loop powers; round trips hold by conversion on representatives, composite windings by subdivided transport (the single-substitution intensional boundary is recorded in SPEC §1.14.7/§4).
- **Front end**: deeper HOU imitation/identification with iterative deepening; `ModuleItem`-interleaved imports and declarations; binary v2 with producer, v1 migration, tag-8 refusal, and an in-process artifact store.

### Phase 12: same-spec recursion, eliminator compilation, structural agreement, case splits, the artifact repository, field towers, stratified extensionality and principal unifiers

- **Schemas**: a specless `DFunctorSelfFamily` marker gives Bush-style same-spec non-uniform recursion; the real host `Self` type replaces the placeholder; positivity of opaque operators is declaration-based (`DPositivityDeclaration`, with a structurally verified lambda variant — trusted, not proved). Simultaneous IR gains an eliminator compilation route (predicative fragment: function level strictly below base level; closed terms verified by forced application, case by case).
- **DSystem/conversion**: agreement probing is restricted to the dimensions branches actually mention; exact repair can supplement verified candidates (maximal, not maximum). Term-level Bool case-split conversion is new; Circle/Torus branch caps are read from generic coordinates so winding survives and path-valued composition computes the loop.
- **Persistence**: `ArtifactRepository` over an abstract byte store (dual-hash manifests, index-last atomic commits, manifest-scan recovery); module/registry bytes share a DAG codec (CHMODBIN v3 / CHREGBIN v2) with version policies and peer negotiation. An abstract protocol, not a disk service.
- **Algebra/Jacobi**: an irreducibility-certificate fast path (`x⁴+1` decided with zero Kronecker budget); the radical-equality tower gains pure-cubic and triquadratic fields; interval Jacobi refines clusters inside the iteration (kept separate from post-hoc Sturm separation).
- **Costs/extensionality**: provably optimal BDD orders by subset DP to n≤12; CDCL with LBD clause deletion and independently replayed RUP proofs; host cube functions are checked on face-interior, diagonal and connection probe strata, with stratified box validation (a strong check, not an extensionality proof).
- **Spheres/HOU**: a single substitution now accumulates windings of composite loops (π₁(S¹)≃ℤ for arbitrary neutral loops still unproved); unit laws of loop composition are witnessed by connection-rotation 3-cells on representatives, and Hopf identities are verified in exact rational arithmetic (no internal Hopf map or π₃ classification); `hou_unify_mgu` gives the Miller-pattern fragment an MGU / no-unifier / residual-constraints semantics.

### Phase 13: positivity fixed points, maximum completion, a shared DAG, tower fields, DRUP, loop classification and an integrity chain

- **Schemas**: SelfFamily parameter strict positivity is decided by a least fixed point over the per-parameter reports (Bush passes, deep negativity propagates); foreign simultaneous-IR hypotheses are transported across Product/Pi/List nested arguments by term-level functor maps.
- **DSystem/conversion/composition**: face-relative conversion descends only relevant dimensions, and repair can exact-restrict then choose a genuinely maximum compatible completion by maximum clique. Bool case splitting is guided by the syntactic difference of the two normal forms; square-valued Circle/Torus composition verifies candidate coordinates face by face and leaves unverifiable boxes as `DNComp`.
- **Persistence**: intern tables store child-id edges, so `CHDAGBIN` and a live interner share the same DAG (a second import adds zero nodes). Every artifact put/remove appends a previous-digest-linked `CHARTCHN` entry; after index destruction, chained recovery replays live records under an external head, while old chains and tampering are rejected.
- **Algebra/Jacobi**: `CertModDegreePatterns` jointly excludes factor degrees across several mod-p patterns; `MultiQuadNum` rises to four squareclass-independent generators with in-field and one-generator square roots. An adaptive Jacobi driver falls back to exact Sturm separation when interval envelopes stagnate.
- **Costs/extensionality**: the exact BDD-order incremental-cofactor subset DP reaches n≤16; CDCL proofs record Add/Delete steps for independent DRUP replay; host-cube stratification adds axis-specific deep-connection Tier D probes (105 in two dimensions).
- **Spheres/HOU**: inverse, associativity and symmetry-of-composite 3-cells join the unit laws, and closed loop expressions normalize by recursively assembled 3-cells to same-degree canonical words. `hou_solve_constraints` alternates principal propagation with bounded Huet search over whole residual constraint sets (a success is a specific unifier, not a general MGU).

## Concept map (concise)

| Concept | Implementation | Files |
|---|---|---|
| Idempotent Hermitian | `is_hermitian`, `is_idempotent`, `P=Σvₖvₖ†` | `complex.mbt`, `projector.mbt` |
| Well-formed eigenspaces | `Cⁿ=im(P)⊕ker(P)`, eigenvalue equations, `tr(P)` | `projector.mbt` |
| Commuting compatibility | `PQ=QP ⇒ PQ` is a projector | `projector.mbt` |
| System quotients/pruning | BDD region normal forms; delete unsatisfiable/entailed branches; union commutativity | `bdd.mbt`, `system.mbt`, `system_symbolic.mbt` |
| Kan pruning/comp | `P∘fill`, open-box formulas, caps, path transitivity | `cube.mbt` |
| NbE / definitional coe | βπ and η-long forms, `def_eq(_eta)` | `nbe.mbt`, `nbe_eta.mbt` |
| HOAS isomorphism | Host-function binding, smart βπ operations, reify=`nf` | `nbe.mbt` |
| ua/PathP/J | wiring equivalence→path, product-swap naturality, constant-line coe | `wiring.mbt`, `pathp_glue.mbt` |
| Glue soundness/comp | `glue/unglue` equations, finite endpoint algorithm, subspace hcomp correction | `pathp_glue.mbt`, `glue_comp.mbt` |
| Categorification | Karoubi, face posets, □ category, syntactic CCC, monoidal coherence | `categories.mbt`, `wiring.mbt` |
| Π/Σ/universes | Dependent NbE, type-directed conversion, dependent substitution, Typeᵢ hierarchy | `nbe_dep.mbt` |
| Kan for all types | DLine recursion for Π/Σ/U/embeddings | `kan_dep.mbt` |
| Symbolic spectral algebra | Characteristic polynomials, spectral projection identities, unique affine filling | `algebra/symalg.mbt`, `algebra/spectral_symbolic.mbt` |
| Cubical AST/hcomp | PathP, `DSystem`, reduction by Π/Σ/Path/Glue/data/HIT/Universe | `nbe_dep.mbt`, `kan_ast.mbt`, `ast_laws.mbt` |
| Environments/laziness/caches | Shared `DEnv` tails, at-most-once `DVThunk`, dimension-line/family memoization | `nbe_dep.mbt`, `semantic_system_laws.mbt` |
| Generic inductive/HIT schemas | Telescopes, functor positivity, mutual/nested/IR, quotients, higher cells, generated eliminators/cases/comp | `schema.mbt`, `schema_extensions.mbt` |
| Raw systems/Equiv/lines | Checked DSystem compatibility, first-match forms, AST Equiv/ua/GlueEquiv, checked lines and registry | `dsystem_compat.mbt`, `equiv_ast.mbt`, `checked_line.mbt`, `schema_registry.mbt` |
| Exact spectral extensions | QPoly/QMat, algebraic numbers, generalized eigenspaces, primary projectors, Jordan decomposition | `algebra/{qpoly,qmat,algnum,Jordan}.mbt` |
| DAG/certified numerics | BDD manager, budgets/DPLL, exact QuadC projector and polynomial-fill certificates | `bdd_dag.mbt`, `certified_numeric.mbt` |
| Containers/S³/Jacobi/HOU/modules | Nested container recursion, suspension spheres, interval unitary certificates, pattern-HOU elaboration, module functors/namespaces | `schema_functor.mbt`, `sphere3.mbt`, `algebra/Jacobi_interval.mbt`, `hou_elaborator.mbt`, `module_system.mbt` |
| Cubical algorithms/univalence | KanBox, transport, path algebra, subst/funext, ua/pathToEquiv/uaβ, round-trips and Glue square | `cubical_algorithms.mbt`, `univalence.mbt` |
| Phase 9 closure | Complete factorization/root isolation, level declarations, DSystem repair, AlgC, spherical representatives, non-Miller HOU and compiled module interfaces | `algebra/qpoly_factor.mbt`, `schema_phase9.mbt`, `certified_algebraic.mbt`, `sphere_homotopy.mbt`, `module_compilation.mbt` |
| Phase 10 closure | General `lemIso`/adjointification, `IntegerS` and π₃ presentations, bounded Huet search, module byte codec, BDD/SAT/QPoly cost controls | `equivalence_phase10.mbt`, `sphere_classification.mbt`, `hou_elaborator.mbt`, `module_binary.mbt`, `face_sat_watched.mbt`, `algebra/qpoly.mbt` |
| Phase 11 closure | Cross-family functors/simultaneous-IR compilation, Face agreement + exact repair, generic-point lemIso, CHREGBIN + hash-consing, pattern pruning/biquadratic denesting, opaque cubes/optimal orders/CDCL, circle encode/decode, interleaved modules and v2 migration | `schema_functor.mbt`, `dcube_filler.mbt`, `dterm_intern.mbt`, `schema_registry_persist.mbt`, `algebra/biquad_denest.mbt`, `algebra/poly_cube.mbt`, `circle_classify.mbt`, `phase11_laws.mbt` |
| Phase 13 closure | SelfFamily positivity fixed point/foreign nested-IH functor maps, relevant descent/maximum completion, difference-guided Bool splits/verified square caps, CHDAGBIN shared graphs/CHARTCHN integrity chain, joint irreducibility certificates/four-generator multiquadratic tower/adaptive Jacobi, exact orders to n≤16/DRUP/Tier D, inverse-associativity 3-cells/closed-expression classification, HOU residual solver | `schema_positivity.mbt`, `dsystem_compat.mbt`, `conv_case_split.mbt`, `dterm_dag_binary.mbt`, `algebra/multiquad_tower.mbt`, `phase13_laws.mbt` |
| Phase 12 closure | Same-spec self-nesting/positivity declarations, simultaneous-IR eliminator compilation, structural agreement + supplementation, Bool case-split and path-valued comp, artifact repository/DAG codecs/version negotiation, irreducibility certificates/cubic-triquadratic towers/cluster-aware Jacobi, subset-DP orders/CDCL deletion+RUP, stratified extensionality, unit-law 3-cells/exact Hopf, three-state pattern MGU | `schema_phase9.mbt`, `schema_positivity.mbt`, `conv_case_split.mbt`, `artifact_repository.mbt`, `algebra/qpoly_certificate.mbt`, `algebra/tower_fields.mbt`, `phase12_laws.mbt` |
| Package governance | cubical subgraph `cmd/main → root → algebra` (13 cubical components) inside a 27-package / 36-component 5-federation + apex platform, no upward edges | `architecture.json`, `tools/arch_check.py`, `ARCHITECTURE.md` |
| Specification registry | 127 cubical entries + 6,484 federation-wide bilingual appendix symbols + multi-package audit | `spec.mbt`, `SPEC*.md`, `SPEC-APPENDIX*.md`, `tools/audit_spec.py` |

## File map

```text
complex.mbt / projector.mbt   C, vectors, matrices, adjoints; projectors/eigenspaces
interval.mbt / bdd.mbt        De Morgan interval and faces; face-formula ROBDDs
system.mbt / system_symbolic.mbt  systems, compatibility, pruning; BDD region forms
cube.mbt                      cubes, face restriction, open-box comp, eigenspace pruning
nbe.mbt / nbe_eta.mbt         beta-pi NbE+HOAS; typed eta NbE and syntactic arrows
wiring.mbt                    signed-permutation finite equivalences, monoidal coherence
pathp_glue.mbt                finite universe: ua, coe, PathP, Glue, J
glue_comp.mbt                 general Glue comp (finite and subspace lines)
categories.mbt                Karoubi/face-poset/cube categories/syntactic CCC
nbe_dep.mbt / kan_dep.mbt     dependent Pi/Sigma/universe and cubical AST NbE; DLine coe/comp
kan_ast.mbt / ast_laws.mbt    AST comp/hcomp/hfill/coe by type, with laws
cubical_algorithms.mbt        KanBox, transport, path algebra, funext, subst
univalence.mbt                finite/AST computational univalence, checked universe paths
schema.mbt / schema_laws.mbt  generic inductive-family and HIT schema generators and laws
schema_extensions.mbt / schema_functor.mbt / schema_positivity.mbt
                              functors/positivity, mutual families, quotients, schemes, higher HITs
dsystem_compat.mbt / equiv_ast.mbt / checked_line.mbt / schema_registry.mbt
                              checked boundaries: systems, equivalences, lines, registry/caches
algebra/                      separate exact-algebra package
  symalg / qpoly / qmat       exact polynomials, rational matrices and kernels
  algnum / Jordan             algebraic extensions, generalized eigenspaces, Jordan theory
  spectral_symbolic           spectral projector and affine identities
  Jacobi_interval             certified Jacobi interval spectral iteration
bdd_dag.mbt / certified_numeric.mbt
                              interned BDDs, budgets/DPLL, exact numeric shadows
sphere3.mbt / hou_elaborator.mbt / module_system.mbt
                              S3, HOU elaborator, parameterized modules
semantic_system_laws.mbt      DSystem, environments, lazy/cache, multi-branch Glue laws
algebra/{qpoly_factor,root_isolation,splitting_field,radical_denest}.mbt
                              complete factorization, root isolation, splitting fields, denesting
schema_phase9.mbt / truncation.mbt / equivalence_phase9.mbt
                              level/simultaneous declarations, truncation, adjoint/fiber data
certified_algebraic.mbt / sphere_homotopy.mbt / module_compilation.mbt
                              general algebraic certification, spheres/Hopf, separate compilation
equivalence_phase10.mbt / sphere_classification.mbt
                              general lemIso/adjointification; IntegerS, pi quotients, loop representatives
module_binary.mbt / face_sat_watched.mbt
                              CHMODBIN v1/v2/v3 codec, migration, store; Tseitin CNF, watched DPLL, CDCL
dcube_filler.mbt / dterm_intern.mbt / schema_registry_persist.mbt
                              opaque-cube open boxes, DTerm hash-consing, CHREGBIN registry bytes
algebra/{biquad_denest,poly_cube}.mbt / circle_classify.mbt / phase11_laws.mbt
                              biquadratic denesting, exact cubes; circle helix encode/decode; phase-11 laws
conv_case_split.mbt / artifact_repository.mbt
                              difference-guided Bool splits; artifact repository and CHARTCHN chain
algebra/{qpoly_certificate,tower_fields}.mbt / phase12_laws.mbt
                              irreducibility certificates, pure-cubic/triquadratic towers; phase-12 laws
algebra/multiquad_tower.mbt / dterm_dag_binary.mbt / phase13_laws.mbt
                              four-generator multiquadratic tower; CHDAGBIN shared DAG; phase-13 laws
algebra/phase14_algebra.mbt / phase14_laws.mbt / phase15_laws.mbt
                              Hensel factorization certificates, real algebraic radicals, block Jacobi; phase-14/15 laws
algebra/phase16_algebra.mbt / artifact_crypto_wal.mbt / phase16_laws.mbt
                              LLL/Van Hoeij & Q̄⊂ℂ, SHA-256/512 + Ed25519 + WAL, phase-16 six-track laws
spec.mbt / verify.mbt         135 registry entries; 124 theorem checks
*_wbtest.mbt                  consolidated L8 tests across all 5 federations (15 tests)
architecture.json             package/component ownership and dependency manifest
tools/arch_check.py           architecture/count gate
tools/audit_spec.py           bilingual multi-package symbol-appendix generator/audit
cmd/main/ , cmd/showcase/     executable 124-theorem and 42-certificate unification reports
```

## Scope and boundaries

This remains an **executable model/specification** of a theory fragment, not a complete production cubical kernel. Building on Phases 10–13, Phase 14 adds joint `Σ`-tuple simultaneous IR, unfolded positivity witnesses, Hensel factorization certificates, rank-6 multiquadratic + real algebraic radicals, block-deflated Jacobi certificates, `Ω²` Eckmann–Hilton 3-cells, Mac Lane pentagon 4-cells, Brunerie's internal univalent Hopf fibration & integer invariant, cross-constraint HOU backtracking/enumeration, and `CHMODENV`/`CHARTAUT` authenticated CAS + incremental sync. Phase 15 delivers symmetry-orbit + connected-support decomposed optimal ROBDD ordering (up to 28-variable 4-component `exact=true`), linear-time indexed LRAT checking + DRAT→LRAT elaboration + the `CHLRATBN` v1 binary codec, strength-4 `ℙ¹(𝔽₈)` covering arrays + 5-color PHF + `CheckedDCube` & the cubical Yoneda naturality audit, and open-variable internal proofs of bidirectional bijectivity (`DVEquiv`), set truncation `‖A‖₀`, `π₁(S¹) = ‖Ω¹(S¹)‖₀ ≃ ℤ`, the pointed loop-suspension adjunction `(ΣA →* B) ≃ (A →* ΩB)`, and the 0-connected Freudenthal suspension theorem `‖Ω¹(Susp(A))‖₀ ≃ 1` (`π₁(S²) ≃ 1`, `π₁(S³) ≃ 1`) with circle wedge connectivity. Phase 16 completes all six remaining engineering tracks: cumulative large-universe & Dybjer–Setzer open multi-decoder simultaneous IR + anti-circular container positivity certificates, DSATUR chromatic max-clique pruning & `0 ~ 1` glued Circle/Torus open-box composition, FIPS 180-4 SHA-256/512 + RFC 8032 Pure-Ed25519 `CHARTSIG` sealing + `CHWALJRN` crash-consistent WAL journaling, exact rational LLL + Van Hoeij trace-lattice factor recombination + `Q̄ ⊂ ℂ` Rouché-disk algebraic closure, open-variable fibration loop equivalences + open Hopf–Freudenthal retraction `∂_Hopf(σ_{S²}(p)) ≡ p` + `π₂(S²)` split section + Stasheff's 5D `K₅` coherence 5-cell, and Huet delayed flex-flex constraint graphs + pull-based lazy unifier streams + DAG interface-hash relinking + LCA-based 3-way repository merge. Remaining boundaries are detailed in §4 of `SPEC.en.md`.
