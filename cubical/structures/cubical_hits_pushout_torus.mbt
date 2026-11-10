// ---------------------------------------------------------------------------
// cubical/structures — 高階歸納類型（HIT）2D 胞腔表達與整係數同調、圓形度數自同倫、
// 推出（Pushout）泛餘錐雙射、懸置（Suspension）`Σ ⊣ Ω` 伴隨與圓環 `T^2 ≃ S^1 × S^1`
// ---------------------------------------------------------------------------
//
// 編寫專屬數學結構落實《工作內容4.md》之高階歸納與同倫推出叢集：
//   - #12 推出構造（同倫推出黏合跨度 `A <- C -> B`：導出 `1 ⊔^{Bool} 1 ≃ S^1`、楔和 `S^1 ∨ S^1` 與
//         Klein 瓶 `aba^{-1}b` 黏合，計算 `H_1(K; Z) ≅ Z ⊕ Z/2Z` 撓率不變量）
//   - #42 高階歸納類型（一般 2D HIT 胞腔表達 `CubicalHit2Presentation`、歐拉示性數、整邊界矩陣
//         Smith 消元求 `H_0`/`H_1` 自由秩與撓率因子，並耦合 `@kernel.hit_schema_validate`）
//   - #43 圓形（`S^1` 泛映射性質：在 `@kernel` 中由 `eval_circle_elim` 構造度數映射 `deg_k : S^1 -> S^1`，
//         檢驗點 β `deg_k(base) ≡ base`、路徑 β `winding(ap_{deg_k}(loop)) == k` 與函子合成律 `deg_3 ∘ deg_{-2} ≃ deg_{-6}`）
//   - #44 懸置（由 `Pushout(!_C, !_C)` 導出懸置 `Susp(C)`，並結合 `@homotopy` 驗證 `Susp(Bool) ≃ S^1`
//         雙向往返及迴路—懸置伴隨 `loop_suspension_adjunction_equiv_value` `(ΣBool ->_* S^1) ≃ (Bool ->_* ΩS^1)`）
//   - #45 圓環（在 `@kernel` 中構造 `T^2 ≃ S^1 × S^1` 雙向消去器，證明開放 2-立方體點 `torus_point(i_0, i_1)`
//         與 `(circle_point(i_0), circle_point(i_1))` 之嚴格定義往返，並以 `torus_square_glued_cap` 驗證交換面填充與雙繞數阻礙）
//   - #46 推出（構造有限跨度推出 `CubicalPushoutHit` 及其消去器 `pushout_rec`，窮舉證明泛映射雙射
//         `Hom(A ⊔^C B, Y) ≅ Cocone(A <- C -> B, Y)` 雙向往返恆等）

///|
/// 2 維高階歸納類型（2D HIT）胞腔複形表達：
/// - `num_points`：0-胞腔（點構造子）個數；
/// - `paths_1`：1-胞腔端點對 `(src, dst)`；
/// - `squares_2`：2-胞腔邊界自由字 `Array[(edge_idx, sign)]`（`sign ∈ {+1, -1}`）。
#derive(Debug, Eq)
pub(all) struct CubicalHit2Presentation {
  name : String
  num_points : Int32
  paths_1 : Array[(Int32, Int32)]
  squares_2 : Array[Array[(Int32, Int32)]]
}

///|
pub extend CubicalHit2Presentation with @debug.Debug::{to_repr}

///|
pub extend CubicalHit2Presentation with Eq::{not_equal, equal}

///|
/// 2D HIT 同調不變量報告：`H_0` 連通分支數、歐拉示性數 `χ`、`H_1` 自由秩 `β_1` 與非平凡撓率因子（> 1 升序）。
#derive(Debug, Eq)
pub(all) struct Hit2HomologySummary {
  pi0_components : Int32
  euler_characteristic : Int32
  h1_free_rank : Int32
  h1_torsion_factors : Array[Int32]
}

///|
pub extend Hit2HomologySummary with @debug.Debug::{to_repr}

///|
pub extend Hit2HomologySummary with Eq::{not_equal, equal}

///|
fn iabs(x : Int32) -> Int32 {
  if x < 0 {
    -x
  } else {
    x
  }
}

