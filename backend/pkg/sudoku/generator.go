package sudoku

import (
	"math/rand"
	"time"
)

// Generate produces a Sudoku puzzle with a unique solution.
// rng controls all randomness, making output deterministic for a given seed.
// rng must not be nil; use rand.New(rand.NewSource(seed)) to construct one.
// Returns the puzzle (partially filled), its solution (complete), and the time taken.
func Generate(rng *rand.Rand) (Grid, Grid, time.Duration) {
	start := time.Now()
	solution := generateSolution(rng)
	puzzle := removeClues(solution, rng)
	return puzzle, solution, time.Since(start)
}

// generateSolution fills an empty grid with a valid random solution using
// randomized backtracking. Cell selection uses MRV for performance; digit
// order within each cell is shuffled by rng so the resulting grid varies
// across calls.
func generateSolution(rng *rand.Rand) Grid {
	var g Grid
	cands := Init(g)
	result, ok := backtrackWith(g, cands, func(mask uint16) []uint8 {
		return shuffledDigits(mask, rng)
	})
	if !ok {
		panic("sudoku: generateSolution failed on empty grid — this should never happen")
	}
	return result
}

// removeClues tries removing each cell from solution in a random order,
// keeping a removal only when the puzzle still has a unique solution.
func removeClues(solution Grid, rng *rand.Rand) Grid {
	puzzle := solution
	for _, idx := range rng.Perm(81) {
		r, c := idx/9, idx%9
		digit := puzzle[r][c]
		puzzle[r][c] = 0
		if !HasUniqueSolution(puzzle) {
			puzzle[r][c] = digit
		}
	}
	return puzzle
}

// shuffledDigits extracts all candidate digits from mask and returns them in random order.
func shuffledDigits(mask uint16, rng *rand.Rand) []uint8 {
	digits := make([]uint8, 0, 9)
	for mask != 0 {
		bit := mask & (-mask)
		mask &^= bit
		digits = append(digits, uint8(trailingZeros(bit)+1))
	}
	rng.Shuffle(len(digits), func(i, j int) { digits[i], digits[j] = digits[j], digits[i] })
	return digits
}
