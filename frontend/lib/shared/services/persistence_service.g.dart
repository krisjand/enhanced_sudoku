// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persistence_service.dart';

// ignore_for_file: type=lint
mixin _$GameHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $SolvedGamesTable get solvedGames => attachedDatabase.solvedGames;
  GameHistoryDaoManager get managers => GameHistoryDaoManager(this);
}

class GameHistoryDaoManager {
  final _$GameHistoryDaoMixin _db;
  GameHistoryDaoManager(this._db);
  $$SolvedGamesTableTableManager get solvedGames =>
      $$SolvedGamesTableTableManager(_db.attachedDatabase, _db.solvedGames);
}

mixin _$InProgressGameDaoMixin on DatabaseAccessor<AppDatabase> {
  $InProgressGamesTable get inProgressGames => attachedDatabase.inProgressGames;
  InProgressGameDaoManager get managers => InProgressGameDaoManager(this);
}

class InProgressGameDaoManager {
  final _$InProgressGameDaoMixin _db;
  InProgressGameDaoManager(this._db);
  $$InProgressGamesTableTableManager get inProgressGames =>
      $$InProgressGamesTableTableManager(
        _db.attachedDatabase,
        _db.inProgressGames,
      );
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTableTable get settingsTable => attachedDatabase.settingsTable;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db.attachedDatabase, _db.settingsTable);
}

class $SolvedGamesTable extends SolvedGames
    with TableInfo<$SolvedGamesTable, SolvedGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolvedGamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintCountMeta = const VerificationMeta(
    'hintCount',
  );
  @override
  late final GeneratedColumn<int> hintCount = GeneratedColumn<int>(
    'hint_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _gaveUpMeta = const VerificationMeta('gaveUp');
  @override
  late final GeneratedColumn<bool> gaveUp = GeneratedColumn<bool>(
    'gave_up',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gave_up" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _solveTimeSecondsMeta = const VerificationMeta(
    'solveTimeSeconds',
  );
  @override
  late final GeneratedColumn<int> solveTimeSeconds = GeneratedColumn<int>(
    'solve_time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _techniquesUsedMeta = const VerificationMeta(
    'techniquesUsed',
  );
  @override
  late final GeneratedColumn<String> techniquesUsed = GeneratedColumn<String>(
    'techniques_used',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    puzzleId,
    difficulty,
    hintCount,
    gaveUp,
    solveTimeSeconds,
    techniquesUsed,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solved_games';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolvedGame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('hint_count')) {
      context.handle(
        _hintCountMeta,
        hintCount.isAcceptableOrUnknown(data['hint_count']!, _hintCountMeta),
      );
    }
    if (data.containsKey('gave_up')) {
      context.handle(
        _gaveUpMeta,
        gaveUp.isAcceptableOrUnknown(data['gave_up']!, _gaveUpMeta),
      );
    }
    if (data.containsKey('solve_time_seconds')) {
      context.handle(
        _solveTimeSecondsMeta,
        solveTimeSeconds.isAcceptableOrUnknown(
          data['solve_time_seconds']!,
          _solveTimeSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_solveTimeSecondsMeta);
    }
    if (data.containsKey('techniques_used')) {
      context.handle(
        _techniquesUsedMeta,
        techniquesUsed.isAcceptableOrUnknown(
          data['techniques_used']!,
          _techniquesUsedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_techniquesUsedMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolvedGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolvedGame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      hintCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_count'],
      )!,
      gaveUp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gave_up'],
      )!,
      solveTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}solve_time_seconds'],
      )!,
      techniquesUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}techniques_used'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $SolvedGamesTable createAlias(String alias) {
    return $SolvedGamesTable(attachedDatabase, alias);
  }
}

