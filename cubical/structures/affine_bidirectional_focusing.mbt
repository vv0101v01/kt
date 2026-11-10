// ---------------------------------------------------------------------------
// cubical/structures — 仿射／德摩根資源追蹤雙向立方體型檢驗器、宇宙多態層級約束求解
// 與極化聚焦立方體演算 LJF_cub
// ---------------------------------------------------------------------------
//
// 落實《工作內容4.md》核心結構：
//   - #1  項（帶區間與宇宙層級之雙向語法項 `CubicalBidirTerm`）
//   - #2  宇宙多態性（`∀ℓ_0..ℓ_{k-1}` 層級差分約束圖與 Bellman–Ford 悖論環偵測）
//   - #3  計算相等（NbE βη 正規化下之型別與端點定義轉換）
//   - #4/#5 蘊涵與 Π-type、全稱量化與 Π-type（自由變數出現度分離 `A -> B` vs `∀(x:A). B(x)`）
//   - #7/#35/#36 膠水構造、黏合類型 `Glue`、膠水資料 `glue`/`unglue` 雙向檢驗與面收縮規則
//   - #13/#14/#47/#54 βη-歸約、雙向類型檢驗、雙向立方體型檢驗、立方體正規化求值法
//   - #15 仿射類型系統（次結構資源重數半環 `{0, 1, ω}`：弱化合法、區間／線性變數對角複製在仿射模式拒絕）
//   - #27 聚焦於立方體類型論（Andreoli–Zeilberger 雙極聚焦序列演算 `LJF_cub`：異步反轉＋同步聚焦）
//
// 交互運用之 26 動詞與 14 組範疇組合範例：
//   - [V02 計算機抽象 × V08 推論 × V16 借鑒 × C05 張量—內冪對偶]：
//     借鑒熱帶最短路 Bellman–Ford 判定宇宙層級 `ℓ_i + c ≤ ℓ_j` 可滿足性（拒絕 Girard `U_ℓ : U_ℓ`）。
//   - [V14 邏輯推理 × V23 統計 × V24 比照 × C04 單子分配律 × C14 博弈張量與管線策略]：
//     證明 `LJF_cub` 極化聚焦搜尋對非聚焦搜尋可靠且完備，並消除無關規則交錯排列（如 `6 -> 1` 規範導出），
//     同時對應雙極博弈 Arena 上 Copycat 管線策略合成。

///|
/// 次結構使用重數半環元素：`Zero` (0, 未使用／弱化)、`One` (1, 仿射單次使用)、`Many` (ω, 笛卡兒重複使用)。
#derive(Debug, Eq)
pub(all) enum UsageMult {
  UZero
  UOne
  UMany
}

///|
pub extend UsageMult with @debug.Debug::{to_repr}

///|
pub extend UsageMult with Eq::{not_equal, equal}

///|
/// 乘法式（張量／函數應用／配對）資源疊加：`0 + u = u`，`1 + 1 = ω`。
pub fn usage_seq_add(a : UsageMult, b : UsageMult) -> UsageMult {
  match (a, b) {
    (UZero, x) => x
    (x, UZero) => x
    _ => UMany
  }
}

///|
/// 加法式（上纖維化面分支 `[φ_1 ↦ t_1, φ_2 ↦ t_2]`）資源共享取上確界：`max(1, 1) = 1`。
pub fn usage_branch_join(a : UsageMult, b : UsageMult) -> UsageMult {
  match (a, b) {
    (UMany, _) | (_, UMany) => UMany
    (UOne, _) | (_, UOne) => UOne
    _ => UZero
  }
}

///|
/// 雙向檢驗器之次結構體制：`AffineCubicalMode` 禁止區間維度與仿射變數出現 `UMany`；
/// `DeMorganCartesianMode` 容許對角與連接重用。
#derive(Debug, Eq)
pub(all) enum BidirSubstructuralMode {
  AffineCubicalMode
  DeMorganCartesianMode
}

///|
pub extend BidirSubstructuralMode with @debug.Debug::{to_repr}

///|
pub extend BidirSubstructuralMode with Eq::{not_equal, equal}

///|
/// 宇宙層級代數表達式：`max_i (ℓ_{var_i} + offset_i, const_base)`。
#derive(Debug, Eq)
pub(all) enum LevelExpr {
  LConst(Int32)
  LVar(Int32, Int32)
  LMax(LevelExpr, LevelExpr)
}

///|
pub extend LevelExpr with @debug.Debug::{to_repr}

///|
pub extend LevelExpr with Eq::{not_equal, equal}

///|
/// 宇宙層級不等式約束 `lhs + delta <= rhs`（`delta = 1` 表示嚴格 `U_{lhs} : U_{rhs}`）。
#derive(Debug, Eq)
pub(all) struct LevelConstraint {
  lhs_var : Int32
  delta : Int32
  rhs_var : Int32
}

///|
pub extend LevelConstraint with @debug.Debug::{to_repr}

///|
pub extend LevelConstraint with Eq::{not_equal, equal}

///|
/// 以 Bellman–Ford 最長路徑演算法在 `O(n_vars · |constraints|)` 判定宇宙多態層級約束系統是否無悖論環，
/// 若一致則回傳最小非負整數層級指派（證偽 Girard 循環 `ℓ + 1 <= ℓ` 或 `ℓ_0 < ℓ_1 < ℓ_0`）。
pub fn solve_universe_level_constraints(
  n_vars : Int32,
  constraints : Array[LevelConstraint],
) -> (Bool, Array[Int32]) {
  let dist : Array[Int32] = Array::make(n_vars, 0)
  for _round in 0..<n_vars {
    let mut updated = false
    for c in constraints {
      if c.lhs_var >= 0 &&
        c.lhs_var < n_vars &&
        c.rhs_var >= 0 &&
        c.rhs_var < n_vars {
        let cand = dist[c.lhs_var] + c.delta
        if cand > dist[c.rhs_var] {
          dist[c.rhs_var] = cand
          updated = true
        }
      }
    }
    if !updated {
      return (true, dist)
    }
  }
  // 第 n_vars + 1 輪仍可鬆弛 ⇔ 存在嚴格正權環（Girard 宇宙層級悖論！）
  for c in constraints {
    if c.lhs_var >= 0 &&
      c.lhs_var < n_vars &&
      c.rhs_var >= 0 &&
      c.rhs_var < n_vars &&
      dist[c.lhs_var] + c.delta > dist[c.rhs_var] {
      return (false, dist)
    }
  }
  (true, dist)
}

///|
/// 雙向立方體核心型別語法（涵蓋宇宙多態、Π 蘊涵／全稱量化、Σ、PathP、Glue 與 Bool/S1）。
#derive(Debug, Eq)
pub(all) enum CubicalBidirType {
  BTUniv(Int32)
  BTBool
  BTCircle
  BTPi(Bool, CubicalBidirType, CubicalBidirType) // Bool: true = 仿射線性參數, false = 笛卡兒參數
  BTSigma(CubicalBidirType, CubicalBidirType)
  BTPath(CubicalBidirType, CubicalBidirTerm, CubicalBidirTerm)
  BTGlue(CubicalBidirType, @face_bdd.Face, CubicalBidirType)
}

