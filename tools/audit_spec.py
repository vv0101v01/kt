#!/usr/bin/env python3
"""Generate / audit the per-symbol specification appendices.

Parses pkg.generated.mbti (run `moon info` first) for every public
declaration, enum constructor and struct field, classifies each symbol
into a specification family (canonical form / categorification / decision
procedure), and (re)writes the appendix of SPEC.md between the
APPENDIX markers.  --check verifies the appendix is exactly the set of
interface symbols, each listed once, each classified.
"""
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APPENDIX_ZH = ROOT / "SPEC-APPENDIX.md"
APPENDIX_EN = ROOT / "SPEC-APPENDIX.en.md"

FAMILIES = {
    "複數標量": ("(re, im) 有序對", "交換環 C；共軛為對合", "eps 分量比較"),
    "複向量與內積": ("分量列", "Hilbert 空間 Hilb 的物件；內積誘導對偶", "分量運算"),
    "矩陣與伴隨": ("列之列", "Hilb 態射；† 為 dagger 函子", "矩陣運算"),
    "投影與特徵空間": ("Σ vₖvₖ†；分解為正交對 (Pv,(I−P)v)", "自伴冪等態射及其在 Hilb 中的分裂（雙積）", "特徵值方程／正交性／跡整數性"),
    "Karoubi 包絡": ("物件 P；態射被夾緊矩陣 QAP=A", "冪完備化；恒等是 P 本身；dagger", "QAP=A 與合成律"),
    "區間": ("De Morgan 表達式；端點布林化", "De Morgan 代數（區間物件）", "求值與重寫簡化"),
    "面公式與 BDD": ("由 interned DAG 展開的 ROBDD 樹（相容表示）；主判定在同一 manager 以 root 代表", "面格（自由有界分配格的商）的規範代表", "DAG apply/root 相等判定；樹形 API 為逐公式展開"),
    "面偏序範疇": ("BDD 等價類", "偏序範疇：∧積、∨餘積、⊤/⊥ 終始", "bdd_face_le 與萬有性等式"),
    "系統與剪枝": ("分支列；語義範形見系統符號範形", "面上 presheaf 的偏元素；聯集拼接", "重疊面的 BDD 可滿足性"),
    "系統符號範形": ("值標記不交 BDD 分割＋未定義區域", "偏元素在面格切片中的像分解", "BDD 區域運算"),
    "立方體與 Kan 填充": ("函數 Iⁿ→Cᵐ；填充用仿射公式；帽子為 comp 結果", "□ 上 cubical set 的實現；retract 的 Kan 結構", "邊界方程（網格）"),
    "未型別 NbE": ("βπ 正規形 nf", "句法範疇在 βπ 商下的態射代表", "eval/quote 後結構比較"),
    "HOAS": ("經 reify 的 de Bruijn 範形", "函子範疇式綁定；與一階語法範疇等價（模定義相等）", "reflect/reify 往返"),
    "型別化 NbE 與 η": ("η 長 βπ 範形 nf_eta", "自由笛卡兒閉範疇的態射代表", "雙向檢查＋按型別 quote"),
    "依賴型別 NbE（Π/Σ/宇宙）": ("按型別 quote 的 η 長依賴正規形；Π/Σ 第二分量為語義閉包族；累積 Typeᵢ 層級", "帶族範疇 (CwF) 模型：脈絡延伸與依賴代入是閉包施用", "雙向 elaboration＋型別導向轉換；相等=範形相等；項層級另有對離散 Bool 脈絡變量的差異導引 case-split 轉換加強（先比較兩側範形、優先切分實際差異變量，兩分支代入後遞迴判定，含相依型別代入並回報 nodes/probes；Nat 變量不切分），不改變覈心轉換"),
    "立方 AST 與維度 NbE": ("DTerm 的項/維度雙 de Bruijn 索引；線與 tube body；帶 dlevel 的 quote", "帶區間脈絡的 cubical CwF；PathP 為依賴路徑物件，Glue 值為 (raw/DPartial partial,base) 對", "雙向檢查＋Dim/Face 簡化及 ROBDD 語義謂詞"),
    "AST Kan comp/hcomp": ("分支一律攜帶為 DSystem；在一般維度按型別頭派遣；頂分支取帽、形式合成為 DNComp/DNHComp；CircleSquareWindingReport 記錄二維圓方塊四邊繞數與 H-空間黏合狀態", "各型別構造子保存 Kan 纖維化結構；hcompU 是 Glue 黏合；圓 S¹≃K(ℤ,1) 與環面 T²≃S¹×S¹ 的群胚 H-空間乘法把端點 0~1 黏合方塊邊界化約為整數纏繞數二上循環守恆條件", "系統 base/重疊相容＋型別遞迴；Circle/Torus 分支配帽由一般分支值的座標表式代入 1 讀出，二維端點黏合開盒在零淨纏繞時以 H-空間旋轉構造二維填充帽、非零淨纏繞阻礙時明示回傳 None；coe/fill 為 comp 線段限制"),
    "資料型別與 HIT 消去": ("Nat/List 構造子遞迴；Circle loop@r；Torus square@(i,j) 模對邊等同", "初始代數與 HIT 的依賴消去是 motive 截面，並與形式 composition 交換", "構造子模式遞迴、Dim 語義相等、motive 中的 comp"),
    "持久環境、惰性與語義快取": ("帶長度持久連結串列 DEnv/DDimEnv（de Bruijn 頭在最內）；DVThunk 最多強制一次；快取鍵為簡化維度/引文項 Debug 鍵；DTerm 全域 hash-consing 以子項 stamp 自底向上建立 intern 表，結構相等子項共享同一 intern id 而重建後項結構相等；intern 表另存每節點子 ID，DTermDagSnapshot 以 local shell＋child-id 邊輸出同一 DAG，CHDAGBIN v1 以逐節點 hash-cons 匯入並回報 added/reused", "CwF 脈絡延伸是共享尾部的 cons；惰性值是 call-by-need 語義值，memoized 族/維度線是外延函數的有限圖延伸", "環境索引、force_count 與快取鍵相等"),
    "依賴語義系統與 partial 值": ("DSystem 分支去 ⊥、按值合併同 body 並以引文排序；DPartialValue 的 BDD 有效區域分割 DSystemNF", "面格切片中的偏元素；多分支 Glue 為 partial type 系統與 base 的極限式配對", "BDD 區域運算＋分支 body 的型別導向轉換/引文鍵"),
    "通用歸納族 schema": ("telescope＋完整 DTerm 引數型別（外部、直接/巢狀/函數遞迴與約束）；值為 DVIntro，中性消去按生成 case 型別引文", "結構化嚴格正性函子的依賴初始代數；消去子是 motive 截面，comp 沿先前引數 filler 遞迴", "schema 結構相等、telescope elaboration、極性正性判定與生成檢查"),
    "通用 HIT schema": ("任意有限維 cell；任一端點按 face expression 逐維化簡；case 為逐維巢狀 PathP", "帶 face 映射的胞腔型高階初始代數；消去子保存各維 cells", "face 引數/索引檢查、多維角落雙路化簡轉換與維度語義相等"),
    "依賴 Kan 線（coe/comp）": ("DLine{at, coe, fill}，comp=fill(1)；coe 在 Π 定義域反向、在 Σ 沿第一分量路徑", "型別即 Kan 纖維化結構；依賴族為 (路徑)→DLine；與子空間/Glue 線共同覆蓋全型別族", "按型別構造子遞迴；coe(r,r) 定義恆等"),
    "精確符號代數": ("Q 上多變量多項式規範形（合併去零排序）；分式；複符號量 (re,im)", "多項式戒與分式體承載矩陣代數；共軛為對合", "多項式恆等／分式交叉相乘（精確）"),
    "譜投影與仿射唯一填充": ("Pₖ=qₖ(A)/qₖ(λₖ)；雙線性角插值 k00+i k10+j k01+ij k11", "單位分解與譜分解；雙線性是兩仿射方向的張量黏合", "首一整除（模最小多項式）與在原子 i,j 的恆等"),
    "句法笛卡兒閉範疇": ("帶註記閉箭頭，其 nf_eta", "自由 CCC：積與指數的萬有性", "def_eq_eta 驗證範疇律"),
    "有限宇宙型別與值": ("葉序／葉值列", "有限集合範疇中由 Bool/Unit 以積生成", "樹遞迴"),
    "Wiring 符號等價": ("帶號置換（Unit 輸出 /(−1,false)）", "自由對稱冪冪範疇態射；⊗／換位／結合子／單位子", "置換性 O(#葉)；相等=結構相等"),
    "同構、等價、ua、coe": ("wiring；coe 按端點計算", "ua 在有限宇宙；積交換為自然性方塊", "wiring_eq 與 w;w⁻¹=id"),
    "PathP、離散路徑與 J": ("規範 PathP 元（遠端為 coe 像）；離散路徑常值", "依賴路徑物件；J 來自常值線 coe 的恆等性", "端點與點值檢驗"),
    "有限 Glue": ("(partial, base) 對；glue_from_base 由 base 範形", "沿等價黏合的極限式構造；unglue 為纖維化投影", "face_sat＋相容方程"),
    "Glue comp（有限線）": ("輸出 (t₁, e₁(t₁))", "箭頭範疇 Ty²：等價線是其態射，comp 是沿線合成", "自然性方塊 wiring_eq；不相干則拒絕"),
    "Glue comp（子空間線）": ("校正方塊 k=1 邊", "變動 retract 線上的 Kan 提升；校正為 hcomp", "邊界／帽子／落點方程（網格）"),
    "BDD DAG、預算與 DPLL": ("hash-consed DAG 節點 ID；root 的 reachable node count 為 ROBDD 大小；apply cache 於 apply_misses 超過桶數四倍時 doubling rehash；sifting 逐變量試全部插入位置並以 reachable size 衡量 並回報 initial/final/attempts/improved；CNF 以 Tseitin 門變量線性編碼；LRAT 證明步驟為帶顯式傳播提示鏈的 LratAdd/LratDelete 及 CHLRATBN v1 二進位範形", "布林函數在固定變量次序下的共享規範圖；apply 是格運算的 memoized 實現；watched-literal DPLL/CDCL 是面格可滿足性的搜尋判定，DRAT→LRAT 精化則是到帶顯式見證鏈證明範疇的函子提升", "同 manager root-id 相等、root≠0 的 sat、節點預算 FaceDecision、或有步數預算的 DPLL（舊掃描式與 watched-literal）；另有候選變量次序最小化與 3ⁿ 最壞節點界；watched/list DPLL 以 2^n brute force 差分驗證，sifting 以恆等哨兵避免大小同分時誤稱改善；CDCL 在 watched 傳播上加 1-UIP 子句學習、VSIDS 與 Luby 重啟、LBD 子句刪除、DRUP/DRAT 核驗、反向核心裁剪，以及 DRAT→LRAT 精化器與索引化線性時間 LRAT 檢查器；精確最佳變量序結合啟發式上界剪枝、cofactor 對稱軌道剪枝（單連通分量達 n≤20）與變量共現交互圖連通支援分解（獨立支援分量各自精確求解並拼接，單分量超限明示 exact=false）"),
    "原始 DSystem 相容性與 first-match 範形": ("相容系統沿用 DSystem 型別導向範形；任意 first-match 系統化為不交有效區域 DTubeNF；兩值的合意區域同時給出布林 BDD 形與保留雙端點的 Face 值形，exact repair 以 Face 值合意面截斷分支而不動端點；DSystemDsaturCliqueReport 記錄著色上界與最大團枚舉統計", "面相對切片中的偏元素；checked 構造是進入 composition 系統子類的反射；正常著色數 χ(G[P]) 是最大團數 ω(G[P]) 的偶圖上界", "局部脈絡轉換只在分支實際提及的相關維度上枚舉（不相干維度由 BDD cofactor 結構剪去），檢查 base 與兩兩重疊；不相容回報首個衝突；exact repair 除截斷外可依序補入；maximum completion 另先 exact-restrict，再以分支相容圖的最大團或 DSATUR 飽和度著色上界剪枝枚舉全部最大相容子系統並回報 exact"),
    "AST 一等 Equiv 與 GlueEquiv": ("DEquiv 攜帶 fwd/bwd/sect/retr 四項；DVGlueEquiv 攜帶完整 Equiv 分支與 base/partial 對", "AST 內的等價是帶同倫逆證明的同構；ua 是通往宇宙路徑的函子，GlueEquiv 是沿 partial 等價系統的黏合", "雙向檢查四個分量與兩條 PathP 證明；conversion/quote 按 Equiv 分量與分支面遞迴；沿 ua 的 coe 定義地為 fwd/bwd"),
    "受檢查語義型別線": ("DCheckedTypeLine 保存已檢查的開放型別 body、脈絡、環境與宇宙層級，不保存裸宿主函數", "可代換的立方型別線由句法 body 在維度環境下求值，天然與維度代換交換", "構造時以新鮮維度檢查 body : Typeᵢ；at 以維度求值，coe/comp 直接派遣 AST Kan"),
    "Schema 註冊與 elaboration 快取": ("DSchemaRegistry 中以穩定 Debug 鍵 intern 的 DInductivePlan/DHitPlan 與 telescope 前綴鏈；位元組形 CHREGBIN v2＝magic＋版本＋長度＋校驗＋與 CHMODBIN v3 共享的 DAG DTerm/schema codec payload（v1 仍可讀）", "schema 描述子是可共享計劃；快取只保存同一 elaboration 函數的有限圖，不改變指稱", "驗證布爾值與語義 telescope 前綴按 (term,args,args) 鍵查表；hit/miss 計數可觀察"),
    "Schema 函子、正性與歸納遞迴": ("DPositiveFunctor 的 Id/Const/Product/Sum/List/Pi/Container/DecodedFunction/Family/SelfFamily 語法（SelfFamily 為不攜帶規格的同規格自嵌標記，支援 Bush 型非均勻遞迴，參數的 Self 型別由已建立的宿主 Self 型別給出而非佔位）及其解碼型別；DPositivityReport 記錄出現與極性；DFunctorialPositivityCert 承載語義協變律或容器同構憑證", "正性型別函子的初始代數與 decoded induction hypothesis；DDecode 是 Tarski 宇宙的歸納—遞迴解碼函數；多項式容器同構 Equiv(F X, Σs:S.P(s)→X) 給出嚴格正性自函子的反循環語義刻畫", "在別名展開後的 DTerm 上做極性遞迴：巢狀函子與正位置接受、負位置拒絕、未知中性族應用在無宣告時拒絕；不透明中性算子可攜帶受信的 DPositivityDeclaration、λ 驗證版或經核心型別檢查的語義憑證（反循環容器同構授予 strict_args，僅協變律授予非嚴格 positive_args）；IH 由函子遞迴生成"),
    "Schema 擴展：互歸納、商與宇宙多態": ("DMutualFamily 的 Sum-indexed 合併 schema；DLevelExpr 的層級 scheme；商即帶等式 1-cell 的 HIT", "互相歸納族是索引和上的單一初始代數；宇宙 scheme 是層級指派的函數；商構造為高階胞腔黏合", "互構子以分量索引約束編譯並以 Σ motive 消去；scheme 依層級向量求值並可再驗證；構造子等式以 Path 約束檢查"),
    "精確單變量多項式與有理矩陣": ("QPoly 的升冪稠密係數（尾零去除）；QMat 的有理列之列；RREF 與 pivot 列", "Q[x] 歐氏環與 Qⁿ 線性範疇；特徵/最小多項式是矩陣代數的表示不變量", "乘法在稀疏輸入走非零卷積、稠密輸入走公分母 BigInt 整係數縮放（schoolbook/Karatsuba 視項數而定）再除回，冪次走平方乘法；primitive pseudo-remainder gcd、Yun 重因數分解、有理根定理、Faddeev–LeVerrier、RREF；相等全為有理結構相等"),
    "代數擴張與根式範形": ("QuadNum 的 a+b√d（d 無平方因數）；CubicNum 的 a+b∛m+c∛m²（m 無立方因數）；TriquadNum 在三個平方類獨立生成元的 8 維基底；MultiQuadNum 在至多四個生成元的 16 維基底並以平方類 span 對齊；AlgNum 的 Q[x]/(m) 餘式多項式", "二次擴張與一般有限代數擴張體；範數/跡由乘法矩陣行列式/跡給出", "模極小多項式的剩餘算術與擴張歐氏求逆；multiquadratic 逆元以 Galois 共軛乘積、判號以二進區間細化；根式去巢以平方判別；相等為對齊基底後係數相等"),
    "廣義特徵空間與 Jordan 理論": ("(A−λI) 冪次零化列、遞增 nullity、Jordan 塊大小與鏈底基；PJP⁻¹=A", "主分解是互質多項式因子的單位分解；Jordan 型是相似等價的完全不變量片斷", "以特徵多項式重數、冪次核維度與鏈提升精確判定；不可在 Q 完全分裂者回報殘餘因子，AlgMat 在擴張上續行"),
    "認證數值影子與精確立方體": ("QuadC=QuadNum+i·QuadNum；CertMat 與次數≤2 的 CertPath/CertSquare 係數", "精確複二次矩陣代數與多項式立方體；Double 矩陣只是精確影子的近似表示", "P²=P、P†=P、正交分解與盒邊界以精確結構相等驗證；數值一致性只量測對影子的偏差與浮點 residual"),
    "球面與懸掛 HIT": ("一般參數化懸掛 SuspS(A) 的 north/south 兩點與每點 a:A 一條 meridian；S²=Susp(S¹)、S³=Susp(S²)；Susp(Bool)≃S¹、餘錐 Cocone(A,B) 與基點環路—懸掛伴隨 (ΣA→*B)≃(A→*ΩB)", "懸掛是把 A×I 兩端各塌縮為一點的同倫推出 HIT 商，映出態射由餘錐萬有性分類；在基點類型範疇 Type* 中 Σ 與 Ω 構成典範同倫伴隨 Σ⊣Ω", "generic HIT schema 驗證、meridian 端點 face 化簡、依賴消去與 hcomp；0-連通空間的懸掛基本群由 Freudenthal 0-連通定理證為平凡群 ‖Ω¹(Susp(A))‖₀≃1（導出 π₁(S²)≃1 與 π₁(S³)≃1），並具圓楔連通延伸及相干見證"),
    "Jacobi 區間譜迭代": ("RatInterval/CInterval 矩形包絡與 dyadic 外向捨入後的 Hermitian 區間矩陣；每次旋轉保存 before/after 與累積酉變換", "Hermitian 相似變換在區間矩陣包絡上的單調提升；Gershgorin 圓盤給出譜的像分解與重數簇", "精確有理平方比較證明 sqrt/相位/c/s 包絡包含真值；逐旋轉重算 J†J−I∋0 與 J†AJ⊆after，最終圓盤分簇計數；特徵值簇分離以平方自由部分（Sturm 鏈＋與導數 gcd）的 Sturm 區間對原多項式計數回多重數，區間重疊唯一匹配；區間迭代本身具簇感知精化：Gershgorin 簇在迭代內偵測、旋轉以簇懲罰改變 pivot 選擇、精度不足時升級重跑，並在迭代內把 count-2 簇分離為不交單點；自適應驅動在 Jacobi 包絡停滯時切換至精確特徵多項式分離，保留精確重數"),
    "高階合一與雙向 elaborator": ("UTerm 的 Miller pattern spine `?F x₁…xₙ` 與 zonk 後 beta/投影簡化核心；表面 STerm 按名解析為 de Bruijn UTerm；HouSearchReport 記錄 status/nodes/branches/depth；HouDelayedGraphReport 保存 Huet 滯留 flex-flex 約束圖邊，HouLazyUnifierStream 保存拉取式顯式 continuation 堆疊", "pattern HOU 是高階合一的可判定片斷；Huet 預合一範疇以滯留 flex-flex 等式為態射商、惰性串流為搜尋樹的餘代數展開；雙向 elaboration 把隱含引數與 dependent motive 問題送入同一合一器再編譯至依賴覈心", "確定性層以 WHNF 後 rigid 分解、pattern 抽象、occurs/scope 檢查與閉項 fallback 判定；搜尋層在節點與證明項深度預算內求 solved/no-unifier，否則以 residual 或 budget-exceeded 明示未定；支援 Miller pattern 三態 MGU、跨約束殘差求解、Huet 延遲 flex-flex 約束圖自動喚醒與預合一具現，以及拉取式惰性正規形合一子串流"),
    "參數化模組與名字空間": ("模組 telescope（參數→以 ModuleItem 交錯的 imports 與本地宣告；舊 decls-only 建構仍可讀，語義為全部 imports 前置）與分離的 name→ordinal bindings；實例是同時代換後的閉合宣告", "參數化模組是模組函子，import 是函子套用的內聯，open/alias/rename 是同一 telescope entry 的不同名字投影", "循環檢測、參數引數依賴檢查、import 選擇/隱藏/改名的歧義拒絕、opaque export 中性化，以及實例閉合後逐宣告 dep_check"),
    "立方體演算法": (
        "KanBox 打包型別線、系統與 base；transport filler 是 PathP；路徑傳遞是 hcomp 方塊的頂邊；依賴和路徑分裂、纖維化環路等價與五維 Stasheff 結合多面體 K₅ 相干 5-胞",
        "cubical CwF 中由 Kan 纖維化結構生成的路徑物件運算、纖維化環路序列 Ω¹(ΣB P)≃Σ(p:Ω¹B).(subst P p e₀≡e₀) 與 A_∞ 環路空間五重結合的 K₅ 相干胞",
        "派遣至覈心 coe/comp/fill 並以轉換驗證端點；單位律 3-胞、Mac Lane 五邊形 4-胞與 Stasheff K₅ 南北雙五邊形路線間的 5-胞均經轉換核驗；閉項與開放認證等價由依賴檢查器驗收",
    ),
    "計算性單值性（univalence）": (
        "有限宇宙路徑以 wiring 等價為範形；依賴宇宙路徑是受檢查型別線，pathToEquiv 取其 coe 等價，ua 取 Glue 線，uaβ 是 transport filler 的 unglue，往返由 Equiv 同倫與二維 Glue 方塊見證",
        "宇宙路徑範疇與等價之間的等價 (Equiv A B) ≃ Path U A B；Glue 沿等價黏合，transport 是其 coe 函子",
        "有限側以 wiring 相等；AST 側以 coe/comp 計算並以型別導向轉換驗證往返端點與方塊四邊；閉項 pathToEquiv 的 fill/coe 證明由依賴檢查器驗收",
    ),
    "完備精確代數與根隔離": ("BigInt 有理數；Q[x] 不可約因式與重數；精確有理 LLL 約化格基與單模變換 U∈GLₙ(ℤ)；Van Hoeij 冪和跡格重組因式；Sturm 實根區間、不交 Rouché 複圓盤與複代數閉包元素 ComplexAlgNum∈Q̄⊂ℂ；雙二次數與去巢根式表達式", "Q[x] 唯一因式分解、GLₙ(ℤ) 格約化軌道、Frobenius/Hensel 冪和跡約束子格與代數閉包 Q̄⊂ℂ 的複嵌入正向極限", "不可約性證書 fast path、Hensel 提升結合 Fujiwara 根界 Van Hoeij LLL 冪和跡格因式重組（消除 Swinnerton-Dyer 型多項式組合爆炸）與 Kronecker 保底；Sturm 計數、Cauchy/Rouché 圓盤細分與結式消元實作 Q̄⊂ℂ 精確加減乘除、共軛、開方與判等"),
    "一等宇宙多態與同時宣告 schema": ("DLevelDecl 的層級 binders 與實例化；透明算子展開後的正性函子；迭代編譯的非均勻巢狀族；聯合互歸納、跨宇宙累積同時 IR 與 Dybjer–Setzer 多解碼器開放同時 IR DOpenSimultaneousIRSpec", "宇宙 scheme、參數迭代初始代數、累積宇宙 Σ 聯合動機與多切片纖維範疇 Famₘ(Type) 上的開放同步歸納—遞迴初始代數", "層級作用域、正性報告、生成 telescope 與依賴轉換；同時 IR 以 joint_motive_level = maxᵢ function_universe_level(fᵢ) 聯合編譯跨宇宙大/小互賴區塊；開放多解碼器同時 IR 支援驗證、碼檢查、解碼求值、依賴消去與單解碼器核心降階"),
    "Adjoint 等價、纖維與命題截斷": ("quasi-inverse 上加三角形 Path(Path)；improved counit；一般 fiber 的 Σ 點、lemIso 路徑與中心的收縮 (center, contraction)；PropTrunc 的 point/squash HIT；SetTruncS 的 point/hub/spoke 集合截斷 ‖A‖₀ 與開放雙向雙射認證 DVEquiv", "half-adjoint equivalence、contractible fiber 的等價刻畫、到命題與到 h-set（0-群胚）的左伴隨截斷反射", "adjointify_equiv_value、equiv_bidirectional_certified_in 與 equiv_contractible_fibers_value 由 hfill/hcomp/dpath 在開放脈絡構造並以依賴轉換核驗；SetTruncS 具內部 h-set 證書與向任意 h-set 的萬有消去及 ‖X‖₀≃B 等價提升"),
    "球面同倫代表元與 Hopf 不變量": ("Ωⁿ 的巢狀 Path；懸掛迭代的整數度數映射；極交換 S³ 的 HIT；幾何與內部單值 Hopf 纖維叢 H:S²→Type₀ 及全空間 E_Hopf=Σ(x:S²)H(x)；IntegerS 規範整數與內部 h-set 證書；π₂(S²)=‖Ω²(S²)‖₀ 與 π₃ 商呈現", "懸掛函子、纖維化長精確環路序列 Ω¹(E_Hopf)≃Σ(p:Ω¹(S²))Path(S¹,subst H p base,base) 與連接映射在懸掛環路上的 Hopf–Freudenthal 恆等收縮 ∂_Hopf(σ_{S²}(p))≡p", "代表元群律、Ω² Eckmann–Hilton 與五邊形相干胞逐面驗證；Hopf 全空間環路等價經雙向認證，開放自由環路 p:Ω¹(S¹) 上證明 ∂_Hopf(σ_{S²}(p))≡p 並導出開放整數脈絡下 π₂(S²) 到 ℤ 的認證分裂收縮截面"),
    "模組分離編譯與連結": ("CompiledModule 的展平已檢查 telescope、exports、依賴指紋與介面公共投影；CHMODBIN v1–v3／TLV 信封與共享 DAG 項 codec；拓樸建置計畫與增量重連結報告；ArtifactRepository 結合 FIPS 180-4 SHA-256/512、RFC 8032 Pure-Ed25519 CHARTSIG 非對稱封緘、CHWALJRN 預寫式崩潰一致日誌與基於最近共同祖先（LCA）的三方合併報告", "模組函子的已編譯物件、簽章商不變增量重連結、唯讀公鑰驗證態射、預寫式原子提交單子與歷史圖上相對 LCA 的三方推出合併", "介面 hash 忽略 opaque body 實現下游零重編譯並以 module_instantiate 重連結；SHA-256/512 與 RFC 8032 Ed25519 逐位核驗防偽與防延展；CHWALJRN 以 SHA-256 幀校驗回滾未提交交易與斷尾位元組並冪等重放；三方合併支援收斂合併、墓碑傳播與三種衝突策略"),
    "範疇化總檢": ("範疇律的布爾合取", "彙總各範疇的身分／合成／相干律", "逐律求值"),
    "定理登記與範例": ("(名稱, Bool) 登記列；具體見證向量／項", "可判定命題在見證上的實現", "moon test／登記表"),
    "規格登記": ("SpecEntry 六元組", "規格之規格；完備性對產生介面核對", "spec_registry_sound＋本審計"),
    "圓的萬有覆疊與 encode/decode": ("覆疊纖維在 base 是 IntegerS 規範整數、在 loop 點是 ua 線的 GlueEquiv 型別；環路代表元為 schema 圓的 DVHitCell 路徑，繞數為規範整數值；π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ 以認證 DVEquiv 呈現", "helix 是圓到宇宙的纖維化族；encode 是沿環路在覆疊中的 subst 提升端點，decode 是整數消去給出的環路冪；結合 ℤ 為 h-set 與集合截斷萬有性給出基本群同構", "base 纖維以宇宙層轉換等於 ℤ；生成元/逆/refl 及複合環路跨 trans 點的 subst 直接累積繞數；在自由環路與自由整數開放脈絡下內部構造雙向同倫 decode(encode(p))≡p 與 encode(decode(z))≡z，完成 Path S¹ base x ≃ Cover(x)、Ω¹(S¹)≃ℤ 與 π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ 的完整內部證明"),
    "宿主不透明立方與開盒填充": ("立方是宿主函數（維度列→語義值／有理多項式座標）或受型別檢查語法錨定的 CheckedDCube；開盒為缺一面的邊界資料，帽是填充在缺面的限制", "□ 上外部立方資料與 Kan 填充條件的宿主實作，自然變換由立方 Yoneda 引理在通用對角元上唯一決定；多項式立方是精確有理座標系中的立方映射，迭代開盒填充以 F += w·(S − F|face) 逐面修正", "邊界完整性與重疊相容以型別轉換／規範多項式相等逐面驗證；外延比較提供四層分層探針、基於 P¹(𝔽₈) 的強度 t≤4 正交覆蓋陣列與五色完美雜湊族 PHF、揭穿非自然閉包的 Yoneda 自然性與忠實度審計，以及 CheckedDCube 的無探針精確語法讀回判定"),
    "輔助工具": ("整數／網格等具體值", "基礎集合層工具", "直接計算"),
    "下V泛消元新最大公因數（@gcd）": ("F_p 約化列梯形 RREF、ℤ-矩陣 Hermite 與 Smith 範式對角不變因子、首一餘式與多生成元 Bézout 線性組合證書", "交換整環／體上消元帶動的最大下界格結構（整數可除格、F_p[x] 首一多項式格、F_p 子空間模格、ℤ-格對偶零化與主理想和）", "擴張歐氏演算法、F_p 消元核空間對偶正交補、HNF/SNF 單模矩陣分解 U·A·V=D 與維數模律 dim(U∩W)+dim(U+W)=dim U+dim W 核驗"),
    "X形交疊凝聚數學、凝聚高階結構×4、範疇×2與新猜想（@condensed）": ("有限逆系塔滿射轉移矩陣、自由固態模 Z[S]^■、最小 Steenrod A(2) 自由分解、大雙分次譜序列頁、冪等規範化射與雜湊鏈不變量賬本", "凝聚範疇 CondCategory（極端不連通下降與固態化左伴隨反射）、規範消元範疇 CanonElimCategory、凝聚高階同倫棧 CondAnima（Milnor lim¹）、固態與 p-液態模 CondSolidModule、凝聚譜層 CondSpectralSheaf 與 Huber–熱帶雙極解析棧 CondAnalyticStack", "Mittag-Leffler 秩穩定與餘核撓率增長判定、p∈(0,1] 液態次可加性、Adem 關係與 Ext_A^{2,3}(F_2,F_2)=0（證 2η=0）、Čech 扭曲阻礙 k¹−r⁰、SNF 整數守恆律自動推導與四項新猜想實驗核驗"),
    "第七聯邦：多線性超行列式、離散 Radon 變換、Clifford 旋量規範場與 VR 持續同調（@tensor）": ("F_3 全體 6561 個 2×2×2 張量秩與超行列式索引表、有限平面關聯矩陣與 Sherman–Morrison 顯式逆、Jordan–Wigner γ 矩陣與 T² 全純類、非交叉弦遮罩與全維度 VR 單純邊界複形", "SL₂³×S₃ 多線性不變量、有限幾何積分對偶、扭曲群代數辛根中心與離散主叢模空間、非交叉森林 Grothendieck 層景、Kalton–Ostrovskii 對應失真與 Viro–Krasner 熱帶超體", "O(|R₁|²) 精確秩分解 [1,128,5568,864]、仿射修正 Plancherel 能量恆等式、偶奇維旋量中心分裂、[T-NC-Free] 單調自由與 K₄ 反例、同調—上同調轉置秩對偶核驗"),
    "第七聯邦：Lakatos 十二猜想演化圖譜、守恆律自動發現與五大認識論透鏡（@conjecture）": ("觀測軌跡 F_p 零空間成對加減飽和整數基、五謂詞蘊含閉包與最小反例矩陣、五態 Lakatos 猜想生命週期與持久雜湊鏈入賬紀錄", "跨尺度演化守恆律函子 [E-Derive]+[P-Transfer]、相對／對偶／對比／蘊含／比率五大認識論透鏡與七大聯邦 K₇ 完全圖星稜柱大一統", "6 組演化定律自動發現並剔除小規模巧合（含三次至四次平面曲線 Hironaka–Serre 虧格轉移）、5 項天真猜想反例推翻與精煉定理配對、共 12 項跨聯邦猜想（CONJ-01..12）機器核驗"),
}

