package main

import "github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"

// fixtureStandardPuzzle returns the well-known "newspaper" puzzle used across
// multiple test files. Optional modifiers are applied before returning.
func fixtureStandardPuzzle(modifiers ...func(*sudoku.Grid)) sudoku.Grid {
	g := sudoku.Grid{
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
