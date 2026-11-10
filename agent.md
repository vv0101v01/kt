# `agent.md` — Handover Handbook: Working Policy + Repository Map

This file is the **single document a new maintainer needs first**. It has two parts:

* **Part I — Working policy** (binding): how code is verified in this repository, and where work is
  reported. Three rules, stated once, enforced by tooling.
* **Part II — Repository map**: what every folder is, what every per-folder `README.md` covers, which
  order to read them in, and the template any new README must follow.

The former standalone index `readme.packages.md` has been **merged into Part II of this file**; that file
no longer exists. [`agent.v2.md`](agent.v2.md) remains the authoritative governance document
(architecture, layering, MoonBit style, hardware-acceleration rules, refactor history). Where the two
overlap, `agent.v2.md` governs the detail and this file governs the procedure and the map.

**Repository at a glance** — MoonBit package `vv0101v01/cubical-hermitian` v2.0.0,
`preferred_target = "wasm"`, **8 federations + 1 unification apex**, **39 packages**, **48 components**,
**222 `.mbt` files**, **152,883 lines** (verified by `python3 tools/arch_check.py`).

---

# Part I — Working policy

## 1. Testing policy

### 1.1 What is forbidden

The repository keeps **no persistent tests**. The following are banned outright and are rejected
mechanically by `tools/arch_check.py`:

| Banned | Why |
|---|---|
| Any `*_test.mbt` / `*_wbtest.mbt` file | They accumulate, outlive the code they describe, and silently rot |
| Any `for "test" { … }` / `for "wbtest" { … }` block in `moon.pkg` | Turns test scaffolding into build configuration |
| Any committed top-level `test { … }` block | Same as above, one indirection further |
| Black-box unit tests (drive the public API from outside, assert on returned values) | They encode *today's* observable behaviour rather than the invariant, so every internal refactor becomes a rewrite |
| Smoke tests ("call it and see that it does not crash") | They assert almost nothing but cost a full build |

**Why.** Persistent test suites grow monotonically while the invariants they protect do not. In this
repository they pushed single-package `wasm-gc` runs past the hundred-second mark and produced a wall of
synchronisation noise every time a module boundary moved. The durable mathematics of this project does not
belong in test files at all: it belongs in **first-class pure functions of the module itself** — the
`check_*` / `*_laws_hold` / `*_report` entry points you will find in every package. Those are shipped,
documented, callable, and reviewed like any other code. Anything that is *not* worth shipping as a
first-class function is not worth keeping as a test file either.

### 1.2 What is required — the edit → inspect → localized-test → delete loop

Every change is verified in **three tiers**, in this order. Tiers A and C always run; tier B runs while
you are working and leaves nothing behind.

#### Tier A — static gate (run after every edit, `< 3 s`)

```bash
moon check   --deny-warn --target wasm-gc
moon build   --target wasm-gc
python3 tools/arch_check.py
```

The bar is **0 warnings, 0 errors**. An unused variable, a non-exhaustive branch, a deprecated form, or a
cross-layer import is a failure, not a note. `arch_check.py` must print
`architecture ok: 8 federations + unification apex, 39 packages, 48 components, …`.

#### Tier B — localized test at the bottom of the file (the whole point of this policy)

When you implement an algorithm, probe a counter-example, or move code between packages, **append a
temporary `test` block to the very bottom of the file you are editing** — not to a new file, not to a
sibling `*_test.mbt`, not to a shared harness. Then:

```moonbit
// ... end of src/the_file_you_are_editing.mbt ...

///|
test {
  debug_inspect(radon_invert_fp(r3, rf_mod), content="[1, 2, 0, 3, 1, 4, 2, 0, 1]")
  debug_inspect(f3_atlas.rank_counts, content="[1, 128, 4032, 2400]")
}
```

```bash
moon test <the-single-package> --target wasm-gc --update   # fills in the real values, ~1 s
moon test <the-single-package> --target wasm-gc            # asserts they match exactly
```

Rules that make this loop work:

* **One package, never the workspace.** `moon test <pkg>` on the package you just touched — that is the
  sub-second feedback signal. Never `moon test` at the root.
* **`debug_inspect` for structured values.** Under `moonc v0.10.18+`, arrays, tuples, structs and enums
  go through `debug_inspect(..., content="…")` to stay warning-free; `inspect` is fine only for plain
  strings and scalars.
