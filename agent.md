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
`preferred_target = "wasm"`, **10 federations (9 in the dual-V graph + `ualg` in parallel) + 1 unification apex**,
**57 packages**, **66 components**, **321 `.mbt` files**, **202,287 lines** (verified by `python3 tools/arch_check.py`, 2026-11-12 K₁₀ round).

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
`architecture ok: 9 federations + unification apex, 52 packages, 61 components, …`.

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
end-to-end run — `moon run cmd/main --target wasm-gc` (`139/139` theorems),
`moon run cmd/metatheory --target wasm-gc` (`631/631` laws), and
`moon run cmd/showcase --target wasm-gc` (`48/48` historical certificates + `K_10 = 45/45` constructive bridges, incl. 9 `ualg` edges and 6 structural replacements).
(Local 2026-11-12 re-run after the K₁₀ round and the De Morgan conversion fix; historical merge note in §5 is superseded for these counts.)

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
  `architecture.json` components, the theorem registry counts (`139/139`), the metatheory law counts
  (`631/631`), the certificate ledger (`48/48`), the `K₁₀ = 45/45` bridge counts (historical `K₉ = 36/36` subgraph), `ATLAS-01..18`,
  the 7-entry resolved conjecture atlas (`CONJ-02..06/09/10`), the `agent.v2.md` rules themselves, and the per-folder `README.md` set mapped in Part II
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

## 5. The 18 top-level folders

`.mbt` counts and line counts are the on-disk truth for that folder, **recursive**, measured 2026-11-11
post-merge (`find <folder> -name '*.mbt' | xargs cat | wc -l`):

