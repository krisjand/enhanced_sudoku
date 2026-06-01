package sudoku

import "time"

// Solve returns the solution to g, whether one exists, and the time taken.
func Solve(g Grid) (Grid, bool, time.Duration) {
	start := time.Now()
	solution, found := solve(g)
	return solution, found, time.Since(start)
}

// HasUniqueSolution reports whether g has exactly one solution.
func HasUniqueSolution(g Grid) bool {
	count := 0
	countSolutions(g, &count)
	return count == 1
}

// solve is the recursive backtracking solver. It selects the most constrained
// empty cell (fewest candidates, MRV heuristic) at each step to minimise the
// search space and detect contradictions as early as possible.
func solve(g Grid) (Grid, bool) {
	r, c, ok := mostConstrained(g)
	if !ok {
		return g, g.IsValid()
	}

	cands := Init(g)
	mask := cands[r][c]
	if mask == 0 {
		return g, false // contradiction — backtrack
	}

	for mask != 0 {
		bit := mask & (-mask) // isolate lowest set bit
		mask &^= bit
		digit := uint8(trailingZeros(bit) + 1)

		g[r][c] = digit
		if solution, found := solve(g); found {
			return solution, true
		}
		g[r][c] = 0
	}
	return g, false
}

// countSolutions counts solutions, stopping once count reaches 2.
// This is sufficient to determine uniqueness without exhaustive search.
func countSolutions(g Grid, count *int) {
	if *count >= 2 {
		return
	}
	r, c, ok := mostConstrained(g)
	if !ok {
		if g.IsValid() {
			*count++
		}
		return
	}

	cands := Init(g)
	mask := cands[r][c]
	if mask == 0 {
		return // contradiction — backtrack
	}

	for mask != 0 {
		bit := mask & (-mask)
		mask &^= bit
		digit := uint8(trailingZeros(bit) + 1)

		g[r][c] = digit
		countSolutions(g, count)
		g[r][c] = 0
	}
}

// mostConstrained returns the empty cell with the fewest candidates (MRV).
// If a cell has zero candidates it is returned immediately as a contradiction.
// Returns ok=false when no empty cells remain.
func mostConstrained(g Grid) (row, col int, ok bool) {
	cands := Init(g)
	bestR, bestC := -1, -1
	bestCount := 10

	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 {
				continue
			}
			n := popcount(cands[r][c])
			if n == 0 {
				return r, c, true // contradiction — caller will see empty mask
			}
			if n < bestCount {
				bestCount = n
				bestR, bestC = r, c
				if n == 1 {
					return bestR, bestC, true // forced cell — can't do better
				}
			}
		}
	}

	if bestR == -1 {
		return 0, 0, false // no empty cells
	}
	return bestR, bestC, true
}
