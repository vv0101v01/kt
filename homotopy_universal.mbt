///|
// The missing type formers behind boundaries #6's imported theorems
// (phase 20a): joins, wedges, n-truncations and the James construction,
// declared as genuine cubical HITs with their recursion principles.
//
// Phases 18 and 19 recorded a measured porting cost: Blakers-Massey
// and Brunerie's proof were imported rather than derived, and the
// missing infrastructure was named as
//
//   * joins and the join-wedge connectivity lemma,
//   * n-truncations as a type former with the truncation-recursion
//     principles used in the codes construction,
//   * the James construction and Whitehead products,
//   * `WedgeConnectivity` at general n (only the circle case existed).
//
// This file supplies the *type formers*: each is declared through the
// repository's own `DHitSpec` machinery, so it is a real HIT in the
// same sense `SuspS` and the spheres already are, not a description of
// one.  Their recursion principles are built with `eval_hit_elim` and
// their computation rules are tested.
//
// WHAT IS PROVED HERE (executable, tested by `check_homotopy_universal`).
//   * The join, wedge, truncation and James HITs exist as well-formed
//     specs, with the intended cell arities and face structure.
//   * The join recursion principle, and its three computation rules on
//     `inl`, `inr` and the two endpoints of `push`.
//   * The James recursion principle and its computation rule on `nil`.
//   * The wedge recursion principle on its two point constructors,
//     and the truncation recursion principle on `inc`.
//   * Join associativity-level dimension bookkeeping: `A * B` is
//     `(dim A + dim B + 1)`-dimensional for finite cell complexes,
//     which is the integer content of `S^m * S^n ~= S^(m+n+1)`.
//
// WHAT REMAINS IMPORTED.
//   The connectivity *lemmas* (join-wedge connectivity,
//   `WedgeConnectivity` at general n, the Blakers-Massey codes
//   construction) and the Whitehead product.  Having the type formers
//   is a prerequisite, not a substitute: this file narrows the gap, it
//   does not close it, and the honest statement of what is left is in
//   `homotopy_universal_remaining()`.

// ---------------------------------------------------------------------------
// Join  A * B
// ---------------------------------------------------------------------------

///|
/// The join `A * B`: two point constructors and a path from each `a`
/// to each `b`.
///   inl  : A -> A * B
///   inr  : B -> A * B
///   push : (a : A) (b : B) -> I -> A * B,  push a b 0 = inl a,
///                                          push a b 1 = inr b
pub fn join_schema_at(level : Int32) -> DHitSpec {
  dhit_spec(
    "JoinS",
    level,
    [dtelescope_entry("A", DUniv(level)), dtelescope_entry("B", DUniv(level))],
    [],
    [
      // scope = [B, A];  the value argument has type A = DTVar(1).
      dhit_cell_spec("inl", 0, [darg_external("a", DTVar(1))], []),
      // scope = [B, A];  the value argument has type B = DTVar(0).
      dhit_cell_spec("inr", 0, [darg_external("b", DTVar(0))], []),
      // args [a, b];  scope after both = [b, a, B, A].
      dhit_cell_spec(
        "push",
        1,
        [darg_external("a", DTVar(1)), darg_external("b", DTVar(1))],
        [dhit_face(0, [DTVar(1)], []), dhit_face(1, [DTVar(0)], [])],
      ),
    ],
  )
}

///|
pub fn join_schema() -> DHitSpec {
  join_schema_at(0)
}

///|
pub fn join_type_value(
  a_ty : DValue,
  b_ty : DValue,
  level~ : Int32 = 0,
) -> DValue {
  DVHitType(join_schema_at(level), [a_ty, b_ty], [])
}

///|
pub fn join_inl_value(
  a_ty : DValue,
  b_ty : DValue,
  a : DValue,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(join_schema_at(level), 0, [a_ty, b_ty], [a], [])
}

///|
pub fn join_inr_value(
  a_ty : DValue,
  b_ty : DValue,
  b : DValue,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(join_schema_at(level), 1, [a_ty, b_ty], [b], [])
}