* **`content=""` first, then `--update`.** Write the empty expectation, let the compiler fill in what the
  code actually produced, *read it*, and only then decide whether it is right. The value you commit to
  `content` must be one you have verified by reasoning, by an independent implementation, or by a brute
  force oracle — never merely the value the code happened to emit.
* **Cross-check with a second, independent path whenever one exists.** The house style throughout this
  repository is "same question, two unrelated theories, same answer" (`fw` vs. Lehmann vs. blocked
  closure; `trop_det` vs. `trop_det_dp` vs. `trop_det_bruteforce`; kernel NbE vs. the finite model in
  `cubical/finite`; geometric `|β| = 2` vs. algebraic `Ext^{2,3} = 0`). A localized test that only
  compares an implementation with itself proves nothing.
* **Include the negative control.** If you are checking a checker, feed it something that must fail.
  `cmd/semiringreport` does exactly this with `ReportBroken` (a `times` that breaks distributivity) and
  `ReportLying` (a semiring that falsely claims idempotence); the report *asserts that the law checker
  rejects them*. A checker that has never rejected anything is untested.
* **Write it, test it, delete it — immediately.** The instant the numbers are confirmed, **delete the
  `test` block from the file.** Write → run → know → delete is a single operation, on the order of one
  second. Nothing temporary survives the edit. If a check turns out to be permanently valuable, promote
  it into a first-class `check_*` / `*_report` function in the module (Tier A + reviewers will see it),
  never into a lingering test file.

#### Tier C — interface and milestone audit (before a commit)

```bash
moon info --target wasm-gc && moon fmt
moon check --deny-warn --target wasm-gc
python3 tools/arch_check.py
git diff '*.mbti'
```

`.mbti` snapshots are the diff that catches accidental public-API changes: a refactor that is meant to be
internal must leave the generated interfaces untouched. For cross-federation work, finish with an
end-to-end run — `moon run cmd/main --target wasm-gc` (`137/137` theorems),
`moon run cmd/metatheory --target wasm-gc` (`545/545` laws), and
`moon run cmd/showcase --target wasm-gc` (`47/47` certificates + `K_9 = 36/36` bridges).

### 1.3 The one-sentence version

> **Edit the code, inspect the result, put a tiny test at the bottom of the file you are in, run it, read
> it, delete it.**

If you find yourself creating a test file, a fixtures directory, or a test runner, you have taken the
wrong branch of the policy; go back to tier B.

---

## 2. Reporting: everything goes through `agent.v2.md`

No other channel counts. Work that is not recorded in `agent.v2.md` is, for the purposes of this
repository, work that did not happen.

Every reporting entry answers, in this order:

1. **What changed** — packages and files touched, with line-level scope.
2. **Why** — the invariant, theorem, or boundary being served; if it is a refactor, the layering rule
   that required it.
3. **How it was verified** — the tier A output verbatim (`arch_check` totals, `0 warnings`), the tier C
   `.mbti` diff verdict, and the *values* the tier B localized test produced. State explicitly that the
   temporary test was deleted.
4. **What is still open** — unfinished items, known limitations, and anything deliberately deferred.

Reporting rules:

* **Numbers, not adjectives.** "Faster" is not a report; `mul_ikj` vs `mul_naive` in microseconds on a
  stated input is. Every claim of correctness ships with the second path that agrees with it, and every
  claim of a limit ships with the measured number where the limit starts to bite.
* **Do not hide the seams.** If a result depends on a hypothesis (tree-shaped factor graph, no negative
  cycle, `n ≤ 8`, single-threaded host backend), say so in the entry and, where possible, measure the
  boundary rather than describing it — §19 of the semiring report exists for precisely this reason.
* **Report failures as failures.** A red gate, a mismatch between two independent paths, or a
  `[FAIL]` line in `cmd/showcase` goes into the entry verbatim; it is not softened into "needs
  attention".
* **Keep it append-only in spirit.** Correction means a new dated entry that supersedes the old one, not
  a silent rewrite of history; readers must be able to see what was believed and why it changed.

---

## 3. Suggestions and project-content changes: also `agent.v2.md`

`agent.v2.md` is not only a changelog. It is the single place where the project's *direction* is
recorded. Submit through it:

