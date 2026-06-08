import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/settings_provider.dart';

class HighlightModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // settingsProvider loads from DB asynchronously. Listen for its first real
    // load so the saved preference overrides the synchronous default.
    ref.listen(settingsProvider, (prev, next) {
      if (prev?.highlightModeDefault != next.highlightModeDefault) {
        state = next.highlightModeDefault;
      }
    });
    return ref.read(settingsProvider).highlightModeDefault;
  }

  void toggle() => state = !state;
}

final highlightModeProvider = NotifierProvider<HighlightModeNotifier, bool>(
  HighlightModeNotifier.new,
);
