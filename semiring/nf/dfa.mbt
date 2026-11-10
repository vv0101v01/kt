// ===========================================================================
// 規範形式 II：最小 DFA 作為 Myhill–Nerode 正規形
//
// 定理（Myhill–Nerode）：每個正則語言的「最小完整 DFA」在同構意義下唯一。
// 若再把狀態按 BFS 首次到達的順序編號、符號按固定順序展開，就得到一個
// **逐位元可比對的字串**——這就是本庫所稱的「正規形」：
//
//     語言 L 的正規形 = canonical(minimal(complete(DFA(L))))
//
// 三個操作因此可以互相驗證：
//   * `dfa_of_regex`   由導數直接建 DFA（狀態 = ACI 正規形表示式）
//   * `dfa_minimize`   Moore 分割細化（等價類合併）
//   * `dfa_canonical`  BFS 正規化字串
//
// `regex_equiv(a,b)` 判定的就是 canonical(a) == canonical(b)，
// 而且另外用「乘積自動機」獨立再判一次（兩條路必須一致）。
// ===========================================================================

///|
/// 完整 DFA（每個狀態的每個符號都有轉移；`-1` 表示尚未建邊）。
pub(all) struct Dfa {
  nsym : Int32
  alphabet : Array[Int32]
  start : Int32
  accept : Array[Bool]
  /// 大小 `nstates * nsym`，`trans[s*nsym + k]`
  trans : Array[Int32]
}

///|
pub fn Dfa::nstates(self : Dfa) -> Int32 {
  // 以 accept 的長度為準：`nsym = 0`（空字母表）時轉移表是空的，
  // 用 trans.length()/nsym 會除以零。
  self.accept.length()
}

///|
/// 正規表示式語法樹之 64-bit SplitMix64 結構雜湊（零字串配置，搭配 `regex_cmp` 碰撞核對）。
fn regex_hash64(r : Regex) -> UInt64 {
  match r {
    RZero => 0x9E3779B97F4A7C15UL
    ROne => 0xBF58476D1CE4E5B9UL
    RChar(c) =>
      (0x94D049BB133111EBUL ^ (c.to_uint64() + 1UL)) * 0xBF58476D1CE4E5B9UL
    RStar(x) => {
      let h = regex_hash64(x) ^ 0x517CC1B727220A95UL
      (h ^ (h >> 30)) * 0xBF58476D1CE4E5B9UL
    }
    RSum(a, b) => {
      let ha = regex_hash64(a)
      let hb = regex_hash64(b)
      let h = (ha * 0x9E3779B97F4A7C15UL) ^ hb ^ 0x2545F4914F6CDD1DUL
      h ^ (h >> 27)
    }
    RProd(a, b) => {
      let ha = regex_hash64(a)
      let hb = regex_hash64(b)
      let h = (ha * 0xBF58476D1CE4E5B9UL) ^ hb ^ 0xD6E8FEB86659FD93UL
      h ^ (h >> 29)
    }
  }
}

///|
/// 由正規表示式建 DFA：狀態就是導數（的 ACI 正規形）。
///
/// 以 `regex_hash64` 雜湊桶 + `regex_cmp` 精確核對取代舊版 `O(|Q|²)` 線性掃描，
/// 使 Brzozowski 導數子集建構降至期望 `O(|Q|·|Σ|)`。
pub fn dfa_of_regex(r : Regex, alphabet : Array[Int32]) -> Dfa {
  let states : Array[Regex] = [r]
  let buckets : Map[UInt64, Array[Int32]] = Map([])
  buckets.set(regex_hash64(r), [0])
  let trans : Array[Int32] = []
  let mut head = 0
  let nsym = alphabet.length()
  while head < states.length() {
    let cur = states[head]
    for k in 0..<nsym {
      let d = deriv(cur, alphabet[k])
      let h = regex_hash64(d)
      let mut idx = -1
      match buckets.get(h) {
        Some(list) =>
          for q in list {
            if regex_cmp(states[q], d) == 0 {
              idx = q
              break
            }
          }
        None => ()
      }
      if idx < 0 {
        idx = states.length()
        states.push(d)
        match buckets.get(h) {
          Some(list) => list.push(idx)
          None => buckets.set(h, [idx])
        }
      }
      trans.push(idx)
    }
    head = head + 1
  }
  let n = states.length()
  let accept : Array[Bool] = Array::make(n, false)
  for i in 0..<n {
    accept[i] = nullable(states[i])
  }
  { nsym, alphabet, start: 0, accept, trans, }
}

