# Go Best Practices

This file documents Go-specific best practices learned during development.

## Error handling

- Never silently drop errors, including from `json.Encoder.Encode()`. If the status code is already written, log the error instead.
- HTTP handlers should explicitly check `r.Method` and return `405 Method Not Allowed` for unexpected methods.

## Configuration

- Never hardcode ports or addresses. Use `os.Getenv("PORT")` with a sensible default. This makes the app container-friendly from the start.

## Linting

- Always commit a `.golangci.yml` config file alongside Go code. Without it, `golangci-lint` uses its default linter set which can change between versions and produce unexpected failures.
- Run `golangci-lint` before `go test` in CI — linting is faster and catches issues before spending time on tests.

## Testing

- Test HTTP handlers directly using `httptest.NewRecorder()` and `httptest.NewRequest()` — no need to spin up a real server.
- Assert the full response contract in tests: status code, `Content-Type` header, and response body shape.
