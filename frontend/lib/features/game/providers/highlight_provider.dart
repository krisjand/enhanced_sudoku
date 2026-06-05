import 'package:flutter_riverpod/flutter_riverpod.dart';

class HighlightModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final highlightModeProvider = NotifierProvider<HighlightModeNotifier, bool>(
  HighlightModeNotifier.new,
);
