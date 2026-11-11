/-
  KtLaws/Registry.lean — 已證明定律的登記表

  與 MoonBit 側 `tools/gen_laws.py` 同一個精神：定律必須登記，否則不算數。
  每一筆都對應一個真的 `theorem`，而且下面 `section Checks` 用 `#check` 逐一指到
  具體常數——名字打錯、定理被刪，這裡就會編不過（不會出現「登記了但不存在」）。
  `#eval` 印出目前條數；MoonBit 側目前總數 551／互異 453（2026-11-10）。
-/
import KtLaws.Ramsey
import KtLaws.RamseyEx
import KtLaws.Matroid
import KtLaws.Ordinal
import KtLaws.Simplicial
import KtLaws.IIT.Examples
import KtLaws.IIT.Extra
import KtLaws.IIT.STLC
import KtLaws.Instances.Engine
import KtLaws.Instances.Characterize
import KtLaws.Instances.Compose
import KtLaws.Instances.Coherence
import KtLaws.Instances.Termination
import KtLaws.Reflect.Nbe
import KtLaws.Reflect.NfNormal
import KtLaws.Reflect.Proof
import KtLaws.Reflect.Link
import KtLaws.Unify

set_option maxRecDepth 100000

open KtLaws

/-! ### 登記清單 -/

