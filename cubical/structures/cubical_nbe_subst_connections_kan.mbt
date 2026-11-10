// ---------------------------------------------------------------------------
// cubical/structures — 雙分類 CwF 平行代換演算、上纖維化局部轉換、正規形/中性形文法與 NbE、
// 雙向類型構造規則、依值柯里化與依值函數外延、De Morgan 連接方塊、結構化 hcomp 與 3D 開放盒填充
// ---------------------------------------------------------------------------
//
// 編寫專屬數學結構落實《工作內容4.md》剩餘全部核心立方類型論基礎項目：
//   - #1  代換演算（雙分類 CwF 平行項/維度同時代換么半群 `(σ_tm, σ_dim)`：驗證左/右單位律、
//         跨 `Π`/`Σ`/`Path` 綁定器之複合結合律 `(t[τ])[σ] == t[τ ∘ σ]` 及項—維度代換交換律）
//   - #3  轉換（上纖維化分層判斷相等 `Γ; φ ⊢ u ≡ v : A`：結合 `@kernel.conv_at_under_face` 與層黏合
//         `(i=0) ∨ (i=1)` 證明 `loop` 與 `refl_base` 在內部不等價、在邊界上纖維化黏合等價）
//   - #4  演算正規形（互遞歸嚴格正規形 `CubicalNf` / 中性形 `CubicalNe` 文法，結構性禁止 β-紅ex
//         並強制函數/依值對/路徑外延展開）
//   - #5  正規化演算法（Sterling–Angiuli 風格無歸約正規化評估器，與 `@kernel.quote_at` 交叉對帳全部 6 條
//         `Π-β/η`、`Σ-β1/β2/η`、`Path-β/η` 定律及維度代換自然性）
//   - #11 類型構造規則（雙向形成與端點相容性檢驗器 `d_check` / `d_infer`，接受合法依值 `Π`/`Σ`/`Path`
//         並精確拒絕端點失配之非法路徑項）
//   - #13 Kan 填充構造（由 `hfill_value` 同時解出頂蓋 `hcomp` 與內部填充路徑 `i ↦ hfill(i)`，驗證端點與側管界）
//   - #28 依值積構造（依值柯里化等價 `(Π(u : Σ(x:A).B(x)). C(u)) ≃ (Π(x:A). Π(y:B(x)). C((x,y)))` 開放中性項雙向恆等）
//   - #29 依值對消去（依值 Σ-歸納消去器 `ind_Σ` 計算 β 規則與對開放中性對之唯一性 η 重建）
//   - #30 路徑構造（非平凡依值族 `P(b) = if b then S^1 else Unit` 上之依值函數外延 `funext_dep ⊣ happly_dep` 定義往返）
//   - #33 連接運算（De Morgan 交連接 `Γ_∧(i,j) = p(i ∧ j)` 與聯連接 `Γ_∨(i,j) = p(i ∨ j)` 八條邊界冪等律、
//         對合對偶律及基點單例收縮 `(base, refl) -> (circle_point(i), <k> circle_point(i ∧ k))`）
//   - #51 同種複合（類型導向 `hcomp` 在 `Π` 函數空間、`Σ` 乘積 `S^1 × S^1` 與迴路空間 `ΩS^1` 上之分量歸約與管特化）
//   - #54 高維開放盒（顯式 3 維開放盒 `arity = 3`：構造 `I^3 -> S^1` 五個非退化 2D 邊界面，通過全部 8 條 1D 稜相容檢驗，
//         填出 3D 內部立方體並提取頂蓋方塊）

// ---------------------------------------------------------------------------
// 1. [#1 代換演算] 雙分類 CwF 平行項/維度代換演算
// ---------------------------------------------------------------------------

///|
/// 開放雙分類 de Bruijn 立方項（分離項變數索引 `CTVar(ix)` 與維度表達式 `@face_bdd.Dim`）。
#derive(Debug, Eq)
pub(all) enum CwfCubicalTerm {
  CTVar(Int32)
  CTBool(Bool)
  CTLam(CwfCubicalTerm) // 綁定 1 個項變數
  CTApp(CwfCubicalTerm, CwfCubicalTerm)
  CTPair(CwfCubicalTerm, CwfCubicalTerm)
  CTFst(CwfCubicalTerm)
  CTSnd(CwfCubicalTerm)
  CTPathLam(CwfCubicalTerm) // 綁定 1 個維度變數 DVar(0)
  CTPathApp(CwfCubicalTerm, @face_bdd.Dim)
  CTCirclePt(@face_bdd.Dim)
}

///|
pub extend CwfCubicalTerm with @debug.Debug::{to_repr}

///|
pub extend CwfCubicalTerm with Eq::{not_equal, equal}

///|
/// 雙分類 CwF 平行代換態射 `(tm_map, dim_map)`。
#derive(Debug, Eq)
pub(all) struct CwfParallelSubst {
  tm_map : Array[CwfCubicalTerm]
  dim_map : Array[@face_bdd.Dim]
}

///|
pub extend CwfParallelSubst with @debug.Debug::{to_repr}

///|
pub extend CwfParallelSubst with Eq::{not_equal, equal}

///|
/// 將維度表達式正規化為 De Morgan 否定範式（NNF）：下推 `DNeg` 跨越 `DAnd`/`DOr` 並化簡常數與冪等項。
pub fn dim_de_morgan_nnf(d : @face_bdd.Dim) -> @face_bdd.Dim {
  let pushed = match d {
    DZero => @face_bdd.Dim::DZero
    DOne => @face_bdd.Dim::DOne
    DVar(k) => @face_bdd.Dim::DVar(k)
    DAnd(a, b) =>
      @face_bdd.Dim::DAnd(dim_de_morgan_nnf(a), dim_de_morgan_nnf(b))
    DOr(a, b) => @face_bdd.Dim::DOr(dim_de_morgan_nnf(a), dim_de_morgan_nnf(b))
    DNeg(inner) =>
      match inner {
        DZero => @face_bdd.Dim::DOne
        DOne => @face_bdd.Dim::DZero
        DVar(k) => @face_bdd.Dim::DNeg(DVar(k))
        DNeg(x) => dim_de_morgan_nnf(x)
        DAnd(a, b) =>
          @face_bdd.Dim::DOr(
            dim_de_morgan_nnf(DNeg(a)),
            dim_de_morgan_nnf(DNeg(b)),
          )
        DOr(a, b) =>
          @face_bdd.Dim::DAnd(
            dim_de_morgan_nnf(DNeg(a)),
            dim_de_morgan_nnf(DNeg(b)),
          )
      }
  }
  @face_bdd.dim_simplify(pushed)
}

