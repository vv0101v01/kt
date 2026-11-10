///|
/// # Marks — 子群共軛類、標記向量、Burnside 環之 table of marks
///
/// 把 G-集之同構類轉譯成**整數向量**，於是同構判定變成向量比較（O(類數)），
/// 而不是逐點比對（O(|X|!)）。
///
/// - `Sub { order, members, group }`：子群（members 為排序後之元素表）
/// - `subgroup_classes(G, cap)`：共軛類代表（n ≤ 5 窮舉 ≤2 生成元之子群；
///   ng > 24 時只列循環子群 ⇒ 類數為下界）
/// - `gset_mark(X, H)` = |X^H|（H 之全局不動點數）、`mark_vector(X, subs)`
/// - `table_of_marks(G, subs)`：M[i][j] = |(G/H_i)^{H_j}|（**下三角、對角正** ⇒
///   標記向量為 G-集之完全不變量）；`table_of_marks_formula` 以
///   M_ij = |{gH_i : H_j ⊆ gH_ig^{-1}}| 獨立重算 ⇒ 互為證人
/// - `coset_reps` / `coset_gset`：G/H 之 G-集
/// - `marks_cert(G, cap)`：兩條公式一致 + 下三角 + 對角正 + Burnside 一致性
/// - `gset_isomorphic` / `gset_canon_key`：以標記向量判同構
/// - `frobenius_reciprocity(H ≤ G, X)`：⟨Ind_H^G Y, X⟩_G = ⟨Y, Res_H X⟩_H（以不動點計數驗證）

///|
/// 子群（以元素索引之位向量表示；`members` 為 G 元素列表中屬於 H 者）。
pub(all) struct Sub {
  order : Int64
  members : BitVec
  group : PermGroup
}

///|
/// 子群 H 之不動點數 |X^H| = 標記 m_H(X)。
pub fn gset_mark(gs : GSetOf, h : Sub) -> Int32 {
  let idxs = h.members.to_array()
  let mut c = 0
  for y in 0..<gs.x {
    let mut ok = true
    for i in idxs {
      if gs.imgs[i][y] != y {
        ok = false
        break
      }
    }
    if ok {
      c = c + 1
    }
  }
  c
}

///|
/// 標記向量（依 `subgroup_classes` 之順序）。
pub fn mark_vector(gs : GSetOf, subs : Array[Sub]) -> Array[Int32] {
  let v : Array[Int32] = []
  for h in subs {
    v.push(gset_mark(gs, h))
  }
  v
}

///|
/// 子群集合之雜湊桶（BitVec::hash → 索引表）：去重與共軛併類之 O(1) 查找，
/// 免建字串鍵（每次 O(|H|) 配置 + O(|H|²) 複製）。碰撞以 `BitVec::equal` 排除。
fn sub_lookup(
  buckets : Map[Int32, Array[Int32]],
  mems : Array[BitVec],
  bv : BitVec,
) -> Int32 {
  match buckets.get(bv.hash()) {
    Some(list) => {
      let mut hit = -1
      for j in list {
        if mems[j].equal(bv) {
          hit = j
          break
        }
      }
      hit
    }
    None => -1
  }
}

///|
/// 子群共軛類（Holt 陪集剪枝逐層擴張 + 共軛軌道併類，對任意生成元秩完整）。
///
/// **演算法與完備性定理**：
/// 1. 任意非平凡子群 `L ≤ G` 必含極大真子群 `M < L`，對任意 `y ∈ L \ M` 有 `⟨M, y⟩ = L`；
///    由歸納假設 `M = g H g⁻¹` 共軛於前沿代表 `H`，故 `⟨H, g⁻¹ y g⟩ = g⁻¹ L g` 必於擴張 `H` 時命中 `L` 之共軛類（包括如 `B_3(48)` 中需 3 生成元的初等阿貝爾子群 `(C_2)^3`）。
/// 2. 陪集剪枝：對任意 `h ∈ H`，`⟨H, h·x⟩ = ⟨H, x⟩ = ⟨H, x·h⟩`，每次嘗試 `x` 即一次標記整個左/右陪集 `H·x ∪ x·H`，候選數壓縮 `|H|` 倍。
/// 3. 採用無度數上限 `PermLut`（`n ≤ 15` 為 4-bit Nibble 無乘法 SWAR，`n > 15` 為 SplitMix64 + 原像核對），解除舊版 `n ≤ 12` 與 `|G| ≤ 24` 限制。
pub fn subgroup_classes(group : PermGroup, cap : Int32) -> Array[Sub] {
  let t = sub_table(group, cap)
  sub_holt_lattice(t, group, cap)
}

