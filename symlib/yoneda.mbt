///|
/// # Yoneda — 預層、米田引理、comma 範疇、Kan 擴張、歸納/上歸納 G-集
///
/// 範疇化之第二層機器（建立在 `fincat.mbt` 之上）：
///
/// - **預層**：`Presheaf`（反變函子 F : C^op → FinSet，`res[m] : F(cod m) → F(dom m)`）、
///   `is_presheaf`（恆等 + 反變函子性之窮舉驗證）
/// - **米田引理**：`yoneda_support`（h^a = Hom(−,a) 之支撐 = a 之**下集**）、
///   `yoneda_extend`（η ↦ 自然變換）、`yoneda_nats`（Nat(h^a,F) 之窮舉）、
///   `yoneda_count`、`yoneda_roundtrip` ⇒ **|Nat(h^a,F)| = |F(a)|** 之機器證明
/// - **Kan 擴張**：`comma_down` / `comma_up`（ comma 範疇）、`lan` / `lan_map`（左擴張）、
///   `ran` / `ran_map`（右擴張）、`id_functor`（沿恆等函子 ⇒ Lan F = F = Ran F）
/// - **歸納 / 上歸納**（沿 K : 1 → BG）：`induced_gset` = G×X（Lan，自由作用）、
///   `coinduced_gset` = X^G（Ran，(Ran)^G = X）；態射層面 `induced_lift` / `coinduced_lift`
///   與左正則表示（`regular_perm`）逐一相符 ⇒ Frobenius 互反之兩半
///
/// 注意：`FinAction::lift` 只適用於 base 大小 == 群作用度數之情形；
/// 歸納/上歸納 G-集之 base 為 ng·x 或 x^ng ⇒ 必須用 `induced_lift` / `coinduced_lift`。

///|
/// 預層：反變函子 C^op → FinSet（C 為薄範疇，通常為偏序）。
/// `res[m]` : F(cod m) → F(dom m)。
pub(all) struct Presheaf {
  cat : FinCat
  size : Array[Int32]
  res : Array[Array[Int32]]
}

///|
/// 建構預層（驗證範圍）。
pub fn presheaf_new(
  cat : FinCat,
  size : Array[Int32],
  res : Array[Array[Int32]],
) -> Presheaf {
  guard size.length() == cat.nobj else { abort("presheaf_new: object count") }
  guard res.length() == cat.nmor else { abort("presheaf_new: morphism count") }
  for m in 0..<cat.nmor {
    guard res[m].length() == size[cat.cod[m]] else {
      abort("presheaf_new: restriction length")
    }
    for x in res[m] {
      guard x >= 0 && x < size[cat.dom[m]] else {
        abort("presheaf_new: restriction range")
      }
    }
  }
  { cat, size, res, }
}

///|
/// 反變函子性：res[id] = id，res[f∘g] = res[g] ∘ res[f]。
pub fn is_presheaf(p : Presheaf) -> Bool {
  let c = p.cat
  for a in 0..<c.nobj {
    let m = c.id[a]
    for x in 0..<p.size[a] {
      guard p.res[m][x] == x else { return false }
    }
  }
  for f in 0..<c.nmor {
    for g in 0..<c.nmor {
      let fg = c.comp[f * c.nmor + g]
      if fg < 0 {
        continue
      }
      // res[fg] : F(cod fg) → F(dom fg)；res[g]∘res[f] 需同型
      for y in 0..<p.size[c.cod[fg]] {
        let lhs = p.res[fg][y]
        let rhs = p.res[g][p.res[f][y]]
        guard lhs == rhs else { return false }
      }
    }
  }
  true
}

///|
/// 可表預層 h^a = Hom(-, a) 之支撐：{ x : 存在態射 x → a }（a 之下集）。
fn yoneda_support(p : Presheaf, a : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for x in 0..<p.cat.nobj {
    if has_morphism(p.cat, x, a) {
      out.push(x)
    }
  }
  out
}

///|
/// 是否存在態射 a → b。
fn has_morphism(c : FinCat, a : Int32, b : Int32) -> Bool {
  for m in 0..<c.nmor {
    if c.dom[m] == a && c.cod[m] == b {
      return true
    }
  }
  false
}

///|
/// a → x 之（薄範疇中唯一的）態射索引；不存在回 -1。
fn morph_index(c : FinCat, a : Int32, b : Int32) -> Int32 {
  for m in 0..<c.nmor {
    if c.dom[m] == a && c.cod[m] == b {
      return m
    }
  }
  -1
}

