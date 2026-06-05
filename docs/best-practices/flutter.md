# Flutter Best Practices

This file documents Flutter/Dart-specific best practices learned during development.

## Formatting

- Always run `dart format lib/` before committing. The CI job runs `dart format --output=none --set-exit-if-changed .` and will fail on any unformatted file.
- `dart format` is opinionated and has no configuration — do not add a `.dartfmt.yaml` or similar. Accept the canonical style.
- Line length defaults to 80 characters. Do not override it.

## Navigation

- Use `context.push()` (not `context.go()`) when navigating to a screen that should have a back button. `go()` replaces the entire navigation stack — `canPop()` returns false and the AppBar shows no back arrow. `push()` adds to the stack — the AppBar automatically shows a back arrow and `context.pop()` works.
- Only use `context.go()` for top-level navigation where you intentionally want to reset the stack (e.g. switching between root tabs, or navigating away from a completed flow).

## go_router test isolation

The module-level `final appRouter = GoRouter(...)` singleton retains navigation state between `testWidgets` tests. After test N navigates to `/game`, test N+1 pumps a fresh widget but reuses the same router (still pointing at `/game`), so `HomeScreen` is never shown and button finders return 0 widgets.

Fix pattern:
1. Extract a factory function: `GoRouter buildAppRouter() => GoRouter(initialLocation: '/', routes: [...]);`
2. Keep the singleton for production: `final appRouter = buildAppRouter();`
3. Make `App` accept an optional router: `const App({super.key, this.router});`
4. In tests, pass a fresh instance per test: `ProviderScope(child: App(router: buildAppRouter()))`

## Theme

- Declare `AppTheme.light` (and any other static theme data) as `static final`, not as a `static ... get`. A getter reallocates the entire `ThemeData` object graph (`ColorScheme.fromSeed`, button themes, `TextStyle` instances) on every access — including every `App.build()` call during hot reload or root-level rebuilds. A `static final` field allocates once at startup.

## Lint: prefer_initializing_formals

The `prefer_initializing_formals` lint fires when a constructor parameter is assigned to a field in the initializer list (`const Foo({Bar? bar}) : _bar = bar`). The fix is `this.fieldName` as an initializing formal. For a private field (`_bar`) where the constructor parameter needs a public name (`bar`), make the field non-private — `StatelessWidget` fields are `final` and immutable, so there is no reason to hide them.

```dart
// triggers lint
const App({super.key, GoRouter? router}) : _router = router;
final GoRouter? _router;

// correct
const App({super.key, this.router});
final GoRouter? router;
```

## Riverpod v3 API

`flutter_riverpod ^3.x` removed `StateNotifier` and `StateNotifierProvider`. Use the new equivalents:

| Old (v2) | New (v3) |
|---|---|
| `class Foo extends StateNotifier<T>` | `class Foo extends Notifier<T>` |
| `StateNotifierProvider<Foo, T>((_) => Foo())` | `NotifierProvider<Foo, T>(Foo.new)` |
| `StateNotifier.state = ...` | `state = ...` (same, but inside `Notifier`) |
| Override `build()` not needed | Must override `build()` — returns initial state |

```dart
// v3 pattern
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setBackendUrl(String url) => state = state.copyWith(backendUrl: url);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
```

## CI

- Run `dart format --output=none --set-exit-if-changed .` in CI to enforce formatting without modifying files in the runner. Use `--output=none` to make the check-only intent explicit.
- Run `flutter analyze` before `flutter test` in CI — analysis is faster and catches issues before spending time on tests.
- Use a pre-built Docker image with Flutter already installed rather than downloading Flutter on every CI run. This eliminates the largest source of Flutter CI latency.
- When building a Flutter CI Docker image, use `git config --system` (not `--global`) to mark the Flutter installation as a git safe directory. `--global` writes to `$HOME/.gitconfig` which differs between image build time and GitHub Actions runtime, causing a "dubious ownership" error at runtime.
- `flutter analyze` scans `$FLUTTER_HOME/examples/` via `listSync()` internally. If that directory is deleted from the image, CI will crash with `PathNotFoundException`. Remove only the contents (`examples/*`), keeping the empty directory in place.
