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
	Duration time.Duration // time elapsed to find this specific action
}

// SolveStep records one pass of a solving technique and all the actions it produced.
type SolveStep struct {
	Technique string
	Actions   []CellAction
	Duration  time.Duration // total time for this technique pass
}
