package sudoku

import "testing"

func fixtureForcedChainDualCellPuzzle() Grid {
	return Grid{
		{0, 0, 6, 0, 1, 9, 5, 0, 0},
		{9, 0, 7, 0, 6, 8, 0, 4, 3},
		{0, 8, 0, 0, 0, 0, 0, 0, 0},
		{8, 0, 4, 1, 9, 0, 0, 0, 0},
		{0, 0, 0, 6, 4, 5, 8, 0, 0},
		{0, 0, 0, 8, 0, 2, 9, 0, 4},
		{0, 0, 0, 0, 0, 6, 4, 2, 0},
		{5, 4, 0, 0, 0, 1, 6, 0, 7},
		{0, 0, 2, 9, 8, 4, 3, 0, 0},
	}
}

func fixtureForcedChainDualCell2Puzzle() Grid {
	return Grid{
		{0, 8, 0, 1, 0, 3, 0, 7, 0},
		{0, 9, 0, 5, 0, 6, 0, 0, 0},
		{0, 0, 1, 4, 0, 8, 0, 2, 0},
		{5, 7, 8, 2, 4, 1, 6, 3, 9},
		{1, 4, 3, 6, 5, 9, 7, 8, 2},
		{9, 2, 6, 8, 3, 7, 4, 5, 1},
		{0, 3, 7, 9, 0, 5, 2, 0, 0},
		{0, 0, 0, 3, 0, 4, 0, 9, 7},
		{4, 1, 9, 7, 8, 2, 0, 6, 0},
	}
}

func fixtureForcingChainTripleCellPuzzle() Grid {
	return Grid{
		{0, 2, 0, 0, 0, 6, 0, 3, 5},
		{0, 5, 8, 0, 0, 0, 6, 0, 1},
		{0, 6, 4, 0, 5, 0, 2, 8, 9},
		{0, 0, 6, 3, 0, 0, 9, 5, 2},
		{0, 3, 5, 6, 9, 0, 0, 1, 8},
		{8, 9, 0, 0, 0, 5, 3, 0, 6},
		{6, 0, 0, 0, 7, 0, 5, 9, 0},
		{5, 0, 9, 0, 6, 0, 8, 2, 0},
		{0, 8, 0, 5, 0, 9, 1, 6, 0},
	}
}

func fixtureForcingChainTripleCell2Puzzle() Grid {
	return Grid{
		{9, 2, 0, 0, 0, 6, 0, 3, 5},
		{0, 5, 8, 0, 0, 0, 6, 0, 1},
		{0, 6, 4, 0, 5, 0, 2, 8, 9},
		{0, 0, 6, 3, 0, 0, 9, 5, 2},
		{0, 3, 5, 6, 9, 0, 0, 1, 8},
		{8, 9, 0, 0, 0, 5, 3, 0, 6},
		{6, 0, 0, 0, 7, 0, 5, 9, 0},
		{5, 0, 9, 0, 6, 0, 8, 2, 0},
		{0, 8, 0, 5, 0, 9, 1, 6, 0},
	}
}

