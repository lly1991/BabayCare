import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:babycare_flutter/core/database/app_database.dart';
import 'package:babycare_flutter/core/services/backup_service.dart';
import 'package:babycare_flutter/core/security/password_hasher.dart';
import 'package:babycare_flutter/features/auth/data/auth_repository_impl.dart';
import 'package:babycare_flutter/features/daily_moments/data/data_sources/daily_moment_local_data_source.dart';
import 'package:babycare_flutter/features/daily_moments/data/dto/daily_moment_model.dart';
import 'package:babycare_flutter/features/daily_moments/domain/entities/daily_moment.dart';
import 'package:babycare_flutter/features/feeding/data/feeding_repository_impl.dart';
import 'package:babycare_flutter/features/feeding/domain/entities/daily_stat.dart';
import 'package:babycare_flutter/features/feeding/domain/entities/feeding_record.dart';

import 'test_database_utils.dart';

void main() {
  late FeedingRepositoryImpl repository;
  late AuthRepositoryImpl authRepository;
  late DailyMomentLocalDataSource dailyMomentsDataSource;

  setUpAll(() async {
    await initTestDatabase();
    repository = FeedingRepositoryImpl(AppDatabase.instance);
    authRepository = AuthRepositoryImpl(AppDatabase.instance);
    dailyMomentsDataSource = DailyMomentLocalDataSource(AppDatabase.instance);
  });

  setUp(() async {
    await resetTables();
  });

  tearDownAll(() async {
    await closeTestDatabase();
  });

  test('日统计按口径聚合奶粉次数/奶量和母乳次数/时长', () async {
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 10, 8, 0),
        type: FeedType.formula,
        amountMl: 120,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 10, 10, 30),
        type: FeedType.formula,
        amountMl: 90,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 10, 13, 0),
        type: FeedType.breast,
        durationMin: 25,
      ),
    );

    final stat = await repository.getDailyStat(1, '2026-03-10');

    expect(stat.totalCount, 3);
    expect(stat.formulaCount, 2);
    expect(stat.formulaAmount, 210);
    expect(stat.breastCount, 1);
    expect(stat.breastDuration, 25);
  });

  test('周/月统计的日详情与日统计口径一致', () async {
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 10, 9, 0),
        type: FeedType.formula,
        amountMl: 100,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 10, 12, 0),
        type: FeedType.breast,
        durationMin: 20,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 11, 7, 0),
        type: FeedType.formula,
        amountMl: 80,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 3, 11, 8, 30),
        type: FeedType.breast,
        durationMin: 15,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 1,
        userId: 10,
        feedTime: DateTime(2026, 2, 28, 20, 0),
        type: FeedType.formula,
        amountMl: 70,
      ),
    );
    await repository.addRecord(
      _record(
        babyId: 2,
        userId: 10,
        feedTime: DateTime(2026, 3, 10, 9, 0),
        type: FeedType.formula,
        amountMl: 999,
      ),
    );

    final weekStats = await repository.getWeeklyStats(1, '2026-03-10');
    expect(weekStats.length, 2);
    expect(weekStats[0], _matchesDaily('2026-03-10', 2, 1, 100, 1, 20));
    expect(weekStats[1], _matchesDaily('2026-03-11', 2, 1, 80, 1, 15));

    final monthStats = await repository.getMonthlyStats(1, 2026, 3);
    expect(monthStats.length, 2);
    expect(monthStats[0], _matchesDaily('2026-03-10', 2, 1, 100, 1, 20));
    expect(monthStats[1], _matchesDaily('2026-03-11', 2, 1, 80, 1, 15));
  });

  test('日常动态支持落库读取并按创建时间倒序', () async {
    final olderFile = await _createTempMediaFile('older.jpg');
    final newerFile = await _createTempMediaFile('newer.mp4');

    await dailyMomentsDataSource.create(
      DailyMomentModel(
        babyId: 1,
        userId: 10,
        filePath: olderFile.path,
        type: DailyMomentType.image,
        createdAt: DateTime(2026, 3, 10, 8, 0),
      ),
    );
    await dailyMomentsDataSource.create(
      DailyMomentModel(
        babyId: 1,
        userId: 10,
        filePath: newerFile.path,
        type: DailyMomentType.video,
        createdAt: DateTime(2026, 3, 10, 9, 0),
      ),
    );
    await dailyMomentsDataSource.create(
      DailyMomentModel(
        babyId: 2,
        userId: 10,
        filePath: (await _createTempMediaFile('other_baby.jpg')).path,
        type: DailyMomentType.image,
        createdAt: DateTime(2026, 3, 10, 10, 0),
      ),
    );

    final list = await dailyMomentsDataSource.getByBabyId(1);
    expect(list.length, 2);
    expect(list.first.filePath, newerFile.path);
    expect(list.last.filePath, olderFile.path);
  });

  test('删除动态时同时删除数据库记录与本地文件', () async {
    final file = await _createTempMediaFile('to_delete.jpg');
    final created = await dailyMomentsDataSource.create(
      DailyMomentModel(
        babyId: 1,
        userId: 10,
        filePath: file.path,
        type: DailyMomentType.image,
        createdAt: DateTime(2026, 3, 10, 11, 0),
      ),
    );

    expect(await file.exists(), isTrue);
    await dailyMomentsDataSource.delete(created);

    final remaining = await dailyMomentsDataSource.getByBabyId(1);
    expect(remaining, isEmpty);
    expect(await file.exists(), isFalse);
  });

  test('register 会以 sha256 保存密码，且可用明文密码登录', () async {
    await authRepository.register('new_user', 'pass1234');
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['new_user'],
      limit: 1,
    );

    expect(rows, isNotEmpty);
    final stored = rows.first['password_hash'] as String;
    expect(stored, isNot('pass1234'));
    expect(stored, hasLength(64));
    expect(stored, sha256Hex('pass1234'));

    final loggedIn = await authRepository.login('new_user', 'pass1234');
    expect(loggedIn, isNotNull);
  });

  test('login 兼容旧版本 sha256 密码', () async {
    final db = await AppDatabase.instance.database;
    await db.insert('users', {
      'username': 'legacy_hash',
      'password_hash': sha256Hex('legacy_pwd'),
      'created_at': '2026-03-14T08:00:00.000',
    });

    final loggedIn = await authRepository.login('legacy_hash', 'legacy_pwd');
    expect(loggedIn, isNotNull);
    expect(loggedIn?.username, 'legacy_hash');
  });

  test('login 兼容旧明文并自动升级为 sha256', () async {
    final db = await AppDatabase.instance.database;
    final userId = await db.insert('users', {
      'username': 'legacy_plain',
      'password_hash': 'plain_pwd',
      'created_at': '2026-03-14T09:00:00.000',
    });

    final loggedIn = await authRepository.login('legacy_plain', 'plain_pwd');
    expect(loggedIn, isNotNull);

    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    expect(rows, isNotEmpty);
    expect(rows.first['password_hash'], sha256Hex('plain_pwd'));
  });

  test('当仅存在旧库时会自动迁移旧库用户数据', () async {
    final db = await AppDatabase.instance.database;
    await db.delete('users');

    final databasesPath = await getDatabasesPath();
    final legacyPath = p.join(databasesPath, 'babycare_dbSQLite.db');
    await deleteDatabase(legacyPath);

    final legacyDb = await openDatabase(
      legacyPath,
      version: 1,
      onCreate: (legacyDb, version) async {
        await _createAllTables(legacyDb);
      },
    );
    await legacyDb.insert('users', {
      'username': 'legacy_db_user',
      'password_hash': sha256Hex('abc12345'),
      'created_at': '2026-03-14T10:00:00.000',
    });
    await legacyDb.close();

    await AppDatabase.instance.close();

    final reopened = await AppDatabase.instance.database;
    final rows = await reopened.query(
      'users',
      where: 'username = ?',
      whereArgs: ['legacy_db_user'],
      limit: 1,
    );
    expect(rows, isNotEmpty);

    final loggedIn = await authRepository.login('legacy_db_user', 'abc12345');
    expect(loggedIn, isNotNull);
  });

  test('当新库已有用户时，登录旧账号会按需导入旧用户及关联数据', () async {
    await authRepository.register('current_user', '11112222');

    final databasesPath = await getDatabasesPath();
    final legacyPath = p.join(databasesPath, 'babycare_dbSQLite.db');
    await deleteDatabase(legacyPath);

    final legacyDb = await openDatabase(
      legacyPath,
      version: 1,
      onCreate: (legacyDb, version) async {
        await _createAllTables(legacyDb);
      },
    );
    await legacyDb.insert('users', {
      'id': 21,
      'username': 'legacy_need_import',
      'password_hash': sha256Hex('legacy_pass'),
      'created_at': '2026-03-14T11:00:00.000',
    });
    await legacyDb.insert('babies', {
      'id': 31,
      'user_id': 21,
      'name': 'Legacy Baby',
      'birth_date': '2025-01-01T00:00:00.000',
      'gender': 'unknown',
      'avatar': null,
      'created_at': '2026-03-14T11:00:00.000',
    });
    await legacyDb.insert('feeding_records', {
      'id': 41,
      'baby_id': 31,
      'user_id': 21,
      'feed_time': '2026-03-10T08:00:00.000',
      'end_time': null,
      'feed_type': 'formula',
      'amount_ml': 120,
      'duration_min': null,
      'left_duration': null,
      'right_duration': null,
      'brand': 'legacy',
      'notes': null,
      'created_at': '2026-03-10T08:00:00.000',
    });
    await legacyDb.close();

    final imported =
        await authRepository.login('legacy_need_import', 'legacy_pass');
    expect(imported, isNotNull);
    expect(imported!.id, isNotNull);

    final db = await AppDatabase.instance.database;
    final users = await db.query('users', orderBy: 'id ASC');
    expect(users.length, 2);

    final babies = await db.query(
      'babies',
      where: 'user_id = ?',
      whereArgs: [imported.id],
    );
    expect(babies.length, 1);

    final babyId = babies.first['id'] as int;
    final feedings = await db.query(
      'feeding_records',
      where: 'user_id = ? AND baby_id = ?',
      whereArgs: [imported.id, babyId],
    );
    expect(feedings.length, 1);
    expect(feedings.first['amount_ml'], 120);
  });

  test('当前库同名用户密码不匹配时，仍可用旧库密码登录并修复', () async {
    final db = await AppDatabase.instance.database;
    final currentUserId = await db.insert('users', {
      'username': 'same_name_user',
      'password_hash': sha256Hex('new_pass'),
      'created_at': '2026-03-14T11:30:00.000',
    });

    final databasesPath = await getDatabasesPath();
    final legacyPath = p.join(databasesPath, 'babycare_dbSQLite.db');
    await deleteDatabase(legacyPath);

    final legacyDb = await openDatabase(
      legacyPath,
      version: 1,
      onCreate: (legacyDb, version) async {
        await _createAllTables(legacyDb);
      },
    );
    await legacyDb.insert('users', {
      'id': 51,
      'username': 'same_name_user',
      'password_hash': sha256Hex('old_pass'),
      'created_at': '2026-03-14T10:00:00.000',
    });
    await legacyDb.insert('babies', {
      'id': 61,
      'user_id': 51,
      'name': 'Legacy Repair Baby',
      'birth_date': '2025-08-01T00:00:00.000',
      'gender': 'unknown',
      'avatar': null,
      'created_at': '2026-03-14T10:10:00.000',
    });
    await legacyDb.insert('feeding_records', {
      'id': 71,
      'baby_id': 61,
      'user_id': 51,
      'feed_time': '2026-03-12T08:00:00.000',
      'end_time': null,
      'feed_type': 'formula',
      'amount_ml': 130,
      'duration_min': null,
      'left_duration': null,
      'right_duration': null,
      'brand': null,
      'notes': null,
      'created_at': '2026-03-12T08:00:00.000',
    });
    await legacyDb.close();

    final loggedIn = await authRepository.login('same_name_user', 'old_pass');
    expect(loggedIn, isNotNull);
    expect(loggedIn!.id, currentUserId);

    final userRows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [currentUserId],
      limit: 1,
    );
    expect(userRows, isNotEmpty);
    expect(userRows.first['password_hash'], sha256Hex('old_pass'));

    final babies = await db.query(
      'babies',
      where: 'user_id = ?',
      whereArgs: [currentUserId],
    );
    expect(babies.length, 1);

    final babyId = babies.first['id'] as int;
    final feedingRows = await db.query(
      'feeding_records',
      where: 'user_id = ? AND baby_id = ?',
      whereArgs: [currentUserId, babyId],
    );
    expect(feedingRows.length, 1);
    expect(feedingRows.first['amount_ml'], 130);
  });

  test('数据备份导入可恢复账号、喂养记录和提醒数据', () async {
    final service = BackupService(AppDatabase.instance);
    final payload = jsonEncode({
      'version': 2,
      'timestamp': '2026-03-14T12:00:00.000',
      'data': {
        'users': [
          {
            'id': 1,
            'username': 'backup_user',
            'password_hash': sha256Hex('backup_pwd'),
            'created_at': '2026-03-14T10:00:00.000',
          },
        ],
        'babies': [
          {
            'id': 1,
            'user_id': 1,
            'name': 'Backup Baby',
            'birth_date': '2025-01-01T00:00:00.000',
            'gender': 'female',
            'avatar': null,
            'created_at': '2026-03-14T10:10:00.000',
          },
        ],
        'feeding_records': [
          {
            'id': 1,
            'baby_id': 1,
            'user_id': 1,
            'feed_time': '2026-03-14T09:00:00.000',
            'end_time': null,
            'feed_type': 'formula',
            'amount_ml': 120,
            'duration_min': null,
            'left_duration': null,
            'right_duration': null,
            'brand': 'backup',
            'notes': 'from backup',
            'created_at': '2026-03-14T09:00:00.000',
          },
        ],
        'media_records': [],
        'sleep_records': [],
        'diaper_records': [],
        'growth_records': [],
        'reminders': [
          {
            'id': 1,
            'user_id': 1,
            'title': '喂养提醒',
            'body': '测试',
            'hour': 8,
            'minute': 30,
            'created_at': '2026-03-14T10:00:00.000',
          },
        ],
      },
    });

    await service.importFromJsonString(payload);

    final db = await AppDatabase.instance.database;
    final users = await db.query('users');
    final feedings = await db.query('feeding_records');
    final reminders = await db.query('reminders');

    expect(users.length, 1);
    expect(users.first['username'], 'backup_user');
    expect(feedings.length, 1);
    expect(feedings.first['amount_ml'], 120);
    expect(reminders.length, 1);
    expect(reminders.first['title'], '喂养提醒');
  });
}

