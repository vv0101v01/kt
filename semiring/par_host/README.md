# `semiring/par_host/` — 只存在於 native 的主機後端（F3 · 平台擴充）

> **套件**：`vv0101v01/cubical-hermitian/semiring/par_host` · **Layer 2（平台擴充）**
> **`moon.pkg` 的 `supported_targets: "native"` ⇒ 其他 target 整個跳過本套件**
> **依賴**：`semiring-par`、`moonbitlang/async`、`moonbitlang/async/fs`、`moonbitlang/core/bench`
> **1 檔 112 行**

---

## 1. 為什麼要分成 `par` 與 `par_host` 兩個套件

這是整個聯邦**最乾淨的編譯期多型範例**：

```text
       par/          （零依賴、全 target 可編）        ← 契約
         ▲
         │ 同一個型別 @par.ShardIO、同一組語義
         │
   par_host/   （supported_targets: "native"）        ← 實作
```
* `par/` 只宣告契約，**不依賴 async** ⇒ 在 `wasm`、`wasm-gc`、`js` 上零警告編譯。
* `par_host/` 只在 native 上存在；呼叫端的程式碼一行不改，只換 import 就換後端。

---

## 2. API（與 `par/` 同名同義）

```moonbit
pub fn backend_name() -> String        // "async(single-thread, structured)"
pub fn par_for(chunks : Int32, f : (Int32) -> Unit) -> Unit
pub fn shard_io_bench(payload : String, files : Int32) -> @par.ShardIO
```

### 2.1 `par_for` 的結構化併發
```text
@async.run_async_main
  └─ @async.with_task_group(g)
       └─ for k in 0..<chunks { g.spawn_bg(() => f(k)) }
```
三個保證都由 `TaskGroup` 提供，而不是靠呼叫端自律：
1. **群組結束時所有子任務都已結束** ⇒ 不會有懸掛的工作；
2. **任一子任務拋錯 ⇒ 群組取消其餘任務**（結構化取消）；
3. 使用者程式碼仍是**單執行緒** ⇒ 不需要鎖。

### 2.2 誠實的限制
第 (3) 點同時是本後端的**上限**：單執行緒 ⇒ **不能加速 CPU 密集的工作**（矩陣乘法不會因為換到這個後端而變快）。它加速的是 **I/O 等待**（`shard_io_bench` 的場合）。文件與 `par/par.mbt` 的註解都明寫這件事，避免「換了後端就變快」的誤解。

---

## 3. 範例

```moonbit
// native 專用：分片 I/O 併發
let io = @par_host.shard_io_bench(payload, files=16)
println(@par_host.backend_name())     // "async(single-thread, structured)"

// 呼叫端與 wasm 版共用同一份程式碼
@par_host.par_for(8, fn(c) { process(c) })
```

---

## 4. 驗證

```bash
moon test semiring/par_host --target native
# 其他 target 會直接跳過此套件（這是設計，不是失敗）
moon check --target wasm-gc      # 全倉：本套件不參與，且不產生警告
```
