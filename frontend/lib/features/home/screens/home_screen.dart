import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../shared/providers/persistence_provider.dart';
import '../../../shared/services/persistence_service.dart';
import '../../game/screens/game_screen.dart';

final _inProgressGameProvider = FutureProvider.autoDispose<InProgressGame?>((
  ref,
) async {
  final db = ref.watch(persistenceProvider);
  return db.inProgressGameDao.getCurrent();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeAsync = ref.watch(_inProgressGameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Sudoku')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            resumeAsync.when(
              data: (saved) {
                if (saved == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume game'),
                      onPressed: () {
                        ref.read(pendingResumeProvider.notifier).set(saved);
                        context.push(AppRoutes.game);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.game),
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
