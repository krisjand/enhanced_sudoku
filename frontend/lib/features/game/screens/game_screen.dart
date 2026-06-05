import 'package:flutter/material.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/widgets/sudoku_grid.dart';

// Naked-pair fixture from test_grids/naked_pair.json
final _testPuzzle = GameState(
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

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SudokuGrid(state: _testPuzzle),
      ),
    );
  }
}
