package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestPuzzleHandler(t *testing.T) {
	tests := []struct {
		name       string
		method     string
		wantStatus int
	}{
		{name: "GET returns puzzle", method: http.MethodGet, wantStatus: http.StatusOK},
		{name: "HEAD returns 200", method: http.MethodHead, wantStatus: http.StatusOK},
		{name: "POST is not allowed", method: http.MethodPost, wantStatus: http.StatusMethodNotAllowed},
	}
	h := newPuzzleHandler()
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/puzzle", nil)
			w := httptest.NewRecorder()

			h.ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d", w.Code, tt.wantStatus)
			}
			if tt.wantStatus != http.StatusOK || tt.method == http.MethodHead {
				return
			}

			if ct := w.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
				t.Errorf("Content-Type = %q, want application/json", ct)
			}

			var resp puzzleResponse
			if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
				t.Fatalf("failed to decode response: %v", err)
			}
			if !resp.Solution.IsSolved() {
				t.Error("solution is not fully solved")
			}
			if !resp.Puzzle.IsValid() {
				t.Error("puzzle is not a valid grid")
			}
			if resp.Puzzle.IsSolved() {
				t.Error("puzzle has no empty cells — should be a partial grid")
			}
			if resp.GeneratedUs < 0 {
				t.Errorf("generated_us = %d, want >= 0", resp.GeneratedUs)
			}
			if resp.Difficulty == "" {
				t.Error("difficulty is empty")
			}
			if resp.TechniquesUsed == nil {
				t.Error("techniques_used is nil")
			}
		})
	}
}
