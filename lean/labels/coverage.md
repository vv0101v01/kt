# MoonBit 標籤 ↔ Lean 定理對照表

> **⚠️ 這張表是「人讀的族對應」，不是形式連結**：Lean 命題與 kt 的 `Bool` 檢查之間沒有 refinement／extraction 橋，
> 「有對應」不等於「已形式化」。必要性與比例見 [`../WHY.md`](../WHY.md)（137/580 為全稱、403/580 為具體計算）。

> **現況更新**：kt 側已增至 **485** 條標籤（388 條互異），本表只涵蓋遷移前的 **437** 條；
> 本輪新增的 48 條能力定律（NbE 一般 β／SLD 完備性／匯入圖 SCC／QIIT 商良定義／修補終止序／真實 club 反射）
> 尚未鏡射到 Lean。原始 485 條清單見 [`moonbit-labels.md`](moonbit-labels.md)。

由 `cmd/lawcount`（`moon run`，讀四個 `all_laws()`）實測的標籤總數是 **437**
（`core` 115 / `instances` 123 / `iit` 151 / `reflect` 48）—— 但其中**大量重複**：
同一個 `chk` 在迴圈裡被 push 多次（例：iit 的 Even/Odd `#6`/`#7` 各出現 13 次），
去重之後只剩 **340 個互異標籤**（core 102 / instances 120 / iit 74 / reflect 44）。
Lean 側目前有 **492** 條已登記定理。兩邊條數不對齊是刻意的：某些家族 MoonBit
用多個樣本標籤檢查同一件事（iit 的 Even/Odd 有 29 個標籤但只有 7 個互異），Lean 側寫成全稱定理；
反過來某些家族 Lean 側更細（reflect 44 個互異標籤 ↔ 91 條定理）。

下表逐族列出對應關係（標籤數合計 **437**）。

