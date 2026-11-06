# cubical-hermitian — 一部可執行的數學工程史

> MoonBit · `vv0101v01/cubical-hermitian` v2.0.0 · `preferred_target = "wasm"`
> **9 聯邦 + 統一頂點 · 44 套件 · 53 元件 · 245 個 `.mbt` · 162,396 行**
> `python3 tools/arch_check.py` → `architecture ok` · `cmd/main` → **129/129 定理** · `cmd/metatheory` → **485/485 定律** · `cmd/showcase` → **47/47 證書**

這個倉庫把「依賴立方型別論 × 精確代數 × 有限對稱 × 拓撲斯 × 概形 × 凝聚數學 × 張量幾何」寫成
一份**可編譯、可判定、可複驗**的程式。它不是論文附錄，而是一條**有年月、有瓶頸、有突破**的工程線。

本 README 是規格書（SPEC）的**工程史濃縮版**：只保留「為什麼要這樣做、卡在哪、怎麼破、留下什麼」。
逐條規格與逐符號登記看 `spec.mbt` 的 `spec_registry`；每個資料夾的逐檔精讀看各自 `README.md`。

---

## 30 秒驗證

```bash
python3 tools/arch_check.py                       # 245 .mbt / 162,396 行、44 套件、53 元件
moon check --deny-warn --target wasm-gc           # 0 warnings, 0 errors
moon run --release cmd/main        --target wasm-gc  # 129/129 定理總表
moon run --release cmd/metatheory  --target wasm-gc  # 485/485 定律（反射 × 全域實例 × 歸納-歸納）
python3 tools/health_scan.py > tools/health_report.md # 死碼／重複／債務盤點（報告，非閘門）
moon run --release cmd/showcase --target wasm-gc  # 47/47 大一統證書
moon run cmd/semiringreport --target native       # 19 節量測報告（含限制的量化邊界）
```

---

## 一、工程發展史

倉庫以「期」推進。每一期的驗收方式都一樣：**新增登記條目 + 可執行的 `check_*` 函式 + 白箱見證**；
沒有做完的部分下一期明示，不以代表元或數值觀察冒充一般定理。

