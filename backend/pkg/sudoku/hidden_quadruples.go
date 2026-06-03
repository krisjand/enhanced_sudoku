package sudoku

import "time"

const (
	TechniqueHiddenQuadruples      = "hiddenQuadruples"
	TechniqueHiddenQuadruplesRow    = "hiddenQuadruplesRow"
	TechniqueHiddenQuadruplesColumn = "hiddenQuadruplesColumn"
	TechniqueHiddenQuadruplesBox    = "hiddenQuadruplesBox"
)

// HiddenQuadruples identifies four digits whose candidates collectively appear
// in exactly four cells within a unit, enabling elimination of all other
// candidates from those four cells. Returns up to three SolveSteps — one per
// unit type that found eliminations — or nil if none exist. All actions are
// ActionEliminate.
func HiddenQuadruples(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := hiddenQuadruplesInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := hiddenQuadruplesInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions := hiddenQuadruplesInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenQuadruplesRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenQuadruplesColumn, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenQuadruplesBox, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func hiddenQuadruplesInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for r := 0; r < 9; r++ {
		actions = eliminateFromHiddenQuadruples(actions, cands, seen, rowUnit(r))
	}
	return actions
}

func hiddenQuadruplesInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for c := 0; c < 9; c++ {
		actions = eliminateFromHiddenQuadruples(actions, cands, seen, colUnit(c))
	}
	return actions
}

func hiddenQuadruplesInBoxes(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for b := 0; b < 9; b++ {
		actions = eliminateFromHiddenQuadruples(actions, cands, seen, boxUnit(b))
	}
	return actions
}

// eliminateFromHiddenQuadruples finds hidden quadruples in a unit and appends
// eliminations. For each quadruple of digits (d1,d2,d3,d4) whose candidates
// collectively appear in exactly four cells and nowhere else in the unit, all
// other candidates are removed from those four cells.
//
// Uses a position bitmask per digit (bit i set ↔ unit[i] contains that digit)
// so the cell-union for any quadruple is a cheap bitwise OR + popcount.
func eliminateFromHiddenQuadruples(actions []CellAction, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
	var posMask [10]uint16 // posMask[d]: bit i set if unit[i] has digit d as candidate
	for i, pos := range unit {
		c := cands[pos.r][pos.c]
		for d := 1; d <= 9; d++ {
			if c&(1<<uint(d-1)) != 0 {
				posMask[d] |= 1 << uint(i)
			}
		}
	}

	for d1 := 1; d1 <= 6; d1++ {
		if posMask[d1] == 0 || popcount(posMask[d1]) > 4 {
			continue
		}
		for d2 := d1 + 1; d2 <= 7; d2++ {
			if posMask[d2] == 0 || popcount(posMask[d2]) > 4 {
				continue
			}
			u12 := posMask[d1] | posMask[d2]
			if popcount(u12) > 4 {
				continue
			}
			for d3 := d2 + 1; d3 <= 8; d3++ {
				if posMask[d3] == 0 || popcount(posMask[d3]) > 4 {
					continue
				}
				u123 := u12 | posMask[d3]
				if popcount(u123) > 4 {
					continue
				}
				for d4 := d3 + 1; d4 <= 9; d4++ {
					if posMask[d4] == 0 || popcount(posMask[d4]) > 4 {
						continue
					}
					union := u123 | posMask[d4]
					if popcount(union) != 4 {
						continue
					}
					// Hidden quadruple found — eliminate all other candidates from the four cells.
					quadMask := uint16(1<<uint(d1-1)) | uint16(1<<uint(d2-1)) | uint16(1<<uint(d3-1)) | uint16(1<<uint(d4-1))
					m := union
					for m != 0 {
						lsb := m & (-m)
						m &^= lsb
						idx := int(trailingZeros(lsb))
						pos := unit[idx]
						extras := cands[pos.r][pos.c] &^ quadMask
						for extras != 0 {
							eb := extras & (-extras)
							extras &^= eb
							digit := int(trailingZeros(eb) + 1)
							key := [3]int{pos.r, pos.c, digit}
							if !seen[key] {
								seen[key] = true
								actions = append(actions, CellAction{Row: pos.r, Col: pos.c, Digit: digit, Type: ActionEliminate})
							}
						}
					}
				}
			}
		}
	}
	return actions
}
