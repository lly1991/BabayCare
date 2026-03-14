import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/daily_moment.dart';
import '../dto/daily_moment_model.dart';

class DailyMomentLocalDataSource {
  const DailyMomentLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<DailyMomentModel>> getByBabyId(int babyId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'media_records',
      where: 'baby_id = ?',
      whereArgs: [babyId],
      orderBy: 'created_at DESC',
    );
    return rows.map(DailyMomentModel.fromMap).toList();
  }

  Future<DailyMomentModel> create(DailyMomentModel model) async {
    final db = await _appDatabase.database;
    final payload = model.toMap()..remove('id');
    final id = await db.insert('media_records', payload);
    return DailyMomentModel.fromEntity(model.copyWith(id: id));
  }

  Future<void> delete(DailyMomentModel model) async {
    if (model.id == null) {
      throw AppException('Cannot delete a moment without id');
    }

    final db = await _appDatabase.database;
    await db.delete('media_records', where: 'id = ?', whereArgs: [model.id]);

    final file = File(model.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> persistPickedFile({
    required String sourcePath,
    required DailyMomentType type,
    required int babyId,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw AppException('Selected file does not exist: $sourcePath');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(appDir.path, 'daily_moments'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final safeExt = ext.isNotEmpty
        ? ext
        : (type == DailyMomentType.video ? '.mp4' : '.jpg');
    final fileName =
        'baby_${babyId}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final targetPath = p.join(mediaDir.path, fileName);

    final copied = await sourceFile.copy(targetPath);
    return copied.path;
  }
}
