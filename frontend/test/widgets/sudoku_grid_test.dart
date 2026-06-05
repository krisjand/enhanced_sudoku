import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/game/providers/game_state_notifier.dart';
import 'package:frontend/shared/models/game_state.dart';
import 'package:frontend/shared/widgets/sudoku_cell.dart';
import 'package:frontend/shared/widgets/sudoku_grid.dart';

Widget buildGrid(GameState state) => MaterialApp(
  home: Scaffold(body: SudokuGrid(state: state)),
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

    group('GameState selection', () {
      test('isPeer returns true for same row, col, and box', () {
        final state = GameState.empty().copyWith(
          selectedRow: 4,
          selectedCol: 4,
        );
        // same row
        expect(state.isPeer(4, 0), isTrue);
        // same col
        expect(state.isPeer(0, 4), isTrue);
        // same box (center box)
        expect(state.isPeer(3, 3), isTrue);
        expect(state.isPeer(5, 5), isTrue);
        // selected cell itself is NOT a peer
        expect(state.isPeer(4, 4), isFalse);
        // unrelated cell
        expect(state.isPeer(0, 0), isFalse);
        expect(state.isPeer(8, 8), isFalse);
      });

      test('no selection means no peers', () {
        final state = GameState.empty();
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            expect(state.isPeer(r, c), isFalse);
          }
        }
      });
    });

    testWidgets('tapping a cell selects it via gameStateProvider', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(gameStateProvider);
                  return SudokuGrid(
                    state: state,
                    onCellTap: ref.read(gameStateProvider.notifier).selectCell,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Find the first cell (top-left) and tap it.
      final cells = tester.widgetList<SudokuCell>(find.byType(SudokuCell));
      expect(cells.first.isSelected, isFalse);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      final updatedCells = tester
          .widgetList<SudokuCell>(find.byType(SudokuCell))
          .toList();
      expect(updatedCells.first.isSelected, isTrue);
      // Peer cells in same row/col/box should have isPeer == true.
      expect(updatedCells[1].isPeer, isTrue); // (0,1) same row
      expect(updatedCells[9].isPeer, isTrue); // (1,0) same col
    });

    testWidgets('tapping selected cell deselects it', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(gameStateProvider);
                  return SudokuGrid(
                    state: state,
                    onCellTap: ref.read(gameStateProvider.notifier).selectCell,
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
        tester.widgetList<SudokuCell>(find.byType(SudokuCell)).first.isSelected,
        isTrue,
      );

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(
        tester.widgetList<SudokuCell>(find.byType(SudokuCell)).first.isSelected,
        isFalse,
      );
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
