package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	addr := os.Getenv("PORT")
	if addr == "" {
		addr = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.Handle("/puzzle", newPuzzleHandler())
	mux.Handle("/puzzle/solve", newSolveHandler())

	log.Printf("Server listening on :%s", addr)
	if err := http.ListenAndServe(":"+addr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if !requireGET(w, r) {
		return
	}
	writeJSON(w, map[string]string{"status": "ok"})
}

// decodeJSON decodes the JSON request body into v.
func decodeJSON(r *http.Request, v any) error {
	return json.NewDecoder(r.Body).Decode(v)
}

// requireGET rejects any method other than GET or HEAD with 405.
// Returns false if the request was rejected so the caller can return early.
func requireGET(w http.ResponseWriter, r *http.Request) bool {
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return false
	}
	return true
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
