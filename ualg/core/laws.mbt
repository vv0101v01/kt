// ---------------------------------------------------------------------------
// ualg/core — 定律登記
// ---------------------------------------------------------------------------
// 每條定律是一個 `law_*` 函式，回傳「標籤（含重算出的數字）＋布林」的清單；
// `cmd/ualg` 逐條執行並印出。新增定律：寫 `pub fn law_*`，再把它列進下面的清單。

///|
/// ualg/core 的全部定律，依章節分組：(章節名, 定律清單)。
pub fn all_laws() -> Array[(String, Array[(String, Bool)])] {
  [
    ("同餘格：兩條路徑", law_congruence_lattice_two_paths()),
    ("商代數與同構定理", law_quotient_and_isomorphism_theorems()),
    ("Mal'cev 項：三個演算法", law_malcev_three_algorithms()),
    ("Mal'cev 定理：同餘可換", law_malcev_theorem_permutability()),
    ("零元與吸收元普查", law_zero_and_absorbing_census()),
    ("理想與 Rees 商", law_ideals_and_rees_quotient()),
    ("Galois 連接與 NextClosure", law_galois_connection_and_next_closure()),
    (
      "Galois 基本定理（Fix ⊣ Stab）",
      law_galois_fixstab_fundamental_theorem(),
    ),
    ("Mod ⊣ Th：簇的 Galois 對應", law_galois_mod_th_varieties()),
    ("譜：平移算子與商", law_spectrum_functional_and_quotient()),
  ]
}
