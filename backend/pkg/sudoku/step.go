package sudoku

import "time"

// ActionType describes what a solving step did to a cell.
type ActionType uint8

const (
	ActionSet      ActionType = iota // digit placed in cell
	ActionEliminate                  // digit removed from candidates
)

// CellAction records a single resolution or elimination within a technique pass.
type CellAction struct {
	Row, Col int
	Digit    int
	Type     ActionType
}

// ForcedChainBranch records the propagation steps taken when one candidate
// of a seed cell is assumed to be true.
type ForcedChainBranch struct {
	Candidate int
	Steps     []SolveStep
}

// SourceCell identifies a cell that is part of the pattern triggering a technique.
// Digits lists the candidate digits in this cell that are relevant to the pattern.
type SourceCell struct {
	Row    int
	Col    int
	Digits []int
}

// SolveStep records one pass of a solving technique and all the actions it produced.
type SolveStep struct {
	Technique string
	Sources   []SourceCell        // cells forming the pattern that triggered the technique
	Actions   []CellAction
	Duration  time.Duration       // total time for this technique pass
	Chains    []ForcedChainBranch `json:"chains,omitempty"`    // only set for forced chain conclusions
	ChainType string              `json:"chainType,omitempty"` // forced chains only: contradiction / mutualInclusion / mutualElimination / mixed
	SeedType  string              `json:"seedType,omitempty"`  // forced chains only: biValue / biLocation / triValue
}

// TechniqueFn is the common signature all analysis functions implement.
type TechniqueFn func(Grid, Candidates) []SolveStep

// TechniqueAttempt records one attempt to apply a technique,
// whether or not it produced any findings. Duration is always populated
// so timing is preserved even when Steps is nil.
type TechniqueAttempt struct {
	Technique string
	Duration  time.Duration
	Steps     []SolveStep // nil if the technique found nothing
}

// SolveResult is the output of HumanSolve.
type SolveResult struct {
	Solved     bool
	Grid       Grid
	Duration   time.Duration        // total wall time spent solving
	Iterations [][]TechniqueAttempt // one []TechniqueAttempt per iteration until solved or stuck
}
