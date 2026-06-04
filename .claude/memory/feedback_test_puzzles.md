---
name: feedback-test-puzzles
description: test_grids/ at project root holds JSON fixtures; convert to Grid literals for tests — never search programmatically
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4d5c3de0-022a-4991-be84-91b4564b76df
---

## Fixture location and format

`test_grids/` lives at the **project root** (not inside the Go package). Each file is a plain `[[int]]` 2D array where `0` = empty cell — **not** a Go `Grid` struct. Files also have companion `.png` screenshots.

To use a fixture in a Go test, manually convert the JSON array to an inline `Grid` literal in the `*_test.go` file.

## Files present (as of 2026-06-03)

`naked_pair.json`, `naked_pair_2.json`, `hidden_pair.json`, `box_line_reduction.json`,
`naked_triple.json`, `naked_triple_2.json`, `naked_triple_3.json`, `hidden_triple.json`,
`naked_quad.json`, `hidden_quad_1.json`, `hidden_quad_2.json`,
`x_wing.json`, `swordfish_1.json`, `swordfish_2.json`, `swordfish_3.json`,
`xy_wing.json`, `xy_wing_2.json`, `xyz_wing.json`, `xyz_wing_2.json`,
`forced_chain_dual_cell.json`, `forced_chain_dual_cell_2.json`, `forcing_chain_triple_cell.json`

## Swordfish fixture notes (as of 2026-06-03)
`swordfish_1.json` and `swordfish_2.json` — column-elimination swordfishes (pattern in cols, eliminations in rows).
`swordfish_3.json` — row-elimination swordfish (pattern in rows, eliminations in cols). Transcribed from a screenshot provided by the user.

## Never search programmatically

Do not run seed loops or brute-force generators to find fixture puzzles. If a HumanSolve integration fixture is needed and none of the `test_grids/` files works, use the `/puzzle/find?technique=<name>` endpoint.

**Why:** Simple techniques may be found in <100 puzzles, but complex ones could require thousands of iterations. Running that inside a test is wasteful and fragile.

**How to apply:** For each new technique, check `test_grids/` first. Convert the relevant JSON file to a `Grid` literal for unit tests. For the HumanSolve integration case, use the puzzle finder endpoint if no suitable file exists.
