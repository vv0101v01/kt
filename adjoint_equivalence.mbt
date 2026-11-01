///|
// Adjoint equivalences, contractible fibers, and primitive Glue
// quoting.
//
// The kernel's `DMkEquiv` is a quasi-inverse equivalence (two
// functions with a section and a retraction).  An *adjoint*
// equivalence additionally carries the triangle coherence
//
//   τ (x : A) : Path (Path B (f (g (f x))) (f x))
//                      (ap f (retr x)) (sect (f x)).
//
// This file makes that data first-class: a semantic record with an
// explicit triangle value, the corresponding AST Σ-type over
// `Equiv A B`, identity and Bool-negation instances whose triangle
// is reflexivity, and the standard improved counit of a
// quasi-inverse (the first step of adjointification).  It also
// gives the contractible-fiber characterization as checked AST
// types, the definitional contraction of based singletons, and a
// fiber center for every quasi-inverse equivalence.

// ---------------------------------------------------------------------------
// Triangle coherence and adjoint equivalence data
// ---------------------------------------------------------------------------

///|
/// The type of the triangle coherence, as a semantic value:
/// `Π x, Path (Path B (f (g (f x))) (f x)) (ap f (retr x)) (sect (f x))`.
pub fn equiv_triangle_type(
  src : DValue,
  dst : DValue,
  fwd : DValue,
  bwd : DValue,
  sect : DValue,
  retr : DValue,
) -> DValue {
  DVPi(src, x => {
    let fx = dapp_typed(fwd, x, src)
    let gfx = dapp_typed(bwd, fx, dst)
    let fgfx = dapp_typed(fwd, gfx, src)
    let path_ty = DVPathTy(_ => dst, fgfx, fx)
    let ap_retr = dpath_cong_value(fwd, src, dapp_typed(retr, x, src))
    let sect_fx = dapp_typed(sect, fx, dst)
    DVPathTy(_ => path_ty, ap_retr, sect_fx)
  })
}

///|
pub struct DAdjointEquivParts {
  equiv : DEquivParts
  triangle : DValue
}

///|

///|
/// Forget the coherence: the underlying quasi-inverse equivalence.

///|
/// The identity adjoint equivalence: every component is
/// reflexivity, including the triangle.
pub fn adjoint_id_value(ty : DValue) -> DAdjointEquivParts {
  DAdjointEquivParts::{
    equiv: equiv_parts(equiv_id_value(ty), ty, ty),
    triangle: DVLam(x => DVPathLam(_ => DVPathLam(_ => x))),
  }
}

///|
/// The improved counit (section) of a quasi-inverse equivalence,
/// `ε'(y) = ε(f (g y))⁻¹ ∙ ap f (η (g y)) ∙ ε(y)`.  Replacing `ε`
/// by `ε'` is the standard first step in adjointifying a
/// quasi-inverse; the resulting data is still an equivalence with
/// the same functions and retraction.
pub fn equiv_improved_sect_value(
  src : DValue,
  dst : DValue,
  fwd : DValue,
  bwd : DValue,
  sect : DValue,
  retr : DValue,
  dlevel : Int32,
) -> DValue {
  DVLam(y => {
    let gy = dapp_typed(bwd, y, dst)
    let fgy = dapp_typed(fwd, gy, src)
    let first = dpath_sym_value(dapp_typed(sect, fgy, dst))
    let second = dpath_cong_value(fwd, src, dapp_typed(retr, gy, src))
    let third = dapp_typed(sect, y, dst)
    dpath_trans_value(
      dst,
      dpath_trans_value(dst, first, second, dlevel),
      third,
      dlevel,
    )
  })
}

///|
/// A quasi-inverse equivalence with its section replaced by the
/// improved counit.
pub fn equiv_with_improved_sect(
  e : DValue,
  src : DValue,
  dst : DValue,
  dlevel : Int32,
) -> DValue {
  let p = equiv_parts(e, src, dst)
  DVEquiv(
    p.src,
    p.dst,
    p.fwd,
    p.bwd,
    equiv_improved_sect_value(
      p.src,
      p.dst,
      p.fwd,
      p.bwd,
      p.sect,
      p.retr,
      dlevel,
    ),
    p.retr,
  )
}

///|
/// The AST Σ-type of adjoint equivalences over `Equiv A B`.  In the
/// body, `DTVar(0)` is the bound equivalence and, under the
/// additional `x : A` binder, `DTVar(1)` is the equivalence and
/// `DTVar(0)` is `x`.
pub fn adjoint_equiv_type_term(a : DTerm, b : DTerm) -> DTerm {
  let e1 = DTVar(1)
  let x = DTVar(0)
  let fx = DApp(DEquivFwd(e1), x)
  let fgfx = DApp(DEquivFwd(e1), DApp(DEquivBwd(e1), fx))
  // `b`/`a` are closed in the uses here; under the Σ and Π binders
  // they are unchanged because DTerm binders are explicit in the
  // builders used by the laws (closed A and B).
  DSigma(
    DEquivTy(a, b),
    DPi(
      a,
      DPath(
        DPath(b, fgfx, fx),
        dpath_cong_term(DEquivFwd(e1), DApp(DEquivRetr(e1), x)),
        DApp(DEquivSect(e1), fx),
      ),
    ),
  )
}

