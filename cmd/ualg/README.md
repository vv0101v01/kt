# `cmd/ualg/` — 第十聯邦的定律總表

> **架構位置**：套件 `cmd-ualg`，聯邦 `ualg`，Layer 3，`depends_on: [ualg-core, ualg-site, ualg-demorgan, ualg-cube]`。
> 可執行套件（`pkgtype(kind: "executable")`）；只消費、不生產，任何套件都不得匯入它。

## 1. 一句話定位

把 `ualg/core`、`ualg/site`、`ualg/demorgan`、`ualg/cube` 四個套件的 `all_laws()` 逐條執行並印出；任何一條為假就 `abort`。

## 2. 檔案

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `main.mbt` | 57 | `main`：依套件、依章節印出每個命題，統計並決定結束碼 |
| `moon.pkg` | 8 | 四個 import ＋ `pkgtype(kind: "executable")` |

## 3. 得到的定理／實作的演算法

本資料夾不含數學內容——定理與演算法在四個被匯入的套件裡（見 [`ualg/README.md`](../../ualg/README.md)）。
這裡唯一的邏輯是「全部為真才正常結束」。

## 4. 依賴圖

```
ualg/core ──┐
ualg/site ──┤
ualg/demorgan ┼──► cmd/ualg（main）
ualg/cube ────┘
```

## 5. 流程與輸入／輸出

* **輸入**：無（不讀檔、不讀參數）。
* **輸出**（stdout）：

```
=== ualg/core — 構造性泛代數 ===

  ── 同餘格：兩條路徑
  ok   [  1] 同餘格：Freese 主同餘閉包 = Bell 窮舉（12 個代數逐一相同），|Con| = [4,4,3,16,2,5,2,2,2,4,14,2]
  …
  小計：10 條定律、49 個命題
…
  小計：2 條定律、26 個命題
…
通過 167 / 167 個命題
```

* **結束碼**：全部為真 ⇒ 0；否則 `abort("ualg laws failed")`。
* 標籤裡的數字是執行時算出後嵌入的；改了演算法而數字變了，輸出就會跟著變。

## 6. 執行

```bash
moon run cmd/ualg --target wasm-gc
```

在 2 核／2 GB 的沙盒上，含建置約 2 秒。CI（`.github/workflows/ci.yml`）有對應的一步。