FeedingRecord _record({
  required int babyId,
  required int userId,
  required DateTime feedTime,
  required FeedType type,
  int? amountMl,
  int? durationMin,
}) {
  return FeedingRecord(
    babyId: babyId,
    userId: userId,
    feedTime: feedTime,
    feedType: type,
    amountMl: amountMl,
    durationMin: durationMin,
    createdAt: feedTime,
  );
}

Matcher _matchesDaily(
  String date,
  int totalCount,
  int formulaCount,
  int formulaAmount,
  int breastCount,
  int breastDuration,
) {
  return isA<DailyStat>()
      .having((e) => e.date, 'date', date)
      .having((e) => e.totalCount, 'totalCount', totalCount)
      .having((e) => e.formulaCount, 'formulaCount', formulaCount)
      .having((e) => e.formulaAmount, 'formulaAmount', formulaAmount)
      .having((e) => e.breastCount, 'breastCount', breastCount)
      .having((e) => e.breastDuration, 'breastDuration', breastDuration);
}

Future<File> _createTempMediaFile(String name) async {
  final dir = await Directory.systemTemp.createTemp('babycare_daily_moment_');
  final file = File('${dir.path}/$name');
  await file.writeAsString('mock-media');
  return file;
}

Future<void> _createAllTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS babies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      birth_date TEXT NOT NULL,
      gender TEXT DEFAULT 'unknown',
      avatar TEXT,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS feeding_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      baby_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      feed_time TEXT NOT NULL,
      end_time TEXT,
      feed_type TEXT NOT NULL,
      amount_ml INTEGER,
      duration_min INTEGER,
      left_duration INTEGER,
      right_duration INTEGER,
      brand TEXT,
      notes TEXT,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS media_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      baby_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      file_path TEXT NOT NULL,
      file_type TEXT NOT NULL,
      thumbnail_path TEXT,
      description TEXT,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS sleep_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      baby_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT,
      is_ongoing INTEGER DEFAULT 0,
      notes TEXT,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS diaper_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      baby_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      record_time TEXT NOT NULL,
      type TEXT NOT NULL,
      color TEXT,
      texture TEXT,
      notes TEXT,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS growth_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      baby_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      weight_kg REAL,
      height_cm REAL,
      head_circ_cm REAL,
      measure_time TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
}
