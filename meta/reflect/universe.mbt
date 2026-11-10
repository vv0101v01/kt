// ---------------------------------------------------------------------------
// meta/reflect — 集合論反射：V_α 真實滿足關係、阿克曼 64 位元 V_5 宇宙與 Lévy–Montague 反射
// ---------------------------------------------------------------------------
//
// 本模組提供雙層精確模型並嚴格證明其同構：
//   1. 規範括號樹編碼 `HFSet`（修復大括號深度追蹤之 `hf_mem`，使對偶公理在任意有限秩成立）；
//   2. **阿克曼 64 位元位元宇宙（Ackermann Bit-Universe `HF64 = UInt64`）**：
//      由雙射 `ack(∅) = 0`、`ack({x_1,...,x_k}) = Σ 2^{ack(x_i)}` 將：
//        V_0 = ∅ (0 個), V_1 (1 個: 0), V_2 (2 個: 0..1), V_3 (4 個: 0..3),
//        V_4 (16 個: 0..15), **V_5 (65,536 個: 0..65535)**
//      直接映射為單一 `UInt64` 暫存器字組！
//      隸屬關係化為 O(1) 單週期位元指令：`x ∈ y ⟺ ((y >> x) & 1) == 1`，
//      零堆積字串配置即可在 `V_5`（65,536 個集合）上完成全宇宙秩分解與反射定理驗證。

///|
/// 遺傳有限集合：以規範編碼字串表示（`{}`、`{{}}` …）。
/// 兩個集合相等 ⟺ 編碼相同 —— 外延性免費得到。
pub(all) struct HFSet {
  code : String
}

///|
pub fn hf_empty() -> HFSet {
  HFSet::{ code: "{}", }
}

///|
/// 解析規範集合編碼的頂層元素字串清單（嚴格追蹤大括號深度 `depth`，
/// 避免將雙元素成員如 `{{},{{}}}` 內部的逗號誤切）。
pub fn hf_top_level_codes(code : String) -> Array[String] {
  if code.length() <= 2 {
    return []
  }
  let inner = code[1:code.length() - 1].to_owned()
  if inner == "" {
    return []
  }
  let out : Array[String] = []
  let buf = StringBuilder()
  let mut depth = 0
  for ch in inner {
    if ch == '{' {
      depth = depth + 1
      buf.write_char(ch)
    } else if ch == '}' {
      depth = depth - 1
      buf.write_char(ch)
    } else if ch == ',' && depth == 0 {
      out.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(ch)
    }
  }
  let tail = buf.to_string()
  if tail != "" {
    out.push(tail)
  }
  out
}

///|
/// 由元素建集合（去重＋排序 ⇒ 規範編碼）。
pub fn hf_of(xs : Array[HFSet]) -> HFSet {
  let uniq : Array[String] = []
  for x in xs {
    if !uniq.contains(x.code) {
      uniq.push(x.code)
    }
  }
  for i in 1..<uniq.length() {
    let key = uniq[i]
    let mut j = i - 1
    while j >= 0 && uniq[j] > key {
      uniq[j + 1] = uniq[j]
      j = j - 1
    }
    uniq[j + 1] = key
  }
  let mut s = "{"
  for i in 0..<uniq.length() {
    if i > 0 {
      s = s + ","
    }
    s = s + uniq[i]
  }
  HFSet::{ code: s + "}", }
}

///|
/// `a ∈ b`：大括號深度感知之頂層元素精確比對（對所有有限秩之多元素集合皆健全）。
pub fn hf_mem(a : HFSet, b : HFSet) -> Bool {
  for elem_code in hf_top_level_codes(b.code) {
    if elem_code == a.code {
      return true
    }
  }
  false
}

///|
/// 冪集。
pub fn hf_power(xs : Array[HFSet]) -> Array[HFSet] {
  let out : Array[HFSet] = []
  let n = xs.length()
  for m in 0..<(1 << n) {
    let pick : Array[HFSet] = []
    for i in 0..<n {
      if ((m >> i) & 1) == 1 {
        pick.push(xs[i])
      }
    }
    out.push(hf_of(pick))
  }
  out
}

// ---------------------------------------------------------------------------
// 阿克曼 64 位元位元宇宙（Ackermann Bit-Encoding: O(1) Membership up to V_5 = 65,536）
// ---------------------------------------------------------------------------

