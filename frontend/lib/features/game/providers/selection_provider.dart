import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SelectedCell = ({int row, int col});

class SelectionNotifier extends Notifier<SelectedCell?> {
  @override
  SelectedCell? build() => null;

  void select(int row, int col) {
    state = state?.row == row && state?.col == col
        ? null
        : (row: row, col: col);
  }

  void clear() => state = null;
}

final selectionProvider = NotifierProvider<SelectionNotifier, SelectedCell?>(
  SelectionNotifier.new,
);
