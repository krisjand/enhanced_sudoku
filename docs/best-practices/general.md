# General Best Practices

This file documents workflow, branching, and PR conventions learned during development.

## Branching & PRs

- Always rebase feature branches on `main` before opening a PR.
- Squash-merge all PRs to keep `main` history clean and linear.
- One PR per feature/task — smaller PRs are faster to review and easier to revert.
- Add `concurrency` groups to CI workflows to cancel stale runs when a new commit is pushed — avoids wasting runner minutes.

## GitHub Actions

- Always pin third-party actions to an immutable commit SHA, not a mutable tag (`@v1`). Include the tag as a comment for readability: `@<sha> # v1`. This prevents supply chain attacks if a tag is moved or a repo is compromised.
- Use a single CI workflow that always triggers on PRs rather than multiple workflow files with `paths` filters. A dedicated `changes` job detects which areas were modified and downstream jobs run conditionally — this allows both jobs to be added as required status checks (skipped jobs satisfy required checks in GitHub branch protection).
- Detect changed paths in a PR by fetching just the base branch tip (`git fetch origin $base_ref --depth=1`) then using a three-dot diff (`git diff --name-only origin/$base_ref...HEAD`). This correctly captures all commits in the PR against the target branch without fetching full history. Do not use `HEAD^1 HEAD` — it only compares the last two commits and breaks for multi-commit PRs.
