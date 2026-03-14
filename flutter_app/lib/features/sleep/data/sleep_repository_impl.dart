import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/sleep_record.dart';
import '../domain/repositories/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  const SleepRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<SleepRecord>> getByBaby(int babyId) async {
    final db = await _database.database;
    final rows = await db.query(
      'sleep_records',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'start_time DESC',
    );
    return rows.map(_map).toList();
  }

  @override
  Future<SleepRecord?> getOngoing(int babyId) async {
    final db = await _database.database;
    final rows = await db.query(
      'sleep_records',
      where: 'baby_id = ? AND is_ongoing = 1',
      whereArgs: [babyId],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<SleepRecord> create(SleepRecord record) async {
    final db = await _database.database;
    final id = await db.insert('sleep_records', {
      'baby_id': record.babyId,
      'user_id': record.userId,
      'start_time': record.startTime.toLocalIsoString(),
      'end_time': record.endTime?.toLocalIsoString(),
      'is_ongoing': record.isOngoing ? 1 : 0,
      'notes': record.notes,
      'created_at': record.createdAt.toLocalIsoString(),
    });
    return SleepRecord(
      id: id,
      babyId: record.babyId,
      userId: record.userId,
      startTime: record.startTime,
      endTime: record.endTime,
      isOngoing: record.isOngoing,
      notes: record.notes,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<void> endSleep(int recordId, DateTime endTime) async {
    final db = await _database.database;
    await db.update(
      'sleep_records',
      {'end_time': endTime.toLocalIsoString(), 'is_ongoing': 0},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('sleep_records', where: 'id = ?', whereArgs: [id]);
  }

  SleepRecord _map(Map<String, Object?> row) {
    return SleepRecord(
      id: asInt(row['id']),
      babyId: asInt(row['baby_id']),
      userId: asInt(row['user_id']),
      startTime: DateTime.parse(asString(row['start_time'])),
      endTime: row['end_time'] == null
          ? null
          : DateTime.parse(asString(row['end_time'])),
      isOngoing: asInt(row['is_ongoing']) == 1,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(asString(row['created_at'])),
    );
  }
}
