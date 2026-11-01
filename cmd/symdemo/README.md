# `cmd/symdemo/` — `symlib` 的功能演示（309 行）

> **套件**：`vv0101v01/cubical-hermitian/cmd/symdemo` · `pkgtype(kind: "executable")`
> **依賴**：`symlib`、`moonbitlang/core/bench`
> **1 檔 309 行** · 全 target 可編譯

---

## 1. 定位

`symbench` 與本套件同吃 `symlib`，但**問的問題不同**：

| 套件 | 問題 | 輸出 |
|---|---|---|
| `cmd/symbench` | **多快**？ | 每個案例的毫秒數 + `|Aut|` 對照 |
| **`cmd/symdemo`** | **能做什麼**？ | 「衍生演算法 vs 直接演算法」的**同結果對照** + 耗時 |

本套件的主角是 `versus(label, a, b)` —— 它同時跑兩條路徑、印出兩個結果，並**要求結果字串相同**。所以它既是演示，也是驗證。

---

## 2. 結構

```moonbit
fn timed(label : String, f : () -> String) -> Unit
fn versus(label, a : () -> String, b : () -> String) -> Unit
fn main
fn list_monad_laws_ok() -> Bool      // 串列單子三律
fn state_monad_laws_ok() -> Bool     // 狀態單子三律
```

### 2.1 `timed`
```text
t0 = monotonic_clock_start(); out = f(); dt = (end − t0)/1000.0 ms
println("{label}: {out}  [{dt}ms]")
```
**單位只在這裡換一次**（`monotonic_clock_end` 回傳微秒 → 除 1000 得毫秒），避免單位換算散落各處（`symbench/derived.mbt` 的頂註特別強調這點）。

### 2.2 `versus`
```text
衍生: <ra>  [xa ms]
直接: <rb>  [xb ms]
```
「衍生」= 由 `symlib` 的規範形式／範疇化**導出**的演算法；「直接」= 暴力／全搜索。兩者結果必須一致，速度差則是導出法的收益。這是 `symbench/derived.mbt` 的演示版（不量 12 個案例、只示範方法）。

### 2.3 單子律檢查
`list_monad_laws_ok()`、`state_monad_laws_ok()`：左單位、右單位、結合律三條，直接回 `Bool`。
它們存在於 `cmd` 而非 `symlib` 的理由：**單子律是「用法」的性質，不是「群論」的性質** —— 放在演示端才不會污染 `symlib` 的最小依賴面。

---

## 3. 執行

```bash
moon run cmd/symdemo --target native --release
```
（頂註建議 native release；wasm 直譯可跑但慢。）

---

## 4. 與 `symbench` 的關係

* 本套件的 `versus` 是**兩個路徑、兩個結果、兩個時間**；
* `symbench/derived.mbt` 把它擴展成 **A–G 七個衍生演算法族**（分量分解、Whitney 線圖、補圖對偶、標記向量、置換集、軌道折疊、Cayley），每個都附「結果一致（OK/FAIL）× 成本比（×）」。
* 因此開發順序是：先在 `symdemo` 確認語義正確，再搬進 `symbench` 量產能。