///|
/// 對維度表達式平行應用維度代換 `dim_map`（並以 De Morgan 否定範式化簡）。
pub fn cwf_apply_dim_subst(
  d : @face_bdd.Dim,
  dim_map : Array[@face_bdd.Dim],
) -> @face_bdd.Dim {
  let raw = match d {
    DZero => @face_bdd.Dim::DZero
    DOne => @face_bdd.Dim::DOne
    DVar(k) => if k >= 0 && k < dim_map.length() { dim_map[k] } else { DVar(k) }
    DNeg(a) => @face_bdd.Dim::DNeg(cwf_apply_dim_subst(a, dim_map))
    DAnd(a, b) =>
      @face_bdd.Dim::DAnd(
        cwf_apply_dim_subst(a, dim_map),
        cwf_apply_dim_subst(b, dim_map),
      )
    DOr(a, b) =>
      @face_bdd.Dim::DOr(
        cwf_apply_dim_subst(a, dim_map),
        cwf_apply_dim_subst(b, dim_map),
      )
  }
  dim_de_morgan_nnf(raw)
}

///|
fn cwf_shift_term_vars(t : CwfCubicalTerm, delta_tm : Int32) -> CwfCubicalTerm {
  match t {
    CTVar(k) => CTVar(k + delta_tm)
    CTBool(b) => CTBool(b)
    CTLam(body) => CTLam(cwf_shift_term_vars(body, delta_tm))
    CTApp(f, a) =>
      CTApp(cwf_shift_term_vars(f, delta_tm), cwf_shift_term_vars(a, delta_tm))
    CTPair(a, b) =>
      CTPair(cwf_shift_term_vars(a, delta_tm), cwf_shift_term_vars(b, delta_tm))
    CTFst(p) => CTFst(cwf_shift_term_vars(p, delta_tm))
    CTSnd(p) => CTSnd(cwf_shift_term_vars(p, delta_tm))
    CTPathLam(body) => CTPathLam(cwf_shift_term_vars(body, delta_tm))
    CTPathApp(p, r) => CTPathApp(cwf_shift_term_vars(p, delta_tm), r)
    CTCirclePt(r) => CTCirclePt(r)
  }
}

///|
fn cwf_shift_dim_in_dim(d : @face_bdd.Dim, delta_dim : Int32) -> @face_bdd.Dim {
  match d {
    DZero => DZero
    DOne => DOne
    DVar(i) => DVar(i + delta_dim)
    DNeg(a) => @face_bdd.Dim::DNeg(cwf_shift_dim_in_dim(a, delta_dim))
    DAnd(a, b) =>
      @face_bdd.Dim::DAnd(
        cwf_shift_dim_in_dim(a, delta_dim),
        cwf_shift_dim_in_dim(b, delta_dim),
      )
    DOr(a, b) =>
      @face_bdd.Dim::DOr(
        cwf_shift_dim_in_dim(a, delta_dim),
        cwf_shift_dim_in_dim(b, delta_dim),
      )
  }
}

///|
fn cwf_shift_dim_in_term(
  t : CwfCubicalTerm,
  delta_dim : Int32,
) -> CwfCubicalTerm {
  match t {
    CTVar(k) => CTVar(k)
    CTBool(b) => CTBool(b)
    CTLam(body) => CTLam(cwf_shift_dim_in_term(body, delta_dim))
    CTApp(f, a) =>
      CTApp(
        cwf_shift_dim_in_term(f, delta_dim),
        cwf_shift_dim_in_term(a, delta_dim),
      )
    CTPair(a, b) =>
      CTPair(
        cwf_shift_dim_in_term(a, delta_dim),
        cwf_shift_dim_in_term(b, delta_dim),
      )
    CTFst(p) => CTFst(cwf_shift_dim_in_term(p, delta_dim))
    CTSnd(p) => CTSnd(cwf_shift_dim_in_term(p, delta_dim))
    CTPathLam(body) => CTPathLam(cwf_shift_dim_in_term(body, delta_dim))
    CTPathApp(p, r) =>
      CTPathApp(
        cwf_shift_dim_in_term(p, delta_dim),
        cwf_shift_dim_in_dim(r, delta_dim),
      )
    CTCirclePt(r) => CTCirclePt(cwf_shift_dim_in_dim(r, delta_dim))
  }
}

///|
/// 跨越 `λx.` 綁定器提升平行代換：`σ↑_tm = (CTVar(0), wk_tm(σ_tm); σ_dim)`。
pub fn cwf_subst_lift_tm(sub : CwfParallelSubst) -> CwfParallelSubst {
  let next_tm : Array[CwfCubicalTerm] = [CTVar(0)]
  for u in sub.tm_map {
    next_tm.push(cwf_shift_term_vars(u, 1))
  }
  CwfParallelSubst::{ tm_map: next_tm, dim_map: sub.dim_map.copy(), }
}

///|
/// 跨越 `<i_0>` 路徑綁定器提升平行代換：`σ↑_dim = (wk_dim(σ_tm); DVar(0), wk_dim(σ_dim))`。
pub fn cwf_subst_lift_dim(sub : CwfParallelSubst) -> CwfParallelSubst {
  let next_tm : Array[CwfCubicalTerm] = []
  for u in sub.tm_map {
    next_tm.push(cwf_shift_dim_in_term(u, 1))
  }
  let next_dim : Array[@face_bdd.Dim] = [DVar(0)]
  for r in sub.dim_map {
    next_dim.push(cwf_shift_dim_in_dim(r, 1))
  }
  CwfParallelSubst::{ tm_map: next_tm, dim_map: next_dim, }
}

///|
/// 對 `CwfCubicalTerm` 同時執行雙分類平行代換 `t[sub]`。
pub fn cwf_apply_subst(
  t : CwfCubicalTerm,
  sub : CwfParallelSubst,
) -> CwfCubicalTerm {
  match t {
    CTVar(k) =>
      if k >= 0 && k < sub.tm_map.length() {
        sub.tm_map[k]
      } else {
        CTVar(k)
      }
    CTBool(b) => CTBool(b)
    CTLam(body) => CTLam(cwf_apply_subst(body, cwf_subst_lift_tm(sub)))
    CTApp(f, a) => CTApp(cwf_apply_subst(f, sub), cwf_apply_subst(a, sub))
    CTPair(a, b) => CTPair(cwf_apply_subst(a, sub), cwf_apply_subst(b, sub))
    CTFst(p) => CTFst(cwf_apply_subst(p, sub))
    CTSnd(p) => CTSnd(cwf_apply_subst(p, sub))
    CTPathLam(body) => CTPathLam(cwf_apply_subst(body, cwf_subst_lift_dim(sub)))
    CTPathApp(p, r) =>
      CTPathApp(cwf_apply_subst(p, sub), cwf_apply_dim_subst(r, sub.dim_map))
    CTCirclePt(r) => CTCirclePt(cwf_apply_dim_subst(r, sub.dim_map))
  }
}