TYPE_FAMILY = {
    "Complex": "複數標量", "CVec": "複向量與內積", "CMat": "矩陣與伴隨",
    "Dim": "區間", "Face": "面公式與 BDD", "Bdd": "面公式與 BDD",
    "VecBranch": "系統與剪枝", "VecSystem": "系統與剪枝",
    "SymRegion": "系統符號範形", "SystemNF": "系統符號範形",
    "Cube": "立方體與 Kan 填充", "KanBox": "立方體演算法", "UniversePath": "計算性單值性（univalence）",
    "Term": "未型別 NbE", "Neutral": "未型別 NbE", "Value": "未型別 NbE",
    "HTm": "HOAS",
    "LTy": "型別化 NbE 與 η", "TNeutral": "型別化 NbE 與 η",
    "TValue": "型別化 NbE 與 η", "TypedValue": "型別化 NbE 與 η",
    "Ty": "有限宇宙型別與值", "PVal": "有限宇宙型別與值",
    "LeafKind": "Wiring 符號等價", "LeafMap": "Wiring 符號等價", "Wiring": "Wiring 符號等價",
    "Iso": "同構、等價、ua、coe", "Equiv": "同構、等價、ua、coe", "UPath": "同構、等價、ua、coe",
    "PathPVal": "PathP、離散路徑與 J", "DiscPath": "PathP、離散路徑與 J", "Family": "PathP、離散路徑與 J",
    "GlueData": "有限 Glue", "GlueElem": "有限 Glue",
    "GlueLineFinite": "Glue comp（有限線）",
    "SubLine": "Glue comp（子空間線）", "LinEquivLine": "Glue comp（子空間線）",
    "GlueLineVec": "Glue comp（子空間線）", "VecBox": "Glue comp（子空間線）",
    "GlueCompVecResult": "Glue comp（子空間線）",
    "DEnv": "持久環境、惰性與語義快取", "DDimEnv": "持久環境、惰性與語義快取",
    "DThunk": "持久環境、惰性與語義快取",
    "DSystem": "依賴語義系統與 partial 值", "DFaceTerm": "依賴語義系統與 partial 值",
    "DFaceValue": "依賴語義系統與 partial 值", "DPartialValue": "依賴語義系統與 partial 值",
    "DSystemClass": "依賴語義系統與 partial 值", "DSystemNF": "依賴語義系統與 partial 值",
    "DArgKind": "通用歸納族 schema", "DTelescopeEntry": "通用歸納族 schema",
    "DConstructorArg": "通用歸納族 schema", "DConstructorSpec": "通用歸納族 schema",
    "DInductiveSpec": "通用歸納族 schema",
    "DHitFaceExpr": "通用 HIT schema", "DHitCellSpec": "通用 HIT schema", "DHitSpec": "通用 HIT schema",
    "DTerm": "依賴型別 NbE（Π/Σ/宇宙）", "DNeutral": "依賴型別 NbE（Π/Σ/宇宙）",
    "DValue": "依賴型別 NbE（Π/Σ/宇宙）", "DInfer": "依賴型別 NbE（Π/Σ/宇宙）",
    "DTypeVal": "依賴型別 NbE（Π/Σ/宇宙）", "DFamilyParts": "依賴型別 NbE（Π/Σ/宇宙）",
    "DTubeTerm": "立方 AST 與維度 NbE", "DPathParts": "立方 AST 與維度 NbE",
    "DGlueParts": "立方 AST 與維度 NbE", "DTubeBranch": "依賴語義系統與 partial 值",
    "DLine": "依賴 Kan 線（coe/comp）",
    "Rat": "精確符號代數", "PolyTerm": "精確符號代數", "Poly": "精確符號代數",
    "SymFrac": "精確符號代數", "SymC": "精確符號代數", "SymMat": "精確符號代數",
    "UPoly": "精確符號代數", "SymVec": "精確符號代數",
    "RPoly": "譜投影與仿射唯一填充", "RPolyDiv": "譜投影與仿射唯一填充",
    "SymPath": "譜投影與仿射唯一填充", "SymSquare": "譜投影與仿射唯一填充",
    "CheckResult": "定理登記與範例",
    "SpecKind": "規格登記", "SpecEntry": "規格登記",
    "BddApplyEntry": "BDD DAG、預算與 DPLL", "BddBestBuild": "BDD DAG、預算與 DPLL",
    "BddDagFace": "BDD DAG、預算與 DPLL", "BddDagNode": "BDD DAG、預算與 DPLL",
    "BddManager": "BDD DAG、預算與 DPLL", "FaceDecision": "BDD DAG、預算與 DPLL",
    "FaceSatDecision": "BDD DAG、預算與 DPLL",
    "DSystemCompatibility": "原始 DSystem 相容性與 first-match 範形",
    "DSystemIncompatibility": "原始 DSystem 相容性與 first-match 範形",
    "DTubeNF": "原始 DSystem 相容性與 first-match 範形",
    "DTubeNFClass": "原始 DSystem 相容性與 first-match 範形",
    "DEquivBranch": "AST 一等 Equiv 與 GlueEquiv", "DEquivBranchValue": "AST 一等 Equiv 與 GlueEquiv",
    "DEquivParts": "AST 一等 Equiv 與 GlueEquiv", "DEquivTypeParts": "AST 一等 Equiv 與 GlueEquiv",
    "DGlueEquivParts": "AST 一等 Equiv 與 GlueEquiv",
    "DCheckedTypeLine": "受檢查語義型別線",
    "DHitPlan": "Schema 註冊與 elaboration 快取", "DInductivePlan": "Schema 註冊與 elaboration 快取",
    "DSchemaRegistry": "Schema 註冊與 elaboration 快取", "DTelescopeCacheEntry": "Schema 註冊與 elaboration 快取",
    "DPositiveFunctor": "Schema 函子、正性與歸納遞迴", "DPositivityReport": "Schema 函子、正性與歸納遞迴",
    "DConstructorConstraint": "Schema 擴展：互歸納、商與宇宙多態",
    "DHitLevelScheme": "Schema 擴展：互歸納、商與宇宙多態",
    "DInductiveLevelScheme": "Schema 擴展：互歸納、商與宇宙多態",
    "DLevelExpr": "Schema 擴展：互歸納、商與宇宙多態", "DMutualFamily": "Schema 擴展：互歸納、商與宇宙多態",
    "QPoly": "精確單變量多項式與有理矩陣", "QMat": "精確單變量多項式與有理矩陣",
    "QVec": "精確單變量多項式與有理矩陣", "QPolyDiv": "精確單變量多項式與有理矩陣",
    "QPolyExtGcd": "精確單變量多項式與有理矩陣", "QPolyFactor": "精確單變量多項式與有理矩陣",
    "QPolyRationalFactorization": "精確單變量多項式與有理矩陣", "QRref": "精確單變量多項式與有理矩陣",
    "QuadNum": "代數擴張與根式範形", "AlgNum": "代數擴張與根式範形",
    "AlgGeneralizedEigenspace": "廣義特徵空間與 Jordan 理論", "AlgJordanDecomposition": "廣義特徵空間與 Jordan 理論",
    "AlgMat": "廣義特徵空間與 Jordan 理論", "AlgRref": "廣義特徵空間與 Jordan 理論", "AlgVec": "廣義特徵空間與 Jordan 理論",
    "QGeneralizedEigenspace": "廣義特徵空間與 Jordan 理論", "QJordanDecomposition": "廣義特徵空間與 Jordan 理論",
    "QPrimaryProjector": "廣義特徵空間與 Jordan 理論", "QRationalSpectrum": "廣義特徵空間與 Jordan 理論",
    "CertMat": "認證數值影子與精確立方體", "CertVec": "認證數值影子與精確立方體",
    "CertPath": "認證數值影子與精確立方體", "CertSquare": "認證數值影子與精確立方體",
    "QuadC": "認證數值影子與精確立方體", "ProjectorCertificate": "認證數值影子與精確立方體",
    "NumericProjectorCertificate": "認證數值影子與精確立方體",
    "RatInterval": "Jacobi 區間譜迭代", "CInterval": "Jacobi 區間譜迭代",
    "QCpx": "Jacobi 區間譜迭代", "QCpxMat": "Jacobi 區間譜迭代",
    "QCIntervalMat": "Jacobi 區間譜迭代", "JacobiCoefficients": "Jacobi 區間譜迭代",
    "JacobiRotationCertificate": "Jacobi 區間譜迭代", "JacobiCertificate": "Jacobi 區間譜迭代",
    "EigenInterval": "Jacobi 區間譜迭代",
    "UTerm": "高階合一與雙向 elaborator", "UMetaInfo": "高階合一與雙向 elaborator",
    "Unifier": "高階合一與雙向 elaborator", "STerm": "高階合一與雙向 elaborator",
    "ElabVar": "高階合一與雙向 elaborator", "Elaborator": "高階合一與雙向 elaborator",
    "ElabResult": "高階合一與雙向 elaborator",
    "ModuleRename": "參數化模組與名字空間", "ModuleImport": "參數化模組與名字空間",
    "ModuleDecl": "參數化模組與名字空間", "ModuleDef": "參數化模組與名字空間",
    "ModuleEnv": "參數化模組與名字空間", "ModuleEntry": "參數化模組與名字空間",
    "ModuleBinding": "參數化模組與名字空間", "ModuleExport": "參數化模組與名字空間",
    "ModuleSignature": "參數化模組與名字空間", "ModuleInstanceDecl": "參數化模組與名字空間",
    "ModuleInstance": "參數化模組與名字空間",
    "CubicNum": "代數擴張與根式範形", "TriquadNum": "代數擴張與根式範形",
    "JacobiClusterAwareReport": "Jacobi 區間譜迭代",
    "QPolyIrreducibilityCertificate": "完備精確代數與根隔離",
    "ArtifactByteStore": "模組分離編譯與連結", "ArtifactRecord": "模組分離編譯與連結",
    "ArtifactRepository": "模組分離編譯與連結", "ArtifactRepositoryStats": "模組分離編譯與連結",
    "BinaryVersionPolicy": "模組分離編譯與連結",
    "DCubeStratifiedReport": "宿主不透明立方與開盒填充",
    "DPositivityDeclaration": "Schema 函子、正性與歸納遞迴",
    "DSystemRepairSupplemented": "原始 DSystem 相容性與 first-match 範形",
    "FaceCdclProofResult": "BDD DAG、預算與 DPLL",
    "HouConstraint": "高階合一與雙向 elaborator", "HouMguReport": "高階合一與雙向 elaborator",
    "HouMguStatus": "高階合一與雙向 elaborator",
    "CertEnclosure": "完備精確代數與根隔離",
    "EIrrCertificate": "完備精確代數與根隔離",
    "RefutationResult": "完備精確代數與根隔離",
    "HotLoadDecision": "模組分離編譯與連結",
    "HotLoadRecord": "模組分離編譯與連結",
    "HotLoadReport": "模組分離編譯與連結",
    "HotLoadEnv": "模組分離編譯與連結",
    "StoreOp": "模組分離編譯與連結",
    "Recovery": "模組分離編譯與連結",
    "DiskState": "模組分離編譯與連結",
    "HouMatchResult": "高階合一與雙向 elaborator",
    "Paren": "立方體演算法",
    "Stree": "立方體演算法",
    "Origin": "立方體演算法",
    "FgAb": "立方體演算法",
    "FreuStatus": "立方體演算法",
    "BrunerieNorm": "立方體演算法",
    "BrunerieNumber": "立方體演算法",
    "LiouvilleTranscendenceCert": "完備精確代數與根隔離",
    "SchanuelRankWitness": "完備精確代數與根隔離",
    "BerkowitzCrtReport": "精確單變量多項式與有理矩陣",
    "BftReplicaVote": "模組分離編譯與連結",
    "BftQuorumCommit": "模組分離編譯與連結",
    "BftDurableCluster": "模組分離編譯與連結",
    "BftEd25519WalReport": "模組分離編譯與連結",
    "HotLoadMvccSnapshot": "模組分離編譯與連結",
    "HotLoadMvccStore": "模組分離編譯與連結",
    "CantorOrdinal": "Schema 函子、正性與歸納遞迴",
    "IndexedContainerSpec": "Schema 函子、正性與歸納遞迴",
    "MahloReflectionCert": "一等宇宙多態與同時宣告 schema",
    "SheafPartitionConvReport": "依賴型別 NbE（Π/Σ/宇宙）",
    "KernelizedCliqueReport": "原始 DSystem 相容性與 first-match 範形",
    "WedgeSquareFillerReport": "AST Kan comp/hcomp",
    "BddFrontierBuild": "BDD DAG、預算與 DPLL",
    "GoldfarbDiophantineReport": "高階合一與雙向 elaborator",
}

