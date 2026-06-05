import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../shared/providers/persistence_provider.dart';
import '../../../shared/services/persistence_service.dart';
import '../../game/screens/game_screen.dart';

final _inProgressGameProvider = StreamProvider.autoDispose<InProgressGame?>((
  ref,
) {
  final db = ref.watch(persistenceProvider);
  return db.inProgressGameDao.watchCurrent();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _onNewGame(
    BuildContext context,
    WidgetRef ref,
    InProgressGame? savedGame,
  ) async {
    if (savedGame != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start new game?'),
          content: const Text('Your current game will be discarded.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep playing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('New game'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (context.mounted) context.push(AppRoutes.game);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedGame = ref.watch(_inProgressGameProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Sudoku')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (savedGame != null) ...[
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume game'),
                onPressed: () {
                  ref.read(pendingResumeProvider.notifier).set(savedGame);
                  context.push(AppRoutes.game);
                },
              ),
              const SizedBox(height: 8),
            ],
            ElevatedButton(
              onPressed: () => _onNewGame(context, ref, savedGame),
              child: const Text('New Game'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push(AppRoutes.tutorialList),
              child: const Text('Tutorial'),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.scores),
              child: const Text('Scores'),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.settings),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