| 期 | 主題 | 關鍵突破 | 留下的東西 |
|---|---|---|---|
| 早期 §1.1–1.3 | 打地基 | η-long βπη 正規化；有限宇宙的端點 `comp`；符號判定（ROBDD、wiring、first-match 範形） | `cubical/finite`、`cubical/face_bdd` |
| 早期 §1.4–1.5 | 依賴化 | NbE 擴到 Π／Σ／宇宙；Kan 結構推行至全專案型別 | `cubical/kernel/nbe_dep.mbt`、`kan_dep.mbt` |
| 早期 §1.6–1.7 | 立方 AST | 特徵值／投影子／仿射填充的完全符號代數；Path、資料、HIT 與 `hcomp` 按型別化簡 | 符號線性代數層、`kan_ast.mbt`、`ast_laws.mbt` |
| 早期 §1.8 | 生成而非手寫 | 語義系統重構；**通用 schema 生成器**（一個描述同時生成 checker／evaluator／conversion／quote／Kan） | `cubical/kernel/schema.mbt` |
| **第六期** | 六大邊界收束 | 正性函子／互歸納／商／宇宙 scheme／高維 HIT；`DSystem` 相容與 first-match 範形；一等 `Equiv`／`ua`／`GlueEquiv`；受檢型別線＋schema registry；代數擴張＋Jordan；BDD DAG＋認證數值 | `schema_*`、`dsystem_compat.mbt`、`equiv_ast.mbt`、`algebra/` |
| **第七期** | 宣告與模組 | 容器函子巢狀遞迴；`S³ = Susp(S²)`；認證 Jacobi 譜迭代；HOU + 雙向 semantic elaborator；參數化模組 | `sphere3.mbt`、`Jacobi_interval.mbt`、`cubical/elaborator`、`module_system.mbt` |
| **第八期** | 從檔案到套件 | `architecture.json` + `arch_check.py`：依賴關係變成**可檢查的 DAG**；立方體演算法；計算性單值性 | 五聯邦分層、`cubical_algorithms.mbt`、`univalence.mbt` |
| **第九期** | 精確代數完備 | `Rat` 全面改用 `BigInt`；Sturm 實根隔離、Rouché 圓盤認證、分裂域塔；一等宇宙多態宣告；分離編譯 | `algebra/qpoly_factor*`、`root_isolation.mbt`、`schema_universe_poly.mbt` |
| **第十期** | 一般化與成本 | 一般 quasi-inverse 的 `lemIso`、可收縮纖維、自動 adjointification；核內 `IntegerS` 與 `π_n` 商型；有界 Huet；模組位元組格式 | `equivalence_phase10`→`adjoint_equivalence.mbt`、`sphere_classification.mbt`、`hou_unify_stream.mbt`、`module_binary.mbt` |
| **第十一期** | 跨家族與持久化 | 跨家族宣告、精確修復、一般點收縮、位元組持久化、雙二次去巢、子句學習、圓的覆疊、交錯模組 | `schema_inductive_recursive.mbt`、`biquad_denest.mbt`、`circle_classify.mbt` |
| **第十二期** | 編譯出來的一切 | 同規格遞迴與 eliminator 編譯、case-split 轉換與路徑值合成、DAG codec、DRUP、主合一子 | `conv_case_split.mbt`、`dterm_dag_binary.mbt`、`hou_unify` MGU |
| **第十三期** | 收緊與證明 | 正性不動點與 foreign IH 映射、最大相容補入、intern 共圖、DRUP 與自適應譜、環路分類、殘差求解、完整性鏈 | `schema_positivity.mbt`、`dterm_intern.mbt`、`artifact_crypto_wal.mbt` |
| **第十四期** | 規模化 | 同時 IR、全部最大完成、增量 DAG 與共用 bundle、Hensel／Van Hoeij、剪枝 BDD／DRAT、Eckmann–Hilton／五邊形 4-胞、TLV／認證 CAS／增量同步 | `hensel_multiquad_deflation.mbt`、`artifact_repository.mbt`、`associahedron.mbt` |
| **第十五期** | 推核心到極限 | BDD／SAT／宿主立方極限推進；`π₁(S¹) ≃ ℤ`；基點環路—懸掛伴隨；Freudenthal 懸掛定理 | `bdd_cutwidth.mbt`、`circle_classify.mbt`、`sphere_homotopy.mbt` |
| **第十六期** | 六大核心工程完備 | 大宇宙與開放同時 IR、容器正性；DSATUR 最大團與 0~1 黏合方塊；標準 SHA／Ed25519＋WAL；精確 LLL／Van Hoeij；Hopf–Freudenthal 收縮；Huet 延遲約束圖／惰性串流／三方倉庫合併 | `schema_open_ir.mbt`、`module_bft_mvcc.mbt`、`lll_van_hoeij_rouche.mbt`、`hou_unify_stream.mbt` |
| **第二十二期** | 型別論機制的三根軸（＋四項續作） | 反射＝NbE `decide_eq` ＋可重放憑證 `check_cert` ＋宇宙保守性／Mahlo 反射；全域實例＝Horn/SLD ＋序數終止 ＋臨界對一致性 ＋黏合與鏡像對偶；歸納-歸納＝切片塔 Kleene 鏈（Fin 落後 Nat 一階）＋索引檢查 ＋互遞迴消除器。續作：**STLC 的 β 與索引傳輸**、**一致性判準的完備化**（可達目標宇宙＋區域實例＋擴充穩定性＋Newman）、**可導性擬陣判準**（交換公理太弱，次模性反例）、**R(4,4)=18 與 R(3,5)=14 用 Paley 見證夾死** | 第九聯邦 `meta/`、`cmd/metatheory`（485/485 定律）、[`meta/README.md`](meta/README.md) |
| **第二十一期** | 七大邊界總帳 + 重構 | 七項能力邊界全部以「突破／變化／推遠／剔除」四重處置收乾；重構成**雙 V 形 + X 形交疊**；新增 `@gcd` 與 `@condensed`；四項猜想進實驗室 | 見下兩節、`architecture.json`、`bridge/` |
| **v2 Wave 1–4** | 拆包與收斂 | 編年史檔名清零；`cubical` 拆成 7 個無環子套件；`root` 收斂為門面＋定理總表 | `root` 單包微測試 **11.05s → 0.63s**、`pkg.generated.mbti` 精簡 **90%** |

> Wave 2–4 的單包微測試實測：`finite 0.22s` · `face_bdd 0.38s` · `homotopy 0.38s` · `elaborator 0.35s` ·
> `hermitian 0.57s` · `store 0.58s` · `kernel 0.95s`。**拆包的收益是秒級的，不是美學的。**

---

## 二、七大能力邊界：瓶頸 → 突破 → 見證