EXACT = {
    "circle_cover_value": "圓的萬有覆疊與 encode/decode", "circle_encode_value": "圓的萬有覆疊與 encode/decode",
    "circle_encode_pieces_value": "圓的萬有覆疊與 encode/decode", "circle_decode_value": "圓的萬有覆疊與 encode/decode",
    "circle_loop_space_type_value": "圓的萬有覆疊與 encode/decode", "circle_hit_type_value": "圓的萬有覆疊與 encode/decode",
    "integer_succ_equiv_value": "圓的萬有覆疊與 encode/decode",
    "code_interpretation_ir": "一等宇宙多態與同時宣告 schema",
    "dterm_rebuild": "持久環境、惰性與語義快取",
    "dterm_distinct_subterm_count": "持久環境、惰性與語義快取",
    "dterm_tree_node_count": "持久環境、惰性與語義快取",
    "bool_ops_module": "參數化模組與名字空間", "generic_iterate_module": "參數化模組與名字空間",
    "container_tree_schema": "Schema 函子、正性與歸納遞迴",
    "as_equiv_type": "AST 一等 Equiv 與 GlueEquiv", "as_glue_equiv": "AST 一等 Equiv 與 GlueEquiv",
    "bool_not_equiv_term": "AST 一等 Equiv 與 GlueEquiv", "bool_not_term": "AST 一等 Equiv 與 GlueEquiv",
    "comp_equiv_value": "AST 一等 Equiv 與 GlueEquiv", "comp_glue_equiv_value": "AST 一等 Equiv 與 GlueEquiv",
    "d_check_glue_equiv_partial": "AST 一等 Equiv 與 GlueEquiv", "d_equiv_branch": "AST 一等 Equiv 與 GlueEquiv",
    "dequiv_branch_value": "AST 一等 Equiv 與 GlueEquiv", "mk_equiv_term": "AST 一等 Equiv 與 GlueEquiv",
    "conv_at_under_face": "原始 DSystem 相容性與 first-match 範形",
    "binary_negotiate_version": "模組分離編譯與連結",
    "dterm_dim_vars": "立方 AST 與維度 NbE",
    "tube_paths_conv_under_face": "原始 DSystem 相容性與 first-match 範形",
    "default_schema_registry": "Schema 註冊與 elaboration 快取",
    "dterm_children": "Schema 函子、正性與歸納遞迴", "dterm_shift": "Schema 函子、正性與歸納遞迴",
    "dterm_substitute": "Schema 函子、正性與歸納遞迴", "conv_schema_args_full": "Schema 函子、正性與歸納遞迴",
    "decode_term": "Schema 函子、正性與歸納遞迴", "infer_decode": "Schema 函子、正性與歸納遞迴",
    "conv_decode_neutral": "Schema 函子、正性與歸納遞迴", "comp_schema_args_decoded": "Schema 函子、正性與歸納遞迴",
    "circle_level_scheme": "Schema 擴展：互歸納、商與宇宙多態", "list_level_scheme": "Schema 擴展：互歸納、商與宇宙多態",
    "cube3_schema": "Schema 擴展：互歸納、商與宇宙多態", "equal_nat_pair_schema": "Schema 擴展：互歸納、商與宇宙多態",
    "even_odd_components": "Schema 擴展：互歸納、商與宇宙多態", "even_odd_family": "Schema 擴展：互歸納、商與宇宙多態",
    "tree_forest_components": "Schema 擴展：互歸納、商與宇宙多態", "tree_forest_family": "Schema 擴展：互歸納、商與宇宙多態",
    "rose_tree_schema": "Schema 擴展：互歸納、商與宇宙多態", "tarski_universe_schema": "Schema 擴展：互歸納、商與宇宙多態",
    "quotient_eq_term": "Schema 擴展：互歸納、商與宇宙多態", "quotient_point_term": "Schema 擴展：互歸納、商與宇宙多態",
    "quotient_schema": "Schema 擴展：互歸納、商與宇宙多態",
    "int_sqrt_exact": "代數擴張與根式範形", "int_squarefree_decomp": "代數擴張與根式範形",
    "double_dyadic_interval": "認證數值影子與精確立方體",
    "eps": "複數標量",
    "outer": "投影與特徵空間", "outer2": "Glue comp（子空間線）",
    "assignment_of_mask": "面公式與 BDD", "pow2": "面公式與 BDD",
    "vec_box": "Glue comp（子空間線）", "vec_lex_lt": "系統符號範形",
    "vec_normalize": "Glue comp（子空間線）",
    "vec_e3": "定理登記與範例", "grid": "定理登記與範例",
    "inv_sqrt2": "定理登記與範例", "example_unit": "定理登記與範例",
    "example_projector": "定理登記與範例", "sample_vectors": "定理登記與範例",
    "sample_terms": "定理登記與範例",
    "disc_samples": "PathP、離散路徑與 J",
    "tm_id": "未型別 NbE", "tm_const": "未型別 NbE", "tm_swap": "未型別 NbE",
    "coe_rules_definitional": "未型別 NbE", "swap_involutive_on_element": "未型別 NbE",
    "cube_in_subline": "Glue comp（子空間線）",
    "prune_cube_subline": "Glue comp（子空間線）",
    "int_pow": "輔助工具", "sort_ints": "面公式與 BDD", "contains_int": "面公式與 BDD",
    "dmin": "區間", "dmax": "區間",
    "check_categories_all": "範疇化總檢",
    "spec_registry_sound": "規格登記",
    "deval": "依賴型別 NbE（Π/Σ/宇宙）", "d_infer": "依賴型別 NbE（Π/Σ/宇宙）",
    "d_check": "依賴型別 NbE（Π/Σ/宇宙）", "d_as_type": "依賴型別 NbE（Π/Σ/宇宙）",
    "dapp_typed": "依賴型別 NbE（Π/Σ/宇宙）", "dfst_typed": "依賴型別 NbE（Π/Σ/宇宙）",
    "dsnd_typed": "依賴型別 NbE（Π/Σ/宇宙）", "as_pi": "依賴型別 NbE（Π/Σ/宇宙）",
    "as_sigma": "依賴型別 NbE（Π/Σ/宇宙）", "as_univ_level": "依賴型別 NbE（Π/Σ/宇宙）",
    "conv_at": "依賴型別 NbE（Π/Σ/宇宙）", "conv_ty": "依賴型別 NbE（Π/Σ/宇宙）",
    "conv_neutral": "依賴型別 NbE（Π/Σ/宇宙）", "quote_at": "依賴型別 NbE（Π/Σ/宇宙）",
    "quote_ty": "依賴型別 NbE（Π/Σ/宇宙）", "quote_dneutral": "依賴型別 NbE（Π/Σ/宇宙）",
    "dep_type_val_of": "依賴型別 NbE（Π/Σ/宇宙）", "lty_to_dterm": "依賴型別 NbE（Π/Σ/宇宙）",
    "as_path": "立方 AST 與維度 NbE", "as_glue": "立方 AST 與維度 NbE",
    "as_list_elem": "立方 AST 與維度 NbE", "d_tube": "立方 AST 與維度 NbE",
    "fresh_dim": "立方 AST 與維度 NbE", "deval_dim": "立方 AST 與維度 NbE",
    "eval_dim_expr": "立方 AST 與維度 NbE", "eval_tube_terms": "立方 AST 與維度 NbE",
    "dim_quote": "立方 AST 與維度 NbE", "face_eval_env": "立方 AST 與維度 NbE",
    "face_quote": "立方 AST 與維度 NbE", "quote_tube_branches": "立方 AST 與維度 NbE",
    "dapp_dim": "立方 AST 與維度 NbE", "dep_def_eq_closed": "立方 AST 與維度 NbE",
    "dim_vars_of": "AST Kan comp/hcomp", "dim_nvars_sem": "AST Kan comp/hcomp",
    "dim_eq_sem": "AST Kan comp/hcomp", "face_nvars_sem": "AST Kan comp/hcomp",
    "face_is_top_sem": "AST Kan comp/hcomp", "face_is_bot_sem": "AST Kan comp/hcomp",
    "face_is_sat_sem": "AST Kan comp/hcomp", "tube_branch": "依賴語義系統與 partial 值",
    "map_branches": "依賴語義系統與 partial 值", "comp_value": "AST Kan comp/hcomp",
    "hcomp_value": "AST Kan comp/hcomp", "fill_value": "AST Kan comp/hcomp",
    "hfill_value": "AST Kan comp/hcomp", "coe_value": "AST Kan comp/hcomp",
    "comp_pi_value": "AST Kan comp/hcomp", "comp_sigma_value": "AST Kan comp/hcomp",
    "comp_path_value": "AST Kan comp/hcomp", "comp_glue_value": "AST Kan comp/hcomp",
    "comp_univ_value": "AST Kan comp/hcomp", "hcomp_univ_value": "AST Kan comp/hcomp",
    "circle_point": "資料型別與 HIT 消去", "torus_point": "資料型別與 HIT 消去",
    "circle_dim_of": "資料型別與 HIT 消去", "torus_dims_of": "資料型別與 HIT 消去",
    "d_nat_lit": "資料型別與 HIT 消去", "dv_nat_lit": "資料型別與 HIT 消去",
    "eval_bool_elim": "資料型別與 HIT 消去", "eval_nat_elim": "資料型別與 HIT 消去", "eval_list_elim": "資料型別與 HIT 消去",
    "eval_circle_elim": "資料型別與 HIT 消去", "eval_torus_elim": "資料型別與 HIT 消去",
    "comp_bool_value": "資料型別與 HIT 消去", "comp_nat_value": "資料型別與 HIT 消去",
    "comp_list_value": "資料型別與 HIT 消去", "comp_circle_value": "資料型別與 HIT 消去",
    "comp_torus_value": "資料型別與 HIT 消去",
    "quote_eta": "型別化 NbE 與 η", "quote_tneutral": "型別化 NbE 與 η",
    "nf_eta": "型別化 NbE 與 η", "def_eq_eta": "型別化 NbE 與 η",
    "sym_affine_path": "譜投影與仿射唯一填充", "sym_square_fill": "譜投影與仿射唯一填充",
    "sym_bilinear_from_corners": "譜投影與仿射唯一填充", "sym_bilinear_ansatz": "譜投影與仿射唯一填充",
    "sym_frac_one_minus": "譜投影與仿射唯一填充", "sym_hermitian2": "譜投影與仿射唯一填充",
    "d_face_term": "依賴語義系統與 partial 值", "dface_value": "依賴語義系統與 partial 值",
    "glue_partial_values": "依賴語義系統與 partial 值", "glue_store_partial": "依賴語義系統與 partial 值",
    "dim_cache_key": "持久環境、惰性與語義快取",
    "check_telescope_terms": "通用歸納族 schema", "telescope_type_values": "通用歸納族 schema",
    "conv_telescope_values": "通用歸納族 schema", "quote_telescope_values": "通用歸納族 schema",
    "conv_schema_args": "通用歸納族 schema", "quote_schema_args": "通用歸納族 schema",
    "schema_motives_conv": "通用歸納族 schema", "quote_schema_motive": "通用歸納族 schema",
    "comp_schema_args": "通用歸納族 schema", "comp_inductive_value": "通用歸納族 schema",
    "eval_inductive_elim": "通用歸納族 schema", "eval_inductive_elim_term": "通用歸納族 schema",
    "eval_inductive_type_term": "通用歸納族 schema", "eval_intro_term": "通用歸納族 schema",
    "infer_inductive_elim": "通用歸納族 schema", "infer_inductive_type": "通用歸納族 schema",
    "infer_intro": "通用歸納族 schema", "conv_inductive_elim_neutral": "通用歸納族 schema",
    "conv_inductive_type": "通用歸納族 schema", "conv_intro_at": "通用歸納族 schema",
    "quote_inductive_elim_neutral": "通用歸納族 schema",
    "quote_inductive_type": "通用歸納族 schema", "quote_intro_at": "通用歸納族 schema",
    "nat_schema": "通用歸納族 schema", "bool_schema": "通用歸納族 schema",
    "list_schema": "通用歸納族 schema", "vec_schema": "通用歸納族 schema",
    "fin_schema": "通用歸納族 schema", "tree_schema": "通用歸納族 schema", "w_schema": "通用歸納族 schema",
    "nat_schema_lit": "通用歸納族 schema",
    "eval_hit_elim": "通用 HIT schema", "eval_hit_elim_term": "通用 HIT schema",
    "eval_hit_intro_term": "通用 HIT schema", "eval_hit_type_term": "通用 HIT schema",
    "infer_hit_elim": "通用 HIT schema", "infer_hit_intro": "通用 HIT schema", "infer_hit_type": "通用 HIT schema",
    "conv_hit_cell_at": "通用 HIT schema", "conv_hit_elim_neutral": "通用 HIT schema",
    "conv_hit_type": "通用 HIT schema", "quote_hit_cell_at": "通用 HIT schema",
    "quote_hit_elim_neutral": "通用 HIT schema", "quote_hit_type": "通用 HIT schema",
    "comp_hit_value": "通用 HIT schema", "circle_schema": "通用 HIT schema",
    "segment_schema": "通用 HIT schema", "torus_schema": "通用 HIT schema",
}


TYPE_FAMILY.update({
    "AlgPoly": "完備精確代數與根隔離", "AlgPolyDiv": "完備精確代數與根隔離",
    "AlgPolyFactor": "完備精確代數與根隔離", "ComplexDisk": "完備精確代數與根隔離",
    "ComplexRootIsolation": "完備精確代數與根隔離",
    "QPolyCompleteFactorization": "完備精確代數與根隔離",
    "RadicalExpr": "完備精確代數與根隔離", "RealRootIsolation": "完備精確代數與根隔離",
    "SplittingField": "完備精確代數與根隔離", "SplittingRoot": "完備精確代數與根隔離",
    "DLevelDecl": "一等宇宙多態與同時宣告 schema",
    "DLevelHitDecl": "一等宇宙多態與同時宣告 schema",
    "DLevelInductiveDecl": "一等宇宙多態與同時宣告 schema",
    "DLevelTermDecl": "一等宇宙多態與同時宣告 schema",
    "DLevelTermInstance": "一等宇宙多態與同時宣告 schema",
    "DMutualDecl": "一等宇宙多態與同時宣告 schema",
    "DMutualPositivityReport": "一等宇宙多態與同時宣告 schema",
    "DNestedArg": "一等宇宙多態與同時宣告 schema",
    "DNestedConstructor": "一等宇宙多態與同時宣告 schema",
    "DNestedIterDecl": "一等宇宙多態與同時宣告 schema",
    "DNestedIterFamily": "一等宇宙多態與同時宣告 schema",
    "DSimultaneousFunction": "一等宇宙多態與同時宣告 schema",
    "DSimultaneousIRSpec": "一等宇宙多態與同時宣告 schema",
    "DTypeOperatorDecl": "一等宇宙多態與同時宣告 schema",
    "DFaceConvReport": "原始 DSystem 相容性與 first-match 範形",
    "DSystemRepair": "原始 DSystem 相容性與 first-match 範形",
    "DSchemaRegistrySnapshot": "Schema 註冊與 elaboration 快取",
    "DAdjointEquivParts": "Adjoint 等價、纖維與命題截斷",
    "AlgC": "認證數值影子與精確立方體",
    "AlgCertMat": "認證數值影子與精確立方體",
    "AlgCertPath": "認證數值影子與精確立方體",
    "AlgCertSquare": "認證數值影子與精確立方體",
    "AlgCertVec": "認證數值影子與精確立方體",
    "CompiledModule": "模組分離編譯與連結",
    "CompiledModuleEnv": "模組分離編譯與連結",
    "ModuleCompileCache": "模組分離編譯與連結",
    "ModuleCompileCacheEntry": "模組分離編譯與連結",
    "ModuleDependencyFingerprint": "模組分離編譯與連結",
    "BddOptimizedBuild": "BDD DAG、預算與 DPLL",
    "FaceBoolExpr": "BDD DAG、預算與 DPLL",
    "FaceCnfStats": "BDD DAG、預算與 DPLL",
    "HouSearchReport": "高階合一與雙向 elaborator",
    "HouSearchStatus": "高階合一與雙向 elaborator",
    "ModuleBinaryLoad": "模組分離編譯與連結",
    "ModuleBinaryStatus": "模組分離編譯與連結",
    "SphereLoopExpr": "球面同倫代表元與 Hopf 不變量",
})

for _name in [
    "qpoly_factor_complete", "qpoly_factor_complete_with_budget",
    "qpoly_complete_factorization_expand", "qpoly_is_irreducible",
    "qpoly_sturm_sequence", "qpoly_sturm_variations", "qpoly_real_root_count",
    "qpoly_isolate_real_roots", "qpoly_isolate_complex_roots",
    "qpoly_splitting_field", "qmat_symmetric_eigenvalue_isolations",
    "qcpx_hermitian_charpoly", "qcpx_hermitian_eigenvalue_isolations",
]:
    EXACT[_name] = "完備精確代數與根隔離"
for _name in [
    "dterm_instantiate_levels", "dterm_levels_in_scope", "dlevel_expr_in_scope",
    "extract_positive_functor", "darg_nested_from_type",
    "eval_simultaneous_ir", "circle_level_decl", "list_level_decl",
    "compile_nested_iter_decl", "nat_parity_double_ir",
]:
    EXACT[_name] = "一等宇宙多態與同時宣告 schema"
for _name in [
    "equiv_triangle_type", "equiv_improved_sect_value",
    "equiv_with_improved_sect", "equiv_fiber_center_value",
    "is_contr_type_term", "fiber_type_term", "contractible_fibers_type_term",
    "identity_fibers_contractible_value", "singleton_contraction_value",
]:
    EXACT[_name] = "Adjoint 等價、纖維與命題截斷"
for _name in [
    "loop_space_type_term", "based_map_type_term", "iterated_refl_term",
    "sphere_degree_value", "sphere_degree_function_value",
    "sphere3_swapped_schema", "sphere3_swapped_type_term",
    "sphere3_swapped_north_value", "sphere3_swapped_south_value",
    "sphere3_swapped_meridian_value", "sphere3_to_swapped_value",
    "sphere3_from_swapped_value", "sphere3_swapped_retr_value",
    "sphere3_swapped_sect_value", "sphere3_swapped_equiv_value",
    "suspension_map_value", "suspension_meridian_path_value",
    "suspension_unit_loop_value",
]:
    EXACT[_name] = "球面同倫代表元與 Hopf 不變量"
for _name in ["cube_root_two_modulus", "cube_root_unit_vector"]:
    EXACT[_name] = "認證數值影子與精確立方體"
for _name in [
    "module_decl_abstract", "module_compile", "module_compile_with_compiled",
    "module_link_signature", "module_link_instantiate",
    "module_source_fingerprint", "module_compile_cache_new",
    "module_compile_cache_size", "module_compile_cache_lookup",
    "module_compile_cached", "module_dependency_fingerprint",
    "module_dependency_of_compiled", "abstract_point_module",
    "point_implementation_module", "point_client_module",
]:
    EXACT[_name] = "模組分離編譯與連結"

for _name in [
    "adjointify_equiv_value", "equiv_fiber_type_value",
    "equiv_fiber_path_value", "equiv_fiber_contraction_value",
    "equiv_contractible_fibers_value",
]:
    EXACT[_name] = "Adjoint 等價、纖維與命題截斷"
for _name in [
    "face_sat_watched_dpll", "face_eq_watched_dpll", "face_cnf_stats",
]:
    EXACT[_name] = "BDD DAG、預算與 DPLL"
EXACT.update({
    "face_cdcl_drup_check": "BDD DAG、預算與 DPLL",
    "face_cdcl_drat_check": "BDD DAG、預算與 DPLL",
    "face_cdcl_drup_trim": "BDD DAG、預算與 DPLL",
    "dsystem_repair_maximum": "原始 DSystem 相容性與 first-match 範形",
    "dsystem_repair_all_maxima": "原始 DSystem 相容性與 first-match 範形",
    "conv_difference_variables": "依賴型別 NbE（Π/Σ/宇宙）",
    "cs_finite_closed_inhabitants": "依賴型別 NbE（Π/Σ/宇宙）",
    "circle_encode_decode_sect_value": "圓的萬有覆疊與 encode/decode",
    "circle_self_loop_value": "球面同倫代表元與 Hopf 不變量",
    "circle_rot_equiv_value": "球面同倫代表元與 Hopf 不變量",
    "shared_dag_bundle_to_binary": "模組分離編譯與連結",
    "shared_dag_bundle_load_binary_report": "模組分離編譯與連結",
    "qpoly_factor_hensel": "完備精確代數與根隔離",
    "qpoly_factor_certified": "完備精確代數與根隔離",
    "qpoly_factor_certificate_check": "完備精確代數與根隔離",
    "qpoly_irreducible_upto3": "完備精確代數與根隔離",
    "sphere_loop_canonical_expr": "球面同倫代表元與 Hopf 不變量",
    "sphere_loop_canonical_value": "球面同倫代表元與 Hopf 不變量",
    "sphere_loop_expr_normal_form": "球面同倫代表元與 Hopf 不變量",
    "sphere_loop_expr_normalize3_value": "球面同倫代表元與 Hopf 不變量",
    "sphere_loop_expr_same_class": "球面同倫代表元與 Hopf 不變量",
})

for _name in [
    "integer_schema", "integer_type_term", "integer_type_value",
    "integer_term", "integer_value", "integer_pred_value",
    "integer_succ_value", "homotopy_group_type_term",
    "pi3_sphere_type_term", "pi3_sphere_point_term",
    "iterated_refl_value", "loop_space_type_value",
    "sphere_type_term", "sphere_type_value", "sphere_north_term",
    "sphere_north_value", "suspend_loop_value",
    "sphere_loop_power_value", "sphere_loop_expr_degree",
    "sphere_loop_expr_of_integer", "sphere_loop_compose_value",
    "sphere_loop_expr_value", "dpath_trans_sym_cancel_value",
]:
    EXACT[_name] = "球面同倫代表元與 Hopf 不變量"

TYPE_FAMILY.update({
    "BiquadNum": "完備精確代數與根隔離", "JacobiClusterSeparation": "Jacobi 區間譜迭代",
    "SeparatedEigenInterval": "Jacobi 區間譜迭代", "QPolyDegreePattern": "完備精確代數與根隔離",
    "PolyBoxFace": "宿主不透明立方與開盒填充", "PolyCube": "宿主不透明立方與開盒填充", "PolyOpenBox": "宿主不透明立方與開盒填充",
    "BddOptimalBuild": "BDD DAG、預算與 DPLL",
    "CompiledModuleStore": "模組分離編譯與連結", "CompiledModuleStoreStats": "模組分離編譯與連結",
    "DCubeBoxFace": "宿主不透明立方與開盒填充", "DCubeBoxReport": "宿主不透明立方與開盒填充",
    "DCubeFunction": "宿主不透明立方與開盒填充", "DCubeOpenBox": "宿主不透明立方與開盒填充",
    "DFunctorParamArg": "Schema 函子、正性與歸納遞迴",
    "DSchemaRegistryBinaryLoad": "Schema 註冊與 elaboration 快取",
    "DSystemRepairExact": "原始 DSystem 相容性與 first-match 範形",
    "DTermInternTable": "持久環境、惰性與語義快取",
    "FaceCdclResult": "BDD DAG、預算與 DPLL", "FaceCdclStats": "BDD DAG、預算與 DPLL",
    "HouIterativeReport": "高階合一與雙向 elaborator",
    "ModuleItem": "參數化模組與名字空間",
    "MultiQuadNum": "代數擴張與根式範形",
    "JacobiAdaptiveReport": "Jacobi 區間譜迭代",
    "ArtifactChainEntry": "模組分離編譯與連結",
    "ArtifactChainReport": "模組分離編譯與連結",
    "CaseSplitReport": "依賴型別 NbE（Π/Σ/宇宙）",
    "DSystemRepairMaximum": "原始 DSystem 相容性與 first-match 範形",
    "DTermDagBinaryLoad": "持久環境、惰性與語義快取",
    "DTermDagImportReport": "持久環境、惰性與語義快取",
    "DTermDagNode": "持久環境、惰性與語義快取",
    "DTermDagSnapshot": "持久環境、惰性與語義快取",
    "FaceCdclProofStep": "BDD DAG、預算與 DPLL",
    "HouResidualSolveReport": "高階合一與雙向 elaborator",
    "QPolyCertifiedFactor": "完備精確代數與根隔離",
    "QPolyFactorCertificate": "完備精確代數與根隔離",
    "RealAlgRadical": "代數擴張與根式範形",
    "JacobiBlockDeflatedReport": "Jacobi 區間譜迭代",
    "DPositivityWitness": "Schema 函子、正性與歸納遞迴",
    "DSystemRepairAllMaxima": "原始 DSystem 相容性與 first-match 範形",
    "DTermDagDelta": "持久環境、惰性與語義快取",
    "DTermDagDeltaBinaryLoad": "持久環境、惰性與語義快取",
    "SharedDagBundle": "模組分離編譯與連結",
    "SharedDagBundleLoad": "模組分離編譯與連結",
    "ModuleTlvSection": "模組分離編譯與連結",
    "CompiledModuleEnvelopeLoad": "模組分離編譯與連結",
    "ArtifactAuthKey": "模組分離編譯與連結",
    "ArtifactCasStatus": "模組分離編譯與連結",
    "ArtifactSyncReport": "模組分離編譯與連結",
    "BddPrunedOptimalBuild": "BDD DAG、預算與 DPLL",
    "BddDecomposedOptimalBuild": "BDD DAG、預算與 DPLL",
    "FaceDrupTrimReport": "BDD DAG、預算與 DPLL",
    "FaceLratStep": "BDD DAG、預算與 DPLL",
    "FaceLratElaborateReport": "BDD DAG、預算與 DPLL",
    "DCubeCoveringReport": "宿主不透明立方與開盒填充",
    "CheckedDCube": "宿主不透明立方與開盒填充",
    "DCubeYonedaReport": "宿主不透明立方與開盒填充",
    "HouEnumerationReport": "高階合一與雙向 elaborator",
    "ComplexAlgNum": "完備精確代數與根隔離",
    "LllReductionReport": "完備精確代數與根隔離",
    "QPolyLllFactorReport": "完備精確代數與根隔離",
    "ArtifactMergeConflict": "模組分離編譯與連結",
    "ArtifactMergePolicy": "模組分離編譯與連結",
    "ArtifactThreeWayMergeReport": "模組分離編譯與連結",
    "ArtifactWalRecoveryReport": "模組分離編譯與連結",
    "ArtifactWalStore": "模組分離編譯與連結",
    "Ed25519Keypair": "模組分離編譯與連結",
    "Ed25519PublicKey": "模組分離編譯與連結",
    "Ed25519Signature": "模組分離編譯與連結",
    "ModuleBuildPlanReport": "模組分離編譯與連結",
    "ModuleIncrementalBuildReport": "模組分離編譯與連結",
    "CircleSquareWindingReport": "AST Kan comp/hcomp",
    "DFunctorPositivityEvidence": "Schema 函子、正性與歸納遞迴",
    "DFunctorialPositivityCert": "Schema 函子、正性與歸納遞迴",
    "DOpenIRArg": "一等宇宙多態與同時宣告 schema",
    "DOpenIRArgKind": "一等宇宙多態與同時宣告 schema",
    "DOpenIRArgVal": "一等宇宙多態與同時宣告 schema",
    "DOpenIRCode": "一等宇宙多態與同時宣告 schema",
    "DOpenIRConstructor": "一等宇宙多態與同時宣告 schema",
    "DOpenIRDecoder": "一等宇宙多態與同時宣告 schema",
    "DOpenSimultaneousIRSpec": "一等宇宙多態與同時宣告 schema",
    "DSystemDsaturCliqueReport": "原始 DSystem 相容性與 first-match 範形",
    "HouDelayedGraphReport": "高階合一與雙向 elaborator",
    "HouDelayedSolveStatus": "高階合一與雙向 elaborator",
    "HouFlexFlexEdge": "高階合一與雙向 elaborator",
    "HouLazyUnifierStream": "高階合一與雙向 elaborator",
})

