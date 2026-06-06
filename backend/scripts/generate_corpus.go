//go:build ignore

// generate_corpus produces pre-rated Sudoku puzzles and writes them to one
// compact JSON file per difficulty, for bundling with the Flutter app.
//
// Usage (from the backend/ directory):
//
//	go run ./scripts/generate_corpus.go [flags]
//
// Flags:
//
//	-out      Output directory (default: ../puzzle_corpus)
//	-seed     Random seed (default: current time)
//	-easy     Target count for easy puzzles (default: 3000)
//	-medium   Target count for medium puzzles (default: 3000)
//	-hard     Target count for hard puzzles (default: 3000)
//	-expert   Target count for expert puzzles (default: 3000)
//	-master   Target count for master puzzles (default: 3000)
//	-grand    Target count for grandmaster puzzles (default: 2000)
//	-legend   Cap for legendary puzzles (default: 200; opportunistic — does not block completion)
//
// The script is resumable: it reads existing output files on startup and only
// generates puzzles for targets not yet met. Duplicate puzzles are skipped via
// content-derived IDs.
package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

// puzzleRecord is one entry in the output JSON files.
type puzzleRecord struct {
	ID                   string         `json:"id"`
	Grid                 [9][9]int      `json:"grid"`
	Solution             [9][9]int      `json:"solution"`
	Techniques           []string       `json:"techniques"`
	Decisive             string         `json:"decisive,omitempty"`
	ForcedChainUses      int            `json:"forcedChainUses,omitempty"`
	ForcedChainMaxDepth  int            `json:"forcedChainMaxDepth,omitempty"`
	ForcedChainTypes     map[string]int `json:"forcedChainTypes,omitempty"`
	ForcedChainSeedTypes map[string]int `json:"forcedChainSeedTypes,omitempty"`
}


func puzzleID(g sudoku.Grid) string {
	h := sha256.New()
	for _, row := range g {
		h.Write(row[:])
	}
	b := h.Sum(nil)
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
		b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

func toInts(g sudoku.Grid) [9][9]int {
	var out [9][9]int
	for r, row := range g {
		for c, v := range row {
			out[r][c] = int(v)
		}
	}
	return out
}

// buildRecord analyses puzzle and returns its record and difficulty level.
// solution comes from Generate() so we never need to re-derive it.
// Exactly one HumanSolve call is made per puzzle.
func buildRecord(puzzle, solution sudoku.Grid, reg *sudoku.TechniqueRegistry) (puzzleRecord, string, bool) {
	result := sudoku.HumanSolve(puzzle)

	// Collect techniques that produced at least one step, in encounter order.
	seen := map[string]bool{}
	var used []string
	var fcUses, fcMaxDepth int
	var fcTypes, fcSeedTypes map[string]int
	for _, iter := range result.Iterations {
		for _, attempt := range iter {
			if len(attempt.Steps) == 0 {
				continue
			}
			if !seen[attempt.Technique] {
				seen[attempt.Technique] = true
				used = append(used, attempt.Technique)
			}
			if attempt.Technique != sudoku.TechniqueForcedChains {
				continue
			}
			fcUses++
			for _, step := range attempt.Steps {
				if step.ChainType != "" {
					if fcTypes == nil {
						fcTypes = map[string]int{}
					}
					fcTypes[step.ChainType]++
				}
				if step.SeedType != "" {
					if fcSeedTypes == nil {
						fcSeedTypes = map[string]int{}
					}
					fcSeedTypes[step.SeedType]++
				}
				for _, branch := range step.Chains {
					if d := len(branch.Steps); d > fcMaxDepth {
						fcMaxDepth = d
					}
				}
			}
		}
	}

	sorted := reg.Sort(used)
	decisive := reg.Decisive(sorted)
	level := reg.Level(sorted)
	if !result.Solved {
		level = sudoku.DifficultyLegendary
	}

	return puzzleRecord{
		ID:                   puzzleID(puzzle),
		Grid:                 toInts(puzzle),
		Solution:             toInts(solution),
		Techniques:           sorted,
		Decisive:             decisive,
		ForcedChainUses:      fcUses,
		ForcedChainMaxDepth:  fcMaxDepth,
		ForcedChainTypes:     fcTypes,
		ForcedChainSeedTypes: fcSeedTypes,
	}, level, true
}

// loadExisting reads a JSON file and returns the records and a set of IDs.
// If the file does not exist, empty results are returned silently.
// If the file exists but cannot be decoded, the error is logged and the
// program exits to avoid silently discarding previously generated puzzles.
func loadExisting(path string) ([]puzzleRecord, map[string]bool) {
	seen := map[string]bool{}
	f, err := os.Open(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, seen
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "error opening %s: %v\n", path, err)
		os.Exit(1)
	}
	defer f.Close()

	var records []puzzleRecord
	if err := json.NewDecoder(f).Decode(&records); err != nil {
		fmt.Fprintf(os.Stderr, "error decoding %s: %v\n  (delete or fix the file and retry)\n", path, err)
		os.Exit(1)
	}
	for _, r := range records {
		seen[r.ID] = true
	}
	return records, seen
}