* **Proposals and suggestions** — new packages, splits, merges, a change of layering, an algorithm worth
  replacing, a limit worth measuring. State the motivation, the invariant at stake, the estimated blast
  radius (which packages, which federations, which `.mbti` surfaces), and the verification plan.
* **Project-content changes** — anything that alters what the repository *is*: the federation map or
  `architecture.json` components, the theorem registry counts (`137/137`), the metatheory law counts
  (`545/545`), the certificate ledger (`47/47`), the `K₉ = 36` bridge counts, `ATLAS-01..18`,
  `CONJ-01..12`, the `agent.v2.md` rules themselves, and the per-folder `README.md` set mapped in Part II
  of this file.
* **Boundary changes** — a new `moon.pkg` import edge, a new `supported_targets` restriction, a new
  `publish`/`test` mode. These are project content, not implementation detail: `tools/arch_check.py`
  will reject them until the governance text agrees.

A proposal is not adopted because it was made; it is adopted when the entry records that `arch_check.py`
passes on the new shape, that `moon check --deny-warn` is clean, and that the affected counts have been
updated in one consistent edit. Untracked drift between code and `architecture.json` is treated as a
defect.

---

# Part II — Repository map

## 4. Where the documentation lives

| File | Scope | Language |
|---|---|---|
| **`agent.md`** (this file) | Binding policy + the full folder/sub-package map + reading orders + README template | English |
| [`agent.v2.md`](agent.v2.md) | Governance: architecture rules, 7-way `cubical` split, MoonBit style, WGSL portability, refactor records, **all work reports and proposals** | Chinese |
| [`readme.v2.md`](readme.v2.md) | Root overview: the 9-federation + apex architecture, package→federation table, quick commands | Chinese |
| **`<folder>/README.md`** × 17 | One per top-level folder (`gcd/` .. `webgpu/`, including `meta/`): file-by-file reading of every `.mbt` in it | Chinese |
| **`<folder>/<sub>/README.md`** × 40 | One per nested sub-package inside `cubical/`(9), `semiring/`(15), `cmd/`(6), `meta/`(4), plus the 6 decoupled light cores (`symlib/core`, `algebra/core`, `condensed/core`, `topos/site`, `conjecture/kernel`, `accel/swar`) | Chinese |
| `architecture.json` | Machine-readable source of truth: 9 federations + apex, **52 packages, 61 components** | JSON |
| `tools/arch_check.py` | Enforces the above and prints the totals quoted everywhere | Python |

**Total documentation coverage: 100% of all 52 MoonBit packages + infrastructure folders (`17` top-level + `40` nested sub-package `README.md`s, plus root `README.md` / `readme.v2.md` / `agent.v2.md`).**

**Rule for maintainers:** if you add, remove, split, merge, or rename a package, you update **three**
places in one commit — `architecture.json`, the affected `README.md`(s), and the corresponding table row
in Part II of this file — and you record the change in `agent.v2.md`. A stale row here is a defect of the
same severity as a failing gate.

---

## 5. The 17 top-level folders

`.mbt` counts and line counts are the on-disk truth for that folder (**recursive** for folders containing nested sub-packages).

