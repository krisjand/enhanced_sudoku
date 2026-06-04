---
name: feedback-ci-change-detection
description: Never use HEAD^1 HEAD for PR change detection — use origin/$base_ref...HEAD
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 51113308-feef-4117-9dc3-c5925d806cd1
---

Do not suggest `git diff --name-only HEAD^1 HEAD` for detecting changed files in a PR.

**Why:** This only compares the last two commits. In a multi-commit PR, changes from earlier commits are invisible, causing CI jobs to be incorrectly skipped.

**How to apply:** Always use `fetch-depth: 0` on `actions/checkout` combined with `git diff --name-only origin/$base_ref...HEAD`. The three-dot diff requires a shared history — shallow clones have no common ancestor and will fail with "no merge base". `fetch-depth: 0` is the only reliable approach.
