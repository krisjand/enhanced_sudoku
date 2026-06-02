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

// SolveStep records one pass of a solving technique and all the actions it produced.
type SolveStep struct {
	Technique string
	Actions   []CellAction
	Duration  time.Duration // total time for this technique pass
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
