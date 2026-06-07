import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/cell_action.dart';
import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/models/solve_step.dart';
import '../../../shared/models/tutorial_lesson.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/tutorial_provider.dart';
import 'tutorial_elimination_widgets.dart';

// Pedagogical order for show-and-tell cycling.
const _kSubTypeOrder = [
  'lockedCandidatesPointingRow',
  'lockedCandidatesPointingColumn',
  'lockedCandidatesReductionRow',
  'lockedCandidatesReductionColumn',
];

enum _Phase { intro, observe, findCells, findDigit, eliminate }

class LockedCandidatesLessonScreen extends ConsumerStatefulWidget {
  const LockedCandidatesLessonScreen({super.key});

  @override
  ConsumerState<LockedCandidatesLessonScreen> createState() =>
      _LockedCandidatesLessonScreenState();
}

class _LockedCandidatesLessonScreenState
    extends ConsumerState<LockedCandidatesLessonScreen> {
  _Phase _phase = _Phase.intro;

  // observe
  int _observeIdx = 0; // 0–3
  int _observeStep = 0; // sub-steps within one example

  // findCells
  final Set<(int, int)> _selectedCells = {};
  Set<(int, int)> _flashCells = {};

  // findDigit
  int? _flashDigit;

  // eliminate
  int? _selRow;
  int? _selCol;
  final Set<(int, int)> _doneEliminations = {};

  // practice state
  int _practiceIdx = 0; // 0–3
  SolveStep? _matchedStep; // set after a valid lock-in

  // organised boards — populated once lesson loads
  bool _boardsReady = false;
  late List<LessonBoard> _observeBoards; // 4 boards, one per sub-type
  late List<LessonBoard> _practiceBoards; // 4 boards, one per sub-type

  // ── Board organisation ────────────────────────────────────────────────────

  void _initBoards(TutorialLesson lesson) {
    if (_boardsReady) return;
    final all = [lesson.explain, ...lesson.practice];
    final observePick = <LessonBoard>[];
    final remaining = List<LessonBoard>.from(all);
    for (final sv in _kSubTypeOrder) {
      final idx = remaining.indexWhere((b) => b.subVariant == sv);
      if (idx >= 0) {
        observePick.add(remaining.removeAt(idx));
      }
    }
    // Practice: one per sub-type from what's left, same order.
    final practicePick = <LessonBoard>[];
    for (final sv in _kSubTypeOrder) {
      final idx = remaining.indexWhere((b) => b.subVariant == sv);
      if (idx >= 0) {
        practicePick.add(remaining.removeAt(idx));
      }
    }
    _observeBoards = observePick;
    _practiceBoards = practicePick;
    _boardsReady = true;
  }

  // ── Board accessors ───────────────────────────────────────────────────────

  LessonBoard get _currentObserveBoard => _observeBoards[_observeIdx];
  LessonBoard get _currentPracticeBoard => _practiceBoards[_practiceIdx];

  // ── Observe helpers (use board.step — single group) ───────────────────────

  Set<(int, int)> _sourceCells(LessonBoard board) => {
    for (final s in board.step!.sources) (s.row, s.col),
  };

  Set<(int, int)> _targetCells(LessonBoard board) => {
    for (final a in board.step!.actions)
      if (a.type == ActionType.eliminate) (a.row, a.col),
  };

  int _lockedDigit(LessonBoard board) => board.step!.actions.first.digit;

  Set<(int, int)> _confiningUnit(LessonBoard board) {
    final sv = board.subVariant ?? '';
    final sources = board.step!.sources;
    if (sources.isEmpty) return {};
    final r0 = sources.first.row;
    final c0 = sources.first.col;
    if (sv.startsWith('lockedCandidatesPointing')) {
      // Confining unit is the box.
      final br = (r0 ~/ 3) * 3;
      final bc = (c0 ~/ 3) * 3;
      return {
        for (var r = br; r < br + 3; r++)
          for (var c = bc; c < bc + 3; c++) (r, c),
      };
    } else if (sv == 'lockedCandidatesReductionRow') {
      return {for (var c = 0; c < 9; c++) (r0, c)};
    } else {
      return {for (var r = 0; r < 9; r++) (r, c0)};
    }
  }

  String _confiningUnitLabel(LessonBoard board) {
    final sv = board.subVariant ?? '';
    if (sv.startsWith('lockedCandidatesPointing')) return 'box';
    if (sv == 'lockedCandidatesReductionRow') {
      return 'row ${board.step!.sources.first.row + 1}';
    }
    return 'column ${board.step!.sources.first.col + 1}';
  }

  String _confinedUnitLabel(LessonBoard board) {
    final sv = board.subVariant ?? '';
    final targets = board.step!.actions;
    if (targets.isEmpty) return '';
    if (sv == 'lockedCandidatesPointingRow') {
      return 'row ${targets.first.row + 1}';
    }
    if (sv == 'lockedCandidatesPointingColumn') {
      return 'column ${targets.first.col + 1}';
    }
    // Reduction: confined to box.
    final r0 = board.step!.sources.first.row;
    final c0 = board.step!.sources.first.col;
    final br = (r0 ~/ 3) * 3;
    final bc = (c0 ~/ 3) * 3;
    final rowName = br == 0 ? 'top' : (br == 3 ? 'middle' : 'bottom');
    final colName = bc == 0 ? 'left' : (bc == 3 ? 'centre' : 'right');
    return 'the $rowName-$colName box';
  }

  // ── Practice helpers ──────────────────────────────────────────────────────

  String _findCellsInstruction(String sv) => switch (sv) {
    'lockedCandidatesPointingRow' =>
      'Find a Pointing Row: in one box, a digit\'s candidates all lie in '
          'the same row. Tap those cells, then tap Lock in.',
    'lockedCandidatesPointingColumn' =>
      'Find a Pointing Column: in one box, a digit\'s candidates all lie in '
          'the same column. Tap those cells, then tap Lock in.',
    'lockedCandidatesReductionRow' =>
      'Find a Reduction Row: in one row, a digit\'s candidates all lie in '
          'the same box. Tap those cells, then tap Lock in.',
    'lockedCandidatesReductionColumn' =>
      'Find a Reduction Column: in one column, a digit\'s candidates all '
          'lie in the same box. Tap those cells, then tap Lock in.',
    _ => 'Find the locked candidate group and tap Lock in.',
  };

  // ── GameState builders ────────────────────────────────────────────────────

  GameState _boardState(LessonBoard board) => GameState(
    initialGrid: board.initialGrid,
    currentGrid: board.currentGrid,
    notes: List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    ),
  );

  GameState _cleanedObserveState(LessonBoard board) {
    final digit = _lockedDigit(board);
    final targets = _targetCells(board);
    final notes = List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    );
    for (final (r, c) in targets) {
      notes[r][c].remove(digit);
    }
    return GameState(
      initialGrid: board.initialGrid,
      currentGrid: board.currentGrid,
      notes: notes,
    );
  }

  GameState _eliminatePhaseState(LessonBoard board) {
    final digit = _matchedStep!.actions.first.digit;
    final notes = List.generate(
      9,
      (r) => List.generate(9, (c) => board.notes[r][c].toSet()),
    );
    for (final (r, c) in _doneEliminations) {
      notes[r][c].remove(digit);
    }
    return GameState(
      initialGrid: board.initialGrid,
      currentGrid: board.currentGrid,
      notes: notes,
    );
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _onCellTap(int row, int col) {
    if (_phase != _Phase.findCells) return;
    setState(() {
      final key = (row, col);
      if (_selectedCells.contains(key)) {
        _selectedCells.remove(key);
      } else {
        _selectedCells.add(key);
      }
    });
  }

  void _onLockIn() {
    final board = _currentPracticeBoard;
    final targetSv = board.subVariant!;
    // Accept any individual group of the requested sub-type.
    SolveStep? matched;
    for (final step in board.allSteps) {
      if (step.technique != targetSv) continue;
      final sourcePairs = {for (final s in step.sources) (s.row, s.col)};
      if (_selectedCells.length == sourcePairs.length &&
          _selectedCells.containsAll(sourcePairs)) {
        matched = step;
        break;
      }
    }
    if (matched != null) {
      setState(() {
        _matchedStep = matched;
        _phase = _Phase.findDigit;
        _flashCells = {};
      });
    } else {
      final wrong = Set<(int, int)>.from(_selectedCells);
      setState(() => _flashCells = wrong);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _flashCells = {};
            _selectedCells.clear();
          });
        }
      });
    }
  }

  void _onDigitTap(int digit) {
    final expected = _matchedStep!.actions.first.digit;
    if (digit == expected) {
      final targets = {
        for (final a in _matchedStep!.actions)
          if (a.type == ActionType.eliminate) (a.row, a.col),
      };
      if (targets.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onPracticeRoundDone(),
        );
        return;
      }
      setState(() {
        _phase = _Phase.eliminate;
        _flashDigit = null;
        _doneEliminations.clear();
        _selRow = null;
        _selCol = null;
      });
    } else {
      setState(() => _flashDigit = digit);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _flashDigit = null);
      });
    }
  }

  void _onEliminateCellTap(int row, int col) => setState(() {
    _selRow = row;
    _selCol = col;
  });

  void _onEliminateDigitTap(int digit) {
    final r = _selRow;
    final c = _selCol;
    if (r == null || c == null) return;
    final locked = _matchedStep!.actions.first.digit;
    if (digit != locked) return;
    final allTargets = {
      for (final a in _matchedStep!.actions)
        if (a.type == ActionType.eliminate) (a.row, a.col),
    };
    final remaining = allTargets.difference(_doneEliminations);
    if (!remaining.contains((r, c))) return;
    setState(() => _doneEliminations.add((r, c)));
    if (_doneEliminations.length == allTargets.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onPracticeRoundDone(),
      );
    }
  }

  Future<void> _onPracticeRoundDone() async {
    if (_practiceIdx < _practiceBoards.length - 1) {
      setState(() {
        _practiceIdx++;
        _phase = _Phase.findCells;
        _selectedCells.clear();
        _flashCells = {};
        _flashDigit = null;
        _matchedStep = null;
        _doneEliminations.clear();
        _selRow = null;
        _selCol = null;
      });
    } else {
      await _showSuccess();
    }
  }

  Future<void> _showSuccess() async {
    ref
        .read(completedLessonsProvider.notifier)
        .markComplete('lockedCandidates');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Lesson complete!'),
        content: const Text(
          'You identified locked candidates across all four sub-types and '
          'eliminated the restricted digit from the affected cells.\n\n'
          'Tip: whenever a candidate in a box is confined to one row or column '
          '(or vice versa), use it to clean up the rest of that unit immediately.',
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
    final lessonAsync = ref.watch(tutorialLessonProvider('lockedCandidates'));
    return Scaffold(
      appBar: AppBar(title: const Text('Locked Candidates')),
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (lesson) {
            _initBoards(lesson);

            if (_phase == _Phase.intro) {
              return _IntroBody(
                onNext: () => setState(() => _phase = _Phase.observe),
              );
            }

            if (_phase == _Phase.observe) {
              final board = _currentObserveBoard;
              final isLast = _observeIdx == _observeBoards.length - 1;
              return _ObserveBody(
                key: ValueKey(_observeIdx),
                board: board,
                step: _observeStep,
                sourceCells: _sourceCells(board),
                targetCells: _targetCells(board),
                confiningUnit: _confiningUnit(board),
                confiningUnitLabel: _confiningUnitLabel(board),
                confinedUnitLabel: _confinedUnitLabel(board),
                lockedDigit: _lockedDigit(board),
                originalState: _boardState(board),
                cleanedState: _cleanedObserveState(board),
                isLastExample: isLast,
                onAdvanceStep: () => setState(() => _observeStep++),
                onNext: () => setState(() {
                  if (isLast) {
                    _phase = _Phase.findCells;
                  } else {
                    _observeIdx++;
                    _observeStep = 0;
                  }
                }),
              );
            }

            final board = _currentPracticeBoard;

            if (_phase == _Phase.findCells) {
              return TutorialCellPickerBody(
                key: ValueKey('findCells-$_practiceIdx'),
                boardState: _boardState(board),
                selectedCells: _selectedCells,
                flashCells: _flashCells,
                onCellTap: _onCellTap,
                onLockIn: _onLockIn,
                instructionText: _findCellsInstruction(board.subVariant ?? ''),
              );
            }

            if (_phase == _Phase.findDigit) {
              final matchedSources = {
                for (final s in _matchedStep!.sources) (s.row, s.col),
              };
              return TutorialDigitPickerBody(
                key: ValueKey('findDigit-$_practiceIdx'),
                boardState: _boardState(board),
                sourceCells: matchedSources,
                flashDigit: _flashDigit,
                onDigitTap: _onDigitTap,
                instructionText:
                    'The highlighted cells are your locked group. '
                    'Which digit is the locked candidate? Tap it below.',
              );
            }

            // _Phase.eliminate
            final matched = _matchedStep!;
            final matchedSources = {
              for (final s in matched.sources) (s.row, s.col),
            };
            final allTargets = {
              for (final a in matched.actions)
                if (a.type == ActionType.eliminate) (a.row, a.col),
            };
            final remaining = allTargets.difference(_doneEliminations);
            return TutorialEliminateNotesBody(
              key: ValueKey('eliminate-$_practiceIdx'),
              boardState: _eliminatePhaseState(board),
              sourceCells: matchedSources,
              remainingTargets: remaining,
              digit: matched.actions.first.digit,
              remainingCount: remaining.length,
              selRow: _selRow,
              selCol: _selCol,
              onCellTap: _onEliminateCellTap,
              onDigitTap: _onEliminateDigitTap,
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
            'Locked candidates',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This is the first technique that only removes candidates — no '
            'digit is placed. You will clean up notes instead.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'What is a locked candidate?',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A locked candidate is a digit whose only possible positions '
            'in one unit are all contained within another unit. Because '
            'the digit must go somewhere in the first unit, it can be '
            'eliminated from the rest of the second unit.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'Four sub-types',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _SubTypeCard(
            label: 'Pointing — row',
            description:
                'A digit in a box can only go in cells that all share '
                'the same row → eliminate it from the rest of that row.',
          ),
          _SubTypeCard(
            label: 'Pointing — column',
            description:
                'A digit in a box can only go in cells that all share '
                'the same column → eliminate it from the rest of that column.',
          ),
          _SubTypeCard(
            label: 'Reduction — row',
            description:
                'A digit in a row can only go in cells that all share '
                'the same box → eliminate it from the rest of that box.',
          ),
          _SubTypeCard(
            label: 'Reduction — column',
            description:
                'A digit in a column can only go in cells that all share '
                'the same box → eliminate it from the rest of that box.',
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onNext, child: const Text('See examples →')),
        ],
      ),
    );
  }
}

