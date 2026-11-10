///|
// 幾何複合與 Artin 膠合運算（Geometric Composition & Artin Gluing）：
//   1. [T-Artin-Gluing-Comma] 沿全域截面函子 Γ(P) = Hom_{PSh(C)}(1, P) 建構 Artin 膠合逗號範疇
//      Gl(Γ) = Set ↓ Γ：對象為 (S_sem, P_syn, α : S_sem -> Γ(P_syn))，態射滿足逗號交換方塊
//      Γ(f_P) ∘ α₁ = α₂ ∘ f_S，在終端對象與有限乘積下嚴格封閉。
//   2. [T-STC-Boolean-Canonicity] 合成 Tait 可計算性（Sterling 2021）布林正規性定理：
//      在雙連通分支離散景 Discrete(2) 上，純語法布林對象 1 + 1 擁有 2 × 2 = 4 個全域截面（含 2 個非規範混合截面），
//      而膠合布林對象 Bool_Gl 將語義謂詞 S = {0, 1} 對齊至規範注入 {inl, inr}，迫使全體膠合全域元
//      Hom_{Gl(Γ)}(1_Gl, Bool_Gl) 精確收縮為 2 個且語法投影必為 inl 或 inr（嚴格拒絕非規範混合截面）。
//   3. [T-SGA4-Recollement-Gluing] 謝爾賓斯基箭頭範疇 (0 -> 1) 上開子拓撲斯纖維 P(1)、閉子拓撲斯纖維 P(0)
//      與邊緣限制映射 r : P(1) -> P(0) 之 SGA4 重黏合（Recollement）雙向自然同構。
//   4. [T-Geometric-Morphism-Horizontal-Comp] 幾何態射水平複合 (ψ* ∘ φ*) ⊣ (φ_* ∘ ψ_*) 在預層上滿足
//      (ψ ∘ φ)^* P ≅ φ^*(ψ^* P) 且嚴格保持有限乘積與終端對象。

///|
/// Artin 膠合逗號範疇 `Gl(Γ) = Set ↓ Γ` 之對象 `(sem_card, syn_psh, display_map)`。
pub(all) struct ArtinGluedObject {
  sem_card : Int32
  syn_psh : @sym.Presheaf
  global_secs : Array[PresheafHom]
  display_map : Array[Int32]
}

///|
/// `Gl(Γ)` 中之膠合態射 `(sem_map : S₁ -> S₂, syn_hom : P₁ -> P₂)`。
pub(all) struct ArtinGluedMorphism {
  sem_map : Array[Int32]
  syn_hom : PresheafHom
}

///|
/// Artin 膠合、STC 正規性、SGA4 重黏合與幾何態射複合總體檢驗報告。
#derive(Debug, Eq)
pub(all) struct ArtinGluingGeometricReport {
  raw_discrete2_bool_sections : Int32
  glued_canonical_bool_elements : Int32
  noncanonical_mixed_rejected : Bool
  glued_product_universal_ok : Bool
  sga4_recollement_roundtrip_ok : Bool
  geometric_horizontal_comp_ok : Bool
  all_ok : Bool
}

///|
pub extend ArtinGluingGeometricReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend ArtinGluingGeometricReport with Eq::{not_equal, equal}

///|
fn find_global_sec_index(
  secs : Array[PresheafHom],
  target : PresheafHom,
) -> Int32 {
  for i in 0..<secs.length() {
    if presheaf_hom_eq(secs[i], target) {
      return i
    }
  }
  -1
}

///|
/// 驗證膠合對象良構性：每個語義元 `s ∈ 0..<sem_card` 皆指向 `Γ(syn_psh)` 中合法全域截面。
pub fn artin_glued_object_valid(obj : ArtinGluedObject) -> Bool {
  if obj.sem_card < 0 || obj.display_map.length() != obj.sem_card {
    return false
  }
  for s in 0..<obj.sem_card {
    let idx = obj.display_map[s]
    if idx < 0 || idx >= obj.global_secs.length() {
      return false
    }
  }
  true
}

///|
/// 驗證膠合態射滿足自然性與 Artin 逗號方塊交換律 `Γ(syn_hom)(α₁(s)) == α₂(sem_map(s))`。
pub fn artin_glued_morphism_valid(
  dom : ArtinGluedObject,
  cod : ArtinGluedObject,
  mor : ArtinGluedMorphism,
) -> Bool {
  if !artin_glued_object_valid(dom) || !artin_glued_object_valid(cod) {
    return false
  }
  if mor.sem_map.length() != dom.sem_card {
    return false
  }
  if !presheaf_hom_is_natural(dom.syn_psh, cod.syn_psh, mor.syn_hom) {
    return false
  }
  for s in 0..<dom.sem_card {
    let img_s = mor.sem_map[s]
    if img_s < 0 || img_s >= cod.sem_card {
      return false
    }
    let lhs_sec = presheaf_hom_compose(
      dom.global_secs[dom.display_map[s]],
      mor.syn_hom,
    )
    let rhs_sec = cod.global_secs[cod.display_map[img_s]]
    if !presheaf_hom_eq(lhs_sec, rhs_sec) {
      return false
    }
  }
  true
}

