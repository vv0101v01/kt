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
end-to-end run — `moon run --release cmd/main --target wasm-gc` (`129/129` theorems) and
`moon run --release cmd/showcase --target wasm-gc` (`47/47` certificates).

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
  `architecture.json` components, the theorem registry counts (`129/129`), the certificate ledger
  (`47/47`), the `K₆ = 15` / `K₇ = 21` bridge counts, `ATLAS-01..18`, `CONJ-01..12`, the `agent.v2.md`
  rules themselves, and the per-folder `README.md` set mapped in Part II of this file.
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
| [`readme.v2.md`](readme.v2.md) | Root overview: the 8-federation double-V architecture, package→federation table, quick commands | Chinese |
| **`<folder>/README.md`** × 16 | One per top-level folder: file-by-file reading of every `.mbt` in it | Chinese |
| **`<folder>/<sub>/README.md`** × 27 | One per nested sub-package inside `cubical/`, `semiring/`, `cmd/` | Chinese |
| `architecture.json` | Machine-readable source of truth: 8 federations, 39 packages, 48 components | JSON |
| `tools/arch_check.py` | Enforces the above and prints the totals quoted everywhere | Python |

**Total documentation written for this map: 16 + 27 = 43 per-folder READMEs, 5,474 lines**
(2,536 lines for the 16 top-level files, 2,938 for the 27 nested ones).

**Rule for maintainers:** if you add, remove, split, merge, or rename a package, you update **three**
places in one commit — `architecture.json`, the affected `README.md`(s), and the corresponding table row
in Part II of this file — and you record the change in `agent.v2.md`. A stale row here is a defect of the
same severity as a failing gate.

---

## 5. The 16 top-level folders

`.mbt` counts and line counts are the on-disk truth for that folder (**recursive** for the three package
groups `cubical/`, `semiring/`, `cmd/`, whose code lives one level down). "README" is the length of that
folder's `README.md` in lines.

| # | Folder | Federation · layer | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`gcd/`](gcd/README.md) | F6 · L0 (lower-V apex `V₁`) | 2 | 1,196 | 136 | Five-domain generic elimination GCD: `F_p` RREF, `ℤ` HNF/SNF, CRT, Grassmann duality, free-group reduction, six-domain certificates |
| 2 | [`algebra/`](algebra/README.md) | F1 · L1 | 22 | 18,797 | 165 | Exact rational/algebraic tower: complete polynomial factorization, number fields, Jordan theory, certified intervals, transcendence certificates |
| 3 | [`cubical/`](cubical/README.md) | F1 · L0–L5 (**7 sub-packages**) | 65 | 71,077 | 238 | The trusted dependent-cubical core: NbE, Kan, Glue, univalence, HITs, ROBDD/CDCL, elaborator, persistence |
| 4 | [`symlib/`](symlib/README.md) | F2 · L1 | 26 | 8,768 | 159 | Finite symmetry: individualisation–refinement, Schreier–Sims, canonical forms, `G`-sets & Burnside, categorification, Yoneda/Kan |
| 5 | [`semiring/`](semiring/README.md) | F3 · L1–L4 (**15 sub-packages**) | 38 | 9,778 | 161 | Idempotent/star/tropical semirings and a "types are theorems" algorithm library, plus the 19-section measurement report |
| 6 | [`topos/`](topos/README.md) | F4 · L2 | 6 | 6,767 | 140 | Grothendieck/elementary toposes: sites, sheaves, `Ω_J`, geometric morphisms, Diaconescu points, descent, cohomology, nerve homotopy |
| 7 | [`scheme/`](scheme/README.md) | F5 · L2 | 5 | 4,982 | 142 | Algebraic geometry: Gröbner bases, glued schemes, Kähler/Fitting, Serre duality, valuative truth test, Chow motives |
| 8 | [`condensed/`](condensed/README.md) | F6 · L3 (X-overlap hub) | 4 | 3,249 | 189 | Condensed mathematics: profinite towers, solid/liquid modules, Steenrod–Adams, persistent-invariant ledger, quaternion rotation axis, four conjectures |
| 9 | [`tensor/`](tensor/README.md) | F7 · L2 | 2 | 1,769 | 165 | Multilinear tensor geometry: the 6,561-tensor `𝔽₃` atlas, discrete Radon, Clifford spinors, non-crossing forests, VR homology |
| 10 | [`conjecture/`](conjecture/README.md) | F7 · L5 | 2 | 1,291 | 169 | Lakatos conjecture-evolution engine: automatic conservation-law discovery, out-of-sample transfer, five epistemic lenses, 12 cross-federation conjectures |
| 11 | [`bridge/`](bridge/README.md) | apex · L7 (upper-V apex `V₂`) | 15 | 5,428 | 211 | `K₇` 21/21 bridges, four-family rotation axis, five intuition-driven conjectures with counterexample attacks, geometry–logic atlas, 47/47 certificates |
| 12 | [`accel/`](accel/README.md) | F8 · L4 | 5 | 2,722 | 184 | CPU 64-bit SWAR (M4RI / GF(3) / Face) + Ozaki II / RNS NTT / Scanbox / HVM2 + 7 WGSL shaders |
| 13 | [`hostfs/`](hostfs/README.md) | F1 · L1 | 2 | 822 | 149 | Executable crash-consistency model (content `fsync` before the directory entry) + BFT `3f+1` quorum durable replicas |
| 14 | [`cmd/`](cmd/README.md) | 5 executables · L2–L8 | 10 | 3,844 | 136 | Theorem ledger (`129`), unification showcase (`47`) plus rotation-axis report, symmetry demo/bench, semiring measurement report (`§1–§19`) |
| 15 | [`tools/`](tools/README.md) | infrastructure (not a MoonBit package) | 0 | 0 | 96 | `arch_check.py`: federation partition, file ownership, `moon.pkg` imports, source reference graph, statistics |
| 16 | [`webgpu/`](webgpu/README.md) | F8 browser side | 0 | 0 | 98 | Zero-dependency single-page verifier: `navigator.gpu` detection, 6 WGSL audits, CPU-SWAR bitwise cross-check |

