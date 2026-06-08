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
    this.hasUnitTint = false,
    this.isSource = false,
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
  // Light tint for the unit being examined during hidden-singles show-and-tell.
  final bool hasUnitTint;
  // Green tint — marks source cells for elimination-based technique tutorials.
  final bool isSource;

  Color _background(GameColors c) {
    if (hasConflict) return c.errorDigit.withValues(alpha: 0.25);
    if (isSource) return c.sourceCell;
    if (isSelected || isDigitMatch) return c.selectedCell;
    if (hasWrongBackground) {
      return c.errorDigit.withValues(alpha: 0.25);
    }
    if (isTarget) return c.highlightedDigit.withValues(alpha: 0.5);
    if (hasUnitTint || isPeer) return c.peerCell;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<GameColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: _background(c),
        border: Border(
          right: BorderSide(color: rightBorderColor, width: rightBorderWidth),
          bottom: BorderSide(
            color: bottomBorderColor,
            width: bottomBorderWidth,
          ),
        ),
      ),
      child: digit != 0
          ? _DigitContent(digit: digit, isClue: isClue, c: c)
          : _NotesContent(
              notes: notes,
              highlightedNote: highlightedNote,
              wrongNoteDigits: wrongNoteDigits,
              c: c,
            ),
    );
  }
}

class _DigitContent extends StatelessWidget {
  const _DigitContent({
    required this.digit,
    required this.isClue,
    required this.c,
  });

  final int digit;
  final bool isClue;
  final GameColors c;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Text(
          '$digit',
          style: TextStyle(
            fontSize: constraints.maxWidth * 0.65,
            color: isClue ? c.clueDigit : c.userDigit,
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
    required this.c,
    this.highlightedNote,
    this.wrongNoteDigits = const {},
  });

  final Set<int> notes;
  final GameColors c;
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
                  color: isHighlit ? c.selectedCell : null,
                  child: Center(
                    child: notes.contains(digit)
                        ? FittedBox(
                            child: Text(
                              '$digit',
                              style: TextStyle(
                                color: isWrong ? c.errorDigit : c.noteText,
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
