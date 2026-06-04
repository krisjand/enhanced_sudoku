package sudoku

import "testing"

func fixtureHiddenPairsPuzzle() Grid {
	return Grid{
		{7, 2, 0, 4, 0, 8, 0, 3, 0},
		{0, 8, 0, 0, 0, 0, 0, 4, 7},
		{4, 0, 1, 0, 7, 6, 8, 0, 2},
		{8, 1, 0, 7, 3, 9, 0, 0, 0},
		{0, 0, 0, 8, 5, 1, 0, 0, 0},
		{0, 0, 0, 2, 6, 4, 0, 8, 0},
		{2, 0, 9, 6, 8, 0, 4, 1, 3},
		{3, 4, 0, 0, 0, 0, 0, 0, 8},
		{1, 6, 8, 9, 4, 3, 2, 7, 5},
	}
}

func TestHiddenPairs(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no hidden pairs",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no hidden pairs",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces hidden pair eliminations",
			grid:    fixtureHiddenPairsPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertHiddenPairsValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := HiddenPairs(tt.grid, cands)

			if tt.wantNil {
				if steps != nil {
					t.Errorf("HiddenPairs() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("HiddenPairs() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueHiddenPairRow &&
					s.Technique != TechniqueHiddenPairColumn &&
					s.Technique != TechniqueHiddenPairBox {
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

// assertHiddenPairsValid checks that every elimination is backed by a real hidden pair.
func assertHiddenPairsValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	assertStepsHaveSources(t, steps)
	for _, s := range steps {
		for _, a := range s.Actions {
			bit := uint16(1) << uint(a.Digit-1)
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("(%d,%d) digit=%d: not a candidate before elimination",
					a.Row, a.Col, a.Digit)
				continue
			}
			var unit []cell
			switch s.Technique {
			case TechniqueHiddenPairRow:
				unit = rowUnit(a.Row)
			case TechniqueHiddenPairColumn:
				unit = colUnit(a.Col)
			case TechniqueHiddenPairBox:
				unit = boxUnit((a.Row/3)*3 + a.Col/3)
			}
			if !hasHiddenPairCoveringCell(cands, unit, cell{a.Row, a.Col}) {
				t.Errorf("(%d,%d): no hidden pair found in unit for %q", a.Row, a.Col, s.Technique)
			}
		}
	}
}

// hasHiddenPairCoveringCell reports whether the unit contains a hidden pair
// that includes the target cell (i.e. two digits each appearing in exactly
// two cells, one of which is target).
func hasHiddenPairCoveringCell(cands Candidates, unit []cell, target cell) bool {
	for d1 := 1; d1 <= 8; d1++ {
		bit1 := uint16(1) << uint(d1-1)
		if cands[target.r][target.c]&bit1 == 0 {
			continue
		}
		var c1 [2]cell
		n1 := 0
		for _, pos := range unit {
			if cands[pos.r][pos.c]&bit1 != 0 {
				if n1 == 2 {
					n1 = 3
					break
				}
				c1[n1] = pos
				n1++
			}
		}
		if n1 != 2 || (c1[0] != target && c1[1] != target) {
			continue
		}
		for d2 := d1 + 1; d2 <= 9; d2++ {
			bit2 := uint16(1) << uint(d2-1)
			var c2 [2]cell
			n2 := 0
			for _, pos := range unit {
				if cands[pos.r][pos.c]&bit2 != 0 {
					if n2 == 2 {
						n2 = 3
						break
					}
					c2[n2] = pos
					n2++
				}
			}
			if n2 == 2 && c1[0] == c2[0] && c1[1] == c2[1] {
				return true
			}
		}
	}
	return false
}
