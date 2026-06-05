class GameState {
  const GameState({
    required this.initialGrid,
    required this.currentGrid,
    required this.notes,
  });

  final List<List<int>> initialGrid;
  final List<List<int>> currentGrid;
  final List<List<Set<int>>> notes;

  bool isClue(int row, int col) => initialGrid[row][col] != 0;

  int digit(int row, int col) {
    final clue = initialGrid[row][col];
    if (clue != 0) return clue;
    return currentGrid[row][col];
  }

  bool isEmpty(int row, int col) => digit(row, col) == 0;

  GameState copyWith({
    List<List<int>>? initialGrid,
    List<List<int>>? currentGrid,
    List<List<Set<int>>>? notes,
  }) {
    return GameState(
      initialGrid: initialGrid ?? this.initialGrid,
      currentGrid: currentGrid ?? this.currentGrid,
      notes: notes ?? this.notes,
    );
  }

  static GameState empty() => GameState(
    initialGrid: List.generate(9, (_) => List.filled(9, 0)),
    currentGrid: List.generate(9, (_) => List.filled(9, 0)),
    notes: List.generate(9, (_) => List.generate(9, (_) => {})),
  );
}
