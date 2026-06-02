package sudoku

import "time"

const (
	TechniqueNakedPairs       = "Naked Pairs"
	TechniqueNakedPairRow     = "Naked Pair (Row)"
	TechniqueNakedPairColumn  = "Naked Pair (Column)"
	TechniqueNakedPairBox     = "Naked Pair (Box)"
)

// NakedPairs identifies cells in a unit that share exactly the same two
// candidates, and records the eliminations this enables in the rest of the unit.
// Returns up to three SolveSteps — one per unit type that found eliminations —
// or nil if none exist. All actions are ActionEliminate.
func NakedPairs(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	rowStart := time.Now()
	rowActions := nakedPairsInRows(cands, seen)
	rowDur := time.Since(rowStart)

	colStart := time.Now()
	colActions := nakedPairsInCols(cands, seen)
	colDur := time.Since(colStart)

	boxStart := time.Now()
	boxActions := nakedPairsInBoxes(cands, seen)
	boxDur := time.Since(boxStart)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedPairRow, Actions: rowActions, Duration: rowDur})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedPairColumn, Actions: colActions, Duration: colDur})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueNakedPairBox, Actions: boxActions, Duration: boxDur})
	}
	return steps
}

func nakedPairsInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for r := 0; r < 9; r++ {
		actions = eliminateFromPairs(actions, cands, seen, rowUnit(r))
	}
	return actions
}

func nakedPairsInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for c := 0; c < 9; c++ {
		actions = eliminateFromPairs(actions, cands, seen, colUnit(c))
	}
	return actions
}

func nakedPairsInBoxes(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for b := 0; b < 9; b++ {
		actions = eliminateFromPairs(actions, cands, seen, boxUnit(b))
	}
	return actions
}

// cell holds a row/col coordinate.
type cell struct{ r, c int }

// eliminateFromPairs finds naked pairs in a unit and appends eliminations.
func eliminateFromPairs(actions []CellAction, cands Candidates, seen map[[3]int]bool, unit []cell) []CellAction {
	// Collect cells with exactly 2 candidates.
	var pairs []cell
	for _, pos := range unit {
		if popcount(cands[pos.r][pos.c]) == 2 {
			pairs = append(pairs, pos)
		}
	}
	// Check each combination of two cells.
	for i := 0; i < len(pairs)-1; i++ {
		for j := i + 1; j < len(pairs); j++ {
			a, b := pairs[i], pairs[j]
			if cands[a.r][a.c] != cands[b.r][b.c] {
				continue
			}
			// Found a naked pair — eliminate both digits from all other cells in the unit.
			mask := cands[a.r][a.c]
			for _, pos := range unit {
				if pos == a || pos == b {
					continue
				}
				m := mask
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
	return actions
}

// rowUnit returns the 9 cells in row r.
func rowUnit(r int) []cell {
	cells := make([]cell, 9)
	for c := 0; c < 9; c++ {
		cells[c] = cell{r, c}
	}
	return cells
}

// colUnit returns the 9 cells in column c.
func colUnit(c int) []cell {
	cells := make([]cell, 9)
	for r := 0; r < 9; r++ {
		cells[r] = cell{r, c}
	}
	return cells
}

// boxUnit returns the 9 cells in box b (0-8, row-major).
func boxUnit(b int) []cell {
	br, bc := (b/3)*3, (b%3)*3
	cells := make([]cell, 0, 9)
	for dr := 0; dr < 3; dr++ {
		for dc := 0; dc < 3; dc++ {
			cells = append(cells, cell{br + dr, bc + dc})
		}
	}
	return cells
}
