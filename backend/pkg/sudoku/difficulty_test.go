package sudoku

import "testing"

func fixtureExpertHiddenTriplePuzzle() Grid {
	return Grid{
		{0, 1, 0, 2, 0, 0, 8, 0, 0},
		{0, 0, 0, 5, 0, 6, 0, 0, 0},
		{3, 0, 0, 0, 0, 9, 0, 0, 2},
		{1, 4, 7, 0, 0, 0, 5, 3, 0},
		{8, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 2, 7},
		{7, 0, 0, 0, 0, 3, 0, 0, 0},
		{0, 0, 3, 0, 0, 0, 4, 0, 0},
		{0, 0, 0, 0, 4, 0, 0, 5, 0},
	}
}

func TestRate(t *testing.T) {
	tests := []struct {
		name          string
		puzzle        Grid
		wantLevel     string
		wantTechnique string // expected in Techniques slice; "" to skip check
	}{
		{
			name:          "easy: near-complete puzzle",
			puzzle:        fixtureNearCompletePuzzle(),
			wantLevel:     DifficultyEasy,
			wantTechnique: TechniqueNakedSingles,
		},
		{
			name:          "easy: standard newspaper puzzle",
			puzzle:        fixtureStandardPuzzle(),
			wantLevel:     DifficultyEasy,
			wantTechnique: TechniqueNakedSingles,
		},
		{
			name:          "medium: naked pairs puzzle",
			puzzle:        fixtureNakedPairs2Puzzle(),
			wantLevel:     DifficultyMedium,
			wantTechnique: TechniqueNakedPairs,
		},
		{
			// fixtureNakedTriplesPuzzle is fully solvable with locked candidates
			name:          "hard: hidden triples fixture needs naked triples",
			puzzle:        fixtureHiddenTriplesPuzzle(),
			wantLevel:     DifficultyHard,
			wantTechnique: TechniqueNakedTriples,
		},
		{
			// fixtureNakedQuadruplesPuzzle is fully solvable with hidden pairs
			name:          "hard: naked quadruples fixture needs hidden pairs",
			puzzle:        fixtureNakedQuadruplesPuzzle(),
			wantLevel:     DifficultyHard,
			wantTechnique: TechniqueHiddenPairs,
		},
		{
			name:          "expert: hidden triple puzzle (seed 42, offset 253)",
			puzzle:        fixtureExpertHiddenTriplePuzzle(),
			wantLevel:     DifficultyExpert,
			wantTechnique: TechniqueHiddenTriples,
		},
		{
			name:          "master: forced chains puzzle",
			puzzle:        fixtureForcedChainDualCellPuzzle(),
			wantLevel:     DifficultyMaster,
			wantTechnique: TechniqueForcedChains,
		},
		{
			name:      "legendary: puzzle unsolvable by known techniques",
			puzzle:    Grid{},
			wantLevel: DifficultyLegendary,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := Rate(tt.puzzle)

			if got.Level != tt.wantLevel {
				t.Errorf("Level = %q, want %q (techniques used: %v)", got.Level, tt.wantLevel, got.Techniques)
			}

			if tt.wantTechnique != "" {
				found := false
				for _, tech := range got.Techniques {
					if tech == tt.wantTechnique {
						found = true
						break
					}
				}
				if !found {
					t.Errorf("Techniques = %v, want to contain %q", got.Techniques, tt.wantTechnique)
				}
			}

		})
	}
}
