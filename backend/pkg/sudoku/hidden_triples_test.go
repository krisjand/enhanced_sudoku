package sudoku

import "testing"

func fixtureHiddenTriplesPuzzle() Grid {
	return Grid{
		{0, 0, 0, 0, 0, 1, 0, 3, 0},
		{2, 3, 1, 0, 9, 0, 0, 0, 0},
		{0, 6, 5, 0, 0, 3, 1, 0, 0},
		{6, 7, 8, 9, 2, 4, 3, 0, 0},
		{1, 0, 3, 0, 5, 0, 0, 0, 6},
		{0, 0, 0, 1, 3, 6, 7, 0, 0},
		{0, 0, 9, 3, 6, 0, 5, 7, 0},
		{0, 0, 6, 0, 1, 9, 8, 4, 3},
		{3, 0, 0, 0, 0, 0, 0, 0, 0},
	}
}

// fixtureHiddenTriplesPuzzle2 returns a puzzle where HiddenTriples must win as
// the decisive technique even after simpler techniques are exhausted.
// Generated via GET /puzzle/find?technique=hiddenTriples&max=5000.
func fixtureHiddenTriplesPuzzle2() Grid {
	return Grid{
		{0, 0, 0, 0, 0, 4, 7, 3, 0},
		{0, 0, 9, 5, 1, 0, 0, 0, 0},
		{0, 0, 0, 3, 0, 0, 0, 2, 9},
		{0, 0, 8, 0, 0, 5, 3, 0, 0},
		{0, 7, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 1, 0, 4, 0, 0, 0, 0},
		{2, 0, 0, 0, 3, 8, 0, 7, 0},
		{0, 0, 0, 9, 7, 0, 0, 6, 0},
		{0, 0, 6, 0, 0, 0, 0, 0, 0},
	}
}

func TestHiddenTriples(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no hidden triples",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no hidden triples",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces hidden triple eliminations",
			grid:    fixtureHiddenTriplesPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertHiddenTriplesValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := HiddenTriples(tt.grid, cands)

			if tt.wantNil {
				if steps != nil {
					t.Errorf("HiddenTriples() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("HiddenTriples() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueHiddenTripleRow &&
					s.Technique != TechniqueHiddenTripleColumn &&
					s.Technique != TechniqueHiddenTripleBox {
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

// assertHiddenTriplesValid checks that every elimination is backed by a real hidden triple.
func assertHiddenTriplesValid(t *testing.T, steps []SolveStep, cands Candidates) {
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
			case TechniqueHiddenTripleRow:
				unit = rowUnit(a.Row)
			case TechniqueHiddenTripleColumn:
				unit = colUnit(a.Col)
			case TechniqueHiddenTripleBox:
				unit = boxUnit((a.Row/3)*3 + a.Col/3)
			}
			if !hasHiddenTripleCoveringCell(cands, unit, cell{a.Row, a.Col}, a.Digit) {
				t.Errorf("(%d,%d) digit=%d: no hidden triple found in unit for %q",
					a.Row, a.Col, a.Digit, s.Technique)
			}
		}
	}
}

// hasHiddenTripleCoveringCell reports whether the unit contains a hidden triple
// that includes target, where eliminatedDigit is not one of the triple's three digits.
func hasHiddenTripleCoveringCell(cands Candidates, unit []cell, target cell, eliminatedDigit int) bool {
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

	for d1 := 1; d1 <= 7; d1++ {
		if d1 == eliminatedDigit || posMask[d1] == 0 || popcount(posMask[d1]) > 3 {
			continue
		}
		for d2 := d1 + 1; d2 <= 8; d2++ {
			if d2 == eliminatedDigit || posMask[d2] == 0 || popcount(posMask[d2]) > 3 {
				continue
			}
			u12 := posMask[d1] | posMask[d2]
			if popcount(u12) > 3 {
				continue
			}
			for d3 := d2 + 1; d3 <= 9; d3++ {
				if d3 == eliminatedDigit || posMask[d3] == 0 || popcount(posMask[d3]) > 3 {
					continue
				}
				union := u12 | posMask[d3]
				if popcount(union) == 3 && union&targetBit != 0 {
					return true
				}
			}
		}
	}
	return false
}
