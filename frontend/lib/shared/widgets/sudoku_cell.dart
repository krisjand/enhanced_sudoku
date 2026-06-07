import 'package:flutter/material.dart';

import '../theme/game_colors.dart';

class SudokuCell extends StatelessWidget {
  const SudokuCell({
    super.key,
    required this.digit,
    required this.isClue,
    required this.notes,
    required this.rightBorderWidth,
    required this.bottomBorderWidth,
    required this.rightBorderColor,
    required this.bottomBorderColor,
    this.isSelected = false,
    this.isPeer = false,
    this.hasConflict = false,
    this.isDigitMatch = false,
    this.highlightedNote,
    this.isTarget = false,
    this.hasWrongBackground = false,
    this.wrongNoteDigits = const {},
  });

  final int digit;
  final bool isClue;
  final Set<int> notes;
  final double rightBorderWidth;
  final double bottomBorderWidth;
  final Color rightBorderColor;
  final Color bottomBorderColor;
  final bool isSelected;
  final bool isPeer;
  final bool hasConflict;
  // True when another placed cell holds the same digit as the selected cell.
  final bool isDigitMatch;
  // When non-null, this note digit slot inside the notes grid is highlighted.
  final int? highlightedNote;
  // Yellow ring — marks the cell the user should interact with next.
  final bool isTarget;
  // Red background — marks a cell with invalid notes (tutorial use).
  final bool hasWrongBackground;
  // Specific note digits rendered in red (tutorial wrong-note feedback).
  final Set<int> wrongNoteDigits;

  Color get _background {
    if (hasConflict || hasWrongBackground) {
      return GameColors.errorDigit.withValues(alpha: 0.25);
    }
    if (isTarget) return GameColors.highlightedDigit.withValues(alpha: 0.5);
    if (isSelected || isDigitMatch) return GameColors.selectedCell;
    if (isPeer) return GameColors.peerCell;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _background,
        border: Border(
          right: BorderSide(color: rightBorderColor, width: rightBorderWidth),
          bottom: BorderSide(
            color: bottomBorderColor,
            width: bottomBorderWidth,
          ),
        ),
      ),
      child: digit != 0
          ? _DigitContent(digit: digit, isClue: isClue)
          : _NotesContent(
              notes: notes,
              highlightedNote: highlightedNote,
              wrongNoteDigits: wrongNoteDigits,
            ),
    );
  }
}

class _DigitContent extends StatelessWidget {
  const _DigitContent({required this.digit, required this.isClue});

  final int digit;
  final bool isClue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Text(
          '$digit',
          style: TextStyle(
            fontSize: constraints.maxWidth * 0.65,
            color: isClue ? GameColors.clueDigit : GameColors.userDigit,
            fontWeight: isClue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NotesContent extends StatelessWidget {
  const _NotesContent({
    required this.notes,
    this.highlightedNote,
    this.wrongNoteDigits = const {},
  });

  final Set<int> notes;
  final int? highlightedNote;
  final Set<int> wrongNoteDigits;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (row) {
        return Expanded(
          child: Row(
            children: List.generate(3, (col) {
              final digit = row * 3 + col + 1;
              final isHighlit =
                  digit == highlightedNote && notes.contains(digit);
              final isWrong = wrongNoteDigits.contains(digit);
              return Expanded(
                child: Container(
                  color: isHighlit ? GameColors.selectedCell : null,
                  child: Center(
                    child: notes.contains(digit)
                        ? FittedBox(
                            child: Text(
                              '$digit',
                              style: TextStyle(
                                color: isWrong
                                    ? GameColors.errorDigit
                                    : GameColors.noteText,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
