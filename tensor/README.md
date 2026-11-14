# `tensor/` — 多線性張量幾何、離散 Radon、Clifford 旋量、非交叉森林與 VR 同調

> **架構位置**：`architecture.json` 中的 `tensor`，**Layer 2**，依賴 `gcd`（唯一上游）。
> 聯邦歸屬：**F7 `discovery`**（第七聯邦：多線性張量場論與猜想演化），與 `conjecture/` 成對。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/tensor`。

---

## 1. 定位

`tensor/` 是「**把一個具體的有限宇宙徹底算完**」的套件：`𝔽₃^{2×2×2}` 全部 `6,561` 個張量都被分類（秩 + 超行列式），離散 Radon 變換的精確反演被寫出，Clifford 旋量與 `T²` 規範場的模空間被計數，非交叉弦森林構成一個 Grothendieck 景，Vietoris–Rips 同調與其上同調被**獨立**算出並對照。所有線性消元代數一律下沉 `@gcd`。

兩個檔案，分工明確：**代數／幾何**（`multilinear_radon_gauge.mbt`）與**組合／拓撲**（`noncrossing_metric_hyper.mbt`）。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `multilinear_radon_gauge.mbt` | 863 | 三階張量 `Tensor3`、Cayley `2×2×2` 超行列式、`𝔽₃^{2×2×2}` 全 `6,561` 張量秩圖譜、離散 Radon 變換（Gram／反演／Plancherel）、扭群代數、Clifford Ramond 零模、`T²` 規範模空間 |
| `noncrossing_metric_hyper.mbt` | 906 | 非交叉弦森林、多邊形翻轉圖（Stasheff 骨架）、圓單調 MST、有限度量空間、精確 Gromov–Hausdorff 失真、全維 VR 持續同調、Krasner 超結構 |

---

## 3. `multilinear_radon_gauge.mbt` 精讀

### 3.1 張量基本層
```moonbit
pub(all) struct Tensor3 { d0; d1; d2; p; data }   // F_p 上 dim0 × dim1 × dim2
```
`t3_make`、`t3_of(f)`（用生成函數建）、`t3_get`、`t3_add`、`t3_rank1_scaled(c, u, v, w)`（純秩 1 張量 `c·(u⊗v⊗w)`）。
`t3_flatten(t, mode)`：mode-`k` 展平為 `@gcd.FpMat`；`t3_flatten_rank_lower_bound`：`[P-Flat]` 秩下界 `max_m rank(flatten_m T)`。

### 3.2 Cayley 超行列式（`2×2×2`）
```text
Det = Σ_{4 diag} (乘積)² − 2·Σ_{6 rect} (乘積)² + 4·Σ_{2 tetra} (乘積)²
```
`t3_hyperdet222` 以 `Int64` 中間運算實作，並由 `t3_check_sl2_shear_and_s3_invariance` 驗證 `[P-Shear]` 與 `[T-Dual-Tensor]`：
* 對 `SL₂(F_p)` 在三個 mode 上的 **全部 6 個基本 shear** 不變；
* 對三個軸的 **全部 `3! = 6` 個置換** 不變。

### 3.3 `𝔽₃^{2×2×2}` 全宇宙分類
```moonbit
pub(all) struct F3Tensor222Atlas {
  ranks           : Array[Int32]      // code 0..6560 -> 秩 0..3
  decompositions  : Array[Int32]      // 無序 2 項秩-1 分解的重數
  hyperdets       : Array[Int32]      // 每個 code 的 Cayley 超行列式
  rank_counts     : Array[Int32]      // = [1, 128, 4032, 2400]
}
```
* `f3_tensor_of_code(code)` / `f3_tensor_code(t)`：base-3 編碼往返；
* `f3_tensor222_atlas_build()`：`[T-Strassen-F3]` 以 `O(|R₁|²)` 完成 —— **128** 個射影歸一化的純張量 ⇒ `8,128` 對 ⇒ 覆蓋全部 `6,561` 個張量。秩分佈 `[1, 128, 4032, 2400]`（秩 0/1/2/3）。
* 這個常數被三處交叉驗證：`accel` 的雙軌 `GF(3)` 位切片（`103` 次 SWAR 掃描）、`conjecture` 的演化定律、`bridge` 的 `K7-*` 證書。

### 3.4 離散 Radon 變換（有限平面 `ℤ_n²`）
```moonbit
pub(all) struct DiscreteRadon { n; p }
```
* `radon_line_points(dir, t)`：`(n+1)·n` 條仿射線上的點；
* `radon_incidence_matrix(r)`：關聯矩陣 `R`（`(n+1)n × n²`，元素在 `F_p`）；
* `radon_apply_exact(r, f)`：`ℤ` 上**精確整數和**（供能量比檢查）；
* `radon_check_gram_identity(r)`：`[T-Radon-Gram]` 檢查 `RᵀR = n·I + J (mod p)`。**只有 `n` 為質數時成立**：`n = 4` 失敗，因為兩點可能共享 0 或 2 條線 ⇒ 「有限平面」與「有限域」的差別被具體否證；
* `radon_invert_fp(r, Rf)`：`[T-Radon-Inv]` 以 Sherman–Morrison 顯式反演
  `f = (1/n)(Rᵀ(Rf) − (1/(n+1))·Σ_pt (RᵀRf)(pt))`（需 `n` 質數且 `p ∤ n(n+1)`）；
* `radon_energy_triple(r, f)`：驗仿射修正的 Plancherel 律 `Σ(Rf)² = n·Σf² + (Σf)²`。

### 3.5 扭群代數、Clifford、規範模空間
* `twisted_group_clifford_cocycle_report(d, ell, p)`：分析 `F_p^ω[(ℤ/ell)^d]`，`ω(a,b) = Σ_{i>j} a_i b_j (mod ell)`（Jordan–Wigner／Clifford 餘圈），記錄 `dim Z`、`|rad|`、伴隨性等。
* `clifford_ramond_anticommutator_ok(d, p)`：構造 `2^{d/2} × 2^{d/2}` 的 `γ₀…γ_{d-1}` 矩陣並驗 `{γ_a, γ_b} = 2δ_{ab}I`；**要求 `p ≡ 1 (mod 4)`**（`p = 5, 13`），`p ≡ 3 (mod 4)` 時明確拒答（`clifford_available == false`）。
* `lattice_torus_gauge_moduli_verify(ell)`：`[T-Gauge-Moduli-Bij]` 在 `2×2` 環面 `T²` 上，1-上鏈連結配置數 `ell⁸`、平坦聯絡（四片 plaquette 曲率全 `0`，Bianchi 和 `≡ 0`）、模空間計數與 `ℤ/ell` 的交換性。

---

## 4. `noncrossing_metric_hyper.mbt` 精讀

### 4.1 非交叉弦森林（組合）
* `nc_chords_cross((a₁,b₁),(a₂,b₂))`：凸 `n` 邊形上的嚴格內點交叉判定（共用端點不算）。
* `nc_polygon_triangulations_flip_report(n)`：`n = 4..7` 窮舉全部 `C_{n-2}` 個三角化，建**對角翻轉圖**（Stasheff 結合多面體 `K_{n-1}` 的 1-骨架），驗證 `(n−3)`-正則與連通性，並輸出 Catalan 對偶樹不變量列。
* `nc_mst_vs_unconstrained_mst(dist)`：無約束 MST 權重 vs **非交叉** MST 權重（`n ≤ 6`）。
* `nc_forest_grothendieck_site_ok(n, p)`：`[T-X-Site]` 在 `n = 4, 5` 上，非交叉弦森林的偏序 + 併覆蓋 `U = U₁ ∪ U₂` 滿足 Grothendieck **拉回穩定性**，且弦指派預層是層（與 `@topos` 的等化器判定對接）。

### 4.2 有限度量與 Gromov–Hausdorff
```moonbit
pub(all) struct FiniteMetricSpace { n; dist }   // 整數值度量
```
`metric_check_axioms`、`metric_diameter`；`metric_gh_twice_exact(X, Y)`：以 **Kalton–Ostrovskii 對應失真** `min_R dis(R)` 對所有「左全 + 右全」關係 `R ⊆ X×Y` 精確求 `2·d_GH`（`|X|·|Y| ≤ 12` 可行）。

### 4.3 全維 Vietoris–Rips 同調
```moonbit
pub(all) struct VrHomologyReport { betti; cobetti; euler; chain_dims; ... }
```
`metric_vr_homology_report(ms, scale_r)`（`n ≤ 8`）：
* 用 `@gcd.fp_rank(d_k)` 算**同調** `H_k`；
* 用 `@gcd.fp_rank(fp_mat_transpose(d_k))` **獨立**算**上同調** `H^k`；
* 驗證 `d_{k-1} ∘ d_k = 0`、`dim H_k == dim H^k`、Euler–Poincaré。

「同調與上同調走兩條獨立程式路徑」是本套件對「相信演算法」問題的回答。

### 4.4 Krasner 超結構
* `hyper_check_marty_hypergroup(op)`：Marty 超群公理 —— 非空值、超結合 `(a+b)+c = a+(b+c)`、再生性 `a + H = H = H + a`。
* `hyper_tropical_viro_op(top, a, b)`：截斷 Viro–Krasner 熱帶超加法
  ```text
  a ≠ b  ⇒  a ⊕ b = { min(a,b) }
  a = b  ⇒  a ⊕ a = { a, a+1, …, top }   （打破平手的整段區間）
  ```
  這是「熱帶行列式不唯一 ⇔ 超加法多值」的橋樑，`bridge` 的 `K7-18` 用它對接 `@strop.trop_det_tie_count`。

### 4.5 健康探針
`tensor_check_federation_laws()`：`tensor` 套件的總開關。

---

## 5. 招牌常數與結果

| 事實 | 值 | 入口 |
|---|---|---|
| `𝔽₃^{2×2×2}` 秩分佈 | `[1, 128, 4032, 2400]` | `f3_tensor222_atlas_build().rank_counts` |
| `n` 邊形三角化數 | `C_{n-2}`（`4..7`） | `nc_polygon_triangulations_flip_report` |
| Radon Gram 恆等式成立條件 | `n` 為質數 | `radon_check_gram_identity` |
| 仿射 Plancherel | `Σ(Rf)² = nΣf² + (Σf)²` | `radon_energy_triple` |
| Clifford 反交換 | `p ≡ 1 mod 4` | `clifford_ramond_anticommutator_ok` |
| `T²` 平坦聯絡數 | `ell⁸` 中挑出 | `lattice_torus_gauge_moduli_verify` |
| VR 同調 = 上同調 | `dim H_k == dim H^k` | `metric_vr_homology_report` |

---

## 6. 範例

```moonbit
// 1) 秩 2 張量與超行列式
let t = @tensor.t3_of(2, 2, 2, 3, fn(i, j, k) { ... })
println(@tensor.t3_flatten_rank_lower_bound(t))
println(@tensor.t3_hyperdet222(t))

