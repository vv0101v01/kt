# `semiring/par/` — 後端無關的平行抽象（F3 · Layer 2）

> **套件**：`vv0101v01/cubical-hermitian/semiring/par` · **Layer 2** · 零依賴（除 `moonbitlang/core`）
> **被依賴**：`semiring-par-host`、`semiring-matrix`（`mul_rows_par` 的語義）、`root`
> **2 檔 159 行** —— 抽象的價值在於它**薄**。

---

## 1. 定位

目標環境是 `wasm`（`preferred_target = "wasm"`），**沒有執行緒**。因此本套件的設計原則是：

> 平行是**問題的形狀**（可分塊、可結合），不是**執行的手段**。
> 這裡只定義「怎麼切」「怎麼併」「怎麼在沒有硬體平行時仍然是同一個答案」。

`par_host/` 提供真正的（或退化的）後端，`matrix/mul_par.mbt` 與 `accel` 的 GPU 路徑都吃這個介面。

---

## 2. `backend.mbt`（49 行）— 後端介面

```moonbit
pub fn backend_name() -> String                    // "sequential" / "wasm-thread" / ...
pub fn par_for(chunks : Int32, f : (Int32) -> Unit) -> Unit
pub(all) struct ShardIO { ... }
pub fn shard_io_bench(_payload : String, files : Int32) -> ShardIO
```
* `par_for(chunks, f)`：對 `0..chunks` 呼叫 `f`。**契約是「每個 chunk 互不影響」** —— 這不是並行安全的註解，而是呼叫端必須自己保證的事（不共享可寫狀態）。
* `shard_io_bench`：分片 I/O 的量測骨架（`files` 個分片），不含真實檔案系統。

---

## 3. `par.mbt`（110 行）— 分塊與掃描

```moonbit
pub fn backend() -> String
pub fn chunk_size(total : Int32, chunks : Int32) -> Int32      // 切法（含餘數分配）
pub fn par_map_chunks(chunks, total, f)                         // 分塊 map
pub fn scan_depth(n : Int32) -> Int32                           // log2 上界
pub fn par_scan(values : Array[Int64]) -> Array[Int64]          // 平行前綴（兩趟）
pub fn scan_sequential(values : Array[Int64]) -> Array[Int64]   // 對照組
```
* **`par_scan` 的兩趟**：先分塊算局部掃描（`scan_depth` 趟上提），再把偏移加回去。這是 Blelloch/Hillis–Steele 家族的標準形狀。
* **不變量**：`par_scan(v) == scan_sequential(v)` **逐元素相同**。因為加法結合，兩者必然相等 —— 而 `chunk_size` 的餘數分配若寫錯，這個等式就會破，所以它是**唯一真正的測試**。
* `scan_depth(n)` 是 `⌈log₂ n⌉`，讓「趟數」與「分塊數」都可量測。

---

## 4. 範例

```moonbit
// 1) 分塊 map
@par.par_for(8, fn(c) { process_chunk(c) })

// 2) 平行前綴與序列前綴必須相同
let v = [1L, 2L, 3L, 4L, 5L]
assert_true(@par.par_scan(v) == @par.scan_sequential(v))

// 3) 切法
println(@par.chunk_size(1000, 7))     // 每塊大小（餘數分配到此）
println(@par.backend())                // 實際後端名稱
```

---

## 5. 依賴邊界與驗證

* **零依賴**：本套件不依賴任何其他 `semiring` 套件（連 `algebra` 都不用）—— 因此可被任何套件安全匯入，不會造成環。
* 下游：`par_host` 在 `wasm` 上退化為序列；`bridge` 用它的 `par_for` 做跨聯邦的批次驗證。

```bash
moon test semiring/par --target wasm-gc
```
