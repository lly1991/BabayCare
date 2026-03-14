class GrowthRecord {
  const GrowthRecord({
    this.id,
    required this.babyId,
    required this.userId,
    required this.weightKg,
    required this.heightCm,
    this.headCircCm,
    required this.measureTime,
    required this.createdAt,
  });

  final int? id;
  final int babyId;
  final int userId;
  final double weightKg;
  final double heightCm;
  final double? headCircCm;
  final DateTime measureTime;
  final DateTime createdAt;
}
