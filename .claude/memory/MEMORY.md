# Memory Index

- [User Profile](user_profile.md) — experienced Flutter/Go developer, evaluating Claude Code for team CI/CD adoption
- [Collaboration Workflow](project_workflow.md) — full SDLC loop: story → breakdown → implement → PR → review → merge → acceptance test
- [Project Conventions](project_conventions.md) — branching strategy, PR rules, best practices file locations
- [CI Change Detection](feedback_ci_change_detection.md) — never use HEAD^1 HEAD; use origin/$base_ref...HEAD for correct multi-commit PR diff
- [Git Auth](feedback_git_auth.md) — use HTTPS remote (not SSH); SSH agent loses keys between sessions
- [Review Effort](feedback_review_effort.md) — medium for technique PRs, high for architectural PRs, low/skip for docs/infra
- [Time Tracking](feedback_time_tracking.md) — log time per task as a comment on the story's GitHub issue; do it without being asked
- [Project State](project_state.md) — Stories through naked/hidden quadruples done (PR #47, 57 tests); next is forced chains (issue #18)
- [Story Map](story_map.md) — all 19 feature stories with GitHub issue numbers (#8–#26)
- [Deferred Suggestions](reference_deferred_suggestions.md) — GitHub issue #42 is the backlog for SUGGESTION-level review findings not resolved before merge
- [Test Fixtures](feedback_test_puzzles.md) — test_grids/ at project root; [[int]] JSON arrays, convert to Grid literals; full file list inside; never search programmatically
- [Technique Identifiers](feedback_technique_identifiers.md) — technique constants use camelCase string values (e.g. `"nakedSingles"`), not display names
- [X-wing Implementation](xwing_implementation.md) — algorithm, files to create/modify, constants, difficulty slot, existing fixture path
- [Workflow Order](feedback_workflow_order.md) — post task breakdown on the GitHub issue before writing any code (violated on #16, CLAUDE.md tightened)
- [File Access](feedback_file_access.md) — sandbox active (bwrap); restricted to project dir + memory cache; do not access paths outside these two
