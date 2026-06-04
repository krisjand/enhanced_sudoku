package sudoku

import "time"

const TechniqueXYWing = "xyWing"

// sees reports whether cell a and cell b share a row, column, or box.
func sees(a, b cell) bool {
	return a.r == b.r || a.c == b.c || (a.r/3 == b.r/3 && a.c/3 == b.c/3)
}

// XYWing identifies XY-wing patterns and records the candidate eliminations
// they enable. An XY-wing consists of a pivot cell {x,y} that sees two
// pincers {x,z} and {y,z}; digit z can be eliminated from every cell that
// sees both pincers. Returns a single SolveStep with all eliminations, or nil
// if none exist. All actions are ActionEliminate.
func XYWing(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	start := time.Now()
	actions, sources := xyWingScan(cands, seen)
	dur := time.Since(start)

	if len(actions) == 0 {
		return nil
	}
	return []SolveStep{{Technique: TechniqueXYWing, Sources: sources, Actions: actions, Duration: dur}}
}

func xyWingScan(cands Candidates, seen map[[3]int]bool) ([]CellAction, []SourceCell) {
	// Collect all bi-value cells once — pivots and pincers must all be bi-value.
	var bivalue []cell
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if popcount(cands[r][c]) == 2 {
				bivalue = append(bivalue, cell{r, c})
			}
		}
	}

	var actions []CellAction
	var sources []SourceCell

	for _, p := range bivalue {
		pmask := cands[p.r][p.c]
		xBit := pmask & (^pmask + 1) // lowest set bit = x
		yBit := pmask ^ xBit         // other bit = y

		for _, a := range bivalue {
			if a == p || !sees(p, a) {
				continue
			}
			amask := cands[a.r][a.c]
			if amask&xBit == 0 {
				continue // A must contain x
			}
			zBit := amask ^ xBit // z is A's other candidate
			z := int(trailingZeros(zBit) + 1)

			bwant := yBit | zBit
			for _, b := range bivalue {
				if b == p || b == a || !sees(p, b) {
					continue
				}
				if cands[b.r][b.c] != bwant {
					continue // B must be exactly {y, z}
				}

				// Valid XY-wing (P,A,B): eliminate z from cells seeing both A and B.
				prevLen := len(actions)
				for r := 0; r < 9; r++ {
					for c := 0; c < 9; c++ {
						e := cell{r, c}
						if e == a || e == b {
							continue
						}
						if cands[r][c]&zBit == 0 {
							continue
						}
						if !sees(e, a) || !sees(e, b) {
							continue
						}
						key := [3]int{r, c, z}
						if !seen[key] {
							seen[key] = true
							actions = append(actions, CellAction{Row: r, Col: c, Digit: z, Type: ActionEliminate})
						}
					}
				}
				if len(actions) > prevLen {
					sources = append(sources,
						SourceCell{Row: p.r, Col: p.c, Digits: maskToDigits(pmask)},
						SourceCell{Row: a.r, Col: a.c, Digits: maskToDigits(cands[a.r][a.c])},
						SourceCell{Row: b.r, Col: b.c, Digits: maskToDigits(cands[b.r][b.c])},
					)
				}
			}
		}
	}
	return actions, sources
}
