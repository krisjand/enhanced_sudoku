import 'package:flutter_riverpod/flutter_riverpod.dart';

// State encoding:
//   null  = highlight mode off
//   0     = mode active, no digit selected yet
//   1–9   = mode active, this digit highlighted
class HighlightNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void toggle() => state = state == null ? 0 : null;

  // Tapping a cell with [digit] while in highlight mode:
  //   same digit → deactivate entirely (AC#6)
  //   different digit → switch to that digit
  //   mode off → no-op
  void selectDigit(int digit) {
    if (state == null) return;
    state = state == digit ? null : digit;
  }

  bool get isActive => state != null;
}

final highlightProvider = NotifierProvider<HighlightNotifier, int?>(
  HighlightNotifier.new,
);
