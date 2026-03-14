import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _dbName = 'babycare_flutter.db';
  static const _legacyDbCandidates = [
    'babycare_db',
    'babycare_db.db',
    'babycare_dbSQLite',
    'babycare_dbSQLite.db',
  ];
  static const _tables = [
    'users',
    'babies',
    'feeding_records',
    'media_records',
    'sleep_records',
    'diaper_records',
    'growth_records',
  ];

  Database? _database;

  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    await _copyLegacyDatabaseIfNeeded(
      databasesPath: databasesPath,
      targetPath: path,
    );

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createBaseTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createRemindersTable(db);
        }
      },
    );

    await _mergeLegacyDataIfNeeded(
      currentDb: db,
      databasesPath: databasesPath,
      currentPath: path,
    );

    return db;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> _copyLegacyDatabaseIfNeeded({
    required String databasesPath,
    required String targetPath,
  }) async {
    try {
      final targetFile = File(targetPath);
      if (await targetFile.exists()) return;

      final legacyPath = await _findLegacyDbPath(
        databasesPath: databasesPath,
        excludePath: targetPath,
      );
      if (legacyPath == null) return;

      await targetFile.parent.create(recursive: true);
      await File(legacyPath).copy(targetPath);
    } catch (_) {
      // Best-effort migration: continue with a fresh DB if copy fails.
    }
  }

  Future<void> _mergeLegacyDataIfNeeded({
    required Database currentDb,
    required String databasesPath,
    required String currentPath,
  }) async {
    try {
      final currentUsers = await currentDb.query(
        'users',
        columns: ['id'],
        limit: 1,
      );
      if (currentUsers.isNotEmpty) return;

      final legacyPath = await _findLegacyDbPath(
        databasesPath: databasesPath,
        excludePath: currentPath,
      );
      if (legacyPath == null) return;

      final legacyDb = await openDatabase(legacyPath, readOnly: true);
      try {
        final legacyUsers = await legacyDb.query(
          'users',
          columns: ['id'],
          limit: 1,
        );
        if (legacyUsers.isEmpty) return;

        await currentDb.transaction((txn) async {
          for (final table in _tables) {
            final rows = await legacyDb.query(table);
            for (final row in rows) {
              await txn.insert(
                table,
                row,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }

          for (final table in _tables) {
            final maxRows = await txn.rawQuery(
              'SELECT MAX(id) AS max_id FROM $table',
            );
            final maxId = maxRows.first['max_id'] as int?;
            if (maxId == null) continue;
            await txn.delete(
              'sqlite_sequence',
              where: 'name = ?',
              whereArgs: [table],
            );
            await txn.insert('sqlite_sequence', {'name': table, 'seq': maxId});
          }
        });
      } finally {
        await legacyDb.close();
      }
    } catch (_) {
      // Best-effort migration: ignore and keep app startup available.
    }
  }

  Future<String?> _findLegacyDbPath({
    required String databasesPath,
    required String excludePath,
  }) async {
    for (final name in _legacyDbCandidates) {
      final candidatePath = p.join(databasesPath, name);
      if (candidatePath == excludePath) continue;
      if (await File(candidatePath).exists()) {
        return candidatePath;
      }
    }
    return null;
  }

  Future<void> _createBaseTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE babies (
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
      CREATE TABLE feeding_records (
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
      CREATE TABLE media_records (
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
      CREATE TABLE sleep_records (
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
      CREATE TABLE diaper_records (
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
      CREATE TABLE growth_records (
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

    await _createRemindersTable(db);
  }

  Future<void> _createRemindersTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
