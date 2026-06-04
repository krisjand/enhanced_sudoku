package sudoku

import "testing"

// assertStepsHaveSources verifies that every step has at least one source cell
// and every source cell has at least one digit.
func assertStepsHaveSources(t *testing.T, steps []SolveStep) {
	t.Helper()
	for i, s := range steps {
		if len(s.Sources) == 0 {
			t.Errorf("step[%d] technique=%q: Sources is empty", i, s.Technique)
			continue
		}
		for j, src := range s.Sources {
			if len(src.Digits) == 0 {
				t.Errorf("step[%d] technique=%q source[%d] at (%d,%d): Digits is empty",
					i, s.Technique, j, src.Row, src.Col)
			}
		}
	}
}

// fixtureStandardPuzzle returns the well-known "newspaper" puzzle used across
// multiple test files. Optional modifiers are applied before returning.
func fixtureStandardPuzzle(modifiers ...func(*Grid)) Grid {
	g := Grid{
		{5, 3, 0, 0, 7, 0, 0, 0, 0},
		{6, 0, 0, 1, 9, 5, 0, 0, 0},
		{0, 9, 8, 0, 0, 0, 0, 6, 0},
		{8, 0, 0, 0, 6, 0, 0, 0, 3},
		{4, 0, 0, 8, 0, 3, 0, 0, 1},
		{7, 0, 0, 0, 2, 0, 0, 0, 6},
		{0, 6, 0, 0, 0, 0, 2, 8, 0},
		{0, 0, 0, 4, 1, 9, 0, 0, 5},
		{0, 0, 0, 0, 8, 0, 0, 7, 9},
	}
	for _, m := range modifiers {
		m(&g)
	}
	return g
}
