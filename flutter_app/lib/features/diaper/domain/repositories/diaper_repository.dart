import '../entities/diaper_record.dart';

abstract class DiaperRepository {
  Future<List<DiaperRecord>> getByBaby(int babyId);
  Future<DiaperRecord> create(DiaperRecord record);
  Future<void> delete(int id);
}
