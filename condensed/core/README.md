# `condensed/core/` — 凝聚輕核：射影有限塔、構造性 Nöbeling 自由基底與 64× `@swar` Steenrod–Adams

> **架構位置**：`architecture.json` 中的 `condensed-core`（元件 `condensed-base`），**Package Layer 1 / Component Layer 2**，僅依賴兩個 `L0` 套件：`gcd` 與 `accel-swar`。
> 聯邦歸屬：**F6 `condensed`**（凝聚數學核心；`L4 condensed` 透過 `reexport_core.mbt` 之 `pub using @core` 100% 向後相容重導出）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/condensed/core`。

---

## 1. 一句話定位

將凝聚數學中不耦合 `scheme`/`topos`/`symlib` 的純同調與固態模引擎獨立為 `L1` 輕核，實作構造性 Nöbeling 自由整數基底、Roos–Milnor `R¹lim` 幽靈障礙，以及串接 `@swar.gf2_rref_eliminate_u64` 之 64× 加速 Steenrod–Adams 極小分解。

---

## 2. 檔案清單（2 個 `.mbt`，共 1,953 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `profinite_solid.mbt` | 917 | 有限逆系 `CondProfinite`、緊緻函數型射影塔 `CompactProfiniteTower`、**構造性 Nöbeling 分層纖維單模基底 `nobeling_unimodular_basis_zmat`**、固態對偶 `verify_nobeling_free_solid_duality`、Roos–Milnor 轉移餘核 `rlim_zmat_endomorphism`、`CondAnima` 與 `CondSolidModule` |
| `spectral_homotopy.mbt` | 1036 | 濾過鏈複形譜序列、Serre 收斂、**齊次 `t`-分塊 64-bit `@swar` Steenrod–Adams 極小分解 `minimal_resolution_ext_f2`**、前沿報告 `adams_ext_swar_frontier_report`（`trunc_deg=12`）、Koszul `Tor` 與凝聚譜層 `CondSpectralSheaf` |

---

## 3. 核心定理與演算法突破

| 標籤／定理 | 數學內容與演算法 | 公開入口 |
|---|---|---|
| `[T-Nobeling-Solid]` 有限射影塔上局部常值整數函數環 `C(S, ℤ) ≅ ⨁ ℤ` 具顯式上三角分層示性函數基底 `B_ℤ`，Bareiss `\|det(B_ℤ)\| = 1` 且 SNF 全為 `1`，對偶固態自由模 `ℤ[S]^■ ≅ ∏ ℤ` | `O(\|S_L\|^3)` 單模基底合成與 Bareiss／SNF 雙路徑核驗 | `nobeling_unimodular_basis_zmat`、`verify_nobeling_free_solid_duality` |
| `[T-Roos-Milnor-R1lim]` 逆系 `… → ℤ →^{×p} ℤ` 之轉移算子 `I - T` 餘核不變因子精確捕捉 `R¹lim` 非零障礙與 Mittag-Leffler 消滅判準 | `ℤ`-SNF 餘核不變因子分解 | `rlim_zmat_endomorphism` |
| `[T-Adams-SWAR-Frontier]` Steenrod 代數 `A` 上按內部次數 `t` 齊次分塊並以 `@swar.gf2_rref_eliminate_u64` + 64-bit `ctz` 稀疏基底計算 `Ext_A^{s,t}(F_2, F_2)`（`s ≤ 4, t ≤ 12`）：機器證明四個 Hopf 不變量類 `h_0, h_1=η, h_2=ν, h_3=σ`、Adem 非 2-冪消滅定理，以及 **`Ext_A^{3,6} = 1`（`h_1^3 = h_0^2 h_2` / `η³ = 4ν`）** | 64× 位元字組並行 `GF(2)` RREF | `minimal_resolution_ext_f2`、`adams_ext_swar_frontier_report` |

---

## 4. 依賴關係圖與輸出接口

```text
L0 gcd + L0 accel/swar ──► L1 condensed/core ──► L4 condensed (pub using @core 重導出)
                                                    └──► conjecture, bridge, cmd/showcase
```

---

## 5. 驗證方式

`moon check --deny-warn --target wasm-gc` 零警告通過；由 `verify.mbt`、`bridge/f2_f3_f6_triad_bridge.mbt` 與 `cmd/showcase` 持續執行驗證。