///|
/// 複合兩條 Artin 膠合態射 `(g_S ∘ f_S, g_P ∘ f_P)`。
pub fn artin_glued_compose(
  f : ArtinGluedMorphism,
  g : ArtinGluedMorphism,
) -> ArtinGluedMorphism {
  let comp_sem : Array[Int32] = []
  for i in 0..<f.sem_map.length() {
    comp_sem.push(g.sem_map[f.sem_map[i]])
  }
  ArtinGluedMorphism::{
    sem_map: comp_sem,
    syn_hom: presheaf_hom_compose(f.syn_hom, g.syn_hom),
  }
}

///|
/// `Gl(Γ)` 之膠合終端對象 `1_Gl = ({0}, 1_{PSh(C)}, 0 ↦ id_1)`。
pub fn artin_glued_terminal(cat : @sym.FinCat) -> ArtinGluedObject {
  let term = presheaf_terminal(cat)
  let secs = presheaf_hom_enumerate(term, term)
  ArtinGluedObject::{
    sem_card: 1,
    syn_psh: term,
    global_secs: secs,
    display_map: [0],
  }
}

///|
/// `Gl(Γ)` 之膠合乘積 `G₁ ×_{Gl} G₂`（語義笛卡兒積配對語法預層積）。
pub fn artin_glued_product(
  cat : @sym.FinCat,
  g1 : ArtinGluedObject,
  g2 : ArtinGluedObject,
) -> (ArtinGluedObject, ArtinGluedMorphism, ArtinGluedMorphism) {
  let term = presheaf_terminal(cat)
  let (prod_psh, pi1_hom, pi2_hom) = presheaf_product(g1.syn_psh, g2.syn_psh)
  let prod_secs = presheaf_hom_enumerate(term, prod_psh)
  let disp : Array[Int32] = []
  let proj1_sem : Array[Int32] = []
  let proj2_sem : Array[Int32] = []
  for s1 in 0..<g1.sem_card {
    for s2 in 0..<g2.sem_card {
      proj1_sem.push(s1)
      proj2_sem.push(s2)
      let sec1 = g1.global_secs[g1.display_map[s1]]
      let sec2 = g2.global_secs[g2.display_map[s2]]
      // 在每個對象 u 上找出唯一全域截面 sec_p 使得 pi1(sec_p) == sec1 且 pi2(sec_p) == sec2
      let mut found = 0
      for k in 0..<prod_secs.length() {
        let cand = prod_secs[k]
        if presheaf_hom_eq(presheaf_hom_compose(cand, pi1_hom), sec1) &&
          presheaf_hom_eq(presheaf_hom_compose(cand, pi2_hom), sec2) {
          found = k
          break
        }
      }
      disp.push(found)
    }
  }
  let obj = ArtinGluedObject::{
    sem_card: g1.sem_card * g2.sem_card,
    syn_psh: prod_psh,
    global_secs: prod_secs,
    display_map: disp,
  }
  (
    obj,
    ArtinGluedMorphism::{ sem_map: proj1_sem, syn_hom: pi1_hom, },
    ArtinGluedMorphism::{ sem_map: proj2_sem, syn_hom: pi2_hom, },
  )
}

///|
/// 合成 Tait 可計算性（STC）膠合布林對象 `Bool_Gl`：
/// 語法載體為 `1 + 1`，語義可計算集 `S = {0, 1}` 嚴格錨定至規範全域截面 `{inl, inr}`。
pub fn artin_glued_booleans(
  cat : @sym.FinCat,
) -> (ArtinGluedObject, PresheafHom, PresheafHom) {
  let term = presheaf_terminal(cat)
  let (bool_psh, inl_hom, inr_hom) = presheaf_coproduct(term, term)
  let secs = presheaf_hom_enumerate(term, bool_psh)
  let idx_l = find_global_sec_index(secs, inl_hom)
  let idx_r = find_global_sec_index(secs, inr_hom)
  (
    ArtinGluedObject::{
      sem_card: 2,
      syn_psh: bool_psh,
      global_secs: secs,
      display_map: [idx_l, idx_r],
    },
    inl_hom,
    inr_hom,
  )
}

