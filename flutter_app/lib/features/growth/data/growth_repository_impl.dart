import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/growth_record.dart';
import '../domain/repositories/growth_repository.dart';

class GrowthRepositoryImpl implements GrowthRepository {
  const GrowthRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<GrowthRecord>> getByBaby(int babyId) async {
    final db = await _database.database;
    final rows = await db.query(
      'growth_records',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'measure_time DESC',
    );
    return rows.map(_map).toList();
  }

  @override
  Future<GrowthRecord> create(GrowthRecord record) async {
    final db = await _database.database;
    final id = await db.insert('growth_records', {
      'baby_id': record.babyId,
      'user_id': record.userId,
      'weight_kg': record.weightKg,
      'height_cm': record.heightCm,
      'head_circ_cm': record.headCircCm,
      'measure_time': record.measureTime.toLocalIsoString(),
      'created_at': record.createdAt.toLocalIsoString(),
    });
    return GrowthRecord(
      id: id,
      babyId: record.babyId,
      userId: record.userId,
      weightKg: record.weightKg,
      heightCm: record.heightCm,
      headCircCm: record.headCircCm,
      measureTime: record.measureTime,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('growth_records', where: 'id = ?', whereArgs: [id]);
  }

  GrowthRecord _map(Map<String, Object?> row) {
    return GrowthRecord(
      id: asInt(row['id']),
      babyId: asInt(row['baby_id']),
      userId: asInt(row['user_id']),
      weightKg: asDouble(row['weight_kg']),
      heightCm: asDouble(row['height_cm']),
      headCircCm:
          row['head_circ_cm'] == null ? null : asDouble(row['head_circ_cm']),
      measureTime: DateTime.parse(asString(row['measure_time'])),
      createdAt: DateTime.parse(asString(row['created_at'])),
    );
  }
}
