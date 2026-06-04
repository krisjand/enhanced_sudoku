---
name: feedback-git-auth
description: Git remote uses HTTPS via gh auth — SSH agent loses keys between sessions
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dbf99497-3c6c-43fd-9830-a79a41396973
---

The SSH agent loses its loaded key between sessions (or after inactivity), causing `git push` to fail with "agent refused operation". The remote has been switched to HTTPS and `gh auth setup-git` was run so the gh CLI token is used as the credential helper.

**Why:** SSH key re-adding requires interactive passphrase entry which Claude Code cannot do.

**How to apply:** Always use HTTPS remote (`https://github.com/krisjand/enhanced_sudoku.git`) for pushes. If a push fails with an SSH error, the remote may have reverted — fix with: `git remote set-url origin https://github.com/krisjand/enhanced_sudoku.git`
