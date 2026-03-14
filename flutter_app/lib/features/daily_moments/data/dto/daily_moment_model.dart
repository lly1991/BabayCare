import '../../domain/entities/daily_moment.dart';
import '../../../../core/utils/date_time_x.dart';

class DailyMomentModel extends DailyMoment {
  const DailyMomentModel({
    super.id,
    required super.babyId,
    required super.userId,
    required super.filePath,
    required super.type,
    required super.createdAt,
    super.description,
    super.thumbnailPath,
  });

  factory DailyMomentModel.fromMap(Map<String, Object?> map) {
    return DailyMomentModel(
      id: map['id'] as int?,
      babyId: map['baby_id'] as int,
      userId: map['user_id'] as int,
      filePath: map['file_path'] as String,
      type: (map['file_type'] as String) == 'video'
          ? DailyMomentType.video
          : DailyMomentType.image,
      thumbnailPath: map['thumbnail_path'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'baby_id': babyId,
      'user_id': userId,
      'file_path': filePath,
      'file_type': type == DailyMomentType.video ? 'video' : 'image',
      'thumbnail_path': thumbnailPath,
      'description': description,
      'created_at': createdAt.toLocalIsoString(),
    };
  }

  factory DailyMomentModel.fromEntity(DailyMoment entity) {
    return DailyMomentModel(
      id: entity.id,
      babyId: entity.babyId,
      userId: entity.userId,
      filePath: entity.filePath,
      type: entity.type,
      createdAt: entity.createdAt,
      description: entity.description,
      thumbnailPath: entity.thumbnailPath,
    );
  }
}