///|
/// 米田雙射之正向：由 e ∈ F(a) 延展出自然族 η（η_x = F(x→a)(e)）。
/// 對 x ≤ a，η_x 必為 res[x≤a](e)：這正是自然性 F(x≤a)(η_a) = η_x。
/// 回傳長度 nobj 之陣列：支撐（a 之下集）外為 -1。
pub fn yoneda_extend(p : Presheaf, a : Int32, e : Int32) -> Array[Int32] {
  guard e >= 0 && e < p.size[a] else { abort("yoneda_extend: e out of range") }
  let eta = Array::make(p.cat.nobj, -1)
  for x in yoneda_support(p, a) {
    let m = morph_index(p.cat, x, a)
    eta[x] = p.res[m][e]
  }
  eta
}

///|
/// 自然族之驗證：∀m : x → y，F(m)(η_y) = η_x（僅對支撐內之對象）。
fn is_natural(p : Presheaf, a : Int32, eta : Array[Int32]) -> Bool {
  let c = p.cat
  for m in 0..<c.nmor {
    let x = c.dom[m]
    let y = c.cod[m]
    if eta[x] >= 0 && eta[y] >= 0 {
      guard p.res[m][eta[y]] == eta[x] else { return false }
    }
  }
  // 支撐需恰為 h^a = Hom(-,a) 之支撐（a 之下集）
  for x in 0..<c.nobj {
    let want = has_morphism(c, x, a)
    let got = eta[x] >= 0
    guard want == got else { return false }
  }
  true
}

///|
/// 列舉 Nat(h^a, F) 之全部元素（cap 為上限）。
pub fn yoneda_nats(p : Presheaf, a : Int32, cap : Int32) -> Array[Array[Int32]] {
  let c = p.cat
  let sup = yoneda_support(p, a)
  let k = sup.length()
  let mut vol = 1
  for x in sup {
    if p.size[x] == 0 {
      vol = 0
      break
    }
    if vol > cap / p.size[x] {
      vol = -1
      break
    }
    vol = vol * p.size[x]
  }
  guard vol >= 0 else { abort("yoneda_nats: presheaf too large") }
  let out : Array[Array[Int32]] = []
  let eta = Array::make(c.nobj, -1)
  fn rec(i : Int32) -> Unit {
    if i == k {
      if is_natural(p, a, eta) {
        out.push(eta.copy())
      }
      return
    }
    let x = sup[i]
    for v in 0..<p.size[x] {
      eta[x] = v
      rec(i + 1)
    }
    eta[x] = -1
  }
  rec(0)
  out
}

///|
/// **米田引理之機器證明**（有限情形）：
/// (a) 每個 e ∈ F(a) 之延展出自然族，且在 a 處取回 e（正向 + 取值）；
/// (b) 每個自然族都由 η_a 延展而來（滿射 + 單射 ⇒ 雙射）；
/// 故 |Nat(h^a, F)| = |F(a)|。回傳 (a, b, 計數相等)。
pub fn yoneda_roundtrip(
  p : Presheaf,
  a : Int32,
  cap : Int32,
) -> (Bool, Bool, Bool) {
  let mut ok_a = true
  for e in 0..<p.size[a] {
    let eta = yoneda_extend(p, a, e)
    if !is_natural(p, a, eta) || eta[a] != e {
      ok_a = false
      break
    }
  }
  let nats = yoneda_nats(p, a, cap)
  let mut ok_b = true
  for eta in nats {
    let back = yoneda_extend(p, a, eta[a])
    for x in 0..<p.cat.nobj {
      if back[x] != eta[x] {
        ok_b = false
        break
      }
    }
    if !ok_b {
      break
    }
  }
  (ok_a, ok_b, nats.length() == p.size[a])
}

///|
/// 函子（範疇之間）：`obj[a]` = K(a)，`mor[m]` = K(m)。
pub(all) struct FinFunctor {
  src : FinCat
  dst : FinCat
  obj : Array[Int32]
  mor : Array[Int32]
}

