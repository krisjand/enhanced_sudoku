import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/game_state_notifier.dart';
import '../providers/selection_provider.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final selection = ref.watch(selectionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SudokuGrid(
          state: state,
          selectedRow: selection?.row,
          selectedCol: selection?.col,
          onCellTap: (row, col) =>
              ref.read(selectionProvider.notifier).select(row, col),
        ),
      ),
    );
  }
}
