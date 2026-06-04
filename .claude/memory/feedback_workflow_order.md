---
name: feedback-workflow-order
description: Task breakdown must be posted to the GitHub issue before writing any code
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fc8fb8da-37b9-4218-a328-1d36fc440fd5
---

Always post the task breakdown comment on the GitHub issue **before writing any code**. This was violated during hidden triples (issue #16) — implementation started before the breakdown was posted. The CLAUDE.md was updated to make this explicit.

**Why:** The task breakdown is a planning checkpoint, not a retrospective. Posting it first ensures scope is agreed before work begins, and keeps the issue history accurate.

**How to apply:** When starting a new story, the very first action is to post the breakdown on the issue. Only then start implementing. See [[project-workflow]] for the full ordered steps.
