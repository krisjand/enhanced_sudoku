package sudoku

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
	if !result.Solved {
		return DifficultyResult{Level: DifficultyLegendary}
	}

	seen := make(map[string]bool)
	var techniques []string
	maxRank := -1

	for _, iteration := range result.Iterations {
		for _, attempt := range iteration {
			if len(attempt.Steps) == 0 || seen[attempt.Technique] {
				continue
			}
			seen[attempt.Technique] = true
			techniques = append(techniques, attempt.Technique)
			if r := techniqueRank[attempt.Technique]; r > maxRank {
				maxRank = r
			}
		}
	}

	level := DifficultyEasy
	if maxRank >= 0 {
		level = rankToLevel[maxRank]
	}

	return DifficultyResult{Level: level, Techniques: techniques}
}
