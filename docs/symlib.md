> **合併後位置**：本文由 algorithm03（`05232fd`）原 README 遷移而來。
> 程式碼現位於 `symlib/`，套件路徑為 `vv0101v01/cubical-hermitian/symlib`；
> 演示與基準分別為 `cmd/symdemo`、`cmd/symbench`。文中的「單子」指
> **monad（單子函子）**，不要與 semiring 支柱的 **monoid（么半群）**混淆。

# symlib — 演算法數學庫（MoonBit）

以**圖自同構群**為核心的演算法數學庫：數學結構圖、規範形式、群作用、軌道折疊、單子、
範疇化（有限範疇 / Yoneda / Kan 擴張 / G-集 / Burnside 環 / table of marks），
全部演算法處於**同一作用域**、互相作用，並以統一引擎管理計算複雜度。

第二階段在規範形式與範疇化兩層之上**擴展定理**，並由定理**衍生新演算法**
（免搜索的積公式、免搜索線圖的 Whitney 提升、一次搜索得兩份規範形式的補圖對偶、
免階乘枚舉的 G-集標記判別、Cayley 嵌入、規範折疊），全部定理以**機器可驗證證書**
（`Cert`）表達，並由 `prove_graph` / `prove_pair` / `prove_all` 三組電池自動跑驗。

**第三階段是全代碼健檢**（除錯 / 去重 / 減債 / 清死碼）：刪掉 9 個無人使用之定義、
把 8 份在測試與 cmd 中各自複製的本地工具上收為庫 API（`random.mbt`、`Graph::disjoint_union`、
`ints_to_string`…）、把 1444 行/1111 行/1109 行三個巨檔依關注點切分、204 行的
`subgroup_classes` 與 459 行的 `prove_all` 拆成具名輔助、為 10 個型別補上 `Debug`
（於是 `assert_eq` 能印結構化差異）、並修掉一個**真實的計時單位 bug**
（`monotonic_clock_end` 回傳微秒却被當毫秒 ⇒ 過去所有絕對時間放大 1000 倍）。
詳見 §10。

```
moon test symlib                            # 69 個測試（原 67 + 合併後 colored search 2 個）
moon run cmd/symdemo --target native --release  # 全模組演示（§1–§9，含定理電池與衍生演算法對照）
moon run cmd/symbench --target native --release # 性能基準（12 個圖譜 + 7 組衍生演算法對照）
```

---

## 1. 架構：一次搜索，多模組消費

```
                    ┌─────────────────────────────┐
   Graph（結構圖）──▶│  Search：個體化-精煉引擎     │
                    │  （等變精煉 + 前綴剪枝 +     │
                    │    軌道剪枝 + 自同構發現）   │
                    └──────┬──────────────┬───────┘
                     規範編碼/標號      自同構生成元
                           │              │
        ┌──────────────────┼──────┐  ┌────▼───────────┐
        │                  │      │  │ PermGroup       │
   ┌────▼─────┐   ┌────────▼───┐  │  │ Schreier–Sims   │
   │ Canon    │   │ Dual 補圖   │  │  │ 群階/成員/穩定子 │
   │ 規範形式  │   │ Line 線圖   │  │  │ elements 元素表 │
   │ 同構判定  │   │ Decomp 分解 │  │  └────┬───────────┘
   └────┬─────┘   └────────┬───┘  │       │
        │     labeling_perm│共軛搬運        │
        └──────────────────┼───────────────┤
                    ┌──────▼───────────────▼──────┐
                    │ FinAction 群作用（點/邊/序對）│
                    │ OrbitFold 軌道折疊（商結構）  │
                    │ GSet G-集：標記向量/Burnside環│
                    │      Cayley 圖/PermSet 規範鍵 │
                    │ Cat 作用廣群（範疇化）        │
                    │ Yoneda 預層/comma/Lan/Ran     │
                    │      歸納=G×X、上歸納=X^G      │
                    └──────┬──────────────────────┘
                           │
              ┌────────────▼─────────────┐   Monad（ListM/StateM）貫穿管線：
              │ Report 管線（analyze）    │   analyze_m 以 StateM 線程化統計；
              │ Theorem 證書電池（Cert）  │   isomorphisms_m 以 ListM 列舉全部同構；
              └──────────────────────────┘   csp_limit（極限）== search_nd（單子）。
```

底層共用件：`BitVec`（O(n/64) 集合運算）、`Perm`（置換代數）、`Part`（有序分割 + 等價精煉）、
`KeyLut`（64 位元鍵之開放定址表，零配置反查）。

**同一作用域的意義**：搜索引擎的一次 DFS 同時產出規範形式與自同構生成元；
群結構餵給作用、折疊、G-集與 Cayley 圖；折疊反過來壓縮搜索空間（軌道代表分支）；
範疇層（Lan/Ran）把「歸納/上歸納 G-集」與「群作用」接起來，並用 `csp_limit`
把約束滿足寫成極限，再由單子 `search_nd` 求同一解集（互相驗證）——
各演算法互為輸入輸出，避免重複計算（`analyze` 全流程只做一次搜索）。

---

## 2. 演算法與複雜度

### 2.1 Search — 個體化-精煉（Individualization–Refinement）

規範形式與自同構群的共用引擎（`search.mbt`）。

- **等變精煉**：簽名 = (顏色, 各顏色類鄰居計數, 對已放置前綴的鄰接位遮罩, 到前綴的 BFS 距離)，
  以**可加雜湊**聚合（O(deg)/點），按簽名排序後以字典序秩重新編號 ⇒ 精煉結果與頂點編號無關
  （重標號等變），故可安全作規範化依據。
- **候選規則**：下一位置的候選 = 未放置頂點中簽名最小者。等變規則 ⇒ 探索集在重標號下
  對應 ⇒ 最小葉編碼是**完全不變量**（G ≅ H ⇔ canon(G) = canon(H)）。
- **前綴編碼剪枝**：編碼採列主序 `idx(i,j) = j(j-1)/2 + i`（i<j）。左到右填位置 ⇒
  深度 r 的節點已確定前 r(r-1)/2 位且**連續**；前綴大於最優前綴 ⇒ 整枝剪掉（可靠剪枝）。
- **軌道剪枝**：固定前綴的已發現自同構構成路徑穩定子；候選集每軌道只走一個代表。
  φ 固定前綴 ⇒ v 分支與 φ(v) 分支的葉編碼**逐位相同** ⇒ 最小葉不丟失。
- **自同構發現**：葉編碼 == 最優編碼 ⇒ `best_lab → lab` 的映射為自同構候選（逐一驗證後收集）。

複雜度：每節點精煉 O(rounds·(m + u log u))；最壞情形指數級（圖同構問題本性），
但前綴 + 軌道雙剪枝使高度對稱圖（K_n、C_n、Q_k）的節點數降至 O(n²) 級。

**剪枝紀律（`search_graph_mode`）**：

| 模式 | 說明 | 規範形式 | 自同構生成元 |
|---|---|---|---|
| 0 | 無軌道剪枝 | ✓ 完整 | ✓ 完整 |
| 1（預設） | 靜態：節點入口計算軌道代表 | ✓ 完整 | ✓ 完整 |
| 2 | 動態：逐候選即時重算軌道 | ✓ 完整（指紋與 0/1 一致，已測試） | ⚠ 可能只生成子群 |

模式 2 節點數最少（Petersen：881 → 385 → 69），每次跳過都附帶合法見證自同構
（`search_bad_witness` 恆為 0，已測試），但激進剪枝會跳過部分平手葉，令發現的
生成元只張成真自同構群的子群——故**預設為模式 1**；模式 2 適合「只要規範形式/指紋」的快速路徑。

### 2.2 Canon — 規範形式

- `canonical_labeling` / `canonical_form` / `canon_encoding`
- `canon_digest`：編碼位串打包為 64-bit 字組的十六進制指紋，同構判定 O(n²/64)
- `isomorphic`：快速否證（度序列 + 精煉顏色多重集）→ 指紋比較
- `isomorphism`：由兩圖規範標號合成**顯式同構** σ（並驗證）
- **`labeling_perm`（衍生）**：規範標號陣列 → 重標號置換 σ（σ(lab[i]) = i）。
  有了 σ，任何在原標號下算得的自同構 p 可用 `p.conjugate_by(σ)` = σ∘p∘σ⁻¹ 搬到規範標號下
  ⇒ **一次搜索同時得到規範圖與規範標號下的 Aut**（`fold_canonical` 據此免第二次搜索）。

### 2.3 PermGroup — 增量 Schreier–Sims

