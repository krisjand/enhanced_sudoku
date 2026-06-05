import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/game/providers/game_state_notifier.dart';
import 'package:frontend/shared/models/game_state.dart';
import 'package:frontend/shared/providers/settings_provider.dart';

// Minimal blank puzzle with no clues — lets us place any digit freely.
GameState blankPuzzle({List<List<Set<int>>>? notes}) => GameState(
  initialGrid: List.generate(9, (_) => List.filled(9, 0)),
  currentGrid: List.generate(9, (_) => List.filled(9, 0)),
  notes: notes ?? List.generate(9, (_) => List.generate(9, (_) => <int>{})),
);

ProviderContainer makeContainer({bool autoRemoveNotes = true}) {
  final container = ProviderContainer(
    overrides: [
      gameStateProvider.overrideWith(() => _BlankGameNotifier()),
      settingsProvider.overrideWith(
        () => _SettingsNotifierStub(autoRemoveNotes: autoRemoveNotes),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// Notifier that starts from a blank puzzle so tests can place any digit.
class _BlankGameNotifier extends GameStateNotifier {
  @override
  GameState build() => blankPuzzle();
}

class _SettingsNotifierStub extends SettingsNotifier {
  _SettingsNotifierStub({required this.autoRemoveNotes});
  final bool autoRemoveNotes;

  @override
  SettingsState build() => SettingsState(autoRemoveNotes: autoRemoveNotes);
}

void main() {
  group('auto-remove notes', () {
    test('placing a digit removes that digit from peer notes when enabled', () {
      // Arrange: notes[0][1] = {5} (same row as target) and
      //          notes[1][0] = {5} (same col) and
      //          notes[1][1] = {5} (same box).
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][1] = {5};
      notes[1][0] = {5};
      notes[1][1] = {5};
      notes[5][5] = {5}; // unrelated cell — should NOT be affected

      final container = ProviderContainer(
        overrides: [
          gameStateProvider.overrideWith(
            () => _PuzzleNotifier(blankPuzzle(notes: notes)),
          ),
          settingsProvider.overrideWith(
            () => _SettingsNotifierStub(autoRemoveNotes: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(gameStateProvider.notifier).enterDigit(0, 0, 5);

      final state = container.read(gameStateProvider);
      expect(state.currentGrid[0][0], 5);
      expect(state.notes[0][0], isEmpty); // target cell cleared
      expect(state.notes[0][1], isEmpty); // same row — 5 removed
      expect(state.notes[1][0], isEmpty); // same col — 5 removed
      expect(state.notes[1][1], isEmpty); // same box — 5 removed
      expect(state.notes[5][5], {5}); // unrelated — unchanged
    });

    test('placing a digit does NOT remove peer notes when disabled', () {
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][1] = {5}; // same row as target
      notes[1][0] = {5}; // same col

      final container = ProviderContainer(
        overrides: [
          gameStateProvider.overrideWith(
            () => _PuzzleNotifier(blankPuzzle(notes: notes)),
          ),
          settingsProvider.overrideWith(
            () => _SettingsNotifierStub(autoRemoveNotes: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(gameStateProvider.notifier).enterDigit(0, 0, 5);

      final state = container.read(gameStateProvider);
      expect(state.currentGrid[0][0], 5);
      expect(state.notes[0][0], isEmpty); // target cell always cleared
      expect(state.notes[0][1], {5}); // peer untouched when disabled
      expect(state.notes[1][0], {5}); // peer untouched when disabled
    });

    test('digit + peer note removal is a single undo step', () {
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][1] = {5};

      final container = ProviderContainer(
        overrides: [
          gameStateProvider.overrideWith(
            () => _PuzzleNotifier(blankPuzzle(notes: notes)),
          ),
          settingsProvider.overrideWith(
            () => _SettingsNotifierStub(autoRemoveNotes: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(gameStateProvider.notifier);
      notifier.enterDigit(0, 0, 5);
      expect(container.read(gameStateProvider).notes[0][1], isEmpty);

      // One undo should restore both the digit AND the peer note.
      notifier.undo();

      final restored = container.read(gameStateProvider);
      expect(restored.currentGrid[0][0], 0); // digit gone
      expect(restored.notes[0][1], {5}); // peer note restored
    });
  });
}

class _PuzzleNotifier extends GameStateNotifier {
  _PuzzleNotifier(this._puzzle);
  final GameState _puzzle;

  @override
  GameState build() => _puzzle;
}
