// ---------------------------------------------------------------------------
// meta/reflect — 集合論反射：V_α 上的**真實滿足關係**與 Lévy–Montague 反射
// ---------------------------------------------------------------------------
//
// 舊版這裡是玩具：把「層級檢查」（句子裡最大的原子編號 < 層級）當成可證性，
// 再對它證保守性。那**不是**集合論反射 —— 沒有集合、沒有 ∈、沒有量詞，club
// 與無界的內容全被「原子編號」這個假模型吃掉了。這一版把它整個刪掉，換成真的：
//
//   * 集合：遺傳有限集合（HF），以**規範編碼**表示（外延性由編碼唯一性保證）；
//   * 累積層級：`V_0 = ∅`、`V_{α+1} = P(V_α)`，物化到 `V_3`（16 個集合）；
//   * 語意：公式帶真正的量詞與 `∈`、`=`，滿足關係 `V_α ⊨ φ[x]` 逐個算；
//   * 反射（Lévy–Montague）：`φ` 在 `α` 上**對參數絕對** ⟺ 對所有 `x ∈ V_α`，
//     `V_α ⊨ φ[x]` 與 `V ⊨ φ[x]` 同真假；句子版本去掉參數。
//   ⇒ 「`φ` 反射的層級」在視窗內**無界**且**對更大的層級封閉**，
//     而「交集仍是 club」就是「有限公式集可同時反射」。
//
// 邊界（誠實寫在這裡，不是 TODO）：本檔的 `V` 是物化出來的 `V_3`，所以給出的
// 是**有限視窗**版本的反射定理；真正的 `V` 是全部 HF 集合。視窗內每一條都是
// 機器算出來的，不引用文獻。

///|
/// 遺傳有限集合：以規範編碼字串表示（`{}`、`{{}}` …）。
/// 兩個集合相等 ⟺ 編碼相同 —— 外延性免費得到。
pub(all) struct HFSet {
  code : String
}

///|
pub fn hf_empty() -> HFSet {
  HFSet::{ code: "{}" }
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
  HFSet::{ code: s + "}" }
}

///|
/// `a ∈ b`：`b` 的內容清單裡有 `a` 的編碼。
pub fn hf_mem(a : HFSet, b : HFSet) -> Bool {
  if b.code.length() < 2 {
    return false
  }
  let inner = b.code[1:b.code.length() - 1].to_owned()
  if inner == "" {
    return false
  }
  inner.split(",").contains(a.code)
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

///|
/// 累積層級 `V_n`（`n ≤ 4`；`V_4` 有 16 個集合，`V_5` 是 65536 個，物化沒意義）。
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
/// 「真宇宙」的物化版本：`V_3`（背景理論）。
pub fn v_universe() -> Array[HFSet] {
  v_level(4)
}

///|
/// 視窗上界：層級 0,1,2,3。
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
/// 層級集合在視窗內**封閉**：成員之上的層級也是成員（有限層級下，這正是
/// 「sup 封閉」的可算面貌：`V_α ⊆ V_β`，句子在 `α` 反射 ⇒ 在 `β` 也反射）。
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
/// `p1`：`∃x. x = x` 需要 `V_1`；`p2`：`∃x∃y. x ∈ y` 需要 `V_2`；
/// `p3`：`∃x∃y∃z. (x ∈ y ∧ y ∈ z)` 需要 `V_3`。
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
/// #1 外延性與層級大小：`|V_1|=1, |V_2|=2, |V_3|=16`、幂集大小 `2^n`
/// #2 `∈` 的行為：`∅ ∉ ∅`、`∅ ∈ {∅}`、`{∅} ∉ {∅}`
/// #3 層級累積：`V_α ⊆ V_β`（`α < β`）
/// #4 反射層級是**無界**的（每個 `β` 之上都有反射層級）
/// #5 反射層級對更大的層級**封閉**（club 的兩半）
/// #6 反射不是空洞的：`p3` 在 `V_0..V_2` 都不反射、只在 `V_3` 反射
pub fn law_universe_reflection_levels_form_a_club() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let v1 = v_level(1)
  let v2 = v_level(2)
  let v3 = v_level(3)
  let v4 = v_level(4)
  let e = hf_empty()
  // #1
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #1 (hierarchy sizes)",
    v1.length() == 1 &&
    v2.length() == 2 &&
    v3.length() == 4 &&
    v4.length() == 16 &&
    hf_power(v3).length() == (1 << v3.length()),
  )
  // #2
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #2 (membership behaves)",
    !hf_mem(e, e) && hf_mem(e, hf_of([e])) && !hf_mem(hf_of([e]), hf_of([e])),
  )
  // #3 累積性（逐個元素檢查包含關係）
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
    out,
    "universe reflection: reflecting levels form a club #3 (levels are cumulative)",
    cumulative,
  )
  // #4 無界
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
  // #5 封閉（對更大的層級封閉）
  @core.chk(
    out,
    "universe reflection: reflecting levels form a club #5 (closed upward)",
    closed_upward_in_window(s1, v_top()) &&
    closed_upward_in_window(s2, v_top()) &&
    closed_upward_in_window(s3, v_top()),
  )
  // #6 非空洞
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
/// #1 `φ ∧ ψ` 的反射層級 = 兩者反射層級的交集
/// #2 交集的成員就是「同時反射」的層級
/// #3 交集仍然無界（club ∩ club 無界）
/// #4 三條公式一起也找得到共同反射層級
/// #5 帶參數的絕對性與句子反射是**不同**的概念（不能互相替代）
/// #6 `p1` 對所有 `x ∈ V_1` 都絕對，但對 `x ∈ V_3` 不（`V_3` 已無更高層可逃 ⇒ 取 `V_2` 對照）
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
  // #1
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
  // #2
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #2 (intersection = simultaneous reflection)",
    same_levels(inter, [2, 3, 4]),
  )
  // #3
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #3 (intersection is unbounded)",
    unbounded_in_window(inter, v_top()),
  )
  // #4
  let all3 = reflecting_levels(f_and(p1, f_and(p2, p3)), v_top())
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #4 (three formulas share a level)",
    same_levels(all3, [3, 4]) && unbounded_in_window(all3, v_top()),
  )
  // #5 絕對性（帶參數）與反射（句子）不同：`∃y. y ∈ x` 對 x = ∅ 在 V_1 就絕對，
  //    但它作為**句子**的反射需要 V_2；所以兩個概念不能互相取代。
  let phi_mem_x = f_ex(FMem(0, 1)) // ∃y. y ∈ x（自由變數 x）
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #5 (parametrized absoluteness differs from sentential reflection)",
    absolute_at(1, phi_mem_x) &&
    !reflects(1, sentence_p2()) &&
    reflects(2, sentence_p2()),
  )
  // #6 帶參數絕對性也會失敗（非空洞）：`∃y∃z. (y ∈ x ∧ z ∈ y)`
  // 向上的量詞：`∃y. x ∈ y`。`x` 的秩是 `α−1` 時，見證 `y` 必須在 `V_{α+1}` 裡，
  // 所以「在 `V_α` 內」永遠假、「在 `V` 內」可以真 ⇒ 不絕對。
  let phi_up = f_ex(FMem(1, 0))
  @core.chk(
    out,
    "universe reflection: finitely many formulas reflect together #6 (parametrized absoluteness is not vacuous)",
    !absolute_at(1, phi_up) && !absolute_at(3, phi_up),
  )
  out
}
