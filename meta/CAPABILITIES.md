# kt 的三個能力：反射技術 / 全域實例 / 歸納-歸納

**目的不是形式化。** Lean 只在「推進能力時順帶需要證明」才寫（那是證明義務，不是產品）。
這份文件問的是能力問題，每個能力分三層：

1. **能不能用** —— 有 API、能跑、有輸出；
2. **能不能自己檢查** —— 有可判定的自我驗證（定律／檢查器），不是「我覺得對」；
3. **邊界在哪** —— 明示寫出來，不用「未來工作」帶過。

本輪全部落在 **kt（MoonBit）側**，`lean/` 一行沒改（仍凍結在 492 條定理）。
現況：`cmd/metatheory` **485 / 485 定律**、`cmd/main` **129 / 129**、`arch_check` → `architecture ok`
（44 packages、248 `.mbt`、164,345 行）。標籤分佈：core 115（互異 102）／instances 147（144）／
iit 164（87）／reflect 59（55），合計 485 條、**388 條互異**；定律函式 63 個。

---

## 1. 反射技術（`meta/reflect`）

| 能力 | 狀態 | 位置 |
|---|---|---|
| NbE 判定 βη 相等（`reflect`⊣`reify`） | ✅ | `nbe.mbt` |
| `nf` 真的算到正規形（含高階、含**開項**） | ✅ | `nbe.mbt` `nf`／`nf_in` |
| **一般 β：對型別上大小 ≤ 10 的所有項逐一檢查** | ✅ **本輪新增** | `nbe.mbt` `enum_terms`、`law_nbe_general_beta_over_all_terms` |
| 快判定 ↔ 逐步憑證兩條路徑可對帳 | ✅ | `proof.mbt` |
| **集合論反射：`V_α ⊨ φ` 真實滿足關係 + club** | ✅ **本輪把玩具換成真實並刪掉玩具** | `universe.mbt`、`club.mbt` |
| 實例憑證不靠搜尋就能複驗 | ✅ | `link.mbt` |

**本輪在這裡做了三件事：**

1. **NbE 的一般 β（316 個項，6 個型別，不是樣本）**：`enum_terms` 在給定上下文與型別上窮舉所有
   大小 ≤ 10 的項，逐個檢查 β-正規、`nf` 冪等、一步 β 後 `nf` 不變、η 收縮後 `nf` 不變、型別保持。
   過程中抓到兩個真 bug：
   * `nf` 不知道自由變數的型別（中性應用的參數型別掉成 `TOne`）→ 新增 `nf_in` 帶上下文；
   * `beta_once` 的 `subst` 在**開項**上不會把索引 > j 的變數減一（之前樣本全是閉項，所以沒被打到）。
2. **集合論反射換成真實表述，玩具版已刪除**。舊版把「句子裡最大的原子編號 < 層級」當成可證性，
   再對它證保守性 —— 沒有集合、沒有 ∈、沒有量詞，反射與 club 的內容全被編碼遊戲吃掉。現在：
   * `HFSet` 是規範編碼的遺傳有限集合（外延性由編碼唯一性保證），`V_0 = ∅`、`V_{n+1} = P(V_n)`，物化到 `V_4`（16 個集合）；
   * `sat` 是真的滿足關係（量詞、`∈`、`=`）；
   * 「`φ` 在 `α` 反射」＝ 對所有 `x ∈ V_α`，`V_α ⊨ φ[x]` 與 `V ⊨ φ[x]` 同真假；
   * 反射層級**無界**且**對更大的層級封閉**；`φ ∧ ψ` 的反射層級正好是交集 ⇒ **有限公式集可同時反射**（club ∩ club 仍是 club）；
   * 非空洞：`∃x.x=x` 需 `V_1`、`∃x∃y.x∈y` 需 `V_2`、`∃x∃y∃z.(x∈y ∧ y∈z)` 需 `V_3`；帶參數的絕對性另有反例（`∃y. x ∈ y`）。
3. **club 的組合學（`club.mbt`）**：`α ↦ ω^{1+α}`、`α ↦ ω^{ω+α}` 是 normal function；像嚴格遞增、無界、
   連續（`f(sup_n(1+n)) = sup_n f(1+n) = ω^ω`）；對角迭代 `α_{n+1} = g(f(α_n))` 的點遞增且落在兩個像裡
   （12.3 的交集構造）；反例 `{ω^{1+n}}` 無界但**不封閉** ⇒ 缺封閉性就不是 club。

