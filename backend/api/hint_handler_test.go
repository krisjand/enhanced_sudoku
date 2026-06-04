package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/krisjand/enhanced_sudoku/backend/pkg/sudoku"
)

func TestHintHandler(t *testing.T) {
	// A solved grid for the "already solved" case.
	solvedGrid := sudoku.Grid{
		{5, 3, 4, 6, 7, 8, 9, 1, 2},
		{6, 7, 2, 1, 9, 5, 3, 4, 8},
		{1, 9, 8, 3, 4, 2, 5, 6, 7},
		{8, 5, 9, 7, 6, 1, 4, 2, 3},
		{4, 2, 6, 8, 5, 3, 7, 9, 1},
		{7, 1, 3, 9, 2, 4, 8, 5, 6},
		{9, 6, 1, 5, 3, 7, 2, 8, 4},
		{2, 8, 7, 4, 1, 9, 6, 3, 5},
		{3, 4, 5, 2, 8, 6, 1, 7, 9},
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
			name:   "invalid grid returns 422",
			method: http.MethodPost,
			body: map[string]any{
				"grid": fixtureStandardPuzzle(func(g *sudoku.Grid) { g[0][1] = 5 }),
			},
			wantStatus: http.StatusUnprocessableEntity,
		},
		{
			name:       "solved grid returns solved=true",
			method:     http.MethodPost,
			body:       map[string]any{"grid": solvedGrid},
			wantStatus: http.StatusOK,
			check: func(t *testing.T, body []byte) {
				var resp hintResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if !resp.Solved {
					t.Errorf("expected solved=true, got %+v", resp)
				}
			},
		},
		{
			name:   "candidates omitted — computed from grid, returns a step",
			method: http.MethodPost,
			body:   map[string]any{"grid": fixtureStandardPuzzle()},
			wantStatus: http.StatusOK,
			check: func(t *testing.T, body []byte) {
				var resp hintResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if resp.Step == nil {
					t.Fatalf("expected a step, got solved=%v stuck=%v", resp.Solved, resp.Stuck)
				}
				if resp.Step.Technique == "" {
					t.Error("step technique must not be empty")
				}
				if len(resp.Step.Actions) == 0 {
					t.Error("expected at least one action in the step")
				}
			},
		},
		{
			name:   "explicit candidates — returns a step",
			method: http.MethodPost,
			body: func() map[string]any {
				g := fixtureStandardPuzzle()
				cands := sudoku.Init(g)
				wire := [9][9][]int{}
				for r := 0; r < 9; r++ {
					for c := 0; c < 9; c++ {
						for d := 1; d <= 9; d++ {
							if cands[r][c]&(1<<uint(d-1)) != 0 {
								wire[r][c] = append(wire[r][c], d)
							}
						}
					}
				}
				return map[string]any{"grid": g, "candidates": wire}
			}(),
			wantStatus: http.StatusOK,
			check: func(t *testing.T, body []byte) {
				var resp hintResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if resp.Step == nil {
					t.Fatalf("expected a step, got solved=%v stuck=%v", resp.Solved, resp.Stuck)
				}
			},
		},
		{
			name:   "all-empty candidates — returns stuck=true",
			method: http.MethodPost,
			body:   map[string]any{"grid": fixtureStandardPuzzle(), "candidates": [9][9][]int{}},
			wantStatus: http.StatusOK,
			check: func(t *testing.T, body []byte) {
				var resp hintResponse
				if err := json.Unmarshal(body, &resp); err != nil {
					t.Fatalf("failed to decode response: %v", err)
				}
				if !resp.Stuck {
					t.Errorf("expected stuck=true, got %+v", resp)
				}
			},
		},
	}

	h := newHintHandler()
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

			req := httptest.NewRequest(tt.method, "/puzzle/hint", bytes.NewReader(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			h.ServeHTTP(w, req)

			if w.Code != tt.wantStatus {
				t.Errorf("status = %d, want %d (body: %s)", w.Code, tt.wantStatus, w.Body.String())
			}
			if tt.check != nil && w.Code == tt.wantStatus {
				tt.check(t, w.Body.Bytes())
			}
		})
	}
}