這是整部工程史最值得讀的一頁：**每一條「這裡做不到」都被追到具體的演算法或語法限制，然後被打掉。**

| 邊界 | 當年的瓶頸 | 突破了什麼 | 可複驗見證 |
|---|---|---|---|
| 一 · Schema | 宇宙層級只有有限 `Int32`；容器不能帶路徑索引 | 直至 ε₀ 的 **Cantor 範式超限序數**（`cantor_ord_lt`，`1+ω=ω<ω+1`）；索引容器降階為正性函子；Tarski–Mahlo 反射證書 | `verify_mahlo_universe_reflection` |
| 二 · DSystem／合成 | 高維布林空間逐點枚舉 `2ⁿ`；未知中性項分不清是缺陷還是拓撲障礙 | ROBDD 餘因子不交莖黏合轉換：**2 個規範莖覆蓋 `2²⁰ = 1,048,576`** 個居民；自由群 `F₂` 字約化證明交換子 `[a,b]` 在 `T²` 可填、在 `S¹∨S¹` 必拒（殘留字長 4） | `conv_sheaf_glued_boolean_partition`、`wedge_square_filler_report` |
| 三 · 持久層／共識 | 只有單機 `fsync` 撕裂模型，沒有共識 | `3f+1` 拜占庭狀態機 + RFC 8032 Ed25519 法定人數封緘 + `CHWALJRN` 崩潰恢復；`wasm-gc` 與 `native` 上 100% 確定 | `bft_ed25519_quorum_commit_to_wal`（`n=4, f=1`，需 `2f+1=3` 獨立真簽章） |
| 四 · 精確代數 | 超越數只能對一次有理數分離；特徵多項式的高斯消元遇有理數爆炸 | 任意次數 **Liouville 分離證書**；Schanuel 線性無關秩見證；**無除法 Berkowitz Toeplitz `O(n⁴)` + 多質數 CRT** 重構特徵多項式 | `liouville_transcendence_certificate`、`schanuel_linear_independence_cert`、`qmat_charpoly_berkowitz_crt` |
| 五 · BDD／SAT／宿主立方 | 自然宿主立方需要 `2ⁿ` 次探針；單一連通分量 `n ≤ 20` | **泛點 Yoneda `O(1)` 具體化**：`n = 24` 只需 1 次求值（省 `16,777,216` 次探針）；Cuthill–McKee 前沿割寬排序，26 變量鏈得 **51 節點** ROBDD、精確 `#SAT = 66,791,053` | `reify_natural_dcube_symbolic_o1`、`bdd_dag_of_face_frontier_treewidth` |
| 六 · 球面同倫／相干 | 單例傳輸硬上限 5 階；`dhit_face` 不能寫裸變數端點 | 任意 `n` 階單例收縮；**六維 `K₆`**（42 頂點、9 個五維小面、`χ = 1`）南北半球＋相干胞；裸變數端點 HIT；凝聚 Adams ↔ 立方 Brunerie 雙向互證 | `dpath_singleton_n_transport_value`、`dpath_associahedron_k6_coherence_value`、`Ext^{1,2}=F₂` 且 `Ext^{2,3}=0`（故 `2η=0`）↔ `\|β\|=2` |
| 七 · HOU／模組 | 高階匹配結果型別須一階；模組熱替換禁止互遞迴與並行快照 | 內層 `ULam` 的高階匹配（候選皆經 βη 驗證）；Tarjan SCC + 無鎖 MVCC 原子熱替換；Goldfarb 不可判定性**在核心內**以丟番圖歸約見證（`2×3=6` 合一成立、`2×3=5` 拒絕） | `hou_match_higher_order_lambda`、`hot_load_tarjan_scc`、`hot_load_mvcc_commit_atomic`、`goldfarb_verify_diophantine_encoding` |

**方法論上的一條硬規則**：能證的就證，不能證的就**量**，量到的邊界**寫進報告**。
`cmd/semiringreport` 的 §19 專章就是這條規則的產物——例如「只有一個候選時，錯誤不會被發現」。

---

## 三、三條技術主線

**主線 A · 立方型別論核心**（`cubical/`，7 個子套件、65 檔、71,077 行）

