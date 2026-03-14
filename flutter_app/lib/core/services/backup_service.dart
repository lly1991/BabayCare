import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class BackupService {
  const BackupService(this._appDatabase);

  final AppDatabase _appDatabase;

  static const tables = [
    'users',
    'babies',
    'feeding_records',
    'media_records',
    'sleep_records',
    'diaper_records',
    'growth_records',
    'reminders',
  ];

  Future<File> exportToJsonFile() async {
    final db = await _appDatabase.database;
    final backupData = <String, List<Map<String, Object?>>>{};

    for (final table in tables) {
      final rows = await db.query(table);
      backupData[table] = rows;
    }

    final payload = {
      'version': 2,
      'timestamp': DateTime.now().toIso8601String(),
      'data': backupData,
    };

    final documentsDir = await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File(p.join(documentsDir.path, 'babycare_backup_$stamp.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));
    return file;
  }

  Future<void> importFromJsonString(String jsonString) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('无效备份文件');
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('备份内容不完整');
    }

    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      for (final table in tables) {
        final tableRows = data[table];
        if (tableRows is! List) continue;

        await txn.delete(table);
        if (tableRows.isEmpty) continue;

        for (final row in tableRows) {
          if (row is! Map) continue;
          final map = <String, Object?>{};
          row.forEach((key, value) {
            if (key is String) {
              map[key] = value;
            }
          });
          if (map.isEmpty) continue;
          await txn.insert(
            table,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await _repairSequence(txn, table);
      }
    });
  }

  Future<void> _repairSequence(Transaction txn, String table) async {
    final maxRows = await txn.rawQuery('SELECT MAX(id) AS max_id FROM $table');
    final maxId = maxRows.first['max_id'] as int?;
    await txn.delete(
      'sqlite_sequence',
      where: 'name = ?',
      whereArgs: [table],
    );
    if (maxId == null) return;
    await txn.insert('sqlite_sequence', {'name': table, 'seq': maxId});
  }
}