/-- 已形式化（kernel 檢查通過）的定律，順序與下面 `#check` 一一對應。 -/
def provedLaws : List String :=
  [ -- Ramsey（7）
    "ramsey: Paley P₁₇ 有 68 條紅邊（8·17/2）",
    "ramsey: Paley 著色對稱",
    "ramsey: P₁₇ 沒有紅色 K₄、也沒有藍色 K₄（⇒ R(4,4) ≥ 18）",
    "ramsey: K₈ circulant 有 12 條紅邊（3·8/2）",
    "ramsey: K₈ circulant 沒有紅色 K₃",
    "ramsey: K₈ circulant 沒有藍色 K₄",
    "ramsey: R(3,4) ≥ 9（同一張 circulant 著色）",
    -- Ramsey: 上界（1）
    "ramsey: R(3,3) ≤ 6（K₆ 的 32768 種 2-著色全都含單色三角形）",
    "ramsey: R(3,4) ≤ 10（4 紅 / 6 藍的鴿籠 + 星形六點引理，非窮舉）",
    "ramsey: R(3,4) ≤ 9（每點紅度必為 3，與握手引理的奇偶性矛盾；零窮舉）",
    "ramsey: R(4,3) ≤ 9（紅藍對調，由 R(3,4) ≤ 9 得到）",
    "ramsey: R(4,4) ≤ 18（Ramsey 遞推 9+9）",
    "ramsey: R(3,4) = 9（上界 + Z₈ 見證）",
    "ramsey: R(4,4) = 18（上界 + Paley P₁₇ 見證）",
    "ramsey: R(3,5) ≤ 14（遞推 5+9：五紅鄰點 ⇒ 藍 K₅；九藍鄰點 ⇒ R(3,4) ≤ 9）",
    "ramsey: GG13 無紅 K₃（Z₁₃ 差集 {1,5,8,12} 的循環圖）",
    "ramsey: GG13 無藍 K₅（同上，補圖獨立數 ≤ 4）",
    "ramsey: R(3,5) = 14（上界 + 13 點見證）",
    "graph: 握手引理（Σ 度數 = 2 × 邊數）",
    -- Matroid: 集合層（3）
    "matroid: 補集是對合（compl ∘ compl = id）",
    "matroid: 對偶是對合（M** = M）",
    "matroid: 對偶後基底逐一相等",
    -- Matroid: 圖擬陣、對偶、Q 上線性擬陣（11）
    "matroid: 圖擬陣的秩（三角形 + 尾，r(E) = 3）",
    "matroid: 圖擬陣滿足秩公理（R1 r(∅) = 0、R2 單調、R3 次模）",
    "matroid: 圖擬陣滿足獨立集交換公理",
    "matroid: 貪心在圖擬陣上最優（4⁴ 種權重逐一同暴力解比對）",
    "matroid: 對偶秩 r*(E) = |E| − r(E)",
    "matroid: 對偶的對偶秩回到原秩（r** = r，16 個子集全比）",
    "matroid: 對偶擬陣滿足交換公理",
    "matroid: Q 上線性擬陣的秩為 2（行 (1,0)、(0,1)、(1,1)）",
    "matroid: {0,1} 獨立而 {0,1,2} 相依",
    "matroid: {0,1} 的閉包就是全部三點",
    "matroid: 線性擬陣滿足交換公理",
    -- Simplicial / covers（19，對應 MoonBit complex.mbt 的 18 條標籤）
    "simplicial: Euler–Poincaré（任意 f-向量與秩序列，兩端秩為 0 ⇒ χ = Σ(−1)^k b_k）",
    "simplicial: Euler–Poincaré 套到所有有限複形（χ 兩種算法一致）",
    "simplicial: 三角形邊界（≅ S¹）χ = 0",
    "simplicial: 三角形邊界的 b₀ = 1",
    "simplicial: 三角形邊界的 b₁ = 1",
    "simplicial: 三角形邊界是鏈複形（∂∘∂ = 0）",
    "simplicial: 實心三角形 χ = 1",
    "simplicial: 實心三角形的 b₁ = 0",
    "simplicial: 實心三角形的 b₂ = 0",
    "complex: f-向量長度 ≥ 3（有頂點層到 2-面）",
    "complex: 頂點層不少於邊層（f₀ ≥ f₁）",
    "complex: f-向量的交錯和 = χ",
    "complex: 兩個孤立點 χ = 2",
    "covers: 兩片貼片重疊可黏（nerve 收縮 ⇒ H¹ = 0）",
    "covers: 兩片貼片重疊沒有障礙見證",
    "covers: 三片兩兩相交、三者共交為空 ⇒ 不可黏（nerve ≅ S¹）",
    "covers: 障礙見證就是三元組 (0,1,2)",
    "covers: 三片共同相交可黏",
    "covers: 三片共同相交沒有障礙見證",
    -- IIT / 歸納-歸納（42 條）
    "iit: schema 良構性（Nat/Fin 通過、索引佔位被拒）",
    "iit: Even/Odd 第 1 階段只有兩個零元建構子",
    "iit: Even/Odd 第 2 階段各 2 個居民",
    "iit: Even/Odd 第 6 階段 6 個居民（無限、不穩定）",
    "iit: Even/Odd 族嚴格成長（2 < 6）",
    "iit: Even/Odd 每個居民都通過 icheck（對所有階段）",
    "iit: Even/Odd 每個居民都落在正確的 sort",
    "iit: 有限 schema 在第 4 階段穩定（2 / 1）",
    "iit: 有限 schema 在第 7 階段仍是（2 / 1）",
    "iit: Nat/Fin 的 schema 良構",
    "iit: Nat/Fin 第 1 階段 Fin 還生不出居民（一階相位差）",
    "iit: Nat/Fin 第 2 階段 Nat 2 個、Fin 開始出現",
    "iit: Nat/Fin 第 3 階段 Nat 3 個、Fin ≥ 3 個",
    "iit: fz z : Fin (s z) 通過索引檢查且 sort 正確",
    "iit: fz z 的索引就是 s z",
    "iit: 內層索引不匹配的 fs 被拒",
    "iit: fs (s z) (fz z) 通過索引檢查",
    "iit: fs (s z) (fz z) 的索引是 s (s z)",
    "iit: fs (z, fz z) 被拒（fz z 的索引不是 z）",
    "iit: icheckAt 認證 fz z 的 sort 與索引",
    "iit: 同一個值不能宣稱另一個索引",
    "iit: Kleene 鏈單調（第 2 段 ⊆ 第 4 段）",
    "iit: 鏈上每個居民都良構（對所有燃料）",
    "iit: 鏈上每個居民都落在正確的 sort",
    "iit: Nat 的居民數隨階段嚴格增加",
    "iit: 互遞迴消除器滿足 ι 律（對所有項）",
    "iit: 終止性被認證（對所有項）",
    "iit: 父項的 ω^size 度量嚴格大於子項",
    "iit: Even/Odd 的索引依賴圖無環",
    "iit: Nat/Fin 的索引依賴圖無環",
    "iit: 有限 schema 的索引依賴圖無環",
    "iit: 資料依賴圖允許有環（Even/Odd 0↔1）",
    "iit: Even/Odd 完全沒有索引依賴",
    "iit: iota 律（schema 層，對所有 IVal）",
    "iit: 子項終止性憑證（schema 層，對所有 IVal）",
    "iit: 子項嚴格小於父項（ω^size 的基礎）",
    "iit: icheckAt 判真 ⇒ sort 與索引都對",
    "iit: Kleene 階段保留前一階段（單調）",
    "iit: Kleene 階段可靠性（良構對階段封閉）",
    "iit: 從空族枚舉出的居民全部良構",
    "iit: 從空族枚舉出的居民 sort 全部正確",
    "iit: Kleene 鏈單調（schema 層，對所有燃料）",
    -- IIT / STLC 的 β 與索引傳輸（40 條）
    "STLC: β 索引保持 #1 原項良構",
    "STLC: β 索引保持 #2 一次 β 回到 λy.y",
    "STLC: β 索引保持 #3 約簡結果良構",
    "STLC: β 索引保持 #4 索引（上下文, 型別）不變",
    "STLC: β 索引保持 #5 走進 binder 的原項良構",
    "STLC: β 索引保持 #6 約簡結果是 λ",
    "STLC: β 索引保持 #7 約簡結果良構（arg 被弱化過）",
    "STLC: β 索引保持 #8 索引不變",
    "STLC: β 索引保持 #9 內層 arg 的上下文被插入 nat",
    "STLC: β 索引保持 #10 燃料 0 時停在原項",
    "STLC: β 索引保持 #11 λ 是值，β 不開火",
    "STLC: 弱化 #1 變數弱化 = 包一層 vs",
    "STLC: 弱化 #2 弱化後的變數良構",
    "STLC: 弱化 #3 型別不變",
    "STLC: 弱化 #4 上下文確實改變",
    "STLC: 弱化 #5 λ 弱化後良構",
    "STLC: 弱化 #6 λ 的上下文插入 nat",
    "STLC: 弱化 #7 弱化兩次良構",
    "STLC: 弱化 #8 弱化兩次的位置 = 2",
    "STLC: 弱化 #9 型別錯的 app 被索引檢查攔下",
    "STLC: 主體約簡 #1 四個閉項每一步都保持索引",
    "STLC: 主體約簡 #2 電池的每個成員都良構",
    "STLC: 主體約簡 #3 內層先約簡的項走完兩步回到 arg",
    "STLC: 主體約簡 #4 正規形仍然良構",
    "STLC: 正規化 #1 正規化到 λy.y",
    "STLC: 正規化 #2 正規形不能再走",
    "STLC: 正規化 #3 函式位置是變數時不 β",
    "STLC: 正規化 #4 卡住的項本身良構",
    "STLC: 正規化 #5 燃料 0 時不會假裝算出答案",
    "STLC: 正規化 #6 exApp1 一步就到底",
    "STLC: 正規化 #7 走進 binder 的項正規化後良構",
    "STLC: Tm 索引需要 cons #1 STLC schema 良構",
    "STLC: Tm 索引需要 cons #2 恆等項良構",
    "STLC: Tm 索引需要 cons #3 恆等項的索引是 (nil, nat→nat)",
    "STLC: Tm 索引需要 cons #4 不能宣稱成另一個上下文",
    "STLC: Tm 索引需要 cons #5 型別錯的 app 被拒",
    "STLC: Tm 索引需要 cons #6 正確的 app 良構",
    "STLC: Tm 索引需要 cons #7 應用結果的索引",
    "STLC: Tm 索引需要 cons #8 變數的索引 = 上下文 + 型別",
    "STLC: Tm 索引需要 cons #9 上下文長度不對被拒",
    -- instances / engine：SLD 解析、終止、一致性（22 條）
    "instances: SLD 解析解出 Show Int",
    "instances: 泛型規則組合出 Show (Array Int)",
    "instances: 兩層組合 Show (Array (Array Bool))",
    "instances: 兩個 body 目標 Show (Pair Int (Array Bool))",
    "instances: 沒有 Eq 實例時解不出來（引擎不假裝成功）",
    "instances: Show (Array Int) 只有一條推導",
    "instances: 那條推導用的規則是 Array",
    "instances: 子推導用的是 Int 公理",
    "instances: 深度決定推導的大小（深度 2、節點數 2）",
    "instances: 經典環境可終止",
    "instances: 繞圈的法則被判為不終止",
    "instances: 不終止的判定是可判定的",
    "instances: 序數度量確實嚴格下降（ω¹ < ω²）",
    "instances: 終止與一致性是兩件事（不一致環境照樣終止）",
    "instances: 重疊實例只有一對臨界對",
    "instances: Show Int 有兩條推導（重疊存在）",
    "instances: 典範化挑出 specific 實例",
    "instances: 優先級不同 ⇒ 視為一致",
    "instances: 同優先級重疊 ⇒ 有不一致見證",
    "instances: 不一致見證就是那個目標本身",
    "instances: 同優先級重疊 ⇒ 不一致",
    "instances: 經典環境沒有臨界對（風險為零）",
    -- instances / characterize：可導性秩是不是擬陣的判準（40 條）
    "instances: 公理片段 #1 目標集是公理可解的",
    "instances: 公理片段 #2 秩公理全過",
    "instances: 公理片段 #3 沒有失敗原因",
    "instances: 公理片段 #4 r({0}) = 1",
    "instances: 公理片段 #5 r({0,1}) = 2",
    "instances: 公理片段 #6 r({0,1,2}) = 3",
    "instances: 公理片段 #7 沒有單位增量反例",
    "instances: 公理片段 #8 沒有次模性反例",
    "instances: 交換公理太弱 #1 舊判準說「是擬陣」",
    "instances: 交換公理太弱 #2 嚴格判準說「不是」",
    "instances: 交換公理太弱 #3 失敗理由是次模性 R3",
    "instances: 交換公理太弱 #4 單位增量見證 (0,0,2)",
    "instances: 交換公理太弱 #5 空規則集秩 0",
    "instances: 交換公理太弱 #6 只有公理時秩 1",
    "instances: 交換公理太弱 #7 只有合成規則時秩 0",
    "instances: 交換公理太弱 #8 兩條一起用秩跳 2",
    "instances: 交換公理太弱 #9 加一條公理讓秩增加 2",
    "instances: 交換公理太弱 #10 次模性反例存在",
    "instances: 交換公理太弱 #11 反例本身 r(A)+r(B) < r(A∪B)+r(A∩B)",
    "instances: 交換公理太弱 #12 目標集不是公理可解的",
    "instances: 判準 #1 六環境×兩目標集與嚴格秩公理逐一一致",
    "instances: 判準 #2 樣本裡有「是擬陣」的情形",
    "instances: 判準 #3 樣本裡也有「不是擬陣」的情形",
    "instances: 判準 #4 兩邊的計數相等",
    "instances: 判準 #5 合成規則落在目標上、覆蓋仍不相交",
    "instances: 判準 #6 所以不是擬陣",
    "instances: 判準 #7 萬用實例讓覆蓋不相交失效",
    "instances: 判準 #8 所以不是擬陣",
    "instances: 判準 #9 無害的合成規則 head 落不到目標集",
    "instances: 判準 #10 所以仍是擬陣（判準的邊界）",
    "instances: 判準 #11 換目標集後合成規則變得有害",
    "instances: 判準 #12 同環境換目標集就翻面",
    "instances: 貪心 #1 正序刪除留下大小 1 的基",
    "instances: 貪心 #2 反序刪除留下大小 3 的基",
    "instances: 貪心 #3 後者嚴格大於前者",
    "instances: 貪心 #4 {3} 是極小基",
    "instances: 貪心 #5 {0,1,2} 也是極小基",
    "instances: 貪心 #6 {3} 真的解得出目標",
    "instances: 貪心 #7 {0,1,2} 也真的解得出目標",
    "instances: 貪心 #8 公理可解但貪心仍不保證最小",
    -- instances / compose：組合、併攏、鏡像對偶、深度窗口（35 條）
    "compose: 最小基 #1 envShow 的極小基要 4 條規則",
    "compose: 最小基 #2 它真的是極小基",
    "compose: 最小基 #3 多加無用規則不會讓基變大",
    "compose: 可導性 #1 平坦情形交換公理成立",
    "compose: 可導性 #2 共享子目標時量測結果仍成立",
    "compose: 併攏 #1 線段覆蓋黏得起來",
    "compose: 併攏 #2 黏出的截面是 [7,7]",
    "compose: 併攏 #3 結構上合法（轉移都落在真重疊）",
    "compose: 併攏 #4 Möbius 帶黏不起來",
    "compose: 併攏 #5 有具體的障礙見證",
    "compose: 併攏 #6 黏合結果是「沒有截面」",
    "compose: 併攏 #7 零截面黏得起來（Möbius 帶的拓撲事實）",
    "compose: 併攏 #8 平凡化（全 +1）黏得起來",
    "compose: 併攏 #9 Möbius 的單值化見證存在",
    "compose: 併攏 #10 平凡化沒有單值化障礙",
    "compose: 併攏 #11 零截面黏出全 0",
    "compose: 併攏 #12 平凡化的截面是 [1,1,1]",
    "compose: 神經 #1 線段覆蓋的神經可縮 ⇒ 可黏",
    "compose: 神經 #2 圈覆蓋的神經 ≅ S¹ ⇒ 不可黏",
    "compose: 神經 #3 圈覆蓋的障礙見證 (0,1,2)",
    "compose: 神經 #4 線段覆蓋沒有障礙",
    "compose: 鏡像 #1 mirror² 的規則數不變",
    "compose: 鏡像 #2 mirror² 的規則名稱逐條相同",
    "compose: 鏡像 #3 E ⊢ Show (Array Int)",
    "compose: 鏡像 #4 互證：mirror(E)+假設 ⊢ ⊤",
    "compose: 鏡像 #5 反面：E 解不出 Eq Int",
    "compose: 鏡像 #6 對偶也證不出 ⊤",
    "compose: 視窗 #1 R(3,3) = 6",
    "compose: 視窗 #2 鴿籠視窗 3+1 = 4",
    "compose: 視窗 #3 Ramsey 視窗不窄於鴿籠視窗",
    "compose: 視窗 #4 R(4,4) = 18 比 C(6,3)=20 更緊",
    "compose: 視窗 #5 R(4,4) = 18 ≥ R(3,4) = 9",
    "compose: 指紋 #1 mirror² 的 head 序列不變",
    "compose: 指紋 #2 指紋分辨得出鏡像",
    "compose: 指紋 #3 指紋非空",
    -- instances / coherence：完備一致性、區域實例、擴充穩定性、Newman（40 條）
    "instances: 完備 #1 可達宇宙自己算得出來且不空",
    "instances: 完備 #2 純規則環境一致",
    "instances: 完備 #3 且回報沒有不一致",
    "instances: 完備 #4 極小環境也一致",
    "instances: 完備 #5 有衝突的環境被判不一致",
    "instances: 完備 #6 指得出是哪個目標",
    "instances: 完備 #7 回報確實存在",
    "instances: 完備 #8 宇宙含 Show (Array Int)",
    "instances: 完備 #9 宇宙含 Show (Pair Int Int)",
    "instances: 完備 #10 宇宙含深層目標 Show (Array (Array Int))",
    "instances: 尖峰 #1 envShow 上局部尖峰⟺head 重疊",
    "instances: 尖峰 #2 極小環境上一致",
    "instances: 尖峰 #3 衝突環境上一致",
    "instances: 尖峰 #4 優先級不同的重疊也一致",
    "instances: 尖峰 #5 該環境剛好一對臨界對",
    "instances: 尖峰 #6 但仍然一致（典範化挑得出唯一見證）",
    "instances: 尖峰 #7 envShow 的兩條泛型實例不重疊",
    "instances: 區域實例 #1 全域規則之間沒有臨界對",
    "instances: 區域實例 #2 只看全域規則時一致",
    "instances: 區域實例 #3 可達宇宙裡也沒有重疊對",
    "instances: 區域實例 #4 同優先級區域實例 ⇒ 不一致（舊 API 看不見）",
    "instances: 區域實例 #5 更高優先級 ⇒ 具體者勝而非不一致",
    "instances: 區域實例 #6 無關的區域實例不影響",
    "instances: 區域實例 #7 漂移見證指得出目標",
    "instances: 區域實例 #8 漂移見證存在",
    "instances: 穩定性 #1 加無關實例 ⇒ 穩定",
    "instances: 穩定性 #2 加高優先級具體實例 ⇒ 見證改變",
    "instances: 穩定性 #3 漂移只發生在被影響的目標",
    "instances: 穩定性 #4 漂移見證存在",
    "instances: 穩定性 #5 同優先級 catch-all 不漂移",
    "instances: 穩定性 #6 高優先級 catch-all 會漂移",
    "instances: 穩定性 #7 同擴充可重複判定",
    "instances: Newman #1 envShow 終止",
    "instances: Newman #2 且局部合流",
    "instances: Newman #3 ⇒ 全域合流",
    "instances: Newman #4 同優先級兩實例仍終止",
    "instances: Newman #5 但不局部合流",
    "instances: Newman #6 ⇒ 不全域合流（逆否）",
    "instances: Newman #7 繞圈環境終止性失敗",
    "instances: Newman #8 本批環境上沒有反例",
    -- Instances / termination（O4 重寫終止，13 條；見 Instances/Termination.lean）
    "instances: 代入後 uSize 的精確展開（ufn 各貢獻 1、變數各貢獻代入值）",
    "instances: 多重集包含 ⇒ 加權和不增（count 點式比較）",
    "instances: 根重列在足夠條件下嚴格減少 uSize",
    "instances: 參數清單重寫每步嚴格減少 uSizeList",
    "instances: 任意位置重寫每步嚴格減少 uSize",
    "instances: 足夠條件 ⇒ 重寫關係良基（InvImage uSize）",
    "instances: envShow 四條規則逐一驗明足夠條件",
    "instances: envShow 重寫全域終止",
    "instances: 反例：純規則 h(f x, y) ⇒ g(y, y) 在 kt 節點數上定向卻增大",
    "instances: 反例的成長步（headσ 大小 6 < bodyσ 大小 7）",
    "instances: 反例大項大小逐點可判定（6、7、4、3）",
    "instances: 反例改寫在重寫系統中成立（Rewrites ctEnv）",
    "instances: kt 的『head 節點數 > body 節點數』不是終止性證明",
    -- Reflect / NbE（O1 第一半邊，2 條；見 Reflect/NfNormal.lean）
    "reflect: NbE reify/reifyNeu 的輸出恆 β-正常（頭不為 lam；對所有項/燃料成立）",
    "reflect: Well-typed 項正規化後 β-正常（nf_beta_normal；冪等半邊仍待 logical relation）",
    -- Ordinal: 比較的結構性（5）
    "ordinal: 自然數三向比較判等 iff 相等",
    "ordinal: 自然數比較交換 ⇔ swap",
    "ordinal: CNF 唯一性（cmp a b = eq ↔ a = b）",
    "ordinal: 序數比較交換 ⇔ swap（反對稱）",
    "ordinal: 自己和自己比一定相等",
    -- Ordinal: 全序（3）
    "ordinal: ≤ 自反",
    "ordinal: ≤ 全序（任兩者可比）",
    "ordinal: ≤ 反對稱",
    -- Ordinal: 遞移性與結合律（4）
    "ordinal: 自然數比較的嚴格序（cmpNat = lt → a < b）",
    "ordinal: 自然數比較遞移",
    "ordinal: 字典序遞移（cmp a b = lt ∧ cmp b c = lt ⇒ cmp a c = lt）",
    "ordinal: ≤ 遞移",
    -- Ordinal: ord_max 是 lattice join（8，對所有序數，不只是樣本）
    "ordinal: ord_max 是上界（左）",
    "ordinal: ord_max 是上界（右）",
    "ordinal: ord_max 恰為兩者之一",
    "ordinal: ord_max 對稱",
    "ordinal: ord_max 冪等",
    "ordinal: ord_max 是最小上界（join 的定義性質）",
    "ordinal: ord_max ≤ c ↔ a ≤ c ∧ b ≤ c（上確界判準）",
    "ordinal: ord_max 結合律",
    "ordinal: ord_max 結合律（等式形式）",
    -- Ordinal: CNF 恆等式（10，MoonBit ord_probe_laws 的逐條版本）
    "ordinal CNF: 1 + ω = ω（吸收律）",
    "ordinal CNF: ω < ω + 1",
    "ordinal CNF: ω + ω = ω·2",
    "ordinal CNF: 1 + (ω + 1) = ω + 1",
    "ordinal CNF: ω + ω² = ω²",
    "ordinal CNF: ω·1000000 < ω^ω",
    "ordinal CNF: 加法結合律（3 + ω + 1 兩條路徑一致）",
    "ordinal CNF: ω^(ω^ω) 是範式且大於 ω^ω",
    "ordinal CNF: 範式性在加法下封閉（實例）",
    "ordinal CNF: ω²·ω = ω³",
    -- reflect / nbe：β、η、冪等、保型（7 條）
    "reflect / nbe：#1 β 規約 (λx.x) * ↦ *",
    "reflect / nbe：#2 冪等 nf(nf t) = nf t",
    "reflect / nbe：#3 η —— reify∘reflect 與自由變數讀出同一個正常形式",
    "reflect / nbe：#4 eval 造出的中性應用在基底型別上安全 reify",
    "reflect / nbe：#5 保型的準備——(1→B0)→B0 的項通過檢查",
    "reflect / nbe：#6 保型——正規化之後型別不變",
    "reflect / nbe：#7 反例——型別不對的項被拒",
    -- reflect / proof：快與慢、可列印（16 條）
    "reflection：快與慢 #1 反射判定 (λx.x) * = *",
    "reflection：快與慢 #2 憑證重放——每一步都是局部 β/η",
    "reflection：快與慢 #3 憑證至少兩格（起點與終點）",
    "reflection：快與慢 #4 所以「沒有憑證」分支不被觸發",
    "reflection：快與慢 #5 * = (λx.x)((λx.x)*) 也有憑證",
    "reflection：快與慢 #6 同一個樣本上快速判定也成立",
    "reflection：快與慢 #7 基底型別的邊界：reify 把非中性值讀成 *（decide 會說相等）",
    "reflection：快與慢 #8 但同一對項沒有 βη 帳 ⇒ 憑證不存在",
    "reflection：快與慢 #9 篡改終點的憑證被拒",
    "reflection：快與慢 #10 篡改起點的憑證被拒",
    "reflection：快與慢 #11 一致性（差別測試）：五個樣本上判定與憑證存在不衝突",
    "reflection：憑證可列印 #1 憑證指紋非空",
    "reflection：憑證可列印 #2 印出來的東西仍然檢查得過",
    "reflection：憑證可列印 #3 大小與帳的長度一致",
    "reflection：憑證可列印 #4 至少兩格",
    "reflection：憑證可列印 #5 帳的終點就是正常形式",
    -- reflect / link：實例憑證獨立複驗（13 條）
    "reflect / link：#1 Show(Array Int) 的憑證檢查得過（不搜尋）",
    "reflect / link：#2 憑證深度是 2",
    "reflect / link：#3 憑證形狀 Array(Int) = [2,0]",
    "reflect / link：#4 憑證根節點的目標就是原目標",
    "reflect / link：#5 巢狀目標 Show(Pair Int (Array Bool)) 的憑證也檢查得過",
    "reflect / link：#6 巢狀憑證深度是 3",
    "reflect / link：#7 巢狀憑證形狀 = [3,0,2,1]",
    "reflect / link：#8 無解的目標（Eq Int）搜尋結果為空",
    "reflect / link：#9 所以無解的目標拿不到憑證",
    "reflect / link：#10 篡改根節點的規則 ⇒ 被拒",
    "reflect / link：#11 篡改子節點的規則 ⇒ 被拒",
    "reflect / link：#12 良性憑證只有一個子節點（篡改測試的前提）",
    "reflect / link：#13 有解的目標一定有憑證（None 分支不被觸發）",
    -- core / unification：正確性、普遍性、occurs check、對偶（15 條，覆蓋 11 個標籤）
    "unification #1 正確性：σ 讓 f0(x1,f1) 與 f0(f2,x2) 相等",
    "unification #2 普遍性：σ(x1) = f2",
    "unification #3 普遍性：σ(x2) = f1",
    "unification #4（未觸發分支）這一對確實有 mgu",
    "unification #5 occurs check：x0 =? f3(x0) 不可合一",
    "unification #6 不可合一：不同常數 f0／f1 一定失敗",
    "unification #7 對稱性（左）：兩方向的 mgu 代換後給出同一個項",
    "unification #8 對稱性（右）：f4(f5,x1) 也一樣",
    "unification #9（未觸發分支）兩個方向都真的有 mgu",
    "anti-unification #1 lgg 保留共同結構：最外層是 f0 的二元節點",
    "anti-unification #2 第一個子項仍是 f1 節點",
    "anti-unification #3（未觸發分支）抽象出來的是新變數（≥100），不與原項串味",
    "anti-unification #4 不同子項被抽象成變數，第二個子項恰好帶一個變數",
    "anti-unification #5（未觸發分支）整個 lgg 的變數都在新變數空間裡",
    "anti-unification #6 lgg 是 join：lgg(x0,x1) 同時是兩邊的推廣",
    -- core / ramsey_ex：遞迴上界、Paley、夾擠、深度窗口、搜尋（46 條，對應 50 個 ramsey 標籤）
    "ramsey_ex #1 遞迴上界 R(2,5) ≤ 5（基底）",
    "ramsey_ex #2 遞迴上界 R(3,3) ≤ 6",
    "ramsey_ex #3 用精確種子後 R(3,4) 的界 = 9，而 Erdős–Szekeres 只給 10",
    "ramsey_ex #4 遞迴上界 R(4,4) ≤ 18",
    "ramsey_ex #5 遞迴上界 R(3,5) ≤ 14",
    "ramsey_ex #6 R(4,4) = 18 < 20 = C(6,3)",
    "ramsey_ex #7 3 ≤ k,l < 8 的 25 個點上遞迴上界永不比 Erdős–Szekeres 差",
    "ramsey_ex #8 上界本身也對稱（36 個點）",
    "ramsey_ex #9 種子 R(3,3) = 6 與窮舉一致",
    "ramsey_ex #10 種子 R(3,4) = 9 同理",
    "ramsey_ex Paley #1 P₁₇ 是自補圖",
    "ramsey_ex Paley #2 17 有 8 個非零平方剩餘",
    "ramsey_ex Paley #3 P₁₇ 有 68 條紅邊",
    "ramsey_ex Paley #4 P₁₇ 既無紅色 K₄ 也無藍色 K₄",
    "ramsey_ex Paley #5 自補性 ⇒ (4,5)-free",
    "ramsey_ex Paley #6 也 ⇒ (5,4)-free",
    "ramsey_ex Paley #7 全紅 K₁₇ 有 136 條邊",
    "ramsey_ex Paley #8 檢查器不是橡皮章：全紅 K₁₇ 被否決",
    "ramsey_ex Paley #9 P₅ = C₅ 有 5 條邊",
    "ramsey_ex 夾擠 #1 R(4,4) 的上界是 18",
    "ramsey_ex 夾擠 #2 所以 R(4,4) 被夾死",
    "ramsey_ex 夾擠 #3 夾死後下界 = 18",
    "ramsey_ex 夾擠 #4 見證是 P₁₇ 的 68 條紅邊",
    "ramsey_ex 夾擠 #5 見證通過獨立檢查（無紅 K₄、無藍 K₄）",
    "ramsey_ex 夾擠 #6 R(3,5) 的上界是 5+9 = 14",
    "ramsey_ex 夾擠 #7 所以 R(3,5) 也被夾死",
    "ramsey_ex 夾擠 #8 見證是 GG13 在 K₁₃ 上（無紅 K₃、無藍 K₅）",
    "ramsey_ex 夾擠 #9 R(4,4) = 18（精確值）",
    "ramsey_ex 夾擠 #10 R(3,5) = 14（精確值）",
    "ramsey_ex 夾擠 #11 與窮舉對帳：R(3,3) = 6",
    "ramsey_ex 夾擠 #12 與窮舉對帳：R(3,4) = 9",
    "ramsey_ex 夾擠 #13 夾不死就誠實回報 none（R(3,6)）",
    "ramsey_ex 夾擠 #14 R(3,6) 的上界是 20",
    "ramsey_ex 窗口 #1 ramseyWindow 3 = 18（舊版會去窮舉 R(4,4)）",
    "ramsey_ex 窗口 #2 ramseyWindow 2 = 6",
    "ramsey_ex 窗口 #3 ramseyWindow 1 = 2",
    "ramsey_ex 窗口 #4 窗口嚴格單調",
    "ramsey_ex 窗口 #5 窗口是安全上界（≥ 18）",
    "ramsey_ex 窗口 #6 d=4 的窗口不小於 d=3（R(5,5) 的界 64）",
    "ramsey_ex 搜尋 #1 R(2,2) = 2（由定義可算）",
    "ramsey_ex 搜尋 #2 R(2,5) = 5",
    "ramsey_ex 搜尋 #3 R(3,3) = 6",
    "ramsey_ex 搜尋 #4 R(3,4) = 9（結構性上界＋Z₈ 見證夾死）",
    "ramsey_ex 搜尋 #5 C(5,2) = 10（R(3,4) 的 Erdős–Szekeres 上界）",
    "ramsey_ex 搜尋 #6 R(4,4) ≤ C(6,3) = 20",
    "ramsey_ex 搜尋 #7 Erdős–Szekeres 上界不小於 Ramsey 值（6 ≤ 6）",
    -- iit 剩下的兩個樣本族：佔位符、有限 schema 穩定化（6 條）
    "iit：佔位符被拒 #1 正常的 Nat/Fin schema 通過良構性檢查",
    "iit：佔位符被拒 #2 索引換成 hole 之後 ichemaOK 一定回報錯誤",
    "iit：有限互遞迴 schema 穩定化 #1 第 4 階段（A 有 2 個、B 有 1 個）",
    "iit：有限互遞迴 schema 穩定化 #2 第 7 階段（a0、a1(b0)）",
    "iit：有限互遞迴 schema 穩定化 #3 第 8 階段居民數不變",
    "iit：有限互遞迴 schema 穩定化 #4 第 10 階段仍然相同（Kleene 鏈真的停住）",
    -- 三族審查補證：η 收縮的位移、α-等價、短路的正當性、列印、−1 對齊（24 條）
    "reflect / η #1 λx. * x ↦ *（f 裡沒有變數 0）",
    "reflect / η #2 f 裡有變數 0 時不能收縮",
    "reflect / η #3 去掉外層 λ 後自由變數往下移一層（λx. x₁x ↦ x₀）",
    "reflect / α-等價 #1 自反",
    "reflect / α-等價 #2 對稱",
    "reflect / α-等價 #3 遞移",
    "reflect / α-等價 #4 變數重新命名不改變等價類",
    "reflect / α-等價 #5 f(x,x) 與 f(x,y) 不等價",
    "reflect / α-等價檢查器 #1 良性憑證同樣被接受",
    "reflect / α-等價檢查器 #2 巢狀目標也一樣",
    "reflect / α-等價檢查器 #3 兩個檢查器在良性憑證上答案相同",
    "reflect / α-等價檢查器 #4 篡改過的憑證一樣被拒",
    "reflect / 列印 #1 任何項印出來至少一個字元（對所有項）",
    "reflect / 列印 #2 憑證其餘部分每格至少 3 個字元",
    "reflect / 列印 #3 不是空帳就一定印得出東西",
    "instances / 短路 #0 一般引理：頂層推導唯一 ⇒ 歧義清單為空（任意環境）",
    "instances / 短路 #1 envShow 的每個可達目標只有一條頂層推導",
    "instances / 短路 #2 所以沒有短路的版本在 envShow 上也是空的",
    "instances / 短路 #3 每個可達目標最多一條規則可套用",
    "instances / 短路 #4 envShow 沒有臨界對",
    "instances / 短路 #5 有短路與沒短路給出同一個答案",
    "instances / 短路 #6 對照組：envClash2 有臨界對且真的有歧義",
    -- 反射的一般律（2 條）：§6 的 η 樣本升級成對所有型別成立
    "reflect / 反射一般律 #1 對所有型別、所有深度、所有中性值：先 reflect 再 reify 等於直接 reify",
    "reflect / 反射一般律 #2 換成 nf 實際用的燃料 64 也一樣（η 擴張再收縮不動正規形式）",
    -- 前沿對帳（36 條）：反射原理的 club 結構、全域實例的「不造假」、IIT 的可判定範圍與初始代數唯一性
    "instances / 前沿 #1 輔助：典範化每一步只是「二選一」",
    "instances / 前沿 #2 輔助：摺疊結果一定落在原清單裡",
    "instances / 前沿 #3 **典範化不造假**：選出的推導一定來自輸入",
    "instances / 前沿 #4 最高優先級推導是原清單的子集（過濾不做發明）",
    "instances / 前沿 #5 臨界對不漏方向：每一對都是 `i < j`（無自環、無重複）",
    "instances / 前沿 #6 **臨界對完備**：任何可重疊的規則對都會被列進去",
    "instances / 前沿 #7 輔助：`findSome?` 回傳自己（而非映射值）時仍在清單裡",
    "instances / 前沿 #8 歧義見證一定是給定目標集裡的一個目標",
    "iit / 前沿 #1 輔助：錯誤清單全空 ⟺ 每一項都空",
    "iit / 前沿 #2 輔助：範圍檢查清單的成員 = 某個子項的檢查結果",
    "iit / 前沿 #3 輔助：整串索引通過 ⟺ 每個索引項都通過",
    "iit / 前沿 #4 輔助：建構子項的大小 `1 + 參數大小和`",
    "iit / 前沿 #5 輔助：參數清單大小是 head 加 tail",
    "iit / 前沿 #6 子項嚴格小於父項（簽名層的良基性）",
    "iit / 前沿 #7 **索引範圍檢查可靠**：通過檢查 ⇒ 索引變數都在範圍內（對所有項）",
    "iit / 前沿 #8 輔助：消除器的參數走訪 = 以自身為函式的走訪",
    "iit / 前沿 #9 輔助：兩個在遞迴參數上一致的函式，走訪結果相同",
    "iit / 前沿 #10 **消除器唯一**（有界版）：任何與簽名交換的 φ 都等於 `iitFold`",
    "iit / 前沿 #11 **初始代數的普遍性質**：`iitFold s h` 是唯一與簽名交換的映射",
    "iit / 前沿 #12 §5 的 ι 律正是唯一性的特例（φ = 重建函式）",
    "iit / 前沿 #13 輔助：不含佔位符的清單，每個成員都不含佔位符",
    "iit / 前沿 #14 **索引範圍檢查完備**：不含佔位符且變數都在範圍內 ⇒ 檢查通過（與 #7 合起來就是精確刻畫）" ]

