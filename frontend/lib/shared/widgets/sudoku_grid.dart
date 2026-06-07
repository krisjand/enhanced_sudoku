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
    this.isHighlightMode = true,
    this.onCellTap,
    this.targetRow,
    this.targetCol,
    this.wrongCells = const {},
    this.wrongNotes = const {},
  });

  final GameState state;
  final int? selectedRow;
  final int? selectedCol;
  final int? conflictRow;
  final int? conflictCol;
  final bool isHighlightMode;
  final void Function(int row, int col)? onCellTap;
  // Yellow highlight on the cell the user should interact with next.
  final int? targetRow;
  final int? targetCol;
  // Cells with invalid notes — shown with a red background.
  final Set<(int, int)> wrongCells;
  // Specific note digits rendered in red per cell.
  final Map<(int, int), Set<int>> wrongNotes;

  // The digit in the selected cell (1–9), or null when nothing useful to highlight.
  int? get selectedDigit {
    if (!isHighlightMode) return null;
    if (selectedRow == null || selectedCol == null) return null;
    final d = state.digit(selectedRow!, selectedCol!);
    return d == 0 ? null : d;
  }

  @override
  Widget build(BuildContext context) {
    final highlightDigit = selectedDigit;
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
                        isDigitMatch: isDigitMatch(row, col, highlightDigit),
                        highlightedNote: highlightedNote(
                          row,
                          col,
                          highlightDigit,
                        ),
                        isTarget: row == targetRow && col == targetCol,
                        hasWrongBackground: wrongCells.contains((row, col)),
                        wrongNoteDigits: wrongNotes[(row, col)] ?? const {},
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
    if (!isHighlightMode) return false;
    if (selectedRow == null || selectedCol == null) return false;
    return peerCells[selectedRow!][selectedCol!].any(
      (p) => p.row == row && p.col == col,
    );
  }

  // True when this cell holds the same placed digit as the selected cell
  // (but is not the selected cell itself).
  bool isDigitMatch(int row, int col, int? highlightDigit) {
    if (highlightDigit == null) return false;
    if (row == selectedRow && col == selectedCol) return false;
    return state.digit(row, col) == highlightDigit;
  }

  // Returns the note digit to highlight in this cell, or null.
  // Only applies to empty cells whose notes contain the selected digit.
  int? highlightedNote(int row, int col, int? highlightDigit) {
    if (highlightDigit == null) return null;
    if (state.digit(row, col) != 0) return null;
    return state.notes[row][col].contains(highlightDigit)
        ? highlightDigit
        : null;
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
