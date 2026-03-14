class SleepRecord {
  const SleepRecord({
    this.id,
    required this.babyId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.isOngoing,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final int babyId;
  final int userId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isOngoing;
  final String? notes;
  final DateTime createdAt;
}
