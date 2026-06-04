---
name: feedback-review-effort
description: Match code review effort level to PR type to conserve context/quota
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dbf99497-3c6c-43fd-9830-a79a41396973
---

High-effort reviews (7 finder angles × 6 candidates + verifiers) are expensive in context and time. They are overkill for small, pattern-following PRs.

**Why:** Previous technique PRs (naked singles, hidden singles) consumed large amounts of session context running full high-effort reviews that mostly produced SUGGESTIONs.

**How to apply:**
- New technique function following an established pattern → `/code-review medium --comment`
- Human solver, API endpoints, new data types, new patterns → `/code-review high --comment` (or no flag, defaults to high)
- Refactors, infrastructure, docs → `/code-review low --comment` or skip

This is also documented in `docs/best-practices/general.md`.