///|
/// 元素表：`elems[i]` 為第 i 個群元素、`imgs[i]` 為其像表、`lut` 提供任意度數 O(1) 元素→索引。
priv struct SubTable {
  n : Int32
  ng : Int32
  elems : Array[Perm]
  imgs : Array[Array[Int32]]
  lut : PermLut
  id_idx : Int32
}

///|
/// 建立元素表（`|G| > cap` 時 `PermGroup::elements` 會 abort）。
fn sub_table(group : PermGroup, cap : Int32) -> SubTable {
  let elems = group.elements(cap)
  let n = group.size()
  let ng = elems.length()
  let lut = PermLut::of_elems(elems)
  let imgs : Array[Array[Int32]] = []
  for e in elems {
    imgs.push(e.img)
  }
  let id_idx = lut.at_perm(Perm::identity(n))
  { n, ng, elems, imgs, lut, id_idx, }
}

///|
/// 已知閉子群 `H`（成員 `h_mem`、元素索引 `h_idxs`、生成元 `h_gens`）添加 `x` 後之閉包 `⟨H, x⟩`。
/// 利用 `H` 已對 `h_gens` 封閉之性質，初始層僅需右乘 `x`，新元素再對 `h_gens ∪ {x}` 閉包。
fn sub_extend_closure(
  t : SubTable,
  h_mem : BitVec,
  h_idxs : Array[Int32],
  h_gens : Array[Int32],
  x : Int32,
  cap : Int32,
) -> BitVec? {
  let mem = h_mem.copy()
  let queue : Array[Int32] = []
  let ix = t.imgs[x]
  for h in h_idxs {
    let y = t.lut.at_composed(t.imgs[h], ix)
    if !mem.get(y) {
      mem.set(y)
      queue.push(y)
      if h_idxs.length() + queue.length() > cap {
        return None
      }
    }
  }
  let mut head = 0
  while head < queue.length() {
    let u_img = t.imgs[queue[head]]
    head = head + 1
    let yx = t.lut.at_composed(u_img, ix)
    if !mem.get(yx) {
      mem.set(yx)
      queue.push(yx)
      if h_idxs.length() + queue.length() > cap {
        return None
      }
    }
    for g in h_gens {
      let yg = t.lut.at_composed(u_img, t.imgs[g])
      if !mem.get(yg) {
        mem.set(yg)
        queue.push(yg)
        if h_idxs.length() + queue.length() > cap {
          return None
        }
      }
    }
  }
  Some(mem)
}

