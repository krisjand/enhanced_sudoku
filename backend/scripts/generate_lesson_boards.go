//go:build ignore

// generate_lesson_boards extracts board states from the puzzle corpus for use
// in the Flutter tutorial.
//
// For each technique it reads puzzles where that technique is decisive, then
// steps through HumanSolve until the technique first fires, capturing the exact
// grid, notes, and SolveStep at that moment.
//
// Sub-variant collection: for techniques with row/column/box variants the
// collector prioritises gathering at least one board per variant before filling
// the remaining slots with any variant.
//
// Output: one JSON file per technique in ../frontend/assets/tutorial/
//
// Usage (from the backend/ directory):
//
//	go run ./scripts/generate_lesson_boards.go [-out <dir>]
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
	SubVariant  string      `json:"sub_variant,omitempty"`
	AllSteps    []stepJSON  `json:"all_steps,omitempty"`
}

type stepJSON struct {
	Technique string           `json:"technique"`
	Sources   []sourceJSON     `json:"sources"`
	Actions   []actionJSON     `json:"actions"`
	Chains    []chainBranchJSON `json:"chains,omitempty"`
	ChainType string           `json:"chain_type,omitempty"`
	SeedType  string           `json:"seed_type,omitempty"`
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

type techniqueFile struct {
	Technique string        `json:"technique"`
	Explain   lessonBoard   `json:"explain"`
	Practice  []lessonBoard `json:"practice"`
}

type notesFile struct {
	Practice lessonBoard `json:"practice"`
}

// ── Corpus types ──────────────────────────────────────────────────────────────

type corpusEntry struct {
	ID       string    `json:"id"`
	Grid     [9][9]int `json:"grid"`
	Decisive string    `json:"decisive"`
}

// ── Sub-variant definitions ───────────────────────────────────────────────────

// subVariants maps each top-level technique to its sub-level step identifiers.
// Techniques not listed here have no sub-variants.
var subVariants = map[string][]string{
	"hiddenSingles":    {"hiddenSingleRow", "hiddenSingleColumn", "hiddenSingleBox"},
	"lockedCandidates": {"lockedCandidatesPointingRow", "lockedCandidatesPointingColumn", "lockedCandidatesReductionRow", "lockedCandidatesReductionColumn"},
	"nakedPairs":       {"nakedPairRow", "nakedPairColumn", "nakedPairBox"},
	"hiddenPairs":      {"hiddenPairRow", "hiddenPairColumn", "hiddenPairBox"},
	"nakedTriples":     {"nakedTripleRow", "nakedTripleColumn", "nakedTripleBox"},
	"hiddenTriples":    {"hiddenTripleRow", "hiddenTripleColumn", "hiddenTripleBox"},
	"nakedQuadruples":  {"nakedQuadruplesRow", "nakedQuadruplesColumn", "nakedQuadruplesBox"},
	"hiddenQuadruples": {"hiddenQuadruplesRow", "hiddenQuadruplesColumn", "hiddenQuadruplesBox"},
	"xWing":            {"xWingRow", "xWingColumn"},
	"swordfish":        {"swordfishRow", "swordfishColumn"},
}

// stepToTopLevel maps a sub-level step technique to its top-level name.
var stepToTopLevel map[string]string

func init() {
	stepToTopLevel = make(map[string]string)
	for top, subs := range subVariants {
		for _, sub := range subs {
			stepToTopLevel[sub] = top
		}
	}
	// Techniques with no sub-variants map to themselves.
	for _, t := range sudoku.KnownTechniques() {
		if _, ok := subVariants[t]; !ok {
			stepToTopLevel[t] = t
		}
	}
}

// ── Curriculum ────────────────────────────────────────────────────────────────

var curriculum = []struct {
	technique  string
	corpusFile string
	nPractice  int
}{
	{"nakedSingles", "../puzzle_corpus/easy.json", 5},
	{"hiddenSingles", "../puzzle_corpus/easy.json", 5},
	{"lockedCandidates", "../puzzle_corpus/medium.json", 7},
	{"nakedPairs", "../puzzle_corpus/medium.json", 5},
	{"hiddenPairs", "../puzzle_corpus/hard.json", 5},
	{"nakedTriples", "../puzzle_corpus/hard.json", 5},
	{"hiddenTriples", "../puzzle_corpus/expert.json", 5},
	{"nakedQuadruples", "../puzzle_corpus/expert.json", 5},
	{"hiddenQuadruples", "../puzzle_corpus/expert.json", 5},
	{"xWing", "../puzzle_corpus/expert.json", 5},
	{"swordfish", "../puzzle_corpus/master.json", 5},
	{"xyWing", "../puzzle_corpus/master.json", 5},
	{"xyzWing", "../puzzle_corpus/master.json", 5},
	{"forcedChains", "../puzzle_corpus/grandmaster.json", 5},
}

// ── Main ──────────────────────────────────────────────────────────────────────

func main() {
	outDir := flag.String("out", "../frontend/assets/tutorial", "output directory")
	flag.Parse()

	if err := os.MkdirAll(*outDir, 0o755); err != nil {
		log.Fatalf("mkdir: %v", err)
	}

	for _, c := range curriculum {
		path := filepath.Join(*outDir, c.technique+".json")
		if exists(path) {
			fmt.Printf("%-28s skip (already exists)\n", c.technique)
			continue
		}
		fmt.Printf("%-28s collecting from %s …\n", c.technique, c.corpusFile)
		entries := loadCorpus(c.corpusFile)
		boards := collect(entries, c.technique, 1+c.nPractice)
		if len(boards) == 0 {
			fmt.Printf("%-28s WARNING: no boards found — skipping\n", c.technique)
			continue
		}
		lf := techniqueFile{
			Technique: c.technique,
			Explain:   boards[0],
		}
		if len(boards) > 1 {
			lf.Practice = boards[1:]
		}
		writeJSON(path, lf)
		fmt.Printf("%-28s wrote %d board(s)\n", c.technique, len(boards))
	}

	generateNotesLesson(*outDir)
}

// ── Collection ────────────────────────────────────────────────────────────────

// collect returns up to max boards for technique, prioritising sub-variant
// variety: it fills slots for each sub-variant before repeating any variant.
func collect(entries []corpusEntry, technique string, max int) []lessonBoard {
	variants := subVariants[technique] // nil if no sub-variants
	seen := make(map[string]int)       // sub-variant → count already collected
	var boards []lessonBoard

	for _, e := range entries {
		if len(boards) >= max {
			break
		}
		if e.Decisive != technique {
			continue
		}
		board, ok := captureBoard(e.Grid, technique)
		if !ok {
			continue
		}
		sv := board.SubVariant
		// If variants are defined, prefer unrepresented ones.
		if len(variants) > 0 {
			minSeen := seen[sv]
			// Skip this board if its variant already has more than the least-seen variant.
			leastSeen := minCount(seen, variants)
			if minSeen > leastSeen {
				continue
			}
		}
		seen[sv]++
		boards = append(boards, board)
	}

	// Second pass: top up to max without variant restrictions.
	if len(boards) < max {
		for _, e := range entries {
			if len(boards) >= max {
				break
			}
			if e.Decisive != technique {
				continue
			}
			board, ok := captureBoard(e.Grid, technique)
			if !ok {
				continue
			}
			// Avoid duplicates (same SubVariant and same InitialGrid).
			if !alreadyIn(boards, board) {
				boards = append(boards, board)
			}
		}
	}

	return boards
}

// captureBoard steps through HumanSolve until a step belonging to technique
// fires, then records the board state at that moment.
func captureBoard(grid [9][9]int, technique string) (lessonBoard, bool) {
	g := toGrid(grid)
	cands := sudoku.Init(g)

	for {
		step, solved, stuck := sudoku.HumanSolveStep(g, cands)
		if solved || stuck {
			return lessonBoard{}, false
		}
		topLevel := stepToTopLevel[step.Technique]
		if topLevel == technique {
			board := lessonBoard{
				InitialGrid: grid,
				CurrentGrid: toIntGrid(g),
				Notes:       toNotes(cands, g),
				SubVariant:  step.Technique,
			}
			if technique == "lockedCandidates" {
				// Compute per-group steps so the tutorial can show one group at a
				// time and accept any valid group of the requested sub-type.
				all := lockedCandidatesEachGroup(cands)
				board.AllSteps = all
				// Use the first per-group step matching the sub-variant as the
				// display step — guaranteed to be a single-group step.
				for i := range all {
					if all[i].Technique == step.Technique {
						s := all[i]
						board.Step = &s
						break
					}
				}
			} else {
				board.Step = toStepJSON(step)
			}
			return board, true
		}
		// Apply and continue.
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

// lockedCandidatesEachGroup returns one stepJSON per individual locked-candidate
// group (one per box+digit for pointing; one per row/col+digit for reduction).
// This differs from sudoku.LockedCandidates which aggregates all groups of each
// sub-type into a single step.
func lockedCandidatesEachGroup(cands sudoku.Candidates) []stepJSON {
	var steps []stepJSON

	// Pointing rows: one step per (box, digit) group.
	for b := 0; b < 9; b++ {
		br, bc := (b/3)*3, (b%3)*3
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			row, count, confined := -1, 0, true
		ptRow:
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					if cands[br+dr][bc+dc]&bit != 0 {
						count++
						if row == -1 {
							row = br + dr
						} else if row != br+dr {
							confined = false
							break ptRow
						}
					}
				}
			}
			if !confined || count < 2 || row < 0 {
				continue
			}
			var actions []actionJSON
			for c := 0; c < 9; c++ {
				if c >= bc && c < bc+3 {
					continue
				}
				if cands[row][c]&bit != 0 {
					actions = append(actions, actionJSON{Row: row, Col: c, Digit: d, Type: "eliminate"})
				}
			}
			if len(actions) == 0 {
				continue
			}
			var sources []sourceJSON
			for dc := 0; dc < 3; dc++ {
				if cands[row][bc+dc]&bit != 0 {
					sources = append(sources, sourceJSON{Row: row, Col: bc + dc, Digits: []int{d}})
				}
			}
			steps = append(steps, stepJSON{Technique: "lockedCandidatesPointingRow", Sources: sources, Actions: actions})
		}
	}

	// Pointing cols: one step per (box, digit) group.
	for b := 0; b < 9; b++ {
		br, bc := (b/3)*3, (b%3)*3
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			col, count, confined := -1, 0, true
		ptCol:
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					if cands[br+dr][bc+dc]&bit != 0 {
						count++
						if col == -1 {
							col = bc + dc
						} else if col != bc+dc {
							confined = false
							break ptCol
						}
					}
				}
			}
			if !confined || count < 2 || col < 0 {
				continue
			}
			var actions []actionJSON
			for r := 0; r < 9; r++ {
				if r >= br && r < br+3 {
					continue
				}
				if cands[r][col]&bit != 0 {
					actions = append(actions, actionJSON{Row: r, Col: col, Digit: d, Type: "eliminate"})
				}
			}
			if len(actions) == 0 {
				continue
			}
			var sources []sourceJSON
			for dr := 0; dr < 3; dr++ {
				if cands[br+dr][col]&bit != 0 {
					sources = append(sources, sourceJSON{Row: br + dr, Col: col, Digits: []int{d}})
				}
			}
			steps = append(steps, stepJSON{Technique: "lockedCandidatesPointingColumn", Sources: sources, Actions: actions})
		}
	}

	// Reduction rows: one step per (row, digit) group.
	for r := 0; r < 9; r++ {
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			boxIdx, count, confined := -1, 0, true
			for c := 0; c < 9; c++ {
				if cands[r][c]&bit != 0 {
					count++
					b := (r/3)*3 + c/3
					if boxIdx == -1 {
						boxIdx = b
					} else if boxIdx != b {
						confined = false
						break
					}
				}
			}
			if !confined || count < 2 || boxIdx < 0 {
				continue
			}
			br, bc := (boxIdx/3)*3, (boxIdx%3)*3
			var actions []actionJSON
			for dr := 0; dr < 3; dr++ {
				if br+dr == r {
					continue
				}
				for dc := 0; dc < 3; dc++ {
					cr, cc := br+dr, bc+dc
					if cands[cr][cc]&bit != 0 {
						actions = append(actions, actionJSON{Row: cr, Col: cc, Digit: d, Type: "eliminate"})
					}
				}
			}
			if len(actions) == 0 {
				continue
			}
			var sources []sourceJSON
			for c := 0; c < 9; c++ {
				if cands[r][c]&bit != 0 {
					sources = append(sources, sourceJSON{Row: r, Col: c, Digits: []int{d}})
				}
			}
			steps = append(steps, stepJSON{Technique: "lockedCandidatesReductionRow", Sources: sources, Actions: actions})
		}
	}

	// Reduction cols: one step per (col, digit) group.
	for c := 0; c < 9; c++ {
		for d := 1; d <= 9; d++ {
			bit := uint16(1) << uint(d-1)
			boxIdx, count, confined := -1, 0, true
			for r := 0; r < 9; r++ {
				if cands[r][c]&bit != 0 {
					count++
					b := (r/3)*3 + c/3
					if boxIdx == -1 {
						boxIdx = b
					} else if boxIdx != b {
						confined = false
						break
					}
				}
			}
			if !confined || count < 2 || boxIdx < 0 {
				continue
			}
			br, bc := (boxIdx/3)*3, (boxIdx%3)*3
			var actions []actionJSON
			for dr := 0; dr < 3; dr++ {
				for dc := 0; dc < 3; dc++ {
					cr, cc := br+dr, bc+dc
					if cc == c {
						continue
					}
					if cands[cr][cc]&bit != 0 {
						actions = append(actions, actionJSON{Row: cr, Col: cc, Digit: d, Type: "eliminate"})
					}
				}
			}
			if len(actions) == 0 {
				continue
			}
			var sources []sourceJSON
			for r := 0; r < 9; r++ {
				if cands[r][c]&bit != 0 {
					sources = append(sources, sourceJSON{Row: r, Col: c, Digits: []int{d}})
				}
			}
			steps = append(steps, stepJSON{Technique: "lockedCandidatesReductionColumn", Sources: sources, Actions: actions})
		}
	}

	return steps
}

