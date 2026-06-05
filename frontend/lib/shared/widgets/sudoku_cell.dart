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
  });

  final int digit;
  final bool isClue;
  final Set<int> notes;
  final double rightBorderWidth;
  final double bottomBorderWidth;
  final Color rightBorderColor;
  final Color bottomBorderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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
    return Center(
      child: Text(
        '$digit',
        style: TextStyle(
          color: isClue ? GameColors.clueDigit : GameColors.userDigit,
          fontWeight: isClue ? FontWeight.bold : FontWeight.normal,
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
    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: List.generate(9, (i) {
        final digit = i + 1;
        return Center(
          child: notes.contains(digit)
              ? FittedBox(
                  child: Text(
                    '$digit',
                    style: const TextStyle(color: GameColors.noteText),
                  ),
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }
}
