package sudoku

import "testing"

// fixtureXYZWing2Puzzle returns a puzzle where XYZWing fires from the initial
// candidate state.
// Source: test_grids/xyz_wing_2.json
func fixtureXYZWing2Puzzle() Grid {
	return Grid{
		{6, 0, 0, 0, 0, 0, 0, 0, 8},
		{5, 0, 0, 9, 0, 8, 0, 0, 7},
		{8, 2, 0, 0, 0, 1, 0, 3, 0},
		{3, 4, 0, 2, 0, 9, 0, 8, 0},
		{2, 0, 0, 0, 8, 0, 3, 0, 0},
		{1, 8, 0, 3, 0, 7, 0, 2, 5},
		{7, 5, 0, 4, 0, 0, 0, 9, 2},
		{9, 0, 0, 0, 0, 5, 0, 0, 4},
		{4, 0, 0, 0, 9, 0, 0, 0, 3},
	}
}

func TestXYZWing(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no xyz-wing",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no xyz-wing",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "xyz_wing_2 produces xyz-wing eliminations from initial state",
			grid:    fixtureXYZWing2Puzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertXYZWingValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := XYZWing(tt.grid, cands)
			if tt.wantNil {
				if steps != nil {
					t.Errorf("XYZWing() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("XYZWing() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueXYZWing {
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

func TestXYZWingExhausted(t *testing.T) {
	cands := Init(fixtureXYZWing2Puzzle())
	steps := XYZWing(fixtureXYZWing2Puzzle(), cands)
	if len(steps) == 0 {
		t.Fatal("first pass: expected xyz-wing eliminations, got none")
	}
	for _, s := range steps {
		for _, a := range s.Actions {
			cands.Eliminate(a.Row, a.Col, a.Digit)
		}
	}
	if steps2 := XYZWing(fixtureXYZWing2Puzzle(), cands); steps2 != nil {
		t.Errorf("second pass: expected nil after eliminations applied, got %d step(s)", len(steps2))
	}
}

// assertXYZWingValid checks that every elimination is backed by a valid XYZ-wing triple.
func assertXYZWingValid(t *testing.T, steps []SolveStep, cands Candidates) {
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
			if !hasXYZWingFor(cands, cell{a.Row, a.Col}, a.Digit) {
				t.Errorf("(%d,%d) digit=%d: no XYZ-wing triple found", a.Row, a.Col, a.Digit)
			}
		}
	}
}

// hasXYZWingFor reports whether there exists a valid (P,A,B) XYZ-wing triple
// that justifies eliminating digit z from cell e.
func hasXYZWingFor(cands Candidates, e cell, z int) bool {
	zBit := uint16(1) << uint(z-1)

	var bivalue []cell
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if popcount(cands[r][c]) == 2 {
				bivalue = append(bivalue, cell{r, c})
			}
		}
	}

	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			pmask := cands[r][c]
			if popcount(pmask) != 3 || pmask&zBit == 0 {
				continue // pivot must be tri-value and contain z
			}
			p := cell{r, c}
			if !sees(e, p) {
				continue
			}

			for _, a := range bivalue {
				if a == p || !sees(p, a) || !sees(e, a) {
					continue
				}
				amask := cands[a.r][a.c]
				if amask&^pmask != 0 || amask&zBit == 0 {
					continue
				}

				for _, b := range bivalue {
					if b == p || b == a || !sees(p, b) || !sees(e, b) {
						continue
					}
					bmask := cands[b.r][b.c]
					if bmask&^pmask != 0 || bmask&zBit == 0 {
						continue
					}
					if amask|bmask != pmask {
						continue
					}
					if amask&bmask == zBit {
						return true
					}
				}
			}
		}
	}
	return false
}
