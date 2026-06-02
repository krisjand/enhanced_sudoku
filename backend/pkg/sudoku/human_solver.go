package sudoku

import "time"

const TechniqueHiddenSingles = "Hidden Singles"

// namedTechnique pairs a display name with an analysis function.
// The name appears in TechniqueAttempt regardless of whether the function
// finds anything; step-level names (e.g. "Hidden Single (Row)") live inside
// the returned SolveSteps.
type namedTechnique struct {
	name string
	fn   TechniqueFn
}

// techniques lists analysis functions in order of complexity — simplest first.
// Add new techniques here as they are implemented.
var techniques = []namedTechnique{
	{TechniqueNakedSingles, NakedSingles},
	{TechniqueHiddenSingles, HiddenSingles},
	{TechniqueNakedPairs, NakedPairs},
	{TechniqueHiddenPairs, HiddenPairs},
}

// HumanSolve solves puzzle using human techniques applied in complexity order.
// Each iteration tries techniques until one succeeds; if none succeed the puzzle
// is stuck with the currently implemented techniques.
// Returns a full trace of every attempt (successful or not) for each iteration.
func HumanSolve(puzzle Grid) SolveResult {
	start := time.Now()
	g := puzzle
	cands := Init(g)
	var iterations [][]TechniqueAttempt

	for !g.IsSolved() {
		var attempts []TechniqueAttempt
		found := false

		for _, tech := range techniques {
			start := time.Now()
			steps := tech.fn(g, cands)
			dur := time.Since(start)

			attempts = append(attempts, TechniqueAttempt{
				Technique: tech.name,
				Duration:  dur,
				Steps:     steps,
			})

			if len(steps) > 0 {
				applied := false
				for _, s := range steps {
					for _, a := range s.Actions {
						switch a.Type {
						case ActionSet:
							g[a.Row][a.Col] = uint8(a.Digit)
							cands.Set(a.Row, a.Col, a.Digit)
							applied = true
						case ActionEliminate:
							cands.Eliminate(a.Row, a.Col, a.Digit)
							applied = true
						}
					}
				}
				if applied {
					found = true
					break
				}
			}
		}

		iterations = append(iterations, attempts)

		if !found {
			return SolveResult{Solved: false, Grid: g, Duration: time.Since(start), Iterations: iterations}
		}
	}

	return SolveResult{Solved: true, Grid: g, Duration: time.Since(start), Iterations: iterations}
}