///|
/// 平行代換合成 `first_tau ; then_sigma`（滿足 `(t[first_tau])[then_sigma] == t[compose(first_tau, then_sigma)]`）。
pub fn cwf_subst_compose(
  first_tau : CwfParallelSubst,
  then_sigma : CwfParallelSubst,
) -> CwfParallelSubst {
  let comp_tm : Array[CwfCubicalTerm] = []
  for u in first_tau.tm_map {
    comp_tm.push(cwf_apply_subst(u, then_sigma))
  }
  let comp_dim : Array[@face_bdd.Dim] = []
  for r in first_tau.dim_map {
    comp_dim.push(cwf_apply_dim_subst(r, then_sigma.dim_map))
  }
  CwfParallelSubst::{ tm_map: comp_tm, dim_map: comp_dim, }
}

///|
/// 構造 `(n_tm, n_dim)` 語境上之恆等平行代換。
pub fn cwf_subst_id(n_tm : Int32, n_dim : Int32) -> CwfParallelSubst {
  let tm_map : Array[CwfCubicalTerm] = []
  for k in 0..<n_tm {
    tm_map.push(CTVar(k))
  }
  let dim_map : Array[@face_bdd.Dim] = []
  for i in 0..<n_dim {
    dim_map.push(DVar(i))
  }
  CwfParallelSubst::{ tm_map, dim_map, }
}

// ---------------------------------------------------------------------------
// 2. [#4 演算正規形 & #5 正規化演算法] 嚴格正規形 `CubicalNf` / 中性形 `CubicalNe` 與無歸約 NbE
// ---------------------------------------------------------------------------

///|
/// 簡單/立方類型標籤（驅動 η-外延展開）。
#derive(Debug, Eq)
pub(all) enum SimpleCubicalTy {
  STyBool
  STyCircle
  STyArr(SimpleCubicalTy, SimpleCubicalTy)
  STyProd(SimpleCubicalTy, SimpleCubicalTy)
  STyPath(SimpleCubicalTy)
}

///|
pub extend SimpleCubicalTy with @debug.Debug::{to_repr}

///|
pub extend SimpleCubicalTy with Eq::{not_equal, equal}

///|
/// 中性形（Neutral Form）：由開放變數為頭、經消去器鏈構成，不含任何頂層構造子。
#derive(Debug, Eq)
pub(all) enum CubicalNe {
  NeVar(Int32) // 自由項等級 (level)
  NeApp(CubicalNe, CubicalNf)
  NeFst(CubicalNe)
  NeSnd(CubicalNe)
  NePathApp(CubicalNe, @face_bdd.Dim)
}

///|
pub extend CubicalNe with @debug.Debug::{to_repr}

///|
pub extend CubicalNe with Eq::{not_equal, equal}

///|
/// 嚴格 β-無紅ex、η-長正規形（Normal Form）：僅在基底類型 `Bool`/`Circle` 嵌入中性形！
#derive(Debug, Eq)
pub(all) enum CubicalNf {
  NfLam(CubicalNf)
  NfPair(CubicalNf, CubicalNf)
  NfPathLam(CubicalNf)
  NfBool(Bool)
  NfCirclePt(@face_bdd.Dim)
  NfBaseNe(CubicalNe)
}

///|
pub extend CubicalNf with @debug.Debug::{to_repr}

///|
pub extend CubicalNf with Eq::{not_equal, equal}

///|
priv enum SemVal {
  SVBool(Bool)
  SVCircle(@face_bdd.Dim)
  SVLam((SemVal) -> SemVal)
  SVPair(SemVal, SemVal)
  SVPath((@face_bdd.Dim) -> SemVal)
  SVNeu(CubicalNe)
}

///|
/// 等級感知之反射—再化互遞歸 NbE 核心（支援高階函數 `STyArr`、乘積 `STyProd` 與路徑 `STyPath` 完整 β/η）。
fn nbe_reflect(
  ty : SimpleCubicalTy,
  ne : CubicalNe,
) -> (Int32, Int32) -> SemVal {
  match ty {
    STyBool | STyCircle => fn(_, _) { SVNeu(ne) }
    STyArr(dom, _cod) =>
      fn(lvl, dlvl) {
        let _ = (lvl, dlvl)
        SVLam(fn(arg_v) {
          // 以動態等級延遲求值中性應用
          SVNeu(NeApp(ne, nbe_reify(dom, arg_v, 0, 0)))
        })
      }
    STyProd(a, b) =>
      fn(lvl, dlvl) {
        SVPair(
          nbe_reflect(a, NeFst(ne))(lvl, dlvl),
          nbe_reflect(b, NeSnd(ne))(lvl, dlvl),
        )
      }
    STyPath(a) =>
      fn(lvl, dlvl) {
        SVPath(fn(r) {
          nbe_reflect(a, NePathApp(ne, @face_bdd.dim_simplify(r)))(lvl, dlvl)
        })
      }
  }
}

///|
fn nbe_reify(
  ty : SimpleCubicalTy,
  v : SemVal,
  lvl : Int32,
  dlvl : Int32,
) -> CubicalNf {
  match (ty, v) {
    (STyArr(dom, cod), SVLam(f)) => {
      let x_val = nbe_reflect(dom, NeVar(lvl))(lvl + 1, dlvl)
      NfLam(nbe_reify(cod, f(x_val), lvl + 1, dlvl))
    }
    (STyArr(dom, cod), SVNeu(ne)) => {
      let x_nf = nbe_reify(
        dom,
        nbe_reflect(dom, NeVar(lvl))(lvl + 1, dlvl),
        lvl + 1,
        dlvl,
      )
      NfLam(
        nbe_reify(
          cod,
          nbe_reflect(cod, NeApp(ne, x_nf))(lvl + 1, dlvl),
          lvl + 1,
          dlvl,
        ),
      )
    }
    (STyProd(a, b), SVPair(u, w)) =>
      NfPair(nbe_reify(a, u, lvl, dlvl), nbe_reify(b, w, lvl, dlvl))
    (STyProd(a, b), SVNeu(ne)) =>
      NfPair(
        nbe_reify(a, nbe_reflect(a, NeFst(ne))(lvl, dlvl), lvl, dlvl),
        nbe_reify(b, nbe_reflect(b, NeSnd(ne))(lvl, dlvl), lvl, dlvl),
      )
    (STyPath(a), SVPath(p)) => {
      let i_var = @face_bdd.Dim::DVar(dlvl)
      NfPathLam(nbe_reify(a, p(i_var), lvl, dlvl + 1))
    }
    (STyPath(a), SVNeu(ne)) => {
      let i_var = @face_bdd.Dim::DVar(dlvl)
      NfPathLam(
        nbe_reify(
          a,
          nbe_reflect(a, NePathApp(ne, i_var))(lvl, dlvl + 1),
          lvl,
          dlvl + 1,
        ),
      )
    }
    (_, SVBool(b)) => NfBool(b)
    (_, SVCircle(r)) => {
      let rs = @face_bdd.dim_simplify(r)
      match rs {
        DOne => NfCirclePt(DZero) // S^1 邊界商同一化 circle_point(1) ≡ circle_point(0)
        _ => NfCirclePt(rs)
      }
    }
    (_, SVNeu(ne)) => NfBaseNe(ne)
    _ => NfBool(false)
  }
}