///|
/// 對整數矩陣執行行列歐幾里得初等變換（Smith 標準形對角化），回傳非零不變因子（升序）。
pub fn integer_matrix_smith_invariants(
  rows : Int32,
  cols : Int32,
  flat_entries : Array[Int32],
) -> Array[Int32] {
  if rows == 0 || cols == 0 {
    return []
  }
  let m = flat_entries.copy()
  let limit = if rows < cols { rows } else { cols }
  let mut k = 0
  while k < limit {
    // 尋找子矩陣 [k..rows) x [k..cols) 中絕對值最小之非零元
    let mut piv_r = -1
    let mut piv_c = -1
    let mut best = 0
    for r in k..<rows {
      for c in k..<cols {
        let v = iabs(m[r * cols + c])
        if v > 0 && (piv_r == -1 || v < best) {
          best = v
          piv_r = r
          piv_c = c
        }
      }
    }
    if piv_r == -1 {
      break
    }
    // 交換至 (k, k)
    if piv_r != k {
      for c in 0..<cols {
        let tmp = m[k * cols + c]
        m[k * cols + c] = m[piv_r * cols + c]
        m[piv_r * cols + c] = tmp
      }
    }
    if piv_c != k {
      for r in 0..<rows {
        let tmp = m[r * cols + k]
        m[r * cols + k] = m[r * cols + piv_c]
        m[r * cols + piv_c] = tmp
      }
    }
    // 反覆以行列整除消去第 k 列與第 k 行其餘非零元
    let mut changed = true
    while changed {
      changed = false
      for r in (k + 1)..<rows {
        while m[r * cols + k] != 0 {
          let q = m[r * cols + k] / m[k * cols + k]
          for c in k..<cols {
            m[r * cols + c] = m[r * cols + c] - q * m[k * cols + c]
          }
          if m[r * cols + k] != 0 {
            for c in k..<cols {
              let tmp = m[k * cols + c]
              m[k * cols + c] = m[r * cols + c]
              m[r * cols + c] = tmp
            }
            changed = true
          }
        }
      }
      for c in (k + 1)..<cols {
        while m[k * cols + c] != 0 {
          let q = m[k * cols + c] / m[k * cols + k]
          for r in k..<rows {
            m[r * cols + c] = m[r * cols + c] - q * m[r * cols + k]
          }
          if m[k * cols + c] != 0 {
            for r in k..<rows {
              let tmp = m[r * cols + k]
              m[r * cols + k] = m[r * cols + c]
              m[r * cols + c] = tmp
            }
            changed = true
          }
        }
      }
      // 確保可整除性：若子塊中某元不被 m[k,k] 整除，將該行加至第 k 行重啟消元
      let piv = m[k * cols + k]
      let mut found_un = false
      for r in (k + 1)..<rows {
        if !found_un {
          for c in (k + 1)..<cols {
            if m[r * cols + c] % piv != 0 {
              for cc in k..<cols {
                m[k * cols + cc] = m[k * cols + cc] + m[r * cols + cc]
              }
              changed = true
              found_un = true
              break
            }
          }
        }
      }
    }
    if m[k * cols + k] < 0 {
      m[k * cols + k] = -m[k * cols + k]
    }
    k = k + 1
  }
  let diag : Array[Int32] = []
  for i in 0..<k {
    let d = iabs(m[i * cols + i])
    if d > 0 {
      diag.push(d)
    }
  }
  diag.sort()
  diag
}

///|
/// 計算任意 2D HIT 表達之連通分支數 `π_0`、歐拉示性數 `χ` 與一階整同調群 `H_1(X; Z)`。
pub fn compute_hit2_homology(
  hit : CubicalHit2Presentation,
) -> Hit2HomologySummary {
  let n0 = hit.num_points
  let n1 = hit.paths_1.length()
  let n2 = hit.squares_2.length()

  // 1. 並查集計算 π_0 連通分支數與 ∂_1 秩（rank(∂_1) = n0 - π_0）
  let parent = Array::make(n0, 0)
  for i in 0..<n0 {
    parent[i] = i
  }
  let find_root = fn(x0 : Int32) -> Int32 {
    let mut x = x0
    while parent[x] != x {
      parent[x] = parent[parent[x]]
      x = parent[x]
    }
    x
  }
  let mut comps = n0
  for e in 0..<n1 {
    let (u, v) = hit.paths_1[e]
    let ru = find_root(u)
    let rv = find_root(v)
    if ru != rv {
      parent[ru] = rv
      comps = comps - 1
    }
  }
  let rank_d1 = n0 - comps
  let z1_rank = n1 - rank_d1 // ker(∂_1) 自由阿貝爾秩

  // 2. 組裝 2-胞腔阿貝爾化邊界矩陣 ∂_2 : Z^{n2} -> Z^{n1}（n1 列 × n2 行）
  let d2_flat = Array::make(n1 * n2, 0)
  for f in 0..<n2 {
    let word = hit.squares_2[f]
    for step in word {
      let (edge_idx, sgn) = step
      d2_flat[edge_idx * n2 + f] = d2_flat[edge_idx * n2 + f] + sgn
    }
  }
  let inv_factors = integer_matrix_smith_invariants(n1, n2, d2_flat)
  let rank_d2 = inv_factors.length()
  let torsion : Array[Int32] = []
  for d in inv_factors {
    if d > 1 {
      torsion.push(d)
    }
  }
  Hit2HomologySummary::{
    pi0_components: comps,
    euler_characteristic: n0 - n1 + n2,
    h1_free_rank: z1_rank - rank_d2,
    h1_torsion_factors: torsion,
  }
}

