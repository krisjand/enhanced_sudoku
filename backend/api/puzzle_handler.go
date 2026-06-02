package main

import (
	"math/rand"
	"net/http"
	"sync"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

type puzzleResponse struct {
	Puzzle      sudoku.Grid `json:"puzzle"`
	Solution    sudoku.Grid `json:"solution"`
	GeneratedUs int64       `json:"generated_us"`
}

type puzzleHandler struct {
	rng   *rand.Rand
	rngMu sync.Mutex
}

func newPuzzleHandler() *puzzleHandler {
	return &puzzleHandler{
		rng: rand.New(rand.NewSource(time.Now().UnixNano())),
	}
}

func (h *puzzleHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if !requireGET(w, r) {
		return
	}
	puzzle, solution, dur := func() (sudoku.Grid, sudoku.Grid, time.Duration) {
		h.rngMu.Lock()
		defer h.rngMu.Unlock()
		return sudoku.Generate(h.rng)
	}()
	writeJSON(w, puzzleResponse{
		Puzzle:      puzzle,
		Solution:    solution,
		GeneratedUs: dur.Microseconds(),
	})
}