**Totals: 222 `.mbt` files, 152,883 lines** — identical to the `totals` printed by
`python3 tools/arch_check.py`. Per-federation breakdown from the same run:

| Federation | Packages | Files | Lines |
|---|---:|---:|---:|
| `cubical` | 11 | 108 | 103,095 |
| `symlib` | 3 | 29 | 9,671 |
| `semiring` | 16 | 43 | 12,577 |
| `topos` | 1 | 6 | 6,767 |
| `scheme` | 1 | 5 | 4,982 |
| `condensed` | 2 | 6 | 4,445 |
| `discovery` | 2 | 4 | 3,060 |
| `accel` | 1 | 5 | 2,722 |
| apex / unification | 2 | 16 | 5,564 |
| root package | 1 | 18 | 12,393 |

---

## 6. The 27 nested sub-packages

`cubical/`, `semiring/`, and `cmd/` are **package groups**: each nested folder is its own `moon.pkg`
with its own `README.md`. The three groups hold **113 `.mbt` files / 84,699 lines**; their READMEs total
**2,941 lines**.

### 6.1 `cubical/` — 7 sub-packages (65 files, 71,077 lines)

| # | Sub-package | Layer | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`cubical/face_bdd/`](cubical/face_bdd/README.md) | L0 | 5 | 6,209 | 140 | Two decision procedures for faces: ROBDD canonical form (`O(1)` equality) and CDCL proofs (DRUP/DRAT/LRAT) |
| 2 | [`cubical/finite/`](cubical/finite/README.md) | L1 | 4 | 1,828 | 141 | The finite universe: η-NbE, wiring, `ua` / `coe` / `PathP` / `Glue` / `J` — **the best entry point in the repository** |
| 3 | [`cubical/hermitian/`](cubical/hermitian/README.md) | L2 | 9 | 3,199 | 143 | Hermitian projectors and certifiable cubical filling (float → `QuadC` → `AlgC`) + the Karoubi envelope |
| 4 | [`cubical/kernel/`](cubical/kernel/README.md) | L2 | 20 | 30,899 | 180 | **The trust boundary**: dependent NbE, Kan, DSystem repair, inductive/HIT/open-IR schemas, ε₀ ordinals |
| 5 | [`cubical/elaborator/`](cubical/elaborator/README.md) | L3 | 4 | 5,514 | 143 | Bidirectional elaboration; higher-order **matching** (decidable) / bounded Huet search / Goldfarb undecidability certificate |
| 6 | [`cubical/homotopy/`](cubical/homotopy/README.md) | L3 | 14 | 12,281 | 189 | Computational homotopy: `π₁(S¹)≃ℤ`, `π₂(S²)≃ℤ`, `π₄(S³)≅ℤ/2ℤ`, Blakers–Massey, `Kₙ` coherence |
| 7 | [`cubical/store/`](cubical/store/README.md) | L5 | 9 | 11,147 | 184 | `CHMODBIN` / `CHDAGBIN` / `CHREGBIN`, version negotiation, Ed25519 WAL, SCC-atomic hot reload |

### 6.2 `semiring/` — 15 sub-packages (38 files, 9,778 lines)

