# 全代碼健檢報告（自動產生）

由 `python3 tools/health_scan.py`（v3）產生（含遞移死碼不動點、`Type::method` 精確呼叫匹配、
排除自遞迴／`spec.mbt`／`facade.mbt`／`reexport_*`／`extend` 虛假引用、純函式體與私有助手 α 等價查重）。
此檔是**報告**，不是閘門；閘門仍是 `moon check --deny-warn` + `python3 tools/arch_check.py`。

## 0. 規模

| 項目 | 數量 |
|---|---|
| 掃描到的函式／方法定義 | 6271 |
| 完全無引用函式／方法（遞移死碼候選） | 40 |
| 完全無引用型別（`struct`/`enum`/`type`/`trait`） | 0 |
| 空殼列舉（`enum Foo {}`） | 0 |
| 完全相同或同包 α 等價函式體的重複組 | 1 |
| 結構極相近的重複組 | 4 |

## 1. 死碼候選（全倉零引用函式／方法／型別／空殼）

| 檔案 | 行 | 可見性 | 名稱 |
|---|---|---|---|
| `cubical/kernel/schema_open_ir.mbt` | 1181 | pub | `dopen_arg_external` |
| `cubical/kernel/schema_open_ir.mbt` | 1191 | pub | `dopen_arg_decoded_val` |
| `cubical/kernel/schema_open_ir.mbt` | 1287 | pub | `dopen_val_term` |
| `semiring/algebra/lattice_instances.mbt` | 378 | pub | `CyclicSet::of_range` |
| `semiring/algebra/lattice_instances.mbt` | 394 | pub | `CyclicSet::cardinality` |
| `semiring/algebra/laws.mbt` | 129 | priv | `law_check_star` |
| `semiring/algebra/laws.mbt` | 207 | pub | `check_star` |
| `semiring/app/wasm_verify.mbt` | 15 | pub | `verify_semiring_wasm_suite` |
| `semiring/bp/factor.mbt` | 361 | priv | `combine_and_eliminate_var` |
| `semiring/bp/factor.mbt` | 420 | pub | `bp_exact_marginal_ve` |
| `semiring/bp/factor.mbt` | 524 | pub | `bp_exact_all_marginals_ve` |
| `semiring/cat/free.mbt` | 191 | pub | `DiGraph::hom_setmat` |
| `semiring/cat/setmat.mbt` | 102 | pub | `smat_plus` |
| `semiring/graph/dijkstra.mbt` | 148 | pub | `bellman_ford_potentials` |
| `semiring/graph/dijkstra.mbt` | 179 | pub | `apsp_johnson` |
| `semiring/matrix/blocking.mbt` | 78 | pub | `mul_blocked_auto` |
| `semiring/matrix/csr.mbt` | 38 | pub | `Csr::row_range` |
| `semiring/matrix/csr.mbt` | 166 | pub | `csr_mul` |
| `semiring/matrix/mat.mbt` | 49 | pub | `Mat::from_flat` |
| `semiring/matrix/mat.mbt` | 73 | pub | `Mat::transpose` |
| `semiring/matrix/mat.mbt` | 89 | pub | `Mat::byte_size` |
| `semiring/matrix/mul.mbt` | 190 | pub | `mul_trop_plain` |
| `semiring/matrix/mul.mbt` | 281 | pub | `copy_region_out` |
| `semiring/matrix/mul.mbt` | 306 | pub | `mul_bool_swar` |
| `semiring/matrix/mul.mbt` | 382 | pub | `mul_gf2_m4ri_swar` |
| `semiring/matrix/mul_par.mbt` | 64 | pub | `closure_fw_par` |
| `semiring/nf/dfa.mbt` | 114 | pub | `Dfa::accepts` |
| `semiring/trop/poly.mbt` | 160 | pub | `UniPoly::argmin_at` |
| `semiring/trop/tla.mbt` | 118 | pub | `trop_assignment` |
| `semiring/trop/tla.mbt` | 264 | pub | `trop_eigenvalue_karp` |
| `semiring/trop/tla.mbt` | 341 | pub | `trop_critical_eigenvector` |
| `semiring/trop/tla.mbt` | 402 | pub | `verify_trop_eigenpair` |
| `symlib/core/group.mbt` | 368 | pub | `PermGroup::hyperoctahedral` |
| `symlib/marks.mbt` | 471 | pub | `burnside_mobius_solve` |
| `symlib/yoneda.mbt` | 786 | pub | `representable_presheaf` |
| `symlib/yoneda.mbt` | 817 | pub | `presheaf_from_gset` |
| `symlib/yoneda.mbt` | 836 | pub | `presheaf_nat_is_natural` |
| `symlib/yoneda.mbt` | 867 | pub | `gen_yoneda_extend` |
| `symlib/yoneda.mbt` | 889 | pub | `gen_yoneda_eval` |
| `symlib/yoneda.mbt` | 912 | pub | `verify_general_yoneda_bijection` |

## 2. 完全相同或同包 α 等價的函式體

- 重複組（正規化長度 137）：
  - `ualg/core/algebra.mbt:43` `show_ints`
  - `ualg/site/poset.mbt:225` `show_ints`

## 3. 結構極相近（同一組識別字集合，疑似複製貼上）

- 近似組（長度 318）：
  - `cubical/homotopy/homotopy_universal.mbt:53` `join_schema_at`
  - `cubical/homotopy/homotopy_universal.mbt:150` `wedge_schema_at`
- 近似組（長度 302）：
  - `cubical/kernel/schema.mbt:4453` `torus_schema`
  - `cubical/kernel/schema_extensions.mbt:710` `cube3_schema`
- 近似組（長度 275）：
  - `meta/instances/modules.mbt:261` `graph_dag`
  - `meta/instances/modules.mbt:280` `graph_dag_permuted`
- 近似組（長度 248）：
  - `algebra/poly_cube.mbt:70` `poly_insert_atom`
  - `algebra/poly_cube.mbt:93` `poly_drop_atom`

