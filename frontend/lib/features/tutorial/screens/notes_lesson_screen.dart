import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/tutorial_provider.dart';

enum _Phase { guided, practice }

class NotesLessonScreen extends ConsumerStatefulWidget {
  const NotesLessonScreen({super.key});

  @override
  ConsumerState<NotesLessonScreen> createState() => _NotesLessonScreenState();
}

class _NotesLessonScreenState extends ConsumerState<NotesLessonScreen> {
  _Phase _phase = _Phase.guided;
  late List<List<Set<int>>> _playerNotes;
  List<(int, int)> _guideCells = [];
  int _guideBoxRow = 0;
  int _guideBoxCol = 0;
  int _guideIdx = 0;
  int? _invalidDigit;
  int? _pracSelRow;
  int? _pracSelCol;
  bool _done = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _playerNotes = List.generate(9, (_) => List.generate(9, (_) => {}));
  }

  void _init(LessonBoard board) {
    if (_initialized) return;
    _initialized = true;
    // Find the first 3×3 box with at least 2 empty cells to use as the guide box.
    for (var box = 0; box < 9; box++) {
      final br = (box ~/ 3) * 3;
      final bc = (box % 3) * 3;
      final cells = <(int, int)>[];
      for (var r = br; r < br + 3; r++) {
        for (var c = bc; c < bc + 3; c++) {
          if (board.initialGrid[r][c] == 0 && board.notes[r][c].isNotEmpty) {
            cells.add((r, c));
          }
        }
      }
      if (cells.length >= 2) {
        _guideCells = cells;
        _guideBoxRow = box ~/ 3;
        _guideBoxCol = box % 3;
        return;
      }
    }
    // Fallback: no suitable box — skip guided phase.
    _phase = _Phase.practice;
  }

  bool _isInGuideBox(int r, int c) =>
      r ~/ 3 == _guideBoxRow && c ~/ 3 == _guideBoxCol;

  bool _isCellComplete(LessonBoard board) {
    if (_guideIdx >= _guideCells.length) return false;
    final (r, c) = _guideCells[_guideIdx];
    final target = Set<int>.from(board.notes[r][c]);
    final entered = _playerNotes[r][c];
    return entered.length == target.length && target.every(entered.contains);
  }

  void _onGuidedDigitTap(LessonBoard board, int digit) {
    if (_guideIdx >= _guideCells.length) return;
    final (r, c) = _guideCells[_guideIdx];
    final target = Set<int>.from(board.notes[r][c]);
    setState(() {
      final notes = Set<int>.from(_playerNotes[r][c]);
      if (notes.contains(digit)) {
        notes.remove(digit);
        _invalidDigit = null;
      } else if (target.contains(digit)) {
        notes.add(digit);
        _invalidDigit = null;
      } else {
        _invalidDigit = digit;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _invalidDigit = null);
        });
        return;
      }
      _playerNotes[r][c] = notes;
    });
  }

  void _advanceGuide() {
    setState(() {
      _guideIdx++;
      if (_guideIdx >= _guideCells.length) {
        _phase = _Phase.practice;
      }
    });
  }

  void _onPracticeCellTap(int r, int c) {
    setState(() {
      _pracSelRow = r;
      _pracSelCol = c;
    });
  }

  void _onPracticeDigitTap(LessonBoard board, int digit) {
    final r = _pracSelRow;
    final c = _pracSelCol;
    if (r == null || c == null) return;
    if (board.initialGrid[r][c] != 0) return;
    if (_isInGuideBox(r, c)) return; // guide box is locked in practice

    setState(() {
      final notes = Set<int>.from(_playerNotes[r][c]);
      if (notes.contains(digit)) {
        notes.remove(digit);
      } else {
        notes.add(digit);
      }
      _playerNotes[r][c] = notes;
      if (!_done && _isPracticeComplete(board)) {
        _done = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
      }
    });
  }

  bool _isPracticeComplete(LessonBoard board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] != 0) continue;
        final target = Set<int>.from(board.notes[r][c]);
        final player = _playerNotes[r][c];
        if (player.length != target.length || !target.every(player.contains)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _showSuccess() async {
    ref.read(completedLessonsProvider.notifier).markComplete('notes');
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Lesson complete!'),
        content: const Text(
          'You filled in all the candidates correctly. '
          'Notes help you track possibilities as you solve.',
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
    final lessonAsync = ref.watch(notesLessonProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: SafeArea(
        child: lessonAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (lesson) {
            _init(lesson.practice);
            final board = lesson.practice;
            final state = GameState(
              initialGrid: board.initialGrid,
              currentGrid: board.currentGrid,
              notes: _playerNotes,
            );

            if (_phase == _Phase.guided) {
              final (gr, gc) = _guideIdx < _guideCells.length
                  ? _guideCells[_guideIdx]
                  : (0, 0);
              return _GuidedBody(
                board: board,
                guideCells: _guideCells,
                guideIdx: _guideIdx,
                playerNotes: _playerNotes,
                invalidDigit: _invalidDigit,
                isCellDone: _isCellComplete(board),
                boardState: state,
                selectedRow: _guideIdx < _guideCells.length ? gr : null,
                selectedCol: _guideIdx < _guideCells.length ? gc : null,
                onDigitTap: (d) => _onGuidedDigitTap(board, d),
                onAdvance: _advanceGuide,
              );
            }

            return _PracticeBody(
              boardState: state,
              selectedRow: _pracSelRow,
              selectedCol: _pracSelCol,
              invalidDigit: _invalidDigit,
              onCellTap: _onPracticeCellTap,
              onDigitTap: (d) => _onPracticeDigitTap(board, d),
            );
          },
        ),
      ),
    );
  }
}

