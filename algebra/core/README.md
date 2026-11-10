# `algebra/core/` — 精確有理數快徑、一元多項式與 Bareiss／Ozaki-II 矩陣輕核

> **架構位置**：`architecture.json` 中的 `algebra-core`，**Package Layer 1 / Component Layer 1**，僅依賴兩個 `L0` 套件：`gcd` 與 `accel-swar`。
> 聯邦歸屬：**F1 `cubical`**（代數輕核；`L2 algebra` 透過 `reexport_core.mbt` 之 `pub using @acore` 100% 向後相容重導出全體 `16` 型別與 `172` 函式／常數）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/algebra/core`。

---

## 1. 一句話定位

將 `Rat`、`Poly`、`QPoly` 與 `QMat` 自重量級代數擴張／因式分解套件 `algebra` 中拆出為獨立 `L1` 核心，使 `topos`、`condensed`、`conjecture`、`accel` 與 `cubical/homotopy` 無須編譯分裂域塔與 LLL 即可獲得任意精度有理多項式與矩陣線性代數。

---

## 2. 檔案清單（3 個 `.mbt`，共 2,938 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `symalg.mbt` | 886 | 任意精度有理數 `Rat`（內建 `Int64` 無溢位分子分母快徑 `rat_fast_binop`，自動退回 `BigInt` GCD 約分）、整係數多項式 `Poly` 與符號有理分式運算 |
| `qpoly.mbt` | 970 | `ℚ[x]` 一元多項式 `QPoly`：歐幾里得長除、擴展 GCD、無平方分解（Yun / Musser）、微分、結式（Subresultant PRS）與多點求值 |
| `qmat.mbt` | 1082 | `ℚ` 上精確矩陣 `QMat`：高斯—若爾當 RREF、零空間、逆矩陣、**無分數 Sylvester–Bareiss `O(n³)` 行列式 `qmat_det`**、**無除法 Samuelson–Berkowitz + 多素數 CRT 特徵多項式 `qmat_charpoly_berkowitz_crt`**，以及串接 `@swar` 之 **Ozaki Scheme II CRT 有理矩陣乘 `qmat_mul_ozaki2_crt`** |

---

## 3. 核心演算法與已獲得定理

| 標籤／定理 | 演算法與複雜度 | 公開入口 |
|---|---|---|
| `[T-Rat-FastPath]` `\|a\|,\|b\| < 2^{30}` 時 `Int64` 二進位 Stein GCD 無堆積配置算術與 `BigInt` 語義逐位全等 | `O(log min(a,b))` 暫存器運算 | `Rat::add` / `sub` / `mul` / `div` |
| `[T-Bareiss-Det]` 整數清分母後 Sylvester–Bareiss 精確整除消元，無中間分數膨脹 | `O(n³)` 整數運算 | `qmat_det` |
| `[T-Berkowitz-CRT]` Toeplitz 無除法遞迴在多素數 `F_p` 上並行求特徵多項式，再經 CRT 與有理重構還原 | `O(n⁴)` 無分數爆炸 | `qmat_charpoly_berkowitz_crt` |
| `[T-Ozaki2-QMat]` 行列獨立清分母後以 `@swar.ozaki2_crt_gemm` INT8 DP4A 切片重建精確 `QMat` 乘積 | 常數級切片並行 | `qmat_mul_ozaki2_crt` |

---

## 4. 依賴關係圖與輸出接口

```text
L0 gcd + L0 accel/swar ──► L1 algebra/core
                              ├──► L2 algebra (pub using @acore 重導出)
                              └──► topos, condensed, conjecture, accel, cubical/homotopy
```

---

## 5. 驗證方式

`moon check --deny-warn --target wasm-gc` 零警告通過；由 `verify.mbt`、`bridge/accel_bridge.mbt`（`verify_f8_f5_f1_triad_bridge`）與 `cmd/showcase` 雙路徑對帳驗證。
