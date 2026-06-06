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
  bool _elimMsg = false;
  // hiddenSingles cycles through 3 observe examples before practice
  int _observeExampleIdx = 0;
  int? _wrongRow;
  int? _wrongCol;

  bool _digitPlaced = false;
  List<(int, int)> _pendingPeers = [];
  final Set<(int, int)> _eliminatedPeers = {};

  bool get _isHiddenSingles => widget.technique == 'hiddenSingles';
  bool get _needsEliminationTeaching =>
      widget.technique == 'nakedSingles' || widget.technique == 'hiddenSingles';
  // hiddenSingles uses explain + practice[0] + practice[1] as 3 observe examples;
  // actual practice starts at practice[2].
  int get _observeExampleCount => _isHiddenSingles ? 3 : 1;
  int get _practiceStartIndex => _isHiddenSingles ? 2 : 0;

  LessonBoard _currentObserveBoard(TutorialLesson lesson) {
    if (!_isHiddenSingles || _observeExampleIdx == 0) return lesson.explain;
    return lesson.practice[_observeExampleIdx - 1];
  }

  // Detects which unit makes the step on `board` a hidden single.
  String _hiddenSingleUnit(LessonBoard board) {
    if (board.step == null || board.step!.actions.isEmpty) return 'this unit';
    final action = board.step!.actions[0];
    final d = action.digit;
    final row = action.row;
    final col = action.col;
    final notes = board.notes;
    var rowCount = 0;
    var colCount = 0;
    for (var i = 0; i < 9; i++) {
      if (i != col && notes[row][i].contains(d)) rowCount++;
      if (i != row && notes[i][col].contains(d)) colCount++;
    }
    if (rowCount == 0) return 'row ${row + 1}';
    if (colCount == 0) return 'column ${col + 1}';
    return 'the box';
  }

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
    final moreExamples =
        _isHiddenSingles && _observeExampleIdx < _observeExampleCount - 1;
    setState(() {
      if (moreExamples) {
        _observeExampleIdx++;
      } else {
        _phase = _Phase.find;
      }
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
    final board = lesson.practice[_practiceStartIndex];
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
    final board = lesson.practice[_practiceStartIndex];
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
    if (_eliminatedPeers.contains((row, col))) return;

    if (_pendingPeers.contains((row, col))) {
      setState(() => _eliminatedPeers.add((row, col)));
      if (_eliminatedPeers.length == _pendingPeers.length) {
        _onCorrect(lesson);
      }
    } else {
      final board = lesson.practice[_practiceStartIndex];
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
            if (_phase == _Phase.observe) {
              final board = _currentObserveBoard(lesson);
              final target = board.step?.actions.firstOrNull;

              // Board state
              final GameState boardState;
              if (_applied && _elimMsg && _needsEliminationTeaching) {
                boardState = _appliedWithElimsState(board);
              } else if (_applied) {
                boardState = _appliedState(board);
              } else {
                boardState = _boardToState(board);
              }

              // Select the target cell after apply (greys out peers for cleanup step)
              // and after reveal for hiddenSingles (highlights the target cell).
              final int? selRow;
              final int? selCol;
              if (_applied && _needsEliminationTeaching) {
                selRow = target?.row;
                selCol = target?.col;
              } else if (_revealed && _isHiddenSingles) {
                selRow = target?.row;
                selCol = target?.col;
              } else {
                selRow = null;
                selCol = null;
              }

              // Overlay: only for techniques where the overlay adds value (not singles).
              final overlayStep =
                  (!_needsEliminationTeaching && _revealed && !_applied)
                  ? board.step
                  : null;

              // Description text computed here so _ObservePhase stays dumb.
              final String descText;
              if (_applied && _elimMsg) {
                descText =
                    'Those notes are now gone.\n\n'
                    'Tip: in Settings you can enable auto-note-removal — the app '
                    'removes candidates automatically each time you place a digit.';
              } else if (_applied) {
                final d = target?.digit;
                descText = d != null
                    ? 'Placing the $d removes it as a candidate from every cell '
                          'in the same row, column, and box. Tap "Show effect →" to '
                          'see which notes are removed.'
                    : 'Placing a digit removes it from the notes of all cells '
                          'that see it.';
              } else if (_isHiddenSingles && _revealed) {
                final d = target?.digit;
                final unit = _hiddenSingleUnit(board);
                descText = d != null
                    ? '$d can only go in this cell in $unit — every other cell '
                          'in that unit already has $d ruled out. Even though this '
                          'cell has other candidates, $d must go here.'
                    : techniqueLessonIntro(lesson.technique);
              } else if (_isHiddenSingles) {
                final n = _observeExampleIdx + 1;
                final total = _observeExampleCount;
                descText =
                    'Example $n of $total\n\n'
                    'Scan this board: one digit can only go in one place within '
                    'a row, column, or box. Find it and tap "Show me →".';
              } else {
                descText = techniqueLessonIntro(lesson.technique);
              }

              final String nextLabel;
              if (_isHiddenSingles &&
                  _observeExampleIdx < _observeExampleCount - 1) {
                nextLabel = 'Next example →';
              } else if (_needsEliminationTeaching) {
                nextLabel = 'Practice →';
              } else {
                nextLabel = 'Next →';
              }

              return _ObservePhase(
                revealed: _revealed,
                applied: _applied,
                elimMsg: _elimMsg,
                needsElimTeaching: _needsEliminationTeaching,
                boardState: boardState,
                selectedRow: selRow,
                selectedCol: selCol,
                overlayStep: overlayStep,
                descText: descText,
                nextLabel: nextLabel,
                onReveal: _onReveal,
                onApply: _onApply,
                onElimMsg: _onElimMsg,
                onNext: _onNext,
              );
            }

            // Find / elimination phase
            final practiceBoard = lesson.practice[_practiceStartIndex];
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

            final target = practiceBoard.step?.actions.firstOrNull;
            final remaining = _pendingPeers.length - _eliminatedPeers.length;
            final String instrText;
            if (!_digitPlaced) {
              instrText =
                  'Tap the cell where you can apply '
                  '${techniqueDisplayName(lesson.technique)}.';
            } else if (remaining > 0) {
              instrText =
                  'Now tap each cell to remove ${target?.digit ?? '?'} from '
                  'its notes — $remaining cell${remaining == 1 ? '' : 's'} '
                  'remaining.';
            } else {
              instrText = 'All done!';
            }

            return _FindPhase(
              boardState: findState,
              wrongRow: _wrongRow,
              wrongCol: _wrongCol,
              selectedRow: findSelRow,
              selectedCol: findSelCol,
              instrText: instrText,
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
    required this.revealed,
    required this.applied,
    required this.elimMsg,
    required this.needsElimTeaching,
    required this.boardState,
    required this.descText,
    required this.nextLabel,
    required this.onReveal,
    required this.onApply,
    required this.onElimMsg,
    required this.onNext,
    this.selectedRow,
    this.selectedCol,
    this.overlayStep,
  });

  final bool revealed;
  final bool applied;
  final bool elimMsg;
  final bool needsElimTeaching;
  final GameState boardState;
  final String descText;
  final String nextLabel;
  final VoidCallback onReveal;
  final VoidCallback onApply;
  final VoidCallback onElimMsg;
  final VoidCallback onNext;
  final int? selectedRow;
  final int? selectedCol;
  final dynamic overlayStep; // SolveStep? — null suppresses the overlay

  @override
  Widget build(BuildContext context) {
    Widget buildButton() {
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
      return FilledButton(onPressed: onNext, child: Text(nextLabel));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed-size grid: AspectRatio(1) gets its width from the Column
          // (full width minus padding), so height == width and never shifts.
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                SudokuGrid(
                  state: boardState,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                ),
                if (overlayStep != null)
                  TechniqueOverlay(step: overlayStep!, onDismiss: () {}),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    descText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  buildButton(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Find / elimination phase ──────────────────────────────────────────────────

class _FindPhase extends StatelessWidget {
  const _FindPhase({
    required this.boardState,
    required this.wrongRow,
    required this.wrongCol,
    required this.instrText,
    required this.onCellTap,
    this.selectedRow,
    this.selectedCol,
  });

  final GameState boardState;
  final int? wrongRow;
  final int? wrongCol;
  final String instrText;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onCellTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: SudokuGrid(
              state: boardState,
              selectedRow: selectedRow,
              selectedCol: selectedCol,
              conflictRow: wrongRow,
              conflictCol: wrongCol,
              onCellTap: onCellTap,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                instrText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