///|
/// Holt 陪集剪枝逐層擴張求全體子群共軛類代表（支援 `B_3(48)`、`A_5(60)`、`S_5(120)` 等任意生成元秩有限群）。
fn sub_holt_lattice(t : SubTable, group : PermGroup, cap : Int32) -> Array[Sub] {
  let all_mems : Array[BitVec] = []
  let all_buckets : Map[Int32, Array[Int32]] = Map([])
  let rep_mems : Array[BitVec] = []
  let rep_arrs : Array[Array[Int32]] = []
  let rep_gens : Array[Array[Int32]] = []

  let gimgs : Array[Array[Int32]] = []
  let ginvs : Array[Array[Int32]] = []
  for p in group.generators() {
    gimgs.push(p.img)
    let inv = Array::make(t.n, 0)
    for v in 0..<t.n {
      inv[p.img[v]] = v
    }
    ginvs.push(inv)
  }
  let tmp = Array::make(t.n, 0)

  fn record_all(bv : BitVec) -> Unit {
    let h = bv.hash()
    let idx = all_mems.length()
    match all_buckets.get(h) {
      Some(list) => list.push(idx)
      None => all_buckets.set(h, [idx])
    }
    all_mems.push(bv)
  }

  fn register_orbit(k_mem : BitVec, k_gens : Array[Int32]) -> Unit {
    if sub_lookup(all_buckets, all_mems, k_mem) >= 0 {
      return
    }
    record_all(k_mem)
    let orbit_mems : Array[BitVec] = [k_mem]
    let orbit_gens : Array[Array[Int32]] = [k_gens]
    let mut best_i = 0
    let mut best_arr = k_mem.to_array()
    let mut head = 0
    while head < orbit_mems.length() {
      let cur_mem = orbit_mems[head]
      let cur_arr = cur_mem.to_array()
      let cur_gens = orbit_gens[head]
      head = head + 1
      for gi in 0..<gimgs.length() {
        let gimg = gimgs[gi]
        let ginv = ginvs[gi]
        let conj = BitVec::make(t.ng)
        for idx in cur_arr {
          let eimg = t.imgs[idx]
          for v in 0..<t.n {
            tmp[v] = eimg[ginv[v]]
          }
          conj.set(t.lut.at_composed(gimg, tmp))
        }
        if sub_lookup(all_buckets, all_mems, conj) < 0 {
          record_all(conj)
          let cgens : Array[Int32] = []
          for g_idx in cur_gens {
            let eimg = t.imgs[g_idx]
            for v in 0..<t.n {
              tmp[v] = eimg[ginv[v]]
            }
            cgens.push(t.lut.at_composed(gimg, tmp))
          }
          let carr = conj.to_array()
          if cmp_arr(carr, best_arr) < 0 {
            best_i = orbit_mems.length()
            best_arr = carr
          }
          orbit_mems.push(conj)
          orbit_gens.push(cgens)
        }
      }
    }
    rep_mems.push(orbit_mems[best_i])
    rep_arrs.push(best_arr)
    rep_gens.push(orbit_gens[best_i])
  }

  let triv = BitVec::make(t.ng)
  triv.set(t.id_idx)
  register_orbit(triv, [])

  let mut f_head = 0
  while f_head < rep_mems.length() {
    let h_mem = rep_mems[f_head]
    let h_idxs = rep_arrs[f_head]
    let h_gens = rep_gens[f_head]
    f_head = f_head + 1
    if h_idxs.length() >= t.ng {
      continue
    }
    let skip = h_mem.copy()
    for x in 0..<t.ng {
      if skip.get(x) {
        continue
      }
      let ix = t.imgs[x]
      for h in h_idxs {
        let ih = t.imgs[h]
        skip.set(t.lut.at_composed(ih, ix))
        skip.set(t.lut.at_composed(ix, ih))
      }
      match sub_extend_closure(t, h_mem, h_idxs, h_gens, x, cap) {
        Some(k_mem) => {
          let next_gens = h_gens.copy()
          next_gens.push(x)
          register_orbit(k_mem, next_gens)
        }
        None => ()
      }
    }
  }

  let ns = rep_mems.length()
  let cand : Array[(Int64, Array[Int32], Int32)] = []
  for i in 0..<ns {
    cand.push((rep_arrs[i].length().to_int64(), rep_arrs[i], i))
  }
  cand.sort_by(fn(
    x : (Int64, Array[Int32], Int32),
    y : (Int64, Array[Int32], Int32),
  ) -> Int32 {
    if x.0 != y.0 {
      if x.0 < y.0 {
        -1
      } else {
        1
      }
    } else {
      cmp_arr(x.1, y.1)
    }
  })
  let out : Array[Sub] = []
  for trip in cand {
    let r = trip.2
    let perms : Array[Perm] = []
    for gi in rep_gens[r] {
      perms.push(t.elems[gi])
    }
    out.push({
      order: trip.0,
      members: rep_mems[r],
      group: PermGroup::new(t.n, perms),
    })
  }
  out
}

///|
/// 標記矩陣（table of marks）：M[i][j] = m_{H_i}(G/H_j) = #(H_i 固定之 H_j-陪集)。
/// 以陪集作用直接計算（第一種算法）。
pub fn table_of_marks(
  group : PermGroup,
  subs : Array[Sub],
  cap : Int32,
) -> Array[Array[Int32]] {
  // 每個 H_j 之陪集 G-集只需建一次
  let cosets : Array[GSetOf] = []
  for k in subs {
    cosets.push(coset_gset(group, k, cap))
  }
  // 三角性剪枝（定理）：H 固定某 H_j-陪集 ⇔ g⁻¹Hg ⊆ H_j ⇒ |H| ≤ |H_j|；
  // 故 |H| > |H_j| 時標記必為 0，免算陪集作用。
  let m : Array[Array[Int32]] = []
  for h in subs {
    let row : Array[Int32] = []
    for j, gs in cosets {
      row.push(if h.order > subs[j].order { 0 } else { gset_mark(gs, h) })
    }
    m.push(row)
  }
  m
}

