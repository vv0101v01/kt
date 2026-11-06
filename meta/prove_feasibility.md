# 〈437 條定律搬進 `moon prove`（Why3 + Z3）〉可行性評估

> 這是一份**決策文件**，不是成果宣稱。所有數字都是本機實測，指令與輸出原文照抄，
> 任何人都能在同一份工具鏈上重跑。日期：2026-11-04。
> 結論先講：**我不認為能在合理成本內把 437 條全部交給 Why3 + Z3**，理由是下面第 4 節
> 那些** lowering 缺口**正好卡在本倉定律的形狀上，不是「多花時間就行」的問題。

---

## 1. 環境（實測可行，且比想像中容易）

```text
moon 0.1.20261102 (ea07287 2026-11-02)      # 已內建 Why3（~/.moon/share/why3、~/.moon/lib/prelude_proof）
z3 4.13.3                                    # apt-get install z3，唯一需要自己裝的東西
moon prove lib                               # 直接可用，不需要另外 opam 安裝 why3（1.8 以後的行為）
```

套件開關（`moon.pkg`，非舊版 json）：

```text
options(
  "proof-enabled": true,
)
```

管線本身是忠實的：`.mbt` + `.mbtp` → `_build/verif/<pkg>/<pkg>.mlw` → Z3。
生成的 WhyML 可讀（約 60 行的迴圈函式），`Int` 被包成 `Int.t`（有 `.model` 投影），
迴圈自動產生 `variant`（`length - i`）。

---

## 2. 一次就過的（好消息）

| 測試 | 形狀 | 結果 |
|---|---|---|
| `nadd_logic_hom` | 對 ADT 的結構遞迴 `lemma`，`proof_decrease: a` | **proved**（Z3 自動做歸納） |
| `nadd_logic_right_unit` | 同上，歸納到 `NZ`/`NS` | **proved** |
| `count_above` 的迴圈不變量 | 迴圈 + `0 ≤ acc ≤ i ≤ length` → 後置條件 `0 ≤ result ≤ length` | **proved**（13 個子目標全過） |

這一類是 `moon prove` 真正擅長的：**不變量式**的性質陳述。

---

## 3. 卡住的（壞消息，且是本倉的主體形狀）

| 測試 | 形狀 | 結果 |
|---|---|---|
| `pinned`：`result == 2`，前置條件把 4 元素陣列完全釘死 | **具體值**的後置條件 | **Z3 timeout**（13 子目標過、後置條件那條超時） |
| `rb(4,4) == 18` 的邏輯版 | 對 `Int` 的遞迴計算 | lowering 直接拒絕：`Cannot prove termination for rb_logic` |
| 給它 `proof_decrease: a + b` | 同上 | `invalid #proof_decrease: add is not a logic function`（`Int` 沒有算術 variant） |
| 邏輯函式裡寫條件式 `(if c { x } else { y }) + …` | 規格要在表達式裡分枝 | `3002 unexpected if`（`.mbtp` 的 `if` 只能在函式體頂層） |
| 契約本體呼叫未簽約的輔助函式 | 我們的 `law_*` 全都這樣寫 | `4207 only contracted functions … can be called in contracted function bodies` |

還有一個量測陷阱：`moon prove` 有**增量快取導致的假成功**——同一個套件明明有編譯錯誤，
摘要仍印 `Succeeded: 2 goals proved`（與上游 issue #2372 同型）。每次判斷前必須 `rm -rf _build`。

---

## 4. 決定性的三個 lowering 缺口

1. **`#proof_pure` 不支援遞迴、也不支援契約。** 它是「同一份實作同時給程式端與邏輯端看」的
   唯一橋樑；文件白紙黑字寫著 *direct recursion, and mutual recursion are not yet supported*。
   而 `meta/*` 幾乎每個函式都是對 ADT／`Array` 的遞迴。**結果：定律裡的 `f(...)` 不能是實作本身，
   只能是 `.mbtp` 裡另寫一份邏輯副本**——這正是我們上一輪才剛剛消滅掉的「同語義雙實作」。
2. **`Int` 上沒有算術 variant，`.mbtp` 也沒有條件式。** 我們的定律大量是
   `if/match` 分支 + 遞迴累加（`ramsey_rec_bound`、`iit_stage`、`stlc_norm`），
   這種形狀在 `.mbtp` 裡連**寫出來**都困難，別說證明。
3. **SMT 不做計算。** 第 3 節的 `pinned` 是四步就能算完的具體值，Z3 仍超時；
   我們的定律裡 **44/54 個 law 函式含字面值比較、13 個驅動列舉迴圈**（實測統計），
   每一條都得改寫成「不變量 + 手工展開 + 輔助引理」才可能過。

---

## 5. 成本估計（若硬做）

- 一條具體值定律 → 需要：邏輯側副本（可能上百行）＋ 前綴和型不變量 ＋ 展開用的輔助引理 ＋ 調 Z3。
  以本機實測的最小例子估，**每條 0.5–1.5 小時**，且部分條目（Kleene 鏈、Ramsey 遞迴）可能根本不過。
- 437 條 ⇒ **200–600 小時**，且需要維護一份與 `.mbt` 同步的邏輯副本（漂移風險）。
- 這與「把定律搬進證明助手」原本的意圖（提高可信度）**方向相反**：證明的是副本，不是跑得動的程式。

## 6. 建議（不是拒絕，是換一條路）

1. **閘門不變**：`moon check --deny-warn` ＋ `arch_check` ＋ 437 條執行期定律。這些是**可執行**的，
   壞掉會紅，可信度來自「每次執行都重算」。
2. **新增一支可選的「已證明核心」**：挑 30–60 條**結構性**定律（序數 join 律、擬陣對偶對合、
   一致性判準的局部引理、STLC 索引傳輸的交換律），放進獨立聯邦 `proof/`，
   用 `moon prove` 真的證明，並在 `meta/README.md` 標明「已由 SMT 證明 / 未證明，僅執行」。
   這給出的是**分層可信度**，而不是把 437 條全部假裝成定理。
3. 若目標是「metatheorem 級」的可信度，長期還是得走 Agda/Lean（§10 第 5 條），
   Why3 適合的是**演算法層**的性質，不是型別論的歸納定義。

---

### 附：本次 pilot 的位置

`/home/user/pilot`（**不在**本倉內，避免污染 `arch_check` 的檔案計數）：

```text
pilot/lib/nat.mbt       ADT Nat + 遞迴計算
pilot/lib/hits.mbt      迴圈 + 不變量 + 具體值釘死（timeout 的那一條）
pilot/lib/laws.mbtp     邏輯側副本、兩條歸納引理、pin4 / sum4 嘗試
_build/verif/lib/*.mlw  生成的 WhyML（可讀，值得一看）
```
