package sudoku

import (
	"reflect"
	"testing"
)

// mustRegistry wraps NewTechniqueRegistry and fails the test on error.
func mustRegistry(t *testing.T, max ...string) *TechniqueRegistry {
	t.Helper()
	r, err := NewTechniqueRegistry(max...)
	if err != nil {
		t.Fatalf("NewTechniqueRegistry(%v): %v", max, err)
	}
	return r
}

func TestNewTechniqueRegistry(t *testing.T) {
	allTechniques := []string{
		TechniqueNakedSingles,
		TechniqueHiddenSingles,
		TechniqueLockedCandidates,
		TechniqueNakedPairs,
		TechniqueHiddenPairs,
		TechniqueNakedTriples,
		TechniqueHiddenTriples,
		TechniqueNakedQuadruples,
		TechniqueHiddenQuadruples,
		TechniqueXWing,
		TechniqueSwordfish,
		TechniqueXYWing,
		TechniqueXYZWing,
		TechniqueForcedChains,
	}

	tests := []struct {
		name      string
		max       string
		wantNames []string
		wantErr   bool
	}{
		{
			name:      "no max returns all techniques in order",
			wantNames: allTechniques,
		},
		{
			name:      "capped at middle technique",
			max:       TechniqueNakedPairs,
			wantNames: allTechniques[:4],
		},
		{
			name:      "capped at first technique",
			max:       TechniqueNakedSingles,
			wantNames: allTechniques[:1],
		},
		{
			name:      "capped at last technique equals full registry",
			max:       TechniqueForcedChains,
			wantNames: allTechniques,
		},
		{
			name:    "unknown max returns error",
			max:     "notATechnique",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var r *TechniqueRegistry
			var err error
			if tt.max == "" {
				r, err = NewTechniqueRegistry()
			} else {
				r, err = NewTechniqueRegistry(tt.max)
			}

			if tt.wantErr {
				if err == nil {
					t.Error("expected error, got nil")
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got := r.Names(); !reflect.DeepEqual(got, tt.wantNames) {
				t.Errorf("Names() = %v, want %v", got, tt.wantNames)
			}
		})
	}
}

func TestTechniqueRegistry_Sort(t *testing.T) {
	r := mustRegistry(t)

	tests := []struct {
		name  string
		input []string
		want  []string
	}{
		{
			name:  "already in order",
			input: []string{TechniqueNakedSingles, TechniqueHiddenPairs, TechniqueForcedChains},
			want:  []string{TechniqueNakedSingles, TechniqueHiddenPairs, TechniqueForcedChains},
		},
		{
			name:  "reverse order",
			input: []string{TechniqueForcedChains, TechniqueNakedPairs, TechniqueNakedSingles},
			want:  []string{TechniqueNakedSingles, TechniqueNakedPairs, TechniqueForcedChains},
		},
		{
			name:  "deduplicates",
			input: []string{TechniqueHiddenSingles, TechniqueNakedSingles, TechniqueHiddenSingles},
			want:  []string{TechniqueNakedSingles, TechniqueHiddenSingles},
		},
		{
			name:  "unknown technique placed at end",
			input: []string{"unknownTech", TechniqueNakedSingles},
			want:  []string{TechniqueNakedSingles, "unknownTech"},
		},
		{
			name:  "empty input",
			input: []string{},
			want:  []string{},
		},
		{
			name:  "all techniques sorted correctly",
			input: []string{TechniqueXYZWing, TechniqueHiddenSingles, TechniqueXWing, TechniqueNakedSingles},
			want:  []string{TechniqueNakedSingles, TechniqueHiddenSingles, TechniqueXWing, TechniqueXYZWing},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := r.Sort(tt.input)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Sort(%v) = %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}

func TestTechniqueRegistry_Decisive(t *testing.T) {
	r := mustRegistry(t)

	tests := []struct {
		name       string
		techniques []string
		want       string
	}{
		{
			name:       "single technique",
			techniques: []string{TechniqueNakedSingles},
			want:       TechniqueNakedSingles,
		},
		{
			name:       "picks hardest regardless of input order",
			techniques: []string{TechniqueForcedChains, TechniqueNakedSingles, TechniqueXWing},
			want:       TechniqueForcedChains,
		},
		{
			name:       "picks hardest when input is simple-first",
			techniques: []string{TechniqueNakedSingles, TechniqueHiddenSingles, TechniqueNakedPairs},
			want:       TechniqueNakedPairs,
		},
		{
			name:       "xyzWing is harder than xyWing",
			techniques: []string{TechniqueXYWing, TechniqueXYZWing},
			want:       TechniqueXYZWing,
		},
		{
			name:       "empty returns empty string",
			techniques: []string{},
			want:       "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := r.Decisive(tt.techniques)
			if got != tt.want {
				t.Errorf("Decisive(%v) = %q, want %q", tt.techniques, got, tt.want)
			}
		})
	}
}

func TestTechniqueRegistry_Level(t *testing.T) {
	r := mustRegistry(t)

	tests := []struct {
		name       string
		techniques []string
		want       string
	}{
		{
			name:       "empty returns easy",
			techniques: []string{},
			want:       DifficultyEasy,
		},
		{
			name:       "only naked singles → easy",
			techniques: []string{TechniqueNakedSingles},
			want:       DifficultyEasy,
		},
		{
			name:       "hidden singles → easy",
			techniques: []string{TechniqueNakedSingles, TechniqueHiddenSingles},
			want:       DifficultyEasy,
		},
		{
			name:       "locked candidates → medium",
			techniques: []string{TechniqueNakedSingles, TechniqueLockedCandidates},
			want:       DifficultyMedium,
		},
		{
			name:       "naked pairs → medium",
			techniques: []string{TechniqueNakedSingles, TechniqueNakedPairs},
			want:       DifficultyMedium,
		},
		{
			name:       "hidden pairs → hard",
			techniques: []string{TechniqueNakedSingles, TechniqueHiddenPairs},
			want:       DifficultyHard,
		},
		{
			name:       "naked triples → hard",
			techniques: []string{TechniqueNakedSingles, TechniqueNakedTriples},
			want:       DifficultyHard,
		},
		{
			name:       "hidden triples → expert",
			techniques: []string{TechniqueNakedSingles, TechniqueHiddenTriples},
			want:       DifficultyExpert,
		},
		{
			name:       "x-wing → expert",
			techniques: []string{TechniqueNakedSingles, TechniqueXWing},
			want:       DifficultyExpert,
		},
		{
			name:       "swordfish → master",
			techniques: []string{TechniqueNakedSingles, TechniqueSwordfish},
			want:       DifficultyMaster,
		},
		{
			name:       "xy-wing → master",
			techniques: []string{TechniqueNakedSingles, TechniqueXYWing},
			want:       DifficultyMaster,
		},
		{
			name:       "xyz-wing → master",
			techniques: []string{TechniqueNakedSingles, TechniqueXYZWing},
			want:       DifficultyMaster,
		},
		{
			name:       "forced chains → grandmaster",
			techniques: []string{TechniqueNakedSingles, TechniqueForcedChains},
			want:       DifficultyGrandmaster,
		},
		{
			name:       "hardest of mixed set wins",
			techniques: []string{TechniqueNakedSingles, TechniqueXWing, TechniqueSwordfish},
			want:       DifficultyMaster,
		},
		{
			name:       "unknown technique ignored for level",
			techniques: []string{TechniqueNakedSingles, "unknownTech"},
			want:       DifficultyEasy,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := r.Level(tt.techniques)
			if got != tt.want {
				t.Errorf("Level(%v) = %q, want %q", tt.techniques, got, tt.want)
			}
		})
	}
}

func TestTechniqueRegistry_cappedDecisive(t *testing.T) {
	r := mustRegistry(t, TechniqueNakedPairs)

	// forcedChains is beyond the cap — treated as unknown, placed after nakedPairs
	got := r.Decisive([]string{TechniqueForcedChains, TechniqueNakedPairs})
	if got != TechniqueForcedChains {
		t.Errorf("Decisive beyond cap = %q, want %q (unknown techniques sort last)", got, TechniqueForcedChains)
	}
}

func TestTechniqueRegistry_cappedLevel(t *testing.T) {
	r := mustRegistry(t, TechniqueNakedPairs)

	// forcedChains is not in the capped registry — ignored for level
	got := r.Level([]string{TechniqueNakedSingles, TechniqueForcedChains})
	if got != DifficultyEasy {
		t.Errorf("Level with out-of-cap technique = %q, want %q", got, DifficultyEasy)
	}
}
