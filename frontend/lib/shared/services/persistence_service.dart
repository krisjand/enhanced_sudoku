import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'persistence_service.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

class SolvedGames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId => text()();
  TextColumn get difficulty => text()();
  IntColumn get hintCount => integer().withDefault(const Constant(0))();
  BoolColumn get gaveUp => boolean().withDefault(const Constant(false))();
  IntColumn get solveTimeSeconds => integer()();
  TextColumn get techniquesUsed => text()(); // JSON list
  DateTimeColumn get completedAt => dateTime()();
}

class InProgressGames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId => text()();
  TextColumn get difficulty => text()();
  TextColumn get initialGrid => text()(); // JSON
  TextColumn get currentGrid => text()(); // JSON
  TextColumn get notes => text()(); // JSON
  IntColumn get elapsedSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ── DAOs ──────────────────────────────────────────────────────────────────────

@DriftAccessor(tables: [SolvedGames])
class GameHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$GameHistoryDaoMixin {
  GameHistoryDao(super.db);

  Future<void> insertGame(SolvedGamesCompanion game) =>
      into(solvedGames).insert(game);

  Future<List<SolvedGame>> listByDifficulty(String difficulty) =>
      (select(solvedGames)
            ..where((t) => t.difficulty.equals(difficulty))
            ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .get();

  Future<SolvedGame?> bestByDifficulty(String difficulty) =>
      (select(solvedGames)
            ..where((t) => t.difficulty.equals(difficulty) & t.gaveUp.not())
            ..orderBy([(t) => OrderingTerm.asc(t.solveTimeSeconds)])
            ..limit(1))
          .getSingleOrNull();
}

@DriftAccessor(tables: [InProgressGames])
class InProgressGameDao extends DatabaseAccessor<AppDatabase>
    with _$InProgressGameDaoMixin {
  InProgressGameDao(super.db);

  // Insert when companion has no id (new game); update only the provided
  // columns when companion carries an id (saving progress on an existing game).
  Future<void> save(InProgressGamesCompanion game) async {
    if (game.id.present) {
      await (update(
        inProgressGames,
      )..where((t) => t.id.equals(game.id.value))).write(game);
    } else {
      await into(inProgressGames).insert(game);
    }
  }

  Future<InProgressGame?> getCurrent() =>
      (select(inProgressGames)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  Stream<InProgressGame?> watchCurrent() =>
      (select(inProgressGames)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<int> deleteGame(int id) =>
      (delete(inProgressGames)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [SettingsTable])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> get(String key) async {
    final row = await (select(
      settingsTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) =>
      into(settingsTable).insertOnConflictUpdate(
        SettingsTableCompanion(key: Value(key), value: Value(value)),
      );
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [SolvedGames, InProgressGames, SettingsTable],
  daos: [GameHistoryDao, InProgressGameDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'enhanced_sudoku'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(inProgressGames, inProgressGames.elapsedSeconds);
      }
    },
  );
}
