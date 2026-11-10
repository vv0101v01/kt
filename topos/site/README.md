# `topos/site` — Lightweight Grothendieck Sites, `Sieve64` SWAR Bi-Heyting Kernel & Sheaf Logic

Layer-2 foundation package of **Federation 4 (`topos`)** decoupled from rational linear algebra (`@exactalg`), depending only on `gcd`, `symlib`, and `accel/swar`:

1. **`Sieve64` & `SitePrecomp64` (`sieve64_swar.mbt`)**:
   - Encodes sieves on finite sites (`|Mor(C)| ≤ 64`) in a single `UInt64` word, executing intersection (`&`), union (`|`), inclusion, Heyting implication `(S ⇒ T)`, co-Heyting subtraction `(S ⇐ T)`, Lawvere boundary `∂S`, and double-negation nucleus `¬¬S` in `O(1)`–`O(popcnt)` register bitwise ops.
2. **MAC Forward-Checking Matching-Family Solver (`enumerate_matching_families_mac64`)**:
   - Propagates naturality constraints `P.res[g](x_f) = x_{f ∘ g}` eagerly on partial matching families.
3. **Sites, Sheafification `(−)⁺⁺`, CCC Exponentials `G^F`, `Ω_J`, Geometric Morphisms & Classifying Topoi**:
   - Houses `site_presheaf.mbt`, `sheaf_ccc_omega.mbt`, `geometric_morphism_local_properties.mbt`, and `logic_classifying_categorify.mbt`, all transparently re-exported by `@topos`.