///|
/// 函子性驗證。
pub fn is_fin_functor(k : FinFunctor) -> Bool {
  guard k.obj.length() == k.src.nobj && k.mor.length() == k.src.nmor else {
    return false
  }
  for m in 0..<k.src.nmor {
    let km = k.mor[m]
    guard k.dst.dom[km] == k.obj[k.src.dom[m]] else { return false }
    guard k.dst.cod[km] == k.obj[k.src.cod[m]] else { return false }
  }
  for a in 0..<k.src.nobj {
    guard k.mor[k.src.id[a]] == k.dst.id[k.obj[a]] else { return false }
  }
  for f in 0..<k.src.nmor {
    for g in 0..<k.src.nmor {
      let fg = k.src.comp[f * k.src.nmor + g]
      if fg < 0 {
        continue
      }
      let l = k.mor[fg]
      let r = k.dst.comp[k.mor[f] * k.dst.nmor + k.mor[g]]
      guard l == r else { return false }
    }
  }
  true
}

///|
/// 恆等函子。
pub fn id_functor(c : FinCat) -> FinFunctor {
  let obj : Array[Int32] = []
  for a in 0..<c.nobj {
    obj.push(a)
  }
  let mor : Array[Int32] = []
  for m in 0..<c.nmor {
    mor.push(m)
  }
  { src: c, dst: c, obj, mor, }
}

///|
fn comma_cat_build(k : FinFunctor, d : Int32, is_down : Bool) -> FinCat {
  let objs : Array[(Int32, Int32)] = []
  for c in 0..<k.src.nobj {
    for m in 0..<k.dst.nmor {
      let ok = if is_down {
        k.dst.dom[m] == k.obj[c] && k.dst.cod[m] == d
      } else {
        k.dst.dom[m] == d && k.dst.cod[m] == k.obj[c]
      }
      if ok {
        objs.push((c, m))
      }
    }
  }
  let nobj = objs.length()
  let mors : Array[(Int32, Int32)] = []
  let mlabel : Array[Int32] = []
  for i, o in objs {
    let (c, m) = o
    for f in 0..<k.src.nmor {
      if k.src.dom[f] != c {
        continue
      }
      let c2 = k.src.cod[f]
      let kf = k.mor[f]
      for j, o2 in objs {
        let (c3, m2) = o2
        if c3 != c2 {
          continue
        }
        let comm = if is_down {
          k.dst.comp[m2 * k.dst.nmor + kf] == m
        } else {
          k.dst.comp[kf * k.dst.nmor + m] == m2
        }
        if comm {
          mors.push((i, j))
          mlabel.push(f)
        }
      }
    }
  }
  let nmor = mors.length()
  let dom = Array::make(nmor, 0)
  let cod = Array::make(nmor, 0)
  for t, e in mors {
    let (i, j) = e
    dom[t] = i
    cod[t] = j
  }
  let id = Array::make(nobj, 0)
  for a in 0..<nobj {
    let mut found = -1
    for t in 0..<nmor {
      if dom[t] == a && cod[t] == a && mlabel[t] == k.src.id[objs[a].0] {
        found = t
        break
      }
    }
    guard found >= 0 else { abort("comma_cat_build: missing identity") }
    id[a] = found
  }
  let comp = Array::make(nmor * nmor, -1)
  for f in 0..<nmor {
    for g in 0..<nmor {
      if cod[g] != dom[f] {
        continue
      }
      let prod = k.src.comp[mlabel[f] * k.src.nmor + mlabel[g]]
      guard prod >= 0 else { abort("comma_cat_build: composition missing") }
      let mut hit = -1
      for t in 0..<nmor {
        if dom[t] == dom[g] && cod[t] == cod[f] && mlabel[t] == prod {
          hit = t
          break
        }
      }
      guard hit >= 0 else { abort("comma_cat_build: composite arrow missing") }
      comp[f * nmor + g] = hit
    }
  }
  { nobj, nmor, dom, cod, id, comp, }
}

///|
/// comma 範疇 (K ↓ d)：對象 = (c, m : K(c) → d)，態射 f : c → c' 使 m' ∘ K(f) = m。
pub fn comma_down(k : FinFunctor, d : Int32) -> FinCat {
  comma_cat_build(k, d, true)
}

///|
/// comma 範疇 (d ↓ K)：對象 = (c, m : d → K(c))，態射 f : c → c' 使 K(f) ∘ m = m'。
pub fn comma_up(k : FinFunctor, d : Int32) -> FinCat {
  comma_cat_build(k, d, false)
}

///|
/// 左 Kan 擴張 Lan_K F：逐點為 (K↓d) 上 F∘π 之餘極限。
/// 回傳 (每對象基數, 每對象餘極限之 class_of 與 comma 投影)。
pub(all) struct LanResult {
  k : FinFunctor
  f : FinDiagram
  size : Array[Int32]
  /// 每個 d：(comma 對象之投影 π, class_of, nclass)
  proj : Array[Array[Int32]]
  class_of : Array[Array[Int32]]
}