| # | Folder | Federation · layer | `.mbt` | Lines | What it is |
|---:|---|---|---:|---:|---|
| 1 | [`gcd/`](gcd/README.md) | F6 · L0 (lower-V apex `V₁`) | 3 | 1,683 | Five-domain generic elimination GCD: 16-lane lazy `F_p` RREF, HMM `ℤ`-SNF, Bareiss det, modular HNF, CRT, Wang rational recon & digest chain |
| 2 | [`algebra/`](algebra/README.md) | F1 · L1–L2 (`algebra/core` + `algebra`) | 23 | 19,282 | Exact rational/algebraic tower (`Rat` `Int64` fast path, Bareiss/Ozaki-II `QMat`, complete factorization, number fields, Jordan, certified intervals, transcendence) |
| 3 | [`cubical/`](cubical/README.md) | F1 · L0–L6 (**9 sub-packages**) | 77 | 78,794 | Trusted dependent-cubical core: Kalman free De Morgan `I_DM`, CCHM `Cofib(n)`, NbE, Kan, Glue, univalence, HITs, `O(Δ)` HOU, BFT/MVCC store, universal algebra autonomy & 54 cubical structures |
| 4 | [`symlib/`](symlib/README.md) | F2 · L0–L1 (`symlib/core` + `symlib`) | 27 | 9,061 | Finite symmetry: hardware `popcnt` `BitVec`, unbounded `PermLut`, Schreier–Sims, McKay search, Holt arbitrary-rank subgroup lattices, Burnside Möbius & groupoid Yoneda/Kan |
| 5 | [`semiring/`](semiring/README.md) | F3 · L1–L4 (**15 sub-packages**) | 39 | 10,982 | `@swar` Bool/GF(2) GEMM, 3D gift-wrapping Newton subdivision, Karp tropical eigenpairs, Johnson negative-weight APSP, Min-Fill VE & Hopcroft `O(\|Σ\|\|Q\|log\|Q\|)` minimal DFA |
| 6 | [`topos/`](topos/README.md) | F4 · L2–L3 (`topos/site` + `topos`) | 9 | 8,210 | Grothendieck sites, `Sieve64` SWAR bi-Heyting kernel, MAC matching families, `¬¬` Boolean sheafification, Alexandrov/Chu dualities, geometric morphisms, Torsors & cohomology |
| 7 | [`scheme/`](scheme/README.md) | F5 · L3 | 6 | 6,150 | `Mono64` SWAR, Yan geobuckets, M4RI Boolean F4, multi-prime CRT modular F4, Grassmann–Plücker det, glued schemes, Kähler/Fitting, Serre duality & Chow motives |
| 8 | [`condensed/`](condensed/README.md) | F6 · L1–L4 (`condensed/core` + `condensed`) | 5 | 3,376 | Profinite towers, constructive Nöbeling unimodular basis, Roos–Milnor `R¹lim`, solid/liquid modules, 64× `@swar` Steenrod–Adams (`h₃=σ`, `η³=4ν`) & analytic stacks |
| 9 | [`tensor/`](tensor/README.md) | F7 · L2 | 2 | 2,151 | 64-trit `𝔽₃` 6,561-tensor rank atlas `[1, 128, 4032, 2400]`, MRV/MAC exact Gromov–Hausdorff, dominated VR collapse, Radon & Clifford spinors |
| 10 | [`conjecture/`](conjecture/README.md) | F7 · L3–L5 (`conjecture/kernel` + `conjecture`) | 3 | 1,436 | Half-GCD rational reconstruction, 64-bit `ctz` bitplane implication lattice, Lakatos conjecture-evolution engine & 12 cross-federation conjectures |
| 11 | [`bridge/`](bridge/README.md) | apex · L8 (upper-V apex `V₂`) | 18 | 6,626 | **`K₉ = 36/36` all-pairs bridges**, `F7→F9→F4→F1` promotion, `F8×F5×F1` & `F2×F3×F6` triads, 18-entry geometry–logic atlas & 47/47 certificates |
| 12 | [`accel/`](accel/README.md) | F8 · L0–L4 (`accel/swar` + `accel`) | 10 | 3,601 | `L0` 64-bit SWAR primitives (M4RI RREF, 64-trit `GF(3)`, Ozaki-II CRT, Stockham NTT, Cube64 butterfly, Scanbox, HVM2 `INetArena`) + 8/8 portable WGSL shaders |
| 13 | [`hostfs/`](hostfs/README.md) | F1 · L1 | 2 | 828 | Executable crash-consistency model (`fsync` ordering) + BFT `3f+1` quorum durable replicas |
| 14 | [`meta/`](meta/README.md) | F9 · L0–L2 (**4 library sub-packages**) | 29 | 13,967 | Zero-business-dependency metatheory floor & three-axis engine: Paterson–Wegman DAG MGU, Bareiss, SLG tabling, bidirectional E-graph QIIT, NbE reflection, `V₅ = 65,536` HF64 & Paley Ramsey |
| 15 | [`cmd/`](cmd/README.md) | 6 executables · L2–L9 | 11 | 4,013 | `cmd/main` (`137/137`), `cmd/metatheory` (`545/545`), `cmd/showcase` (`47/47` + `K₉=36/36`), `cmd/symdemo`, `cmd/symbench`, `cmd/semiringreport` (`§1–§19`) |
| 16 | [`tools/`](tools/README.md) | infrastructure | 0 | 0 | `arch_check.py`, `health_scan.py` (`5,745` fns, `0` dead code, `0` duplicates), `gen_laws.py`, `gen_labels.py` |
| 17 | [`webgpu/`](webgpu/README.md) | F8 browser side | 0 | 0 | Zero-dependency browser verifier for all 8 registered WGSL compute shaders + CPU-SWAR bitwise cross-check |

