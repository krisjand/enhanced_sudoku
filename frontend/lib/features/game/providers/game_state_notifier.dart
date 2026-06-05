import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/models/sudoku_peers.dart';
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
  final List<GameState> _redoStack = [];

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

  // Fills every empty cell with its valid candidates (digits absent from its
  // row, column, and box). Replaces any existing notes; one undo step.
  // No-op (no history entry) when notes are already fully correct.
  void autoFillNotes() {
    final newNotes = List.generate(
      9,
      (r) => List.generate(9, (c) {
        if (!state.isEmpty(r, c)) return <int>{};
        final forbidden = <int>{};
        for (final peer in peerCells[r][c]) {
          final d = state.digit(peer.row, peer.col);
          if (d != 0) forbidden.add(d);
        }
        return {1, 2, 3, 4, 5, 6, 7, 8, 9}.difference(forbidden);
      }),
    );
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cur = state.notes[r][c];
        if (cur.length != newNotes[r][c].length ||
            !cur.containsAll(newNotes[r][c])) {
          _pushHistory();
          state = state.copyWith(notes: newNotes);
          return;
        }
      }
    }
  }

  void undo() {
    if (_history.isEmpty) return;
    _redoStack.add(state);
    state = _history.removeLast();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _history.add(state);
    state = _redoStack.removeLast();
  }

  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _pushHistory() {
    _history.add(state);
    _redoStack.clear();
  }
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

// Builds the new notes grid for a digit-placement event.
// Target cell is always cleared; if autoRemovePeers, the digit is removed from
// the pre-computed peer list (20 cells) rather than scanning all 81.
List<List<Set<int>>> _enterDigitNotes(
  List<List<Set<int>>> notes,
  int row,
  int col,
  int digit,
  bool autoRemovePeers,
) {
  final updated = [
    for (var r = 0; r < 9; r++) [...notes[r]],
  ];
  updated[row][col] = <int>{};
  if (autoRemovePeers && digit != 0) {
    for (final peer in peerCells[row][col]) {
      final peerNotes = updated[peer.row][peer.col];
      if (peerNotes.contains(digit)) {
        updated[peer.row][peer.col] = Set<int>.from(peerNotes)..remove(digit);
      }
    }
  }
  return updated;
}

List<List<Set<int>>> _updatedNotes(
  List<List<Set<int>>> notes,
  int row,
  int col,
  Set<int> cell,
) => [
  for (var r = 0; r < 9; r++)
    [for (var c = 0; c < 9; c++) (r == row && c == col) ? cell : notes[r][c]],
];
