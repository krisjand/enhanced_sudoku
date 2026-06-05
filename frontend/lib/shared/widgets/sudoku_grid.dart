import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../theme/game_colors.dart';
import 'sudoku_cell.dart';

const _thinBorder = 0.5;
const _thickBorder = 2.0;

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: GameColors.gridLineHeavy,
            width: _thickBorder,
          ),
        ),
        child: Column(
          children: List.generate(9, (row) {
            return Expanded(
              child: Row(
                children: List.generate(9, (col) {
                  return Expanded(
                    child: SudokuCell(
                      digit: state.digit(row, col),
                      isClue: state.isClue(row, col),
                      notes: state.notes[row][col],
                      rightBorderWidth: _rightBorder(col),
                      bottomBorderWidth: _bottomBorder(row),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  static double _rightBorder(int col) {
    if (col == 8) return 0;
    return col % 3 == 2 ? _thickBorder : _thinBorder;
  }

  static double _bottomBorder(int row) {
    if (row == 8) return 0;
    return row % 3 == 2 ? _thickBorder : _thinBorder;
  }
}