**(Plus root package `.` : `18` `.mbt` files, `12,769` lines → Grand Total: `52` packages, `61` components, `282` `.mbt` files, `182,929` lines.)**

| Federation | Packages | Files | Lines |
|---|---:|---:|---:|
| `cubical` (incl. root, `algebra`, `hostfs`, `cmd/main`) | 14 | 121 | 111,679 |
| `symlib` | 4 | 30 | 9,964 |
| `semiring` | 16 | 44 | 13,795 |
| `topos` | 2 | 9 | 8,210 |
| `scheme` | 1 | 6 | 6,150 |
| `condensed` | 3 | 8 | 5,059 |
| `discovery` | 3 | 5 | 3,587 |
| `accel` | 2 | 10 | 3,601 |
| `meta` | 5 | 30 | 14,092 |
| `unification` (apex) | 2 | 19 | 6,792 |

---

## 6. The 40 nested sub-packages

`cubical/`, `semiring/`, `cmd/`, and `meta/` are package groups, joined by the 6 decoupled lightweight core sub-packages (`symlib/core`, `algebra/core`, `condensed/core`, `topos/site`, `conjecture/kernel`, `accel/swar`). Every nested folder is its own `moon.pkg` with its own `README.md`.

### 6.1 `cubical/` — 9 sub-packages (77 files, 78,794 lines)

| # | Sub-package | Layer | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`cubical/face_bdd/`](cubical/face_bdd/README.md) | L0 | 6 | 6,705 | 148 | Kalman free De Morgan `I_DM`, free CCHM `Cofib(n)`, `UInt64` SWAR fast path, ROBDD (`O(1)` eq) & CDCL (DRUP/DRAT/LRAT) |
| 2 | [`cubical/finite/`](cubical/finite/README.md) | L1 | 4 | 1,834 | 141 | The finite universe: η-NbE, wiring, `ua` / `coe` / `PathP` / `Glue` / `J` — **the best entry point in the repository** |
| 3 | [`cubical/hermitian/`](cubical/hermitian/README.md) | L3 | 9 | 3,201 | 143 | Hermitian projectors and certifiable cubical filling (float → `QuadC` → `AlgC`) + the Karoubi envelope |
| 4 | [`cubical/kernel/`](cubical/kernel/README.md) | L2 | 20 | 30,968 | 180 | **The trust boundary**: dependent NbE, Kan, DSystem repair, `DLevelDecl`, inductive/HIT/open-IR schemas, ε₀ ordinals |
| 5 | [`cubical/elaborator/`](cubical/elaborator/README.md) | L3 | 4 | 5,610 | 145 | Bidirectional elaboration; `O(Δ)` Trail-Stack HOU / higher-order matching / Goldfarb undecidability certificate |
| 6 | [`cubical/homotopy/`](cubical/homotopy/README.md) | L3 | 14 | 12,264 | 189 | Computational homotopy: `π₁(S¹)≃ℤ`, `π₂(S²)≃ℤ`, `π₄(S³)≅ℤ/2ℤ`, Blakers–Massey, `Kₙ` coherence |
| 7 | [`cubical/store/`](cubical/store/README.md) | L3 | 9 | 11,193 | 184 | `CHMODBIN` / `CHDAGBIN` / `CHREGBIN`, version negotiation, Ed25519 BFT WAL, SCC-atomic MVCC hot reload |
| 8 | [`cubical/autonomy/`](cubical/autonomy/README.md) | L5 | 5 | 2,645 | 85 | Constructive universal algebra autonomy, Mal'cev congruences/quotients, affine & bi-De Morgan cubical duality, Moore free paths, degeneracy trees, 5D alternating boundaries, bidirectional NF pruning & `¬¬` presheaf gluing |
| 9 | [`cubical/structures/`](cubical/structures/README.md) | L6 | 6 | 4,374 | 87 | All 54 higher cubical structures (Swan strict `Id`, free path fibration, 65,536-cube Eilenberg–Zilber split, affine bidirectional & `LJF` focusing, polynomial container Yoneda & SIP, Galois covering correspondence, torus/`RP²` torsion, HOU motive reconstruction, matroid boundary repair, computational reflection) + 26-verb × 14-composition atlas |

