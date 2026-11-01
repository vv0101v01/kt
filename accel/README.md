# `accel/` — CPU 64 位 SWAR 與瀏覽器免費 WebGPU（WGSL）六大前沿加速引擎

> **架構位置**：`architecture.json` 中的 `accel`，**Layer 4**，依賴 `gcd`、`cubical-face-bdd`、`algebra`、`semiring-trop`、`tensor`。
> 聯邦歸屬：**F8**（第八聯邦，硬體加速）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/accel`。瀏覽器對照頁：`../webgpu/index.html`。

---

## 1. 核心立場

> **不做環境敏感的效能基準測試；做逐位元數學等價證書。**

沙盒與雲端容器沒有穩定的實體 GPU 時脈，跑分沒有意義。因此本套件的每個加速核心都必須以**逐位（bit-exact）等價**證明自己算的是 `@gcd`／`@face_bdd`／`@algebra`／`@semiring/trop`／`@tensor` 的**同一個數學定義**；`verify_accel_federation()` 是總裁判。

第二條立場：**消費者級瀏覽器零擴充基線**。所有 WGSL 著色器不得使用 `f64`／`u64`／`i64`；高精度與大整數一律用 **Ozaki Scheme II 位元組模數 CRT** 或 **WebGPU 安全質數（`p < 46340`）多模 RNS** 精確重構。

---

## 2. 檔案清單（5 檔，約 2.7k 行）

| 檔案 | 行數 | 加速族 |
|---|---:|---|
| `bitslice_m4ri_f3.mbt` | 453 | ① `GF(2)` 位元打包 + M4RI Gray-code 矩陣乘／RREF；② `GF(3)` 雙軌 64-trit 無分支 SWAR + `6,561` 超行列式掃描；③ 64 路 `Face` 超立方體 `#SAT` |
| `ozaki2_ntt_rns.mbt` | 515 | ③ `INT8→INT32`（`dot4I8Packed` DP4A）Ozaki Scheme II CRT 精確／`FP64` 矩陣乘；④ 32 位 RNS Stockham 自動排序 NTT 與 30 位 Montgomery REDC |
| `scanbox_tropical_tile.mbt` | 473 | ⑤ Scanbox 解耦回看單遍前綴掃描（含 `subgroups` 特化）、Morton Z-序、`16×17` 無衝突共享記憶體三相熱帶 Kleene 閉包 |
| `hvm2_inet_arena.mbt` | 487 | ⑥ HVM2 扁平競技場並行交互組合子（`ANNI`/`COMM`/`ERAS`），機器驗證 Lafont 強合流定理 |
| `webgpu_wgsl_kernels.mbt` | 794 | 7 個 WGSL 計算著色器 + W3C 瀏覽器可移植性靜態審計 + 跨聯邦等價總驗 |

---

## 3. 六大加速引擎精讀

### 3.1 `GF(2)`：M4RI（Method of Four Russians）
```moonbit
pub struct Gf2BitMatrix { rows; cols; words_per_row; data : Array[UInt64] }
```
* `gf2_matmul_m4ri(a, b)`：Kronrod–Arlazarov–Albrecht–Pernet 的 **M4RM**，Gray-code 表寬 `k = 4` —— 對 `b` 的每個 4 列條帶預先算出全部 `2⁴ = 16` 種列組合，之後每個 `a` 的半字節只需一次查表 + XOR。
* `gf2_rref_rank_u64(a)`：以硬體 **count-trailing-zeros（`ctz`）** 找主元，整字 XOR 掃列做 RREF ⇒ 秩計算在 `O(n³/64)` 次字運算內完成。
* 對照定義仍來自 `@gcd`（`fp_rank` over `F₂`）與 `@face_bdd`。

