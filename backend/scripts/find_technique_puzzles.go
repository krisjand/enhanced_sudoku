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
	"syscall"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

// corpusFileForLevel maps a difficulty level to its corpus file name.
var corpusFileForLevel = map[string]string{
	sudoku.DifficultyEasy:        "easy.json",
	sudoku.DifficultyMedium:      "medium.json",
	sudoku.DifficultyHard:        "hard.json",
	sudoku.DifficultyExpert:      "expert.json",
	sudoku.DifficultyMaster:      "master.json",
	sudoku.DifficultyGrandmaster: "grandmaster.json",
	sudoku.DifficultyLegendary:   "legendary.json",
}

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

// buildRecord solves puzzle capped at technique and returns the record if that
// technique is decisive. Returns ok=false if the puzzle is unsolvable within
// the cap or if a simpler technique is sufficient.
func buildRecord(puzzle, solution sudoku.Grid, technique string, reg *sudoku.TechniqueRegistry) (puzzleRecord, bool) {
	result := sudoku.HumanSolveWith(puzzle, sudoku.HumanSolveOpts{MaxTechnique: technique})
	if !result.Solved {
		return puzzleRecord{}, false
	}

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
	if decisive != technique {
		return puzzleRecord{}, false
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
	}, true
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

func marshalRecords(records []puzzleRecord) ([]byte, error) {
	var buf bytes.Buffer
	buf.WriteString("[\n")
	for i, r := range records {
		line, err := json.Marshal(r)
		if err != nil {
			return nil, err
		}
		buf.WriteString("  ")
		buf.Write(line)
		if i < len(records)-1 {
			buf.WriteByte(',')
		}
		buf.WriteByte('\n')
	}
	buf.WriteString("]\n")
	return buf.Bytes(), nil
}

func writeRecords(path string, records []puzzleRecord) error {
	data, err := marshalRecords(records)
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// appendRecord locks the corpus file, re-reads it, appends rec if not already
// present, and writes it back. Safe to call from parallel instances.
func appendRecord(path string, rec puzzleRecord) error {
	lockPath := path + ".lock"
	lf, err := os.OpenFile(lockPath, os.O_CREATE|os.O_RDWR, 0644)
	if err != nil {
		return err
	}
	defer lf.Close()
	if err := syscall.Flock(int(lf.Fd()), syscall.LOCK_EX); err != nil {
		return err
	}
	defer syscall.Flock(int(lf.Fd()), syscall.LOCK_UN) //nolint:errcheck

	records, seen := loadExisting(path)
	if seen[rec.ID] {
		return nil // another instance already added it
	}
	return writeRecords(path, append(records, rec))
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
		fullReg, _ := sudoku.NewTechniqueRegistry()
		for _, t := range fullReg.Names() {
			fmt.Fprintf(os.Stderr, "  %s\n", t)
		}
		os.Exit(1)
	}

	reg, err := sudoku.NewTechniqueRegistry(*technique)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: unknown technique %q\n", *technique)
		fmt.Fprintln(os.Stderr, "known techniques:")
		fullReg, _ := sudoku.NewTechniqueRegistry()
		for _, t := range fullReg.Names() {
			fmt.Fprintf(os.Stderr, "  %s\n", t)
		}
		os.Exit(1)
	}

	level := reg.Level([]string{*technique})
	corpusFile := corpusFileForLevel[level]
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

		rec, ok := buildRecord(puzzle, solution, *technique, reg)
		if !ok {
			if generated%500 == 0 {
				elapsed := time.Since(start).Seconds()
				rate := float64(generated) / elapsed
				fmt.Fprintf(os.Stderr, "\r%7d generated  %5.0f/s  found %d/%d", generated, rate, found, *target)
			}
			continue
		}
		if seen[rec.ID] {
			continue
		}
		seen[rec.ID] = true
		found++

		elapsed := time.Since(start).Seconds()
		rate := float64(generated) / elapsed
		fmt.Fprintf(os.Stderr, "\r%7d generated  %5.0f/s  found %d/%d", generated, rate, found, *target)

		if err := appendRecord(outPath, rec); err != nil {
			fmt.Fprintf(os.Stderr, "\nsave error: %v\n", err)
		}
	}

	fmt.Fprintln(os.Stderr, "")
	finalRecords, _ := loadExisting(outPath)
	elapsed := time.Since(start)
	fmt.Printf("\nDone — found %d decisive puzzles in %d generated (%s)\n",
		found, generated, elapsed.Round(time.Second))
	fmt.Printf("Corpus file now has %d total records.\n", len(finalRecords))
}
