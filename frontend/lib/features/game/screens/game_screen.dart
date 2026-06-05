import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/digit_pad.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/game_state_notifier.dart';
import '../providers/notes_mode_provider.dart';
import '../providers/selection_provider.dart';

// Transient conflict state — row/col of the last rejected cell, cleared after
// a short delay so the cell flashes red then returns to normal.
class _ConflictNotifier extends Notifier<({int row, int col})?> {
  @override
  ({int row, int col})? build() => null;

  void flash(int row, int col) => state = (row: row, col: col);
  void clear() => state = null;
}

final _conflictProvider =
    NotifierProvider<_ConflictNotifier, ({int row, int col})?>(
      _ConflictNotifier.new,
    );

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final selection = ref.watch(selectionProvider);
    final isNotesMode = ref.watch(notesModeProvider);
    final conflict = ref.watch(_conflictProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SudokuGrid(
                  state: state,
                  selectedRow: selection?.row,
                  selectedCol: selection?.col,
                  conflictRow: conflict?.row,
                  conflictCol: conflict?.col,
                  onCellTap: (row, col) =>
                      ref.read(selectionProvider.notifier).select(row, col),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DigitPad(
              isEnabled: selection != null,
              isNotesMode: isNotesMode,
              onToggleNotes: ref.read(notesModeProvider.notifier).toggle,
              onDigitTap: (digit) {
                final sel = ref.read(selectionProvider);
                if (sel == null) return;
                final notifier = ref.read(gameStateProvider.notifier);
                if (isNotesMode) {
                  notifier.toggleNote(sel.row, sel.col, digit);
                } else {
                  final ok = notifier.enterDigit(sel.row, sel.col, digit);
                  if (!ok) {
                    final cn = ref.read(_conflictProvider.notifier);
                    cn.flash(sel.row, sel.col);
                    Future.delayed(const Duration(milliseconds: 600), cn.clear);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
