# Lean 側的「全稱／歸納」清單（144 條，2026-11-11 重計）

（2026-11-10：依使用者裁決刪除 `Reflect/Universe.lean` 玩具模型——其 12 條全稱一併移除，146 → 134。）
（2026-11-11：新增 `Reflect/NfNormal.lean`（O1 第一半邊，kernel 綠），134 → 137；隨後重計補錄 `Instances/ImportGraph.lean` 7 條（未入桶、未登記 Registry；獨立 `lake env lean` 綠），137 → 144。`Instances/SldComplete.lean` 紅（O2 未完成），不計入。）

由 `lean/KtLaws/**/*.lean` 以**證明形狀**抽出的全稱或歸納性命題，共 **144** 條（134 + `Reflect/NfNormal.lean` 3 條 + `Instances/ImportGraph.lean` 7 條，2026-11-11 重計）。
計數規則：逐檔 `grep -cE '^(theorem|lemma)'`，依證明主體分類（`decide`/`native_decide` 主體 ⇒ 具體計算；顯式參數／∀／`induction`／`wellFounded` ⇒ 全稱歸納；其餘 ⇒ 其他）。`SldComplete.lean`（紅）不計入。
分類判準（可重跑）：證明主體不是 `decide`/`native_decide`，且陳述含顯式參數或 `∀`，或證明用到 `induction`／`wellFounded`／`Acc`。

這批是 [`WHY.md`](WHY.md) §2 所講「原因部份」的實際資產：它們是 kt 的執行檢查**確立不了**的全稱主張。
其餘 382 條具體計算＋47 條其他**不在這份清單裡**——那些 kt 跑一次就知道，屬於「超出理由」的部分。

## `lean/KtLaws/Graph.lean`（11）

- `nodup_filter`
- `exists_subset_len`
- `eq_pair_of_len`
- `eq_quad_of_len`
- `eq_six_of_len`
- `sum_map_add`
- `sum_map_congr`
- `sum_indicator`
- `sum_map_const`
- `handshake`
- `mkfun`

## `lean/KtLaws/IIT/Examples.lean`（8）

- `evenOdd_sound`
- `evenOdd_sorted`
- `natFin_monotone`
- `natFin_chain_sound`
- `natFin_chain_sorted`
- `iota_law`
- `termination_certified`
- `measure_decrease`

## `lean/KtLaws/IIT/Schema.lean`（38）

- `itermEq_complete`
- `ivalEq_complete`
- `containsVal_sound`
- `step_mem`
- `dedupVal_subset`
- `ivalSize_lt_of_mem`
- `icheckAt_sound`
- `foldArgs_rebuild`
- `iit_fold_iota_n`
- `iit_fold_iota`
- `mergeNew_keeps`
- `mergeNew_subset`
- `stage_inflates`
- `freshOfCtor_sound`
- `freshOfCtor_sort`
- `freshOfSort_sound`
- `freshOfSort_sort`
- `mergeNew_sound`
- `mergeNew_sort`
- `stage_sound`
- `stage_sort`
- `enumerate_sound`
- `enumerate_sort`
- `enumerate_mono`
- `firstErr_eq_none`
- `mem_itermScopeList`
- `firstErr_itermScopeList_none`
- `itermSize_ctor`
- `itermSizeList_cons`
- `itermSize_lt_ctor`
- `itermScopeOK_sound`
- `foldArgs_eq_foldArgsWith`
- `foldArgsWith_congr`
- `iitFold_unique_aux`
- `iitFold_unique`
- `iit_fold_iota_is_instance`
- `hasHoleList_false`
- `itermScopeOK_complete`

## `lean/KtLaws/Instances/Coherence.lean`（1）

- `ambiguityFilter_nil_of_unique_top`

## `lean/KtLaws/Instances/Termination.lean`（9）

- `uSize_apply`
- `root_size_decreases`
- `uSizeList_rewrite_lt`
- `rewrites_size_decreases`
- `rewrites_restriction_wf`
- `envShow_rules_measureDecreasing`
- `envShow_terminating`
- `sum_map_le_of_count_le`
- `kt_node_measure_orientation_unsound`

## `lean/KtLaws/Instances/Engine.lean`（7）

- `pick_eq_or`
- `foldl_pick_mem`
- `canonical_mem`
- `maximalDerivs_subset`
- `criticalPairs_lt`
- `criticalPairs_complete`
- `incoherenceWitness_mem`

## `lean/KtLaws/Matroid.lean`（4）

- `compl_compl`
- `dual_dual`
- `dual_dual_bases`
- `card_eq`

## `lean/KtLaws/Ordinal.lean`（14）

- `cmp_eq_iff`
- `cmp_swap`
- `cmpList_nil_cons`
- `cmpList_cons_nil`
- `cmpList_cons_cons`
- `cmpNat_lt`
- `cmpNat_lt_trans`
- `cmp_lt_trans`
- `cmp_self`
- `leq_refl`
- `leq_antisymm`
- `max_idem`
- `max_is_join`
- `leq_trans`

## `lean/KtLaws/Ramsey.lean`（17）

- `monoFree4_sound`
- `pigeon5_f`
- `six_star_step`
- `succ_ne_zero'`
- `succ_ne`
- `degIn_eq_nbhd`
- `red_deg_le_three`
- `red_deg_ge_three`
- `r34_le_9`
- `triRed_one`
- `triRed_two`
- `triRed_three`
- `triBlue_one`
- `triBlue_two`
- `triBlue_three`
- `r43_le_9`
- `r44_le_18`

## `lean/KtLaws/Reflect/Link.lean`（3）

- `variant_refl`
- `variant_symm`
- `variant_trans`

## `lean/KtLaws/Reflect/Nbe.lean`（8）

- `reifyN_arr`
- `reifyN_one`
- `reflVal_arr`
- `applyAtN_neu'`
- `applyAtN_vapp'`
- `applyAtN_vneu_gen`
- `nbe_reify_refl_neutral`
- `nbe_reify_reflect_fuel`

## `lean/KtLaws/Reflect/Proof.lean`（3）

- `termText_pos`
- `certTextAux_ge`
- `certText_pos`

## `lean/KtLaws/Reflect/NfNormal.lean`（3）

- `reifyN_isBetaNormal`
- `nf_isBetaNormal`
- `nf_beta_normal`

## `lean/KtLaws/Instances/ImportGraph.lean`（7）— 未入桶、未登記 Registry（獨立 `lake env lean` 綠；O5 邏輯核心）

- `imports_trans`
- `acyclic_self_edge_absent`
- `reach_antisym_of_acyclic`
- `no_mutual_reach_of_acyclic`
- `imports_acyclic_iff_mutuality`
- `cycle_of_distinct_mutual`
- `cycle_of_self_loop`

## `lean/KtLaws/Simplicial.lean`（11）

- `altSum_add`
- `altSum_sub`
- `altSum_pair`
- `euler_poincare`
- `le_foldl_max`
- `maxdim_bound`
- `filter_eq_nil`
- `layer_top`
- `boundary_top`
- `rankF_zero`
- `rankF_top`
