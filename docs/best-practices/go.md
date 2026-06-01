# Go Best Practices

This file documents Go-specific best practices learned during development.

## Error handling

- Never silently drop errors, including from `json.Encoder.Encode()`. If the status code is already written, log the error instead.
- HTTP handlers should explicitly check `r.Method` and return `405 Method Not Allowed` for unexpected methods.
- Always accept HEAD alongside GET — clients and load balancers use HEAD for liveness checks. Use a shared helper: `if r.Method != http.MethodGet && r.Method != http.MethodHead`.
- Marshal JSON to a buffer (`json.Marshal`) before writing to the `ResponseWriter`. `json.NewEncoder(w).Encode` commits the 200 status on the first write — if marshalling then fails, you can no longer send a 500. With `json.Marshal` you detect the error before any bytes are sent.

## Configuration

- Never hardcode ports or addresses. Use `os.Getenv("PORT")` with a sensible default. This makes the app container-friendly from the start.

## Linting

- Always commit a `.golangci.yml` config file alongside Go code. Without it, `golangci-lint` uses its default linter set which can change between versions and produce unexpected failures.
- Run `golangci-lint` before `go test` in CI — linting is faster and catches issues before spending time on tests.

## HTTP handler design

- Give stateful handlers a struct with their dependencies as fields, a `newX()` constructor, and a `ServeHTTP` method. Register with `mux.Handle` so the struct satisfies `http.Handler` directly. This keeps all mutable state encapsulated and makes the handler independently testable.
- `*rand.Rand` (created with `rand.New()`) is **not** goroutine-safe. HTTP handlers run in separate goroutines — protect a shared instance with a `sync.Mutex`, or create a new instance per request. The global `rand` package functions are safe since Go 1.20, but `rand.New()` instances are not.

## API design

- Don't expose redundant fields that differ only in unit (e.g. `generated_ms` and `generated_us`). One subsumes the other — expose the most precise value and let clients convert. Redundant fields invite misinterpretation: callers may treat them as clock components and compute `ms*1000 + us`, overstating the total.

## Testing

- Test HTTP handlers directly using `httptest.NewRecorder()` and `httptest.NewRequest()` — no need to spin up a real server.
- Assert the full response contract in tests: status code, `Content-Type` header, and response body shape.
- Use table-driven tests for every exported function, even those with a single case — makes it easy to add cases later without restructuring.
- Return test fixtures from functions (not package-level variables) and accept optional `func(*T)` modifiers. This keeps fixtures reusable while allowing per-test mutations inline: `fixtureX(func(x *X) { x.Field = value })`.
- Put shared fixtures used across multiple test files in a `testdata_test.go` file in the same package. Duplicating fixture data across files causes silent drift.
- When testing a response that should be a partial grid, assert `!grid.IsSolved()` — `IsValid()` alone passes for a fully solved grid and would not catch a puzzle/solution swap.

## Performance

- Use `math/bits.OnesCount16` / `TrailingZeros16` instead of manual bit-counting loops — these compile to single hardware instructions (POPCNT, BSF/TZCNT) on x86/ARM.
- In recursive algorithms, avoid recomputing derived state at every level. Pass pre-computed state as a parameter and update it incrementally. For backtracking specifically, Go value types (arrays, structs) copy on assignment — `next := state` gives a clean copy for the next level with zero heap allocation, making backtracking state management both safe and fast.

## Deferred improvements (from Story #3 review)

The following were identified in the PR #29 review and deliberately deferred:

- **`shuffledDigits` allocates a `[]uint8` per recursive call.** Because the slice is returned across a function boundary it escapes to the heap. `solve`'s original in-place bitmask loop was allocation-free; `backtrackWith` introduced a small allocation per node for both paths. Fix: inline the digit extraction into `backtrackWith` using a `[9]uint8` stack buffer and a length counter, or pass a `*[9]uint8` scratch buffer from the caller. Revisit if profiling shows generation is a bottleneck.
- **`removeClues` re-runs `Init` on every `HasUniqueSolution` call (up to 81 times).** `Init` scans all 81 cells against their 27 peers per call. An incremental alternative: compute `Init(puzzle)` once before the loop, then derive the updated `Candidates` for each tentative removal with a single `Set`/undo operation. Revisit if server-side batch puzzle generation becomes a hot path.