### 3.2 `GF(3)`：雙軌 64-trit 位切片
```moonbit
pub struct Gf3Slice64 { lo : UInt64; hi : UInt64 }   // 0=(0,0), 1=(1,0), 2=(0,1)，不變量 lo & hi == 0
```
* `gf3_add64` / `gf3_neg64` / `gf3_sub64` / `gf3_mul64`：**無分支、無整數除法**的雙軌布林電路（Boothby–Bradshaw），一次處理 **64 個三元元素**；`gf3_mul64` 只要 6 個位元運算就得到 64 個乘積。
* `gf3_bitsliced_all_6561_hyperdeterminants()`：`ceil(6561/64) = 103` 次 SWAR 迭代掃完全部 `𝔽₃^{2×2×2}` 的 Cayley 超行列式，最後用硬體 `popcount` 統計 `{0,1,2}` 的分佈。
  **對照**：`@tensor.f3_tensor222_atlas_build()`（純量版，`6,561` 次呼叫）⇒ 兩者必須給出同一個秩分佈 `[1, 128, 4032, 2400]`。

### 3.3 `Face` 超立方體 `#SAT`
* `dim_truth_word64(dim, block)`：`@face_bdd.Dim` 在 64 個連續賦值上的真值字；
* `face_truth_word64(face, block)`：一個 `UInt64` 同時算出 `Face` 在 64 個超立方體頂點上的值；
* `face_swar_model_count(face, n_vars)`：以 `popcount` 得**精確** `#SAT` 模型數。
* 對照：`@face_bdd.bdd_dag_sat_count`（ROBDD 遞迴計數）。兩條完全不同的路徑必須一致。

### 3.4 Ozaki Scheme II：`INT8 → INT32` 的 CRT 精確矩陣乘
* `ozaki2_byte_moduli()`：八個互質奇質數 `m_i ≤ 251`；中心殘差落在 `[-125, +125]` ⇒ 塞進有號 `INT8`；`217 · 125² ≪ 2³¹` ⇒ `i32` 內積**不溢位**。
* `centered_smod_bigint(x, m)`：對稱中心殘差。
* `pack4_i8_to_u32` / `dot4_i8_packed`：**逐位元複製 WGSL 的 `pack4xI8` 與 `dot4I8Packed`（DP4A）語義**（lane 0 在 bits `0..7`）。這讓 CPU 端可以「模擬 GPU 指令」來驗證著色器。
* `garner_symmetric_crt_bigint`：Garner 混合基底對稱 CRT，從殘差還原 `X ∈ [-M/2, M/2)`。
* `ozaki2_int_gemm_dp4a(A, B)`：真正只靠 INT8 + DP4A 累加（每 ≤ 216 lanes 分塊）+ Garner CRT 的**精確**整數 GEMM。
* `ozaki2_emulate_fp64_gemm`：`FP64` 矩陣乘模擬 —— 抽列／行 2 的冪次尺度，把尾數量化成 `bits` 位整數（預設 `26` 位，使內積落在 8 模數 CRT 範圍內），最終以精確有理數還原。

### 3.5 RNS Stockham NTT 與 30 位 Montgomery
* `webgpu_rns_ntt_primes()`：`(12289, 18433, 40961)` —— 每個都 `< 46340 = ⌊√(2³¹)⌋`，故 `(a·b) < 2³¹` 在**單一** 32 位 `u32` GPU 乘法內完成，零 64 位模擬。
* `stockham_ntt_u32(...)`：Stockham **自動排序** radix-2 NTT，自然序進自然序出，靠 ping-pong 工作緩衝區，**免位元反轉**。
* `rns_stockham_poly_mul_exact(...)`：多模 RNS 卷積 + CRT ⇒ 精確多項式乘（係數不截斷）。
* `mont30_*`：30 位 Montgomery 規約（`mont30_ntt_998244353`、`mont30_redc`、`mont30_to_mont`、`mont30_from_mont`、`mont30_mul`），在不支援 64 位乘加的環境用 32 位分段乘法完成 `mod 998244353` 的 NTT。

