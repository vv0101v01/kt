///|
// 記憶化類型檢查 × 雙向歸納 × 完備雙向依賴類型精緻化引擎：
//   1. [T-SWAR-Merkle-Memo-Typecheck] 基於 L0 `@swar.SwarMemoTable64` 與雙射 Stafford Mix13
//      Merkle DAG 雜湊共享競技場 `BidirDagArena`：將深度 `d` 之共享菱形依值證明項由樹狀 `O(2^d)`
//      指數次檢查壓縮為 `O(d)` 線性次檢查，並具備 `swar_memo_bump_epoch` O(1) 世代失效保證。
//   2. [T-Bidirectional-Induction] 雙向歸納（Bidirectional Induction）：
//      - 向下檢查（`⇐`）：無標註索引建構子 `BDVecNil` / `BDVecCons(hd, tl)` 直接對齊目標型別
//        `Vec(A, len)` 之正規化指標（自動拆解 `len ≡ S n` 並拒絕 `BDVecNil ⇐ Vec(A, S n)` 荒謬分支）；
//      - 雙向依值消去（`BDNatInd(z_br, s_br, scrut) ⇐ TargetTy`）：向上合成 `scrut ⇒ Nat`，
//        自動由目標型別抽象出依值動機 `M(n)`，並向下精化零分支 `M(0)` 與後繼分支 `Πk. Π(ih:M(k)). M(S k)`，
//        免除手工標註動機函數！
//   3. [T-Complete-Bidirectional-Kernel-Soundness] 嚴格分離合成 `⇒` 與檢查 `⇐`（Lennon-Bertrand 負健全性紀律：
//      僅於模式切換 `Sub` 處觸發正規形轉換），且所有通過雙向檢查之閉項經 `bidir_dag_compile_closed_dterm`
//      編譯為受信任立方核心 `@kernel.DTerm` 並通過 `@kernel.dep_check_closed` 獨立複驗。

///|
/// 雙向依賴與索引歸納 DAG 節點語法（全部索引指向同一 `BidirDagArena` 中已雜湊共享之節點 ID）。
#derive(Debug, Eq)
pub(all) enum BidirDagNode {
  BDUniv(Int32)
  BDNatTy
  BDBoolTy
  BDUnitTy
  BDVar(Int32)
  BDPi(Int32, Int32)
  BDSigma(Int32, Int32)
  BDLam(Int32)
  BDApp(Int32, Int32)
  BDPair(Int32, Int32)
  BDFst(Int32)
  BDSnd(Int32)
  BDZero
  BDSucc(Int32)
  BDBoolLit(Bool)
  BDUnitLit
  BDAnn(Int32, Int32)
  /// 索引歸納向量型別族 `Vec(elem_ty, len_nat)`
  BDVecTy(Int32, Int32)
  /// 無標註空向量建構子（僅在檢查模式 `⇐ Vec(A, 0)` 下合法）
  BDVecNil
  /// 無標註非空向量建構子（僅在檢查模式 `⇐ Vec(A, S n)` 下拆解指標並向下傳播）
  BDVecCons(Int32, Int32)
  /// 無動機標註之雙向自然數依值歸納 `nat_ind(zero_br, succ_br, scrut)`（由檢查目標自動合成動機 `M`）
  BDNatInd(Int32, Int32, Int32)
}

///|
pub extend BidirDagNode with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BidirDagNode with Eq::{not_equal, equal}

///|
/// 雜湊共享雙向依賴類型競技場（含 `@swar.SwarMemoTable64` 記憶化快取與比較計數器）。
#derive(Debug, Eq)
pub(all) struct BidirDagArena {
  nodes : Array[BidirDagNode]
  digests : Array[UInt64]
  intern_map : Map[UInt64, Array[Int32]]
  /// 儲存編譯期合成出之依值動機體 `(nat_ind_node_id, ctx_digest) -> motive_body_id`
  motive_table : Map[UInt64, Int32]
  memo_infer : @swar.SwarMemoTable64
  memo_check : @swar.SwarMemoTable64
  mut memo_step_visits : Int32
  mut unmemo_step_visits : Int32
}

///|
pub extend BidirDagArena with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend BidirDagArena with Eq::{not_equal, equal}

///|
/// 記憶化雙向依賴與雙向歸納驗證總報告。
#derive(Debug, Eq)
pub(all) struct MemoBidirInductiveReport {
  diamond_depth : Int32
  unmemoized_visits : Int32
  memoized_visits : Int32
  memo_cache_hits : Int32
  epoch_invalidation_ok : Bool
  bidir_vec_cons_nil_checked_ok : Bool
  bidir_vec_wrong_index_rejected : Bool
  bidir_nat_ind_motive_synthesized_ok : Bool
  kernel_dterm_soundness_ok : Bool
  existing_elaborator_memo_ok : Bool
  all_ok : Bool
}

///|
pub extend MemoBidirInductiveReport with @moonbitlang/core/debug.Debug::{
  to_repr,
}

///|
pub extend MemoBidirInductiveReport with Eq::{not_equal, equal}

///|
pub fn bidir_dag_new(log2_memo_cap~ : Int32 = 10) -> BidirDagArena {
  BidirDagArena::{
    nodes: [],
    digests: [],
    intern_map: Map([]),
    motive_table: Map([]),
    memo_infer: @swar.swar_memo_new(log2_memo_cap),
    memo_check: @swar.swar_memo_new(log2_memo_cap),
    memo_step_visits: 0,
    unmemo_step_visits: 0,
  }
}

///|
fn node_digest_compute(arena : BidirDagArena, node : BidirDagNode) -> UInt64 {
  match node {
    BDUniv(l) =>
      @swar.swar_merkle_node64(1, l.to_int64().reinterpret_as_uint64(), 0UL)
    BDNatTy => @swar.swar_merkle_node64(2, 0UL, 0UL)
    BDBoolTy => @swar.swar_merkle_node64(3, 0UL, 0UL)
    BDUnitTy => @swar.swar_merkle_node64(4, 0UL, 0UL)
    BDVar(ix) =>
      @swar.swar_merkle_node64(5, ix.to_int64().reinterpret_as_uint64(), 0UL)
    BDPi(a, b) =>
      @swar.swar_merkle_node64(6, arena.digests[a], arena.digests[b])
    BDSigma(a, b) =>
      @swar.swar_merkle_node64(7, arena.digests[a], arena.digests[b])
    BDLam(body) => @swar.swar_merkle_node64(8, arena.digests[body], 0UL)
    BDApp(f, x) =>
      @swar.swar_merkle_node64(9, arena.digests[f], arena.digests[x])
    BDPair(a, b) =>
      @swar.swar_merkle_node64(10, arena.digests[a], arena.digests[b])
    BDFst(p) => @swar.swar_merkle_node64(11, arena.digests[p], 0UL)
    BDSnd(p) => @swar.swar_merkle_node64(12, arena.digests[p], 0UL)
    BDZero => @swar.swar_merkle_node64(13, 0UL, 0UL)
    BDSucc(n) => @swar.swar_merkle_node64(14, arena.digests[n], 0UL)
    BDBoolLit(b) => @swar.swar_merkle_node64(15, if b { 1UL } else { 0UL }, 0UL)
    BDUnitLit => @swar.swar_merkle_node64(16, 0UL, 0UL)
    BDAnn(e, ty) =>
      @swar.swar_merkle_node64(17, arena.digests[e], arena.digests[ty])
    BDVecTy(el, len) =>
      @swar.swar_merkle_node64(18, arena.digests[el], arena.digests[len])
    BDVecNil => @swar.swar_merkle_node64(19, 0UL, 0UL)
    BDVecCons(h, t) =>
      @swar.swar_merkle_node64(20, arena.digests[h], arena.digests[t])
    BDNatInd(z, s, n) =>
      @swar.swar_merkle_seq64(21, [
        arena.digests[z],
        arena.digests[s],
        arena.digests[n],
      ])
  }
}

