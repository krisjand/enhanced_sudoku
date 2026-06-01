package sudoku

import "testing"

// fixturePartialGrid is an alias for fixtureStandardPuzzle kept for readability
// in candidate-focused tests.
func fixturePartialGrid(modifiers ...func(*Grid)) Grid {
	return fixtureStandardPuzzle(modifiers...)
}

func TestInit(t *testing.T) {
	tests := []struct {
		name               string
		grid               Grid
		checkRow, checkCol int
		wantEmpty          bool  // true if we expect mask == 0 (cell is solved)
		wantContains       []int // digits that must be candidates
		wantExcludes       []int // digits that must not be candidates
	}{
		{
			name:      "solved cell has no candidates",
			grid:      fixturePartialGrid(),
			checkRow:  0,
			checkCol:  0,
			wantEmpty: true,
		},
		{
			// Row 0 uses {5,3,7}; col 2 uses {8}; box 0 uses {3,5,6,8,9}
			// Combined used: {3,5,6,7,8,9} → available: {1,2,4}
			name:         "empty cell excludes digits already in row, col, and box",
			grid:         fixturePartialGrid(),
			checkRow:     0,
			checkCol:     2,
			wantEmpty:    false,
			wantContains: []int{1, 2, 4},
			wantExcludes: []int{3, 5, 6, 7, 8, 9},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := Init(tt.grid)
			mask := c[tt.checkRow][tt.checkCol]
			if tt.wantEmpty {
				if mask != 0 {
					t.Errorf("Init()[%d][%d] = %b, want 0 for solved cell", tt.checkRow, tt.checkCol, mask)
				}
				return
			}
			for _, d := range tt.wantContains {
				if mask&(1<<uint(d-1)) == 0 {
					t.Errorf("Init()[%d][%d] missing expected digit %d", tt.checkRow, tt.checkCol, d)
				}
			}
			for _, d := range tt.wantExcludes {
				if mask&(1<<uint(d-1)) != 0 {
					t.Errorf("Init()[%d][%d] should not contain digit %d", tt.checkRow, tt.checkCol, d)
				}
			}
		})
	}
}

func TestEliminate(t *testing.T) {
	tests := []struct {
		name  string
		digit int
	}{
		{name: "eliminates digit 1", digit: 1},
		{name: "eliminates digit 5", digit: 5},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := Init(fixturePartialGrid())
			c.Eliminate(0, 2, tt.digit)
			if c[0][2]&(1<<uint(tt.digit-1)) != 0 {
				t.Errorf("Eliminate(%d): digit still present in candidates", tt.digit)
			}
		})
	}
}

func TestCount(t *testing.T) {
	tests := []struct {
		name     string
		grid     Grid
		row, col int
		want     int
	}{
		{
			name: "solved cell has 0 candidates",
			grid: fixturePartialGrid(),
			row:  0, col: 0,
			want: 0,
		},
		{
			// Cell (0,2): available digits are {1,2,4} — 3 candidates
			name: "empty cell (0,2) has 3 candidates",
			grid: fixturePartialGrid(),
			row:  0, col: 2,
			want: 3,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := Init(tt.grid)
			if got := c.Count(tt.row, tt.col); got != tt.want {
				t.Errorf("Count(%d,%d) = %d, want %d", tt.row, tt.col, got, tt.want)
			}
		})
	}
}

func TestOnly(t *testing.T) {
	tests := []struct {
		name string
		mask uint16
		want uint8
	}{
		{
			name: "bit 3 set returns digit 4",
			mask: 1 << 3,
			want: 4,
		},
		{
			name: "bit 0 set returns digit 1",
			mask: 1 << 0,
			want: 1,
		},
		{
			name: "two candidates returns 0",
			mask: 0b0000000011,
			want: 0,
		},
		{
			name: "zero candidates returns 0",
			mask: 0,
			want: 0,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var c Candidates
			c[0][0] = tt.mask
			if got := c.Only(0, 0); got != tt.want {
				t.Errorf("Only() = %d, want %d", got, tt.want)
			}
		})
	}
}

func TestSet(t *testing.T) {
	// Set digit 1 at cell (0,2) in the standard puzzle.
	// Row 0 peers: cols 0-1, 3-8 in row 0
	// Col 2 peers: rows 1-8 in col 2
	// Box 0 peers: (0,0),(0,1),(1,0),(1,1),(1,2),(2,0),(2,1),(2,2)
	const setRow, setCol, setDigit = 0, 2, 1
	bit := uint16(1) << uint(setDigit-1)

	tests := []struct {
		name              string
		checkRow, checkCol int
		wantMaskZero      bool // true = cell should be solved (mask == 0)
		wantBitCleared    bool // true = setDigit should be absent from candidates
		wantBitPresent    bool // true = setDigit should remain in candidates (non-peer)
	}{
		{
			name:          "cell itself is marked solved",
			checkRow:      setRow, checkCol: setCol,
			wantMaskZero:  true,
		},
		{
			name:           "same-row peer loses the digit",
			checkRow:       0, checkCol: 5,
			wantBitCleared: true,
		},
		{
			name:           "same-column peer loses the digit",
			checkRow:       4, checkCol: 2,
			wantBitCleared: true,
		},
		{
			name:           "same-box peer loses the digit",
			checkRow:       2, checkCol: 0,
			wantBitCleared: true,
		},
		{
			// (5,5) is not in row 0, col 2, or box 0 — digit 1 must remain
			name:           "non-peer cell retains the digit",
			checkRow:       5, checkCol: 5,
			wantBitPresent: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := Init(fixturePartialGrid())
			c.Set(setRow, setCol, setDigit)
			mask := c[tt.checkRow][tt.checkCol]

			if tt.wantMaskZero && mask != 0 {
				t.Errorf("Set: cell (%d,%d) mask = %b, want 0", tt.checkRow, tt.checkCol, mask)
			}
			if tt.wantBitCleared && mask&bit != 0 {
				t.Errorf("Set: digit %d still present at (%d,%d)", setDigit, tt.checkRow, tt.checkCol)
			}
			if tt.wantBitPresent && mask&bit == 0 {
				t.Errorf("Set: digit %d missing from non-peer (%d,%d)", setDigit, tt.checkRow, tt.checkCol)
			}
		})
	}
}