///|
/// 計算 Lan_K F（含每個 d 之 comma 範疇資料，供後續求 Lan 之態射映射）。
pub fn lan(k : FinFunctor, f : FinDiagram, cap : Int32) -> LanResult {
  guard k.src.nobj == f.cat.nobj && k.src.nmor == f.cat.nmor else {
    abort("lan: functor/diagram mismatch")
  }
  let n = k.dst.nobj
  let size = Array::make(n, 0)
  let proj : Array[Array[Int32]] = []
  let class_of : Array[Array[Int32]] = []
  for d in 0..<n {
    let cd = comma_down(k, d)
    let objs : Array[Int32] = []
    // 重建 comma 對象之投影（與 comma_down 同序）
    for c in 0..<k.src.nobj {
      for m in 0..<k.dst.nmor {
        if k.dst.dom[m] == k.obj[c] && k.dst.cod[m] == d {
          objs.push(c)
        }
      }
    }
    guard objs.length() == cd.nobj else { abort("lan: comma mismatch") }
    // 圖 F∘π：態射標籤 = src 之態射 ⇒ 需與 comma_down 之態射順序一致
    let d2 = comma_pullback(cd, objs, f, k, d, true)
    let (cl, nc) = colimit(d2)
    size[d] = nc
    proj.push(objs)
    class_of.push(cl)
    guard nc <= cap else { abort("lan: too large") }
  }
  { k, f, size, proj, class_of, }
}

///|
/// 依 comma 範疇重建 F∘π 之圖（態射標籤由建構順序還原）。
fn comma_pullback(
  cd : FinCat,
  objs : Array[Int32],
  f : FinDiagram,
  k : FinFunctor,
  d : Int32,
  down : Bool,
) -> FinDiagram {
  let size = Array::make(cd.nobj, 0)
  for a in 0..<cd.nobj {
    size[a] = f.size[objs[a]]
  }
  // 態射映射：由 comma_down/up 之建構順序（物件迴圈 × src 態射迴圈 × 物件迴圈）還原
  let labels : Array[Int32] = []
  let cobjs : Array[(Int32, Int32)] = []
  for c in 0..<k.src.nobj {
    for m in 0..<k.dst.nmor {
      if down {
        if k.dst.dom[m] == k.obj[c] && k.dst.cod[m] == d {
          cobjs.push((c, m))
        }
      } else if k.dst.dom[m] == d && k.dst.cod[m] == k.obj[c] {
        cobjs.push((c, m))
      }
    }
  }
  for o in cobjs {
    let (c, m) = o
    for ff in 0..<k.src.nmor {
      if k.src.dom[ff] != c {
        continue
      }
      let c2 = k.src.cod[ff]
      let kf = k.mor[ff]
      for o2 in cobjs {
        let (c3, m2) = o2
        if c3 != c2 {
          continue
        }
        let ok = if down {
          k.dst.comp[m2 * k.dst.nmor + kf] == m
        } else {
          k.dst.comp[kf * k.dst.nmor + m] == m2
        }
        if ok {
          labels.push(ff)
        }
      }
    }
  }
  guard labels.length() == cd.nmor else {
    abort("comma_pullback: morphism count")
  }
  let img : Array[Array[Int32]] = []
  for t in 0..<cd.nmor {
    img.push(f.img[labels[t]].copy())
  }
  diagram_new(cd, size, img)
}

