import '../entities/daily_moment.dart';
import '../repositories/daily_moment_repository.dart';

class CreateDailyMomentUseCase {
  const CreateDailyMomentUseCase(this._repository);

  final DailyMomentRepository _repository;

  Future<DailyMoment> call(DailyMoment moment) => _repository.create(moment);
}
