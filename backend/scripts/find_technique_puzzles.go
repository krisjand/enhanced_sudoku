//go:build ignore

// find_technique_puzzles generates puzzles where a specific technique is
// decisive (the "gatekeeper") and appends them to the appropriate corpus file.
//
// Useful for filling gaps where a technique is rare — e.g. hiddenQuadruples
// has only ~7 examples in the default corpus.
//
// Usage (from the backend/ directory):
//
//	go run ./scripts/find_technique_puzzles.go -technique hiddenQuadruples
//	go run ./scripts/find_technique_puzzles.go -technique hiddenQuadruples -target 20 -seed 42
//
// Flags:
//
//	-technique  Technique identifier to search for (required)
//	-target     How many new decisive puzzles to find (default: 20)
//	-corpus     Corpus directory (default: ../puzzle_corpus)
//	-seed       Random seed (default: current time)
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

// techniqueCorpusFile maps each known technique to its corpus file.
var techniqueCorpusFile = map[string]string{
	sudoku.TechniqueNakedSingles:  "easy.json",
	sudoku.TechniqueHiddenSingles: "easy.json",

	sudoku.TechniqueLockedCandidates: "medium.json",
	sudoku.TechniqueNakedPairs:       "medium.json",

	sudoku.TechniqueHiddenPairs:   "hard.json",
	sudoku.TechniqueNakedTriples:  "hard.json",

	sudoku.TechniqueHiddenTriples:    "expert.json",
	sudoku.TechniqueNakedQuadruples:  "expert.json",
	sudoku.TechniqueHiddenQuadruples: "expert.json",
	sudoku.TechniqueXWing:            "expert.json",

	sudoku.TechniqueSwordfish: "master.json",
	sudoku.TechniqueXYWing:    "master.json",
	sudoku.TechniqueXYZWing:   "master.json",

	sudoku.TechniqueForcedChains: "grandmaster.json",
}

type puzzleRecord struct {
	ID               string    `json:"id"`
	Grid             [9][9]int `json:"grid"`
	Solution         [9][9]int `json:"solution"`
	Techniques       []string  `json:"techniques"`
	Decisive         string    `json:"decisive,omitempty"`
	ForcedChainUses  int       `json:"forcedChainUses,omitempty"`
	ForcedChainSteps int       `json:"forcedChainSteps,omitempty"`
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

func buildRecord(puzzle, solution sudoku.Grid) (puzzleRecord, string) {
	result := sudoku.HumanSolve(puzzle)
	dr := sudoku.RateResult(result)

	var fcUses, fcSteps int
	for _, iter := range result.Iterations {
		for _, attempt := range iter {
			if attempt.Technique != sudoku.TechniqueForcedChains || len(attempt.Steps) == 0 {
				continue
			}
			fcUses++
			for _, step := range attempt.Steps {
				for _, branch := range step.Chains {
					if d := len(branch.Steps); d > fcSteps {
						fcSteps = d
					}
				}
			}
		}
	}

	return puzzleRecord{
		ID:               puzzleID(puzzle),
		Grid:             toInts(puzzle),
		Solution:         toInts(solution),
		Techniques:       dr.Techniques,
		Decisive:         dr.Decisive,
		ForcedChainUses:  fcUses,
		ForcedChainSteps: fcSteps,
	}, dr.Level
}

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
	technique := flag.String("technique", "", "technique identifier to search for (required)")
	target    := flag.Int("target", 20, "number of new decisive puzzles to find")
	corpusDir := flag.String("corpus", "../puzzle_corpus", "corpus directory")
	seed      := flag.Int64("seed", time.Now().UnixNano(), "random seed")
	flag.Parse()

	if *technique == "" {
		fmt.Fprintln(os.Stderr, "error: -technique is required")
		fmt.Fprintln(os.Stderr, "known techniques:")
		for t := range techniqueCorpusFile {
			fmt.Fprintf(os.Stderr, "  %s\n", t)
		}
		os.Exit(1)
	}

	corpusFile, ok := techniqueCorpusFile[*technique]
	if !ok {
		fmt.Fprintf(os.Stderr, "error: unknown technique %q\n", *technique)
		fmt.Fprintln(os.Stderr, "known techniques:")
		for t := range techniqueCorpusFile {
			fmt.Fprintf(os.Stderr, "  %s\n", t)
		}
		os.Exit(1)
	}

	outPath := filepath.Join(*corpusDir, corpusFile)
	fmt.Printf("Searching for puzzles decisive in: %s\n", *technique)
	fmt.Printf("Output file:                        %s\n", outPath)
	fmt.Printf("Target new puzzles:                 %d\n", *target)
	fmt.Printf("Seed:                               %d\n\n", *seed)

	records, seen := loadExisting(outPath)

	// Count how many decisive puzzles already exist for this technique.
	alreadyHave := 0
	for _, r := range records {
		if r.Decisive == *technique {
			alreadyHave++
		}
	}
	fmt.Printf("Already in corpus: %d decisive, %d total records\n\n", alreadyHave, len(records))

	rng       := rand.New(rand.NewSource(*seed))
	found     := 0
	generated := 0
	start     := time.Now()

	for found < *target {
		puzzle, solution, _ := sudoku.Generate(rng)
		generated++

		rec, _ := buildRecord(puzzle, solution)
		if seen[rec.ID] {
			continue
		}
		seen[rec.ID] = true

		if rec.Decisive != *technique {
			if generated%500 == 0 {
				elapsed := time.Since(start).Seconds()
				rate := float64(generated) / elapsed
				fmt.Fprintf(os.Stderr, "\r%7d generated  %5.0f/s  found %d/%d", generated, rate, found, *target)
			}
			continue
		}

		records = append(records, rec)
		found++

		elapsed := time.Since(start).Seconds()
		rate := float64(generated) / elapsed
		fmt.Fprintf(os.Stderr, "\r%7d generated  %5.0f/s  found %d/%d", generated, rate, found, *target)

		if err := saveFile(outPath, records); err != nil {
			fmt.Fprintf(os.Stderr, "\nsave error: %v\n", err)
		}
	}

	// Final save.
	fmt.Fprintln(os.Stderr, "")
	if err := saveFile(outPath, records); err != nil {
		fmt.Fprintf(os.Stderr, "save error: %v\n", err)
		os.Exit(1)
	}

	elapsed := time.Since(start)
	fmt.Printf("\nDone — found %d decisive puzzles in %d generated (%s)\n",
		found, generated, elapsed.Round(time.Second))
	fmt.Printf("Corpus file now has %d total records.\n", len(records))
}
