# `cubical/store/` — 模組編譯、二進位格式、認證 WAL 與原子熱替換（Layer 5）

> **套件**：`vv0101v01/cubical-hermitian/cubical/store` · **Layer 5**
> **依賴**：`condensed`、`cubical-face-bdd`、`cubical-kernel`
> **被依賴**：`root`
> **9 檔 11,147 行** · 單包微測試實測 **0.58s**

---

## 1. 定位

`kernel` 提供檢驗過的物件（`CompiledModule`、`SchemaRegistry`、`DTerm` DAG）；本套件負責讓它們**離開記憶體而不失去可信度**：

```text
  編譯 ──► 二進位（自檢：magic + 版本 + 校驗）──► 位元組儲存 ──► 崩潰一致 WAL
    │            │                                              │
    │            └─ 版本協商（for_peer / migrate）               └─ Ed25519 簽章 + 法定人數
    └─ 分離編譯 + interface_hash + 依賴指紋 + 拓撲建置計畫
                                                    熱替換 ──► Tarjan SCC 批次原子 MVCC
```

設計約束：MoonBit core（本專案所用版本）**沒有可匯入的檔案系統套件**，因此儲存層一律寫在**抽象位元組儲存**介面上 —— 於是同一套邏輯可在 `wasm-gc` 上完整測試。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `module_system.mbt` | 1,152 | 模組系統：改名、匯入、宣告、定義、簽章、實例 |
| `module_compilation.mbt` | 1,101 | 分離編譯、介面雜湊、快取、拓撲建置計畫 |
| `module_binary.mbt` | 3,468 | `CHMODBIN` 穩定格式、版本政策與遷移、TLV 段、共享 DAG 包、模組儲存 |
| `module_hotload.mbt` | 748 | 執行期熱載入：過期偵測、依賴者計算、套用計畫 |
| `module_bft_mvcc.mbt` | 279 | Ed25519 BFT 提交寫 WAL + Tarjan SCC 原子熱替換（MVCC） |
| `dterm_dag_binary.mbt` | 646 | `CHDAGBIN`：intern DAG 的持久化與**增量 delta** |
| `schema_registry_persist.mbt` | 373 | `CHREGBIN`：schema registry 快照的二進位 |
| `artifact_crypto_wal.mbt` | 1,258 | SHA-256／SHA-512、Ed25519、`CHARTSIG` 簽章、崩潰一致 WAL |
| `artifact_repository.mbt` | 2,122 | 抽象位元組儲存上的耐久工件庫、雜湊鏈、CAS、增量同步、三方合併 |

---

## 3. 模組系統與分離編譯

### 3.1 `module_system.mbt`
| 型別 | 說明 |
|---|---|
| `ModuleRename` / `ModuleImport` | 改名與匯入 |
| `ModuleDecl` / `ModuleDef` / `ModuleItem` | 宣告／定義／條目 |
| `ModuleEnv` / `ModuleEntry` / `ModuleBinding` | 環境與綁定 |
| `ModuleExport` / `ModuleSignature` | 匯出與簽章 |
| `ModuleInstanceDecl` / `ModuleInstance` | 參數化模組的實例 |

入口：`module_rename`、`module_import`、`module_decl(_abstract)`、`module_def`、`module_env_new/add/find`、`module_signature`、`module_validate`、`module_resolve`、`module_ref`、`module_instantiate`、`module_instance_find`；示例 `bool_ops_module`、`generic_iterate_module`；檢核 `check_module_system()`、`check_module_interleaved_items()`。

### 3.2 `module_compilation.mbt`
* `CompiledModule`：檢驗過的物件／介面；保留**扁平化望遠鏡**，因此**不需要原始 import 即可作為匯入目標**（`compiled_module_to_module_def` 造出無 import 的合成模組）。
* `interface_hash`：由公開投影（參數、匯出型別…）計算，穩定且與實作細節無關。
* `ModuleDependencyFingerprint { path, interface_hash }`：**依賴的身分**。
* 快取：`ModuleCompileCache`、`module_compile_cache_new/size/lookup`、`module_compile_cached`、`module_source_fingerprint`、`module_dependency_fingerprint`。
* 建置：`module_topological_plan`（`ModuleBuildPlanReport`）、`module_build_dag_incremental`（`ModuleIncrementalBuildReport`）、`module_link_signature`、`module_link_instantiate`、`compiled_module_specialize_prefix`。
* 教學三件套：`abstract_point_module`、`point_implementation_module`、`point_client_module`。

---

## 4. 二進位格式（三個 magic）

