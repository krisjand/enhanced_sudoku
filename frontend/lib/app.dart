import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'shared/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Enhanced Sudoku',
      theme: AppTheme.light,
      routerConfig: router ?? appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
