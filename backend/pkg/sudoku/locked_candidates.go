package sudoku

import "time"

const (
	TechniqueLockedCandidates                = "lockedCandidates"
	TechniqueLockedCandidatesPointingRow     = "lockedCandidatesPointingRow"
	TechniqueLockedCandidatesPointingColumn  = "lockedCandidatesPointingColumn"
	TechniqueLockedCandidatesReductionRow    = "lockedCandidatesReductionRow"
	TechniqueLockedCandidatesReductionColumn = "lockedCandidatesReductionColumn"
)

// LockedCandidates identifies two elimination patterns:
//   - Pointing: all candidates for a digit in a box lie in one row/column →
//     eliminate from that row/column outside the box.
//   - Reduction: all candidates for a digit in a row/column lie in one box →
//     eliminate from that box outside the row/column.
//
// Returns up to four SolveSteps (one per direction) or nil. All actions are ActionEliminate.
func LockedCandidates(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	ptRowStart := time.Now()
	ptRowActions, ptRowSources := pointingInBoxesForRows(cands, seen)
	ptRowDur := time.Since(ptRowStart)

	ptColStart := time.Now()
	ptColActions, ptColSources := pointingInBoxesForCols(cands, seen)
	ptColDur := time.Since(ptColStart)

	rdRowStart := time.Now()
	rdRowActions, rdRowSources := reductionInRows(cands, seen)
	rdRowDur := time.Since(rdRowStart)

	rdColStart := time.Now()
	rdColActions, rdColSources := reductionInCols(cands, seen)
	rdColDur := time.Since(rdColStart)

	var steps []SolveStep
	if len(ptRowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueLockedCandidatesPointingRow, Sources: ptRowSources, Actions: ptRowActions, Duration: ptRowDur})
	}
	if len(ptColActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueLockedCandidatesPointingColumn, Sources: ptColSources, Actions: ptColActions, Duration: ptColDur})
	}
	if len(rdRowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueLockedCandidatesReductionRow, Sources: rdRowSources, Actions: rdRowActions, Duration: rdRowDur})
	}
	if len(rdColActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueLockedCandidatesReductionColumn, Sources: rdColSources, Actions: rdColActions, Duration: rdColDur})
	}
	return steps
}

// pointingInBoxesForRows scans each box: if a digit's candidates are all in one
// row, eliminate that digit from the rest of that row outside the box.
func pointingInBoxesForRows(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for b := 0; b < 9; b++ {
		br, bc := (b/3)*3, (b%3)*3
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			row, count, confined := -1, 0, true
		scanRow:
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					if cands[br+dr][bc+dc]&bit != 0 {
						count++
						if row == -1 {
							row = br + dr
						} else if row != br+dr {
							confined = false
							break scanRow
						}
					}
				}
			}
			if !confined || count < 2 {
				continue
			}
			prevLen := len(actions)
			for c := 0; c < 9; c++ {
				if c >= bc && c < bc+3 {
					continue
				}
				if cands[row][c]&bit != 0 {
					key := [3]int{row, c, d}
					if !seen[key] {
						seen[key] = true
						actions = append(actions, CellAction{Row: row, Col: c, Digit: d, Type: ActionEliminate})
					}
				}
			}
			if len(actions) > prevLen {
				for dc := 0; dc < 3; dc++ {
					if cands[row][bc+dc]&bit != 0 {
						sources = append(sources, SourceCell{Row: row, Col: bc + dc, Digits: []int{d}})
					}
				}
			}
		}
	}
	return actions, sources
}

// pointingInBoxesForCols scans each box: if a digit's candidates are all in one
// column, eliminate that digit from the rest of that column outside the box.
func pointingInBoxesForCols(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for b := 0; b < 9; b++ {
		br, bc := (b/3)*3, (b%3)*3
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			col, count, confined := -1, 0, true
		scanCol:
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					if cands[br+dr][bc+dc]&bit != 0 {
						count++
						if col == -1 {
							col = bc + dc
						} else if col != bc+dc {
							confined = false
							break scanCol
						}
					}
				}
			}
			if !confined || count < 2 {
				continue
			}
			prevLen := len(actions)
			for r := 0; r < 9; r++ {
				if r >= br && r < br+3 {
					continue
				}
				if cands[r][col]&bit != 0 {
					key := [3]int{r, col, d}
					if !seen[key] {
						seen[key] = true
						actions = append(actions, CellAction{Row: r, Col: col, Digit: d, Type: ActionEliminate})
					}
				}
			}
			if len(actions) > prevLen {
				for dr := 0; dr < 3; dr++ {
					if cands[br+dr][col]&bit != 0 {
						sources = append(sources, SourceCell{Row: br + dr, Col: col, Digits: []int{d}})
					}
				}
			}
		}
	}
	return actions, sources
}

// reductionInRows scans each row: if a digit's candidates are all in one box,
// eliminate that digit from the rest of that box outside the row.
func reductionInRows(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for r := 0; r < 9; r++ {
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			boxIdx, count, confined := -1, 0, true
			for c := 0; c < 9; c++ {
				if cands[r][c]&bit != 0 {
					count++
					b := (r/3)*3 + c/3
					if boxIdx == -1 {
						boxIdx = b
					} else if boxIdx != b {
						confined = false
						break
					}
				}
			}
			if !confined || count < 2 {
				continue
			}
			br, bc := (boxIdx/3)*3, (boxIdx%3)*3
			prevLen := len(actions)
			for dr := 0; dr < 3; dr++ {
				if br+dr == r {
					continue
				}
				for dc := 0; dc < 3; dc++ {
					cr, cc := br+dr, bc+dc
					if cands[cr][cc]&bit != 0 {
						key := [3]int{cr, cc, d}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: cr, Col: cc, Digit: d, Type: ActionEliminate})
						}
					}
				}
			}
			if len(actions) > prevLen {
				for c := 0; c < 9; c++ {
					if cands[r][c]&bit != 0 {
						sources = append(sources, SourceCell{Row: r, Col: c, Digits: []int{d}})
					}
				}
			}
		}
	}
	return actions, sources
}

// reductionInCols scans each column: if a digit's candidates are all in one box,
// eliminate that digit from the rest of that box outside the column.
func reductionInCols(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for c := 0; c < 9; c++ {
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			boxIdx, count, confined := -1, 0, true
			for r := 0; r < 9; r++ {
				if cands[r][c]&bit != 0 {
					count++
					b := (r/3)*3 + c/3
					if boxIdx == -1 {
						boxIdx = b
					} else if boxIdx != b {
						confined = false
						break
					}
				}
			}
			if !confined || count < 2 {
				continue
			}
			br, bc := (boxIdx/3)*3, (boxIdx%3)*3
			prevLen := len(actions)
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					cr, cc := br+dr, bc+dc
					if cc == c {
						continue
					}
					if cands[cr][cc]&bit != 0 {
						key := [3]int{cr, cc, d}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: cr, Col: cc, Digit: d, Type: ActionEliminate})
						}
					}
				}
			}
			if len(actions) > prevLen {
				for r := 0; r < 9; r++ {
					if cands[r][c]&bit != 0 {
						sources = append(sources, SourceCell{Row: r, Col: c, Digits: []int{d}})
					}
				}
			}
		}
	}
	return actions, sources
}