///|
/// 枚舉全部合法膠合全域元 `Hom_{Gl(Γ)}(1_Gl, target)`。
pub fn artin_glued_enumerate_global_elements(
  cat : @sym.FinCat,
  target : ArtinGluedObject,
) -> Array[ArtinGluedMorphism] {
  let g_one = artin_glued_terminal(cat)
  let out : Array[ArtinGluedMorphism] = []
  for s in 0..<target.sem_card {
    for k in 0..<target.global_secs.length() {
      let cand = ArtinGluedMorphism::{
        sem_map: [s],
        syn_hom: target.global_secs[k],
      }
      if artin_glued_morphism_valid(g_one, target, cand) {
        out.push(cand)
      }
    }
  }
  out
}

///|
/// 複合兩個有限函子 `ψ ∘ φ : C -> E`（驅動幾何態射水平複合）。
pub fn compose_fin_functors(
  phi : @sym.FinFunctor,
  psi : @sym.FinFunctor,
) -> @sym.FinFunctor {
  let obj : Array[Int32] = []
  for x in 0..<phi.src.nobj {
    obj.push(psi.obj[phi.obj[x]])
  }
  let mor : Array[Int32] = []
  for m in 0..<phi.src.nmor {
    mor.push(psi.mor[phi.mor[m]])
  }
  { src: phi.src, dst: psi.dst, obj, mor, }
}

///|
/// SGA4 開—閉重黏合（Recollement）：在謝爾賓斯基箭頭範疇 `0 -> 1` 上，將任意預層 `P`
/// 分解為閉纖維 `P(0)`、開纖維 `P(1)` 與黏合映射 `gluing : P(1) -> P(0)`，並由黏合三元組重建預層。
pub fn sga4_recollement_reconstruct_arrow(
  closed_card : Int32,
  open_card : Int32,
  fringe_map_open_to_closed : Array[Int32],
) -> @sym.Presheaf {
  let arrow = @sym.cat_arrow()
  // 在 @sym.cat_arrow() 中對象為 0, 1，態射為 id_0, id_1 與非恆等箭頭 f : 0 -> 1；
  // 逆變預層限制 P(f) : P(1) -> P(0) 恰為開到閉之邊緣黏合映射！
  let res : Array[Array[Int32]] = []
  for m in 0..<arrow.nmor {
    let d = arrow.dom[m]
    let c = arrow.cod[m]
    if d == c {
      let n = if d == 0 { closed_card } else { open_card }
      res.push(Array::makei(n, i => i))
    } else {
      // d == 0, c == 1 => 逆變限制從 P(1) 映至 P(0)
      res.push(fringe_map_open_to_closed.copy())
    }
  }
  @sym.presheaf_new(arrow, [closed_card, open_card], res)
}

