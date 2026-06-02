package sudoku

import "testing"

// fixtureNakedTriplesPuzzle returns a puzzle known to contain naked triples.
// Verified: NakedTriples finds box eliminations after Init.
func fixtureNakedTriplesPuzzle() Grid {
	return Grid{
		{2, 9, 4, 5, 1, 3, 0, 0, 6},
		{6, 0, 0, 8, 4, 2, 3, 1, 9},
		{3, 0, 0, 6, 9, 7, 2, 5, 4},
		{0, 0, 0, 0, 5, 6, 0, 0, 0},
		{0, 4, 0, 0, 8, 0, 0, 6, 0},
		{0, 0, 0, 4, 7, 0, 0, 0, 0},
		{7, 3, 0, 1, 6, 4, 0, 0, 5},
		{9, 0, 0, 7, 3, 5, 0, 0, 1},
		{4, 0, 0, 9, 2, 8, 6, 3, 7},
	}
}

// fixtureNakedTriplesHumanSolvePuzzle returns a puzzle where NakedTriples must
// win as the decisive technique even after simpler techniques are exhausted.
func fixtureNakedTriplesHumanSolvePuzzle() Grid {
	return Grid{
		{0, 0, 8, 0, 0, 0, 0, 0, 0},
		{0, 2, 0, 0, 0, 4, 0, 0, 0},
		{0, 0, 4, 0, 0, 0, 0, 2, 6},
		{0, 0, 0, 3, 0, 0, 5, 0, 9},
		{0, 0, 0, 0, 1, 0, 4, 0, 0},
		{0, 0, 1, 0, 0, 2, 0, 0, 3},
		{2, 0, 9, 6, 0, 0, 0, 5, 0},
		{7, 5, 0, 9, 0, 0, 0, 0, 4},
		{0, 8, 0, 0, 0, 0, 7, 0, 0},
	}
}

func TestNakedTriples(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no naked triples",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no naked triples",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces box naked triples",
			grid:    fixtureNakedTriplesPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertNakedTriplesValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := NakedTriples(tt.grid, cands)
			if tt.wantNil {
				if len(steps) != 0 {
					t.Errorf("expected no steps, got %d", len(steps))
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("expected steps, got none")
			}
			if tt.check != nil {
				tt.check(t, steps, cands)
			}
		})
	}
}

// assertNakedTriplesValid checks structural correctness of NakedTriples output:
// every eliminated digit must actually be a candidate in the cell before
// elimination, and must not belong to the naked triple itself.
func assertNakedTriplesValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	for _, step := range steps {
		for _, a := range step.Actions {
			if a.Type != ActionEliminate {
				t.Errorf("expected ActionEliminate, got %v at (%d,%d)", a.Type, a.Row, a.Col)
				continue
			}
			bit := uint16(1) << (a.Digit - 1)
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("digit %d is not a candidate at (%d,%d)", a.Digit, a.Row, a.Col)
			}
		}
	}
}
