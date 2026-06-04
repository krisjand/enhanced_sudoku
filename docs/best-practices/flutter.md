# Flutter Best Practices

This file documents Flutter/Dart-specific best practices learned during development.

## Formatting

- Always run `dart format lib/` before committing. The CI job runs `dart format --output=none --set-exit-if-changed .` and will fail on any unformatted file.
- `dart format` is opinionated and has no configuration — do not add a `.dartfmt.yaml` or similar. Accept the canonical style.
- Line length defaults to 80 characters. Do not override it.

## CI

- Run `dart format --output=none --set-exit-if-changed .` in CI to enforce formatting without modifying files in the runner. Use `--output=none` to make the check-only intent explicit.
- Run `flutter analyze` before `flutter test` in CI — analysis is faster and catches issues before spending time on tests.
- Use a pre-built Docker image with Flutter already installed rather than downloading Flutter on every CI run. This eliminates the largest source of Flutter CI latency.
- When building a Flutter CI Docker image, use `git config --system` (not `--global`) to mark the Flutter installation as a git safe directory. `--global` writes to `$HOME/.gitconfig` which differs between image build time and GitHub Actions runtime, causing a "dubious ownership" error at runtime.
- `flutter analyze` scans `$FLUTTER_HOME/examples/` via `listSync()` internally. If that directory is deleted from the image, CI will crash with `PathNotFoundException`. Remove only the contents (`examples/*`), keeping the empty directory in place.