| MoonBit 標籤群 | 標籤數 | Lean 定理 | 對應方式 |
|---|---|---|---|
| core / ramsey：Paley graph gives R(4,4) ≥ 18 | 9 | `paley_self_complementary`, `paley_qr_count`, `paley_edges_count`, `paley_free_44`, `paley_free_45`, `paley_free_54`, `complete_edges_17`, `complete_not_free`, `paley_five_edges` | 逐條 1:1（`KtLaws/RamseyEx.lean`） |
| core / ramsey：R(4,4) and R(3,5) pinned exactly | 14 | `pin_44_upper`, `pin_44_pinned`, `pin_44_lower`, `pin_44_witness_edges`, `pin_44_witness_free`, `pin_35_upper`, `pin_35_pinned`, `pin_35_witness_free`, `pin_exact_44`, `pin_exact_35`, `pin_exact_33`, `pin_exact_34`, `pin_exact_36_none`, `pin_upper_36` | 逐條 1:1 |
| core / ramsey：recursion bound beats Erdős–Szekeres | 10 | `rec_bound_25`, `rec_bound_33`, `rec_bound_34_beats`, `rec_bound_44`, `rec_bound_35`, `rec_bound_44_lt_es`, `rec_bound_never_worse`, `rec_bound_symm`, `seed_33`, `seed_34` | 逐條 1:1 |
| core / ramsey：depth window now usable up to d=3 | 6 | `window_3`, `window_2`, `window_1`, `window_monotone`, `window_safe`, `window_4` | 逐條 1:1 |
| core / explicit (3,4)-free coloring of K8 | 4 | `circ8_red_edges`, `circ8_no_red3`, `circ8_no_blue4`, `circ8_no_red3_no_blue4` | 逐條 1:1（`KtLaws/Ramsey.lean`） |
| core / ramsey numbers computed by search | 7 | `search_22`, `search_25`, `search_33`, `search_34`, `search_es_34`, `search_es_44`, `search_es_ge` | 逐條 1:1 |
| core / ordinal | 16 | `le_refl_of_cmp`, `leq_total`, `leq_trans`, `cmp_lt_trans`, `ordMax` 的 join 性質、`max_assoc` 等 | 31 條覆蓋（樣本改成全稱） |
| core / ordinal CNF laws | 2 | `cnf_absorption`, `cnf_succ_gt`, `cnf_omega_two`, `cnf_one_plus_succ_omega`, `cnf_omega_plus_square`, `cnf_finite_below_tower`, `cnf_assoc`, `cnf_tower`, `cnf_normal_closed`, `cnf_mul_omega` | 10 條 CNF 恆等式覆蓋 2 個標籤 |
| core / matroid | 13 | `dual_dual`、貪心最優、秩公理／交換公理、`linear_*`（Q 上線性擬陣） | 14 條覆蓋 13 個標籤 |
| core / exact rational rank | 5 | `ratRank_*`（Q 上的精確秩） | 同上（`KtLaws/Matroid.lean`） |
| core / simplicial complexes | 9 | `euler_poincare`, `euler_poincare_complex`, `betti_*` | 19 條覆蓋 9+5+4 |
| core / covers | 5 | `glue_criterion`, `bad_cover_obstruction`, `disk_f0_ge_f1` | 同上 |
| core / complex | 4 | `euler_poincare_complex`、交錯和恆等式 | 同上 |
| core / unification | 7 | `unify_correct`, `unify_generality_x`, `unify_generality_y`, `unify_exists`, `unify_occurs`, `unify_constants`, `unify_symm_left`, `unify_symm_right`, `unify_symm_both` | 15 條覆蓋 11 個標籤（`KtLaws/Unify.lean`） |
| core / anti-unification = join (dual of mgu) | 4 | `lgg_shape`, `lgg_first_child`, `lgg_second_child_fresh`, `lgg_second_child_one_var`, `lgg_vars_are_fresh`, `lgg_is_join` | 同上 |
| instances | 123 | Engine 22 / Characterize 40 / Compose 35 / Coherence 40 | 138 條覆蓋 123 個標籤（`KtLaws/Instances/*`） |
| iit | 151（互異 74） | Schema 35 / Examples 樣本 / STLC 40 / Extra 6 | 88 條全稱定理覆蓋 12 個族，逐族對照見 §iit |
| reflect / universe reflection | 18 | `conserv_*`（8 條保守性）、`mahlo_*`（10 條 Mahlo） | 23 條覆蓋 18 個標籤 |
| reflect / reflection | 15 | `proof_decide_fast` … `proof_last_is_nf` + `termText_pos`／`certTextAux_ge`／`certText_pos` | 16+3 條覆蓋 15 個標籤 |
| reflect / link | 8 | `link_checks`, `link_depth_two`, `link_shape`, `link_root_goal`, `link_nested_checks`, `link_nested_depth`, `link_nested_shape`, `link_no_cert` | 13 條覆蓋 8 個標籤 |
| reflect / nbe | 7 | `nbe_beta`, `nbe_idempotent`, `nbe_eta`, `nbe_eval_neutral`, `nbe_check_terminates`, `nbe_check_preserved`, `nbe_check_rejects` | 逐條 1:1 |

## 判讀規則

* **逐條 1:1**：每個標籤有自己的定理，名字與語意一一對應。
* **覆蓋**：MoonBit 的標籤是同一族定理的樣本實例，Lean 側的定理對該族**全稱**成立，
  因此一個定理涵蓋多個標籤（或反過來一個標籤由多條定理共同支撐）。
* 落在 `match` 未觸發分支上的標籤（`reflect` 11 個、`unification` 4 個）：
  Lean 側改陳述成同一樣本的另一面向，並在各檔案頭註明 —— 這是**明示的偏離**，不是悄悄略過。
* `meta/core/{algebra,unify}.mbt` 的「精確有理秩」五條由 `Matroid.lean` 的 Q 上線性擬陣
  定理涵蓋（同一批樣本、同一個判準）。

## iit 的 12 族逐族對照（74 個互異標籤）

