package sudoku

import "time"

const (
	TechniqueNakedQuadruples      = "nakedQuadruples"
	TechniqueNakedQuadruplesRow    = "nakedQuadruplesRow"
	TechniqueNakedQuadruplesColumn = "nakedQuadruplesColumn"
	TechniqueNakedQuadruplesBox    = "nakedQuadruplesBox"
)

// NakedQuadruples identifies cells in a unit whose combined candidates contain
// exactly four digits, and records the eliminations this enables in the rest of
// the unit. Returns up to three SolveSteps — one per unit type that found
// eliminations — or nil if none exist. All actions are ActionEliminate.
func NakedQuadruples(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := nakedQuadruplesInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := nakedQuadruplesInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions := nakedQuadruplesInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedQuadruplesRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedQuadruplesColumn, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedQuadruplesBox, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func nakedQuadruplesInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for r := 0; r < 9; r++ {
		actions = eliminateFromQuadruples(actions, cands, seen, rowUnit(r))
	}
	return actions
}

func nakedQuadruplesInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for c := 0; c < 9; c++ {
		actions = eliminateFromQuadruples(actions, cands, seen, colUnit(c))
	}
	return actions
}

func nakedQuadruplesInBoxes(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for b := 0; b < 9; b++ {
		actions = eliminateFromQuadruples(actions, cands, seen, boxUnit(b))
	}
	return actions
}

// eliminateFromQuadruples finds naked quadruples in a unit and appends eliminations.
func eliminateFromQuadruples(actions []CellAction, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
	var candidates []cell
	for _, pos := range unit {
		n := popcount(cands[pos.r][pos.c])
		if n >= 2 && n <= 4 {
			candidates = append(candidates, pos)
		}
	}
	for i := 0; i < len(candidates)-3; i++ {
		for j := i + 1; j < len(candidates)-2; j++ {
			ab := cands[candidates[i].r][candidates[i].c] | cands[candidates[j].r][candidates[j].c]
			if popcount(ab) > 4 {
				continue
			}
			for k := j + 1; k < len(candidates)-1; k++ {
				abc := ab | cands[candidates[k].r][candidates[k].c]
				if popcount(abc) > 4 {
					continue
				}
				for l := k + 1; l < len(candidates); l++ {
					a, b, c, d := candidates[i], candidates[j], candidates[k], candidates[l]
					union := abc | cands[d.r][d.c]
					if popcount(union) != 4 {
						continue
					}
					// Found a naked quadruple — eliminate all four digits from other cells.
					for _, pos := range unit {
						if pos == a || pos == b || pos == c || pos == d {
							continue
						}
						m := union
						for m != 0 {
							bit := m & (-m)
							m &^= bit
							digit := int(trailingZeros(bit) + 1)
							if cands[pos.r][pos.c]&bit != 0 {
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
	}
	return actions
}
