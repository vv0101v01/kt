# `cmd/main/` — 定理註冊表的唯一入口（6 行）

> **套件**：`vv0101v01/cubical-hermitian/cmd/main` · `pkgtype(kind: "executable")`
> **依賴**：`root`（`vv0101v01/cubical-hermitian`，別名 `@lib`）
> **1 檔 6 行** —— 全倉最短的檔案，卻是最重要的介面。

---

## 1. 全文

```moonbit
///|
/// Entry point: run the theorem registry and print the report.
/// Run with `moon run cmd/main` from the project root.
fn main {
  guard @lib.print_report() else { abort("theorem registry failed") }
}
```

---

## 2. 為什麼只有 6 行

所有的定理、證書、對照檢查都在 `root` 的 `spec.mbt`／`report.mbt` 中，本檔只做**一件事**：把回傳值變成 **exit code**。

```text
  @lib.print_report() : Bool
        │ true  → 行程正常結束（exit 0）
        └ false → abort("theorem registry failed")（非零退出）
```

這使得 CI 只需要 `moon run cmd/main --target wasm-gc` 一行，就能把 129 個定理的整體結果變成一個布林值。**沒有任何「部分通過」的空間** —— 這是刻意的。

---

## 3. 執行

```bash
moon run cmd/main                      # wasm 直譯（最慢、最可移植）
moon run cmd/main --target native      # native 直譯
moon run cmd/main --target native --release   # 最快
```
輸出：`root/report.mbt` 產生的完整報告（見 `kt/README.md` 的輸出樣本），結尾為 129/129 的統計。

---

## 4. 與其他 `cmd/*` 的分工

| 套件 | 角色 | 是否需要在 CI 跑 |
|---|---|---|
| **`cmd/main`** | **正確性**（129 定理 + 47 證書） | **必須** |
| `cmd/showcase` | 七聯邦 + `K₇` + 雙 V 的敘事式輸出 | 建議（人類可讀） |
| `cmd/symdemo` | `symlib` 功能演示 | 選用 |
| `cmd/symbench` | `symlib` 效能基準（native release） | 選用（時間不穩定） |
| `cmd/semiringreport` | 19 節量測報告（native only） | 選用（產出 markdown） |

**原則**：`cmd/main` 只回答「對不對」，不回答「多快」。時間敏感的東西一律不進 `cmd/main`，否則 CI 會因為機器負載而偽失敗。