| MoonBit 標籤群（互異數） | Lean 定理 |
|---|---|
| Even/Odd is plain mutual induction（7） | `evenOdd_schema_ok`, `evenOdd_stage1`, `evenOdd_stage2`, `evenOdd_stage6`, `evenOdd_grows`, `evenOdd_sound`, `evenOdd_sorted` |
| mutual eliminator + iota + termination（3） | `iota_law`, `termination_certified`, `measure_decrease` |
| Kleene chain is monotone（4） | `enumerate_sound`, `enumerate_sort`, `enumerate_mono`, `stage_inflates` |
| subject reduction on a battery（4） | `subject_reduction_battery`, `battery_terms_check`, `battery_bat4_nf`, `battery_nf_checks` |
| Nat/Fin — index checking + phase lag（14） | `natFin_schema_ok`, `natFin_stage1_fin_empty`, `natFin_stage2`, `natFin_stage3`, `natFin_fz_z_checks`, `natFin_fz_z_index`, `natFin_fs_ok`, `natFin_fs_ok_index`, `natFin_fs_bad1_rejected`, `natFin_fs_bad2_rejected`, `natFin_fz_z_at`, `natFin_fz_z_at_wrong`, `natFin_monotone`, `natFin_chain_sound` |
| STLC Tm indexed by (Ctx,Ty)（9） | `stlc_schema_ok`, `stlc_id_term_checks`, `stlc_id_term_index`, `stlc_id_term_wrong_ctx`, `stlc_bad_app_rejected`, `stlc_good_app_checks`, `stlc_good_app_index`, `stlc_var_index`, `stlc_var_wrong_index` |
| STLC β is index-preserving（9） | `beta1_src_checks`, `beta1_reduct_is_arg`, `beta1_reduct_checks`, `beta1_index_preserved`, `beta2_*`（5 條） |
| weakening and context insert（9） | `weaken_var_is_vs`, `weaken_var_checks`, `weaken_var_ty_preserved`, `weaken_var_ctx_changes`, `weaken_lam_checks`, `weaken_lam_ctx_inserted`, `weaken_twice_checks`, `weaken_twice_depth`, `weaken_bad_app_rejected` |
| normalization reaches a stuck value（6） | `norm_reaches_arg`, `norm_result_is_stuck`, `norm_zero_fuel`, `norm_one_step_then_stuck`, `stuck_app_does_not_beta`, `stuck_app_checks` |
| index-dependency graph acyclic（3） | `evenOdd_index_acyclic`, `natFin_index_acyclic`, `finite_index_acyclic` |
| a finite mutual schema does stabilize（4） | `finite_stage4_stable`, `finite_stage7_stable`, `finite_stage8_same`, `finite_stage10_same` |
| schema placeholders are rejected（2） | `hole_natFin_ok`, `hole_rejected` |

## 三族審查：把「替代品」換成定理

前一輪為了讓 kernel 能歸約，有 5 處是用「替代品 + 註解」撐住的，加上 1 處「只有樣本」，這一輪全部換成真證明：

| 原本的替代品 | 現在的定理 | 位置 |
|---|---|---|
| η 收縮不做 `shift −1`（`Nat` 沒有負數），直接丟掉外層 λ | `shiftDn` + `eta_contracts_star`、`eta_blocked`、`eta_contract_shifts` | `Reflect/Nbe.lean` §7 |
| `u_variant_eq`（α-等價）用 `uEq` 代替 | `uCanon` / `uFingerprint` / `uVariantEq` + `variant_refl/symm/trans/renames/distinguishes`，再用 `checkInstanceProofV` 重驗同一批憑證（`variant_accepts*`、`variant_agrees`、`variant_rejects_tampering`） | `Reflect/Link.lean` §2, §3b, §5–6 |
| 「可列印」只用 `List Nat` 指紋 | `termText` / `certText`（`List Char`）+ `termText_pos`、`certTextAux_ge`、`certText_pos` | `Reflect/Proof.lean` §6 |
| §6 的 η 定律只是樣本 | `nbe_reify_refl_neutral`、`nbe_reify_reflect_fuel`（對所有型別／深度／中性值） | `Reflect/Nbe.lean` §8 |
| `triv` 的最大原子用 0（MoonBit 是 −1） | `stmtMaxAtomI` + `max_atom_triv_int`、`max_atom_bridge`（夾到 0 之後逐句相同） | `Reflect/Universe.lean` §6 |
| `ambiguousGoals` 的短路只有一句註解 | `ambiguityFilter_nil_of_unique_top`（一般引理）+ `coherence_unique_top_envShow`、`coherence_no_ambiguity_envShow`、`coherence_single_rule_envShow`、`coherence_no_critical_pairs`、`coherence_shortcut_agrees`、`coherence_shortcut_needs_hypothesis`（對照組） | `Instances/Coherence.lean` §12 |
