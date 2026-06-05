import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';

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
  @override
  GameState build() => _initialPuzzle;

  void selectCell(int row, int col) {
    if (state.isSelected(row, col)) {
      state = state.copyWith(selectedRow: null, selectedCol: null);
    } else {
      state = state.copyWith(selectedRow: row, selectedCol: col);
    }
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(
  GameStateNotifier.new,
);
