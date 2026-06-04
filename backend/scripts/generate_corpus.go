// generate_corpus produces pre-rated Sudoku puzzles and writes them to one
// compact JSON file per difficulty, for bundling with the Flutter app.
//
// Usage (from the backend/ directory):
//
//	go run ./scripts/generate_corpus.go [flags]
//
// Flags:
//
//	-out      Output directory (default: ../../puzzle_corpus)
//	-seed     Random seed (default: current time)
//	-easy     Target count for easy puzzles (default: 2000)
//	-medium   Target count for medium puzzles (default: 2000)
//	-hard     Target count for hard puzzles (default: 1000)
//	-expert   Target count for expert puzzles (default: 300)
//	-master   Target count for master puzzles (default: 1000)
//	-grand    Target count for grandmaster puzzles (default: 2000)
//
// The script is resumable: it reads existing output files on startup and only
// generates puzzles for targets not yet met. Duplicate puzzles are skipped via
// content-derived IDs.
package main

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"sort"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

// puzzleRecord is one entry in the output JSON files.
type puzzleRecord struct {
	ID         string      `json:"id"`
	Grid       [9][9]int   `json:"grid"`
	Solution   [9][9]int   `json:"solution"`
	Techniques []string    `json:"techniques"`
	Decisive   string      `json:"decisive"`
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

func buildRecord(puzzle sudoku.Grid) (puzzleRecord, bool) {
	result := sudoku.HumanSolve(puzzle)
	if !result.Solved {
		return puzzleRecord{}, false
	}

	dr := sudoku.Rate(puzzle)
	if dr.Level == sudoku.DifficultyLegendary {
		return puzzleRecord{}, false
	}

	// Sort techniques by complexity order (simplest first).
	known  := sudoku.KnownTechniques()
	rankOf := make(map[string]int, len(known))
	for i, t := range known {
		rankOf[t] = i
	}
	techSet := make(map[string]bool, len(dr.Techniques))
	for _, t := range dr.Techniques {
		techSet[t] = true
	}
	techniques := make([]string, 0, len(dr.Techniques))
	for _, t := range known {
		if techSet[t] {
			techniques = append(techniques, t)
		}
	}
	sort.Slice(techniques, func(i, j int) bool {
		return rankOf[techniques[i]] < rankOf[techniques[j]]
	})

	return puzzleRecord{
		ID:         puzzleID(puzzle),
		Grid:       toInts(puzzle),
		Solution:   toInts(result.Grid),
		Techniques: techniques,
		Decisive:   techniques[len(techniques)-1],
	}, true
}

// loadExisting reads a JSON file and returns the records and a set of IDs.
func loadExisting(path string) ([]puzzleRecord, map[string]bool) {
	seen := map[string]bool{}
	f, err := os.Open(path)
	if err != nil {
		return nil, seen
	}
	defer f.Close()

	var records []puzzleRecord
	if err := json.NewDecoder(f).Decode(&records); err != nil {
		return nil, seen
	}
	for _, r := range records {
		seen[r.ID] = true
	}
	return records, seen
}

// saveFile writes records as a compact JSON array — one puzzle per line.
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
	outDir  := flag.String("out", "../../puzzle_corpus", "output directory")
	seed    := flag.Int64("seed", time.Now().UnixNano(), "random seed")
	easy    := flag.Int("easy",   2000, "target easy puzzles")
	medium  := flag.Int("medium", 2000, "target medium puzzles")
	hard    := flag.Int("hard",   1000, "target hard puzzles")
	expert  := flag.Int("expert",  300, "target expert puzzles")
	master  := flag.Int("master", 1000, "target master puzzles")
	grand   := flag.Int("grand",  2000, "target grandmaster puzzles")
	flag.Parse()

	targets := map[string]int{
		sudoku.DifficultyEasy:        *easy,
		sudoku.DifficultyMedium:      *medium,
		sudoku.DifficultyHard:        *hard,
		sudoku.DifficultyExpert:      *expert,
		sudoku.DifficultyMaster:      *master,
		sudoku.DifficultyGrandmaster: *grand,
	}
	fileNames := map[string]string{
		sudoku.DifficultyEasy:        "easy.json",
		sudoku.DifficultyMedium:      "medium.json",
		sudoku.DifficultyHard:        "hard.json",
		sudoku.DifficultyExpert:      "expert.json",
		sudoku.DifficultyMaster:      "master.json",
		sudoku.DifficultyGrandmaster: "grandmaster.json",
	}

	if err := os.MkdirAll(*outDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "cannot create output dir: %v\n", err)
		os.Exit(1)
	}

	// Load existing records and build global seen set.
	records := map[string][]puzzleRecord{}
	seen    := map[string]bool{}
	for level, fname := range fileNames {
		path := filepath.Join(*outDir, fname)
		recs, ids := loadExisting(path)
		records[level] = recs
		for id := range ids {
			seen[id] = true
		}
	}

	// Print starting counts.
	fmt.Printf("Corpus generator  seed=%d\n\n", *seed)
	fmt.Printf("%-14s  %6s  %6s\n", "difficulty", "have", "target")
	for _, lvl := range []string{
		sudoku.DifficultyEasy, sudoku.DifficultyMedium, sudoku.DifficultyHard,
		sudoku.DifficultyExpert, sudoku.DifficultyMaster, sudoku.DifficultyGrandmaster,
	} {
		fmt.Printf("%-14s  %6d  %6d\n", lvl, len(records[lvl]), targets[lvl])
	}
	fmt.Println()

	// Check if already done.
	allMet := true
	for lvl, target := range targets {
		if len(records[lvl]) < target {
			allMet = false
			break
		}
	}
	if allMet {
		fmt.Println("All targets already met.")
		return
	}

	rng      := rand.New(rand.NewSource(*seed))
	total    := 0
	start    := time.Now()
	dirty    := map[string]bool{}
	scanner  := bufio.NewScanner(os.Stdin)
	_ = scanner

	saveInterval := 500

	for {
		// Check if all targets are met.
		allMet = true
		for lvl, target := range targets {
			if len(records[lvl]) < target {
				allMet = false
				break
			}
		}
		if allMet {
			break
		}

		puzzle, _, _ := sudoku.Generate(rng)
		total++

		rec, ok := buildRecord(puzzle)
		if !ok || seen[rec.ID] {
			continue
		}

		lvl := sudoku.Rate(puzzle).Level
		if len(records[lvl]) >= targets[lvl] {
			continue
		}

		seen[rec.ID] = true
		records[lvl] = append(records[lvl], rec)
		dirty[lvl] = true

		// Save periodically and print progress.
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
			fmt.Printf("\r%7d generated  %5.0f/s  ", total, rate)
			for _, lvl := range []string{
				sudoku.DifficultyEasy, sudoku.DifficultyMedium, sudoku.DifficultyHard,
				sudoku.DifficultyExpert, sudoku.DifficultyMaster, sudoku.DifficultyGrandmaster,
			} {
				fmt.Printf("%s:%d/%d  ", lvl[:3], len(records[lvl]), targets[lvl])
			}
		}
	}

	// Final save.
	fmt.Println("\nSaving final output…")
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
	fmt.Printf("\nDone — %d puzzles generated in %s\n\n", total, elapsed.Round(time.Second))
	fmt.Printf("%-14s  %6s\n", "difficulty", "count")
	for _, lvl := range []string{
		sudoku.DifficultyEasy, sudoku.DifficultyMedium, sudoku.DifficultyHard,
		sudoku.DifficultyExpert, sudoku.DifficultyMaster, sudoku.DifficultyGrandmaster,
	} {
		fmt.Printf("%-14s  %6d\n", lvl, len(records[lvl]))
	}
}
