import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cell_action.dart';
import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/models/tutorial_lesson.dart';
import '../../../shared/utils/technique_descriptions.dart';
import '../../../shared/utils/technique_names.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../../../shared/widgets/technique_overlay.dart';
import '../providers/tutorial_provider.dart';

enum _Phase { observe, find }

class TechniqueLessonScreen extends ConsumerStatefulWidget {
  const TechniqueLessonScreen({super.key, required this.technique});

  final String technique;

  @override
  ConsumerState<TechniqueLessonScreen> createState() =>
      _TechniqueLessonScreenState();
}

class _TechniqueLessonScreenState extends ConsumerState<TechniqueLessonScreen> {
  _Phase _phase = _Phase.observe;
  bool _revealed = false;
  bool _applied = false;
  bool _elimMsg = false; // observe: "Show effect →" pressed
  int? _wrongRow;
  int? _wrongCol;

  // find / elimination phase
  bool _digitPlaced = false;
  List<(int, int)> _pendingPeers = [];
  final Set<(int, int)> _eliminatedPeers = {};

  final int _practiceIndex = 0;

  bool get _needsEliminationTeaching =>
      widget.technique == 'nakedSingles' || widget.technique == 'hiddenSingles';

  GameState _boardToState(LessonBoard board) => GameState(
    initialGrid: board.initialGrid,
    currentGrid: board.currentGrid,
    notes: List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    ),
  );

  GameState _appliedState(LessonBoard board) {
    final newGrid = board.currentGrid.map((r) => List<int>.from(r)).toList();
    final newNotes = List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    );
    for (final action in board.step!.actions) {
      if (action.type == ActionType.set) {
        newGrid[action.row][action.col] = action.digit;
        newNotes[action.row][action.col] = {};
      } else if (action.type == ActionType.eliminate) {
        newNotes[action.row][action.col].remove(action.digit);
      }
    }
    return GameState(
      initialGrid: board.initialGrid,
      currentGrid: newGrid,
      notes: newNotes,
    );
  }

  List<(int, int)> _computePeers(
    LessonBoard board,
    int row,
    int col,
    int digit,
  ) {
    final peers = <(int, int)>[];
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (r == row && c == col) continue;
        if ((r == row ||
                c == col ||
                (r >= br && r < br + 3 && c >= bc && c < bc + 3)) &&
            board.notes[r][c].contains(digit)) {
          peers.add((r, c));
        }
      }
    }
    return peers;
  }

  // Observe phase: applied board with all peer notes removed (after "Show effect →").
  GameState _appliedWithElimsState(LessonBoard board) {
    final base = _appliedState(board);
    final target = board.step!.actions[0];
    final peers = _computePeers(board, target.row, target.col, target.digit);
    final newNotes = List.generate(
      9,
      (r) => List.generate(9, (c) => Set<int>.from(base.notes[r][c])),
    );
    for (final (r, c) in peers) {
      newNotes[r][c].remove(target.digit);
    }
    return GameState(
      initialGrid: base.initialGrid,
      currentGrid: base.currentGrid,
      notes: newNotes,
    );
  }

  // Find phase: applied board with only the already-eliminated peers cleaned up.
  GameState _eliminatingState(LessonBoard board) {
    final base = _appliedState(board);
    final target = board.step!.actions[0];
    final newNotes = List.generate(
      9,
      (r) => List.generate(9, (c) => Set<int>.from(base.notes[r][c])),
    );
    for (final (r, c) in _eliminatedPeers) {
      newNotes[r][c].remove(target.digit);
    }
    return GameState(
      initialGrid: base.initialGrid,
      currentGrid: base.currentGrid,
      notes: newNotes,
    );
  }

  void _onReveal() => setState(() => _revealed = true);
  void _onApply() => setState(() => _applied = true);
  void _onElimMsg() => setState(() => _elimMsg = true);

  void _onNext() {
    setState(() {
      _phase = _Phase.find;
      _revealed = false;
      _applied = false;
      _elimMsg = false;
      _digitPlaced = false;
      _pendingPeers = [];
      _eliminatedPeers.clear();
    });
  }

  void _onCellTap(TutorialLesson lesson, int row, int col) {
    if (_digitPlaced) {
      _onPeerTap(lesson, row, col);
      return;
    }
    final board = lesson.practice[_practiceIndex];
    if (board.step == null || board.step!.actions.isEmpty) return;
    final target = board.step!.actions[0];
    if (row == target.row && col == target.col) {
      if (_needsEliminationTeaching) {
        _startElimination(lesson);
      } else {
        _onCorrect(lesson);
      }
    } else {
      _flashWrong(row, col);
    }
  }

  void _startElimination(TutorialLesson lesson) {
    final board = lesson.practice[_practiceIndex];
    final target = board.step!.actions[0];
    final peers = _computePeers(board, target.row, target.col, target.digit);
    if (peers.isEmpty) {
      _onCorrect(lesson);
      return;
    }
    setState(() {
      _digitPlaced = true;
      _pendingPeers = peers;
      _eliminatedPeers.clear();
    });
  }

  void _onPeerTap(TutorialLesson lesson, int row, int col) {
    if (_eliminatedPeers.length == _pendingPeers.length) return;
    if (_eliminatedPeers.contains((row, col))) {
      return; // already done — ignore silently
    }

    if (_pendingPeers.contains((row, col))) {
      setState(() => _eliminatedPeers.add((row, col)));
      if (_eliminatedPeers.length == _pendingPeers.length) {
        _onCorrect(lesson);
      }
    } else {
      // Ignore taps on the placed cell itself; flash wrong for everything else.
      final board = lesson.practice[_practiceIndex];
      final target = board.step!.actions[0];
      if (row == target.row && col == target.col) return;
      _flashWrong(row, col);
    }
  }

  void _onCorrect(TutorialLesson lesson) {
    ref.read(completedLessonsProvider.notifier).markComplete(lesson.technique);
    final isElim = _needsEliminationTeaching;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(isElim ? 'Lesson complete!' : 'Found it!'),
        content: Text(
          isElim
              ? 'You placed the digit and cleaned up the notes correctly.\n\n'
                    'Tip: enable auto-note-removal in Settings to have the app '
                    'remove candidates automatically each time you place a digit.'
              : 'You spotted the ${techniqueDisplayName(lesson.technique)}. '
                    'Keep practising to get faster.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _flashWrong(int row, int col) {
    setState(() {
      _wrongRow = row;
      _wrongCol = col;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _wrongRow = null;
          _wrongCol = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(tutorialLessonProvider(widget.technique));

    return Scaffold(
      appBar: AppBar(title: Text(techniqueDisplayName(widget.technique))),
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (lesson) {
            final practiceBoard = lesson.practice[_practiceIndex];

            if (_phase == _Phase.observe) {
              final explainTarget = lesson.explain.step?.actions.firstOrNull;
              final GameState observeState;
              if (_applied && _elimMsg && _needsEliminationTeaching) {
                observeState = _appliedWithElimsState(lesson.explain);
              } else if (_applied) {
                observeState = _appliedState(lesson.explain);
              } else {
                observeState = _boardToState(lesson.explain);
              }
              // After applying a digit, select that cell so its peers are greyed out.
              final int? obsSelRow = (_applied && _needsEliminationTeaching)
                  ? explainTarget?.row
                  : null;
              final int? obsSelCol = (_applied && _needsEliminationTeaching)
                  ? explainTarget?.col
                  : null;

              return _ObservePhase(
                lesson: lesson,
                revealed: _revealed,
                applied: _applied,
                elimMsg: _elimMsg,
                needsElimTeaching: _needsEliminationTeaching,
                boardState: observeState,
                selectedRow: obsSelRow,
                selectedCol: obsSelCol,
                onReveal: _onReveal,
                onApply: _onApply,
                onElimMsg: _onElimMsg,
                onNext: _onNext,
              );
            }

            final GameState findState;
            final int? findSelRow;
            final int? findSelCol;
            if (_digitPlaced) {
              findState = _eliminatingState(practiceBoard);
              final t = practiceBoard.step?.actions.firstOrNull;
              findSelRow = t?.row;
              findSelCol = t?.col;
            } else {
              findState = _boardToState(practiceBoard);
              findSelRow = null;
              findSelCol = null;
            }

            return _FindPhase(
              lesson: lesson,
              boardState: findState,
              wrongRow: _wrongRow,
              wrongCol: _wrongCol,
              digitPlaced: _digitPlaced,
              pendingCount: _pendingPeers.length,
              eliminatedCount: _eliminatedPeers.length,
              selectedRow: findSelRow,
              selectedCol: findSelCol,
              onCellTap: (r, c) => _onCellTap(lesson, r, c),
            );
          },
        ),
      ),
    );
  }
}

