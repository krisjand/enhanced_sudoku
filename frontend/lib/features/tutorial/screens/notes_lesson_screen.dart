import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/models/sudoku_peers.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/tutorial_provider.dart';

enum _Phase { intro, guided }

enum _SubStep {
  waitHighlight,
  waitCellTap,
  waitNotesOn,
  waitFirstNote,
  waitNoteRemoval,
  fillingNotes,
}

class NotesLessonScreen extends ConsumerStatefulWidget {
  const NotesLessonScreen({super.key});

  @override
  ConsumerState<NotesLessonScreen> createState() => _NotesLessonScreenState();
}

class _NotesLessonScreenState extends ConsumerState<NotesLessonScreen> {
  _Phase _phase = _Phase.intro;
  _SubStep _subStep = _SubStep.waitHighlight;

  int _guidedRow = 0;
  int _guidedCol = 0;
  bool _guidedInit = false;

  final List<List<Set<int>>> _playerNotes = List.generate(
    9,
    (_) => List.generate(9, (_) => {}),
  );

  bool _highlightOn = false;
  bool _anyTapped = false;
  int? _selectedRow;
  int? _selectedCol;

  bool _notesOn = false;
  bool _showNotesOffBanner = false;

  int? _invalidDigit;
  Set<(int, int)> _invalidPeers = {};
  int? _firstNoteDigit;

  Set<(int, int)> _badPeers = {};

  bool _done = false;