///|
/// 執行 Artin 膠合逗號範疇、STC 布林正規性、SGA4 重黏合與幾何態射水平複合完整驗證套件。
pub fn verify_artin_gluing_and_geometric_composition_suite() -> ArtinGluingGeometricReport {
  // 1. 離散雙點景 Discrete(2)：純語法 1 + 1 有 4 個全域截面，而膠合 Bool_Gl 精確篩出 2 個規範布林元
  let disc2 = @sym.cat_discrete(2)
  let (bool_gl, inl_h, inr_h) = artin_glued_booleans(disc2)
  let raw_secs = bool_gl.global_secs.length()
  let glued_elems = artin_glued_enumerate_global_elements(disc2, bool_gl)
  let mut canon_proj_ok = glued_elems.length() == 2
  for el in glued_elems {
    if !presheaf_hom_eq(el.syn_hom, inl_h) &&
      !presheaf_hom_eq(el.syn_hom, inr_h) {
      canon_proj_ok = false
    }
  }
  // 負對照：取一個在連通分支 0 選 inl、在連通分支 1 選 inr 之混合全域截面，驗證逗號方塊嚴格拒絕
  let g_one = artin_glued_terminal(disc2)
  let mut mixed_rejected = true
  for k in 0..<bool_gl.global_secs.length() {
    let sec = bool_gl.global_secs[k]
    if !presheaf_hom_eq(sec, inl_h) && !presheaf_hom_eq(sec, inr_h) {
      for s in 0..<2 {
        let bogus = ArtinGluedMorphism::{ sem_map: [s], syn_hom: sec, }
        if artin_glued_morphism_valid(g_one, bool_gl, bogus) {
          mixed_rejected = false
        }
      }
    }
  }

  // 2. Gl(Γ) 有限乘積泛性質與投影複合律
  let (prod_gl, pi1, pi2) = artin_glued_product(disc2, bool_gl, bool_gl)
  let prod_elems = artin_glued_enumerate_global_elements(disc2, prod_gl)
  let mut prod_ok = artin_glued_morphism_valid(prod_gl, bool_gl, pi1) &&
    artin_glued_morphism_valid(prod_gl, bool_gl, pi2) &&
    prod_elems.length() == 4
  if prod_elems.length() == 4 {
    let e01 = prod_elems[1] // 對應 (0, 1) -> (inl, inr)
    let c1 = artin_glued_compose(e01, pi1)
    let c2 = artin_glued_compose(e01, pi2)
    if !(artin_glued_morphism_valid(g_one, bool_gl, c1) &&
      artin_glued_morphism_valid(g_one, bool_gl, c2) &&
      presheaf_hom_eq(c1.syn_hom, inl_h) &&
      presheaf_hom_eq(c2.syn_hom, inr_h)) {
      prod_ok = false
    }
  }

  // 3. SGA4 開—閉重黏合雙向重建自然同構
  let arrow = @sym.cat_arrow()
  let fringe = [1, 0, 1] // P(1) = {0,1,2} -> P(0) = {0,1}
  let p_orig = sga4_recollement_reconstruct_arrow(2, 3, fringe)
  // 從預層提取閉纖維、開纖維與非恆等限制態射後重建，驗證預層同構
  let mut arrow_f_idx = 0
  for m in 0..<arrow.nmor {
    if arrow.dom[m] == 0 && arrow.cod[m] == 1 {
      arrow_f_idx = m
    }
  }
  let p_rebuilt = sga4_recollement_reconstruct_arrow(
    p_orig.size[0],
    p_orig.size[1],
    p_orig.res[arrow_f_idx],
  )
  let recoll_ok = presheaf_are_isomorphic(p_orig, p_rebuilt)

  // 4. 幾何態射水平複合：Discrete(2) -φ-> Arrow(0->1) -ψ-> Terminal(1)
  let term_cat = @sym.cat_terminal()
  let phi_mor : Array[Int32] = []
  for m in 0..<disc2.nmor {
    let o = disc2.dom[m]
    // 尋找 arrow 上對象 o 之恆等態射
    let mut id_m = 0
    for am in 0..<arrow.nmor {
      if arrow.dom[am] == o && arrow.cod[am] == o {
        id_m = am
      }
    }
    phi_mor.push(id_m)
  }
  let phi : @sym.FinFunctor = {
    src: disc2,
    dst: arrow,
    obj: [0, 1],
    mor: phi_mor,
  }
  let psi : @sym.FinFunctor = {
    src: arrow,
    dst: term_cat,
    obj: [0, 0],
    mor: Array::make(arrow.nmor, 0),
  }
  let comp_fn = compose_fin_functors(phi, psi)
  let base_set = @sym.presheaf_new(term_cat, [2], [[0, 1]])
  // 拉回 (ψ ∘ φ)* (base_set) ≅ φ* (ψ* (base_set))，其中 direct_image_presheaf 實作預複合拉回 f*
  let pull_comp = direct_image_presheaf(comp_fn, base_set)
  let pull_step = direct_image_presheaf(
    phi,
    direct_image_presheaf(psi, base_set),
  )
  // 同時驗證左正合性：拉回嚴格保持規範有限乘積 f*(A × B) = f*(A) × f*(B) 與箭頭範疇自然同構
  let (prod_base, _, _) = presheaf_product(base_set, base_set)
  let pull_prod = direct_image_presheaf(comp_fn, prod_base)
  let (prod_pull, _, _) = presheaf_product(pull_comp, pull_comp)
  let pull_psi = direct_image_presheaf(psi, base_set)
  let pull_psi_prod = direct_image_presheaf(psi, prod_base)
  let (prod_pull_psi, _, _) = presheaf_product(pull_psi, pull_psi)
  let horiz_ok = @sym.is_fin_functor(phi) &&
    @sym.is_fin_functor(psi) &&
    @sym.is_fin_functor(comp_fn) &&
    presheaf_are_isomorphic(pull_comp, pull_step) &&
    presheaf_are_isomorphic(pull_psi_prod, prod_pull_psi) &&
    pull_prod.size == prod_pull.size &&
    pull_prod.res == prod_pull.res

  let all_ok = raw_secs == 4 &&
    canon_proj_ok &&
    mixed_rejected &&
    prod_ok &&
    recoll_ok &&
    horiz_ok
  ArtinGluingGeometricReport::{
    raw_discrete2_bool_sections: raw_secs,
    glued_canonical_bool_elements: glued_elems.length(),
    noncanonical_mixed_rejected: mixed_rejected,
    glued_product_universal_ok: prod_ok,
    sga4_recollement_roundtrip_ok: recoll_ok,
    geometric_horizontal_comp_ok: horiz_ok,
    all_ok,
  }
}
