import '../entities/daily_stat.dart';
import '../entities/feeding_record.dart';

abstract class FeedingRepository {
  Future<FeedingRecord> addRecord(FeedingRecord record);
  Future<void> deleteRecord(int id);
  Future<List<FeedingRecord>> getRecent(int babyId, {int limit = 20});
  Future<List<FeedingRecord>> getByDate(int babyId, String date);
  Future<List<FeedingRecord>> getByMonth(int babyId, int year, int month);
  Future<DailyStat> getDailyStat(int babyId, String date);
  Future<List<DailyStat>> getWeeklyStats(int babyId, String startDate);
  Future<List<DailyStat>> getMonthlyStats(int babyId, int year, int month);
}
