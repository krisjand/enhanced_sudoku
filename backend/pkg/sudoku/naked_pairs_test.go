package sudoku

import "testing"

// fixtureNakedPairsPuzzle returns a puzzle known to contain multiple naked pairs.
// Verified pairs after Init:
//   - Row 0: (0,1) and (0,2) share {1,6}
//   - Row 2: (2,5) and (2,8) share {6,7}
//   - Box pairs in boxes 4 and 5
func fixtureNakedPairsPuzzle(modifiers ...func(*Grid)) Grid {
	g := Grid{
		{4, 0, 0, 0, 0, 0, 9, 3, 8},
		{0, 3, 2, 0, 9, 4, 1, 0, 0},
		{0, 9, 5, 3, 0, 0, 2, 4, 0},
		{3, 7, 0, 6, 0, 9, 0, 0, 4},
		{5, 2, 9, 0, 0, 1, 6, 7, 3},
		{6, 0, 4, 7, 0, 3, 0, 9, 0},
		{9, 5, 7, 0, 0, 8, 3, 0, 0},
		{0, 0, 3, 9, 0, 0, 4, 0, 0},
		{2, 4, 0, 0, 3, 0, 7, 0, 9},
	}
	for _, m := range modifiers {
		m(&g)
	}
	return g
}

// fixtureNakedPairs2Puzzle returns a puzzle where NakedPairs must win as the
// decisive technique even after LockedCandidates has already made progress.
func fixtureNakedPairs2Puzzle() Grid {
	return Grid{
		{0, 8, 0, 0, 9, 0, 0, 3, 0},
		{0, 3, 0, 0, 0, 0, 0, 6, 9},
		{9, 0, 2, 0, 6, 3, 1, 5, 8},
		{0, 2, 0, 8, 0, 4, 5, 9, 0},
		{8, 5, 1, 9, 0, 7, 0, 4, 6},
		{3, 9, 4, 6, 0, 5, 8, 7, 0},
		{5, 6, 3, 0, 4, 0, 9, 8, 7},
		{2, 0, 0, 0, 0, 0, 0, 1, 5},
		{0, 1, 0, 0, 5, 0, 0, 2, 0},
	}
}

func TestNakedPairs(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no naked pairs",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no naked pairs",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces row and box naked pairs",
			grid:    fixtureNakedPairsPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertNakedPairsValid(t, steps, cands)

				// Verify the known row pair {1,6} at (0,1)+(0,2) produced eliminations.
				assertEliminationFound(t, steps, 1, 0, 3, TechniqueNakedPairRow)
				assertEliminationFound(t, steps, 6, 0, 5, TechniqueNakedPairRow)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := NakedPairs(tt.grid, cands)

			if tt.wantNil {
				if steps != nil {
					t.Errorf("NakedPairs() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("NakedPairs() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueNakedPairRow &&
					s.Technique != TechniqueNakedPairColumn &&
					s.Technique != TechniqueNakedPairBox {
					t.Errorf("unexpected technique %q", s.Technique)
				}
				for _, a := range s.Actions {
					if a.Type != ActionEliminate {
						t.Errorf("expected ActionEliminate, got %v", a.Type)
					}
				}
			}
			if tt.check != nil {
				tt.check(t, steps, cands)
			}
		})
	}
}

// assertNakedPairsValid checks that every elimination is backed by a real naked pair.
func assertNakedPairsValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	for _, s := range steps {
		for _, a := range s.Actions {
			bit := uint16(1) << uint(a.Digit-1)
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("(%d,%d) digit=%d: not a candidate before elimination",
					a.Row, a.Col, a.Digit)
			}
			switch s.Technique {
			case TechniqueNakedPairRow:
				if !hasNakedPairInUnit(cands, rowUnit(a.Row), bit) {
					t.Errorf("no naked pair for digit=%d found in row %d", a.Digit, a.Row)
				}
			case TechniqueNakedPairColumn:
				if !hasNakedPairInUnit(cands, colUnit(a.Col), bit) {
					t.Errorf("no naked pair for digit=%d found in col %d", a.Digit, a.Col)
				}
			case TechniqueNakedPairBox:
				b := (a.Row/3)*3 + a.Col/3
				if !hasNakedPairInUnit(cands, boxUnit(b), bit) {
					t.Errorf("no naked pair for digit=%d found in box %d", a.Digit, b)
				}
			}
		}
	}
}

// assertEliminationFound checks that a specific elimination appears in the given technique's step.
func assertEliminationFound(t *testing.T, steps []SolveStep, digit, row, col int, technique string) {
	t.Helper()
	for _, s := range steps {
		if s.Technique != technique {
			continue
		}
		for _, a := range s.Actions {
			if a.Digit == digit && a.Row == row && a.Col == col {
				return
			}
		}
	}
	t.Errorf("expected elimination of digit=%d at (%d,%d) in %q, not found", digit, row, col, technique)
}

// hasNakedPairInUnit reports whether the unit contains two cells with identical
// 2-candidate masks that include the given bit.
func hasNakedPairInUnit(cands Candidates, unit []cell, bit uint16) bool {
	for i := 0; i < len(unit)-1; i++ {
		a := unit[i]
		if popcount(cands[a.r][a.c]) != 2 || cands[a.r][a.c]&bit == 0 {
			continue
		}
		for j := i + 1; j < len(unit); j++ {
			b := unit[j]
			if cands[a.r][a.c] == cands[b.r][b.c] {
				return true
			}
		}
	}
	return false
}
