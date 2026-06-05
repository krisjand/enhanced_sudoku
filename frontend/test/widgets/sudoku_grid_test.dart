import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/models/game_state.dart';
import 'package:frontend/shared/widgets/sudoku_grid.dart';
import 'package:frontend/shared/widgets/sudoku_cell.dart';

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