// ---------------------------------------------------------------------------
// Contractible fibers
// ---------------------------------------------------------------------------

///|
/// `isContr A = Σ (c : A), Π (x : A), Path A c x` as an AST type
/// (for closed `A`).
pub fn is_contr_type_term(a : DTerm) -> DTerm {
  DSigma(a, DPi(a, DPath(a, DTVar(1), DTVar(0))))
}

///|
/// `fiber f y = Σ (x : A), Path B (f x) y` as an AST type, for
/// closed `A`, `B`, `f`, and `y`.
pub fn fiber_type_term(a : DTerm, b : DTerm, f : DTerm, y : DTerm) -> DTerm {
  DSigma(a, DPath(b, DApp(f, DTVar(0)), y))
}

///|
/// `Π (y : B), isContr (fiber f y)` as an AST type, for closed
/// `A`, `B`, and `f`.  Under the Π binder `DTVar(0)` is `y`.
pub fn contractible_fibers_type_term(a : DTerm, b : DTerm, f : DTerm) -> DTerm {
  DPi(b, is_contr_type_term(fiber_type_term(a, b, f, DTVar(0))))
}

///|
/// The based singleton contraction: the path in
/// `Σ (x : A), Path A x y` from the center `(y, refl)` to `(x, p)`,
/// by `i ↦ (p (¬i), λ j ↦ p (¬i ∨ j))`.  This computes at both
/// endpoints by the De Morgan endpoint laws.
pub fn singleton_contraction_value(p : DValue) -> DValue {
  DVPathLam(i => {
    DVPair(dapp_dim(p, DNeg(i)), DVPathLam(j => dapp_dim(p, DOr(DNeg(i), j))))
  })
}

///|
/// The center of the fiber of a quasi-inverse equivalence over
/// `y`: `(g y, sect y)`.
pub fn equiv_fiber_center_value(
  e : DValue,
  src : DValue,
  dst : DValue,
  y : DValue,
) -> DValue {
  let p = equiv_parts(e, src, dst)
  DVPair(dapp_typed(p.bwd, y, dst), dapp_typed(p.sect, y, dst))
}

///|
/// Contractibility data for the fibers of an identity equivalence,
/// from the singleton contraction: `y ↦ ((y, refl), λ w ↦ ...)`.
/// A fiber element is `(x, p)` with `p : Path A x y`; its
/// contraction is the singleton contraction at `p`.

///|
pub fn check_adjoint_equivalence_and_fibers() -> Bool {
  // Triangle coherence of the identity on Bool and on the circle,
  // checked at the semantic triangle type for fresh points.
  for ty in [DVBoolTy, DVCircleTy] {
    let adj = adjoint_id_value(ty)
    let p = adj.equiv
    let tri_ty = equiv_triangle_type(ty, ty, p.fwd, p.bwd, p.sect, p.retr)
    let fresh = DVNeutral(DNVar(0))
    let at = dapp_typed(adj.triangle, fresh, ty)
    let expected = match as_pi(tri_ty) {
      Some(parts) => (parts.fam)(fresh)
      None => DVUnitTy
    }
    if !conv_at(
        1,
        0,
        expected,
        at,
        DVPathLam(_ => {
          dpath_cong_value(p.fwd, ty, dapp_typed(p.retr, fresh, ty))
        }),
      ) {
      return false
    }
  }
  // Improved counit of Bool negation: still a section at both
  // points (endpoint computation), with the same functions.
  let e = deval_dim(bool_not_equiv_term(), denv_empty(), ddim_empty())
  let improved = equiv_with_improved_sect(e, DVBoolTy, DVBoolTy, 0)
  let parts = equiv_parts(improved, DVBoolTy, DVBoolTy)
  for y in [true, false] {
    let sect_y = dapp_typed(parts.sect, DVBool(y), DVBoolTy)
    if !conv_at(0, 0, DVBoolTy, dapp_dim(sect_y, DZero), DVBool(y)) ||
      !conv_at(0, 0, DVBoolTy, dapp_dim(sect_y, DOne), DVBool(y)) ||
      !conv_at(
        0,
        0,
        DVBoolTy,
        equiv_fun_value(improved, DVBoolTy, DVBoolTy, DVBool(y)),
        DVBool(!y),
      ) {
      return false
    }
  }
  // The AST adjoint Σ-type and contractible-fiber types are
  // well-formed types.
  if !dep_check_closed(adjoint_equiv_type_term(DBoolTy, DBoolTy), DUniv(0)) ||
    !dep_check_closed(is_contr_type_term(DBoolTy), DUniv(0)) ||
    !dep_check_closed(
      contractible_fibers_type_term(DBoolTy, DBoolTy, DLam(DBoolTy, DTVar(0))),
      DUniv(0),
    ) {
    return false
  }
  // Singleton contraction endpoints on the circle loop.
  let loop_path : DValue = DVPathLam(d => circle_point(d))
  let contr = singleton_contraction_value(loop_path)
  let singleton_ty = DVSigma(DVCircleTy, x => {
    DVPathTy(_ => DVCircleTy, x, DVCirclePoint(DZero))
  })
  let center : DValue = DVPair(
    DVCirclePoint(DZero),
    DVPathLam(_ => DVCirclePoint(DZero)),
  )
  let element : DValue = DVPair(DVCirclePoint(DZero), loop_path)
  if !conv_at(0, 0, singleton_ty, dapp_dim(contr, DZero), center) ||
    !conv_at(0, 0, singleton_ty, dapp_dim(contr, DOne), element) {
    return false
  }
  // Fiber center of Bool negation over `true` is `(false, refl)`.
  let center2 = equiv_fiber_center_value(e, DVBoolTy, DVBoolTy, DVBool(true))
  match force_value(center2) {
    DVPair(gx, proof) =>
      conv_at(0, 0, DVBoolTy, gx, DVBool(false)) &&
      conv_at(0, 0, DVBoolTy, dapp_dim(proof, DZero), DVBool(true)) &&
      conv_at(0, 0, DVBoolTy, dapp_dim(proof, DOne), DVBool(true))
    _ => false
  }
}

