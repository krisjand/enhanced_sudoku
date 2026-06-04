import 'package:go_router/go_router.dart';

import 'features/game/screens/game_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/scores/screens/scores_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/tutorial/screens/tutorial_list_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const game = '/game';
  static const tutorialList = '/tutorial';
  static const scores = '/scores';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) => const GameScreen(),
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
    ),
  ],
);
