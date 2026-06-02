package sudoku

import "time"

const (
	TechniqueHiddenPairs      = "hiddenPairs"
	TechniqueHiddenPairRow    = "hiddenPairRow"
	TechniqueHiddenPairColumn = "hiddenPairColumn"
	TechniqueHiddenPairBox    = "hiddenPairBox"
)

// HiddenPairs identifies two digits that appear as candidates in exactly the
// same two cells within a unit, enabling elimination of all other candidates
// from those two cells. Returns up to three SolveSteps — one per unit type
// that found eliminations — or nil if none exist. All actions are ActionEliminate.
func HiddenPairs(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := hiddenPairsInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := hiddenPairsInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions := hiddenPairsInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenPairRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenPairColumn, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenPairBox, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func hiddenPairsInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for r := 0; r < 9; r++ {
		actions = eliminateFromHiddenPairs(actions, cands, seen, rowUnit(r))
	}
	return actions
}

func hiddenPairsInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for c := 0; c < 9; c++ {
		actions = eliminateFromHiddenPairs(actions, cands, seen, colUnit(c))
	}
	return actions
}

func hiddenPairsInBoxes(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for b := 0; b < 9; b++ {
		actions = eliminateFromHiddenPairs(actions, cands, seen, boxUnit(b))
	}
	return actions
}

// eliminateFromHiddenPairs finds hidden pairs in a unit and appends eliminations.
// For each pair of digits (d1, d2) that appear in exactly the same two cells
// and nowhere else in the unit, all other candidates are removed from those cells.
func eliminateFromHiddenPairs(actions []CellAction, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
	for d1 := 1; d1 <= 8; d1++ {
		bit1 := uint16(1) << uint(d1-1)
		// Collect cells containing d1.
		var cells1 [2]cell
		n1 := 0
		for _, pos := range unit {
			if cands[pos.r][pos.c]&bit1 != 0 {
				if n1 == 2 {
					n1 = 3 // more than 2, skip
					break
				}
				cells1[n1] = pos
				n1++
			}
		}
		if n1 != 2 {
			continue
		}
		for d2 := d1 + 1; d2 <= 9; d2++ {
			bit2 := uint16(1) << uint(d2-1)
			// Collect cells containing d2.
			var cells2 [2]cell
			n2 := 0
			for _, pos := range unit {
				if cands[pos.r][pos.c]&bit2 != 0 {
					if n2 == 2 {
						n2 = 3
						break
					}
					cells2[n2] = pos
					n2++
				}
			}
			if n2 != 2 {
				continue
			}
			// Both digits must live in exactly the same two cells.
			if cells1[0] != cells2[0] || cells1[1] != cells2[1] {
				continue
			}
			// Hidden pair found — eliminate all other candidates from both cells.
			pairMask := bit1 | bit2
			for _, pos := range cells1 {
				extras := cands[pos.r][pos.c] &^ pairMask
				for extras != 0 {
					bit := extras & (-extras)
					extras &^= bit
					digit := int(trailingZeros(bit) + 1)
					key := [3]int{pos.r, pos.c, digit}
					if !seen[key] {
						seen[key] = true
						actions = append(actions, CellAction{Row: pos.r, Col: pos.c, Digit: digit, Type: ActionEliminate})
					}
				}
			}
		}
	}
	return actions
}
