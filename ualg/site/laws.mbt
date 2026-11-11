// ---------------------------------------------------------------------------
// ualg/site — 定律登記
// ---------------------------------------------------------------------------
// 與 ualg/core 相同的形狀：(章節名, 定律清單)。

///|
pub fn all_laws() -> Array[(String, Array[(String, Bool)])] {
  [
    ("Alexandrov 拓撲", law_alexandrov_topology()),
    ("開集的 Heyting 代數", law_heyting_algebra_of_opens()),
    ("雙重否定核子 j = ¬¬", law_double_negation_nucleus()),
    ("核子普查與 Isbell 稠密性", law_nuclei_census_and_isbell()),
    ("預層模板：層化是左伴隨", law_presheaf_template_sheafification()),
    ("其他拓撲與立方體上的層化", law_sheaves_for_other_topologies()),
  ]
}