///|
/// Quoting a Glue-by-equivalence type with a top branch preserves
/// the primitive `DGlueEquiv` syntax (it does not collapse to the
/// branch type), while remaining convertible to the original.
pub fn check_glue_equiv_quote_preserves_syntax() -> Bool {
  let e = deval_dim(bool_not_equiv_term(), denv_empty(), ddim_empty())
  let glue : DValue = DVGlueEquiv(
    [dequiv_branch_value(FTop, DVBoolTy, e)],
    DVBoolTy,
    0,
  )
  let quoted = quote_ty(0, 0, glue)
  match quoted {
    DGlueEquiv(base, branches) => {
      let convertible = match
        d_as_type(quoted, denv_empty(), denv_empty(), ddim_empty()) {
        Some(tv) => conv_ty(0, 0, tv.value, glue)
        None => false
      }
      base == DBoolTy && branches.length() == 1 && convertible
    }
    _ => false
  }
}

/// Phase-10 semantic adjointification and contractible fibers.
///
/// The construction follows the standard cubical `lemIso` square:
/// from a quasi-inverse equivalence it joins any two elements of a
/// fiber, hence gives contractible fibers.  Specializing the same
/// contraction at `(x, refl)` in the fiber over `f x` produces a
/// replacement retraction and the half-adjoint triangle.

///|
fn equiv_parts_apply_fwd(parts : DEquivParts, x : DValue) -> DValue {
  dapp_typed(parts.fwd, x, parts.src)
}

///|
fn equiv_parts_apply_bwd(parts : DEquivParts, y : DValue) -> DValue {
  dapp_typed(parts.bwd, y, parts.dst)
}

///|
pub fn equiv_fiber_type_value(parts : DEquivParts, y : DValue) -> DValue {
  DVSigma(parts.src, x => {
    DVPathTy(_ => parts.dst, equiv_parts_apply_fwd(parts, x), y)
  })
}

///|
fn equiv_fiber_fst_value(parts : DEquivParts, y : DValue, w : DValue) -> DValue {
  ignore(y)
  dfst_typed(w, x => {
    DVPathTy(_ => parts.dst, equiv_parts_apply_fwd(parts, x), y)
  })
}

///|
fn equiv_fiber_snd_value(parts : DEquivParts, y : DValue, w : DValue) -> DValue {
  dsnd_typed(w, parts.src, x => {
    DVPathTy(_ => parts.dst, equiv_parts_apply_fwd(parts, x), y)
  })
}

