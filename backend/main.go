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
	writeJSON(w, map[string]string{"status": "ok"})
}

func puzzleHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	puzzle, solution, dur := sudoku.Generate(rng)
	writeJSON(w, struct {
		Puzzle      sudoku.Grid `json:"puzzle"`
		Solution    sudoku.Grid `json:"solution"`
		GeneratedMs int64       `json:"generated_ms"`
		GeneratedUs int64       `json:"generated_us"`
	}{
		Puzzle:      puzzle,
		Solution:    solution,
		GeneratedMs: dur.Milliseconds(),
		GeneratedUs: dur.Microseconds(),
	})
}

// writeJSON marshals v to JSON and writes it to w.
// If marshalling fails, it returns a 500 to the client before any bytes are written.
func writeJSON(w http.ResponseWriter, v any) {
	data, err := json.Marshal(v)
	if err != nil {
		log.Printf("writeJSON: failed to marshal response: %v", err)
		http.Error(w, "internal server error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	if _, err := w.Write(data); err != nil {
		log.Printf("writeJSON: failed to write response: %v", err)
	}
}