### 3.6 Scanbox、Morton、熱帶閉包（`scanbox_tropical_tile.mbt`）
* `ScanboxTileDescriptor{ status; aggregate; inclusive_prefix }`：Contini / Merrill–Garland **解耦回看（decoupled look-back）** 的三態機（`0 NOT_READY`、`1 AGGREGATE_AVAILABLE`、`2 PREFIX_AVAILABLE`）；`scanbox_decoupled_scan` 是**單遍**前綴掃描（不需二次上掃），WebGPU 版另有 `enable subgroups;` 的 `subgroupInclusiveAdd` 特化。
* `morton_encode_2d` / `morton_decode_2d`：Z-序（空間填充曲線）布局，讓二維鄰居在記憶體上相鄰 ⇒ 快取不敏感。
* `tropical_blocked_kleene_closure`：**三相**分塊 `(min,+)` Kleene 閉包，共享記憶體用 `16 × 17`（`+1` 欄填充）消除 32-bank 衝突；結果必須等於 `@semiring/trop` 的 `apsp_kleene`。

### 3.7 HVM2 扁平競技場（`hvm2_inet_arena.mbt`）
* `INetArena`：**零 GC** 的埠索引整數競技場（`3 * node + port`），與 WebGPU `var<storage, read_write> peer : array<u32>` **同構**，可直接搬上 GPU。
* 節點標籤：`0 FREE`、`1 ROOT`、`2 ERA`、`3 CON`（建構子／`λ`／`app`）、`4 DUP`（複製扇，`label ≥ 1`）。
* 並行波同步重寫：`ANNI`（湮滅）、`COMM`（交換）、`ERAS`（擦除）；`inet_collect_active_wave` 收集當前所有 active pair —— 因為每個節點只有**一個主埠**，同一波內的 active pair 必定**點不相交**，這正是可安全平行的理由。
* `inet_normalize_waves(max_waves, schedule)`：`INetWaveSchedule` = `Forward` / `Reversed` / `OddEven` 三種波排程。
* `inet_encode_church_nat` / `inet_build_church_mul_net` / `inet_readback_church_nat`：把 Church 數乘法 `((λm.λn.λf.λx. m (n f) x) c_a c_b) (λz.S z) Z` 建成網並讀回 Peano 正規形。
* `inet_verify_church_mul_confluence(a, b)`：**Lafont 強合流定理**的機器驗證 —— 三種排程都必須得到同一個數值 `a·b`，且 `(anni_steps, comm_steps, eras_steps)` 三元組**完全相同**。

---

## 4. 七個 WGSL 計算著色器（`webgpu_wgsl_kernels.mbt`）

```moonbit
pub(all) struct WgslComputeKernel {
  slug; paper_family;
  workgroup_size : (Int32, Int32, Int32);
  shared_mem_bytes : Int32;
  uses_subgroups : Bool;
  wgsl_source : String;
}
```

| # | 著色器 | `workgroup_size` | 要點 |
|---|---|---|---|
| 1 | `wgsl_kernel_ozaki2_dp4a_gemm` | `16×16` | CRT 位元組模數分塊 GEMM，`dot4I8Packed` |
| 2 | `wgsl_kernel_stockham_ntt_u32` | `256` | 32 位 RNS Stockham NTT（`p < 46340`，零 `u64`） |
| 3 | `wgsl_kernel_bitsliced_f3_hyperdet` | `64` | 雙軌 `u32` 位切片 `GF(3)` 掃 `6,561` 超行列式 |
| 4 | `wgsl_kernel_scanbox_decoupled_scan` | `256` | 解耦回看前綴掃描（`use_subgroups` 切換 `subgroupInclusiveAdd` vs 共享記憶體基線） |
| 5 | `wgsl_kernel_tropical_blocked_apsp` | `16×16` | `16×17` 無 bank 衝突熱帶閉包 |
| 6 | `wgsl_kernel_hvm2_inet_rewrite` | `64` | 扁平競技場 active-pair 重寫 |
| 7 | （第 4 的子群特化版） | `256` | `enable subgroups;` 版本，與基線並列 |

