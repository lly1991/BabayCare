import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../session/application/session_providers.dart';
import '../../data/sleep_repository_impl.dart';
import '../../domain/entities/sleep_record.dart';
import '../../domain/repositories/sleep_repository.dart';

final sleepRepositoryProvider = Provider<SleepRepository>(
  (ref) => SleepRepositoryImpl(AppDatabase.instance),
);

final sleepRecordsProvider = FutureProvider<List<SleepRecord>>((ref) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return const [];
  return ref.read(sleepRepositoryProvider).getByBaby(babyId);
});

final ongoingSleepProvider = FutureProvider<SleepRecord?>((ref) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return null;
  return ref.read(sleepRepositoryProvider).getOngoing(babyId);
});
