import '../entities/growth_record.dart';

abstract class GrowthRepository {
  Future<List<GrowthRecord>> getByBaby(int babyId);
  Future<GrowthRecord> create(GrowthRecord record);
  Future<void> delete(int id);
}
