///|
// F2 graph -> F3 Boolean closure -> F6 integer Laplacian SNF.
// Only a genuinely shared object is checked here. The old conjunction of
// unrelated A5/B3, Yoneda, DFA, Nöbeling and Adams health probes was removed;
// their native APIs and native verification entry points remain available.
#derive(Debug, Eq)
pub(all) struct GraphClosureSnfReport {
  vertices : Int32
  components : Int32
  reachable_pairs : Int32
  expected_reachable_pairs : Int32
  laplacian_rank : Int32
  snf_certificate_ok : Bool
  all_holds : Bool
}

///|
pub extend GraphClosureSnfReport with @debug.Debug::{to_repr}

///|
pub extend GraphClosureSnfReport with Eq::{not_equal, equal}

///|
/// Reusable three-path comparison on a simple undirected graph (1..32 vertices).
/// Component BFS, Boolean Kleene reachability and verified integral SNF are
/// different algorithms on the SAME adjacency data. Bad shape is rejected.
pub fn graph_closure_snf_report(graph : @sym.Graph) -> GraphClosureSnfReport? {
  let n = graph.order()
  if n < 1 || n > 32 {
    return None
  }
  for i in 0..<n {
    if graph.has_edge(i, i) {
      return None
    }
    for j in 0..<n {
      if graph.has_edge(i, j) != graph.has_edge(j, i) {
        return None
      }
    }
  }
  let components = graph.components()
  let component_of = Array::make(n, -1)
  let mut expected = 0
  for c in 0..<components.length() {
    let members = components[c]
    expected = expected + members.length() * members.length()
    for v in members {
      component_of[v] = c
    }
  }
  let adjacency : @smat.Mat[@semialg.BoolSr] = @smat.Mat::zero(n, n)
  let rows = Array::makei(n, i => {
    Array::makei(n, j => {
      if i == j {
        graph.degree(i)
      } else if graph.has_edge(i, j) {
        adjacency.set(i, j, @semialg.BoolSr::of(true))
        -1
      } else {
        0
      }
    })
  })
  let (closure, reachable) = @smat.closure_bool_swar(adjacency)
  let mut pointwise = true
  for i in 0..<n {
    for j in 0..<n {
      if closure.get(i, j).is_one() != (component_of[i] == component_of[j]) {
        pointwise = false
      }
    }
  }
  let laplacian = @gcd.zmat_from_int_rows(rows)
  let snf = @gcd.zmat_snf(laplacian)
  let certified = @gcd.zmat_snf_verify(laplacian, snf)
  Some({
    vertices: n,
    components: components.length(),
    reachable_pairs: reachable,
    expected_reachable_pairs: expected,
    laplacian_rank: snf.rank,
    snf_certificate_ok: certified,
    all_holds: pointwise &&
    reachable == expected &&
    certified &&
    snf.rank == n - components.length(),
  })
}

///|
#derive(Debug, Eq)
pub(all) struct F2F3F6TriadBridgeReport {
  cases : Array[GraphClosureSnfReport]
  negative_control_detected : Bool
  all_holds : Bool
}

///|
pub extend F2F3F6TriadBridgeReport with @debug.Debug::{to_repr}

///|
pub extend F2F3F6TriadBridgeReport with Eq::{not_equal, equal}

///|
/// The A4 Cayley graph is connected; two disjoint triangles are not.
/// Thus the tempting "every Laplacian has corank one" claim is rejected.
pub fn verify_f2_f3_f6_triad_bridge() -> F2F3F6TriadBridgeReport {
  let cayley = @sym.cayley_graph(@sym.PermGroup::alternating(4), 32)
  let disconnected = @sym.Graph::disjoint_union([
    @sym.Graph::cycle(3),
    @sym.Graph::cycle(3),
  ])
  let cases : Array[GraphClosureSnfReport] = []
  for graph in [cayley, disconnected] {
    if graph_closure_snf_report(graph) is Some(report) {
      cases.push(report)
    }
  }
  let negative = cases.length() == 2 &&
    cases[0].vertices == 12 &&
    cases[0].components == 1 &&
    cases[0].reachable_pairs == 144 &&
    cases[0].laplacian_rank == 11 &&
    cases[1].components == 2 &&
    cases[1].reachable_pairs == 18 &&
    cases[1].laplacian_rank == 4 &&
    graph_closure_snf_report(@sym.Graph::empty(0)) == None &&
    graph_closure_snf_report(@sym.Graph::empty(33)) == None
  {
    cases,
    negative_control_detected: negative,
    all_holds: negative && cases.all(r => r.all_holds),
  }
}
