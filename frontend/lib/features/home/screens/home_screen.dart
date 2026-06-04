import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Sudoku')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Home',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.game),
              child: const Text('New Game'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.tutorialList),
              child: const Text('Tutorial'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.scores),
              child: const Text('Scores'),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.settings),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