func TestForcedChains(t *testing.T) {
	fc := NewForcedChains(defaultForcedChainsOptions())

	tests := []struct {
		name    string
		grid    Grid
		wantNil bool
		check   func(t *testing.T, steps []SolveStep, grid Grid, cands Candidates)
	}{
		{
			name:    "solved grid has no forced chain",
			grid:    fixtureUniqueSolution(),
			wantNil: true,
		},
		{
			name:    "near-complete puzzle has no forced chain (solvable by naked singles)",
			grid:    fixtureNearCompletePuzzle(),
			wantNil: true,
		},
		{
			name:    "dual-cell forced chain puzzle yields a conclusion",
			grid:    fixtureForcedChainDualCellPuzzle(),
			wantNil: false,
			check:   assertForcedChainsValid,
		},
		{
			name:    "dual-cell forced chain puzzle 2 yields a conclusion",
			grid:    fixtureForcedChainDualCell2Puzzle(),
			wantNil: false,
			check:   assertForcedChainsValid,
		},
		{
			name:    "triple-cell forcing chain puzzle yields a contradiction conclusion",
			grid:    fixtureForcingChainTripleCellPuzzle(),
			wantNil: false,
			check:   assertForcedChainsValid,
		},
		{
			name:    "triple-cell forcing chain puzzle 2 yields an intersection conclusion",
			grid:    fixtureForcingChainTripleCell2Puzzle(),
			wantNil: false,
			check: func(t *testing.T, steps []SolveStep, grid Grid, cands Candidates) {
				t.Helper()
				assertForcedChainsValid(t, steps, grid, cands)
				// Intersection: the common action is a downstream cell, not the seed
				// itself. Verify by checking that no action places a digit that matches
				// a branch candidate (a contradiction would place the seed candidate).
				for _, s := range steps {
					seedCands := make(map[int]bool)
					for _, ch := range s.Chains {
						seedCands[ch.Candidate] = true
					}
					for _, a := range s.Actions {
						if a.Type == ActionSet && seedCands[a.Digit] {
							t.Errorf("Set(%d) at (%d,%d) matches a seed candidate — expected intersection, not contradiction", a.Digit, a.Row, a.Col)
						}
					}
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := fc(tt.grid, cands)

			if tt.wantNil {
				if steps != nil {
					t.Errorf("ForcedChains() = %v, want nil", steps)
				}
				return
			}
			if len(steps) == 0 {
				t.Fatal("ForcedChains() returned nil, want at least one step")
			}
			for _, s := range steps {
				if s.Technique != TechniqueForcedChains {
					t.Errorf("unexpected technique %q, want %q", s.Technique, TechniqueForcedChains)
				}
				if len(s.Actions) == 0 {
					t.Error("step has no actions")
				}
				if len(s.Chains) < 2 {
					t.Errorf("step has %d chains, want at least 2", len(s.Chains))
				}
			}
			if tt.check != nil {
				tt.check(t, steps, tt.grid, cands)
			}
		})
	}
}

// assertForcedChainsValid checks that every action targets an empty cell and that
// each chain branch records the candidate it assumed.
func assertForcedChainsValid(t *testing.T, steps []SolveStep, g Grid, cands Candidates) {
	t.Helper()
	for _, s := range steps {
		for _, a := range s.Actions {
			if g[a.Row][a.Col] != 0 {
				t.Errorf("action targets already-filled cell (%d,%d)", a.Row, a.Col)
			}
			if a.Type == ActionEliminate {
				bit := uint16(1) << uint(a.Digit-1)
				if cands[a.Row][a.Col]&bit == 0 {
					t.Errorf("elimination of digit %d from (%d,%d): not a candidate", a.Digit, a.Row, a.Col)
				}
			}
		}
		for _, ch := range s.Chains {
			if ch.Candidate < 1 || ch.Candidate > 9 {
				t.Errorf("chain has invalid candidate %d", ch.Candidate)
			}
		}
	}
}

func TestFcHasContradiction(t *testing.T) {
	tests := []struct {
		name string
		g    Grid
		cands func(Grid) Candidates
		want bool
	}{
		{
			name:  "solved grid — no contradiction",
			g:     fixtureUniqueSolution(),
			cands: Init,
			want:  false,
		},
		{
			name:  "valid partial grid — no contradiction",
			g:     fixtureStandardPuzzle(),
			cands: Init,
			want:  false,
		},
		{
			name: "empty cell with zero candidates — contradiction",
			g:    fixtureStandardPuzzle(),
			cands: func(g Grid) Candidates {
				c := Init(g)
				for r := 0; r < 9; r++ {
					for col := 0; col < 9; col++ {
						if g[r][col] == 0 {
							c[r][col] = 0
							return c
						}
					}
				}
				return c
			},
			want: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := tt.cands(tt.g)
			if got := fcHasContradiction(tt.g, cands); got != tt.want {
				t.Errorf("fcHasContradiction() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestFcIntersectActions(t *testing.T) {
	act := func(r, c, d int, tp ActionType) CellAction {
		return CellAction{Row: r, Col: c, Digit: d, Type: tp}
	}

	tests := []struct {
		name     string
		branches []*fcBranch
		wantLen  int
		wantActs []CellAction
	}{
		{
			name:     "single branch — all actions returned",
			branches: []*fcBranch{{allActions: []CellAction{act(0, 0, 1, ActionSet), act(1, 1, 2, ActionEliminate)}}},
			wantLen:  2,
		},
		{
			name: "two branches with one common action",
			branches: []*fcBranch{
				{allActions: []CellAction{act(0, 0, 1, ActionSet), act(3, 4, 5, ActionSet)}},
				{allActions: []CellAction{act(1, 1, 2, ActionEliminate), act(3, 4, 5, ActionSet)}},
			},
			wantLen:  1,
			wantActs: []CellAction{act(3, 4, 5, ActionSet)},
		},
		{
			name: "two branches with no common action",
			branches: []*fcBranch{
				{allActions: []CellAction{act(0, 0, 1, ActionSet)}},
				{allActions: []CellAction{act(1, 1, 2, ActionEliminate)}},
			},
			wantLen: 0,
		},
		{
			name: "duplicate action within a branch — not duplicated in output",
			branches: []*fcBranch{
				{allActions: []CellAction{act(3, 4, 5, ActionSet), act(3, 4, 5, ActionSet)}},
				{allActions: []CellAction{act(3, 4, 5, ActionSet)}},
			},
			wantLen:  1,
			wantActs: []CellAction{act(3, 4, 5, ActionSet)},
		},
		{
			name: "three branches — action in all three included, action in two excluded",
			branches: []*fcBranch{
				{allActions: []CellAction{act(5, 5, 7, ActionEliminate), act(0, 0, 1, ActionSet)}},
				{allActions: []CellAction{act(5, 5, 7, ActionEliminate), act(0, 0, 1, ActionSet)}},
				{allActions: []CellAction{act(5, 5, 7, ActionEliminate)}},
			},
			wantLen:  1,
			wantActs: []CellAction{act(5, 5, 7, ActionEliminate)},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := fcIntersectActions(tt.branches)
			if len(got) != tt.wantLen {
				t.Fatalf("fcIntersectActions() returned %d actions, want %d: %v", len(got), tt.wantLen, got)
			}
			for i, want := range tt.wantActs {
				if got[i] != want {
					t.Errorf("action[%d] = %v, want %v", i, got[i], want)
				}
			}
		})
	}
}
