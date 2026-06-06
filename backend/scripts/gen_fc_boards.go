//go:build ignore

// gen_fc_boards generates the forcedChains tutorial JSON with 5 sub-variant
// groups (one per chain-type × seed-type combination). Each group has 1 explain
// board (curated) and 3 practice boards sourced from the grandmaster corpus.
//
// Output format:
//
//	{
//	  "technique": "forcedChains",
//	  "sub_variants": [
//	    { "id": "contradiction_biLocation", "explain": {...}, "practice": [{...}, ...] },
//	    ...
//	  ]
//	}
//
// Usage (from the backend/ directory):
//
//	go run ./scripts/gen_fc_boards.go [-corpus <dir>] [-out <dir>]
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

// ── JSON output types ─────────────────────────────────────────────────────────

type lessonBoard struct {
	InitialGrid [9][9]int   `json:"initial_grid"`
	CurrentGrid [9][9]int   `json:"current_grid"`
	Notes       [9][9][]int `json:"notes"`
	Step        *stepJSON   `json:"step,omitempty"`
}

type stepJSON struct {
	Technique string            `json:"technique"`
	Sources   []sourceJSON      `json:"sources"`
	Actions   []actionJSON      `json:"actions"`
	Chains    []chainBranchJSON `json:"chains,omitempty"`
	ChainType string            `json:"chain_type,omitempty"`
	SeedType  string            `json:"seed_type,omitempty"`
}

type chainBranchJSON struct {
	Candidate int        `json:"candidate"`
	Steps     []stepJSON `json:"steps"`
}

type sourceJSON struct {
	Row    int   `json:"row"`
	Col    int   `json:"col"`
	Digits []int `json:"digits"`
}

type actionJSON struct {
	Row   int    `json:"row"`
	Col   int    `json:"col"`
	Digit int    `json:"digit"`
	Type  string `json:"type"`
}

type subVariantGroup struct {
	ID       string        `json:"id"`
	Explain  lessonBoard   `json:"explain"`
	Practice []lessonBoard `json:"practice"`
}

type techniqueFile struct {
	Technique   string            `json:"technique"`
	SubVariants []subVariantGroup `json:"sub_variants"`
}

// ── Corpus type ───────────────────────────────────────────────────────────────

type corpusEntry struct {
	ID   string    `json:"id"`
	Grid [9][9]int `json:"grid"`
}

// ── Curated explain grids (one per sub-variant) ───────────────────────────────

// explainGrids lists the hand-picked grids for each sub-variant's explain board,
// in the same order as subVariantOrder.
var explainGrids = map[string][9][9]int{
	"contradiction_biLocation": {
		{0, 0, 0, 0, 0, 0, 3, 4, 0},
		{0, 1, 0, 0, 4, 5, 0, 0, 0},
		{0, 9, 0, 0, 8, 0, 0, 0, 0},
		{8, 6, 0, 0, 9, 0, 0, 0, 0},
		{7, 3, 0, 0, 0, 0, 0, 1, 4},
		{0, 0, 0, 0, 0, 4, 0, 2, 0},
		{2, 4, 0, 0, 3, 0, 0, 0, 6},
		{0, 0, 0, 9, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 7},
	},
	"mutualInclusion_biLocation": {
		{0, 0, 0, 0, 2, 7, 0, 0, 3},
		{0, 0, 7, 0, 0, 4, 0, 0, 0},
		{6, 0, 0, 0, 0, 8, 9, 2, 0},
		{0, 0, 4, 0, 0, 0, 0, 0, 0},
		{0, 6, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 1, 6, 7, 0, 0, 3, 0},
		{9, 0, 0, 0, 0, 0, 1, 6, 0},
		{1, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 3, 0, 5, 0, 7, 0},
	},
	"mutualElimination_biLocation": {
		{0, 3, 0, 0, 2, 0, 0, 0, 0},
		{9, 5, 0, 1, 0, 0, 0, 0, 2},
		{0, 0, 0, 0, 8, 0, 9, 0, 0},
		{0, 0, 7, 0, 3, 0, 4, 0, 5},
		{0, 0, 0, 0, 4, 5, 2, 0, 8},
		{0, 0, 0, 2, 0, 0, 0, 0, 0},
		{2, 0, 0, 0, 0, 0, 0, 1, 0},
		{0, 4, 1, 0, 0, 8, 0, 0, 0},
		{0, 0, 9, 3, 0, 0, 5, 0, 0},
	},
	"contradiction_triValue": {
		{6, 0, 0, 0, 3, 0, 1, 0, 0},
		{0, 0, 0, 0, 2, 6, 0, 8, 7},
		{9, 0, 0, 4, 1, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 7, 0, 3},
		{0, 0, 5, 0, 0, 3, 0, 2, 4},
		{2, 0, 4, 0, 6, 0, 0, 0, 0},
		{0, 0, 6, 5, 0, 0, 0, 0, 0},
		{0, 3, 0, 0, 0, 8, 0, 5, 2},
	},
	"contradiction_biValue": {
		{0, 6, 9, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 6, 0, 0, 0, 0, 0},
		{2, 0, 0, 0, 0, 7, 0, 6, 0},
		{0, 0, 4, 1, 0, 2, 0, 8, 0},
		{0, 0, 0, 0, 0, 8, 0, 5, 0},
		{0, 7, 0, 0, 3, 0, 0, 0, 0},
		{7, 0, 8, 9, 0, 0, 0, 0, 6},
		{0, 0, 0, 0, 0, 0, 0, 0, 3},
		{0, 1, 0, 0, 0, 4, 0, 2, 7},
	},
}

