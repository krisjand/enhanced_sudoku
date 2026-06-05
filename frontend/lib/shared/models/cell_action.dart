enum ActionType { set, eliminate }

class CellAction {
  const CellAction({
    required this.row,
    required this.col,
    required this.digit,
    required this.type,
  });

  final int row;
  final int col;
  final int digit;
  final ActionType type;

  factory CellAction.fromJson(Map<String, dynamic> json) => CellAction(
    row: json['row'] as int,
    col: json['col'] as int,
    digit: json['digit'] as int,
    type: switch (json['type'] as String) {
      'eliminate' => ActionType.eliminate,
      'set' => ActionType.set,
      final t => throw ArgumentError('Unknown action type: $t'),
    },
  );
}
