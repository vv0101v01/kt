# `ualg/cube/` — 立方體上的層化 × 立方體上的雙重否定核子

> **架構位置**：`architecture.json` 的套件 `ualg-cube`，聯邦 `ualg`，**Layer 2**，
> `depends_on: [ualg-core, ualg-site, ualg-demorgan]`。只匯入本聯邦與 `moonbitlang/core`。

## 1. 一句話定位

把**預層模板**（`ualg/site`）與 **De Morgan 面格**（`ualg/demorgan`）裡的「j = ¬¬、層化、左伴隨」
整個搬到立方體 □ⁿ（面偏序 Vⁿ）上，做成兩個可以重算的大項：

* **大項一（層化）**：Sh_¬¬(□ⁿ) ≃ **Set^{頂點}** —— 立方體上 ¬¬-層由 2ⁿ 個頂點上的值自由決定；
  層化 a 有公式 `a(F)(x) = ∏_{v ≤ x} |F(v)|`，子複形的層化 = 頂點閉包，Ω_¬¬ 的大小 = 2^{2^{dim x}}。
* **大項二（雙重否定核子）**：面 Heyting 代數上 j = ¬¬；Glivenko：Fix(¬¬) ≅ P(頂點) 布林代數；
  j ⊣ i 左伴隨；[T-Bool] 的第三條路徑；球面與填充在 ¬¬ 下不可分。

## 2. 檔案與依賴圖

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `faces.mbt` | 97 | 面（三進位碼）↔ 頂點遮罩（二進位索引）的雙重索引；頂點閉包 `dneg_vertex`、∂σ `face_boundary` |
| `sheaf.mbt` | 333 | `psh_times`／`psh_sum`／`psh_tensor`（F×G、F+G、F⊠G）、`min_below`、`rho_bijective`／`rho_eta`、`psh_vertex`（由頂點賦值構造層）、`nat_product`、70 個 V 上預層窮舉、V² 拒絕採樣器 |
| `cubical_sheaf.mbt` | 452 | 大項一定律 `law_cubical_sheafification()`（16 個命題） |
| `dneg.mbt` | 294 | 大項二定律 `law_double_negation_nucleus_cubical()`（10 個命題）＋共用的 `chk`／`show_ints`／`lcg` |
| `laws.mbt` | 18 | `all_laws()`：兩個章節 |

```
moonbitlang/core        ualg/site            ualg/demorgan
      │                 (Poset/Vⁿ、j_dneg、  (face_open/open_face、
      │                  Presheaf、層化)      open_face、面碼、face_dim)
      │                    │                     │
      └────────────────────┴─────────┬───────────┘
                                     ▼
                               ualg/cube
                                     │
                                     ▼
                               cmd/ualg（Layer 3）
```

## 3. 得到的定理（含算出的數字）

### 大項二 — 立方體上的雙重否定核子（10 個命題）

| 標籤 | 敘述 | 驗證 |
|---|---|---|
| 規模 | \|O(V³)\| = 15,936 = `face_count_recursive(3)` | 列舉 × 遞推 |
| [T-Cube-1] | j 的兩條獨立路徑逐點相同：`hneg∘hneg` = 「f 的頂點全在 u」 | n = 1, 2, 3，15,989 個開集 |
| 核子（一元） | `u ≤ j(u)`、`j(j(u)) = j(u)`、`j(∅) = ∅` | n ≤ 3 全部開集 |
| 核子（二元） | `j(u∧v) = j(u)∧j(v)` | n ≤ 2 窮舉 2,329 對；n = 3 偽隨機 1,200 對 |
| **Glivenko** | Fix(¬¬) = {u_S : S ⊆ 頂點}；u_S ↦ S 是 **P(頂點) ≅ Fix(¬¬)** 的布林同構：保補 `¬u_S = u_{~S}`、保交、Fix 內的併 = j(u∨v) | n ≤ 3 窮舉；正則子複形數 **4、16、256** |
| j ⊣ i | `j(u) ≤ v ⇔ u ≤ v`（v 取正則開集） | n ≤ 3 |
| [T-Bool-cube] | DM(n) 布林反射的核 = j 的核（hneg-路徑 = 頂點路徑），類數 4、16 | 兩個分割互相細化（`core.part_leq`） |
| ∂σ ~ ↓σ | dim ≥ 1 的面（共 25 個）：球面與填充的 ¬¬ 相同 | n ≤ 3 |
| j 不保併 | n = 1, 2 的開集對中共 **484** 組 `j(u∨v) ≠ j(u)∨j(v)` | 反例對照 |
| 量詞×¬¬ | j∃i ≠ ∃i j 共 **4** 組；j∀i ≠ ∀i j 共 **44** 組（𝔽(2) 48 公式 × 2 方向） | 反例對照 |

