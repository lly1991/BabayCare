import '../entities/sleep_record.dart';

abstract class SleepRepository {
  Future<List<SleepRecord>> getByBaby(int babyId);
  Future<SleepRecord?> getOngoing(int babyId);
  Future<SleepRecord> create(SleepRecord record);
  Future<void> endSleep(int recordId, DateTime endTime);
  Future<void> delete(int id);
}