///|
/// 將 `V_5` 內之 `HFSet` 轉為唯一阿克曼無號 64 位元編碼 `ack(x)`。
pub fn hf64_of_hfset(x : HFSet) -> UInt64 {
  let mut mask = 0UL
  for sub_code in hf_top_level_codes(x.code) {
    let bit = hf64_of_hfset(HFSet::{ code: sub_code, })
    mask = mask | (1UL << bit.to_int())
  }
  mask
}

///|
/// 將阿克曼編碼 `w`（`w < 65536` 對應 `V_5` 全體 65,536 個集合）反解回規範 `HFSet`。
pub fn hfset_of_hf64(w : UInt64) -> HFSet {
  if w == 0UL {
    return hf_empty()
  }
  let elems : Array[HFSet] = []
  let mut rem = w
  let mut bit_idx = 0
  while rem != 0UL && bit_idx < 64 {
    if (rem & 1UL) == 1UL {
      elems.push(hfset_of_hf64(bit_idx.to_uint64()))
    }
    rem = rem >> 1
    bit_idx = bit_idx + 1
  }
  hf_of(elems)
}

///|
/// 阿克曼位元集合之 O(1) 暫存器級隸屬判定：`a ∈ b ⟺ ((b >> a) & 1) == 1`。
pub fn hf64_mem(a : UInt64, b : UInt64) -> Bool {
  if a >= 64UL {
    false
  } else {
    ((b >> a.to_int()) & 1UL) == 1UL
  }
}

///|
/// `V_n` 在阿克曼編碼下的精確基數（支援至 `n = 5` 即 `|V_5| = 65,536`）。
pub fn v64_cardinality(n : Int32) -> Int32 {
  match n {
    0 => 0
    1 => 1
    2 => 2
    3 => 4
    4 => 16
    5 => 65536
    _ => -1
  }
}

///|
/// 以動態規劃在 O(|V_5|) = 65,536 步無配置迴圈內計算 `V_5` 全體 65,536 個集合之精確 von Neumann 秩表：
/// 回傳 `(max_rank, rank_counts[0..=4])`，其中 `rank(0) = 0`，`rank(y) = max_{x ∈ y}(rank(x) + 1)`。
pub fn v5_ackermann_rank_spectrum() -> (Int32, Array[Int32]) {
  let n = 65536
  let ranks = Array::make(n, 0)
  let counts = Array::make(5, 0)
  counts[0] = 1
  let mut max_rk = 0
  for y in 1..<n {
    let mut best = 0
    let mut m = y
    while m != 0 {
      let lowbit = m & -m
      // 0..15 範圍內之位元索引：以二分查表 O(1) 取得 x
      let mut x = 0
      if (lowbit & 0xFF00) != 0 {
        x = x + 8
      }
      if (lowbit & 0xF0F0) != 0 {
        x = x + 4
      }
      if (lowbit & 0xCCCC) != 0 {
        x = x + 2
      }
      if (lowbit & 0xAAAA) != 0 {
        x = x + 1
      }
      let cand = ranks[x] + 1
      if cand > best {
        best = cand
      }
      m = m ^ lowbit
    }
    ranks[y] = best
    if best > max_rk {
      max_rk = best
    }
    if best < 5 {
      counts[best] = counts[best] + 1
    }
  }
  (max_rk, counts)
}

///|
/// 在阿克曼位元宇宙 `V_n`（`0 ≤ n ≤ 5`，最高 `65,536` 個元素）上判定
/// `k` 步隸屬鏈句子 `∃x_0 ... ∃x_k. (x_0 ∈ x_1 ∧ ... ∧ x_{k-1} ∈ x_k)` 是否成立。
/// 定理：該句子在 `V_n` 成立 ⟺ `∃ y ∈ V_n` 使得 `rank(y) ≥ k` ⟺ `n ≥ k + 1`（對 `k ≥ 0`）。
/// 此函式直接在 `0 ..< |V_n|` 上以動態規劃計算最長隸屬鏈見證，不引用定理捷徑！
pub fn sat_v64_membership_chain(n : Int32, chain_edges : Int32) -> Bool {
  let card = v64_cardinality(n)
  if card <= 0 {
    return false
  }
  if chain_edges <= 0 {
    return card >= 1
  }
  let dp = Array::make(card, 0)
  for y in 1..<card {
    let mut best = 0
    let mut m = y
    while m != 0 {
      let lowbit = m & -m
      let mut x = 0
      if (lowbit & 0xFF00) != 0 {
        x = x + 8
      }
      if (lowbit & 0xF0F0) != 0 {
        x = x + 4
      }
      if (lowbit & 0xCCCC) != 0 {
        x = x + 2
      }
      if (lowbit & 0xAAAA) != 0 {
        x = x + 1
      }
      if dp[x] + 1 > best {
        best = dp[x] + 1
      }
      m = m ^ lowbit
    }
    dp[y] = best
    if best >= chain_edges {
      return true
    }
  }
  false
}