| # | Folder | Federation · layer | `.mbt` | Lines | What it is |
|---:|---|---|---:|---:|---|
| 1 | [`gcd/`](gcd/README.md) | F6 · L0 (lower-V apex `V₁`) | 3 | 1,683 | Five-domain generic elimination GCD: 16-lane lazy `F_p` RREF, HMM `ℤ`-SNF, Bareiss det, modular HNF, CRT, Wang rational recon & digest chain |
| 2 | [`algebra/`](algebra/README.md) | F1 · L1–L2 (`algebra/core` + `algebra`) | 23 | 19,220 | Exact rational/algebraic tower (`Rat` `Int64` fast path, Bareiss/Ozaki-II `QMat`, complete factorization, number fields, Jordan, certified intervals, transcendence) |
| 3 | [`cubical/`](cubical/README.md) | F1 · L0–L6 (**9 sub-packages**) | 82 | 83,245 | Trusted dependent-cubical core: Kalman free De Morgan `I_DM`, CCHM `Cofib(n)`, NbE, Kan, Glue, univalence, HITs, `O(Δ)` HOU, BFT/MVCC store, universal algebra autonomy & all 54 higher cubical structures (zero piggybacking) |
| 4 | [`symlib/`](symlib/README.md) | F2 · L0–L1 (`symlib/core` + `symlib`) | 27 | 8,927 | Finite symmetry: hardware `popcnt` `BitVec`, unbounded `PermLut`, Schreier–Sims, McKay search, Holt arbitrary-rank subgroup lattices, Burnside Möbius & groupoid Yoneda/Kan |
| 5 | [`semiring/`](semiring/README.md) | F3 · L1–L4 (**15 sub-packages**) | 40 | 11,077 | `@swar` Bool/GF(2) GEMM, 3D gift-wrapping Newton subdivision, Karp tropical eigenpairs, Johnson negative-weight APSP, Min-Fill VE & Hopcroft `O(‖Σ‖‖Q‖log‖Q‖)` minimal DFA |
| 6 | [`topos/`](topos/README.md) | F4 · L2–L3 (`topos/site` + `topos`) | 10 | 8,607 | Grothendieck sites, `Sieve64` SWAR bi-Heyting kernel, MAC matching families, `¬¬` Boolean sheafification, Alexandrov/Chu dualities, geometric morphisms, Torsors & cohomology |
| 7 | [`scheme/`](scheme/README.md) | F5 · L3 | 6 | 6,150 | `Mono64` SWAR, Yan geobuckets, M4RI Boolean F4, multi-prime CRT modular F4, Grassmann–Plücker det, glued schemes, Kähler/Fitting, Serre duality & Chow motives |
| 8 | [`condensed/`](condensed/README.md) | F6 · L1–L4 (`condensed/core` + `condensed`) | 5 | 3,376 | Profinite towers, constructive Nöbeling unimodular basis, Roos–Milnor `R¹lim`, solid/liquid modules, 64× `@swar` Steenrod–Adams (`h₃=σ`, `η³=4ν`) & analytic stacks |
| 9 | [`tensor/`](tensor/README.md) | F7 · L2 | 2 | 2,151 | 64-trit `𝔽₃` 6,561-tensor rank atlas `[1, 128, 4032, 2400]`, MRV/MAC exact Gromov–Hausdorff, dominated VR collapse, Radon & Clifford spinors |
| 10 | [`conjecture/`](conjecture/README.md) | F7 · L3–L5 (`conjecture/kernel` + `conjecture`) | 3 | 1,436 | Half-GCD rational reconstruction, 64-bit `ctz` bitplane implication lattice, Lakatos conjecture-evolution engine & 12 cross-federation conjectures |
| 11 | [`bridge/`](bridge/README.md) | apex · L8 (upper-V apex `V₂`) | 22 | 9,554 | **`K₁₀ = 45/45` constructive all-pairs bridges** (9 `ualg` edges + 13 nominal-bridge replacements in two waves), `F7→F9→F4→F1` promotion, `F8×F5×F1` & `F2×F3×F6` triads, 18-entry geometry–logic atlas, 48/48 historical certificates + K₁₀ certificate |
| 12 | [`accel/`](accel/README.md) | F8 · L0–L4 (`accel/swar` + `accel`) | 11 | 3,887 | `L0` 64-bit SWAR primitives (M4RI RREF, 64-trit `GF(3)`, Ozaki-II CRT, Stockham NTT, Cube64 butterfly, Scanbox, HVM2 `INetArena`) + 8/8 portable WGSL shaders |
| 13 | [`hostfs/`](hostfs/README.md) | F1 · L1 | 2 | 818 | Executable crash-consistency model (`fsync` ordering) + BFT `3f+1` quorum durable replicas |
| 14 | [`meta/`](meta/README.md) | F9 · L0–L2 (**4 library sub-packages** + `cmd/metatheory`) | 33 | 17,115 | Zero-business-dependency metatheory floor & three-axis engine: Paterson–Wegman DAG MGU, Bareiss, SLG tabling, bidirectional E-graph QIIT, NbE reflection, `V₅ = 65,536` HF64, Vogt/HS realignment & Paley Ramsey |
| 15 | [`cmd/`](cmd/README.md) | 6 executables · L2–L9 | 12 | 4,076 | `cmd/main` (`139/139`), `cmd/metatheory` (`631/631`), `cmd/showcase` (`48/48` + `K₁₀=45/45`), `cmd/symdemo`, `cmd/symbench`, `cmd/semiringreport` (`§1–§19`) |
| 16 | [`tools/`](tools/README.md) | infrastructure (not a MoonBit package) | 0 | 0 | `arch_check.py`: federation partition, file ownership, `moon.pkg` imports, source reference graph, statistics |
| 17 | [`webgpu/`](webgpu/README.md) | F8 browser side | 0 | 0 | Zero-dependency browser verifier for all 8 registered WGSL compute shaders + CPU-SWAR bitwise cross-check |
| 18 | [`ualg/`](ualg/README.md) | F10 · L0–L3 (**4 sub-packages** + `cmd/ualg`) | 22 | 7,756 | Constructive universal algebra × presheaf template × De Morgan cubes (congruence lattices/quotients, Mal'cev terms, Rees quotients, nuclei, `¬¬`-sheafification as counted left adjoint; free De Morgan algebras `DM(n)`; cubical double-negation nucleus; Glivenko). Parallel to the dual-V graph; **not wired into `K₉`**; Lean-side counterpart: `lean/KtLaws/Instances/ImportGraph.lean` (O5 logic core, green, unregistered) |

> **2026-11-11 merge note.** Row 18 (`ualg/`) is local-side work (rounds 5–7) that shares ancestor 84266c0 with the
> remote line's S1–T4 refactor; both were merged on 2026-11-11. Remote's pre-merge table (286 `.mbt`, 185,986 lines) and
> local's (222 `.mbt`, 152,883 lines) are both **superseded** by the post-merge reality measured by
> `python3 tools/arch_check.py`: **10 federations + unification apex · 57 packages · 66 components · 318 `.mbt` files ·
> 199,215 lines**. Remote's MoonBit claims (139/139, 565/565, 48/48, 5,810 fns `0` dead code, four-target zero-warning
> `moon check`) are **carried from remote's 2026-11-10 verification and have NOT been re-run on this merged tree**
> (no `moon` toolchain in this sandbox). Re-run before trusting them.
> **Superseded 2026-11-12**: the merged tree has since been re-run locally — `139/139`, `631/631`, `167/167`,
> `48/48` + `K₁₀ = 45/45`, `architecture ok` (321 `.mbt`, 202,287 lines). The historical numbers above are kept only as a record.
>
> **2026-11-10 note.** Row 17 was extended on 2026-11-10 (same day) with `ualg/cube/` (L2): cubical sheafification
> (`Sh_¬¬(□ⁿ) ≃ Set^{頂點}`) and the cubical double-negation nucleus (Glivenko, Ω_¬¬ size formula). `cmd/ualg` moved to L3.
> The heading count ("16"), the totals line below and the per-federation table still predate both `meta/` and `ualg/`;
> the current on-disk truth is the output of `python3 tools/arch_check.py`: **10 federations, 49 packages, 58 components,
> 271 `.mbt` files, 173,471 lines**.
>
> **2026-11-10 note (round 3).** The fourth federation `meta/` (47→**67** `law_*` functions, **527/527** laws,
> counter-distribution core 126／instances 169／iit 173／reflect 59, 430 distinct labels, 123 families) closed its
> four open items: STLC η (`stlc_eta`, x ∉ FV(f) made decidable as "no `vz` node in f", index-preservation re-measured),
> the matroid criterion's (⇐) side upgraded from 12-sample comparison to **per-instance certificates** verified by
> construction-independent checks + 2^n exhaustive rank reconciliation (n ≤ 12), multi-target mirror rules handled by a
> **co-derivation** (`forward_least_model`, forward fixed-point closure, three-valued honest `None`) with `mirror_exact`
> as the executable precondition of the mirror law (a measured counterexample pins down that naive mirroring is
> two-sided wrong for ≥ 2 premises), and the **R(4,5) ≥ 25 lower bound** certified by the published McKay–Radziszowski
> `r45_24.g6` first-graph witness embedded in the tree (124 edges; re-verified by two independent algorithms).
> Upper bound for R(4,5) remains 32 (recursion bound); R(5,5) untouched. `cmd/metatheory` now prints `通過 527 / 527 定律`.