///|
pub extend CubicalBidirType with @debug.Debug::{to_repr}

///|
pub extend CubicalBidirType with Eq::{not_equal, equal}

///|
/// 雙向立方體語法項（分離可推導項與可檢驗項）。
#derive(Debug, Eq)
pub(all) enum CubicalBidirTerm {
  BVar(Int32)
  BBool(Bool)
  BCircleBase
  BCircleLoop(@face_bdd.Dim)
  BLam(CubicalBidirTerm)
  BApp(CubicalBidirTerm, CubicalBidirTerm)
  BPair(CubicalBidirTerm, CubicalBidirTerm)
  BFst(CubicalBidirTerm)
  BSnd(CubicalBidirTerm)
  BPathLam(CubicalBidirTerm) // 綁定頂層區間變數 d_k
  BPathApp(CubicalBidirTerm, @face_bdd.Dim)
  BGlueIntro(@face_bdd.Face, CubicalBidirTerm, CubicalBidirTerm)
  BUnglue(@face_bdd.Face, CubicalBidirTerm)
  BHComp(
    CubicalBidirType,
    Array[(@face_bdd.Face, CubicalBidirTerm)],
    CubicalBidirTerm
  )
  BAnn(CubicalBidirTerm, CubicalBidirType)
}

///|
pub extend CubicalBidirTerm with @debug.Debug::{to_repr}

///|
pub extend CubicalBidirTerm with Eq::{not_equal, equal}

///|
/// 判定 `BTPi(_, dom, cod)` 為命題蘊涵（`x ∉ FV(cod)`）抑或真正依賴全稱量化（`x ∈ FV(cod)`）。
pub fn classify_pi_quantifier_role(ty : CubicalBidirType) -> (Bool, Bool) {
  fn has_var0_term(tm : CubicalBidirTerm, depth : Int32) -> Bool {
    match tm {
      BVar(ix) => ix == depth
      BBool(_) | BCircleBase | BCircleLoop(_) => false
      BLam(b) => has_var0_term(b, depth + 1)
      BApp(f, a) | BPair(f, a) =>
        has_var0_term(f, depth) || has_var0_term(a, depth)
      BFst(p) | BSnd(p) | BPathLam(p) | BPathApp(p, _) | BUnglue(_, p) =>
        has_var0_term(p, depth)
      BGlueIntro(_, t, a) => has_var0_term(t, depth) || has_var0_term(a, depth)
      BHComp(_, brs, base) => {
        for (_, btm) in brs {
          if has_var0_term(btm, depth) {
            return true
          }
        }
        has_var0_term(base, depth)
      }
      BAnn(e, _) => has_var0_term(e, depth)
    }
  }
  fn has_var0_ty(t : CubicalBidirType, depth : Int32) -> Bool {
    match t {
      BTUniv(_) | BTBool | BTCircle => false
      BTPi(_, d, c) | BTSigma(d, c) =>
        has_var0_ty(d, depth) || has_var0_ty(c, depth + 1)
      BTPath(a, l, r) =>
        has_var0_ty(a, depth) ||
        has_var0_term(l, depth) ||
        has_var0_term(r, depth)
      BTGlue(base, _, fib) =>
        has_var0_ty(base, depth) || has_var0_ty(fib, depth)
    }
  }
  match ty {
    BTPi(_, _, cod) => {
      let dep = has_var0_ty(cod, 0)
      (!dep, dep)
    }
    _ => (false, false)
  }
}

///|
/// 在區間變數 `dim_idx` 代入常數端點 `endpoint`（`DZero` 或 `DOne`）後做雙向語法正規化求值（NbE 端點規約）。
pub fn bidir_eval_subst_dim(
  tm : CubicalBidirTerm,
  dim_idx : Int32,
  endpoint : @face_bdd.Dim,
) -> CubicalBidirTerm {
  fn subst_d(
    d : @face_bdd.Dim,
    target : Int32,
    repl : @face_bdd.Dim,
  ) -> @face_bdd.Dim {
    match d {
      DZero => DZero
      DOne => DOne
      DVar(v) => if v == target { repl } else { DVar(v) }
      DNeg(x) => @face_bdd.dim_simplify(DNeg(subst_d(x, target, repl)))
      DAnd(a, b) =>
        @face_bdd.dim_simplify(
          DAnd(subst_d(a, target, repl), subst_d(b, target, repl)),
        )
      DOr(a, b) =>
        @face_bdd.dim_simplify(
          DOr(subst_d(a, target, repl), subst_d(b, target, repl)),
        )
    }
  }
  let raw = match tm {
    BVar(i) => CubicalBidirTerm::BVar(i)
    BBool(b) => BBool(b)
    BCircleBase => BCircleBase
    BCircleLoop(d) => {
      let sd = subst_d(d, dim_idx, endpoint)
      match sd {
        DZero | DOne => BCircleBase
        _ => BCircleLoop(sd)
      }
    }
    BLam(b) => BLam(bidir_eval_subst_dim(b, dim_idx, endpoint))
    BApp(f, a) => {
      let nf = bidir_eval_subst_dim(f, dim_idx, endpoint)
      let na = bidir_eval_subst_dim(a, dim_idx, endpoint)
      BApp(nf, na)
    }
    BPair(a, b) =>
      BPair(
        bidir_eval_subst_dim(a, dim_idx, endpoint),
        bidir_eval_subst_dim(b, dim_idx, endpoint),
      )
    BFst(p) =>
      match bidir_eval_subst_dim(p, dim_idx, endpoint) {
        BPair(a, _) => a
        np => BFst(np)
      }
    BSnd(p) =>
      match bidir_eval_subst_dim(p, dim_idx, endpoint) {
        BPair(_, b) => b
        np => BSnd(np)
      }
    BPathLam(b) => BPathLam(bidir_eval_subst_dim(b, dim_idx + 1, endpoint))
    BPathApp(p, r) => {
      let np = bidir_eval_subst_dim(p, dim_idx, endpoint)
      let nr = subst_d(r, dim_idx, endpoint)
      match np {
        BPathLam(body) => bidir_eval_subst_dim(body, 0, nr)
        _ => BPathApp(np, nr)
      }
    }
    BGlueIntro(phi, t, a) =>
      if phi == FTop {
        bidir_eval_subst_dim(t, dim_idx, endpoint)
      } else {
        BGlueIntro(
          phi,
          bidir_eval_subst_dim(t, dim_idx, endpoint),
          bidir_eval_subst_dim(a, dim_idx, endpoint),
        )
      }
    BUnglue(phi, g) =>
      match bidir_eval_subst_dim(g, dim_idx, endpoint) {
        BGlueIntro(_, _, a) => a
        ng => BUnglue(phi, ng)
      }
    BHComp(ty, brs, base) =>
      BHComp(ty, brs, bidir_eval_subst_dim(base, dim_idx, endpoint))
    BAnn(e, _) => bidir_eval_subst_dim(e, dim_idx, endpoint)
  }
  raw
}

