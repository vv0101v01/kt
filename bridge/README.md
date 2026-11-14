# `bridge/` — 跨表示構造與有限核驗 observer

**位置：pkgL8 / compL13。** 上游直接 import 由 `architecture.json` 核對；下層不可反向匯入。執行入口為 `cmd/showcase`，位於 pkgL9 / compL14。

目前 **39 條 active 配對橋、6 條 retired**。歷史 K5..K10 ID 沿用以便追溯；不為湊齊完全圖而保留無構造的邊。

## 1. 先讀這三份

- [聯邦及分層全景](../docs/FEDERATION_ARCHITECTURE.md)
- [全部橋的實際功能／產物／範圍／負控制](../docs/BRIDGE_CATALOG.md)
- [刪除及 API 遷移](../docs/BRIDGE_MIGRATION.md)

`catalog.json` 是 lifecycle 的機讀來源，`registry.mbt` 由 `tools/federation_docs.py` 生成。文檔不是驗證結果；執行 `showcase` 才會真正重算 active 比較。

## 2. 資料流

```text
上游原生物件／演算法
    ↓ 同一物件的跨表示轉換或明示範圍的獨立對帳
FederationPairBridge { id, lhs, rhs, bridge_theorem, holds, quantitative_witness }
    ↓ 精確 inventory validator（不只數 true）
39 個 active 結果的一次性快照
    ├─ 全部功能與量化見證列印
    ├─ K6 / K7 / K9 / K10 active 子圖
    ├─ ualg 9 條、第一波 6 條／第二波 7 條替換
    └─ 總成功條件

原生／atlas／輔助證書 → 另列 50 個 BridgeCertificate（不當作額外配對邊）
retired metadata       → 只列 ID 與理由，不執行、無失敗占位項
```

## 3. 核心入口

```moonbit
let edges = @bridge.verify_k10_ten_federation_bridges()
let audit = @bridge.validate_bridge_registry(edges)
// audit.expected_count = 39；僅當實際構造全過且覆蓋精確才 all_holds=true
let k7 = @bridge.bridge_edges_for_federations(edges, 7)
let k7_audit = @bridge.validate_bridge_registry(k7, federation_count=7)
```

`validate_bridge_registry` 支援 5..10 聯邦，拒絕：空表、缺邊、同長度重複替換、額外 ID、錯端點、退役 ID、未知 ID、空白見證、false 結果及超出世代的邊。端點反轉容許，因為這是無向比較圖。

**安全邊界**：公開 `FederationPairBridge` 可以由呼叫者建造。validator 證明的是「覆蓋及報告形狀符合契約」，不是重新證明任意傳入的 `Bool`。`*_precomputed` 僅用於可信的同一行程重用；不要把它當不可信外部證書驗證器。

## 4. 本輪保留及提升的真構造

### K6-15：P¹ 線叢上同調

`@condensed.cond_p1_cech_dimensions(twist, cutoff)` 建立有限 Laurent Čech 差分矩陣，在 F₇ 上求秩。

- 基底：`C⁰ = <1,…,t^c> ⊕ <t^n,…,t^(n-c)>`，`C¹ = <t^(n-c),…,t^c>`。
- `0≤c≤16`、`|n|≤c`；超範圍回傳 `None`。
- K6-15 將 `n=-4..3` 的 H⁰/H¹ 與 scheme 引擎逐項比較，且 cutoff 4/6 一致；另驗 Serre/RR 與 proper≠acyclic。
- **不是** affinoid annulus 的 H⁰，也不是 p-adic analytic stack 定理。

### K7-19：同一個 VR 複形進入 Topos

`metric_vr_to_topos_nerve(space, scale)` 檢查矩陣形狀、正定性、對稱性與三角式，然後逐一輸出邊、三角形、四面體。

- 範圍 1..8 點、非負尺度；三角式用 Int64 避免 Int32 溢位。
- 產出 3-skeleton，供 H⁰..H² 核驗；不外推 H³ 或更高維。
- C4 尺度 0/1/2：H⁰ `[4,1,1]`、H¹ `[0,1,0]`；刪去填面後錯誤 H¹=3，負控制確實拒絕。

### F2×F3×F6：圖的三路對帳

`graph_closure_snf_report(graph)` 用同一簡單無向圖，對照 component BFS、Boolean Kleene closure 和有憑證的整數 Laplacian SNF。

- 1..32 點；空域、self-loop 或不對稱輸入拒絕。
- A4 Cayley：12 點、1 component、144 可達對、Laplacian rank 11。
- 兩個不連通三角形：6 點、2 components、18 可達對、rank 4；否證「每個 Laplacian corank 都是 1」。
- 已移走與這個構造無關的 A5/B3、Yoneda、DFA、Nöbeling、Adams 健康合取；相關原生 API 仍在原套件。

## 5. 檔案按職責導航

| 檔案／組別 | 角色 |
|---|---|
| `catalog.json` / `registry.mbt` / `audit.mbt` | lifecycle、生成 metadata、精確驗收、15 條 checker laws、輔助證書 |
| `five_federation_plan.mbt` | FederationId、描述子及 K5 構造 |
| `double_v_chiasm.mbt` | 歷史檔名保留；實際只剩 K6 active 及原生健康摘要，不再含 X theorem |
| `discovery_k7_bridges.mbt` | K7 active、VR→nerve adapter、已決猜想整合摘要 |
| `meta_k9_unification.mbt` | K8 + K9 active 組裝；promotion code 已刪 |
| `ualg_federation_constructions.mbt` | 9 條 ualg 構造及 ten-federation report |
| `structural_bridge_replacements.mbt` / `nominal_bridge_elimination.mbt` | 兩波真構造替換；可重用已計算快照 |
| `permutation_bridge.mbt` / `graph_symmetry.mbt` / `tropical_bridge.mbt` / `face_semiring.mbt` / `free_category.mbt` | 可重用表示 adapter、群／圖／熱帶／半環功能 |
| `logic_theory_translation.mbt` / `geometry_logic_atlas.mbt` | 公式轉換及 18 項有正反對照的有限圖譜 |
| `accel_bridge.mbt` / `f2_f3_f6_triad_bridge.mbt` / `frontier_7pillars_unification.mbt` | 共用物件的多方對帳或明示案例整合；WGSL 僅靜態檢查 |
| `rotation_axis_bridge.mbt` / `intuitive_conjecture_lab.mbt` | 旋轉關係對齊（非彼此同構）、4 個反例後修正條目 |
| `certificates.mbt` / `grand_unification.mbt` | 報告彙整，不增加配對數；舊的 universal-sounding 名稱不是一般形式證明 |

## 6. 改動／驗證規則

新增或移除橋要同時更新 catalog、實作、負控制、`.mbti`、生成文檔及 `agent.v2.md`。保留有限比較有合理回歸收益，但要明說範圍；不允許用兩個獨立健康旗標冒稱結構傳輸。

```bash
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py
moon info --target wasm-gc && moon fmt
python3 tools/gen_laws.py
python3 tools/federation_docs.py
python3 tools/federation_docs.py --check
moon run cmd/showcase --target wasm-gc
```
