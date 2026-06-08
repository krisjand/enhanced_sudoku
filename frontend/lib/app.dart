import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'shared/providers/settings_provider.dart';
import 'shared/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(gameColorsProvider);
    return MaterialApp.router(
      title: 'Enhanced Sudoku',
      theme: AppTheme.build(colors),
      routerConfig: router ?? appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
