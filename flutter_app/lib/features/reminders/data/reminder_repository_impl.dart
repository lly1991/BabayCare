import '../../../core/database/app_database.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/reminder_item.dart';
import '../domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<ReminderItem> create(ReminderItem item) async {
    final db = await _database.database;
    final id = await db.insert('reminders', {
      'user_id': item.userId,
      'title': item.title,
      'body': item.body,
      'hour': item.hour,
      'minute': item.minute,
      'created_at': item.createdAt.toLocalIsoString(),
    });
    return ReminderItem(
      id: id,
      userId: item.userId,
      title: item.title,
      body: item.body,
      hour: item.hour,
      minute: item.minute,
      createdAt: item.createdAt,
    );
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ReminderItem>> getByUserId(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'hour ASC, minute ASC, id DESC',
    );
    return rows.map(_map).toList();
  }

  ReminderItem _map(Map<String, Object?> row) {
    return ReminderItem(
      id: asInt(row['id']),
      userId: asInt(row['user_id']),
      title: asString(row['title']),
      body: asString(row['body']),
      hour: asInt(row['hour']),
      minute: asInt(row['minute']),
      createdAt:
          DateTime.tryParse(asString(row['created_at'])) ?? DateTime.now(),
    );
  }
}
