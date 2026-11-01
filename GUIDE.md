# cubical-hermitian 導覽（MoonBit 實作）

語言：**中文正本** · [English](GUIDE.en.md) · [規格](SPEC.md) · [Specification](SPEC.en.md) · [架構](ARCHITECTURE.md)

一組互相纏繞的概念做成**可執行、可測試的計算模型**：

- 冪等 Hermitian 矩陣（正交投影）與其特徵空間正交分解；
- 以投影 `P` 為 retraction，對特徵空間做 Kan 纖維化**剪枝**（ambient 先填充，再 `P ∘ fill`）；
- cubical 區間、面公式與系統（partial elements）的**商**、可交換性與相容性；
- 立方體在區間上的 `comp`（開盒填充公式）；
- NbE 的**單值性**（正規形唯一），型別導向版本給出 **η 長正規形**；
- `coe` 計算規則是求值器規則故 `coe^refl ≡ id`、`coe^(ua swap) ≡ swap` 定義成立；
- HOAS 與一階語法在正規形上的**同構**；
- 有限宇宙的 **ua**、`PathP` 積交換、`Glue` 可靠性與**一般 Glue comp**、`J` 律、正交性；
- 有限側**符號判定**：ROBDD（面）、BDD 區域範形（系統）、wiring（有限等價）；
- 單一立方 AST 承載 PathP、Bool/Nat/List、Circle/Torus，以及
  `coe/comp/hcomp/hfill` 項構造子，`hcomp` 按型別逐類化簡；
- 依賴語義以持久共享環境、最多算一次的 thunk 與引文鍵快取求值；
  composition 分支是可按值合併/排序的 `DSystem`，Glue 保存完整
  多分支 partial type/value 系統；
- 有限 schema 描述子可生成通用歸納族（巢狀正性函子、互歸納、
  Tarski 歸納—遞迴、構造子等式約束、宇宙 scheme）與任意有限維 HIT
  （含商型別）的檢查、依賴消去、conversion、quote 與 Kan comp；
- 原始 `DSystem` 可精確判定相容性並有 first-match 範形；AST 內有一等
  `Equiv`/`ua`/`GlueEquiv`；語義線與 schema 分別有受檢查入口與註冊快取；
- 精確有理/代數擴張代數給出廣義特徵空間與 Jordan 分解；BDD 是
  hash-consed DAG 並有預算/DPLL，數值投影/立方體有精確證書影子；
- 宿主值上的立方體演算法：Kan 開盒、transport filler、路徑反演／串接、
  前綴／片段、congruence、函數外延性與依賴 `subst`；
- 計算性單值性：有限 wiring 宇宙的完全判定，以及 AST 的 `ua`／
  `pathToEquiv`、`uaβ`、往返同倫與二維 Glue 方塊證書；
- 一般語義 `lemIso` 給出 quasi-inverse 的纖維路徑／收縮與自動
  adjointification；另有核內 `IntegerS`、π₃ 商型與典範球面環路
  代表元（不是任意 π₃ 元素的分類定理）；
- 有界 Huet 搜尋、版本化已編譯模組 byte codec，以及 BDD
  sifting/cache、watched-literal DPLL 與 sparse/Karatsuba `QPoly` 乘法；
- `SPEC.md`/`SPEC.en.md` 與雙語附錄對全部型別、算子、規格、結構逐符號
  給出規範形式與範疇化；雙V形＋星稜柱七聯邦大一統後附錄共 **7,303 個符號**，cubical 與發現支柱的
  規格登記為 **142 條**；
- 雙V形（`V₁=@gcd → X=@condensed → V₂=@bridge`）＋Lakatos 發現迴圈七大聯邦（`cubical`、`symlib`、`semiring`、`topos`、`scheme`、`condensed`、`discovery`）及 `bridge`/apps 合共
  **31 套件／49 元件**，由同一 `architecture.json`/`tools/arch_check.py` 管制。

## 運行與驗收

```text
moon check --deny-warn --target wasm-gc     # 全專案通過且零警告
moon test --release --target wasm-gc        # 全倉精煉測試 21/21（覆蓋七聯邦＋大一統＋十二猜想圖譜與健檢回歸）
moon run --release cmd/main --target wasm-gc      # 129 項定理登記表，期望 129/129
moon run --release cmd/showcase --target wasm-gc  # 七聯邦 K_7 星稜柱大一統證書，期望 46/46
python3 tools/arch_check.py                 # 七聯邦依賴層級、唯一檔案歸位與計數
moon info --target wasm-gc && python3 tools/audit_spec.py --check
                                            # 雙語符號附錄與各套件介面＋spec.mbt 集合核驗（7,303 符號）
```

## 本次升級重點

### NbE 加 η（`nbe_eta.mbt`）

雙向型別檢查/求值；`quote_eta` 按型別產生 η 長範形：函數 `λx.f x`、積
`(fst p, snd p)`、Unit `()`。中性 spine 攜帶參數/姊妹型別，故
`f:(B→B)→B` 的範形是 `λg. f (λx. g x)`。積 η 令 `swap∘swap ≡ id` 在
函數層面定義成立。範疇化：物件 `LTy`、態射為項模 βπη 的自由笛卡兒閉範疇。

### 一般 Glue comp（`glue_comp.mbt`）

