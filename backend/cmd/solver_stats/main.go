// solver_stats generates Sudoku puzzles and prints statistics about how often
// each technique is used, the difficulty spread, forced-chain depth, and the
// average scan time per technique.
//
// Usage:
//
//	go run ./cmd/solver_stats [-n 1000] [-seed 42]
package main

import (
	"flag"
	"fmt"
	"math/rand"
	"sort"
	"strings"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

func main() {
	n := flag.Int("n", 1000, "number of puzzles to generate and analyse")
	seed := flag.Int64("seed", time.Now().UnixNano(), "random seed")
	flag.Parse()

	rng := rand.New(rand.NewSource(*seed))
	techs := sudoku.KnownTechniques()

	// --- accumulators ---

	diffCount := map[string]int{}

	// Per technique: number of puzzles where it was used (won ≥1 iteration)
	// and number where it was the decisive (hardest) technique.
	techUsed     := map[string]int{}
	techDecisive := map[string]int{}

	// Timing: total duration and attempt count per technique (all attempts,
	// success and failure alike, because that's the raw scan cost).
	techTotalDur   := map[string]time.Duration{}
	techAttempts   := map[string]int{}

	// Forced-chain depth: per FC win, collect branch depths.
	var fcChainCounts []int   // number of branches per FC step
	var fcBranchDepths []int  // depth of each branch across all FC steps

	solvable := 0

	fmt.Printf("Generating and solving %d puzzles (seed %d)…\n", *n, *seed)

	for i := 0; i < *n; i++ {
		puzzle, _, _ := sudoku.Generate(rng)
		result := sudoku.HumanSolve(puzzle)

		// --- collect timing and find winning techniques ---
		won := map[string]bool{}
		for _, iter := range result.Iterations {
			for _, attempt := range iter {
				techTotalDur[attempt.Technique] += attempt.Duration
				techAttempts[attempt.Technique]++

				if len(attempt.Steps) > 0 {
					won[attempt.Technique] = true

					// Forced-chain depth statistics.
					if attempt.Technique == sudoku.TechniqueForcedChains {
						for _, step := range attempt.Steps {
							fcChainCounts = append(fcChainCounts, len(step.Chains))
							for _, branch := range step.Chains {
								fcBranchDepths = append(fcBranchDepths, len(branch.Steps))
							}
						}
					}
				}
			}
		}

		for tech := range won {
			techUsed[tech]++
		}

		// Difficulty / decisive technique.
		dr := sudoku.Rate(puzzle)
		diffCount[dr.Level]++
		if result.Solved {
			solvable++
			// The decisive technique is the last one in dr.Techniques
			// (they are in complexity order; the last used is the hardest).
			if len(dr.Techniques) > 0 {
				decisive := dr.Techniques[len(dr.Techniques)-1]
				techDecisive[decisive]++
			}
		}
	}

	pct := func(k, total int) string {
		if total == 0 {
			return "  0.0%"
		}
		return fmt.Sprintf("%5.1f%%", 100.0*float64(k)/float64(total))
	}

	// ------------------------------------------------------------------ //
	// 1. Difficulty distribution
	// ------------------------------------------------------------------ //
	levels := []string{
		sudoku.DifficultyEasy,
		sudoku.DifficultyMedium,
		sudoku.DifficultyHard,
		sudoku.DifficultyExpert,
		sudoku.DifficultyMaster,
		sudoku.DifficultyGrandmaster,
		sudoku.DifficultyLegendary,
	}

	fmt.Printf("\n%s\n", strings.Repeat("─", 56))
	fmt.Printf("Difficulty distribution  (n=%d)\n", *n)
	fmt.Printf("%s\n", strings.Repeat("─", 56))
	fmt.Printf("  %-14s  %6s  %7s\n", "level", "count", "pct")
	for _, lvl := range levels {
		c := diffCount[lvl]
		fmt.Printf("  %-14s  %6d  %s\n", lvl, c, pct(c, *n))
	}

	// ------------------------------------------------------------------ //
	// 2. Technique usage
	// ------------------------------------------------------------------ //
	fmt.Printf("\n%s\n", strings.Repeat("─", 72))
	fmt.Printf("Technique usage  (base: %d solvable puzzles)\n", solvable)
	fmt.Printf("%s\n", strings.Repeat("─", 72))
	fmt.Printf("  %-22s  %8s  %10s\n", "technique", "used", "decisive")

	for _, tech := range techs {
		u := pct(techUsed[tech], solvable)
		d := pct(techDecisive[tech], solvable)
		fmt.Printf("  %-22s  %8s  %10s\n", tech, u, d)
	}

	// ------------------------------------------------------------------ //
	// 3. Cumulative solvability
	// ------------------------------------------------------------------ //
	fmt.Printf("\n%s\n", strings.Repeat("─", 56))
	fmt.Printf("Cumulative solvability (puzzles solved by technique or simpler)\n")
	fmt.Printf("%s\n", strings.Repeat("─", 56))
	cum := 0
	for _, tech := range techs {
		cum += techDecisive[tech]
		fmt.Printf("  up to %-22s  %6d  %s\n", tech, cum, pct(cum, *n))
	}
	// legendary (unsolvable) adds the rest
	cum += diffCount[sudoku.DifficultyLegendary]
	fmt.Printf("  %-29s  %6d  %s\n", "(legendary / unsolvable)", diffCount[sudoku.DifficultyLegendary], pct(diffCount[sudoku.DifficultyLegendary], *n))

	// ------------------------------------------------------------------ //
	// 4. Forced-chain depth
	// ------------------------------------------------------------------ //
	fmt.Printf("\n%s\n", strings.Repeat("─", 56))
	fmt.Printf("Forced-chain statistics\n")
	fmt.Printf("%s\n", strings.Repeat("─", 56))
	fcWins := len(fcChainCounts)
	if fcWins == 0 {
		fmt.Println("  No forced-chain wins in this sample.")
	} else {
		avgChains := mean(fcChainCounts)
		avgDepth := mean(fcBranchDepths)
		maxDepth := maxInt(fcBranchDepths)
		fmt.Printf("  Forced-chain wins (steps)   : %d\n", fcWins)
		fmt.Printf("  Avg branches per step       : %.2f\n", avgChains)
		fmt.Printf("  Avg branch depth            : %.2f\n", avgDepth)
		fmt.Printf("  Max branch depth            : %d\n", maxDepth)
		depthDist := map[int]int{}
		for _, d := range fcBranchDepths {
			depthDist[d]++
		}
		fmt.Printf("  Branch depth distribution:\n")
		for _, d := range sortedKeys(depthDist) {
			fmt.Printf("    depth %2d : %4d  (%.1f%%)\n", d, depthDist[d], 100.0*float64(depthDist[d])/float64(len(fcBranchDepths)))
		}
	}

	// ------------------------------------------------------------------ //
	// 5. Per-technique timing
	// ------------------------------------------------------------------ //
	fmt.Printf("\n%s\n", strings.Repeat("─", 56))
	fmt.Printf("Per-technique scan timing (avg per attempt)\n")
	fmt.Printf("%s\n", strings.Repeat("─", 56))
	fmt.Printf("  %-22s  %12s  %10s\n", "technique", "avg/attempt", "attempts")
	for _, tech := range techs {
		att := techAttempts[tech]
		if att == 0 {
			continue
		}
		avg := techTotalDur[tech] / time.Duration(att)
		fmt.Printf("  %-22s  %12s  %10d\n", tech, avg, att)
	}

	fmt.Printf("\n%s\n", strings.Repeat("─", 56))
}

func mean(xs []int) float64 {
	if len(xs) == 0 {
		return 0
	}
	sum := 0
	for _, x := range xs {
		sum += x
	}
	return float64(sum) / float64(len(xs))
}

func maxInt(xs []int) int {
	if len(xs) == 0 {
		return 0
	}
	m := xs[0]
	for _, x := range xs[1:] {
		if x > m {
			m = x
		}
	}
	return m
}

func sortedKeys(m map[int]int) []int {
	keys := make([]int, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Ints(keys)
	return keys
}
