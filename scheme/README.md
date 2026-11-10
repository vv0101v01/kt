# `scheme/` — 代數幾何：Gröbner 基、黏合概形、Kähler／Fitting、Serre 對偶、吹脹與 Chow 動機

> **架構位置**：`architecture.json` 中的 `scheme`，**Layer 2**，依賴 `algebra`（以及 `algebra` 背後的 `gcd`）。
> 聯邦歸屬：**F5**（第五聯邦）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/scheme`。

---

## 1. 定位

`scheme` 建立在**精確有理多項式環 `ℚ[x₀,…,x_{n-1}]`** 之上，把代數幾何的標準證明工具（Gröbner 基、消元、飽和、根理想）當成**可計算的正規形**，於是「理想相等」「概形同構」「態射是否仿射／分離／真」全部變成可判定的有限計算。**零浮點、零取樣**：所有答案都是精確等式。

五層結構：

```text
Layer 4  cycles_dual_points_categorify.mbt    Weil/主除子、Bézout、Serre 對偶、點函子、Chow 動機
Layer 3  scheme_morphisms_affine_proper.mbt   黏合概形、態射、纖維積、分離性、DVR 真判定、Laurent 級數
Layer 2  sheafification_affine_reduced.mbt   座標環、環同態、Zariski 局部化、單位分解層化、M~、既約概形
Layer 2' derived_structural_theorems.mbt     Kähler 微分、Fitting 理想、Tjurina 數、Hilbert 多項式、吹脹、F_{p²} 下降
Layer 1  groebner_ideal.mbt                  多元多項式環、單項序、Buchberger 約化 Gröbner 基、消元／飽和／根、Krull 維度
              @algebra (Rat/Poly/QMat)  @gcd (BigInt/SNF/CRT)