- 強生成集：軌道-穩定子鏈 G = G⁽⁰⁾ ⊵ G⁽¹⁾ ⊵ … ⊵ 1
- **群階 = Π|軌道ᵢ|**（軌道-穩定子定理）——免列舉元素，S_20 的階（≈2.4×10¹⁸）瞬時可得
- 成員判定（sifting）O(深度·n)；`elements(cap)` 經橫截積唯一分解 g = u₀∘u₁∘… 列舉（小群）
- `stabilizer` / `pointwise_stabilizer`：Schreier 引理
- **關鍵不變量 1**：第 i 層軌道必須在「全部 tag ≥ i 的強生成元」下閉包——
  深層生成元（固定 b₀..b_{j-1}, j>i）仍會移動第 i 層軌道內的點。
  漏掉它們會低估軌道（實測 ⟨(01234),(01)⟩ = S₅ 若漏掉會誤得階 8）。
  本實現以全局生成元表 + 層級標籤 + 加入新生成元時重閉包所有 ≤ tag 層保證正確。
- **關鍵不變量 2（第二階段修正）**：`elements` 的橫截累積次序必須是 `acc.compose(u)`
  （g = u₀∘u₁∘…）；反向累積（`u.compose(acc)`）會產生**重複且漏元素**的元素表，
  計數仍等於 |G|，故只看階的測試無法發現。現由 `elements_cert`（計數 + 相異 +
  SGS 篩選成員 + 乘法封閉）與白盒/黑盒回歸測試共同把關。

### 2.4 FinAction — 群作用

- 點作用 / 序對作用（X×X）/ 邊作用（圖的邊集）
- `lift`：把底置換提升到導出作用（推導類型 `ActionDerive` 記錄提升規則）
- 軌道、穩定子、可遷性、基本域
- **Burnside 軌道計數**：#軌道 = (1/|G|)·Σ_g |Fix(g)|（列舉版，用於驗證恆等式；
  BFS 軌道計數為線性版）

### 2.5 OrbitFold — 軌道折疊

- `fold_graph`：商圖 = 軌道代表 + 邊重數矩陣 + 軌道大小（Σ重數 = m、Σ軌道大小 = n，已測試）
- `fold_edges`：邊軌道分割
- `fundamental_domain` / `fold_candidates`：**搜索空間折疊**——分支候選在群作用下
  每軌道只取一個代表（壓縮因子 = Π|分支軌道|），這正是引擎軌道剪枝的數學內容
- 可遷圖 ⇒ 單點商（壓縮率 1/n）

### 2.6 Monad — 單子

MoonBit 無高階型構造子，故以具體單子 + 定律測試實現：

- `ListM`（非確定性/冪集單子）：pure/bind/map/mplus/filter/guard/fold；`search_nd` 回溯搜索
- `StateM`（狀態單子）：get/put/modify/eval/exec——`analyze_m` 以之線程化搜索統計
- Option 單子（`opt_pure`/`opt_bind`）、Kleisli 組合（`kleisli_list`/`kleisli_state`）
- 三大單子律（左單位/右單位/結合）全部測試通過
- **實際應用**：`isomorphisms_m(g1,g2)` = 基同構 ∘ Aut(g1) 經 ListM 列舉全部同構

### 2.7 Cat — 範疇化（第一層：單對象結構）

- **FinSet/FinMap**：有限集範疇（id/複合/單射/滿射/同構/逆），範疇律測試
- **冪集單子 P**：單子 = 內函子範疇中的幺半群——η : Id → P、μ : P² → P，
  單位律/結合律/自然性（μ_Y ∘ P(P(f)) = P(f) ∘ μ_X）在 FinSet 層面**逐點驗證**
- **Aut 函子**：圖同構 φ ↦ 共軛 σ ↦ φσφ⁻¹；函子性 F(φ₂∘φ₁)=F(φ₂)∘F(φ₁) 測試
- **作用廣群 G-Set**：群作用 = 廣群（hom(x,y) = {g : g·x = y}；連通分量 = 軌道 =
  軌道折疊之骨架；迷向群 = 穩定子）；**廣群基數** |X//G| = Σ 1/|G_x| = |X|/|G|
  把「計數」提升為「範疇基數」，與 Burnside 形式 Σ 1/|Orb(x)| = #軌道互為對偶

### 2.8 Yoneda — 範疇化（第二層：多對象範疇、預層、Kan 擴張）

`fincat.mbt` + `yoneda.mbt` + `csp.mbt`（518 + 843 + 95 行；第三階段自單一 1444 行檔**依關注點切分**）
把「圖/群/作用」放進真正的有限範疇機器：

- **FinCat / FinDiagram / FinFunctor**：有限範疇（對象表 + 態射表 dom/cod + 恆等 + 複合表），
  `is_category` 窮舉驗證恆等律與結合律；建構子：`cat_discrete` / `cat_terminal` / `cat_arrow` /
  `cat_cospan` / `cat_span` / `cat_poset`（傳遞閉包）/ `cat_parallel` / **`cat_group`（BG）**
- **極限/餘極限**：`limit_set`（等化子）、`pullback_set`、`product_set`、`limit_card`（暴力對照）、
  `colimit_card`（union-find 之餘等化子/推出/餘積）、`arrow_diagram`（limit = A、colimit = B）
- **預層與 Yoneda 引理**：`presheaf_new`（反變：res[m] : F(cod) → F(dom)）、`is_presheaf`、
  `yoneda_nat`（Nat(h^a,F) 之元素 ↔ F(a) 之元素）、`yoneda_roundtrip`（雙向互逆）、
  `yoneda_count` ⇒ **|Nat(h^a,F)| = |F(a)|** 之機器驗證
- **comma 範疇與 Kan 擴張**：`comma_down` / `comma_up`、`lan` / `ran` / `lan_map` / `ran_map`
- **歸納 / 上歸納（Frobenius 互反之兩半）**：沿 K : 1 → BG，
  `Lan_K F = G × X`（**歸納**，|·| = |G|·|X|，自由作用）與 `Ran_K F = X^G`
  （**上歸納**，|·| = |X|^|G|，(Ran)^G = X）；態射層面 `induced_lift` / `coinduced_lift`
  與 `regular_perm`（左正則表示）逐一相符
- **CSP = 極限**：`csp_limit(dom, cons, cap)` 把約束滿足寫成
  lim [ Π_v D_v →(proj) D_i×D_j ←(incl) R_k ]，與單子式 `search_nd` 得**同一解集**（4/5-皇后）
- **注意**：`FinDiagram.img` 以**態射**為索引（含全部恆等態射），故建構圖時必須提供
  `id_map(n)` 之恆等像；`pushout_card` 需要 **span**（共同定義域），cospan 會 abort。

### 2.9 GSet — G-集、Burnside 環、table of marks、Cayley 圖、PermSet

`gset.mbt` + `marks.mbt` + `permset.mbt`（477 + 605 + 91 行；第三階段自單一 1111 行檔切分）
是「群作用 × 規範形式 × 範疇化」三層的交會點：

- **分類定理（Burnside/Mackey）**：有限 G-集之同構類 ↔ 傳遞 G-集 G/H 之非負整係數組合
  ↔ **標記向量** m_H(X) = |X^H|（H 跑遍子群共軛類）
- **table of marks**：M[i][j] = m_{H_i}(G/H_j)；在「按 |H| 升冪排序」下為**三角矩阵且對角為正**
  （H 固定 gK ⇔ g⁻¹Hg ⊆ K ⇒ |H| ≤ |K|，且 M_{H,H} = [G:N_G(H)] ≥ 1）⇒ 可逆 ⇒ 標記映射單射
  ⇒ **標記向量是 G-集之完全不變量（= 規範形式）**
  - 兩種獨立算法：`table_of_marks`（陪集 G-集作用）與 `table_of_marks_formula`
    （#{ gK : g⁻¹Hg ⊆ K } 公式），`marks_cert` 做**雙式記帳**交叉驗證
- **G-集建構子**：`gset_points` / `gset_pairs` / `gset_edges` / `gset_induced`（G×X）/
  `gset_coinduced`（X^G）/ `coset_gset`（G/H）；`gset_orbits` / `gset_burnside`（#軌道 = Burnside 平均）/
  `gset_global_fixed`（X^G）/ `gset_isomorphic`（標記向量相等）/ `gset_canon_key`（可雜湊鍵）
- **`subgroup_classes`**：子群共軛類（≤2 生成之候選 + 共軛併類）；見 §3 之衍生加速
- **Cayley 圖定理**：左正則表示 λ_h(g) = h∘g 給出單射群同態 **G ↪ Aut(Cay(G,S))**
  ⇒ |Aut(Cay(G,S))| ≥ |G|（O(1) 下界，免搜索）；`cayley_graph` / `regular_perm` / `cayley_cert`
  把「抽象群」編碼為「數學結構圖」，使本庫之圖演算法可直接處理群本身
