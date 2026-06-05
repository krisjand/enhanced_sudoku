import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/sudoku_peers.dart';
import '../theme/game_colors.dart';
import 'sudoku_cell.dart';

const _thinBorder = 2.0;
const _thickBorder = 4.0;

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({
    super.key,
    required this.state,
    this.selectedRow,
    this.selectedCol,
    this.conflictRow,
    this.conflictCol,
    this.onCellTap,
  });

  final GameState state;
  final int? selectedRow;
  final int? selectedCol;
  final int? conflictRow;
  final int? conflictCol;
  final void Function(int row, int col)? onCellTap;

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
                    child: GestureDetector(
                      onTap: () => onCellTap?.call(row, col),
                      child: SudokuCell(
                        digit: state.digit(row, col),
                        isClue: state.isClue(row, col),
                        notes: state.notes[row][col],
                        rightBorderWidth: _rightBorder(col),
                        bottomBorderWidth: _bottomBorder(row),
                        rightBorderColor: _borderColor(_rightBorder(col)),
                        bottomBorderColor: _borderColor(_bottomBorder(row)),
                        isSelected: row == selectedRow && col == selectedCol,
                        isPeer: isPeer(row, col),
                        hasConflict: row == conflictRow && col == conflictCol,
                      ),
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

  bool isPeer(int row, int col) {
    if (selectedRow == null) return false;
    return peerCells[selectedRow!][selectedCol!].any(
      (p) => p.row == row && p.col == col,
    );
  }

  static Color _borderColor(double width) => width == _thickBorder
      ? GameColors.gridLineHeavy
      : GameColors.gridLineLight;

  static double _rightBorder(int col) {
    if (col == 8) return 0;
    return col % 3 == 2 ? _thickBorder : _thinBorder;
  }

  static double _bottomBorder(int row) {
    if (row == 8) return 0;
    return row % 3 == 2 ? _thickBorder : _thinBorder;
  }
}