///|
/// 標記矩陣之公式算法：M[i][j] = #{ 陪集 gH_j : g^{-1}H_i g ⊆ H_j }。
pub fn table_of_marks_formula(
  group : PermGroup,
  subs : Array[Sub],
  cap : Int32,
) -> Array[Array[Int32]] {
  let elems = group.elements(cap)
  let ng = elems.length()
  let n = group.size()
  let lut = PermLut::of_elems(elems)
  let imgs : Array[Array[Int32]] = []
  for e in elems {
    imgs.push(e.img)
  }
  let reps_all : Array[Array[Int32]] = []
  for k in subs {
    reps_all.push(coset_reps(elems, k, lut, ng))
  }
  let hmem : Array[Array[Int32]] = []
  for h in subs {
    hmem.push(h.members.to_array())
  }
  let tmp = Array::make(group.size(), 0)
  let m : Array[Array[Int32]] = []
  for hi, h in subs {
    let row : Array[Int32] = []
    let hidx = hmem[hi]
    for kj, k in subs {
      if h.order > k.order {
        row.push(0)
        continue
      }
      let reps = reps_all[kj]
      let mut c = 0
      for r in reps {
        let rimg = imgs[r]
        let rinv = Array::make(n, 0)
        for v in 0..<n {
          rinv[rimg[v]] = v
        }
        let mut ok = true
        for idx in hidx {
          let eimg = imgs[idx]
          for v in 0..<n {
            tmp[v] = eimg[rimg[v]]
          }
          let ci = lut.at_composed(rinv, tmp)
          if !k.members.get(ci) {
            ok = false
            break
          }
        }
        if ok {
          c = c + 1
        }
      }
      row.push(c)
    }
    m.push(row)
  }
  m
}

///|
/// H 之左陪集代表（元素索引）。
fn coset_reps(
  elems : Array[Perm],
  h : Sub,
  lut : PermLut,
  ng : Int32,
) -> Array[Int32] {
  let seen = Array::make(ng, false)
  let reps : Array[Int32] = []
  let hidx = h.members.to_array()
  for g in 0..<ng {
    if !seen[g] {
      reps.push(g)
      let gimg = elems[g].img
      for k in hidx {
        seen[lut.at_composed(gimg, elems[k].img)] = true
      }
    }
  }
  reps
}

///|
/// 陪集 G-集 G/H（左乘作用）。
pub fn coset_gset(group : PermGroup, h : Sub, cap : Int32) -> GSetOf {
  let elems = group.elements(cap)
  let ng = elems.length()
  let lut = PermLut::of_elems(elems)
  let imgs0 : Array[Array[Int32]] = []
  for e in elems {
    imgs0.push(e.img)
  }
  let coset_of = Array::make(ng, -1)
  let reps = coset_reps(elems, h, lut, ng)
  let hidx = h.members.to_array()
  for ci, r in reps {
    let rimg = imgs0[r]
    for k in hidx {
      coset_of[lut.at_composed(rimg, imgs0[k])] = ci
    }
  }
  let nc = reps.length()
  let imgs : Array[Array[Int32]] = []
  for ei in 0..<ng {
    let eimg = imgs0[ei]
    let img = Array::make(nc, 0)
    for ci, r in reps {
      img[ci] = coset_of[lut.at_composed(eimg, imgs0[r])]
    }
    imgs.push(img)
  }
  { x: nc, imgs, }
}

