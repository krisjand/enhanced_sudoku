package sudoku

import "testing"

// fixtureNearComplete returns the known solution with a handful of cells cleared.
// Each cleared cell is the only missing digit in its row+col+box, so they are
// all naked singles immediately after Init.
func fixtureNearComplete() (puzzle Grid, wantActions []CellAction) {
	g := fixtureUniqueSolution()
	clears := []struct {
		r, c  int
		digit int
	}{
		{0, 0, 5},
		{1, 1, 7},
		{2, 2, 8},
		{3, 3, 7},
		{4, 4, 5},
	}
	for _, cl := range clears {
		g[cl.r][cl.c] = 0
		wantActions = append(wantActions, CellAction{Row: cl.r, Col: cl.c, Digit: cl.digit, Type: ActionSet})
	}
	return g, wantActions
}

func TestNakedSingles(t *testing.T) {
	nearComplete, wantActions := fixtureNearComplete()

	tests := []struct {
		name        string
		grid        Grid
		wantActions []CellAction // nil means no step expected
	}{
		{
			name:        "near-complete puzzle returns all naked singles",
			grid:        nearComplete,
			wantActions: wantActions,
		},
		{
			name:        "empty grid has no naked singles",
			grid:        Grid{},
			wantActions: nil,
		},
		{
			name:        "solved grid has no naked singles",
			grid:        fixtureUniqueSolution(),
			wantActions: nil,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cands := Init(tt.grid)
			steps := NakedSingles(tt.grid, cands)

			if tt.wantActions == nil {
				if steps != nil {
					t.Errorf("NakedSingles() = %v, want nil", steps)
				}
				return
			}

			if len(steps) != 1 {
				t.Fatalf("len(steps) = %d, want 1", len(steps))
			}
			step := steps[0]
			if step.Technique != "Naked Singles" {
				t.Errorf("Technique = %q, want \"Naked Singles\"", step.Technique)
			}
			if len(step.Actions) != len(tt.wantActions) {
				t.Fatalf("len(Actions) = %d, want %d", len(step.Actions), len(tt.wantActions))
			}
			for i, want := range tt.wantActions {
				got := step.Actions[i]
				if got.Row != want.Row || got.Col != want.Col || got.Digit != want.Digit || got.Type != want.Type {
					t.Errorf("Actions[%d] = {%d,%d,d=%d,t=%d}, want {%d,%d,d=%d,t=%d}",
						i, got.Row, got.Col, got.Digit, got.Type,
						want.Row, want.Col, want.Digit, want.Type)
				}
			}
			if step.Duration <= 0 {
				t.Error("step.Duration should be > 0")
			}
		})
	}
}

func TestNakedSinglesSolvesCompletely(t *testing.T) {
	puzzle, _ := fixtureNearComplete()
	g := puzzle
	cands := Init(g)

	const maxPasses = 81
	for range maxPasses {
		steps := NakedSingles(g, cands)
		if steps == nil {
			break
		}
		for _, a := range steps[0].Actions {
			g[a.Row][a.Col] = uint8(a.Digit)
			cands.Set(a.Row, a.Col, a.Digit)
		}
	}

	if !g.IsSolved() {
		t.Error("puzzle not solved after applying naked singles to completion")
	}
}
