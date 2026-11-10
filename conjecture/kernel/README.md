# `conjecture/kernel` — Layer-3 Decoupled Algorithmic Discovery Kernel

Lightweight (`L3`) core of **Federation 7 (`discovery`)** depending only on `gcd`, `accel/swar`, and `tensor`:

1. **Half-GCD Modular Rational Reconstruction (`half_gcd_rat_recon`)**:
   - Wang–Guy–Davenport `O(log p)` Euclidean truncation (`2 r_k^2 < p`, `2 t_k^2 < p`) recovering exact signed integer conservation laws `[E-Derive]` with arbitrary denominators `< √(p/2)`.
2. **64-Bit Bitplane Implication Lattice (`implication_lattice_build`)**:
   - Packs finite-model predicate truth vectors into `UInt64` bitplanes and extracts both `implies[i][j]` and exact minimal counterexample IDs via `(w << 6) + (plane_i[w] & ~plane_j[w]).ctz()`.