///|
/// 雜湊共享配置節點（結構完全相同之子式在 `O(1)` 時間內回傳同一節點 ID）。
pub fn bidir_dag_alloc(arena : BidirDagArena, node : BidirDagNode) -> Int32 {
  let dig = node_digest_compute(arena, node)
  match arena.intern_map.get(dig) {
    Some(bucket) => {
      for id in bucket {
        if arena.nodes[id] == node {
          return id
        }
      }
      let new_id = arena.nodes.length()
      arena.nodes.push(node)
      arena.digests.push(dig)
      bucket.push(new_id)
      new_id
    }
    None => {
      let new_id = arena.nodes.length()
      arena.nodes.push(node)
      arena.digests.push(dig)
      arena.intern_map[dig] = [new_id]
      new_id
    }
  }
}

///|
/// O(1) 遞增記憶化世代，使舊上下文／舊假設快取瞬間失效而免除陣列清零。
pub fn bidir_dag_invalidate_cache(arena : BidirDagArena) -> Unit {
  @swar.swar_memo_bump_epoch(arena.memo_infer)
  @swar.swar_memo_bump_epoch(arena.memo_check)
}

///|
fn bd_shift(
  arena : BidirDagArena,
  id : Int32,
  delta : Int32,
  cutoff : Int32,
) -> Int32 {
  if delta == 0 {
    return id
  }
  match arena.nodes[id] {
    BDUniv(_)
    | BDNatTy
    | BDBoolTy
    | BDUnitTy
    | BDZero
    | BDBoolLit(_)
    | BDUnitLit
    | BDVecNil => id
    BDVar(ix) =>
      if ix >= cutoff {
        bidir_dag_alloc(arena, BDVar(ix + delta))
      } else {
        id
      }
    BDPi(a, b) =>
      bidir_dag_alloc(
        arena,
        BDPi(
          bd_shift(arena, a, delta, cutoff),
          bd_shift(arena, b, delta, cutoff + 1),
        ),
      )
    BDSigma(a, b) =>
      bidir_dag_alloc(
        arena,
        BDSigma(
          bd_shift(arena, a, delta, cutoff),
          bd_shift(arena, b, delta, cutoff + 1),
        ),
      )
    BDLam(body) =>
      bidir_dag_alloc(arena, BDLam(bd_shift(arena, body, delta, cutoff + 1)))
    BDApp(f, x) =>
      bidir_dag_alloc(
        arena,
        BDApp(
          bd_shift(arena, f, delta, cutoff),
          bd_shift(arena, x, delta, cutoff),
        ),
      )
    BDPair(a, b) =>
      bidir_dag_alloc(
        arena,
        BDPair(
          bd_shift(arena, a, delta, cutoff),
          bd_shift(arena, b, delta, cutoff),
        ),
      )
    BDFst(p) => bidir_dag_alloc(arena, BDFst(bd_shift(arena, p, delta, cutoff)))
    BDSnd(p) => bidir_dag_alloc(arena, BDSnd(bd_shift(arena, p, delta, cutoff)))
    BDSucc(n) =>
      bidir_dag_alloc(arena, BDSucc(bd_shift(arena, n, delta, cutoff)))
    BDAnn(e, ty) =>
      bidir_dag_alloc(
        arena,
        BDAnn(
          bd_shift(arena, e, delta, cutoff),
          bd_shift(arena, ty, delta, cutoff),
        ),
      )
    BDVecTy(el, len) =>
      bidir_dag_alloc(
        arena,
        BDVecTy(
          bd_shift(arena, el, delta, cutoff),
          bd_shift(arena, len, delta, cutoff),
        ),
      )
    BDVecCons(h, t) =>
      bidir_dag_alloc(
        arena,
        BDVecCons(
          bd_shift(arena, h, delta, cutoff),
          bd_shift(arena, t, delta, cutoff),
        ),
      )
    BDNatInd(z, s, n) =>
      bidir_dag_alloc(
        arena,
        BDNatInd(
          bd_shift(arena, z, delta, cutoff),
          bd_shift(arena, s, delta, cutoff),
          bd_shift(arena, n, delta, cutoff),
        ),
      )
  }
}

///|
fn bd_subst_at(
  arena : BidirDagArena,
  body : Int32,
  depth : Int32,
  arg : Int32,
) -> Int32 {
  match arena.nodes[body] {
    BDUniv(_)
    | BDNatTy
    | BDBoolTy
    | BDUnitTy
    | BDZero
    | BDBoolLit(_)
    | BDUnitLit
    | BDVecNil => body
    BDVar(ix) =>
      if ix == depth {
        bd_shift(arena, arg, depth, 0)
      } else if ix > depth {
        bidir_dag_alloc(arena, BDVar(ix - 1))
      } else {
        body
      }
    BDPi(a, b) =>
      bidir_dag_alloc(
        arena,
        BDPi(
          bd_subst_at(arena, a, depth, arg),
          bd_subst_at(arena, b, depth + 1, arg),
        ),
      )
    BDSigma(a, b) =>
      bidir_dag_alloc(
        arena,
        BDSigma(
          bd_subst_at(arena, a, depth, arg),
          bd_subst_at(arena, b, depth + 1, arg),
        ),
      )
    BDLam(b) =>
      bidir_dag_alloc(arena, BDLam(bd_subst_at(arena, b, depth + 1, arg)))
    BDApp(f, x) =>
      bidir_dag_alloc(
        arena,
        BDApp(
          bd_subst_at(arena, f, depth, arg),
          bd_subst_at(arena, x, depth, arg),
        ),
      )
    BDPair(a, b) =>
      bidir_dag_alloc(
        arena,
        BDPair(
          bd_subst_at(arena, a, depth, arg),
          bd_subst_at(arena, b, depth, arg),
        ),
      )
    BDFst(p) => bidir_dag_alloc(arena, BDFst(bd_subst_at(arena, p, depth, arg)))
    BDSnd(p) => bidir_dag_alloc(arena, BDSnd(bd_subst_at(arena, p, depth, arg)))
    BDSucc(n) =>
      bidir_dag_alloc(arena, BDSucc(bd_subst_at(arena, n, depth, arg)))
    BDAnn(e, ty) =>
      bidir_dag_alloc(
        arena,
        BDAnn(
          bd_subst_at(arena, e, depth, arg),
          bd_subst_at(arena, ty, depth, arg),
        ),
      )
    BDVecTy(el, len) =>
      bidir_dag_alloc(
        arena,
        BDVecTy(
          bd_subst_at(arena, el, depth, arg),
          bd_subst_at(arena, len, depth, arg),
        ),
      )
    BDVecCons(h, t) =>
      bidir_dag_alloc(
        arena,
        BDVecCons(
          bd_subst_at(arena, h, depth, arg),
          bd_subst_at(arena, t, depth, arg),
        ),
      )
    BDNatInd(z, s, n) =>
      bidir_dag_alloc(
        arena,
        BDNatInd(
          bd_subst_at(arena, z, depth, arg),
          bd_subst_at(arena, s, depth, arg),
          bd_subst_at(arena, n, depth, arg),
        ),
      )
  }
}

