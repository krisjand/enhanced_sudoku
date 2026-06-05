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
   - **CRITICAL and WARNING** → MUST be posted as **inline PR comments** on the relevant line using `gh api repos/{owner}/{repo}/pulls/{pr}/comments` with `commit_id`, `path`, `line` (integer), and `side: "RIGHT"`. Fall back to a top-level comment **only** when the code no longer exists in the PR (e.g. the line was removed in a later commit). Never post a CRITICAL or WARNING as a top-level comment if the code is still present in the diff.
   - **SUGGESTION** → post as a top-level PR comment (reference file + line in the body). This avoids unresolved threads that would block merging. Log deferred suggestions in GitHub issue #42. When addressing a PR review, evaluate each suggestion on impact vs. effort — act on it if worthwhile, otherwise leave it deferred.
6. **Address comments** — resolve all CRITICAL and WARNING comments; **immediately after fixing each one, resolve its thread** via the GitHub GraphQL API `resolveReviewThread` mutation. Do not wait until all fixes are done — resolve each thread as soon as the fix is committed. Then re-request review.
7. **Re-review if production code changed** — if step 6 touched production code (not test-only changes), perform another full review and repeat from step 6 until clean; test-only fixes do not require a new review pass
8. **Ask before merging** — always confirm with the user before merging the PR
9. **Acceptance test** — after merging, verify all ACs are met
10. **Bug fix loop** — if the acceptance test finds failures, open a new PR and re-enter the loop from step 4

Learnings from reviews and acceptance tests are documented in `docs/best-practices/` **and** in the relevant memory files under `.claude/` (system memory). Both must be updated — best-practices files hold concrete code-level patterns; memory files hold behavioral rules and process learnings.

## Time Tracking

Time spent per task is logged as a comment on the GitHub issue for each story, not in the repository. Log time **without being asked** after each task completes. Each entry records: PR, AI role (developer / reviewer / tester), task, start time, end time, and duration.

**Capturing timestamps:** Use `date +"%H:%M:%S"` in bash to get the current time. Run it at **both the start and the end** of each task phase — never invent or estimate timestamps. The user may take breaks between phases, so timestamps must reflect actual wall-clock moments, not inferred times.

Tracked phases and capture points:
- **Task breakdown** — capture start when beginning the breakdown; capture end and post after the breakdown comment is posted on the issue
- **Implementation** — capture start immediately after posting the breakdown comment; capture end and post when the PR is opened
- **Code review** — capture start when beginning the review; capture end and post after posting the review comment on the PR
- **Acceptance test** — capture start when beginning the acceptance test; capture end and post after posting the acceptance result on the issue

| PR | Role | Task | Started | Completed | Duration |
|----|------|------|---------|-----------|----------|
| — | Developer | Task breakdown | HH:MM | HH:MM | X min |
| ... | Developer | Implementation | HH:MM | HH:MM | X min |
| ... | Reviewer | Code review (pass N) | HH:MM | HH:MM | X min |
| ... | Tester | Acceptance test | HH:MM | HH:MM | X min |

## Frontend Development

Frontend stories differ from backend stories in three ways: story creation, merge ownership, and acceptance testing.

### Story creation

For frontend epics (Foundation, Game Board, Game Management, Scores & Stats, Tutorial, Settings, Forced Chains Helper), the AI creates the stories autonomously — no user input is needed to define them. Stories are created as GitHub issues referencing their parent epic, with acceptance criteria written by the AI.

### Autonomy

Once a frontend story is started, proceed through every phase without asking the user to continue:

1. **Task breakdown** — post on the issue before writing any code
2. **Implement** — write production code; Flutter UI stories do not require unit tests unless logic is non-trivial
3. **Create PR** — open a pull request referencing the issue
4. **Code review** — same three-level system (CRITICAL / WARNING / SUGGESTION) and inline comment rules as the backend
5. **Address comments** — resolve all CRITICAL and WARNING, resolve threads via GraphQL, re-request review
6. **Re-review if production code changed** — same rule as backend
7. **Pause: owner PR approval** — post a summary comment on the PR containing:
   - The AC checklist (checkboxes)
   - Step-by-step test instructions: what to do in the app and what to expect to see for each AC
   The owner follows the instructions, verifies visual output, checks off ACs, then approves and merges. Do not merge the PR yourself.
8. **Pause: story close** — post the final time log and wait for the owner to close the issue

The only two points where execution pauses are **owner PR approval** (step 7) and **story close** (step 8).

### Acceptance testing

The AI cannot capture screenshots in this environment, so visual output cannot be verified programmatically. Responsibilities are split:

- **AI verifies:** the app compiles (`flutter build web` / `flutter test`) and the code is structurally correct via review.
- **Owner verifies:** visual output — runs the app in their browser and confirms the ACs look correct **before approving the PR**.

Post the ACs as a checklist in a comment on the PR. The owner checks them off while reviewing, then approves and merges. There is no separate post-merge acceptance test phase for frontend stories.

### Time tracking (frontend)

Same format as backend — all phases for a story in one table on the story's GitHub issue. Update the same comment (or append a new comment with the full updated table) after each phase. Do not log in the repository.

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
