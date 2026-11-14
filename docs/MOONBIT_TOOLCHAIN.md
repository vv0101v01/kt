# MoonBit 正式工具鏈與現行語法

## 本次取得及核對

核對日期：**2026-11-14（香港）**。

官方 `latest`（**非 nightly**）安裝通道及 `https://cli.moonbitlang.com/version.json` 當時回報：

```text
moon    0.1.20261104 (940aa18 2026-11-04)
moonc   v0.10.20+65efd5b93 (2026-11-05)
moonrun 0.1.20261104 (940aa18 2026-11-04)
feature flags: rr_moon_mod, rr_moon_pkg
```

安裝不是只看搜尋標題：下載官方安裝腳本、閱讀後執行，實際呼叫 `moon version --all` / `moonc -v`，並以官方 `moonbit-linux-x86_64.sha256` 核對 **18 個工具鏈檔案，全部 OK**。這是官方發布檔案一致性核對，不另宣稱完成可重現原始碼建置或獨立供應鏈審計。

官方 2026-11-05 release note 的標題是 **v0.10.19**，而當前下載 metadata／二進位已是 **v0.10.20**；不要把 release-note 標題當成實際安裝版號。

本工作區安裝於 `/home/user/.cache/moonbit`。工具鏈和編譯快取不打包到原始碼交付；新環境按下列步驟重建。

## 固定同版重建

`.moonbit-version` 與 CI 固定 `0.10.20+65efd5b93`，依賴仍為 `moonbitlang/async@0.22.5`，沒有因本次橋審計任意升級第三方 API。

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh -o /tmp/install-moonbit.sh
# 可先閱讀腳本，再安裝指定發佈版本
bash /tmp/install-moonbit.sh "$(cat .moonbit-version)"
export PATH="$HOME/.moon/bin:$PATH"
moon version --all
moon update
moon check --deny-warn --target wasm-gc
moon build --target wasm-gc
```

核對到新版本時應先做相同驗收，再更新 pin；不要把 CI 的正式發佈 pin 換成 nightly。

## 已查閱並以編譯器驗證的語法

| 主題 | 本次採用 |
|---|---|
| Derive | 型別之前的 `#derive(Debug, Eq)`，不新增舊式尾置 `derive(...)` |
| 明確整數寬度 | `Int32` / `UInt32`；需要防止三角不等式加總溢位時轉 `Int64` |
| Trait 方法附著 | 明示 `pub extend T with Eq::{not_equal, equal}`、`Debug::{to_repr}` |
| 封裝與報告 | 不可偽造的不變量要用封裝型別；公開 `pub(all)` report 不冒稱 sealed proof |
| 可選標籤參數 | `precomputed~ : T? = None`，呼叫 `precomputed=Some(value)` 或同名 `precomputed~` |
| Option 模式 | `guard ... is Some(value) else { ... }`；外來 payload 無 Eq 時用 `value is None`，不是 `value == None` |
| Range 優先序 | `0..<(cutoff + 1)`、`(i + 1)..<n` 明加括號，避免 `ambiguous_precedence` |
| Manifests | `moon.mod`／`moon.pkg`、`import { "pkg" @alias }`、`pkgtype(kind: "executable")` |
| 檢查／介面 | `moon check --deny-warn --target wasm-gc`；另跑 `moon info --target wasm-gc` 生成及審視 `.mbti` |

原始基線已大致採用現行語法，所以本次不是沒有理由的全倉語法重寫；主要變更是橋行為、嚴格驗收及文件契約。

## 參考的官方來源

1. [官方下載及 SHA-256 方法](https://www.moonbitlang.com/download/)
2. [正式下載通道版本 metadata](https://cli.moonbitlang.com/version.json)
3. [2026-11-05 語言／工具鏈更新](https://www.moonbitlang.com/updates/2026/11/05/index)
4. [stable：methods / traits / extend](https://docs.moonbitlang.com/en/stable/language/methods.html)
5. [stable：package DSL](https://docs.moonbitlang.com/en/stable/toolchain/moon/package.html)

官方 `/en/latest/` 頁面標示為 nightly；本輪以 `/en/stable/` 及實際正式版編譯結果作準。文件網站可隨後更新，精確版本由 pin 與本次執行證據限定。
