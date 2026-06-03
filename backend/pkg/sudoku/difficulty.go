package sudoku

import "fmt"

const (
	DifficultyEasy      = "easy"
	DifficultyMedium    = "medium"
	DifficultyHard      = "hard"
	DifficultyExpert    = "expert"
	DifficultyMaster    = "master"
	DifficultyLegendary = "legendary"
)

// DifficultyResult is the output of Rate.
type DifficultyResult struct {
	Level      string   // one of the Difficulty constants
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
	TechniqueForcedChains:     4,
}

var rankToLevel = []string{
	DifficultyEasy,
	DifficultyMedium,
	DifficultyHard,
	DifficultyExpert,
	DifficultyMaster,
}

// Rate determines the difficulty of puzzle by running HumanSolve and
// inspecting which techniques were required.
func Rate(puzzle Grid) DifficultyResult {
	result := HumanSolve(puzzle)

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

	if !result.Solved {
		return DifficultyResult{Level: DifficultyLegendary, Techniques: techniques}
	}

	level := DifficultyEasy
	if maxRank >= 0 {
		if maxRank >= len(rankToLevel) {
			panic(fmt.Sprintf("rank %d out of range — extend rankToLevel in difficulty.go", maxRank))
		}
		level = rankToLevel[maxRank]
	}

	return DifficultyResult{Level: level, Techniques: techniques}
}
