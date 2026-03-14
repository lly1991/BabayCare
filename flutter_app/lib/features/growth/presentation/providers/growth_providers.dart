import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../session/application/session_providers.dart';
import '../../data/growth_repository_impl.dart';
import '../../domain/entities/growth_record.dart';
import '../../domain/repositories/growth_repository.dart';

final growthRepositoryProvider = Provider<GrowthRepository>(
  (ref) => GrowthRepositoryImpl(AppDatabase.instance),
);

final growthRecordsProvider = FutureProvider<List<GrowthRecord>>((ref) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return const [];
  return ref.read(growthRepositoryProvider).getByBaby(babyId);
});
