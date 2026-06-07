import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cell_action.dart';
import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/models/tutorial_lesson.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/tutorial_provider.dart';

enum _Phase { intro, observe, find, eliminate }

enum _UnitType { row, col, box }

// Number of boards used for show-and-tell; practice starts after these.
const _kObserveCount = 3;

class HiddenSinglesLessonScreen extends ConsumerStatefulWidget {
  const HiddenSinglesLessonScreen({super.key});

  @override
  ConsumerState<HiddenSinglesLessonScreen> createState() =>
      _HiddenSinglesLessonScreenState();
}

class _HiddenSinglesLessonScreenState
    extends ConsumerState<HiddenSinglesLessonScreen> {
  _Phase _phase = _Phase.intro;

  // observe
  int _exampleIndex = 0; // 0–2

  // find
  int? _selRow;
  int? _selCol;
  int? _wrongRow;
  int? _wrongCol;

  // eliminate
  int? _placedRow;
  int? _placedCol;
  int? _placedDigit;
  bool _notesOn = false;
  List<(int, int)> _pendingPeers = [];
  final Set<(int, int)> _eliminatedPeers = {};

  // ── Helpers ───────────────────────────────────────────────────────────────

  LessonBoard _observeBoard(TutorialLesson lesson) =>
      _exampleIndex == 0 ? lesson.explain : lesson.practice[_exampleIndex - 1];

  /// Returns the first (row, col, digit) set-action in the board's step.
  (int, int, int) _findHiddenSingle(LessonBoard board) {
    final step = board.step;
    if (step != null) {
      for (final a in step.actions) {
        if (a.type == ActionType.set) return (a.row, a.col, a.digit);
      }
    }
    return (0, 0, 1);
  }

  _UnitType _unitType(LessonBoard board) {
    final sv = board.subVariant ?? '';
    if (sv.contains('Column')) return _UnitType.col;
    if (sv.contains('Box')) return _UnitType.box;
    return _UnitType.row;
  }

  Set<(int, int)> _unitCells(_UnitType type, int row, int col) {
    switch (type) {
      case _UnitType.row:
        return {for (var c = 0; c < 9; c++) (row, c)};
      case _UnitType.col:
        return {for (var r = 0; r < 9; r++) (r, col)};
      case _UnitType.box:
        final br = (row ~/ 3) * 3;
        final bc = (col ~/ 3) * 3;
        return {
          for (var r = br; r < br + 3; r++)
            for (var c = bc; c < bc + 3; c++) (r, c),
        };
    }
  }

  String _unitLabel(_UnitType type, int row, int col) {
    switch (type) {
      case _UnitType.row:
        return 'row ${row + 1}';
      case _UnitType.col:
        return 'column ${col + 1}';
      case _UnitType.box:
        final br = (row ~/ 3) * 3;
        final bc = (col ~/ 3) * 3;
        final name = _boxName(br, bc);
        return '$name box';
    }
  }

  String _boxName(int br, int bc) {
    final rowName = br == 0 ? 'top' : (br == 3 ? 'middle' : 'bottom');
    final colName = bc == 0 ? 'left' : (bc == 3 ? 'centre' : 'right');
    return '$rowName-$colName';
  }

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

  List<(int, int)> _computePeers(LessonBoard board, int row, int col, int d) {
    final peers = <(int, int)>[];
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (r == row && c == col) continue;
        if ((r == row ||
                c == col ||
                (r >= br && r < br + 3 && c >= bc && c < bc + 3)) &&
            board.notes[r][c].contains(d)) {
          peers.add((r, c));
        }
      }
    }
    return peers;
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _onDigitFindTap(LessonBoard board, int d) {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    if (board.initialGrid[r][c] != 0) return;

    final (tr, tc, td) = _findHiddenSingle(board);
    if (r == tr && c == tc && d == td) {
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
    ref.read(completedLessonsProvider.notifier).markComplete('hiddenSingles');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Lesson complete!'),
        content: const Text(
          'You found the hidden single, placed the digit, and cleaned up '
          'the notes.\n\n'
          'Tip: scan each unit for digits that can only appear in one '
          'cell — whenever you spot one, place it immediately.',
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(tutorialLessonProvider('hiddenSingles'));
    return Scaffold(
      appBar: AppBar(title: const Text('Hidden Singles')),
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
              final board = _observeBoard(lesson);
              final isLast = _exampleIndex == _kObserveCount - 1;
              return _ObserveBody(
                key: ValueKey(_exampleIndex),
                board: board,
                hiddenSingle: _findHiddenSingle(board),
                unitType: _unitType(board),
                unitCellsFn: _unitCells,
                unitLabelFn: _unitLabel,
                isLastExample: isLast,
                onNext: () => setState(() {
                  if (isLast) {
                    _phase = _Phase.find;
                  } else {
                    _exampleIndex++;
                  }
                }),
              );
            }

            final practiceBoard = lesson.practice[_kObserveCount - 1];

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
            'Hidden singles',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You already know naked singles — cells where only one candidate '
            'remains. Hidden singles are the next step up.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'What is a hidden single?',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A hidden single is a digit that can only go in one cell within '
            'a particular row, column, or box — even though that cell still '
            'has other candidates.\n\n'
            'The digit is "hidden" among the other notes, but within its unit '
            'it has nowhere else to go.',
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
            'For each digit 1–9, scan every row, column, and box. If a '
            'digit appears as a note in exactly one cell of a unit, '
            'that cell must hold that digit.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onNext, child: const Text('See examples →')),
        ],
      ),
    );
  }
}

