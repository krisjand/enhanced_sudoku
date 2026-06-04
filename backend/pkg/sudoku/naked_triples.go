package sudoku

import "time"

const (
	TechniqueNakedTriples      = "nakedTriples"
	TechniqueNakedTripleRow    = "nakedTripleRow"
	TechniqueNakedTripleColumn = "nakedTripleColumn"
	TechniqueNakedTripleBox    = "nakedTripleBox"
)

// NakedTriples identifies cells in a unit whose combined candidates contain
// exactly three digits, and records the eliminations this enables in the rest
// of the unit. Returns up to three SolveSteps — one per unit type that found
// eliminations — or nil if none exist. All actions are ActionEliminate.
func NakedTriples(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions, rowSources := nakedTriplesInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions, colSources := nakedTriplesInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions, boxSources := nakedTriplesInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedTripleRow, Sources: rowSources, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedTripleColumn, Sources: colSources, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedTripleBox, Sources: boxSources, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func nakedTriplesInRows(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for r := 0; r < 9; r++ {
		actions = eliminateFromTriples(actions, &sources, cands, seen, rowUnit(r))
	}
	return actions, sources
}

func nakedTriplesInCols(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for c := 0; c < 9; c++ {
		actions = eliminateFromTriples(actions, &sources, cands, seen, colUnit(c))
	}
	return actions, sources
}

func nakedTriplesInBoxes(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	var actions []CellAction
	var sources []SourceCell
	for b := 0; b < 9; b++ {
		actions = eliminateFromTriples(actions, &sources, cands, seen, boxUnit(b))
	}
	return actions, sources
}

// eliminateFromTriples finds naked triples in a unit and appends eliminations.
func eliminateFromTriples(actions []CellAction, sources *[]SourceCell, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
	// Collect cells with 2 or 3 candidates.
	// Cells with 1 candidate are excluded: in the HumanSolve pipeline NakedSingles
	// always runs before NakedTriples and resolves every 1-candidate cell, so n == 1
	// is never reachable here. When called in isolation the caller must ensure naked
	// singles have already been applied.
	var candidates []cell
	for _, pos := range unit {
		n := popcount(cands[pos.r][pos.c])
		if n == 2 || n == 3 {
			candidates = append(candidates, pos)
		}
	}
	// Check each combination of three cells.
	for i := 0; i < len(candidates)-2; i++ {
		for j := i + 1; j < len(candidates)-1; j++ {
			for k := j + 1; k < len(candidates); k++ {
				a, b, c := candidates[i], candidates[j], candidates[k]
				union := cands[a.r][a.c] | cands[b.r][b.c] | cands[c.r][c.c]
				if popcount(union) != 3 {
					continue
				}
				// Found a naked triple — eliminate all three digits from other cells.
				prevLen := len(actions)
				for _, pos := range unit {
					if pos == a || pos == b || pos == c {
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
					)
				}
			}
		}
	}
	return actions
}
