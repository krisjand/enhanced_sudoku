package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

func TestHealthHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()

	healthHandler(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
		t.Errorf("expected Content-Type application/json, got %q", ct)
	}
	if !strings.Contains(w.Body.String(), `"status"`) {
		t.Errorf("expected body to contain status field, got %q", w.Body.String())
	}
}

func TestHealthHandlerMethodNotAllowed(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/health", nil)
	w := httptest.NewRecorder()

	healthHandler(w, req)

	if w.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", w.Code)
	}
}

func TestPuzzleHandler(t *testing.T) {
	tests := []struct {
		name       string
		method     string
		wantStatus int
	}{
		{name: "GET returns puzzle", method: http.MethodGet, wantStatus: http.StatusOK},
		{name: "POST is not allowed", method: http.MethodPost, wantStatus: http.StatusMethodNotAllowed},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/puzzle", nil)
			w := httptest.NewRecorder()

			puzzleHandler(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d", w.Code, tt.wantStatus)
			}
			if tt.wantStatus != http.StatusOK {
				return
			}

			if ct := w.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
				t.Errorf("Content-Type = %q, want application/json", ct)
			}

			var resp struct {
				Puzzle      sudoku.Grid `json:"puzzle"`
				Solution    sudoku.Grid `json:"solution"`
				GeneratedMs int64       `json:"generated_ms"`
			}
			if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
				t.Fatalf("failed to decode response: %v", err)
			}
			if !resp.Solution.IsSolved() {
				t.Error("solution is not fully solved")
			}
			if !resp.Puzzle.IsValid() {
				t.Error("puzzle is not a valid grid")
			}
			if resp.GeneratedMs < 0 {
				t.Errorf("generated_ms = %d, want >= 0", resp.GeneratedMs)
			}
		})
	}
}