class SolvedGame extends DataClass implements Insertable<SolvedGame> {
  final int id;
  final String puzzleId;
  final String difficulty;
  final int hintCount;
  final bool gaveUp;
  final int solveTimeSeconds;
  final String techniquesUsed;
  final DateTime completedAt;
  const SolvedGame({
    required this.id,
    required this.puzzleId,
    required this.difficulty,
    required this.hintCount,
    required this.gaveUp,
    required this.solveTimeSeconds,
    required this.techniquesUsed,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['difficulty'] = Variable<String>(difficulty);
    map['hint_count'] = Variable<int>(hintCount);
    map['gave_up'] = Variable<bool>(gaveUp);
    map['solve_time_seconds'] = Variable<int>(solveTimeSeconds);
    map['techniques_used'] = Variable<String>(techniquesUsed);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  SolvedGamesCompanion toCompanion(bool nullToAbsent) {
    return SolvedGamesCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      difficulty: Value(difficulty),
      hintCount: Value(hintCount),
      gaveUp: Value(gaveUp),
      solveTimeSeconds: Value(solveTimeSeconds),
      techniquesUsed: Value(techniquesUsed),
      completedAt: Value(completedAt),
    );
  }

  factory SolvedGame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolvedGame(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      hintCount: serializer.fromJson<int>(json['hintCount']),
      gaveUp: serializer.fromJson<bool>(json['gaveUp']),
      solveTimeSeconds: serializer.fromJson<int>(json['solveTimeSeconds']),
      techniquesUsed: serializer.fromJson<String>(json['techniquesUsed']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'difficulty': serializer.toJson<String>(difficulty),
      'hintCount': serializer.toJson<int>(hintCount),
      'gaveUp': serializer.toJson<bool>(gaveUp),
      'solveTimeSeconds': serializer.toJson<int>(solveTimeSeconds),
      'techniquesUsed': serializer.toJson<String>(techniquesUsed),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  SolvedGame copyWith({
    int? id,
    String? puzzleId,
    String? difficulty,
    int? hintCount,
    bool? gaveUp,
    int? solveTimeSeconds,
    String? techniquesUsed,
    DateTime? completedAt,
  }) => SolvedGame(
    id: id ?? this.id,
    puzzleId: puzzleId ?? this.puzzleId,
    difficulty: difficulty ?? this.difficulty,
    hintCount: hintCount ?? this.hintCount,
    gaveUp: gaveUp ?? this.gaveUp,
    solveTimeSeconds: solveTimeSeconds ?? this.solveTimeSeconds,
    techniquesUsed: techniquesUsed ?? this.techniquesUsed,
    completedAt: completedAt ?? this.completedAt,
  );
  SolvedGame copyWithCompanion(SolvedGamesCompanion data) {
    return SolvedGame(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      hintCount: data.hintCount.present ? data.hintCount.value : this.hintCount,
      gaveUp: data.gaveUp.present ? data.gaveUp.value : this.gaveUp,
      solveTimeSeconds: data.solveTimeSeconds.present
          ? data.solveTimeSeconds.value
          : this.solveTimeSeconds,
      techniquesUsed: data.techniquesUsed.present
          ? data.techniquesUsed.value
          : this.techniquesUsed,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolvedGame(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('hintCount: $hintCount, ')
          ..write('gaveUp: $gaveUp, ')
          ..write('solveTimeSeconds: $solveTimeSeconds, ')
          ..write('techniquesUsed: $techniquesUsed, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    puzzleId,
    difficulty,
    hintCount,
    gaveUp,
    solveTimeSeconds,
    techniquesUsed,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolvedGame &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.difficulty == this.difficulty &&
          other.hintCount == this.hintCount &&
          other.gaveUp == this.gaveUp &&
          other.solveTimeSeconds == this.solveTimeSeconds &&
          other.techniquesUsed == this.techniquesUsed &&
          other.completedAt == this.completedAt);
}

class SolvedGamesCompanion extends UpdateCompanion<SolvedGame> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> difficulty;
  final Value<int> hintCount;
  final Value<bool> gaveUp;
  final Value<int> solveTimeSeconds;
  final Value<String> techniquesUsed;
  final Value<DateTime> completedAt;
  const SolvedGamesCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.hintCount = const Value.absent(),
    this.gaveUp = const Value.absent(),
    this.solveTimeSeconds = const Value.absent(),
    this.techniquesUsed = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  SolvedGamesCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String difficulty,
    this.hintCount = const Value.absent(),
    this.gaveUp = const Value.absent(),
    required int solveTimeSeconds,
    required String techniquesUsed,
    required DateTime completedAt,
  }) : puzzleId = Value(puzzleId),
       difficulty = Value(difficulty),
       solveTimeSeconds = Value(solveTimeSeconds),
       techniquesUsed = Value(techniquesUsed),
       completedAt = Value(completedAt);
  static Insertable<SolvedGame> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? difficulty,
    Expression<int>? hintCount,
    Expression<bool>? gaveUp,
    Expression<int>? solveTimeSeconds,
    Expression<String>? techniquesUsed,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (difficulty != null) 'difficulty': difficulty,
      if (hintCount != null) 'hint_count': hintCount,
      if (gaveUp != null) 'gave_up': gaveUp,
      if (solveTimeSeconds != null) 'solve_time_seconds': solveTimeSeconds,
      if (techniquesUsed != null) 'techniques_used': techniquesUsed,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  SolvedGamesCompanion copyWith({
    Value<int>? id,
    Value<String>? puzzleId,
    Value<String>? difficulty,
    Value<int>? hintCount,
    Value<bool>? gaveUp,
    Value<int>? solveTimeSeconds,
    Value<String>? techniquesUsed,
    Value<DateTime>? completedAt,
  }) {
    return SolvedGamesCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      difficulty: difficulty ?? this.difficulty,
      hintCount: hintCount ?? this.hintCount,
      gaveUp: gaveUp ?? this.gaveUp,
      solveTimeSeconds: solveTimeSeconds ?? this.solveTimeSeconds,
      techniquesUsed: techniquesUsed ?? this.techniquesUsed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (hintCount.present) {
      map['hint_count'] = Variable<int>(hintCount.value);
    }
    if (gaveUp.present) {
      map['gave_up'] = Variable<bool>(gaveUp.value);
    }
    if (solveTimeSeconds.present) {
      map['solve_time_seconds'] = Variable<int>(solveTimeSeconds.value);
    }
    if (techniquesUsed.present) {
      map['techniques_used'] = Variable<String>(techniquesUsed.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolvedGamesCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('hintCount: $hintCount, ')
          ..write('gaveUp: $gaveUp, ')
          ..write('solveTimeSeconds: $solveTimeSeconds, ')
          ..write('techniquesUsed: $techniquesUsed, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $InProgressGamesTable extends InProgressGames
    with TableInfo<$InProgressGamesTable, InProgressGame> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InProgressGamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialGridMeta = const VerificationMeta(
    'initialGrid',
  );
  @override
  late final GeneratedColumn<String> initialGrid = GeneratedColumn<String>(
    'initial_grid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentGridMeta = const VerificationMeta(
    'currentGrid',
  );
  @override
  late final GeneratedColumn<String> currentGrid = GeneratedColumn<String>(
    'current_grid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedSecondsMeta = const VerificationMeta(
    'elapsedSeconds',
  );
  @override
  late final GeneratedColumn<int> elapsedSeconds = GeneratedColumn<int>(
    'elapsed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    puzzleId,
    difficulty,
    initialGrid,
    currentGrid,
    notes,
    elapsedSeconds,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'in_progress_games';
  @override
  VerificationContext validateIntegrity(
    Insertable<InProgressGame> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('initial_grid')) {
      context.handle(
        _initialGridMeta,
        initialGrid.isAcceptableOrUnknown(
          data['initial_grid']!,
          _initialGridMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialGridMeta);
    }
    if (data.containsKey('current_grid')) {
      context.handle(
        _currentGridMeta,
        currentGrid.isAcceptableOrUnknown(
          data['current_grid']!,
          _currentGridMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentGridMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('elapsed_seconds')) {
      context.handle(
        _elapsedSecondsMeta,
        elapsedSeconds.isAcceptableOrUnknown(
          data['elapsed_seconds']!,
          _elapsedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InProgressGame map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InProgressGame(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      initialGrid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_grid'],
      )!,
      currentGrid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_grid'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      elapsedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InProgressGamesTable createAlias(String alias) {
    return $InProgressGamesTable(attachedDatabase, alias);
  }
}

class InProgressGame extends DataClass implements Insertable<InProgressGame> {
  final int id;
  final String puzzleId;
  final String difficulty;
  final String initialGrid;
  final String currentGrid;
  final String notes;
  final int elapsedSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InProgressGame({
    required this.id,
    required this.puzzleId,
    required this.difficulty,
    required this.initialGrid,
    required this.currentGrid,
    required this.notes,
    required this.elapsedSeconds,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['difficulty'] = Variable<String>(difficulty);
    map['initial_grid'] = Variable<String>(initialGrid);
    map['current_grid'] = Variable<String>(currentGrid);
    map['notes'] = Variable<String>(notes);
    map['elapsed_seconds'] = Variable<int>(elapsedSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InProgressGamesCompanion toCompanion(bool nullToAbsent) {
    return InProgressGamesCompanion(
      id: Value(id),
      puzzleId: Value(puzzleId),
      difficulty: Value(difficulty),
      initialGrid: Value(initialGrid),
      currentGrid: Value(currentGrid),
      notes: Value(notes),
      elapsedSeconds: Value(elapsedSeconds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InProgressGame.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InProgressGame(
      id: serializer.fromJson<int>(json['id']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      initialGrid: serializer.fromJson<String>(json['initialGrid']),
      currentGrid: serializer.fromJson<String>(json['currentGrid']),
      notes: serializer.fromJson<String>(json['notes']),
      elapsedSeconds: serializer.fromJson<int>(json['elapsedSeconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'difficulty': serializer.toJson<String>(difficulty),
      'initialGrid': serializer.toJson<String>(initialGrid),
      'currentGrid': serializer.toJson<String>(currentGrid),
      'notes': serializer.toJson<String>(notes),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InProgressGame copyWith({
    int? id,
    String? puzzleId,
    String? difficulty,
    String? initialGrid,
    String? currentGrid,
    String? notes,
    int? elapsedSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InProgressGame(
    id: id ?? this.id,
    puzzleId: puzzleId ?? this.puzzleId,
    difficulty: difficulty ?? this.difficulty,
    initialGrid: initialGrid ?? this.initialGrid,
    currentGrid: currentGrid ?? this.currentGrid,
    notes: notes ?? this.notes,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InProgressGame copyWithCompanion(InProgressGamesCompanion data) {
    return InProgressGame(
      id: data.id.present ? data.id.value : this.id,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      initialGrid: data.initialGrid.present
          ? data.initialGrid.value
          : this.initialGrid,
      currentGrid: data.currentGrid.present
          ? data.currentGrid.value
          : this.currentGrid,
      notes: data.notes.present ? data.notes.value : this.notes,
      elapsedSeconds: data.elapsedSeconds.present
          ? data.elapsedSeconds.value
          : this.elapsedSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InProgressGame(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('initialGrid: $initialGrid, ')
          ..write('currentGrid: $currentGrid, ')
          ..write('notes: $notes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    puzzleId,
    difficulty,
    initialGrid,
    currentGrid,
    notes,
    elapsedSeconds,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InProgressGame &&
          other.id == this.id &&
          other.puzzleId == this.puzzleId &&
          other.difficulty == this.difficulty &&
          other.initialGrid == this.initialGrid &&
          other.currentGrid == this.currentGrid &&
          other.notes == this.notes &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InProgressGamesCompanion extends UpdateCompanion<InProgressGame> {
  final Value<int> id;
  final Value<String> puzzleId;
  final Value<String> difficulty;
  final Value<String> initialGrid;
  final Value<String> currentGrid;
  final Value<String> notes;
  final Value<int> elapsedSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const InProgressGamesCompanion({
    this.id = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.initialGrid = const Value.absent(),
    this.currentGrid = const Value.absent(),
    this.notes = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InProgressGamesCompanion.insert({
    this.id = const Value.absent(),
    required String puzzleId,
    required String difficulty,
    required String initialGrid,
    required String currentGrid,
    required String notes,
    this.elapsedSeconds = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : puzzleId = Value(puzzleId),
       difficulty = Value(difficulty),
       initialGrid = Value(initialGrid),
       currentGrid = Value(currentGrid),
       notes = Value(notes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InProgressGame> custom({
    Expression<int>? id,
    Expression<String>? puzzleId,
    Expression<String>? difficulty,
    Expression<String>? initialGrid,
    Expression<String>? currentGrid,
    Expression<String>? notes,
    Expression<int>? elapsedSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (difficulty != null) 'difficulty': difficulty,
      if (initialGrid != null) 'initial_grid': initialGrid,
      if (currentGrid != null) 'current_grid': currentGrid,
      if (notes != null) 'notes': notes,
      if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InProgressGamesCompanion copyWith({
    Value<int>? id,
    Value<String>? puzzleId,
    Value<String>? difficulty,
    Value<String>? initialGrid,
    Value<String>? currentGrid,
    Value<String>? notes,
    Value<int>? elapsedSeconds,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return InProgressGamesCompanion(
      id: id ?? this.id,
      puzzleId: puzzleId ?? this.puzzleId,
      difficulty: difficulty ?? this.difficulty,
      initialGrid: initialGrid ?? this.initialGrid,
      currentGrid: currentGrid ?? this.currentGrid,
      notes: notes ?? this.notes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (initialGrid.present) {
      map['initial_grid'] = Variable<String>(initialGrid.value);
    }
    if (currentGrid.present) {
      map['current_grid'] = Variable<String>(currentGrid.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (elapsedSeconds.present) {
      map['elapsed_seconds'] = Variable<int>(elapsedSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InProgressGamesCompanion(')
          ..write('id: $id, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('difficulty: $difficulty, ')
          ..write('initialGrid: $initialGrid, ')
          ..write('currentGrid: $currentGrid, ')
          ..write('notes: $notes, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  final String key;
  final String value;
  const SettingsTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsTableData copyWith({String? key, String? value}) =>
      SettingsTableData(key: key ?? this.key, value: value ?? this.value);
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SolvedGamesTable solvedGames = $SolvedGamesTable(this);
  late final $InProgressGamesTable inProgressGames = $InProgressGamesTable(
    this,
  );
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final GameHistoryDao gameHistoryDao = GameHistoryDao(
    this as AppDatabase,
  );
  late final InProgressGameDao inProgressGameDao = InProgressGameDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    solvedGames,
    inProgressGames,
    settingsTable,
  ];
}

typedef $$SolvedGamesTableCreateCompanionBuilder =
    SolvedGamesCompanion Function({
      Value<int> id,
      required String puzzleId,
      required String difficulty,
      Value<int> hintCount,
      Value<bool> gaveUp,
      required int solveTimeSeconds,
      required String techniquesUsed,
      required DateTime completedAt,
    });
typedef $$SolvedGamesTableUpdateCompanionBuilder =
    SolvedGamesCompanion Function({
      Value<int> id,
      Value<String> puzzleId,
      Value<String> difficulty,
      Value<int> hintCount,
      Value<bool> gaveUp,
      Value<int> solveTimeSeconds,
      Value<String> techniquesUsed,
      Value<DateTime> completedAt,
    });

class $$SolvedGamesTableFilterComposer
    extends Composer<_$AppDatabase, $SolvedGamesTable> {
  $$SolvedGamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintCount => $composableBuilder(
    column: $table.hintCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gaveUp => $composableBuilder(
    column: $table.gaveUp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get solveTimeSeconds => $composableBuilder(
    column: $table.solveTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get techniquesUsed => $composableBuilder(
    column: $table.techniquesUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SolvedGamesTableOrderingComposer
    extends Composer<_$AppDatabase, $SolvedGamesTable> {
  $$SolvedGamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintCount => $composableBuilder(
    column: $table.hintCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gaveUp => $composableBuilder(
    column: $table.gaveUp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get solveTimeSeconds => $composableBuilder(
    column: $table.solveTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get techniquesUsed => $composableBuilder(
    column: $table.techniquesUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolvedGamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SolvedGamesTable> {
  $$SolvedGamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintCount =>
      $composableBuilder(column: $table.hintCount, builder: (column) => column);

  GeneratedColumn<bool> get gaveUp =>
      $composableBuilder(column: $table.gaveUp, builder: (column) => column);

  GeneratedColumn<int> get solveTimeSeconds => $composableBuilder(
    column: $table.solveTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get techniquesUsed => $composableBuilder(
    column: $table.techniquesUsed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$SolvedGamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SolvedGamesTable,
          SolvedGame,
          $$SolvedGamesTableFilterComposer,
          $$SolvedGamesTableOrderingComposer,
          $$SolvedGamesTableAnnotationComposer,
          $$SolvedGamesTableCreateCompanionBuilder,
          $$SolvedGamesTableUpdateCompanionBuilder,
          (
            SolvedGame,
            BaseReferences<_$AppDatabase, $SolvedGamesTable, SolvedGame>,
          ),
          SolvedGame,
          PrefetchHooks Function()
        > {
  $$SolvedGamesTableTableManager(_$AppDatabase db, $SolvedGamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SolvedGamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SolvedGamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SolvedGamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<int> hintCount = const Value.absent(),
                Value<bool> gaveUp = const Value.absent(),
                Value<int> solveTimeSeconds = const Value.absent(),
                Value<String> techniquesUsed = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => SolvedGamesCompanion(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                hintCount: hintCount,
                gaveUp: gaveUp,
                solveTimeSeconds: solveTimeSeconds,
                techniquesUsed: techniquesUsed,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String puzzleId,
                required String difficulty,
                Value<int> hintCount = const Value.absent(),
                Value<bool> gaveUp = const Value.absent(),
                required int solveTimeSeconds,
                required String techniquesUsed,
                required DateTime completedAt,
              }) => SolvedGamesCompanion.insert(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                hintCount: hintCount,
                gaveUp: gaveUp,
                solveTimeSeconds: solveTimeSeconds,
                techniquesUsed: techniquesUsed,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SolvedGamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SolvedGamesTable,
      SolvedGame,
      $$SolvedGamesTableFilterComposer,
      $$SolvedGamesTableOrderingComposer,
      $$SolvedGamesTableAnnotationComposer,
      $$SolvedGamesTableCreateCompanionBuilder,
      $$SolvedGamesTableUpdateCompanionBuilder,
      (
        SolvedGame,
        BaseReferences<_$AppDatabase, $SolvedGamesTable, SolvedGame>,
      ),
      SolvedGame,
      PrefetchHooks Function()
    >;
typedef $$InProgressGamesTableCreateCompanionBuilder =
    InProgressGamesCompanion Function({
      Value<int> id,
      required String puzzleId,
      required String difficulty,
      required String initialGrid,
      required String currentGrid,
      required String notes,
      Value<int> elapsedSeconds,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$InProgressGamesTableUpdateCompanionBuilder =
    InProgressGamesCompanion Function({
      Value<int> id,
      Value<String> puzzleId,
      Value<String> difficulty,
      Value<String> initialGrid,
      Value<String> currentGrid,
      Value<String> notes,
      Value<int> elapsedSeconds,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$InProgressGamesTableFilterComposer
    extends Composer<_$AppDatabase, $InProgressGamesTable> {
  $$InProgressGamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialGrid => $composableBuilder(
    column: $table.initialGrid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentGrid => $composableBuilder(
    column: $table.currentGrid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InProgressGamesTableOrderingComposer
    extends Composer<_$AppDatabase, $InProgressGamesTable> {
  $$InProgressGamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialGrid => $composableBuilder(
    column: $table.initialGrid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentGrid => $composableBuilder(
    column: $table.currentGrid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InProgressGamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InProgressGamesTable> {
  $$InProgressGamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initialGrid => $composableBuilder(
    column: $table.initialGrid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentGrid => $composableBuilder(
    column: $table.currentGrid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get elapsedSeconds => $composableBuilder(
    column: $table.elapsedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InProgressGamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InProgressGamesTable,
          InProgressGame,
          $$InProgressGamesTableFilterComposer,
          $$InProgressGamesTableOrderingComposer,
          $$InProgressGamesTableAnnotationComposer,
          $$InProgressGamesTableCreateCompanionBuilder,
          $$InProgressGamesTableUpdateCompanionBuilder,
          (
            InProgressGame,
            BaseReferences<
              _$AppDatabase,
              $InProgressGamesTable,
              InProgressGame
            >,
          ),
          InProgressGame,
          PrefetchHooks Function()
        > {
  $$InProgressGamesTableTableManager(
    _$AppDatabase db,
    $InProgressGamesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InProgressGamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InProgressGamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InProgressGamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> initialGrid = const Value.absent(),
                Value<String> currentGrid = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> elapsedSeconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InProgressGamesCompanion(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                initialGrid: initialGrid,
                currentGrid: currentGrid,
                notes: notes,
                elapsedSeconds: elapsedSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String puzzleId,
                required String difficulty,
                required String initialGrid,
                required String currentGrid,
                required String notes,
                Value<int> elapsedSeconds = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => InProgressGamesCompanion.insert(
                id: id,
                puzzleId: puzzleId,
                difficulty: difficulty,
                initialGrid: initialGrid,
                currentGrid: currentGrid,
                notes: notes,
                elapsedSeconds: elapsedSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InProgressGamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InProgressGamesTable,
      InProgressGame,
      $$InProgressGamesTableFilterComposer,
      $$InProgressGamesTableOrderingComposer,
      $$InProgressGamesTableAnnotationComposer,
      $$InProgressGamesTableCreateCompanionBuilder,
      $$InProgressGamesTableUpdateCompanionBuilder,
      (
        InProgressGame,
        BaseReferences<_$AppDatabase, $InProgressGamesTable, InProgressGame>,
      ),
      InProgressGame,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsTableData,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $SettingsTableTable,
              SettingsTableData
            >,
          ),
          SettingsTableData,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SettingsTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsTableData,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsTableData,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>,
      ),
      SettingsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SolvedGamesTableTableManager get solvedGames =>
      $$SolvedGamesTableTableManager(_db, _db.solvedGames);
  $$InProgressGamesTableTableManager get inProgressGames =>
      $$InProgressGamesTableTableManager(_db, _db.inProgressGames);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
