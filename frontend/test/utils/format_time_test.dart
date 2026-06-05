import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/utils/format_time.dart';

void main() {
  group('formatTime', () {
    test('zero shows 00:00', () => expect(formatTime(0), '00:00'));
    test('59 seconds', () => expect(formatTime(59), '00:59'));
    test('one minute', () => expect(formatTime(60), '01:00'));
    test('under an hour', () => expect(formatTime(3599), '59:59'));
    test('exactly one hour shows H:MM:SS', () => expect(formatTime(3600), '1:00:00'));
    test('1h 5m 3s', () => expect(formatTime(3903), '1:05:03'));
    test('multi-hour', () => expect(formatTime(7322), '2:02:02'));
  });
}
