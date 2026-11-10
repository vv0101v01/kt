# `symlib/core/` — 第五 `L0` 基石：無度數上限置換表、硬體位向量、Schreier–Sims 與個體化—精煉核心

> **架構位置**：`architecture.json` 中的 `symlib-core`（元件 `symlib-base`），**Package Layer 0 / Component Layer 0**，零外部業務依賴（`depends_on: []`）。
> 聯邦歸屬：**F2 `symlib`**（第二聯邦基礎核；`L1 symlib` 透過 `reexport_core.mbt` 之 `pub using @core` 100% 向後相容重導出）。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/symlib/core`。

---

## 1. 一句話定位

將有限對稱引擎中不依賴範疇論／Burnside 環的全部底層組合與群論原語拆為零外部依賴 `L0` 輕核，以硬體 `popcnt` 位向量、無度數上限 `PermLut`、零配置 Schreier 篩選與位向量 1-WL 顏色精煉支撐 McKay 個體化—精煉圖同構與置換群計算。

---

## 2. 檔案清單（11 個 `.mbt`，共 3,316 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `bitvec.mbt` | 212 | 64-bit 字組定長位向量 `BitVec`；硬體 `UInt64::popcnt()` 計數與零配置交集計數 `and_popcount`（`O(n/64)`） |
| `perm.mbt` | 272 | 置換 `Perm`（乘法 `a.compose(b)(x) = a(b(x))`）：恆等、逆、冪、循環分解、`perm_key64` 混合基數鍵 |
| `lut.mbt` | 241 | 雙層查找表：整數鍵開放定址 `KeyLut` ＋ **無度數上限 `PermLut`**（`n ≤ 15` 無乘法 4-bit Nibble SWAR，`n > 15` SplitMix64 64-bit 雜湊＋原像防碰撞核對，徹底解除舊版 `n ≤ 12` 硬上限） |
| `random.mbt` | 55 | 確定性 LCG 偽隨機流 `Rng`、Fisher–Yates 洗牌與 Erdős–Rényi `G(n, p)` 圖生成 |
| `group.mbt` | 619 | 增量 **Schreier–Sims** `PermGroup`：強生成集（SGS）、零配置 Schreier 對恆等快篩、`order`、`contains`、點穩定子，以及典型群建構器 `cyclic`、`dihedral`、`symmetric`、`alternating` (`A_n`)、`hyperoctahedral` (`B_n = (C_2)^n ⋊ S_n`) |
| `graph.mbt` | 350 | 簡單無向圖 `Graph`：排序鄰接陣列 ＋ `BitVec` 鄰接矩陣列（`O(1)` 邊查詢、`O(n/64)` 共同鄰居計數） |
| `partition.mbt` | 276 | 有序分割 `Part` 與 `BitVec::and_popcount` 驅動之等變 1-WL 顏色精煉 `refine_colors` |
| `search.mbt` | 755 | **核心引擎**：McKay 個體化—精煉回溯樹（等變簽名選取、自同構葉剪枝、字典序最優規範葉追蹤） |
| `aut.mbt` | 56 | 圖自同構群 `automorphism_group`、`aut_order`、`vertex_orbits`、`edge_orbits`、`automorphism_group_colored` |
| `action.mbt` | 293 | 有限群作用 `FinAction`：軌道分解、不動點、Burnside 引理 `burnside_orbits`，以及點／序對／無向邊誘導作用 `FinAction::derive`（含顯式邊保持不變量檢查） |
| `fold.mbt` | 187 | 軌道折疊 `OrbitFold`／商圖 `FoldedGraph` `X → X/G`、基本域 `fundamental_domain` 與分支壓縮比 |

---

## 3. 核心資料型別與演算法突破

* **`BitVec::and_popcount(a, b)`**：直接在 `FixedArray[UInt64]` 上執行 `(a.words[w] & b.words[w]).popcnt()` 累加，免除 1-WL 精煉內迴圈的暫存 `BitVec` 堆積配置。
* **`PermLut`（無度數上限置換雜湊表）**：
  * `n ≤ 15`：每個影像座標佔 4-bit nibble，以位元移位打包進單一 `UInt64` 鍵，消除 `(n+1)` 進位連乘與 `n = 15` 時 `16^15` 溢位。
  * `n > 15`：採 SplitMix64 混合雜湊定位開放定址槽位，並在桶內逐元素核對 `Perm` 陣列，精確支援任意有限度數置換群枚舉與子群格閉包。
* **零配置 Schreier 篩選（`group.mbt`）**：在 Schreier 對 `(u, g)` 進入 `sift` 配置新陣列前，先在原陣列上檢查 `trans[b][img[g(u)]] == u` 是否已為恆等置換，大幅削減高階群（如 `B_3(48)`、`A_5(60)`、`S_6(720)`）之短生命週期配置。

---

## 4. 已獲得定理與公開入口

| 標籤／定理 | 對應公開函式 |
|---|---|
| `[T-Schreier-Sims]` 強生成集軌道乘積群階公式 `\|G\| = ∏ \|Δ_i\|` | `PermGroup::order`、`PermGroup::contains` |
| `[T-Alternating-Hyperoctahedral]` 交錯群 `\|A_n\| = n!/2` 與超八面體群 `\|B_n\| = 2^n · n!` | `PermGroup::alternating`、`PermGroup::hyperoctahedral` |
| `[T-Burnside-Orbit]` 軌道數 `\|X/G\| = (1/\|G\|) ∑_{g∈G} \|X^g\|` | `FinAction::burnside_orbits`、`FinAction::orbits` |
| `[T-Equivariant-Refinement]` 1-WL 顏色精煉與圖同構等變性 | `refine_colors`、`search_graph` |

---

## 5. 依賴關係圖與輸出接口

```text
(零外部依賴 L0) symlib/core ──► L1 symlib (pub using @core 全量重導出)
                                   ├──► cmd/symdemo, cmd/symbench
                                   ├──► topos/site, condensed, cubical/structures, bridge
```

---

## 6. 驗證方式

`moon check --deny-warn --target wasm-gc` 零警告通過；所有群論、同構與軌道不變量由 `symlib/theorem_all.mbt`、`cmd/symdemo` 與 `bridge/f2_f3_f6_triad_bridge.mbt` 常駐執行核驗。
