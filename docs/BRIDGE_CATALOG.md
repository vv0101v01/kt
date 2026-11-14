# 聯邦橋功能枚舉與收益邊界

> 自動產生自 `bridge/catalog.json`；變更 lifecycle 必須同步程式、負控制、介面及 `agent.v2.md`。

**39 active / 45 歷史配對，6 retired**。Active 表示仍有保留理由及可執行核驗，**不表示已證任意輸入的普世定理**。以下明示哪些只是有限模型或計數對帳；公開 adapter 與驗證入口也不混稱。

## 驗收與重用

- `verify_k10_ten_federation_bridges()` 回傳 active 結果，不產生已刪橋的占位失敗列。
- `validate_bridge_registry(edges, federation_count=10)` 驗 ID、唯一配對、端點、缺邊、數量、非空見證及 `holds`；空表、退役 ID、錯配或重複均失敗。
- `bridge_edges_for_federations` 只做篩選；結果仍須經 validator，不能當驗證捷徑。
- `*_precomputed` 是同一行程內可信呼叫者的重用介面；公開 record 的布林值不是防偽證明或外部證書重放器。
- `cmd/showcase` 建一次 active 邊快照，列印、歷史子圖、兩波替換及總閘均讀同一批結果。

## Active 功能、產物、實際收益

