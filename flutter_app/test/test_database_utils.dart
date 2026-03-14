import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:babycare_flutter/core/database/app_database.dart';

const _dbNames = [
  'babycare_flutter.db',
  'babycare_db',
  'babycare_db.db',
  'babycare_dbSQLite',
  'babycare_dbSQLite.db',
];

Future<void> initTestDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await _deleteTestDbFiles();
  await AppDatabase.instance.close();
}

Future<void> resetTables() async {
  final db = await AppDatabase.instance.database;
  for (final table in const [
    'feeding_records',
    'media_records',
    'sleep_records',
    'diaper_records',
    'growth_records',
    'reminders',
    'babies',
    'users',
  ]) {
    await db.delete(table);
  }
}

Future<void> closeTestDatabase() async {
  await AppDatabase.instance.close();
  await _deleteTestDbFiles();
}

Future<void> _deleteTestDbFiles() async {
  final databasesPath = await getDatabasesPath();
  for (final dbName in _dbNames) {
    await deleteDatabase(p.join(databasesPath, dbName));
  }
}