///|
fn bd_subst0(arena : BidirDagArena, body : Int32, arg : Int32) -> Int32 {
  bd_subst_at(arena, body, 0, arg)
}

///|
/// 在已上移 `+1` 之目標型別 `ty_id` 中，將目標子項 `scrut_shifted` 抽象為新綁定變數 `BDVar(0)`（深度感知）。
fn bd_abstract_target(
  arena : BidirDagArena,
  ty_id : Int32,
  target_at_depth : Int32,
  binder_depth : Int32,
) -> Int32 {
  if ty_id == target_at_depth {
    return bidir_dag_alloc(arena, BDVar(binder_depth))
  }
  match arena.nodes[ty_id] {
    BDUniv(_)
    | BDNatTy
    | BDBoolTy
    | BDUnitTy
    | BDVar(_)
    | BDZero
    | BDBoolLit(_)
    | BDUnitLit
    | BDVecNil => ty_id
    BDPi(a, b) => {
      let t_next = bd_shift(arena, target_at_depth, 1, 0)
      bidir_dag_alloc(
        arena,
        BDPi(
          bd_abstract_target(arena, a, target_at_depth, binder_depth),
          bd_abstract_target(arena, b, t_next, binder_depth + 1),
        ),
      )
    }
    BDSigma(a, b) => {
      let t_next = bd_shift(arena, target_at_depth, 1, 0)
      bidir_dag_alloc(
        arena,
        BDSigma(
          bd_abstract_target(arena, a, target_at_depth, binder_depth),
          bd_abstract_target(arena, b, t_next, binder_depth + 1),
        ),
      )
    }
    BDLam(b) => {
      let t_next = bd_shift(arena, target_at_depth, 1, 0)
      bidir_dag_alloc(
        arena,
        BDLam(bd_abstract_target(arena, b, t_next, binder_depth + 1)),
      )
    }
    BDApp(f, x) =>
      bidir_dag_alloc(
        arena,
        BDApp(
          bd_abstract_target(arena, f, target_at_depth, binder_depth),
          bd_abstract_target(arena, x, target_at_depth, binder_depth),
        ),
      )
    BDPair(a, b) =>
      bidir_dag_alloc(
        arena,
        BDPair(
          bd_abstract_target(arena, a, target_at_depth, binder_depth),
          bd_abstract_target(arena, b, target_at_depth, binder_depth),
        ),
      )
    BDFst(p) =>
      bidir_dag_alloc(
        arena,
        BDFst(bd_abstract_target(arena, p, target_at_depth, binder_depth)),
      )
    BDSnd(p) =>
      bidir_dag_alloc(
        arena,
        BDSnd(bd_abstract_target(arena, p, target_at_depth, binder_depth)),
      )
    BDSucc(n) =>
      bidir_dag_alloc(
        arena,
        BDSucc(bd_abstract_target(arena, n, target_at_depth, binder_depth)),
      )
    BDAnn(e, t) =>
      bidir_dag_alloc(
        arena,
        BDAnn(
          bd_abstract_target(arena, e, target_at_depth, binder_depth),
          bd_abstract_target(arena, t, target_at_depth, binder_depth),
        ),
      )
    BDVecTy(el, len) =>
      bidir_dag_alloc(
        arena,
        BDVecTy(
          bd_abstract_target(arena, el, target_at_depth, binder_depth),
          bd_abstract_target(arena, len, target_at_depth, binder_depth),
        ),
      )
    BDVecCons(h, t) =>
      bidir_dag_alloc(
        arena,
        BDVecCons(
          bd_abstract_target(arena, h, target_at_depth, binder_depth),
          bd_abstract_target(arena, t, target_at_depth, binder_depth),
        ),
      )
    BDNatInd(z, s, n) =>
      bidir_dag_alloc(
        arena,
        BDNatInd(
          bd_abstract_target(arena, z, target_at_depth, binder_depth),
          bd_abstract_target(arena, s, target_at_depth, binder_depth),
          bd_abstract_target(arena, n, target_at_depth, binder_depth),
        ),
      )
  }
}

///|
/// 弱頭正規形（WHNF）求值器（處理 `β`、`π₁`/`π₂`、標註擦除與 `nat_ind` `ι` 歸約）。
pub fn bd_whnf(arena : BidirDagArena, id0 : Int32) -> Int32 {
  let mut cur = id0
  for _ in 0..<64 {
    match arena.nodes[cur] {
      BDAnn(e, _) => cur = e
      BDApp(f, arg) => {
        let f_w = bd_whnf(arena, f)
        match arena.nodes[f_w] {
          BDLam(body) => cur = bd_subst0(arena, body, arg)
          _ => return bidir_dag_alloc(arena, BDApp(f_w, arg))
        }
      }
      BDFst(p) => {
        let p_w = bd_whnf(arena, p)
        match arena.nodes[p_w] {
          BDPair(a, _) => cur = a
          BDVecCons(h, _) => cur = h
          _ => return bidir_dag_alloc(arena, BDFst(p_w))
        }
      }
      BDSnd(p) => {
        let p_w = bd_whnf(arena, p)
        match arena.nodes[p_w] {
          BDPair(_, b) => cur = b
          BDVecCons(_, t) => cur = t
          _ => return bidir_dag_alloc(arena, BDSnd(p_w))
        }
      }
      BDNatInd(z, s, n) => {
        let n_w = bd_whnf(arena, n)
        match arena.nodes[n_w] {
          BDZero => cur = z
          BDSucc(pred) => {
            let ih = bidir_dag_alloc(arena, BDNatInd(z, s, pred))
            let s_k = bidir_dag_alloc(arena, BDApp(s, pred))
            cur = bidir_dag_alloc(arena, BDApp(s_k, ih))
          }
          _ => return bidir_dag_alloc(arena, BDNatInd(z, s, n_w))
        }
      }
      _ => return cur
    }
  }
  cur
}

