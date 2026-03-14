import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/security/password_hasher.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._database);

  static const _currentDbName = 'babycare_flutter.db';
  static const _legacyDbCandidates = [
    'babycare_db',
    'babycare_db.db',
    'babycare_dbSQLite',
    'babycare_dbSQLite.db',
  ];

  final AppDatabase _database;

  @override
  Future<AppUser?> login(String username, String password) async {
    final db = await _database.database;
    final normalized = username.trim();
    final passwordHash = sha256Hex(password);

    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (rows.isEmpty) {
      return _importLegacyUserIfMatched(
        currentDb: db,
        username: normalized,
        password: password,
        passwordHash: passwordHash,
      );
    }

    final row = rows.first;
    final stored = asString(row['password_hash']);
    final matched = _passwordMatches(
      stored: stored,
      password: password,
      passwordHash: passwordHash,
    );
    if (!matched) return null;

    final user = _map(row);

    // Auto-upgrade plaintext passwords to sha256 after first successful login.
    if (!looksLikeSha256Hex(stored)) {
      await db.update(
        'users',
        {'password_hash': passwordHash},
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return AppUser(
        id: user.id,
        username: user.username,
        passwordHash: passwordHash,
        createdAt: user.createdAt,
      );
    }

    return user;
  }

  @override
  Future<AppUser> register(String username, String password) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw AppException('用户名不能为空');
    }
    if (password.length < 4) {
      throw AppException('密码至少 4 位');
    }

    final db = await _database.database;
    final passwordHash = sha256Hex(password);
    final exists = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: [normalized],
      limit: 1,
    );
    if (exists.isNotEmpty) {
      throw AppException('用户名已存在');
    }

    final createdAt = DateTime.now().toLocalIsoString();
    final id = await db.insert('users', {
      'username': normalized,
      'password_hash': passwordHash,
      'created_at': createdAt,
    });

    return AppUser(
      id: id,
      username: normalized,
      passwordHash: passwordHash,
      createdAt: DateTime.parse(createdAt),
    );
  }

  @override
  Future<AppUser?> getById(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  AppUser _map(Map<String, Object?> row) {
    return AppUser(
      id: asInt(row['id']),
      username: asString(row['username']),
      passwordHash: asString(row['password_hash']),
      createdAt:
          DateTime.tryParse(asString(row['created_at'])) ?? DateTime.now(),
    );
  }

  bool _passwordMatches({
    required String stored,
    required String password,
    required String passwordHash,
  }) {
    return stored == passwordHash ||
        stored.toLowerCase() == passwordHash ||
        stored == password;
  }

  String _normalizePasswordHash({
    required String stored,
    required String passwordHash,
  }) {
    if (looksLikeSha256Hex(stored)) {
      return stored.toLowerCase();
    }
    return passwordHash;
  }

  Future<AppUser?> _importLegacyUserIfMatched({
    required Database currentDb,
    required String username,
    required String password,
    required String passwordHash,
  }) async {
    final databasesPath = await getDatabasesPath();
    final currentPath = p.join(databasesPath, _currentDbName);

    for (final name in _legacyDbCandidates) {
      final candidatePath = p.join(databasesPath, name);
      if (candidatePath == currentPath) continue;
      if (!await File(candidatePath).exists()) continue;

      final legacyDb = await openDatabase(candidatePath, readOnly: true);
      try {
        final legacyRows = await legacyDb.query(
          'users',
          where: 'username = ?',
          whereArgs: [username],
          limit: 1,
        );
        if (legacyRows.isEmpty) continue;

        final legacyUser = legacyRows.first;
        final stored = asString(legacyUser['password_hash']);
        final matched = _passwordMatches(
          stored: stored,
          password: password,
          passwordHash: passwordHash,
        );
        if (!matched) return null;

        final legacyUserId = asInt(legacyUser['id']);
        final createdAt = asString(legacyUser['created_at']);
        final normalizedHash = _normalizePasswordHash(
          stored: stored,
          passwordHash: passwordHash,
        );

        final importedUser = await currentDb.transaction((txn) async {
          final existing = await txn.query(
            'users',
            where: 'username = ?',
            whereArgs: [username],
            limit: 1,
          );
          if (existing.isNotEmpty) {
            return _map(existing.first);
          }

          final newUserId = await txn.insert('users', {
            'username': username,
            'password_hash': normalizedHash,
            'created_at': createdAt,
          });

          final legacyBabies = await legacyDb.query(
            'babies',
            where: 'user_id = ?',
            whereArgs: [legacyUserId],
            orderBy: 'id ASC',
          );
          final babyIdMap = <int, int>{};
          for (final baby in legacyBabies) {
            final oldBabyId = asInt(baby['id']);
            final payload = Map<String, Object?>.from(baby)
              ..remove('id')
              ..['user_id'] = newUserId;
            final newBabyId = await txn.insert('babies', payload);
            babyIdMap[oldBabyId] = newBabyId;
          }

          for (final table in const [
            'feeding_records',
            'media_records',
            'sleep_records',
            'diaper_records',
            'growth_records',
          ]) {
            final rows = await legacyDb.query(
              table,
              where: 'user_id = ?',
              whereArgs: [legacyUserId],
              orderBy: 'id ASC',
            );
            for (final row in rows) {
              final payload = Map<String, Object?>.from(row)..remove('id');
              final oldBabyId = payload['baby_id'] as int?;
              if (oldBabyId != null) {
                final mappedBabyId = babyIdMap[oldBabyId];
                if (mappedBabyId == null) continue;
                payload['baby_id'] = mappedBabyId;
              }
              payload['user_id'] = newUserId;
              await txn.insert(table, payload);
            }
          }

          return AppUser(
            id: newUserId,
            username: username,
            passwordHash: normalizedHash,
            createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
          );
        });

        return importedUser;
      } catch (_) {
        continue;
      } finally {
        await legacyDb.close();
      }
    }

    return null;
  }
}