```text
簡單型別 NbE → +η → 依賴 Π/Σ/宇宙 → Kan 全型別 → schema 生成器（inductive/HIT/open-IR）
   → 一等 Equiv/ua/Glue → 受檢型別線與 registry → 計算性單值性
   → π₁(S¹)≃ℤ → π₂(S²)≃ℤ → Blakers–Massey → π₄(S³)≅ℤ/2ℤ
```
演進的判準始終是同一句話：**把「在有限宇宙上算得出來」升級成「在依賴核心裡算得出來」**。
`cubical/finite` 至今仍是規格樣板；`cubical/kernel` 是唯一信任邊界（零浮點、零代數耦合）。

**主線 B · 精確代數與判定**（`algebra/`、`gcd/`、`semiring/trop/`）

```text
Rat → BigInt（任意精度）→ QuadNum/AlgNum（Q[x]/(m)）→ 分裂域塔 → 實根隔離(Sturm) → Rouché 認證
   → 超越分離（Liouville/Schanuel）→ 無除法 Berkowitz+CRT（避開分數爆炸）
   → 泛消元 GCD（F_p RREF / ℤ HNF·SNF / 擴張歐氏 / Grassmann / 自由群）五域對帳
```
判定的哲學：**先選規範形，再用比較規範形代替比較物件**（BDD 根 ID、DFA 典範字串、DFT 範形、
minimal 多項式餘式、`Trop` 的根與重數）。

**主線 C · 工程化與可信度**（`architecture.json`、`cubical/store`、`hostfs/`、`accel/`、`tools/`）

```text
可檢查的依賴 DAG → 分離編譯（interface_hash + 依賴指紋）
   → CHMODBIN/CHDAGBIN/CHREGBIN（版本協商、TLV 段、增量 delta）
   → 雜湊鏈 + Ed25519 工件庫 + 崩潰一致 WAL → BFT 法定人數 → SCC 原子熱替換
   → CPU 64-bit SWAR / Ozaki II + RNS NTT / Hscanbox / HVM2 → WGSL 著色器（瀏覽器零依賴驗證台）
```
這一線的價值不在「多一個功能」，而在**讓前面的數學家不會因為編譯順序、位元組格式或
崩潰時序而失去可信度**。

**主線 D · 型別論機制的三根軸**（`meta/`，5 套件、19 檔 —— 第九聯邦）

```text
數學地板（序數 · 合一/反合一 · 擬陣 · 有限複形 · Ramsey）
   ├─ 反射：          reify ⊣ reflect（NbE）→ decide_eq（快）＋ check_cert（逐步重放） → 宇宙抬升保守性 → Mahlo 式反射
   ├─ 全域實例：      Horn/SLD 解析 → 序數終止 → 臨界對一致性 → 黏合（H¹ 障礙）→ 鏡像對偶 → Ramsey 深度窗口
   └─ 歸納-歸納：     schema → 索引檢查 → 切片塔 Kleene 鏈（Fin 落後 Nat 一階）→ 互遞迴消除器 → 序數終止憑證
                      → STLC 的 β（ctx_insert / subst_insert 的索引傳輸）→ 逐步型別保持
```

四項續作把「已知未做」變成可執行：STLC 的 β、一致性判準的完備化（可達目標宇宙＋區域實例＋
擴充穩定性＋Newman 引導）、可導性擬陣判準（交換公理太弱，給出次模性反例）、以及
**R(4,4) = 18 / R(3,5) = 14**（Paley 圖 P₁₇ 給下界、遞迴上界 9+9 給上界，兩邊夾死，
不需要 2^153 的窮舉）。細節見 [`meta/README.md`](meta/README.md) §6.5。

這一線的判準和前六期一樣：**不是「實作了特性」，而是「機制中的每一條命題都被重算一次」**。
`moon run cmd/metatheory` 逐條印出被機器重算的定律與最小見證，不引用任何外部結論。

---

## 四、里程碑數字

