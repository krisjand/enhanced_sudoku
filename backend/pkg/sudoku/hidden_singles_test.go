package sudoku

import "testing"

// fixtureHiddenSingleRow returns a grid where digit 5 is a hidden single in
// row 0 at column 0: it is the only cell in row 0 that can hold digit 5,
// but cell (0,0) has multiple candidates.
func fixtureHiddenSingleRow() Grid {
	// Start from the solution and clear all of row 0 except col 4 (digit 7),
	// plus clear a few cells in other rows to open candidates in row 0.
	// The solution's column 0 is {5,6,1,8,4,7,9,2,3}, so digit 5 only appears
	// at (0,0) in column 0 — making it a hidden single in row 0.
	g := fixtureUniqueSolution()
	// Clear row 0 entirely.
	for c := 0; c < 9; c++ {
		g[0][c] = 0
	}
	// Put back digit 7 at (0,4) to constrain the row — 7 is now placed.
	g[0][4] = 7
	return g
}

func TestHiddenSingles(t *testing.T) {
	tests := []struct {
		name      string
		grid      Grid
		wantNil   bool
		wantCheck func(t *testing.T, steps []SolveStep, g Grid, cands Candidates)
	}{
		{
			name:    "empty grid has no hidden singles",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no hidden singles",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "standard puzzle has hidden singles",
			grid:    fixtureStandardPuzzle(),
			wantNil: false,
			wantCheck: func(t *testing.T, steps []SolveStep, g Grid, cands Candidates) {
				t.Helper()
				assertHiddenSinglesValid(t, steps, cands)
			},
		},
		{
			name:    "constructed row hidden single is found",
			grid:    fixtureHiddenSingleRow(),
			wantNil: false,
			wantCheck: func(t *testing.T, steps []SolveStep, g Grid, cands Candidates) {
				t.Helper()
				assertHiddenSinglesValid(t, steps, cands)
				// Digit 5 at (0,0) must appear in a row step.
				found := false
				for _, s := range steps {
					if s.Technique == TechniqueHiddenSingleRow {
						for _, a := range s.Actions {
							if a.Row == 0 && a.Col == 0 && a.Digit == 5 {
								found = true
							}
						}
					}
				}
				if !found {
					t.Error("expected hidden single digit=5 at (0,0) in row, not found")
				}
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := HiddenSingles(tt.grid, cands)

			if tt.wantNil {
				if steps != nil {
					t.Errorf("HiddenSingles() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("HiddenSingles() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueHiddenSingleRow &&
					s.Technique != TechniqueHiddenSingleColumn &&
					s.Technique != TechniqueHiddenSingleBox {
					t.Errorf("unexpected technique %q", s.Technique)
				}
				if s.Duration <= 0 {
					t.Errorf("step %q: Duration should be > 0", s.Technique)
				}
			}
			if tt.wantCheck != nil {
				tt.wantCheck(t, steps, tt.grid, cands)
			}
		})
	}
}

// assertHiddenSinglesValid checks that every returned action is genuinely a
// hidden single in the claimed unit type.
func assertHiddenSinglesValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	for _, s := range steps {
		for _, a := range s.Actions {
			bit := uint16(1) << uint(a.Digit-1)
			switch s.Technique {
			case TechniqueHiddenSingleRow:
				count := 0
				for c := 0; c < 9; c++ {
					if cands[a.Row][c]&bit != 0 {
						count++
					}
				}
				if count != 1 {
					t.Errorf("row hidden single (%d,%d) digit=%d: digit appears %d times in row, want 1",
						a.Row, a.Col, a.Digit, count)
				}
			case TechniqueHiddenSingleColumn:
				count := 0
				for r := 0; r < 9; r++ {
					if cands[r][a.Col]&bit != 0 {
						count++
					}
				}
				if count != 1 {
					t.Errorf("col hidden single (%d,%d) digit=%d: digit appears %d times in col, want 1",
						a.Row, a.Col, a.Digit, count)
				}
			case TechniqueHiddenSingleBox:
				br, bc := (a.Row/3)*3, (a.Col/3)*3
				count := 0
				for dr := 0; dr < 3; dr++ {
					for dc := 0; dc < 3; dc++ {
						if cands[br+dr][bc+dc]&bit != 0 {
							count++
						}
					}
				}
				if count != 1 {
					t.Errorf("box hidden single (%d,%d) digit=%d: digit appears %d times in box, want 1",
						a.Row, a.Col, a.Digit, count)
				}
			}
		}
	}
}
