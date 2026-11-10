# `semiring/algebra/` — 半環結構與定律層（F3 · Layer 1，6 檔 2,265 行）

> **套件**：`vv0101v01/cubical-hermitian/semiring/algebra` · **Layer 1** · 零依賴（除 `moonbitlang/core`）
> **被依賴**：`matrix`、`monoid`、`trop`、`bp`、`io`、`graph`、`cat`、`app`、`cmd-semiringreport`
> **角色**：整個 F3 聯邦的「型別即定理」根源 —— 只放**結構與定律**，不含任何演算法。

---

## 1. 定位

> **能在編譯期表達的前提，就不要放到執行期檢查。**

10 個 trait 把「這一招在某半環上是錯的」變成**型別錯誤**；`laws.mbt` 提供可重跑、且**接受故意壞掉的實例**（negative control）的定律檢查器；`tropical.mbt` 一次給出七個具體實例。

---

## 2. 檔案清單

| 檔案 | 行數 | 內容 |
|---|---:|---|
| `semiring.mbt` | 222 | 10 個 trait 階層 + `Ops` 運算計數器 |
| `tropical.mbt` | 890 | 七個實例：`Trop`、`TropMax`、`Bottleneck`、`Counting`、`Prob`、`BoolSr`、`TropF` |
| `lattice_instances.mbt` | 607 | 兩個非平凡格序實例：`ParetoSet`、`CyclicSet` |
| `laws.mbt` | 371 | `LawReport` 與各層定律檢查器 |
| `group_star.mbt` | 120 | 完全正則半環的 `a*` 以子群階倍增計算 |
| `prng.mbt` | 55 | SplitMix64 可重現隨機源 |

---

## 3. `semiring.mbt` — trait 階層

| trait | 必須提供 | 數學保證 |
|---|---|---|
| `Semiring: Eq` | `zero`、`one`、`plus`、`times`、`is_zero`、`is_one` | `(⊕,⊗)` 交換么半群 + 分配律 + `0` 吸收 |
| `IdempotentSemiring` | `le(a,b)` | `a ⊕ a = a` ⇒ 自然偏序 |
| `TropicalSemiring` | （選擇性） | `x ⊕ y ∈ {x,y}`，熱帶／瓶頸皆屬此類 |
| `StarSemiring` | `star(a)` | Kleene 星 `a* = 1 ⊕ a ⊕ a² ⊕ …` |
| `OrderedSemiring` | `meet`、`top` | 有格結構（用於 `bridge/face_semiring.mbt`） |
| `GroupElement` | `group_inv`、`order_bound` | 元素落在有限子群內 ⇒ `a*` 可 `O(log m)` |
| `Monoid: Eq` | `empty`、`append` | 么半群 |
| `IdempotentMonoid` / `GroupMonoid` | 子標記 | 分別給 Sparse Table、Fenwick 的型別約束 |

`Ops`：`⊕`/`⊗` 的實際呼叫計數器，所有矩陣／圖演算法都可傳入，使「運算量」可量測而非估算。

---

## 4. `tropical.mbt` — 七個實例

```moonbit
pub(all) struct Trop       { ... }   // (min, +)：0 = +INF，1 = 0；值域 [-2^30+2, +INF]
pub(all) struct TropMax    { ... }   // (max, +)：0 = -INF
pub(all) struct Bottleneck { ... }   // (max, min)：瓶頸路徑
pub(all) struct Counting   { ... }   // (+, ×) on Int64：路徑計數
pub(all) struct Prob       { ... }   // (+, ×) on Double：機率（半環，非冪等）
pub(all) struct BoolSr     { ... }   // (∨, ∧)：可達性
pub(all) struct TropF      { ... }   // (min, +) on Double：浮點熱帶
```
* 建構／取值：`Trop::new/inf/is_inf/value`、`TropMax::new/is_neg_inf/value`、`Bottleneck::new/value`、`Counting::new/value`、`Prob::new/value`、`BoolSr::of`、`TropF::of/value/inf/is_inf`。
* **溢位不是答案**：`Trop` 以 `INF = 2^30 − 1` 表示 `+∞`，乘法做**飽和加**（`sat_add_i32`／`sat_mul_i32`）⇒ 錯的答案不會以溢位的形式偷偷出現。
* **星運算的誠實**：`Trop::star_checked`、`Prob::star_checked`、`TropF::star_checked` 回傳 `Result[_, String]` —— 當 `star` 不收斂（例如 `Prob` 的 `p ≥ 1`）時明確拒絕，而不是給出偽值。
* 每個實例都同時實作 `Show`、`Semiring`、必要的 `IdempotentSemiring` / `StarSemiring` / `GroupElement`（`Trop` 在 `a ≠ 0` 時形成 `ℤ` 的群結構，`order_bound` 用於有限化）。

---

## 5. `lattice_instances.mbt` — 兩個「非平凡」實例

### 5.1 `ParetoSet`（多目標最短路的核心代數）
* 元素 = **非支配集（antichain）**；`⊕` = 聯集後**支配剪枝**（冪等）；`⊗` = 閔可夫斯基和後剪枝。
* API：`ParetoSet::empty(dim)`、`::one_of(dim)`、`::point(vec)`、`::size`、`::label(i)`、`::is_identity`。
* 這是「向量成本」上的格序半環：`docs/DESIGN.md §5` 的多目標最短路就建立在它之上（見 `semiring/graph/pareto.mbt`）。