### 6.2 `semiring/` — 15 sub-packages (39 files, 10,982 lines)

| # | Sub-package | Layer | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`semiring/algebra/`](semiring/algebra/README.md) | L1 | 6 | 2,208 | 147 | Ten-trait hierarchy + `Ops` counter, seven concrete semirings, `CyclicSet` hardware `popcnt`, law checkers (with negative controls) |
| 2 | [`semiring/matrix/`](semiring/matrix/README.md) | L2 | 6 | 1,797 | 154 | Generic `Mat[E]`, `@swar` Four-Russians 64-bit Bool & M4RI `GF(2)` GEMM, SWAR closures, CSR sparsity |
| 3 | [`semiring/graph/`](semiring/graph/README.md) | L3 | 4 | 643 | 104 | Bitset closure, functional decomposition, Dijkstra, Bellman–Ford + Johnson negative-weight APSP, multi-objective Pareto |
| 4 | [`semiring/io/`](semiring/io/README.md) | L2 | 1 | 153 | 58 | `Bytes`-direct parsing vs. the naive path, reproducible synthetic data |
| 5 | [`semiring/monoid/`](semiring/monoid/README.md) | L2 | 1 | 533 | 81 | Prefix scan / segment tree / sparse table / Fenwick — **four strengths, four type-class costs** |
| 6 | [`semiring/par/`](semiring/par/README.md) | L1 | 2 | 159 | 73 | Backend-agnostic parallelism contract: chunking, two-pass scan (elementwise identical to sequential) |
| 7 | [`semiring/sim/`](semiring/sim/README.md) | L1 | 2 | 261 | 96 | Parameterised cache model + access trace + `time_min` (minimum, not mean) |
| 8 | [`semiring/bp/`](semiring/bp/README.md) | L2 | 1 | 535 | 82 | Generalised distributive law + Min-Fill exact variable elimination `bp_exact_all_marginals_ve` on loopy factor graphs |
| 9 | [`semiring/cat/`](semiring/cat/README.md) | L3 | 3 | 554 | 100 | Free category (hom-sets), set matrices, decategorification (cardinality preserves multiplication), Maslov dequantisation |
| 10 | [`semiring/nf/`](semiring/nf/README.md) | L1 | 3 | 903 | 101 | 64-bit hashed Brzozowski DFA construction + Valmari–Hopcroft `O(\|Σ\|\|Q\|log\|Q\|)` DFA minimisation, monoid word problem |
| 11 | [`semiring/par_host/`](semiring/par_host/README.md) | L4 (platform ext.) | 1 | 112 | 69 | `supported_targets: native`; structured concurrency |
| 12 | [`semiring/ratelimit/`](semiring/ratelimit/README.md) | L1 | 2 | 490 | 97 | GCRA with a single `tat` cell + hierarchical limiting + eviction counters |
| 13 | [`semiring/spline/`](semiring/spline/README.md) | L3 | 1 | 348 | 71 | Periodic cubic splines in three agreeing solvers; the monoid (`AffineM`) path solves no linear system |
| 14 | [`semiring/trop/`](semiring/trop/README.md) | L2 | 3 | 1,631 | 115 | Tropical roots, 3D ridge gift-wrapping Newton subdivision `O(n log n + n·#Faces)`, Karp tropical eigenpairs, `trop_det` |
| 15 | [`semiring/app/`](semiring/app/README.md) | L4 | 3 | 655 | 79 | Transitive closure + consensus + portable `wasm-gc` verification suite `verify_semiring_wasm_suite` |

### 6.3 `cmd/` — 6 executables (11 files, 4,013 lines)

