package sudoku

import "testing"

func TestHumanSolve(t *testing.T) {
	tests := []struct {
		name       string
		puzzle     Grid
		wantSolved bool
		check      func(t *testing.T, r SolveResult)
	}{
		{
			name:       "already solved grid",
			puzzle:     fixtureUniqueSolution(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				if len(r.Iterations) != 0 {
					t.Errorf("expected 0 iterations for solved grid, got %d", len(r.Iterations))
				}
			},
		},
		{
			name:       "near-complete puzzle solved by naked singles",
			puzzle:     fixtureNearCompletePuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				if len(r.Iterations) == 0 {
					t.Fatal("expected at least one iteration")
				}
				// Every winning attempt must be naked singles.
				for i, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner == nil {
						t.Errorf("iteration %d: no winning attempt", i)
						continue
					}
					if winner.Technique != TechniqueNakedSingles {
						t.Errorf("iteration %d: winning technique = %q, want %q",
							i, winner.Technique, TechniqueNakedSingles)
					}
				}
			},
		},
		{
			name:       "standard puzzle solved (may require hidden singles)",
			puzzle:     fixtureStandardPuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				assertSolveResultValid(t, r, fixtureStandardPuzzle())
			},
		},
		{
			name:       "hidden pairs puzzle exercises HiddenPairs through HumanSolve",
			puzzle:     fixtureHiddenPairsPuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueHiddenPairs {
						return
					}
				}
				t.Error("no iteration had HiddenPairs as the winning technique")
			},
		},
		{
			name:       "locked candidates puzzle exercises LockedCandidates through HumanSolve",
			puzzle:     fixtureLockedCandidatesPuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueLockedCandidates {
						return
					}
				}
				t.Error("no iteration had LockedCandidates as the winning technique")
			},
		},
		{
			name:       "naked pairs puzzle exercises NakedPairs through HumanSolve",
			puzzle:     fixtureNakedPairs2Puzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueNakedPairs {
						return
					}
				}
				t.Error("no iteration had NakedPairs as the winning technique")
			},
		},
		{
			name:       "naked triples puzzle exercises NakedTriples through HumanSolve",
			puzzle:     fixtureNakedTriplesHumanSolvePuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueNakedTriples {
						return
					}
				}
				t.Error("no iteration had NakedTriples as the winning technique")
			},
		},
		{
			name:       "hidden triples puzzle exercises HiddenTriples through HumanSolve",
			puzzle:     fixtureHiddenTriplesPuzzle2(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueHiddenTriples {
						return
					}
				}
				t.Error("no iteration had HiddenTriples as the winning technique")
			},
		},
		{
			name:       "hidden quadruples puzzle exercises HiddenQuadruples through HumanSolve",
			puzzle:     fixtureHiddenQuadruplesHumanSolvePuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueHiddenQuadruples {
						return
					}
				}
				t.Error("no iteration had HiddenQuadruples as the winning technique")
			},
		},
		{
			name:       "naked quadruples puzzle exercises NakedQuadruples through HumanSolve",
			puzzle:     fixtureNakedQuadruplesHumanSolvePuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueNakedQuadruples {
						return
					}
				}
				t.Error("no iteration had NakedQuadruples as the winning technique")
			},
		},
		{
			name:       "forced chain dual-cell puzzle exercises ForcedChains through HumanSolve",
			puzzle:     fixtureForcedChainDualCellPuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueForcedChains {
						return
					}
				}
				t.Error("no iteration had ForcedChains as the winning technique")
			},
		},
		{
			name:       "forced chain dual-cell puzzle 2 exercises ForcedChains through HumanSolve",
			puzzle:     fixtureForcedChainDualCell2Puzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueForcedChains {
						return
					}
				}
				t.Error("no iteration had ForcedChains as the winning technique")
			},
		},
		{
			name:   "forcing chain triple-cell puzzle 2 exercises ForcedChains (intersection) through HumanSolve",
			puzzle: fixtureForcingChainTripleCell2Puzzle(),
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueForcedChains {
						return
					}
				}
				t.Error("no iteration had ForcedChains as the winning technique")
			},
		},
		{
			name:       "forcing chain triple-cell puzzle exercises ForcedChains through HumanSolve",
			puzzle:     fixtureForcingChainTripleCellPuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueForcedChains {
						return
					}
				}
				t.Error("no iteration had ForcedChains as the winning technique")
			},
		},
		{
			name:       "x-wing puzzle exercises XWing through HumanSolve",
			puzzle:     fixtureXWingPuzzle(),
			wantSolved: true,
			check: func(t *testing.T, r SolveResult) {
				for _, iter := range r.Iterations {
					winner := winningAttempt(iter)
					if winner != nil && winner.Technique == TechniqueXWing {
						return
					}
				}
				t.Error("no iteration had XWing as the winning technique")
			},
		},
		{
			name:       "empty grid is stuck with current techniques",
			puzzle:     Grid{},
			wantSolved: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := HumanSolve(tt.puzzle)

			if result.Solved != tt.wantSolved {
				t.Errorf("Solved = %v, want %v", result.Solved, tt.wantSolved)
			}
			if result.Solved && !result.Grid.IsSolved() {
				t.Error("Solved=true but Grid is not fully solved")
			}

			// All attempts must have a technique name and non-negative duration.
			for i, iter := range result.Iterations {
				for j, attempt := range iter {
					if attempt.Technique == "" {
						t.Errorf("iteration %d attempt %d: empty Technique", i, j)
					}
					if attempt.Duration < 0 {
						t.Errorf("iteration %d attempt %d: negative Duration", i, j)
					}
				}
			}

			if tt.check != nil {
				tt.check(t, result)
			}
		})
	}
}

// fixtureNearCompletePuzzle returns the near-complete puzzle from naked_singles_test.go.
func fixtureNearCompletePuzzle() Grid {
	g, _ := fixtureNearComplete()
	return g
}

// winningAttempt returns the first attempt in an iteration that found steps.
func winningAttempt(iter []TechniqueAttempt) *TechniqueAttempt {
	for i := range iter {
		if len(iter[i].Steps) > 0 {
			return &iter[i]
		}
	}
	return nil
}

// assertSolveResultValid checks structural correctness of a SolveResult.
func assertSolveResultValid(t *testing.T, r SolveResult, original Grid) {
	t.Helper()
	// Solution must be a superset of the original puzzle clues.
	for row := 0; row < 9; row++ {
		for col := 0; col < 9; col++ {
			if original[row][col] != 0 && r.Grid[row][col] != original[row][col] {
				t.Errorf("solution[%d][%d]=%d does not match original clue %d",
					row, col, r.Grid[row][col], original[row][col])
			}
		}
	}
	// Every action in every step must be consistent with the final grid.
	for _, iter := range r.Iterations {
		for _, attempt := range iter {
			for _, step := range attempt.Steps {
				for _, a := range step.Actions {
					if a.Type == ActionSet && r.Grid[a.Row][a.Col] != uint8(a.Digit) {
						t.Errorf("action Set(%d) at (%d,%d) inconsistent with final grid value %d",
							a.Digit, a.Row, a.Col, r.Grid[a.Row][a.Col])
					}
				}
			}
		}
	}
}
