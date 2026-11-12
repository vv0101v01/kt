// ---------------------------------------------------------------------------
// ualg/demorgan — 正方形的對稱：B₂ 在 DM(2)、𝔽(2) 上的作用與 Galois 對應
// ---------------------------------------------------------------------------
//
// [D-Act]   Aut([2]) = B₂ ≅ D₄ 以代換 f ↦ f∘σ 作用在 DM(2)（168 個元素）、
//           面格 𝔽(2)（48 個子複形）與仿射片段（14 個）上。
// [T-Burn]  軌道數：Burnside 平均 = 併查集直接合併（兩條路徑）。
// [T-Gal]   Fix ⊣ Stab：在 DM(2) 上 D₄ 的 10 個子群有 9 個是 Galois 閉的
//           （H = Stab(Fix(H))）；唯一例外是 C₄：Fix(C₄) = Fix(D₄)。
//           （原先猜「10 個全閉」，被這條定律的計算否定。）
// [T-OS]    軌道–穩定子：|軌道|·|穩定子| = 8。

///|
/// σ 在元素清單上誘導的置換；norm 把 f∘σ 送回清單所用的正規形。
pub fn subst_action(
  elems : Array[Array[Int32]],
  sigma : Array[Array[Int32]],
  norm : (Array[Int32]) -> Array[Int32],
) -> Array[Int32] {
  let index = dm_index(elems)
  elems.map(f => {
    match index.get(dnf_key(norm(dnf_subst(f, sigma)))) {
      Some(i) => i
      None => -1
    }
  })
}

///|
fn is_perm(f : Array[Int32]) -> Bool {
  let hit = Array::make(f.length(), false)
  for v in f {
    if v < 0 || hit[v] {
      return false
    }
    hit[v] = true
  }
  true
}

///|
/// 定律：正方形對稱群的軌道計數與 Galois 對應。
pub fn law_square_symmetry_galois() -> Array[(String, Bool)] {
  let out : Array[(String, Bool)] = []
  let x = dnf_var(0)
  let y = dnf_var(1)
  let group = mor_group([[y, x], [dnf_nvar(0), y]], 2)
  let id = (f : Array[Int32]) => f
  let dm = dm_elements(2)
  let faces : Array[Array[Int32]] = []
  let seen : Map[String, Bool] = Map([])
  for f in dm {
    let g = face_norm(f)
    if !seen.contains(dnf_key(g)) {
      seen[dnf_key(g)] = true
      faces.push(g)
    }
  }
  let (aff, _) = affine_elements(2)
  let p_dm = group.map(s => subst_action(dm, s, id))
  let p_face = group.map(s => subst_action(faces, s, face_norm))
  let p_aff = group.map(s => subst_action(aff, s, id))
  let mut perms_ok = true
  for ps in [p_dm, p_face, p_aff] {
    for f in ps {
      if !is_perm(f) {
        perms_ok = false
      }
    }
  }
  chk(
    out,
    "B₂ 的 8 個代換在 DM(2)（168）、𝔽(2)（48）、仿射片段（14）上都誘導置換（作用良定）",
    perms_ok && group.length() == 8 && faces.length() == 48,
  )
  let orbits : Array[Int32] = []
  let mut burnside = true
  for ps in [p_dm, p_face, p_aff] {
    let (sum, order) = @core.burnside_sum(ps)
    let direct = @core.orbit_count(ps)
    orbits.push(direct)
    if sum % order != 0 || sum / order != direct {
      burnside = false
    }
  }
  chk(
    out,
    "軌道數兩條路徑（Burnside = 併查集）：DM(2)、𝔽(2)、仿射片段 = \{@core.show_ints(orbits)}（正方形的子複形在對稱下共 \{orbits[1]} 型）",
    burnside && orbits[2] == 5,
  )
  // 軌道–穩定子
  let mut os = true
  for i in 0..<dm.length() {
    let orbit : Map[Int32, Bool] = Map([])
    let mut stab = 0
    for f in p_dm {
      orbit[f[i]] = true
      if f[i] == i {
        stab = stab + 1
      }
    }
    if orbit.length() * stab != 8 {
      os = false
    }
  }
  chk(
    out, "軌道–穩定子：DM(2) 的每個元素 |軌道|·|穩定子| = 8",
    os,
  )
  // 子群（暴力）與 Galois 閉子群（NextClosure）
  let mut subgroups = 0
  let mut closed_direct = 0
  let pol = @core.fixstab_polarity(dm.length(), p_dm)
  let pol_face = @core.fixstab_polarity(faces.length(), p_face)
  let pol_aff = @core.fixstab_polarity(aff.length(), p_aff)
  let fix_sizes : Array[Int32] = []
  let exceptions : Array[Int32] = []
  let mut exception_cyclic = false
  let mut face_closed = 0
  let mut aff_closed = 0
  for code in 1..<256 {
    let s = Array::makei(8, i => has(code, i))
    if @core.is_subgroup(p_dm, s) {
      subgroups = subgroups + 1
      let fix = @core.polar_up(pol, s)
      fix_sizes.push(@core.set_size(fix))
      let cl = @core.polar_down(pol, fix)
      if cl == s {
        closed_direct = closed_direct + 1
      } else {
        exceptions.push(@core.set_size(s))
        exceptions.push(@core.set_size(cl))
        // 含四階元 ⇔ 是循環群 C₄
        for i in 0..<8 {
          if s[i] {
            let f = p_dm[i]
            let mut square_is_id = true
            for v in 0..<f.length() {
              if f[f[v]] != v {
                square_is_id = false
              }
            }
            if !square_is_id {
              exception_cyclic = true
            }
          }
        }
      }
      if @core.polar_down(pol_face, @core.polar_up(pol_face, s)) == s {
        face_closed = face_closed + 1
      }
      if @core.polar_down(pol_aff, @core.polar_up(pol_aff, s)) == s {
        aff_closed = aff_closed + 1
      }
    }
  }
  fix_sizes.sort()
  let closed = @core.closed_sets_next_closure(pol)
  let mut closed_are_groups = true
  for s in closed {
    if !@core.is_subgroup(p_dm, s) {
      closed_are_groups = false
    }
  }
  chk(
    out,
    "D₄ 有 \{subgroups} 個子群（窮舉 255 個非空子集）；Galois 閉的有 \{closed_direct} 個，兩條路徑一致（逐一驗 H = Stab(Fix(H))；NextClosure 列舉閉集 \{closed.length()} 個且都是子群）",
    subgroups == 10 &&
    closed_direct == 9 &&
    closed.length() == closed_direct &&
    closed_are_groups,
  )
  chk(
    out,
    "唯一不閉的子群：階 \{exceptions[0]} 的循環群 C₄（旋轉 (x,y) ↦ (y,¬x)），閉包是整個 D₄（階 \{exceptions[1]}）——旋轉不變的 De Morgan 函數必全對稱（DM(2) 無手性元素）",
    exceptions == [4, 8] && exception_cyclic,
  )
  chk(
    out,
    "|Fix(H)| 排序 = \{@core.show_ints(fix_sizes)}：Fix(1) = 168、Fix(C₄) = Fix(D₄) = 8",
    fix_sizes[0] == 8 && fix_sizes[1] == 8 && fix_sizes[9] == 168,
  )
  chk(
    out,
    "被作用集合越小、閉子群越少：DM(2) 上 \{closed_direct} 個、𝔽(2) 上 \{face_closed} 個、仿射片段上 \{aff_closed} 個",
    aff_closed <= face_closed && face_closed <= closed_direct,
  )
  out
}