`webgpu_frontier_kernel_suite()` 回傳全部 7 個。

### 靜態可移植性審計
```moonbit
pub fn audit_wgsl_browser_portability(k : WgslComputeKernel) -> WgslPortabilityAudit
```
檢查項（全部必須通過，否則審計失敗）：
1. 零 `f64`／`u64`／`i64` 純量；
2. `workgroup_size` 各維 `≤ 256`；
3. `var<workgroup>` 共享記憶體 `≤ 16,384` bytes；
4. 存在 `@compute @workgroup_size(...)` 入口；
5. `{}` 與 `()` 分隔符平衡（避免字串截斷造成的假陽性）。

對應規範：`agent.v2.md` §五。

---

## 5. 總裁判：`verify_accel_federation()`

```moonbit
pub fn verify_accel_federation() -> AccelFederationReport
```
逐一比對六大演算法族與其**數學主定義**：

| 加速實作 | 對照主定義 |
|---|---|
| `gf2_rref_rank_u64` / `gf2_matmul_m4ri` | `@gcd.fp_rank` / `@gcd.fp_mat_mul` over `F₂` |
| `gf3_bitsliced_all_6561_hyperdeterminants` | `@tensor.t3_hyperdet222`（`6,561` 個） |
| `face_swar_model_count` | `@face_bdd.bdd_dag_sat_count` |
| `ozaki2_int_gemm_dp4a` / `emulate_fp64_gemm` | `@algebra` 精確有理矩陣乘 |
| `rns_stockham_poly_mul_exact` / `mont30_*` | 整數多項式精確卷積 |
| `tropical_blocked_kleene_closure` | `@semiring/trop` 的 Kleene 閉包 |
| `inet_verify_church_mul_confluence` | Peano 算術（`a·b`） |

`bridge/accel_bridge.mbt` 會把這份報告轉成 `BridgeCertificate`，計入 `cmd/showcase` 的 **47/47**。

---

## 6. 範例

```moonbit
// 1) GF(2) 位元矩陣
let a = @accel.gf2_bit_matrix_from_ints(4, 4, entries)   // entries: Array[Int32] row-major of 0/1
println(@accel.gf2_rref_rank_u64(a))

// 2) 64 路 GF(3) 超行列式掃描（103 次 SWAR）
let rep = @accel.gf3_bitsliced_all_6561_hyperdeterminants()
debug_inspect(rep.rank_counts, content="[1, 128, 4032, 2400]")

// 3) Face #SAT（與 BDD 對照）
println(@accel.face_swar_model_count(f, 20))       // == @face_bdd.bdd_dag_sat_count

// 4) Church 乘法 × 三種波排程的強合流
let cert = @accel.inet_verify_church_mul_confluence(3, 4)
assert_true(cert.schedules_confluent)               // decoded_value == 12 且三排程步數三元組相同

// 5) WGSL 審計
for k in @accel.webgpu_frontier_kernel_suite() {
  assert_true(@accel.audit_wgsl_browser_portability(k).ok)
}
```

---

## 7. 依賴與邊界

* **依賴**：`gcd`、`cubical-face-bdd`、`algebra`、`semiring-trop`、`tensor`；**不依賴** `cubical/kernel`（加速層不需要可信核心，只需主定義）。
* **被依賴**：`bridge`（`accel_bridge.mbt`）、`root`。
* **設計準則**：任何新加速核心必須 (a) 提供等價證書入口，(b) 若上 GPU，必須通過 `audit_wgsl_browser_portability`，(c) 不得引入 `f64`/`u64`/`i64` 到 WGSL。

---

## 8. 驗證

```bash
moon test accel --target wasm-gc        # 單包即時微測試約 0.24s
moon run --release cmd/showcase --target wasm-gc
# 瀏覽器直開：../webgpu/index.html（自動偵測 navigator.gpu，並回退到 CPU SWAR 對照）
```