// ---------------------------------------------------------------------------
// 推出（Pushout）`A ⊔^C B` 與泛餘錐映射雙射 `Hom(A ⊔^C B, Y) ≅ Cocone(f, g; Y)`
// ---------------------------------------------------------------------------

///|
/// 有限跨度 `A <-f- C -g-> B` 之同倫推出資料。
#derive(Debug, Eq)
pub(all) struct CubicalPushoutSpan {
  card_a : Int32
  card_b : Int32
  card_c : Int32
  leg_f : Array[Int32] // C -> A
  leg_g : Array[Int32] // C -> B
}

///|
pub extend CubicalPushoutSpan with @debug.Debug::{to_repr}

///|
pub extend CubicalPushoutSpan with Eq::{not_equal, equal}

///|
/// 將跨度 `A <- C -> B` 轉化為標準 2D HIT 表達（點 = `A ⊔ B`，1-胞腔 = `push(c) : inl(f(c)) -> inr(g(c))`）。
pub fn pushout_span_to_hit2(
  name : String,
  span : CubicalPushoutSpan,
) -> CubicalHit2Presentation {
  let paths : Array[(Int32, Int32)] = []
  for c in 0..<span.card_c {
    paths.push((span.leg_f[c], span.card_a + span.leg_g[c]))
  }
  CubicalHit2Presentation::{
    name,
    num_points: span.card_a + span.card_b,
    paths_1: paths,
    squares_2: [],
  }
}

