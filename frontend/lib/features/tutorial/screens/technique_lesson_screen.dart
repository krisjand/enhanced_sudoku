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
  final int _practiceIndex = 0;
  int? _wrongRow;
  int? _wrongCol;

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

  void _onReveal() => setState(() => _revealed = true);

  void _onApply() => setState(() => _applied = true);

  void _onNext() {
    setState(() {
      _phase = _Phase.find;
      _revealed = false;
      _applied = false;
    });
  }

  void _onCellTap(TutorialLesson lesson, int row, int col) {
    final board = lesson.practice[_practiceIndex];
    if (board.step == null || board.step!.actions.isEmpty) return;
    final target = board.step!.actions[0];
    if (row == target.row && col == target.col) {
      _onCorrect(lesson);
    } else {
      _flashWrong(row, col);
    }
  }

  void _onCorrect(TutorialLesson lesson) {
    ref.read(completedLessonsProvider.notifier).markComplete(lesson.technique);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Found it!'),
        content: Text(
          'You spotted the ${techniqueDisplayName(lesson.technique)}. '
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
          data: (lesson) => _phase == _Phase.observe
              ? _ObservePhase(
                  lesson: lesson,
                  revealed: _revealed,
                  applied: _applied,
                  boardState: _applied
                      ? _appliedState(lesson.explain)
                      : _boardToState(lesson.explain),
                  onReveal: _onReveal,
                  onApply: _onApply,
                  onNext: _onNext,
                )
              : _FindPhase(
                  lesson: lesson,
                  boardState: _boardToState(lesson.practice[_practiceIndex]),
                  wrongRow: _wrongRow,
                  wrongCol: _wrongCol,
                  onCellTap: (r, c) => _onCellTap(lesson, r, c),
                ),
        ),
      ),
    );
  }
}

class _ObservePhase extends StatelessWidget {
  const _ObservePhase({
    required this.lesson,
    required this.revealed,
    required this.applied,
    required this.boardState,
    required this.onReveal,
    required this.onApply,
    required this.onNext,
  });

  final TutorialLesson lesson;
  final bool revealed;
  final bool applied;
  final GameState boardState;
  final VoidCallback onReveal;
  final VoidCallback onApply;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final explain = lesson.explain;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Stack(
                children: [
                  SudokuGrid(state: boardState),
                  if (revealed && !applied && explain.step != null)
                    TechniqueOverlay(step: explain.step!, onDismiss: () {}),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            techniqueLessonIntro(lesson.technique),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (!revealed)
            FilledButton(onPressed: onReveal, child: const Text('Show me →'))
          else if (!applied)
            FilledButton(onPressed: onApply, child: const Text('Apply'))
          else
            FilledButton(onPressed: onNext, child: const Text('Next →')),
        ],
      ),
    );
  }
}

class _FindPhase extends StatelessWidget {
  const _FindPhase({
    required this.lesson,
    required this.boardState,
    required this.wrongRow,
    required this.wrongCol,
    required this.onCellTap,
  });

  final TutorialLesson lesson;
  final GameState boardState;
  final int? wrongRow;
  final int? wrongCol;
  final void Function(int row, int col) onCellTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SudokuGrid(
                state: boardState,
                conflictRow: wrongRow,
                conflictCol: wrongCol,
                onCellTap: onCellTap,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap the cell where you can apply ${techniqueDisplayName(lesson.technique)}.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