// ── Observe phase ─────────────────────────────────────────────────────────────

class _ObservePhase extends StatelessWidget {
  const _ObservePhase({
    required this.lesson,
    required this.revealed,
    required this.applied,
    required this.elimMsg,
    required this.needsElimTeaching,
    required this.boardState,
    required this.onReveal,
    required this.onApply,
    required this.onElimMsg,
    required this.onNext,
    this.selectedRow,
    this.selectedCol,
  });

  final TutorialLesson lesson;
  final bool revealed;
  final bool applied;
  final bool elimMsg;
  final bool needsElimTeaching;
  final GameState boardState;
  final VoidCallback onReveal;
  final VoidCallback onApply;
  final VoidCallback onElimMsg;
  final VoidCallback onNext;
  final int? selectedRow;
  final int? selectedCol;

  @override
  Widget build(BuildContext context) {
    final explain = lesson.explain;
    final target = explain.step?.actions.firstOrNull;

    final String descText;
    if (!applied || !needsElimTeaching) {
      descText = techniqueLessonIntro(lesson.technique);
    } else if (!elimMsg) {
      final d = target?.digit;
      descText = d != null
          ? 'Placing the $d removes it as a candidate from every cell in '
                'the same row, column, and box. Tap "Show effect →" to see '
                'which notes are removed.'
          : 'Placing a digit removes it from the notes of all cells that see it.';
    } else {
      descText =
          'Those notes are now gone.\n\n'
          'Tip: in Settings you can enable auto-note-removal — the app '
          'will remove candidates automatically each time you place a digit.';
    }

    Widget button() {
      if (!revealed) {
        return FilledButton(
          onPressed: onReveal,
          child: const Text('Show me →'),
        );
      }
      if (!applied) {
        return FilledButton(onPressed: onApply, child: const Text('Apply'));
      }
      if (needsElimTeaching && !elimMsg) {
        return FilledButton(
          onPressed: onElimMsg,
          child: const Text('Show effect →'),
        );
      }
      return FilledButton(
        onPressed: onNext,
        child: Text(needsElimTeaching ? 'Practice →' : 'Next →'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  SudokuGrid(
                    state: boardState,
                    selectedRow: selectedRow,
                    selectedCol: selectedCol,
                  ),
                  if (revealed && !applied && explain.step != null)
                    TechniqueOverlay(step: explain.step!, onDismiss: () {}),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            descText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          button(),
        ],
      ),
    );
  }
}