///|
/// 計算集合層推出商 `π_0(A ⊔^C B)` 之正規代表元映射 `(inl_rep : A -> Q, inr_rep : B -> Q, card_q)`，
/// 並驗證對任意目標集 `[card_y]`，餘錐集合 `Cocone((f,g), Y) = {(h_A, h_B) | h_A ∘ f == h_B ∘ g}`
/// 與商空間映射 `Hom(Q, Y)` 之間由 `pushout_rec` 與 `( - ∘ inl, - ∘ inr )` 給出嚴格雙射！
pub fn verify_pushout_universal_cocone_bijection(
  span : CubicalPushoutSpan,
  card_y : Int32,
) -> (Bool, Int32, Int32) {
  let n_ab = span.card_a + span.card_b
  let parent = Array::make(n_ab, 0)
  for i in 0..<n_ab {
    parent[i] = i
  }
  let find_r = fn(x0 : Int32) -> Int32 {
    let mut x = x0
    while parent[x] != x {
      parent[x] = parent[parent[x]]
      x = parent[x]
    }
    x
  }
  for c in 0..<span.card_c {
    let ru = find_r(span.leg_f[c])
    let rv = find_r(span.card_a + span.leg_g[c])
    if ru != rv {
      parent[ru] = rv
    }
  }
  let root_to_q = Array::make(n_ab, -1)
  let mut card_q = 0
  for i in 0..<n_ab {
    let r = find_r(i)
    if root_to_q[r] == -1 {
      root_to_q[r] = card_q
      card_q = card_q + 1
    }
  }
  let inl_q = Array::make(span.card_a, 0)
  for a in 0..<span.card_a {
    inl_q[a] = root_to_q[find_r(a)]
  }
  let inr_q = Array::make(span.card_b, 0)
  for b in 0..<span.card_b {
    inr_q[b] = root_to_q[find_r(span.card_a + b)]
  }

  // 窮舉所有 Hom(Q, Y)（共 card_y^{card_q} 個），驗證限制至 (inl, inr) 必滿足餘錐條件且 pushout_rec 還原原映射
  let mut total_hom = 1
  for _ in 0..<card_q {
    total_hom = total_hom * card_y
  }
  let mut roundtrip_hom_ok = true
  for code in 0..<total_hom {
    let k_map = Array::make(card_q, 0)
    let mut rem = code
    for q in 0..<card_q {
      k_map[q] = rem % card_y
      rem = rem / card_y
    }
    let ha = Array::make(span.card_a, 0)
    for a in 0..<span.card_a {
      ha[a] = k_map[inl_q[a]]
    }
    let hb = Array::make(span.card_b, 0)
    for b in 0..<span.card_b {
      hb[b] = k_map[inr_q[b]]
    }
    for c in 0..<span.card_c {
      if ha[span.leg_f[c]] != hb[span.leg_g[c]] {
        roundtrip_hom_ok = false
      }
    }
    // pushout_rec(ha, hb) 重建 k_rec : Q -> Y
    let k_rec = Array::make(card_q, -1)
    for a in 0..<span.card_a {
      k_rec[inl_q[a]] = ha[a]
    }
    for b in 0..<span.card_b {
      k_rec[inr_q[b]] = hb[b]
    }
    if k_rec != k_map {
      roundtrip_hom_ok = false
    }
  }

  // 窮舉所有對 (h_A : A -> Y, h_B : B -> Y)，計數滿足 h_A ∘ f == h_B ∘ g 之合法餘錐數並驗證 β 定律
  let mut total_pairs = 1
  for _ in 0..<n_ab {
    total_pairs = total_pairs * card_y
  }
  let mut cocone_count = 0
  let mut beta_ok = true
  for code in 0..<total_pairs {
    let ha = Array::make(span.card_a, 0)
    let hb = Array::make(span.card_b, 0)
    let mut rem = code
    for a in 0..<span.card_a {
      ha[a] = rem % card_y
      rem = rem / card_y
    }
    for b in 0..<span.card_b {
      hb[b] = rem % card_y
      rem = rem / card_y
    }
    let mut valid = true
    for c in 0..<span.card_c {
      if ha[span.leg_f[c]] != hb[span.leg_g[c]] {
        valid = false
      }
    }
    if valid {
      cocone_count = cocone_count + 1
      let k_rec = Array::make(card_q, -1)
      for a in 0..<span.card_a {
        k_rec[inl_q[a]] = ha[a]
      }
      for b in 0..<span.card_b {
        k_rec[inr_q[b]] = hb[b]
      }
      for a in 0..<span.card_a {
        if k_rec[inl_q[a]] != ha[a] {
          beta_ok = false
        }
      }
      for b in 0..<span.card_b {
        if k_rec[inr_q[b]] != hb[b] {
          beta_ok = false
        }
      }
    }
  }

  (
    roundtrip_hom_ok && beta_ok && total_hom == cocone_count,
    total_hom,
    cocone_count,
  )
}

// ---------------------------------------------------------------------------
// 圓形度數映射 `deg_k : S^1 -> S^1` 與圓環雙向消去器 `T^2 ≃ S^1 × S^1`
// ---------------------------------------------------------------------------

///|
/// 在 `@kernel` 中構造基迴路 `k` 次整數冪 `loop^k : Path S^1 base base`。
pub fn circle_loop_power_value(k : Int32, dlevel : Int32) -> @kernel.DValue {
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let loop1 = @homotopy.circle_hit_loop_path_value()
  if k == 0 {
    return @kernel.DValue::DVPathLam(fn(_) { base })
  }
  let unit_step = if k > 0 { loop1 } else { @homotopy.dpath_sym_value(loop1) }
  let steps = iabs(k)
  let mut acc = unit_step
  for step_idx in 1..<steps {
    acc = @homotopy.dpath_trans_value(s1, acc, unit_step, dlevel + step_idx)
  }
  acc
}

///|
/// 由 `S^1` 泛消去性質構造度數 `k` 自映射 `deg_k : S^1 -> S^1`（`base ↦ base`, `loop ↦ loop^k`，顯式傳遞 `dlevel` 防止維度捕獲）。
pub fn circle_degree_map_value(k : Int32, dlevel : Int32) -> @kernel.DValue {
  let c_spec = @kernel.circle_schema()
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let loop_k = circle_loop_power_value(k, dlevel)
  @kernel.DValue::DVLam(fn(x) {
    @kernel.eval_hit_elim(
      c_spec,
      fn(_, _) { s1 },
      [base, loop_k],
      [],
      [],
      x,
      dlevel + 2,
    )
  })
}

