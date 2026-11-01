# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
  `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
  `find-references`. See $moonbit-agent-guide for details.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
  are stable or very unlikely to change. For snapshot tests that record
  structured debugging output, derive `Debug` and use `debug_inspect`, rather
  than deriving `Show` for debugging. For solid, well-defined results (e.g.
  scientific computations), prefer assertion tests. You can use
  `moon coverage analyze > uncovered.log` to see which parts of your code are
  not covered by tests.

## This project (cubical-hermitian — Double-V, X-Overlap & Star-Prism 7-Federation Architecture)

- Governance documents (`AGENTS.md`, `ARCHITECTURE.md`, `SPEC.md`, `docs/BRIDGE.md`) are living, mutable engineering records that evolve alongside mathematical and architectural refactorings.
- **Double-V (`V₁ → X → V₂`) & Lakatosian Discovery Package Topology (31 packages, 49 components across layers `0..6`)**:
  - Layer `0` (`V₁` Lower Apex): `gcd` (Universal Elimination-GCD: `F_p` RREF, `ℤ` HNF/SNF, multi-domain Bézout & subspace double-annihilator GCD).
  - Layers `1..2` (Divergent Arms): `algebra`, `hostfs` (crash-durability & BFT quorum), `symlib`, `semiring/*`, `topos`, `scheme`, `tensor` (Federation 7 Layer 2: `F_3` 6,561-tensor atlas, discrete Radon, Clifford/gauge spinors, non-crossing site & VR homology).
  - Layer `3` (`X` Central Pivot — Federation 6): `condensed` (`CondCategory`, `CanonElimCategory`, 4 condensed higher structures, Steenrod–Adams `2η=0`, SNF conservation ledger, and 4-conjecture base lab).
  - Layer `4` (Convergent Root & Conjecture Engine): `root` (`cubical-hermitian`) and `conjecture` (Federation 7 Layer 4: 6 evolutionary transfer laws, 5 epistemic lenses, and 12-entry Lakatosian Conjecture Atlas `CONJ-01..CONJ-12`), every `.mbt` file owned by one component in `architecture.json`.
  - Layers `5..6` (`V₂` Upper Apex): `bridge` (`K_7` = 21/21 cross-federation bridges, `[T-X-Chiasmus]`, Star-Prism synthesis, 46/46 Grand Unification certificates), `cmd/main`, `cmd/showcase`.
- Acceptance gates (all must pass):
  `moon fmt`, `moon info --target wasm-gc`, `moon check --deny-warn --target wasm-gc`,
  `moon test --release --target wasm-gc` (`21/21`), `moon run --release cmd/main --target wasm-gc` (`129/129`),
  `moon run --release cmd/showcase --target wasm-gc` (`46/46`), `python3 tools/arch_check.py`,
  `python3 tools/audit_spec.py --check` (`7303` symbols).
- Note on MoonBit `--deny-warn` (`moonc v0.10.18+`): public types deriving `Debug` or `Eq` should explicitly declare `pub extend <Type> with @moonbitlang/core/debug.Debug::{to_repr}` and `pub extend <Type> with Eq::{not_equal, equal}` to keep generated `.mbti` traits warning-free.
- New public symbols must be classified in `tools/audit_spec.py`
  (the bilingual `SPEC-APPENDIX*.md` files are generated via `--write`, never hand-edited)
  and, when they carry a checkable law, registered in `verify.mbt`
  and `spec.mbt`. Counts in prose docs come from the tools, not by hand.
- Artifact-chain trust anchors are `expected_head~ : (Int32, Int32)?`.
  Never replace this with `-1` sentinels: the repository's overflowing
  Int32 dual hashes can legitimately be negative.