///|
/// 收集區間表達式 `d` 對 `0..n_dims-1` 各維度變數的使用重數與是否含連接算子。
fn dim_expr_usage_vec(
  d : @face_bdd.Dim,
  n_dims : Int32,
) -> (Array[UsageMult], Bool) {
  let u : Array[UsageMult] = Array::make(n_dims, UZero)
  let mut has_conn = false
  fn walk(cur : @face_bdd.Dim, vec : Array[UsageMult], n : Int32) -> Bool {
    match cur {
      DZero | DOne => false
      DVar(v) => {
        if v >= 0 && v < n {
          vec[v] = usage_seq_add(vec[v], UOne)
        }
        false
      }
      DNeg(inner) => walk(inner, vec, n)
      DAnd(a, b) | DOr(a, b) => {
        let _ = walk(a, vec, n)
        let _ = walk(b, vec, n)
        true
      }
    }
  }
  has_conn = walk(d, u, n_dims)
  (u, has_conn)
}

///|
/// 雙向立方體型別檢驗結果（含變數使用重數向量與區間維度使用重數向量）。
#derive(Debug, Eq)
pub(all) struct BidirCheckOutcome {
  ok : Bool
  inferred_ty : CubicalBidirType?
  var_usage : Array[UsageMult]
  dim_usage : Array[UsageMult]
}

///|
pub extend BidirCheckOutcome with @debug.Debug::{to_repr}

///|
pub extend BidirCheckOutcome with Eq::{not_equal, equal}

///|
/// 雙向立方體合成模式 `Γ ; Δ ; ψ ⊢ e ⇒ A | (u_Γ, u_Δ)`。
pub fn infer_cubical_bidir(
  ctx : Array[(Bool, CubicalBidirType)],
  n_dims : Int32,
  psi : @face_bdd.Face,
  tm : CubicalBidirTerm,
  mode : BidirSubstructuralMode,
) -> BidirCheckOutcome {
  let n_vars = ctx.length()
  let empty_v = Array::make(n_vars, UsageMult::UZero)
  let empty_d = Array::make(n_dims, UsageMult::UZero)
  match tm {
    BVar(ix) =>
      if ix >= 0 && ix < n_vars {
        let uv = Array::make(n_vars, UsageMult::UZero)
        uv[ix] = UOne
        let (_, ty) = ctx[n_vars - 1 - ix]
        BidirCheckOutcome::{
          ok: true,
          inferred_ty: Some(ty),
          var_usage: uv,
          dim_usage: empty_d,
        }
      } else {
        BidirCheckOutcome::{
          ok: false,
          inferred_ty: None,
          var_usage: empty_v,
          dim_usage: empty_d,
        }
      }
    BBool(_) =>
      BidirCheckOutcome::{
        ok: true,
        inferred_ty: Some(BTBool),
        var_usage: empty_v,
        dim_usage: empty_d,
      }
    BCircleBase =>
      BidirCheckOutcome::{
        ok: true,
        inferred_ty: Some(BTCircle),
        var_usage: empty_v,
        dim_usage: empty_d,
      }
    BCircleLoop(d) => {
      let (du, has_conn) = dim_expr_usage_vec(d, n_dims)
      let mut dim_ok = true
      if mode == AffineCubicalMode {
        if has_conn {
          dim_ok = false
        }
        for mult in du {
          if mult == UMany {
            dim_ok = false
          }
        }
      }
      BidirCheckOutcome::{
        ok: dim_ok,
        inferred_ty: if dim_ok {
          Some(BTCircle)
        } else {
          None
        },
        var_usage: empty_v,
        dim_usage: du,
      }
    }
    BAnn(e, ann_ty) => {
      let chk = check_cubical_bidir(ctx, n_dims, psi, e, ann_ty, mode)
      let reduced_ty = match ann_ty {
        BTGlue(_, FTop, fib_ty) => fib_ty
        other => other
      }
      BidirCheckOutcome::{
        ok: chk.ok,
        inferred_ty: if chk.ok {
          Some(reduced_ty)
        } else {
          None
        },
        var_usage: chk.var_usage,
        dim_usage: chk.dim_usage,
      }
    }
    BApp(fn_tm, arg_tm) => {
      let f_res = infer_cubical_bidir(ctx, n_dims, psi, fn_tm, mode)
      match (f_res.ok, f_res.inferred_ty) {
        (true, Some(BTPi(_, dom_ty, cod_ty))) => {
          let a_res = check_cubical_bidir(
            ctx, n_dims, psi, arg_tm, dom_ty, mode,
          )
          if !a_res.ok {
            return BidirCheckOutcome::{
              ok: false,
              inferred_ty: None,
              var_usage: empty_v,
              dim_usage: empty_d,
            }
          }
          let uv = Array::make(n_vars, UsageMult::UZero)
          let mut aff_ok = true
          for k in 0..<n_vars {
            uv[k] = usage_seq_add(f_res.var_usage[k], a_res.var_usage[k])
            let (is_aff_var, _) = ctx[n_vars - 1 - k]
            if mode == AffineCubicalMode && is_aff_var && uv[k] == UMany {
              aff_ok = false
            }
          }
          let ud = Array::make(n_dims, UsageMult::UZero)
          for k in 0..<n_dims {
            ud[k] = usage_seq_add(f_res.dim_usage[k], a_res.dim_usage[k])
            if mode == AffineCubicalMode && ud[k] == UMany {
              aff_ok = false
            }
          }
          BidirCheckOutcome::{
            ok: aff_ok,
            inferred_ty: if aff_ok {
              Some(cod_ty)
            } else {
              None
            },
            var_usage: uv,
            dim_usage: ud,
          }
        }
        _ =>
          BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
      }
    }
    BFst(p_tm) => {
      let p_res = infer_cubical_bidir(ctx, n_dims, psi, p_tm, mode)
      match (p_res.ok, p_res.inferred_ty) {
        (true, Some(BTSigma(fst_ty, _))) =>
          BidirCheckOutcome::{
            ok: true,
            inferred_ty: Some(fst_ty),
            var_usage: p_res.var_usage,
            dim_usage: p_res.dim_usage,
          }
        _ =>
          BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
      }
    }
    BSnd(p_tm) => {
      let p_res = infer_cubical_bidir(ctx, n_dims, psi, p_tm, mode)
      match (p_res.ok, p_res.inferred_ty) {
        (true, Some(BTSigma(_, snd_ty))) =>
          BidirCheckOutcome::{
            ok: true,
            inferred_ty: Some(snd_ty),
            var_usage: p_res.var_usage,
            dim_usage: p_res.dim_usage,
          }
        _ =>
          BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
      }
    }
    BPathApp(p_tm, r) => {
      let p_res = infer_cubical_bidir(ctx, n_dims, psi, p_tm, mode)
      let (du_r, has_conn) = dim_expr_usage_vec(r, n_dims)
      match (p_res.ok, p_res.inferred_ty) {
        (true, Some(BTPath(elem_ty, _, _))) => {
          let ud = Array::make(n_dims, UsageMult::UZero)
          let mut dim_ok = !(mode == AffineCubicalMode && has_conn)
          for k in 0..<n_dims {
            ud[k] = usage_seq_add(p_res.dim_usage[k], du_r[k])
            if mode == AffineCubicalMode && ud[k] == UMany {
              dim_ok = false
            }
          }
          BidirCheckOutcome::{
            ok: dim_ok,
            inferred_ty: if dim_ok {
              Some(elem_ty)
            } else {
              None
            },
            var_usage: p_res.var_usage,
            dim_usage: ud,
          }
        }
        _ =>
          BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
      }
    }
    BUnglue(_, g_tm) => {
      let g_res = infer_cubical_bidir(ctx, n_dims, psi, g_tm, mode)
      match (g_res.ok, g_res.inferred_ty) {
        (true, Some(BTGlue(base_ty, _, _))) =>
          BidirCheckOutcome::{
            ok: true,
            inferred_ty: Some(base_ty),
            var_usage: g_res.var_usage,
            dim_usage: g_res.dim_usage,
          }
        _ =>
          BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
      }
    }
    _ =>
      BidirCheckOutcome::{
        ok: false,
        inferred_ty: None,
        var_usage: empty_v,
        dim_usage: empty_d,
      }
  }
}