> **2026-11-10 note (round 4).** `meta/iit/sn.mbt`: STLC 逐項 SN certificates — full-tree exhaustive β∪η
> (`stlc_one_step_reducts`, **all positions**, structural dedupe); `stlc_sn_depth` returns `Some(k)` = every
> reduction path ≤ k certified by complete exploration, or `None` over budget (**not** "not SN");
> `stlc_sn_tree_typed` re-checks `icheck` at every node of the tree. Measure (longest-path depth) strictly
> decreases along every step (battery law). Exact small depths: id=0, app1=1, app2=1, eta_deep=1, k_app=2;
> `two_positions` = exactly 2 distinct one-step reducts (after redesign — the first construction had three
> routes converging to the same term). **Not a universal SN theorem** (Tait–Girard/logical relations belong
> to Lean; frozen). R(4,5) ≥ 25 witness re-audited byte-level vs upstream `r45_24.g6` line 1 (independent
> decoder: n=24, 276 data bits exactly consumed, 124 edges, degrees 9×2/10×12/11×10; masks bit-identical;
> upper bound stays 32; R(5,5) untouched). Suite now **551/551** (73 `law_*` fns); labels regenerated:
> **551 條／453 互異／146 族** (iit 197 條／119 互異); `arch_check` → **272 .mbt / 173,944 行**.
> Push deferred to a later user instruction (no remote configured in sandbox; .git/config lost).
> Reminder: after any `/var/tmp` cleanup, run `. /home/user/moon_env.sh && moon update` before building.