EXACT.update({
    "checked_dcube_make": "宿主不透明立方與開盒填充",
    "checked_dcube_closed": "宿主不透明立方與開盒填充",
    "checked_dcube_extensional_eq": "宿主不透明立方與開盒填充",
    "face_cdcl_lrat_check": "BDD DAG、預算與 DPLL",
    "face_cdcl_lrat_check_binary": "BDD DAG、預算與 DPLL",
    "face_cdcl_elaborate_lrat": "BDD DAG、預算與 DPLL",
    "face_lrat_to_binary": "BDD DAG、預算與 DPLL",
    "face_lrat_from_binary": "BDD DAG、預算與 DPLL",
    "conv_at_under_face_in": "原始 DSystem 相容性與 first-match 範形",
    "tube_paths_conv_under_face_in": "原始 DSystem 相容性與 first-match 範形",
    "cubical_face_subcubes": "原始 DSystem 相容性與 first-match 範形",
    "reflect_var": "依賴型別 NbE（Π/Σ/宇宙）",
    "reflect_neutral_at_type": "依賴型別 NbE（Π/Σ/宇宙）",
    "infer_unglue_equiv": "AST 一等 Equiv 與 GlueEquiv",
    "empty_inductive_schema": "通用歸納族 schema",
    "empty_inductive_type_value": "通用歸納族 schema",
    "empty_inductive_elim_value": "通用歸納族 schema",
    "dj_singleton_elim_value": "立方體演算法",
    "dpathp_of_transport_eq_value": "立方體演算法",
    "dpathp_eq_in_set_family_value": "立方體演算法",
    "dprop_is_set_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_schema": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_schema_at": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_type_term": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_type_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_point_term": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_point_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_hub_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_spoke_path_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_loop_trivial_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_is_set_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_rec_set_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_elim_prop_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_elim_set_value": "Adjoint 等價、纖維與命題截斷",
    "set_trunc_equiv_of_equiv_set_value": "Adjoint 等價、纖維與命題截斷",
    "integer_succ_pred_sect_value": "圓的萬有覆疊與 encode/decode",
    "integer_pred_succ_retr_value": "圓的萬有覆疊與 encode/decode",
    "integer_is_set_value": "圓的萬有覆疊與 encode/decode",
    "circle_encode_x_value": "圓的萬有覆疊與 encode/decode",
    "circle_decode_step_value": "圓的萬有覆疊與 encode/decode",
    "circle_decode_x_value": "圓的萬有覆疊與 encode/decode",
    "circle_encode_decode_x_sect_with_zset_value": "圓的萬有覆疊與 encode/decode",
    "circle_encode_decode_x_sect_value": "圓的萬有覆疊與 encode/decode",
    "circle_decode_encode_x_retr_value": "圓的萬有覆疊與 encode/decode",
    "circle_decode_encode_retr_value": "圓的萬有覆疊與 encode/decode",
    "circle_path_equiv_cover_with_zset_value": "圓的萬有覆疊與 encode/decode",
    "circle_path_equiv_cover_value": "圓的萬有覆疊與 encode/decode",
    "circle_loop_space_equiv_integer_value": "圓的萬有覆疊與 encode/decode",
    "pi1_set_circle_equiv_integer_value": "圓的萬有覆疊與 encode/decode",
    "susp_type_schema": "球面與懸掛 HIT",
    "susp_type_schema_at": "球面與懸掛 HIT",
    "susp_type_value": "球面與懸掛 HIT",
    "susp_north_value": "球面與懸掛 HIT",
    "susp_south_value": "球面與懸掛 HIT",
    "susp_merid_path_value": "球面與懸掛 HIT",
    "susp_bool_to_circle_value": "球面與懸掛 HIT",
    "circle_to_susp_bool_value": "球面與懸掛 HIT",
    "susp_bool_equiv_circle_value": "球面與懸掛 HIT",
    "susp_cocone_type_value": "球面與懸掛 HIT",
    "susp_universal_equiv_value": "球面與懸掛 HIT",
    "based_map_type_value": "球面與懸掛 HIT",
    "susp_based_to_cocone_equiv_value": "球面與懸掛 HIT",
    "cocone_to_based_loop_equiv_value": "球面與懸掛 HIT",
    "loop_suspension_adjunction_equiv_value": "球面與懸掛 HIT",
    "circle_0_connected_value": "球面與懸掛 HIT",
    "susp_0_connected_of_pointed_value": "球面與懸掛 HIT",
    "freudenthal_pi1_susp_connected_equiv_unit_value": "球面與懸掛 HIT",
    "pi1_susp_circle_equiv_unit_value": "球面與懸掛 HIT",
    "pi1_susp2_circle_equiv_unit_value": "球面與懸掛 HIT",
    "wedge_connectivity_circle_set_ext_value": "球面與懸掛 HIT",
    "wedge_connectivity_circle_left_coh_value": "球面與懸掛 HIT",
    "wedge_connectivity_circle_right_coh_value": "球面與懸掛 HIT",
    "freudenthal_susp_loop1_to_loop2_value": "球面同倫代表元與 Hopf 不變量",
    "freudenthal_susp_loop1_preserves_refl_value": "球面同倫代表元與 Hopf 不變量",
    "van_hoeij_lll_recombine": "完備精確代數與根隔離",
    "qmat_lll_reduce": "完備精確代數與根隔離",
    "qmat_is_lll_reduced": "完備精確代數與根隔離",
    "rat_round_nearest_bigint": "完備精確代數與根隔離",
    "qpoly_factor_lll": "完備精確代數與根隔離",
    "dsatur_color_order": "原始 DSystem 相容性與 first-match 範形",
    "dsystem_repair_all_maxima_dsatur": "原始 DSystem 相容性與 first-match 範形",
    "circle_path_winding_int": "AST Kan comp/hcomp",
    "circle_square_glued_cap": "AST Kan comp/hcomp",
    "torus_square_glued_cap": "AST Kan comp/hcomp",
    "sigma_cong_snd_equiv_value": "立方體演算法",
    "sigma_path_equiv_subst_value": "立方體演算法",
    "sigma_path_equiv_value": "立方體演算法",
    "fibration_loop_equiv_fiber_path_value": "立方體演算法",
    "pathp_equiv_transport_eq_value": "立方體演算法",
    "circle_rot_eval_base_eq_value": "球面同倫代表元與 Hopf 不變量",
    "sphere2_susp_loop1_to_loop2_value": "球面同倫代表元與 Hopf 不變量",
    "integer_to_pi2_s2_value": "球面同倫代表元與 Hopf 不變量",
    "pi2_s2_hopf_hom_value": "球面同倫代表元與 Hopf 不變量",
    "pi2_s2_hopf_retract_sect_value": "球面同倫代表元與 Hopf 不變量",
    "pi2_s2_type_value": "球面同倫代表元與 Hopf 不變量",
    "module_topological_plan": "模組分離編譯與連結",
    "module_build_dag_incremental": "模組分離編譯與連結",
    "hou_conv": "高階合一與雙向 elaborator",
    "paren_all": "立方體演算法",
    "paren_left_spine": "立方體演算法",
    "paren_right_spine": "立方體演算法",
    "paren_k5_lhs1": "立方體演算法",
    "assoc_tree_value": "立方體演算法",
    "paren_rotations": "立方體演算法",
    "paren_rotation_edge_count": "立方體演算法",
    "paren_rotation_graph_connected": "立方體演算法",
    "stree_dim": "立方體演算法",
    "stree_all": "立方體演算法",
    "assoc_fvector": "立方體演算法",
    "assoc_two_faces": "立方體演算法",
    "catalan": "立方體演算法",
    "paren_leaves": "立方體演算法",
    "paren_renumber": "立方體演算法",
    "stree_leaves": "立方體演算法",
    "fg_zero": "立方體演算法",
    "fg_z": "立方體演算法",
    "fg_zmod": "立方體演算法",
    "fg_is_trivial": "立方體演算法",
    "fg_rank_le": "立方體演算法",
    "les_middle_is_injective": "立方體演算法",
    "les_middle_is_surjective": "立方體演算法",
    "les_middle_is_iso": "立方體演算法",
    "pi_circle": "立方體演算法",
    "hopf_les_iso": "立方體演算法",
    "hopf_les_injective": "立方體演算法",
    "hopf_les_surjective": "立方體演算法",
    "conn_of_sphere": "立方體演算法",
    "bm_gap": "立方體演算法",
    "gap_equiv_below": "立方體演算法",
    "gap_surj_at": "立方體演算法",
    "suspension_gap": "立方體演算法",
    "freudenthal_status": "立方體演算法",
    "pi3_s2_iso_pi3_s3": "立方體演算法",
    "pi3_s2_iso_pi3_s3_origins": "立方體演算法",
    "pi3_s3_iso_pi2_s2": "立方體演算法",
    "pi3_s3_iso_pi2_s2_origins": "立方體演算法",
    "pi2_s2_iso_z_origins": "立方體演算法",
    "pi2_s2_iso_z_halves": "立方體演算法",
    "join_sphere_dim": "立方體演算法",
    "s3_is_join_of_two_circles": "立方體演算法",
    "whitehead_degree": "立方體演算法",
    "brunerie_whitehead_lives_in": "立方體演算法",
    "join_schema_at": "立方體演算法",
    "join_schema": "立方體演算法",
    "join_type_value": "立方體演算法",
    "join_inl_value": "立方體演算法",
    "join_inr_value": "立方體演算法",
    "join_push_value": "立方體演算法",
    "join_cocone_type_value": "立方體演算法",
    "join_rec_value": "立方體演算法",
    "wedge_schema_at": "立方體演算法",
    "wedge_schema": "立方體演算法",
    "wedge_type_value": "立方體演算法",
    "wedge_winl_value": "立方體演算法",
    "wedge_winr_value": "立方體演算法",
    "wedge_glue_value": "立方體演算法",
    "wedge_rec_value": "立方體演算法",
    "trunc_schema_at": "立方體演算法",
    "trunc_schema": "立方體演算法",
    "trunc_type_value": "立方體演算法",
    "trunc_inc_value": "立方體演算法",
    "trunc_rec_value": "立方體演算法",
    "james_schema_at": "立方體演算法",
    "james_schema": "立方體演算法",
    "james_type_value": "立方體演算法",
    "james_nil_value": "立方體演算法",
    "james_cons_value": "立方體演算法",
    "james_rec_value": "立方體演算法",
    "join_dim": "立方體演算法",
    "james_cell_dim": "立方體演算法",
    "check_homotopy_universal": "立方體演算法",
    "homotopy_universal_remaining": "立方體演算法",

    "james_cells": "立方體演算法",
    "brunerie_original": "立方體演算法",
    "brunerie_new_family": "立方體演算法",
    "brunerie_norm_establishes": "立方體演算法",
    "brunerie_family_establishes": "立方體演算法",
    "brunerie_family_decreasing": "立方體演算法",
    "cyclic_of_beta": "立方體演算法",
    "pi4_s3_iso_pi4_s2": "立方體演算法",
    "pi4_s3_group": "立方體演算法",
    "pi4_s3_origins": "立方體演算法",
    "assoc_euler_characteristic": "立方體演算法",
    "hou_match": "高階合一與雙向 elaborator",
    "hou_match_solved_within": "高階合一與雙向 elaborator",
    "disk_state_new": "模組分離編譯與連結",
    "disk_apply": "模組分離編譯與連結",
    "disk_recover": "模組分離編譯與連結",
    "durable_write_protocol": "模組分離編譯與連結",
    "torn_write_protocol": "模組分離編譯與連結",
    "unacknowledged_write_protocol": "模組分離編譯與連結",
    "protocol_is_crash_consistent": "模組分離編譯與連結",
    "protocol_durable_on_completion": "模組分離編譯與連結",
    "protocol_first_tear": "模組分離編譯與連結",
    "durable_delete_protocol": "模組分離編譯與連結",
    "unacknowledged_delete_protocol": "模組分離編譯與連結",
    "protocol_deletes_on_completion": "模組分離編譯與連結",
    "hot_load_env_new": "模組分離編譯與連結",
    "hot_load_env_to_compiled": "模組分離編譯與連結",
    "hot_load_env_epoch": "模組分離編譯與連結",
    "hot_load_env_history": "模組分離編譯與連結",
    "hot_load_env_modules": "模組分離編譯與連結",
    "hot_load_dependents": "模組分離編譯與連結",
    "hot_load_consistent": "模組分離編譯與連結",
    "hot_load_stale_modules": "模組分離編譯與連結",
    "hot_load_plan": "模組分離編譯與連結",
    "hot_load_apply": "模組分離編譯與連結",
    "hot_load_instantiate": "模組分離編譯與連結",
    "hot_load_signature": "模組分離編譯與連結",
    "certified_e": "完備精確代數與根隔離",
    "certified_pi": "完備精確代數與根隔離",
    "e_irrationality_certificate": "完備精確代數與根隔離",
    "e_irr_certificate_verify": "完備精確代數與根隔離",
    "e_refute_rational": "完備精確代數與根隔離",
    "poly_nonzero_at_e": "完備精確代數與根隔離",
    "pi_refute_rational_refined": "完備精確代數與根隔離",
})

CHECK_FAMILY_HINTS = [
    ("brunerie_pi4_s3", "立方體演算法"),
    ("homotopy_universal", "立方體演算法"),
    ("blakers_massey", "立方體演算法"),
    ("assoc_faces", "立方體演算法"),
    ("hou_matching", "高階合一與雙向 elaborator"),
    ("durable_write_protocol", "模組分離編譯與連結"),
    ("module_runtime_hot_loading", "模組分離編譯與連結"),
    ("transcendental_boundary_layer", "完備精確代數與根隔離"),
    ("phase16_schema_large_open_positivity", "一等宇宙多態與同時宣告 schema"),
    ("phase16_dsatur_and_glued_cubical_comp", "原始 DSystem 相容性與 first-match 範形"),
    ("phase16_crypto_ed25519_and_wal", "模組分離編譯與連結"),
    ("phase16_sphere_homotopy_and_k5", "球面同倫代表元與 Hopf 不變量"),
    ("phase16_hou_stream_and_module_merge", "高階合一與雙向 elaborator"),
    ("lll_lattice_and_van_hoeij_factor", "完備精確代數與根隔離"),
    ("complex_algebraic_closure_rouche", "完備精確代數與根隔離"),
    ("phase15_bdd_symmetry_orbit_and_decomposed_optimal", "BDD DAG、預算與 DPLL"),
    ("phase15_cdcl_lrat_elaboration_and_binary_codec", "BDD DAG、預算與 DPLL"),
    ("phase15_dcube_strength4_phf_and_yoneda_audit", "宿主不透明立方與開盒填充"),
    ("phase15_bidirectional_bijectivity_and_pi1_circle", "圓的萬有覆疊與 encode/decode"),
    ("phase15_suspension_and_loop_suspension_adjunction", "球面與懸掛 HIT"),
    ("phase15_freudenthal_suspension_and_wedge_connectivity", "球面與懸掛 HIT"),
    ("phase14_joint_simultaneous_ir_mutual", "一等宇宙多態與同時宣告 schema"),
    ("phase14_positivity_witness_certificates", "Schema 函子、正性與歸納遞迴"),
    ("phase14_dsystem_all_maxima_and_finite_case_split", "原始 DSystem 相容性與 first-match 範形"),
    ("phase14_decoupled_torus_and_semantic_circle_norm", "AST Kan comp/hcomp"),
    ("phase14_incremental_dag_delta_and_shared_bundle", "持久環境、惰性與語義快取"),
    ("phase14_qpoly_hensel_factor_and_certificates", "完備精確代數與根隔離"),
    ("qpoly_hensel_factor_and_certificates", "完備精確代數與根隔離"),
    ("phase14_algebraic_radicals_and_rank6_multiquad", "代數擴張與根式範形"),
    ("algebraic_radicals_and_rank6_multiquad", "代數擴張與根式範形"),
    ("phase14_jacobi_block_deflation_and_multiplicity", "Jacobi 區間譜迭代"),
    ("jacobi_block_deflation_and_multiplicity", "Jacobi 區間譜迭代"),
    ("phase14_bdd_bnb_and_cdcl_drat", "BDD DAG、預算與 DPLL"),
    ("phase14_dcube_orthogonal_array_covering", "宿主不透明立方與開盒填充"),
    ("phase14_eckmann_hilton_and_pentagon_coherence", "立方體演算法"),
    ("phase14_internal_circle_sect_and_hopf_invariant", "球面同倫代表元與 Hopf 不變量"),
    ("phase14_hou_backtracking_and_enumeration", "高階合一與雙向 elaborator"),
    ("phase14_tlv_envelope_cas_and_incremental_sync", "模組分離編譯與連結"),
    ("self_family_positivity_fixpoint", "Schema 函子、正性與歸納遞迴"),
    ("simultaneous_ir_nested_foreign", "一等宇宙多態與同時宣告 schema"),
    ("conv_under_face_relevant_descent", "原始 DSystem 相容性與 first-match 範形"),
    ("dsystem_maximum_completion", "原始 DSystem 相容性與 first-match 範形"),
    ("circle_torus_square_comp", "AST Kan comp/hcomp"),
    ("difference_guided_case_split", "依賴型別 NbE（Π/Σ/宇宙）"),
    ("interned_dag_byte_sharing", "持久環境、惰性與語義快取"),
    ("qpoly_degree_pattern_certificates", "完備精確代數與根隔離"),
    ("multiquadratic_tower", "代數擴張與根式範形"),
    ("bdd_optimal_order_dp_extended", "BDD DAG、預算與 DPLL"),
    ("cdcl_drup_proof_with_deletions", "BDD DAG、預算與 DPLL"),
    ("dcube_stratified_tier_d", "宿主不透明立方與開盒填充"),
    ("jacobi_adaptive_exact_fallback", "Jacobi 區間譜迭代"),
    ("loop_inverse_assoc_and_classification", "球面同倫代表元與 Hopf 不變量"),
    ("hou_residual_solver", "高階合一與雙向 elaborator"),
    ("artifact_manifest_integrity_chain", "模組分離編譯與連結"),
    ("jacobi_cluster_separation", "Jacobi 區間譜迭代"),
    ("biquadratic_denesting", "完備精確代數與根隔離"),
    ("qpoly_mod_pattern_pruning", "完備精確代數與根隔離"),
    ("circle_encode_decode", "圓的萬有覆疊與 encode/decode"),
    ("cdcl_clause_learning", "BDD DAG、預算與 DPLL"),
    ("bdd_optimal_order_exact", "BDD DAG、預算與 DPLL"),
    ("schema_registry_byte_persistence", "Schema 註冊與 elaboration 快取"),
    ("dterm_hash_consing", "持久環境、惰性與語義快取"),
    ("face_agreement_and_exact_repair", "原始 DSystem 相容性與 first-match 範形"),
    ("dcube_open_box_filler", "宿主不透明立方與開盒填充"),
    ("poly_cubes", "宿主不透明立方與開盒填充"),
    ("circle_torus_point_comp", "AST Kan comp/hcomp"),
    ("family_nested_functors", "Schema 函子、正性與歸納遞迴"),
    ("family_functor_persistence", "Schema 註冊與 elaboration 快取"),
    ("simultaneous_ir_compiled_decode", "一等宇宙多態與同時宣告 schema"),
    ("hou_search_extensions", "高階合一與雙向 elaborator"),
    ("module_interleaved_items", "參數化模組與名字空間"),
    ("module_binary_versions_and_store", "模組分離編譯與連結"),
    ("lemiso_generic_points", "Adjoint 等價、纖維與命題截斷"),
    ("general_adjointification", "Adjoint 等價、纖維與命題截斷"),
    ("hou_bounded_search", "高階合一與雙向 elaborator"),
    ("module_binary_format", "模組分離編譯與連結"),
    ("bdd_cost_optimizations", "BDD DAG、預算與 DPLL"),
    ("qpoly_fast_arithmetic", "精確單變量多項式與有理矩陣"),
    ("sphere_loop_representatives", "球面同倫代表元與 Hopf 不變量"),
    ("qpoly_factor_complete", "完備精確代數與根隔離"),
    ("root_isolation", "完備精確代數與根隔離"),
    ("splitting_field", "完備精確代數與根隔離"),
    ("radical_denesting", "完備精確代數與根隔離"),
    ("jacobi_arbitrary_precision", "Jacobi 區間譜迭代"),
    ("level_polymorphic", "一等宇宙多態與同時宣告 schema"),
    ("type_operator", "一等宇宙多態與同時宣告 schema"),
    ("nested_iter", "一等宇宙多態與同時宣告 schema"),
    ("mutual_declaration", "一等宇宙多態與同時宣告 schema"),
    ("simultaneous_induction", "一等宇宙多態與同時宣告 schema"),
    ("hit_moving_dimension", "一等宇宙多態與同時宣告 schema"),
    ("dsystem_repair_phase9", "原始 DSystem 相容性與 first-match 範形"),
    ("adjoint_equivalence", "Adjoint 等價、纖維與命題截斷"),
    ("propositional_truncation", "Adjoint 等價、纖維與命題截斷"),
    ("dline_dimension", "依賴 Kan 線（coe/comp）"),
    ("semantic_dimension", "受檢查語義型別線"),
    ("schema_registry_persistence", "Schema 註冊與 elaboration 快取"),
    ("certified_algebraic", "認證數值影子與精確立方體"),
    ("bdd_dag_native", "BDD DAG、預算與 DPLL"),
    ("sphere_homotopy", "球面同倫代表元與 Hopf 不變量"),
    ("hopf_numeric", "球面同倫代表元與 Hopf 不變量"),
    ("hou_phase9", "高階合一與雙向 elaborator"),
    ("module_compilation", "模組分離編譯與連結"),
    ("cubical_algorithms", "立方體演算法"), ("univalence", "計算性單值性（univalence）"),
    ("finite_univalence", "計算性單值性（univalence）"), ("universe_paths", "計算性單值性（univalence）"),
    ("sphere3", "球面與懸掛 HIT"),
    ("jacobi_interval", "Jacobi 區間譜迭代"),
    ("hou_elaborator", "高階合一與雙向 elaborator"),
    ("module_system", "參數化模組與名字空間"),
    ("container_functor", "Schema 函子、正性與歸納遞迴"),
    ("bdd_and_certified", "認證數值影子與精確立方體"),
    ("algebraic_extensions", "廣義特徵空間與 Jordan 理論"),
    ("phase6_infrastructure", "受檢查語義型別線"),
    ("equiv_ast", "AST 一等 Equiv 與 GlueEquiv"),
    ("dsystem_first_match", "原始 DSystem 相容性與 first-match 範形"),
    ("schema_extensions", "Schema 擴展：互歸納、商與宇宙多態"),
    ("structural_positivity", "Schema 函子、正性與歸納遞迴"),
    ("tarski", "Schema 函子、正性與歸納遞迴"),
    ("nested_rose", "Schema 函子、正性與歸納遞迴"),
    ("hit_schema", "通用 HIT schema"), ("hit_endpoint", "通用 HIT schema"),
    ("generated_hit", "通用 HIT schema"), ("schema", "通用歸納族 schema"),
    ("generated_inductive", "通用歸納族 schema"), ("persistent", "持久環境、惰性與語義快取"),
    ("dsystem", "依賴語義系統與 partial 值"), ("multibranch", "依賴語義系統與 partial 值"),
    ("phase5", "依賴語義系統與 partial 值"),
    ("ast_kan", "AST Kan comp/hcomp"), ("ast_coe", "AST Kan comp/hcomp"),
    ("ast_hcomp", "AST Kan comp/hcomp"), ("ast_bool", "資料型別與 HIT 消去"), ("ast_nat", "資料型別與 HIT 消去"),
    ("ast_list", "資料型別與 HIT 消去"), ("ast_data", "資料型別與 HIT 消去"),
    ("ast_hits", "資料型別與 HIT 消去"), ("ast", "立方 AST 與維度 NbE"),
    ("dep", "依賴型別 NbE（Π/Σ/宇宙）"),
    ("kan_coe", "依賴 Kan 線（coe/comp）"), ("kan_comp", "依賴 Kan 線（coe/comp）"),
    ("kan_embeddings", "依賴 Kan 線（coe/comp）"), ("kan_dep", "依賴 Kan 線（coe/comp）"),
    ("kan_all", "依賴 Kan 線（coe/comp）"),
    ("spectral", "譜投影與仿射唯一填充"), ("symbolic", "譜投影與仿射唯一填充"),
    ("bdd", "面公式與 BDD"), ("eta", "型別化 NbE 與 η"),
    ("wiring", "Wiring 符號等價"),
    ("glue_comp", "Glue comp（有限線）"), ("glue", "有限 Glue"),
    ("karoubi", "Karoubi 包絡"), ("face_poset", "面偏序範疇"),
    ("syntactic", "句法笛卡兒閉範疇"), ("cubical", "立方體與 Kan 填充"),
    ("categories", "範疇化總檢"),
    ("projector", "投影與特徵空間"), ("eigenspace", "投影與特徵空間"),
    ("commuting", "投影與特徵空間"), ("orthogonal", "投影與特徵空間"),
    ("kan", "立方體與 Kan 填充"), ("cube", "立方體與 Kan 填充"),
    ("interval", "面公式與 BDD"), ("systems", "系統與剪枝"),
    ("nbe", "未型別 NbE"), ("coe", "同構、等價、ua、coe"),
    ("hoas", "HOAS"), ("ua", "同構、等價、ua、coe"),
    ("pathp", "PathP、離散路徑與 J"), ("j", "PathP、離散路徑與 J"),
]

