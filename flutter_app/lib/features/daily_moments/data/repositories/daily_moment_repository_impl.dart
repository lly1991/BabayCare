import '../../domain/entities/daily_moment.dart';
import '../../domain/repositories/daily_moment_repository.dart';
import '../data_sources/daily_moment_local_data_source.dart';
import '../dto/daily_moment_model.dart';

class DailyMomentRepositoryImpl implements DailyMomentRepository {
  const DailyMomentRepositoryImpl(this._localDataSource);

  final DailyMomentLocalDataSource _localDataSource;

  @override
  Future<List<DailyMoment>> getByBabyId(int babyId) async {
    return _localDataSource.getByBabyId(babyId);
  }

  @override
  Future<DailyMoment> create(DailyMoment moment) async {
    final model = DailyMomentModel.fromEntity(moment);
    return _localDataSource.create(model);
  }

  @override
  Future<void> delete(DailyMoment moment) async {
    final model = DailyMomentModel.fromEntity(moment);
    await _localDataSource.delete(model);
  }
}