///|
/// The first filler in `lemIso`: interpolate `g (p (~ i))`, the
/// constant center `g y`, and the retraction path at `x`.
fn equiv_fiber_fill_at(
  parts : DEquivParts,
  y : DValue,
  x : DValue,
  p : DValue,
  i : Dim,
  k : Dim,
  dlevel : Int32,
) -> DValue {
  let gy = equiv_parts_apply_bwd(parts, y)
  let retr_x = dapp_typed(parts.retr, x, parts.src)
  let branches = dsystem_of([
    tube_branch(face_simplify(FEq1(i)), kk => dapp_dim(retr_x, kk)),
    tube_branch(face_simplify(FEq0(i)), _ => gy),
  ])
  hfill_value(
    parts.src,
    branches,
    equiv_parts_apply_bwd(parts, dapp_dim(p, dim_simplify(DNeg(i)))),
    dlevel,
  )(k)
}

///|
/// Join the end edges of the two fillers for points in one fiber.
fn equiv_fiber_fill2_at(
  parts : DEquivParts,
  y : DValue,
  x0 : DValue,
  p0 : DValue,
  x1 : DValue,
  p1 : DValue,
  i : Dim,
  k : Dim,
  dlevel : Int32,
) -> DValue {
  let gy = equiv_parts_apply_bwd(parts, y)
  let branches = dsystem_of([
    tube_branch(face_simplify(FEq1(i)), kk => {
      equiv_fiber_fill_at(parts, y, x1, p1, kk, DOne, dlevel + 1)
    }),
    tube_branch(face_simplify(FEq0(i)), kk => {
      equiv_fiber_fill_at(parts, y, x0, p0, kk, DOne, dlevel + 1)
    }),
  ])
  hfill_value(parts.src, branches, gy, dlevel)(k)
}

///|
fn equiv_fiber_path_a_at(
  parts : DEquivParts,
  y : DValue,
  x0 : DValue,
  p0 : DValue,
  x1 : DValue,
  p1 : DValue,
  i : Dim,
  dlevel : Int32,
) -> DValue {
  equiv_fiber_fill2_at(parts, y, x0, p0, x1, p1, i, DOne, dlevel)
}

///|
/// The square in the source type obtained by closing the second
/// filler with the two first fillers and the retraction.
fn equiv_fiber_square_a_at(
  parts : DEquivParts,
  y : DValue,
  x0 : DValue,
  p0 : DValue,
  x1 : DValue,
  p1 : DValue,
  i : Dim,
  j : Dim,
  dlevel : Int32,
) -> DValue {
  let gy = equiv_parts_apply_bwd(parts, y)
  let top = equiv_fiber_path_a_at(parts, y, x0, p0, x1, p1, i, dlevel + 1)
  let retr_top = dapp_typed(parts.retr, top, parts.src)
  let branches = dsystem_of([
    tube_branch(face_simplify(FEq1(i)), kk => {
      equiv_fiber_fill_at(
        parts,
        y,
        x1,
        p1,
        j,
        dim_simplify(DNeg(kk)),
        dlevel + 1,
      )
    }),
    tube_branch(face_simplify(FEq0(i)), kk => {
      equiv_fiber_fill_at(
        parts,
        y,
        x0,
        p0,
        j,
        dim_simplify(DNeg(kk)),
        dlevel + 1,
      )
    }),
    tube_branch(face_simplify(FEq1(j)), kk => {
      dapp_dim(retr_top, dim_simplify(DNeg(kk)))
    }),
    tube_branch(face_simplify(FEq0(j)), _ => gy),
  ])
  hcomp_value(
    parts.src,
    branches,
    equiv_fiber_fill2_at(parts, y, x0, p0, x1, p1, i, j, dlevel + 1),
    dlevel,
  )
}

///|
/// Apply `f` to the source square and close it with the naturality
/// squares of the section.  This supplies the second coordinate of
/// the path in the dependent fiber.
fn equiv_fiber_square_b_at(
  parts : DEquivParts,
  y : DValue,
  x0 : DValue,
  p0 : DValue,
  x1 : DValue,
  p1 : DValue,
  i : Dim,
  j : Dim,
  dlevel : Int32,
) -> DValue {
  let path_a = equiv_fiber_path_a_at(parts, y, x0, p0, x1, p1, i, dlevel + 1)
  let sect_top = dapp_typed(
    parts.sect,
    equiv_parts_apply_fwd(parts, path_a),
    parts.dst,
  )
  let sect_y = dapp_typed(parts.sect, y, parts.dst)
  let branches = dsystem_of([
    tube_branch(face_simplify(FEq1(i)), kk => {
      dapp_dim(
        dapp_typed(parts.sect, dapp_dim(p1, dim_simplify(DNeg(j))), parts.dst),
        kk,
      )
    }),
    tube_branch(face_simplify(FEq0(i)), kk => {
      dapp_dim(
        dapp_typed(parts.sect, dapp_dim(p0, dim_simplify(DNeg(j))), parts.dst),
        kk,
      )
    }),
    tube_branch(face_simplify(FEq1(j)), kk => dapp_dim(sect_top, kk)),
    tube_branch(face_simplify(FEq0(j)), kk => dapp_dim(sect_y, kk)),
  ])
  hcomp_value(
    parts.dst,
    branches,
    equiv_parts_apply_fwd(
      parts,
      equiv_fiber_square_a_at(parts, y, x0, p0, x1, p1, i, j, dlevel + 1),
    ),
    dlevel,
  )
}