### 大項一 — 立方體上的層化（16 個命題）

| 標籤 | 敘述 | 驗證 |
|---|---|---|
| 偏序積 | V×V = V²、V×V² = V³（down/up 遮罩逐點相同） | 位元遮罩比較 |
| **[T-Cube-S2]** | 子終預層 = 子複形；¬¬-層恰為正則子複形，**4、16、256** 個 | n = 1, 2 以 `is_sheaf` 窮舉全部子複形；n = 3 以格刻畫 j(K) = K 窮舉 15,936 個 + 4 個代表元直接 `is_sheaf` |
| **[T-Cube-S1]** | Sh_¬¬(□ⁿ) ≃ Set^{頂點}：ρ 逐點雙射；顯式同構 `ρ : F ≅ F̂(F\|頂點)` 是自然同構 | n = 1（V¹ 的 10 個層）、n = 2（16 個子終層） |
| **[T-Cube-S2]** | **a(K) = u_{verts K}**（子複形的層化 = 頂點閉包） | n = 1、2 全部 5 + 48 個；n = 3 抽 60 個 + 對帳 |
| **[T-Cube-S3]** | `a(F)(x) = ∏_{v ≤ x} \|F(v)\|`；aF 是層；冪等 `a(aF) ≅ aF`；**F 層 ⇔ η 同構** | n = 1 全部 **70** 個大小 ≤ 2 預層；n = 2 全部子終 + 4 常數 + 60 個 LCG 合法隨機預層（112 個） |
| **[T-Cube-S3]** | a(Δ2)、a(Δ3) 在 V³：\|F(x)\| = k^{2^{dim x}}（頂纖維 256、6561） | 直接構造 + 伴隨單位驗證 |
| **[T-Cube-S4]** | **層化只經由頂點決定**：a(aF⊠aG) = a(F⊠G)（Künneth）、a(F×G) = aF×aG（i 右伴隨保極限）、a(F+G) = a(aF+aG)（a 左伴隨保 Sh-餘積） | 258 對（V pool × 6 個 G） |
| **[T-Cube-S5]** | **\|Ω_¬¬(x)\| = 2^{2^{dim x}}**（顏色：Ω_¬¬ 是 Sh 的子對象分類子） | n = 1、2、3 全部面（含 V³ 的 27 個面） |
| [T-Cube-S5] 對照 | id-核子的 Ω_id：頂大小 = 48 ≠ 2⁴ | 失敗即成功 |
| **[T-Cube-S6]** | a ⊣ i 計數：\|Nat(aF,G)\| = \|Nat(F,G)\|（V¹：86 對；V²：子終層 × {Ω_¬¬, Δ1}，32 對）；層 F、G：\|Nat(F,G)\| = ∏_v \|G(v)\|^{\|F(v)\|} | `count_nat` 窮舉 |
| [T-Cube-S6] 對照 | G = Ω（非層）：16 ≠ 47（伴隨在非層目標上失效） | 反例 |

## 4. 演算法