///|
/// `T^2 -> S^1 × S^1`：由 `@kernel.eval_torus_elim` 將 `torus_point(a, b)` 映為原語圓形對 `(circle_point(a), circle_point(b))`。
pub fn torus_to_circle_product_value(
  t : @kernel.DValue,
  dlevel : Int32,
) -> @kernel.DValue {
  let prim_s1 = @kernel.DValue::DVCircleTy
  let prod_ty = @kernel.DValue::DVSigma(prim_s1, fn(_) { prim_s1 })
  @kernel.eval_torus_elim(
    fn(_) { prod_ty },
    fn(a, b) {
      @kernel.DValue::DVPair(@kernel.circle_point(a), @kernel.circle_point(b))
    },
    t,
    dlevel,
  )
}

///|
/// `S^1 × S^1 -> T^2`：雙重嵌套 `@kernel.eval_circle_elim` 將原語圓形對 `(ca, cb)` 映回 `torus_point(a, b)`。
pub fn circle_product_to_torus_value(
  pair : @kernel.DValue,
  dlevel : Int32,
) -> @kernel.DValue {
  let prim_s1 = @kernel.DValue::DVCircleTy
  let torus_ty = @kernel.DValue::DVTorusTy
  let ca = @kernel.dfst_typed(pair, fn(_) { prim_s1 })
  let cb = @kernel.dsnd_typed(pair, prim_s1, fn(_) { prim_s1 })
  @kernel.eval_circle_elim(
    fn(_) { torus_ty },
    @kernel.eval_circle_elim(
      fn(_) { torus_ty },
      @kernel.torus_point(DZero, DZero),
      @kernel.DValue::DVPathLam(fn(b) { @kernel.torus_point(DZero, b) }),
      cb,
      dlevel + 2,
    ),
    @kernel.DValue::DVPathLam(fn(a) {
      @kernel.eval_circle_elim(
        fn(_) { torus_ty },
        @kernel.torus_point(a, DZero),
        @kernel.DValue::DVPathLam(fn(b) { @kernel.torus_point(a, b) }),
        cb,
        dlevel + 2,
      )
    }),
    ca,
    dlevel + 2,
  )
}

///|
/// 高階歸納類型、圓形、懸置、圓環與推出驗證報告。
#derive(Debug, Eq)
pub(all) struct CubicalHitsPushoutTorusReport {
  kernel_hit_schemas_and_2d_homology_ok : Bool
  klein_bottle_pushout_torsion_z_plus_z2_ok : Bool
  pushout_universal_cocone_bijection_ok : Bool
  circle_degree_beta_and_functoriality_ok : Bool
  suspension_bool_circle_and_loop_adjunction_ok : Bool
  torus_circle_product_generic_2cube_roundtrip_ok : Bool
  torus_commutator_cap_and_biwinding_obstruction_ok : Bool
}

///|
pub extend CubicalHitsPushoutTorusReport with @debug.Debug::{to_repr}

///|
pub extend CubicalHitsPushoutTorusReport with Eq::{not_equal, equal}

