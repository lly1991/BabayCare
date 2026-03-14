import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../session/application/session_providers.dart';
import '../../data/feeding_repository_impl.dart';
import '../../domain/entities/daily_stat.dart';
import '../../domain/entities/feeding_record.dart';
import '../../domain/repositories/feeding_repository.dart';

class YearMonth {
  const YearMonth({required this.year, required this.month});

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearMonth &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(year, month);
}

final feedingRepositoryProvider = Provider<FeedingRepository>(
  (ref) => FeedingRepositoryImpl(AppDatabase.instance),
);

final recentFeedingsProvider = FutureProvider<List<FeedingRecord>>((ref) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return const [];
  return ref.read(feedingRepositoryProvider).getRecent(babyId, limit: 20);
});

final dailyStatProvider =
    FutureProvider.family<DailyStat, String>((ref, date) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) {
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
  return ref.read(feedingRepositoryProvider).getDailyStat(babyId, date);
});

final feedingsByDateProvider =
    FutureProvider.family<List<FeedingRecord>, String>((ref, date) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return const [];
  return ref.read(feedingRepositoryProvider).getByDate(babyId, date);
});

final weeklyStatsProvider =
    FutureProvider.family<List<DailyStat>, String>((ref, startDate) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return const [];
  return ref.read(feedingRepositoryProvider).getWeeklyStats(babyId, startDate);
});

final monthlyStatsProvider = FutureProvider.family<List<DailyStat>, YearMonth>(
  (ref, ym) async {
    final babyId = ref.watch(currentBabyIdProvider);
    if (babyId == null) return const [];
    return ref
        .read(feedingRepositoryProvider)
        .getMonthlyStats(babyId, ym.year, ym.month);
  },
);