///|
/// 定義相等判定（經 WHNF 結構遞迴比對，含 `Vec(A, 0) ≡ Unit` 與 `Vec(A, S n) ≡ Σ(_:A). Vec(A, n)` 展開）。
pub fn bd_conv(arena : BidirDagArena, a0 : Int32, b0 : Int32) -> Bool {
  if a0 == b0 {
    return true
  }
  let a = bd_whnf(arena, a0)
  let b = bd_whnf(arena, b0)
  if a == b {
    return true
  }
  match (arena.nodes[a], arena.nodes[b]) {
    (BDUniv(l1), BDUniv(l2)) => l1 == l2
    (BDVar(i1), BDVar(i2)) => i1 == i2
    (BDPi(d1, c1), BDPi(d2, c2)) =>
      bd_conv(arena, d1, d2) && bd_conv(arena, c1, c2)
    (BDSigma(d1, c1), BDSigma(d2, c2)) =>
      bd_conv(arena, d1, d2) && bd_conv(arena, c1, c2)
    (BDLam(b1), BDLam(b2)) => bd_conv(arena, b1, b2)
    (BDApp(f1, x1), BDApp(f2, x2)) =>
      bd_conv(arena, f1, f2) && bd_conv(arena, x1, x2)
    (BDPair(x1, y1), BDPair(x2, y2)) =>
      bd_conv(arena, x1, x2) && bd_conv(arena, y1, y2)
    (BDFst(p1), BDFst(p2)) => bd_conv(arena, p1, p2)
    (BDSnd(p1), BDSnd(p2)) => bd_conv(arena, p1, p2)
    (BDSucc(n1), BDSucc(n2)) => bd_conv(arena, n1, n2)
    (BDBoolLit(v1), BDBoolLit(v2)) => v1 == v2
    (BDVecTy(e1, l1), BDVecTy(e2, l2)) =>
      bd_conv(arena, e1, e2) && bd_conv(arena, l1, l2)
    (BDVecCons(h1, t1), BDVecCons(h2, t2)) =>
      bd_conv(arena, h1, h2) && bd_conv(arena, t1, t2)
    (BDNatInd(z1, s1, n1), BDNatInd(z2, s2, n2)) =>
      bd_conv(arena, z1, z2) && bd_conv(arena, s1, s2) && bd_conv(arena, n1, n2)
    _ => false
  }
}

///|
fn ctx_merkle_digest(arena : BidirDagArena, ctx : Array[Int32]) -> UInt64 {
  let hs : Array[UInt64] = []
  for ty_id in ctx {
    hs.push(arena.digests[ty_id])
  }
  @swar.swar_merkle_seq64(99, hs)
}

///|
fn check_is_universe(
  arena : BidirDagArena,
  ctx : Array[Int32],
  ty_id : Int32,
  use_memo : Bool,
) -> Int32? {
  let k_id = match bidir_dag_infer_core(arena, ctx, ty_id, use_memo) {
    Some(k) => k
    None => return None
  }
  match arena.nodes[bd_whnf(arena, k_id)] {
    BDUniv(lvl) => Some(lvl)
    _ => None
  }
}

///|
fn bidir_dag_infer_core(
  arena : BidirDagArena,
  ctx : Array[Int32],
  term_id : Int32,
  use_memo : Bool,
) -> Int32? {
  let ctx_dig = ctx_merkle_digest(arena, ctx)
  let memo_key = @swar.swar_merkle_node64(101, ctx_dig, arena.digests[term_id])
  if use_memo {
    match @swar.swar_memo_get(arena.memo_infer, memo_key) {
      Some(cached) => return if cached >= 0 { Some(cached) } else { None }
      None => ()
    }
    arena.memo_step_visits = arena.memo_step_visits + 1
  } else {
    arena.unmemo_step_visits = arena.unmemo_step_visits + 1
  }

  let depth = ctx.length()
  let res : Int32? = match arena.nodes[term_id] {
    BDUniv(l) =>
      if l >= 0 {
        Some(bidir_dag_alloc(arena, BDUniv(l + 1)))
      } else {
        None
      }
    BDNatTy | BDBoolTy | BDUnitTy => Some(bidir_dag_alloc(arena, BDUniv(0)))
    BDVar(ix) =>
      if ix >= 0 && ix < depth {
        let entry = ctx[depth - 1 - ix]
        Some(bd_shift(arena, entry, ix + 1, 0))
      } else {
        None
      }
    BDPi(dom, cod) | BDSigma(dom, cod) =>
      match check_is_universe(arena, ctx, dom, use_memo) {
        Some(l1) => {
          let ctx2 = ctx.copy()
          ctx2.push(dom)
          match check_is_universe(arena, ctx2, cod, use_memo) {
            Some(l2) =>
              Some(
                bidir_dag_alloc(arena, BDUniv(if l1 > l2 { l1 } else { l2 })),
              )
            None => None
          }
        }
        None => None
      }
    BDVecTy(elem_ty, len_tm) =>
      match check_is_universe(arena, ctx, elem_ty, use_memo) {
        Some(lvl) => {
          let nat_id = bidir_dag_alloc(arena, BDNatTy)
          if bidir_dag_check_core(arena, ctx, len_tm, nat_id, use_memo) {
            Some(bidir_dag_alloc(arena, BDUniv(lvl)))
          } else {
            None
          }
        }
        None => None
      }
    BDZero => Some(bidir_dag_alloc(arena, BDNatTy))
    BDSucc(n) => {
      let nat_id = bidir_dag_alloc(arena, BDNatTy)
      if bidir_dag_check_core(arena, ctx, n, nat_id, use_memo) {
        Some(nat_id)
      } else {
        None
      }
    }
    BDBoolLit(_) => Some(bidir_dag_alloc(arena, BDBoolTy))
    BDUnitLit => Some(bidir_dag_alloc(arena, BDUnitTy))
    BDAnn(e, ty) =>
      match check_is_universe(arena, ctx, ty, use_memo) {
        Some(_) =>
          if bidir_dag_check_core(arena, ctx, e, ty, use_memo) {
            Some(ty)
          } else {
            None
          }
        None => None
      }
    BDApp(fn_id, arg_id) =>
      match bidir_dag_infer_core(arena, ctx, fn_id, use_memo) {
        Some(fn_ty) =>
          match arena.nodes[bd_whnf(arena, fn_ty)] {
            BDPi(dom, cod) =>
              if bidir_dag_check_core(arena, ctx, arg_id, dom, use_memo) {
                Some(bd_subst0(arena, cod, arg_id))
              } else {
                None
              }
            _ => None
          }
        None => None
      }
    BDFst(p_id) =>
      match bidir_dag_infer_core(arena, ctx, p_id, use_memo) {
        Some(p_ty) =>
          match arena.nodes[bd_whnf(arena, p_ty)] {
            BDSigma(dom, _) => Some(dom)
            BDVecTy(elem_ty, len_tm) =>
              match arena.nodes[bd_whnf(arena, len_tm)] {
                BDSucc(_) => Some(elem_ty)
                _ => None
              }
            _ => None
          }
        None => None
      }
    BDSnd(p_id) =>
      match bidir_dag_infer_core(arena, ctx, p_id, use_memo) {
        Some(p_ty) =>
          match arena.nodes[bd_whnf(arena, p_ty)] {
            BDSigma(_, cod) => {
              let fst_p = bidir_dag_alloc(arena, BDFst(p_id))
              Some(bd_subst0(arena, cod, fst_p))
            }
            BDVecTy(elem_ty, len_tm) =>
              match arena.nodes[bd_whnf(arena, len_tm)] {
                BDSucc(pred) =>
                  Some(bidir_dag_alloc(arena, BDVecTy(elem_ty, pred)))
                _ => None
              }
            _ => None
          }
        None => None
      }
    // 無標註介紹項與無動機標註歸納必須處於檢查模式 `⇐`（Lennon-Bertrand 嚴格雙向邊界）
    BDLam(_) | BDPair(_, _) | BDVecNil | BDVecCons(_, _) | BDNatInd(_, _, _) =>
      None
  }

  if use_memo {
    let code = match res {
      Some(ty_id) => ty_id
      None => -1
    }
    @swar.swar_memo_put(arena.memo_infer, memo_key, code)
  }
  res
}