///|
/// 執行 2D HIT 胞腔同調與核心模式檢驗（#42）、推出構造與泛餘錐雙射（#12/#46）、
/// 圓形度數映射（#43）、懸置與 `Σ ⊣ Ω` 伴隨（#44）、以及圓環 `T^2 ≃ S^1 × S^1`（#45）完整驗證。
pub fn verify_cubical_hits_pushout_torus_suite() -> CubicalHitsPushoutTorusReport {
  // 1. [#42 高階歸納類型] 受信任核心全部 HIT Schema 驗證 + S^1 / RP^2 / T^2 / Klein 瓶 2D 胞腔同調
  let examples = @kernel.hit_schema_examples()
  let mut schemas_ok = examples.length() > 0 &&
    @kernel.hit_schema_validate(@kernel.torus_schema())
  for spec in examples {
    if !@kernel.hit_schema_validate(spec) {
      schemas_ok = false
    }
  }
  let hit_s1 = CubicalHit2Presentation::{
    name: "S1",
    num_points: 1,
    paths_1: [(0, 0)],
    squares_2: [],
  }
  let hit_rp2 = CubicalHit2Presentation::{
    name: "RP2",
    num_points: 1,
    paths_1: [(0, 0)],
    squares_2: [[(0, 1), (0, 1)]],
  }
  let hit_t2 = CubicalHit2Presentation::{
    name: "T2",
    num_points: 1,
    paths_1: [(0, 0), (0, 0)],
    squares_2: [[(0, 1), (1, 1), (0, -1), (1, -1)]],
  }
  let hit_klein = CubicalHit2Presentation::{
    name: "KleinBottle",
    num_points: 1,
    paths_1: [(0, 0), (0, 0)],
    squares_2: [[(0, 1), (1, 1), (0, -1), (1, 1)]],
  }
  let h_s1 = compute_hit2_homology(hit_s1)
  let h_rp2 = compute_hit2_homology(hit_rp2)
  let h_t2 = compute_hit2_homology(hit_t2)
  let h_klein = compute_hit2_homology(hit_klein)
  let hit2_ok = schemas_ok &&
    h_s1.h1_free_rank == 1 &&
    h_s1.h1_torsion_factors == [] &&
    h_rp2.h1_free_rank == 0 &&
    h_rp2.h1_torsion_factors == [2] &&
    h_t2.h1_free_rank == 2 &&
    h_t2.h1_torsion_factors == [] &&
    h_t2.euler_characteristic == 0
  let klein_ok = h_klein.pi0_components == 1 &&
    h_klein.euler_characteristic == 0 &&
    h_klein.h1_free_rank == 1 &&
    h_klein.h1_torsion_factors == [2]

  // 2. [#12 推出構造 & #46 推出]
  //    (a) 懸置推出跨度 `1 <- Bool -> 1` 導出 `π_0 = 1, H_1 ≅ Z`（與 S^1 同調同構）；
  //    (b) 非平凡黏合跨度 `A={0,1,2} <- C={0,1} -> B={0,1}`（leg_f=[0,1], leg_g=[0,0]）合併 {a0,a1,b0}
  //        但保留 a2, b1 獨立（card_q = 3），對目標集 Y = {0,1,2} 窮舉驗證 `3^3 = 27` 個泛餘錐雙射！
  let susp_bool_span = CubicalPushoutSpan::{
    card_a: 1,
    card_b: 1,
    card_c: 2,
    leg_f: [0, 0],
    leg_g: [0, 0],
  }
  let h_susp_bool = compute_hit2_homology(
    pushout_span_to_hit2("SuspBool", susp_bool_span),
  )
  let glue_span = CubicalPushoutSpan::{
    card_a: 3,
    card_b: 2,
    card_c: 2,
    leg_f: [0, 1],
    leg_g: [0, 0],
  }
  let (cocone_bij, hom_card, cocone_card) = verify_pushout_universal_cocone_bijection(
    glue_span, 3,
  )
  let pushout_ok = h_susp_bool.pi0_components == 1 &&
    h_susp_bool.h1_free_rank == 1 &&
    cocone_bij &&
    hom_card == 27 &&
    cocone_card == 27

  // 3. [#43 圓形] `deg_k` 在 Schema `S^1` 上之點 β、路徑 β（`w(deg_3)=3, w(deg_2)=2, w(deg_{-2})=-2`）、
  //    單位/零度數律，以及函子合成度數乘法：`w(deg_3 ∘ deg_2) == +6` 且 `w(deg_{-2} ∘ deg_3) == -6`！
  let s1 = @homotopy.circle_hit_type_value()
  let base = @homotopy.circle_hit_base_value()
  let loop1 = @homotopy.circle_hit_loop_path_value()
  let deg3 = circle_degree_map_value(3, 12)
  let deg2 = circle_degree_map_value(2, 2)
  let deg_m2 = circle_degree_map_value(-2, 2)
  let gen_s1_pt = @kernel.DValue::DVHitCell(
    @kernel.circle_schema(),
    1,
    [],
    [],
    [@face_bdd.Dim::DVar(0)],
  )
  let pt_beta_ok = @kernel.conv_at(
      0,
      0,
      s1,
      @kernel.dapp_typed(deg3, base, s1),
      base,
    ) &&
    @kernel.conv_at(
      0,
      1,
      s1,
      @homotopy.circle_degree_value(1, gen_s1_pt, 2),
      gen_s1_pt,
    ) &&
    @kernel.conv_at(
      0,
      1,
      s1,
      @homotopy.circle_degree_value(0, gen_s1_pt, 2),
      base,
    )
  let p_3 = @homotopy.dpath_cong_value(deg3, s1, loop1)
  let p_2 = @homotopy.dpath_cong_value(deg2, s1, loop1)
  let p_m2 = @homotopy.dpath_cong_value(deg_m2, s1, loop1)
  let p_6 = @homotopy.dpath_cong_value(deg3, s1, p_2)
  let p_m6 = @homotopy.dpath_cong_value(deg_m2, s1, p_3)
  let w3 = @autonomy.univalent_circle_winding(p_3).unwrap_or(-99)
  let w2 = @autonomy.univalent_circle_winding(p_2).unwrap_or(-99)
  let wm2 = @autonomy.univalent_circle_winding(p_m2).unwrap_or(-99)
  let w6 = @autonomy.univalent_circle_winding(p_6).unwrap_or(-99)
  let wm6 = @autonomy.univalent_circle_winding(p_m6).unwrap_or(-99)
  let circle_ok = pt_beta_ok &&
    w3 == 3 &&
    w2 == 2 &&
    wm2 == -2 &&
    w6 == 6 &&
    wm6 == -6

  // 4. [#44 懸置] `@homotopy.susp_bool_equiv_circle_value`（基於 `bool_schema`）雙向往返 + `Σ ⊣ Ω` 伴隨等價！
  let b_spec = @kernel.bool_schema()
  let b_schema_ty = @kernel.DValue::DVInductive(b_spec, [], [])
  let bfalse_s = @kernel.DValue::DVIntro(b_spec, 0, [], [])
  let btrue_s = @kernel.DValue::DVIntro(b_spec, 1, [], [])
  let susp_b_schema_ty = @homotopy.susp_type_value(b_schema_ty)
  let eq_sb_s1 = @homotopy.susp_bool_equiv_circle_value(0)
  let north_s = @homotopy.susp_north_value(b_schema_ty)
  let south_s = @homotopy.susp_south_value(b_schema_ty)
  let north_img = @kernel.equiv_fun_value(
    eq_sb_s1, susp_b_schema_ty, s1, north_s,
  )
  let base_back = @kernel.equiv_inv_fun_value(
    eq_sb_s1, susp_b_schema_ty, s1, base,
  )
  // `merid(true) · merid(false)^{-1}` 在 `Susp(Bool) ≃ S^1` 下對應繞數 `±1` 生成元
  let m_true = @homotopy.susp_merid_path_value(b_schema_ty, btrue_s)
  let m_false = @homotopy.susp_merid_path_value(b_schema_ty, bfalse_s)
  let susp_loop = @homotopy.dpath_trans_value(
    susp_b_schema_ty,
    m_true,
    @homotopy.dpath_sym_value(m_false),
    0,
  )
  let fwd_fn = @kernel.DValue::DVLam(fn(z) {
    @kernel.equiv_fun_value(eq_sb_s1, susp_b_schema_ty, s1, z)
  })
  let w_susp_gen = iabs(
    @autonomy.univalent_circle_winding(
      @homotopy.dpath_cong_value(fwd_fn, susp_b_schema_ty, susp_loop),
    ).unwrap_or(0),
  )

  // 迴路—懸置伴隨：`Map*((Susp(Bool), north), (S^1, base)) ≃ Map*((Bool, false), (ΩS^1, refl_base))`
  let bool_ty = @kernel.DValue::DVBoolTy
  let susp_bool_ty = @homotopy.susp_type_value(bool_ty)
  let north = @homotopy.susp_north_value(bool_ty)
  let b_false = @kernel.DValue::DVBool(false)
  let b_true = @kernel.DValue::DVBool(true)
  let omega_s1 = @homotopy.loop_space_type_value(s1, base, 0)
  let refl_base = @homotopy.dpath_refl_value(base)
  let adj_eq = @homotopy.loop_suspension_adjunction_equiv_value(
    bool_ty, b_false, s1, base, 0,
  )
  let lhs_ty = @homotopy.based_map_type_value(susp_bool_ty, s1, north, base)
  let rhs_ty = @homotopy.based_map_type_value(
    bool_ty, omega_s1, b_false, refl_base,
  )
  // 構造右端保基點映射 `g_pt : (Bool, false) ->_* (ΩS^1, refl)`：`false ↦ refl`, `true ↦ loop^2`
  let loop2 = circle_loop_power_value(2, 0)
  let g_map = @kernel.DValue::DVLam(fn(b) {
    @kernel.eval_bool_elim(fn(_) { omega_s1 }, loop2, refl_base, b, 0)
  })
  let g_pt = @kernel.DValue::DVPair(
    g_map,
    @kernel.DValue::DVPathLam(fn(_) { refl_base }),
  )
  let adjunct_lhs = @kernel.equiv_inv_fun_value(adj_eq, lhs_ty, rhs_ty, g_pt)
  let roundtrip_rhs = @kernel.equiv_fun_value(
    adj_eq, lhs_ty, rhs_ty, adjunct_lhs,
  )
  let rt_map = @kernel.dfst_typed(roundtrip_rhs, fn(_) {
    @kernel.DValue::DVPathTy(fn(_) { omega_s1 }, refl_base, refl_base)
  })
  let w_rt_true = @autonomy.univalent_circle_winding(
    @kernel.dapp_typed(rt_map, b_true, bool_ty),
  ).unwrap_or(-99)
  let w_rt_false = @autonomy.univalent_circle_winding(
    @kernel.dapp_typed(rt_map, b_false, bool_ty),
  ).unwrap_or(-99)
  let south_not_north = !@kernel.conv_at(
    0, 0, susp_b_schema_ty, north_s, south_s,
  )
  let susp_ok = @kernel.conv_at(0, 0, s1, north_img, base) &&
    @kernel.conv_at(0, 0, susp_b_schema_ty, base_back, north_s) &&
    south_not_north &&
    w_susp_gen == 1 &&
    w_rt_true == 2 &&
    w_rt_false == 0

  // 5. [#45 圓環] 在 dlevel = 2（兩個自由維度變數 i_0, i_1）上檢驗 `T^2 ≃ S^1 × S^1` 嚴格定義往返，
  //    並驗證 `torus_square_glued_cap` 交換面填充 `(Some(_), 0, 0)` 與非平凡雙繞數阻礙 `(None, 1, -1)`！
  let prim_s1 = @kernel.DValue::DVCircleTy
  let torus_ty = @kernel.DValue::DVTorusTy
  let prod_s1 = @kernel.DValue::DVSigma(prim_s1, fn(_) { prim_s1 })
  let i0 = @face_bdd.Dim::DVar(0)
  let i1 = @face_bdd.Dim::DVar(1)
  let gen_torus_pt = @kernel.torus_point(i0, i1)
  let gen_prod_pt = @kernel.DValue::DVPair(
    @kernel.circle_point(i0),
    @kernel.circle_point(i1),
  )
  let rt_torus = circle_product_to_torus_value(
    torus_to_circle_product_value(gen_torus_pt, 2),
    2,
  )
  let rt_prod = torus_to_circle_product_value(
    circle_product_to_torus_value(gen_prod_pt, 2),
    2,
  )
  let torus_roundtrip_ok = @kernel.conv_at(
      2, 2, torus_ty, rt_torus, gen_torus_pt,
    ) &&
    @kernel.conv_at(2, 2, prod_s1, rt_prod, gen_prod_pt)

  // 交換邊界：i=0 與 i=1 皆沿第二迴路 q(j)，j=0 與 j=1 皆沿第一迴路 p(i) => 淨雙繞數 (0, 0)，成功填出 2-胞腔
  let (cap_comm, wa0, wb0) = @kernel.torus_square_glued_cap(
    fn(j) { @kernel.torus_point(DZero, j) },
    fn(j) { @kernel.torus_point(DZero, j) },
    fn(i) { @kernel.torus_point(i, DZero) },
    fn(i) { @kernel.torus_point(i, DZero) },
  )
  // 非交換阻礙邊界：底邊 j=0 繞 p 一次 `(i, 0)`，左邊 i=0 繞 q 一次 `(0, j)`，其餘兩邊退化為基點 `(0, 0)`
  // => 兩分量淨繞數皆非零，拒絕填充並回報精確雙繞數阻礙！
  let (cap_obs, wa_obs, wb_obs) = @kernel.torus_square_glued_cap(
    fn(j) { @kernel.torus_point(DZero, j) },
    fn(_) { @kernel.torus_point(DZero, DZero) },
    fn(i) { @kernel.torus_point(i, DZero) },
    fn(_) { @kernel.torus_point(DZero, DZero) },
  )
  let torus_cap_ok = cap_comm is Some(_) &&
    wa0 == 0 &&
    wb0 == 0 &&
    cap_obs is None &&
    iabs(wa_obs) == 1 &&
    iabs(wb_obs) == 1

  CubicalHitsPushoutTorusReport::{
    kernel_hit_schemas_and_2d_homology_ok: hit2_ok,
    klein_bottle_pushout_torsion_z_plus_z2_ok: klein_ok,
    pushout_universal_cocone_bijection_ok: pushout_ok,
    circle_degree_beta_and_functoriality_ok: circle_ok,
    suspension_bool_circle_and_loop_adjunction_ok: susp_ok,
    torus_circle_product_generic_2cube_roundtrip_ok: torus_roundtrip_ok,
    torus_commutator_cap_and_biwinding_obstruction_ok: torus_cap_ok,
  }
}
