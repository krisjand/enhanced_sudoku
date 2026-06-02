package sudoku

import "testing"

func fixtureLockedCandidatesPuzzle() Grid {
	return Grid{
		{0, 2, 0, 9, 4, 3, 7, 1, 5},
		{9, 0, 4, 0, 0, 0, 6, 0, 0},
		{7, 5, 0, 0, 0, 0, 0, 4, 0},
		{5, 0, 0, 4, 8, 0, 0, 0, 0},
		{2, 0, 0, 0, 0, 0, 4, 5, 3},
		{4, 0, 0, 3, 5, 2, 0, 0, 0},
		{0, 4, 2, 0, 0, 0, 0, 8, 1},
		{0, 0, 5, 0, 0, 4, 2, 6, 0},
		{0, 9, 0, 2, 0, 8, 5, 0, 4},
	}
}

func TestLockedCandidates(t *testing.T) {
	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, cands Candidates)
	}{
		{
			name:    "empty grid has no locked candidates",
			grid:    Grid{},
			wantNil: true,
		},
		{
			name:    "solved grid has no locked candidates",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "real puzzle produces locked candidate eliminations",
			grid:    fixtureLockedCandidatesPuzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, cands Candidates) {
				t.Helper()
				assertLockedCandidatesValid(t, steps, cands)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := LockedCandidates(tt.grid, cands)

			if tt.wantNil {
				if steps != nil {
					t.Errorf("LockedCandidates() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("LockedCandidates() returned nil, want at least one step")
			}
			for _, s := range steps {
				switch s.Technique {
				case TechniqueLockedCandidatesPointingRow,
					TechniqueLockedCandidatesPointingColumn,
					TechniqueLockedCandidatesReductionRow,
					TechniqueLockedCandidatesReductionColumn:
				default:
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

// assertLockedCandidatesValid checks that each elimination is justified by a
// locked candidates pattern in the given candidate state.
func assertLockedCandidatesValid(t *testing.T, steps []SolveStep, cands Candidates) {
	t.Helper()
	for _, s := range steps {
		for _, a := range s.Actions {
			bit := uint16(1) << uint(a.Digit-1)
			if cands[a.Row][a.Col]&bit == 0 {
				t.Errorf("(%d,%d) digit=%d: not a candidate before elimination", a.Row, a.Col, a.Digit)
				continue
			}
			switch s.Technique {
			case TechniqueLockedCandidatesPointingRow:
				if !hasPointingRowSource(cands, a.Row, a.Col, bit) {
					t.Errorf("(%d,%d) digit=%d: no pointing-row source box found", a.Row, a.Col, a.Digit)
				}
			case TechniqueLockedCandidatesPointingColumn:
				if !hasPointingColSource(cands, a.Row, a.Col, bit) {
					t.Errorf("(%d,%d) digit=%d: no pointing-col source box found", a.Row, a.Col, a.Digit)
				}
			case TechniqueLockedCandidatesReductionRow:
				if !hasReductionRowSource(cands, a.Row, a.Col, bit) {
					t.Errorf("(%d,%d) digit=%d: no reduction-row source found", a.Row, a.Col, a.Digit)
				}
			case TechniqueLockedCandidatesReductionColumn:
				if !hasReductionColSource(cands, a.Row, a.Col, bit) {
					t.Errorf("(%d,%d) digit=%d: no reduction-col source found", a.Row, a.Col, a.Digit)
				}
			}
		}
	}
}

// hasPointingRowSource reports whether a box in the same row-band (not
// containing the target column) has all bit candidates confined to target row.
func hasPointingRowSource(cands Candidates, row, col int, bit uint16) bool {
	rowBand := row / 3
	for bc := 0; bc < 3; bc++ {
		colStart := bc * 3
		if col >= colStart && col < colStart+3 {
			continue // target is inside this box
		}
		count, confined := 0, true
		for dr := 0; dr < 3; dr++ {
			for dc := 0; dc < 3; dc++ {
				r, c := rowBand*3+dr, colStart+dc
				if cands[r][c]&bit != 0 {
					count++
					if r != row {
						confined = false
					}
				}
			}
		}
		if confined && count >= 2 {
			return true
		}
	}
	return false
}

// hasPointingColSource reports whether a box in the same col-band (not
// containing the target row) has all bit candidates confined to target column.
func hasPointingColSource(cands Candidates, row, col int, bit uint16) bool {
	colBand := col / 3
	for br := 0; br < 3; br++ {
		rowStart := br * 3
		if row >= rowStart && row < rowStart+3 {
			continue
		}
		count, confined := 0, true
		for dr := 0; dr < 3; dr++ {
			for dc := 0; dc < 3; dc++ {
				r, c := rowStart+dr, colBand*3+dc
				if cands[r][c]&bit != 0 {
					count++
					if c != col {
						confined = false
					}
				}
			}
		}
		if confined && count >= 2 {
			return true
		}
	}
	return false
}

// hasReductionRowSource reports whether a row in the same row-band (not equal
// to target row) has all bit candidates confined to the box containing target.
func hasReductionRowSource(cands Candidates, row, col int, bit uint16) bool {
	b := (row/3)*3 + col/3
	colStart := (b%3)*3
	rowBand := row / 3
	for dr := 0; dr < 3; dr++ {
		r := rowBand*3 + dr
		if r == row {
			continue
		}
		count, confined := 0, true
		for c := 0; c < 9; c++ {
			if cands[r][c]&bit != 0 {
				count++
				if c < colStart || c >= colStart+3 {
					confined = false
					break
				}
			}
		}
		if confined && count >= 2 {
			return true
		}
	}
	return false
}

// hasReductionColSource reports whether a column in the same col-band (not
// equal to target col) has all bit candidates confined to the box containing target.
func hasReductionColSource(cands Candidates, row, col int, bit uint16) bool {
	b := (row/3)*3 + col/3
	rowStart := (b/3)*3
	colBand := col / 3
	for dc := 0; dc < 3; dc++ {
		c := colBand*3 + dc
		if c == col {
			continue
		}
		count, confined := 0, true
		for r := 0; r < 9; r++ {
			if cands[r][c]&bit != 0 {
				count++
				if r < rowStart || r >= rowStart+3 {
					confined = false
					break
				}
			}
		}
		if confined && count >= 2 {
			return true
		}
	}
	return false
}
