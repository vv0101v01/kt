# `semiring/sim/` — 效能的主機無關模擬器（F3 · Layer 2）

> **套件**：`vv0101v01/cubical-hermitian/semiring/sim` · **Layer 2** · 零依賴（除 `moonbitlang/core`）
> **被依賴**：`semiring-matrix`（`blocking.mbt` 的參數選擇）、`cmd-symbench`、`root`
> **2 檔 261 行** —— 讓「為什麼分塊乘法比較快」**在任何 target 上都能重現**。

---

## 1. 定位

目標平台是 `wasm`，**沒有 `perf`、沒有 cache counter、沒有 CPU 型號**。於是「這個常數選得好不好」只能靠：

1. **解析模型**（本套件）：用一個可參數化的集相聯 cache 模型去跑記憶體存取軌跡，得到 L1/L2 miss 與 DRAM 字數；
2. **牆鐘時間**（`clock.mbt`）：在真實機器上量，但只當作**佐證**。

兩者相乘，就是「模型預測 vs 實測」的對照 —— 不一致時，通常是模型漏了某個效應（TLB、預取、分支），而不是資料錯。

---

## 2. `cache.mbt`（219 行）

| 型別 | 內容 |
|---|---|
| `Cache` | `sets × ways × line_bytes`；`access(addr, write) -> Bool`（是否命中） |
| `MemHierarchy` | L1 + L2 + DRAM 三層；`MemHierarchy::typical()` 給一組典型參數 |
| `Tracer` | 矩陣乘法的存取軌跡發生器（register + probe） |

### 2.1 `Cache`
```moonbit
pub fn Cache::new(sets : Int32, ways : Int32, line_bytes : Int32) -> Cache
pub fn Cache::access(self, addr : Int32, write : Bool) -> Bool
pub fn Cache::accesses(self) -> Int64
pub fn Cache::reset(self) -> Unit
```
LRU 在每個 set 內以「最近使用」順序維護（`ways` 很小，線性掃描即可）。`accesses` 是總存取數 —— 除以 miss 數就得到 miss rate，於是 `mul_naive` vs `mul_ikj` vs `mul_blocked` 的差距**變成一個數字**。

### 2.2 `MemHierarchy`
```moonbit
pub fn MemHierarchy::typical() -> MemHierarchy
pub fn MemHierarchy::access(self, addr) -> Bool
pub fn MemHierarchy::dram_words(self) -> Int64
pub fn MemHierarchy::reset(self) -> Unit
```
`dram_words` 是「真正付了 DRAM 延遲」的字數 —— 這是分塊法唯一的目標函數。

### 2.3 `Tracer`
```moonbit
pub fn Tracer::new(elem_bytes : Int32)
pub fn Tracer::register(self, rows, cols) -> Int32          // 註冊一個矩陣，取得 id
pub fn Tracer::probe(self) -> (Int32,Int32,Int32,Bool) -> Unit   // 產生一個存取事件
pub fn Tracer::reset(self) / ::l1_misses() / ::l2_misses() / ::l1_accesses() / ::dram_words()
```
`Tracer` 把「矩陣乘法第 `(i,k,j)` 步會碰哪些位址」編碼成**事件流**，直接餵 `MemHierarchy`。因此 `matrix/blocking.mbt` 的 `choose_block_l1`／`choose_panel_l2` 有**模型依據**，而不是從別人的部落格抄來的常數。

---

## 3. `clock.mbt`（42 行）

```moonbit
pub struct Timer { ... }
pub fn Timer::start() -> Timer
pub fn Timer::elapsed_us(self) -> Double
pub fn[T] time_min(reps : Int32, f : () -> T) -> (T, Double)     // 取 reps 次的最小值
```
`time_min` 取**最小值**而非平均：平均值被排程抖動污染，最小值接近真實成本。回傳 `(結果, 微秒)` 一起，因此**不會出現「量到時間但結果被丟掉」**的情形。

---

## 4. 範例

```moonbit
// 1) 模型預測：分塊 vs 樸素
let tr = @sim.Tracer::new(elem_bytes=8)
let a = tr.register(512, 512)
let b = tr.register(512, 512)
let c = tr.register(512, 512)
naive_mul_trace(tr, a, b, c)                       // 產生 i-j-k 軌跡
let naive_dram = tr.dram_words()
tr.reset()

let mh = @sim.MemHierarchy::typical()
// 2) 實測（最小值）
let (_, us) = @sim.time_min(5, fn() { run_blocked_mul() })
println("model DRAM words = " + naive_dram.to_string() + ", real = " + us.to_string())
```

---

## 5. 依賴邊界與驗證

* **零依賴**：可被任何套件匯入。
* `cmd/symbench` 用 `Timer`/`time_min` 產生所有基準表的微秒數；`semiring/matrix/blocking.mbt` 用 `Tracer`/`MemHierarchy` 選參數。

```bash
moon test semiring/sim --target wasm-gc
```
