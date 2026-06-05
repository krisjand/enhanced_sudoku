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

ProviderContainer makeContainer(
  GameState puzzle, {
  bool autoRemoveNotes = true,
}) {
  final container = ProviderContainer(
    overrides: [
      gameStateProvider.overrideWith(() => _PuzzleNotifier(puzzle)),
      settingsProvider.overrideWith(
        () => _SettingsNotifierStub(autoRemoveNotes: autoRemoveNotes),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _SettingsNotifierStub extends SettingsNotifier {
  _SettingsNotifierStub({required this.autoRemoveNotes});
  final bool autoRemoveNotes;

  @override
  SettingsState build() => SettingsState(autoRemoveNotes: autoRemoveNotes);
}

class _PuzzleNotifier extends GameStateNotifier {
  _PuzzleNotifier(this._puzzle);
  final GameState _puzzle;

  @override
  GameState build() => _puzzle;
}

void main() {
  group('redo', () {
    test('redo restores state after undo', () {
      final c = makeContainer(blankPuzzle());
      final notifier = c.read(gameStateProvider.notifier);

      notifier.enterDigit(0, 0, 5);
      notifier.undo();
      expect(c.read(gameStateProvider).currentGrid[0][0], 0);
      expect(notifier.canRedo, isTrue);

      notifier.redo();
      expect(c.read(gameStateProvider).currentGrid[0][0], 5);
      expect(notifier.canRedo, isFalse);
    });

    test('new action clears redo stack', () {
      final c = makeContainer(blankPuzzle());
      final notifier = c.read(gameStateProvider.notifier);

      notifier.enterDigit(0, 0, 5);
      notifier.undo();
      expect(notifier.canRedo, isTrue);

      notifier.enterDigit(0, 0, 3);
      expect(notifier.canRedo, isFalse);
    });

    test('redo without prior undo does nothing', () {
      final c = makeContainer(blankPuzzle());
      final notifier = c.read(gameStateProvider.notifier);
      expect(notifier.canRedo, isFalse);
      notifier.redo();
      expect(c.read(gameStateProvider).currentGrid[0][0], 0);
    });

    test('multiple undo/redo steps round-trip correctly', () {
      final c = makeContainer(blankPuzzle());
      final notifier = c.read(gameStateProvider.notifier);

      notifier.enterDigit(0, 0, 1);
      notifier.enterDigit(0, 1, 2);
      notifier.undo();
      notifier.undo();

      expect(c.read(gameStateProvider).currentGrid[0][0], 0);
      expect(c.read(gameStateProvider).currentGrid[0][1], 0);

      notifier.redo();
      expect(c.read(gameStateProvider).currentGrid[0][0], 1);
      notifier.redo();
      expect(c.read(gameStateProvider).currentGrid[0][1], 2);
    });
  });

  group('auto-remove notes', () {
    test('placing a digit removes that digit from peer notes when enabled', () {
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][1] = {5}; // same row
      notes[1][0] = {5}; // same col
      notes[1][1] = {5}; // same box
      notes[5][5] = {5}; // unrelated cell — must NOT be affected

      final c = makeContainer(blankPuzzle(notes: notes));
      c.read(gameStateProvider.notifier).enterDigit(0, 0, 5);

      final state = c.read(gameStateProvider);
      expect(state.currentGrid[0][0], 5);
      expect(state.notes[0][0], isEmpty); // target cell cleared
      expect(state.notes[0][1], isEmpty); // same row — 5 removed
      expect(state.notes[1][0], isEmpty); // same col — 5 removed
      expect(state.notes[1][1], isEmpty); // same box — 5 removed
      expect(state.notes[5][5], {5}); // unrelated — unchanged
    });

    test('clearing a digit does NOT remove peer notes', () {
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][1] = {5}; // same row — must survive the clear

      final initial = GameState(
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        currentGrid: [
          [5, 0, 0, 0, 0, 0, 0, 0, 0],
          ...List.generate(8, (_) => List.filled(9, 0)),
        ],
        notes: notes,
      );

      final c = makeContainer(initial);
      c.read(gameStateProvider.notifier).enterDigit(0, 0, 5); // toggle-to-clear

      final state = c.read(gameStateProvider);
      expect(state.currentGrid[0][0], 0); // digit cleared
      expect(state.notes[0][1], {5}); // peer note untouched
    });

    test(
      'placing a digit does NOT remove peer notes when setting is disabled',
      () {
        final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
        notes[0][1] = {5};
        notes[1][0] = {5};

        final c = makeContainer(
          blankPuzzle(notes: notes),
          autoRemoveNotes: false,
        );
        c.read(gameStateProvider.notifier).enterDigit(0, 0, 5);

        final state = c.read(gameStateProvider);
        expect(state.currentGrid[0][0], 5);
        expect(state.notes[0][0], isEmpty); // target cell always cleared
        expect(state.notes[0][1], {5}); // peer untouched when disabled
        expect(state.notes[1][0], {5}); // peer untouched when disabled
      },
    );

    test('undo without prior action does nothing', () {
      final c = makeContainer(blankPuzzle());
      final notifier = c.read(gameStateProvider.notifier);
      expect(notifier.canUndo, isFalse);
      notifier.undo();
      expect(c.read(gameStateProvider).currentGrid[0][0], 0);
    });

    test('digit + peer note removal is a single undo step', () {
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][1] = {5};

      final c = makeContainer(blankPuzzle(notes: notes));
      final notifier = c.read(gameStateProvider.notifier);

      notifier.enterDigit(0, 0, 5);
      expect(c.read(gameStateProvider).notes[0][1], isEmpty);

      notifier.undo();

      final restored = c.read(gameStateProvider);
      expect(restored.currentGrid[0][0], 0); // digit gone
      expect(restored.notes[0][1], {5}); // peer note restored
    });
  });

  group('autoFillNotes', () {
    test('blank board fills every empty cell with {1..9}', () {
      final c = makeContainer(blankPuzzle());
      c.read(gameStateProvider.notifier).autoFillNotes();
      final state = c.read(gameStateProvider);
      for (var r = 0; r < 9; r++) {
        for (var col = 0; col < 9; col++) {
          expect(state.notes[r][col], {1, 2, 3, 4, 5, 6, 7, 8, 9});
        }
      }
    });

    test('excludes peer digits from candidates', () {
      final initial = GameState(
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        currentGrid: [
          [5, 0, 0, 0, 0, 0, 0, 0, 0],
          ...List.generate(8, (_) => List.filled(9, 0)),
        ],
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      );
      final c = makeContainer(initial);
      c.read(gameStateProvider.notifier).autoFillNotes();
      final state = c.read(gameStateProvider);

      expect(state.notes[0][0], isEmpty); // has a digit — not touched
      expect(state.notes[0][1], {
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
      }); // same row: 5 excluded
      expect(state.notes[1][0], {
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
      }); // same col: 5 excluded
      expect(state.notes[1][1], {
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
      }); // same box: 5 excluded
      expect(state.notes[5][5], {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      }); // unrelated: all candidates
    });

    test('does not modify cells with a clue', () {
      final initial = GameState(
        initialGrid: [
          [5, 0, 0, 0, 0, 0, 0, 0, 0],
          ...List.generate(8, (_) => List.filled(9, 0)),
        ],
        currentGrid: List.generate(9, (_) => List.filled(9, 0)),
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      );
      final c = makeContainer(initial);
      c.read(gameStateProvider.notifier).autoFillNotes();
      final state = c.read(gameStateProvider);

      expect(state.notes[0][0], isEmpty); // clue cell — notes untouched
      expect(state.notes[0][1], {
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
      }); // 5 excluded (clue peer)
    });

    test('replaces existing notes in empty cells', () {
      final notes = List.generate(9, (r) => List.generate(9, (c) => <int>{}));
      notes[0][0] = {1, 2, 3}; // arbitrary pre-existing notes
      final c = makeContainer(blankPuzzle(notes: notes));
      c.read(gameStateProvider.notifier).autoFillNotes();
      expect(c.read(gameStateProvider).notes[0][0], {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      });
    });

    test(
      'no-op when notes already match candidates — does not push history',
      () {
        final c = makeContainer(blankPuzzle());
        final notifier = c.read(gameStateProvider.notifier);

        notifier.autoFillNotes(); // first call fills notes
        expect(notifier.canUndo, isTrue);

        notifier.autoFillNotes(); // second call is a no-op
        // Still only one undo step from the first call
        notifier.undo();
        expect(c.read(gameStateProvider).notes[0][0], isEmpty);
        expect(notifier.canUndo, isFalse);
      },
    );

    test('is a single undo step', () {
      final c = makeContainer(blankPuzzle());
      final notifier = c.read(gameStateProvider.notifier);

      notifier.autoFillNotes();
      expect(c.read(gameStateProvider).notes[0][0], {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
      });

      notifier.undo();

      final restored = c.read(gameStateProvider);
      for (var r = 0; r < 9; r++) {
        for (var col = 0; col < 9; col++) {
          expect(restored.notes[r][col], isEmpty);
        }
      }
      expect(notifier.canUndo, isFalse);
    });
  });
}