**邊界（明示）**：`universe.mbt` 的「`V`」是物化的 `V_4`，所以是**有限視窗**版反射定理（真 `V` 是全部 HF 集合）；
`club.mbt` 用探針集與具體極限，不是對所有序數的全稱量化。`meta/core` 只有右乘，所以 normal function 一律用 `ω^{…}` 造
（`α ↦ α·2` 不連續，`ω^{ω+α}·2` 不是 club —— #6 就是這個現象）。
Lean 側的 `KtLaws/Reflect/Universe.lean` 仍是**舊玩具模型**的鏡射，屬凍結留檔、不代表能力。

---

## 2. 全域實例（`meta/instances`）

| 能力 | 狀態 | 位置 |
|---|---|---|
| SLD 解析（合一＋深度界＋環路偵測）、見證項 | ✅ | `engine.mbt` |
| **SLD 完備性：對照無剪枝的暴力搜尋，21672 組目標/深度全一致** | ✅ **本輪新增** | `engine.mbt` `derivable_bruteforce`／`law_engine_sld_resolution_is_complete_within_depth` |
| 終止（序數度量 `ω^{depth}`） | ✅ | `terminating` |
| 一致性判定（臨界對＋典範化＋歧義見證） | ✅ | `critical_pairs`／`coherent` |
| 不一致時自動修（Knuth–Bendix 式） | ✅ | `repair_step`／`complete` |
| **修補帶終止序（新規則必須 head > body，否則報告不硬塞）** | ✅ **本輪新增** | `rule_oriented`／`complete_oriented` |
| **模組匯入圖的良基性：SCC 判環、環給真見證、DAG 給典範解析序** | ✅ **本輪新增** | `modules.mbt` `resolve_modules` |
| 局部解黏合／Möbius 障礙、鏡像對偶、完備化與 Newman | ✅ | `compose.mbt`、`coherence.mbt` |

**本輪在這裡做了三件事：**

1. **SLD 完備性不再靠宣稱**：`resolve_all` 有兩個剪枝（深度界、路徑去環），會影響完備性。
   於是另寫一個刻意笨的 `derivable_bruteforce`（純 DFS、不做環路偵測、只靠深度遞減終止），
   在**窮舉**出來的目標空間（簽名 `Int/Bool/Array/Pair/Show`、大小 ≤ 6）× 3 環境 × 4 深度上
   逐一比對可解性：**21672 組全一致**（不漏解、不加假解）。另外驗深度單調、含環環境不發散、
   深度界真的會咬人（`Show (Array (Pair Int Int))` 在 d=2 無解、d=3 有解）。
2. **修補的終止序**：上一版只靠優先級釘死歧義，不保證收斂到**終止**的重寫系統。現在新規則只在
   「`head` 節點數嚴格大於每個 `body` 目標」時加入（orient），定向不了的臨界對**被報告**；
   `complete_oriented` 迭代到沒有可修的東西。六條檢查包含「每條新規則都定向」「舊規則未被動到」
   「沒有把定向不了的東西偷偷塞進去」「與舊版對一致性給同一個結論」。
3. **`resolve_canonical` 的循環匯入**：`resolve_modules` 對模組匯入圖跑 Tarjan（迭代版），
   SCC 大小 > 1 或自環 ⇒ 拒絕並給**真實迴路**（每步都是有向邊、首尾相同）；無環 ⇒ Tarjan 的反拓撲
   發射序就是典範解析順序（依賴先解），且與模組宣告順序無關（同一 DAG 打亂順序仍得同一串規則）。

**邊界（明示）**：`coherent` 在「觀察到的目標 + 給定深度」內完備，不是全域合流判定程序；
定向用節點數度量（不是完整 RPO/KBO），「節點數不定向但其實終止」的系統會被報告為未定向。

---

## 3. 歸納-歸納（`meta/iit`）

| 能力 | 狀態 | 位置 |
|---|---|---|
| schema（sort／建構子／索引項）與索引檢查 | ✅ | `schema.mbt` `icheck` |
| Kleene 鏈、有限 schema 穩定化、`Even/Odd` 不成長 | ✅ | `schema.mbt`、`examples.mbt` |
| 互遞迴消除器（ι 律）＋ 序數終止憑證 | ✅ | `iit_fold`／`iit_measure` |
| STLC 的 β 與索引傳輸 | ✅ | `stlc.mbt` |
| **等式進 schema（`ISchema.eqs`）＋ `ischema_ok` 承認等式** | ✅ **本輪完成** | `schema.mbt` `IEquation`／`ieq_ok` |
| **商對整條 Kleene 鏈良定義（任意兩居民商相等 ⇒ 摺疊相等）** | ✅ **本輪新增** | `quotient.mbt` |
| 商與 `iit_stage`／`iit_enumerate` 的相容、商不逃出鏈 | ✅ **本輪新增** | `quotient.mbt` |