| ID / 聯邦 | 實際入口 | 產物與收益 | 已核驗範圍 | 負控制／限制 |
|---|---|---|---|---|
| `K5-01` Cubical↔Symlib | [`check_perm_wiring_bridge`](../bridge/permutation_bridge.mbt) | Perm ↔ Bool wiring/Equiv 與置換矩陣 | S4 的 24 置換 × 16 Bool 狀態 | 往返及伴隨；不是任意維度的形式證明 |
| `K5-02` Cubical↔Semiring | [`replace_k5_02_face_lattice_chain_semiring`](../bridge/nominal_bridge_elimination.mbt) | CCHM 面序 → Boolean Kleene 閉包；計數半環數極大鏈 | □³ 的 27 面、729 序對、48 極大鏈 | 對稱化後序塌縮及冪零性消失 |
| `K5-03` Cubical↔Topos | [`verify_dependent_cubical_topos_bridge`](../bridge/five_federation_plan.mbt) | DTerm isContr → Kripke–Joyal 公式 | Sierpiński 景的 1／2 元 carrier 與一維 CCHM 景 | 二元 carrier 反駁可縮；不含 Glivenko 子定理 |
| `K5-04` Cubical↔Scheme | [`verify_cubical_algebra_scheme_bridge`](../bridge/five_federation_plan.mbt) | Poly/MPoly 轉換、理想商與分裂域對帳 | 圓與對角線交點及二變量 Face 理想 | 保環運算與根理想對帳；未作任意多項式完備證明 |
| `K5-05` Symlib↔Semiring | [`replace_k5_05_burnside_walk_orbits`](../bridge/nominal_bridge_elimination.mbt) | 群作用閉路 → 計數半環 trace → Burnside 軌道 | C4、D4、閉路長 1..4 | 非自同構置換使路徑像失效 |
| `K5-06` Symlib↔Topos | [`verify_symlib_galois_topos_bridge`](../bridge/five_federation_plan.mbt) | S3 G-set → 原子景預層與軌道分解 | 9 點序對、2 軌道、3+6 原子 | 非原子性與 Γ=0；反序神經另列輔助證書 |
| `K5-07` Symlib↔Scheme | [`verify_symlib_symmetric_scheme_bridge`](../bridge/five_federation_plan.mbt) | 置換作用 → RingHom、有限域點軌道與 Vieta étale | S3 trace-zero 平面 F2/F3、S2 判別式開集 | F2/F3 固定點差異；分歧閉集不作 étale 宣稱 |
| `K5-08` Semiring↔Topos | [`verify_semiring_kleene_alexandroff_topos_bridge`](../bridge/five_federation_plan.mbt) | 可達矩陣 → 偏序景 → Ω 的全局真值 | 4 點菱形、6 個不動向量 | 新增覆蓋後全局真值 6→5 |
| `K5-09` Semiring↔Scheme | [`verify_kapranov_tropical_laurent_bridge`](../bridge/tropical_bridge.mbt) | 有理 Laurent 賦值 → min-plus 熱帶折點 | 指定 Laurent 多項式與 P1 延拓 | 只覆蓋實作中的有限截斷與樣例 |
| `K5-10` Topos↔Scheme | [`replace_k5_10_zariski_nilpotent_topos`](../bridge/audit.mbt) | Zariski 命題景與點函子區分冪零加厚 | F3 與 F3[ε] 上的 X / X_red | 普通點 2=2，dual-number 點 4≠2 |
| `K6-12` Condensed↔Symlib | [`verify_k6_12_condensed_symlib_bridge`](../bridge/double_v_chiasm.mbt) | Z2 軌道的 canon normalizer 與 Burnside 對帳 | 4 點、2 軌道 | 有限固定案例；一般作用的 transport 尚未實作 |
| `K6-14` Condensed↔Topos | [`verify_k6_14_condensed_topos_bridge`](../bridge/double_v_chiasm.mbt) | Hopf Serre 底／纖維 Betti 與神經對帳 | S2、S1、截斷 Serre report | 有限模型一致性；不宣稱已構造完整 spectral sequence 比較映射 |
| `K6-15` Condensed↔Scheme | [`verify_k6_15_condensed_scheme_bridge`](../bridge/double_v_chiasm.mbt) | 有限 Laurent Čech 矩陣 → P1 O(n) 維數、Serre/RR | n=-4..3、cutoff=4/6、F7 | P1 proper 但 O(-2) H1=1；拒絕越界截斷 |
| `K7-16` Discovery↔Cubical | [`verify_k7_16_discovery_cubical_bridge`](../bridge/discovery_k7_bridges.mbt) | 多邊形翻轉圖與 associahedron f-vector 對帳 | 5／6 邊形頂點與邊數 | 僅 skeleton 計數相符，不宣稱已證範疇等價 |
| `K7-17` Discovery↔Symlib | [`verify_k7_17_discovery_symlib_bridge`](../bridge/discovery_k7_bridges.mbt) | S3 軸作用的張量秩軌道分層 | 全部 6561 張量 × 6 置換 | mode-0 flattening rank 在軌道內變化 |
| `K7-19` Discovery↔Topos | [`verify_k7_19_discovery_topos_bridge`](../bridge/discovery_k7_bridges.mbt) | 同一 metric VR 複形 → Topos 3-skeleton 神經 | C4 尺度 0/1/2；公開 adapter 限 1..8 點 | 圈被填滿後 H1:1→0；拒絕畸形矩陣、負尺度 |
| `K7-20` Discovery↔Scheme | [`verify_k7_20_discovery_scheme_bridge`](../bridge/discovery_k7_bridges.mbt) | Radon 仿射平面的射影補點計數 | A2(F3) 9 點 + 4 方向 = P2(F3) 13 點 | 僅點數與 Gram 核驗，尚無一般 incidence transport API |
| `K8-22` Accel↔Cubical | [`replace_k8_22_swar_face_bdd`](../bridge/structural_bridge_replacements.mbt) | 布林面真值表 → SWAR / ROBDD 同態 | 2 變量、16 個布林函數 | 只屬 Boolean quotient，不混同自由 De Morgan 代數 |
| `K8-23` Accel↔Symlib | [`replace_k8_23_s3_axis_invariance_swar`](../bridge/nominal_bridge_elimination.mbt) | S3 張量作用 → SWAR 超行列式不變量與 Burnside | 6561×6、1485 軌道 | 單一 tensor entry 不是不變量 |
| `K8-24` Accel↔Semiring | [`replace_k8_24_tropical_four_way`](../bridge/structural_bridge_replacements.mbt) | 熱帶 APSP 四條演算法交叉核驗 | 固定小矩陣、Kleene/FW/SWAR/Dijkstra | 負環獨立偵測；Dijkstra 限非負權 |
| `K8-25` Accel↔Topos | [`verify_k9_federation_bridges`](../bridge/meta_k9_unification.mbt) | Sieve64 與列舉式 Heyting/SIP/MAC 對帳 | topos/site 原生有界驗證 | 由 topos/site 實際調用 accel/swar，非僅硬體名稱 |
| `K8-26` Accel↔Scheme | [`replace_k8_26_segre_cone_point_census`](../bridge/nominal_bridge_elimination.mbt) | scheme P1 點數 → Segre 仿射錐 → SWAR census | F3 的 129 rank≤1 點、2241 Det=0 點 | rank2 code12、rank3 code93 均可 Det=0 |
| `K8-27` Accel↔Condensed | [`replace_k8_27_ozaki_crt_zmat_snf`](../bridge/structural_bridge_replacements.mbt) | 同一整數矩陣 → CRT / 有理 / BigInt 乘法與 SNF | 含超過 2^53 的輸入 | 不使用浮點相等冒充精確整數 |
| `K8-28` Accel↔Discovery | [`replace_k8_28_bitplane_implication_soundness`](../bridge/nominal_bridge_elimination.mbt) | SWAR bitplanes ↔ 獨立語義蘊涵與最小反例 | 6561 樣本、5 謂詞、25 對 | 單 bit 篡改與 Det=0⇒rank≤1 反例 |
| `K9-29` Meta↔Cubical | [`replace_k9_29_stlc_dterm_nbe`](../bridge/structural_bridge_replacements.mbt) | STLC Term → DTerm；兩套 NbE 比較 | 5 個閉 Unit 項、η 與開項控制 | 不是任意依賴項的 normalization 證明 |
| `K9-30` Meta↔Symlib | [`replace_k9_30_congruence_orbit_rank`](../bridge/nominal_bridge_elimination.mbt) | 生成元圖等價閉包 ↔ 群軌道 ↔ 線性秩 | Aut(K3⊔K2)、2 軌道 | 刪生成元導致 4 類 |
| `K9-31` Meta↔Semiring | [`replace_k9_31_horn_kleene_least_model`](../bridge/structural_bridge_replacements.mbt) | 一元 definite Horn → Boolean Kleene 最小模型 | 有限 unary Horn、兩組初始事實 | 二元 body 顯示單純 reachability 不足 |
| `K9-32` Meta↔Topos | [`replace_k9_32_nerve_h1_bareiss`](../bridge/audit.mbt) | 單純邊界矩陣 Bareiss rank ↔ 神經上同調 | S1、填充三角形與 S2 | 填面後 H1=0；S2 H2=1 |
| `K9-33` Meta↔Scheme | [`replace_k9_33_macaulay_hilbert_bareiss`](../bridge/nominal_bridge_elimination.mbt) | Macaulay 矩陣 rank ↔ Gröbner Hilbert 函數 | 二變量、d=0..3、HF=[1,2,2,2] | 胖點 HF3 與約化 HF1 |
| `K9-34` Meta↔Condensed | [`replace_k9_34_mobius_glue_rlim_torsion`](../bridge/structural_bridge_replacements.mbt) | Möbius 單值化符號 → Smith coinvariants | [-1] 撓 [2]；[+1] 自由秩1 | 零截面可黏；coinvariants 不是 inverse limit |
| `K10-37` Ualg↔Cubical | [`construct_k10_ualg_cubical_face_bdd`](../bridge/ualg_federation_constructions.mbt) | ualg 面格 → 雙軌 CCHM BDD | □² 的 48 面公式及量詞 | boundary≠top |
| `K10-38` Ualg↔Symlib | [`construct_k10_ualg_symlib_burnside_marks`](../bridge/ualg_federation_constructions.mbt) | B2 替換作用 → 48 點 G-set 與 marks | 8 元群、15 軌道 | trivial action 48 軌道 |
| `K10-39` Ualg↔Semiring | [`construct_k10_ualg_semiring_congruence_kleene`](../bridge/ualg_federation_constructions.mbt) | 平移像＋Boolean Kleene 交替閉包 → 同餘 | 45 principal pairs；對照 Freese | 單步 reachability 不足 |
| `K10-40` Ualg↔Topos | [`construct_k10_ualg_topos_cube_sieve64`](../bridge/ualg_federation_constructions.mbt) | □² 開集 → Sieve64；Heyting/¬¬ 傳輸 | 48 開集、482 組不保併 | ¬¬ 不保 join |
| `K10-41` Ualg↔Scheme | [`construct_k10_ualg_scheme_stanley_reisner`](../bridge/ualg_federation_constructions.mbt) | 立方子複形 → squarefree monomial ideal → Hilbert | □² 邊界及整體 | 只核驗指定構造，非一般 cubical/simplicial Betti 等價 |
| `K10-42` Ualg↔Condensed | [`construct_k10_ualg_condensed_translation_spectrum`](../bridge/ualg_federation_constructions.mbt) | GL(2,2) 平移作用 → Smith coinvariants | 6 個自同構；rank/cycles/root multiplicity | 3I2 有 2-撓；不冒稱 inverse limit |
| `K10-43` Ualg↔Discovery | [`construct_k10_ualg_discovery_cubical_implications`](../bridge/ualg_federation_constructions.mbt) | 48 面公式的謂詞 → SWAR 蘊涵／反例 | 5 謂詞、全部序對 | 非等價謂詞最小反例 |
| `K10-44` Ualg↔Accel | [`construct_k10_ualg_accel_gf2_cubical_betti`](../bridge/ualg_federation_constructions.mbt) | 同一立方邊界矩陣 → GF2 SWAR RREF 與 Betti | 11 複形、T2 [1,2,1]、S2 [1,0,1] | 有撓空間 Q/F2 可能不同；不外推 |
| `K10-45` Ualg↔Meta | [`construct_k10_ualg_meta_congruence_malcev`](../bridge/ualg_federation_constructions.mbt) | 同餘／商核／Malcev → meta 關係代數 | 22 同餘案例 | 非 Malcev 運算對照 |

