package sudoku

import "testing"

// fixtureNakedQuadruplesPuzzle returns a puzzle known to contain naked quadruples.
// Source: test_grids/naked_quad.json
func fixtureNakedQuadruplesPuzzle() Grid {
	return Grid{
		{0, 0, 0, 0, 3, 0, 0, 8, 6},
		{0, 0, 0, 0, 2, 0, 0, 4, 0},
		{0, 9, 0, 0, 7, 8, 5, 2, 0},
		{3, 7, 1, 8, 5, 6, 2, 9, 4},
		{9, 0, 0, 1, 4, 2, 3, 7, 5},
		{4, 0, 0, 3, 9, 7, 6, 1, 8},
		{2, 0, 0, 7, 0, 3, 8, 5, 9},
		{0, 3, 9, 2, 0, 5, 4, 6, 7},
		{7, 0, 0, 9, 0, 4, 1, 3, 2},
	}
}

// fixtureNakedQuadruplesHumanSolvePuzzle returns a puzzle where NakedQuadruples
// must win as the decisive technique even after simpler techniques are exhausted.
// Generated via GET /puzzle/find?technique=nakedQuadruples&max=10000.
func fixtureNakedQuadruplesHumanSolvePuzzle() Grid {
	return Grid{
		{0, 0, 5, 0, 0, 0, 0, 7, 0},
		{0, 0, 0, 4, 0, 9, 2, 6, 0},
		{8, 6, 0, 2, 0, 0, 0, 0, 0},
		{0, 9, 0, 0, 0, 0, 1, 5, 0},
		{0, 5, 0, 0, 0, 8, 0, 0, 6},
		{1, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 6, 2, 0, 0, 0, 9},
		{0, 0, 0, 0, 0, 7, 0, 3, 0},
		{2, 3, 0, 9, 8, 0, 0, 0, 0},
	}
}

func TestNakedQuadruples(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no naked quadruples",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no naked quadruples",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces naked quadruple eliminations",
			grid:    fixtureNakedQuadruplesPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertNakedQuadruplesValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := NakedQuadruples(tt.grid, cands)
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

// assertNakedQuadruplesValid checks structural correctness of NakedQuadruples output:
// every eliminated digit must be a candidate in the target cell, and the target
// cell must not be one of the four naked-quadruple members.
func assertNakedQuadruplesValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	for _, s := range steps {
		for _, a := range s.Actions {
			if a.Type != ActionEliminate {
				t.Errorf("expected ActionEliminate, got %v at (%d,%d)", a.Type, a.Row, a.Col)
				continue
			}
			bit := uint16(1) << uint(a.Digit-1)
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("digit %d is not a candidate at (%d,%d)", a.Digit, a.Row, a.Col)
			}
			switch s.Technique {
			case TechniqueNakedQuadruplesRow:
				if !hasNakedQuadrupleInUnit(cands, rowUnit(a.Row), a.Row, a.Col, bit) {
					t.Errorf("no naked quadruple for digit=%d in row %d excluding (%d,%d)", a.Digit, a.Row, a.Row, a.Col)
				}
			case TechniqueNakedQuadruplesColumn:
				if !hasNakedQuadrupleInUnit(cands, colUnit(a.Col), a.Row, a.Col, bit) {
					t.Errorf("no naked quadruple for digit=%d in col %d excluding (%d,%d)", a.Digit, a.Col, a.Row, a.Col)
				}
			case TechniqueNakedQuadruplesBox:
				b := (a.Row/3)*3 + a.Col/3
				if !hasNakedQuadrupleInUnit(cands, boxUnit(b), a.Row, a.Col, bit) {
					t.Errorf("no naked quadruple for digit=%d in box %d excluding (%d,%d)", a.Digit, b, a.Row, a.Col)
				}
			}
		}
	}
}

// hasNakedQuadrupleInUnit reports whether the unit contains a naked quadruple
// whose combined candidates include bit, where none of the four members is
// (targetRow, targetCol).
func hasNakedQuadrupleInUnit(cands Candidates, unit []cell, targetRow, targetCol int, bit uint16) bool {
	var members []cell
	for _, pos := range unit {
		n := popcount(cands[pos.r][pos.c])
		if n >= 2 && n <= 4 {
			members = append(members, pos)
		}
	}
	for i := 0; i < len(members)-3; i++ {
		for j := i + 1; j < len(members)-2; j++ {
			for k := j + 1; k < len(members)-1; k++ {
				for l := k + 1; l < len(members); l++ {
					a, b, c, d := members[i], members[j], members[k], members[l]
					if (a.r == targetRow && a.c == targetCol) ||
						(b.r == targetRow && b.c == targetCol) ||
						(c.r == targetRow && c.c == targetCol) ||
						(d.r == targetRow && d.c == targetCol) {
						continue
					}
					union := cands[a.r][a.c] | cands[b.r][b.c] | cands[c.r][c.c] | cands[d.r][d.c]
					if popcount(union) == 4 && union&bit != 0 {
						return true
					}
				}
			}
		}
	}
	return false
}