| 檔案 | Magic | 內容 |
|---|---|---|
| `module_binary.mbt` | **`CHMODBIN`** | bytes `0..8` magic、`8..10` `u16` 版本、`10..12` `u16` flags、之後各段；全小端，每個 `Array[Int32]` 元素一 byte（`0..255`） |
| `dterm_dag_binary.mbt` | **`CHDAGBIN`** | intern DAG 的快照 + **增量 delta** |
| `schema_registry_persist.mbt` | **`CHREGBIN`** | `DSchemaRegistry` 快照 |

### 4.1 版本政策（三檔共用同一個精神）
`*_binary_format_version()`、`*_supported_versions()`、`*_version_policy()`、`*_version_of(bytes)`、`binary_negotiate_version` / `compiled_module_binary_negotiate_version`、`*_to_binary_for_peer(peer_version)`、`compiled_module_migrate_binary`。
⇒ 「舊版可讀、新版可寫、對等方可協商」是**程式碼**而不是約定。

### 4.2 其他機制
* 讀取回報：`*_load_binary_report` → `ModuleBinaryLoad` / `DTermDagBinaryLoad` / `SchemaRegistryBinaryLoad`（`ModuleBinaryStatus` 指出失敗階段）。
* Hex 往返：`compiled_module_binary_to_hex/from_hex`、`schema_registry_binary_to_hex/from_hex`。
* 段式擴充：`ModuleTlvSection`、`compiled_module_envelope_to_binary/load_binary`（外層信封可容納未知段 ⇒ 向前相容）。
* 共享 DAG：`SharedDagBundle`、`shared_dag_bundle_to_binary`、`shared_dag_bundle_load_binary_report`（多個模組共用一份 intern DAG）。
* 增量：`dterm_dag_delta_compute`、`dterm_dag_delta_validate`、`dterm_dag_delta_to_binary`、`dterm_dag_delta_apply`、`dterm_dag_delta_import_binary`；`dterm_intern_table_prefix_digest` 作為 delta 的錨點。
* 記憶體儲存：`CompiledModuleStore`、`compiled_module_store_put/get/contains/stats`。
* 檢核：`check_module_binary_format()`、`check_module_binary_versions_and_store()`、`schema_registry_binary_roundtrip_ok()`。

---

## 5. 熱載入

`module_hotload.mbt` 處理 SPEC §4 明列的邊界「連結目標是靜態無環 DAG，而非執行期熱載入」：

| 型別 | 說明 |
|---|---|
| `HotLoadDecision` | 每個模組的判定（`Reuse` / `Reload` / `Reject`） |
| `HotLoadRecord` / `HotLoadReport` | 歷史與整體報告 |
| `HotLoadEnv` | 可演進的環境 |

流程：`hot_load_dependents`（誰依賴我）→ `hot_load_stale_modules`（誰過期，以 `interface_hash` 判定）→ `hot_load_plan` → `hot_load_apply` → `hot_load_instantiate`；`hot_load_consistent` 檢查整個環境是否仍自洽；`hot_load_env_epoch` / `_history` / `_modules` / `_to_compiled`、`hot_load_signature`。
檢核：`check_module_runtime_hot_loading()`。

**判定原則**：只有 `interface_hash` 改變才需要重編下游；純實作改變可原地替換（配合下面的 MVCC 原子性）。

---

## 6. 密碼學與 WAL（`artifact_crypto_wal.mbt`，1,258 行）

* **FIPS 180-4**：`crypto_sha256`（64 輪 32 位）、`crypto_sha512`（80 輪 64 位）、`*_hex`。純實作，輸入輸出皆 `Array[Int32]`（每元素一 byte）。
* **RFC 8032 Ed25519**：`Ed25519Keypair`、`Ed25519PublicKey`、`Ed25519Signature`；`ed25519_keypair_from_seed`、`ed25519_sign`、`ed25519_verify`（GF(2²⁵⁵−19)、完整擴展扭曲 Edwards `(X : Y : Z : T)`）。
* **工件簽章**：`CHARTSIG` v1 —— `artifact_repository_seal_ed25519`、`artifact_repository_verify_ed25519`。
* **崩潰一致 WAL**：`ArtifactWalStore`、`ArtifactWalRecoveryReport`；`artifact_wal_store_open`、`artifact_wal_begin_tx`、`artifact_wal_put`、`artifact_wal_delete`、`artifact_wal_abort_tx`、`artifact_wal_commit_tx`、`artifact_wal_checkpoint`、`artifact_wal_recover`、`artifact_wal_byte_store`。
  提交語義與 `hostfs/durability.mbt` 的可執行模型同構（內容 `fsync` 先於目錄項），因此可在 `wasm-gc` 上驗證。

---

## 7. 工件儲存庫（`artifact_repository.mbt`，2,122 行）

