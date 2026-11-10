# meta/core — 三個機制共用的數學地板

**層級 0，零外部依賴。** 這裡只有四件結構 + 兩個工具，其他 meta 套件全部建在它們上面。

| 檔案 | 結構 | 公開入口 |
|---|---|---|
| `ordinal.mbt` | Cantor 範式序數（`ω^{e1}·c1 + …`，`< ε₀`） | `ord_add`（**非交換**，1+ω=ω）、`ord_mul_omega`、`ord_is_normal`、`ord_is_*`／極限判定在 `reflect/universe.mbt` |
| `algebra.mbt` | 精確有理數＋整數矩陣秩（消元） | `matrix_rank`、`rank_int`、`mat_mul` |
| `unify.mbt` | 一階合一（mgu，meet）／反合一（lgg，join） | `u_mgu`、`u_lgg`、UTerm 的 α-正規化與字串化 |
| `matroid.mbt` | 秩函數擬陣：貪心、對偶、交換公理 | `mat_from_rank`、`mat_greedy`、`mat_dual`、`mat_exchange_ok`、`mat_rank_axioms_ok`、`mat_graphic`、`mat_linear` |
| `ramsey.mbt` | Ramsey 數的真搜尋與可證上界 | `ramsey`、`ramsey_free_exists`、`erdos_szekeres`、`binom` |
| `complex.mbt` | 單純複形、邊界矩陣、Betti、Čech 神經 | `cx_betti`、`cx_is_chain_complex`、`nerve_of_cover`、`cover_glues`、`cover_obstruction` |
| `malcev_chu.mbt` | 構造性泛代數同餘、商代數、吸收零／點化零二分、Pol–Inv 伽羅瓦對偶 | `ua_is_malcev_op`、`law_malcev_congruence_permutability_and_one_step_join`、`law_malcev_pol_inv_galois_correspondence` |
| `covering_focusing.mbt` | `S₃` 覆蓋空間伽羅瓦對應、Eilenberg–Zilber 退化分層、極性聚焦伴隨 `↓ ⊣ ↑`、多項式米田與 Swan 嚴格 `J` | `law_covering_galois_correspondence`、`law_ez_degeneracy_partition_stirling`、`law_polarized_focusing_adjunction`、`law_polynomial_yoneda_and_parametricity`、`law_swan_constant_extent_j_strictness` |
| `demorgan_swar_f4.mbt` | Kalman 四元鑽石 De Morgan 代數 `M_4`、三值 CCHM 上纖維化分配格、64-bit SWAR `Mono64` 整除／`GRevLex` 同構與 Zhegalkin ANF Möbius 對合 | `law_kalman_demorgan_diamond`、`law_cchm_cofibration_three_valued`、`law_swar_mono64_divisibility_and_order`、`law_zhegalkin_anf_mobius_involution` |
| `triad_f2_f3_f6_spec.mbt` | Burnside 標記環 Möbius 反演、非薄群胚一般米田雙射、Karp 最小環平均熱帶特徵對偶與 Nöbeling 上三角單模整數反演 | `law_burnside_table_of_marks_mobius`、`law_general_groupoid_yoneda_bijection`、`law_tropical_karp_cycle_mean_duality`、`law_nobeling_unimodular_triangular_inversion` |
| `glue_vogt_realignment.mbt` | `Fin(3)`/`Fin(4)` 四重等價與 1-群胚 Vogt 半伴隨化消阻（162 個繞數實例）、Hofmann–Streicher 重對齊 96 個 `S₃` 交換方塊、推出泛餘錐與指點 `Σ ⊣ Ω` 基數雙射及三值 Kleene–De Morgan 連接對偶律 | `law_equiv_quadrilogy_and_vogt_coherence`、`law_hs_realignment_and_glue_collapse`、`law_pushout_cocone_and_loop_susp_adjunction`、`law_demorgan_connections_and_cwf_subst` |
| `multimodal_qiit_qtt_meta.mbt` | 嚴格模式 2-範疇 `ModeTheory2Cat`（凝聚平坦 `♭ = Δ∘Π` 與全體四元組 Godement 互換律）、Fitch 左伴隨鎖正規形與逆變 2-胞腔鑰匙 `mtt_find_fitch_2cell_key`、Artin 逗號膠合 `2^k → 2` 規範截面篩選與 SGA4 重黏合 `○∘• = 1`、四元線性—仿射—無限制半環與鑽石 DAG `O(d)` 記憶化完備性 | `cohesive_flat_mode_2cat`、`mode_2cat_verify_laws`、`mtt_normalize_fitch_locks`、`law_mtt_2cat_interchange_and_fitch_locks`、`law_artin_gluing_stc_and_sga4_recollement_meta`、`law_dual_qtt_and_memo_bidir_completeness_meta` |

**不變式**：`ord_cmp` 是全序；`mat_dual ∘ mat_dual = id`；`cx_betti` 用 rank(B_{k−1}) − rank(B_k) 算，不靠數 Euler 特徵。
**邊界**：`ramsey(k,l)` 只對小值可行（`R(3,4)=9` 秒級），`R(4,4)` 請用 `erdos_szekeres` 的可證上界 —— 程式不假裝。
