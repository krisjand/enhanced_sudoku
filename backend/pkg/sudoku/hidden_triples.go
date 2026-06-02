package sudoku

import "time"

const (
	TechniqueHiddenTriples      = "hiddenTriples"
	TechniqueHiddenTripleRow    = "hiddenTripleRow"
	TechniqueHiddenTripleColumn = "hiddenTripleColumn"
	TechniqueHiddenTripleBox    = "hiddenTripleBox"
)

// HiddenTriples identifies three digits whose candidates collectively appear in
// exactly three cells within a unit, enabling elimination of all other candidates
// from those three cells. Returns up to three SolveSteps — one per unit type
// that found eliminations — or nil if none exist. All actions are ActionEliminate.
func HiddenTriples(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := hiddenTriplesInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := hiddenTriplesInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions := hiddenTriplesInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenTripleRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenTripleColumn, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenTripleBox, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func hiddenTriplesInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for r := 0; r < 9; r++ {
		actions = eliminateFromHiddenTriples(actions, cands, seen, rowUnit(r))
	}
	return actions
}

func hiddenTriplesInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for c := 0; c < 9; c++ {
		actions = eliminateFromHiddenTriples(actions, cands, seen, colUnit(c))
	}
	return actions
}

func hiddenTriplesInBoxes(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for b := 0; b < 9; b++ {
		actions = eliminateFromHiddenTriples(actions, cands, seen, boxUnit(b))
	}
	return actions
}

// eliminateFromHiddenTriples finds hidden triples in a unit and appends eliminations.
// For each triple of digits (d1, d2, d3) whose candidates collectively appear in
// exactly three cells and nowhere else in the unit, all other candidates are removed
// from those three cells.
//
// Uses a position bitmask per digit (bit i set ↔ unit[i] contains that digit) so
// the cell-union for any triple is a cheap bitwise OR + popcount.
func eliminateFromHiddenTriples(actions []CellAction, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
	var posMask [10]uint16 // posMask[d]: bit i set if unit[i] has digit d as candidate
	for i, pos := range unit {
		c := cands[pos.r][pos.c]
		for d := 1; d <= 9; d++ {
			if c&(1<<uint(d-1)) != 0 {
				posMask[d] |= 1 << uint(i)
			}
		}
	}

	for d1 := 1; d1 <= 7; d1++ {
		if posMask[d1] == 0 || popcount(posMask[d1]) > 3 {
			continue
		}
		for d2 := d1 + 1; d2 <= 8; d2++ {
			if posMask[d2] == 0 || popcount(posMask[d2]) > 3 {
				continue
			}
			u12 := posMask[d1] | posMask[d2]
			if popcount(u12) > 3 {
				continue
			}
			for d3 := d2 + 1; d3 <= 9; d3++ {
				if posMask[d3] == 0 || popcount(posMask[d3]) > 3 {
					continue
				}
				union := u12 | posMask[d3]
				if popcount(union) != 3 {
					continue
				}
				// Hidden triple found — eliminate all other candidates from the three cells.
				tripleMask := uint16(1<<uint(d1-1)) | uint16(1<<uint(d2-1)) | uint16(1<<uint(d3-1))
				m := union
				for m != 0 {
					lsb := m & (-m)
					m &^= lsb
					idx := int(trailingZeros(lsb))
					pos := unit[idx]
					extras := cands[pos.r][pos.c] &^ tripleMask
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
	return actions
}
