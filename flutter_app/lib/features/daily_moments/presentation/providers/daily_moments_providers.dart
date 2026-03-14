import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../session/application/session_providers.dart';
import '../../data/data_sources/daily_moment_local_data_source.dart';
import '../../data/repositories/daily_moment_repository_impl.dart';
import '../../domain/entities/daily_moment.dart';
import '../../domain/repositories/daily_moment_repository.dart';
import '../../domain/usecases/create_daily_moment_usecase.dart';
import '../../domain/usecases/delete_daily_moment_usecase.dart';
import '../../domain/usecases/get_daily_moments_usecase.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final dailyMomentsLocalDataSourceProvider =
    Provider<DailyMomentLocalDataSource>(
  (ref) => DailyMomentLocalDataSource(AppDatabase.instance),
);

final dailyMomentRepositoryProvider = Provider<DailyMomentRepository>(
  (ref) =>
      DailyMomentRepositoryImpl(ref.watch(dailyMomentsLocalDataSourceProvider)),
);

final getDailyMomentsUseCaseProvider = Provider<GetDailyMomentsUseCase>(
  (ref) => GetDailyMomentsUseCase(ref.watch(dailyMomentRepositoryProvider)),
);

final createDailyMomentUseCaseProvider = Provider<CreateDailyMomentUseCase>(
  (ref) => CreateDailyMomentUseCase(ref.watch(dailyMomentRepositoryProvider)),
);

final deleteDailyMomentUseCaseProvider = Provider<DeleteDailyMomentUseCase>(
  (ref) => DeleteDailyMomentUseCase(ref.watch(dailyMomentRepositoryProvider)),
);

final dailyMomentsNotifierProvider =
    AsyncNotifierProvider<DailyMomentsNotifier, List<DailyMoment>>(
  DailyMomentsNotifier.new,
);

class DailyMomentsNotifier extends AsyncNotifier<List<DailyMoment>> {
  @override
  Future<List<DailyMoment>> build() async {
    final babyId = ref.watch(currentBabyIdProvider);
    if (babyId == null) return const [];
    return ref.read(getDailyMomentsUseCaseProvider)(babyId);
  }

  Future<void> refresh() async {
    final babyId = ref.read(currentBabyIdProvider);
    if (babyId == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(getDailyMomentsUseCaseProvider)(babyId),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ref.read(imagePickerProvider);
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    await _createMoment(sourcePath: file.path, type: DailyMomentType.image);
  }

  Future<void> pickVideo(ImageSource source) async {
    final picker = ref.read(imagePickerProvider);
    final file = await picker.pickVideo(source: source);
    if (file == null) return;
    await _createMoment(sourcePath: file.path, type: DailyMomentType.video);
  }

  Future<void> deleteMoment(DailyMoment moment) async {
    await ref.read(deleteDailyMomentUseCaseProvider)(moment);
    await refresh();
  }

  Future<void> _createMoment({
    required String sourcePath,
    required DailyMomentType type,
  }) async {
    final babyId = ref.read(currentBabyIdProvider);
    final userId = ref.read(currentUserIdProvider);
    if (babyId == null || userId == null) {
      throw AppException('当前未选择宝宝或用户未登录');
    }
    final localDs = ref.read(dailyMomentsLocalDataSourceProvider);

    final persistedPath = await localDs.persistPickedFile(
      sourcePath: sourcePath,
      type: type,
      babyId: babyId,
    );

    final draft = DailyMoment(
      babyId: babyId,
      userId: userId,
      filePath: persistedPath,
      type: type,
      createdAt: DateTime.now(),
    );

    await ref.read(createDailyMomentUseCaseProvider)(draft);
    await refresh();
  }
}