> **2026-11-10 note (round 5).** Lean unfreezes and round 5 lands the Lean backlog's first obligation:
> **O4 done, honestly** — the WHY.md draft `orientable e → WellFounded (Rewrites e)` (node-count
> orientation, kt's `orientable`) is *false*: `h(f x, y) ⇒ g(y, y)` is oriented at `uSize` (4 > 3) with
> Vars(body) ⊆ Vars(head), yet the substitution y ↦ `ufn 7 [ufn 0 [], ufn 0 []]` makes one root step
> grow a term from 6 to 7. Honest delivery: `lean/KtLaws/Instances/Termination.lean` (316 lines) proves
> the sound restricted criterion (`measureDecreasing`: pointwise `varsOf` count domination + strict ufn
> decrease ⇒ every rewrite step shrinks `uSize` ⇒ `WellFounded (Rewrites e)`), verifies `envShow`'s four
> rules instance-wise (`envShow_terminating`), and ships the counterexample as a kernel-checked negative
> asset (`kt_node_measure_orientation_unsound`). **2026-11-10 update (round 6):** user ordered the toy
> `Reflect/Universe.lean` **deleted with no archive** （不另作保存） — deletion landed; the four pure-`decide`
> files were kept （裁決 universe_only）. Registry 505 → **464**; UNIVERSAL 146 → **134**; full rebuild green.
> Note: round-5 commit objects were lost with the pre-6 snapshot (HEAD reset to 2c0350b); the worktree
> content all survived and was re-committed in round 6. **O1–O6 mandate (full_kernel)**: every obligation
> must build green with no `sorry` and registry entry — not just the two “easiest”. O4 stands done
> (round 5). **O1 is not done**: O1 needs a full logical
> relation (1–2 wk), O2 SLD-completeness (2–3 wk), O3 QIIT respectfulness (3–4 wk), O5 SCC-from-scratch
> (no mathlib, ~1 wk), O6 club intersection (no mathlib, 1–2 wk). No `sorry` passes anything off as done.
> MoonBit side untouched; **not pushed**.
>
> **2026-11-11 update (round 7):** user ordered O1 next （「接著進行O1」）. **O1 is still not done** —
> but its `isBetaNormal` half landed as a **kernel-green, registry-checked** structural theorem
> (`KtLaws/Reflect/NfNormal.lean`, 110 lines): `reifyN_isBetaNormal` (mutual induction on fuel — for *all*
> fuel/types/values, reify output is β-normal with lam-free head), `nf_isBetaNormal`, and `nf_beta_normal`
> (`check Γ t A = true → isBetaNormal (nf A t) = true`, same statement shape as O1; the hypothesis is
> unused — the result is stronger). `KtLaws.lean` + `Registry.lean` updated (464 → **466**, two `#check`s).
> The **idempotency half (`nf (nf t) = nf t`) is not done** and remains honest-open: it needs a full
> reducibility/logical relation (NbE soundness under βη), 1–2 weeks. O2's status is unchanged: its on-disk
> `hasBody_ne` statement is itself unprovable (k = 0, bs = [] ⇒ LHS true, RHS false); a fix (uniform-fuel
> statement) is identified but not landed; `Instances/SldComplete.lean` stays red and is not counted.
> Same-day doc recount (2026-11-11): WHY.md/UNIVERSAL.md per-file line counts fixed to `wc` truth
> (9,326 total excl. barrel; was 8,932), missing `SldComplete.lean`/`ImportGraph.lean` rows added;
> ImportGraph's 7 universal theorems now counted (全稱 137→**144**, 宣告 562→**573**, 其他 43→**47**),
> marked 未入桶未登記； lean/README、root README、coverage.md、CAPABILITIES.md synced (Registry 466;
> Universe toy-model mention removed from root README). MoonBit side untouched; **not pushed**.

**合併截面總計（`python3 tools/arch_check.py`，2026-11-11）：`10` 聯邦 + `unification` apex · `57` packages · `66` components · `318` `.mbt` files · `199,215` lines。**

| Federation | Packages | Files | Lines |
|---|---:|---:|---:|
| `cubical` (incl. root, `algebra`, `hostfs`, `cmd/main`) | 14 | 126 | 116,167 |
| `symlib` | 4 | 30 | 9,830 |
| `semiring` | 16 | 45 | 13,885 |
| `topos` | 2 | 10 | 8,607 |
| `scheme` | 1 | 6 | 6,150 |
| `condensed` | 3 | 8 | 5,059 |
| `discovery` | 3 | 5 | 3,587 |
| `accel` | 2 | 11 | 3,887 |
| `meta` | 5 | 34 | 17,246 |
| `ualg` | 5 | 23 | 7,813 |
| `unification` (apex) | 2 | 20 | 6,984 |

---

## 6. The 40 nested sub-packages

`cubical/`, `semiring/`, `cmd/`, and `meta/` are package groups, joined by the 6 decoupled lightweight core sub-packages (`symlib/core`, `algebra/core`, `condensed/core`, `topos/site`, `conjecture/kernel`, `accel/swar`). Every nested folder is its own `moon.pkg` with its own `README.md`.

### 6.1 `cubical/` — 9 sub-packages (80 files, 81,437 lines)

| # | Sub-package | Layer | `.mbt` | Lines | README | What it is |
|---:|---|---|---:|---:|---:|---|
| 1 | [`cubical/face_bdd/`](cubical/face_bdd/README.md) | L0 | 6 | 6,705 | 148 | Kalman free De Morgan `I_DM`, free CCHM `Cofib(n)`, `UInt64` SWAR fast path, ROBDD (`O(1)` eq) & CDCL (DRUP/DRAT/LRAT) |
| 2 | [`cubical/finite/`](cubical/finite/README.md) | L1 | 4 | 1,834 | 141 | The finite universe: η-NbE, wiring, `ua` / `coe` / `PathP` / `Glue` / `J` — **the best entry point in the repository** |
| 3 | [`cubical/hermitian/`](cubical/hermitian/README.md) | L3 | 9 | 3,201 | 143 | Hermitian projectors and certifiable cubical filling (float → `QuadC` → `AlgC`) + the Karoubi envelope |
| 4 | [`cubical/kernel/`](cubical/kernel/README.md) | L2 | 20 | 30,968 | 180 | **The trust boundary**: dependent NbE, Kan, DSystem repair, inductive/HIT/open-IR schemas, ε₀ ordinals |
| 5 | [`cubical/elaborator/`](cubical/elaborator/README.md) | L3 | 4 | 5,610 | 145 | Bidirectional elaboration; `O(Δ)` Trail-Stack HOU / higher-order matching / Goldfarb undecidability certificate |
| 6 | [`cubical/homotopy/`](cubical/homotopy/README.md) | L3 | 14 | 12,264 | 189 | Computational homotopy: `π₁(S¹)≃ℤ`, `π₂(S²)≃ℤ`, `π₄(S³)≅ℤ/2ℤ`, Blakers–Massey, `Kₙ` coherence |
| 7 | [`cubical/store/`](cubical/store/README.md) | L3 | 9 | 11,193 | 184 | `CHMODBIN` / `CHDAGBIN` / `CHREGBIN`, version negotiation, Ed25519 BFT WAL, SCC-atomic MVCC hot reload |
| 8 | [`cubical/autonomy/`](cubical/autonomy/README.md) | L5 | 5 | 2,645 | 85 | Constructive universal algebra autonomy, Mal'cev congruences/quotients, affine & bi-De Morgan cubical duality, Moore free paths, degeneracy trees, 5D alternating boundaries, bidirectional NF pruning & `¬¬` presheaf gluing |
| 9 | [`cubical/structures/`](cubical/structures/README.md) | L6 | 9 | 7,017 | 115 | All 54 higher cubical structures with dedicated non-aliased realizations (CCHM `Glue`, Vogt 2-cell HAE, HS `U8` universe realignment, Klein pushout torsion, `Σ⊣Ω`, `T²≃S¹×S¹`, CwF subst, reduction-free NbE, connections, 3D open box, Swan `Id`, `65,536` EZ split, `LJF`, poly SIP, `S₃` Galois cover, HOU repair & reflection) + 26×14 atlas |

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
| 1 | [`cmd/main/`](cmd/main/README.md) | all | 1 | 6 | 57 | Entry point for the `139/139` theorem ledger (`print_report()`) |
| 2 | [`cmd/metatheory/`](cmd/metatheory/README.md) | all | 1 | 125 | 31 | Ninth Federation entry point recomputing all `631/631` metatheory laws across `104` `law_*` functions |
| 3 | [`cmd/showcase/`](cmd/showcase/README.md) | all | 1 | 221 | 66 | Ten federations × `K₁₀ = 45/45` × three cross-federation triads/pipelines × `48/48` historical certificates + K₁₀ certificate + 7/7 wave-2 nominal-bridge elimination gate |
| 4 | [`cmd/symdemo/`](cmd/symdemo/README.md) | all | 1 | 309 | 65 | `symlib` demo: "derived vs. direct" two-path agreement + monad laws |
| 5 | [`cmd/symbench/`](cmd/symbench/README.md) | all | 2 | 594 | 88 | 12-case full-pipeline timing + seven derived-algorithm families (A–G) |
| 6 | [`cmd/semiringreport/`](cmd/semiringreport/README.md) | **native only** | 5 | 2,813 | 118 | The 19-section measurement report; §19 turns every limitation into a measured number |
| 7 | [`cmd/ualg/`](cmd/ualg/README.md) | all | 1 | 57 | 55 | Federation-10 law table: recomputes and prints the propositions of `ualg/core`, `ualg/site`, `ualg/demorgan`, `ualg/cube`; aborts if any is false (local-side, 2026-11-10) |

### 6.4 `meta/` & decoupled lightweight core sub-packages — 10 sub-packages (54 files, 30,233 lines)

| # | Sub-package | Layer | `.mbt` | Lines | What it is |
|---:|---|---|---:|---:|---|
| 1 | [`meta/core/`](meta/core/README.md) | L0 | 13 | 5,198 | Ordinals, `Int64` Bareiss, Paterson–Wegman linear DAG MGU, matroids, complexes, Paley Ramsey (`R(4,4)=18, R(3,5)=14`), Vogt HAE, HS realignment & universal algebra laws |
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

**Just need to run something** — `moon run cmd/main --target wasm-gc` (139/139 theorems),
`moon run cmd/metatheory --target wasm-gc` (631/631 laws),
`moon run cmd/showcase --target wasm-gc` (48/48 historical certificates + K_10=45/45),
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

1. `python3 tools/arch_check.py` → confirm `10 federations + unification apex, 57 packages, 66 components, 321 .mbt files, 202287 .mbt lines` on your machine. This is
   your baseline; every later claim of "unchanged architecture" is measured against it.
2. `moon check --deny-warn --target wasm-gc` → must be silent.
3. `moon run cmd/main --target wasm-gc` → must end at `139/139` (`cmd/metatheory` → `631 / 631`).
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
