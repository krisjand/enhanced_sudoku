import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../shared/services/persistence_service.dart';
import '../../../shared/widgets/digit_pad.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/game_state_notifier.dart';
import '../providers/highlight_provider.dart';
import '../providers/notes_mode_provider.dart';
import '../providers/selection_provider.dart';
import '../providers/timer_provider.dart';

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

// Written by HomeScreen before navigating to /game to trigger a resume.
class _PendingResumeNotifier extends Notifier<InProgressGame?> {
  @override
  InProgressGame? build() => null;
  void set(InProgressGame? game) => state = game;
}

final pendingResumeProvider =
    NotifierProvider<_PendingResumeNotifier, InProgressGame?>(
      _PendingResumeNotifier.new,
    );

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with WidgetsBindingObserver {
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGame());
  }

  void _initGame() {
    final saved = ref.read(pendingResumeProvider);
    if (saved != null) {
      ref.read(pendingResumeProvider.notifier).set(null);
      final elapsed = ref.read(gameStateProvider.notifier).loadSavedGame(saved);
      ref.read(timerProvider.notifier).start(elapsed);
    } else {
      ref.read(timerProvider.notifier).start(0);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final timer = ref.read(timerProvider.notifier);
    if (state == AppLifecycleState.hidden) {
      timer.pause();
    } else if (state == AppLifecycleState.resumed) {
      timer.resume();
    }
  }

  Future<void> _onPuzzleComplete() async {
    _completionHandled = true;
    final capturedElapsed = ref.read(timerProvider);
    ref.read(timerProvider.notifier).stop();
    await ref.read(gameStateProvider.notifier).clearSavedGame();
    if (mounted) context.go(AppRoutes.gameComplete, extra: capturedElapsed);
  }

  Future<void> _exitGame() async {
    final elapsed = ref.read(timerProvider);
    ref.read(timerProvider.notifier).stop();
    await ref.read(gameStateProvider.notifier).saveProgress(elapsed);
    if (mounted) context.go(AppRoutes.home);
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final gameNotifier = ref.read(gameStateProvider.notifier);
    final selection = ref.watch(selectionProvider);
    final isNotesMode = ref.watch(notesModeProvider);
    final conflict = ref.watch(_conflictProvider);
    final isHighlightMode = ref.watch(highlightModeProvider);
    final elapsed = ref.watch(timerProvider);

    // Completion detection: navigate once when all cells are filled.
    ref.listen(gameStateProvider, (_, next) {
      if (!_completionHandled && next.isSolved) _onPuzzleComplete();
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitGame();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_formatTime(elapsed))),
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
                    isHighlightMode: isHighlightMode,
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
                canUndo: gameNotifier.canUndo,
                onUndo: gameNotifier.undo,
                canRedo: gameNotifier.canRedo,
                onRedo: gameNotifier.redo,
                isHighlightMode: isHighlightMode,
                onToggleHighlight: ref
                    .read(highlightModeProvider.notifier)
                    .toggle,
                onAutoFillNotes: gameNotifier.autoFillNotes,
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
                      Future.delayed(
                        const Duration(milliseconds: 600),
                        cn.clear,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
