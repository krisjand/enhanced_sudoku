import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/router.dart';

Widget buildApp() => ProviderScope(child: App(router: buildAppRouter()));

void main() {
  group('HomeScreen', () {
    testWidgets('renders app title and all navigation buttons', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Enhanced Sudoku'), findsOneWidget);
      expect(find.text('New Game'), findsOneWidget);
      expect(find.text('Tutorial'), findsOneWidget);
      expect(find.text('Scores'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('New Game navigates to GameScreen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Game'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('Tutorial navigates to TutorialListScreen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tutorial'));
      await tester.pumpAndSettle();

      expect(find.text('Basics'), findsOneWidget);
    });

    testWidgets('Scores navigates to ScoresScreen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scores'));
      await tester.pumpAndSettle();

      expect(find.text('Scores — coming soon'), findsOneWidget);
    });

    testWidgets('Settings navigates to SettingsScreen', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Colors'), findsOneWidget);
    });
  });
}
