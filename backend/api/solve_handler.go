package main

import (
	"net/http"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

type solveHandler struct{}

func newSolveHandler() *solveHandler { return &solveHandler{} }

func (h *solveHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Puzzle sudoku.Grid `json:"puzzle"`
	}
	if err := decodeJSON(w, r, &req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if !req.Puzzle.IsValid() {
		http.Error(w, "invalid puzzle", http.StatusUnprocessableEntity)
		return
	}

	result := sudoku.HumanSolve(req.Puzzle)
	writeJSON(w, toSolveResponse(result))
}

// solveResponse is the JSON shape returned by POST /puzzle/solve.
type solveResponse struct {
	Solved      bool                `json:"solved"`
	Grid        sudoku.Grid         `json:"grid"`
	DurationUs  int64               `json:"duration_us"`
	Iterations  []iterationResponse `json:"iterations"`
}

type iterationResponse struct {
	Attempts []attemptResponse `json:"attempts"`
}

type attemptResponse struct {
	Technique   string          `json:"technique"`
	DurationUs  int64           `json:"duration_us"`
	Found       bool            `json:"found"`
	Steps       []stepResponse  `json:"steps,omitempty"`
}

type stepResponse struct {
	Technique string               `json:"technique"`
	Actions   []actionResponse     `json:"actions"`
	Chains    []chainBranchResponse `json:"chains,omitempty"`
}

type actionResponse struct {
	Row   int    `json:"row"`
	Col   int    `json:"col"`
	Digit int    `json:"digit"`
	Type  string `json:"type"`
}

type chainBranchResponse struct {
	Candidate int            `json:"candidate"`
	Steps     []stepResponse `json:"steps"`
}

func toStepResponse(s sudoku.SolveStep) stepResponse {
	sr := stepResponse{Technique: s.Technique}
	for _, act := range s.Actions {
		sr.Actions = append(sr.Actions, actionResponse{
			Row:   act.Row,
			Col:   act.Col,
			Digit: act.Digit,
			Type:  actionTypeName(act.Type),
		})
	}
	for _, branch := range s.Chains {
		br := chainBranchResponse{Candidate: branch.Candidate}
		for _, bs := range branch.Steps {
			br.Steps = append(br.Steps, toStepResponse(bs))
		}
		sr.Chains = append(sr.Chains, br)
	}
	return sr
}

func toSolveResponse(r sudoku.SolveResult) solveResponse {
	iterations := make([]iterationResponse, len(r.Iterations))
	for i, iter := range r.Iterations {
		attempts := make([]attemptResponse, len(iter))
		for j, attempt := range iter {
			a := attemptResponse{
				Technique:  attempt.Technique,
				DurationUs: attempt.Duration.Microseconds(),
				Found:      len(attempt.Steps) > 0,
			}
			for _, s := range attempt.Steps {
				a.Steps = append(a.Steps, toStepResponse(s))
			}
			attempts[j] = a
		}
		iterations[i] = iterationResponse{Attempts: attempts}
	}
	return solveResponse{
		Solved:     r.Solved,
		Grid:       r.Grid,
		DurationUs: r.Duration.Microseconds(),
		Iterations: iterations,
	}
}

func actionTypeName(t sudoku.ActionType) string {
	if t == sudoku.ActionEliminate {
		return "eliminate"
	}
	return "set"
}