///|
/// Lan 之態射映射 Lan(m0) : Lan(d) → Lan(d')（由 comma 範疇間之前複合誘導）。
/// 回傳像陣列（長度 size[d]），並附良定義性檢查（若失敗回 None）。
pub fn lan_map(
  r : LanResult,
  m0 : Int32,
  d : Int32,
  dp : Int32,
) -> Array[Int32]? {
  let k = r.k
  guard k.dst.dom[m0] == d && k.dst.cod[m0] == dp else { return None }
  // Φ : (K↓d) → (K↓dp)，(c,m) ↦ (c, m0 ∘ m)
  let src_objs : Array[(Int32, Int32)] = []
  for c in 0..<k.src.nobj {
    for m in 0..<k.dst.nmor {
      if k.dst.dom[m] == k.obj[c] && k.dst.cod[m] == d {
        src_objs.push((c, m))
      }
    }
  }
  let dst_objs : Array[(Int32, Int32)] = []
  for c in 0..<k.src.nobj {
    for m in 0..<k.dst.nmor {
      if k.dst.dom[m] == k.obj[c] && k.dst.cod[m] == dp {
        dst_objs.push((c, m))
      }
    }
  }
  // 找 Φ 在對象索引上之映射
  let omap = Array::make(src_objs.length(), -1)
  for i, o in src_objs {
    let (c, m) = o
    let m2 = k.dst.comp[m0 * k.dst.nmor + m]
    guard m2 >= 0 else { return None }
    let mut hit = -1
    for j, o2 in dst_objs {
      let (c3, m3) = o2
      if c3 == c && m3 == m2 {
        hit = j
        break
      }
    }
    guard hit >= 0 else { return None }
    omap[i] = hit
  }
  // 由不交併索引映射到類號
  let src_off = Array::make(src_objs.length(), 0)
  let dst_off = Array::make(dst_objs.length(), 0)
  let mut t = 0
  for a in 0..<src_objs.length() {
    src_off[a] = t
    t = t + r.f.size[src_objs[a].0]
  }
  t = 0
  for a in 0..<dst_objs.length() {
    dst_off[a] = t
    t = t + r.f.size[dst_objs[a].0]
  }
  let dst_class = r.class_of[dp]
  // 代表元：每個來源類取首個索引
  let rep = Array::make(r.size[d], -1)
  let src_class = r.class_of[d]
  for i in 0..<src_class.length() {
    if rep[src_class[i]] < 0 {
      rep[src_class[i]] = i
    }
  }
  let out = Array::make(r.size[d], 0)
  for i in 0..<r.size[d] {
    let idx = rep[i]
    let a = obj_of_index(idx, src_off, r.f.size, src_objs)
    let x = idx - src_off[a]
    let b = omap[a]
    out[i] = dst_class[dst_off[b] + x]
  }
  // 良定義性：所有同類索引需映到同一類
  for i in 0..<src_class.length() {
    let a = obj_of_index(i, src_off, r.f.size, src_objs)
    let x = i - src_off[a]
    let b = omap[a]
    guard dst_class[dst_off[b] + x] == out[src_class[i]] else { return None }
  }
  Some(out)
}

///|
/// 由不交併索引找出所屬對象。
fn obj_of_index(
  idx : Int32,
  off : Array[Int32],
  size : Array[Int32],
  objs : Array[(Int32, Int32)],
) -> Int32 {
  for a in 0..<objs.length() {
    if idx >= off[a] && idx < off[a] + size[objs[a].0] {
      return a
    }
  }
  abort("obj_of_index: out of range")
}

///|
/// 右 Kan 擴張 Ran_K F：逐點為 (d↓K) 上 F∘π 之極限。
pub(all) struct RanResult {
  k : FinFunctor
  f : FinDiagram
  size : Array[Int32]
  /// 每個 d：極限錐之列表（每錐為陣列，索引 = comma 對象）
  cones : Array[Array[Array[Int32]]]
  proj : Array[Array[Int32]]
}

///|
/// 計算 Ran_K F。
pub fn ran(k : FinFunctor, f : FinDiagram, cap : Int32) -> RanResult {
  let n = k.dst.nobj
  let size = Array::make(n, 0)
  let cones : Array[Array[Array[Int32]]] = []
  let proj : Array[Array[Int32]] = []
  for d in 0..<n {
    let cd = comma_up(k, d)
    let objs : Array[Int32] = []
    for c in 0..<k.src.nobj {
      for m in 0..<k.dst.nmor {
        if k.dst.dom[m] == d && k.dst.cod[m] == k.obj[c] {
          objs.push(c)
        }
      }
    }
    let d2 = comma_pullback(cd, objs, f, k, d, false)
    let cs = limit(d2, cap)
    size[d] = cs.length()
    cones.push(cs)
    proj.push(objs)
  }
  { k, f, size, cones, proj, }
}