```

---

## 2. 檔案清單（6 檔，共 6,150 行）

| 檔案 | 行數 | 主題 |
|---|---:|---|
| `f4_macaulay_swar.mbt` | 1168 | 7 變數 7-bit `Mono64` 無分支 3 指令單項式整除／`GRevLex`、Yan 對數地理桶（Geobuckets）、Gebauer–Möller 臨界對判準、串接 `@swar.gf2_rref_eliminate_u64` 之 Lazard–Macaulay M4RI 布林 Faugère F4 `f4_boolean_groebner_gf2`，以及三素數 CRT + `ugcd_rat_recon_bigint` 有理重構模 F4 `f4_groebner_rat_modular` |
| `groebner_ideal.mbt` | 1210 | 多元多項式、三種單項序、Buchberger 約化 Gröbner 基（規範形）、消元／交／商／飽和、Rabinowitsch Nullstellensatz、根理想、Krull 維度 |
| `sheafification_affine_reduced.mbt` | 585 | 座標環與環同態、`O(D(f))` 局部化截面、單位分解層化、準相干模 `M~`、約化概形 `X_red` 與泛性質 |
| `derived_structural_theorems.mbt` | 703 | Kähler 微分 `Ω¹_{B/A}`、Grassmann–Plücker `O(k·2^k)`／Berkowitz `O(k⁴)` 行列式、`Fitt₀`、非分歧／平展判準、Jacobi 奇異軌跡與 Tjurina 數 `τ`、Hilbert 多項式、吹脹解消、`F_{p²}` Frobenius 下降 |
| `scheme_morphisms_affine_proper.mbt` | 1272 | 黏合概形與重疊資料、典範圖集（`𝔸ⁿ`、`ℙ¹`、`ℙ²`、雙原點直線、去點平面）、態射合成與纖維積、對角分離性、仿射態射判定、`ℚ((t))` Laurent 級數、DVR 賦值真判定 |
| `cycles_dual_points_categorify.mbt` | 1212 | `ℙ¹` 的 Weil／主除子與有理等價、`ℙ²` Bézout 交點數、Čech 上同調算 `O(n)`、Serre 對偶與 Riemann–Roch、平面曲線 `ω_C^•`、點函子 `h_X(R)`、Zariski 切空間、Chow 對應與 `h(ℙ¹) = 1 ⊕ L` |

---

## 3. 逐檔精讀

### 3.1 `groebner_ideal.mbt`（Layer 1：一切都是理想的正規形）
* **單項序** `MonomialOrder`：`Lex`、`GRevLex`（預設）、`Elim(k)`（先消掉前 `k` 個變數，每塊內部 `GRevLex`）。
* **`reduced_groebner_basis`**：Buchberger 演算法 + 約化 ⇒ **規範形**，因此 `ideal_eq` 只需比較約化基（這是 `ideal_contains`、`ideal_is_unit` 等所有判定的基礎）。
* **理想運算**：`ideal_add`、`ideal_eliminate_first_k`（用消元序）、`ideal_intersect`、`ideal_quotient_poly`、`ideal_saturate`（`I : f^∞`）、`ideal_radical`、`ideal_radical_contains`（Rabinowitsch trick）。
* **幾何不變量**：`ideal_standard_monomials`、`ideal_quotient_vector_space_dim`、`ideal_krull_dimension`。
* **多項式 ↔ 單變數互轉**：`mpoly_to_qpoly_univariate`、`qpoly_to_mpoly_var`、`mpoly_of_poly`、`mpoly_to_poly`（把 `algebra` 的單變數分解能力接進多變數世界）。

### 3.2 `sheafification_affine_reduced.mbt`（Layer 2：結構層）
* `CoordRing`（`ℚ[x]/I`，`coord_ring_nf` 取正規形）＋ `RingHom`（由生成元像 `var_images` 指定，反變地給出 `Spec(dst) → Spec(src)`）。
* **截面**：`LocalizedSection{num, den_base, exp}` 表示 `O(D(f))` 的元素；`localized_section_eq` 在相容分母上做精確等式。
* **Zariski 開覆蓋**：`principal_open_subset`（`D(g) ⊆ D(f)` ⇔ `g ∈ √(I + (f))`，Hilbert Nullstellensatz）、`is_zariski_open_cover`。
* **層化／黏合**：`glue_zariski_structure_sections` 給定覆蓋 `{D(f_i)}` 與局部截面 `s_i`，實際**黏出**全域截面（乘上單位分解的幂次使其成為多項式）。
* **準相干模**：`QuasiCoherentModule`（`coker(A^{ncols} → A^{nrows})`）；`localize_quasicoherent_module` 把呈現矩陣推到 `A_f = ℚ[x,u]/⟨I_A, u·f − 1⟩`。
* **約化概形**：`affine_is_reduced` 搜尋**非零冪零見證** `w ∉ I` 且 `w^m ∈ I`（有則非既約）；`affine_reduction` 給 `X_red = Spec(A/√I)` 與閉浸入；`verify_affine_reduction_universal_property` 驗證「任何從既約源出發的態射必唯一穿過 `X_red`」。

### 3.3 `derived_structural_theorems.mbt`（第 2 輪：導出結構）
| 主題 | 演算法要點 |
|---|---|
| **Kähler 微分** `Ω¹_{B/A}` | 以 `(B ⊗_A B)/I²` 呈現為 `QuasiCoherentModule`；`Fitt₀` 理想 = `Ω¹` 的 0 階 Fitting 理想 |
| **非分歧／平展** | `Fitt₀` 為單位理想 ⇔ 非分歧；再加平坦 ⇔ 平展（配合 Jacobian 判準） |
| **奇異軌跡與 Tjurina 數** | `Sing(X) = V(Fitt₀(Ω¹))`；`τ(X) = dim ℚ[x]/(f, ∂f/∂x_i)` |
| **Macaulay–Taylor Hilbert 多項式** | 由分次 Gröbner 基的自由分解算 `P_X(t) ∈ ℚ[t]`、投影維度、`deg(X)`、算術虧格 `p_a(X)`；**支援任意餘維**（測試：`ℙ³` 中的 twisted cubic） |
| **吹脹** | `Bl_{(0,0)}(𝔸²)` 用 Gröbner **飽和**建 strict transform，一步判結節（`τ`，兩個不同切線）vs 尖點（`τ+1`，重切線）的例外纖維 |
| **`F_{p²}` 下降** | 二次 Galois 有限體、算術 Frobenius，比對 `h_X(𝔽_p)` 與 `h_X(𝔽_{p²})` 的點數 |

### 3.4 `scheme_morphisms_affine_proper.mbt`（Layer 3：幾何）
* **`ChartOverlap`**：`U_{ij} = Spec(ring)` 加兩支開浸入拉回 `from_i : A_i → ring`、`from_j : A_j → ring`；`is_empty` 表示不相交。**整個概形 = 圖集 + 疊（gluing datum）**。
* **典範圖集**：`scheme_affine_space(n)`、`scheme_projective_space(n)`（`ℙ¹`、`ℙ²`）、`scheme_projective_subscheme`、`scheme_doubled_origin_line`（非分離的教材反例）、`scheme_punctured_plane`（`𝔸² ∖ {0}`）。
* **態射**：`SchemeMorphism` 要求重疊圖的交換性；`scheme_morphism_is_valid` 逐重疊檢查；`affine_fiber_product` 用 `(A ⊗_ℚ B)/⟨φ_A(s) − φ_B(s)⟩` 算纖維積。
* **分離性**：`is_separated_scheme` ⇔ 對角 `Δ : X → X ×_X X` 是閉浸入（以重疊環同態滿射判定）。
* **仿射態射**：`is_affine_morphism` ⇔ 每個仿射圖 `V_j` 的原像 `f⁻¹(V_j)` 是仿射概形。**招牌例子**：`π : 𝔸²∖{0} → ℙ¹`（`(x,y) ↦ [x:y]`）竟是仿射態射，而開浸入 `𝔸²∖{0} ↪ 𝔸²` **不是**。
* **`ℚ((t))` Laurent 級數**：`LaurentSeries` 截斷精度；`laurent_is_integral_dvr`（`v_t(s) ≥ 0` ⇔ 在 `ℚ[[t]]`）、`laurent_inv`、`mpoly_eval_laurent`。
* **真判定（Grothendieck 賦值判準）**：`synthesize_chart_test_arcs` 產生 `t^{±1}` 方向的測試弧；`valuative_extension_classes_for_arc` 數 DVR 擴張的等價類；`analyze_scheme_properness` 回傳 `PropernessReport`（`0` 類 ⇒ 逃到無窮／缺洞 ⇒ 非真）。

### 3.5 `cycles_dual_points_categorify.mbt`（Layer 4：除子、對偶、動機）
* **除子**：`PrimeDivisorP1`（`ℙ¹_ℚ` 的閉點，含 Galois 軌道與剩餘次數 `[κ(P):ℚ]`）、`WeilDivisorP1`、`weil_divisor_p1_degree`；`principal_divisor_p1` 用 `@exactalg.qpoly_factor_complete` 精確分解 `num/den`。
* **有理等價**：`rational_equivalence_witness_p1` 在 `deg(D₁) = deg(D₂)` 時**實際造出**有理函數見證 `D₁ − D₂ = div(num/den)`；`are_rationally_equivalent_p1`（`CH¹(ℙ¹) ≅ ℤ`）。
* **Bézout**：`bezout_intersection_number_p2`（`F`、`G` 正常相交的概形論交點數）、`verify_bezout_theorem_p2`（`= deg F · deg G`）。
* **Čech 上同調**：`cech_cohomology_p1_line_bundle(n)` 用 `δ_n : O(n)(U₀)⊕O(n)(U₁) → O(n)(U₀₁)`（`(p₀(u), p₁(v)) ↦ p₀(u) − u^n p₁(u⁻¹)`）算 `(h⁰, h¹, χ)`；`cech_cohomology_p2_line_bundle(n)` 用三圖 `C⁰ → C¹ → C²`。
* **Serre 對偶**：`ω_{ℙ¹}^• = O(−2)[1]`、`ω_{ℙ²}^• = O(−3)[2]`；`verify_serre_duality_and_riemann_roch_p1`（`h¹(ℙ¹, ω) = 1`、Riemann–Roch）；平面曲線 `ω_C^• = i^!(ω_{ℙ²}^•) ≅ O_C(d−3)[1]`（`plane_curve_dualizing_complex`，奇異 Cohen–Macaulay 曲線亦成立）。
* **點函子**：`FiniteCommRing`（`𝔽_p`、雙數 `𝔽_p[ε]/ε²`、`𝔽_p[t]/t^k`、乘積環）、`eval_scheme_functor_of_points` 算 `h_X(R)` 的**餘等化子** `(∐U_i(R))/(∐U_{ij}(R))`；`zariski_tangent_dimension_fp` 用
  `dim T_x = log_p |(h_X(𝔽_p[ε]/ε²) → h_X(𝔽_p))⁻¹(x)|`
  純函子地求出切空間維度 —— 這是「無窮小資訊只在點函子裡、Zariski 拓撲看不到」的可執行證明。
* **Chow 動機**：`p1_correspondence_bidegree` 抽 `CH¹(ℙ¹×ℙ¹) ≅ ℤ[H₁]⊕ℤ[H₂]` 的雙次數；`compose_p1_correspondences_groebner` 用 **6 變數 Buchberger** 在 `ℙ¹_X × ℙ¹_Y × ℙ¹_Z` 上真正複合對應；`verify_motivic_p1_categorification` 驗 `h(ℙ¹) ≅ 1 ⊕ L`。

---

## 4. 招牌結果一覽

| 結果 | 入口 |
|---|---|
| 理想相等（規範形） | `ideal_eq` |
| 概形層的黏合（非僅局部資料） | `glue_zariski_structure_sections`、`scheme_is_valid` |
| `X_red ↪ X` 的泛性質 | `verify_affine_reduction_universal_property` |
| 仿射態射 vs 開浸入 | `is_affine_morphism`、`morphism_hopf_punctured_plane_to_p1` |
| 分離／真（賦值判準） | `is_separated_scheme`、`analyze_scheme_properness` |
| `h¹(ℙ¹, O(−2)) = 1`（Serre 對偶） | `verify_serre_duality_and_riemann_roch_p1` |
| `Bézout`：`I(F,G) = deg F · deg G` | `verify_bezout_theorem_p2` |
| `h(ℙ¹) ≅ 1 ⊕ L`（Chow 動機） | `verify_motivic_p1_categorification` |

---

## 5. 範例

```moonbit
// 1) 理想正規形與相等（x = mpoly_var(2,0), y = mpoly_var(2,1)）
let x = @scheme.mpoly_var(2, 0)
let y = @scheme.mpoly_var(2, 1)
let xy = @scheme.mpoly_mul(x, y)
let one = @scheme.mpoly_const(2, @exactalg.rat_one())
let i1 = @scheme.ideal_new(2, [@scheme.mpoly_sub(xy, one)])                   // <xy - 1>
let g2 = @scheme.mpoly_mul(y, @scheme.mpoly_sub(xy, one))                     // y(xy - 1)
let i2 = @scheme.ideal_new(2, [@scheme.mpoly_sub(xy, one), g2])
assert_true(@scheme.ideal_eq(i1, i2))            // 約化 Gröbner 基相同