```moonbit
pub struct ArtifactByteStore      // 抽象位元組儲存（記憶體實作：artifact_memory_byte_store_new）
pub(all) struct ArtifactRecord    // 工件記錄（kind + 內容雜湊 + 位元組）
pub(all) struct ArtifactRepository
```

| 群 | 函式 |
|---|---|
| 基本 | `artifact_repository_new/put/get/record/list/remove/recover/verify_all/stats` |
| 型別化 | `artifact_kind_compiled_module`、`artifact_kind_schema_registry`、`artifact_kind_dterm_dag`；`artifact_repository_put_compiled_module`/`get_…`、`put_registry_snapshot`/`get_…`、`put_dterm_dag_snapshot`/`get_…`、`put_dterm_dag_terms`、`get_dterm_dag_into` |
| 雜湊鏈 | `artifact_chain_save`、`artifact_repository_chain_entries`、`_chain_head`、`_chain_report`、`artifact_repository_get_chained`、`_recover_chained` ⇒ 任一筆被改動都可在驗證時定位 |
| 認證 | `ArtifactAuthKey`、`artifact_repository_verify_authenticated`、`_seal_authenticated`、`_put_cas_authenticated` |
| CAS | `ArtifactCasStatus`（內容定址儲存：相同內容只存一份） |
| 同步 | `ArtifactSyncReport`、`artifact_repository_sync_incremental` |
| 合併 | `ArtifactMergePolicy`（`abort` / `prefer_left` / `prefer_right`）、`ArtifactMergeConflict`、`artifact_repository_common_ancestor_records`、`artifact_repository_merge_three_way` ⇒ `ArtifactThreeWayMergeReport` |

---

## 8. BFT + MVCC 原子熱替換（`module_bft_mvcc.mbt`）

```moonbit
pub(all) struct BftEd25519WalReport
pub(all) struct HotLoadMvccSnapshot
pub(all) struct HotLoadMvccStore
```
* `[T-BFT-Ed25519-WAL]` `bft_ed25519_quorum_commit_to_wal(...)`：以 RFC 8032 簽章的**法定人數**提交，並把結果寫入 WAL（簽章在 `artifact_crypto_wal.mbt`，法定人數交集定理在 `hostfs/bft_consensus.mbt`）。
* `[T-Tarjan-MVCC-HotLoad]` `hot_load_tarjan_scc(...)`：把待替換模組依**強連通分量**分批（同一 SCC 必須一起換，否則中間狀態會看到互相依賴的新舊混搭）。
* `hot_load_mvcc_read(store, ...)`：讀取時看快照版本（MVCC）。
* `hot_load_mvcc_commit_atomic(store, scc)`：整個 SCC **原子**提交 —— 讀者要嘛看到全部舊版，要嘛看到全部新版。

---

## 9. 範例

```moonbit
// 1) 編譯 → 二進位 → 讀回
let cm  = @store.module_compile(mod_def, imports)
let bin = @store.compiled_module_to_binary(cm)
let rt  = @store.compiled_module_load_binary_report(bin)
assert_true(rt.ok)

// 2) 對等方版本協商
let peer_bin = @store.compiled_module_to_binary_for_peer(cm, peer_version=1)
let migrated = @store.compiled_module_migrate_binary(peer_bin, 2)

// 3) 工件庫：簽章 + 雜湊鏈
let repo = @store.artifact_repository_new(@store.artifact_memory_byte_store_new())
let sealed = @store.artifact_repository_seal_authenticated(repo, key)
assert_true(@store.artifact_repository_verify_authenticated(sealed))
println(@store.artifact_repository_chain_report(repo).ok)

// 4) SCC 原子熱替換
let store = @store.hot_load_mvcc_store_new(env)
let scc   = @store.hot_load_tarjan_scc(store)
@store.hot_load_mvcc_commit_atomic(store, scc)     // 全有或全無
```

---

## 10. 依賴邊界與驗證

* **依賴**：`gcd`（`L0` FNV-1a 64-bit 摘要鏈與 `ℤ`-零空間不變量賬本 `gcd/digest_chain_ledger.mbt`，已完全解除對 `condensed` 的跨聯邦依賴，套件層級由 `L5` 下沉至 `L3`）、`cubical-kernel`（`CompiledModule`、`DTerm`、`SchemaRegistry`）、`cubical-face-bdd`。
* **被依賴**：`root`、`bridge`。**只有 `root`／`bridge` 可匯入本套件**；`kernel` 不得反向依賴。
* 不可匯入 `hostfs`（`architecture.json` 未列此邊）：崩潰一致語義在此以 WAL 形式**自足**實作，兩者的對應關係由文件與 `bridge` 保證。

```bash
moon check --deny-warn --target wasm-gc
```
