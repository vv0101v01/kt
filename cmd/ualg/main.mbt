///|
/// cmd/ualg — 第十聯邦（構造性泛代數 × 預層模板 × De Morgan 立方體）的定律總表。
///
/// 跑法：
///   moon run cmd/ualg --target wasm-gc
///
/// 每一行是一個**當場重算**的命題；標籤裡的數字（類數、軌道數、Betti 數……）
/// 由程式算出後才嵌進字串，不是寫死的文字。任何一條為假 ⇒ 以非零狀態結束。
fn main {
  let mut pass = 0
  let mut fail = 0
  let mut index = 0
  let packages = [
    ("ualg/core — 構造性泛代數", @core.all_laws()),
    (
      "ualg/site — 預層模板（Alexandrov 景與 j-層）",
      @site.all_laws(),
    ),
    ("ualg/demorgan — De Morgan 立方體", @demorgan.all_laws()),
    (
      "ualg/cube — 立方體上的層化與雙重否定核子",
      @cube.all_laws(),
    ),
  ]
  for pkg in packages {
    let (title, chapters) = pkg
    println("=== \{title} ===")
    let mut subtotal = 0
    for chapter in chapters {
      let (name, laws) = chapter
      println("")
      println("  ── \{name}")
      for law in laws {
        let (label, ok) = law
        index = index + 1
        subtotal = subtotal + 1
        if ok {
          pass = pass + 1
        } else {
          fail = fail + 1
        }
        let mark = if ok { "ok  " } else { "FAIL" }
        println("  \{mark} [\{pad(index, 3)}] \{label}")
      }
    }
    println("")
    println("  小計：\{chapters.length()} 條定律、\{subtotal} 個命題")
    println("")
  }
  println("通過 \{pass} / \{pass + fail} 個命題")
  if fail > 0 {
    abort("ualg laws failed")
  }
}

///|
fn pad(n : Int32, w : Int32) -> String {
  let mut out = "\{n}"
  while out.length() < w {
    out = " " + out
  }
  out
}