- **自由 G-集單子**：伴隨 Lan_K ⊣ res_K 之複合 T = res∘Lan 正是 T(X) = G × X，
  η_X(x) = (e,x)、μ_X(g,(h,x)) = (g∘h,x)；`gset_monad_laws`（三律）+ `gset_monad_naturality`
- **Frobenius 互反（Set 版）**：`frobenius_reciprocity` 以暴力列舉驗證
  |Hom_G(G×X, Y)| = |Hom_Set(X, res Y)| = |Y|^|X|
- **規範折疊 `fold_canonical`**：先規範化再折疊 ⇒ 折疊結果（含軌道順序、重數矩陣）
  只依賴**同構類**（一般 `fold_graph` 之軌道順序依賴原標號）
- **PermSet 規範鍵**：`permset_encoding(ps, λ)`（λ⁻¹∘p∘λ 之像串接）、`permset_canon`
  （λ 上最小化）、`permset_isomorphic`（鍵相等）、`permset_cert`
  （重標號不變 + 冪等 + 共軛 ⇒ 同構）

### 2.10 Decomp / Dual / Line — 由定理衍生的三條独立通道

| 模組 | 定理 | 衍生演算法 |
|---|---|---|
| `decomp.mbt` | 不交併之 Aut = 直積 ⋊ 置換：**\|Aut(G)\| = Π_類 (Π\|Aut(Cᵢ)\|^{mᵢ} · mᵢ!)** | `decompose`：分量 → 同構類分組 → 積公式（免全搜索）；`automorphism_group` 由「塊內 Aut × 塊間置換」**派生生成元**；`isomorphic_decomposed` / `isomorphism_decomposed`（顯式同構）；`block_encoding_of`（第三個完全不變量） |
| `dual.mbt` | **Aut(G) = Aut(Ḡ)**；canon_enc(Ḡ) = mask ⊕ canon_enc(G) | `canonical_dual` / `canon_encoding_dual`（第二個完全不變量）；`dual_pair`：**一次搜索得 G 與 Ḡ 兩份規範形式**（密度不對稱時只搜稀疏側）；`dual_cross_check`（雙式記帳：兩側獨立搜索須得同一群） |
| `line.mbt` | **Whitney**：連通、δ≥2、非 (K₃,K₁,₃) 例外對 ⇒ L(G)≅L(H) ⇔ G≅H；Φ:Aut(G)→Aut(L(G)) 為同態，**ker Φ ≅ S_{孤立點} × (ℤ/2)^{#K₂分量}** | `line_graph` / `aut_on_line`（Φ 之像）/ `line_kernel_order`（核階公式）⇒ **\|Aut(L(G))\| = \|Aut(G)\|/\|ker Φ\|（免搜索 L(G)）**；`isomorphic_line` / `isomorphism_via_line`（星團回提）；`whitney_exception` / `whitney_applies`（例外守衛）；`line_embed_cert` |

三者與引擎**互相交叉驗證**（`prove_pair` 用四條獨立通道判同一對圖），且各自給出
第三/第二個完全不變量（分量塊編碼、對偶編碼）——n ≤ 5 窮舉實測三者之同構類分割
**皆為 34 類且逐對一致**。

> 已否證的猜想（保留以免重蹈）：(1) 塊編碼之串接**不等於**引擎之規範編碼（反例 2K₂⊔K₁）；
> (2) `xor_mask(canon_encoding(Ḡ))` **不是** G 之最大編碼（引擎編碼等變且完全，但非全局字典序最小）；
> (3) ker Φ **不是**只有孤立點置換（還有每個 K₂ 分量之 ℤ/2）。

### 2.11 Theorem — 機器可驗證之定理證書

`theorem.mbt` + `theorem_all.mbt`（644 + 545 行）把上述所有內容收斂成**可執行的定理**：

```moonbit nocheck
pub(all) struct Cert { name : String; holds : Bool; detail : String }
prove_graph(g, sigma, cap) -> Array[Cert]   // 22 條：單圖（不變性/完全性/群/作用/折疊/線圖/對偶/分解/標記/元素表）
prove_pair(g1, g2)          -> Array[Cert]   // 9 條：雙圖（四條獨立同構通道互證 + 顯式同構逐邊驗證）
prove_all(cap)              -> Array[Cert]   // 20 條：跨模組（範疇律/極限/Yoneda/Kan/單子/CSP/Cayley/標記/Whitney/文獻值）
all_hold / failed_certs / cert_report
```

每條證書都由**計算**判定（窮舉、雙算法對照、暴力法對照、或與文獻值比對），
不依赖外部證明助理；測試要求三組電池**全綠**。

### 2.12 KeyLut — 零配置開放定址鍵表

群演算法的內層迴圈需要「群元素 → 元素索引」之反查（陪集 G-集、子群共軛類、標記矩陣、
歸納/上歸納、Cayley 圖）。`Map[Int64,Int32]`（HAMT）每次查找需裝箱與指標追逐；
`lut.mbt` 以**兩個原始型別陣列 + 線性探測**（Fibonacci hashing，0L 為空槽哨兵）提供
同一介面且**零配置**，配合 `compose_key64`（由像陣列直接算出合成結果之鍵，免建 Perm）
構成熱路徑之常數因子優化。

---

## 3. 性能工程（降低計算複雜度、提升載入/運算速度）

### 3.1 第一階段：熱路徑零分配 + 多項式化群運算

| 技術 | 位置 | 效果 |
|---|---|---|
| 顏色按深度分槽、前綴共享緩衝、lab/pos_of 就地換位回溯 | search | 每節點 0 次堆分配 |
| 可加雜湊簽名（免清零、免向量比較；P1/P2/P3 確定性混雜表） | refine | 每輪 O(m) 而非 O(n·placed) |
| 多源 BFS 距離種子 | refine | 稀疏圖精煉輪數 O(n) → O(1)（Q5 節點數減半） |
| 歸併排序（小塊退化 insertion sort）取代泛型 sort_by | refine | 避開閉包/分配開銷 |
| 固定點 BitVec 遮罩：穩定子檢查 O(placed) → O(n/64) | orbit_reps | 大群剪枝加速 |
| 增量 Schreier–Sims（sifting 過濾 + 配對計數器每對只推一次） | group | 生成元集多項式規模；20! 階瞬時 |
| 數值雜湊桶去重（取代字串鍵） | group | 免除 O(n) 字串拼接/分配 |
| 快速否證（度序列 + 精煉顏色）先於完整搜索 | canon | 非同構對 O(n+m) 拒絕 |
| 一次搜索多模組消費（analyze 管線） | report | 免除重複搜索 |

### 3.2 第二階段：由定理衍生的複雜度下降

| 衍生演算法 | 取代的直接做法 | 複雜度變化 | 沙箱實測 |
|---|---|---|---|
| `decompose().aut_order()`（積公式） | `aut_order(G)` 全搜索 | 指數搜索樹 → Σ 分量搜索 | 2×Petersen **7.79×**（含派生 SGS）／**16.5×**（只要階：0.35ms vs 5.71ms）；mix(36) **3.87×**；3×Petersen、6×C6、10×K3、8×Q3(n=64)、E20 **全搜索不可行**（實測 E16 已 >300s 未完成）而積公式 **0.061ms** 得 20! |
| `line_kernel_order` + `aut_order(G)` | `aut_order(line_graph(G))` | L(G) 有 m 頂點、2(n−2) 正則 ⇒ 搜索樹遠大於 G | L(K7) **25.3×**（0.264ms vs 6.68ms）；K5 3.13×；Q3 2.10×；Petersen 2.01×；K3,3 1.80×（L(G) 與 G 同規模時**無優勢**：C12 0.93×、2×C5 0.79×） |
| `dual_pair`（一次搜索兩份規範形式） | `canonical_form(G)` + `canonical_form(Ḡ)` | 2 次搜索 → 1 次 | n=20..32 隨機圖 **1.84–2.48×** |
| `gset_isomorphic`（標記向量） | 窮舉 G-等變雙射 | \|X\|! → O(#類·\|G\|) | 12 點 G-集 **0.0035ms**（暴力需 12! ≈ 4.8×10⁸ 個雙射）；64 點 G-集 **0.057ms**（暴力 64! ≈ 10⁸⁹） |
| `cayley_cert` 之 \|Aut(Cay)\| ≥ \|G\| | 搜索 Cay(G,S) | O(1) vs 全搜索 | Cay(D4) O(1) 免搜索 vs 全搜索 0.092ms |
| `fold_canonical`（生成元共軛搬運） | `canonical_form` + `automorphism_group` | 2 次搜索 → 1 次 | Q4 **1.62×**、Petersen 1.61×、star4 1.22×；K3,3 1.00×、P5 0.73×（**小圖無優勢，如實記錄**）；且輸出**重標號不變**（一般 `fold_graph` 不是） |
| `permset_canon`（可雜湊規範鍵） | 每對窮舉 λ ∈ S_n | 一次 O(n!) + 每對 O(1) vs 每對 O(n!) | 損益兩平點：n=6 約 **41.5** 項、n=7 約 **21.3** 項；之後規範鍵勝出（且可快取/去重/增量） |

### 3.3 第二階段：常數因子優化（同一演算法、同一複雜度）

| 技術 | 位置 | 沙箱實測（Aut(Petersen)，|G|=120） |
|---|---|---|
| 元素表封閉性以 64 位元鍵表判定，取代 \|G\|² 次 SGS 篩選 | `elements_cert` | 4.985ms → **0.520ms（9.6×）** |
| 共軛併類改为「共軛類 = 共軛作用之**軌道**」⇒ 只用**生成元**做 BFS 閉包（原本對全部 ng 個元素逐一共軛） | `subgroup_classes` | 4.329ms → **0.714ms（6.1×）** |
| 候選子群以乘法閉包 BFS 求得（免對每個生成對建 Schreier–Sims）；SGS 只為倖存代表建構 | `subgroup_classes` | 300 次 SGS → 7 次 |
| 雜湊桶（BitVec::hash + equal）取代字串鍵去重 | `subgroup_classes` | 免 O(\|H\|²) 字串拼接 |
| `KeyLut` 開放定址表 + `compose_key64` 免配置合成 | `coset_gset` / `coset_reps` / `table_of_marks_formula` / `regular_perm` / `cayley_graph` / `gset_monad_*` | `coset_gset` 0.601ms → **0.204ms（2.9×）** |
| 標記矩陣之**三角性剪枝**（\|H\| > \|K\| ⇒ m = 0，免算陪集作用） | `table_of_marks` / `_formula` | 3.429ms → **1.331ms（2.6×）** |
| 陪集代表 hoist 出雙重迴圈（原本重算 ns 次） | `table_of_marks_formula` | ns× 減少 |
| `marks_cert` 總計（S4／Aut(Petersen)） | | 1.670ms → **0.378ms（4.4×）**／8.302ms → **2.200ms（3.8×）** |
| `prove_graph(Petersen)`／`prove_all` 電池總計 | | 19.3ms → **9.4ms（2.1×）**／10.5ms → **4.4ms（2.4×）** |

### 3.4 引擎基線（native release，本機實測；**單位：毫秒**）

| 圖 | n | \|Aut\| | 節點 | 搜索 | SGS |
|---|---|---|---|---|---|
| Petersen | 10 | 120 | 385 | 0.183ms | 0.042ms |
| K10 | 10 | 3 628 800 | 1056 | 0.915ms | 0.736ms |
| Q4 | 16 | 384 | 1674 | 0.988ms | 0.168ms |
| Q5 | 32 | 3840 | 8244 | 14.15ms | 0.738ms |
| C60 | 60 | 120 | 5666 | 14.32ms | 0.189ms |
| P40 | 40 | 2 | 81 | 0.137ms | 0.004ms |

「所有頂點等價」之圖（E_n／K_n，Aut = S_n）搜索樹成長最快，實測瓶頸如下
（同一機器、同一 build、`search_graph(g, true)` = 靜態軌道剪枝）：

| 圖 | 節點 | 搜索時間 |
|---|---|---|
| E12（\|Aut\| = 12! = 479 001 600） | 4541 | 7.26ms |
| E13 | 12 758 | 42.0ms |
| E14 | 53 533 | 639ms |
| E16 | — | **>300s 未完成**（user CPU 滿載，非 I/O；E18/E20 更不必說） |

⇒ 節點數每 +2 頂點約 ×2.8–4.3，但**每節點成本亦随 n 上升**，故時間成長遠陡於節點數
（E12→E14 節點 ×11.8、時間 ×88）。E16 已不可行 ⇒ **E20/K20 之全搜索不可行**；
這正是 §3.2 分量分解（E20 → 20! = 2 432 902 008 176 640 000 於 **0.061ms**）
與補圖對偶（一次搜索得兩份規範形式）的用武之地。
（另：無剪枝模式 `search_graph(g, false)` 在 E13 即因記憶體爆掉被 OOM kill ⇒ 剪枝紀律非選項而是必需。）

> **單位更正（第三階段健檢發現之真 bug）**：core 的 `monotonic_clock_end` 回傳的是
> **微秒**（見 `core/bench/monotonic_clock_native.mbt`：「Returns elapsed time in
> microseconds」），而此前 `cmd/symdemo`、`cmd/symbench` 直接把它當毫秒印出
> ⇒ 所有**絕對時間放大了 1000 倍**（例如舊文件寫「Petersen 搜索 189ms」，實為 0.189ms）。
> 已在 `timed` / `versus` / `bench_one` / `btime` 四個計時點統一 `/ 1000.0` 修正，
> 並以「直接執行已建置二進位」之 wall-clock 交叉驗證：`bench.exe` 全程 **0.134s**、
> `main.exe` 全程 **0.034s**，與程式內印出之計時總和（176ms／28.5ms）相符。
> **加速倍數（比率）不受影響**——分子分母同時被放大 1000 倍；
> 但本文件與 `docs/*_output.txt` 之絕對毫秒數已全面重測更正。

---

## 4. 正確性驗證（**67 個測試全過** + 定理電池全綠）

**第一階段（39 個：`symlib_test.mbt` 28 + `symlib_wbtest.mbt` 11）**

- **窮舉 × 暴力法**：5 頂點全部 1024 個圖——引擎 |Aut| == 暴力計數；
  引擎指紋分類 == 暴力全局最小編碼分類（**雙射**，即同構類完全一致）
- **隨機抽樣 × 暴力法**：n=6（25 個）、n=7（12 個）隨機圖 |Aut| 對照
- **已知值**：K_n=n!、C_n=2n、P_n=2、Q_k=2^k·k!、Petersen=120、K_{a,b}、star、empty、
  S_n/C_n/D_n 群階、軌道-穩定子定理 |G_x|·|Orb(x)|=|G|
- **重標號不變性**、**困難負例**（Petersen ≇ C10、C6 ≇ 2×C3、C8 ≇ 2×C4）、
  **守恆律**（折疊邊重數和 = m、軌道大小和 = n）、**恆等式**（Burnside == BFS 軌道計數）、
  **定律**（ListM/StateM/Option 單子律、FinMap 範疇律、冪集單子律 + 自然性、Aut 函子性）、
  **剪枝紀律**（模式 0/1/2 指紋一致、bad_witness == 0）、**規範形式冪等**

**第二階段（20 個：`symlib_ext_test.mbt`）**

- `ext-exhaustive-n5-all-certs`：**1024 個 n=5 圖 × 10 條證書**
  （decomp 4 條、dual 3 條、line 3 條）全數成立
- `ext-exhaustive-n5-three-canonical-forms`：三個獨立規範形式（引擎／分量塊／補圖對偶）
  之同構類分割**皆為 34 類**，且 `isomorphic_decomposed` / `isomorphic_dual` /
  `isomorphic_line` 與引擎逐對一致（抽樣 1/29 之全部對）
- `ext-decomp-product-formula`：6 組不交併之 |Aut| 與手算積公式相符
  （2×Petersen=28800、3×Petersen=10368000、6×C6=2149908480、10×K3=219419659468800、
  E20=20!、mix=995328000），派生生成元逐個驗證為真自同構，溢位保護（60 孤立點 ⇒ -1L + Double 版）
- `ext-decomp-explicit-isomorphism`：顯式同構**雙向逐邊**驗證 + 硬否定
- `ext-dual-theorems`：Aut(G)=Aut(Ḡ)（同階互含）、dual_enc 位元互補、`dual_cross_check`、
  `dual_pair` 與獨立 `canonical_dual` 之編碼/標號/旗標一致
- `ext-line-whitney`：|ImΦ|·|kerΦ| = |Aut(G)|、Whitney 例外對（K₃ vs K₁,₃）、
  孤立點資訊損失（L(C5⊔K1)=L(C5)）、K₂ 分量之核、L(C6)=C6、L(K5)=10 點 30 邊 4-正則 |Aut|=120
- `ext-finite-categories` / `ext-limits-colimits`：9 個有限範疇之範疇律；
  等化子/餘等化子/拉回/推出/積/餘積與**暴力計數**一致；箭頭圖 limit=A、colimit=B
- `ext-yoneda-lemma`：2 個預層 × 3 個對象（+ 4 對象鏈）之 |Nat(h^a,F)| = |F(a)| 且雙向互逆；
  非預層（違反反變函子性）被偵測
- `ext-kan-extensions`：Lan_Id = F = Ran_Id；Lan_{1→BG} = G×X（態射層面 == `induced_lift`、
  2 個自由軌道）；Ran_{1→BG} = X^G（== `coinduced_lift`、(Ran)^G = X）
- `ext-marks-and-burnside`：S₃ 之 table of marks 逐值比對教科書值
  `[6,3,2,1][0,1,0,1][0,0,2,1][0,0,0,1]`；S₄ 有 11 個子群共軛類；5 個群之 `marks_cert`；
  5 個 G-集之 #軌道 == Burnside 平均；三角形之 V ≅ E 而 V ≇ V×V（標記判別）
- `ext-cayley-graphs`：**Cay(C4) ≅ C4、Cay(D4) ≅ Q3**、Cay(S3) = 三棱柱（6 點 9 邊 3-正則，≇ K3,3）；
  4 個群之 `cayley_cert`（λ 為自同構 + 單射 + |Aut(Cay)| ≥ |G|）
- `ext-permset-canonical-form`：`permset_canon` 之同構判定與**暴力共軛搜尋**（窮舉 λ ∈ S₅）
  在 5×5 = 25 個序對上**逐一相符**
- `ext-free-gset-monad`：η/μ 三律 + 自然性 + Frobenius 互反（3 組）
- `ext-csp-limit-vs-monad`：4/5-皇后之 `csp_limit`（極限）與 `search_nd`（單子）**解集相同**
- `ext-fold-canonical`：9 個圖族之 `fold_canonical_cert`（重標號不變）+ 守恆律
- `ext-sgs-elements-regression` / `wbtest-keylut`：8 個群之元素表（相異/完整/封閉）；
  `elem_lut_fast` == `elem_lut`；`compose_key64(a,b)` == `perm_key64(a.compose(b))`（120² 對）
- `ext-labeling-perm-one-search`：σ∘p∘σ⁻¹ 為規範圖之自同構、群階與軌道結構不變（免二次搜索之依據）
- `ext-theorem-battery`：`prove_graph`（9 圖族 × 22 條）+ `prove_pair`（6 對 × 9 條）+
  `prove_all`（20 條）**全綠**

**第三階段（8 個：`symlib_api_test.mbt` — API 健檢之回歸網）**

清死碼之後，「每個公開入口都被使用**且**被驗證」由這 8 個測試守住：

- `api-shared-utils`：`Graph::disjoint_union`（n/m/分量數/積公式/空陣列/單元素邊界）、
  `Graph::random` / `Perm::random` / `random_ints`（**同 seed ⇒ 同結果**、異 seed ⇒ 異結果、
  值域合法、置換為雙射）、`ints_to_string` / `int_rows_to_string`
- `api-action-fold-consistency`：`FinAction::orbit_sizes` 之和 == \|X\| 且與 `orbits()` 之長度一致；
  `FinAction::fold_ratio` == `FoldedGraph::ratio`；`PermGroup::orbit_rep` == 軌道最小元；
  `fundamental_domain(grp, all)` == 排序去重之代表元 == `folded.k`
- `api-monad-pipeline`：`canonical_labeling_m` / `analyze_m`（StateM 串接）與直接呼叫
  之標號、nodes、leaves 完全一致
- `api-decomp-wrappers`：`canonical_form_decomposed` / `aut_order_decomposed` /
  `block_encoding_of` 與 `Decomp` 之對應方法逐一相符
- `api-kan-finaction-view`：`coinduced_gset`（FinAction 視角）之 card/orbits/orbit_count/fixed_points
  與 `coinduced_card` / `gset_coinduced` / `gset_burnside` / `gset_global_fixed` 一致；
  `induced_gset` 之軌道皆自由（大小 = \|G\|）
- `api-csp-random-vs-monad`：以 `random_ints` 產生之隨機 CSP，`csp_limit`（極限）與
  `search_nd`（ListM 單子）之解集**集合相等**
- `api-search-single-funnel`：`search_graph_flags(g, 1, false)`（關閉前綴編碼剪枝）之
  nodes ≥ 預設值，但 `canon_enc` 相同 ⇒ 三個搜索入口確為**同一漏斗**
- `api-dual-group-and-keylut`：`automorphism_group_dual(g).order() == aut_order(g)` 且
  兩側生成元互相包含；`key_lut_pairs` 與 `key_lut` 結果一致、缺鍵時 `find` 回 -1

---

## 5. API 速查

```moonbit nocheck
// 結構圖
let g = Graph::petersen()            // 或 from_edges / path / cycle / complete /
                                     // complete_bipartite / star / hypercube / empty
let h = g.relabel(σ); let gc = g.complement()
let u = Graph::disjoint_union([g, h])          // 不交併（第三階段自測試工具上收）
let (rg, s2) = Graph::random(12, 0.3, 1234)    // 決定性偽隨機圖（LCG；回傳新 seed）
let (rp, s3) = Perm::random(8, 99)             // 決定性偽隨機置換
let (xs, s4) = random_ints(6, 4, 7)            // 決定性偽隨機整數陣列（CSP 定義域用）
ints_to_string([1, 2, 3]); int_rows_to_string([[1, 2], [3]])
println(g)   // Perm/Graph/PermGroup/FinAction/BitVec/Decomp/DualCanon/FoldedGraph/
             // SymmetryReport/Cert 皆有 Show **與 Debug**（assert_eq 可印結構化差異）

// 規範形式與同構（四條獨立通道）
let lab = canonical_labeling(g); let σ = labeling_perm(lab)
let d = canon_digest(g)              // 引擎指紋
let dd = dual_digest(g)              // 對偶指紋（第二個完全不變量）
isomorphic(g, h); isomorphism(g, h)                      // 引擎
isomorphic_decomposed(g, h); isomorphism_decomposed(g, h) // 分量分解
isomorphic_dual(g, h); isomorphism_dual(g, h)             // 補圖對偶
isomorphic_line(g, h); isomorphism_via_line(g, h)         // 線圖 + Whitney

// 自同構群
let aut = automorphism_group(g); let ord = aut_order(g)
let orbs = vertex_orbits(g); let (ereps, esizes) = edge_orbits(g)

// 衍生：免全搜索
let dec = decompose(g)               // 分量分解
dec.aut_order()                      // Π(Π|Aut(Cᵢ)|^{mᵢ}·mᵢ!)
dec.automorphism_group()             // 派生生成元之群
dec.summary()
let (dg, dc) = dual_pair(g)          // 一次搜索 ⇒ G 與 Ḡ 之規範形式
let lg = line_graph(g)
aut_on_line(g)                       // Φ : Aut(G) → Aut(L(G)) 之像
line_kernel_order(g)                 // |ker Φ| = (孤立點)!·2^{#K₂}
aut_order(g) / line_kernel_order(g)  // = |Aut(L(G))|（Whitney 適用時）

// G-集 / Burnside 環 / 標記
let subs = subgroup_classes(aut, 400)
let marks = table_of_marks(aut, subs, 400)        // 或 table_of_marks_formula
let (ok1, ok2, ok3, ns, ord2) = marks_cert(aut, 400)
let x = gset_induced(aut, 2, 400)    // G×X（Lan）
let y = gset_coinduced(aut, 2, 400)  // X^G（Ran）
mark_vector(x, subs); gset_burnside(x); gset_isomorphic(x, y, subs)
let cay = cayley_graph(aut, 400)     // Cay(G,S)；|Aut(cay)| ≥ |G|
let f = fold_canonical(g)            // 重標號不變之軌道折疊
let ps = permset(n, gens); permset_canon(ps, 5000); permset_isomorphic(ps, ps2, 5000)

// 範疇化
let c = cat_group(aut, 200)          // BG；或 cat_poset / cat_arrow / cat_span ...
is_category(c)
let dgr = arrow_diagram(f); limit_card(dgr, 100000); colimit_card(dgr)
equalizer_set(f1, f2); pullback_set(f1, f2); pushout_card(s1, s2)
let p = presheaf_new(c, sizes, res); is_presheaf(p)
yoneda_count(p, a, 4096); yoneda_roundtrip(p, a, 4096)
let lr = lan(k, f, 1000); let rr = ran(k, f, 100000)
csp_limit(domains, constraints, cap) // == search_nd（單子）

// 定理證書
let certs = prove_graph(g, σ, 200)   // 22 條
all_hold(certs); failed_certs(certs); println(cert_report(certs))
prove_pair(g1, g2)                   // 9 條（四通道互證）
prove_all(200)                       // 20 條（跨模組）
elements_cert(aut, 500)              // SGS 元素表回歸

// 管線
let rep = analyze(g); let prog = analyze_m(g)
let isos = isomorphisms_m(g, g, 100)
```

---

## 6. 模組一覽（第三階段健檢後之檔案切分）

**核心（第一階段）**

| 檔案 | 行 | 內容 |
|---|---|---|
| `bitvec.mbt` | 204 | 64-bit 字組位向量（集合運算 O(n/64)；hash/equal/Show/Debug） |
| `lut.mbt` | 127 | **KeyLut** 開放定址鍵表 + `perm_key64` / `compose_key64`（零配置反查，n ≤ 12） |
| `perm.mbt` | 272 | 置換：複合/逆/冪/輪分解/階/奇偶/共軛/`from_img`/`orbit_of` |
| `graph.mbt` | 350 | 簡單無向圖（鄰接表 + 位向量行）；圖族建構子；重標號/補圖/分量/**不交併** |
| `partition.mbt` | 318 | 有序分割；等價精煉；不變量顏色（WL 型）；快速否證簽名 |
| `search.mbt` | 774 | 個體化-精煉搜索引擎；**單一漏斗 `search_graph_flags`**（三種剪枝紀律）＋固定標籤的頂點 colored search |
| `canon.mbt` | 150 | 規範標號/形式/編碼/指紋；同構判定與顯式同構；`labeling_perm`；colored canonical key／同構判定 |
| `aut.mbt` | 86 | 圖自同構群 API：階/生成元/頂點邊軌道/可遷性/非對稱性；保色群與保色驗證 |
| `group.mbt` | 545 | 置換群：增量 Schreier–Sims、sifting、穩定子、元素列舉、共軛；`trans_at` 為唯一橫截不變量斷言點 |
| `action.mbt` | 329 | 群作用：點/序對/邊推導作用、lift、軌道（共用 `orbit_partition_of`）、Burnside |
| `fold.mbt` | 195 | 軌道折疊：商圖、邊軌道、基本域、搜索空間折疊 |
| `monad.mbt` | 226 | ListM/StateM/Option 單子、Kleisli 組合、單子式回溯搜索 |
| `cat.mbt` | 293 | FinSet/FinMap、冪集單子（η/μ/自然性）、Aut 函子、作用廣群與廣群基數 |
| `report.mbt` | 217 | 統一分析管線（一次搜索多模組消費）+ StateM/ListM 包裝 + 整數陣列格式化 |

**擴展（第二階段：規範形式 × 範疇化）**

| 檔案 | 行 | 內容 |
|---|---|---|
| `decomp.mbt` | 488 | **分量分解**：積公式、派生生成元、塊規範編碼、顯式同構、證書 |
| `dual.mbt` | 275 | **補圖對偶**：Aut(G)=Aut(Ḡ)、對偶規範形式/編碼/指紋、`dual_pair`、雙式記帳 |
| `line.mbt` | 257 | **線圖/Whitney**：L(G)、Φ 與核階公式、星團回提、例外守衛、證書 |
| `fincat.mbt` | 518 | **有限範疇** `FinCat`（含 BG）+ 9 個建構子、圖 `FinDiagram`、limit/colimit、等化子/拉回/推出/積/餘積 |
| `yoneda.mbt` | 843 | **預層與米田**：`Presheaf`、Nat(h^a,F)≅F(a)、comma 範疇、Lan/Ran、歸納/上歸納 G-集 |
| `csp.mbt` | 95 | **約束滿足 = 極限**：`csp_limit`、`queen_constraints` |
| `gset.mbt` | 477 | **G-集**：建構（點/序對/邊/歸納/上歸納）、軌道、Burnside、Cayley 圖、規範折疊、自由 G-集單子 |
| `marks.mbt` | 605 | **標記/Burnside 環**：子群共軛類、標記向量、table of marks（兩種獨立算法互證）、陪集 G-集、Frobenius 互反 |
| `permset.mbt` | 91 | **置換集**（非群）之規範鍵與同構判定 |
| `theorem.mbt` | 644 | **定理證書**：`Cert`（Show+Debug）、`prove_graph`（22 條）、`prove_pair`（9 條）、`elements_cert` |
| `theorem_all.mbt` | 545 | `prove_all`（20 條；已拆為 11 個編號區塊 + 9 個私有 `cert_*` 輔助） |

**第三階段新增／共用工具**

| 檔案 | 行 | 內容 |
|---|---|---|
| `random.mbt` | 68 | **決定性偽隨機**（LCG，a=1103515245、c=12345、mod 2³¹）：`Graph::random` / `Perm::random` / `random_ints`；同 seed ⇒ 同結果（測試可重現） |

**測試與執行檔**

| 檔案 | 行 | 內容 |
|---|---|---|
| `symlib_test.mbt` | 774 | 黑盒（第一階段 **28** 個 + 暴力法對照工具） |
| `symlib_wbtest.mbt` | 207 | 白盒（**11** 個：編碼佈局、精煉收斂、軌道樹、KeyLut 等內部不變量） |
| `symlib_ext_test.mbt` | 926 | 黑盒（第二階段 **20** 個：窮舉證書、三規範形式、定理電池） |
| `symlib_api_test.mbt` | 348 | 黑盒（第三階段 **8** 個：API 健檢回歸網） |
| `colored_search_wbtest.mbt` | 16 | 白盒（合併後 **2** 個：保色群階與 colored 同構錨點） |
| `cmd/symdemo` | 309 | 演示 §1–§9（含定理電池與衍生演算法計時對照）；全程 0.034s |
| `cmd/symbench` | 594 | 基準：12 個圖譜管線 + 7 組衍生演算法對照（A–G）；全程 0.134s |

庫本體（不含測試與 cmd）共 **8,992 行**；`moon check -d` 零錯誤零警告、`moon test symlib` **69/69**。

---

## 7. 已知限制

- 頂點數上限受 Int32 與 O(n²) 編碼影響：n ≤ 數百為宜；n > 64 時鄰接遮罩簽名自動多字組。
- 圖同構最壞情形為指數級（問題本性）；**K_n／E_n 之搜索節點數每 +2 頂點約 ×2.8–4.3**，
  且每節點成本随 n 上升 ⇒ 實測 E12 = 4541 節點／7.26ms、E13 = 12 758／42ms、
  E14 = 53 533／639ms、**E16 >300s 未完成** ⇒ n ≥ 16 之完全圖/空圖全搜索不可行；
  請改用 `decompose`（不交併）或 `dual_pair`（稀疏側）。
- 無剪枝模式（`search_graph(g, false)`，mode 0）在 E13 即因記憶體耗盡被 OOM kill
  ⇒ 軌道剪枝與前綴編碼剪枝是**必需**而非選項。
- `canon_encoding` 是**等變且完全**之不變量，但**不是全局字典序最小**編碼；
  需要「唯一字串鍵」時用 `canon_digest`／`dual_digest`／`block_encoding_of`（皆完全）。
- `elements` / `burnside_orbit_count` / `hom` / `frobenius_reciprocity` / `yoneda_*` /
  `lan` / `ran` / `csp_limit` 等列舉型 API 僅限小規模（皆有 cap 保護，超出即 abort）。
- **`perm_key64` 要求 n ≤ 12**（64 位元裝不下更長之像）⇒ G-集／標記／Cayley／PermSet
  諸 API 之**底集合**限 n ≤ 12；`permset_canon` 另受 n! 限制（n ≤ 8 為宜）。
- `subgroup_classes` 只枚舉 **≤2 生成**之子群：n ≤ 5 之對稱群完整（其全部子群皆 ≤2 生成），
  一般情形為**部分**不變量；ng > 24 時退化为只取循環子群。
- `aut_order` 回傳 Int64，|Aut| > 2⁶³−1 時溢位（`decompose` 於此回傳 -1L；
  另有 `aut_order_double`）。
- `isomorphic_line` 需要「連通、無孤立點、非 (K₃,K₁,₃) 例外對」之守衛（`whitney_applies`）。
- Set 層面**歸納 ≠ 上歸納**（|G|·|X| vs |X|^|G|，實測 12 vs 64）；兩者只在
  Frobenius 互反的意義下配對，不可互相取代。
- 動態剪枝（模式 2）之自同構生成元可能不完整（規範形式仍正確）——見 §2.1。
- 計時單位：`monotonic_clock_end` 回傳**微秒**；本庫之 `cmd/symdemo`、`cmd/symbench`
  已統一換算為毫秒（第三階段修正了此前 1000× 之單位錯誤，見 §3.4）。

---

## 8. 擴展定理清單（`prove_all` 20 條 + `prove_graph` 22 條 + `prove_pair` 9 條）

`prove_all(cap)` 之證書（實測全綠，**4.4ms**；20 條拆為 9 個私有 `cert_*` 輔助 + 11 個編號區塊）：

| # | 證書 | 機器驗證的內容 |
|---|---|---|
| 1 | `category-axioms` | 8 個建構（含 BG）之恆等律與結合律**窮舉**成立 |
| 2 | `limits-universal` | 等化子/拉回/箭頭圖（limit=A、colimit=B）/積/餘積 皆與**暴力計數**一致 |
| 3 | `yoneda-lemma` | Nat(h^a,F) ≅ F(a)：2 個預層 × 3 個對象，雙向映射互逆且計數相等 |
| 4 | `kan-identity` | Lan_Id F = F = Ran_Id F（comma 範疇有終端/始端對象） |
| 5 | `kan-induction` | Lan_{1→BG} F = G×X（\|·\|=12=6·2），態射映射 == 左正則作用，2 個自由軌道 |
| 6 | `kan-coinduction` | Ran_{1→BG} F = X^G（\|·\|=64=2⁶），(Ran)^G = F ⇒ 不動點 = 2 |
| 7 | `frobenius-reciprocity` | \|Hom_G(G×X,Y)\| = \|Hom(X,res Y)\|（C₃ 版 3=3、S₃ 版 3=3） |
| 8 | `monad-from-adjunction` | T = res∘Lan = G×− 之 η/μ 滿足左單位、右單位、結合律與自然性 |
| 9 | `powerset-monad` | 冪集單子 P 之單子律與自然性（n ≤ 3 窮舉） |
| 10 | `monad-list-state` | ListM/StateM/Kleisli 三律 |
| 11 | `csp-limit-vs-monad` | 4-皇后：**極限（範疇）= 2 = search_nd（ListM 單子）** |
| 12 | `cayley-embedding` | 左正則表示 λ:G↪Aut(Cay(G,S)) 單射；\|G\| ≤ \|Aut(Cay)\|（C4/D4/S3/C6） |
| 13 | `marks-triangular` | table of marks 三角 + 對角正 ⇒ 可逆 ⇒ **標記向量為完全不變量**；兩種獨立算法一致（\|G\|=6:4 類、6:4 類、24:11 類） |
| 14 | `gset-burnside-marks` | 5 個 G-集：#軌道 = Burnside 平均；V ≅ E（三角形）而 V ≇ V×V |
| 15 | `whitney-exception` | L(K₃)=L(K₁,₃)=K₃ 但 K₃≇K₁,₃；衍生判定正確排除例外 |
| 16 | `line-loses-isolated` | L(G⊔K₁)=L(G)：孤立點在線圖中消失（故 Whitney 需無孤立點） |
| 17 | `sgs-elements-exact` | S₄/D₈/C₇/Aut(Petersen) 之元素表：相異、完整、封閉 |
| 18 | `known-aut-orders` | 6 個圖譜之 \|Aut\| 與文獻值相符 |
| 19 | `decomp-vs-engine` | 2×Petersen：Π 公式 = 派生群階 = 120²·2 = 28800 |
| 20 | `search-nd-sound` | `search_nd` 之每個解皆滿足約束 |

`prove_graph(g, σ, cap)` 之 22 條涵蓋：規範形式之重標號不變性與冪等性、
同構判定之自反/對稱性、顯式同構之逐邊驗證、|Aut| 與 SGS 群階一致、
軌道-穩定子定理、Burnside == 軌道計數、廣群基數 = |X|/|G|、折疊守恆律、
Aut 函子性、分量分解 4 條證書、對偶 3 條證書、線圖 3 條證書、
`elements_cert`、`marks_cert`（n ≤ 12 且 |G| ≤ cap 時）。

`prove_pair(g1, g2)` 之 9 條：四條**獨立**同構通道（引擎／分解／對偶／線圖-Whitney）
必須給出同一答案，且同構時四條通道各自產出的顯式同構都要通過逐邊驗證。

---

## 9. 衍生演算法（由定理導出）

| 定理 | 衍生演算法 | 入口 |
|---|---|---|
| \|Aut(⊔Cᵢ)\| = Π(Π\|Aut(Cᵢ)\|^{mᵢ}·mᵢ!) | 分量分解 + 積公式 + 派生生成元 + 塊規範編碼 | `decompose` / `aut_order_decomposed` / `isomorphic_decomposed` |
| Aut(G) = Aut(Ḡ) | 一次搜索得兩份規範形式；對偶編碼/指紋；雙式記帳交叉驗證 | `dual_pair` / `canonical_dual` / `dual_cross_check` |
| Whitney + ker Φ ≅ S_{孤立點}×(ℤ/2)^{#K₂} | \|Aut(L(G))\| = \|Aut(G)\|/\|ker Φ\|（免搜索 L(G)）；星團回提同構 | `line_kernel_order` / `aut_on_line` / `isomorphism_via_line` |
| 標記矩陣可逆 ⇒ 標記向量為完全不變量 | G-集同構判定 O(#類·\|G\|)（免 \|X\|! 枚舉）；可雜湊規範鍵 | `mark_vector` / `gset_isomorphic` / `gset_canon_key` |
| Cayley 嵌入 G ↪ Aut(Cay(G,S)) | \|Aut(Cay)\| ≥ \|G\| 之 O(1) 下界；抽象群 → 圖（可餵回圖演算法） | `cayley_graph` / `cayley_cert` / `regular_perm` |
| 規範形式只依賴同構類 + σ∘p∘σ⁻¹ | 一次搜索 ⇒ 規範圖 + 規範標號下之 Aut（免二次搜索）；重標號不變之折疊 | `labeling_perm` / `fold_canonical` |
| Lan_K ⊣ res_K（K:1→BG） | 歸納 G-集 = G×X、上歸納 = X^G 之**建構性**實現（態射層面可取用） | `induced_gset` / `coinduced_gset` / `induced_lift` / `coinduced_lift` |
| CSP = 極限 | 約束滿足之範疇式求解器（與單子式回溯互證） | `csp_limit` |
| 共軛類 = 共軛作用之軌道 | 子群共軛併類只用**生成元** BFS（免對全部 \|G\| 個元素共軛） | `subgroup_classes`（內部） |
| H 固定 gK ⇒ \|H\| ≤ \|K\| | 標記矩陣之三角性剪枝 | `table_of_marks` / `_formula`（內部） |
| SGS 唯一分解 g = u₀∘u₁∘… | 元素表之 O(1) 鍵表驗證（免 \|G\|² 次篩選） | `elements_cert` |

---

## 10. 第三階段：全代碼健檢報告（除錯 / 去重 / 減債 / 清死碼）

### 10.1 方法（可重現，非目視）

**靜態掃描**（對全部 `*.mbt`，排除 `_build/`）：

| 檢查項 | 結果 |
|---|---|
| 公開函數定義 | 309 個，**未被任何呼叫點使用者 0** |
| 私有函數定義 | **死碼 0** |
| 函數體重複（≥8 行函數 221 個，兩兩比對） | **完全相同 0、相似度 ≥0.85 者 0** |
| struct 欄位 | 未使用欄位 **0**（公開 struct/type 28 個） |
| 文件註解覆蓋 | 公開函數 **309/309 = 100%** |
| TODO / FIXME / XXX | **0** |
| deprecated API | **0** |

**動態驗證**：`moon fmt` → `moon info`（重生成 `pkg.generated.mbti`）→ `moon check -d`
（本庫把警告当錯誤）→ `moon test`（**67/67**）→ 直接執行 native release 二進位量測 wall-clock。

### 10.2 除錯：找到的真 bug

| 問題 | 影響 | 修法 |
|---|---|---|
| **計時單位錯誤**：core 的 `monotonic_clock_end` 回傳**微秒**（其文件明寫 “Returns elapsed time in microseconds”），但 `cmd/symdemo` 之 `timed`/`versus` 與 `cmd/symbench` 之 `bench_one`/`btime` 直接当毫秒印出 | 全庫文件與輸出之**絕對時間放大 1000×**（舊文件「Petersen 搜索 189ms」實為 **0.189ms**；「prove_all 4.4s」實為 **4.4ms**）。**加速倍數不受影響**（分子分母同時放大） | 四個計時點統一 `/ 1000.0`（並在 `btime` 文件註解中寫明單位，集中於一點）；以「直接執行已建置二進位」交叉驗證：`bench.exe` wall **0.134s** vs 程式印出計時總和 **176ms**、`main.exe` wall **0.034s** vs **28.5ms** ⇒ 一致；README §3.2/§3.3/§3.4/§7/§8 與 `docs/demo_output.txt`、`docs/bench_output.txt` 全面重測更正 |
| **不可行的基線宣稱**：舊文件寫「E20 全搜索 >420s 未完成（K12 已 8.5s／4541 節點）」 | 8.5s 是上述單位錯誤之产物（實為 7.26ms）；「K12」實為 **E12**；且原宣稱未附可重現證據 | 重測整條尺度梯（同一機器、同一 build）：**E12** 4541 節點／7.26ms、**E13** 12 758／42.0ms、**E14** 53 533／639ms、**E16 >300s 未完成**（user CPU 滿載，非 I/O）；另測得**無剪枝模式在 E13 即被 OOM kill**（exit 137）⇒「n ≥ 16 之 E_n/K_n 全搜索不可行」之結論成立，但證據換成實測數據（見 §3.4） |
| **散落的 `.unwrap()`**：`group.mbt` 有 7 處 `tr[p].unwrap()` 全部依賴同一個不變量（p 在第 i 層軌道內 ⇒ `trans[i][p]` 必為 Some） | 不變量散落 7 處；違規時是裸崩潰、無診斷訊息 | 收斂為單一具名斷言點 `trans_at(tr, p)`（附 abort 訊息）；庫本體 `.unwrap()` 由 18 處降至 **11 處**，剩餘全為「非空堆疊/工作清單 pop」或「建構期必存在之索引表項」之慣用式 |
| 掃描誤報：`perm.mbt` 疑似使用 deprecated 自由函數 `pow` | — | 確認為 `Perm::pow` 之**定義**（方法），非 deprecated API ⇒ 不需修改（如實記錄，避免誤改） |

### 10.3 清死碼：移除 9 個定義

`BitVec::clear`、`Graph::neighbor_bits`、`Graph::to_matrix_string`、`PermGroup::base_points`、
`aut_summary`、`aut_order_dual`、`edge_list_indexed`、`elem_lut`（已被 `elem_lut_fast` 完全取代）、
`labeling_to_perm`（已被 `labeling_perm` 取代），以及 `search.mbt` 內一個寫入後永不讀取的 `remaining`。
判準：全庫（含測試、demo、bench）**零呼叫點**；留著只會讓讀者誤判 API 表面。

同時把三個搜索入口收斂成**單一漏斗**：`search_graph_flags(g, mode, bb)` 是唯一實作，
`search_graph` / `search_graph_mode` 僅委派（原本三份近似邏輯 ⇒ 「修一個 bug 要改三處」之負債）。
`symlib_api_test.mbt` 之 `api-search-single-funnel` 守住這條等價性。

### 10.4 去重

| 原本 | 現況 |
|---|---|
| **5 份**各自的偽隨機產生器（測試與 cmd 之本地 `brnd_*` / `random_perm` / `random_graph`，≈60 行） | `random.mbt`：`lcg_step` + `Graph::random` + `Perm::random` + `random_ints`（決定性 LCG、回傳新 seed、庫與測試共用 ⇒ 測試可重現） |
| **3 份**不交併實作 | `Graph::disjoint_union` |
| **2 份**整數陣列 → 字串 | `ints_to_string` / `int_rows_to_string`（`report.mbt`） |
| `FinAction::orbits` 與 `PermGroup::orbit_partition` 逐行相同（相似度 **0.98**） | 共用 `orbit_partition_of(size, orbit)` |
| `key_lut` 與 `key_lut_pairs` 只差一行（**0.886**） | 共用 `key_lut_of(keys, val_of)` |
| `canon_digest` 與 `digest_from` 之十六進位打包重複（**0.885**） | `canon_digest` 委派 `digest_from` |
| 測試/cmd 中 **11 個**本地複製工具 | 全數刪除，呼叫點改寫為庫 API |

### 10.5 減債（結構）

- **巨檔切分**（同一 package ⇒ 作用域與可見性完全不變，零行為風險）：
  `yoneda.mbt` 1444 行 → `fincat.mbt` 518 + `yoneda.mbt` 843 + `csp.mbt` 95；
  `gset.mbt` 1111 行 → `gset.mbt` 477 + `marks.mbt` 605 + `permset.mbt` 91；
  `theorem.mbt` 1109 行 → `theorem.mbt` 644 + `theorem_all.mbt` 545。
  **最大檔由 1444 行降至 843 行**，且每個檔有單一關注點與自己的模組文件。
- **巨函數拆分**：`subgroup_classes` 204 行（含 3 個巢狀閉包）→ 8 行組合式 +
  `sub_table` / `sub_closure` / `sub_candidates` / `sub_record` / `uf_find` /
  `merge_conjugate_classes`（+ 兩個私有 struct `SubTable` / `SubCands`）；
  `prove_all` 459 行 → **295 行**（20 條證書中 9 條抽成私有 `cert_*` 輔助）。
- **順帶修掉的重複計算**：`subgroup_classes` 原本把循環子群 ⟨a⟩ 之乘法閉包算了**兩次**
  （建快取一次、主迴圈再一次）；現在只算一次並重用 ⇒ 省下 ng 次 BFS 閉包
  （Aut(Petersen) 之 ng=120 ⇒ 候選枚舉工作量約減半）。
- **可測試性**：10 個型別補上 `pub impl Debug`（並附對應 `pub extend … with Debug::{to_repr}`，
  否則 `moon check -d` 會報 implicit_impl_as_method）：Perm、Graph、PermGroup、FinAction、BitVec、
  Decomp、DualCanon、FoldedGraph、SymmetryReport、Cert ⇒ `assert_eq` 失敗時能印結構化差異。
- **API 覆蓋網**：新增 `symlib_api_test.mbt`（8 個測試）把「清死碼後保留下來」的每個公開入口
  都接上驗證 ⇒ 未使用公開定義 0，且日後不會悄悄退化。

### 10.6 如實記錄：沒有改善或負改善的結果

- **Whitney 通道在 L(G) 與 G 同規模時沒有優勢**：C12 **0.93×**、2×C5 **0.79×**（定理路徑反而較慢）。
- **`fold_canonical` 在小圖上是負收益**：P5 **0.73×**、K3,3 **1.00×**（一次搜索 + 生成元共軛搬運之
  常數開銷大於省下的那次搜索）；只有 Q4 1.62×、Petersen 1.61× 這類高對稱圖划算。
- **`permset_canon` 只在項數夠多時划算**：n=6 需 **>41.5** 項、n=7 需 **>21.3** 項
  （因為它內部窮舉 n! 個重標號）；項數少時逐對暴力較快。
- **8×Q3（n=64）之派生 SGS 需 38.4ms**，是 A 節最貴的一項：積公式本身只要 0.59ms，
  成本全在「派生生成元 → Schreier–Sims」。
- **本階段的拆分/去重沒有量到整體加速**（庫本體不是瓶頸：整個 bench 0.134s、整個 demo 0.034s）。
  這一階段的收益是**可維護性、可驗證性與數字可信度**，不是速度。

### 10.7 剩餘負債（未處理，如實列出）

- `prove_all` 仍有 295 行：前 11 個編號區塊共享區域變數（`grp` / `elems` / `bg` / `kterm` / `ind` / `coind`…），
  再拆需要引入一個 proof-context struct；由於重算 `grp.elements(cap)` 會拖慢電池，本階段停在 9 個輔助。
- `prove_graph` 245 行、`prove_pair` 143 行：扁平的 `out.push(cert(…))` 序列，可讀性尚可，未拆。
- `cmd/symdemo` 之 `main` 230 行、`cmd/symbench` 之 `bench_permset` 147 行：演示/基準驅動程式，非庫本體。
- 庫本體 11 處 `.unwrap()`（慣用式，見 §10.2）與 96 處 `abort`（皆為文件化之前提條件守衛，
  含 cap 保護 ⇒ 超規模時明確報錯而非靜默給錯答案）。
- 引擎在 E16+ 之指數爆炸（§3.4）是問題本性 + 剪枝策略之極限，非本次健檢可解。
- `subgroup_classes` 在 ng > 24 時只列循環子群 ⇒ 標記向量退化為**部分**不變量（§7 已載明）。

