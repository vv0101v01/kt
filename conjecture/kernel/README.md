# `conjecture/kernel/` — 解耦科學發現算子核心：Half-GCD 有理重構與 64-bit 位平面蘊含格

> **架構位置**：`architecture.json` 中的 `discovery-kernel`，**Package Layer 3 / Component Layer 4**，僅依賴 `gcd`、`accel-swar` 與 `tensor`（零 `condensed`/`topos`/`scheme` 高層耦合）。
> 聯邦歸屬：**F7 `discovery`**（`L5 conjecture` 透過 `reexport_kernel.mbt` 之 `pub using @kernel` 100% 向後相容重導出）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/conjecture/kernel`。

---

## 1. 一句話定位

將自動化猜想發現中最核心的兩項多項式時間算子——**任意分母 `< √(p/2)` 之模有理守恆律重構**與 **64 樣本暫存器並行蘊含／極小反例抽取**——抽離為輕量獨立核心。

---

## 2. 檔案清單（1 個 `.mbt`，共 418 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `discovery_kernel.mbt` | 418 | Wang–Guy–Davenport Half-GCD 歐幾里得截斷有理重構 `half_gcd_rat_recon`（突破舊版 `mult ≤ 64` 試乘上限，精確還原大質數係數守恆律如 `109x - 173y = 0`），以及串接 `@swar.swar_bitplane_implication_cex` 之 64-bit 位平面蘊含格與硬體 `ctz` 極小反例定位引擎 `implication_lattice_build` |

---

## 3. 核心定理與公開入口

| 標籤／定理 | 公開入口 |
|---|---|
| `[T-HalfGCD-Recon]` 當 `2\|a\|\|b\| < p` 且 `gcd(a,b)=1` 時，`half_gcd_rat_recon(r, p)` 在 `O(log p)` 步內唯一還原 `a/b ≡ r (mod p)` | `half_gcd_rat_recon`、`discover_modular_conservation_laws_hgcd` |
| `[T-Bitplane-Implication]` 64-bit 位平面蘊含矩陣與 `(w << 6) + (P_i & ~P_j).ctz()` 極小反例索引與逐點掃描全等 | `implication_lattice_build`、`verify_discovery_kernel_suite` |

---

## 4. 依賴關係圖與驗證

* 上游依賴：`gcd` (`L0`)、`accel/swar` (`L0`)、`tensor` (`L2`)。
* 下游消費者：`conjecture` (`L5`)、`bridge` (`L8`)（支撐 `F7 → F9 → F4 → F1` 四聯邦自動晉升鏈）。
* 驗證方式：`moon check --deny-warn --target wasm-gc` 零警告；由 `verify.mbt`、`bridge/meta_k9_unification.mbt` 與 `cmd/showcase` 常駐驗證。