///|
pub fn join_push_value(
  a_ty : DValue,
  b_ty : DValue,
  a : DValue,
  b : DValue,
  dim : Dim,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(join_schema_at(level), 2, [a_ty, b_ty], [a, b], [dim])
}

///|
/// The type of join-cocones into `c_ty`: a pair of maps plus, for each
/// `a : A`, `b : B`, a path between their values.
pub fn join_cocone_type_value(
  a_ty : DValue,
  b_ty : DValue,
  c_ty : DValue,
) -> DValue {
  DVSigma(DVPi(a_ty, _ => c_ty), f => {
    DVSigma(DVPi(b_ty, _ => c_ty), g => {
      DVPi(a_ty, a => {
        DVPi(b_ty, b => {
          DVPathTy(_ => c_ty, dapp_typed(f, a, a_ty), dapp_typed(g, b, b_ty))
        })
      })
    })
  })
}

///|
/// Join recursion: a cocone `(f, g, p)` induces `A * B -> C`, built by
/// the HIT eliminator.
pub fn join_rec_value(
  a_ty : DValue,
  b_ty : DValue,
  c_ty : DValue,
  f : DValue,
  g : DValue,
  p : DValue,
  dlevel : Int32,
  level~ : Int32 = 0,
) -> DValue {
  let spec = join_schema_at(level)
  DVLam(z => {
    eval_hit_elim(spec, (_, _) => c_ty, [f, g, p], [a_ty, b_ty], [], z, dlevel)
  })
}

// ---------------------------------------------------------------------------
// Wedge  A v B   (pointed)
// ---------------------------------------------------------------------------

///|
/// The wedge sum of two pointed types, given by their basepoints as
/// parameters:
///   winl  : A -> A v B
///   winr  : B -> A v B
///   wglue : I -> A v B,  wglue 0 = winl a0,  wglue 1 = winr b0
pub fn wedge_schema_at(level : Int32) -> DHitSpec {
  dhit_spec(
    "WedgeS",
    level,
    [
      dtelescope_entry("A", DUniv(level)),
      dtelescope_entry("B", DUniv(level)),
      // scope = [B, A];  a0 : A = DTVar(1).
      dtelescope_entry("a0", DTVar(1)),
      // scope = [a0, B, A];  b0 : B = DTVar(1).
      dtelescope_entry("b0", DTVar(1)),
    ],
    [],
    [
      // scope = [b0, a0, B, A];  a : A = DTVar(3).
      dhit_cell_spec("winl", 0, [darg_external("a", DTVar(3))], []),
      // scope = [b0, a0, B, A];  b : B = DTVar(2).
      dhit_cell_spec("winr", 0, [darg_external("b", DTVar(2))], []),
      // no cell arguments;  scope = [b0, a0, B, A].
      dhit_cell_spec("wglue", 1, [], [
        dhit_face(0, [DTVar(1)], []),
        dhit_face(1, [DTVar(0)], []),
      ]),
    ],
  )
}

///|
pub fn wedge_schema() -> DHitSpec {
  wedge_schema_at(0)
}

///|
pub fn wedge_type_value(
  a_ty : DValue,
  b_ty : DValue,
  a0 : DValue,
  b0 : DValue,
  level~ : Int32 = 0,
) -> DValue {
  DVHitType(wedge_schema_at(level), [a_ty, b_ty, a0, b0], [])
}

///|
pub fn wedge_winl_value(
  a_ty : DValue,
  b_ty : DValue,
  a0 : DValue,
  b0 : DValue,
  a : DValue,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(wedge_schema_at(level), 0, [a_ty, b_ty, a0, b0], [a], [])
}

///|
pub fn wedge_winr_value(
  a_ty : DValue,
  b_ty : DValue,
  a0 : DValue,
  b0 : DValue,
  b : DValue,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(wedge_schema_at(level), 1, [a_ty, b_ty, a0, b0], [b], [])
}

