package sudoku

import "testing"

// fixtureSwordfishPuzzle returns a puzzle with a column-elimination swordfish.
// Source: test_grids/swordfish_1.json
func fixtureSwordfishPuzzle() Grid {
	return Grid{
		{9, 2, 6, 0, 0, 0, 1, 0, 0},
		{5, 3, 7, 0, 1, 0, 4, 2, 0},
		{8, 4, 1, 0, 0, 0, 6, 0, 3},
		{2, 5, 9, 7, 3, 4, 8, 1, 6},
		{7, 1, 4, 0, 6, 0, 0, 3, 0},
		{3, 6, 8, 1, 2, 0, 0, 4, 0},
		{1, 0, 2, 0, 0, 0, 0, 8, 4},
		{4, 8, 5, 0, 7, 1, 3, 6, 0},
		{6, 0, 3, 0, 0, 0, 0, 0, 1},
	}
}

// fixtureSwordfish2Puzzle returns a second puzzle with a column-elimination swordfish.
// Source: test_grids/swordfish_2.json
func fixtureSwordfish2Puzzle() Grid {
	return Grid{
		{5, 2, 9, 4, 1, 0, 7, 0, 3},
		{0, 0, 6, 0, 0, 3, 0, 0, 2},
		{0, 0, 3, 2, 0, 0, 0, 0, 0},
		{0, 5, 2, 3, 0, 0, 0, 7, 6},
		{6, 3, 7, 0, 5, 0, 2, 0, 0},
		{1, 9, 0, 6, 2, 7, 5, 3, 0},
		{3, 0, 0, 0, 6, 9, 4, 2, 0},
		{2, 0, 0, 8, 3, 0, 6, 0, 0},
		{9, 6, 0, 7, 4, 2, 3, 0, 5},
	}
}

// fixtureSwordfish3Puzzle returns a puzzle with both row- and column-elimination swordfishes.
// Source: test_grids/swordfish_3.json (transcribed from screenshot)
func fixtureSwordfish3Puzzle() Grid {
	return Grid{
		{0, 2, 0, 0, 4, 3, 0, 6, 9},
		{0, 0, 3, 8, 9, 6, 2, 0, 0},
		{9, 6, 0, 0, 2, 5, 0, 3, 0},
		{8, 9, 0, 5, 6, 0, 0, 1, 3},
		{6, 0, 0, 0, 3, 0, 0, 0, 0},
		{0, 3, 0, 0, 8, 1, 0, 2, 6},
		{3, 0, 0, 0, 1, 0, 0, 7, 0},
		{0, 0, 9, 6, 7, 4, 3, 0, 2},
		{2, 7, 0, 3, 5, 8, 0, 9, 0},
	}
}

