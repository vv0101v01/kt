# meta/iit — 歸納-歸納（inductive-inductive）型別

**層級 1。** 固定點取在**切片範疇的初始代數**上（Dybjer–Setzer），而不是乘積範疇的互遞迴不動點。

| 檔案 | 內容 |
|---|---|
| `schema.mbt` | `ISchema`/`ICtor`/`ITerm`/`IArg`、索引求值 `iterm_of_val`、`icheck`／`icheck_at`、`iit_stage`／`iit_enumerate`（Kleene 鏈 `T_{n+1} = T_n ∪ F(T_n)`）、`iit_fold`、`iit_measure`／`iit_subterm_decrease`、`ischema_ok`、**QIIT 核心**：`IEquation`／`ipat_var`／`i_match`／`i_inst`／`i_rewrite`／`iquot`、`ISchema.eqs`、`quot_fuel`／`iquot_schema`／`icheck_q`／`iit_fold_q` |
| `quotient.mbt` | QIIT 商的**定律檔**：等式住在 schema 裡、四次 `s` 全消、消除器尊重等式、純 `iit_fold` 不尊重（對照組）、索引檢查商不變、ι 律在商後仍成立、商是保守的 |
| `stlc.mbt` | STLC 的 `Ctx/Ty/Tm` 索引傳輸：`subst_insert`／`stlc_weaken`／`stlc_beta`／`stlc_norm` |
| `examples.mbt` | `Even/Odd`（無限、不穩定）、`Nat/Fin`（**Fin 落後 Nat 一階**）、`STLC Ctx/Ty/Tm` |
| `qiit_displayed_cwf.mbt` | **四分類內蘊帶族範疇（CwF）互遞迴 QIIT**（`QiitCon`、`QiitTy`、`QiitSub`、`QiitTm` + 跨等式轉換子 `QTmCoh`）：商正規化 `qiit_norm_*`、相依索引檢查 `qiit_check_*`、Kaposi–Kovács–Altenkirch 展示代數 `QiitDisplayedCwfAlgebra` 相干審計 `qiit_verify_displayed_coherence` 與 `law_qiit_intrinsic_cwf_and_displayed_eliminator` |

**不變式**：`icheck(v) ⟹ sort/index 一致`；`iit_fold` 滿足 ι 律（重建即恆等）；索引依賴圖無環。

## 這一輪把 QIIT 第一階段做完

等式不再是「值層上的一個補丁」，而是 **schema 的一部分**：`ISchema.eqs : Array[IEquation]`，
`ischema(..., eqs? = [...])` 就能宣告等式建構子。商化作在值層（`iquot`，燃料 32）：
* 等式實例化後雙方都重寫到不動點，所以 `s⁴` 全消（四次 `s` 全部塌成同一個值）；
* **消除器尊重等式**：`iit_fold_q = iit_fold ∘ iquot`，等式兩邊給同一個答案；
* **對照組**證明差別有內容：純 `iit_fold` 在等式兩邊給不同答案；
* 索引檢查商不變（`icheck_q = icheck ∘ iquot`）；ι 律在商之後仍成立；商是保守的（沒把不同的項併掉）。

## 第二階段：等式被 `ischema_ok` 承認，商對整條 Kleene 鏈良定義

等式建構子不再只是「schema 裡的一個欄位」，而是**要通過檢查**：`ieq_ok` 要求
至少一端是建構子、兩端若都是建構子則同一 sort、兩端樣式變數集合相同（重寫封閉）、
且不是空洞等式；不合法時 `ischema_ok` 給出哪一條壞在哪裡。
`law_iit_quotient_is_well_defined_on_all_stage_inhabitants` 檢查六件事：
`ischema_ok` 接受 `s(s x) = x`、拒絕跨 sort 與「兩端都是裸樣式變數」的等式、
商**不逃出** Kleene 鏈、**鏈上任意兩居民**商相等 ⇒ `iit_fold_q` 相等（25 對全過）、
無窮多個 `sⁿz` 收成 **2 個**等價類、`iit_stage` 與商在居民上可交換。

**邊界**：有限 schema 才保證穩定，`Even/Odd` 永遠不成長。商化用燃料上界，等式互相觸發時會在燃料內
反覆重寫；用完仍未收斂就回傳當前值（明示邊界，不假裝是等價閉包）。良定義性是在**這條 Kleene 鏈**
（fuel 5、上限 64）的居民上逐對檢查，不是對所有 QIIT 項的全稱定理。
