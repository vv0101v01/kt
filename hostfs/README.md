# `hostfs/` — 宿主儲存接縫：崩潰一致寫入模型與 BFT 法定人數持久複本

> **架構位置**：`architecture.json` 中的 `hostfs`，**Layer 1**，零依賴（`depends_on: []`）。
> 定位：**跨 target 可執行的儲存語義規格** —— 真正的檔案系統後端只有 native 才有，但「寫入協定是否崩潰一致」這個性質可以在 `wasm-gc` 上被**證明**。
> MoonBit 套件名：`vv0101v01/cubical-hermitian/hostfs`。

---

## 1. 為什麼需要這個套件

SPEC §4 說明：儲存層刻意保持**抽象位元組儲存**，不耦合 POSIX 的 `flock`/`mmap`/`fsync`。這正確，但把「持久化配方」留成了口耳相傳的民俗知識。本套件把那份配方變成**可檢查的物件**。

關鍵區分（混淆這兩者是撕裂檔案（torn file）的根源）：

| 持久性 | 意思 | 對應系統呼叫 |
|---|---|---|
| **內容持久（content durability）** | inode 的位元組已落地 | `fsync(file)` |
| **目錄項持久（dirent durability）** | 「名字 → inode」的連結已落地 | `fsync(dir)` |

> **崩潰一致的唯一條件**：新 inode 的內容必須在**命名它的目錄項變持久之前**就持久。
> 若崩潰落在兩者之間，名字指向一個從未 flush 的 inode ⇒ 讀者看到撕裂值。
> 本套件存在的目的就是排除這**唯一**的失敗模式。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `durability.mbt` | 451 | 崩潰一致寫入的可執行模型：`StoreOp`、`DiskState`、`Recovery`、正確／錯誤協定的對照、崩潰點掃描 |
| `bft_consensus.mbt` | 371 | 把 `hostfs` 從單節點協定驗證器升級為 `N = 3f+1` 的拜占庭法定人數狀態機，並與崩潰一致的 `DiskState` 複本耦合 |

---

## 3. `durability.mbt` 精讀

### 3.1 型別

```moonbit
pub enum StoreOp { ... }                    // 一個與持久性相關的操作
pub enum Recovery { RecoveredValue(Int32); RecoveredOld; RecoveredTorn; RecoveredMissing ... }
pub struct DiskState { ... }                // 一個微型檔案系統的揮發 + 持久狀態
```
`disk_state_new(key, old)`：從「`key` 已持久持有 `old`」開始；`disk_apply(st, op)` 施加一步；`disk_recover(st, key)`：**斷電之後**讀者在 `key` 看到的東西（這是唯一的真相判準）。

### 3.2 三個協定，兩對對照

| 協定 | 步驟 | 性質 |
|---|---|---|
| `durable_write_protocol(key, new)` | `lock → write(staging) → fsync(staging) → rename(staging, key) → fsync(dir) → unlock` | **崩潰一致**且**完成即生效** |
| `torn_write_protocol(key, new)` | 直接 `rename` 而不先 flush staging | 典型錯誤：目錄項持久但內容未落地 ⇒ `RecoveredTorn` |
| `unacknowledged_write_protocol(...)` | flush 檔案但**不 flush 目錄** | **安全但不足**：退化回舊值，不撕裂，但已回報成功的寫入可能消失 |
| `durable_delete_protocol(key)` | `unlink → fsync(dir)` | 刪除本身在崩潰後仍成立 |
| `unacknowledged_delete_protocol(key)` | `unlink` 不 flush 目錄 | 安全，但條目可能**復活**（刪除未被履行） |

### 3.3 判定器（這是本檔的核心價值）

| 函式 | 問題 |
|---|---|
| `disk_run_crash(ops, count)` | 跑 `ops[0..count)` 然後拔插頭 |
| `protocol_is_crash_consistent(p)` | **在每一個可能的崩潰點**，讀者要嘛看到舊值、要嘛看到新值，**永不撕裂** |
| `protocol_durable_on_completion(p)` | 更強：明確跑完再崩潰，必須看到**新值**（才算「履行」了寫入） |
| `protocol_first_tear(p)` | 回傳第一個會撕裂的崩潰點索引（沒有則 `None`） |
| `protocol_deletes_on_completion(p)` | 跑完再崩潰，`key` 是否確實消失 |
| `check_durable_write_protocol()` | 上述全部，作為可執行定律 |

因為模型是**純資料**（沒有 OS、沒有計時器），`protocol_is_crash_consistent` 是對**所有**崩潰點的窮舉檢查，而非抽樣。

---

## 4. `bft_consensus.mbt` 精讀