| 演算法 | 位置 | 說明 |
|---|---|---|
| 頂點遮罩雙重索引 | `faces.mbt` | 三進位面碼 ↔ 二進位頂點索引；O(3ⁿ·2ⁿ) 建表 |
| `dneg_vertex` | `faces.mbt` | ¬¬u = {f : verts(f) ⊆ u}，與 Heyting 路徑互相對帳 |
| `vertex_closure` | `faces.mbt` | S ↦ u_S（P(頂點) → Fix(¬¬) 的同構的計算核心） |
| `psh_vertex` / `rho_eta` | `sheaf.mbt` | Set^{頂點} → Sh_¬¬ 的顯式嵌入；ρ 的自然變換表 |
| `psh_times` / `psh_sum` / `psh_tensor` | `sheaf.mbt` | F×G（極限）、F+G（餘極限）、F⊠G（外部積，編碼 `a + |P|·b`） |
| 70 個預層窮舉 | `sheaf.mbt` | V 上大小 ≤ 2 的全部函子（70 個） |
| V² 拒絕採樣 | `sheaf.mbt` | LCG 隨機映射 + `psh_ok` 驗證函子性（60 個） |
| 核子計數／Glivenko 普查 | `dneg.mbt`、`sheaf.mbt` | `site.fixed_points`、`site.is_sheaf`、`site.sheafify`、`site.count_nat` 的立方體特化 |
| 記憶化 j | `cubical_sheaf.mbt` | j 是冪等的；對開集表做 Map 記憶化（V³ 的 15,936 個開集 × j） |

## 5. 流程與輸入／輸出

```
輸入：n（1..3）、偏序／立方體面碼
  poset_cube(n) ──► 開集列舉（site）──┐
                                       ├──► j（Heyting 或頂點路徑）
頂點賦值 S : 2ⁿ → FinSet ──► psh_vertex ─┤        │
一個預層 F ───────────► sheafify ───────┘        ▼
                          a(F), η ────► 驗證（層、ρ、冪等、伴隨計數、Ω 公式…）

all_laws() = [("立方體上的層化…", law_cubical_sheafification()),
              ("立方體上的雙重否定核子…", law_double_negation_nucleus_cubical())]
cmd/ualg：逐條印出；任一為假 ⇒ abort
```

* **輸入**：無外部檔案。
* **輸出**：26 個命題（16 + 10），標籤內嵌執行時算出的數字。

## 6. 驗證

```bash
moon check --deny-warn --target wasm-gc     # 0 warning / 0 error
moon run cmd/ualg --target wasm-gc          # 通過 167 / 167 個命題
python3 tools/arch_check.py                 # architecture ok: 49 packages, 58 components, 272 .mbt
```

## 7. 界線與修正記錄

### 本輪（2026-11-10）被計算否定／修正的四個首版斷言

1. **a(F⊠G) ≅ aF⊠aG 為假**：V² 上取 F = G = Δ2，(aF⊠aG)(邊) = 2·4 = 8，但 a(Δ4)(邊) = 4² = 16。
   正確形式（左伴隨只保 colimit；層的外部積要在 Sh 裡再取一次層化）：
   **a(aF⊠aG) = a(F⊠G)**——層化只經由頂點決定。已改為此檢查。
2. **a(F+G) ≅ aF+aG（逐點）為假**：(aF+aG)(x) = ∏(f+g) ≠ ∏f + ∏g。
   左伴隨保 **Sh-餘極限**：a(F+G) ≅ a(aF+aG)（不是逐點餘積）。已改。
3. **Glivenko 中「Fix(¬¬) 保併」為假**：Fix(j) 的併是 **j(u∨v)**（不是 u∪v）；
   冪集映射 S ↦ u_S 不保 ∪（邊 {0,1} 的例子）。已改為「交保住、併為 j(u∨v)」；併的反例計數另在定律裡（484 組）。
4. **∂σ ≡ ↓σ 對 σ = 頂點不成立**：∂(頂點) = ∅，j(∅) = ∅ ≠ {v} = j({v})。
   已限制在 dim ≥ 1 的面（25 個），並把頂點情形寫進標籤。

### 未做

* V³ 的二元核子公理只驗了偽隨機 1,200 對；窮舉要 254M 對，沒有做。
* Ω_¬¬（V³）只驗了大小（27 個面的 2^{2^d}），沒有驗限制映射的具體形式。
* Sh_¬¬(□ⁿ) ≃ Set^{頂點} 是**對尺寸的窮舉驗證 + ρ 的顯式自然同構**；不是類型論意義的證明。
* 沒有與 `topos/`（site_presheaf.mbt）或 `cubical/` 橋接；核子普查仍只在小偏序（V）可行。
* 層化的伴隨計數在 V² 只對子終層 × {Ω_¬¬, Δ1}（32 對）；沒有對一般層計數。