## 已關閉及實際刪除的配對橋

只有不可執行的 ID／理由留作追溯；相關函式、assembler 呼叫和 promotion report 已移除。底層學科 API 不隨橋一併刪除。

| ID | 舊配對 | 刪除理由 |
|---|---|---|
| `K6-11` | Condensed↔Cubical | No constructed Adams/Brunerie comparison map; independent invariant checks are not a bridge. |
| `K6-13` | Condensed↔Semiring | Tropical roots and liquid subadditivity are independent; no shared object or transport. |
| `K7-18` | Discovery↔Semiring | Viro ties and tensor implication order are independent; no structure transport. |
| `K7-21` | Discovery↔Condensed | Ledger hashing and Clifford centers are independent; sealing is not a mathematical bridge. |
| `K9-35` | Meta↔Discovery | No soundness map from discovered tensor implications to the unrelated Horn and focused proofs. |
| `K9-36` | Meta↔Accel | Only meta/reflect is executed; there is no Accel data path, independent hardware comparison or acceleration. |

## 已移除的非配對包裝

| 包裝 | 舊入口 | 理由 |
|---|---|---|
| X-Overlap Chiasmus | `verify_x_overlap_chiasmus` | Independent reports plus the coincident triple (1,2,1); no maps whose diagram can commute. |
| Malcev/Presheaf/Autonomy bundle | `verify_malcev_presheaf_autonomy_bridge` | Independent native health reports conjoined without a shared transported object; native APIs remain. |

