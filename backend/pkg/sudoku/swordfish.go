package sudoku

import "time"

const (
	TechniqueSwordfish       = "swordfish"
	TechniqueSwordfishRow    = "swordfishRow"
	TechniqueSwordfishColumn = "swordfishColumn"
)

// Swordfish identifies Swordfish patterns across rows and columns and records
// the candidate eliminations they enable. Returns up to two SolveSteps — one
// for row patterns (eliminations in columns) and one for column patterns
// (eliminations in rows) — or nil if none exist. All actions are ActionEliminate.
func Swordfish(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := swordfishInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := swordfishInCols(cands, seen)
	colDur := time.Since(colStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueSwordfishRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueSwordfishColumn, Actions: colActions, Duration: colDur})
	}
	return steps
}

// swordfishInRows finds Swordfish patterns where the base is a triple of rows
// each having a digit as a candidate in 2 or 3 columns, and the union of those
// columns spans exactly 3 columns. Eliminates the digit from all other cells in
// those 3 columns.
func swordfishInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction

	for d := 1; d <= 9; d++ {
		bit := uint16(1) << uint(d-1)

		// Collect rows where digit d appears in exactly 2 or 3 columns.
		// colMask[i] encodes which columns have digit d in that row.
		type rowEntry struct {
			r       int
			colMask uint16
		}
		var rows []rowEntry
		for r := 0; r < 9; r++ {
			var mask uint16
			for c := 0; c < 9; c++ {
				if cands[r][c]&bit != 0 {
					mask |= 1 << uint(c)
				}
			}
			if cnt := popcount(mask); cnt == 2 || cnt == 3 {
				rows = append(rows, rowEntry{r, mask})
			}
		}

		for i := 0; i < len(rows)-2; i++ {
			for j := i + 1; j < len(rows)-1; j++ {
				u12 := rows[i].colMask | rows[j].colMask
				if popcount(u12) > 3 {
					continue
				}
				for k := j + 1; k < len(rows); k++ {
					union := u12 | rows[k].colMask
					if popcount(union) != 3 {
						continue
					}
					r1, r2, r3 := rows[i].r, rows[j].r, rows[k].r
					for c := 0; c < 9; c++ {
						if union&(1<<uint(c)) == 0 {
							continue
						}
						for r := 0; r < 9; r++ {
							if r == r1 || r == r2 || r == r3 {
								continue
							}
							if cands[r][c]&bit != 0 {
								key := [3]int{r, c, d}
								if !seen[key] {
									seen[key] = true
									actions = append(actions, CellAction{Row: r, Col: c, Digit: d, Type: ActionEliminate})
								}
							}
						}
					}
				}
			}
		}
	}
	return actions
}

// swordfishInCols finds Swordfish patterns where the base is a triple of
// columns each having a digit as a candidate in 2 or 3 rows, and the union of
// those rows spans exactly 3 rows. Eliminates the digit from all other cells in
// those 3 rows.
func swordfishInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction

	for d := 1; d <= 9; d++ {
		bit := uint16(1) << uint(d-1)

		type colEntry struct {
			c       int
			rowMask uint16
		}
		var cols []colEntry
		for c := 0; c < 9; c++ {
			var mask uint16
			for r := 0; r < 9; r++ {
				if cands[r][c]&bit != 0 {
					mask |= 1 << uint(r)
				}
			}
			if cnt := popcount(mask); cnt == 2 || cnt == 3 {
				cols = append(cols, colEntry{c, mask})
			}
		}

		for i := 0; i < len(cols)-2; i++ {
			for j := i + 1; j < len(cols)-1; j++ {
				u12 := cols[i].rowMask | cols[j].rowMask
				if popcount(u12) > 3 {
					continue
				}
				for k := j + 1; k < len(cols); k++ {
					union := u12 | cols[k].rowMask
					if popcount(union) != 3 {
						continue
					}
					c1, c2, c3 := cols[i].c, cols[j].c, cols[k].c
					for r := 0; r < 9; r++ {
						if union&(1<<uint(r)) == 0 {
							continue
						}
						for c := 0; c < 9; c++ {
							if c == c1 || c == c2 || c == c3 {
								continue
							}
							if cands[r][c]&bit != 0 {
								key := [3]int{r, c, d}
								if !seen[key] {
									seen[key] = true
									actions = append(actions, CellAction{Row: r, Col: c, Digit: d, Type: ActionEliminate})
								}
							}
						}
					}
				}
			}
		}
	}
	return actions
}