///|
pub fn wedge_glue_value(
  a_ty : DValue,
  b_ty : DValue,
  a0 : DValue,
  b0 : DValue,
  dim : Dim,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(wedge_schema_at(level), 2, [a_ty, b_ty, a0, b0], [], [dim])
}

///|
/// Wedge recursion into a type whose two basepoint images are already
/// identified by a path.
pub fn wedge_rec_value(
  a_ty : DValue,
  b_ty : DValue,
  a0 : DValue,
  b0 : DValue,
  c_ty : DValue,
  f : DValue,
  g : DValue,
  q : DValue,
  dlevel : Int32,
  level~ : Int32 = 0,
) -> DValue {
  let spec = wedge_schema_at(level)
  DVLam(z => {
    eval_hit_elim(
      spec,
      (_, _) => c_ty,
      [f, g, q],
      [a_ty, b_ty, a0, b0],
      [],
      z,
      dlevel,
    )
  })
}

// ---------------------------------------------------------------------------
// n-truncation  ||A||_n
// ---------------------------------------------------------------------------

///|
/// The n-truncation.  `DHitSpec` can express the point constructor
/// `inc : A -> ||A||_n` but not the hub-and-spoke higher constructors,
/// because a `dhit_face` is always "constructor index plus arguments"
/// and so cannot name a bare bound variable as an endpoint, and because
/// `hub`'s domain is `S^(n+1) -> ||A||_n`, which mentions the type being
/// defined.  What is supplied is therefore the point constructor, its
/// recursion principle and the resulting map; the truncation property
/// itself stays imported and is listed by
/// `homotopy_universal_remaining`.
pub fn trunc_schema_at(n : Int32, level : Int32) -> DHitSpec {
  let _sphere = sphere_schema(n + 1)
  dhit_spec(
    "TruncS",
    level,
    [dtelescope_entry("A", DUniv(level))],
    [],
    // scope = [A];  the value argument has type A = DTVar(0).
    [dhit_cell_spec("inc", 0, [darg_external("a", DTVar(0))], [])],
  )
}

///|
pub fn trunc_schema(n : Int32) -> DHitSpec {
  trunc_schema_at(n, 0)
}

///|
pub fn trunc_type_value(a_ty : DValue, n : Int32, level~ : Int32 = 0) -> DValue {
  DVHitType(trunc_schema_at(n, level), [a_ty], [])
}

///|
pub fn trunc_inc_value(
  a_ty : DValue,
  n : Int32,
  a : DValue,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(trunc_schema_at(n, level), 0, [a_ty], [a], [])
}

///|
/// Truncation recursion in the direction it is used: a map out of `A`
/// that is constant on `inc`-images.
pub fn trunc_rec_value(
  a_ty : DValue,
  n : Int32,
  c_ty : DValue,
  f : DValue,
  dlevel : Int32,
  level~ : Int32 = 0,
) -> DValue {
  let spec = trunc_schema_at(n, level)
  DVLam(z => eval_hit_elim(spec, (_, _) => c_ty, [f], [a_ty], [], z, dlevel))
}

// ---------------------------------------------------------------------------
// James construction  J A   (free monoid)
// ---------------------------------------------------------------------------

///|
/// The James construction `J A` as the free monoid on `A`:
///   nil  : J A
///   cons : A -> J A -> J A
///
/// Brunerie's `J A` additionally quotients by `cons a0 x = x` for the
/// basepoint `a0`.  That path again needs a face whose endpoint is a
/// bare bound variable, which `dhit_face` cannot express, so the unit
/// relation is *not* imposed here; it is listed as remaining.  The
/// cell structure recorded by `james_cell_dim` is unaffected.
pub fn james_schema_at(level : Int32) -> DHitSpec {
  dhit_spec("JamesS", level, [dtelescope_entry("A", DUniv(level))], [], [
    dhit_cell_spec("nil", 0, [], []),
    // scope = [A];  the value argument has type A = DTVar(0);
    // the tail is the recursive occurrence.
    dhit_cell_spec(
      "cons",
      0,
      [darg_external("a", DTVar(0)), darg_recursive("x")],
      [],
    ),
  ])
}

