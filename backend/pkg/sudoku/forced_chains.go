package sudoku

import "time"

const TechniqueForcedChains = "forcedChains"

type forcedChainsOptions struct {
	maxDepth   int
	techniques []namedTechnique
}

func defaultForcedChainsOptions() forcedChainsOptions {
	return forcedChainsOptions{
		maxDepth: 20,
		techniques: []namedTechnique{
			{TechniqueNakedSingles, NakedSingles},
			{TechniqueHiddenSingles, HiddenSingles},
			{TechniqueLockedCandidates, LockedCandidates},
		},
	}
}

// NewForcedChains returns a TechniqueFn that searches for forced chains.
// It tries bi-value seed cells first; if none yield a conclusion it falls back to tri-value seeds.
// Within each seed cell, branches for each candidate are advanced one depth step at a time
// (BFS across all seeds) so the shortest chain is found first.
func NewForcedChains(opts forcedChainsOptions) TechniqueFn {
	return func(g Grid, cands Candidates) []SolveStep {
		start := time.Now()
		for _, valence := range []int{2, 3} {
			if steps := searchForcedChains(g, cands, valence, opts, start); steps != nil {
				return steps
			}
		}
		return nil
	}
}

// fcBranch holds the state of one candidate assumption within a forced chain search.
type fcBranch struct {
	candidate    int
	g            Grid
	cands        Candidates
	steps        []SolveStep  // technique steps taken inside this branch
	allActions   []CellAction // flattened actions for intersection
	contradicted bool
	exhausted    bool // no technique found anything; chain cannot progress further
}

type fcSeed struct {
	row, col int
	branches []*fcBranch
}

func searchForcedChains(g Grid, cands Candidates, valence int, opts forcedChainsOptions, start time.Time) []SolveStep {
	var seeds []fcSeed
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 || cands.Count(r, c) != valence {
				continue
			}
			s := fcSeed{row: r, col: c}
			mask := cands[r][c]
			for d := 1; d <= 9; d++ {
				if mask&(1<<uint(d-1)) == 0 {
					continue
				}
				b := &fcBranch{candidate: d, g: g, cands: cands}
				b.g[r][c] = uint8(d)
				b.cands.Set(r, c, d)
				b.contradicted = fcHasContradiction(b.g, b.cands)
				s.branches = append(s.branches, b)
			}
			seeds = append(seeds, s)
		}
	}
	if len(seeds) == 0 {
		return nil
	}

	for depth := 0; depth <= opts.maxDepth; depth++ {
		// Check all seeds for a conclusion at the current depth before advancing further.
		for _, s := range seeds {
			if steps := fcExtractConclusion(s.row, s.col, s.branches, start); steps != nil {
				return steps
			}
		}
		if depth == opts.maxDepth {
			break
		}
		// Advance every active branch by one technique application (BFS across all seeds).
		allDone := true
		for i := range seeds {
			for _, b := range seeds[i].branches {
				if b.contradicted || b.exhausted {
					continue
				}
				allDone = false
				fcAdvance(b, opts.techniques)
			}
		}
		if allDone {
			break
		}
	}
	return nil
}

// fcAdvance runs the configured techniques on the branch state and applies the first
// technique that finds anything, counting as one depth step.
func fcAdvance(b *fcBranch, techs []namedTechnique) {
	for _, tech := range techs {
		steps := tech.fn(b.g, b.cands)
		if len(steps) == 0 {
			continue
		}
		b.steps = append(b.steps, steps...)
		for _, step := range steps {
			for _, a := range step.Actions {
				switch a.Type {
				case ActionSet:
					b.g[a.Row][a.Col] = uint8(a.Digit)
					b.cands.Set(a.Row, a.Col, a.Digit)
				case ActionEliminate:
					b.cands.Eliminate(a.Row, a.Col, a.Digit)
				}
				b.allActions = append(b.allActions, a)
			}
		}
		b.contradicted = fcHasContradiction(b.g, b.cands)
		return
	}
	b.exhausted = true
}

func fcHasContradiction(g Grid, cands Candidates) bool {
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] == 0 && cands[r][c] == 0 {
				return true
			}
		}
	}
	return false
}

func fcExtractConclusion(row, col int, branches []*fcBranch, start time.Time) []SolveStep {
	var valid, contradicted []*fcBranch
	for _, b := range branches {
		if b.contradicted {
			contradicted = append(contradicted, b)
		} else {
			valid = append(valid, b)
		}
	}
	if len(valid) == 0 {
		return nil
	}

	chains := make([]ForcedChainBranch, len(branches))
	for i, b := range branches {
		chains[i] = ForcedChainBranch{Candidate: b.candidate, Steps: b.steps}
	}

	if len(contradicted) > 0 && len(valid) == 1 {
		// Only one candidate survives: place it and include all consequences.
		b := valid[0]
		actions := make([]CellAction, 0, 1+len(b.allActions))
		actions = append(actions, CellAction{Row: row, Col: col, Digit: b.candidate, Type: ActionSet})
		actions = append(actions, b.allActions...)
		return []SolveStep{{
			Technique: TechniqueForcedChains,
			Actions:   actions,
			Duration:  time.Since(start),
			Chains:    chains,
		}}
	}

	// Find actions present in every valid branch (common placement or elimination).
	common := fcIntersectActions(valid)
	if len(common) == 0 {
		return nil
	}
	return []SolveStep{{
		Technique: TechniqueForcedChains,
		Actions:   common,
		Duration:  time.Since(start),
		Chains:    chains,
	}}
}

type fcActionKey struct {
	row, col   int
	digit      int
	actionType ActionType
}

// fcIntersectActions returns actions that appear in every branch, preserving
// the order from the first branch.
func fcIntersectActions(branches []*fcBranch) []CellAction {
	if len(branches) == 0 {
		return nil
	}
	counts := make(map[fcActionKey]int)
	for _, b := range branches {
		seen := make(map[fcActionKey]bool)
		for _, a := range b.allActions {
			k := fcActionKey{a.Row, a.Col, a.Digit, a.Type}
			if !seen[k] {
				seen[k] = true
				counts[k]++
			}
		}
	}
	emitted := make(map[fcActionKey]bool)
	var common []CellAction
	for _, a := range branches[0].allActions {
		k := fcActionKey{a.Row, a.Col, a.Digit, a.Type}
		if counts[k] == len(branches) && !emitted[k] {
			emitted[k] = true
			common = append(common, a)
		}
	}
	return common
}