| # | Sub-package | Layer | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`semiring/algebra/`](semiring/algebra/README.md) | L1 | 6 | 2,265 | 147 | Ten-trait hierarchy + `Ops` counter, seven concrete semirings, law checkers (with negative controls) |
| 2 | [`semiring/matrix/`](semiring/matrix/README.md) | L1 | 6 | 1,594 | 154 | Generic `Mat[E]`, six multiplications, four closures, CSR sparsity, automatic cache-parameter selection |
| 3 | [`semiring/graph/`](semiring/graph/README.md) | L2 | 4 | 569 | 104 | Bitset closure, functional decomposition, Dijkstra, multi-objective Pareto (partial order ⇒ Dijkstra is illegal) |
| 4 | [`semiring/io/`](semiring/io/README.md) | L2 | 1 | 153 | 58 | `Bytes`-direct parsing vs. the naive path, reproducible synthetic data |
| 5 | [`semiring/monoid/`](semiring/monoid/README.md) | L2 | 1 | 530 | 81 | Prefix scan / segment tree / sparse table / Fenwick — **four strengths, four type-class costs** |
| 6 | [`semiring/par/`](semiring/par/README.md) | L2 | 2 | 159 | 73 | Backend-agnostic parallelism contract: chunking, two-pass scan (elementwise identical to sequential) |
| 7 | [`semiring/sim/`](semiring/sim/README.md) | L2 | 2 | 261 | 96 | Parameterised cache model + access trace + `time_min` (minimum, not mean) |
| 8 | [`semiring/bp/`](semiring/bp/README.md) | L3 | 1 | 354 | 82 | Generalised distributive law: one program, `Prob` = sum-product, `TropMax` = MAP; exact on trees, error measured on cycles |
| 9 | [`semiring/cat/`](semiring/cat/README.md) | L3 | 3 | 554 | 100 | Free category (hom-sets), set matrices, decategorification (cardinality preserves multiplication), Maslov dequantisation |
| 10 | [`semiring/nf/`](semiring/nf/README.md) | L3 | 3 | 712 | 101 | DFA minimisation + canonical strings, Brzozowski derivatives, monoid word problem (two independent paths) |
| 11 | [`semiring/par_host/`](semiring/par_host/README.md) | L2 (platform ext.) | 1 | 112 | 69 | `supported_targets: native`; structured concurrency; **honestly states that one thread does not speed up CPU work** |
| 12 | [`semiring/ratelimit/`](semiring/ratelimit/README.md) | L3 | 2 | 489 | 97 | GCRA with a single `tat` cell + hierarchical limiting + eviction counters |
| 13 | [`semiring/spline/`](semiring/spline/README.md) | L3 | 1 | 348 | 71 | Periodic cubic splines in three agreeing solvers; the monoid (`AffineM`) path solves no linear system |
| 14 | [`semiring/trop/`](semiring/trop/README.md) | L3 | 3 | 1,307 | 115 | Tropical polynomial roots with multiplicity, Newton polytope dual subdivision (integer area conservation), `trop_det` three ways |
| 15 | [`semiring/app/`](semiring/app/README.md) | L4 | 2 | 371 | 79 | Transitive closure (three agreeing algorithms) + one matrix, two semirings, two different answers |

### 6.3 `cmd/` — 5 executables (10 files, 3,844 lines)

| # | Sub-package | Target | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`cmd/main/`](cmd/main/README.md) | all | 1 | 6 | 57 | A six-line entry point: the `Bool` from `print_report()` becomes the exit code |
| 2 | [`cmd/showcase/`](cmd/showcase/README.md) | all | 1 | 136 | 66 | Narrative output for seven federations × `K₇` 21/21 × double-V plus the quaternion rotation axis, each with a quantitative witness |
| 3 | [`cmd/symdemo/`](cmd/symdemo/README.md) | all | 1 | 309 | 65 | `symlib` demo: "derived vs. direct" two-path agreement + monad laws |
| 4 | [`cmd/symbench/`](cmd/symbench/README.md) | all | 2 | 594 | 88 | 12-case full-pipeline timing + seven derived-algorithm families (A–G) with `OK/FAIL × cost ratio` |
| 5 | [`cmd/semiringreport/`](cmd/semiringreport/README.md) | **native only** | 5 | 2,799 | 118 | The 19-section measurement report; §19 turns every limitation into a measured number |

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

**Just need to run something** — `moon run --release cmd/main --target wasm-gc` (129/129 theorems),
`moon run --release cmd/showcase --target wasm-gc` (47/47 certificates),
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

1. `python3 tools/arch_check.py` → confirm `222 .mbt files, 152883 .mbt lines` on your machine. This is
   your baseline; every later claim of "unchanged architecture" is measured against it.
2. `moon check --deny-warn --target wasm-gc` → must be silent.
3. `moon run --release cmd/main --target wasm-gc` → must end at `129/129`.
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
