import '../entities/daily_moment.dart';
import '../repositories/daily_moment_repository.dart';

class DeleteDailyMomentUseCase {
  const DeleteDailyMomentUseCase(this._repository);

  final DailyMomentRepository _repository;

  Future<void> call(DailyMoment moment) => _repository.delete(moment);
}