/-! ### 存在性檢查（編不過就代表登記清單與定理對不上） -/

section Checks

#check @Ramsey.paley_red_edges
#check @Ramsey.paley_symm
#check @Ramsey.paley17_no_mono_K4
#check @Ramsey.circ8_red_edges
#check @Ramsey.circ8_no_red3
#check @Ramsey.circ8_no_blue4
#check @Ramsey.circ8_no_red3_no_blue4
#check @Ramsey.r33_le_6
#check @Ramsey.r34_le_10
#check @Ramsey.r34_le_9
#check @Ramsey.r43_le_9
#check @Ramsey.r44_le_18
#check @Ramsey.ramsey34_eq
#check @Ramsey.ramsey44_eq
#check @Ramsey.r35_le_14
#check @Ramsey.gg13_no_red3
#check @Ramsey.gg13_no_blue5
#check @Ramsey.ramsey35_eq
#check @Graph.handshake
#check @Matroid.compl_compl
#check @Matroid.dual_dual
#check @Matroid.dual_dual_bases
#check @Matroid.graphic_rank_full
#check @Matroid.graphic_rank_axioms
#check @Matroid.graphic_exchange
#check @Matroid.graphic_greedy_optimal
#check @Matroid.dual_rank_complement
#check @Matroid.dual_dual_rank
#check @Matroid.dual_exchange
#check @Matroid.linear_rank_full
#check @Matroid.linear_indep
#check @Matroid.linear_closure
#check @Matroid.linear_exchange
#check @Simplicial.euler_poincare
#check @Simplicial.euler_poincare_complex
#check @Simplicial.circle_euler
#check @Simplicial.circle_betti_zero
#check @Simplicial.circle_betti_one
#check @Simplicial.circle_chain
#check @Simplicial.disk_euler
#check @Simplicial.disk_betti_one
#check @Simplicial.disk_betti_two
#check @Simplicial.disk_f_vector_len
#check @Simplicial.disk_f0_ge_f1
#check @Simplicial.disk_f_vector_alt
#check @Simplicial.twoPoints_euler
#check @Simplicial.good_cover_glues
#check @Simplicial.good_cover_no_obstruction
#check @Simplicial.bad_cover_not_glues
#check @Simplicial.bad_cover_obstruction
#check @Simplicial.good2_cover_glues
#check @Simplicial.good2_cover_no_obstruction
#check @KtLaws.IIT.evenOdd_schema_ok
#check @KtLaws.IIT.evenOdd_stage1
#check @KtLaws.IIT.evenOdd_stage2
#check @KtLaws.IIT.evenOdd_stage6
#check @KtLaws.IIT.evenOdd_grows
#check @KtLaws.IIT.evenOdd_sound
#check @KtLaws.IIT.evenOdd_sorted
#check @KtLaws.IIT.finite_stage4
#check @KtLaws.IIT.finite_stage7
#check @KtLaws.IIT.natFin_schema_ok
#check @KtLaws.IIT.natFin_stage1_fin_empty
#check @KtLaws.IIT.natFin_stage2
#check @KtLaws.IIT.natFin_stage3
#check @KtLaws.IIT.natFin_fz_z_checks
#check @KtLaws.IIT.natFin_fz_z_index
#check @KtLaws.IIT.natFin_fs_bad1_rejected
#check @KtLaws.IIT.natFin_fs_ok
#check @KtLaws.IIT.natFin_fs_ok_index
#check @KtLaws.IIT.natFin_fs_bad2_rejected
#check @KtLaws.IIT.natFin_fz_z_at
#check @KtLaws.IIT.natFin_fz_z_at_wrong
#check @KtLaws.IIT.natFin_monotone
#check @KtLaws.IIT.natFin_chain_sound
#check @KtLaws.IIT.natFin_chain_sorted
#check @KtLaws.IIT.natFin_chain_grows
#check @KtLaws.IIT.iota_law
#check @KtLaws.IIT.termination_certified
#check @KtLaws.IIT.measure_decrease
#check @KtLaws.IIT.evenOdd_index_acyclic
#check @KtLaws.IIT.natFin_index_acyclic
#check @KtLaws.IIT.finite_index_acyclic
#check @KtLaws.IIT.evenOdd_data_cycle
#check @KtLaws.IIT.evenOdd_no_index_edges
#check @KtLaws.IIT.iit_fold_iota
#check @KtLaws.IIT.subterm_decrease
#check @KtLaws.IIT.ivalSize_lt_of_mem
#check @KtLaws.IIT.icheckAt_sound
#check @KtLaws.IIT.stage_inflates
#check @KtLaws.IIT.stage_sound
#check @KtLaws.IIT.enumerate_sound
#check @KtLaws.IIT.enumerate_sort
#check @KtLaws.IIT.enumerate_mono
#check @KtLaws.IIT.beta1_src_checks
#check @KtLaws.IIT.beta1_reduct_is_arg
#check @KtLaws.IIT.beta1_reduct_checks
#check @KtLaws.IIT.beta1_index_preserved
#check @KtLaws.IIT.beta2_src_checks
#check @KtLaws.IIT.beta2_reduct_is_lam
#check @KtLaws.IIT.beta2_reduct_checks
#check @KtLaws.IIT.beta2_index_preserved
#check @KtLaws.IIT.beta2_arg_weakened
#check @KtLaws.IIT.beta_zero_fuel_keeps_term
#check @KtLaws.IIT.beta_lam_is_stuck
#check @KtLaws.IIT.weaken_var_is_vs
#check @KtLaws.IIT.weaken_var_checks
#check @KtLaws.IIT.weaken_var_ty_preserved
#check @KtLaws.IIT.weaken_var_ctx_changes
#check @KtLaws.IIT.weaken_lam_checks
#check @KtLaws.IIT.weaken_lam_ctx_inserted
#check @KtLaws.IIT.weaken_twice_checks
#check @KtLaws.IIT.weaken_twice_depth
#check @KtLaws.IIT.weaken_bad_app_rejected
#check @KtLaws.IIT.subject_reduction_battery
#check @KtLaws.IIT.battery_terms_check
#check @KtLaws.IIT.battery_bat4_nf
#check @KtLaws.IIT.battery_nf_checks
#check @KtLaws.IIT.norm_reaches_arg
#check @KtLaws.IIT.norm_result_is_stuck
#check @KtLaws.IIT.stuck_app_does_not_beta
#check @KtLaws.IIT.stuck_app_checks
#check @KtLaws.IIT.norm_zero_fuel
#check @KtLaws.IIT.norm_one_step_then_stuck
#check @KtLaws.IIT.norm_ex_app2_checks
#check @KtLaws.IIT.stlc_schema_ok
#check @KtLaws.IIT.stlc_id_term_checks
#check @KtLaws.IIT.stlc_id_term_index
#check @KtLaws.IIT.stlc_id_term_wrong_ctx
#check @KtLaws.IIT.stlc_bad_app_rejected
#check @KtLaws.IIT.stlc_good_app_checks
#check @KtLaws.IIT.stlc_good_app_index
#check @KtLaws.IIT.stlc_var_index
#check @KtLaws.IIT.stlc_var_wrong_index
#check @KtLaws.Instances.sld_show_int
#check @KtLaws.Instances.sld_show_array_int
#check @KtLaws.Instances.sld_show_array_array_bool
#check @KtLaws.Instances.sld_show_pair
#check @KtLaws.Instances.sld_no_eq_instance
#check @KtLaws.Instances.sld_single_derivation
#check @KtLaws.Instances.sld_rule_index
#check @KtLaws.Instances.sld_kid_rule
#check @KtLaws.Instances.sld_depth_and_size
#check @KtLaws.Instances.terminating_env_show
#check @KtLaws.Instances.terminating_env_loop
#check @KtLaws.Instances.terminating_env_loop_some
#check @KtLaws.Instances.measure_decreases_show
#check @KtLaws.Instances.terminating_env_clash
#check @KtLaws.Instances.overlap_one_critical_pair
#check @KtLaws.Instances.overlap_two_derivations
#check @KtLaws.Instances.overlap_canonical_picks_specific
#check @KtLaws.Instances.overlap_coherent
#check @KtLaws.Instances.clash_witness_some
#check @KtLaws.Instances.clash_witness_is_goal
#check @KtLaws.Instances.clash_not_coherent
#check @KtLaws.Instances.env_show_no_critical_pairs
#check @KtLaws.Instances.axiomatic_fragment_ok
#check @KtLaws.Instances.axiomatic_matroidal
#check @KtLaws.Instances.axiomatic_no_failure
#check @KtLaws.Instances.axiomatic_rank_1
#check @KtLaws.Instances.axiomatic_rank_2
#check @KtLaws.Instances.axiomatic_rank_3
#check @KtLaws.Instances.axiomatic_no_jump
#check @KtLaws.Instances.axiomatic_no_submodularity_counterexample
#check @KtLaws.Instances.exchange_alone_says_matroid
#check @KtLaws.Instances.strict_says_not_matroid
#check @KtLaws.Instances.failure_reason_is_R3
#check @KtLaws.Instances.jump_witness
#check @KtLaws.Instances.needs_composition_rank_empty
#check @KtLaws.Instances.needs_composition_rank_axiom
#check @KtLaws.Instances.needs_composition_rank_composite_only
#check @KtLaws.Instances.needs_composition_rank_both
#check @KtLaws.Instances.needs_composition_jump_two
#check @KtLaws.Instances.needs_composition_submodularity_exists
#check @KtLaws.Instances.needs_composition_submodularity_witness
#check @KtLaws.Instances.needs_composition_not_axiomatic
#check @KtLaws.Instances.criterion_agrees
#check @KtLaws.Instances.criterion_has_matroid_samples
#check @KtLaws.Instances.criterion_has_non_matroid_samples
#check @KtLaws.Instances.criterion_counts_agree
#check @KtLaws.Instances.criterion_composite_reaches
#check @KtLaws.Instances.criterion_composite_not_matroidal
#check @KtLaws.Instances.wild_coverage_not_disjoint
#check @KtLaws.Instances.wild_not_matroidal
#check @KtLaws.Instances.harmless_no_composite_reach
#check @KtLaws.Instances.harmless_matroidal
#check @KtLaws.Instances.harmful_composite_reaches
#check @KtLaws.Instances.harmful_not_matroidal
#check @KtLaws.Instances.greedy_forward_length
#check @KtLaws.Instances.greedy_backward_length
#check @KtLaws.Instances.greedy_backward_bigger
#check @KtLaws.Instances.greedy_forward_minimal
#check @KtLaws.Instances.greedy_backward_minimal
#check @KtLaws.Instances.greedy_forward_solves
#check @KtLaws.Instances.greedy_backward_solves
#check @KtLaws.Instances.greedy_axiomatic_but_not_minimum
#check @KtLaws.Instances.minimal_basis_length
#check @KtLaws.Instances.minimal_basis_is_minimal
#check @KtLaws.Instances.minimal_basis_ignores_useless
#check @KtLaws.Instances.derivability_flat_exchange
#check @KtLaws.Instances.derivability_shared_exchange
#check @KtLaws.Instances.line_glues
#check @KtLaws.Instances.line_glued_value
#check @KtLaws.Instances.line_structurally_ok
#check @KtLaws.Instances.mobius_not_glues
#check @KtLaws.Instances.mobius_obstruction_some
#check @KtLaws.Instances.mobius_glued_none
#check @KtLaws.Instances.mobius_zero_glues
#check @KtLaws.Instances.mobius_trivial_glues
#check @KtLaws.Instances.mobius_monodromy_some
#check @KtLaws.Instances.trivial_monodromy_none
#check @KtLaws.Instances.mobius_zero_glued_value
#check @KtLaws.Instances.mobius_trivial_glued_value
#check @KtLaws.Instances.nerve_line_glues
#check @KtLaws.Instances.nerve_circle_not_glues
#check @KtLaws.Instances.nerve_circle_obstruction
#check @KtLaws.Instances.nerve_line_no_obstruction
#check @KtLaws.Instances.mirror_twice_length
#check @KtLaws.Instances.mirror_twice_names
#check @KtLaws.Instances.mirror_forward_derivable
#check @KtLaws.Instances.mirror_dual_derivable
#check @KtLaws.Instances.mirror_forward_not_derivable
#check @KtLaws.Instances.mirror_dual_not_derivable
#check @KtLaws.Instances.ramsey_window_3
#check @KtLaws.Instances.pigeonhole_window_3
#check @KtLaws.Instances.ramsey_wider_than_pigeonhole
#check @KtLaws.Instances.ramsey_window_4_beats_erdos_szekeres
#check @KtLaws.Instances.ramsey_window_4_ge_34
#check @KtLaws.Instances.mirror_fingerprint_heads
#check @KtLaws.Instances.mirror_fingerprint_differs
#check @KtLaws.Instances.mirror_fingerprint_nonempty
#check @KtLaws.Instances.universe_not_small
#check @KtLaws.Instances.complete_env_show_coherent
#check @KtLaws.Instances.complete_env_show_no_report
#check @KtLaws.Instances.complete_env_minimal_coherent
#check @KtLaws.Instances.complete_env_clash_incoherent
#check @KtLaws.Instances.complete_env_clash_report
#check @KtLaws.Instances.complete_env_clash_report_some
#check @KtLaws.Instances.universe_has_array
#check @KtLaws.Instances.universe_has_pair
#check @KtLaws.Instances.universe_has_deep
#check @KtLaws.Instances.peaks_env_show
#check @KtLaws.Instances.peaks_env_minimal
#check @KtLaws.Instances.peaks_env_clash
#check @KtLaws.Instances.peaks_env_prio
#check @KtLaws.Instances.prio_one_critical_pair
#check @KtLaws.Instances.prio_coherent
#check @KtLaws.Instances.env_show_no_pairs
#check @KtLaws.Instances.minimal_no_critical_pairs
#check @KtLaws.Instances.minimal_coherent
#check @KtLaws.Instances.minimal_no_overlaps
#check @KtLaws.Instances.local_instance_breaks
#check @KtLaws.Instances.local_instance_higher_prio_ok
#check @KtLaws.Instances.local_instance_unrelated_ok
#check @KtLaws.Instances.local_instance_witness
#check @KtLaws.Instances.local_instance_witness_some
#check @KtLaws.Instances.stable_unrelated
#check @KtLaws.Instances.stable_more_specific_unstable
#check @KtLaws.Instances.stable_witness_is_int
#check @KtLaws.Instances.stable_witness_some
#check @KtLaws.Instances.stable_catch_all_same_prio
#check @KtLaws.Instances.stable_catch_all_high_prio
#check @KtLaws.Instances.stable_deterministic
#check @KtLaws.Instances.newman_env_show_terminating
#check @KtLaws.Instances.newman_env_show_local
#check @KtLaws.Instances.newman_env_show_global
#check @KtLaws.Instances.newman_clash_terminating
#check @KtLaws.Instances.newman_clash_not_local
#check @KtLaws.Instances.newman_clash_not_global
#check @KtLaws.Instances.newman_loop_not_terminating
#check @KtLaws.Instances.newman_no_counterexample
#check @Ordinal.cmpNat_eq_iff
#check @Ordinal.cmpNat_swap
#check @Ordinal.cmp_eq_iff
#check @Ordinal.cmp_swap
#check @Ordinal.cmp_self
#check @Ordinal.leq_refl
#check @Ordinal.leq_total
#check @Ordinal.leq_antisymm
#check @Ordinal.max_upper_left
#check @Ordinal.max_upper_right
#check @Ordinal.max_is_one
#check @Ordinal.max_comm
#check @Ordinal.max_idem
#check @Ordinal.max_is_join
#check @Ordinal.cmpNat_lt
#check @Ordinal.cmpNat_lt_trans
#check @Ordinal.cmp_lt_trans
#check @Ordinal.leq_trans
#check @Ordinal.max_le_iff
#check @Ordinal.max_assoc
#check @Ordinal.max_assoc_eq
#check @Ordinal.cnf_absorption
#check @Ordinal.cnf_succ_gt
#check @Ordinal.cnf_omega_two
#check @Ordinal.cnf_one_plus_succ_omega
#check @Ordinal.cnf_omega_plus_square
#check @Ordinal.cnf_finite_below_tower
#check @Ordinal.cnf_assoc
#check @Ordinal.cnf_tower
#check @Ordinal.cnf_normal_closed
#check @Ordinal.cnf_mul_omega


