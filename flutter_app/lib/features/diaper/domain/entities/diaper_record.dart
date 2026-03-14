class DiaperRecord {
  const DiaperRecord({
    this.id,
    required this.babyId,
    required this.userId,
    required this.recordTime,
    required this.type,
    this.color,
    this.texture,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final int babyId;
  final int userId;
  final DateTime recordTime;
  final String type;
  final String? color;
  final String? texture;
  final String? notes;
  final DateTime createdAt;
}
