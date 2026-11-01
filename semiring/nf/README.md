# `semiring/nf/` — 正規形：DFA 最小化、導數式正則表達式、么半群詞問題（F3 · Layer 3）

> **套件**：`vv0101v01/cubical-hermitian/semiring/nf` · **Layer 3** · 依賴 `semiring-algebra`
> **被依賴**：`cmd-semiringreport`、`root`
> **3 檔 712 行** — 「相等判定」的三個實例，每個都靠**不同的正規形**。

---

## 1. 定位

> 判定兩個東西相等，最便宜的方法永遠是「把它們化成同一個正規形，然後比字串」。

| 檔案 | 問題 | 正規形 | 判定 |
|---|---|---|---|
| `dfa.mbt` | 兩個 DFA 是否等價？ | **最小化 DFA** + 典範字串 | `dfa_canonical` 字串比較 |
| `regex.mbt` | 兩個正則表達式是否等價？ | **Brzo­zowski 導數** + `r_sum`/`r_prod` 的正規化 | 經 DFA |
| `sexpr.mbt` | 么半群詞問題 `a·b = b·a`？ | **么半群詞的正規形**（Knuth–Bendix 風格） | `normalize` 比較 |

---

## 2. `dfa.mbt`（261 行）

```moonbit
pub fn dfa_of_regex(r : Regex, alphabet : Array[Int32]) -> Dfa   // Thompson/導數 → DFA
pub fn Dfa::accepts(self, w : Array[Int32]) -> Bool
pub fn Dfa::nstates(self) -> Int32
pub fn dfa_minimize(d : Dfa) -> Dfa                              // Hopcroft/Moore 分割
pub fn dfa_canonical(d : Dfa) -> String                          // 典範字串（BFS 重編號）
pub fn dfa_equiv(a : Dfa, b : Dfa) -> Bool
pub fn regex_equiv(a : Regex, b : Regex, alphabet) -> Bool
```
* **`dfa_canonical` 是關鍵**：從起始狀態 BFS，按狀態編號重新命名 ⇒ 同構的 DFA 得到**逐字元相同**的字串。於是「等價」變成 `String` 比較，可放進雜湊表。
* `regex_equiv` 的流程：`r₁ → DFA₁ → 最小化 → canonical`，`r₂` 同理，最後比字串。
* 副產物：`Dfa::nstates` 讓「最小化真的變小了」可量測。

---

## 3. `regex.mbt`（235 行）

```moonbit
pub(all) enum Regex { REmpty; REps; RChar(Int32); RSum(Regex,Regex); RProd(Regex,Regex); RStar(Regex) }
pub fn Regex::rank(self) -> Int32       // 深度/複雜度度量
pub fn regex_cmp(a, b) -> Int32         // 全序 ⇒ 可排序 ⇒ 可取正規代表
pub fn r_sum(a, b) -> Regex             // 智慧建構：吸收律、交換排序、去重
pub fn r_prod(a, b) -> Regex            // 智慧建構：∅ 吸收、ε 單位
pub fn r_star(a) -> Regex               // ε* = ε、∅* = ε、(r*)* = r*
pub fn nullable(r) -> Bool
pub fn deriv(r, c) -> Regex             // Brzozowski 導數 d/dc
pub fn rx_accepts(r, w) -> Bool         // 逐字元取導數
pub fn Regex::to_text(self) -> String
```
* `r_sum`／`r_prod`／`r_star` 不是單純的建構子，而是**智慧建構子**：它們維持一個（部分）正規形（交換、結合、吸收、單位），大幅縮小後續 `deriv` 的爆炸。
* `regex_cmp` 提供**全序** ⇒ `r_sum(a,b)` 與 `r_sum(b,a)` 產生同一個語法物件（可交換性在構造層面成立，不只是語義層面）。
* `deriv` 是 Brzozowski 導數：`d/dc(∅)=∅`、`d/dc(ε)=∅`、`d/dc(c)=ε`、`d/dc(c')=∅ (c≠c')`，`sum`/`prod`/`star` 各有規則。`rx_accepts` 只需 `O(|w|)` 次 `deriv`，**不需要先做冪集構造**。

---

## 4. `sexpr.mbt`（216 行）— 么半群詞問題

```moonbit
pub fn mono_cmp(a : Array[Int32], b : Array[Int32]) -> Int32
pub fn normalize(e : SExpr) -> Array[Array[Int32]]              // 正規形：一組詞
pub fn idempotent_identity_holds(a : SExpr, b : SExpr) -> Bool          // 詞法正規形比較
pub fn idempotent_identity_holds_via_dfa(a, b) -> Bool                  // 經 DFA（交叉驗證）
pub fn sexpr_to_regex(e : SExpr) -> Regex
```
* 語法 `SExpr` 描述「么半群表示」：生成元、關係式、要判定的等式。
* `normalize` 產生**一組詞**（正規形可能是多個詞），`mono_cmp` 給全序 ⇒ 集合可比較。
* 兩條獨立的判定路徑：**詞重寫**（`idempotent_identity_holds`）與 **DFA 等價**（`..._via_dfa`）。兩者必須一致 —— 這正是全倉的反覆手法：**同一個問題用兩套完全不同的理論各算一次，答案相同才算數**。

---

## 5. 範例

```moonbit
// 1) 兩個「看起來不同」的正則表達式其實等價
let a = @nf.r_prod(@nf.RChar(97), @nf.r_star(@nf.RChar(98)))
let b = @nf.r_prod(@nf.r_star(@nf.RChar(98)), @nf.RChar(97))
assert_true(!@nf.regex_equiv(a, b, alphabet))
assert_true(@nf.regex_equiv(a, a, alphabet))         // 自反

// 2) DFA 最小化 + 典範字串
let d  = @nf.dfa_of_regex(a, [97, 98])
let m  = @nf.dfa_minimize(d)
assert_true(m.nstates() <= d.nstates())
println(@nf.dfa_canonical(m))                        // 同構 ⇒ 同字串

// 3) 么半群詞問題：兩條路徑必須同答案
assert_true(
  @nf.idempotent_identity_holds(e1, e2)
  == @nf.idempotent_identity_holds_via_dfa(e1, e2),
)
```

---

## 6. 驗證

```bash
moon test semiring/nf --target wasm-gc
```
