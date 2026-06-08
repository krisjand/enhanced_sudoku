import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/game/providers/highlight_provider.dart';
import 'package:frontend/shared/providers/persistence_provider.dart';
import 'package:frontend/shared/services/persistence_service.dart';

ProviderContainer makeContainer() {
  final db = AppDatabase(NativeDatabase.memory());
  final c = ProviderContainer(
    overrides: [persistenceProvider.overrideWithValue(db)],
  );
  addTearDown(() async {
    c.dispose();
    await db.close();
  });
  return c;
}

void main() {
  group('HighlightModeNotifier', () {
    test('initial state is true (on by default)', () {
      final c = makeContainer();
      expect(c.read(highlightModeProvider), isTrue);
    });

    test('toggle flips from true to false', () {
      final c = makeContainer();
      c.read(highlightModeProvider.notifier).toggle();
      expect(c.read(highlightModeProvider), isFalse);
    });

    test('toggle twice returns to true', () {
      final c = makeContainer();
      final n = c.read(highlightModeProvider.notifier);
      n.toggle();
      n.toggle();
      expect(c.read(highlightModeProvider), isTrue);
    });
  });
}
