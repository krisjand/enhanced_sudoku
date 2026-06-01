package sudoku

// Grid is a 9x9 Sudoku board. 0 means empty; 1-9 are filled digits.
type Grid [9][9]uint8

// IsValid reports whether the grid satisfies all Sudoku constraints.
// Empty cells (0) are ignored; only placed digits are checked.
func (g Grid) IsValid() bool {
	for i := 0; i < 9; i++ {
		if !validUnit(g.row(i)) || !validUnit(g.col(i)) || !validUnit(g.box(i)) {
			return false
		}
	}
	return true
}

// IsSolved reports whether the grid is fully and correctly filled.
func (g Grid) IsSolved() bool {
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] == 0 {
				return false
			}
		}
	}
	return g.IsValid()
}

func (g Grid) row(r int) [9]uint8 { return g[r] }

func (g Grid) col(c int) [9]uint8 {
	var unit [9]uint8
	for r := 0; r < 9; r++ {
		unit[r] = g[r][c]
	}
	return unit
}

// box returns the digits in the 3x3 box identified by index (0-8, row-major).
func (g Grid) box(b int) [9]uint8 {
	br, bc := (b/3)*3, (b%3)*3
	var unit [9]uint8
	i := 0
	for r := br; r < br+3; r++ {
		for c := bc; c < bc+3; c++ {
			unit[i] = g[r][c]
			i++
		}
	}
	return unit
}

func validUnit(unit [9]uint8) bool {
	var seen uint16
	for _, d := range unit {
		if d == 0 {
			continue
		}
		if d > 9 {
			return false
		}
		bit := uint16(1) << d
		if seen&bit != 0 {
			return false
		}
		seen |= bit
	}
	return true
}
