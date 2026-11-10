# `accel/swar/` — 零依賴 `L0` 64-bit 暫存器硬體加速原語全集

> **架構位置**：`architecture.json` 中的 `accel-swar`，**Package Layer 0 / Component Layer 0**，零外部業務依賴（`depends_on: []`）。
> 聯邦歸屬：**F8 `accel`**（直接向下賦能 `algebra/core`、`semiring/matrix`、`condensed/core`、`topos/site`、`scheme`、`tensor`、`conjecture/kernel` 與 `L4 accel`；`accel` 以 `reexport_swar.mbt` 全量重導出）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/accel/swar`。

---

## 1. 一句話定位

把單個 `UInt64` 暫存器當成 64 通道位元平面、32 通道雙軌 `GF(3)` 或緊湊交互網競技場，以零外部依賴 `L0` 基石形式消除高層代數、拓撲斯與同倫引擎中的逐位標量迴圈。

---

## 2. 檔案清單（6 個 `.mbt`，共 2,300 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `swar_primitives.mbt` | 290 | Boothby–Bradshaw 雙軌 64-trit `GF(3)` 無分支算術與全體 `6,561` 個 `2×2×2` 超行列式 103-chunk 掃描；64-bit 雙 Heyting 篩算子；64 樣本位平面蘊含與硬體 `ctz` 極小反例定位 |
| `m4ri_gf2.mbt` | 287 | `Gf2BitMatrix`、Four-Russians Gray-code M4RI `GF(2)` 矩陣乘法 `m4ri_gf2_mul`，以及字組並行高斯—若爾當消元 `gf2_rref_eliminate_u64`（單指令同時消去 64 欄） |
| `ozaki2_ntt_rns.mbt` | 541 | Ozaki Scheme II `INT8 DP4A` 切片多素數 CRT 精確矩陣乘、30-bit Montgomery 無除法模乘，以及 32-bit RNS Stockham 免位反轉數論變換 `poly_mul_rns_ntt` |
| `cubical_degeneracy_core.mbt` | 366 | 64-bit 立方體退化遮罩 `O(1)` 合成、位元蝴蝶面抽取 `cube64_extract_face_swar`、退化插入 `cube64_insert_degeneracy_swar` 與交替面微分 `∂² = 0` |
| `scanbox_morton_core.mbt` | 350 | Scanbox 解耦回看並行前綴掃描（Decoupled Look-back Prefix Scan）與 2D/3D Morton Z-階空間填充曲線位元交錯 |
| `hvm2_inet_arena.mbt` | 466 | HVM2 扁平陣列競技場 `INetArena` 並行交互組合子（Lafont Interaction Combinators）與閉合 Peano `λ` 項求值器 `inet_eval_closed_peano_lam` |

---

## 3. 核心定理與公開入口

| 標籤／定理 | 公開入口 |
|---|---|
| `[T-GF3-6561-SWAR]` 雙軌 64-trit 掃描全體 `6,561` 張量超行列式分佈 `2241 + 3456 + 864 = 6561` | `gf3_sweep_all_6561_hyperdets` |
| `[T-M4RI-RREF-U64]` Gray-code 表驅動 `GF(2)` 矩陣乘與 64-bit 字組並行 RREF 等價性 | `m4ri_gf2_mul`、`gf2_rref_eliminate_u64` |
| `[T-Ozaki2-Stockham]` INT8 切片 CRT 重建精確整數／浮點 GEMM 與 Stockham RNS 多項式卷積 | `ozaki2_int_gemm_dp4a`、`poly_mul_rns_ntt` |
| `[T-Cube64-Butterfly]` 64-bit 蝴蝶面抽取與退化插入滿足全套立方體恆等式與 `∂_{k-1}∘∂_k = 0` | `cube64_degeneracy_mask`、`cube64_extract_face_swar` |
| `[T-HVM2-Confluence]` 交互網正向與反向排程強合流並與依賴型 NbE 閉合 Peano 求值一致 | `inet_eval_closed_peano_lam` |

---

## 4. 依賴關係圖與驗證

* 上游依賴：無（`L0` 零外部業務依賴，僅使用內建硬體指令 `popcnt` / `ctz` / `clz`）。
* 下游消費者：`algebra/core`、`semiring/matrix`、`condensed/core`、`topos/site`、`scheme`、`tensor`、`conjecture/kernel`、`accel`、`bridge`。
* 驗證方式：`moon check --deny-warn --target wasm-gc` 零警告；由 `verify.mbt`、`bridge/accel_bridge.mbt` 與 `cmd/showcase` 常駐核驗。
