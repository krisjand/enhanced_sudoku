package sudoku

import "time"

const (
	TechniqueHiddenSingleRow    = "Hidden Single (Row)"
	TechniqueHiddenSingleColumn = "Hidden Single (Column)"
	TechniqueHiddenSingleBox    = "Hidden Single (Box)"
)

// HiddenSingles identifies cells where a digit can appear in only one position
// within a row, column, or box. Returns up to three SolveSteps — one per unit
// type that found at least one hidden single — or nil if none exist.
// Results are deduplicated: a (row, col, digit) found in a row scan is not
// re-emitted in the column or box scan.
func HiddenSingles(g Grid, cands Candidates) []SolveStep {
	start := time.Now()
	seen := make(map[[3]int]bool) // [row, col, digit]

	rowActions := hiddenSinglesInRows(cands, seen)
	colActions := hiddenSinglesInCols(cands, seen)
	boxActions := hiddenSinglesInBoxes(cands, seen)

	var steps []SolveStep
	if len(rowActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenSingleRow, Actions: rowActions, Duration: time.Since(start)})
	}
	if len(colActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenSingleColumn, Actions: colActions, Duration: time.Since(start)})
	}
	if len(boxActions) > 0 {
		steps = append(steps, SolveStep{Technique: TechniqueHiddenSingleBox, Actions: boxActions, Duration: time.Since(start)})
	}
	return steps
}

func hiddenSinglesInRows(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for r := 0; r < 9; r++ {
		for digit := 1; digit <= 9; digit++ {
			bit := uint16(1) << uint(digit-1)
			count, lastC := 0, 0
			for c := 0; c < 9; c++ {
				if cands[r][c]&bit != 0 {
					count++
					lastC = c
				}
			}
			if count == 1 {
				key := [3]int{r, lastC, digit}
				if !seen[key] {
					seen[key] = true
					actions = append(actions, CellAction{Row: r, Col: lastC, Digit: digit, Type: ActionSet})
				}
			}
		}
	}
	return actions
}

func hiddenSinglesInCols(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for c := 0; c < 9; c++ {
		for digit := 1; digit <= 9; digit++ {
			bit := uint16(1) << uint(digit-1)
			count, lastR := 0, 0
			for r := 0; r < 9; r++ {
				if cands[r][c]&bit != 0 {
					count++
					lastR = r
				}
			}
			if count == 1 {
				key := [3]int{lastR, c, digit}
				if !seen[key] {
					seen[key] = true
					actions = append(actions, CellAction{Row: lastR, Col: c, Digit: digit, Type: ActionSet})
				}
			}
		}
	}
	return actions
}

func hiddenSinglesInBoxes(cands Candidates, seen map[[3]int]bool) []CellAction {
	var actions []CellAction
	for b := 0; b < 9; b++ {
		br, bc := (b/3)*3, (b%3)*3
		for digit := 1; digit <= 9; digit++ {
			bit := uint16(1) << uint(digit-1)
			count, lastR, lastC := 0, 0, 0
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					r, c := br+dr, bc+dc
					if cands[r][c]&bit != 0 {
						count++
						lastR, lastC = r, c
					}
				}
			}
			if count == 1 {
				key := [3]int{lastR, lastC, digit}
				if !seen[key] {
					seen[key] = true
					actions = append(actions, CellAction{Row: lastR, Col: lastC, Digit: digit, Type: ActionSet})
				}
			}
		}
	}
	return actions
}
