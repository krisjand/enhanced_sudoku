# Enhanced Sudoku

A Sudoku application with a Flutter frontend and Go backend, built as a proof-of-concept for integrating Claude Code into a CI/CD pipeline.

## Prerequisites

This project uses [Hermit](https://github.com/cashapp/hermit) to manage tool versions. Activate the environment before working on the project:

```bash
. ./bin/activate-hermit
```

This will make the correct versions of `go`, `flutter`, and `golangci-lint` available in your shell.

## Project Structure

```
enhanced_sudoku/
├── backend/    # Go backend (HTTP API)
└── frontend/   # Flutter mobile application
```

## Running the Backend

```bash
cd backend
go run .
```

The server starts on `http://localhost:8080`.

## Running the Frontend

```bash
cd frontend
flutter run
```

## Running Tests

**Backend:**
```bash
cd backend
go test ./...
```

**Frontend:**
```bash
cd frontend
flutter test
```

## Linting

```bash
cd backend
golangci-lint run
```