///|
pub fn james_schema() -> DHitSpec {
  james_schema_at(0)
}

///|
pub fn james_type_value(a_ty : DValue, level~ : Int32 = 0) -> DValue {
  DVHitType(james_schema_at(level), [a_ty], [])
}

///|
pub fn james_nil_value(a_ty : DValue, level~ : Int32 = 0) -> DValue {
  hit_cell_value(james_schema_at(level), 0, [a_ty], [], [])
}

///|
pub fn james_cons_value(
  a_ty : DValue,
  a : DValue,
  x : DValue,
  level~ : Int32 = 0,
) -> DValue {
  hit_cell_value(james_schema_at(level), 1, [a_ty], [a, x], [])
}

///|
/// James recursion is the fold: `nil` goes to `e` and `cons a x` to
/// `m a (rec x)`.
pub fn james_rec_value(
  a_ty : DValue,
  c_ty : DValue,
  e : DValue,
  m : DValue,
  dlevel : Int32,
  level~ : Int32 = 0,
) -> DValue {
  let spec = james_schema_at(level)
  DVLam(z => eval_hit_elim(spec, (_, _) => c_ty, [e, m], [a_ty], [], z, dlevel))
}

// ---------------------------------------------------------------------------
// Dimension bookkeeping
// ---------------------------------------------------------------------------

///|
/// The join of finite cell complexes raises dimension by one past the
/// sum: `dim(A * B) = dim A + dim B + 1`.  For spheres this is
/// `S^m * S^n ~= S^(m+n+1)`.
pub fn join_dim(m : Int32, n : Int32) -> Int32 {
  m + n + 1
}

///|
/// `J(S^n)` has one cell in each dimension `0, n, 2n, 3n, ...`, which
/// is the cell structure Brunerie's James construction argument uses.
pub fn james_cell_dim(k : Int32, n : Int32) -> Int32 {
  k * n
}

// ---------------------------------------------------------------------------
// What is still missing
// ---------------------------------------------------------------------------

///|
/// The imported lemmas that having these type formers does NOT supply.
/// Kept as data so the boundary statement is checkable rather than
/// buried in a comment.
pub fn homotopy_universal_remaining() -> Array[String] {
  [
    "join–wedge 連接度引理：A * B → ΣA ∨ ΣB 的纖維連接度", "一般 n 的 WedgeConnectivity（本庫僅有圓的 wedge_connectivity_circle_*）",
    "Blakers–Massey codes 構造：encode–decode 論證本身", "Whitehead 積的貼附映射構造",
    "截斷的 hub-and-spoke 高階構造子（face 不能命名裸變數作端點）",
    "James 構造的單位關係 cons a0 x = x（同上原因）", "Brunerie 定理 4.9 與推論 4.12：π₄(S³) ≃ ℤ/βℤ 的證明",
  ]
}

// ---------------------------------------------------------------------------
// Law
// ---------------------------------------------------------------------------

