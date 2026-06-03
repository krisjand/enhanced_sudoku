package sudoku

import "time"

const TechniqueHiddenSingles = "hiddenSingles"

// namedTechnique pairs a camelCase identifier with an analysis function.
// The identifier appears in TechniqueAttempt regardless of whether the function
// finds anything; step-level identifiers (e.g. "hiddenSingleRow") live inside
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
	{TechniqueLockedCandidates, LockedCandidates},
	{TechniqueNakedPairs, NakedPairs},
	{TechniqueHiddenPairs, HiddenPairs},
	{TechniqueNakedTriples, NakedTriples},
	{TechniqueHiddenTriples, HiddenTriples},
	{TechniqueNakedQuadruples, NakedQuadruples},
	{TechniqueHiddenQuadruples, HiddenQuadruples},
	{TechniqueXWing, XWing},
	{TechniqueForcedChains, NewForcedChains(defaultForcedChainsOptions())},
}

// KnownTechniques returns the registered technique names in complexity order.
func KnownTechniques() []string {
	names := make([]string, len(techniques))
	for i, t := range techniques {
		names[i] = t.name
	}
	return names
}

// IsKnownTechnique reports whether name matches a registered technique.
func IsKnownTechnique(name string) bool {
	for _, t := range techniques {
		if t.name == name {
			return true
		}
	}
	return false
}

// HumanSolveOpts holds optional overrides for HumanSolve.
type HumanSolveOpts struct {
	// FCMaxPropagation, if non-empty, limits forced chain branch propagation to
	// techniques up to and including the named technique. Must be a known technique
	// name simpler than forcedChains. Ignored when empty.
	FCMaxPropagation string
}

// HumanSolve solves puzzle using human techniques applied in complexity order.
func HumanSolve(puzzle Grid) SolveResult {
	return HumanSolveWith(puzzle, HumanSolveOpts{})
}

// HumanSolveWith is like HumanSolve but accepts optional overrides.
func HumanSolveWith(puzzle Grid, opts HumanSolveOpts) SolveResult {
	techs := techniques
	if opts.FCMaxPropagation != "" {
		propTechs := techniquesUpTo(opts.FCMaxPropagation)
		customFC := NewForcedChains(forcedChainsOptions{
			maxDepth:   defaultForcedChainsOptions().maxDepth,
			techniques: propTechs,
		})
		techs = make([]namedTechnique, len(techniques))
		copy(techs, techniques)
		for i, t := range techs {
			if t.name == TechniqueForcedChains {
				techs[i] = namedTechnique{TechniqueForcedChains, customFC}
				break
			}
		}
	}
	return humanSolveWith(puzzle, techs)
}

// techniquesUpTo returns a copy of the techniques slice including entries up to
// and including the entry named by maxTech. Returns nil if maxTech is not found
// (caller should have validated beforehand).
func techniquesUpTo(maxTech string) []namedTechnique {
	for i, t := range techniques {
		if t.name == maxTech {
			result := make([]namedTechnique, i+1)
			copy(result, techniques[:i+1])
			return result
		}
	}
	return nil
}

func humanSolveWith(puzzle Grid, techs []namedTechnique) SolveResult {
	start := time.Now()
	g := puzzle
	cands := Init(g)
	var iterations [][]TechniqueAttempt

	for !g.IsSolved() {
		var attempts []TechniqueAttempt
		found := false

		for _, tech := range techs {
			techStart := time.Now()
			steps := tech.fn(g, cands)
			dur := time.Since(techStart)

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
