import 'package:go_router/go_router.dart';

import 'features/developer/screens/developer_tools_screen.dart';
import 'features/game/screens/game_complete_screen.dart';
import 'features/game/screens/game_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/scores/screens/scores_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/tutorial/screens/tutorial_list_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const game = '/game';
  static const gameComplete = '/game/complete';
  static const tutorialList = '/tutorial';
  static const scores = '/scores';
  static const settings = '/settings';
  static const developerTools = '/settings/dev-tools';
}

GoRouter buildAppRouter() => GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) => const GameScreen(),
      routes: [
        GoRoute(
          path: 'complete',
          builder: (context, state) =>
              GameCompleteScreen(elapsedSeconds: (state.extra as int?) ?? 0),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.tutorialList,
      builder: (context, state) => const TutorialListScreen(),
    ),
    GoRoute(
      path: AppRoutes.scores,
      builder: (context, state) => const ScoresScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'dev-tools',
          builder: (context, state) => const DeveloperToolsScreen(),
        ),
      ],
    ),
  ],
);

final appRouter = buildAppRouter();
