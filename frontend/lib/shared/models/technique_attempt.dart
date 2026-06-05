import 'solve_step.dart';

class TechniqueAttempt {
  const TechniqueAttempt({
    required this.technique,
    required this.durationUs,
    required this.found,
    required this.steps,
  });

  final String technique;
  final int durationUs;
  final bool found;
  final List<SolveStep> steps;

  factory TechniqueAttempt.fromJson(Map<String, dynamic> json) =>
      TechniqueAttempt(
        technique: json['technique'] as String,
        durationUs: json['duration_us'] as int,
        found: json['found'] as bool,
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((e) => SolveStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
