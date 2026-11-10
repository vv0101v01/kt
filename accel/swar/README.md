# `accel/swar` — Layer-0 64-Bit SWAR Bit-Parallel Primitives

Zero-dependency (`L0`) register-level SWAR substrate in **Federation 8 (`accel`)** shared downward by **F4 (`topos`)**, **F7 (`discovery`)**, and **F8 (`accel`)**:

1. **Boothby–Bradshaw Dual-Rail 64-Trit `GF(3)` Arithmetic (`Gf3Slice64`)**:
   - Branchless 64-lane `gf3_add64`, `gf3_neg64`, `gf3_sub64`, `gf3_mul64`, and `gf3_sweep_all_6561_hyperdets` evaluating all `3^8 = 6,561` `2×2×2` Cayley hyperdeterminants in `103` 64-trit iterations.
2. **64-Bit Bi-Heyting Sieve Operators**:
   - `swar_downset_closure64`, `swar_heyting_impl64`, and `swar_coheyting_sub64` implementing Grothendieck sieve generation, Heyting implication `(S ⇒ T)`, and co-Heyting subtraction `(S ⇐ T)` via `ctz` bit-stripping in `O(popcnt)`.
3. **64-Sample-Per-Word Epistemic Bitplane Implication**:
   - `swar_pack_bitplane` and `swar_bitplane_implication_cex` computing exact implication matrices and minimal counterexample indices via `(w << 6) + (plane_i[w] & ~plane_j[w]).ctz()`.
4. **M4RI `GF(2)` Gray-Code GEMM & Word-Parallel RREF (`m4ri_gf2.mbt`)**:
   - `Gf2BitMatrix`, `m4ri_gf2_mul`, and `gf2_rref_eliminate_u64` (`64` columns per `UInt64` word; powers Faugère F4 Boolean Gröbner bases in `scheme`).
5. **Ozaki Scheme II `INT8 DP4A` CRT GEMM & 32-Bit RNS Stockham NTT (`ozaki2_ntt_rns.mbt`)**:
   - `ozaki2_int_gemm_dp4a`, `ozaki2_f64_gemm`, `montgomery30_mul`, `stockham_ntt_mod`, and `poly_mul_rns_ntt` (powers `algebra/core` `qmat_mul_ozaki2_crt`).
6. **64-Way Cube Degeneracy Pairing, Scanbox Morton Prefix Scan & HVM2 Flat-Arena Interaction Combinators**:
   - `cubical_degeneracy_core.mbt`, `scanbox_morton_core.mbt`, and `hvm2_inet_arena.mbt` (`INetArena` + closed Peano `λ`-term optimal evaluator `inet_eval_closed_peano_lam`).

