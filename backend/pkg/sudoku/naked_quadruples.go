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
	rowActions, rowSources := nakedQuadruplesInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions, colSources := nakedQuadruplesInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions, boxSources := nakedQuadruplesInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedQuadruplesRow, Sources: rowSources, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedQuadruplesColumn, Sources: colSources, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedQuadruplesBox, Sources: boxSources, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func nakedQuadruplesInRows(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for r := 0; r < 9; r++ {
		actions = eliminateFromQuadruples(actions, &sources, cands, seen, rowUnit(r))
	}
	return actions, sources
}

func nakedQuadruplesInCols(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for c := 0; c < 9; c++ {
		actions = eliminateFromQuadruples(actions, &sources, cands, seen, colUnit(c))
	}
	return actions, sources
}

func nakedQuadruplesInBoxes(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for b := 0; b < 9; b++ {
		actions = eliminateFromQuadruples(actions, &sources, cands, seen, boxUnit(b))
	}
	return actions, sources
}

// eliminateFromQuadruples finds naked quadruples in a unit and appends eliminations.
func eliminateFromQuadruples(actions []CellAction, sources *[]SourceCell, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
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
					prevLen := len(actions)
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
					if len(actions) > prevLen {
						*sources = append(*sources,
							SourceCell{Row: a.r, Col: a.c, Digits: maskToDigits(cands[a.r][a.c])},
							SourceCell{Row: b.r, Col: b.c, Digits: maskToDigits(cands[b.r][b.c])},
							SourceCell{Row: c.r, Col: c.c, Digits: maskToDigits(cands[c.r][c.c])},
							SourceCell{Row: d.r, Col: d.c, Digits: maskToDigits(cands[d.r][d.c])},
						)
					}
				}
			}
		}
	}
	return actions
}