PREFIXES = [
    ("liouville_", "完備精確代數與根隔離"),
    ("schanuel_", "完備精確代數與根隔離"),
    ("berkowitz_", "精確單變量多項式與有理矩陣"),
    ("qmat_charpoly_berkowitz_crt", "精確單變量多項式與有理矩陣"),
    ("bft_", "模組分離編譯與連結"),
    ("cantor_ord_", "Schema 函子、正性與歸納遞迴"),
    ("compile_indexed_container", "Schema 函子、正性與歸納遞迴"),
    ("verify_mahlo_", "一等宇宙多態與同時宣告 schema"),
    ("conv_sheaf_", "依賴型別 NbE（Π/Σ/宇宙）"),
    ("dsystem_kernelized_", "原始 DSystem 相容性與 first-match 範形"),
    ("f2_", "AST Kan comp/hcomp"),
    ("wedge_square_", "AST Kan comp/hcomp"),
    ("bdd_dag_of_face_frontier_", "BDD DAG、預算與 DPLL"),
    ("reify_natural_dcube_", "宿主不透明立方與開盒填充"),
    ("dpath_singleton_n_", "立方體演算法"),
    ("dpath_k6_", "立方體演算法"),
    ("dpath_associahedron_k6_", "立方體演算法"),
    ("hou_match_higher_order_", "高階合一與雙向 elaborator"),
    ("goldfarb_", "高階合一與雙向 elaborator"),
    ("hot_load_tarjan_", "模組分離編譯與連結"),
    ("hot_load_mvcc_", "模組分離編譯與連結"),
    ("complex_alg_", "完備精確代數與根隔離"),
    ("crypto_sha", "模組分離編譯與連結"),
    ("ed25519_", "模組分離編譯與連結"),
    ("dopen_", "一等宇宙多態與同時宣告 schema"),
    ("open_ir_", "一等宇宙多態與同時宣告 schema"),
    ("dfunctorial_positivity_", "Schema 函子、正性與歸納遞迴"),
    ("dterm_family_strictly_positive_functorial", "Schema 函子、正性與歸納遞迴"),
    ("dpath_", "立方體演算法"),
    ("hou_", "高階合一與雙向 elaborator"),
    ("multiquad_", "代數擴張與根式範形"),
    ("real_alg_", "代數擴張與根式範形"),
    ("dterm_dag_", "持久環境、惰性與語義快取"),
    ("dterm_local_shell", "持久環境、惰性與語義快取"),
    ("cubic_", "代數擴張與根式範形"), ("triquad_", "代數擴張與根式範形"),
    ("artifact_", "模組分離編譯與連結"),
    ("conv_terms_", "依賴型別 NbE（Π/Σ/宇宙）"),
    ("biquad_", "完備精確代數與根隔離"),
    ("cdcl_", "BDD DAG、預算與 DPLL"),
    ("face_sat_cdcl", "BDD DAG、預算與 DPLL"), ("face_eq_cdcl", "BDD DAG、預算與 DPLL"),
    ("face_agreement", "原始 DSystem 相容性與 first-match 範形"),
    ("dcube_", "宿主不透明立方與開盒填充"), ("poly_cube", "宿主不透明立方與開盒填充"), ("poly_box", "宿主不透明立方與開盒填充"),
    ("dterm_intern", "持久環境、惰性與語義快取"),
    ("algpoly_", "完備精確代數與根隔離"), ("bigint_", "完備精確代數與根隔離"),
    ("complex_root_", "完備精確代數與根隔離"), ("real_root_", "完備精確代數與根隔離"),
    ("splitting_field_", "完備精確代數與根隔離"), ("radical_", "完備精確代數與根隔離"),
    ("level_", "一等宇宙多態與同時宣告 schema"),
    ("dnested_", "一等宇宙多態與同時宣告 schema"),
    ("nested_iter_", "一等宇宙多態與同時宣告 schema"),
    ("bush_", "一等宇宙多態與同時宣告 schema"),
    ("dmutual_", "一等宇宙多態與同時宣告 schema"),
    ("dsimultaneous_", "一等宇宙多態與同時宣告 schema"),
    ("simultaneous_ir_", "一等宇宙多態與同時宣告 schema"),
    ("dtype_operator_", "一等宇宙多態與同時宣告 schema"),
    ("type_operator_", "一等宇宙多態與同時宣告 schema"),
    ("compiled_module_", "模組分離編譯與連結"),
    ("algc_", "認證數值影子與精確立方體"),
    ("alg_cert_", "認證數值影子與精確立方體"),
    ("circle_hit_", "球面同倫代表元與 Hopf 不變量"),
    ("circle_degree_", "球面同倫代表元與 Hopf 不變量"),
    ("hopf_", "球面同倫代表元與 Hopf 不變量"),
    ("adjoint_", "Adjoint 等價、纖維與命題截斷"),
    ("prop_trunc_", "Adjoint 等價、纖維與命題截斷"),
    ("trunc_", "Adjoint 等價、纖維與命題截斷"),
    ("conv_at_under_face_report", "原始 DSystem 相容性與 first-match 範形"),
    ("univalence_", "計算性單值性（univalence）"), ("universe_path_", "計算性單值性（univalence）"),
    ("path_to_equiv", "計算性單值性（univalence）"), ("equiv_to_universe_path", "計算性單值性（univalence）"),
    ("ua_beta", "計算性單值性（univalence）"), ("ua_transport", "計算性單值性（univalence）"),
    ("ua_map_term", "計算性單值性（univalence）"), ("upath_to_equiv", "計算性單值性（univalence）"),
    ("upath_refl", "計算性單值性（univalence）"), ("upath_sym", "計算性單值性（univalence）"),
    ("upath_trans", "計算性單值性（univalence）"), ("finite_transport", "計算性單值性（univalence）"),
    ("transport_roundtrip", "計算性單值性（univalence）"),
    ("transport_", "立方體演算法"), ("dpath_", "立方體演算法"),
    ("dtransport", "立方體演算法"), ("dfunext", "立方體演算法"),
    ("subst_", "立方體演算法"), ("kan_box", "立方體演算法"),
    ("sphere", "球面與懸掛 HIT"), ("suspension_", "球面與懸掛 HIT"),
    ("rat_interval", "Jacobi 區間譜迭代"), ("rat_sqrt_interval", "Jacobi 區間譜迭代"),
    ("rat_cmp_exact", "Jacobi 區間譜迭代"), ("rat_le_exact", "Jacobi 區間譜迭代"),
    ("rat_abs_exact", "Jacobi 區間譜迭代"), ("rat_round_", "Jacobi 區間譜迭代"),
    ("cinterval", "Jacobi 區間譜迭代"), ("qci_", "Jacobi 區間譜迭代"),
    ("qcpx", "Jacobi 區間譜迭代"), ("jacobi_", "Jacobi 區間譜迭代"),
    ("eigen_interval", "Jacobi 區間譜迭代"),
    ("elab_", "高階合一與雙向 elaborator"), ("elaborator_", "高階合一與雙向 elaborator"),
    ("hou_", "高階合一與雙向 elaborator"), ("unifier_", "高階合一與雙向 elaborator"),
    ("uterm_", "高階合一與雙向 elaborator"), ("uty_", "高階合一與雙向 elaborator"),
    ("module_", "參數化模組與名字空間"),
    ("bdd_manager", "BDD DAG、預算與 DPLL"), ("bdd_dag", "BDD DAG、預算與 DPLL"),
    ("bdd_tree_of_dag", "BDD DAG、預算與 DPLL"), ("bdd_worst", "BDD DAG、預算與 DPLL"),
    ("bdd_var_order", "BDD DAG、預算與 DPLL"),
    ("face_sat_dpll", "BDD DAG、預算與 DPLL"), ("face_eq_dpll", "BDD DAG、預算與 DPLL"),
    ("face_sat_within_budget", "BDD DAG、預算與 DPLL"), ("face_eq_within_budget", "BDD DAG、預算與 DPLL"),
    ("checked_", "受檢查語義型別線"),
    ("infer_equiv", "AST 一等 Equiv 與 GlueEquiv"), ("infer_glue_equiv", "AST 一等 Equiv 與 GlueEquiv"),
    ("infer_mk_equiv", "AST 一等 Equiv 與 GlueEquiv"), ("infer_ua", "AST 一等 Equiv 與 GlueEquiv"),
    ("dfunctor_", "Schema 函子、正性與歸納遞迴"), ("positive_functor_", "Schema 函子、正性與歸納遞迴"),
    ("dterm_family_", "Schema 函子、正性與歸納遞迴"), ("dpositivity_", "Schema 函子、正性與歸納遞迴"),
    ("mutual_", "Schema 擴展：互歸納、商與宇宙多態"), ("compile_mutual", "Schema 擴展：互歸納、商與宇宙多態"),
    ("instantiate_", "Schema 擴展：互歸納、商與宇宙多態"), ("dlevel_", "Schema 擴展：互歸納、商與宇宙多態"),
    ("qmat_generalized", "廣義特徵空間與 Jordan 理論"), ("qmat_Jordan", "廣義特徵空間與 Jordan 理論"),
    ("qmat_primary", "廣義特徵空間與 Jordan 理論"), ("qmat_eigen", "廣義特徵空間與 Jordan 理論"),
    ("qmat_diagonalizable", "廣義特徵空間與 Jordan 理論"), ("qmat_is_diagonalizable", "廣義特徵空間與 Jordan 理論"),
    ("qmat_rational_spectrum", "廣義特徵空間與 Jordan 理論"), ("qmat_vector_annihilator", "廣義特徵空間與 Jordan 理論"),
    ("qpoly_", "精確單變量多項式與有理矩陣"), ("qmat_", "精確單變量多項式與有理矩陣"),
    ("qrows_", "精確單變量多項式與有理矩陣"), ("qvec_", "精確單變量多項式與有理矩陣"),
    ("quad_", "代數擴張與根式範形"), ("alg_", "代數擴張與根式範形"),
    ("algmat_", "廣義特徵空間與 Jordan 理論"), ("algrows_", "廣義特徵空間與 Jordan 理論"),
    ("algvec_", "廣義特徵空間與 Jordan 理論"),
    ("cert_", "認證數值影子與精確立方體"), ("certify_", "認證數值影子與精確立方體"),
    ("qcc_", "認證數值影子與精確立方體"), ("numeric_", "認證數值影子與精確立方體"),
    ("cx", "複數標量"), ("cx_", "複數標量"),
    ("vec_", "複向量與內積"), ("inner", "複向量與內積"),
    ("mat_", "矩陣與伴隨"),
    ("is_", "投影與特徵空間"), ("eigen", "投影與特徵空間"),
    ("projector_", "投影與特徵空間"), ("decompose", "投影與特徵空間"),
    ("complement", "投影與特徵空間"),
    ("in_image", "投影與特徵空間"), ("in_kernel", "投影與特徵空間"),
    ("prune_to_eigenspace", "投影與特徵空間"), ("pruning_is_retraction", "投影與特徵空間"),
    ("commuting", "投影與特徵空間"),
    ("karoubi_", "Karoubi 包絡"),
    ("eval_dim", "區間"), ("interval_", "區間"),
    ("bdd_", "面公式與 BDD"), ("dim_", "面公式與 BDD"), ("face_", "面公式與 BDD"),
    ("system_", "系統與剪枝"), ("branch", "系統與剪枝"),
    ("prune_system", "系統與剪枝"), ("pruning_respects", "系統與剪枝"),
    ("compatibility_", "系統與剪枝"), ("union_", "系統與剪枝"),
    ("cube_", "立方體與 Kan 填充"), ("path_line", "立方體與 Kan 填充"),
    ("path_refl", "立方體與 Kan 填充"), ("path_sym", "立方體與 Kan 填充"),
    ("path_eval", "立方體與 Kan 填充"), ("path_start", "立方體與 Kan 填充"),
    ("path_end", "立方體與 Kan 填充"), ("path_trans", "立方體與 Kan 填充"),
    ("restrict_face", "立方體與 Kan 填充"), ("degenerate_", "立方體與 Kan 填充"),
    ("square_fill", "立方體與 Kan 填充"), ("open_box", "立方體與 Kan 填充"),
    ("filler_", "立方體與 Kan 填充"), ("kan_", "立方體與 Kan 填充"),
    ("prune_cube", "立方體與 Kan 填充"), ("bumped_filler", "立方體與 Kan 填充"),
    ("pruning_repairs", "立方體與 Kan 填充"), ("eigenspace_kan", "立方體與 Kan 填充"),
    ("eval", "未型別 NbE"), ("quote", "未型別 NbE"), ("nf", "未型別 NbE"),
    ("def_eq", "未型別 NbE"), ("nbe_", "未型別 NbE"),
    ("vapp", "未型別 NbE"), ("vfst", "未型別 NbE"), ("vsnd", "未型別 NbE"),
    ("happ", "HOAS"), ("hfst", "HOAS"), ("hsnd", "HOAS"), ("hoas_", "HOAS"),
    ("term_to_hoas", "HOAS"),
    ("ty_bool", "有限宇宙型別與值"), ("ty_unit", "有限宇宙型別與值"), ("ty_prod", "有限宇宙型別與值"),
    ("ty_", "型別化 NbE 與 η"), ("eval_check_t", "型別化 NbE 與 η"),
    ("eval_infer_t", "型別化 NbE 與 η"), ("tapp", "型別化 NbE 與 η"),
    ("tfst", "型別化 NbE 與 η"), ("tsnd", "型別化 NbE 與 η"),
    ("quote_eta", "型別化 NbE 與 η"), ("quote_tneutral", "型別化 NbE 與 η"),
    ("nf_eta", "型別化 NbE 與 η"), ("def_eq_eta", "型別化 NbE 與 η"),
    ("eta_", "型別化 NbE 與 η"),
    ("tm_shift", "句法笛卡兒閉範疇"), ("tm_comp", "句法笛卡兒閉範疇"),
    ("tm_id_at", "句法笛卡兒閉範疇"), ("tm_swap_at", "型別化 NbE 與 η"),
    ("tm_coe_swap_at", "型別化 NbE 與 η"),
    ("elems_of", "有限宇宙型別與值"), ("in_ty", "有限宇宙型別與值"),
    ("pval_", "有限宇宙型別與值"), ("flatten_pval", "Wiring 符號等價"),
    ("leaf_", "Wiring 符號等價"), ("leaves_", "Wiring 符號等價"), ("wiring_", "Wiring 符號等價"),
    ("iso_", "同構、等價、ua、coe"), ("equiv_", "同構、等價、ua、coe"),
    ("ua", "同構、等價、ua、coe"), ("upath_", "同構、等價、ua、coe"),
    ("coe_upath", "同構、等價、ua、coe"), ("coe_computes", "同構、等價、ua、coe"),
    ("swap_naturality", "同構、等價、ua、coe"),
    ("pathp_", "PathP、離散路徑與 J"), ("disc_", "PathP、離散路徑與 J"),
    ("refl_path", "PathP、離散路徑與 J"), ("j_", "PathP、離散路徑與 J"),
    ("glue_data", "Glue comp（有限線）"), ("glue_line", "Glue comp（有限線）"),
    ("glue_comp_finite", "Glue comp（有限線）"),
    ("glue_box", "Glue comp（子空間線）"), ("glue_comp_vec", "Glue comp（子空間線）"),
    ("subline_", "Glue comp（子空間線）"), ("lin_equiv", "Glue comp（子空間線）"),
    ("fill_subline", "Glue comp（子空間線）"), ("map_cube", "Glue comp（子空間線）"),
    ("glue_", "有限 Glue"), ("make_glue", "有限 Glue"), ("unglue", "有限 Glue"),
    ("dep_", "依賴型別 NbE（Π/Σ/宇宙）"),
    ("dline_", "依賴 Kan 線（coe/comp）"), ("dcoe", "依賴 Kan 線（coe/comp）"),
    ("dcomp", "依賴 Kan 線（coe/comp）"), ("dfill", "依賴 Kan 線（coe/comp）"),
    ("dbool_not", "依賴 Kan 線（coe/comp）"), ("path_from", "依賴 Kan 線（coe/comp）"),
    ("pval_to_dvalue", "依賴 Kan 線（coe/comp）"), ("dvalue_", "依賴 Kan 線（coe/comp）"),
    ("rat_", "精確符號代數"), ("int_abs", "精確符號代數"), ("int_gcd", "精確符號代數"),
    ("poly_", "精確符號代數"), ("frac_", "精確符號代數"), ("sc_", "精確符號代數"),
    ("sym_", "精確符號代數"), ("upoly_", "精確符號代數"), ("charpoly_sym", "精確符號代數"),
    ("rpoly_", "譜投影與仿射唯一填充"), ("spectral_", "譜投影與仿射唯一填充"),
    ("spec_", "規格登記"),
    ("denv_", "持久環境、惰性與語義快取"), ("ddim_", "持久環境、惰性與語義快取"),
    ("lazy_", "持久環境、惰性與語義快取"), ("force_value", "持久環境、惰性與語義快取"),
    ("memo_", "持久環境、惰性與語義快取"), ("dterm_cache", "持久環境、惰性與語義快取"),
    ("dim_cache", "持久環境、惰性與語義快取"),
    ("dsystem_", "依賴語義系統與 partial 值"), ("partial_", "依賴語義系統與 partial 值"),
    ("tube_system_", "依賴語義系統與 partial 值"), ("glue_partial_", "依賴語義系統與 partial 值"),
    ("glue_store_", "依賴語義系統與 partial 值"),
    ("darg_", "通用歸納族 schema"), ("dtelescope_", "通用歸納族 schema"),
    ("dconstructor_", "通用歸納族 schema"), ("dinductive_", "通用歸納族 schema"),
    ("inductive_", "通用歸納族 schema"), ("schema_", "通用歸納族 schema"),
    ("telescope_", "通用歸納族 schema"),
    ("dhit_", "通用 HIT schema"), ("hit_", "通用 HIT schema"),
    ("run_all_checks", "定理登記與範例"), ("all_checks_pass", "定理登記與範例"),
    ("print_report", "定理登記與範例"),
]

KIND_LABELS = {
    "zh": {
        "fn": "函數", "struct": "結構", "enum": "列舉", "type": "型別別名",
        "let": "常量", "constructor": "構造子", "field": "欄位",
        "trait": "trait", "trait-method": "trait 方法", "impl": "trait 實作",
    },
    "en": {
        "fn": "function", "struct": "struct", "enum": "enum", "type": "type alias",
        "let": "constant", "constructor": "constructor", "field": "field",
        "trait": "trait", "trait-method": "trait method", "impl": "trait implementation",
    },
}

