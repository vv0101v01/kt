///|
// Architecture boundary: the root package consumes the host-filesystem
// package only through this explicit import list.  The durability and BFT
// quorum protocols are simulated in pure MoonBit so that they verify on
// every target (`wasm-gc` and `native`).
using @hostfs {
  check_durable_write_protocol,
  bft_check_consensus_and_crash_durability,
}
