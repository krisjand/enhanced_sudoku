package sudoku

import (
	"math/rand"
	"testing"
)

func TestGenerate(t *testing.T) {
	tests := []struct {
		name string
		seed int64
	}{
		{name: "seed 1", seed: 1},
		{name: "seed 42", seed: 42},
		{name: "seed 999", seed: 999},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			puzzle, solution, dur := Generate(rand.New(rand.NewSource(tt.seed)))

			if !solution.IsSolved() {
				t.Error("Generate() solution is not fully solved")
			}
			if !puzzle.IsValid() {
				t.Error("Generate() puzzle is not a valid grid")
			}
			if !HasUniqueSolution(puzzle) {
				t.Error("Generate() puzzle does not have a unique solution")
			}
			if countFilled(puzzle) >= 81 {
				t.Error("Generate() puzzle has no empty cells — no clues were removed")
			}
			if dur <= 0 {
				t.Error("Generate() returned non-positive duration")
			}

			// All puzzle clues must match the solution.
			for r := 0; r < 9; r++ {
				for c := 0; c < 9; c++ {
					if puzzle[r][c] != 0 && puzzle[r][c] != solution[r][c] {
						t.Errorf("puzzle[%d][%d]=%d does not match solution[%d][%d]=%d",
							r, c, puzzle[r][c], r, c, solution[r][c])
					}
				}
			}

			// Solving the puzzle must reproduce the known solution.
			solved, found, _ := Solve(puzzle)
			if !found {
				t.Error("Generate() puzzle is not solvable")
			} else if solved != solution {
				t.Error("Generate() solving the puzzle does not reproduce the returned solution")
			}
		})
	}
}

func TestGenerateDeterminism(t *testing.T) {
	seed := int64(12345)
	puzzle1, solution1, _ := Generate(rand.New(rand.NewSource(seed)))
	puzzle2, solution2, _ := Generate(rand.New(rand.NewSource(seed)))

	if puzzle1 != puzzle2 {
		t.Error("Generate() with same seed produced different puzzles")
	}
	if solution1 != solution2 {
		t.Error("Generate() with same seed produced different solutions")
	}
}

func countFilled(g Grid) int {
	n := 0
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 {
				n++
			}
		}
	}
	return n
}