### 4.1 定理骨架

```text
[ T-BFT-Quorum-Intersect ]
  在 N = 3f + 1 個複本中，任兩個 >= 2f + 1 的法定人數交集至少
  (2f+1) + (2f+1) - (3f+1) = f + 1 個複本
  ⇒ 只要拜占庭複本 <= f，兩個法定人數的交集必含 >= 1 個誠實複本。
```

### 4.2 型別與流程

```moonbit
pub(all) struct BftReplicaVote { replica_id; view; slot; value_hash; mac }
pub(all) struct BftQuorumCommit { ... }          // >= 2f+1 個不同複本的有效票
pub(all) struct BftDurableCluster { ... }        // 3f+1 個 DiskState 複本
```
| 函式 | 作用 |
|---|---|
| `bft_quorum_threshold(f)` | 回 `(N = 3f+1, Q = 2f+1)` |
| `bft_cluster_new(f, byzantine_ids, key, init_val)` | 建立 `3f+1` 個以崩潰一致協定初始化的 `DiskState`，並指定哪些複本拜占庭 |
| `bft_assemble_quorum(votes)` | 組法定人數，**拒絕**：偽造 MAC、重複 `replica_id`、越界 ID、`(view, slot, key, value)` 不匹配 |
| `bft_propose_and_commit_durable(cluster, ...)` | 一輪複製寫入：誠實複本投票 **且拒絕** 在同一 `(view, slot)` 對衝突值**模稜兩可**（equivocation）；提交時每個複本走 `durable_write_protocol` |
| `bft_cluster_quorum_read(cluster, ...)` | 讀取：當且有 `f + 1` 個複本乾淨恢復到同一個 `RecoveredValue(v)` 才回 `Some(v)`（因為 `<= f` 拜占庭 ⇒ `f+1` 個一致恢復必含誠實已提交者）⇒ **線性化讀** |

### 4.3 一次驗證兩件事

`bft_check_consensus_and_crash_durability()` 對 `f = 1..4`（`N = 4, 7, 10, 13`）驗證：
1. `[T-BFT-Quorum-Intersect]`；
2. 拜占庭模稜兩可被拒；
3. **誠實複本在寫入中途崩潰時，`RecoveredTorn` 出現次數為 0** —— 也就是拜占庭容錯與崩潰一致性**同時**成立；
4. 法定人數讀取的線性化恢復。

換句話說：本檔把「分散式共識」與「單機 `fsync` 順序」**耦合**起來，排除了兩個獨立的資料損毀來源：拜占庭分裂腦，以及半寫入後的撕裂磁碟。

---

## 5. 誰在使用

* `cubical/store/artifact_crypto_wal.mbt`：`ArtifactWalStore` 的 WAL 提交／恢復語義與本檔的協定模型同構（`artifact_wal_commit_tx`、`artifact_wal_recover`）。
* `cubical/store/module_bft_mvcc.mbt`：`bft_ed25519_quorum_commit_to_wal`（RFC 8032 簽章版的法定人數提交）與 `hot_load_mvcc_*` 的原子熱替換。
* `root` 的 `facade.mbt` 重導出本套件的精選入口，供 `cmd/main` 的定理總表引用。

---

## 6. 範例

```moonbit
// 1) 正確協定 vs 撕裂協定
let good = @hostfs.durable_write_protocol("k", 42)
assert_true(@hostfs.protocol_is_crash_consistent(good))
assert_true(@hostfs.protocol_durable_on_completion(good))

let torn = @hostfs.torn_write_protocol("k", 42)
assert_false(@hostfs.protocol_is_crash_consistent(torn))
println(@hostfs.protocol_first_tear(torn))     // Some(某個崩潰點)

// 2) BFT 叢集：3f+1 複本（f = 1 → 4 個複本；複本 #3 視為拜占庭）
let cl = @hostfs.bft_cluster_new(1, [3], "k", 0)
let (n, q) = @hostfs.bft_quorum_threshold(1)   // (4, 3)
assert_true(@hostfs.bft_check_consensus_and_crash_durability())
```

---

## 7. 依賴與邊界

* **依賴**：無（只有 `moonbitlang/core`）。
* **被依賴**：`cubical-store`、`root`。
* **不變量**：本套件**永不**直接呼叫真的 `fsync`；它只**模擬核心的持久性規則**並對協定做判定。真後端（native）只需實作與 `durable_write_protocol` 相同的操作序，即自動取得已被證明的性質。

---

## 8. 驗證

```bash
moon test hostfs --target wasm-gc        # 可在 wasm-gc 上完整驗證（無需真檔案系統）
```
