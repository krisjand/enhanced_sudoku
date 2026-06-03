package sudoku

import "testing"

// fixtureXWingPuzzle returns a puzzle known to contain an X-wing pattern.
// Source: test_grids/x_wing.json
func fixtureXWingPuzzle() Grid {
	return Grid{
		{1, 0, 0, 0, 0, 0, 5, 6, 9},
		{4, 9, 2, 0, 5, 6, 1, 0, 8},
		{0, 5, 6, 1, 0, 9, 2, 4, 0},
		{0, 0, 9, 6, 4, 0, 8, 0, 1},
		{0, 6, 4, 0, 1, 0, 0, 0, 0},
		{2, 1, 8, 0, 3, 5, 6, 0, 4},
		{0, 4, 0, 5, 0, 0, 0, 1, 6},
		{9, 0, 5, 0, 6, 1, 4, 0, 2},
		{6, 2, 1, 0, 0, 0, 0, 0, 5},
	}
}

func TestXWing(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no x-wing",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no x-wing",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces x-wing eliminations",
			grid:    fixtureXWingPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertXWingValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := XWing(tt.grid, cands)
			if tt.wantNil {
				if steps != nil {
					t.Errorf("XWing() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("XWing() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueXWingRow && s.Technique != TechniqueXWingColumn {
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

// assertXWingValid checks that every elimination is backed by a real X-wing.
func assertXWingValid(t *testing.T, steps []SolveStep, cands Candidates) {
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
			case TechniqueXWingRow:
				if !hasXWingInRows(cands, a.Row, a.Col, a.Digit) {
					t.Errorf("(%d,%d) digit=%d: no x-wing row pattern found", a.Row, a.Col, a.Digit)
				}
			case TechniqueXWingColumn:
				if !hasXWingInCols(cands, a.Row, a.Col, a.Digit) {
					t.Errorf("(%d,%d) digit=%d: no x-wing column pattern found", a.Row, a.Col, a.Digit)
				}
			}
		}
	}
}

// hasXWingInRows reports whether there exist two rows (neither equal to elimRow)
// each having digit d as a candidate in exactly two columns, one of which is
// elimCol, and those two columns are the same pair.
func hasXWingInRows(cands Candidates, elimRow, elimCol, d int) bool {
	bit := uint16(1) << uint(d-1)
	type entry struct{ c1, c2 int }
	var rows []struct {
		r  int
		e  entry
	}
	for r := 0; r < 9; r++ {
		if r == elimRow {
			continue
		}
		var c1, c2 int
		count := 0
		for c := 0; c < 9; c++ {
			if cands[r][c]&bit != 0 {
				switch count {
				case 0:
					c1 = c
				case 1:
					c2 = c
				}
				count++
			}
		}
		if count == 2 && (c1 == elimCol || c2 == elimCol) {
			rows = append(rows, struct {
				r int
				e entry
			}{r, entry{c1, c2}})
		}
	}
	for i := 0; i < len(rows)-1; i++ {
		for j := i + 1; j < len(rows); j++ {
			if rows[i].e == rows[j].e {
				return true
			}
		}
	}
	return false
}

// hasXWingInCols reports whether there exist two columns (neither equal to
// elimCol) each having digit d as a candidate in exactly two rows, one of
// which is elimRow, and those two rows are the same pair.
func hasXWingInCols(cands Candidates, elimRow, elimCol, d int) bool {
	bit := uint16(1) << uint(d-1)
	type entry struct{ r1, r2 int }
	var cols []struct {
		c int
		e entry
	}
	for c := 0; c < 9; c++ {
		if c == elimCol {
			continue
		}
		var r1, r2 int
		count := 0
		for r := 0; r < 9; r++ {
			if cands[r][c]&bit != 0 {
				switch count {
				case 0:
					r1 = r
				case 1:
					r2 = r
				}
				count++
			}
		}
		if count == 2 && (r1 == elimRow || r2 == elimRow) {
			cols = append(cols, struct {
				c int
				e entry
			}{c, entry{r1, r2}})
		}
	}
	for i := 0; i < len(cols)-1; i++ {
		for j := i + 1; j < len(cols); j++ {
			if cols[i].e == cols[j].e {
				return true
			}
		}
	}
	return false
}

func TestXWingExhausted(t *testing.T) {
	cands := Init(fixtureXWingPuzzle())
	steps := XWing(fixtureXWingPuzzle(), cands)
	if len(steps) == 0 {
		t.Fatal("first pass: expected x-wing eliminations, got none")
	}
	for _, s := range steps {
		for _, a := range s.Actions {
			cands.Eliminate(a.Row, a.Col, a.Digit)
		}
	}
	if steps2 := XWing(fixtureXWingPuzzle(), cands); steps2 != nil {
		t.Errorf("second pass: expected nil after eliminations applied, got %d step(s)", len(steps2))
	}
}