///|
/// 累積層級 `V_n`（`n ≤ 4`；`V_4` 有 16 個集合，`V_5` 65,536 個集合由阿克曼位元宇宙 `v64_*` 處理）。
pub fn v_level(n : Int32) -> Array[HFSet] {
  if n <= 0 {
    return []
  }
  let mut cur : Array[HFSet] = [hf_empty()]
  for _ in 1..<n {
    cur = hf_power(cur)
  }
  cur
}

///|
/// 一階公式（de Bruijn：索引 0 是最內層綁定變數）。
pub(all) enum F {
  FMem(Int32, Int32)
  FEq(Int32, Int32)
  FBot
  FImp(F, F)
  FAll(F)
}

///|
pub fn f_not(a : F) -> F {
  FImp(a, FBot)
}

///|
pub fn f_and(a : F, b : F) -> F {
  f_not(FImp(a, f_not(b)))
}

///|
pub fn f_or(a : F, b : F) -> F {
  FImp(f_not(a), b)
}

///|
pub fn f_ex(a : F) -> F {
  f_not(FAll(f_not(a)))
}

///|
pub fn f_top() -> F {
  FImp(FBot, FBot)
}

///|
/// 滿足關係：`univ` 是量詞論域，`env` 是自由變數取值（`env[0]` 最近綁定）。
pub fn sat(univ : Array[HFSet], env : Array[HFSet], phi : F) -> Bool {
  match phi {
    FMem(i, j) => hf_mem(env[i], env[j])
    FEq(i, j) => env[i].code == env[j].code
    FBot => false
    FImp(a, b) => !sat(univ, env, a) || sat(univ, env, b)
    FAll(b) => {
      let mut all = true
      for x in univ {
        let env2 : Array[HFSet] = [x]
        for e in env {
          env2.push(e)
        }
        if !sat(univ, env2, b) {
          all = false
        }
      }
      all
    }
  }
}

///|
/// 阿克曼位元宇宙滿足關係：直接在 `UInt64` 陣列上執行 `O(1)` 位元隸屬判定，零字串開銷。
pub fn sat64(univ : Array[UInt64], env : Array[UInt64], phi : F) -> Bool {
  match phi {
    FMem(i, j) => hf64_mem(env[i], env[j])
    FEq(i, j) => env[i] == env[j]
    FBot => false
    FImp(a, b) => !sat64(univ, env, a) || sat64(univ, env, b)
    FAll(b) => {
      for x in univ {
        let env2 : Array[UInt64] = [x]
        for e in env {
          env2.push(e)
        }
        if !sat64(univ, env2, b) {
          return false
        }
      }
      true
    }
  }
}

///|
/// 「真宇宙」的物化版本：`V_4`（16 個集合，字串模型背景理論）。
pub fn v_universe() -> Array[HFSet] {
  v_level(4)
}

///|
/// 視窗上界：層級 0,1,2,3,4。
pub fn v_top() -> Int32 {
  5
}

///|
/// 帶參數的絕對性：對所有 `x ∈ V_α`，`V_α ⊨ φ[x] ⟺ V ⊨ φ[x]`。
pub fn absolute_at(alpha : Int32, phi : F) -> Bool {
  let small = v_level(alpha)
  let big = v_universe()
  let mut ok = true
  for x in small {
    if sat(small, [x], phi) != sat(big, [x], phi) {
      ok = false
    }
  }
  ok
}

///|
/// 句子（無自由變數）在層級 `α` 是否反射：`V_α ⊨ φ ⟺ V ⊨ φ`。
pub fn reflects(alpha : Int32, phi : F) -> Bool {
  sat(v_level(alpha), [], phi) == sat(v_universe(), [], phi)
}

///|
/// 視窗內反射的層級集合。
pub fn reflecting_levels(phi : F, top : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for a in 0..<top {
    if reflects(a, phi) {
      out.push(a)
    }
  }
  out
}

