package sudoku

import "testing"

// fixtureHiddenQuadruplesPuzzle returns a puzzle known to contain hidden quadruples.
// Source: test_grids/hidden_quad_1.json
func fixtureHiddenQuadruplesPuzzle() Grid {
	return Grid{
		{9, 6, 7, 8, 3, 2, 4, 5, 1},
		{5, 0, 0, 4, 9, 7, 8, 6, 0},
		{8, 0, 0, 1, 6, 5, 0, 7, 9},
		{0, 9, 2, 5, 0, 0, 7, 8, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 3, 0, 0, 0, 9, 5, 1, 0},
		{3, 0, 6, 9, 0, 8, 0, 0, 7},
		{2, 7, 0, 3, 0, 6, 0, 0, 8},
		{0, 8, 9, 7, 2, 0, 6, 3, 5},
	}
}

// fixtureHiddenQuadruplesPuzzle2 returns a second puzzle with hidden quadruples.
// Source: test_grids/hidden_quad_2.json
func fixtureHiddenQuadruplesPuzzle2() Grid {
	return Grid{
		{9, 0, 1, 5, 0, 0, 0, 4, 6},
		{4, 2, 5, 0, 9, 0, 0, 8, 1},
		{8, 6, 0, 0, 1, 0, 0, 2, 0},
		{5, 0, 2, 0, 0, 0, 0, 0, 0},
		{0, 1, 9, 0, 0, 0, 4, 6, 0},
		{6, 0, 0, 0, 0, 0, 0, 0, 2},
		{1, 9, 6, 0, 4, 0, 2, 5, 3},
		{2, 0, 0, 0, 6, 0, 8, 1, 7},
		{0, 0, 0, 0, 0, 1, 6, 9, 4},
	}
}

func TestHiddenQuadruples(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no hidden quadruples",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no hidden quadruples",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces hidden quadruple eliminations",
			grid:    fixtureHiddenQuadruplesPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertHiddenQuadruplesValid(t, steps, cands)
			},
		},
		{
			name:    "second real puzzle produces hidden quadruple eliminations",
			grid:    fixtureHiddenQuadruplesPuzzle2(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertHiddenQuadruplesValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := HiddenQuadruples(tt.grid, cands)
			if tt.wantNil {
				if steps != nil {
					t.Errorf("HiddenQuadruples() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("HiddenQuadruples() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueHiddenQuadruplesRow &&
					s.Technique != TechniqueHiddenQuadruplesColumn &&
					s.Technique != TechniqueHiddenQuadruplesBox {
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

// assertHiddenQuadruplesValid checks that every elimination is backed by a real hidden quadruple.
func assertHiddenQuadruplesValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
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
			case TechniqueHiddenQuadruplesRow:
				unit = rowUnit(a.Row)
			case TechniqueHiddenQuadruplesColumn:
				unit = colUnit(a.Col)
			case TechniqueHiddenQuadruplesBox:
				unit = boxUnit((a.Row/3)*3 + a.Col/3)
			}
			if !hasHiddenQuadrupleCoveringCell(cands, unit, cell{a.Row, a.Col}, a.Digit) {
				t.Errorf("(%d,%d) digit=%d: no hidden quadruple found in unit for %q",
					a.Row, a.Col, a.Digit, s.Technique)
			}
		}
	}
}

// hasHiddenQuadrupleCoveringCell reports whether the unit contains a hidden
// quadruple that includes target, where eliminatedDigit is not one of the four
// quadruple digits.
func hasHiddenQuadrupleCoveringCell(cands Candidates, unit []cell, target cell, eliminatedDigit int) bool {
	var posMask [10]uint16
	targetIdx := -1
	for i, pos := range unit {
		if pos == target {
			targetIdx = i
		}
		c := cands[pos.r][pos.c]
		for d := 1; d <= 9; d++ {
			if c&(1<<uint(d-1)) != 0 {
				posMask[d] |= 1 << uint(i)
			}
		}
	}
	if targetIdx < 0 {
		return false
	}
	targetBit := uint16(1) << uint(targetIdx)

	for d1 := 1; d1 <= 6; d1++ {
		if d1 == eliminatedDigit || posMask[d1] == 0 || popcount(posMask[d1]) > 4 {
			continue
		}
		for d2 := d1 + 1; d2 <= 7; d2++ {
			if d2 == eliminatedDigit || posMask[d2] == 0 || popcount(posMask[d2]) > 4 {
				continue
			}
			u12 := posMask[d1] | posMask[d2]
			if popcount(u12) > 4 {
				continue
			}
			for d3 := d2 + 1; d3 <= 8; d3++ {
				if d3 == eliminatedDigit || posMask[d3] == 0 || popcount(posMask[d3]) > 4 {
					continue
				}
				u123 := u12 | posMask[d3]
				if popcount(u123) > 4 {
					continue
				}
				for d4 := d3 + 1; d4 <= 9; d4++ {
					if d4 == eliminatedDigit || posMask[d4] == 0 || popcount(posMask[d4]) > 4 {
						continue
					}
					union := u123 | posMask[d4]
					if popcount(union) == 4 && union&targetBit != 0 {
						return true
					}
				}
			}
		}
	}
	return false
}