FAMILIES_EN = {
    "複數標量": ("Complex scalars", "ordered pair (re, im)", "the commutative ring C; conjugation is an involution", "componentwise eps comparison"),
    "複向量與內積": ("Complex vectors and inner products", "component lists", "objects of the Hilbert-space category Hilb; the inner product induces duals", "componentwise computation"),
    "矩陣與伴隨": ("Matrices and adjoints", "lists of rows", "morphisms of Hilb; † is the dagger functor", "matrix computation"),
    "投影與特徵空間": ("Projectors and eigenspaces", "Σ vₖvₖ†; orthogonal decomposition (Pv,(I−P)v)", "self-adjoint idempotent morphisms and their splittings (biproducts) in Hilb", "eigenvalue equations / orthogonality / integrality of trace"),
    "Karoubi 包絡": ("Karoubi envelope", "object P; morphisms are clamped matrices with QAP=A", "idempotent completion; the identity on P is P itself; dagger structure", "QAP=A and the composition laws"),
    "區間": ("Interval", "De Morgan expressions; booleanization at endpoints", "the De Morgan algebra (interval object)", "evaluation and rewrite simplification"),
    "面公式與 BDD": ("Face formulas and BDDs", "ROBDD trees expanded from interned DAGs (compatibility view); primary decisions use manager roots", "canonical representatives of the face lattice (a quotient of the free bounded distributive lattice)", "DAG apply/root equality; the tree API expands formula by formula"),
    "面偏序範疇": ("Face poset category", "BDD equivalence classes", "poset category with ∧ as product, ∨ as coproduct, ⊤/⊥ terminal/initial", "bdd_face_le and universal-property equations"),
    "系統與剪枝": ("Systems and pruning", "branch lists; for the semantic normal form see symbolic system normal forms", "partial elements of presheaves on faces; union gluing", "BDD satisfiability on overlapping faces"),
    "系統符號範形": ("Symbolic system normal forms", "value-labelled disjoint BDD partitions plus the undefined region", "image decomposition of partial elements in slices of the face lattice", "BDD region operations"),
    "立方體與 Kan 填充": ("Cubes and Kan filling", "functions Iⁿ→Cᵐ; affine filler formulas; the cap is the comp result", "realizations of cubical sets over □; Kan structures of retracts", "boundary equations (on grids)"),
    "未型別 NbE": ("Untyped NbE", "βπ-normal forms nf", "morphism representatives of the syntactic category modulo βπ", "structural comparison after eval/quote"),
    "HOAS": ("HOAS", "de Bruijn normal forms after reification", "functor-category binding; equivalent to the first-order syntactic category modulo definitional equality", "reflect/reify round-trips"),
    "型別化 NbE 與 η": ("Typed NbE and η", "η-long βπ-normal forms nf_eta", "morphism representatives of the free cartesian closed category", "bidirectional checking plus type-directed quoting"),
    "依賴型別 NbE（Π/Σ/宇宙）": ("Dependent NbE (Π/Σ/universes)", "η-long dependent normal forms quoted by type; Π/Σ second components are semantic closure families; cumulative Typeᵢ levels", "a categories-with-families (CwF) model: context extension and dependent substitution are closure application", "bidirectional elaboration plus type-directed conversion; equality is normal-form equality; a term-level strengthening case-splits on discrete Bool context variables, difference-guided by the two normal forms and reporting split nodes/probes (recursive decision after both substitutions, dependent types substituted along; Nat variables are never split) without changing kernel conversion"),
    "立方 AST 與維度 NbE": ("Cubical AST and dimension NbE", "separate term/dimension de Bruijn indices in DTerm; line and tube bodies; quoting with dlevel", "a cubical CwF with interval contexts; PathP is the dependent path object and Glue values are (raw/DPartial partial, base) pairs", "bidirectional checking plus Dim/Face simplification and ROBDD semantic predicates"),
    "AST Kan comp/hcomp": ("AST Kan comp/hcomp", "branches are always carried as DSystem; dispatch by type head at a generic dimension; top branches give caps and formal DNComp/DNHComp are the stuck forms; CircleSquareWindingReport records 2D circle boundary windings and H-space gluing status", "every type former preserves Kan fibration structure; hcompU is Glue gluing; the groupoid H-space multiplication on S¹≃K(ℤ,1) and T²≃S¹×S¹ reduces 0~1 endpoint-glued 2D open-box boundaries to an integer 2-cocycle winding conservation condition", "system base/overlap compatibility plus recursion on types; 2D endpoint-glued circle/torus open boxes construct H-space rotation caps at zero net winding and return None on non-zero winding obstructions; coe/fill are segment restrictions of comp"),
    "資料型別與 HIT 消去": ("Data types and HIT elimination", "constructor recursion for Nat/List; Circle loop@r; Torus square@(i,j) modulo opposite-edge identification", "dependent elimination for initial algebras and HITs is a section of the motive and commutes with formal composition", "constructor-pattern recursion, semantic dimension equality, and comp in motives"),
    "持久環境、惰性與語義快取": ("Persistent environments, laziness and semantic caches", "length-carrying persistent lists DEnv/DDimEnv (innermost de Bruijn head); DVThunk is forced at most once; cache keys are simplified dimensions / quoted-term Debug keys; global DTerm hash-consing builds an intern table bottom-up from subterm stamps so structurally equal subterms share one intern id while rebuilt terms stay structurally equal; the intern table also stores child ids per node, DTermDagSnapshot exports that same DAG as local shells plus child-id edges, and CHDAGBIN v1 imports it by per-node hash-consing with added/reused counts", "CwF context extension is cons with a shared tail; lazy values are call-by-need semantic values and memoized families/dimension lines are finite graphs of extensional functions", "environment indexing, force_count and cache-key equality"),
    "依賴語義系統與 partial 值": ("Dependent semantic systems and partial values", "DSystem branches drop ⊥, merge equal bodies by value and sort by quotation; DPartialValue has the BDD effective-region partition DSystemNF", "partial elements in face-lattice slices; multi-branch Glue is a limit-style pairing of a partial type system with a base", "BDD region operations plus type-directed conversion/quotation keys on branch bodies"),
    "通用歸納族 schema": ("Generic inductive-family schemas", "telescopes plus full DTerm argument types (external, direct/nested/functional recursion and constraints); values are DVIntro and neutral eliminations quote by generated case types", "dependent initial algebras of structured strictly positive functors; eliminators are motive sections and comp recurses along earlier argument fillers", "schema structural equality, telescope elaboration, polarity/positivity decision and generated checking"),
    "通用 HIT schema": ("Generic HIT schemas", "cells of arbitrary finite dimension; every endpoint reduces dimensionwise by face expressions; cases are dimensionwise nested PathP", "cellular higher initial algebras with face maps; eliminators preserve cells in every dimension", "face argument/index checks, two-route corner-reduction conversion and semantic dimension equality"),
    "依賴 Kan 線（coe/comp）": ("Dependent Kan lines (coe/comp)", "DLine{at, coe, fill} with comp=fill(1); coe goes backwards in Π domains and along the first-component path in Σ", "a type is a Kan fibration structure; a dependent family is (path)→DLine; together with subspace/Glue lines all project type families are covered", "recursion on type formers; coe(r,r) is definitionally the identity"),
    "精確符號代數": ("Exact symbolic algebra", "multivariate polynomial normal forms over Q (merged, zero-free, sorted); fractions; complex symbolic scalars (re,im)", "matrix algebra over polynomial rings and fraction fields; conjugation is an involution", "polynomial identities / fraction cross-multiplication (exact)"),
    "譜投影與仿射唯一填充": ("Spectral projectors and unique affine filling", "Pₖ=qₖ(A)/qₖ(λₖ); bilinear corner interpolation k00+i k10+j k01+ij k11", "resolutions of the identity and spectral decompositions; bilinearity is tensor gluing of two affine directions", "monic division modulo the minimal polynomial and identities in atoms i,j"),
    "句法笛卡兒閉範疇": ("Syntactic cartesian closed category", "annotated closed arrows, via nf_eta", "the free CCC: universal properties of products and exponentials", "category laws checked by def_eq_eta"),
    "有限宇宙型別與值": ("Finite-universe types and values", "leaf sequences / leaf-value lists", "generated by Bool/Unit under products in the category of finite sets", "tree recursion"),
    "Wiring 符號等價": ("Wiring symbolic equivalences", "signed permutations (Unit outputs are (−1,false))", "morphisms of a free symmetric monoidal category; ⊗, braiding, associators and unitors", "permutation check in O(#leaves); equality is structural equality"),
    "同構、等價、ua、coe": ("Isomorphisms, equivalences, ua and coe", "wirings; coe computes by endpoints", "ua in the finite universe; product swap is a naturality square", "wiring_eq and w;w⁻¹=id"),
    "PathP、離散路徑與 J": ("PathP, discrete paths and J", "canonical PathP elements (far endpoint is a coe image); discrete paths are constant", "dependent path objects; J comes from coe along constant lines being the identity", "endpoint and point checks"),
    "有限 Glue": ("Finite Glue", "(partial, base) pairs; glue_from_base is normalized from the base", "a limit-style construction gluing along equivalences; unglue is the fibration projection", "face_sat plus compatibility equations"),
    "Glue comp（有限線）": ("Glue comp (finite lines)", "outputs (t₁, e₁(t₁))", "the arrow category Ty²: an equivalence line is a morphism and comp is composition along it", "naturality squares by wiring_eq; incoherent data is rejected"),
    "Glue comp（子空間線）": ("Glue comp (subspace lines)", "the k=1 edge of the correction square", "Kan lifting along varying retract lines; the correction is an hcomp", "boundary/cap/membership equations (on grids)"),
    "BDD DAG、預算與 DPLL": ("BDD DAGs, budgets and DPLL", "hash-consed DAG node ids; the reachable-node count of a root is its ROBDD size; LRAT proof steps are indexed LratAdd/LratDelete chains with a CHLRATBN v1 binary representation", "shared canonical graphs of boolean functions at a fixed variable order; apply is a memoized lattice operation, and DRAT→LRAT elaboration lifts satisfiability-preserving traces to locally checkable proof chains", "same-manager root-id equality, sat as root≠0, node-budget FaceDecision, or step-budgeted DPLL (the legacy scanner and the watched-literal engine on Tseitin CNF); candidate-order minimization, bounded sifting, apply-cache doubling rehash, and a 3ⁿ worst-case node bound; CDCL adds 1-UIP clause learning, VSIDS, Luby restarts, LBD clause deletion, DRUP/DRAT checking, backward core trimming, DRAT→LRAT elaboration and linear-time indexed LRAT checking; provably optimal variable orders combine heuristic upper-bound branch-and-bound, cofactor symmetry-orbit pruning (single component up to n≤20) and variable-cooccurrence connected-support decomposition (disjoint support components solved exactly and concatenated; single components above cap report exact=false)"),
    "原始 DSystem 相容性與 first-match 範形": ("Raw DSystem compatibility and first-match normal forms", "compatible systems reuse the type-directed DSystem normal form; arbitrary first-match systems become disjoint effective regions DTubeNF; agreement regions of two values come in both boolean BDD form and a Face-valued form retaining both endpoints, and exact repair truncates branches to the Face-valued agreement without touching endpoints; DSystemDsaturCliqueReport records chromatic upper bounds and max-clique pruning statistics", "partial elements in face-relative slices; the checked constructor is a reflection into the composition-system subclass; the chromatic number χ(G[P]) is a dual upper bound on the clique number ω(G[P])", "local-context conversion enumerates only the dimensions actually mentioned by the branches (irrelevant dimensions are pruned by BDD cofactor structure), checking the base and pairwise overlaps; exact repair and maximum completion enumerate maximum compatible subsystems by exact maximum clique or DSATUR saturation-degree chromatic upper-bound pruning"),
    "AST 一等 Equiv 與 GlueEquiv": ("First-class AST Equiv and GlueEquiv", "DEquiv carries fwd/bwd/sect/retr terms; DVGlueEquiv carries full equivalence branches and (partial, base) pairs", "equivalences in the AST are isomorphisms with homotopy inverse proofs; ua is a functor to universe paths and GlueEquiv glues along systems of partial equivalences", "bidirectional checking of the four components and two PathP proofs; conversion/quotation recurse over equivalence components and branch faces; coe along ua is definitionally fwd/bwd"),
    "受檢查語義型別線": ("Checked semantic type lines", "DCheckedTypeLine stores a checked open type body, contexts, environments and a universe level, never a raw host function", "substitutable cubical type lines are syntactic bodies evaluated in dimension environments and therefore commute with dimension substitution", "the body is checked at a fresh dimension against Typeᵢ; at evaluates by dimension and coe/comp dispatch to AST Kan operations"),
    "Schema 註冊與 elaboration 快取": ("Schema registry and elaboration caches", "DInductivePlan/DHitPlan interned in DSchemaRegistry by stable Debug keys, with telescope prefix chains; the CHREGBIN v2 byte form is magic + version + length + checksum + the DAG DTerm/schema codec payload shared with CHMODBIN v3 (v1 remains readable)", "schema descriptors are shareable plans; caches store only finite graphs of the same elaboration functions and do not change denotation", "validation booleans and semantic telescope prefixes are looked up by (term,args,args) keys; hit/miss counters are observable"),
    "Schema 函子、正性與歸納遞迴": ("Schema functors, positivity and induction-recursion", "the Id/Const/Product/Sum/List/Pi/Container/DecodedFunction/Family/SelfFamily grammar of DPositiveFunctor and its decoded types; DPositivityReport records occurrences and polarities; DFunctorialPositivityCert carries semantic covariant-law or container-isomorphism certificates", "initial algebras of positive type functors with decoded induction hypotheses; DDecode is the decoding function of a Tarski universe; polynomial container isomorphisms Equiv(F X, Σs:S.P(s)→X) give an anti-circular semantic characterization of strictly positive endofunctors", "polarity recursion on alias-expanded DTerms: nested functors and positive positions are accepted, negative positions rejected, and unknown neutral family applications rejected unless backed by a DPositivityDeclaration, a lambda-verified operator, or a kernel-checked semantic certificate (anti-circular container isomorphisms grant strict_args, whereas covariant functor laws alone grant only non-strict positive_args); IHs are generated by functor recursion"),
    "Schema 擴展：互歸納、商與宇宙多態": ("Schema extensions: mutual induction, quotients and universe polymorphism", "the Sum-indexed merged schema of DMutualFamily; level schemes DLevelExpr; quotients are HITs with equality 1-cells", "mutual families are one initial algebra over an index sum; a universe scheme is a function of level assignments; quotients are higher cellular gluing", "mutual constructors compile with component index constraints and eliminate with Σ motives; schemes evaluate on level vectors and can be revalidated; constructor equations are checked as Path constraints"),
    "精確單變量多項式與有理矩陣": ("Exact univariate polynomials and rational matrices", "dense low-to-high QPoly coefficients with trailing zeros removed; QMat rational row lists; RREF and pivot columns", "the Euclidean ring Q[x] and the linear category over Qⁿ; characteristic/minimal polynomials are representation invariants of matrix algebras", "multiplication is sparse-convolution or common-denominator BigInt integer scaling with schoolbook/Karatsuba kernels and binary exponentiation; primitive pseudo-remainder gcd, Yun squarefree factorization, the rational-root theorem, Faddeev–LeVerrier and RREF; all equality is rational structural equality"),
    "代數擴張與根式範形": ("Algebraic extensions and radical normal forms", "QuadNum a+b√d with squarefree d; CubicNum a+b∛m+c∛m² with cubefree m; TriquadNum on the 8-element basis of three squareclass-independent generators; MultiQuadNum on the 16-element basis of up to four generators, aligned by squareclass span; AlgNum remainder polynomials in Q[x]/(m)", "quadratic and general finite algebraic extension fields; norm/trace come from the determinant/trace of multiplication matrices", "residue arithmetic modulo a minimal polynomial and extended-Euclid inversion; multiquadratic inversion by Galois-conjugate products and sign by dyadic interval refinement; radical denesting by square tests; equality is coefficient equality after basis alignment"),
    "廣義特徵空間與 Jordan 理論": ("Generalized eigenspaces and Jordan theory", "nullity chains of powers of (A−λI), Jordan block sizes and chain bases; PJP⁻¹=A", "primary decomposition is a resolution of the identity from coprime polynomial factors; Jordan type is a complete invariant fragment of similarity", "exact decision from characteristic-polynomial multiplicities, kernel dimensions of powers and chain lifting; non-split cases over Q report residual factors and AlgMat continues over extensions"),
    "認證數值影子與精確立方體": ("Certified numeric shadows and exact cubes", "QuadC=QuadNum+i·QuadNum; CertMat and degree-≤2 CertPath/CertSquare coefficients", "exact complex quadratic matrix algebra and polynomial cubes; Double matrices are only approximate representations of exact shadows", "P²=P, P†=P, orthogonal decompositions and box boundaries are checked by exact structural equality; numeric agreement measures only deviation from shadows and floating residuals"),
    "球面與懸掛 HIT": ("Spheres and suspension HITs", "north/south points of parameterized SuspS(A) with one meridian per point a:A; S²=Susp(S¹), S³=Susp(S²); Susp(Bool)≃S¹, Cocone(A,B) and the pointed loop-suspension adjunction (ΣA→*B)≃(A→*ΩB)", "suspension is the homotopy-pushout HIT quotient collapsing both ends of A×I to points, classified by cocone universal property; Σ and Ω form the canonical homotopy adjunction Σ⊣Ω on pointed types", "generic HIT schema validation, meridian endpoint face reduction, dependent elimination and hcomp; 0-connected spaces have trivial suspended fundamental group ‖Ω¹(Susp(A))‖₀≃1 by the 0-connected Freudenthal suspension theorem (instantiating π₁(S²)≃1 and π₁(S³)≃1), complemented by circle wedge-connectivity extension and coherences"),
    "Jacobi 區間譜迭代": ("Jacobi interval spectral iteration", "RatInterval/CInterval rectangular enclosures and dyadically outward-rounded Hermitian interval matrices; every rotation stores before/after matrices and the accumulated unitary transform", "monotone lifting of Hermitian similarity transforms to interval-matrix enclosures; Gershgorin discs give spectral image decompositions and multiplicity clusters", "exact rational square comparisons certify sqrt/phase/c/s enclosures; every rotation recomputes J†J−I∋0 and J†AJ⊆after, and final discs are clustered and counted; eigenvalue clusters are separated by Sturm-counting the squarefree part (Sturm chain with derivative gcd) and matching multiplicities back by unique interval overlap; the interval iteration itself is cluster-aware: Gershgorin clusters are detected during iteration, a cluster penalty biases pivot choice, precision escalates and reruns when insufficient, and a count-2 cluster is separated into disjoint singletons inside the iteration; an adaptive driver switches to exact characteristic-polynomial separation when the Jacobi envelopes stagnate, retaining exact multiplicities"),
    "高階合一與雙向 elaborator": ("Higher-order unification and the bidirectional elaborator", "Miller-pattern spines `?F x₁…xₙ` in UTerm and beta/projection-reduced zonked cores; surface STerm resolves names to de Bruijn UTerm; HouDelayedGraphReport stores delayed Huet flex-flex constraint-graph edges, and HouLazyUnifierStream stores an explicit pull-based continuation stack", "pattern HOU is the decidable fragment of higher-order unification; Huet pre-unification quotients by delayed flex-flex equations and lazy streams unfold the search tree coalgebraically; bidirectional elaboration sends implicit arguments and dependent motives to the same unifier and compiles to the dependent core", "rigid decomposition after WHNF, pattern abstraction, occurs/scope checks, bounded Huet search, three-state Miller-pattern MGU, cross-constraint residual solving, Huet delayed flex-flex graph wake-up and pre-unifier reification, and pull-based lazy normal-form unifier streams"),
    "參數化模組與名字空間": ("Parameterized modules and namespaces", "module telescopes (parameters→imports and local declarations interleaved as ModuleItem entries; the legacy decls-only construction still reads, with all imports front-loaded) with separate name→ordinal bindings; instances are simultaneously substituted closed declarations", "parameterized modules are module functors, import is inlined functor application, and open/alias/rename are name projections of one telescope entry", "cycle detection, dependent checking of parameter arguments, ambiguity rejection for import selection/hiding/renaming, neutralization of opaque exports, and dep_check of every closed instance declaration"),
    "立方體演算法": ("Cubical algorithms", "KanBox packages a line, a system and a base; transport fillers are PathP values; path transitivity is the top edge of an hcomp square; Σ-path splitting, fibration loop equivalences and Stasheff's 5D associahedron K₅ coherence 5-cell", "path-object operations generated by Kan fibration structure in a cubical CwF, fibration loop sequences Ω¹(ΣB P)≃Σ(p:Ω¹B).(subst P p e₀≡e₀) and the K₅ 5-cell classifying five-fold A_∞ loop associativity", "dispatch to kernel coe/comp/fill with endpoint conversion; unit-law 3-cells, Mac Lane pentagon 4-cells and the Stasheff K₅ 5-cell between northern and southern pentagon routes are verified by conversion; closed and open certified equivalences are checked by the dependent checker"),
    "計算性單值性（univalence）": ("Computational univalence", "finite universe paths are normalized by wiring equivalences; dependent universe paths are checked type lines, pathToEquiv is their coe equivalence, ua is the Glue line, uaβ unglues a transport filler, and the round-trips are an Equiv homotopy and a 2D Glue square", "an equivalence (Equiv A B) ≃ Path U A B between the path category of the universe and equivalences; Glue glues along equivalences and transport is its coe functor", "wiring equality in the finite layer; coe/comp computation and type-directed conversion of round-trip endpoints and square edges in the AST layer; closed-term pathToEquiv fill/coe proofs are checked by the dependent checker"),
    "完備精確代數與根隔離": ("Complete exact algebra and root isolation", "BigInt rationals; irreducible factors and multiplicities in Q[x]; exact rational LLL-reduced lattice bases with unimodular transforms U∈GLₙ(ℤ); Van Hoeij power-sum trace-lattice factors; Sturm real-root intervals, disjoint Rouché complex disks and complex algebraic closure elements ComplexAlgNum∈Q̄⊂ℂ; biquadratic numbers and denested radical expressions", "unique factorization in Q[x], GLₙ(ℤ) lattice-reduction orbits, Frobenius/Hensel power-sum trace sublattices and the complex-embedded direct limit of the algebraic closure Q̄⊂ℂ", "certificate fast-path irreducibility, Hensel lifting with Fujiwara-bounded Van Hoeij LLL trace-lattice recombination (avoiding exponential combinatorics on Swinnerton-Dyer polynomials) and Kronecker fallback; Sturm counting, Cauchy/Rouché disk refinement and resultant elimination implement exact field arithmetic, conjugation, nth roots and equality in Q̄⊂ℂ"),
    "一等宇宙多態與同時宣告 schema": ("First-class universe-polymorphic and simultaneous declaration schemas", "level binders and instantiation in DLevelDecl; positive functors extracted after transparent-operator unfolding; iteratively compiled non-uniform nested families; joint mutual, cumulative cross-universe simultaneous IR and Dybjer–Setzer open multi-decoder simultaneous IR DOpenSimultaneousIRSpec", "universe schemes, parameter-iterated initial-algebra families, cumulative Σ joint motives and open synchronous induction-recursion initial algebras over multi-slice fiber categories Famₘ(Type)", "level scope, positivity reports, generated telescopes and dependent conversion; simultaneous IR compiles mutually dependent cross-universe large/small blocks at joint_motive_level = maxᵢ function_universe_level(fᵢ); open multi-decoder simultaneous IR supports validation, code checking, decoding, dependent elimination and single-decoder kernel lowering"),
    "Adjoint 等價、纖維與命題截斷": ("Adjoint equivalences, fibers and propositional truncation", "a triangle Path(Path) over a quasi-inverse; the improved counit; Σ-points of fibers with singleton contraction; the point/squash HIT for PropTrunc; the point/hub/spoke set truncation ‖A‖₀ (SetTruncS) and open-variable bidirectional bijectivity certification DVEquiv", "half-adjoint equivalences, the contractible-fiber characterization of equivalences, and left-adjoint truncation reflections into propositions and into h-sets (0-groupoids)", "adjointify_equiv_value, equiv_bidirectional_certified_in and equiv_contractible_fibers_value construct and check half-adjoint equivalences in open variable contexts; SetTruncS carries an internal h-set proof, universal elimination into arbitrary h-sets, and ‖X‖₀≃B equivalence lifting"),
    "球面同倫代表元與 Hopf 不變量": ("Spherical homotopy representatives and the Hopf invariant", "nested Path types for Ωⁿ; integer degree maps by iterated suspension; the pole-swapped S³ HIT; geometric and internal univalent Hopf fibration H:S²→Type₀ with total space E_Hopf=Σ(x:S²)H(x); canonical IntegerS integers with an internal h-set proof; π₂(S²)=‖Ω²(S²)‖₀ and π₃ quotient presentations", "suspension functors, the fibration loop sequence Ω¹(E_Hopf)≃Σ(p:Ω¹(S²))Path(S¹,subst H p base,base) and the Hopf–Freudenthal identity retraction ∂_Hopf(σ_{S²}(p))≡p along suspended loops", "groupoid laws, Ω² Eckmann–Hilton interchange and pentagon 4-cells verified face by face; the Hopf total-space loop equivalence is bidirectionally certified, and ∂_Hopf(σ_{S²}(p))≡p is proved over an open neutral loop p:Ω¹(S¹), yielding a certified split-retract section from ℤ into π₂(S²) over an open integer variable"),
    "模組分離編譯與連結": ("Separate module compilation and linking", "flattened checked telescopes, exports, dependency fingerprints and public interface projections of CompiledModule; CHMODBIN v1–v3 / TLV envelopes and shared DAG term codecs; topological build plans and incremental relink reports; ArtifactRepository with FIPS 180-4 SHA-256/512, RFC 8032 Pure-Ed25519 CHARTSIG asymmetric sealing, CHWALJRN crash-consistent write-ahead logging and LCA-based three-way merge reports", "compiled objects of module functors, signature-quotient-invariant incremental relinking, read-only public-key verification morphisms, write-ahead atomic commit monads and three-way pushout merges relative to lowest common ancestors", "interface hashes omit opaque bodies so downstream modules skip recompilation and relink via module_instantiate; SHA-256/512 and RFC 8032 Ed25519 enforce anti-forgery and non-malleability; CHWALJRN rolls back uncommitted transactions and torn tails via SHA-256 frame checksums with idempotent replay; three-way merges support convergent edits, tombstone propagation and three conflict policies"),
    "範疇化總檢": ("Categorification checks", "boolean conjunctions of category laws", "identity/composition/coherence laws of the assembled categories", "law-by-law evaluation"),
    "定理登記與範例": ("Theorem registry and examples", "(name, Bool) registry rows; concrete witness vectors/terms", "realizations of decidable propositions on witnesses", "moon test / the registry"),
    "規格登記": ("Specification registry", "SpecEntry six-tuples", "a specification of the specification; completeness is checked against the generated interface", "spec_registry_sound plus this audit"),
    "圓的萬有覆疊與 encode/decode": ("The circle's universal cover and encode/decode", "cover fibres are canonical IntegerS integers over base and ua-line GlueEquiv types over loop points; loop representatives are DVHitCell paths of the schema circle, winding numbers are canonical integer values, and π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ is certified as a DVEquiv", "the helix is a fibration family from the circle to the universe; encode is the endpoint of substitution (path lifting) in the cover, decode is integer elimination into loop powers, and set truncation lifts Ω¹(S¹)≃ℤ to the fundamental-group isomorphism via ℤ being an h-set", "the base fibre is convertible to ℤ at universe level; substitution accumulates winding numbers across composite loops; both homotopies decode(encode(p))≡p and encode(decode(z))≡z are constructed internally in open neutral loop and integer contexts, completing the full internal proofs of Path S¹ base x ≃ Cover(x), Ω¹(S¹)≃ℤ and π₁(S¹)=‖Ω¹(S¹)‖₀≃ℤ"),
    "宿主不透明立方與開盒填充": ("Host-opaque cubes and open-box filling", "cubes are host functions (dimension lists to semantic values / rational-polynomial coordinates) or CheckedDCube terms anchored to typechecked syntax; an open box is boundary data missing one face and the cap is the filler's restriction to that face", "external cubical data over □ with a host implementation of the Kan filling condition, whose natural transformations are determined at the generic diagonal by the cubical Yoneda lemma; polynomial cubes are cubical maps in exact rational coordinates, filled by the iteration F += w·(S − F|face) face by face", "boundary completeness and overlap compatibility are verified face by face by typed conversion / canonical polynomial equality; extensional comparison combines four-tier stratified probes, strength t≤4 orthogonal/covering arrays over P¹(𝔽₈) with a 5-color perfect hash family, a cubical Yoneda naturality/faithfulness audit that rejects non-natural host closures, and exact probe-free generic-dimension reification for CheckedDCube"),
    "輔助工具": ("Utilities", "concrete integer/grid values", "basic set-level utilities", "direct computation"),
}



# ---------------------------------------------------------------------------
# Three-pillar packages added by the federated merger.  The cubical families
# above remain symbol-name driven; imported packages are classified
# package-aware so identical names such as Graph/Rat in different packages do
# not collide semantically.
# ---------------------------------------------------------------------------

FAMILIES.update({
    "有限對稱：圖規範形與自同構": ("規範標號、鄰接編碼與指紋", "簡單無向圖同構類與自同構群作用", "個體化—精煉搜尋一次給規範形與自同構生成元"),
    "有限對稱：置換群與 Schreier–Sims": ("置換像陣列、基與強生成集", "有限集對稱群的子群與陪集分解", "Schreier–Sims 階數、成員、穩定子與有界列舉"),
    "有限對稱：群作用、軌道與 Burnside": ("軌道分割、marks 向量與表", "G-集範疇、誘導/共誘導與 Burnside 環片段", "不動點計數、軌道枚舉與 marks 同構判準"),
    "有限對稱：圖分解、對偶與折疊": ("連通/雙連通分解鍵、補圖與線圖規範形", "圖範疇的分解、補與線圖函子及軌道商", "分解與對偶雙路互校、Whitney 例外檢查"),
    "有限對稱：有限範疇、預層與 Kan 擴展": ("有限合成表、預層限制表與錐列舉", "有限範疇、FinSet 函子、Yoneda 嵌入與左右 Kan 擴展", "範疇/函子公理窮舉與極限/餘極限基數互校"),
    "有限對稱：單子與非確定搜尋": ("ListM/StateM 計算與 Kleisli 箭", "FinSet 上的冪集單子與 Kleisli 範疇", "單子律、自然性與守衛式列舉"),
    "有限對稱：證書、隨機與報告": ("Cert 記錄、確定性 LCG 與對稱報告", "可判定命題在有限見證集上的實現", "prove_graph/prove_pair/prove_all 證書電池"),
    "半環實驗室：半環與么半群 traits": ("trait 方法表、飽和熱帶元素、Pareto 前沿與 Ops 計數", "冪等/星閉/熱帶半環與么半群的型別類階梯", "隨機取樣定律檢查（含近似度量版）"),
    "半環實驗室：泛型矩陣與星閉包": ("row-major 稠密矩陣與 CSR 三元組正規序", "半環矩陣範疇與 Kleene 星閉包", "多種乘法/閉包實作逐元互校與操作計數"),
    "半環實驗室：么半群聚合": ("仿射函數、Fenwick 樹、稀疏表與掃描結果", "么半群作用與函數合成的結合聚合", "暴力前綴/區間查詢差分互校"),
    "半環實驗室：加權有向圖": ("CSR 出邊列與熱帶距離矩陣", "加權有向圖的路徑半環與豐富範疇片段", "Dijkstra、Kleene 星、位元閉包與 Pareto 仲裁"),
    "半環實驗室：樣條": ("均勻節點、帶狀系統與 de Boor 求值點", "仿射遞迴的么半群掃描與分段多項式函數", "插值性質、稠密/帶狀求解互校與極點量測"),
    "半環實驗室：熱帶幾何": ("Newton 凸包、根及其重數、對偶細分面", "熱帶曲線與普通代數曲線的對偶/去量子化片段", "括號重合、balancing 殘差與熱帶行列式仲裁"),
    "半環實驗室：正則與冪等正規形": ("ACI 正規式、最小 DFA 與單項式排序集", "正則語言與自由冪等半環的範疇/代數表達式", "Brzozowski 導數、DFA 等價與字串枚舉互校"),
    "半環實驗室：集合值矩陣、自由範疇與去量子化": ("路徑證人集、DAG 路徑與 ε-變形矩陣", "集合值矩陣的豐富範疇、圖的自由範疇與 Maslov 去量子化", "路徑列舉/DP/矩陣冪/Lehmann 四路互校"),
    "半環實驗室：代數路徑問題": ("邊三元組矩陣與多候選 Run/Verdict", "以星半環統一的最短/可達/瓶頸/計數路徑問題", "專用算法與泛型閉包多數決仲裁"),
    "半環實驗室：因子圖推論": ("因子表、訊息與邊際矩陣", "因子圖上的半環訊息傳遞與廣義分配律", "樹上 BP 對暴力邊際、環上不保證精確"),
    "半環實驗室：限流應用": ("TAT、理論到達列與有界鍵表", "偏序時間窗上的單調配額更新", "虛擬時鐘事件重播、上下界與淘汰檢查"),
    "半環實驗室：邊表輸入": ("原始邊位元組與剖析後三元組", "圖資料的具體表示與載入函數", "快速/朴素剖析器逐邊互校與吞吐量測"),
    "半環實驗室：量測與快取模擬": ("存取追蹤、快取組與時鐘讀數", "記憶階層的有限狀態模型", "真實存取探針輸入模擬器並比較策略"),
    "半環實驗室：平行接縫": ("分塊區間、掃描樹與 shard I/O 描述", "結合聚合在工作/深度模型下的後端接縫", "序行 oracle 互校；非原生 target 明示序行後端"),
    "半環實驗室：原生宿主後端": ("結構化 async 任務與分片讀取結果", "原生宿主效果在平行接縫之下封裝", "僅 native 編譯與測試，其餘 target 整包跳過"),
    "半環實驗室：範例": ("可編譯教學範例的輸出值", "半環支柱各構造的具體見證", "範例白盒測試"),
    "半環實驗室：量測報告": ("章節函數輸出的量測表與裁決摘要", "半環支柱各演算法在原生主機上的可重現量測敘事", "native 慢閘門完整重跑並保存輸出快照；永不進快速閘門"),
    "三方橋接": ("跨支柱轉換後的規範矩陣、圖、範疇或統一證書", "cubical、有限對稱與半環路徑代數之間的顯式橋接構造", "每一橋接均以來源支柱的判定器重驗"),
    "拓撲斯：景、篩、Grothendieck 拓撲與預層": ("排序無重態射篩、覆蓋篩閉包、自然變換分量表與相容匹配族", "小範疇景 (C,J)、米田嵌入 C↪PSh(C) 與預層極限／餘極限雙完備結構", "篩右理想律、Grothendieck 拓撲三公理（極大／穩定／傳遞）與一般米田雙射窮舉檢驗"),
    "拓撲斯：層化、笛卡兒閉性、子物件分類子與一般拓撲斯": ("J-閉篩真值格 Ω_J、兩步 Grothendieck Plus 層化 a(P)=(P^+)^+ 與米田指數 G^F", "Grothendieck 層拓撲斯 Sh(C,J)、笛卡兒閉結構、子物件分類子拉回與 Lawvere–Tierney 子拓撲斯雙射", "分離／黏合層條件、層化泛性質、CCC 柯里化同構、特徵態射拉回與 Giraud 不交餘積穩定性判定"),
    "拓撲斯：幾何態射、局部／連通／原子／緊緻相干性質": ("左正合逆像 f^*=a∘Lan_{u^{op}}、右伴隨直像 f_*、平坦張量點函子與局部焦點", "幾何態射伴隨 f^*⊣f_*、局部 Topos 三重伴隨 Δ⊣Γ⊣Γ^!、π_0 連通性、原子 Galois 群胚與相干緊緻覆蓋", "伴隨雙射、左正合極限保持、Diaconescu 點平坦／覆蓋保持判準、局部／連通／原子／De Morgan／Boolean 性質檢定"),
    "拓撲斯：幾何邏輯規範形式、分類 Topos 與範疇化": ("Joyal–Reyes 析取存在合取幾何規範形 ⋁∃⋀、伴隨量詞 Σ_f⊣f^*⊣Π_f 與命題分類景", "Kripke–Joyal 層語義、分類 Topos B(T)（Pt(B(T))≃Mod_Set(T)）與元素範疇範疇化 PSh(C)/P≃PSh(∫P)", "Kripke–Joyal 強迫語義、幾何規範形等價性、Beck–Chevalley 正合方塊、分類 Topos 點與模型雙射及切片範疇化檢驗"),
    "拓撲斯：廣群棧、下降理論、層上同調與同倫類型": ("Čech 下降上閉鏈 g_{ij}·g_{jk}=g_{ik}、Roos／單純上鏈複形與整數 Smith 撓率不變因子", "纖維化廣群棧與 G-主叢下降、有理阿貝爾層上同調 H^•(C;F)、蛇引理長正合序列與神經同倫類型", "2-範疇下降上閉鏈相容、有效下降黏合雙射、d^{n+1}∘d^n=0、Euler–Poincaré 恆等式、蛇引理連接同態正合性與 Betti／π_1 計算"),
    "拓撲斯：第2輪結構導出演算法（本徵三重伴隨、開閉子拓撲斯核、稠密比較引理、內蘊主叢與杯積環）": ("右 Kan 擴展預層 Ran_{u^{op}}、開閉 Lawvere–Tierney 核算子 j_o/j_c、誘導子景拓撲 J_C、內蘊置換群作用與 Alexander–Whitney 2-上鏈杯積", "本徵幾何態射 Lan_{u^{op}}⊣u^*⊣Ran_{u^{op}}、餘 Heyting 開閉子拓撲斯互補分解、Grothendieck–Verdier 稠密子景 Morita 等價、Diaconescu 內蘊 G-主叢層與分次微分代數 H^•(U;Q)", "三重伴隨 Hom 雙射、無排中律下 J_o∧J_c=J_triv 與 J_o∨J_c=J_⊥ 互補、稠密層重構同構、剪映射雙射 T×G≅T×T 與 Koszul 符號 Leibniz 律及 T^2 對 S^1∨S^1∨S^2 杯積秩區分"),
    "概形：多元多項式、約化 Gröbner 基規範形與根理想": ("稀疏規範多元多項式 MPoly、單ic 完全互約 Gröbner 基與標準單項式商基底", "多元多項式環 Q[x_1,…,x_n] 上的理想運算（和／積／交／商／飽和／消元／根理想）", "Buchberger S-多項式演算法、多元除法餘式唯一性、Rabinowitsch 根理想成員與 Hilbert–Krull 維數判定"),
    "概形：座標環、Zariski 層化、既約概形與準凝聚模": ("模約化 Gröbner 基商餘式規範形、主開集局部化截面 a/f^m 與冪零根簡化理想 √I", "仿射概形 Spec(Q[x]/I)、Zariski 結構層 O_X、既約伴隨概形 X_red↪X 與準凝聚模局部化範疇", "Zariski 開覆蓋 1∈⟨f_i⟩ 單位分解、局部截面相容與全局多項式黏合唯一性、冪零見證搜尋與既約泛性質檢驗"),
    "概形：黏合概形、概形態射、仿射態射與 DVR 真概形": ("局部仿射圖冊 (U_i,U_{ij})、圖冊回拉同態環圖與截斷形式 Laurent 級數 Q((t)) 賦值展開", "一般黏合概形範疇 Sch/Q（A^n, P^n, 射影閉子概形, A^2\\0, 雙重原點線）、纖維積、仿射態射與對角浸入 Δ_X", "上閉鏈黏合相容、仿射開逆像覆蓋局部性、對角閉浸入分離性與離散賦值環 Q[[t]]⊂Q((t)) 真概形唯一延拓判準"),
    "概形：有理等價、對偶複形、點函子法與動機範疇化": ("P^1 正規化 Weil 除子與有理等價類 CH^1、P^1/P^2/平面曲線 Čech 上同調維數、雙齊次對應理想與有限交換環點集", "有理函數主除子商群、Grothendieck–Serre 對偶複形 ω_{P^1}≅O(-2)[1]／ω_{P^2}≅O(-3)[2]／ω_C≅O_C(d-3)[1]、米田點函子 h_X:CRing→Set 與多射影 Gröbner Chow 對應動機範疇", "有理等價顯式函數 f/g 構造、局部重數 Bézout 定理、Riemann–Roch 與 Serre 對偶配對、F_p[ε] 切空間維數與 6 變元 Gröbner 飽和消元 h(P^1)=1⊕L 動機分解檢驗"),
    "概形：第2輪結構導出演算法（Kähler 微分、平展判準、Hilbert 多項式、爆炸奇點解消與 Frobenius 下降）": ("Kähler 微分呈現矩陣 Ω^1_{B/A}、零階 Fitting 與 Jacobi 子式理想、符號 Hilbert 多項式 P_X(t)∈Q[t]、雙圖冊嚴格變換概形與二次有限域 F_{p^2} 乘法表", "相對微分模與無分歧／光滑／平展態射、Tjurina 孤立奇點代數 τ(X)、任意餘維射影度數與算術虧格、Rees 爆炸 Bl_{(0,0)}(A^2) 奇點解消及 Galois–Frobenius 點計數下降", "Fitting 零化 1∈Fitt_0(Ω^1) 局部化交換性、Macaulay 初理想容斥與齊次單項式計數互校、Gröbner 飽和嚴格變換光滑性與例外纖維既約性區分及 F_3⊂F_9 算術有理點跳躍檢驗"),
    "六支柱大一統：邏輯理論轉譯與幾何邏輯精細圖譜": ("跨立方類型論／Topos／概形／熱帶半環之規範形與幾何公式轉譯及 18 項精細圖譜條目", "Glivenko ¬¬ 稠密布林子拓撲斯、Stone–Zariski 分類景對偶、Kapranov 熱帶賦值、平展主叢 Galois 橋、子拓撲斯與爆炸切除橋及 S^1/P^1/Galois/動機六支柱合成", "跨支柱語義保持、見證與反例雙向非平凡檢驗及 30 項統一大一統證書全數實算裁決"),
})

