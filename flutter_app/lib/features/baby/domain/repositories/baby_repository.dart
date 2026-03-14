import '../entities/baby.dart';

abstract class BabyRepository {
  Future<List<Baby>> getByUser(int userId);
  Future<Baby?> getById(int id);
  Future<Baby> create(Baby baby);
  Future<Baby> update(Baby baby);
}
