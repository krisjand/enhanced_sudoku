package sudoku

import "time"

const TechniqueHiddenSingles = "hiddenSingles"

// namedTechnique pairs a technique name with its analysis function.
type namedTechnique struct {
	name string
	fn   TechniqueFn
}

// techniques maps each technique name to its analysis function.
// Ordering is determined by TechniqueRegistry (via techniqueDefinitions).
var techniques = map[string]TechniqueFn{
	TechniqueNakedSingles:     NakedSingles,
	TechniqueHiddenSingles:    HiddenSingles,
	TechniqueLockedCandidates: LockedCandidates,
	TechniqueNakedPairs:       NakedPairs,
	TechniqueHiddenPairs:      HiddenPairs,
	TechniqueNakedTriples:     NakedTriples,
	TechniqueHiddenTriples:    HiddenTriples,
	TechniqueNakedQuadruples:  NakedQuadruples,
	TechniqueHiddenQuadruples: HiddenQuadruples,
	TechniqueXWing:            XWing,
	TechniqueSwordfish:        Swordfish,
	TechniqueXYWing:           XYWing,
	TechniqueXYZWing:          XYZWing,
	TechniqueForcedChains:     NewForcedChains(defaultForcedChainsOptions()),
}

// defaultTechs is the full ordered technique list, built once at package init.
var defaultTechs = func() []namedTechnique {
	reg, _ := NewTechniqueRegistry()
	return buildTechs(reg.Names(), nil)
}()

// KnownTechniques returns the registered technique names in complexity order.
func KnownTechniques() []string {
	reg, _ := NewTechniqueRegistry()
	return reg.Names()
}

// IsKnownTechnique reports whether name matches a registered technique.
func IsKnownTechnique(name string) bool {
	_, ok := techniques[name]
	return ok
}

// HumanSolveOpts holds optional overrides for HumanSolve.
type HumanSolveOpts struct {
	// MaxTechnique, if non-empty, limits the solver to techniques up to and
	// including the named technique. Must be a known technique name. Ignored when empty.
	MaxTechnique string
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
	var reg *TechniqueRegistry
	if opts.MaxTechnique != "" {
		var err error
		reg, err = NewTechniqueRegistry(opts.MaxTechnique)
		if err != nil {
			panic("HumanSolveWith: " + err.Error())
		}
	} else {
		reg, _ = NewTechniqueRegistry()
	}

	var overrides map[string]TechniqueFn
	if opts.FCMaxPropagation != "" {
		propReg, err := NewTechniqueRegistry(opts.FCMaxPropagation)
		if err != nil {
			panic("HumanSolveWith: " + err.Error())
		}
		overrides = map[string]TechniqueFn{
			TechniqueForcedChains: NewForcedChains(forcedChainsOptions{
				maxDepth:   defaultForcedChainsOptions().maxDepth,
				techniques: buildTechs(propReg.Names(), nil),
			}),
		}
	}

	return humanSolveWith(puzzle, buildTechs(reg.Names(), overrides))
}

// HumanSolveStep tries each technique once against g and cands and returns the
// first SolveStep found. solved=true if g has no empty cells. stuck=true if no
// technique makes progress.
func HumanSolveStep(g Grid, cands Candidates) (step *SolveStep, solved bool, stuck bool) {
	if g.IsSolved() {
		return nil, true, false
	}
	for _, tech := range defaultTechs {
		steps := tech.fn(g, cands)
		if len(steps) > 0 {
			return &steps[0], false, false
		}
	}
	return nil, false, true
}

// buildTechs constructs an ordered []namedTechnique from the given names,
// looking up each function in the techniques map. Entries in overrides replace
// the default function for that technique name. Names absent from the map are skipped.
func buildTechs(names []string, overrides map[string]TechniqueFn) []namedTechnique {
	result := make([]namedTechnique, 0, len(names))
	for _, name := range names {
		fn := techniques[name]
		if overrides != nil {
			if override, ok := overrides[name]; ok {
				fn = override
			}
		}
		if fn != nil {
			result = append(result, namedTechnique{name, fn})
		}
	}
	return result
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
