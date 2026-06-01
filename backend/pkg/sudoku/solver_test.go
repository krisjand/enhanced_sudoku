package sudoku

import "testing"

// fixtureUniquePuzzle is an alias for fixtureStandardPuzzle kept for
// readability in solver-focused tests.
func fixtureUniquePuzzle(modifiers ...func(*Grid)) Grid {
	return fixtureStandardPuzzle(modifiers...)
}

// fixtureUniqueSolution is the known solution for fixtureUniquePuzzle.
func fixtureUniqueSolution() Grid {
	return Grid{
		{5, 3, 4, 6, 7, 8, 9, 1, 2},
		{6, 7, 2, 1, 9, 5, 3, 4, 8},
		{1, 9, 8, 3, 4, 2, 5, 6, 7},
		{8, 5, 9, 7, 6, 1, 4, 2, 3},
		{4, 2, 6, 8, 5, 3, 7, 9, 1},
		{7, 1, 3, 9, 2, 4, 8, 5, 6},
		{9, 6, 1, 5, 3, 7, 2, 8, 4},
		{2, 8, 7, 4, 1, 9, 6, 3, 5},
		{3, 4, 5, 2, 8, 6, 1, 7, 9},
	}
}

// fixtureMultipleSolutionsPuzzle returns a grid with only one row filled —
// the remaining 72 empty cells have many valid completions.
func fixtureMultipleSolutionsPuzzle(modifiers ...func(*Grid)) Grid {
	g := Grid{}
	g[0] = [9]uint8{1, 2, 3, 4, 5, 6, 7, 8, 9}
	for _, m := range modifiers {
		m(&g)
	}
	return g
}

func TestSolve(t *testing.T) {
	tests := []struct {
		name      string
		grid      Grid
		wantFound bool
		wantGrid  *Grid // nil means we only check wantFound
	}{
		{
			name:      "valid puzzle with unique solution",
			grid:      fixtureUniquePuzzle(),
			wantFound: true,
			wantGrid:  func() *Grid { g := fixtureUniqueSolution(); return &g }(),
		},
		{
			name:      "already solved grid",
			grid:      fixtureUniqueSolution(),
			wantFound: true,
			wantGrid:  func() *Grid { g := fixtureUniqueSolution(); return &g }(),
		},
		{
			name:      "puzzle with multiple solutions returns a valid solution",
			grid:      fixtureMultipleSolutionsPuzzle(),
			wantFound: true,
		},
		{
			// Place a conflicting digit to make the puzzle unsolvable
			name:      "unsolvable puzzle returns not found",
			grid:      fixtureUniquePuzzle(func(g *Grid) { g[0][4] = 3 }),
			wantFound: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, found, _ := Solve(tt.grid)
			if found != tt.wantFound {
				t.Errorf("Solve() found = %v, want %v", found, tt.wantFound)
				return
			}
			if tt.wantGrid != nil && got != *tt.wantGrid {
				t.Errorf("Solve() returned wrong solution")
			}
			if found && !got.IsSolved() {
				t.Errorf("Solve() returned a grid that is not fully solved")
			}
		})
	}
}

func TestHasUniqueSolution(t *testing.T) {
	tests := []struct {
		name string
		grid Grid
		want bool
	}{
		{
			name: "puzzle with unique solution",
			grid: fixtureUniquePuzzle(),
			want: true,
		},
		{
			name: "already solved grid has unique solution",
			grid: fixtureUniqueSolution(),
			want: true,
		},
		{
			name: "puzzle with multiple solutions",
			grid: fixtureMultipleSolutionsPuzzle(),
			want: false,
		},
		{
			name: "unsolvable puzzle",
			grid: fixtureUniquePuzzle(func(g *Grid) { g[0][4] = 3 }),
			want: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := HasUniqueSolution(tt.grid); got != tt.want {
				t.Errorf("HasUniqueSolution() = %v, want %v", got, tt.want)
			}
		})
	}
}
