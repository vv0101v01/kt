# `cmd/metatheory/` — 第九聯邦執行入口：逐條重算型別論與跨聯邦元理論定律總表

> **架構位置**：`architecture.json` 中的 `cmd-metatheory`，**Package Layer 3 / Component Layer 3**（`is-main` 可執行套件），依賴 `meta-core`、`meta-instances`、`meta-iit`、`meta-reflect`。
> 聯邦歸屬：**F9 `meta`**（第九聯邦 CLI 閘門）。
> 執行指令：`moon run cmd/metatheory --target wasm-gc`。

---

## 1. 一句話定位

不引用主倉業務程式碼、不讀取預存快照，在零外部業務依賴的第九聯邦內**逐條即時重算全體 `545` 條元理論定律**並統計互異命題數與定律族數，任一條失敗即以 `abort` 終止 CI。

---

## 2. 檔案清單（1 個 `.mbt`，共 125 行）

| 檔案 | 行數 | 職責 |
|---|---:|---|
| `main.mbt` | 125 | 串聯四個子套件由 `tools/gen_laws.py` 自動彙整之 `laws_core()`、`laws_instances()`、`laws_iit()`、`laws_reflect()`，格式化輸出每條定律之標籤、命題陳述與具體見證，最後輸出總計並執行全過斷言 |

---

## 3. 驗證規模與閘門輸出

* 登記 `law_*` 函式總數：**`86` 個**（`meta/core: 37`、`meta/instances: 24`、`meta/iit: 15`、`meta/reflect: 10`）
* 通過定律總數：**`通過 545 / 545 定律`**（`448` 條互異標籤、`179` 個定律族）
* CI 雙重守門：`python3 tools/gen_laws.py` 後 `git diff --exit-code meta/*/laws.mbt` 必須為空，且 `moon run cmd/metatheory --target wasm-gc` 必須全數通過。
