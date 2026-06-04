---
name: story-map
description: Full Sudoku feature story map with GitHub issue numbers
metadata: 
  node_type: memory
  type: project
  originSessionId: 51113308-feef-4117-9dc3-c5925d806cd1
---

All stories are GitHub issues on krisjand/enhanced_sudoku.

## Foundation

| Issue | Story | Status |
|-------|-------|--------|
| #8  | Story #2: Sudoku solver (Grid type, Candidates/bitmasks, Solve, HasUniqueSolution, time tracking) | Done (PR #27) |
| #9  | Story #3: Puzzle generator (complete grid → remove clues → unique solution) | Done (PR #29) |
| #10 | Story #4: Puzzle API endpoint (GET /puzzle, no difficulty yet) | Done (PR #30) |

## Difficulty analysis techniques (in order)

| Issue | Story | Status |
|-------|-------|--------|
| #11 | Story #5: Naked singles | Done (PR #31) |
| #12 | Story #6: Hidden singles | Done (PR #32) |
| #40 | Story: Locked candidates (pointing pairs/triples + box/line reduction) — slots between hidden singles and naked pairs in techniques slice | Done (PR #41) |
| #13 | Story #7: Naked pairs | Done (PR #35) |
| #14 | Story #8: Hidden pairs | Done (PR #38) |
| #15 | Story #9: Naked triples | Done (PR #43) |
| #16 | Story #10: Hidden triples | Done (PR #46) |
| #17 | Story #11: Naked/hidden quadruples (revisit after triples) | Done (PR #47) |
| #18 | Story #12: Forced chains (bi-value first, then three-value; interleaved stepping; configurable max depth) | Done (PR #48) |

## Difficulty + human solver

| Issue | Story | Status |
|-------|-------|--------|
| #19 | Story #13: Difficulty rating (easy/medium/hard/expert/master/legendary) | Done (PR #49) |
| #20 | Story #14: Human-style solver endpoint (POST /puzzle/solve, step-by-step with timing) | Done (PR #34) |

## Forced chains extension

| Issue | Story | Status |
|-------|-------|--------|
| #56 | Story #21: Bi-location forced chains (seed from units where digit has exactly 2 candidate cells) | Not started |

## Advanced techniques (deferred — complex/expensive)

| Issue | Story | Status |
|-------|-------|--------|
| #21 | Story #15: X-wing | Not started |
| #22 | Story #16: Swordfish | Not started |
| #23 | Story #17: XY-wing | Not started |
| #24 | Story #18: XYZ-wing | Not started |

## Developer tooling

| Issue | Story | Status |
|-------|-------|--------|
| #44 | Puzzle finder endpoint (`GET /puzzle/find?technique=<name>`) | Done (PR #45) |

## Backend infrastructure

| Issue | Story | Status |
|-------|-------|--------|
| #25 | Story #19: Database setup (PostgreSQL likely, migrations in code) | Not started |
| #26 | Story #20: Puzzle pre-generation job (pool per difficulty, timeout, check before generating) | Not started |

## Frontend

Deferred — to be defined after backend is solid.

## Cross-cutting concerns (apply to all stories)

- **Time tracking:** every solving step records execution time (`time.Duration`)
- **Performance:** bitmask candidate tracking, minimal allocations, efficient backtracking