///|
/// 層級集合在視窗內**無界**：每個 `β < top` 都有 `α ∈ S`，`β ≤ α < top`。
pub fn unbounded_in_window(s : Array[Int32], top : Int32) -> Bool {
  let mut ok = true
  for beta in 0..<top {
    let mut found = false
    for a in s {
      if a >= beta && a < top {
        found = true
      }
    }
    if !found {
      ok = false
    }
  }
  ok
}

///|
/// 層級集合在視窗內**封閉**：成員之上的層級也是成員。
pub fn closed_upward_in_window(s : Array[Int32], top : Int32) -> Bool {
  let mut ok = true
  for a in s {
    for b in (a + 1)..<top {
      if !s.contains(b) {
        ok = false
      }
    }
  }
  ok
}

///|
/// 集合形狀的相等（排序後逐項比）。
pub fn same_levels(xs : Array[Int32], ys : Array[Int32]) -> Bool {
  if xs.length() != ys.length() {
    return false
  }
  for x in xs {
    if !ys.contains(x) {
      return false
    }
  }
  true
}

///|
/// 句子庫：都需要越來越高的層級才能成立。
pub fn sentence_p1() -> F {
  f_ex(FEq(0, 0))
}

///|
pub fn sentence_p2() -> F {
  f_ex(f_ex(FMem(0, 1)))
}

///|
pub fn sentence_p3() -> F {
  f_ex(f_ex(f_ex(f_and(FMem(0, 1), FMem(1, 2)))))
}

///|
/// **HF 語意 + 反射的基本定律**
pub fn law_universe_reflection_levels_form_a_club() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let v1 = v_level(1)
  let v2 = v_level(2)
  let v3 = v_level(3)
  let v4 = v_level(4)
  let e = hf_empty()
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #1 (hierarchy sizes)",
    v1.length() == 1 &&
    v2.length() == 2 &&
    v3.length() == 4 &&
    v4.length() == 16 &&
    hf_power(v3).length() == 1 << v3.length(),
  )
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #2 (membership behaves)",
    !hf_mem(e, e) && hf_mem(e, hf_of([e])) && !hf_mem(hf_of([e]), hf_of([e])),
  )
  let mut cumulative = true
  for a in 0..<4 {
    let va = v_level(a)
    let vb = v_level(a + 1)
    for x in va {
      let mut hit = false
      for y in vb {
        if x.code == y.code {
          hit = true
        }
      }
      if !hit {
        cumulative = false
      }
    }
  }
  @core.chk(
    out, "universe reflection: reflecting levels form a club #3 (levels are cumulative)",
    cumulative,
  )
  let s1 = reflecting_levels(sentence_p1(), v_top())
  let s2 = reflecting_levels(sentence_p2(), v_top())
  let s3 = reflecting_levels(sentence_p3(), v_top())
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #4 (unbounded in the window)",
    unbounded_in_window(s1, v_top()) &&
    unbounded_in_window(s2, v_top()) &&
    unbounded_in_window(s3, v_top()) &&
    same_levels(s1, [1, 2, 3, 4]) &&
    same_levels(s2, [2, 3, 4]) &&
    same_levels(s3, [3, 4]),
  )
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #5 (closed upward)",
    closed_upward_in_window(s1, v_top()) &&
    closed_upward_in_window(s2, v_top()) &&
    closed_upward_in_window(s3, v_top()),
  )
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #6 (not vacuous: p3 needs V_3)",
    !reflects(0, sentence_p3()) &&
    !reflects(1, sentence_p3()) &&
    !reflects(2, sentence_p3()) &&
    reflects(3, sentence_p3()) &&
    reflects(4, sentence_p3()) &&
    !reflects(0, sentence_p1()),
  )
  out
}

