import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Sudoku')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
