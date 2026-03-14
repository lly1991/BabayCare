import '../entities/daily_moment.dart';
import '../repositories/daily_moment_repository.dart';

class GetDailyMomentsUseCase {
  const GetDailyMomentsUseCase(this._repository);

  final DailyMomentRepository _repository;

  Future<List<DailyMoment>> call(int babyId) => _repository.getByBabyId(babyId);
}
