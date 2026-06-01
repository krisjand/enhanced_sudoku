package main

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

var rng = rand.New(rand.NewSource(time.Now().UnixNano()))

func main() {
	addr := os.Getenv("PORT")
	if addr == "" {
		addr = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/puzzle", puzzleHandler)

	log.Printf("Server listening on :%s", addr)
	if err := http.ListenAndServe(":"+addr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]string{"status": "ok"}); err != nil {
		log.Printf("health: failed to encode response: %v", err)
	}
}

func puzzleHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	puzzle, solution, dur := sudoku.Generate(rng)
	resp := struct {
		Puzzle      sudoku.Grid `json:"puzzle"`
		Solution    sudoku.Grid `json:"solution"`
		GeneratedMs int64       `json:"generated_ms"`
	}{
		Puzzle:      puzzle,
		Solution:    solution,
		GeneratedMs: dur.Milliseconds(),
	}
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("puzzle: failed to encode response: %v", err)
	}
}
