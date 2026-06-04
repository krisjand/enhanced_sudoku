---
name: project-workflow
description: Full SDLC collaboration loop agreed for this project
metadata: 
  node_type: memory
  type: project
  originSessionId: 51113308-feef-4117-9dc3-c5925d806cd1
---

The agreed development workflow for every feature — **strict order, no skipping**:

1. **User story** — define story with acceptance criteria (ACs)
2. **Task breakdown** — identify files to change and type of changes; post as a comment on the GitHub issue **before writing any code**
3. **Implement** — write production code + unit tests
4. **Create PR** — open a pull request referencing the issue
5. **Code review** — three comment levels:
   - `CRITICAL` — must be fixed before merge
   - `WARNING` — must be fixed before merge
   - `SUGGESTION` — optional improvement; does NOT block merge
   - **CRITICAL and WARNING** → post as **inline comments** on the specific line. Only use a top-level review comment when the relevant code no longer exists in the PR.
   - **SUGGESTION** → post as a **top-level PR comment** (reference the file + line in the body). This avoids creating unresolved threads that would block merging.
   - **Deferred suggestions** → log in GitHub issue #42 ("Deferred suggestions from code reviews") with columns: PR, file, line, suggestion text.
   - When addressing a PR review, evaluate each suggestion on **impact vs. effort** — act on it if worthwhile, otherwise leave it deferred. Suggestions are never required.
   - **Resolve comment threads** via the GitHub GraphQL API (`resolveReviewThread` mutation) once a CRITICAL/WARNING is addressed, so the PR can be merged.
6. **Address comments** — fix all CRITICAL + WARNING, resolve threads, re-request review
7. **Re-review if production code changed** — test-only fixes do not require a new review pass; production code changes do
8. **Ask before merging** — always confirm with the user before merging
9. **Acceptance test** — verify all ACs are met post-merge
10. **Bug fix loop** — if tester finds failures, open a new PR and re-enter from step 4

**Learnings** are documented in `docs/best-practices/` after each review/test cycle to prevent repeating mistakes.

**Time tracking:** Log time as a comment on the story's GitHub issue (not in the repo). Each entry: PR, AI role (developer/reviewer/tester), task, start time, end time, duration. Split by task — implementation, each review pass, and acceptance test recorded separately.

**Roles (ramp-up phase):** Claude handles developer, reviewer, and tester. User also verifies reviews and test results. Autonomy increases as user gains confidence in output quality.

**Why:** This project is a PoC to evaluate Claude Code for team CI/CD adoption — quality and process fidelity matter as much as output.

---

## Frontend workflow (epics #65–#71)

Differs from backend in three ways:

### Story creation
AI creates stories autonomously for frontend epics — no user input needed to define them.

### Autonomy
Proceed without pausing except at two explicit checkpoints:
1. **Owner PR approval** — post a summary on the PR and wait; do NOT merge the PR yourself
2. **Story close** — post the final time log and wait for the owner to close

All other steps (breakdown → implement → PR → review → address → re-review) run automatically.

### Acceptance testing
- Before playable game board: code-level acceptance (compile, route check, API calls)
- Once game board is playable: owner performs manual testing in the app; post ACs as a checklist and wait for owner confirmation before closing

### Time tracking
All phases in one growing table on the story's GitHub issue. Update in place (append to same comment or post new comment with full updated table). Same columns: PR, Role, Task, Started, Completed, Duration.