#check @KtLaws.Reflect.nbe_beta
#check @KtLaws.Reflect.nbe_idempotent
#check @KtLaws.Reflect.nbe_eta
#check @KtLaws.Reflect.nbe_eval_neutral
#check @KtLaws.Reflect.nbe_check_terminates
#check @KtLaws.Reflect.nbe_check_preserved
#check @KtLaws.Reflect.nbe_check_rejects

#check @KtLaws.Reflect.proof_decide_fast
#check @KtLaws.Reflect.proof_cert_checks
#check @KtLaws.Reflect.proof_cert_size
#check @KtLaws.Reflect.proof_cert_exists
#check @KtLaws.Reflect.proof_second_sample_exists
#check @KtLaws.Reflect.proof_second_sample_decides
#check @KtLaws.Reflect.proof_unequal_decides
#check @KtLaws.Reflect.proof_unequal_no_cert
#check @KtLaws.Reflect.proof_tampered_end
#check @KtLaws.Reflect.proof_tampered_start
#check @KtLaws.Reflect.proof_decide_agrees
#check @KtLaws.Reflect.proof_cert_printable
#check @KtLaws.Reflect.proof_printed_still_checks
#check @KtLaws.Reflect.proof_size_is_length
#check @KtLaws.Reflect.proof_print_at_least_two
#check @KtLaws.Reflect.proof_last_is_nf
#check @KtLaws.Reflect.link_checks
#check @KtLaws.Reflect.link_depth_two
#check @KtLaws.Reflect.link_shape
#check @KtLaws.Reflect.link_root_goal
#check @KtLaws.Reflect.link_nested_checks
#check @KtLaws.Reflect.link_nested_depth
#check @KtLaws.Reflect.link_nested_shape
#check @KtLaws.Reflect.link_no_rules
#check @KtLaws.Reflect.link_no_cert
#check @KtLaws.Reflect.link_tampered_root
#check @KtLaws.Reflect.link_tampered_kid
#check @KtLaws.Reflect.link_one_kid
#check @KtLaws.Reflect.link_cert_exists

