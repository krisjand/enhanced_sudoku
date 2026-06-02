package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

func TestSolveHandler(t *testing.T) {
	standardPuzzle := sudoku.Grid{
		{5, 3, 0, 0, 7, 0, 0, 0, 0},
		{6, 0, 0, 1, 9, 5, 0, 0, 0},
		{0, 9, 8, 0, 0, 0, 0, 6, 0},
		{8, 0, 0, 0, 6, 0, 0, 0, 3},
		{4, 0, 0, 8, 0, 3, 0, 0, 1},
		{7, 0, 0, 0, 2, 0, 0, 0, 6},
		{0, 6, 0, 0, 0, 0, 2, 8, 0},
		{0, 0, 0, 4, 1, 9, 0, 0, 5},
		{0, 0, 0, 0, 8, 0, 0, 7, 9},
	}

	tests := []struct {
		name       string
		method     string
		body       any
		wantStatus int
		check      func(t *testing.T, body []byte)
	}{
		{
			name:       "GET is not allowed",
			method:     http.MethodGet,
			body:       nil,
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "invalid JSON returns 400",
			method:     http.MethodPost,
			body:       "not json",
			wantStatus: http.StatusBadRequest,
		},
		{
			name:   "invalid puzzle (duplicate digit) returns 422",
			method: http.MethodPost,
			body: map[string]any{"puzzle": sudoku.Grid{
				{5, 5, 0, 0, 7, 0, 0, 0, 0}, // duplicate 5 in row 0
				{6, 0, 0, 1, 9, 5, 0, 0, 0},
				{0, 9, 8, 0, 0, 0, 0, 6, 0},
				{8, 0, 0, 0, 6, 0, 0, 0, 3},
				{4, 0, 0, 8, 0, 3, 0, 0, 1},
				{7, 0, 0, 0, 2, 0, 0, 0, 6},
				{0, 6, 0, 0, 0, 0, 2, 8, 0},
				{0, 0, 0, 4, 1, 9, 0, 0, 5},
				{0, 0, 0, 0, 8, 0, 0, 7, 9},
			}},
			wantStatus: http.StatusUnprocessableEntity,
		},
		{
			name:       "valid puzzle returns 200 with solve result",
			method:     http.MethodPost,
			body:       map[string]any{"puzzle": standardPuzzle},
			wantStatus: http.StatusOK,
			check: func(t *testing.T, body []byte) {
				var resp solveResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if !resp.Solved {
					t.Error("expected puzzle to be solved")
				}
				if resp.Grid.IsSolved() == false {
					t.Error("response grid is not fully solved")
				}
				if len(resp.Iterations) == 0 {
					t.Error("expected at least one iteration")
				}
				// Every attempt must have a technique name.
				for i, iter := range resp.Iterations {
					for j, attempt := range iter.Attempts {
						if attempt.Technique == "" {
							t.Errorf("iteration %d attempt %d: empty technique", i, j)
						}
					}
				}
			},
		},
	}

	h := newSolveHandler()
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var bodyBytes []byte
			if s, ok := tt.body.(string); ok {
				bodyBytes = []byte(s)
			} else if tt.body != nil {
				var err error
				bodyBytes, err = json.Marshal(tt.body)
				if err != nil {
					t.Fatalf("failed to marshal request body: %v", err)
				}
			}

			req := httptest.NewRequest(tt.method, "/puzzle/solve", bytes.NewReader(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			h.ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d", w.Code, tt.wantStatus)
			}
			if tt.check != nil && w.Code == tt.wantStatus {
				tt.check(t, w.Body.Bytes())
			}
		})
	}
}
