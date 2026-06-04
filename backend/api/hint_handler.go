package main

import (
	"net/http"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

type hintHandler struct{}

func newHintHandler() *hintHandler { return &hintHandler{} }

func (h *hintHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Grid       sudoku.Grid  `json:"grid"`
		Candidates *[9][9][]int `json:"candidates"`
	}
	if err := decodeJSON(w, r, &req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if !req.Grid.IsValid() {
		http.Error(w, "invalid grid", http.StatusUnprocessableEntity)
		return
	}

	var cands sudoku.Candidates
	if req.Candidates != nil {
		cands = sudoku.CandidatesFromDigits(req.Grid, *req.Candidates)
	} else {
		cands = sudoku.Init(req.Grid)
	}

	step, solved, stuck := sudoku.HumanSolveStep(req.Grid, cands)
	writeJSON(w, toHintResponse(step, solved, stuck))
}

type hintResponse struct {
	Solved bool          `json:"solved,omitempty"`
	Stuck  bool          `json:"stuck,omitempty"`
	Step   *stepResponse `json:"step,omitempty"`
}

func toHintResponse(step *sudoku.SolveStep, solved, stuck bool) hintResponse {
	if solved {
		return hintResponse{Solved: true}
	}
	if stuck {
		return hintResponse{Stuck: true}
	}
	sr := toStepResponse(*step)
	return hintResponse{Step: &sr}
}
