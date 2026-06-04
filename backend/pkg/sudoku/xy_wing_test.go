package sudoku

import "testing"

// fixtureXYWingPuzzle returns a puzzle known to contain XY-wing patterns.
// Source: test_grids/xy_wing.json
func fixtureXYWingPuzzle() Grid {
	return Grid{
		{0, 3, 4, 5, 9, 0, 0, 8, 6},
		{8, 0, 2, 0, 6, 3, 4, 5, 0},
		{6, 0, 5, 4, 0, 8, 0, 0, 0},
		{0, 0, 3, 9, 8, 0, 5, 6, 4},
		{0, 5, 8, 6, 0, 4, 0, 9, 0},
		{9, 4, 6, 0, 0, 5, 8, 0, 0},
		{5, 2, 7, 3, 1, 6, 9, 4, 8},
		{3, 8, 1, 2, 4, 9, 6, 7, 5},
		{4, 6, 9, 8, 5, 7, 1, 2, 3},
	}
}

func TestXYWing(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no xy-wing",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no xy-wing",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces xy-wing eliminations",
			grid:    fixtureXYWingPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertXYWingValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := XYWing(tt.grid, cands)
			if tt.wantNil {
				if steps != nil {
					t.Errorf("XYWing() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("XYWing() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueXYWing {
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

func TestXYWingExhausted(t *testing.T) {
	cands := Init(fixtureXYWingPuzzle())
	steps := XYWing(fixtureXYWingPuzzle(), cands)
	if len(steps) == 0 {
		t.Fatal("first pass: expected xy-wing eliminations, got none")
	}
	for _, s := range steps {
		for _, a := range s.Actions {
			cands.Eliminate(a.Row, a.Col, a.Digit)
		}
	}
	if steps2 := XYWing(fixtureXYWingPuzzle(), cands); steps2 != nil {
		t.Errorf("second pass: expected nil after eliminations applied, got %d step(s)", len(steps2))
	}
}

// assertXYWingValid checks that every elimination is backed by a valid XY-wing triple.
func assertXYWingValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	assertStepsHaveSources(t, steps)
	for _, s := range steps {
		for _, a := range s.Actions {
			zBit := uint16(1) << uint(a.Digit-1)
			if cands[a.Row][a.Col]&zBit == 0 {
				t.Errorf("(%d,%d) digit=%d: not a candidate before elimination",
					a.Row, a.Col, a.Digit)
				continue
			}
			if !hasXYWingFor(cands, cell{a.Row, a.Col}, a.Digit) {
				t.Errorf("(%d,%d) digit=%d: no XY-wing triple found", a.Row, a.Col, a.Digit)
			}
		}
	}
}

// hasXYWingFor reports whether there exists a valid (P,A,B) XY-wing triple
// that justifies eliminating digit z from cell e.
func hasXYWingFor(cands Candidates, e cell, z int) bool {
	zBit := uint16(1) << uint(z-1)

	var bivalue []cell
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if popcount(cands[r][c]) == 2 {
				bivalue = append(bivalue, cell{r, c})
			}
		}
	}

	for _, p := range bivalue {
		pmask := cands[p.r][p.c]
		if pmask&zBit != 0 {
			continue // pivot must not contain z
		}
		xBit := pmask & (^pmask + 1)
		yBit := pmask ^ xBit

		for _, a := range bivalue {
			if a == p || !sees(p, a) || !sees(e, a) {
				continue
			}
			amask := cands[a.r][a.c]
			if amask&xBit == 0 || amask&zBit == 0 {
				continue // A must have {x, z}
			}
			if amask != (xBit | zBit) {
				continue
			}

			bwant := yBit | zBit
			for _, b := range bivalue {
				if b == p || b == a || !sees(p, b) || !sees(e, b) {
					continue
				}
				if cands[b.r][b.c] == bwant {
					return true
				}
			}
		}
	}
	return false
}
