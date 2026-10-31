///|
test "hostfs: single-node crash durability and 3f+1 BFT replicated quorum consensus" {
  assert_true(check_durable_write_protocol())
  assert_true(bft_check_consensus_and_crash_durability())
}
