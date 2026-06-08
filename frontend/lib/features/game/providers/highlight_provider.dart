import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/settings_provider.dart';

class HighlightModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsProvider).highlightModeDefault;

  void toggle() => state = !state;
}

final highlightModeProvider = NotifierProvider<HighlightModeNotifier, bool>(
  HighlightModeNotifier.new,
);
