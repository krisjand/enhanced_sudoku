package sudoku

import "testing"

// fixtureValidSolved returns a fully solved, valid 9x9 grid.
// Optional modifiers are applied in order before returning.
func fixtureValidSolved(modifiers ...func(*Grid)) Grid {
	g := Grid{
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
	for _, m := range modifiers {
		m(&g)
	}
	return g
}

func TestIsValid(t *testing.T) {
	tests := []struct {
		name string
		grid Grid
		want bool
	}{
		{
			name: "valid solved grid",
			grid: fixtureValidSolved(),
			want: true,
		},
		{
			name: "duplicate in row",
			grid: fixtureValidSolved(func(g *Grid) { g[0][0] = 3 }),
			want: false,
		},
		{
			name: "duplicate in column",
			grid: fixtureValidSolved(func(g *Grid) { g[1][0] = 5 }),
			want: false,
		},
		{
			name: "duplicate in box",
			grid: fixtureValidSolved(func(g *Grid) { g[1][1] = 5 }),
			want: false,
		},
		{
			name: "empty cell is ignored",
			grid: fixtureValidSolved(func(g *Grid) { g[4][4] = 0 }),
			want: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.grid.IsValid(); got != tt.want {
				t.Errorf("IsValid() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestIsSolved(t *testing.T) {
	tests := []struct {
		name string
		grid Grid
		want bool
	}{
		{
			name: "fully solved valid grid",
			grid: fixtureValidSolved(),
			want: true,
		},
		{
			name: "one empty cell",
			grid: fixtureValidSolved(func(g *Grid) { g[4][4] = 0 }),
			want: false,
		},
		{
			name: "duplicate digit",
			grid: fixtureValidSolved(func(g *Grid) { g[0][0] = 3 }),
			want: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.grid.IsSolved(); got != tt.want {
				t.Errorf("IsSolved() = %v, want %v", got, tt.want)
			}
		})
	}
}