// ── Observe ───────────────────────────────────────────────────────────────────

class _ObserveBody extends StatefulWidget {
  const _ObserveBody({
    super.key,
    required this.board,
    required this.hiddenSingle,
    required this.unitType,
    required this.unitCellsFn,
    required this.unitLabelFn,
    required this.isLastExample,
    required this.onNext,
  });

  final LessonBoard board;
  final (int, int, int) hiddenSingle;
  final _UnitType unitType;
  final Set<(int, int)> Function(_UnitType, int, int) unitCellsFn;
  final String Function(_UnitType, int, int) unitLabelFn;
  final bool isLastExample;
  final VoidCallback onNext;

  @override
  State<_ObserveBody> createState() => _ObserveBodyState();
}

class _ObserveBodyState extends State<_ObserveBody> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (row, col, digit) = widget.hiddenSingle;
    final unitCells = widget.unitCellsFn(widget.unitType, row, col);
    final unitLabel = widget.unitLabelFn(widget.unitType, row, col);
    final typeLabel = switch (widget.unitType) {
      _UnitType.row => 'row',
      _UnitType.col => 'column',
      _UnitType.box => 'box',
    };

    final state = GameState(
      initialGrid: widget.board.initialGrid,
      currentGrid: widget.board.currentGrid,
      notes: List.generate(
        9,
        (r) => List.generate(9, (c) => widget.board.notes[r][c].toSet()),
      ),
    );

    final String descText;
    final String buttonLabel;

    if (!_revealed) {
      descText =
          'Look at the highlighted $typeLabel ($unitLabel). '
          'Which cells in this $typeLabel can contain digit $digit?';
      buttonLabel = 'Reveal →';
    } else {
      descText =
          'Only one cell in this $typeLabel has $digit as a candidate '
          '(highlighted in blue). Every other cell in this $typeLabel either '
          'already has a digit placed, or $digit is ruled out by its row, '
          'column, or box.\n\n'
          'Digit $digit must go in this cell — it is a hidden single!';
      buttonLabel = widget.isLastExample
          ? 'Got it, let me try! →'
          : 'Next example →';
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: state,
            selectedRow: _revealed ? row : null,
            selectedCol: _revealed ? col : null,
            targetRow: _revealed ? row : null,
            targetCol: _revealed ? col : null,
            unitCells: unitCells,
            singleHighlightRow: _revealed ? row : null,
            singleHighlightCol: _revealed ? col : null,
            singleHighlightDigit: _revealed ? digit : null,
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
                    if (!_revealed) {
                      setState(() => _revealed = true);
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
                  'Find the hidden single — a digit that can only appear in '
                  'one cell within its row, column, or box. Select the cell '
                  'and tap that digit to place it.',
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
