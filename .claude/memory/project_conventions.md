---
name: project-conventions
description: "Branching strategy, PR rules, and best practices file locations"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 51113308-feef-4117-9dc3-c5925d806cd1
---

**Branching strategy:** `main` + feature branches.

**Why:** Keeps history clean and PRs small and reviewable.

**How to apply:**
- Every feature branch must be rebased on `main` before merging
- All PRs are squash-merged into a single commit on `main`
- One PR per feature/task — keeps PRs small and easy to review
- Never merge a branch with unresolved CRITICAL or WARNING review comments

**Best practices file locations:**
- `docs/best-practices/general.md` — workflow, branching, PR conventions
- `docs/best-practices/flutter.md` — Flutter/Dart specific
- `docs/best-practices/go.md` — Go specific
