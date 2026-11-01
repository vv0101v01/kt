# `webgpu/` — 零依賴單頁驗證台：瀏覽器免費 WebGPU（WGSL）對照 CPU SWAR

> **架構位置**：無 MoonBit 套件（純靜態資產），對應第八聯邦 `accel` 的**瀏覽器端對照頁**。
> 唯一檔案：`index.html`（475 行，內嵌 CSS + JS + 6 段 WGSL，**零外部依賴**）。

---

## 1. 這是什麼

一個**直接雙擊就能跑**的單頁驗證器：

1. 偵測瀏覽器 `navigator.gpu`（免費消費者級 GPU，無需 `f64`／`u64` 硬體擴充）；
2. 對 6 個 WGSL 計算核心做 **W3C 基線可移植性靜態審計**；
3. 用**純 JavaScript 重寫一份 CPU SWAR 位切片**，跑出 `𝔽₃^{2×2×2}` 全部 `6,561` 個張量的 Cayley 超行列式分佈；
4. 若環境有 WebGPU，再把同一份 WGSL 真的編譯、dispatch 上 GPU，**逐位比對** CPU 與 GPU 的答案。

換句話說：這一頁是 `accel/` 的「**可被任何人當場複驗**」入口 —— 不需要 MoonBit 工具鏈，不需要安裝任何東西。

---

## 2. 頁面結構

```text
┌ 標題：kt (cubical-hermitian v2) — 第八聯邦 @accel ─────────────────────┐
│ [GPU 狀態徽章]      [WGSL 靜態審計徽章]      [重新執行全部驗證]        │
├────────────────────────────────────────────────────────────────────────┤
│ 卡片 1  雙軌 GF(3) 位切片 6,561 張量超行列式        ← 有 GPU 時附 GPU 實測 │
│ 卡片 2  Ozaki Scheme II CRT 模數矩陣乘（無需 FP64）                     │
│ 卡片 3  32 位 RNS Stockham 免位反轉自動排序 NTT                         │
│ 卡片 4  Scanbox 解耦回看前綴掃描                                        │
│ 卡片 5  三相分塊熱帶 Kleene 閉包（16×17 共享記憶體）                    │
│ 卡片 6  HVM2 扁平競技場並行 active-pair 重寫                            │
└────────────────────────────────────────────────────────────────────────┘
```
每張卡片：標題 + `PASS` 徽章、論文家族（`paper`）、驗證結果行，以及可展開的 **WGSL 原始碼**。

---

## 3. 三個關鍵函式

| 函式 | 行數位置 | 作用 |
|---|---:|---|
| `auditKernel(k)` | ~307 | 靜態審計：`!/\b(f64\|u64\|i64)\b/` 檢查零 64 位型別；`wg[0]*wg[1]*wg[2] ∈ [1, 256]`；共享記憶體 `shmem ≤ 16,384` B；原始碼含 `@compute` + `@workgroup_size`。與 `accel/webgpu_wgsl_kernels.mbt` 的 `audit_wgsl_browser_portability` 規則一致 |
| `cpuBitslicedF3Sweep()` | ~317 | 把 6,561 個 base-3 code 切成 **206 個 32-lane 區塊**；每個區塊 8 個 trit 各存 `lo`/`hi` 兩軌 `Uint32`；以 6 個位元運算實作無分支 `GF(3)` 加法／乘法，最後 `popcount` 統計 |
| `runGpuF3IfAvailable(device, prep)` | ~368 | 建 shader module → compute pipeline → buffer → `dispatchWorkgroups(4)` → 讀回 `det=0/1/2` 三個計數 |

`runAll()`（~405）是主控：偵測 adapter（含 `subgroups` feature）→ 跑 CPU 對照 → 有 GPU 就實跑 → 逐卡審計並渲染。**任何一步失敗都會降級而不是崩頁**（`try/catch` 包住，徽章轉為 `warn`）。

---

## 4. 已知錨定值（可直接肉眼複驗）

```text
CPU SWAR 6,561 張量：det = 0 : 2241 , det = 1 : 3456 , det = 2 : 864
                     （合計 2241 + 3456 + 864 = 6561）
GPU 實測一致：gpuF3[0] === 2241 && gpuF3[1] === 3456 && gpuF3[2] === 864
```

這三個數字與 `accel/gf3_bitsliced_all_6561_hyperdeterminants()` 的結果相同（後者另給 `rank_counts = [1, 128, 4032, 2400]`，那是**秩**分佈，與**超行列式值**分佈是兩件事）。

---

## 5. 怎麼跑

```bash
# 方式 1：直接用瀏覽器開檔
xdg-open webgpu/index.html        # 或 Finder / 檔案總管雙擊

# 方式 2：本機起一個靜態伺服器（某些瀏覽器對 file:// 的 GPU 權限較嚴）
python3 -m http.server -d webgpu 8000
# 然後開 http://localhost:8000/
```

支援矩陣：Chrome / Edge 113+（`navigator.gpu` 已預設開啟）、Safari 26+、Firefox（`dom.webgpu.enabled`）。
**沒有 WebGPU 也能用**：頁面會自動切到「CPU SWAR 精確對照 + WGSL 靜態審計」模式，仍有完整資訊。

> 開發者提示：若在某環境看到 `GPU 編譯提示: …`，代表該裝置的 WGSL 實作缺少對應特性（例如 `subgroups`），CPU 對照值仍然有效 —— 這正是「免費瀏覽器基線 + 可移植回退」設計的目的。

---

## 6. 與 `accel/` 的對應關係

| 卡片（本頁） | MoonBit 對應 | 對照主定義 |
|---|---|---|
| 1 `bitsliced_f3_cayley_hyperdet` | `accel.gf3_bitsliced_all_6561_hyperdeterminants` / `wgsl_kernel_bitsliced_f3_hyperdet` | `@tensor.t3_hyperdet222` |
| 2 `ozaki2_crt_gemm` | `accel.ozaki2_int_gemm_dp4a` / `wgsl_kernel_ozaki2_dp4a_gemm` | `@algebra` 精確矩陣乘 |
| 3 `stockham_ntt_rns_u32` | `accel.stockham_ntt_u32` / `wgsl_kernel_stockham_ntt_u32` | 多項式精確卷積 |
| 4 `scanbox_decoupled_scan` | `accel.scanbox_decoupled_scan` / `wgsl_kernel_scanbox_decoupled_scan` | 前綴和（序列版） |
| 5 `tropical_blocked_kleene_apsp` | `accel.tropical_blocked_kleene_closure` / `wgsl_kernel_tropical_blocked_apsp` | `@semiring/trop` Kleene 閉包 |
| 6 `hvm2_inet_parallel_rewrite` | `accel.inet_normalize_waves` / `wgsl_kernel_hvm2_inet_rewrite` | Peano 算術（`a·b`） |

---

## 7. 維護守則

* **零外部依賴**：不得引入 CDN、字型、圖片（本頁完全內嵌，可在離線／沙盒環境運作）。
* **WGSL 必須過得了兩道審計**：本頁的 `auditKernel()` 與 `accel/audit_wgsl_browser_portability` 必須對同一份 `wgsl` 給出相同結論；改動任一邊時請同步另一邊。
* **錨定值不可悄悄改**：`2241 / 3456 / 864` 是數學事實（Cayley 超行列式在 `𝔽₃` 上的分佈），若顯示改變代表演算法壞了，而不是「換個基準」。
