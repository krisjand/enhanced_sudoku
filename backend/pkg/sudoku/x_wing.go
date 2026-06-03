package sudoku

import "time"

const (
	TechniqueXWing       = "xWing"
	TechniqueXWingRow    = "xWingRow"
	TechniqueXWingColumn = "xWingColumn"
)

// XWing identifies X-wing patterns across rows and columns and records the
// candidate eliminations they enable. Returns up to two SolveSteps — one for
// row patterns (eliminations in columns) and one for column patterns
// (eliminations in rows) — or nil if none exist. All actions are ActionEliminate.
func XWing(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := xWingInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := xWingInCols(cands, seen)
	colDur := time.Since(colStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueXWingRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueXWingColumn, Actions: colActions, Duration: colDur})
	}
	return steps
}

// xWingInRows finds X-wing patterns where the base is a pair of rows sharing
// the same two candidate columns for a digit, then eliminates that digit from
// all other cells in those two columns.
func xWingInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	type rowEntry struct{ r, c1, c2 int }
	var actions []CellAction

	for d := 1; d <= 9; d++ {
		bit := uint16(1) << uint(d-1)
		var rows []rowEntry
		for r := 0; r < 9; r++ {
			var c1, c2 int
			count := 0
			for c := 0; c < 9; c++ {
				if cands[r][c]&bit != 0 {
					if count == 0 {
						c1 = c
					} else if count == 1 {
						c2 = c
					}
					count++
				}
			}
			if count == 2 {
				rows = append(rows, rowEntry{r, c1, c2})
			}
		}
		for i := 0; i < len(rows)-1; i++ {
			for j := i + 1; j < len(rows); j++ {
				if rows[i].c1 != rows[j].c1 || rows[i].c2 != rows[j].c2 {
					continue
				}
				r1, r2 := rows[i].r, rows[j].r
				c1, c2 := rows[i].c1, rows[i].c2
				for r := 0; r < 9; r++ {
					if r == r1 || r == r2 {
						continue
					}
					if cands[r][c1]&bit != 0 {
						key := [3]int{r, c1, d}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: r, Col: c1, Digit: d, Type: ActionEliminate})
						}
					}
					if cands[r][c2]&bit != 0 {
						key := [3]int{r, c2, d}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: r, Col: c2, Digit: d, Type: ActionEliminate})
						}
					}
				}
			}
		}
	}
	return actions
}

// xWingInCols finds X-wing patterns where the base is a pair of columns
// sharing the same two candidate rows for a digit, then eliminates that digit
// from all other cells in those two rows.
func xWingInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	type colEntry struct{ c, r1, r2 int }
	var actions []CellAction

	for d := 1; d <= 9; d++ {
		bit := uint16(1) << uint(d-1)
		var cols []colEntry
		for c := 0; c < 9; c++ {
			var r1, r2 int
			count := 0
			for r := 0; r < 9; r++ {
				if cands[r][c]&bit != 0 {
					if count == 0 {
						r1 = r
					} else if count == 1 {
						r2 = r
					}
					count++
				}
			}
			if count == 2 {
				cols = append(cols, colEntry{c, r1, r2})
			}
		}
		for i := 0; i < len(cols)-1; i++ {
			for j := i + 1; j < len(cols); j++ {
				if cols[i].r1 != cols[j].r1 || cols[i].r2 != cols[j].r2 {
					continue
				}
				c1, c2 := cols[i].c, cols[j].c
				r1, r2 := cols[i].r1, cols[i].r2
				for c := 0; c < 9; c++ {
					if c == c1 || c == c2 {
						continue
					}
					if cands[r1][c]&bit != 0 {
						key := [3]int{r1, c, d}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: r1, Col: c, Digit: d, Type: ActionEliminate})
						}
					}
					if cands[r2][c]&bit != 0 {
						key := [3]int{r2, c, d}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: r2, Col: c, Digit: d, Type: ActionEliminate})
						}
					}
				}
			}
		}
	}
	return actions
}
