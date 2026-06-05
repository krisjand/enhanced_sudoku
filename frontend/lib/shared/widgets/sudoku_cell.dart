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

  Color get _background {
    if (hasConflict) return GameColors.errorDigit.withValues(alpha: 0.25);
    if (isSelected) return GameColors.selectedCell;
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
          : _NotesContent(notes: notes),
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
  const _NotesContent({required this.notes});

  final Set<int> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (row) {
        return Expanded(
          child: Row(
            children: List.generate(3, (col) {
              final digit = row * 3 + col + 1;
              return Expanded(
                child: Center(
                  child: notes.contains(digit)
                      ? FittedBox(
                          child: Text(
                            '$digit',
                            style: const TextStyle(color: GameColors.noteText),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
