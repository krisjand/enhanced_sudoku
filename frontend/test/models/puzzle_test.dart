import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/models/difficulty_level.dart';
import 'package:frontend/shared/models/puzzle.dart';

void main() {
  group('Puzzle.fromJson', () {
    late Map<String, dynamic> json;

    setUp(() {
      json = {
        'puzzle': List.generate(
          9,
          (r) => List.generate(9, (c) => r == c ? r + 1 : 0),
        ),
        'solution': List.generate(9, (_) => List.generate(9, (c) => c + 1)),
        'difficulty': 'hard',
        'techniques_used': ['nakedSingles', 'hiddenSingles', 'nakedPairs'],
      };
    });

    test('deserialises grid, solution, difficulty and techniques', () {
      final puzzle = Puzzle.fromJson(json);

      expect(puzzle.difficulty, DifficultyLevel.hard);
      expect(puzzle.techniquesUsed, [
        'nakedSingles',
        'hiddenSingles',
        'nakedPairs',
      ]);
      expect(puzzle.grid.length, 9);
      expect(puzzle.grid[0].length, 9);
      expect(puzzle.solution.length, 9);
    });

    test('parses all difficulty levels', () {
      for (final level in DifficultyLevel.values) {
        final p = Puzzle.fromJson({...json, 'difficulty': level.name});
        expect(p.difficulty, level);
      }
    });

    test('throws on unknown difficulty', () {
      expect(
        () => Puzzle.fromJson({...json, 'difficulty': 'impossible'}),
        throwsArgumentError,
      );
    });
  });
}
