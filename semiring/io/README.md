# `semiring/io/` — 位元組級輸入與可重現合成資料（F3 · Layer 2）

> **套件**：`vv0101v01/cubical-hermitian/semiring/io` · **Layer 2** · 依賴 `semiring-algebra`、`semiring-graph`
> **被依賴**：`cmd-semiringreport`、`cmd-symbench`、`root`、`hostfs`（間接）
> **1 檔 153 行** —— 聯邦中最小的套件，但它決定**所有基準數字是否可比較**。

---

## 1. 定位

基準測試的頭號污染源是**解析器**：慢的 I/O 會讓 `O(n³)` 與 `O(n²)` 的差距失真。因此本套件有兩個硬規則：

1. **快路徑在 `Bytes` 上走**，逐位元組解析，不建中間 `String`、不用 `split`；
2. **合成資料用固定種子**，因此「同一個基準」在任何機器、任何 target 上都是同一份輸入。

---

## 2. API

```moonbit
pub(all) struct ParsedEdges { ... }               // 邊陣列（from/to/w）
pub fn parse_edges_fast(src : Bytes) -> ParsedEdges    // 位元組直解（正式路徑）
pub fn parse_edges_naive(src : String) -> ParsedEdges  // split + parse（對照組）
pub fn synth_edge_list(rng : @alg.Rng, n, m) -> String  // 人類可讀邊列表
pub fn synth_edge_bytes(rng : @alg.Rng, n, m) -> Bytes   // 位元組版（免轉換）
```

* 格式：每行 `u v w`（空白分隔、十進位），`#` 起頭為註解、空行忽略。
* **`parse_edges_fast` 與 `parse_edges_naive` 必須給出完全相同的結果**（`check_parse_equivalence()`）；這就是「最佳化沒有改變語義」的可執行證明。
* `synth_edge_bytes` 直接產生 `Bytes`，跳過 `String` 往返 —— 因此 `parse_edges_fast(synth_edge_bytes(rng, n, m))` 是零拷貝路徑。

---

## 3. 用法

```moonbit
// 1) 可重現的合成輸入（同一 seed ⇒ 同一份資料）
let rng = @alg.Rng::new(0x5EEDUL)
let bytes = @io.synth_edge_bytes(rng, n=1024, m=8192)
let parsed = @io.parse_edges_fast(bytes)        // 正式路徑

// 2) 與 naive 解析器對照（語義等價）
let same = @io.parse_edges_naive(
  @io.synth_edge_list(@alg.Rng::new(0x5EEDUL), 1024, 8192),
)
assert_true(same.count == parsed.count)
```

---

## 4. 依賴邊界與驗證

* 依賴 `semiring-algebra`（`Rng`）、`semiring-graph`（回傳型別供 `Graph::build` 直接吃）。
* **不依賴 `hostfs`**：`hostfs` 反而是這個套件的下游（用它的合成資料做耐久性壓力測試）。

```bash
moon test semiring/io --target wasm-gc
```
