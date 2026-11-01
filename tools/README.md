# `tools/` — 架構守門人 `arch_check.py`

> **架構位置**：不屬於任何 MoonBit 套件（`architecture.json` 的 39 個套件不含 `tools`），是**基礎設施腳本**。
> 角色：把 `architecture.json` 的宣告變成**可執行的架構閘門**；`agent.v2.md` 指定的「第一層驗證」三件套之一。

---

## 1. 檔案

| 檔案 | 行數 | 說明 |
|---|---:|---|
| `arch_check.py` | 511 | 純標準庫（無第三方依賴）的架構一致性檢查器：套件／元件分層、檔案歸屬、實體 `moon.pkg` 匯入、原始碼引用圖、統計指標 |

用法：

```bash
python3 tools/arch_check.py                # 預設：只檢查，success 時印出架構摘要
python3 tools/arch_check.py --json         # 額外輸出 JSON 指標（files/lines per package/component）
python3 tools/arch_check.py --list-edges   # 印出元件邊（consumer -> provider：不同名稱數 / 引用次數）
python3 tools/arch_check.py --check        # 顯式只檢查（等同預設）
```
退出碼 `0` = 通過；`1` = 有違規（錯誤會逐條印到 stderr，方便 CI 直接失敗）。

---

## 2. 五項檢查

### 2.1 聯邦／大一統頂點分割
* `federations` 數量必須是 **5、6、7 或 8**（本倉為 8）；
* 每個 `federation.packages` 內的 package id 必須存在於 `packages`；
* **不得重複指派**：一個 package 只能屬於一個 federation（或 `unification` 頂點）；
* 每個 package 都必須被指派（漏了會報 `is not assigned to any federation or unification`）。
`unification`（`id = Double-V-X`，`observer = true`）被特別標記為 **apex** 角色。

### 2.2 檔案歸屬
* 掃描全倉所有 `.mbt`（排除 `_build`、`.git`、`.mooncakes`、`.moonagent`、`target`）；
* `components[].files` 支援 glob（`expand_files`）；
* 每個 `.mbt` 必須**恰好**屬於一個 component（漏掉或重複都報錯）；
* component 宣告的檔案若不存在也報錯。
> 這使得「新檔案沒有登記架構」不可能悄悄發生。

### 2.3 實體 `moon.pkg` 匯入
* 解析每個 `moon.pkg` 的 `import { "…" }` 區塊（含 `for "wbtest"` 的 test-scoped 匯入）；
* production 匯入必須與 `architecture.json` 的 `depends_on` **完全一致**（既不能偷偷多匯，也不能宣告了卻沒匯）；
* test-scoped 匯入也受檢查，但可保留作原始碼名稱解析之用。

### 2.4 原始碼引用圖（guardrail）
* 先把註解與字串剝掉（`strip_comments_strings`），避免文件裡的提及被當成依賴；
* 用 `DECL` / `ENUM` / `CTOR` 正則抽出宣告，**先 package-local 解析**，再沿匯入的廣義閉包解析（直接依賴按 layer 升序訪問，讓常見名稱優先解析到基礎層）；
* 得到的 `component -> component` 邊必須符合 `layer` 遞增與 `allowed` 邊；例外必須明列在 `exceptions`（本倉目前為空）。
* 腳本自述定位：*「The source graph is a guardrail, not a compiler: it reports the names that caused an edge so a human can decide whether the edge is real. Run after `moon check`; the compiler remains the source of truth.」*

### 2.5 統計指標
輸出 `totals`（`.mbt` 檔數與行數）＋ 逐 federation／package／component 的 `mbt_files`／`mbt_lines`。

目前的實測輸出：

```text
architecture ok: 8 federations + unification apex, 39 packages, 48 components,
                 218 .mbt files, 150868 .mbt lines
  federation cubical   (11 pkgs): 107 files, 102794 lines
  federation symlib    ( 3 pkgs):  29 files,   9671 lines
  federation semiring  (16 pkgs):  43 files,  12577 lines
  federation topos     ( 1 pkgs):   6 files,   6767 lines
  federation scheme    ( 1 pkgs):   5 files,   4982 lines
  federation condensed ( 2 pkgs):   5 files,   3643 lines
  federation discovery ( 2 pkgs):   4 files,   3060 lines
  federation accel     ( 1 pkgs):   5 files,   2722 lines
  apex unification     ( 2 pkgs):  14 files,   4652 lines
```

---

## 3. 與 `agent.v2.md` 的關係

`agent.v2.md` 定義了三層驗證閉環，本腳本屬**第一層（< 3 秒總閘）**：

```bash
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
python3 tools/arch_check.py          # ← 本檔
```

三條全綠才可提交。因為它只讀 `architecture.json` 與原始碼文字（不呼叫編譯器），在 CI 上約 **2 秒**完成，遠快於 `moon build`。

---

## 4. 修改流程（新增套件或檔案時）

1. 在 `architecture.json` 的 `packages` 增一筆（`id`、`path`、`moon`、`layer`、`depends_on`、中英摘要）；
2. 在對應 `federations[].packages`（或 `unification.packages`）加入該 `id`；
3. 在 `components` 增一筆（`files` 用 glob）或把新檔案納入既有 component 的 glob；
4. 建好實體 `moon.pkg`（匯入必須**恰好**等於 `depends_on`）；
5. `python3 tools/arch_check.py` 直到 `architecture ok`。

**不要**在 `exceptions` 裡塞東西來繞過分層 —— `agent.v2.md` 明確要求架構違規應以重構解決，而不是開後門。
