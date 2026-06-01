# CLAUDE.md

This file documents the collaboration workflow, conventions, and rules for this project.

## Development Workflow

Every feature follows this loop:

1. **User story** — define a story with acceptance criteria (ACs)
2. **Task breakdown** — identify files to change and the type of changes required; post the breakdown as a comment on the GitHub issue before starting implementation
3. **Implement** — write code and unit tests, then open a PR
4. **Code review** — post findings as inline PR comments on the relevant line of code; fall back to a top-level review comment only when the code no longer exists in the PR. Comments are tagged with one of three levels:
   - `CRITICAL` — must be resolved before merge
   - `WARNING` — must be resolved before merge
   - `SUGGESTION` — optional improvement, can be deferred
5. **Review loop** — address all CRITICAL and WARNING comments, resolve the comment threads via the GitHub GraphQL API, then re-request review; repeat until clean
6. **Merge**
7. **Acceptance test** — verify all ACs are met after merge
8. **Bug fix loop** — if the acceptance test finds failures, open a new PR and re-enter the review loop

Learnings from reviews and acceptance tests are documented in `docs/best-practices/`.

## Branching Strategy

- `main` + feature branches
- Branch naming: `feature/<issue-number>-<short-description>` (e.g. `feature/1-project-scaffolding`)
- Feature branches must be **rebased on `main`** before merging
- All PRs are **squash-merged** into a single commit on `main`
- Never merge a PR with unresolved CRITICAL or WARNING review comments

## PR Conventions

- One PR per feature/task — keep PRs small and easy to review
- PR title format: `#<issue-number>: <short description>`
- Reference the issue in the PR body: `Closes #<issue-number>`

## Project Structure

```
enhanced_sudoku/
├── bin/                  # Hermit-managed tool binaries (Go, Flutter, golangci-lint)
├── backend/              # Go backend application
├── frontend/             # Flutter frontend application
├── docs/
│   ├── best-practices/   # Language- and workflow-specific best practices
│   │   ├── general.md
│   │   ├── flutter.md
│   │   └── go.md
│   └── time-log.md       # Time tracking per story/task
└── .github/
    └── workflows/        # GitHub Actions CI pipelines
```

## Tool Versions (managed by Hermit)

| Tool          | Version  |
|---------------|----------|
| Go            | 1.26.3   |
| Flutter       | 3.44.0   |
| golangci-lint | 2.12.2   |

Activate Hermit before working on this project:

```bash
. ./bin/activate-hermit
```
