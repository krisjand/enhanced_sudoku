---
name: feedback-flutter-formatting
description: Always run dart format before committing Flutter code — CI enforces it
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e85d7da1-4335-409b-b17e-9dee62afb032
---

Run `dart format lib/` before every commit on Flutter code.

**Why:** The CI Flutter job runs `dart format --output=none --set-exit-if-changed .` and fails on any unformatted file. Unformatted PRs are blocked from merging.

**How to apply:**
- Run `dart format lib/` in the `frontend/` directory before staging any Dart files
- `dart format` is opinionated and has no configuration — accept the canonical style, do not override line length or add config files
- Line length is 80 characters (Dart default)
