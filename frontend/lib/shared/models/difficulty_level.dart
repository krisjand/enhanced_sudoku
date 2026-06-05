enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
  master,
  grandmaster,
  legendary;

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown difficulty: $value'),
    );
  }
}
