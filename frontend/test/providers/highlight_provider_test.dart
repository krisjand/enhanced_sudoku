import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/game/providers/highlight_provider.dart';

ProviderContainer makeContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('HighlightNotifier', () {
    test('initial state is null (mode off)', () {
      final c = makeContainer();
      expect(c.read(highlightProvider), isNull);
      expect(c.read(highlightProvider.notifier).isActive, isFalse);
    });

    test('toggle activates mode (state = 0)', () {
      final c = makeContainer();
      c.read(highlightProvider.notifier).toggle();
      expect(c.read(highlightProvider), 0);
      expect(c.read(highlightProvider.notifier).isActive, isTrue);
    });

    test('toggle twice deactivates mode', () {
      final c = makeContainer();
      final n = c.read(highlightProvider.notifier);
      n.toggle();
      n.toggle();
      expect(c.read(highlightProvider), isNull);
      expect(n.isActive, isFalse);
    });

    test('selectDigit while mode is off does nothing', () {
      final c = makeContainer();
      c.read(highlightProvider.notifier).selectDigit(5);
      expect(c.read(highlightProvider), isNull);
    });

    test('selectDigit sets the highlighted digit', () {
      final c = makeContainer();
      final n = c.read(highlightProvider.notifier);
      n.toggle();
      n.selectDigit(7);
      expect(c.read(highlightProvider), 7);
    });

    test('selectDigit with same digit deactivates mode entirely (AC#6)', () {
      final c = makeContainer();
      final n = c.read(highlightProvider.notifier);
      n.toggle();
      n.selectDigit(3);
      expect(c.read(highlightProvider), 3);
      n.selectDigit(3);
      expect(c.read(highlightProvider), isNull);
      expect(n.isActive, isFalse);
    });

    test('selectDigit switches digit when a different one is already set', () {
      final c = makeContainer();
      final n = c.read(highlightProvider.notifier);
      n.toggle();
      n.selectDigit(4);
      n.selectDigit(9);
      expect(c.read(highlightProvider), 9);
    });

    test('toggle while digit is active deactivates mode', () {
      final c = makeContainer();
      final n = c.read(highlightProvider.notifier);
      n.toggle();
      n.selectDigit(6);
      n.toggle();
      expect(c.read(highlightProvider), isNull);
    });
  });
}