### 5.2 `CyclicSet`（`ℤ_m` 冪集）
* `⊕` = 集合聯集、`⊗` = **循環和**集（`{a+b mod m}`）。
* API：`CyclicSet::empty(m)`、`::one_of(m)`、`::singleton(m, x)`、`::of_range(m, elems)`、`::contains(x)`、`::cardinality()`。
* 用途：驗證 Burnside／`G`-集相關的指數律（`bridge` 的 `K5-*` 用它對接 `symlib`）。

---

## 6. `laws.mbt` — 定律檢查器

```moonbit
pub(all) struct LawReport { checks : Int32; violations : Array[String] }
pub fn LawReport::ok(self) -> Bool
pub fn LawReport::summary(self) -> String
```
檢查器（每個都吃 `gen : () -> S` 與 `samples`，用固定種子可重現）：

| 函式 | 檢查項目 | 型別約束 |
|---|---|---|
| `check_semiring` | ⊕/⊗ 結合、交換、分配、`0`/`1` 律 | `Semiring + Show` |
| `check_idempotent` | 冪等律、`le` 與 `⊕` 相容 | `IdempotentSemiring` |
| `check_star` | `a* = 1 ⊕ a·a*` | `StarSemiring` |
| `check_star_idem` | 冪等星閉的完整定律集 | `StarSemiring + IdempotentSemiring` |
| `check_monoid` / `check_monoid`（么半群族） | 單位律、結合律 | `Monoid` |
| `check_group_element` | `group_inv` 的逆律 | `GroupElement` |
| `check_semiring_approx` | 浮點近似版（以 `max_abs_diff` 判距） | `Semiring` |

**Negative control 是硬性要求**：`cmd/semiringreport` 會用 `ReportBroken`（`times(a,b) = a+b+1`，破壞分配律）與 `ReportLying`（謊稱冪等但 `⊕` 是加法）餵進來，並斷言檢查器**必須**報錯 —— 否則「所有定律都通過」只是恆真句。

---

## 7. `group_star.mbt` — `a*` 不必展開

> 若 `a` 落在階為 `ord` 的有限子群中，則 `a* = 1 ⊕ a ⊕ … ⊕ a^{ord−1}`，且對任意 `ord` 的倍數 `m`，`a* = ⊕_{k<m} a^k`。

因此 `star` 只要 `O(log m)` 次 `⊗`/`⊕`（平方倍增），而非 `O(m)`。這正是 `GroupElement` 這個 trait 存在的理由：**有了階上界，星閉就便宜**。

---

## 8. `prng.mbt` — 可重現的破壞者

SplitMix64：`Rng::new(seed)`、`Rng::next_u64`、`Rng::next_int(bound)`、`Rng::range(lo, hi)`。
**同一 seed ⇒ 同一實例**，因此測試、基準與量測報告在任何 target、任何 CI 執行都得到相同的資料與結論。

---

## 8.5 `resource_qtt_ctx.mbt` — 雙上下文半環分級資源系統（DILL / QTT）

將半環聯邦核心 `Semiring`／`StarSemiring` 直接提升為定量依賴類型論（Atkey QTT / Barber DILL）左半模引擎：
* **三值資源星閉半環 `LinUsage = {LinZero(0), LinOne(1), LinMany(ω)}`**（`to_code` 映射至 4-bit SWAR 碼 `{0, 1, 15}`，`usage_compatible` 判定子資源序 `actual ⊑ declared`）。
* **泛型雙上下文 `DualResourceCtx[R]`**：正交分離無限制持久區 `unrestricted_tys`（`Γ`）與半環分級資源區 `resource_grades`（`Δ_{\vec{q}}`），提供 `qtt_ctx_zero_resources`（`0·Δ` 型別形成編譯期抹除）、`qtt_ctx_scale`、`qtt_ctx_add`、`qtt_ctx_var_demand` 與 `verify_dual_qtt_semiring_laws()`（窮舉 `27` 組三元組公理並橫跨 `LinUsage`、`Counting`、`BoolSr` 核驗左半模定律，於 `bridge/frontier_7pillars_unification.mbt` 與 `@swar.swar_grade16_*` 對帳）。

---

## 9. 範例

```moonbit
// 1) 熱帶半環 + 星運算的誠實拒絕
let t = @alg.Trop::new(7)
assert_true(@alg.Trop::inf().is_inf())
match @alg.Trop::star_checked(t) {
  Ok(s)   => println(s)
  Err(msg) => println("star 不收斂：" + msg)
}

// 2) 定律體檢（含定律破壞者）
let ok = @alg.check_star_idem("Trop", fn() { gen_trop() }, samples=64)
println(ok.ok(), ok.summary())

// 3) Pareto 非支配集
let p = @alg.ParetoSet::point([3, 4])
println(p.size())

// 4) 可重現隨機
let rng = @alg.Rng::new(0xC0FFEEUL)
println(rng.range(1, 100))
```

---

## 10. 驗證

```bash
moon test semiring/algebra --target wasm-gc
```
