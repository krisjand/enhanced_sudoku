# CLAUDE.md

This file documents the collaboration workflow, conventions, and rules for this project.

## Development Workflow

Every feature follows this loop **in strict order**. Do not skip or reorder steps.

1. **User story** — define a story with acceptance criteria (ACs)
2. **Task breakdown** — identify files to change and the type of changes required; post the breakdown as a comment on the GitHub issue **before writing any code**
3. **Implement** — write production code and unit tests
4. **Create PR** — open a pull request; reference the issue in the body (`Closes #<issue-number>`)
5. **Code review** — perform a review and tag every comment with one of three levels:
   - `CRITICAL` — must be resolved before merge
   - `WARNING` — must be resolved before merge
   - `SUGGESTION` — optional improvement, does not block merge
   - **CRITICAL and WARNING** → post as inline PR comments on the relevant line. Fall back to a top-level comment only when the code no longer exists in the PR.
   - **SUGGESTION** → post as a top-level PR comment (reference file + line in the body). This avoids unresolved threads that would block merging. Log deferred suggestions in GitHub issue #42. When addressing a PR review, evaluate each suggestion on impact vs. effort — act on it if worthwhile, otherwise leave it deferred.
6. **Address comments** — resolve all CRITICAL and WARNING comments; resolve each thread via the GitHub GraphQL API, then re-request review
7. **Re-review if production code changed** — if step 6 touched production code (not test-only changes), perform another full review and repeat from step 6 until clean; test-only fixes do not require a new review pass
8. **Ask before merging** — always confirm with the user before merging the PR
9. **Acceptance test** — after merging, verify all ACs are met
10. **Bug fix loop** — if the acceptance test finds failures, open a new PR and re-enter the loop from step 4

Learnings from reviews and acceptance tests are documented in `docs/best-practices/`.

## Time Tracking

Time spent per task is logged as a comment on the GitHub issue for each story, not in the repository. Log time **without being asked** after each task (implementation, review, acceptance test). Each entry records: PR, AI role (developer / reviewer / tester), task, start time, end time, and duration.

| PR | Role | Task | Started | Completed | Duration |
|----|------|------|---------|-----------|----------|
| ... | Developer | Implementation | HH:MM | HH:MM | X min |
| ... | Reviewer | Code review (pass N) | HH:MM | HH:MM | X min |
| ... | Tester | Acceptance test | HH:MM | HH:MM | X min |

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
│   └── best-practices/   # Language- and workflow-specific best practices
│       ├── general.md
│       ├── flutter.md
│       └── go.md
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
