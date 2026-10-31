// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "vv0101v01/cubical-hermitian"

version = "0.0.1"

readme = "README.mbt.md"

repository = "https://github.com/vv0101v01/kt"

license = "Apache-2.0"

keywords = [
  "cubical",
  "hermitian",
  "projector",
  "kan",
  "nbe",
  "univalence",
  "hoas",
  "glue",
]

preferred_target = "wasm"

description = "Hermitian projectors meet a dependent cubical kernel in MoonBit: NbE, type-directed Kan coe/comp, inductive/HIT schema generators, computational univalence certificates, exact BigInt algebra, BDD/DPLL decisions."

import {
  "moonbitlang/async@0.22.5",
}
