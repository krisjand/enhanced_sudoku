import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cell_action.dart';
import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/tutorial_provider.dart';

enum _Phase { intro, observe, find, eliminate }

class NakedSinglesLessonScreen extends ConsumerStatefulWidget {
  const NakedSinglesLessonScreen({super.key});

  @override
  ConsumerState<NakedSinglesLessonScreen> createState() =>
      _NakedSinglesLessonScreenState();
}

class _NakedSinglesLessonScreenState
    extends ConsumerState<NakedSinglesLessonScreen> {
  _Phase _phase = _Phase.intro;

  // find phase
  int? _selRow;
  int? _selCol;
  int? _wrongRow;
  int? _wrongCol;

  // eliminate phase
  int? _placedRow;
  int? _placedCol;
  int? _placedDigit;
  bool _notesOn = false;
  List<(int, int)> _pendingPeers = [];
  final Set<(int, int)> _eliminatedPeers = {};

  // ── Board state helpers ───────────────────────────────────────────────────

  GameState _boardToState(LessonBoard board) => GameState(
    initialGrid: board.initialGrid,
    currentGrid: board.currentGrid,
    notes: List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    ),
  );

  GameState _eliminatePhaseState(LessonBoard board) {
    final pr = _placedRow!;
    final pc = _placedCol!;
    final pd = _placedDigit!;
    final newGrid = board.currentGrid.map((r) => List<int>.from(r)).toList();
    newGrid[pr][pc] = pd;
    final newNotes = List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    );
    newNotes[pr][pc] = {};
    for (final (r, c) in _eliminatedPeers) {
      newNotes[r][c].remove(pd);
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

  // Returns the (row, col, digit) of the naked single in the board.
  // Prefers board.step; falls back to scanning for a cell with one note.
  (int, int, int) _findNakedSingle(LessonBoard board) {
    final step = board.step;
    if (step != null) {
      for (final a in step.actions) {
        if (a.type == ActionType.set) return (a.row, a.col, a.digit);
      }
    }
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] == 0 && board.notes[r][c].length == 1) {
          return (r, c, board.notes[r][c].first);
        }
      }
    }
    return (0, 0, 1);
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _onDigitFindTap(LessonBoard board, int d) {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    if (board.initialGrid[r][c] != 0) return;

    if (board.notes[r][c].length == 1 && board.notes[r][c].first == d) {
      final peers = _computePeers(board, r, c, d);
      setState(() {
        _placedRow = r;
        _placedCol = c;
        _placedDigit = d;
        _pendingPeers = peers;
        _eliminatedPeers.clear();
        _phase = _Phase.eliminate;
        _selRow = null;
        _selCol = null;
        _notesOn = false;
      });
      if (peers.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
      }
    } else {
      _flashWrong(r, c);
    }
  }

  void _onDigitEliminateTap(int d) {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    if (!_notesOn) return;
    if (d != _placedDigit) return;
    if (!_pendingPeers.contains((r, c))) return;
    if (_eliminatedPeers.contains((r, c))) return;
    setState(() => _eliminatedPeers.add((r, c)));
    if (_eliminatedPeers.length == _pendingPeers.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
    }
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

  Future<void> _showSuccess() async {
    ref.read(completedLessonsProvider.notifier).markComplete('nakedSingles');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Lesson complete!'),
        content: const Text(
          'You found the naked single, placed the digit, and cleaned up '
          'the notes.\n\n'
          'Tip: enable auto-note-removal in Settings to have the app '
          'remove candidates automatically each time you place a digit.',
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

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(tutorialLessonProvider('nakedSingles'));
    return Scaffold(
      appBar: AppBar(title: const Text('Naked Singles')),
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (lesson) {
            if (_phase == _Phase.intro) {
              return _IntroBody(
                onNext: () => setState(() => _phase = _Phase.observe),
              );
            }

            if (_phase == _Phase.observe) {
              return _ObserveBody(
                board: lesson.explain,
                nakedSingle: _findNakedSingle(lesson.explain),
                onNext: () => setState(() => _phase = _Phase.find),
              );
            }

            final practiceBoard = lesson.practice[0];

            if (_phase == _Phase.find) {
              return _FindBody(
                boardState: _boardToState(practiceBoard),
                selRow: _selRow,
                selCol: _selCol,
                wrongRow: _wrongRow,
                wrongCol: _wrongCol,
                onCellTap: (r, c) => setState(() {
                  _selRow = r;
                  _selCol = c;
                }),
                onDigitTap: (d) => _onDigitFindTap(practiceBoard, d),
              );
            }

            // _Phase.eliminate
            final remaining = _pendingPeers
                .where((p) => !_eliminatedPeers.contains(p))
                .toSet();
            return _EliminateBody(
              boardState: _eliminatePhaseState(practiceBoard),
              selRow: _selRow,
              selCol: _selCol,
              notesOn: _notesOn,
              wrongCells: remaining,
              wrongNotes: {
                for (final p in remaining) p: {_placedDigit!},
              },
              placedDigit: _placedDigit!,
              remainingCount: remaining.length,
              onCellTap: (r, c) => setState(() {
                _selRow = r;
                _selCol = c;
              }),
              onDigitTap: _onDigitEliminateTap,
              onNotesToggle: () => setState(() => _notesOn = !_notesOn),
            );
          },
        ),
      ),
    );
  }
}

