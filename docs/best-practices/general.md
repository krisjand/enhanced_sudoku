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
- Detect changed paths in a PR using `fetch-depth: 0` on `actions/checkout` combined with `git diff --name-only origin/$base_ref...HEAD`. The three-dot diff requires a shared history between the PR branch and the base — shallow clones have no common ancestor visible to git and will fail with "no merge base". Do not use `HEAD^1 HEAD` — it only compares the last two commits and breaks for multi-commit PRs.
- Pin Docker image tags to specific versions (`flutter-ci:3.44.0`) rather than `:latest`. Using `:latest` picks up image rebuilds silently; an explicit tag makes tool version changes a deliberate, visible commit — consistent with pinning GitHub Actions to commit SHAs.
