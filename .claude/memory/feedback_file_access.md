---
name: feedback-file-access
description: Sandbox is configured to restrict file access to project directory and memory cache only
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 741a3ce2-f901-4f2b-a280-0f981563661a
---

Sandbox is enabled in `.claude/settings.json` (project settings). Access is restricted to:
- `/home/kristian-joten-andersen/git/enhanced_sudoku/` (project root, default working directory)
- `/home/kristian-joten-andersen/.claude/projects/-home-kristian-joten-andersen-git-enhanced-sudoku/memory/` (memory cache, explicitly allowed)

**Why:** User wants hard OS-level isolation. bwrap is installed on this machine, so the sandbox is genuinely enforced — attempts to access files outside these paths will receive a kernel-level EACCES.

**How to apply:** Do not attempt to read, write, or access any files outside these two directories. Do not suggest paths outside the project. If a task requires accessing files elsewhere (e.g. corpus files generated outside the repo), tell the user and ask them to move the files or adjust the sandbox config.
