import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerNotifier extends Notifier<int> {
  StreamSubscription<void>? _sub;

  @override
  int build() {
    ref.onDispose(() => _sub?.cancel());
    return 0;
  }

  void start(int initial) {
    state = initial;
    _sub?.cancel();
    _sub = Stream.periodic(const Duration(seconds: 1)).listen((_) => state++);
  }

  void pause() {
    _sub?.cancel();
    _sub = null;
  }

  void resume() {
    if (_sub != null) return;
    _sub = Stream.periodic(const Duration(seconds: 1)).listen((_) => state++);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}

final timerProvider = NotifierProvider<TimerNotifier, int>(TimerNotifier.new);
