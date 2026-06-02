package sudoku

import "testing"

// fixtureNakedPairRow returns a grid with a naked pair {1,2} at (0,0) and (0,1) in row 0.
// Row 0 has 3-8 placed, leaving (0,0), (0,1), and (0,8) empty.
// Columns 0 and 1 each have {3–9} placed so (0,0) and (0,1) are both constrained to {1,2}.
// Column 8 has {1,3–8} placed and box 2 has 1 placed, so (0,8) = {2,9}.
// The naked pair eliminates digit 2 from (0,8).
func fixtureNakedPairRow(modifiers ...func(*Grid)) Grid {
	g := Grid{
		{0, 0, 3, 4, 5, 6, 7, 8, 0},
		{4, 6, 0, 0, 0, 0, 0, 0, 1},
		{5, 7, 0, 0, 0, 0, 0, 0, 3},
		{6, 5, 0, 0, 0, 0, 0, 0, 4},
		{7, 8, 0, 0, 0, 0, 0, 0, 5},
		{9, 3, 0, 0, 0, 0, 0, 0, 6},
		{8, 9, 0, 0, 0, 0, 0, 0, 7},
		{3, 4, 0, 0, 0, 0, 0, 0, 8},
		{0, 0, 0, 0, 0, 0, 0, 0, 0},
	}
	for _, m := range modifiers {
		m(&g)
	}
	return g
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
			name:    "constructed naked pair produces eliminations",
			grid:    fixtureNakedPairRow(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertNakedPairsValid(t, steps, cands)
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
			// The eliminated digit must have been a candidate in that cell.
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("(%d,%d) digit=%d: not a candidate before elimination",
					a.Row, a.Col, a.Digit)
			}
			// There must exist a naked pair in the claimed unit that justifies it.
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

// hasNakedPairInUnit reports whether the unit contains two cells with identical
// 2-candidate masks, and that mask includes the given bit.
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