func TestSwordfish(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no swordfish",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no swordfish",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "swordfish_1 produces column-elimination swordfish",
			grid:    fixtureSwordfishPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertSwordfishValid(t, steps, cands)
				assertHasTechnique(t, steps, TechniqueSwordfishColumn)
			},
		},
		{
			name:    "swordfish_2 produces column-elimination swordfish",
			grid:    fixtureSwordfish2Puzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertSwordfishValid(t, steps, cands)
				assertHasTechnique(t, steps, TechniqueSwordfishColumn)
			},
		},
		{
			name:    "swordfish_3 produces both row- and column-elimination swordfishes",
			grid:    fixtureSwordfish3Puzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertSwordfishValid(t, steps, cands)
				assertHasTechnique(t, steps, TechniqueSwordfishRow)
				assertHasTechnique(t, steps, TechniqueSwordfishColumn)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := Swordfish(tt.grid, cands)
			if tt.wantNil {
				if steps != nil {
					t.Errorf("Swordfish() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("Swordfish() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueSwordfishRow && s.Technique != TechniqueSwordfishColumn {
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

// assertHasTechnique fails if none of the steps use the given technique name.
func assertHasTechnique(t *testing.T, steps []SolveStep, technique string) {
	t.Helper()
	for _, s := range steps {
		if s.Technique == technique {
			return
		}
	}
	t.Errorf("no step with technique %q found", technique)
}

// assertSwordfishValid checks that every elimination is backed by a real swordfish.
func assertSwordfishValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	for _, s := range steps {
		for _, a := range s.Actions {
			bit := uint16(1) << uint(a.Digit-1)
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("(%d,%d) digit=%d: not a candidate before elimination",
					a.Row, a.Col, a.Digit)
				continue
			}
			switch s.Technique {
			case TechniqueSwordfishRow:
				if !hasSwordfishInRows(cands, a.Row, a.Col, a.Digit) {
					t.Errorf("(%d,%d) digit=%d: no swordfish row pattern found", a.Row, a.Col, a.Digit)
				}
			case TechniqueSwordfishColumn:
				if !hasSwordfishInCols(cands, a.Row, a.Col, a.Digit) {
					t.Errorf("(%d,%d) digit=%d: no swordfish column pattern found", a.Row, a.Col, a.Digit)
				}
			}
		}
	}
}

// hasSwordfishInRows reports whether there exist 3 rows (none equal to elimRow)
// each having digit d in 2 or 3 columns, with the union of their column masks
// spanning exactly 3 columns including elimCol.
func hasSwordfishInRows(cands Candidates, elimRow, elimCol, d int) bool {
	bit := uint16(1) << uint(d-1)
	elimColBit := uint16(1) << uint(elimCol)

	type entry struct {
		r       int
		colMask uint16
	}
	var rows []entry
	for r := 0; r < 9; r++ {
		if r == elimRow {
			continue
		}
		var mask uint16
		for c := 0; c < 9; c++ {
			if cands[r][c]&bit != 0 {
				mask |= 1 << uint(c)
			}
		}
		if cnt := popcount(mask); cnt == 2 || cnt == 3 {
			rows = append(rows, entry{r, mask})
		}
	}
	for i := 0; i < len(rows)-2; i++ {
		for j := i + 1; j < len(rows)-1; j++ {
			u12 := rows[i].colMask | rows[j].colMask
			if popcount(u12) > 3 {
				continue
			}
			for k := j + 1; k < len(rows); k++ {
				union := u12 | rows[k].colMask
				if popcount(union) == 3 && union&elimColBit != 0 {
					return true
				}
			}
		}
	}
	return false
}

// hasSwordfishInCols reports whether there exist 3 columns (none equal to
// elimCol) each having digit d in 2 or 3 rows, with the union of their row
// masks spanning exactly 3 rows including elimRow.
func hasSwordfishInCols(cands Candidates, elimRow, elimCol, d int) bool {
	bit := uint16(1) << uint(d-1)
	elimRowBit := uint16(1) << uint(elimRow)

	type entry struct {
		c       int
		rowMask uint16
	}
	var cols []entry
	for c := 0; c < 9; c++ {
		if c == elimCol {
			continue
		}
		var mask uint16
		for r := 0; r < 9; r++ {
			if cands[r][c]&bit != 0 {
				mask |= 1 << uint(r)
			}
		}
		if cnt := popcount(mask); cnt == 2 || cnt == 3 {
			cols = append(cols, entry{c, mask})
		}
	}
	for i := 0; i < len(cols)-2; i++ {
		for j := i + 1; j < len(cols)-1; j++ {
			u12 := cols[i].rowMask | cols[j].rowMask
			if popcount(u12) > 3 {
				continue
			}
			for k := j + 1; k < len(cols); k++ {
				union := u12 | cols[k].rowMask
				if popcount(union) == 3 && union&elimRowBit != 0 {
					return true
				}
			}
		}
	}
	return false
}

func TestSwordfishExhausted(t *testing.T) {
	tests := []struct {
		name string
		grid Grid
	}{
		{name: "swordfish_1", grid: fixtureSwordfishPuzzle()},
		{name: "swordfish_2", grid: fixtureSwordfish2Puzzle()},
		{name: "swordfish_3", grid: fixtureSwordfish3Puzzle()},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)

			steps := Swordfish(tt.grid, cands)
			if len(steps) == 0 {
				t.Fatal("first pass: expected swordfish eliminations, got none")
			}

			for _, s := range steps {
				for _, a := range s.Actions {
					cands.Eliminate(a.Row, a.Col, a.Digit)
				}
			}

			steps2 := Swordfish(tt.grid, cands)
			if steps2 != nil {
				t.Errorf("second pass: expected nil after eliminations applied, got %d step(s)", len(steps2))
			}
		})
	}
}
