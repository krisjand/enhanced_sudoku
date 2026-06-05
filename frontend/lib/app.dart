import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'shared/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, GoRouter? router}) : _router = router;

  final GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Enhanced Sudoku',
      theme: AppTheme.light,
      routerConfig: _router ?? appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
