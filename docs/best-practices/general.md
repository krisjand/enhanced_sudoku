# General Best Practices

This file documents workflow, branching, and PR conventions learned during development.

## Branching & PRs

- Always rebase feature branches on `main` before opening a PR.
- Squash-merge all PRs to keep `main` history clean and linear.
- One PR per feature/task — smaller PRs are faster to review and easier to revert.
- CI path filters should include the workflow file itself (e.g. `ci-backend.yml`) so changes to the pipeline are also validated.
- Add `concurrency` groups to CI workflows to cancel stale runs when a new commit is pushed — avoids wasting runner minutes.

## GitHub Actions

- Always pin third-party actions to an immutable commit SHA, not a mutable tag (`@v1`). Include the tag as a comment for readability: `@<sha> # v1`. This prevents supply chain attacks if a tag is moved or a repo is compromised.
- Split CI into separate workflow files per project area (backend, frontend) with `paths` filters. This avoids running unrelated checks on every PR.
