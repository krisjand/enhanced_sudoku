---
name: feedback-time-tracking
description: "Always log time per task as a comment on the story's GitHub issue"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 18994ac3-aa4e-4767-869c-c271dd3a3e83
---

Log time for every task as a comment on the story's GitHub issue — not in the repo.

**Why:** Agreed workflow in CLAUDE.md. Timestamps must be accurate — never invented or estimated, as fabricated times were caught during the hidden triples story. The user may take breaks between phases, so start and end must both be captured at the actual moment.

**How to apply:**
- Use `date +"%H:%M:%S"` in bash to capture the actual current time — never guess or invent timestamps
- Capture **both start and end** of each phase:
  - **Task breakdown** — start when beginning breakdown work; end and post after the breakdown comment is on the issue
  - **Implementation** — start immediately after posting the breakdown comment; end and post when the PR is opened
  - **Code review** — start when beginning the review; end and post after the review comment is on the PR
  - **Acceptance test** — start when beginning the acceptance test; end and post after the acceptance result is on the issue
- Post a time log comment on the story's GitHub issue after each phase completes
- Format: PR, AI role (developer / reviewer / tester), task, start time, end time, duration
- Role options: Developer (task breakdown / writing code), Reviewer (code review), Tester (acceptance test)
- Do this even when the user doesn't ask — it is a standing agreement
