import '../../../core/database/app_database.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_time_x.dart';
import '../../../core/utils/value_parsers.dart';
import '../domain/entities/baby.dart';
import '../domain/repositories/baby_repository.dart';

class BabyRepositoryImpl implements BabyRepository {
  const BabyRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<Baby>> getByUser(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'babies',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(_map).toList();
  }

  @override
  Future<Baby?> getById(int id) async {
    final db = await _database.database;
    final rows =
        await db.query('babies', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<Baby> create(Baby baby) async {
    final db = await _database.database;
    if (baby.name.trim().isEmpty) {
      throw AppException('宝宝姓名不能为空');
    }

    final createdAt = DateTime.now().toLocalIsoString();
    final id = await db.insert('babies', {
      'user_id': baby.userId,
      'name': baby.name.trim(),
      'birth_date': baby.birthDate.toLocalIsoString(),
      'gender': baby.gender,
      'avatar': baby.avatar,
      'created_at': createdAt,
    });

    return Baby(
      id: id,
      userId: baby.userId,
      name: baby.name.trim(),
      birthDate: baby.birthDate,
      gender: baby.gender,
      avatar: baby.avatar,
      createdAt: DateTime.parse(createdAt),
    );
  }

  @override
  Future<Baby> update(Baby baby) async {
    if (baby.id == null) {
      throw AppException('更新宝宝信息时缺少 id');
    }
    final db = await _database.database;
    await db.update(
      'babies',
      {
        'name': baby.name.trim(),
        'birth_date': baby.birthDate.toLocalIsoString(),
        'gender': baby.gender,
        'avatar': baby.avatar,
      },
      where: 'id = ?',
      whereArgs: [baby.id],
    );
    return baby;
  }

  Baby _map(Map<String, Object?> row) {
    return Baby(
      id: asInt(row['id']),
      userId: asInt(row['user_id']),
      name: asString(row['name']),
      birthDate:
          DateTime.tryParse(asString(row['birth_date'])) ?? DateTime.now(),
      gender: asString(row['gender'], fallback: 'unknown'),
      avatar: row['avatar'] as String?,
      createdAt:
          DateTime.tryParse(asString(row['created_at'])) ?? DateTime.now(),
    );
  }
}
