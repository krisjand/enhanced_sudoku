import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/game_state.dart';
import '../../../shared/models/lesson_board.dart';
import '../../../shared/widgets/sudoku_grid.dart';
import '../providers/tutorial_provider.dart';

class NotesLessonScreen extends ConsumerStatefulWidget {
  const NotesLessonScreen({super.key});

  @override
  ConsumerState<NotesLessonScreen> createState() => _NotesLessonScreenState();
}

class _NotesLessonScreenState extends ConsumerState<NotesLessonScreen> {
  int? _selRow;
  int? _selCol;
  late List<List<Set<int>>> _playerNotes;
  bool _done = false;

  void _initNotes() {
    _playerNotes = List.generate(9, (_) => List.generate(9, (_) => {}));
  }

  @override
  void initState() {
    super.initState();
    _initNotes();
  }

  void _onCellTap(int row, int col) {
    setState(() {
      _selRow = row;
      _selCol = col;
    });
  }

  void _onDigitTap(LessonBoard board, int digit) {
    if (_selRow == null || _selCol == null) return;
    final r = _selRow!;
    final c = _selCol!;
    if (board.initialGrid[r][c] != 0) return; // clue
    if (board.currentGrid[r][c] != 0) return; // placed digit
    setState(() {
      final notes = Set<int>.from(_playerNotes[r][c]);
      if (notes.contains(digit)) {
        notes.remove(digit);
      } else {
        notes.add(digit);
      }
      _playerNotes[r][c] = notes;
      if (!_done && _isComplete(board)) {
        _done = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
      }
    });
  }

  bool _isComplete(LessonBoard board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board.initialGrid[r][c] != 0) continue;
        if (board.currentGrid[r][c] != 0) continue;
        final target = Set<int>.from(board.notes[r][c]);
        final player = _playerNotes[r][c];
        if (target.length != player.length) return false;
        for (final d in target) {
          if (!player.contains(d)) return false;
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
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lesson) => _LessonBody(
          board: lesson.practice,
          playerNotes: _playerNotes,
          selectedRow: _selRow,
          selectedCol: _selCol,
          onCellTap: _onCellTap,
          onDigitTap: (d) => _onDigitTap(lesson.practice, d),
        ),
      ),
    );
  }
}

class _LessonBody extends StatelessWidget {
  const _LessonBody({
    required this.board,
    required this.playerNotes,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    required this.onDigitTap,
  });

  final LessonBoard board;
  final List<List<Set<int>>> playerNotes;
  final int? selectedRow;
  final int? selectedCol;
  final void Function(int row, int col) onCellTap;
  final void Function(int digit) onDigitTap;

  GameState get _state => GameState(
    initialGrid: board.initialGrid,
    currentGrid: board.currentGrid,
    notes: playerNotes,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Fill in the candidates for every empty cell.\n'
            'Tap a cell, then tap digits to toggle pencil marks.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SudokuGrid(
            state: _state,
            selectedRow: selectedRow,
            selectedCol: selectedCol,
            onCellTap: onCellTap,
          ),
          const SizedBox(height: 20),
          _DigitRow(onDigitTap: onDigitTap),
        ],
      ),
    );
  }
}

class _DigitRow extends StatelessWidget {
  const _DigitRow({required this.onDigitTap});
  final void Function(int) onDigitTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(9, (i) {
        final d = i + 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 1,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
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
