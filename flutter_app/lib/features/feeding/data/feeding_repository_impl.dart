import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/daily_stat.dart';
import '../domain/entities/feeding_record.dart';
import '../domain/repositories/feeding_repository.dart';

class FeedingRepositoryImpl implements FeedingRepository {
  const FeedingRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<FeedingRecord> addRecord(FeedingRecord record) async {
    final db = await _database.database;
    final id = await db.insert('feeding_records', {
      'baby_id': record.babyId,
      'user_id': record.userId,
      'feed_time': record.feedTime.toLocalIsoString(),
      'end_time': record.endTime?.toLocalIsoString(),
      'feed_type': record.feedType == FeedType.breast ? 'breast' : 'formula',
      'amount_ml': record.amountMl,
      'duration_min': record.durationMin,
      'left_duration': record.leftDuration,
      'right_duration': record.rightDuration,
      'brand': record.brand,
      'notes': record.notes,
      'created_at': record.createdAt.toLocalIsoString(),
    });
    return FeedingRecord(
      id: id,
      babyId: record.babyId,
      userId: record.userId,
      feedTime: record.feedTime,
      feedType: record.feedType,
      amountMl: record.amountMl,
      durationMin: record.durationMin,
      leftDuration: record.leftDuration,
      rightDuration: record.rightDuration,
      endTime: record.endTime,
      brand: record.brand,
      notes: record.notes,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<void> deleteRecord(int id) async {
    final db = await _database.database;
    await db.delete('feeding_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<FeedingRecord>> getRecent(int babyId, {int limit = 20}) async {
    final db = await _database.database;
    final rows = await db.query(
      'feeding_records',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'feed_time DESC',
      limit: limit,
    );
    return rows.map(_mapRecord).toList();
  }

  @override
  Future<List<FeedingRecord>> getByDate(int babyId, String date) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM feeding_records
      WHERE baby_id = ? AND substr(feed_time, 1, 10) = ?
      ORDER BY feed_time DESC
      ''',
      [babyId, date],
    );
    return rows.map(_mapRecord).toList();
  }

  @override
  Future<List<FeedingRecord>> getByMonth(
      int babyId, int year, int month) async {
    final db = await _database.database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      '''
      SELECT * FROM feeding_records
      WHERE baby_id = ? AND substr(feed_time, 1, 7) = ?
      ORDER BY feed_time DESC
      ''',
      [babyId, monthStr],
    );
    return rows.map(_mapRecord).toList();
  }

  @override
  Future<DailyStat> getDailyStat(int babyId, String date) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        ? AS date,
        COUNT(*) AS total_count,
        COALESCE(SUM(amount_ml), 0) AS total_amount,
        COALESCE(SUM(CASE WHEN feed_type = 'breast' THEN 1 ELSE 0 END), 0) AS breast_count,
        COALESCE(SUM(CASE WHEN feed_type = 'breast' THEN duration_min ELSE 0 END), 0) AS breast_duration,
        COALESCE(SUM(CASE WHEN feed_type = 'formula' THEN 1 ELSE 0 END), 0) AS formula_count,
        COALESCE(SUM(CASE WHEN feed_type = 'formula' THEN amount_ml ELSE 0 END), 0) AS formula_amount
      FROM feeding_records
      WHERE baby_id = ? AND substr(feed_time, 1, 10) = ?
      ''',
      [date, babyId, date],
    );
    if (rows.isEmpty) {
      return DailyStat(
        date: date,
        totalCount: 0,
        totalAmount: 0,
        breastCount: 0,
        breastDuration: 0,
        formulaCount: 0,
        formulaAmount: 0,
      );
    }
    return _mapStat(rows.first);
  }

  @override
  Future<List<DailyStat>> getWeeklyStats(int babyId, String startDate) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        substr(feed_time, 1, 10) AS date,
        COUNT(*) AS total_count,
        COALESCE(SUM(amount_ml), 0) AS total_amount,
        COALESCE(SUM(CASE WHEN feed_type = 'breast' THEN 1 ELSE 0 END), 0) AS breast_count,
        COALESCE(SUM(CASE WHEN feed_type = 'breast' THEN duration_min ELSE 0 END), 0) AS breast_duration,
        COALESCE(SUM(CASE WHEN feed_type = 'formula' THEN 1 ELSE 0 END), 0) AS formula_count,
        COALESCE(SUM(CASE WHEN feed_type = 'formula' THEN amount_ml ELSE 0 END), 0) AS formula_amount
      FROM feeding_records
      WHERE baby_id = ? AND substr(feed_time, 1, 10) >= ?
      GROUP BY substr(feed_time, 1, 10)
      ORDER BY date
      ''',
      [babyId, startDate],
    );
    return rows.map(_mapStat).toList();
  }

  @override
  Future<List<DailyStat>> getMonthlyStats(
      int babyId, int year, int month) async {
    final db = await _database.database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.rawQuery(
      '''
      SELECT
        substr(feed_time, 1, 10) AS date,
        COUNT(*) AS total_count,
        COALESCE(SUM(amount_ml), 0) AS total_amount,
        COALESCE(SUM(CASE WHEN feed_type = 'breast' THEN 1 ELSE 0 END), 0) AS breast_count,
        COALESCE(SUM(CASE WHEN feed_type = 'breast' THEN duration_min ELSE 0 END), 0) AS breast_duration,
        COALESCE(SUM(CASE WHEN feed_type = 'formula' THEN 1 ELSE 0 END), 0) AS formula_count,
        COALESCE(SUM(CASE WHEN feed_type = 'formula' THEN amount_ml ELSE 0 END), 0) AS formula_amount
      FROM feeding_records
      WHERE baby_id = ? AND substr(feed_time, 1, 7) = ?
      GROUP BY substr(feed_time, 1, 10)
      ORDER BY date
      ''',
      [babyId, monthStr],
    );
    return rows.map(_mapStat).toList();
  }

  FeedingRecord _mapRecord(Map<String, Object?> row) {
    return FeedingRecord(
      id: asInt(row['id']),
      babyId: asInt(row['baby_id']),
      userId: asInt(row['user_id']),
      feedTime: DateTime.tryParse(asString(row['feed_time'])) ?? DateTime.now(),
      feedType: asString(row['feed_type']) == 'formula'
          ? FeedType.formula
          : FeedType.breast,
      amountMl: row['amount_ml'] == null ? null : asInt(row['amount_ml']),
      durationMin:
          row['duration_min'] == null ? null : asInt(row['duration_min']),
      leftDuration:
          row['left_duration'] == null ? null : asInt(row['left_duration']),
      rightDuration:
          row['right_duration'] == null ? null : asInt(row['right_duration']),
      endTime: row['end_time'] == null
          ? null
          : DateTime.tryParse(asString(row['end_time'])),
      brand: row['brand'] as String?,
      notes: row['notes'] as String?,
      createdAt:
          DateTime.tryParse(asString(row['created_at'])) ?? DateTime.now(),
    );
  }

  DailyStat _mapStat(Map<String, Object?> row) {
    return DailyStat(
      date: asString(row['date']),
      totalCount: asInt(row['total_count']),
      totalAmount: asInt(row['total_amount']),
      breastCount: asInt(row['breast_count']),
      breastDuration: asInt(row['breast_duration']),
      formulaCount: asInt(row['formula_count']),
      formulaAmount: asInt(row['formula_amount']),
    );
  }
}
