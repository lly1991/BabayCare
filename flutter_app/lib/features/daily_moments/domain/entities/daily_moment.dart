enum DailyMomentType { image, video }

class DailyMoment {
  const DailyMoment({
    this.id,
    required this.babyId,
    required this.userId,
    required this.filePath,
    required this.type,
    required this.createdAt,
    this.description,
    this.thumbnailPath,
  });

  final int? id;
  final int babyId;
  final int userId;
  final String filePath;
  final DailyMomentType type;
  final DateTime createdAt;
  final String? description;
  final String? thumbnailPath;

  DailyMoment copyWith({
    int? id,
    int? babyId,
    int? userId,
    String? filePath,
    DailyMomentType? type,
    DateTime? createdAt,
    String? description,
    String? thumbnailPath,
  }) {
    return DailyMoment(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      userId: userId ?? this.userId,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