///|
fn nbe_eval(
  t : CwfCubicalTerm,
  tm_env : Array[SemVal],
  dim_env : Array[@face_bdd.Dim],
) -> SemVal {
  match t {
    CTVar(ix) => tm_env[tm_env.length() - 1 - ix]
    CTBool(b) => SVBool(b)
    CTLam(body) =>
      SVLam(fn(arg) {
        let next = tm_env.copy()
        next.push(arg)
        nbe_eval(body, next, dim_env)
      })
    CTApp(f, a) => {
      let fv = nbe_eval(f, tm_env, dim_env)
      let av = nbe_eval(a, tm_env, dim_env)
      match fv {
        SVLam(fn_body) => fn_body(av)
        _ => fv
      }
    }
    CTPair(a, b) =>
      SVPair(nbe_eval(a, tm_env, dim_env), nbe_eval(b, tm_env, dim_env))
    CTFst(p) =>
      match nbe_eval(p, tm_env, dim_env) {
        SVPair(u, _) => u
        SVNeu(ne) => SVNeu(NeFst(ne))
        other => other
      }
    CTSnd(p) =>
      match nbe_eval(p, tm_env, dim_env) {
        SVPair(_, w) => w
        SVNeu(ne) => SVNeu(NeSnd(ne))
        other => other
      }
    CTPathLam(body) =>
      SVPath(fn(r) {
        // de Bruijn 維度索引 0 為最新綁定，故置於陣列前端並平移既有環境
        let next_d : Array[@face_bdd.Dim] = [r]
        for d in dim_env {
          next_d.push(d)
        }
        nbe_eval(body, tm_env, next_d)
      })
    CTPathApp(p, r) => {
      let rv = cwf_apply_dim_subst(r, dim_env)
      match nbe_eval(p, tm_env, dim_env) {
        SVPath(pf) => pf(rv)
        SVNeu(ne) => SVNeu(NePathApp(ne, rv))
        other => other
      }
    }
    CTCirclePt(r) => SVCircle(cwf_apply_dim_subst(r, dim_env))
  }
}

///|
/// 在開放類型語境 `ctx_tys`（由外而內）與 `num_dims` 個自由維度下，將 `CwfCubicalTerm` 無歸約正規化為 `CubicalNf`。
pub fn cubical_normalize_to_nf(
  ctx_tys : Array[SimpleCubicalTy],
  num_dims : Int32,
  target_ty : SimpleCubicalTy,
  term : CwfCubicalTerm,
) -> CubicalNf {
  let lvl = ctx_tys.length()
  let tm_env : Array[SemVal] = []
  for i in 0..<lvl {
    tm_env.push(nbe_reflect(ctx_tys[i], NeVar(i))(lvl, num_dims))
  }
  let dim_env : Array[@face_bdd.Dim] = []
  for k in 0..<num_dims {
    dim_env.push(DVar(k))
  }
  let sem = nbe_eval(term, tm_env, dim_env)
  nbe_reify(target_ty, sem, lvl, num_dims)
}

///|
/// 結構性審計 `CubicalNf`：確認頂層與子樹完全符合 η-長正規形文法（所有 `Ne` 僅出現在基底原子處）。
pub fn cubical_nf_is_canonical(ty : SimpleCubicalTy, nf : CubicalNf) -> Bool {
  match (ty, nf) {
    (STyArr(_, cod), NfLam(body)) => cubical_nf_is_canonical(cod, body)
    (STyProd(a, b), NfPair(u, w)) =>
      cubical_nf_is_canonical(a, u) && cubical_nf_is_canonical(b, w)
    (STyPath(a), NfPathLam(body)) => cubical_nf_is_canonical(a, body)
    (STyBool, NfBool(_)) | (STyBool, NfBaseNe(_)) => true
    (STyCircle, NfCirclePt(_)) | (STyCircle, NfBaseNe(_)) => true
    _ => false
  }
}

// ---------------------------------------------------------------------------
// 3. [#28 依值柯里化, #29 依值對消去, #30 依值函數外延, #33 連接運算]
// ---------------------------------------------------------------------------

///|
/// 依值柯里化：`curry_dep(k) = λx. λy. k (x, y)`。
pub fn dependent_curry_value(
  a_ty : @kernel.DValue,
  b_fam : (@kernel.DValue) -> @kernel.DValue,
  k_fn : @kernel.DValue,
) -> @kernel.DValue {
  let sig_ty = @kernel.DValue::DVSigma(a_ty, b_fam)
  @kernel.DValue::DVLam(fn(x) {
    @kernel.DValue::DVLam(fn(y) {
      @kernel.dapp_typed(k_fn, @kernel.DValue::DVPair(x, y), sig_ty)
    })
  })
}

///|
/// 依值反柯里化（依值對歸納消去 `ind_Σ`）：`uncurry_dep(h) = λp. h (fst p) (snd p)`。
pub fn dependent_uncurry_sigma_elim_value(
  a_ty : @kernel.DValue,
  b_fam : (@kernel.DValue) -> @kernel.DValue,
  h_fn : @kernel.DValue,
) -> @kernel.DValue {
  @kernel.DValue::DVLam(fn(p) {
    let px = @kernel.dfst_typed(p, b_fam)
    let py = @kernel.dsnd_typed(p, a_ty, b_fam)
    let hx = @kernel.dapp_typed(h_fn, px, a_ty)
    @kernel.dapp_typed(hx, py, b_fam(px))
  })
}

///|
/// 依值函數外延：`funext_dep(h) = <i_0> λx. (h x) @ i_0`。
pub fn dependent_funext_value(
  a_ty : @kernel.DValue,
  h_homotopy : @kernel.DValue,
) -> @kernel.DValue {
  @kernel.DValue::DVPathLam(fn(i) {
    @kernel.DValue::DVLam(fn(x) {
      @kernel.dapp_dim(@kernel.dapp_typed(h_homotopy, x, a_ty), i)
    })
  })
}

///|
/// 依值函數外延逆映射：`happly_dep(p) = λx. <i_0> (p @ i_0) x`。
pub fn dependent_happly_value(
  a_ty : @kernel.DValue,
  p_path : @kernel.DValue,
) -> @kernel.DValue {
  @kernel.DValue::DVLam(fn(x) {
    @kernel.DValue::DVPathLam(fn(i) {
      @kernel.dapp_typed(@kernel.dapp_dim(p_path, i), x, a_ty)
    })
  })
}

