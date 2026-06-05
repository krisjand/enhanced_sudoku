import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/services/persistence_service.dart';

AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  group('GameHistoryDao', () {
    test('empty on first use', () async {
      expect(await db.gameHistoryDao.listByDifficulty('hard'), isEmpty);
      expect(await db.gameHistoryDao.bestByDifficulty('hard'), isNull);
    });

    test('insert and list by difficulty', () async {
      await db.gameHistoryDao.insertGame(
        SolvedGamesCompanion.insert(
          puzzleId: 'abc123',
          difficulty: 'hard',
          solveTimeSeconds: 120,
          techniquesUsed: '["nakedSingles"]',
          completedAt: DateTime(2026, 6, 5),
        ),
      );
      await db.gameHistoryDao.insertGame(
        SolvedGamesCompanion.insert(
          puzzleId: 'def456',
          difficulty: 'easy',
          solveTimeSeconds: 60,
          techniquesUsed: '[]',
          completedAt: DateTime(2026, 6, 5),
        ),
      );

      final hardGames = await db.gameHistoryDao.listByDifficulty('hard');
      expect(hardGames.length, 1);
      expect(hardGames.first.puzzleId, 'abc123');
      expect(await db.gameHistoryDao.listByDifficulty('easy'), hasLength(1));
    });

    test('bestByDifficulty returns fastest non-gave-up game', () async {
      await db.gameHistoryDao.insertGame(
        SolvedGamesCompanion.insert(
          puzzleId: 'slow',
          difficulty: 'hard',
          solveTimeSeconds: 300,
          techniquesUsed: '[]',
          completedAt: DateTime(2026, 6, 5),
        ),
      );
      await db.gameHistoryDao.insertGame(
        SolvedGamesCompanion.insert(
          puzzleId: 'gave_up',
          difficulty: 'hard',
          solveTimeSeconds: 10,
          gaveUp: const Value(true),
          techniquesUsed: '[]',
          completedAt: DateTime(2026, 6, 5),
        ),
      );
      await db.gameHistoryDao.insertGame(
        SolvedGamesCompanion.insert(
          puzzleId: 'fast',
          difficulty: 'hard',
          solveTimeSeconds: 90,
          techniquesUsed: '[]',
          completedAt: DateTime(2026, 6, 5),
        ),
      );

      final best = await db.gameHistoryDao.bestByDifficulty('hard');
      expect(best?.puzzleId, 'fast');
    });
  });

  group('InProgressGameDao', () {
    test('empty on first use', () async {
      expect(await db.inProgressGameDao.getCurrent(), isNull);
    });

    test('save without id inserts and getCurrent returns latest', () async {
      await db.inProgressGameDao.save(
        InProgressGamesCompanion.insert(
          puzzleId: 'g1',
          difficulty: 'medium',
          initialGrid: '[]',
          currentGrid: '[]',
          notes: '[]',
          createdAt: DateTime(2026, 6, 5, 10),
          updatedAt: DateTime(2026, 6, 5, 10),
        ),
      );
      await db.inProgressGameDao.save(
        InProgressGamesCompanion.insert(
          puzzleId: 'g2',
          difficulty: 'hard',
          initialGrid: '[]',
          currentGrid: '[]',
          notes: '[]',
          createdAt: DateTime(2026, 6, 5, 11),
          updatedAt: DateTime(2026, 6, 5, 11),
        ),
      );

      final current = await db.inProgressGameDao.getCurrent();
      expect(current?.puzzleId, 'g2');
    });

    test(
      'save with id updates the existing row, not inserts a new one',
      () async {
        await db.inProgressGameDao.save(
          InProgressGamesCompanion.insert(
            puzzleId: 'g1',
            difficulty: 'easy',
            initialGrid: '[]',
            currentGrid: '[[1]]',
            notes: '[]',
            createdAt: DateTime(2026, 6, 5),
            updatedAt: DateTime(2026, 6, 5, 10),
          ),
        );
        final inserted = await db.inProgressGameDao.getCurrent();

        // Save again with same id — should update, not insert.
        await db.inProgressGameDao.save(
          InProgressGamesCompanion(
            id: Value(inserted!.id),
            currentGrid: const Value('[[1],[2]]'),
            updatedAt: Value(DateTime(2026, 6, 5, 11)),
          ),
        );

        final rows = await db.inProgressGameDao.getCurrent();
        final all = await (db.select(db.inProgressGames)).get();
        expect(all.length, 1); // update, not insert
        expect(rows?.currentGrid, '[[1],[2]]');
      },
    );

    test('delete removes the row', () async {
      await db.inProgressGameDao.save(
        InProgressGamesCompanion.insert(
          puzzleId: 'g1',
          difficulty: 'easy',
          initialGrid: '[]',
          currentGrid: '[]',
          notes: '[]',
          createdAt: DateTime(2026, 6, 5),
          updatedAt: DateTime(2026, 6, 5),
        ),
      );
      final game = await db.inProgressGameDao.getCurrent();
      await db.inProgressGameDao.deleteGame(game!.id);
      expect(await db.inProgressGameDao.getCurrent(), isNull);
    });
  });

  group('SettingsDao', () {
    test('get returns null for missing key', () async {
      expect(await db.settingsDao.get('backendUrl'), isNull);
    });

    test('set and get round-trips value', () async {
      await db.settingsDao.set('backendUrl', 'http://192.168.1.10:8080');
      expect(
        await db.settingsDao.get('backendUrl'),
        'http://192.168.1.10:8080',
      );
    });

    test('set overwrites existing value', () async {
      await db.settingsDao.set('backendUrl', 'http://localhost:8080');
      await db.settingsDao.set('backendUrl', 'http://prod.example.com');
      expect(await db.settingsDao.get('backendUrl'), 'http://prod.example.com');
    });
  });
}