///|
/// Ran 之態射映射 Ran(m0) : Ran(d) → Ran(dp)（m0 : d → dp，前複合 Ψ）。
pub fn ran_map(
  r : RanResult,
  m0 : Int32,
  d : Int32,
  dp : Int32,
) -> Array[Int32]? {
  let k = r.k
  guard k.dst.dom[m0] == d && k.dst.cod[m0] == dp else { return None }
  // Ψ : (dp↓K) → (d↓K)，(c,m) ↦ (c, m ∘ m0)
  let dst_objs : Array[(Int32, Int32)] = []
  for c in 0..<k.src.nobj {
    for m in 0..<k.dst.nmor {
      if k.dst.dom[m] == dp && k.dst.cod[m] == k.obj[c] {
        dst_objs.push((c, m))
      }
    }
  }
  let src_objs : Array[(Int32, Int32)] = []
  for c in 0..<k.src.nobj {
    for m in 0..<k.dst.nmor {
      if k.dst.dom[m] == d && k.dst.cod[m] == k.obj[c] {
        src_objs.push((c, m))
      }
    }
  }
  // Ψ 於對象索引之映射：dst_objs[j] ↦ src_objs[?]
  let psi = Array::make(dst_objs.length(), -1)
  for j, o in dst_objs {
    let (c, m) = o
    let m2 = k.dst.comp[m * k.dst.nmor + m0]
    guard m2 >= 0 else { return None }
    let mut hit = -1
    for i, o2 in src_objs {
      let (c3, m3) = o2
      if c3 == c && m3 == m2 {
        hit = i
        break
      }
    }
    guard hit >= 0 else { return None }
    psi[j] = hit
  }
  // Ran(m0)(z)_j = z_{psi(j)}：把 d 之錐映為 dp 之錐
  let lut = Map([])
  for i, z in r.cones[d] {
    lut.set(cone_key(z), i)
  }
  let out = Array::make(r.size[d], -1)
  for i, z in r.cones[d] {
    let w = Array::make(dst_objs.length(), 0)
    for j in 0..<dst_objs.length() {
      w[j] = z[psi[j]]
    }
    match lut.get(cone_key(w)) {
      Some(t) => out[i] = t
      None => return None
    }
  }
  Some(out)
}

///|
/// 錐之整數鍵（用於查表；元素皆小，以 1000 進位打包）。
fn cone_key(z : Array[Int32]) -> Int64 {
  let mut k = 1L
  for x in z {
    guard x < 100000 else { abort("cone_key: entry too large") }
    k = k * 1000000L + x.to_int64()
  }
  k
}

///|
/// 沿 K : 1 → BG 之**歸納**（induction = Lan_K）：Lan(∗) = G × X，
/// 作用為 h·(g,x) = (h∘g, x)（左正則作用 ⊗ 平凡作用）⇒ 自由 G-集。
/// 點索引 = (元素索引, x) ↦ gi * x + xv。
pub fn induced_gset(group : PermGroup, x : Int32, cap : Int32) -> FinAction {
  let gens : Array[Array[Int32]] = []
  for s in group.generators() {
    gens.push(induced_lift(group, x, cap, s))
  }
  let ng = group.elements(cap).length()
  FinAction::new(ng * x, gens)
}

///|
/// 歸納作用中單一元素 h 之像陣列（h·(g,x) = (h∘g, x)）。
pub fn induced_lift(
  group : PermGroup,
  x : Int32,
  cap : Int32,
  h : Perm,
) -> Array[Int32] {
  let elems = group.elements(cap)
  let ng = elems.length()
  let lut = PermLut::of_elems(elems)
  let img = Array::make(ng * x, 0)
  for gi in 0..<ng {
    let t = lut.at_composed(h.img, elems[gi].img)
    for xv in 0..<x {
      img[gi * x + xv] = t * x + xv
    }
  }
  img
}

///|
/// 沿 K : 1 → BG 之**上歸納**（coinduction = Ran_K）：Ran(∗) = X^G，
/// 作用為 (h·φ)(g) = φ(g∘h)（右正則作用之前複合）。
/// 點索引 = Σ_i φ_i · x^i（φ_i = φ(g_i)）。
pub fn coinduced_gset(group : PermGroup, x : Int32, cap : Int32) -> FinAction {
  let gens : Array[Array[Int32]] = []
  for s in group.generators() {
    gens.push(coinduced_lift(group, x, cap, s))
  }
  FinAction::new(coinduced_card(group, x, cap), gens)
}

///|
/// 上歸納集之基數 |X|^|G|。
pub fn coinduced_card(group : PermGroup, x : Int32, cap : Int32) -> Int32 {
  guard x >= 1 else { abort("coinduced_card: need x >= 1") }
  let ng = group.elements(cap).length()
  let mut tot = 1
  for _ in 0..<ng {
    guard tot <= cap else { abort("coinduced_card: too large") }
    tot = tot * x
  }
  tot
}

