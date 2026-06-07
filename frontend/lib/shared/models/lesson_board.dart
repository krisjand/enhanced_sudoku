import 'solve_step.dart';

class LessonBoard {
  const LessonBoard({
    required this.initialGrid,
    required this.currentGrid,
    required this.notes,
    this.step,
    this.subVariant,
    this.allSteps = const [],
  });

  final List<List<int>> initialGrid;
  final List<List<int>> currentGrid;
  final List<List<List<int>>> notes; // [row][col][digit]
  final SolveStep? step;
  final String? subVariant;
  // Per-group steps for techniques that aggregate multiple groups (e.g. locked
  // candidates). Each entry is one independent group; use for practice validation.
  final List<SolveStep> allSteps;

  factory LessonBoard.fromJson(Map<String, dynamic> json) => LessonBoard(
    initialGrid: _grid(json['initial_grid']),
    currentGrid: _grid(json['current_grid']),
    notes: _notes(json['notes']),
    step: json['step'] != null
        ? SolveStep.fromJson(json['step'] as Map<String, dynamic>)
        : null,
    subVariant: json['sub_variant'] as String?,
    allSteps: json['all_steps'] != null
        ? (json['all_steps'] as List<dynamic>)
              .map((s) => SolveStep.fromJson(s as Map<String, dynamic>))
              .toList()
        : const [],
  );

  static List<List<int>> _grid(dynamic raw) => (raw as List)
      .map((r) => (r as List).map((v) => v as int).toList())
      .toList();

  static List<List<List<int>>> _notes(dynamic raw) => (raw as List)
      .map(
        (r) => (r as List)
            .map((c) => (c as List).map((v) => v as int).toList())
            .toList(),
      )
      .toList();
}