**本輪把 QIIT 從「值層補丁」推進到「schema 的一部分」**：

* 等式住在 `ISchema.eqs`；`ischema_ok` 透過 `ieq_ok` 要求：至少一端是建構子、兩端若都是建構子則同一 sort、
  兩端樣式變數集合相同（重寫封閉）、非空洞；不合法時指出壞在哪一條。
* 商作在值層（`iquot`，燃料 32）：等式反覆重寫到不動點 —— `s(s x) = x` 下 `s⁴z = z`、四次 `s` 全消。
* **良定義是一般敘述**：對 Kleene 鏈（fuel 5、上限 64）上**每一對**居民比較，
  商相等 ⇒ `iit_fold_q` 相等（25 對全過）；商**不逃出**鏈；無窮多個 `sⁿz` 收成 **2 個**等價類；
  `iit_stage` 與商在居民上交換；ι 律在商之後仍成立（商不破壞歸納原則），而純 `iit_fold` 不尊重等式（對照組）。

**邊界（明示）**：有限 schema 才保證穩定，`Even/Odd` 永遠不成長；良定義性是在這條 Kleene 鏈上逐對檢查，
不是對所有 QIIT 項的全稱定理；商用燃料上界，互觸等式用完燃料即停（不假裝等價閉包）。

---

## 4. 之前列的「淌欠」，逐條結案

| 之前的項目 | 判定 | 本輪結果 |
|---|---|---|
| NbE 的一般 β | 是缺口（「非缺口」的舊判定過寬） | ✅ **做掉**：`enum_terms` 窮舉 316 個項逐個檢查；並修掉 `subst` 在開項上的真 bug |
| SLD 完備性 | 是缺口（沒有獨立對照） | ✅ **做掉**：`derivable_bruteforce` 對照 21672 組 |
| Knuth–Bendix 完備化 | 是缺口 | ✅ **做掉**（上一輪），本輪補上**終止序** |
| `resolveCanonical` 循環匯入 | 是缺口（kt 側本來沒有匯入圖） | ✅ **做掉**：`modules.mbt` Tarjan SCC＋真迴路見證＋典範序 |
| 集合論反射的後設推論 | 是缺口（玩具模型表達不了） | ✅ **做掉**：換成真實 HF 語意＋club 組合學，**玩具已刪除** |
| QIIT／HIIT 等式建構子 | 是缺口 | ✅ **做掉**：等式進 schema、商對整條鏈良定義 |

---

## 5. 驗證方式（可重跑）

```
export PATH="$HOME/.moon/bin:$PATH"
moon build --target wasm-gc                 # 綠
moon run  cmd/metatheory --target wasm-gc   # 通過 485 / 485 定律
moon run  cmd/main       --target wasm-gc   # passed 129/129
python3 tools/arch_check.py                 # architecture ok
python3 tools/gen_laws.py                   # 重新掃描 law_* 並重寫四個 laws.mbt
python3 tools/gen_labels.py                 # 從 metatheory 實際輸出重生 lean/labels/moonbit-labels.md
```

## 6. 形式化的原因與範圍（2026-11-07 補記）

**Lean 存在的唯一理由**已記錄在 [`../lean/WHY.md`](../lean/WHY.md)：`moon prove`（Why3 + Z3）在本倉定律的形狀上有
三個 lowering 缺口（`#proof_pure` 不支援遞迴、`Int` 無算術 variant、SMT 不做計算），
而三個能力裡有一批「對所有項／所有環境／所有 schema」的主張**既算不出來也證不動**。
按這個理由，形式化**只應該覆蓋全稱且需要歸納的命題**。

實測落差（同一份文件 §2）：Lean 側 580 條宣告中 **137 條是全稱／歸納**（屬於理由），
**403 條是 `decide`/`native_decide` 的具體計算**（超出理由：kt 跑一次就知道）。
本輪六個能力的全稱版本全部未寫，已列為證明義務 **O1–O6**（成本 6–10 週，建議先做 O4 定向⇒終止、O1 NbE 一般 β）。

**因此「定理條數」不是本倉的進度指標**，正確的指標是「O1–O6 完成數」，以及三段式對帳（能不能用／能不能自己檢查／邊界在哪）。

---

工具記錄：`tools/gen_laws.py` 的正規表達式原本只認**單行**簽名，`moonfmt` 折行過的 `law_*` 會被漏掉
（曾把 437 條漏成 128 條）。已改成跨行容忍；`tools/gen_labels.py` 改成讀**實際執行輸出**，
所以「漏登記」在標籤清單裡一定看得出來。
