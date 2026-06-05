import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../shared/models/solve_step.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../../shared/services/persistence_service.dart';
import '../../../shared/utils/format_time.dart';
import '../../../shared/widgets/digit_pad.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../../../shared/widgets/technique_overlay.dart';
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
  bool _hintLoading = false;
  SolveStep? _activeHint;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGame());
  }

  Future<void> _initGame() async {
    final saved = ref.read(pendingResumeProvider);
    if (saved != null) {
      ref.read(pendingResumeProvider.notifier).set(null);
      final elapsed = ref.read(gameStateProvider.notifier).loadSavedGame(saved);
      ref.read(timerProvider.notifier).start(elapsed);
    } else {
      await ref.read(gameStateProvider.notifier).reset();
      ref.read(selectionProvider.notifier).clear();
      ref.read(timerProvider.notifier).start(0);
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
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

  Future<void> _requestHint() async {
    setState(() => _hintLoading = true);
    final state = ref.read(gameStateProvider);
    final grid = List.generate(
      9,
      (r) => List.generate(9, (c) => state.digit(r, c)),
    );
    final candidates = List.generate(
      9,
      (r) => List.generate(9, (c) => state.notes[r][c].toList()..sort()),
    );
    try {
      final result = await ref
          .read(apiClientProvider)
          .getHint(grid, candidates: candidates);
      if (!mounted) return;
      if (result.solved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Puzzle already solved!')));
      } else if (result.stuck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hint available for this position.')),
        );
      } else {
        setState(() => _activeHint = result.step);
        _hintTimer = Timer(const Duration(seconds: 5), _applyAndDismissHint);
      }
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach the hint service.')),
        );
      }
    } finally {
      if (mounted) setState(() => _hintLoading = false);
    }
  }

  void _applyAndDismissHint() {
    _hintTimer?.cancel();
    _hintTimer = null;
    final hint = _activeHint;
    setState(() => _activeHint = null);
    if (hint != null) {
      ref.read(gameStateProvider.notifier).applyHintStep(hint);
    }
  }

  Future<void> _exitGame() async {
    final elapsed = ref.read(timerProvider);
    ref.read(timerProvider.notifier).stop();
    if (!ref.read(gameStateProvider).isPristine) {
      await ref.read(gameStateProvider.notifier).saveProgress(elapsed);
    }
    if (mounted) context.go(AppRoutes.home);
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
        appBar: AppBar(
          title: Text(formatTime(elapsed)),
          actions: [
            if (_hintLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'Hint',
                onPressed: _activeHint == null ? _requestHint : null,
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Stack(
                    children: [
                      SudokuGrid(
                        state: state,
                        selectedRow: selection?.row,
                        selectedCol: selection?.col,
                        conflictRow: conflict?.row,
                        conflictCol: conflict?.col,
                        isHighlightMode: isHighlightMode,
                        onCellTap: _activeHint != null
                            ? (_, _) => _applyAndDismissHint()
                            : (row, col) => ref
                                  .read(selectionProvider.notifier)
                                  .select(row, col),
                      ),
                      if (_activeHint != null)
                        TechniqueOverlay(
                          step: _activeHint!,
                          onDismiss: _applyAndDismissHint,
                        ),
                    ],
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