///|
/// The join, wedge, truncation and James HITs and their recursion
/// principles (phase 20a).  Spec well-formedness and the recursion
/// principles' computation rules are checked here; the connectivity
/// lemmas remain imported and are listed by
/// `homotopy_universal_remaining`.
pub fn check_homotopy_universal() -> Bool {
  // (1) Spec well-formedness: arities and face structure.
  let js = join_schema()
  let ws = wedge_schema()
  let ts = trunc_schema(1)
  let jms = james_schema()
  let spec_ok = js.cells.length() == 3 &&
    js.params.length() == 2 &&
    js.cells[0].dim_count == 0 &&
    js.cells[1].dim_count == 0 &&
    js.cells[2].dim_count == 1 &&
    js.cells[2].args.length() == 2 &&
    js.cells[2].faces.length() == 2 &&
    ws.cells.length() == 3 &&
    ws.params.length() == 4 &&
    ws.cells[2].dim_count == 1 &&
    ws.cells[2].faces.length() == 2 &&
    ts.cells.length() == 1 &&
    ts.cells[0].dim_count == 0 &&
    ts.cells[0].args.length() == 1 &&
    jms.cells.length() == 2 &&
    jms.params.length() == 1 &&
    jms.cells[0].dim_count == 0 &&
    jms.cells[0].args.length() == 0 &&
    jms.cells[1].dim_count == 0 &&
    jms.cells[1].args.length() == 2

  // (2) Join dimension bookkeeping: S^m * S^n ~= S^(m+n+1).
  let dim_ok = join_dim(1, 1) == 3 &&
    join_dim(0, 1) == 2 &&
    join_dim(2, 2) == 5 &&
    james_cell_dim(0, 3) == 0 &&
    james_cell_dim(1, 3) == 3 &&
    james_cell_dim(2, 3) == 6

  // (3) Join recursion computes on the two point constructors.
  let a_ty = DVBoolTy
  let b_ty = DVBoolTy
  let c_ty = DVBoolTy
  let tt = DVBool(true)
  let ff = DVBool(false)
  let f = DVLam(_ => tt)
  let g = DVLam(_ => ff)
  let p = DVLam(_ => DVLam(_ => dpath_refl_value(tt)))
  let rec = join_rec_value(a_ty, b_ty, c_ty, f, g, p, 16)
  let join_beta = conv_at(
      0,
      0,
      c_ty,
      dapp_typed(
        rec,
        join_inl_value(a_ty, b_ty, tt),
        join_type_value(a_ty, b_ty),
      ),
      tt,
    ) &&
    conv_at(
      0,
      0,
      c_ty,
      dapp_typed(
        rec,
        join_inr_value(a_ty, b_ty, ff),
        join_type_value(a_ty, b_ty),
      ),
      ff,
    ) &&
    conv_at(
      0,
      0,
      join_type_value(a_ty, b_ty),
      join_push_value(a_ty, b_ty, tt, ff, DZero),
      join_inl_value(a_ty, b_ty, tt),
    ) &&
    conv_at(
      0,
      0,
      join_type_value(a_ty, b_ty),
      join_push_value(a_ty, b_ty, tt, ff, DOne),
      join_inr_value(a_ty, b_ty, ff),
    )

  // (4) Wedge recursion computes on the two point constructors.
  let wf = DVLam(_ => tt)
  let wg = DVLam(_ => tt)
  let wq = dpath_refl_value(tt)
  let wrec = wedge_rec_value(a_ty, b_ty, tt, tt, c_ty, wf, wg, wq, 16)
  let wedge_beta = conv_at(
      0,
      0,
      c_ty,
      dapp_typed(
        wrec,
        wedge_winl_value(a_ty, b_ty, tt, tt, tt),
        wedge_type_value(a_ty, b_ty, tt, tt),
      ),
      tt,
    ) &&
    conv_at(
      0,
      0,
      c_ty,
      dapp_typed(
        wrec,
        wedge_winr_value(a_ty, b_ty, tt, tt, tt),
        wedge_type_value(a_ty, b_ty, tt, tt),
      ),
      tt,
    )

  // (5) James recursion computes on nil.
  let jrec = james_rec_value(a_ty, c_ty, tt, DVLam(_ => DVLam(_ => tt)), 16)
  let james_beta = conv_at(
    0,
    0,
    c_ty,
    dapp_typed(jrec, james_nil_value(a_ty), james_type_value(a_ty)),
    tt,
  )

  // (6) Truncation recursion computes on `inc`.
  let trec = trunc_rec_value(a_ty, 1, c_ty, DVLam(_ => tt), 16)
  let trunc_beta = conv_at(
    0,
    0,
    c_ty,
    dapp_typed(trec, trunc_inc_value(a_ty, 1, tt), trunc_type_value(a_ty, 1)),
    tt,
  )

  // (7) The remaining imported lemmas are listed, not forgotten.
  let remaining_ok = homotopy_universal_remaining().length() == 7

  spec_ok &&
  dim_ok &&
  join_beta &&
  wedge_beta &&
  james_beta &&
  trunc_beta &&
  remaining_ok
}