FAMILIES_EN.update({
    "有限對稱：圖規範形與自同構": ("Finite symmetry: graph canonical forms and automorphisms", "canonical labelings, adjacency encodings and fingerprints", "isomorphism classes of simple undirected graphs and automorphism actions", "one individualization-refinement search returns a canonical form and automorphism generators"),
    "有限對稱：置換群與 Schreier–Sims": ("Finite symmetry: permutation groups and Schreier-Sims", "permutation image arrays, bases and strong generating sets", "subgroups and coset decompositions of finite symmetric groups", "Schreier-Sims order, membership, stabilizers and bounded enumeration"),
    "有限對稱：群作用、軌道與 Burnside": ("Finite symmetry: group actions, orbits and Burnside theory", "orbit partitions, mark vectors and tables of marks", "the category of G-sets, induction/coinduction and a Burnside-ring fragment", "fixed-point counts, orbit enumeration and the marks isomorphism criterion"),
    "有限對稱：圖分解、對偶與折疊": ("Finite symmetry: graph decomposition, duality and folding", "connected/biconnected decomposition keys, complement and line-graph forms", "decomposition, complement and line-graph functors plus orbit quotients", "two-way decomposition/duality cross-checks and Whitney-exception checks"),
    "有限對稱：有限範疇、預層與 Kan 擴展": ("Finite symmetry: finite categories, presheaves and Kan extensions", "finite composition tables, presheaf restriction tables and cone enumerations", "finite categories, FinSet-valued functors, the Yoneda embedding and left/right Kan extensions", "exhaustive category/functor axioms and limit/colimit cardinal cross-checks"),
    "有限對稱：單子與非確定搜尋": ("Finite symmetry: monads and nondeterministic search", "ListM/StateM computations and Kleisli arrows", "the powerset monad on FinSet and Kleisli categories", "monad laws, naturality and guarded enumeration"),
    "有限對稱：證書、隨機與報告": ("Finite symmetry: certificates, randomness and reports", "Cert records, a deterministic LCG and symmetry reports", "realizations of decidable propositions on finite witnesses", "the prove_graph/prove_pair/prove_all certificate batteries"),
    "半環實驗室：半環與么半群 traits": ("Semiring lab: semiring and monoid traits", "trait method tables, saturated tropical elements, Pareto fronts and Ops counters", "a type-class ladder of idempotent/star/tropical semirings and monoids", "sampled law checkers, including an approximate-metric variant"),
    "半環實驗室：泛型矩陣與星閉包": ("Semiring lab: generic matrices and star closure", "row-major dense matrices and normalized CSR triplets", "matrix categories over semirings and Kleene star closure", "entrywise cross-checks of multiplication/closure implementations and operation counts"),
    "半環實驗室：么半群聚合": ("Semiring lab: monoid aggregation", "affine maps, Fenwick trees, sparse tables and scan outputs", "associative aggregation by monoid actions and function composition", "differential checks against brute-force prefix/range queries"),
    "半環實驗室：加權有向圖": ("Semiring lab: weighted directed graphs", "CSR out-edge rows and tropical distance matrices", "path semirings and enriched-category fragments of weighted digraphs", "Dijkstra, Kleene star, bitset closure and Pareto arbitration"),
    "半環實驗室：樣條": ("Semiring lab: splines", "uniform knots, banded systems and de Boor evaluations", "monoid scans of affine recurrences and piecewise-polynomial functions", "interpolation properties, dense/banded solver cross-checks and pole measurements"),
    "半環實驗室：熱帶幾何": ("Semiring lab: tropical geometry", "Newton hulls, roots with multiplicities and dual subdivision faces", "tropical curves and duality/dequantization fragments of algebraic curves", "tie, balancing-residual and tropical-determinant arbitration"),
    "半環實驗室：正則與冪等正規形": ("Semiring lab: regular and idempotent normal forms", "ACI normal forms, minimal DFAs and sorted monomial sets", "regular languages and expressions in free idempotent semirings", "Brzozowski derivatives, DFA equivalence and string-enumeration checks"),
    "半環實驗室：集合值矩陣、自由範疇與去量子化": ("Semiring lab: set-valued matrices, free categories and dequantization", "sets of path witnesses, DAG paths and epsilon-deformed matrices", "set-valued enriched matrices, free categories on graphs and Maslov dequantization", "path enumeration/DP/matrix powers/Lehmann four-way arbitration"),
    "半環實驗室：代數路徑問題": ("Semiring lab: algebraic path problems", "edge-triplet matrices and multi-candidate Run/Verdict records", "shortest/reachable/widest/counting path problems unified by star semirings", "majority arbitration between specialized algorithms and generic closure"),
    "半環實驗室：因子圖推論": ("Semiring lab: factor-graph inference", "factor tables, messages and marginal matrices", "semiring message passing and the generalized distributive law on factor graphs", "tree belief propagation against brute-force marginals; loops are not exactness-guaranteed"),
    "半環實驗室：限流應用": ("Semiring lab: rate limiting application", "TAT values, theoretical arrival rows and bounded key tables", "monotone quota updates over ordered time windows", "virtual-clock event replay, bound and eviction checks"),
    "半環實驗室：邊表輸入": ("Semiring lab: edge-list input", "raw edge bytes and parsed triplets", "concrete representations and loaders of graph data", "fast/naive parser entrywise arbitration and throughput measurement"),
    "半環實驗室：量測與快取模擬": ("Semiring lab: measurement and cache simulation", "access traces, cache sets and clock readings", "finite-state models of a memory hierarchy", "real access probes drive the simulator and strategies are compared"),
    "半環實驗室：平行接縫": ("Semiring lab: parallel seam", "chunk intervals, scan trees and shard-I/O descriptions", "a backend seam for associative aggregation under work/depth models", "serial-oracle checks; non-native targets honestly report the serial backend"),
    "半環實驗室：原生宿主後端": ("Semiring lab: native host backend", "structured async tasks and sharded read results", "native host effects encapsulated below the parallel seam", "compiled and tested only on native; skipped as a whole package elsewhere"),
    "半環實驗室：範例": ("Semiring lab: examples", "outputs of compilable teaching examples", "concrete witnesses for constructions in the semiring pillar", "white-box example tests"),
    "半環實驗室：量測報告": ("Semiring lab: measured report", "measurement tables and verdict summaries emitted by section functions", "a reproducible native-host measurement narrative for algorithms in the semiring pillar", "rerun completely as a native slow gate and archive the output snapshot; never part of the fast gate"),
    "三方橋接": ("Three-way bridges", "canonical matrices, graphs, categories or unified certificates after cross-pillar conversion", "explicit bridge constructions between cubical paths, finite symmetry and semiring path algebra", "every bridge is rechecked by decision procedures from its source pillars"),
    "拓撲斯：景、篩、Grothendieck 拓撲與預層": ("Topos: sites, sieves, Grothendieck topologies and presheaves", "sorted deduplicated morphism sieves, covering-sieve closures, natural-transformation component tables and matching families", "small sites (C, J), the Yoneda embedding C ↪ PSh(C) and bicomplete presheaf limits/colimits", "sieve right-ideal laws, the three Grothendieck topology axioms (maximal/stability/transitivity) and exhaustive general Yoneda bijection checks"),
    "拓撲斯：層化、笛卡兒閉性、子物件分類子與一般拓撲斯": ("Topos: sheafification, cartesian closedness, subobject classifiers and elementary toposes", "J-closed sieve Heyting lattices Ω_J, two-step Grothendieck Plus sheafification a(P)=(P^+)^+ and Yoneda exponentials G^F", "Grothendieck sheaf toposes Sh(C, J), cartesian closed structure, subobject-classifier pullbacks and the Lawvere–Tierney subtopos bijection", "separated/gluing sheaf conditions, sheafification universal property, CCC currying isomorphisms, characteristic pullback squares and Giraud disjoint-coproduct stability"),
    "拓撲斯：幾何態射、局部／連通／原子／緊緻相干性質": ("Topos: geometric morphisms and local/connected/atomic/compact-coherent properties", "left-exact inverse images f^* = a ∘ Lan_{u^{op}}, right-adjoint direct images f_*, flat tensor point functors and focal points", "geometric morphism adjunctions f^* ⊣ f_*, local-topos triple adjunctions Δ ⊣ Γ ⊣ Γ^!, π_0 connectedness, atomic Galois groupoids and coherent compact coverings", "adjunction hom-bijections, finite-limit preservation, Diaconescu flat/cover-preserving point criteria, and local/connected/atomic/De Morgan/Boolean property checks"),
    "拓撲斯：幾何邏輯規範形式、分類 Topos 與範疇化": ("Topos: geometric normal forms, classifying toposes and categorification", "Joyal–Reyes disjunctive-existential-conjunctive normal forms ⋁∃⋀, adjoint quantifiers Σ_f ⊣ f^* ⊣ Π_f and propositional classifying sites", "Kripke–Joyal sheaf semantics, classifying toposes B(T) with Pt(B(T)) ≃ Mod_Set(T), and category-of-elements categorification PSh(C)/P ≃ PSh(∫P)", "Kripke–Joyal forcing, geometric normal-form soundness, Beck–Chevalley exact squares, classifying-topos point/model bijections and slice categorification checks"),
    "拓撲斯：廣群棧、下降理論、層上同調與同倫類型": ("Topos: groupoid stacks, descent, sheaf cohomology and homotopy types", "Čech descent cocycles g_{ij}·g_{jk}=g_{ik}, Roos/simplicial cochain complexes over Q and integer Smith torsion invariant factors", "fibered groupoid stacks and G-torsor descent, rational abelian sheaf cohomology H^•(C; F), Snake-lemma long exact sequences and simplicial nerve homotopy types", "2-categorical cocycle coherence, effective descent bijections, d^{n+1}∘d^n = 0, Euler–Poincaré identities, Snake connecting-homomorphism exactness and Betti/π_1 computation"),
    "拓撲斯：第2輪結構導出演算法（本徵三重伴隨、開閉子拓撲斯核、稠密比較引理、內蘊主叢與杯積環）": ("Topos: Round-2 structural derivations (essential triple adjunctions, open/closed subtopos nuclei, dense Comparison Lemma, internal torsors and cup-product ring)", "right Kan presheaves Ran_{u^{op}}, open/closed Lawvere–Tierney nuclei j_o/j_c, induced dense subsite topologies J_C, internal permutation-group actions and Alexander–Whitney 2-cochain cup products", "essential geometric morphisms Lan_{u^{op}} ⊣ u^* ⊣ Ran_{u^{op}}, co-Heyting open/closed subtopos complementarity, Grothendieck–Verdier dense site Morita equivalence, Diaconescu internal G-torsor sheaves and multiplicative DG-algebras H^•(U; Q)", "triple-adjunction hom bijections, J_o ∧ J_c = J_triv & J_o ∨ J_c = J_⊥ complementarity without internal LEM, dense sheaf reconstruction, shear bijections T × G ≅ T × T and Koszul-signed Leibniz rules separating T^2 from S^1 ∨ S^1 ∨ S^2"),
    "概形：多元多項式、約化 Gröbner 基規範形與根理想": ("Schemes: multivariate polynomials, reduced Gröbner normal forms and radical ideals", "sparse canonical multivariate polynomials MPoly, monic interreduced Gröbner bases and standard-monomial quotient bases", "ideal calculus over Q[x_1,…,x_n] (sum, product, intersection, colon quotient, saturation, elimination and radical)", "Buchberger's S-polynomial algorithm, unique multivariate normal-form remainders, Rabinowitsch radical membership and Hilbert–Krull dimension"),
    "概形：座標環、Zariski 層化、既約概形與準凝聚模": ("Schemes: coordinate rings, Zariski sheafification, reduced schemes and quasi-coherent modules", "normal-form quotient remainders modulo reduced Gröbner bases, localized principal-open sections a/f^m and radical ideals √I", "affine schemes Spec(Q[x]/I), Zariski structure sheaves O_X, associated reduced closed immersions X_red ↪ X and localized quasi-coherent modules", "Zariski partition-of-unity cover tests 1 ∈ ⟨f_i⟩, compatible section gluing uniqueness, nilpotent witness search and reduced universal-property checks"),
    "概形：黏合概形、概形態射、仿射態射與 DVR 真概形": ("Schemes: glued schemes, scheme morphisms, affine morphisms and DVR properness", "affine chart atlases (U_i, U_{ij}), chartwise pullback ring homomorphisms and truncated formal Laurent series in Q((t))", "glued schemes over Q (A^n, P^n, projective closed subschemes, A^2\\0, doubled-origin line), fiber products, affine morphisms and diagonal immersions Δ_X", "cocycle gluing coherence, chart-local affine preimage tests, diagonal closed-immersion separatedness and the Q[[t]] ⊂ Q((t)) DVR valuative criterion of properness"),
    "概形：有理等價、對偶複形、點函子法與動機範疇化": ("Schemes: rational equivalence, dualizing complexes, functor of points and motivic categorification", "normalized Weil divisors and Chow classes CH^1(P^1), P^1/P^2/plane-curve Čech cohomology ranks, bihomogeneous correspondence ideals and finite-ring point sets", "principal divisor quotients, Grothendieck–Serre dualizing complexes ω_{P^1} ≅ O(-2)[1], ω_{P^2} ≅ O(-3)[2] and ω_C ≅ O_C(d-3)[1], Yoneda functors of points h_X : CRing → Set and multi-projective Gröbner Chow motives", "explicit rational-equivalence witnesses f/g, local-multiplicity Bézout verification, Riemann–Roch & Grothendieck–Serre duality pairings, F_p[ε] Zariski tangent dimensions and 6-variable Gröbner saturation/elimination h(P^1) = 1 ⊕ L motivic splitting"),
    "概形：第2輪結構導出演算法（Kähler 微分、平展判準、Hilbert 多項式、爆炸奇點解消與 Frobenius 下降）": ("Schemes: Round-2 structural derivations (Kähler differentials, étale criteria, Hilbert polynomials, blow-up desingularization and Frobenius descent)", "Kähler presentation matrices Ω^1_{B/A}, zeroth Fitting and Jacobian minor ideals, symbolic Hilbert polynomials P_X(t) ∈ Q[t], two-chart strict-transform schemes and quadratic finite fields F_{p^2}", "relative Kähler differential modules and unramified/smooth/étale morphisms, Tjurina isolated-singularity algebras τ(X), arbitrary-codimension projective degree & arithmetic genus, Rees blow-up Bl_{(0,0)}(A^2) desingularization and Galois–Frobenius point-count descent", "Fitting vanishing 1 ∈ Fitt_0(Ω^1) under localization, Macaulay initial-ideal inclusion-exclusion vs homogeneous monomial counts, Gröbner-saturated strict-transform smoothness & reduced vs non-reduced exceptional fibers, and F_3 ⊂ F_9 rational-point jump checks"),
    "六支柱大一統：邏輯理論轉譯與幾何邏輯精細圖譜": ("Six-pillar grand unification: logical theory translations and geometry-logic correspondence atlas", "cross-pillar normal forms, translated geometric formulas/ideals, Double-V & X-Overlap chiasm reports, complete K_6 (15/15) federation bridges and the 18-entry fine-grained geometry-logic correspondence atlas", "Glivenko ¬¬ dense Boolean subtoposes, Stone–Zariski classifying dualities, Kapranov tropical valuations, quadratic étale torsor Galois bridges, subtopos/blow-up excision bridges, Condensed Steenrod–Adams ↔ Brunerie & Double-V synthesis", "cross-pillar semantic preservation, non-tautological witness/contrast pairs and live verification of all 43 unified certificates"),
    "下V泛消元新最大公因數（@gcd）": ("Lower-V Universal Elimination-GCD (@gcd)", "F_p reduced row echelon form (RREF), integer Hermite & Smith Normal Form invariant factors, monic polynomial remainders and multi-generator Bézout linear-combination certificates", "greatest-lower-bound lattice induced by elimination across integers, F_p[x] polynomials, F_p linear subspaces, Z-lattices and multi-generator principal ideals", "extended Euclidean algorithm, double-annihilator subspace intersection verifying dim(U∩W)+dim(U+W)=dim U+dim W, unimodular U·A·V=D decomposition and Bézout certificate verification"),
    "X形交疊凝聚數學、凝聚高階結構×4、範疇×2與新猜想（@condensed）": ("X-Overlap Condensed Mathematics, 4 Condensed Higher Structures, 2 Categories & 4 Conjectures (@condensed)", "profinite inverse-tower surjection matrices, free solid modules Z[S]^■, minimal Steenrod A(2) resolutions, bigraded spectral-sequence pages, idempotent canonical normalizers and hash-chained invariant ledgers", "CondCategory (extremally disconnected sheaf descent & solidification left-adjoint reflector), CanonElimCategory, CondAnima (Milnor lim^1), CondSolidModule (solid gap & p-liquid norm), CondSpectralSheaf (Twisted AHSS + Čech obstruction) and CondAnalyticStack (Huber–Tropical–P^1–Topos bipolar stack)", "Mittag-Leffler rank stabilization vs cokernel torsion growth, 0<p≤1 liquid subadditivity, Adem reduction & Ext_A^{2,3}(F_2,F_2)=0 (certifying 2η=0), Čech obstruction k^1-r^0, automatic SNF conservation-law derivation and finite/counterexample evaluation of 4 conjectures"),
    "第七聯邦：多線性超行列式、離散 Radon 變換、Clifford 旋量規範場與 VR 持續同調（@tensor）": ("Federation 7: Multilinear hyperdeterminants, discrete Radon transform, Clifford spinor gauge fields & VR persistent homology (@tensor)", "exhaustive F_3 6,561-tensor rank & Cayley hyperdeterminant tables, finite-plane incidence matrices & Sherman–Morrison inverses, Jordan–Wigner gamma matrices & T^2 holonomy classes, non-crossing chord bitmasks and full-dimension VR simplicial boundary complexes", "SL_2^3 × S_3 multilinear invariants, finite-geometric integral duality, twisted group algebra symplectic-radical centers & discrete torsor moduli, non-crossing forest Grothendieck sites, Kalton–Ostrovskii correspondence distortion and Viro–Krasner tropical hyperfields", "O(|R_1|^2) exact rank partition [1,128,5568,864], affine-corrected Plancherel energy law, even/odd spinor center splitting, [T-NC-Free] cyclic-monotone freedom vs K_4 counterexample, and independent homology-cohomology rank duality"),
    "第七聯邦：Lakatos 十二猜想演化圖譜、守恆律自動發現與五大認識論透鏡（@conjecture）": ("Federation 7: Lakatosian 12-conjecture evolution atlas, automatic conservation-law discovery & 5 epistemic lenses (@conjecture)", "F_p nullspace pairwise-saturated integer relation bases on observation trajectories, 5-predicate implication closures & minimal counterexample matrices, 5-state Lakatosian conjecture lifecycles and hash-chained ledger records", "out-of-sample evolutionary invariant functor [E-Derive]+[P-Transfer], Relative/Dual/Contrast/Implication/ScaleRatio epistemic lenses and Seven-Federation K_7 Star-Prism unification", "automatic discovery of 6 evolutionary conservation laws with small-scale mirage rejection (including cubic-to-quartic Hironaka–Serre curve genus transfer), 5 counterexample refutations paired with refined theorems, and machine verification of all 12 conjectures (CONJ-01..12)"),
})