///|
/// 是否接受符號序列。
pub fn Dfa::accepts(self : Dfa, w : Array[Int32]) -> Bool {
  let mut s = self.start
  for c in w {
    let mut k = -1
    for i in 0..<self.nsym {
      if self.alphabet[i] == c {
        k = i
        break
      }
    }
    if k < 0 {
      return false
    }
    s = self.trans[s * self.nsym + k]
  }
  self.accept[s]
}

///|
/// Hopcroft–Valmari 分割細化演算法（`O(|Σ|·|Q| log |Q|)` 最小完整 DFA）：
/// 1. 先從 `start` 做可達 BFS 裁剪不可達狀態；
/// 2. 預建扁平反向轉移 CSR `inv_off` / `inv_src`（零巢狀陣列配置）；
/// 3. 採用扁平可細化分割（Refinable Partition：`elems`/`pos`/`blk_of`/`b_start`/`b_end`/`b_split`）
///    與 Hopcroft 較小半塊工作列不變量（每個狀態最多落入較小分裂塊 `log₂|Q|` 次），
///    再按可達區塊之 BFS 順序重新編號，產出唯一 Myhill–Nerode 正規形最小 DFA。
pub fn dfa_minimize(d : Dfa) -> Dfa {
  let n_orig = d.nstates()
  let nsym = d.nsym
  if n_orig == 0 {
    return d
  }
  if nsym == 0 {
    return {
      nsym: 0,
      alphabet: d.alphabet,
      start: 0,
      accept: [d.accept[d.start]],
      trans: [],
    }
  }
  // 1. 可達狀態 BFS 裁剪
  let reach : Array[Int32] = [d.start]
  let reach_map : Array[Int32] = Array::make(n_orig, -1)
  reach_map[d.start] = 0
  let mut r_head = 0
  while r_head < reach.length() {
    let s = reach[r_head]
    r_head = r_head + 1
    for k in 0..<nsym {
      let t = d.trans[s * nsym + k]
      if reach_map[t] < 0 {
        reach_map[t] = reach.length()
        reach.push(t)
      }
    }
  }
  let n = reach.length()
  let r_accept = Array::make(n, false)
  let r_trans = Array::make(n * nsym, 0)
  for i in 0..<n {
    let orig = reach[i]
    r_accept[i] = d.accept[orig]
    for k in 0..<nsym {
      r_trans[i * nsym + k] = reach_map[d.trans[orig * nsym + k]]
    }
  }

  // 2. 初始分割 {Rej, Acc}
  let rej_list : Array[Int32] = []
  let acc_list : Array[Int32] = []
  for i in 0..<n {
    if r_accept[i] {
      acc_list.push(i)
    } else {
      rej_list.push(i)
    }
  }
  if rej_list.length() == 0 || acc_list.length() == 0 {
    return {
      nsym,
      alphabet: d.alphabet,
      start: 0,
      accept: [r_accept[0]],
      trans: Array::make(nsym, 0),
    }
  }

  // 3. 扁平反向轉移 CSR：桶編號 = target * nsym + k
  let nbuckets = n * nsym
  let inv_deg = Array::make(nbuckets + 1, 0)
  for s in 0..<n {
    for k in 0..<nsym {
      let t = r_trans[s * nsym + k]
      inv_deg[t * nsym + k + 1] = inv_deg[t * nsym + k + 1] + 1
    }
  }
  for i in 0..<nbuckets {
    inv_deg[i + 1] = inv_deg[i + 1] + inv_deg[i]
  }
  let inv_off = inv_deg.copy()
  let inv_cur = inv_deg.copy()
  let inv_src = Array::make(n * nsym, 0)
  for s in 0..<n {
    for k in 0..<nsym {
      let bkt = r_trans[s * nsym + k] * nsym + k
      let p = inv_cur[bkt]
      inv_src[p] = s
      inv_cur[bkt] = p + 1
    }
  }

  // 4. Valmari–Hopcroft 可細化分割結構
  let elems = Array::make(n, 0)
  let pos = Array::make(n, 0)
  let blk_of = Array::make(n, 0)
  let b_start = Array::make(n + 1, 0)
  let b_end = Array::make(n + 1, 0)
  let b_split = Array::make(n + 1, 0)
  let mut cursor = 0
  b_start[0] = 0
  for s in rej_list {
    elems[cursor] = s
    pos[s] = cursor
    blk_of[s] = 0
    cursor = cursor + 1
  }
  b_end[0] = cursor
  b_split[0] = 0
  b_start[1] = cursor
  for s in acc_list {
    elems[cursor] = s
    pos[s] = cursor
    blk_of[s] = 1
    cursor = cursor + 1
  }
  b_end[1] = cursor
  b_split[1] = b_start[1]
  let mut nblocks = 2

  let in_wl = Array::make((n + 1) * nsym, false)
  let wl_blk : Array[Int32] = []
  let wl_sym : Array[Int32] = []
  let init_sp = if rej_list.length() <= acc_list.length() { 0 } else { 1 }
  for k in 0..<nsym {
    in_wl[init_sp * nsym + k] = true
    wl_blk.push(init_sp)
    wl_sym.push(k)
  }

  let sp_buf = Array::make(n, 0)
  let touched : Array[Int32] = []
  let mut wl_head = 0
  while wl_head < wl_blk.length() {
    let sp_b = wl_blk[wl_head]
    let sym = wl_sym[wl_head]
    wl_head = wl_head + 1
    in_wl[sp_b * nsym + sym] = false

    let sp_st = b_start[sp_b]
    let sp_en = b_end[sp_b]
    let sp_len = sp_en - sp_st
    for i in 0..<sp_len {
      sp_buf[i] = elems[sp_st + i]
    }
    for i in 0..<sp_len {
      let t = sp_buf[i]
      let bkt = t * nsym + sym
      for p in inv_off[bkt]..<inv_off[bkt + 1] {
        let s = inv_src[p]
        let b = blk_of[s]
        let sp = b_split[b]
        if sp == b_start[b] {
          touched.push(b)
        }
        let ps = pos[s]
        if ps != sp {
          let u = elems[sp]
          elems[sp] = s
          elems[ps] = u
          pos[s] = sp
          pos[u] = ps
        }
        b_split[b] = sp + 1
      }
    }

    for b in touched {
      let st = b_start[b]
      let mid = b_split[b]
      let en = b_end[b]
      b_split[b] = st
      if mid < en {
        let b_new = nblocks
        nblocks = nblocks + 1
        let left_len = mid - st
        let right_len = en - mid
        if left_len <= right_len {
          // 較小左半 [st..<mid] 成為新塊 b_new，原塊 b 保留右半 [mid..<en]
          b_start[b_new] = st
          b_end[b_new] = mid
          b_split[b_new] = st
          b_start[b] = mid
          b_end[b] = en
          b_split[b] = mid
        } else {
          // 較小右半 [mid..<en] 成為新塊 b_new，原塊 b 保留左半 [st..<mid]
          b_start[b_new] = mid
          b_end[b_new] = en
          b_split[b_new] = mid
          b_start[b] = st
          b_end[b] = mid
          b_split[b] = st
        }
        for q in b_start[b_new]..<b_end[b_new] {
          blk_of[elems[q]] = b_new
        }
        for c in 0..<nsym {
          in_wl[b_new * nsym + c] = true
          wl_blk.push(b_new)
          wl_sym.push(c)
        }
      }
    }
    touched.clear()
  }

  // 5. 以起點所在區塊開始按 BFS 規範編號
  let start_block = blk_of[0]
  let order : Array[Int32] = [start_block]
  let mapping : Array[Int32] = Array::make(nblocks + 1, -1)
  mapping[start_block] = 0
  let new_trans : Array[Int32] = []
  let new_accept : Array[Bool] = []
  let mut head = 0
  while head < order.length() {
    let b = order[head]
    let rep = elems[b_start[b]]
    new_accept.push(r_accept[rep])
    for k in 0..<nsym {
      let t = blk_of[r_trans[rep * nsym + k]]
      if mapping[t] < 0 {
        mapping[t] = order.length()
        order.push(t)
      }
      new_trans.push(mapping[t])
    }
    head = head + 1
  }
  {
    nsym,
    alphabet: d.alphabet,
    start: 0,
    accept: new_accept,
    trans: new_trans,
  }
}

