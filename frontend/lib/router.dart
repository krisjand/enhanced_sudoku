import 'package:go_router/go_router.dart';

import 'features/developer/screens/developer_tools_screen.dart';
import 'features/game/screens/game_complete_screen.dart';
import 'features/game/screens/game_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/scores/screens/scores_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/tutorial/screens/hidden_singles_lesson_screen.dart';
import 'features/tutorial/screens/locked_candidates_lesson_screen.dart';
import 'features/tutorial/screens/naked_singles_lesson_screen.dart';
import 'features/tutorial/screens/notes_lesson_screen.dart';
import 'features/tutorial/screens/technique_lesson_screen.dart';
import 'features/tutorial/screens/tutorial_list_screen.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const game = '/game';
  static const gameComplete = '/game/complete';
  static const tutorialList = '/tutorial';
  static const tutorialNotes = '/tutorial/notes';
  static String tutorialLesson(String technique) =>
      '/tutorial/lesson/$technique';
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
      routes: [
        GoRoute(
          path: 'notes',
          builder: (context, state) => const NotesLessonScreen(),
        ),
        GoRoute(
          path: 'lesson/nakedSingles',
          builder: (context, state) => const NakedSinglesLessonScreen(),
        ),
        GoRoute(
          path: 'lesson/hiddenSingles',
          builder: (context, state) => const HiddenSinglesLessonScreen(),
        ),
        GoRoute(
          path: 'lesson/lockedCandidates',
          builder: (context, state) => const LockedCandidatesLessonScreen(),
        ),
        GoRoute(
          path: 'lesson/:technique',
          builder: (context, state) => TechniqueLessonScreen(
            technique: state.pathParameters['technique']!,
          ),
        ),
      ],
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
