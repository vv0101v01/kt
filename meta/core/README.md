# meta/core — 三個機制共用的數學地板

**層級 0，零外部依賴。** 這裡只有四件結構 + 兩個工具，其他 meta 套件全部建在它們上面。

| 檔案 | 結構 | 公開入口 |
|---|---|---|
| `ordinal.mbt` | Cantor 範式序數（`ω^{e1}·c1 + …`，`< ε₀`） | `ord_add`（**非交換**，1+ω=ω）、`ord_mul_omega`、`ord_is_normal`、`ord_is_*`／極限判定在 `reflect/universe.mbt` |
| `algebra.mbt` | 精確有理數＋整數矩陣秩（消元） | `matrix_rank`、`rank_int`、`mat_mul` |
| `unify.mbt` | 一階合一（mgu，meet）／反合一（lgg，join） | `u_mgu`、`u_lgg`、UTerm 的 α-正規化與字串化 |
| `matroid.mbt` | 秩函數擬陣：貪心、對偶、交換公理 | `mat_from_rank`、`mat_greedy`、`mat_dual`、`mat_exchange_ok`、`mat_rank_axioms_ok`、`mat_graphic`、`mat_linear` |
| `ramsey.mbt` | Ramsey 數的真搜尋與可證上界 | `ramsey`、`ramsey_free_exists`、`erdos_szekeres`、`binom` |
| `complex.mbt` | 單純複形、邊界矩陣、Betti、Čech 神經 | `cx_betti`、`cx_is_chain_complex`、`nerve_of_cover`、`cover_glues`、`cover_obstruction` |

**不變式**：`ord_cmp` 是全序；`mat_dual ∘ mat_dual = id`；`cx_betti` 用 rank(B_{k−1}) − rank(B_k) 算，不靠數 Euler 特徵。
**邊界**：`ramsey(k,l)` 只對小值可行（`R(3,4)=9` 秒級），`R(4,4)` 請用 `erdos_szekeres` 的可證上界 —— 程式不假裝。
