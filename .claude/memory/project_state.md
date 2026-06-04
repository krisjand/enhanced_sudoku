---
name: project-state
description: Current project state — what is done and what is next
metadata: 
  node_type: memory
  type: project
  originSessionId: 51113308-feef-4117-9dc3-c5925d806cd1
---

## Status as of 2026-06-04

Corpus generator done (PR #59, merged, issue #58). Script currently running to fill expert (314/500). Corpus improvements in PR #60 (open): startup logging, save/print every 500 generated puzzles. After expert is full, corpus files will be committed to the repo.

## Completed

- Story #1: Project scaffolding (Flutter frontend, Go backend, Hermit, CI/CD)
- GitHub Actions CI with change detection, Docker image for Flutter, branch protection
- Best practices docs populated with learnings
- All 19 feature stories created as GitHub issues (#8–#26)
- Story #2: Sudoku solver (PR #27, issue #8) — `backend/pkg/sudoku/` with `Grid`, `Candidates` (bitmask), `Solve` (backtracking + MRV), `HasUniqueSolution`, per-step timing types; 22 table-driven tests
- Time tracking moved out of repo to GitHub issue comments (PR #28)
- Story #3: Puzzle generator (PR #29, issue #9) — `Generate(rng)` in `backend/pkg/sudoku/generator.go`; randomized backtracking via shared `backtrackWith` kernel; `removeClues` with uniqueness guarantee; 5 tests
- Story #4: Puzzle API endpoint (PR #30, issue #10) — `GET /puzzle` in `backend/api/`; `puzzleHandler` struct with mutex-protected `*rand.Rand`; `writeJSON`/`requireGET` helpers; `Dockerfile` + `docker-compose.yml`; generation time 600µs–13ms observed
- Story #5: Naked singles (PR #31, issue #11) — `NakedSingles(g, cands)` in `naked_singles.go`; `TechniqueNakedSingles` constant; 4 table-driven tests
- Story #6: Hidden singles (PR #32, issue #12) — `HiddenSingles(g, cands)` in `hidden_singles.go`; deduplication across row/col/box; per-scan timing; `TechniqueHiddenSingle{Row,Column,Box}` constants
- Story #7: Naked pairs (PR #35, issue #13) — `NakedPairs(g, cands)` in `naked_pairs.go`; shared `seen` map across row/col/box passes; `TechniqueNakedPair{Row,Column,Box}` constants; `cell` type and `rowUnit/colUnit/boxUnit` helpers
- Story #14 (PR #34): Human solver endpoint — `POST /puzzle/solve`; `HumanSolve` with `TechniqueFn` interface; `SolveResult` with `Duration` field (pure solver wall time, added PR #37)
- Dev tooling (PR #37, issue #36) — `Makefile`, `scripts/generate_and_solve.sh`, `duration_us` in solve response
- Story #8: Hidden pairs (PR #38, issue #14) — `HiddenPairs(g, cands)` in `hidden_pairs.go`; shared `seen` map across row/col/box passes; `TechniqueHiddenPair{Row,Column,Box}` constants; fixed-size `[2]cell` arrays with early-exit counter
- Story #9: Naked triples (PR #43, issue #15) — `NakedTriples(g, cands)` in `naked_triples.go`; C(n,3) triple search; `TechniqueNakedTriple{Row,Column,Box}`; `hasNakedTripleInUnit` structural validator; `naked_triple_3.json` fixture (seed 33)
- Story #10: Hidden triples (PR #46, issue #16) — `HiddenTriples(g, cands)` in `hidden_triples.go`; per-digit position bitmasks (OR + popcount) to find C(9,3) digit triples confined to 3 cells; `TechniqueHiddenTriple{Row,Column,Box}`; unit fixture from `test_grids/hidden_triple.json`; integration fixture generated via `/puzzle/find?technique=hiddenTriples&max=5000`
- Story: Locked candidates (PR #41, issue #40) — `LockedCandidates(g, cands)` in `locked_candidates.go`; 4 passes (pointing rows/cols + reduction rows/cols); `TechniqueLockedCandidatesPointingRow/Column` + `TechniqueLockedCandidatesReductionRow/Column`; registered between HiddenSingles and NakedPairs; `naked_pair_2.json` fixture added for NakedPairs HumanSolve integration check
- Puzzle finder endpoint (PR #45, issue #44) — `GET /puzzle/find?technique=<name>&max=<N>` in `backend/api/find_puzzle_handler.go`; default max 100, absolute cap 10 000; 404 if exhausted; `KnownTechniques()` + `IsKnownTechnique()` in `human_solver.go`; `newFindPuzzleHandlerWithRng(rng)` for deterministic tests; technique identifiers refactored to camelCase (see below)

## Infrastructure highlights

- Flutter CI uses pre-built Docker image: `ghcr.io/krisjand/enhanced_sudoku/flutter-ci:3.44.0`
- Go CI uses Hermit + golangci-lint
- Single `ci.yml` with `changes` detection job (fetch-depth: 0 + origin/$base_ref...HEAD diff)
- Branch protection on `main` requires PRs + CI checks
- Solver package: `backend/pkg/sudoku/` (not `internal/` — chosen for testability)
- API service: `backend/api/` — HTTP handlers, separate from domain logic

## Architecture decisions (human solver)

- `TechniqueFn func(Grid, Candidates) []SolveStep` — common signature for all techniques
- `TechniqueAttempt{Technique, Duration, Steps}` — records one technique attempt (timing preserved even when nothing found)
- `HumanSolve(Grid) SolveResult` — iterates techniques in order; each iteration tries until one succeeds or all fail (stuck)
- `SolveResult{Solved, Grid, Duration, Iterations [][]TechniqueAttempt}` — full trace for the HTTP response
- If stuck with available techniques → `Solved: false`, no error
- Shared `seen` map pattern: one map allocated per `TechniqueFn` call, passed across all three unit-type scans (row/col/box) to prevent duplicate actions in the trace
- Test grids for each technique stored in `test_grids/*.json` (0 = empty cell)

## Technique identifier convention (camelCase — decided 2026-06-02)

All technique string constants use camelCase identifiers, not display names. Display-name translation is a frontend concern.

**Top-level (used in `TechniqueAttempt.Technique` and HTTP query param):**
- `nakedSingles`, `hiddenSingles`, `lockedCandidates`, `nakedPairs`, `hiddenPairs`, `nakedTriples`, `hiddenTriples`, `nakedQuadruples`, `hiddenQuadruples`, `forcedChains`

**Sub-level (used in `SolveStep.Technique`):**
- `hiddenSingleRow`, `hiddenSingleColumn`, `hiddenSingleBox`
- `lockedCandidatesPointingRow`, `lockedCandidatesPointingColumn`, `lockedCandidatesReductionRow`, `lockedCandidatesReductionColumn`
- `nakedPairRow`, `nakedPairColumn`, `nakedPairBox`
- `hiddenPairRow`, `hiddenPairColumn`, `hiddenPairBox`
- `nakedTripleRow`, `nakedTripleColumn`, `nakedTripleBox`
- `hiddenTripleRow`, `hiddenTripleColumn`, `hiddenTripleBox`

**New techniques must follow this pattern** — top-level identifier registered in `techniques` slice; sub-level identifiers in the SolveStep constants within the technique file.

## Technique file pattern (follow for all new techniques)

- Constants: `TechniqueXxx = "camelCaseIdentifier"` (top-level), `TechniqueXxxRow/Column/Box = "camelCaseIdentifierRow/Column/Box"` (sub-level)
- Three helpers `xxxInRows/Cols/Boxes(cands Candidates, seen map[[3]int]bool) []CellAction`
- One shared `seen` map allocated in the top-level function, passed to all three helpers
- Core logic in `eliminateFromXxx(actions, cands, seen, unit []cell) []CellAction`
- Reuse `rowUnit/colUnit/boxUnit` and `cell` type from `naked_pairs.go`
- Register in `human_solver.go` `techniques` slice in complexity order
- Add a `TestHumanSolve` case with `wantSolved` set correctly for the fixture puzzle

## Hidden pairs implementation notes (reference for hidden triples)

- `hidden_pairs.go`: `HiddenPairs(g Grid, cands Candidates) []SolveStep`
- Algorithm: for each unit, find digit pairs (d1,d2) each appearing in exactly 2 cells; those 2 cells must be identical → hidden pair → eliminate all other candidates from those cells
- Uses fixed-size `[2]cell` arrays with early-exit counter (not slices) to avoid allocs in the inner loop
- Shared `seen map[[3]int]bool` — allocated in `HiddenPairs`, passed to all three unit-type helpers
- `hasHiddenPairCoveringCell` in test file is the structural validator for eliminations

## Test fixtures

`test_grids/` is at the **project root**. Files are `[[int]]` 2D arrays (0 = empty); convert to inline `Grid` literals in test files. See [[feedback-test-puzzles]] for full file list and conversion rules.

- Story #11: Naked/hidden quadruples (PR #47, issue #17) — `NakedQuadruples` (C(n,4) cell search) + `HiddenQuadruples` (C(9,4) digit bitmask search); both registered in HumanSolve; 57 tests passing
- Story #12: Forced chains (PR #48, issue #18) — BFS across bi-value then tri-value seeds; configurable propagation (default: naked/hidden singles + locked candidates); contradiction → place surviving candidate; intersection → apply common actions; `ForcedChainBranch` on `SolveStep.Chains` for traceability; `HumanSolveWith(HumanSolveOpts)` added; `maxPropagation` query param on `/puzzle/find`; 39% of generated puzzles use FC; avg 2.44 FC wins/puzzle, avg branch depth 3.51 with default propagation
- Story #13: Difficulty rating (PR #49, issue #19) — `Rate(Grid) DifficultyResult` in `difficulty.go`; runs `HumanSolve` and maps hardest technique used to easy/medium/hard/expert/master/legendary; `GET /puzzle` response now includes `difficulty` + `techniques_used`; partial techniques returned even for legendary; panics on missing `techniqueRank` entry or out-of-bounds rank; expert fixture generated by sampling 5000 puzzles (seed 42, 0.1% expert rate); 8 table-driven tests

## Forced chains implementation notes

- `forced_chains.go`: `NewForcedChains(forcedChainsOptions) TechniqueFn`
- Default propagation: `nakedSingles`, `hiddenSingles`, `lockedCandidates` (up to depth 20)
- BFS: all seeds advanced one step at a time; shortest chain found first
- Contradiction: one branch impossible → place surviving candidate + its full chain
- Intersection: action common to all valid branches → apply it
- `ForcedChainBranch{Candidate int, Steps []SolveStep}` — one per seed candidate
- `SolveStep.Chains []ForcedChainBranch` (omitempty) — only set for forced chain steps
- `HumanSolveWith(puzzle Grid, opts HumanSolveOpts) SolveResult` — allows custom FC propagation
- `GET /puzzle/find?technique=forcedChains&maxPropagation=lockedCandidates` — override propagation per request

## Difficulty rating implementation notes

- `difficulty.go`: `Rate(Grid) DifficultyResult`
- `techniqueRank` maps technique name → int rank (0=easy … 4=master); panics on unknown key to catch missing entries at test time
- `rankToLevel []string` maps rank → level string; panics if rank out of bounds
- Legendary: if `HumanSolve` cannot solve, level = legendary; partial techniques still collected and returned
- `techniques` initialised as `[]string{}` (never nil) so JSON always serialises as `[]`
- Expert puzzles are rare (~0.1% of generated); `test_grids/expert_hidden_triple.json` was found by sampling 5000 puzzles with seed 42

## Difficulty mapping

| Technique | Level |
|---|---|
| nakedSingles, hiddenSingles | easy |
| lockedCandidates, nakedPairs | medium |
| hiddenPairs, nakedTriples | hard |
| hiddenTriples, nakedQuadruples, hiddenQuadruples | expert |
| forcedChains | master |
| unsolvable with known techniques | legendary |

- Story #15: X-wing (PR #50, issue #21) — `XWing(g Grid, cands Candidates) []SolveStep` in `x_wing.go`; row scan + col scan; shared `seen` map; `TechniqueXWing` rank 3 (expert); 131 tests passing

- Story #16: Swordfish (PR #51, issue #22) — `Swordfish(g Grid, cands Candidates) []SolveStep`; bitmask union + popcount for O(1) triple check; row+col scan; shared `seen`; 3 fixtures (swordfish_1/2/3.json); `TestSwordfishExhausted`; 148 tests

- Story #17: XY-wing (PR #52, issue #23) — `XYWing(g Grid, cands Candidates) []SolveStep`; pivot {x,y} + pincers {x,z} + {y,z}; `sees(a,b cell) bool` helper added; single SolveStep; 154 tests

- Story #18: XYZ-wing (PR #53, issue #24) — `XYZWing`; tri-value pivot {x,y,z} + bi-value pincers A⊆P, B⊆P, A∪B=P; eliminates z from cells seeing all three; reuses `sees()`; 160 tests

- Difficulty scale update (PR #54, issue #19 addendum) — grandmaster level added; swordfish/xyWing/xyzWing → master (rank 4); forcedChains → grandmaster (rank 5); 161 tests

- Story #21: Bi-location forced chains (PR #57, issue #56) — extends FC with unit seeds (digit in exactly 2 cells in row/col/box); sequential: bi-value → bi-location → tri-value; dedup by (digit, sorted cell pair); 165 tests

- Story #22: Puzzle corpus generator (PR #59, issue #58) — `backend/scripts/generate_corpus.go`; one JSON file per difficulty in `puzzle_corpus/`; resumable via content-derived IDs; `RateResult(SolveResult)` exported from `difficulty.go`; legendary collected opportunistically (cap 100); `//go:build ignore` on both scripts to avoid linter conflict

- Story: Hint endpoint (PR #62, issue #61) — `POST /puzzle/hint`; accepts grid + optional `[[[int]]]` candidates; returns first SolveStep from the cheapest technique that fires, or `{solved:true}` / `{stuck:true}`; `HumanSolveStep` + `CandidatesFromDigits(Grid, [9][9][]int)` added; chains serialised via shared `toStepResponse`; 171 tests

- Story: SolveStep Sources (PR #64, issue #63) — `Sources []SourceCell` on every `SolveStep`; `maskToDigits` helper; all 14 techniques + wire format; `assertStepsHaveSources` test helper (with chain recursion); nil-guard in `toStepResponse`; 171 tests

## Frontend epics created (2026-06-04)

7 epics created as GitHub issues with `epic` label:
- #65 Foundation, #66 Game Board, #67 Game Management, #68 Scores & Stats, #69 Tutorial, #70 Settings, #71 Forced Chains Helper

Frontend stories to be created autonomously by AI before implementation starts.
Architectural decisions locked: Riverpod, go_router, storage TBD, backend URL configurable (default localhost:8080).
Design: game-like Material 3, review after game board before adding more screens.
Owner approves and merges all frontend PRs.

## Backend: blocked
- Database setup (#25) and puzzle pre-generation (#26) — blocked on DB choice

## Blocked
- Database setup (#25) and puzzle pre-generation (#26) — user needs to investigate DB choice first; skip until unblocked
