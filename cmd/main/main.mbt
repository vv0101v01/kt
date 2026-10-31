///|
/// Entry point: run the theorem registry and print the report.
/// Run with `moon run cmd/main` from the project root.
fn main {
  guard @lib.print_report() else { abort("theorem registry failed") }
}