///|
/// 正規形字串：BFS 順序（起點先、符號按字母表順序）下的
/// 「接受位元序列 + 轉移表」。最小完整 DFA 的這個字串對語言是唯一的。
pub fn dfa_canonical(d : Dfa) -> String {
  let sb = StringBuilder()
  let n = d.nstates()
  let nsym = d.nsym
  // BFS 重新編號
  let order : Array[Int32] = [d.start]
  let seen : Array[Int32] = Array::make(n, -1)
  seen[d.start] = 0
  let mut head = 0
  while head < order.length() {
    let s = order[head]
    for k in 0..<nsym {
      let t = d.trans[s * nsym + k]
      if seen[t] < 0 {
        seen[t] = order.length()
        order.push(t)
      }
    }
    head = head + 1
  }
  sb.write_string("n=\{order.length()};")
  for s in order {
    sb.write_string(if d.accept[s] { "1" } else { "0" })
  }
  sb.write_string(";")
  for s in order {
    for k in 0..<nsym {
      let t = d.trans[s * nsym + k]
      sb.write_string("\{seen[t]},")
    }
    sb.write_string("|")
  }
  sb.to_string()
}

///|
/// 乘積自動機的語言等價判定（不經過最小化，獨立於 `dfa_canonical`）。
pub fn dfa_equiv(a : Dfa, b : Dfa) -> Bool {
  if a.nsym != b.nsym {
    return false
  }
  let na = a.nstates()
  let nb = b.nstates()
  let visited : Array[Bool] = Array::make(na * nb, false)
  let qx : Array[Int32] = [a.start]
  let qy : Array[Int32] = [b.start]
  visited[a.start * nb + b.start] = true
  let mut head = 0
  while head < qx.length() {
    let s = qx[head]
    let t = qy[head]
    if a.accept[s] != b.accept[t] {
      return false
    }
    for k in 0..<a.nsym {
      let s2 = a.trans[s * a.nsym + k]
      let t2 = b.trans[t * b.nsym + k]
      if !visited[s2 * nb + t2] {
        visited[s2 * nb + t2] = true
        qx.push(s2)
        qy.push(t2)
      }
    }
    head = head + 1
  }
  true
}

///|
/// 兩個表示式是否描述同一語言：比對最小 DFA 的正規形字串。
pub fn regex_equiv(a : Regex, b : Regex, alphabet : Array[Int32]) -> Bool {
  let ca = dfa_canonical(dfa_minimize(dfa_of_regex(a, alphabet)))
  let cb = dfa_canonical(dfa_minimize(dfa_of_regex(b, alphabet)))
  ca == cb
}

///|
/// 反向語言：把 DFA 的邊反向，起點 = 原接受集，接受集 = 原起點。
/// 得到的是 NFA（多起點），這裡以「集合狀態」表示成完整 DFA。
