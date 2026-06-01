package sudoku

// Candidates tracks possible digits for each cell using a 9-bit bitmask.
// Bit d-1 represents digit d: digit 1 = bit 0 (value 1), digit 9 = bit 8 (value 256).
// A value of 0 means the cell is already solved (no candidates needed).
type Candidates [9][9]uint16

const fullMask uint16 = 0x1FF // bits 0-8 set: all nine digits possible

// Init computes the initial candidate masks from a grid.
// Solved cells get mask 0; empty cells get the digits not yet used in
// their row, column, and box.
func Init(g Grid) Candidates {
	var c Candidates
	for r := 0; r < 9; r++ {
		for col := 0; col < 9; col++ {
			if g[r][col] != 0 {
				continue // already solved
			}
			used := usedMask(g, r, col)
			c[r][col] = fullMask &^ used
		}
	}
	return c
}

// Eliminate removes digit d from the candidates of cell (r, c).
func (c *Candidates) Eliminate(r, col, d int) {
	c[r][col] &^= 1 << uint(d-1)
}

// Set marks cell (r, c) as solved with digit d and removes d from all
// peers (same row, column, and box).
func (c *Candidates) Set(r, col, d int) {
	c[r][col] = 0 // cell is now solved
	bit := uint16(1) << uint(d-1)
	for i := 0; i < 9; i++ {
		c[r][i] &^= bit      // same row
		c[i][col] &^= bit    // same column
	}
	br, bc := (r/3)*3, (col/3)*3
	for dr := 0; dr < 3; dr++ {
		for dc := 0; dc < 3; dc++ {
			c[br+dr][bc+dc] &^= bit
		}
	}
}

// Count returns the number of remaining candidates in cell (r, c).
func (c Candidates) Count(r, col int) int {
	return popcount(c[r][col])
}

// Only returns the single remaining candidate digit in cell (r, c).
// It returns 0 if the cell has 0 or more than 1 candidate.
func (c Candidates) Only(r, col int) uint8 {
	mask := c[r][col]
	if mask == 0 || mask&(mask-1) != 0 {
		return 0
	}
	return uint8(trailingZeros(mask) + 1)
}

// usedMask returns a bitmask of digits already placed in the row, column,
// and box that contain cell (r, c).
func usedMask(g Grid, r, col int) uint16 {
	var mask uint16
	for i := 0; i < 9; i++ {
		if d := g[r][i]; d != 0 {
			mask |= 1 << uint(d-1)
		}
		if d := g[i][col]; d != 0 {
			mask |= 1 << uint(d-1)
		}
	}
	br, bc := (r/3)*3, (col/3)*3
	for dr := 0; dr < 3; dr++ {
		for dc := 0; dc < 3; dc++ {
			if d := g[br+dr][bc+dc]; d != 0 {
				mask |= 1 << uint(d-1)
			}
		}
	}
	return mask
}

func popcount(x uint16) int {
	n := 0
	for x != 0 {
		n += int(x & 1)
		x >>= 1
	}
	return n
}

func trailingZeros(x uint16) int {
	if x == 0 {
		return 16
	}
	n := 0
	for x&1 == 0 {
		n++
		x >>= 1
	}
	return n
}
