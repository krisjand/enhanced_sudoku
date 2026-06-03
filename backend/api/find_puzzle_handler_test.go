package main

import (
	"encoding/json"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestFindPuzzleHandler(t *testing.T) {
	tests := []struct {
		name       string
		method     string
		url        string
		wantStatus int
		check      func(t *testing.T, body []byte)
	}{
		{
			name:       "POST is not allowed",
			method:     http.MethodPost,
			url:        "/puzzle/find?technique=nakedSingles",
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "missing technique returns 400",
			method:     http.MethodGet,
			url:        "/puzzle/find",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "unknown technique returns 400",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=Telepathy",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "bad max returns 400",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=nakedSingles&max=0",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "non-integer max returns 400",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=nakedSingles&max=abc",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "max exceeding limit returns 400",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=nakedSingles&max=10001",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "unknown maxPropagation returns 400",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=forcedChains&maxPropagation=Telepathy",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:       "maxPropagation=forcedChains is rejected with 400",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=forcedChains&maxPropagation=forcedChains",
			wantStatus: http.StatusBadRequest,
		},
		{
			// Seed 1 produces only Naked/Hidden Singles wins; Naked Triples never wins in
			// 1 attempt, so the handler exhausts max and returns 404.
			name:       "technique not found within max attempts returns 404",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=nakedTriples&max=1",
			wantStatus: http.StatusNotFound,
		},
		{
			// Naked Singles wins on every puzzle; seed 1 confirms it wins in the first attempt.
			name:       "known technique found returns 200 with puzzle and attempt count",
			method:     http.MethodGet,
			url:        "/puzzle/find?technique=nakedSingles&max=1",
			wantStatus: http.StatusOK,
			check: func(t *testing.T, body []byte) {
				var resp findPuzzleResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if resp.Technique != "nakedSingles" {
					t.Errorf("technique = %q, want %q", resp.Technique, "nakedSingles")
				}
				if resp.Attempts <= 0 {
					t.Errorf("attempts = %d, want > 0", resp.Attempts)
				}
				if !resp.Puzzle.IsValid() {
					t.Error("puzzle is not a valid grid")
				}
				if resp.Puzzle.IsSolved() {
					t.Error("puzzle has no empty cells — should be a partial grid")
				}
			},
		},
	}

	// All tests use seed=1 so the 404 case is deterministic.
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h := newFindPuzzleHandlerWithRng(rand.New(rand.NewSource(1)))
			req := httptest.NewRequest(tt.method, tt.url, nil)
			w := httptest.NewRecorder()

			h.ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d (body: %s)", w.Code, tt.wantStatus, w.Body.String())
			}
			if tt.check != nil && w.Code == tt.wantStatus {
				if ct := w.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
					t.Errorf("Content-Type = %q, want application/json", ct)
				}
				tt.check(t, w.Body.Bytes())
			}
		})
	}
}
