import '../entities/daily_moment.dart';

abstract class DailyMomentRepository {
  Future<List<DailyMoment>> getByBabyId(int babyId);
  Future<DailyMoment> create(DailyMoment moment);
  Future<void> delete(DailyMoment moment);
}
