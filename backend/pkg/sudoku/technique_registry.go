package sudoku

import (
	"fmt"
	"sort"
)

// techniqueDefinition pairs a technique name with its human difficulty level.
// The order of entries in techniqueDefinitions is the single source of truth
// for technique complexity — simpler techniques appear first.
type techniqueDefinition struct {
	name  string
	level string // one of the Difficulty constants
}

var techniqueDefinitions = []techniqueDefinition{
	{TechniqueNakedSingles, DifficultyEasy},
	{TechniqueHiddenSingles, DifficultyEasy},
	{TechniqueLockedCandidates, DifficultyMedium},
	{TechniqueNakedPairs, DifficultyMedium},
	{TechniqueHiddenPairs, DifficultyHard},
	{TechniqueNakedTriples, DifficultyHard},
	{TechniqueHiddenTriples, DifficultyExpert},
	{TechniqueNakedQuadruples, DifficultyExpert},
	{TechniqueHiddenQuadruples, DifficultyExpert},
	{TechniqueXWing, DifficultyExpert},
	{TechniqueSwordfish, DifficultyMaster},
	{TechniqueXYWing, DifficultyMaster},
	{TechniqueXYZWing, DifficultyMaster},
	{TechniqueForcedChains, DifficultyGrandmaster},
}

// TechniqueRegistry is a view over the ordered technique list, optionally
// capped at a maximum technique. All methods operate on the capped view.
type TechniqueRegistry struct {
	defs  []techniqueDefinition
	index map[string]int // name → position within defs
}

// NewTechniqueRegistry returns a registry over all known techniques.
// Pass a technique name as max to cap the view at that technique (inclusive);
// the registry will contain only techniques up to and including max.
// Returns an error if max is provided but not a known technique name.
func NewTechniqueRegistry(max ...string) (*TechniqueRegistry, error) {
	defs := techniqueDefinitions
	if len(max) > 0 && max[0] != "" {
		found := false
		for i, d := range techniqueDefinitions {
			if d.name == max[0] {
				defs = techniqueDefinitions[:i+1]
				found = true
				break
			}
		}
		if !found {
			return nil, fmt.Errorf("unknown technique %q", max[0])
		}
	}
	idx := make(map[string]int, len(defs))
	for i, d := range defs {
		idx[d.name] = i
	}
	return &TechniqueRegistry{defs: defs, index: idx}, nil
}

// Names returns the technique names in complexity order (simplest first).
func (r *TechniqueRegistry) Names() []string {
	names := make([]string, len(r.defs))
	for i, d := range r.defs {
		names[i] = d.name
	}
	return names
}

// Sort deduplicates techniques and returns them sorted by complexity
// (simplest first). Techniques not in the registry are placed at the end.
func (r *TechniqueRegistry) Sort(techniques []string) []string {
	seen := make(map[string]bool, len(techniques))
	unique := make([]string, 0, len(techniques))
	for _, t := range techniques {
		if !seen[t] {
			seen[t] = true
			unique = append(unique, t)
		}
	}
	sort.SliceStable(unique, func(i, j int) bool {
		ri, oki := r.index[unique[i]]
		rj, okj := r.index[unique[j]]
		if !oki {
			ri = len(r.defs)
		}
		if !okj {
			rj = len(r.defs)
		}
		return ri < rj
	})
	return unique
}

// Decisive returns the most complex technique in the list.
// Returns "" if the list is empty.
func (r *TechniqueRegistry) Decisive(techniques []string) string {
	sorted := r.Sort(techniques)
	if len(sorted) == 0 {
		return ""
	}
	return sorted[len(sorted)-1]
}

// Level returns the human difficulty level for the hardest technique in the
// list. Returns DifficultyEasy for an empty list. Techniques not present in
// the registry are ignored when determining the level.
func (r *TechniqueRegistry) Level(techniques []string) string {
	maxIdx := -1
	for _, t := range techniques {
		if i, ok := r.index[t]; ok && i > maxIdx {
			maxIdx = i
		}
	}
	if maxIdx < 0 {
		return DifficultyEasy
	}
	return r.defs[maxIdx].level
}
