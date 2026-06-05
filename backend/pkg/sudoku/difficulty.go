package sudoku

import (
	"fmt"
	"sort"
)

const (
	DifficultyEasy      = "easy"
	DifficultyMedium    = "medium"
	DifficultyHard      = "hard"
	DifficultyExpert       = "expert"
	DifficultyMaster       = "master"
	DifficultyGrandmaster  = "grandmaster"
	DifficultyLegendary    = "legendary"
)

// DifficultyResult is the output of Rate.
type DifficultyResult struct {
	Level      string   // one of the Difficulty constants
	Decisive   string // the hardest technique
	Techniques []string // techniques that produced at least one step, in complexity order
}

// techniqueRank maps each technique name to a numeric rank used to find the
// hardest technique applied during a solve.
var techniqueRank = map[string]int{
	TechniqueNakedSingles:     0,
	TechniqueHiddenSingles:    0,
	TechniqueLockedCandidates: 1,
	TechniqueNakedPairs:       1,
	TechniqueHiddenPairs:      2,
	TechniqueNakedTriples:     2,
	TechniqueHiddenTriples:    3,
	TechniqueNakedQuadruples:  3,
	TechniqueHiddenQuadruples: 3,
	TechniqueXWing:            3,
	TechniqueSwordfish:        4,
	TechniqueXYWing:           4,
	TechniqueXYZWing:          4,
	TechniqueForcedChains:     5,
}

var rankToLevel = []string{
	DifficultyEasy,
	DifficultyMedium,
	DifficultyHard,
	DifficultyExpert,
	DifficultyMaster,
	DifficultyGrandmaster,
}

// DifficultyResult is the output of Rate.
type SortedTechniques struct {
	Decisive   string   // the most difficult/highly rated technique
	Techniques []string // techniques sorted by rank
}

var techniqueSortRank = map[string]int{
	TechniqueNakedSingles:     0,
	TechniqueHiddenSingles:    1,
	TechniqueLockedCandidates: 2,
	TechniqueNakedPairs:       3,
	TechniqueHiddenPairs:      4,
	TechniqueNakedTriples:     5,
	TechniqueHiddenTriples:    6,
	TechniqueNakedQuadruples:  7,
	TechniqueHiddenQuadruples: 8,
	TechniqueXWing:            9,
	TechniqueSwordfish:        10,
	TechniqueXYWing:           11,
	TechniqueXYZWing:          12,
	TechniqueForcedChains:     13,
}

// SortTechniques deduplicates techniques, sorts them from easiest to hardest
// by techniqueSortRank, and returns the sorted list plus the decisive (hardest)
// technique. Unknown techniques are placed at the end.
func SortTechniques(techniques []string) SortedTechniques {
	seen := make(map[string]bool, len(techniques))
	unique := make([]string, 0, len(techniques))
	for _, t := range techniques {
		if !seen[t] {
			seen[t] = true
			unique = append(unique, t)
		}
	}

	sort.SliceStable(unique, func(i, j int) bool {
		ri, oki := techniqueSortRank[unique[i]]
		rj, okj := techniqueSortRank[unique[j]]
		if !oki {
			ri = len(techniqueSortRank)
		}
		if !okj {
			rj = len(techniqueSortRank)
		}
		return ri < rj
	})

	decisive := ""
	if len(unique) > 0 {
		decisive = unique[len(unique)-1]
	}

	return SortedTechniques{
		Decisive:         decisive,
		Techniques: unique,
	}
}


// RateResult determines the difficulty of a puzzle from a pre-computed
// SolveResult. Use this when HumanSolve has already been called to avoid a
// second solve.
func RateResult(result SolveResult) DifficultyResult {
	seen := make(map[string]bool)
	techniques := []string{}
	maxRank := -1

	for _, iteration := range result.Iterations {
		for _, attempt := range iteration {
			if len(attempt.Steps) == 0 || seen[attempt.Technique] {
				continue
			}
			seen[attempt.Technique] = true
			techniques = append(techniques, attempt.Technique)
			r, ok := techniqueRank[attempt.Technique]
			if !ok {
				panic(fmt.Sprintf("techniqueRank missing entry for %q — add it to difficulty.go", attempt.Technique))
			}
			if r > maxRank {
				maxRank = r
			}
		}
	}

	sortedTechniques := SortTechniques(techniques)

	if !result.Solved {
		return DifficultyResult{Level: DifficultyLegendary, Decisive: sortedTechniques.Decisive, Techniques: sortedTechniques.Techniques}
	}

	level := DifficultyEasy
	if maxRank >= 0 {
		if maxRank >= len(rankToLevel) {
			panic(fmt.Sprintf("rank %d out of range — extend rankToLevel in difficulty.go", maxRank))
		}
		level = rankToLevel[maxRank]
	}

	return DifficultyResult{Level: level, Decisive: sortedTechniques.Decisive, Techniques: sortedTechniques.Techniques}
}

// Rate determines the difficulty of puzzle by running HumanSolve and
// inspecting which techniques were required.
func Rate(puzzle Grid) DifficultyResult {
	return RateResult(HumanSolve(puzzle))
}
