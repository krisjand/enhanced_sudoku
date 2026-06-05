class GameState {
  const GameState({
    required this.initialGrid,
    required this.currentGrid,
    required this.notes,
    this.selectedRow,
    this.selectedCol,
  });

  final List<List<int>> initialGrid;
  final List<List<int>> currentGrid;
  final List<List<Set<int>>> notes;
  final int? selectedRow;
  final int? selectedCol;

  bool get hasSelection => selectedRow != null;

  bool isClue(int row, int col) => initialGrid[row][col] != 0;

  int digit(int row, int col) {
    final clue = initialGrid[row][col];
    if (clue != 0) return clue;
    return currentGrid[row][col];
  }

  bool isEmpty(int row, int col) => digit(row, col) == 0;

  bool isSelected(int row, int col) => row == selectedRow && col == selectedCol;

  bool isPeer(int row, int col) {
    if (selectedRow == null) return false;
    if (isSelected(row, col)) return false;
    return row == selectedRow! ||
        col == selectedCol! ||
        (row ~/ 3 == selectedRow! ~/ 3 && col ~/ 3 == selectedCol! ~/ 3);
  }

  GameState copyWith({
    List<List<int>>? initialGrid,
    List<List<int>>? currentGrid,
    List<List<Set<int>>>? notes,
    Object? selectedRow = _sentinel,
    Object? selectedCol = _sentinel,
  }) {
    return GameState(
      initialGrid: initialGrid ?? this.initialGrid,
      currentGrid: currentGrid ?? this.currentGrid,
      notes: notes ?? this.notes,
      selectedRow: selectedRow == _sentinel
          ? this.selectedRow
          : selectedRow as int?,
      selectedCol: selectedCol == _sentinel
          ? this.selectedCol
          : selectedCol as int?,
    );
  }

  static GameState empty() => GameState(
    initialGrid: List.generate(9, (_) => List.filled(9, 0)),
    currentGrid: List.generate(9, (_) => List.filled(9, 0)),
    notes: List.generate(9, (_) => List.generate(9, (_) => {})),
  );
}

// Sentinel for copyWith nullable fields — lets callers pass explicit null.
const _sentinel = Object();
