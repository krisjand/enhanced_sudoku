# General Best Practices

This file documents workflow, branching, and PR conventions learned during development.

## Code Reviews

- Always post review comments as inline PR comments on the specific line of code they refer to. Only post as a top-level review comment when the relevant code no longer exists in the PR (e.g. the file or line was removed or changed in a later commit).
- Post SUGGESTION-level comments as **top-level PR comments** (not inline). Inline comments create review threads that must be resolved before merging — a SUGGESTION that is intentionally deferred would block the merge. Top-level comments are informational and do not gate the merge.
- All open inline review threads (CRITICAL and WARNING) must be resolved before merging. SUGGESTION threads that are intentionally deferred must also be resolved (with a note explaining the deferral) before merging.
- Match review effort to the type of change — high-effort reviews are expensive in context/time and should be reserved for PRs that introduce new patterns or architecture:

  | PR type | Effort level |
  |---|---|
  | New technique function following an established pattern | `medium` |
  | Human solver, API endpoints, new data types, new patterns | `high` |
  | Refactors, infrastructure, docs | `low` or skip |

  Use `/code-review medium --comment` for technique PRs (naked pairs, hidden pairs, etc.). Medium is correctness-focused with fewer angles — it catches real bugs without the full cleanup/altitude sweep.

## Branching & PRs

- Always rebase feature branches on `main` before opening a PR.
- Squash-merge all PRs to keep `main` history clean and linear.
- One PR per feature/task — smaller PRs are faster to review and easier to revert.
- Add `concurrency` groups to CI workflows to cancel stale runs when a new commit is pushed — avoids wasting runner minutes.

## Rebasing after a squash-merge

When a feature branch contains commits that were already squash-merged into `main`, a plain `git rebase origin/main` replays every commit including the ones already merged — causing conflicts with the squash commit on `main`.

Fix: use `--onto` to replay only the commits that are not yet on `main`:

```bash
git rebase --onto origin/main <last-already-merged-commit>
```

`<last-already-merged-commit>` is the SHA of the last commit on the feature branch whose work is already reflected in `main` (i.e. the tip of the previous PR's branch before the squash). All commits **after** that SHA are replayed cleanly on top of `main`.

Follow with `git push --force-with-lease` to update the remote branch.

## GitHub Actions

- Always pin third-party actions to an immutable commit SHA, not a mutable tag (`@v1`). Include the tag as a comment for readability: `@<sha> # v1`. This prevents supply chain attacks if a tag is moved or a repo is compromised.
- Use a single CI workflow that always triggers on PRs rather than multiple workflow files with `paths` filters. A dedicated `changes` job detects which areas were modified and downstream jobs run conditionally — this allows both jobs to be added as required status checks (skipped jobs satisfy required checks in GitHub branch protection).
- Detect changed paths in a PR using `fetch-depth: 0` on `actions/checkout` combined with `git diff --name-only origin/$base_ref...HEAD`. The three-dot diff requires a shared history between the PR branch and the base — shallow clones have no common ancestor visible to git and will fail with "no merge base". Do not use `HEAD^1 HEAD` — it only compares the last two commits and breaks for multi-commit PRs.
- Pin Docker image tags to specific versions (`flutter-ci:3.44.0`) rather than `:latest`. Using `:latest` picks up image rebuilds silently; an explicit tag makes tool version changes a deliberate, visible commit — consistent with pinning GitHub Actions to commit SHAs.
