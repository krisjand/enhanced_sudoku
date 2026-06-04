---
name: xwing-implementation
description: "X-wing implementation plan — ready to code, task breakdown posted on issue"
metadata: 
  node_type: memory
  type: project
  originSessionId: bc3e2bd7-f0ee-4b44-99ec-c794953867b8
---

## Status
DONE — merged in PR #50 on 2026-06-03.

## Algorithm

For each digit (1–9):
- **Row scan**: collect rows where the digit has exactly 2 candidate positions. For each pair of rows sharing the same two columns → X-wing found → eliminate that digit from all other cells in those two columns.
- **Column scan**: same logic transposed (pair columns sharing the same two rows → eliminate from those rows).

Both scans are independent and can each produce eliminations. They use a shared `seen map[[3]int]bool` (keyed on `{row, col, digit}`) to deduplicate eliminations across both passes.

## Files to create / modify

### New: `backend/pkg/sudoku/x_wing.go`
```go
const (
    TechniqueXWing       = "xWing"
    TechniqueXWingRow    = "xWingRow"    // pattern in rows, eliminations in cols
    TechniqueXWingColumn = "xWingColumn" // pattern in cols, eliminations in rows
)
```
- `XWing(g Grid, cands Candidates) []SolveStep` — allocates shared `seen` map, calls both helpers, returns 0–2 SolveSteps
- `xWingInRows(cands Candidates, seen map[[3]int]bool) []CellAction`
- `xWingInCols(cands Candidates, seen map[[3]int]bool) []CellAction`
- No Box variant — X-wing does not involve boxes.

### New: `backend/pkg/sudoku/x_wing_test.go`
- `fixtureXWingPuzzle()` — inline Grid from `test_grids/x_wing.json` (file already exists at project root)
- `TestXWing` — table-driven: at least one elimination on fixture; no false positives on trivial grid
- Add a `TestHumanSolve` case (extend existing table in `human_solver_test.go`)
- A second fixture may be needed for the HumanSolve integration test if `x_wing.json` is not fully solvable with X-wing as the hardest technique — determine at implementation time

### Modified: `backend/pkg/sudoku/human_solver.go`
Insert in `techniques` slice between `hiddenQuadruples` and `forcedChains`:
```go
{TechniqueXWing, XWing},
```

### Modified: `backend/pkg/sudoku/difficulty.go`
Add to `techniqueRank`:
```go
TechniqueXWing: 3, // expert — same tier as hidden triples/quadruples
```

## Key design decisions
- Slot: between `hiddenQuadruples` and `forcedChains` — pure elimination (no branching), try before FC
- Difficulty rank: 3 (expert), same as `hiddenTriples`, `nakedQuadruples`, `hiddenQuadruples`
- Technique identifier pattern: `TechniqueXWing` / `TechniqueXWingRow` / `TechniqueXWingColumn` (camelCase, no Box)
- Shared `seen map[[3]int]bool` pattern — same as all other techniques (allocated in `XWing`, passed to both helpers)
- Reuse `rowUnit` / `colUnit` helpers from `naked_pairs.go` for iterating units

## Existing fixture
`test_grids/x_wing.json` already exists at project root:
```json
[[1,0,0,0,0,0,5,6,9],[4,9,2,0,5,6,1,0,8],[0,5,6,1,0,9,2,4,0],
 [0,0,9,6,4,0,8,0,1],[0,6,4,0,1,0,0,0,0],[2,1,8,0,3,5,6,0,4],
 [0,4,0,5,0,0,0,1,6],[9,0,5,0,6,1,4,0,2],[6,2,1,0,0,0,0,0,5]]
```
There is also `test_grids/x_wing_2.json` — does NOT exist (confirmed absent).
