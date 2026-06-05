import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/models/lesson_board.dart';
import 'package:frontend/shared/models/tutorial_lesson.dart';

Map<String, dynamic> _minimalBoard({
  List<List<int>>? initial,
  List<List<int>>? current,
  List<List<List<int>>>? notes,
}) {
  final empty9 = List.generate(9, (_) => List.filled(9, 0));
  final emptyNotes = List.generate(9, (_) => List.generate(9, (_) => <int>[]));
  return {
    'initial_grid': initial ?? empty9,
    'current_grid': current ?? empty9,
    'notes': notes ?? emptyNotes,
  };
}

void main() {
  group('LessonBoard.fromJson', () {
    test('parses grids and notes', () {
      final initial = List.generate(9, (r) => List.generate(9, (c) => r));
      final current = List.generate(9, (r) => List.generate(9, (c) => c));
      final notes = List.generate(
        9,
        (r) => List.generate(9, (c) => r == 0 ? [1, 2, 3] : <int>[]),
      );

      final board = LessonBoard.fromJson(
        _minimalBoard(initial: initial, current: current, notes: notes),
      );

      expect(board.initialGrid[3][0], 3);
      expect(board.currentGrid[0][5], 5);
      expect(board.notes[0][0], [1, 2, 3]);
      expect(board.notes[1][0], isEmpty);
    });

    test('step is null when absent', () {
      final board = LessonBoard.fromJson(_minimalBoard());
      expect(board.step, isNull);
    });

    test('sub_variant is parsed when present', () {
      final json = _minimalBoard();
      json['sub_variant'] = 'row';
      final board = LessonBoard.fromJson(json);
      expect(board.subVariant, 'row');
    });
  });

  group('TutorialLesson.fromJson', () {
    test('parses technique, explain, and practice list', () {
      final json = {
        'technique': 'nakedSingles',
        'explain': _minimalBoard(),
        'practice': [_minimalBoard(), _minimalBoard()],
      };

      final lesson = TutorialLesson.fromJson(json);

      expect(lesson.technique, 'nakedSingles');
      expect(lesson.explain, isA<LessonBoard>());
      expect(lesson.practice.length, 2);
    });

    test('practice defaults to empty list when absent', () {
      final json = {'technique': 'hiddenSingles', 'explain': _minimalBoard()};

      final lesson = TutorialLesson.fromJson(json);
      expect(lesson.practice, isEmpty);
    });
  });

  group('notes completion check', () {
    // Mirrors the _isComplete logic in NotesLessonScreen.
    bool isComplete(LessonBoard board, List<List<Set<int>>> playerNotes) {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board.initialGrid[r][c] != 0) continue;
          if (board.currentGrid[r][c] != 0) continue;
          final target = Set<int>.from(board.notes[r][c]);
          final player = playerNotes[r][c];
          if (target.length != player.length) return false;
          for (final d in target) {
            if (!player.contains(d)) return false;
          }
        }
      }
      return true;
    }

    test('returns true when all empty cells match', () {
      final notes = List.generate(9, (_) => List.generate(9, (_) => [1, 2]));
      final board = LessonBoard.fromJson(_minimalBoard(notes: notes));
      final player = List.generate(9, (_) => List.generate(9, (_) => {1, 2}));
      expect(isComplete(board, player), isTrue);
    });

    test('returns false when one cell is missing a digit', () {
      final notes = List.generate(9, (_) => List.generate(9, (_) => [1, 2]));
      final board = LessonBoard.fromJson(_minimalBoard(notes: notes));
      final player = List.generate(9, (_) => List.generate(9, (_) => {1, 2}));
      player[3][4] = {1}; // missing 2
      expect(isComplete(board, player), isFalse);
    });

    test('returns false when one cell has an extra digit', () {
      final notes = List.generate(9, (_) => List.generate(9, (_) => [1, 2]));
      final board = LessonBoard.fromJson(_minimalBoard(notes: notes));
      final player = List.generate(9, (_) => List.generate(9, (_) => {1, 2}));
      player[0][0] = {1, 2, 3};
      expect(isComplete(board, player), isFalse);
    });

    test('ignores clue cells', () {
      final initial = List.generate(
        9,
        (r) => List.generate(9, (c) => r == 0 ? 5 : 0),
      );
      final notes = List.generate(9, (_) => List.generate(9, (_) => <int>[]));
      final board = LessonBoard.fromJson(
        _minimalBoard(initial: initial, notes: notes),
      );
      // Row 0 are clue cells — player notes for them don't matter.
      final player = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
      player[0][0] = {9, 8, 7}; // should be ignored
      expect(isComplete(board, player), isTrue);
    });

    test('ignores cells with a placed digit in currentGrid', () {
      final current = List.generate(
        9,
        (r) => List.generate(9, (c) => r == 1 ? 3 : 0),
      );
      final notes = List.generate(9, (_) => List.generate(9, (_) => <int>[]));
      final board = LessonBoard.fromJson(
        _minimalBoard(current: current, notes: notes),
      );
      final player = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
      player[1][0] = {1, 2}; // row 1 has placed digit — should be ignored
      expect(isComplete(board, player), isTrue);
    });
  });
}
