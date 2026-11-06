# meta/reflect — 反射：NbE、可重放憑證、集合論反射（真實 club 版）

**層級 2（依賴 `core` 與 `instances`）。**

| 檔案 | 內容 |
|---|---|
| `nbe.mbt` | `Ty`/`Term`/`Val`、`eval`／`eval_typed`、`reflect`⊨`reify`、`nf`／`nf_in`、`is_beta_normal`／`nf_is_fixpoint`、`enum_terms`（型別上**窮舉**項）、`beta_once`/`eta_once`/`conv_step`、型別推導 `infer`/`check` |
| `proof.mbt` | `decide_eq`（快、語義）、`prove_eq`（產生逐步鏈）、`check_cert`（慢、語法、獨立重放）、`cert_size` |
| `universe.mbt` | **集合論反射**：`HFSet`（規範編碼的遺傳有限集合）、`hf_mem`／`hf_power`、`v_level`（`V_0 = ∅`、`V_{n+1} = P(V_n)`）、公式 `F` 與**真滿足關係** `sat`、`absolute_at`（帶參數絕對性）、`reflects`／`reflecting_levels`、`unbounded_in_window`／`closed_upward_in_window` |
| `club.mbt` | **club 的組合學**：`OrdFun`（normal function）、`fun_omega_pow`／`fun_omega_omega_pow`、`in_range`／`preimage`、`diagonal`（12.3 的對角迭代）、`range_subset` |
| `link.mbt` | `prove_instance` → `ProofNode` → `check_instance_proof`：**無搜尋**的實例憑證檢查 |

**信任邊界**：快而不被信任的判定程序 → 短憑證 → 慢而可信的局部檢查器（Boutin 式 reflection 的骨架）。

## 這一輪補完的三件事

1. **NbE 的一般 β（不是樣本）**：`enum_terms` 在給定上下文與型別上窮舉**所有**大小 ≤ 10 的項
   （六個型別、316 個項），逐個檢查 β-正規、`nf` 冪等、一步 β 後 `nf` 不變、η 收縮後 `nf` 不變、型別保持。
   過程中抓到兩個真 bug：`nf` 之前不知道自由變數的型別（現在有 `nf_in` 帶上下文），
   `beta_once` 的 `subst` 在**開項**上不會把索引 > j 的變數減一（樣本全是閉項所以沒被打到）。
2. **集合論反射從玩具模型換成真實表述，玩具版已刪除**。舊版把「句子裡最大的原子編號 < 層級」當成可證性，
   再對它證保守性 —— 那是編碼遊戲，沒有集合、沒有 ∈、沒有量詞。現在：
   * `V_α` 是**真的累積層級**（`V_4` 有 16 個集合），`sat` 是真的滿足關係（含量詞與 ∈）；
   * 「`φ` 在 `α` 反射」= 對所有 `x ∈ V_α`，`V_α ⊨ φ[x]` 與 `V ⊨ φ[x]` 同真假；
   * 反射層級在視窗內**無界**且**對更大的層級封閉**（club 的兩半）；
   * `φ ∧ ψ` 的反射層級 = 兩者反射層級之交 ⇒ **有限公式集可同時反射**（club ∩ club 仍是 club）；
   * 非空洞：`∃x.x=x` 需要 `V_1`，`∃x∃y.x∈y` 需要 `V_2`，`∃x∃y∃z.(x∈y ∧ y∈z)` 需要 `V_3`。
3. **club 的組合學**（`club.mbt`）：`α ↦ ω^{1+α}` 與 `α ↦ ω^{ω+α}` 是 normal function，
   像無界、嚴格遞增、連續（`f(sup_n(1+n)) = sup_n f(1+n) = ω^ω`）；對角迭代
   `α_{n+1} = g(f(α_n))` 的點嚴格遞增且落在兩個像裡；反例 `{ω^{1+n}}` 無界**但不封閉**
   （sup `ω^ω` 不在集合裡）⇒ 缺封閉性就不是 club。

**邊界（明示，不是 TODO）**：本檔的「`V`」是物化出來的 `V_4`，所以給的是**有限視窗**版本的反射定理；
真正的 `V` 是全部 HF 集合。`meta/core` 只有右乘（`ord_mul_int`、`ord_mul_omega`），
所以 normal function 一律用 `ω^{…}` 造；`α ↦ α·2` 不是 normal（右乘不連續），
拿 `ω^{ω+α}·2` 當 club 是錯的 —— `club.mbt` 的 #6 正是這個現象的正面版本。