///|
/// Burnside 環 Möbius / 三角標記反演求解器：
/// 由上三角標記矩陣 `M[i][j] = m_{H_i}(G/H_j)`（`i > j => M[i][j] = 0`，`M[i][i] = [N_G(H_i):H_i] ≥ 1`）
/// 與標記向量 `marks[i] = |X^{H_i}|`，透過精確整數回代唯一解出傳遞軌道分解重數
/// `c = [c_0, ..., c_{ns-1}]`，使得 `[X] = Σ_j c_j [G/H_j] ∈ Ω(G)`；若標記向量非有效 G-集則回傳 `None`。
pub fn burnside_mobius_solve(
  m : Array[Array[Int32]],
  marks : Array[Int32],
) -> Array[Int32]? {
  let ns = m.length()
  guard marks.length() == ns else { return None }
  let c = Array::make(ns, 0)
  for step in 0..<ns {
    let i = ns - 1 - step
    let diag = m[i][i]
    if diag <= 0 {
      return None
    }
    let mut rem = marks[i].to_int64()
    for j in (i + 1)..<ns {
      rem = rem - m[i][j].to_int64() * c[j].to_int64()
    }
    if rem < 0L || rem % diag.to_int64() != 0L {
      return None
    }
    c[i] = (rem / diag.to_int64()).to_int()
  }
  Some(c)
}

///|
/// 標記定理之機器證書：
/// (a) 兩種算法（陪集作用直接計算 / 共軛包含公式）之標記矩陣一致；
/// (b) 下三角性：|H_i| > |H_j| ⇒ M[i][j] = 0；
/// (c) 對角正性：M[i][i] ≥ 1（= [G:N_G(H_i)]）。
/// (b)+(c) ⇒ M 可逆 ⇒ 標記映射單射 ⇒ 標記向量為 G-集之完全不變量。
/// 回傳 (a, b, c, 子群類數, |G|)。
pub fn marks_cert(
  group : PermGroup,
  cap : Int32,
) -> (Bool, Bool, Bool, Int32, Int64) {
  let subs = subgroup_classes(group, cap)
  let m1 = table_of_marks(group, subs, cap)
  let m2 = table_of_marks_formula(group, subs, cap)
  let ns = subs.length()
  let mut a = ns > 0
  for i in 0..<ns {
    for j in 0..<ns {
      if m1[i][j] != m2[i][j] {
        a = false
      }
    }
  }
  let mut b = true
  let mut c = true
  for i in 0..<ns {
    for j in 0..<ns {
      if subs[i].order > subs[j].order && m1[i][j] != 0 {
        b = false
      }
    }
    if m1[i][i] < 1 {
      c = false
    }
  }
  (a, b, c, ns, group.order())
}

///|
/// G-集同構判定（標記向量相等 ⇒ 同構；分類定理）。
/// 兩個 G-集需由**同一**群 G 作用（同一 `subgroup_classes` 列表）。
pub fn gset_isomorphic(gs1 : GSetOf, gs2 : GSetOf, subs : Array[Sub]) -> Bool {
  guard gs1.x == gs2.x else { return false }
  cmp_arr(mark_vector(gs1, subs), mark_vector(gs2, subs)) == 0
}

///|
/// Frobenius 互反（Set 版）：
/// lhs = |Hom_G(G×X, Y)|（暴力列舉等變映射），rhs = |Hom_Set(X, res Y)| = |Y|^{|X|}。
/// 回傳 (lhs, rhs)。需 |Y|^{|G||X|} ≤ cap。
pub fn frobenius_reciprocity(
  group : PermGroup,
  x : Int32,
  y : GSetOf,
  cap : Int32,
) -> (Int32, Int32) {
  let ind = gset_induced(group, x, cap)
  let np = ind.x
  // 函數 φ : G×X → Y 以 mixed-radix 整數編碼
  let mut total = 1
  for _ in 0..<np {
    guard total <= cap / y.x else {
      abort("frobenius_reciprocity: too many functions")
    }
    total = total * y.x
  }
  // 等變性檢查：對全部群元素（以元素表 imgs 直接比對）
  let mut lhs = 0
  let pow = Array::make(np, 1)
  for i in 1..<np {
    pow[i] = pow[i - 1] * y.x
  }
  for code in 0..<total {
    let phi = Array::make(np, 0)
    for i in 0..<np {
      phi[i] = code / pow[i] % y.x
    }
    let mut ok = true
    for k in 0..<ind.imgs.length() {
      let ia = ind.imgs[k]
      let ib = y.imgs[k]
      for i in 0..<np {
        if phi[ia[i]] != ib[phi[i]] {
          ok = false
          break
        }
      }
      if !ok {
        break
      }
    }
    if ok {
      lhs = lhs + 1
    }
  }
  let mut rhs = 1
  for _ in 0..<x {
    rhs = rhs * y.x
  }
  (lhs, rhs)
}
