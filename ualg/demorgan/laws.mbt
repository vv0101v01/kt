// ---------------------------------------------------------------------------
// ualg/demorgan — 定律登記
// ---------------------------------------------------------------------------
// 與 ualg/core、ualg/site 相同的形狀：(章節名, 定律清單)。

///|
pub fn all_laws() -> Array[(String, Array[(String, Bool)])] {
  [
    ("Dedekind 數：三條路徑", law_dedekind_numbers_three_paths()),
    ("自由 De Morgan 代數：Kalman 正規形", law_demorgan_normal_form_kalman()),
    ("De Morgan 立方體範疇：代換", law_cube_category_substitution()),
    ("Aut([n]) = 超八面體群 B_n", law_cube_automorphisms_hyperoctahedral()),
    ("仿射片段：read-once 與 Gurvich 判準", law_affine_fragment_read_once()),
    ("面格 𝔽(n)：三條路徑與布林反射", law_face_lattice_three_paths()),
    ("面格上的量詞 ∃ ⊣ w ⊣ ∀", law_face_quantifiers_adjoint()),
    ("立方同調：開盒與邊界", law_cubical_homology_kan_boxes()),
    ("懸掛、推出、Künneth", law_suspension_pushout_kunneth()),
    ("Hodge 定理與 Laplace 譜", law_hodge_laplacian_spectrum()),
    ("正方形對稱的 Galois 對應", law_square_symmetry_galois()),
  ]
}
