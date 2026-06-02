package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

const defaultMaxAttempts = 100
const maxAllowedAttempts = 10_000

type findPuzzleHandler struct {
	rng   *rand.Rand
	rngMu sync.Mutex
}

func newFindPuzzleHandler() *findPuzzleHandler {
	return newFindPuzzleHandlerWithRng(rand.New(rand.NewSource(time.Now().UnixNano())))
}

func newFindPuzzleHandlerWithRng(rng *rand.Rand) *findPuzzleHandler {
	return &findPuzzleHandler{rng: rng}
}

type findPuzzleResponse struct {
	Puzzle    sudoku.Grid `json:"puzzle"`
	Technique string      `json:"technique"`
	Attempts  int         `json:"attempts"`
}

func (h *findPuzzleHandler) generate() sudoku.Grid {
	h.rngMu.Lock()
	defer h.rngMu.Unlock()
	p, _, _ := sudoku.Generate(h.rng)
	return p
}

func (h *findPuzzleHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if !requireGET(w, r) {
		return
	}

	technique := r.URL.Query().Get("technique")
	if technique == "" {
		http.Error(w, "missing required query parameter: technique", http.StatusBadRequest)
		return
	}
	if !sudoku.IsKnownTechnique(technique) {
		known := strings.Join(sudoku.KnownTechniques(), ", ")
		http.Error(w, fmt.Sprintf("unknown technique %q; known: %s", technique, known), http.StatusBadRequest)
		return
	}

	maxAttempts := defaultMaxAttempts
	if s := r.URL.Query().Get("max"); s != "" {
		n, err := strconv.Atoi(s)
		if err != nil || n <= 0 {
			http.Error(w, "max must be a positive integer", http.StatusBadRequest)
			return
		}
		if n > maxAllowedAttempts {
			http.Error(w, fmt.Sprintf("max must not exceed %d", maxAllowedAttempts), http.StatusBadRequest)
			return
		}
		maxAttempts = n
	}

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		if r.Context().Err() != nil {
			return
		}
		puzzle := h.generate()

		result := sudoku.HumanSolve(puzzle)
		for _, iter := range result.Iterations {
			for _, a := range iter {
				if len(a.Steps) > 0 {
					if a.Technique == technique {
						writeJSON(w, findPuzzleResponse{
							Puzzle:    puzzle,
							Technique: technique,
							Attempts:  attempt,
						})
						return
					}
					break // first technique with steps wins; skip the rest of this iteration
				}
			}
		}
	}

	http.Error(w, fmt.Sprintf("no puzzle found after %d attempts", maxAttempts), http.StatusNotFound)
}