## 新增的可重用產物（不是多算幾條橋）

- `@condensed.cond_p1_cech_dimensions(twist, cutoff)`：有限 Laurent Čech 矩陣的 H⁰/H¹；`0≤cutoff≤16`、`|twist|≤cutoff`，非法輸入回傳 `None`，固定 F₇。
- `metric_vr_to_topos_nerve(space, scale)`：1..8 點有效整數 metric 的 flag 3-skeleton；非法／不對稱／不滿足三角式的輸入回傳 `None`。只保證供 H⁰..H² 比較，高維同調不可由截斷外推。
- `graph_closure_snf_report(graph)`：1..32 點簡單無向圖的 components、Boolean closure、整數 Laplacian SNF 三路對帳；拒絕空域、self-loop、不對稱資料。
- F2×F3×F6 保留實際 Cayley→可達矩陣→Laplacian 構造；移除與此物件無關的健康合取項，以兩個不連通三角形作負控制。

## 仍保留但不是配對橋的輸出

`BridgeCertificate` 統一呈現原生核驗／18 項 atlas／輔助定理；它們不增加 active 配對數。F8×F5×F1、旋轉關係對齊、七支柱整合及 4 個已反例修正的直覺猜想仍可獨立執行；其 `holds` 只描述該入口所列有限案例，不是一般形式證明。WGSL 僅作靜態可移植性檢查，本次沒有 GPU 裝置實跑。
