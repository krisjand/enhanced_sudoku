import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/game/providers/selection_provider.dart';
import 'package:frontend/shared/models/game_state.dart';
import 'package:frontend/shared/widgets/sudoku_cell.dart';
import 'package:frontend/shared/widgets/sudoku_grid.dart';

Widget buildGrid(GameState state, {int? selectedRow, int? selectedCol}) =>
    MaterialApp(
      home: Scaffold(
        body: SudokuGrid(
          state: state,
          selectedRow: selectedRow,
          selectedCol: selectedCol,
        ),
      ),
    );

void main() {
  group('SudokuGrid', () {
    test(
      'GameState.digit returns clue for clue cells, user digit otherwise',
      () {
        final state = GameState(
          initialGrid: [
            [5, 0, ...List.filled(7, 0)],
            ...List.generate(8, (_) => List.filled(9, 0)),
          ],
          currentGrid: [
            [0, 3, ...List.filled(7, 0)],
            ...List.generate(8, (_) => List.filled(9, 0)),
          ],
          notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        );

        expect(state.isClue(0, 0), isTrue);
        expect(state.digit(0, 0), 5);
        expect(state.isClue(0, 1), isFalse);
        expect(state.digit(0, 1), 3);
        expect(state.isEmpty(0, 2), isTrue);
      },
    );

    testWidgets('renders 81 SudokuCell widgets', (tester) async {
      await tester.pumpWidget(buildGrid(GameState.empty()));
      expect(find.byType(SudokuCell), findsNWidgets(81));
    });

    testWidgets('clue digit appears in the grid', (tester) async {
      final state = GameState(
        initialGrid: [
          [7, 0, ...List.filled(7, 0)],
          ...List.generate(8, (_) => List.filled(9, 0)),
        ],
        currentGrid: List.generate(9, (_) => List.filled(9, 0)),
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      );

      await tester.pumpWidget(buildGrid(state));
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('empty grid shows no digit text', (tester) async {
      await tester.pumpWidget(buildGrid(GameState.empty()));
      for (var d = 1; d <= 9; d++) {
        expect(find.text('$d'), findsNothing);
      }
    });

    group('Selection', () {
      // Build a state with digit 5 at (4,4) so isPeer can fire.
      GameState _stateWithDigitAt44() => GameState(
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        currentGrid: [
          ...List.generate(4, (_) => List.filled(9, 0)),
          [0, 0, 0, 0, 5, ...List.filled(4, 0)],
          ...List.generate(4, (_) => List.filled(9, 0)),
        ],
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      );

      test(
        'isPeer: same row, col, and box return true; selected cell is not a peer',
        () {
          final grid = SudokuGrid(
            state: _stateWithDigitAt44(),
            selectedRow: 4,
            selectedCol: 4,
            isHighlightMode: true,
          );
          // same row
          expect(grid.isPeer(4, 0), isTrue);
          // same col
          expect(grid.isPeer(0, 4), isTrue);
          // same box (center box)
          expect(grid.isPeer(3, 3), isTrue);
          expect(grid.isPeer(5, 5), isTrue);
          // selected cell itself is NOT a peer
          expect(grid.isPeer(4, 4), isFalse);
          // unrelated cell
          expect(grid.isPeer(0, 0), isFalse);
          expect(grid.isPeer(8, 8), isFalse);
        },
      );

      test('no selection means no peers', () {
        final grid = SudokuGrid(state: GameState.empty());
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            expect(grid.isPeer(r, c), isFalse);
          }
        }
      });

      test('selecting empty cell still shows peers when highlight is on', () {
        final grid = SudokuGrid(
          state: GameState.empty(),
          selectedRow: 4,
          selectedCol: 4,
          isHighlightMode: true,
        );
        expect(grid.isPeer(4, 0), isTrue); // same row
        expect(grid.isPeer(0, 4), isTrue); // same col
        expect(grid.isPeer(3, 3), isTrue); // same box
      });

      test('selecting empty cell shows no peers when highlight is off', () {
        final grid = SudokuGrid(
          state: GameState.empty(),
          selectedRow: 4,
          selectedCol: 4,
          isHighlightMode: false,
        );
        expect(grid.isPeer(4, 0), isFalse);
        expect(grid.isPeer(0, 4), isFalse);
      });

      testWidgets('tapping a cell updates selectionProvider', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final sel = ref.watch(selectionProvider);
                    return SudokuGrid(
                      state: GameState.empty(),
                      selectedRow: sel?.row,
                      selectedCol: sel?.col,
                      onCellTap: (row, col) =>
                          ref.read(selectionProvider.notifier).select(row, col),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        final cells = tester.widgetList<SudokuCell>(find.byType(SudokuCell));
        expect(cells.first.isSelected, isFalse);

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();

        final updated = tester
            .widgetList<SudokuCell>(find.byType(SudokuCell))
            .toList();
        expect(updated.first.isSelected, isTrue);
        // highlight on by default: peers show even for empty cell
        expect(updated[1].isPeer, isTrue); // (0,1) same row
        expect(updated[9].isPeer, isTrue); // (1,0) same col
      });

      testWidgets('tapping selected cell deselects it', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final sel = ref.watch(selectionProvider);
                    return SudokuGrid(
                      state: GameState.empty(),
                      selectedRow: sel?.row,
                      selectedCol: sel?.col,
                      onCellTap: (row, col) =>
                          ref.read(selectionProvider.notifier).select(row, col),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        expect(
          tester
              .widgetList<SudokuCell>(find.byType(SudokuCell))
              .first
              .isSelected,
          isTrue,
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        expect(
          tester
              .widgetList<SudokuCell>(find.byType(SudokuCell))
              .first
              .isSelected,
          isFalse,
        );
      });
    });

    group('Highlight', () {
      // Grid: selected cell (0,0) has digit 5; cell (0,1) also has digit 5;
      // cell (0,2) is empty with note 5.
      GameState _digitMatchState() {
        final notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
        notes[0][2] = {5};
        return GameState(
          initialGrid: List.generate(9, (_) => List.filled(9, 0)),
          currentGrid: [
            [5, 5, 0, ...List.filled(6, 0)],
            ...List.generate(8, (_) => List.filled(9, 0)),
          ],
          notes: notes,
        );
      }

      test('isDigitMatch: other cell with same digit returns true', () {
        final state = _digitMatchState();
        final grid = SudokuGrid(
          state: state,
          selectedRow: 0,
          selectedCol: 0,
          isHighlightMode: true,
        );
        final d = grid.selectedDigit;
        expect(grid.isDigitMatch(0, 1, d), isTrue);
        expect(grid.isDigitMatch(0, 0, d), isFalse); // selected cell itself
        expect(grid.isDigitMatch(1, 0, d), isFalse); // different digit
      });

      test('isDigitMatch: returns false when highlight mode is off', () {
        final state = _digitMatchState();
        final grid = SudokuGrid(
          state: state,
          selectedRow: 0,
          selectedCol: 0,
          isHighlightMode: false,
        );
        final d = grid.selectedDigit;
        expect(d, isNull);
        expect(grid.isDigitMatch(0, 1, d), isFalse);
      });

      test('highlightedNote: empty cell with matching note returns digit', () {
        final state = _digitMatchState();
        final grid = SudokuGrid(
          state: state,
          selectedRow: 0,
          selectedCol: 0,
          isHighlightMode: true,
        );
        final d = grid.selectedDigit;
        expect(grid.highlightedNote(0, 2, d), 5); // has note 5
        expect(grid.highlightedNote(0, 1, d), isNull); // has a placed digit
        expect(grid.highlightedNote(1, 0, d), isNull); // no note 5
      });

      test('highlightedNote: returns null when highlight mode is off', () {
        final state = _digitMatchState();
        final grid = SudokuGrid(
          state: state,
          selectedRow: 0,
          selectedCol: 0,
          isHighlightMode: false,
        );
        final d = grid.selectedDigit;
        expect(grid.highlightedNote(0, 2, d), isNull);
      });

      test(
        'isPeer: returns true for empty-cell selection when highlight is on',
        () {
          final grid = SudokuGrid(
            state: GameState.empty(),
            selectedRow: 0,
            selectedCol: 0,
            isHighlightMode: true,
          );
          expect(
            grid.isPeer(0, 1),
            isTrue,
          ); // same row — shown even for empty cell
          expect(grid.isPeer(1, 0), isTrue); // same col
        },
      );

      testWidgets('digit-match cell shows selectedCell background', (
        tester,
      ) async {
        final state = _digitMatchState();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SudokuGrid(
                state: state,
                selectedRow: 0,
                selectedCol: 0,
                isHighlightMode: true,
              ),
            ),
          ),
        );

        final cells = tester
            .widgetList<SudokuCell>(find.byType(SudokuCell))
            .toList();
        expect(cells[0].isSelected, isTrue); // (0,0) selected
        expect(cells[1].isDigitMatch, isTrue); // (0,1) same digit
        expect(
          cells[2].isDigitMatch,
          isFalse,
        ); // (0,2) empty, has note not digit
      });
    });

    testWidgets('note digit appears in empty cell notes', (tester) async {
      final notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
      notes[0][0] = {3, 7};

      final state = GameState(
        initialGrid: List.generate(9, (_) => List.filled(9, 0)),
        currentGrid: List.generate(9, (_) => List.filled(9, 0)),
        notes: notes,
      );

      await tester.pumpWidget(buildGrid(state));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('5'), findsNothing);
    });
  });
}