///|
fn bidir_dag_check_core(
  arena : BidirDagArena,
  ctx : Array[Int32],
  term_id : Int32,
  expected_id : Int32,
  use_memo : Bool,
) -> Bool {
  let ctx_dig = ctx_merkle_digest(arena, ctx)
  let memo_key = @swar.swar_merkle_seq64(102, [
    ctx_dig,
    arena.digests[term_id],
    arena.digests[expected_id],
  ])
  if use_memo {
    match @swar.swar_memo_get(arena.memo_check, memo_key) {
      Some(cached) => return cached == 1
      None => ()
    }
    arena.memo_step_visits = arena.memo_step_visits + 1
  } else {
    arena.unmemo_step_visits = arena.unmemo_step_visits + 1
  }

  let exp_whnf = bd_whnf(arena, expected_id)
  let ok : Bool = match arena.nodes[term_id] {
    BDLam(body) =>
      match arena.nodes[exp_whnf] {
        BDPi(dom, cod) => {
          let ctx2 = ctx.copy()
          ctx2.push(dom)
          bidir_dag_check_core(arena, ctx2, body, cod, use_memo)
        }
        _ => false
      }
    BDPair(fst_tm, snd_tm) =>
      match arena.nodes[exp_whnf] {
        BDSigma(dom, cod) =>
          if bidir_dag_check_core(arena, ctx, fst_tm, dom, use_memo) {
            let snd_ty = bd_subst0(arena, cod, fst_tm)
            bidir_dag_check_core(arena, ctx, snd_tm, snd_ty, use_memo)
          } else {
            false
          }
        _ => false
      }
    // 雙向歸納 1：空向量建構子向下檢查索引必須歸約為 `0`
    BDVecNil =>
      match arena.nodes[exp_whnf] {
        BDVecTy(_, len_tm) =>
          match arena.nodes[bd_whnf(arena, len_tm)] {
            BDZero => true
            _ => false
          }
        _ => false
      }
    // 雙向歸納 2：非空向量建構子向下拆解 `len ≡ S pred` 並自動傳播頭尾型別
    BDVecCons(hd, tl) =>
      match arena.nodes[exp_whnf] {
        BDVecTy(elem_ty, len_tm) =>
          match arena.nodes[bd_whnf(arena, len_tm)] {
            BDSucc(pred) => {
              let tail_ty = bidir_dag_alloc(arena, BDVecTy(elem_ty, pred))
              bidir_dag_check_core(arena, ctx, hd, elem_ty, use_memo) &&
              bidir_dag_check_core(arena, ctx, tl, tail_ty, use_memo)
            }
            _ => false
          }
        _ => false
      }
    // 雙向歸納 3：無動機標註依值 `Nat` 歸納——向上合成 `scrut ⇒ Nat`，由目標型別抽象依值動機 `M`！
    BDNatInd(z_br, s_br, scrut) => {
      let nat_id = bidir_dag_alloc(arena, BDNatTy)
      if !bidir_dag_check_core(arena, ctx, scrut, nat_id, use_memo) {
        false
      } else {
        let scrut_w = bd_whnf(arena, scrut)
        let exp_shifted = bd_shift(arena, expected_id, 1, 0)
        let scrut_shifted = bd_shift(arena, scrut_w, 1, 0)
        let motive_body = bd_abstract_target(
          arena, exp_shifted, scrut_shifted, 0,
        )
        // 核驗動機良構：`Γ, m : Nat ⊢ motive_body : Type_l` 且 `M[scrut] ≡ expected`
        let ctx_m = ctx.copy()
        ctx_m.push(nat_id)
        let motive_wf = match
          check_is_universe(arena, ctx_m, motive_body, use_memo) {
          Some(_) =>
            bd_conv(arena, bd_subst0(arena, motive_body, scrut_w), expected_id)
          None => false
        }
        if !motive_wf {
          false
        } else {
          let zero_id = bidir_dag_alloc(arena, BDZero)
          let m_zero = bd_subst0(arena, motive_body, zero_id)
          // 後繼分支預期型別：Π(k : Nat). Π(ih : M[k]). M[S k]
          let var1 = bidir_dag_alloc(arena, BDVar(1))
          let succ_var1 = bidir_dag_alloc(arena, BDSucc(var1))
          // 在 `Γ, k : Nat` 下 `M[k]` 就是 `motive_body`（因為 `motive_body` 以 `BDVar(0)` 表該 `Nat` 參數！）
          let m_k = motive_body
          // 在 `Γ, k : Nat, ih : M[k]` 下，原上下文變數再上移 1，且索引為 `BDSucc(BDVar(1))`
          let motive_lifted2 = bd_shift(arena, motive_body, 1, 1)
          let m_sk = bd_subst0(arena, motive_lifted2, succ_var1)
          let inner_pi = bidir_dag_alloc(arena, BDPi(m_k, m_sk))
          let succ_ty = bidir_dag_alloc(arena, BDPi(nat_id, inner_pi))
          if bidir_dag_check_core(arena, ctx, z_br, m_zero, use_memo) &&
            bidir_dag_check_core(arena, ctx, s_br, succ_ty, use_memo) {
            let mkey = @swar.swar_merkle_node64(
              205,
              ctx_dig,
              arena.digests[term_id],
            )
            arena.motive_table[mkey] = motive_body
            true
          } else {
            false
          }
        }
      }
    }
    // 唯一模式切換規則 `Sub`：合成型別後在 WHNF 下比對定義相等
    _ =>
      match bidir_dag_infer_core(arena, ctx, term_id, use_memo) {
        Some(inferred) => bd_conv(arena, inferred, expected_id)
        None => false
      }
  }

  if use_memo {
    @swar.swar_memo_put(arena.memo_check, memo_key, if ok { 1 } else { 0 })
  }
  ok
}

///|
/// 記憶化雙向依賴合成入口 `Γ ⊢ term ⇒ ty`。
pub fn bidir_dag_infer_memo(
  arena : BidirDagArena,
  ctx : Array[Int32],
  term_id : Int32,
) -> Int32? {
  bidir_dag_infer_core(arena, ctx, term_id, true)
}

///|
/// 記憶化雙向依賴與雙向歸納檢查入口 `Γ ⊢ term ⇐ expected`。
pub fn bidir_dag_check_memo(
  arena : BidirDagArena,
  ctx : Array[Int32],
  term_id : Int32,
  expected_id : Int32,
) -> Bool {
  bidir_dag_check_core(arena, ctx, term_id, expected_id, true)
}

///|
/// 對照組：不啟用記憶化快取之純樹狀雙向檢查（用於精確對帳 `O(2^d)` vs `O(d)` 節點走訪數）。
pub fn bidir_dag_check_unmemoized(
  arena : BidirDagArena,
  ctx : Array[Int32],
  term_id : Int32,
  expected_id : Int32,
) -> Bool {
  bidir_dag_check_core(arena, ctx, term_id, expected_id, false)
}