// 2) ℙ¹ 上的線叢上同調
let h = @scheme.cech_cohomology_p1_line_bundle(-2)   // h^0 = 0, h^1 = 1, chi = -1
assert_true(@scheme.verify_serre_duality_and_riemann_roch_p1(-2))

// 3) 去點平面到 ℙ¹ 是仿射態射（但 𝔸²∖{0} ↪ 𝔸² 不是）
assert_true(@scheme.is_affine_morphism(@scheme.morphism_hopf_punctured_plane_to_p1()))
assert_false(@scheme.is_affine_morphism(@scheme.morphism_punctured_plane_to_a2()))

// 4) 真判定：ℙ¹ 真、𝔸² 非真
assert_true(@scheme.analyze_scheme_properness(@scheme.scheme_projective_space(1)).is_proper)
```

---

## 6. 依賴與被依賴

* **依賴**：`gcd`（`@gcd.FpMat` 模消元、CRT 與 `ugcd_rat_recon_bigint` 有理數重構）、`accel-swar`（`@swar.Gf2BitMatrix` 與 `gf2_rref_eliminate_u64` 字元並行 M4RI 消元）、`algebra`（`Rat`/`Poly`/`QMat`/`qpoly_factor_complete`）。
* **核心硬體加速與演算法（`f4_macaulay_swar.mbt` + `derived_structural_theorems.mbt`）**：
  * `Mono64` 64-bit 打包指數向量（`nvars <= 7, deg <= 127`）：3 指令無分支單項式整除 `(((t | 0x80..80) - d) & 0x80..80) == 0x80..80`、單 `UInt64` `GRevLex` 比較與 `mono64_coprime` 互素判定；
  * `O(m log m)` 歸併正規化、有序線性合併加減法、Yan Geobuckets（`O(|f| log |f|)` 多項式約化）與 Gebauer–Möller 臨界對判準（Criteria M, F, B）；
  * `f4_boolean_groebner_gf2`（Lazard–Macaulay 不動點 M4RI `GF(2)` 布林約化 Gröbner 基）與 `f4_groebner_rat_modular`（多素數 `(65521, 65519, 65497)` Macaulay 矩陣消元＋CRT＋Wang 有理重構＋Buchberger 驗證）；
  * `mpoly_square_det`：Grassmann–Plücker 外代數楔積動態規劃 `O(k · 2^k)`（`k <= 10`）與無除法 Samuelson–Berkowitz `O(k^4)`（`k > 10`），取代指數／階乘級 Laplace 餘子式遞迴。
* **被依賴**：`condensed`（`@scheme.projective_space(2)` 與 `P¹` 真性用於 `K6-15`）、`conjecture`、`bridge`、`root`。本套件**不**匯入 `topos`（幾何—邏輯的交會在 `bridge/`）。

---

## 7. 驗證

```bash
moon check --deny-warn --target wasm-gc
```
主要檢核入口：`verify_affine_reduction_universal_property`、`verify_bezout_theorem_p2`、`verify_serre_duality_and_riemann_roch_p1`、`verify_serre_duality_p2`、`analyze_scheme_properness`、`verify_motivic_p1_categorification`、`f4_boolean_groebner_gf2`、`f4_groebner_rat_modular`。