// ── Notes lesson ──────────────────────────────────────────────────────────────

func generateNotesLesson(outDir string) {
	path := filepath.Join(outDir, "notes.json")
	if exists(path) {
		fmt.Printf("%-28s skip (already exists)\n", "notes")
		return
	}
	entries := loadCorpus("../puzzle_corpus/easy.json")
	if len(entries) == 0 {
		log.Fatal("easy corpus is empty")
	}
	e := entries[0]
	g := toGrid(e.Grid)
	cands := sudoku.Init(g)
	board := lessonBoard{
		InitialGrid: e.Grid,
		CurrentGrid: e.Grid,
		Notes:       toNotes(cands, g),
	}
	writeJSON(path, notesFile{Practice: board})
	fmt.Printf("%-28s wrote %s\n", "notes", path)
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func loadCorpus(path string) []corpusEntry {
	data, err := os.ReadFile(path)
	if err != nil {
		log.Fatalf("read %s: %v", path, err)
	}
	var out []corpusEntry
	if err := json.Unmarshal(data, &out); err != nil {
		log.Fatalf("parse %s: %v", path, err)
	}
	return out
}

func writeJSON(path string, v any) {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		log.Fatalf("marshal: %v", err)
	}
	// Collapse any [[n,n,...],[n,n,...],...] patterns to one row per line.
	compact := collapseNumberArrays(data)
	if err := os.WriteFile(path, append(compact, '\n'), 0o644); err != nil {
		log.Fatalf("write %s: %v", path, err)
	}
}