///|
/// A path between any two elements of the fiber of a quasi-inverse
/// equivalence over `y`.  This is the semantic `lemIso` term.
pub fn equiv_fiber_path_value(
  e : DValue,
  src : DValue,
  dst : DValue,
  y : DValue,
  w0 : DValue,
  w1 : DValue,
  dlevel : Int32,
) -> DValue {
  let parts = equiv_parts(e, src, dst)
  let x0 = equiv_fiber_fst_value(parts, y, w0)
  let p0 = equiv_fiber_snd_value(parts, y, w0)
  let x1 = equiv_fiber_fst_value(parts, y, w1)
  let p1 = equiv_fiber_snd_value(parts, y, w1)
  DVPathLam(i => {
    DVPair(
      equiv_fiber_path_a_at(parts, y, x0, p0, x1, p1, i, dlevel + 1),
      DVPathLam(j => {
        equiv_fiber_square_b_at(
          parts,
          y,
          x0,
          p0,
          x1,
          p1,
          i,
          dim_simplify(DNeg(j)),
          dlevel + 1,
        )
      }),
    )
  })
}

///|
/// The contraction from the canonical center `(g y, ε y)` to an
/// arbitrary element of the fiber.
pub fn equiv_fiber_contraction_value(
  e : DValue,
  src : DValue,
  dst : DValue,
  y : DValue,
  w : DValue,
  dlevel : Int32,
) -> DValue {
  equiv_fiber_path_value(
    e,
    src,
    dst,
    y,
    equiv_fiber_center_value(e, src, dst, y),
    w,
    dlevel,
  )
}

///|
/// Contractibility of every fiber, as a semantic dependent
/// function of `y : dst`.
pub fn equiv_contractible_fibers_value(
  e : DValue,
  src : DValue,
  dst : DValue,
  dlevel : Int32,
) -> DValue {
  DVLam(y => {
    DVPair(
      equiv_fiber_center_value(e, src, dst, y),
      DVLam(w => equiv_fiber_contraction_value(e, src, dst, y, w, dlevel)),
    )
  })
}

///|
/// Turn the diagonal of a square whose top and right sides are
/// constant at the endpoint into the corner path identifying its
/// bottom and left edges.  The four tube faces force exactly those
/// boundaries, which is the step needed to extract the triangle
/// from a dependent path in a fiber.
fn fiber_square_corner_value(
  parts : DEquivParts,
  square : (Dim, Dim) -> DValue,
  start : DValue,
  k : Dim,
  i : Dim,
  dlevel : Int32,
) -> DValue {
  let not_k = dim_simplify(DNeg(k))
  let base = square(dim_simplify(DAnd(i, not_k)), dim_simplify(DAnd(i, k)))
  let branches = dsystem_of([
    tube_branch(face_simplify(FEq0(i)), _ => start),
    tube_branch(face_simplify(FEq1(i)), m => {
      square(dim_simplify(DOr(not_k, m)), dim_simplify(DOr(k, m)))
    }),
    tube_branch(face_simplify(FEq0(k)), _ => square(i, DZero)),
    tube_branch(face_simplify(FEq1(k)), _ => square(DZero, i)),
  ])
  hcomp_value(parts.dst, branches, base, dlevel)
}

///|
/// Automatically adjointify an arbitrary semantic quasi-inverse.
/// The forward map, inverse and section are retained; the new
/// retraction is the first coordinate of the fiber contraction
/// from `(g (f x), ε (f x))` to `(x, refl)`, and the stored
/// triangle is extracted from the contraction's second square.
pub fn adjointify_equiv_value(
  e : DValue,
  src : DValue,
  dst : DValue,
  dlevel : Int32,
) -> DAdjointEquivParts {
  let parts = equiv_parts(e, src, dst)
  let contraction_at = (x : DValue) => {
    equiv_fiber_contraction_value(
      e,
      src,
      dst,
      equiv_parts_apply_fwd(parts, x),
      DVPair(x, DVPathLam(_ => equiv_parts_apply_fwd(parts, x))),
      dlevel,
    )
  }
  let new_retr : DValue = DVLam(x => {
    let fx = equiv_parts_apply_fwd(parts, x)
    DVPathLam(i => {
      equiv_fiber_fst_value(parts, fx, dapp_dim(contraction_at(x), i))
    })
  })
  let triangle : DValue = DVLam(x => {
    let fx = equiv_parts_apply_fwd(parts, x)
    let gfx = equiv_parts_apply_bwd(parts, fx)
    let fgfx = equiv_parts_apply_fwd(parts, gfx)
    let square = (a : Dim, b : Dim) => {
      dapp_dim(
        equiv_fiber_snd_value(parts, fx, dapp_dim(contraction_at(x), a)),
        b,
      )
    }
    DVPathLam(k => {
      DVPathLam(i => {
        fiber_square_corner_value(parts, square, fgfx, k, i, dlevel + 6)
      })
    })
  })
  {
    equiv: {
      src: parts.src,
      dst: parts.dst,
      fwd: parts.fwd,
      bwd: parts.bwd,
      sect: parts.sect,
      retr: new_retr,
    },
    triangle,
  }
}