  void _initGuidedCell(LessonBoard board) {
    if (_guidedInit) return;
    _guidedInit = true;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] == 0 && board.notes[r][c].length >= 2) {
          _guidedRow = r;
          _guidedCol = c;
          return;
        }
      }
    }
  }

  void _onCellTap(int r, int c) {
    switch (_subStep) {
      case _SubStep.waitHighlight:
        setState(() {
          _anyTapped = true;
          _highlightOn = true;
          _selectedRow = r;
          _selectedCol = c;
        });
      case _SubStep.waitNoteRemoval:
      case _SubStep.fillingNotes:
        setState(() {
          _selectedRow = r;
          _selectedCol = c;
        });
      default:
        break;
    }
  }

  void _onAdvanceWaitHighlight() {
    setState(() {
      _subStep = _SubStep.waitCellTap;
      _selectedRow = _guidedRow;
      _selectedCol = _guidedCol;
    });
  }

  void _onAdvanceWaitCellTap() {
    setState(() {
      _subStep = _SubStep.waitNotesOn;
      _selectedRow = null;
      _selectedCol = null;
    });
  }

  void _onNotesToggle() {
    setState(() {
      _notesOn = !_notesOn;
      if (_notesOn && _subStep == _SubStep.waitNotesOn) {
        _subStep = _SubStep.waitFirstNote;
        _selectedRow = _guidedRow;
        _selectedCol = _guidedCol;
      }
    });
  }

  void _onDigitTap(LessonBoard board, int d) {
    switch (_subStep) {
      case _SubStep.waitFirstNote:
        _handleFirstNoteTap(board, d);
      case _SubStep.waitNoteRemoval:
        _handleNoteRemovalTap(d);
      case _SubStep.fillingNotes:
        _handleFillingNotesTap(board, d);
      default:
        break;
    }
  }

  void _handleFirstNoteTap(LessonBoard board, int d) {
    if (!_notesOn) {
      _showNotesOffReminder();
      return;
    }
    if (!board.notes[_guidedRow][_guidedCol].contains(d)) {
      final conflicting = peerCells[_guidedRow][_guidedCol]
          .where((p) => board.currentGrid[p.row][p.col] == d)
          .map((p) => (p.row, p.col))
          .toSet();
      setState(() {
        _invalidDigit = d;
        _invalidPeers = conflicting;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _invalidDigit = null;
            _invalidPeers = {};
          });
        }
      });
      return;
    }
    setState(() {
      _playerNotes[_guidedRow][_guidedCol] = {
        ..._playerNotes[_guidedRow][_guidedCol],
        d,
      };
      _firstNoteDigit = d;
      _enterNoteRemoval(board);
    });
  }

  void _enterNoteRemoval(LessonBoard board) {
    final d = _firstNoteDigit!;
    final bad = <(int, int)>{};
    for (final p in peerCells[_guidedRow][_guidedCol]) {
      if (board.initialGrid[p.row][p.col] == 0 &&
          !board.notes[p.row][p.col].contains(d)) {
        _playerNotes[p.row][p.col] = {..._playerNotes[p.row][p.col], d};
        bad.add((p.row, p.col));
      }
    }
    _badPeers = bad;
    if (_badPeers.isEmpty) {
      _subStep = _SubStep.fillingNotes;
      _notesOn = true;
      _selectedRow = null;
      _selectedCol = null;
    } else {
      _subStep = _SubStep.waitNoteRemoval;
      _selectedRow = null;
      _selectedCol = null;
    }
  }

  void _handleNoteRemovalTap(int d) {
    final r = _selectedRow;
    final c = _selectedCol;
    if (r == null || c == null) return;
    if (!_badPeers.contains((r, c))) return;
    if (d != _firstNoteDigit) return;
    setState(() {
      _playerNotes[r][c] = Set.from(_playerNotes[r][c])..remove(d);
      _badPeers = Set.from(_badPeers)..remove((r, c));
      if (_badPeers.isEmpty) {
        _subStep = _SubStep.fillingNotes;
        _notesOn = true;
        _selectedRow = null;
        _selectedCol = null;
      }
    });
  }

  void _handleFillingNotesTap(LessonBoard board, int d) {
    final r = _selectedRow;
    final c = _selectedCol;
    if (r == null || c == null) return;
    if (board.initialGrid[r][c] != 0) return;
    if (!_notesOn) {
      _showNotesOffReminder();
      return;
    }
    setState(() {
      final notes = Set<int>.from(_playerNotes[r][c]);
      if (notes.contains(d)) {
        notes.remove(d);
      } else {
        notes.add(d);
      }
      _playerNotes[r][c] = notes;
      if (!_done && _isPracticeComplete(board)) {
        _done = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
      }
    });
  }

  void _showNotesOffReminder() {
    setState(() => _showNotesOffBanner = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showNotesOffBanner = false);
    });
  }

  void _onHintTap(LessonBoard board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] != 0) continue;
        if (_playerNotes[r][c].any((d) => !board.notes[r][c].contains(d))) {
          setState(() {
            _selectedRow = r;
            _selectedCol = c;
          });
          return;
        }
      }
    }
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] != 0) continue;
        final target = board.notes[r][c];
        final player = _playerNotes[r][c];
        if (!target.every(player.contains) ||
            player.any((d) => !target.contains(d))) {
          setState(() {
            _selectedRow = r;
            _selectedCol = c;
          });
          return;
        }
      }
    }
  }

  bool _isPracticeComplete(LessonBoard board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] != 0) continue;
        final target = board.notes[r][c];
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

  String _buildDescText() {
    return switch (_subStep) {
      _SubStep.waitHighlight when !_anyTapped =>
        'Tap any cell on the board to select it.',
      _SubStep.waitHighlight =>
        'The grey cells are in the same row, column, and 3×3 box. '
            "They 'see' the selected cell — a digit placed here "
            'cannot appear in any of them.',
      _SubStep.waitCellTap =>
        "This is the cell we'll work on together. "
            'The grey cells all share a row, column, or box with it — '
            'they are its peers.',
      _SubStep.waitNotesOn =>
        'Notes track which digits could still go in an empty cell. '
            'Tap the pencil button to enable notes mode.',
      _SubStep.waitFirstNote =>
        'Notes mode is on. Tap a digit to record it as a '
            'candidate for this cell.',
      _SubStep.waitNoteRemoval =>
        'Some nearby cells have digit $_firstNoteDigit marked as a note, '
            'but it does not belong there. '
            'Tap each red cell and remove digit $_firstNoteDigit from it.',
      _SubStep.fillingNotes =>
        'Fill in candidates for every empty cell. '
            'Tap a cell, then tap each digit that could go there. '
            'Wrong candidates are shown in red.',
    };
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
            final board = lesson.practice;
            _initGuidedCell(board);

            if (_phase == _Phase.intro) {
              return _IntroBody(
                onStart: () => setState(() => _phase = _Phase.guided),
              );
            }

            // Wrong notes/cells — only active in relevant sub-steps
            final Map<(int, int), Set<int>> wrongNotes;
            final Set<(int, int)> wrongCells;
            if (_subStep == _SubStep.waitNoteRemoval) {
              wrongNotes = {
                for (final p in _badPeers) p: {_firstNoteDigit!},
              };
              wrongCells = Set.of(_badPeers);
            } else if (_subStep == _SubStep.fillingNotes) {
              final wn = <(int, int), Set<int>>{};
              final wc = <(int, int)>{};
              for (var r = 0; r < 9; r++) {
                for (var c = 0; c < 9; c++) {
                  if (board.initialGrid[r][c] != 0) continue;
                  final bad = _playerNotes[r][c]
                      .where((d) => !board.notes[r][c].contains(d))
                      .toSet();
                  if (bad.isNotEmpty) {
                    wn[(r, c)] = bad;
                    wc.add((r, c));
                  }
                }
              }
              wrongNotes = wn;
              wrongCells = wc;
            } else if (_subStep == _SubStep.waitFirstNote &&
                _invalidDigit != null) {
              wrongNotes = {};
              wrongCells = _invalidPeers;
            } else {
              wrongNotes = {};
              wrongCells = {};
            }

            final gameState = GameState(
              initialGrid: board.initialGrid,
              currentGrid: board.currentGrid,
              notes: _playerNotes,
            );

            final selRow = switch (_subStep) {
              _SubStep.waitCellTap || _SubStep.waitFirstNote => _guidedRow,
              _ => _selectedRow,
            };
            final selCol = switch (_subStep) {
              _SubStep.waitCellTap || _SubStep.waitFirstNote => _guidedCol,
              _ => _selectedCol,
            };
            final tgtRow = _subStep == _SubStep.waitCellTap ? _guidedRow : null;
            final tgtCol = _subStep == _SubStep.waitCellTap ? _guidedCol : null;

            void Function(int, int)? onCellTap = switch (_subStep) {
              _SubStep.waitHighlight ||
              _SubStep.waitNoteRemoval ||
              _SubStep.fillingNotes => _onCellTap,
              _ => null,
            };

            return _GuidedBody(
              gameState: gameState,
              subStep: _subStep,
              selectedRow: selRow,
              selectedCol: selCol,
              targetRow: tgtRow,
              targetCol: tgtCol,
              wrongCells: wrongCells,
              wrongNotes: wrongNotes,
              anyTapped: _anyTapped,
              highlightOn: _highlightOn,
              notesOn: _notesOn,
              invalidDigit: _invalidDigit,
              firstNoteDigit: _firstNoteDigit,
              showNotesOffBanner: _showNotesOffBanner,
              descText: _buildDescText(),
              onCellTap: onCellTap,
              onDigitTap: (d) => _onDigitTap(board, d),
              onAdvanceWaitHighlight: _onAdvanceWaitHighlight,
              onAdvanceWaitCellTap: _onAdvanceWaitCellTap,
              onNotesToggle: _onNotesToggle,
              onHintTap: () => _onHintTap(board),
            );
          },
        ),
      ),
    );
  }
}

