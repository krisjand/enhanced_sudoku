package sudoku

import "testing"

// fixtureNakedTriplesPuzzle returns a puzzle known to contain naked triples.
// Source: test_grids/naked_triple.json
func fixtureNakedTriplesPuzzle() Grid {
	return Grid{
		{2, 9, 4, 5, 1, 3, 0, 0, 6},
		{6, 0, 0, 8, 4, 2, 3, 1, 9},
		{3, 0, 0, 6, 9, 7, 2, 5, 4},
		{0, 0, 0, 0, 5, 6, 0, 0, 0},
		{0, 4, 0, 0, 8, 0, 0, 6, 0},
		{0, 0, 0, 4, 7, 0, 0, 0, 0},
		{7, 3, 0, 1, 6, 4, 0, 0, 5},
		{9, 0, 0, 7, 3, 5, 0, 0, 1},
		{4, 0, 0, 9, 2, 8, 6, 3, 7},
	}
}

// fixtureNakedTriplesPuzzle2 returns a second puzzle known to contain naked triples.
// Source: test_grids/naked_triple_2.json
func fixtureNakedTriplesPuzzle2() Grid {
	return Grid{
		{0, 7, 0, 4, 0, 8, 0, 2, 9},
		{0, 0, 2, 0, 0, 0, 0, 0, 4},
		{8, 5, 4, 0, 2, 0, 0, 0, 7},
		{0, 0, 8, 3, 7, 4, 2, 0, 0},
		{0, 2, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 3, 2, 6, 1, 7, 0, 0},
		{0, 0, 0, 0, 9, 3, 6, 1, 2},
		{2, 0, 0, 0, 0, 0, 4, 0, 3},
		{1, 3, 0, 6, 4, 2, 0, 7, 0},
	}
}

// fixtureNakedTriplesHumanSolvePuzzle returns a puzzle where NakedTriples must
// win as the decisive technique even after simpler techniques are exhausted.
// Source: test_grids/naked_triple_3.json
func fixtureNakedTriplesHumanSolvePuzzle() Grid {
	return Grid{
		{0, 0, 8, 0, 0, 0, 0, 0, 0},
		{0, 2, 0, 0, 0, 4, 0, 0, 0},
		{0, 0, 4, 0, 0, 0, 0, 2, 6},
		{0, 0, 0, 3, 0, 0, 5, 0, 9},
		{0, 0, 0, 0, 1, 0, 4, 0, 0},
		{0, 0, 1, 0, 0, 2, 0, 0, 3},
		{2, 0, 9, 6, 0, 0, 0, 5, 0},
		{7, 5, 0, 9, 0, 0, 0, 0, 4},
		{0, 8, 0, 0, 0, 0, 7, 0, 0},
	}
}

func TestNakedTriples(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no naked triples",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no naked triples",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces box naked triples",
			grid:    fixtureNakedTriplesPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertNakedTriplesValid(t, steps, cands)
			},
		},
		{
			name:    "second real puzzle produces naked triple eliminations",
			grid:    fixtureNakedTriplesPuzzle2(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertNakedTriplesValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := NakedTriples(tt.grid, cands)
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

// assertNakedTriplesValid checks structural correctness of NakedTriples output:
// every eliminated digit must be a candidate in the target cell, and the target
// cell must not be one of the three naked-triple members (i.e. a real triple in
// the unit must justify the elimination without including the target cell).
func assertNakedTriplesValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	assertStepsHaveSources(t, steps)
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
			case TechniqueNakedTripleRow:
				if !hasNakedTripleInUnit(cands, rowUnit(a.Row), a.Row, a.Col, bit) {
					t.Errorf("no naked triple for digit=%d in row %d excluding (%d,%d)", a.Digit, a.Row, a.Row, a.Col)
				}
			case TechniqueNakedTripleColumn:
				if !hasNakedTripleInUnit(cands, colUnit(a.Col), a.Row, a.Col, bit) {
					t.Errorf("no naked triple for digit=%d in col %d excluding (%d,%d)", a.Digit, a.Col, a.Row, a.Col)
				}
			case TechniqueNakedTripleBox:
				b := (a.Row/3)*3 + a.Col/3
				if !hasNakedTripleInUnit(cands, boxUnit(b), a.Row, a.Col, bit) {
					t.Errorf("no naked triple for digit=%d in box %d excluding (%d,%d)", a.Digit, b, a.Row, a.Col)
				}
			}
		}
	}
}

// hasNakedTripleInUnit reports whether the unit contains a naked triple whose
// combined candidates include bit, where none of the triple members is (targetRow, targetCol).
// This confirms both that the elimination is justified and that the target cell
// is not a triple member being incorrectly eliminated.
func hasNakedTripleInUnit(cands Candidates, unit []cell, targetRow, targetCol int, bit uint16) bool {
	var members []cell
	for _, pos := range unit {
		n := popcount(cands[pos.r][pos.c])
		if n == 2 || n == 3 {
			members = append(members, pos)
		}
	}
	for i := 0; i < len(members)-2; i++ {
		for j := i + 1; j < len(members)-1; j++ {
			for k := j + 1; k < len(members); k++ {
				a, b, c := members[i], members[j], members[k]
				if (a.r == targetRow && a.c == targetCol) ||
					(b.r == targetRow && b.c == targetCol) ||
					(c.r == targetRow && c.c == targetCol) {
					continue
				}
				union := cands[a.r][a.c] | cands[b.r][b.c] | cands[c.r][c.c]
				if popcount(union) == 3 && union&bit != 0 {
					return true
				}
			}
		}
	}
	return false
}