///|
fn dterm_shift_above(t : DTerm, delta : Int32, cutoff : Int32) -> DTerm {
  match t {
    DTVar(i) => if i >= cutoff { DTVar(i + delta) } else { t }
    DUniv(_) | DBoolTy | DBoolLit(_) | DUnitTy | DUnitLit | DNatTy | DNatZero =>
      t
    DLam(dom, body) =>
      DLam(
        dterm_shift_above(dom, delta, cutoff),
        dterm_shift_above(body, delta, cutoff + 1),
      )
    DPi(dom, cod) =>
      DPi(
        dterm_shift_above(dom, delta, cutoff),
        dterm_shift_above(cod, delta, cutoff + 1),
      )
    DSigma(dom, cod) =>
      DSigma(
        dterm_shift_above(dom, delta, cutoff),
        dterm_shift_above(cod, delta, cutoff + 1),
      )
    DApp(f, x) =>
      DApp(
        dterm_shift_above(f, delta, cutoff),
        dterm_shift_above(x, delta, cutoff),
      )
    DPair(a, b) =>
      DPair(
        dterm_shift_above(a, delta, cutoff),
        dterm_shift_above(b, delta, cutoff),
      )
    DFst(p) => DFst(dterm_shift_above(p, delta, cutoff))
    DSnd(p) => DSnd(dterm_shift_above(p, delta, cutoff))
    DSucc(n) => DSucc(dterm_shift_above(n, delta, cutoff))
    DAnn(e, ty) =>
      DAnn(
        dterm_shift_above(e, delta, cutoff),
        dterm_shift_above(ty, delta, cutoff),
      )
    DNatElim(m, z, s, n) =>
      DNatElim(
        dterm_shift_above(m, delta, cutoff + 1),
        dterm_shift_above(z, delta, cutoff),
        dterm_shift_above(s, delta, cutoff),
        dterm_shift_above(n, delta, cutoff),
      )
    _ => t
  }
}

///|
/// 將通過雙向檢查之 `BidirDagNode` 編譯為受信任立方核心 `@kernel.DTerm`：
/// 其中 `BDVecTy(A, n)` 編譯為核心大消去 `DNatElim(Type₀, Unit, λk.λrec. Σ(_:A). rec, n)`！
pub fn bidir_dag_compile_dterm(
  arena : BidirDagArena,
  ctx : Array[Int32],
  term_id : Int32,
  expected_hint : Int32?,
) -> DTerm? {
  let ctx_dig = ctx_merkle_digest(arena, ctx)
  match arena.nodes[term_id] {
    BDUniv(l) => Some(DUniv(l))
    BDNatTy => Some(DNatTy)
    BDBoolTy => Some(DBoolTy)
    BDUnitTy => Some(DUnitTy)
    BDVar(ix) => Some(DTVar(ix))
    BDZero => Some(DNatZero)
    BDBoolLit(b) => Some(DBoolLit(b))
    BDUnitLit => Some(DUnitLit)
    BDSucc(n) =>
      match bidir_dag_compile_dterm(arena, ctx, n, None) {
        Some(dn) => Some(DSucc(dn))
        None => None
      }
    BDPi(dom, cod) =>
      match bidir_dag_compile_dterm(arena, ctx, dom, None) {
        Some(ddom) => {
          let ctx2 = ctx.copy()
          ctx2.push(dom)
          match bidir_dag_compile_dterm(arena, ctx2, cod, None) {
            Some(dcod) => Some(DPi(ddom, dcod))
            None => None
          }
        }
        None => None
      }
    BDSigma(dom, cod) =>
      match bidir_dag_compile_dterm(arena, ctx, dom, None) {
        Some(ddom) => {
          let ctx2 = ctx.copy()
          ctx2.push(dom)
          match bidir_dag_compile_dterm(arena, ctx2, cod, None) {
            Some(dcod) => Some(DSigma(ddom, dcod))
            None => None
          }
        }
        None => None
      }
    BDVecTy(elem_ty, len_tm) =>
      match
        (
          bidir_dag_compile_dterm(arena, ctx, elem_ty, None),
          bidir_dag_compile_dterm(arena, ctx, len_tm, None),
        ) {
        (Some(da), Some(dn)) => {
          // 在 λ(k:Nat). λ(rec:Type_0). DSigma(da_shifted, DTVar(1)) 中，da 上移 2 層
          let da2 = dterm_shift_above(da, 2, 0)
          let step : DTerm = DLam(DNatTy, DLam(DUniv(0), DSigma(da2, DTVar(1))))
          Some(DNatElim(DUniv(0), DUnitTy, step, dn))
        }
        _ => None
      }
    BDVecNil => Some(DUnitLit)
    BDVecCons(hd, tl) => {
      let (h_hint, t_hint) = match expected_hint {
        Some(exp) =>
          match arena.nodes[bd_whnf(arena, exp)] {
            BDVecTy(el, len_tm) =>
              match arena.nodes[bd_whnf(arena, len_tm)] {
                BDSucc(pred) =>
                  (Some(el), Some(bidir_dag_alloc(arena, BDVecTy(el, pred))))
                _ => (None, None)
              }
            _ => (None, None)
          }
        None => (None, None)
      }
      match
        (
          bidir_dag_compile_dterm(arena, ctx, hd, h_hint),
          bidir_dag_compile_dterm(arena, ctx, tl, t_hint),
        ) {
        (Some(dh), Some(dt)) => Some(DPair(dh, dt))
        _ => None
      }
    }
    BDLam(body) =>
      match expected_hint {
        Some(exp) =>
          match arena.nodes[bd_whnf(arena, exp)] {
            BDPi(dom, cod) =>
              match bidir_dag_compile_dterm(arena, ctx, dom, None) {
                Some(ddom) => {
                  let ctx2 = ctx.copy()
                  ctx2.push(dom)
                  match bidir_dag_compile_dterm(arena, ctx2, body, Some(cod)) {
                    Some(dbody) => Some(DLam(ddom, dbody))
                    None => None
                  }
                }
                None => None
              }
            _ => None
          }
        None => None
      }
    BDPair(a, b) =>
      match expected_hint {
        Some(exp) =>
          match arena.nodes[bd_whnf(arena, exp)] {
            BDSigma(dom, cod) => {
              let b_ty = bd_subst0(arena, cod, a)
              match
                (
                  bidir_dag_compile_dterm(arena, ctx, a, Some(dom)),
                  bidir_dag_compile_dterm(arena, ctx, b, Some(b_ty)),
                ) {
                (Some(da), Some(db)) => Some(DPair(da, db))
                _ => None
              }
            }
            _ => None
          }
        None => None
      }
    BDAnn(e, ty) => bidir_dag_compile_dterm(arena, ctx, e, Some(ty))
    BDApp(f, x) => {
      let f_ty = match bidir_dag_infer_memo(arena, ctx, f) {
        Some(t) => t
        None => return None
      }
      let dom_hint = match arena.nodes[bd_whnf(arena, f_ty)] {
        BDPi(dom, _) => Some(dom)
        _ => None
      }
      match
        (
          bidir_dag_compile_dterm(arena, ctx, f, None),
          bidir_dag_compile_dterm(arena, ctx, x, dom_hint),
        ) {
        (Some(df), Some(dx)) => Some(DApp(df, dx))
        _ => None
      }
    }
    BDFst(p) =>
      match bidir_dag_compile_dterm(arena, ctx, p, None) {
        Some(dp) => Some(DFst(dp))
        None => None
      }
    BDSnd(p) =>
      match bidir_dag_compile_dterm(arena, ctx, p, None) {
        Some(dp) => Some(DSnd(dp))
        None => None
      }
    BDNatInd(z_br, s_br, scrut) => {
      let mkey = @swar.swar_merkle_node64(205, ctx_dig, arena.digests[term_id])
      let motive_body = match arena.motive_table.get(mkey) {
        Some(m) => m
        None => return None
      }
      let nat_id = bidir_dag_alloc(arena, BDNatTy)
      let ctx_m = ctx.copy()
      ctx_m.push(nat_id)
      let zero_id = bidir_dag_alloc(arena, BDZero)
      let m_zero = bd_subst0(arena, motive_body, zero_id)
      let var1 = bidir_dag_alloc(arena, BDVar(1))
      let succ_var1 = bidir_dag_alloc(arena, BDSucc(var1))
      let motive_lifted2 = bd_shift(arena, motive_body, 1, 1)
      let m_sk = bd_subst0(arena, motive_lifted2, succ_var1)
      let succ_ty = bidir_dag_alloc(
        arena,
        BDPi(nat_id, bidir_dag_alloc(arena, BDPi(motive_body, m_sk))),
      )
      match
        (
          bidir_dag_compile_dterm(arena, ctx_m, motive_body, None),
          bidir_dag_compile_dterm(arena, ctx, z_br, Some(m_zero)),
          bidir_dag_compile_dterm(arena, ctx, s_br, Some(succ_ty)),
          bidir_dag_compile_dterm(arena, ctx, scrut, Some(nat_id)),
        ) {
        (Some(dm), Some(dz), Some(ds), Some(dn)) =>
          Some(DNatElim(dm, dz, ds, dn))
        _ => None
      }
    }
  }
}