// ── Intro phase ───────────────────────────────────────────────────────────────

class _IntroBody extends StatelessWidget {
  const _IntroBody({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When solving a Sudoku puzzle...',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The goal is to fill every row, column, and 3×3 box with the '
            'digits 1–9, each appearing exactly once. Every puzzle has a '
            'unique solution, and every technique is about narrowing down '
            'which digits can go where.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'Reading the board',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When you select a cell, the cells in the same row, column, '
            'and 3×3 box are greyed out. These are its peers — a digit '
            'placed in the selected cell cannot appear in any of them.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            'Notes (candidates)',
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A note in a cell records that a digit might still go there. '
            'When all other possibilities are eliminated, only one note '
            "remains — and that's the answer. "
            "Let's fill in a cell's notes together.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: onStart, child: const Text("Let's go →")),
        ],
      ),
    );
  }
}

// ── Guided phase ──────────────────────────────────────────────────────────────

class _GuidedBody extends StatelessWidget {
  const _GuidedBody({
    required this.gameState,
    required this.subStep,
    required this.selectedRow,
    required this.selectedCol,
    required this.targetRow,
    required this.targetCol,
    required this.wrongCells,
    required this.wrongNotes,
    required this.anyTapped,
    required this.highlightOn,
    required this.notesOn,
    required this.invalidDigit,
    required this.firstNoteDigit,
    required this.showNotesOffBanner,
    required this.descText,
    required this.onCellTap,
    required this.onDigitTap,
    required this.onAdvanceWaitHighlight,
    required this.onAdvanceWaitCellTap,
    required this.onNotesToggle,
    required this.onHintTap,
  });

