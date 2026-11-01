# `semiring/ratelimit/` — 可算數的速率限制（GCRA + 階層式限流）（F3 · Layer 3）

> **套件**：`vv0101v01/cubical-hermitian/semiring/ratelimit` · **Layer 3** · 零依賴（除 `moonbitlang/core`）
> **被依賴**：`hostfs`、`root`（HTTP 邊緣與 WAL 提交路徑）
> **2 檔 489 行**

---

## 1. 定位

速率限制是**典型的「看起來簡單、實際上全是邊界條件」**的問題。本套件選 GCRA（Generic Cell Rate Algorithm）而非 token bucket，理由是**狀態小且單調**：

```text
  每個 key 只存一個 tat（theoretical arrival time）
  admit(now) :  tat ≤ now + tolerance  ⇒ 允許，tat ← max(tat, now) + T
                否則                     ⇒ 拒絕，回傳「還要等多久」
```
* **單一 `Int64` 狀態** ⇒ 可持久化、可比對、可重放（配 `hostfs` 的 WAL）。
* **`tolerance`** 就是突發容量（burst）：`tolerance = (burst − 1) · T`。

---

## 2. `gcra.mbt`（251 行）

```moonbit
pub(all) enum Decision { Admit; Throttled(wait_us : Int64); ... }
pub(all) struct Gcra { rate_per_sec; burst; ... }
pub fn Gcra::new(rate_per_sec : Double, burst : Int32) -> Gcra
pub fn Gcra::tolerance(self) -> Int64
pub fn Gcra::preview(self, tat, now) -> Decision      // 不改變狀態的查詢
pub fn Gcra::commit(self, tat, now) -> Int64          // 允許後寫回新的 tat
pub fn Gcra::backoff(self, strikes : Int32) -> Int64  // 指數退避（有上限）
```
* **`preview` / `commit` 分離**：查詢與更新分開 ⇒ 呼叫端可以先問、再（在交易裡）落地，因此限流決策能與 WAL 提交同一個原子單位。
* `backoff`：重複違規者指數退避（`strikes` 次），但**有上限** —— 避免把使用者永久封死。

### 2.1 `KeyTable`（冪次容量的開定址表）
```moonbit
pub(all) struct KeyState { ... }
pub(all) struct KeyTable { ... }
pub fn KeyTable::new(capacity_pow2 : Int32)
pub fn KeyTable::get_or_insert(key) -> ...
pub fn KeyTable::capacity(self) -> Int32
```
* 容量是 **2 的冪** ⇒ 取模變成位遮罩。
* 滿了之後的淘汰策略有明確計數（見下 `table_evictions`）⇒ 「限流器自己有沒有成為瓶頸」是量測出來的，不是猜的。

---

## 3. `limiter.mbt`（238 行）— 兩層

```moonbit
pub(all) struct Limiter { ... }         // 單層
pub(all) struct HierLimiter { ... }     // 階層：全域 → 租戶 → key
pub fn Limiter::new(...)
pub fn Limiter::with_gate(...)          // 加一道閘門（例如「全站熔斷」）
pub fn Limiter::admit(key : UInt64, now_us : Int64) -> Decision
pub fn HierLimiter::new(...) / ::admit(...)
```
診斷（三項，全部是 `Int64`/`Int32` 而非布林）：
```moonbit
Limiter::stats()        -> (admitted, throttled, total)
HierLimiter::stats()    -> 同上（合併）
Limiter::table_used()   -> Int32
Limiter::table_evictions() -> Int64
HierLimiter::table_used() / ::table_evictions()   // 兩張表各一
```
**階層的意義**：單層限流擋不住「一個租戶用掉全部配額」。`HierLimiter` 先問全域、再問租戶、再問 key，任一層拒絕即拒絕 —— 三層的順序在 `admit` 內固定，因此決策可重現。

---

## 4. 範例

```moonbit
let rl = @ratelimit.Limiter::new(rate_per_sec=100.0, burst=20)
let now = 1_700_000_000_000_000L            // 微秒

match rl.admit(key=42UL, now) {
  Admit        => handle()
  Throttled(w) => sleep_us(w)               // 明確告訴你還要等多久
}

// 診斷：限流器自己的健康度
let (ok, no, total) = rl.stats()
println(rl.table_used(), rl.table_evictions())
```

---

## 5. 依賴邊界與驗證

* **零依賴**：不依賴任何 `semiring/*` 套件 —— 因此可被 `hostfs`（耐久性／BFT 提交）與 `root`（HTTP 邊緣）同時匯入而不造成環。
* `hostfs` 的 WAL 提交路徑用它做「每租戶的寫入配額」，`tat` 與 WAL 記錄同一筆原子提交。

```bash
moon test semiring/ratelimit --target wasm-gc
```