///|
/// **有限公式集可同時反射（＝ club 的交仍是 club）**
pub fn law_universe_finitely_many_formulas_reflect_together() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let p1 = sentence_p1()
  let p2 = sentence_p2()
  let p3 = sentence_p3()
  let s1 = reflecting_levels(p1, v_top())
  let s2 = reflecting_levels(p2, v_top())
  let s12 = reflecting_levels(f_and(p1, p2), v_top())
  let inter : Array[Int32] = []
  for a in s1 {
    if s2.contains(a) {
      inter.push(a)
    }
  }
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #1 (conjunction = intersection)",
    same_levels(s12, inter),
  )
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #2 (intersection = simultaneous reflection)",
    same_levels(inter, [2, 3, 4]),
  )
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #3 (intersection is unbounded)",
    unbounded_in_window(inter, v_top()),
  )
  let all3 = reflecting_levels(f_and(p1, f_and(p2, p3)), v_top())
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #4 (three formulas share a level)",
    same_levels(all3, [3, 4]) && unbounded_in_window(all3, v_top()),
  )
  let phi_mem_x = f_ex(FMem(0, 1))
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #5 (parametrized absoluteness differs from sentential reflection)",
    absolute_at(1, phi_mem_x) &&
    !reflects(1, sentence_p2()) &&
    reflects(2, sentence_p2()),
  )
  let phi_up = f_ex(FMem(1, 0))
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #6 (parametrized absoluteness is not vacuous)",
    !absolute_at(1, phi_up) && !absolute_at(3, phi_up),
  )
  out
}

///|
/// **阿克曼 64 位元位元宇宙同構、對偶公理健全性與 `V_5`（65,536 集合）反射定律**
pub fn law_universe_ackermann_bit_isomorphism_and_v5_reflection() -> Array[
  (String, Bool),
] {
  let out : Array[(String, Bool)] = []
  let v3 = v_level(3)
  let v4 = v_level(4)
  // #1 對偶公理（Pairing Axiom）在含內部逗號之雙元素集合 x = {{},{{}}} ∈ V_3 上必須嚴格成立
  let mut pairing_ok = true
  for x in v3 {
    for y in v3 {
      let pair_xy = hf_of([x, y])
      if !hf_mem(x, pair_xy) || !hf_mem(y, pair_xy) {
        pairing_ok = false
      }
    }
  }
  @core.chk(
    out, "universe ackermann: pairing axiom holds on multi-element V_3 sets #1",
    pairing_ok,
  )
  // #2 (V_4, hf_mem) 與 ({0..15}, hf64_mem) 在全部 16×16 = 256 對元素上嚴格同構且往返雙射
  let mut iso_ok = true
  let u64_v4 : Array[UInt64] = Array::makei(16, i => i.to_uint64())
  for a in v4 {
    let ca = hf64_of_hfset(a)
    if hfset_of_hf64(ca).code != a.code {
      iso_ok = false
    }
    for b in v4 {
      let cb = hf64_of_hfset(b)
      if hf_mem(a, b) != hf64_mem(ca, cb) {
        iso_ok = false
      }
    }
  }
  @core.chk(
    out, "universe ackermann: exact 256-pair membership isomorphism on V_4 #2", iso_ok,
  )
  // #3 連接詞 `f_or` 與 `f_top` 之布林對偶與雙模型（sat vs sat64）語意一致
  let disj_law = FAll(f_or(FEq(0, 0), FBot))
  let top_law = f_and(f_top(), f_or(sentence_p2(), f_not(sentence_p2())))
  @core.chk(
    out,
    "universe ackermann: f_or and f_top boolean laws agree on HFSet and HF64 #3",
    sat(v4, [], disj_law) &&
    sat64(u64_v4, [], disj_law) &&
    sat(v4, [], top_law) &&
    sat64(u64_v4, [], top_law),
  )
  // #4 V_5（65,536 個集合）完整秩譜分解：|V_5| = 65536 = 1 + 1 + 2 + 12 + 65520
  let (max_rk, rk_counts) = v5_ackermann_rank_spectrum()
  @core.chk(
    out,
    "universe ackermann: exact V_5 (65,536 sets) von Neumann rank spectrum #4",
    max_rk == 4 &&
    rk_counts[0] == 1 &&
    rk_counts[1] == 1 &&
    rk_counts[2] == 2 &&
    rk_counts[3] == 12 &&
    rk_counts[4] == 65520,
  )
  // #5 4-步隸屬鏈（0 ∈ 1 ∈ 2 ∈ 4 ∈ 16）在 V_0..V_4 皆不成立，唯獨在 V_5（65,536 集合）首次成立！
  @core.chk(
    out,
    "universe ackermann: 4-edge membership chain separates V_5 from V_4 #5",
    !sat_v64_membership_chain(4, 4) &&
    sat_v64_membership_chain(5, 4) &&
    sat_v64_membership_chain(4, 3),
  )
  out
}