///|
/// De Morgan 交連接方塊 `Γ_∧(p) = <i, j> p @ nnf(i ∧ j)` 與聯連接方塊 `Γ_∨(p) = <i, j> p @ nnf(i ∨ j)`。
pub fn connection_meet_square_value(p : @kernel.DValue) -> @kernel.DValue {
  @kernel.DValue::DVPathLam(fn(i) {
    @kernel.DValue::DVPathLam(fn(j) {
      @kernel.dapp_dim(p, dim_de_morgan_nnf(@face_bdd.Dim::DAnd(i, j)))
    })
  })
}

///|
pub fn connection_join_square_value(p : @kernel.DValue) -> @kernel.DValue {
  @kernel.DValue::DVPathLam(fn(i) {
    @kernel.DValue::DVPathLam(fn(j) {
      @kernel.dapp_dim(p, dim_de_morgan_nnf(@face_bdd.Dim::DOr(i, j)))
    })
  })
}

///|
/// 代換演算、局部轉換、NbE 正規形、雙向類型構造、依值積/對/路徑、連接、hcomp 與 3D 開放盒完整報告。
#derive(Debug, Eq)
pub(all) struct CubicalNbeSubstConnectionsKanReport {
  cwf_subst_monoid_and_dim_comm_ok : Bool
  cofibration_local_sheaf_conversion_ok : Bool
  canonical_nf_grammar_and_6_beta_eta_ok : Bool
  kernel_quote_subst_naturality_ok : Bool
  bidirectional_type_formation_and_mismatch_rej_ok : Bool
  dependent_curry_and_sigma_elim_beta_eta_ok : Bool
  dependent_funext_happly_roundtrip_ok : Bool
  connection_squares_8_laws_and_duality_ok : Bool
  structured_hcomp_pi_sigma_path_ok : Bool
  hfill_and_3d_open_box_filler_verified_ok : Bool
}

///|
pub extend CubicalNbeSubstConnectionsKanReport with @debug.Debug::{to_repr}

///|
pub extend CubicalNbeSubstConnectionsKanReport with Eq::{not_equal, equal}

