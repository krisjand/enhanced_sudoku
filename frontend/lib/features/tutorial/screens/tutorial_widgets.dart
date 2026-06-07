import 'package:flutter/material.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/widgets/sudoku_grid.dart';

// Returns all cells in the same row, column, and box as (row, col) that
// still carry digit as a note. Shared by both singles lesson screens.
List<(int, int)> tutorialComputePeers(
  LessonBoard board,
  int row,
  int col,
  int digit,
) {
  final peers = <(int, int)>[];
  final br = (row ~/ 3) * 3;
  final bc = (col ~/ 3) * 3;
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      if (r == row && c == col) continue;
      if ((r == row ||
              c == col ||
              (r >= br && r < br + 3 && c >= bc && c < bc + 3)) &&
          board.notes[r][c].contains(digit)) {
        peers.add((r, c));
      }
    }
  }
  return peers;
}

// Shown when the placed digit has no peer notes to remove.
class TutorialNoPeersBody extends StatelessWidget {
  const TutorialNoPeersBody({
    super.key,
    required this.boardState,
    required this.digit,
    required this.message,
    required this.onDone,
  });

  final GameState boardState;
  final int digit;
  final String message;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AspectRatio(aspectRatio: 1, child: SudokuGrid(state: boardState)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onDone,
                  child: const Text('Finish lesson →'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Eliminate-phase body: user removes the placed digit from peer notes.
class TutorialEliminateBody extends StatelessWidget {
  const TutorialEliminateBody({
    super.key,
    required this.boardState,
    required this.notesOn,
    required this.wrongCells,
    required this.wrongNotes,
    required this.placedDigit,
    required this.remainingCount,
    required this.onCellTap,
    required this.onDigitTap,
    required this.onNotesToggle,
    this.selRow,
    this.selCol,
  });

  final GameState boardState;
  final int? selRow;
  final int? selCol;
  final bool notesOn;
  final Set<(int, int)> wrongCells;
  final Map<(int, int), Set<int>> wrongNotes;
  final int placedDigit;
  final int remainingCount;
  final void Function(int, int) onCellTap;
  final void Function(int) onDigitTap;
  final VoidCallback onNotesToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String descText;
    if (!notesOn) {
      descText =
          'You placed digit $placedDigit — now remove it from the notes of '
          'every cell that can see it.\n\n'
          'First, switch to notes mode using the pencil button.';
    } else if (remainingCount > 0) {
      descText =
          'Notes mode is on. Tap each red cell to select it, '
          'then tap $placedDigit to remove it from that cell\'s notes.\n'
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
            wrongCells: wrongCells,
            wrongNotes: wrongNotes,
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
                TutorialNotesToggle(notesOn: notesOn, onToggle: onNotesToggle),
                if (notesOn && remainingCount > 0) ...[
                  const SizedBox(height: 12),
                  TutorialDigitRow(
                    onDigitTap: onDigitTap,
                    markedDigit: placedDigit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TutorialNotesToggle extends StatelessWidget {
  const TutorialNotesToggle({
    super.key,
    required this.notesOn,
    required this.onToggle,
  });

  final bool notesOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.tonal(
      onPressed: onToggle,
      style: FilledButton.styleFrom(
        backgroundColor: notesOn
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        foregroundColor: notesOn
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSecondaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(notesOn ? Icons.edit : Icons.edit_off, size: 18),
          const SizedBox(width: 8),
          Text(notesOn ? 'Notes on' : 'Notes off'),
        ],
      ),
    );
  }
}

class TutorialDigitRow extends StatelessWidget {
  const TutorialDigitRow({
    super.key,
    required this.onDigitTap,
    this.markedDigit,
  });

  final void Function(int) onDigitTap;
  final int? markedDigit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(9, (i) {
        final d = i + 1;
        final isMarked = d == markedDigit;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 1,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isMarked
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  foregroundColor: isMarked
                      ? colorScheme.onPrimaryContainer
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
