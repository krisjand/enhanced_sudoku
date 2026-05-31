# Flutter Best Practices

This file documents Flutter/Dart-specific best practices learned during development.

## CI

- Run `dart format --output=none --set-exit-if-changed .` in CI to enforce formatting without modifying files in the runner. Use `--output=none` to make the check-only intent explicit.
- Run `flutter analyze` before `flutter test` in CI — analysis is faster and catches issues before spending time on tests.
