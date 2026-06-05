import 'package:flutter/material.dart';

import '../models/cell_action.dart';
import '../models/solve_step.dart';
import '../utils/technique_names.dart';

// Positioned on top of a SudokuGrid inside a Stack.
// Colours source cells amber, set-action cells green, eliminate-action cells red.
// Tapping anywhere dismisses via [onDismiss].
class TechniqueOverlay extends StatelessWidget {
  const TechniqueOverlay({
    super.key,
    required this.step,
    required this.onDismiss,
  });

  final SolveStep step;
  final VoidCallback onDismiss;

  static const _outerBorder = 4.0;

  Color? _cellColor(int row, int col) {
    for (final src in step.sources) {
      if (src.row == row && src.col == col) {
        return Colors.amber.withValues(alpha: 0.45);
      }
    }
    for (final action in step.actions) {
      if (action.row == row && action.col == col) {
        return action.type == ActionType.set
            ? Colors.green.withValues(alpha: 0.5)
            : Colors.red.withValues(alpha: 0.45);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(_outerBorder),
              child: Column(
                children: List.generate(9, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(9, (col) {
                        final color = _cellColor(row, col);
                        return Expanded(
                          child: color != null
                              ? Container(color: color)
                              : const SizedBox.expand(),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    techniqueDisplayName(step.technique),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