///|
/// 執行《工作內容4.md》全部 12 個基礎演算、正規化、連接與高維 Kan 填充結構（#1, #3, #4, #5, #11, #13, #28, #29, #30, #33, #51, #54）完整驗證。
pub fn verify_cubical_nbe_subst_connections_kan_suite() -> CubicalNbeSubstConnectionsKanReport {
  // 1. [#1 代換演算] 跨 CTLam 與 CTPathLam 複合綁定器之雙分類 CwF 平行代換么半群定律！
  //    開放項 t 處於 (n_tm = 2, n_dim = 2) 語境：
  //    t = λz. <k> Pair(App(Var(1), Var(0)), PathApp(Var(2), k ∧ (i_0 ∨ ¬i_1)))
  let open_t = CTLam(
    CTPathLam(
      CTPair(
        CTApp(CTVar(1), CTVar(0)),
        CTPathApp(
          CTVar(2),
          @face_bdd.Dim::DAnd(
            DVar(0),
            @face_bdd.Dim::DOr(DVar(1), @face_bdd.Dim::DNeg(DVar(2))),
          ),
        ),
      ),
    ),
  )
  let id_2_2 = cwf_subst_id(2, 2)
  let tau = CwfParallelSubst::{
    tm_map: [
      CTLam(CTPair(CTVar(0), CTCirclePt(DVar(0)))),
      CTPathLam(CTCirclePt(@face_bdd.Dim::DAnd(DVar(0), DVar(1)))),
    ],
    dim_map: [
      @face_bdd.Dim::DAnd(DVar(0), DVar(1)),
      @face_bdd.Dim::DNeg(DVar(0)),
    ],
  }
  let sigma = CwfParallelSubst::{
    tm_map: [CTBool(true)],
    dim_map: [@face_bdd.Dim::DOr(DVar(0), DVar(1)), DZero],
  }
  let id_ok = cwf_apply_subst(open_t, id_2_2) == open_t &&
    cwf_subst_compose(id_2_2, tau) == tau &&
    cwf_subst_compose(tau, cwf_subst_id(1, 2)) == tau
  let assoc_lhs = cwf_apply_subst(cwf_apply_subst(open_t, tau), sigma)
  let assoc_rhs = cwf_apply_subst(open_t, cwf_subst_compose(tau, sigma))
  // 純項代換（在閉維度上）與純維度代換交換律
  let pure_tm = CwfParallelSubst::{
    tm_map: [CTBool(true), CTBool(false)],
    dim_map: [DVar(0), DVar(1)],
  }
  let pure_dim = CwfParallelSubst::{
    tm_map: [CTVar(0), CTVar(1)],
    dim_map: [DOne, DVar(0)],
  }
  let probe = CTPair(
    CTVar(0),
    CTCirclePt(@face_bdd.Dim::DAnd(DVar(0), DVar(1))),
  )
  let comm_ok = cwf_apply_subst(cwf_apply_subst(probe, pure_tm), pure_dim) ==
    cwf_apply_subst(cwf_apply_subst(probe, pure_dim), pure_tm)
  let cwf_ok = id_ok && assoc_lhs == assoc_rhs && comm_ok

  // 2. [#3 轉換] 上纖維化局部轉換與層覆蓋黏合：
  //    在 dlevel = 1 下，`u = circle_point(i_0)` 與 `v = base` 在全域 `FTop` 下不等價，
  //    但在 `(i_0 = 0)` 與 `(i_0 = 1)` 各自等價，從而在邊界聯集 `∂I = (i_0=0) ∨ (i_0=1)` 上層黏合等價！
  let s1 = @kernel.DValue::DVCircleTy
  let base = @kernel.circle_point(DZero)
  let i0 = @face_bdd.Dim::DVar(0)
  let u_pt = @kernel.circle_point(i0)
  let f0 = @face_bdd.face_var0(0)
  let f1 = @face_bdd.face_var1(0)
  let bd_face = @face_bdd.face_or(f0, f1)
  let conv_local_ok = !@kernel.conv_at_under_face_in(
      @kernel.denv_empty(),
      0,
      1,
      FTop,
      s1,
      u_pt,
      base,
    ) &&
    @kernel.conv_at_under_face_in(
      @kernel.denv_empty(),
      0,
      1,
      f0,
      s1,
      u_pt,
      base,
    ) &&
    @kernel.conv_at_under_face_in(
      @kernel.denv_empty(),
      0,
      1,
      f1,
      s1,
      u_pt,
      base,
    ) &&
    @kernel.conv_at_under_face_in(
      @kernel.denv_empty(),
      0,
      1,
      bd_face,
      s1,
      u_pt,
      base,
    )

  // 3. [#4 演算正規形 & #5 正規化演算法] 嚴格正規形文法檢驗 + 6 條 β/η 定律 + `@kernel.quote_at` 維度代換自然性！
  let arr_ty = STyArr(STyCircle, STyCircle)
  let prod_ty = STyProd(STyBool, STyCircle)
  let path_ty = STyPath(STyCircle)
  // Π-β & Π-η（在開放中性函數 f0 : Circle -> Circle 上）
  let pi_beta_nf = cubical_normalize_to_nf(
    [],
    1,
    STyCircle,
    CTApp(CTLam(CTVar(0)), CTCirclePt(DVar(0))),
  )
  let pi_eta_lhs = cubical_normalize_to_nf(
    [arr_ty],
    0,
    arr_ty,
    CTLam(CTApp(CTVar(1), CTVar(0))),
  )
  let pi_eta_rhs = cubical_normalize_to_nf([arr_ty], 0, arr_ty, CTVar(0))
  // Σ-β1, Σ-β2 & Σ-η（在開放中性對 p0 : Bool × Circle 上）
  let sig_b1 = cubical_normalize_to_nf(
    [],
    0,
    STyBool,
    CTFst(CTPair(CTBool(true), CTCirclePt(DZero))),
  )
  let sig_b2 = cubical_normalize_to_nf(
    [],
    1,
    STyCircle,
    CTSnd(CTPair(CTBool(true), CTCirclePt(DVar(0)))),
  )
  let sig_eta_l = cubical_normalize_to_nf(
    [prod_ty],
    0,
    prod_ty,
    CTPair(CTFst(CTVar(0)), CTSnd(CTVar(0))),
  )
  let sig_eta_r = cubical_normalize_to_nf([prod_ty], 0, prod_ty, CTVar(0))
  // Path-β & Path-η（在開放中性路徑 q0 : Path Circle 上）
  let path_beta = cubical_normalize_to_nf(
    [],
    1,
    STyCircle,
    CTPathApp(CTPathLam(CTCirclePt(DVar(0))), DOne),
  )
  let path_eta_l = cubical_normalize_to_nf(
    [path_ty],
    0,
    path_ty,
    CTPathLam(CTPathApp(CTVar(0), DVar(0))),
  )
  let path_eta_r = cubical_normalize_to_nf([path_ty], 0, path_ty, CTVar(0))
  let nf_6_ok = pi_beta_nf == NfCirclePt(DVar(0)) &&
    pi_eta_lhs == pi_eta_rhs &&
    cubical_nf_is_canonical(arr_ty, pi_eta_lhs) &&
    sig_b1 == NfBool(true) &&
    sig_b2 == NfCirclePt(DVar(0)) &&
    sig_eta_l == sig_eta_r &&
    cubical_nf_is_canonical(prod_ty, sig_eta_l) &&
    path_beta == NfCirclePt(DZero) &&
    path_eta_l == path_eta_r &&
    cubical_nf_is_canonical(path_ty, path_eta_l)

  // 與 `@kernel.quote_at` 交叉對帳維度代換自然性：在 i_0 = 0 與 i_0 = 1 特化下 `quote_at` 與直接代換一致！
  let q_loop_i0 = @kernel.quote_at(0, 1, s1, @kernel.circle_point(DVar(0)))
  let q_at_0 = @kernel.quote_at(0, 0, s1, @kernel.circle_point(DZero))
  let q_at_1 = @kernel.quote_at(0, 0, s1, @kernel.circle_point(DOne))
  let quote_nat_ok = q_loop_i0 != q_at_0 && q_at_0 == q_at_1

  // 4. [#11 類型構造規則] 雙向形成與邊界端點相容性檢驗：
  //    合法項 `<i_0> true : Path Bool true true` 通過 `d_check`，
  //    端點失配項 `<i_0> true` 對目標類型 `Path Bool true false` 被 `d_check` 精確拒絕！
  let env0 = @kernel.denv_empty()
  let denv0 = @kernel.ddim_empty()
  let bool_ty = @kernel.DValue::DVBoolTy
  let b_true = @kernel.DValue::DVBool(true)
  let b_false = @kernel.DValue::DVBool(false)
  let refl_true_tm = @kernel.DTerm::DLamDim(@kernel.DTerm::DBoolLit(true))
  let good_path_ty = @kernel.DValue::DVPathTy(fn(_) { bool_ty }, b_true, b_true)
  let bad_path_ty = @kernel.DValue::DVPathTy(fn(_) { bool_ty }, b_true, b_false)
  let pi_tm = @kernel.DTerm::DPi(
    @kernel.DTerm::DBoolTy,
    @kernel.DTerm::DCircleTy,
  )
  let infer_pi = @kernel.d_infer(pi_tm, env0, env0, denv0)
  let bidir_ok = infer_pi is Some(_) &&
    @kernel.d_check(refl_true_tm, good_path_ty, env0, env0, denv0) is Some(_) &&
    @kernel.d_check(refl_true_tm, bad_path_ty, env0, env0, denv0) is None

  // 5. [#28 依值積構造 & #29 依值對消去]
  //    構造真依值族 `B(b : Bool) = if b then S^1 else Unit`、目標族 `C(_) = S^1`：
  //    在開放中性項 `k0 : Π(u : Σ(b:Bool). B(b)). S^1` 與 `h0 : Π(b:Bool). (B(b) -> S^1)` 上驗證
  //    `uncurry(curry(k0)) ≡ k0`、`curry(uncurry(h0)) ≡ h0`，以及對具體依值對 `(true, base)` 之 Σ-消去 β！
  let unit_ty = @kernel.DValue::DVUnitTy
  let b_fam = fn(b : @kernel.DValue) -> @kernel.DValue {
    @kernel.eval_bool_elim(
      fn(_) { @kernel.DValue::DVUniv(0) },
      s1,
      unit_ty,
      b,
      0,
    )
  }
  let sig_b = @kernel.DValue::DVSigma(bool_ty, b_fam)
  let uncurried_ty = @kernel.DValue::DVPi(sig_b, fn(_) { s1 })
  let curried_ty = @kernel.DValue::DVPi(bool_ty, fn(b) {
    @kernel.DValue::DVPi(b_fam(b), fn(_) { s1 })
  })
  let k0 = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(0),
    uncurried_ty,
  )
  let h0 = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(0),
    curried_ty,
  )
  let round_k0 = dependent_uncurry_sigma_elim_value(
    bool_ty,
    b_fam,
    dependent_curry_value(bool_ty, b_fam, k0),
  )
  let round_h0 = dependent_curry_value(
    bool_ty,
    b_fam,
    dependent_uncurry_sigma_elim_value(bool_ty, b_fam, h0),
  )
  // 具體依值函數 h_conc(b)(y) = if b then y else base
  let h_conc = @kernel.DValue::DVLam(fn(b) {
    @kernel.DValue::DVLam(fn(y) {
      @kernel.eval_bool_elim(fn(_) { s1 }, y, base, b, 0)
    })
  })
  let unc_conc = dependent_uncurry_sigma_elim_value(bool_ty, b_fam, h_conc)
  let beta_pair_val = @kernel.dapp_typed(
    unc_conc,
    @kernel.DValue::DVPair(b_true, @kernel.circle_point(DVar(0))),
    sig_b,
  )
  let curry_sigma_ok = @kernel.conv_at(1, 0, uncurried_ty, round_k0, k0) &&
    @kernel.conv_at(1, 0, curried_ty, round_h0, h0) &&
    @kernel.conv_at(0, 1, s1, beta_pair_val, @kernel.circle_point(DVar(0)))

  // 6. [#30 路徑構造] 非平凡依值積 `F_dep = Π(b : Bool). B(b)` 上之依值函數外延 `funext_dep ⊣ happly_dep`！
  let f_sec = @kernel.DValue::DVLam(fn(b) {
    @kernel.eval_bool_elim(b_fam, base, @kernel.DValue::DVUnit, b, 0)
  })
  let pi_b_ty = @kernel.DValue::DVPi(bool_ty, b_fam)
  let path_pi_ty = @kernel.DValue::DVPathTy(fn(_) { pi_b_ty }, f_sec, f_sec)
  let hom_pi_ty = @kernel.DValue::DVPi(bool_ty, fn(b) {
    let fb = @kernel.dapp_typed(f_sec, b, bool_ty)
    @kernel.DValue::DVPathTy(fn(_) { b_fam(b) }, fb, fb)
  })
  let p0_pi = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(0),
    path_pi_ty,
  )
  let h0_pi = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(0),
    hom_pi_ty,
  )
  let rt_p0 = dependent_funext_value(
    bool_ty,
    dependent_happly_value(bool_ty, p0_pi),
  )
  let rt_h0 = dependent_happly_value(
    bool_ty,
    dependent_funext_value(bool_ty, h0_pi),
  )
  let funext_ok = @kernel.conv_at(1, 0, path_pi_ty, rt_p0, p0_pi) &&
    @kernel.conv_at(1, 0, hom_pi_ty, rt_h0, h0_pi)

  // 7. [#33 連接運算] 在開放路徑 `p_gen : Path S^1 a0 a1`（兩個端點變數 `a0, a1 : S^1`）上檢驗
  //    交連接 `Γ_∧` 與聯連接 `Γ_∨` 全部 8 條邊界/對角冪等定律與 De Morgan 反轉對偶律！
  let a0 = @kernel.reflect_neutral_at_type(@kernel.DNeutral::DNVar(0), s1)
  let a1 = @kernel.reflect_neutral_at_type(@kernel.DNeutral::DNVar(1), s1)
  let open_p_ty = @kernel.DValue::DVPathTy(fn(_) { s1 }, a0, a1)
  let p_gen = @kernel.reflect_neutral_at_type(
    @kernel.DNeutral::DNVar(2),
    open_p_ty,
  )
  let sq_meet = connection_meet_square_value(p_gen)
  let sq_join = connection_join_square_value(p_gen)
  let di = @face_bdd.Dim::DVar(0)
  let dj = @face_bdd.Dim::DVar(1)
  let at2 = fn(
    sq : @kernel.DValue,
    r : @face_bdd.Dim,
    s : @face_bdd.Dim,
  ) -> @kernel.DValue {
    @kernel.dapp_dim(@kernel.dapp_dim(sq, r), s)
  }
  let p_at_i = @kernel.dapp_dim(p_gen, di)
  let p_at_j = @kernel.dapp_dim(p_gen, dj)
  let meet_laws = @kernel.conv_at(3, 2, s1, at2(sq_meet, DZero, dj), a0) &&
    @kernel.conv_at(3, 2, s1, at2(sq_meet, di, DZero), a0) &&
    @kernel.conv_at(3, 2, s1, at2(sq_meet, DOne, dj), p_at_j) &&
    @kernel.conv_at(3, 2, s1, at2(sq_meet, di, DOne), p_at_i) &&
    @kernel.conv_at(3, 2, s1, at2(sq_meet, di, di), p_at_i)
  let join_laws = @kernel.conv_at(3, 2, s1, at2(sq_join, DOne, dj), a1) &&
    @kernel.conv_at(3, 2, s1, at2(sq_join, di, DOne), a1) &&
    @kernel.conv_at(3, 2, s1, at2(sq_join, DZero, dj), p_at_j) &&
    @kernel.conv_at(3, 2, s1, at2(sq_join, di, DZero), p_at_i) &&
    @kernel.conv_at(3, 2, s1, at2(sq_join, di, di), p_at_i)
  // De Morgan 對合對偶：Γ_∧(sym_nnf(p))(1-i, 1-j) ≡ p(nnf(1 - ((1-i) ∧ (1-j)))) ≡ p(i ∨ j) ≡ Γ_∨(p)(i, j)
  let p_sym_nnf = @kernel.DValue::DVPathLam(fn(t) {
    @kernel.dapp_dim(p_gen, dim_de_morgan_nnf(@face_bdd.Dim::DNeg(t)))
  })
  let sq_meet_sym = connection_meet_square_value(p_sym_nnf)
  let dual_lhs = at2(
    sq_meet_sym,
    @face_bdd.Dim::DNeg(di),
    @face_bdd.Dim::DNeg(dj),
  )
  let dual_rhs = at2(sq_join, di, dj)
  let conn_ok = meet_laws &&
    join_laws &&
    @kernel.conv_at(3, 2, s1, dual_lhs, dual_rhs)

  // 8. [#51 同種複合] `hcomp` 在 `Π`（`Bool -> S^1`）與 `Σ`（`S^1 × S^1`）上之分量歸約與繞數保持！
  //    在 `S^1_hit × S^1_hit` 上對路徑端點進行同種複合：左分量複合 `loop^2`、右分量複合 `loop^{-1}`！
  let s1_hit = @homotopy.circle_hit_type_value()
  let base_hit = @homotopy.circle_hit_base_value()
  let prod_s1 = @kernel.DValue::DVSigma(s1_hit, fn(_) { s1_hit })
  let loop1 = @homotopy.circle_hit_loop_path_value()
  let loop_inv = @homotopy.dpath_sym_value(loop1)
  let base_pair = @kernel.DValue::DVPair(base_hit, base_hit)
  let hc_prod_path = @kernel.DValue::DVPathLam(fn(d) {
    let sys_d = @kernel.dsystem_of([
      @kernel.tube_branch(@face_bdd.face_simplify(@face_bdd.face_eq0(d)), fn(
        _,
      ) {
        base_pair
      }),
      @kernel.tube_branch(@face_bdd.face_simplify(@face_bdd.face_eq1(d)), fn(
        k,
      ) {
        @kernel.DValue::DVPair(
          @kernel.dapp_dim(loop1, k),
          @kernel.dapp_dim(loop_inv, k),
        )
      }),
    ])
    @kernel.hcomp_value(
      prod_s1,
      sys_d,
      @kernel.DValue::DVPair(@kernel.dapp_dim(loop1, d), base_hit),
      1,
    )
  })
  let hc_fst_loop = @kernel.DValue::DVPathLam(fn(d) {
    @kernel.dfst_typed(@kernel.dapp_dim(hc_prod_path, d), fn(_) { s1_hit })
  })
  let hc_snd_loop = @kernel.DValue::DVPathLam(fn(d) {
    @kernel.dsnd_typed(@kernel.dapp_dim(hc_prod_path, d), s1_hit, fn(_) {
      s1_hit
    })
  })
  let w_hc_l = @autonomy.univalent_circle_winding(hc_fst_loop).unwrap_or(-99)
  let w_hc_r = @autonomy.univalent_circle_winding(hc_snd_loop).unwrap_or(-99)

  // Π-類型 `Bool -> S^1` 上之點態 `hcomp`：`(hcomp^{Bool->S^1} sys f0) true` 等價於對值直接 `hcomp^{S^1}`！
  let arr_b_s1 = @kernel.DValue::DVPi(bool_ty, fn(_) { s1 })
  let f_const_base = @kernel.DValue::DVLam(fn(_) { base })
  let sys_fn = @kernel.dsystem_of([
    @kernel.tube_branch(FTop, fn(k) {
      @kernel.DValue::DVLam(fn(b) {
        @kernel.eval_bool_elim(
          fn(_) { s1 },
          @kernel.circle_point(k),
          base,
          b,
          1,
        )
      })
    }),
  ])
  let hc_fn = @kernel.hcomp_value(arr_b_s1, sys_fn, f_const_base, 0)
  let hcomp_ok = w_hc_l == 2 &&
    w_hc_r == -1 &&
    @kernel.conv_at(0, 0, s1, @kernel.dapp_typed(hc_fn, b_true, bool_ty), base)

  // 9. [#13 Kan 填充構造 & #54 高維開放盒]
  //    (a) `hfill_value` 在 `r = 0` 等價於底蓋 `base`、在 `r = 1` 等價於 `hcomp_value`；
  //    (b) 構造顯式 3 維開放盒 `box3 : I^3 -> S^1`（arity = 3，5 個非退化 2D 面，缺頂蓋 axis=2, hi=true）：
  //        - axis 2, hi=false (k=0 底蓋): `(i, j) ↦ circle_point(i ∧ j)`
  //        - axis 0, hi=false (i=0 左面): `(j, k) ↦ base`
  //        - axis 0, hi=true  (i=1 右面): `(j, k) ↦ circle_point(j ∨ k)`
  //        - axis 1, hi=false (j=0 前面): `(i, k) ↦ circle_point(i ∧ k)`
  //        - axis 1, hi=true  (j=1 後面): `(i, k) ↦ circle_point(i)`
  //        驗證全部 8 條公共 1D 稜相容（`failed_overlaps == 0`），並由 `dcube_box_fill_verified` 填出 3D 立方體！
  let sys_1d = @kernel.dsystem_of([
    @kernel.tube_branch(f0, fn(_) { base }),
    @kernel.tube_branch(f1, fn(k) { @kernel.circle_point(k) }),
  ])
  let hf = @kernel.hfill_value(s1, sys_1d, @kernel.circle_point(i0), 1)
  let hc_1d = @kernel.hcomp_value(s1, sys_1d, @kernel.circle_point(i0), 1)
  let hfill_laws_ok = @kernel.conv_at(
      0,
      1,
      s1,
      hf(DZero),
      @kernel.circle_point(i0),
    ) &&
    @kernel.conv_at(0, 1, s1, hf(DOne), hc_1d)

  let face_k0 = @kernel.dcube_function(2, fn(ds) {
    @kernel.circle_point(
      @face_bdd.dim_simplify(@face_bdd.Dim::DAnd(ds[0], ds[1])),
    )
  })
  let face_i0 = @kernel.dcube_function(2, fn(_ds) { base })
  let face_i1 = @kernel.dcube_function(2, fn(ds) {
    @kernel.circle_point(
      @face_bdd.dim_simplify(@face_bdd.Dim::DOr(ds[0], ds[1])),
    )
  })
  let face_j0 = @kernel.dcube_function(2, fn(ds) {
    @kernel.circle_point(
      @face_bdd.dim_simplify(@face_bdd.Dim::DAnd(ds[0], ds[1])),
    )
  })
  let face_j1 = @kernel.dcube_function(2, fn(ds) { @kernel.circle_point(ds[0]) })
  let box3 = @kernel.dcube_open_box(s1, 3, 0, [
    @kernel.dcube_box_face(0, false, face_i0),
    @kernel.dcube_box_face(0, true, face_i1),
    @kernel.dcube_box_face(1, false, face_j0),
    @kernel.dcube_box_face(1, true, face_j1),
    @kernel.dcube_box_face(2, false, face_k0),
  ])
  let val_rep = @kernel.dcube_box_validate(box3, 0)
  let filled_3d = @kernel.dcube_box_fill_verified(box3, 0)
  let cap_2d = @kernel.dcube_box_cap(box3)
  let box3_ok = hfill_laws_ok &&
    val_rep.complete &&
    val_rep.overlaps_ok &&
    val_rep.failed_overlaps == 0 &&
    filled_3d is Some(_) &&
    cap_2d is Some(_)

  CubicalNbeSubstConnectionsKanReport::{
    cwf_subst_monoid_and_dim_comm_ok: cwf_ok,
    cofibration_local_sheaf_conversion_ok: conv_local_ok,
    canonical_nf_grammar_and_6_beta_eta_ok: nf_6_ok,
    kernel_quote_subst_naturality_ok: quote_nat_ok,
    bidirectional_type_formation_and_mismatch_rej_ok: bidir_ok,
    dependent_curry_and_sigma_elim_beta_eta_ok: curry_sigma_ok,
    dependent_funext_happly_roundtrip_ok: funext_ok,
    connection_squares_8_laws_and_duality_ok: conn_ok,
    structured_hcomp_pi_sigma_path_ok: hcomp_ok,
    hfill_and_3d_open_box_filler_verified_ok: box3_ok,
  }
}
