import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/providers/settings_provider.dart';

// Naked-pair fixture — replaced by a real puzzle fetch in story #84.
final _initialPuzzle = GameState(
  initialGrid: const [
    [0, 0, 0, 2, 6, 0, 7, 0, 1],
    [6, 8, 0, 0, 7, 0, 0, 9, 0],
    [1, 9, 0, 0, 0, 4, 5, 0, 0],
    [8, 2, 0, 1, 0, 0, 0, 4, 0],
    [0, 0, 4, 6, 0, 2, 9, 0, 0],
    [0, 5, 0, 0, 0, 3, 0, 2, 8],
    [0, 0, 9, 3, 0, 0, 0, 7, 4],
    [0, 4, 0, 0, 5, 0, 0, 3, 6],
    [7, 0, 3, 0, 1, 8, 0, 0, 0],
  ],
  currentGrid: List.generate(9, (_) => List.filled(9, 0)),
  notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
);

class GameStateNotifier extends Notifier<GameState> {
  final List<GameState> _history = [];

  @override
  GameState build() => _initialPuzzle;

  // Returns true if placing [digit] at [row,col] conflicts with an existing
  // digit in the same row, column, or 3×3 box.
  bool isConflict(int row, int col, int digit) {
    for (var c = 0; c < 9; c++) {
      if (c != col && state.digit(row, c) == digit) return true;
    }
    for (var r = 0; r < 9; r++) {
      if (r != row && state.digit(r, col) == digit) return true;
    }
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = br; r < br + 3; r++) {
      for (var c = bc; c < bc + 3; c++) {
        if ((r != row || c != col) && state.digit(r, c) == digit) return true;
      }
    }
    return false;
  }

  // Places [digit] in [row,col], or clears the cell if it already holds [digit].
  // Clears notes in the target cell; optionally removes that digit from peer
  // notes in one atomic update (same undo step). Rejects if conflicting.
  bool enterDigit(int row, int col, int digit) {
    if (state.isClue(row, col)) return false;
    if (isConflict(row, col, digit)) return false;

    _pushHistory();
    final current = state.currentGrid[row][col];
    final newDigit = current == digit ? 0 : digit;
    final autoRemove = ref.read(settingsProvider).autoRemoveNotes;
    state = state.copyWith(
      currentGrid: _updatedGrid(state.currentGrid, row, col, newDigit),
      notes: _enterDigitNotes(state.notes, row, col, newDigit, autoRemove),
    );
    return true;
  }

  // Toggles [digit] as a pencil mark in [row,col].
  void toggleNote(int row, int col, int digit) {
    if (state.isClue(row, col)) return;
    if (state.currentGrid[row][col] != 0) return;

    _pushHistory();
    final cell = Set<int>.from(state.notes[row][col]);
    if (cell.contains(digit)) {
      cell.remove(digit);
    } else {
      cell.add(digit);
    }
    state = state.copyWith(notes: _updatedNotes(state.notes, row, col, cell));
  }

  void undo() {
    if (_history.isEmpty) return;
    state = _history.removeLast();
  }

  bool get canUndo => _history.isNotEmpty;

  void _pushHistory() => _history.add(state);
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(
  GameStateNotifier.new,
);

// ── Immutable helpers ──────────────────────────────────────────────────────────

List<List<int>> _updatedGrid(
  List<List<int>> grid,
  int row,
  int col,
  int value,
) => [
  for (var r = 0; r < 9; r++)
    [for (var c = 0; c < 9; c++) (r == row && c == col) ? value : grid[r][c]],
];

// Builds the new notes grid for a digit-placement event in one pass:
// - target cell (row, col): always cleared
// - peer cells: digit removed if autoRemovePeers is true
bool _isPeerCell(int r, int c, int row, int col) =>
    (r != row || c != col) &&
    (r == row || c == col || (r ~/ 3 == row ~/ 3 && c ~/ 3 == col ~/ 3));

List<List<Set<int>>> _enterDigitNotes(
  List<List<Set<int>>> notes,
  int row,
  int col,
  int digit,
  bool autoRemovePeers,
) => [
  for (var r = 0; r < 9; r++)
    [
      for (var c = 0; c < 9; c++)
        if (r == row && c == col)
          <int>{}
        else if (autoRemovePeers &&
            _isPeerCell(r, c, row, col) &&
            notes[r][c].contains(digit))
          (Set<int>.from(notes[r][c])..remove(digit))
        else
          notes[r][c],
    ],
];

List<List<Set<int>>> _updatedNotes(
  List<List<Set<int>>> notes,
  int row,
  int col,
  Set<int> cell,
) => [
  for (var r = 0; r < 9; r++)
    [for (var c = 0; c < 9; c++) (r == row && c == col) ? cell : notes[r][c]],
];