| 項目 | 數字 | 出處 |
|---|---|---|
| 定理總表 | **129 / 129** | `cmd/main`（`root/spec.mbt` 的 `print_report`） |
| 大一統證書 | **47 / 47**（`atlas 18/18`） | `cmd/showcase` 的 `all_certs_ok` 與 summary 行 |
| 跨聯邦橋 | `K₆ = 15/15`、`K₇ = 21/21` | `@bridge` |
| 幾何—邏輯圖譜 | `ATLAS-01..18` | `@bridge` |
| 猜想實驗室 | `CONJ-01..12`、演化族 6 | `@conjecture` |
| 張量圖譜 | `𝔽₃` 6,561 張量秩計數 `[1, 128, 4032, 2400]` | `@tensor`、`spec.mbt` |
| 同倫 | `π₁(S¹)≃ℤ`、`π₂(S²)≃ℤ`、`π₄(S³)≅ℤ/2ℤ` | `@homotopy` |
| 指定有限模型的局部相干角 | `11040→552→0`；`276` 個規範類、總重數 `11040` | `@homotopy`、`@bridge` |
| 直覺猜想與反例攻擊 | **5 條**：1 條有界倖存、4 條反例後修正 | [`bridge/INTUITIVE_CONJECTURES.md`](bridge/INTUITIVE_CONJECTURES.md) |
| 上同調 | `h¹(ℙ¹, O(−2)) = 1`；`T²` 杯秩 1 vs `S¹∨S¹∨S²` 秩 0 | `@scheme`、`@topos` |
| 量化工程的極限 | 26 變量鏈 51 節點、`#SAT=66,791,053`；`n=24` 方塊 1 次求值 | `@face_bdd`、`cubical/kernel` |
| **型別論機制定律** | **485 / 485** | `cmd/metatheory`（第九聯邦，逐條重算） |
| Ramsey 的更大值 | **R(4,4)=18**、**R(3,5)=14**（Paley P₁₇ 下界 ＋ 遞迴上界夾死） | `meta/core/ramsey_ex.mbt` |
| STLC 的 β | 每一步約簡都 `icheck` 通過且索引不變（含走入 binder 的索引傳輸） | `meta/iit/stlc.mbt` |
| 可導性擬陣性 | 判準（無合成規則落在目標集上 ＋ 每規則最多覆蓋一目標），12 樣本與嚴格秩公理逐一對帳 | `meta/instances/characterize.mbt` |
| 全代碼健檢 | 死碼候選 **14 → 4**、完全相同函式體 **0**、結構極相近 **0** | [`tools/health_report.md`](tools/health_report.md) |
| 形式化（進行中） | **492** 條定理已在 Lean 4.35.0 中證明並登記（437 個舊標籤全部有對應；本輪新增 48 條能力定律尚未鏡射）（含 **R(3,4) = 9、R(4,4) = 18、R(3,5) = 14 的精確值**、R(3,3) ≤ 6、R(3,4) ≤ 10、擬陣的秩公理／交換公理／**貪心最優**／對偶 `r** = r`／Q 上線性擬陣、**Euler–Poincaré 全稱版與覆蓋神經的 H¹ 黏合判準**、字典序遞移與 ord_max 是 lattice join／結合的全稱版本、10 條 CNF 恆等式、**歸納-歸納型別的 ι 律與終止性（對所有項）**、**STLC 的 β 索引傳輸與主體約簡**、**擬陣判準／Möbius 併攏障礙／Newman 引理／完備一致性**、**宇宙反射的保守性與 Mahlo 式反射**（極限層成立、臨界後繼失效）、**NbE 的 β/η/冪等/保型，且「先 reflect 再 reify 等於直接 reify」對所有型別成立**、**快判定與逐步憑證兩條路徑一致且篡改被拒**、**實例憑證不靠搜尋即可獨立複驗**） | [`lean/`](lean/README.md) |
| 反射的兩條判斷路徑 | NbE `decide_eq` 與逐步憑證 `check_cert` 在所有樣本上一致 | `meta/reflect/proof.mbt` |
| 歸納-歸納的相位差 | `Fin` 的擴張永遠落後 `Nat` 一階（第 1 階段 `Fin = ∅`、第 2 階段才出現） | `meta/iit/schema.mbt` |

---

## 五、架構：雙 V + X 形交疊

```text
        [ 上 V₂：@bridge 大一統層 · cmd/* ]   47/47 證書 · K₆ 15/15 · 雙 V 閉環
                        ▲                                    ▲
        (幾何—拓撲—同倫左翼)                          (代數—邏輯—熱帶右翼)
        Cubical · Topos · Scheme          Symlib · Semiring · Algebra
                        ▲                                    ▲
        ══════ [ X 形交疊樞紐：@condensed ] ══════
          凝聚範疇 · 規範消元範疇 · Steenrod–Adams · 守恆律賬本 · 猜想 ×4
                        ▲                                    ▲
        (連續—層化—幾何分支)                          (離散—符號—路徑分支)
        Topos · Scheme · HostFS           Symlib · Semiring · Algebra
                        ▲                                    ▲
        [ 下 V₁：@gcd 泛消元新最大公因數基底 ]  F_p RREF · ℤ HNF/SNF · 擴張歐氏 · 五域消元
```

