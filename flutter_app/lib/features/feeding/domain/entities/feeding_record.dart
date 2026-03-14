enum FeedType { breast, formula }

class FeedingRecord {
  const FeedingRecord({
    this.id,
    required this.babyId,
    required this.userId,
    required this.feedTime,
    required this.feedType,
    this.amountMl,
    this.durationMin,
    this.leftDuration,
    this.rightDuration,
    this.endTime,
    this.brand,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final int babyId;
  final int userId;
  final DateTime feedTime;
  final FeedType feedType;
  final int? amountMl;
  final int? durationMin;
  final int? leftDuration;
  final int? rightDuration;
  final DateTime? endTime;
  final String? brand;
  final String? notes;
  final DateTime createdAt;
}