///|
/// End-to-end validation of the general constructions: contractible
/// fibers and automatic adjointification are checked for Bool
/// negation and for the identity of the (primitive) circle.  The
/// circle case also checks the dependent boundary of a generic
/// point of the contraction under its two endpoint faces, which is
/// the judgment the type checker needs for the second component of
/// every intermediate fiber element.
pub fn check_general_adjointification_and_contractible_fibers() -> Bool {
  // Bool negation, fiber over `true`.
  let e = deval_dim(bool_not_equiv_term(), denv_empty(), ddim_empty())
  let parts = equiv_parts(e, DVBoolTy, DVBoolTy)
  let y : DValue = DVBool(true)
  let w : DValue = DVPair(DVBool(false), DVPathLam(_ => DVBool(true)))
  let fiber_ty = equiv_fiber_type_value(parts, y)
  let center = equiv_fiber_center_value(e, DVBoolTy, DVBoolTy, y)
  let contraction = equiv_fiber_contraction_value(
    e,
    DVBoolTy,
    DVBoolTy,
    y,
    w,
    2,
  )
  if !conv_at(0, 0, fiber_ty, dapp_dim(contraction, DZero), center) ||
    !conv_at(0, 0, fiber_ty, dapp_dim(contraction, DOne), w) {
    return false
  }
  // The bundled contractibility proof computes definitionally at
  // the same fiber.
  let bundled = dapp_typed(
    equiv_contractible_fibers_value(e, DVBoolTy, DVBoolTy, 2),
    y,
    DVBoolTy,
  )
  let bundled_center = dfst_typed(bundled, x => {
    DVPi(fiber_ty, _ => DVPathTy(_ => fiber_ty, x, w))
  })
  let bundled_contraction = dapp_typed(
    dsnd_typed(bundled, fiber_ty, _ => DVPi(fiber_ty, _ => fiber_ty)),
    w,
    fiber_ty,
  )
  if !conv_at(0, 0, fiber_ty, bundled_center, center) ||
    !conv_at(0, 0, fiber_ty, dapp_dim(bundled_contraction, DOne), w) {
    return false
  }
  // Adjointification of Bool negation at both points.
  let adj_bool = adjointify_equiv_value(e, DVBoolTy, DVBoolTy, 2)
  let qb = adj_bool.equiv
  for xv in [true, false] {
    let x : DValue = DVBool(xv)
    let fx = equiv_parts_apply_fwd(qb, x)
    let gfx = equiv_parts_apply_bwd(qb, fx)
    let retr_x = dapp_typed(qb.retr, x, DVBoolTy)
    if !conv_at(0, 0, DVBoolTy, dapp_dim(retr_x, DZero), gfx) ||
      !conv_at(0, 0, DVBoolTy, dapp_dim(retr_x, DOne), x) {
      return false
    }
    let triangle_x = dapp_typed(adj_bool.triangle, x, DVBoolTy)
    let path_ty : DValue = DVPathTy(
      _ => DVBoolTy,
      equiv_parts_apply_fwd(qb, gfx),
      fx,
    )
    if !conv_at(
        0,
        0,
        path_ty,
        dapp_dim(triangle_x, DZero),
        dpath_cong_value(qb.fwd, DVBoolTy, retr_x),
      ) ||
      !conv_at(
        0,
        0,
        path_ty,
        dapp_dim(triangle_x, DOne),
        dapp_typed(qb.sect, fx, DVBoolTy),
      ) {
      return false
    }
  }
  // Circle identity, fiber over the base point, target
  // `(base, loop)`: this exercises the filler construction in a
  // non-discrete type.
  let id_parts = adjoint_id_value(DVCircleTy).equiv
  let ec : DValue = DVEquiv(
    DVCircleTy,
    DVCircleTy,
    id_parts.fwd,
    id_parts.bwd,
    id_parts.sect,
    id_parts.retr,
  )
  let cparts = equiv_parts(ec, DVCircleTy, DVCircleTy)
  let base : DValue = DVCirclePoint(DZero)
  let wloop : DValue = DVPair(base, DVPathLam(d => circle_point(d)))
  let cfiber_ty = equiv_fiber_type_value(cparts, base)
  let ccenter = equiv_fiber_center_value(ec, DVCircleTy, DVCircleTy, base)
  let ccontraction = equiv_fiber_contraction_value(
    ec,
    DVCircleTy,
    DVCircleTy,
    base,
    wloop,
    2,
  )
  if !conv_at(0, 0, cfiber_ty, dapp_dim(ccontraction, DZero), ccenter) ||
    !conv_at(0, 0, cfiber_ty, dapp_dim(ccontraction, DOne), wloop) {
    return false
  }
  let mid = dapp_dim(ccontraction, DVar(0))
  let mid_fst = dfst_typed(mid, x => DVPathTy(_ => DVCircleTy, x, base))
  let mid_snd = dsnd_typed(mid, DVCircleTy, x => {
    DVPathTy(_ => DVCircleTy, x, base)
  })
  let mid_point = dapp_dim(mid_snd, DVar(1))
  if !conv_at_under_face(0, 2, FEq0(DVar(1)), DVCircleTy, mid_point, mid_fst) ||
    !conv_at_under_face(0, 2, FEq1(DVar(1)), DVCircleTy, mid_point, base) {
    return false
  }
  // Adjointification of the circle identity at the base point.
  let adj_circle = adjointify_equiv_value(ec, DVCircleTy, DVCircleTy, 2)
  let qc = adj_circle.equiv
  let retr_base = dapp_typed(qc.retr, base, DVCircleTy)
  if !conv_at(0, 0, DVCircleTy, dapp_dim(retr_base, DZero), base) ||
    !conv_at(0, 0, DVCircleTy, dapp_dim(retr_base, DOne), base) {
    return false
  }
  let triangle_base = dapp_typed(adj_circle.triangle, base, DVCircleTy)
  let cpath_ty : DValue = DVPathTy(_ => DVCircleTy, base, base)
  conv_at(
    0,
    0,
    cpath_ty,
    dapp_dim(triangle_base, DZero),
    dpath_cong_value(qc.fwd, DVCircleTy, retr_base),
  ) &&
  conv_at(
    0,
    0,
    cpath_ty,
    dapp_dim(triangle_base, DOne),
    dapp_typed(qc.sect, base, DVCircleTy),
  )
}