- 有限宇宙端點算法：任意線 `A0≃A1`、`T0≃T1`、端點等價 `e0/e1` 與面
  `φ0/φ1`。要求自然性方塊 `e₁∘coe_T = coe_A∘e₀`（箭頭範疇的態射，
  wiring 符號判定）。步驟：在 A 合成 `a_raw=coe_A(a0)`；在 T 合成
  `t1=coe_T(t0)`（φ 在 1 才亮起時由 `e₁⁻¹(a_raw)` 反造偏部分）；
  校正 `a1=e₁(t1)`。兩端 φ 皆成立時相干性保證校正是常值，逐一檢證；
  不相干線數據回 `None`。
- 特徵子空間線：型別線是變動投影 `P(j)` 的像。兩只相容開盒各自
  ambient 填充再逐點剪枝；帽子以 `(i,k)↦(1−k)a_cap(i)+k·U(1)(t_cap(i))`
  的校正方塊（A 內 hcomp）修到 `U(1)(t_cap)`，側面端點不動。

### 符號判定（`bdd.mbt`, `wiring.mbt`, `system_symbolic.mbt`）

- 面：ROBDD 為規範形，`sat/≤/≡/見證` 皆符號操作；
- 系統：有效區域 `φᵢ∧¬前覆蓋` 的 BDD 分割範形 `SystemNF`，商相等＝範形相等；
- 有限等價：wiring 帶號置換範形，wf 是 O(#葉) 置換性，合成是替換＋XOR，
  相等是結構相等。它同時是自由對稱冪冪範疇的態射（五邊形/三角形/六邊形
  相干律已驗）；
- 枚舉只留在 `*_extensional / *_oracle` 與白箱測試做差分校驗，不是判定路徑。

### 依賴 NbE：Π、Σ、宇宙（`nbe_dep.mbt`）

項與型別共用 `DTerm`；Π/Σ 的綁定後分量在語意域是閉包族，依賴代入
如 `snd p : B(fst p)` 直接計算。宇宙採累積 `Typeᵢ : Typeᵢ₊₁`。
轉換與範形由按型別的 `conv_at/quote_at`（含 η）與 `quote_ty` 給出；
範疇化為帶族範疇（CwF）句法模型。

### Kan coe/comp 全型別化（`kan_dep.mbt`）

型別線 `DLine{at,coe,fill}`，`comp=fill(1)`。Bool/Unit/Universe 是
常線；Π 在定義域反向 coe，Σ 沿第一分量路徑 coe 第二分量；依賴族
以「A 中路徑 → DLine」呈現。簡單型別與有限型別經非依賴嵌入，
有限 ua 是非恆常線；再加子空間線與 Glue，全專案型別族皆有 Kan 結構。

### 特徵值／投影／仿射填充的符號代數（`algebra/symalg.mbt`, `algebra/spectral_symbolic.mbt`）

以 Q 上多變量多項式範形與分式精確表示 `SymC/SymMat`，相等即多項式
恆等。譜投影用拉格朗日式 `Pₖ=qₖ(A)/qₖ(λₖ)`，幂等、正交、單位
分解與譜分解用首一整除及多項式恆等證明；`det(XI−A)` 給出特徵
多項式。仿射填充在雙線性類中由四角唯一決定，其係數差分公式與
邊界方程均在座標原子上以恆等式成立；投影剪枝滿足 `(I−P)(PF)=0`。

### 立方 AST 與 hcomp 按型別化簡（`nbe_dep.mbt`, `kan_ast.mbt`, `ast_laws.mbt`）

`DTerm` 同時有項與維度兩套 de Bruijn 索引：`DLamDim/DAppDim` 是
`<i> e`/`e @ r`，型別線和 tube 都是維度綁定子下的 body；
`DComp/DHComp/DHFill` 攜帶 `Array[DTubeTerm]` 多分支系統，
`DCoe` 攜帶線與任意兩端點。`comp_value` 的核心派遣是：

| 型別 | 化簡口訣 |
|---|---|
| Π | 參數先沿定義域**反向填充**，再在被搬運的餘域合成 |
| Σ | 先取第一分量 filler，第二分量沿它合成 |
| PathP | 除原 tube 外再加左右端點分支 |
| Universe | `hcompU` 產生 Glue；Glue 再以 partial/base 兩合成＋hcomp 校正 |
| Bool/Nat/List | 構造子對齊才遞迴（`succ`、`cons` 分頭尾） |
| Circle/Torus | 全 base 回 base，非平凡系統留形式 hcomp 點 |

Bool/Nat/List/Circle/Torus 都有依賴消去子；消去子遇到形式 composition
時會在 motive 裡再 comp，因此不會只卡在 eliminator 外層。Circle 點範形
是 `loop@r`，Torus 點範形是對邊黏合的 `square@(i,j)`。填充則由
`comp` 限制到線段 `j≤r` 得到；任意端點 `coe` 由 fill 與線段重參數化
組成，`coe(r,r)` 定義恆等。

### 語義系統、持久環境與惰性求值（`nbe_dep.mbt`, `semantic_system_laws.mbt`）

`DEnv/DDimEnv` 是帶長度的持久連結串列：脈絡延伸只 cons 一個節點並
共享尾部，陣列只留在公開邊界。構造子分量、函數引數、case 與 partial
分支以 `DVThunk` 延遲，第一次 `force_value` 後保存結果，
`lazy_force_count` 可驗證最多計算一次。維度線與 Π/Σ 族分別以簡化
維度鍵和引文鍵 memoize。

composition 的語義分支封裝為 `DSystem`。`dsystem_canonical` 沿型別線
以轉換合併同 body 分支（面取聯集）並按引文排序；`DPartialValue` 的
`partial_normal_form` 則用 BDD 計算 first-match 有效區域。`DVGlue`
保存完整 partial type `DSystem`，多分支元素以 `DPartial/DVPartial`
逐面給值，檢查、conversion、quote 與 Glue comp 都逐分支對齊。

### 通用歸納族與 HIT schema 生成器（`schema.mbt`, `schema_laws.mbt`）

`DInductiveSpec` 以參數/索引 telescopes、完整引數型別與
`DPositiveFunctor` 解碼描述一族，結構化極性判定處理別名與巢狀遞迴；生成器自動產生
`DInductive/DIntro/DInductiveElim` 的求值、雙向檢查、motive/case
型別、IH、conversion、quote 與逐引數 filler 的 comp。範例包括
`NatS/BoolS/ListS/VecS/FinS/TreeS/WS`。

`DHitSpec` 以任意有限維 cells 與 face expressions 描述 HIT。
`hit_cell_value` 在端點維度遞迴代入 face；生成 case 型別按維數是
point、PathP 或巢狀 PathP square，端點由低維 face 的消去值給出。
同 cell 時 comp 逐引數計算；移動維度在端點可精確決定時亦計算，其餘保留形式中性合成範形。
範例包括 `CircleS/SegmentS/TorusS`。

### 第六期邊界收束（`schema_extensions.mbt`, `dsystem_compat.mbt`, `equiv_ast.mbt`, `checked_line.mbt`, `schema_registry.mbt`, `algebra/qpoly.mbt`, `algebra/qmat.mbt`, `algebra/Jordan.mbt`, `algebra/algnum.mbt`, `bdd_dag.mbt`, `certified_numeric.mbt`）

- **Schema**：互歸納（Sum-indexed 編譯）、`DDecode` Tarski 歸納—遞迴、
  商 HIT、宇宙 level schemes、構造子 Path 約束與高維 cells。
- **系統/等價**：原始 `DSystem` 相容性以面相對轉換判定；AST `Equiv`
  攜帶 fwd/bwd/section/retraction，`ua` 與 `GlueEquiv` 在 Kan 引擎中計算。
- **可信邊界**：`DCheckedTypeLine` 保存經檢查 body；schema registry
  快取驗證與 telescopes。
- **精確代數**：`QPoly/QMat`、二次與一般代數擴張、primary projectors、
  廣義特徵空間與 Jordan 分解。
- **可擴展/認證**：BDD DAG（root 判定、預算、最佳候選次序、DPLL）；
  `QuadC/CertMat/CertPath` 以精確恆等取代數值網格的真假來源。

### 第七期：容器函子、S³、Jacobi、HOU 與模組

- `DFunctorContainer(Shape, Positions, index)` 把任意有限依賴多項式
  函子寫成 `Σ s, Positions(s)→X`，與互歸納/`DDecode` 共用生成器。
- `sphere3.mbt` 以懸掛迭代定義 `S²/S³`，meridian 端點與消去由 HIT
  生成器計算。
- `jacobi_interval.mbt` 對每次複 Jacobi 酉旋轉保存可重算的符號區間
  包含證書，最終以 Gershgorin 圓盤分簇特徵值。
- `hou_elaborator.mbt` 以 Miller pattern HOU 驅動雙向 elaborator，
  解隱含引數與 Nat motive，優化後譯回 `DTerm`。
- `module_system.mbt` 實作參數化模組函子、遞迴 import 內聯、
  only/hiding/open/alias/rename、歧義拒絕與 opaque 邊界。

### 第八期：架構治理、立方體演算法與計算性單值性

- **依賴順序**：同一個 MoonBit package 內的檔案沒有編譯先後；有意義的是
  依賴方向。專案現在有實體圖 `cmd/main → root → algebra`，root 內部則以
  `architecture.json` 分成 13 個 L0–L9 元件。`algebra/` 已成獨立套件，
  `algebra_imports.mbt` 集中管理 root 向它借用的名稱；`tools/arch_check.py`
  若發現未歸位檔案、重複歸屬或向上依賴就失敗。檔案/行數不再人工猜，
  由工具每次現算（細節見 `ARCHITECTURE.md`）。
- **立方體演算法** (`cubical_algorithms.mbt`)：`KanBox` 包住型別線、
  system 與 base；`kan_box_fill`、`kan_box_comp`、`kan_box_pathp` 給出開盒
  filler/cap。另有向 1/0 的 transport、checked-line transport、filler
  `PathP`，以及 `refl/sym/prefix/segment`、顯式 hcomp 方塊的
  transitivity、`cong/ap`、`funext`、`subst/substPathP` 的語義版與閉項
  builders。檢查函數為 `check_cubical_algorithms`。
- **計算性單值性** (`univalence.mbt`)：有限 `UPath` 透過 wiring 與
  `Equiv` 雙向精確轉換，transport 兩邊可計算。AST 側對語義型別線以 coe
  兩方向和 filler 往返路徑組成 `pathToEquiv`；`uaβ` 把沿 Glue 線的
  filler unglue；retraction 同倫與 Glue 方塊分別證明
  `pathToEquiv(ua e)=e`、`ua(pathToEquiv L)=L`，再包裝成
  `univalence_equiv_value`。checked 宇宙路徑與閉項
  `DMkEquiv` 映射亦被檢驗。檢查函數為 `check_univalence`。

### 第九期：完備代數、一等宣告與分離編譯

- **精確代數**：有理係數改為 `BigInt`；新增 Q 上完整因式分解、Sturm 實根
  與保證完備的複根細分、自動分裂域、一般根式去巢、任意精度 Jacobi。
- **Schema**：`schema_phase9.mbt` 加入一等層級宣告、透明型別算子正性、
  Bush 類非均勻巢狀迭代、原始互歸納、同時 IR 與 HIT 移動維度 lift。
- **系統與等價**：原始 `DSystem` 有 BDD 剪枝轉換、合意區域與受限修復；
  新增命題截斷、adjoint 型別與 improved counit、fiber center/singleton
  收縮，並令 primitive `DGlueEquiv` 引文保真。
- **基礎設施**：裸 `DLine` 與語義值可做維度代換；schema registry 有
  bucket hash-cons、snapshot/restore/merge 與 manifest。
- **認證與 BDD**：`AlgC` 在一般代數擴張上認證投影與任意次係數路徑；
  BDD DAG 原生提供 eval、BigInt sat-count、restrict、量化與 DPLL 總判定。
- **球面**：懸掛函子給出整數度數映射與單位環路，S³ 有極交換呈現的等價
  資料；經典 Hopf 映射的南北纖維以 Gauss 連結積分得到 `|lk|=1`。
- **前端**：HOU 新增重複變量、構造子 spine 與相異 flex-flex 交集片斷；
  模組有無 body 抽象宣告、`CompiledModule` 介面連結、prefix 特化與
  增量快取。在第九期當時，一般 adjoint 三角形與一般 fiber 收縮尚未
  完成；它們在第十期以語義 `lemIso` 補上。一般同倫群分類仍未宣稱，
  詳見 SPEC §4。


### 第十期：一般纖維、核內 π₃ 呈現、Huet 搜尋與穩定模組格式

- **等價**：`equivalence_phase10.mbt` 對任意輸入的語義
  quasi-inverse 分量實作三層 `lemIso` 填充，給出
  `equiv_fiber_path_value`、`equiv_contractible_fibers_value`，
  並把對角纖維收縮轉成 `adjointify_equiv_value` 的新 retraction
  與三角形。登記驗收在 Bool 非與 Circle 恆等上做端點轉換；
  Circle 的一般中點只按兩端面檢查，文件中不把它寫成任意脈絡
  一次驗畢的閉合 Π 證明。
- **整數與球面代表元**：生成歸納型 `IntegerS` 以
  `zero/posSucc/negSucc` 唯一表示整數，語義 `succ/pred` 在
  代表元上互逆。`pi3_sphere_type_term(2/3)` 是 `Ω³` 對
  命題截斷路徑關係的核內 QuotientS 型別。懸掛生成環路沿
  `p∙p⁻¹` 消去方塊以 `subst` 改基，`SphereLoopExpr` 以
  integer degree 分類這套代表元演算。這仍不是任意 π₃ 元素的
  encode/decode 證明 `π₃(S³)≅ℤ` 或 `π₃(S²)≅ℤ`。
- **HOU**：確定性 `hou_unify` 之外新增交易式
  `hou_search_unify`：先確定性求解，失敗才分支 imitation、
  projection、eta 生成、常數與同頭不變座標剪枝。狀態明示
  solved/no-unifier/residual/budget-exceeded；剪枝解是具體
  unifier 而非 MGU，一般 HOU 仍不可判定。
- **模組格式**：`module_binary.mbt` 是 `CHMODBIN` 版本 1
  byte-array／hex codec，標頭含長度與 DJB2-xor checksum；
  payload 固定標籤編碼整個 `CompiledModule`。結構解析與
  `compiled_module_validate` 語義載入分開，竄改、截斷、版本與
  尾隨位元組各有狀態。尚無檔案系統持久層或跨版本遷移。
- **成本**：BDD 有 bucket 增長 rehash、cache stats 與逐變量
  全位置的有預算 sifting；`face_sat_decide` 後備改為 Tseitin
  CNF 上的 two-watched-literal DPLL。`QPoly` 稀疏輸入用跳零
  卷積，稠密輸入一次縮放成 BigInt 整多項式後
  schoolbook/Karatsuba，冪次走二進位冪。最壞 BDD/SAT/代數
  成本仍可指數，檢查不作一般 benchmark 宣稱。

### 第十一期：跨家族函子、精確修復、一般點、持久化、雙二次去巢、CDCL、圓覆疊與交錯模組

- **Schema**：`DFunctorFamily` 讓巢狀引數實例化**另一個**已註冊
  家族（參數槽以 `DFunctorParamArg` 分 Term／Self），IH 以巢狀
  束 gather、validate 把關葉出現；同時 IR 可編譯出 decode
  規格（`simultaneous_ir_compile_decode`，真互依誠實拒絕）。
- **DSystem**：`face_agreement_face` 給 Face 值合意面（保留
  i=0/i=1 雙端點），`dsystem_repair_to_base_exact` 據此精確
  修復；`DCubeFunction` 開放盒把宿主不透明立方變成可驗證填充的
  物件（`algebra/poly_cube.mbt` 是精確座標版）。
- **等價**：`lemIso` 推到中性點與中性路徑兩端驗證；原始
  Circle/Torus 在點值 tube 上以 De Morgan 選擇計算合成。
- **持久化**：registry 的 `CHREGBIN` 位元組往返與損壞拒絕；
  `dterm_intern` 真正全域 hash-consing（共享子項、同 id、
  檢查/正規形不變）。
- **代數**：因式分解前置自適應 mod-p 圖樣剪枝；雙二次域
  `BiquadNum` 去巢/判等/符號完備於本域片斷；`Jacobi` 特徵值
  簇以平方自由 Sturm 精確分離。
- **成本**：BDD 變量序 n≤8 全排列可證最優；SAT 升格 CDCL
  （1-UIP 學習、VSIDS、Luby 重啟），鴿洞要真學習。
- **圓分類**：schema 圓的 helix 覆蓋（base↦ℤ、loop↦
  `ua(succ)`），encode 是 subst、decode 是整數消去的環路冪；
  代表元往返轉換成立，複合環路靠 transport 細分（單次 subst
  越 trans 點的內涵邊界明記於 SPEC §1.14.7 與 §4）。
- **前端**：HOU 搜尋加深 imitation/identification 與迭代加深；
  模組 `ModuleItem` 交錯 import 與宣告；二進位進 v2（含
  producer、v1 遷移、tag 8 拒絕）與進程內 artifact store。

### 第十二期：同規格遞迴、eliminator 編譯、結構合意、case-split、儲存庫、塔體、分層外延與主合一子

- **Schema**：無規格標記 `DFunctorSelfFamily` 達成 Bush 型同
  規格非均勻遞迴；函子 handler 以真實宿主 Self 型別取代佔位；
  不透明算子正性走宣告制（`DPositivityDeclaration`，另有 λ
  結構驗證版；宣告受信，不冒充證明）。同時 IR 多一條
  eliminator 編譯路線（函數層級嚴格低於 base 層級的
  predicative 片斷，閉項經強制套用逐 case 驗證）。
- **DSystem/轉換**：合意檢查只探分支實際出現的維度；exact
  repair 可在驗證下補入候選分支（極大非最大）。新增項層級
  Bool case-split 轉換；Circle/Torus 分支帽改以一般座標讀法
  保留繞數，路徑值 comp 算出環路帽。
- **持久化**：抽象位元組儲存上的 `ArtifactRepository`
  （manifest 雙哈希、index 最後提交、掃描復原）；模組/註冊
  位元組共用 DAG codec（CHMODBIN v3/CHREGBIN v2）與版本
  政策/peer 協商。仍是抽象協議、非磁碟服務。
- **代數/Jacobi**：不可約證書 fast path（`x⁴+1` 零
  Kronecker 預算判不可約）；根式判等塔增純三次與三二次體；
  Jacobi 區間迭代內建簇感知精化（與事後 Sturm 分離分開）。
- **成本/外延**：精確最佳 BDD 序進到子集 DP（n≤12）；CDCL
  加 LBD 刪除與 RUP 證明輸出（獨立重播核驗）；宿主立方以
  面內部/對角/連接三層有限探針分層檢查開盒相容（強檢查，
  非外延證明）。
- **球面/HOU**：單次 subst 跨複合環路串接繞數（π₁(S¹)≃ℤ
  對任意中性環路仍未證）；環路單位律以連接旋轉 3-胞在
  代表元上驗證，Hopf 恆等式改精確有理驗證（內部 Hopf/π₃
  分類不宣稱）；`hou_unify_mgu` 給 Miller pattern 片斷
  MGU／無解／殘留約束三態語意。

### 第十三期：正性不動點、最大完成、共用 DAG、塔體、DRUP、環路分類與完整性鏈

- **Schema**：SelfFamily 參數嚴格正性由逐參數報告的最小
  不動點判定（Bush 通過、深層負性傳播）；同時 IR 的 foreign
  IH 可經項層函子映射搬過 Product/Pi/List 巢狀引數。
- **DSystem/轉換/合成**：面下轉換只沿相關維度下降；repair
  可 exact-restrict 後以最大團給出真正最大相容補入。Bool
  case-split 改由兩範形差異選變量；Circle/Torus 方塊 comp
  逐候選座標逐面驗證，無可驗帽則保留 `DNComp`。
- **持久化**：intern 表保存 child-id 邊，`CHDAGBIN` 與
  活 interner 共用同一 DAG（第二次匯入新增 0）；工件每次
  put/remove 追加 `CHARTCHN` 前條摘要連結鏈，銷毀 index 後可攜
  外部鏈頭由 replay 復原，舊鏈與竄改被拒。
- **代數/Jacobi**：`CertModDegreePatterns` 以多個 mod-p
  次數圖樣聯合排除因式次數；`MultiQuadNum` 擴至四個平方類
  獨立生成元並作同域/加一根開方。Jacobi 包絡停滯時自適應
  切換精確 Sturm 分離。
- **成本/外延**：精確 BDD 序的增量 cofactor 子集 DP 擴至
  n≤16；CDCL 證明錄 Add/Delete 步驟供獨立 DRUP 重播；
  宿主立方分層加逐軸深層連接 Tier D（二維 105 探針）。
- **球面/HOU**：環路逆元、結合律及 sym 複合反同態
  3-胞齊備，閉代表式遞迴正規化至同次數典範字；
  `hou_solve_constraints` 交替 principal 傳播與有界 Huet
  搜尋求解整個殘留約束集（成功仍只保證 specific unifier）。

## 概念對照（精簡表）

| 概念 | 實作 | 檔案 |
|---|---|---|
| 冪等 Hermitian | `is_hermitian`, `is_idempotent`, `P=Σvₖvₖ†` | `complex.mbt`, `projector.mbt` |
| 特徵空間良構 | `Cⁿ=im(P)⊕ker(P)`、特徵方程、`tr(P)` | `projector.mbt` |
| 可交換相容 | `PQ=QP ⇒ PQ` 為投影 | `projector.mbt` |
| 系統商/剪枝 | BDD 區域範形、刪不可滿足/被含蘊分支、聯集交換 | `bdd.mbt`, `system.mbt`, `system_symbolic.mbt` |
| Kan 剪枝/comp | `P∘fill`、開盒公式、帽子、路徑傳遞 | `cube.mbt` |
| NbE / coe 定義等 | βπ 與 η 長範形、`def_eq(_eta)` | `nbe.mbt`, `nbe_eta.mbt` |
| HOAS 同構 | 宿主函數綁定、smart βπ、reify=`nf` | `nbe.mbt` |
| ua/PathP/J | wiring 等價→路徑、積交換自然性、常值線 coe | `wiring.mbt`, `pathp_glue.mbt` |
| Glue 可靠/comp | `glue/unglue` 方程、有限線端點算法、子空間 hcomp 校正 | `pathp_glue.mbt`, `glue_comp.mbt` |
| 範疇化 | Karoubi、面偏序、□ 範疇、句法 CCC、冪冪相干 | `categories.mbt`, `wiring.mbt` |
| Π/Σ/宇宙 | 依賴 NbE、型別導向轉換、依賴代入、Typeᵢ 層級 | `nbe_dep.mbt` |
| Kan 全型別 | DLine 對 Π/Σ/U/嵌入之 coe/comp 遞迴 | `kan_dep.mbt` |
| 符號譜代數 | 特徵多項式、譜投影恆等、仿射唯一填充恆等 | `algebra/symalg.mbt`, `algebra/spectral_symbolic.mbt` |
| 立方 AST/hcomp | PathP、`DSystem`、按 Π/Σ/Path/Glue/資料/HIT/Universe 化簡 | `nbe_dep.mbt`, `kan_ast.mbt`, `ast_laws.mbt` |
| 環境/惰性/快取 | `DEnv` 共享尾、`DVThunk` 最多算一次、維度線/族 memoization | `nbe_dep.mbt`, `semantic_system_laws.mbt` |
| 通用歸納/HIT schema | telescopes、函子正性、互/巢狀/歸納遞迴、商、高維 cells、生成 elim/case 與 comp | `schema.mbt`, `schema_extensions.mbt` |
| 原始系統/Equiv/線 | DSystem checked 相容、first-match 範形、AST Equiv/ua/GlueEquiv、受檢查線與 registry | `dsystem_compat.mbt`, `equiv_ast.mbt`, `checked_line.mbt`, `schema_registry.mbt` |
| 精確譜理論擴展 | QPoly/QMat、代數數、廣義特徵空間、primary 投影、Jordan 分解 | `algebra/qpoly.mbt`, `algebra/qmat.mbt`, `algebra/algnum.mbt`, `algebra/Jordan.mbt` |
| DAG/認證數值 | BDD manager、預算/DPLL、QuadC 精確投影與多項式填充證書 | `bdd_dag.mbt`, `certified_numeric.mbt` |
| 容器/S³/Jacobi/HOU/模組 | container 巢狀遞迴、懸掛球面、區間酉旋轉證書、pattern HOU elaborator、模組函子與名字空間 | `schema_functor.mbt`, `sphere3.mbt`, `jacobi_interval.mbt`, `hou_elaborator.mbt`, `module_system.mbt` |
| 立方體演算法/單值性 | KanBox、transport、路徑代數、subst/funext、ua/pathToEquiv/uaβ、往返與 Glue 方塊 | `cubical_algorithms.mbt`, `univalence.mbt` |
| 第九期收束 | 完備因式分解/根隔離、層級宣告、DSystem 修復、AlgC、球面同倫代表元、非 Miller HOU、已編譯模組介面 | `algebra/qpoly_factor.mbt`, `schema_phase9.mbt`, `certified_algebraic.mbt`, `sphere_homotopy.mbt`, `module_compilation.mbt` |
| 第十期收束 | 一般 `lemIso`／adjointification、`IntegerS` 與 π₃ 商呈現、有界 Huet、模組 byte codec、BDD/SAT/QPoly 成本控制 | `equivalence_phase10.mbt`, `sphere_classification.mbt`, `hou_elaborator.mbt`, `module_binary.mbt`, `face_sat_watched.mbt`, `algebra/qpoly.mbt` |
| 第十一期收束 | 跨家族函子／同時 IR 編譯、Face 合意與精確修復、lemIso 一般點、CHREGBIN＋hash-consing、圖樣剪枝／雙二次去巢、不透明立方／最佳序／CDCL、圓 encode/decode、模組交錯與 v2 遷移 | `schema_functor.mbt`, `dcube_filler.mbt`, `dterm_intern.mbt`, `schema_registry_persist.mbt`, `algebra/biquad_denest.mbt`, `algebra/poly_cube.mbt`, `circle_classify.mbt`, `phase11_laws.mbt` |
| 第十三期收束 | SelfFamily 正性不動點／foreign 巢狀 IH 函子映射、相關維度下降／最大相容補入、差異導引 Bool 切分／驗證方塊帽、CHDAGBIN 共圖／CHARTCHN 完整性鏈、聯合不可約證書／四生成元多二次塔／自適應 Jacobi、n≤16 精確序／DRUP／Tier D、逆元結合律 3-胞／閉代表式分類、HOU 殘差求解器 | `schema_positivity.mbt`, `dsystem_compat.mbt`, `conv_case_split.mbt`, `dterm_dag_binary.mbt`, `algebra/multiquad_tower.mbt`, `phase13_laws.mbt` |
| 第十二期收束 | 同規格自嵌／正性宣告、同時 IR eliminator 編譯、結構合意與補入、Bool case-split 與路徑值 comp、artifact 儲存庫／DAG codec／版本協商、不可約證書／三次三二次塔／簇感知 Jacobi、子集 DP 序／CDCL 刪除＋RUP、分層外延、單位律 3-胞／精確 Hopf、HOU 三態 MGU | `schema_phase9.mbt`, `schema_positivity.mbt`, `conv_case_split.mbt`, `artifact_repository.mbt`, `algebra/qpoly_certificate.mbt`, `algebra/tower_fields.mbt`, `phase12_laws.mbt` |
| 套件與依賴治理 | `cmd/main → root → algebra`、17 元件、禁止向上邊 | `architecture.json`, `tools/arch_check.py`, `ARCHITECTURE.md` |
| 規格範形登記 | cubical 101 條目＋全倉 5,054 雙語附錄符號＋多套件審計 | `spec.mbt`, `SPEC*.md`, `SPEC-APPENDIX*.md`, `tools/audit_spec.py` |

## 檔案地圖

```text
complex.mbt / projector.mbt   C、向量、矩陣、伴隨；投影與特徵空間分解
interval.mbt / bdd.mbt        De Morgan 區間與面；面公式 ROBDD
system.mbt / system_symbolic.mbt  系統、相容性、剪枝；BDD 區域範形
cube.mbt                      立方體、面限制、開盒 comp、特徵空間剪枝
nbe.mbt / nbe_eta.mbt         βπ NbE＋HOAS；型別化 η NbE 與句法箭頭
wiring.mbt                    有限等價帶號置換範形、冪冪相干律
pathp_glue.mbt                有限宇宙：ua、coe、PathP、Glue、J
glue_comp.mbt                 一般 Glue comp（有限線＋子空間線）
categories.mbt                Karoubi／面偏序／立方體範疇／句法 CCC
nbe_dep.mbt / kan_dep.mbt     Π/Σ/宇宙與立方 AST 依賴 NbE；DLine 的 coe/comp
kan_ast.mbt / ast_laws.mbt    AST 的 comp/hcomp/hfill/coe 按型別化簡與律
schema.mbt / schema_laws.mbt  通用歸納族與 HIT schema 生成器及其律
schema_extensions.mbt / schema_functor.mbt / schema_positivity.mbt
                              函子/正性、互歸納、商、宇宙 scheme、高維 HIT
dsystem_compat.mbt / equiv_ast.mbt / checked_line.mbt / schema_registry.mbt
                              checked 邊界：系統、等價、線、註冊與快取
algebra/{qpoly,qmat,algnum,Jordan}.mbt  精確有理與代數擴張線性代數、Jordan 理論
bdd_dag.mbt / certified_numeric.mbt
                              interned BDD、預算/DPLL、認證數值影子
sphere3.mbt / jacobi_interval.mbt / hou_elaborator.mbt / module_system.mbt
                              S³、認證 Jacobi、HOU elaborator、參數化模組
semantic_system_laws.mbt      DSystem、持久環境、惰性/快取與多分支 Glue 律
algebra/symalg.mbt / algebra/spectral_symbolic.mbt  精確多項式代數；譜投影與仿射恆等
algebra/                      獨立精確代數套件（symalg/qpoly/qmat/algnum/Jordan/spectral/Jacobi）
cubical_algorithms.mbt        KanBox、transport、路徑代數、funext 與 subst
univalence.mbt                有限/AST 計算性單值性與 checked 宇宙路徑
algebra/{qpoly_factor,root_isolation,splitting_field,radical_denest}.mbt
                              完備因式分解、根隔離、分裂域與去巢
schema_phase9.mbt / truncation.mbt / equivalence_phase9.mbt
                              層級/同時宣告、截斷、adjoint 與 fiber 資料
certified_algebraic.mbt / sphere_homotopy.mbt / module_compilation.mbt
                              一般代數認證、球面同倫/Hopf、模組分離編譯
equivalence_phase10.mbt / sphere_classification.mbt
                              一般 lemIso／adjointification；IntegerS、π 商型與環路代表元
module_binary.mbt / face_sat_watched.mbt
                              CHMODBIN v1/v2/v3 codec、遷移與 store；Tseitin CNF、watched DPLL 與 CDCL
dcube_filler.mbt / dterm_intern.mbt / schema_registry_persist.mbt
                              不透明立方開盒、DTerm hash-consing、CHREGBIN 註冊持久化
algebra/{biquad_denest,poly_cube}.mbt / circle_classify.mbt / phase11_laws.mbt
                              雙二次去巢與精確立方；圓的 helix encode/decode；第十一期律束
conv_case_split.mbt / artifact_repository.mbt
                              差異導引 Bool case-split；工件儲存庫與 CHARTCHN 完整性鏈
algebra/{qpoly_certificate,tower_fields}.mbt / phase12_laws.mbt
                              不可約證書、純三次／三二次塔；第十二期律束
algebra/multiquad_tower.mbt / dterm_dag_binary.mbt / phase13_laws.mbt
                              四生成元多二次塔；CHDAGBIN 共圖；第十三期律束
algebra/phase14_algebra.mbt / phase14_laws.mbt / phase15_laws.mbt
                              Hensel 因式分解證書、實代數根式與區塊 Jacobi；第十四／十五期律束
algebra/phase16_algebra.mbt / artifact_crypto_wal.mbt / phase16_laws.mbt
                              LLL／Van Hoeij 與 Q̄⊂ℂ、SHA/Ed25519 與 WAL、第十六期六大工程律束
spec.mbt / verify.mbt         135 條規格登記；124 項定理登記表
*_wbtest.mbt                  跨五聯邦精煉 L8 測試（15 項，含第十六期與健檢回歸）
cmd/main/ , cmd/showcase/     打印 124 項定理登記表與 42 項五聯邦大一統證書的入口
```

## 範圍與邊界

這仍是理論片斷的**可執行模型/規範**，不是完整生產級 cubical 內核。
第十期再補上一般語義 `lemIso`／自動 adjointification、核內整數與
π₃ 商型代表元、有界 Huet 搜尋、版本化模組 byte codec，以及
BDD/SAT/QPoly 的成本控制。但 `lemIso` 的驗收仍是代表元轉換；
π₃ 只分類典範代表元演算，沒有任意元素的合成 encode/decode
同倫群分類或核內 Hopf 不變量。完整 HOU 不可判定，Huet 搜尋的
residual 不表示無解、求得者也不保證 MGU。ROBDD、DPLL 與精確
代數演算法最壞成本仍可爆炸；任意宿主 `Cube` 仍只能抽樣觀察。
模組格式在第十一期已有 v2、v1 遷移與進程內 store，但仍無檔案
系統服務。架構 checker 的元件邊是保守源碼近似，MoonBit
套件圖與 `moon check --deny-warn` 才是硬邊界。第十一期另補：
跨家族巢狀函子與同時 IR 編譯、Face 值合意與精確修復、一般點
lemIso、CHREGBIN＋全域 hash-consing、圖樣剪枝與雙二次去巢
（完備於雙二次片斷）、宿主不透明立方、可證最佳 BDD 序（n≤8）
與 CDCL、圓的 helix 覆疊 encode/decode（複合環路以細分
transport 計算；任意中性環路的完整 π₁(S¹)≃ℤ 仍未內部化）、
Jacobi 簇分離、HOU 深搜尋與模組交錯編排。第十二期再補：同
規格自嵌與同時 IR eliminator 編譯、結構合意與 repair 補入、
Bool case-split 轉換與路徑值合成、抽象工件儲存庫與共用 DAG
codec、不可約證書與三次／三二次塔、簇感知 Jacobi、子集 DP
最佳序與 CDCL 刪除＋RUP、宿主立方分層外延檢查、單位律 3-胞
與精確有理 Hopf、HOU 主合一子三態語意。第十三期再補：
SelfFamily 正性不動點與 foreign 巢狀 IH 函子映射、
DSystem 最大相容補入與相關維度下降、差異導引 case-split
與驗證方塊帽、CHDAGBIN 活/位元組共圖、聯合次數圖樣證書
與四生成元多二次塔、n≤16 精確 BDD 序與 DRUP、Tier D
與自適應 Jacobi、環路逆元/結合律 3-胞及閉代表式分類、
整個殘留約束集的 HOU 求解器，與工件 manifest 完整性鏈。
第十四期補齊聯合 Σ 動機同時 IR、展開正性見證、Hensel 全分解證書與實代數根式、區塊 Jacobi、Eckmann–Hilton 3-胞與五邊形 4-胞、單值 Hopf 不變量、跨約束 HOU 回溯枚舉與認證 CAS／增量同步；第十五期進一步完成對稱軌道剪枝與連通支援分解最佳 ROBDD（28 變量四分量 exact）、索引化線性時間 LRAT 檢查與精化及 `CHLRATBN` v1 編解碼、強度 4 `ℙ¹(𝔽₈)` 覆蓋陣列＋五色 PHF＋`CheckedDCube` 與立方 Yoneda 自然性審計，並在開放變數脈絡下完整內部證明雙向雙射認證 `DVEquiv`、`π₁(S¹) = ‖Ω¹(S¹)‖₀ ≃ ℤ`、基點環路—懸掛伴隨 `(ΣA →* B) ≃ (A →* ΩB)` 及 0-連通 Freudenthal 懸掛定理 `‖Ω¹(Susp A)‖₀ ≃ 1`（`π₁(S²)=π₁(S³)=1`）與圓楔連通；第十六期再完成餘下六大核心工程：大宇宙累積同時 IR、Dybjer–Setzer 開放多解碼器同時 IR 與反循環容器正性憑證，DSATUR 著色上界最大團修復與 `0~1` 黏合圓／環面開盒合成，標準 SHA-256/512、RFC 8032 Pure-Ed25519 非對稱封緘與崩潰一致 WAL 日誌，精確有理 LLL 格約化、Van Hoeij 跡格因式重組與 `Q̄ ⊂ ℂ` Rouché 代數閉包，纖維化環路序列等價、開放變量 Hopf–Freudenthal 收縮 `∂_Hopf(σ_{S²}(p))≡p`、`π₂(S²)` 分裂截面與五維 Stasheff `K₅` 相干胞，以及 Huet 延遲 flex-flex 約束圖、拉取式惰性合一串流、模組 DAG 介面雜湊重連結與基於 LCA 的三方倉庫合併。現行邊界細節見 `SPEC.md` 第四節。