class _SubTypeCard extends StatelessWidget {
  const _SubTypeCard({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}

// ── Observe ───────────────────────────────────────────────────────────────────

class _ObserveBody extends StatelessWidget {
  const _ObserveBody({
    super.key,
    required this.board,
    required this.step,
    required this.sourceCells,
    required this.targetCells,
    required this.confiningUnit,
    required this.confiningUnitLabel,
    required this.confinedUnitLabel,
    required this.lockedDigit,
    required this.originalState,
    required this.cleanedState,
    required this.isLastExample,
    required this.onAdvanceStep,
    required this.onNext,
  });

  final LessonBoard board;
  final int step;
  final Set<(int, int)> sourceCells;
  final Set<(int, int)> targetCells;
  final Set<(int, int)> confiningUnit;
  final String confiningUnitLabel;
  final String confinedUnitLabel;
  final int lockedDigit;
  final GameState originalState;
  final GameState cleanedState;
  final bool isLastExample;
  final VoidCallback onAdvanceStep;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final GameState gridState;
    final Set<(int, int)> gridSources;
    final Set<(int, int)> gridTargets;
    final Set<(int, int)> gridUnit;
    final String descText;
    final String buttonLabel;

    switch (step) {
      case 0:
        gridState = originalState;
        gridSources = const {};
        gridTargets = const {};
        gridUnit = confiningUnit;
        descText =
            'Look at the highlighted $confiningUnitLabel. '
            'Can you spot a digit whose candidates all fall within '
            'a single row, column, or box?';
        buttonLabel = 'Reveal →';

      case 1:
        gridState = originalState;
        gridSources = sourceCells;
        gridTargets = const {};
        gridUnit = confiningUnit;
        descText =
            'Digit $lockedDigit in this $confiningUnitLabel can only go in '
            'the green cells — and they all lie within $confinedUnitLabel. '
            'Digit $lockedDigit is locked to $confinedUnitLabel!';
        buttonLabel = 'Show eliminations →';

      case 2:
        gridState = originalState;
        gridSources = sourceCells;
        gridTargets = targetCells;
        gridUnit = confiningUnit;
        descText =
            'Because digit $lockedDigit must be in $confinedUnitLabel '
            '(within this $confiningUnitLabel), no other cell in '
            '$confinedUnitLabel can hold $lockedDigit. '
            'The red cells carry $lockedDigit as a candidate — it must be removed.';
        buttonLabel = 'Remove them →';

      default: // step 3
        gridState = cleanedState;
        gridSources = sourceCells;
        gridTargets = const {};
        gridUnit = confiningUnit;
        final n = targetCells.length;
        descText =
            'Done. Digit $lockedDigit was eliminated from '
            '$n cell${n == 1 ? '' : 's'} outside the locked group.';
        buttonLabel = isLastExample
            ? 'Got it, let me try! →'
            : 'Next example →';
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: gridState,
            sourceCells: gridSources,
            wrongCells: gridTargets,
            unitCells: gridUnit,
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
                  onPressed: step < 3 ? onAdvanceStep : onNext,
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
