class SourceCell {
  const SourceCell({
    required this.row,
    required this.col,
    required this.digits,
  });

  final int row;
  final int col;
  final List<int> digits;

  factory SourceCell.fromJson(Map<String, dynamic> json) => SourceCell(
    row: json['row'] as int,
    col: json['col'] as int,
    digits: (json['digits'] as List<dynamic>).cast<int>(),
  );
}