// ── Guided phase ─────────────────────────────────────────────────────────────

class _GuidedBody extends StatelessWidget {
  const _GuidedBody({
    required this.board,
    required this.guideCells,
    required this.guideIdx,
    required this.playerNotes,
    required this.invalidDigit,
    required this.isCellDone,
    required this.boardState,
    required this.selectedRow,
    required this.selectedCol,
    required this.onDigitTap,
    required this.onAdvance,
  });

  final LessonBoard board;
  final List<(int, int)> guideCells;
  final int guideIdx;
  final List<List<Set<int>>> playerNotes;
  final int? invalidDigit;
  final bool isCellDone;
  final GameState boardState;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int) onDigitTap;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = guideIdx >= guideCells.length - 1;
    final (gr, gc) = guideIdx < guideCells.length
        ? guideCells[guideIdx]
        : (0, 0);
    final target = Set<int>.from(board.notes[gr][gc]);
    final entered = playerNotes[gr][gc];
    final foundCount = entered.intersection(target).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (guideIdx == 0) ...[
            Text(
              'Welcome to Sudoku',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'The goal is to fill every row, column, and 3×3 box with the '
              'digits 1–9, each appearing exactly once. There are many '
              'techniques to help you get there, and we will teach you them '
              'one by one. The core concept behind every technique is taking '
              'notes — and that is where we start.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            Text(
              'Reading the board',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'When you select a cell, the cells in the same row, column, '
              'and box are greyed out. These cells "see" the selected cell, '
              'meaning a digit can only be placed in the selected cell if it '
              'does not already appear in any of those greyed-out cells.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 24),
            Text(
              'Notes (candidates)',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Notes track which digits are still possible in each empty '
              "cell — the ones that don't appear in any greyed-out cell. "
              "Let's fill in one box together, one cell at a time.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 24),
          ],
          Text(
            'Cell ${guideIdx + 1} of ${guideCells.length} — '
            'tap every digit that could go in the highlighted cell.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (target.isNotEmpty && foundCount > 0 && foundCount < target.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$foundCount / ${target.length} found',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SudokuGrid(
            state: boardState,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
          ),
          const SizedBox(height: 12),
          _DigitRow(onDigitTap: onDigitTap, invalidDigit: invalidDigit),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isCellDone ? onAdvance : null,
            child: Text(isLast ? 'Start practice →' : 'Next cell →'),
          ),
        ],
      ),
    );
  }
}

// ── Practice phase ────────────────────────────────────────────────────────────

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.boardState,
    required this.selectedRow,
    required this.selectedCol,
    required this.invalidDigit,
    required this.onCellTap,
    required this.onDigitTap,
  });

  final GameState boardState;
  final int? selectedRow;
  final int? selectedCol;
  final int? invalidDigit;
  final void Function(int row, int col) onCellTap;
  final void Function(int) onDigitTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Now fill in the candidates for the rest of the grid. '
            'Tap a cell, then tap each digit that could go there.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SudokuGrid(
            state: boardState,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            onCellTap: onCellTap,
          ),
          const SizedBox(height: 12),
          _DigitRow(onDigitTap: onDigitTap, invalidDigit: invalidDigit),
        ],
      ),
    );
  }
}

// ── Shared digit row ──────────────────────────────────────────────────────────

class _DigitRow extends StatelessWidget {
  const _DigitRow({required this.onDigitTap, this.invalidDigit});

  final void Function(int) onDigitTap;
  final int? invalidDigit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(9, (i) {
        final d = i + 1;
        final isInvalid = d == invalidDigit;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 1,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isInvalid
                      ? colorScheme.errorContainer
                      : colorScheme.secondaryContainer,
                  foregroundColor: isInvalid
                      ? colorScheme.onErrorContainer
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