// 2) 全 6,561 張量圖譜
let atlas = @tensor.f3_tensor222_atlas_build()
debug_inspect(atlas.rank_counts, content="[1, 128, 4032, 2400]")

// 3) 離散 Radon 反演（n 質數）
let r = @tensor.radon_make(5, 101)
let rf = @tensor.radon_apply_exact(r, f)
let back = @tensor.radon_invert_fp(r, rf)     // back == f (mod 101)

// 4) VR 同調與上同調雙路徑
let rep = @tensor.metric_vr_homology_report(ms, 1, 1_000_000_007)
assert_true(rep.homology_cohomology_dual)      // betti_homology == betti_cohomology
```

---

## 7. 依賴／被依賴

* **依賴**：`gcd`（`FpMat` 秩、RREF、零空間）。
* **被依賴**：`conjecture`（6 條演化定律以 `tensor` 的翻轉圖、規範流、VR 等為實驗台）、`accel`（`GF(3)` 位切片對照 `6,561` 超行列式）、`bridge`（`K7-16..21`）、`root`。
* `tensor` 刻意**不**依賴 `topos`：非交叉森林景的 Grothendieck 性質在本套件自足驗證，`bridge` 只負責在 `K7-19` 把兩邊的結論接起來。

---

## 8. 驗證

```bash
moon test tensor --target wasm-gc
```
主檢核：`tensor_check_federation_laws()`。

---

## 9. 迭代 3：`orbit_pencil_persistence.mbt`（763 行）

工具鏈：`moon 0.1.20261104` / `moonc v0.10.20`。新檔只依賴 `gcd`，架構邊不變。

| 標籤 | 內容 | 公開入口 |
|---|---|---|
| `[T-GL-Covariance]` | mode-`k` 乘積 `g ·_k T` 與三軸同時作用；`Det((g0,g1,g2)·T) = det(g0)² det(g1)² det(g2)² · Det(T)`，奇異矩陣也成立（右邊為 0）。取代只驗 6 個 shear 的舊判準 | `t3_mode_product`、`t3_multilinear_transform`、`t3_hyperdet_gl_covariance_ok` |
| `[T-Schlafli-Pencil]` | 超行列式的第二條獨立路徑：切片束 `det(x·T₀ + y·T₁) = ax² + bxy + cy²` 的判別式 `b² − 4ac`。在 `𝔽₃` 全部 6,561 個張量、三個軸向上逐一與 Cayley 12 項式對照 | `t3_slice_pencil_quadratic`、`t3_hyperdet222_via_pencil` |
| `[T-F3-Orbits]` | `𝔽₃^{2×2×2}` 在 `GL₂(𝔽₃)³`（階 110,592）與 `GL₂(𝔽₃)³ ⋊ S₃` 下的完整軌道分類；union-find 計數再以 Burnside 引理按共軛類（`8³ = 512` 次秩計算）獨立重算 | `f3_tensor222_orbit_report` |
| `[T-VR-Barcode]` | `𝔽₂` 上 Vietoris–Rips 持續同調條碼：位元壓縮欄 + Chen–Kerber clearing，一次約化得到所有尺度的 Betti 數；`n ≤ 16`，可截斷單形維度 | `metric_vr_persistence_barcode`、`vr_barcode_betti_at`、`vr_barcode_matches_per_scale_ranks`、`metric_cycle_graph` |

### 軌道分類結果（執行時算出，非引用）

| 軌道 | 大小 | 秩 | `Det` |
|---|---:|---:|---:|
| 零 | 1 | 0 | 0 |
| 純張量 | 128 | 1 | 0 |
| 三個「單軸退化」類（`S₃` 下合併為一個 576） | 192 × 3 | 2 | 0 |
| GHZ 類 | 3,456 | 2 | 1 |
| W 類（Segre 切叢） | 1,536 | 3 | 0 |
| `𝔽₉` 扭類 | 864 | 3 | 2（非平方） |

`GL` 軌道 8 個（Burnside 亦得 8），加 `S₃` 後 6 個；`(秩, Det)` 完全分離這 6 個軌道。

**更正**：`tensor_check_federation_laws` 舊註解把秩 3 的拆分寫成「864 個 `Det = 0` + 1536 個 `Det ≠ 0`」，方向相反。正確為 **1536（W 類，`Det = 0`）+ 864（扭類，`Det ≠ 0`）**；穩定子階 `110592/864 = 128 = |{(a,b,c) ∈ (𝔽₉ˣ)³ : abc = 1}| · 2` 可交叉核對。註解已改，數值現由第 6 節定律釘住。

### 既有程式的優化

`metric_vr_homology_report`：單形改以頂點位元遮罩儲存，團判定用鄰域遮罩，面的列號由 `index_of[mask]` 直接查表。邊界矩陣組裝由「每個面線性掃描 `C_{k-1}`」降為 `O(Σ_k k·|C_k|)`；輸出逐欄位不變（四個 `cmd` 的輸出與改動前逐位元相同）。

### 條碼範例

```moonbit
let c6 = @tensor.metric_cycle_graph(6)
let bars = @tensor.metric_vr_persistence_barcode(c6, 5)
// bars: [0,0,1]×5、[0,0,-1]、[1,1,2]（圓）、[2,2,3]（尺度 2 的八面體 S²）
```

主檢核：`tensor_check_orbit_pencil_persistence_laws(atlas)`，已接入 `tensor_check_federation_laws()` 第 6 節。