| # | Sub-package | Target | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`cmd/main/`](cmd/main/README.md) | all | 1 | 6 | 57 | Entry point for the `137/137` theorem ledger (`print_report()`) |
| 2 | [`cmd/metatheory/`](cmd/metatheory/README.md) | all | 1 | 125 | 31 | Ninth Federation entry point recomputing all `545/545` metatheory laws across `86` `law_*` functions |
| 3 | [`cmd/showcase/`](cmd/showcase/README.md) | all | 1 | 166 | 66 | Nine federations × `K₉ = 36/36` × three cross-federation triads/pipelines × `47/47` certificates |
| 4 | [`cmd/symdemo/`](cmd/symdemo/README.md) | all | 1 | 309 | 65 | `symlib` demo: "derived vs. direct" two-path agreement + monad laws |
| 5 | [`cmd/symbench/`](cmd/symbench/README.md) | all | 2 | 594 | 88 | 12-case full-pipeline timing + seven derived-algorithm families (A–G) |
| 6 | [`cmd/semiringreport/`](cmd/semiringreport/README.md) | **native only** | 5 | 2,813 | 118 | The 19-section measurement report; §19 turns every limitation into a measured number |

### 6.4 `meta/` & decoupled lightweight core sub-packages — 10 sub-packages (53 files, 29,938 lines)

| # | Sub-package | Layer | `.mbt` | Lines | What it is |
|---:|---|---|---:|---:|---|
| 1 | [`meta/core/`](meta/core/README.md) | L0 | 12 | 4,903 | Ordinals, `Int64` Bareiss, Paterson–Wegman linear DAG MGU, matroids, complexes, Paley Ramsey (`R(4,4)=18, R(3,5)=14`) & universal algebra laws |
| 2 | [`meta/instances/`](meta/instances/README.md) | L1 | 6 | 4,206 | Horn/SLG tabled resolution, ordinal termination, critical-pair coherence, `H¹` gluing & matroid characterization |
| 3 | [`meta/iit/`](meta/iit/README.md) | L1 | 5 | 2,811 | Induction-induction Kleene slice tower (`Fin` lags `Nat`), bidirectional E-graph QIIT & STLC β index transport |
| 4 | [`meta/reflect/`](meta/reflect/README.md) | L2 | 6 | 2,047 | NbE `decide_eq` + replayable certificates `check_cert`, Ackermann `V₅ = 65,536` HF64 & Mahlo universe reflection |
| 5 | [`accel/swar/`](accel/swar/README.md) | L0 | 6 | 2,300 | Zero-dependency 64-bit SWAR: 64-trit `GF(3)`, M4RI RREF, Ozaki-II DP4A CRT, Stockham NTT, Cube64 butterfly, Scanbox & HVM2 `INetArena` |
| 6 | [`symlib/core/`](symlib/core/README.md) | L0 | 11 | 3,316 | Zero-dependency symmetry kernel: hardware `popcnt` `BitVec`, unbounded `PermLut`, Schreier–Sims & McKay search |
| 7 | [`algebra/core/`](algebra/core/README.md) | L1 | 3 | 2,938 | `Rat` `Int64` fast path, `Poly`/`QPoly` & Bareiss/Ozaki-II `QMat` decoupled from field towers |
| 8 | [`condensed/core/`](condensed/core/README.md) | L1 | 2 | 1,953 | `CompactProfiniteTower`, constructive Nöbeling unimodular basis, Roos–Milnor `R¹lim` & 64× `@swar` Steenrod–Adams |
| 9 | [`topos/site/`](topos/site/README.md) | L2 | 5 | 5,046 | Linear-algebra-free Grothendieck sites, `Sieve64` SWAR bi-Heyting kernel, MAC gluing, sheafification, `Ω_J` & Torsors |
| 10 | [`conjecture/kernel/`](conjecture/kernel/README.md) | L3 | 1 | 418 | Half-GCD modular rational reconstruction & 64-bit `ctz` bitplane implication lattice |

---

## 7. Reading paths by intent

**First contact** — `readme.v2.md` (the whole picture) → this Part II → `gcd/` → `cubical/` → `bridge/`.

**Type theory / proof assistant** — `cubical/face_bdd/` → `cubical/finite/` → `cubical/kernel/` →
`cubical/homotopy/` → `cubical/elaborator/` → `cubical/store/`.

**Algorithms / performance** — `semiring/algebra/` → `semiring/matrix/` → `semiring/graph/` →
`semiring/sim/` → `accel/` → `webgpu/` → `cmd/semiringreport/` (the numbers).

**Algebraic geometry / category theory** — `symlib/` → `topos/` → `scheme/` → `condensed/` → `algebra/`.

**"Automated scientific method"** — `tensor/` → `conjecture/` → `bridge/` (how discoveries become bridges).

