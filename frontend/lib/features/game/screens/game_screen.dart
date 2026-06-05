import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/digit_pad.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/game_state_notifier.dart';
import '../providers/highlight_provider.dart';
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
    final gameNotifier = ref.read(gameStateProvider.notifier);
    final selection = ref.watch(selectionProvider);
    final isNotesMode = ref.watch(notesModeProvider);
    final conflict = ref.watch(_conflictProvider);
    final highlightState = ref.watch(highlightProvider);
    final highlightNotifier = ref.read(highlightProvider.notifier);

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
                  selectedRow: highlightState != null ? null : selection?.row,
                  selectedCol: highlightState != null ? null : selection?.col,
                  conflictRow: conflict?.row,
                  conflictCol: conflict?.col,
                  highlightedDigit: highlightState,
                  onCellTap: (row, col) {
                    if (highlightState != null) {
                      // Highlight mode: tapping a cell with a digit sets the
                      // highlighted digit; tapping an empty cell does nothing.
                      final d = state.digit(row, col);
                      if (d != 0) highlightNotifier.selectDigit(d);
                    } else {
                      ref.read(selectionProvider.notifier).select(row, col);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            DigitPad(
              isEnabled: selection != null && highlightState == null,
              isNotesMode: isNotesMode,
              onToggleNotes: ref.read(notesModeProvider.notifier).toggle,
              canUndo: gameNotifier.canUndo,
              onUndo: gameNotifier.undo,
              canRedo: gameNotifier.canRedo,
              onRedo: gameNotifier.redo,
              isHighlightMode: highlightState != null,
              onToggleHighlight: () {
                highlightNotifier.toggle();
                if (highlightState == null) {
                  ref.read(selectionProvider.notifier).clear();
                }
              },
              onDigitTap: (digit) {
                final sel = ref.read(selectionProvider);
                if (sel == null) return;
                if (isNotesMode) {
                  gameNotifier.toggleNote(sel.row, sel.col, digit);
                } else {
                  final ok = gameNotifier.enterDigit(sel.row, sel.col, digit);
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