///|
/// 上歸納作用中單一元素 h 之像陣列：(h·φ)(g_i) = φ(g_i∘h)。
pub fn coinduced_lift(
  group : PermGroup,
  x : Int32,
  cap : Int32,
  h : Perm,
) -> Array[Int32] {
  let elems = group.elements(cap)
  let ng = elems.length()
  let lut = PermLut::of_elems(elems)
  let tot = coinduced_card(group, x, cap)
  let pow = Array::make(ng, 1)
  for i in 1..<ng {
    pow[i] = pow[i - 1] * x
  }
  // j(i) = index(g_i ∘ h)
  let jmap = Array::make(ng, 0)
  for i in 0..<ng {
    jmap[i] = lut.at_composed(elems[i].img, h.img)
  }
  let img = Array::make(tot, 0)
  for idx in 0..<tot {
    let mut out = 0
    for i in 0..<ng {
      let digit = idx / pow[jmap[i]] % x
      out = out + digit * pow[i]
    }
    img[idx] = out
  }
  img
}

// ---------------------------------------------------------------------------
// 一般非薄範疇 / 群胚米田引理（General Non-Thin / Groupoid Yoneda Lemma）
// ---------------------------------------------------------------------------

///|
/// 一般有限範疇 `C` 上對象 `a` 的可表預層 `y(a) = Hom_C(-, a) : C^op → FinSet`
/// （不假設薄範疇：`BG = cat_group(G)` 上 `|Hom(0, 0)| = |G|` 為右正則 G-集）。
pub fn representable_presheaf(cat : FinCat, a : Int32) -> Presheaf {
  guard a >= 0 && a < cat.nobj else {
    abort("representable_presheaf: object out of range")
  }
  let hom_lists : Array[Array[Int32]] = Array::makei(cat.nobj, _ => [])
  let local_idx = Array::make(cat.nmor, -1)
  for m in 0..<cat.nmor {
    if cat.cod[m] == a {
      let x = cat.dom[m]
      local_idx[m] = hom_lists[x].length()
      hom_lists[x].push(m)
    }
  }
  let size = Array::makei(cat.nobj, x => hom_lists[x].length())
  let res : Array[Array[Int32]] = []
  for u in 0..<cat.nmor {
    let src = hom_lists[cat.cod[u]]
    let r = Array::make(src.length(), 0)
    for i in 0..<src.length() {
      let f = src[i]
      let fu = cat.comp[f * cat.nmor + u]
      r[i] = local_idx[fu]
    }
    res.push(r)
  }
  presheaf_new(cat, size, res)
}

///|
/// 將右 G-集（或透過逆元轉為反變作用的左 `GSetOf`）嵌入單對象群胚 `BG = cat_group(G)` 上之預層：
/// 對群元素 `g`（`BG` 之態射），限制映射 `F(g)(y) = g⁻¹ · y`，滿足 `F(f ∘ g) = F(g) ∘ F(f)`。
pub fn presheaf_from_gset(
  group : PermGroup,
  gs : GSetOf,
  cap : Int32,
) -> Presheaf {
  let cat = cat_group(group, cap)
  let elems = group.elements(cap)
  let lut = PermLut::of_elems(elems)
  let res : Array[Array[Int32]] = []
  for m in 0..<cat.nmor {
    let inv_idx = lut.at_perm(elems[m].inverse())
    res.push(gs.imgs[inv_idx].copy())
  }
  presheaf_new(cat, [gs.x], res)
}

///|
/// 檢驗一般預層自然變換 `alpha : h ⇒ p`（對每個態射 `u : x' → x` 與截面 `s ∈ h(x)`，
/// 驗證 `alpha[x'](h(u)(s)) == p(u)(alpha[x](s))`）。
pub fn presheaf_nat_is_natural(
  h : Presheaf,
  p : Presheaf,
  alpha : Array[Array[Int32]],
) -> Bool {
  let c = h.cat
  guard alpha.length() == c.nobj else { return false }
  for x in 0..<c.nobj {
    guard alpha[x].length() == h.size[x] else { return false }
    for v in alpha[x] {
      if v < 0 || v >= p.size[x] {
        return false
      }
    }
  }
  for u in 0..<c.nmor {
    let dom_u = c.dom[u]
    let cod_u = c.cod[u]
    for s in 0..<h.size[cod_u] {
      let lhs = alpha[dom_u][h.res[u][s]]
      let rhs = p.res[u][alpha[cod_u][s]]
      if lhs != rhs {
        return false
      }
    }
  }
  true
}