  final GameState gameState;
  final _SubStep subStep;
  final int? selectedRow;
  final int? selectedCol;
  final int? targetRow;
  final int? targetCol;
  final Set<(int, int)> wrongCells;
  final Map<(int, int), Set<int>> wrongNotes;
  final bool anyTapped;
  final bool highlightOn;
  final bool notesOn;
  final int? invalidDigit;
  final int? firstNoteDigit;
  final bool showNotesOffBanner;
  final String descText;
  final void Function(int, int)? onCellTap;
  final void Function(int) onDigitTap;
  final VoidCallback onAdvanceWaitHighlight;
  final VoidCallback onAdvanceWaitCellTap;
  final VoidCallback onNotesToggle;
  final VoidCallback onHintTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: SudokuGrid(
            state: gameState,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            targetRow: targetRow,
            targetCol: targetCol,
            wrongCells: wrongCells,
            wrongNotes: wrongNotes,
            isHighlightMode: highlightOn,
            onCellTap: onCellTap,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showNotesOffBanner) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notes mode is off — tap the pencil button to '
                            'switch back.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  descText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return switch (subStep) {
      _SubStep.waitHighlight when !anyTapped => const SizedBox.shrink(),
      _SubStep.waitHighlight => FilledButton(
        onPressed: onAdvanceWaitHighlight,
        child: const Text('Got it →'),
      ),
      _SubStep.waitCellTap => FilledButton(
        onPressed: onAdvanceWaitCellTap,
        child: const Text('Got it →'),
      ),
      _SubStep.waitNotesOn => _NotesToggle(
        notesOn: notesOn,
        onToggle: onNotesToggle,
      ),
      _SubStep.waitFirstNote => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NotesToggle(notesOn: notesOn, onToggle: onNotesToggle),
          const SizedBox(height: 12),
          _DigitRow(onDigitTap: onDigitTap, invalidDigit: invalidDigit),
        ],
      ),
      _SubStep.waitNoteRemoval => _DigitRow(
        onDigitTap: onDigitTap,
        markedDigit: firstNoteDigit,
      ),
      _SubStep.fillingNotes => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NotesToggle(notesOn: notesOn, onToggle: onNotesToggle),
          const SizedBox(height: 12),
          _DigitRow(onDigitTap: onDigitTap),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onHintTap,
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Hint'),
          ),
        ],
      ),
    };
  }
}

// ── Notes toggle button ───────────────────────────────────────────────────────

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

// ── Digit row ─────────────────────────────────────────────────────────────────

class _DigitRow extends StatelessWidget {
  const _DigitRow({
    required this.onDigitTap,
    this.invalidDigit,
    this.markedDigit,
  });

  final void Function(int) onDigitTap;
  final int? invalidDigit;
  // Digit to visually highlight (e.g. the one the user should remove).
  final int? markedDigit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(9, (i) {
        final d = i + 1;
        final isInvalid = d == invalidDigit;
        final isMarked = d == markedDigit;
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
                      : isMarked
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  foregroundColor: isInvalid
                      ? colorScheme.onErrorContainer
                      : isMarked
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
