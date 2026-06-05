import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/models/cell_action.dart';
import 'package:frontend/shared/models/solve_step.dart';

void main() {
  group('SolveStep.fromJson', () {
    test('deserialises technique, sources, actions', () {
      final json = {
        'technique': 'nakedPairRow',
        'sources': [
          {
            'row': 0,
            'col': 1,
            'digits': [3, 7],
          },
          {
            'row': 0,
            'col': 5,
            'digits': [3, 7],
          },
        ],
        'actions': [
          {'row': 0, 'col': 3, 'digit': 3, 'type': 'eliminate'},
          {'row': 0, 'col': 4, 'digit': 7, 'type': 'eliminate'},
        ],
      };

      final step = SolveStep.fromJson(json);

      expect(step.technique, 'nakedPairRow');
      expect(step.sources.length, 2);
      expect(step.sources[0].row, 0);
      expect(step.sources[0].col, 1);
      expect(step.sources[0].digits, [3, 7]);
      expect(step.actions.length, 2);
      expect(step.actions[0].type, ActionType.eliminate);
      expect(step.actions[1].digit, 7);
      expect(step.chains, isEmpty);
    });

    test('deserialises forced chain step with nested chains', () {
      final json = {
        'technique': 'forcedChains',
        'sources': [],
        'actions': [
          {'row': 2, 'col': 2, 'digit': 5, 'type': 'set'},
        ],
        'chains': [
          {
            'candidate': 5,
            'steps': [
              {
                'technique': 'nakedSingles',
                'sources': [],
                'actions': [
                  {'row': 2, 'col': 2, 'digit': 5, 'type': 'set'},
                ],
              },
            ],
          },
          {'candidate': 9, 'steps': []},
        ],
      };

      final step = SolveStep.fromJson(json);

      expect(step.technique, 'forcedChains');
      expect(step.chains.length, 2);
      expect(step.chains[0].candidate, 5);
      expect(step.chains[0].steps.length, 1);
      expect(step.chains[0].steps[0].technique, 'nakedSingles');
      expect(step.chains[1].candidate, 9);
      expect(step.chains[1].steps, isEmpty);
    });

    test('tolerates missing sources field', () {
      final json = {
        'technique': 'nakedSingles',
        'actions': [
          {'row': 4, 'col': 4, 'digit': 1, 'type': 'set'},
        ],
      };

      final step = SolveStep.fromJson(json);
      expect(step.sources, isEmpty);
      expect(step.actions[0].type, ActionType.set);
    });
  });
}