// saveFile writes records as a compact JSON array — one puzzle per line.
// Uses atomic write (tmp file + rename) to protect against partial writes.
func saveFile(path string, records []puzzleRecord) error {
	var buf bytes.Buffer
	buf.WriteString("[\n")
	for i, r := range records {
		line, err := json.Marshal(r)
		if err != nil {
			return err
		}
		buf.WriteString("  ")
		buf.Write(line)
		if i < len(records)-1 {
			buf.WriteByte(',')
		}
		buf.WriteByte('\n')
	}
	buf.WriteString("]\n")

	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, buf.Bytes(), 0644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

func main() {
	outDir := flag.String("out", "../puzzle_corpus", "output directory")
	seed   := flag.Int64("seed", time.Now().UnixNano(), "random seed")
	easy   := flag.Int("easy",   3000, "target easy puzzles")
	medium := flag.Int("medium", 3000, "target medium puzzles")
	hard   := flag.Int("hard",   3000, "target hard puzzles")
	expert := flag.Int("expert",  2000, "target expert puzzles")
	master  := flag.Int("master",  3000, "target master puzzles")
	grand   := flag.Int("grand",   2000, "target grandmaster puzzles")
	legend  := flag.Int("legend",   200, "cap for legendary puzzles (opportunistic — does not block completion)")
	flag.Parse()

	targets := map[string]int{
		sudoku.DifficultyEasy:        *easy,
		sudoku.DifficultyMedium:      *medium,
		sudoku.DifficultyHard:        *hard,
		sudoku.DifficultyExpert:      *expert,
		sudoku.DifficultyMaster:      *master,
		sudoku.DifficultyGrandmaster: *grand,
		sudoku.DifficultyLegendary:   *legend,
	}
	fileNames := map[string]string{
		sudoku.DifficultyEasy:        "easy.json",
		sudoku.DifficultyMedium:      "medium.json",
		sudoku.DifficultyHard:        "hard.json",
		sudoku.DifficultyExpert:      "expert.json",
		sudoku.DifficultyMaster:      "master.json",
		sudoku.DifficultyGrandmaster: "grandmaster.json",
		sudoku.DifficultyLegendary:   "legendary.json",
	}
	levelOrder := []string{
		sudoku.DifficultyEasy, sudoku.DifficultyMedium, sudoku.DifficultyHard,
		sudoku.DifficultyExpert, sudoku.DifficultyMaster, sudoku.DifficultyGrandmaster,
		sudoku.DifficultyLegendary,
	}

	if err := os.MkdirAll(*outDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "cannot create output dir: %v\n", err)
		os.Exit(1)
	}

	// Load existing records and build global seen set.
	fmt.Fprintf(os.Stderr, "Loading existing corpus from %s…\n", *outDir)
	records := map[string][]puzzleRecord{}
	seen    := map[string]bool{}
	for _, lvl := range levelOrder {
		fname := fileNames[lvl]
		path := filepath.Join(*outDir, fname)
		fmt.Fprintf(os.Stderr, "  loading %s… ", fname)
		recs, ids := loadExisting(path)
		records[lvl] = recs
		for id := range ids {
			seen[id] = true
		}
		fmt.Fprintf(os.Stderr, "%d records\n", len(recs))
	}
	fmt.Fprintf(os.Stderr, "Loaded %d total records.\n\n", len(seen))

	// Print starting counts.
	fmt.Printf("Corpus generator  seed=%d\n\n", *seed)
	fmt.Printf("%-14s  %6s  %6s\n", "difficulty", "have", "target")
	for _, lvl := range levelOrder {
		fmt.Printf("%-14s  %6d  %6d\n", lvl, len(records[lvl]), targets[lvl])
	}
	fmt.Println()

	// Check if already done.
	allMet := true
	for lvl, target := range targets {
		if lvl == sudoku.DifficultyLegendary {
			continue // legendary is a cap, not a required target
		}
		if len(records[lvl]) < target {
			allMet = false
			break
		}
	}
	if allMet {
		fmt.Println("All targets already met.")
		return
	}

	reg, _ := sudoku.NewTechniqueRegistry()

	fmt.Fprintf(os.Stderr, "Starting generation loop…\n")
	rng          := rand.New(rand.NewSource(*seed))
	total        := 0
	start        := time.Now()
	dirty        := map[string]bool{}
	saveInterval := 500

	for {
		// Check if all targets are met.
		allMet = true
		for lvl, target := range targets {
			if lvl == sudoku.DifficultyLegendary {
				continue // legendary is a cap, not a required target
			}
			if len(records[lvl]) < target {
				allMet = false
				break
			}
		}
		if allMet {
			break
		}

		puzzle, solution, _ := sudoku.Generate(rng)
		total++

		rec, lvl, ok := buildRecord(puzzle, solution, reg)
		if !ok || seen[rec.ID] {
			// fall through to progress check
		} else if len(records[lvl]) >= targets[lvl] {
			// fall through to progress check
		} else {
			seen[rec.ID] = true
			records[lvl] = append(records[lvl], rec)
			dirty[lvl] = true
		}

		// Every 500 generated puzzles: save any new finds and print progress.
		if total%saveInterval == 0 {
			for lvl := range dirty {
				path := filepath.Join(*outDir, fileNames[lvl])
				if err := saveFile(path, records[lvl]); err != nil {
					fmt.Fprintf(os.Stderr, "save error (%s): %v\n", lvl, err)
				}
			}
			dirty = map[string]bool{}

			elapsed := time.Since(start).Seconds()
			rate    := float64(total) / elapsed
			fmt.Fprintf(os.Stderr, "\r%7d generated  %5.0f/s  ", total, rate)
			for _, lvl := range levelOrder {
				fmt.Fprintf(os.Stderr, "%s:%d/%d  ", lvl[:3], len(records[lvl]), targets[lvl])
			}
		}
	}

	// Final save.
	fmt.Fprintln(os.Stderr, "\nSaving final output…")
	for lvl, fname := range fileNames {
		if len(records[lvl]) == 0 {
			continue
		}
		path := filepath.Join(*outDir, fname)
		if err := saveFile(path, records[lvl]); err != nil {
			fmt.Fprintf(os.Stderr, "save error (%s): %v\n", lvl, err)
		}
	}

	elapsed := time.Since(start)
	fmt.Fprintf(os.Stderr, "\nDone — %d puzzles generated in %s\n\n", total, elapsed.Round(time.Second))
	fmt.Fprintf(os.Stderr, "%-14s  %6s\n", "difficulty", "count")
	for _, lvl := range levelOrder {
		fmt.Fprintf(os.Stderr, "%-14s  %6d\n", lvl, len(records[lvl]))
	}
}