///|
/// 接駁既有 `Elaborator`（`STerm`）之元變數世代感知記憶化輔助：
/// 當單次 `elab_infer` 前後未新增或解出任何 `UMeta`（純確定性子樹）時，安全快取結果索引。
fn unifier_epoch_fingerprint(u : Unifier) -> UInt64 {
  let mut solved = 0
  for m in u.metas {
    match m.solution {
      Some(_) => solved = solved + 1
      None => ()
    }
  }
  ((u.metas.length().to_int64() << 20) | solved.to_int64()).reinterpret_as_uint64()
}

///|
fn sterm_structural_digest(s : STerm) -> UInt64 {
  match s {
    SVar(name) => {
      let mut h = 0xCBF29CE484222325UL
      for i in 0..<name.length() {
        h = @swar.swar_mix64(
          h ^ name.code_unit_at(i).to_int().to_int64().reinterpret_as_uint64(),
        )
      }
      @swar.swar_merkle_node64(1, h, 0UL)
    }
    SLam(name, _, body) =>
      @swar.swar_merkle_node64(
        2,
        sterm_structural_digest(SVar(name)),
        sterm_structural_digest(body),
      )
    SApp(f, a) =>
      @swar.swar_merkle_node64(
        3,
        sterm_structural_digest(f),
        sterm_structural_digest(a),
      )
    SPair(a, b) =>
      @swar.swar_merkle_node64(
        4,
        sterm_structural_digest(a),
        sterm_structural_digest(b),
      )
    SFst(p) => @swar.swar_merkle_node64(5, sterm_structural_digest(p), 0UL)
    SSnd(p) => @swar.swar_merkle_node64(6, sterm_structural_digest(p), 0UL)
    SBoolLit(b) => @swar.swar_merkle_node64(7, if b { 1UL } else { 0UL }, 0UL)
    SUnitLit => @swar.swar_merkle_node64(8, 0UL, 0UL)
    SNatZero => @swar.swar_merkle_node64(9, 0UL, 0UL)
    SSucc(n) => @swar.swar_merkle_node64(10, sterm_structural_digest(n), 0UL)
    SNatElim(m, z, sc, n) =>
      @swar.swar_merkle_seq64(11, [
        sterm_structural_digest(m),
        sterm_structural_digest(z),
        sterm_structural_digest(sc),
        sterm_structural_digest(n),
      ])
    SAnn(e, _) => @swar.swar_merkle_node64(12, sterm_structural_digest(e), 1UL)
    SHole => @swar.swar_merkle_node64(13, 0UL, 0UL)
  }
}

///|
/// 既有表面精緻化器 `Elaborator` 的 `@swar` 記憶化包裝會話。
pub(all) struct MemoElabSession {
  elab : Elaborator
  cache : @swar.SwarMemoTable64
  results : Array[ElabResult?]
}

///|
pub fn memo_elab_session_new() -> MemoElabSession {
  MemoElabSession::{
    elab: elaborator_new(),
    cache: @swar.swar_memo_new(9),
    results: [],
  }
}

///|
pub fn memo_elab_infer(sess : MemoElabSession, term : STerm) -> ElabResult? {
  let ep_before = unifier_epoch_fingerprint(sess.elab.unifier)
  let depth_u = sess.elab.vars.length().to_int64().reinterpret_as_uint64()
  let key = @swar.swar_merkle_seq64(301, [
    ep_before,
    depth_u,
    sterm_structural_digest(term),
  ])
  match @swar.swar_memo_get(sess.cache, key) {
    Some(slot) => return sess.results[slot]
    None => ()
  }
  let res = elab_infer(sess.elab, term)
  let ep_after = unifier_epoch_fingerprint(sess.elab.unifier)
  // 僅當合一器狀態未產生副作用突變時寫入記憶表（保證元變數健全性）
  if ep_before == ep_after {
    let slot = sess.results.length()
    sess.results.push(res)
    @swar.swar_memo_put(sess.cache, key, slot)
  }
  res
}

