import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../session/application/session_providers.dart';
import '../../data/baby_repository_impl.dart';
import '../../domain/entities/baby.dart';
import '../../domain/repositories/baby_repository.dart';

final babyRepositoryProvider = Provider<BabyRepository>(
  (ref) => BabyRepositoryImpl(AppDatabase.instance),
);

final currentBabyProvider = FutureProvider<Baby?>((ref) async {
  final babyId = ref.watch(currentBabyIdProvider);
  if (babyId == null) return null;
  return ref.read(babyRepositoryProvider).getById(babyId);
});

final babiesProvider = FutureProvider<List<Baby>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.read(babyRepositoryProvider).getByUser(userId);
});