PACKAGE_FAMILY = {
    "gcd": "下V泛消元新最大公因數（@gcd）",
    "condensed": "X形交疊凝聚數學、凝聚高階結構×4、範疇×2與新猜想（@condensed）",
    "tensor": "第七聯邦：多線性超行列式、離散 Radon 變換、Clifford 旋量規範場與 VR 持續同調（@tensor）",
    "conjecture": "第七聯邦：Lakatos 十二猜想演化圖譜、守恆律自動發現與五大認識論透鏡（@conjecture）",
    "semiring-algebra": "半環實驗室：半環與么半群 traits",
    "semiring-matrix": "半環實驗室：泛型矩陣與星閉包",
    "semiring-monoid": "半環實驗室：么半群聚合",
    "semiring-graph": "半環實驗室：加權有向圖",
    "semiring-spline": "半環實驗室：樣條",
    "semiring-trop": "半環實驗室：熱帶幾何",
    "semiring-nf": "半環實驗室：正則與冪等正規形",
    "semiring-cat": "半環實驗室：集合值矩陣、自由範疇與去量子化",
    "semiring-app": "半環實驗室：代數路徑問題",
    "semiring-bp": "半環實驗室：因子圖推論",
    "semiring-ratelimit": "半環實驗室：限流應用",
    "semiring-io": "半環實驗室：邊表輸入",
    "semiring-sim": "半環實驗室：量測與快取模擬",
    "semiring-par": "半環實驗室：平行接縫",
    "semiring-par-host": "半環實驗室：原生宿主後端",
    "cmd-semiringreport": "半環實驗室：量測報告",
}

TOPOS_SITE = "拓撲斯：景、篩、Grothendieck 拓撲與預層"
TOPOS_SHEAF = "拓撲斯：層化、笛卡兒閉性、子物件分類子與一般拓撲斯"
TOPOS_GEOM = "拓撲斯：幾何態射、局部／連通／原子／緊緻相干性質"
TOPOS_LOGIC = "拓撲斯：幾何邏輯規範形式、分類 Topos 與範疇化"
TOPOS_STACK = "拓撲斯：廣群棧、下降理論、層上同調與同倫類型"
TOPOS_DERIVED = "拓撲斯：第2輪結構導出演算法（本徵三重伴隨、開閉子拓撲斯核、稠密比較引理、內蘊主叢與杯積環）"

TOPOS_TYPE_FAMILY = {
    "Sieve": TOPOS_SITE, "GrothendieckTopology": TOPOS_SITE, "Site": TOPOS_SITE,
    "PresheafHom": TOPOS_SITE, "MatchingFamily": TOPOS_SITE,
    "SheafificationResult": TOPOS_SHEAF, "ExponentialData": TOPOS_SHEAF,
    "SubobjectClassifierData": TOPOS_SHEAF,
    "FlatPointFunctor": TOPOS_GEOM,
    "LocalToposReport": TOPOS_GEOM, "ConnectedToposReport": TOPOS_GEOM,
    "AtomicToposReport": TOPOS_GEOM, "CompactCoherentReport": TOPOS_GEOM,
    "Subpresheaf": TOPOS_LOGIC, "GeoAtom": TOPOS_LOGIC, "GeoFormula": TOPOS_LOGIC,
    "GeoSequent": TOPOS_LOGIC, "GeometricTheory": TOPOS_LOGIC,
    "SheafStructure": TOPOS_LOGIC, "GeoConjClause": TOPOS_LOGIC,
    "GeoNormalForm": TOPOS_LOGIC, "PropGeoAxiom": TOPOS_LOGIC,
    "PropGeoTheory": TOPOS_LOGIC, "ClassifyingToposData": TOPOS_LOGIC,
    "SliceCategoryData": TOPOS_LOGIC,
    "FiniteGroupoid": TOPOS_STACK, "GroupoidFibration": TOPOS_STACK,
    "CoverDescentDiagram": TOPOS_STACK, "DescentDatum": TOPOS_STACK,
    "RectQMat": TOPOS_STACK, "CochainComplexQ": TOPOS_STACK,
    "AbelianPresheafQ": TOPOS_STACK, "SimplicialNerve": TOPOS_STACK,
    "HomotopyTypeSummary": TOPOS_STACK,
    "SubtoposComplementReport": TOPOS_DERIVED,
    "InternalGroupTorsor": TOPOS_DERIVED,
}

SCHEME_GB = "概形：多元多項式、約化 Gröbner 基規範形與根理想"
SCHEME_SHEAF = "概形：座標環、Zariski 層化、既約概形與準凝聚模"
SCHEME_MORPH = "概形：黏合概形、概形態射、仿射態射與 DVR 真概形"
SCHEME_CYCLE = "概形：有理等價、對偶複形、點函子法與動機範疇化"
SCHEME_DERIVED = "概形：第2輪結構導出演算法（Kähler 微分、平展判準、Hilbert 多項式、爆炸奇點解消與 Frobenius 下降）"

SCHEME_TYPE_FAMILY = {
    "MonomialOrder": SCHEME_GB, "MTerm": SCHEME_GB, "MPoly": SCHEME_GB,
    "ReducedGroebnerBasis": SCHEME_GB, "Ideal": SCHEME_GB,
    "CoordRing": SCHEME_SHEAF, "RingHom": SCHEME_SHEAF,
    "AffineScheme": SCHEME_SHEAF, "LocalizedSection": SCHEME_SHEAF,
    "QuasiCoherentModule": SCHEME_SHEAF,
    "ChartOverlap": SCHEME_MORPH, "Scheme": SCHEME_MORPH,
    "SchemeMorphism": SCHEME_MORPH, "LaurentSeries": SCHEME_MORPH,
    "PropernessReport": SCHEME_MORPH,
    "PrimeDivisorP1": SCHEME_CYCLE, "WeilDivisorP1": SCHEME_CYCLE,
    "P1LineBundleCohomology": SCHEME_CYCLE,
    "P2LineBundleCohomology": SCHEME_CYCLE,
    "PlaneCurveDualizingReport": SCHEME_CYCLE,
    "FiniteCommRing": SCHEME_CYCLE, "FiniteRingHom": SCHEME_CYCLE,
    "ProjectiveHilbertReport": SCHEME_DERIVED,
    "PlaneCurveBlowupReport": SCHEME_DERIVED,
}

BRIDGE_CLASSIC = "三方橋接"
BRIDGE_GRAND = "六支柱大一統：邏輯理論轉譯與幾何邏輯精細圖譜"


def classify_topos(sym, kind):
    owner = symlib_owner(sym, kind)
    if owner in TOPOS_TYPE_FAMILY:
        return TOPOS_TYPE_FAMILY[owner]

    def has(*prefixes):
        return any(sym == p or sym.startswith(p) for p in prefixes)

    if has(
        "right_kan_presheaf", "verify_essential_geometric",
        "is_connected_essential", "topology_lattice_",
        "open_subtopos_lt", "closed_subtopos_lt",
        "verify_open_closed_subtopos", "induced_dense_subsite",
        "verify_grothendieck_comparison", "is_internal_group_torsor",
        "build_mobius_internal_z2", "simplicial_cup_",
        "verify_alexander_whitney", "torus_t2_minimal", "wedge_s1_s1_s2",
    ):
        return TOPOS_DERIVED
    if has(
        "groupoid_", "is_valid_groupoid", "verify_descent", "descent_data",
        "canonical_descent", "verify_stack", "build_circle_z2", "classify_group_torsor",
        "circle_mobius", "rect_qmat_", "cochain_", "cohomology_", "verify_euler",
        "verify_snake", "abelian_presheaf", "is_valid_abelian", "roos_site",
        "nerve_", "classifying_nerve", "compute_nerve", "boundary_simplex",
        "rp2_minimal",
    ):
        return TOPOS_STACK
    if has(
        "is_valid_subpresheaf", "subpresheaf_", "verify_beck_chevalley",
        "kripke_joyal", "model_satisfies", "geometric_normal_form",
        "geo_normal_form", "verify_geometric_normal_form",
        "build_propositional_classifying", "enumerate_set_models",
        "verify_classifying_topos", "category_of_elements", "cat_slice",
        "verify_elements_slice",
    ):
        return TOPOS_LOGIC
    if has(
        "is_valid_site_functor", "is_cover_preserving", "direct_image",
        "inverse_image", "verify_geometric_morphism", "is_flat_point",
        "is_covariant_point", "is_diaconescu", "covariant_representable_point",
        "enumerate_canonical_points", "point_stalk", "point_skyscraper",
        "global_sections", "analyze_local", "analyze_connected",
        "is_atom_sheaf", "analyze_atomic", "analyze_compact",
    ):
        return TOPOS_GEOM
    if has(
        "is_separated_presheaf", "is_sheaf", "plus_construction", "sheafify",
        "verify_sheafification", "presheaf_exponential", "exponential_",
        "verify_sheaf_cartesian", "subobject_classifier", "characteristic_morphism",
        "verify_subobject_classifier", "omega_j_", "is_boolean_topos",
        "is_de_morgan_topos", "is_lawvere_tierney", "lawvere_tierney",
        "topology_of_lawvere", "verify_elementary_and_giraud",
    ):
        return TOPOS_SHEAF
    return TOPOS_SITE


def classify_scheme(sym, kind):
    owner = symlib_owner(sym, kind)
    if owner in SCHEME_TYPE_FAMILY:
        return SCHEME_TYPE_FAMILY[owner]

    def has(*prefixes):
        return any(sym == p or sym.startswith(p) for p in prefixes)

    if has(
        "kahler_differentials", "affine_kahler_differentials",
        "quasicoherent_fitting_zero", "quasicoherent_module_is_zero",
        "is_unramified_ring_hom", "affine_jacobian_ideal",
        "affine_singular_locus", "affine_is_smooth", "affine_tjurina_number",
        "is_etale_ring_hom", "projective_hilbert_", "blowup_plane_curve",
        "fcomm_fp2", "verify_weil_zeta",
    ):
        return SCHEME_DERIVED
    if has(
        "monomial_cmp", "mpoly_", "qpoly_to_mpoly", "s_polynomial",
        "reduced_groebner", "ideal_",
    ):
        if sym == "mpoly_eval_laurent":
            return SCHEME_MORPH
        if sym == "mpoly_eval_finite_ring":
            return SCHEME_CYCLE
        return SCHEME_GB
    if has(
        "coord_ring_", "ring_hom_", "affine_", "verify_affine_reduction",
        "solve_ideal_linear", "is_zariski_open", "principal_open",
        "localized_section", "restrict_localized", "glue_zariski",
        "localize_quasicoherent",
    ):
        if sym == "affine_fiber_product":
            return SCHEME_MORPH
        return SCHEME_SHEAF
    if has(
        "scheme_", "global_sections_dimension", "morphism_", "is_affine_morphism",
        "is_separated_scheme", "laurent_", "valuative_extension",
        "analyze_scheme_properness", "is_proper_",
    ):
        return SCHEME_MORPH
    return SCHEME_CYCLE


def classify_bridge(sym, kind):
    owner = symlib_owner(sym, kind)
    if owner in (
        "GeometryLogicAtlasEntry",
        "GrandUnificationReport",
        "FederationId",
        "FederationDescriptor",
        "FederationPairBridge",
    ):
        return BRIDGE_GRAND

    def has(*prefixes):
        return any(sym == p or sym.startswith(p) for p in prefixes)

    if has(
        "translate_", "glivenko_", "build_cchm_interval", "build_fine_grained",
        "five_federation_", "six_federation_", "seven_federation_", "verify_",
        "grand_unification", "run_grand_unification", "XOverlapChiasmReport",
        "DoubleVArchitectureReport", "SevenFederationStarPrismReport",
    ):
        return BRIDGE_GRAND
    return BRIDGE_CLASSIC

SYMLIB_GRAPH = "有限對稱：圖規範形與自同構"
SYMLIB_GROUP = "有限對稱：置換群與 Schreier–Sims"
SYMLIB_ACTION = "有限對稱：群作用、軌道與 Burnside"
SYMLIB_DECOMP = "有限對稱：圖分解、對偶與折疊"
SYMLIB_CAT = "有限對稱：有限範疇、預層與 Kan 擴展"
SYMLIB_MONAD = "有限對稱：單子與非確定搜尋"
SYMLIB_CERT = "有限對稱：證書、隨機與報告"

SYMLIB_TYPE_FAMILY = {
    "Graph": SYMLIB_GRAPH, "SearchResult": SYMLIB_GRAPH, "SearchStats": SYMLIB_GRAPH,
    "BitVec": SYMLIB_GRAPH, "KeyLut": SYMLIB_GRAPH, "Part": SYMLIB_GRAPH,
    "Perm": SYMLIB_GROUP, "PermGroup": SYMLIB_GROUP,
    "ActionDerive": SYMLIB_ACTION, "FinAction": SYMLIB_ACTION,
    "GSet": SYMLIB_ACTION, "GSetOf": SYMLIB_ACTION, "Sub": SYMLIB_ACTION,
    "PermSet": SYMLIB_ACTION,
    "Decomp": SYMLIB_DECOMP, "DualCanon": SYMLIB_DECOMP, "FoldedGraph": SYMLIB_DECOMP,
    "FinCat": SYMLIB_CAT, "FinDiagram": SYMLIB_CAT, "FinFunctor": SYMLIB_CAT,
    "FinMap": SYMLIB_CAT, "FinSet": SYMLIB_CAT, "Presheaf": SYMLIB_CAT,
    "LanResult": SYMLIB_CAT, "RanResult": SYMLIB_CAT,
    "ListM": SYMLIB_MONAD, "StateM": SYMLIB_MONAD,
    "Cert": SYMLIB_CERT, "SymmetryReport": SYMLIB_CERT,
}


def symlib_owner(sym, kind):
    if kind == "impl":
        tail = sym.rsplit(" for ", 1)[-1]
        return re.split(r"[\[\s]", tail, maxsplit=1)[0]
    return re.split(r"[.:]", sym)[0].split("::")[0]


def classify_symlib(sym, kind):
    owner = symlib_owner(sym, kind)
    if owner in SYMLIB_TYPE_FAMILY:
        return SYMLIB_TYPE_FAMILY[owner]
    if kind in ("field", "constructor"):
        return SYMLIB_TYPE_FAMILY.get(owner, SYMLIB_GRAPH)

    def has(*prefixes):
        return any(sym == p or sym.startswith(p) for p in prefixes)

    if has("prove_", "failed_certs", "all_hold", "random_", "lcg_", "ints_to_", "int_rows"):
        return SYMLIB_CERT
    if has(
        "cat_", "diagram_", "id_functor", "id_map", "is_category", "is_functor",
        "is_fin_functor", "is_presheaf", "presheaf_", "limit", "colimit",
        "equalizer", "coequalizer", "pullback", "pushout", "product_set",
        "coproduct", "comma_", "lan", "ran", "yoneda", "arrow_diagram",
        "csp_", "queen_", "pow_",
    ):
        return SYMLIB_CAT
    if has("kleisli", "opt_", "search_nd", "nd_guard"):
        return SYMLIB_MONAD
    if has(
        "gset", "mark", "table_of_marks", "subgroup", "coinduced", "induced",
        "coset", "frobenius", "fundamental_domain", "cayley", "permset",
        "vertex_orbits", "edge_orbits",
    ):
        return SYMLIB_ACTION
    if has("all_perms", "regular_perm", "symmetric_gen"):
        return SYMLIB_GROUP
    if has(
        "decomp", "dual", "fold", "line_", "whitney", "k2_", "block_encoding",
    ):
        return SYMLIB_DECOMP
    if sym.endswith("_cert") or sym.startswith("cert"):
        return SYMLIB_CERT
    return SYMLIB_GRAPH


def parse_mbti(text):
    """Parse the public surface of one generated MoonBit interface.

    The parser deliberately covers the declaration forms used by all three
    pillars: `pub(all)`, `pub(open) trait`, generic `pub fn[...]`, generic
    types, trait methods and public trait implementations.  Implementations
    are normalized to ``impl Trait for Type`` so they receive a stable,
    package-scoped identity in the appendix.
    """

    decls = []
    top = re.compile(
        r"^pub(?:\((?:all|open)\))?\s+"
        r"(fn|struct|enum|type|let|trait)(?:\[[^\]]*\])?\s+"
        r"([A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)?)"
    )
    impl = re.compile(r"^pub impl(?:\[[^\]]*\])?\s+(.+?)\s+for\s+(.+?)\s*$")
    block = None  # (name, kind)
    for raw in text.splitlines():
        line = raw.rstrip()

        im = impl.match(line)
        if im:
            trait = im.group(1).strip().rsplit(".", 1)[-1]
            typ = im.group(2).strip()
            decls.append((f"impl {trait} for {typ}", "impl"))
            block = None
            continue

        m = top.match(line)
        if m:
            kind, sym = m.group(1), m.group(2)
            decls.append((sym, kind))
            if kind in ("struct", "enum", "trait") and line.rstrip().endswith("{"):
                block = (sym, kind)
            else:
                block = None
            continue

        if block is not None:
            if line.startswith("}"):
                block = None
                continue
            name, kind = block
            if kind == "struct":
                fm = re.match(r"^\s+(?:mut\s+)?([a-z_][A-Za-z0-9_]*)\s*:", line)
                if fm:
                    decls.append((f"{name}.{fm.group(1)}", "field"))
            elif kind == "trait":
                tm = re.match(r"^\s+fn\s+([a-z_][A-Za-z0-9_]*)", line)
                if tm:
                    decls.append((f"{name}::{tm.group(1)}", "trait-method"))
            else:
                vm = re.match(r"^\s+([A-Z][A-Za-z0-9_]*)", line)
                if vm:
                    decls.append((f"{name}::{vm.group(1)}", "constructor"))
    return decls


def load_decls():
    """All public declarations of every manifested local package."""
    arch = json.loads((ROOT / "architecture.json").read_text())
    decls = []
    for pkg in arch["packages"]:
        mbti = ROOT / pkg["path"] / "pkg.generated.mbti"
        assert mbti.exists(), f"missing {mbti}: run `moon info` first"
        for sym, kind in parse_mbti(mbti.read_text()):
            decls.append((pkg["id"], sym, kind))
    return decls


def classify(pkg, sym, kind):
    if pkg == "symlib":
        return classify_symlib(sym, kind)
    if pkg == "topos":
        return classify_topos(sym, kind)
    if pkg == "scheme":
        return classify_scheme(sym, kind)
    if pkg == "bridge":
        return classify_bridge(sym, kind)
    if pkg in PACKAGE_FAMILY:
        return PACKAGE_FAMILY[pkg]
    if kind in ("field", "constructor"):
        owner = re.split(r"[.:]", sym)[0]
        return TYPE_FAMILY.get(owner)
    if kind in ("struct", "enum", "type"):
        return TYPE_FAMILY.get(sym)
    if "::" in sym:  # derived Eq/Debug methods belong to their type's family
        return TYPE_FAMILY.get(sym.split("::")[0])
    if sym in EXACT:
        return EXACT[sym]
    if sym.startswith("check_"):
        rest = sym[len("check_"):]
        for hint, fam in CHECK_FAMILY_HINTS:
            if rest == hint or rest.startswith(hint + "_") or rest.startswith(hint):
                return fam
        return "定理登記與範例"
    for prefix, fam in PREFIXES:
        if sym == prefix or sym.startswith(prefix):
            return fam
    return None


def render(decls, lang):
    by_family = {name: [] for name in FAMILIES}
    for pkg, sym, kind in decls:
        fam = classify(pkg, sym, kind)
        assert fam in FAMILIES, f"unclassified symbol: {pkg}/{sym} ({kind}) -> {fam}"
        by_family[fam].append((pkg, sym, kind))
    total = len(decls)
    families_used = sum(1 for v in by_family.values() if v)
    per_pkg = {}
    for pkg, _, _ in decls:
        per_pkg[pkg] = per_pkg.get(pkg, 0) + 1
    out = []
    if lang == "zh":
        pkg_text = "、".join(f"`{p}` {n}" for p, n in sorted(per_pkg.items()))
        out.append(f"共 **{total}** 個公共符號（宣告＋構造子＋欄位），分屬 {families_used} 個規格族；按套件：{pkg_text}。")
        labels = ("規範形式", "範疇化", "判定")
        headers = ("符號", "套件", "類別")
        oracle_note = "（差分測試 oracle，非判定路徑）"
    else:
        pkg_text = ", ".join(f"`{p}` {n}" for p, n in sorted(per_pkg.items()))
        out.append(f"**{total}** public symbols (declarations + constructors + fields) in {families_used} specification families; by package: {pkg_text}.")
        labels = ("Canonical form", "Categorification", "Decision")
        headers = ("Symbol", "Package", "Kind")
        oracle_note = " (differential-testing oracle, not a decision path)"
    for fam, (canon, cat, dec) in FAMILIES.items():
        items = sorted(by_family[fam], key=lambda x: (x[1], x[0]))
        if not items:
            continue
        if lang == "en":
            fam_name, canon, cat, dec = FAMILIES_EN[fam]
        else:
            fam_name = fam
        out.append("")
        out.append(f"### {fam_name}")
        out.append("")
        out.append(f"- {labels[0]}：{canon}" if lang == "zh" else f"- {labels[0]}: {canon}")
        out.append(f"- {labels[1]}：{cat}" if lang == "zh" else f"- {labels[1]}: {cat}")
        out.append(f"- {labels[2]}：{dec}" if lang == "zh" else f"- {labels[2]}: {dec}")
        out.append("")
        out.append(f"| {headers[0]} | {headers[1]} | {headers[2]} |")
        out.append("|---|---|---|")
        for pkg, sym, kind in items:
            note = oracle_note if ("oracle" in sym or "extensional" in sym) else ""
            out.append(f"| `{sym}` | {pkg} | {KIND_LABELS[lang][kind]}{note} |")
    return "\n".join(out) + "\n"


def appendix_document(lang, rendered):
    if lang == "zh":
        head = """# cubical-hermitian 規格附錄（逐符號登記）

[English appendix](SPEC-APPENDIX.en.md) · [中文規格正本](SPEC.md) · [English specification](SPEC.en.md)

> 本檔案由 `tools/audit_spec.py --write` 自各套件的 `pkg.generated.mbti`
> （`moon info`）生成，**勿手改**附錄標記之間的內容。套件欄是
> `architecture.json` 登記的 MoonBit 套件。

"""
    else:
        head = """# cubical-hermitian Specification Appendix (per-symbol registry)

[中文附錄](SPEC-APPENDIX.md) · [English specification](SPEC.en.md) · [中文規格正本](SPEC.md)

> This file is generated by `tools/audit_spec.py --write` from each
> package's `pkg.generated.mbti` (`moon info`).  Do **not** edit the
> content between the appendix markers by hand.  The package column
> is the MoonBit package registered in `architecture.json`.

"""
    return head + "<!-- APPENDIX:BEGIN -->\n" + rendered.rstrip("\n") + "\n<!-- APPENDIX:END -->\n"


def appendix_of(text):
    m = re.search(r"<!-- APPENDIX:BEGIN -->\n(.*?)\n<!-- APPENDIX:END -->", text, re.S)
    return m.group(1) if m else None


def symbols_in_appendix(app):
    return [(pkg, sym) for sym, pkg in re.findall(r"^\| `([^`]+)` \| ([A-Za-z0-9_-]+) \|", app, re.M)]


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "--check"
    decls = load_decls()
    identities = [(pkg, sym) for pkg, sym, _ in decls]
    assert len(identities) == len(set(identities)), "duplicate (package, symbol) parsed from mbti files"
    docs = {
        "zh": (APPENDIX_ZH, appendix_document("zh", render(decls, "zh"))),
        "en": (APPENDIX_EN, appendix_document("en", render(decls, "en"))),
    }
    if mode == "--write":
        for path, text in docs.values():
            path.write_text(text)
        print(f"appendices written: {len(identities)} symbols (zh + en)")
    for path, expected in docs.values():
        assert path.exists(), f"missing {path.name}: run with --write"
        text = path.read_text()
        app = appendix_of(text)
        assert app is not None, f"appendix markers not found in {path.name}"
        listed = symbols_in_appendix(app)
        missing = sorted(set(identities) - set(listed))
        extra = sorted(set(listed) - set(identities))
        dup = sorted({s for s in listed if listed.count(s) > 1})
        assert not missing, f"{path.name}: missing from appendix: {missing[:20]}"
        assert not extra, f"{path.name}: not in interface: {extra[:20]}"
        assert not dup, f"{path.name}: duplicated in appendix: {dup[:20]}"
        if mode == "--check":
            assert text == expected, f"{path.name} is stale: run with --write"
    kinds = {}
    pkgs = {}
    for pkg, _, k in decls:
        kinds[k] = kinds.get(k, 0) + 1
        pkgs[pkg] = pkgs.get(pkg, 0) + 1
    # Verify that every symbol registered in spec.mbt actually exists in .mbti or .mbt code
    mbti_tokens = set()
    code_tokens = set()
    for dp, dn, fn in os.walk(ROOT):
        dn[:] = [d for d in dn if d not in (".git", "_build", ".mooncakes")]
        for f in fn:
            p = Path(dp) / f
            if f == "pkg.generated.mbti":
                mbti_tokens.update(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", p.read_text()))
            elif f.endswith(".mbt") and f != "spec.mbt":
                raw = re.sub(r"//.*", "", p.read_text())
                raw = re.sub(r'"(?:\\.|[^"\\])*"', '""', raw)
                code_tokens.update(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", raw))
    spec_text = (ROOT / "spec.mbt").read_text()
    phantoms = []
    for em in re.finditer(r'entry\(\s*"([^"]+)"\s*,\s*Spec[A-Za-z]+\s*,\s*\[(.*?)\]', spec_text, re.S):
        title, arr_body = em.group(1), em.group(2)
        for s in re.findall(r'"([^"]+)"', arr_body):
            leaf = re.split(r"[.:]+", s)[-1]
            if s not in mbti_tokens and s not in code_tokens and leaf not in code_tokens:
                phantoms.append((title, s))
    assert not phantoms, f"phantom symbols in spec.mbt: {phantoms[:20]}"
    print(f"audit ok: {len(identities)} symbols, by kind {kinds}, by package {pkgs}")


if __name__ == "__main__":
    main()