#check @KtLaws.Unify.unify_correct
#check @KtLaws.Unify.unify_generality_x
#check @KtLaws.Unify.unify_generality_y
#check @KtLaws.Unify.unify_exists
#check @KtLaws.Unify.unify_occurs
#check @KtLaws.Unify.unify_constants
#check @KtLaws.Unify.unify_symm_left
#check @KtLaws.Unify.unify_symm_right
#check @KtLaws.Unify.unify_symm_both
#check @KtLaws.Unify.lgg_shape
#check @KtLaws.Unify.lgg_first_child
#check @KtLaws.Unify.lgg_second_child_fresh
#check @KtLaws.Unify.lgg_second_child_one_var
#check @KtLaws.Unify.lgg_vars_are_fresh
#check @KtLaws.Unify.lgg_is_join

#check @KtLaws.RamseyEx.rec_bound_25
#check @KtLaws.RamseyEx.rec_bound_33
#check @KtLaws.RamseyEx.rec_bound_34_beats
#check @KtLaws.RamseyEx.rec_bound_44
#check @KtLaws.RamseyEx.rec_bound_35
#check @KtLaws.RamseyEx.rec_bound_44_lt_es
#check @KtLaws.RamseyEx.rec_bound_never_worse
#check @KtLaws.RamseyEx.rec_bound_symm
#check @KtLaws.RamseyEx.seed_33
#check @KtLaws.RamseyEx.seed_34
#check @KtLaws.RamseyEx.paley_self_complementary
#check @KtLaws.RamseyEx.paley_qr_count
#check @KtLaws.RamseyEx.paley_edges_count
#check @KtLaws.RamseyEx.paley_free_44
#check @KtLaws.RamseyEx.paley_free_45
#check @KtLaws.RamseyEx.paley_free_54
#check @KtLaws.RamseyEx.complete_edges_17
#check @KtLaws.RamseyEx.complete_not_free
#check @KtLaws.RamseyEx.paley_five_edges
#check @KtLaws.RamseyEx.pin_44_upper
#check @KtLaws.RamseyEx.pin_44_pinned
#check @KtLaws.RamseyEx.pin_44_lower
#check @KtLaws.RamseyEx.pin_44_witness_edges
#check @KtLaws.RamseyEx.pin_44_witness_free
#check @KtLaws.RamseyEx.pin_35_upper
#check @KtLaws.RamseyEx.pin_35_pinned
#check @KtLaws.RamseyEx.pin_35_witness_free
#check @KtLaws.RamseyEx.pin_exact_44
#check @KtLaws.RamseyEx.pin_exact_35
#check @KtLaws.RamseyEx.pin_exact_33
#check @KtLaws.RamseyEx.pin_exact_34
#check @KtLaws.RamseyEx.pin_exact_36_none
#check @KtLaws.RamseyEx.pin_upper_36
#check @KtLaws.RamseyEx.window_3
#check @KtLaws.RamseyEx.window_2
#check @KtLaws.RamseyEx.window_1
#check @KtLaws.RamseyEx.window_monotone
#check @KtLaws.RamseyEx.window_safe
#check @KtLaws.RamseyEx.window_4
#check @KtLaws.RamseyEx.search_22
#check @KtLaws.RamseyEx.search_25
#check @KtLaws.RamseyEx.search_33
#check @KtLaws.RamseyEx.search_34
#check @KtLaws.RamseyEx.search_es_34
#check @KtLaws.RamseyEx.search_es_44
#check @KtLaws.RamseyEx.search_es_ge

