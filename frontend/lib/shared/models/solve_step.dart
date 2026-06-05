import 'cell_action.dart';
import 'source_cell.dart';

// SolveStep and ForcedChainBranch are mutually recursive — kept in the same file.

class ForcedChainBranch {
  const ForcedChainBranch({required this.candidate, required this.steps});

  final int candidate;
  final List<SolveStep> steps;

  factory ForcedChainBranch.fromJson(Map<String, dynamic> json) =>
      ForcedChainBranch(
        candidate: json['candidate'] as int,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => SolveStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SolveStep {
  const SolveStep({
    required this.technique,
    required this.sources,
    required this.actions,
    this.chains = const [],
  });

  final String technique;
  final List<SourceCell> sources;
  final List<CellAction> actions;
  final List<ForcedChainBranch> chains;

  factory SolveStep.fromJson(Map<String, dynamic> json) => SolveStep(
    technique: json['technique'] as String,
    sources: (json['sources'] as List<dynamic>? ?? [])
        .map((e) => SourceCell.fromJson(e as Map<String, dynamic>))
        .toList(),
    actions: (json['actions'] as List<dynamic>)
        .map((e) => CellAction.fromJson(e as Map<String, dynamic>))
        .toList(),
    chains: (json['chains'] as List<dynamic>? ?? [])
        .map((e) => ForcedChainBranch.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