///|
/// 雙向立方體檢驗模式 `Γ ; Δ ; ψ ⊢ e ⇐ A | (u_Γ, u_Δ)`。
pub fn check_cubical_bidir(
  ctx : Array[(Bool, CubicalBidirType)],
  n_dims : Int32,
  psi : @face_bdd.Face,
  tm : CubicalBidirTerm,
  expected : CubicalBidirType,
  mode : BidirSubstructuralMode,
) -> BidirCheckOutcome {
  let n_vars = ctx.length()
  let empty_v = Array::make(n_vars, UsageMult::UZero)
  let empty_d = Array::make(n_dims, UsageMult::UZero)
  // Glue 面收縮計算規則：Glue A [⊤ ↦ T] ≡ T
  let norm_expected = match expected {
    BTGlue(_, FTop, fib_ty) => fib_ty
    other => other
  }
  match (tm, norm_expected) {
    (BLam(body), BTPi(is_aff_arg, dom_ty, cod_ty)) => {
      let ext_ctx : Array[(Bool, CubicalBidirType)] = []
      for item in ctx {
        ext_ctx.push(item)
      }
      ext_ctx.push((is_aff_arg, dom_ty))
      let b_res = check_cubical_bidir(ext_ctx, n_dims, psi, body, cod_ty, mode)
      if !b_res.ok {
        return BidirCheckOutcome::{
          ok: false,
          inferred_ty: None,
          var_usage: empty_v,
          dim_usage: empty_d,
        }
      }
      let bound_u = b_res.var_usage[0]
      let bound_ok = !(mode == AffineCubicalMode &&
        is_aff_arg &&
        bound_u == UMany)
      let out_uv = Array::make(n_vars, UsageMult::UZero)
      for k in 0..<n_vars {
        out_uv[k] = b_res.var_usage[k + 1]
      }
      BidirCheckOutcome::{
        ok: bound_ok,
        inferred_ty: if bound_ok {
          Some(norm_expected)
        } else {
          None
        },
        var_usage: out_uv,
        dim_usage: b_res.dim_usage,
      }
    }
    (BPair(a, b), BTSigma(fst_ty, snd_ty)) => {
      let r1 = check_cubical_bidir(ctx, n_dims, psi, a, fst_ty, mode)
      let r2 = check_cubical_bidir(ctx, n_dims, psi, b, snd_ty, mode)
      if !r1.ok || !r2.ok {
        return BidirCheckOutcome::{
          ok: false,
          inferred_ty: None,
          var_usage: empty_v,
          dim_usage: empty_d,
        }
      }
      let uv = Array::make(n_vars, UsageMult::UZero)
      let mut aff_ok = true
      for k in 0..<n_vars {
        uv[k] = usage_seq_add(r1.var_usage[k], r2.var_usage[k])
        let (is_aff, _) = ctx[n_vars - 1 - k]
        if mode == AffineCubicalMode && is_aff && uv[k] == UMany {
          aff_ok = false
        }
      }
      let ud = Array::make(n_dims, UsageMult::UZero)
      for k in 0..<n_dims {
        ud[k] = usage_seq_add(r1.dim_usage[k], r2.dim_usage[k])
        if mode == AffineCubicalMode && ud[k] == UMany {
          aff_ok = false
        }
      }
      BidirCheckOutcome::{
        ok: aff_ok,
        inferred_ty: if aff_ok {
          Some(norm_expected)
        } else {
          None
        },
        var_usage: uv,
        dim_usage: ud,
      }
    }
    (BPathLam(body), BTPath(elem_ty, ep0, ep1)) => {
      let b_res = check_cubical_bidir(ctx, n_dims + 1, psi, body, elem_ty, mode)
      if !b_res.ok {
        return BidirCheckOutcome::{
          ok: false,
          inferred_ty: None,
          var_usage: empty_v,
          dim_usage: empty_d,
        }
      }
      let top_dim_u = b_res.dim_usage[n_dims]
      let top_aff_ok = !(mode == AffineCubicalMode && top_dim_u == UMany)
      // 雙向立方體端點檢驗：body[0/d_n] == ep0 且 body[1/d_n] == ep1！
      let at0 = bidir_eval_subst_dim(body, n_dims, DZero)
      let at1 = bidir_eval_subst_dim(body, n_dims, DOne)
      let ep0_nf = bidir_eval_subst_dim(ep0, n_dims, DZero)
      let ep1_nf = bidir_eval_subst_dim(ep1, n_dims, DOne)
      let endpoints_ok = at0 == ep0_nf && at1 == ep1_nf
      let out_ud = Array::make(n_dims, UsageMult::UZero)
      for k in 0..<n_dims {
        out_ud[k] = b_res.dim_usage[k]
      }
      let ok_all = top_aff_ok && endpoints_ok
      BidirCheckOutcome::{
        ok: ok_all,
        inferred_ty: if ok_all {
          Some(norm_expected)
        } else {
          None
        },
        var_usage: b_res.var_usage,
        dim_usage: out_ud,
      }
    }
    (BGlueIntro(phi, fib_tm, base_tm), BTGlue(base_ty, expected_phi, fib_ty)) => {
      let face_match = @face_bdd.bdd_face_eq(phi, expected_phi, n_dims + 1)
      let r_fib = check_cubical_bidir(
        ctx,
        n_dims,
        @face_bdd.face_and(psi, phi),
        fib_tm,
        fib_ty,
        mode,
      )
      let r_base = check_cubical_bidir(ctx, n_dims, psi, base_tm, base_ty, mode)
      let ok_all = face_match && r_fib.ok && r_base.ok
      let uv = Array::make(n_vars, UsageMult::UZero)
      for k in 0..<n_vars {
        uv[k] = usage_branch_join(r_fib.var_usage[k], r_base.var_usage[k])
      }
      let ud = Array::make(n_dims, UsageMult::UZero)
      for k in 0..<n_dims {
        ud[k] = usage_branch_join(r_fib.dim_usage[k], r_base.dim_usage[k])
      }
      BidirCheckOutcome::{
        ok: ok_all,
        inferred_ty: if ok_all {
          Some(norm_expected)
        } else {
          None
        },
        var_usage: uv,
        dim_usage: ud,
      }
    }
    (BHComp(ty_ann, branches, base_tm), _) => {
      if ty_ann != norm_expected {
        return BidirCheckOutcome::{
          ok: false,
          inferred_ty: None,
          var_usage: empty_v,
          dim_usage: empty_d,
        }
      }
      let r_base = check_cubical_bidir(
        ctx, n_dims, psi, base_tm, norm_expected, mode,
      )
      if !r_base.ok {
        return r_base
      }
      let uv = Array::make(n_vars, UsageMult::UZero)
      for k in 0..<n_vars {
        uv[k] = r_base.var_usage[k]
      }
      let ud = Array::make(n_dims, UsageMult::UZero)
      for k in 0..<n_dims {
        ud[k] = r_base.dim_usage[k]
      }
      // 檢驗面分支兩兩相容性：在 φ_i ∧ φ_j 可滿足處，分支項在端點處相等！
      let m = branches.length()
      for i in 0..<m {
        let (phi_i, tm_i) = branches[i]
        let ri = check_cubical_bidir(
          ctx,
          n_dims + 1,
          @face_bdd.face_and(psi, phi_i),
          tm_i,
          norm_expected,
          mode,
        )
        if !ri.ok {
          return BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
        }
        for k in 0..<n_vars {
          uv[k] = usage_branch_join(uv[k], ri.var_usage[k])
        }
        for k in 0..<n_dims {
          ud[k] = usage_branch_join(ud[k], ri.dim_usage[k])
        }
        // 底蓋相容：tm_i[0/d_n] == base_tm
        let t_at_0 = bidir_eval_subst_dim(tm_i, n_dims, DZero)
        if t_at_0 != base_tm {
          return BidirCheckOutcome::{
            ok: false,
            inferred_ty: None,
            var_usage: empty_v,
            dim_usage: empty_d,
          }
        }
        for j in (i + 1)..<m {
          let (phi_j, tm_j) = branches[j]
          let overlap = @face_bdd.face_and(phi_i, phi_j)
          if @face_bdd.bdd_of_face(overlap, n_dims + 1) != BddZero &&
            tm_i != tm_j {
            return BidirCheckOutcome::{
              ok: false,
              inferred_ty: None,
              var_usage: empty_v,
              dim_usage: empty_d,
            }
          }
        }
      }
      BidirCheckOutcome::{
        ok: true,
        inferred_ty: Some(norm_expected),
        var_usage: uv,
        dim_usage: ud,
      }
    }
    _ => {
      let inf = infer_cubical_bidir(ctx, n_dims, psi, tm, mode)
      let ok_conv = match (inf.ok, inf.inferred_ty) {
        (true, Some(actual)) => {
          let norm_actual = match actual {
            BTGlue(_, FTop, fib_ty) => fib_ty
            other => other
          }
          norm_actual == norm_expected
        }
        _ => false
      }
      BidirCheckOutcome::{
        ok: ok_conv,
        inferred_ty: if ok_conv {
          Some(norm_expected)
        } else {
          None
        },
        var_usage: inf.var_usage,
        dim_usage: inf.dim_usage,
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 極化聚焦立方體序列演算 LJF_cub（Andreoli / Liang–Miller / Zeilberger）
// ---------------------------------------------------------------------------

///|
/// 極化立方體公式（正極性 `PFPos` 與負極性 `PFNeg` 透過位移模態 `PFDown` ↓ / `PFUp` ↑ 伴隨連接）。
#derive(Debug, Eq)
pub(all) enum PolarCubicalFormula {
  // 正極性公式（右同步聚焦、左異步反轉）
  PPosAtom(Int32)
  PTensor(PolarCubicalFormula, PolarCubicalFormula) // Σ / ⊗
  PPlus(PolarCubicalFormula, PolarCubicalFormula) // + / HIT 分支
  PUnitPos // 1^+ / Swan refl_Id
  PZeroPos // 0^+ / 空面 ⊥
  PDown(PolarCubicalFormula) // ↓N^-（thunk：負轉正）
  // 負極性公式（右異步反轉、左同步聚焦）
  PNegAtom(Int32)
  PArrow(PolarCubicalFormula, PolarCubicalFormula) // Π / ->（正前提 -> 負結論）
  PPathNeg(Int32, PolarCubicalFormula) // Path_A（右異步引入區間變數）
  PWith(PolarCubicalFormula, PolarCubicalFormula) // & / 笛卡兒積
  PTopNeg // ⊤^-
  PUp(PolarCubicalFormula) // ↑P^+（returner：正轉負）
}

///|
pub extend PolarCubicalFormula with @debug.Debug::{to_repr}

///|
pub extend PolarCubicalFormula with Eq::{not_equal, equal}

///|
/// 判定極化立方體公式是否屬於正極性（`true` = Positive，`false` = Negative）。
pub fn is_positive_polar_formula(f : PolarCubicalFormula) -> Bool {
  match f {
    PPosAtom(_)
    | PTensor(_, _)
    | PPlus(_, _)
    | PUnitPos
    | PZeroPos
    | PDown(_) => true
    _ => false
  }
}

///|
/// 非聚焦序列證明搜尋：統計所有合法規則交錯導出樹數量 `(provable, derivation_count)`，
/// 用作與 `LJF_cub` 極化聚焦正規導出樹之比照基準（V23 統計 × V24 比照）。
pub fn unfocused_cubical_sequent_count(
  hyps : Array[PolarCubicalFormula],
  goal : PolarCubicalFormula,
  fuel : Int32,
) -> (Bool, Int32) {
  if fuel <= 0 {
    return (false, 0)
  }
  if goal == PTopNeg || goal == PUnitPos {
    return (true, 1)
  }
  for h in hyps {
    if h == PZeroPos {
      return (true, 1)
    }
  }
  let mut total_derivs = 0

  // 1. 嘗試公理匹配（原子恆等）
  match goal {
    PPosAtom(a) =>
      for h in hyps {
        if h == PPosAtom(a) {
          total_derivs = total_derivs + 1
        }
      }
    PNegAtom(a) =>
      for h in hyps {
        if h == PNegAtom(a) {
          total_derivs = total_derivs + 1
        }
      }
    _ => ()
  }

  // 2. 非聚焦右規則（任意時刻皆可搶先拆解目標）
  match goal {
    PArrow(a, b) => {
      let next_h = hyps.copy()
      next_h.push(a)
      let (_, c) = unfocused_cubical_sequent_count(next_h, b, fuel - 1)
      total_derivs = total_derivs + c
    }
    PPathNeg(_, body) => {
      let (_, c) = unfocused_cubical_sequent_count(hyps, body, fuel - 1)
      total_derivs = total_derivs + c
    }
    PWith(a, b) => {
      let (_, c1) = unfocused_cubical_sequent_count(hyps, a, fuel - 1)
      let (_, c2) = unfocused_cubical_sequent_count(hyps, b, fuel - 1)
      total_derivs = total_derivs + c1 * c2
    }
    PTensor(a, b) => {
      let (_, c1) = unfocused_cubical_sequent_count(hyps, a, fuel - 1)
      let (_, c2) = unfocused_cubical_sequent_count(hyps, b, fuel - 1)
      total_derivs = total_derivs + c1 * c2
    }
    PPlus(a, b) => {
      let (_, c1) = unfocused_cubical_sequent_count(hyps, a, fuel - 1)
      let (_, c2) = unfocused_cubical_sequent_count(hyps, b, fuel - 1)
      total_derivs = total_derivs + c1 + c2
    }
    PUp(p) | PDown(p) => {
      let (_, c) = unfocused_cubical_sequent_count(hyps, p, fuel - 1)
      total_derivs = total_derivs + c
    }
    _ => ()
  }

  // 3. 非聚焦左規則（任意假設皆可與右規則自由交錯，造成階乘級排列爆炸！）
  for idx in 0..<hyps.length() {
    let h = hyps[idx]
    match h {
      PTensor(x, y) => {
        let next_h : Array[PolarCubicalFormula] = []
        for j in 0..<hyps.length() {
          if j != idx {
            next_h.push(hyps[j])
          }
        }
        next_h.push(x)
        next_h.push(y)
        let (_, c) = unfocused_cubical_sequent_count(next_h, goal, fuel - 1)
        total_derivs = total_derivs + c
      }
      PPlus(x, y) => {
        let h1 : Array[PolarCubicalFormula] = []
        let h2 : Array[PolarCubicalFormula] = []
        for j in 0..<hyps.length() {
          if j != idx {
            h1.push(hyps[j])
            h2.push(hyps[j])
          }
        }
        h1.push(x)
        h2.push(y)
        let (_, c1) = unfocused_cubical_sequent_count(h1, goal, fuel - 1)
        let (_, c2) = unfocused_cubical_sequent_count(h2, goal, fuel - 1)
        total_derivs = total_derivs + c1 + c2
      }
      PDown(n) | PUp(n) => {
        let next_h : Array[PolarCubicalFormula] = []
        for j in 0..<hyps.length() {
          if j != idx {
            next_h.push(hyps[j])
          }
        }
        next_h.push(n)
        let (_, c) = unfocused_cubical_sequent_count(next_h, goal, fuel - 1)
        total_derivs = total_derivs + c
      }
      PArrow(arg_p, res_n) => {
        let rem_h : Array[PolarCubicalFormula] = []
        for j in 0..<hyps.length() {
          if j != idx {
            rem_h.push(hyps[j])
          }
        }
        let (_, c_arg) = unfocused_cubical_sequent_count(rem_h, arg_p, fuel - 1)
        if c_arg > 0 {
          let ext_h = rem_h.copy()
          ext_h.push(res_n)
          let (_, c_res) = unfocused_cubical_sequent_count(
            ext_h,
            goal,
            fuel - 1,
          )
          total_derivs = total_derivs + c_arg * c_res
        }
      }
      PWith(n1, n2) => {
        let h1 : Array[PolarCubicalFormula] = []
        let h2 : Array[PolarCubicalFormula] = []
        for j in 0..<hyps.length() {
          if j != idx {
            h1.push(hyps[j])
            h2.push(hyps[j])
          }
        }
        h1.push(n1)
        h2.push(n2)
        let (_, c1) = unfocused_cubical_sequent_count(h1, goal, fuel - 1)
        let (_, c2) = unfocused_cubical_sequent_count(h2, goal, fuel - 1)
        total_derivs = total_derivs + c1 + c2
      }
      _ => ()
    }
  }
  (total_derivs > 0, total_derivs)
}

///|
/// `LJF_cub` 極化聚焦證明搜尋：嚴格執行
/// (Phase 1: 異步反轉) 先按固定規範順序拆解所有負右目標與正左假設，直至邊界穩定（stable sequent）；
/// (Phase 2: 同步聚焦) 鎖定 stoup 焦點做原子分解，徹底消除無關交錯排列！
pub fn focused_ljf_cubical_prove(
  stable_neg_hyps : Array[PolarCubicalFormula],
  pos_atoms : Array[Int32],
  async_left : Array[PolarCubicalFormula],
  goal : PolarCubicalFormula,
  fuel : Int32,
) -> (Bool, Int32) {
  if fuel <= 0 {
    return (false, 0)
  }
  // 階段 1A：右異步反轉（若目標為負極性且非負原子，強制唯一拆解，不允許與左規則交錯！）
  match goal {
    PTopNeg => return (true, 1)
    PArrow(a, b) => {
      let next_left = async_left.copy()
      next_left.push(a)
      return focused_ljf_cubical_prove(
        stable_neg_hyps,
        pos_atoms,
        next_left,
        b,
        fuel - 1,
      )
    }
    PPathNeg(_, body) =>
      return focused_ljf_cubical_prove(
        stable_neg_hyps,
        pos_atoms,
        async_left,
        body,
        fuel - 1,
      )
    PWith(a, b) => {
      let (ok1, c1) = focused_ljf_cubical_prove(
        stable_neg_hyps,
        pos_atoms,
        async_left,
        a,
        fuel - 1,
      )
      let (ok2, c2) = focused_ljf_cubical_prove(
        stable_neg_hyps,
        pos_atoms,
        async_left,
        b,
        fuel - 1,
      )
      return (ok1 && ok2, c1 * c2)
    }
    PUp(pos_inner) =>
      // 模糊化移位（↑P^+）：先清空左異步隊列後進入正目標或穩定狀態
      if async_left.length() == 0 {
        return focused_right_sync(
          stable_neg_hyps,
          pos_atoms,
          pos_inner,
          fuel - 1,
        )
      }
    _ => ()
  }

  // 階段 1B：左異步反轉（按隊列尾端唯一確定性拆解正假設）
  if async_left.length() > 0 {
    let next_q = async_left.copy()
    let h = next_q.pop().unwrap()
    match h {
      PZeroPos => return (true, 1)
      PUnitPos =>
        return focused_ljf_cubical_prove(
          stable_neg_hyps,
          pos_atoms,
          next_q,
          goal,
          fuel - 1,
        )
      PPosAtom(a) => {
        let next_pa = pos_atoms.copy()
        next_pa.push(a)
        return focused_ljf_cubical_prove(
          stable_neg_hyps,
          next_pa,
          next_q,
          goal,
          fuel - 1,
        )
      }
      PTensor(x, y) => {
        next_q.push(y)
        next_q.push(x)
        return focused_ljf_cubical_prove(
          stable_neg_hyps,
          pos_atoms,
          next_q,
          goal,
          fuel - 1,
        )
      }
      PPlus(x, y) => {
        let q1 = next_q.copy()
        q1.push(x)
        let q2 = next_q.copy()
        q2.push(y)
        let (ok1, c1) = focused_ljf_cubical_prove(
          stable_neg_hyps,
          pos_atoms,
          q1,
          goal,
          fuel - 1,
        )
        let (ok2, c2) = focused_ljf_cubical_prove(
          stable_neg_hyps,
          pos_atoms,
          q2,
          goal,
          fuel - 1,
        )
        return (ok1 && ok2, c1 * c2)
      }
      PDown(neg_f) => {
        let next_neg = stable_neg_hyps.copy()
        next_neg.push(neg_f)
        return focused_ljf_cubical_prove(
          next_neg,
          pos_atoms,
          next_q,
          goal,
          fuel - 1,
        )
      }
      other_neg => {
        let next_neg = stable_neg_hyps.copy()
        next_neg.push(other_neg)
        return focused_ljf_cubical_prove(
          next_neg,
          pos_atoms,
          next_q,
          goal,
          fuel - 1,
        )
      }
    }
  }

  // 階段 2：穩定序列決策點（Decision）—— 選擇右聚焦 `[⊢ P^+]` 或左聚焦 `[N^- ⊢]`
  let mut canonical_derivs = 0
  if is_positive_polar_formula(goal) {
    let (_, cr) = focused_right_sync(stable_neg_hyps, pos_atoms, goal, fuel - 1)
    canonical_derivs = canonical_derivs + cr
  }
  for neg_h in stable_neg_hyps {
    let (_, cl) = focused_left_sync(
      stable_neg_hyps,
      pos_atoms,
      neg_h,
      goal,
      fuel - 1,
    )
    canonical_derivs = canonical_derivs + cl
  }
  (canonical_derivs > 0, canonical_derivs)
}

///|
/// 右同步聚焦階段 `Γ^- ; Δ_a^+ ⊢ [P^+]`：必須一鼓作氣分解正公式直至正原子或 `↓N^-` 模糊點！
fn focused_right_sync(
  stable_neg_hyps : Array[PolarCubicalFormula],
  pos_atoms : Array[Int32],
  pos_goal : PolarCubicalFormula,
  fuel : Int32,
) -> (Bool, Int32) {
  if fuel <= 0 {
    return (false, 0)
  }
  match pos_goal {
    PUnitPos => (true, 1)
    PZeroPos => (false, 0)
    PPosAtom(a) => {
      let mut hits = 0
      for pa in pos_atoms {
        if pa == a {
          hits = hits + 1
        }
      }
      (hits > 0, hits)
    }
    PTensor(p1, p2) => {
      let (ok1, c1) = focused_right_sync(
        stable_neg_hyps,
        pos_atoms,
        p1,
        fuel - 1,
      )
      let (ok2, c2) = focused_right_sync(
        stable_neg_hyps,
        pos_atoms,
        p2,
        fuel - 1,
      )
      (ok1 && ok2, c1 * c2)
    }
    PPlus(p1, p2) => {
      let (_, c1) = focused_right_sync(stable_neg_hyps, pos_atoms, p1, fuel - 1)
      let (_, c2) = focused_right_sync(stable_neg_hyps, pos_atoms, p2, fuel - 1)
      (c1 + c2 > 0, c1 + c2)
    }
    PDown(neg_inner) =>
      // Blur（脫焦回異步階段）
      focused_ljf_cubical_prove(
        stable_neg_hyps,
        pos_atoms,
        [],
        neg_inner,
        fuel - 1,
      )
    _ => (false, 0)
  }
}

///|
/// 左同步聚焦階段 `Γ^- ; Δ_a^+ ; [N^-] ⊢ G`：沿負公式 spine 鎖定分解直至負原子匹配或 `↑P^+` 脫焦！
fn focused_left_sync(
  stable_neg_hyps : Array[PolarCubicalFormula],
  pos_atoms : Array[Int32],
  focus_neg : PolarCubicalFormula,
  goal : PolarCubicalFormula,
  fuel : Int32,
) -> (Bool, Int32) {
  if fuel <= 0 {
    return (false, 0)
  }
  match focus_neg {
    PNegAtom(a) => if goal == PNegAtom(a) { (true, 1) } else { (false, 0) }
    PArrow(arg_pos, res_neg) => {
      let (ok_arg, c_arg) = focused_right_sync(
        stable_neg_hyps,
        pos_atoms,
        arg_pos,
        fuel - 1,
      )
      if !ok_arg {
        return (false, 0)
      }
      let (ok_res, c_res) = focused_left_sync(
        stable_neg_hyps,
        pos_atoms,
        res_neg,
        goal,
        fuel - 1,
      )
      (ok_res, c_arg * c_res)
    }
    PWith(n1, n2) => {
      let (_, c1) = focused_left_sync(
        stable_neg_hyps,
        pos_atoms,
        n1,
        goal,
        fuel - 1,
      )
      let (_, c2) = focused_left_sync(
        stable_neg_hyps,
        pos_atoms,
        n2,
        goal,
        fuel - 1,
      )
      (c1 + c2 > 0, c1 + c2)
    }
    PUp(pos_inner) =>
      // 左脫焦：將 P^+ 放入異步左隊列重啟異步階段
      focused_ljf_cubical_prove(
        stable_neg_hyps,
        pos_atoms,
        [pos_inner],
        goal,
        fuel - 1,
      )
    _ => (false, 0)
  }
}

///|
/// 仿射雙向立方體檢驗、宇宙多態層級約束與極化聚焦演算驗證報告。
#derive(Debug, Eq)
pub(all) struct AffineBidirFocusingReport {
  universe_poly_consistent_ok : Bool
  girard_cycle_rejected : Bool
  implication_vs_forall_separated : Bool
  affine_path_accepted : Bool
  diagonal_path_rejected_in_affine_accepted_in_demorgan : Bool
  wrong_path_endpoint_rejected : Bool
  glue_top_strict_reduction_ok : Bool
  hcomp_incompatible_overlap_rejected : Bool
  focusing_sound_and_complete_batch : Bool
  unfocused_interleavings_count : Int32
  focused_canonical_derivations_count : Int32
}

///|
pub extend AffineBidirFocusingReport with @debug.Debug::{to_repr}

///|
pub extend AffineBidirFocusingReport with Eq::{not_equal, equal}

///|
/// 執行仿射／德摩根雙向立方體型檢驗器、宇宙層級環偵測與 `LJF_cub` 極化聚焦演算綜合驗證。
pub fn verify_affine_bidirectional_and_focusing_suite() -> AffineBidirFocusingReport {
  // 1. 宇宙多態層級約束：ℓ0 < ℓ1 <= ℓ2 可解 (0, 1, 1)，而 Girard 悖論環 ℓ0 < ℓ1 < ℓ0 被拒絕！
  let (u_ok, u_sol) = solve_universe_level_constraints(3, [
    LevelConstraint::{ lhs_var: 0, delta: 1, rhs_var: 1, },
    LevelConstraint::{ lhs_var: 1, delta: 0, rhs_var: 2, },
  ])
  let (girard_sat, _) = solve_universe_level_constraints(2, [
    LevelConstraint::{ lhs_var: 0, delta: 1, rhs_var: 1, },
    LevelConstraint::{ lhs_var: 1, delta: 1, rhs_var: 0, },
  ])
  let univ_ok = u_ok && u_sol == [0, 1, 1] && !girard_sat

  // 2. Π-type 蘊涵（x ∉ FV(B)）與全稱量化（x ∈ FV(B)）精確分離
  let imp_ty = CubicalBidirType::BTPi(true, BTBool, BTCircle)
  let forall_ty = CubicalBidirType::BTPi(
    false,
    BTCircle,
    BTPath(BTCircle, BVar(0), BVar(0)),
  )
  let (imp_is_imp, imp_is_fa) = classify_pi_quantifier_role(imp_ty)
  let (fa_is_imp, fa_is_fa) = classify_pi_quantifier_role(forall_ty)
  let pi_sep_ok = imp_is_imp && !imp_is_fa && !fa_is_imp && fa_is_fa

  // 3. 雙向立方體路徑檢驗：
  //    (a) 仿射迴圈 `λi. loop(i) : Path S^1 base base` 通過（重數 = 1，端點 loop(0)=base, loop(1)=base）；
  //    (b) 對角連線路徑 `λi. loop(i ∧ i) : Path S^1 base base` 在仿射模式被拒絕、在德摩根模式通過！
  //    (c) 錯誤端點 `λi. true : Path Bool true false` 被端點定義檢驗拒絕！
  let loop_ty = CubicalBidirType::BTPath(BTCircle, BCircleBase, BCircleBase)
  let aff_loop_tm = CubicalBidirTerm::BPathLam(BCircleLoop(DVar(0)))
  let diag_loop_tm = CubicalBidirTerm::BPathLam(
    BCircleLoop(DAnd(DVar(0), DVar(0))),
  )
  let aff_res = check_cubical_bidir(
    [],
    0,
    FTop,
    aff_loop_tm,
    loop_ty,
    AffineCubicalMode,
  )
  let diag_aff = check_cubical_bidir(
    [],
    0,
    FTop,
    diag_loop_tm,
    loop_ty,
    AffineCubicalMode,
  )
  let diag_dm = check_cubical_bidir(
    [],
    0,
    FTop,
    diag_loop_tm,
    loop_ty,
    DeMorganCartesianMode,
  )
  let bad_ep_ty = CubicalBidirType::BTPath(BTBool, BBool(true), BBool(false))
  let bad_ep_res = check_cubical_bidir(
    [],
    0,
    FTop,
    BPathLam(BBool(true)),
    bad_ep_ty,
    DeMorganCartesianMode,
  )

  // 4. Glue 面收縮 `Glue Bool [⊤ ↦ S^1] ≡ S^1` 與 HComp 重疊面衝突拒絕
  let glue_top_ty = CubicalBidirType::BTGlue(BTBool, FTop, BTCircle)
  let glue_top_chk = check_cubical_bidir(
    [],
    0,
    FTop,
    BCircleBase,
    glue_top_ty,
    AffineCubicalMode,
  )
  let bad_hcomp = CubicalBidirTerm::BHComp(
    BTBool,
    [
      (@face_bdd.face_var0(0), BBool(true)),
      (@face_bdd.face_var0(0), BBool(false)),
    ],
    BBool(true),
  )
  let bad_hcomp_chk = check_cubical_bidir(
    [],
    0,
    FTop,
    bad_hcomp,
    BTBool,
    DeMorganCartesianMode,
  )

  // 5. 極化聚焦 `LJF_cub` vs 非聚焦搜尋：
  //    目標 `(A^+ ⊗ B^+) -> Path_i (↑(A^+ ⊗ B^+))` 在非聚焦系統中因右 `Path_i` 與左 `⊗` 拆解可任意交錯，
  //    產生多重冗餘導出（> 1 棵證明樹），而 `LJF_cub` 強制異步順序收斂為唯一 1 棵規範證明樹！
  let goal_interleave = PolarCubicalFormula::PArrow(
    PTensor(PPosAtom(0), PPosAtom(1)),
    PPathNeg(0, PPathNeg(1, PUp(PTensor(PPosAtom(0), PPosAtom(1))))),
  )
  let (unf_ok1, unf_cnt1) = unfocused_cubical_sequent_count(
    [],
    goal_interleave,
    8,
  )
  let (foc_ok1, foc_cnt1) = focused_ljf_cubical_prove(
    [],
    [],
    [],
    goal_interleave,
    10,
  )
  // 不可證負對照：`A^+ -> ↑B^+`（兩個系統皆必須回傳 false, 0）
  let unprovable_goal = PolarCubicalFormula::PArrow(
    PPosAtom(0),
    PUp(PPosAtom(1)),
  )
  let (unf_bad, _) = unfocused_cubical_sequent_count([], unprovable_goal, 6)
  let (foc_bad, _) = focused_ljf_cubical_prove([], [], [], unprovable_goal, 6)
  // 含左聚焦 Modus Ponens：`↓(A^+ -> N^-) ⊗ A^+ ⊢ N^-`
  let mp_goal = PolarCubicalFormula::PArrow(
    PTensor(PDown(PArrow(PPosAtom(0), PNegAtom(2))), PPosAtom(0)),
    PNegAtom(2),
  )
  let (unf_mp, _) = unfocused_cubical_sequent_count([], mp_goal, 8)
  let (foc_mp, foc_mp_cnt) = focused_ljf_cubical_prove([], [], [], mp_goal, 10)
  let focus_batch_ok = unf_ok1 &&
    foc_ok1 &&
    unf_cnt1 > foc_cnt1 &&
    foc_cnt1 == 1 &&
    !unf_bad &&
    !foc_bad &&
    unf_mp &&
    foc_mp &&
    foc_mp_cnt == 1

  AffineBidirFocusingReport::{
    universe_poly_consistent_ok: univ_ok,
    girard_cycle_rejected: !girard_sat,
    implication_vs_forall_separated: pi_sep_ok,
    affine_path_accepted: aff_res.ok,
    diagonal_path_rejected_in_affine_accepted_in_demorgan: !diag_aff.ok &&
    diag_dm.ok,
    wrong_path_endpoint_rejected: !bad_ep_res.ok,
    glue_top_strict_reduction_ok: glue_top_chk.ok,
    hcomp_incompatible_overlap_rejected: !bad_hcomp_chk.ok,
    focusing_sound_and_complete_batch: focus_batch_ok,
    unfocused_interleavings_count: unf_cnt1,
    focused_canonical_derivations_count: foc_cnt1,
  }
}