///|
/// Phase 11: the `lemIso` contraction and the adjointification
/// triangle verified at *generic* points -- neutral variables and
/// abstract neutral paths -- rather than only at concrete
/// representatives.  Endpoint conversion at open values is the
/// general judgment of the NbE kernel, so these checks are the
/// general theorem in the form this architecture can state it.
/// They pass for identity equivalences on discrete and on
/// non-discrete (circle) types, including with an abstract
/// neutral path in the fiber.  The circle midpoint laws are also
/// strengthened from Phase 10's under-face conversion to global
/// conversion: the interpolated point now *computes* to a
/// circle point at generic dimensions by point-valued
/// composition, and the connecting path's endpoint laws are
/// global (its generic interior has no dimension-coordinate
/// cap and stays formal -- Phase 13).
///
/// Remaining boundaries, both about conversion of formal
/// compositions at neutral data rather than about the
/// construction: (1) for an equivalence *defined by
/// eliminators* (Bool negation) at neutral points, endpoints of
/// path-valued eliminator neutrals and the eta/commuting-
/// eliminator equalities they generate are not decided by
/// neutral conversion; (2) the adjointification *triangle* at a
/// neutral variable (any type) compares two formal Kan fillers
/// whose interiors stay neutral, so it is verified here at a
/// generic-dimension circle point and at concrete points in
/// `check_general_adjointification_and_contractible_fibers`.
pub fn check_lemiso_generic_points() -> Bool {
  // Nat identity at a neutral point with refl path.
  let e_nat = equiv_id_value(DVNatTy)
  let parts_nat = equiv_parts(e_nat, DVNatTy, DVNatTy)
  let yn : DValue = DVNeutral(DNVar(0))
  let wn : DValue = DVPair(yn, DVPathLam(_ => yn))
  let fib_nat = equiv_fiber_type_value(parts_nat, yn)
  let center_nat = equiv_fiber_center_value(e_nat, DVNatTy, DVNatTy, yn)
  let contr_nat = equiv_fiber_contraction_value(
    e_nat,
    DVNatTy,
    DVNatTy,
    yn,
    wn,
    2,
  )
  if !conv_at(1, 0, fib_nat, dapp_dim(contr_nat, DZero), center_nat) ||
    !conv_at(1, 0, fib_nat, dapp_dim(contr_nat, DOne), wn) {
    return false
  }
  // Circle identity at a generic-dimension point.
  let e_circ = equiv_id_value(DVCircleTy)
  let parts_circ = equiv_parts(e_circ, DVCircleTy, DVCircleTy)
  let yc = circle_point(DVar(0))
  let wc : DValue = DVPair(yc, DVPathLam(_ => yc))
  let fib_circ = equiv_fiber_type_value(parts_circ, yc)
  let center_circ = equiv_fiber_center_value(e_circ, DVCircleTy, DVCircleTy, yc)
  let contr_circ = equiv_fiber_contraction_value(
    e_circ,
    DVCircleTy,
    DVCircleTy,
    yc,
    wc,
    2,
  )
  if !conv_at(0, 1, fib_circ, dapp_dim(contr_circ, DZero), center_circ) ||
    !conv_at(0, 1, fib_circ, dapp_dim(contr_circ, DOne), wc) {
    return false
  }
  // Circle identity at neutral points with an abstract neutral
  // path in the fiber: both endpoints of the contraction.
  let xv : DValue = DVNeutral(DNVar(0))
  let yv : DValue = DVNeutral(DNVar(1))
  let pv : DValue = DVPathLam(i => DVNeutral(DNAppDim(DNVar(2), i)))
  let wv : DValue = DVPair(xv, pv)
  let fib_v = equiv_fiber_type_value(parts_circ, yv)
  let center_v = equiv_fiber_center_value(e_circ, DVCircleTy, DVCircleTy, yv)
  let contr_v = equiv_fiber_contraction_value(
    e_circ,
    DVCircleTy,
    DVCircleTy,
    yv,
    wv,
    2,
  )
  if !conv_at(3, 0, fib_v, dapp_dim(contr_v, DZero), center_v) ||
    !conv_at(3, 0, fib_v, dapp_dim(contr_v, DOne), wv) {
    return false
  }
  // Nat identity with an abstract neutral path.
  let fib_np = equiv_fiber_type_value(parts_nat, yv)
  let center_np = equiv_fiber_center_value(e_nat, DVNatTy, DVNatTy, yv)
  let contr_np = equiv_fiber_contraction_value(
    e_nat,
    DVNatTy,
    DVNatTy,
    yv,
    wv,
    2,
  )
  if !conv_at(3, 0, fib_np, dapp_dim(contr_np, DZero), center_np) ||
    !conv_at(3, 0, fib_np, dapp_dim(contr_np, DOne), wv) {
    return false
  }
  // Circle midpoint: global endpoint laws and point-valued
  // computation at generic dimensions.
  let base : DValue = DVCirclePoint(DZero)
  let wloop : DValue = DVPair(base, DVPathLam(d => circle_point(d)))
  let contr_c = equiv_fiber_contraction_value(
    e_circ,
    DVCircleTy,
    DVCircleTy,
    base,
    wloop,
    2,
  )
  let mid = dapp_dim(contr_c, DVar(0))
  let mid_fst = dfst_typed(mid, x => DVPathTy(_ => DVCircleTy, x, base))
  let mid_snd = dsnd_typed(mid, DVCircleTy, x => {
    DVPathTy(_ => DVCircleTy, x, base)
  })
  if !conv_at(0, 2, DVCircleTy, dapp_dim(mid_snd, DZero), mid_fst) ||
    !conv_at(0, 2, DVCircleTy, dapp_dim(mid_snd, DOne), base) {
    return false
  }
  // The connecting path's generic interior stays a formal
  // composition: its box (loop tube on one face, constant
  // caps on the opposite and endpoint faces) has no cap
  // given by a single dimension coordinate, because the
  // four edge restrictions agree only as points (0 ~ 1), not
  // as coordinate expressions (Phase 13 verified selection).
  // Its endpoint laws above are nevertheless global.  The
  // interpolated midpoint itself does compute to a point.
  match force_value(mid_fst) {
    DVCirclePoint(_) => ()
    _ => return false
  }
  // Adjointification triangle at a generic-dimension circle
  // point: point-valued composition makes both endpoints
  // compute, so the triangle law converts globally there.
  let adj_c = adjointify_equiv_value(e_circ, DVCircleTy, DVCircleTy, 2)
  let qc = adj_c.equiv
  let tri_c = dapp_typed(adj_c.triangle, yc, DVCircleTy)
  let retr_c = dapp_typed(qc.retr, yc, DVCircleTy)
  let fyc = dapp_typed(qc.fwd, yc, DVCircleTy)
  let path_tyc : DValue = DVPathTy(_ => DVCircleTy, fyc, fyc)
  conv_at(
    0,
    1,
    path_tyc,
    dapp_dim(tri_c, DZero),
    dpath_cong_value(qc.fwd, DVCircleTy, retr_c),
  ) &&
  conv_at(
    0,
    1,
    path_tyc,
    dapp_dim(tri_c, DOne),
    dapp_typed(qc.sect, fyc, DVCircleTy),
  )
}
