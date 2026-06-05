import 'grid.dart';
import 'technique_attempt.dart';

class SolveResult {
  const SolveResult({
    required this.solved,
    required this.grid,
    required this.durationUs,
    required this.iterations,
  });

  final bool solved;
  final Grid grid;
  final int durationUs;
  final List<List<TechniqueAttempt>> iterations;

  factory SolveResult.fromJson(Map<String, dynamic> json) => SolveResult(
    solved: json['solved'] as bool,
    grid: (json['grid'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).cast<int>())
        .toList(),
    durationUs: json['duration_us'] as int,
    iterations: (json['iterations'] as List<dynamic>)
        .map(
          (iter) =>
              ((iter as Map<String, dynamic>)['attempts'] as List<dynamic>)
                  .map(
                    (a) => TechniqueAttempt.fromJson(a as Map<String, dynamic>),
                  )
                  .toList(),
        )
        .toList(),
  );
}