九個聯邦各自可獨立編譯、獨立驗證；`@gcd`（下頂點）與 `@bridge`（上頂點）是唯一被允許橫向聚合的兩處。
第九聯邦 `meta/` 不接依賴圖的任一端：它只依賴自己的 `meta/core`，用命題「重算」而非「引用」來支撐三大機制
（反射／全域實例／歸納-歸納，見 [`meta/README.md`](meta/README.md)）。它是**橫向**加入的第五條主線，
不改變原有雙 V 形的上下頂點。
完整依賴圖與層級見 `architecture.json`，規則見 `agent.v2.md`。

---

## 六、從哪裡讀起

| 你想做的事 | 從這裡開始 |
|---|---|
| 全景與快速上手 | 本檔 → [`readme.v2.md`](readme.v2.md) |
| 型別論機制（反射／實例／歸納-歸納） | [`meta/README.md`](meta/README.md) → `meta/reflect/nbe.mbt` → `meta/instances/engine.mbt` → `meta/iit/schema.mbt` |
| 程式碼健檢／債務盤點 | `python3 tools/health_scan.py` → [`tools/health_report.md`](tools/health_report.md) |
| 三個能力的能力對帳 | [`meta/CAPABILITIES.md`](meta/CAPABILITIES.md)（能不能用／能不能自己檢查／邊界在哪） |
| 定律的 Lean 4 形式化 | [`lean/README.md`](lean/README.md)（`lake build`；目前 492 條定理、437 個舊標籤（340 個互異）全覆蓋；MoonBit 側現有 485 條） |
| 為什麼不用 Why3 + Z3 | [`meta/prove_feasibility.md`](meta/prove_feasibility.md)（`moon prove` 實測報告） |
| 型別論／證明助理 | [`cubical/finite/`](cubical/finite/README.md) → [`cubical/kernel/`](cubical/kernel/README.md) → [`cubical/homotopy/`](cubical/homotopy/README.md) |
| 演算法／效能 | [`semiring/matrix/`](semiring/matrix/README.md) → [`semiring/sim/`](semiring/sim/README.md) → [`accel/`](accel/README.md) → [`cmd/semiringreport/`](cmd/semiringreport/README.md) |
| 代數幾何／範疇論 | [`symlib/`](symlib/README.md) → [`topos/`](topos/README.md) → [`scheme/`](scheme/README.md) → [`condensed/`](condensed/README.md) |
| 科學方法自動化 | [`tensor/`](tensor/README.md) → [`conjecture/`](conjecture/README.md) → [`bridge/`](bridge/README.md) |
| 改架構／接下這個專案 | **[`agent.md`](agent.md)**（英文交接手冊：43 份 README 索引、閱讀路徑、模板、onboarding）→ [`agent.v2.md`](agent.v2.md)（治理與通報） |
| 逐條規格 | `spec.mbt` 的 `spec_registry`；`spec_registry_sound()` 檢查非空欄位、名稱與符號唯一性，`spec_covers` 查詢登記覆蓋 |

**全倉 43 份資料夾 README**（16 個頂層 + 27 個巢狀子套件）都是「逐個讀完該資料夾每一個碼檔」後寫的，
索引與表格在 [`agent.md`](agent.md) Part II。

---

## 七、工程紀律（摘要）

1. **沒有常駐單元測試、沒有煙霧測試。** 改動 → 在**該檔案最底部**寫臨時 `test` → `moon test <單一套件>`
   → 讀值 → **立即刪除**。有長期價值的檢查提升成正式 `check_*` / `*_report` 函式。
2. **同一個問題用兩條互不相關的路徑各算一次**，答案相同才算數（FW vs Lehmann vs 分塊；`trop_det` 三路；
   幾何 `|β|=2` vs 代數 `Ext^{2,3}=0`）。
3. **檢查器必須有負對照**：`ReportBroken`（破壞分配律）、`ReportLying`（謊稱冪等）必須被拒絕。
4. **所有工作報告、建議、專案內容變更**只走 [`agent.v2.md`](agent.v2.md)。

細節見 [`agent.md`](agent.md) Part I。

---

## 授權與狀態

授權見 [`LICENSE`](LICENSE)。本倉庫為研究級工程：`129/129` 與 `47/47` 是**這次執行算出來的**，
不是宣稱；每一條限制在哪一個數字開始咬人，寫在 `cmd/semiringreport` §19 與各資料夾 README 的
「限制」段落裡。
