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
// Seeds are tried in three passes, stopping at the first that yields a conclusion:
//  1. Bi-value cell seeds (cell with exactly 2 candidates)
//  2. Bi-location unit seeds (digit with exactly 2 candidate cells in a unit)
//  3. Tri-value cell seeds (cell with exactly 3 candidates)
//
// Within each pass all seeds are advanced one depth step at a time (BFS) so
// the shortest chain is found first.
func NewForcedChains(opts forcedChainsOptions) TechniqueFn {
	return func(g Grid, cands Candidates) []SolveStep {
		start := time.Now()
		// Pass 1: bi-value cells
		if steps := runForcedChainPass(collectBivalueSeeds(g, cands), opts, start); steps != nil {
			return steps
		}
		// Pass 2: bi-location units
		if steps := runForcedChainPass(collectBilocationSeeds(g, cands), opts, start); steps != nil {
			return steps
		}
		// Pass 3: tri-value cells
		if steps := runForcedChainPass(collectCellSeeds(g, cands, 3), opts, start); steps != nil {
			return steps
		}
		return nil
	}
}

// fcBranch holds the state of one candidate assumption within a forced chain search.
type fcBranch struct {
	candidate    int
	seedRow      int // row of the cell where this branch places its digit
	seedCol      int // col of the cell where this branch places its digit
	g            Grid
	cands        Candidates
	steps        []SolveStep  // technique steps taken inside this branch
	allActions   []CellAction // flattened actions for intersection
	contradicted bool
	exhausted    bool // no technique found anything; chain cannot progress further
}

type fcSeed struct {
	branches []*fcBranch
}

// collectBivalueSeeds returns one seed per cell with exactly 2 candidates.
func collectBivalueSeeds(g Grid, cands Candidates) []fcSeed {
	return collectCellSeeds(g, cands, 2)
}

// collectCellSeeds returns one seed per cell whose candidate count equals valence.
func collectCellSeeds(g Grid, cands Candidates, valence int) []fcSeed {
	var seeds []fcSeed
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 || cands.Count(r, c) != valence {
				continue
			}
			s := fcSeed{}
			mask := cands[r][c]
			for d := 1; d <= 9; d++ {
				if mask&(1<<uint(d-1)) == 0 {
					continue
				}
				b := &fcBranch{candidate: d, seedRow: r, seedCol: c, g: g, cands: cands}
				b.g[r][c] = uint8(d)
				b.cands.Set(r, c, d)
				b.contradicted = fcHasContradiction(b.g, b.cands)
				s.branches = append(s.branches, b)
			}
			seeds = append(seeds, s)
		}
	}
	return seeds
}

// collectBilocationSeeds returns one seed per (unit, digit) pair where the digit
// appears in exactly 2 candidate cells in that unit. Duplicate pairs (same two
// cells for the same digit arising from multiple units) are deduplicated.
func collectBilocationSeeds(g Grid, cands Candidates) []fcSeed {
	type pairKey [3]int // [digit, linearA, linearB] with linearA < linearB

	seen := map[pairKey]bool{}
	var seeds []fcSeed

	addSeed := func(d int, a, b cell) {
		idxA, idxB := a.r*9+a.c, b.r*9+b.c
		if idxA > idxB {
			idxA, idxB = idxB, idxA
			a, b = b, a
		}
		k := pairKey{d, idxA, idxB}
		if seen[k] {
			return
		}
		seen[k] = true

		bA := &fcBranch{candidate: d, seedRow: a.r, seedCol: a.c, g: g, cands: cands}
		bA.g[a.r][a.c] = uint8(d)
		bA.cands.Set(a.r, a.c, d)
		bA.contradicted = fcHasContradiction(bA.g, bA.cands)

		bB := &fcBranch{candidate: d, seedRow: b.r, seedCol: b.c, g: g, cands: cands}
		bB.g[b.r][b.c] = uint8(d)
		bB.cands.Set(b.r, b.c, d)
		bB.contradicted = fcHasContradiction(bB.g, bB.cands)

		seeds = append(seeds, fcSeed{branches: []*fcBranch{bA, bB}})
	}

	for d := 1; d <= 9; d++ {
		bit := uint16(1) << uint(d-1)

		for r := 0; r < 9; r++ {
			var cells []cell
			for c := 0; c < 9; c++ {
				if g[r][c] == 0 && cands[r][c]&bit != 0 {
					cells = append(cells, cell{r, c})
				}
			}
			if len(cells) == 2 {
				addSeed(d, cells[0], cells[1])
			}
		}

		for c := 0; c < 9; c++ {
			var cells []cell
			for r := 0; r < 9; r++ {
				if g[r][c] == 0 && cands[r][c]&bit != 0 {
					cells = append(cells, cell{r, c})
				}
			}
			if len(cells) == 2 {
				addSeed(d, cells[0], cells[1])
			}
		}

		for b := 0; b < 9; b++ {
			br, bc := (b/3)*3, (b%3)*3
			var cells []cell
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					r, c := br+dr, bc+dc
					if g[r][c] == 0 && cands[r][c]&bit != 0 {
						cells = append(cells, cell{r, c})
					}
				}
			}
			if len(cells) == 2 {
				addSeed(d, cells[0], cells[1])
			}
		}
	}
	return seeds
}

func runForcedChainPass(seeds []fcSeed, opts forcedChainsOptions, start time.Time) []SolveStep {
	if len(seeds) == 0 {
		return nil
	}
	for depth := 0; depth <= opts.maxDepth; depth++ {
		for _, s := range seeds {
			if steps := fcExtractConclusion(s.branches, start); steps != nil {
				return steps
			}
		}
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

func fcExtractConclusion(branches []*fcBranch, start time.Time) []SolveStep {
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
		actions = append(actions, CellAction{Row: b.seedRow, Col: b.seedCol, Digit: b.candidate, Type: ActionSet})
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