///|
/// 一般非薄米田延展：`e ∈ F(a)` ↦ 自然變換 `α^e : Hom_C(-, a) ⇒ F`，其中 `α^e_x(f : x → a) = F(f)(e)`。
pub fn gen_yoneda_extend(
  p : Presheaf,
  a : Int32,
  e : Int32,
) -> Array[Array[Int32]] {
  guard a >= 0 && a < p.cat.nobj else {
    abort("gen_yoneda_extend: object out of range")
  }
  guard e >= 0 && e < p.size[a] else {
    abort("gen_yoneda_extend: element out of range")
  }
  let alpha : Array[Array[Int32]] = Array::makei(p.cat.nobj, _ => [])
  for m in 0..<p.cat.nmor {
    if p.cat.cod[m] == a {
      alpha[p.cat.dom[m]].push(p.res[m][e])
    }
  }
  alpha
}

///|
/// 一般非薄米田求值：自然變換 `α : Hom_C(-, a) ⇒ F` ↦ `α_a(id_a) ∈ F(a)`。
pub fn gen_yoneda_eval(
  p : Presheaf,
  a : Int32,
  alpha : Array[Array[Int32]],
) -> Int32 {
  let id_a = p.cat.id[a]
  let mut k = 0
  for m in 0..<p.cat.nmor {
    if p.cat.dom[m] == a && p.cat.cod[m] == a {
      if m == id_a {
        return alpha[a][k]
      }
      k = k + 1
    }
  }
  abort("gen_yoneda_eval: identity morphism not found")
}

///|
/// 機器驗證一般非薄米田雙射定理 `Nat(Hom_C(-, a), F) ≅ F(a)`：
/// (1) `y(a)` 與 `F` 皆通過反變函子性驗證 `is_presheaf`；
/// (2) 對所有 `e ∈ F(a)`，`gen_yoneda_extend(F, a, e)` 滿足完整自然性且 `eval(extend(e)) == e`；
/// (3) 當總函數空間 `∏_x |F(x)|^{|Hom(x,a)|} ≤ cap` 時，窮舉全體自然變換並驗證 `|Nat(y(a), F)| == |F(a)|` 且每一個自然變換皆滿足 `extend(eval(α)) == α`。
pub fn verify_general_yoneda_bijection(
  p : Presheaf,
  a : Int32,
  cap : Int32,
) -> Bool {
  if !is_presheaf(p) {
    return false
  }
  let ya = representable_presheaf(p.cat, a)
  if !is_presheaf(ya) {
    return false
  }
  for e in 0..<p.size[a] {
    let alpha = gen_yoneda_extend(p, a, e)
    if !presheaf_nat_is_natural(ya, p, alpha) {
      return false
    }
    if gen_yoneda_eval(p, a, alpha) != e {
      return false
    }
  }
  // 若函數空間在 cap 內，同時窮舉全體函數以獨立驗證無額外自然變換
  let mut total_slots = 0
  for x in 0..<p.cat.nobj {
    total_slots = total_slots + ya.size[x]
  }
  let mut space = 1L
  let mut can_enumerate = true
  for x in 0..<p.cat.nobj {
    for _ in 0..<ya.size[x] {
      let b = p.size[x].to_int64()
      if b == 0L {
        space = 0L
      } else if space > cap.to_int64() / b {
        can_enumerate = false
      } else {
        space = space * b
      }
    }
  }
  if can_enumerate && total_slots >= 0 {
    let mut nat_count = 0
    let tot = space.to_int()
    for code in 0..<tot {
      let mut rem = code
      let alpha : Array[Array[Int32]] = []
      for x in 0..<p.cat.nobj {
        let sx = p.size[x]
        let comp_x = Array::make(ya.size[x], 0)
        for i in 0..<ya.size[x] {
          comp_x[i] = rem % sx
          rem = rem / sx
        }
        alpha.push(comp_x)
      }
      if presheaf_nat_is_natural(ya, p, alpha) {
        nat_count = nat_count + 1
        let e = gen_yoneda_eval(p, a, alpha)
        let recon = gen_yoneda_extend(p, a, e)
        for x in 0..<p.cat.nobj {
          if cmp_arr(alpha[x], recon[x]) != 0 {
            return false
          }
        }
      }
    }
    if nat_count != p.size[a] {
      return false
    }
  }
  true
}
