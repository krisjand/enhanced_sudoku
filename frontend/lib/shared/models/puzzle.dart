import 'difficulty_level.dart';
import 'grid.dart';

class Puzzle {
  const Puzzle({
    required this.grid,
    required this.solution,
    required this.difficulty,
    required this.techniquesUsed,
  });

  final Grid grid;
  final Grid solution;
  final DifficultyLevel difficulty;
  final List<String> techniquesUsed;

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
    grid: (json['puzzle'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).cast<int>())
        .toList(),
    solution: (json['solution'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).cast<int>())
        .toList(),
    difficulty: DifficultyLevel.fromString(json['difficulty'] as String),
    techniquesUsed: (json['techniques_used'] as List<dynamic>).cast<String>(),
  );
}
