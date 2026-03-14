import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/diaper_record.dart';
import '../domain/repositories/diaper_repository.dart';

class DiaperRepositoryImpl implements DiaperRepository {
  const DiaperRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<DiaperRecord>> getByBaby(int babyId) async {
    final db = await _database.database;
    final rows = await db.query(
      'diaper_records',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'record_time DESC',
    );
    return rows.map(_map).toList();
  }

  @override
  Future<DiaperRecord> create(DiaperRecord record) async {
    final db = await _database.database;
    final id = await db.insert('diaper_records', {
      'baby_id': record.babyId,
      'user_id': record.userId,
      'record_time': record.recordTime.toLocalIsoString(),
      'type': record.type,
      'color': record.color,
      'texture': record.texture,
      'notes': record.notes,
      'created_at': record.createdAt.toLocalIsoString(),
    });
    return DiaperRecord(
      id: id,
      babyId: record.babyId,
      userId: record.userId,
      recordTime: record.recordTime,
      type: record.type,
      color: record.color,
      texture: record.texture,
      notes: record.notes,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('diaper_records', where: 'id = ?', whereArgs: [id]);
  }

  DiaperRecord _map(Map<String, Object?> row) {
    return DiaperRecord(
      id: asInt(row['id']),
      babyId: asInt(row['baby_id']),
      userId: asInt(row['user_id']),
      recordTime: DateTime.parse(asString(row['record_time'])),
      type: asString(row['type']),
      color: row['color'] as String?,
      texture: row['texture'] as String?,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(asString(row['created_at'])),
    );
  }
}
