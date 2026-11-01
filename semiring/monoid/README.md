# `semiring/monoid/` — 么半群上的前綴與樹結構（F3 · Layer 2）

> **套件**：`vv0101v01/cubical-hermitian/semiring/monoid` · **Layer 2** · 依賴 `semiring-algebra`
> **被依賴**：`cmd-semiringreport`、`root`
> **1 檔 530 行** — 四種資料結構、四種**不同強度**的么半群要求。

---

## 1. 定位

> 「可以做前綴和」從來不是一個性質，是**四個**性質，強度不同，代價也不同。

| 結構 | 型別約束 | 更新 | 查詢 | 為什麼需要這個強度 |
|---|---|---|---|---|
| 前綴掃描 | `Monoid` | — | `O(n)` | 只要結合律 + 單位元 |
| 線段樹 `SegTree` | `Monoid` | `O(log n)` | `O(log n)` | 任意么半群皆可 |
| 稀疏表 `SparseTable` | **`IdempotentMonoid`** | 不可更新 | **`O(1)`** | 冪等 ⇒ 重疊區間重複計算無害 |
| 樹狀陣列 `Fenwick` | **`GroupMonoid`** | `O(log n)` | `O(log n)` | 需要減法才能做「前綴差」 |

這張表就是本套件的全部內容 —— **型別即代價**。

---

## 2. 檔案與 API

### 2.1 具體么半群
| 型別 | 內容 |
|---|---|
| `SumI64` | `SumI64::of(v)`；`⊗ = +`，`1 = 0` |
| `AffineM` | `AffineM::new(a, b)`、`::apply(x) = a·x + b`；**複合順序是關鍵**（`(f⊗g)(x) = f(g(x))`，故不可交換） |
| `OppositeM[M]` | `OppositeM::of(x)`：把任何么半群的**乘法順序顛倒**（`Monoid` 的 `append` 反向）—— 用來測「順序敏感」的實作是否真的正確 |

### 2.2 前綴
```moonbit
pub fn[M : Monoid] prefix_scan(data : Array[M], out~ : Array[M]) -> Unit
pub fn[M : Monoid] prefix_scan_sequential(data, out)   // 對照組
```
`AffineM` 是**非交換**么半群：若實作偷用交換律，`prefix_scan` 與 `prefix_scan_sequential` 會不一致 ⇒ 這是最有效的反例測試集。

### 2.3 三種樹
```moonbit
pub fn[M : Monoid] SegTree::build(data) / ::set(idx, v) / ::query(l, r) / ::len()
pub fn[M : IdempotentMonoid] SparseTable::build(data) / ::query(l, r)
pub fn[M : GroupMonoid] Fenwick::build(data) / ::add(i, v) / ::prefix(end) / ::range(l, r)
```
* `SparseTable` 的 `O(1)` 查詢**只在冪等時正確**：`min`／`max`／`gcd` 可以，`sum` 不行（重疊區間會被算兩次）。型別系統擋掉了 `SumI64` 的誤用。
* `Fenwick::range(l, r) = prefix(r) ⊖ prefix(l−1)` 需要**逆元**，因此是 `GroupMonoid`。

---

## 3. 範例

```moonbit
// 1) 非交換么半群的前綴（順序敏感）
let affines = [@mon.AffineM::new(2.0, 1.0), @mon.AffineM::new(0.5, -1.0)]
let out = Array::make(2, @mon.AffineM::new(1.0, 0.0))
@mon.prefix_scan(affines, out~=out)
println(out[1].apply(3.0))          // 依序應用，順序不可交換

// 2) 冪等：稀疏表 O(1)
let st = @mon.SparseTable::build([3, 1, 4, 1, 5])
println(st.query(1, 3).value)        // min = 1

// 3) 群：Fenwick 區間和
let fw = @mon.Fenwick::build([@mon.SumI64::of(5), @mon.SumI64::of(7)])
println(fw.range(0, 1).value)        // 12

// 4) 翻轉順序的么半群（測順序敏感性）
let opp = @mon.OppositeM::of(@mon.SumI64::of(1))
```

---

## 4. 依賴邊界與驗證

* 只依賴 `semiring-algebra` 的 `Monoid`／`IdempotentMonoid`／`GroupMonoid` trait。
* 段樹／稀疏表在 `cmd/semiringreport` 的「結構 × 複雜度」表中被引用。

```bash
moon test semiring/monoid --target wasm-gc
```