**Changing the architecture** — `agent.v2.md` (governance) → §1–§3 of this file (verification and
reporting) → `tools/` → `architecture.json`.

**Just need to run something** — `moon run cmd/main --target wasm-gc` (137/137 theorems),
`moon run cmd/metatheory --target wasm-gc` (545/545 laws),
`moon run cmd/showcase --target wasm-gc` (47/47 certificates + K_9=36/36),
`moon run cmd/semiringreport --target native` (the measurement report).

---

## 8. The uniform README template

Every one of the 43 per-folder READMEs follows the same nine sections, in this order. New READMEs must
match it; readers rely on section positions being predictable.

1. **Architectural position** — layer, dependencies, federation, from `architecture.json`.
2. **One-line positioning** — what problem this folder exists to solve.
3. **File table** — every file, its line count, and its responsibility.
4. **Core data types** — the `pub` structs/enums/traits that define the interface.
5. **File-by-file / function-by-function reading** — the algorithm and theorem content, with the
   project's tags `[T-…]` (theorem), `[D-…]` (definition/derivation), `[Ax-…]` (axiom/capability
   boundary).
6. **Signature results table** — the constants and entry functions that can be re-verified.
7. **Usage example** — written against **public APIs that actually exist**, not aspirational ones.
8. **Dependency boundaries** — what imports it, what it may import, and what is forbidden.
9. **Verification** — `moon check`, `moon test <pkg>`, and the package's own `check_*` / `*_report`
   master switch.

Two habits that the existing 43 READMEs follow and new ones must keep: (a) **examples are compiled
against real signatures** — if a function name or arity changes, the README changes in the same commit;
(b) **limitations are stated with the number where they bite**, not softened into "in some cases".

---

## 9. Onboarding checklist (first hour)

1. `python3 tools/arch_check.py` → confirm `52 packages, 61 components, 282 .mbt files, 182929 .mbt lines` on your machine. This is
   your baseline; every later claim of "unchanged architecture" is measured against it.
2. `moon check --deny-warn --target wasm-gc` → must be silent.
3. `moon run cmd/main --target wasm-gc` → must end at `137/137` (`cmd/metatheory` → `545 / 545`).
4. Read `cubical/finite/README.md`, then `semiring/algebra/README.md` — they are the two smallest
   self-contained views of what this repository is about.
5. Read §1.2 Tier B of this file once more, then make a one-line change to some file and walk the loop
   (append test → `--update` → read → delete). This is the loop you will use thousands of times.
6. Before your first real commit: read §2 and write the four-part entry into `agent.v2.md`.

---

## 10. Quick reference

| Situation | Do this |
|---|---|
| Wrote a function | Bottom-of-file `test` with `debug_inspect` → `moon test <pkg> --update` → read → assert → **delete** |
| Need to know a value | `content=""` + `--update`, then judge the printed value by reasoning or a second path |
| Refactored internals | `moon info && git diff '*.mbti'` must be empty of unintended changes |
| Moving code between packages | `moon check --deny-warn --target wasm-gc` + `python3 tools/arch_check.py`; call out the new edge in `agent.v2.md` |
| Found a permanent invariant | Promote it to a `check_*` / `*_report` function in the package; do **not** keep a test file |
| About to create `*_test.mbt` | Stop. Re-read §1.2 Tier B. |
| Added / split / renamed a package | Update `architecture.json` + the folder README(s) + the relevant table in Part II + an `agent.v2.md` entry, in one commit |
| Finished a piece of work | Write the four-part entry in `agent.v2.md` |
| Have an idea for a change | Proposal entry in `agent.v2.md`, with blast radius and verification plan |
| Looking for a folder | §5 (16 top-level) then §6 (27 nested); every row links to its `README.md` |

---

## 11. Two-paragraph summary

> **Verify locally and transiently:** edit the file, append a tiny test at its bottom, run the single
> package, read the number, delete the test. No test files, no smoke tests, no persistent harness — the
> durable invariants live on as first-class `check_*` / `*_report` functions.
>
> **Report permanently and centrally:** every result, proposal, and project-content change is an entry in
> `agent.v2.md` — with numbers, with the independent path that agrees, and with the limits measured, not
> assumed. And navigate by this file: the 16 top-level folders (§5) and the 27 nested sub-packages (§6)
> each have a README that was written by reading every line of code in them.