var subVariantOrder = []string{
	"contradiction_biLocation",
	"contradiction_biValue",
	"contradiction_triValue",
	"mutualInclusion_biLocation",
	"mutualElimination_biLocation",
}

// ── Board capture ─────────────────────────────────────────────────────────────

// captureBoard steps through HumanSolve until the first forced chain step fires,
// returning the board state at that moment and the step's sub-variant id.
func captureBoard(grid [9][9]int) (lessonBoard, string, bool) {
	var g sudoku.Grid
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			g[r][c] = uint8(grid[r][c])
		}
	}
	cands := sudoku.Init(g)
	for {
		step, solved, stuck := sudoku.HumanSolveStep(g, cands)
		if solved || stuck {
			return lessonBoard{}, "", false
		}
		if step.Technique == sudoku.TechniqueForcedChains {
			sv := strings.TrimRight(step.ChainType+"_"+step.SeedType, "_")

			var notes [9][9][]int
			for r := 0; r < 9; r++ {
				for c := 0; c < 9; c++ {
					if g[r][c] != 0 {
						notes[r][c] = []int{}
					} else {
						mask := cands[r][c]
						for d := 1; d <= 9; d++ {
							if mask&(1<<uint(d-1)) != 0 {
								notes[r][c] = append(notes[r][c], d)
							}
						}
					}
				}
			}
			var cur [9][9]int
			for r := 0; r < 9; r++ {
				for c := 0; c < 9; c++ {
					cur[r][c] = int(g[r][c])
				}
			}
			return lessonBoard{
				InitialGrid: grid,
				CurrentGrid: cur,
				Notes:       notes,
				Step:        toStepJSON(step),
			}, sv, true
		}
		for _, a := range step.Actions {
			switch a.Type {
			case sudoku.ActionSet:
				g[a.Row][a.Col] = uint8(a.Digit)
				cands.Set(a.Row, a.Col, a.Digit)
			case sudoku.ActionEliminate:
				cands.Eliminate(a.Row, a.Col, a.Digit)
			}
		}
	}
}

func toStepJSON(s *sudoku.SolveStep) *stepJSON {
	sources := make([]sourceJSON, len(s.Sources))
	for i, src := range s.Sources {
		sources[i] = sourceJSON{Row: src.Row, Col: src.Col, Digits: src.Digits}
	}
	actions := make([]actionJSON, len(s.Actions))
	for i, a := range s.Actions {
		t := "set"
		if a.Type == sudoku.ActionEliminate {
			t = "eliminate"
		}
		actions[i] = actionJSON{Row: a.Row, Col: a.Col, Digit: a.Digit, Type: t}
	}
	sj := &stepJSON{
		Technique: s.Technique,
		Sources:   sources,
		Actions:   actions,
		ChainType: s.ChainType,
		SeedType:  s.SeedType,
	}
	for _, branch := range s.Chains {
		bj := chainBranchJSON{Candidate: branch.Candidate}
		for i := range branch.Steps {
			bj.Steps = append(bj.Steps, *toStepJSON(&branch.Steps[i]))
		}
		sj.Chains = append(sj.Chains, bj)
	}
	return sj
}

