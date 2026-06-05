import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/models/sudoku_peers.dart';
import '../../../shared/providers/persistence_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/services/persistence_service.dart';

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
  int? _savedGameId;

  @override
  GameState build() => _initialPuzzle;

  // Persists current board state + elapsed seconds to the in-progress table.
  // Inserts on first save; updates on subsequent saves using [_savedGameId].
  Future<void> saveProgress(int elapsedSeconds) async {
    final db = ref.read(persistenceProvider);
    final notesJson = jsonEncode([
      for (var r = 0; r < 9; r++)
        [for (var c = 0; c < 9; c++) state.notes[r][c].toList()..sort()],
    ]);
    final companion = InProgressGamesCompanion(
      id: _savedGameId != null ? Value(_savedGameId!) : const Value.absent(),
      puzzleId: const Value('local'),
      difficulty: const Value('unknown'),
      initialGrid: Value(jsonEncode(state.initialGrid)),
      currentGrid: Value(jsonEncode(state.currentGrid)),
      notes: Value(notesJson),
      elapsedSeconds: Value(elapsedSeconds),
      createdAt: const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
    await db.inProgressGameDao.save(companion);
    if (_savedGameId == null) {
      final saved = await db.inProgressGameDao.getCurrent();
      _savedGameId = saved?.id;
    }
  }

  // Loads a previously saved game, restoring board state.
  // Returns the saved elapsed seconds.
  int loadSavedGame(InProgressGame saved) {
    _savedGameId = saved.id;
    _history.clear();
    _redoStack.clear();
    final initial = (jsonDecode(saved.initialGrid) as List)
        .map((r) => (r as List).map((v) => v as int).toList())
        .toList();
    final current = (jsonDecode(saved.currentGrid) as List)
        .map((r) => (r as List).map((v) => v as int).toList())
        .toList();
    final notesRaw = jsonDecode(saved.notes) as List;
    final notes = [
      for (var r = 0; r < 9; r++)
        [
          for (var c = 0; c < 9; c++)
            (notesRaw[r][c] as List).map((v) => v as int).toSet(),
        ],
    ];
    state = GameState(initialGrid: initial, currentGrid: current, notes: notes);
    return saved.elapsedSeconds;
  }

  // Deletes the saved in-progress record (called on game completion or give-up).
  Future<void> clearSavedGame() async {
    if (_savedGameId == null) return;
    final db = ref.read(persistenceProvider);
    await db.inProgressGameDao.deleteGame(_savedGameId!);
    _savedGameId = null;
  }

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
