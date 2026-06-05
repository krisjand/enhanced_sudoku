import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/game/providers/timer_provider.dart';

ProviderContainer makeTimerContainer() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('TimerNotifier', () {
    test('starts at 0 before start() is called', () {
      final c = makeTimerContainer();
      expect(c.read(timerProvider), 0);
    });

    test('start() sets initial value immediately', () {
      final c = makeTimerContainer();
      c.read(timerProvider.notifier).start(42);
      expect(c.read(timerProvider), 42);
    });

    test('start() with 0 begins at 0', () {
      final c = makeTimerContainer();
      c.read(timerProvider.notifier).start(0);
      expect(c.read(timerProvider), 0);
    });

    test('stop() does not throw when called before start()', () {
      final c = makeTimerContainer();
      expect(() => c.read(timerProvider.notifier).stop(), returnsNormally);
    });

    test('stop() halts the timer — value stays fixed after stop', () async {
      final c = makeTimerContainer();
      c.read(timerProvider.notifier).start(0);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      c.read(timerProvider.notifier).stop();
      final stoppedAt = c.read(timerProvider);
      expect(stoppedAt, greaterThanOrEqualTo(1));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(c.read(timerProvider), stoppedAt);
    });

    test('start() resumes from given initial value (resume flow)', () {
      final c = makeTimerContainer();
      c.read(timerProvider.notifier).start(120);
      expect(c.read(timerProvider), 120);
      c.read(timerProvider.notifier).stop();
    });
  });
}