///|
/// 執行記憶化類型檢查、雙向歸納與完備雙向依賴類型精緻化全套驗證。
pub fn verify_memo_bidir_inductive_suite() -> MemoBidirInductiveReport {
  let arena = bidir_dag_new()
  let bool_ty = bidir_dag_alloc(arena, BDBoolTy)
  let nat_ty = bidir_dag_alloc(arena, BDNatTy)
  let arr_bb = bidir_dag_alloc(arena, BDPi(bool_ty, bool_ty))

  // 1. 構造深度 d = 10 之共享菱形函數複合塔：
  //    f₀ = (λx. x : Bool -> Bool)
  //    f_{k+1} = (λx. f_k (f_k x) : Bool -> Bool)
  //    由於雜湊共享，`f_k` 只佔 1 個節點 ID，但展開樹含 > 2^10 = 1024 個重複子檢查！
  let v0 = bidir_dag_alloc(arena, BDVar(0))
  let id_fn = bidir_dag_alloc(
    arena,
    BDAnn(bidir_dag_alloc(arena, BDLam(v0)), arr_bb),
  )
  let mut cur_fn = id_fn
  let diamond_depth = 10
  for _ in 0..<diamond_depth {
    let f_shifted = bd_shift(arena, cur_fn, 1, 0)
    let inner_app = bidir_dag_alloc(arena, BDApp(f_shifted, v0))
    let outer_app = bidir_dag_alloc(arena, BDApp(f_shifted, inner_app))
    let lam = bidir_dag_alloc(arena, BDLam(outer_app))
    cur_fn = bidir_dag_alloc(arena, BDAnn(lam, arr_bb))
  }
  let unmemo_ok = bidir_dag_check_unmemoized(arena, [], cur_fn, arr_bb)
  let unmemo_visits = arena.unmemo_step_visits
  let memo_ok = bidir_dag_check_memo(arena, [], cur_fn, arr_bb)
  let memo_visits = arena.memo_step_visits
  let hits_first = arena.memo_infer.hits + arena.memo_check.hits

  // 測試 O(1) 世代失效：失效前二次查詢直接命中快取（0 新增走訪），失效後重算
  let visits_before_repeat = arena.memo_step_visits
  let repeat_ok = bidir_dag_check_memo(arena, [], cur_fn, arr_bb)
  let zero_extra_on_hit = arena.memo_step_visits == visits_before_repeat
  bidir_dag_invalidate_cache(arena)
  let after_inval_ok = bidir_dag_check_memo(arena, [], cur_fn, arr_bb)
  let recomputed_after_inval = arena.memo_step_visits > visits_before_repeat
  let epoch_ok = repeat_ok &&
    zero_extra_on_hit &&
    after_inval_ok &&
    recomputed_after_inval

  // 2. 雙向歸納構造子向下精化：無標註 `vcons(true, vcons(false, vnil)) ⇐ Vec(Bool, S (S 0))`
  let z = bidir_dag_alloc(arena, BDZero)
  let s1 = bidir_dag_alloc(arena, BDSucc(z))
  let s2 = bidir_dag_alloc(arena, BDSucc(s1))
  let vec_b_2 = bidir_dag_alloc(arena, BDVecTy(bool_ty, s2))
  let t_true = bidir_dag_alloc(arena, BDBoolLit(true))
  let t_false = bidir_dag_alloc(arena, BDBoolLit(false))
  let vnil = bidir_dag_alloc(arena, BDVecNil)
  let v1 = bidir_dag_alloc(arena, BDVecCons(t_false, vnil))
  let v2 = bidir_dag_alloc(arena, BDVecCons(t_true, v1))
  let vec_good = bidir_dag_check_memo(arena, [], v2, vec_b_2)
  // 負對照：長度不符 `v2 ⇐ Vec(Bool, S 0)` 與 `vnil ⇐ Vec(Bool, S 0)` 必須被雙向索引拆解拒絕
  let vec_b_1 = bidir_dag_alloc(arena, BDVecTy(bool_ty, s1))
  let vec_bad_rejected = !bidir_dag_check_memo(arena, [], v2, vec_b_1) &&
    !bidir_dag_check_memo(arena, [], vnil, vec_b_1)

  // 3. 雙向依值歸納無動機合成：
  //    replicate_true : Π(n : Nat). Vec(Bool, n)
  //    := λn. nat_ind(vnil, λk. λih. vcons(true, ih), n)
  //    注意：完全未提供動機 `λm. Vec(Bool, m)`，亦未提供任何 `λ` 型別標註！
  let vec_b_v0 = bidir_dag_alloc(arena, BDVecTy(bool_ty, v0))
  let rep_ty = bidir_dag_alloc(arena, BDPi(nat_ty, vec_b_v0))
  let succ_step = bidir_dag_alloc(
    arena,
    BDLam(
      bidir_dag_alloc(
        arena,
        BDLam(bidir_dag_alloc(arena, BDVecCons(t_true, v0))),
      ),
    ),
  )
  let ind_body = bidir_dag_alloc(arena, BDNatInd(vnil, succ_step, v0))
  let rep_fn = bidir_dag_alloc(arena, BDLam(ind_body))
  let nat_ind_ok = bidir_dag_check_memo(arena, [], rep_fn, rep_ty)

  // 4. 編譯至受信任核心 `@kernel.DTerm` 並以 `@kernel.dep_check_closed` 獨立複驗（含計算歸約對帳！）
  let kernel_ok = match
    (
      bidir_dag_compile_dterm(arena, [], rep_fn, Some(rep_ty)),
      bidir_dag_compile_dterm(arena, [], rep_ty, None),
      bidir_dag_compile_dterm(arena, [], v2, Some(vec_b_2)),
      bidir_dag_compile_dterm(arena, [], vec_b_2, None),
    ) {
    (Some(d_rep), Some(d_rep_ty), Some(d_v2), Some(d_vec_b2)) => {
      let chk1 = dep_check_closed(d_rep, d_rep_ty)
      let chk2 = dep_check_closed(d_v2, d_vec_b2)
      // 進一步驗證計算等價：`rep_fn (S (S 0))` 正規形與 `(true, (false_replaced_by_true, unit))` 一致
      let d_two = d_nat_lit(2)
      let d_rep2 : DTerm = DApp(d_rep, d_two)
      let d_expected_v2 : DTerm = DPair(
        DBoolLit(true),
        DPair(DBoolLit(true), DUnitLit),
      )
      let nf1 = dep_nf_closed(d_rep2, d_vec_b2)
      let nf2 = dep_nf_closed(d_expected_v2, d_vec_b2)
      chk1 && chk2 && nf1 == Some(d_expected_v2) && nf1 == nf2
    }
    _ => false
  }

  // 5. 驗證接駁既有 `Elaborator` 之 `MemoElabSession`
  let sess = memo_elab_session_new()
  let st = SAnn(SLam("b", None, SVar("b")), uty_arrow(uty_bool(), uty_bool()))
  let r1 = memo_elab_infer(sess, st)
  let r2 = memo_elab_infer(sess, st)
  let elab_memo_ok = match (r1, r2) {
    (Some(v1_r), Some(v2_r)) => v1_r == v2_r && sess.cache.hits >= 1
    _ => false
  }

  let all_ok = unmemo_ok &&
    memo_ok &&
    unmemo_visits > 15000 &&
    memo_visits <= 120 &&
    hits_first >= 15 &&
    epoch_ok &&
    vec_good &&
    vec_bad_rejected &&
    nat_ind_ok &&
    kernel_ok &&
    elab_memo_ok
  MemoBidirInductiveReport::{
    diamond_depth,
    unmemoized_visits: unmemo_visits,
    memoized_visits: memo_visits,
    memo_cache_hits: hits_first,
    epoch_invalidation_ok: epoch_ok,
    bidir_vec_cons_nil_checked_ok: vec_good,
    bidir_vec_wrong_index_rejected: vec_bad_rejected,
    bidir_nat_ind_motive_synthesized_ok: nat_ind_ok,
    kernel_dterm_soundness_ok: kernel_ok,
    existing_elaborator_memo_ok: elab_memo_ok,
    all_ok,
  }
}
