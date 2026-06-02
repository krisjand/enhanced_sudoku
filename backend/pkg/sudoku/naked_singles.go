package sudoku

import "time"

const TechniqueNakedSingles = "nakedSingles"

// NakedSingles identifies all cells where only one digit remains possible.
// Returns a single SolveStep containing all found naked singles, or nil if none exist.
func NakedSingles(g Grid, cands Candidates) []SolveStep {
	start := time.Now()
	var actions []CellAction
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 {
				continue
			}
			if d := cands.Only(r, c); d != 0 {
				actions = append(actions, CellAction{
					Row:   r,
					Col:   c,
					Digit: int(d),
					Type:  ActionSet,
				})
			}
		}
	}
	if len(actions) == 0 {
		return nil
	}
	return []SolveStep{{
		Technique: TechniqueNakedSingles,
		Actions:   actions,
		Duration:  time.Since(start),
	}}
}