// collapseNumberArrays reformats JSON so grids and notes are readable:
// pass 1 collapses [n,n,...] onto one line;
// pass 2 collapses [[n,...],[n,...],...] (notes rows) onto one line.
func collapseNumberArrays(data []byte) []byte {
	reNum := regexp.MustCompile(`\[\s*(-?\d+(?:,\s*-?\d+)*)\s*\]`)
	collapse := func(match []byte) []byte {
		nums := regexp.MustCompile(`-?\d+`).FindAll(match, -1)
		out := []byte{'['}
		for i, n := range nums {
			if i > 0 {
				out = append(out, ',')
			}
			out = append(out, n...)
		}
		return append(out, ']')
	}
	// Pass 1: [n,n,...] → [n,n,...]
	result := reNum.ReplaceAllFunc(data, collapse)
	// Pass 2: [[n,...],[n,...],...] → [[n,...],[n,...],...]  (notes rows)
	reRow := regexp.MustCompile(`\[\s*(\[[\d,]*\](?:,\s*\[[\d,]*\])*)\s*\]`)
	result = reRow.ReplaceAllFunc(result, func(match []byte) []byte {
		inner := regexp.MustCompile(`\[[\d,]*\]`).FindAll(match, -1)
		out := []byte{'['}
		for i, cell := range inner {
			if i > 0 {
				out = append(out, ',')
			}
			out = append(out, cell...)
		}
		return append(out, ']')
	})
	return result
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func toGrid(g [9][9]int) sudoku.Grid {
	var sg sudoku.Grid
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			sg[r][c] = uint8(g[r][c])
		}
	}
	return sg
}

func toIntGrid(g sudoku.Grid) [9][9]int {
	var out [9][9]int
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			out[r][c] = int(g[r][c])
		}
	}
	return out
}

func toNotes(cands sudoku.Candidates, g sudoku.Grid) [9][9][]int {
	var notes [9][9][]int
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 {
				notes[r][c] = []int{}
				continue
			}
			notes[r][c] = maskToDigits(cands[r][c])
		}
	}
	return notes
}

func maskToDigits(mask uint16) []int {
	var out []int
	for d := 1; d <= 9; d++ {
		if mask&(1<<uint(d-1)) != 0 {
			out = append(out, d)
		}
	}
	return out
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

func minCount(seen map[string]int, variants []string) int {
	min := -1
	for _, v := range variants {
		c := seen[v]
		if min < 0 || c < min {
			min = c
		}
	}
	if min < 0 {
		return 0
	}
	return min
}

func alreadyIn(boards []lessonBoard, b lessonBoard) bool {
	key := gridKey(b.InitialGrid)
	for _, existing := range boards {
		if gridKey(existing.InitialGrid) == key {
			return true
		}
	}
	return false
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