// ── Find / elimination phase ──────────────────────────────────────────────────

class _FindPhase extends StatelessWidget {
  const _FindPhase({
    required this.lesson,
    required this.boardState,
    required this.wrongRow,
    required this.wrongCol,
    required this.digitPlaced,
    required this.pendingCount,
    required this.eliminatedCount,
    required this.onCellTap,
    this.selectedRow,
    this.selectedCol,
  });

  final TutorialLesson lesson;
  final GameState boardState;
  final int? wrongRow;
  final int? wrongCol;
  final bool digitPlaced;
  final int pendingCount;
  final int eliminatedCount;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onCellTap;

  @override
  Widget build(BuildContext context) {
    final target = lesson.practice.isNotEmpty
        ? lesson.practice[0].step?.actions.firstOrNull
        : null;
    final remaining = pendingCount - eliminatedCount;

    final String instrText;
    if (!digitPlaced) {
      instrText =
          'Tap the cell where you can apply '
          '${techniqueDisplayName(lesson.technique)}.';
    } else if (remaining > 0) {
      instrText =
          'Now tap each cell to remove ${target?.digit ?? '?'} from its '
          'notes — $remaining cell${remaining == 1 ? '' : 's'} remaining.';
    } else {
      instrText = 'All done!';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SudokuGrid(
                state: boardState,
                selectedRow: selectedRow,
                selectedCol: selectedCol,
                conflictRow: wrongRow,
                conflictCol: wrongCol,
                onCellTap: onCellTap,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            instrText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
