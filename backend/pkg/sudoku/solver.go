package sudoku

import "time"

// Solve returns the solution to g, whether one exists, and the time taken.
func Solve(g Grid) (Grid, bool, time.Duration) {
	start := time.Now()
	cands := Init(g)
	solution, found := solve(g, cands)
	return solution, found, time.Since(start)
}

// HasUniqueSolution reports whether g has exactly one solution.
func HasUniqueSolution(g Grid) bool {
	count := 0
	cands := Init(g)
	countSolutions(g, cands, &count)
	return count == 1
}

// solve is the recursive backtracking solver. Candidates are computed once at
// the top level and updated incrementally — each placement copies the 162-byte
// Candidates struct and applies Set() (O(27) bit ops) rather than recomputing
// from scratch (O(81×27)) at every node.
func solve(g Grid, cands Candidates) (Grid, bool) {
	r, c, ok := mostConstrainedFrom(cands, g)
	if !ok {
		return g, g.IsValid()
	}
	mask := cands[r][c]
	if mask == 0 {
		return g, false // contradiction — backtrack
	}

	for mask != 0 {
		bit := mask & (-mask) // isolate lowest set bit
		mask &^= bit
		digit := uint8(trailingZeros(bit) + 1)

		next := cands
		next.Set(r, c, int(digit))
		g[r][c] = digit
		if solution, found := solve(g, next); found {
			return solution, true
		}
		g[r][c] = 0
	}
	return g, false
}

// countSolutions counts solutions, stopping once count reaches 2.
// This is sufficient to determine uniqueness without exhaustive search.
func countSolutions(g Grid, cands Candidates, count *int) {
	if *count >= 2 {
		return
	}
	r, c, ok := mostConstrainedFrom(cands, g)
	if !ok {
		if g.IsValid() {
			*count++
		}
		return
	}
	mask := cands[r][c]
	if mask == 0 {
		return // contradiction — backtrack
	}

	for mask != 0 {
		bit := mask & (-mask)
		mask &^= bit
		digit := uint8(trailingZeros(bit) + 1)

		next := cands
		next.Set(r, c, int(digit))
		g[r][c] = digit
		countSolutions(g, next, count)
		g[r][c] = 0
	}
}

// mostConstrainedFrom returns the empty cell with the fewest candidates (MRV)
// using the pre-computed candidate set. If a cell has zero candidates it is
// returned immediately as a contradiction. Returns ok=false when no empty
// cells remain.
func mostConstrainedFrom(cands Candidates, g Grid) (row, col int, ok bool) {
	bestR, bestC := -1, -1
	bestCount := 10

	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if g[r][c] != 0 {
				continue
			}
			n := popcount(cands[r][c])
			if n == 0 {
				return r, c, true // contradiction — caller sees empty mask
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