func gridKey(g [9][9]int) string {
	var sb strings.Builder
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			sb.WriteByte(byte(g[r][c]) + '0')
		}
	}
	return sb.String()
}

// ── Main ──────────────────────────────────────────────────────────────────────

func main() {
	corpusDir := flag.String("corpus", "../puzzle_corpus", "corpus directory")
	outDir    := flag.String("out", "../frontend/assets/tutorial", "output directory")
	nPractice := flag.Int("practice", 3, "practice boards per sub-variant")
	flag.Parse()

	// Build explain boards from curated grids.
	explains := make(map[string]lessonBoard)
	for sv, grid := range explainGrids {
		b, got, ok := captureBoard(grid)
		if !ok {
			log.Fatalf("curated grid for %s: no forced chain found", sv)
		}
		if got != sv {
			log.Fatalf("curated grid for %s: first FC step was %s instead", sv, got)
		}
		explains[sv] = b
		fmt.Printf("explain %-35s actions=%d\n", sv, len(b.Step.Actions))
	}

	// Track explain grid keys to exclude from practice.
	explainKeys := make(map[string]bool)
	for _, grid := range explainGrids {
		explainKeys[gridKey(grid)] = true
	}

	// Collect practice boards from corpus.
	practice := make(map[string][]lessonBoard)
	needed := func(sv string) bool { return len(practice[sv]) < *nPractice }
	allDone := func() bool {
		for _, sv := range subVariantOrder {
			if needed(sv) {
				return false
			}
		}
		return true
	}

	corpusPath := filepath.Join(*corpusDir, "grandmaster.json")
	data, err := os.ReadFile(corpusPath)
	if err != nil {
		log.Fatalf("read corpus: %v", err)
	}
	var entries []corpusEntry
	if err := json.Unmarshal(data, &entries); err != nil {
		log.Fatalf("parse corpus: %v", err)
	}

	for _, e := range entries {
		if allDone() {
			break
		}
		if explainKeys[gridKey(e.Grid)] {
			continue
		}
		b, sv, ok := captureBoard(e.Grid)
		if !ok || !needed(sv) {
			continue
		}
		practice[sv] = append(practice[sv], b)
	}

	// Report results.
	fmt.Println()
	for _, sv := range subVariantOrder {
		fmt.Printf("practice %-35s %d/%d boards\n", sv, len(practice[sv]), *nPractice)
	}

	// Build output.
	groups := make([]subVariantGroup, 0, len(subVariantOrder))
	for _, sv := range subVariantOrder {
		groups = append(groups, subVariantGroup{
			ID:       sv,
			Explain:  explains[sv],
			Practice: practice[sv],
		})
	}

	out := techniqueFile{
		Technique:   "forcedChains",
		SubVariants: groups,
	}
	outData, err := json.MarshalIndent(out, "", "  ")
	if err != nil {
		log.Fatalf("marshal: %v", err)
	}
	reNum := regexp.MustCompile(`\[\s*(-?\d+(?:,\s*-?\d+)*)\s*\]`)
	compact := reNum.ReplaceAllFunc(outData, func(match []byte) []byte {
		nums := regexp.MustCompile(`-?\d+`).FindAll(match, -1)
		b := []byte{'['}
		for i, n := range nums {
			if i > 0 {
				b = append(b, ',')
			}
			b = append(b, n...)
		}
		return append(b, ']')
	})
	reRow := regexp.MustCompile(`\[\s*(\[[\d,]*\](?:,\s*\[[\d,]*\])*)\s*\]`)
	compact = reRow.ReplaceAllFunc(compact, func(match []byte) []byte {
		cells := regexp.MustCompile(`\[[\d,]*\]`).FindAll(match, -1)
		b := []byte{'['}
		for i, cell := range cells {
			if i > 0 {
				b = append(b, ',')
			}
			b = append(b, cell...)
		}
		return append(b, ']')
	})
	outPath := filepath.Join(*outDir, "forcedChains.json")
	if err := os.WriteFile(outPath, append(compact, '\n'), 0o644); err != nil {
		log.Fatalf("write: %v", err)
	}
	fmt.Printf("\nwrote %s\n", outPath)
}
