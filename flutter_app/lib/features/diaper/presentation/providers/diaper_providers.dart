import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../session/application/session_providers.dart';
import '../../data/diaper_repository_impl.dart';
import '../../domain/entities/diaper_record.dart';
import '../../domain/repositories/diaper_repository.dart';

final diaperRepositoryProvider = Provider<DiaperRepository>(
  (ref) => DiaperRepositoryImpl(AppDatabase.instance),
);

final diaperRecordsProvider = FutureProvider<List<DiaperRecord>>((ref) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return const [];
  return ref.read(diaperRepositoryProvider).getByBaby(babyId);
});