#check @KtLaws.IIT.hole_natFin_ok
#check @KtLaws.IIT.hole_rejected
#check @KtLaws.IIT.finite_stage4_stable
#check @KtLaws.IIT.finite_stage7_stable
#check @KtLaws.IIT.finite_stage8_same
#check @KtLaws.IIT.finite_stage10_same

#check @KtLaws.Reflect.eta_contracts_star
#check @KtLaws.Reflect.eta_blocked
#check @KtLaws.Reflect.eta_contract_shifts
#check @KtLaws.Reflect.nbe_reify_refl_neutral
#check @KtLaws.Reflect.nbe_reify_reflect_fuel
#check @KtLaws.Instances.pick_eq_or
#check @KtLaws.Instances.foldl_pick_mem
#check @KtLaws.Instances.canonical_mem
#check @KtLaws.Instances.maximalDerivs_subset
#check @KtLaws.Instances.criticalPairs_lt
#check @KtLaws.Instances.criticalPairs_complete
#check @KtLaws.Instances.mem_of_findSome?_self
#check @KtLaws.Instances.incoherenceWitness_mem
#check @KtLaws.IIT.firstErr_eq_none
#check @KtLaws.IIT.mem_itermScopeList
#check @KtLaws.IIT.firstErr_itermScopeList_none
#check @KtLaws.IIT.itermSize_ctor
#check @KtLaws.IIT.itermSizeList_cons
#check @KtLaws.IIT.itermSize_lt_ctor
#check @KtLaws.IIT.itermScopeOK_sound
#check @KtLaws.IIT.foldArgs_eq_foldArgsWith
#check @KtLaws.IIT.foldArgsWith_congr
#check @KtLaws.IIT.iitFold_unique_aux
#check @KtLaws.IIT.iitFold_unique
#check @KtLaws.IIT.iit_fold_iota_is_instance
#check @KtLaws.IIT.hasHoleList_false
#check @KtLaws.IIT.itermScopeOK_complete
#check @KtLaws.Reflect.variant_refl
#check @KtLaws.Reflect.variant_symm
#check @KtLaws.Reflect.variant_trans
#check @KtLaws.Reflect.variant_renames
#check @KtLaws.Reflect.variant_distinguishes
#check @KtLaws.Reflect.variant_accepts
#check @KtLaws.Reflect.variant_accepts_nested
#check @KtLaws.Reflect.variant_agrees
#check @KtLaws.Reflect.variant_rejects_tampering
#check @KtLaws.Reflect.termText_pos
#check @KtLaws.Reflect.certTextAux_ge
#check @KtLaws.Reflect.certText_pos
#check @KtLaws.Instances.ambiguityFilter_nil_of_unique_top
#check @KtLaws.Instances.coherence_unique_top_envShow
#check @KtLaws.Instances.coherence_no_ambiguity_envShow
#check @KtLaws.Instances.coherence_single_rule_envShow
#check @KtLaws.Instances.coherence_no_critical_pairs
#check @KtLaws.Instances.coherence_shortcut_agrees
#check @KtLaws.Instances.coherence_shortcut_needs_hypothesis

#check @KtLaws.Instances.uSize_apply
#check @KtLaws.Instances.sum_map_le_of_count_le
#check @KtLaws.Instances.root_size_decreases
#check @KtLaws.Instances.uSizeList_rewrite_lt
#check @KtLaws.Instances.rewrites_size_decreases
#check @KtLaws.Instances.rewrites_restriction_wf
#check @KtLaws.Instances.envShow_rules_measureDecreasing
#check @KtLaws.Instances.envShow_terminating
#check @KtLaws.Instances.ct_orientable_node_measure
#check @KtLaws.Instances.ct_bodyterm_size
#check @KtLaws.Instances.ct_headterm_size
#check @KtLaws.Instances.ct_step
#check @KtLaws.Instances.kt_node_measure_orientation_unsound
#check @KtLaws.Reflect.reifyN_isBetaNormal
#check @KtLaws.Reflect.nf_beta_normal

end Checks

/-- 登記條數（編譯期就確定，不是執行期數的）。 -/
example : provedLaws.length = 466 := rfl

#eval s!"lean 側已證明並登記：{provedLaws.length} 條（MoonBit 側目前總數 551／互異 453）"
