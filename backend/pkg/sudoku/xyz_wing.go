package sudoku

import "time"

const TechniqueXYZWing = "xyzWing"

// XYZWing identifies XYZ-wing patterns and records the candidate eliminations
// they enable. An XYZ-wing consists of a tri-value pivot {x,y,z} that sees
// two bi-value pincers whose candidates are subsets of the pivot's and together
// cover all three pivot candidates. Digit z — the candidate shared by both
// pincers — can be eliminated from every cell that sees the pivot and both
// pincers. Returns a single SolveStep with all eliminations, or nil if none
// exist. All actions are ActionEliminate.
func XYZWing(g Grid, cands Candidates) []SolveStep {
	seen := make(map[[3]int]bool)

	start := time.Now()
	actions := xyzWingScan(cands, seen)
	dur := time.Since(start)

	if len(actions) == 0 {
		return nil
	}
	return []SolveStep{{Technique: TechniqueXYZWing, Actions: actions, Duration: dur}}
}

func xyzWingScan(cands Candidates, seen map[[3]int]bool) []CellAction {
	// Collect bi-value cells once — pincers must be bi-value.
	var bivalue []cell
	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			if popcount(cands[r][c]) == 2 {
				bivalue = append(bivalue, cell{r, c})
			}
		}
	}

	var actions []CellAction

	for r := 0; r < 9; r++ {
		for c := 0; c < 9; c++ {
			pmask := cands[r][c]
			if popcount(pmask) != 3 {
				continue
			}
			p := cell{r, c}

			for _, a := range bivalue {
				if a == p || !sees(p, a) {
					continue
				}
				amask := cands[a.r][a.c]
				if amask&^pmask != 0 {
					continue // A's candidates must be a subset of P's
				}

				for _, b := range bivalue {
					if b == p || b == a || !sees(p, b) {
						continue
					}
					bmask := cands[b.r][b.c]
					if bmask&^pmask != 0 {
						continue // B's candidates must be a subset of P's
					}
					if amask|bmask != pmask {
						continue // A and B together must cover all of P's candidates
					}

					// zBit always has exactly 1 bit by pigeonhole:
					// |A|=|B|=2, A⊆P, B⊆P, |P|=3, |A∪B|=3 → |A∩B|=1.
					zBit := amask & bmask
					z := int(trailingZeros(zBit) + 1)

					// Eliminate z from cells seeing P, A, and B.
					for er := 0; er < 9; er++ {
						for ec := 0; ec < 9; ec++ {
							e := cell{er, ec}
							if e == p || e == a || e == b {
								continue
							}
							if cands[er][ec]&zBit == 0 {
								continue
							}
							if !sees(e, p) || !sees(e, a) || !sees(e, b) {
								continue
							}
							key := [3]int{er, ec, z}
							if !seen[key] {
								seen[key] = true
								actions = append(actions, CellAction{Row: er, Col: ec, Digit: z, Type: ActionEliminate})
							}
						}
					}
				}
			}
		}
	}
	return actions
}
