import 'package:flutter/material.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import 'tutorial_widgets.dart';

// ── Cell picker ───────────────────────────────────────────────────────────────

// Board with multi-cell tap-to-toggle selection and a "Lock in" button.
// The parent manages [selectedCells] and provides [onCellTap] / [onLockIn].
// [flashCells] triggers a brief red background on incorrect selections.
class TutorialCellPickerBody extends StatelessWidget {
  const TutorialCellPickerBody({
    super.key,
    required this.boardState,
    required this.selectedCells,
    required this.onCellTap,
    required this.onLockIn,
    required this.instructionText,
    this.flashCells = const {},
  });

  final GameState boardState;
  final Set<(int, int)> selectedCells;
  final void Function(int, int) onCellTap;
  final VoidCallback onLockIn;
  final String instructionText;
  final Set<(int, int)> flashCells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveWrong = flashCells.isNotEmpty
        ? flashCells
        : const <(int, int)>{};
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: boardState,
            sourceCells: selectedCells,
            wrongCells: effectiveWrong,
            onCellTap: onCellTap,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  instructionText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: selectedCells.isNotEmpty ? onLockIn : null,
                  child: const Text('Lock in →'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Digit picker ──────────────────────────────────────────────────────────────

// Board (with source cells highlighted) + digit row. User taps to confirm.
// [flashDigit] briefly highlights an incorrect tap in red — parent clears it.
class TutorialDigitPickerBody extends StatelessWidget {
  const TutorialDigitPickerBody({
    super.key,
    required this.boardState,
    required this.sourceCells,
    required this.onDigitTap,
    required this.instructionText,
    this.flashDigit,
  });

  final GameState boardState;
  final Set<(int, int)> sourceCells;
  final void Function(int) onDigitTap;
  final String instructionText;
  final int? flashDigit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(state: boardState, sourceCells: sourceCells),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  instructionText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _FlashDigitRow(onDigitTap: onDigitTap, flashDigit: flashDigit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashDigitRow extends StatelessWidget {
  const _FlashDigitRow({required this.onDigitTap, this.flashDigit});

  final void Function(int) onDigitTap;
  final int? flashDigit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(9, (i) {
        final d = i + 1;
        final isFlash = d == flashDigit;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 1,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isFlash
                      ? colorScheme.errorContainer
                      : colorScheme.secondaryContainer,
                  foregroundColor: isFlash
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSecondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => onDigitTap(d),
                child: Text(
                  '$d',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Sub-type picker ───────────────────────────────────────────────────────────

// Board (source + target cells highlighted) + labelled option buttons.
// [options] is a list of (displayLabel, value) pairs.
// [flashValue] briefly colours the wrong button red.
class TutorialSubTypePickerBody extends StatelessWidget {
  const TutorialSubTypePickerBody({
    super.key,
    required this.boardState,
    required this.sourceCells,
    required this.targetCells,
    required this.options,
    required this.onSelect,
    required this.instructionText,
    this.flashValue,
  });

  final GameState boardState;
  final Set<(int, int)> sourceCells;
  final Set<(int, int)> targetCells;
  final List<(String label, String value)> options;
  final void Function(String) onSelect;
  final String instructionText;
  final String? flashValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: boardState,
            sourceCells: sourceCells,
            wrongCells: targetCells,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  instructionText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final isFlash = opt.$2 == flashValue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: isFlash
                            ? colorScheme.errorContainer
                            : colorScheme.secondaryContainer,
                        foregroundColor: isFlash
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                      onPressed: () => onSelect(opt.$2),
                      child: Text(opt.$1),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Eliminate notes ───────────────────────────────────────────────────────────

// Elimination phase for techniques that never place a digit.
// Notes mode is always on. Source cells shown in green, remaining targets in red.
class TutorialEliminateNotesBody extends StatelessWidget {
  const TutorialEliminateNotesBody({
    super.key,
    required this.boardState,
    required this.sourceCells,
    required this.remainingTargets,
    required this.digit,
    required this.remainingCount,
    required this.onCellTap,
    required this.onDigitTap,
    this.selRow,
    this.selCol,
  });

  final GameState boardState;
  final Set<(int, int)> sourceCells;
  final Set<(int, int)> remainingTargets;
  final int digit;
  final int remainingCount;
  final void Function(int, int) onCellTap;
  final void Function(int) onDigitTap;
  final int? selRow;
  final int? selCol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String descText;
    if (remainingCount > 0) {
      descText =
          'Tap each red cell to select it, then tap $digit to remove it '
          'from that cell\'s notes.\n'
          '$remainingCount cell${remainingCount == 1 ? '' : 's'} remaining.';
    } else {
      descText = 'All done!';
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: boardState,
            selectedRow: selRow,
            selectedCol: selCol,
            sourceCells: sourceCells,
            wrongCells: remainingTargets,
            wrongNotes: {
              for (final t in remainingTargets) t: {digit},
            },
            onCellTap: onCellTap,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  descText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TutorialDigitRow(onDigitTap: onDigitTap, markedDigit: digit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