// ── Intro ─────────────────────────────────────────────────────────────────────

class _IntroBody extends StatelessWidget {
  const _IntroBody({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your first solving technique',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Now that you know how to fill in notes, you are ready to '
            'apply the first and simplest solving technique: naked singles.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'What is a naked single?',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A naked single is a cell where only one candidate digit remains. '
            'All other digits have been ruled out by the cells in its row, '
            'column, or box.\n\n'
            'Since no other digit can fit, that remaining candidate must be '
            'the answer — place it immediately.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'How to find one',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan the board for any cell that shows exactly one note. '
            'That is your naked single.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onNext,
            child: const Text('See an example →'),
          ),
        ],
      ),
    );
  }
}

// ── Observe (show and tell, 2 sub-steps) ─────────────────────────────────────

class _ObserveBody extends StatefulWidget {
  const _ObserveBody({
    required this.board,
    required this.nakedSingle,
    required this.onNext,
  });

  final LessonBoard board;
  final (int, int, int) nakedSingle;
  final VoidCallback onNext;

  @override
  State<_ObserveBody> createState() => _ObserveBodyState();
}

class _ObserveBodyState extends State<_ObserveBody> {
  int _step = 0;

  GameState _beforeState(LessonBoard board) => GameState(
    initialGrid: board.initialGrid,
    currentGrid: board.currentGrid,
    notes: List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    ),
  );

  GameState _afterState(LessonBoard board, int row, int col, int digit) {
    final newGrid = board.currentGrid.map((r) => List<int>.from(r)).toList();
    newGrid[row][col] = digit;
    final newNotes = List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    );
    newNotes[row][col] = {};
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (r == row && c == col) continue;
        if (r == row ||
            c == col ||
            (r >= br && r < br + 3 && c >= bc && c < bc + 3)) {
          newNotes[r][c].remove(digit);
        }
      }
    }
    return GameState(
      initialGrid: board.initialGrid,
      currentGrid: newGrid,
      notes: newNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final board = widget.board;
    final (row, col, digit) = widget.nakedSingle;

    final GameState gridState;
    final int? selRow;
    final int? selCol;
    final int? targetRow;
    final int? targetCol;
    final String descText;
    final String buttonLabel;

    if (_step == 0) {
      gridState = _beforeState(board);
      selRow = row;
      selCol = col;
      targetRow = row;
      targetCol = col;
      descText =
          'The highlighted cell has only one candidate: digit $digit.\n\n'
          'Every other digit is already present in its row, column, or box, '
          'so $digit is the only possibility. Place it immediately.';
      buttonLabel = 'Place it →';
    } else {
      gridState = _afterState(board, row, col, digit);
      selRow = row;
      selCol = col;
      targetRow = null;
      targetCol = null;
      descText =
          'Digit $digit is now placed.\n\n'
          'Every peer cell that still had $digit as a candidate (greyed cells) '
          'no longer needs it — $digit can appear only once in each row, '
          'column, and box, so those notes are removed.';
      buttonLabel = 'Got it →';
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: gridState,
            selectedRow: selRow,
            selectedCol: selCol,
            targetRow: targetRow,
            targetCol: targetCol,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  descText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (_step == 0) {
                      setState(() => _step = 1);
                    } else {
                      widget.onNext();
                    }
                  },
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Find ──────────────────────────────────────────────────────────────────────

class _FindBody extends StatelessWidget {
  const _FindBody({
    required this.boardState,
    required this.onCellTap,
    required this.onDigitTap,
    this.selRow,
    this.selCol,
    this.wrongRow,
    this.wrongCol,
  });

  final GameState boardState;
  final int? selRow;
  final int? selCol;
  final int? wrongRow;
  final int? wrongCol;
  final void Function(int, int) onCellTap;
  final void Function(int) onDigitTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: boardState,
            selectedRow: selRow,
            selectedCol: selCol,
            conflictRow: wrongRow,
            conflictCol: wrongCol,
            onCellTap: onCellTap,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Find the cell with only one candidate. '
                  'Select it, then tap that digit to place it.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _DigitRow(onDigitTap: onDigitTap),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Eliminate ─────────────────────────────────────────────────────────────────

class _EliminateBody extends StatelessWidget {
  const _EliminateBody({
    required this.boardState,
    required this.notesOn,
    required this.wrongCells,
    required this.wrongNotes,
    required this.placedDigit,
    required this.remainingCount,
    required this.onCellTap,
    required this.onDigitTap,
    required this.onNotesToggle,
    this.selRow,
    this.selCol,
  });

  final GameState boardState;
  final int? selRow;
  final int? selCol;
  final bool notesOn;
  final Set<(int, int)> wrongCells;
  final Map<(int, int), Set<int>> wrongNotes;
  final int placedDigit;
  final int remainingCount;
  final void Function(int, int) onCellTap;
  final void Function(int) onDigitTap;
  final VoidCallback onNotesToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String descText;
    if (!notesOn) {
      descText =
          'You placed digit $placedDigit — now remove it from the notes of '
          'every cell that can see it.\n\n'
          'First, switch to notes mode using the pencil button.';
    } else if (remainingCount > 0) {
      descText =
          'Notes mode is on. Tap each red cell to select it, '
          'then tap $placedDigit to remove it from that cell\'s notes.\n'
          '$remainingCount cell${remainingCount == 1 ? '' : 's'} remaining.';
    } else {
      descText = 'All done!';
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: boardState,
            selectedRow: selRow,
            selectedCol: selCol,
            wrongCells: wrongCells,
            wrongNotes: wrongNotes,
            onCellTap: onCellTap,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  descText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _NotesToggle(notesOn: notesOn, onToggle: onNotesToggle),
                if (notesOn && remainingCount > 0) ...[
                  const SizedBox(height: 12),
                  _DigitRow(onDigitTap: onDigitTap, markedDigit: placedDigit),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _NotesToggle extends StatelessWidget {
  const _NotesToggle({required this.notesOn, required this.onToggle});

  final bool notesOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.tonal(
      onPressed: onToggle,
      style: FilledButton.styleFrom(
        backgroundColor: notesOn
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        foregroundColor: notesOn
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSecondaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(notesOn ? Icons.edit : Icons.edit_off, size: 18),
          const SizedBox(width: 8),
          Text(notesOn ? 'Notes on' : 'Notes off'),
        ],
      ),
    );
  }
}

class _DigitRow extends StatelessWidget {
  const _DigitRow({required this.onDigitTap, this.markedDigit});

  final void Function(int) onDigitTap;
  final int? markedDigit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(9, (i) {
        final d = i + 1;
        final isMarked = d == markedDigit;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 1,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isMarked
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  foregroundColor: isMarked
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => onDigitTap(d),
                child: Text(
                  '$d',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
